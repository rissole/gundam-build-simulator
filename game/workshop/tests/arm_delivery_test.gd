extends "res://tests/kit/stage_section.gd"
## Mechanical commands and staged rig/stock in continuous play.
## No walking, reach, aiming or rendered acceptance is inferred.
func run() -> void:
	if not await start("left_arm"):finish();return
	expect(await deliver_arms(),"detailed section completes")
	finish()

func deliver_arms() -> bool:
	var crane=game.equipment.get_equipment("service_crane")
	var cassette=game.equipment.get_equipment("arm_cassette")
	if not is_equal_approx(rail.index_x,22) and not command(rail,"park"):return false
	if not command(crane,"task:cassette") or not command(crane,"go:source") or not command(crane,"down"):return false
	supply_rig(crane,true)
	if not command(crane,"up") or not command(crane,"go:receiver") or not command(crane,"down"):return false
	supply_rig(crane,false)
	if not command(crane,"up") or not command(crane,"go:park"):return false
	for side in ["left","right"]:
		var uid=side+"_arm";var shoulder=game.equipment.get_equipment(side+"_shoulder")
		if side=="right":
			if not command(crane,"task:right_arm_store") or not command(crane,"go:source") or not command(crane,"down"):return false
			supply_rig(crane,true)
			if not command(crane,"up") or not command(crane,"go:receiver"):return false
			expect(crane.request("down").is_empty(),"second arm descends onto the same cleared cassette")
			crane.physics(4.75);crane.request("stop")
			expect(cassette.clamps.all(func(v):return v>0 and v<1),"cassette clamps engage progressively after the second arm reaches its saddles")
			if not command(crane,"resume"):return false
			expect(game.model.assemblies.right_arm.location=="support:arm_cassette","same right-arm identity transfers from passive store onto the shared cassette")
			supply_rig(crane,false)
			if not command(crane,"up") or not command(crane,"go:park"):return false
		if not command(crane,"task:"+uid) or not command(crane,"go:source") or not command(crane,"down"):return false
		var expected=preload("res://scripts/arm_delivery_geometry.gd").route(-1 if side=="left" else 1)
		expect(crane.route.size()==expected.size() and range(expected.size()).all(func(n):return crane.route[n].is_equal_approx(expected[n])),uid+" live waypoints exactly match the measured preflight route and rotations")
		supply_rig(crane,true)
		var access=game.equipment.get_equipment("workshop_access")
		expect(access.request_mode("arm").is_empty() and settle(access),uid+" delivery decks open before interrupted source transfer")
		expect(crane.request("up").is_empty(),uid+" starts four-end source weight transfer")
		crane.physics(.2);crane.request("stop")
		expect(cassette.clamps.all(func(v):return v>0 and v<1) and game.model.assemblies[uid].location=="support:arm_cassette",uid+" stays on its saddles through partial clamp release")
		if not command(crane,"resume"):return false
		expect(cassette.occupant().is_empty() and cassette.clamps.all(func(v):return v==1),uid+" clears the reusable cassette with every clamp folded")
		if side=="left":
			expect(cassette.request("clamp:0").is_empty(),"empty cassette permits independent clamp adjustment")
			cassette.physics(.7);cassette.request("stop")
			expect(cassette.clamps[0]>0 and cassette.clamps[0]<1,"manual empty-cassette clamp retracts/folds continuously")
			if not command(cassette,"resume") or not command(cassette,"clamp:0"):return false
		expect(crane.request("go:receiver").is_empty(),uid+" begins guided upend/yaw/splay")
		crane.physics(.45);crane.request("stop")
		var body=game.runtime.node(uid)
		expect(body.global_basis!=Basis.IDENTITY,uid+" changes orientation continuously during restrained upending")
		expect(PhysicsServer3D.body_get_state(body.get_rid(),PhysicsServer3D.BODY_STATE_TRANSFORM).is_equal_approx(body.global_transform),uid+" physics body follows between input and physics ticks")
		if not command(crane,"resume") or not command(crane,"down"):return false
		expect(shoulder.active and shoulder.tension==1 and game.model.assemblies[uid].parent=="chest",uid+" seats with the crane still carrying its full weight")
		expect(not shoulder.rig_error("detach","").is_empty(),uid+" cup seating alone never permits crane release")
		expect(not shoulder.request("check_brakes").is_empty(),uid+" brake confirmation requires complete structural retention")
		expect(not game.equipment.placement_error("chest",uid+"/service").is_empty(),uid+" services wait for supported weight transfer")
		var root=uid+"/"
		fit_shoulder([root+"ring_front",root+"ring_rear"])
		if side=="left":
			expect(game.model.transfer("sh-washer","bin","pocket","SH-WASHER__008")=="SH-WASHER__008" and game.model.install("chest",root+"washer_1","SH-WASHER__008").ok,"compatible opposite-side washer copy retains its own identity")
			game.components.sync("chest")
			var found=false
			for mesh in game.runtime.node("chest").get_children():
				if mesh.has_meta("component_uid") and mesh.get_meta("component_uid")=="SH-WASHER__008":found=mesh.mesh==game.source[game.model.slot_definition("chest",root+"washer_1").pose_source].mesh and mesh.global_transform.is_equal_approx(game.runtime.slot_pose("chest",root+"washer_1"))
			expect(found,"swapped washer uses the receiving source geometry and orientation")
		fit_shoulder(shoulder.spec.structural_slots.filter(func(sid):return sid.begins_with(root+"washer_") or sid.begins_with(root+"bolt_")))
		if side=="left":
			var wrong="SH-BRACE-RIGHT__001"
			expect(game.model.carry_item(wrong).is_empty(),"wrong handed brace can be collected as ordinary stock")
			expect(not game.model.placement_error("chest",root+"brace",wrong).is_empty(),"ready left keyed seat rejects the actual right brace variant")
			game.model.release_item("bin")
		fit_shoulder(shoulder.spec.structural_slots.filter(func(sid):return sid!=uid and sid not in [root+"ring_front",root+"ring_rear"]))
		expect(not shoulder.rig_error("detach","").is_empty(),uid+" complete pins still require brakes and deliberate load transfer")
		if not command(shoulder,"check_brakes"):return false
		expect(crane.request("guide:transfer_weight").is_empty(),uid+" console starts transferring weight to retained shoulder")
		shoulder.physics(.7);shoulder.request("stop")
		expect(shoulder.tension>0 and shoulder.tension<1,uid+" weight transfer has an intermediate resumable load fraction")
		var rig: Array=shoulder.rig_solids(shoulder.load_pose());var matched=true
		for n in range(rig.size()):
			if rig[n].rig_kind in ["spreader","equalizer","hook"]:matched=matched and shoulder.rig_nodes[n].global_transform.is_equal_approx(rig[n].world) and shoulder.rig_nodes[n].mesh.size.is_equal_approx(rig[n].shape.size)
		expect(matched,uid+" live spreader, equalizers and hook match swept geometry through partial weight transfer")
		if not command(shoulder,"resume"):return false
		fit_shoulder(shoulder.spec.service_slots)
		expect(shoulder.secured() and shoulder.rig_error("detach","").is_empty(),uid+" connected retained shoulder permits rig release")
		supply_rig(crane,false)
		if not command(crane,"up") or not command(crane,"go:park"):return false
		expect(game.model.integrity_errors().is_empty(),uid+" delivery and retention conserve stock and assembly ownership")
		if not await correct_shoulder(side):return false
	return true

