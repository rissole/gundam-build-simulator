"""Measured FA-02 interfaces and sampled shin/guard clearance. Tolerances <=10 mm.

No geometric check compares custom-property datums. Bore rings are selected and
fitted from actual world-space vertices, with ray checks through receiver solids.
"""
import csv
import math
from pathlib import Path
from collections import Counter
import bpy
import numpy as np
from mathutils import Vector

CSV=Path(__file__).resolve().parents[3]/'design/legs/foot-and-ankle/foot-components.csv'
ROWS=list(csv.DictReader(CSV.open()))
DEFERRED_ROWS=set()
TOL=.010


class Check(tuple):
    """Tuple contract, plus record access for the existing generic leg runner."""
    def __new__(cls,name,ok,detail):return tuple.__new__(cls,(name,bool(ok),detail))
    def get(self,key,default=None):
        return {'name':self[0],'check':self[0],'ok':self[1],'passed':self[1],'detail':self[2]}.get(key,default)


def translation_clearance(moving,static,travel=(0,0,3),required=.010,facet_region=None):
    """Conservative continuous solid separation, including the seating interval.

    Sweep each actual mesh triangle into a convex prism. A separating projection
    between that prism and every static triangle bounds their Euclidean distance
    from below. AABB gaps reject easy pairs; triangle/prism face normals and
    cross-edge axes resolve diagonal folds. No pose sampling or mount exemption.
    Surface separation plus an independent initial containment test proves the
    solids remain disjoint. Unresolved/degenerate pairs fail conservatively.
    """
    def triangles(obj):
        obj.data.calc_loop_triangles()
        points=np.array([obj.matrix_world@v.co for v in obj.data.vertices])
        return points[np.array([t.vertices[:] for t in obj.data.loop_triangles])]
    a,b=triangles(moving),triangles(static);delta=np.array(travel,dtype=float)
    if facet_region is not None:
        # F4 changes only the straight lateral lower folds, tapering to zero
        # before the original plan chamfers. Include their full inner/outer skin.
        y0,y1=facet_region
        a=a[(a[:,:,2].max(1)<=.311)&(abs(a[:,:,0]).min(1)>=.670)&
            (a[:,:,1].min(1)>=y0-.001)&(a[:,:,1].max(1)<=y1+.001)]
        if not len(a):return False,{'error':'No lower facet triangles found'}
    blo,bhi=b.min(1),b.max(1);be=np.roll(b,-1,axis=1)-b
    bn=np.cross(be[:,0],be[:,1]);worst=float('inf');unresolved=[];pairs=0
    for i,tri in enumerate(a):
        prism=np.concatenate((tri,tri+delta));lo,hi=prism.min(0),prism.max(0)
        gap=np.linalg.norm(np.maximum(np.maximum(blo-hi,lo-bhi),0),axis=1)
        selected=np.flatnonzero(gap<max(.030,required+1e-6))
        if not len(selected):
            worst=min(worst,float(gap.min()));continue
        pairs+=len(selected);other=b[selected];edges=be[selected]
        ae=np.roll(tri,-1,axis=0)-tri
        fixed=[np.cross(ae[0],ae[1]),*[np.cross(e,delta) for e in ae]]
        axes=[np.broadcast_to(n,(len(selected),3)) for n in fixed]
        axes.extend([bn[selected],*[np.cross(e,edges[:,j]) for e in [*ae,delta] for j in range(3)]])
        lower=gap[selected].copy()
        for axis in axes:
            lengths=np.linalg.norm(axis,axis=1)
            unit=axis/np.maximum(lengths[:,None],1e-30)
            pa=prism@unit.T;pb=np.einsum('nvc,nc->nv',other,unit)
            separation=np.maximum(pb.min(1)-pa.max(0),pa.min(0)-pb.max(1))
            lower=np.maximum(lower,np.where(lengths>1e-12,separation,0))
        gap[selected]=lower;worst=min(worst,float(gap.min()))
        unresolved.extend((i,int(j),float(d)) for j,d in zip(selected,lower) if d<required-1e-6)
    from verify_sequence import MeshClearance
    solid=MeshClearance()
    # The full shell intentionally mates to rail receivers above the F4 region.
    # Only full-object sweeps use the connected-solid containment check.
    if facet_region is None:
        initial=solid.clear(moving['instance_id'],static['instance_id'],(0,0,0))
    else:
        shells=solid.geometry(static['instance_id'])[3]
        initial=not any(solid.inside(Vector(p),shells) for p in np.unique(a.reshape(-1,3),axis=0))
    return not unresolved and initial,{'continuous_lower_bound_m':worst,
        'required_m':required,'translation_m':list(travel),'initial_solids_disjoint':initial,
        'lower_facet_y_range_m':facet_region,'moving_triangles':len(a),
        'narrow_triangle_pairs':pairs,'unresolved_pairs':len(unresolved),'examples':unresolved[:8]}


