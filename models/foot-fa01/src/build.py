"""Build every FA-01 inventory object and its assembly/explosion animation.

Run: Blender --background --factory-startup --python models/foot-fa01/src/build.py
"""
import sys
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parent))
import bpy
import math
import json
import csv
import collections
import zipfile
import io
from mathutils import Vector
import geometry as g
import frame_parts
import actuator_parts
import finish_parts

HERE=Path(__file__).resolve().parents[1]
OUT=HERE/"output"
OUT.mkdir(exist_ok=True)
SCENE=bpy.context.scene
ASSEMBLED=440
END=984


def expected_inventory():
    expected={}
    for line in (g.SPEC/"parts.md").read_text().splitlines():
        cells=[c.strip() for c in line.strip("|").split("|")]
        if len(cells)>=3 and cells[0].startswith(("FA-","H-","W-")) and cells[2].isdigit():
            expected[cells[0]]=int(cells[2])
    return expected


def animate():
    # FA-200 is prepared on the bench before the adapter enters it.
    for o in g.PARTS:
        if o["part_id"]=="FA-200":o["assembly_phase"]=2.85
    for o in g.PARTS:
        assembled=Vector(o["assembled_position_m"])
        offset=Vector(o["explosion_offset_m"])
        phase=o["assembly_phase"]
        begin=round(30+phase*29)
        finish=begin+18
        bench=Vector((0,0,0))
        transfer=None
        core=o["part_id"] in {"FA-200","FA-201","FA-203","FA-204","FA-205","FA-207","FA-209"}
        core |= o["part_id"]=="FA-230" and "Roll_" in o.name
        core |= "FA-209" in o.get("owner_instance","")
        if core:
            bench=Vector((0,0,.55))
            transfer=(147,166)
        if "actuator" in o:
            bench=Vector(actuator_parts.ACTUATORS[o["actuator"]]["explosion"])/1600
            transfer=(265,290)
        keyframes=[(1,assembled+offset),(begin,assembled+offset),(finish,assembled+bench)]
        if transfer:
            # Late-fitting internal screws settle before the subassembly moves.
            transfer=(max(transfer[0],finish+2),max(transfer[1],finish+20))
            keyframes += [(transfer[0],assembled+bench),(transfer[1],assembled)]
        keyframes += [(420,assembled),(ASSEMBLED,assembled)]
        keyframes=sorted(dict(keyframes).items())
        full=keyframes+[(936-f,p) for f,p in reversed(keyframes)]
        full += [(END,assembled+offset)]
        for f,p in sorted(full):
            o.location=p
            o.keyframe_insert(data_path="location",frame=f,group="Assembly and exploded view")
        action=o.animation_data.action
        action.name=o["instance_id"]+"_Assembly"
        # Blender 4.5 layered actions expose curves through their channel bags.
        for layer in action.layers:
            for strip in layer.strips:
                for bag in strip.channelbags:
                    for fc in bag.fcurves:
                        for k in fc.keyframe_points:
                            k.interpolation="BEZIER"
                            k.handle_left_type="AUTO_CLAMPED"
                            k.handle_right_type="AUTO_CLAMPED"


