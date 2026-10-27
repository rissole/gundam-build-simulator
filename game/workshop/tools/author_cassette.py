"""Track the one movable cassette as equipment, using the blockout as source.

The cassette is a reusable physical assembly, not consumable robot stock. Arms
keep their own identities on its support while its floor/crane ownership moves.
"""
import math

def extend(trial, layout):
    world=layout["workshop"];groups=world["groups"];context=[];pieces={}
    def relative(group):
        if group=="arm_cassette":return [0,0,0]
        entry=groups[group]
        assert entry["rotation_degrees"]==[0,0,0]
        parent=relative(entry["parent"])
        return [a+b for a,b in zip(parent,entry["position"])]
    def belongs(group):
        while group:
            if group=="arm_cassette":return True
            group=groups[group]["parent"]
        return False
    for piece in world["solids"]:
        if not belongs(piece["parent"]):continue
        uid="CS-"+piece["id"]
        origin=relative(piece["parent"])
        position=[a+b for a,b in zip(origin,piece["position"])]
        primitive=dict(shape="box",center=[0,0,0],size=piece["size"])
        if piece["id"].startswith("arm_cassette_foot_"):
            primitive.update(shape="plate",axis="y",holes=[[0,0,.021]])
        trial["sources"][uid]=dict(family="CS-FRAME",position=position,rotation_degrees=[0,0,0],
            primitives=[primitive],
            motion_shapes=[dict(type="box",position=[0,0,0],size=piece["size"])],
            mass_kg=math.prod(piece["size"])*400,mass_center=position)
        context.append(uid)
        pieces[uid]=dict(group=piece["parent"],position=piece["position"],size=piece["size"])
    for n,(t,x) in enumerate([(t,x) for t in [1.35,6.05] for x in [-.7,.7]],1):
        for key,position,primitive,motion in [
            ("LOCK-PIN",[x,.02,t],dict(shape="tube",center=[0,0,0],outer=.02,inner=0,length=.20,axis="y"),dict(type="cylinder",radius=.02,height=.20)),
            ("LOCK-HANDLE",[x+(.11 if x>0 else -.11),.30,t],dict(shape="box",center=[0,0,0],size=[.12,.05,.14]),dict(type="box",size=[.12,.05,.14]))]:
            uid=f"CS-{key}__{n:03}"
            volume=math.pi*.02**2*.20 if key=="LOCK-PIN" else math.prod(primitive["size"])
            trial["sources"][uid]=dict(family="CS-"+key,position=position,rotation_degrees=[0,0,0],primitives=[primitive],motion_shapes=[motion],mass_kg=volume*7800,mass_center=position)
            context.append(uid);pieces[uid]=dict(group="",position=position)
    descriptor=dict(title="Arm rig",carry_class="equipment",bounds=[2,1.68,9],
        work_locations=["support"],interaction="components",context_sources=context,slots={},
        supplied_milestones=["prepared"],milestones={"prepared":[]},manual=[dict(title="Arm rig",view="overview",slots=[],
        body="Park the leg rig (Park, then hold INDEX +) before bringing the arm rig into the Limb Bay. The arm rig holds the prepared arm on three saddles and six clamps. Use the shared crane's Arm rig to Limb Bay task, fit all four magnetic connectors, then raise and transfer the retained arm rig. Its floor locks engage before the crane releases. Reverse the same task to park an unfinished arm without changing its construction.")])
    trial["parents"].append(dict(id="arm_cassette",definition="arm_cassette",label=descriptor["title"],location="support:cassette_park",home=[14,0,-6.3]))
    for name in ["cassette_park","cassette_station"]:
        trial["supports"][name]=dict(assemblies=["arm_cassette"],assembly_ids=["arm_cassette"])
    for key in ["assemblies","assembly_ids"]:
        trial["supports"]["crane_rigging"][key].append("arm_cassette")
        trial["supports"]["arm_cassette"][key]=["left_arm","right_arm"]
    trial["equipment"]["arm_cassette"]=dict(pieces=pieces,park=[14,0,-6.3],station=[14,0,9.9],arm_offset=[0,1.55,0])
    return descriptor
