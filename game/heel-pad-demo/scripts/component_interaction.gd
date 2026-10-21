extends Node
## Desktop projection for arbitrary authored component slots and carrying profiles.
var game: Node
var held_body: WorkshopPart
var parent_visuals: Node3D

func _init(workshop: Node) -> void:
	game = workshop

func is_component_build(id: String) -> bool:
	return game.model.definitions.assemblies[game.model.assemblies[id].definition].get("interaction","") == "components"

func definition(id: String) -> Dictionary:
	return game.model.definitions.assemblies[game.model.assemblies[id].definition]

func title(kind: String) -> String:
	return game.model.definitions.parts[kind].title if game.model.definitions.parts.has(kind) else "Empty pocket"

func setup() -> void:
	parent_visuals = Node3D.new()
	game.foot.add_child(parent_visuals)

func slot_pose(owner: String, sid: String) -> Transform3D:
	var source_pose: Transform3D = game.source[game.model.slot_definition(owner,sid).pose_source].transform
	if owner == "foot":return game.foot.global_transform*Transform3D(Basis.IDENTITY,-game.FOOT_CENTER)*source_pose
	var root: String = definition(owner).slots[definition(owner).root_slot].pose_source
	return game.bodies[owner].global_transform*game.source[root].transform.affine_inverse()*source_pose

func slot_point(owner: String, sid: String) -> Vector3:
	var d = game.model.slot_definition(owner,sid)
	return slot_pose(owner,sid)*game.source[d.pose_source].mesh.get_aabb().get_center()

func selected_uid(kind: String) -> String:
	var held: String = game.model.held_item()
	if not held.is_empty():return held
	return game.model.find_item(kind,"pocket")

func candidates() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if not game.hud:return result
	var owner: String = game.hud.manual_id
	if owner != "foot" and not is_component_build(owner):return result
	var a: Dictionary = game.model.assemblies[owner]
	if owner != "foot" and not a.location.begins_with("station:"):return result
	var step: Dictionary = definition(owner).manual[game.hud.page]
	if step.get("view","") != "components":return result
	var selected: String = game.selected_kind
	var held: String = game.model.held_item()
	if not held.is_empty():selected = game.model.items[held].kind
	for sid in step.slots:
		var d = game.model.slot_definition(owner,sid)
		if d.has("assembly") or not a.slots[sid].is_empty():continue
		# Prefer the selected family when several internal fasteners share an axis.
		if d.accepts != selected:continue
		if not d.get("requires",[]).all(func(r):return not a.slots[r].is_empty()):continue
		result.append({"type":"component","owner":owner,"sid":sid,"point":slot_point(owner,sid),"radius":0.24})
	return result

func access() -> String:
	if game.camera.global_position.distance_to(game.target.point) > game.REACH:return "Move closer to this component."
	var body: Node3D = game.foot if game.target.owner == "foot" else game.bodies[game.target.owner]
	# A service view exposes internals through the enclosing build, while scenery
	# still blocks the first ray hit. Precision threading is handled by the fixture.
	var allowed: Array = [body]
	for child in game.bodies.values():
		if body.is_ancestor_of(child):allowed.append(child)
	if not game._visible(game.target.point,allowed,true):return "View obstructed. Approach the station's open side."
	if is_instance_valid(held_body):return game._carry_placement_error(slot_pose(game.target.owner,game.target.sid),held_body,body)
	return ""

func attach() -> void:
	var t: Dictionary = game.target
	var error = access()
	if not error.is_empty():game.hud.toast(error);return
	var item = selected_uid(game.selected_kind)
	var result: Dictionary = game.model.install(t.owner,t.sid,item)
	if not result.ok:game.hud.toast(result.error);return
	if is_instance_valid(held_body):held_body.queue_free();held_body = null
	sync(t.owner)
	game.hud.toast("Fitted "+title(game.model.items[item].kind),true)
	game.hud.refresh()

func collect(kind: String, all_stock: bool = false, uid: String = "") -> void:
	var location = "loose" if not uid.is_empty() else "bin"
	if game.model.definitions.parts[kind].carry_class == "pocket":
		var result: Dictionary = game.model.stock_pocket(kind)
		if not result.ok:game.hud.toast(result.error);return
		game.hud.toast("%s · pocket %d · ×%d"%[title(kind),(result.index+1)%10,game.model.pocket_size(result.index)],true)
	else:
		if uid.is_empty():uid = game.model.find_item(kind,"bin")
		var error: String = game.model.carry_item(uid)
		if not error.is_empty():game.hud.toast(error);return
		if game.loose.has(uid):
			held_body = game.loose[uid]
			game.loose.erase(uid)
		else:
			game._spawn_loose(uid,true)
			held_body = game.loose[uid]
			game.loose.erase(uid)
			held_body.global_position = game.bins[kind].global_position+Vector3(0,0.2,0.65)
		held_body.held = true
		held_body.freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
		held_body.freeze = true
		held_body.linear_velocity = Vector3.ZERO
		held_body.angular_velocity = Vector3.ZERO
		held_body.add_collision_exception_with(game.player)
		game.player.add_collision_exception_with(held_body)
		game.hud.toast("Carrying "+title(kind)+". Click its preview; Q sets it down.",true)
	game.hud.refresh()

func drop(to_bin: bool = false) -> void:
	var uid: String = game.model.release_item("bin" if to_bin else "loose")
	if uid.is_empty():return
	if to_bin:held_body.queue_free()
	else:
		held_body.held = false
		held_body.freeze = false
		held_body.gravity_scale = 1
		game.loose[uid] = held_body
	held_body = null
	game.hud.refresh()

func physics(delta: float) -> void:
	if not is_instance_valid(held_body) or game.paused:return
	held_body.carry_target = game.camera.global_position+game.camera.global_basis*Vector3(0.5,-0.32,-1.1)
	held_body.carry_basis = game.camera.global_basis
	held_body.update_grip(delta)

func sync(owner: String) -> void:
	var node: Node3D = parent_visuals if owner == "foot" else game.bodies[owner]
	var a: Dictionary = game.model.assemblies[owner]
	var d = definition(owner)
	var existing: Dictionary = {}
	for child in node.get_children():
		if child.has_meta("component_uid"):
			var uid: String = child.get_meta("component_uid")
			if not a.slots.values().has(uid):node.remove_child(child);child.queue_free()
			else:existing[uid] = child
	for sid in a.slots:
		var uid: String = a.slots[sid]
		if uid.is_empty() or d.slots[sid].has("assembly") or sid == d.get("root_slot",""):continue
		if owner == "foot" and d.slots[sid].get("presentation","") != "components":continue
		if existing.has(uid):continue
		# A type may have source instances with different baked mesh orientations.
		# Match the slot/preview geometry; component_uid retains the consumed piece.
		var mesh = game._mesh(d.slots[sid].pose_source)
		node.add_child(mesh)
		mesh.global_transform = slot_pose(owner,sid)
		mesh.set_meta("component_uid",uid)
	update_service_view()

func update_service_view() -> void:
	for id in game.builds:
		if not is_component_build(id):continue
		var body: Node3D = game.bodies[id]
		var inspecting: bool = game.hud and game.hud.manual_id == id and game.model.assemblies[id].location.begins_with("station:") and not game.builds[id].prepared()
		var root: MeshInstance3D = body.get_child(0)
		if inspecting and root.material_override == null:
			var mat = game.material(Color(0.40,0.60,0.68,0.16))
			mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			mat.cull_mode = BaseMaterial3D.CULL_DISABLED
			root.material_override = mat
		elif not inspecting:root.material_override = null
