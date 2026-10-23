extends SceneTree
## Independent M1 geometry/isolation attack. Uses sampled controller poses, not
## evidence of ordinary desktop operation or human visibility/scale acceptance.
var game: Node
var trial: Node3D
var checks: Array[Dictionary] = []
var failures: Dictionary = {}
var sampled = 0
var min_floor = INF
var min_source_clearance = INF
var relatives: Array[Dictionary] = []
var access_report: Array[Dictionary] = []
var deferred_root_samples = 0

func _initialize() -> void:
	run.call_deferred()

func expect(ok: bool, label: String) -> void:
	checks.append({"check":label,"passed":ok})
	print("CHECK ","PASS " if ok else "FAIL ",label)

func fail_once(category: String, detail: String) -> void:
	if not failures.has(category):failures[category] = detail

func frames(count: int) -> void:
	for index in range(count):await physics_frame

func descendants(node: Node, inverse: Transform3D) -> void:
	if node is MeshInstance3D or node is CollisionShape3D or node is CollisionObject3D:
		relatives.append({"node":node,"pose":inverse*node.global_transform})
	for child in node.get_children():descendants(child,inverse)

func obb(visual: MeshInstance3D) -> Dictionary:
	var bound = visual.mesh.get_aabb()
	var pose = visual.global_transform
	var axes = [pose.basis.x.normalized(),pose.basis.y.normalized(),pose.basis.z.normalized()]
	var half = bound.size*.5*Vector3(pose.basis.x.length(),pose.basis.y.length(),pose.basis.z.length())
	return {"center":pose*bound.get_center(),"axes":axes,"half":half,"aabb":pose*bound}

func intersects(a: Dictionary, b: Dictionary, tolerance: float = .002) -> bool:
	if not a.aabb.grow(tolerance).intersects(b.aabb):return false
	var axes: Array = a.axes.duplicate()
	axes.append_array(b.axes)
	for aa in a.axes:
		for bb in b.axes:axes.append(aa.cross(bb))
	for axis in axes:
		if axis.length_squared()<.00000001:continue
		axis = axis.normalized()
		var ar = 0.0
		var br = 0.0
		for index in range(3):
			ar += a.half[index]*absf(axis.dot(a.axes[index]))
			br += b.half[index]*absf(axis.dot(b.axes[index]))
		if absf(axis.dot(a.center-b.center))>ar+br+tolerance:return false
	return true

func connected(records: Array, source_ids: Array, target_id: String) -> bool:
	var bounds: Array[Dictionary] = []
	var reached: Array[int] = []
	var targets: Array[int] = []
	for index in range(records.size()):
		bounds.append(obb(records[index].visual))
		if source_ids.has(records[index].id):reached.append(index)
		if records[index].id == target_id:targets.append(index)
	var cursor = 0
	while cursor<reached.size():
		var current = reached[cursor]
		cursor += 1
		for index in range(records.size()):
			if not reached.has(index) and intersects(bounds[current],bounds[index]):reached.append(index)
	return not targets.is_empty() and targets.all(func(index):return reached.has(index))

func pose_close(a: Transform3D, b: Transform3D) -> bool:
	return a.origin.distance_to(b.origin)<.0002 and a.basis.x.distance_to(b.basis.x)<.0002 and a.basis.y.distance_to(b.basis.y)<.0002 and a.basis.z.distance_to(b.basis.z)<.0002

func jaw_touches_load(contact: Dictionary) -> bool:
	var slot_id = "shin" if contact.local_y<4 else "spar"
	var uid: String = game.model.assemblies.left_leg.slots[slot_id]
	var target_mesh: MeshInstance3D
	for child in trial.load_body.get_children():
		if child is MeshInstance3D and child.get_meta("component_uid","") == uid:target_mesh = child;break
	if target_mesh == null:return false
	var side_axis: Vector3 = trial.load_body.global_basis.x*contact.side
	var center: Vector3 = contact.visual.global_position
	var start = target_mesh.to_local(center+side_axis*.20)
	var end = target_mesh.to_local(center-side_axis*.40)
	var nearest = INF
	var hit_world = Vector3.ZERO
	var vertices = target_mesh.mesh.get_faces()
	for index in range(0,vertices.size(),3):
		var hit = Geometry3D.segment_intersects_triangle(start,end,vertices[index],vertices[index+1],vertices[index+2])
		if hit == null:continue
		if start.distance_to(hit)<nearest:
			nearest = start.distance_to(hit);hit_world = target_mesh.to_global(hit)
	return nearest<INF and hit_world.distance_to(center-side_axis*.06)<.002

