extends SceneTree
## Native scene/geometry checks. All writes use a unique temporary save slot.
const Store = preload("res://scripts/save_store.gd")
const Codec = preload("res://scripts/workshop_save.gd")
var game: Node
var checks: Array[Dictionary] = []
var save_path: String

func _initialize() -> void:
	run.call_deferred()

func expect(ok: bool, label: String) -> void:
	checks.append({"check":label, "passed":ok})
	print("CHECK ", "PASS " if ok else "FAIL ", label)
	if not ok:push_error(label)

func frames(count: int = 3) -> void:
	for index in range(count):await physics_frame

func station(owner: String, id: String) -> void:
	expect(game.model.move_assembly(owner, "station:" + id).is_empty(), "Suspend " + owner)
	game._activate(owner)
	game._set_pad_station(id)

func stage(owner: String, limit: int) -> int:
	var count = 0
	var definition: Dictionary = game.runtime.definition(owner)
	for pass_index in range(definition.slots.size()):
		var changed = false
		for sid in definition.slots:
			if not game.model.assemblies[owner].slots[sid].is_empty():continue
			var spec: Dictionary = definition.slots[sid]
			if spec.has("assembly"):continue
			if not spec.get("requires", []).all(func(required):return not game.model.assemblies[owner].slots[required].is_empty()):continue
			var uid: String
			if game.model.definitions.parts[spec.accepts].carry_class == "pocket":
				game.model.stock_pocket(spec.accepts)
				uid = game.model.find_item(spec.accepts, "pocket")
			else:
				uid = game.model.find_item(spec.accepts, "bin")
				game.model.carry_item(uid)
			if uid.is_empty():continue
			var result: Dictionary = game.model.install(owner, sid, uid)
			expect(result.ok, "Stage exact physical occupant " + owner + "/" + sid)
			if not result.ok:return count
			count += 1
			changed = true
			if count >= limit:break
		if count >= limit or not changed:break
	if game.builds.has(owner):
		game._activate(owner)
		game._sync_installed_visuals()
	else:game.components.sync(owner)
	return count

func available_hand() -> String:
	for uid in game.model.items:
		var item: Dictionary = game.model.items[uid]
		if item.location == "bin" and game.model.definitions.parts[item.kind].carry_class != "pocket":return uid
	return ""

func valid(snapshot: Dictionary, label: String) -> void:
	var errors: Array[String] = game.saves.validate(snapshot)
	if not errors.is_empty():print("SAVE_VALIDATION_DIAGNOSTIC ", errors)
	expect(errors.is_empty(), label)

func diagnose_json(value: Variant, path: String = "snapshot") -> void:
	if value is Dictionary:
		for key in value:
			if not key is String:print("INVALID_JSON_KEY ", path, " ", key, " ", typeof(key))
			diagnose_json(value[key], path + "/" + str(key))
	elif value is Array:
		for index in range(value.size()):diagnose_json(value[index], path + "/" + str(index))
	elif typeof(value) not in [TYPE_NIL, TYPE_BOOL, TYPE_INT, TYPE_STRING, TYPE_FLOAT]:print("INVALID_JSON_VALUE ", path, " ", typeof(value), " ", value)

func pause_layout() -> void:
	await process_frame
	await process_frame
	var viewport: Rect2 = root.get_visible_rect()
	var card: Rect2 = game.hud.pause_card.get_global_rect()
	expect(viewport.size.is_equal_approx(Vector2(1440, 900)) and viewport.encloses(card), "Native pause card fits inside the 1440 × 900 viewport")
	var controls: Array = [game.hud.save_button, game.hud.reload_button, game.hud.restart_button, game.hud.quit_button]
	var visible = true
	var separate = true
	for index in range(controls.size()):
		var rect: Rect2 = controls[index].get_global_rect()
		visible = visible and controls[index].is_visible_in_tree() and card.encloses(rect) and rect.has_area()
		for other in range(index + 1, controls.size()):
			separate = separate and not rect.intersects(controls[other].get_global_rect())
	expect(visible and separate, "Save, Reload, New workshop and Quit buttons are visible inside the pause card without overlap")
	if not viewport.encloses(card) or not visible or not separate:print("PAUSE_LAYOUT_DIAGNOSTIC viewport=", viewport, " card=", card)

