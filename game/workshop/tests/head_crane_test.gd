extends "res://tests/kit/m3_section.gd"
## Supplied earlier work; actual fixture, crane, receiver and inventory APIs.

func run() -> void:
	if not await start("head"):finish();return
	var crane=game.equipment.get_equipment("service_crane");var fixture=game.equipment.get_equipment("module_supports")
	var left=game.equipment.get_equipment("head_left_receiver");var top=game.equipment.get_equipment("head_top_receiver")
	expect(not left.receiving_error().is_empty(),"side before baseplate retention/connection is rejected")
	expect(not top.receiving_error().is_empty(),"top before both sides is rejected")
	audit_manual()
	# Right side first exercises the independently valid handed installation order.
	for uid in ["head_baseplate","head_right","head_left","head_top"]:
		var receiver=game.equipment.get_equipment(uid+"_receiver")
		if not command(fixture,"template:"+uid):finish();return
		if not transfer(uid+"_to_fixture"):finish();return
		expect(game.model.assemblies[uid].location=="support:bulky_fixture" and fixture.source_release==0,uid+" transfers to matching upright saddles and closed source clamps")
		supply_rig(crane,false)
		if not command(crane,"up") or not command(crane,"go:park"):finish();return
		if not command(crane,"task:"+uid) or not command(crane,"go:source") or not command(crane,"down"):finish();return
		expect(crane.required_ends==(4 if uid=="head_top" else 2),uid+" uses its specified end count")
		for index in range(crane.required_ends):
			var normal=AssemblyRuntime.vec(receiver.spec.rig.normals[index])
			expect(crane._end_transform(crane.source_pose,index).basis.y.is_equal_approx(normal),uid+" magnetic end follows its exposed pad normal")
		supply_rig(crane,true)
		if not command(crane,"up") or not command(crane,"go:receiver"):finish();return
		if uid=="head_baseplate":
			var body=game.runtime.node(uid);var before: Transform3D=body.global_transform
			body.global_basis=Basis(Vector3.UP,PI)
			expect(not receiver.accept().is_empty() and game.model.assemblies[uid].parent.is_empty(),"reversed baseplate is rejected without consuming its crane support")
			body.global_transform=before
		if not command(crane,"down"):finish();return
		expect(receiver.state=="seated" and game.model.assemblies[uid].parent=="chest",uid+" seats while the crane holds it")
		expect(game.runtime.node(uid).global_transform.is_equal_approx(receiver.load_pose()),uid+" retains its exact chest-relative mating pose")
		expect(not crane.action_error("detach:"+crane.END_IDS[0]).is_empty(),uid+" premature release is rejected")
		var retention: Array=receiver.spec.retention_slots
		for sid in retention:expect(game.equipment.placement_error("chest",sid).is_empty(),sid+" is accessible under complete crane support")
		if uid=="head_baseplate":
			var loom: String=retention[-1]
			var loom_uid="HD-LOOM__001";game.model.transfer("hd-loom","bin","pocket",loom_uid)
			expect(not game.model.install("chest",loom,loom_uid).ok,"loom cannot precede all four neck bolts")
			Staging.fill(game,"chest",retention.slice(0,-1))
			expect(game.model.milestone("chest","head_baseplate_retained") and not game.model.milestone("chest","head_baseplate_connected"),"neck bolts establish retention without pretending the loom is connected")
			expect(not left.receiving_error().is_empty(),"sides still require the central loom after all neck bolts")
			expect(not receiver.rig_error("detach","").is_empty(),"baseplate rig stays attached through loom connection and strain relief")
			Staging.fill(game,"chest",[loom])
			expect(not left.receiving_error().is_empty(),"connected baseplate still blocks sides while its rig zone is occupied")
			var partial: Dictionary=crane.capture();partial.endpoints[crane.END_IDS[0]]={"state":"held","point":""};partial.endpoints[crane.END_IDS[1]]={"state":"stowed","point":""};crane.apply(partial)
			expect(not left.receiving_error().is_empty(),"a detached end still held in the front opening must be stowed before shells")
			supply_rig(crane,true)
		else:Staging.fill(game,"chest",retention)
		expect(receiver.retained() and receiver.rig_error("detach","").is_empty(),uid+" full retention permits rig release")
		if uid=="head_right":
			expect(not top.receiving_error().is_empty(),"one retained side cannot receive the roof")
			var wrong="HD-M12160__001";game.model.transfer("hd-m12-160","bin","pocket",wrong)
			var last: String=game.model.assemblies.chest.slots[retention[-1]]
			supply_rig(crane,false)
			expect(game.equipment.undo("chest").handled,"unsupported side-bolt correction is rejected")
			supply_rig(crane,true)
			expect(not game.equipment.undo("chest").handled and game.model.undo("chest").ok,"matching fully rigged crane permits one local side-bolt correction")
			game.components.sync("chest")
			expect(not game.model.install("chest",retention[-1],wrong).ok,"long M12 top bolt cannot replace an M12 side bolt")
			expect(game.model.install("chest",retention[-1],last).ok,"correction reinstalls the same consumed side bolt identity")
			game.components.sync("chest")
		supply_rig(crane,false)
		expect(receiver.state=="released" and game.zones.holder(uid+"_rig").is_empty(),uid+" released and stowed rig clears its zone")
		if not command(crane,"up") or not command(crane,"go:park"):finish();return
	expect(stages.stage_errors("head_sensors").is_empty(),"head_sensors begins with all four pieces retained, rig stowed and crane parked")
	expect(game.model.integrity_errors().is_empty(),"head construction preserves every physical owner and identity")
	# Leave the straight front sensor prism open after the structural roof.
	var shape=BoxShape3D.new();shape.size=Vector3(1.06,.66,1.42)
	var at=Transform3D(Basis.IDENTITY,Vector3(13,18.21,25.21))
	var query=PhysicsShapeQueryParameters3D.new();query.shape=shape;query.transform=at;query.collision_mask=15
	await frames(2)
	expect(game.get_world_3d().direct_space_state.intersect_shape(query).is_empty(),"installed sides and roof preserve the complete straight front sensor insertion prism")
	finish()

