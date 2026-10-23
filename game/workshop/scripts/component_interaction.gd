extends Node
## Desktop projection for arbitrary authored component slots and carrying profiles.
var game: Node
var held_body: WorkshopPart
var presentation: Dictionary = {}
var markers: Array[Dictionary] = []

func _init(workshop: Node) -> void:
	game = workshop

func definition(id: String) -> Dictionary:
	return game.model.definitions.assemblies[game.model.assemblies[id].definition]

func frame_source(owner: String) -> String:
	return game.runtime.frame_source(owner)

func title(kind: String) -> String:
	return game.model.definitions.parts[kind].title if game.model.definitions.parts.has(kind) else "Empty pocket"

func setup() -> void:
	presentation = preload("res://scripts/workshop_content.gd").presentation(game.model.definitions)

func slot_pose(owner: String, sid: String) -> Transform3D:
	return game.slot_pose(owner,sid)

func slot_presentation(owner: String, sid: String) -> Dictionary:
	return presentation.get(game.model.assemblies[owner].definition,{}).get("slots",{}).get(sid,{})

func slot_point(owner: String, sid: String) -> Vector3:
	var d = game.model.slot_definition(owner,sid).duplicate()
	d.merge(slot_presentation(owner,sid),true)
	if d.has("target_child"):
		var child: String = game.model.assemblies[owner].slots[d.target_child]
		return slot_point(child,d.target_slot)
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
			if d.has("assembly") or sid == definition(owner).get("root_slot","") or not a.slots[sid].is_empty():continue
			if not game.model.assembly_access_error(owner,sid).is_empty():continue
			if not d.get("requires",[]).all(func(r):return not a.slots[r].is_empty()):continue
			var point: Vector3 = slot_point(owner,sid)
			if game.camera.global_position.distance_to(point) > game.SNAP_DISCOVERY_RANGE:continue
			# Preserve feedback for a wrong variant; selection only affects ranking.
			result.append({"type":"component","owner":owner,"sid":sid,"point":point,"radius":slot_presentation(owner,sid).get("target_radius",0.24),"compatible":d.accepts == selected})
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

func access(check_approach: bool = true) -> String:
	if game.target.get("discovery_only",false):return game._snap_guidance_message()
	var equipment_error: String = game.equipment_access_error(game.target.owner)
	if not equipment_error.is_empty():return equipment_error
	if game.camera.global_position.distance_to(game.target.point) > game.REACH:return "Out of reach. Move closer to this component."
	var owner: String = game.target.owner
	var policy_error: String = game.model.assembly_access_error(owner,game.target.sid)
	if not policy_error.is_empty():return policy_error
	var body: Node3D = game.assembly_node(owner)
	if not game._visible(game.target.point,receiving_bodies(owner,game.target.sid),service_access(owner,game.target.sid)):return "View obstructed. Approach the station's open side."
	if check_approach and is_instance_valid(held_body):return game._carry_placement_error(slot_pose(game.target.owner,game.target.sid),held_body,body)
	return ""

## A legacy child recipe may expose hardware owned by its receiving assembly.
## Keep that guidance with presentation, while model ownership/rules stay generic.
func placement_error(owner: String, sid: String, uid: String) -> String:
	var a: Dictionary = game.model.assemblies[owner]
	if a.parent.is_empty() and game.model.items.has(uid) and game.model.items[uid].kind in presentation.get(a.definition,{}).get("parent_hardware",[]):
		return "Mount the prepared assembly on its receiving carrier first."
	return game.model.placement_error(owner,sid,uid)

