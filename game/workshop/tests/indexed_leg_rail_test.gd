extends "res://tests/kit/harness.gd"
## Supported motion test using the actual scene/stock/solids. Construction is
## explicitly supplied via model staging; no walk/aim/reach acceptance is run.
var game: Node
var rail: Node
var carrier: Node
const Store = preload("res://scripts/save_store.gd")

func _initialize() -> void:call_deferred("run")

func settle(controller: Node, limit: int = 1600) -> bool:
	for tick in range(limit):
		if not controller.moving:return controller.blocked_reason.is_empty()
		game.equipment.get_equipment("workshop_access").physics(.1)
		game.equipment.get_equipment("rail_gates").physics(.1)
		controller.physics(.1)
	return false

func command(controller: Node, action: String) -> bool:
	var error: String=controller.request(action)
	expect(error.is_empty(),controller.equipment_id+" accepts "+action+": "+error)
	if not error.is_empty():return false
	var okay=settle(controller)
	if not okay:
		print("MECHANICAL_STOP ",controller.capture())
		for id in game.runtime.nodes:print("ASSEMBLY_BODY ",id," ",game.runtime.node(id).name)
	expect(okay,controller.equipment_id+" completes "+action+": "+controller.blocked_reason)
	return okay

func finish() -> void:
	var passed=checks.all(func(check):return check.passed)
	write_evidence("res://verification/indexed-leg-rail.json",{"scope":"mechanical route; construction supplied through model; no walking/access acceptance","checks":checks})
	print("INDEXED_LEG_RAIL ","PASS " if passed else "FAIL ",checks.size()," checks")
	game.free();quit(0 if passed else 1)

func reopen(label: String) -> bool:
	var snapshot: Dictionary=game.saves.capture()
	var errors: Array[String]=game.saves.validate(snapshot)
	expect(errors.is_empty(),label+" interrupted session validates: "+str(errors))
	if not errors.is_empty():return false
	var file="/tmp/indexed-leg-session-"+str(Time.get_ticks_usec())+".json"
	var fingerprint: String=game.saves.fingerprint
	var error: String=Store.write(file,fingerprint,snapshot,false)
	expect(error.is_empty(),label+" atomic file save: "+error)
	if not error.is_empty():return false
	game.free();await frames(2)
	game=await boot_profile("leg_bay_m3")
	var read: Dictionary=Store.read(file,fingerprint)
	var restored_errors: Array[String]=game.saves.validate(read.get("payload",{})) if read.ok else [str(read.get("error"))]
	var restored: bool=read.ok and restored_errors.is_empty() and game.saves.apply_snapshot(read.payload)
	expect(restored,label+" restores in a fresh scene: "+str(restored_errors))
	DirAccess.remove_absolute(file)
	if not restored:return false
	rail=game.equipment.get_equipment("leg_rail");carrier=game.equipment.get_equipment("foot_carrier")
	game.set_paused(false)
	return true

