"""Render the assembled skeleton without changing the saved scene."""
import bpy
from pathlib import Path

HERE=Path(__file__).resolve().parents[1]
s=bpy.context.scene
s.frame_set(440)
for o in s.objects:
    if o.get("part_id") in {"FA-400","FA-401","FA-402","FA-403","FA-404","FA-405"} or o.get("hardware_use")=="Armor captive bolts":
        o.hide_render=True
    if o.type=="FONT" and o.data.body=="FA-01  /  FOOT ASSEMBLY":
        o.data.body="FA-01  /  SKELETON INSPECTION"
    if o.type=="FONT" and o.data.body.startswith("ASSEMBLED  /"):
        o.data.body="ARMOR REMOVED FOR MECHANISM REVIEW"
s.render.resolution_percentage=100
s.render.image_settings.file_format="PNG"
s.render.filepath=str(HERE/"output/foot-fa01-skeleton.png")
bpy.ops.render.render(write_still=True)
