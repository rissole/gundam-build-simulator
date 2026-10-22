extends "res://tests/save_resume_test.gd"
## Real sources and scene collision; only small component preparation is staged.
var equipment: Node3D

func action(id: String) -> bool:
	var error: String = equipment.request(id)
	expect(error.is_empty(),"Equipment accepts "+id+": "+error)
	return error.is_empty()

func finish_motion() -> bool:
	for tick in range(300):
		if not equipment.moving:return true
		equipment.physics(0.5)
		await physics_frame
		if not equipment.blocked_reason.is_empty():
			print("MOTION_BLOCKED ",equipment.operation," ",equipment.uid," ",equipment.blocked_reason," pose ",equipment._body(equipment.uid).global_position)
			return false
	return false

func validate_equipment(label: String) -> void:
	var errors: Array[String] = equipment.validate(JSON.parse_string(JSON.stringify(equipment.capture())))
	expect(errors.is_empty(),label+": "+str(errors))

func prepare_foot() -> void:
	station("pad_1","prep")
	station("pad_2","prep2")
	station("pitch","prep3")
	stage("pad_1",1000);stage("pad_2",1000);stage("pitch",1000)
	for child in ["pad_1","pad_2","pitch"]:
		if child == "pitch":stage("foot",1000)
		game.model.move_assembly(child,"held")
		var sid: String = {"pad_1":"heel_1","pad_2":"heel_2","pitch":"pitch"}[child]
		expect(game.model.install("foot",sid,child).ok,"Mount prepared foot child "+child)
		game.runtime.mount("foot",sid,child)
	stage("foot",1000)
	game.components.sync("foot")
	game.refresh_assembly_collision("foot")
	game.player.global_position = Vector3(-8,0.1,2)
	game.foot_fixture._apply_pose(Transform3D(Basis.IDENTITY,Vector3(2.3,1.55,4.4)))
	game.foot_fixture.at_dispatch = true
	game.foot_fixture.work_pose = "upright"

func hardware(owner: String) -> void:
	stage(owner,1000)
	await frames(2)

func obstacle(at: Vector3, size: Vector3, layer: int = 1) -> StaticBody3D:
	var body = StaticBody3D.new()
	body.collision_layer = layer
	var collision = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = size;collision.shape = shape
	body.add_child(collision)
	game.add_child(body)
	body.position = at
	return body

func brace_collisions(active: bool) -> bool:
	var brace = game.leg_layout.gantry.get_node("LegStabilizer")
	var colliders: Array = brace.find_children("*","CollisionObject3D",true,false)
	return not colliders.is_empty() and colliders.all(func(body):return body.collision_layer == (1 if active else 0))

func primitive_bounds(source_uid: String, primitive_index: int, assembly: String) -> AABB:
	var primitive: Dictionary = game.leg_content.sources[source_uid].primitives[primitive_index]
	var size = AssemblyRuntime.vec(primitive.size)
	var center = AssemblyRuntime.vec(primitive.get("center",[0,0,0]))
	return game.runtime.node(assembly).global_transform*game.source[source_uid].transform*AABB(center-size*0.5,size)

func equipment_piece_bounds(piece: CollisionObject3D) -> AABB:
	var collision = SolidHandling.shapes(piece)[0]
	return piece.global_transform*collision.transform*collision.shape.get_debug_mesh().get_aabb()

func fixture_engagement(active: bool) -> bool:
	return game.leg_layout.fixture_contacts.size() == 8 and game.leg_layout.fixture_contacts.all(func(contact):return contact.body.collision_layer == (1 if active else 0) and contact.body.position.is_equal_approx(contact.closed if active else contact.open) and contact.visual.position.is_equal_approx(contact.body.position))

func foot_cradle_engagement(active: bool) -> bool:
	var contacts: Array = game.leg_layout.foot_cradle_contacts
	return contacts.size() == 2 and contacts.all(func(contact):return contact.body.collision_layer == (1 if active else 0) and contact.body.position.is_equal_approx(contact.closed if active else contact.open) and contact.body.position.is_equal_approx(contact.visual.position))

