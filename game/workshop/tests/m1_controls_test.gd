extends "res://tests/save_resume_test.gd"
## Walks from spawn and operates camera-targeted controls through desktop input.
## Geometry/load preparation belongs to the disclosed M1 setup, never this test.
var trial: Node3D

func key(code: Key, pressed: bool = true) -> void:
	var event = InputEventKey.new();event.physical_keycode = code;event.pressed = pressed
	game.handle_desktop_input(event)

func look(point: Vector3) -> void:
	var direction = point-game.camera.global_position
	game.player.rotation = Vector3(0,atan2(-direction.x,-direction.z),0)
	game.camera.rotation = Vector3(atan2(direction.y,Vector2(direction.x,direction.z).length()),0,0)
	game._update_target()

func walk(point: Vector3, label: String) -> bool:
	var arrived = false
	for tick in range(1600):
		var offset = point-game.player.global_position;offset.y = 0
		if offset.length() < .09:arrived = true;break
		game.player.rotation.y = atan2(-offset.x,-offset.z);game.camera.rotation.x = 0
		key(KEY_W);await frames(1)
	key(KEY_W,false);await frames(10)
	if not arrived:print("M1_WALK ",label," feet=",game.player.global_position," destination=",point)
	expect(arrived and game.player.is_on_floor(),"Ordinary walking reaches "+label)
	return arrived

func press(entry: Dictionary, click: bool = false, expected_error: String = "") -> bool:
	look(entry.node.global_position)
	await frames(2)
	game._update_target()
	var found: bool = game.target.get("node") == entry.node and game._access([]) == expected_error
	if not found:print("M1_TARGET ",entry.action," feet=",game.player.global_position," target=",game.target," access=",game._access([]))
	expect(found,"Ordinary aim reaches "+entry.action)
	if not found:return false
	if click:
		var event = InputEventMouseButton.new();event.button_index = MOUSE_BUTTON_LEFT;event.pressed = true
		game.handle_desktop_input(event)
	else:key(KEY_E);key(KEY_E,false)
	if not expected_error.is_empty():
		expect(game.hud.toast_label.text == expected_error and game.hud.target_label.text.contains(expected_error),"Rejected "+("click" if click else "E")+" explains the dock interlock in toast and aim prompt")
		expect(trial.labels.all(func(label):return label.text.contains(expected_error)),"Both physical consoles explain blocked "+entry.action)
	return true

func button(action: String, bay: bool = false) -> Dictionary:
	return trial.controls()[(3 if bay else 0)+["advance","stop","return"].find(action)]

func settle() -> bool:
	for tick in range(1100):
		if not trial.moving:return trial.blocked_reason.is_empty()
		await frames(1)
	return false

