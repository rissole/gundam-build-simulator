extends SceneTree
const SaveModel = preload("res://scripts/save_model.gd")
var checks: Array[Dictionary] = []

func expect(value: bool, label: String) -> void:
	checks.append({"check":label, "passed":value})
	if not value:push_error(label)

func baseline() -> AssemblyModel:
	var model = AssemblyModel.new()
	expect(model.configure(HeelAssemblyState.definition_data(), HeelAssemblyState.scenario()).is_empty(), "Configure pad workshop")
	return model

func rejected(snapshot: Variant, original: AssemblyModel, label: String) -> void:
	var before = SaveModel.capture(original)
	expect(not SaveModel.validate(snapshot, original).is_empty(), label)
	expect(SaveModel.capture(original) == before, label + " leaves baseline unchanged")

func _initialize() -> void:
	var fresh = baseline()
	var model = baseline()
	model.move_assembly("pad_1", "station:one")
	model.move_assembly("pad_2", "station:two")
	model.stock_pocket("sleeve")
	model.stock_pocket("washer")
	for id in ["pad_2", "pad_1"]:
		for index in [3, 1]:expect(model.install(id, "sleeve_%d" % index, model.find_item("sleeve", "pocket")).ok, "Interleaved partial preparation")
	model.select_pocket(7)
	var partial = SaveModel.capture(model)
	expect(SaveModel.validate(partial, fresh).is_empty(), "Multiple unfinished builds and pocket stock validate")
	var restored = baseline()
	SaveModel.apply(JSON.parse_string(JSON.stringify(partial)), restored)
	expect(SaveModel.capture(restored) == partial and restored.integrity_errors().is_empty(), "JSON round trip restores unfinished builds and integer pocket fields")
	# Snapshot and application own their dictionaries and preserve the model object.
	var frozen = SaveModel.capture(restored)
	partial.assemblies.pad_1.history.clear()
	expect(SaveModel.capture(restored) == frozen, "Applying makes independent deep copies")
	var captured = SaveModel.capture(restored)
	captured.items[captured.items.keys()[0]].source_id = "changed"
	expect(SaveModel.capture(restored) == frozen, "Capturing makes independent deep copies")
	for id in ["pad_2", "pad_1"]:
		for index in [0, 2]:expect(restored.install(id, "sleeve_%d" % index, restored.find_item("sleeve", "pocket")).ok, "Continue restored partial build")
	# Opposite mount positions and independent order must not be overconstrained.
	restored.move_assembly("pad_2", "held")
	expect(restored.install("foot", "heel_1", "pad_2").ok, "Mount compatible opposite physical copy")
	restored.move_assembly("pad_1", "held")
	expect(restored.install("foot", "heel_2", "pad_1").ok, "Mount sibling independently")
	restored.stock_pocket("bolt")
	expect(restored.install("foot", "heel_2/washer_0", restored.find_item("washer", "pocket")).ok, "Install parent washer")
	expect(restored.install("foot", "heel_2/bolt_0", restored.find_item("bolt", "pocket")).ok, "Install parent bolt")
	var mounted = SaveModel.capture(restored)
	expect(SaveModel.validate(JSON.parse_string(JSON.stringify(mounted)), fresh).is_empty(), "Mounted siblings and full undo histories validate")
	var resumed = baseline()
	SaveModel.apply(mounted, resumed)
	expect(resumed.undo("foot").ok and resumed.undo("foot").ok, "Resume exact hardware undo after applying")
	expect(resumed.undo("foot", "station:one").ok and resumed.assemblies.pad_1.location == "station:one", "Resume mount undo with nested built state")
	expect(resumed.undo("pad_1").ok and resumed.integrity_errors().is_empty(), "Continue child construction undo after detaching")
	expect(SaveModel.validate(SaveModel.capture(resumed), fresh).is_empty(), "Resumed undo yields another valid save")
	var corrupted: Dictionary
	for malformed in [null, [], "text", {}, {"items":{}}, {"items":[], "assemblies":{}, "pockets":[], "selected_pocket":0}]:rejected(malformed, fresh, "Reject malformed root/container")
	for field in ["items", "assemblies", "pockets", "selected_pocket"]:
		corrupted = mounted.duplicate(true)
		corrupted.erase(field)
		rejected(corrupted, fresh, "Reject truncated " + field)
	for field in SaveModel.ITEM_FIELDS:
		corrupted = mounted.duplicate(true)
		corrupted.items[corrupted.items.keys()[0]].erase(field)
		rejected(corrupted, fresh, "Reject truncated item " + field)
	for field in SaveModel.ASSEMBLY_FIELDS:
		corrupted = mounted.duplicate(true)
		corrupted.assemblies.pad_1.erase(field)
		rejected(corrupted, fresh, "Reject truncated assembly " + field)
	for invalid in [null, [], {}, 2.5]:
		corrupted = mounted.duplicate(true)
		corrupted.assemblies.pad_1.history = invalid
		rejected(corrupted, fresh, "Reject malformed history container")
	for field in SaveModel.STEP_FIELDS:
		corrupted = mounted.duplicate(true)
		corrupted.assemblies.pad_1.history[0][field] = 3
		rejected(corrupted, fresh, "Reject malformed history " + field)
	for invalid in [-1, 10, 0.5, "0", null]:
		corrupted = mounted.duplicate(true)
		corrupted.selected_pocket = invalid
		rejected(corrupted, fresh, "Reject invalid selected pocket")
	corrupted = mounted.duplicate(true)
	corrupted.items.extra = corrupted.items[corrupted.items.keys()[0]].duplicate(true)
	rejected(corrupted, fresh, "Reject extra physical identity")
	corrupted = mounted.duplicate(true)
	corrupted.items[corrupted.items.keys()[0]].source_id = "wrong"
	rejected(corrupted, fresh, "Reject changed source identity")
	corrupted = mounted.duplicate(true)
	corrupted.assemblies.pad_1.definition = "foot"
	rejected(corrupted, fresh, "Reject changed assembly definition")
	corrupted = mounted.duplicate(true)
	corrupted.assemblies.pad_1.slots.base = corrupted.assemblies.pad_2.slots.base
	rejected(corrupted, fresh, "Reject changed root occupant")
	corrupted = mounted.duplicate(true)
	corrupted.assemblies.foot.location = "held"
	rejected(corrupted, fresh, "Reject moving fixture")
	corrupted = mounted.duplicate(true)
	corrupted.assemblies.pad_1.location = "station:"
	rejected(corrupted, fresh, "Reject empty station identity")
	corrupted = mounted.duplicate(true)
	corrupted.assemblies.pad_1.history.pop_back()
	rejected(corrupted, fresh, "Reject missing undo action")
	corrupted = mounted.duplicate(true)
	var missing_sleeve: String = corrupted.assemblies.pad_1.slots.sleeve_2
	corrupted.assemblies.pad_1.slots.sleeve_2 = ""
	corrupted.assemblies.pad_1.history.pop_back()
	corrupted.items[missing_sleeve].location = "bin"
	corrupted.items[missing_sleeve].owner = ""
	corrupted.items[missing_sleeve].slot = ""
	rejected(corrupted, fresh, "Reject mounted child missing its required milestone")
	corrupted = mounted.duplicate(true)
	corrupted.assemblies.pad_1.history.append(corrupted.assemblies.pad_1.history[0].duplicate())
	rejected(corrupted, fresh, "Reject duplicate undo action")
	corrupted = mounted.duplicate(true)
	corrupted.assemblies.pad_1.history.append({"action":"install", "assembly":"pad_1", "slot":"base", "uid":corrupted.assemblies.pad_1.slots.base})
	rejected(corrupted, fresh, "Reject undoing permanent root")
	corrupted = mounted.duplicate(true)
	corrupted.assemblies.foot.history.reverse()
	rejected(corrupted, fresh, "Reject undo history violating prerequisites")
	corrupted = mounted.duplicate(true)
	corrupted.assemblies.pad_1.parent = "pad_1"
	rejected(corrupted, fresh, "Reject cyclic child ownership")
	corrupted = mounted.duplicate(true)
	corrupted.pockets[0] = "unknown"
	rejected(corrupted, fresh, "Reject unknown pocket kind before model integrity")
	var in_pocket = restored.find_item("washer", "pocket")
	corrupted = mounted.duplicate(true)
	corrupted.items[in_pocket].pocket = 200
	rejected(corrupted, fresh, "Reject out of bounds pocket before model integrity")
	corrupted = mounted.duplicate(true)
	corrupted.items[in_pocket].pocket = 0.5
	rejected(corrupted, fresh, "Reject fractional pocket number")
	corrupted = mounted.duplicate(true)
	corrupted.items[in_pocket].location = "teleported"
	rejected(corrupted, fresh, "Reject unknown physical location")
	corrupted = mounted.duplicate(true)
	corrupted.assemblies.pad_1.slots.sleeve_0 = "unknown"
	rejected(corrupted, fresh, "Reject unknown slot identity")
	# Global hand/station capacity and orphan ownership need explicit coverage.
	corrupted = frozen.duplicate(true)
	corrupted.assemblies.pad_1.location = "held"
	corrupted.assemblies.pad_2.location = "held"
	rejected(corrupted, fresh, "Reject two held builds")
	corrupted = frozen.duplicate(true)
	corrupted.assemblies.pad_2.location = corrupted.assemblies.pad_1.location
	rejected(corrupted, fresh, "Reject duplicate station occupancy")
	corrupted = frozen.duplicate(true)
	corrupted.items[in_pocket].owner = "pad_1"
	rejected(corrupted, fresh, "Reject stale ownership of uninstalled piece")
	expect(SaveModel.capture(restored) == mounted, "All rejected snapshots leave the live model unchanged")
	_test_variants_and_nested()
	var passed = checks.all(func(check):return check.passed)
	print("SAVE_MODEL_AUDIT ", "PASS" if passed else "FAIL", " ", checks.size(), " checks")
	quit(0 if passed else 1)