def setup_scene():
    SCENE.unit_settings.system="METRIC"
    SCENE.unit_settings.length_unit="METERS"
    SCENE.render.engine="BLENDER_EEVEE_NEXT"
    SCENE.render.resolution_x=1280
    SCENE.render.resolution_y=720
    SCENE.render.resolution_percentage=100
    SCENE.render.fps=24
    SCENE.frame_start=1;SCENE.frame_end=END
    SCENE.render.image_settings.file_format="PNG"
    SCENE.render.film_transparent=False
    if hasattr(SCENE.eevee,"taa_render_samples"):SCENE.eevee.taa_render_samples=48
    SCENE.world.use_nodes=True
    SCENE.world.node_tree.nodes["Background"].inputs[0].default_value=(.78,.83,.87,1)
    SCENE.world.node_tree.nodes["Background"].inputs[1].default_value=.35
    SCENE.view_settings.view_transform="AgX"
    SCENE.view_settings.look="AgX - Medium High Contrast"

    env=bpy.data.collections.new("PRESENTATION — excluded from parts export")
    SCENE.collection.children.link(env)
    camera_data=bpy.data.cameras.new("Technical camera")
    camera=bpy.data.objects.new("Technical camera",camera_data)
    env.objects.link(camera)
    SCENE.camera=camera
    camera_data.type="ORTHO"
    camera_data.clip_end=100
    direction=Vector((-6,7,4.6)).normalized()
    camera.rotation_euler=(-direction).to_track_quat("-Z","Y").to_euler()
    rotation=camera.rotation_euler.to_matrix()
    right=rotation@Vector((1,0,0)); up=rotation@Vector((0,1,0))

    def bounds_at(f):
        SCENE.frame_set(f)
        pts=[o.matrix_world@Vector(v) for o in g.PARTS for v in o.bound_box]
        lo=Vector(tuple(min(p[i] for p in pts) for i in range(3)))
        hi=Vector(tuple(max(p[i] for p in pts) for i in range(3)))
        center=(lo+hi)/2
        horizontal=[(p-center).dot(right) for p in pts]
        vertical=[(p-center).dot(up) for p in pts]
        center += right*(max(horizontal)+min(horizontal))/2
        center += up*(max(vertical)+min(vertical))/2
        scale=max(max(horizontal)-min(horizontal),(max(vertical)-min(vertical))*16/9)*1.22
        return center,scale
    # Track actual intermediate bounds rather than zooming toward the destination
    # while late-installing armor and sole parts still occupy the exploded layout.
    for f in sorted(set([1,ASSEMBLED,END]+list(range(12,END+1,12)))):
        center,scale=bounds_at(f)
        camera.location=center+direction*16
        camera.keyframe_insert("location",frame=f)
        camera_data.ortho_scale=scale
        camera_data.keyframe_insert("ortho_scale",frame=f)
    for name,loc,energy,size in [
        ("Large soft key",(-4,2,7),1400,5),
        ("Front fill",(4,6,4),900,4),
        ("Rear rim",(0,-5,6),1800,4),
    ]:
        ld=bpy.data.lights.new(name,"AREA");ld.energy=energy;ld.shape="DISK";ld.size=size
        light=bpy.data.objects.new(name,ld);env.objects.link(light)
        light.location=loc;light.rotation_euler=(Vector((0,.6,.6))-Vector(loc)).to_track_quat("-Z","Y").to_euler()
    # A faint ground shadow gives depth without hiding the downward sole explosion.
    groundmesh=bpy.data.meshes.new("Studio ground")
    groundmesh.from_pydata([(-100,-100,-2.2),(100,-100,-2.2),(100,100,-2.2),(-100,100,-2.2)],[],[(0,1,2,3)])
    ground=bpy.data.objects.new("Studio ground",groundmesh);env.objects.link(ground)
    mat=g.material("Studio",(.83,.87,.89),0,.8)
    groundmesh.materials.append(mat)
    ink=g.material("Diagram ink",(.018,.035,.05),0,.5)
    shader=ink.node_tree.nodes.get("Principled BSDF")
    shader.inputs["Emission Color"].default_value=(.018,.035,.05,1)
    shader.inputs["Emission Strength"].default_value=.8

    def label(name,body,x,y,size,interval=None):
        data=bpy.data.curves.new(name,"FONT")
        data.body=body;data.size=1;data.align_x="LEFT"
        obj=bpy.data.objects.new(name,data);env.objects.link(obj)
        obj.parent=camera;obj.location=(0,0,-8)
        data.materials.append(ink)
        for index,factor in [(0,x),(1,y)]:
            fc=obj.driver_add("location",index)
            v=fc.driver.variables.new();v.name="s";v.targets[0].id_type="CAMERA"
            v.targets[0].id=camera_data;v.targets[0].data_path="ortho_scale"
            fc.driver.expression=f"s*{factor}"
        for index in range(3):
            fc=obj.driver_add("scale",index)
            v=fc.driver.variables.new();v.name="s";v.targets[0].id_type="CAMERA"
            v.targets[0].id=camera_data;v.targets[0].data_path="ortho_scale"
            fc.driver.expression=f"s*{size}"
        if interval:
            a,b=interval
            for f,hide in [(1,True),(max(1,a-1),True),(a,False),(b,False),(b+1,True)]:
                obj.hide_render=hide;obj.keyframe_insert("hide_render",frame=f)
                obj.hide_viewport=hide;obj.keyframe_insert("hide_viewport",frame=f)
        return obj
    label("Film title","FA-01  /  FOOT ASSEMBLY",-.46,.245,.022)
    label("Film subtitle","745 SEPARATE OBJECTS  |  METRIC MODEL  |  3 ELECTRIC DRIVES",-.46,.222,.010)
    captions=[
        (1,39,"PARTS LAID OUT"),
        (40,106,"01  REAR FRAME / NUT PLATES / CRADLE"),
        (107,174,"02  NESTED ANKLE / FOUR SHORT PINS"),
        (175,231,"03  FOREFOOT FRAME / CONTINUOUS AXLE"),
        (232,289,"04  THREE ELECTRIC ACTUATORS / INTERNAL ASSEMBLY"),
        (290,318,"05  ACTUATOR MOUNTS / RETAINING PINS"),
        (319,338,"06  SOLE CARRIERS / SIX GRIP PADS"),
        (339,361,"07  CONTROLLER / HARNESSES / CLIPS"),
        (362,377,"08  KEYED SHIN INTERFACE"),
        (378,419,"09  FIVE REMOVABLE ARMOR SHELLS"),
        (420,504,"ASSEMBLED  /  3.0 m LONG  x  1.3 m WIDE"),
        (505,935,"DECONSTRUCTION  /  REVERSE ASSEMBLY ORDER"),
        (936,END,"EXPLODED VIEW  /  EVERY PART REMAINS SEPARATE"),
    ]
    for i,(a,b,text) in enumerate(captions):
        label(f"Stage {i:02d}",text,-.46,-.25,.014,(a,b))
        SCENE.timeline_markers.new(text,frame=a)
    SCENE.frame_set(ASSEMBLED)
    for area in bpy.context.screen.areas if bpy.context.screen else []:
        if area.type=="VIEW_3D":
            area.spaces.active.region_3d.view_perspective="CAMERA"
            area.spaces.active.clip_end=200
    return camera