func attach() -> void:
	var t: Dictionary = game.target
	var error = access()
	if not error.is_empty():game.hud.toast(error);return
	var item = selected_uid(game.selected_kind)
	error = placement_error(t.owner,t.sid,item)
	if not error.is_empty():game.hud.toast(error);return
	var prepared_before: Dictionary = game.prepared_flags.duplicate()
	var complete_before: Dictionary = game.completed_flags.duplicate()
	var result: Dictionary = game.model.install(t.owner,t.sid,item)
	if not result.ok:game.hud.toast(result.error);return
	if is_instance_valid(held_body):held_body.queue_free();held_body = null
	sync(t.owner)
	# Keep a newly announced milestone visible for legacy connection recipes.
	var milestone_changed: bool = prepared_before != game.prepared_flags or complete_before != game.completed_flags
	if not slot_presentation(t.owner,t.sid).get("milestone_feedback",false) or not milestone_changed:
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

## Puts an already model-held identity into the hands, starting from `at`.
func hold_at(uid: String, at: Transform3D) -> void:
	game._spawn_loose(uid)
	var body: WorkshopPart = game.loose[uid];game.loose.erase(uid)
	body.global_transform = at;body.held = true;body.freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC;body.freeze = true
	body.linear_velocity = Vector3.ZERO;body.angular_velocity = Vector3.ZERO
	body.add_collision_exception_with(game.player);game.player.add_collision_exception_with(body)
	held_body = body

## Removing a fitted component into the hands needs the same reach and a clear
## sightline; the fitted component itself may stand in front of the connection.
func removal_access(owner: String, sid: String) -> String:
	var point: Vector3 = slot_point(owner,sid)
	if game.camera.global_position.distance_to(point) > game.REACH:return "Out of reach. Move closer to this component."
	if not game._visible(point,receiving_bodies(owner,sid),true):return "View obstructed. Approach the station's open side."
	return ""

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
		var body: Node3D = game.assembly_node(id)
		var d = definition(id)
		var closed: bool = game.model.milestone(id,"enclosed")
		# Assisted connection access does not change the fitted shell's appearance.
		# Open ends and exterior lands remain usable while the housing is opaque.
		for mesh in body.get_children():
			if not mesh is MeshInstance3D or not mesh.has_meta("slot_id"):continue
			var slot: Dictionary = d.slots[mesh.get_meta("slot_id")]
			mesh.visible = not (closed and slot.get("enclosed",false))


func make_build(owner: String) -> void:
	var d: Dictionary = definition(owner)
	var uid: String = game.model.assemblies[owner].slots[d.root_slot]
	var body = WorkshopPart.new()
	body.uid = uid;body.kind = game.model.items[uid].kind;body.name = owner.to_pascal_case()
	body.collision_layer = 2;body.collision_mask = game.WORLD_MASK
	game.add_child(body)
	body.mass = 2.0
	game.bodies[owner] = body
	game.runtime.register_node(owner,body)
	var visual: MeshInstance3D = game._mesh(uid)
	body.add_child(visual)
	visual.transform = game.runtime.local_slot_pose(owner,d.root_slot)
	visual.set_meta("component_uid",uid);visual.set_meta("slot_id",d.root_slot)
	body.add_collision_exception_with(game.player);game.player.add_collision_exception_with(body)
	body.position = game.home_position(owner)
	game.refresh_assembly_collision(owner)

func make_markers() -> void:
	for owner in game.builds:
		for descriptor in presentation.get(game.model.assemblies[owner].definition,{}).get("markers",[]):
			var marker = MeshInstance3D.new()
			var sphere = SphereMesh.new();sphere.radius = .009;sphere.height = .018
			marker.mesh = sphere;marker.material_override = game.material(Color("79d8b8"),0,true)
			marker.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			game.add_child(marker);marker.visible = false
			markers.append({"owner":owner,"spec":descriptor,"node":marker})

func update_markers() -> void:
	for record in markers:
		var owner: String = record.owner
		var a: Dictionary = game.model.assemblies[owner]
		var complete = false
		if not a.parent.is_empty():complete = not game.model.assemblies[a.parent].slots.get(a.parent_slot+"/"+record.spec.parent_completion,"").is_empty()
		var point: Vector3 = slot_point(owner,record.spec.slot)
		record.node.visible = game.interactable_assembly(owner) and not complete and game.camera.global_position.distance_to(point)<3.5 and game.targeting.can_see(point,[game.assembly_node(owner),game.foot])
		record.node.global_position = point

