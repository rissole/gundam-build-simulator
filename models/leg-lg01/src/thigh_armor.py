"""LG-01 removable thigh armor and local helpers. Distances in metres.

Integral standoffs, captive fasteners and decal sheets stay in their plate mesh.
The section function maps a flat kit plate onto a piecewise-linear limb surface.
"""
import math
import bpy
import bmesh
from mathutils import Vector
from kit import (plate, combine, finish, difference, chamfered_box, chamfered_rect,
                 recessed_hex_bolt, panel_line, normals)
from materials import decal
from thigh import register, box, strut


def clean(obj):
    """Remove collapsed kit bevel edges without moving the visible surface."""
    bm=bmesh.new(); bm.from_mesh(obj.data)
    bmesh.ops.dissolve_degenerate(bm,dist=1e-7,edges=list(bm.edges))
    bm.to_mesh(obj.data); bm.free(); obj.data.update()
    return finish(obj,wear=True)


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


def panel(ctx, outline, bolts=(), grooves=(), cuts=(), marks=(), slots=(), accent=None):
    m=ctx.materials
    center=(min(z for u,z in outline)+max(z for u,z in outline))/2
    local=[(u,z-center) for u,z in outline]
    chamfer=min(.075,(max(z for u,z in local)-min(z for u,z in local))*.20)
    skin=plate(local,.060,chamfer,material=m[accent or 'armor'])
    skin.location.y=center
    for cut_center,size in cuts:
        difference(skin,chamfered_box(size,cut_center,.025,m['recess']))
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
    for kind,u,z,width in marks:
        mark=decal(kind,width)
        mark.location=(u,z,.0607)
        features.append(mark)
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


def build(ctx):
    side_surface=profile([(5.75,.600),(6.10,.600),(6.62,.660),(7.87,.840),(8.23,.755)])
    front_surface=profile([(5.75,.46),(6.10,.54),(7.88,.840),(8.23,.770)])
    rear_surface=profile([(5.89,.53),(6.61,.60),(7.88,.840),(8.23,.76)])
    outline=[(-.47,5.75),(.47,5.75),(.63,6.05),(.77,7.88),(.64,8.23),(-.64,8.23),(-.77,7.88),(-.63,6.05)]
    front=panel(ctx,outline,
        bolts=[(-.43,5.91),(.43,5.91),(-.63,7.89),(.63,7.89)],
        grooves=[[(-.36,5.87),(-.40,6.10),(.40,6.10),(.36,5.87)]],
        cuts=[((-.339,8.00,.03),(.23,1.50,.22)),((.464,8.00,.03),(.24,1.50,.22))],
        marks=[('caution',0,6.18,.36),('unit01',.24,7.12,.22)],
        slots=[(-.64,7.29,.08,.62),(.64,7.29,.08,.62)])
    mapped(front,'front',front_surface)
    attach(ctx,front,'LG-200',[( (0,.46,6.62),(0,front_surface(6.62)+.01,6.62)),
                              ((0,.74,7.94),(0,front_surface(7.94)+.01,7.94))])
    # Broad side panels have a lowered shoulder channel above the outer lug.
    outline=[(-.40,5.77),(.33,5.77),(.65,6.35),(.72,7.88),(.52,8.21),(-.56,8.21),(-.73,7.91),(-.62,6.35)]
    for side,pid in [(-1,'LG-210'),(1,'LG-215')]:
        skin=panel(ctx,outline,bolts=[(-.43,6.64),(.35,6.60),(-.52,7.95),(.57,7.75)],
                   grooves=[[(-.39,6.53),(-.50,6.90),(-.50,7.53)]],
                   slots=[(.56,7.28,.10,.66)],
                   cuts=[((.339 if side<0 else .124,8.00,.03),(.30,1.50,.22)),
                         ((.03,6.10,.03),(.46,.42,.22))],
                   marks=[('red_marks',-.35,6.78,.20)])
        if side<0:
            strip=plate(chamfered_rect(.20,.40,.04),.025,.025,material=ctx.materials['ochre'])
            strip.location=(-.44,7.91,.061)
            skin=combine([skin,strip],'Outer plate and ochre shoulder')
        mapped(skin,'side',side_surface,side)
        y_mount=.02 if side<0 else -.10
        attach(ctx,skin,pid,[((side*.50,.02,6.62),(side*(side_surface(6.62)+.01),.02,6.62)),
                             ((side*.74,y_mount,7.94),(side*(side_surface(7.94)+.01),y_mount,7.94))])
    for side,pid in [(-1,'LG-220'),(1,'LG-225')]:
        outline=[(.22,5.89),(.45,5.89),(.63,6.60),(.73,7.88),(.59,8.22),(.22,8.22)]
        if side<0: outline=[(-x,z) for x,z in reversed(outline)]
        skin=panel(ctx,outline,bolts=[(side*.34,6.51),(side*.34,8.06),(side*.55,7.85)],
                   grooves=[[(side*.23,7.51),(side*.65,7.51)]],
                   slots=[(side*.42,7.39,.26,.065)],
                   marks=[('red_marks',side*.39,6.72,.18)])
        mapped(skin,'back',rear_surface)
        attach(ctx,skin,pid,[((side*.32,-.415,z),(side*.32,-rear_surface(z)-.01,z)) for z in (6.94,8.05)])
