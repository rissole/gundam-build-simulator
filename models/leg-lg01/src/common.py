"""LG-01 scene and part-module contract (Phase 2).

Units METRES. LEFT leg origin is ground below ankle; X robot-right (inner side
of left leg), Y forward, Z up. ANKLE=(0,0,1), KNEE=(0,0,5.10), HIP=(0,0,9.20).
Whole-robot placement is translation (-1.10,0,0); author at the local origin.

Each part module exposes build(ctx). ctx.materials maps armor/gunmetal/ochre/
red/chrome/bronze/rubber/amber/steel/recess to Principled materials. ctx.parts is
the registered object list. ctx.register(...) and module-level register(...)
are identical. Use kit constructors, transform to assembled pose, then register
the mesh with EXACT CSV part_id and name-column part_name. instance_no may be
an integer (auto namespaced by part_name), 'lug.03', or a full instance ID.
Duplicate instance IDs are errors. CSV names are never normalized in metadata.
ctx.root/src/output/work, ctx.collections and ctx.joint_centres are available.

register(obj, part_id, part_name, subassembly, category, finish, instance_no)
sets exact identity/finish properties, step=-1 (phase 5 placeholder), gives each
object independent mesh data, and moves it into its subassembly collection.
Only registered objects enter manifests. The 'presentation' collection contains
camera/lights/labels and is always excluded by export_glb(path, objects).
export_glb exports selected mesh nodes with extras, materials, UVs and COLOR_0.
No animation/explosion transform is applied in this phase.
"""
import csv
import json
import re
from dataclasses import dataclass, field
from pathlib import Path
import bpy
from mathutils import Vector
from materials import create_materials

ROOT=Path(__file__).resolve().parents[1]
SRC=ROOT/'src'
OUT=ROOT/'output'
WORK=ROOT/'work'
ANKLE=(0.,0.,1.00)
KNEE=(0.,0.,5.10)
HIP=(0.,0.,9.20)
JOINT_CENTRES={'ankle':ANKLE,'knee':KNEE,'hip':HIP}
GLOBAL_OFFSET=(-1.10,0.,0.)
_context=None


@dataclass
class BuildContext:
    root: Path=ROOT
    src: Path=SRC
    output: Path=OUT
    work: Path=WORK
    materials: dict=field(default_factory=dict)
    parts: list=field(default_factory=list)
    collections: dict=field(default_factory=dict)
    joint_centres: dict=field(default_factory=lambda:dict(JOINT_CENTRES))

    def register(self,obj,part_id,part_name,subassembly,category,finish,instance_no):
        return _register(self,obj,part_id,part_name,subassembly,category,finish,instance_no)


def collection(name):
    col=bpy.data.collections.get(name)
    if col is None:
        col=bpy.data.collections.new(name)
        bpy.context.scene.collection.children.link(col)
    return col


def init_scene():
    global _context
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.object.delete(use_global=False)
    for col in list(bpy.data.collections):
        bpy.data.collections.remove(col)
    for path in (OUT,WORK): path.mkdir(parents=True,exist_ok=True)
    scene=bpy.context.scene
    scene.unit_settings.system='METRIC'
    scene.unit_settings.scale_length=1
    scene.unit_settings.length_unit='METERS'
    scene['units']='metres'; scene['frame']='left leg: X right, Y forward, Z up'
    scene['global_offset_m']=GLOBAL_OFFSET
    for key,value in JOINT_CENTRES.items(): scene[key+'_centre_m']=value
    _context=BuildContext(materials=create_materials())
    _context.collections['presentation']=collection('presentation')
    return _context


def _register(ctx,obj,part_id,part_name,subassembly,category,finish,instance_no):
    if obj.type!='MESH' or not part_id or not part_name:
        raise ValueError('Registration requires a mesh and exact CSV identity')
    if obj in ctx.parts:
        raise ValueError(f'Object already registered: {obj.name}')
    if isinstance(instance_no,int):
        role=re.sub(r'[^a-z0-9]+','-',part_name.lower()).strip('-')
        instance_id=f'{part_id}.{role}.{instance_no:02d}'
    else:
        suffix=str(instance_no)
        instance_id=suffix if suffix.startswith(part_id+'.') else f'{part_id}.{suffix}'
    if any(o['instance_id']==instance_id for o in ctx.parts):
        raise ValueError(f'Duplicate instance_id: {instance_id}')
    if obj.data.users>1: obj.data=obj.data.copy()
    for key,value in dict(part_id=part_id,part_name=part_name,instance_id=instance_id,
                          subassembly=subassembly,category=category,finish=finish,step=-1).items():
        obj[key]=value
    obj.name=instance_id+' '+part_name[:64]
    obj.data.name=instance_id+' mesh'
    col=ctx.collections.setdefault(subassembly,collection(subassembly))
    for old in list(obj.users_collection): old.objects.unlink(obj)
    col.objects.link(obj)
    ctx.parts.append(obj)
    return obj


def register(obj,part_id,part_name,subassembly,category,finish,instance_no):
    if _context is None: raise RuntimeError('Call init_scene() before register()')
    return _context.register(obj,part_id,part_name,subassembly,category,finish,instance_no)


