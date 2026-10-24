extends "res://tests/indexed_leg_rail_test.gd"
## The prepared major-section handoff uses machinery/model staging only.
func run() -> void:
	game=await boot_profile("leg_bay_m3");rail=game.equipment.get_equipment("leg_rail");carrier=game.equipment.get_equipment("foot_carrier")
	var fixture=game.equipment.get_equipment("module_supports")
	expect(game.saves.validate(game.saves.capture()).is_empty(),"fresh prepared pelvis session validates")
	expect(not fixture.source_error().is_empty(),"unset waist pins reject source lifting")
	fixture.request("advance");fixture.physics(1);fixture.request("stop")
	expect(game.runtime.node("pelvis").global_position.y>1.25,"fixture height adjustment carries the existing pelvis")
	if not await reopen("bulky height adjustment"):finish();return
	fixture=game.equipment.get_equipment("module_supports")
	if not command(fixture,"return"):finish();return
	if not await deliver_pelvis():finish();return
	fixture=game.equipment.get_equipment("module_supports")
	var unsupported: Dictionary=game.saves.capture();unsupported.world.equipment.module_supports.jaws[0]=1;unsupported.world.equipment.module_supports.jaw_goals[0]=1
	expect(not game.saves.validate(unsupported).is_empty(),"save rejects missing gantry retention after crane departure")
	var displaced: Dictionary=game.saves.capture();displaced.world.fixtures.pelvis[9]+=1
	expect(not game.saves.validate(displaced).is_empty(),"save rejects a pelvis pose outside its actual supported seat")
	expect(not fixture.request("jaw:0").is_empty(),"gantry cannot open without four-end reacquisition")
	expect(not fixture.request("lock:yaw").is_empty(),"released crane cannot leave an unlocked waist at the gantry")
	finish()

func finish() -> void:
	var passed=checks.all(func(check):return check.passed)
	write_evidence("res://verification/pelvis-delivery.json",{"scope":"mechanical source fixture / four-end crane / gantry retention, no walking or access review","checks":checks})
	print("PELVIS_DELIVERY ","PASS " if passed else "FAIL ",checks.size()," checks")
	game.free();quit(0 if passed else 1)
