extends "res://tests/leg_equipment_test.gd"
## New structural connections use real drawers/shelves, desktop targets, previews
## and clicks. Only the already-regressed original foot branch is staged.
var installed: Array[String] = []
var held_routes: Array = []
var wrong_hardware_checked = false

func key(code: Key, pressed: bool = true) -> void:
	var event = InputEventKey.new()
	event.physical_keycode = code
	event.pressed = pressed
	game.handle_desktop_input(event)

func click() -> void:
	var event = InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	game.handle_desktop_input(event)

func look(point: Vector3) -> void:
	var direction = point - game.camera.global_position
	game.player.rotation = Vector3(0, atan2(-direction.x, -direction.z), 0)
	game.camera.rotation = Vector3(clampf(atan2(direction.y, Vector2(direction.x, direction.z).length()), -1.35, 1.35), 0, 0)
	game._update_target()
	game._update_ghost()

func stand(at: Vector3, label: String) -> bool:
	if not game.model.held_item().is_empty():
		expect(false, "Test setup cannot teleport a carried component: " + label)
		return false
	game.player.global_position = at + Vector3.UP * .025
	game.player.velocity = Vector3.ZERO
	await frames(12)
	var grounded: bool = game.player.is_on_floor() and absf(game.player.global_position.y - at.y) < .065
	expect(grounded, "Real floor/deck supports operator: " + label)
	return grounded

func walk_to(point: Vector3, label: String) -> bool:
	var carried: String = game.model.held_item()
	var begin: Vector3 = game.player.global_position
	var reached = false
	for tick in range(900):
		var offset = point - game.player.global_position
		offset.y = 0
		if offset.length() < .10:
			reached = true
			break
		game.player.rotation.y = atan2(-offset.x, -offset.z)
		game.camera.rotation.x = 0
		key(KEY_W)
		await frames(1)
	key(KEY_W, false)
	await frames(12)
	if not reached:
		var blockers: Array = []
		for index in range(game.player.get_slide_collision_count()):
			var contact = game.player.get_slide_collision(index)
			blockers.append(str(contact.get_collider().get_path()) + " at " + str(contact.get_position()))
		print("WALK_DIAGNOSTIC ", label, " from=", begin, " actual=", game.player.global_position, " destination=", point, " held=", carried, " body=", game.components.held_body.global_position if is_instance_valid(game.components.held_body) else Vector3.ZERO, " contacts=", blockers)
	expect(reached and game.player.is_on_floor(), "Ordinary walking reaches " + label)
	if not carried.is_empty():
		held_routes.append({"uid": carried, "from": str(begin), "to": str(game.player.global_position), "grounded": game.player.is_on_floor()})
		expect(game.model.held_item() == carried, "Walking preserves carried identity: " + label)
	return reached

func move_lift(lift: Node3D, height: float) -> bool:
	while not is_equal_approx(lift.height, height):
		var error: String = lift.request("up" if lift.height < height else "down")
		expect(error.is_empty(), "Occupied lift accepts hand-carry route: " + lift.equipment_id + ": " + error)
		if not error.is_empty(): return false
		for tick in range(900):
			if not lift.moving: break
			await frames(1)
			if not lift.blocked_reason.is_empty():
				print("LIFT_DIAGNOSTIC ", lift.equipment_id, " ", lift.blocked_reason, " held=", game.model.held_item())
				return false
		await frames(10)
		expect(game.player.is_on_floor() and absf(game.player.global_position.y - lift.height) < .06, "Moving deck carries grounded operator to " + str(lift.height))
	return true

