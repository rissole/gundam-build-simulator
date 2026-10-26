extends "res://tests/kit/harness.gd"
## Isolated saved-state fixtures against production manual and equipment logic.
## These check progression, not physical assembly, reach or presentation.
const Objectives = preload("res://scripts/manual_objectives.gd")
const Progress = preload("res://scripts/manual_progress.gd")
var game
var crane
var rail
var foot
var pins
var braces

func _initialize() -> void:call_deferred("run")

func machine(script, id: String):
	var value = script.new();game.add_child(value);value.game=game;value.equipment_id=id;game.equipment.register(value)
	return value

func page(owner: String, index: int) -> Dictionary:
	return game.model.definitions.assemblies[game.model.assemblies[owner].definition].manual[index]

func fill(owner: String, slots: Array) -> void:
	for sid in slots:
		var spec: Dictionary = game.model.slot_definition(owner,str(sid))
		game.model.assemblies[owner].slots[sid] = str(spec.get("pose_source",spec.get("assembly","fixture")))

func evaluate(owner: String, index: int) -> Dictionary:return Objectives.evaluate(game,owner,page(owner,index))

func run() -> void:
	game = preload("res://tests/kit/model_workshop.gd").new();root.add_child(game)
	expect(game.setup().is_empty(),"authored model loads")
	crane=machine(preload("res://scripts/service_crane.gd"),"service_crane")
	crane.tasks=preload("res://scripts/leg_bay_layout.gd").layout().crane.tasks
	crane.task="foot";crane.station="park";crane.raised=true;crane.END_IDS=["a","b"]
	crane.endpoints={"a":{"state":"stowed","point":""},"b":{"state":"stowed","point":""}}
	rail=machine(preload("res://scripts/indexed_leg_rail.gd"),"leg_rail")
	rail.spec={"station_x":14.0,"lanes":{"left":10.0,"right":18.0,"parking":20.0}}
	rail.active_assembly="left_leg";rail.lane="left";rail.index_x=14.0;rail.path=0.0;rail.engaged=true
	foot=machine(preload("res://scripts/foot_carrier.gd"),"foot_carrier")
	pins=machine(preload("res://scripts/captive_controls.gd"),"captive_controls")
	pins.specs=game.leg_content.equipment.captive_controls
	for id in pins.specs:pins.locked[id]=false
	var supports=machine(preload("res://scripts/module_supports.gd"),"module_supports")
	supports.locks={"yaw":true,"lean":true};supports.jaws.resize(4);supports.jaws.fill(0.0);supports.jaw_goals.resize(4);supports.jaw_goals.fill(0.0)
	braces=machine(preload("res://scripts/passive_joint_restraints.gd"),"joint_restraints")
	for owner in ["left_leg","right_leg"]:
		for group in ["ankle","knee","beam"]:
			for side in ["outboard","inboard"]:braces.fixtures.append({"id":owner+":"+group+":"+side,"locked":false})
	var progress=Progress.new(game)
	expect(not progress.complete(),"fresh workshop is not complete")
	expect(evaluate("left_leg",1).current == 0,"initial parked crane does not tick a delivery")
	# Reproduce leaving a captive pin out and starting the next cylinder.
	fill("pelvis",page("pelvis",8).slots)
	fill("pelvis",["cylinder_2"])
	var steps=[{"owner":"pelvis","page":page("pelvis",8)},{"owner":"pelvis","page":page("pelvis",9)}]
	expect(not Objectives.done_states(game,steps)[0] and evaluate("pelvis",8).current == 2,"next cylinder cannot finish the previous lock pin")
	pins.locked.left_hip_1=true
	expect(Objectives.done_states(game,steps)[0] and evaluate("pelvis",8).current == -1,"inserted pin completes both step and objective")
	pins.locked.left_hip_1=false
	expect(not Objectives.done_states(game,steps)[0],"pulling the pin reopens the step")
	# The same stop must not count as mounting the other foot or leg.
	foot.path=3.0;foot.receiving_assembly="left_leg"
	expect(not evaluate("right_leg",2).started and not evaluate("right_leg",2).fits_complete,"left foot dock pose does not advance the right-foot page")
	rail.path=3.0;rail.bolster=1.0;rail.index_x=10.0
	expect(not evaluate("pelvis",13).started,"left leg dock pose does not advance the right-leg page")
	game.model.assemblies.left_leg.slots.foot="foot"
	game.model.assemblies.foot.parent="left_leg"
	game.model.assemblies.pelvis.slots.left_leg="left_leg"
	# Shared-machine prefixes must all match. A foot rig already home is not
	# evidence of releasing the leg rig; changing Build is not a foot reset.
	foot.path=0.0
	var reset=evaluate("pelvis",11)
	expect(reset.current==0 and not reset.machine_complete,"foot rig home cannot tick leg release")
	rail.engaged=false;rail.path=2.0
	reset=evaluate("pelvis",11)
	expect(reset.ticked == [true,false,false,false],"released leg still requires the rail to return")
	rail.path=0.0;rail.index_x=14.0;foot.path=3.0
	reset=evaluate("pelvis",11)
	expect(reset.ticked == [true,true,false,false],"home rail still requires foot reset and Build")
	rail.active_assembly="right_leg";rail.engaged=true
	expect(evaluate("pelvis",11).current != -1,"Build cannot hide a foot rig left at docking")
	foot.path=0.0
	expect(evaluate("pelvis",11).current == -1,"both resets and right Build complete release")
	game.model.assemblies.right_foot.location="support:foot_carrier"
	foot.receiving_assembly="right_leg";foot.path=1.5
	expect(evaluate("pelvis",11).current == -1,"left reset stays complete while the next delivered foot moves")
	# Once the right foot is really installed, reuse of both rigs is durable proof.
	game.model.assemblies.right_leg.slots.foot="right_foot"
	game.model.assemblies.right_foot.parent="right_leg"
	foot.receiving_assembly="right_leg";foot.path=3.0;rail.path=2.0;rail.index_x=18.0
	expect(evaluate("pelvis",11).current == -1,"right-foot installation preserves the completed left reset")
	expect(evaluate("left_leg",2).current == -1,"left-foot docking stays complete after rig reuse")
	game.model.assemblies.right_leg.slots.foot="";game.model.assemblies.right_foot.parent=""
	expect(evaluate("right_leg",2).current != -1,"undo mounting reopens the actual right-foot seat")
	game.model.assemblies.right_foot.location="support:right_foot_store"
	expect(evaluate("pelvis",11).current != -1,"returning the right foot to stock removes its reset evidence")
	# A released delivery stays complete after crane reuse, but not after undo.
	fill("left_leg",["shin"]);fill("left_leg",page("left_leg",4).slots)
	crane.task="shin";crane.station="receiver";crane.raised=false
	expect(evaluate("left_leg",4).current != -1,"retention still needs the crane raised and parked")
	crane.station="park";crane.raised=true
	expect(evaluate("left_leg",4).current != -1,"retention and parked crane still require deliberate ankle brace locks")
	for fixture in braces.fixtures:
		if fixture.id.begins_with("left_leg:ankle:"):fixture.locked=true
	expect(evaluate("left_leg",4).current == -1,"retained shin and parked empty crane complete release")
	crane.task="fork";crane.station="source"
	var retained=evaluate("left_leg",4)
	expect(retained.current == -1 and retained.ticked.all(func(tick):return tick),"crane reuse preserves consistent Done ticks")
	game.model.assemblies.left_leg.slots.shin=""
	expect(evaluate("left_leg",3).current != -1 and evaluate("left_leg",4).current != -1,"removed load invalidates both delivery and release evidence")
	# Mixed machine states keep permanent controls mandatory.
	game.model.assemblies.pelvis.location="support:pelvis_gantry"
	crane.task="right_foot";crane.station="park"
	expect(evaluate("pelvis",0).current == -1,"delivered locked hip stays done after crane reuse")
	supports.locks.yaw=false
	expect(evaluate("pelvis",0).current != -1,"later crane work cannot hide a removed waist lock")
	supports.locks.yaw=true
	# No ready row is a blocked manual, not a completed robot.
	progress._data={"chapters":[{"id":"blocked","title":"Blocked","after":["unfinished"],"steps":[["pelvis",8]]}]}
	progress.refresh()
	expect(progress.tracked().is_empty() and not progress.complete(),"all-locked manual is not robot completion")
	pins.locked.left_hip_1=true;progress.refresh()
	expect(progress.complete() and progress.evaluation("pelvis",8).current == -1,"completion uses the same resolved ticks as objectives")
	var note: Dictionary=page("pelvis",8).note
	expect(note.at==2 and str(note.text).contains("gold handle") and str(note.text).contains("press E"),"PV-200 instruction locates the captive control at the lock objective")
	expect(page("pelvis",20).note.at==2 and str(page("pelvis",20).note.text).contains("press E"),"mirrored cylinder receives the same lock guidance")
	# Guided receivers have an arrival before the actual mounting operation.
	var guide=machine(preload("res://scripts/core_guide.gd"),"core_guide")
	guide.spec={"capture":0.85,"travel":2.2};guide.travel=0.85
	crane.task="core";crane.station="receiver";crane.raised=false
	crane.POINT_IDS.assign(["core_front","core_aft"])
	crane.endpoints.a={"state":"attached","point":"core_front"};crane.endpoints.b={"state":"attached","point":"core_aft"}
	expect(evaluate("chest",2).current==7 and not evaluate("chest",2).fits_complete,"core capture advances to releasing the front connector before mounting")
	crane.endpoints.a={"state":"stowed","point":""}
	expect(evaluate("chest",2).current==8,"front connector release advances to guide seating")
	game.model.assemblies.chest.slots.core="core";guide.travel=2.2
	expect(evaluate("chest",2).current == -1,"physical core seating completes its delivery")
	crane.endpoints.b={"state":"stowed","point":""}
	# A whole-robot state fixture exercises every authored chapter after all
	# shared machines have moved on. No stage journey or rendering is involved.
	for owner in game.model.assemblies:fill(str(owner),game.model.assemblies[owner].slots.keys())
	for id in pins.locked:pins.locked[id]=true
	game.model.assemblies.arm_cassette.location="support:cassette_station"
	game.model.assemblies.right_foot.parent="right_leg"
	rail.active_assembly="right_leg";rail.engaged=false;rail.path=0.0;rail.release=0.0;rail.index_x=20.0
	foot.path=0.0
	crane.task="head_crown";crane.station="park";crane.raised=true
	guide.connected=true;guide.bolts.fill(true)
	var pack=machine(preload("res://scripts/backpack_hinge.gd"),"backpack_hinge")
	pack.angle=1.0;pack.struts.fill(1.0);pack.latches.fill(true);pack.covers.fill(true)
	for side in ["left","right"]:
		var shoulder=machine(preload("res://scripts/shoulder_support.gd"),side+"_shoulder")
		shoulder.brakes=true
	for id in game.leg_content.equipment.receivers:
		var receiver=machine(preload("res://scripts/staged_receiver.gd"),str(id))
		receiver.spec=game.leg_content.equipment.receivers[id]
		for operation in receiver.spec.get("operations",[]):receiver.released_operations[str(operation.id)]=true
	for fixture in braces.fixtures:fixture.locked=true
	progress=Progress.new(game)
	var unfinished: Array[String]=[]
	for chapter in progress.chapters():
		for step in chapter.steps:
			if progress.status(step.owner,step.page)!="done":unfinished.append(str(chapter.id)+" / "+str(step.title)+" "+str(progress.evaluation(step.owner,step.page).ticked))
	expect(unfinished.is_empty() and progress.complete(),"all chapters complete from retained physical state: "+str(unfinished))
	crane.task="backpack";crane.station="receiver";crane.raised=false
	crane.endpoints.a.state="attached";crane.endpoints.b.state="attached"
	pack.angle=0.0;pack.latches.fill(false);pack.covers.fill(false);pack.locks.fill(true)
	expect(evaluate("chest",7).current == -1,"connected services preserve strut work when closing reacquires the crane")
	pack.locks.fill(false)
	expect(evaluate("chest",7).current != -1,"service connections alone cannot hide unlocked open struts")
	pack.angle=1.0;pack.latches.fill(true);crane.endpoints.a.state="stowed";crane.endpoints.b.state="stowed"
	crane.station="park";crane.raised=true
	crane.task="backpack";pack.covers.fill(false)
	expect(evaluate("chest",9).current==8,"latched backpack retires crane tension but still requires its covers")
	pack.covers.fill(true)
	expect(evaluate("chest",9).current == -1,"closed covers complete the latched backpack")
	crane.task="head_crown"
	pins.locked.left_hip_2=false;progress.refresh()
	expect(not progress.complete() and progress.status("pelvis",9)!="done" and not progress.evaluation("pelvis",9).ticked[2],"even a late robot state cannot hide an undone cylinder lock")
	var passed=checks.all(func(check):return check.passed)
	print("MANUAL_COMPLETION ","PASS " if passed else "FAIL ",checks.size()," checks")
	game.free();quit(0 if passed else 1)
