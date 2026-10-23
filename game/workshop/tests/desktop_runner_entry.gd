extends SceneTree
## Boots the workshop on a named profile and hands it to an in-scene runner.
func launch(profile_id: String, runner_path: String, configure: Callable = Callable()) -> void:
	var game = load("res://scenes/workshop.tscn").instantiate()
	game.profile_override = profile_id
	game.automated_test = true
	root.add_child(game)
	var runner = load(runner_path).new()
	if configure.is_valid():configure.call(runner)
	game.add_child(runner)
	runner.call_deferred("run",game)
