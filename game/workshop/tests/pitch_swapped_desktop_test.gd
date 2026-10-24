extends "res://tests/desktop_runner_entry.gd"
## Normal collection supplies the second identical physical copy first.
func _initialize() -> void:
	launch("res://tests/pitch_build_test.gd",func(runner):runner.swap_identical = true)
