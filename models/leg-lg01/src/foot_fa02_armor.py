"""FA-02 P4B: five removable shells, six pads and exactly 132 hardware pieces.

All coordinates are metres. Existing registered frame meshes receive integral
bosses/tab sockets here; no extra inventory objects or FA-01 source edits. Solid
features are closed visualization shells, matching the common kit contract.
"""
import csv
from collections import Counter
from pathlib import Path
import bpy
import bmesh
from mathutils import Vector
from kit import (prism, plate, chamfered_rect, chamfered_box, cylinder, tube,
                 combine, difference, finish, place, mesh_object)

SPEC=Path(__file__).resolve().parents[3]/'design/legs/foot-and-ankle'
ROWS=list(csv.DictReader((SPEC/'foot-components.csv').open()))
ARMOR_ROWS={(r['part_id'],r['name']) for r in ROWS
            if r['part_id'] in {'FA-302','FA-303','FA-304','FA-305','FA-400',
                                'FA-401-L','FA-402','FA-403-L','FA-404-L','FA-405'}
            or r['name'].endswith((' - Sole pad mounts',' - Armor captive bolts'))}
PAD_PAIRS=(('FA-302',-.850,-.110),('FA-303',-.070,1.220),('FA-304',1.480,2.440))
GUARD_SITES=((-0.600,.720),(.700,.720),(-.500,1.450),(.500,1.450))


def register(ctx,obj,pid,no=1,use=None,owner=None,removal=None):
    row=next(r for r in ROWS if r['part_id']==pid and
             (use is None or r['name'].endswith(' - '+use)))
    ctx.register(obj,pid,row['name'],row['subassembly'],row['category'],row['finish'],no)
    obj['component']='foot';obj['spec_revision']='FA-02'
    if use:obj['hardware_use']=use
    if owner:obj['owner_instance']=owner['instance_id']
    if removal is not None:obj['removal_direction']=list(removal)
    return obj


def find(ctx,pid):return next(o for o in ctx.parts if o['part_id']==pid)


def add(receiver,pieces):
    """Retain the existing registered object, properties and mesh identity."""
    name=receiver.name;meshname=receiver.data.name
    combine([receiver,*pieces],name)
    receiver.data.name=meshname
    finish(receiver)


def closed_bore(obj,radius,depth,p,axis):
    """Machine each closed manufactured feature without welding coincident seams."""
    mesh=obj.data;bm=bmesh.new();bm.from_mesh(mesh)
    unseen=set(bm.faces);parts=[]
    while unseen:
        start=unseen.pop();faces={start};pending=[start]
        while pending:
            for e in pending.pop().edges:
                for f in e.link_faces:
                    if f in unseen:unseen.remove(f);faces.add(f);pending.append(f)
        verts=list({v for f in faces for v in f.verts});indices={v:i for i,v in enumerate(verts)}
        faces=list(faces)
        piece=mesh_object('Closed machining feature',[v.co[:] for v in verts],
                          [[indices[v] for v in f.verts] for f in faces],list(mesh.materials),
                          [f.material_index for f in faces])
        piece.matrix_world=obj.matrix_world.copy()
        coords=[piece.matrix_world@v.co for v in piece.data.vertices]
        # Broad sphere bound deliberately overestimates the oriented tool.
        reach=depth/2+radius
        if all(min(v[k] for v in coords)<=p[k]+reach and max(v[k] for v in coords)>=p[k]-reach for k in range(3)):
            difference(piece,cutter(radius,depth,p,axis))
        parts.append(piece)
    bm.free()
    joined=combine(parts,'Machined closed shells')
    obj.data=joined.data.copy()
    bpy.data.objects.remove(joined,do_unlink=True)
    # All shell source objects are baked at world identity before machining.
    if not mesh.users:bpy.data.meshes.remove(mesh)


def beam(a,b,width,material):
    a,b=Vector(a),Vector(b)
    return place(chamfered_box((width,width,(b-a).length),bevel=.003,material=material),
                 (a+b)/2,b-a)


def cutter(radius,depth,p,axis=(0,0,1),segments=32):
    return cylinder(radius,depth,p,axis,segments=segments,bevel=0)


