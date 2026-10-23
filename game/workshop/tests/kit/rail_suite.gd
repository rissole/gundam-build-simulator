extends "res://tests/kit/workshop_suite.gd"
## Ordinary walking, aiming and key input for the M2 leg-rail trials.
var trial: Node3D

func button(action: String, bay: bool = false) -> Dictionary:
	return trial.controls()[(3 if bay else 0)+["advance","stop","return"].find(action)]

func settle() -> bool:
	for tick in range(1100):
		if not trial.moving:return trial.blocked_reason.is_empty()
		await frames(1)
	return false

func key(code: Key, pressed: bool = true) -> void:
	PlayerDriver.new(game).key(code,pressed)

func look(point: Vector3) -> void:
	PlayerDriver.new(game).look(point)

func walk(point: Vector3, label: String) -> bool:
	var arrived: bool = await PlayerDriver.new(game).walk(point)
	expect(arrived,"Ordinary walking reaches "+label)
	return arrived
