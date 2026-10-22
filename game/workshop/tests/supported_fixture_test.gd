extends SceneTree
## Exercise the complete workshop, its physical controls and its supported load.
## Stage child internals through the model; essential mounting and fastening use
## the same camera rays, carried bodies and input handlers as ordinary play.
var game: Node
var driver: Node
var checks: Array[Dictionary] = []
var fixture: Node

func _initialize() -> void:
	run.call_deferred()

func expect(ok: bool, label: String) -> void:
	checks.append({"check":label,"passed":ok})
	print("CHECK ","PASS " if ok else "FAIL ",label)
	if not ok:push_error(label)

func finish() -> void:
	checks.append_array(driver.checks)
	var passed: bool = checks.all(func(check):return check.passed)
	DirAccess.make_dir_recursive_absolute("res://verification/supported-fixture")
	FileAccess.open("res://verification/supported-fixture/headless-audit.json",FileAccess.WRITE).store_string(JSON.stringify({"passed":passed,"checks":checks,"engine":Engine.get_version_info().string,"rendered":false},"  "))
	print("SUPPORTED_FIXTURE ","PASS" if passed else "FAIL"," ",checks.size()," checks")
	game.chime.stop()
	game.chime.stream = null
	await driver.frames(4)
	quit(0 if passed else 1)

func look_from(point: Vector3, feet: Vector3) -> void:
	game.player.global_position = feet
	game.player.velocity = Vector3.ZERO
	var direction: Vector3 = point-game.camera.global_position
	game.player.rotation = Vector3(0,atan2(-direction.x,-direction.z),0)
	game.camera.rotation = Vector3(atan2(direction.y,Vector2(direction.x,direction.z).length()),0,0)
	await driver.frames(5)
	game._update_target()
	game._update_ghost()

func control(action: String) -> Dictionary:
	for button in fixture.controls():
		if button.action == action:return button
	return {}

func aim_control(action: String, distance: float = 1.0) -> void:
	var point: Vector3 = control(action).point
	# Work controls are operated from the raised deck; dispatch stays at floor
	# level. Use the same ordinary character and camera as connection access.
	var height = 0.025 if action == "return" else 0.575
	await look_from(point,Vector3(point.x-distance,height,point.z))

func operate(action: String) -> bool:
	await aim_control(action)
	var targeted: bool = game.target.get("type","") == "equipment" and game.target.get("action","") == action
	expect(targeted,"Aim identifies the physical "+action+" control")
	driver.key(KEY_E)
	expect(fixture.moving,"E starts the powered "+action+" operation")
	if not fixture.moving:print("EQUIPMENT_DIAGNOSTIC ",action," ",game.hud.toast_label.text)
	return targeted and fixture.moving

func settle(max_frames: int = 1000) -> bool:
	for tick in range(max_frames):
		if not fixture.moving:return true
		await driver.frames(1)
	print("EQUIPMENT_TIMEOUT ",fixture.status_text())
	return false

func obstacle(point: Vector3, layer: int = 1) -> StaticBody3D:
	var body = StaticBody3D.new()
	body.collision_layer = layer
	game.add_child(body)
	body.global_position = point
	var collision = CollisionShape3D.new()
	collision.shape = BoxShape3D.new()
	collision.shape.size = Vector3(0.36,0.6,0.36)
	body.add_child(collision)
	return body

func stage_child(owner: String, station: String) -> bool:
	game.model.move_assembly(owner,"station:"+station)
	game._activate(owner)
	game._set_pad_station(station)
	var ok = true
	var definition: Dictionary = game.model.definitions.assemblies[game.model.assemblies[owner].definition]
	for pass_index in range(definition.slots.size()):
		var changed = false
		for sid in definition.slots:
			if not game.model.assemblies[owner].slots[sid].is_empty():continue
			var spec: Dictionary = definition.slots[sid]
			if spec.has("assembly"):continue
			if not spec.requires.all(func(required):return not game.model.assemblies[owner].slots[required].is_empty()):continue
			var uid: String = game.model.find_item(spec.accepts,"bin")
			if game.model.definitions.parts[spec.accepts].carry_class == "pocket":
				game.model.stock_pocket(spec.accepts)
				uid = game.model.find_item(spec.accepts,"pocket")
			else:game.model.carry_item(uid)
			if uid.is_empty():continue
			ok = game.model.install(owner,sid,uid).ok and ok
			changed = true
		if not changed:break
	if game.components.is_component_build(owner):game.components.sync(owner)
	else:game._sync_installed_visuals()
	return ok and game.model.milestone(owner,"prepared")

