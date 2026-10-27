extends RefCounted
## Scripted build progression: the same equipment commands the mechanical tests use.
## Fastenings and rig attachments are supplied (Staging.fill / supplied rig state);
## this is never playtest evidence and never a save.
const Staging=preload("res://scripts/scenario_staging.gd")
## The left foot is built before the robot structure's first stage.
const FOOT_STAGES = ["foot","actuator"]
const STAGES = ["pelvis","left_leg_build","left_leg_dock","right_leg_build","right_leg_dock","chest","core","backpack","left_arm","right_arm","pauldrons","head","head_sensors","complete"]
const TITLES = {"foot":"Left-foot heel pads","actuator":"Left-foot pitch actuator","pelvis":"Hip assembly delivery","left_leg_build":"Left-leg construction","left_leg_dock":"Left-leg docking","right_leg_build":"Right-leg construction","right_leg_dock":"Right-leg docking","chest":"Chest delivery","core":"Core delivery","backpack":"Backpack delivery","left_arm":"Left-arm delivery","right_arm":"Right-arm delivery","pauldrons":"Pauldron fitting","head":"Head fitting","head_sensors":"Head sensor fitting","complete":"Robot structure complete"}
var game: Node

func _init(workshop: Node) -> void:game=workshop

## Every stage name, in build order.
const ALL = FOOT_STAGES+STAGES

## The --stage=<name> launch flag, or "".
static func stage_flag(user_args: Array) -> String:
	for arg in user_args:
		if str(arg).begins_with("--stage="):return str(arg).trim_prefix("--stage=")
	return ""

func stages() -> Array:return ALL

