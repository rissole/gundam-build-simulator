from geometry import *
import math

REAR = "01 Rear frame"
ANKLE = "02 Ankle"
FORE = "03 Forefoot"


def build_frames():
    seats = [(-500, 100), (0, 200), (1000, 100)]
    foreseats = [(1420,80), (2100,80)]
    for sign, side in [(-1,"OUT"), (1,"IN")]:
        x=sign*500
        m=Mesh().box((x,215,320),(180,1830,240))
        for y, spacing in seats:
            m.box((sign*350,y,370),(120,spacing+80,40))
        rail=emit("FA-100",f"Rear_rail_{side}",m,REAR,.4,(sign*700,0,0),bevel=8)
        cut(rail,Mesh().box((x,215,320),(140,1834,200)))
        bore(rail,[((sign*350,y+dy,370),19,70,(0,0,1))
                   for y,s in seats for dy in (-s/2,s/2)])
        m=Mesh().box((x,1760,320),(180,840,240))
        for y,s in foreseats: m.box((sign*350,y,370),(120,160,40))
        rail=emit("FA-104",f"Forefoot_rail_{side}",m,FORE,5,(sign*700,1050,80),bevel=8)
        cut(rail,Mesh().box((x,1760,320),(140,844,200)))
        bore(rail,[((sign*350,y+dy,370),19,70,(0,0,1))
                   for y,s in foreseats for dy in (-s/2,s/2)])
        for is_fore, group, specs in [(False,REAR,seats),(True,FORE,foreseats)]:
            for y,s in specs:
                length=s+80
                nm=Mesh().box((sign*350,y,323),(80,length,54))
                keeperpoints=[]
                for dy in (-length/2+16,length/2-16):
                    # Integral side tabs sit clear of the main M36 threads.
                    nm.box((sign*290,y+dy,340),(40,28,20))
                    keeperpoints.append((sign*290,y+dy,352.5))
                plate=emit("FA-107",f"Nut_plate_{side}_{int(y)}_pitch_{s}",nm,group,
                           5.1 if is_fore else .8,
                           (sign*700,1050 if is_fore else 0,-260),("Steel",),2)
                bore(plate,[((sign*350,y+dy,323),18,80,(0,0,1)) for dy in (-s/2,s/2)])
                hardware("Nut plate keepers",keeperpoints,phase=5.2 if is_fore else .9,
                         explosion=(sign*700,1050 if is_fore else 0,-400),owner=plate)

    for family,label,y,spacing,is_fore in [
        ("FA-101","Rear_crossmember",-500,100,False),
        ("FA-102","Front_crossmember",1000,100,False),
        ("FA-105","Toe_crossmember",2100,80,True),
        ("FA-106","Hinge_beam",1420,80,True),
    ]:
        group=FORE if is_fore else REAR
        phase=5.4 if is_fore else 1.3
        ex=(0,1050 if is_fore else (-500 if y<0 else 400),400)
        if family=="FA-106":
            m=Mesh().box((0,1335,350),(800,120,260))
            for s in (-1,1):
                m.box((s*350,1420,410),(120,160,40))
                m.beam((s*350,1380,350),(s*350,1420,410),100)
                m.tube((s*380,1200,350),95,75,140,(1,0,0))
                m.beam((s*380,1200,350),(s*380,1335,350),100)
        else:
            m=Mesh().box((0,y,320),(820,160,200))
            for s in (-1,1):
                m.box((s*350,y,410),(120,spacing+80,40))
            if family=="FA-102":
                for s in (-1,1):
                    m.tube((s*520,1200,350),95,60,120,(1,0,0))
                    m.beam((s*520,1000,320),(s*520,1200,350),120)
                    # Receiver ears for the two axle-cap screws.
                    m.box((s*520,1200,460),(120,70,50))
                    m.box((s*520,1200,240),(120,70,50))
        o=emit(family,label,m,group,phase,ex,bevel=5)
        centers=[(s*350,y+dy,436) for s in (-1,1) for dy in (-spacing/2,spacing/2)]
        bore(o,[(p,19,140,(0,0,1)) for p in centers])
        if family=="FA-106":
            bore(o,[((s*380,1200,350),75,160,(1,0,0)) for s in (-1,1)])
        hardware("Forefoot frame joints" if is_fore else "Rear frame joints",
                 centers,phase=phase+.25,explosion=ex,owner=o)

    # Cradle is a single cast/fabricated component with open center and outriggers.
    m=Mesh()
    for s in (-1,1):
        m.box((s*350,0,410),(120,280,40))
        m.box((s*500,0,975),(100,280,350))
        for y in (-100,100):
            m.beam((s*350,y,430),(s*500,y,830),85)
    for y in (-100,100):
        m.beam((-350,y,470),(350,y,470),70)
    m.beam((-500,0,550),(-540,800,450),70)
    m.beam((-350,100,430),(-540,800,450),55)
    m.box((-540,800,430),(140,180,40))
    cradle=emit("FA-103","Fixed_ankle_cradle",m,REAR,2,(0,0,700),bevel=5)
    bore(cradle,[((s*500,0,1000),60,120,(1,0,0)) for s in (-1,1)]
         +[((s*350,y,410),19,70,(0,0,1)) for s in (-1,1) for y in (-100,100)])
    hardware("Rear frame joints",[(s*350,y,436) for s in (-1,1) for y in (-100,100)],
             phase=2.2,explosion=(0,0,900),owner=cradle)
    return cradle


