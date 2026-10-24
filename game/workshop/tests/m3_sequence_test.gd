extends "res://tests/kit/harness.gd"
## Shared forward sequence only; this is supplied mechanical progress.
const M3Stages=preload("res://scripts/m3_stages.gd")

func _initialize() -> void:call_deferred("run")

func run() -> void:
	var game=await boot_profile("leg_bay_m3");var stages=M3Stages.new(game)
	expect(not stages.stage_errors("unknown").is_empty(),"unknown boundary returns an error")
	expect(not (await stages.run_to("unknown")).is_empty(),"unknown launch stage returns an error")
	var titles: Array[String]=[]
	expect((await stages.run_to("pelvis",func(title):titles.append(title))).is_empty() and titles==[M3Stages.TITLES.pelvis],"fresh pelvis boundary reports progress without completing it")
	expect(game.model.transfer("ch-w36","bin","pocket","CH-W36__001")=="CH-W36__001","collect stock before checking fresh-workshop rejection")
	expect(not (await stages.run_to("pelvis")).is_empty(),"pocketed stock makes the workshop non-fresh even before pelvis delivery")
	game.model.clear_pocket(game.model.pocket_for("ch-w36"))
	for stage in M3Stages.STAGES:
		var errors: Array[String]=stages.stage_errors(stage)
		expect(errors.is_empty(),stage+" starts at its boundary: "+str(errors))
		if not errors.is_empty():break
		if stage=="head":
			expect(not stages.complete(stage).is_empty(),"last stage has no completion yet")
			break
		var error: String=stages.complete(stage)
		expect(error.is_empty(),stage+" completes: "+error)
		if not error.is_empty():break
		if stage=="pelvis":expect(not (await stages.run_to("chest")).is_empty(),"stage runner rejects a non-fresh workshop")
		await process_frame
	var passed=checks.all(func(check):return check.passed)
	write_evidence("res://verification/m3-sequence.json",{"scope":"shared supplied happy path through closed pauldrons and released restraints; no walking/access/rendered review","checks":checks})
	print("M3_SEQUENCE ","PASS " if passed else "FAIL ",checks.size()," checks")
	game.free();quit(0 if passed else 1)
