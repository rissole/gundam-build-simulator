extends "res://tests/kit/harness.gd"
## Integration of the new spatial/access foundation into the robot workshop.
## This is deliberately not a played journey or complete milestone acceptance.
func _initialize() -> void:call_deferred("run")

func run() -> void:
	var game = await boot_workshop("pelvis")
	expect(is_instance_valid(game.leg_layout.blockout),"workshop uses authored hangar world")
	for id in ["left_lift","right_lift","left_shelf","right_shelf","workshop_access"]:
		expect(game.equipment.get_equipment(id)!=null,"workshop registers "+id)
	expect(game.model.support_definitions.has("left_shelf_0") and game.model.support_definitions.has("right_shelf_0"),"both physical shelf support sets declared")
	var access = game.equipment.get_equipment("workshop_access")
	var error: String = access.request_mode("leg")
	expect(error.is_empty(),"actual scene can request rail access configuration: "+error)
	access.physics(2);access.request("stop")
	expect(not access.moving,"stopped access configuration holds its phase")
	var passed = checks.all(func(check):return check.passed)
	write_evidence("res://verification/wide-foundation.json",{"scope":"partial implementation integration; no journey acceptance","checks":checks})
	print("WIDE_FOUNDATION ","PASS " if passed else "FAIL ",checks.size()," checks")
	game.free();quit(0 if passed else 1)
