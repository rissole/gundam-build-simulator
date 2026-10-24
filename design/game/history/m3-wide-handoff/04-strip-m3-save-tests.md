# Task 04 — Remove save/restore checks from the M3 tests

**Model:** Grok · **Depends on:** 01, 03 · **Expected size:** ~15 test files, mostly deletions

## Goal

M3 saving is deferred (task 03), so M3 tests must stop saving, validating saves or
restoring fresh scenes. Each fresh-scene restore costs ~2.8 s and they were ~75% of
the full-sequence runtime. Keep every check that isn't about saving. Keep all
stop/resume motion checks; only the save between stop and resume goes.

## Rules

- Edit only the test files listed, plus `tools/run_regressions.py`. Change nothing in `game/workshop/scripts/`.
- Delete only what the rules below cover. Don't reorder, rename or restructure tests.
  Task 05 restructures them later.
- No automated walking, reach/visibility or rendered review. Never touch
  `m3_acceptance_test.gd`, `m3_hip_access_test.gd` or `m3_route_clearance_test.gd`.
- Don't request sandbox escalation. If Godot asks for an editor import, stop and ask the user.
- If deleting a line would leave a function or loop body empty, stop and report the location.

## Files in scope (all under `game/workshop/tests/`)

`indexed_leg_rail_test.gd`, `pelvis_delivery_test.gd`, `chest_delivery_test.gd`,
`core_delivery_test.gd`, `backpack_delivery_test.gd`, `backpack_fixture_test.gd`,
`arm_cassette_test.gd`, `arm_delivery_test.gd`, `chest_content_test.gd`,
`core_content_test.gd`, `mirrored_leg_content_test.gd`, `arm_preflight_test.gd`,
`backpack_preflight_test.gd`, `wide_foundation_test.gd`, `m3_stock_test.gd`.

Do **not** edit the M2/default save tests (`save_resume_test.gd`, `m2_*_save_test.gd`,
`foot_save_pin_test.gd`, `save_store_test.gd`, `save_model_test.gd`,
`shared_crane_payload_test.gd`).

## Edits

1. **Make `reopen` a no-op.** In `indexed_leg_rail_test.gd`, replace the whole
   `func reopen(label: String) -> bool:` function (from that line down to and
   including its final `return true`) with:
   ```gdscript
   func reopen(_label: String) -> bool:
   	# M3 saving is deferred (design/game/handoff/README.md). Call sites keep their
   	# stop/resume structure; no snapshot or fresh scene is created.
   	return true
   ```
   Leave every `reopen(...)` call site and the equipment re-fetch lines after them
   unchanged; they're harmless now and task 05 removes them.
2. **Delete save-validation lines.** In every in-scope file, delete each line that
   contains any of: `game.saves.validate(`, `game.saves.capture(`,
   `saves.apply_snapshot(`, `Store.write(`, `Store.read(`, `game.saves.fingerprint`.
   Also delete the lines whose only purpose is to build or alter the value passed to
   those calls. Example from `chest_delivery_test.gd`; delete all three lines:
   ```gdscript
   	var valid: Dictionary=game.saves.capture()
   	var displaced=valid.duplicate(true);displaced.world.fixtures.chest[9]+=.5
   	expect(not game.saves.validate(displaced).is_empty(),"save rejects a displaced mounted chest")
   ```
   The same applies to `var invalid=...`/`var bad=...`/`var unsupported=...`/
   `var unrestrained=...`/`var saved=...`/`var altered=...`/`var wrong=...` lines
   that feed a deleted validate call. Also delete any line that *reads* a variable
   created by a deleted line. Example from `indexed_leg_rail_test.gd`; delete both:
   ```gdscript
   		var errors: Array[String]=game.saves.validate(game.saves.capture())
   		expect(errors.is_empty(),"holder phase validates: "+str(errors))
   ```
   A leftover reference to a deleted variable is a parse error that the runner
   reports as `SCRIPT ERROR`.
