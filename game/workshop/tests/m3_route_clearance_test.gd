extends "res://tests/kit/m3_journey.gd"
## Bounded real-input clearance probe. Completed construction/player start are
## disclosed fixtures; movement and held two-hand ring use ordinary controls.
func run() -> void:
	await boot_m3()
	var seated: Dictionary = game.model.install_supported("left_leg","foot","foot","foot_carrier")
	expect(seated.ok,"Disclosed route fixture seats the supplied foot")
	game.runtime.mount("left_leg","foot","foot")
	Staging.fill(game,"left_leg")
	var carrier = game.equipment.get_equipment("foot_carrier")
	carrier.path = 2;carrier.goal = 2;carrier.withdrawal = 1;carrier._pose()
	game.equipment.get_equipment("service_crane")._refresh()
	expect(game.model.milestone("left_leg","structural_ready"),"Disclosed route fixture supplies complete horizontal leg")
	# Start at the clear west cross aisle, then acquire an actual retaining half.
	driver.stage_pose("route probe begins outside stock",Vector3(3.2,.03,22.5))
	await frames(5)
	var uid = "PV-120__001"
	expect(game.model.carry_item(uid).is_empty(),"Disclosed payload fixture takes original two-hand ring identity")
	game.components.hold_at(uid,game.camera.global_transform*Transform3D(Basis.IDENTITY,Vector3(0,0,-.7)))
	await frames(5)
	var passed = true
	for point in [Vector3(6.85,0,22.5),Vector3(6.85,0,20.5),Vector3(10.5,0,20.5),Vector3(6.85,0,20.5),Vector3(6.85,0,22.5),Vector3(3.2,0,22.5)]:
		if not await walk(point,"two-hand clear cross aisle "+str(point)):passed = false;break
	if passed:
		for point in [Vector3(6.85,0,22.5),Vector3(6.85,0,21.7),Vector3(9.6,0,21.7),Vector3(9.6,0,24.3)]:
			if not await walk(point,"two-hand ramp boarding "+str(point)):passed = false;break
	if passed:
		expect(absf(game.player.global_position.y-.15)<.08,"Actual two-hand payload boards lift through its shallow front ramp")
		for point in [Vector3(9.6,0,21.7),Vector3(6.85,0,21.7),Vector3(6.85,0,22.5),Vector3(3.2,0,22.5)]:
			if not await walk(point,"two-hand ramp return "+str(point)):passed = false;break
	expect(game.model.held_item()==uid and is_instance_valid(game.components.held_body),"Same real retaining half remains carried throughout both route directions")
	passed = passed and checks.all(func(check):return check.passed)
	write_evidence("res://verification/m3-route-clearance.json",{"passed":passed,"checks":checks,"routes":travelled,"rendered":false,"fixture":"Complete leg installed by model fixture; start at west cross aisle with original ring identity. All subsequent movement uses ordinary desktop input."})
	game.free()
	print("M3_ROUTE_CLEARANCE ","PASS" if passed else "FAIL"," ",checks.size()," checks")
	quit(0 if passed else 1)
