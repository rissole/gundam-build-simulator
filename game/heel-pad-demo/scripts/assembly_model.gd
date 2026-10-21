class_name AssemblyModel
extends RefCounted
## Input-independent ownership, compatibility, prerequisites and build history.
signal changed
var definitions: Dictionary = {}
var items: Dictionary = {}
var assemblies: Dictionary = {}
const POCKET_SLOTS = 10
const STACK_LIMIT = 20
var pockets: Array[String] = []
var selected_pocket: int = 0
var expected_ids: Array = []

func configure(data: Dictionary, scenario: Dictionary) -> Array[String]:
	var errors = validate_definitions(data)
	if not errors.is_empty(): return errors
	if scenario.get("version",0) != 1 or not scenario.has("builds") or not scenario.has("parent") or not scenario.has("parts"):
		return ["Unsupported or incomplete scenario."]
	var ids: Array = []
	var roots: Array = []
	var physical: Dictionary = {}
	for part in scenario.parts:
		if physical.has(part.instance_id):errors.append("Duplicate source identity: "+part.instance_id)
		physical[part.instance_id] = part
		if not data.parts.has(part.kind):errors.append("Unknown part type: "+part.kind)
		elif part.get("part_id",data.parts[part.kind].family) != data.parts[part.kind].family:errors.append("Part family mismatch: "+part.instance_id)
	for build in scenario.builds:
		if ids.has(build.id):errors.append("Duplicate assembly identity: "+build.id)
		ids.append(build.id)
		if not data.assemblies.has(build.definition):errors.append("Unknown build definition: "+build.definition);continue
		var definition: Dictionary = data.assemblies[build.definition]
		var root: String = definition.get("root_slot","")
		if not definition.slots.has(root):errors.append("Missing root slot: "+build.definition);continue
		if not physical.has(build.base):errors.append("Missing root part: "+build.base);continue
		if roots.has(build.base):errors.append("Duplicate root ownership: "+build.base)
		roots.append(build.base)
		if physical[build.base].kind != definition.slots[root].get("accepts",""):errors.append("Wrong root part: "+build.base)
	if ids.has(scenario.parent.id) or not data.assemblies.has(scenario.parent.definition):errors.append("Invalid parent assembly.")
	if not errors.is_empty():return errors
	definitions = data.duplicate(true)
	pockets.assign(["","","","","","","","","",""])
	selected_pocket = 0
	items.clear()
	assemblies.clear()
	expected_ids.clear()
	for part in scenario.parts:
		items[part.instance_id] = {"kind":part.kind,"location":"bin","owner":"","slot":"","pocket":-1}
	for build in scenario.builds:
		_add_assembly(build.id,build.definition)
		var root: String = definitions.assemblies[build.definition].root_slot
		_set_part(build.base,build.id,root)
	_add_assembly(scenario.parent.id,scenario.parent.definition)
	assemblies[scenario.parent.id].location = "fixture"
	expected_ids = items.keys()
	errors.append_array(integrity_errors())
	return errors

func _add_assembly(id: String, definition: String) -> void:
	var slots: Dictionary = {}
	for slot in definitions.assemblies[definition].slots: slots[slot] = ""
	assemblies[id] = {"definition":definition,"slots":slots,"location":"loose","parent":"","parent_slot":"","history":[]}

static func validate_definitions(data: Dictionary) -> Array[String]:
	var errors: Array[String] = []
	if data.get("version",0) != 1 or not data.has("parts") or not data.has("assemblies"):
		return ["Unsupported or incomplete assembly definition document."]
	for id in data.assemblies:
		var definition: Dictionary = data.assemblies[id]
		var slots: Dictionary = definition.get("slots",{})
		if slots.is_empty(): errors.append("Assembly has no slots: "+id)
		if definition.has("root_slot"):
			var root: String = definition.root_slot
			if not slots.has(root) or slots[root].has("assembly") or not slots[root].get("requires",[]).is_empty():errors.append("Root must be an independent physical part: "+id)
		for sid in slots:
			var s: Dictionary = slots[sid]
			if s.has("assembly"):
				if not data.assemblies.has(s.assembly): errors.append("Unknown child definition: "+sid)
				elif not data.assemblies[s.assembly].get("milestones",{}).has(s.get("milestone","")): errors.append("Unknown child milestone: "+sid)
			elif not data.parts.has(s.get("accepts","")): errors.append("Unknown accepted part: "+sid)
			for required in s.get("requires",[]):
				if not slots.has(required): errors.append("Unknown prerequisite: "+required)
		for group in definition.get("milestones",{}).values():
			for sid in group:
				if not slots.has(sid): errors.append("Unknown milestone slot: "+sid)
		for step in definition.get("manual",[]):
			for sid in step.get("slots",[]):
				if not slots.has(sid): errors.append("Unknown manual slot: "+sid)
		var resolved: Array = []
		for pass_index in range(slots.size()):
			for sid in slots:
				if not resolved.has(sid) and slots[sid].get("requires",[]).all(func(r):return resolved.has(r)): resolved.append(sid)
		if resolved.size() != slots.size(): errors.append("Cyclic or unreachable prerequisites: "+id)
	# Child definitions must also form an acyclic ownership hierarchy.
	var resolved_defs: Array = []
	for pass_index in range(data.assemblies.size()):
		for id in data.assemblies:
			if resolved_defs.has(id): continue
			var ready = true
			for slot in data.assemblies[id].get("slots",{}).values():
				if slot.has("assembly") and not resolved_defs.has(slot.assembly): ready = false
			if ready: resolved_defs.append(id)
	if resolved_defs.size() != data.assemblies.size(): errors.append("Cyclic assembly definitions.")
	return errors

