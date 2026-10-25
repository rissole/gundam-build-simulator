# 04 — Pause menu: New workshop and save status

Read [README.md](README.md) "Rules for every task" first. Requires task 03: check
that `grep -c "func new_workshop" game/workshop/scripts/workshop.gd` prints `1`.
Otherwise stop.

**Files you may touch:** `game/workshop/scripts/hud.gd`

## Goal

When saving is on (a normal launch):
- The pause menu's restart button becomes **New workshop**, with a confirm step. It
  deletes the save and reloads.
- The session text says the workshop is saved each time a component is set, plus the
  load/discard notice.

`--stage` launches and test fixtures keep **Restart build** and say the launch isn't
saved. Fixture games may not have a `save` property, so always use
`game.get("save")`.

## Step 1 — replace `refresh_session_status`

In `game/workshop/scripts/hud.gd`, anchor (must match once):

```
## Nothing is saved: the pause menu restarts from this launch's starting stage.
func refresh_session_status() -> void:
	if session_label == null:return
	restart_button.text = "Confirm restart" if confirm_restart else "Restart build"
	resume_button.text = "Resume    →" if entered else "Start building    →"
	if confirm_restart:return
	session_label.text = "Robot workshop · nothing is saved yet.\nRestart begins again from this launch's starting point."+("\n"+game.stage_notice if not game.stage_notice.is_empty() else "")
```

Replace with:

```gdscript
## Whether this launch keeps the workshop save (never in tests or --stage launches).
func _saving() -> bool:
	var slot = game.get("save")
	return slot != null and slot.enabled()

## Normal launches save each set component; --stage launches restart from their start.
func refresh_session_status() -> void:
	if session_label == null:return
	var saving: bool = _saving()
	if confirm_restart:restart_button.text = "Confirm new workshop" if saving else "Confirm restart"
	else:restart_button.text = "New workshop" if saving else "Restart build"
	resume_button.text = "Resume    →" if entered else "Start building    →"
	if confirm_restart:return
	var status: String = "Robot workshop · saved each time a component is set." if saving else "Robot workshop · this launch is not saved.\nRestart begins again from this launch's starting point."
	var notice: String = game.Save.notice if saving else ""
	session_label.text = status+("\n"+notice if not notice.is_empty() else "")+("\n"+game.stage_notice if not game.stage_notice.is_empty() else "")
```

## Step 2 — replace `_restart_clicked`

Anchor (must match once):

```
func _restart_clicked() -> void:
	if confirm_restart:
		confirm_restart = false
		game.reset_demo()
		refresh_session_status()
	else:
		confirm_restart = true
		refresh_session_status()
		session_label.text = "Restart this build from the beginning?\nResume to keep your progress."
```

Replace with:

```gdscript
func _restart_clicked() -> void:
	var saving: bool = _saving()
	if confirm_restart:
		confirm_restart = false
		if saving:game.new_workshop()
		else:game.reset_demo()
		refresh_session_status()
	else:
		confirm_restart = true
		refresh_session_status()
		session_label.text = "Start a new workshop? This deletes your saved build.\nResume to keep it." if saving else "Restart this build from the beginning?\nResume to keep your progress."
```

## Acceptance

1. `grep -c "func _saving() -> bool:" game/workshop/scripts/hud.gd` prints `1`.
2. `grep -c "nothing is saved yet" game/workshop/scripts/hud.gd` prints `0`.
3. `python3 game/workshop/tools/run_regressions.py --only workshop_smoke_test interaction_outline_test targeting_candidates_test`
   passes.
4. `grep -rn "Restart build\|nothing is saved" game/workshop/tests` lists the tests that
   assert the old text. If any of those tests are in the routine set
   (`game/workshop/tools/test_inventory.py` `ROUTINE`), run them with `--only`. If they
   fail only because of the text, stop and report the file and line. Don't edit
   tests in this task.

## Commit

```
git commit -m "Offer New workshop and show save status in the pause menu" -- game/workshop/scripts/hud.gd
```
