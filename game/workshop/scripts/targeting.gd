extends RefCounted
## Aim scoring, sightlines, discovery, access, prompts and placement previews.
var game: Node
var pickup_surfaces = preload("res://scripts/pickup_surfaces.gd").new()
var pickup_bodies: Dictionary = {}

func _init(workshop: Node) -> void:
	game = workshop

## Snapshot only the button and callback, never the mutable aiming target.
func latch_control() -> Dictionary:
	var handler = preload("res://scripts/equipment_button.gd").hold_handler(game.target)
	if not handler.is_valid():return {}
	var error = access(target_receivers())
	if not error.is_empty():
		game.hud.toast(error)
		return {}
	return {"node":game.target.node,"handler":handler}

func update_target() -> void:
	game.target = {}
	pickup_bodies.clear()
	var best: float = INF
	var candidates: Array[Dictionary] = []
	var held = game.held_build()
	var fitting_part = held.is_empty() and not game.components.selected_uid(game.selected_kind).is_empty()
	for id in game.builds:
		var location: String = game.model.assemblies[id].location
		if location == "loose" or location.begins_with("station:"):
			candidates.append({"type":"assembly","build":id,"point":game.bodies[id].global_position,"radius":0.40})
	if not held.is_empty():
		for station in game.stations:
			candidates.append({"type":"prep","build":held,"station":station,"point":game.stations[station].global_position,"radius":0.48})
		for owner in game.model.assemblies:
			if owner == held or not game.interactable_assembly(owner):continue
			for sid in game.model.assemblies[owner].slots:
				var slot: Dictionary = game.model.slot_definition(owner,sid)
				if slot.get("assembly","") != game.model.assemblies[held].definition or not game.model.assemblies[owner].slots[sid].is_empty():continue
				candidates.append({"type":"mount","owner":owner,"build":held,"mount":sid,"point":game.mount_point(sid,owner,held),"radius":0.30})

	for kind in game.bins:
		var point: Vector3 = game.bins[kind].global_transform*Vector3(0,0.13,0.27)
		if game.camera.global_position.distance_squared_to(point) <= game.SNAP_DISCOVERY_RANGE*game.SNAP_DISCOVERY_RANGE:
			candidates.append({"type":"bin","kind":kind,"point":point,"radius":0.35})
	for uid in game.loose:
		if is_instance_valid(game.loose[uid]):candidates.append({"type":"loose","uid":uid,"pickup_body":game.loose[uid],"point":game.loose[uid].global_position,"radius":0.12})
	if game.journey != null:candidates = game.journey.filter_candidates(candidates)
	candidates.append_array(game.equipment.controls())
	if held.is_empty():
		for candidate in game.components.candidates():
			# Fixed/mounted builds have no competing pickup action; retain their
			# connection inspection even when no pocket is selected.
			if fitting_part or not game.builds.has(game.model.top_level(candidate.owner)):candidates.append(candidate)
	for candidate in candidates:
		if candidate.has("pickup_body"):pickup_bodies[candidate.pickup_body] = true
	var scored: Array[Dictionary] = []
	var focused_connections: Dictionary = {}
	var discovery_hits: Dictionary = {}
	var precise_snap = false
	for candidate in candidates:
		var score: float
		if candidate.has("pickup_body"):
			var surface = pickup_surfaces.aim_hit(candidate.pickup_body,game.camera,game.SNAP_DISCOVERY_RANGE)
			if surface.is_empty():continue
			candidate.point = surface.point
			score = surface.score
			if not can_see(candidate.point,[candidate.pickup_body]):continue
		else:
			if game.camera.global_position.distance_to(candidate.point) > game.SNAP_DISCOVERY_RANGE:continue
			score = aim_score(candidate.point,candidate.radius)
			if score == INF and candidate.type == "component":score = aim_score(candidate.point,candidate.radius+minf(0.02,candidate.radius*0.25))
		var connection = candidate.type in ["component","mount"]
		var connection_visible = true
		if candidate.type == "component" and score != INF:
			connection_visible = can_see(candidate.point,game.components.receiving_bodies(candidate.owner,candidate.sid),game.components.service_access(candidate.owner,candidate.sid),game.components.sight_depth(candidate.owner,candidate.sid))
		if score == INF or not connection_visible:
			if not connection:continue
			var owner: String = game.model.top_level(candidate.get("owner",candidate.get("build","")))
			if not discovery_hits.has(owner):discovery_hits[owner] = assembly_discovery_hit(owner)
			if discovery_hits[owner] == null:continue
			candidate["discovery_only"] = true
			candidate["discovery_hit"] = discovery_hits[owner]
			candidate["discovery_obstructed"] = not connection_visible
			# Inspection needs a visible workpiece, not placement permission.
			# Precise ready connections still win over broad workpiece context.
			var offset: Vector3 = candidate.point-game.camera.global_position
			var perpendicular = (offset+game.camera.global_basis.z*offset.dot(-game.camera.global_basis.z)).length()
			score = 0.75+minf(perpendicular,10.0)*0.01
		if candidate.type == "component":
			score -= 1.0 if candidate.get("compatible",false) else 0.12
			if not snap_candidate_valid(candidate):score += 0.2
			focused_connections[game.model.top_level(candidate.owner)] = true
		if connection_visible and not candidate.get("discovery_only",false) and snap_candidate_valid(candidate):precise_snap = true
		scored.append({"candidate":candidate,"score":score})
	for entry in scored:
		var candidate: Dictionary = entry.candidate
		if precise_snap and candidate.get("discovery_only",false):continue
		# Connection feedback and whole-assembly pickup describe the same object.
		# With a part selected, a nearby connection owns that object's focus instead
		# of trading places with its center as the geometric scores fluctuate.
		if candidate.type == "assembly" and focused_connections.has(candidate.build):continue
		var score: float = entry.score
		if score < best:
			best = score
			game.target = candidate
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

