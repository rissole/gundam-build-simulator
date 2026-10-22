extends "res://tests/leg_equipment_test.gd"
## Real camera targeting and the ordinary desktop E adapter. Preparation is staged;
## control operation, walking support and powered passenger movement are live.

func press_e() -> void:
	var event = InputEventKey.new()
	event.physical_keycode = KEY_E
	event.pressed = true
	game.handle_desktop_input(event)
	event.pressed = false
	game.handle_desktop_input(event)

func look_at_control(entry: Dictionary, feet: Vector3) -> bool:
	game.player.global_position = feet
	game.player.velocity = Vector3.ZERO
	await frames(12)
	var point: Vector3 = entry.node.global_position
	var direction: Vector3 = point-game.camera.global_position
	game.player.rotation = Vector3(0,atan2(-direction.x,-direction.z),0)
	game.camera.rotation = Vector3(atan2(direction.y,Vector2(direction.x,direction.z).length()),0,0)
	await frames(2)
	game._update_target()
	var selected: bool = game.target.get("type","") == "equipment" and game.target.get("node") == entry.node
	var visible: bool = game._visible(point,[])
	var reachable: bool = game.camera.global_position.distance_to(point) <= game.REACH
	var grounded: bool = game.player.is_on_floor()
	if not selected or not visible or not reachable or not grounded:
		print("CONTROL_DIAGNOSTIC ",entry.node.get_path()," action=",entry.action," feet=",game.player.global_position," target=",game.target," visible=",visible," distance=",game.camera.global_position.distance_to(point)," grounded=",grounded)
	expect(selected and visible and reachable and grounded,"Grounded aim sees and reaches "+str(entry.node.get_path())+" / "+entry.action)
	if selected:expect(game.equipment_controller(game.target) == game.equipment_controller(entry),"Target routes to the control's own equipment")
	return selected and visible and reachable and grounded

func lift_control(platform: Node3D, action_id: String, ground: bool = false) -> Dictionary:
	for entry in platform.controls():
		if entry.action == action_id and (entry.node.get_parent() == platform) == ground:return entry
	return {}

func ride_button(platform: Node3D, action_id: String) -> bool:
	var entry = lift_control(platform,action_id)
	var feet: Vector3 = platform.global_position+Vector3(0,platform.height+0.02,0)
	if not await look_at_control(entry,feet):return false
	var before: float = platform.height
	press_e()
	expect(platform.moving,"Desktop E starts "+platform.equipment_id+" lift / "+action_id)
	if not platform.moving:
		print("CONTROL_E_DIAGNOSTIC ",game.hud.toast_label.text)
		return false
	await frames(25)
	expect(absf(platform.height-before)>0.1 and absf(game.player.global_position.y-platform.global_position.y-platform.height)<0.06,"Occupied "+platform.equipment_id+" deck carries player after desktop E")
	for tick in range(900):
		if not platform.moving:break
		await frames(1)
	expect(not platform.moving and game.player.is_on_floor(),"Desktop-operated "+platform.equipment_id+" lift reaches indexed stop")
	return not platform.moving

func check_console(entry: Dictionary, raised: bool) -> void:
	var point: Vector3 = entry.node.global_position
	var feet = Vector3(point.x-0.25,0.025,point.z)
	if entry.node.get_parent().name == "HipHandlingControlsground":feet.x = point.x-0.6
	if raised:
		var platform = game.access_lifts.hip
		feet = platform.global_position+Vector3(0.55,platform.height+0.02,clampf(point.z-platform.global_position.z,-0.76,0.76))
	await look_at_control(entry,feet)

func run() -> void:
	game = load("res://scenes/workshop.tscn").instantiate()
	game.leg_workshop = true
	game.automated_test = true
	root.add_child(game)
	await frames(6)
	equipment = game.leg_equipment
	game.set_paused(false)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	for entry in equipment.controls():
		if entry.node.get_parent().name != "HipHandlingControlsdeck":await check_console(entry,false)
	for platform in game.access_lifts.values():
		if not await ride_button(platform,"up"):continue
		if not await ride_button(platform,"down"):continue
		if not await ride_button(platform,"up"):continue
		if not await ride_button(platform,"ground"):continue
		if not await ride_button(platform,"up"):continue
		var ground_call = lift_control(platform,"ground",true)
		var point: Vector3 = ground_call.node.global_position
		if await look_at_control(ground_call,Vector3(point.x+0.7,0.025,point.z)):
			press_e()
			expect(platform.moving and is_equal_approx(platform.destination,platform.stops[0]),"Grounded desktop E calls "+platform.equipment_id+" lift back to floor")
			for tick in range(900):
				if not platform.moving:break
				await frames(1)
			expect(not platform.moving and platform.gate.disabled,"Ground call finishes with open boarding gate")
	var hip = game.access_lifts.hip
	if await ride_button(hip,"up"):
		for entry in equipment.controls():
			if entry.node.get_parent().name == "HipHandlingControlsdeck":await check_console(entry,true)
		await ride_button(hip,"ground")
	# One accepted new-controller action proves E dispatch, beyond prerequisite
	# feedback on the other buttons. Reuse the established identity staging helper.
	await prepare_foot()
	game.set_paused(false)
	for entry in equipment.controls():
		if entry.action == "seat_foot":
			var point: Vector3 = entry.node.global_position
			if await look_at_control(entry,Vector3(point.x-0.25,0.025,point.z)):
				expect(equipment.action_error("seat_foot").is_empty(),"Staged complete foot satisfies physical transfer control prerequisites")
				press_e()
				expect(equipment.moving and equipment.operation == "foot_seat" and equipment.foot_departed,"Desktop E dispatches valid supported transfer to new controller")
				var foot_before: Vector3 = game.foot.global_position
				await frames(20)
				expect(game.foot.global_position.distance_to(foot_before)>0.1 and game.model.assemblies.foot.location == "support:foot_hoist","Desktop control produces physical hoist motion with supported ownership")
			break
	var passed: bool = checks.all(func(check):return check.passed)
	FileAccess.open("/tmp/leg-controls.audit.json",FileAccess.WRITE).store_string(JSON.stringify({"passed":passed,"checks":checks,"rendered":false,"engine":Engine.get_version_info().string},"  "))
	game.free()
	await process_frame
	print("LEG_CONTROLS ","PASS" if passed else "FAIL"," ",checks.size()," checks")
	quit(0 if passed else 1)
