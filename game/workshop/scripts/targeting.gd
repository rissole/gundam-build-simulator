extends RefCounted
## Aim scoring, sightlines, discovery, access, prompts and placement previews.
var game: Node

func _init(workshop: Node) -> void:
	game = workshop

func update_target() -> void:
	game.target = {}
	var best: float = INF
	var candidates: Array[Dictionary] = []
	var previous_build = game.active_build
	var held = game.held_build()
	var fitting_part = held.is_empty() and not game.components.selected_uid(game.selected_kind).is_empty()
	for id in game.builds:
		game._activate(id)
		if held.is_empty() and (fitting_part or game.state.pad_location == "foot") and not game.components.is_component_build(id) and ["prep","foot"].has(game.state.pad_location):
			for i in range(4):candidates.append({"type":"slot","build":id,"index":i,"point":game.connection(i),"radius":0.15})
		if game.state.pad_location in ["loose","prep"]:
			candidates.append({"type":"pad","build":id,"point":game.pad.global_position,"radius":0.40})
	if not held.is_empty():
		game._activate(held)
		for station in game.stations:
			candidates.append({"type":"prep","build":held,"station":station,"point":game.stations[station].global_position,"radius":0.48})
		for owner in game.model.assemblies:
			if owner == held or not game.interactable_assembly(owner):continue
			for sid in game.model.assemblies[owner].slots:
				var slot: Dictionary = game.model.slot_definition(owner,sid)
				if slot.get("assembly","") != game.model.assemblies[held].definition or not game.model.assemblies[owner].slots[sid].is_empty():continue
				if not game.model.assembly_access_error(owner,sid).is_empty():continue
				candidates.append({"type":"mount","owner":owner,"build":held,"mount":sid,"point":game.mount_point(sid,owner,held),"radius":0.30})

	game._activate(previous_build if held.is_empty() else held)
	for kind in game.bins:candidates.append({"type":"bin","kind":kind,"point":game.bins[kind].global_transform*Vector3(0,0.13,0.27),"radius":0.35})
	for uid in game.loose:
		if is_instance_valid(game.loose[uid]):candidates.append({"type":"loose","uid":uid,"point":game.loose[uid].global_position,"radius":0.12})
	if game.foot_equipment_available():candidates.append_array(game.foot_fixture.controls())
	if is_instance_valid(game.m2):
		candidates = candidates.filter(func(entry):return entry.type == "loose" or (entry.type == "bin" and game.model.count_at(entry.kind,"bin") > 0))
		candidates.append_array(game.m2.controls())
	for lift in game.access_lifts.values():candidates.append_array(lift.controls())
	if held.is_empty():
		var allowed_slots: Variant = game.leg_content.get("m2",{}).get("playable_slots")
		for candidate in game.components.candidates():
			# Fixed/mounted builds have no competing pickup action; retain their
			# connection inspection even when no pocket is selected.
			if allowed_slots != null and (not candidate.owner in allowed_slots or not candidate.sid in allowed_slots[candidate.owner]):continue
			if fitting_part or not game.builds.has(game.model.top_level(candidate.owner)):candidates.append(candidate)
	var scored: Array[Dictionary] = []
	var focused_connections: Dictionary = {}
	var discovery_hits: Dictionary = {}
	var precise_snap = false
	for candidate in candidates:
		if game.camera.global_position.distance_to(candidate.point) > game.SNAP_DISCOVERY_RANGE: continue
		var score = aim_score(candidate.point,candidate.radius)
		if score == INF:
			if not snap_candidate_valid(candidate):continue
			var owner: String = game.model.top_level(candidate.get("owner",candidate.get("build","")))
			if not discovery_hits.has(owner):discovery_hits[owner] = assembly_discovery_hit(owner)
			if discovery_hits[owner] == null:continue
			candidate["discovery_only"] = true
			candidate["discovery_hit"] = discovery_hits[owner]
			# Precise compatible aim wins; otherwise reveal the closest compatible
			# connection on the workpiece intersected by the view ray.
			var offset: Vector3 = candidate.point-game.camera.global_position
			var perpendicular = (offset+game.camera.global_basis.z*offset.dot(-game.camera.global_basis.z)).length()
			score = 0.75+minf(perpendicular,10.0)*0.01
		var connection_visible = true
		# While holding hardware, a nearby socket wins over the pad's center.
		if candidate.type == "slot":
			score -= 0.12
			connection_visible = can_see(candidate.point,[game.bodies[candidate.build],game.foot])
		if candidate.type == "component":
			score -= 1.0 if candidate.get("compatible",false) else 0.12
			connection_visible = can_see(candidate.point,game.components.receiving_bodies(candidate.owner,candidate.sid),game.components.service_access(candidate.owner,candidate.sid))
			if not connection_visible:score += 1.0
		if connection_visible and candidate.type in ["slot","component"]:
			var owner: String = candidate.get("owner",candidate.get("build",""))
			focused_connections[game.model.top_level(owner)] = true
		if connection_visible and not candidate.get("discovery_only",false) and snap_candidate_valid(candidate):precise_snap = true
		scored.append({"candidate":candidate,"score":score})
	for entry in scored:
		var candidate: Dictionary = entry.candidate
		if precise_snap and candidate.get("discovery_only",false):continue
		# Connection feedback and whole-assembly pickup describe the same object.
		# With a part selected, a nearby connection owns that object's focus instead
		# of trading places with its center as the geometric scores fluctuate.
		if candidate.type == "pad" and focused_connections.has(candidate.build):continue
		var score: float = entry.score
		if score < best:
			best = score
			game.target = candidate
	if game.target.has("build"):game._activate(game.target.build)
	# Share one current access result between prompt and preview. Actual clicks
	# always recheck access, and incompatible parts never run a placement sweep.
	var access_error = access(target_receivers(),game.target.type == "prep" or snap_candidate_valid(game.target)) if not game.target.is_empty() else ""
	present_target(access_error)
	update_ghost(access_error)

