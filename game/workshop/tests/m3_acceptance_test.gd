extends "res://tests/kit/m3_journey.gd"
## Normal M3 opening and actual walked forward construction through holder release.
## Historical reverse helpers remain dormant; the default gate is forward only.
var foundation_only = false
var main_only = false
var from_played_fork = false
var from_played_half = false
var from_played_full_ring = false
var from_played_recovery = false
var from_played_fork_recovery = false
var recovery_count = 0
var lift_resume_covered = {"up":false,"ground":false}

func input_hashes() -> Dictionary:
	var hashes: Dictionary = {}
	var paths: Array[String] = ["tests/m3_acceptance_test.gd"]
	for directory in ["scripts","tests/kit","assets"]:
		for filename in DirAccess.get_files_at("res://"+directory):
			if filename.ends_with(".gd") or filename.ends_with(".json") or filename.ends_with(".glb"):
				paths.append(directory+"/"+filename)
	for path in paths:
		hashes[path] = FileAccess.get_sha256("res://"+path)
	return hashes

func opening() -> void:
	expect(game.profile.id == "leg_bay_m3" and game.profile.trial == "m3","Normal M3 profile is active")
	expect(game.model.assemblies.left_leg.slots.values().all(func(uid):return uid.is_empty()) and game.model.assemblies.pelvis.slots.values().all(func(uid):return uid.is_empty()),"M3 opens with every leg and pelvis installation slot empty")
	var prepared = 0
	for item in game.model.items.values():
		if item.owner in ["foot","pad_1","pad_2","pitch"]:prepared += 1
	expect(prepared==135 and game.model.milestone("foot","complete"),"Only supplied construction is the complete 135-identity foot")
	expect(game.model.items.size()==175,"M3 supplies exactly 135 prepared-foot identities and 40 remaining physical components")
	expect(game.model.assemblies.foot.location=="support:foot_carrier","Complete foot begins on actual dispatch carrier")
	audit_manuals()

func foot_forward() -> bool:
	if not await walk(Vector3(8.5,0,7.3),"foot dispatch panel"):return false
	var carrier = game.equipment.get_equipment("foot_carrier")
	if not await control(carrier,"advance"):return false
	await frames(30)
	if not await control(carrier,"stop"):return false
	if not await checkpoint("foot_raise_stopped"):return false
	carrier = game.equipment.get_equipment("foot_carrier")
	if not await control(carrier,"advance"):return false
	await frames(30)
	if not await checkpoint("foot_raise_in_progress"):return false
	carrier = game.equipment.get_equipment("foot_carrier")
	if not await settle(carrier):expect(false,"Foot guided carrier route completes");return false
	if not await control(carrier,"advance"):return false
	await frames(60)
	if not await checkpoint("foot_turnover_in_progress"):return false
	carrier = game.equipment.get_equipment("foot_carrier")
	if not await settle(carrier):expect(false,"Foot indexed turnover completes");return false
	expect(game.model.assemblies.left_leg.slots.foot == "foot","Guided turnover installs the same foot on horizontal receiving fixture")
	return game.model.assemblies.left_leg.slots.foot == "foot"

func rig_current(receiver: bool = false) -> bool:
	var crane = game.equipment.get_equipment("service_crane")
	var x = 10.7 if receiver else 6.6
	for index in range(2):
		var magnet = ["magnet_a","magnet_b"][index]
		var point_id = ["load_near","load_far"][index]
		var point: Vector3 = crane.point_position(point_id)
		if not await walk(Vector3(x,0,point.z),"magnet work "+magnet):return false
		if not await control(crane,"pick:"+magnet):return false
		if not await control(crane,"attach:"+point_id,true):return false
		expect(crane.attached_count()==index+1,"Real magnet engaged: "+point_id)
		if index==0:
			if not await checkpoint(crane.task+"_partial_rigging"):return false
			crane = game.equipment.get_equipment("service_crane")
	return crane.attached_count()==2