func pose_matches(body: Node3D, saved: Dictionary) -> bool:
	return body.global_transform.is_equal_approx(Codec.to_pose(saved.pose))

func mounted_matches(owner: String) -> bool:
	var a: Dictionary = game.model.assemblies[owner]
	if a.parent.is_empty():return false
	var body: RigidBody3D = game.bodies[owner]
	var expected: Transform3D = game.runtime.mount_pose(a.parent, a.parent_slot, owner)
	var physics_pose: Transform3D = PhysicsServer3D.body_get_state(body.get_rid(), PhysicsServer3D.BODY_STATE_TRANSFORM)
	return body.get_parent() == game.assembly_node(a.parent) and body.global_transform.is_equal_approx(expected) and physics_pose.is_equal_approx(expected) and body.freeze and body.freeze_mode == RigidBody3D.FREEZE_MODE_STATIC and body.collision_layer == 0

func all_mounted_match() -> bool:
	return mounted_matches("pad_1") and mounted_matches("pad_2") and mounted_matches("pitch")

func complete_visual_inventory() -> bool:
	var seen: Dictionary = {}
	for piece in game.runtime.visual_pieces("foot"):
		var visual: MeshInstance3D = piece.visual
		var uid: String = visual.get_meta("component_uid", visual.get_meta("installed_uid", ""))
		if not game.model.items.has(uid):continue
		if seen.has(uid):return false
		seen[uid] = true
		if piece.owner == "pitch":
			var sid: String = game.model.items[uid].slot
			if not visual.global_transform.is_equal_approx(game.components.slot_pose("pitch", sid)):return false
	for uid in game.model.items:
		if game.model.items[uid].location == "installed" and not seen.has(uid):return false
	return true

func settle_loaded_carrier() -> bool:
	var follows = true
	for tick in range(700):
		await frames(1)
		follows = follows and all_mounted_match()
		if not game.foot_fixture.moving:break
	return follows and not game.foot_fixture.moving

