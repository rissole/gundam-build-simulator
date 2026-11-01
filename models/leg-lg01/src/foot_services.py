"""FA-02 electrical modules; source cartridge boundaries retained."""
from foot_geometry import *
from foot_actuators import ACTUATORS
ELEC='06 Electrical'
SOLE='05 Soles'

def plug(mesh, p, axis, radius=14):
    p=vec(p);a=vec(axis).normalized()
    mesh.cyl(p,radius,30,a,mat=1)
    mesh.tube(p+a*16,radius+2,radius*.5,6,a,mat=1)
    for s in (-1,1):
        u,v,w=frame(a)
        mesh.cyl(p+a*18+u*s*4,2,8,a,mat=2)


def build_electrical():
    case=emit("FA-600","Junction_box",Mesh().box((300,800,535),(300,300,150)),
              ELEC,10,(1100,450,1200),("Frame",),4)
    cut(case,Mesh().box((300,800,560),(270,270,170)))
    frame_part=find_part('FA-102')
    for x in (180,420):
        for y in (680,920):
            add_feature(frame_part,Mesh().cyl((x,y,450),18,20)
                        .beam((x+(40 if x>300 else -40),1120,390),(x,y,450),32))
    bore(frame_part,[((x,y,449),6,24,(0,0,1)) for x in (180,420) for y in (680,920)])
    ports=[(x,646,550) for x in (210,270,330,390)]
    bore(case,[(p,14,35,(0,1,0)) for p in ports])
    lid=emit("FA-601","Junction_box_lid",Mesh().box((300,800,615),(300,300,10)),
             ELEC,10.8,(1100,450,1800),("Steel",),3)
    m=Mesh()
    for x in (157,443):m.box((x,800,609),(10,286,2))
    for y in (657,943):m.box((300,y,609),(276,10,2))
    emit("FA-602","Box_lid_gasket",m,ELEC,10.75,(1100,450,1650),("Rubber",),0)
    m=Mesh().box((300,800,502),(240,240,5))
    for x,y in [(250,750),(350,750),(250,850),(350,850)]:
        m.box((x,y,513),(48,48,18),mat=1)
        for s in (-1,1):
            for dy in (-18,-9,0,9,18):m.box((x+s*27,y+dy,508),(8,4,4),mat=2)
    for y in (710,890):m.box((300,y,510),(100,12,12),mat=1)
    board=emit("FA-603","Three_channel_controller",m,ELEC,10.2,(1100,450,1450),
               ("Board","Frame","Copper"),1)
    corners=[(x,y) for x in (180,420) for y in (680,920)]
    for x,y in corners:
        add_feature(case,Mesh().cyl((x,y,489),12,28))
    for x,y in corners:
        add_feature(case,Mesh().tube((x,y,590),14,6,40)
                    .beam((x,y,600),(160 if x<300 else 440,y,600),22))
    board_points=[(x,y) for x in (195,405) for y in (695,905)]
    for x,y in board_points:
        add_feature(case,Mesh().tube((x,y,487.25),12,6,24.5))
    bore(case,[((x,y,468),6.5,20,(0,0,1)) for x,y in corners])
    bore(lid,[((x,y,615),6.5,14,(0,0,1)) for x,y in corners])
    bore(board,[((x,y,502),6.5,10,(0,0,1)) for x,y in board_points])
    hardware("Junction box mounting",[(x,y,480.5) for x,y in corners],
             phase=10.1,explosion=(1100,450,1000),owner=case,sites=("out-rear", "out-front", "in-rear", "in-front"))
    hardware("Junction box lid",[(x,y,622.5) for x,y in corners],
             phase=10.9,explosion=(1100,450,1950),owner=lid,sites=("out-rear", "out-front", "in-rear", "in-front"))
    hardware("Controller board mounting",[(x,y,507) for x in (195,405) for y in (695,905)],
             phase=10.3,explosion=(1100,450,1550),owner=board,sites=("out-rear", "out-front", "in-rear", "in-front"))
    for i,p in enumerate(ports):
        m=Mesh().tube(p,18,10,30,(0,1,0))
        m.cyl(vec(p)+Vector((0,12,0)),21,5,(0,1,0))
        for x in (-4,4):m.cyl(vec(p)+Vector((x,-8,0)),2,12,(0,1,0),mat=1)
        emit("FA-604",f"Box_socket_{i+1}",m,ELEC,10.15,(1100+(i-1.5)*80,250,1200),
             ("Steel","Copper"),.8)
    paths=[
        ("FA-605","Main_input",[ports[0],(210,590,550),(470,500,510),(540,150,650),
         (530,-120,850),(400,-170,1100),(200,-170,1160),(170,50,1240),(250,100,1400)],5,(1250,-400,700)),
        ("FA-606","Pitch_branch",[ports[1],(270,590,550),(180,500,570),(-150,550,570),
         (-400,720,530),ACTUATORS["P"]["socket"]],3,(-1300,700,400)),
        ("FA-606","Roll_branch",[ports[2],(330,580,550),(550,400,550),(560,80,700),
         (540,-230,820),(450,-440,900),ACTUATORS["R"]["socket"]],3,(1350,-700,700)),
        ("FA-606","Forefoot_branch",[ports[3],(390,580,550),(300,540,540),(160,540,550),
         ACTUATORS["F"]["socket"]],1,(700,1200,500)),
    ]
    for pid,name,points,nclips,ex in paths:
        m=Mesh().poly_tube(smooth_path(points),10 if pid=="FA-605" else 8,n=12)
        plug(m,points[0],vec(points[0])-vec(points[1]))
        plug(m,points[-1],vec(points[-1])-vec(points[-2]))
        harness=emit(pid,name,m,ELEC,10.5,ex,("Cable","Steel","Copper"),0)
        for i in range(nclips):
            p=vec(points[1+int(i*(len(points)-3)/max(nclips-1,1))])
            # One mounting tab and one screw per clip.
            m=Mesh().tube(p,14,10.5,14,(0,1,0),n=24)
            m.box(p+Vector((24,0,-12)),(28,18,5))
            clip=emit("FA-607",name+f"_clip_{i+1}",m,ELEC,10.6,
                      vec(ex)+Vector((100+i*40,0,150)),("Steel",),.6)
            hp=p+Vector((28,0,-7))
            bore(clip,[(hp,6.5,20,(0,0,1))])
            hardware("Cable clips",[hp],phase=10.65,
                     explosion=vec(ex)+Vector((100+i*40,0,250)),owner=clip,sites=("mount",))


def build_soles():
    pad_holes=[(x,y,170) for x in (-595,-125,125,595) for y in (-750,-210,30,1120,1580,2340)]
    for family,y0,y1,ys in [('FA-300',-850,1230,(-670,170,1040)),
                            ('FA-301',1470,2450,(1640,2280))]:
        pts=[(s*560,y,168) for s in (-1,1) for y in ys]
        m=Mesh().prism(chamfer_rect(-685,685,y0,y1,25),140,200)
        carrier=emit(family,'Rear_carrier' if family=='FA-300' else 'Forefoot_carrier',
                     m,SOLE,9,materials=('Frame',),bevel=.6)
        bore(carrier,[(p,12,64,(0,0,1)) for p in pad_holes if y0<p[1]<y1]
             +[((p[0],p[1],185),13,64,(0,0,1)) for p in pts]
             +[((p[0],p[1],153),28,38,(0,0,1)) for p in pts])
        hardware('Sole carrier mounts',pts,axis=(0,0,1),owner=carrier,
                 sites=('out-rear','out-middle','out-front','in-rear','in-middle','in-front')
                 if family=='FA-300' else ('out-rear','out-front','in-rear','in-front'))