func source_and_deliver(task: String) -> bool:
	if not await to_console():return false
	var crane = game.equipment.get_equipment("service_crane")
	if crane.get("task") != task:
		if not await console_action("task:"+task):return false
	if not crane.raised:
		if not await command("up"):return false
	if crane.station!="source":
		if not await command("go:source"):return false
	if not await command("down"):return false
	tap(KEY_Q)
	if not await walk(Vector3(6.4,0,20.5),"west source entry"):return false
	if not await walk(Vector3(6.4,0,crane.source_pose.origin.z-.8),"source rack west aisle"):return false
	if not await rig_current():return false
	if not await checkpoint(task+"_fully_rigged_source"):return false
	crane = game.equipment.get_equipment("service_crane")
	if not await walk(Vector3(6.4,0,20.5),"rigged source exit"):return false
	if not await to_console():return false
	if not await command("up"):return false
	if not await console_action("go:receiver"):return false
	await frames(35)
	if not await checkpoint(task+"_crane_transport"):return false
	crane = game.equipment.get_equipment("service_crane")
	if not await settle(crane):expect(false,"Loaded crane reaches "+task+" receiver");return false
	if not await command("down"):return false
	tap(KEY_Q)
	expect(game.model.items[crane.uid].owner=="left_leg" and crane.assisting,"Supported crane seats "+task+" with one physical owner")
	audit_readiness("left_leg")
	return game.model.items[crane.uid].owner=="left_leg"

func ankle_fasteners() -> bool:
	for kind in ["lg-w36","lg-m36-90"]:
		if not await collect(kind,4):return false
	if not await stock_to_fixture():return false
	var slots: Array = game.equipment.get_equipment("service_crane").fastener_slots
	var work_side = -1.0
	var first_point: Vector3 = game.components.slot_point("left_leg",slots[0])
	if not await walk(Vector3(FIXTURE_WEST.x,0,first_point.z+.65),"ankle west aisle past rail jaw"):return false
	for sid in slots:
		var point: Vector3 = game.components.slot_point("left_leg",sid)
		var side = -1.0 if point.x<11.9 else 1.0
		if side!=work_side:
			if not await walk(Vector3(10.5,0,20.3),"ankle far cross aisle west"):return false
			if not await walk(Vector3(13.1,0,20.3),"ankle far cross aisle east"):return false
			if not await walk(Vector3(13.1,0,point.z+.65),"ankle east work aisle"):return false
			work_side=side
		if not await walk(Vector3(point.x+side*.65,0,point.z+.65),"ankle work face "+sid):return false
		if not await install_slot("left_leg",sid):return false
		if sid==slots[0]:
			if not await checkpoint("shin_partial_fastening"):return false
	return true

func undo_slots(owner: String, count: int) -> bool:
	for index in range(count):
		var before: int = game.model.assemblies[owner].history.size()
		tap(KEY_Z)
		var undone: bool = game.model.assemblies[owner].history.size()==before-1
		expect(undone,"Ordinary Z reverses "+owner+" history: "+game.hud.toast_label.text)
		if not undone:return false
	return true

func return_current_to_source() -> bool:
	var crane = game.equipment.get_equipment("service_crane")
	if game.player.global_position.x>11.9:
		if not await walk(Vector3(13.2,0,20.5),"receiver east exit around shin"):return false
	if not await walk(Vector3(10.5,0,20.5),"receiver west exit"):return false
	if not await to_console():return false
	if not await command("up"):return false
	if not await command("go:source"):return false
	if not await command("down"):return false
	tap(KEY_Q)
	if not await walk(Vector3(6.4,0,20.5),"source return west entry"):return false
	for magnet in ["magnet_a","magnet_b"]:
		var point_id = "load_near" if magnet=="magnet_a" else "load_far"
		var point: Vector3 = crane.point_position(point_id)
		if not await walk(Vector3(6.6,0,point.z),"source released magnet "+magnet):return false
		if not await control(crane,"detach:"+magnet):return false
		tap(KEY_Q)
	expect(game.model.items[crane.uid].location=="support:"+crane.source_support and crane.attached_count()==0,"Supported source recovery keeps the original "+crane.uid)
	return true

