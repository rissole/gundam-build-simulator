extends "res://tests/kit/harness.gd"
## Exactly one fresh scene, no stage replay or equipment journey.
func _initialize() -> void:call_deferred("run")
func run() -> void:
	var game=instantiate_workshop(self)
	await frames(2)
	expect(game.started and game.paused,"fresh workshop initializes paused")
	expect(game.equipment.ids().size()==game.equipment.ids().reduce(func(ids,id):ids[id]=true;return ids,{}).size(),"registered equipment identities are unique")
	for id in game.EQUIPMENT:expect(game.equipment.get_equipment(id)!=null,"startup registers "+id)
	expect(game.model.assemblies.foot.location=="support:foot_store" and game.model.milestone("right_foot","complete"),"initial supports and supplied right foot are correct")
	expect(["pad_1","pad_2","pitch"].all(func(id):return game.model.assemblies[id].parent.is_empty()),"left foot children remain available to build")
	expect(game.hud.manual_id=="foot" and game.model.integrity_errors().is_empty(),"initial manual and ownership are valid")
	expect(preload("res://scripts/build_stages.gd").new(game).stage_errors("foot").is_empty(),"actual startup satisfies fresh stage boundary")
	game.set_paused(false)
	var key=InputEventKey.new();key.physical_keycode=KEY_ESCAPE;key.pressed=true
	game.handle_desktop_input(key)
	expect(game.paused,"production Escape input pauses the workshop")
	var passed=checks.all(func(c):return c.passed)
	print("WORKSHOP_SMOKE ","PASS " if passed else "FAIL ",checks.size()," checks")
	game.free();quit(0 if passed else 1)
