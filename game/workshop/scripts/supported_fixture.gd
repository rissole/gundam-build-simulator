class_name SupportedFootFixture
extends "res://scripts/equipment.gd"
## The receiving foot stays in the assembly model. This equipment only supports
## and repositions its existing body; a carriage is never another inventory item.
## In the hangar it stands at the foot's bay store without dispatch rails; the
## crane then collects the upright foot from the same pose.

const WORK_ORIGIN = Vector3(2.3, 1.55, -1.8)
const DISPATCH_ORIGIN = Vector3(2.3, 1.55, 4.4)
const ANGULAR_SPEED = PI / 8.0
const TRANSFER_SPEED = 0.65
const POSE_ANGLES = {"upright": 0.0, "sole_left": -PI / 2.0, "sole_right": PI / 2.0}
const OBSTACLE_MASK = 15
const Sweep = preload("res://scripts/motion_sweep.gd")
const Codec = preload("res://scripts/pose_codec.gd")

var foot: AnimatableBody3D
var work_origin = WORK_ORIGIN
var dispatch_origin = DISPATCH_ORIGIN
## False in the hangar, where the crane collects the foot instead of the carrier.
var has_dispatch = true
## The foot's model location while it rests in this fixture.
var holding_location = ""
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

## `placement.origin` moves the whole fixture so the upright foot rests there.
func setup(workshop: Node3D, receiving_foot: AnimatableBody3D, placement: Dictionary = {}) -> void:
	game = workshop
	equipment_id = "foot_fixture"
	click_operates = false
	foot = receiving_foot
	holding_location = game.model.assemblies[game.default_parent_id()].location
	if placement.has("origin"):
		work_origin = placement.origin
		has_dispatch = false
		# Static parts are authored around the component-room bay; shift them as one.
		position = Vector3(work_origin.x-WORK_ORIGIN.x, 0, work_origin.z-WORK_ORIGIN.z)
		dispatch_origin = work_origin
	_steel = game.material(Color("526970"), 0.55)
	_dark = game.material(Color("23353b"), 0.4)
	_yellow = game.material(Color("e8b46b"), 0.2)
	_make_rails()
	_make_carriage()
	_make_platform()
	# The working controls face inward from the platform's parallel outer rail.
	# An operator can turn the foot without leaving its connection access aisle.
	_make_console(Vector3(4.87, 0.55, -1.8), false)
	if has_dispatch:_make_console(Vector3(0.78, 0, 6.9), true)
	_apply_pose(Transform3D(Basis.IDENTITY, work_origin))
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
		return blocked_reason if not blocked_reason.is_empty() else "Wait for the foot rig to stop."
	if game.model.assemblies[game.default_parent_id()].location != holding_location:
		return "The foot has left its rig."
	var held_by: String = game.equipment.busy_reason("foot_fixture", equipment_id)
	if not held_by.is_empty():
		return held_by
	if action == "return":
		return "The foot rig is already in the Foot Bay." if not at_dispatch else ""
	if at_dispatch:
		return "Return the foot rig to the Foot Bay first."
	if action == "transfer":
		if not has_dispatch:
			return "Unknown foot rig control."
		if not game.model.milestone(game.default_parent_id(), "complete"):
			return "Secure both heel pads and the pitch actuator before transferring the foot."
		if work_pose != "upright":
			return "Set the foot upright before transferring it."
		return ""
	if not POSE_ANGLES.has(action):
		return "Unknown foot rig control."
	if action == work_pose:
		return "The foot rig is already in this working pose."
	return ""

func request(action: String) -> String:
	var error = action_error(action)
	if not error.is_empty():
		return error
	var next_dispatch = action == "transfer"
	var next_pose = "upright" if action == "transfer" or action == "return" else action
	var next_origin = dispatch_origin if next_dispatch else work_origin
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
			return "FOOT RIG PAUSED — " + blocked_reason
		if foot.global_position.distance_to(_destination.origin) > 0.01:
			return "FOOT RIG MOVING — " + ("dispatch" if _destination_dispatch else "Foot Bay")
		return "FOOT RIG TURNING — " + _pose_title(_destination_pose)
	if at_dispatch:
		return "DISPATCH — foot secured on the foot rig"
	return "FOOT RIG — " + _pose_title(work_pose)

