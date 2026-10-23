extends Node
## Deliberately has no save-store or normal save-codec dependency.
var game: Node
var enabled = false
var blocked = false
var has_save = false
var restored = false
var applying = false

func setup(workshop: Node, _path_override: String = "", _automatic: bool = true) -> void:
	game = workshop
	if is_instance_valid(game.hud):game.hud.refresh_save_status()

func status_text() -> String:
	return "M1 layout trial · preassembled leg; dock, inspect, Return.\nHip fastening is not playable in M1. Session only: no save/resume. Your normal saved workshop is untouched."

func save_now() -> bool:
	return false

func reload_save(_startup: bool = false) -> bool:
	return false

func new_workshop() -> void:
	game.get_tree().reload_current_scene()

func quit_game(_discard: bool = false) -> void:
	game.get_tree().quit()
