extends "res://tests/kit/harness.gd"
## Isolate 60 Hz RISE arrival and real model/runtime mounting from route geometry.
class Rail extends "res://scripts/indexed_leg_rail.gd":
	func _pose() -> void:pass
	func _refresh() -> void:pass
	func motion_error(_from: Dictionary, _to: Dictionary, _contact: bool = false) -> String:return ""
	func _travel_scale(_field: String) -> float:return 1.2
class Access extends WorkshopEquipment:
	var queries: Array = []
	func front_open(front: String) -> bool:queries.append(front);return front=="lower"
	func front_closed(front: String) -> bool:return not front_open(front)

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
	var rail=Rail.new();game.add_child(rail);rail.game=game;rail.spec=preload("res://scripts/leg_bay_layout.gd").layout().workshop.rail
	rail.foot_support=1.0;rail.travel_z=rail.spec.bay_z;rail.tilt_deg=90.0
	rail.index_x=rail.spec.lanes.left;rail.rise_m=rail.spec.dock_rise-.03
	expect(rail.action_error("rise+").is_empty(),"supported leg just below the top permits held RISE: "+rail.action_error("rise+"))
	expect(game.model.assemblies.left_leg.parent.is_empty(),"approaching the top installs nothing")
	var installs={"count":0}
	game.model.changed.connect(func():
		if game.model.assemblies.left_leg.parent=="pelvis":installs.count+=1)
	rail.set_jog("rise+")
	rail.physics(1.0/60.0)
	expect(game.model.assemblies.left_leg.parent.is_empty() and rail.rise_m<rail.spec.dock_rise,"first 60 Hz step does not install prematurely")
	var ticks=1
	while not rail.jog_settled() and ticks<120:rail.physics(1.0/60.0);ticks+=1
	expect(rail.jog_settled() and ticks==13,"60 Hz RISE covers the last 3 cm in 13 ticks at 0.144 m/s, got "+str(ticks)+": "+rail.blocked_reason)
	expect(rail.index_x==rail.spec.lanes.left and rail.rise_m==rail.spec.dock_rise and rail.tilt_deg==90.0,"RISE arrival reaches the exact docked joint pose")
	expect(game.model.assemblies.left_leg.parent=="pelvis","arrival transfers the supported leg into the pelvis")
	expect(game.runtime.node("left_leg").get_parent()==game.runtime.node("pelvis") and game.runtime.node("left_leg").position==Vector3(0,1,0),"arrival mounts the existing node at the receiver interface")
	for tick in range(8):rail.physics(1.0/60.0)
	expect(installs.count==1 and game.model.assemblies.pelvis.history.size()==1,"holding RISE at the top installs exactly once")
	rail.set_jog("")
	expect(not rail.moving and rail.jog.is_empty(),"release clears the held RISE input")
	expect(not access.queries.is_empty() and access.queries.all(func(front):return front=="lower"),"RISE queries only the explicitly open lower front")
	expect(game.model.integrity_errors().is_empty(),"arrival conserves physical identities")
	var passed=checks.all(func(c):return c.passed)
	print("RAIL_ENDPOINT ","PASS " if passed else "FAIL ",checks.size()," checks")
	game.free();quit(0 if passed else 1)
