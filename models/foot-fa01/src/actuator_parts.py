from geometry import *
import math

GROUP="04 Actuators"
ACTUATORS={}


def spherical_bearing(center, axis, radius, bore_radius, width):
    u,v,w=frame(axis); c=vec(center)
    n=32
    levels=[-width/2,-width/4,0,width/4,width/2]
    outer=[math.sqrt(max(radius*radius-z*z,bore_radius*bore_radius+1)) for z in levels]
    vs=[]
    for z,r in zip(levels,outer):
        vs.extend(c+w*z+(u*math.cos(i*2*math.pi/n)+v*math.sin(i*2*math.pi/n))*r for i in range(n))
    for z in (levels[0],levels[-1]):
        vs.extend(c+w*z+(u*math.cos(i*2*math.pi/n)+v*math.sin(i*2*math.pi/n))*bore_radius for i in range(n))
    fs=[]
    for ring in range(4):
        for i in range(n):
            j=(i+1)%n
            fs.append((ring*n+i,ring*n+j,(ring+1)*n+j,(ring+1)*n+i))
    for i in range(n):
        j=(i+1)%n
        fs += [(i,5*n+i,5*n+j,j),(4*n+i,4*n+j,6*n+j,6*n+i),
               (5*n+i,6*n+i,6*n+j,5*n+j)]
    return Mesh().add(vs,fs)