## Errors describing why the workshop is not at the start of stage.
func stage_errors(stage: String) -> Array[String]:
	var errors: Array[String]=[]
	if not is_instance_valid(game):return ["Stages require the robot workshop."]
	if stage not in stages():return ["Unknown stage: "+stage]
	var model=game.model;var rail=_equipment("leg_rail");var carrier=_equipment("foot_carrier")
	var fixture=_equipment("module_supports");var crane=_equipment("service_crane")
	_need(errors,crane.station=="park" and crane.raised and crane.attached_count()==0 and not crane.moving and crane.motion.is_empty(),"Park the empty crane raised with no motion.")
	if stage in FOOT_STAGES:
		var turning=_equipment("foot_fixture")
		_location(errors,"foot","support:foot_store")
		_need(errors,turning!=null and turning.work_pose=="upright" and not turning.moving,"Set the foot rig upright.")
		var fitted=["pad_1","pad_2"] if stage=="actuator" else []
		for child in ["pad_1","pad_2","pitch"]:
			_need(errors,(model.assemblies[child].parent=="foot")==(child in fitted),child+(" must be fitted to the foot." if child in fitted else " must not be fitted yet."))
		if stage=="foot":
			_need(errors,model.items.keys().all(func(uid):return not model.items[uid].owner.is_empty() or model.items[uid].location==game.part_defs[uid].get("location","bin")),"Fresh workshop stock must remain at its authored source.")
		return errors
	match stage:
		"pelvis":
			_location(errors,"pelvis","support:bulky_fixture")
			for pair in [["foot","foot_store"],["right_foot","right_foot_store"],["chest","chest_store"],["core","core_store"],["backpack","backpack_store"],["arm_cassette","cassette_park"],["left_arm","arm_cassette"],["right_arm","right_arm_store"],["left_leg","leg_holder"],["right_leg","leg_queue_right"]]:_location(errors,pair[0],"support:"+pair[1])
			for owner in ["left_leg","right_leg","pelvis"]:
				var root: String=game.runtime.definition(owner).get("root_slot","")
				_need(errors,model.assemblies[owner].slots.keys().all(func(sid):return sid==root or model.assemblies[owner].slots[sid].is_empty()),"Fresh "+owner+" must have no construction supplied.")
			_need(errors,rail.active_assembly=="left_leg" and rail.lane=="left" and rail.can_construct() and rail.release==0 and rail.bolster==0,"Fresh leg rig must support the left build at home.")
			_carrier_home(errors)
			_need(errors,fixture.template=="pelvis" and fixture.height==0 and not fixture.moving and fixture.source_release==0 and not fixture.locks.values().any(func(v):return v) and fixture.jaws.all(func(v):return v==1),"Fresh heavy module rig must be lowered with open jaws and unset waist pins.")
			_need(errors,crane.endpoints.values().all(func(end):return end.state=="stowed"),"Stow every fresh magnetic connector.")
			_need(errors,_equipment("arm_cassette").support_secured("left_arm"),"Retain the left arm on its parked arm rig.")
			for owner in ["foot","right_foot"]:_need(errors,model.milestone(owner,"complete"),"Keep the supplied "+owner+" complete on its bay support.")
			_need(errors,model.items.keys().all(func(uid):return not model.items[uid].owner.is_empty() or model.items[uid].location==game.part_defs[uid].get("location","bin")),"Fresh workshop stock must remain at its authored source.")
		"left_leg_build":
			_location(errors,"pelvis","support:pelvis_gantry")
			_need(errors,fixture.support_secured(),"Secure the gantry and both waist pins.")
			_location(errors,"foot","support:foot_store")
			_need(errors,rail.active_assembly=="left_leg" and rail.can_construct(),"Select the left leg at the construction station.")
		"left_leg_dock","right_leg_dock":
			var owner="left_leg" if stage=="left_leg_dock" else "right_leg"
			var foot="foot" if stage=="left_leg_dock" else "right_foot"
			_need(errors,model.milestone(owner,"structural_ready"),"Complete "+owner+" structural construction.")
			_need(errors,_equipment("joint_restraints").required_error(owner).is_empty(),"Engage every transport brace on "+owner+".")
			_need(errors,model.assemblies[foot].parent==owner,"Mount the prepared foot on "+owner+".")
			_need(errors,rail.active_assembly==owner and rail.can_construct(),"Return the active "+owner+" leg rig to its construction pose.")
		"right_leg_build":
			_leg_secured(errors,"left")
			_holder_home(errors)
			_carrier_home(errors)
			_need(errors,rail.active_assembly=="right_leg" and rail.can_construct(),"Select the right build on the returned leg rig.")
			_location(errors,"right_foot","support:right_foot_store")
		"chest":
			for side in ["left","right"]:_leg_secured(errors,side)
			_holder_home(errors)
			_need(errors,not rail.engaged,"Release the leg rig from the retained legs.")
			_carrier_home(errors)
			_location(errors,"chest","support:chest_store")
		"core":
			_need(errors,model.milestone("pelvis","chest_connected"),"Retain and connect the chest.")
			_need(errors,model.support_occupant("bulky_fixture").is_empty(),"Clear the heavy module rig.")
			_location(errors,"core","support:core_store")
		"backpack":
			var guide=_equipment("core_guide")
			_need(errors,guide.active and guide.secured() and is_equal_approx(guide.travel,guide.spec.travel) and model.assemblies.core.parent=="chest" and not guide.moving,"Retain and connect the seated core before releasing its crane.")
			_need(errors,model.support_occupant("bulky_fixture").is_empty(),"Clear the heavy module rig.")
			_location(errors,"backpack","support:backpack_store")
		"left_arm":
			var pack=_equipment("backpack_hinge")
			_need(errors,model.milestone("chest","backpack_connected") and pack.active and pack.angle==1 and pack.retained() and pack.covers.all(func(v):return v) and not pack.moving and pack.motion.is_empty(),"Close, latch and cover the connected backpack.")
			_location(errors,"arm_cassette","support:cassette_park")
			_need(errors,_equipment("arm_cassette").support_secured("left_arm"),"Retain the left arm on its parked arm rig.")
		"right_arm":
			_need(errors,_equipment("left_shoulder").secured(),"Secure the left shoulder.")
			_location(errors,"right_arm","support:right_arm_store")
		"pauldrons":
			for side in ["left","right"]:_need(errors,_equipment(side+"_shoulder").secured(),"Secure the "+side+" shoulder.")
		"head":
			for side in ["left","right"]:
				_need(errors,model.milestone("chest",side+"_pauldron_closed"),"Retain and close the "+side+" pauldron.")
				_need(errors,_equipment(side+"_pauldron_receiver").operations_released(),"Release the "+side+" arm's joint and digit restraints.")
		"head_sensors","complete":
			for uid in ["head_baseplate","head_left","head_right","head_top"]:
				_need(errors,model.milestone("chest",uid+"_retained") and _equipment(uid+"_receiver").state=="released","Retain "+uid+" and release its magnetic connectors.")
				_need(errors,game.zones.holder(uid+"_rig").is_empty(),"Stow every magnetic connector of "+uid+".")
			_need(errors,model.milestone("chest","head_baseplate_connected"),"Connect and clip the central head loom.")
			_need(errors,model.support_occupant("bulky_fixture").is_empty(),"Clear the heavy module rig.")
	if stage=="complete":
		for uid in ["head_sensors","head_faceplate","head_mask","head_crown"]:
			_need(errors,model.milestone("chest",uid+"_retained"),"Retain "+uid+".")
		_need(errors,model.milestone("chest","head_sensors_connected"),"Connect the sensor carrier power/data.")
		_need(errors,_equipment("head_crown_receiver").state=="released" and game.zones.holder("head_crown_rig").is_empty(),"Release and stow the final crown magnetic connectors.")
	if stage in ["right_arm","pauldrons","head","head_sensors","complete"]:
		_need(errors,crane.endpoints.values().all(func(end):return end.state=="stowed"),"Stow every arm magnetic connector.")
	return errors