func interact(all_stock: bool = false) -> void:
	var target: Dictionary = game.target
	if target.is_empty():game.hud.toast("Aim at a drawer, shelf or loose component.");return
	if target.type == "equipment":
		if target.get("input","") == "place":game.hud.toast("Aim and click to seat this supported component.");return
		var error: String = game.targeting.access(game.targeting.target_receivers())
		if error.is_empty():error = target.controller.request(target.action)
		game.hud.toast(error if not error.is_empty() else target.controller.status_text(),error.is_empty());return
	if target.type == "component":
		var owner: String = game.model.top_level(target.owner)
		if not game.builds.has(owner):game.hud.toast("This fixture stays at its work station.");return
		var previous_target: Dictionary = target
		game.target = {"type":"assembly","build":owner,"point":target.get("discovery_hit",target.point)}
		interact(all_stock)
		game.target = previous_target
		return
	var error: String = game.targeting.access(game.targeting.target_receivers())
	if not error.is_empty():game.hud.toast(error);return
	if game.hands.payload_holder() != null:game.hud.toast(game.hands.error());return
	match target.type:
		"bin":collect(target.kind,all_stock)
		"assembly":
			var owner: String = target.build
			var assembly: Dictionary = game.model.assemblies[owner]
			if not assembly.parent.is_empty():game.hud.toast("The assembly is mounted. Undo its installation in the parent manual.");return
			if assembly.location == "held":return
			var carry_error: String = game.model.move_assembly(owner,"held")
			if not carry_error.is_empty():game.hud.toast(carry_error);return
			var body: WorkshopPart = game.bodies[owner]
			body.reparent(game)
			body.freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC;body.freeze = true
			body.linear_velocity = Vector3.ZERO;body.angular_velocity = Vector3.ZERO
			body.held = true;body.gravity_scale = 0
			body.collision_layer = 2;body.collision_mask = game.WORLD_MASK
		"loose":collect(game.model.items[target.uid].kind,false,target.uid)
	game.hud.refresh()

func attach_target() -> void:
	var target: Dictionary = game.target
	if target.get("type","") == "equipment" and target.controller.click_operates:
		if target.get("input","") == "pickup":game.hud.toast("Use E to pick up this equipment payload.");return
		var error: String = game.targeting.access(game.targeting.target_receivers())
		if error.is_empty():error = target.controller.request(target.action)
		game.hud.toast(error if not error.is_empty() else target.controller.status_text(),error.is_empty());return
	if target.get("type","") == "component":attach();return
	var error: String = game.targeting.access(game.targeting.target_receivers())
	if not error.is_empty():game.hud.toast(error);return
	var owner: String = target.get("build",game.held_build())
	if not owner.is_empty() and game.model.assemblies[owner].location == "held":
		if target.type == "prep":
			var station: String = target.get("station","prep")
			error = game.model.move_assembly(owner,"station:"+station)
			if not error.is_empty():game.hud.toast(error);return
			game.suspend_build(owner,station);game.hud.toast("Assembly suspended.",true)
		elif target.type == "mount":
			var result: Dictionary = game.model.install(target.owner,target.mount,owner)
			if not result.ok:game.hud.toast(result.error);return
			game.mount_build(owner)
			if game.profile.get("pads","") == "single":game.hud.open_manual(game.model.assemblies[owner].parent,1)
			game.hud.toast("Assembly seated. Follow the receiving manual to secure its connections.",true)
		else:game.hud.toast("Select a compatible part and aim at a ready connection.")
	else:game.hud.toast("Select a compatible part and aim at a ready connection.")
	game.hud.refresh()