func slot_definition(assembly: String, slot: String) -> Dictionary:
	if not assemblies.has(assembly): return {}
	return definitions.assemblies[assemblies[assembly].definition].slots.get(slot,{})

func milestone(assembly: String, name: String) -> bool:
	if not assemblies.has(assembly): return false
	var a: Dictionary = assemblies[assembly]
	var required: Array = definitions.assemblies[a.definition].get("milestones",{}).get(name,[])
	return not required.is_empty() and required.all(func(s):return not a.slots[s].is_empty())

func count_at(kind: String, location: String) -> int:
	var n = 0
	for item in items.values():
		if item.kind == kind and item.location == location:n += 1
	return n

func pocket_count() -> int:
	var n = 0
	for item in items.values():
		if item.location == "pocket":n += 1
	return n

func find_item(kind: String, location: String) -> String:
	for uid in items:
		if items[uid].kind == kind and items[uid].location == location:return uid
	return ""

func selected_kind() -> String:
	return pockets[selected_pocket]

func select_pocket(index: int) -> void:
	if index < 0 or index >= POCKET_SLOTS:return
	selected_pocket = index
	changed.emit()

func pocket_size(index: int) -> int:
	var count = 0
	for item in items.values():
		if item.location == "pocket" and item.pocket == index:count += 1
	return count

func pocket_for(kind: String) -> int:
	return pockets.find(kind) if not kind.is_empty() else -1

func _available_pocket(kind: String) -> int:
	var existing = pocket_for(kind)
	if existing >= 0:return existing if pocket_size(existing) < STACK_LIMIT else -1
	return pockets.find("")

func _return_pocket(index: int) -> int:
	var returned = 0
	for item in items.values():
		if item.location == "pocket" and item.pocket == index:
			item.location = "bin"
			item.pocket = -1
			returned += 1
	pockets[index] = ""
	return returned

func clear_pocket(index: int = -1) -> int:
	if index == -1:index = selected_pocket
	if index < 0 or index >= POCKET_SLOTS:return 0
	var returned = _return_pocket(index)
	changed.emit()
	return returned

func stock_pocket(kind: String) -> Dictionary:
	if not definitions.parts.has(kind) or definitions.parts[kind].carry_class != "pocket":return {"ok":false,"error":"This component is carried from a shelf."}
	var index = pocket_for(kind)
	if index >= 0 and pocket_size(index) == STACK_LIMIT:
		selected_pocket = index
		changed.emit()
		return {"ok":true,"index":index,"taken":0,"returned":0}
	# Empty stock must never evict an unrelated stack.
	if find_item(kind,"bin").is_empty():return {"ok":false,"error":"This drawer is empty."}
	if index < 0:index = pockets.find("")
	var returned = 0
	if index < 0:
		index = selected_pocket
		returned = _return_pocket(index)
	pockets[index] = kind
	selected_pocket = index
	var taken = 0
	var space = STACK_LIMIT-pocket_size(index)
	for item in items.values():
		if item.kind != kind or item.location != "bin":continue
		item.location = "pocket"
		item.pocket = index
		taken += 1
		if taken == space:break
	changed.emit()
	return {"ok":true,"index":index,"taken":taken,"returned":returned}

func _remove_from_pocket(uid: String) -> void:
	var index: int = items[uid].get("pocket",-1)
	items[uid].pocket = -1
	if index >= 0 and not items.values().any(func(i):return i.location == "pocket" and i.pocket == index):pockets[index] = ""

