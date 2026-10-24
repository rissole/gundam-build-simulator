extends "res://tests/kit/workshop_suite.gd"
## Deliberately staged save-boundary tests. The walked acceptance suite proves
## construction and real file interruption; these fixtures exercise rejection.
var attacks = 0
var defects: Array[Dictionary] = []
var snapshots: Array[Dictionary] = []

func clone(value: Dictionary) -> Dictionary:
	return JSON.parse_string(JSON.stringify(value))

func live_state() -> String:
	return JSON.stringify(game.saves.capture())

func remember(label: String) -> Dictionary:
	var snapshot = clone(game.saves.capture())
	var errors: Array[String] = game.saves.validate(snapshot)
	expect(errors.is_empty(), "Staged validation fixture is legal: " + label + " " + str(errors))
	if errors.is_empty():snapshots.append({"label":label,"snapshot":snapshot})
	return snapshot

func reject(snapshot: Dictionary, label: String) -> void:
	var before = live_state()
	var errors: Array[String] = game.saves.validate(snapshot)
	attacks += 1
	var rejected = not errors.is_empty()
	# Attempt application too: it must share the detached validation boundary.
	var applied: bool = game.saves.apply_snapshot(snapshot) if rejected else false
	var unchanged = before == live_state()
	if not rejected or applied or not unchanged:
		defects.append({"label":label,"rejected":rejected,"applied":applied,"unchanged":unchanged})
	expect(rejected and not applied and unchanged, label + " rejects without live mutation")

func branch(value: Dictionary, path: Array) -> Dictionary:
	var result = value
	for key in path:result = result[key]
	return result

func fuzz(snapshot: Dictionary, path: Array) -> void:
	var target = branch(snapshot,path)
	for key in target:
		var missing = clone(snapshot)
		branch(missing,path).erase(key)
		reject(missing, "Missing " + str(path) + "/" + key)
		var wrong_type = clone(snapshot)
		var value = target[key]
		branch(wrong_type,path)[key] = [] if value is String or value is Dictionary else "wrong type"
		reject(wrong_type, "Mistyped " + str(path) + "/" + key)
		if value is Dictionary and not value.is_empty():fuzz(snapshot,path+[key])

func stage_secured_leg() -> bool:
	var result: Dictionary = game.model.install_supported("left_leg","foot","foot","foot_carrier")
	expect(result.ok, "Validation fixture mounts supplied foot through authorized carrier")
	if not result.ok:return false
	game.runtime.mount("left_leg","foot","foot")
	var carrier = game.equipment.get_equipment("foot_carrier")
	carrier.path = 2;carrier.goal = 2;carrier.withdrawal = 1;carrier.handoff = "";carrier._pose()
	Staging.fill(game,"left_leg")
	game.refresh_assembly_collision("left_leg")
	expect(game.model.milestone("left_leg","structural_ready"), "Validation fixture stages complete existing structural graph")
	var rail = game.equipment.get_equipment("leg_rail")
	var crane = game.equipment.get_equipment("service_crane")
	crane.station = "receiver";crane.raised = false;crane._refresh()
	game.set_paused(false)
	expect(not rail.action_error("advance").is_empty(),"Loaded rail waits for the empty crane to be raised and parked")
	game.set_paused(true)
	crane.station = "park";crane.raised = true;crane._refresh()
	var at_home = remember("complete leg on home holder")
	var invalid_capture = clone(at_home)
	invalid_capture.world.equipment.foot_carrier.handoff = "capture"
	invalid_capture.world.equipment.foot_carrier.moving = true
	invalid_capture.world.equipment.foot_carrier.withdrawal = .5
	reject(invalid_capture,"Carrier cannot recapture foot while the shin remains fastened")
	carrier.withdrawal = .5;carrier.handoff = "withdraw";carrier.moving = false;carrier._pose()
	remember("stopped carrier withdrawal with completed leg still home")
	game.set_paused(false)
	expect(not rail.action_error("advance").is_empty(),"Stopped carrier handoff still blocks loaded rail departure")
	game.set_paused(true)
	carrier.withdrawal = 1;carrier.handoff = "";carrier._pose()
	rail.path = 3;rail.goal = 3;rail._pose()
	result = game.model.install_supported("pelvis","left_leg","left_leg","m2_leg_rail")
	expect(result.ok, "Validation fixture seats complete leg on authorized rail")
	if not result.ok:return false
	game.runtime.mount("pelvis","left_leg","left_leg")
	Staging.fill(game,"pelvis")
	game.refresh_assembly_collision("pelvis")
	rail._pose()
	expect(game.model.milestone("pelvis","left_leg_secured"), "Validation fixture fits both halves and every retaining pair")
	game.set_paused(false)
	for destination in ["source","receiver"]:
		expect(not crane.action_error("go:"+destination).is_empty(),"Empty crane stays parked while holder is away: " + destination)
	expect(crane.action_error("task:fork").is_empty(),"Parked crane task selection remains available while holder is away")
	game.set_paused(true)
	return true

