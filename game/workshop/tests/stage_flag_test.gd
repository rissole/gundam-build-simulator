extends "res://tests/kit/harness.gd"
## Development launch flag: scripted stage preparation hands over paused at the boundary.
const Stages = preload("res://scripts/build_stages.gd")
func _initialize() -> void:call_deferred("run")

func run() -> void:
	var game = await boot_workshop()
	var rejected: String = await game.run_stage("no_such_stage")
	expect(not rejected.is_empty(),"unknown stage is rejected")
	expect(Stages.new(game).stage_errors("foot").is_empty(),"rejected stage leaves the fresh workshop untouched")
	game.free();await frames(2)
	for stage in ["left_leg_dock","complete"]:
		game = await boot_workshop()
		var error: String = await game.run_stage(stage)
		expect(error.is_empty(),stage+" prepares: "+error)
		expect(game.paused,stage+" hands over paused")
		expect(Stages.new(game).stage_errors(stage).is_empty(),stage+" boundary holds after handover")
		# boot_workshop sets automated_test; run_stage must restore the prior value.
		expect(game.automated_test,stage+" restores the prior input mode")
		game.free();await frames(2)
	var passed = checks.all(func(check):return check.passed)
	print("STAGE_FLAG ","PASS " if passed else "FAIL ",checks.size()," checks")
	quit(0 if passed else 1)