func rail_resume() -> void:
	# The dispatch interlock requires the actual complete inventory and hardware.
	station("pad_1", "prep")
	station("pad_2", "prep2")
	station("pitch", "prep3")
	stage("pad_1", 1000)
	stage("pad_2", 1000)
	stage("pitch", 1000)
	var mount_slots = {"pad_1":"heel_1", "pad_2":"heel_2", "pitch":"pitch"}
	for owner in mount_slots:
		if owner == "pitch":stage("foot", 1000)
		var move_error: String = game.model.move_assembly(owner, "held")
		var install_result: Dictionary = game.model.install("foot", mount_slots[owner], owner)
		expect(move_error.is_empty() and install_result.ok, "Mount completed " + owner + " for secured rail transport")
		if not move_error.is_empty() or not install_result.ok:
			print("RAIL_STAGE_DIAGNOSTIC ", move_error, " ", install_result)
			return
		game.runtime.mount("foot", mount_slots[owner], owner)
	stage("foot", 1000)
	for owner in game.builds:
		game._activate(owner)
		game._sync_installed_visuals()
	game.components.sync("foot")
	game.refresh_assembly_collision("foot")
	var identities: Array = game.model.items.keys()
	expect(game.model.milestone("foot", "complete") and game.model.integrity_errors().is_empty(), "All three children and retention hardware satisfy dispatch completion interlock")
	expect(complete_visual_inventory(), "Every installed physical identity has one native visual including the complete actuator")
	valid(game.saves.capture(), "Fully secured supported foot validates before dispatch")
	game.player.global_position = Vector3(-0.4, 0.025, -1.8)
	game.player.velocity = Vector3.ZERO
	game.set_paused(false)
	expect(game.foot_fixture.request("transfer").is_empty(), "Secured upright assembly starts powered dispatch transfer")
	await frames(18)
	game.set_paused(true)
	var outgoing: Dictionary = game.saves.capture()
	valid(outgoing, "Mid-rail outgoing transfer snapshot validates")
	expect(outgoing.world.support.moving and outgoing.world.support.destination_dispatch and not outgoing.world.support.at_dispatch and game.foot.global_position.z > SupportedFootFixture.WORK_ORIGIN.z, "Capture outgoing carrier between the work and dispatch endpoints")
	expect(game.saves.save_now() and game.saves.reload_save(), "Persist and restore mid-rail outgoing transfer")
	expect(game.foot.global_transform.is_equal_approx(Codec.to_pose(outgoing.world.fixtures.foot)) and game.foot_fixture.moving and game.foot_fixture._destination_dispatch and not game.foot_fixture.at_dispatch, "Restore outgoing rail pose and destination flags exactly")
	await frames(2)
	expect(all_mounted_match() and complete_visual_inventory(), "All three restored children retain mounted native physics and complete mesh inventory")
	game.set_paused(false)
	expect(await settle_loaded_carrier() and game.foot_fixture.at_dispatch and game.foot.global_position.is_equal_approx(SupportedFootFixture.DISPATCH_ORIGIN), "Loaded restored carrier reaches dispatch with all child physics following continuously")
	game.set_paused(true)
	valid(game.saves.capture(), "Stopped dispatch endpoint snapshot validates")
	expect(game.saves.save_now() and game.saves.reload_save() and game.foot_fixture.at_dispatch and not game.foot_fixture.moving and game.foot_fixture._destination_dispatch, "Persist and restore the dispatch endpoint")
	game.set_paused(false)
	expect(game.foot_fixture.request("return").is_empty(), "Restored dispatch carrier starts its return route")
	await frames(18)
	game.set_paused(true)
	var returning: Dictionary = game.saves.capture()
	valid(returning, "Mid-rail return snapshot validates")
	expect(returning.world.support.moving and returning.world.support.at_dispatch and not returning.world.support.destination_dispatch and game.foot.global_position.z < SupportedFootFixture.DISPATCH_ORIGIN.z, "Capture returning carrier with distinct current and destination endpoint flags")
	expect(game.saves.save_now() and game.saves.reload_save(), "Persist and restore mid-rail return")
	expect(game.foot.global_transform.is_equal_approx(Codec.to_pose(returning.world.fixtures.foot)) and game.foot_fixture.moving and game.foot_fixture.at_dispatch and not game.foot_fixture._destination_dispatch, "Restore returning rail pose and destination flags exactly")
	game.set_paused(false)
	expect(await settle_loaded_carrier() and not game.foot_fixture.at_dispatch and game.foot.global_position.is_equal_approx(SupportedFootFixture.WORK_ORIGIN), "Loaded restored carrier completes its return with continuous child physics agreement")
	game.set_paused(true)
	valid(game.saves.capture(), "Returned secured foot snapshot validates")
	expect(game.model.items.keys() == identities and game.model.milestone("foot", "complete") and game.model.integrity_errors().is_empty() and complete_visual_inventory(), "Rail persistence conserves all identities, complete actuator visuals and secured ownership")

func rejected_without_mutation(snapshot: Dictionary, label: String) -> void:
	# A valid checksum makes the coordinator, rather than the file envelope, reject it.
	var before: Dictionary = game.saves.capture()
	expect(Store.write(save_path, game.saves.fingerprint, snapshot, false).is_empty(), "Write malformed-payload fixture")
	DirAccess.remove_absolute(save_path + ".bak")
	expect(not game.saves.reload_save(), label)
	expect(game.saves.capture() == before, label + " preserves live world and model")
	expect(Store.write(save_path, game.saves.fingerprint, before, false).is_empty(), "Restore valid test slot")
	expect(game.saves.reload_save(), "Recover live test session from valid slot")