func can_see(point: Vector3, allowed: Array = [], allow_body_hit: bool = false, depth: float = 0.065) -> bool:
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
	var hit = {}
	# A coarse pickup collider may cover a real opening. Refine only known
	# collectible bodies against their visible mesh, keeping scenery solid.
	for attempt in range(16):
		hit = game.get_world_3d().direct_space_state.intersect_ray(query)
		if hit.is_empty() or not pickup_bodies.has(hit.collider):break
		var surface = pickup_surfaces.ray_hit(hit.collider,game.camera.global_position,(point-game.camera.global_position).normalized(),game.camera.global_position.distance_to(point)+0.002)
		if not surface.is_empty():
			hit.position = surface.point
			break
		excluded.append(hit.collider.get_rid())
		query.exclude = excluded
		if attempt == 15:return false
	if hit.is_empty(): return true
	if allowed.has(hit.collider) and not allow_body_hit and hit.position.distance_to(point) >= depth and hit.position.distance_to(point) <= depth+0.025:
		# A small proxy mismatch is forgiven only when actual receiver material
		# leaves the connection exposed. Deep/back-side body hits stay blocked.
		var surface = pickup_surfaces.ray_hit(hit.collider,game.camera.global_position,(point-game.camera.global_position).normalized(),game.camera.global_position.distance_to(point))
		if surface.is_empty() or surface.point.distance_to(point) < depth:
			excluded.append(hit.collider.get_rid())
			query.exclude = excluded
			return game.get_world_3d().direct_space_state.intersect_ray(query).is_empty()
	if allowed.has(hit.collider):
		if allow_body_hit:return true
		# A surface at the destination is expected; hitting the back/side far
		# before the target is an occlusion, even on the same assembly.
		# `depth` is the near-surface allowance. Hollow seats whose collision
		# is a solid proxy name a larger one; it is not a view through the part.
		return hit.position.distance_to(point) < depth
	return hit.position.distance_to(point) < 0.025