func check_geometry(label: String) -> void:
	sampled += 1
	var root_pose: Transform3D = trial.load_body.global_transform
	var physical_root: Transform3D = PhysicsServer3D.body_get_state(trial.load_body.get_rid(),PhysicsServer3D.BODY_STATE_TRANSFORM)
	var after_physics = label.ends_with("after physics")
	if not after_physics and not pose_close(root_pose,physical_root):deferred_root_samples += 1
	for record in relatives:
		var expected: Transform3D = root_pose*record.pose
		if not record.node.global_transform.is_equal_approx(expected):fail_once("descendants",label+" "+str(record.node.get_path()))
		if record.node is CollisionObject3D:
			var actual: Transform3D = PhysicsServer3D.body_get_state(record.node.get_rid(),PhysicsServer3D.BODY_STATE_TRANSFORM)
			# Animatable getters expose the last committed frame between ticks;
			# explicitly published frozen rigid children expose their current frame.
			# Check active collision consistency and frozen-child pose accordingly,
			# then require every body to match the scene after the tick commits.
			var physical_expected: Transform3D = expected if after_physics or record.node is RigidBody3D else physical_root*record.pose
			if not pose_close(actual,physical_expected):fail_once("physics_after" if after_physics else "physics_relative_before",label+" "+str(record.node.get_path())+" assembly="+str(record.node.get_meta("assembly_id",""))+" actual="+str(actual.origin)+" expected="+str(physical_expected.origin))
		if record.node is MeshInstance3D:
			var bound: AABB = record.node.global_transform*record.node.mesh.get_aabb()
			min_floor = minf(min_floor,bound.position.y)
			if bound.position.y<-.002:fail_once("floor",label+" "+str(record.node.name)+" Y="+str(bound.position.y))
	var pieces: Array = trial.layout.moving_pieces.duplicate()
	for piece in trial.layout.static_pieces:
		if piece.id in ["Rail","TraverserRail"]:pieces.append(piece)
	if not connected(pieces,["Rail"],"LocatedJaw"):fail_once("rail_support",label)
	for contact in trial.layout.contacts:
		if not jaw_touches_load(contact):fail_once("load_contact",label+" "+str(contact.kind)+" Y="+str(contact.local_y)+" side="+str(contact.side))
	for piece in trial.layout.moving_pieces:
		var bound: AABB = piece.visual.global_transform*piece.visual.mesh.get_aabb()
		if bound.position.y<-.002:fail_once("fixture_floor",label+" "+piece.id+" Y="+str(bound.position.y))
	# Conservative AABB clearance to the reserved beam rack across the only
	# reachable loaded route; this makes no claim about a future empty route.
	for rack in trial.layout.static_pieces:
		if rack.id != "ReservedSparRack":continue
		var source: AABB = rack.visual.global_transform*rack.visual.mesh.get_aabb()
		for piece in trial.layout.moving_pieces:
			var bounds: AABB = piece.visual.global_transform*piece.visual.mesh.get_aabb()
			min_source_clearance = minf(min_source_clearance,bounds.position.x-source.end.x)
		for record in relatives:
			if record.node is MeshInstance3D:
				var bounds: AABB = record.node.global_transform*record.node.mesh.get_aabb()
				min_source_clearance = minf(min_source_clearance,bounds.position.x-source.end.x)

func key(code: Key, pressed: bool = true) -> void:
	var event = InputEventKey.new()
	event.physical_keycode = code;event.pressed = pressed
	game.handle_desktop_input(event)

func check_readonly_inputs() -> void:
	var before = JSON.stringify({"items":game.model.items,"assemblies":game.model.assemblies})
	for owner in ["pad_1","pad_2","pitch","foot","left_leg","pelvis"]:
		game.hud.open_manual(owner)
		# A stale non-equipment target must not bypass the read-only sample seam.
		game.target = {"type":"pad","build":owner,"point":game.assembly_node(owner).global_position}
		key(KEY_E);key(KEY_E,false)
		game.target = {"type":"pad","build":owner,"point":game.assembly_node(owner).global_position}
		var click = InputEventMouseButton.new();click.button_index = MOUSE_BUTTON_LEFT;click.pressed = true
		game.handle_desktop_input(click)
		key(KEY_Z);key(KEY_Z,false)
		key(KEY_Q);key(KEY_Q,false)
		key(KEY_F);key(KEY_F,false)
		key(KEY_R)
		var drag = InputEventMouseMotion.new();drag.relative = Vector2(50,25)
		game.handle_desktop_input(drag);key(KEY_R,false)
		expect(JSON.stringify({"items":game.model.items,"assemblies":game.model.assemblies}) == before,"Collect/click/build/reset/rotate inputs preserve staged "+owner+" ownership")
	check_geometry("after legacy build inputs")

