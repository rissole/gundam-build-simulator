extends Node
## One local slot. Validate a detached snapshot before touching the live workshop.
const ModelSave = preload("res://scripts/save_model.gd")
const Store = preload("res://scripts/save_store.gd")
const Codec = preload("res://scripts/pose_codec.gd")
const SAVE_PATH = "user://workshop-save.json"
const AUTOSAVE_SECONDS = 30.0
const WORLD_VERSION = 1
const TRIAL_VERSION = 3

var game: Node
var baseline: AssemblyModel
var initial: Dictionary
var path: String = SAVE_PATH
var fingerprint: String
var enabled = false
var automatic = true
var has_save = false
var restored = false
var blocked = false
var applying = false
var elapsed = 0.0
var message = ""
var rotate_backup = true

func setup(workshop: Node, path_override: String = "", use_automatic: bool = true) -> void:
	game = workshop
	automatic = use_automatic
	path = game.profile.session.path if path_override.is_empty() else path_override
	var trial = _trial()
	var script_launch = OS.get_cmdline_args().has("--script") or OS.get_cmdline_args().has("-s")
	enabled = not path_override.is_empty() or (not script_launch and DisplayServer.get_name() != "headless" and not game.automated_test and not path.is_empty() and (trial or is_instance_valid(game.foot_fixture)))
	baseline = AssemblyModel.new()
	var configuration_errors = baseline.configure(game.model.definitions,game.config)
	assert(configuration_errors.is_empty(),str(configuration_errors))
	var materials: Dictionary = {"world":WORLD_VERSION,"definitions":game.model.definitions,"scenario":game.config,"supported":is_instance_valid(game.foot_fixture),"geometry":FileAccess.get_sha256("res://assets/foot-fa01.glb")}
	if trial:
		materials = {"m2":TRIAL_VERSION,"trial":game.profile.trial,"definitions":game.model.definitions,"scenario":game.config,"sources":game.leg_content.sources,"geometry":FileAccess.get_sha256("res://assets/foot-fa01.glb"),"layout":FileAccess.get_sha256(game.profile.get("layout_path","res://assets/leg-bay-layout.json"))}
	fingerprint = JSON.stringify(materials).sha256_text()
	initial = capture()
	if enabled:
		game.get_tree().auto_accept_quit = false
		if trial and game.get_tree().get_meta("m2_reset",false):
			game.get_tree().remove_meta("m2_reset");new_workshop()
		else:reload_save(true)
	_refresh()

func _trial() -> bool:
	return game.profile.session.codec == "trial"

func status_text() -> String:
	if game.profile.trial == "m3" and not enabled:return "M3 wider workshop · saving is off while the structure is built.\nRestart begins again from this launch's starting point."+("\n"+game.m3_stage_notice if not game.m3_stage_notice.is_empty() else "")
	if _trial():
		var title = "M3 Complete leg" if game.profile.trial == "m3" else ("Hip retainer" if game.profile.trial == "retention" else "Crane delivery")
		return title+" · separate workshop save slot.\n"+(message if not message.is_empty() else ("Autosaves on pause, quit and every 30 seconds. Restart resets only this trial." if enabled else "Headless/test session; normal saves are untouched."))
	if not enabled:return "This scenario is session-only.\nYour saved workshop is untouched."
	if not message.is_empty():return message
	return "Autosaves every 30 seconds, on pause and on quit.\nYour workshop resumes when you reopen the game."

func _process(delta: float) -> void:
	if not enabled or not automatic or blocked or applying or game.paused:return
	elapsed += delta
	if elapsed >= AUTOSAVE_SECONDS:save_now()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST and enabled:quit_game()

func _refresh() -> void:
	if is_instance_valid(game) and is_instance_valid(game.hud):game.hud.refresh_save_status()

func _failure(error: String, protect: bool = false) -> bool:
	blocked = blocked or protect
	elapsed = 0.0
	message = "Could not save/resume: "+error+"\n"+("Existing save preserved. New workshop replaces this slot." if blocked else "Your current workshop is still open. Try Save again.")
	_refresh()
	if not game.paused:game.hud.toast("Saving needs attention. Open the pause menu for details.")
	return false

