extends RefCounted
## Content materialization. Patches replace explicitly named fields, never save data.

static func scenario() -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string("res://assets/heel-pads.json"))

static func definition_data() -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string("res://assets/assembly-definitions.json"))

static func apply_definitions(data: Dictionary, overlay: Dictionary) -> void:
	for section in ["parts","assemblies"]:
		data[section].merge(overlay.get(section,{}),true)
	for id in overlay.get("assembly_patches",{}):
		var patch: Dictionary = overlay.assembly_patches[id]
		var definition: Dictionary = data.assemblies[id]
		_apply_fields(definition,patch)
		for sid in patch.get("slots",{}):
			assert(definition.slots.has(sid),"Patch names unknown slot: "+id+"/"+sid)
			_apply_fields(definition.slots[sid],patch.slots[sid])

static func _apply_fields(destination: Dictionary, patch: Dictionary) -> void:
	for field in patch.get("remove",[]):destination.erase(field)
	for field in patch.get("set",{}):destination[field] = patch.set[field].duplicate(true) if patch.set[field] is Array or patch.set[field] is Dictionary else patch.set[field]

## Presentation adapters for the original recipe format. Kept outside the model
## so the accepted foot content and its save fingerprint remain byte-identical.
static func presentation(data: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	var pad: Dictionary = data.assemblies.get("heel_pad",{})
	if pad.is_empty():return result
	var pad_slots: Dictionary = {}
	var markers: Array = []
	for sid in pad.slots:
		if sid == pad.root_slot:continue
		pad_slots[sid] = {"target_radius":0.15,"ghost_no_depth_test":false,"selected_caption":true,"milestone_feedback":true}
		markers.append({"slot":sid,"parent_completion":"bolt_"+sid.get_slice("_",1)})
	result.heel_pad = {"slots":pad_slots,"markers":markers,"mount_target_offset":[0,-0.085,0]}
	var parent_slots: Dictionary = {}
	var parent_hardware: Array = []
	for sid in data.assemblies.foot.slots:
		if not sid.contains("/"):continue
		var connection: String = sid.get_slice("/",1)
		if not connection.begins_with("washer_") and not connection.begins_with("bolt_"):continue
		var kind: String = data.assemblies.foot.slots[sid].accepts
		if not kind in parent_hardware:parent_hardware.append(kind)
		parent_slots[sid] = {"target_child":sid.get_slice("/",0),"target_slot":"sleeve_"+connection.get_slice("_",1),"target_radius":0.15,"ghost_no_depth_test":false,"selected_caption":true,"milestone_feedback":true}
	result.heel_pad["parent_hardware"] = parent_hardware
	result.foot = {"slots":parent_slots}
	return result

## Compose fresh workshop data without creating nodes, equipment or source meshes.
static func load_workshop() -> Dictionary:
	var config: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/pitch-workshop.json"))
	var data = definition_data()
	apply_definitions(data,JSON.parse_string(FileAccess.get_file_as_string(config.definitions)))
	var foot_kinds: Dictionary = {}
	for part in config.parts:foot_kinds[part.kind] = true
	var leg_content = JSON.parse_string(FileAccess.get_file_as_string("res://assets/leg-prototype-content.json"))
	apply_definitions(data,JSON.parse_string(FileAccess.get_file_as_string("res://assets/leg-prototype-definitions.json")))
	apply_definitions(data,JSON.parse_string(FileAccess.get_file_as_string("res://assets/robot-definitions.json")))
	var extension: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/robot-content.json"))
	leg_content.sources.merge(extension.get("sources",{}),true)
	if extension.has("context_sources"):leg_content.context_sources = extension.context_sources
	leg_content.supports.merge(extension.supports,true)
	for field in ["parts","parents","equipment","robot"]:leg_content[field] = extension[field]
	for field in ["builds","mirror_sources","prepared_branches"]:
		if extension.has(field):leg_content[field] = extension[field]
	config.parts.append_array(leg_content.parts)
	config.builds.append_array(leg_content.get("builds",[]))
	config.parents = leg_content.parents.duplicate(true)
	config.supports = leg_content.supports.duplicate(true)
	# The turning foot fixture stands in for the left foot's bay store.
	config.parent.location = "support:foot_store"
	for parent in config.parents:
		if parent.id == "foot":parent.location = "support:foot_store"
	var homes: Dictionary = preload("res://scripts/leg_bay_layout.gd").layout().parent_homes
	for parent in config.parents:
		if homes.has(parent.id):parent.home = homes[parent.id]

	return {"data":data,"scenario":config,"content":leg_content,"foot_kinds":foot_kinds}
