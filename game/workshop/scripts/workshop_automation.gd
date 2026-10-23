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
	game.suspend_build(build_id,station_id)
	return ""

func fill(owner: String, limit: int = -1, permitted: Array = []) -> int:
	return Staging.fill(game,owner,permitted,limit)

func sync_visuals(owner: String) -> void:
	game.components.sync(owner)
	game.refresh_assembly_collision(owner)

## Reader focus only. World interaction always names its owner explicitly.
func select_build(build_id: String) -> void:
	assert(game.builds.has(build_id),"Unknown build: "+build_id)
	game.active_build = build_id

func body(owner: String) -> Node3D:
	return game.assembly_node(owner)

func slot_point(owner: String, sid: String) -> Vector3:
	return game.components.slot_point(owner,sid)

func root_uid(owner: String) -> String:
	return game.model.assemblies[owner].slots[game.runtime.definition(owner).root_slot]

func prepared(owner: String) -> bool:
	return game.build_prepared(owner)

func complete(owner: String) -> bool:
	return game.build_complete(owner)

func mount_build(owner: String, parent: String, sid: String) -> Dictionary:
	var result: Dictionary = game.model.install(parent,sid,owner)
	if result.ok:game.mount_build(owner)
	return result

func refresh_presentation() -> void:
	game.targeting.update_ghost()

func refresh_markers() -> void:
	game.targeting.update_markers()

func show_assembly_ghost(owner: String) -> void:
	game.targeting.show_assembly_ghost(owner)