func transfer(task: String) -> bool:
	var crane=game.equipment.get_equipment("service_crane")
	if not command(crane,"task:"+task) or not command(crane,"go:source") or not command(crane,"down"):return false
	supply_rig(crane,true)
	return command(crane,"up") and command(crane,"go:receiver") and command(crane,"down")

func audit_manual() -> void:
	var definition: Dictionary=game.runtime.definition("chest");var counts={};var pages=0
	for index in range(definition.manual.size()):
		var page: Dictionary=definition.manual[index]
		if page.slots.is_empty() or not (page.slots[0].begins_with("head_") or page.slots[0].begins_with("hd-")):continue
		game.hud.open_manual("chest",index)
		var supplies: String=game.hud.page_body.text.get_slice("Parts for this step\n",1)
		expect(not supplies.is_empty(),"runtime HUD shows supplies for "+page.title)
		for sid in page.slots:counts[sid]=counts.get(sid,0)+1
		if page.slots==["head_baseplate"] or page.slots==["head_left"] or page.slots==["head_right"] or page.slots==["head_top"]:
			expect("(prepared) ×1" in supplies,"delivery lists exactly one prepared head piece")
		elif page.slots.size()==8:expect(supplies.count("×4")==2 and "HD-W24" in supplies and "HD-M24160" in supplies,"neck retention HUD requests four bolts and four separate washers")
		pages+=1
	expect(pages==9 and counts.size()==21 and counts.values().all(func(n):return n==1),"nine head pages cover each of the 21 physical installation slots exactly once")

func finish() -> void:
	var passed=checks.all(func(check):return check.passed)
	write_evidence("res://verification/head-crane.json",{"scope":"head source transfers, installation, part/manual HUD audit and supported correction; no walking/reach/rendered review","checks":checks})
	print("HEAD_CRANE ","PASS " if passed else "FAIL ",checks.size()," checks")
	game.free();quit(0 if passed else 1)
