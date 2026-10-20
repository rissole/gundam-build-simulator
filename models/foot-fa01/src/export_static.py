"""Re-export the assembled pose without modifying or rebuilding the source scene."""
import bpy
from pathlib import Path

OUT=Path(__file__).resolve().parents[1]/"output"
scene=bpy.context.scene
scene.frame_set(440)
bpy.ops.object.select_all(action="DESELECT")
parts=[o for o in scene.objects if o.get("is_assembly_part")]
assert len(parts)==745
for o in parts:o.select_set(True)
bpy.context.view_layer.objects.active=parts[0]
bpy.ops.export_scene.gltf(filepath=str(OUT/"foot-fa01-assembled.glb"),export_format="GLB",
    use_selection=True,export_apply=True,export_extras=True,export_animations=False,
    export_current_frame=True,export_cameras=False,export_lights=False)
