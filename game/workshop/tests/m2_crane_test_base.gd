extends "res://tests/save_resume_test.gd"
## Shared real-scene helpers. Tests disclose supplied construction, never rigging.
var crane: Node3D

func boot() -> void:
	game = load("res://scenes/workshop.tscn").instantiate()
	game.profile_override = "leg_bay_crane";game.automated_test = true
	root.add_child(game);game.automated_test = true;await frames(8)
	game.set_paused(false);Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	crane = game.equipment.get_equipment("service_crane")

func key(code: Key, down: bool = true) -> void:
	var event = InputEventKey.new();event.physical_keycode = code;event.pressed = down
	game.handle_desktop_input(event)

func tap(code: Key) -> void:
	key(code);key(code,false)

func pocket(kind: String) -> void:
	var index: int = game.model.pocket_for(kind)
	if index < 0:expect(false,"Pocket contains "+kind);return
	tap([KEY_1,KEY_2,KEY_3,KEY_4,KEY_5,KEY_6,KEY_7,KEY_8,KEY_9,KEY_0][index])

func click() -> void:
	var event = InputEventMouseButton.new();event.button_index = MOUSE_BUTTON_LEFT;event.pressed = true
	game.handle_desktop_input(event)

func look(point: Vector3) -> void:
	var direction = point-game.camera.global_position
	game.player.rotation = Vector3(0,atan2(-direction.x,-direction.z),0)
	game.camera.rotation = Vector3(atan2(direction.y,Vector2(direction.x,direction.z).length()),0,0)
	game._update_target()

func walk(point: Vector3, label: String) -> bool:
	var arrived = false
	for tick in range(1100):
		var offset = point-game.player.global_position;offset.y = 0
		if offset.length()<.10:arrived = true;break
		game.player.rotation.y = atan2(-offset.x,-offset.z);game.camera.rotation.x = 0
		key(KEY_W);await frames(1)
	key(KEY_W,false);await frames(8)
	if not arrived:print("M2_CRANE_WALK ",label," feet=",game.player.global_position," target=",point)
	expect(arrived and game.player.is_on_floor(),"Walked route reaches "+label)
	return arrived

func entry(action: String) -> Dictionary:
	for candidate in crane.controls():
		if candidate.action == action:return candidate
	return {}

func aim_action(action: String, use_click: bool = false) -> bool:
	var candidate = entry(action)
	if candidate.is_empty():expect(false,"Crane offers "+action);return false
	look(candidate.point);await frames(2);game._update_target()
	var aimed: bool = game.target.get("controller") == crane and game.target.get("action","") == action
	if not aimed:print("M2_CRANE_AIM ",action," feet=",game.player.global_position," actual=",game.target)
	expect(aimed,"Ordinary aim selects "+action)
	if not aimed:return false
	if use_click:click()
	else:tap(KEY_E)
	return true

func console_action(action: String) -> bool:
	if not crane.console.is_open:
		if not await aim_action("open_console"):return false
	expect(crane.console.is_open,"E opens physical central crane console")
	var before = crane.capture()
	await console_click(action)
	var error: String = crane.console.feedback.text
	var accepted = error == "Command accepted."
	if not accepted:print("M2_CRANE_CONSOLE ",action," ",error," before=",before)
	expect(accepted,"Console accepts "+action)
	return accepted

func console_click(action: String) -> void:
	await process_frame
	if not crane.console.buttons.has(action):expect(false,"Console offers "+action);return
	var button: Button = crane.console.buttons[action]
	var position: Vector2 = button.get_global_rect().get_center()
	for down in [true,false]:
		var event = InputEventMouseButton.new();event.button_index = MOUSE_BUTTON_LEFT;event.position = position;event.global_position = position;event.pressed = down
		game.get_viewport().push_input(event,true)
		await process_frame
	await frames(2)

