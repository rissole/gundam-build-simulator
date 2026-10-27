class_name EquipmentRegistry
extends RefCounted
## Workshop equipment in interaction order. Every aggregate visits that order,
## so the first registered answer wins. It also carries the player, and the
## load in their hands, with whatever moving body they stand on.
const Codec = preload("res://scripts/pose_codec.gd")
const Sweep = preload("res://scripts/motion_sweep.gd")
const Motion = preload("res://scripts/equipment_motion.gd")
var _deck_cargo = preload("res://scripts/loose_deck_cargo.gd").new()
## How far above a deck a hopping player still counts as riding it.
const RIDE_HOP = 0.6
var _items: Array = []
## Each machine's capture at its most recent stop (or first tick). A save uses it
## for a machine that is still moving, so motion is never saved halfway.
var _rest: Dictionary = {}
var _was_moving: Dictionary = {}
## Where the player last stood with nothing under them moving. A save taken mid-ride
## uses it: that is the deck at the stop the ride left, where the machine reloads.
var steady_player: Variant = null
## Each machine's manual state after the last tick; a difference means an arrival,
## a pin or a connector changed, so the manual recomputes once instead of polling.
signal manual_state_changed
var _manual_states: Dictionary = {}

## Pickup targeting shares its contour with the first waiting loose obstacle.
func obstruction_target() -> Node3D:
	for equipment in all():
		var hit: Dictionary = equipment.motion_obstruction
		if equipment.get("moving") != true or hit.get("kind","") != "part":continue
		var body = hit.get("collider")
		if is_instance_valid(body):return body as Node3D
	return null

func register(equipment: Node) -> void:
	if get_equipment(equipment.equipment_id) != null:
		push_error("Duplicate equipment: "+equipment.equipment_id)
		return
	_items.append(equipment)

func get_equipment(id: String) -> Node:
	for equipment in all():
		if equipment.equipment_id == id:return equipment
	return null

func all() -> Array:
	_items = _items.filter(func(equipment):return is_instance_valid(equipment))
	return _items.duplicate()

func ids() -> Array:
	return all().map(func(equipment):return equipment.equipment_id)

func _detect_manual_changes(items: Array) -> void:
	var changed := false
	for equipment in items:
		var state: Dictionary = equipment.manual_state()
		if state.is_empty() or _manual_states.get(equipment.equipment_id) == state:continue
		_manual_states[equipment.equipment_id] = state
		changed = true
	if changed:manual_state_changed.emit()

func controls() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for equipment in all():result.append_array(equipment.controls())
	return result

func physics(delta: float) -> void:
	var items = all()
	var game: Node = items[0].game if not items.is_empty() else null
	_deck_cargo.refresh(game,items)
	var floor = rider_floor(game)
	var before = floor.global_transform if floor != null else Transform3D.IDENTITY
	for equipment in items:equipment.physics(delta)
	_deck_cargo.move_cargo(game)
	_remember_rest(items)
	_detect_manual_changes(items)
	if game == null or not is_instance_valid(game.get("player")):return
	if floor == null or not is_instance_valid(floor):
		steady_player = game.player.global_transform
		return
	var moved = floor.global_transform*before.affine_inverse()
	if moved.is_equal_approx(Transform3D.IDENTITY):
		if not items.any(func(equipment):return equipment.get("moving") == true and equipment.carries(floor)):steady_player = game.player.global_transform
		return
	game.player.global_position = moved*game.player.global_position
	game.player.rotate_y(moved.basis.get_euler().y)
	var carried = carried_body(game)
	if carried != null:carried.global_transform = moved*carried.global_transform
	# Later queries this tick see the new poses. Jolt applies a kinematic floor's
	# pose only at the next step, so the player moves before equipment does.
	for body in [floor,game.player,carried]:
		if body != null:PhysicsServer3D.body_set_state(body.get_rid(),PhysicsServer3D.BODY_STATE_TRANSFORM,body.global_transform)

## Only still-loose cargo is excluded; pickup/shelf transfer takes effect immediately.
func loose_passengers(equipment: Node) -> Array[CollisionObject3D]:
	return _deck_cargo.passengers(equipment.game,equipment)

