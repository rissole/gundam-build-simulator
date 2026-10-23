class_name WorkshopAutomation
extends RefCounted
## Public seam for tests and declared staging. Everything routes through the
## ordinary workshop paths; staging teleports are explicit and named as such.
const Staging = preload("res://scripts/scenario_staging.gd")
var game: Node

func _init(workshop: Node) -> void:
	game = workshop

func refresh_target() -> Dictionary:
	game._update_target()
	return game.target

func access_error() -> String:
	return game._access(game._target_receivers())

func send(event: InputEvent) -> void:
	game.handle_desktop_input(event)

func key(code: Key, pressed: bool = true) -> void:
	var event = InputEventKey.new();event.physical_keycode = code;event.pressed = pressed
	send(event)

func click(button: MouseButton = MOUSE_BUTTON_LEFT) -> void:
	var event = InputEventMouseButton.new();event.button_index = button;event.pressed = true
	send(event)

func place_player(position: Vector3, yaw: float = NAN) -> void:
	game.player.global_position = position
	game.player.velocity = Vector3.ZERO
	if not is_nan(yaw):game.player.rotation.y = yaw

func look_at_point(point: Vector3) -> void:
	var direction = point-game.camera.global_position
	game.player.rotation = Vector3(0,atan2(-direction.x,-direction.z),0)
	game.camera.rotation = Vector3(atan2(direction.y,Vector2(direction.x,direction.z).length()),0,0)

func suspend_at_station(build_id: String, station_id: String) -> String:
	var error: String = game.model.move_assembly(build_id,"station:"+station_id)
	if not error.is_empty():return error
	game._activate(build_id)
	game._set_pad_station(station_id)
	return ""

func fill(owner: String, limit: int = -1, permitted: Array = []) -> int:
	return Staging.fill(game,owner,permitted,limit)

func sync_visuals(owner: String) -> void:
	if game.builds.has(owner):
		var previous: String = game.active_build
		game._activate(owner)
		game._sync_installed_visuals()
		game._activate(previous)
	else:
		game.components.sync(owner)
		game.refresh_assembly_collision(owner)

func select_build(build_id: String) -> void:
	game._activate(build_id)
