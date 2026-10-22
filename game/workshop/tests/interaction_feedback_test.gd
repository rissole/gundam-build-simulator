extends SceneTree
## Exercise focus feedback through real targeting, inventory, reach and occlusion.
var game: Node
var driver: Node
var checks: Array[Dictionary] = []

func _initialize() -> void:
	run.call_deferred()

func expect(ok: bool, message: String) -> void:
	checks.append({"check":message,"passed":ok})
	if not ok:push_error(message)

func aim_fixture_control() -> void:
	for control in game.foot_fixture.controls():
		if control.action != "sole_left":continue
		game.player.global_position = Vector3(control.point.x-1.0,0.575,control.point.z)
		game.player.velocity = Vector3.ZERO
		var direction: Vector3 = control.point-game.camera.global_position
		game.player.rotation = Vector3(0,atan2(-direction.x,-direction.z),0)
		game.camera.rotation = Vector3(atan2(direction.y,Vector2(direction.x,direction.z).length()),0,0)
		await driver.frames(5)
		game._update_target()
		return

func run() -> void:
	game = load("res://scenes/workshop.tscn").instantiate()
	root.add_child(game)
	driver = load("res://tests/demo_test.gd").new()
	root.add_child(driver)
	driver.game = game
	await driver.frames(10)
	game.automated_test = true
	game.set_paused(false)
	expect(not game.hud.carry_panel.visible,"Empty hands leave no status strip")
	var bin: Node3D = game.bins["w-12"]
	var point = bin.global_position+Vector3(0,0.13,0.27)
	await driver.aim(point,1.0)
	expect(game.target.get("kind","") == "w-12" and game.interaction_outline.focused == bin and not game.interaction_outline.copies.is_empty(),"Reachable stock under the crosshair gets an object contour")
	expect(game.hud.target_panel.visible and game.hud.target_key.get_child(0).text == "E" and game.hud.target_action_label.text == "Stock pocket","Collection uses a compact keycap action beside the object")
	var anchored: Vector2 = game.hud.target_panel.position
	game.camera.rotate_y(0.04)
	game._update_target()
	await driver.frames(2)
	expect(game.hud.target_panel.position.distance_to(anchored)>2.0,"World prompt follows the object's projected position as the view changes")
	driver.key(KEY_E)
	expect(game.model.pocket_size(game.model.selected_pocket)>0,"The advertised stock action still fills the selected pocket")
	expect(not game.hud.carry_panel.visible,"Selecting stocked hardware does not show a hands status strip")
	await driver.aim(point,3.0)
	expect(game.interaction_outline.focused == null and not game.hud.target_action.visible and game.hud.target_label.text == game.components.title("w-12"),"Distant stock shows its identity without a distance reminder, actionable outline or key")
	await driver.aim(point,1.0)
	var obstacle = StaticBody3D.new()
	obstacle.collision_layer = 1
	game.add_child(obstacle)
	obstacle.global_position = game.camera.global_position.lerp(point,0.5)
	var shape = CollisionShape3D.new()
	shape.shape = BoxShape3D.new()
	shape.shape.size = Vector3.ONE*0.3
	obstacle.add_child(shape)
	await driver.frames(3)
	game._update_target()
	expect(game.interaction_outline.focused == null and not game.hud.target_panel.visible,"Scenery hides both focus outlines and world prompts")
	obstacle.queue_free()
	await driver.frames(3)
	await driver.aim(point,1.0)
	game.set_paused(true)
	expect(game.interaction_outline.focused == null and not game.hud.target_panel.visible,"Pause clears the focused contour and prompt")
	game.set_paused(false)
	await aim_fixture_control()
	expect(game.target.get("type","") == "equipment" and game.hud.target_action.visible and game.hud.target_action_label.text == "Operate" and game.interaction_outline.focused == null,"Reachable equipment keeps its E action without advertising pickup with a contour")
	# A receiving fixture is still an obstacle when picking up another object.
	# The prompt must use the same receiver exclusions as the actual pickup.
	point = game.bodies.pad_1.global_position
	await driver.aim(point,1.0)
	var original_foot: Node3D = game.foot
	var fixture = AnimatableBody3D.new()
	fixture.collision_layer = 1
	game.add_child(fixture)
	fixture.global_position = game.camera.global_position.lerp(point,0.5)
	var fixture_shape = CollisionShape3D.new()
	fixture_shape.shape = BoxShape3D.new()
	fixture_shape.shape.size = Vector3.ONE*0.35
	fixture.add_child(fixture_shape)
	game.foot = fixture
	await driver.frames(3)
	game._update_target()
	expect(game.target.get("type","") == "pad" and not game.hud.target_panel.visible and game.interaction_outline.focused == null,"An unrelated receiving fixture cannot be ignored by pickup feedback")
	game.foot = original_foot
	fixture.queue_free()
	await driver.frames(2)
	var cartridge_kind: String = game.model.items["FA-514__001"].kind
	await driver.aim(game.bins[cartridge_kind].global_position+Vector3(0,0.13,0.27),1.0)
	expect(game.target.get("kind","") == cartridge_kind and game.interaction_outline.focused == game.bins[cartridge_kind].get_node("ShelfPart") and not game.interaction_outline.copies.is_empty(),"Shelf collection outlines the removable part instead of its cabinet")
	game.hud.toast_time = 0
	driver.key(KEY_E)
	expect(game.model.held_item() == "FA-514__001" and game.hud.carry_panel.visible and game.hud.carry_label.text == "Carrying "+game.components.title(cartridge_kind),"Carrying a shelf component shows only its hands status, without the selected pocket")
	expect(game.hud.toast_time == 0,"Starting to carry a shelf component does not create a popup")
	await driver.aim(game.bins[cartridge_kind].global_position+Vector3(0,0.13,0.27),1.0)
	expect(game.interaction_outline.focused == null and not game.hud.target_action.visible,"Occupied hands suppress the shelf pickup contour and action")
	await aim_fixture_control()
	expect(game.model.held_item() == "FA-514__001" and game.target.get("type","") == "equipment" and game.hud.target_action.visible and game.interaction_outline.focused == null,"Carrying a part leaves equipment operable without a pickup contour")
	game.set_paused(true)
	expect(not game.hud.carry_panel.visible,"Pause hides the hands strip")
	game.set_paused(false)
	expect(game.hud.carry_panel.visible,"Resuming restores the occupied hands strip")
	await driver.aim(game.bins[cartridge_kind].global_position+Vector3(0,0.13,0.27),1.0)
	# Let the held body follow after returning from the fixture controls.
	await driver.frames(60)
	driver.key(KEY_Q)
	expect(not game.hud.carry_panel.visible and game.model.held_item().is_empty(),"Setting down a component immediately hides the hands strip")
	await driver.aim(game.loose["FA-514__001"].global_position,0.9)
	expect(game.target.get("type","") == "loose" and game.interaction_outline.focused == game.loose["FA-514__001"],"A reachable loose part advertises pickup with a contour")
	driver.key(KEY_E)
	expect(game.model.held_item() == "FA-514__001" and game.hud.toast_time == 0,"Picking up a loose component uses the hands strip without a popup")
	game.components.drop(true)
	# Reproduce discovery on the full supported foot with a real carried fitting.
	var clevis_slot = "pitch/FA-220__001"
	var clevis_kind: String = game.model.slot_definition("foot",clevis_slot).accepts
	await driver.aim(game.bins[clevis_kind].global_position+Vector3(0,0.13,0.27),1.0)
	driver.key(KEY_E)
	var clevis_uid: String = game.model.held_item()
	var clevis_point: Vector3 = game.components.slot_point("foot",clevis_slot)
	await driver.aim(clevis_point,3.0)
	expect(not clevis_uid.is_empty() and game.target.get("owner","") == "foot" and game.target.get("sid","") == clevis_slot and game.ghost.visible and game.ghost_material.albedo_color == game.SNAP_DISTANT_COLOR,"A carried clevis reveals its yellow receiving location on the supported foot from a distance")
	driver.click()
	expect(game.model.held_item() == clevis_uid and game.model.assemblies.foot.slots[clevis_slot].is_empty(),"Distant foot guidance leaves the fitting in the player's hands")
	game.foot_fixture.moving = true
	game._update_ghost()
	expect(not game.ghost.visible,"The moving fixture suppresses distant connection guidance")
	game.foot_fixture.moving = false
	game.components.drop(true)
	# An actual ready assembly connection retains its green preview without a
	# repeated click instruction; the failure path still explains compatibility.
	game.model.move_assembly("pitch","station:prep3")
	game._activate("pitch")
	game._set_pad_station("prep3")
	game.model.carry_item("FA-514__001")
	game.model.install("pitch","FA-514__001","FA-514__001")
	game.components.sync("pitch")
	var empty_pocket: int = game.model.pockets.find("")
	game.model.select_pocket(empty_pocket)
	var slot_point: Vector3 = game.components.slot_point("pitch","W-12__039")
	var stable_pickup = true
	for fraction in [0.0,0.25,0.5,0.75,1.0]:
		await driver.aim(slot_point.lerp(game.bodies.pitch.global_position,fraction),1.2)
		stable_pickup = stable_pickup and game.target.get("type","") == "pad" and game.target.get("build","") == "pitch" and game.hud.target_action_label.text == "Carry" and game.interaction_outline.focused == game.bodies.pitch
	expect(stable_pickup,"Empty-handed aim across an unfinished assembly keeps one assembly pickup prompt")
	game.model.stock_pocket("w-12")
	var stable_connection = true
	for offset in [-0.04,0.0,0.04]:
		await driver.aim(slot_point+Vector3(offset,0,0),1.2)
		stable_connection = stable_connection and game.target.get("type","") == "component" and game.target.get("owner","") == "pitch" and game.ghost.visible
	expect(stable_connection,"Selected hardware keeps nearby connections ahead of their assembly pickup target")
	await driver.aim(game.components.slot_point("pitch","W-12__039"),1.2)
	expect(game.target.get("type","") == "component" and game.ghost.visible and not game.hud.target_panel.visible and game.interaction_outline.focused == null,"A valid green attachment preview needs no click-to-attach tooltip or pickup contour")
	await driver.aim(slot_point,3.0)
	var distant_slot: String = game.target.get("sid","")
	expect(game.target.get("type","") == "component" and game.ghost.visible and game.ghost_material.albedo_color == game.SNAP_DISTANT_COLOR,"A compatible ready connection shows its yellow destination beyond attachment reach")
	expect(game.ghost.global_transform.is_equal_approx(game.components.slot_pose("pitch",distant_slot)),"Distant guidance marks the exact receiving pose, not the whole assembly")
	expect(game.hud.target_panel.visible and game.hud.target_label.text.contains("Move closer to attach") and not game.hud.target_action.visible,"Yellow discovery explains distance without advertising an available action")
	var stock_before: int = game.model.count_at("w-12","pocket")
	driver.click()
	expect(game.model.assemblies.pitch.slots[distant_slot].is_empty() and game.model.count_at("w-12","pocket") == stock_before,"Clicking yellow guidance cannot install or consume the distant part")
	game.model.stock_pocket("h-12030")
	game._update_target()
	game._update_ghost()
	expect(not game.ghost.visible,"A screw whose prerequisite washer is missing gets no distant preview")
	game.model.select_pocket(game.model.pocket_for("w-12"))
	await driver.aim(slot_point,3.0)
	obstacle = StaticBody3D.new()
	obstacle.collision_layer = 1
	game.add_child(obstacle)
	obstacle.global_position = game.camera.global_position.lerp(slot_point,0.5)
	shape = CollisionShape3D.new()
	shape.shape = BoxShape3D.new()
	shape.shape.size = Vector3.ONE*0.5
	obstacle.add_child(shape)
	await driver.frames(3)
	game._update_target()
	game._update_ghost()
	expect(not game.ghost.visible and not game.hud.target_panel.visible,"Scenery blocks distant guidance even for a compatible part")
	obstacle.queue_free()
	await driver.frames(3)
	await driver.aim(slot_point,3.0)
	game.set_paused(true)
	game._update_ghost()
	expect(not game.ghost.visible,"Pause clears yellow destination guidance")
	game.set_paused(false)
	await driver.aim(slot_point,6.2)
	expect(not game.ghost.visible,"Discovery stays limited to the local work area")
	await driver.aim(slot_point,1.2)
	expect(game.ghost.visible and game.ghost_material.albedo_color == game.SNAP_READY_COLOR and not game.hud.target_panel.visible,"Approaching the connection restores green ready-to-attach feedback")
	game.model.stock_pocket("h-12030")
	game.model.select_pocket(game.model.pocket_for("h-12030"))
	game._update_target()
	game._update_ghost()
	expect(not game.ghost.visible and game.hud.target_panel.visible and not game.hud.target_action.visible and game.interaction_outline.focused == null,"Incompatible hardware keeps feedback without advertising an available action")
	game.hud.toast_time = 0
	driver.key(KEY_E)
	expect(game.held_build() == "pitch" and game.hud.carry_label.text == "Carrying "+game.build_label("pitch") and game.hud.toast_time == 0,"Pickup over a connection carries its assembly and updates hands status without a popup")
	game.set_paused(true)
	expect(game.hud.pause_panel.get_child(0) is CenterContainer and game.hud.pause_card.get_theme_stylebox("panel").bg_color.a == 1,"Pause and help windows are opaque with no full-screen backdrop")
	game.set_paused(false)
	game.hud.browser.open_browser()
	expect(game.hud.browser.get_child(0) is MarginContainer and game.hud.manual.get_theme_stylebox("panel").bg_color.a == 1,"Manual browser windows are opaque with no full-screen backdrop")
	game.hud.browser.close_browser()
	# Check real UI layout at the workshop's logical resolution, including a
	# wrapped error beside the reader and the longest stocked pocket labels.
	game.set_process(false)
	# Service-view transparency must not acquire an opaque silhouette from the
	# inverted hull. Restore opacity and the same source becomes outlineable.
	var enclosure = MeshInstance3D.new()
	enclosure.mesh = BoxMesh.new()
	game.add_child(enclosure)
	var service = StandardMaterial3D.new()
	service.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	service.albedo_color.a = 0.16
	enclosure.material_override = service
	game.interaction_outline.focus(enclosure)
	expect(game.interaction_outline.copies.is_empty(),"A translucent service enclosure stays clear for internal inspection")
	enclosure.material_override = null
	game.interaction_outline.focus(enclosure)
	expect(game.interaction_outline.copies.size() == 1,"Returning an enclosure to opaque restores its focus contour")
	game.interaction_outline.clear()
	enclosure.queue_free()
	game.hud.present_target("FA-525 · Receiver collar\nSet down the carried component before collecting this part.","","",Vector2(1410,30))
	await driver.frames(3)
	expect(game.hud.target_panel.size.x<=261 and root.get_visible_rect().encloses(game.hud.target_panel.get_global_rect()),"Wrapped object feedback stays compact and inside the viewport")
	expect(not game.hud.target_panel.get_global_rect().intersects(game.hud.manual.get_global_rect()),"Object feedback avoids the open manual")
	var square_slots = game.hud.action_slots.all(func(slot):return is_equal_approx(slot.card.size.x,slot.card.size.y))
	expect(square_slots and game.hud.action_bar.size.x<=750 and game.hud.action_slots[0].model.size.x>=50,"Action-bar slots are square with readable image space in a compact row")
	for node in [game.hud.manual,game.hud.target_panel,game.hud.carry_panel,game.hud.action_slots[0].card]:
		expect(node.get_theme_stylebox("panel").bg_color.a<0.75,"HUD text panel has a translucent scrim: "+node.name)
	var passed = checks.all(func(check):return check.passed)
	DirAccess.make_dir_recursive_absolute("res://verification/interaction-feedback")
	FileAccess.open("res://verification/interaction-feedback/audit.json",FileAccess.WRITE).store_string(JSON.stringify({"passed":passed,"checks":checks,"engine":Engine.get_version_info().string},"  "))
	print("INTERACTION_FEEDBACK ","PASS" if passed else "FAIL"," ",checks.size()," checks")
	game.queue_free()
	driver.queue_free()
	await process_frame
	quit(0 if passed else 1)
