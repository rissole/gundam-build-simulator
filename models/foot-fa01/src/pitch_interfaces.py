"""Pitch-only connection geometry for the playable FA-500-P build.

Replace meshes on existing physical identities; do not allocate parts or modify
shared hardware templates. Coordinates are mm in the actuator's own basis.
All fastener points denote the underside of the screw head. The washer occupies
the next 2.5 mm in the insertion direction; the receiver starts after that.
"""
from geometry import *


def rebuild_pitch(spec):
    b = vec(spec['base']); u, v, d = map(vec, spec['basis']); L = spec['length']
    basis = (u, v, d)
    objects = {o['instance_id']: o for o in PARTS}
    def obj(family, n=1): return objects[f'{family}__{n:03d}']
    def world(p): return b + u*p[0] + v*p[1] + d*p[2]
    def direction(p): return u*p[0] + v*p[1] + d*p[2]
    def replace(o, mesh, bevel=.4):
        mesh.transform(b, basis)
        lo = vec(tuple(min(p[i] for p in mesh.v) for i in range(3)))
        hi = vec(tuple(max(p[i] for p in mesh.v) for i in range(3)))
        center = (lo+hi)/2
        old = o.data
        data = bpy.data.meshes.new(o.name+'_interfaces')
        data.from_pydata([(vec(p)-center)/1000 for p in mesh.v], [], mesh.f)
        data.update()
        bm = bmesh.new(); bm.from_mesh(data)
        bmesh.ops.recalc_face_normals(bm, faces=list(bm.faces)); bm.to_mesh(data); bm.free()
        for mat in old.materials: data.materials.append(mat)
        for poly, mi in zip(data.polygons,mesh.mi): poly.material_index=min(mi,len(data.materials)-1)
        o.data=data; o.location=center/1000; o['assembled_position_m']=list(o.location)
        for mod in list(o.modifiers): o.modifiers.remove(mod)
        if bevel:
            mod=o.modifiers.new('Machined edge radii','BEVEL'); mod.width=bevel/1000; mod.segments=2
        if old.users==0: bpy.data.meshes.remove(old)
        return o
    def holes(o, entries):
        bore(o, [(world(p),r,length,direction(axis)) for p,r,length,axis in entries])
    def boxcut(o, center, size): cut(o, Mesh().box(center,size).transform(b,basis))
    def fasteners(family, nums, points, axis=(0,0,-1)):
        for n,p in zip(nums,points):
            screw=obj(family,n)
            index=PARTS.index(screw); washer=PARTS[index+1]
            assert washer['part_id']=='W-12'
            replace(screw,screw_mesh(p,axis,12,int(family[-2:])),0)
            replace(washer,Mesh().tube(vec(p)+vec(axis)*1.25,12,6.5,2.5,axis,n=32),.15)
            screw['insertion_axis']=list(direction(axis))
            washer['insertion_axis']=list(direction(axis))
    axial=(0,0,1)
    radial=[(58,0),(0,58),(-58,0),(0,-58)]
    motor_xy=[(50*math.cos(math.pi/4+i*math.pi/2),50*math.sin(math.pi/4+i*math.pi/2)) for i in range(4)]
    gear_xy=[(48*math.cos(i*math.pi/2),48*math.sin(i*math.pi/2)) for i in range(4)]
    eye_xy=[(-50,-25),(50,25)]
    rod_eye_xy=[(-32,-16),(32,16)]
    rear=L-350 # Preserve the original travelling-nut datum.
    rod_end=L-68

    # Barrel: actual internal seats, cap bosses, guide lands and sensor openings.
    m=Mesh().tube((0,0,320),70,64,460) # 90..550; clearance for base eye below rear cap.
    m.tube((0,0,100),64,36,20)
    for x,y in radial:
        for z in (109,531): m.cyl((x,y,z),12,38)
    m.tube((0,0,248),64,18.5,4).tube((0,0,257),64,34.4,14)
    for y in (-42,42): m.cyl((0,y,256),12,32)
    m.tube((0,0,532),64,45.5,4).tube((0,0,542),64,50.4,16)
    for z in (430,490): m.box((51.5,64,z),(39,22,26))
    # Keep the rear sensor land above the 90 mm barrel face, clear of the cap.
    for z in (110,502): m.box((59,-28,z-9),(26,28,22))
    m.cyl((66,0,185),18,8,(1,0,0))
    barrel=replace(obj('FA-510'),m)
    holes(barrel,[((x,y,z),6.2,42,axial) for x,y in radial for z in (109,531)]
        + [((x,y,100),6.2,24,axial) for x,y in motor_xy]
        + [((x,y,99),10.6,20,axial) for x,y in eye_xy]
        + [((0,y,256),6.2,36,axial) for y in (-42,42)]
        + [((58,64,z),6.2,26,(0,1,0)) for z in (430,490)]
        + [((59,-28,z-12),6.2,30,(1,0,0)) for z in (110,502)]
        + [((67,0,z+11.75),6.5,24,(1,0,0)) for z in (110,502)]
        + [((0,0,261),34.4,22,axial),((0,0,542),50.4,16,axial)]
        + [((68,0,185),14.3,28,(1,0,0))])

    # Caps close against face gaskets; front has a separate wiper recess.
    front=replace(obj('FA-511'),Mesh().tube((0,0,562),70,45.5,20))
    holes(front,[((0,0,570),51.3,8,axial)]+[((x,y,562),6.5,24,axial) for x,y in radial])
    m=Mesh().cyl((0,0,78),70,20)
    for x,y in eye_xy: m.cyl((x,y,97),10,18)
    back=replace(obj('FA-512'),m)
    holes(back,[((x,y,78),6.5,24,axial) for x,y in radial]
        +[((x,y,84),6.5,10,axial) for x,y in motor_xy]
        +[((x,y,87),6.2,42,axial) for x,y in eye_xy])

    # Cartridge flanges sit on defined shoulders. Both sets of heads face forward
    # outside the cartridge cores, leaving a clear axial tool approach.
    m=Mesh().cyl((0,0,138),34,40).cyl((0,0,114),63,8).cyl((0,0,152),61,12)
    for x,y in gear_xy: m.cyl((x,y,143),9.5,30)
    m.cyl((0,0,105),14,10,mat=1)
    motor=replace(obj('FA-513'),m)
    holes(motor,[((x,y,114),6.5,12,axial) for x,y in motor_xy]
        +[((x,y,114),12.4,12,axial) for x,y in radial]
        +[((x,y,152),13,16,axial) for x,y in motor_xy]
        +[((x,y,144),6.2,32,axial) for x,y in gear_xy])
    m=Mesh().cyl((0,0,180),34,28).cyl((0,0,162),61,8)
    m.cyl((0,0,207),12,26)
    gear=replace(obj('FA-514'),m)
    holes(gear,[((x,y,162),6.5,12,axial) for x,y in gear_xy])

    # Split coupling clamps two 24 mm journals, with separated transverse screws.
    m=Mesh().tube((0,0,219.5),23,12.2,51)
    for z in (207,233): m.box((24,0,z),(26,34,24))
    coupling=replace(obj('FA-515'),m,.25)
    boxcut(coupling,(22,0,219.5),(48,2,55))
    holes(coupling,[((0,0,219.5),12.2,55,axial)]+[((24,0,z),6.5,38,(0,1,0)) for z in (207,233)])
    bearing=replace(obj('FA-522'),Mesh().tube((0,0,261),34,18.2,22))
    retainer=replace(obj('FA-523'),Mesh().tube((0,0,276),54,20,8))
    holes(retainer,[((0,y,276),6.5,12,axial) for y in (-42,42)])
    m=Mesh().cyl((0,0,232.5),12,25).cyl((0,0,274.5),18,59)
    m.cyl((0,0,421),17.2,234)
    m.helical_thread((0,0,310),axial,20,218,10,2.5)
    replace(obj('FA-516'),m,0)

    # Two physical collar halves, joining across the same split plane. Their
    # opposing semicircles no longer receive identically directed radial screws.
    for n,sign in ((1,-1),(2,1)):
        m=Mesh().tube((0,0,292),28,18.1,24)
        for x in (-29,29): m.box((x,0,292),(26,28,24))
        half=replace(obj('FA-524',n),m,.25)
        boxcut(half,(0,-sign*35,292),(110,72,30))
        holes(half,[((0,0,292),18.1,28,axial)]+[((x,0,292),6.5 if sign==1 else 6.2,34,(0,1,0)) for x in (-29,29)])

    # Rod flange pockets expose the two axial screws rather than burying heads.
    m=Mesh().tube((0,0,rear-17),40,20.3,34,n=6)
    m.tube((0,0,rear-6),63,20.3,12)
    for x in (-50,50): m.cyl((x,0,rear-15),10,30)
    nut=replace(obj('FA-517'),m)
    holes(nut,[((x,0,rear-15),6.2,34,axial) for x in (-50,50)])
    m=Mesh().tube((0,0,(rear+rod_end)/2),45,24,rod_end-rear)
    # Keep the exposed end at the rod's nominal diameter so the guide, wiper
    # and front cap can slide onto it before the separate eye is attached.
    m.tube((0,0,rear+5),63,24,10)
    rod=replace(obj('FA-518'),m)
    holes(rod,[((x,0,rear+5),6.5,14,axial) for x in (-50,50)]
        +[((x,0,rear+24),13,28,axial) for x in (-50,50)]
        +[((x,y,rod_end-15),6.2,34,axial) for x,y in rod_eye_xy])
    boxcut(rod,(0,51,(410+rod_end-6)/2),(12,24,rod_end-6-410))
    # A fixed cantilever guide tongue engages this slot; offset mounting ears
    # leave room for heads beside the moving rod, not through its wall.
    m=Mesh().box((0,44.5,460),(10,9,80)).box((22.5,49,460),(57,8,86))
    for z in (430,490): m.box((58,49,z),(26,8,26))
    key=replace(obj('FA-521'),m)
    holes(key,[((58,49,z),6.5,12,(0,1,0)) for z in (430,490)])
    replace(obj('FA-519'),Mesh().tube((0,0,543),50,45.4,18))
    replace(obj('FA-520'),Mesh().tube((0,0,569),51,44.8,6),.15)

    # Clear pin bores, shoulder on the far side, grooved clip on the near side.
    from actuator_parts import spherical_bearing
    for n,z,sign in ((1,0,1),(2,L,-1)):
        eye_points=eye_xy if n==1 else rod_eye_xy
        m=Mesh().tube((0,0,z),54,44.4,60,(1,0,0))
        m.tube((-28.5,0,z),44.4,34.8,3,(1,0,0))
        m.box((0,0,z+sign*56),(60,32,24))
        m.box((0,0,z+sign*64),(128,80,8) if n==1 else (120,70,8))
        eye=replace(obj('FA-525',n),m)
        holes(eye,[((0,0,z),44.4,55,(1,0,0)),((29,0,z),45.6,4,(1,0,0))]
            +[((x,y,z+sign*64),6.5,12,axial) for x,y in eye_points])
        if n==1:
            # The eye is attached after closing the cap. Reliefs must leave the
            # already installed cap washers and heads completely unobstructed.
            holes(eye,[((x,y,64),12.5,12,axial) for x,y in radial])
        if n==2:
            # Open scallops expose the heads beside the bearing without entering
            # its spherical seat or the pin bore.
            holes(eye,[((x,y,z-52),13,16,axial) for x,y in eye_points])
        replace(obj('FA-526',n),spherical_bearing((0,0,z),(1,0,0),44,25,54),.2)
        clip=replace(obj('FA-527',n),Mesh().tube((28.5,0,z),45.4,34.5,3,(1,0,0)),.15)
        boxcut(clip,(28.5,0,z+40),(5,3,20))
        fasteners('H-12040',range(1+(n-1)*2,3+(n-1)*2),[(x,y,z+sign*57.5) for x,y in eye_points],(0,0,sign))

    # Manufactured sensor modules have an internal probe and an external mounting
    # flange: screws and blue sensing feature are separate and remain accessible.
    for n,z in ((1,110),(2,502)):
        # Offset the mounting ear away from the longitudinal cap bolt and the
        # rear-eye receiver boss; the sensing probe keeps its axial datum.
        m=Mesh().box((76,-14,z),(8,56,50)).cyl((67,0,z+11.75),6,22,(1,0,0),mat=1)
        sensor=replace(obj('FA-528',n),m)
        holes(sensor,[((76,-28,z-12),6.5,12,(1,0,0))])
    for n,z in ((1,89),(2,551)):
        gasket=replace(obj('FA-529',n),Mesh().tube((0,0,z),70,64,2),0)
        holes(gasket,[((x,y,z),6.5,4,axial) for x,y in radial])
        if n==1:holes(gasket,[((x,y,z),10.5,4,axial) for x,y in eye_xy])
    m=Mesh().tube((80,0,185),14,8,32,(1,0,0)).tube((72,0,185),18,8,4,(1,0,0))
    replace(obj('FA-530'),m)
    spec['socket']=list(world((96,0,185)))

    fasteners('H-12030',range(21,23),[(82.5,-28,z-12) for z in (110,502)],(-1,0,0))
    fasteners('H-12050',range(1,5),[(x,y,65.5) for x,y in radial],axial)
    fasteners('H-12050',range(5,9),[(x,y,574.5) for x,y in radial])
    fasteners('H-12040',range(5,9),[(x,y,120.5) for x,y in motor_xy])
    fasteners('H-12040',range(9,13),[(x,y,168.5) for x,y in gear_xy])
    fasteners('H-12030',range(23,25),[(24,19.5,z) for z in (207,233)],(0,-1,0))
    fasteners('H-12040',range(13,15),[(x,0,rear+12.5) for x in (-50,50)])
    fasteners('H-12040',range(15,17),[(0,y,282.5) for y in (-42,42)])
    fasteners('H-12030',range(25,27),[(x,16.5,292) for x in (-29,29)],(0,-1,0))
    fasteners('H-12030',range(27,29),[(58,42.5,z) for z in (430,490)],(0,1,0))

    # Parent hardware uses the outboard side for both pins and keepers. A side
    # landing on the cradle avoids putting the base mounting bolts in the eye.
    # Only these two receiving frame instances gain pitch-specific machined holes.
    def local_mesh(mesh):
        mesh.v=[((vec(p)-b).dot(u),(vec(p)-b).dot(v),(vec(p)-b).dot(d)) for p in mesh.v]
        return mesh
    def local_point(p):
        q=vec(p)-b
        return (q.dot(u),q.dot(v),q.dot(d))
    def world_fastener(family,n,p,axis,diameter=12):
        screw=obj(family,n); washer=PARTS[PARTS.index(screw)+1]
        wt=2.5 if diameter==12 else 4
        replace(screw,local_mesh(screw_mesh(p,axis,diameter,int(family[-2:]))),0)
        replace(washer,local_mesh(Mesh().tube(vec(p)+vec(axis)*wt/2,12 if diameter==12 else 22,6.5 if diameter==12 else 13,wt,axis,n=32)),.15)
        for o in (screw,washer):o['insertion_axis']=list(axis)
    def world_bores(o,holes):bore(o,holes)
    X=Vector((1,0,0));Y=Vector((0,1,0));Z=Vector((0,0,1))
    cradle=obj('FA-103');ring=obj('FA-200')
    # Relieve the outrigger immediately around the eye; the two side lands and
    # their connecting lower web remain. This is away from the ankle/pad joints.
    bore(cradle,[(b,60,160,X)])
    for n,p in ((1,b),(2,vec(spec['tip']))):
        cm=Mesh()
        for sign in (-1,1):cm.tube(p+X*sign*48.5,45,25.4,35,X)
        if n==1:
            anchor=Vector((-625,800,425))
            cm.box(anchor,(30,180,50))
            for sign in (-1,1):
                for ysign in (-1,1):
                    shoulder=p+X*sign*48.5+Y*ysign*35-Z*25
                    landing=Vector((p.x+sign*48.5,p.y+ysign*65,425))
                    cm.beam(shoulder,landing,24)
                    cm.beam(landing,Vector((-625,p.y+ysign*65,425)),24)
            points=[Vector((-644,p.y+s*65,425)) for s in (-1,1)]
            mounting_axis=X
        else:
            anchor=Vector((-370,300,1075))
            cm.box(anchor,(132,120,30))
            # Open bridge over the eye leaves both pin approaches unobstructed.
            for sign in (-1,1):
                shoulder=p+X*sign*48.5+Z*35
                elbow=p+X*sign*48.5+Z*78
                cm.beam(shoulder,elbow,25)
                cm.beam(elbow,anchor+X*sign*40,25)
            points=[anchor+X*s*40+Z*19 for s in (-1,1)]
            mounting_axis=-Z
        # Integral outboard keeper boss. It sits beyond the pin hole's radius.
        cm.box(p-X*58.5+Y*51,(35,28,40))
        clevis=replace(obj('FA-220',n),local_mesh(cm),.8)
        world_bores(clevis,[(p,25.4,154,X)]
            # Continue through the integral braces, not just the landing plate.
            +[(q+mounting_axis*30,12.8,160,mounting_axis) for q in points]
            +[(p-X*65+Y*51,6.2,32,X)])
        receiver=cradle if n==1 else ring
        # Threaded receiver holes continue along the same axes as the clearances.
        world_bores(receiver,[(q+mounting_axis*45,12.2,80,mounting_axis) for q in points])
        for j,q in enumerate(points):world_fastener('H-24070',13+(n-1)*2+j,q,mounting_axis,24)
        pin=replace(obj('FA-221',n),local_mesh(Mesh().cyl(p,25,132,X).cyl(p-X*71,33,10,X)),.4)
        keeper=replace(obj('FA-222',n),local_mesh(Mesh().box(p-X*81+Y*40,(10,50,36))),.4)
        world_bores(keeper,[(p-X*81+Y*51,6.5,14,X)])
        world_fastener('H-12030',28+n,p-X*88.5+Y*51,X)
