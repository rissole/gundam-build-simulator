"""Render resumable PNG frames; encoding is separate so interrupted jobs retain work."""
import bpy
import sys
import json
import hashlib
from pathlib import Path

HERE=Path(__file__).resolve().parents[1]
args=sys.argv[sys.argv.index("--")+1:] if "--" in sys.argv else []
start=int(args[0]) if args else 1
end=int(args[1]) if len(args)>1 else bpy.context.scene.frame_end
scene=bpy.context.scene
scene.render.resolution_percentage=100
scene.render.image_settings.file_format="PNG"
scene.render.image_settings.color_mode="RGB"
folder=HERE/"output/frames"
folder.mkdir(exist_ok=True)
manifest_path=folder/"render-manifest.json"
manifest={"blend_sha256":hashlib.sha256(Path(bpy.data.filepath).read_bytes()).hexdigest(),
          "width":1280,"height":720,"fps":24,"frame_end":scene.frame_end}
if manifest_path.exists():
    assert json.loads(manifest_path.read_text())==manifest,"Frame folder belongs to a different scene revision"
else:
    manifest_path.write_text(json.dumps(manifest,indent=2)+"\n")
for frame in range(start,end+1):
    path=folder/f"{frame:04d}.png"
    if path.exists() and path.stat().st_size>10000:
        continue
    scene.frame_set(frame)
    scene.render.filepath=str(path)
    bpy.ops.render.render(write_still=True)
    print("FRAME_SAVED",frame,flush=True)
