class_name MotionSweep
extends RefCounted
## The one sampled-pose collision sweep and occupancy query used by moving
## equipment, carried bodies and the player. Callers own their sample counts,
## margins and player-facing messages; this owns the physics queries.
## Set WORKSHOP_SWEEP_DIAGNOSTIC to print every reported contact.
const DIAGNOSTIC_ENV = "WORKSHOP_SWEEP_DIAGNOSTIC"

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
## "error", "cast", "cast_error"}. "{collider}" in an error names the hit body.
## Returns {} when clear, else {"error","index","collider"}.
static func sweep(space: PhysicsDirectSpaceState3D, groups: Array, sample_count: int, pose_at: Callable, mask: int, exclude: Array[RID], label: String = "") -> Dictionary:
	var previous = Transform3D.IDENTITY
	for index in range(sample_count+1):
		var fraction = float(index)/sample_count
		var pose: Transform3D = pose_at.call(fraction)
		for group in groups:
			var frame: Transform3D = group.frame.call(pose) if group.has("frame") else pose
			var previous_frame: Transform3D = group.frame.call(previous) if group.has("frame") else previous
			var shapes: Array = group.shapes_at.call(pose,fraction) if group.has("shapes_at") else group.shapes
			for entry in shapes:
				var at: Transform3D = entry.world if entry.has("world") else frame*entry.transform
				var margin: float = entry.get("margin",group.get("margin",0.001))
				var hit = overlap(space,entry.shape,at,mask,exclude,margin)
				if not hit.is_empty():
					if OS.has_environment(DIAGNOSTIC_ENV):
						var target=hit.collider.shape_owner_get_owner(hit.collider.shape_find_owner(hit.shape)) if hit.collider is CollisionObject3D else null
						print("SWEEP_SHAPE ",label," at=",at," moving=",entry.shape," target=",target," source=",target.get_meta("source_uid","") if target!=null else "")
					return _report(group.error,hit.collider,index,label)
				if group.get("cast",false) and index > 0:
					var fractions = cast(space,entry.shape,previous_frame*entry.transform,at,mask,exclude,margin)
					if fractions.size() == 2 and fractions[0] < 0.999:return _report(group.get("cast_error",group.error),null,index,label)
		previous = pose
	return {}

static func _report(error: String, collider: Object, index: int, label: String) -> Dictionary:
	var name = str(collider.name) if collider is Node else ""
	if OS.has_environment(DIAGNOSTIC_ENV):print("SWEEP_CONTACT ",label," sample=",index," collider=",collider.get_path() if collider is Node and collider.is_inside_tree() else name)
	return {"error":error.replace("{collider}",name),"index":index,"collider":collider}
