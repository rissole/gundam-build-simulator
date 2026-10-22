extends "res://tests/save_resume_test.gd"
## Separate leg profile; temporary files only, using the real workshop projection.
func run() -> void:
	save_path = "/tmp/gundam-leg-save-%s-%s.json" % [OS.get_process_id(),Time.get_ticks_usec()]
	game = load("res://scenes/workshop.tscn").instantiate()
	game.leg_workshop = true
	game.automated_test = true
	root.add_child(game)
	await frames(6)
	expect(not game.saves.enabled and game.saves.path == Codec.LEG_SAVE_PATH,"Headless leg profile selects separate slot without writing user storage")
	game.saves.setup(game,save_path,false)
	valid(game.saves.capture(),"Initial expanded workshop validates all supported poses and stock")
	expect(game.saves.enabled and not game.saves.automatic,"Explicit isolated path enables leg persistence tests")
	var first: Dictionary = game.saves.capture()
	expect(first.world.has("leg_equipment") and first.world.has("access_lifts") and first.world.access_lifts.size() == game.access_lifts.size(),"Leg-only equipment and all access lifts are captured")
	var legacy = load("res://scenes/workshop.tscn").instantiate()
	legacy.automated_test = true
	root.add_child(legacy)
	expect(legacy.saves.path == Codec.SAVE_PATH and legacy.saves.fingerprint != game.saves.fingerprint,"Legacy foot save profile remains separate and incompatible")
	var old_fingerprint = JSON.stringify({"world":Codec.WORLD_VERSION,"definitions":legacy.model.definitions,"scenario":legacy.config,"supported":is_instance_valid(legacy.foot_fixture),"geometry":FileAccess.get_sha256("res://assets/foot-fa01.glb")}).sha256_text()
	expect(legacy.saves.fingerprint == old_fingerprint and not legacy.saves.capture().world.has("leg_equipment"),"Legacy fingerprint and snapshot shape remain unchanged")
	legacy.free()
	station("pad_1","prep")
	station("pad_2","prep2")
	station("pitch","prep3")
	expect(stage("pad_1",2) == 2 and stage("pad_2",1) == 1 and stage("pitch",3) == 3,"Independent unfinished foot children keep exact physical IDs")
	game.hud.open_manual("left_leg",1)
	game.hud.open_manual("pelvis",1)
	game.hud.open_manual("pitch",3)
	game.model.select_pocket(4)
	var partial: Dictionary = game.saves.capture()
	valid(partial,"Partial children and expanded reader context validate")
	expect(game.saves.save_now(),"Save partial expanded workshop to isolated profile")
	game.model.select_pocket(0)
	game.hud.open_manual("foot",0)
	expect(game.saves.reload_save() and game.saves.capture().model == partial.model,"Reload preserves all partial physical ownership and history")
	expect(game.hud.pages == partial.world.reader.pages and game.hud.manual_id == "pitch","Restore leg, pelvis and component manual pages independently")
	var clone = load("res://scenes/workshop.tscn").instantiate()
	clone.leg_workshop = true
	clone.automated_test = true
	root.add_child(clone)
	clone.saves.setup(clone,save_path,false)
	expect(clone.saves.restored and clone.saves.capture().model == partial.model,"Fresh leg scene automatically reconstructs the saved profile")
	clone.free()
	var lift = game.access_lifts.values()[0]
	game.player.global_position = lift.global_position+Vector3(0,lift.height+0.02,0)
	game.player.velocity = Vector3.ZERO
	game.set_paused(false)
	game.components.collect("lg-knee-bearing")
	game.components.held_body.global_position = game.player.global_position+Vector3(0,1.2,-0.8)
	await frames(20)
	expect(is_instance_valid(game.components.held_body) and not game.model.held_item().is_empty(),"Actual carried knee bearing accompanies lift rider")
	var lift_error: String = lift.request("up")
	if not lift_error.is_empty():
		print("LEG_SAVE_LIFT_DIAGNOSTIC ",lift_error)
		var query = PhysicsShapeQueryParameters3D.new()
		var box = BoxShape3D.new()
		box.size = Vector3(lift.deck_size.x-0.006,5.54,lift.deck_size.y-0.006)
		query.shape = box
		query.transform = Transform3D(Basis.IDENTITY,lift.global_position+Vector3(0,2.8,0))
		query.collision_mask = 15
		var excluded: Array[RID] = lift._hardware.duplicate()
		excluded.append(game.player.get_rid())
		query.exclude = excluded
		for hit in game.get_world_3d().direct_space_state.intersect_shape(query,8):
			print("LEG_SAVE_LIFT_OBSTACLE ",hit.collider.get_path()," ",hit.collider.global_position)
	expect(game.player.is_on_floor() and lift_error.is_empty(),"Real workshop rider starts powered access lift")
	await frames(40)
	game.set_paused(true)
	var rising: Dictionary = game.saves.capture()
	valid(rising,"Player aboard a moving access lift validates")
	expect(lift.moving and game.saves.save_now() and game.saves.reload_save(),"Save and reload intermediate access lift travel")
	expect(same_lift(lift.capture(),rising.world.access_lifts[lift.equipment_id]) and game.player.global_transform.is_equal_approx(Codec.to_pose(rising.world.player.pose)),"Restore lift current height, destination, gate and rider pose")
	clone = load("res://scenes/workshop.tscn").instantiate()
	clone.leg_workshop = true
	clone.automated_test = true
	root.add_child(clone)
	clone.saves.setup(clone,save_path,false)
	await frames(5)
	expect(clone.saves.restored and same_lift(clone.access_lifts[lift.equipment_id].capture(),rising.world.access_lifts[lift.equipment_id]) and absf(clone.player.global_position.y-Codec.to_pose(rising.world.player.pose).origin.y)<0.03,"Fresh scene restores paused moving lift without rider impulse")
	clone.set_paused(false)
	await frames(20)
	expect(absf(clone.player.global_position.y-clone.access_lifts[lift.equipment_id].height-clone.access_lifts[lift.equipment_id].global_position.y)<0.06,"Fresh-scene rider follows resumed moving platform")
	clone.free()
	await frames(5)
	expect(is_equal_approx(lift.height,rising.world.access_lifts[lift.equipment_id].height),"Reload holds restored lift motion while workshop is paused")
	game.set_paused(false)
	await frames(300)
	expect(not lift.moving and absf(game.player.global_position.y-lift.global_position.y-lift.height)<0.06,"Resuming restored lift carries rider through completion")
	game.components.drop(true)
	for id in game.access_lifts:
		if id == lift.equipment_id:continue
		var other = game.access_lifts[id]
		game.player.global_position = other.global_position+Vector3(0,other.height+0.02,0)
		game.player.velocity = Vector3.ZERO
		await frames(12)
		var error: String = other.request("up")
		expect(error.is_empty(),"Actual "+id+" access lift has a clear upward route")
		if not error.is_empty():
			print("LEG_SAVE_OTHER_LIFT_DIAGNOSTIC ",id," ",error)
			lift_obstacles(other)
		for tick in range(800):
			await frames(1)
			if not other.moving:break
		expect(not other.moving and other.height>0.2 and absf(game.player.global_position.y-other.global_position.y-other.height)<0.06,"Actual "+id+" lift carries rider through work-height travel")
	for platform in game.access_lifts.values():
		if platform.height < 0.2:continue
		var lower_error: String = platform.request("ground")
		expect(lower_error.is_empty(),"Lower access equipment before material transfer")
		for tick in range(900):
			await frames(1)
			if not platform.moving:break
	game.set_paused(true)
	var correct: Dictionary = game.saves.capture()
	var invalid = correct.duplicate(true)
	invalid.world.access_lifts[lift.equipment_id].height = INF
	expect(not game.saves.apply_snapshot(invalid) and game.saves.capture() == correct,"Nonfinite lift pose is rejected before direct-apply mutation")
	invalid = correct.duplicate(true)
	invalid.world.access_lifts[lift.equipment_id].destination = 2.37
	rejected_without_mutation(invalid,"Reject unconfigured lift destination transactionally")
	invalid = correct.duplicate(true)
	invalid.world.fixtures.left_leg[9] += 0.5
	rejected_without_mutation(invalid,"Reject forged supported leg pose transactionally")
	invalid = correct.duplicate(true)
	invalid.world.leg_equipment.operation = "teleport"
	rejected_without_mutation(invalid,"Reject forged equipment operation transactionally")
	await leg_stages()
	var passed: bool = checks.all(func(check):return check.passed)
	FileAccess.open("/tmp/leg-save.audit.json",FileAccess.WRITE).store_string(JSON.stringify({"passed":passed,"checks":checks,"rendered":false,"engine":Engine.get_version_info().string},"  "))
	for suffix in ["",".bak"]:DirAccess.remove_absolute(save_path+suffix)
	game.free()
	await process_frame
	print("LEG_SAVE_AUDIT ","PASS" if passed else "FAIL"," ",checks.size()," checks")
	quit(0 if passed else 1)

