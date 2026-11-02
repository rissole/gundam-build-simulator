"""Export the current saved scene; never rebuild or save over the source blend.

blender --background --factory-startup --python-exit-code 1 --python models/leg-lg01/src/export_viewer.py
"""
import hashlib
from pathlib import Path
import sys
sys.path.insert(0, str(Path(__file__).resolve().parent))

import bpy
from common import ROOT, export_glb
VIEWER = ROOT.parents[1] / 'design/legs/viewer'  # viewer app lives with the leg design docs
from verify_export import read_glb, write_glb, triangle_count, MAX_BYTES


def main():
    source = ROOT / 'output/leg-lg01.blend'
    target = VIEWER / 'leg-lg01.glb'
    source_hash = hashlib.sha256(source.read_bytes()).hexdigest()
    bpy.ops.wm.open_mainfile(filepath=str(source))
    scene = bpy.context.scene
    scene.frame_set(1)
    presentation = bpy.data.collections.get('presentation')
    excluded = set(presentation.all_objects) if presentation else set()
    parts = [o for o in scene.objects if o.type == 'MESH' and o.get('instance_id') and o not in excluded]
    if not parts or len({o['instance_id'] for o in parts}) != len(parts):
        raise ValueError('Scene must contain parts with unique instance IDs')
    for obj in parts:
        for key in ('part_id', 'part_name', 'instance_id', 'subassembly', 'category'):
            if not obj.get(key):
                raise ValueError(f'{obj.name}: missing {key}')
    depsgraph = bpy.context.evaluated_depsgraph_get()
    # Freeze evaluated world matrices and modifiers before changing the hierarchy.
    snapshots = []
    for obj in parts:
        evaluated = obj.evaluated_get(depsgraph)
        mesh = bpy.data.meshes.new_from_object(evaluated, preserve_all_data_layers=True, depsgraph=depsgraph)
        snapshots.append((obj, mesh, evaluated.matrix_world.copy()))
    collection = bpy.data.collections.new('viewer-export')
    scene.collection.children.link(collection)
    exports = []
    triangles = 0
    used_materials = set()
    for index, (original, mesh, matrix) in enumerate(snapshots):
        iid = original['instance_id']
        original.name = f'__source_{index}'
        obj = bpy.data.objects.new(iid, mesh)
        collection.objects.link(obj)
        obj.matrix_world = matrix
        for key in ('part_id', 'part_name', 'instance_id', 'subassembly', 'category', 'finish', 'step'):
            if key in original:
                obj[key] = original[key]
        mesh.calc_loop_triangles()
        triangles += len(mesh.loop_triangles)
        for polygon in mesh.polygons:
            if polygon.material_index < len(mesh.materials) and mesh.materials[polygon.material_index]:
                used_materials.add(mesh.materials[polygon.material_index].name)
        exports.append(obj)
    bpy.context.view_layer.update()
    # common.export_glb uses selection/extras/Y-up and no animation. Blender's
    # Draco flag defaults OFF; remove saved UI export options for reproducibility.
    if 'glTF2ExportSettings' in scene:
        del scene['glTF2ExportSettings']
    export_glb(target, exports)
    document, chunks = read_glb(target)
    if 'KHR_draco_mesh_compression' in document.get('extensionsUsed', []):
        raise ValueError('Unexpected Draco compression in export')
    document.setdefault('asset', {}).setdefault('extras', {})['lg01_export'] = {
        'source': 'output/leg-lg01.blend', 'source_sha256': source_hash,
        'scene_part_count': len(parts), 'evaluated_triangles': triangles,
        'material_count': len(used_materials), 'materials': sorted(used_materials),
        'coordinates': 'glTF Y-up: (Blender X, Blender Z, -Blender Y)',
        'pose': 'assembled', 'draco': False,
    }
    write_glb(target, document, chunks)
    size = target.stat().st_size
    print(f'VIEWER EXPORT: {len(document.get("nodes", []))} nodes; '
          f'{triangle_count(document):,} triangles; {len(document.get("materials", []))} materials; '
          f'{size / 1e6:.3f} MB; Draco OFF', flush=True)
    if size >= MAX_BYTES:
        raise ValueError('Export exceeds 150 MB: simplify hidden internals before delivery')


if __name__ == '__main__':
    main()
