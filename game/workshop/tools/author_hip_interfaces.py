"""Prepared hip drive/stop interfaces for the robot workshop, in pelvis-local axes.

The component specification uses X right/Y forward/Z up. Here Y is up and Z
is rear; the pelvis origin is the hip-centre height, as in the inherited ring.
This is external mounting work, not a cylinder-internals or articulation model.
"""
import math


def extend(trial, kinds, leg, pelvis, diagram):
    sources = trial["sources"]
    slots = pelvis["slots"]
    support = "leg_holder"
    controls = trial["equipment"].setdefault("captive_controls", {})

    def part(key, family, title, carry, **extra):
        kinds[key] = dict(family=family, variant=key, title=f"{family} · {title}",
                          short_title=title, carry_class=carry, **extra)

    def tube(at, outer, inner, length, axis="y"):
        return dict(shape="tube", center=at, outer=outer, inner=inner, length=length, axis=axis)

    def box(at, size):
        return dict(shape="box", center=at, size=size)

    def source(uid, family, at, shapes, rotation=(0, 0, 0)):
        sources[uid] = dict(family=family, position=at, primitives=shapes, rotation_degrees=list(rotation))

    def stock(uid, key):
        family = kinds.get(key, {}).get("family", "LG-W12")
        trial["parts"].append(dict(instance_id=uid, source_id=uid, part_id=family, kind=key, location="bin"))

    def connection(sid, key, uid, requires, **extra):
        slots[sid] = dict(accepts=key, pose_source=uid, requires=list(requires),
                          label=kinds.get(key, {}).get("title", "LG-W12 · M12 washer"),
                          undo_requires_support=support, **extra)
        stock(uid, key)
        return sid

    def page(title, body, ids):
        return dict(title=title, body=body, slots=ids, view="components",
                    diagram_views=[diagram(title, [slots[sid]["pose_source"] for sid in ids])])

    part("pv-stop-half", "PV-130", "Hip stop-cage half", "hand")
    part("pv-m12-60", "PV-H12060", "M12 × 60 stop-cage screw", "pocket")
    part("pv-cylinder", "PV-200", "Complete hip cylinder cartridge", "two_hand",
         handling=dict(distance=.9), collision_shapes=[
             dict(type="box", position=[0,-.66,0], size=[.24,1.49,.24])])
    part("pv-eye-pin", "PV-P60220", "Hip eye pin with captive keeper", "hand",
         collision_shapes=[dict(type="box", position=[0,0,0], size=[.09,.09,.25])])
    hip_x = -1.1
    ring = list(slots)
    pelvis["milestones"]["left_ring_secured"] = ring
    pages = []
    cage = []
    for half in (1, 2):
        uid = f"PV-130__{half:03}"
        # Two equivalent half shells with paired horizontal seam ears. The
        # 4-degree gap at each seam leaves the real through-bores open.
        shapes = [dict(shape="ring_plate", center=[0,0,0], inner=.335, outer=.46,
                       length=.22, start_degrees=184, end_degrees=356)]
        for x in (-.52, .52):
            for y in (-.06, .06):
                shapes.append(tube([x,y,-.014], .025, .0065, .028, [0,0,1]))
                shapes.append(box([math.copysign(.47,x),y,-.014],[.06,.05,.028]))
        source(uid,"PV-130",[hip_x,-.71,0],shapes,[0,0 if half==1 else 180,0])
        cage.append(connection(f"stop_half_{half}","pv-stop-half",uid,ring,undo_to="hands"))
    pages.append(page("Fit the hip stop cage", "With both ring halves and all four ring bolt pairs fitted, carry the two identical PV-130 stop-cage halves around the already retained neck. Their lower lip surrounds the prepared stop tongues; the cage limits motion and does not replace the ring or the engaged holder.",cage.copy()))
    fasteners = []
    for n,(x,y) in enumerate([(x,y) for x in (-.52,.52) for y in (-.06,.06)],1):
        w=f"LG-W12__{n+2:03}";b=f"PV-H12060__{n:03}"
        source(w,"LG-W12",[hip_x+x,-.71+y,-.030],[tube([0,0,0],.01104,.0066,.004,[0,0,1])])
        source(b,"PV-H12060",[hip_x+x,-.71+y,-.032],[tube([0,0,.03],.006,0,.06,[0,0,1]),tube([0,0,-.006],.009,0,.012,[0,0,1])])
        ws=connection(f"stop/washer_{n}","lg-w12",w,cage)
        fasteners += [ws,connection(f"stop/bolt_{n}","pv-m12-60",b,[ws],target_offset=[0,0,-.012])]
    pages.append(page("Secure the cage seams", "Fit four LG-W12 washers and four PV-H12060 M12 × 60 screws through the four front-facing seam ears, each washer before its screw. These screws are longer than the knee-cap screws. Keep the holder engaged for the cylinder connections.",fasteners))
    cage += fasteners
    # The stock cartridges use their own straight upright local frame. Each
    # destination clocks that frame to the two authored eye centres; installed
    # geometry follows the receiving source even when physical copies swap.
    contact_sources=[]
    lock_ids=[]
    for n,theta in enumerate((0,120,240),1):
        a=math.radians(theta);b=math.radians(theta+45)
        upper=[hip_x-.78*math.cos(a),-.60,-.78*math.sin(a)]
        lower=[hip_x-.48*math.cos(b),-1.80,-.48*math.sin(b)]
        delta=[lower[i]-upper[i] for i in range(3)]
        length=math.sqrt(sum(v*v for v in delta))
        pitch=math.acos(-delta[1]/length);yaw=math.atan2(-delta[0],-delta[2])
        # R=Ry(yaw) Rx(pitch). Return a world direction in the cartridge frame.
        def local(v):
            x=math.cos(yaw)*v[0]-math.sin(yaw)*v[2]
            z=math.sin(yaw)*v[0]+math.cos(yaw)*v[2]
            return [x,math.cos(pitch)*v[1]+math.sin(pitch)*z,-math.sin(pitch)*v[1]+math.cos(pitch)*z]
        pin_axis=local([0,0,1]);side=-1 if n<3 else 1
        uid=f"PV-200__{n:03}"
        shapes=[tube([0,-.46,0],.07,0,.76),tube([0,-(length+.84)/2,0],.035,0,length-.84),
                tube([0,0,0],.08,.031,.09,pin_axis),tube([0,-length,0],.08,.031,.09,pin_axis),
                box([.095,-length/2,0],[.025,length-.18,.035])]
        for sign in (-1,1):shapes.append(dict(shape="sphere",center=local([sign*.11,0,0]),radius=.02))
        source(uid,"PV-200",upper,shapes,[math.degrees(pitch),math.degrees(yaw),0])
        sid=connection(f"cylinder_{n}","pv-cylinder",uid,cage,
                       undo_to="hands",target_position=[upper[0],upper[1],upper[2]+side*.12])
        pins=[]
        for end,at in [("upper",upper),("lower",lower)]:
            puid=f"PV-P60220__{(n-1)*2+(1 if end=='upper' else 2):03}"
            # Insertion is from front/front/rear, with keeper at the far face.
            source(puid,"PV-P60220",at,[tube([0,0,0],.03,0,.22,[0,0,1]),
                   tube([0,0,side*.118],.045,0,.016,[0,0,1]),box([0,0,-side*.105],[.072,.012,.012])])
            pins.append(connection(f"cylinder_{n}/{end}_pin","pv-eye-pin",puid,
                          [sid] if end=="upper" else [pins[0]],undo_to="hands",target_offset=[0,0,side*.13]))
            # Prepared clevis cheeks/rests stay with the correct owning frame.
            local_at=at if end=="upper" else [at[0]-hip_x,at[1]+9.2,at[2]]
            brackets=[]
            for zsign in (-1,1):brackets.append(tube([0,0,zsign*.072],.10,.031,.05,[0,0,1]))
            brackets += [box([0,-.095,0],[.14,.03,.194])]
            if end=="upper":
                radial=[(at[0]-hip_x)/.78,0,at[2]/.78]
                brackets += [tube([0,.42,0],.05,0,.64),
                             tube([-radial[0]*.14,.74,-radial[2]*.14],.06,0,.28,radial)]
                # Two small parking saddles flank the upper eye; their lugs
                # are part of the cartridge and leave the pin bore exposed.
                for x in (-.11,.11):brackets.append(box([x,-.03,0],[.04,.02,.06]))
                cid=f"PV-C-CLEVIS__{n:03}";source(cid,"PV-C-CLEVIS",local_at,brackets)
                contact_sources.append(cid)
            else:
                spar=sources["LG-120__001"]
                radial=[(at[0]-hip_x)/.48,0,at[2]/.48]
                brackets.append(tube([-radial[0]*.19,0,-radial[2]*.19],.06,0,.38,radial))
                for primitive in brackets:
                    primitive["center"]=[primitive["center"][i]+local_at[i]-spar["position"][i] for i in range(3)]
                    spar["primitives"].append(primitive)
                    # The installed spar uses an authored compound, so include
                    # the new lug envelopes in motion collision as well.
                    size=primitive.get("size")
                    if size is None:
                        axis=primitive.get("axis","y")
                        axis=[0,1,0] if axis=="y" else axis
                        size=[abs(axis[i])*primitive["length"]+2*primitive["outer"]*math.sqrt(max(0,1-axis[i]**2)) for i in range(3)]
                    kinds["lg-thigh-spar"]["collision_shapes"].append(dict(type="box",position=primitive["center"],size=size))
        pages.append(page(f"Mount hip cylinder {n}", "Carry any PV-200 complete cartridge using one elevator shelf trip. With the leg holder engaged, lower its upper parking lugs into the clevis hooks and guide the lower eye onto its prepared rest. Assisted seating captures both rests at neutral length. Fit one PV-P60220 pin through the upper eye, then a second through the lower eye; each pin includes its captive keeper. The front two cartridges use front pin entry; the rear cartridge uses rear entry. Operate this cartridge's captive neutral lock after both pins are fitted.",[sid]+pins))
        lock_id=f"left_hip_{n}"
        lock_ids.append(lock_id)
        controls[lock_id]=dict(owner="pelvis",slot=sid,label=f"Hip cylinder {n} neutral lock",
             requires=pins,group="left_leg_neutral",support_assembly="left_leg",
             position=[.125,-length/2,0],axis=[1,0,0],stroke=.04,
             size=[.06,.025,.025],protected_slots=[sid]+pins)
    pelvis["milestones"]["left_leg_secured"]=list(slots)
    pelvis["milestones"]["structural_ready"]=list(slots)
    trial["context_sources"]=list(pelvis["context_sources"])+contact_sources
    pelvis["context_sources"]=trial["context_sources"]
    end=next(i for i,p in enumerate(pelvis["manual"]) if p["title"]=="Left leg structurally secured")
    pelvis["manual"][end:end]=pages
    pelvis["manual"][end+len(pages)]["body"]="Both retaining halves, all ring and stop-cage hardware, all three cylinders and their six eye pins are required. Operate each cylinder's captive neutral lock at its exposed index rail. Only then can Advance release the holder: open contacts, lower, withdraw 1.4 m rearward, compact and shift 2 m outboard. Return turns and travels the empty holder home without moving the installed leg. Stop and Advance hold/resume a phase. Reacquire holder support before unlocking a cylinder or undoing retention."
    trial["robot"]["playable_slots"]["pelvis"]=list(slots)
    # Prepared leg-owned collar/tongues share the upper spar's identity.
    spar=sources["LG-120__001"]
    local_y=9.2-.74-spar["position"][1]
    spar["primitives"] += [tube([0,local_y,0],.16,0,.04),box([0,local_y,0],[.44,.04,.06])]
    kinds["lg-thigh-spar"]["collision_shapes"] += [dict(type="box",position=[0,local_y,0],size=[.44,.04,.32])]
    # Every shelf accepts the same hand-carried families, with finite capacity
    # still enforced by the shelf controller. The crane has no role in this work.
    for name,definition in trial["supports"].items():
        if "shelf" in name:
            definition["parts"] += ["pv-stop-half","pv-cylinder","pv-eye-pin"]
