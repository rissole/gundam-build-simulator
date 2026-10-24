extends "res://tests/indexed_leg_rail_test.gd"
## Mechanical transfer and fresh-scene saves, not walking/targetability review.
func run() -> void:
	game=await boot_profile("leg_bay_m3");rail=game.equipment.get_equipment("leg_rail");carrier=game.equipment.get_equipment("foot_carrier")
	var cassette=game.equipment.get_equipment("arm_cassette");var crane=game.equipment.get_equipment("service_crane")
	var initial: Array[String]=game.saves.validate(game.saves.capture())
	expect(initial.is_empty(),"cassette and its prepared arm start on declared independent supports: "+str(initial))
	expect(cassette.occupant()=="left_arm","same physical left arm starts retained on the one cassette")
	var trim: Dictionary=cassette.mass_properties()
	expect(trim.center.z>1.35 and trim.center.z<6.05,"loaded cassette's authored mass centre lies between both lifting pairs: "+str(trim))
	expect(not cassette.receiving_error("arm_cassette").is_empty(),"occupied leg station rejects the cassette before travel")
	if not command(rail,"park"):finish();return
	expect(cassette.receiving_error("arm_cassette").is_empty(),"parked leg cradle makes the shared station available")
	expect(crane.request("task:cassette").is_empty(),"existing crane selects the retained-cassette task")
	if not command(crane,"go:source") or not command(crane,"down"):finish();return
	attach_ends(crane)
	expect(not cassette.request("clamp:0").is_empty(),"retained arm clamp cannot open during cassette lifting")
	expect(crane.request("up").is_empty(),"crane starts taking cassette weight")
	crane.physics(.2);crane.request("stop")
	expect(cassette.floor_release>0 and cassette.floor_release<1,"four floor locks release only while the four-end crane takes weight")
	var matching=true
	for owner_id in cassette.body.get_shape_owners():
		var col=cassette.body.shape_owner_get_owner(owner_id)
		if not col is CollisionShape3D or not col.has_meta("source_uid"):continue
		var uid: String=col.get_meta("source_uid")
		var actual: Transform3D=PhysicsServer3D.body_get_shape_transform(cassette.body.get_rid(),cassette.body.shape_owner_get_shape_index(owner_id,0))
		matching=matching and actual.is_equal_approx(cassette.source_nodes[uid].transform)
	expect(matching,"all cassette source meshes and actual physics shapes agree during partial lock travel between physics ticks")
	if not await reopen("cassette partial floor-lock release"):finish();return
	cassette=game.equipment.get_equipment("arm_cassette");crane=game.equipment.get_equipment("service_crane")
	if not command(crane,"resume"):finish();return
	expect(game.model.assemblies.arm_cassette.location=="support:m2_service_crane","crane owns the lifted cassette")
	expect(game.model.assemblies.left_arm.location=="support:arm_cassette" and is_equal_approx(game.runtime.node("left_arm").global_position.y,6.35),"retained arm follows its cassette above the foot crossing without changing owner")
	var bad: Dictionary=game.saves.capture();bad.world.equipment.arm_cassette.floor_release=0
	expect(not game.saves.validate(bad).is_empty(),"suspended cassette cannot save with lowered floor pins")
	if not await reopen("cassette suspended with retained arm"):finish();return
	cassette=game.equipment.get_equipment("arm_cassette");crane=game.equipment.get_equipment("service_crane")
	if not command(crane,"go:receiver"):finish();return
	expect(crane.request("down").is_empty(),"crane starts lowering cassette into station")
	crane.physics(4.75);crane.request("stop")
	expect(cassette.floor_release>0 and cassette.floor_release<1,"station locks close only after cassette reaches floor contact")
	if not await reopen("cassette partial receiving floor-lock engagement"):finish();return
	cassette=game.equipment.get_equipment("arm_cassette");crane=game.equipment.get_equipment("service_crane")
	if not command(crane,"resume"):finish();return
	expect(cassette.support_secured() and game.model.assemblies.arm_cassette.location=="support:cassette_station","station floor locks take the retained cassette before rig release")
	expect(not rail.request("park").is_empty(),"cassette occupancy prevents the parked leg holder from returning")
	stow_ends(crane)
	if not command(crane,"up") or not command(crane,"go:park"):finish();return
	if not await reopen("retained cassette at shared station"):finish();return
	cassette=game.equipment.get_equipment("arm_cassette");crane=game.equipment.get_equipment("service_crane")
	bad=game.saves.capture();bad.world.fixtures.left_arm[9]+=.5
	expect(not game.saves.validate(bad).is_empty(),"saved retained arm cannot move independently of its cassette")
	bad=game.saves.capture();bad.world.equipment.arm_cassette.clamps[0]=1
	expect(not game.saves.validate(bad).is_empty(),"saved retained arm must keep all cassette clamps")
	if not command(crane,"go:receiver") or not command(crane,"down"):finish();return
	attach_ends(crane)
	if not command(crane,"up") or not command(crane,"go:source") or not command(crane,"down"):finish();return
	stow_ends(crane)
	if not command(crane,"up") or not command(crane,"go:park"):finish();return
	expect(game.model.assemblies.left_arm.location=="support:arm_cassette" and cassette.occupant()=="left_arm","parking retains the same arm without rebuilding or replacing it")
	if not await reopen("cassette returned to passive parking"):finish();return
	if not command(rail,"park"):finish();return
	expect(rail.can_construct(),"leg cradle physically reclaims the cleared shared station")
	finish()

func attach_ends(crane: Node) -> void:
	var state: Dictionary=crane.capture()
	for n in range(4):state.endpoints[crane.END_IDS[n]]={"state":"attached","point":crane.POINT_IDS[n]}
	expect(crane.validate(state,game.model).is_empty(),"supplied four-end cassette attachment respects the current support")
	crane.apply(state)

func stow_ends(crane: Node) -> void:
	var state: Dictionary=crane.capture()
	for id in crane.END_IDS:state.endpoints[id]={"state":"stowed","point":""}
	expect(crane.validate(state,game.model).is_empty(),"supplied cassette rig release preserves floor support")
	crane.apply(state)

func finish() -> void:
	var passed=checks.all(func(check):return check.passed)
	write_evidence("res://verification/arm-cassette.json",{"scope":"mechanical shared-cassette transfer/occupancy, staged rig attachment; no walking/access acceptance","checks":checks})
	print("ARM_CASSETTE ","PASS " if passed else "FAIL ",checks.size()," checks")
	game.free();quit(0 if passed else 1)
