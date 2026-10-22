class_name SupportedFootFixture
extends Node3D
## The receiving foot stays in the assembly model. This equipment only supports
## and repositions its existing body; a carriage is never another inventory item.

const WORK_ORIGIN = Vector3(2.3, 1.55, -1.8)
const DISPATCH_ORIGIN = Vector3(2.3, 1.55, 4.4)
const ANGULAR_SPEED = PI / 8.0
const TRANSFER_SPEED = 0.65
const POSE_ANGLES = {"upright": 0.0, "sole_left": -PI / 2.0, "sole_right": PI / 2.0}
const OBSTACLE_MASK = 15

var game: Node3D
var foot: AnimatableBody3D
var carriage: AnimatableBody3D
var rotator: AnimatableBody3D
var moving = false
var at_dispatch = false
var work_pose = "upright"
var blocked_reason = ""
var _destination_pose = "upright"
var _destination_dispatch = false
var _destination = Transform3D.IDENTITY
var _buttons: Array[Dictionary] = []
var _rail_bodies: Array[CollisionObject3D] = []
var _steel: StandardMaterial3D
var _dark: StandardMaterial3D
var _yellow: StandardMaterial3D
var _work_label: Label3D
var _dispatch_label: Label3D

func setup(workshop: Node3D, receiving_foot: AnimatableBody3D) -> void:
	game = workshop
	foot = receiving_foot
	_steel = game.material(Color("526970"), 0.55)
	_dark = game.material(Color("23353b"), 0.4)
	_yellow = game.material(Color("e8b46b"), 0.2)
	_make_rails()
	_make_carriage()
	_make_platform()
	# The working controls face inward from the platform's parallel outer rail.
	# An operator can turn the foot without leaving its connection access aisle.
	_make_console(Vector3(4.87, 0.55, -1.8), false)
	_make_console(Vector3(0.78, 0, 6.9), true)
	_apply_pose(Transform3D(Basis.IDENTITY, WORK_ORIGIN))
	_refresh_labels()

func controls() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for button in _buttons:
		var entry: Dictionary = button.duplicate()
		entry.point = button.node.global_position
		result.append(entry)
	return result

func action_error(action: String) -> String:
	if moving:
		return blocked_reason if not blocked_reason.is_empty() else "Wait for the fixture to stop."
	if action == "return":
		return "The carrier is already in the work bay." if not at_dispatch else ""
	if at_dispatch:
		return "Return the carrier to the work bay first."
	if action == "transfer":
		if not game.model.milestone(game.default_parent_id(), "complete"):
			return "Secure both heel pads and the pitch actuator before transferring the foot."
		if work_pose != "upright":
			return "Set the foot upright before transferring it."
		return ""
	if not POSE_ANGLES.has(action):
		return "Unknown fixture control."
	if action == work_pose:
		return "The fixture is already in this working pose."
	return ""

func request(action: String) -> String:
	var error = action_error(action)
	if not error.is_empty():
		return error
	var next_dispatch = action == "transfer"
	var next_pose = "upright" if action == "transfer" or action == "return" else action
	var next_origin = DISPATCH_ORIGIN if next_dispatch else WORK_ORIGIN
	var destination = Transform3D(Basis(Vector3.BACK, POSE_ANGLES[next_pose]), next_origin)
	error = _sweep_error(foot.global_transform, destination)
	if not error.is_empty():
		return error
	_destination = destination
	_destination_pose = next_pose
	_destination_dispatch = next_dispatch
	blocked_reason = ""
	moving = true
	_refresh_labels()
	return ""

func status_text() -> String:
	if moving:
		if not blocked_reason.is_empty():
			return "FIXTURE PAUSED — " + blocked_reason
		if foot.global_position.distance_to(_destination.origin) > 0.01:
			return "CARRIER MOVING — " + ("dispatch bay" if _destination_dispatch else "work bay")
		return "FIXTURE TURNING — " + _pose_title(_destination_pose)
	if at_dispatch:
		return "DISPATCH BAY — foot secured on its carrier"
	return "FOOT FIXTURE — " + _pose_title(work_pose)

