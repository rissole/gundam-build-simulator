extends "res://tests/kit/harness.gd"
## Boots the robot workshop and hands it to an in-scene runner.
func launch(runner_path: String, configure: Callable = Callable()) -> void:
	var game = instantiate_workshop(self)
	var runner = load(runner_path).new()
	if configure.is_valid():configure.call(runner)
	game.add_child(runner)
	runner.call_deferred("run",game)
