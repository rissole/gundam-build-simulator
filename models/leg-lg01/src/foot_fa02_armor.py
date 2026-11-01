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
from kit.plates import loft

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
    joined=parts[0] if len(parts)==1 else combine(parts,'Machined closed shells')
    obj.data=joined.data.copy()
    bpy.data.objects.remove(joined,do_unlink=True)
    # All shell source objects are baked at world identity before machining.
    if not mesh.users:bpy.data.meshes.remove(mesh)


def beam(a,b,width,material):
    a,b=Vector(a),Vector(b)
    return place(chamfered_box((width,width,(b-a).length),bevel=.003,material=material),
                 (a+b)/2,b-a)


def cap_machining_slivers(obj):
    """Close only triangular Boolean rims left on shallow inside folds."""
    bm=bmesh.new();bm.from_mesh(obj.data)
    boundary={e for e in bm.edges if e.is_boundary}
    while boundary:
        edge=boundary.pop();rim={edge};pending=[edge]
        while pending:
            for v in pending.pop().verts:
                for other in v.link_edges:
                    if other in boundary:boundary.remove(other);rim.add(other);pending.append(other)
        verts=list({v for e in rim for v in e.verts})
        assert len(rim)==len(verts)==3 and max(v.co.y for v in verts)-min(v.co.y for v in verts)<1e-6, \
            'Unexpected non-triangular slot-end boundary'
        assert all(.600<abs(v.co.x)<.731 and .600<v.co.z<.701 for v in verts)
        # holes_fill can skip these narrow triangles after bore retessellation;
        # the measured closed three-edge rim defines its cap unambiguously.
        bm.faces.new(verts)
    assert all(e.is_manifold for e in bm.edges),'Unexpected upper-plate machining boundary'
    bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces))
    bm.to_mesh(obj.data);bm.free();obj.data.update()


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


def side_panel(ctx,outline,sign,x=.730,material='armor',facet=.005):
    # Local XY = (fore/aft, height), local thickness = lateral wall.
    obj=plate(outline,.020,facet,material=ctx.materials[material])
    for v in obj.data.vertices:
        y,z,t=v.co;v.co=(sign*(x-.020+t),y,z)
    return finish(obj,wear=True)


