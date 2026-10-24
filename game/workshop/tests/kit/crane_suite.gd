extends "res://tests/kit/workshop_suite.gd"
## Shared real-scene helpers. Tests disclose supplied construction, never rigging.
var crane: Node3D

func pocket(kind: String) -> void:
	var index: int = game.model.pocket_for(kind)
	if index < 0:expect(false,"Pocket contains "+kind);return
	tap([KEY_1,KEY_2,KEY_3,KEY_4,KEY_5,KEY_6,KEY_7,KEY_8,KEY_9,KEY_0][index])

func entry(action: String) -> Dictionary:
	for candidate in crane.controls():
		if candidate.action == action:return candidate
	return {}

func aim_action(action: String, use_click: bool = false) -> bool:
	var candidate = entry(action)
	if candidate.is_empty():expect(false,"Crane offers "+action);return false
	look(candidate.point);await frames(2);game.automation.refresh_target()
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
	var accepted = error.is_empty()
	if not accepted:print("M2_CRANE_CONSOLE ",action," ",error," before=",before)
	expect(accepted,"Console accepts "+action)
	return accepted

func console_click(action: String) -> void:
	await process_frame
	if not crane.console.buttons.has(action):expect(false,"Console offers "+action);return
	var button: Button = crane.console.buttons[action]
	crane.console.scroll.ensure_control_visible(button);await process_frame
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
	write_evidence(filename,{"passed":passed,"checks":checks,"rendered":false,"supplied_construction":"Completed foot and all authored pre-spar leg slots. The save test uses one real model-installed washer solely as a partial-fastening snapshot fixture; the controls test fits all eight fasteners normally."})
	if is_instance_valid(game):game.free()
	await process_frame
	print(label," ","PASS" if passed else "FAIL"," ",checks.size()," checks")
	quit(0 if passed else 1)

func boot() -> void:
	game = await boot_profile("leg_bay_crane")
	crane = game.equipment.get_equipment("service_crane")

func key(code: Key, pressed: bool = true) -> void:
	PlayerDriver.new(game).key(code,pressed)

func look(point: Vector3) -> void:
	PlayerDriver.new(game).look(point)

func walk(point: Vector3, label: String) -> bool:
	var arrived: bool = await PlayerDriver.new(game).walk(point,1100,.10,8)
	expect(arrived,"Walked route reaches "+label)
	return arrived

func tap(code: Key) -> void:
	PlayerDriver.new(game).tap(code)

func click() -> void:
	PlayerDriver.new(game).click()