func physics(delta: float) -> void:
	if not moving or game.paused:
		return
	var current = foot.global_transform
	var distance = current.origin.distance_to(_destination.origin)
	var angle = current.basis.get_rotation_quaternion().angle_to(_destination.basis.get_rotation_quaternion())
	var fraction = 1.0
	if distance > 0.0001:
		fraction = minf(fraction, TRANSFER_SPEED * delta / distance)
	if angle > 0.0001:
		fraction = minf(fraction, ANGULAR_SPEED * delta / angle)
	var candidate = _guided_pose(current, _destination, fraction)
	var error = _sweep_error(current, candidate)
	if not error.is_empty():
		blocked_reason = error
		_refresh_labels()
		return
	blocked_reason = ""
	_apply_pose(candidate)
	if fraction >= 1.0:
		_apply_pose(_destination)
		moving = false
		at_dispatch = _destination_dispatch
		work_pose = _destination_pose
	_refresh_labels()

func _apply_pose(pose: Transform3D) -> void:
	foot.global_transform = pose
	carriage.global_position = Vector3(pose.origin.x, 0, pose.origin.z)
	rotator.global_transform = pose

static func _guided_pose(from: Transform3D, to: Transform3D, weight: float) -> Transform3D:
	# The two sole poses are exactly 180 degrees apart. Quaternion interpolation
	# may choose either arc there; this machine always turns through upright.
	var from_angle = atan2(from.basis.x.y, from.basis.x.x)
	var to_angle = atan2(to.basis.x.y, to.basis.x.x)
	return Transform3D(Basis(Vector3.BACK, lerpf(from_angle, to_angle, weight)), from.origin.lerp(to.origin, weight))

func _sweep_error(from: Transform3D, to: Transform3D) -> String:
	# A single workpiece envelope deliberately reserves the foot's internal gaps:
	# the operator cannot stand inside the frame while the powered fixture moves.
	# Carriage/clamp solids are checked separately, keeping the open underside open.
	var bounds = SolidHandling.bounds(foot)
	for descendant in foot.find_children("*", "CollisionObject3D", true, false):
		var child_bounds = SolidHandling.bounds(descendant)
		if child_bounds.size.length_squared() > 0.0:
			bounds = bounds.merge(foot.global_transform.affine_inverse() * descendant.global_transform * child_bounds)
	var envelope = BoxShape3D.new()
	envelope.size = bounds.size.max(Vector3(0.01, 0.01, 0.01))
	var excluded: Array[RID] = []
	_collect_excluded(foot, excluded)
	_collect_excluded(carriage, excluded)
	for rail in _rail_bodies:
		excluded.append(rail.get_rid())
	var radius = maxf(2.0, bounds.get_center().length() + bounds.size.length() * 0.5)
	var steps = SolidHandling.sweep_steps(from, to, radius, 0.035)
	var space = foot.get_world_3d().direct_space_state
	var query = PhysicsShapeQueryParameters3D.new()
	query.collision_mask = OBSTACLE_MASK
	query.exclude = excluded
	# Covers travel between the sampled poses, including the outer clamp fingers.
	query.margin = 0.003 + (from.origin.distance_to(to.origin) + from.basis.get_rotation_quaternion().angle_to(to.basis.get_rotation_quaternion()) * radius) / steps * 0.5
	var carriage_shapes = SolidHandling.shapes(carriage)
	var rotating_shapes = SolidHandling.shapes(rotator)
	for index in range(steps + 1):
		var pose = _guided_pose(from, to, float(index) / steps)
		query.shape = envelope
		query.transform = pose * Transform3D(Basis.IDENTITY, bounds.get_center())
		if not space.intersect_shape(query, 1).is_empty():
			return "Clear the foot's movement area and stand beside the controls."
		var carrier_pose = Transform3D(Basis.IDENTITY, Vector3(pose.origin.x, 0, pose.origin.z))
		for shape in carriage_shapes:
			query.shape = shape.shape
			query.transform = carrier_pose * shape.transform
			if not space.intersect_shape(query, 1).is_empty():
				return "Clear the carrier's rail route, including loose parts."
		for shape in rotating_shapes:
			query.shape = shape.shape
			query.transform = pose * shape.transform
			if not space.intersect_shape(query, 1).is_empty():
				return "Clear the turning clamps and stand beside the controls."
	return ""

