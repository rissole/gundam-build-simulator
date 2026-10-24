extends "res://tests/kit/harness.gd"
## Model fixtures shared by world suites, independent of save-regression bodies.
var game: Node

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	push_error("Workshop suite must implement run().")
	quit(1)

func station(owner: String, id: String) -> void:
	expect(game.automation.suspend_at_station(owner,id).is_empty(),"Suspend "+owner)

func stage(owner: String, limit: int) -> int:
	var before: Dictionary = game.model.assemblies[owner].slots.duplicate()
	var count: int = Staging.fill(game,owner,[],limit)
	var actual = 0
	for sid in before:
		if before[sid].is_empty() and not game.model.assemblies[owner].slots[sid].is_empty():
			var uid: String = game.model.assemblies[owner].slots[sid]
			expect(game.model.items.has(uid) and game.model.items[uid].owner == owner and game.model.items[uid].slot == sid,"Stage exact physical occupant "+owner+"/"+sid)
			actual += 1
	if actual != count:expect(false,"Staging count matches newly owned identities for "+owner)
	return count

func available_hand() -> String:
	for uid in game.model.items:
		var item: Dictionary = game.model.items[uid]
		if item.location == "bin" and game.model.definitions.parts[item.kind].carry_class != "pocket":return uid
	return ""
