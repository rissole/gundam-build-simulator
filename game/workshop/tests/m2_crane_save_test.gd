extends "res://tests/kit/crane_suite.gd"
const ModelSave = preload("res://scripts/save_model.gd")
var snapshots: Array[Dictionary] = []

func remember(label: String) -> void:
	var captured: Dictionary = JSON.parse_string(JSON.stringify(game.saves.capture()))
	var live_before = JSON.stringify(game.saves.capture())
	var errors: Array[String] = game.saves.validate(captured)
	if not errors.is_empty():print("M2_CRANE_SAVE_DIAGNOSTIC ",label," ",errors)
	expect(errors.is_empty(),label+" validates against detached saved ownership")
	expect(live_before == JSON.stringify(game.saves.capture()),label+" validation never mutates live equipment or inventory")
	snapshots.append({"label":label,"snapshot":captured})

func reject(data: Dictionary, label: String) -> void:
	var before = JSON.stringify(game.saves.capture())
	expect(not game.saves.validate(data).is_empty(),label+" is rejected")
	expect(not game.saves.apply_snapshot(data) and before == JSON.stringify(game.saves.capture()),label+" rejects without any live mutation")

func run() -> void:
	await boot();remember("Parked rack-owned beam")
	await source_route()
	await aim_action("pick:magnet_a");remember("Held magnetic end")
	await aim_action("attach:beam_near",true);remember("One endpoint attached")
	await walk(Vector3(6.85,0,18.14),"far end for save journey")
	await aim_action("pick:magnet_b");await aim_action("attach:beam_far",true)
	remember("Both endpoints rigged with source support retained")
	await walk(Vector3(6.85,0,20.1),"source exit for save journey")
	await walk(Vector3(4.9,0,21.9),"console for saved transfer")
	await console_action("up");remember("Taking weight before source release")
	for tick in range(180):
		await frames(1)
		if crane.path>.10:break
	remember("Suspended crane-owned transfer")
	crane.console.buttons.stop.pressed.emit();remember("Stopped suspended transfer")
	var stopped: float = crane.path
	game.set_paused(true);await frames(5)
	expect(crane.path == stopped,"Escape-style pause preserves suspended support and progress")
	game.set_paused(false)
	expect(crane.request("resume").is_empty(),"Stopped suspended transfer resumes through command API")
	# Introduce a real person-sized obstacle after motion begins; it must stop
	# before changing path, with the same two cable contacts and crane ownership.
	var block = StaticBody3D.new();block.collision_layer = 8
	var shape = CollisionShape3D.new();var box = BoxShape3D.new();box.size = Vector3(.4,3,.4);shape.shape = box;block.add_child(shape);game.add_child(block)
	block.global_position = crane.load_pose()*Vector3(0,1.0,0)
	await frames(3)
	expect(not crane.blocked_reason.is_empty(),"Dynamic route obstacle blocks crane motion with support retained")
	remember("Dynamically blocked suspended transfer")
	block.free();await frames(2)
	expect(await settle(),"Clearing dynamic obstacle recovers the same supported transfer")
	remember("Raised source load")
	await console_action("go:receiver");await frames(30);remember("Suspended horizontal travel")
	expect(await settle(),"Horizontal travel completes")
	await console_action("down");await frames(30);remember("Receiver lowering")
	expect(await settle(),"Receiver Down seats beam")
	remember("Seated beam with zero flange hardware and crane assistance")
	var washer_uid: String = game.model.find_item("lg-w24","bin")
	game.model.stock_pocket("lg-w24")
	washer_uid = game.model.find_item("lg-w24","pocket")
	expect(game.model.install("left_leg","fork/washer_1",washer_uid).ok,"Bounded save fixture fits one actual washer identity")
	game.components.sync("left_leg");remember("Partly fastened beam still crane-assisted")
	var partial = snapshots.back().snapshot
	var forged: Dictionary = partial.duplicate(true)
	forged.world.equipment.service_crane.route_profile = "invented_route"
	reject(forged,"Invented motion profile")
	forged = partial.duplicate(true);forged.world.equipment.service_crane.progress = 1.25
	reject(forged,"Forged off-route load pose")
	forged = partial.duplicate(true);forged.world.equipment.service_crane.station = "source"
	reject(forged,"Forged beam/cable pose")
	forged = partial.duplicate(true);forged.world.equipment.service_crane.endpoints.magnet_b.point = "beam_near"
	reject(forged,"Duplicate magnetic-point occupation")
	forged = partial.duplicate(true);forged.world.equipment.service_crane.endpoints.magnet_a = {"state":"stowed","point":""};forged.world.equipment.service_crane.raised = true
	reject(forged,"Unsecured flange missing one required magnetic contact")
	forged = partial.duplicate(true);forged.world.equipment.service_crane.source_reservation = ""
	reject(forged,"Contradictory source reservation")
	var original_game = game
	for record in snapshots:
		var fresh = load("res://scenes/workshop.tscn").instantiate();fresh.profile_override = "leg_bay_crane";fresh.automated_test = true;root.add_child(fresh);fresh.automated_test = true
		await frames(3)
		var errors: Array[String] = fresh.saves.validate(record.snapshot)
		var applied: bool = errors.is_empty() and fresh.saves.apply_snapshot(record.snapshot)
		if not applied:print("M2_FRESH_RESTORE ",record.label," ",errors)
		expect(applied and fresh.paused,"Fresh scene restores paused: "+record.label)
		if applied:
			expect(JSON.parse_string(JSON.stringify(fresh.equipment.get_equipment("service_crane").capture()))==record.snapshot.world.equipment.service_crane,"Fresh scene preserves canonical load, beam, endpoints and reservations: "+record.label)
			expect(JSON.parse_string(JSON.stringify(fresh.model.items[crane.uid]))==record.snapshot.model.items[crane.uid],"Fresh scene preserves exact beam UID ownership: "+record.label)
		fresh.free();await process_frame
	game = original_game
	await finish("M2_CRANE_SAVE","/tmp/m2-crane-save.audit.json")