func _collect_excluded(node: Node, excluded: Array[RID]) -> void:
	if node is CollisionObject3D:
		excluded.append(node.get_rid())
	for child in node.get_children():
		_collect_excluded(child, excluded)

func _make_rails() -> void:
	for x in [1.4, 3.2]:
		var rail = StaticBody3D.new()
		rail.collision_layer = 1
		add_child(rail)
		# Rails are flush strips: no kerb to block walking or a carried pad.
		_solid_box(rail, Vector3(x, 0.012, 1.3), Vector3(0.10, 0.024, 10.5), _steel)
		_rail_bodies.append(rail)
	for z in [-3.8, 6.4]:
		game.box(self, Vector3(2.3, 0.014, z), Vector3(2.2, 0.012, 0.08), _yellow)
	game.sign_panel(self, "FOOT / WORK BAY", Vector3(2.3, 3.15, -6.82), Vector2(1.75, 0.28), 52, 0.002)
	# A posted sign faces the operator standing at the dispatch controls.
	game.box(self, Vector3(3.35, 1.05, 6.65), Vector3(0.06, 2.10, 0.06), _steel)
	game.sign_panel(self, "DISPATCH / RETURN", Vector3(2.3, 2.10, 6.65), Vector2(2.2, 0.30), 56, 0.002)

func _make_carriage() -> void:
	carriage = AnimatableBody3D.new()
	carriage.name = "FootCarrier"
	carriage.collision_layer = 1
	carriage.collision_mask = 0
	carriage.sync_to_physics = false
	add_child(carriage)
	for x in [-0.9, 0.9]:
		# The lower runner fits between the wheel housings; its upper cap rests
		# on them. Splitting at that joint removes the coincident end faces while
		# preserving the original exterior solid and its collision shape.
		var runner_bottom = 0.17 - 0.18 / 2.0
		var runner_top = 0.17 + 0.18 / 2.0
		var wheel_top = 0.105 + 0.15 / 2.0
		var inner_wheel_end = 1.73 - 0.34 / 2.0
		game.box(carriage, Vector3(x, (wheel_top + runner_top) / 2.0, 0), Vector3(0.14, runner_top - wheel_top, 3.8), _dark)
		game.box(carriage, Vector3(x, (runner_bottom + wheel_top) / 2.0, 0), Vector3(0.14, wheel_top - runner_bottom, inner_wheel_end * 2.0), _dark)
		_box_collision(carriage, Vector3(x, 0.17, 0), Vector3(0.14, 0.18, 3.8))
		for z in [-1.73, 1.73]:
			_solid_box(carriage, Vector3(x, 0.105, z), Vector3(0.25, 0.15, 0.34), _steel)
	for z in [-1.72, 1.72]:
		# Inset the welded crossbar skin inside the runner's outer faces. The
		# collision dimensions remain unchanged, without coincident render faces.
		_solid_box(carriage, Vector3(0, 0.25, z), Vector3(1.94, 0.16, 0.19), _dark, Vector3(1.936, 0.16, 0.19))
		_solid_box(carriage, Vector3(0, 0.87, z), Vector3(0.22, 1.18, 0.22), _steel, Vector3(0.22, 1.18, 0.216))
		_solid_box(carriage, Vector3(0, 1.55, z), Vector3(0.44, 0.44, 0.22), _yellow)
		_cylinder(carriage, Vector3(0, 1.55, z), 0.145, 0.32, _dark)
	rotator = AnimatableBody3D.new()
	rotator.name = "FrameClamps"
	rotator.collision_layer = 1
	rotator.collision_mask = 0
	rotator.sync_to_physics = false
	carriage.add_child(rotator)
	# Offset clamp fingers meet frame rails above the sole/carrier. Both crossbars
	# and the bearing pedestals remain beyond the foot's +/-1.5 m end envelope.
	for z in [-1.58, 1.58]:
		_solid_box(rotator, Vector3(0, -0.25, z), Vector3(0.12, 0.50, 0.10), _steel, Vector3(0.12, 0.50, 0.096))
		_solid_box(rotator, Vector3(0, -0.50, z), Vector3(1.12, 0.10, 0.10), _yellow)
		for x in [-0.50, 0.50]:
			_solid_box(rotator, Vector3(x, -0.46, z * 0.93), Vector3(0.12, 0.12, 0.30), _steel, Vector3(0.116, 0.12, 0.30))
			game.box(rotator, Vector3(x, -0.38, z * 0.89), Vector3(0.14, 0.05, 0.13), _dark)

