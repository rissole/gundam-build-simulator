"""LG-01 removable thigh armor and local helpers. Distances in metres.

Integral standoffs, captive fasteners and decal sheets stay in their plate mesh.
The section function maps a flat kit plate onto a piecewise-linear limb surface.
"""
import math
import bpy
import bmesh
from mathutils import Vector
from kit import (plate, combine, finish, difference, chamfered_box, chamfered_rect,
                 recessed_hex_bolt, panel_line, normals, mesh_object, prism)
from materials import decal
from thigh import register, box, strut


def clean(obj):
    """Remove collapsed kit bevel edges without moving the visible surface."""
    bm=bmesh.new(); bm.from_mesh(obj.data)
    bmesh.ops.dissolve_degenerate(bm,dist=1e-7,edges=list(bm.edges))
    bm.to_mesh(obj.data); bm.free(); obj.data.update()
    finish(obj,angle=12,wear=True)
    # Flat armor facets must not inherit broad interpolated normals from the
    # unbent kit plate, which produce false dents around grooves and bolt wells.
    for face in obj.data.polygons: face.use_smooth=False
    return obj


def interp(z, points):
    for (a,x),(b,y) in zip(points,points[1:]):
        if z <= b: return x+(y-x)*max(0,min(1,(z-a)/(b-a)))
    return points[-1][1]


def profile(points,offset=0):
    def sample(z): return interp(z,points)+offset
    sample.knots=[z for z,value in points]
    return sample


def mapped(obj, face, surface, side=1):
    # Input: local X across panel, Y up limb, Z outward from the back skin.
    bpy.context.view_layer.update()
    obj.data.transform(obj.matrix_world)
    obj.matrix_world.identity()
    # Split planar faces at each change in slope before bending the skin.
    # Otherwise a long n-gon triangulates across the bend and its groove floor.
    if getattr(surface,'knots',None):
        bm=bmesh.new(); bm.from_mesh(obj.data)
        for z in surface.knots:
            bmesh.ops.bisect_plane(bm,geom=list(bm.verts)+list(bm.edges)+list(bm.faces),
                                  plane_co=(0,z,0),plane_no=(0,1,0),dist=1e-7)
        bm.to_mesh(obj.data);bm.free();obj.data.update()
    for vert in obj.data.vertices:
        u,z,w=vert.co
        d=surface(z)+w
        vert.co=(u,d,z) if face=='front' else ((u,-d,z) if face=='back' else (side*d,u,z))
    return clean(normals(obj))


def panel(ctx, outline, bolts=(), grooves=(), cuts=(), marks=(), slots=(), accent=None, chamfer=None, inserts=(), channels=()):
    m=ctx.materials
    center=(min(z for u,z in outline)+max(z for u,z in outline))/2
    local=[(u,z-center) for u,z in outline]
    chamfer=chamfer if chamfer is not None else min(.075,(max(z for u,z in local)-min(z for u,z in local))*.20)
    skin=plate(local,.060,chamfer,material=m[accent or 'armor'])
    skin.location.y=center
    for cut_center,size in cuts:
        difference(skin,chamfered_box(size,cut_center,.025,m['recess']))
    channel_loops=[]
    for u,z,width in channels:
        # Top-open channel with a faceted entry and a real inward return.
        # The straight throat retains the old cartridge clearance width.
        loop=[(u-width/2,z),(u+width/2,z),(u+width/2,z+.72),
              (u+width/2+.08,z+.98),(u+width/2+.08,z+1.60),
              (u-width/2-.08,z+1.60),(u-width/2-.08,z+.98),(u-width/2,z+.72)]
        channel_loops.append(loop)
        difference(skin,prism(loop,.24,'Faceted cartridge channel',z=-.12))
    for path in grooves:
        panel_line(skin,[(u,z-center) for u,z in path],.060,.025,.015,m['recess'])
    features=[skin]
    for u,z in bolts:
        features.append(recessed_hex_bolt(skin,(u,z-center,.060),.025,
                                         well_radius=.042,well_depth=.032,material=m['gunmetal']))
    for u,z,w,h in slots:
        cutter=chamfered_box((w,h,.038),(u,z,.054),.018,m['recess'])
        difference(skin,cutter)
        features.append(chamfered_box((w-.008,h-.008,.008),(u,z,.032),.015,m['recess']))
    for u,z,w,h in inserts:
        # A 25 mm surrounding recess, with a broad gunmetal face 20 mm below paint.
        difference(skin,chamfered_box((w+.050,h+.050,.045),(u,z,.0535),.024,m['recess']))
        features.append(chamfered_box((w+.046,h+.046,.008),(u,z,.032),.022,m['recess']))
        features.append(chamfered_box((w,h,.012),(u,z,.034),.018,m['gunmetal']))
    for kind,u,z,width in marks:
        mark=decal(kind,width)
        mark.location=(u,z,.0607)
        features.append(mark)
    # Machine overlapping details individually before joining closed solids.
    # Cutting the already intersecting combined shells makes invalid Boolean
    # edges; cutting only the skin would leave insert backing in the channel.
    bpy.context.view_layer.update()
    for feature in features[1:]:
        for loop in channel_loops:
            points=[feature.matrix_world@v.co for v in feature.data.vertices]
            if points and all(min(v[axis] for v in points)<max(p[axis] for p in loop) and
                              max(v[axis] for v in points)>min(p[axis] for p in loop)
                              for axis in (0,1)):
                difference(feature,prism(loop,.24,'Detail cartridge clearance',z=-.12))
    result=combine(features,'Armor skin with captive details')
    result['plate_thickness_m']=.060
    result['decal_policy']='joined into parent mesh; no additional inventory'
    return result