## Rigging the foot needs it upright and still: the crane collects the store pose.
func busy_reason(subject: String) -> String:
	if subject == "rig:" + game.default_parent_id() and game.model.assemblies[game.default_parent_id()].location == holding_location:
		if moving:
			return "Wait for the foot rig to stop."
		if work_pose != "upright":
			return "Turn the foot rig upright before attaching the magnetic connectors."
	return ""

func access_error(owner: String) -> String:
	if not game.model.assemblies.has(owner) or game.model.top_level(owner) != game.default_parent_id():
		return ""
	if moving:
		return "Wait for the foot rig to stop before working on its connections."
	if at_dispatch:
		return "Return the foot to the assembly bay before changing its connections."
	return ""

## Saved as the foot workshop's `world.support`; keys are part of the pinned format.
func capture() -> Dictionary:
	return {"moving": moving, "at_dispatch": at_dispatch, "work_pose": work_pose, "destination_pose": _destination_pose, "destination_dispatch": _destination_dispatch}

func validate(data: Variant, candidate: AssemblyModel = null, world: Dictionary = {}) -> Array[String]:
	var s: Dictionary = data
	if not s.get("moving") is bool or not s.get("at_dispatch") is bool or not s.get("destination_dispatch") is bool:return ["Invalid foot support motion."]
	if not s.get("work_pose") is String or not POSE_ANGLES.has(s.work_pose) or not s.get("destination_pose") is String or not POSE_ANGLES.has(s.destination_pose):return ["Invalid foot working position."]
	var transform = Codec.to_pose(world.fixtures[game.default_parent_id()])
	var angle = atan2(transform.basis.x.y,transform.basis.x.x)
	var origin = transform.origin
	if not transform.basis.is_equal_approx(Basis(Vector3.BACK,angle)) or absf(angle)>PI/2+0.001 or absf(origin.x-work_origin.x)>0.001 or absf(origin.y-work_origin.y)>0.001 or origin.z < work_origin.z-0.001 or origin.z > dispatch_origin.z+0.001:return ["Foot has left its supported path."]
	if s.at_dispatch or s.destination_dispatch or origin.z > work_origin.z+0.001:
		# A carrier must never bypass the completion interlock through a save.
		if not candidate.milestone(game.default_parent_id(),"complete") or absf(angle)>0.001 or s.work_pose != "upright" or s.destination_pose != "upright":return ["Dispatch requires a secured upright foot."]
	if not s.moving:
		var expected = Transform3D(Basis(Vector3.BACK,POSE_ANGLES[s.work_pose]),dispatch_origin if s.at_dispatch else work_origin)
		if not transform.is_equal_approx(expected) or s.destination_pose != s.work_pose or s.destination_dispatch != s.at_dispatch:return ["Stopped foot does not match its indexed pose."]
	elif s.at_dispatch == s.destination_dispatch:
		var from_angle: float = POSE_ANGLES[s.work_pose]
		var to_angle: float = POSE_ANGLES[s.destination_pose]
		if s.at_dispatch or s.work_pose == s.destination_pose or not origin.is_equal_approx(work_origin) or angle < minf(from_angle,to_angle)-0.001 or angle > maxf(from_angle,to_angle)+0.001:return ["Turning foot is outside its indexed movement."]
	return []

