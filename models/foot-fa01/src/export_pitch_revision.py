"""Export only the pitch prototype's repaired physical instances with Blender.
The separate merge tool preserves unrelated game meshes byte-for-byte.
"""
import sys,json
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parent))
import bpy
import build
import geometry as g
from source_connections import pitch_instance_ids
import frame_parts, actuator_parts, finish_parts

g.init()
for fn in [frame_parts.build_frames,frame_parts.build_ankle,frame_parts.build_toe_joint,frame_parts.build_stops,actuator_parts.build,finish_parts.build_soles,finish_parts.build_electrical,finish_parts.build_armor]: fn()
build.inventory_audit()
source_ids=pitch_instance_ids()
selected=[o for o in g.PARTS if o['instance_id'] in source_ids]+[g.find_part('FA-103'),g.find_part('FA-200')]
assert len(selected)==111
bpy.ops.object.select_all(action='DESELECT')
for o in selected:o.select_set(True)
bpy.context.view_layer.objects.active=selected[0]
bpy.ops.export_scene.gltf(filepath=str(g.OUT/'pitch-revision.glb'),export_format='GLB',use_selection=True,export_apply=True,export_extras=True,export_animations=False,export_cameras=False,export_lights=False)
manifest_path=g.OUT/'parts-manifest.json'
manifest=json.loads(manifest_path.read_text())
updates={}
for o in selected:
    item={k:o[k] for k in o.keys()}
    for k in ('assembled_position_m','explosion_offset_m','insertion_axis'):
        if k in item:item[k]=list(item[k])
    item.update(object_name=o.name,mesh_name=o.data.name,vertices=len(o.data.vertices),polygons=len(o.data.polygons))
    updates[o['instance_id']]=item
for i,part in enumerate(manifest['parts']):
    if part['instance_id'] in updates:manifest['parts'][i]=updates[part['instance_id']]
manifest_path.write_text(json.dumps(manifest,indent=2)+'\n')
print('PITCH_REVISION_EXPORTED',len(selected),flush=True)