def hardware(ctx,p,normal,diameter,length,use,index,owner):
    """p = under-head bearing plane; normal points toward accessible head."""
    p,n=Vector(p),Vector(normal)
    m=ctx.materials;h=diameter;wt=.004 if diameter==.024 else .0025
    shaft=cylinder(diameter/2,length,p-n*length/2,n,segments=12,bevel=.0003,material=m['steel'])
    head=cylinder(diameter*.75,h,p+n*h/2,n,segments=32,bevel=.001,material=m['gunmetal'])
    difference(head,cutter(diameter*.31,h*.65,p+n*h*.85,n,6))
    bolt=combine([shaft,head],'Recessed socket bolt')
    washer=tube(.022 if diameter==.024 else .012,.013 if diameter==.024 else .0065,
                wt,p-n*wt/2,n,segments=32,bevel=.0002,material=m['steel'])
    pid='H-24120' if diameter==.024 else 'H-12050-C'
    register(ctx,bolt,pid,index,use,owner,normal)
    register(ctx,washer,'W-24' if diameter==.024 else 'W-12',index,use,owner,normal)
    bolt['paired_instance_id']=washer['instance_id'];washer['paired_instance_id']=bolt['instance_id']
    return bolt,washer


def pads(ctx):
    m=ctx.materials;n=0
    for pid,y0,y1 in PAD_PAIRS:
        carrier=find(ctx,'FA-301' if pid=='FA-304' else 'FA-300')
        for copy,s in enumerate((-1,1),1):
            x0,x1=(-.695,-.025) if s<0 else (.025,.695)
            sites=[(x,y) for x in (x0+.100,x1-.100) for y in (y0+.100,y1-.100)]
            outline=[(x+(x0+x1)/2,y+(y0+y1)/2) for x,y in chamfered_rect(.670,y1-y0,.060)]
            obj=finish(prism(outline,.140,'Rubber grip pad',m['rubber']),bevel=.020)
            # Genuine underside tread cuts. Four circular bolt lands interrupt
            # only grooves close to a counterbore, retaining 12 mm tread relief.
            y=y0+.100
            while y<y1-.040:
                spans=[(x0+.040,x1-.040)]
                for bx,by in sites:
                    if abs(y-by)<.055:
                        spans=[piece for a,b in spans for piece in ((a,min(b,bx-.046)),(max(a,bx+.046),b))
                               if piece[1]-piece[0]>.003]
                for a,b in spans:
                    difference(obj,chamfered_box((b-a,.030,.026),((a+b)/2,y,-.001),.002))
                y+=.120
            for x,y in sites:
                difference(obj,cutter(.0212,.160,(x,y,.080)))
                difference(obj,cutter(.028,.070,(x,y,.029))) # floor / sleeve start Z64
            finish(obj,bevel=.0006)
            register(ctx,obj,pid,copy,owner=carrier,removal=(0,0,-1))
            for x,y in sites:
                n+=1
                sleeve=tube(.021,.013,.076,(x,y,.102),bevel=.0003,material=m['steel'],segments=32)
                register(ctx,sleeve,'FA-305',n,owner=obj,removal=(0,0,-1))
                hardware(ctx,(x,y,.060),(0,0,-1),.024,.120,'Sole pad mounts',n,obj)


def side_panel(ctx,outline,sign,x=.730,material='armor'):
    # Local XY = (fore/aft, height), local thickness = lateral wall.
    obj=plate(outline,.020,.005,material=ctx.materials[material])
    for v in obj.data.vertices:
        y,z,t=v.co;v.co=(sign*(x-.020+t),y,z)
    return finish(obj,wear=True)


