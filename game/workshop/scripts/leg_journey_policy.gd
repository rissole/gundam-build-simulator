extends RefCounted
## Only the internally complete right foot is supplied. The player builds the
## left foot; all structural/hip work is real.
const RIGHT_FOOT = ["right_foot","right_pad_1","right_pad_2","right_pitch"]
## Clear walking depth kept in front (+Z) of preparation work.
const APPROACH = 1.6
var game: Node
func _init(workshop: Node) -> void:
	game = workshop

func position_stock() -> void:
	var index = 0
	var grid: Dictionary = preload("res://scripts/leg_bay_layout.gd").layout().workshop.stock_grid
	# The grid skips cells whose drawer would stand in the preparation stations,
	# stock tray or actuator start, or in the 1.6 m aisle in front of each.
	var reserved: Array[Rect2] = []
	for station in game.stations.values():
		var volume: Vector3 = station.get_meta("work_volume")
		reserved.append(Rect2(station.global_position.x-volume.x/2,station.global_position.z-volume.z/2,volume.x,volume.z+APPROACH))
	reserved.append(Rect2(-0.95,0.25,1.1,0.7+APPROACH))
	var actuator: Vector3 = game.home_position("pitch")
	reserved.append(Rect2(actuator.x-.6,actuator.z-.3,1.2,.6+APPROACH))
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

## Empty drawers and shelves offer nothing; every other target stays.
func filter_candidates(candidates: Array[Dictionary]) -> Array[Dictionary]:
	# One inventory pass, not one full recount for every drawer. Build this from
	# current state so collection, return and supplied staging need no cache invalidation.
	var stocked: Dictionary = {}
	for item in game.model.items.values():
		if item.location == "bin":stocked[item.kind] = true
	return candidates.filter(func(entry):return entry.type != "bin" or stocked.has(entry.kind))

func undo_error(owner: String) -> String:
	return "The supplied right foot stays assembled." if owner in RIGHT_FOOT else ""