func _read_valid(file_path: String) -> Dictionary:
	var result: Dictionary = Store.read(file_path,fingerprint)
	if result.ok:
		var errors = validate(result.payload)
		if not errors.is_empty():
			result.ok = false
			result.error = errors[0]
	return result

func save_now() -> bool:
	if not enabled:return true
	if applying:return false
	if blocked:return false
	var snapshot = capture()
	var errors = validate(snapshot)
	if not errors.is_empty():return _failure(errors[0])
	# Do not rotate a damaged or externally replaced primary over a good backup.
	if rotate_backup and Store.exists(path):
		var previous = _read_valid(path)
		if not previous.ok:return _failure(previous.error,true)
	var error: String = Store.write(path,fingerprint,snapshot,rotate_backup)
	if not error.is_empty():return _failure(error)
	rotate_backup = true
	has_save = true
	elapsed = 0.0
	message = "Saved locally at "+Time.get_time_string_from_system()+".\nAutosave is on · pause and quit also save."
	_refresh()
	return true

func reload_save(startup: bool = false) -> bool:
	if not enabled:return false
	var result = _read_valid(path)
	var recovered = false
	if not result.ok:
		# A newer/different content save must never be silently downgraded to a backup.
		if result.get("unsupported",false):return _failure(result.error,true)
		var backup = _read_valid(path+".bak")
		if not backup.ok:
			if startup and result.get("missing",false) and backup.get("missing",false):return false
			return _failure(result.error+" No compatible backup is available.",true)
		result = backup
		recovered = true
	apply_snapshot(result.payload)
	has_save = true
	restored = true
	blocked = false
	rotate_backup = not recovered
	elapsed = 0.0
	message = ("Recovered the previous save from backup." if recovered else "Restored your saved workshop.")+"\nAutosave is on · pause and quit also save."
	game.hud.entered = true
	game.set_paused(true)
	_refresh()
	return true

func new_workshop() -> bool:
	if enabled:
		var current = _read_valid(path)
		var error: String = Store.write(path,fingerprint,initial,current.ok)
		if not error.is_empty():return _failure(error)
	apply_snapshot(initial)
	blocked = false
	restored = false
	has_save = enabled
	rotate_backup = true
	elapsed = 0.0
	message = "New workshop saved.\nAutosave is on · pause and quit also save."
	game.hud.entered = false
	game.set_paused(true)
	_refresh()
	return true

func quit_game(discard: bool = false) -> void:
	if discard or not enabled or save_now():
		game.get_tree().quit()
		return
	# A failed write must not silently throw away the live session.
	applying = true
	_pause_menu()
	applying = false
	game.hud.offer_discard()

func _pause_menu() -> void:
	# The browser reparents the manual into its reader. Close it normally before
	# showing the pause card, including a failed OS quit while browsing a manual.
	if game.hud.browser.visible:
		game.hud.browser.return_to_pause = true
		game.hud.browser.close_browser()
	game.set_paused(true)

# Thin delegates: snapshot callers and tests address poses through this codec.
static func vector(value: Vector3) -> Array:return Codec.vector(value)
static func pose(value: Transform3D) -> Array:return Codec.pose(value)
static func to_vector(value: Array) -> Vector3:return Codec.to_vector(value)
static func to_pose(value: Array) -> Transform3D:return Codec.to_pose(value)
static func number(value: Variant, limit: float = 256.0) -> bool:return Codec.number(value,limit)
static func valid_vector(value: Variant, count: int = 3) -> bool:return Codec.valid_vector(value,count)
static func valid_pose(value: Variant) -> bool:return Codec.valid_pose(value)
static func same_keys(value: Variant, expected: Array) -> bool:return Codec.same_keys(value,expected)

# Attached children have exactly one legal transform, derived from their
# receiving connection; saved world poses are only audited against it.
func _saved_assembly_pose(owner: String, world: Dictionary, candidate: AssemblyModel) -> Transform3D:
	var a: Dictionary = candidate.assemblies[owner]
	if not a.parent.is_empty():return _saved_mount_pose(a.parent,a.parent_slot,owner,_saved_assembly_pose(a.parent,world,candidate),world)
	return to_pose(world.fixtures[owner] if world.fixtures.has(owner) else world.bodies[owner].pose)