## The body under the player's feet, allowing a short hop, or null.
static func rider_floor(game: Node) -> CollisionObject3D:
	if game == null:return null
	# A suspended descender just above a deck is not that deck's passenger.
	var registry = game.get("equipment")
	var rope = registry.get_equipment("rope_access") if registry!=null else null
	if rope!=null and rope.attached() and rope.hanging:return null
	var player = game.get("player") as CharacterBody3D
	if not is_instance_valid(player) or not player.is_inside_tree():return null
	var excluded: Array[RID] = [player.get_rid()]
	var carried = carried_body(game)
	if carried != null:Sweep.collect_rids(carried,excluded)
	var query = PhysicsRayQueryParameters3D.create(player.global_position+Vector3.UP*0.1,player.global_position-Vector3.UP*RIDE_HOP,15,excluded)
	var hit = player.get_world_3d().direct_space_state.intersect_ray(query)
	return hit.collider as CollisionObject3D if not hit.is_empty() else null

## The component or build in the player's hands, which travels with a rider.
static func carried_body(game: Node) -> CollisionObject3D:
	if game == null:return null
	var components = game.get("components")
	if is_instance_valid(components):
		var held = components.get("held_body") as CollisionObject3D
		if is_instance_valid(held):return held
	if game.has_method("held_build"):
		var owner: String = game.held_build()
		var bodies = game.get("bodies")
		if not owner.is_empty() and bodies is Dictionary:return bodies.get(owner) as CollisionObject3D
	return null

func access_error(owner: String) -> String:
	for equipment in all():
		var error: String = equipment.access_error(owner)
		if not error.is_empty():return error
	return ""

func placement_error(owner: String, sid: String) -> String:
	for equipment in all():
		var error: String=equipment.placement_error(owner,sid)
		if not error.is_empty():return error
	return ""

func undo(owner: String) -> Dictionary:
	for equipment in all():
		var result: Dictionary = equipment.undo(owner)
		if result.get("handled",false):return result
	return {"handled":false,"error":""}

## The handling equipment's status is included for confirmation feedback.
func drop() -> Dictionary:
	for equipment in all():
		var result: Dictionary = equipment.drop()
		if result.get("handled",false):
			result["status"] = equipment.status_text()
			return result
	return {"handled":false,"error":""}

func busy_reason(subject: String, except_id: String = "") -> String:
	for equipment in all():
		if equipment.equipment_id == except_id:continue
		var reason: String = equipment.busy_reason(subject)
		if not reason.is_empty():return reason
	return ""

func travel_error(carrier_id: String, from: float, to: float) -> String:
	for equipment in all():
		if equipment.equipment_id == carrier_id:continue
		var error: String = equipment.travel_error(carrier_id,from,to)
		if not error.is_empty():return error
	return ""

func carrier_moved(carrier_id: String) -> void:
	for equipment in all():
		if equipment.equipment_id != carrier_id:equipment.carrier_moved(carrier_id)

func payload_holder() -> Node:
	for equipment in all():
		if not equipment.hand_payload().is_empty():return equipment
	return null

func capture() -> Dictionary:
	var result = {}
	for equipment in all():result[equipment.equipment_id] = equipment.capture()
	return result

## Captures a machine only when it comes to rest (and on its first tick), never every frame.
func _remember_rest(items: Array) -> void:
	for equipment in items:
		var id: String = equipment.equipment_id
		var moving: bool = equipment.get("moving") == true
		if not moving and _was_moving.get(id,true):_rest[id] = equipment.capture()
		_was_moving[id] = moving

## Save state for every machine except `skipped`: live when at rest, otherwise
## its last stop.
func save_capture(skipped: Array = []) -> Dictionary:
	var result = {}
	for equipment in all():
		var id: String = equipment.equipment_id
		if id in skipped:continue
		var moving: bool = equipment.get("moving") == true
		var state: Dictionary = (_rest[id] if moving and _rest.has(id) and not equipment.saves_in_motion() else equipment.capture()).duplicate(true)
		if moving and equipment.saves_in_motion():
			state.moving = false
			state.blocked_reason = ""
		result[id] = state
	return result

## Applies save_capture() output, in interaction order, to the machines it lists.
func apply_saved(data: Dictionary) -> void:
	for equipment in all():
		if data.has(equipment.equipment_id):equipment.apply(data[equipment.equipment_id])
	_rest.clear()
	_was_moving.clear()

func validate(data: Variant, candidate: AssemblyModel, world: Dictionary) -> Array[String]:
	if not Codec.same_keys(data,ids()):return ["Equipment identities changed."]
	for equipment in all():
		if not data[equipment.equipment_id] is Dictionary:return ["Invalid "+equipment.equipment_id+" snapshot."]
		var errors: Array[String] = equipment.validate(data[equipment.equipment_id],candidate,world)
		if not errors.is_empty():return errors
	return []

func apply(data: Dictionary) -> void:
	for equipment in all():equipment.apply(data[equipment.equipment_id])