func run() -> void:
	game=await boot_profile("leg_bay_m3");rail=game.equipment.get_equipment("leg_rail");carrier=game.equipment.get_equipment("foot_carrier")
	expect(rail.can_construct() and is_equal_approx(game.assembly_node("left_leg").global_position.x,14),"empty cradle starts at shared X14 station")
	expect(not rail.request("advance").is_empty(),"incomplete structural leg cannot depart")
	if not await deliver_pelvis():finish();return
	if not await deliver_foot("foot"):finish();return
	carrier.request("advance");carrier.physics(1);carrier.request("stop")
	if not await reopen("foot raise"):finish();return
	for stage in range(3):
		if not command(carrier,"advance"):finish();return
		expect(game.saves.validate(game.saves.capture()).is_empty(),"foot phase "+str(stage)+" session validates")
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
		expect(crane.validate(rigged,game.model).is_empty(),"supplied "+task+" rigging state satisfies machinery contract")
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
		rigged=crane.capture()
		for id in crane.END_IDS:rigged.endpoints[id]={"state":"stowed","point":""}
		expect(crane.validate(rigged,game.model).is_empty(),task+" supplied rig release preserves support rules")
		crane.apply(rigged)
		if not command(crane,"up"):finish();return
		if not command(crane,"go:park"):finish();return
	expect(game.model.milestone("left_leg","structural_ready"),"model supplies structural connections for mechanical route fixture")
	expect(game.model.integrity_errors().is_empty(),"construction fixture preserves unique stock")
	if not command(rail,"park"):finish();return
	expect(is_equal_approx(rail.index_x,22) and not rail.can_construct(),"passive leg parking clears the shared station")
	expect(not crane._receiver_error().is_empty(),"crane cannot deliver into a parked leg")
	if not command(rail,"park"):finish();return
	rail.request("roll");rail.physics(1);rail.request("stop")
	if not await reopen("source roll raise"):finish();return
	if not command(rail,"advance"):finish();return
	if not command(rail,"roll"):finish();return
	expect(is_equal_approx(rail.roll,90) and is_equal_approx(rail.roll_height,1),"supported source roll uses raised axis")
	expect(not rail.request("advance").is_empty(),"rolled leg cannot index for delivery")
	if not command(rail,"return"):finish();return
	if not command(rail,"return"):finish();return
	expect(rail.can_construct(),"return locks neutral construction pose")
	for phase in range(7):
		if rail.path==3:break
		if not command(rail,"advance"):finish();return
		var errors: Array[String]=game.saves.validate(game.saves.capture())
		expect(errors.is_empty(),"holder phase validates: "+str(errors))
	expect(rail.path==3 and game.model.assemblies.left_leg.parent=="pelvis","supported leg seats at its actual hip destination")
	expect(game.assembly_node("left_leg").global_position.is_equal_approx(Vector3(11.9,1.4,26)),"mounted leg matches raised datum without pose jump")
	var access=game.equipment.get_equipment("workshop_access")
	settle(access)
	expect(access.ready_for("work"),"shared hip decks restore after docking: "+access.blocked_reason)
	expect(not rail.request("advance").is_empty(),"unretained leg rejects holder release")
	var locks=game.equipment.get_equipment("captive_controls")
	var before_locks: Dictionary=locks.capture()
	before_locks.locked.left_hip_1=true
	expect(not locks.validate(before_locks,game.model).is_empty(),"save rejects a locked missing cylinder")
	Staging.fill(game,"pelvis",game.runtime.definition("pelvis").slots.keys().filter(func(sid):return not sid.begins_with("cylinder_")))
	expect(game.model.milestone("pelvis","left_ring_secured") and not rail.request("advance").is_empty(),"complete ring and stop cage alone cannot release pose support")
	expect(game.model.carry_item("PV-200__003").is_empty(),"a compatible cartridge can be selected out of source order")
	expect(not game.model.placement_error("pelvis","cylinder_1/upper_pin","PV-200__003").is_empty(),"a cartridge cannot substitute for an eye pin")
	expect(game.model.install("pelvis","cylinder_1","PV-200__003").ok,"third physical cartridge fits first destination")
	game.components.sync("pelvis")
	expect(not locks.request("left_hip_1").is_empty(),"cartridge parking does not permit neutral locking before pins")
	for pair in [["upper","PV-P60220__006"],["lower","PV-P60220__005"]]:
		expect(game.model.carry_item(pair[1]).is_empty() and game.model.install("pelvis","cylinder_1/"+pair[0]+"_pin",pair[1]).ok,"compatible eye pins retain their consumed identities")
	Staging.fill(game,"pelvis")
	expect(not rail.request("advance").is_empty(),"complete mounting hardware still requires the three neutral locks")
	for id in locks.specs:
		if not id.begins_with("left_"):continue
		expect(locks.request(id).is_empty(),"operate captive lock with both eye pins and holder support")
	expect(rail.retention_state()=="complete","hardware and neutral locks secure the leg")
	expect(locks.undo("pelvis").get("handled",false),"locked cylinder prevents connection undo")
	rail.request("advance");rail.physics(1);rail.request("stop")
	expect(rail.undo("pelvis").get("handled",false),"partial contact release rejects retention undo")
	if not await reopen("holder withdrawal"):finish();return
	locks=game.equipment.get_equipment("captive_controls")
	if not command(rail,"advance"):finish();return
	expect(not rail.engaged and rail.release==5,"holder withdraws/compacts/shifts before empty return")
	expect(not locks.action_error("left_hip_1").is_empty(),"released holder prevents neutral lock removal")
	var unrestrained: Dictionary=game.saves.capture()
	unrestrained.world.equipment.captive_controls.locked.left_hip_2=false
	expect(not game.saves.validate(unrestrained).is_empty(),"released-holder save requires all three neutral locks")
	var mounted: Transform3D=game.assembly_node("left_leg").global_transform
	for phase in range(5):
		if rail.path==0 and rail.index_x==14 and rail.release==0:break
		if not command(rail,"return"):finish();return
		expect(game.assembly_node("left_leg").global_transform.is_equal_approx(mounted),"empty return leaves retained leg stationary")
	expect(not rail.engaged and rail.path==0 and rail.index_x==14 and rail.release==0,"empty holder returns and restores at common station")
	expect(game.saves.validate(game.saves.capture()).is_empty(),"empty holder home snapshot validates")
	for phase in range(7):
		if rail.engaged and rail.path==3:break
		if not command(rail,"advance"):finish();return
		expect(game.assembly_node("left_leg").global_transform.is_equal_approx(mounted),"local reacquisition leaves the retained leg stationary")
	expect(rail.engaged and rail.path==3 and rail.release==0,"returned empty holder reacquires the mounted leg for local correction")
	expect(not rail.undo("pelvis").get("handled",false),"retention undo is available only after reacquisition")
	if not await reopen("reacquired holder"):finish();return
	if not command(rail,"advance"):finish();return
	for phase in range(5):
		if rail.path==0 and rail.index_x==14 and rail.release==0:break
		if not command(rail,"return"):finish();return
	for phase in range(3):
		if not command(carrier,"return"):finish();return
	expect(carrier.path==0 and carrier.withdrawal==0 and not carrier.carrying(),"empty carrier returns without moving retained left foot")
	if not command(rail,"build"):finish();return
	expect(rail.active_assembly=="right_leg" and rail.can_construct(),"clear single holder selects independent right build")
	if not await deliver_foot("right_foot"):finish();return
	for phase in range(3):
		if not command(carrier,"advance"):finish();return
	expect(not rail.request("build").is_empty(),"occupied right build cannot be replaced by selecting left")
	crane=game.equipment.get_equipment("service_crane")
	for key in ["shin","fork","spar"]:
		if not command(crane,"task:right_"+key):finish();return
		if not command(crane,"go:source") or not command(crane,"down"):finish();return
		supply_rig(crane,true)
		if not command(crane,"up") or not command(crane,"go:receiver") or not command(crane,"down"):finish();return
		Staging.fill(game,"right_leg",game.runtime.definition("right_leg").slots.keys().filter(func(sid):return sid not in ["shin","fork","spar"]))
		expect(crane.secured(),"right "+key+" mounted using separate physical stock")
		supply_rig(crane,false)
		if not command(crane,"up") or not command(crane,"go:park"):finish();return
	for phase in range(7):
		if rail.path==3:break
		if not command(rail,"advance"):finish();return
		expect(game.assembly_node("left_leg").global_transform.is_equal_approx(mounted),"right delivery leaves first fitted leg stationary")
	expect(game.assembly_node("right_leg").global_position.is_equal_approx(Vector3(14.1,1.4,26)),"right delivery seats at independent mirrored socket")
	Staging.fill(game,"pelvis")
	locks=game.equipment.get_equipment("captive_controls")
	for id in locks.specs:
		if id.begins_with("right_"):expect(locks.request(id).is_empty(),"right hip locks require its own pins and supported holder")
	if not await reopen("both retained legs"):finish();return
	settle(game.equipment.get_equipment("workshop_access"))
	if not command(rail,"advance"):finish();return
	for phase in range(5):
		if rail.path==0 and rail.index_x==14 and rail.release==0:break
		if not command(rail,"return"):finish();return
	if not await reopen("second empty return"):finish();return
	if not await after_legs():finish();return
	finish()

