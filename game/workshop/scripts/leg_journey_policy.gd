extends RefCounted
## M3 supplies only the internally complete feet. All structural/hip work is real.
## The robot game leaves the left foot to the player; only the right is supplied.
const Codec = preload("res://scripts/pose_codec.gd")
const LEFT_FOOT = ["foot","pad_1","pad_2","pitch"]
const RIGHT_FOOT = ["right_foot","right_pad_1","right_pad_2","right_pitch"]
var game: Node
var prepared: Array = []
func _init(workshop: Node) -> void:
	game = workshop
	prepared = (LEFT_FOOT if game.profile.get("prepared_foot",true) else [])+RIGHT_FOOT

func position_stock() -> void:
	var index = 0
	var grid: Dictionary = preload("res://scripts/leg_bay_layout.gd").layout().workshop.stock_grid
	# The robot game uses the preparation stations, stock tray and actuator start,
	# so its grid skips cells whose drawer would stand in them.
	var reserved: Array[Rect2] = []
	if not game.profile.get("prepared_foot",true):
		for station in game.stations.values():
			var volume: Vector3 = station.get_meta("work_volume")
			reserved.append(Rect2(station.global_position.x-volume.x/2,station.global_position.z-volume.z/2,volume.x,volume.z))
		reserved.append(Rect2(-0.95,0.25,1.1,0.7))
		var actuator: Vector3 = game.home_position("pitch")
		reserved.append(Rect2(actuator.x-.3,actuator.z-.3,.6,.6))
	for kind in game.bins:
		var node: Node3D = game.bins[kind]
		if game.model.count_at(kind,"bin") == 0:node.hide();continue
		if node.get_meta("cabinet",false):continue
		if node.get_parent()!=game:node.reparent(game)
		while reserved.any(func(area):return area.intersects(_cell(grid,index).grow(.01))):index += 1
		# A ground-height drawer wall away from the fixture's extraction aisles.
		var row = index/int(grid.columns)
		node.global_position = AssemblyRuntime.vec(grid.origin)+Vector3((index%int(grid.columns))*grid.spacing[0],0,row*grid.spacing[1])
		node.rotation = Vector3.ZERO
		game.box(game.leg_layout,Vector3(node.global_position.x,.245,node.global_position.z),Vector3(.8,.49,.55),game.material(Color("506971")),true)
		index += 1

## The floor footprint of a grid drawer's support.
static func _cell(grid: Dictionary, index: int) -> Rect2:
	var at: Vector3 = AssemblyRuntime.vec(grid.origin)+Vector3((index%int(grid.columns))*grid.spacing[0],0,(index/int(grid.columns))*grid.spacing[1])
	return Rect2(at.x-.4,at.z-.275,.8,.55)

func filter_candidates(candidates: Array[Dictionary]) -> Array[Dictionary]:
	return candidates.filter(func(entry):return entry.type == "loose" or (entry.type == "bin" and game.model.count_at(entry.kind,"bin") > 0))

func undo_error(owner: String) -> String:
	return "The prepared foot stays assembled in M3." if owner in prepared else ""

func capture() -> Dictionary:return {"version":1,"trial":"m3"}

func validate(data: Variant, candidate: AssemblyModel, initial: Dictionary, world: Dictionary) -> Array[String]:
	if not Codec.same_keys(data,["version","trial"]) or not Codec.number(data.version) or data.version != 1 or not data.trial is String or data.trial != "m3":return ["Invalid M3 scenario state."]
	for owner in prepared:
		if candidate.assemblies[owner].slots != initial.model.assemblies[owner].slots:return ["Prepared foot construction changed."]
	return []
