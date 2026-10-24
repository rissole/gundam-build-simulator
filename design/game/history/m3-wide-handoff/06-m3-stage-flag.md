# Task 06 — `--m3-stage=<name>` development launch flag

**Model:** Grok · **Depends on:** 05 · **Expected size:** edits in 2 scripts and the README, 1 new test

## Goal

`./play.command -- --m3-stage=chest` launches M3 and runs the scripted sequence from
`scripts/m3_stages.gd` (task 05) up to the start of the chest stage. The player then
gets control, paused, with a notice that earlier work was supplied by script. No
saves are involved. Restart (pause menu) reloads the scene, which re-runs the flag.

API from task 05 (read `game/workshop/scripts/m3_stages.gd` to confirm):
`STAGES`, `TITLES`, `M3Stages.new(game)`, `stage_errors(stage) -> Array[String]`,
`await run_to(stage, progress: Callable) -> String` ("" on success).

## Rules

- Make only these edits. Don't change equipment, crane or stage-sequence code.
- If `m3_stages.gd` doesn't match the API above, stop and report the difference.
- No M3 save code. No automated walking, reach/visibility or rendered review.
- Don't request sandbox escalation; ask the user to run the Godot import if needed.
- Match the surrounding GDScript style.

## Edits

1. `game/workshop/scripts/scenario_profile.gd`, in `static func resolve(...)`:
   directly above the line
   `	if user_args.has("--m3-workshop"):return profile("leg_bay_m3",legacy)` insert:
   ```gdscript
   	for arg in user_args:
   		if str(arg).begins_with("--m3-stage="):return profile("leg_bay_m3",legacy)
   ```
2. `game/workshop/scripts/workshop.gd`:
   - Near the other top-level preloads/consts, add
     `const M3Stages = preload("res://scripts/m3_stages.gd")`.
   - Near `var automated_test: bool = false`, add `var m3_stage: String = ""`.
   - In `_ready()`, directly after the line `	saves.setup(self)` (the last line of
     `_ready`), add:
     ```gdscript
     	if profile.id == "leg_bay_m3":
     		for arg in OS.get_cmdline_user_args():
     			if str(arg).begins_with("--m3-stage="):m3_stage = str(arg).trim_prefix("--m3-stage=")
     		if not m3_stage.is_empty() and not automated_test:call_deferred("run_m3_stage",m3_stage)
     ```
   - Add this function (next to `reset_demo`):
     ```gdscript
     ## Development shortcut: script the M3 sequence up to `stage`, then hand over
     ## paused. Supplied progress only; never a save or playtest evidence.
     func run_m3_stage(stage: String) -> String:
     	if stage not in M3Stages.STAGES:
     		var unknown = "Unknown M3 stage '"+stage+"'. Use one of: "+", ".join(M3Stages.STAGES)
     		if is_instance_valid(hud):hud.toast(unknown)
     		push_error(unknown)
     		return unknown
     	var title: String = M3Stages.TITLES[stage]
     	var overlay = CanvasLayer.new();overlay.layer = 100;add_child(overlay)
     	var shade = ColorRect.new();shade.color = Color("111d26e6");shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);overlay.add_child(shade)
     	var note = Label.new();note.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
     	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER;note.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
     	note.add_theme_font_size_override("font_size",24);overlay.add_child(note)
     	note.text = "Preparing M3 stage: "+title+"\nEarlier work is supplied by script, not playtested."
     	await get_tree().process_frame;await get_tree().process_frame
     	# Scripted controls block walking/look so the player can't step into a route.
     	var was_automated = automated_test
     	automated_test = true
     	set_paused(false)
     	var error: String = await M3Stages.new(self).run_to(stage,func(step: String):note.text = "Preparing M3 stage: "+title+"\nNow: "+step)
     	automated_test = was_automated
     	overlay.queue_free()
     	set_paused(true)
     	if is_instance_valid(hud):hud.toast(("Stage ready: "+title+". Earlier work was supplied by script.") if error.is_empty() else ("Stage preparation stopped: "+error),error.is_empty())
     	if not error.is_empty():push_error("M3 stage "+stage+": "+error)
     	return error
     ```
     If `hud.toast` has a different signature than `toast(text: String, success: bool = false)`,
     stop and report it.
3. New `game/workshop/tests/m3_stage_flag_test.gd`:
   ```gdscript
   extends "res://tests/kit/harness.gd"
   ## Development launch flag: scripted stage preparation hands over paused at the boundary.
   const M3Stages = preload("res://scripts/m3_stages.gd")
   func _initialize() -> void:call_deferred("run")

   func run() -> void:
   	var game = await boot_profile("leg_bay_m3")
   	var rejected: String = await game.run_m3_stage("no_such_stage")
   	expect(not rejected.is_empty(),"unknown stage is rejected")
   	expect(M3Stages.new(game).stage_errors("pelvis").is_empty(),"rejected stage leaves the fresh workshop untouched")
   	game.free();await frames(2)
   	for stage in ["left_leg_dock","chest","pauldrons"]:
   		game = await boot_profile("leg_bay_m3")
   		var error: String = await game.run_m3_stage(stage)
   		expect(error.is_empty(),stage+" prepares: "+error)
   		expect(game.paused,stage+" hands over paused")
   		expect(M3Stages.new(game).stage_errors(stage).is_empty(),stage+" boundary holds after handover")
   		# boot_profile sets automated_test; run_m3_stage must restore the prior value.
   		expect(game.automated_test,stage+" restores the prior input mode")
   		game.free();await frames(2)
   	var passed = checks.all(func(check):return check.passed)
   	print("M3_STAGE_FLAG ","PASS " if passed else "FAIL ",checks.size()," checks")
   	quit(0 if passed else 1)
   ```
4. `game/workshop/README.md`: below the launch table, add:
   ````markdown
   ### M3 stage shortcut (development)

   `./play.command -- --m3-stage=<stage>` launches M3 and scripts the earlier work
   with the same equipment commands as the mechanical tests, then hands over paused.
   Fastenings and rigging are supplied, so this is not playtest evidence, and nothing
   is saved. Restart re-runs the shortcut. Stages: `pelvis`, `left_leg_build`,
   `left_leg_dock`, `right_leg_build`, `right_leg_dock`, `chest`, `core`, `backpack`,
   `left_arm`, `right_arm`, `pauldrons` (later tasks add `head`, `head_sensors`,
   `complete`). Preparation takes up to about a minute. Don't use the controls until
   the overlay closes.
   ````

## Verify

```sh
python3 game/workshop/tools/run_regressions.py --only m3_stage_flag_test m3_sequence_test m3_workshop_launch default_workshop_launch m2_crane_launch m2_retention_launch --jobs 3
```

All must pass.

## Finish

Commit: `Add --m3-stage development launch flag`.

## Report

Pass/fail per case, `m3_stage_flag_test` seconds, and the commit hash. Ask the user
to try `./play.command -- --m3-stage=chest` and confirm the overlay, the handover
notice, and that walking works after resuming.