def folded_shell(ctx,regions,zfunc,open_y,crease=.630,drop=.060,bottom=None,lower_facet=None):
    """Continuous roof/side/nose skin, thickened inward from shared fold edges.

    Regions only divide paint or roof slopes; they never divide the physical
    skin. Side walls use the exact roof boundary, including crease intersections
    at plan chamfers. This prevents triangular daylight at folded corners.
    """
    def clip(poly,x,greater):
        result=[]
        for a,b in zip(poly,poly[1:]+poly[:1]):
            ina=a[0]>=x-1e-9 if greater else a[0]<=x+1e-9
            inb=b[0]>=x-1e-9 if greater else b[0]<=x+1e-9
            if ina:result.append(a)
            if ina!=inb:
                t=(x-a[0])/(b[0]-a[0]);result.append((x,a[1]+t*(b[1]-a[1])))
        return result
    vertices=[];lookup={};faces=[];indices=[]
    materials=list(dict.fromkeys(material for outline,material in regions))
    def vertex(p):
        key=tuple(round(v,8) for v in p)
        if key not in lookup:lookup[key]=len(vertices);vertices.append(p)
        return lookup[key]
    for outline,material in regions:
        if lower_facet:
            # Taper the lower fold over 80 mm before each existing plan corner.
            # The chamfered rail-end clearances keep their original profile.
            split=[]
            for a,b in zip(outline,outline[1:]+outline[:1]):
                split.append(a)
                if abs(abs(a[0])-.730)>1e-8 or abs(a[0]-b[0])>1e-8:continue
                cuts=[y for y in (lower_facet[0]+.080,lower_facet[1]-.080)
                      if min(a[1],b[1])<y<max(a[1],b[1])]
                split.extend((a[0],y) for y in sorted(cuts,reverse=b[1]<a[1]))
            outline=split
        polys=[clip(outline,-crease,False),clip(clip(outline,-crease,True),crease,False),clip(outline,crease,True)]
        for poly in polys:
            ids=[]
            for x,y in poly:
                idx=vertex((x,y,zfunc(y)-max(0,abs(x)-crease)*drop/(.730-crease)))
                if not ids or ids[-1]!=idx:ids.append(idx)
            if ids and ids[0]==ids[-1]:ids.pop()
            if len(ids)>=3:faces.append(ids);indices.append(materials.index(material))
    edges=Counter(tuple(sorted((a,b))) for f in faces for a,b in zip(f,f[1:]+f[:1]))
    for f,material_index in list(zip(faces,indices)):
        for a,b in zip(f,f[1:]+f[:1]):
            if edges[tuple(sorted((a,b)))]!=1:continue
            ax,ay,az=vertices[a];bx,by,bz=vertices[b]
            if any(abs(ay-y)<1e-8 and abs(by-y)<1e-8 for y in open_y):continue
            za=bottom(ax,ay) if bottom else .200
            zb=bottom(bx,by) if bottom else .200
            def inset(x,y):
                if not lower_facet or abs(abs(x)-.730)>1e-8:return x
                taper=max(0,min(1,(y-lower_facet[0])/.080,(lower_facet[1]-y)/.080))
                return x-(.030 if x>0 else -.030)*taper
            low_a=vertex((inset(ax,ay),ay,za))
            low_b=vertex((inset(bx,by),by,zb))
            if lower_facet:
                shoulder_a=vertex((ax,ay,.300));shoulder_b=vertex((bx,by,.300))
                faces.extend([(b,a,shoulder_a,shoulder_b),(shoulder_b,shoulder_a,low_a,low_b)])
                indices.extend([material_index]*2)
            else:
                faces.append((b,a,low_a,low_b));indices.append(material_index)
    obj=mesh_object('Continuous folded shell',vertices,faces,
                    [ctx.materials[m] for m in materials],indices)
    bpy.context.view_layer.objects.active=obj
    mod=obj.modifiers.new('20 mm inward folded skin','SOLIDIFY')
    mod.thickness=.020;mod.offset=-1;mod.use_even_offset=True
    if lower_facet:
        mod.solidify_mode='EXTRUDE';mod.use_quality_normals=True
    bpy.ops.object.modifier_apply(modifier=mod.name)
    return finish(obj,wear=True)


def toe_z(y):return .600-(y-1.500)*(.080/.900) if y<=2.400 else .520-(y-2.400)*2