func _test_variants_and_nested() -> void:
	var definitions = {"version":1, "parts":{
		"base":{"family":"base", "carry_class":"hand"},
		"ring":{"family":"hardware", "carry_class":"pocket"},
		"long_ring":{"family":"hardware", "carry_class":"pocket"}}, "assemblies":{
		"child":{"root_slot":"base", "slots":{"base":{"accepts":"base"}, "ring":{"accepts":"ring", "requires":["base"]}}, "milestones":{"ready":["base", "ring"]}, "work_locations":["station"]},
		"frame":{"root_slot":"base", "access_policy":"mounted", "slots":{"base":{"accepts":"base"}, "left":{"assembly":"child", "milestone":"ready", "requires":["base"]}, "right":{"assembly":"child", "milestone":"ready", "requires":["base"]}, "ring":{"accepts":"ring", "requires":["left"]}}, "milestones":{"ready":["base", "left", "right"]}, "work_locations":["station", "fixture"]},
		"rack":{"slots":{"frame":{"assembly":"frame", "milestone":"ready"}}, "milestones":{"ready":["frame"]}, "work_locations":["fixture"]}}}
	var scenario = {"version":1, "parts":[{"instance_id":"a", "kind":"base"}, {"instance_id":"b", "kind":"base"}, {"instance_id":"f", "kind":"base"}, {"instance_id":"r1", "kind":"ring"}, {"instance_id":"r2", "kind":"ring"}, {"instance_id":"r3", "kind":"ring"}, {"instance_id":"wrong", "kind":"long_ring"}], "builds":[{"id":"left", "definition":"child", "base":"a"}, {"id":"right", "definition":"child", "base":"b"}, {"id":"frame", "definition":"frame", "base":"f"}], "parent":{"id":"rack", "definition":"rack"}}
	var original = AssemblyModel.new()
	var live = AssemblyModel.new()
	expect(original.configure(definitions, scenario).is_empty() and live.configure(definitions, scenario).is_empty(), "Configure alternate nested recipe and incompatible variant")
	live.stock_pocket("ring")
	live.stock_pocket("long_ring")
	for id in ["left", "right"]:
		live.move_assembly(id, "station:" + id)
		expect(live.install(id, "ring", "r2" if id == "left" else "r1").ok, "Use interchangeable physical copy")
	live.move_assembly("frame", "station:frame")
	for id in ["right", "left"]:
		live.move_assembly(id, "held")
		expect(live.install("frame", id, id).ok, "Nested siblings mount in independent order")
	live.move_assembly("frame", "held")
	expect(live.install("rack", "frame", "frame").ok, "Mount nested frame")
	expect(live.install("frame", "ring", "r3").ok, "Authored internals may change after mounting")
	var saved = SaveModel.capture(live)
	expect(SaveModel.validate(saved, original).is_empty(), "Nested histories accept mounted internal changes and independent sibling order")
	var invalid = saved.duplicate(true)
	invalid.items.r3.kind = "long_ring"
	rejected(invalid, original, "Reject incompatible variant substitution")
	invalid = saved.duplicate(true)
	invalid.assemblies.frame.slots.ring = "wrong"
	invalid.assemblies.frame.history.back().uid = "wrong"
	invalid.items.r3.location = "pocket"
	invalid.items.r3.owner = ""
	invalid.items.r3.slot = ""
	invalid.items.r3.pocket = 0
	invalid.items.wrong.location = "installed"
	invalid.items.wrong.owner = "frame"
	invalid.items.wrong.slot = "ring"
	invalid.items.wrong.pocket = -1
	invalid.pockets[1] = ""
	rejected(invalid, original, "Reject wrong variant physical occupant despite matching history")
	invalid = saved.duplicate(true)
	invalid.assemblies.left.history.clear()
	rejected(invalid, original, "Reject lost child construction history within mounted frame")
	SaveModel.apply(saved, original)
	expect(original.undo("rack", "station:frame").ok and original.undo("frame").ok and original.undo("frame", "station:left").ok and original.undo("left").ok, "Nested mount and internal histories remain executable after loading")
