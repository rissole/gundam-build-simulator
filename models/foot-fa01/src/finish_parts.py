from geometry import *
from actuator_parts import ACTUATORS

SOLE="05 Soles"
ARMOR="07 Armor"
ELEC="06 Electrical"


def build_soles():
    rearpoints=[(s*500,y,168) for s in (-1,1) for y in (-650,150,1000)]
    frontpoints=[(s*500,y,168) for s in (-1,1) for y in (1420,2100)]
    pad_holes=[]
    for family,y0,y1 in [("FA-302",-760,-100),("FA-303",-60,1090),("FA-304",1320,2180)]:
        for s in (-1,1):
            x0,x1=(-620,-20) if s<0 else (20,620)
            pts=[(x,y,60) for x in (x0+100,x1-100) for y in (y0+100,y1-100)]
            pad_holes.extend(pts)
            m=Mesh().prism(chamfer_rect(x0,x1,y0,y1,20),0,140)
            ex=(s*360,400 if family=="FA-304" else 0,-1050-(0 if family=="FA-302" else 140))
            pad=emit(family,("Heel" if family=="FA-302" else "Midfoot" if family=="FA-303" else "Forefoot")+"_pad",
                     m,SOLE,9.6,ex,("Rubber",),4)
            bore(pad,[(vec(p)+Vector((0,0,40)),21,100,(0,0,1)) for p in pts]
                 +[((p[0],p[1],25),28,78,(0,0,1)) for p in pts])
            # Tread grooves are cut from the ground-facing surface.
            grooves=Mesh()
            y=y0+70
            while y<y1-40:
                # Keep solid bolt counterbore lands clear of the grooves.
                if all(abs(y-p[1])>45 for p in pts):
                    grooves.box(((x0+x1)/2,y,5),(x1-x0-80,30,14))
                y+=120
            if grooves.v:cut(pad,grooves)
            for p in pts:
                emit("FA-305","Pad_compression_sleeve",
                     Mesh().tube((p[0],p[1],102),21,13,76),
                     SOLE,9.5,vec(ex)+Vector((0,0,-180)),("Steel",),.5)
            hardware("Sole pad mounts",pts,axis=(0,0,1),phase=9.8,
                     explosion=vec(ex)+Vector((0,0,-330)),owner=pad)
    for family,y0,y1,pts,phase,ex in [
        ("FA-300",-760,1100,rearpoints,9,(0,0,-500)),
        ("FA-301",1310,2190,frontpoints,9.1,(0,650,-650))]:
        m=Mesh().prism(chamfer_rect(-610,610,y0,y1,25),140,200)
        carrier=emit(family,"Rear_carrier" if family=="FA-300" else "Forefoot_carrier",
                     m,SOLE,phase,ex,("Frame",),4)
        ownholes=[p for p in pad_holes if y0<=p[1]<=y1]
        bore(carrier,[((p[0],p[1],170),12,70,(0,0,1)) for p in ownholes]
             +[((p[0],p[1],185),13,60,(0,0,1)) for p in pts]
             +[((p[0],p[1],149),28,38,(0,0,1)) for p in pts])
        hardware("Sole carrier mounts",pts,axis=(0,0,1),phase=phase+.2,
                 explosion=vec(ex)+Vector((0,0,-160)),owner=carrier)


def wedge_shell(outline, low, height_fn, thickness=20):
    n=len(outline)
    center=sum((vec((x,y,0)) for x,y in outline),Vector())/n
    inside=[]
    for x,y in outline:
        direction=Vector((x,y,0))-center
        direction.normalize()
        inside.append((x-direction.x*thickness,y-direction.y*thickness))
    vs=[]
    vs += [(x,y,low) for x,y in outline]
    vs += [(x,y,height_fn(x,y)) for x,y in outline]
    vs += [(x,y,height_fn(x,y)-thickness) for x,y in inside]
    vs += [(x,y,low) for x,y in inside]
    fs=[tuple(range(n,2*n)),tuple(reversed(range(2*n,3*n)))]
    for i in range(n):
        j=(i+1)%n
        fs += [(i,j,j+n,i+n),(i+2*n,j+2*n,j+3*n,i+3*n),
               (i,i+3*n,j+3*n,j)]
    return Mesh().add(vs,fs)


