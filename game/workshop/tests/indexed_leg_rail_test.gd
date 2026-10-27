extends "res://tests/kit/stage_section.gd"
## Supported motion test using the actual scene/stock/solids. Construction is
## explicitly supplied via model staging; no walk/aim/reach acceptance is run.
func finish() -> void:
	var passed=checks.all(func(check):return check.passed)
	write_evidence("res://verification/indexed-leg-rail.json",{"scope":"mechanical route; construction supplied through model; no walking/access acceptance","checks":checks})
	print("INDEXED_LEG_RAIL ","PASS " if passed else "FAIL ",checks.size()," checks")
	game.free();quit(0 if passed else 1)

func run() -> void:
	if not await start("left_leg_build"):finish();return
	if not gantry_front("upper",true):finish();return
	if not await deliver_foot("foot"):finish();return
	carrier.request("advance");carrier.physics(1);carrier.request("stop")
	for stage in range(3):
		if not command(carrier,"advance"):finish();return
	expect(game.model.assemblies.foot.parent=="left_leg" and carrier.withdrawal==1,"foot handoff takes receiver support before carrier withdraws")
	# Rig attachments are supplied mechanical states. Commands still exercise
	# actual ownership, crane routes, premature-release rules and scene solids.
	var crane=game.equipment.get_equipment("service_crane")
	for task in ["shin","fork","spar"]:
		if task!=crane.task:
			expect(crane.request("task:"+task).is_empty(),"select "+task+" physical load")
		if not command(crane,"go:source"):finish();return
		if not command(crane,"down"):finish();return
		var rigged: Dictionary=crane.capture()
		for index in range(crane.END_IDS.size()):rigged.endpoints[crane.END_IDS[index]]={"state":"attached","point":crane.POINT_IDS[index]}
		crane.apply(rigged)
		if not command(crane,"up"):finish();return
		expect(game.model.items[crane.uid].location=="support:"+crane.support,task+" transfers rack ownership only after crane takes weight")
		if not command(crane,"go:receiver"):finish();return
		if not command(crane,"down"):finish();return
		expect(game.model.assemblies.left_leg.slots[task]==crane.uid,task+" seats the same physical identity")
		expect(crane.action_error("detach:"+crane.END_IDS[0]).contains("retaining"),task+" rejects premature crane release")
		var supplied: Array=[]
		for sid in game.runtime.definition("left_leg").slots:
			if sid not in ["shin","fork","spar"]:supplied.append(sid)
		Staging.fill(game,"left_leg",supplied)
		expect(crane.secured(),task+" structural fastening permits rig release")
		if not lock_braces("left_leg",task):finish();return
		rigged=crane.capture()
		for id in crane.END_IDS:rigged.endpoints[id]={"state":"stowed","point":""}
		crane.apply(rigged)
		if not command(crane,"up"):finish();return
		if not command(crane,"go:park"):finish();return
	expect(game.model.milestone("left_leg","structural_ready"),"model supplies structural connections for mechanical route fixture")
	expect(game.model.integrity_errors().is_empty(),"construction fixture preserves unique stock")
	if not pull_support(1) or not index_to(rail.spec.lanes.parking):finish();return
	expect(is_equal_approx(rail.index_x,22) and not rail.can_construct(),"passive leg parking clears the shared station")
	expect(not crane._receiver_error().is_empty(),"crane cannot deliver into a parked leg")
	if not index_to(rail.spec.station_x) or not pull_support(0):finish();return
	rail.set_jog("lift+");rail.physics(1);rail.set_jog("")
	expect(rail.roll_height_m>0 and rail.roll_height_m<1.25 and not rail.moving,"releasing LIFT + brakes the construction axis part way")
	if not jog(rail,"lift+") or not jog(rail,"roll+"):finish();return
	expect(is_equal_approx(rail.roll_deg,90) and is_equal_approx(rail.roll_height_m,1.25),"supported source roll uses raised axis")
	expect(not rail.action_error("lever").is_empty(),"rolled leg locks the transfer table lever")
	if not jog(rail,"roll-") or not jog(rail,"lift-"):finish();return
	expect(rail.can_construct(),"neutral roll and lowered axis lock the construction pose")
	if not deliver("left"):finish();return
	expect(game.model.assemblies.left_leg.parent=="pelvis","supported leg seats at its actual hip destination")
	expect(game.assembly_node("left_leg").global_position.is_equal_approx(Vector3(11.9,1.4,26)),"mounted leg matches raised datum without pose jump")
	var access=game.equipment.get_equipment("workshop_access")
	expect(access.front_closed("lower"),"explicitly closed lower front stays closed after docking")
	expect(not rail.action_error("clamps").is_empty(),"unretained leg rejects holder release")
	var locks=game.equipment.get_equipment("captive_controls")
	Staging.fill(game,"pelvis",game.runtime.definition("pelvis").slots.keys().filter(func(sid):return not sid.begins_with("cylinder_")))
	expect(game.model.milestone("pelvis","left_ring_secured") and not rail.action_error("clamps").is_empty(),"complete ring and stop cage alone cannot release pose support")
	expect(game.model.carry_item("PV-200__003").is_empty(),"a compatible cartridge can be selected out of source order")
	expect(not game.model.placement_error("pelvis","cylinder_1/upper_pin","PV-200__003").is_empty(),"a cartridge cannot substitute for an eye pin")
	expect(game.model.install("pelvis","cylinder_1","PV-200__003").ok,"third physical cartridge fits first destination")
	game.components.sync("pelvis")
	expect(not locks.request("left_hip_1").is_empty(),"cartridge parking does not permit neutral locking before pins")
	for pair in [["upper","PV-P60220__006"],["lower","PV-P60220__005"]]:
		expect(game.model.carry_item(pair[1]).is_empty() and game.model.install("pelvis","cylinder_1/"+pair[0]+"_pin",pair[1]).ok,"compatible eye pins retain their consumed identities")
	Staging.fill(game,"pelvis")
	expect(not rail.action_error("clamps").is_empty(),"complete mounting hardware still requires the three neutral locks")
	for id in locks.specs:
		if not id.begins_with("left_"):continue
		expect(locks.request(id).is_empty(),"operate captive lock with both eye pins and holder support")
	expect(rail.retention_state()=="complete","hardware and neutral locks secure the leg")
	expect(locks.undo("pelvis").get("handled",false),"locked cylinder prevents connection undo")
	expect(rail.request("clamps").is_empty(),"clamps switch starts supported release")
	rail.physics(1)
	expect(rail.release>0 and rail.release<5 and rail.undo("pelvis").get("handled",false),"partial contact release rejects retention undo")
	if not settle(rail):expect(false,"clamps finish their requested release: "+rail.blocked_reason);finish();return
	expect(not rail.engaged and rail.release==5,"holder withdraws/compacts/shifts before empty return")
	expect(not locks.action_error("left_hip_1").is_empty(),"released holder prevents neutral lock removal")
	var mounted: Transform3D=game.assembly_node("left_leg").global_transform
	if not empty_home(mounted):finish();return
	expect(not rail.engaged and rail.at_home(),"empty holder returns and restores at common station")
	if not command(rail,"clamps") or not index_to(rail.spec.lanes.left):finish();return
	for action in ["travel+","rise+"]:
		if not jog(rail,action):finish();return
		expect(game.assembly_node("left_leg").global_transform.is_equal_approx(mounted),"local reacquisition leaves the retained leg stationary")
	if not command(rail,"clamps"):finish();return
	expect(rail.supports_seated("left_leg"),"returned empty holder reacquires the mounted leg for local correction")
	expect(not rail.undo("pelvis").get("handled",false),"retention undo is available only after reacquisition")
	if not command(rail,"clamps") or not empty_home(mounted):finish();return
	for phase in range(3):
		if not command(carrier,"return"):finish();return
	expect(carrier.path==0 and carrier.withdrawal==0 and not carrier.carrying(),"empty carrier returns without moving retained left foot")
	if not command(rail,"next_leg"):finish();return
	expect(rail.active_assembly=="right_leg" and rail.can_construct(),"clear single holder selects independent right build")
	if not await deliver_foot("right_foot"):finish();return
	for phase in range(3):
		if not command(carrier,"advance"):finish();return
	expect(not rail.request("next_leg").is_empty(),"occupied right build cannot be replaced by selecting left")
	for key in ["shin","fork","spar"]:
		if not command(crane,"task:right_"+key):finish();return
		if not command(crane,"go:source") or not command(crane,"down"):finish();return
		supply_rig(crane,true)
		if not command(crane,"up") or not command(crane,"go:receiver") or not command(crane,"down"):finish();return
		Staging.fill(game,"right_leg",game.runtime.definition("right_leg").slots.keys().filter(func(sid):return sid not in ["shin","fork","spar"]))
		expect(crane.secured(),"right "+key+" mounted using separate physical stock")
		if not lock_braces("right_leg",key):finish();return
		supply_rig(crane,false)
		if not command(crane,"up") or not command(crane,"go:park"):finish();return
	if not deliver("right"):finish();return
	expect(game.assembly_node("left_leg").global_transform.is_equal_approx(mounted),"right delivery leaves first fitted leg stationary")
	expect(game.assembly_node("right_leg").global_position.is_equal_approx(Vector3(14.1,1.4,26)),"right delivery seats at independent mirrored socket")
	Staging.fill(game,"pelvis")
	for id in locks.specs:
		if id.begins_with("right_"):expect(locks.request(id).is_empty(),"right hip locks require its own pins and supported holder")
	settle(game.equipment.get_equipment("workshop_access"))
	if not command(rail,"clamps") or not empty_home(game.assembly_node("right_leg").global_transform):finish();return
	for phase in range(3):
		if not command(carrier,"return"):finish();return
	expect(carrier.path==0 and carrier.withdrawal==0 and not carrier.carrying(),"empty carrier returns without moving retained right foot")
	if not gantry_front("upper",false):finish();return
	finish()

