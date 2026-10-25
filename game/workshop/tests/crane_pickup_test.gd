extends "res://tests/kit/stage_section.gd"
## Pickup/deliver crane console: movement only, the next load comes from
## crane.order. Mechanical fixture; console clarity is the user's playtest.
func run() -> void:
	if not await start("left_leg_build"):finish();return
	expect(pickup_and_deliver(),"the empty crane serves the next load in build order")
	finish()

func actions(crane: Node) -> Array:
	return crane.menu_options().map(func(option):return option.action)

func pickup_and_deliver() -> bool:
	var crane=game.equipment.get_equipment("service_crane")
	expect(crane.station=="park" and crane.next_route()=="foot" and crane.load_text()=="Next pickup: "+crane._load_title("foot"),"parked crane names the next pickup: "+crane.load_text())
	expect(actions(crane)==["pickup"],"parked console offers only the pickup move: "+str(actions(crane)))
	expect(crane.menu_options()[0].label.begins_with("Move to ") and not crane.menu_options()[0].label.contains("pickup"),"pickup names its place: "+crane.menu_options()[0].label)
	if not command(crane,"pickup"):return false
	expect(crane.task=="foot" and crane.station=="source","pickup moves over the foot")
	expect(actions(crane)==["down","go:park"],"empty crane at pickup offers Lower and Park: "+str(actions(crane)))
	if not command(crane,"down"):return false
	supply_rig(crane,true)
	if not command(crane,"up"):return false
	expect(crane.load_text().begins_with("Carrying: "),"lifted load is carried: "+crane.load_text())
	expect(actions(crane)==["down","go:receiver"],"carried load offers Lower and delivery only: "+str(actions(crane)))
	if not command(crane,"go:receiver") or not command(crane,"down"):return false
	expect(crane._installed(),"delivery seats the foot on its carrier")
	supply_rig(crane,false)
	if not command(crane,"up"):return false
	expect(crane.next_route()=="shin" and not crane.next_hint().is_empty(),"shin waits for the fitted foot: "+crane.next_hint())
	expect(not crane.action_error("pickup").is_empty(),"blocked pickup explains itself instead of travelling")
	if not command(carrier,"advance") or not command(carrier,"advance") or not command(carrier,"advance"):return false
	expect(crane.next_hint().is_empty(),"fitted foot releases the shin pickup")
	var before: Transform3D=crane._beam_pose()
	var error: String=crane.request("pickup")
	expect(error.is_empty() and crane.task=="shin","pickup switches route from the delivery point: "+error)
	expect(crane._beam_pose().origin.distance_to(before.origin)<.001,"route changes without the beam jumping")
	if not settle(crane):return false
	expect(crane.station=="source" and crane.place_of("source")=="left_shin_rack","crane arrives over the shin rack")
	return crane.task=="shin"

func finish() -> void:
	var passed=checks.all(func(check):return check.passed)
	write_evidence("res://verification/crane-pickup.json",{"scope":"mechanical crane pickup order; no walking, access or console clarity review","checks":checks})
	print("CRANE_PICKUP ","PASS " if passed else "FAIL ",checks.size()," checks")
	game.free();quit(0 if passed else 1)
