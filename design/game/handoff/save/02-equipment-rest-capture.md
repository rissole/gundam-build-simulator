# 02 — Equipment last-stop capture and save helpers

Read [README.md](README.md) "Rules for every task" first. This task can run at the
same time as 01; the files don't overlap.

**Files you may touch:**
- `game/workshop/scripts/equipment_registry.gd`
- `game/workshop/scripts/workshop_save.gd` (new)
- `game/workshop/scripts/workshop_save.gd.uid` (generated)

## Goal

- The registry remembers each machine's `capture()` at its most recent stop. A save
  uses that for any machine still moving, so motion is never saved halfway.
- `save_capture(skipped)` returns the state of every machine except the skipped ids.
- `apply_saved(data)` applies it.
- A new `workshop_save.gd` starts with two generic static helpers that task 03 uses:
  - `coerce`: restores JSON floats to ints where today's value is an int
  - `same_shape`: checks a saved capture has exactly today's fields

## Step 1 — registry state

In `game/workshop/scripts/equipment_registry.gd`, anchor (must match once):

```
var _items: Array = []
```

Replace it with:

```gdscript
var _items: Array = []
## Each machine's capture at its most recent stop (or first tick). A save uses it
## for a machine that is still moving, so motion is never saved halfway.
var _rest: Dictionary = {}
var _was_moving: Dictionary = {}
```

## Step 2 — record stops each tick

Anchor (must match once):

```
	for equipment in items:equipment.physics(delta)
```

Replace it with:

```gdscript
	for equipment in items:equipment.physics(delta)
	_remember_rest(items)
```

## Step 3 — new methods

Anchor (must match once):

```
func capture() -> Dictionary:
	var result = {}
	for equipment in all():result[equipment.equipment_id] = equipment.capture()
	return result
```

Insert the following **immediately after** that function, with a blank line before it:

```gdscript
## Captures a machine only when it comes to rest (and on its first tick), never every frame.
func _remember_rest(items: Array) -> void:
	for equipment in items:
		var id: String = equipment.equipment_id
		var moving: bool = equipment.get("moving") == true
		if not moving and _was_moving.get(id,true):_rest[id] = equipment.capture()
		_was_moving[id] = moving

## Save state for every machine except `skipped`: live when at rest, otherwise
## its last stop.
func save_capture(skipped: Array = []) -> Dictionary:
	var result = {}
	for equipment in all():
		var id: String = equipment.equipment_id
		if id in skipped:continue
		var state: Dictionary = _rest[id] if equipment.get("moving") == true and _rest.has(id) else equipment.capture()
		result[id] = state.duplicate(true)
	return result

## Applies save_capture() output, in interaction order, to the machines it lists.
func apply_saved(data: Dictionary) -> void:
	for equipment in all():
		if data.has(equipment.equipment_id):equipment.apply(data[equipment.equipment_id])
	_rest.clear()
	_was_moving.clear()
```

## Step 4 — new file `game/workshop/scripts/workshop_save.gd`

Create it with exactly this content. Task 03 extends this same file.

```gdscript
extends RefCounted
## One local workshop save slot. Task 03 adds the store and load; these helpers
## are generic so no machine needs its own save code.

## Saved machine state must have exactly the fields today's capture has.
static func same_shape(saved: Variant, fresh: Variant) -> bool:
	if not saved is Dictionary or not fresh is Dictionary or saved.size() != fresh.size():return false
	return fresh.keys().all(func(key):return saved.has(key))

## JSON turns every number into a float. Restore ints wherever today's value is
## an int, recursively, so typed fields and comparisons keep working.
static func coerce(saved: Variant, fresh: Variant) -> Variant:
	if fresh is int and saved is float:return int(saved)
	if fresh is Dictionary and saved is Dictionary:
		var result = {}
		for key in saved:result[key] = coerce(saved[key],fresh[key]) if fresh.has(key) else saved[key]
		return result
	if fresh is Array and saved is Array and not fresh.is_empty():
		var result = []
		for index in range(saved.size()):result.append(coerce(saved[index],fresh[mini(index,fresh.size()-1)]))
		return result
	return saved
```

Then run `./play.command --headless --editor --import --quit` once to generate
`workshop_save.gd.uid`.

## Acceptance

1. `grep -c "func save_capture(skipped: Array = \[\]) -> Dictionary:" game/workshop/scripts/equipment_registry.gd` prints `1`.
2. `grep -c "^	_remember_rest(items)$" game/workshop/scripts/equipment_registry.gd` prints `1`.
3. `test -f game/workshop/scripts/workshop_save.gd.uid && grep -c "class_name" game/workshop/scripts/workshop_save.gd`
   prints `0`.
4. `python3 game/workshop/tools/run_regressions.py --only workshop_smoke_test wide_elevators_test equipment_motion_test access_lift_test`
   passes.

## Commit

```
git commit -m "Remember each machine's last stop for the workshop save" -- game/workshop/scripts/equipment_registry.gd game/workshop/scripts/workshop_save.gd game/workshop/scripts/workshop_save.gd.uid
```
