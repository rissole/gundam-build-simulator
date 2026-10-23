extends "res://scripts/work_access_lift.gd"
func _sweep_error(from: float, to: float) -> String:
	var error = super._sweep_error(from,to)
	if not error.is_empty():return error
	if is_instance_valid(game.m2) and is_instance_valid(game.m2.shelf):return game.m2.shelf.lift_sweep(from,to)
	return ""

func _pose() -> void:
	super._pose()
	if is_instance_valid(game.m2) and is_instance_valid(game.m2.shelf):game.m2.shelf.sync()
