"""FA-02 frame and unscaled ankle stacks, adapted from FA-01. Units mm."""
from foot_geometry import *
REAR='01 Rear frame'
ANKLE='02 Ankle'
FORE='03 Forefoot'

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
        pin=emit("FA-202","Pitch_pin",m,ANKLE,4.1,(s*1500,0,1000),("Pin",),1,role=f"FA-202/Pitch_pin/{'negative' if s<0 else 'positive'}")
        emit("FA-204","Pitch_bushing",Mesh().tube((s*370,0,1000),75,60,140,(1,0,0)),
             ANKLE,3.5,(s*900,0,1300),("Bronze",),.8,role=f"FA-204/Pitch_bushing/{'negative' if s<0 else 'positive'}")
        emit("FA-206","Pitch_thrust_washer",Mesh().tube((s*444,0,1000),85,61,8,(1,0,0)),
             ANKLE,3.7,(s*1100,0,1200),("Steel",),.4,role=f"FA-206/Pitch_thrust_washer/{'negative' if s<0 else 'positive'}")
        capmesh=Mesh().cyl((s*585,0,1000),83,20,(1,0,0))
        for y in (-110,110):capmesh.box((s*568,y,1000),(54,70,70))
        cap=emit("FA-208","Pitch_pin_cap",capmesh,ANKLE,4.3,(s*1750,0,1000),("Steel",),3,role=f"FA-208/Pitch_pin_cap/{'negative' if s<0 else 'positive'}")
        points=[(s*571,y,1000) for y in (-110,110)]
        bore(cap,[((s*584,y,1000),20,28,(1,0,0)) for y in (-110,110)])
        hardware("Ankle pin caps",points,axis=(-s,0,0),phase=4.4,
                 explosion=(s*1900,0,1000),owner=cap,sites=("negative", "positive"))

        m=Mesh().cyl((0,s*235,1000),50,250,(0,1,0))
        m.cyl((0,s*372.5,1000),66,25,(0,1,0))
        emit("FA-203","Roll_pin",m,ANKLE,3.45,(0,s*1000,1650),("Pin",),1,role=f"FA-203/Roll_pin/{'negative' if s<0 else 'positive'}")
        emit("FA-205","Roll_bushing",Mesh().tube((0,s*160,1000),65,50,100,(0,1,0)),
             ANKLE,3,(0,s*600,1900),("Bronze",),.8,role=f"FA-205/Roll_bushing/{'negative' if s<0 else 'positive'}")
        emit("FA-207","Roll_thrust_washer",Mesh().tube((0,s*214,1000),75,51,8,(0,1,0)),
             ANKLE,3.35,(0,s*800,1800),("Steel",),.4,role=f"FA-207/Roll_thrust_washer/{'negative' if s<0 else 'positive'}")
        m=Mesh().cyl((0,s*395,1000),72,20,(0,1,0))
        for x in (-90,90):m.box((x,s*378,1000),(60,54,65))
        cap=emit("FA-209","Roll_pin_cap",m,ANKLE,3.55,(0,s*1300,1700),("Steel",),3,role=f"FA-209/Roll_pin_cap/{'negative' if s<0 else 'positive'}")
        bore(cap,[((x,s*394,1000),20,28,(0,1,0)) for x in (-90,90)])
        hardware("Ankle pin caps",[(x,s*381,1000) for x in (-90,90)],axis=(0,-s,0),
                 phase=3.65,explosion=(0,s*1450,1700),owner=cap,sites=("negative", "positive"))
    hardware("Shin flange",[(x,y,1416) for x in (-200,200) for y in (-150,150)],
             phase=11.3,explosion=(0,0,2550),owner=adapter,sites=("out-rear", "out-front", "in-rear", "in-front"))
    return ring,adapter


def build_toe_joint():
    m=Mesh().cyl((0,1340,350),60,1160,(1,0,0))
    m.cyl((-592.5,1340,350),80,25,(1,0,0))
    axle=emit("FA-210","Continuous_forefoot_axle",m,FORE,6.2,(-1600,1050,300),("Pin",),1)
    for s in (-1,1):
        emit("FA-211","Forefoot_bushing",Mesh().tube((s*380,1340,350),75,60,140,(1,0,0)),
             FORE,5.7,(s*600,1050,350),("Bronze",),.7,role=f"FA-211/Forefoot_bushing/{'negative' if s<0 else 'positive'}")
        emit("FA-212","Forefoot_thrust_washer",Mesh().tube((s*454,1340,350),85,61,8,(1,0,0)),
             FORE,6,(s*900,1050,350),("Steel",),.4,role=f"FA-212/Forefoot_thrust_washer/{'negative' if s<0 else 'positive'}")
    m=Mesh().cyl((590,1340,350),80,20,(1,0,0))
    for z in (240,460):m.box((575,1340,z),(50,65,70))
    cap=emit("FA-213","Forefoot_axle_cap",m,FORE,6.4,(1400,1050,300),("Steel",),3)
    bore(cap,[((587,1340,z),20,28,(1,0,0)) for z in (240,460)])
    hardware("Forefoot axle cap",[(576,1340,z) for z in (240,460)],axis=(-1,0,0),
             phase=6.5,explosion=(1550,1050,300),owner=cap,sites=("negative", "positive"))


