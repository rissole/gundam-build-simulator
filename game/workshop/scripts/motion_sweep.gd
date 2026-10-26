class_name MotionSweep
extends RefCounted
## The one sampled-pose collision sweep and occupancy query used by moving
## equipment, carried bodies and the player. Callers own their sample counts,
## margins and player-facing messages; this owns the physics queries.
## Set WORKSHOP_SWEEP_DIAGNOSTIC to print every reported contact.
const DIAGNOSTIC_ENV = "WORKSHOP_SWEEP_DIAGNOSTIC"

## Reuse a rigid load's local geometry, never a collision result. Owners must
## invalidate on articulation/model changes; collision rebuilds carry a revision.
## Unversioned bodies deliberately fall back to live collection.
class RigidGeometry extends RefCounted:
	var shapes: Array[Dictionary] = []
	var rids: Array[RID] = []
	var _body: WeakRef
	var _revision: int = -1
	func invalidate() -> void:
		_body = null
		shapes.clear();rids.clear()
	func read(body: Node3D) -> void:
		var revision: int = body.get_meta("collision_revision",-1)
		if revision >= 0 and _body != null and _body.get_ref() == body and revision == _revision:return
		shapes = [];rids = []
		MotionSweep.collect_shapes(body,body.global_transform.affine_inverse(),shapes)
		MotionSweep.collect_rids(body,rids)
		_body = weakref(body);_revision = revision

## First overlapping collider for one shape at one pose, or {}.
static func overlap(space: PhysicsDirectSpaceState3D, shape: Shape3D, at: Transform3D, mask: int, exclude: Array[RID], margin: float) -> Dictionary:
	var query = PhysicsShapeQueryParameters3D.new()
	query.shape = shape;query.transform = at;query.collision_mask = mask;query.exclude = exclude;query.margin = margin
	var hits = space.intersect_shape(query,1)
	return hits[0] if not hits.is_empty() else {}

## Fractions from a linear cast between two poses of one shape.
static func cast(space: PhysicsDirectSpaceState3D, shape: Shape3D, from: Transform3D, to: Transform3D, mask: int, exclude: Array[RID], margin: float) -> PackedFloat32Array:
	var query = PhysicsShapeQueryParameters3D.new()
	query.shape = shape;query.transform = from;query.motion = to.origin-from.origin;query.collision_mask = mask;query.exclude = exclude;query.margin = margin
	return space.cast_motion(query)

## Surface travel, not a fixed angle: long arms need finer angular sampling.
static func steps(from: Transform3D, to: Transform3D, radius: float, max_travel: float = 0.025) -> int:
	var angle = from.basis.get_rotation_quaternion().angle_to(to.basis.get_rotation_quaternion())
	return maxi(1,ceili((from.origin.distance_to(to.origin)+angle*radius)/maxf(0.002,max_travel)))

## Enabled direct collision shapes of one body, in its own frame.
static func body_shapes(body: CollisionObject3D) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for child in body.get_children():
		if child is CollisionShape3D and not child.disabled:result.append({"shape":child.shape,"transform":child.transform})
	return result

## Every enabled shape under `node`, posed by `inverse`; concave shapes become box proxies.
static func collect_shapes(node: Node, inverse: Transform3D, output: Array[Dictionary]) -> void:
	if node is CollisionShape3D and not node.disabled:
		var shape: Shape3D = node.shape
		var pose = inverse*node.global_transform
		if node.has_meta("motion_shapes"):
			for entry in node.get_meta("motion_shapes"):output.append({"shape":entry.shape,"transform":pose*entry.transform})
			return
		if shape is ConcavePolygonShape3D:
			var bounds = shape.get_debug_mesh().get_aabb()
			shape = BoxShape3D.new();shape.size = bounds.size.max(Vector3.ONE*.004)
			pose *= Transform3D(Basis.IDENTITY,bounds.get_center())
		output.append({"shape":shape,"transform":pose})
	for child in node.get_children():collect_shapes(child,inverse,output)

## Adds the RID of every collision object at or under `node`.
static func collect_rids(node: Node, output: Array[RID]) -> void:
	if node is CollisionObject3D and not output.has(node.get_rid()):output.append(node.get_rid())
	for child in node.get_children():collect_rids(child,output)

