"""Encode the completed PNG sequence using Blender's bundled FFmpeg."""
import bpy
import sys
from pathlib import Path

HERE=Path(__file__).resolve().parents[1]
frames=HERE/"output/frames"
args=sys.argv[sys.argv.index("--")+1:] if "--" in sys.argv else []
end=int(args[0]) if args else 984
destination=Path(args[1]).resolve() if len(args)>1 else HERE/"output/foot-fa01-build-and-explode.mp4"
paths=[frames/f"{f:04d}.png" for f in range(1,end+1)]
assert all(p.exists() and p.stat().st_size>10000 for p in paths),"Incomplete render sequence"
bpy.ops.wm.read_factory_settings(use_empty=True)
s=bpy.context.scene
s.render.resolution_x=1280
s.render.resolution_y=720
s.render.resolution_percentage=100
s.render.fps=24
s.frame_start=1;s.frame_end=end
s.render.use_sequencer=True
ed=s.sequence_editor_create()
strip=ed.strips.new_image("FA-01 construction and explosion",str(paths[0]),channel=1,frame_start=1)
for p in paths[1:]:strip.elements.append(p.name)
strip.frame_final_duration=end
s.view_settings.view_transform="Standard"
s.view_settings.look="None"
s.render.image_settings.file_format="FFMPEG"
s.render.ffmpeg.format="MPEG4"
s.render.ffmpeg.codec="H264"
s.render.ffmpeg.constant_rate_factor="HIGH"
s.render.ffmpeg.ffmpeg_preset="GOOD"
s.render.ffmpeg.audio_codec="NONE"
s.render.filepath=str(destination)
bpy.ops.render.render(animation=True)
print("VIDEO_ENCODE_COMPLETE",s.render.filepath,flush=True)
