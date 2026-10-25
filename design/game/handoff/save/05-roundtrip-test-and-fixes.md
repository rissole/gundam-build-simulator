# 05 — Round-trip test and at-rest apply fixes

Read [README.md](README.md) "Rules for every task" first. Requires tasks 03 and 04:
check that `grep -c "func load_saved" game/workshop/scripts/workshop_save.gd` and
`grep -c "func _saving" game/workshop/scripts/hud.gd` each print `1`. Otherwise stop.

**Files you may touch:**
- `game/workshop/tests/kit/save_roundtrip.gd` (new) and its `.uid`
- `game/workshop/tests/save_roundtrip_test.gd` (new) and its `.uid`
- `game/workshop/tests/workshop_smoke_test.gd`
- `game/workshop/tools/test_inventory.py`
- `game/workshop/scripts/supported_fixture.gd`
- `game/workshop/scripts/staged_receiver.gd`
- Only under the step 6 rule: the `apply()`/`_pose()` of a machine named in a
  failing round-trip message

## Goal

Prove that a normal save reloads to the same build:
- same model
- every machine (except the crane) at its saved stop
- the same body poses
- the crane parked
- empty hands and pockets

Also prove that invalid files are deleted without touching live state. Then fix the
two at-rest `apply()` gaps already known.

## Step 1 — known fix: foot fixture applies its indexed pose at rest

`supported_fixture.apply` currently re-poses from the foot's current transform. After
a reload that is the fresh upright pose, so a turned foot comes back upright.

In `game/workshop/scripts/supported_fixture.gd`, anchor (must match once):

```
	_apply_pose(foot.global_transform)
```

Replace with:

```gdscript
	# At rest the indexed pose is authoritative (a reload starts from the fresh pose).
	# The foot follows only while this fixture still holds it.
	var pose: Transform3D = foot.global_transform if moving else Transform3D(Basis(Vector3.BACK, POSE_ANGLES[work_pose]), dispatch_origin if at_dispatch else work_origin)
	if game.model.assemblies[game.default_parent_id()].location == holding_location:
		_apply_pose(pose)
	else:
		carriage.global_position = Vector3(pose.origin.x, 0, pose.origin.z)
		rotator.global_transform = pose
```

## Step 2 — known fix: staged receivers save released restraints

Staged receivers derive everything from the model except which joint/digit
restraints the player released. Today that resets on reload.

In `game/workshop/scripts/staged_receiver.gd`:

**2a.** Anchor:
```
## this controller deliberately inherits the equipment's empty save contract.
```
Replace with:
```gdscript
## its only save state is which joint and digit restraints the player released.
```

**2b.** Anchor:
```
func operations_released() -> bool:return released_operations.values().all(func(value):return value)
```
Insert this **immediately after** it, with a blank line before it:
```gdscript
func capture() -> Dictionary:return {"released_operations":released_operations.duplicate()}

func apply(data: Dictionary) -> void:
	for operation in released_operations:
		var released: bool = data.get("released_operations",{}).get(operation,false) == true
		released_operations[operation] = released
		operation_nodes[operation].visual.visible = not released
		operation_nodes[operation].collision.disabled = released
	_sync()
```

## Step 3 — shared comparison kit `game/workshop/tests/kit/save_roundtrip.gd`

Create it with exactly this content:

```gdscript
extends RefCounted
## What a workshop reload must reproduce: the normalised model, every saved
## machine's state, and the pose of every placed (non-loose) assembly body.
const Save = preload("res://scripts/workshop_save.gd")

static func state(game: Node) -> Dictionary:
	var poses = {}
	for id in game.runtime.nodes:
		var a: Dictionary = game.model.assemblies.get(id,{})
		# Loose builds reset to their home pose and settle under physics.
		if a.is_empty() or (a.parent.is_empty() and a.location == "loose"):continue
		var node: Node3D = game.runtime.node(id)
		if is_instance_valid(node):poses[id] = node.global_transform
	return {"model":JSON.stringify(game.save.normalised_model()),"equipment":game.equipment.save_capture(Save.SKIPPED),"poses":poses}

## Differences between a saved workshop's state and its reload, as messages.
static func differences(saved: Dictionary, loaded: Dictionary) -> Array[String]:
	var errors: Array[String] = []
	if saved.model != loaded.model:errors.append("model differs")
	for id in saved.equipment:
		var a: String = JSON.stringify(saved.equipment[id])
		var b: String = JSON.stringify(loaded.equipment.get(id))
		if a != b:errors.append(id+" differs: "+a+" vs "+b)
	for id in saved.poses:
		var a: Transform3D = saved.poses[id]
		var b: Transform3D = loaded.poses.get(id,Transform3D())
		if a.origin.distance_to(b.origin) > .001 or not a.basis.is_equal_approx(b.basis):errors.append(id+" body moved: "+str(a.origin)+" vs "+str(b.origin))
	return errors

## A second workshop in its own physics world, so it never collides with one still
## under test. Free it with `workshop.get_parent().free()`.
static func boot_isolated(tree: SceneTree, path: String) -> Node:
	var viewport = SubViewport.new()
	viewport.own_world_3d = true
	tree.root.add_child(viewport)
	var workshop = load("res://scenes/workshop.tscn").instantiate()
	workshop.automated_test = true
	workshop.save_path = path
	viewport.add_child(workshop)
	for tick in range(8):await tree.physics_frame
	workshop.set_paused(false)
	return workshop
```

## Step 4 — routine test `game/workshop/tests/save_roundtrip_test.gd`

Create it with exactly this content:

```gdscript
extends "res://tests/kit/harness.gd"
## Workshop save round trip from a fresh boot: build state, machine stops, the
## parked crane and deletion of invalid files. Later stages: save_roundtrip_stages_test.
const Save = preload("res://scripts/workshop_save.gd")
const Stages = preload("res://scripts/build_stages.gd")
const Roundtrip = preload("res://tests/kit/save_roundtrip.gd")
const PATH = "user://save-roundtrip-test.json"
func _initialize() -> void:call_deferred("run")
func run() -> void:
	Save.delete(PATH)
	var game = await boot_workshop("",8,{"save_path":PATH})
	expect(game.save.enabled() and not FileAccess.file_exists(PATH),"an opted-in fresh workshop writes nothing before a component is set")
	expect(game.automation.suspend_at_station("pad_1","prep").is_empty() and game.automation.fill("pad_1",2) == 2,"pad_1 sits at a station with two fitted sleeves")
	await frames(2,false)
	expect(FileAccess.file_exists(PATH),"setting a component writes the save")
	var fixture = game.equipment.get_equipment("foot_fixture")
	expect(Stages.new(game).command(fixture,"sole_left").is_empty() and fixture.work_pose == "sole_left","the foot fixture turns to a stop")
	await frames(2)
	var lift = game.equipment.get_equipment("left_lift")
	var lift_rest: String = JSON.stringify(lift.capture())
	expect(lift.request("up").is_empty() and lift.moving,"the left lift starts moving")
	expect(game.automation.fill("pad_1",1) == 1,"a sleeve is fitted while the lift moves")
	await frames(2,false)
	var undone: Dictionary = game.model.undo("pad_1")
	game.components.sync("pad_1")
	expect(undone.ok,"an undo is saved like any other change")
	await frames(2,false)
	expect(lift.moving,"the lift is still moving when the save is written")
	var file: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	expect(JSON.stringify(Save.coerce(file.equipment.left_lift,lift.capture())) == lift_rest,"a moving machine is saved at its last stop")
	expect(not file.equipment.has("service_crane"),"the crane is not saved")
	var saved: Dictionary = Roundtrip.state(game)
	game.free()
	await frames(2)
	var loaded = await boot_workshop("",8,{"save_path":PATH})
	var differences: Array[String] = Roundtrip.differences(saved,Roundtrip.state(loaded))
	expect(differences.is_empty(),"the reload matches the saved workshop: "+"; ".join(differences))
	var crane = loaded.equipment.get_equipment("service_crane")
	expect(crane.station == "park" and crane.attached_count() == 0,"the crane reloads parked with its ends stowed")
	expect(loaded.model.integrity_errors().is_empty() and loaded.model.held_item().is_empty() and loaded.held_build().is_empty() and loaded.model.pockets.all(func(kind):return kind.is_empty()),"the reload is valid with empty hands and pockets")
	expect(Save.notice.begins_with("Restored"),"the pause menu notice reports the restore")
	# Invalid files are deleted before anything live changes.
	var good: String = FileAccess.get_file_as_string(PATH)
	var before: String = JSON.stringify(loaded.save.normalised_model())
	var wrong_format: Dictionary = JSON.parse_string(good)
	wrong_format.format = 999
	var unknown: Dictionary = JSON.parse_string(good)
	unknown.model.items["ghost"] = unknown.model.items.values()[0]
	var renamed: Dictionary = JSON.parse_string(good)
	renamed.equipment.left_lift["renamed"] = 1
	for case in [["truncated JSON",good.substr(0,good.length()/2)],["wrong format",JSON.stringify(wrong_format)],["unknown identity",JSON.stringify(unknown)],["changed machine fields",JSON.stringify(renamed)]]:
		var out = FileAccess.open(PATH,FileAccess.WRITE)
		out.store_string(case[1])
		out.close()
		Save.notice = ""
		expect(not loaded.save.load_saved() and not FileAccess.file_exists(PATH) and Save.notice.begins_with("Your saved workshop") and JSON.stringify(loaded.save.normalised_model()) == before,"discarded without changes: "+case[0])
	loaded.free()
	Save.delete(PATH)
	var passed = checks.all(func(c):return c.passed)
	print("SAVE_ROUNDTRIP ","PASS " if passed else "FAIL ",checks.size()," checks")
	quit(0 if passed else 1)
```

