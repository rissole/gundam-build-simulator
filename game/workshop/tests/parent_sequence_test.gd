extends "res://tests/kit/harness.gd"
## Isolate all parent connections after preparing the child through its real rules.
var game: Node
var driver: Node

func _initialize() -> void:
	run.call_deferred()

func finish() -> void:
	checks.append_array(driver.checks)
	var passed: bool = checks.all(func(c):return c.passed)
	DirAccess.make_dir_recursive_absolute("res://verification/parent-sequence")
	write_evidence("res://verification/parent-sequence/headless-audit.json",{"passed":passed,"checks":checks,"engine":Engine.get_version_info()})
	print("PARENT_SEQUENCE ","PASS" if passed else "FAIL"," ",checks.size()," checks")
	quit(0 if passed else 1)

func run() -> void:
	game = load("res://scenes/workshop.tscn").instantiate()
	root.add_child(game)
	driver = load("res://tests/pitch_build_test.gd").new()
	root.add_child(driver)
	driver.game = game
	await driver.frames(10)
	game.automated_test = true
	game.set_paused(false)
	game.model.move_assembly("pitch","station:prep3")
	game.automation.select_build("pitch")
	expect(game.automation.suspend_at_station("pitch","prep3").is_empty(),"Stage selected build at station")
	var staged: bool = true
	for step in game.components.definition("pitch").manual:
		if step.get("view","") == "prepared":continue
		for sid in step.slots:
			var spec: Dictionary = game.model.slot_definition("pitch",sid)
			var uid: String = game.model.find_item(spec.accepts,"bin")
			if game.model.definitions.parts[spec.accepts].carry_class == "pocket":
				game.model.stock_pocket(spec.accepts)
				uid = game.model.find_item(spec.accepts,"pocket")
			else:game.model.carry_item(uid)
			staged = game.model.install("pitch",sid,uid).ok and staged
	game.components.sync("pitch")
	expect(staged and game.model.milestone("pitch","prepared"),"Prepare the child fixture through all authored prerequisites")
	game.hud.open_manual("pad_2",1)
	for page in game.components.definition("foot").manual.slice(3,5):
		for sid in page.slots:
			if not game.model.assemblies.foot.slots[sid].is_empty():continue
			if not await driver.place_slot("foot",sid):finish();return
	# Seat the actual prepared child via ordinary carry and public click input.
	await driver.aim(game.bodies.pitch.global_position)
	driver.key(KEY_E)
	await driver.frames(40)
	await driver.aim(Vector3(-6.4,1.5,1.8))
	await driver.frames(100)
	await driver.aim(game.mount_point("pitch","foot","pitch"),2.0)
	await driver.frames(100)
	driver.click()
	expect(game.model.assemblies.foot.slots.pitch == "pitch","Seat the prepared child through the actual parent connection")
	if game.model.assemblies.foot.slots.pitch.is_empty():finish();return
	for sid in game.components.definition("foot").manual[5].slots:
		if sid == "pitch" or not game.model.assemblies.foot.slots[sid].is_empty():continue
		if not await driver.place_slot("foot",sid):finish();return
	expect(driver.installed_count == 18 and game.model.milestone("foot","pitch_secured"),"All eighteen parent parts fit in actual order with their receiving geometry present")
	expect(game.hud.manual_id == "pad_2" and game.hud.page == 1,"The entire parent sequence preserves the unrelated selected manual")
	expect(game.model.integrity_errors().is_empty(),"Full parent sequence preserves physical ownership and exact dependencies")
	finish()
