class_name HeelAssemblyState
extends RefCounted
## Physical identity is conserved across bins, pockets, loose parts and builds.
## This model supplies placement, manual progress, feedback and undo.

signal changed
const KINDS = ["sleeve", "washer", "bolt"]
const TITLES = {"sleeve": "FA-305 · Compression sleeve", "washer": "W-24 · Washer", "bolt": "H-24120 · Mounting bolt", "pad": "FA-302 · Heel pad"}
var items: Dictionary = {}
var slots: Dictionary = {"sleeve": ["", "", "", ""], "washer": ["", "", "", ""], "bolt": ["", "", "", ""]}
var pad_location: String = "loose"
var history: Array[Dictionary] = []
var capacity: int = 20
var pad_id: String

func configure(config: Dictionary) -> void:
	items.clear()
	pad_id = config.pad_id
	capacity = int(config.pocket_capacity)
	for part in config.parts:
		items[part.instance_id] = {"kind": part.kind, "location": "loose" if part.kind == "pad" else "bin"}

func count_at(kind: String, location: String) -> int:
	var n = 0
	for item in items.values():
		if item.kind == kind and item.location == location: n += 1
	return n

func pocket_count() -> int:
	var n = 0
	for kind in KINDS: n += count_at(kind, "pocket")
	return n

func find_item(kind: String, location: String) -> String:
	for uid in items:
		if items[uid].kind == kind and items[uid].location == location: return uid
	return ""

func take(kind: String, location: String = "bin", uid: String = "") -> String:
	if pocket_count() >= capacity: return ""
	if uid.is_empty(): uid = find_item(kind, location)
	if not items.has(uid) or items[uid].kind != kind or items[uid].location != location: return ""
	items[uid].location = "pocket"
	changed.emit()
	return uid

func drop(kind: String) -> String:
	var uid = find_item(kind, "pocket")
	if uid.is_empty(): return ""
	items[uid].location = "loose"
	changed.emit()
	return uid

func return_to_bin(kind: String) -> String:
	var uid = find_item(kind, "pocket")
	if uid.is_empty(): return ""
	items[uid].location = "bin"
	changed.emit()
	return uid

func move_pad(where: String) -> void:
	pad_location = where
	items[pad_id].location = where
	changed.emit()

func installed(kind: String) -> int:
	return 4 - slots[kind].count("")

func prepared() -> bool:
	return installed("sleeve") == 4

func complete() -> bool:
	return pad_location == "foot" and installed("bolt") == 4

func compatible(index: int) -> String:
	if index < 0 or index > 3: return "Aim near one of the four mounting points."
	if slots.sleeve[index] == "": return TITLES.sleeve
	if pad_location != "foot": return "Prepared FA-302 heel pad → rear sole carrier"
	if slots.washer[index] == "": return TITLES.washer
	if slots.bolt[index] == "": return TITLES.bolt
	return "This mounting point is complete."

func reason(kind: String, index: int) -> String:
	if not KINDS.has(kind) or index < 0 or index > 3: return "Choose a pocket item and aim at a mounting point."
	if not ["prep", "foot"].has(pad_location): return "Place the heel pad in the small assembly station first."
	if slots.bolt[index] != "": return "This mounting point is complete. Aim at an unfinished point."
	if slots[kind][index] != "": return "Already installed here. Compatible next components: " + compatible(index)
	if kind != "sleeve" and pad_location != "foot": return "Mount the prepared FA-302 pad on the rear sole carrier first."
	if kind != "sleeve" and slots.sleeve[index] == "": return "Missing sleeve. Compatible next components: " + TITLES.sleeve
	if kind == "bolt" and slots.washer[index] == "": return "Missing washer. Compatible next components: " + TITLES.washer
	return ""

func install(kind: String, index: int) -> Dictionary:
	var error = reason(kind, index)
	if not error.is_empty(): return {"ok": false, "error": error}
	var uid = find_item(kind, "pocket")
	if uid.is_empty(): return {"ok": false, "error": "Your pockets contain no " + TITLES[kind] + ". Collect one from storage or a nearby tray."}
	items[uid].location = "installed"
	slots[kind][index] = uid
	history.append({"action": "install", "kind": kind, "index": index, "uid": uid})
	changed.emit()
	return {"ok": true, "uid": uid}

func mount() -> Dictionary:
	if pad_location != "held": return {"ok": false, "error": "Pick up the prepared pad with E before mounting it."}
	if not prepared(): return {"ok": false, "error": "Fit all four FA-305 compression sleeves before mounting the prepared pad."}
	pad_location = "foot"
	items[pad_id].location = "foot"
	history.append({"action": "mount"})
	changed.emit()
	return {"ok": true}

func undo() -> Dictionary:
	if history.is_empty(): return {"ok": false, "error": "No build actions to undo."}
	var step: Dictionary = history.pop_back()
	if step.action == "mount":
		pad_location = "prep"
		items[pad_id].location = "prep"
	else:
		slots[step.kind][step.index] = ""
		items[step.uid].location = "pocket" if pocket_count() < capacity else "loose"
	changed.emit()
	return {"ok": true, "step": step}

func integrity_errors() -> Array[String]:
	var errors: Array[String] = []
	if items.size() != 13: errors.append("Physical inventory must contain exactly 13 pieces.")
	if pocket_count() > capacity: errors.append("Pocket capacity exceeded.")
	var seen: Array[String] = []
	for kind in KINDS:
		for index in range(4):
			var uid: String = slots[kind][index]
			if uid.is_empty(): continue
			if seen.has(uid): errors.append("Duplicate installed identity: " + uid)
			seen.append(uid)
			if not items.has(uid) or items[uid].kind != kind or items[uid].location != "installed": errors.append("Invalid installed ownership: " + uid)
			if kind == "bolt" and (slots.sleeve[index] == "" or slots.washer[index] == "" or pad_location != "foot"): errors.append("Bolt missing prerequisite.")
	for uid in items:
		if items[uid].location == "installed" and not seen.has(uid): errors.append("Unowned installed item: " + uid)
	if items[pad_id].location != pad_location: errors.append("Pad ownership mismatch.")
	return errors