def attach(ctx, skin, pid, mounts=(), instance=1):
    pieces=[skin]
    for a,b in mounts:
        pieces.append(strut(a,b,.10,.12,ctx.materials['gunmetal']))
    obj=register(ctx,clean(combine(pieces,pid+' removable armor')),pid,instance)
    obj['plate_thickness_m']=.060
    obj['decal_policy']='joined into parent mesh; no additional inventory'
    obj['mount_standoffs']=len(mounts)
    obj['handed']=next(r['handed'] for r in __import__('thigh').ROWS if r['part_id']==pid)
    if pid in {'LG-200','LG-400','LG-300','LG-210','LG-410'}:
        layer=obj.data.uv_layers.active
        if layer:
            for polygon in obj.data.polygons:
                material=obj.data.materials[polygon.material_index]
                if material and 'Decal' in material.name:
                    for index in polygon.loop_indices:
                        u,v=layer.data[index].uv
                        layer.data[index].uv=(1-u,v)
            obj.data.update()
    return obj



def folded_strip(rows, material, name='Integral folded corner', thickness=.060):
    """Closed ruled skin between paired 3D edge rails, with inward thickness.

    Keep each return on its owning inventory mesh. Slight overlaps with that
    plate are intentional visualization solids; neighboring plates have a
    35 mm seam backed by an integral dark lap, never an open daylight wedge.
    """
    verts=[]
    for a,b in rows:
        a,b=Vector(a),Vector(b)
        tangent=b-a
        inward=Vector((-tangent.y,tangent.x,0)).normalized()
        if inward.dot(Vector((a.x+b.x,a.y+b.y,0)))>0: inward=-inward
        verts.extend([a,b,b+inward*thickness,a+inward*thickness])
    count=len(rows)
    faces=[(3,2,1,0),tuple(range((count-1)*4,count*4))]
    faces += [(k*4+i,k*4+(i+1)%4,(k+1)*4+(i+1)%4,(k+1)*4+i)
              for k in range(count-1) for i in range(4)]
    return clean(mesh_object(name,verts,faces,material))


def corner_returns(ctx, zs, edge, surface, lateral, side, rear=False):
    """Front/rear fold with a recessed lap covering the 35 mm side seam."""
    direction=-1 if rear else 1
    fold=[]; lap=[]
    for z in zs:
        y=direction*surface(z)
        a=(side*(edge(z)-.045),y+direction*.048,z)
        b=(side*(lateral(z)+.040),y-direction*.105,z)
        fold.append((a,b))
        lap.append(((side*(lateral(z)-.020),y-direction*.085,z),
                    (side*(lateral(z)-.020),y-direction*.225,z)))
    return [folded_strip(fold,ctx.materials['armor']),
            folded_strip(lap,ctx.materials['recess'],'Integral shadow-seam lap',.025)]