func unchanged_state() -> String:
	var machinery: Array = []
	for piece in trial.layout.static_pieces+trial.layout.moving_pieces:
		machinery.append({"id":piece.id,"pose":var_to_str(piece.visual.global_transform),"visible":piece.visual.visible})
	return JSON.stringify({"items":game.model.items,"assemblies":game.model.assemblies,"path":trial.path,"goal":trial.goal,"moving":trial.moving,"load":var_to_str(trial.load_body.global_transform),"machinery":machinery,"node_count":game.find_children("*","Node",true,false).size()})

func expect_rejected(action: String, error: String, label: String) -> void:
	var before = unchanged_state()
	var result: String = trial.request(action)
	trial.physics(.25)
	expect(result == error and unchanged_state() == before,label+"; rejection preserves model, motion and all visible support geometry")
	expect(trial.labels.all(func(panel):return panel.text.contains(error)),label+"; physical panels explain the rejection")

func check_dock_boundary() -> void:
	trial.path = 3;trial.goal = 3;trial._pose();trial._refresh()
	await physics_frame
	expect(trial.retention_state() == "none" and game.model.support_occupant("m1_leg_rail") == "left_leg","Normal M1 docking retains rail ownership with no installed hip retention")
	expect(not game.model.support_definitions.has("m1_sample_receiver") and trial.layout.contacts.size() == 4 and trial.layout.contacts.all(func(contact):return contact.kind == "rail") and trial.layout.find_children("*Sample*","Node",true,false).is_empty(),"Synthetic receiver, capture controls and appearing support geometry are absent")
	expect_rejected("advance",trial.RETENTION_REQUIRED,"Docked Advance cannot release unfastened leg")
	expect(trial.request("return").is_empty(),"Docked unfastened leg can Return on its existing holder")
	trial.physics(.15)
	expect(trial.path < 3 and game.model.assemblies.left_leg.location == "support:m1_leg_rail" and trial.load_body.global_transform.is_equal_approx(trial.rail_pose(trial.path).load),"Return lowers the same rail-supported leg without any ownership handoff")
	trial.request("stop")
	trial.path = 0;trial.goal = 0;trial._pose()
	await physics_frame

func stage_retention_slot(sid: String) -> bool:
	# Test-only real installation. M1 offers no mounting, half handling or bolting.
	var spec: Dictionary = game.model.slot_definition("pelvis",sid)
	var uid = ""
	for candidate in game.model.items:
		var item: Dictionary = game.model.items[candidate]
		if item.kind == spec.accepts and item.owner.is_empty():uid = candidate;break
	if uid.is_empty():return false
	var item: Dictionary = game.model.items[uid]
	var result: Dictionary
	if item.location.begins_with("support:"):
		result = game.model.install_supported("pelvis",sid,uid,item.location.trim_prefix("support:"))
	else:
		if item.location == "bin":game.model.transfer(item.kind,"bin","pocket",uid)
		result = game.model.install("pelvis",sid,uid)
	game.components.sync("pelvis")
	return result.ok

