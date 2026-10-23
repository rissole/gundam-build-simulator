extends "res://tests/m2_retention_controls_test.gd"
func run() -> void:
	await loop()
	game.free();await process_frame
	for label in snapshots:
		game = load("res://scenes/workshop.tscn").instantiate();game.profile_override = "leg_bay_retention";root.add_child(game);game.automated_test = true
		var codec = game.saves
		var saved: Dictionary = snapshots[label]
		expect(codec.validate(saved).is_empty(),"Fresh scene accepts "+label)
		expect(codec.apply_snapshot(saved) and game.paused,"Fresh scene restores "+label+" paused")
		expect(JSON.stringify(codec.capture().model) == JSON.stringify(saved.model),"Fresh restore preserves identities/history at "+label)
		expect(codec.validate(codec.capture()).is_empty(),"Restored world validates at "+label)
		var nested = true
		for owner in game.model.assemblies:
			var a: Dictionary = game.model.assemblies[owner]
			if not a.parent.is_empty():nested = nested and game.assembly_node(owner).get_parent() == game.assembly_node(a.parent) and game.assembly_node(owner).global_transform.is_equal_approx(game.runtime.mount_pose(a.parent,a.parent_slot,owner))
		expect(nested,"Fresh restore rebuilds exact nested scene ownership at "+label)
		for tick in range(3):
			await frames(1)
			for member in game.runtime.descendants("left_leg"):
				var body: CollisionObject3D = game.runtime.node(member)
				var physics_pose: Transform3D = PhysicsServer3D.body_get_state(body.get_rid(),PhysicsServer3D.BODY_STATE_TRANSFORM)
				if not body.global_transform.is_equal_approx(physics_pose):print("M2_PHYSICS_MISMATCH ",label," ",member," scene=",body.global_transform," physics=",physics_pose)
				expect(body.global_transform.is_equal_approx(physics_pose),"Restored descendant physics matches "+member+" at "+label+" tick "+str(tick))
		var original: Dictionary = codec.capture()
		var mutations: Array[Dictionary] = []
		var bad = original.duplicate(true);bad.world.m2.rail.erase("parent");mutations.append(bad)
		bad = original.duplicate(true);bad.world.m2.rail.path = 4;mutations.append(bad)
		bad = original.duplicate(true);bad.world.m2.shelf.occupants = ["PV-120__001","PV-120__001"];mutations.append(bad)
		bad = original.duplicate(true);bad.world.m2.shelf.occupants = ["invented",""];mutations.append(bad)
		bad = original.duplicate(true);bad.world.m2.shelf.version = 0;mutations.append(bad)
		bad = original.duplicate(true);bad.world.access_lifts.hip.destination = 3;mutations.append(bad)
		bad = original.duplicate(true);bad.world.fixtures.left_leg[10] += .4;mutations.append(bad)
		for index in range(mutations.size()):
			var before = JSON.stringify(codec.capture())
			expect(not codec.validate(mutations[index]).is_empty() and not codec.apply_snapshot(mutations[index]),"Reject malformed snapshot "+label+" / "+str(index))
			expect(JSON.stringify(codec.capture()) == before,"Malformed snapshot causes zero live mutation "+label+" / "+str(index))
		if label == "lift_moving":
			var lift = game.access_lifts.hip
			var height: float = lift.height
			await frames(5)
			expect(lift.moving and is_equal_approx(lift.height,height),"Paused restore holds moving lift progress")
			game.set_paused(false);await frames(20)
			expect(lift.height > height and absf(game.player.global_position.y-lift.global_position.y-lift.height)<.06,"Restored rider follows the resumed moving lift")
		game.free();await process_frame
	game = load("res://scenes/workshop.tscn").instantiate();game.profile_override = "leg_bay_retention";root.add_child(game);game.automated_test = true
	var path = "/tmp/m2-retention-store-"+str(Time.get_ticks_usec())+".json"
	game.saves.setup(game,path,false)
	var applied: bool = game.saves.apply_snapshot(snapshots.partial_hardware)
	var written: bool = game.saves.save_now() if applied else false
	if not applied or not written:print("M2_STORE_FAILURE applied=",applied," written=",written," errors=",game.saves.validate(snapshots.partial_hardware)," status=",game.saves.status_text())
	expect(applied and written,"M2 codec saves a partially fastened real snapshot to its own temporary slot")
	var stored: Dictionary = Store.read(path,game.saves.fingerprint)
	expect(stored.ok,"Stored M2 envelope and fingerprint verify")
	game.free();await process_frame
	game = load("res://scenes/workshop.tscn").instantiate();game.profile_override = "leg_bay_retention";root.add_child(game);game.automated_test = true
	game.saves.setup(game,path,false)
	expect(game.saves.restored and game.paused and game.model.assemblies.pelvis.slots["ring/washer_3"] != "","Fresh M2 session resumes partial hardware from real store while paused")
	game.free();await process_frame
	var passed = checks.all(func(check):return check.passed)
	FileAccess.open("/tmp/m2-retention-save.audit.json",FileAccess.WRITE).store_string(JSON.stringify({"passed":passed,"checks":checks,"states":snapshots.keys()},"  "))
	print("M2_RETENTION_SAVE ","PASS" if passed else "FAIL"," ",checks.size()," checks")
	quit(0 if passed else 1)