func collect(kind: String) -> bool:
	var carry: String = game.model.definitions.parts[kind].carry_class
	if carry == "pocket" and game.model.count_at(kind, "pocket") > 0:
		key([KEY_1, KEY_2, KEY_3, KEY_4, KEY_5, KEY_6, KEY_7, KEY_8, KEY_9, KEY_0][game.model.pocket_for(kind)])
		return true
	var bin: Node3D = game.bins[kind]
	if not await stand(Vector3(bin.global_position.x, 0, bin.global_position.z + 1.25), "collect " + kind): return false
	look(bin.global_position + Vector3(0, .13, .27))
	await frames(3)
	game._update_target()
	var count_before: int = game.model.count_at(kind, "bin")
	var target_ok: bool = game.target.get("type", "") == "bin" and game.target.get("kind", "") == kind
	if not target_ok: print("COLLECT_DIAGNOSTIC ", kind, " ", game.target)
	expect(target_ok, "Real shelf/drawer target selects " + kind)
	key(KEY_E)
	await frames(20)
	var got: bool = game.model.count_at(kind, "pocket") > 0 if carry == "pocket" else not game.model.held_item().is_empty() and game.model.items[game.model.held_item()].kind == kind
	expect(got and game.model.count_at(kind, "bin") < count_before, "E collection removes physical stock into pocket/hands: " + kind)
	if carry == "pocket":
		expect(game.model.selected_kind() == kind and game.model.pocket_size(game.model.selected_pocket) == count_before, "Drawer fills one grouped selected pocket: " + kind)
	return got

func hand_approach(owner: String, sid: String) -> bool:
	# First clear the shelf's open face, then follow the aisle around the west
	# platform and fixture. Carrying never teleports through scenery.
	if not await walk_to(Vector3(-5.8, 0, game.player.global_position.z), "shelf front aisle"): return false
	if not await walk_to(Vector3(-5.8, 0, 18.8), "west equipment aisle"): return false
	var west: bool = sid in ["bearing_1", "thrust_1", "axle"]
	var lift: Node3D = game.access_lifts["knee" if west else "leg"]
	# Return an empty platform to its entrance before boarding with a component.
	if not is_equal_approx(lift.height, .15):
		var error: String = lift.request("ground")
		expect(error.is_empty(), "Call platform to the floor before boarding: " + error)
		if not error.is_empty(): return false
		for tick in range(900):
			if not lift.moving: break
			await frames(1)
	if not await walk_to(Vector3(lift.global_position.x, 0, 18.8), "platform ramp approach"): return false
	if not await walk_to(Vector3(lift.global_position.x, .15, 15.7), "open platform gate"): return false
	var work_height = 1.2 if sid == "main_input" else 3.8
	if not await move_lift(lift, work_height): return false
	var x: float = lift.global_position.x + (.55 if west else -.55)
	return await walk_to(Vector3(x, work_height, 14.4), "ankle disconnect" if sid == "main_input" else "knee exposed " + ("left" if west else "right") + " face")