func aim_score(point: Vector3, radius: float) -> float:
	var offset = point-game.camera.global_position
	var ahead = offset.dot(-game.camera.global_basis.z)
	if ahead < 0.05: return INF
	var perpendicular = (offset+game.camera.global_basis.z*ahead).length()
	if perpendicular > radius: return INF
	return perpendicular/radius + ahead*0.008

func can_see(point: Vector3, allowed: Array = [], allow_body_hit: bool = false) -> bool:
	var query = PhysicsRayQueryParameters3D.create(game.camera.global_position,point,game.WORLD_MASK)
	var excluded: Array[RID] = [game.player.get_rid()]
	for body in game.bodies.values():
		if body.held:excluded.append(body.get_rid())
	if is_instance_valid(game.components.held_body):excluded.append(game.components.held_body.get_rid())
	if allow_body_hit:
		for receiver in allowed:
			if not is_instance_valid(receiver):continue
			if receiver is CollisionObject3D:excluded.append(receiver.get_rid())
			for body in game.bodies.values():
				if receiver.is_ancestor_of(body):excluded.append(body.get_rid())
	query.exclude = excluded
	var hit = game.get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty(): return true
	if allowed.has(hit.collider):
		if allow_body_hit:return true
		# A surface at the destination is expected; hitting the back/side far
		# before the target is an occlusion, even on the same assembly.
		return hit.position.distance_to(point) < 0.065
	return hit.position.distance_to(point) < 0.025

func assembly_discovery_hit(owner: String) -> Variant:
	var body: CollisionObject3D = game.assembly_node(owner)
	var inverse = body.global_transform.affine_inverse()
	var hit: Variant = SolidHandling.bounds(body).intersects_ray(inverse*game.camera.global_position,inverse.basis*(-game.camera.global_basis.z))
	if hit == null:return null
	var point: Vector3 = body.global_transform*hit
	if game.camera.global_position.distance_to(point) > game.SNAP_DISCOVERY_RANGE:return null
	# The cheap box belongs to the workpiece, not its stand or scaffold. Test
	# scenery along the view ray as well as the eventual connection's sightline.
	return point if can_see(point,[body],true) else null

func snap_candidate_valid(candidate: Dictionary) -> bool:
	var owner: String = candidate.get("owner",candidate.get("build",""))
	if not game.equipment_access_error(owner).is_empty():return false
	match candidate.get("type",""):
		"component":
			var uid: String = game.components.selected_uid(game.selected_kind)
			return not uid.is_empty() and game.model.placement_error(owner,candidate.sid,uid).is_empty()
		"mount":
			return game.model.assemblies[candidate.build].location == "held" and game.model.placement_error(owner,candidate.mount,candidate.build).is_empty()
		"slot":
			var view = game.builds[candidate.build]
			return HeelAssemblyState.KINDS.has(game.selected_kind) and view.count_at(game.selected_kind,"pocket") > 0 and view.reason(game.selected_kind,candidate.index).is_empty()
	return false

