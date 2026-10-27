class_name HeelAssemblyState
extends RefCounted
## Desktop pad view of shared assembly state. Construction rules live in data/model.
signal changed
const KINDS = ["sleeve", "washer", "bolt"]
const TITLES = {"sleeve":"FA-305 · Compression sleeve","washer":"W-24 · M24 washer","bolt":"H-24120 · Mounting bolt","pad":"FA-302 · Heel pad"}
var model: AssemblyModel
var build_id: String = "pad_1"
var items: Dictionary:
	get:return model.items
var pad_id: String:
	get:return model.assemblies[build_id].slots[model.definitions.assemblies[model.assemblies[build_id].definition].root_slot]
var pad_location: String:
	get:
		var location: String = model.assemblies[build_id].location
		return "prep" if location.begins_with("station:") else ("foot" if location == "parent" else location)
var station_id: String:
	get:return model.assemblies[build_id].location.trim_prefix("station:")
var mount_slot: String:
	get:return model.assemblies[build_id].parent_slot
var parent_id: String:
	get:return model.assemblies[build_id].parent
var history: Array:
	get:return model.assemblies[parent_id if not parent_id.is_empty() else build_id].history
var slots: Dictionary:
	get:
		var result = {}
		for kind in KINDS:
			result[kind] = []
			for i in range(4):
				var owner = build_id if kind == "sleeve" else parent_id
				var sid = "%s_%d" % [kind,i] if kind == "sleeve" else "%s/%s_%d" % [mount_slot,kind,i]
				result[kind].append(model.assemblies[owner].slots.get(sid,"") if model.assemblies.has(owner) else "")
		return result

# Standalone compatibility for historical state tests; production loads Content.
static func scenario() -> Dictionary:
	return preload("res://scripts/workshop_content.gd").scenario()

static func definition_data() -> Dictionary:
	return preload("res://scripts/workshop_content.gd").definition_data()

func bind(shared: AssemblyModel, id: String) -> void:
	model = shared
	build_id = id

## Configures a standalone one-pad foot from `config` parts, for model tests.
func configure(config: Dictionary) -> void:
	var shared = AssemblyModel.new()
	var setup = scenario()
	setup.parts = config.parts
	setup.builds.resize(1)
	setup.mounts.resize(1)
	var data = definition_data()
	for sid in data.assemblies.foot.slots.keys():
		if sid.begins_with("heel_2"):data.assemblies.foot.slots.erase(sid)
	data.assemblies.foot.milestones.complete = data.assemblies.foot.slots.keys()
	data.assemblies.foot.milestones.erase("heel_2_secured")
	data.assemblies.foot.manual.resize(2)
	data.assemblies.foot.manual[0].slots = data.assemblies.foot.slots.keys()
	var errors = shared.configure(data,setup)
	assert(errors.is_empty(),str(errors))
	bind(shared,"pad_1")

func count_at(kind: String, location: String) -> int:return model.count_at(kind,location)
func pocket_count() -> int:return model.pocket_count()
func find_item(kind: String, location: String) -> String:return model.find_item(kind,location)
func take(kind: String, location: String = "bin", uid: String = "") -> String:return model.transfer(kind,location,"pocket",uid)
func drop(kind: String) -> String:return model.transfer(kind,"pocket","bin")
func return_to_bin(kind: String) -> String:return model.transfer(kind,"pocket","bin")
func move_pad(where: String) -> String:return model.move_assembly(build_id,"station:prep" if where == "prep" else where)
func installed(kind: String) -> int:return slots[kind].size()-slots[kind].count("")
func prepared() -> bool:return model.milestone(build_id,"prepared")
func complete() -> bool:return not mount_slot.is_empty() and model.milestone(parent_id,mount_slot+"_secured")
func compatible(index: int) -> String:
	for kind in KINDS:
		if slots[kind][index].is_empty():return TITLES[kind]
	return "This mounting point is complete."
func reason(kind: String, index: int) -> String:
	if not KINDS.has(kind) or index < 0 or index >= slots.sleeve.size():return "Choose hardware and aim at a connection."
	if not ["prep","foot"].has(pad_location):return "Suspend this build at a preparation station first."
	if kind != "sleeve" and mount_slot.is_empty():return "Mount the prepared pad on the rear sole carrier first."
	var owner = build_id if kind == "sleeve" else parent_id
	var sid = "%s_%d" % [kind,index] if kind == "sleeve" else "%s/%s_%d" % [mount_slot,kind,index]
	return model.placement_error(owner,sid,find_item(kind,"pocket"))
func install(kind: String, index: int) -> Dictionary:
	var error = reason(kind,index)
	if not error.is_empty():return {"ok":false,"error":error}
	var owner = build_id if kind == "sleeve" else parent_id
	var sid = "%s_%d" % [kind,index] if kind == "sleeve" else "%s/%s_%d" % [mount_slot,kind,index]
	return model.install(owner,sid,find_item(kind,"pocket"))
func mount(destination: String = "heel_1", owner: String = "foot") -> Dictionary:return model.install(owner,destination,build_id)
func undo() -> Dictionary:return model.undo(parent_id if not parent_id.is_empty() else build_id,"station:prep")
func integrity_errors() -> Array[String]:return model.integrity_errors()
