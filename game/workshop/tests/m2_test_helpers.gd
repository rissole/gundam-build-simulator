extends "res://tests/save_resume_test.gd"
## Ordinary walking, aiming and key input for the M2 leg-rail trials.
var trial: Node3D

func key(code: Key, pressed: bool = true) -> void:
	var event = InputEventKey.new();event.physical_keycode = code;event.pressed = pressed
	game.handle_desktop_input(event)

func look(point: Vector3) -> void:
	var direction = point-game.camera.global_position
	game.player.rotation = Vector3(0,atan2(-direction.x,-direction.z),0)
	game.camera.rotation = Vector3(atan2(direction.y,Vector2(direction.x,direction.z).length()),0,0)
	game._update_target()

func walk(point: Vector3, label: String) -> bool:
	var arrived = false
	for tick in range(1600):
		var offset = point-game.player.global_position;offset.y = 0
		if offset.length() < .09:arrived = true;break
		game.player.rotation.y = atan2(-offset.x,-offset.z);game.camera.rotation.x = 0
		key(KEY_W);await frames(1)
	key(KEY_W,false);await frames(10)
	if not arrived:print("M2_WALK ",label," feet=",game.player.global_position," destination=",point)
	expect(arrived and game.player.is_on_floor(),"Ordinary walking reaches "+label)
	return arrived

func button(action: String, bay: bool = false) -> Dictionary:
	return trial.controls()[(3 if bay else 0)+["advance","stop","return"].find(action)]

func settle() -> bool:
	for tick in range(1100):
		if not trial.moving:return trial.blocked_reason.is_empty()
		await frames(1)
	return false