func transfer(kind: String, from: String, to: String, uid: String = "") -> String:
	# Single-piece operation for model clients; desktop drawers use stock_pocket.
	if from not in ["bin","pocket"] or to not in ["bin","pocket"] or from == to:return ""
	if uid.is_empty():uid = find_item(kind,from)
	if not items.has(uid) or items[uid].kind != kind or items[uid].location != from:return ""
	if definitions.parts[kind].carry_class != "pocket":return ""
	if to == "pocket":
		var index = _available_pocket(kind)
		if index < 0:return ""
		pockets[index] = kind
		items[uid].pocket = index
		selected_pocket = index
	else:_remove_from_pocket(uid)
	items[uid].location = to
	changed.emit()
	return uid

func held_item() -> String:
	for uid in items:
		if items[uid].location == "held":return uid
	return ""

func hands_occupied() -> bool:
	return not held_item().is_empty() or assemblies.values().any(func(a):return a.location == "held")

func carry_item(uid: String) -> String:
	if not items.has(uid) or items[uid].location not in ["bin","loose"]:return "Choose an available component."
	if definitions.parts[items[uid].kind].carry_class == "pocket":return "Collect this small piece into your pockets."
	if hands_occupied():return "Both hands are occupied. Set down the carried component first."
	items[uid].location = "held"
	changed.emit()
	return ""

func release_item(destination: String = "loose") -> String:
	var uid = held_item()
	if uid.is_empty() or destination not in ["bin","loose"]:return ""
	items[uid].location = destination
	changed.emit()
	return uid

func move_assembly(id: String, location: String) -> String:
	if not assemblies.has(id):return "Unknown build."
	if location not in ["held","loose"] and not location.begins_with("station:"):return "Invalid assembly destination."
	if assemblies[id].location == "fixture":return "This fixture stays at its work station."
	if not assemblies[id].parent.is_empty():return "This assembly is mounted. Undo its parent installation first."
	if location == "held":
		if not held_item().is_empty():return "Both hands are occupied. Set down the carried component first."
		for other in assemblies:
			if other != id and assemblies[other].location == "held":return "Both hands are occupied. Set down the carried assembly first."
	if location.begins_with("station:"):
		for other in assemblies:
			if other != id and assemblies[other].location == location:return "This station is occupied. Move its assembly first."
	assemblies[id].location = location
	changed.emit()
	return ""

func placement_error(assembly: String, slot: String, uid: String) -> String:
	var s = slot_definition(assembly,slot)
	if s.is_empty():return "Unknown attachment slot."
	var a: Dictionary = assemblies[assembly]
	var locations: Array = definitions.assemblies[a.definition].get("work_locations",[])
	var location: String = "station" if a.location.begins_with("station:") else a.location
	if not a.parent.is_empty():return "This child is installed. Undo its parent installation before changing its internals."
	if not locations.is_empty() and not locations.has(location):return "Suspend this build at a preparation station first."
	if not a.slots[slot].is_empty():return "Already installed here. Choose an unfinished connection."
	for required in s.get("requires",[]):
		if a.slots[required].is_empty():
			var dependency = slot_definition(assembly,required)
			return "Missing prerequisite: "+(dependency.get("label","prepared assembly on the carrier") if dependency.has("assembly") else definitions.parts[dependency.accepts].title)
	if s.has("assembly"):
		if not assemblies.has(uid) or assemblies[uid].definition != s.assembly:return "Requires a compatible completed subassembly."
		if not assemblies[uid].parent.is_empty():return "That assembly already has a parent."
		if assemblies[uid].location != "held":return "Pick up the prepared assembly before mounting it."
		if not milestone(uid,s.milestone):return "Prepare this assembly first: "+s.milestone
	else:
		if not items.has(uid) or items[uid].kind != s.accepts:return "Compatible next component: "+definitions.parts[s.accepts].title
		var required_location = "pocket" if definitions.parts[s.accepts].carry_class == "pocket" else "held"
		if items[uid].location != required_location:return ("Collect " if required_location == "pocket" else "Carry ")+definitions.parts[s.accepts].title+" first."
	return ""

func install(assembly: String, slot: String, uid: String) -> Dictionary:
	var error = placement_error(assembly,slot,uid)
	if not error.is_empty():return {"ok":false,"error":error}
	var child = slot_definition(assembly,slot).has("assembly")
	if child:
		assemblies[assembly].slots[slot] = uid
		assemblies[uid].parent = assembly
		assemblies[uid].parent_slot = slot
		assemblies[uid].location = "parent"
	else:_set_part(uid,assembly,slot)
	var step = {"action":"mount" if child else "install","assembly":assembly,"slot":slot,"uid":uid}
	assemblies[assembly].history.append(step)
	changed.emit()
	return {"ok":true,"uid":uid,"step":step}