func mount_pad(owner: String, slot: String) -> bool:
	game._activate(owner)
	await driver.aim(game.bodies[owner].global_position)
	driver.key(KEY_E)
	await driver.frames(40)
	expect(game.held_build() == owner,"Prepared "+owner+" retains its two-handed grip")
	var point: Vector3 = game.mount_point(slot,"foot",owner)
	var body_point: Vector3 = game.foot.global_transform*SolidHandling.bounds(game.foot).get_center()
	await look_from(body_point,Vector3(body_point.x-3.0,0.025,body_point.z))
	expect(game.target.get("type","") == "mount" and game.target.get("discovery_only",false) and game.ghost.visible and game.ghost_material.albedo_color == game.SNAP_DISTANT_COLOR,"Aiming at the foot body reveals a yellow destination for carried "+owner)
	await look_from(point,Vector3(point.x-3.0,0.025,point.z))
	expect(game.target.get("mount","") == slot and game.ghost.visible and game.ghost_material.albedo_color == game.SNAP_DISTANT_COLOR,"Carried "+owner+" shows its yellow mounting preview beyond reach")
	driver.click()
	expect(game.held_build() == owner and game.model.assemblies.foot.slots[slot].is_empty(),"Yellow mounting guidance cannot remotely install "+owner)
	await look_from(point,Vector3(point.x-1.1,0.025,point.z))
	await driver.frames(100)
	game._update_target()
	game._update_ghost()
	expect(game.target.get("mount","") == slot and game.ghost.visible,"Supported sole exposes the "+slot+" carrying preview")
	driver.click()
	var mounted: bool = game.model.assemblies.foot.slots[slot] == owner
	expect(mounted,"Ordinary carried placement seats "+owner+" on the supported foot")
	if not mounted:
		print("PAD_FIXTURE_DIAGNOSTIC ",game.target," ",game.hud.toast_label.text)
		return false
	for index in range(4):
		for kind in ["washer","bolt"]:
			if game.model.find_item(kind,"pocket").is_empty():await driver.collect_kind(kind)
			else:driver.select_kind(kind)
			game._activate(owner)
			point = game.connection(index)
			if index == 0 and kind == "washer":
				await look_from(point,Vector3(point.x-3.0,0.025,point.z))
				expect(game.target.get("type","") == "slot" and game.ghost.visible and game.ghost_material.albedo_color == game.SNAP_DISTANT_COLOR,"Mounted "+owner+" exposes yellow distant hardware guidance")
			await look_from(point,Vector3(point.x-1.1,0.025,point.z))
			driver.click()
			var fitted: bool = not game.builds[owner].slots[kind][index].is_empty()
			expect(fitted,"Physical sole access fits %s %s %d"%[owner,kind,index])
			if not fitted:
				print("PAD_FASTENER_DIAGNOSTIC ",game.target," ",game.hud.toast_label.text)
				return false
	return true

func mounted_follow() -> bool:
	# Mounted children delegate their collision to the foot's compound. Compare
	# the actual physics server root as well as every visual/body child frame.
	var foot_physics: Transform3D = PhysicsServer3D.body_get_state(game.foot.get_rid(),PhysicsServer3D.BODY_STATE_TRANSFORM)
	var ok: bool = foot_physics.is_equal_approx(game.foot.global_transform)
	for child in ["pad_1","pad_2","pitch"]:
		if game.model.assemblies[child].parent != "foot":continue
		var slot: String = game.model.assemblies[child].parent_slot
		var expected: Transform3D = game.runtime.mount_pose("foot",slot,child)
		var body: RigidBody3D = game.bodies[child]
		var physics_pose: Transform3D = PhysicsServer3D.body_get_state(body.get_rid(),PhysicsServer3D.BODY_STATE_TRANSFORM)
		ok = ok and body.global_transform.is_equal_approx(expected) and physics_pose.is_equal_approx(expected)
		ok = ok and body.freeze and body.freeze_mode == RigidBody3D.FREEZE_MODE_STATIC and body.collision_layer == 0
		for visual in body.get_children():
			if visual is MeshInstance3D and visual.has_meta("component_uid"):
				var sid: String = game.model.items[visual.get_meta("component_uid")].slot
				ok = ok and visual.global_transform.is_equal_approx(game.components.slot_pose(child,sid))
	return ok