func initial_attacks(snapshot: Dictionary) -> void:
	fuzz(snapshot,["world","equipment"])
	fuzz(snapshot,["world","trial"])
	var forged = clone(snapshot)
	forged.world.equipment.leg_rail.path = 1
	forged.world.equipment.leg_rail.goal = 1
	reject(forged,"Incomplete leg cannot be saved away from home")
	forged = clone(snapshot)
	forged.world.equipment.foot_carrier.path = 2
	forged.world.equipment.foot_carrier.goal = 2
	reject(forged,"Carrier progress cannot disagree with the supported foot pose")
	forged = clone(snapshot)
	forged.world.equipment.service_crane.task = "invented"
	reject(forged,"Unknown selected crane task")
	forged = clone(snapshot)
	forged.world.equipment.service_crane.endpoints.magnet_a = {"state":"attached","point":"load_near"}
	reject(forged,"Parked crane cannot claim a magnetic contact")
	forged = clone(snapshot)
	forged.world.equipment.leg_rail.engaged = false
	forged.world.equipment.leg_rail.jaw_open = 1
	reject(forged,"Unbuilt leg cannot lose its only supporting holder")
	forged = clone(snapshot)
	forged.world.equipment.lift_shelf.occupants = ["PV-120__001","PV-120__001"]
	reject(forged,"One retaining half cannot occupy both shelf places")
	forged = clone(snapshot)
	forged.world.fixtures.pelvis[10] += .5
	reject(forged,"Gantry pelvis cannot move through a save")
	forged = clone(snapshot)
	forged.world.equipment.joint_restraints = {"engaged":false}
	reject(forged,"Passive joint restraints cannot be independently switched off in a save")

