"""Package the verified model, animation and reproducible source, excluding frames/cache."""
import hashlib
import json
import zipfile
from pathlib import Path

HERE=Path(__file__).resolve().parents[1]
ROOT=HERE.parents[1]
OUT=HERE/"output"
scene=json.loads((OUT/"scene-audit.json").read_text())
exports=json.loads((OUT/"export-audit.json").read_text())
video=json.loads((OUT/"video-audit.json").read_text())
assert scene["passed"] and exports["passed"] and video["passed"]
render=json.loads((OUT/"frames/render-manifest.json").read_text())
assert render["blend_sha256"]==hashlib.sha256((OUT/"foot-fa01.blend").read_bytes()).hexdigest()
for name in ("foot-fa01-assembled.glb","foot-fa01-animated.glb"):
    assert exports[name]["sha256"]==hashlib.sha256((OUT/name).read_bytes()).hexdigest()

deliverables=[
    "foot-fa01.blend","foot-fa01-animated.glb","foot-fa01-assembled.glb",
    "individual-parts-745.zip","foot-fa01-build-and-explode.mp4",
    "foot-fa01-assembled.png","foot-fa01-exploded.png","foot-fa01-skeleton.png",
    "parts-manifest.csv","parts-manifest.json","scene-audit.json","export-audit.json","video-audit.json",
]
checksums={name:hashlib.sha256((OUT/name).read_bytes()).hexdigest() for name in deliverables}
audit={"passed":True,"scene_parts":745,"independent_meshes":745,"animated_glb_parts":745,
       "individual_obj_files":745,"video_frames":984,"video_fps":24,"video_seconds":41,
       "rendered_from_current_blend":True,"sha256":checksums}
(OUT/"delivery-audit.json").write_text(json.dumps(audit,indent=2)+"\n")
files=[ROOT/"ROBOT_DESIGN.md",HERE/"README.md",HERE/"MODELING_NOTES.md",HERE/"open-in-blender.command"]
files += sorted((HERE/"src").glob("*.py"))
files += [OUT/name for name in deliverables]+[OUT/"delivery-audit.json",OUT/"frames/render-manifest.json"]
files += [p for p in sorted((ROOT/"design").rglob("*"))
          if p.is_file() and "__pycache__" not in p.parts]
package=OUT/"foot-fa01-complete-package.zip"
with zipfile.ZipFile(package,"w",zipfile.ZIP_DEFLATED,compresslevel=6) as archive:
    for path in files:
        archive.write(path,path.relative_to(ROOT))
with zipfile.ZipFile(package) as archive:
    assert archive.testzip() is None
    assert len(archive.namelist())==len(files)
print("PACKAGE_VERIFIED",package,"bytes",package.stat().st_size,"files",len(files))
