"""Turned machinery and swept services. Construction axes are documented below."""
import math
from mathutils import Vector
from .core import (frame, mesh_object, finish, lathe, cylinder, tube, sphere,
                   chamfered_box, combine, difference, place)


def bell_nozzle(throat_radius=.19,mouth_radius=.43,length=.55,wall=.025,
                material=None,lining=None,segments=48,name='Bronze-lined bell nozzle'):
    """Closed annular section; throat at Z=0, open mouth at Z=length.

    Outer shell, continuous bronze lip and complete inner lining are faces of
    ONE solid wall. The interior is open through the throat, never a dark cap.
    """
    if not 0<wall<throat_radius or mouth_radius<=throat_radius or length<=0:
        raise ValueError('Invalid bell wall, radii or length')
    r,m,L,t=throat_radius,mouth_radius,length,wall
    outer=[(r+t,0),(r+t,L*.22),(r*1.2+t,L*.45),(m*.85,L*.78),(m,L*.95),(m,L)]
    inner=[(m-t,L),(m-t,L*.95),(m*.85-t,L*.78),(r*1.2,L*.45),(r,L*.22),(r,0)]
    obj=lathe(outer+inner,segments,[material,lining or material],
              [0]*5+[1]*6+[0],name)
    obj['wall_thickness_m']=wall
    return obj


def smooth_path(points,steps=5):
    if len(points)<2:
        raise ValueError('A sweep needs at least two points')
    p=[Vector(points[0]),*[Vector(x) for x in points],Vector(points[-1])]
    result=[]
    for i in range(1,len(p)-2):
        a,b,c,d=p[i-1:i+3]
        for j in range(steps):
            t=j/steps
            result.append(.5*((2*b)+(-a+c)*t+(2*a-5*b+4*c-d)*t*t+(-a+3*b-3*c+d)*t*t*t))
    return result+[p[-1]]


def swept_bar(points,radius=.025,segments=8,material=None,name='Swept bar',smooth=False):
    """Capped circular/octagonal sweep with transported cross-section frames."""
    points=smooth_path(points) if smooth else list(map(Vector,points))
    if len(points)<2 or radius<=0 or segments<4:
        raise ValueError('Sweep needs >=2 points, positive radius and >=4 sides')
    vertices=[]
    u=None
    for i,p in enumerate(points):
        w=(points[min(i+1,len(points)-1)]-points[max(0,i-1)]).normalized()
        if u is None:
            u,v,w=frame(w)
        else:
            projected=u-w*u.dot(w)
            u=projected.normalized() if projected.length>1e-6 else frame(w)[0]
            v=w.cross(u).normalized()
        vertices.extend(tuple(p+radius*(u*math.cos(j*math.tau/segments)+v*math.sin(j*math.tau/segments)))
                        for j in range(segments))
    faces=[tuple(reversed(range(segments))),
           tuple(range((len(points)-1)*segments,len(points)*segments))]
    faces += [(i*segments+j,i*segments+(j+1)%segments,(i+1)*segments+(j+1)%segments,(i+1)*segments+j)
              for i in range(len(points)-1) for j in range(segments)]
    return finish(mesh_object(name,vertices,faces,material))


def cable_bundle(points,count=3,radius=.022,spacing=None,material=None,name='Cable bundle'):
    """Smooth parallel cable runs, each capped and eight-sided; one mesh."""
    if count<1:
        raise ValueError('Cable count must be positive')
    spacing=spacing or radius*2.35
    # Spread across the mounting plane, rather than stacking cables in Z where
    # a surface-mounted loom would appear to be one thick cable from the front.
    tangent=(Vector(points[1])-Vector(points[0])).normalized()
    u=Vector((0,0,1)).cross(tangent)
    u=u.normalized() if u.length>1e-6 else frame(tangent)[0]
    cables=[swept_bar([Vector(p)+u*(i-(count-1)/2)*spacing for p in points],
                      radius,8,material,smooth=True) for i in range(count)]
    return combine(cables,name)