def roof(ctx,outline,zfunc,material='armor',crease=.630,drop=.060):
    """One closed 20 mm skin with broad folded edge facets, no internal seams."""
    def clip(poly,x,greater):
        result=[]
        for a,b in zip(poly,poly[1:]+poly[:1]):
            ina=a[0]>=x-1e-9 if greater else a[0]<=x+1e-9
            inb=b[0]>=x-1e-9 if greater else b[0]<=x+1e-9
            if ina:result.append(a)
            if ina!=inb:
                t=(x-a[0])/(b[0]-a[0]);result.append((x,a[1]+t*(b[1]-a[1])))
        return result
    regions=[clip(outline,-crease,False),clip(clip(outline,-crease,True),crease,False),clip(outline,crease,True)]
    xy=[];lookup={};polygons=[]
    for poly in regions:
        if len(poly)<3:continue
        indices=[]
        for q in poly:
            key=tuple(round(v,8) for v in q)
            if key not in lookup:lookup[key]=len(xy);xy.append(q)
            idx=lookup[key]
            if not indices or indices[-1]!=idx:indices.append(idx)
        if indices[0]==indices[-1]:indices.pop()
        if len(indices)>=3:polygons.append(indices)
    size=len(xy)
    vertices=[(x,y,zfunc(y)-max(0,abs(x)-crease)*drop/(.730-crease)-depth)
              for depth in (.020,0) for x,y in xy]
    faces=[tuple(reversed(f)) for f in polygons]+[tuple(k+size for k in f) for f in polygons]
    edges=Counter(tuple(sorted((a,b))) for f in polygons for a,b in zip(f,f[1:]+f[:1]))
    for f in polygons:
        for a,b in zip(f,f[1:]+f[:1]):
            if edges[tuple(sorted((a,b)))]==1:faces.append((a,b,b+size,a+size))
    return finish(mesh_object('Folded faceted skin',vertices,faces,ctx.materials[material]),wear=True)


def toe_z(y):return .600-(y-1.500)*(.080/.900) if y<=2.400 else .520-(y-2.400)*2


def shell_meshes(ctx):
    m=ctx.materials
    # Toe: low two-slope cap, open at the rear and underside, ochre paint only
    # on the front band. The large plan facets are 80–100 mm, wall stays 20 mm.
    white=[(-.630,1.500),(.630,1.500),(.730,1.600),(.730,2.240),(-.730,2.240),(-.730,1.600)]
    band=[(-.730,2.240),(.730,2.240),(.730,2.360),(.690,2.400),(-.690,2.400),(-.730,2.360)]
    nose=[(-.690,2.400),(.690,2.400),(.630,2.460),(-.630,2.460)]
    toe=[roof(ctx,white,toe_z),roof(ctx,band,toe_z,'ochre'),roof(ctx,nose,toe_z,'ochre')]
    for s in (-1,1):
        toe.append(side_panel(ctx,[(1.500,.280),(1.580,.200),(2.240,.200),(2.240,toe_z(2.240)-.060),
                                  (1.500,.540)],s))
        # Wrap the painted nose around its beveled plan corners.
        path=[(s*.730,2.240),(s*.730,2.360),(s*.630,2.460)]
        for (ax,ay),(bx,by) in zip(path,path[1:]):
            verts=[(x,y,z) for offset in (0,-s*.020) for x,y,z in
                   [(ax+offset,ay,.200),(bx+offset,by,.200),(bx+offset,by,toe_z(by)-max(0,abs(bx)-.630)*.6),(ax+offset,ay,toe_z(ay)-max(0,abs(ax)-.630)*.6)]]
            toe.append(finish(mesh_object('Painted folded toe band',verts,
                [(3,2,1,0),(4,5,6,7),(0,1,5,4),(1,2,6,5),(2,3,7,6),(3,0,4,7)],m['ochre']),wear=True))
    face=plate([(-.630,.200),(.630,.200),(.630,.400),(-.630,.400)],.020,.005,material=m['ochre'])
    for v in face.data.vertices:x,z,t=v.co;v.co=(x,2.460-t,z)
    toe.append(finish(face,wear=True))
    toe=combine(toe,'FA-400 folded toe cap')

    # Rear-open U shell. Cuts extend through every folded feature in their area.
    outline=[(x,y+.355) for x,y in chamfered_rect(1.460,1.710,.080)]
    upper=roof(ctx,outline,lambda y:.700,crease=.680,drop=.080)
    difference(upper,chamfered_box((1.180,1.100,.2),(0,0,.700),0))
    difference(upper,chamfered_box((.170,.320,.2),(-.535,.710,.700),0))
    # One sparse 25 mm panel score; 4 mm deep in the 20 mm skin.
    difference(upper,chamfered_box((.950,.025,.010),(0,1.135,.701),.001))
    walls=[side_panel(ctx,[(-.500,.280),(-.420,.200),(1.130,.200),(1.210,.280),
                           (1.210,.540),(1.130,.620),(-.420,.620),(-.500,.540)],s) for s in (-1,1)]
    upper=combine([upper,*walls],'FA-401 rear-open upper shell')

    # Heel: short rear closure with front opening; sparse red caution bar.
    face=plate([(-.650,.200),(.650,.200),(.730,.280),(.730,.500),(.630,.600),
                (-.630,.600),(-.730,.500),(-.730,.280)],.020,.005,material=m['armor'])
    for v in face.data.vertices:x,z,t=v.co;v.co=(x,-.900+t,z)
    heel=[finish(face,wear=True)]
    for s in (-1,1):
        heel.append(side_panel(ctx,[(-.900,.280),(-.820,.200),(-.500,.200),(-.500,.500),(-.900,.500)],s))
    heel.append(roof(ctx,[(-.630,-.900),(.630,-.900),(.730,-.800),(.730,-.500),
                          (-.730,-.500),(-.730,-.800)],lambda y:.600,drop=.100))
    heel.append(chamfered_box((.250,.0003,.014),(0,-.90015,.460),0,m['red']))
    heel.append(chamfered_box((.170,.0003,.004),(-.040,-.90015,.437),0,m['red']))
    heel=combine(heel,'FA-402 heel with caution paint')

    guards=[]
    contour=[(-.730,.700),(-.630,.600),(.750,.600),(.950,.800),(.850,1.090),
             (.570,1.530),(.450,1.600),(-.450,1.600),(-.570,1.530),(-.730,1.050)]
    for s in (1,-1):guards.append(side_panel(ctx,contour,s))
    return [('FA-400',toe,'FA-106',(0,0,1)),('FA-401-L',upper,'FA-102',(0,0,1)),
            ('FA-402',heel,'FA-101',(0,-1,0)),('FA-403-L',guards[0],'FA-103-L',(1,0,0)),
            ('FA-404-L',guards[1],'FA-103-L',(-1,0,0))]


