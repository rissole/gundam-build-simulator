extends "res://tests/kit/harness.gd"

func definitions() -> Dictionary:
	return {"version":1,"parts":{
		"base":{"family":"base","title":"Base","carry_class":"equipment"},
		"bolt":{"family":"bolt","title":"Bolt","carry_class":"pocket"},
		"beam":{"family":"beam","title":"Beam","carry_class":"equipment"}},"assemblies":{
		"foot":{"carry_class":"equipment","root_slot":"base","work_locations":["support","fixture"],"slots":{"base":{"accepts":"base"},"bolt":{"accepts":"bolt","requires":["base"]}},"milestones":{"ready":["base","bolt"]}},
		"leg":{"carry_class":"equipment","root_slot":"base","work_locations":["support","fixture"],"slots":{"base":{"accepts":"base"},"foot":{"assembly":"foot","milestone":"ready","support_required":true,"source_supports":["hoist"],"snap_position":[0,1,0]},"beam":{"accepts":"beam","requires":["foot"],"support_required":true,"source_supports":["beam_cradle"]},"bolt":{"accepts":"bolt","requires":["beam"]}},"milestones":{"ready":["foot","beam","bolt"]}},
		"hip":{"work_locations":["fixture"],"slots":{"leg":{"assembly":"leg","milestone":"ready","support_required":true,"source_supports":["hoist"]}},"milestones":{"ready":["leg"]}}}}

func scenario() -> Dictionary:
	return {"version":1,"supports":{
		"carrier":{"assemblies":["foot"],"assembly_ids":["foot"]},
		"leg_fixture":{"assemblies":["leg"]},
		"hoist":{"assemblies":["foot","leg"]},
		"beam_cradle":{"parts":["beam"]},
		"beam_stock":{"parts":["beam"]}},
		"parts":[{"instance_id":"f","kind":"base"},{"instance_id":"l","kind":"base"},{"instance_id":"b1","kind":"bolt"},{"instance_id":"b2","kind":"bolt"},{"instance_id":"beam","kind":"beam","location":"support:beam_stock"}],
		"builds":[{"id":"foot","definition":"foot","base":"f","location":"support:carrier"}],
		"parents":[{"id":"leg","definition":"leg","base":"l","location":"support:leg_fixture"},{"id":"hip","definition":"hip"}]}