## Step 5 — isolation check and inventory

**5a.** In `game/workshop/tests/workshop_smoke_test.gd`, anchor (must match once):
```
	expect(game.hud.manual_id=="foot" and game.model.integrity_errors().is_empty(),"initial manual and ownership are valid")
```
Insert this **immediately after** it:
```gdscript
	expect(game.save != null and not game.save.enabled(),"automated boots never read or write the human save")
```

**5b.** In `game/workshop/tools/test_inventory.py`, add `'save_roundtrip_test',` to
`ROUTINE`, in alphabetical position (after `'runner_contracts',`).

Then run `./play.command --headless --editor --import --quit` once to generate the
`.uid` files for the two new scripts.

## Step 6 — run and fix

```
python3 game/workshop/tools/run_regressions.py --only save_roundtrip_test workshop_smoke_test receiver_contract_test stage_contract_test
```

If `save_roundtrip_test` fails:
- **`<machine> differs` or `<assembly> body moved`:** you may change only that machine's
  `apply()` or the `_pose()` it calls, so that applying an at-rest capture (`moving` is
  false) poses the machine and the loads it supports from its state and the model,
  never from the current body transform. Keep the change local. Never add per-machine
  validators, and never change `capture()` keys unless the difference message proves a
  needed at-rest field is missing.
- **`model differs`:** stop and report it with the full test output. That is a task 01/03
  problem, not something to patch here.
- **A runner failure caused by `WARNING:` lines** (from `push_warning` in discard): stop
  and report. Don't remove the warnings.
- **Time:** `save_roundtrip_test` must take under 15 s in the runner's slowest-cases
  report. If it doesn't, stop and report the time.

Stop and report after two failed attempts on the same failure.

## Acceptance

1. The run in step 6 passes all four cases.
2. `grep -c "'save_roundtrip_test'" game/workshop/tools/test_inventory.py` prints `1`.
3. `python3 game/workshop/tools/run_regressions.py --only assembly_model_test wide_elevators_test access_lift_test`
   still passes.

## Commit

Include every machine file you changed under the step 6 rule.

```
git commit -m "Test the workshop save round trip and restore machines at rest" -- game/workshop/tests/kit/save_roundtrip.gd game/workshop/tests/kit/save_roundtrip.gd.uid game/workshop/tests/save_roundtrip_test.gd game/workshop/tests/save_roundtrip_test.gd.uid game/workshop/tests/workshop_smoke_test.gd game/workshop/tools/test_inventory.py game/workshop/scripts/supported_fixture.gd game/workshop/scripts/staged_receiver.gd
```