def checks():
    result=[]
    objs=[o for o in bpy.context.scene.objects if o.type=='MESH' and o.get('component')=='foot']
    def record(name,ok,detail):result.append(Check(name,ok,detail))
    def near(name,actual,expected,tol=TOL):
        a=np.array(actual); e=np.array(expected); error=float(np.max(abs(a-e)))
        record(name,np.isfinite(a).all() and error<=tol+1e-6,{'measured':a.tolist(),'expected':e.tolist(),'max_error_m':error})
    def get(pid):return sorted([o for o in objs if o['part_id']==pid],key=lambda o:o['instance_id'])
    def vertices(o):return np.array([tuple(o.matrix_world@v.co) for v in o.data.vertices])
    def bounds(o):
        p=vertices(o);return p.min(axis=0),p.max(axis=0)
    def circle(name,o,center,axis,radius,span=None,clear=False,rim_chamfer=0):
        p=vertices(o); c=np.array(center); w=np.array(axis,dtype=float);w/=np.linalg.norm(w)
        ref=np.array([0,0,1] if abs(w[2])<.9 else [0,1,0]);u=np.cross(ref,w);u/=np.linalg.norm(u);v=np.cross(w,u)
        d=p-c; xy=np.column_stack((d@u,d@v)); z=d@w
        selected=abs(np.linalg.norm(xy,axis=1)-radius)<.002
        if span is not None:selected &= abs(z)<=span/2+.003
        q=xy[selected]
        record(name+' rim exists',len(q)>=12,{'rim_vertices':len(q)})
        if len(q)<12:return None
        A=np.column_stack((2*q,np.ones(len(q))));cx,cy,k=np.linalg.lstsq(A,(q*q).sum(axis=1),rcond=None)[0]
        axial_rim=selected
        if rim_chamfer:
            rad=np.linalg.norm(xy,axis=1)
            axial_rim=(rad>=radius-.002)&(rad<=radius+rim_chamfer+.002)&(abs(z)<=span/2+.003)
        axial=(z[axial_rim].min()+z[axial_rim].max())/2
        measured=c+u*cx+v*cy+w*axial
        near(name+' centre',measured,c)
        near(name+' diameter',2*math.sqrt(max(0,k+cx*cx+cy*cy)),2*radius)
        if span is not None:near(name+' span',z[axial_rim].max()-z[axial_rim].min(),span)
        if clear:
            inv=o.matrix_world.inverted(); direction=(inv.to_3x3()@Vector(w)).normalized();hits=[]
            for offset in (np.zeros(3),u*radius*.6,-u*radius*.6,v*radius*.6,-v*radius*.6):
                hit,point,normal,idx=o.ray_cast(inv@Vector(c+offset-w*(span/2+.001)),direction,distance=span+.002)
                if hit:hits.append(tuple(o.matrix_world@point))
            record(name+' clear bore',not hits,{'hits':hits})
        return measured
    counts=Counter((o['part_id'],o['part_name']) for o in objs)
    expected=Counter({(r['part_id'],r['name']):int(r['qty_per_leg']) for r in ROWS if (r['part_id'],r['name']) not in DEFERRED_ROWS})
    active=Counter({k:v for k,v in counts.items() if k not in DEFERRED_ROWS})
    record('FA02 complete row counts',active==expected,{'actual':sum(active.values()),'expected':sum(expected.values())})
    record('FA02 independent meshes',len({o.data.as_pointer() for o in objs})==len(objs),{'objects':len(objs)})
    if not get('FA-201'):return result+[Check('FA02 geometry exists',False,'Missing adapter')]
    for pid,axis,rad,centers,span in [
        ('FA-202',(1,0,0),.060,[(-.425,0,1),(.425,0,1)],.250),
        ('FA-203',(0,1,0),.050,[(0,-.235,1),(0,.235,1)],.250),
        ('FA-204',(1,0,0),.060,[(-.370,0,1),(.370,0,1)],.140),
        ('FA-205',(0,1,0),.050,[(0,-.160,1),(0,.160,1)],.100),
        ('FA-210',(1,0,0),.060,[(0,1.340,.350)],1.160),
        ('FA-211',(1,0,0),.060,[(-.380,1.340,.350),(.380,1.340,.350)],.140)]:
        for i,(o,c) in enumerate(zip(get(pid),centers)):circle(pid+str(i),o,c,axis,rad,span)
    adapter=get('FA-201')[0];p=vertices(adapter)
    flange=p[(p[:,2]>1.319)&(p[:,2]<1.381)&((abs(p[:,0])>.19)|(abs(p[:,1])>.14))]
    near('Adapter flange bounds',np.array([flange.min(axis=0),flange.max(axis=0)]),[[-.260,-.220,1.320],[.260,.220,1.380]])
    key=p[p[:,2]>1.3801];near('Adapter key top and plan',[*np.ptp(key,axis=0)[:2],key[:,2].max()],[.180,.100,1.400])
    for i,(x,y) in enumerate([(x,y) for x in (-.2,.2) for y in (-.15,.15)]):
        circle('Adapter bolt bore '+str(i),adapter,(x,y,1.350),(0,0,1),.018,.060,True)
        bolt=get('H-36090')[i];lo,hi=bounds(bolt)
        near('Shin bolt axis '+str(i),(lo+hi)[:2]/2,[x,y]);near('Shin bolt tip/head '+str(i),[lo[2],hi[2]],[1.326,1.452])
        head=vertices(bolt);head=head[(np.linalg.norm(head[:,:2]-[x,y],axis=1)>.020)]
        record('Shin bolt bearing above baseplate '+str(i),head[:,2].min()>=1.416-.0001,{'minimum_head_z':float(head[:,2].min())})
        washer=next(o for o in objs if o['instance_id']==bolt['paired_instance_id'])
        lo,hi=bounds(washer);near('Shin washer planes '+str(i),[lo[2],hi[2]],[1.410,1.416])
    schedules=[('Rear frame joints',[(-560,110), (1120,110),(0,220)]),('Forefoot frame joints',[(2350,90),(1590,90)])]
    for use,sites in schedules:
        actual=[]
        for o in objs:
            if o.get('hardware_use')==use and o['part_id']=='H-36140':
                lo,hi=bounds(o);actual.append((round((lo[0]+hi[0])/2,6),round((lo[1]+hi[1])/2,6),lo[2],hi[2]))
        expected_points=sorted([(s*.395,(y+dy)/1000,.296,.472) for y,spacing in sites for s in (-1,1) for dy in (-spacing/2,spacing/2)])
        near(use+' bolt axes and ends',sorted(actual),expected_points)
    # Measure the receiving lands as well as the matching fastener shafts.
    for pid,y,pitch in [('FA-101',-.560,.110),('FA-102',1.120,.110),
                         ('FA-103-L',0,.220),('FA-105',2.350,.090),('FA-106',1.590,.090)]:
        for sign in (-1,1):
            x=sign*.395
            rail_id=('FA-104-' if pid in {'FA-105','FA-106'} else 'FA-100-')+('A' if sign<0 else 'B')
            for dy in (-pitch/2,pitch/2):
                circle(pid+f' land bore {x} {dy}',get(pid)[0],(x,y+dy,.410),(0,0,1),.019,.040,True,rim_chamfer=.020)
                circle(rail_id+f' ledge bore {y} {dy}',get(rail_id)[0],(x,y+dy,.370),(0,0,1),.019,.040,True,rim_chamfer=.020)
                receiver=get(pid)[0];inv=receiver.matrix_world.inverted()
                hit,point,normal,index=receiver.ray_cast(inv@Vector((x+.026,y+dy,.600)),Vector((0,0,-1)),distance=.25)
                record(pid+f' washer seat exists {x} {dy}',hit,{})
                if hit:near(pid+f' washer seat plane {x} {dy}',(receiver.matrix_world@point).z,.430,.001)

    for pid in ('FA-101','FA-102','FA-105'):
        lo,hi=bounds(get(pid)[0]);near(pid+' transverse span',[lo[0],hi[0]],[-.650,.650])
    harness=get('FA-605-L')[0]
    plug_axis=np.array([.08,.05,.16]);plug_axis/=np.linalg.norm(plug_axis)
    circle('Main harness shin plug collar',harness,np.array([.250,.100,1.400])+plug_axis*.016,
           plug_axis,.016,.006)
    for pid,ys in [('FA-300',[-.670,.170,1.040]),('FA-301',[1.640,2.280])]:
        carrier=get(pid)[0]
        for x in (-.560,.560):
            for y in ys:circle(pid+f' carrier bore {x} {y}',carrier,(x,y,.186),(0,0,1),.013,.028,True)
        lo,hi=bounds(carrier);near(pid+' thickness',[lo[2],hi[2]],[.140,.200])
    # Bearings are symmetric actual solids; compare their fitted bore axes with
    # the corresponding pin and clevis rims, including the oblique roll basis.
    for kind,base,tip,r in [('P',(-.54,.8,.48),(-.54,.3,1),.025),
                            ('R',(.5,-.45,.85),(.2,-.45,1.32),.020),
                            ('F',(0,.79,.52),(0,1.4,.57),.020)]:
        d=np.array(tip)-base;d/=np.linalg.norm(d);axis=np.array([1.,0,0]);axis-=d*np.dot(d,axis);axis/=np.linalg.norm(axis)
        for i,c in enumerate((base,tip)):
            bearing=next(o for o in objs if o['part_id'].startswith('FA-526') and o['label']==f'{kind} Spherical eye bearing {i+1}')
            pin=next(o for o in objs if o['part_id'].startswith('FA-221') and o['label']==f'{kind} Eye pin {i+1}')
            clevis=next(o for o in objs if o['part_id'].startswith('FA-220') and o['label']==f'{kind} Clevis {i+1}')
            bc=circle(kind+str(i)+' eye',bearing,c,axis,r,.054 if kind=='P' else .039)
            pc=circle(kind+str(i)+' pin',pin,c,axis,r,.132 if kind=='P' else .097)
            cc=circle(kind+str(i)+' clevis',clevis,c,axis,r+.0004 if kind=='P' else r,.132 if kind=='P' else .097,True)
            if bc is not None and pc is not None:near(kind+str(i)+' eye/pin alignment',bc,pc)
            if bc is not None and cc is not None:near(kind+str(i)+' eye/clevis alignment',bc,cc)
    # P4B: independent measurements of the six pads and all 44 new fastener
    # stacks. Expected sites come from the written FA-02 schedule, not extras.
    def first_hit(o,start,direction,distance):
        inv=o.matrix_world.inverted()
        hit,p,normal,index=o.ray_cast(inv@Vector(start),(inv.to_3x3()@Vector(direction)).normalized(),distance=distance)
        return np.array(o.matrix_world@p) if hit else None
    for pid,y0,y1 in [('FA-302',-.850,-.110),('FA-303',-.070,1.220),('FA-304',1.480,2.440)]:
        for i,pad in enumerate(get(pid)):
            x0,x1=(-.695,-.025) if i==0 else (.025,.695)
            near(pid+f' pad {i} bounds',bounds(pad),[[x0,y0,0],[x1,y1,.140]],.001)
            carrier=get('FA-301' if pid=='FA-304' else 'FA-300')[0]
            for x in (x0+.100,x1-.100):
                for y in (y0+.100,y1-.100):
                    name=pid+f' pad seat {x} {y}'
                    circle(name+' counterbore',pad,(x,y,.032),(0,0,1),.028,.064,True)
                    circle(name+' carrier thread',carrier,(x,y,.170),(0,0,1),.012,.060,True)
                    sleeve=min(get('FA-305'),key=lambda o:np.linalg.norm((sum(bounds(o))/2)[:2]-[x,y]))
                    circle(name+' sleeve',sleeve,(x,y,.102),(0,0,1),.013,.076,True)
                    bolt=min(get('H-24120'),key=lambda o:np.linalg.norm((sum(bounds(o))/2)[:2]-[x,y]))
                    lo,hi=bounds(bolt)
                    near(name+' bolt axis and ends',[(lo[0]+hi[0])/2,(lo[1]+hi[1])/2,lo[2],hi[2]],[x,y,.036,.180],.001)
                    washer=next(o for o in objs if o['instance_id']==bolt['paired_instance_id'])
                    near(name+' washer planes',[bounds(washer)[0][2],bounds(washer)[1][2]],[.060,.064],.0001)
                    record(name+' physical owner',bolt.get('owner_instance')==pad['instance_id'] and sleeve.get('owner_instance')==pad['instance_id'],{})
            q=first_hit(pad,((x0+x1)/2,y0+.220,-.020),(0,0,1),.1)
            record(pid+f' groove {i} exists',q is not None,{})
            if q is not None:near(pid+f' groove {i} depth',q[2],.012,.001)
    def ztoe(y):return .600-(y-1.500)*(.080/.900)
    schedule=[('FA-400',[((x,y,ztoe(y)),(0,0,1)) for x in (-.560,.560) for y in (1.630,2.310)]),
              ('FA-401-L',[((x,y,.700),(0,0,1)) for x in (-.650,.650) for y in (-.300,1.060)]),
              ('FA-402',[((x,-.900,z),(0,-1,0)) for x in (-.560,.560) for z in (.300,.500)]),
              ('FA-403-L',[((.730,y,z),(1,0,0)) for y,z in ((-.600,.720),(.700,.720),(-.500,1.450),(.500,1.450))]),
              ('FA-404-L',[((-.730,y,z),(-1,0,0)) for y,z in ((-.600,.720),(.700,.720),(-.500,1.450),(.500,1.450))])]
    for pid,sites in schedule:
        shell=get(pid)[0];lo,hi=bounds(shell)
        expected_height=1.600 if pid in {'FA-403-L','FA-404-L'} else .700 if pid=='FA-401-L' else .600
        near(pid+' top',hi[2],expected_height,.001)
        record(pid+' lateral envelope',lo[0]>=-.7301 and hi[0]<=.7301,{'min_x':float(lo[0]),'max_x':float(hi[0])})
        fasteners=[o for o in get('H-12050-C') if o.get('owner_instance')==shell['instance_id']]
        collars=[o for o in get('FA-405') if o.get('owner_instance')==shell['instance_id']]
        record(pid+' four complete captive mounts',len(fasteners)==len(collars)==4,{})
        for j,(p,n) in enumerate(sites):
            p=np.array(p);n=np.array(n);name=pid+f' shell mount {j}'
            if pid in {'FA-400','FA-401-L','FA-402'}:
                receiver=get(('FA-104-' if pid=='FA-400' else 'FA-100-')+('A' if p[0]<0 else 'B'))[0]
            else:receiver=get('FA-103-L')[0]
            circle(name+' land',shell,p-n*.029,n,.0065,.026,True)
            circle(name+' receiver',receiver,p-n*.059,n,.006,.026,True)
            bolt=min(fasteners,key=lambda o:np.linalg.norm((sum(bounds(o))/2)-p))
            v=vertices(bolt)-p
            axial=v@n;radial=np.linalg.norm(v-n[None,:]*axial[:,None],axis=1)
            near(name+' shaft and head',[axial.min(),axial.max()],[-.0635,-.0015],.001)
            axis=(vertices(bolt).min(axis=0)+vertices(bolt).max(axis=0))/2
            near(name+' coaxial',np.cross(axis-p,n),[0,0,0],.001)
            head=axial[radial>.0065];near(name+' under-head',head.min(),-.0135,.001)
            washer=next(o for o in objs if o['instance_id']==bolt['paired_instance_id'])
            axial=(vertices(washer)-p)@n
            near(name+' washer', [axial.min(),axial.max()],[-.016,-.0135],.0001)
            collar=min(collars,key=lambda o:np.linalg.norm((sum(bounds(o))/2)-p))
            circle(name+' collar',collar,p-n*.044,n,.006,.004,True)
            tangent=np.cross(n,[0,1,0] if abs(n[1])<.9 else [1,0,0])*.011
            for target,label,depth in [(shell,'washer seat',.016),(receiver,'thread seat',.046)]:
                q=first_hit(target,p+tangent+n*.040,-n,.150)
                record(name+' '+label+' exists',q is not None,{})
                if q is not None:near(name+' '+label+' plane',np.dot(q-p,n),-depth,.001)
    # Cache neutral bounds once for pitch-cap visibility's broad phase.
    cap_occluders=[(o,*bounds(o)) for o in objs]
    # Check an actual central open corridor, including both guard objects.
    for pid in ('FA-403-L','FA-404-L'):
        guard=get(pid)[0];v=vertices(guard)
        record(pid+' lateral wall / no roof',np.min(abs(v[:,0]))>=.679,{'innermost_x':float(np.min(abs(v[:,0])))})
        s=1 if pid=='FA-403-L' else -1
        # P6F1: measure the cut wall itself, independently of generator datums.
        rim=v[(abs(v[:,1])<=.2001)&(abs(v[:,2]-1)<=.1801)&(abs(v[:,0])>.7099)]
        record(pid+' access window rim exists',len(rim)>=16,{'vertices':len(rim)})
        if len(rim):
            near(pid+' access window bounds',[rim[:,1:].min(0),rim[:,1:].max(0)],
                 [[-.200,.820],[.200,1.180]],.0002)
            near(pid+' access window wall thickness',np.ptp(abs(rim[:,0])),.020,.0002)
            for y,z in [(-.140,.820),(.140,.820),(.200,.880),(.200,1.120),
                        (.140,1.180),(-.140,1.180),(-.200,1.120),(-.200,.880)]:
                distance=np.linalg.norm(rim[:,1:]-[y,z],axis=1).min()
                near(pid+f' window 60 mm chamfer {y} {z}',distance,0,.0002)
        blocked=[]
        for y in np.linspace(-.198,.198,9):
            for z in np.linspace(.822,1.178,9):
                if abs(y)+abs(z-1)>.318:continue
                if first_hit(guard,(s*.800,y,z),(-s,0,0),.115) is not None:
                    blocked.append([float(y),float(z)])
        record(pid+' access window through wall',not blocked,{'blocked_samples':blocked})
        for y,z in [(-.190,.830),(.190,.830),(-.190,1.170),(.190,1.170)]:
            record(pid+f' window chamfer retains corner {y} {z}',
                   first_hit(guard,(s*.800,y,z),(-s,0,0),.115) is not None,{})
        # F7: the new crown must retain the complete window return, not just
        # its open centre. Probe the surrounding skin from both sides.
        for y,z in ((0,.808),(0,1.192),(-.212,1),(.212,1),
                    (-.180,.840),(.180,.840),(-.180,1.160),(.180,1.160)):
            front=first_hit(guard,(s*.800,y,z),(-s,0,0),.115)
            back=first_hit(guard,(s*.680,y,z),(s,0,0),.115)
            record(pid+f' window retained surrounding skin {y} {z}',
                   front is not None and back is not None,{})
            if front is not None and back is not None:
                near(pid+f' window surrounding 20 mm wall {y} {z}',
                     abs(front[0]-back[0]),.020,.0002)
        for y,z in ((-.730,1.050),(-.600,1.500),(-.160,1.600),
                    (.160,1.600),(.600,1.500),(.850,1.090)):
            near(pid+f' tapered crown vertex {y} {z}',
                 np.linalg.norm(v[:,1:]-[y,z],axis=1).min(),0,.0002)
        crown=v[v[:,2]>1.5999]
        near(pid+' flat crown length',np.ptp(crown[:,1]),.320,.0002)
        for y,z in ((-.380,1.550),(.380,1.550),(-.665,1.275),(.725,1.295)):
            record(pid+f' crown outside clear {y} {z}',
                   first_hit(guard,(s*.800,y,z+.010),(-s,0,0),.115) is None,{})
            record(pid+f' crown inside retained {y} {z}',
                   first_hit(guard,(s*.800,y,z-.010),(-s,0,0),.115) is not None,{})
        cap=min(get('FA-208'),key=lambda o:abs(sum(bounds(o))[0]/2-s*.585))
        visible=[];obstructed=[]
        samples=[(0,1)]+[(.060*math.cos(t),1+.060*math.sin(t))
                        for t in np.linspace(0,math.tau,8,endpoint=False)]
        for y,z in samples:
            start=(s*.800,y,z);direction=(-s,0,0)
            hit=first_hit(cap,start,direction,.250)
            if hit is None:continue
            visible.append([float(y),float(z)])
            distance=abs(start[0]-hit[0])-.0005
            for obj,lo,hi in cap_occluders:
                if obj==cap:continue
                if not (lo[1]<=y<=hi[1] and lo[2]<=z<=hi[2]):continue
                if (s>0 and hi[0]<hit[0]) or (s<0 and lo[0]>hit[0]):continue
                q=first_hit(obj,start,direction,distance)
                if q is not None:obstructed.append({'part_id':obj['part_id'],'point':q.tolist()})
        record(pid+' pitch cap visible through installed assembly',len(visible)==9 and not obstructed,
               {'cap_samples':len(visible),'obstructions':obstructed})
        clear,detail=translation_clearance(cap,guard,travel=(s*.300,0,0))
        record(pid+' window clears actual pitch cap extraction',clear,detail)
        near(pid+' independent lateral removal',list(guard['removal_direction']),[s,0,0],.0001)
        # The facets stay within the specified wall; sample a plain crown edge.
        q=first_hit(guard,(s*.800,0,1.570),(-s,0,0),.120)
        record(pid+' broad perimeter facet exists',q is not None,{})
        if q is not None:near(pid+' crown facet relief',abs(q[0]),.72625,.0003)
        for y,z in ((-.600,.720),(.700,.720),(-.500,1.450),(.500,1.450)):
            q=first_hit(guard,(s*.800,y,z+.032),(-s,0,0),.120)
            record(pid+f' octagonal recessed land {y} {z}',q is not None and .714<abs(q[0])<.728,
                   {'hit':q.tolist() if q is not None else None})
            # F8: measure the sloped depression beside the bore and skin just
            # outside its new 80 mm mouth. Upper wells can meet a crown facet.
            for dy in (-.035,.035):
                q=first_hit(guard,(s*.800,y+dy,z),(-s,0,0),.120)
                record(pid+f' small well slope {y} {z} {dy}',q is not None,{})
                if q is not None:
                    near(pid+f' small well profile {y} {z} {dy}',abs(q[0]),
                         .714+.016*(.035-.02795)/(.040-.02795),.0003)
            for dy in (-.045,.045):
                q=first_hit(guard,(s*.800,y+dy,z),(-s,0,0),.120)
                record(pid+f' skin outside small well {y} {z} {dy}',
                       q is not None and abs(q[0])>.727,{'hit':q.tolist() if q is not None else None})
    # Rays cross the former triangular daylight at roof/side junctions. These
    # are within each shell and deliberately outside the open hinge channel.
    for pid,y,z in [('FA-400',2.390,.452),('FA-401-L',1.180,.630),('FA-402',-.850,.515)]:
        for s in (-1,1):
            q=first_hit(get(pid)[0],(s*.800,y,z),(-s,0,0),.200)
            record(pid+f' continuous folded corner {s}',q is not None,
                   {'hit':q.tolist() if q is not None else None})
    upper=get('FA-401-L')[0]
    # F6: independent section rays verify both shoulder folds, retained flat
    # roof and actual 20 mm skin away from lands, grooves and receiver slots.
    toe=get('FA-400')[0]
    for pid,y,crease,drop,zroof in (('FA-400',2.000,.610,.090,ztoe(2.000)),
                                  ('FA-401-L',.950,.650,.100,.700)):
        shell=get(pid)[0];slope=drop/(.730-crease)
        for s in (-1,1):
            for x in (0,crease-.010,crease+.025,.725):
                expected=zroof-max(0,x-crease)*slope
                q=first_hit(shell,(s*x,y,.800),(0,0,-1),.500)
                record(pid+f' shoulder section exists {s} {x}',q is not None,{})
                if q is not None:near(pid+f' shoulder section {s} {x}',q[2],expected,.0002)
            x=crease+.035
            centre=np.array([s*x,y,zroof-(x-crease)*slope])
            normal=np.array([s*slope,.080/.900 if pid=='FA-400' else 0,1])
            normal/=np.linalg.norm(normal)
            outer=first_hit(shell,centre+normal*.050,-normal,.100)
            inner=first_hit(shell,centre-normal*.050,normal,.100)
            record(pid+f' shoulder has both skins {s}',outer is not None and inner is not None,{})
            if outer is not None and inner is not None:
                near(pid+f' shoulder 20 mm skin {s}',np.linalg.norm(outer-inner),.020,.0003)
    near('Upper flat central underside',first_hit(upper,(0,.950,.600),(0,0,1),.150)[2],.680,.0002)
    for x in (0,-.670,.670):
        normal=np.array([0 if x==0 else math.copysign(.75,x),.080/.900,1])
        normal/=np.linalg.norm(normal)
        centre=np.array([x,2.240,ztoe(2.240)-max(0,abs(x)-.610)*.75])
        floor=first_hit(toe,centre+normal*.030,-normal,.100)
        back=first_hit(toe,centre-normal*.040,normal,.080)
        record(f'Toe nose score floor and backing {x}',floor is not None and back is not None,{})
        if floor is not None and back is not None:
            near(f'Toe nose score depth {x}',np.dot(centre-floor,normal),.004,.0002)
            near(f'Toe nose score retained skin {x}',np.dot(floor-back,normal),.016,.0003)
    for s in (-1,1):
        for z,expected in ((.299,.730),(.301,.726),(.350,.726),(.420,.726)):
            q=first_hit(toe,(s*.800,2.240,z),(-s,0,0),.120)
            record(f'Toe nose score side floor {s} {z}',q is not None,{})
            if q is not None:near(f'Toe nose score side depth/end {s} {z}',abs(q[0]),expected,.0004)
    for y,recess in ((2.2265,False),(2.2285,True),(2.2515,True),(2.2535,False)):
        q=first_hit(toe,(0,y,.700),(0,0,-1),.250)
        record(f'Toe nose score width sample {y}',q is not None,{})
        if q is not None:near(f'Toe nose score width/depth {y}',q[2],
                             ztoe(y)-(.004*math.sqrt(1+(.080/.900)**2) if recess else 0),.0002)
    inv=toe.matrix_world.inverted()
    hit,point,normal,index=toe.ray_cast(inv@Vector((0,2.240,.700)),Vector((0,0,-1)),distance=.250)
    record('Toe nose score dark floor',hit and toe.data.materials[toe.data.polygons[index].material_index].name=='LG01 Gunmetal',
           {'material':toe.data.materials[toe.data.polygons[index].material_index].name if hit else None})
    clear,detail=translation_clearance(upper,get('FA-103-L')[0])
    record('Upper plate clears cradle throughout full +Z descent',clear,detail)
    # Independently measure the two preserved upper locators and their sockets.
    # The clear bore itself is only 0.5 mm around the intended 10 mm engagement;
    # it is a mating feature, not part of the unrelated cradle-clearance check.
    from verify_sequence import MeshClearance
    features=MeshClearance()
    # F6: the two toe locators follow the lowered shoulder, with intact socket
    # walls moved inboard of the side skin. Test the actual receiving solids,
    # excluding the tab's intentional engagement with its own socket.
    toe_body=max(features.geometry(toe['instance_id'])[3],
                 key=lambda f:np.prod(np.array(f[1])-f[0]))
    for s in (-1,1):
        x=s*.680;y=1.850;z=.4728888889
        tab=min(features.geometry(toe['instance_id'])[3],
                key=lambda f:np.linalg.norm((np.array(f[0])+f[1])/2-[x,y,z]))
        near(f'Toe locator {s} actual bounds',[tab[0],tab[1]],
             [[x-.016,y-.008,z-.020],[x+.016,y+.008,z+.020]],.0001)
        rail=get('FA-104-'+('A' if s<0 else 'B'))[0]
        socket=min(features.geometry(rail['instance_id'])[3],
                   key=lambda f:np.linalg.norm((np.array(f[0])+f[1])/2-[x,y,z-.015]))
        near(f'Toe locator {s} socket bounds',[socket[0],socket[1]],
             [[x-.025,y-.017,z-.020],[x+.025,y+.017,z-.010]],.0001)
        near(f'Toe locator {s} engagement',min(tab[1][2],socket[1][2])-max(tab[0][2],socket[0][2]),.010,.0001)
        overlaps=toe_body[3].overlap(socket[3])
        contained=features.inside(socket[2],[toe_body]) or features.inside(toe_body[2],[socket])
        record(f'Toe skin clears locator socket {s}',not overlaps and not contained,
               {'triangle_contacts':len(overlaps),'containment':contained})
        for label,start,direction,minimum in (
                ('side',(s*.705,y,z-.015),(s,0,0),.0049),
                ('roof',(s*.705,y,z-.010),(0,0,1),.009)):
            point,normal,index,distance=toe_body[3].ray_cast(Vector(start),Vector(direction),.100)
            record(f'Toe locator socket {s} {label} clearance',point is not None and distance>=minimum,
                   {'distance_m':distance,'minimum_m':minimum})
    for s in (-1,1):
        x=s*.690;y=1.100
        tab=min(features.geometry(upper['instance_id'])[3],
                key=lambda f:np.linalg.norm((np.array(f[0])+f[1])/2-[x,y,.654]))
        near(f'Upper locator {s} actual bounds',[tab[0],tab[1]],
             [[x-.016,y-.008,.634],[x+.016,y+.008,.674]],.0001)
        rail=get('FA-100-'+('A' if s<0 else 'B'))[0]
        socket=min(features.geometry(rail['instance_id'])[3],
                   key=lambda f:np.linalg.norm((np.array(f[0])+f[1])/2-[x,y,.639]))
        near(f'Upper locator {s} socket bounds',[socket[0],socket[1]],
             [[x-.025,y-.017,.634],[x+.025,y+.017,.644]],.0001)
        near(f'Upper locator {s} engagement',min(tab[1][2],socket[1][2])-max(tab[0][2],socket[0][2]),.010,.0001)
    # F4: solid skin normals/thickness and inset measured away from relief slots.
    for pid,y in [('FA-400',2.000),('FA-401-L',.950)]:
        shell=get(pid)[0]
        for s in (-1,1):
            for z,expected in ((.210,.703),(.250,.715),(.300,.730),(.350,.730)):
                q=first_hit(shell,(s*.800,y,z),(-s,0,0),.180)
                record(pid+f' lower facet {s} {z}',q is not None,{})
                if q is not None:near(pid+f' lower facet profile {s} {z}',abs(q[0]),expected,.0003)
            normal=np.array([s,0,-.3]);normal/=np.linalg.norm(normal)
            centre=np.array([s*.715,y,.250])
            outer=first_hit(shell,centre+normal*.050,-normal,.100)
            inner=first_hit(shell,centre-normal*.050,normal,.100)
            record(pid+f' lower facet has both skins {s}',outer is not None and inner is not None,{})
            if outer is not None and inner is not None:
                near(pid+f' lower facet 20 mm skin {s}',np.linalg.norm(outer-inner),.020,.0003)
            rail=get(('FA-104-' if pid=='FA-400' else 'FA-100-')+('A' if s<0 else 'B'))[0]
            # Shell lands and tabs intentionally mate with rail receivers. F4's
            # lower skin is checked independently against the frame below Z300.
            region=(1.600,2.360) if pid=='FA-400' else (-.420,1.130)
            clear,detail=translation_clearance(shell,rail,travel=(0,0,0),facet_region=region)
            record(pid+f' inset lower skin clears frame {s}',clear,detail)
    for y in (-.500,-.250,0,.250,.530):
        record('Upper rear-open notch '+str(y),first_hit(upper,(0,y,.800),(0,0,-1),.5) is None,{})
    record('Upper actuator relief',first_hit(upper,(-.535,.710,.800),(0,0,-1),.5) is None,{})
    for pid in ('FA-400','FA-401-L'):
        lo,hi=bounds(get(pid)[0]);record(pid+' leaves hinge channel open',lo[1]>=1.499 if pid=='FA-400' else hi[1]<=1.211,{})
    # Sample the actual neighboring shin/calf meshes through the specified
    # pitch/roll range, testing triangle intersection with both guard walls.
    # This is explicitly a sampled sweep (2-degree pitch/roll increments).
    from mathutils import Matrix
    from mathutils.bvhtree import BVHTree
    guard_trees=[BVHTree.FromPolygons([Vector(v) for v in vertices(get(pid)[0])],
                 [tuple(f.vertices) for f in get(pid)[0].data.polygons],epsilon=.0001)
                 for pid in ('FA-403-L','FA-404-L','FA-103-L')]
    shin=[o for o in bpy.context.scene.objects if o.type=='MESH' and o.get('part_id') in {'LG-150','LG-400','LG-410','LG-415','LG-420'}]
    collisions=[];poses=0
    if shin:
        # Higher vertices cannot enter the 1.6 m guard box; retain crossing
        # triangles by selecting faces with at least one vertex below 2.15 m.
        meshsets=[]
        for o in shin:
            verts=vertices(o);faces=[tuple(f.vertices) for f in o.data.polygons if min(verts[k,2] for k in f.vertices)<2.15]
            used=sorted({k for f in faces for k in f});remap={k:i for i,k in enumerate(used)}
            meshsets.append((verts[used],[[remap[k] for k in f] for f in faces]))
        c=np.array([0,0,1.])
        for pitch in range(-20,21,2):
            for roll in range(-10,11,2):
                poses+=1
                rot=np.array(Matrix.Rotation(math.radians(-pitch),3,'X')@Matrix.Rotation(math.radians(roll),3,'Y'))
                for verts,faces in meshsets:
                    moved=(verts-c)@rot.T+c
                    tree=BVHTree.FromPolygons([Vector(v) for v in moved],faces,epsilon=.0001)
                    if any(tree.overlap(guard) for guard in guard_trees):collisions.append((pitch,roll));break
        record('Guards and receiver arms clear sampled actual shin sweep',not collisions,{'poses':poses,'collisions':collisions,'pitch_step_deg':2,'roll_step_deg':2})
    else:record('Guard default without leg geometry',all(np.min(abs(vertices(get(pid)[0])[:,0]))>=.700 for pid in ('FA-403-L','FA-404-L')),{'shin_geometry_present':False})

    allp=np.concatenate([vertices(o) for o in objs]);lo=allp.min(axis=0);hi=allp.max(axis=0)
    record('Foot stays above ground',lo[2]>=-.010,{'min_z':float(lo[2])})
    record('Foot within FA02 neutral envelope',lo[0]>=-.740 and hi[0]<=.740 and lo[1]>=-.910 and hi[1]<=2.470 and hi[2]<=1.610,{'min':lo.tolist(),'max':hi.tolist()})
    triangles=0
    for o in objs:o.data.calc_loop_triangles();triangles+=len(o.data.loop_triangles)
    record('Foot triangle budget',triangles<=800000,{'triangles':triangles,'limit':800000})
    return result