def spherical_eye(radius=.12,bore_radius=.055,center=(0,0,0),axis=(0,1,0),
                  material=None,name='Spherical rod eye'):
    if not 0<bore_radius<radius:
        raise ValueError('Eye bore must fit in the spherical housing')
    eye=sphere(radius,center,material,name)
    difference(eye,cylinder(bore_radius,radius*3,center,axis,segments=24,bevel=0))
    return finish(eye)


def hydraulic_cylinder(eye_a,eye_b,retracted_length,barrel_radius=.14,rod_radius=.065,
                       material=None,chrome=None,steel=None,eye_axis=(0,1,0),
                       name='Hydraulic cylinder'):
    """Eye-centre-to-eye-centre model. retracted_length includes both eyes.

    The barrel length is derived from the minimum eye span. Eye B extends the
    rod; the physical rod overlaps the barrel through a bored gland. Max stroke
    is the usable barrel length. The returned manufactured module is one mesh
    with independent material slots and explicit endpoint/stroke custom props.
    """
    a,b=Vector(eye_a),Vector(eye_b)
    span=(b-a).length
    R=barrel_radius
    eye_r=R*.85
    usable=retracted_length-4*eye_r
    if usable<=0 or span<retracted_length-1e-6 or span>retracted_length+usable+1e-6:
        raise ValueError('Eye span is outside the cylinder retracted length / usable stroke')
    if not 0<rod_radius<barrel_radius*.7:
        raise ValueError('Rod must fit the barrel and gland')
    w=(b-a).normalized()
    start=a+w*(eye_r*1.3)
    end=start+w*usable
    gland_depth=R*.45
    pieces=[tube(R,rod_radius*1.12,usable,(start+end)/2,w,32,.008,material,'Barrel'),
            cylinder(R*1.04,R*.25,start,w,32,.007,steel or material,'Rear cap'),
            tube(R*1.08,rod_radius*1.04,gland_depth,end,w,32,.006,steel or material,'Bored gland'),
            tube(rod_radius*1.14,rod_radius*1.01,.018,end+w*gland_depth*.52,w,24,.002,material,'Rod seal')]
    rod_end=b-w*eye_r*.65
    rod_start=end-w*min(.12,usable*.3)
    pieces.append(cylinder(rod_radius,(rod_end-rod_start).length,(rod_end+rod_start)/2,w,
                           32,.003,chrome or steel,'Polished rod'))
    for p,q in [(a,start),(b,rod_end)]:
        pieces.append(cylinder(rod_radius*1.15,(q-p).length,(p+q)/2,w,16,.003,steel or material,'Eye neck'))
        pieces.append(spherical_eye(eye_r,eye_r*.43,p,eye_axis,steel or material))
    obj=combine(pieces,name)
    obj['eye_a_m']=list(a); obj['eye_b_m']=list(b)
    obj['retracted_length_m']=retracted_length
    obj['extension_m']=span-retracted_length
    obj['maximum_stroke_m']=usable
    return obj


def clevis(width=.42,gap=.18,depth=.35,height=.42,bore_radius=.055,
           material=None,name='Bored clevis'):
    """Mount base at Z=0; paired ears along X, pin axis X at Z=.7*height."""
    if not 0<gap<width or min(depth,height,bore_radius)<=0:
        raise ValueError('Clevis requires a positive gap, ears, depth and height')
    t=(width-gap)/2
    pieces=[chamfered_box((width,depth,height*.2),(0,0,height*.1),.012,material)]
    for s in (-1,1):
        x=s*(gap+t)/2
        ear=chamfered_box((t,depth*.8,height*.85),(x,0,height*.55),.025,material)
        difference(ear,cylinder(bore_radius,t+.02,(x,0,height*.7),(1,0,0),24,0))
        pieces.append(finish(ear))
    return combine(pieces,name)