func correct_shoulder(side: String) -> bool:
	var crane=game.equipment.get_equipment("service_crane");var shoulder=game.equipment.get_equipment(side+"_shoulder")
	var uid=side+"_arm";var keeper_slot=uid+"/drive_3_b_keeper"
	var keeper: String=game.model.assemblies.chest.slots[keeper_slot]
	var service: String=game.model.assemblies.chest.slots[uid+"/service"]
	expect(not game.equipment.undo("chest").handled and game.model.undo("chest").ok,"isolated "+side+" service harness removes while retained shoulder carries the load")
	# Supply the return to storage; hand pickup/reach remains human playtest.
	expect(game.model.carry_item(service).is_empty() and game.model.release_item("bin")==service,"same disconnected harness returns to stock for local correction")
	game.components.sync("chest")
	expect(game.equipment.undo("chest").handled,"released "+side+" shoulder blocks retention undo without crane support")
	if not command(crane,"go:receiver") or not command(crane,"down"):return false
	supply_rig(crane,true)
	expect(game.equipment.undo("chest").handled,"attached ends must take "+side+" arm weight before keeper correction")
	if not command(shoulder,"take_weight"):return false
	expect(not game.equipment.undo("chest").handled and game.model.undo("chest").ok,"four-ended crane permits supported "+side+" keeper correction")
	game.components.sync("chest")
	expect(not shoulder.brakes and game.model.assemblies[uid].parent=="chest","keeper correction invalidates brake confirmation while keeping the same seated arm")
	fit_shoulder([keeper_slot])
	expect(game.model.assemblies.chest.slots[keeper_slot]==keeper,"supported correction reinstalls the same "+side+" keeper identity")
	if not command(shoulder,"check_brakes") or not command(shoulder,"transfer_weight"):return false
	fit_shoulder(shoulder.spec.service_slots);supply_rig(crane,false)
	if not command(crane,"up") or not command(crane,"go:park"):return false
	return true

func fit_shoulder(ids: Array) -> void:
	for sid in ids:
		if not game.model.assemblies.chest.slots[sid].is_empty():continue
		var error: String=game.equipment.placement_error("chest",sid)
		expect(error.is_empty(),"shoulder mounting permits "+sid+": "+error)
		if error.is_empty():Staging.fill(game,"chest",[sid])

func finish() -> void:
	var passed=checks.all(func(check):return check.passed)
	write_evidence("res://verification/arm-delivery.json",{"scope":"mechanical delivery of both arms, shared cassette, supported shoulder retention; supplied attachments/stock; no walking/access review","checks":checks})
	print("ARM_DELIVERY ","PASS " if passed else "FAIL ",checks.size()," checks")
	game.free();quit(0 if passed else 1)