func _set_part(uid: String, assembly: String, slot: String) -> void:
	assemblies[assembly].slots[slot] = uid
	_remove_from_pocket(uid)
	items[uid].location = "installed"
	items[uid].owner = assembly
	items[uid].slot = slot

func undo(assembly: String, child_destination: String = "loose") -> Dictionary:
	if not assemblies.has(assembly):return {"ok":false,"error":"Select a build manual first."}
	var a: Dictionary = assemblies[assembly]
	if not a.parent.is_empty():return {"ok":false,"error":"Open the parent manual and undo installation before changing this child."}
	if a.history.is_empty():return {"ok":false,"error":"No build actions to undo in this manual."}
	var step: Dictionary = a.history.back()
	if step.action == "mount" and child_destination != "loose" and not child_destination.begins_with("station:"):
		return {"ok":false,"error":"Choose a free output station or loose destination."}
	if step.action == "mount" and child_destination.begins_with("station:"):
		for other in assemblies.values():
			if other.location == child_destination:return {"ok":false,"error":"Output station occupied. Clear it before undoing the mount."}
	a.history.pop_back()
	a.slots[step.slot] = ""
	if step.action == "mount":
		assemblies[step.uid].parent = ""
		assemblies[step.uid].parent_slot = ""
		assemblies[step.uid].location = child_destination
	else:
		var item: Dictionary = items[step.uid]
		if definitions.parts[item.kind].carry_class == "pocket":
			var index = _available_pocket(item.kind)
			item.location = "bin" if index < 0 else "pocket"
			item.pocket = index
			if index >= 0:pockets[index] = item.kind
		else:item.location = "loose"
		items[step.uid].owner = ""
		items[step.uid].slot = ""
	changed.emit()
	return {"ok":true,"step":step}

func integrity_errors() -> Array[String]:
	var errors: Array[String] = []
	if items.keys() != expected_ids and not expected_ids.is_empty():errors.append("Source identities changed.")
	if pockets.size() != POCKET_SLOTS:errors.append("Invalid pocket count.")
	var pocket_kinds: Array = []
	for index in range(pockets.size()):
		var kind: String = pockets[index]
		var count = pocket_size(index)
		if count > STACK_LIMIT:errors.append("Pocket stack exceeded.")
		if kind.is_empty():
			if count > 0:errors.append("Unlabelled pocket contents.")
			continue
		if pocket_kinds.has(kind):errors.append("Duplicate pocket type.")
		pocket_kinds.append(kind)
		if count == 0 or definitions.parts[kind].carry_class != "pocket":errors.append("Invalid pocket type or empty assigned stack.")
	for item in items.values():
		if item.location == "pocket":
			if item.pocket < 0 or item.pocket >= pockets.size() or pockets[item.pocket] != item.kind:errors.append("Pocket ownership mismatch.")
		elif item.get("pocket",-1) != -1:errors.append("Non-pocket item retains a pocket.")
	var seen: Array = []
	var children: Array = []
	var held = 0
	for item in items.values():
		if item.location == "held":held += 1
	var stations: Array = []
	for id in assemblies:
		var a: Dictionary = assemblies[id]
		if a.location == "held":held += 1
		if a.location.begins_with("station:"):
			if stations.has(a.location):errors.append("Two builds occupy a station.")
			stations.append(a.location)
		for sid in a.slots:
			var uid: String = a.slots[sid]
			if uid.is_empty():continue
			var d = slot_definition(id,sid)
			for required in d.get("requires",[]):
				if a.slots[required].is_empty():errors.append("Missing dependency: "+sid)
			if d.has("assembly"):
				if children.has(uid):errors.append("Duplicate child ownership.")
				children.append(uid)
				if not assemblies.has(uid):errors.append("Unknown child.");continue
				if assemblies[uid].parent != id or assemblies[uid].parent_slot != sid or assemblies[uid].location != "parent":errors.append("Child ownership mismatch.")
				if assemblies[uid].definition != d.assembly or not milestone(uid,d.milestone):errors.append("Invalid child assembly.")
			else:
				if seen.has(uid):errors.append("Duplicate physical identity: "+uid)
				seen.append(uid)
				if not items.has(uid):errors.append("Unknown item: "+uid);continue
				if items[uid].owner != id or items[uid].slot != sid or items[uid].location != "installed" or items[uid].kind != d.accepts:errors.append("Invalid slot occupant: "+uid)
	for uid in items:
		if items[uid].location == "installed" and not seen.has(uid):errors.append("Unowned installed piece: "+uid)
	for id in assemblies:
		if not assemblies[id].parent.is_empty() and not children.has(id):errors.append("Unowned child: "+id)
	if held > 1:errors.append("Hand capacity exceeded.")
	return errors
