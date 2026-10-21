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
	game.hud.toast_time = 0
	driver.key(KEY_E)
	expect(game.model.held_item() == "FA-514__001" and game.hud.carry_panel.visible and game.hud.carry_label.text == "Carrying "+game.components.title(cartridge_kind),"Carrying a shelf component shows only its hands status, without the selected pocket")
	expect(game.hud.toast_time == 0,"Starting to carry a shelf component does not create a popup")
	game.set_paused(true)
	expect(not game.hud.carry_panel.visible,"Pause hides the hands strip")
	game.set_paused(false)
	expect(game.hud.carry_panel.visible,"Resuming restores the occupied hands strip")
	driver.key(KEY_Q)
	expect(not game.hud.carry_panel.visible and game.model.held_item().is_empty(),"Setting down a component immediately hides the hands strip")
	await driver.aim(game.loose["FA-514__001"].global_position,0.9)
	driver.key(KEY_E)
	expect(game.model.held_item() == "FA-514__001" and game.hud.toast_time == 0,"Picking up a loose component uses the hands strip without a popup")
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
		stable_pickup = stable_pickup and game.target.get("type","") == "pad" and game.target.get("build","") == "pitch" and game.hud.target_action_label.text == "Carry"
	expect(stable_pickup,"Empty-handed aim across an unfinished assembly keeps one assembly pickup prompt")
	game.model.stock_pocket("w-12")
	var stable_connection = true
	for offset in [-0.04,0.0,0.04]:
		await driver.aim(slot_point+Vector3(offset,0,0),1.2)
		stable_connection = stable_connection and game.target.get("type","") == "component" and game.target.get("owner","") == "pitch" and game.ghost.visible
	expect(stable_connection,"Selected hardware keeps nearby connections ahead of their assembly pickup target")
	await driver.aim(game.components.slot_point("pitch","W-12__039"),1.2)
	expect(game.target.get("type","") == "component" and game.ghost.visible and not game.hud.target_panel.visible,"A valid green attachment preview needs no click-to-attach tooltip")
	game.model.stock_pocket("h-12030")
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
