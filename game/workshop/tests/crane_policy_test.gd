extends "res://tests/kit/harness.gd"
## Production crane decisions with real authored stock; unrelated receiver replies are controlled.
class Hands extends RefCounted:
	func error(_id: String) -> String:return ""
class Workshop extends "res://tests/kit/model_workshop.gd":
	var hands: RefCounted
class Crane extends "res://scripts/service_crane.gd":
	func _refresh() -> void:pass # visual projection only
	func _interaction_error(_point: Vector3, _allowed: Array = []) -> String:return ""
class Gate extends WorkshopEquipment:
	var refusal="receiver unavailable"
	func receiving_error(_uid: String, _support: String = "") -> String:return refusal
	func source_error(_uid: String) -> String:return ""
func _initialize() -> void:call_deferred("run")
func actions(crane: Node) -> Array:return crane.menu_options().map(func(option):return option.action)
func retention(game: Node, crane: Node) -> void:
	# Reach is not this check. The refusal must open because retention changed.
	game.paused=false
	var spec: Dictionary=crane.tasks.shin
	crane.task="shin";crane.config={"spec":spec};crane.uid=spec.load_uid
	crane.load_owner=spec.owner;crane.slot=spec.slot;crane.secured_milestone=spec.secured.milestone
	crane.assembly_payload=false;crane.receiver_support="";crane.support=spec.support
	crane.fastener_slots=game.runtime.definition("left_leg").milestones.shin_secured.filter(func(sid):return sid!="shin")
	crane.END_IDS=spec.endpoint_ids.duplicate();crane.endpoints={};crane.end_nodes={}
	for id in crane.END_IDS:
		var end:=Node3D.new();crane.add_child(end);crane.end_nodes[id]=end
		crane.endpoints[id]={"state":"attached","point":""}
	crane.station="receiver";crane.raised=false;crane.motion="";crane.moving=false
	crane.blocked_reason="Waiting for the loose washer."
	var beam: Dictionary=game.model.items["LG-100__001"]
	beam.location="installed";beam.owner="left_leg";beam.slot="shin"
	game.model.assemblies.left_leg.slots.shin="LG-100__001"
	var seated: String=crane.status_text()
	expect(not seated.contains("Connection retention") and not seated.to_lower().contains("shin") and seated.contains("Magnetic connectors attached: 2/2") and seated.contains(crane.blocked_reason),"seated crane status keeps magnets and the obstruction without a retention count")
	crane.blocked_reason="";crane.station="park";crane.raised=true
	for id in crane.END_IDS:crane.endpoints[id]={"state":"stowed","point":""}
	var parked: String=crane.status_text()
	expect(parked=="Parking bay · Up","empty parked crane shows only its place and height: "+parked)
	crane.station="receiver";crane.raised=false
	for id in crane.END_IDS:crane.endpoints[id]={"state":"attached","point":""}
	var partial: String=crane.fastener_slots[0]
	game.model.assemblies.left_leg.slots[partial]="partial"
	var detach: String=crane.action_error("detach:"+crane.END_IDS[0])
	var lift: String=crane.action_error("up")
	expect(not crane.secured() and crane.hardware_count()==1,"one fitted fastener is still incomplete retention")
	expect(detach=="Finish retaining the structural shin in the manual (M) before detaching a magnetic connector.","early release names the connection and the manual")
	expect(lift=="Undo retaining hardware for the structural shin in the manual (M) before lifting the component.","early lift says what to undo")
	for sid in game.runtime.definition("left_leg").milestones.shin_secured:
		if str(game.model.assemblies.left_leg.slots[sid]).is_empty():game.model.assemblies.left_leg.slots[sid]="fitted"
	expect(crane.secured() and crane.action_error("detach:"+crane.END_IDS[0]).is_empty(),"finished retention allows the existing release")
	expect(crane.action_error("up")==lift,"fitted retention still refuses the lift")
	for sid in crane.fastener_slots:game.model.assemblies.left_leg.slots[sid]=""
	expect(crane.hardware_count()==0 and not crane.secured() and crane.action_error("up").is_empty(),"clearing the retaining hardware allows the existing lift")
	expect(not crane.status_text().contains("Connection retention"),"console and crane sign share status without a retention count")

func run() -> void:
	var game=Workshop.new();game.hands=Hands.new();root.add_child(game)
	expect(game.setup().is_empty(),"authored stock configures")
	var gate=Gate.new();gate.equipment_id="module_supports";game.add_child(gate);game.equipment.register(gate)
	var crane=Crane.new();game.add_child(crane);crane.game=game
	crane.tasks=preload("res://scripts/leg_bay_layout.gd").layout().crane.tasks
	expect(crane.tasks.values().all(func(spec):return not spec.has("access_mode") and not spec.has("restore_access")),"no crane task operates or restores gantry access")
	expect(crane.tasks.keys().filter(func(key):return crane.tasks[key].get("needs_front",[])==["lower"])==["left_arm","right_arm"],"only shoulder deliveries require the lower front")
	crane.task="pelvis";crane.uid="pelvis";crane.assembly_payload=true
	crane.config={"spec":crane.tasks.pelvis}
	crane.END_IDS=["a","b"]
	crane.endpoints={"a":{"state":"stowed","point":""},"b":{"state":"stowed","point":""}}
	expect(crane.next_route()=="pelvis" and actions(crane)==["pickup"],"empty crane offers first authored pickup only")
	var before=snapshot(game.model)
	expect(crane.next_hint()==gate.refusal and not crane.request("pickup").is_empty(),"blocked receiver explains next pickup and rejects command")
	expect(crane.next_route()=="pelvis" and before==snapshot(game.model),"blocked first load is not skipped and ownership stays unchanged")
	gate.refusal=""
	expect(crane.next_hint().is_empty(),"cleared receiver allows first pickup")
	expect(game.model.transfer_supported_assembly("pelvis","bulky_fixture","crane_rigging").is_empty(),"supply carried pelvis with real ownership transfer")
	expect(crane.next_route()=="foot","source departure advances authored order")
	crane.station="source"
	expect(actions(crane)==["down","go:receiver"],"carried load offers delivery rather than new pickup")
	crane.station="receiver"
	expect(actions(crane)==["down","go:source"],"delivered-position load can be put back")
	crane.motion="go:source";crane.moving=true;crane.progress=.4
	expect(actions(crane)==["stop"] and crane.request("stop").is_empty() and not crane.moving and crane.progress==.4,"Stop preserves interrupted transfer progress")
	expect(actions(crane)==["resume"] and crane.request("resume").is_empty() and crane.moving and crane.progress==.4,"Resume continues interrupted transfer")
	crane.motion="";crane.moving=false;crane.station="source";crane.raised=false
	crane.endpoints.a.state="attached"
	expect(not crane.request("up").is_empty() and not crane.moving,"partial rig rejects lifting")
	crane.reacquire="pelvis"
	expect(crane.next_route()=="pelvis" and crane._pickup_role("pelvis")=="receiver","undo reacquires exact load at receiver")
	game.paused=true
	expect(not crane.request("resume").is_empty(),"paused workshop rejects commands")
	retention(game,crane)
	var passed=checks.all(func(c):return c.passed)
	print("CRANE_POLICY ","PASS " if passed else "FAIL ",checks.size()," checks")
	game.free();quit(0 if passed else 1)
