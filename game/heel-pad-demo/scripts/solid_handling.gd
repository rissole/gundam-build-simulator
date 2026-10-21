class_name SolidHandling
extends RefCounted
## Authored primitive compounds, with per-installed-part mesh bounds as fallback.
## This keeps openings in frames and grows collision only as pieces are installed.
static func authored_shapes(profile: Array, fallback: AABB) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if profile.is_empty():
		var shape = BoxShape3D.new()
		shape.size = fallback.size.max(Vector3.ONE*0.004)
		return [{"shape":shape,"transform":Transform3D(Basis.IDENTITY,fallback.get_center())}]
	for primitive in profile:
		var shape: Shape3D
		match primitive.get("type","box"):
			"sphere":
				shape = SphereShape3D.new()
				shape.radius = primitive.radius
			"capsule":
				shape = CapsuleShape3D.new()
				shape.radius = primitive.radius
				shape.height = primitive.height
			_:
				shape = BoxShape3D.new()
				shape.size = AssemblyRuntime.vec(primitive.size)
		var basis = Basis.from_euler(AssemblyRuntime.vec(primitive.get("rotation_degrees",[0,0,0]))*PI/180.0)
		result.append({"shape":shape,"transform":Transform3D(basis,AssemblyRuntime.vec(primitive.get("position",[0,0,0])))})
	return result

static func shapes(body: CollisionObject3D) -> Array[CollisionShape3D]:
	var result: Array[CollisionShape3D] = []
	for child in body.get_children():
		if child is CollisionShape3D and not child.disabled:result.append(child)
	return result

static func bounds(body: CollisionObject3D) -> AABB:
	var revision: int = body.get_meta("collision_revision",0)
	if body.get_meta("solid_bounds_revision",-1) == revision:return body.get_meta("solid_bounds")
	var result = AABB()
	var first = true
	for col in shapes(body):
		var local_bounds: AABB = col.transform*col.shape.get_debug_mesh().get_aabb()
		result = local_bounds if first else result.merge(local_bounds)
		first = false
	body.set_meta("solid_bounds_revision",revision)
	body.set_meta("solid_bounds",result)
	return result

static func sweep_steps(from: Transform3D, to: Transform3D, radius: float, max_travel: float = 0.025) -> int:
	var angle = from.basis.get_rotation_quaternion().angle_to(to.basis.get_rotation_quaternion())
	# Surface travel, not a fixed angle: long arms need finer angular sampling.
	return maxi(1,ceili((from.origin.distance_to(to.origin)+angle*radius)/maxf(0.002,max_travel)))

static func sweep_error(body: CollisionObject3D, destination: Transform3D, excluded: Array[RID], mask: int, travel: float = 0.025) -> String:
	var space = body.get_world_3d().direct_space_state
	var current = body.global_transform
	var envelope = bounds(body)
	var radius = envelope.get_center().length()+envelope.size.length()/2
	var steps = sweep_steps(current,destination,radius,travel)
	var previous = current
	var angle = current.basis.get_rotation_quaternion().angle_to(destination.basis.get_rotation_quaternion())
	var rotation_margin = radius*angle/steps*0.5
	for i in range(steps+1):
		var pose = current.interpolate_with(destination,float(i)/steps)
		for col in shapes(body):
			var query = PhysicsShapeQueryParameters3D.new()
			query.shape = col.shape
			query.transform = pose*col.transform
			query.collision_mask = mask
			query.exclude = excluded
			query.margin = 0.001+rotation_margin
			if not space.intersect_shape(query,1).is_empty():return "The assembly's approach is blocked by an obstacle. Pull it clear before placing it."
			if i > 0:
				query.transform = previous*col.transform
				query.motion = (pose*col.transform).origin-query.transform.origin
				var fractions = space.cast_motion(query)
				if fractions.size() == 2 and fractions[0] < 0.999:return "The assembly's approach is blocked by scenery. Reposition before placing it."
		previous = pose
	return ""

static func carry_offset(body: CollisionObject3D, _view_basis: Basis, profile: Dictionary) -> Vector3:
	var envelope = bounds(body)
	var orientation: Basis = profile.get("basis",Basis.IDENTITY)
	var oriented: AABB = Transform3D(orientation,Vector3.ZERO)*envelope
	var size = oriented.size
	var extra = maxf(0.0,maxf(size.x,size.z)-0.8)
	var distance = float(profile.get("distance",1.1))
	if profile.has("offset"):distance = -AssemblyRuntime.vec(profile.offset).z
	# Center the held geometry, including off-origin source meshes, on the view
	# axis. Legacy lateral/height offsets no longer move the grip off-screen-center.
	# Larger workpieces still suspend farther forward and retain solid collision.
	return Vector3(0,0,-distance-extra*0.65)-oriented.get_center()