func target_receivers() -> Array:
	match game.target.get("type",""):
		"equipment":return game.target.get("allowed",[])
		"bin":return [game.bins[game.target.kind]]
		"pad":return [game.pad]
		"loose":return [game.loose[game.target.uid]]
		"component":return game.components.receiving_bodies(game.target.owner,game.target.sid)
		"mount":return [game.pad,game.assembly_node(game.model.top_level(game.target.owner))]
	return [game.pad,game.foot]

func target_object() -> Node3D:
	match game.target.get("type",""):
		"equipment":return game.target.get("node",null)
		"bin":
			var bin: Node3D = game.bins[game.target.kind]
			return bin.get_node("ShelfPart") if bin.has_node("ShelfPart") else bin
		"loose":return game.loose[game.target.uid]
		"pad", "slot":return game.bodies[game.target.build]
		"component", "mount":return game.assembly_node(game.target.owner)
	return null

func present_target(access_error: String) -> void:
	if game.target.is_empty() or game.paused:
		game.hud.present_target("")
		if is_instance_valid(game.interaction_outline):game.interaction_outline.clear()
		return
	var receivers = target_receivers()
	# A prompt should not disclose a connection through unrelated scenery. Keep
	# the target itself so attempting the action can still explain an obstruction.
	if game.camera.is_position_behind(game.target.point) or not can_see(game.target.point,receivers,target_allows_body_hit()):
		game.hud.present_target("")
		if is_instance_valid(game.interaction_outline):game.interaction_outline.clear()
		return
	var caption = ""
	var detail = ""
	var action_key = ""
	var action_label = ""
	var usable = false
	var pickup_target = false
	match game.target.type:
		"equipment":
			caption = game.target.label
			detail = game.equipment_controller(game.target).action_error(game.target.action)
			usable = detail.is_empty()
			if usable:
				action_key = "Click" if game.target.get("input","") == "place" else "E"
				action_label = "Place" if game.target.get("input","") == "place" else ("Operate" if game.profile.get("trial","").is_empty() else "Use")
		"bin":
			pickup_target = true
			var count: int = game.model.count_at(game.target.kind,"bin")
			var pocket: bool = game.model.definitions.parts[game.target.kind].carry_class == "pocket"
			caption = game.components.title(game.target.kind)
			detail = "%d available" % count
			if count > 0 and (pocket or not game.model.hands_occupied()):
				action_key = "E"
				action_label = "Stock pocket" if pocket else "Carry"
				usable = true
			elif count > 0:detail = "Set down the carried component first"
		"pad":
			pickup_target = true
			caption = game.build_label(game.active_build)
			detail = "Prepared" if game.state.prepared() else "Unfinished"
			if not game.model.hands_occupied():
				action_key = "E"
				action_label = "Carry"
				usable = true
			else:detail = "Set down the carried component first"
		"loose":
			pickup_target = true
			caption = game.components.title(game.model.items[game.target.uid].kind)
			if not game.model.hands_occupied():
				action_key = "E"
				action_label = "Carry"
				usable = true
			else:detail = "Set down the carried component first"
		"prep":
			caption = "Preparation station"
			usable = true
		"mount":
			caption = game.model.slot_definition(game.target.owner,game.target.mount).get("label",game.target.mount)
			detail = game.model.placement_error(game.target.owner,game.target.mount,game.active_build)
			usable = detail.is_empty()
		"component":
			var spec = game.model.slot_definition(game.target.owner,game.target.sid)
			caption = game.components.title(spec.accepts)
			detail = game.model.placement_error(game.target.owner,game.target.sid,game.components.selected_uid(game.selected_kind))
			usable = detail.is_empty()
		"slot":
			caption = game.build_label(game.active_build)+" · mounting point %d" % (game.target.index+1)
			if game.state.complete():detail = "Complete"
			elif game.selected_kind.is_empty():
				if game.state.pad_location == "prep" and not game.model.hands_occupied():
					action_key = "E"
					action_label = "Carry assembly"
					usable = true
					pickup_target = true
				else:detail = "Select a stocked pocket"
			else:
				caption = game.components.title(game.selected_kind)
				detail = game.state.reason(game.selected_kind,game.target.index)
				usable = detail.is_empty()
	if not access_error.is_empty():
		detail = snap_guidance_message() if snap_guidance_available() else ("" if game.camera.global_position.distance_to(game.target.point) > game.REACH else access_error)
		usable = false
	if not usable:
		action_key = ""
		action_label = ""
	if is_instance_valid(game.interaction_outline):
		# Contours advertise collection, not every available keyboard action.
		if usable and pickup_target:game.interaction_outline.focus(target_object())
		else:game.interaction_outline.clear()
	# The green geometry is the successful attachment affordance. Only explain
	# failures here; collection still needs its small keyboard action prompt.
	if usable and action_key.is_empty():
		game.hud.present_target("")
		return
	if not detail.is_empty():caption += "\n"+detail
	game.hud.present_target(caption,action_key,action_label,game.camera.unproject_position(game.target.point),usable)