func _make_platform() -> void:
	var platform = StaticBody3D.new()
	platform.name = "AccessPlatform"
	platform.collision_layer = 1
	add_child(platform)
	_solid_box(platform, Vector3(4.25, 0.49, -1.6), Vector3(1.1, 0.12, 3.4), _steel)
	for x in [3.78, 4.72]:
		for z in [-3.15, -0.05]:
			_solid_box(platform, Vector3(x, 0.23, z), Vector3(0.08, 0.46, 0.08), _dark)
	# The 0.55 m deck has a shallow continuous ramp. Jumping is optional: every
	# point on the access path must remain reachable by ordinary walking.
	var ramp_points = PackedVector3Array([
		Vector3(3.7, 0, 0.1), Vector3(4.8, 0, 0.1),
		Vector3(3.7, 0.55, 0.1), Vector3(4.8, 0.55, 0.1),
		Vector3(3.7, 0, 2.3), Vector3(4.8, 0, 2.3)])
	var ramp_shape = ConvexPolygonShape3D.new()
	ramp_shape.points = ramp_points
	var collision = CollisionShape3D.new()
	collision.shape = ramp_shape
	platform.add_child(collision)
	var mesh = MeshInstance3D.new()
	mesh.name = "AccessRamp"
	var ramp = SurfaceTool.new()
	ramp.begin(Mesh.PRIMITIVE_TRIANGLES)
	ramp.set_smooth_group(-1)
	# Godot front faces wind clockwise. Close the underside too, so every
	# exterior of the wedge is visible with ordinary back-face culling.
	for index in [2, 3, 4, 3, 5, 4, 0, 2, 4, 1, 5, 3, 0, 1, 2, 1, 3, 2, 0, 4, 1, 1, 4, 5]:
		ramp.add_vertex(ramp_points[index])
	ramp.generate_normals()
	mesh.mesh = ramp.commit()
	mesh.material_override = _steel
	platform.add_child(mesh)
	# The inside edge stays open for reaching connections; railings face outward.
	for z in [-3.15, -1.6, -0.05]:
		_solid_box(platform, Vector3(4.76, 1.02, z), Vector3(0.055, 0.95, 0.055), _yellow)
	_solid_box(platform, Vector3(4.76, 1.49, -1.6), Vector3(0.06, 0.06, 3.2), _yellow)
	_solid_box(platform, Vector3(4.25, 1.49, -3.24), Vector3(1.06, 0.06, 0.06), _yellow)
	# Mount the entrance plaque on the last outer post, facing up the ramp.
	# Its width extends outward from the post, keeping the access path open.
	game.sign_panel(platform, "ACCESS PLATFORM", Vector3(5.13, 1.22, -0.01), Vector2(0.80, 0.24), 40, 0.0018)