func place(owner: String, sid: String) -> bool:
	var definition: Dictionary = game.model.slot_definition(owner, sid)
	var kind: String = definition.accepts
	if sid == "cap/washer_1" and not wrong_hardware_checked:
		if not await collect("lg-w24"): return false
		var lift: Node3D = game.access_lifts.leg
		lift.apply({"height": 3.8, "destination": 3.8, "moving": false})
		if not await stand(Vector3(4.25, 3.8, 14.4), "wrong-size knee hardware check"): return false
		look(game.components.slot_point(owner, sid))
		var history_before: int = game.model.assemblies[owner].history.size()
		var wrong_count: int = game.model.count_at("lg-w24", "pocket")
		click()
		await frames(2)
		expect(game.model.assemblies[owner].history.size() == history_before and game.model.count_at("lg-w24", "pocket") == wrong_count, "Desktop click rejects incompatible M24 washer at M12 cap without consuming stock")
		wrong_hardware_checked = true
	if not await collect(kind): return false
	var hand: bool = game.model.definitions.parts[kind].carry_class != "pocket"
	if hand:
		if not await hand_approach(owner, sid): return false
	elif owner == "pelvis":
		var lift: Node3D = game.access_lifts.hip
		# Test setup may place a pocket-equipped operator on a real platform; the
		# lift's own movement and collision suite verifies boarding/travel.
		lift.apply({"height": 8.4, "destination": 8.4, "moving": false})
		var point: Vector3 = game.components.slot_point(owner, sid)
		if not await stand(Vector3(point.x, 8.4, 27.75), "hip underside connection"): return false
	else:
		var height = 5.2 if sid.begins_with("fork/") else 3.8 if sid.begins_with("cap/") else 1.2
		if height > 1:
			var lift: Node3D = game.access_lifts.leg
			lift.apply({"height": height, "destination": height, "moving": false})
			if not await stand(Vector3(4.25, height, 14.4), "thigh flange work deck" if height > 2 else "ankle flange work deck"): return false
		else:
			if not await stand(Vector3(2.3, .30, 16.25), "ankle rear foundation deck"): return false
	var point: Vector3 = game.components.slot_point(owner, sid)
	look(point)
	await frames(25 if hand else 3)
	look(point)
	var chosen: String = game.components.selected_uid(game.selected_kind)
	var matched: String = game.target.get("sid", "")
	var target_ok: bool = game.target.get("type", "") == "component" and game.target.get("owner", "") == owner and matched == sid
	var access: String = game.components.access() if target_ok else "Target mismatch"
	var preview: bool = target_ok and game.ghost.visible and access.is_empty()
	if not preview: print("PLACEMENT_DIAGNOSTIC owner=", owner, " sid=", sid, " position=", game.player.global_position, " point=", point, " target=", game.target, " access=", access, " held=", game.model.held_item(), " body=", game.components.held_body.global_position if is_instance_valid(game.components.held_body) else Vector3.ZERO)
	expect(game.player.is_on_floor() and preview, "Grounded ordinary desktop target and valid preview: " + owner + "/" + sid)
	if not preview: return false
	var before: int = game.model.assemblies[owner].history.size()
	var pocket_before: int = game.model.count_at(kind, "pocket")
	var drawer_before: int = game.model.count_at(kind, "bin")
	click()
	await frames(2)
	var occupant: String = game.model.assemblies[owner].slots[sid]
	var ok: bool = game.model.assemblies[owner].history.size() == before + 1 and occupant == chosen
	expect(ok, "Click installs exactly selected physical identity: " + owner + "/" + sid)
	if not ok: return false
	if not hand:
		expect(game.model.count_at(kind, "pocket") == pocket_before - 1 and game.model.count_at(kind, "bin") == drawer_before, "Placement consumes one pocket item without changing drawer stock")
	var source_matches = false
	for visual in game.assembly_node(owner).get_children():
		if not visual is MeshInstance3D or visual.get_meta("component_uid", "") != occupant: continue
		var actual: PackedVector3Array = visual.mesh.get_faces()
		var expected: PackedVector3Array = game.source[definition.pose_source].mesh.get_faces()
		source_matches = actual.size() == expected.size()
		for i in range(mini(actual.size(), expected.size())):
			if (visual.global_transform * actual[i]).distance_to(game.components.slot_pose(owner, sid) * expected[i]) > .00001: source_matches = false; break
	expect(source_matches, "Installed geometry follows destination source while retaining chosen identity: " + sid)
	if sid == "bearing_2": expect(occupant == "LG-130__001", "First identical bearing fills the opposite source slot")
	if sid == "thrust_2": expect(occupant == "LG-135__001", "First identical thrust spacer fills the opposite source slot")
	installed.append(owner + "/" + sid)
	return true

