# 01 — AssemblyModel capture/restore

Read [README.md](README.md) "Rules for every task" first.

**Files you may touch:**
- `game/workshop/scripts/assembly_model.gd`
- `game/workshop/tests/assembly_model_test.gd`

## Goal

Give `AssemblyModel` a JSON-safe `capture()` and an atomic `restore(data)`:
- `restore` checks that the snapshot has exactly today's item and assembly identities,
  item fields and slot names, and that it passes `integrity_errors()`.
- Only then does it replace live state. Otherwise it returns errors and changes nothing.
- JSON turns ints into floats, so `restore` converts `pocket` and `selected_pocket`
  back to ints.

## Step 1 — add the methods

In `game/workshop/scripts/assembly_model.gd`, find this anchor (must match once):

```
func integrity_errors() -> Array[String]:
```

Insert the following **immediately before** that line, followed by one blank line:

```gdscript
## JSON-safe mutable state for the workshop save; definitions stay authored.
func capture() -> Dictionary:
	return {"items":items.duplicate(true),"assemblies":assemblies.duplicate(true),"pockets":Array(pockets),"selected_pocket":selected_pocket}

## Replaces mutable state only when `data` has this content's exact identities,
## item fields and slot names and passes integrity. Otherwise nothing changes.
## No migration: a snapshot from different content is simply rejected.
func restore(data: Variant) -> Array[String]:
	if not data is Dictionary or not data.get("items") is Dictionary or not data.get("assemblies") is Dictionary or not data.get("pockets") is Array:return ["Invalid model snapshot."]
	if data.items.size() != items.size() or not items.keys().all(func(uid):return data.items.has(uid)):return ["Item identities changed."]
	if data.assemblies.size() != assemblies.size() or not assemblies.keys().all(func(id):return data.assemblies.has(id)):return ["Assembly identities changed."]
	if data.pockets.size() != POCKET_SLOTS or not data.pockets.all(func(kind):return kind is String):return ["Invalid pockets."]
	var candidate = AssemblyModel.new()
	candidate.definitions = definitions
	candidate.support_definitions = support_definitions
	candidate.expected_ids = expected_ids
	# Rebuild in today's key order; integrity compares item order with expected_ids.
	for uid in items:
		var saved: Variant = data.items[uid]
		if not saved is Dictionary or saved.size() != items[uid].size() or not items[uid].keys().all(func(key):return saved.has(key)):return ["Item fields changed: "+uid]
		if saved.kind != items[uid].kind or saved.source_id != items[uid].source_id:return ["Item kind changed: "+uid]
		var item: Dictionary = {}
		for key in items[uid]:item[key] = saved[key]
		if not (item.pocket is int or item.pocket is float) or not item.location is String or not item.owner is String or not item.slot is String:return ["Invalid item fields: "+uid]
		item.pocket = int(item.pocket)
		candidate.items[uid] = item
	for id in assemblies:
		var saved: Variant = data.assemblies[id]
		if not saved is Dictionary or saved.size() != assemblies[id].size() or not assemblies[id].keys().all(func(key):return saved.has(key)):return ["Assembly fields changed: "+id]
		if saved.definition != assemblies[id].definition or not saved.slots is Dictionary or not saved.history is Array:return ["Assembly definition changed: "+id]
		if saved.slots.size() != assemblies[id].slots.size() or not assemblies[id].slots.keys().all(func(sid):return saved.slots.has(sid) and saved.slots[sid] is String):return ["Assembly slots changed: "+id]
		if not saved.location is String or not saved.parent is String or not saved.parent_slot is String or not saved.history.all(func(step):return step is Dictionary):return ["Invalid assembly fields: "+id]
		var slots: Dictionary = {}
		for sid in assemblies[id].slots:slots[sid] = saved.slots[sid]
		candidate.assemblies[id] = {"definition":saved.definition,"slots":slots,"location":saved.location,"parent":saved.parent,"parent_slot":saved.parent_slot,"history":saved.history.duplicate(true)}
	candidate.pockets.assign(data.pockets)
	candidate.selected_pocket = clampi(int(data.get("selected_pocket",0)),0,POCKET_SLOTS-1)
	var errors: Array[String] = candidate.integrity_errors()
	if not errors.is_empty():return errors
	# Mutate in place: other objects may hold these dictionaries.
	items.clear()
	for uid in candidate.items:items[uid] = candidate.items[uid]
	assemblies.clear()
	for id in candidate.assemblies:assemblies[id] = candidate.assemblies[id]
	pockets.assign(candidate.pockets)
	selected_pocket = candidate.selected_pocket
	changed.emit()
	return []
```

Note: `_add_assembly` creates assemblies with exactly the keys `definition, slots,
location, parent, parent_slot, history`. The rebuild above relies on that. If
`_add_assembly` has other keys when you read it, stop and report.

## Step 2 — tests

In `game/workshop/tests/assembly_model_test.gd`, find this anchor (must match once):

```
	var passed = checks.all(func(c):return c.passed)
```

Insert the following **immediately before** it. By that point in the test, `model`
holds pad_1 at `station:one` with sleeves fitted, which is a non-trivial state.

```gdscript
	# Workshop save contract: a JSON round trip restores exactly; changed shapes are rejected atomically.
	var text: String = JSON.stringify(model.capture())
	var fresh = AssemblyModel.new()
	fresh.configure(definitions,scenario)
	expect(fresh.restore(JSON.parse_string(text)).is_empty(),"JSON model snapshot restores")
	expect(JSON.stringify(fresh.capture())==text,"Restored model matches the saved state exactly")
	expect(fresh.integrity_errors().is_empty() and fresh.items.values().all(func(item):return item.pocket is int),"Restored ownership is valid and pocket indices stay integers")
	var before: String = JSON.stringify(fresh.capture())
	var changed_slot: Dictionary = JSON.parse_string(text)
	changed_slot.assemblies.pad_1.slots.erase("sleeve_0")
	expect(not fresh.restore(changed_slot).is_empty() and JSON.stringify(fresh.capture())==before,"Renamed or removed slots are rejected without changing live state")
	var unknown: Dictionary = JSON.parse_string(text)
	unknown.items["ghost"] = unknown.items.values()[0].duplicate()
	expect(not fresh.restore(unknown).is_empty(),"Unknown identities are rejected")
	var broken_owner: Dictionary = JSON.parse_string(text)
	broken_owner.items[fresh.assemblies.pad_1.slots.sleeve_0].owner = "pad_2"
	expect(not fresh.restore(broken_owner).is_empty() and JSON.stringify(fresh.capture())==before,"Ownership that fails integrity is rejected atomically")
	expect(not fresh.restore("not a snapshot").is_empty(),"Non-dictionary snapshots are rejected")
```

## Acceptance

1. `grep -c "^func capture() -> Dictionary:" game/workshop/scripts/assembly_model.gd` prints `1`.
2. `grep -c "^func restore(data: Variant) -> Array\[String\]:" game/workshop/scripts/assembly_model.gd` prints `1`.
3. `python3 game/workshop/tools/run_regressions.py --only assembly_model_test pockets_model_test state_test`
   passes. `assembly_model_test` must report 7 more checks than before your change.

If check 2 of the new tests fails (exact text match), print both strings and compare
them. A float/int difference in a field other than `pocket`/`selected_pocket` means the
model has another numeric field: convert it the same way, then report it. Stop after
two failed attempts.

## Commit

```
git commit -m "Add atomic AssemblyModel capture/restore for the workshop save" -- game/workshop/scripts/assembly_model.gd game/workshop/tests/assembly_model_test.gd
```
