# 06 — Stage round-trip diagnostic and docs

Read [README.md](README.md) "Rules for every task" first. Requires task 05: check
that `game/workshop/tests/kit/save_roundtrip.gd` exists and that
`grep -c "'save_roundtrip_test'" game/workshop/tools/test_inventory.py` prints `1`.
Otherwise stop.

**Files you may touch:**
- `game/workshop/tests/save_roundtrip_stages_test.gd` (new) and its `.uid`
- `game/workshop/tools/test_inventory.py`
- `game/workshop/README.md`
- `design/game/robot-workshop-plan.md`
- `design/game/workshop-state.md`

**Do not run the new diagnostic.** It is expensive and runs only at the user's explicit request.

## Step 1 — diagnostic `game/workshop/tests/save_roundtrip_stages_test.gd`

Create it with exactly this content:

```gdscript
extends "res://tests/kit/harness.gd"
## Expensive diagnostic, explicit request only: the save round trip at every stage
## boundary from the foot to the complete robot. Each reload boots in its own
## physics world beside the workshop under test.
const Save = preload("res://scripts/workshop_save.gd")
const Stages = preload("res://scripts/build_stages.gd")
const Roundtrip = preload("res://tests/kit/save_roundtrip.gd")
const PATH = "user://save-roundtrip-stages.json"
func _initialize() -> void:call_deferred("run")
func run() -> void:
	Save.delete(PATH)
	var game = await boot_workshop("",8,{"save_path":PATH})
	var runner = Stages.new(game)
	for stage in Stages.ALL:
		var errors: Array[String] = runner.stage_errors(stage)
		expect(errors.is_empty(),stage+" boundary reached: "+"; ".join(errors))
		if not errors.is_empty():break
		expect(game.save.write(game.save.snapshot()).is_empty(),stage+" save written")
		var saved: Dictionary = Roundtrip.state(game)
		var loaded = await Roundtrip.boot_isolated(self,PATH)
		var differences: Array[String] = Roundtrip.differences(saved,Roundtrip.state(loaded))
		expect(differences.is_empty(),stage+" reload matches: "+"; ".join(differences))
		expect(loaded.model.integrity_errors().is_empty() and loaded.equipment.get_equipment("service_crane").station == "park",stage+" reload is valid with the crane parked")
		loaded.get_parent().free()
		await frames(2)
		if stage == Stages.ALL.back():break
		var error: String = runner.complete(stage)
		expect(error.is_empty(),stage+" completed: "+error)
		if not error.is_empty():break
		await process_frame
	game.free()
	Save.delete(PATH)
	var passed = checks.all(func(c):return c.passed)
	print("SAVE_ROUNDTRIP_STAGES ","PASS " if passed else "FAIL ",checks.size()," checks")
	quit(0 if passed else 1)
```

Run `./play.command --headless --editor --import --quit` once to generate its `.uid`.

In `game/workshop/tools/test_inventory.py`, add this line to `DIAGNOSTIC`, after
`'robot_workshop_test',`:

```
    'save_roundtrip_stages_test',  # Every stage boundary; explicit request only.
```

## Step 2 — docs

Use exact replacements. Each anchor must match once; check with `grep -cF`.

**2a.** `design/game/robot-workshop-plan.md`. Replace the whole paragraph that starts
with `**Deferred on 2026-10-24.**` and ends with `preserved for that later work.` with:

