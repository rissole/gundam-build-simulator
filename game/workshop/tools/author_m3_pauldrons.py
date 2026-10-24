"""Pauldron sources, receiver data and routes; no pauldron controller.

Carrier coordinates are upright Godot axes: X across, Y up, Z rearward.
The chest owns the mounting recipe; the prepared arm owns the threaded bosses.
"""
import math


def pose(at):
    return dict(position=list(at), rotation_degrees=[0, 0, 0])


def routes(layout):
    for side, sign, source_x in [("left", -1, -9.0), ("right", 1, -5.0)]:
        uid = side+"_pauldron"
        source = [source_x, 1.45, 1.0]
        seat = [13+sign*2.21, 15.75, 26]
        points = {"pauldron_front": [sign*.14, .63, -.65], "pauldron_rear": [sign*.14, .63, .65]}
        layout["crane"]["tasks"][uid] = dict(title=side.title()+" pauldron", payload="assembly", load_uid=uid,
            owner="chest", slot=uid, source_support=uid+"_store", support="m2_service_crane",
            guided_receiver=uid+"_receiver", receiver_equipment=uid+"_receiver",
            secured=dict(milestone=uid+"_retained"), endpoint_ids=["magnet_a", "magnet_b"],
            magnetic_points=points, handle_points=points,
            spreader_points=[[sign*.14, 0, -.85], [sign*.14, 0, .85]],
            source_pose=pose(source), receiver_pose=pose(seat),
            route_positions=[source, [source_x, 18.7, 1.0], [source_x, 18.7, 13],
                             [seat[0], 18.7, 13], [seat[0], 18.7, 26],
                             [seat[0], 17.35, 26], seat],
            approach=dict(axis=[0, -1, 0], distance=1.60), rig_clearance=1.20,
            sweep_rig=True, exact_receiver=True, sweep_radius=1.2, up_y=20.53,
            access_mode="head", console_position=layout["workshop"]["crane"]["console"],
            overhead_y=23.0, park_position=[8.4, 0, 18], rack_contacts=[])


def stores(data):
    # Bottom-open carriers rest on their outer-wall bottom edge, world Y .75.
    for side, x in [("left", -9.0), ("right", -5.0)]:
        sign = -1 if side == "left" else 1
        for n, z in enumerate([.57, 1.43]):
            for name, y, size in [("post", .345, [.18, .69, .26]), ("saddle", .72, [.22, .06, .30])]:
                data["solids"].append(dict(id=f"{side}_pauldron_store_{name}_{n}", parent="",
                    position=[x+sign*.575, y, z], size=size, material="yellow" if name=="saddle" else "steel", solid=True))