def inventory_audit():
    expected=expected_inventory()
    actual=dict(g.COUNTS)
    missing={k:(q,actual.get(k,0)) for k,q in expected.items() if actual.get(k,0)!=q}
    extras={k:q for k,q in actual.items() if k not in expected}
    use_errors={k:(int(r["quantity_per_foot"]),g.USES[k]) for k,r in g.SCHEDULE.items()
                if int(r["quantity_per_foot"])!=g.USES[k]}
    assert not missing and not extras and not use_errors,(missing,extras,use_errors)
    assert len(g.PARTS)==745
    assert len({o.data.as_pointer() for o in g.PARTS})==745
    assert all(len(o.data.vertices)>0 and len(o.data.polygons)>0 for o in g.PARTS)
    return {"expected":expected,"actual":actual,"hardware_uses":dict(g.USES),
            "objects":len(g.PARTS),"independent_mesh_datablocks":745}


def manifest(audit):
    result={"revision":"FA-01-3D-01","units":"meters","axes":"X right, Y forward, Z up",
            "frames":{"start":1,"assembled":ASSEMBLED,"exploded":END,"fps":24},
            "inventory_audit":audit,"parts":[]}
    SCENE.frame_set(ASSEMBLED)
    for o in g.PARTS:
        item={k:o[k] for k in o.keys()}
        for k in ("assembled_position_m","explosion_offset_m"):
            item[k]=list(item[k])
        item.update({"object_name":o.name,"mesh_name":o.data.name,
                     "vertices":len(o.data.vertices),"polygons":len(o.data.polygons)})
        result["parts"].append(item)
    (OUT/"parts-manifest.json").write_text(json.dumps(result,indent=2)+"\n")
    with (OUT/"parts-manifest.csv").open("w",newline="") as f:
        w=csv.writer(f)
        w.writerow(["instance_id","part_id","label","group","phase","x_m","y_m","z_m","obj_file"])
        for o in g.PARTS:
            w.writerow([o["instance_id"],o["part_id"],o["label"],o["assembly_group"],o["assembly_phase"],
                        *o["assembled_position_m"],o["instance_id"]+".obj"])


