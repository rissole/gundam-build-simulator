extends "res://tests/kit/workshop_suite.gd"
## Canonical equipment stock persists independently of crane task selection.
const Layout = preload("res://scripts/leg_bay_layout.gd")
func verify_stock(crane: Node, label: String) -> void:
	expect(crane.stock_bodies.size()==3,label+": all three physical load bodies exist")
	for spec in crane.tasks.values():
		var body: AnimatableBody3D = crane.stock_bodies[spec.load_uid]
		var at_source: bool = game.model.items[spec.load_uid].location == "support:"+spec.source_support
		expect(body.get_meta("equipment_item_uid")==spec.load_uid,label+": body identifies exact "+spec.load_uid)
		expect(body.visible == at_source and body.collision_layer == (2 if at_source else 0),label+": visibility and solidity follow actual source ownership "+spec.load_uid)
		if at_source:
			expect(body.global_transform.is_equal_approx(Layout.authored_pose(spec.source_pose)),label+": actual source frame "+spec.load_uid)
			expect(body.global_transform.is_equal_approx(PhysicsServer3D.body_get_state(body.get_rid(),PhysicsServer3D.BODY_STATE_TRANSFORM)),label+": physics matches visible stock immediately "+spec.load_uid)
		var visual: MeshInstance3D = body.get_child(0)
		expect(visual.mesh == game.source[spec.load_uid].mesh and visual.get_meta("source_uid")==spec.load_uid,label+": canonical source mesh "+spec.load_uid)

func run() -> void:
	game = await boot_profile("leg_bay_m3")
	var crane = game.equipment.get_equipment("service_crane")
	verify_stock(crane,"Opening")
	var bodies: Dictionary = crane.stock_bodies.duplicate()
	for task in ["fork","spar","shin"]:
		expect(crane.request("task:"+task).is_empty(),"Direct controller layer selects "+task+" at parked rig")
		verify_stock(crane,"Selected "+task)
		expect(crane.stock_bodies == bodies and crane.load_body == bodies[crane.uid],"Task selection preserves all existing bodies and selects exact identity")
	var snapshot: Dictionary = JSON.parse_string(JSON.stringify(game.saves.capture()))
	expect(game.saves.validate(snapshot).is_empty(),"All visible source stock validates in detached snapshot")
	game.free();await process_frame
	game = await boot_profile("leg_bay_m3")
	expect(game.saves.apply_snapshot(snapshot),"Fresh scene restores independent source-stock projection")
	crane = game.equipment.get_equipment("service_crane");verify_stock(crane,"Restored")
	var passed = checks.all(func(check):return check.passed)
	write_evidence("res://verification/m3-stock.json",{"passed":passed,"checks":checks,"rendered":false,"ordinary_controls":false})
	game.free();print("M3_STOCK ","PASS" if passed else "FAIL"," ",checks.size()," checks");quit(0 if passed else 1)
