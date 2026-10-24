extends RefCounted
## M3 supplies only the internally complete foot. All structural/hip work is real.
const Codec = preload("res://scripts/pose_codec.gd")
var game: Node
func _init(workshop: Node) -> void:game = workshop

func position_stock() -> void:
	var index = 0
	for kind in game.bins:
		var node: Node3D = game.bins[kind]
		if game.model.count_at(kind,"bin") == 0:node.hide();continue
		if node.get_parent()!=game:node.reparent(game)
		# A ground-height drawer wall away from the fixture's extraction aisles.
		var row = index/7
		node.global_position = Vector3(-7.6+(index%7)*.9,.7,12.6+row*2.3)
		node.rotation = Vector3.ZERO
		game.box(game.leg_layout,Vector3(node.global_position.x,.245,node.global_position.z),Vector3(.8,.49,.55),game.material(Color("506971")),true)
		index += 1

func filter_candidates(candidates: Array[Dictionary]) -> Array[Dictionary]:
	return candidates.filter(func(entry):return entry.type == "loose" or (entry.type == "bin" and game.model.count_at(entry.kind,"bin") > 0))

func undo_error(owner: String) -> String:
	return "The prepared foot stays assembled in M3." if owner in ["foot","pad_1","pad_2","pitch"] else ""

func capture() -> Dictionary:return {"version":1,"trial":"m3"}

func validate(data: Variant, candidate: AssemblyModel, initial: Dictionary, world: Dictionary) -> Array[String]:
	if not Codec.same_keys(data,["version","trial"]) or not Codec.number(data.version) or data.version != 1 or not data.trial is String or data.trial != "m3":return ["Invalid M3 scenario state."]
	for owner in ["foot","pad_1","pad_2","pitch"]:
		if candidate.assemblies[owner].slots != initial.model.assemblies[owner].slots:return ["Prepared foot construction changed."]
	if not Codec.to_pose(world.fixtures.pelvis).is_equal_approx(Codec.to_pose(initial.world.fixtures.pelvis)):return ["Pelvis must remain anchored to its gantry."]
	return []