## Runs only this stage's forward work, up to the next stage's boundary.
func complete(stage: String) -> String:
	var errors=stage_errors(stage)
	if not errors.is_empty():return stage+": "+"; ".join(errors)
	match stage:
		"foot":Staging.prepare_foot(game,true);return ""
		"actuator":Staging.prepare_foot(game);return ""
		"pelvis":return _pelvis()
		"left_leg_build":return _leg_build("left")
		"right_leg_build":return _leg_build("right")
		"left_leg_dock":return _leg_dock("left")
		"right_leg_dock":return _leg_dock("right")
		"chest":return _chest()
		"core":return _core()
		"backpack":return _backpack()
		"left_arm":return _arm("left")
		"right_arm":return _arm("right")
		"pauldrons":return _pauldrons()
		"head":return _head()
		"head_sensors":return _head_closure()
	return stage+": No completion is defined for the last stage."

## Runs earlier stages from a fresh workshop, yielding between their commands.
func run_to(stage: String, progress: Callable = Callable()) -> String:
	if stage not in stages():return "Unknown stage: "+stage
	var fresh=stage_errors(stages()[0])
	if not fresh.is_empty():return "Fresh workshop required: "+"; ".join(fresh)
	for s in stages():
		if progress.is_valid():progress.call(TITLES[s])
		var errors=stage_errors(s)
		if not errors.is_empty():return s+": "+"; ".join(errors)
		if s==stage:return ""
		var error=complete(s)
		if not error.is_empty():return error
		await game.get_tree().process_frame
	return "Unknown stage: "+stage

## Shared mechanical settling; supplied progress does not bypass interlocks.
func settle(controller: Node, limit: int = 1600) -> String:
	for tick in range(limit):
		if not controller.moving:return controller.blocked_reason
		_equipment("workshop_access").physics(.1)
		_equipment("rail_gates").physics(.1)
		controller.physics(.1)
	# A held lift waits for its obstruction instead of refusing the request.
	var held: String = str(controller.get("blocked_reason")) if controller.get("blocked_reason") != null else ""
	return "Motion did not settle within "+str(limit)+" ticks."+("" if held.is_empty() else " "+held)