func foundation() -> bool:
	if not await foot_forward():return false
	if not await source_and_deliver("shin"):return false
	if not await ankle_fasteners():return false
	expect(game.model.milestone("left_leg","shin_secured"),"All four ordinary ankle pairs secure shin")
	if not await checkpoint("shin_secured"):return false
	# V opens the actual aimed build through the normal desktop binding.
	look(game.components.slot_point("left_leg","ankle/H-36090__004"));await frames(3);game.automation.refresh_target();tap(KEY_V)
	expect(game.hud.manual_id=="left_leg","V selects actual leg manual for normal undo")
	if not await undo_slots("left_leg",8):return false
	if not await return_current_to_source():return false
	if not await checkpoint("shin_recovered_at_source"):return false
	if not await walk(Vector3(6.4,0,4.5),"returned shin west aisle to dispatch front"):return false
	if not await walk(Vector3(8.5,0,4.5),"dispatch south cross aisle"):return false
	if not await walk(Vector3(8.5,0,7.3),"foot panel for supported return"):return false
	var carrier = game.equipment.get_equipment("foot_carrier")
	if not await control(carrier,"return"):return false
	if not await settle(carrier):expect(false,"Carrier supported return completes");return false
	if not await control(carrier,"return"):return false
	if not await settle(carrier):expect(false,"Carrier lowers complete foot to dispatch");return false
	expect(game.model.assemblies.foot.location=="support:foot_carrier" and game.model.assemblies.left_leg.slots.foot.is_empty(),"Same prepared foot returns to dispatch after supported shin recovery")
	return game.model.assemblies.foot.location=="support:foot_carrier"

func release_and_park() -> bool:
	var crane = game.equipment.get_equipment("service_crane")
	if game.player.global_position.x>11.9:
		if not await walk(Vector3(13.2,0,20.5),"secured load east exit"):return false
		if not await walk(Vector3(10.5,0,20.5),"secured load far cross aisle"):return false
	for magnet in ["magnet_a","magnet_b"]:
		var point_id = "load_near" if magnet=="magnet_a" else "load_far"
		var point: Vector3 = crane.point_position(point_id)
		if not await walk(Vector3(10.7,0,point.z),"secured receiver magnetic end "+magnet):return false
		if not await control(crane,"detach:"+magnet):return false
		tap(KEY_Q)
	expect(crane.attached_count()==0 and crane.hand_payload().is_empty(),"Fastened component releases real handling endpoints")
	if not await walk(Vector3(10.5,0,20.5),"receiver west exit"):return false
	if not await to_console():return false
	if not await command("up"):return false
	if not await command("go:park"):return false
	tap(KEY_Q)
	return true

func carry_and_fit(sid: String) -> bool:
	var kind: String = game.model.slot_definition("left_leg",sid).accepts
	if not await collect(kind,1):return false
	var point: Vector3 = game.components.slot_point("left_leg",sid)
	var side = -1.0 if point.x<11.9 else 1.0
	if not await stock_to_fixture(side>0):return false
	var work = Vector3(point.x+side*.80,0,point.z)
	if sid=="main_input":work=Vector3(point.x+1.05,0,point.z+2.10)
	if sid=="axle":work=Vector3(point.x-1.40,0,point.z)
	if not await walk(work,"receiving face "+sid):return false
	return await install_slot("left_leg",sid)

func beam_fasteners() -> bool:
	for kind in ["lg-w24","lg-m24-100"]:
		if not await collect(kind,4):return false
	if not await stock_to_fixture():return false
	for pair in range(1,5):
		if pair==3:
			if not await route([FIXTURE_WEST,FIXTURE_EAST],"beam far cross aisle"):return false
		for family in ["washer","bolt"]:
			var sid = "fork/%s_%d"%[family,pair]
			var point: Vector3 = game.components.slot_point("left_leg",sid)
			if not await walk(Vector3(point.x+(-.65 if point.x<11.9 else .65),0,point.z+.18),"beam fastening "+sid):return false
			if not await install_slot("left_leg",sid):return false
			if pair==1 and family=="washer":
				if not await checkpoint("spar_partial_fastening"):return false
	return true

