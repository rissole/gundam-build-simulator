extends "res://tests/save_resume_test.gd"
## The complete structural leg is intentionally staged by the M1 scenario itself.
var trial: Node3D
var min_floor = INF
var total_motion_samples = 0
var preview_matches = true
var fixture_floor = INF

func run() -> void:
	game = load("res://scenes/workshop.tscn").instantiate()
	game.m1_blockout = true
	root.add_child(game)
	game.automated_test = true
	game.set_paused(false)
	await frames(5)
	trial = game.m1
	print("M1_LOAD meshes=",trial.mesh_bounds.size()," solids=",trial.solids.size())
	expect(game.model.milestone("foot","complete") and game.model.milestone("left_leg","structural_ready"),"M1 supplies the fully populated existing structural leg")
	expect(game.model.items.values().filter(func(item):return item.location == "installed").size() == 165,"All 165 existing load identities are fitted; pelvis retention remains outside M1")
	expect(not game.saves.enabled and not game.saves.save_now() and not game.saves.reload_save(),"M1 never enables or invokes normal save IO")
	var spar: Dictionary = game.leg_content.sources["LG-120__001"]
	var socket: Dictionary = game.leg_content.sources["PV-110__001"]
	var ball_center = AssemblyRuntime.vec(spar.position)+AssemblyRuntime.vec(spar.primitives[3].center)
	var radius: float = spar.primitives[3].radius
	var skirt_y: float = game.runtime.node("pelvis").global_position.y+socket.primitives[2].center[1]-socket.primitives[2].length/2
	var crown_clearance = INF
	for index in range(201):
		var pose: Transform3D = trial.rail_pose(1.0+float(index)/200).load
		crown_clearance = minf(crown_clearance,skirt_y-(pose*ball_center).y-radius)
	expect(crown_clearance > .060,"Actual integral ball clears socket skirt throughout the populated tilt, including intermediate angles")
	var dock: Transform3D = trial.rail_pose(3).load
	var socket_center: Vector3 = game.runtime.node("pelvis").global_transform*AssemblyRuntime.vec(socket.position)
	expect((dock*ball_center).distance_to(socket_center)<.0001 and radius < socket.primitives[0].inner and radius < socket.primitives[1].inner and radius < socket.primitives[2].inner,"Upward docking is coaxial and clears the authored rim, skirt and bowl")
	var axle_shape = BoxShape3D.new();axle_shape.size = Vector3(1.2,.4,.5)
	var axle_query = PhysicsShapeQueryParameters3D.new();axle_query.shape = axle_shape
	axle_query.transform = Transform3D(Basis.IDENTITY,Vector3(10.76,1.35,14.5));axle_query.collision_mask = 1;axle_query.margin = .001
	expect(game.get_world_3d().direct_space_state.intersect_shape(axle_query,1).is_empty(),"Full 1.2 m knee extraction volume clears machinery at the working axle height")
	for section in range(3):
		var error: String = trial.request("advance")
		expect(error.is_empty(),"Advance stage "+str(section)+": "+error)
		for tick in range(250):
			if not trial.moving:break
			trial.physics(.12)
			check_sample()
			await physics_frame
		if not trial.blocked_reason.is_empty():print("M1_BLOCKED path=",trial.path," ",trial.blocked_reason)
		expect(is_equal_approx(trial.path,float(section+1)),"Supported loaded route reaches stage "+str(section+1))
		if not trial.blocked_reason.is_empty():break
	if is_equal_approx(trial.path,3.0):
		expect(trial.request("advance") == trial.RETENTION_REQUIRED and not trial.moving and game.model.support_occupant("m1_leg_rail") == "left_leg","Docked Advance rejects release while holder keeps the load")
		for section in range(2,-1,-1):
			var error: String = trial.request("return")
			expect(error.is_empty(),"Return accepts reverse stage "+str(section))
			for tick in range(250):
				if not trial.moving:break
				trial.physics(.12);check_sample();await physics_frame
			if not trial.blocked_reason.is_empty():print("M1_REVERSE_BLOCKED ",trial.path," ",trial.blocked_reason)
			expect(is_equal_approx(trial.path,float(section)),"Reverse route reaches stage "+str(section))
			if not trial.blocked_reason.is_empty():break
	expect(is_zero_approx(trial.path) and game.model.support_occupant("m1_leg_rail") == "left_leg","Same continuously supported sample withdraws from socket and returns to loading position")
	expect(game.model.integrity_errors().is_empty(),"Full forward/reverse journey preserves physical ownership")
	expect(preview_matches,"Continuous safety preview matches every moving visible support pose and size")
	expect(min_floor >= .499 and fixture_floor >= -.001,"Complete load and visible machinery clear floor through forward and reverse sweeps")
	# A thin obstruction enters ahead of the actual integral ball, not an empty
	# controller envelope. The same partial trip must be recoverable in reverse.
	if is_zero_approx(trial.path):
		var blocker = StaticBody3D.new();game.add_child(blocker)
		blocker.name = "M1ThinRouteObstruction"
		var collision = CollisionShape3D.new();var box = BoxShape3D.new()
		box.size = Vector3(.20,.8,.012);collision.shape = box;blocker.add_child(collision)
		blocker.position = Vector3(11.9,1.35,19.3)
		await frames(2)
		trial.request("advance")
		for tick in range(100):
			if not trial.moving:break
			trial.physics(.08);await physics_frame
		expect(not trial.moving and not trial.blocked_reason.is_empty() and trial.path < .1,"Thin real obstacle stops motion before full populated load reaches it")
		expect(game.model.support_occupant("m1_leg_rail") == "left_leg","Blocked motion keeps rail support and identity")
		var error: String = trial.request("return")
		for tick in range(100):
			if not trial.moving:break
			trial.physics(.08);await physics_frame
		expect(error.is_empty() and trial.blocked_reason.is_empty() and is_zero_approx(trial.path),"Return recovers blocked load while obstacle remains in place")
		blocker.free();await frames(2)
		trial.request("advance");trial.physics(.25)
		var moving_path: float = trial.path
		var moving_goal: float = trial.goal
		expect(not trial.request("return").is_empty() and trial.moving and is_equal_approx(trial.path,moving_path) and is_equal_approx(trial.goal,moving_goal) and trial.status_text().begins_with("MOVING"),"Rejected direction change preserves active motion and does not falsely label it stopped")
		game.set_paused(true)
		var held: float = trial.path
		trial.physics(10)
		expect(is_equal_approx(held,trial.path) and game.model.support_occupant("m1_leg_rail") == "left_leg","Pause freezes supported motion without save side effects")
		game.set_paused(false);trial.request("stop");trial.request("return")
		for tick in range(100):
			if not trial.moving:break
			trial.physics(.08);await physics_frame
	print("M1_METRICS floor=",min_floor," motion_samples=",total_motion_samples," safety_steps=",trial.checked_steps)
	var passed = checks.all(func(check):return check.passed)
	FileAccess.open("/tmp/m1-blockout.audit.json",FileAccess.WRITE).store_string(JSON.stringify({"passed":passed,"checks":checks,"min_floor":min_floor,"min_fixture_floor":fixture_floor,"samples":total_motion_samples,"rendered":false},"  "))
	game.free()
	await process_frame
	print("M1_BLOCKOUT ","PASS" if passed else "FAIL"," ",checks.size()," checks")
	quit(0 if passed else 1)

func check_sample() -> void:
	total_motion_samples += 1
	for piece in trial.mesh_bounds:
		var bounds: AABB = piece.node.global_transform*piece.bounds
		min_floor = minf(min_floor,bounds.position.y)

	var sample = trial.rail_pose(trial.path)
	for piece in game.leg_layout.motion_geometry(sample.load,sample.z,sample.x):
		var visual: MeshInstance3D = piece.visual
		preview_matches = preview_matches and piece.pose.origin.distance_to(visual.global_position)<.0002 and piece.pose.basis.is_equal_approx(visual.global_basis.orthonormalized()) and piece.shape.size.distance_to(visual.mesh.size*visual.scale)<.0002
		var bounds: AABB = visual.global_transform*visual.mesh.get_aabb()
		fixture_floor = minf(fixture_floor,bounds.position.y)
