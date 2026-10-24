extends "res://tests/kit/harness.gd"
## Production crane decisions with real authored stock; unrelated receiver replies are controlled.
class Crane extends "res://scripts/service_crane.gd":
	func _refresh() -> void:pass # visual projection only
class Gate extends WorkshopEquipment:
	var refusal="receiver unavailable"
	func receiving_error(_uid: String, _support: String = "") -> String:return refusal
	func source_error(_uid: String) -> String:return ""
func _initialize() -> void:call_deferred("run")
func actions(crane: Node) -> Array:return crane.menu_options().map(func(option):return option.action)
func run() -> void:
	var game=preload("res://tests/kit/model_workshop.gd").new();root.add_child(game)
	expect(game.setup().is_empty(),"authored stock configures")
	var gate=Gate.new();gate.equipment_id="module_supports";game.add_child(gate);game.equipment.register(gate)
	var crane=Crane.new();game.add_child(crane);crane.game=game
	crane.tasks=preload("res://scripts/leg_bay_layout.gd").layout().crane.tasks
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
	var passed=checks.all(func(c):return c.passed)
	print("CRANE_POLICY ","PASS " if passed else "FAIL ",checks.size()," checks")
	game.free();quit(0 if passed else 1)
