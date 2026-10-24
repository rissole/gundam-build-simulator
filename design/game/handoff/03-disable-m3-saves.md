# Task 03 — Turn off M3 saving

**Model:** Grok · **Depends on:** 01 · **Expected size:** 4 small edits in 4 files

## Goal

M3 (`leg_bay_m3`, launched with `--m3-workshop`) must not read or write a save file.
The pause menu should show no Save/Reload buttons, and Restart reloads the scene
fresh. The default foot workshop and the M2 trials must keep saving exactly as before.

How saving switches today: `scripts/workshop_save.gd` sets `enabled` only when
`path` is non-empty (around line 32). The M3 profile sets its path in
`scripts/scenario_profile.gd` (around line 46).

## Rules

- Make only the edits below. Don't delete any save code; it stays for the other profiles.
- No automated walking, reach/visibility or rendered review.
- Don't request sandbox escalation. If Godot asks for an editor import, stop and ask the user.
- If a quoted line isn't found exactly once, stop and report it.

## Edits

1. `game/workshop/scripts/scenario_profile.gd` — replace
   ```gdscript
   			p.session = {"codec":"trial","path":"user://m3-workshop-save.json"}
   ```
   with
   ```gdscript
   			# Saving is deferred while the wider structure is built (design/game/handoff/README.md).
   			p.session = {"codec":"trial","path":""}
   ```
2. `game/workshop/scripts/workshop_save.gd` — in `func status_text() -> String:`,
   insert this as the **first line of the function body**:
   ```gdscript
   	if game.profile.trial == "m3" and not enabled:return "M3 wider workshop · saving is off while the structure is built.\nRestart begins again from this launch's starting point."
   ```
3. `game/workshop/scripts/hud.gd` — replace
   ```gdscript
   	if game.profile.session.codec == "trial":
   		var choose_trial = button("Choose M2 trial")
   ```
   with
   ```gdscript
   	if game.profile.session.codec == "trial" and game.profile.trial != "m3":
   		var choose_trial = button("Choose M2 trial")
   ```
4. `game/workshop/scripts/workshop.gd` — replace
   ```gdscript
   func reset_demo() -> void:
   	if is_instance_valid(saves):saves.new_workshop()
   	else:get_tree().reload_current_scene()
   ```
   with
   ```gdscript
   func reset_demo() -> void:
   	# M3 has no save slot; reloading also re-runs any --m3-stage launch flag.
   	if is_instance_valid(saves) and (saves.enabled or profile.trial != "m3"):saves.new_workshop()
   	else:get_tree().reload_current_scene()
   ```
5. `game/workshop/README.md` — in the launch table row that starts
   `| Complete structural leg |`, replace `` `user://m3-workshop-save.json` `` with
   `none (saving deferred)`.

## Verify

```sh
python3 game/workshop/tools/run_regressions.py --only m3_workshop_launch leg_bay_m3_profile_launch default_workshop_launch m2_retention_launch m2_crane_launch save_resume_test m2_retention_save_test m2_crane_save_test foot_save_pin_test save_store_test save_model_test --jobs 4
```

All cases must pass. If a non-M3 case fails, revert your edits
(`git checkout -- game/workshop`) and report. If an M3 test outside this list fails
later because it saves, that's expected; task 04 removes those checks.

## Finish

```sh
git add -A
git commit -m "Turn off M3 saving while the wider workshop structure is built"
```

## Report

Edits made, the regression output directory, per-case pass/fail, and the commit hash.
Also tell the user to check by hand: launch `./play.command -- --m3-workshop`, press
Esc, and confirm the pause menu shows no Save/Reload or "Choose M2 trial" buttons
and that Restart reloads a fresh workshop.