def build(ctx):
    m=ctx.materials
    zs=[5.77,6.05,6.65,7.88,8.21]
    # Full mass through most of the thigh; only the final 0.9 m tapers to knee.
    side_surface=profile([(5.75,.600),(6.05,.600),(6.65,.810),(7.88,.840),(8.23,.755)])
    front_surface=profile([(5.75,.46),(6.05,.60),(6.65,.810),(7.88,.840),(8.23,.770)])
    rear_surface=profile([(5.75,.46),(6.05,.60),(6.65,.810),(7.88,.840),(8.23,.76)])
    front_edge=profile([(5.75,.47),(6.05,.59),(6.65,.765),(7.88,.795),(8.23,.685)])
    outline=[(-front_edge(z),z) for z in reversed([5.75,6.05,6.65,7.88,8.23])]
    outline += [(front_edge(z),z) for z in [5.75,6.05,6.65,7.88,8.23]]
    front=panel(ctx,outline,chamfer=.020,
        bolts=[(-.43,5.91),(.43,5.91),(-.63,7.89),(.63,7.89)],
        grooves=[[(-.36,5.87),(-.40,6.10),(.40,6.10),(.36,5.87)]],
        channels=[(-.339,7.25,.23),(.464,7.25,.24)],
        marks=[('caution',0,6.18,.36),('unit01',.24,7.12,.22)],
        inserts=[(-.69,7.25,.15,.85),(.69,7.25,.15,.85)])
    # Dark inward channel lips frame the exposed machinery without spanning it.
    lips=[]
    for u,width in [(-.339,.23),(.464,.24)]:
        for sign in (-1,1):
            path=[(z,u+sign*(width/2+flare)) for z,flare in [(7.25,0),(7.97,0),(8.20,.071)]]
            rows=[((x,front_surface(z)+.022,z),(x+sign*.014,front_surface(z)-.080,z)) for z,x in path]
            lips.append(folded_strip(rows,m['gunmetal'],'Channel inward return',.020))
    mapped(front,'front',front_surface)
    returns=[]
    for side in (-1,1):
        corner=corner_returns(ctx,sorted(zs+[7.80]),front_edge,front_surface,side_surface,side)
        if side<0:
            # Paint the actual forward shoulder facet; no patch bridges a channel.
            fold=corner[0]
            fold.data.materials.append(m['ochre'])
            for face in fold.data.polygons:
                if face.center.z>7.80 and face.normal.x<-.2 and face.normal.y>.2:
                    face.material_index=len(fold.data.materials)-1
        returns.extend(corner)
    front=combine([front,*returns,*lips],'Front plate with folded shoulders and channels')
    attach(ctx,front,'LG-200',[( (0,.46,6.62),(0,front_surface(6.62)+.01,6.62)),
                              ((0,.74,7.94),(0,front_surface(7.94)+.01,7.94))])
    for side,pid in [(-1,'LG-210'),(1,'LG-215')]:
        # Both long corner seams follow the front/back returns with 35 mm gaps.
        outline=[(-rear_surface(z)+.140,z) for z in reversed(zs)]
        outline += [(front_surface(z)-.140,z) for z in zs]
        skin=panel(ctx,outline,chamfer=.012,
                   bolts=[(-.43,6.64),(.35,6.60),(-.52,7.95),(.57,7.75)],
                   grooves=[[(-.39,6.53),(-.50,6.90),(-.50,7.53)]],
                   slots=[(.53,7.25,.15,.85)],
                   channels=[(.339 if side<0 else .124,7.25,.30)],
                   cuts=[((.03,6.10,.03),(.46,.42,.22))],
                   marks=[('red_marks',-.35,6.78,.20)])
        mapped(skin,'side',side_surface,side)
        if side<0:
            # Paint-sized angular region on the existing forward shoulder.
            accent=panel(ctx,[(.43,7.80),(.61,7.82),(.62,8.05),(.53,8.20),(.39,8.16)],
                         accent='ochre',chamfer=.012,channels=[(.339,7.25,.30)])
            mapped(accent,'side',profile([(z,side_surface(z)-.001) for z in zs]),side)
            skin=combine([skin,accent],'Outer plate and angular forward ochre shoulder')
        y_mount=.02 if side<0 else -.10
        attach(ctx,skin,pid,[((side*.50,.02,6.62),(side*(side_surface(6.62)+.01),.02,6.62)),
                             ((side*.74,y_mount,7.94),(side*(side_surface(7.94)+.01),y_mount,7.94))])
    rear_zs=[5.89,6.05,6.65,7.88,8.21]
    rear_edge=profile([(5.89,.46),(6.05,.53),(6.65,.765),(7.88,.795),(8.23,.675)])
    for side,pid in [(-1,'LG-220'),(1,'LG-225')]:
        outline=[(.22,5.89)]+[(rear_edge(z),z) for z in rear_zs if z!=6.05]+[(.22,8.21)]
        if side<0: outline=[(-x,z) for x,z in reversed(outline)]
        skin=panel(ctx,outline,chamfer=.020,bolts=[(side*.34,6.51),(side*.34,8.06),(side*.55,7.85)],
                   grooves=[[(side*.23,7.51),(side*.65,7.51)]],
                   slots=[(side*.42,7.39,.26,.065)],
                   marks=[('red_marks',side*.39,6.72,.18)])
        mapped(skin,'back',rear_surface)
        skin=combine([skin,*corner_returns(ctx,rear_zs,rear_edge,rear_surface,side_surface,side,True)],'Rear cover with folded corner')
        attach(ctx,skin,pid,[((side*.32,-.415,z),(side*.32,-rear_surface(z)-.01,z)) for z in (6.94,8.05)])
