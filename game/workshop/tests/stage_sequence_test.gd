extends "res://tests/kit/harness.gd"
## Shared forward sequence only; this is supplied mechanical progress.
const Stages=preload("res://scripts/build_stages.gd")

func _initialize() -> void:call_deferred("run")

func run() -> void:
	var game=await boot_workshop();var stages=Stages.new(game)
	expect(not stages.stage_errors("unknown").is_empty(),"unknown boundary returns an error")
	expect(not (await stages.run_to("unknown")).is_empty(),"unknown launch stage returns an error")
	expect(game.model.transfer("ch-w36","bin","pocket","CH-W36__001")=="CH-W36__001","collect stock before checking fresh-workshop rejection")
	expect(not (await stages.run_to("pelvis")).is_empty(),"pocketed stock makes the workshop non-fresh before any stage")
	game.model.clear_pocket(game.model.pocket_for("ch-w36"))
	var titles: Array[String]=[]
	expect((await stages.run_to("pelvis",func(title):titles.append(title))).is_empty() and titles==[Stages.TITLES.foot,Stages.TITLES.actuator,Stages.TITLES.pelvis],"fresh workshop supplies the foot and reports each stage up to the pelvis boundary")
	for stage in Stages.STAGES:
		var errors: Array[String]=stages.stage_errors(stage)
		expect(errors.is_empty(),stage+" starts at its boundary: "+str(errors))
		if not errors.is_empty():break
		if stage=="complete":
			expect(not stages.complete(stage).is_empty(),"last stage has no completion yet")
			break
		var error: String=stages.complete(stage)
		expect(error.is_empty(),stage+" completes: "+error)
		if not error.is_empty():break
		if stage=="pelvis":expect(not (await stages.run_to("chest")).is_empty(),"stage runner rejects a non-fresh workshop")
		await process_frame
	var passed=checks.all(func(check):return check.passed)
	write_evidence("res://verification/stage-sequence.json",{"scope":"shared supplied happy path through the complete retained/connected head and parked crane; no walking/access/rendered review","checks":checks})
	print("STAGE_SEQUENCE ","PASS " if passed else "FAIL ",checks.size()," checks")
	game.free();quit(0 if passed else 1)
