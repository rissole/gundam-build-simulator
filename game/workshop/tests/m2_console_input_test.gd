extends "res://tests/kit/crane_suite.gd"
func actual_key(code: Key) -> void:
	for down in [true,false]:
		var event = InputEventKey.new();event.physical_keycode=code;event.keycode=code;event.pressed=down
		game.get_viewport().push_input(event,true);await process_frame
	await frames(1)

func run() -> void:
	await boot()
	await walk(Vector3(4.9,0,21.9),"console")
	await aim_action("open_console")
	var view = game.camera.global_transform
	var feet = game.player.global_position
	var mouse = InputEventMouseMotion.new();mouse.relative=Vector2(120,-90);mouse.screen_relative=mouse.relative
	game.handle_desktop_input(mouse)
	key(KEY_W);await frames(15);key(KEY_W,false)
	expect(game.camera.global_transform.is_equal_approx(view) and game.player.global_position.distance_to(feet)<.01,"Modal mouse/keyboard cannot rotate or walk the player")
	expect(Input.mouse_mode==Input.MOUSE_MODE_VISIBLE,"Modal releases mouse for ordinary buttons")
	expect(not game.hud.visible,"Opening console tucks away the manual and inventory HUD")
	var untouched = crane.capture()
	for down in [true,false]:
		var outside = InputEventMouseButton.new();outside.button_index=MOUSE_BUTTON_LEFT
		outside.position=Vector2(8,8);outside.global_position=outside.position;outside.pressed=down
		game.get_viewport().push_input(outside,true);await process_frame
	expect(crane.console.is_open and crane.capture()==untouched,"Outside clicks keep console open without issuing world or crane commands")
	# Parking offers movement first, without an unusable Lower command.
	expect(crane.console.order[crane.console.selected]=="go:source","Pickup destination has initial keyboard focus")
	await actual_key(KEY_E)
	expect(crane.motion=="go:source" and crane.moving,"E executes focused command through viewport input")
	expect(crane.console.buttons.stop.has_focus(),"Changing command list focuses Stop during motion")
	await settle()
	await actual_key(KEY_E);await settle()
	expect(not crane.raised and crane.console.order==["up"],"Only Up is offered while lowered")
	var before = crane.capture()
	expect(not crane.request_console("go:receiver").is_empty() and crane.capture()==before,"Hidden travel command is also rejected by controller")
	await actual_key(KEY_Q)
	game.handle_desktop_input(mouse)
	expect(not crane.console.is_open and not game.camera.global_transform.is_equal_approx(view),"Q closes modal and restores mouse look")
	await walk(Vector3(6.85,0,20.1),"source approach")
	await walk(Vector3(6.85,0,16.05),"near magnetic end")
	await aim_action("pick:magnet_a")
	for rotation in [Vector2(0,0),Vector2(.6,.2),Vector2(-.5,-.3)]:
		game.player.rotation.y+=rotation.x;game.camera.rotation.x=rotation.y;await frames(2)
		var local: Vector3 = game.camera.global_transform.affine_inverse()*crane.end_nodes.magnet_a.global_position
		expect(absf(local.x)<.0001 and absf(local.y)<.0001 and is_equal_approx(local.z,-.65),"Held magnetic end remains exactly on camera centre while looking around")
	expect(game.hud.carry_label.text.contains("magnetic end"),"Holding prompt explains aim/click and Q")
	tap(KEY_Q)
	expect(crane.hand_payload().is_empty(),"Q returns cable end to its own stow")
	await finish("M2_CONSOLE_INPUT","/tmp/m2-console-input.audit.json")
