extends "res://tests/kit/stage_section.gd"
## Supplied earlier construction and rigging; real receiver/support/stock APIs.
## No walking, reach, visibility, saving or rendered review.

func run() -> void:
	if not await start("pauldrons"):finish();return
	var crane=game.equipment.get_equipment("service_crane")
	var right=game.equipment.get_equipment("right_pauldron_receiver")
	expect(game.model.undo("chest").ok,"supply an isolated right-shoulder service prerequisite counterexample")
	expect(not right.receiving_error().is_empty(),"receiver requires the shoulder-connected milestone")
	Staging.fill(game,"chest",["right_arm/service"])
	expect(right.receiving_error().is_empty(),"restored service satisfies the receiver milestone")
	for side in ["left","right"]:
		var uid=side+"_pauldron";var receiver=game.equipment.get_equipment(uid+"_receiver")
		audit_manual(uid)
		expect(receiver.state=="idle" and receiver.capture().is_empty(),uid+" starts idle and inherits the empty save contract")
		expect(not receiver.request("release:joint_restraints").is_empty(),uid+" prevents restraint release before closure")
		if not command(crane,"task:"+uid) or not command(crane,"go:source") or not command(crane,"down"):finish();return
		expect(crane.required_ends==2,uid+" uses exactly two crane ends")
		for index in range(2):
			var point: Vector3=crane.points[index];var normal=AssemblyRuntime.vec(receiver.spec.rig.normals[index])
			expect(crane._end_transform(crane.source_pose,index).basis.y.is_equal_approx(normal),uid+" articulated end follows the vertical plate normal")
			expect(crane.handle_position(crane.POINT_IDS[index]).is_equal_approx(crane.source_pose*point),uid+" visible handle shares its attachment face")
		supply_rig(crane,true)
		if not command(crane,"up") or not command(crane,"go:receiver") or not command(crane,"down"):finish();return
		expect(receiver.state=="seated" and game.model.assemblies[uid].parent=="chest",uid+" seats without claiming retention")
		expect(game.runtime.node(uid).global_transform.is_equal_approx(receiver.load_pose()),uid+" inherits the chest's exact authored seat pose")
		expect(not crane.action_error("detach:"+crane.END_IDS[0]).is_empty(),uid+" rejects premature rig release")
		expect(not game.equipment.placement_error("chest",receiver.spec.closure_slots[0]).is_empty(),uid+" rejects a panel before carrier retention")
		var retention: Array=receiver.spec.retention_slots
		# The short and long clamp shoes are physically different fitting variants.
		var wrong=""
		for item in game.model.items:
			if game.model.items[item].kind=="pd-bolt-long" and game.model.items[item].owner.is_empty():wrong=item;break
		game.model.transfer("pd-bolt-long","bin","pocket",wrong)
		expect(not game.model.install("chest",retention[3],wrong).ok,uid+" rejects a long shoe at a distal short-shoe boss")
		if side=="left":
			game.model.transfer("pd-bolt-long","bin","pocket","PD-M20__005")
			expect(game.model.install("chest",retention[0],"PD-M20__005").ok,uid+" accepts a compatible opposite-side long-shoe copy")
		Staging.fill(game,"chest",retention.slice(0,3))
		expect(not receiver.rig_error("detach","").is_empty(),uid+" three M20 bolts cannot release the rig")
		Staging.fill(game,"chest",[retention[3]])
		expect(receiver.state=="retained" and receiver.rig_error("detach","").is_empty(),uid+" all four bolts permit rig release")
		expect(not game.equipment.placement_error("chest",receiver.spec.closure_slots[0]).is_empty(),uid+" closure still waits for every attached end")
		# One end removed: retention remains safe, correction does not.
		var partial: Dictionary=crane.capture();partial.endpoints[crane.END_IDS[0]]={"state":"stowed","point":""};crane.apply(partial)
		expect(game.equipment.undo("chest").handled,uid+" blocks retention undo under incomplete crane support")
		supply_rig(crane,false)
		expect(receiver.state=="released" and game.equipment.undo("chest").handled,uid+" released carrier forbids unsupported bolt correction")
		supply_rig(crane,true)
		var last: String=game.model.assemblies.chest.slots[retention[3]]
		expect(not game.equipment.undo("chest").handled and game.model.undo("chest").ok,uid+" matching fully attached crane permits local bolt correction")
		game.components.sync("chest")
		expect(receiver.state=="seated" and not receiver.rig_error("detach","").is_empty(),uid+" correction invalidates retention while preserving seating")
		expect(game.equipment.placement_error("chest",retention[3]).is_empty() and game.model.install("chest",retention[3],last).ok,uid+" reinstalls the same bolt identity under support")
		game.components.sync("chest");supply_rig(crane,false)
		if not command(crane,"up") or not command(crane,"go:park"):finish();return
		var panel_slots: Array=receiver.spec.closure_slots
		# Either closure may go first; each retains its own four captive screws.
		if not await panel_via_shelf(side,panel_slots[1]) or not await panel_via_shelf(side,panel_slots[0]):finish();return
		expect(game.model.milestone("chest",uid+"_closed"),uid+" both independent panels close the retained carrier")
		expect(not receiver.rig_error("attach","").is_empty(),uid+" closed panels block re-rigging")
		for operation in receiver.spec.operations:
			expect(receiver.request("release:"+operation.id).is_empty(),uid+" permits local release of "+operation.id)
			var nodes: Dictionary=receiver.operation_nodes[operation.id]
			expect(not nodes.visual.visible and nodes.collision.disabled,uid+" released "+operation.id+" removes its restraint solid")
		expect(game.equipment.undo("chest").handled,uid+" correction waits for local restraints to re-engage")
		for operation in receiver.spec.operations:expect(receiver.request("engage:"+operation.id).is_empty(),uid+" re-engages "+operation.id+" for local correction")
		expect(not game.equipment.undo("chest").handled,uid+" restored restraints permit panel correction")
		for operation in receiver.spec.operations:receiver.request("release:"+operation.id)
	expect(stages.stage_errors("head").is_empty(),"head boundary requires both closed retained carriers, released restraints and parked crane")
	expect(game.model.integrity_errors().is_empty(),"both deliveries preserve every physical identity and support owner")
	finish()