3. **Delete equipment-validate guards in helpers, keep the apply.** Delete each
   `expect(crane.validate(...` line and any `var errors...=crane.validate(...)` line
   with the `expect` that reads it. The neighbouring `crane.capture()` and
   `crane.apply(...)` lines stay. Places: `supply_rig` (indexed_leg_rail_test.gd),
   `end_state` (core_delivery_test.gd), `attach_ends`/`stow_ends` (arm_cassette_test.gd),
   and any other `.validate(` on equipment in scope, such as
   `locks.validate(before_locks,game.model)`. Delete that last one together with its
   three setup lines (`var before_locks...`, `before_locks.locked...`, and the `expect`).
4. **`arm_delivery_test.gd`:** delete the whole `func run() -> void:` override (the
   `WORKSHOP_ARM_FIXTURE` shortcut, from `func run` down to its final `finish()`).
   The inherited run is equivalent without the env var. In `after_legs()`, delete the
   line containing `write_evidence("/tmp/arm-ready-fixture.json"`.
5. **`wide_foundation_test.gd`:** delete `const Store = preload(...)`, the line with
   `"initial wider scene snapshot validates"`, and everything from
   `var snapshot: Dictionary = game.saves.capture()` through
   `DirAccess.remove_absolute(path)` inclusive. Replace that range with this one line:
   ```gdscript
   	expect(not access.moving,"stopped access configuration holds its phase")
   ```
   Then delete the now-unused `func _bad_json(...)` function at the end of the file.
6. **`m3_stock_test.gd`:** delete everything from
   `var snapshot: Dictionary = JSON.parse_string(JSON.stringify(game.saves.capture()))`
   through `crane = game.equipment.get_equipment("service_crane");verify_stock(crane,"Restored")` inclusive.
7. **Runner:** in `game/workshop/tools/run_regressions.py`, below the
   `HUMAN_M3_CHECKS = {...}` line, add:
   ```python
   # M3 saving is deferred until the wider structure exists (design/game/handoff/README.md).
   DEFERRED_M3_SAVE_CHECKS = {"m3_save_validation_test"}
   ```
   In `cases()`, change `if path.stem in HUMAN_M3_CHECKS:` to
   `if path.stem in HUMAN_M3_CHECKS or path.stem in DEFERRED_M3_SAVE_CHECKS:`.

## Acceptance

1. This grep, from `game/workshop`, must print nothing:
   ```sh
   grep -n "saves\.\|Store\.\|\.validate(\|arm-ready-fixture\|WORKSHOP_ARM_FIXTURE" tests/indexed_leg_rail_test.gd tests/pelvis_delivery_test.gd tests/chest_delivery_test.gd tests/core_delivery_test.gd tests/backpack_delivery_test.gd tests/backpack_fixture_test.gd tests/arm_cassette_test.gd tests/arm_delivery_test.gd tests/chest_content_test.gd tests/core_content_test.gd tests/mirrored_leg_content_test.gd tests/arm_preflight_test.gd tests/backpack_preflight_test.gd tests/wide_foundation_test.gd tests/m3_stock_test.gd
   ```
2. Run the M3 set:
   ```sh
   python3 game/workshop/tools/run_regressions.py --only indexed_leg_rail_test pelvis_delivery_test chest_delivery_test chest_after_legs_test core_delivery_test core_after_legs_test backpack_delivery_test backpack_after_legs_test backpack_fixture_test arm_cassette_test arm_delivery_test arm_after_legs_test chest_content_test core_content_test mirrored_leg_content_test arm_preflight_test backpack_preflight_test shoulder_content_test wide_foundation_test wide_access_test wide_elevators_test mobile_platform_test rail_gates_test m3_stock_test m3_content_test shared_crane_payload_test m3_workshop_launch --jobs 4
   ```
   Every case must pass. A failure here means an edit removed something it shouldn't
   have: compare against `git diff`, fix your edit, and re-run. Do not change
   `scripts/` to make a test pass.
3. `m3_save_validation_test` must not appear in `python3 game/workshop/tools/run_regressions.py --list`.

## Finish

```sh
git add -A
git commit -m "Remove save and fresh-scene restore checks from M3 mechanical tests"
```

## Report

Per-case pass/fail with check counts and `seconds`, especially `arm_after_legs_test`
before (from task 01) and after; the grep result; and the commit hash.
