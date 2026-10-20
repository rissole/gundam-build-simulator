"""Independent audit of the saved Blender scene, not the builder's in-memory list."""
import bpy
import json
import math
import collections
from pathlib import Path
from mathutils import Vector

HERE=Path(__file__).resolve().parents[1]
ROOT=HERE.parents[1]
scene=bpy.context.scene
parts=[o for o in scene.objects if o.get("is_assembly_part")]
expected={}
for line in (ROOT/"design/legs/foot-and-ankle/parts.md").read_text().splitlines():
    c=[x.strip() for x in line.strip("|").split("|")]
    if len(c)>=3 and c[0].startswith(("FA-","H-","W-")) and c[2].isdigit():
        expected[c[0]]=int(c[2])
actual=dict(collections.Counter(o["part_id"] for o in parts))
checks={
    "every_inventory_family_matches":actual==expected,
    "745_separate_objects":len(parts)==745,
    "745_independent_meshes":len({o.data.as_pointer() for o in parts})==745,
    "all_are_meshes":all(o.type=="MESH" for o in parts),
    "all_have_geometry":all(len(o.data.vertices)>=8 and len(o.data.polygons)>=6 for o in parts),
    "all_have_animation":all(o.animation_data and o.animation_data.action for o in parts),
    "unique_ids":len({o["instance_id"] for o in parts})==len(parts),
    "all_render_enabled_at_assembled":True,
}
positions={}
for f in (1,120,230,280,350,440,600,750,984):
    scene.frame_set(f)
    positions[f]={o["instance_id"]:tuple(o.location) for o in parts}
    if f==440:
        checks["assembled_positions_match_manifest"]=all(
            (o.location-Vector(o["assembled_position_m"])).length<1e-5 for o in parts)
        checks["all_render_enabled_at_assembled"]=all(not o.hide_render for o in parts)
    if f==984:
        checks["exploded_positions_match_manifest"]=all(
            (o.location-Vector(o["assembled_position_m"])-Vector(o["explosion_offset_m"])).length<1e-5
            for o in parts)
checks["every_part_moves"]=all((Vector(positions[1][k])-Vector(positions[440][k])).length>.005 for k in positions[1])
checks["deconstruction_returns_to_explosion"]=all(
    (Vector(positions[1][k])-Vector(positions[984][k])).length<1e-5 for k in positions[1])
checks["all_coordinates_finite"]=all(math.isfinite(v) for poses in positions.values() for p in poses.values() for v in p)
margin=1.
camera=scene.camera
camera_frames=sorted(set(range(1,985,6))|{440,984})
for f in camera_frames:
    scene.frame_set(f)
    inverse=camera.matrix_world.inverted()
    width=camera.data.ortho_scale
    height=width*scene.render.resolution_y/scene.render.resolution_x
    for o in parts:
        transform=inverse@o.matrix_world
        for corner in o.bound_box:
            p=transform@Vector(corner)
            x=p.x/width+.5
            y=p.y/height+.5
            margin=min(margin,x,1-x,y,1-y)
checks["sampled_camera_contains_every_part"]=margin>.02
scene.frame_set(440)
box={}
for family in ("FA-300","FA-301","FA-400","FA-403","FA-404"):
    pts=[o.matrix_world@Vector(v) for o in parts if o["part_id"]==family for v in o.bound_box]
    box[family]={"min":[min(p[i] for p in pts) for i in range(3)],
                 "max":[max(p[i] for p in pts) for i in range(3)]}
result={"checks":checks,"passed":all(checks.values()),"object_count":len(parts),
        "mesh_vertices":sum(len(o.data.vertices) for o in parts),
        "mesh_polygons":sum(len(o.data.polygons) for o in parts),
        "sampled_frames":list(positions),"camera_sample_count":len(camera_frames),
        "minimum_camera_border_fraction":margin,"critical_bounds_m":box,
        "scope":"Part completeness, mesh independence, saved animation transforms and key dimensions. Not a full collision or strength certification."}
(HERE/"output/scene-audit.json").write_text(json.dumps(result,indent=2)+"\n")
print(json.dumps(result,indent=2))
assert result["passed"],checks