func after_legs() -> bool:return true

func supply_rig(crane: Node, attached: bool) -> void:
	var state: Dictionary=crane.capture()
	for index in range(crane.END_IDS.size()):state.endpoints[crane.END_IDS[index]]={"state":"attached" if attached else "stowed","point":crane.POINT_IDS[index] if attached else ""}
	expect(crane.validate(state,game.model).is_empty(),"supplied magnetic-end state respects required end count and ownership")
	crane.apply(state)

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
	if not await reopen(owner+" suspended on crane"):return false
	crane=game.equipment.get_equipment("service_crane")
	if not command(crane,"resume") or not command(crane,"go:receiver") or not command(crane,"down"):return false
	expect(game.model.assemblies[owner].location=="support:foot_carrier","crane transfers prepared assembly onto sole carrier only after contact")
	expect(carrier.assembly_id==owner,"shared carrier receives the correct physical foot identity")
	supply_rig(crane,false)
	return command(crane,"up") and command(crane,"go:park")

func deliver_pelvis() -> bool:
	var fixture=game.equipment.get_equipment("module_supports")
	var crane=game.equipment.get_equipment("service_crane")
	expect(game.model.assemblies.pelvis.location=="support:bulky_fixture","pelvis starts as one prepared assembly on the bulky fixture")
	for key in ["yaw","lean"]:
		if not command(fixture,"lock:"+key):return false
	if not command(crane,"task:pelvis") or not command(crane,"go:source") or not command(crane,"down"):return false
	supply_rig(crane,true)
	if not crane.request("up").is_empty():return false
	crane.physics(.1);settle(game.equipment.get_equipment("workshop_access"));crane.physics(.3);crane.request("stop")
	expect(fixture.source_release>0 and fixture.source_release<1 and game.model.assemblies.pelvis.location=="support:bulky_fixture","four ends take weight while source clamps open before ownership changes")
	if not await reopen("pelvis source contact"):return false
	crane=game.equipment.get_equipment("service_crane");fixture=game.equipment.get_equipment("module_supports")
	if not command(crane,"resume") or not command(crane,"go:receiver") or not command(crane,"down"):return false
	var access=game.equipment.get_equipment("workshop_access")
	expect(settle(access) and access.ready_for("work"),"upper work platforms restore after pelvis seating: "+access.blocked_reason)
	expect(game.model.assemblies.pelvis.location=="support:pelvis_gantry" and not fixture.support_secured(),"bearing contact seats pelvis without automatic hold-down retention")
	expect(crane.action_error("detach:"+crane.END_IDS[0]).contains("four"),"unclamped gantry rejects crane release")
	for index in range(4):
		if index==0:
			fixture.request("jaw:0");fixture.physics(.4);fixture.request("stop")
			if not await reopen("gantry jaw closing"):return false
			crane=game.equipment.get_equipment("service_crane");fixture=game.equipment.get_equipment("module_supports")
			if not command(fixture,"jaw:0"):return false
			continue
		if not command(fixture,"jaw:"+str(index)):return false
	expect(fixture.support_secured(),"four closed jaws and both waist pins secure the pelvis")
	if not await reopen("pelvis retained at gantry"):return false
	crane=game.equipment.get_equipment("service_crane")
	supply_rig(crane,false)
	return command(crane,"up") and command(crane,"go:park")