func _saved_mount_pose(parent: String, sid: String, child: String, parent_pose: Transform3D, world: Dictionary={}) -> Transform3D:
	var slot: Dictionary = baseline.slot_definition(parent,sid)
	var anchor: String = slot.get("child_anchor_slot","")
	var local_anchor = game.runtime.local_slot_pose(child,anchor) if not anchor.is_empty() else Transform3D.IDENTITY
	var local_pose=game.runtime.local_slot_pose(parent,sid,false)
	if slot.has("mounted_motion"):
		var controller=game.equipment.get_equipment(slot.mounted_motion)
		local_pose=controller.local_mount_pose(world.get("equipment",{}).get(slot.mounted_motion,{}))
	return parent_pose*local_pose*local_anchor.affine_inverse()

static func body_state(body: RigidBody3D) -> Dictionary:
	return {"pose":pose(body.global_transform),"linear":vector(body.linear_velocity),"angular":vector(body.angular_velocity)}

func capture() -> Dictionary:
	var world = {"stations":{},"fixtures":{},"bodies":{},"items":{},"support":{},"active_build":game.active_build}
	for id in game.stations:world.stations[id] = pose(game.stations[id].global_transform)
	for id in game.runtime.nodes:
		if not game.bodies.has(id):world.fixtures[id] = pose(game.assembly_node(id).global_transform)
		elif game.model.assemblies[id].parent.is_empty():world.bodies[id] = body_state(game.bodies[id])
	for uid in game.model.items:
		var location: String = game.model.items[uid].location
		if location == "loose" and game.loose.has(uid) and is_instance_valid(game.loose[uid]):world.items[uid] = body_state(game.loose[uid])
		elif location == "held" and is_instance_valid(game.components.held_body):world.items[uid] = body_state(game.components.held_body)
	if is_instance_valid(game.foot_fixture):world.support = game.foot_fixture.capture()
	if _trial():
		world["equipment"] = game.equipment.capture()
		world["trial"] = game.trial.capture()
	world["player"] = {"pose":pose(game.player.global_transform),"velocity":vector(game.player.velocity),"pitch":game.camera.rotation.x,"height":game.camera.position.y,"fov":game.camera.fov,"crouched":game.crouched}
	world["reader"] = {"manual":game.hud.manual_id,"pages":game.hud.pages.duplicate(),"visible":game.hud.manual.visible,"suggested_only":game.hud.browser.suggested_only}
	return {"model":ModelSave.capture(game.model),"world":world}

static func valid_body(value: Variant) -> bool:
	return value is Dictionary and valid_pose(value.get("pose")) and valid_vector(value.get("linear")) and valid_vector(value.get("angular"))