def build_stops():
    # Six separate reference stop blocks, with separate bolts and receiver datums.
    data=[
        ("Pitch_back",(420,-90,745),2.4,(700,-400,650)),
        ("Pitch_forward",(420,90,745),2.4,(700,400,650)),
        ("Roll_outer",(-100,0,760),3.15,(-500,0,1500)),
        ("Roll_inner",(100,0,760),3.15,(500,0,1500)),
        ("Toe_flat",(220,1310,465),6.6,(450,900,500)),
        ("Toe_limit",(220,1240,565),6.6,(450,1200,600)),
    ]
    for name,p,phase,ex in data:
        m=Mesh().box(p,(80,140,30))
        m.box(vec(p)+Vector((0,0,35)),(50,50,45))
        block=emit("FA-230",name+"_stop",m,ANKLE if "Toe" not in name else FORE,
                   phase,ex,("Steel",),3)
        holes=[(p[0],p[1]+dy,p[2]+19) for dy in (-40,40)]
        bore(block,[(h,12.5,70,(0,0,1)) for h in holes])
        hardware("Mechanical stops",holes,phase=phase+.1,explosion=ex,owner=block,sites=("rear", "front"))


def build_frames():
    seats=[(-560,110,200,-500),(0,220,310,0),(1120,110,200,1000)]
    foreseats=[(1590,90,180,1420),(2350,90,180,2100)]
    for sign,side in [(-1,'OUT'),(1,'IN')]:
        for is_fore,specs in [(False,seats),(True,foreseats)]:
            y0,y1=(1500,2440) if is_fore else (-785,1265)
            pid='FA-104' if is_fore else 'FA-100'
            label=('Forefoot' if is_fore else 'Rear')+'_rail_'+side
            m=Mesh().prism(chamfer_rect(200,440,sign*560-90,sign*560+90,20),y0,y1,'Y')
            for y,pitch,length,old_y in specs:
                m.box((sign*402.5,y,370),(135,length,40))
                # Web connects the inward ledge to the continuous lower rail
                # beneath the crossmember's upper half-lap socket.
                for dy in (-length/2+20,length/2-20):
                    m.box((sign*460,y+dy,335),(20,40,70))
            rail=emit(pid,label,m,FORE if is_fore else REAR,5 if is_fore else .4,bevel=2)
            cut(rail,Mesh().prism(chamfer_rect(220,420,sign*560-70,sign*560+70,8),y0-2,y1+2,'Y'))
            sockets=Mesh()
            for yy,depth in ([(2350,160)] if is_fore else [(-560,200),(1120,200)]):
                sockets.box((sign*560,yy,381),(182,depth+1,122))
            cut(rail,sockets)
            bore(rail,[((sign*395,y+dy,370),19,44,(0,0,1))
                       for y,pitch,length,old_y in specs for dy in (-pitch/2,pitch/2)])
            # Frame-to-carrier thread bosses remain solid inside the hollow rails.
            carrier_y=(1640,2280) if is_fore else (-670,170,1040)
            for y in carrier_y:
                add_feature(rail,Mesh().cyl((sign*560,y,220),25,40))
            bore(rail,[((sign*560,y,220),12,44,(0,0,1)) for y in carrier_y])
            for y,pitch,length,old_y in specs:
                # Two lowered keeper lands: head at362.5, washer360..362.5,
                # rail land350..360, plate ear332.5..350 engagement.
                kp=[(sign*395+dx,y,362.5) for dx in (-55,55)]
                pockets=Mesh()
                for x,yy,z in kp:pockets.box((x,yy,379),(28,36,38))
                cut(rail,pockets)
                bore(rail,[((x,yy,355),6.5,14,(0,0,1)) for x,yy,z in kp])
                nm=Mesh().box((sign*395,y,323),(80,length,54))
                for x,yy,z in kp:nm.box((x,yy,337),(30,32,26))
                old_pitch=80 if is_fore else (200 if y==0 else 100)
                old_label=f'Nut_plate_{side}_{old_y}_pitch_{old_pitch}'
                plate=emit('FA-107',old_label,nm,FORE if is_fore else REAR,1,materials=('Frame',),bevel=2)
                bore(plate,[((sign*395,y+dy,323),18,58,(0,0,1)) for dy in (-pitch/2,pitch/2)]
                     +[((x,yy,337),6,30,(0,0,1)) for x,yy,z in kp])
                hardware('Nut plate keepers',kp,owner=plate,sites=('rear','front'))
    for family,label,y,pitch,is_fore,depth in [
        ('FA-101','Rear_crossmember',-560,110,False,200),
        ('FA-102','Front_crossmember',1120,110,False,200),
        ('FA-105','Toe_crossmember',2350,90,True,160),
        ('FA-106','Hinge_beam',1590,90,True,120)]:
        if family=='FA-106':
            # A 0.5 mm front-face relief avoids an exactly tangent bore at
            # Y1545; rear face stays1425 and the documented fit tolerance is10.
            m=Mesh().box((0,1484.75,350),(900,119.5,260))
            for s in (-1,1):
                m.box((s*395,1590,410),(120,180,40))
                m.beam((s*395,1500,350),(s*395,1590,410),100)
                m.tube((s*380,1340,350),95,75,140,(1,0,0))
                m.beam((s*380,1340,350),(s*380,1485,350),100)
        else:
            # Open transverse section; ends terminate at the outer rail faces.
            m=Mesh().prism(chamfer_rect(y-depth/2,y+depth/2,200,440,20),-650,650,'X')
            for s in (-1,1):m.box((s*395,y,410),(120,pitch+90,40))
            if family=='FA-102':
                for s in (-1,1):
                    m.tube((s*520,1340,350),95,60,120,(1,0,0))
                    m.beam((s*520,1120,320),(s*520,1340,350),120)
                    for z in (240,460):m.box((s*520,1340,z),(120,70,50))
        o=emit(family,label,m,FORE if is_fore else REAR,5 if is_fore else 1,bevel=8)
        if family!='FA-106':
            cut(o,Mesh().prism(chamfer_rect(y-depth/2+20,y+depth/2-20,220,400,8),-652,652,'X'))
            # Half-lap ends reach the specified X±650 outer faces: rail
            # lower walls remain continuous and crossmember end lands occupy
            # Z320..440. The inward M36 lands stay at Z390..430.
            void=Mesh()
            for s in (-1,1):
                void.box((s*560,y,259.75),(182,depth+4,120.5))
                void.box((s*395,y,440),(120,depth+4,20))
            cut(o,void)
        centers=[(s*395,y+dy,436) for s in (-1,1) for dy in (-pitch/2,pitch/2)]
        bore(o,[(p,19,300,(0,0,1)) for p in centers])
        if family=='FA-106':bore(o,[((s*380,1340,350),75,144,(1,0,0)) for s in (-1,1)])
        if family=='FA-106':
            # The beam rises to480, so expose the430 washer seats with real
            # octagonal wells (also clear the joining arm beneath the head).
            wells=Mesh()
            for x,yy,z in centers:wells.cyl((x,yy,469.975),44,80.05,n=8)
            cut(o,wells)
        hardware('Forefoot frame joints' if is_fore else 'Rear frame joints',centers,
                 owner=o,sites=('out-rear','out-front','in-rear','in-front'))
    m=Mesh()
    for s in (-1,1):
        for y in (-110,110):
            m.box((s*395,y,410),(120,80,40))
            m.beam((s*470,y,430),(s*500,y,830),55)
        # Chamfered cheek outline with the original unscaled bearing seats.
        profile=[(-140,800),(140,800),(140,1080),(70,1150),(-70,1150),(-140,1080)]
        m.prism(profile,min(s*450,s*550),max(s*450,s*550),'X')
    # Keep the M36 heads and their upward tool corridors clear of braces.
    for y in (-30,30):m.beam((-470,y,470),(470,y,470),55)
    for side in (-1,1):
        for sign in (-1,1):m.beam((side*470,sign*110,470),(side*470,sign*30,470),45)
    m.beam((-500,-110,550),(-500,110,550),55)
    m.beam((-500,0,550),(-540,800,450),70)
    m.beam((-470,150,430),(-540,800,450),55)
    m.box((-540,800,430),(140,180,40))
    # Repaired pitch base bracket threads horizontally into an outboard land.
    m.box((-585,800,425),(70,180,50))
    cradle=emit('FA-103','Fixed_ankle_cradle',m,REAR,2,bevel=5)
    bore(cradle,[((s*500,0,1000),60,104,(1,0,0)) for s in (-1,1)]
         +[((s*395,y,410),19,44,(0,0,1)) for s in (-1,1) for y in (-110,110)])
    hardware('Rear frame joints',[(s*395,y,436) for s in (-1,1) for y in (-110,110)],
             owner=cradle,sites=('out-rear','out-front','in-rear','in-front'))
    return cradle