func audit_manual(uid: String) -> void:
	var manual: Array=game.runtime.definition("chest").manual
	var audited=0
	for i in range(manual.size()):
		var page: Dictionary=manual[i]
		if page.slots.is_empty() or not page.slots[0].begins_with(uid):continue
		game.hud.open_manual("chest",i)
		var supplies: String=game.hud.page_body.text.get_slice("Parts for this step\n",1)
		expect(not supplies.is_empty(),uid+" runtime HUD supplies exist for "+page.title)
		if page.slots==[uid]:expect("(prepared) ×1" in supplies,uid+" delivery page requests one prepared carrier")
		elif page.slots.size()==4:expect(supplies.count("×2")==2 and "PD-M20-LONG" in supplies and "PD-M20-SHORT" in supplies,uid+" retention page requests exactly two of each fitting variant")
		else:expect(supplies.count("×1")==1 and "M12" not in supplies,uid+" panel page requests one panel with no extra captive-screw stock")
		audited+=1
	expect(audited==4,uid+" parent manual covers delivery, retention and each independent closure once")

func panel_via_shelf(side: String, sid: String) -> bool:
	var receiver=game.equipment.get_equipment(side+"_pauldron_receiver")
	var spec: Dictionary=game.model.slot_definition("chest",sid)
	var uid=""
	for item in game.model.items:
		if game.model.items[item].kind==spec.accepts and game.model.items[item].owner.is_empty():uid=item;break
	var bound: AABB=game.source[game.source_uid(uid)].mesh.get_aabb()
	expect(bound.size.x<=1.35 and bound.size.z<=.35 and bound.size.y<=1.10,sid+" complete panel fits the unchanged shelf: "+str(bound.size))
	var shelf=game.equipment.get_equipment(side+"_shelf");var lift=game.equipment.get_equipment(side+"_lift")
	if lift.height!=lift.stops[0] and not command(lift,"ground"):return false
	expect(game.model.carry_item(uid).is_empty(),sid+" two-hand panel leaves stock")
	game.components.hold_at(uid,shelf._pose(uid,0).translated(Vector3.UP*.10))
	var error: String=shelf.request("store")
	expect(error.is_empty(),sid+" stores its real identity on the elevator shelf: "+error)
	if not error.is_empty():return false
	if not command(lift,"stop3"):return false
	expect(game.model.items[uid].location=="support:"+shelf.support_ids[0],sid+" remains shelf-owned during elevator travel")
	error=shelf.request("take:0");expect(error.is_empty(),sid+" returns from the shelf to two hands: "+error)
	if not error.is_empty():return false
	expect(game.equipment.placement_error("chest",sid).is_empty(),sid+" receiver allows closure after rig release")
	var result: Dictionary=game.model.install("chest",sid,uid)
	expect(result.ok,sid+" fits with four captive M12 fastening operations: "+str(result))
	game.components.held_body.free();game.components.held_body=null;game.components.sync("chest")
	if sid==receiver.spec.closure_slots[1]:expect(not receiver.request("release:digit_cradle").is_empty(),side+" one panel cannot release restraints")
	return result.ok

func finish() -> void:
	var passed=checks.all(func(check):return check.passed)
	write_evidence("res://verification/pauldron-delivery.json",{"scope":"mechanical delivery, inventory/manual audit, actual shelf/elevator handling and supported correction; no walking/reach/rendered review","checks":checks})
	print("PAULDRON_DELIVERY ","PASS " if passed else "FAIL ",checks.size()," checks")
	game.free();quit(0 if passed else 1)