func validate(data: Variant) -> Array[String]:
	if not data is Dictionary:return ["Missing workshop snapshot."]
	var errors: Array[String] = ModelSave.validate(data.get("model"),baseline)
	if not errors.is_empty():return errors
	var w = data.get("world")
	if not w is Dictionary:return ["Missing workshop positions."]
	if not same_keys(w.get("stations"),game.stations.keys()):return ["Preparation stations changed."]
	for id in w.stations:
		if not valid_pose(w.stations[id]):return ["Invalid station pose."]
		if not to_pose(w.stations[id]).origin.is_equal_approx(to_pose(initial.world.stations[id]).origin):return ["Preparation station moved from its anchors."]
	var roots: Array = []
	var fixtures: Array = []
	for id in data.model.assemblies:
		var a: Dictionary = data.model.assemblies[id]
		if not game.bodies.has(id):fixtures.append(id)
		elif a.parent.is_empty():roots.append(id)
		if a.location.begins_with("station:") and not game.stations.has(a.location.trim_prefix("station:")):return ["Unknown occupied station."]
	if not same_keys(w.get("bodies"),roots) or not same_keys(w.get("fixtures"),fixtures):return ["Assembly positions do not match ownership."]
	for id in w.bodies:
		if not valid_body(w.bodies[id]):return ["Invalid assembly pose or motion."]
		var location: String = data.model.assemblies[id].location
		if location.begins_with("station:") and not to_pose(w.bodies[id].pose).is_equal_approx(to_pose(w.stations[location.trim_prefix("station:")])):return ["Suspended assembly is detached from its station."]
	for id in w.fixtures:
		if not valid_pose(w.fixtures[id]):return ["Invalid receiving fixture pose."]
	var physical: Array = []
	for uid in data.model.items:
		if data.model.items[uid].location in ["loose","held"]:physical.append(uid)
	if not same_keys(w.get("items"),physical):return ["Loose or carried pieces do not match inventory."]
	for uid in w.items:
		if not valid_body(w.items[uid]):return ["Invalid loose component pose or motion."]
	if not w.get("active_build") is String or not game.builds.has(w.active_build):return ["Unknown active build."]
	var p = w.get("player")
	if not p is Dictionary or not valid_pose(p.get("pose")) or not valid_vector(p.get("velocity")) or not p.get("crouched") is bool:return ["Invalid player position."]
	if not number(p.get("pitch"),PI/2) or not number(p.get("height")) or p.height < 0.9 or p.height > 1.64 or not number(p.get("fov")) or p.fov < 20 or p.fov > 100:return ["Invalid camera view."]
	if not to_pose(p.pose).basis.y.is_equal_approx(Vector3.UP):return ["Player must stand upright."]
	var r = w.get("reader")
	if not r is Dictionary or not r.get("manual") is String or not baseline.assemblies.has(r.manual) or not r.get("pages") is Dictionary or not r.get("visible") is bool or not r.get("suggested_only") is bool:return ["Invalid manual selection."]
	for id in r.pages:
		if not baseline.assemblies.has(id) or not number(r.pages[id]) or r.pages[id] != int(r.pages[id]):return ["Unknown manual page."]
		var page_count: int = baseline.definitions.assemblies[baseline.assemblies[id].definition].manual.size()
		if r.pages[id] < 0 or r.pages[id] >= page_count:return ["Manual page is out of range."]
	if _trial():
		var candidate = AssemblyModel.new();candidate.configure(baseline.definitions,game.config);ModelSave.apply(data.model,candidate)
		errors = game.equipment.validate(w.get("equipment"),candidate,w)
		if not errors.is_empty():return errors
		errors = game.trial.validate(w.get("trial"),candidate,initial,w)
		if not errors.is_empty():return errors
		for id in w.fixtures:
			var a: Dictionary = candidate.assemblies[id]
			if not a.parent.is_empty():
				var parent_pose = _saved_assembly_pose(a.parent,w,candidate)
				if not to_pose(w.fixtures[id]).is_equal_approx(_saved_mount_pose(a.parent,a.parent_slot,id,parent_pose,w)):return ["Mounted fixture pose disagrees with its parent."]

	return _validate_support(w,data.model)

func _validate_support(w: Dictionary, saved_model: Dictionary) -> Array[String]:
	var s = w.get("support")
	if not s is Dictionary:return ["Missing foot support state."]
	if not is_instance_valid(game.foot_fixture):
		if s.is_empty():return []
		return ["Unexpected foot support."]
	var candidate = AssemblyModel.new()
	candidate.configure(baseline.definitions,game.config)
	ModelSave.apply(saved_model,candidate)
	return game.foot_fixture.validate(s,candidate,w)