func horizontal_forward() -> bool:
	if not from_played_fork:
		if not await foot_forward():return false
		if not await source_and_deliver("shin"):return false
		if not await ankle_fasteners():return false
		if not await release_and_park():return false
		# Knee work before harness proves these branches remain independent.
		for sid in ["bearing_2","bearing_1","thrust_2","thrust_1"]:
			if not await carry_and_fit(sid):return false
		if not await source_and_deliver("fork"):return false
		for sid in ["axle","cap"]:
			if not await carry_and_fit(sid):return false
		for kind in ["lg-w12","lg-m12-50"]:
			if not await collect(kind,2):return false
		var cap_point: Vector3 = game.components.slot_point("left_leg","cap")
		if not await stock_to_fixture(true):return false
		if not await walk(Vector3(cap_point.x+.8,0,cap_point.z),"axle-cap fastening face"):return false
		for sid in ["cap/washer_1","cap/screw_1","cap/washer_2","cap/screw_2"]:
			if not await install_slot("left_leg",sid):return false
		if not await checkpoint("fork_axle_cap_secured"):return false
	if not await release_and_park():return false
	if not await carry_and_fit("main_input"):return false
	if not await source_and_deliver("spar"):return false
	if not await beam_fasteners():return false
	if not await checkpoint("spar_fully_fastened"):return false
	if not await release_and_park():return false
	expect(game.model.milestone("left_leg","structural_ready"),"Actual ordinary construction completes all horizontal structural slots")
	audit_readiness("left_leg")
	return game.model.milestone("left_leg","structural_ready")

func rail_action(action: String, checkpoint_name: String = "") -> bool:
	var rail = game.equipment.get_equipment("leg_rail")
	if not await control(rail,action,true):return false
	if not checkpoint_name.is_empty():
		await frames(30)
		if not await checkpoint(checkpoint_name):return false
		rail = game.equipment.get_equipment("leg_rail")
	var stopped = await settle(rail)
	expect(stopped,"Rail completes "+action)
	if not stopped:await checkpoint("blocked-rail-"+action)
	return stopped

func rail_to_pelvis() -> bool:
	if not await route([Vector3(6.85,0,21.9),JUNCTION,Vector3(8.65,0,20.5),Vector3(8.65,0,11.4)],"console to rail home controls"):return false
	if not await walk(Vector3(8.3,0,11.4),"rail source controls"):return false
	if not await control(game.equipment.get_equipment("leg_rail"),"advance"):return false
	await frames(30)
	if not await control(game.equipment.get_equipment("leg_rail"),"stop",true):return false
	if not await checkpoint("loaded_rail_stopped"):return false
	if not await control(game.equipment.get_equipment("leg_rail"),"advance"):return false
	if not await walk(Vector3(STOCK.x,0,11.4),"rail walking west aisle"):return false
	if not await to_bay_panel():return false
	if not await settle(game.equipment.get_equipment("leg_rail")):expect(false,"Loaded rail reaches final bay");return false
	for label in ["loaded_rail_tilt","loaded_rail_docking"]:
		if not await rail_action("advance",label):return false
	expect(game.model.assemblies.left_leg.parent=="pelvis","Ordinary travel/tilt/docking mounts the same prepared left leg")
	return game.model.assemblies.left_leg.parent=="pelvis"

func lift_move(action: String) -> bool:
	var lift = game.equipment.get_equipment("hip_lift")
	if not await control(lift,action,true):return false
	var payload: bool = game.equipment.get_equipment("lift_shelf").occupants().any(func(uid):return not uid.is_empty())
	if payload and not lift_resume_covered[action]:
		await frames(30)
		expect(lift.moving and absf(game.player.global_position.y-lift.height)<.12,"Moving lift actually carries the shelved half and passenger: "+action)
		if not await checkpoint("lift_"+action+"_motion"):return false
		lift_resume_covered[action]=true
		lift=game.equipment.get_equipment("hip_lift")
	var stopped = await settle(lift)
	var arrived: bool = is_equal_approx(lift.height,8.4 if action=="up" else .15)
	expect(stopped and arrived,"Passenger lift reaches actual "+action+" stop")
	return stopped and arrived

func ring_forward(sid: String) -> bool:
	for kind in ["lg-w24","pv-m24-140"]:
		if not await collect(kind,2):return false
	if not await collect("pv-ring-half",1):return false
	var uid: String = game.model.held_item()
	if not await to_ramp_front():return false
	if not await walk(lift_center(),"board personnel lift with "+uid):return false
	var shelf = game.equipment.get_equipment("lift_shelf")
	if not await control(shelf,"store",true):return false
	expect(shelf.occupants().has(uid) and not game.model.hands_occupied(),"Finite shelf takes just this two-hand half "+uid)
	if not await checkpoint(sid+"_shelved_ground"):return false
	if not await lift_move("up"):return false
	shelf = game.equipment.get_equipment("lift_shelf")
	if not await control(shelf,"take:0"):return false
	if not await walk(Vector3(10.4,8.4,25.4),"hip work corner for "+sid):return false
	if not await select_build("pelvis"):return false
	if not await install_slot("pelvis",sid):return false
	expect(game.model.assemblies.pelvis.slots[sid]==uid,"Ring destination retains consumed identity "+uid)
	if not await checkpoint(sid+"_seated_before_hardware"):return false
	var pairs = [3,4] if sid=="ring_1" else [1,2]
	for pair in pairs:
		for family in ["washer","bolt"]:
			if not await install_slot("pelvis","ring/%s_%d"%[family,pair]):return false
			if pair==pairs[0] and family=="washer":
				if not await checkpoint(sid+"_partial_fastening"):return false
	if not await checkpoint(sid+"_secured"):return false
	audit_readiness("pelvis")
	return await lower_and_disembark()

