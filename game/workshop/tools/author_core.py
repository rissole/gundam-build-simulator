"""Prepared core, captured guides and the two-ended rear delivery contract."""
import math


def extend(trial, chest, layout, diagram):
    sources=trial["sources"];context=[];dock=[]
    def box(at,size):return dict(shape="box",center=at,size=size)
    def tube(at,r,inside,length):return dict(shape="tube",center=at,outer=r,inner=inside,length=length,axis=[0,0,1])
    def add(uid,at,shapes,owner=context,rotation=(0,0,0),motion=None):
        sources[uid]=dict(family=uid.split("__")[0],position=at,rotation_degrees=list(rotation),primitives=shapes)
        if motion is not None:sources[uid]["motion_shapes"]=motion
        owner.append(uid)
    def proxy(at,size):return dict(type="box",position=at,size=size)
    add("PC-BODY__001",[0,0,0],[tube([0,0,.23],.42,0,1.6),tube([0,0,-.61],.09,0,.08),box([.095,0,-.61],[.03,.04,.08])],motion=[
        dict(type="cylinder",radius=.42,height=1.6,position=[0,0,.23],rotation_degrees=[90,0,0]),
        dict(type="cylinder",radius=.09,height=.08,position=[0,0,-.61],rotation_degrees=[90,0,0]),proxy([.095,0,-.61],[.03,.04,.08])])
    # Flange notches pass the continuous diagonal guide rails. The center disc
    # stops inside those channels; three annular sectors leave the two mouths.
    flange=[tube([0,0,1.085],.42,0,.11)]
    proxies=[dict(type="cylinder",radius=.42,height=.109,position=[0,0,1.085],rotation_degrees=[90,0,0])]
    for start,end in [(-38,38),(52,128),(142,322)]:
        holes=[]
        for angle in [0,90,180,270]:
            if start<angle<end:holes.append([.445*math.cos(math.radians(angle)),.445*math.sin(math.radians(angle)),.0085])
        flange.append(dict(shape="ring_plate",center=[0,0,1.085],outer=.47,inner=.42,length=.11,axis=[0,0,1],start_degrees=start,end_degrees=end,holes=holes))
        # Convex sectors retain the notches during moving collision queries.
        count=math.ceil((end-start)/5)
        for i in range(count):
            a=math.radians(start+(end-start)*i/count);b=math.radians(start+(end-start)*(i+1)/count)
            vertices=[[r*math.cos(t),-r*math.sin(t),z] for z in [1.0305,1.1395] for r,t in [(.42,a),(.47,a),(.47,b),(.42,b)]]
            proxies.append(dict(type="convex",points=vertices))
    add("PC-FLANGE__001",[0,0,0],flange,motion=proxies)
    for side,width in [(-1,.04),(1,.06)]:
        angle=135 if side<0 else -135
        # Integral T keys and captured channels: narrow neck, broader head,
        # different widths. Their undersides/side lips establish guide capture.
        keys=[box([0,.424,.23],[.020,.028,1.60]),box([0,.441,.23],[width,.012,1.60])]
        add(f"PC-KEY__{1 if side<0 else 2:03}",[0,0,0],keys,rotation=[0,0,angle],motion=[proxy(p["center"],p["size"]) for p in keys])
        channels=[box([0,.460,.275],[width+.038,.020,1.65])]
        for sign in [-1,1]:
            channels += [box([sign*(width/2+.010),.441,.275],[.012,.026,1.65]),
                         box([sign*(.014+(width/2-.014)/2),.428,.275],[width/2-.014,.008,1.65])]
        add(f"CH-CORE-GUIDE__{1 if side<0 else 2:03}",[0,.65,0],channels,dock,[0,0,angle])
    # Continuous receiving ring with relief for both guide channels and the
    # permanent upper lifting pads. Cardinal bolt bosses remain uninterrupted;
    # side webs bulge to R.55 while upper/lower cardinal bounds stay at R.50.
    dock_ring=[]
    for start,end,inner,outer in [(-65,-55,.425,.55),(-55,-35,.495,.55),(-35,38,.425,.55),
        (38,52,.477,.55),(52,65,.425,.55),(65,115,.425,.50),(115,128,.425,.55),
        (128,142,.477,.55),(142,215,.425,.55),(215,235,.495,.55),(235,245,.425,.55),(245,295,.425,.50)]:
        holes=[[.445*math.cos(math.radians(a)),.445*math.sin(math.radians(a)),.0085] for a in [0,90,180,270] if start<a<end]
        dock_ring.append(dict(shape="ring_plate",center=[0,0,.99],outer=outer,inner=inner,length=.08,axis=[0,0,1],start_degrees=start,end_degrees=end,holes=holes))
    add("CH-CORE-DOCK__001",[0,.65,0],dock_ring+[
        dict(shape="ring_plate",center=[0,0,-.65],outer=.14,inner=.095,length=.14,axis=[0,0,1],start_degrees=17,end_degrees=343),
        dict(shape="ring_plate",center=[0,0,-.65],outer=.14,inner=.115,length=.14,axis=[0,0,1],start_degrees=343,end_degrees=377),box([0,-.49,-.65],[1.08,.035,.14])]+
        [box([x,-.25,.99],[.045,.50,.08]) for x in [-.53,.53]],dock)
    # Bridge contacts lie on the core. The removable bridge itself belongs to
    # the crane and disappears from the load only after the guide handoff.
    add("PC-LIFT__001",[0,0,0],[box([x,.32,-.15],[.10,.04,.04]) for x in [-.30,.30]]+
        [box([0,.22,1.15],[.16,.14,.02])],motion=[proxy([x,.32,-.15],[.10,.04,.04]) for x in [-.30,.30]]+[proxy([0,.22,1.15],[.16,.14,.02])])
    bolts=[]
    for i,(x,y) in enumerate([(-.445,0),(.445,0),(0,-.445),(0,.445)],1):
        uid=f"PC-H16-CAPTIVE__{i:03}"
        add(uid,[x,y,1.15],[tube([0,0,-.055],.008,0,.11),tube([0,0,0],.012,0,.02)],owner=[])
        bolts.append(dict(source=uid,position=[x,y,1.16]))
    chest["context_sources"]+=dock
    core=dict(title="Prepared power core",carry_class="equipment",bounds=[.94,.94,1.81],work_locations=["support","parent"],interaction="components",
        context_sources=context,slots={},supplied_milestones=["prepared"],milestones={"prepared":[]},manual=[dict(title="Prepared core cartridge",view="overview",slots=[],
        body="The core cartridge, keyed rails and four captive retaining bolts are supplied. Keep it horizontal on the bulky fixture's core saddles. Its forward equalizing bridge captures two side pads; the aft end attaches to the rear pad. The chest manual owns guide insertion, retention and rear connection.")])
    trial["parents"].append(dict(id="core",definition="core",label=core["title"],location="support:core_store",home=layout["workshop"]["core_storage"]["position"]))
    for name in ["core_store","core_guide"]:trial["supports"][name]=dict(assemblies=["core"],assembly_ids=["core"])
    for name in ["bulky_fixture","crane_rigging"]:
        trial["supports"][name]["assemblies"].append("core");trial["supports"][name]["assembly_ids"].append("core")
    chest["slots"]["core"]=dict(assembly="core",milestone="prepared",requires=[],label=core["title"],pose_source="CH-CORE-DOCK__001",snap_position=[0,.65,0],
        support_required=True,source_supports=["core_guide"],undo_requires_support="core_guide",access_policy="mounted",secured_equipment="core_guide")
    chest["milestones"]["core_seated"]=["core"]
    chest["manual"] += [dict(title="Deliver and guide the core",view="components",slots=["core"],
        body="Select core saddles on the empty bulky fixture, then use Core to fixture to collect the prepared cartridge. Core to rear dock follows the low right-side bypass, outboard lift and high crossing. Down brings the horizontal load to the rear approach with both ends fitted. At the right-side guide control, Advance stops at captured engagement. Release and stow the forward equalizing bridge using its side handle; keep the aft end fitted. Advance folds the unloaded forward equalizer and shifts its head aft before inserting farther. The aft end and captured guides stay engaged. Advance again, if stopped, completes flange and keyed-nose seating.",
        diagram_views=[diagram("Core and captured guides",context,dock,offsets={uid:[0,.65,0] for uid in context})]),
        dict(title="Retain and connect the core",view="overview",slots=[],status_equipment="core_guide",
        body="Operate all four PC-H16 captive flange bolts, then complete the rear interlock connection. The aft crane end remains fitted through both operations. Release and stow that end only when all four bolts and the rear connection are secure. For local correction, isolate the connection, refit the aft end and release all four bolts. Return stops at guide capture. Return again extends the empty forward rig; refit its bridge before returning out of the guides.")]
    trial["robot"]["playable_slots"]["chest"]=["core"]
    trial["robot"]["controlled_mount_slots"].append("chest.core")
    trial["equipment"]["core_guide"]=dict(owner="chest",uid="core",slot="core",support="core_guide",travel=2.20,capture=.85,
        panel=[1.9,-.30,1.80],seat=[0,.65,0],bolts=bolts,connection=[.50,.88,1.16],isolation=[-.50,.88,1.16],
        front_point="core_front",aft_point="core_aft",rig=dict(full_center=[0,1.75,.60],aft_center=[0,1.39,1.35],
            full_size=[.28,.18,1.64],aft_size=[.28,.18,.34],full_anchors=[[0,0,-.65],[0,0,.65]],aft_anchors=[[0,0,-.08],[0,0,0]],
            contacts=[[0,.58,-.15],[0,.22,1.16]],overhead_y=23,stow_drop=.55),
        bridge=dict(position=[0,.58,-.15],handle=[.42,.32,-.15],shapes=[
            dict(at=[0,.58,-.15],size=[.70,.06,.04]),dict(at=[-.30,.46,-.15],size=[.08,.24,.04]),
            dict(at=[.30,.46,-.15],size=[.08,.24,.04]),dict(at=[.39,.32,-.15],size=[.18,.06,.04])]))
    return core
