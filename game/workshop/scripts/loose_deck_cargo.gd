extends RefCounted
## Runtime support, never model ownership. Cargo remains loose, is moved once by
## the registry, and returns to dynamic physics as soon as it leaves its support.
const Sweep = preload("res://scripts/motion_sweep.gd")
const CONTACT = .008
var _cargo: Dictionary = {}
var _observed: Dictionary = {}

func _is_loose(game: Node, body) -> bool:
	if not is_instance_valid(body) or body.is_queued_for_deletion() or body.held or body == EquipmentRegistry.carried_body(game):return false
	var loose = game.get("loose")
	var model = game.get("model")
	return loose is Dictionary and loose.get(body.uid) == body and model != null and model.items.has(body.uid) and model.items[body.uid].location == "loose"

func passengers(game: Node, equipment: Node) -> Array[CollisionObject3D]:
	var result: Array[CollisionObject3D] = []
	for entry in _cargo.values():
		if entry.equipment == equipment and _is_loose(game,entry.body):result.append(entry.body)
	return result

func _release(entry: Dictionary) -> void:
	var body = entry.body
	if not is_instance_valid(body) or body.is_queued_for_deletion() or body.held:return
	# Pickup has already installed kinematic hand physics; never overwrite it.
	if body.freeze_mode != RigidBody3D.FREEZE_MODE_STATIC:return
	body.freeze_mode = entry.mode
	body.freeze = entry.frozen
	body.linear_velocity = Vector3.ZERO;body.angular_velocity = Vector3.ZERO

func refresh(game: Node, items: Array) -> void:
	var next: Dictionary = {};var observed: Dictionary = {}
	if game == null:return
	for equipment in items:
		for surface in equipment.cargo_decks():
			var support: CollisionObject3D = surface.body
			var bounds: AABB = surface.bounds
			var probe = BoxShape3D.new();probe.size = bounds.size
			var query = PhysicsShapeQueryParameters3D.new()
			query.shape = probe;query.transform = support.global_transform*Transform3D(Basis.IDENTITY,bounds.get_center());query.collision_mask = 2
			for hit in support.get_world_3d().direct_space_state.intersect_shape(query,256):
				var body = hit.collider as WorkshopPart
				if body == null or support.is_ancestor_of(body) or next.has(body.get_instance_id()) or not _is_loose(game,body):continue
				var id = body.get_instance_id()
				if not _contact(body,support):continue
				var local = support.global_transform.affine_inverse()*body.global_transform
				observed[id] = {"support":support,"pose":local}
				var previous: Dictionary = _observed.get(id,{})
				if previous.get("support") != support or not _stable(previous.pose,local):continue
				if body.linear_velocity.length() > .15 or body.angular_velocity.length() > .15:continue
				var old: Dictionary = _cargo.get(id,{})
				var entry = {"body":body,"support":support,"equipment":equipment,"before":support.global_transform,"mode":body.freeze_mode,"frozen":body.freeze}
				if not old.is_empty():entry.mode = old.mode;entry.frozen = old.frozen
				body.freeze_mode = RigidBody3D.FREEZE_MODE_STATIC;body.freeze = true
				body.linear_velocity = Vector3.ZERO;body.angular_velocity = Vector3.ZERO
				next[id] = entry
	for id in _cargo:
		if not next.has(id):_release(_cargo[id])
	_cargo = next;_observed = observed

func _stable(from: Transform3D, to: Transform3D) -> bool:
	return from.origin.distance_to(to.origin) < .008 and from.basis.get_rotation_quaternion().angle_to(to.basis.get_rotation_quaternion()) < .015

func _contact(body: WorkshopPart, support: CollisionObject3D) -> bool:
	var space = body.get_world_3d().direct_space_state
	var bounds = body.global_transform*SolidHandling.bounds(body)
	var centre = Vector3(bounds.get_center().x,bounds.position.y,bounds.get_center().z)
	var excluded: Array[RID] = [];Sweep.collect_rids(body,excluded)
	# Stable support needs the load's centre over a real upward-facing surface.
	# A neighbouring rail, hovering load or mere deck-volume overlap cannot claim it.
	var ray = PhysicsRayQueryParameters3D.create(centre+Vector3.UP*.012,centre-Vector3.UP*CONTACT,1,excluded)
	var below = space.intersect_ray(ray)
	if below.get("collider") != support or below.normal.y < .85:return false
	var shapes: Array[Dictionary] = [];Sweep.collect_shapes(body,Transform3D.IDENTITY,shapes)
	var contact = false
	for entry in shapes:
		var query = PhysicsShapeQueryParameters3D.new()
		query.shape = entry.shape;query.transform = entry.transform.translated(Vector3.DOWN*CONTACT)
		query.collision_mask = 1;query.exclude = excluded;query.margin = 0.0
		for hit in space.intersect_shape(query,64):
			# A part bridging the deck and a fixed landing stays an obstruction.
			if hit.collider != support:return false
			contact = true
	return contact

func move_cargo(game: Node) -> void:
	for entry in _cargo.values():
		var body = entry.body
		if not _is_loose(game,body) or not is_instance_valid(entry.support):continue
		entry.support.force_update_transform()
		PhysicsServer3D.body_set_state(entry.support.get_rid(),PhysicsServer3D.BODY_STATE_TRANSFORM,entry.support.global_transform)
		var moved: Transform3D = entry.support.global_transform*entry.before.affine_inverse()
		body.global_transform = moved*body.global_transform
		body.force_update_transform()
		PhysicsServer3D.body_set_state(body.get_rid(),PhysicsServer3D.BODY_STATE_TRANSFORM,body.global_transform)
		# Remember the post-move relative pose, rather than stale physics history.
		_observed[body.get_instance_id()] = {"support":entry.support,"pose":entry.support.global_transform.affine_inverse()*body.global_transform}