## The player's delivery: pull support, throw lever, travel, open the lower
## front and hold RISE until it seats. Only the player closes the front afterward.
func deliver(side: String) -> bool:
	if not pull_support(1) or not index_to(rail.spec.lanes[side]):return false
	if not jog(rail,"travel+") or not gantry_front("lower",true):return false
	if not jog(rail,"rise+"):return false
	return gantry_front("lower",false) and rail.supports_seated(side+"_leg")

func lock_braces(owner: String, task: String) -> bool:
	var braces=game.equipment.get_equipment("joint_restraints")
	for fixture in braces.fixtures:
		if fixture.owner==owner and fixture.spec.milestone==task+"_secured":
			if not command(braces,"engage:"+fixture.id):return false
	return true

## The released holder lies down, travels home, indexes and extends; the
## retained leg never moves.
func empty_home(mounted: Transform3D) -> bool:
	var leg: String=rail.active_assembly
	for action in ["rise-","travel-"]:
		if not jog(rail,action):return false
		expect(game.assembly_node(leg).global_transform.is_equal_approx(mounted),"empty "+action+" leaves the retained leg stationary")
	return index_to(rail.spec.station_x) and command(rail,"clamps") and rail.at_home()

func deliver_foot(owner: String) -> bool:
	var crane=game.equipment.get_equipment("service_crane")
	if not command(crane,"task:"+owner) or not command(crane,"go:source") or not command(crane,"down"):return false
	expect(crane.required_ends==4 and crane.load_body==game.runtime.node(owner),"prepared-foot task uses four ends and its existing assembly body")
	supply_rig(crane,true)
	var incomplete: Dictionary=crane.capture();incomplete.endpoints[crane.END_IDS.back()]={"state":"stowed","point":""}
	crane.apply(incomplete)
	expect(not crane.request("up").is_empty(),"three of four ends cannot lift prepared foot")
	supply_rig(crane,true)
	if not crane.request("up").is_empty():return false
	crane.physics(1.7);crane.request("stop")
	if not command(crane,"resume") or not command(crane,"go:receiver") or not command(crane,"down"):return false
	expect(game.model.assemblies[owner].location=="support:foot_carrier","crane transfers prepared assembly onto sole carrier only after contact")
	expect(carrier.assembly_id==owner,"shared carrier receives the correct physical foot identity")
	supply_rig(crane,false)
	return command(crane,"up") and command(crane,"go:park")