## Samples `pose_at(fraction)` at steps+1 poses. At each pose every group is
## checked in order: {"shapes":[{shape,transform}], "frame":Callable(pose),
## "shapes_at":Callable(pose, fraction) -> [{shape,world,margin}], "margin",
## "error", "cast", "cast_error", "linear"}. An explicitly linear group has
## constant shape dimensions/orientations and straight paths for every member:
## endpoints plus a continuous cast suffice. Never infer this from equal endpoint
## bases (an articulated route may curve), or skip pose-dependent exclusions.
## "{collider}" in an error names the hit body.
## Returns {} when clear, else {"error","index","collider"}.
## Every shape is first bounded over its whole sweep (all sampled poses and the
## casts between them) and queried once. A shape whose swept bounds touch nothing
## cannot report a contact, so it skips its detailed queries; the first reported
## contact is unchanged. Callers never opt in: every sweep pays per detailed
## shape only near obstacles, however many members or samples it has.
static func sweep(space: PhysicsDirectSpaceState3D, groups: Array, sample_count: int, pose_at: Callable, mask: int, exclude: Array[RID], label: String = "", exclusions_at: Callable = Callable()) -> Dictionary:
	var previous_shapes: Dictionary = {}
	if not exclusions_at.is_valid() and groups.all(func(group):return group.get("linear",false) and group.get("cast",false)):
		sample_count = 1
	var plan: Array[Dictionary] = []
	for index in range(sample_count+1):
		var fraction = float(index)/sample_count
		var pose: Transform3D = pose_at.call(fraction)
		var ignored: Array[RID] = exclusions_at.call(pose) if exclusions_at.is_valid() else exclude
		var posed: Array = []
		for group_index in groups.size():
			var group: Dictionary = groups[group_index]
			if index > 0 and index < sample_count and not exclusions_at.is_valid() and group.get("linear",false) and group.get("cast",false):
				posed.append(null);continue
			posed.append(_posed_shapes(group,pose,fraction))
		plan.append({"pose":pose,"fraction":fraction,"ignored":ignored,"groups":posed})
	var clear: Dictionary = _clear_shapes(space,groups,plan,mask)
	for index in range(plan.size()):
		var step: Dictionary = plan[index]
		var ignored: Array[RID] = step.ignored
		for group_index in groups.size():
			var group: Dictionary = groups[group_index]
			var shapes = step.groups[group_index]
			if shapes == null:continue
			var pending := false
			for shape_index in shapes.size():
				if not clear.has(Vector2i(group_index,shape_index)):pending = true;break
			if not pending:continue
			# shapes_at may reuse and resize its query shapes; pose them again here.
			if group.has("shapes_at"):shapes = _posed_shapes(group,step.pose,step.fraction)
			for shape_index in shapes.size():
				if clear.has(Vector2i(group_index,shape_index)):continue
				var entry: Dictionary = shapes[shape_index]
				var at: Transform3D = entry.at
				var margin: float = entry.margin
				var hit = overlap(space,entry.shape,at,mask,ignored,margin)
				if not hit.is_empty():
					if OS.has_environment(DIAGNOSTIC_ENV):
						var target=hit.collider.shape_owner_get_owner(hit.collider.shape_find_owner(hit.shape)) if hit.collider is CollisionObject3D else null
						print("SWEEP_SHAPE ",label," at=",at," moving=",entry.shape," target=",target," source=",target.get_meta("source_uid","") if target!=null else "")
					return _report(group.error,hit.collider,index,label)
				var key = Vector2i(group_index,shape_index)
				if group.get("cast",false) and previous_shapes.has(key):
					var previous: Transform3D = previous_shapes[key]
					var fractions = cast(space,entry.shape,previous,at,mask,ignored,margin)
					if fractions.size() == 2 and fractions[0] < 0.999:
						# cast_motion returns fractions only. Query at contact so thin
						# obstacles between samples still have an identity for feedback.
						var contact = previous
						contact.origin = contact.origin.lerp(at.origin,fractions[1])
						var blocker = overlap(space,entry.shape,contact,mask,ignored,margin+.001)
						return _report(group.get("cast_error",group.error),blocker.get("collider"),index,label)
				if group.get("cast",false):previous_shapes[key] = at
	return {}