func assembly_discovery_hit(owner: String) -> Variant:
	var body: Node3D = game.assembly_node(owner)
	var hit = pickup_surfaces.ray_hit(body,game.camera.global_position,-game.camera.global_basis.z,game.SNAP_DISCOVERY_RANGE)
	if hit.is_empty():return null
	# Refine the visible workpiece, including hollow gaps, before ignoring its
	# receiver collider. Unrelated stands, equipment and scenery remain solid.
	return hit.point if can_see(hit.point,[body],true) else null

func snap_candidate_valid(candidate: Dictionary) -> bool:
	# Stock, pickups and controls cannot become attachment previews. Avoid
	# querying every equipment interlock for these non-connection candidates.
	if candidate.get("type","") not in ["component","mount"]:return false
	var owner: String = candidate.get("owner",candidate.get("build",""))
	if not game.equipment_access_error(owner).is_empty():return false
	match candidate.get("type",""):
		"component":
			var uid: String = game.components.selected_uid(game.selected_kind)
			return not uid.is_empty() and game.components.placement_error(owner,candidate.sid,uid).is_empty()
		"mount":
			return game.model.assemblies[candidate.build].location == "held" and game.model.placement_error(owner,candidate.mount,candidate.build).is_empty()
	return false

func target_receivers() -> Array:
	match game.target.get("type",""):
		"equipment":return game.target.get("allowed",[])
		"bin":return [game.bins[game.target.kind]]
		"assembly":return [game.bodies[game.target.build]]
		"loose":return [game.loose[game.target.uid]]
		"component":return game.components.receiving_bodies(game.target.owner,game.target.sid)
		"mount":return [game.bodies[game.target.build],game.assembly_node(game.model.top_level(game.target.owner))]
	return [game.bodies[game.target.build],game.foot] if game.target.has("build") else [game.foot]

func target_object() -> Node3D:
	match game.target.get("type",""):
		"equipment":return game.target.get("node",null)
		"bin":
			var bin: Node3D = game.bins[game.target.kind]
			return bin.get_node("ShelfPart") if bin.has_node("ShelfPart") else bin
		"loose":return game.loose[game.target.uid]
		"assembly":return game.bodies[game.target.build]
		"component", "mount":return game.assembly_node(game.target.owner)
	return null

func _present_outline(pickup: Node3D = null) -> void:
	if not is_instance_valid(game.interaction_outline):return
	var obstacle: Node3D = game.equipment.obstruction_target() if not game.paused else null
	if pickup != null and not game.paused:game.interaction_outline.focus(pickup)
	elif obstacle != null:game.interaction_outline.focus(obstacle)
	else:game.interaction_outline.clear()