def extend(trial, chest, arms, kinds, layout, diagram):
    definitions = {}
    sources = trial["sources"]
    for key,title in [("long","Long"),("short","Short")]:
        family="PD-M20-"+key.upper()
        kinds["pd-bolt-"+key] = dict(family=family, variant="M20x120-"+key+"-shoe", title=family+" · M20 carrier bolt / "+key+" shoe", short_title="M20 / "+key+" shoe", carry_class="pocket")
    for face in ["front", "rear"]:
        kinds["pd-"+face] = dict(family="PD-"+face.upper(), variant=face,
            title="PD-"+face.upper()+" · "+face.title()+" upper closure panel", short_title=face.title()+" upper panel", carry_class="two_hand")
    def box(at, size):return dict(shape="box", center=list(at), size=list(size))
    def tube(at, outer, inner, length, axis):return dict(shape="tube", center=list(at), outer=outer, inner=inner, length=length, axis=axis)
    def source(uid, at, shapes, rotation=(0,0,0), motion=None):
        sources[uid] = dict(family=uid.split("__")[0], position=list(at), rotation_degrees=list(rotation), primitives=shapes)
        if motion is not None:sources[uid]["motion_shapes"]=motion
    def proxies(shapes):return [dict(type="box", position=p["center"], size=p["size"]) for p in shapes]
    # A single harness AABB filled its entire loop. Keep each protected run
    # segment solid, without treating the loop's empty interior as material.
    for slot in chest["slots"].values():
        if slot.get("accepts")!="sh-service":continue
        profile=[]
        for p in sources[slot["pose_source"]]["primitives"]:
            axis=[1,0,0] if p["axis"]=="x" else p["axis"]
            seed=[0,1,0] if abs(axis[1])<.9 else [1,0,0]
            cross=lambda a,b:[a[1]*b[2]-a[2]*b[1],a[2]*b[0]-a[0]*b[2],a[0]*b[1]-a[1]*b[0]]
            u=cross(axis,seed);length=math.sqrt(sum(v*v for v in u));u=[v/length for v in u];v=cross(axis,u)
            vertices=[]
            radius=p["outer"]/math.cos(math.pi/16)
            for end in [-1,1]:
                for n in range(16):
                    angle=n*math.pi/8
                    vertices.append([p["center"][i]+end*axis[i]*p["length"]/2+radius*(u[i]*math.cos(angle)+v[i]*math.sin(angle)) for i in range(3)])
            profile.append(dict(type="convex",points=vertices))
        slot["collision_shapes"]=profile
    for side, sign, prefix in [("left", -1, "AL"), ("right", 1, "AR")]:
        uid = side+"_pauldron"; root=uid+"/"; slots=chest["slots"]
        carrier_at=[sign*2.21, 3.05, 0] # chest datum world Y12.70
        def arm_point(p):
            f,e,t=p;s=math.sin(math.pi/12);c=math.cos(math.pi/12)
            return [sign*2.2+sign*(c*e+s*t), 3.1+s*e-c*t, -sign*f]
        def local(p):return [a-b for a,b in zip(p,carrier_at)]
        # Bottom-open mounting reliefs let the arm-owned M20 bosses enter the
        # outer wall during the last .18 m of descent; no closed hole is lowered
        # through a fixed boss. Saddles bear on the uninterrupted front/rear rim.
        shell=[box([0,.685,0],[1.18,.03,1.30]), box([sign*.575,.075,0],[.03,1.19,1.30])]
        for lo,hi in [(-.65,-.105),(-.005,.005),(.105,.65)]:
            shell.append(box([sign*.575,-.61,(lo+hi)/2],[.03,.18,hi-lo]))
        source("PD-"+side.upper()+"-SHELL__001",[0,0,0],shell,motion=proxies(shell))
        context=["PD-"+side.upper()+"-SHELL__001"]
        rig=[box([sign*.14,.63,z],[.14,.12,.02]) for z in [-.64,.64]]
        source("PD-"+side.upper()+"-LIFT__001",[0,0,0],rig,motion=proxies(rig));context.append("PD-"+side.upper()+"-LIFT__001")
        bolts=[];lugs=[]
        beam=sources[prefix+"-BALL-BEAM__001"]
        for n,(t,f) in enumerate([(t,f) for t in [.60,.75] for f in [-.11,.11]],1):
            # Native arm f-axis bolts, with the exact existing yaw/splay transform.
            direction=1 if f>0 else -1
            boss=tube([direction*.055,.38,t],.028,.0105,.066,"x")
            beam["primitives"].append(boss)
            beam["motion_shapes"].append(dict(type="box",position=boss["center"],size=[.066,.056,.056]))
            # Integral arm-owned ear joining the boss to the structural beam.
            web=box([direction*.055,.245,t],[.05,.23,.025])
            beam["primitives"].append(web);beam["motion_shapes"]+=proxies([web])
            p=arm_point([direction*.10,.38,t]);q=local(p)
            # Only the outboard ledge descends past the ring. The inboard
            # clamping shoe is captive to the M20 bolt unit, fitted after seating.
            wall=sign*.575
            lugs.append(box([wall-sign*.0075,q[1],q[2]],[.045,.055,.020]))
            bolt_uid=f"PD-M20__{n+(0 if sign<0 else 4):03}"
            head=arm_point([f,.38,t]);wall_x=carrier_at[0]+sign*.56
            dz=-sign*direction
            source(bolt_uid,head,[
                tube([0,0,-dz*.06],.010,0,.12,[0,0,1]),tube([0,0,dz*.007],.015,0,.014,[0,0,1]),
                box([(wall_x-head[0])/2,0,dz*.006],[abs(wall_x-head[0])+.022,.045,.012])])
            kind="pd-bolt-"+("long" if t==.60 else "short")
            trial["parts"].append(dict(instance_id=bolt_uid,source_id=bolt_uid,part_id=kinds[kind]["family"],kind=kind,location="bin"))
            sid=root+"bolt_"+str(n);bolts.append(sid)
            slots[sid]=dict(accepts=kind,pose_source=bolt_uid,requires=[uid],label=kinds[kind]["title"],access_policy="mounted",undo_requires_support="m2_service_crane")
        lug_uid="PD-"+side.upper()+"-LUGS__001"
        source(lug_uid,[0,0,0],lugs);context.append(lug_uid)
        # Tight separate proxies preserve the empty cup cavity, never one full box.
        sources[lug_uid]["motion_shapes"]=[dict(type="box",position=p["center"],size=p.get("size",[.056,.056,.02])) for p in lugs]
        definitions[uid]=dict(title="Prepared "+side+" pauldron carrier",carry_class="equipment",bounds=[1.18,1.40,1.30],
            work_locations=["support","parent"],interaction="components",context_sources=context,slots={},
            supplied_milestones=["prepared"],milestones=dict(prepared=[]),
            manual=[dict(title="Prepared pauldron carrier",view="overview",slots=[],body="Open bottom and inboard cavity; use the two front/rear rig plates. Mounting bolts and panels belong to the chest manual.")])
        seat_source="PD-"+side.upper()+"-SEAT__001"
        source(seat_source,carrier_at,[box([0,0,0],[.02,.02,.02])])
        slots[uid]=dict(assembly=uid,milestone="prepared",requires=[side+"_arm/service"],pose_source=seat_source,label=definitions[uid]["title"],
            support_required=True,source_supports=["m2_service_crane"],undo_requires_support="m2_service_crane",secured_by=bolts.copy(),access_policy="mounted")
        # Keep installation and audit order topological.
        for sid in bolts:slots[sid]=slots.pop(sid)
        panels=[]
        for face,z,low,rows in [("front",-.635,-.15,[.0,.52]),("rear",.635,.45,[.51,.63])]:
            panel_uid="PD-"+face.upper()+f"__{1 if sign<0 else 2:03}"
            height=.67-low
            at=[carrier_at[0]-sign*.015,carrier_at[1]+(low+.67)/2,z]
            shapes=[box([0,0,0],[1.15,height,.03])]
            # Four captive screw heads travel with each panel, no separate stock.
            for x in [-.44,.44]:
                for y in rows:shapes.append(tube([x,y-(low+.67)/2,-.023 if face=="front" else .023],.010,0,.016,[0,0,1]))
            source(panel_uid,at,shapes)
            trial["parts"].append(dict(instance_id=panel_uid,source_id=panel_uid,part_id=kinds["pd-"+face]["family"],kind="pd-"+face,location="bin"))
            sid=root+face;panels.append(sid)
            slots[sid]=dict(accepts="pd-"+face,pose_source=panel_uid,requires=bolts.copy(),label=kinds["pd-"+face]["title"],access_policy="mounted",undo_to="hands")
            assert 1.15<=1.35 and .054<=.35 and height<=1.10
        retained=[uid]+bolts
        chest["milestones"][uid+"_retained"]=retained
        chest["milestones"][uid+"_closed"]=retained+panels
        trial["m3"]["security_slots"][uid]=retained
        trial["m3"]["controlled_mount_slots"].append("chest."+uid)
        task=layout["crane"]["tasks"][uid]
        trial["parents"].append(dict(id=uid,definition=uid,label=definitions[uid]["title"],location="support:"+uid+"_store",home=task["source_pose"]["position"]))
        trial["supports"][uid+"_store"]=dict(assemblies=[uid],assembly_ids=[uid])
        for key in ["assemblies","assembly_ids"]:trial["supports"]["m2_service_crane"][key].append(uid)
        trial["equipment"].setdefault("receivers",{})[uid+"_receiver"]=dict(title=definitions[uid]["title"],uid=uid,owner="chest",slot=uid,seat=pose(carrier_at),crane_task=uid,
            requires=["chest:"+side+"_arm_connected"],retention_slots=bolts,closure_slots=panels,
            rig=dict(normals=[[0,0,-1],[0,0,1]]),
            operations=[dict(id="joint_restraints",owner=side+"_arm",source=prefix+"-JOINT-RESTRAINTS__001",point=[sign*.46,0,3],label="elbow / wrist restraints"),
                        dict(id="digit_cradle",owner=side+"_arm",source=prefix+"-DIGIT-CRADLE__001",point=[0,-.30,6.82],label="digit cradle")])
        def page(title,body,ids):return dict(title=side.title()+" pauldron: "+title,body=body,slots=ids,view="components",
            diagram_views=[diagram(title,[slots[s]["pose_source"] for s in ids])])
        chest["manual"] += [page("deliver carrier","With the shoulder retained, brakes checked, weight transferred and services connected, stow all arm crane ends. Select "+side.title()+" pauldron at the central crane console. Its upright passive store is in small stock at X"+str(task["source_pose"]["position"][0])+", Z1. Fit both front/rear ends and lift above the guards; travel via front Z13, then lower through the open deck notch. Keep both ends attached.",[uid]),
            page("retain carrier","Pocket two PD-M20-LONG bolt units and two PD-M20-SHORT bolt units. The long captive shoes span the proximal bosses; the short shoes fit the distal pair. Fit from front/rear into the arm-owned bosses, clamping the carrier ledges after seating. Keep both crane ends attached. Reacquire both ends before any local bolt correction.",bolts),
            page("front closure","Release and stow both crane ends. Carry PD-FRONT with two hands on an elevator shelf. Fit the upper panel and fasten its four captive M12 screws. The permanent lower mechanical window stays open.",[panels[0]]),
            page("rear closure","Carry PD-REAR with two hands on an elevator shelf. Fit the upper strip and fasten its four captive M12 screws; leave the lower mechanical window open. Once both panels close, release the elbow/wrist restraints and digit cradle at their local handles. Re-engage them before reopening panels for correction.",[panels[1]])]
    for support in trial["supports"]:
        if support.startswith(("left_shelf_", "right_shelf_")):
            trial["supports"][support]["parts"] += ["pd-front", "pd-rear"]
    trial["m3"]["playable_slots"]["chest"]=list(chest["slots"])
    return definitions