func foot_only_support() -> void:
	var matched = 0
	for owner in ["pad_1","pad_2"]:
		var root_visual: MeshInstance3D
		for piece in game.runtime.visual_pieces(owner):
			if piece.visual.has_meta("component_uid"):root_visual = piece.visual;break
		var sole: AABB = root_visual.global_transform*root_visual.mesh.get_aabb()
		for contact in game.leg_layout.foot_cradle_contacts:
			var bearing = equipment_piece_bounds(contact.body)
			if bearing.get_center().x < sole.position.x or bearing.get_center().x > sole.end.x:continue
			expect(is_equal_approx(bearing.end.y,sole.position.y) and bearing.position.x >= sole.position.x and bearing.end.x <= sole.end.x and bearing.position.z >= sole.position.z and bearing.end.z <= sole.end.z,"Foot-only cradle bears entirely beneath actual prepared heel sole")
			matched += 1
	expect(matched == 2 and foot_cradle_engagement(true) and game.model.assemblies.left_leg.slots.shin.is_empty(),"Both grounded cradle supports carry the seated foot before any shin exists")
	for post in game.leg_layout.foot_cradle_posts:
		var column = equipment_piece_bounds(post.body)
		var pad_top = post.closed.y+game.leg_layout.LEG_ORIGIN.y+post.closed_height*0.5
		expect(is_equal_approx(column.position.y,0.12) and is_equal_approx(column.end.y,0.65) and is_equal_approx(pad_top,0.65),"Cradle column connects fixed ground base to heel support pad")

func service_connected() -> bool:
	var top = equipment._service_cable.global_transform*Vector3(0,0.5,0)
	var eye = game.leg_layout.service_trolley.global_transform*Vector3(0,game.leg_layout.SERVICE_CABLE_Y,0)
	return top.is_equal_approx(eye)

func load_path_geometry() -> void:
	var jaws = 0
	var shafts: Array[AABB] = [primitive_bounds("LG-100__001",1,"left_leg"),primitive_bounds("LG-120__001",1,"left_leg")]
	for contact in game.leg_layout.fixture_contacts:
		if not contact.body.get_meta("fixture_jaw",false):continue
		var bounds = equipment_piece_bounds(contact.body)
		var shaft: AABB = shafts[0] if contact.closed.y < 4 else shafts[1]
		var left: bool = bounds.get_center().x < shaft.get_center().x
		var face: float = bounds.end.x if left else bounds.position.x
		var receiving_face: float = shaft.position.x if left else shaft.end.x
		expect(is_equal_approx(face,receiving_face) and bounds.position.z <= shaft.position.z+0.001 and bounds.end.z >= shaft.end.z-0.001 and bounds.position.y < shaft.end.y and bounds.end.y > shaft.position.y,"Fixture jaw bears on actual authored shaft face")
		jaws += 1
	expect(jaws == 4 and fixture_engagement(true),"Both fixture jaw pairs have closed load contacts and solid collision")
	var beam = primitive_bounds("PV-100__001",0,"pelvis")
	var saddles = 0
	var clamp_jaws = 0
	for piece in game.leg_layout.clamp.find_children("*","CollisionObject3D",true,false):
		var bounds = equipment_piece_bounds(piece)
		if piece.get_meta("equipment_piece","") == "PelvisSupportArm":
			expect(is_equal_approx(bounds.end.y,beam.position.y) and bounds.position.x < beam.end.x and bounds.end.x > beam.position.x and bounds.position.z < beam.end.z and bounds.end.z > beam.position.z,"Pelvis saddle bears beneath beam without penetration")
			saddles += 1
		if piece.get_meta("equipment_piece","") == "PelvisClampJaw":
			expect(is_equal_approx(bounds.end.z,beam.position.z) and bounds.position.y < beam.end.y and bounds.end.y > beam.position.y,"Pelvis clamp pad contacts beam front face")
			clamp_jaws += 1
	expect(saddles == 2 and clamp_jaws == 2,"Pelvis gantry has two complete saddle and side-pad load paths")
	var min_x: float = game.leg_layout.SERVICE_MIN_X
	var max_x: float = game.leg_layout.SERVICE_MAX_X
	var min_z: float = game.leg_layout.SERVICE_MIN_Z
	var max_z: float = game.leg_layout.SERVICE_MAX_Z
	var covered = min_x < 2.3 and max_x > 2.3 and min_z < 4.4 and max_z > 26
	for item_uid in equipment.stock_poses:
		var start: Transform3D = equipment.stock_poses[item_uid]
		var spec: Dictionary = equipment.parts[item_uid]
		var end: Transform3D = game.runtime.slot_pose(spec.owner,spec.slot)
		for point in [start.origin,end.origin]:covered = covered and point.x > min_x and point.x < max_x and point.z > min_z and point.z < max_z
	expect(covered,"Separate service bridge covers every actual rack, foot pickup and receiving destination")
	var beam_top = game.leg_layout.SERVICE_BRIDGE_Y+0.15
	expect(beam_top < 21.275 and game.leg_layout.SERVICE_CABLE_Y > 20.4,"Service bridge clears roof trusses and main crane above its full route")
	var outside_future = true
	var columns = 0
	for body in game.leg_layout.find_children("*","CollisionObject3D",true,false):
		if body.get_meta("equipment_piece","") != "ServiceCraneColumn":continue
		var at: Vector3 = body.global_position
		outside_future = outside_future and (at.x < 18.5 or at.x > 24 or at.z < 26 or at.z > 36)
		columns += 1
	expect(columns == 4 and outside_future,"Service crane columns preserve the reserved future assembly floor")

