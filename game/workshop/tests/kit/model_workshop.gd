extends Node3D
## Real model and authored content; presentation-only staging collaborators are inert.
var model = AssemblyModel.new()
var loaded: Dictionary
var leg_content: Dictionary
var runtime: RefCounted
var automation: RefCounted
var components = NullComponents.new()
var active_build = ""
var paused = false
var hud: Node
var equipment = EquipmentRegistry.new()
var zones: RefCounted
class NullComponents extends RefCounted:
	func sync(_owner: String) -> void:pass
class ModelRuntime extends RefCounted:
	var model: AssemblyModel
	func _init(value: AssemblyModel) -> void:model=value
	func definition(owner: String) -> Dictionary:return model.definitions.assemblies[model.assemblies[owner].definition]
	func mount(_owner: String, _slot: String, _child: String) -> void:pass
class Stations extends RefCounted:
	var model: AssemblyModel
	func _init(value: AssemblyModel) -> void:model=value
	func suspend_at_station(owner: String, id: String) -> String:return model.move_assembly(owner,"station:"+id)
func setup() -> Array[String]:
	loaded=preload("res://scripts/workshop_content.gd").load_workshop()
	leg_content=loaded.content
	var errors=model.configure(loaded.data,loaded.scenario)
	runtime=ModelRuntime.new(model);automation=Stations.new(model)
	zones=preload("res://scripts/zone_register.gd").new(preload("res://scripts/leg_bay_layout.gd").layout().workshop.zones)
	return errors
func refresh_assembly_collision(_owner: String) -> void:pass
