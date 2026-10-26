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
static func sweep(space: PhysicsDirectSpaceState3D, groups: Array, sample_count: int, pose_at: Callable, mask: int, exclude: Array[RID], label: String = "", exclusions_at: Callable = Callable()) -> Dictionary:
	var previous_shapes: Dictionary = {}
	if not exclusions_at.is_valid() and groups.all(func(group):return group.get("linear",false) and group.get("cast",false)):
		sample_count = 1
	for index in range(sample_count+1):
		var fraction = float(index)/sample_count
		var pose: Transform3D = pose_at.call(fraction)
		var ignored: Array[RID] = exclusions_at.call(pose) if exclusions_at.is_valid() else exclude
		for group_index in groups.size():
			var group: Dictionary = groups[group_index]
			if index > 0 and index < sample_count and not exclusions_at.is_valid() and group.get("linear",false) and group.get("cast",false):continue
			var frame: Transform3D = group.frame.call(pose) if group.has("frame") else pose
			var shapes: Array = group.shapes_at.call(pose,fraction) if group.has("shapes_at") else group.shapes
			for shape_index in shapes.size():
				var entry: Dictionary = shapes[shape_index]
				var at: Transform3D = entry.world if entry.has("world") else frame*entry.transform
				var margin: float = entry.get("margin",group.get("margin",0.001))
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

static func _report(error: String, collider: Object, index: int, label: String) -> Dictionary:
	var name = str(collider.name) if collider is Node else ""
	if OS.has_environment(DIAGNOSTIC_ENV):print("SWEEP_CONTACT ",label," sample=",index," collider=",collider.get_path() if collider is Node and collider.is_inside_tree() else name)
	return {"error":error.replace("{collider}",name),"index":index,"collider":collider}