static func _posed_shapes(group: Dictionary, pose: Transform3D, fraction: float) -> Array[Dictionary]:
	var frame: Transform3D = group.frame.call(pose) if group.has("frame") else pose
	var shapes: Array = group.shapes_at.call(pose,fraction) if group.has("shapes_at") else group.shapes
	var result: Array[Dictionary] = []
	for entry in shapes:
		var at: Transform3D = entry.world if entry.has("world") else frame*entry.transform
		result.append({"shape":entry.shape,"at":at,"margin":float(entry.get("margin",group.get("margin",0.001))),"bounds":local_bounds(entry.shape)})
	return result

## Shape keys whose complete swept bounds overlap nothing outside the RIDs
## excluded at every sample. Bounds cover each sampled pose and, for cast
## groups, the translation from the previous checked pose that the cast tests.
static func _clear_shapes(space: PhysicsDirectSpaceState3D, groups: Array, plan: Array[Dictionary], mask: int) -> Dictionary:
	var swept: Dictionary = {}
	var padding: Dictionary = {}
	var unbounded: Dictionary = {}
	var previous: Dictionary = {}
	var common: Array[RID] = plan[0].ignored
	for step in plan:
		if step.ignored == common:continue
		var kept: Array[RID] = []
		for rid in common:
			if step.ignored.has(rid):kept.append(rid)
		common = kept
	for step in plan:
		for group_index in groups.size():
			var shapes = step.groups[group_index]
			if shapes == null:continue
			var cast: bool = groups[group_index].get("cast",false)
			for shape_index in shapes.size():
				var key = Vector2i(group_index,shape_index)
				var entry: Dictionary = shapes[shape_index]
				if entry.bounds == null:unbounded[key] = true;continue
				var local: AABB = entry.bounds
				var at: Transform3D = entry.at
				var box: AABB = at*local
				if cast and previous.has(key):
					var from: Transform3D = previous[key]
					box = box.merge(from*local).merge(Transform3D(from.basis,at.origin)*local)
				if cast:previous[key] = at
				swept[key] = swept[key].merge(box) if swept.has(key) else box
				padding[key] = maxf(padding.get(key,0.0),entry.margin)
	var clear: Dictionary = {}
	var probe := BoxShape3D.new()
	for key in swept:
		if unbounded.has(key):continue
		# The detail check queries again with margin+0.001 at a cast contact.
		var box: AABB = swept[key].grow(maxf(padding[key],0.0)+.003)
		probe.size = box.size
		if overlap(space,probe,Transform3D(Basis.IDENTITY,box.get_center()),mask,common,0.0).is_empty():clear[key] = true
	return clear

static var _hull_bounds: Dictionary = {}

## Local bounds of a query shape, or null when it has no cheap bound (such a
## shape is always checked in detail).
static func local_bounds(shape: Shape3D) -> Variant:
	if shape is BoxShape3D:return AABB(-shape.size/2,shape.size)
	if shape is SphereShape3D:return AABB(-Vector3.ONE*shape.radius,Vector3.ONE*2*shape.radius)
	if shape is CapsuleShape3D or shape is CylinderShape3D:
		var radius: float = shape.radius;var height: float = shape.height
		return AABB(Vector3(-radius,-height/2,-radius),Vector3(2*radius,height,2*radius))
	if shape is ConvexPolygonShape3D:
		var points: PackedVector3Array = shape.points
		if points.is_empty():return null
		var signature := hash(points)
		var cached = _hull_bounds.get(shape.get_instance_id())
		if cached != null and cached[0] == signature:return cached[1]
		var bounds := AABB(points[0],Vector3.ZERO)
		for point in points:bounds = bounds.expand(point)
		if _hull_bounds.size() > 4096:_hull_bounds.clear()
		_hull_bounds[shape.get_instance_id()] = [signature,bounds]
		return bounds
	return null

static func _report(error: String, collider: Object, index: int, label: String) -> Dictionary:
	var name = str(collider.name) if collider is Node else ""
	if OS.has_environment(DIAGNOSTIC_ENV):print("SWEEP_CONTACT ",label," sample=",index," collider=",collider.get_path() if collider is Node and collider.is_inside_tree() else name)
	return {"error":error.replace("{collider}",name),"index":index,"collider":collider}