func present_target(access_error: String) -> void:
	if game.target.is_empty() or game.paused:
		game.hud.present_target("")
		_present_outline()
		return
	var receivers = target_receivers()
	var presentation_point: Vector3 = game.target.get("discovery_hit",game.target.point)
	# A prompt should not disclose a connection through unrelated scenery. Keep
	# the target itself so attempting the action can still explain an obstruction.
	if game.camera.is_position_behind(presentation_point) or not can_see(presentation_point,receivers,true if game.target.has("discovery_hit") else target_allows_body_hit(),target_sight_depth()):
		game.hud.present_target("")
		_present_outline()
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
			pickup_target = game.target.get("input","") == "pickup"
			detail = game.target.controller.action_error(game.target.action)
			usable = detail.is_empty()
			if usable:
				action_key = "Click" if game.target.get("input","") == "place" else ("Hold E" if preload("res://scripts/equipment_button.gd").hold_handler(game.target).is_valid() else "E")
				action_label = "Carry" if pickup_target else ("Place" if game.target.get("input","") == "place" else "Use")
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
		"assembly":
			pickup_target = true
			caption = game.build_label(game.target.build)
			detail = "Prepared" if game.build_prepared(game.target.build) else "Unfinished"
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
			detail = game.model.placement_error(game.target.owner,game.target.mount,game.target.build)
			usable = detail.is_empty()
		"component":
			var spec = game.model.slot_definition(game.target.owner,game.target.sid)
			caption = game.components.title(spec.accepts)
			var selected: String = game.components.selected_uid(game.selected_kind)
			if game.components.slot_presentation(game.target.owner,game.target.sid).get("selected_caption",false) and game.model.items.has(selected):caption = game.components.title(game.model.items[selected].kind)
			detail = game.components.placement_error(game.target.owner,game.target.sid,game.components.selected_uid(game.selected_kind))
			usable = detail.is_empty()
	if not access_error.is_empty():
		detail = snap_guidance_message() if game.target.get("type","") in ["component","mount"] and (game.target.get("discovery_only",false) or game.camera.global_position.distance_to(game.target.point) > game.REACH) else access_error
		usable = false
	if not usable:
		action_key = ""
		action_label = ""
	if is_instance_valid(game.interaction_outline):
		# Contours advertise collection, not every available keyboard action.
		_present_outline(target_object() if usable and pickup_target else null)
	# The green geometry is the successful attachment affordance. Only explain
	# failures here; collection still needs its small keyboard action prompt.
	if usable and action_key.is_empty():
		game.hud.present_target("")
		return
	if not detail.is_empty():caption += "\n"+detail
	game.hud.present_target(caption,action_key,action_label,game.camera.unproject_position(presentation_point),usable)

func target_sight_depth() -> float:
	if game.target.get("type","") != "component":return 0.065
	return game.components.sight_depth(game.target.owner,game.target.sid)

func target_allows_body_hit() -> bool:
	if game.target.has("pickup_body"):return false
	if game.target.get("type","") == "equipment":return game.target.get("allow_body_hit",false)
	if game.target.get("type","") == "component":return game.components.service_access(game.target.owner,game.target.sid)
	if game.target.get("type","") == "mount":return game.components.service_access(game.target.get("owner",game.default_parent_id()),game.target.mount)
	return game.target.get("type","") in ["assembly","loose"]

func access(allowed: Array = [], check_approach: bool = true) -> String:
	if game.target.is_empty(): return "Aim near a part, bin, or mounting point."
	if game.target.get("discovery_only",false):return snap_guidance_message()
	if game.target.type in ["mount","component"]:
		var equipment_error = game.equipment_access_error(game.target.get("owner",game.target.get("build","")))
		if not equipment_error.is_empty():return equipment_error
	if game.target.type == "component":return game.components.access(check_approach)
	if game.camera.global_position.distance_to(game.target.point) > game.REACH: return "Out of reach. Move closer to the connection (maximum %.2f m)." % game.REACH
	if not can_see(game.target.point,allowed,target_allows_body_hit()): return "Connection is obstructed. Approach its exposed side or use the work-position controls."
	if game.target.type == "equipment":return game.target.controller.action_error(game.target.action)
	if game.target.type == "prep":
		var station: Node3D = game.stations[game.target.get("station","prep")]
		var envelope: Vector3 = SolidHandling.bounds(game.bodies[game.target.build]).size
		var volume: Vector3 = station.get_meta("work_volume")
		if envelope.x > volume.x or envelope.y > volume.y or envelope.z > volume.z:return "This assembly needs a larger work volume."
		for id in game.builds:
			if id != game.target.build and game.model.assemblies[id].location == "station:"+game.target.get("station","prep"):return "This station is occupied. Move its assembly first."
	if game.target.type in ["prep","mount"] and game.model.assemblies[game.target.build].location == "held" and check_approach:
		return game._carry_placement_error(game.placement_destination(),game.bodies[game.target.build],game.assembly_node(game.target.owner) if game.target.has("owner") else null)
	return ""

