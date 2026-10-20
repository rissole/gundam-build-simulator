import bpy
import sys
from pathlib import Path

HERE=Path(__file__).resolve().parents[1]
args=sys.argv[sys.argv.index("--")+1:] if "--" in sys.argv else ["440","984","260"]
scene=bpy.context.scene
scene.render.resolution_percentage=75
scene.render.image_settings.file_format="PNG"
if hasattr(scene.eevee,"taa_render_samples"):scene.eevee.taa_render_samples=16
for item in args:
    f=int(item)
    scene.frame_set(f)
    scene.render.filepath=str(HERE/"previews"/f"frame-{f:04d}.png")
    bpy.ops.render.render(write_still=True)
    print("PREVIEW_SAVED",f,flush=True)
