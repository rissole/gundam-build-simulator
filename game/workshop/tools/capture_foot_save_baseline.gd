extends SceneTree
## Writes the pinned foot-workshop save fixture used by foot_save_pin_test.gd.
## Run once from the pre-consolidation baseline:
##   ./play.command --headless --script tools/capture_foot_save_baseline.gd
const FIXTURE = "res://tests/fixtures/foot-save-baseline.json"
const Staging = preload("res://scripts/scenario_staging.gd")
var game: Node

func _initialize() -> void:
	run.call_deferred()

func _stage(owner: String, limit: int) -> void:
	Staging.fill(game,owner,[],limit)

func run() -> void:
	game = load("res://scenes/workshop.tscn").instantiate();game.profile_override = "foot"
	root.add_child(game)
	game.automated_test = true
	for index in range(6):await physics_frame
	assert(game.foot_fixture != null and game.profile.id == "foot","Baseline must use the supported foot workshop.")
	for pair in [["pad_1","prep"],["pitch","prep3"]]:
		var error: String = game.automation.suspend_at_station(pair[0],pair[1])
		assert(error.is_empty(),error)
	_stage("pad_1",3)
	_stage("pitch",6)
	game.model.stock_pocket(game.model.definitions.assemblies.foot.slots["heel_1/washer_0"].accepts)
	game.player.global_position = Vector3(1.2,0.1,3.4)
	game.hud.open_manual("pitch")
	for index in range(3):await physics_frame
	var temporary = "/tmp/gundam-foot-baseline-%s.json" % OS.get_process_id()
	game.saves.setup(game,temporary,false)
	assert(game.saves.save_now(),"Baseline save failed: "+game.saves.message)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://tests/fixtures"))
	var bytes = FileAccess.get_file_as_bytes(temporary)
	var out = FileAccess.open(FIXTURE,FileAccess.WRITE)
	out.store_buffer(bytes)
	out.close()
	DirAccess.remove_absolute(temporary)
	print("FOOT_FINGERPRINT ",game.saves.fingerprint)
	print("FOOT_FIXTURE_WRITTEN ",FIXTURE)
	quit(0)
