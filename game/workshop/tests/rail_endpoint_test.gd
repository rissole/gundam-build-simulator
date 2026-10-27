extends "res://tests/kit/harness.gd"
## Isolate SEAT lead-in arithmetic and real model/runtime mounting from route geometry.
class Rail extends "res://scripts/indexed_leg_rail.gd":
	func _pose() -> void:pass
	func _refresh() -> void:pass
	func motion_error(_from: Dictionary, _to: Dictionary, _contact: bool = false) -> String:return ""
	func _travel_scale(_field: String) -> float:return 1.2
class Access extends WorkshopEquipment:
	var requested := "leg"
	func ready_for(_mode: String) -> bool:return true
	func request_mode(mode: String) -> String:requested=mode;return ""
class Gates extends WorkshopEquipment:
	var requested_closed := true
	var goal := 1.0
	func closed() -> bool:return true
	func occupancy_error() -> String:return ""
	func request_closed(value: bool) -> String:requested_closed=value;return ""

func _initialize() -> void:run.call_deferred()
func run() -> void:
	var game=preload("res://tests/kit/model_workshop.gd").new();root.add_child(game)
	var data={"version":1,"parts":{"base":{"family":"base","carry_class":"equipment"}},"assemblies":{
		"leg":{"root_slot":"base","work_locations":["support:leg_holder"],"slots":{"base":{"accepts":"base"}},"milestones":{"ready":["base"],"structural_ready":["base"]}},
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
	var rail=Rail.new();game.add_child(rail);rail.game=game;rail.spec=preload("res://scripts/leg_bay_layout.gd").layout().workshop.rail
	rail.bolster=1.0;rail.travel_z=rail.spec.bay_z;rail.tilt_deg=90.0;rail.rise_m=rail.spec.dock_rise-rail.SEAT_LEAD
	# Inside the axis tolerances, not on the exact pose: the lead-in blends it out.
	rail.index_x=rail.spec.lanes.left+.015
	expect(rail.seat_error(false).is_empty(),"aligned supported leg passes the SEAT support checks: "+rail.seat_error(false))
	expect(game.model.assemblies.left_leg.parent.is_empty(),"reaching jog tolerance alone installs nothing")
	rail.seating=true;rail._sync_moving()
	var ticks=0
	while rail.moving and ticks<120:rail.physics(1.0/60.0);ticks+=1
	expect(not rail.moving and not rail.seating and ticks>=29 and ticks<=31,"60 Hz SEAT guides the last 3 cm in about half a second, got "+str(ticks)+" ticks")
	expect(rail.index_x==rail.spec.lanes.left and rail.rise_m==rail.spec.dock_rise and rail.tilt_deg==90.0,"lead-in arrival reaches the exact docked joint pose")
	expect(game.model.assemblies.left_leg.parent=="pelvis","arrival transfers the supported leg into the pelvis")
	expect(game.runtime.node("left_leg").get_parent()==game.runtime.node("pelvis") and game.runtime.node("left_leg").position==Vector3(0,1,0),"arrival mounts the existing node at the receiver interface")
	expect(access.requested=="work" and not gates.requested_closed,"arrival restores decks and reopens ground gates")
	expect(game.model.integrity_errors().is_empty(),"arrival conserves physical identities")
	var passed=checks.all(func(c):return c.passed)
	print("RAIL_ENDPOINT ","PASS " if passed else "FAIL ",checks.size()," checks")
	game.free();quit(0 if passed else 1)