def export_individual_objs():
    # Each OBJ is a separate centered component. Assembly translations are in the manifest.
    SCENE.frame_set(ASSEMBLED)
    deps=bpy.context.evaluated_depsgraph_get()
    mtl=[]
    for name,mat in g.MATERIALS.items():
        c=mat.diffuse_color
        mtl += [f"newmtl {name}",f"Kd {c[0]} {c[1]} {c[2]}","Ks 0.25 0.25 0.25","Ns 80",""]
    with zipfile.ZipFile(OUT/"individual-parts-745.zip","w",zipfile.ZIP_DEFLATED,compresslevel=5) as archive:
        archive.writestr("materials.mtl","\n".join(mtl))
        archive.writestr("parts-manifest.csv",(OUT/"parts-manifest.csv").read_text())
        archive.writestr("README.txt","745 separate OBJ files. Units: metres. Z up, Y forward. Each mesh uses its own centered pivot. Restore its assembly position using parts-manifest.csv. OBJ has no animation; use the BLEND or animated GLB for the complete sequence.\n")
        for index,o in enumerate(g.PARTS):
            evaluated=o.evaluated_get(deps)
            mesh=evaluated.to_mesh()
            lines=[f"# {o.name} | units metres | centered part","mtllib materials.mtl",f"o {o['instance_id']}"]
            lines += [f"v {v.co.x:.7f} {v.co.y:.7f} {v.co.z:.7f}" for v in mesh.vertices]
            last=None
            for p in mesh.polygons:
                mat=mesh.materials[p.material_index].name if len(mesh.materials) else "Steel"
                if mat!=last:lines.append(f"usemtl {mat}");last=mat
                lines.append("f "+" ".join(str(i+1) for i in p.vertices))
            archive.writestr(o["instance_id"]+".obj","\n".join(lines)+"\n")
            evaluated.to_mesh_clear()
    print("INDIVIDUAL_OBJS_SAVED",flush=True)


def export_glb():
    bpy.ops.object.select_all(action="DESELECT")
    for o in g.PARTS:o.select_set(True)
    bpy.context.view_layer.objects.active=g.PARTS[0]
    SCENE.frame_set(ASSEMBLED)
    bpy.ops.export_scene.gltf(filepath=str(OUT/"foot-fa01-assembled.glb"),export_format="GLB",
        use_selection=True,export_apply=True,export_extras=True,export_animations=False,
        export_current_frame=True,export_cameras=False,export_lights=False)
    bpy.ops.export_scene.gltf(filepath=str(OUT/"foot-fa01-animated.glb"),export_format="GLB",
        use_selection=True,export_apply=True,export_extras=True,export_animations=True,
        export_animation_mode="ACTIVE_ACTIONS",export_nla_strips_merged_animation_name="Build then explode",
        export_force_sampling=False,export_frame_range=True,export_optimize_animation_size=True,
        export_cameras=False,export_lights=False)
    bpy.ops.object.select_all(action="DESELECT")


def main():
    g.init()
    for name,fn in [
        ("Frames",frame_parts.build_frames),("Ankle",frame_parts.build_ankle),
        ("Toe hinge",frame_parts.build_toe_joint),("Stops",frame_parts.build_stops),
        ("Actuators",actuator_parts.build),("Soles",finish_parts.build_soles),
        ("Electrical",finish_parts.build_electrical),("Armor",finish_parts.build_armor),
    ]:
        print("BUILDING",name,flush=True)
        fn()
        print("OBJECTS",len(g.PARTS),flush=True)
    audit=inventory_audit()
    animate()
    setup_scene()
    manifest(audit)
    SCENE["revision"]="FA-01-3D-01"
    SCENE["part_count"]=745
    SCENE["readme"]="All 745 inventory objects are separate meshes. Frame 440 assembled; frame 984 exploded. Rendered construction is schematic, not a collision-certified installation simulation."
    bpy.ops.wm.save_as_mainfile(filepath=str(OUT/"foot-fa01.blend"))
    export_individual_objs()
    export_glb()
    SCENE.frame_set(ASSEMBLED)
    bpy.ops.wm.save_as_mainfile(filepath=str(OUT/"foot-fa01.blend"))
    print("BUILD_COMPLETE",flush=True)


if __name__=="__main__":main()
