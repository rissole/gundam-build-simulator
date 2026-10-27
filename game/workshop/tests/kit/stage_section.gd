extends "res://tests/kit/harness.gd"
## Independent section fixture. Earlier work is supplied by the shared sequence;
## assertions belong to the section that exercises them.
const Stages=preload("res://scripts/build_stages.gd")
var game: Node
var rail: Node
var carrier: Node
var stages: RefCounted

func _initialize() -> void:call_deferred("run")

func start(stage: String) -> bool:
	game=await boot_workshop();rail=game.equipment.get_equipment("leg_rail");carrier=game.equipment.get_equipment("foot_carrier")
	stages=Stages.new(game)
	var error: String=await stages.run_to(stage)
	expect(error.is_empty(),"shared sequence reaches "+stage+": "+error)
	return error.is_empty()

func settle(controller: Node, limit: int = 1600) -> bool:return stages.settle(controller,limit).is_empty()

func command(controller: Node, action: String) -> bool:
	var error: String=stages.command(controller,action)
	expect(error.is_empty(),controller.equipment_id+" accepts and completes "+action+": "+error)
	return error.is_empty()

func supply_rig(crane: Node, attached: bool) -> void:stages.supply_rig(crane,attached)

## Holds one leg rig arrow as Hold E does until it reaches its next stop.
func jog(controller: Node, action: String) -> bool:
	var error: String=stages.jog(controller,action)
	expect(error.is_empty(),controller.equipment_id+" holds "+action+" to its stop: "+error)
	return error.is_empty()

func index_to(x: float) -> bool:
	var error: String=stages.index_to(rail,x)
	expect(error.is_empty(),"leg rig indexes to X"+str(x)+": "+error)
	return error.is_empty()
