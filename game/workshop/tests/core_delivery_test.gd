extends "res://tests/kit/m3_section.gd"
## Supplied rigging and fastening fixture; no walking/aim/access automation.
func run() -> void:
	if not await start("core"):finish();return
	expect(await deliver_core(),"detailed section completes")
	finish()

func end_state(crane: Node, point: String, state: String) -> void:
	var saved: Dictionary=crane.capture()
	var id: String=crane.END_IDS[crane.POINT_IDS.find(point)]
	saved.endpoints[id]={"state":state,"point":point if state=="attached" else ""}
	crane.apply(saved)

func deliver_core() -> bool:
	var fixture=game.equipment.get_equipment("module_supports")
	var crane=game.equipment.get_equipment("service_crane")
	var guide=game.equipment.get_equipment("core_guide")
	if not command(fixture,"template:core"):return false
	if not command(crane,"task:core_store") or not command(crane,"go:source") or not command(crane,"down"):return false
	supply_rig(crane,true)
	if not command(crane,"up") or not command(crane,"go:receiver") or not command(crane,"down"):return false
	expect(game.model.assemblies.core.location=="support:bulky_fixture","same prepared core reaches matched saddles")
	# Clearing the shared fixture is independent of the downstream build order.
	# Reacquire while both ends are still fitted, then return the same core to stock.
	expect(crane.request("up").is_empty(),"occupied fixture permits supported return to storage")
	crane.physics(.3);crane.request("stop")
	expect(fixture.source_release>0 and fixture.source_release<1,"receiving clamps open only after crane takes weight for return")
	if not command(crane,"resume") or not command(crane,"go:source") or not command(crane,"down"):return false
	expect(game.model.assemblies.core.location=="support:core_store","shared fixture can clear back to the original storage support")
	if not command(crane,"up") or not command(crane,"go:receiver") or not command(crane,"down"):return false
	supply_rig(crane,false)
	if not command(crane,"up") or not command(crane,"go:park"):return false
	if not command(crane,"task:core") or not command(crane,"go:source") or not command(crane,"down"):return false
	supply_rig(crane,true)
	if not command(crane,"up"):return false
	expect(crane.request("go:receiver").is_empty(),"rear core route starts through outboard bypass")
	crane.physics(2.5);crane.request("stop")
	if not command(crane,"resume") or not command(crane,"down"):return false
	expect(guide.active and guide.travel==0 and game.model.assemblies.core.location=="support:m2_service_crane","rear approach retains both-ended crane ownership")
	expect(not guide.rig_error("detach","core_front").is_empty(),"forward bridge cannot release before capture")
	if not command(guide,"advance"):return false
	expect(is_equal_approx(guide.travel,.85) and game.model.assemblies.core.location=="support:core_guide","captured guides take forward support at the authored stop")
	expect(not guide.request("advance").is_empty(),"forward bridge blocks further insertion")
	expect(guide.rig_error("detach","core_front").is_empty() and not guide.rig_error("detach","core_aft").is_empty(),"capture permits only the forward handoff")
	end_state(crane,"core_front","held")
	expect(not guide.request("advance").is_empty(),"held bridge must be stowed before further insertion")
	expect(crane.request("stow").is_empty(),"forward bridge stows using normal crane hand action")
	guide.request("advance");guide.physics(1);guide.request("stop")
	expect(guide.rig>0 and guide.rig<1 and is_equal_approx(guide.travel,.85),"spreader folds above aft support before deep insertion")
	guide.request("advance");guide.physics(2);guide.physics(1);guide.request("stop")
	if not command(guide,"advance"):return false
	expect(game.model.assemblies.core.parent=="chest","flange seating mounts the same core into the already mounted chest")
	expect(not guide.request("connection").is_empty(),"rear connection requires four captive bolts")
	for i in range(4):
		if not command(guide,"bolt:"+str(i)):return false
	expect(not guide.rig_error("detach","core_aft").is_empty(),"retained core still needs rear interlock before release")
	if not command(guide,"connection"):return false
	end_state(crane,"core_aft","stowed")
	if not command(crane,"up") or not command(crane,"go:park"):return false
	expect(not guide.request("bolt:0").is_empty(),"connected core refuses retention undo")
	if not command(guide,"isolation"):return false
	if not command(crane,"go:receiver") or not command(crane,"down"):return false
	end_state(crane,"core_aft","attached")
	for i in range(4):
		if not command(guide,"bolt:"+str(i)):return false
	if not command(guide,"return"):return false
	expect(is_equal_approx(guide.travel,.85),"local correction stops at capture before losing forward support")
	if not command(guide,"return"):return false
	expect(guide.rig==0 and is_equal_approx(guide.travel,.85),"forward rig extends at capture before bridge reacquisition")
	expect(not guide.request("return").is_empty(),"guide exit requires forward bridge reacquisition")
	end_state(crane,"core_front","attached")
	guide.request("return");guide.physics(1);guide.request("stop")
	if not command(guide,"return"):return false
	expect(game.model.assemblies.core.location=="support:m2_service_crane","both ends own the returned core outside the guides")
	# Repeat only the short supported insertion, preserving all physical stock.
	if not command(guide,"advance"):return false
	end_state(crane,"core_front","stowed")
	if not command(guide,"advance"):return false
	for i in range(4):
		if not command(guide,"bolt:"+str(i)):return false
	if not command(guide,"connection"):return false
	end_state(crane,"core_aft","stowed")
	if not command(crane,"up") or not command(crane,"go:park"):return false
	expect(game.model.integrity_errors().is_empty(),"core correction conserves every assembly and stock identity")
	return true

func finish() -> void:
	var passed=checks.all(func(check):return check.passed)
	write_evidence("res://verification/core-delivery.json",{"scope":"mechanical rear route / captured handoff / captive retention / local correction; no walking or access review","checks":checks})
	print("CORE_DELIVERY ","PASS " if passed else "FAIL ",checks.size()," checks")
	game.free();quit(0 if passed else 1)