func holder_states() -> void:
	var rail = game.equipment.get_equipment("leg_rail")
	var secured = remember("complete ring, holder engaged")
	var forged = clone(secured)
	forged.world.equipment.leg_rail.path = 2.5
	forged.world.equipment.leg_rail.goal = 2.5
	reject(forged,"Engaged holder cannot separate from its pelvis-owned load")
	forged = clone(secured)
	forged.world.fixtures.left_leg[9] += .2
	reject(forged,"Mounted leg pose cannot drift from the pelvis")
	forged = clone(secured)
	forged.world.fixtures.foot[10] += .2
	reject(forged,"Nested foot pose cannot drift from its leg")
	forged = clone(secured)
	forged.world.equipment.foot_carrier.handoff = "capture"
	forged.world.equipment.foot_carrier.moving = true
	forged.world.equipment.foot_carrier.withdrawal = .5
	reject(forged,"Home foot carrier cannot recapture a leg docked at the pelvis")
	forged = clone(secured)
	forged.world.equipment.foot_carrier.withdrawal = 0
	reject(forged,"Departed leg requires the foot carrier to have withdrawn")
	# Contact phase sampling is state evidence, not a player journey or sweep proof.
	rail.holder_motion = "release";rail.moving = true;rail.jaw_open = .4;rail._pose()
	var releasing = remember("interrupted holder release")
	forged = clone(releasing);forged.world.equipment.leg_rail.engaged = false
	reject(forged,"Release phase must still identify the engaged source holder")
	rail.engaged = false;rail.jaw_open = 1;rail.holder_motion = "";rail.moving = false;rail._pose()
	var released = remember("complete ring, released holder")
	forged = clone(released)
	forged.world.equipment.leg_rail.jaw_open = 0
	reject(forged,"Released holder cannot claim closed contact jaws")
	# Preserve the mounted leg pose while the empty holder alone traverses its path.
	var mounted_pose: Transform3D = game.runtime.node("left_leg").global_transform
	rail.path = 2.5;rail.goal = 2;rail.moving = true;rail._pose()
	remember("empty holder interrupted reverse travel")
	expect(game.runtime.node("left_leg").global_transform.is_equal_approx(mounted_pose), "Empty holder fixture sampling leaves mounted leg fixed")
	rail.path = 0;rail.goal = 0;rail.moving = false;rail._pose()
	remember("empty holder home while leg remains secured")
	rail.path = 3;rail.goal = 3;rail.holder_motion = "acquire";rail.moving = true;rail.jaw_open = .4;rail._pose()
	var acquiring = remember("interrupted support reacquisition")
	forged = clone(acquiring);forged.world.equipment.leg_rail.engaged = true
	reject(forged,"Acquisition cannot claim engagement before closing contact jaws")
	rail.jaw_open = 0;rail.engaged = true;rail.holder_motion = "";rail.moving = false;rail._pose()
	remember("physically reacquired holder")
	# Removing one real bolt leaves a legal partial-retention state only with support.
	var undo: Dictionary = game.model.undo("pelvis")
	expect(undo.ok,"Validation fixture removes one actual retaining bolt after reacquisition")
	game.components.sync("pelvis")
	var partial = remember("partially undone retention on reacquired support")
	forged = clone(partial)
	forged.world.equipment.leg_rail.engaged = false;forged.world.equipment.leg_rail.jaw_open = 1
	reject(forged,"Partial retention cannot be saved with departed support")

func fresh_restores() -> void:
	game.free();await process_frame
	for entry in snapshots:
		game = await boot_profile("leg_bay_m3",2)
		var before = live_state()
		var errors: Array[String] = game.saves.validate(entry.snapshot)
		expect(errors.is_empty() and before == live_state(), "Fresh detached validation: " + entry.label + " " + str(errors))
		if errors.is_empty():
			expect(game.saves.apply_snapshot(entry.snapshot) and game.paused,"Fresh scene restores paused: " + entry.label)
			var restored = clone(game.saves.capture())
			expect(restored.model == entry.snapshot.model and restored.world.equipment == entry.snapshot.world.equipment,"Fresh scene preserves exact model/equipment: " + entry.label)
		game.free();await process_frame

func run() -> void:
	game = await boot_profile("leg_bay_m3")
	game.set_paused(true)
	var initial = remember("prepared foot at dispatch")
	initial_attacks(initial)
	# Different task point IDs must validate against the saved task, not live shin.
	var crane = game.equipment.get_equipment("service_crane")
	game.set_paused(false)
	for task in ["fork","spar","shin"]:
		expect(crane.request("task:"+task).is_empty(),"Validation fixture selects empty parked task " + task)
		remember("empty crane selected " + task)
	game.set_paused(true)
	if stage_secured_leg():holder_states()
	await fresh_restores()
	var passed: bool = checks.all(func(check):return check.passed)
	write_evidence("res://verification/m3-save-validation.json",{"passed":passed,"checks":checks,"attacks":attacks,"defects":defects,"snapshots":snapshots.map(func(entry):return entry.label),"scope":"staged detached-validation and fresh-scene restore; ordinary input/file journeys covered separately"})
	print("M3_SAVE_VALIDATION ","PASS" if passed else "FAIL"," ",checks.size()," checks; ",attacks," malformed snapshots")
	quit(0 if passed else 1)
