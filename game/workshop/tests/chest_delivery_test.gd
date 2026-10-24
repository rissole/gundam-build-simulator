extends "res://tests/kit/stage_section.gd"
## Mechanical/model fixture only. The user owns walking and connection access.
func run() -> void:
	if not await start("chest"):finish();return
	expect(await deliver_chest(),"detailed section completes")
	finish()

func deliver_chest() -> bool:
	var fixture=game.equipment.get_equipment("module_supports")
	var crane=game.equipment.get_equipment("service_crane")
	if not command(fixture,"template:chest"):return false
	if not command(crane,"task:chest_store") or not command(crane,"go:source") or not command(crane,"down"):return false
	supply_rig(crane,true)
	if not command(crane,"up") or not command(crane,"go:receiver"):return false
	crane.request("down");crane.physics(4.7);crane.request("stop")
	var pelvis_body: AnimatableBody3D=game.assembly_node("pelvis")
	var pelvis_physics: Transform3D=PhysicsServer3D.body_get_state(pelvis_body.get_rid(),PhysicsServer3D.BODY_STATE_TRANSFORM)
	print("PELVIS_AT_CHEST node=",pelvis_body.global_position," physics=",pelvis_physics.origin)
	expect(fixture.source_release>0 and fixture.source_release<1,"fixture clamps close after chest seat contact")
	if not command(crane,"resume"):return false
	expect(game.model.assemblies.chest.location=="support:bulky_fixture" and fixture.support_secured("chest"),"same physical chest transfers to closed fixture")
	supply_rig(crane,false)
	if not command(crane,"up") or not command(crane,"go:park"):return false
	expect(not fixture.request("template:pelvis").is_empty(),"occupied chest prevents insert exchange")
	fixture.request("advance");fixture.physics(1);fixture.request("stop")
	if not command(fixture,"return"):return false
	if not command(crane,"task:chest") or not command(crane,"go:source") or not command(crane,"down"):return false
	supply_rig(crane,true)
	if not command(crane,"up"):return false
	var traverse_error: String=crane.request("go:receiver")
	expect(traverse_error.is_empty(),"loaded chest traverse accepted: "+traverse_error)
	if not traverse_error.is_empty():return false
	crane.physics(2);crane.request("stop")
	if not command(crane,"resume") or not command(crane,"down"):return false
	expect(game.model.assemblies.chest.parent=="pelvis","waist seat mounts the existing chest hierarchy")
	expect(not crane.secured() and crane.action_error("detach:"+crane.END_IDS[0]).contains("retaining"),"seating alone cannot release the four lifting shoes")
	var washers: Array=game.runtime.definition("pelvis").milestones.chest_secured.filter(func(sid):return sid!="chest")
	game.model.transfer("ch-w36","bin","pocket","CH-W36__004")
	expect(game.model.install("pelvis","chest/washer_1","CH-W36__004").ok,"interchangeable fourth washer fits first waist corner")
	expect(not game.model.placement_error("pelvis","chest/washer_2","CH-H36160__001").is_empty(),"bolt cannot replace washer")
	Staging.fill(game,"pelvis",washers)
	expect(crane.secured(),"four separate washer and bolt pairs secure the chest")
	expect(not game.components.placement_error("pelvis","chest/service_1","CH-SERVICE__001").is_empty(),"rigging remains an explicit service-connection interlock")
	supply_rig(crane,false)
	if not command(crane,"up") or not command(crane,"go:park"):return false
	Staging.fill(game,"pelvis",["chest/service_1","chest/service_2"])
	expect(game.model.milestone("pelvis","chest_connected") and game.model.integrity_errors().is_empty(),"retained and serviced chest preserves unique ownership")
	# Undo the two service plugs through the normal history, then reacquire the
	# same four-ended crane before touching any structural retention.
	for i in range(2):
		expect(not game.equipment.undo("pelvis").handled,"chest service undo is independent of leg-holder retention")
		expect(game.model.undo("pelvis").ok,"service plug returns to inventory for local correction")
	game.components.sync("pelvis")
	if not command(crane,"task:shin"):return false
	expect(game.equipment.undo("pelvis").handled,"wrong crane task cannot bypass chest retention support")
	if not command(crane,"task:chest") or not command(crane,"go:receiver") or not command(crane,"down"):return false
	supply_rig(crane,true)
	for i in range(8):
		expect(not game.equipment.undo("pelvis").handled,"reacquired chest permits one retention undo")
		expect(game.model.undo("pelvis").ok,"same waist hardware returns to inventory")
	game.components.sync("pelvis")
	if not command(crane,"up"):return false
	expect(game.model.assemblies.chest.location=="support:crane_rigging" and game.model.assemblies.chest.parent.is_empty(),"supported correction removes only the chest from its parent")
	if not command(crane,"down"):return false
	Staging.fill(game,"pelvis",washers)
	supply_rig(crane,false)
	if not command(crane,"up") or not command(crane,"go:park"):return false
	Staging.fill(game,"pelvis",["chest/service_1","chest/service_2"])
	expect(game.model.integrity_errors().is_empty(),"correction and reinstall conserve every physical chest and hardware identity")
	return true

func finish() -> void:
	var passed=checks.all(func(check):return check.passed)
	write_evidence("res://verification/chest-delivery.json",{"scope":"mechanical source exchange / crane / waist hardware and services; no walking or access review","checks":checks})
	print("CHEST_DELIVERY ","PASS " if passed else "FAIL ",checks.size()," checks")
	game.free();quit(0 if passed else 1)