func run() -> void:
	game = load("res://scenes/workshop.tscn").instantiate();game.m1_blockout = true
	root.add_child(game);game.automated_test = true;game.set_paused(false)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	trial = game.m1
	await frames(8)
	await walk(Vector3(8.3,0,11.4),"source control aisle from trial spawn")
	await press(button("advance"))
	await frames(30)
	expect(trial.path > .02 and trial.moving,"E begins real supported rail travel")
	await press(button("stop"),true)
	var stopped: float = trial.path
	await frames(20)
	expect(not trial.moving and is_equal_approx(trial.path,stopped),"Click Stop holds the populated load")
	await press(button("return"))
	expect(await settle() and is_zero_approx(trial.path),"Return reverses a stopped partial trip")
	await press(button("advance"),true)
	await walk(Vector3(4.3,0,11.4),"west bypass clear of load")
	await walk(Vector3(4.3,0,24.2),"final-bay controls along open route")
	expect(await settle() and is_equal_approx(trial.path,1.0),"Travel reaches final bay while player walks alongside")
	for index in range(1,3):
		await press(button("advance",true),index%2 == 0)
		var finished = await settle()
		if not finished:print("M1_CONTROL_BLOCKED ",trial.path," ",trial.blocked_reason)
		expect(finished and is_equal_approx(trial.path,float(index+1)),"E/click finishes loaded route stage "+str(index+1))
		if not finished:break
	var dock_model = JSON.stringify({"items":game.model.items,"assemblies":game.model.assemblies})
	var dock_pose: Transform3D = trial.load_body.global_transform
	for click in [false,true]:
		await press(button("advance",true),click,trial.RETENTION_REQUIRED)
		await frames(3)
		expect(is_equal_approx(trial.path,3) and is_equal_approx(trial.goal,3) and not trial.moving and trial.load_body.global_transform.is_equal_approx(dock_pose) and JSON.stringify({"items":game.model.items,"assemblies":game.model.assemblies}) == dock_model,"Rejected dock input preserves pose, path, goal and physical ownership")
		expect(game.model.support_occupant("m1_leg_rail") == "left_leg" and trial.layout.contacts.all(func(contact):return contact.kind == "rail"),"Holder remains sole load support after rejected dock input")

	# Isolated interlock fixture, using real model APIs and the same walked-to
	# console. This stages later retention solely for rejection coverage; it is
	# not evidence of a playable mounting/retainer interaction in M1.
	expect(game.model.transfer_supported_assembly("left_leg","m1_leg_rail","leg_hoist").is_empty() and game.model.install_supported("pelvis","left_leg","left_leg","leg_hoist").ok,"Test-only setup stages real pelvis ownership for input interlock probe")
	game.runtime.mount("pelvis","left_leg","left_leg")
	var ring_uid: String = game.model.find_item("pv-ring-half","support:pelvis_ring_rack_1")
	expect(game.model.install_supported("pelvis","ring_1",ring_uid,"pelvis_ring_rack_1").ok,"Test-only setup stages first real retainer half")
	game.components.sync("pelvis")
	var retained_model = JSON.stringify({"items":game.model.items,"assemblies":game.model.assemblies})
	var retained_pose: Transform3D = trial.load_body.global_transform
	for click in [false,true]:
		await press(button("return",true),click,trial.RETENTION_BLOCKS_RETURN)
		await frames(3)
		expect(not trial.moving and is_equal_approx(trial.path,3) and is_equal_approx(trial.goal,3) and trial.load_body.global_transform.is_equal_approx(retained_pose) and JSON.stringify({"items":game.model.items,"assemblies":game.model.assemblies}) == retained_model,"Rejected partial-retention Return preserves real mounted model and pose")
	expect(game.model.undo_supported("pelvis","pelvis_ring_rack_1").ok and game.model.undo_supported("pelvis","leg_hoist").ok and game.model.transfer_supported_assembly("left_leg","leg_hoist","m1_leg_rail").is_empty(),"Test-only teardown restores ordinary unfastened rail-owned sample")
	trial.load_body.reparent(game);game.components.sync("pelvis");trial._pose()

	await walk(Vector3(4.3,0,20.0),"open route to front personnel lift")
	await walk(Vector3(9.6,0,20.0),"lift boarding approach")
	await walk(Vector3(9.6,0,24.3),"ramp and personnel lift deck without jumping")
	var lift = game.access_lifts.hip
	var up: Dictionary
	var ground: Dictionary
	for entry in lift.controls():
		if entry.action == "up":up = entry
		if entry.action == "ground" and entry.node.get_parent() == lift.deck:ground = entry
	await press(up,true)
	for tick in range(1000):
		if not lift.moving:break
		await frames(1)
	print("M1_LIFT height=",lift.height," feet=",game.player.global_position," blocked=",lift.blocked_reason)
	expect(is_equal_approx(lift.height,8.4) and absf(game.player.global_position.y-lift.height)<.08 and game.player.is_on_floor(),"Occupied lift reaches hip working height through ordinary click")
	await press(ground)
	for tick in range(1000):
		if not lift.moving:break
		await frames(1)
	expect(is_equal_approx(lift.height,.15) and game.player.is_on_floor() and lift.gate.disabled,"Onboard Return to ground preserves rider and opens boarding gate")
	await walk(Vector3(9.6,0,20.0),"off the lift along its boarding ramp")
	await walk(Vector3(4.3,0,20.0),"west aisle after lift inspection")
	await walk(Vector3(4.3,0,24.2),"bay panel for loaded Return")
	for stage in range(2,-1,-1):
		await press(button("return",true),stage%2 == 0)
		expect(await settle() and is_equal_approx(trial.path,float(stage)),"Ordinary Return brings supported leg back through stage "+str(stage))
	await walk(Vector3(4.3,0,11.4),"west aisle back to horizontal station")
	await walk(Vector3(8.3,0,11.4),"source panel after complete return")
	expect(game.model.support_occupant("m1_leg_rail") == "left_leg" and game.model.assemblies.left_leg.parent.is_empty() and trial.load_body.global_transform.is_equal_approx(trial.rail_pose(0).load),"Complete ordinary-control loop returns same rail-owned preassembled leg home")

	var passed = checks.all(func(check):return check.passed)
	FileAccess.open("/tmp/m1-controls.audit.json",FileAccess.WRITE).store_string(JSON.stringify({"passed":passed,"checks":checks,"rendered":false,"teleported_player":false,"partial_retention":"Isolated real-model fixture for rejected E/click only; normal trial provides no retention interaction"},"  "))
	game.free();await process_frame
	print("M1_CONTROLS ","PASS" if passed else "FAIL"," ",checks.size()," checks")
	quit(0 if passed else 1)
