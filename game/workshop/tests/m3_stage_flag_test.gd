extends "res://tests/kit/harness.gd"
## Development launch flag: scripted stage preparation hands over paused at the boundary.
const M3Stages = preload("res://scripts/m3_stages.gd")
func _initialize() -> void:call_deferred("run")

func run() -> void:
	var game = await boot_profile("leg_bay_m3")
	var rejected: String = await game.run_m3_stage("no_such_stage")
	expect(not rejected.is_empty(),"unknown stage is rejected")
	expect(M3Stages.new(game).stage_errors("pelvis").is_empty(),"rejected stage leaves the fresh workshop untouched")
	game.free();await frames(2)
	for stage in ["left_leg_dock","chest","pauldrons"]:
		game = await boot_profile("leg_bay_m3")
		var error: String = await game.run_m3_stage(stage)
		expect(error.is_empty(),stage+" prepares: "+error)
		expect(game.paused,stage+" hands over paused")
		expect(M3Stages.new(game).stage_errors(stage).is_empty(),stage+" boundary holds after handover")
		# boot_profile sets automated_test; run_m3_stage must restore the prior value.
		expect(game.automated_test,stage+" restores the prior input mode")
		game.free();await frames(2)
	var passed = checks.all(func(check):return check.passed)
	print("M3_STAGE_FLAG ","PASS " if passed else "FAIL ",checks.size()," checks")
	quit(0 if passed else 1)
