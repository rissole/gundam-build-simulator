extends "res://tests/kit/m3_journey.gd"
## Physical access regression. Build/rider setup is a disclosed model fixture;
## the final local walk, pocket choices, aim and fitting use desktop controls.
func clear_ray(eye: Vector3, point: Vector3) -> bool:
	if eye.distance_to(point)>game.REACH:return false
	var ray = PhysicsRayQueryParameters3D.create(eye,point,game.WORLD_MASK);ray.exclude = [game.player.get_rid()]
	var hit = game.get_world_3d().direct_space_state.intersect_ray(ray)
	return hit.is_empty() or hit.position.distance_to(point)<.025 or hit.collider==game.runtime.node("pelvis") and hit.position.distance_to(point)<.065

func run() -> void:
	await boot_m3()
	var result: Dictionary = game.model.install_supported("left_leg","foot","foot","foot_carrier")
	expect(result.ok,"Disclosed hip fixture seats prepared foot")
	game.runtime.mount("left_leg","foot","foot");Staging.fill(game,"left_leg")
	var carrier = game.equipment.get_equipment("foot_carrier")
	carrier.path = 2;carrier.goal = 2;carrier.withdrawal = 1;carrier._pose()
	var rail = game.equipment.get_equipment("leg_rail")
	rail.path = 3;rail.goal = 3;rail._pose()
	result = game.model.install_supported("pelvis","left_leg","left_leg","m2_leg_rail")
	expect(result.ok,"Disclosed hip fixture docks completed leg")
	game.runtime.mount("pelvis","left_leg","left_leg")
	Staging.fill(game,"pelvis",["ring_1","ring_2","ring/washer_3","ring/bolt_3","ring/washer_4","ring/bolt_4"])
	game.equipment.get_equipment("service_crane")._refresh()
	for kind in ["lg-w24","pv-m24-140"]:expect(game.model.stock_pocket(kind).ok,"Disclosed hip fixture supplies remaining "+kind)
	var lift = game.equipment.get_equipment("hip_lift")
	lift.height = lift.stops[-1];lift.destination = lift.height;lift._pose();await frames(3)
	var slots = ["ring/washer_1","ring/bolt_1","ring/washer_2","ring/bolt_2"]
	var patch: Array = []
	# Nine different normal standing positions, spanning a usable work patch.
	for x in [10.3,10.4,10.5]:
		for z in [25.3,25.4,25.5]:
			var eye = Vector3(x,lift.height+1.62,z)
			var clear: bool = slots.all(func(sid):return clear_ray(eye,game.components.slot_point("pelvis",sid)))
			expect(clear,"All four far fasteners have real sightline and reach from standing patch "+str(Vector2(x,z)))
			patch.append({"feet":[x,lift.height,z],"clear":clear})
	driver.stage_pose("disclosed rider starts at raised deck center",Vector3(lift.position.x,lift.height,lift.position.z))
	await frames(5)
	if await walk(Vector3(10.4,lift.height,25.4),"ordinary standing hip work patch"):
		for sid in slots:
			if not await install_slot("pelvis",sid):break
	expect(game.model.milestone("pelvis","left_leg_secured"),"Ordinary fitting from usable guarded-deck patch completes both halves and all four pairs")
	var passed = checks.all(func(check):return check.passed)
	write_evidence("res://verification/m3-hip-access.json",{"passed":passed,"checks":checks,"patch":patch,"rendered":false,"fixture":"Completed leg and seated halves supplied by model fixture; rider starts at raised lift center. Final local walk/aim/pocket choice/fit are actual desktop input."})
	game.free();print("M3_HIP_ACCESS ","PASS" if passed else "FAIL"," ",checks.size()," checks");quit(0 if passed else 1)
