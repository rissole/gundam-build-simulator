extends "res://tests/kit/model_workshop.gd"
## Only selected authored source meshes and their production collision projection.
var source: Dictionary={}
var primitives=preload("res://scripts/primitives.gd").new()
func material(color: Color, metal: float = 0.0) -> Material:return primitives.material(color,metal)
func _mesh(uid: String) -> MeshInstance3D:
	var mesh=MeshInstance3D.new();mesh.mesh=source[uid].mesh;mesh.set_meta("source_uid",uid);return mesh
func prepare_sources(owners: Array) -> Array[String]:
	var errors=setup()
	if not errors.is_empty():return errors
	var selected: Dictionary={}
	for owner in owners:
		var definition: Dictionary=runtime.definition(owner)
		for uid in definition.get("context_sources",[]):selected[uid]=leg_content.sources[uid]
		for slot in definition.slots.values():
			var uid: String=slot.get("pose_source","")
			if leg_content.sources.has(uid):selected[uid]=leg_content.sources[uid]
	LegSourceGeometry.add_sources(source,{"sources":selected})
	runtime=AssemblyRuntime.new(model,source)
	for owner in owners:
		var body=StaticBody3D.new();body.collision_layer=4;add_child(body);runtime.register_node(owner,body)
	preload("res://scripts/workshop_world.gd").new(self).make_leg_context()
	return []
