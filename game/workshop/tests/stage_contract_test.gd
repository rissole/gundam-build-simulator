extends "res://tests/kit/harness.gd"
const Stages=preload("res://scripts/build_stages.gd")
class Sequence extends "res://scripts/build_stages.gd":
	var visited: Array=[]
	var rejected=""
	var failed=""
	func stage_errors(stage: String) -> Array[String]:return ["blocked"] if stage==rejected else []
	func complete(stage: String) -> String:
		visited.append(stage)
		return "completion failed" if stage==failed else ""
class Prepared extends RefCounted:
	var calls: Array=[]
	func run_to(stage: String, progress: Callable) -> String:
		calls.append(stage);progress.call("Fixture stage")
		return ""
class SettledSave extends RefCounted:
	var settled=0
	func settle() -> void:settled+=1
class Handover extends "res://scripts/workshop.gd":
	var runner=Prepared.new()
	func _init() -> void:save=SettledSave.new()
	func _ready() -> void:pass
	func set_paused(value: bool) -> void:paused=value
	func create_stage_runner() -> RefCounted:return runner
func _initialize() -> void:call_deferred("run")
func run() -> void:
	var host=Node.new();root.add_child(host)
	expect(Stages.stage_flag([])=="" and Stages.stage_flag(["--stage=pelvis"])=="pelvis","stage argument parsing")
	var sequence=Sequence.new(host)
	expect(not (await sequence.run_to("unknown")).is_empty() and sequence.visited.is_empty(),"unknown boundary does no work")
	sequence.rejected="foot"
	expect(not (await sequence.run_to("pelvis")).is_empty() and sequence.visited.is_empty(),"invalid starting boundary does no work")
	sequence.rejected=""
	var titles: Array=[]
	expect((await sequence.run_to("pelvis",func(title):titles.append(title))).is_empty(),"sequence reaches requested boundary")
	expect(sequence.visited==["foot","actuator"] and titles==[Stages.TITLES.foot,Stages.TITLES.actuator,Stages.TITLES.pelvis],"sequence completes only preceding stages and reports arrival")
	sequence.visited.clear();sequence.failed="actuator"
	expect(not (await sequence.run_to("chest")).is_empty() and sequence.visited==["foot","actuator"],"failed completion prevents subsequent work")
	sequence.failed="";sequence.rejected="pelvis";sequence.visited.clear()
	expect(not (await sequence.run_to("chest")).is_empty() and sequence.visited==["foot","actuator"],"intermediate invalid boundary prevents continuation")
	var game=Handover.new();root.add_child(game);game.automated_test=true
	expect(not (await game.run_stage("unknown")).is_empty() and game.runner.calls.is_empty(),"handover rejects unknown stages before runner")
	for automated in [false,true]:
		game.automated_test=automated
		expect((await game.run_stage("pelvis")).is_empty() and not game.paused and not game.staging and game.automated_test==automated,"handover restores input mode and enters play after supplied progress")
	expect(game.save.settled==2,"each prepared stage establishes the session baseline")
	expect(game.runner.calls==["pelvis","pelvis"] and game.stage_notice.contains("not playtested"),"handover reports supplied progress honestly")
	var passed=checks.all(func(c):return c.passed)
	print("STAGE_CONTRACT ","PASS " if passed else "FAIL ",checks.size()," checks")
	game.free();host.free();quit(0 if passed else 1)