```markdown
**Implemented 2026-10-25 as a lightweight snapshot.** One local slot,
`user://workshop-save.json`, is written each time the normalised assembly model
changes: a component set, mounted, seated or undone. It holds the model and
each machine's `capture()` at its last stop, so motion is never saved halfway. The
service crane is not saved. It reloads parked, and no save is taken while a load
hangs on it. Loading is synchronous: restore the model, place assembly bodies, let
each machine `apply()` its at-rest state, re-sync visuals. The player, pockets,
loose and held parts and the manual reset. An invalid file (unreadable, a different
`FORMAT`, changed identities, slots or machine fields, or failed integrity) is
deleted; there are no migrations, checksums or backups. Tests, tools and `--stage`
launches never touch the slot. The pause menu's **New workshop** deletes it. The one
ongoing rule: a machine's `capture()`/`apply()` must round-trip its at-rest state,
including where its supported load sits. `save_roundtrip_test` checks a fresh boot;
the explicit-request diagnostic `save_roundtrip_stages_test` checks every stage
boundary. A replayed action log was rejected because late-game loads would be too
slow. The removed mid-motion design is [archived](history/save-resume.md).
Handoff: [design/game/handoff/save/](handoff/save/README.md).
```

Then replace the line `*Preserved requirements (not active):*` with:

```markdown
*Original requirements (superseded by the design above; pause-menu checkpoints remain unimplemented):*
```

**2b.** `game/workshop/README.md`:
- Replace `Nothing is saved yet (see [Saves and checkpoints](../../design/game/robot-workshop-plan.md#saves-and-checkpoints)): Restart and relaunch begin again from the launch's starting stage.`
  with `Your build is saved each time you set a component and restored when you relaunch (see [Saves and checkpoints](../../design/game/robot-workshop-plan.md#saves-and-checkpoints)); **New workshop** in the pause menu starts over.`
- Replace `playtest evidence, and nothing is saved. Restart re-runs the shortcut.`
  with `playtest evidence, and stage launches are never saved. Restart re-runs the shortcut.`
- Replace these four lines:
  ```
  Nothing is saved yet. Quitting or restarting begins again from the launch's
  starting stage; use `--stage` to skip earlier work. The earlier foot-only save
  system was removed with the separate foot workshop; robot saves are planned in
  [Saves and checkpoints](../../design/game/robot-workshop-plan.md#saves-and-checkpoints).
  ```
  with:
  ```
  A normal launch saves to `user://workshop-save.json` (on macOS,
  `~/Library/Application Support/Godot/app_userdata/<project name>/`) each time a
  component is set, and restores it on the next launch. The crane reloads parked;
  hands, pockets and loose parts return to their drawers; a machine moving at save
  time reloads at its last stop. An invalid save is deleted, never migrated. **New
  workshop** deletes it. Tests, tools and `--stage` launches never touch it. A
  machine's `capture()`/`apply()` must round-trip its at-rest state, including its
  supported load; see [Saves and checkpoints](../../design/game/robot-workshop-plan.md#saves-and-checkpoints).
  ```
- Replace `| Escape | Open grouped controls, Resume, Restart build (asks for confirmation) or Quit |`
  with `| Escape | Open grouped controls, Resume, New workshop (Restart build in --stage launches; asks for confirmation) or Quit |`.

**2c.** `design/game/workshop-state.md`: insert this bullet as the **first** item under
`## Where things stand`, followed by a blank line before the next bullet:

```markdown
- **Workshop save (2026-10-25):** normal launches save each time a component is
  set and restore on launch: the model and every machine's last stop, with the
  crane parked and hands/pockets/loose parts back in drawers. Invalid saves are
  deleted, never migrated. The pause menu offers **New workshop**. Mechanical
  checks: `save_roundtrip_test` (fresh boot). The later-stage diagnostic
  `save_roundtrip_stages_test` has **not** been run. Reload feel and correctness in
  later stages await the user's playtest. Design:
  [Saves and checkpoints](robot-workshop-plan.md#saves-and-checkpoints).
```

If `workshop-state.md` has other lines saying saves are deferred, removed or
"nothing is saved", list them in your report with line numbers, but don't edit them.

## Acceptance

1. `grep -c "save_roundtrip_stages_test" game/workshop/tools/test_inventory.py` prints `1`.
2. `grep -c "Nothing is saved yet" game/workshop/README.md` prints `0`.
3. `grep -c "Implemented 2026-10-25 as a lightweight snapshot" design/game/robot-workshop-plan.md` prints `1`.
4. `python3 game/workshop/tools/run_regressions.py --only runner_contracts save_roundtrip_test`
   passes. `runner_contracts` checks that every test is classified. Do not run the
   diagnostic.

## Commit

```
git commit -m "Document the workshop save and add the stage round-trip diagnostic" -- game/workshop/tests/save_roundtrip_stages_test.gd game/workshop/tests/save_roundtrip_stages_test.gd.uid game/workshop/tools/test_inventory.py game/workshop/README.md design/game/robot-workshop-plan.md design/game/workshop-state.md design/game/handoff/save
```
