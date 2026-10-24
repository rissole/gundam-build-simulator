extends RefCounted
## M3 supplies only the internally complete foot. All structural/hip work is real.
const Codec = preload("res://scripts/pose_codec.gd")
const PREPARED = ["foot","pad_1","pad_2","pitch","right_foot","right_pad_1","right_pad_2","right_pitch"]
var game: Node
func _init(workshop: Node) -> void:game = workshop

func position_stock() -> void:
	var index = 0
	var grid: Dictionary = preload("res://scripts/leg_bay_layout.gd").layout().workshop.stock_grid
	for kind in game.bins:
		var node: Node3D = game.bins[kind]
		if game.model.count_at(kind,"bin") == 0:node.hide();continue
		if node.get_parent()!=game:node.reparent(game)
		# A ground-height drawer wall away from the fixture's extraction aisles.
		var row = index/int(grid.columns)
		node.global_position = AssemblyRuntime.vec(grid.origin)+Vector3((index%int(grid.columns))*grid.spacing[0],0,row*grid.spacing[1])
		node.rotation = Vector3.ZERO
		game.box(game.leg_layout,Vector3(node.global_position.x,.245,node.global_position.z),Vector3(.8,.49,.55),game.material(Color("506971")),true)
		index += 1

func filter_candidates(candidates: Array[Dictionary]) -> Array[Dictionary]:
	return candidates.filter(func(entry):return entry.type == "loose" or (entry.type == "bin" and game.model.count_at(entry.kind,"bin") > 0))

func undo_error(owner: String) -> String:
	return "The prepared foot stays assembled in M3." if owner in PREPARED else ""

func capture() -> Dictionary:return {"version":1,"trial":"m3"}

func validate(data: Variant, candidate: AssemblyModel, initial: Dictionary, world: Dictionary) -> Array[String]:
	if not Codec.same_keys(data,["version","trial"]) or not Codec.number(data.version) or data.version != 1 or not data.trial is String or data.trial != "m3":return ["Invalid M3 scenario state."]
	for owner in PREPARED:
		if candidate.assemblies[owner].slots != initial.model.assemblies[owner].slots:return ["Prepared foot construction changed."]
	return []
