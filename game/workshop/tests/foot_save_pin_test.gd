extends "res://tests/kit/harness.gd"
## Existing player foot saves must keep loading through every refactor.
## The fixture was captured from the pre-consolidation baseline (commit 889986b).
const Store = preload("res://scripts/save_store.gd")
const FIXTURE = "res://tests/fixtures/foot-save-baseline.json"
const PINNED_FINGERPRINT = "8c6c1c21c92c0bdf24d45f655606de580816d1f6ccb3806ebbe35e09d37b9293"

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	var game = load("res://scenes/workshop.tscn").instantiate();game.profile_override = "foot"
	root.add_child(game)
	game.automated_test = true
	for index in range(6):await physics_frame
	expect(game.saves.fingerprint == PINNED_FINGERPRINT,"Foot workshop fingerprint is unchanged")
	var temporary = "/tmp/gundam-foot-pin-%s-%s.json" % [OS.get_process_id(),Time.get_ticks_usec()]
	var copy = FileAccess.open(temporary,FileAccess.WRITE)
	copy.store_buffer(FileAccess.get_file_as_bytes(FIXTURE))
	copy.close()
	var stored: Dictionary = Store.read(temporary,PINNED_FINGERPRINT)
	expect(stored.ok,"Pinned fixture is a readable save envelope")
	game.saves.setup(game,temporary,false)
	expect(game.saves.restored,"Fresh foot workshop restores the pinned save: "+game.saves.message)
	if stored.ok and game.saves.restored:
		var live: Dictionary = game.saves.capture()
		var normalize = func(value):return JSON.stringify(JSON.parse_string(JSON.stringify(value)),"",true)
		expect(normalize.call(live.model) == normalize.call(stored.payload.model),"Restored model ownership matches the fixture")
		expect(game.model.assemblies.pad_1.location == "station:prep" and game.model.assemblies.pitch.location == "station:prep3","Restored builds sit at their stations")
		expect(game.hud.manual_id == "pitch","Restored manual selection")
	game.free()
	DirAccess.remove_absolute(temporary)
	var passed: bool = checks.all(func(check):return check.passed)
	print(("FOOT_SAVE_PIN PASS " if passed else "FOOT_SAVE_PIN FAIL ")+"%d checks" % checks.size())
	quit(0 if passed else 1)
