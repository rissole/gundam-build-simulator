extends "res://tests/kit/harness.gd"
## Workshop save round trip from a fresh boot: manual saving, build state, machine
## stops, the player's position, the crane stopped mid-delivery and deletion of
## invalid files. Later stages: save_roundtrip_stages_test.
const Save = preload("res://scripts/workshop_save.gd")
const Stages = preload("res://scripts/build_stages.gd")
const Roundtrip = preload("res://tests/kit/save_roundtrip.gd")
const PATH = "user://save-roundtrip-test.json"
func _initialize() -> void:call_deferred("run")
func run() -> void:
	Save.delete(PATH)
	var game = await boot_workshop("",8,{"save_path":PATH})
	expect(game.save.enabled() and not FileAccess.file_exists(PATH) and not game.save.unsaved(),"an opted-in fresh workshop writes nothing and has no unsaved changes")
	expect(game.automation.suspend_at_station("pad_1","prep").is_empty() and game.automation.fill("pad_1",2) == 2,"pad_1 sits at a station with two fitted sleeves")
	await frames(2,false)
	expect(not FileAccess.file_exists(PATH) and game.save.unsaved(),"setting a component does not save; it is an unsaved change")
	expect(game.save.save_now().is_empty() and FileAccess.file_exists(PATH) and not game.save.unsaved(),"Save writes the workshop")
	var fixture = game.equipment.get_equipment("foot_fixture")
	expect(Stages.new(game).command(fixture,"sole_left").is_empty() and fixture.work_pose == "sole_left","the foot fixture turns to a stop")
	await frames(2)
	expect(Stages.new(game).gantry_front("lower",true).is_empty(),"player opens lower front before the snapshot")
	var lift = game.equipment.get_equipment("left_lift")
	var lift_rest: String = JSON.stringify(lift.capture())
	# Ride the lift: a mid-ride save stands the player back on the deck at its stop.
	game.player.global_position = lift.deck.global_position+Vector3.UP*.4
	game.player.rotation.y = .7
	game.camera.rotation.x = -.3
	await frames(30)
	var pose: Transform3D = game.player.global_transform
	expect(lift.rider() != null,"the player stands on the left lift deck")
	expect(lift.request("up").is_empty() and lift.moving,"the left lift starts moving")
	expect(game.automation.fill("pad_1",1) == 1,"a sleeve is fitted while the lift moves")
	await frames(2,false)
	var undone: Dictionary = game.model.undo("pad_1")
	game.components.sync("pad_1")
	expect(undone.ok,"an undo is saved like any other change")
	await frames(2,false)
	await frames(20)
	expect(lift.moving and lift.rider() != null and game.player.global_position.y > pose.origin.y+.05,"the lift is still carrying the player up when the save is written: moving="+str(lift.moving)+" riding="+str(lift.rider() != null)+" rise="+str(game.player.global_position.y-pose.origin.y))
	expect(game.save.save_now().is_empty(),"Save writes mid-ride")
	var file: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	expect(JSON.stringify(Save.coerce(file.equipment.left_lift,lift.capture())) == lift_rest,"a moving machine is saved at its last stop")
	expect(file.equipment.has("service_crane") and file.equipment.service_crane.station == "park","the parked crane is saved")
	expect(file.equipment.workshop_access.version==2 and not file.equipment.workshop_access.has("mode") and file.equipment.workshop_access.channels.rear.value==1 and file.equipment.workshop_access.channels["20.6"].value==0,"save keeps independent fronts in version 2")
	var saved: Dictionary = Roundtrip.state(game)
	game.free()
	await frames(2)
	var loaded = await boot_workshop("",8,{"save_path":PATH})
	var differences: Array[String] = Roundtrip.differences(saved,Roundtrip.state(loaded))
	expect(differences.is_empty(),"the reload matches the saved workshop: "+"; ".join(differences))
	expect(loaded.player.global_position.distance_to(pose.origin) < .05 and is_equal_approx(loaded.player.rotation.y,.7) and is_equal_approx(loaded.camera.rotation.x,-.3) and not loaded.save.unsaved(),"the player reloads on the deck at the lift's last stop, looking the same way, with nothing unsaved")
	var crane = loaded.equipment.get_equipment("service_crane")
	expect(crane.station == "park" and crane.attached_count() == 0,"the crane reloads parked with its ends stowed")
	expect(loaded.model.integrity_errors().is_empty() and loaded.model.held_item().is_empty() and loaded.held_build().is_empty() and loaded.model.pockets.all(func(kind):return kind.is_empty()),"the reload is valid with empty hands and pockets")
	expect(Save.notice.begins_with("Restored"),"the pause menu notice reports the restore")
	# Invalid files are deleted before anything live changes.
	var good: String = FileAccess.get_file_as_string(PATH)
	var before: String = JSON.stringify(loaded.save.normalised_model())
	var wrong_format: Dictionary = JSON.parse_string(good)
	wrong_format.format = 999
	var unknown: Dictionary = JSON.parse_string(good)
	unknown.model.items["ghost"] = unknown.model.items.values()[0]
	var renamed: Dictionary = JSON.parse_string(good)
	renamed.equipment.left_lift["renamed"] = 1
	var old_access: Dictionary = JSON.parse_string(good)
	old_access.equipment.workshop_access.version=1
	old_access.equipment.workshop_access.mode="work"
	for case in [["old access version",JSON.stringify(old_access)],["truncated JSON",good.substr(0,good.length()/2)],["wrong format",JSON.stringify(wrong_format)],["unknown identity",JSON.stringify(unknown)],["changed machine fields",JSON.stringify(renamed)]]:
		var out = FileAccess.open(PATH,FileAccess.WRITE)
		out.store_string(case[1])
		out.close()
		Save.notice = ""
		expect(not loaded.save.load_saved() and not FileAccess.file_exists(PATH) and Save.notice.begins_with("Your saved workshop") and JSON.stringify(loaded.save.normalised_model()) == before,"discarded without changes: "+case[0])
	# A save mid-delivery keeps the crane stopped where it was, its load hanging.
	var runner = Stages.new(loaded)
	var bulky = loaded.equipment.get_equipment("module_supports")
	expect(["lock:yaw","lock:lean"].all(func(action):return runner.command(bulky,action).is_empty()) and runner.command(crane,"pickup").is_empty() and runner.command(crane,"down").is_empty(),"the crane is down over the pelvis")
	runner.supply_rig(crane,true)
	expect(crane.request("up").is_empty(),"the crane starts lifting the pelvis")
	for tick in range(200):
		if not crane.moving or crane.progress >= .5:break
		loaded.equipment.get_equipment("workshop_access").physics(.1)
		crane.physics(.1)
	expect(crane.moving and loaded.model.assemblies.pelvis.location == "support:crane_rigging","the pelvis hangs on the moving crane")
	expect(loaded.save.save_now().is_empty(),"Save writes mid-delivery")
	var lifted: Dictionary = Roundtrip.state(loaded)
	var progress: float = crane.progress
	loaded.free()
	await frames(2)
	var resumed = await boot_workshop("",8,{"save_path":PATH})
	differences = Roundtrip.differences(lifted,Roundtrip.state(resumed))
	expect(differences.is_empty(),"the mid-delivery reload matches: "+"; ".join(differences))
	var halted = resumed.equipment.get_equipment("service_crane")
	expect(not halted.moving and halted.station == "source" and halted.motion == "up" and is_equal_approx(halted.progress,progress) and halted.attached_count() == halted.required_ends,"the crane reloads stopped mid-lift with its ends attached")
	expect(halted.request("resume").is_empty() and halted.moving,"Resume continues the lift")
	resumed.free()
	Save.delete(PATH)
	var passed = checks.all(func(c):return c.passed)
	print("SAVE_ROUNDTRIP ","PASS " if passed else "FAIL ",checks.size()," checks")
	quit(0 if passed else 1)