func target_allows_body_hit() -> bool:
	if game.target.get("type","") == "equipment":return game.target.get("allow_body_hit",false)
	if game.target.get("type","") == "component":return game.components.service_access(game.target.owner,game.target.sid)
	if game.target.get("type","") == "mount":return game.components.service_access(game.target.get("owner",game.default_parent_id()),game.target.mount)
	return game.target.get("type","") in ["pad","loose"]

func access(allowed: Array = [], check_approach: bool = true) -> String:
	if game.target.is_empty(): return "Aim near a part, bin, or mounting point."
	if game.target.get("discovery_only",false):return snap_guidance_message()
	if game.target.type in ["slot","mount","component"]:
		var equipment_error = game.equipment_access_error(game.target.get("owner",game.target.get("build","")))
		if not equipment_error.is_empty():return equipment_error
	if game.target.type == "component":return game.components.access(check_approach)
	if game.camera.global_position.distance_to(game.target.point) > game.REACH: return "Out of reach. Move closer to the connection (maximum %.2f m)." % game.REACH
	if not can_see(game.target.point,allowed,target_allows_body_hit()): return "Connection is obstructed. Approach its exposed side or use the work-position controls."
	if game.target.type == "equipment":return game.equipment_controller(game.target).action_error(game.target.action)
	if game.target.type == "prep":
		var station: Node3D = game.stations[game.target.get("station","prep")]
		var envelope: Vector3 = SolidHandling.bounds(game.pad).size
		var volume: Vector3 = station.get_meta("work_volume")
		if envelope.x > volume.x or envelope.y > volume.y or envelope.z > volume.z:return "This assembly needs a larger work volume."
		for id in game.builds:
			if id != game.active_build and game.model.assemblies[id].location == "station:"+game.target.get("station","prep"):return "This station is occupied. Move its assembly first."
	if game.target.type in ["prep","mount"] and game.state.pad_location == "held" and check_approach:
		return game._carry_placement_error(game.placement_destination(),game.pad,game.assembly_node(game.target.owner) if game.target.has("owner") else null)
	return ""

func carry_placement_error(destination: Transform3D, carried: WorkshopPart = null, receiving: PhysicsBody3D = null) -> String:
	if carried == null:carried = game.pad
	if carried.global_position.distance_to(game.camera.global_position) > game.REACH+0.75+maxf(0.0,SolidHandling.bounds(carried).size.length()-1.0)*0.7:
		return "The carried assembly is caught or too far away. Bring it alongside you first."
	var excluded: Array[RID] = [carried.get_rid()]
	for exception in carried.get_collision_exceptions():excluded.append(exception.get_rid())
	if receiving:
		if receiving.has_meta("assembly_id"):receiving = game.assembly_node(game.model.top_level(receiving.get_meta("assembly_id")))
		excluded.append(receiving.get_rid())
		# Both rigid children and large animatable fixtures belong to the receiver.
		# Unrelated workshop supports remain obstacles throughout the approach.
		if receiving.has_meta("assembly_id"):
			for member in game.runtime.descendants(receiving.get_meta("assembly_id"),false):
				var child_body: CollisionObject3D = game.assembly_node(member)
				excluded.append(child_body.get_rid())
	# Only actual receiving owners are excluded; other fixtures stay solid.
	return SolidHandling.sweep_error(carried,destination,excluded,game.WORLD_MASK)

