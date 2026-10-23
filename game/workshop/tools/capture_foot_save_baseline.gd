extends SceneTree
## Writes the pinned foot-workshop save fixture used by foot_save_pin_test.gd.
## Run once from the pre-consolidation baseline:
##   ./play.command --headless --script tools/capture_foot_save_baseline.gd
const FIXTURE = "res://tests/fixtures/foot-save-baseline.json"
var game: Node

func _initialize() -> void:
	run.call_deferred()

func _stage(owner: String, limit: int) -> void:
	var count = 0
	var definition: Dictionary = game.runtime.definition(owner)
	for pass_index in range(definition.slots.size()):
		var changed = false
		for sid in definition.slots:
			if count >= limit:break
			if not game.model.assemblies[owner].slots[sid].is_empty():continue
			var spec: Dictionary = definition.slots[sid]
			if spec.has("assembly") or not spec.get("requires",[]).all(func(r):return not game.model.assemblies[owner].slots[r].is_empty()):continue
			var uid: String
			if game.model.definitions.parts[spec.accepts].carry_class == "pocket":
				game.model.stock_pocket(spec.accepts)
				uid = game.model.find_item(spec.accepts,"pocket")
			else:
				uid = game.model.find_item(spec.accepts,"bin")
				game.model.carry_item(uid)
			if uid.is_empty():continue
			assert(game.model.install(owner,sid,uid).ok)
			count += 1
			changed = true
		if count >= limit or not changed:break
	if game.builds.has(owner):
		game._activate(owner)
		game._sync_installed_visuals()
	else:game.components.sync(owner)

func run() -> void:
	game = load("res://scenes/workshop.tscn").instantiate()
	root.add_child(game)
	game.automated_test = true
	for index in range(6):await physics_frame
	assert(game.foot_fixture != null and not game.leg_workshop,"Baseline must use the supported foot workshop.")
	for pair in [["pad_1","prep"],["pitch","prep3"]]:
		assert(game.model.move_assembly(pair[0],"station:"+pair[1]).is_empty())
		game._activate(pair[0])
		game._set_pad_station(pair[1])
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
