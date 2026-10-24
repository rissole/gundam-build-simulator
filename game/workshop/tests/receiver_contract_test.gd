extends "res://tests/kit/harness.gd"
## One supported assembly/receiver pair; real model, mount projection and retention gates.
func _initialize() -> void:call_deferred("run")
func run() -> void:
	var game=preload("res://tests/kit/model_workshop.gd").new();root.add_child(game)
	var data={"version":1,"parts":{"base":{"family":"base","carry_class":"equipment"},"bolt":{"family":"bolt","carry_class":"pocket"}},"assemblies":{
		"payload":{"root_slot":"base","carry_class":"equipment","work_locations":["support"],"slots":{"base":{"accepts":"base"}},"milestones":{"ready":["base"]}},
		"frame":{"work_locations":["fixture"],"slots":{"seat":{"assembly":"payload","milestone":"ready","support_required":true,"source_supports":["rig"],"snap_position":[0,1,0]},"bolt":{"accepts":"bolt","requires":["seat"]},"cover":{"accepts":"bolt","requires":["bolt"]}},"milestones":{"retained":["seat","bolt"]}}}}
	var scenario={"version":1,"parts":[{"instance_id":"base","kind":"base"},{"instance_id":"bolt","kind":"bolt"},{"instance_id":"cover","kind":"bolt"}],"supports":{"rack":{"assemblies":["payload"]},"rig":{"assemblies":["payload"]}},"builds":[{"id":"payload","definition":"payload","base":"base","location":"support:rack"}],"parents":[{"id":"frame","definition":"frame"}]}
	expect(game.model.configure(data,scenario).is_empty(),"minimal supported receiver configures")
	game.runtime=AssemblyRuntime.new(game.model,{})
	for id in ["frame","payload"]:
		var body=Node3D.new();game.add_child(body);game.runtime.register_node(id,body)
	game.zones=preload("res://scripts/zone_register.gd").new(["prior_rig"])
	var crane=preload("res://scripts/service_crane.gd").new();game.add_child(crane);crane.equipment_id="service_crane";crane.game=game;crane.task="payload";crane.support="rig"
	crane.END_IDS=["a","b"];crane.endpoints={"a":{"state":"attached","point":"a"},"b":{"state":"attached","point":"b"}}
	crane.station="receiver";crane.raised=false;game.equipment.register(crane)
	var receiver=preload("res://scripts/staged_receiver.gd").new();game.add_child(receiver)
	receiver.setup(game,"receiver",{"owner":"frame","uid":"payload","slot":"seat","crane_task":"payload","retention_slots":["bolt"],"closure_slots":["cover"],"clear_zones":["prior_rig"],"seat":{"position":[0,1,0]}})
	game.zones.claim("prior_rig","previous")
	var initial=snapshot(game.model)
	expect(not receiver.accept().is_empty() and initial==snapshot(game.model),"occupied rig zone rejects seating atomically")
	game.zones.release("prior_rig","previous")
	expect(not receiver.accept().is_empty(),"rack ownership cannot masquerade as crane support")
	expect(game.model.transfer_supported_assembly("payload","rack","rig").is_empty() and receiver.accept().is_empty(),"supported payload seats through production receiver")
	expect(game.runtime.node("payload").get_parent()==game.runtime.node("frame") and game.runtime.node("payload").position==Vector3(0,1,0),"receiver projects actual mounting transform")
	expect(receiver.state=="seated" and not receiver.rig_error("detach","").is_empty(),"seating alone cannot release rigging")
	expect(receiver.placement_error("frame","bolt").is_empty(),"full rig permits retention")
	crane.endpoints.b.state="stowed"
	expect(not receiver.placement_error("frame","bolt").is_empty() and not receiver.departure_error().is_empty(),"partial rig cannot fasten or depart unsupported")
	crane.endpoints.b.state="attached"
	game.model.stock_pocket("bolt")
	expect(game.model.install("frame","bolt","bolt").ok and receiver.retained(),"real fastener establishes retention")
	expect(receiver.rig_error("detach","").is_empty() and not receiver.placement_error("frame","cover").is_empty(),"retention permits release but closures wait for crane detachment")
	for end in crane.endpoints.values():end.state="stowed"
	expect(receiver.state=="released" and receiver.departure_error().is_empty() and receiver.placement_error("frame","cover").is_empty(),"retained detached load permits departure and closure")
	expect(game.model.install("frame","cover","cover").ok and not receiver.rig_error("attach","").is_empty(),"fitted closure blocks re-rigging")
	expect(game.model.integrity_errors().is_empty(),"receiver lifecycle conserves physical identities")
	var passed=checks.all(func(c):return c.passed)
	print("RECEIVER_CONTRACT ","PASS " if passed else "FAIL ",checks.size()," checks")
	game.free();quit(0 if passed else 1)
