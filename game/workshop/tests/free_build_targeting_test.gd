extends "res://tests/kit/harness.gd"
## The reader supplies guidance; physical ready slots supply placement permission.
var game: Node
var driver: Node

func _initialize() -> void:
	run.call_deferred()

func blocker(position: Vector3, size: float = 0.16) -> StaticBody3D:
	var body = StaticBody3D.new()
	body.collision_layer = 1
	game.add_child(body)
	body.global_position = position
	var shape = CollisionShape3D.new()
	shape.shape = BoxShape3D.new()
	shape.shape.size = Vector3.ONE*size
	body.add_child(shape)
	return body

func run() -> void:
	game = load("res://scenes/workshop.tscn").instantiate();game.profile_override = "foot"
	root.add_child(game)
	driver = load("res://tests/kit/node_runner.gd").new()
	root.add_child(driver)
	driver.game = game
	await driver.frames(10)
	game.automated_test = true
	game.set_paused(false)
	game.model.move_assembly("pitch","station:prep3")
	game.automation.select_build("pitch")
	expect(game.automation.suspend_at_station("pitch","prep3").is_empty(),"Stage selected build at station")
	# Prepare the receiving cartridge through the same input-independent rules;
	# the following fasteners exercise the desktop targeting and click boundary.
	expect(game.model.carry_item("FA-514__001").is_empty() and game.model.install("pitch","FA-514__001","FA-514__001").ok,"Prepare a physical receiving cartridge at its station")
	game.components.sync("pitch")
	game.model.stock_pocket("w-12")
	game.hud.open_manual("pad_2",1)
	await driver.aim(game.components.slot_point("pitch","W-12__039"),1.2)
	expect(game.target.get("type","") == "component" and game.target.get("owner","") == "pitch" and game.ghost.visible,"A ready connection previews with an unrelated manual and page open")
	var first: String = game.target.get("sid","")
	var history: int = game.model.assemblies.pitch.history.size()
	driver.click()
	expect(game.model.assemblies.pitch.history.size() == history+1 and game.model.slot_definition("pitch",first).accepts == "w-12","Normal click installs compatible hardware outside the selected manual")
	expect(game.hud.manual_id == "pad_2" and game.hud.page == 1,"Successful placement keeps the reader on its chosen physical build and page")
	# A different ready family remains available without visiting another page.
	var bolt: String = ""
	for sid in game.components.definition("pitch").slots:
		var spec: Dictionary = game.model.slot_definition("pitch",sid)
		if spec.get("accepts","") == "h-12040" and spec.requires == [first]:bolt = sid;break
	game.model.stock_pocket("h-12040")
	await driver.aim(game.components.slot_point("pitch",bolt),1.2)
	history = game.model.assemblies.pitch.history.size()
	driver.click()
	expect(game.model.assemblies.pitch.history.size() == history+1,"A newly ready dependent bolt can be fitted without turning the manual")
	var next: String = ""
	for sid in game.components.definition("pitch").slots:
		var spec: Dictionary = game.model.slot_definition("pitch",sid)
		if spec.get("accepts","") == "w-12" and game.model.assemblies.pitch.slots[sid].is_empty() and spec.requires == ["FA-514__001"]:next = sid;break
	game.model.stock_pocket("h-12030")
	await driver.aim(game.components.slot_point("pitch",next),1.2)
	history = game.model.assemblies.pitch.history.size()
	driver.click()
	expect(game.target.get("type","") == "component" and game.model.assemblies.pitch.history.size() == history and game.hud.toast_label.text.contains("Compatible next component"),"Wrong variants still identify ready connections and explain the compatible component")
	driver.select_kind("w-12")
	await driver.aim(game.components.slot_point("pitch",next),game.REACH+1.0)
	history = game.model.assemblies.pitch.history.size()
	driver.click()
	expect(game.ghost.visible and game.ghost_material.albedo_color == game.SNAP_DISTANT_COLOR and game.model.assemblies.pitch.history.size() == history and game.hud.toast_label.text.contains("closer"),"Yellow discovery of an independent connection still requires actual physical reach to install")
	await driver.aim(game.components.slot_point("pitch",next),1.2)
	var point: Vector3 = game.target.point
	var obstacle = blocker(game.camera.global_position.lerp(point,0.7))
	await driver.frames(3)
	game.automation.refresh_target()
	game.automation.refresh_presentation()
	driver.click()
	expect(not game.ghost.visible and game.model.assemblies.pitch.history.size() == history and game.hud.toast_label.text.contains("obstructed"),"Scenery blocks preview and placement even with an open service fixture")
	# The service ray must continue beyond a receiver hit rather than accepting
	# that first surface while overlooking unrelated scenery farther along it.
	var receiver = blocker(game.camera.global_position.lerp(point,0.3))
	await driver.frames(3)
	expect(not game.targeting.can_see(point,[receiver,game.bodies.pitch],true),"Service ray tests scenery behind the receiving surface along the full segment")
	receiver.queue_free()
	obstacle.queue_free()
	await driver.frames(3)
	game.automation.refresh_target()
	game.automation.refresh_presentation()
	driver.click()
	expect(game.model.assemblies.pitch.history.size() == history+1,"Removing the real obstacle restores the same valid independent placement")
	var original: Dictionary = game.model.slot_definition("pitch",next).duplicate(true)
	game.model.definitions.assemblies.pitch_actuator.slots[next].target_offset = [-0.01,0.002,0]
	var source_target: Vector3 = game.components.slot_pose("pitch",next)*Vector3(-0.01,0.002,0)
	expect(game.components.slot_point("pitch",next).is_equal_approx(source_target),"Source-local target offsets follow the same rotated pose as their slot geometry")
	game.model.definitions.assemblies.pitch_actuator.slots[next].target = [0.15,0.25,-0.2]
	var authored: Vector3 = game.bodies.pitch.global_transform*Vector3(0.15,0.25,-0.2)
	expect(game.components.slot_point("pitch",next).is_equal_approx(authored),"Authored accessible connection points take priority over hidden mesh centers")
	game.model.definitions.assemblies.pitch_actuator.slots[next] = original
	game.hud.open_manual("pitch",12)
	game.hud.open_manual("pad_2",1)
	expect(game.components.service_access("pitch"),"Open-fixture service access belongs to the build policy independently of the reader")
	game.model.move_assembly("pitch","loose")
	expect(not game.components.candidates().any(func(c):return c.owner == "pitch"),"Loose unstationed builds cannot become arbitrary remote placement targets")
	# Reproduce the real closed-eye target ambiguity: two adjacent compatible
	# washers fit opposite cheeks, and only the near cheek is visible from here.
	game.model.move_assembly("pitch","station:prep3")
	game.automation.select_build("pitch")
	expect(game.automation.suspend_at_station("pitch","prep3").is_empty(),"Stage selected build at station")
	var staged: bool = true
	var reached: bool = false
	for step in game.components.definition("pitch").manual:
		if reached:break
		for sid in step.slots:
			if sid == "W-12__023":reached = true;break
			if not game.model.assemblies.pitch.slots[sid].is_empty():continue
			var spec: Dictionary = game.model.slot_definition("pitch",sid)
			var uid: String = game.model.find_item(spec.accepts,"bin")
			if game.model.definitions.parts[spec.accepts].carry_class == "pocket":
				game.model.stock_pocket(spec.accepts)
				uid = game.model.find_item(spec.accepts,"pocket")
			else:game.model.carry_item(uid)
			staged = game.model.install("pitch",sid,uid).ok and staged
	expect(staged and reached,"Prepare the closed rod eye through real dependencies for adjacent target regression")
	game.components.sync("pitch")
	game.model.stock_pocket("w-12")
	driver.select_kind("w-12")
	var eye_driver = load("res://tests/pitch_build_test.gd").new()
	root.add_child(eye_driver)
	eye_driver.game = game
	await eye_driver.aim_exterior_eye("pitch","W-12__023")
	expect(game.target.get("owner","") == "pitch" and game.target.get("sid","") == "W-12__023" and game.ghost.visible,"Generous aim prefers the visible ready washer over its occluded compatible neighbor")
	var visible_target: Dictionary = game.target.duplicate()
	game.target = {"type":"component","owner":"pitch","sid":"W-12__024","point":game.components.slot_point("pitch","W-12__024")}
	expect(not game.components.access().is_empty(),"The adjacent washer on the opposite cheek remains physically obstructed from this view")
	game.target = visible_target
	# Receiver-frame openings must remain open to the parent ring connection.
	var parent_staged: bool = true
	var parent_reached: bool = false
	for step in game.components.definition("foot").manual.slice(3,5):
		if parent_reached:break
		for sid in step.slots:
			if sid == "pitch/W-24__025":parent_reached = true;break
			var spec: Dictionary = game.model.slot_definition("foot",sid)
			var uid: String = game.model.find_item(spec.accepts,"bin")
			if game.model.definitions.parts[spec.accepts].carry_class == "pocket":
				game.model.stock_pocket(spec.accepts)
				uid = game.model.find_item(spec.accepts,"pocket")
			else:game.model.carry_item(uid)
			parent_staged = game.model.install("foot",sid,uid).ok and parent_staged
	expect(parent_staged and parent_reached,"Prepare both parent clevis receivers through independent valid dependencies")
	game.components.sync("foot")
	game.model.stock_pocket("washer")
	driver.select_kind("washer")
	await eye_driver.aim_parent_connection("foot","pitch/W-24__025")
	var parent_point: Vector3 = game.components.slot_point("foot","pitch/W-24__025")
	game.target = {"type":"component","owner":"foot","sid":"pitch/W-24__025","point":parent_point}
	expect(game.components.access().is_empty() and game.model.placement_error("foot","pitch/W-24__025",game.components.selected_uid(game.selected_kind)).is_empty(),"The real ring washer is accessible through the receiving frame's geometric opening")
	var parent_obstacle = blocker(game.camera.global_position.lerp(parent_point,0.5))
	await driver.frames(3)
	game.target = {"type":"component","owner":"foot","sid":"pitch/W-24__025","point":parent_point}
	expect(game.components.access().contains("obstructed"),"Precise receiver access still rejects unrelated scenery before the same washer")
	parent_obstacle.queue_free()
	await driver.frames(3)
	var receiving_source: Dictionary = game.source["FA-103__001"]
	var triangles: PackedVector3Array = receiving_source.mesh.get_faces()
	var receiver_pose: Transform3D = game.assembly_frame("foot")*receiving_source.transform
	var solid_found: bool = false
	var original_camera: Transform3D = game.camera.global_transform
	# Search actual triangle interiors for a front-facing solid patch with a clear
	# short outside approach. Its ray must hit the same source frame, not its AABB.
	for i in range(0,triangles.size(),3):
		var a: Vector3 = receiver_pose*triangles[i]
		var b: Vector3 = receiver_pose*triangles[i+1]
		var c: Vector3 = receiver_pose*triangles[i+2]
		var normal: Vector3 = (b-a).cross(c-a)
		if normal.length_squared() < 0.000001:continue
		normal = normal.normalized()
		var center: Vector3 = (a+b+c)/3.0
		var start: Vector3 = center+normal*0.20
		var end: Vector3 = center-normal*0.10
		var ray = PhysicsRayQueryParameters3D.create(start,end,game.WORLD_MASK)
		ray.exclude = [game.player.get_rid()]
		var hit: Dictionary = game.get_world_3d().direct_space_state.intersect_ray(ray)
		if hit.is_empty() or hit.collider != game.foot:continue
		var shape_owner: int = game.foot.shape_find_owner(hit.shape)
		var collision: Node = game.foot.shape_owner_get_owner(shape_owner)
		if collision.get_meta("source_uid","") != "FA-103__001":continue
		game.camera.global_position = start
		if not game.targeting.can_see(end,[game.foot],false):solid_found = true;break
	game.camera.global_transform = original_camera
	expect(solid_found,"Solid material in the same precise receiving frame continues to obstruct connection rays")
	expect(game.model.integrity_errors().is_empty(),"Independent targeting preserves physical identities, ownership and prerequisites")
	var passed: bool = checks.all(func(c):return c.passed)
	DirAccess.make_dir_recursive_absolute("res://verification/free-build-targeting")
	write_evidence("res://verification/free-build-targeting/headless-audit.json",{"passed":passed,"checks":checks})
	print("FREE_BUILD_TARGETING ","PASS" if passed else "FAIL"," ",checks.size()," checks")
	quit(0 if passed else 1)