func command(controller: Node, action: String) -> String:
	var step: String=controller.equipment_id+" "+action
	var error: String=controller.request(action)
	if error.is_empty():error=settle(controller)
	return "" if error.is_empty() else step+": "+error

func supply_rig(crane: Node, attached: bool) -> void:
	var state: Dictionary=crane.capture()
	for index in range(crane.END_IDS.size()):state.endpoints[crane.END_IDS[index]]={"state":"attached" if attached else "stowed","point":crane.POINT_IDS[index] if attached else ""}
	crane.apply(state)

func _equipment(id: String) -> Node:return game.equipment.get_equipment(id)
func _need(errors: Array[String], okay: bool, message: String) -> void:
	if not okay:errors.append(message)
func _location(errors: Array[String], owner: String, location: String) -> void:
	_need(errors,game.model.assemblies[owner].location==location,owner+" must be at "+location+".")
func _holder_home(errors: Array[String]) -> void:
	var rail=_equipment("leg_rail")
	_need(errors,rail.path==0 and is_equal_approx(rail.index_x,rail.spec.station_x) and rail.release==0 and not rail.moving and rail.mode.is_empty(),"Return the leg rig home and finish its release motion.")
func _carrier_home(errors: Array[String]) -> void:
	var carrier=_equipment("foot_carrier")
	_need(errors,carrier.path==0 and carrier.withdrawal==0 and not carrier.carrying() and not carrier.moving and carrier.handoff.is_empty(),"Return the empty foot carrier home.")
func _leg_secured(errors: Array[String], side: String) -> void:
	_need(errors,game.model.assemblies[side+"_leg"].parent=="pelvis","Mount the "+side+" leg at its hip.")
	_need(errors,_equipment("joint_restraints").required_error(side+"_leg").is_empty(),"Keep the "+side+" leg transport braces engaged.")
	var locks=_equipment("captive_controls")
	_need(errors,locks.locked.keys().filter(func(id):return id.begins_with(side+"_")).all(func(id):return locks.locked[id]),"Engage every "+side+" hip captive lock.")
func _commands(controller: Node, actions: Array) -> String:
	for action in actions:
		var error=command(controller,action)
		if not error.is_empty():return error
	return ""
func _transfer(task: String) -> String:
	# The player's console path: the crane's next pickup must be this stage's load.
	var crane=_equipment("service_crane")
	if crane.next_route()!=task:return "service_crane: next pickup is "+crane.next_route()+", not "+task+"."
	var error=_commands(crane,(["pickup"] if crane.task!=task or crane.station!="source" else [])+["down"])
	if not error.is_empty():return error
	supply_rig(crane,true)
	return _commands(crane,["up","go:receiver","down"])
func _park() -> String:
	var crane=_equipment("service_crane");supply_rig(crane,false)
	return _commands(crane,["up","go:park"])

func _pelvis() -> String:
	var fixture=_equipment("module_supports")
	var error=_commands(fixture,["lock:yaw","lock:lean"])
	if not error.is_empty():return error
	error=_transfer("pelvis")
	if not error.is_empty():return error
	for index in range(4):
		error=command(fixture,"jaw:"+str(index))
		if not error.is_empty():return error
	return _park()

func _leg_build(side: String) -> String:
	var owner=side+"_leg";var crane=_equipment("service_crane")
	var error=_transfer("foot" if side=="left" else "right_foot")
	if not error.is_empty():return error
	error=_park()
	if not error.is_empty():return error
	error=_commands(_equipment("foot_carrier"),["advance","advance","advance"])
	if not error.is_empty():return error
	for task in ["shin","fork","spar"]:
		error=_transfer(task if side=="left" else "right_"+task)
		if not error.is_empty():return error
		Staging.fill(game,owner,game.runtime.definition(owner).slots.keys().filter(func(sid):return sid not in ["shin","fork","spar"]))
		if not crane.secured():return owner+" "+task+": Supplied structural fastening did not secure the load."
		var braces=_equipment("joint_restraints")
		for fixture in braces.fixtures:
			if fixture.owner!=owner or fixture.spec.milestone!=task+"_secured":continue
			error=command(braces,"engage:"+fixture.id)
			if not error.is_empty():return error
		error=_park()
		if not error.is_empty():return error
	return ""

