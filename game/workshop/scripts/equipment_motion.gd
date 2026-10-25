extends RefCounted
## Shared guarded-motion policy. Controllers supply their actual load/rig shapes
## and intentional contact exclusions; this owns the horizon and obstacle feedback.
const Sweep = preload("res://scripts/motion_sweep.gd")
const LOOKAHEAD = 0.25
const STRUCTURE = 1
const PARTS = 2
const ASSEMBLIES = 4
const PLAYER = 8
const ALL = STRUCTURE | PARTS | ASSEMBLIES | PLAYER

## A short reservation in metres, always covering the actual physics step.
## metres_per_unit also accounts for rotation at the outer edge of a load.
static func ahead(current: float, goal: float, step: float, metres_per_unit: float = 1.0) -> float:
	return move_toward(current,goal,maxf(absf(step),LOOKAHEAD/maxf(.001,metres_per_unit)))

static func travel(from: Transform3D, to: Transform3D, radius: float) -> float:
	return from.origin.distance_to(to.origin)+from.basis.get_rotation_quaternion().angle_to(to.basis.get_rotation_quaternion())*radius

## Follow route corners rather than casting a chord across them. `step` is the
## next actual route coordinate, which must be covered even on a long frame.
static func path_ahead(route: Array[Transform3D], current: float, goal: float, step: float, radius: float) -> float:
	var cursor = current
	var remaining = LOOKAHEAD
	var direction = signf(goal-current)
	while absf(cursor-goal) > .00001 and remaining > .00001:
		var index = clampi(floori(cursor+.00001) if direction > 0 else ceili(cursor-.00001)-1,0,route.size()-2)
		var end = minf(goal,index+1) if direction > 0 else maxf(goal,index)
		var scale = maxf(.001,travel(route[index],route[index+1],radius))
		var amount = minf(absf(end-cursor),remaining/scale)
		cursor += direction*amount
		remaining -= amount*scale
	return maxf(cursor,step) if direction > 0 else minf(cursor,step) if direction < 0 else step

static func overlap(equipment: Node, shape: Shape3D, at: Transform3D, excluded: Array[RID], margin: float = .001, mask: int = ALL) -> Dictionary:
	return describe(equipment,Sweep.overlap(equipment.get_world_3d().direct_space_state,shape,at,mask,excluded,margin))

static func sweep(equipment: Node, groups: Array, samples: int, pose_at: Callable, excluded: Array[RID], mask: int = ALL, exclusions_at: Callable = Callable()) -> Dictionary:
	var guarded: Array = []
	for group in groups:
		var entry: Dictionary = group.duplicate()
		entry["cast"] = true
		entry["error"] = ""
		guarded.append(entry)
	return describe(equipment,Sweep.sweep(equipment.get_world_3d().direct_space_state,guarded,samples,pose_at,mask,excluded,equipment.equipment_id,exclusions_at))

static func describe(equipment: Node, hit: Dictionary) -> Dictionary:
	if hit.is_empty():return {}
	var body = hit.get("collider")
	var kind = "structure"
	var message = "Waiting for the travel area to clear."
	var game: Node = equipment.game
	if is_instance_valid(body):
		if body == equipment.carried_body():
			kind = "hand_load";message = "Move the component in your hands out of the travel area."
		elif body == game.get("player") or body is CollisionObject3D and body.collision_layer & PLAYER:
			kind = "player";message = "Step out of the travel area."
		elif body is WorkshopPart:
			kind = "part"
			var components = game.get("components")
			var title: String = components.title(body.kind) if is_instance_valid(components) and components.has_method("title") else body.kind.replace("_"," ")
			message = "Move the loose %s out of the travel area." % title
		elif body is CollisionObject3D and body.collision_layer & (PARTS | ASSEMBLIES):
			kind = "part";message = "Move %s out of the travel area." % str(body.name).replace("_"," ")
		else:message = "Waiting for %s to clear the travel area." % str(body.name).replace("_"," ")
	var result = {"error":message,"kind":kind,"collider":body}
	equipment.motion_obstruction = result
	return result