func manual_page(owner: String, index: int) -> void:
	var previous_diagram: String = game.hud.diagram.signature
	game.hud.open_manual(owner, index)
	await frames(2)
	var page: Dictionary = game.components.definition(owner).manual[index]
	var text: String = game.hud.page_body.text
	if not page.get("diagram_views", []).is_empty():
		expect(game.hud.diagram.signature == str(page.diagram_views), "Runtime manual completes diagram update without an early script failure: " + page.title)
	else:
		expect(not game.hud.diagram.signature.is_empty() and game.hud.diagram.signature != previous_diagram, "Runtime readiness diagram updates for logical parent: " + owner)
	if page.view == "prepared":
		expect(not text.contains("Parts for this step") and not game.hud.page_count.text.contains("step components"), "Runtime readiness page lists no new supplies: " + owner)
	else:
		expect(text.contains("Parts for this step") and game.hud.page_count.text.contains("/ %d step components" % page.slots.size()), "Runtime manual uses this page's exact component count: " + page.title)
		for sid in page.slots:
			var slot: Dictionary = game.model.slot_definition(owner, sid)
			if slot.has("accepts"): expect(text.contains(game.components.title(slot.accepts)), "Runtime manual includes real part label: " + slot.accepts)

func finish_audit() -> void:
	var passed: bool = checks.all(func(check): return check.passed)
	DirAccess.make_dir_recursive_absolute("res://verification")
	FileAccess.open("res://verification/leg-build-audit.json", FileAccess.WRITE).store_string(JSON.stringify({"passed": passed, "checks": checks, "installed": installed, "held_routes": held_routes}, "  "))
	print("LEG_BUILD_AUDIT ", "PASS" if passed else "FAIL", " ", checks.size(), " checks; ", installed.size(), " ordinary desktop installations")
	quit(0 if passed else 1)

func run() -> void:
	game = load("res://scenes/workshop.tscn").instantiate()
	game.leg_workshop = true
	root.add_child(game)
	await frames(4)
	game.automated_test = true
	game.set_paused(false)
	equipment = game.leg_equipment
	await prepare_foot()
	await frames(3)
	if not action("seat_foot") or not await finish_motion(): finish_audit(); return
	for owner in ["left_leg", "pelvis"]:
		var recipe: Dictionary = game.components.definition(owner)
		for index in range(recipe.manual.size()):
			await manual_page(owner, index)
			var page: Dictionary = recipe.manual[index]
			if page.view == "prepared": continue
			var page_slots: Array = ["bearing_2", "bearing_1", "thrust_2", "thrust_1"] if page.title == "Seat bearings and thrust spacers" else page.slots
			for sid in page_slots:
				if not game.model.assemblies[owner].slots[sid].is_empty(): continue
				var slot: Dictionary = game.model.slot_definition(owner, sid)
				if slot.has("assembly"):
					if not await stand(Vector3(8, 0, 20), "clear hoist route"): finish_audit(); return
					for command in ["pick_leg", "transfer_leg", "seat_leg"]:
						if not action(command) or not await finish_motion(): finish_audit(); return
				elif game.model.definitions.parts[slot.accepts].carry_class == "equipment":
					if not await stand(Vector3(8, 0, 20), "clear structural lift route"): finish_audit(); return
					var uid: String = game.model.find_item(slot.accepts, "support:" + slot.source_supports[0])
					if uid.is_empty():
						for candidate in game.model.items:
							if game.model.items[candidate].kind == slot.accepts and game.model.items[candidate].owner.is_empty(): uid = candidate; break
					if not action("install:" + uid) or not await finish_motion(): finish_audit(); return
				else:
					if not await place(owner, sid): finish_audit(); return
		expect(game.model.milestone(owner, "structural_ready"), "Desktop manual reaches structural readiness: " + owner)
	var expected: Array = []
	for owner in ["left_leg", "pelvis"]:
		for sid in game.model.assemblies[owner].slots:
			var slot: Dictionary = game.model.slot_definition(owner, sid)
			if slot.has("accepts") and game.model.definitions.parts[slot.accepts].carry_class != "equipment": expected.append(owner + "/" + sid)
	expect(installed.size() == expected.size() and expected.all(func(sid): return installed.has(sid)), "Every new hand/pocket slot was installed through collection, target, preview and click")
	expect(game.model.integrity_errors().is_empty(), "Final nested build preserves all 175 physical identities")
	finish_audit()