func check_ramp_geometry() -> void:
	var ramp: MeshInstance3D = fixture.get_node("AccessPlatform/AccessRamp")
	var arrays: Array = ramp.mesh.surface_get_arrays(0)
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var indices = PackedInt32Array()
	if arrays[Mesh.ARRAY_INDEX] != null:
		indices = arrays[Mesh.ARRAY_INDEX]
	var center = Vector3(4.25, 0.55 / 3.0, (0.1 + 0.1 + 2.3) / 3.0)
	var outward = not vertices.is_empty() and normals.size() == vertices.size()
	var count = indices.size() if not indices.is_empty() else vertices.size()
	for offset in range(0, count, 3):
		var ids = [offset, offset + 1, offset + 2]
		if not indices.is_empty():
			ids = [indices[offset], indices[offset + 1], indices[offset + 2]]
		var midpoint: Vector3 = (vertices[ids[0]] + vertices[ids[1]] + vertices[ids[2]]) / 3.0
		for index in ids:
			outward = outward and normals[index].dot(midpoint - center) > 0.0001
	expect(outward and count == 24, "The complete access ramp has outward-facing slope, sides and underside")
	var bounds: AABB = ramp.mesh.get_aabb()
	expect(bounds.position.is_equal_approx(Vector3(3.7, 0, 0.1)) and bounds.size.is_equal_approx(Vector3(1.1, 0.55, 2.2)), "The visible ramp matches the ordinary walking collision route")