func lower_and_disembark() -> bool:
	if not await walk(lift_center(),"half journey return onboard lift"):return false
	if not await lift_move("ground"):return false
	if not await walk(RAMP_FRONT,"disembark after retaining-half lift journey"):return false
	return true

func holder_round_trip() -> bool:
	if not await to_bay_panel():return false
	var leg: Node3D = game.runtime.node("left_leg")
	var stationary: Transform3D = leg.global_transform
	if not await rail_action("advance","holder_releasing"):return false
	expect(not game.equipment.get_equipment("leg_rail").engaged,"Full ring permits physical holder release")
	if not await select_build("pelvis"):return false
	var history_count: int = game.model.assemblies.pelvis.history.size()
	tap(KEY_Z)
	expect(game.model.assemblies.pelvis.history.size()==history_count,"Departed support blocks first retaining-hardware undo")
	for index in range(3):
		if not await rail_action("return","empty_holder_return_"+str(index)):return false
		expect(game.runtime.node("left_leg").global_transform.is_equal_approx(stationary),"Mounted leg stays stationary throughout empty holder return stage "+str(index))
	for index in range(3):
		if not await rail_action("advance","empty_holder_advance_"+str(index)):return false
		expect(game.runtime.node("left_leg").global_transform.is_equal_approx(stationary),"Mounted leg stays stationary throughout empty holder advance stage "+str(index))
	# Docking an empty holder reacquires real jaw contact automatically.
	expect(game.equipment.get_equipment("leg_rail").engaged,"Empty holder physically reacquires stationary leg before retention undo")
	return game.equipment.get_equipment("leg_rail").engaged

func ring_reverse(sid: String) -> bool:
	if not await to_ramp_front():return false
	if not await walk(lift_center(),"board empty lift for retention recovery"):return false
	if not await lift_move("up"):return false
	if not await walk(Vector3(10.4,8.4,25.4),"retention recovery work corner"):return false
	if not await select_build("pelvis"):return false
	var uid: String = game.model.assemblies.pelvis.slots[sid]
	if not await undo_slots("pelvis",5):return false
	expect(game.model.held_item()==uid,"Ordinary supported undo puts the same half into hands: "+uid)
	return await finish_recovered_half(sid,uid)

func finish_recovered_half(sid: String, uid: String, already_stored: bool = false) -> bool:
	if not await walk(lift_center(),"return undone half to finite shelf"):return false
	if not already_stored:
		if not await control(game.equipment.get_equipment("lift_shelf"),"store",true):return false
	var stored: bool = game.equipment.get_equipment("lift_shelf").occupants().has(uid) and not game.model.hands_occupied()
	expect(stored,"Ordinary shelf store transfers the exact recovered half out of hands: "+uid)
	if not stored:
		print("M3_RECOVERY_SHELF_REFUSAL ",game.hud.toast_label.text," held=",game.components.held_body.global_transform if is_instance_valid(game.components.held_body) else Transform3D.IDENTITY," lift=",game.equipment.get_equipment("hip_lift").capture()," shelf=",game.equipment.get_equipment("lift_shelf").capture())
		await checkpoint(sid+"_failed_recovery_store")
		return false
	if not await checkpoint(sid+"_recovery_on_shelf"):return false
	if not await lift_move("ground"):return false
	if not await control(game.equipment.get_equipment("lift_shelf"),"take:0"):return false
	if not await walk(Vector3(9.6,0,21.7),"disembark recovered half"):return false
	if not await walk(Vector3(9.6,0,20.7),"carry recovered half clear of boarding route"):return false
	look(Vector3(9.6,.3,19.7));await frames(80);tap(KEY_Q);await frames(30)
	expect(game.model.items[uid].location=="loose","Recovered original half becomes ordinary ground stock: "+uid)
	return game.model.items[uid].location=="loose"