func _leg_dock(side: String) -> String:
	var rail=_equipment("leg_rail")
	for phase in range(7):
		if rail.path==3:break
		var error=command(rail,"advance")
		if not error.is_empty():return error
	if rail.path!=3:return side+" leg docking: Holder did not reach its hip."
	Staging.fill(game,"pelvis")
	var locks=_equipment("captive_controls")
	for id in locks.specs:
		if not id.begins_with(side+"_"):continue
		var error: String=locks.request(id)
		if not error.is_empty():return id+": "+error
	var error=settle(_equipment("workshop_access"))
	if not error.is_empty():return "hip work decks: "+error
	error=command(rail,"advance")
	if not error.is_empty():return error
	for phase in range(5):
		if rail.path==0 and is_equal_approx(rail.index_x,rail.spec.station_x) and rail.release==0:break
		error=command(rail,"return")
		if not error.is_empty():return error
	error=_commands(_equipment("foot_carrier"),["return","return","return"])
	if not error.is_empty():return error
	return command(rail,"build") if side=="left" else ""

func _chest() -> String:
	var error=command(_equipment("module_supports"),"template:chest")
	if not error.is_empty():return error
	error=_transfer("chest_store")
	if not error.is_empty():return error
	error=_park()
	if not error.is_empty():return error
	error=_transfer("chest")
	if not error.is_empty():return error
	Staging.fill(game,"pelvis",game.runtime.definition("pelvis").milestones.chest_secured.filter(func(sid):return sid!="chest"))
	error=_park()
	if not error.is_empty():return error
	Staging.fill(game,"pelvis",["chest/service_1","chest/service_2"])
	return ""

func _core() -> String:
	var guide=_equipment("core_guide");var crane=_equipment("service_crane")
	var error=command(_equipment("module_supports"),"template:core")
	if not error.is_empty():return error
	error=_transfer("core_store")
	if not error.is_empty():return error
	error=_park()
	if not error.is_empty():return error
	error=_transfer("core")
	if not error.is_empty():return error
	error=command(guide,"advance")
	if not error.is_empty():return error
	var state: Dictionary=crane.capture()
	state.endpoints[crane.END_IDS[crane.POINT_IDS.find("core_front")]]={"state":"stowed","point":""};crane.apply(state)
	error=command(guide,"advance")
	if not error.is_empty():return error
	error=_commands(guide,["bolt:0","bolt:1","bolt:2","bolt:3","connection"])
	if not error.is_empty():return error
	return _park()

func _backpack() -> String:
	var pack=_equipment("backpack_hinge");var crane=_equipment("service_crane")
	var error=command(_equipment("module_supports"),"template:backpack")
	if not error.is_empty():return error
	error=_transfer("backpack_store")
	if not error.is_empty():return error
	error=_park()
	if not error.is_empty():return error
	error=_transfer("backpack")
	if not error.is_empty():return error
	Staging.fill(game,"chest",pack.spec.hinge_slots)
	error=_commands(pack,["strut:0","strut:1"])
	if not error.is_empty():return error
	Staging.fill(game,"chest",pack.spec.strut_slots)
	error=_commands(pack,["lock:0","lock:1"])
	if not error.is_empty():return error
	error=_park()
	if not error.is_empty():return error
	Staging.fill(game,"chest",pack.spec.service_slots)
	error=_commands(crane,["go:receiver","down"])
	if not error.is_empty():return error
	supply_rig(crane,true)
	error=_commands(pack,["take_weight","lock:0","lock:1","close","latch:0","latch:1"])
	if not error.is_empty():return error
	error=_park()
	if not error.is_empty():return error
	return _commands(pack,["cover:0","cover:1"])