func run() -> void:
	game = load("res://scenes/workshop.tscn").instantiate()
	root.add_child(game)
	driver = load("res://tests/pitch_build_test.gd").new()
	root.add_child(driver)
	driver.game = game
	game.automated_test = true
	await driver.frames(10)
	game.set_paused(false)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	fixture = game.foot_fixture
	expect(fixture != null and fixture.work_pose == "upright","The full workshop starts with a supported upright foot")
	if fixture == null:await finish();return
	check_ramp_geometry()
	var identities: Array = game.model.items.keys()
	expect(identities.size() == 135,"Equipment adds no physical build identities")
	await driver.aim(game.foot.global_position,2.5)
	var initial: Transform3D = game.foot.global_transform
	driver.key(KEY_R)
	var drag = InputEventMouseMotion.new()
	drag.relative = Vector2(120,70)
	game.handle_desktop_input(drag)
	driver.release(KEY_R)
	driver.key(KEY_F)
	game.reset_station("foot")
	expect(game.foot.global_transform.is_equal_approx(initial),"Free mouse rotation and reset leave the supported foot fixed")
	await aim_control("sole_left",3.5)
	driver.key(KEY_E)
	expect(not fixture.moving and game.hud.toast_label.text.contains("reach"),"Equipment controls enforce the ordinary character reach")
	await aim_control("sole_left")
	var point: Vector3 = control("sole_left").point
	var blocker = obstacle(game.camera.global_position.lerp(point,0.5))
	await driver.frames(3)
	game._update_target()
	driver.key(KEY_E)
	expect(not fixture.moving,"An intervening solid blocks operation of a hidden control")
	blocker.queue_free()
	await driver.frames(3)
	await aim_control("transfer")
	driver.key(KEY_E)
	expect(not fixture.moving and game.hud.toast_label.text.contains("Secure"),"The dispatch control requires completed pads and actuator")
	# Walk the complete access route using character collisions and ordinary W.
	game.player.global_position = Vector3(4.25,0.025,2.65)
	game.player.rotation = Vector3.ZERO
	game.player.velocity = Vector3.ZERO
	driver.hold(KEY_W,true)
	await driver.frames(80)
	driver.hold(KEY_W,false)
	await driver.frames(10)
	expect(game.player.global_position.y > 0.50 and game.player.global_position.z < 0.1 and game.player.is_on_floor(),"Ordinary walking climbs the continuous ramp onto the access platform")
	# Walk alongside the foot to the new controls, including past their rail
	# brackets. The panel must neither consume the deck nor require a floor aim.
	driver.hold(KEY_W,true)
	await driver.frames(23)
	driver.hold(KEY_W,false)
	await driver.frames(5)
	expect(game.player.global_position.z < -1.8 and game.player.global_position.y > 0.50 and game.player.is_on_floor(),"The rail-mounted controls leave the platform walking lane open")
	for action in ["upright","sole_left","sole_right","transfer"]:
		var button: Dictionary = control(action)
		await look_from(button.point,Vector3(4.10,0.575,button.point.z))
		expect(game.player.is_on_floor() and game.player.global_position.y > 0.50 and game.target.get("action","") == action and game.camera.global_position.distance_to(button.point) <= game.REACH,"Standing on the platform reaches the inward-facing "+action+" control")
	expect(stage_child("pad_1","prep"),"Stage the small preparation task separately from the receiving foot")
	game.model.undo("pad_1")
	game._activate("pad_1")
	game._sync_installed_visuals()
	expect(not game.model.milestone("pad_1","prepared"),"One sleeve remains to finish at the hand-sized preparation station")
	if not await operate("sole_left"):await finish();return
	await driver.frames(20)
	var moving_pose: Transform3D = game.foot.global_transform
	expect(not moving_pose.is_equal_approx(initial) and fixture.moving,"Powered positioning advances continuously toward its working pose")
	game.set_paused(true)
	await driver.frames(20)
	expect(game.foot.global_transform.is_equal_approx(moving_pose),"Pause freezes powered fixture movement")
	game.set_paused(false)
	driver.select_kind("sleeve")
	game._activate("pad_1")
	await driver.aim(game.connection(3))
	driver.click()
	expect(fixture.moving and game.model.milestone("pad_1","prepared"),"Hand-sized preparation remains available while the distant foot fixture moves")
	expect(await settle() and fixture.work_pose == "sole_left","Resuming completes the guided sole working position")
	for entry in [["pad_1","prep","heel_1"],["pad_2","prep2","heel_2"]]:
		expect(stage_child(entry[0],entry[1]),"Prepare "+entry[0]+" through its actual inventory rules")
		if not await mount_pad(entry[0],entry[2]):await finish();return
	expect(stage_child("pitch","prep3"),"Prepare all actuator internals with their authored prerequisites")
	for page in game.components.definition("foot").manual.slice(3,5):
		for sid in page.slots:
			if not await driver.place_slot("foot",sid):await finish();return
	await driver.aim(game.bodies.pitch.global_position)
	driver.key(KEY_E)
	await driver.frames(40)
	await driver.aim(Vector3(-6.4,1.5,1.8))
	await driver.frames(100)
	await driver.aim(game.mount_point("pitch","foot","pitch"),1.2)
	await driver.frames(100)
	game._update_target()
	game._update_ghost()
	expect(game.ghost.visible and game.target.get("mount","") == "pitch","The upright fixture permits carrying the complete actuator to its clevises")
	driver.click()
	expect(game.model.assemblies.foot.slots.pitch == "pitch","Normal input mounts the actuator beside both prepared pads")
	if game.model.assemblies.foot.slots.pitch.is_empty():await finish();return
	for sid in game.components.definition("foot").manual[5].slots:
		if sid == "pitch":continue
		if not await driver.place_slot("foot",sid):await finish();return
	expect(game.model.milestone("foot","complete"),"All mounted children and retention hardware complete the current foot build")
	# Resolve a real ready target, start machinery, then click before the next
	# targeting refresh. The access guard must reject this ordinary input race.
	game.hud.open_manual("foot")
	driver.key(KEY_Z)
	var pending_sid = "pitch/H-12030__030"
	driver.select_kind("h-12030")
	await driver.aim_parent_connection("foot",pending_sid)
	expect(game.target.get("sid","") == pending_sid,"The last keeper screw has a real reachable target before motion")
	var pending_history: int = game.model.assemblies.foot.history.size()
	var request_error: String = fixture.request("sole_right")
	expect(request_error.is_empty() and fixture.moving,"The loaded fixture begins a turn while a parent target is pending")
	if not fixture.moving:await finish();return
	driver.click()
	expect(game.model.assemblies.foot.history.size() == pending_history and game.model.assemblies.foot.slots[pending_sid].is_empty(),"A click on a previously ready parent target cannot install hardware during motion")
	# Follow all three mounted bodies between frame boundaries throughout a turn.
	var follows = true
	var changes = 0
	var previous: Transform3D = game.foot.global_transform
	for tick in range(600):
		if not fixture.moving:break
		await process_frame
		follows = mounted_follow() and follows
		await driver.frames(1)
		follows = mounted_follow() and follows
		if not previous.is_equal_approx(game.foot.global_transform):changes += 1
		previous = game.foot.global_transform
	expect(follows and changes > 30,"All mounted children, meshes and physics frames follow the continuously moving support")
	expect(not fixture.moving and fixture.work_pose == "sole_right","Loaded fixture reaches the opposite sole position")
	if not await driver.place_slot("foot",pending_sid):await finish();return
	expect(fixture.work_pose == "upright" and game.model.milestone("foot","complete"),"Returning upright restores access to the pending keeper screw before transfer")
	# A player or loose obstacle anywhere ahead blocks the full transport route.
	game.player.global_position = Vector3(2.3,0.025,1.5)
	game.player.velocity = Vector3.ZERO
	await driver.frames(3)
	expect(not fixture.request("transfer").is_empty() and not fixture.moving,"The carrier refuses a route occupied by the player")
	await aim_control("transfer")
	for layer in [1,2]:
		blocker = obstacle(Vector3(2.3,1.15,1.5),layer)
		await driver.frames(3)
		driver.key(KEY_E)
		expect(not fixture.moving,("Fixed scenery" if layer == 1 else "A loose solid")+" on the rail route prevents transfer")
		blocker.queue_free()
		await driver.frames(3)
	if not await operate("transfer"):await finish();return
	await driver.frames(25)
	blocker = obstacle(Vector3(2.3,1.15,2.5),2)
	game.hud.open_manual("foot")
	var before_undo: int = game.model.assemblies.foot.history.size()
	driver.key(KEY_Z)
	expect(game.model.assemblies.foot.history.size() == before_undo and not game.equipment_access_error("foot").is_empty(),"Parent editing and undo stay locked while the loaded carrier moves")
	for tick in range(700):
		if not fixture.blocked_reason.is_empty():break
		await driver.frames(1)
	var stopped: Transform3D = game.foot.global_transform
	await driver.frames(20)
	expect(fixture.moving and not fixture.blocked_reason.is_empty() and game.foot.global_transform.is_equal_approx(stopped),"An obstacle introduced during transport stops the carrier before contact")
	blocker.queue_free()
	await driver.frames(3)
	expect(await settle() and fixture.at_dispatch,"Clearing the obstruction resumes transport to the dispatch bay")
	expect(mounted_follow(),"The transported assembly retains all mounted body and collision relationships")
	driver.key(KEY_Z)
	expect(game.model.assemblies.foot.history.size() == before_undo and not game.equipment_access_error("foot").is_empty(),"The dispatch bay requires a return before editing the foot")
	if not await operate("return"):await finish();return
	expect(await settle() and not fixture.at_dispatch and game.foot.global_transform.is_equal_approx(initial),"The return control brings the same assembly back to its work bay")
	driver.key(KEY_Z)
	expect(game.model.assemblies.foot.history.size() == before_undo-1 and not game.model.milestone("foot","complete"),"Parent undo resumes normally after the carrier returns")
	expect(game.model.items.keys() == identities and game.model.integrity_errors().is_empty(),"Turning, transfer and undo conserve all 135 identities and their valid ownership")
	await finish()