def shell_meshes(ctx):
    m=ctx.materials
    # Toe: low two-slope cap, open at the rear and underside, ochre paint only
    # on the front band. The large plan facets are 80–100 mm, wall stays 20 mm.
    white=[(-.630,1.500),(.630,1.500),(.730,1.600),(.730,2.240),(-.730,2.240),(-.730,1.600)]
    band=[(-.730,2.240),(.730,2.240),(.730,2.360),(.690,2.400),(-.690,2.400),(-.730,2.360)]
    nose=[(-.690,2.400),(.690,2.400),(.630,2.460),(-.630,2.460)]
    toe=folded_shell(ctx,[(white,'armor'),(band,'ochre'),(nose,'ochre')],toe_z,(1.500,),
                     bottom=lambda x,y:.200+max(0,1.580-y),lower_facet=(1.600,2.360))

    # Rear-open U shell. Cuts extend through every folded feature in their area.
    outline=[(x,y+.355) for x,y in chamfered_rect(1.460,1.710,.080)]
    upper=folded_shell(ctx,[(outline,'armor')],lambda y:.700,(-.500,1.210),crease=.650,drop=.080,
                       bottom=lambda x,y:.200+max(0,y-1.130,-.420-y),lower_facet=(-.420,1.130))
    difference(upper,chamfered_box((1.180,1.100,.2),(0,0,.700),0))
    difference(upper,chamfered_box((.170,.320,.2),(-.535,.710,.700),0))
    # Straight +Z clearance for the fixed guard posts, bosses and tab sockets.
    # These open skirt slots continue through the roof; a 40 mm half-width
    # clears the 24/25 mm receiver radii by >=15 mm. The inboard roof ligament
    # retains the original X+/-590 rear notch. Neither plate mount nor tab moves.
    for s in (-1,1):
        for y0,y1 in ((-.540,-.440),(.460,.540),(.660,.830)):
            difference(upper,chamfered_box((.210,y1-y0,.800),
                                          (s*.730,(y0+y1)/2,.450),0))
    # One sparse 25 mm panel score; 4 mm deep in the 20 mm skin.
    difference(upper,chamfered_box((.950,.025,.010),(0,1.135,.701),.001))
    # Exact cuts through the shallow inside fold can leave triangular slivers
    # uncapped at a slot end. Close only those planar three-edge machining rims;
    # the notch and clearance slots themselves remain through the solid skin.
    cap_machining_slivers(upper)

    # Heel: short rear closure with front opening; sparse red caution bar.
    heel=[folded_shell(ctx,[([(-.630,-.900),(.630,-.900),(.730,-.800),(.730,-.500),
                             (-.730,-.500),(-.730,-.800)],'armor')],lambda y:.600,(-.500,),drop=.100)]
    heel.append(chamfered_box((.250,.0003,.014),(0,-.90015,.460),0,m['red']))
    heel.append(chamfered_box((.170,.0003,.004),(-.040,-.90015,.437),0,m['red']))
    heel=combine(heel,'FA-402 heel with caution paint')

    guards=[]
    contour=[(-.730,.700),(-.630,.600),(.750,.600),(.950,.800),(.850,1.090),
             (.570,1.530),(.450,1.600),(-.450,1.600),(-.570,1.530),(-.730,1.050)]
    for s in (1,-1):
        guard=side_panel(ctx,contour,s,facet=.080)
        window=prism(chamfered_rect(.400,.360,.060),.100)
        for v in window.data.vertices:
            y,z,t=v.co;v.co=(s*(.680+t),y,1.000+z)
        difference(guard,finish(window))
        # Machine depressions while the wall is one continuous solid, before
        # adding the intersecting integral lands and locator feature shells.
        for y,z in GUARD_SITES:
            outline=chamfered_rect(.130,.130,.038)
            well=loft([(-.016,[(a*.43,b*.43) for a,b in outline]),
                       (0,outline),(.025,outline)])
            difference(guard,place(well,(s*.730,y,z),(s,0,0)))
        guards.append(guard)
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
            # One low backbone per side, outside the pitch drive, supports the
            # unchanged four threaded seats and two locator sockets. Its top
            # remains below the upper roof; it clears the inset skirt as well.
            add(owner,[beam((s*.530,0,.850),(s*.530,0,.580),.028,m['gunmetal']),
                       beam((s*.530,0,.580),(s*.650,0,.580),.028,m['gunmetal']),
                       beam((s*.650,-.650,.580),(s*.650,.790,.580),.018,m['gunmetal'])])
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
            if pid not in {'FA-403-L','FA-404-L'}:
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
                # Route below the upper roof, then rise through its dedicated
                # skirt slots. The old diagonal high arms crossed the plate's
                # bolt lands during +Z removal, even after the rear relief.
                supports=[beam((s*.650,p.y,.580),(s*.661,p.y,.580),.018,m['gunmetal']),
                          beam((s*.661,p.y,.580),seat-n*.023,.028,m['gunmetal'])]
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
            else:
                receiver=owner;s=1 if p.x>0 else -1
                route=[(s*.650,p.y,.580),(s*.680,p.y,.580),p-n*.020]
                add(receiver,[socket,*[beam(a,b,.018,m['gunmetal']) for a,b in zip(route,route[1:])]])
                continue
            add(receiver,[socket,beam(anchor,p-n*.020,.018,m['gunmetal'])])
        # Bore machining can retriangulate those same shallow slot ends.
        if pid=='FA-401-L':cap_machining_slivers(shell)
        finish(shell,wear=True)
        if pid in {'FA-403-L','FA-404-L'}:
            # The perimeter only drops 6 mm across an 80 mm facet. Weighted
            # smooth normals erase that shallow fold and the octagonal wells.
            for face in shell.data.polygons:face.use_smooth=False


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
