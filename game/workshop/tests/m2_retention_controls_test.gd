extends "res://tests/m2_test_helpers.gd"
var shelf: Node3D
var snapshots: Dictionary = {}
var replay_uid = "PV-120__001"
func press(entry: Dictionary, click: bool = false, expected_error: String = "") -> bool:
	look(entry.point)
	await frames(2);game._update_target()
	var found: bool = game.target.get("controller") == entry.get("controller") and game.target.get("action") == entry.action and game._access(game._target_receivers()) == expected_error
	if not found:print("M2_TARGET ",entry.action," feet=",game.player.global_position," target=",game.target," access=",game._access(game._target_receivers()))
	expect(found,"Normal aim reaches "+entry.action)
	if not found:return false
	if click:
		var event = InputEventMouseButton.new();event.button_index = MOUSE_BUTTON_LEFT;event.pressed = true;game.handle_desktop_input(event)
	else:key(KEY_E);key(KEY_E,false)
	return true

func take_snapshot(label: String) -> void:
	var data: Dictionary = game.saves.capture()
	var errors: Array[String] = game.saves.validate(data)
	expect(errors.is_empty(),"Snapshot validates at "+label+" "+str(errors))
	snapshots[label] = data

func loop() -> bool:
	game = load("res://scenes/workshop.tscn").instantiate();game.m2_trial = "retention";game.m2_half_uid = replay_uid;root.add_child(game);game.automated_test = true;game.set_paused(false)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	trial = game.m2.rail;shelf = game.m2.shelf
	await frames(8)
	take_snapshot("home")
	await walk(Vector3(8.3,0,11.4),"rail source controls")
	await press(button("advance"))
	await frames(15);take_snapshot("rail_travel")
	await press(button("stop"),true);take_snapshot("rail_stopped")
	await press(button("advance"))
	await walk(Vector3(4.3,0,11.4),"west aisle")
	await walk(Vector3(4.3,0,24.2),"bay controls")
	expect(await settle(),"Rail reaches bay")
	for index in range(2):
		await press(button("advance",true),true)
		await frames(15);take_snapshot("tilt" if index == 0 else "dock")
		expect(await settle(),"Rail completes stage "+str(index))
	expect(game.model.assemblies.left_leg.parent == "pelvis" and game.runtime.node("left_leg").get_parent() == game.runtime.node("pelvis"),"Dock actually transfers leg model and runtime to pelvis")
	take_snapshot("seated_zero_retention")
	await walk(Vector3(4.3,0,20),"lift approach west")
	# Ground stock uses ordinary drawer/shelf pickup before boarding.
	for kind in ["lg-w24","pv-m24-140","pv-ring-half"]:
		var bin: Node3D = game.bins[kind]
		await walk(Vector3(bin.global_position.x,0,21.7),"ground stock "+kind)
		look(bin.global_transform*Vector3(0,.13,.27));await frames(2);game._update_target()
		expect(game.target.get("type") == "bin" and game.target.get("kind") == kind,"Ground aim identifies "+kind)
		key(KEY_E);key(KEY_E,false)
		expect(game.model.held_item()==replay_uid if kind=="pv-ring-half" else game.model.count_at(kind,"pocket")==2,"E collects "+kind)
	take_snapshot("half_carried")
	await walk(Vector3(9.6,0,21.7),"lift approach front")
	await walk(Vector3(9.6,0,24.3),"lift deck via ramp")
	var lift = game.access_lifts.hip
	await press(shelf.controls()[0],true)
	expect(shelf.occupants().has(replay_uid) and not game.model.hands_occupied(),"Click stores the same two-hand half on lift shelf")
	take_snapshot("shelf_ground")
	var up: Dictionary = lift.controls().filter(func(entry):return entry.action == "up")[0]
	await press(up,true)
	await frames(30);take_snapshot("lift_moving")
	for tick in range(1000):
		if not lift.moving:break
		await frames(1)
	expect(is_equal_approx(lift.height,8.4),"Lift reaches accepted hip work stop")
	if lift.height < 8:return false
	await press(shelf.controls()[0])
	expect(game.model.held_item()==replay_uid and shelf.occupants()==["",""],"E retrieves the same ring at height")
	await walk(Vector3(10.45,8.4,25.15),"hip working corner")
	game.hud.open_manual("pelvis",1)
	look(game.components.slot_point("pelvis","ring_1"));await frames(12);game._update_target()
	expect(game.target.get("sid")=="ring_1","Normal aim finds ring connection")
	var seat = InputEventMouseButton.new();seat.button_index=MOUSE_BUTTON_LEFT;seat.pressed=true;game.handle_desktop_input(seat)
	expect(game.model.assemblies.pelvis.slots.ring_1==replay_uid,"Ordinary click installs held ring half: "+game.hud.toast_label.text)
	take_snapshot("half_seated")
	if game.model.assemblies.pelvis.slots.ring_1!=replay_uid:return false
	expect(not trial.action_error("return").is_empty(),"Real fitted half blocks rail Return")
	for sid in ["ring/washer_3","ring/bolt_3","ring/washer_4","ring/bolt_4"]:
		var kind: String = game.model.slot_definition("pelvis",sid).accepts
		var pocket: int = game.model.pocket_for(kind)
		key(KEY_1+pocket);key(KEY_1+pocket,false)
		look(game.components.slot_point("pelvis",sid));await frames(2);game._update_target()
		expect(game.target.get("type") == "component" and game.target.get("sid") == sid,"Ordinary aim finds "+sid)
		if sid == "ring/bolt_3":
			var before_wrong = JSON.stringify(game.saves.capture().model)
			game.model.select_pocket(game.model.pocket_for("lg-w24"))
			var selected_wrong = JSON.stringify(game.saves.capture().model)
			var wrong_event = InputEventMouseButton.new();wrong_event.button_index = MOUSE_BUTTON_LEFT;wrong_event.pressed = true;game.handle_desktop_input(wrong_event)
			expect(JSON.stringify(game.saves.capture().model) == selected_wrong,"Wrong washer at bolt connection is rejected atomically")
			game.model.select_pocket(pocket)
		var event = InputEventMouseButton.new();event.button_index = MOUSE_BUTTON_LEFT;event.pressed = true;game.handle_desktop_input(event)
		expect(not game.model.assemblies.pelvis.slots[sid].is_empty(),"Click installs "+sid)
		if sid == "ring/washer_3":take_snapshot("partial_hardware")
	expect(not game.model.milestone("pelvis","left_leg_secured"),"One bolted half never claims a secured hip")
	take_snapshot("fully_bolted_half")
	for index in range(4):key(KEY_Z);key(KEY_Z,false)
	expect(game.model.assemblies.pelvis.slots.ring_1==replay_uid,"Z returns hardware while half remains seated")
	key(KEY_Z);key(KEY_Z,false)
	expect(game.model.held_item()==replay_uid,"Z returns actual retaining half directly into hands: "+game.hud.toast_label.text)
	take_snapshot("undone_half_held")
	await walk(Vector3(9.6,8.4,24.3),"return shelf position")
	await press(shelf.controls()[0],true)
	expect(shelf.occupants().has(replay_uid),"Undo half can travel down on shelf")
	take_snapshot("shelf_upper")
	await walk(Vector3(9.6,8.4,24.3),"onboard ground control reach")
	var ground: Dictionary = lift.controls().filter(func(entry):return entry.action == "ground" and entry.node.get_parent() == lift.deck)[0]
	await press(ground)
	for tick in range(1000):
		if not lift.moving:break
		await frames(1)
	await press(shelf.controls()[0])
	expect(game.model.held_item()==replay_uid,"Ground pickup preserves returned ring identity")
	await walk(Vector3(9.6,0,20),"lift disembark")
	look(game.player.global_position+Vector3(0,.10,-1.0));await frames(15)
	key(KEY_Q);key(KEY_Q,false);await frames(35)
	expect(game.model.items[replay_uid].location=="loose","Q drops ring as an ordinary solid component")
	look(game.loose[replay_uid].global_position);await frames(3);game._update_target()
	expect(game.target.get("type")=="loose" and game.target.get("uid")==replay_uid,"Dropped ring remains targetable in M2")
	key(KEY_E);key(KEY_E,false)
	expect(game.model.held_item()==replay_uid,"E recovers the same dropped ring")
	key(KEY_Q);key(KEY_Q,false);await frames(4)
	await walk(Vector3(4.3,0,20),"return aisle")
	await walk(Vector3(4.3,0,24.2),"bay Return control")
	for index in range(3):
		await press(button("return",true),true)
		expect(await settle(),"Loaded Return stage "+str(index))
		print("M2_RETURN ",trial.path," ",game.model.assemblies.left_leg.location," ",game.model.assemblies.left_leg.parent," ",game.hud.toast_label.text)
	expect(game.model.assemblies.left_leg.location == "support:m2_leg_rail" and game.model.assemblies.left_leg.parent.is_empty() and trial.path == 0,"Real supported undo returns the leg home")
	take_snapshot("home_after_return")
	return true

func run() -> void:
	await loop()
	game.free();await process_frame
	replay_uid = "PV-120__002"
	await loop()
	var passed = checks.all(func(check):return check.passed)
	FileAccess.open("/tmp/m2-retention-controls.audit.json",FileAccess.WRITE).store_string(JSON.stringify({"passed":passed,"checks":checks,"rendered":false,"teleported_player":false},"  "))
	game.free();await process_frame
	print("M2_RETENTION_CONTROLS ","PASS" if passed else "FAIL"," ",checks.size()," checks")
	quit(0 if passed else 1)