def build_ankle():
    m=Mesh()
    for s in (-1,1):
        m.box((s*370,0,1000),(140,720,120))
        m.box((0,s*290,1000),(600,140,120))
        m.tube((s*370,0,1000),90,75,140,(1,0,0))
        m.tube((0,s*290,1000),100,50,140,(0,1,0))
    # Integral stop tab and lower stop-mount ears.
    m.box((420,0,845),(40,50,190))
    for x in (-100,100):
        m.box((x,0,735),(80,170,30))
        m.beam((x,0,735),(x/abs(x)*330,0,940),45)
    ring=emit("FA-200","Open_horizontal_pitch_ring",m,ANKLE,3.8,(0,0,1450),bevel=4)
    bore(ring,[((s*370,0,1000),75,170,(1,0,0)) for s in (-1,1)]
         +[((0,s*290,1000),50,170,(0,1,0)) for s in (-1,1)])
    m=Mesh().box((0,0,1125),(360,260,390))
    m.box((0,0,1350),(520,440,60))
    m.box((0,0,1390),(180,100,20))
    for s in (-1,1):m.tube((0,s*160,1000),90,65,100,(0,1,0))
    m.box((0,0,850),(45,45,160))
    adapter=emit("FA-201","Keyed_roll_adapter",m,ANKLE,3.2,(0,0,2050),bevel=6)
    bore(adapter,[((0,0,1000),65,460,(0,1,0))]
         +[((x,y,1350),18,80,(0,0,1)) for x in (-200,200) for y in (-150,150)])
    for s in (-1,1):
        # Pitch journal, short pin; central region remains empty.
        m=Mesh().cyl((s*425,0,1000),60,250,(1,0,0))
        m.cyl((s*562.5,0,1000),78,25,(1,0,0))
        pin=emit("FA-202","Pitch_pin",m,ANKLE,4.1,(s*1500,0,1000),("Pin",),1)
        emit("FA-204","Pitch_bushing",Mesh().tube((s*370,0,1000),75,60,140,(1,0,0)),
             ANKLE,3.5,(s*900,0,1300),("Bronze",),.8)
        emit("FA-206","Pitch_thrust_washer",Mesh().tube((s*444,0,1000),85,61,8,(1,0,0)),
             ANKLE,3.7,(s*1100,0,1200),("Steel",),.4)
        capmesh=Mesh().cyl((s*585,0,1000),83,20,(1,0,0))
        for y in (-110,110):capmesh.box((s*568,y,1000),(54,70,70))
        cap=emit("FA-208","Pitch_pin_cap",capmesh,ANKLE,4.3,(s*1750,0,1000),("Steel",),3)
        points=[(s*571,y,1000) for y in (-110,110)]
        bore(cap,[((s*584,y,1000),20,28,(1,0,0)) for y in (-110,110)])
        hardware("Ankle pin caps",points,axis=(-s,0,0),phase=4.4,
                 explosion=(s*1900,0,1000),owner=cap)

        m=Mesh().cyl((0,s*235,1000),50,250,(0,1,0))
        m.cyl((0,s*372.5,1000),66,25,(0,1,0))
        emit("FA-203","Roll_pin",m,ANKLE,3.45,(0,s*1000,1650),("Pin",),1)
        emit("FA-205","Roll_bushing",Mesh().tube((0,s*160,1000),65,50,100,(0,1,0)),
             ANKLE,3,(0,s*600,1900),("Bronze",),.8)
        emit("FA-207","Roll_thrust_washer",Mesh().tube((0,s*214,1000),75,51,8,(0,1,0)),
             ANKLE,3.35,(0,s*800,1800),("Steel",),.4)
        m=Mesh().cyl((0,s*395,1000),72,20,(0,1,0))
        for x in (-90,90):m.box((x,s*378,1000),(60,54,65))
        cap=emit("FA-209","Roll_pin_cap",m,ANKLE,3.55,(0,s*1300,1700),("Steel",),3)
        bore(cap,[((x,s*394,1000),20,28,(0,1,0)) for x in (-90,90)])
        hardware("Ankle pin caps",[(x,s*381,1000) for x in (-90,90)],axis=(0,-s,0),
                 phase=3.65,explosion=(0,s*1450,1700),owner=cap)
    hardware("Shin flange",[(x,y,1386) for x in (-200,200) for y in (-150,150)],
             phase=11.3,explosion=(0,0,2550),owner=adapter)
    return ring,adapter


