class_name WorkshopSaveModel
extends RefCounted
## Snapshot boundary for the shared assembly model. Validate before applying.

const ITEM_FIELDS = ["source_id", "kind", "location", "owner", "slot", "pocket"]
const ASSEMBLY_FIELDS = ["definition", "slots", "location", "parent", "parent_slot", "history"]
const STEP_FIELDS = ["action", "assembly", "slot", "uid"]

static func capture(model: AssemblyModel) -> Dictionary:
	return {"items":model.items.duplicate(true), "assemblies":model.assemblies.duplicate(true),
		"pockets":model.pockets.duplicate(), "selected_pocket":model.selected_pocket}

static func _keys_match(value: Dictionary, expected: Array) -> bool:
	if value.size() != expected.size():return false
	for key in expected:
		if not value.has(key):return false
	return true

static func _integer(value: Variant) -> bool:
	return value is int or (value is float and is_finite(value) and value == floor(value) and abs(value) < 2147483648.0)

static func _strings(value: Dictionary, fields: Array) -> bool:
	for field in fields:
		if not value.get(field) is String:return false
	return true

static func validate(data: Variant, baseline: AssemblyModel) -> Array[String]:
	# No model methods may consume untrusted nested values until this entire
	# structural pass succeeds. A candidate keeps failed loads out of live state.
	if not data is Dictionary:return ["Assembly snapshot must be an object."]
	if not _keys_match(data, ["items", "assemblies", "pockets", "selected_pocket"]):return ["Incomplete or unknown assembly snapshot fields."]
	if not data.items is Dictionary or not data.assemblies is Dictionary or not data.pockets is Array:return ["Invalid assembly snapshot containers."]
	if not _keys_match(data.items, baseline.items.keys()) or not _keys_match(data.assemblies, baseline.assemblies.keys()):return ["Snapshot inventory or build identities do not match this workshop."]
	if not _integer(data.selected_pocket) or data.selected_pocket < 0 or data.selected_pocket >= AssemblyModel.POCKET_SLOTS:return ["Invalid selected pocket."]
	if data.pockets.size() != AssemblyModel.POCKET_SLOTS:return ["Invalid pocket count."]
	for kind in data.pockets:
		if not kind is String:return ["Pocket types must be strings."]
		if not kind.is_empty() and not baseline.definitions.parts.has(kind):return ["Unknown pocket type."]
	for uid in baseline.items:
		var item: Variant = data.items[uid]
		if not item is Dictionary or not _keys_match(item, ITEM_FIELDS):return ["Invalid item record: " + uid]
		if not _strings(item, ["source_id", "kind", "location", "owner", "slot"]) or not _integer(item.pocket):return ["Invalid item fields: " + uid]
		if item.source_id != baseline.items[uid].source_id or item.kind != baseline.items[uid].kind:return ["Changed physical identity or component type: " + uid]
		if item.location not in ["bin", "pocket", "held", "loose", "installed"] and not item.location.begins_with("support:"):return ["Unknown item location: " + uid]
		if item.location == "pocket":
			if item.pocket < 0 or item.pocket >= AssemblyModel.POCKET_SLOTS:return ["Invalid item pocket: " + uid]
		elif item.pocket != -1:return ["Non-pocket item retains a pocket: " + uid]
		if item.location != "installed" and (not item.owner.is_empty() or not item.slot.is_empty()):return ["Uninstalled item retains ownership: " + uid]
		if item.location in ["held", "loose"] and baseline.definitions.parts[item.kind].carry_class == "pocket":return ["Pocket-sized item has an impossible location: " + uid]
	for id in baseline.assemblies:
		var assembly: Variant = data.assemblies[id]
		var initial: Dictionary = baseline.assemblies[id]
		if not assembly is Dictionary or not _keys_match(assembly, ASSEMBLY_FIELDS):return ["Invalid build record: " + id]
		if not _strings(assembly, ["definition", "location", "parent", "parent_slot"]) or not assembly.slots is Dictionary or not assembly.history is Array:return ["Invalid build fields: " + id]
		if assembly.definition != initial.definition or not _keys_match(assembly.slots, initial.slots.keys()):return ["Changed build definition or slots: " + id]
		if assembly.location not in ["loose", "held", "fixture", "parent"] and not assembly.location.begins_with("support:") and not (assembly.location.begins_with("station:") and assembly.location.length() > 8):return ["Unknown build location: " + id]
		if initial.location == "fixture":
			if assembly.location != "fixture" or not assembly.parent.is_empty() or not assembly.parent_slot.is_empty():return ["Fixed build moved or mounted: " + id]
		elif assembly.location == "fixture":return ["Movable build became a fixture: " + id]
		if assembly.parent.is_empty():
			if not assembly.parent_slot.is_empty() or assembly.location == "parent":return ["Incomplete child ownership: " + id]
		elif not baseline.assemblies.has(assembly.parent) or assembly.parent_slot.is_empty() or assembly.location != "parent":return ["Invalid child ownership: " + id]
		for sid in assembly.slots:
			var occupant: Variant = assembly.slots[sid]
			if not occupant is String:return ["Slot occupant must be an identity: " + id]
			if not initial.slots[sid].is_empty() and occupant != initial.slots[sid]:return ["Changed fixed root occupant: " + id]
			if occupant.is_empty():continue
			var slot: Dictionary = baseline.slot_definition(id, sid)
			if slot.has("assembly"):
				if not baseline.assemblies.has(occupant):return ["Unknown child occupant: " + id]
			elif not baseline.items.has(occupant):return ["Unknown physical occupant: " + id]
		if assembly.history.size() > assembly.slots.size():return ["Too many undo actions: " + id]
		for step in assembly.history:
			if not step is Dictionary or not _keys_match(step, STEP_FIELDS) or not _strings(step, STEP_FIELDS):return ["Invalid undo record: " + id]
			if step.assembly != id or not assembly.slots.has(step.slot):return ["Undo record targets an unknown build or slot: " + id]
			var slot: Dictionary = baseline.slot_definition(id, step.slot)
			if step.action != ("mount" if slot.has("assembly") else "install"):return ["Undo action disagrees with its slot: " + id]
			if step.uid.is_empty() or assembly.slots[step.slot] != step.uid:return ["Undo record disagrees with installed occupant: " + id]
	var candidate = AssemblyModel.new()
	candidate.definitions = baseline.definitions.duplicate(true)
	candidate.support_definitions = baseline.support_definitions.duplicate(true)
	candidate.expected_ids = baseline.expected_ids.duplicate()
	# Keep source ordering stable, including for JSON readers with reordered keys.
	candidate.items = baseline.items.duplicate(true)
	candidate.assemblies = baseline.assemblies.duplicate(true)
	apply(data, candidate)
	var errors: Array[String] = candidate.integrity_errors()
	for id in candidate.assemblies:
		var assembly: Dictionary = candidate.assemblies[id]
		var replay: Dictionary = baseline.assemblies[id].slots.duplicate()
		for step in assembly.history:
			if not replay[step.slot].is_empty():
				errors.append("Duplicate or fixed-root undo action: " + id)
				continue
			for required in candidate.slot_definition(id, step.slot).get("requires", []):
				if replay[required].is_empty():errors.append("Undo order violates prerequisites: " + id)
			replay[step.slot] = step.uid
		if replay != assembly.slots:errors.append("Undo history does not cover every installed connection: " + id)
	return errors

static func apply(data: Dictionary, model: AssemblyModel) -> void:
	# The coordinator validates the complete snapshot before calling this method.
	for uid in model.items:
		model.items[uid] = data.items[uid].duplicate(true)
		model.items[uid].pocket = int(model.items[uid].pocket)
	for id in model.assemblies:model.assemblies[id] = data.assemblies[id].duplicate(true)
	model.pockets.assign(data.pockets)
	model.selected_pocket = int(data.selected_pocket)
