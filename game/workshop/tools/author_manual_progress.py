"""Bind manual machine work to its load and explicit physical completion evidence.

No page-order completion inference is emitted. Transport proof uses the crane's
authored route graph; persistent controls keep their live state requirements.
"""


def state(machine, **values):
    return dict(machine=machine, state=values)


def mounted(owner, slot):
    return dict(owner=owner, slot=slot)


def transport(task, phase):
    return dict(machine="service_crane", task=task, phase=phase)


def bind(recipes, chapters):
    task = ""
    for chapter in chapters:
        for owner, index, *_ in chapter["steps"]:
            if owner not in recipes:
                continue
            page = recipes[owner]["manual"][index]
            objectives = page.get("objectives", [])
            machines = {o.get("machine", o.get("via", {}).get("machine")) for o in objectives}
            for objective in objectives:
                if objective.get("machine") == "service_crane" and objective.get("task"):
                    task = objective["task"]
            scope = {}
            proofs = []
            seat = next((o for o in objectives if o["op"] == "seat" and "via" in o), None)
            if seat:
                # Actual mounting is durable proof of the preceding delivery.
                proofs.append(mounted(owner, seat["slot"]))
                if "foot_carrier" in machines:
                    scope["foot_carrier"] = dict(receiver=owner)
                if "leg_rail" in machines:
                    scope["leg_rail"] = dict(active_assembly=seat["slot"])
            if "service_crane" in machines:
                assert task, (owner, page["title"])
                scope["service_crane"] = dict(task=task)
                # The initial parked pose equals the final parked pose. Require
                # delivery evidence from the receiver-lowering objective onward.
                approaching = False
                delivered = not any(o.get("command") == "pickup" for o in objectives)
                for objective in objectives:
                    if objective.get("machine") != "service_crane":
                        continue
                    if approaching and objective.get("command") == "down":
                        delivered = True
                    if delivered:
                        objective["requires_state"] = transport(task, "arrived")
                    if objective.get("command") == "go:receiver":
                        approaching = True
                phase = "delivered"
                if any(o.get("machine") == "service_crane" and o.get("op") == "detach" and "point" not in o for o in objectives):
                    phase = "released"
                if any(o.get("command") == "go:park" for o in objectives):
                    phase = "parked"
                proofs.append(transport(task, phase))
            # Persistent operations remain mandatory even after equipment reuse.
            for objective in objectives:
                machine, command = objective.get("machine"), objective.get("command")
                if machine == "module_supports" and command == "insert_pins":
                    proofs.append(state(machine, pins=2))
                elif machine == "module_supports" and command == "close_jaws":
                    proofs.append(state(machine, jaws_closed=4))
                elif machine == "joint_restraints" and command.startswith("engage:"):
                    proofs.append(state(machine, **{command.removeprefix("engage:"): True}))
                elif machine == "core_guide" and command == "secure_bolts":
                    proofs.append(state(machine, **{f"bolt:{i}": True for i in range(4)}))
                elif machine == "core_guide" and command == "connection":
                    proofs.append(state(machine, connected=True))
                elif machine in ("left_shoulder", "right_shoulder"):
                    key = {"check_brakes": "brakes", "transfer_weight": "transferred"}[command]
                    proofs.append(state(machine, **{key: True}))
            if "backpack_hinge" in machines:
                latched = state("backpack_hinge", closed=True, latches=2)
                if any(o.get("command") == "lock_struts" for o in objectives):
                    # Closing deliberately reacquires the same crane task.
                    # The connected services supersede the earlier temporary
                    # detach instruction; required strut retention still applies.
                    services = recipes[owner]["milestones"]["backpack_connected"]
                    released = proofs.pop()
                    assert released == transport(task, "released")
                    proofs.append(dict(any=[released, dict(all=[mounted(owner, sid) for sid in services])]))
                    proofs.append(dict(any=[state("backpack_hinge", struts=2, locks=2), latched]))
                else:
                    proofs.append(state("backpack_hinge", closed=True, latches=2, covers=2, locks=0))
                    for objective in objectives:
                        if objective.get("command") == "take_weight":
                            objective["completed_by"] = latched
            if "leg_rail" in machines and not seat:
                commands = {o.get("command") for o in objectives if o.get("machine") == "leg_rail"}
                if "next:release" in commands:
                    side = "left_leg" if "build" in commands else "right_leg"
                    scope["leg_rail"] = dict(active_assembly=side)
                    page["requires_state"] = mounted("pelvis", side)
                    if side == "left_leg":
                        # Receiving the next foot already requires both rigs
                        # reset and the right build selected. Keep that evidence
                        # while the foot subsequently moves toward its leg.
                        proofs.append(transport("right_foot", "delivered"))
                    else:
                        proofs.append(dict(all=[state("leg_rail", active_assembly="right_leg", engaged=False, parked=True),
                                                state("foot_carrier", stop=0)]))
                    proofs.append(mounted("pelvis", side))
                elif "park" in commands:
                    proofs.append(state("leg_rail", parked=True))
            if scope:
                page["machine_scope"] = scope
            if proofs:
                page["completed_by"] = dict(all=proofs)