func run() -> void:
	game = load("res://scenes/workshop.tscn").instantiate()
	game.leg_workshop = true
	game.automated_test = true
	root.add_child(game)
	await frames(4)
	equipment = game.leg_equipment
	game.set_physics_process(false)
	game.paused = false
	validate_equipment("Initial equipment snapshot validates")
	expect(brace_collisions(false),"Retracted stabilizer has no phantom solid jaws")
	load_path_geometry()
	expect(not equipment.action_error("seat_foot").is_empty(),"Incomplete foot cannot leave carrier")
	await prepare_foot()
	await frames(3)
	expect(game.model.milestone("foot","complete"),"Real foot completion includes pads, actuator and retention")
	var blocker = obstacle(Vector3(2.3,1.4,8),Vector3(2,2,0.4))
	await frames(2)
	expect(not equipment.request("seat_foot").is_empty() and not equipment.foot_departed,"Scenery on route rejects entire carrier transaction")
	blocker.queue_free();await frames(2)
	if not action("seat_foot"):quit(1);return
	equipment.physics(1.0)
	validate_equipment("Mid foot transfer validates")
	expect(service_connected(),"Foot service cable connects directly to travelling trolley eye")
	var saved = equipment.capture()
	var stopped = game.foot.global_transform
	game.paused = true;equipment.physics(5)
	expect(game.foot.global_transform == stopped,"Global pause stops equipment without losing progress")
	game.paused = false
	equipment.apply(saved)
	var moving_before = equipment.capture()
	var source_collision = SolidHandling.shapes(game.foot)[0]
	var occupied_point = game.foot.global_transform*source_collision.transform*source_collision.shape.get_debug_mesh().get_aabb().get_center()
	var pedestrian = obstacle(occupied_point,Vector3(0.6,1.8,0.6),8)
	await frames(2)
	equipment.physics(2.0)
	expect(not equipment.blocked_reason.is_empty() and game.foot.global_transform == stopped and equipment.progress == moving_before.progress,"A person entering the route pauses the actual load atomically")
	validate_equipment("Dynamically blocked foot movement validates")
	pedestrian.queue_free();await frames(2)
	equipment.physics(0.2)
	expect(equipment.blocked_reason.is_empty() and game.foot.global_position.y > stopped.origin.y,"Clearing the route resumes the same supported movement")
	expect(await finish_motion(),"Completed foot arrives through supported carrier motion")
	expect(game.model.assemblies.foot.parent == "left_leg" and game.foot.get_parent() == game.runtime.node("left_leg"),"Seated foot has one actual parent")
	validate_equipment("Foot seated state validates")
	foot_only_support()
	for item_uid in ["LG-100__001","LG-110__001","LG-120__001"]:
		await hardware("left_leg")
		if not action("install:"+item_uid):quit(1);return
		equipment.physics(0.7)
		validate_equipment("Mid structural part lift validates")
		expect(service_connected(),"Structural part cable follows its independent overhead trolley")
		expect(await finish_motion(),"Large component arrives on equipment: "+item_uid)
		expect(game.model.items[item_uid].owner == "left_leg" and not equipment.stock_bodies[item_uid].visible,"Exact equipment item moves from rack to leg: "+item_uid)
	await hardware("left_leg")
	expect(game.model.milestone("left_leg","structural_ready"),"Physical structural parts and all retention satisfy leg readiness")
	var complete_leg: CollisionObject3D = game.runtime.node("left_leg")
	var through_crossbar = complete_leg.global_transform
	through_crossbar.origin.z += 2.0
	expect(not equipment._sweep(complete_leg,complete_leg.global_transform,through_crossbar,"","leg_transfer","left_leg").is_empty(),"Fixed rear crossbars remain solid during supported transfer")
	expect(game.foot_fixture.carriage.global_position.is_equal_approx(Vector3(2.3,0,4.4)),"Empty rail carrier remains at dispatch clear of leg fixture and exit route")
	validate_equipment("Completed leg on fixture validates")
	expect(not equipment.action_error("release_hoist").is_empty(),"Hoist cannot release before secured hip")
	if not action("pick_leg"):quit(1);return
	expect(equipment.assisting and not equipment.fixture_engaged,"Leg hoist engagement precedes fixture release")
	expect(fixture_engagement(false),"Fixture jaws retract and release collision before hoisted transfer")
	expect(foot_cradle_engagement(false) and game.leg_layout.foot_cradle_posts.all(func(post):return equipment_piece_bounds(post.body).end.y < 0.5),"Heel cradle telescopes beneath the transfer sole before hoisted movement")
	if not action("transfer_leg"):quit(1);return
	equipment.physics(0.7)
	validate_equipment("Mid completed leg route validates")
	saved = equipment.capture()
	var invalid = saved.duplicate(true)
	invalid.waypoints[0][9] += 2
	expect(not equipment.validate(invalid).is_empty(),"Forged guide route cannot change equipment destination")
	invalid = saved.duplicate(true);invalid.assisting = false
	expect(not equipment.validate(invalid).is_empty(),"Moving leg requires active hoist support")
	equipment.apply(saved)
	expect(await finish_motion(),"Guided completed leg clears actual workshop to pelvis approach")
	if not action("seat_leg"):quit(1);return
	expect(await finish_motion(),"Hip seating raises integral ball into socket")
	expect(game.model.assemblies.left_leg.parent == "pelvis" and equipment.assisting,"Seating keeps assist despite model parent ownership")
	validate_equipment("Seated leg with live assist validates")
	for item_uid in ["PV-120__002","PV-120__001"]:
		var main_hook: Transform3D = game.leg_layout.hook.global_transform
		if not action("install:"+item_uid):quit(1);return
		equipment.physics(0.4)
		expect(service_connected() and game.leg_layout.hook.global_transform.is_equal_approx(main_hook),"Ring service trolley follows load while main leg hoist remains attached")
		expect(await finish_motion(),"Equipment retainer half seats: "+item_uid)
	await hardware("pelvis")
	expect(game.model.milestone("pelvis","left_leg_secured"),"Pelvis retention includes every required real fastener")
	expect(action("stabilize") and action("release_hoist"),"Secured stabilized leg releases hoist")
	expect(brace_collisions(true),"Engaged stabilizer jaws provide actual solid support")
	validate_equipment("Released stable nested leg validates")
	var released = game.model.assemblies.pelvis.history.size()
	expect(not equipment.undo("pelvis").get("error","").is_empty() and game.model.assemblies.pelvis.history.size() == released,"Retention undo requires reacquiring hoist")
	expect(action("reacquire_hoist"),"Hoist reacquires supported seated leg")
	for pass_index in range(game.model.assemblies.pelvis.history.size()):
		var result: Dictionary = equipment.undo("pelvis")
		if result.handled:
			expect(result.get("error","").is_empty(),"Equipment undo pelvis: "+str(result))
			expect(await finish_motion(),"Removed load returns along support route")
		else:expect(game.model.undo("pelvis").ok,"Undo small pelvis retention")
		game.components.sync("pelvis")
		await frames(1)
	expect(game.model.assemblies.left_leg.location == "support:leg_hoist" and equipment.leg_stage == "approach","Unseated exact leg remains hoisted")
	expect(brace_collisions(false),"Unseating retracts stabilizer visuals and collision together")
	if action("return_leg"):expect(await finish_motion(),"Whole leg returns to reserved assembly fixture")
	validate_equipment("Returned full leg state validates")
	expect(fixture_engagement(true),"Returning completed leg closes the physical fixture jaws")
	expect(foot_cradle_engagement(true),"Returning completed leg restores heel cradle support")
	expect(game.model.assemblies.left_leg.location == "support:leg_fixture" and game.model.milestone("left_leg","structural_ready") and game.model.integrity_errors().is_empty(),"Full round trip preserves all structural identities and completion")
	for pass_index in range(game.model.assemblies.left_leg.history.size()):
		var result: Dictionary = equipment.undo("left_leg")
		if result.handled:
			expect(result.get("error","").is_empty(),"Supported structural undo starts: "+str(result))
			expect(await finish_motion(),"Structural load returns to its original reserved support")
			validate_equipment("Supported structural return snapshot validates")
		else:expect(game.model.undo("left_leg").ok,"Undo ordinary leg connection before structural removal")
		game.components.sync("left_leg")
		await frames(1)
	for item_uid in ["LG-100__001","LG-110__001","LG-120__001"]:
		expect(equipment.stock_bodies[item_uid].visible and equipment.stock_bodies[item_uid].global_transform.is_equal_approx(equipment.stock_poses[item_uid]) and game.model.items[item_uid].location == "support:"+equipment.parts[item_uid].support,"Structural source identity and rack pose restored: "+item_uid)
	expect(not equipment.foot_departed and game.model.assemblies.foot.location == "support:foot_carrier" and game.foot_fixture.at_dispatch and game.foot.global_position.is_equal_approx(Vector3(2.3,1.55,4.4)),"Exact prepared foot returns by carrier to original dispatch support")
	expect(game.model.milestone("foot","complete") and game.model.integrity_errors().is_empty(),"Complete foot internals survive full nested equipment undo")
	var passed = checks.all(func(check):return check.passed)
	print("LEG_EQUIPMENT_AUDIT ","PASS" if passed else "FAIL"," ",checks.size()," checks")
	quit(0 if passed else 1)
