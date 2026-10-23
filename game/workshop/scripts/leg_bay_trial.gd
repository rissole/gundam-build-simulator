extends RefCounted
## Leg-bay trial rules that are not equipment: supplied construction stays
## assembled, only the trial's playable slots are worked, and ground stock
## is the only free-standing pickup. Equipment interlocks live in the registry.
const VERSION = 3
const Codec = preload("res://scripts/pose_codec.gd")
const SUPPLIED = "The supplied construction stays assembled in this M2 example. Use rail Return after removing retention."
var game: Node

func _init(workshop: Node) -> void:
	game = workshop

func position_stock() -> void:
	# Ground stock feeds pockets and the lift's finite component shelf.
	var index = 0
	for kind in game.bins:
		if game.model.count_at(kind,"bin") == 0:
			game.bins[kind].hide()
			continue
		var node: Node3D = game.bins[kind]
		if node.get_parent() != game:node.reparent(game)
		node.global_position = Vector3(6.4+index*1.15,.7,20.7) if game.profile.trial == "retention" else Vector3(8.3+index*.9,.7,14.2)
		node.rotation = Vector3.ZERO
		game.box(game.leg_layout,Vector3(node.global_position.x,.245,node.global_position.z),Vector3(.8,.49,.55),game.material(Color("506971")),true)
		index += 1

func filter_candidates(candidates: Array[Dictionary]) -> Array[Dictionary]:
	return candidates.filter(func(entry):return entry.type == "loose" or (entry.type == "bin" and game.model.count_at(entry.kind,"bin") > 0))

## Undo is allowed only for the trial's own playable connections.
func undo_error(owner: String) -> String:
	var playable: Array = game.leg_content.m2.playable_slots.get(owner,[])
	var history: Array = game.model.assemblies[owner].history if game.model.assemblies.has(owner) else []
	if history.is_empty():return "There is no retaining hardware to undo." if not playable.is_empty() else SUPPLIED
	return "" if history.back().slot in playable else SUPPLIED

func capture() -> Dictionary:
	return {"version":VERSION,"trial":game.profile.trial}

func validate(data: Variant, candidate: AssemblyModel, initial: Dictionary, world: Dictionary) -> Array[String]:
	if not data is Dictionary or data.size() != 2:return ["Missing M2 example snapshot."]
	if not (data.get("version") is int or data.get("version") is float) or not data.get("trial") is String:return ["Invalid M2 example metadata."]
	if data.version != VERSION or data.trial != game.profile.trial:return ["Unsupported M2 example snapshot."]
	for owner in initial.model.assemblies:
		var fixed_slots: Dictionary = initial.model.assemblies[owner].slots
		for sid in fixed_slots:
			if not str(fixed_slots[sid]).is_empty() and candidate.assemblies[owner].slots[sid] != fixed_slots[sid]:return ["Supplied construction changed outside this M2 example."]
	if game.equipment.get_equipment("lift_shelf") == null and (not candidate.support_occupant("m2_lift_shelf_0").is_empty() or not candidate.support_occupant("m2_lift_shelf_1").is_empty()):return ["Unexpected shelf cargo in crane example."]
	if not Codec.to_pose(world.fixtures.pelvis).is_equal_approx(Codec.to_pose(initial.world.fixtures.pelvis)):return ["Pelvis must remain anchored to its gantry."]
	return []
