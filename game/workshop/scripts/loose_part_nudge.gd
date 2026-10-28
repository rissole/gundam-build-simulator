extends RefCounted
## Transactional, horizontal nudging for free-driven equipment. Discover every
## loose body in the next short step, check the whole pile, then move it once.
## A fixed/held/supported blocker aborts the entire step without moving any part.
const Sweep = preload("res://scripts/motion_sweep.gd")
const Motion = preload("res://scripts/equipment_motion.gd")
const MAX_PARTS = 16

static func pushable(game: Node, body) -> bool:
	if not body is WorkshopPart or body.held or body.freeze:return false
	if body == EquipmentRegistry.carried_body(game):return false
	var loose = game.get("loose")
	return loose is Dictionary and loose.get(body.uid)==body and game.model.items.has(body.uid) and game.model.items[body.uid].location=="loose"

static func move(equipment: Node3D, shapes: Array[Dictionary], destination: Transform3D, excluded: Array[RID]) -> Dictionary:
	var pending: Array[WorkshopPart] = []
	var ignored = excluded.duplicate()
	var linear = equipment.global_basis.is_equal_approx(destination.basis)
	var radius = _radius(shapes)
	var groups = [{"shapes":shapes,"linear":linear,"cast":true,"margin":-.002,"error":""}]
	var from = equipment.global_transform
	for attempt in range(MAX_PARTS+1):
		var hit = Sweep.sweep(equipment.get_world_3d().direct_space_state,groups,Sweep.steps(from,destination,radius),func(p):return from.interpolate_with(destination,p),Motion.ALL,ignored)
		if hit.is_empty():
			for body in pending:
				body.global_transform = destination*from.affine_inverse()*body.global_transform
				body.force_update_transform()
				PhysicsServer3D.body_set_state(body.get_rid(),PhysicsServer3D.BODY_STATE_TRANSFORM,body.global_transform)
				# A controlled nudge must not accumulate a second physics shove.
				body.linear_velocity.x = 0;body.linear_velocity.z = 0
				body.angular_velocity = Vector3.ZERO;body.sleeping = false
			return {}
		var body = hit.get("collider")
		if not pushable(equipment.game,body) or pending.size()>=MAX_PARTS:
			return Motion.describe(equipment,hit)
		pending.append(body);Sweep.collect_rids(body,ignored)
		var payload: Array[Dictionary] = []
		Sweep.collect_shapes(body,from.affine_inverse(),payload)
		radius = maxf(radius,_radius(payload))
		groups.append({"shapes":payload,"linear":linear,"cast":true,"margin":-.002,"error":""})
	return {}

static func _radius(shapes: Array[Dictionary]) -> float:
	var radius = 0.0
	for entry in shapes:
		var bounds = Sweep.local_bounds(entry.shape)
		if bounds != null:
			var posed: AABB = entry.transform*bounds
			radius = maxf(radius,posed.get_center().length()+posed.size.length()/2)
	return radius
