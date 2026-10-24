extends "res://tests/kit/m3_section.gd"
## Mechanical source exchange only; the installation/closure controller follows
## the full geometry preflight. No player walking, aim or access automation.
func run() -> void:
	if not await start("backpack"):finish();return
	expect(await exchange_backpack(),"detailed section completes")
	finish()

func exchange_backpack() -> bool:
	var fixture=game.equipment.get_equipment("module_supports")
	var crane=game.equipment.get_equipment("service_crane")
	if not command(fixture,"template:backpack"):return false
	if not command(crane,"task:backpack_store") or not command(crane,"go:source") or not command(crane,"down"):return false
	supply_rig(crane,true)
	if not command(crane,"up") or not command(crane,"go:receiver"):return false
	crane.request("down");crane.physics(4.7);crane.request("stop")
	expect(fixture.source_release>0 and fixture.source_release<1,"backpack perimeter clamps close only after the load seats")
	if not command(crane,"resume"):return false
	supply_rig(crane,false)
	if not command(crane,"up") or not command(crane,"go:park"):return false
	expect(not fixture.request("template:core").is_empty(),"occupied backpack cannot be replaced by another insert selection")
	if not command(fixture,"advance"):return false
	if not command(fixture,"return"):return false
	if not command(crane,"go:receiver") or not command(crane,"down"):return false
	supply_rig(crane,true)
	expect(crane.request("up").is_empty(),"same backpack can return to free the common fixture")
	crane.physics(.3);crane.request("stop")
	if not command(crane,"resume") or not command(crane,"go:source") or not command(crane,"down"):return false
	supply_rig(crane,false)
	expect(game.model.assemblies.backpack.location=="support:backpack_store","same prepared backpack returns to its original passive store")
	if not command(crane,"up") or not command(crane,"go:park"):return false
	expect(game.model.integrity_errors().is_empty(),"fixture exchange preserves all physical stock and assembly identities")
	return true

func finish() -> void:
	var passed=checks.all(func(check):return check.passed)
	write_evidence("res://verification/backpack-fixture.json",{"scope":"mechanical source/fixture exchange and interrupted motion; no installation completion or access review","checks":checks})
	print("BACKPACK_FIXTURE ","PASS " if passed else "FAIL ",checks.size()," checks")
	game.free();quit(0 if passed else 1)