def build_one(kind, base, rod_eye, od, barrel_length, guide, rod_radius, rod_length, pin_dia, ex):
    b=vec(base); tip=vec(rod_eye); d=(tip-b).normalized()
    # Local X is the crosswise eye-pin axis; local Z is extension direction.
    u=Vector((1,0,0))
    if abs(d.dot(u))>.05: u=(u-d*d.dot(u)).normalized()
    v=d.cross(u).normalized()
    basis=(u,v,d)
    L=(tip-b).length
    radius=od/2
    start=guide-20-barrel_length
    end=start+barrel_length
    caprad=radius
    bolt_r=60 if kind=="P" else 44
    phase=7.0
    ACTUATORS[kind]={"base":list(base),"tip":list(rod_eye),"axis":list(d),"basis":[list(t) for t in basis],
                     "length":L,"explosion":ex}
    local_parts=[]

    def world(p):return b+u*p[0]+v*p[1]+d*p[2]
    def part(pid,label,m,zphase,offset=(0,0,0),materials=("Steel",),bevel=1):
        m.transform(b,basis)
        o=emit(pid,f"{kind}_{label}",m,GROUP,zphase,
               vec(ex)+u*offset[0]+v*offset[1]+d*offset[2],materials,bevel)
        o["actuator"]=kind
        local_parts.append(o)
        return o
    def bolts(use,points,zphase,direction=(0,0,-1),offset=(0,0,0),owner=None):
        a=u*direction[0]+v*direction[1]+d*direction[2]
        before=len(PARTS)
        hardware(use,[world(p) for p in points],a,zphase,
                 vec(ex)+u*offset[0]+v*offset[1]+d*offset[2],owner=owner)
        for o in PARTS[before:]:o["actuator"]=kind

    radial=[(bolt_r*math.cos(i*math.pi/2),bolt_r*math.sin(i*math.pi/2)) for i in range(4)]
    m=Mesh().tube((0,0,(start+end)/2),radius,radius-9,barrel_length)
    for x,y in radial:
        for z in (start+18,end-18):m.cyl((x,y,z),8,36)
    body=part("FA-510","Barrel",m,7.0,(0,0,0),("Frame",),1)
    part("FA-511","Front_cap",Mesh().tube((0,0,end+10),caprad,rod_radius+1,20),
         7.75,(0,0,310))
    part("FA-512","Rear_cap",Mesh().cyl((0,0,start-10),caprad,20),
         7.05,(0,0,-350))

    motor_z=100 if kind=="P" else 75
    motor_len=80 if kind=="P" else 50
    motor_r=46 if kind=="P" else 35
    m=Mesh().cyl((0,0,motor_z),motor_r,motor_len)
    m.cyl((0,0,motor_z+motor_len/2),motor_r+5,8)
    for i in range(12):
        a=i*math.pi/6
        x,y=(motor_r+1)*math.cos(a),(motor_r+1)*math.sin(a)
        m.box((x,y,motor_z),(5,5,motor_len-8))
    m.cyl((0,0,motor_z-motor_len/2-5),15,10,mat=1)
    part("FA-513","Motor_with_encoder",m,7.1,(0,240,-120),("Frame","Indicator"),1)
    gz=165 if kind=="P" else 120
    gl=50 if kind=="P" else 40
    m=Mesh().cyl((0,0,gz),motor_r+1,gl)
    for z in (gz-gl/2,gz+gl/2):m.cyl((0,0,z),motor_r+5,5)
    part("FA-514","Reduction_gearbox",m,7.15,(0,300,-80),("Steel",),1)
    cz=202 if kind=="P" else 150
    part("FA-515","Clamp_coupling",Mesh().tube((0,0,cz),25 if kind=="P" else 20,12,24),
         7.2,(0,360,-30),("Steel",),.8)
    bz=225 if kind=="P" else 170
    part("FA-522","Thrust_bearing_cartridge",Mesh().tube((0,0,bz),35 if kind=="P" else 27,20 if kind=="P" else 15,22),
         7.22,(0,420,30),("Steel",),.8)
    part("FA-523","Bearing_retainer",Mesh().tube((0,0,bz+14),42 if kind=="P" else 35,22 if kind=="P" else 17,6),
         7.24,(0,480,60),("Steel",),.5)
    screw_r=20 if kind=="P" else 15
    screw_start=bz-10
    screw_end=end-12
    m=Mesh().cyl((0,0,(screw_start+screw_end)/2),screw_r*.86,screw_end-screw_start)
    m.helical_thread((0,0,screw_start+10),(0,0,1),screw_r,screw_end-screw_start-20,10 if kind=="P" else 8,2.5)
    part("FA-516","Lead_screw",m,7.3,(0,-290,0),("Pin",),0)

    rear=L-30-rod_length
    nut_z=rear-17
    m=Mesh().tube((0,0,nut_z),rod_radius, screw_r+.3,34,n=6)
    nut=part("FA-517","Travelling_nut",m,7.35,(0,-370,80),("Bronze",),1)
    m=Mesh().tube((0,0,(rear+L-30)/2),rod_radius,screw_r+4,rod_length)
    m.tube((0,0,rear+10),rod_radius+2,screw_r+4,20)
    output=part("FA-518","Hollow_output_rod",m,7.4,(0,0,230),("Pin",),1)
    part("FA-519","Front_guide_bushing",Mesh().tube((0,0,guide-12),rod_radius+7,rod_radius+.4,24),
         7.65,(0,0,390),("Bronze",),.6)
    part("FA-520","Rod_wiper",Mesh().tube((0,0,guide+2),rod_radius+6,rod_radius-.2,5),
         7.8,(0,0,450),("Rubber",),.4)
    key_y=rod_radius+1
    part("FA-521","Antirotation_key",Mesh().box((0,key_y,(start+end)/2),(8,8,barrel_length*.45)),
         7.5,(0,570,0),("Bronze",),.6)
    for i,s in enumerate((-1,1)):
        # Each collar half is its own semicircular mesh.
        m=Mesh()
        n=20;vs=[]
        for z,r in [(bz-16,screw_r+9),(bz-8,screw_r+9),(bz-16,screw_r),(bz-8,screw_r)]:
            for j in range(n+1):
                a=(0 if s==1 else math.pi)+j*math.pi/n
                vs.append((r*math.cos(a),r*math.sin(a),z))
        nn=n+1;fs=[]
        for j in range(n):
            fs += [(j,j+1,j+1+nn,j+nn),(j+2*nn,j+3*nn,j+1+3*nn,j+1+2*nn),
                   (j,j+2*nn,j+1+2*nn,j+1),(j+nn,j+1+nn,j+1+3*nn,j+3*nn)]
        fs += [(0,nn,3*nn,2*nn),(n,n+2*nn,n+3*nn,n+nn)]
        m.add(vs,fs)
        part("FA-524",f"Shaft_collar_half_{i+1}",m,7.25,(s*200,450,0),("Steel",),.3)

    eye_width=60 if kind=="P" else 45
    bearing_R=44 if kind=="P" else 34
    eye_outer=52 if kind=="P" else 42
    for index,z in enumerate((0,L)):
        off=(0,0,-470 if index==0 else 560)
        m=Mesh().tube((0,0,z),eye_outer,bearing_R*.82,eye_width,(1,0,0))
        m.box((0,0,z+(30 if index==0 else -30)),(eye_width,35,30))
        eye=part("FA-525",f"Eye_housing_{index+1}",m,7.85,off,("Frame",),2)
        bearing=spherical_bearing((0,0,z),(1,0,0),bearing_R,pin_dia/2,eye_width-6)
        part("FA-526",f"Spherical_eye_bearing_{index+1}",bearing,7.88,
             (110,0,off[2]),("Pin",),.5)
        part("FA-527",f"Eye_retaining_ring_{index+1}",
             Mesh().tube((eye_width/2+1,0,z),bearing_R*.85,pin_dia/2+2,3,(1,0,0)),
             7.9,(180,0,off[2]),("Steel",),.3)
        # Two eye bolts per housing; they enter along the actuator axis.
        points=[(-eye_width*.3,0,z+(45 if index==0 else -45)),
                (eye_width*.3,0,z+(45 if index==0 else -45))]
        bolts("Actuator eye housings",points,7.92,
              direction=(0,0,-1 if index==0 else 1),offset=off,owner=eye)
    for i,z in enumerate((start+40,end-40)):
        sensor=part("FA-528",f"End_sensor_{i+1}",
                    Mesh().box((radius-14,0,z),(12,20,20)).cyl((radius-6,0,z),4,4,(1,0,0),mat=1),
                    7.6,(180+i*70,-200,0),("Frame","Indicator"),1)
        bolts("Actuator end sensors",[(radius-5,0,z)],7.62,direction=(-1,0,0),
              offset=(260+i*70,-200,0),owner=sensor)
    for i,z in enumerate((start-1,end+1)):
        part("FA-529",f"Cap_gasket_{i+1}",Mesh().tube((0,0,z),radius,radius-6,2),
             7.7,(0,0,-280 if i==0 else 280),("Rubber",),0)
    socket=part("FA-530","Keyed_connector",
                Mesh().tube((radius+10,0,start+80),14,8,24,(1,0,0)).cyl((radius-2,0,start+80),18,4,(1,0,0)),
                7.6,(300,-100,0),("Steel",),.7)
    ACTUATORS[kind]["socket"] = list(world((radius+22,0,start+80)))

    for z,sgn in [(start-22,1),(end+22,-1)]:
        bolts("Actuator front and rear caps",[(x,y,z) for x,y in radial],7.82,
              direction=(0,0,sgn),offset=(0,0,-390 if sgn==1 else 420))
    r1=motor_r*.65
    for use,z,delta in [("Motor flanges",motor_z-motor_len/2-3,-150),
                        ("Gearbox flanges",gz-gl/2-3,-40)]:
        bolts(use,[(r1*math.cos(a*math.pi/2),r1*math.sin(a*math.pi/2),z) for a in range(4)],
              7.18,direction=(0,0,1),offset=(0,320,delta))
    bolts("Actuator coupling clamps",[(26 if kind=="P" else 21,y,cz) for y in (-6,6)],
          7.23,direction=(-1,0,0),offset=(200,360,0))
    bolts("Travelling nut to output rod",[(-rod_radius*.65,0,rear+25),(rod_radius*.65,0,rear+25)],
          7.45,offset=(0,-370,150),owner=nut)
    bolts("Actuator bearing retainer plates",[(-30 if kind=="P" else -24,0,bz+20),
                                               (30 if kind=="P" else 24,0,bz+20)],
          7.27,offset=(0,480,120))
    bolts("Actuator split shaft collars",[(0,s*(screw_r+10),bz-12) for s in (-1,1)],
          7.28,direction=(0,-1,0),offset=(0,500,20))
    bolts("Actuator antirotation guides",[(0,key_y+5,start+barrel_length*.35),
                                         (0,key_y+5,start+barrel_length*.65)],
          7.55,direction=(0,-1,0),offset=(0,650,0))

    # Six separately modeled clevis brackets, pins, and keeper plates.
    for index,p in enumerate((b,tip)):
        ear=35 if kind=="P" else 25
        inner=eye_width+2
        span=inner+2*ear
        support=p-d*(65 if index==0 else -65)
        cm=Mesh().box((0,0,-65 if index==0 else 65),(span+30,120,30))
        for s in (-1,1):
            cm.box((s*(inner+ear)/2,0,(-25 if index==0 else 25)),(ear,90,65))
            cm.tube((s*(inner+ear)/2,0,0),45 if kind=="P" else 35,pin_dia/2,ear,(1,0,0))
        cm.transform(p,basis)
        anchors={
            ("P",0):((-540,800,465),(0,0,1)),
            ("P",1):((-370,300,1075),(0,0,1)),
            ("R",0):((370,-290,1075),(0,0,1)),
            ("R",1):((100,-145,1230),(0,-1,0)),
            ("F",0):((0,980,435),(0,0,1)),
            ("F",1):((0,1320,495),(0,0,1)),
        }
        anchor,normal=anchors[(kind,index)]
        anchor=vec(anchor); normal=vec(normal)
        mount_basis=(Vector((1,0,0)), normal.cross(Vector((1,0,0))), normal)
        cm.beam(support,anchor,60)
        cm.box(anchor,(120,120,30),basis=mount_basis)
        clevis=emit("FA-220",f"{kind}_Clevis_{index+1}",cm,GROUP,8,
                    vec(ex)+u*(-250 if index==0 else 250),("Frame",),3)
        bore(clevis,[(p,pin_dia/2,span+10,u)])
        pts=[anchor+Vector((s*40,0,0))+normal*19 for s in (-1,1)]
        bore(clevis,[(q,12.5,80,normal) for q in pts])
        hardware("Actuator clevis mounts",pts,-normal,8.1,
                 vec(ex)+u*(-450 if index==0 else 450),owner=clevis)
        m=Mesh().cyl(p,pin_dia/2,span,u)
        m.cyl(p-u*(span/2+5),pin_dia*.66,10,u)
        pin=emit("FA-221",f"{kind}_Eye_pin_{index+1}",m,GROUP,8.3,
                 vec(ex)-u*650,("Pin",),.8)
        keeper_center=p+u*(span/2+5)
        keeper=emit("FA-222",f"{kind}_Pin_keeper_{index+1}",
                    Mesh().box(keeper_center,(10,45,60),basis=(u,v,d)),GROUP,8.4,
                    vec(ex)+u*650,("Steel",),1)
        hardware("Actuator attachment pin keepers",[keeper_center+u*7],-u,8.5,
                 vec(ex)+u*760,owner=keeper)
    return local_parts


def build():
    build_one("P",(-540,800,480),(-540,300,1000),140,500,570,45,320,50,(-1600,-200,700))
    build_one("R",(500,-450,850),(200,-450,1320),110,380,440,32.5,230,40,(1600,-700,1000))
    build_one("F",(0,650,520),(0,1260,570),110,365,425,32.5,220,40,(0,1400,1000))