func _arm(side: String) -> String:
	var crane=_equipment("service_crane");var rail=_equipment("leg_rail")
	var error=""
	if side=="left":
		error=command(rail,"park")
		if not error.is_empty():return error
		error=_transfer("cassette")
	else:error=_transfer("right_arm_store")
	if not error.is_empty():return error
	error=_park()
	if not error.is_empty():return error
	error=_transfer(side+"_arm")
	if not error.is_empty():return error
	var shoulder=_equipment(side+"_shoulder")
	Staging.fill(game,"chest",shoulder.spec.structural_slots.filter(func(sid):return sid!=side+"_arm"))
	error=_commands(shoulder,["check_brakes","transfer_weight"])
	if not error.is_empty():return error
	Staging.fill(game,"chest",shoulder.spec.service_slots)
	return _park()

func _pauldrons() -> String:
	for side in ["left","right"]:
		var receiver=_equipment(side+"_pauldron_receiver")
		var error=_transfer(side+"_pauldron")
		if not error.is_empty():return error
		Staging.fill(game,receiver.spec.owner,receiver.spec.retention_slots)
		error=_park()
		if not error.is_empty():return error
		Staging.fill(game,receiver.spec.owner,receiver.spec.closure_slots)
		for operation in receiver.spec.operations:
			error=receiver.request("release:"+operation.id)
			if not error.is_empty():return side+" "+operation.id+": "+error
	return ""

func _head() -> String:
	for uid in ["head_baseplate","head_left","head_right","head_top"]:
		var receiver=_equipment(uid+"_receiver")
		var error=command(_equipment("module_supports"),"template:"+uid)
		if not error.is_empty():return error
		error=_transfer(uid+"_to_fixture")
		if not error.is_empty():return error
		error=_park()
		if not error.is_empty():return error
		error=_transfer(uid)
		if not error.is_empty():return error
		Staging.fill(game,receiver.spec.owner,receiver.spec.retention_slots)
		error=_park()
		if not error.is_empty():return error
	return ""

func _shelf_item(sid: String, side: String = "left") -> String:
	var slot=game.model.slot_definition("chest",sid);var uid: String=slot.pose_source
	var shelf=_equipment(side+"_shelf");var lift=_equipment(side+"_lift")
	var error="" if is_equal_approx(lift.height,lift.stops[0]) else command(lift,"ground")
	if not error.is_empty():return error
	error=game.model.carry_item(uid)
	if not error.is_empty():return sid+": "+error
	game.components.hold_at(uid,shelf._pose(uid,0).translated(Vector3.UP*.10))
	error=shelf.request("store")
	if not error.is_empty():return sid+" shelf: "+error
	error=command(lift,"stop"+str(lift.stops.size()-1))
	if not error.is_empty():return error
	error=shelf.request("take:0")
	if not error.is_empty():return error
	error=game.components.placement_error("chest",sid,uid)
	if not error.is_empty():return error
	var result: Dictionary=game.model.install("chest",sid,uid)
	if not result.ok:return sid+": "+result.error
	game.components.held_body.free();game.components.held_body=null;game.components.sync("chest")
	return ""

func _head_closure() -> String:
	for uid in ["head_sensors","head_faceplate","head_mask"]:
		var receiver=_equipment(uid+"_receiver")
		var error=_shelf_item(uid)
		if not error.is_empty():return error
		for sid in receiver.spec.get("captive_slots",[]):
			error=receiver.request("fasten:"+sid)
			if not error.is_empty():return error
		Staging.fill(game,"chest",receiver.spec.retention_slots)
		if not receiver.retained():return uid+": Retain and connect the seated hand-carried piece."
	var error=command(_equipment("module_supports"),"template:head_crown")
	if not error.is_empty():return error
	error=_transfer("head_crown_to_fixture")
	if not error.is_empty():return error
	error=_park()
	if not error.is_empty():return error
	error=_transfer("head_crown")
	if not error.is_empty():return error
	Staging.fill(game,"chest",_equipment("head_crown_receiver").spec.retention_slots)
	return _park()
