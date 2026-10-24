extends "res://tests/kit/stage_section.gd"
## The prepared major-section handoff uses machinery/model staging only.
func run() -> void:
	if not await start("pelvis"):finish();return
	expect(rail.can_construct() and is_equal_approx(game.assembly_node("left_leg").global_position.x,14),"empty cradle starts at shared X14 station")
	expect(not rail.request("advance").is_empty(),"incomplete structural leg cannot depart")
	var fixture=game.equipment.get_equipment("module_supports")
	expect(not fixture.request("template:chest").is_empty(),"occupied pelvis fixture refuses contact exchange")
	expect(not fixture.source_error().is_empty(),"unset waist pins reject source lifting")
	fixture.request("advance");fixture.physics(1);fixture.request("stop")
	expect(game.runtime.node("pelvis").global_position.y>1.25,"fixture height adjustment carries the existing pelvis")
	if not command(fixture,"return"):finish();return
	if not await deliver_pelvis():finish();return
	expect(not fixture.request("jaw:0").is_empty(),"gantry cannot open without four-end reacquisition")
	expect(not fixture.request("lock:yaw").is_empty(),"released crane cannot leave an unlocked waist at the gantry")
	finish()

func finish() -> void:
	var passed=checks.all(func(check):return check.passed)
	write_evidence("res://verification/pelvis-delivery.json",{"scope":"mechanical source fixture / four-end crane / gantry retention, no walking or access review","checks":checks})
	print("PELVIS_DELIVERY ","PASS " if passed else "FAIL ",checks.size()," checks")
	game.free();quit(0 if passed else 1)

func deliver_pelvis() -> bool:
	var fixture=game.equipment.get_equipment("module_supports")
	var crane=game.equipment.get_equipment("service_crane")
	expect(game.model.assemblies.pelvis.location=="support:bulky_fixture","pelvis starts as one prepared assembly on the bulky fixture")
	for key in ["yaw","lean"]:
		if not command(fixture,"lock:"+key):return false
	if not command(crane,"task:pelvis") or not command(crane,"go:source") or not command(crane,"down"):return false
	supply_rig(crane,true)
	if not crane.request("up").is_empty():return false
	crane.physics(.1);settle(game.equipment.get_equipment("workshop_access"));crane.physics(.3);crane.request("stop")
	expect(fixture.source_release>0 and fixture.source_release<1 and game.model.assemblies.pelvis.location=="support:bulky_fixture","four ends take weight while source clamps open before ownership changes")
	if not command(crane,"resume") or not command(crane,"go:receiver") or not command(crane,"down"):return false
	var access=game.equipment.get_equipment("workshop_access")
	expect(settle(access) and access.ready_for("work"),"upper work platforms restore after pelvis seating: "+access.blocked_reason)
	expect(game.model.assemblies.pelvis.location=="support:pelvis_gantry" and not fixture.support_secured(),"bearing contact seats pelvis without automatic hold-down retention")
	expect(crane.action_error("detach:"+crane.END_IDS[0]).contains("four"),"unclamped gantry rejects crane release")
	for index in range(4):
		if index==0:
			fixture.request("jaw:0");fixture.physics(.4);fixture.request("stop")
			if not command(fixture,"jaw:0"):return false
			continue
		if not command(fixture,"jaw:"+str(index)):return false
	expect(fixture.support_secured(),"four closed jaws and both waist pins secure the pelvis")
	supply_rig(crane,false)
	return command(crane,"up") and command(crane,"go:park")
