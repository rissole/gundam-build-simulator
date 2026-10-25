extends "res://tests/kit/harness.gd"
## Isolate arrival arithmetic and real model/runtime mounting from route geometry.
class Rail extends "res://scripts/indexed_leg_rail.gd":
	func _pose() -> void:pass
	func _refresh() -> void:pass
	func motion_error(_from: Dictionary, _to: Dictionary) -> String:return ""
	func _travel_scale() -> float:return 1.2
class Access extends WorkshopEquipment:
	var requested := "leg"
	func ready_for(_mode: String) -> bool:return true
	func request_mode(mode: String) -> String:requested=mode;return ""
class Gates extends WorkshopEquipment:
	var requested_closed := true
	func closed() -> bool:return true
	func occupancy_error() -> String:return ""
	func request_closed(value: bool) -> String:requested_closed=value;return ""

func _initialize() -> void:run.call_deferred()
func run() -> void:
	var game=preload("res://tests/kit/model_workshop.gd").new();root.add_child(game)
	var data={"version":1,"parts":{"base":{"family":"base","carry_class":"equipment"}},"assemblies":{
		"leg":{"root_slot":"base","work_locations":["support:leg_holder"],"slots":{"base":{"accepts":"base"}},"milestones":{"ready":["base"]}},
		"pelvis":{"work_locations":["fixture"],"slots":{"left_leg":{"assembly":"leg","milestone":"ready","support_required":true,"source_supports":["leg_holder"],"snap_position":[0,1,0]}}}}}
	var scenario={"version":1,"parts":[{"instance_id":"base","kind":"base"}],"supports":{"leg_holder":{"assemblies":["leg"]}},"builds":[{"id":"left_leg","definition":"leg","base":"base","location":"support:leg_holder"}],"parents":[{"id":"pelvis","definition":"pelvis"}]}
	var errors: Array=game.model.configure(data,scenario)
	expect(errors.is_empty(),"isolated supported leg configures: "+str(errors))
	if not errors.is_empty():game.free();quit(1);return
	game.runtime=AssemblyRuntime.new(game.model,{})
	for id in ["left_leg","pelvis"]:
		var body=Node3D.new();game.add_child(body);game.runtime.register_node(id,body)
	var access=Access.new();access.equipment_id="workshop_access";game.add_child(access);game.equipment.register(access)
	var gates=Gates.new();gates.equipment_id="rail_gates";game.add_child(gates);game.equipment.register(gates)
	var rail=Rail.new();game.add_child(rail);rail.game=game
	rail.path=2;rail.goal=3;rail.mode="path";rail.moving=true
	for tick in range(510):rail.physics(1.0/60.0)
	expect(rail.path==3 and not rail.moving and rail.mode.is_empty(),"60 Hz docking reaches the exact indexed stop")
	expect(game.model.assemblies.left_leg.parent=="pelvis","arrival transfers the supported leg into the pelvis")
	expect(game.runtime.node("left_leg").get_parent()==game.runtime.node("pelvis") and game.runtime.node("left_leg").position==Vector3(0,1,0),"arrival mounts the existing node at the receiver interface")
	expect(access.requested=="work" and not gates.requested_closed,"arrival restores decks and reopens ground gates")
	expect(game.model.integrity_errors().is_empty(),"arrival conserves physical identities")
	var passed=checks.all(func(c):return c.passed)
	print("RAIL_ENDPOINT ","PASS " if passed else "FAIL ",checks.size()," checks")
	game.free();quit(0 if passed else 1)
