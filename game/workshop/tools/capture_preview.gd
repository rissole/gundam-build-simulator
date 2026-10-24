extends SceneTree
## Rendered preview of the launch profile: ./play.command --script tools/capture_preview.gd -- [profile flags]
func _initialize() -> void:
	capture.call_deferred()

func capture() -> void:
	var game = load("res://scenes/workshop.tscn").instantiate();game.profile_override = "foot"
	root.add_child(game)
	game.set_paused(false)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	await create_timer(2).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://verification/workshop.png")
	print("PREVIEW_SAVED")
	quit()
