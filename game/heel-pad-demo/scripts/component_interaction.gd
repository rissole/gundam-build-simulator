extends Node
## Desktop projection for arbitrary authored component slots and carrying profiles.
var game: Node
var held_body: WorkshopPart
var service_material: StandardMaterial3D

func _init(workshop: Node) -> void:
	game = workshop

func is_component_build(id: String) -> bool:
	return game.model.definitions.assemblies[game.model.assemblies[id].definition].get("interaction","") == "components"

func definition(id: String) -> Dictionary:
	return game.model.definitions.assemblies[game.model.assemblies[id].definition]

func frame_source(owner: String) -> String:
	return game.runtime.frame_source(owner)

func title(kind: String) -> String:
	return game.model.definitions.parts[kind].title if game.model.definitions.parts.has(kind) else "Empty pocket"

func setup() -> void:
	pass

func slot_pose(owner: String, sid: String) -> Transform3D:
	return game.slot_pose(owner,sid)

func slot_point(owner: String, sid: String) -> Vector3:
	var d = game.model.slot_definition(owner,sid)
	# Authored targets are accessible connection points in the owner's local frame.
	if d.has("target") or d.has("target_position"):
		var point: Array = d.get("target",d.get("target_position",[]))
		return game.assembly_node(owner).global_transform*Vector3(point[0],point[1],point[2])
	if d.has("target_offset"):
		var offset: Array = d.target_offset
		return slot_pose(owner,sid)*Vector3(offset[0],offset[1],offset[2])
	return slot_pose(owner,sid)*game.source[game.source_uid(d.pose_source)].mesh.get_aabb().get_center()

func selected_uid(kind: String) -> String:
	var held: String = game.model.held_item()
	if not held.is_empty():return held
	return game.model.find_item(kind,"pocket")

func candidates() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var selected: String = game.selected_kind
	var held: String = game.model.held_item()
	if not held.is_empty():selected = game.model.items[held].kind
	for owner in game.model.assemblies:
		if not game.interactable_assembly(owner):continue
		var a: Dictionary = game.model.assemblies[owner]
		for sid in a.slots:
			var d: Dictionary = game.model.slot_definition(owner,sid)
			if d.has("assembly") or not a.slots[sid].is_empty():continue
			if not is_component_build(owner) and d.get("presentation","") != "components":continue
			if not game.model.assembly_access_error(owner,sid).is_empty():continue
			if not d.get("requires",[]).all(func(r):return not a.slots[r].is_empty()):continue
			var point: Vector3 = slot_point(owner,sid)
			if game.camera.global_position.distance_to(point) > 6.0:continue
			# Preserve feedback for a wrong variant; selection only affects ranking.
			result.append({"type":"component","owner":owner,"sid":sid,"point":point,"radius":0.24,"compatible":d.accepts == selected})
	return result

func service_access(owner: String, sid: String = "") -> bool:
	var a: Dictionary = game.model.assemblies[owner]
	var d: Dictionary = definition(owner)
	var policy: String = game.model.slot_definition(owner,sid).get("service_access",d.get("service_access","surface"))
	if policy == "assisted":return true
	# The open preparation fixture exposes internal connections. This explicit
	# recipe policy belongs to the workpiece and never depends on the reader.
	var root: String = game.model.top_level(owner)
	return policy == "open_station" and game.model.assemblies[root].location.begins_with("station:") and game.model.assembly_access_error(owner,sid).is_empty() and not game.model.milestone(owner,"enclosed")

func receiving_bodies(owner: String, sid: String = "") -> Array:
	var body: Node3D = game.assembly_node(owner)
	var allowed: Array = [body]
	# A mounted child shares its root's compound collision. Expose that receiver
	# only under the same explicit service/access policy that exposes the child.
	if service_access(owner,sid):
		var root: Node3D = game.assembly_node(game.model.top_level(owner))
		if root != body:allowed.append(root)
	for child in game.bodies.values():
		if body.is_ancestor_of(child):allowed.append(child)
	return allowed

func access() -> String:
	if game.camera.global_position.distance_to(game.target.point) > game.REACH:return "Move closer to this component."
	var owner: String = game.target.owner
	var policy_error: String = game.model.assembly_access_error(owner,game.target.sid)
	if not policy_error.is_empty():return policy_error
	var body: Node3D = game.assembly_node(owner)
	if not game._visible(game.target.point,receiving_bodies(owner,game.target.sid),service_access(owner,game.target.sid)):return "View obstructed. Approach the station's open side."
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
	game.apply_carry_intent(held_body,delta)

func sync(owner: String) -> void:
	var node: Node3D = game.assembly_node(owner)
	var a: Dictionary = game.model.assemblies[owner]
	var d = definition(owner)
	var existing: Dictionary = {}
	var changed = false
	for child in node.get_children():
		if child.has_meta("component_uid"):
			var uid: String = child.get_meta("component_uid")
			if not a.slots.values().has(uid):node.remove_child(child);child.queue_free();changed = true
			else:existing[uid] = child
	for sid in a.slots:
		var uid: String = a.slots[sid]
		if uid.is_empty() or d.slots[sid].has("assembly") or sid == d.get("root_slot",""):continue
		if not is_component_build(owner) and d.slots[sid].get("presentation","") != "components":continue
		if existing.has(uid):continue
		# A type may have source instances with different baked mesh orientations.
		# Match the slot/preview geometry; component_uid retains the consumed piece.
		var mesh = game._mesh(d.slots[sid].pose_source)
		node.add_child(mesh)
		mesh.global_transform = slot_pose(owner,sid)
		mesh.set_meta("component_uid",uid)
		mesh.set_meta("slot_id",sid)
		changed = true
	if changed:
		node.set_meta("visual_revision",int(node.get_meta("visual_revision",0))+1)
		game.refresh_assembly_collision(owner)
	update_service_view()

func update_service_view() -> void:
	for id in game.model.assemblies:
		if not is_component_build(id):continue
		var body: Node3D = game.assembly_node(id)
		var d = definition(id)
		var closed: bool = game.model.milestone(id,"enclosed")
		var inspecting: bool = service_access(id)
		for mesh in body.get_children():
			if not mesh is MeshInstance3D or not mesh.has_meta("slot_id"):continue
			var slot: Dictionary = d.slots[mesh.get_meta("slot_id")]
			mesh.visible = not (closed and slot.get("enclosed",false))
			if slot.pose_source != d.get("enclosure_source",""):continue
			if inspecting:
				if service_material == null:
					service_material = game.material(Color(0.40,0.60,0.68,0.16))
					service_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
					service_material.cull_mode = BaseMaterial3D.CULL_DISABLED
				mesh.material_override = service_material
			else:mesh.material_override = null