func check_retention_interlocks() -> void:
	# Stage the real authored seat using its authorized legacy support, solely to
	# exercise valid model prerequisites. This is not a playable M1 transition.
	trial.path = 3;trial.goal = 3;trial.moving = false;trial._pose()
	expect(game.model.transfer_supported_assembly("left_leg","m1_leg_rail","leg_hoist").is_empty() and game.model.install_supported("pelvis","left_leg","left_leg","leg_hoist").ok,"Test-only setup mounts actual leg through authorized model APIs")
	game.runtime.mount("pelvis","left_leg","left_leg")
	expect(trial.retention_state() == "none","Pelvis seat alone is not a fitted retainer")
	expect_rejected("return",trial.OWNERSHIP_OUTSIDE_M1,"Externally mounted seat needs the future unmount seam, not a false retention gate")
	var sequences = [["ring_1","ring/washer_3","ring/bolt_3","ring/washer_4","ring/bolt_4","ring_2","ring/washer_1","ring/bolt_1","ring/washer_2","ring/bolt_2"],["ring_2","ring/washer_1","ring/bolt_1","ring/washer_2","ring/bolt_2","ring_1","ring/washer_3","ring/bolt_3","ring/washer_4","ring/bolt_4"]]
	for sequence in sequences:
		for index in range(sequence.size()):
			var sid: String = sequence[index]
			expect(stage_retention_slot(sid),"Test-only real compatible installation: "+sid)
			var complete = index == sequence.size()-1
			expect(trial.retention_state() == ("complete" if complete else "partial"),"Retention after "+sid+" requires both halves and all four washer/bolt pairs")
			expect_rejected("advance",trial.RELEASE_OUTSIDE_M1 if complete else trial.RETENTION_REQUIRED,"Advance after "+sid)
			expect_rejected("return",trial.RETENTION_BLOCKS_RETURN,"Return after "+sid)
			if index == 0:
				trial.path = 2.95;trial.goal = 2.95;trial._pose()
				expect_rejected("return",trial.RETENTION_BLOCKS_RETURN,"Stopped near-dock Return with first retaining half")
				trial.path = 3;trial.goal = 3;trial._pose()
		expect(game.model.milestone("pelvis","left_leg_secured") and game.model.integrity_errors().is_empty() and trial.load_body.get_parent() == game.runtime.node("pelvis"),"Complete detection uses actual pelvis-owned leg and ten installed identities; M1 still has no release operation")
		for index in range(sequence.size()-1,-1,-1):
			var sid: String = sequence[index]
			var spec: Dictionary = game.model.slot_definition("pelvis",sid)
			var result: Dictionary
			if spec.get("support_required",false):
				var uid: String = game.model.assemblies.pelvis.slots[sid]
				var outputs: Array = spec.source_supports.filter(func(id):return game.model.support_error(uid,id).is_empty() and game.model.support_occupant(id).is_empty())
				result = game.model.undo_supported("pelvis",outputs[0]) if not outputs.is_empty() else {"ok":false}
			else:result = game.model.undo("pelvis")
			expect(result.ok,"Test-only supported removal restores "+sid)
		game.components.sync("pelvis")
		expect(trial.retention_state() == "none","Removing every retaining identity restores no-retention classification")
	# Explicit test teardown restores model AND scene ownership before motion.
	expect(game.model.undo_supported("pelvis","leg_hoist").ok and game.model.transfer_supported_assembly("left_leg","leg_hoist","m1_leg_rail").is_empty(),"Test-only teardown restores rail ownership through model APIs")
	trial.load_body.reparent(game)
	trial._pose();trial.blocked_reason = "";trial._refresh()
	expect(trial.action_error("return").is_empty() and game.model.integrity_errors().is_empty(),"Restored ordinary M1 dock permits loaded Return")

func check_deck_access(probe_levels: Array = []) -> void:
	# Geometric work-position proof only: no retaining parts or M2 operations.
	var lift = game.access_lifts.hip
	var sampled_levels: Array = lift.stops if probe_levels.is_empty() else probe_levels
	var original_stops: Array = lift.stops.duplicate()
	if not probe_levels.is_empty():lift.stops.assign(probe_levels)
	for sid in game.runtime.definition("pelvis").slots:
		if not sid.begins_with("ring/"):continue
		var point: Vector3 = game.components.slot_point("pelvis",sid)
		var best = Vector3.ZERO
		var best_height = 0.0
		var best_crouch = false
		var best_distance = INF
		var closest = INF
		var visible_positions = 0
		for level in sampled_levels:
			lift.apply({"height":level,"destination":level,"moving":false})
			await frames(2)
			for use_crouch in [false,true]:
				game.player.global_position = lift.to_global(Vector3(0,lift.height+.015,0))
				key(KEY_CTRL,use_crouch)
				game._update_crouch(use_crouch,1.0)
				for ix in range(9):
					for iz in range(9):
						var local = Vector3(lerpf(-lift.deck_size.x/2+.36,lift.deck_size.x/2-.36,float(ix)/8),lift.height,lerpf(-lift.deck_size.y/2+.36,lift.deck_size.y/2-.36,float(iz)/8))
						var feet: Vector3 = lift.to_global(local)
						game.player.global_position = feet
						var distance: float = game.camera.global_position.distance_to(point)
						closest = minf(closest,distance)
						if game._visible(point,game.components.receiving_bodies("pelvis",sid),game.components.service_access("pelvis",sid)):
							visible_positions += 1
							if distance<best_distance:best_distance = distance;best = feet;best_height = level;best_crouch = use_crouch
		var reachable = best_distance<=game.REACH
		var grounded = false
		if reachable:
			lift.apply({"height":best_height,"destination":best_height,"moving":false})
			game.player.global_position = best+Vector3.UP*.015;game.player.velocity = Vector3.ZERO
			key(KEY_CTRL,best_crouch)
			game.set_physics_process(true)
			await frames(16)
			grounded = game.player.is_on_floor() and absf(game.player.global_position.y-lift.height)<.05
			reachable = game.camera.global_position.distance_to(point)<=game.REACH and game._visible(point,game.components.receiving_bodies("pelvis",sid),game.components.service_access("pelvis",sid))
			game.set_physics_process(false)
		var record = {"slot":sid,"minimum_distance":closest,"minimum_visible_distance":best_distance if best_distance<INF else -1,"visible_positions":visible_positions,"grounded":grounded,"reachable":reachable,"crouched":best_crouch,"height":best_height,"actual_crouched":game.crouched,"actual_eye":[game.camera.global_position.x,game.camera.global_position.y,game.camera.global_position.z],"feet":[best.x,best.y,best.z],"target":[point.x,point.y,point.z]}
		access_report.append(record)
		if not reachable or not grounded:print("DECK_ACCESS ",JSON.stringify(record))
		expect(reachable and grounded,"Grounded safe deck position sees and reaches authored "+sid+" (geometry only)")
	key(KEY_CTRL,false)
	lift.stops.assign(original_stops)