func _make_console(origin: Vector3, dispatch: bool) -> void:
	var panel = StaticBody3D.new()
	panel.name = "DispatchControls" if dispatch else "FixtureControls"
	panel.collision_layer = 1
	panel.position = origin
	add_child(panel)
	if dispatch:
		_solid_box(panel, Vector3(0, 0.54, 0), Vector3(0.08, 1.08, 0.09), _steel)
		_solid_box(panel, Vector3(0, 0.05, 0), Vector3(0.36, 0.1, 0.4), _dark)
	else:
		# Short rail brackets support the panel outside the walking lane. Their
		# inset skins avoid coincident faces with the rail and control enclosure.
		for z in [-0.45, 0.45]:
			_solid_box(panel, Vector3(-0.11, 0.94, z), Vector3(0.20, 0.05, 0.045), _steel)
	_solid_box(panel, Vector3(0, 1.16, 0), Vector3(0.12, 0.48, 1.36 if not dispatch else 0.56), _dark)
	var actions = ["return"] if dispatch else ["upright", "sole_left", "sole_right", "transfer"]
	for index in range(actions.size()):
		var action: String = actions[index]
		var z = 0.0 if dispatch else -0.45 + float(index) * 0.3
		var node = game.box(panel, Vector3(-0.08, 1.2, z), Vector3(0.06, 0.11, 0.16), _yellow if action == "transfer" or dispatch else game.material(Color("79d8b8"), 0.1))
		var title = _pose_title(action) if POSE_ANGLES.has(action) else ("Return" if dispatch else "Transfer")
		game.sign_panel(panel, title, Vector3(-0.115, 1.04, z), Vector2(0.285, 0.10), 32, 0.0015, -PI / 2.0)
		_buttons.append({"type": "equipment", "point": node.global_position, "radius": 0.12, "action": action, "label": title, "node": node})
	# Small brackets bridge the status plate to the console above the buttons.
	for z in ([-0.20, 0.20] if dispatch else [-0.45, 0.45]):
		game.box(panel, Vector3(-0.05, 1.40, z), Vector3(0.12, 0.12, 0.04), _steel)
	var status = game.sign_panel(panel, "", Vector3(-0.10, 1.55, 0), Vector2(1.36 if not dispatch else 0.85, 0.30), 48, 0.0018, -PI / 2.0)
	if dispatch:
		_dispatch_label = status
	else:
		_work_label = status

func _solid_box(body: CollisionObject3D, position: Vector3, size: Vector3, mat: Material, visual_size: Vector3 = Vector3.ZERO) -> void:
	game.box(body, position, size if visual_size == Vector3.ZERO else visual_size, mat)
	_box_collision(body, position, size)

func _box_collision(body: CollisionObject3D, position: Vector3, size: Vector3) -> void:
	var shape = BoxShape3D.new()
	shape.size = size
	var collision = CollisionShape3D.new()
	collision.position = position
	collision.shape = shape
	body.add_child(collision)

func _cylinder(parent: Node3D, position: Vector3, radius: float, length: float, mat: Material) -> void:
	var mesh = MeshInstance3D.new()
	var cylinder = CylinderMesh.new()
	cylinder.top_radius = radius
	cylinder.bottom_radius = radius
	cylinder.height = length
	mesh.mesh = cylinder
	mesh.material_override = mat
	mesh.position = position
	mesh.rotation.x = PI / 2.0
	parent.add_child(mesh)

func _pose_title(pose: String) -> String:
	return {"upright": "Upright", "sole_left": "Sole left", "sole_right": "Sole right"}.get(pose, pose)

func _refresh_labels() -> void:
	if is_instance_valid(_work_label):
		_work_label.text = "FOOT FIXTURE\n" + ("CLEAR MOVEMENT AREA" if not blocked_reason.is_empty() else ("MOVING" if moving else _pose_title(work_pose)))
	if is_instance_valid(_dispatch_label):
		_dispatch_label.text = "DISPATCH\n" + ("CARRIER DOCKED" if at_dispatch else "RETURN CONTROL")