func carry_placement_error(destination: Transform3D, carried: WorkshopPart = null, receiving: PhysicsBody3D = null) -> String:
	if carried == null:
		var held: String = game.held_build()
		if held.is_empty():return "Your hands are empty."
		carried = game.bodies[held]
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
	game.ghost_material.no_depth_test = not game.target.get("discovery_only",false) and game.target.get("type","") == "component" and game.components.slot_presentation(game.target.owner,game.target.sid).get("ghost_no_depth_test",true)
	if game.target.get("type","") == "component":
		if not game.components.placement_error(game.target.owner,game.target.sid,game.components.selected_uid(game.selected_kind)).is_empty():return
		if not distant and not (game.components.access() if access_result == null else access_result).is_empty():return
		game.ghost.mesh = game.source[game.model.slot_definition(game.target.owner,game.target.sid).pose_source].mesh
		game.ghost.global_transform = game.components.slot_pose(game.target.owner,game.target.sid)
		game.ghost.visible = true
		return
	if game.target.is_empty():return
	if not game.target.type in ["mount","prep"]:return
	var owner: String = game.target.build
	if game.model.assemblies[owner].location != "held":return
	if not distant and not (access(target_receivers()) if access_result == null else access_result).is_empty():return
	if game.target.type == "mount" and not game.model.placement_error(game.target.owner,game.target.mount,owner).is_empty():return
	game.ghost.global_transform = game.placement_destination()
	game.ghost.visible = true
	show_assembly_ghost(owner)

func snap_guidance_message() -> String:
	if game.target.get("type","") == "component":
		var reason: String = game.components.placement_error(game.target.owner,game.target.sid,game.components.selected_uid(game.selected_kind))
		if not reason.is_empty():return reason
	var equipment_error: String = game.equipment_access_error(game.target.get("owner",game.target.get("build","")))
	if not equipment_error.is_empty():return equipment_error
	if game.camera.global_position.distance_to(game.target.point) > game.REACH:return "Move closer to attach"
	if game.target.get("discovery_obstructed",false) or not can_see(game.target.point,target_receivers(),target_allows_body_hit(),target_sight_depth()):return "Connection is obstructed. Approach its exposed side."
	return "Aim at the highlighted connection to attach"

func snap_guidance_available() -> bool:
	# Discovery is feedback only. Placement keeps its normal reach, carrying
	# sweep and access checks; no physics or recipe rule is relaxed here.
	if game.paused or game.target.is_empty() or game.target.get("discovery_obstructed",false):return false
	var distance = game.camera.global_position.distance_to(game.target.point)
	if (distance <= game.REACH and not game.target.get("discovery_only",false)) or distance > game.SNAP_DISCOVERY_RANGE:return false
	if game.camera.is_position_behind(game.target.point):return false
	if not can_see(game.target.point,target_receivers(),target_allows_body_hit(),target_sight_depth()):return false
	if game.target.has("discovery_hit") and not can_see(game.target.discovery_hit,[game.assembly_node(game.model.top_level(game.target.get("owner",game.target.get("build",""))))],true):return false
	return snap_candidate_valid(game.target)

func show_assembly_ghost(owner: String = "") -> void:
	if owner.is_empty():owner = game.target.get("build",game.held_build())
	if owner.is_empty():return
	game.ghost.mesh = null
	var pieces = game.runtime.visual_pieces(owner)
	var key = owner
	for member in game.runtime.descendants(owner):key += ":"+member+":"+str(game.assembly_node(member).get_meta("visual_revision",0))
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
			preview.set_meta("component_uid",visual.get_meta("component_uid",""))
			preview.set_meta("source_uid",visual.get_meta("source_uid",""))
			preview.set_meta("body_visual",visual)
			game.ghost.add_child(preview)
		game.ghost_assembly_signature = key
	for child in game.ghost.get_children():
		var visual = child.get_meta("body_visual")
		child.visible = is_instance_valid(visual) and visual.visible

func update_markers() -> void:
	game.components.update_markers()
