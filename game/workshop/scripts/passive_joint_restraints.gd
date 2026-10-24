extends "res://scripts/equipment.gd"
## Captive service braces lock unpowered joints as their connections are secured.
## They travel on the assembly; holder release does not release these braces.
var fixtures: Array[Dictionary] = []

func setup(workshop: Node) -> void:
	game = workshop;equipment_id = "joint_restraints"
	var steel = game.material(Color("506971"),.45)
	var yellow = game.material(Color("e8b46b"),.3)
	for spec in preload("res://scripts/leg_bay_layout.gd").layout().restraints:
		var root = Node3D.new();root.name = spec.id;game.runtime.node("left_leg").add_child(root)
		var bodies: Array = []
		for piece in spec.pieces:
			var visual = game.box(root,AssemblyRuntime.vec(piece.position),AssemblyRuntime.vec(piece.size),yellow if piece.get("contact",false) else steel,true)
			visual.name = piece.id
			bodies.append(root.get_child(root.get_child_count()-1))
		fixtures.append({"id":spec.id,"milestone":spec.milestone,"node":root,"bodies":bodies})
	game.model.changed.connect(sync)
	sync()

func sync() -> void:
	for fixture in fixtures:
		var engaged = game.model.milestone("left_leg",fixture.milestone)
		fixture.node.visible = engaged
		for body in fixture.bodies:body.collision_layer = 1 if engaged else 0
	sync_pose()

func sync_pose() -> void:
	for fixture in fixtures:
		for body in fixture.bodies:
			body.force_update_transform()
			PhysicsServer3D.body_set_state(body.get_rid(),PhysicsServer3D.BODY_STATE_TRANSFORM,body.global_transform)

func capture() -> Dictionary:return {}
func validate(data: Variant, _candidate: AssemblyModel = null, _world: Dictionary = {}) -> Array[String]:
	if not data is Dictionary or not data.is_empty():return ["Passive restraint state must derive from its secured connections."]
	return []
func apply(_data: Dictionary) -> void:sync()
