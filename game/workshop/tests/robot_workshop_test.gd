extends "res://tests/kit/harness.gd"
## The single robot workshop: the left foot is built in its turning fixture in
## the hangar's foot bay, then the structure continues. Mechanical checks only;
## walking, reach and visibility in the hangar are the user's playtest.
const Stages=preload("res://scripts/build_stages.gd")

func _initialize() -> void:call_deferred("run")

func settle_fixture(game: Node) -> void:
	for tick in range(600):
		if not game.foot_fixture.moving:return
		await frames(1)

func run() -> void:
	expect(Stages.stage_flag(["--stage=actuator"])=="actuator" and Stages.stage_flag([]).is_empty(),"--stage chooses a later start")
	expect(Stages.ALL.front()=="foot" and Stages.ALL.back()=="complete","stages run from the foot build to the complete structure")

	var game=await boot_workshop();var stages=Stages.new(game)
	var store: Vector3=AssemblyRuntime.vec(game.leg_layout.layout().workshop.foot_storage.foot.position)
	expect(game.model.assemblies.foot.location=="support:foot_store" and game.foot.global_transform.is_equal_approx(Transform3D(Basis.IDENTITY,store)),"unbuilt left foot rests upright at its bay store pose")
	expect(game.foot_fixture!=null and game.foot_fixture.work_origin.is_equal_approx(store) and not game.foot_fixture.has_dispatch,"turning fixture stands at the store without dispatch rails")
	expect(not game.foot_fixture.controls().any(func(control):return control.action=="transfer"),"fixture offers no dispatch transfer in the hangar")
	var pieces: Dictionary=game.leg_layout.blockout.pieces
	expect(pieces.keys().filter(func(id):return id.begins_with("foot_store_")).all(func(id):return not pieces[id].visual.visible and pieces[id].body.collision_layer==0),"fixture replaces the left store's masts and soles")
	expect(pieces.keys().filter(func(id):return id.begins_with("right_foot_store_")).all(func(id):return pieces[id].visual.visible and pieces[id].body.collision_layer==1),"right foot store is unchanged")
	expect(["pad_1","pad_2","pitch"].all(func(owner):return game.model.assemblies[owner].parent.is_empty() and game.model.assemblies[owner].history.is_empty()),"heel pads and actuator start unbuilt")
	expect(game.model.milestone("right_foot","complete"),"right foot is still supplied complete")
	expect(game.hud.manual_id=="foot","foot manual opens first")
	expect(stages.stage_errors("foot").is_empty(),"fresh game starts at the foot stage: "+str(stages.stage_errors("foot")))
	expect(game.journey.undo_error("pad_1").is_empty() and not game.journey.undo_error("right_pad_1").is_empty(),"player-built foot can be undone; the supplied right foot cannot")

	var cabinets=game.bins.keys().filter(func(kind):return game.bins[kind].get_meta("cabinet",false))
	expect(cabinets.size()==game.foot_kinds.keys().filter(func(kind):return game.bins.has(kind)).size() and cabinets.all(func(kind):return game.foot_kinds.has(kind) and game.bins[kind].global_position.z<-7.5),"foot-build stock keeps its wall cabinets on the hangar's rear wall")
	var crowded=game.bins.keys().filter(func(kind):
		var bin: Node3D=game.bins[kind]
		if not bin.visible or bin.get_meta("cabinet",false):return false
		return game.stations.values().any(func(station):return absf(bin.global_position.x-station.global_position.x)<.925 and absf(bin.global_position.z-station.global_position.z)<.725))
	expect(crowded.is_empty(),"grid stock leaves the preparation stations clear: "+str(crowded))

	for pose in ["sole_left","upright","sole_right","upright"]:
		var error: String=game.foot_fixture.request(pose)
		expect(error.is_empty(),"fixture accepts "+pose+" in the foot bay: "+error)
		await settle_fixture(game)
		expect(game.foot_fixture.work_pose==pose and game.foot_fixture.blocked_reason.is_empty(),"fixture reaches "+pose)
	expect(game.foot_fixture.request("sole_left").is_empty(),"turn the foot before rigging")
	await settle_fixture(game)
	expect(not game.equipment.busy_reason("rig:foot").is_empty(),"crane rigging waits for an upright foot")
	expect(game.foot_fixture.request("upright").is_empty(),"return the foot upright")
	await settle_fixture(game)
	expect(game.equipment.busy_reason("rig:foot").is_empty(),"upright foot can be rigged")
	var crane=game.equipment.get_equipment("service_crane")
	var error: String=stages._commands(crane,["task:foot","go:source","down"])
	expect(error.is_empty(),"crane lowers over the foot fixture: "+error)
	stages.supply_rig(crane,true)
	expect(not game.foot_fixture.action_error("sole_left").is_empty(),"rigged foot cannot be turned")
	stages.supply_rig(crane,false)
	expect(game.foot_fixture.action_error("sole_left").is_empty(),"unrigged foot can be turned again")
	game.free();await frames(2)

	game=await boot_workshop()
	expect((await game.run_stage("actuator")).is_empty(),"actuator stage supplies only the heel pads")
	expect(game.model.assemblies.pad_1.parent=="foot" and game.model.assemblies.pad_2.parent=="foot" and game.model.assemblies.pitch.parent.is_empty(),"actuator stage leaves the pitch actuator to build")
	game.free();await frames(2)
	game=await boot_workshop()
	expect((await game.run_stage("left_leg_dock")).is_empty(),"later stages supply the foot and collect it from the fixture")
	expect(game.model.assemblies.foot.parent=="left_leg" and not game.foot_fixture.action_error("upright").is_empty(),"collected foot rides the left leg; the empty fixture stays idle")
	game.free();await frames(2)

	var passed=checks.all(func(check):return check.passed)
	print("ROBOT_WORKSHOP ","PASS " if passed else "FAIL ",checks.size()," checks")
	quit(0 if passed else 1)