func apply_snapshot(snapshot: Dictionary) -> bool:
	# Keep this boundary transactional even for direct callers and UI reset paths.
	if not validate(snapshot).is_empty():return false
	applying = true
	_pause_menu()
	game.target.clear()
	game.ghost.hide()
	game.ghost_assembly_signature = ""
	game.interaction_outline.clear()
	for body in game.loose.values():
		if is_instance_valid(body):body.free()
	game.loose.clear()
	if is_instance_valid(game.components.held_body):game.components.held_body.free()
	game.components.held_body = null
	# Detach before changing ownership, so no old parent carries a restored child.
	if _trial():
		for id in game.runtime.nodes:
			var node: Node3D = game.runtime.node(id)
			if node.get_parent() != game:node.reparent(game)
	for body in game.bodies.values():
		body.freeze = true
		body.freeze_mode = RigidBody3D.FREEZE_MODE_STATIC
		body.held = false
		if body.get_parent() != game:body.reparent(game)
	# Rebuild slot visuals even when a compatible physical copy changed slots.
	# The source geometry belongs to the receiving slot, not the consumed identity.
	for id in game.runtime.nodes:
		var definition: Dictionary = game.runtime.definition(id)
		var root_slot: String = definition.get("root_slot","")
		var root_uid: String = baseline.assemblies[id].slots.get(root_slot,"")
		for visual in game.assembly_node(id).get_children():
			if not visual is MeshInstance3D:continue
			if visual.has_meta("component_uid") and visual.get_meta("component_uid") != root_uid:
				visual.free()
	ModelSave.apply(snapshot.model,game.model)
	var w: Dictionary = snapshot.world
	for id in w.stations:game.stations[id].global_transform = to_pose(w.stations[id])
	for id in w.fixtures:game.assembly_node(id).global_transform = to_pose(w.fixtures[id])
	if is_instance_valid(game.foot_fixture):game.foot_fixture.apply(w.support)
	if _trial():game.equipment.apply(w.equipment)
	for id in w.bodies:
		var body: WorkshopPart = game.bodies[id]
		var location: String = game.model.assemblies[id].location
		if location.begins_with("station:"):game.suspend_build(id,location.trim_prefix("station:"))
		_restore_body(body,w.bodies[id],location)
	# Parent-first traversal derives exact child mount transforms from authored slots.
	for id in game.model.assemblies:
		if game.model.assemblies[id].parent.is_empty():_mount_children(id)
	for id in game.builds:
		game.components.sync(id)
		game.prepared_flags[id] = game.build_prepared(id)
		game.completed_flags[id] = game.build_complete(id)
	if _trial():
		for id in game.runtime.nodes:
			var body: CollisionObject3D = game.runtime.node(id)
			if body is AnimatableBody3D:PhysicsServer3D.body_set_mode(body.get_rid(),PhysicsServer3D.BODY_MODE_STATIC)
			body.force_update_transform()
			PhysicsServer3D.body_set_state(body.get_rid(),PhysicsServer3D.BODY_STATE_TRANSFORM,body.global_transform)
	for id in w.fixtures:game.components.sync(id)
	for id in game.model.assemblies:
		if game.model.assemblies[id].parent.is_empty():game.refresh_assembly_collision(id)
	for uid in w.items:
		game._spawn_loose(uid,true)
		var body: WorkshopPart = game.loose[uid]
		var location: String = game.model.items[uid].location
		_restore_body(body,w.items[uid],location)
		if location == "held":
			game.loose.erase(uid)
			game.components.held_body = body
			body.add_collision_exception_with(game.player)
			game.player.add_collision_exception_with(body)
	game.active_build = w.active_build
	game.player.global_transform = to_pose(w.player.pose)
	game.player.velocity = to_vector(w.player.velocity)
	game.crouched = w.player.crouched
	game.player_collision.shape.height = 1.0 if game.crouched else 1.7
	game.player_collision.position.y = 0.51 if game.crouched else 0.86
	game.camera.rotation = Vector3(w.player.pitch,0,0)
	game.camera.position.y = w.player.height
	game.camera.fov = w.player.fov
	game.jump_held = false
	game.scripted_controls.clear()
	game.hud.manual_id = w.reader.manual
	game.hud.pages.clear()
	for id in w.reader.pages:game.hud.pages[id] = int(w.reader.pages[id])
	game.hud.manual.visible = w.reader.visible
	game.hud.browser.set_suggested_only(w.reader.suggested_only)
	game.hud.body_scroll.scroll_vertical = 0
	game._state_changed()
	game.hud.browser.sync_selection()
	applying = false
	return true

func _mount_children(owner: String) -> void:
	for sid in game.model.assemblies[owner].slots:
		var child: String = game.model.assemblies[owner].slots[sid]
		if child.is_empty() or not game.model.slot_definition(owner,sid).has("assembly"):continue
		game.runtime.mount(owner,sid,child)
		_mount_children(child)

static func _restore_body(body: WorkshopPart, saved: Dictionary, location: String) -> void:
	body.held = location == "held"
	body.freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC if body.held else RigidBody3D.FREEZE_MODE_STATIC
	body.freeze = location != "loose"
	body.gravity_scale = 0.0 if body.held else 1.0
	body.global_transform = to_pose(saved.pose)
	body.linear_velocity = to_vector(saved.linear)
	body.angular_velocity = to_vector(saved.angular)
	body.sleeping = false