func lift_obstacles(platform: Node3D) -> void:
	var query = PhysicsShapeQueryParameters3D.new()
	var box = BoxShape3D.new()
	var high: float = platform._target("up")+1.77
	var low: float = platform.height-0.112
	box.size = Vector3(platform.deck_size.x-0.006,high-low,platform.deck_size.y-0.006)
	query.shape = box
	query.transform = Transform3D(Basis.IDENTITY,platform.global_position+Vector3(0,(high+low)/2,0))
	query.collision_mask = 15
	var excluded: Array[RID] = platform._hardware.duplicate()
	excluded.append(game.player.get_rid())
	query.exclude = excluded
	for hit in game.get_world_3d().direct_space_state.intersect_shape(query,8):
		print("LEG_SAVE_LIFT_OBSTACLE ",platform.equipment_id," ",hit.collider.get_path()," ",hit.collider.global_position)

func same_lift(actual: Dictionary, expected: Dictionary) -> bool:
	return is_equal_approx(float(actual.height),float(expected.height)) and is_equal_approx(float(actual.destination),float(expected.destination)) and actual.moving == expected.moving

func wait_equipment(controller: Node, limit: int = 8000) -> bool:
	for tick in range(limit):
		await frames(1)
		if not controller.moving:return true
		if not controller.blocked_reason.is_empty():
			print("LEG_SAVE_MOTION_BLOCKED ",controller.blocked_reason)
			return false
	return false