def bounds(obj):
    points=[obj.matrix_world@Vector(p) for p in obj.bound_box]
    return ([min(p[i] for p in points) for i in range(3)],
            [max(p[i] for p in points) for i in range(3)])


def write_manifest(ctx,path=None):
    base=Path(path) if path else ctx.output/'parts-manifest'
    bpy.context.view_layer.update()
    rows=[]
    for obj in ctx.parts:
        obj.data.calc_loop_triangles()
        lo,hi=bounds(obj)
        row={key:obj[key] for key in ('instance_id','part_id','part_name','subassembly','category','finish','step')}
        row.update(location=list(obj.matrix_world.translation),bbox_min=lo,bbox_max=hi,
                   triangles=len(obj.data.loop_triangles),object_name=obj.name)
        rows.append(row)
    result={'revision':'LG-01-3D-01','units':'metres','axes':'X right, Y forward, Z up',
            'joint_centres':JOINT_CENTRES,'global_offset':GLOBAL_OFFSET,
            'object_count':len(rows),'triangles':sum(r['triangles'] for r in rows),'parts':rows}
    base.with_suffix('.json').write_text(json.dumps(result,indent=2)+'\n')
    fields=['instance_id','part_id','part_name','subassembly','category','finish','step',
            'location','bbox_min','bbox_max','triangles','object_name']
    with base.with_suffix('.csv').open('w',newline='') as f:
        writer=csv.DictWriter(f,fieldnames=fields)
        writer.writeheader()
        writer.writerows({k:json.dumps(v) if isinstance(v,list) else v for k,v in r.items()} for r in rows)
    return result


def export_glb(path,objects):
    """Export only supplied meshes, omitting presentation descendants; extras on."""
    presentation=bpy.data.collections.get('presentation')
    excluded=set(presentation.all_objects) if presentation else set()
    selected=[o for o in objects if o.type=='MESH' and o not in excluded]
    if not selected: raise ValueError('GLB export needs at least one non-presentation mesh')
    old_selected=list(bpy.context.selected_objects)
    old_active=bpy.context.view_layer.objects.active
    try:
        bpy.ops.object.select_all(action='DESELECT')
        for obj in selected: obj.select_set(True)
        bpy.context.view_layer.objects.active=selected[0]
        Path(path).parent.mkdir(parents=True,exist_ok=True)
        bpy.ops.export_scene.gltf(filepath=str(path),export_format='GLB',use_selection=True,
                                  export_apply=True,export_extras=True,export_animations=False,
                                  export_cameras=False,export_lights=False,
                                  export_yup=True,export_texcoords=True,export_normals=True)
    finally:
        bpy.ops.object.select_all(action='DESELECT')
        for obj in old_selected: obj.select_set(True)
        bpy.context.view_layer.objects.active=old_active
    return Path(path)


def setup_studio(target=(0,0,4.6),camera_location=(12,17,11),scale=12,resolution=(1600,1000)):
    scene=bpy.context.scene
    engines={item.identifier for item in scene.render.bl_rna.properties['engine'].enum_items}
    scene.render.engine=next(e for e in ('BLENDER_EEVEE','BLENDER_EEVEE_NEXT') if e in engines)
    scene.render.resolution_x,scene.render.resolution_y=resolution
    scene.render.resolution_percentage=100
    scene.render.film_transparent=False
    scene.eevee.use_raytracing=True
    scene.eevee.fast_gi_quality=.75
    scene.eevee.fast_gi_ray_count=4
    scene.eevee.fast_gi_step_count=16
    scene.eevee.fast_gi_distance=3
    scene.view_settings.view_transform='AgX'
    scene.view_settings.look='AgX - Medium High Contrast'
    scene.view_settings.exposure=-.65
    scene.world=scene.world or bpy.data.worlds.new('White studio')
    scene.world.use_nodes=True
    bg=scene.world.node_tree.nodes.get('Background')
    bg.inputs['Color'].default_value=(1,1,1,1)
    bg.inputs['Strength'].default_value=.30
    env=collection('presentation')
    data=bpy.data.cameras.new('Studio camera')
    camera=bpy.data.objects.new('Studio camera',data); env.objects.link(camera)
    camera.location=camera_location
    camera.rotation_euler=(Vector(target)-camera.location).to_track_quat('-Z','Y').to_euler()
    data.type='ORTHO'; data.ortho_scale=scale; data.clip_end=200
    scene.camera=camera
    for name,delta,energy,size in [('Soft key',(-5,-3,8),1400,5),('Fill',(5,0,6),500,5),
                                    ('Edge',(0,5,7),950,4)]:
        light_data=bpy.data.lights.new(name,'AREA'); light_data.energy=energy; light_data.shape='DISK'; light_data.size=size
        light=bpy.data.objects.new(name,light_data); env.objects.link(light)
        light.location=Vector(target)+Vector(delta)
        light.rotation_euler=(Vector(target)-light.location).to_track_quat('-Z','Y').to_euler()
    return camera
