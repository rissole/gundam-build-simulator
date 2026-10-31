"""Explicit player-operated fronts for the crane's gantry crossings.

The routes in author_workshop_blockout and service_crane._upper_crossing put
these loaded transfers and their empty returns through the upper leaf band.
Storage/fixture and Limb Bay transfers stay outside it. No crane task is changed.
"""

CROSSING_TASKS = {
    "pelvis", "chest", "core", "backpack", "left_arm", "right_arm",
    "left_pauldron", "right_pauldron", "head_baseplate", "head_left",
    "head_right", "head_top", "head_crown",
}
ARM_TASKS = {"left_arm", "right_arm"}


def front(command):
    return dict(op="operate", machine="workshop_access", command=command)


def position(objectives, objective):
    """Index by identity: separate "up" commands compare equal."""
    return next(i for i, o in enumerate(objectives) if o is objective)


def insert(page, index, objective):
    page["objectives"].insert(index, objective)
    if page.get("note", {}).get("at", -1) >= index:
        page["note"]["at"] += 1


def bind_fronts(recipes, chapters):
    groups = {key: [] for key in ("upper_delivery", "upper_return", "arm_delivery", "arm_return")}
    task = ""
    for chapter in chapters:
        for owner, index, *_ in chapter["steps"]:
            if owner not in recipes:
                continue
            page = recipes[owner]["manual"][index]
            objectives = page.get("objectives", [])
            crane = [o for o in objectives if o.get("machine") == "service_crane"]
            for objective in crane:
                task = objective.get("task", task)
            if task not in CROSSING_TASKS or not crane:
                continue
            delivery = next((o for o in crane if o.get("command") == "go:receiver"), None)
            # A return raises the released crane from the connection. The crane
            # waits there, so the upper leaves stay open for its next pickup.
            ups = [o for o in crane if o.get("command") == "up"]
            ret = ups[-1] if ups and (delivery is None or position(objectives, ups[-1]) > position(objectives, delivery)) else None
            if delivery:
                if task in ARM_TASKS:
                    # Arm routes stop in front of the leaves; the receiver's
                    # lowering/seat crosses them. The lower front is needed
                    # earlier, as soon as the loaded crane starts lifting.
                    lift = next(o for o in crane if o.get("command") == "up")
                    insert(page, objectives.index(lift), front("lower_open"))
                    seat = next(o for o in objectives if o.get("op") == "seat")
                    insert(page, objectives.index(seat), front("upper_open"))
                else:
                    insert(page, objectives.index(delivery), front("upper_open"))
            if ret:
                # Rope work may have closed the leaves since delivery. Reopen
                # before raising the empty spreader: some head spreaders still
                # touch the band while rising.
                at = position(objectives, ret)
                if task in ARM_TASKS:
                    insert(page, at, front("lower_close"))
                    at += 1
                if not delivery:
                    insert(page, at, front("upper_open"))
            if delivery or ret:
                page["goal"] = page["goal"].rstrip(".") + ", using the UPPER GANTRY panel at 20.6 m beside the left lift to " + ("open the way before crossing." if delivery else "open the leaves before raising the crane.")
                # The core's individual connector and guide operations and the
                # backpack's closing operation stay explicit. Their patterns
                # differ from an ordinary delivery/release.
                if delivery and not ret and task != "core":
                    groups["arm_delivery" if task in ARM_TASKS else "upper_delivery"].append([owner, index])
                if ret and not delivery and task != "backpack":
                    groups["arm_return" if task in ARM_TASKS else "upper_return"].append([owner, index])
    titles = {
        "upper_delivery": "Crane a load through the upper gantry",
        "upper_return": "Open the upper gantry and raise the released crane",
        "arm_delivery": "Open both gantries and crane the arm to its shoulder",
        "arm_return": "Close the lower gantry, open the upper gantry and raise the released crane",
    }
    return {key: dict(title=titles[key], machines=["service_crane", "workshop_access"], pages=pages)
            for key, pages in groups.items()}