func powered(action: String) -> bool:
	game.set_paused(false)
	var error: String = game.leg_equipment.request(action)
	expect(error.is_empty(),"Start equipment action "+action)
	if not error.is_empty():
		print("LEG_SAVE_ACTION_DIAGNOSTIC ",error)
		return false
	var finished: bool = await wait_equipment(game.leg_equipment)
	expect(finished,"Complete equipment action "+action)
	return finished

func persist(label: String) -> bool:
	game.set_paused(true)
	var snapshot: Dictionary = game.saves.capture()
	valid(snapshot,label+" validates")
	var saved: bool = game.saves.save_now() and game.saves.reload_save()
	expect(saved,label+" saves and resumes")
	if not saved:
		print("LEG_SAVE_PERSIST_DIAGNOSTIC ",game.saves.message)
		return false
	expect(game.saves.capture().model == snapshot.model,label+" preserves physical IDs and undo history")
	return true

func fresh_stage(label: String) -> void:
	var snapshot: Dictionary = game.saves.capture()
	var clone = load("res://scenes/workshop.tscn").instantiate()
	clone.leg_workshop = true
	clone.automated_test = true
	root.add_child(clone)
	clone.saves.setup(clone,save_path,false)
	var ownership_ok: bool = clone.saves.restored and clone.saves.capture().model == snapshot.model
	for owner in clone.model.assemblies:
		var a: Dictionary = clone.model.assemblies[owner]
		if not a.parent.is_empty():ownership_ok = ownership_ok and clone.assembly_node(owner).get_parent() == clone.assembly_node(a.parent) and clone.assembly_node(owner).global_transform.is_equal_approx(clone.runtime.mount_pose(a.parent,a.parent_slot,owner))
	expect(ownership_ok,label+" reconstructs exact nested ownership in a fresh scene")
	var stock_ok = true
	for uid in clone.leg_equipment.stock_bodies:
		stock_ok = stock_ok and clone.leg_equipment.stock_bodies[uid].visible == (clone.model.items[uid].location != "installed")
	expect(stock_ok,label+" reconstructs supported source stock visibility")
	clone.free()

