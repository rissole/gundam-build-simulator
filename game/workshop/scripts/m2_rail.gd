extends "res://scripts/m1_blockout.gd"
signal changed
func setup(workshop: Node3D, scene_layout: Node3D) -> void:
	game = workshop;layout = scene_layout
	load_body = game.runtime.node("left_leg")
	_collect(load_body,load_body.global_transform.affine_inverse())
	for body in game.runtime.nodes.values():
		if body is CollisionObject3D:excluded.append(body.get_rid())
	excluded.append_array(layout.hardware)
	_pose()
	game.model.changed.connect(_model_changed)
	for at in [Vector3(9.2,0,11.4),Vector3(5.1,0,24.2)]:_panel(at)

func _pose() -> void:
	var pose = rail_pose(path)
	if game.model.assemblies.left_leg.location == "support:m2_leg_rail":load_body.global_transform = pose.load
	layout.set_pose(pose.load,pose.z,pose.x)
	for member in game.runtime.descendants("left_leg"):
		var body: CollisionObject3D = game.runtime.node(member)
		if body is AnimatableBody3D:PhysicsServer3D.body_set_mode(body.get_rid(),PhysicsServer3D.BODY_MODE_STATIC)
		body.force_update_transform()
		PhysicsServer3D.body_set_state(body.get_rid(),PhysicsServer3D.BODY_STATE_TRANSFORM,body.global_transform)

func action_error(action: String) -> String:
	if game.paused:return "Resume the trial before moving equipment."
	if not action in ["advance","stop","return"]:return "Unknown rail command."
	if action == "stop":return "" if moving else "The fixture is stopped."
	if game.m2_trial == "crane":return "The crane example keeps the rail home. Finish the beam connection and stow both cables."
	if moving:return "Stop the motion before selecting a different direction."
	if action == "return" and retention_state() != "none":return RETENTION_BLOCKS_RETURN
	if action == "advance" and path >= 2.9999:return "One half does not secure the hip. Holder departure is outside M2."
	if action == "return" and path <= .001:return "The loaded fixture is already home."
	return ""

func request(action: String) -> String:
	var error = action_error(action)
	if not error.is_empty():
		if not moving:blocked_reason = error
		_refresh();return error
	if action == "return" and game.model.assemblies.left_leg.parent == "pelvis":
		var previous = load_body.global_transform
		var result: Dictionary = game.model.undo_supported("pelvis","m2_leg_rail")
		if not result.ok:return result.error
		load_body.reparent(game)
		load_body.global_transform = previous
		game.refresh_assembly_collision("pelvis")
		game.refresh_assembly_collision("left_leg")
		_pose()
	return super.request(action)

func physics(delta: float) -> void:
	var was_moving = moving
	super.physics(delta)
	if was_moving and not moving and blocked_reason.is_empty():path = goal;_pose()
	if was_moving and not moving and path >= 2.9999 and game.model.assemblies.left_leg.parent.is_empty():
		var result: Dictionary = game.model.install_supported("pelvis","left_leg","left_leg","m2_leg_rail")
		assert(result.ok,str(result))
		game.runtime.mount("pelvis","left_leg","left_leg")
		game.refresh_assembly_collision("pelvis")
		_pose()
	if was_moving:changed.emit()

func status_text() -> String:
	if game.m2_trial == "crane":return "CRANE DELIVERY / Rail stays home\nUse the central crane console. Fit all four flange pairs before stowing the magnetic ends."
	if not blocked_reason.is_empty():return "STOPPED / "+blocked_reason
	if moving:return "MOVING / "+(TITLES[clampi(floori(minf(path,goal)),0,2)] if goal > path else "Return · supported reverse")
	if path >= 2.9999:return "DOCKED / Rail still supports leg\nFit one half from the lift. One half does not secure the hip.\nRemove all retention before Return."
	return "M2 / "+next_action()+"\nE or click · Advance / Stop / Return"

func capture() -> Dictionary:
	return {"version":1,"path":path,"goal":goal,"moving":moving,"blocked_reason":blocked_reason,"support":"m2_leg_rail","parent":game.model.assemblies.left_leg.parent,"assisting":game.model.assemblies.left_leg.parent == "pelvis"}

func validate(data: Dictionary, candidate: AssemblyModel) -> Array[String]:
	if not (data.get("version") is int or data.get("version") is float) or not data.get("support") is String or not data.get("parent") is String:return ["Invalid M2 rail metadata."]
	if data.version != 1 or data.support != "m2_leg_rail":return ["Unsupported M2 rail state."]
	if not data.get("moving") is bool or not data.get("blocked_reason") is String or not data.get("assisting") is bool:return ["Invalid rail flags."]
	for key in ["path","goal"]:
		if not (data.get(key) is int or data.get(key) is float) or not is_finite(data[key]) or data[key] < 0 or data[key] > 3:return ["Invalid rail progress."]
	if not data.moving and absf(data.path-data.goal) > .0001:return ["Stopped rail has a pending target."]
	if data.moving and (is_equal_approx(data.path,data.goal) or data.goal != floorf(data.goal) or absf(data.path-data.goal)>1.001):return ["Invalid indexed rail motion."]
	var leg: Dictionary = candidate.assemblies.left_leg
	if data.parent != leg.parent or data.assisting != (leg.parent == "pelvis"):return ["Rail assistance disagrees with leg owner."]
	if leg.parent == "pelvis":
		if absf(data.path-3)>0.0001 or data.moving:return ["Mounted leg must remain docked on its rail."]
	elif leg.location != "support:m2_leg_rail":return ["Leg has no authorized rail support."]
	if game.m2_trial == "crane" and (data.path != 0 or data.goal != 0 or data.moving):return ["Crane trial rail must stay home."]
	return []

func apply(data: Dictionary) -> void:
	path = data.path;goal = data.goal;moving = data.moving;blocked_reason = data.blocked_reason
	_pose();_refresh()
