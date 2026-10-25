"""Prepared chest/cockpit and its external waist connection, in metre source frames.

Prepared members belong to one logical assembly; only the external washers,
bolts and service plugs add consumable stock. Internal preparation is supplied.
"""
import math


def extend(trial, kinds, pelvis, layout, diagram):
    sources = trial["sources"]
    context = []

    def box(at, size):return dict(shape="box", center=at, size=size)
    def tube(at, outer, inner, length, axis="y"):
        return dict(shape="tube", center=at, outer=outer, inner=inner, length=length, axis=axis)
    def plate(at, size, holes=(), rect=()):
        return dict(shape="plate", center=at, size=size, holes=list(holes), rect_holes=list(rect))
    def source(uid, at, shapes, prepared=True, rotation=(0,0,0)):
        sources[uid]=dict(family=uid.split("__")[0], position=at, rotation_degrees=list(rotation), primitives=shapes)
        if prepared:context.append(uid)
    def strut(a,b,r=.065):
        d=[b[i]-a[i] for i in range(3)];length=math.sqrt(sum(v*v for v in d))
        return tube([(a[i]+b[i])/2 for i in range(3)],r,0,length,[v/length for v in d])

    # Perforated flange and raised key bosses: no solid placeholder fills the
    # four bolt bores or the four upward-entering waist-key pockets.
    axes=[(x,z) for x in [-.84,.84] for z in [-.58,.58]]
    keys=[(x,z) for x in [-.92,.92] for z in [-.25,.25]]
    flange=[plate([0,.05,0],[2,.10,1.5],[[x,z,.0185] for x,z in axes],[[x,z,.084,.124] for x,z in keys])]
    for x,z in keys:
        flange += [plate([x,.12,z],[.15,.04,.20],rect=[[0,0,.084,.124]]),box([x,.15,z],[.15,.02,.20])]
    source("CH-FLANGE__001",[0,0,0],flange)
    frame=[]
    for side in [-1,1]:
        frame += [box([side*1.20,.865,.96],[.24,1.57,.28]),plate([side*1.02,.04,.77],[.60,.08,.66],[[-side*.18,-.19,.0185]])]
        for z in [-.35,.40]:frame.append(strut([side*.86,.10,z],[side*1.55,3.4,z],.075))
        frame += [box([side*1.40,3.40,.20],[.40,.18,1.8]),box([side*.82,1.27,-.20],[.24,.12,1.35])]
    frame += [box([0,1.525,.96],[2.64,.25,.28]),box([0,2.60,.96],[.5,1.90,.28]),box([0,3.10,.875],[3.70,.44,.45])]
    source("CH-FRAME__001",[0,0,0],frame)
    # Supplied opaque capsule, isolated ears and already-refitted front ties.
    capsule=[box([0,2.35,-.225],[1.4,2.2,1.55])]
    for x in [-.82,.82]:
        for z in [-.70,.30]:
            capsule += [box([x,1.31,z],[.22,.22,.20]),tube([x,1.27,z],.08,0,.16)]
    for side in [-1,1]:capsule.append(strut([side*1.15,1.15,-1.085],[side*.64,3.35,-1.085],.035))
    source("CH-COCKPIT__001",[0,0,0],capsule)
    # Four structural pads with outward guides. The crane's visible end handles
    # use these offsets; the load-bearing contacts remain on the upper pads.
    pads=[]
    for x in [-1.15,1.15]:
        for z in [-.65,.65]:
            handle_z=-.85 if z<0 else 1.05
            pads += [box([x,3.515,z],[.18,.07,.18]),box([x,3.49,(z+handle_z)/2],[.12,.12,abs(z-handle_z)+.12])]
            pads.append(strut([x,3.48,z],[math.copysign(1.55,x),3.40,z],.05))
    source("CH-LIFT__001",[0,0,0],pads)
    # Fixed rear roots keep the lower central cartridge corridor open.
    roots=[]
    for side in [-1,1]:
        roots += [box([side*.9,2.715,1.05],[.2,.33,.2]),box([side*1.115,.275,1.10],[.13,.25,.2]),
                  tube([side*1.08,2.15,1.27],.08,.03,.14,"x")]
    source("CH-REAR-ROOTS__001",[0,0,0],roots)
    # Fixed neck seat, four thread bores, central loom passage and front key.
    neck=[box([0,3.64,.30],[.96,.18,1.26]),tube([0,3.91,0],.20,.06,.38),
          dict(shape="ring_plate",center=[0,4.05,0],outer=.44,inner=.06,length=.10,
               holes=[[x,z,.0125] for x in [-.27,.27] for z in [-.27,.27]]),
          tube([0,4.19,0],.16,.06,.18),box([0,4.19,-.18],[.08,.14,.04]),
          plate([0,4.27,-.18],[.08,.02,.04])]
    source("CH-NECK__001",[0,0,0],neck)
    # Shoulder cups retain their true open mouth. Ring halves are future
    # external mounting stock, never baked into the prepared cup.
    for side,name in [(-1,"LEFT"),(1,"RIGHT")]:
        shapes=[dict(shape="hemisphere_shell",center=[0,0,0],outer=.43,inner=.345),
                dict(shape="ring_plate",center=[0,-.02,0],outer=.465,inner=.35,length=.12,
                     holes=[[.405*math.cos(a),.405*math.sin(a),.0125] for a in [math.pi/4,3*math.pi/4,5*math.pi/4,7*math.pi/4]])]
        source(f"CH-{name}-CUP__001",[side*2.2,3.1,0],shapes,rotation=(0,0,side*15))
        root=[box([side*1.765,3.1,.97],[.17,.44,.30]),box([side*2.02,3.26,.83],[.64,.22,.28]),
              strut([side*2.2,3.27,.83],[side*2.2,3.32,.44],.09),
              box([side*1.72,3.11,.64],[.12,.08,.40])]
        source(f"CH-{name}-ROOT__001",[0,0,0],root)
    chest=dict(title="Prepared chest and cockpit",carry_class="equipment",bounds=[5.48,4.28,2.55],
               work_locations=["support","parent"],interaction="components",context_sources=context,
               slots={},supplied_milestones=["prepared"],milestones={"prepared":[]},manual=[dict(title="Prepared chest and cockpit",view="overview",slots=[],
               body="The chest frame, enclosed cockpit, fixed shoulder cups and neck spoke are supplied assembled. Use Chest to Heavy Module Bay at the shared crane to transfer it from the chest rig after selecting chest inserts on the empty heavy module rig. Keep the fitted cockpit upright. After checking the supported unit, lower the heavy module rig to its pickup stop and choose Chest to waist. The hip assembly manual owns seating, retention and service connections.")])
    trial["parents"].append(dict(id="chest",definition="chest",label=chest["title"],location="support:chest_store",home=layout["workshop"]["chest_storage"]["position"]))
    trial["supports"]["chest_store"]=dict(assemblies=["chest"],assembly_ids=["chest"])
    for name in ["bulky_fixture","crane_rigging"]:
        trial["supports"][name].setdefault("assemblies",[]).append("chest")
        trial["supports"][name].setdefault("assembly_ids",[]).append("chest")
    slots=pelvis["slots"]
    source("CH-SEAT__001",[0,2.1,0],[box([0,.05,0],[2,.1,1.5])],False)
    slots["chest"]=dict(assembly="chest",milestone="prepared",requires=[],pose_source="CH-SEAT__001",snap_position=[0,2.1,0],
                        label="Prepared chest and cockpit",support_required=True,source_supports=["crane_rigging"],undo_requires_support="crane_rigging")
    def part(key,family,title):
        kinds[key]=dict(family=family,variant=key,title=family+" · "+title,short_title=title,carry_class="pocket")
    part("ch-w36","CH-W36","M36 waist washer")
    part("ch-m36-160","CH-H36160","M36 × 160 waist bolt")
    part("ch-service","CH-SERVICE","Chest service plug")
    def connection(sid,key,uid,requires,**extra):
        trial["parts"].append(dict(instance_id=uid,source_id=uid,part_id=kinds[key]["family"],kind=key,location="bin"))
        slots[sid]=dict(accepts=key,pose_source=uid,requires=list(requires),label=kinds[key]["title"],**extra)
        return sid
    hardware=[]
    for n,(x,z) in enumerate(axes,1):
        w=f"CH-W36__{n:03}";b=f"CH-H36160__{n:03}"
        source(w,[x,2.203,z],[tube([0,0,0],.033,.019,.006)],False)
        source(b,[x,2.206,z],[tube([0,-.08,0],.018,0,.16),tube([0,.018,0],.027,0,.036)],False)
        ws=connection(f"chest/washer_{n}","ch-w36",w,["chest"],undo_requires_support="crane_rigging")
        hardware += [ws,connection(f"chest/bolt_{n}","ch-m36-160",b,[ws],undo_requires_support="crane_rigging",target_offset=[0,.036,0])]
    services=[]
    for n,side in enumerate([-1,1],1):
        uid=f"CH-SERVICE__{n:03}"
        source(uid,[side*.86,1.95,0],[tube([0,0,0],.045,0,.12,"x"),tube([side*.06,0,0],.06,0,.025,"x"),strut([0,0,0],[-side*.06,.19,.10],.025)],False)
        services.append(connection(f"chest/service_{n}","ch-service",uid,hardware,requires_crane_clear="chest"))
        # Waist receiving bores and chest tail are prepared fixed context, each
        # owned by the physical assembly carrying it.
        receiving=f"PV-C-SERVICE__{n:03}"
        source(receiving,[side*.80,1.95,0],[tube([0,0,0],.065,.046,.08,"x")],False)
        trial["context_sources"].append(receiving);pelvis["context_sources"].append(receiving)
        source(f"CH-TAIL__{n:03}",[0,0,0],[strut([side*.80,.12,.25],[side*.80,.04,.10],.025)])
    crane, rig = "service_crane", "module_supports"
    def operate(machine, command, task=None):
        record = dict(op="operate", machine=machine, command=command)
        if task is not None: record["task"] = task
        return record
    def crane_to(task, seat=None):
        steps = [operate(crane, "pickup", task), operate(crane, "down"), dict(op="connect", machine=crane),
                 operate(crane, "up"), operate(crane, "go:receiver", task)]
        if seat is None: steps.append(operate(crane, "down"))
        else: steps.append(dict(op="seat", slot=seat, via=dict(machine=crane, command="down")))
        return steps
    def park():
        return [dict(op="detach", machine=crane), operate(crane, "up"), operate(crane, "go:park")]
    def objective_page(title, goal, ids, objectives, note=None):
        record = dict(title=title, view="components", slots=list(ids), goal=goal, objectives=objectives)
        if note is not None: record["note"] = note
        return record
    pelvis["manual"] += [
        objective_page("Bring the chest to the heavy module rig", "Fit chest inserts on the heavy module rig and crane the chest onto it.", [],
            [operate(rig, "template:chest")] + crane_to("chest_store") + park()),
        objective_page("Seat the prepared chest", "Crane the chest from the heavy module rig onto the waist.", ["chest"],
            crane_to("chest", "chest"), dict(at=2, text="Keep all four connectors attached until the chest is bolted.")),
        objective_page("Retain the chest on the waist", "Bolt the chest to the waist, then release and park the crane.", hardware,
            [dict(op="fit", slots=list(hardware))] + park(), dict(at=0, text="The bolts go downward into the waist threads.")),
        objective_page("Connect chest services", "Plug both chest service lines into the waist.", services,
            [dict(op="fit", slots=list(services))], dict(at=0, text="Keep both waist lock pins in."))]
    pelvis["manual"][-3]["diagram_views"]=[diagram("Prepared chest onto the locked waist",context,["PV-320__001"],
        offsets={uid:[0,2.1,0] for uid in context})]
    pelvis["manual"][-2]["diagram_views"]=[diagram("Waist corner "+str(n),[f"CH-W36__{n:03}",f"CH-H36160__{n:03}"],
        ["CH-FLANGE__001","PV-320__001"],offsets={"CH-FLANGE__001":[0,2.1,0]}) for n in range(1,5)]
    pelvis["manual"][-1]["diagram_views"]=[diagram("Chest service coupling",[f"CH-SERVICE__{n:03}"],
        [f"PV-C-SERVICE__{n:03}",f"CH-TAIL__{n:03}"],offsets={f"CH-TAIL__{n:03}":[0,2.1,0]}) for n in [1,2]]
    pelvis["milestones"]["chest_secured"]=["chest"]+hardware
    pelvis["milestones"]["chest_connected"]=["chest"]+hardware+services
    trial["robot"]["security_slots"]["chest"]=["chest"]+hardware
    trial["robot"]["controlled_mount_slots"].append("pelvis.chest")
    trial["robot"]["playable_slots"]["pelvis"]=list(slots)
    return chest