func loaded_return() -> bool:
	if not await to_bay_panel():return false
	for index in range(3):
		if not await rail_action("return","loaded_recovery_"+str(index)):return false
	expect(game.model.assemblies.left_leg.parent.is_empty() and game.model.assemblies.left_leg.location=="support:m2_leg_rail","Removed retention permits supported complete leg return home")
	return game.model.assemblies.left_leg.parent.is_empty()

func reacquire(task: String) -> bool:
	if not await to_console():return false
	var crane = game.equipment.get_equipment("service_crane")
	if crane.task != task:
		if not await console_action("task:"+task):return false
	if not await command("go:receiver"):return false
	if not await command("down"):return false
	tap(KEY_Q)
	if not await walk(Vector3(10.5,0,20.5),"installed load reacquisition aisle"):return false
	if not await rig_current(true):return false
	if not await checkpoint(task+"_installed_reacquisition"):return false
	if not await select_build("left_leg"):return false
	return true

func undo_hand_component(sid: String) -> bool:
	var expected_uid: String = game.model.assemblies.left_leg.slots[sid]
	var point: Vector3 = game.components.slot_point("left_leg",sid)
	var side = -1.0 if point.x<11.9 else 1.0
	if game.player.global_position.x>11.9:
		if not await walk(Vector3(13.3,0,20.5),"recovery east aisle for "+sid):return false
	elif game.player.global_position.x<8:
		if not await walk(Vector3(6.85,0,21.9),"recovery console exit for "+sid):return false
	if not await walk(Vector3(10.8,0,20.5),"recovery far cross aisle for "+sid):return false
	if side>0:
		if not await walk(Vector3(13.3,0,20.5),"recovery receiving east side for "+sid):return false
	var work = Vector3(point.x+side*.80,0,point.z)
	if sid=="main_input":work=Vector3(point.x+1.05,0,point.z+2.10)
	if not await walk(work,"ordinary undo receiving face "+sid):return false
	if not await undo_slots("left_leg",1):return false
	var uid: String = game.model.held_item()
	expect(not expected_uid.is_empty() and uid==expected_uid,"Supported undo returns the exact installed "+sid+" identity: "+expected_uid)
	if uid!=expected_uid or uid.is_empty():return false
	var exit_x = 13.3 if side>0 else 10.5
	if not await walk(Vector3(exit_x,0,20.5),"carry recovered "+sid+" clear of work face"):return false
	if not await walk(Vector3(15.7+float(recovery_count)*.65,0,20.5),"ground recovery staging clear of leg routes"):return false
	recovery_count += 1
	look(game.player.global_position+Vector3(0,.2,1.5));await frames(80);tap(KEY_Q);await frames(30)
	expect(game.model.items[uid].location=="loose","Ordinary Q preserves recovered component identity "+uid)
	return game.model.items[uid].location=="loose"

func park_from_source() -> bool:
	if not await walk(Vector3(6.4,0,20.5),"recovered source exit"):return false
	if not await to_console():return false
	if not await command("up"):return false
	if not await command("go:park"):return false
	tap(KEY_Q)
	return true

func structural_reverse() -> bool:
	if not await reacquire("spar"):return false
	if not await undo_slots("left_leg",8):return false
	if not await return_current_to_source():return false
	if not await park_from_source():return false
	if not await undo_hand_component("main_input"):return false
	if not await reacquire("fork"):return false
	return await reverse_knee_and_lower()

