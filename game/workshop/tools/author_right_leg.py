"""Author the independent mirrored leg/foot without changing canonical FA-01.

Mesh/pose reflection is explicit source metadata, resolved once by the runtime.
Compatible hardware retains its family; handed structural/service pieces get
distinct types. No occupied assembly moves when the selected task changes.
"""
from copy import deepcopy
import json

PREFIX = "R-"


def extend(assets, trial, kinds, left_leg, pelvis, canonical_parts, source_records):
    foot_scenario=json.loads((assets/"pitch-workshop.json").read_text())
    base_document=json.loads((assets/"assembly-definitions.json").read_text())
    pitch_document=json.loads((assets/"pitch-actuator-definitions.json").read_text())
    base=base_document["assemblies"];base.update(pitch_document["assemblies"])
    all_parts={**base_document["parts"],**pitch_document["parts"],**canonical_parts,**kinds}
    base["foot"]["carry_class"]="equipment";base["foot"]["work_locations"]=["support"]
    mirrors=set()
    assembly_ids={"foot":"right_foot","pad_1":"right_pad_1","pad_2":"right_pad_2","pitch":"right_pitch","left_leg":"right_leg"}
    definitions={"foot":"right_foot","heel_pad":"right_heel_pad","pitch_actuator":"right_pitch_actuator","left_leg":"right_leg"}
    handed={"lg-shin":"lg-shin-right","lg-thigh-spar":"lg-thigh-spar-right","lg-main-input":"lg-main-input-right"}

    def mirrored(uid):
        if not uid:return uid
        mirrors.add(PREFIX+uid)
        return PREFIX+uid

    def vector(value):
        return [-value[0],*value[1:]]

    def collision(records):
        result=deepcopy(records)
        for shape in result:
            if "position" in shape:shape["position"]=vector(shape["position"])
            if "rotation_degrees" in shape:shape["rotation_degrees"]=[shape["rotation_degrees"][0],-shape["rotation_degrees"][1],-shape["rotation_degrees"][2]]
        return result

    def reflect_recipe(recipe, title):
        result=deepcopy(recipe);result["title"]=title
        for field in ["frame_source","enclosure_source"]:
            if field in result:result[field]=mirrored(result[field])
        if "context_sources" in result:result["context_sources"]=[mirrored(uid) for uid in result["context_sources"]]
        for slot in result["slots"].values():
            if "pose_source" in slot:slot["pose_source"]=mirrored(slot["pose_source"])
            if "assembly" in slot:slot["assembly"]=definitions.get(slot["assembly"],slot["assembly"])
            if "accepts" in slot:
                original=slot["accepts"]
                slot["accepts"]=handed.get(original,original)
                profile=slot.get("collision_shapes",all_parts.get(original,{}).get("collision_shapes",[]))
                if profile:slot["collision_shapes"]=collision(profile)
            for key in ["target","target_position","target_offset","snap_position"]:
                if key in slot:slot[key]=vector(slot[key])
            if "snap_rotation_degrees" in slot:slot["snap_rotation_degrees"]=[slot["snap_rotation_degrees"][0],-slot["snap_rotation_degrees"][1],-slot["snap_rotation_degrees"][2]]
        for page in result["manual"]:
            for field in ["title","body","goal"]:
                if field in page:page[field]=page[field].replace("Left","Right").replace("left","right")
            if "note" in page:page["note"]["text"]=page["note"]["text"].replace("Left","Right").replace("left","right")
            for objective in page.get("objectives",[]):
                if "task" in objective:objective["task"]="right_"+objective["task"]
                if objective.get("machine")=="joint_restraints":
                    objective["command"]=objective["command"].replace(":left_leg:",":right_leg:")
            for field in ["context_sources"]:
                if field in page:page[field]=[mirrored(uid) for uid in page[field]]
            for diagram in page.get("diagram_views",[]):
                for field in ["sources","context"]:
                    if field in diagram:diagram[field]=[mirrored(uid) for uid in diagram[field]]
                if "direction" in diagram:diagram["direction"]=vector(diagram["direction"])
                if "offsets" in diagram:diagram["offsets"]={mirrored(uid):vector(at) for uid,at in diagram["offsets"].items()}
        return result

    for original,key in handed.items():
        kinds[key]=deepcopy(kinds.get(original,canonical_parts[original]))
        kinds[key]["variant"]="right-hand"
        kinds[key]["title"] += " · right hand"
        kinds[key]["short_title"] += " · right hand"
        if "collision_shapes" in kinds[key]:kinds[key]["collision_shapes"]=collision(kinds[key]["collision_shapes"])

    right_leg=reflect_recipe(left_leg,"Right leg · structural prototype")
    right_foot=reflect_recipe(base["foot"],"Right foot · prepared")
    right_pad=reflect_recipe(base["heel_pad"],"Right heel pad · prepared")
    right_pitch=reflect_recipe(base["pitch_actuator"],"Right pitch actuator · prepared")
    right_leg["slots"]["foot"]["label"]="Prepared right foot"
    for page in right_leg["manual"]:
        if page["title"]=="Insert the knee axle":page["note"]["text"]="Insert from the right leg's outward (+X) axle aisle. The cap and its screws fit on the inner side."
    # The left and right definitions share their manufactured hardware types,
    # but their placement geometry is reflected through X.
    original_stock=deepcopy(trial["parts"])
    for item in original_stock+foot_scenario["parts"]:
        new=deepcopy(item);new["instance_id"]=PREFIX+item["instance_id"]
        new["source_id"]=mirrored(item.get("source_id",item["instance_id"]))
        new["kind"]=handed.get(item["kind"],item["kind"])
        if new.get("location","").startswith("support:"):new["location"] += "_right"
        trial["parts"].append(new)

    # An empty logical right-leg build waits at the shared station. It has no
    # physical stock until the one cradle is clear and takes its first foot.
    trial["parents"] += [dict(id="right_leg",definition="right_leg",label="Structural right leg",
        location="support:leg_queue_right",home=[14,1.85,9.4],rotation_degrees=[90,0,0]),
        dict(id="right_foot",definition="right_foot",label="Prepared right foot",location="support:right_foot_store",
             home=[-7,2,12.3],frame_offset=[0,-.8,.7],mirror_context_of="foot")]
    trial["builds"]=[]
    for build in foot_scenario["builds"]:
        record=deepcopy(build);record["id"]=assembly_ids[build["id"]];record["definition"]=definitions[build["definition"]]
        record["base"]=PREFIX+build["base"];record["label"]="Right "+record["label"]
        trial["builds"].append(record)
    trial["supports"]["leg_queue_right"]={"assemblies":["right_leg"],"assembly_ids":["right_leg"]}
    trial["supports"]["leg_queue_left"]={"assemblies":["left_leg"],"assembly_ids":["left_leg"]}
    trial["supports"]["right_foot_store"]={"assemblies":["right_foot"],"assembly_ids":["right_foot"]}
    trial["supports"]["foot_store"]={"assemblies":["foot"],"assembly_ids":["foot"]}
    trial["supports"]["leg_holder"]={"assemblies":["left_leg","right_leg"],"assembly_ids":["left_leg","right_leg"]}
    trial["supports"]["foot_carrier"]={"assemblies":["foot","right_foot"],"assembly_ids":["foot","right_foot"]}
    crane=trial["supports"]["crane_rigging"]
    crane["assemblies"]=["foot","right_foot"];crane["assembly_ids"]=["foot","right_foot"]
    crane["parts"] += [handed.get(key,key) for key in crane["parts"] if handed.get(key,key) not in crane["parts"]]
    crane["item_ids"] += [PREFIX+uid for uid in list(crane["item_ids"])]
    for key in ("shin","fork","spar"):
        rack="leg_"+key+"_rack_right"
        accepted=right_leg["slots"][key]["accepts"]
        trial["supports"][rack]={"parts":[accepted]}
        uid=PREFIX+left_leg["slots"][key]["pose_source"]
        trial["equipment"]["parts"][uid]=dict(owner="right_leg",slot=key,support=rack,delivery_support="crane_rigging")
        trial["robot"]["security_slots"]["right_"+key]=list(trial["robot"]["security_slots"][key])
    # Mirror the hip work as an independent branch of the pelvis manual.
    original_slots=deepcopy(pelvis["slots"])
    mirrored_pelvis=reflect_recipe(pelvis,"Hip assembly · hip installation")
    slot_names={sid:"right_leg" if sid=="left_leg" else "right/"+sid for sid in original_slots}
    for sid,record in mirrored_pelvis["slots"].items():
        record["requires"]=[slot_names[required] for required in record["requires"]]
        pelvis["slots"][slot_names[sid]]=record
    for page in mirrored_pelvis["manual"]:
        page["slots"]=[slot_names[sid] for sid in page.get("slots",[])]
        if "objectives" in page:
            kept=[]
            for objective in page["objectives"]:
                if objective.get("machine")=="leg_rail" and objective.get("command")=="build":
                    continue
                if objective.get("slot") in slot_names:
                    objective["slot"]=slot_names[objective["slot"]]
                if "slots" in objective:
                    objective["slots"]=[slot_names[sid] for sid in objective["slots"]]
                command=objective.get("command","")
                if isinstance(command,str) and command.startswith("lock:left_"):
                    objective["command"]="lock:right_"+command[len("lock:left_"):]
                kept.append(objective)
            page["objectives"]=kept
        pelvis["manual"].append(page)
    pelvis["title"]="Hip assembly · both hip installations"
    pelvis["milestones"]["right_ring_secured"]=[slot_names[sid] for sid in pelvis["milestones"]["left_ring_secured"]]
    pelvis["milestones"]["right_leg_secured"]=list(slot_names.values())
    pelvis["milestones"]["structural_ready"]=list(pelvis["slots"])
    context=[uid for uid in trial["context_sources"] if uid.startswith("PV-C-CLEVIS")]
    trial["context_sources"] += [mirrored(uid) for uid in context]
    pelvis["context_sources"]=trial["context_sources"]
    locks=trial["equipment"]["captive_controls"]
    for key,record in list(locks.items()):
        new=deepcopy(record);new["slot"]=slot_names[record["slot"]]
        new["requires"]=[slot_names[sid] for sid in record["requires"]]
        new["protected_slots"]=[slot_names[sid] for sid in record["protected_slots"]]
        new["group"]="right_leg_neutral";new["support_assembly"]="right_leg"
        new["position"]=vector(new["position"]);new["axis"]=vector(new["axis"])
        new["label"]="Right "+new["label"][:1].lower()+new["label"][1:]
        locks[key.replace("left_","right_")]=new
    trial["robot"]["playable_slots"].update(right_leg=list(right_leg["slots"]),pelvis=list(pelvis["slots"]))
    trial["robot"]["staged_slots"]["right_leg"]=[]
    trial["robot"]["controlled_mount_slots"] += ["right_leg.foot","pelvis.right_leg"]
    trial["mirror_sources"]={uid:uid.removeprefix(PREFIX) for uid in sorted(mirrors)}
    trial["prepared_branches"]={"right_foot":["right_pad_1","right_pad_2","right_pitch"]}
    return {"right_leg":right_leg,"right_foot":right_foot,"right_heel_pad":right_pad,"right_pitch_actuator":right_pitch}
