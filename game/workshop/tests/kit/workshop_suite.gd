extends "res://tests/kit/harness.gd"
## Model fixtures shared by world suites, independent of save-regression bodies.
const Store = preload("res://scripts/save_store.gd")
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

func valid(snapshot: Dictionary, label: String) -> void:
	var errors: Array[String] = game.saves.validate(snapshot)
	if not errors.is_empty():print("SAVE_VALIDATION_DIAGNOSTIC ",errors)
	expect(errors.is_empty(),label)

func diagnose_json(value: Variant, path: String = "snapshot") -> void:
	if value is Dictionary:
		for key in value:
			if not key is String:print("INVALID_JSON_KEY ", path, " ", key, " ", typeof(key))
			diagnose_json(value[key], path + "/" + str(key))
	elif value is Array:
		for index in range(value.size()):diagnose_json(value[index], path + "/" + str(index))
	elif typeof(value) not in [TYPE_NIL, TYPE_BOOL, TYPE_INT, TYPE_STRING, TYPE_FLOAT]:print("INVALID_JSON_VALUE ", path, " ", typeof(value), " ", value)