func leg_stages() -> void:
	game.player.global_position = Vector3(-8,0.03,6)
	game.player.velocity = Vector3.ZERO
	for owner in ["pad_1","pad_2","pitch"]:stage(owner,1000)
	for pair in [["pad_1","heel_1"],["pad_2","heel_2"],["pitch","pitch"]]:
		if pair[0] == "pitch":stage("foot",1000)
		expect(game.model.move_assembly(pair[0],"held").is_empty(),"Pick staged "+pair[0])
		var result: Dictionary = game.model.install("foot",pair[1],pair[0])
		expect(result.ok,"Mount staged foot child "+pair[0])
		if not result.ok:return
		game.runtime.mount("foot",pair[1],pair[0])
	stage("foot",1000)
	for owner in game.builds:
		game._activate(owner)
		game._sync_installed_visuals()
	game.components.sync("foot")
	game.refresh_assembly_collision("foot")
	game.set_paused(false)
	var error: String = game.foot_fixture.request("transfer")
	expect(error.is_empty(),"Dispatch completed foot on original supported carrier")
	if not error.is_empty():return
	await frames(25)
	if not await persist("Interrupted original foot carrier in leg profile"):return
	game.set_paused(false)
	expect(await wait_equipment(game.foot_fixture),"Original carrier completes after leg-profile resume")
	error = game.leg_equipment.request("seat_foot")
	expect(error.is_empty(),"Start foot transfer into structural leg")
	if not error.is_empty():
		print("LEG_SAVE_ACTION_DIAGNOSTIC ",error)
		return
	await frames(35)
	if not await persist("Interrupted foot-to-leg supported transfer"):return
	var correct: Dictionary = game.saves.capture()
	var invalid = correct.duplicate(true)
	invalid.world.leg_equipment.waypoints[-1][9] += 0.75
	rejected_without_mutation(invalid,"Reject forged powered movement destination transactionally")
	game.set_paused(false)
	expect(await wait_equipment(game.leg_equipment),"Foot transfer completes after restore")
	if not await persist("Foot nested into leg fixture"):return
	expect(game.foot.get_parent() == game.assembly_node("left_leg") and game.foot.global_transform.is_equal_approx(game.runtime.mount_pose("left_leg","foot","foot")),"Foot scene and physics ownership rebuild under leg")
	for uid in ["LG-100__001","LG-110__001","LG-120__001"]:
		if not await powered("install:"+uid):return
		stage("left_leg",1000)
	if not await persist("Structurally complete leg with nested foot"):return
	fresh_stage("Completed leg")
	if not await powered("pick_leg"):return
	game.set_paused(false)
	error = game.leg_equipment.request("transfer_leg")
	expect(error.is_empty(),"Start loaded leg hoist transfer")
	if not error.is_empty():
		print("LEG_SAVE_ACTION_DIAGNOSTIC ",error)
		return
	await frames(45)
	if not await persist("Interrupted loaded leg hoist transfer"):return
	game.set_paused(false)
	expect(await wait_equipment(game.leg_equipment),"Loaded hoist resumes through clear corridor")
	if not await powered("seat_leg"):return
	if not await persist("Leg seated into pelvis before hip retention"):return
	expect(game.assembly_node("left_leg").get_parent() == game.assembly_node("pelvis") and game.foot.get_parent() == game.assembly_node("left_leg"),"Parent-first restore reconstructs pelvis to leg to foot hierarchy")
	var rings: Array[String] = []
	for uid in game.leg_equipment.parts:
		if game.leg_equipment.parts[uid].owner == "pelvis":rings.append(uid)
	for uid in rings:
		if not await powered("install:"+uid):return
	expect(stage("pelvis",4) == 4,"Install half of hip retention hardware")
	if not await persist("Half-fastened hip retention stage"):return
	fresh_stage("Half-fastened hip")
	expect(not game.model.milestone("pelvis","left_leg_secured") and not game.leg_equipment.action_error("release_hoist").is_empty(),"Restored half-fastened hip retains its hoist release interlock")
	stage("pelvis",1000)
	if not await powered("stabilize"):return
	if not await powered("release_hoist"):return
	if not await persist("Retained stabilized leg with released hoist"):return
	expect(game.leg_equipment.released and not game.leg_equipment.assisting and game.model.integrity_errors().is_empty(),"Released loaded stage restores support flags and inventory integrity")
	if not await powered("reacquire_hoist"):return
	for index in range(8):
		var result: Dictionary = game.model.undo("pelvis")
		expect(result.ok,"Remove hip retention fastener with hoist reacquired")
		if not result.ok:return
	game.components.sync("pelvis")
	game.refresh_assembly_collision("pelvis")
	for index in range(2):
		game.set_paused(false)
		var result: Dictionary = game.leg_equipment.undo("pelvis")
		expect(result.get("ok",false),"Start supported retainer removal")
		if not result.get("ok",false):
			print("LEG_SAVE_UNDO_DIAGNOSTIC ",result)
			return
		await frames(25)
		if not await persist("Interrupted supported hip retainer removal"):return
		game.set_paused(false)
		expect(await wait_equipment(game.leg_equipment),"Removed retainer returns to source rack after restore")
	game.set_paused(false)
	var removal: Dictionary = game.leg_equipment.undo("pelvis")
	expect(removal.get("ok",false),"Start hoist-supported leg unseating")
	if not removal.get("ok",false):return
	await frames(12)
	if not await persist("Interrupted hoist-supported leg unseating"):return
	game.set_paused(false)
	expect(await wait_equipment(game.leg_equipment),"Unseated leg resumes to approach after restore")
	var error_return: String = game.leg_equipment.request("return_leg")
	expect(error_return.is_empty(),"Start loaded hoist return to leg fixture")
	if not error_return.is_empty():return
	await frames(45)
	if not await persist("Interrupted loaded return transfer"):return
	game.set_paused(false)
	expect(await wait_equipment(game.leg_equipment),"Loaded return resumes to engaged assembly fixture")
	if not await persist("Returned structural leg on assembly fixture"):return
	expect(game.leg_equipment.fixture_engaged and not game.leg_equipment.assisting and game.model.assemblies.left_leg.location == "support:leg_fixture","Returned support ownership and fixture engagement survive reload")
	fresh_stage("Returned structural leg")

