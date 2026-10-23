extends "res://scripts/workshop_save.gd"
## Separate trial codec; the legacy upright-hoist validator is never reused.
const M2_VERSION = 2
func _leg_mode() -> bool:
	return false

func setup(workshop: Node, path_override: String = "", use_automatic: bool = true) -> void:
	game = workshop;automatic = use_automatic
	path = "user://m2-"+game.m2_trial+"-save.json" if path_override.is_empty() else path_override
	enabled = not path_override.is_empty() or (DisplayServer.get_name() != "headless" and not game.automated_test and not OS.get_cmdline_args().has("--script"))
	baseline = AssemblyModel.new();assert(baseline.configure(game.model.definitions,game.config).is_empty())
	var materials = {"m2":M2_VERSION,"trial":game.m2_trial,"definitions":game.model.definitions,"scenario":game.config,"sources":game.leg_content.sources,"geometry":FileAccess.get_sha256("res://assets/foot-fa01.glb")}
	var resources = ["m2_layout.gd","m2_rail.gd","m2_workshop.gd","m2_staging.gd","m2_access_lift.gd","m2_session.gd","m1_layout.gd","m1_blockout.gd","work_access_lift.gd","leg_source_geometry.gd"]
	resources.append_array(["m2_lift_shelf.gd"] if game.m2_trial == "retention" else ["service_crane.gd","service_crane_console.gd"])
	for resource in resources:
		materials[resource] = FileAccess.get_sha256("res://scripts/"+resource) if FileAccess.file_exists("res://scripts/"+resource) else "missing"
	fingerprint = JSON.stringify(materials).sha256_text()
	initial = capture()
	if enabled:
		game.get_tree().auto_accept_quit = false
		if game.get_tree().get_meta("m2_reset",false):
			game.get_tree().remove_meta("m2_reset");new_workshop()
		else:reload_save(true)
	_refresh()

func status_text() -> String:
	var title = "Hip retainer" if game.m2_trial == "retention" else "Crane delivery"
	return title+" · separate M2 save slot.\n"+(message if not message.is_empty() else ("Autosaves on pause, quit and every 30 seconds. Restart resets only this trial." if enabled else "Headless/test session; normal saves are untouched."))

func capture() -> Dictionary:
	var snapshot = super.capture()
	snapshot.world["m2"] = game.m2.capture()
	snapshot.world["access_lifts"] = {}
	for id in game.access_lifts:snapshot.world.access_lifts[str(id)] = game.access_lifts[id].capture()
	return snapshot

func validate(data: Variant) -> Array[String]:
	var errors = super.validate(data)
	if not errors.is_empty():return errors
	var w: Dictionary = data.world
	if not same_keys(w.get("access_lifts"),game.access_lifts.keys()):return ["M2 lift identities changed."]
	for id in game.access_lifts:
		if not w.access_lifts[id] is Dictionary:return ["Invalid lift snapshot."]
		errors = game.access_lifts[id].validate(w.access_lifts[id])
		if not errors.is_empty():return errors
	var candidate = AssemblyModel.new();candidate.configure(baseline.definitions,game.config);ModelSave.apply(data.model,candidate)
	for owner in initial.model.assemblies:
		var fixed_slots: Dictionary = initial.model.assemblies[owner].slots
		for sid in fixed_slots:
			if not str(fixed_slots[sid]).is_empty() and candidate.assemblies[owner].slots[sid] != fixed_slots[sid]:return ["Supplied construction changed outside this M2 example."]
	errors = game.m2.validate(w.get("m2"),candidate,w.access_lifts)
	if not errors.is_empty():return errors
	if not to_pose(w.fixtures.pelvis).is_equal_approx(to_pose(initial.world.fixtures.pelvis)):return ["Pelvis must remain anchored to its gantry."]
	var expected: Transform3D = game.m2.rail.rail_pose(w.m2.rail.path).load
	if not to_pose(w.fixtures.left_leg).is_equal_approx(expected):return ["Rail and leg transforms disagree."]
	for id in w.fixtures:
		var a: Dictionary = candidate.assemblies[id]
		if not a.parent.is_empty():
			var parent_pose = _saved_assembly_pose(a.parent,w,candidate)
			if not to_pose(w.fixtures[id]).is_equal_approx(_saved_mount_pose(a.parent,a.parent_slot,id,parent_pose)):return ["Mounted fixture pose disagrees with its parent."]
	return []

func apply_snapshot(snapshot: Dictionary) -> bool:
	if not validate(snapshot).is_empty():return false
	# Detach every fixture before base restoration; mount traversal then runs parent-first.
	for id in game.runtime.nodes:
		var node: Node3D = game.runtime.node(id)
		if node.get_parent() != game:node.reparent(game)
	if not super.apply_snapshot(snapshot):return false
	for id in game.access_lifts:game.access_lifts[id].apply(snapshot.world.access_lifts[id])
	game.m2.apply(snapshot.world.m2)
	for id in game.runtime.nodes:
		var body: CollisionObject3D = game.runtime.node(id)
		if body is AnimatableBody3D:PhysicsServer3D.body_set_mode(body.get_rid(),PhysicsServer3D.BODY_MODE_STATIC)
		body.force_update_transform()
		PhysicsServer3D.body_set_state(body.get_rid(),PhysicsServer3D.BODY_STATE_TRANSFORM,body.global_transform)
	game.set_paused(true)
	return true
