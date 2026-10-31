extends "res://tests/kit/harness.gd"
## Walks every manual step in chapter order against synthetic machine states and
## checks the checklist only moves forwards: after each objective is done, it and
## every earlier objective are ticked, and every step ends Done.
## Each machine reports the cumulative effects of the objectives walked so far;
## nothing here proves that real machines reach those states (stage runs do).
const Objectives = preload("res://scripts/manual_objectives.gd")
const Progress = preload("res://scripts/manual_progress.gd")
var game

## Reports walked state; effects, commands and crane transport proof come from
## the real machine script.
class WalkMachine extends "res://scripts/equipment.gd":
	var real
	var state: Dictionary = {}
	func manual_commands() -> Array:return real.manual_commands()
	func manual_state() -> Dictionary:return state
	func manual_effect(objective: Dictionary) -> Dictionary:return real.manual_effect(objective)
	func manual_proves(condition: Dictionary) -> bool:return real.manual_proves(condition)

func _initialize() -> void:call_deferred("run")

func machine(script, id: String) -> WalkMachine:
	var real = script.new();game.add_child(real);real.game=game;real.equipment_id=id
	var walker := WalkMachine.new();game.add_child(walker);walker.game=game;walker.equipment_id=id;walker.real=real
	game.equipment.register(walker)
	return walker

func fill(owner: String, sid: String) -> void:
	var spec: Dictionary = game.model.slot_definition(owner,sid)
	game.model.assemblies[owner].slots[sid] = str(spec.get("pose_source",spec.get("assembly","fixture")))
	if spec.has("assembly") and game.model.assemblies.has(str(spec.assembly)):game.model.assemblies[str(spec.assembly)].parent = owner

## The real crane answers transport proofs from its own fields and the model.
func sync_crane(crane: WalkMachine) -> void:
	var real = crane.real
	real.task = str(crane.state.get("task",""));real.station = str(crane.state.get("station","park"));real.raised = bool(crane.state.get("raised",true))
	var attached := int(crane.state.get("attached",0))
	for i in real.END_IDS.size():real.endpoints[real.END_IDS[i]] = {"state":"attached" if i < attached else "stowed","point":""}

func perform(owner: String, objective: Dictionary, crane: WalkMachine) -> void:
	var op := str(objective.get("op",""))
	for sid in Objectives._objective_slots(objective):fill(owner,str(sid))
	var machine_id := str(objective.get("machine",""))
	var effect_objective := objective
	if op == "seat":
		if not objective.get("via") is Dictionary:return
		machine_id = str(objective.via.get("machine",""))
		effect_objective = {"op":"operate","command":str(objective.via.get("command",""))}
	if not Objectives.MACHINE_OPS.has(op) and op != "seat":return
	var walker: WalkMachine = game.equipment.get_equipment(machine_id)
	walker.state.merge(walker.manual_effect(effect_objective),true)
	if walker != crane:return
	sync_crane(crane)
	# Lowering a rigged load at its receiver sets it on that support.
	if str(effect_objective.get("command","")) == "down" and crane.state.get("station") == "receiver" and int(crane.state.get("attached",0)) > 0:
		var spec: Dictionary = crane.real.tasks.get(str(crane.state.task),{})
		var receiver := str(spec.get("receiver_support",""))
		if not receiver.is_empty() and game.model.assemblies.has(str(spec.get("load_uid",""))):game.model.assemblies[str(spec.load_uid)].location = "support:"+receiver

func run() -> void:
	var started := Time.get_ticks_msec()
	game = preload("res://tests/kit/model_workshop.gd").new();root.add_child(game)
	expect(game.setup().is_empty(),"authored model loads")
	var layout = preload("res://scripts/leg_bay_layout.gd").layout()
	var crane := machine(preload("res://scripts/service_crane.gd"),"service_crane")
	crane.real.tasks = layout.crane.tasks;crane.real.END_IDS = ["a","b"]
	crane.state = {"task":"","station":"park","raised":true,"attached":0,"held":false};sync_crane(crane)
	machine(preload("res://tests/kit/manual_fronts.gd"),"workshop_access")
	machine(preload("res://scripts/indexed_leg_rail.gd"),"leg_rail")
	machine(preload("res://scripts/foot_carrier.gd"),"foot_carrier")
	machine(preload("res://scripts/captive_controls.gd"),"captive_controls").real.specs = game.leg_content.equipment.captive_controls
	var supports := machine(preload("res://scripts/module_supports.gd"),"module_supports")
	supports.real.locks = {"yaw":false,"lean":false};supports.real.jaws.resize(4)
	machine(preload("res://scripts/passive_joint_restraints.gd"),"joint_restraints")
	machine(preload("res://scripts/core_guide.gd"),"core_guide")
	machine(preload("res://scripts/backpack_hinge.gd"),"backpack_hinge")
	for side in ["left","right"]:machine(preload("res://scripts/shoulder_support.gd"),side+"_shoulder")
	for id in game.leg_content.equipment.receivers:
		machine(preload("res://scripts/staged_receiver.gd"),str(id)).real.spec = game.leg_content.equipment.receivers[id]
	var progress = Progress.new(game)
	var walked: Array = []
	var pages := 0
	for chapter in progress.chapters():
		for step in chapter.steps:
			var owner := str(step.owner)
			var page: Dictionary = step.definition
			walked.append({"owner":owner,"page":page})
			if not page.get("objectives") is Array or page.objectives.is_empty():continue
			pages += 1
			var title := "%s · %s"%[chapter.title,step.title]
			# A machine working for this build reports that scope; the crane
			# takes its task from the pickup objective.
			var scope: Dictionary = page.get("machine_scope",{})
			for id in scope:
				if id != "service_crane":game.equipment.get_equipment(str(id)).state.merge(scope[id],true)
			var objectives: Array = page.objectives
			var failure := ""
			for k in objectives.size():
				perform(owner,objectives[k],crane)
				var evaluation := Objectives.evaluate(game,owner,page)
				for i in k+1:
					if not evaluation.ticked[i]:
						failure = "after objective %d (%s), objective %d is unticked; current is %d"%[k+1,_describe(objectives[k]),i+1,int(evaluation.current)+1]
						break
				if not failure.is_empty():break
			expect(failure.is_empty(),title+" progresses forwards"+("" if failure.is_empty() else ": "+failure))
	var done: Array = Objectives.done_states(game,walked)
	var unfinished: Array[String] = []
	for i in walked.size():
		if walked[i].page.has("objectives") and not done[i]:unfinished.append(str(walked[i].owner)+" · "+str(walked[i].page.get("title","")))
	expect(pages > 50,"the walk covers the manual (%d action steps)"%pages)
	expect(unfinished.is_empty(),"every walked step stays Done at the end: "+", ".join(unfinished))
	var passed=checks.all(func(check):return check.passed)
	print("MANUAL_WALK ","PASS " if passed else "FAIL ",checks.size()," checks in %d ms"%(Time.get_ticks_msec()-started))
	game.free();quit(0 if passed else 1)

func _describe(objective: Dictionary) -> String:
	var text := str(objective.get("op",""))
	for key in ["machine","command","task","slot"]:
		if objective.has(key):text += " "+str(objective[key])
	return text
