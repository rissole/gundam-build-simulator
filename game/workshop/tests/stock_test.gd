extends "res://tests/kit/workshop_suite.gd"
## Canonical equipment stock persists independently of crane task selection.
const Layout = preload("res://scripts/leg_bay_layout.gd")
func verify_stock(crane: Node, label: String) -> void:
	var loads: Dictionary={}
	for spec in crane.tasks.values():loads[spec.load_uid]=true
	expect(crane.stock_bodies.size()==loads.size(),label+": each distinct physical load has one body across all tasks")
	for spec in crane.tasks.values():
		var body: AnimatableBody3D = crane.stock_bodies[spec.load_uid]
		if spec.get("payload","")=="assembly":
			var record: Dictionary=game.model.assemblies[spec.load_uid]
			expect(body==game.runtime.node(spec.load_uid) and body.get_meta("assembly_id")==spec.load_uid,label+": assembly load reuses its exact runtime body "+spec.load_uid)
			expect(body.visible and body.collision_layer==4,label+": supported assembly remains visible and solid "+spec.load_uid)
			if record.location=="support:"+spec.source_support:
				var expected=Layout.authored_pose(spec.source_pose)
				if spec.source_support=="arm_cassette":expected=game.runtime.node("arm_cassette").global_transform*Transform3D(Basis.IDENTITY,AssemblyRuntime.vec(game.leg_content.equipment.arm_cassette.arm_offset))
				expect(body.global_transform.is_equal_approx(expected),label+": assembly follows its actual source support "+spec.load_uid)
			expect(body.global_transform.is_equal_approx(PhysicsServer3D.body_get_state(body.get_rid(),PhysicsServer3D.BODY_STATE_TRANSFORM)),label+": physics matches visible assembly immediately "+spec.load_uid)
			continue
		var at_source: bool = game.model.items[spec.load_uid].location == "support:"+spec.source_support
		expect(body.get_meta("equipment_item_uid")==spec.load_uid,label+": body identifies exact "+spec.load_uid)
		expect(body.visible == at_source and body.collision_layer == (2 if at_source else 0),label+": visibility and solidity follow actual source ownership "+spec.load_uid)
		if at_source:
			expect(body.global_transform.is_equal_approx(Layout.authored_pose(spec.source_pose)),label+": actual source frame "+spec.load_uid)
			expect(body.global_transform.is_equal_approx(PhysicsServer3D.body_get_state(body.get_rid(),PhysicsServer3D.BODY_STATE_TRANSFORM)),label+": physics matches visible stock immediately "+spec.load_uid)
		var visual: MeshInstance3D = body.get_child(0)
		expect(visual.mesh == game.source[spec.load_uid].mesh and visual.get_meta("source_uid")==spec.load_uid,label+": canonical source mesh "+spec.load_uid)

func run() -> void:
	game = await boot_workshop("pelvis")
	var crane = game.equipment.get_equipment("service_crane")
	verify_stock(crane,"Opening")
	var bodies: Dictionary = crane.stock_bodies.duplicate()
	for task in crane.tasks:
		expect(crane.request("task:"+task).is_empty(),"Direct controller layer selects "+task+" at parked rig")
		verify_stock(crane,"Selected "+task)
		expect(crane.stock_bodies == bodies and crane.load_body == bodies[crane.uid],"Task selection preserves all existing bodies and selects exact identity")
	var passed = checks.all(func(check):return check.passed)
	write_evidence("res://verification/stock.json",{"passed":passed,"checks":checks,"rendered":false,"ordinary_controls":false})
	game.free();print("STOCK ","PASS" if passed else "FAIL"," ",checks.size()," checks");quit(0 if passed else 1)
