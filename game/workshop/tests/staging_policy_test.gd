extends "res://tests/kit/harness.gd"
const Fixture=preload("res://tests/kit/model_workshop.gd")
func _initialize() -> void:call_deferred("run")
func run() -> void:
	var game=Fixture.new();root.add_child(game)
	expect(game.setup().is_empty(),"production content configures without a scene")
	var before=snapshot(game.model)
	Staging.prepare(game)
	expect(game.model.milestone("right_foot","complete"),"production staging prepares right foot")
	for owner in ["pad_1","pad_2","pitch","foot"]:
		var definition: Dictionary=game.runtime.definition(owner)
		var preserved=true
		for spec in definition.slots.values():
			var uid: String=spec.get("pose_source","")
			if before.items.has(uid) and before.items[uid].owner.is_empty():preserved=preserved and game.model.items[uid]==before.items[uid]
		expect(preserved,"supplied right branch preserves intended stock for "+owner)
	var policy=preload("res://scripts/leg_journey_policy.gd").new(game)
	var candidates: Array[Dictionary]=[{"type":"carry"},{"type":"station"},{"type":"mount"},{"type":"bin","kind":"nonexistent"}]
	expect(policy.filter_candidates(candidates)==candidates.slice(0,3),"filter retains carry/station/mount and removes empty stock")
	var carrier=preload("res://scripts/foot_carrier.gd").new();game.add_child(carrier);carrier.game=game
	for owner in ["foot","pad_1","pad_2","pitch"]:
		expect(not carrier.undo(owner).handled and policy.undo_error(owner).is_empty(),"fixture permits local correction of "+owner)
	for owner in policy.RIGHT_FOOT:expect(not policy.undo_error(owner).is_empty(),"supplied branch rejects undo: "+owner)
	expect(game.model.transfer_supported_assembly("foot","foot_store","crane_rigging").is_empty(),"supply departure from foot fixture through model")
	for owner in ["foot","pad_1","pad_2","pitch"]:expect(not carrier.undo(owner).error.is_empty(),"departed foot cannot undo internal work: "+owner)
	expect(game.model.integrity_errors().is_empty(),"staging and transfer conserve ownership")
	var fresh=preload("res://scripts/workshop_content.gd").load_workshop()
	expect(fresh.scenario==game.loaded.scenario,"content loader returns fresh unchanged source data")
	game.loaded.data.assemblies.clear()
	expect(not fresh.data.assemblies.is_empty(),"loader results do not share mutable definitions")
	var passed=checks.all(func(c):return c.passed)
	print("STAGING_POLICY ","PASS " if passed else "FAIL ",checks.size()," checks")
	game.free();quit(0 if passed else 1)