func baseline() -> AssemblyModel:
	var model = AssemblyModel.new()
	var errors = model.configure(definitions(),scenario())
	expect(errors.is_empty(),"Equipment scenario configures: "+str(errors))
	return model

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var model = baseline()
	var initial = snapshot(model)
	expect(not model.move_assembly("foot","held").is_empty(),"Equipment build cannot enter hands")
	expect(not model.move_assembly("foot","loose").is_empty(),"Equipment build cannot drop support")
	expect(not model.carry_item("beam").is_empty(),"Equipment part cannot enter hands")
	expect(not model.stock_pocket("beam").ok and model.transfer("beam","bin","pocket").is_empty(),"Equipment part cannot use pockets")
	expect(not model.transfer_supported_assembly("hip","carrier","hoist").is_empty(),"Fixed hip cannot transfer")
	expect(not model.transfer_supported_assembly("foot","invented","hoist").is_empty(),"Unknown source cannot forge equipment move")
	expect(not model.transfer_supported_assembly("foot","carrier","leg_fixture").is_empty(),"Wrong support compatibility rejects transfer")
	expect(snapshot(model) == initial,"Rejected handling operations are atomic")
	expect(model.transfer_supported_assembly("foot","carrier","hoist").is_empty(),"Transfer keeps exact assembly identity")
	expect(not model.install("leg","foot","foot").ok,"Ordinary install cannot bypass equipment")
	expect(not model.install_supported("leg","foot","foot","carrier").ok,"Wrong named source rejects mount")
	expect(not model.install_supported("leg","foot","foot","hoist").ok,"Incomplete milestone rejects supported mount")
	model.stock_pocket("bolt")
	expect(model.install("foot","bolt","b1").ok,"Small hardware installs while parent remains supported")
	expect(model.install_supported("leg","foot","foot","hoist").ok,"Prepared supported assembly seats into supported parent")
	expect(model.assemblies.foot.parent == "leg" and model.assemblies.foot.location == "parent" and model.support_occupant("hoist").is_empty(),"Assembly ownership stays separate from handling metadata")
	expect(not model.transfer_supported_assembly("foot","hoist","carrier").is_empty() and not model.undo("foot").ok,"Installed child cannot move or undo internally")
	expect(not model.undo("leg").ok and not model.undo("leg","support:hoist").ok,"Ordinary undo cannot bypass equipment handling")
	expect(model.transfer_supported_assembly("leg","leg_fixture","hoist").is_empty(),"Parent with mounted child can transfer as one assembly")
	expect(not model.undo_supported("leg","hoist").ok,"Occupied output support refuses detachment")
	expect(model.transfer_supported_assembly("leg","hoist","leg_fixture").is_empty(),"Return entire assembly to available fixture")
	expect(model.undo_supported("leg","hoist").ok and model.assemblies.foot.location == "support:hoist" and model.milestone("foot","ready"),"Supported undo preserves child identity and completion")
	expect(model.install_supported("leg","foot","foot","hoist").ok,"Supported child reinstalls")
	expect(not model.install_supported("leg","beam","beam","beam_cradle").ok,"Equipment stock must reach nominated output cradle")
	expect(model.transfer_supported_item("beam","beam_stock","beam_cradle").is_empty(),"Equipment stock transfers between authorized supports")
	expect(not model.install("leg","beam","beam").ok,"Equipment part cannot use ordinary installation")
	expect(model.install_supported("leg","beam","beam","beam_cradle").ok and model.items.beam.owner == "leg","Equipment part installs with exact physical identity")
	expect(model.install("leg","bolt","b2").ok,"Retention hardware follows supported seating")
	expect(model.undo("leg").ok and model.items.b2.location == "pocket","Ordinary hardware undo retains pockets")
	expect(not model.undo("leg").ok and model.undo_supported("leg","beam_cradle").ok and model.items.beam.location == "support:beam_cradle","Equipment part undo restores cradle without hand state")
	expect(model.install_supported("leg","beam","beam","beam_cradle").ok and model.install("leg","bolt","b2").ok,"Reinstall equipment and retention")
	expect(model.transfer_supported_assembly("leg","leg_fixture","hoist").is_empty() and model.install_supported("hip","leg","leg","hoist").ok,"Completed nested leg mounts to fixed hip")
	expect(model.integrity_errors().is_empty(),"Nested equipment transitions conserve physical ownership")
	var mounted = snapshot(model)
	for mutation in ["unknown","occupied","incompatible","metadata","slot_compatibility"]:
		var bad = scenario()
		if mutation == "unknown":bad.builds[0].location = "support:missing"
		if mutation == "occupied":bad.parents[0].location = "support:carrier"
		if mutation == "incompatible":bad.parts.back().location = "support:carrier"
		if mutation == "metadata":bad.supports.hoist.assemblies = ["missing"]
		if mutation == "slot_compatibility":bad.supports.beam_cradle.parts = []
		expect(not model.configure(definitions(),bad).is_empty() and snapshot(model) == mounted,"Invalid support authoring rejects atomically: "+mutation)
	await test_animatable_mount(model)
	var passed = checks.all(func(check):return check.passed)
	print("SUPPORTED_MODEL_AUDIT ","PASS" if passed else "FAIL"," ",checks.size()," checks")
	quit(0 if passed else 1)

func test_animatable_mount(model: AssemblyModel) -> void:
	var root_body = AnimatableBody3D.new()
	root_body.sync_to_physics = false
	var child = AnimatableBody3D.new()
	root.add_child(root_body)
	root.add_child(child)
	var runtime = AssemblyRuntime.new(model,{})
	runtime.register_node("leg",root_body)
	runtime.register_node("foot",child)
	runtime.mount("leg","foot","foot")
	expect(child.get_parent() == root_body and child.position.is_equal_approx(Vector3.UP),"Animatable assembly mounts without rigid-body properties")
	for index in range(12):
		root_body.rotation += Vector3(0.02,0.03,0.01)
		expect(child.global_transform.is_equal_approx(root_body.global_transform*Transform3D(Basis.IDENTITY,Vector3.UP)),"Animatable child follows parent between physics ticks")
		await physics_frame
	root_body.queue_free()