def build_toe_joint():
    m=Mesh().cyl((0,1200,350),60,1160,(1,0,0))
    m.cyl((-592.5,1200,350),80,25,(1,0,0))
    axle=emit("FA-210","Continuous_forefoot_axle",m,FORE,6.2,(-1600,1050,300),("Pin",),1)
    for s in (-1,1):
        emit("FA-211","Forefoot_bushing",Mesh().tube((s*380,1200,350),75,60,140,(1,0,0)),
             FORE,5.7,(s*600,1050,350),("Bronze",),.7)
        emit("FA-212","Forefoot_thrust_washer",Mesh().tube((s*454,1200,350),85,61,8,(1,0,0)),
             FORE,6,(s*900,1050,350),("Steel",),.4)
    m=Mesh().cyl((590,1200,350),80,20,(1,0,0))
    for z in (240,460):m.box((575,1200,z),(50,65,70))
    cap=emit("FA-213","Forefoot_axle_cap",m,FORE,6.4,(1400,1050,300),("Steel",),3)
    bore(cap,[((587,1200,z),20,28,(1,0,0)) for z in (240,460)])
    hardware("Forefoot axle cap",[(576,1200,z) for z in (240,460)],axis=(-1,0,0),
             phase=6.5,explosion=(1550,1050,300),owner=cap)


def build_stops():
    # Six separate reference stop blocks, with separate bolts and receiver datums.
    data=[
        ("Pitch_back",(420,-90,745),2.4,(700,-400,650)),
        ("Pitch_forward",(420,90,745),2.4,(700,400,650)),
        ("Roll_outer",(-100,0,760),3.15,(-500,0,1500)),
        ("Roll_inner",(100,0,760),3.15,(500,0,1500)),
        ("Toe_flat",(220,1170,465),6.6,(450,900,500)),
        ("Toe_limit",(220,1100,565),6.6,(450,1200,600)),
    ]
    for name,p,phase,ex in data:
        m=Mesh().box(p,(80,140,30))
        m.box(vec(p)+Vector((0,0,35)),(50,50,45))
        block=emit("FA-230",name+"_stop",m,ANKLE if "Toe" not in name else FORE,
                   phase,ex,("Steel",),3)
        holes=[(p[0],p[1]+dy,p[2]+19) for dy in (-40,40)]
        bore(block,[(h,12.5,70,(0,0,1)) for h in holes])
        hardware("Mechanical stops",holes,phase=phase+.1,explosion=ex,owner=block)