func apply(data: Dictionary) -> void:
	moving = data.moving
	at_dispatch = data.at_dispatch
	work_pose = data.work_pose
	_destination_pose = data.destination_pose
	_destination_dispatch = data.destination_dispatch
	_destination = Transform3D(Basis(Vector3.BACK, POSE_ANGLES[data.destination_pose]), dispatch_origin if data.destination_dispatch else work_origin)
	blocked_reason = ""
	# At rest the indexed pose is authoritative (a reload starts from the fresh pose).
	# The foot follows only while this fixture still holds it.
	var pose: Transform3D = foot.global_transform if moving else Transform3D(Basis(Vector3.BACK, POSE_ANGLES[work_pose]), dispatch_origin if at_dispatch else work_origin)
	if game.model.assemblies[game.default_parent_id()].location == holding_location:
		_apply_pose(pose)
	else:
		carriage.global_position = Vector3(pose.origin.x, 0, pose.origin.z)
		rotator.global_transform = pose
	_refresh_labels()

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
	Sweep.collect_rids(foot, excluded)
	Sweep.collect_rids(carriage, excluded)
	for rail in _rail_bodies:
		excluded.append(rail.get_rid())
	var radius = maxf(2.0, bounds.get_center().length() + bounds.size.length() * 0.5)
	var steps = Sweep.steps(from, to, radius, 0.035)
	# Covers travel between the sampled poses, including the outer clamp fingers.
	var margin = 0.003 + (from.origin.distance_to(to.origin) + from.basis.get_rotation_quaternion().angle_to(to.basis.get_rotation_quaternion()) * radius) / steps * 0.5
	var groups = [
		{"shapes": [{"shape": envelope, "transform": Transform3D(Basis.IDENTITY, bounds.get_center())}], "margin": margin, "error": "Clear the foot's movement area and stand beside the controls."},
		{"shapes": Sweep.body_shapes(carriage), "frame": func(pose: Transform3D) -> Transform3D: return Transform3D(Basis.IDENTITY, Vector3(pose.origin.x, 0, pose.origin.z)), "margin": margin, "error": "Clear the foot rig route, including loose parts."},
		{"shapes": Sweep.body_shapes(rotator), "margin": margin, "error": "Clear the turning clamps and stand beside the controls."}]
	return Sweep.sweep(foot.get_world_3d().direct_space_state, groups, steps, func(weight: float) -> Transform3D: return _guided_pose(from, to, weight), OBSTACLE_MASK, excluded, "foot_fixture").get("error", "")

func _make_rails() -> void:
	# Without dispatch the rails only seat the carriage under the work position.
	var rail_center = 1.3 if has_dispatch else -1.8
	var rail_length = 10.5 if has_dispatch else 4.3
	for x in [1.4, 3.2]:
		var rail = StaticBody3D.new()
		rail.collision_layer = 1
		add_child(rail)
		# Rails are flush strips: no kerb to block walking or a carried pad.
		_solid_box(rail, Vector3(x, 0.012, rail_center), Vector3(0.10, 0.024, rail_length), _steel)
		_rail_bodies.append(rail)
	for z in ([-3.8, 6.4] if has_dispatch else [-4.0, 0.4]):
		game.box(self, Vector3(2.3, 0.014, z), Vector3(2.2, 0.012, 0.08), _yellow)
	if not has_dispatch:
		return
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
		# Pedestals rise from the crossbar to the bearing at the foot's work height.
		var bearing = work_origin.y
		var pedestal = bearing - 0.37
		_solid_box(carriage, Vector3(0, 0.28 + pedestal / 2.0, z), Vector3(0.22, pedestal, 0.22), _steel, Vector3(0.22, pedestal, 0.216))
		_solid_box(carriage, Vector3(0, bearing, z), Vector3(0.44, 0.44, 0.22), _yellow)
		_cylinder(carriage, Vector3(0, bearing, z), 0.145, 0.32, _dark)
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
	var actions = ["return"] if dispatch else (["upright", "sole_left", "sole_right", "transfer"] if has_dispatch else ["upright", "sole_left", "sole_right"])
	for index in range(actions.size()):
		var action: String = actions[index]
		var z = 0.0 if dispatch else -0.45 + float(index) * 0.3
		var node = game.box(panel, Vector3(-0.08, 1.2, z), Vector3(0.06, 0.11, 0.16), _yellow if action == "transfer" or dispatch else game.material(Color("79d8b8"), 0.1))
		var title = _pose_title(action) if POSE_ANGLES.has(action) else ("Return" if dispatch else "Transfer")
		game.sign_panel(panel, title, Vector3(-0.115, 1.04, z), Vector2(0.285, 0.10), 32, 0.0015, -PI / 2.0)
		_buttons.append(control_entry(node, action, title, 0.12, {"point": node.global_position}))
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
		_work_label.text = "FOOT RIG\n" + ("CLEAR MOVEMENT AREA" if not blocked_reason.is_empty() else ("MOVING" if moving else _pose_title(work_pose)))
	if is_instance_valid(_dispatch_label):
		_dispatch_label.text = "DISPATCH\n" + ("CARRIER DOCKED" if at_dispatch else "RETURN CONTROL")
