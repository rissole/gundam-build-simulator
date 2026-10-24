extends "res://tests/core_delivery_test.gd"
## Supplied rigging/fastening fixture. Actual equipment transitions and disk
## restoration are exercised; the user owns walking and connection access.
func after_legs() -> bool:
	if not await deliver_chest() or not await deliver_core():return false
	return await deliver_backpack()

func fit_backpack(ids: Array) -> void:
	for sid in ids:
		expect(game.equipment.placement_error("chest",sid).is_empty(),"backpack connection permits current supported state: "+sid+" "+game.equipment.placement_error("chest",sid))
		Staging.fill(game,"chest",[sid])

func deliver_backpack() -> bool:
	var fixture=game.equipment.get_equipment("module_supports")
	var crane=game.equipment.get_equipment("service_crane")
	var pack=game.equipment.get_equipment("backpack_hinge")
	if not command(fixture,"template:backpack"):return false
	if not command(crane,"task:backpack_store") or not command(crane,"go:source") or not command(crane,"down"):return false
	supply_rig(crane,true)
	if not command(crane,"up") or not command(crane,"go:receiver") or not command(crane,"down"):return false
	supply_rig(crane,false)
	if not command(crane,"up") or not command(crane,"go:park"):return false
	if not command(crane,"task:backpack") or not command(crane,"go:source") or not command(crane,"down"):return false
	supply_rig(crane,true)
	if not command(crane,"up"):return false
	crane.request("go:receiver");crane.physics(2.5);crane.request("stop")
	if not await reopen("backpack low bypass and lifting well"):return false
	crane=game.equipment.get_equipment("service_crane");pack=game.equipment.get_equipment("backpack_hinge")
	if not command(crane,"resume") or not command(crane,"down"):return false
	expect(pack.active and game.model.assemblies.backpack.parent=="chest" and pack.tension==1,"crane seats the same open backpack while retaining its full weight")
	expect(not pack.rig_error("detach","backpack_left").is_empty(),"unretained hinges cannot release crane support")
	expect(not pack.request("strut:0").is_empty(),"struts cannot deploy before both hinge pin/keeper pairs")
	game.model.transfer("bp-hinge-pin","bin","pocket","BP-P60__002")
	expect(game.model.install("chest","backpack/hinge_pin_1","BP-P60__002").ok,"interchangeable hinge pin keeps its identity at the opposite bracket")
	expect(not game.model.placement_error("chest","backpack/hinge_pin_2","BP-P40__001").is_empty(),"40 mm strut pin cannot replace a 60 mm hinge pin")
	fit_backpack(pack.spec.hinge_slots.filter(func(sid):return sid!="backpack/hinge_pin_1"))
	expect(not game.equipment.placement_error("chest","backpack/strut_pin_1").is_empty(),"strut base pin needs the actual deployed eye")
	pack.request("strut:0");pack.physics(1);pack.request("stop")
	expect(pack.struts[0]>0 and pack.struts[0]<1,"prepared telescope moves continuously from its stowed position")
	if not await reopen("backpack strut deployment"):return false
	crane=game.equipment.get_equipment("service_crane");pack=game.equipment.get_equipment("backpack_hinge")
	if not command(pack,"resume") or not command(pack,"strut:1"):return false
	fit_backpack(pack.spec.strut_slots)
	expect(not pack.rig_error("detach","backpack_left").is_empty(),"pins alone do not establish positive open support")
	if not command(pack,"lock:0") or not command(pack,"lock:1"):return false
	expect(pack.retained(),"both positive locks establish independent open support")
	expect(not game.equipment.placement_error("chest","backpack/service_1").is_empty(),"services require the rig released and stowed")
	supply_rig(crane,false)
	if not command(crane,"up") or not command(crane,"go:park"):return false
	fit_backpack(pack.spec.service_slots)
	if not await reopen("backpack locked open and serviced"):return false
	crane=game.equipment.get_equipment("service_crane");pack=game.equipment.get_equipment("backpack_hinge")
	expect(not pack.request("lock:0").is_empty(),"open lock cannot release before crane reacquisition")
	if not command(crane,"go:receiver") or not command(crane,"down"):return false
	supply_rig(crane,true)
	expect(not pack.request("lock:0").is_empty(),"attached ends must take weight before releasing locks")
	expect(crane.request("guide:take_weight").is_empty(),"existing crane console requests backpack load transfer")
	pack.physics(.5);pack.request("stop")
	expect(pack.tension>0 and pack.tension<1,"weight reacquisition is an interrupted explicit phase")
	if not await reopen("backpack crane takes closure weight"):return false
	crane=game.equipment.get_equipment("service_crane");pack=game.equipment.get_equipment("backpack_hinge")
	if not command(pack,"resume"):return false
	if not command(pack,"lock:0") or not command(pack,"lock:1"):return false
	expect(crane.request("guide:close").is_empty(),"shared crane begins supported closure")
	pack.physics(2);pack.request("stop")
	expect(pack.angle>0 and pack.angle<1,"closure preserves a continuous intermediate hinge angle")
	for uid in pack.source_cols:
		expect(pack.source_nodes[uid].global_transform.is_equal_approx(pack.source_cols[uid].global_transform),"articulated source mesh and collision agree between input and physics ticks: "+uid)
	if not await reopen("backpack partly closed with services"):return false
	crane=game.equipment.get_equipment("service_crane");pack=game.equipment.get_equipment("backpack_hinge")
	expect(game.runtime.node("backpack").global_transform.is_equal_approx(pack.load_pose()),"mounted backpack restores its exact articulated parent pose")
	if not command(pack,"resume"):return false
	expect(not pack.rig_error("detach","backpack_left").is_empty(),"closed locator contact still needs both lower latches")
	if not command(pack,"latch:0") or not command(pack,"latch:1"):return false
	supply_rig(crane,false)
	if not command(crane,"up") or not command(crane,"go:park"):return false
	if not command(pack,"cover:0") or not command(pack,"cover:1"):return false
	if not await reopen("backpack closed latched and covered"):return false
	crane=game.equipment.get_equipment("service_crane");pack=game.equipment.get_equipment("backpack_hinge")
	expect(not pack.request("latch:0").is_empty(),"latched backpack cannot reopen without the crane")
	# Local supported correction: reopen, isolate both service runs, undo and
	# refit one strut keeper, preserving its physical identity, then close again.
	if not command(pack,"cover:0") or not command(pack,"cover:1"):return false
	if not command(crane,"go:receiver") or not command(crane,"down"):return false
	supply_rig(crane,true)
	if not command(pack,"take_weight") or not command(pack,"latch:0") or not command(pack,"latch:1") or not command(pack,"open"):return false
	if not command(pack,"lock:0") or not command(pack,"lock:1"):return false
	supply_rig(crane,false)
	for i in range(2):
		expect(not game.equipment.undo("chest").handled,"independently locked open backpack permits service removal")
		expect(game.model.undo("chest").ok,"same service identity returns for correction")
	game.components.sync("chest")
	supply_rig(crane,true)
	if not command(pack,"take_weight") or not command(pack,"lock:0") or not command(pack,"lock:1"):return false
	var keeper: String=game.model.assemblies.chest.slots["backpack/strut_keeper_2"]
	expect(not game.equipment.undo("chest").handled,"reacquired crane permits strut keeper correction")
	expect(game.model.undo("chest").ok,"strut keeper returns without detaching the backpack")
	game.components.sync("chest");fit_backpack(["backpack/strut_keeper_2"])
	expect(game.model.assemblies.chest.slots["backpack/strut_keeper_2"]==keeper,"keeper correction reinstalls the same physical identity")
	if not command(pack,"lock:0") or not command(pack,"lock:1"):return false
	supply_rig(crane,false);fit_backpack(pack.spec.service_slots);supply_rig(crane,true)
	if not command(pack,"take_weight") or not command(pack,"lock:0") or not command(pack,"lock:1") or not command(pack,"close"):return false
	if not command(pack,"latch:0") or not command(pack,"latch:1"):return false
	supply_rig(crane,false)
	if not command(crane,"up") or not command(crane,"go:park"):return false
	if not command(pack,"cover:0") or not command(pack,"cover:1"):return false
	expect(game.model.integrity_errors().is_empty(),"backpack mounting and local correction conserve every stock and assembly identity")
	return await reopen("backpack corrected and completed")

func finish() -> void:
	var passed=checks.all(func(check):return check.passed)
	write_evidence("res://verification/backpack-delivery.json",{"scope":"mechanical delivery, retention, services, crane-assisted closure, local correction and interrupted saves; no walking/access review","checks":checks})
	print("BACKPACK_DELIVERY ","PASS " if passed else "FAIL ",checks.size()," checks")
	game.free();quit(0 if passed else 1)