func run() -> void:
	save_path = "/tmp/gundam-save-resume-%s-%s.json" % [OS.get_process_id(), Time.get_ticks_usec()]
	game = load("res://scenes/workshop.tscn").instantiate()
	root.add_child(game)
	game.automated_test = true
	await frames(6)
	expect(not game.saves.enabled and game.foot_fixture != null, "Headless supported workshop leaves the player save disabled")
	game.saves.setup(game, save_path, false)
	expect(game.saves.enabled and not game.saves.automatic and not FileAccess.file_exists(save_path), "Explicit temporary slot enables manual saves without touching user storage")
	valid(game.saves.capture(), "Initial real workshop snapshot validates")
	expect(game.saves.save_now(), "Create the initial temporary save before checking pause layout")
	await pause_layout()
	station("pad_1", "prep")
	station("pad_2", "prep2")
	station("pitch", "prep3")
	expect(stage("pad_1", 2) == 2 and stage("pad_2", 1) == 1 and stage("pitch", 3) == 3, "Two pads and actuator retain simultaneous unfinished work")
	game.model.stock_pocket("washer")
	game.model.select_pocket(8)
	game.hud.open_manual("pad_1", 1)
	game.hud.open_manual("pad_2", 1)
	game.hud.open_manual("pitch", 2)
	game.hud.browser.set_suggested_only(false)
	game._activate("pitch")
	game.stations.prep.basis = Basis.from_euler(Vector3(0.24, -0.35, 0.16))
	game.player.global_transform = Transform3D(Basis(Vector3.UP, 0.65), Vector3(-0.4, 0.025, -1.8))
	game.player.velocity = Vector3(0.12, -0.1, 0.08)
	game._update_crouch(true, 1.0)
	game.camera.rotation.x = -0.23
	game.camera.fov = 62.0
	var partial: Dictionary = game.saves.capture()
	valid(partial, "Interleaved unfinished builds, pocket selection and per-manual pages validate")
	expect(game.saves.save_now(), "Save unfinished real workshop")
	if not FileAccess.file_exists(save_path):
		print("SAVE_WRITE_DIAGNOSTIC ", game.saves.message)
		diagnose_json(partial)
		quit(1)
		return
	game.model.select_pocket(0)
	game.hud.open_manual("foot", 0)
	game.hud.browser.open_browser()
	expect(game.saves.reload_save(), "Reload unfinished real workshop")
	expect(not game.hud.browser.visible and game.hud.manual.get_parent() == game.hud.root and game.hud.manual.visible and game.paused, "Reload from an open browser returns the restored manual to the normal HUD")
	expect(game.saves.capture().model == partial.model, "Restore all physical identities, partial progress and pockets")
	expect(game.hud.pages == partial.world.reader.pages and game.hud.manual_id == "pitch" and game.model.selected_pocket == 8 and not game.hud.browser.suggested_only, "Restore separate reader pages, manual, filter and selected pocket")
	expect(game.bodies.pitch.get_parent() == game.stations.prep3 and game.bodies.pad_2.get_parent() == game.stations.prep2, "Restore suspended bodies to their own stations")
	expect(game.stations.prep.global_transform.is_equal_approx(Codec.to_pose(partial.world.stations.prep)) and game.bodies.pad_1.global_transform.is_equal_approx(game.stations.prep.global_transform), "Restore multi-axis station rotation and its suspended assembly")
	expect(game.player.global_transform.is_equal_approx(Codec.to_pose(partial.world.player.pose)) and game.player.velocity.is_equal_approx(Codec.to_vector(partial.world.player.velocity)) and game.crouched and is_equal_approx(game.camera.position.y, 0.93) and is_equal_approx(game.camera.rotation.x, -0.23) and is_equal_approx(game.camera.fov, 62.0) and is_equal_approx(game.player_collision.shape.height, 1.0), "Restore player pose, velocity, crouch collision and camera view")
	var clone = load("res://scenes/workshop.tscn").instantiate()
	root.add_child(clone)
	clone.automated_test = true
	clone.saves.setup(clone, save_path, false)
	expect(clone.saves.restored and clone.paused and clone.saves.capture().model == partial.model and clone.hud.manual_id == "pitch", "A fresh scene automatically resumes the persisted slot on setup")
	clone.free()
	var hand_uid = available_hand()
	expect(not hand_uid.is_empty(), "Scenario has an uninstalled large component")
	game.components.collect(game.model.items[hand_uid].kind, false, hand_uid)
	var held_component: Dictionary = game.saves.capture()
	valid(held_component, "Held physical component snapshot validates")
	expect(game.saves.save_now(), "Save held component")
	game.components.drop()
	expect(game.saves.reload_save(), "Restore held component after dropping")
	expect(game.model.held_item() == hand_uid and is_instance_valid(game.components.held_body) and game.components.held_body.held and game.components.held_body.freeze_mode == RigidBody3D.FREEZE_MODE_KINEMATIC and pose_matches(game.components.held_body, held_component.world.items[hand_uid]), "Restore exact component identity, hand ownership and carrying body")
	game.components.drop()
	var loose_body: RigidBody3D = game.loose[hand_uid]
	loose_body.global_transform = Transform3D(Basis.from_euler(Vector3(0.2, 0.4, 0.1)), Vector3(-0.3, 1.35, 0.5))
	loose_body.linear_velocity = Vector3(0.12, 0.03, -0.04)
	loose_body.angular_velocity = Vector3(0.03, 0.08, 0.02)
	var loose_snapshot: Dictionary = game.saves.capture()
	valid(loose_snapshot, "Loose component pose and motion validate")
	expect(game.saves.save_now(), "Save loose component motion")
	loose_body.global_position += Vector3.UP
	expect(game.saves.reload_save(), "Reload loose component pose")
	loose_body = game.loose[hand_uid]
	expect(pose_matches(loose_body, loose_snapshot.world.items[hand_uid]) and loose_body.linear_velocity.is_equal_approx(Codec.to_vector(loose_snapshot.world.items[hand_uid].linear)) and loose_body.angular_velocity.is_equal_approx(Codec.to_vector(loose_snapshot.world.items[hand_uid].angular)) and not loose_body.freeze, "Restore loose body transform and linear/angular motion")
	# Resume grip on a whole unfinished build in a separate snapshot.
	game.model.move_assembly("pad_2", "held")
	var held_body: WorkshopPart = game.bodies.pad_2
	held_body.reparent(game)
	held_body.held = true
	held_body.freeze = true
	held_body.freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
	var held_assembly: Dictionary = game.saves.capture()
	valid(held_assembly, "Held assembly snapshot validates separately from component grip")
	expect(game.saves.save_now() and game.saves.reload_save(), "Save and reload a held unfinished assembly")
	expect(game.held_build() == "pad_2" and held_body.held and held_body.freeze_mode == RigidBody3D.FREEZE_MODE_KINEMATIC and pose_matches(held_body, held_assembly.world.bodies.pad_2), "Restore held assembly grip and world transform")
	station("pad_2", "prep2")
	# Complete one pad, mount its native body, then restore through real geometry.
	expect(stage("pad_1", 20) == 2 and game.model.milestone("pad_1", "prepared"), "Finish one saved child while sibling and actuator remain unfinished")
	game.model.move_assembly("pad_1", "held")
	expect(game.model.install("foot", "heel_2", "pad_1").ok, "Mount prepared compatible child at opposite parent slot")
	game._activate("pad_1")
	game._set_pad_foot()
	game._sync_installed_visuals()
	game.player.global_position = Vector3(-0.4, 0.025, -1.8)
	game.player.velocity = Vector3.ZERO
	game.set_paused(false)
	expect(game.foot_fixture.request("sole_left").is_empty(), "Start supported-foot working pose change with mounted child")
	await frames(14)
	game.set_paused(true)
	var moving: Dictionary = game.saves.capture()
	valid(moving, "Mounted child and foot captured during actual powered motion validate")
	expect(moving.world.support.moving and game.foot.global_basis != Basis.IDENTITY and game.saves.save_now(), "Persist intermediate supported-foot pose and destination")
	expect(game.saves.reload_save() and game.foot_fixture.moving and game.foot_fixture._destination_pose == "sole_left", "Restore paused motion with original powered destination")
	await frames(2)
	expect(mounted_matches("pad_1"), "Restored child body and native physics pose follow parent attachment")
	var visuals = 0
	var collision_owned = false
	for visual in game.bodies.pad_1.get_children():
		if visual is MeshInstance3D and visual.has_meta("installed_uid"):visuals += 1
	for col in game.foot.get_children():
		if col is CollisionShape3D and col.get_meta("physical_uid", "") == game.builds.pad_1.pad_id:collision_owned = true
	expect(visuals == 4 and collision_owned, "Restore installed child meshes and root-owned compound collision")
	game.set_paused(false)
	var follows = true
	for tick in range(400):
		await frames(1)
		follows = follows and mounted_matches("pad_1")
		if not game.foot_fixture.moving:break
	expect(not game.foot_fixture.moving and game.foot_fixture.work_pose == "sole_left" and follows, "Resume powered motion through completion with continuous child body/physics agreement")
	game.set_paused(true)
	valid(game.saves.capture(), "Stopped restored indexed working pose validates")
	game.hud.open_manual("foot", 0)
	game.undo_build()
	expect(game.model.assemblies.pad_1.parent.is_empty() and game.model.assemblies.pad_1.location.begins_with("station:") and game.model.milestone("pad_1", "prepared"), "Parent undo after resume detaches the exact built child into a free station")
	game.hud.open_manual("pad_1", 0)
	game.undo_build()
	expect(game.model.assemblies.pad_1.history.size() == 3 and game.model.integrity_errors().is_empty(), "Child undo continues after loaded mount undo")
	var correct: Dictionary = game.saves.capture()
	var invalid = correct.duplicate(true)
	invalid.model.assemblies.pad_2.history.clear()
	rejected_without_mutation(invalid, "Reject invalid model payload transactionally")
	invalid = correct.duplicate(true)
	invalid.world.stations.prep[9] += 1.0
	rejected_without_mutation(invalid, "Reject moved station payload transactionally")
	invalid = correct.duplicate(true)
	invalid.world.player.pose[0] = 0.0
	rejected_without_mutation(invalid, "Reject invalid world basis transactionally")
	invalid = correct.duplicate(true)
	invalid.model.assemblies.pad_2.location = "station:unknown"
	rejected_without_mutation(invalid, "Reject unknown occupied runtime station")
	game.set_paused(false)
	game.model.select_pocket(2)
	game.saves.automatic = true
	game.saves.elapsed = 0.0
	game.saves._process(29.0)
	expect(Store.read(save_path, game.saves.fingerprint).payload.model.selected_pocket != 2, "Autosave waits for its interval")
	game.saves._process(1.1)
	expect(Store.read(save_path, game.saves.fingerprint).payload.model.selected_pocket == 2 and game.saves.elapsed == 0.0, "Autosave interval persists the active workshop and resets its timer")
	game.set_paused(true)
	game.model.select_pocket(1)
	game.saves._process(31.0)
	expect(Store.read(save_path, game.saves.fingerprint).payload.model.selected_pocket == 2, "Periodic autosave is suspended in the pause menu")
	game.saves.automatic = false
	# Normal pause and explicit UI save produce persistence, including pages.
	game.set_paused(false)
	game.model.select_pocket(6)
	game.hud.open_manual("pitch", 3)
	game.set_paused(true)
	var paused_save = Store.read(save_path, game.saves.fingerprint)
	expect(paused_save.ok and paused_save.payload.model.selected_pocket == 6 and paused_save.payload.world.reader.pages.pitch == 3, "Pausing saves progress and reader context")
	game.model.select_pocket(5)
	game.hud.save_button.pressed.emit()
	expect(Store.read(save_path, game.saves.fingerprint).payload.model.selected_pocket == 5, "Pause menu Save writes current state")
	game.model.select_pocket(4)
	game.hud.reload_button.pressed.emit()
	expect(game.hud.confirm_reload and game.model.selected_pocket == 4, "Reload menu first click asks before replacing live work")
	game.hud.reload_button.pressed.emit()
	expect(not game.hud.confirm_reload and game.model.selected_pocket == 5, "Reload menu confirmation restores saved work")
	# The backup is the previous successful snapshot, not the damaged primary.
	game.model.select_pocket(3)
	expect(game.saves.save_now(), "Create valid previous backup")
	FileAccess.open(save_path, FileAccess.WRITE).store_string("truncated")
	expect(game.saves.reload_save() and game.model.selected_pocket == 5 and game.saves.message.contains("backup"), "Recover previous workshop from backup when primary is truncated")
	var backup_bytes = FileAccess.get_file_as_bytes(save_path + ".bak")
	expect(game.saves.save_now() and FileAccess.get_file_as_bytes(save_path + ".bak") == backup_bytes, "First save after backup recovery preserves the good backup")
	var envelope: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(save_path))
	envelope.version = 999
	var unsupported_text = JSON.stringify(envelope)
	FileAccess.open(save_path, FileAccess.WRITE).store_string(unsupported_text)
	var before_unsupported: Dictionary = game.saves.capture()
	expect(not game.saves.reload_save() and game.saves.blocked and game.saves.capture() == before_unsupported, "Unsupported primary blocks recovery without changing the live session")
	expect(not game.saves.save_now() and FileAccess.get_file_as_string(save_path) == unsupported_text and game.hud.save_button.disabled, "Unsupported primary is protected from normal save and disabled in UI")
	game.hud.restart_button.pressed.emit()
	expect(game.hud.confirm_restart and FileAccess.get_file_as_string(save_path) == unsupported_text, "New workshop menu first click preserves protected save")
	game.hud.restart_button.pressed.emit()
	expect(not game.saves.blocked and game.saves.has_save and game.model.assemblies.pad_1.history.is_empty() and game.model.assemblies.pitch.history.is_empty() and game.model.pocket_count() == 0, "Confirmed new workshop replaces protected save and resets construction")
	valid(game.saves.capture(), "Fresh workshop after confirmed reset validates")
	expect(Store.read(save_path, game.saves.fingerprint).ok and game.hud.resume_button.text.contains("Start building"), "New workshop persists and returns to the start action")
	var protected_bytes = FileAccess.get_file_as_bytes(save_path)
	var protected_model: Dictionary = game.saves.capture().model
	game.saves.path = save_path + "-missing-parent/slot.json"
	game.set_paused(false)
	game.saves.quit_game()
	expect(game.paused and game.hud.discard_offered and game.hud.quit_button.text == "Quit without saving", "Failed Save & quit keeps the game open and offers an explicit discard action")
	expect(FileAccess.get_file_as_bytes(save_path) == protected_bytes and game.saves.capture().model == protected_model, "Failed quit preserves the original slot and live construction")
	game.hud._clear_save_confirmations()
	game.set_paused(false)
	game.hud.browser.open_browser()
	expect(game.hud.browser.visible, "Open manual browser before testing window close failure")
	game.saves._notification(Node.NOTIFICATION_WM_CLOSE_REQUEST)
	expect(game.paused and game.hud.discard_offered and not game.hud.browser.visible and game.hud.manual.get_parent() == game.hud.root, "Window close failure closes the browser, returns the manual and exposes discard protection")
	game.saves.path = save_path
	game.hud.save_button.pressed.emit()
	expect(not game.hud.discard_offered and game.saves.has_save and Store.read(save_path, game.saves.fingerprint).ok, "Saving to a repaired destination clears the discard offer")
	await rail_resume()
	var passed = checks.all(func(check):return check.passed)
	FileAccess.open("/tmp/save-resume.audit.json", FileAccess.WRITE).store_string(JSON.stringify({"passed":passed,"checks":checks,"engine":Engine.get_version_info().string,"rendered":false,"save_path":save_path}, "  "))
	for suffix in ["", ".bak"]:DirAccess.remove_absolute(save_path + suffix)
	game.chime.stop()
	game.chime.stream = null
	await frames(2)
	print("SAVE_RESUME_AUDIT ", "PASS" if passed else "FAIL", " ", checks.size(), " checks")
	quit(0 if passed else 1)
