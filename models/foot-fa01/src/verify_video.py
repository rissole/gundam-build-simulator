"""Decode the final movie and render representative frames from the encoded file."""
import bpy
import json
import sys
from pathlib import Path

HERE=Path(__file__).resolve().parents[1]
args=sys.argv[sys.argv.index("--")+1:] if "--" in sys.argv else []
path=Path(args[0]).resolve() if args else HERE/"output/foot-fa01-build-and-explode.mp4"
expected_frames=int(args[1]) if len(args)>1 else 984
assert path.exists() and path.stat().st_size>100000
bpy.ops.wm.read_factory_settings(use_empty=True)
scene=bpy.context.scene
scene.render.resolution_x=1280;scene.render.resolution_y=720
scene.render.resolution_percentage=100
scene.render.fps=24
scene.render.use_sequencer=True
scene.view_settings.view_transform="Standard"
scene.view_settings.look="None"
editor=scene.sequence_editor_create()
strip=editor.strips.new_movie("Decode completed MP4",str(path),channel=1,frame_start=1)
clip=bpy.data.movieclips.load(str(path))
report={"path":path.name,"width":clip.size[0],"height":clip.size[1],
        "frames":clip.frame_duration,"fps":clip.fps,"bytes":path.stat().st_size}
assert report["width"]==1280 and report["height"]==720
assert report["frames"]==expected_frames and abs(report["fps"]-24)<.01
scene.render.image_settings.file_format="PNG"
samples=[1,260,440,750,984] if expected_frames==984 else [1,expected_frames//2,expected_frames]
for f in samples:
    scene.frame_set(f)
    scene.render.filepath=str(HERE/"previews"/f"video-{f:04d}.png")
    bpy.ops.render.render(write_still=True)
report["decoded_sample_frames"]=samples
report["duration_seconds"]=report["frames"]/report["fps"]
report["passed"]=True
report_path=HERE/("output/video-audit.json" if expected_frames==984 else "previews/preview-video-audit.json")
report_path.write_text(json.dumps(report,indent=2)+"\n")
print(json.dumps(report,indent=2))