func reverse_knee_and_lower() -> bool:
	if not await undo_slots("left_leg",4):return false
	if not await undo_hand_component("cap"):return false
	if not await undo_hand_component("axle"):return false
	if not await return_current_to_source():return false
	if not await park_from_source():return false
	for sid in ["thrust_1","thrust_2","bearing_1","bearing_2"]:
		if not await undo_hand_component(sid):return false
	if not await reacquire("shin"):return false
	if not await undo_slots("left_leg",8):return false
	if not await return_current_to_source():return false
	if not await checkpoint("all_three_crane_loads_recovered"):return false
	if not await walk(Vector3(6.4,0,4.5),"final recovery west aisle to dispatch front"):return false
	if not await walk(Vector3(8.5,0,4.5),"final dispatch south cross aisle"):return false
	if not await walk(Vector3(8.5,0,7.3),"complete foot recovery dispatch panel"):return false
	for index in range(2):
		var carrier = game.equipment.get_equipment("foot_carrier")
		if not await control(carrier,"return"):return false
		if not await settle(carrier):return false
	expect(game.model.assemblies.left_leg.slots.values().all(func(uid):return uid.is_empty()),"Supported reverse empties every leg installation slot")
	expect(game.model.integrity_errors().is_empty(),"Complete ordinary journey preserves all physical identities and single ownership")
	if not game.model.assemblies.left_leg.slots.values().all(func(uid):return uid.is_empty()):return false
	return await checkpoint("complete_supported_recovery")

func complete_journey() -> bool:
	if from_played_fork_recovery:
		recovery_count=1
		if not await select_build("left_leg"):return false
		return await reverse_knee_and_lower()
	if from_played_recovery:
		var held_uid: String = game.model.held_item()
		var stored_uid: String = game.equipment.get_equipment("lift_shelf").occupants()[0]
		if not await finish_recovered_half("ring_2",stored_uid if held_uid.is_empty() else held_uid,held_uid.is_empty()):return false
		if not await ring_reverse("ring_1"):return false
		if not await loaded_return():return false
		return await structural_reverse()
	if from_played_full_ring:
		if not await lower_and_disembark():return false
	else:
		if from_played_half:
			if not await lower_and_disembark():return false
		else:
			if not await horizontal_forward():return false
			if not await rail_to_pelvis():return false
			if not await ring_forward("ring_1"):return false
		expect(not game.model.milestone("pelvis","left_leg_secured"),"One fully bolted half never secures the complete hip")
		if not await to_bay_panel():return false
		var rail = game.equipment.get_equipment("leg_rail")
		for action in ["return","advance"]:
			var before_model: String = JSON.stringify(game.saves.capture().model)
			if not await control(rail,action,true,true):return false
			expect(not rail.moving and rail.engaged and is_equal_approx(rail.path,3),"Partial retention blocks ordinary "+action+" without losing support")
			expect(JSON.stringify(game.saves.capture().model)==before_model,"Rejected ordinary partial-ring "+action+" preserves every physical owner and component")
		if not await ring_forward("ring_2"):return false
	expect(game.model.milestone("pelvis","left_leg_secured"),"Both separately carried halves and all four pairs secure the hip")
	audit_readiness("left_leg");audit_readiness("pelvis")
	if not await holder_round_trip():return false
	if not await ring_reverse("ring_2"):return false
	if not await ring_reverse("ring_1"):return false
	if not await loaded_return():return false
	return await structural_reverse()