func update_ghost(access_result: Variant = null) -> void:
	game.ghost.visible = false
	for child in game.ghost.get_children():child.visible = false
	if game.paused:return
	var distant = snap_guidance_available()
	game.ghost_material.albedo_color = game.SNAP_DISTANT_COLOR if distant else game.SNAP_READY_COLOR
	game.ghost_material.no_depth_test = game.target.get("type","") == "component"
	if game.target.get("type","") == "component":
		if not game.model.placement_error(game.target.owner,game.target.sid,game.components.selected_uid(game.selected_kind)).is_empty():return
		if not distant and not (game.components.access() if access_result == null else access_result).is_empty():return
		game.ghost.mesh = game.source[game.model.slot_definition(game.target.owner,game.target.sid).pose_source].mesh
		game.ghost.global_transform = game.components.slot_pose(game.target.owner,game.target.sid)
		game.ghost.visible = true
		return
	if game.target.is_empty():return
	var allowed: Array = [game.pad]
	if game.target.has("owner"):allowed.append(game.assembly_node(game.model.top_level(game.target.owner)))
	elif is_instance_valid(game.foot):allowed.append(game.foot)
	if not distant and not (access(allowed) if access_result == null else access_result).is_empty():return
	if game.target.type == "slot" and HeelAssemblyState.KINDS.has(game.selected_kind):
		if not game.state.reason(game.selected_kind,game.target.index).is_empty() or game.state.count_at(game.selected_kind,"pocket") == 0:return
		var uid: String = game.slot_sources[game.selected_kind][game.target.index]
		game.ghost.mesh = game.source[uid].mesh
		var pose: Transform3D = game.source["FA-302__001"].transform.affine_inverse()*game.source[uid].transform
		game.ghost.global_transform = game.pad.global_transform*pose
		game.ghost.visible = true
	elif game.target.type == "mount" and game.state.pad_location == "held" and game.model.placement_error(game.target.get("owner",game.default_parent_id()),game.target.mount,game.active_build).is_empty():
		game.ghost.mesh = game.source[game.source_uid(game.state.pad_id)].mesh
		game.ghost.global_transform = game.mount_transform()
		game.ghost.visible = true
		show_assembly_ghost()
	elif game.target.type == "prep" and game.state.pad_location == "held":
		game.ghost.mesh = game.source[game.source_uid(game.state.pad_id)].mesh
		game.ghost.global_transform = game.stations[game.target.get("station","prep")].global_transform
		game.ghost.visible = true
		show_assembly_ghost()

func snap_guidance_message() -> String:
	return "Move closer to attach" if game.camera.global_position.distance_to(game.target.point) > game.REACH else "Aim at the highlighted connection to attach"

func snap_guidance_available() -> bool:
	# Discovery is feedback only. Placement keeps its normal reach, carrying
	# sweep and access checks; no physics or recipe rule is relaxed here.
	if game.paused or game.target.is_empty():return false
	var distance = game.camera.global_position.distance_to(game.target.point)
	if (distance <= game.REACH and not game.target.get("discovery_only",false)) or distance > game.SNAP_DISCOVERY_RANGE:return false
	if game.camera.is_position_behind(game.target.point):return false
	if not can_see(game.target.point,target_receivers(),target_allows_body_hit()):return false
	if game.target.has("discovery_hit") and not can_see(game.target.discovery_hit,[game.assembly_node(game.model.top_level(game.target.get("owner",game.target.get("build",""))))],true):return false
	return snap_candidate_valid(game.target)

func show_assembly_ghost() -> void:
	game.ghost.mesh = null
	var pieces = game.runtime.visual_pieces(game.active_build)
	var key = game.active_build
	for member in game.runtime.descendants(game.active_build):key += ":"+member+":"+str(game.assembly_node(member).get_meta("visual_revision",0))
	if key != game.ghost_assembly_signature:
		for child in game.ghost.get_children():
			game.ghost.remove_child(child)
			child.queue_free()
		for piece in pieces:
			var visual: MeshInstance3D = piece.visual
			var preview = MeshInstance3D.new()
			preview.mesh = visual.mesh
			preview.transform = piece.transform
			preview.material_override = game.ghost_material
			preview.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			preview.set_meta("component_uid",visual.get_meta("component_uid",visual.get_meta("installed_uid","")))
			preview.set_meta("source_uid",visual.get_meta("source_uid",""))
			preview.set_meta("body_visual",visual)
			game.ghost.add_child(preview)
		game.ghost_assembly_signature = key
	for child in game.ghost.get_children():
		var visual = child.get_meta("body_visual")
		child.visible = is_instance_valid(visual) and visual.visible

func update_markers() -> void:
	var previous_build = game.active_build
	var marker_index = 0
	for id in game.builds:
		if game.components.is_component_build(id):continue
		game._activate(id)
		for i in range(4):
			var point = game.connection(i)
			var marker = game.socket_markers[marker_index]
			marker_index += 1
			marker.visible = ["prep","foot"].has(game.state.pad_location) and game.camera.global_position.distance_to(point)<3.5 and can_see(point,[game.pad,game.foot]) and game.state.slots.bolt[i] == ""
			marker.global_position = point
	game._activate(previous_build)

