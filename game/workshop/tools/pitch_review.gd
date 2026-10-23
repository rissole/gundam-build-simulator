extends "res://tests/desktop_runner_entry.gd"
## Rendered pitch review: ./play.command --disable-render-loop --fixed-fps 60 --script tools/pitch_review.gd -- [review flags]
func _initialize() -> void:
	launch("foot","res://tests/pitch_visual_review.gd")