func settle() -> bool:
	for tick in range(1200):
		if not crane.moving:return crane.blocked_reason.is_empty()
		await frames(1)
	print("M2_CRANE_MOTION_TIMEOUT ",crane.capture())
	return false

func source_route() -> void:
	await walk(Vector3(4.9,0,21.9),"central console")
	await aim_action("open_console");tap(KEY_Q)
	expect(not crane.console.is_open,"Q closes the physical console with no hand payload")
	await console_action("go:source")
	expect(await settle() and crane.station=="source" and crane.raised,"Travel reaches source while Up")
	await console_action("down")
	expect(await settle() and not crane.raised,"Down lowers reachable magnetic ends")
	expect(crane.console.order==["up"],"Only Up appears while Down")
	tap(KEY_Q)
	await walk(Vector3(6.85,0,20.1),"west source approach")
	await walk(Vector3(6.85,0,16.05),"near magnetic point")
	expect(not crane.console.is_open,"Q closes the modal before walking")

func rig(swapped: bool = false) -> void:
	await aim_action("pick:magnet_a")
	expect(crane.hand_payload() == "magnet_a","E acquires first equipment endpoint")
	if swapped:await walk(Vector3(6.85,0,18.14),"held first end to other compatible point")
	await aim_action("attach:"+("beam_far" if swapped else "beam_near"),true)
	expect(crane.attached_count()==1 and crane.hand_payload().is_empty(),"Click seats first magnet without consuming robot inventory")
	await walk(Vector3(6.85,0,18.14),"far magnetic end")
	await aim_action("pick:magnet_b")
	if swapped:await walk(Vector3(6.85,0,16.05),"held second end to remaining compatible point")
	var held_before = crane.capture()
	var occupied: String = "beam_far" if swapped else "beam_near"
	expect(not crane.request("attach:"+occupied).is_empty() and crane.capture()==held_before,"Held second magnet rejects occupied point without mutation")
	await aim_action("attach:"+("beam_near" if swapped else "beam_far"),true)
	expect(crane.attached_count()==2 and game.model.items[crane.uid].location == "support:leg_spar_rack","Both magnets engage before rack ownership releases")

func deliver() -> void:
	await walk(Vector3(6.85,0,20.1),"source exit")
	await walk(Vector3(4.9,0,21.9),"console for supported transfer")
	await console_action("up")
	expect(crane.motion == "up" and game.model.items[crane.uid].location == "support:leg_spar_rack","Source still owns beam while crane takes weight")
	tap(KEY_ESCAPE);await frames(2)
	var paused_progress: float = crane.progress
	expect(game.paused and not crane.console.is_open,"Escape retains global pause and closes the physical console")
	await frames(3);expect(crane.progress == paused_progress,"Paused take-weight operation preserves support and progress")
	tap(KEY_ESCAPE)
	expect(await settle() and crane.raised,"Up raises supported load before travel")
	await console_action("go:receiver")
	expect(await settle() and crane.station=="receiver" and crane.raised,"Travel reaches leg while Up")
	await console_action("down")
	expect(await settle() and not crane.raised,"Down completes axial flange seating")
	tap(KEY_Q)
	expect(game.model.items[crane.uid].owner == "left_leg" and crane.assisting and crane.attached_count()==2,"Installed beam has one model owner and real crane assistance")

func finish(label: String, filename: String) -> void:
	var passed = checks.all(func(check):return check.passed)
	FileAccess.open(filename,FileAccess.WRITE).store_string(JSON.stringify({"passed":passed,"checks":checks,"rendered":false,"supplied_construction":"Completed foot and all authored pre-spar leg slots. The save test uses one real model-installed washer solely as a partial-fastening snapshot fixture; the controls test fits all eight fasteners normally."},"  "))
	if is_instance_valid(game):game.free()
	await process_frame
	print(label," ","PASS" if passed else "FAIL"," ",checks.size()," checks")
	quit(0 if passed else 1)