func run() -> void:
	game = load("res://scenes/workshop.tscn").instantiate()
	game.m1_blockout = true
	root.add_child(game)
	game.automated_test = true
	game.set_physics_process(false)
	game.set_paused(false)
	await frames(3)
	trial = game.m1
	descendants(trial.load_body,trial.load_body.global_transform.affine_inverse())
	var nested_context = relatives.filter(func(record):return record.node is MeshInstance3D and not record.node.has_meta("component_uid") and not record.node.has_meta("installed_uid") and not record.node.has_meta("source_uid"))
	expect(not nested_context.is_empty(),"Independent traversal includes untagged static foot geometry")
	expect(game.saves.get_script().resource_path == "res://scripts/m1_session.gd","M1 constructs only the session adapter")
	var marker_path = "/tmp/gundam-m1-acceptance-save-marker.json"
	FileAccess.open(marker_path,FileAccess.WRITE).store_string("M1 isolation marker; not a save codec payload")
	var marker_hash = FileAccess.get_sha256(marker_path)
	game.saves.setup(game,marker_path,true)
	expect(not game.saves.save_now() and not game.saves.reload_save(true),"Explicit save/reload and normal-style path override remain unavailable")
	game.set_paused(true);game.set_paused(false)
	expect(FileAccess.get_sha256(marker_path) == marker_hash,"Explicit path override and pause preserve existing bytes")
	check_readonly_inputs()
	await check_dock_boundary()
	# Dense direct-pose sampling independently checks machinery geometry. Ordinary
	# desktop movement/operation is covered by the owner's M1 blockout test.
	for direction in [1,-1]:
		for index in range(61):
			trial.path = float(index if direction == 1 else 60-index)/20
			trial._pose()
			check_geometry("path="+str(trial.path)+" before physics")
			await physics_frame
			check_geometry("path="+str(trial.path)+" after physics")

	for category in ["descendants","physics_relative_before","physics_after","floor","rail_support","load_contact","fixture_floor"]:
		expect(not failures.has(category),category+" across all sampled phases"+(": "+str(failures[category]) if failures.has(category) else ""))
	expect(min_source_clearance > 2.5,"Loaded holder and complete leg stay over 2.5 m east of reserved upper-leg beam rack throughout the route")
	trial.path = 3;trial.goal = 3;trial._pose()
	await check_deck_access()
	await check_retention_interlocks()
	var passed = checks.all(func(check):return check.passed)
	var report = {"passed":passed,"checks":checks,"failures":failures,"samples":sampled,"deferred_root_samples":deferred_root_samples,"minimum_load_floor_y":min_floor,"context_meshes":nested_context.size(),"minimum_reserved_source_clearance_x":min_source_clearance,"retention_setup":"Test-only real model installation and teardown; M1 has no playable retention or release","deck_access":access_report,"method":"Independent direct-pose geometry/isolation; no rendered review or human scale acceptance","rendered":false}
	FileAccess.open("res://verification/m1-acceptance-audit.json",FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
	game.free()
	await process_frame
	print("M1_ACCEPTANCE ","PASS" if passed else "FAIL"," ",checks.size()," checks / ",sampled," samples")
	quit(0 if passed else 1)