def build_armor():
    # A short chisel nose preserves the 400 mm tip while the roof clears the
    # M36 heads (top Z472) over the front crossmember at Y2060/2140.
    outline=chamfer_rect(-640,640,1340,2200,55)
    def toe_height(x,y):
        return 600-(y-1340)*80/805 if y<=2145 else 520-(y-2145)*120/55
    toe=wedge_shell(outline,200,toe_height)
    toe.f=toe.f[2:]
    toe.mi=toe.mi[2:]
    def roof_plate(points):
        n=len(points)
        toe.add(points+[(x,y,z-20) for x,y,z in points],
                [tuple(range(n)),tuple(reversed(range(n,2*n)))]+
                [(i,(i+1)%n,(i+1)%n+n,i+n) for i in range(n)])
    roof_plate([(x,y,toe_height(x,y)) for x,y in
                [outline[0],outline[1],outline[2],outline[3],outline[6],outline[7]]])
    roof_plate([(-585,2145,520),(585,2145,520),(585,2200,400),(-585,2200,400)])
    roof_plate([(640,2145,520),(585,2200,400),(585,2145,520)])
    roof_plate([(-585,2145,520),(-585,2200,400),(-640,2145,520)])
    upper_outline=[(-610,-450),(-350,-450),(-350,470),(350,470),(350,-450),
                   (610,-450),(610,1080),(-610,1080),(-610,870),(-450,870),
                   (-450,550),(-610,550)]
    upper=Mesh().prism(upper_outline,680,700)
    # Wraparound skirts are integral to the upper shell, not extra panels.
    upper.box((620,315,445),(20,1530,490))
    upper.box((-620,50,445),(20,1000,490))
    upper.box((-620,975,445),(20,210,490))
    upper.box((-620,710,330),(20,320,260))
    upper.box((605,315,680),(30,1530,20))
    upper.box((-605,50,680),(30,1000,20))
    upper.box((-605,975,680),(30,210,20))
    heel=wedge_shell(chamfer_rect(-640,640,-800,-450,45),200,
                     lambda x,y:450+(y+800)*150/350)
    guard_profile=[(-650,600),(-650,1050),(-300,1600),(180,1600),
                   (450,1250),(850,700),(850,600)]
    data=[
        ("FA-400","Toe_cap",toe,(0,1100,1400),[(s*628,y,330) for s in (-1,1) for y in (1500,2020)],
         [(-s,0,0) for s in (-1,1) for _ in range(2)]),
        ("FA-401","Upper_foot_shell",upper,(0,0,2400),[(s*480,y,688) for s in (-1,1) for y in (350,980)],
         [(0,0,-1)]*4),
        ("FA-402","Heel_cover",heel,(0,-1400,500),
         [(-480,-620,515),(480,-620,515),(-440,-788,330),(440,-788,330)],
         [(0,0,-1),(0,0,-1),(0,1,0),(0,1,0)]),
        ("FA-403","Inner_guard",Mesh().prism(guard_profile,630,650,"X"),(2000,0,900),
         [(638,y,z) for y,z in [(-400,720),(500,720),(-250,1450),(180,1430)]],[(-1,0,0)]*4),
        ("FA-404","Outer_guard",Mesh().prism(guard_profile,-650,-630,"X"),(-2000,0,900),
         [(-638,y,z) for y,z in [(-400,720),(500,720),(-250,1450),(180,1430)]],[(1,0,0)]*4),
    ]
    for index,(pid,name,m,ex,points,axes) in enumerate(data):
        panel=emit(pid,name,m,ARMOR,12+index*.13,ex,("Armor",),3)
        for p,a in zip(points,axes):
            add_feature(panel,Mesh().tube(vec(p)+vec(a)*13,16,6.5,10,a,n=24))
        bore(panel,[(p,6.5,80,a) for p,a in zip(points,axes)]
             +[(vec(p)-vec(a)*6,10,16,a) for p,a in zip(points,axes)])
        for i,(p,a) in enumerate(zip(points,axes)):
            a=vec(a);p=vec(p)
            # Captive bolts remain independent geometry and have their own collars.
            hardware("Armor captive bolts",[p],a,12.15+index*.13,
                     vec(ex)-a*(120+i*20),owner=panel)
            collarpos=p+a*22
            emit("FA-405",name+"_captive_collar",Mesh().tube(collarpos,11,6,4,a,n=24),
                 ARMOR,12.12+index*.13,vec(ex)+a*110,("Steel",),.4)
            if pid in ("FA-403","FA-404"):
                parent=find_part("FA-103")
                anchor=Vector((500 if p.x>0 else -500, max(-100,min(100,p.y)),1000))
            else:
                parent=find_part("FA-104" if pid=="FA-400" else "FA-100","IN" if p.x>0 else "OUT")
                anchor=Vector((500 if p.x>0 else -500,max(-690,min(2150,p.y)),430))
            receiver=p+a*38
            feature=Mesh().box(receiver,(40,40,40)).beam(anchor,receiver,28)
            add_feature(parent,feature)
            bore(parent,[(receiver,5.8,45,a)])
        # Two integral locating tabs per shell.
        for p,a in zip(points[:2],axes[:2]):
            add_feature(panel,Mesh().box(vec(p)+vec(a)*24,(20,30,12)))


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
    hardware("Junction box mounting",[(x,y,480.5) for x,y in corners],
             phase=10.1,explosion=(1100,450,1000),owner=case)
    hardware("Junction box lid",[(x,y,622.5) for x,y in corners],
             phase=10.9,explosion=(1100,450,1950),owner=lid)
    hardware("Controller board mounting",[(x,y,510.5) for x in (195,405) for y in (695,905)],
             phase=10.3,explosion=(1100,450,1550),owner=board)
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
                     explosion=vec(ex)+Vector((100+i*40,0,250)),owner=clip)
