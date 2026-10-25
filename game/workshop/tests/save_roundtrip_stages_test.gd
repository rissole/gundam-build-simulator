extends "res://tests/kit/harness.gd"
## Expensive diagnostic, explicit request only: the save round trip at every stage
## boundary from the foot to the complete robot. Each reload boots in its own
## physics world beside the workshop under test.
const Save = preload("res://scripts/workshop_save.gd")
const Stages = preload("res://scripts/build_stages.gd")
const Roundtrip = preload("res://tests/kit/save_roundtrip.gd")
const PATH = "user://save-roundtrip-stages.json"
func _initialize() -> void:call_deferred("run")
func run() -> void:
	Save.delete(PATH)
	var game = await boot_workshop("",8,{"save_path":PATH})
	var runner = Stages.new(game)
	for stage in Stages.ALL:
		var errors: Array[String] = runner.stage_errors(stage)
		expect(errors.is_empty(),stage+" boundary reached: "+"; ".join(errors))
		if not errors.is_empty():break
		expect(game.save.write(game.save.snapshot()).is_empty(),stage+" save written")
		var saved: Dictionary = Roundtrip.state(game)
		var loaded = await Roundtrip.boot_isolated(self,PATH)
		var differences: Array[String] = Roundtrip.differences(saved,Roundtrip.state(loaded))
		expect(differences.is_empty(),stage+" reload matches: "+"; ".join(differences))
		expect(loaded.model.integrity_errors().is_empty() and loaded.equipment.get_equipment("service_crane").station == "park",stage+" reload is valid with the crane parked")
		loaded.get_parent().free()
		await frames(2)
		if stage == Stages.ALL.back():break
		var error: String = runner.complete(stage)
		expect(error.is_empty(),stage+" completed: "+error)
		if not error.is_empty():break
		await process_frame
	game.free()
	Save.delete(PATH)
	var passed = checks.all(func(c):return c.passed)
	print("SAVE_ROUNDTRIP_STAGES ","PASS " if passed else "FAIL ",checks.size()," checks")
	quit(0 if passed else 1)
