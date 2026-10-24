extends "res://tests/kit/crane_suite.gd"
## Headless layout and GUI checks, not a rendered presentation review.

func press_key(code: Key) -> void:
	for down in [true,false]:
		var event = InputEventKey.new();event.physical_keycode=code;event.keycode=code;event.pressed=down
		root.push_input(event,true);await process_frame
	await frames(2)

func click_at(point: Vector2) -> void:
	for down in [true,false]:
		var event = InputEventMouseButton.new();event.button_index=MOUSE_BUTTON_LEFT
		event.position=point;event.global_position=point;event.pressed=down
		root.push_input(event,true);await process_frame
	await frames(2)

func check_bounds(label: String) -> void:
	var console = crane.console
	var bounds = root.get_visible_rect().grow(-16)
	var rect: Rect2 = console.panel.get_global_rect()
	expect(bounds.encloses(rect),label+": panel stays within viewport margins "+str(rect))
	expect(is_equal_approx(rect.size.x,340),label+": controls retain compact readable width")
	expect(rect.get_area()<root.get_visible_rect().get_area()*.35,label+": workshop remains mostly uncovered")
	expect(console.backdrop is Control and not console.backdrop is ColorRect,label+": fullscreen input shield has no painted background")
	expect(rect.get_center().is_equal_approx(root.get_visible_rect().get_center()),label+": panel stays centered on screen")
	var close: Button = console.panel.get_child(0).get_children().back()
	expect(rect.encloses(close.get_global_rect()),label+": Close stays accessible outside the command scroll area")

func run() -> void:
	var profiles = ["leg_bay_crane"]
	if "leg_bay_m3" in preload("res://scripts/scenario_profile.gd").IDS:profiles.append("leg_bay_m3")
	for profile_id in profiles:
		game=await boot_profile(profile_id)
		crane=game.equipment.get_equipment("service_crane")
		if profile_id=="leg_bay_m3":
			for point in [Vector3(8.65,0,20.5),Vector3(6.85,0,20.5),Vector3(6.85,0,22.5)]:
				await walk(point,"M3 west aisle to console")
		await walk(Vector3(4.9,0,21.9),"console in "+profile_id)
		await aim_action("open_console");await frames(4)
		expect(not crane.console.load_label.text.is_empty(),profile_id+": current load is identified")
		for dimensions in [Vector2i(1440,900),Vector2i(1280,720)]:
			root.content_scale_size=dimensions;root.size=dimensions;await frames(6)
			expect(root.get_visible_rect().size==Vector2(dimensions),"Layout check uses actual "+str(dimensions)+" viewport")
			check_bounds(profile_id+" "+str(dimensions))
		# A disclosed camera fixture checks that placement remains centered even
		# when the physical console is near the edge of the view.
		look(crane.console_node.global_position);game.player.rotation.y+=.8;await frames(6)
		check_bounds(profile_id+" console near screen edge")
		look(crane.console_node.global_position)
		# A constrained viewport and wrapped error stress command scrolling while
		# retaining the real controller's current command list.
		root.content_scale_size=Vector2i(1280,480);root.size=Vector2i(1280,480)
		crane.console.feedback.text="Move within reach of the central crane console. The connection must be secured before releasing the magnetic ends. ".repeat(2)
		await frames(6)
		expect(root.get_visible_rect().grow(-16).encloses(crane.console.panel.get_global_rect()),profile_id+": wrapped feedback and controls fit a short viewport")
		expect(not crane.console.order.any(func(action):return action.begins_with("task:")),profile_id+": console offers movement, never a load list")
		for index in range(crane.console.order.size()-1):await press_key(KEY_DOWN)
		var last: Button=crane.console.buttons[crane.console.order.back()]
		var visible_commands: Rect2=crane.console.scroll.get_global_rect()
		expect(last.has_focus() and visible_commands.encloses(last.get_global_rect()),profile_id+": keyboard navigation scrolls the last command into view")
		var close: Button=crane.console.panel.get_child(0).get_children().back()
		await click_at(close.get_global_rect().get_center())
		expect(not crane.console.is_open and not game.desktop_input.modal_active(),profile_id+": Close restores ordinary input")
		await aim_action("open_console");await frames(3)
		expect(crane.console.buttons[crane.console.order[0]].has_focus(),profile_id+": reopening restores keyboard focus to the first command")
		await press_key(KEY_ESCAPE)
		expect(game.paused and not crane.console.is_open,profile_id+": Escape closes controls and pauses")
		game.free();await process_frame
	var passed=checks.all(func(check):return check.passed)
	write_evidence("/tmp/crane-console-panel.audit.json",{"passed":passed,"checks":checks,"rendered":false})
	print("CRANE_CONSOLE_PANEL ","PASS" if passed else "FAIL"," ",checks.size()," checks")
	quit(0 if passed else 1)
