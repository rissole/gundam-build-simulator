extends "res://tests/kit/harness.gd"
## Expensive diagnostic, explicit request only: the save round trip at every stage
## boundary from the foot to the complete robot, and partway through each stage's
## first crane delivery. Each reload boots in its own physics world beside the
## workshop under test.
const Save = preload("res://scripts/workshop_save.gd")
const Stages = preload("res://scripts/build_stages.gd")
const Roundtrip = preload("res://tests/kit/save_roundtrip.gd")
const PATH = "user://save-roundtrip-stages.json"
## [motion, station, progress]: lifting off the source (partial clamp release),
## then halfway along the route to the receiver.
const POINTS = [["up","source",.05],["go:receiver","source",.5]]

## Saves the workshop when a crane move passes each remaining point.
class Sampler extends "res://scripts/build_stages.gd":
	var points: Array = []
	var samples: Array[Dictionary] = []
	func settle(controller: Node, limit: int = 1600) -> String:
		if controller.equipment_id != "service_crane":return super(controller,limit)
		for tick in range(limit):
			if not controller.moving or points.is_empty():break
			_equipment("workshop_access").physics(.1)
			controller.physics(.1)
			var point: Array = points[0]
			if controller.moving and controller.motion == point[0] and controller.station == point[1] and controller.progress >= point[2]:
				points.pop_front()
				var path: String = "user://save-roundtrip-sample-"+str(samples.size())+".json"
				var error: String = preload("res://scripts/workshop_save.gd").new(game,path).write(game.save.snapshot())
				samples.append({"label":controller.task+" "+point[0]+" at "+str(snappedf(controller.progress,.01)),"path":path,"error":error,"state":preload("res://tests/kit/save_roundtrip.gd").state(game)})
		return super(controller,limit)
func _initialize() -> void:call_deferred("run")
func run() -> void:
	Save.delete(PATH)
	var game = await boot_workshop("",8,{"save_path":PATH})
	var runner = Sampler.new(game)
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
		runner.points = POINTS.duplicate()
		var error: String = runner.complete(stage)
		expect(error.is_empty(),stage+" completed: "+error)
		for sample in runner.samples:
			expect(sample.error.is_empty(),stage+" "+sample.label+" save written: "+sample.error)
			var halted = await Roundtrip.boot_isolated(self,sample.path)
			var mid: Array[String] = Roundtrip.differences(sample.state,Roundtrip.state(halted))
			expect(mid.is_empty(),stage+" "+sample.label+" reload matches: "+"; ".join(mid))
			expect(halted.model.integrity_errors().is_empty() and not halted.equipment.get_equipment("service_crane").moving,stage+" "+sample.label+" reload is valid with the crane stopped")
			halted.get_parent().free()
			Save.delete(sample.path)
			await frames(2)
		runner.samples.clear()
		if not error.is_empty():break
		await process_frame
	game.free()
	Save.delete(PATH)
	var passed = checks.all(func(c):return c.passed)
	print("SAVE_ROUNDTRIP_STAGES ","PASS " if passed else "FAIL ",checks.size()," checks")
	quit(0 if passed else 1)