func run_historical_debug() -> void:
	var hashes: Dictionary = input_hashes()
	foundation_only = "--foundation" in OS.get_cmdline_user_args()
	from_played_fork = "--from-played-fork" in OS.get_cmdline_user_args()
	from_played_half = "--from-played-half" in OS.get_cmdline_user_args()
	from_played_full_ring = "--from-played-full-ring" in OS.get_cmdline_user_args()
	from_played_recovery = "--from-played-recovery" in OS.get_cmdline_user_args()
	from_played_fork_recovery = "--from-played-fork-recovery" in OS.get_cmdline_user_args()
	main_only = "--main-only" in OS.get_cmdline_user_args() or from_played_fork or from_played_half or from_played_full_ring or from_played_recovery or from_played_fork_recovery
	await boot_m3()
	opening()
	if from_played_fork or from_played_half or from_played_full_ring or from_played_recovery or from_played_fork_recovery:
		var played_path = "res://verification/m3-played-fork_installed_reacquisition.json" if from_played_fork_recovery else ("res://verification/m3-played-ring_2_recovery_on_shelf.json" if from_played_recovery else ("res://verification/m3-played-ring_2_secured.json" if from_played_full_ring else ("res://verification/m3-played-ring_1_secured.json" if from_played_half else "res://verification/m3-played-fork_axle_cap_secured.json")))
		if not await restore_played_debug(played_path,"--diagnostic-fixture" in OS.get_cmdline_user_args()):
			quit(1);return
		expect(game.model.milestone("left_leg","fork_secured"),"Played debug checkpoint retains actual constructed fork")
	var traversed = true
	if not main_only:
		traversed = await foundation()
		expect(traversed,"Representative foot+shin ordinary-control loop completes forward and reverse")
	if not foundation_only:
		var complete: bool = await complete_journey() if traversed else false
		expect(complete,"Complete M3 ordinary-control journey and supported reverse finishes")
		if complete and not from_played_fork and not from_played_half and not from_played_full_ring and not from_played_recovery and not from_played_fork_recovery:
			expect(lift_resume_covered.up and lift_resume_covered.ground,"Fresh scenes resume one loaded Up and one recovered-half Ground journey")
	expect(input_hashes()==hashes,"Independent acceptance code and asset inputs remain unchanged during the run")
	var passed: bool = checks.all(func(check):return check.passed)
	write_evidence("res://verification/m3-independent-acceptance.json",{"passed":passed,"scope":"debug-from-played-fork-recovery" if from_played_fork_recovery else ("debug-from-played-recovery" if from_played_recovery else ("debug-from-played-full-ring" if from_played_full_ring else ("debug-from-played-half" if from_played_half else ("debug-from-played-fork" if from_played_fork else ("foundation" if foundation_only else ("full-main" if main_only else "full")))))),"debug_fixture":debug_fixture,"lift_resume_covered":lift_resume_covered,"checks":checks,"checkpoints":checkpoints,"travelled":travelled,"installed":installed,"staged_player_poses":driver.staging_poses,"rendered":false,"input_hashes":hashes})
	game.free();await process_frame
	print("M3_INDEPENDENT_ACCEPTANCE ","PASS" if passed else "FAIL"," ",checks.size()," checks")
	quit(0 if passed else 1)

func forward_journey() -> bool:
	if not await horizontal_forward():return false
	if not await rail_to_pelvis():return false
	if not await ring_forward("ring_1"):return false
	expect(not game.model.milestone("pelvis","left_leg_secured"),"One retaining half does not complete hip security")
	if not await to_bay_panel():return false
	var before: String = JSON.stringify(game.saves.capture().model)
	if not await control(game.equipment.get_equipment("leg_rail"),"advance",true,true):return false
	expect(JSON.stringify(game.saves.capture().model)==before and game.equipment.get_equipment("leg_rail").engaged,"Partial retention cannot release the holder")
	if not await ring_forward("ring_2"):return false
	expect(game.model.milestone("pelvis","left_leg_secured"),"Both separate retaining-half journeys and all four fastener pairs secure the hip")
	audit_readiness("left_leg");audit_readiness("pelvis")
	if not await to_bay_panel():return false
	var pose: Transform3D = game.runtime.node("left_leg").global_transform
	if not await rail_action("advance","holder_releasing"):return false
	var released: bool = not game.equipment.get_equipment("leg_rail").engaged and game.model.assemblies.left_leg.parent=="pelvis" and game.runtime.node("left_leg").global_transform.is_equal_approx(pose)
	expect(released,"Full retention permits holder release while the mounted leg stays stationary")
	expect(game.model.integrity_errors().is_empty(),"Forward construction preserves every physical identity and single ownership")
	if not released:return false
	return await checkpoint("forward_complete_holder_released")

func run() -> void:
	var hashes: Dictionary = input_hashes()
	await boot_m3()
	opening()
	var complete: bool = await forward_journey()
	expect(complete,"Fresh M3 forward journey reaches secured leg and holder release")
	if complete:expect(lift_resume_covered.up,"A fresh scene resumes the actual shelved-half Up journey")
	expect(input_hashes()==hashes,"Independent forward acceptance inputs remain unchanged during the run")
	var passed: bool = checks.all(func(check):return check.passed)
	write_evidence("res://verification/m3-independent-acceptance.json",{"passed":passed,"scope":"fresh-forward","debug_fixture":{},"lift_resume_covered":lift_resume_covered,"checks":checks,"checkpoints":checkpoints,"travelled":travelled,"installed":installed,"staged_player_poses":driver.staging_poses,"rendered":false,"input_hashes":hashes})
	game.free();await process_frame
	print("M3_FORWARD_ACCEPTANCE ","PASS" if passed else "FAIL"," ",checks.size()," checks")
	quit(0 if passed else 1)