def armor(ctx):
    m=ctx.materials;number=0
    for pid,shell,receiver_id,removal in shell_meshes(ctx):
        owner=find(ctx,receiver_id)
        register(ctx,shell,pid,owner=owner,removal=removal)
        if pid=='FA-400':
            sites=[((x,y,toe_z(y)),(0,0,1)) for x in (-.560,.560) for y in (1.630,2.310)]
        elif pid=='FA-401-L':sites=[((x,y,.700),(0,0,1)) for x in (-.650,.650) for y in (-.300,1.060)]
        elif pid=='FA-402':sites=[((x,-.900,z),(0,-1,0)) for x in (-.560,.560) for z in (.300,.500)]
        else:
            s=1 if pid=='FA-403-L' else -1
            sites=[((s*.730,y,z),(s,0,0)) for y,z in GUARD_SITES]
        shell['attachment_count']=4;shell['tab_count']=2
        for p,n in sites:
            p,n=Vector(p),Vector(n);number+=1
            # Recessed well with a 30 mm land below its washer-bearing floor.
            closed_bore(shell,.025,.120,p-n*.030,n)
            land=tube(.036,.0065,.030,p-n*.031,n,segments=32,bevel=.0003,material=m['armor'])
            # Collar sits inside a dedicated back counterbore in the land.
            difference(land,cutter(.0092,.0042,p-n*.044,n))
            add(shell,[land])
            # A thin octagonal annulus returns the cut skin to its land and
            # creates a visible dark well. It never adds a decorative bolt.
            rim=tube(.026,.020,.016,p-n*.008,n,segments=8,bevel=.0004,material=m['armor'])
            add(shell,[rim])
            collar=tube(.009,.006,.004,p-n*.044,n,segments=24,bevel=.0002,material=m['gunmetal'])
            register(ctx,collar,'FA-405',number,owner=shell,removal=removal)
            hardware(ctx,p-n*.0135,n,.012,.050,'Armor captive bolts',number,shell)
            seat=p-n*.046
            boss=tube(.024,.006,.026,seat-n*.013,n,segments=32,bevel=.0002,material=m['gunmetal'])
            # Route support to the appropriate fixed or moving frame member.
            if pid=='FA-400':
                receiver=find(ctx,'FA-104-'+('A' if p.x<0 else 'B'))
                anchor=(p.x,p.y,.420);end=seat-n*.023
            elif pid=='FA-401-L':
                receiver=find(ctx,'FA-100-'+('A' if p.x<0 else 'B'))
                anchor=(.625 if p.x>0 else -.625,p.y,.420);end=seat-n*.023
            elif pid=='FA-402':
                receiver=find(ctx,'FA-100-'+('A' if p.x<0 else 'B'))
                anchor=(p.x,-.760,min(p.z,.420));end=seat-n*.023
            else:
                receiver=owner;s=1 if p.x>0 else -1
                # Edge posts stay lateral, outside the moving lower shin.
                anchor=(s*.530,0,1.100 if p.z>1 else .850)
                elbow=(s*.660,p.y,1.080 if p.z>1 else .720)
                supports=[beam(anchor,elbow,.028,m['gunmetal']),beam(elbow,seat-n*.023,.028,m['gunmetal'])]
                anchor=None
            if anchor:supports=[beam(anchor,end,.030,m['gunmetal'])]
            for support in supports:
                difference(support,cutter(.006,.140,p-n*.070,n))
            add(receiver,supports)
            add(receiver,[boss])
        # Two 10 mm sliding locators. Rectangular socket bores are open along
        # the removal axis; tabs do not hook across or trap adjacent shells.
        if pid in {'FA-400','FA-401-L'}:
            y=1.850 if pid=='FA-400' else 1.100
            tab_sites=[(s*.690,y,(toe_z(y)-.036 if pid=='FA-400' else .684)-.030) for s in (-1,1)]
        elif pid=='FA-402':tab_sites=[(s*.660,-.870,.380) for s in (-1,1)]
        else:
            s=1 if pid=='FA-403-L' else -1
            tab_sites=[(s*.700,y,.900) for y in (-.650,.790)]
        for p in tab_sites:
            p,n=Vector(p),Vector(removal)
            tab=place(chamfered_box((.032,.016,.040),bevel=.001,material=m['armor']),p,n)
            socket=place(chamfered_box((.050,.034,.010),bevel=.001,material=m['gunmetal']),p-n*.015,n)
            tool=place(chamfered_box((.033,.017,.025),bevel=0),p-n*.015,n)
            difference(socket,tool)
            add(shell,[tab])
            # Socket arms belong to the same owner as the shell, with no
            # additional bracket inventory. Their endpoints avoid the ring.
            if pid in {'FA-400','FA-401-L'}:
                receiver=find(ctx,('FA-104-' if pid=='FA-400' else 'FA-100-')+('A' if p.x<0 else 'B'))
                anchor=(p.x*.91,p.y,.420)
            elif pid=='FA-402':
                receiver=find(ctx,'FA-100-'+('A' if p.x<0 else 'B'));anchor=(p.x*.90,-.760,.380)
            else:receiver=owner;anchor=(p.x*.78,0,1.100)
            add(receiver,[socket,beam(anchor,p-n*.020,.018,m['gunmetal'])])
        finish(shell,wear=True)


def build(ctx):
    before=len(ctx.parts)
    print('FA02 ARMOR pads',flush=True);pads(ctx)
    print('FA02 ARMOR shells and attachments',flush=True);armor(ctx)
    new=ctx.parts[before:]
    expected=Counter({(r['part_id'],r['name']):int(r['qty_per_leg']) for r in ROWS
                      if (r['part_id'],r['name']) in ARMOR_ROWS})
    actual=Counter((o['part_id'],o['part_name']) for o in new)
    assert actual==expected,(actual-expected,expected-actual)
    print('FA02 ARMOR COMPLETE:',len(new),'independent meshes; 14 complete CSV rows',flush=True)
