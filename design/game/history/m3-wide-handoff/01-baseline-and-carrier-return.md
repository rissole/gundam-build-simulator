# Task 01 — Baseline commit and right-foot carrier return

**Model:** Grok · **Depends on:** nothing · **Expected size:** 3 small edits, 2 commits

## Context

The working tree holds ~6 hours of uncommitted M3 work. The full-sequence test
`arm_after_legs_test` fails at check 873 with:

`service_crane accepts go:source: Clear the foot carrier from the common station before lowering the cassette.`

Cause: `tests/indexed_leg_rail_test.gd` returns the empty foot carrier after the
left leg (around line 173) but never after the right leg. The cassette interlock in
`scripts/arm_cassette.gd:118` correctly requires the carrier at home.
Do **not** change that interlock.

## Rules

- Do exactly these steps. Change nothing in `game/workshop/scripts/`.
- No automated walking, reach/visibility or rendered review.
- Don't request sandbox escalation. If Godot asks for an editor import, stop and
  ask the user to run `./play.command --headless --editor --import --quit`.
- If a step can't be done exactly as written, stop and report what you found.

## Steps

1. From the repo root, confirm the current branch is `main` and the tree is dirty:
   `git status --short | head`.
2. Create the branch and commit everything as-is:
   ```sh
   git switch -c m3-wide-structure
   git add -A
   git commit -m "Integrate wider M3 workshop through both shoulder installs (paused Codex run, 2026-10-24)"
   ```
3. In `game/workshop/tests/indexed_leg_rail_test.gd`, find this exact line
   (it occurs once):
   ```gdscript
   	if not await reopen("second empty return"):finish();return
   ```
   Insert these three lines **directly after it** (tab-indented, same style):
   ```gdscript
   	for phase in range(3):
   		if not command(carrier,"return"):finish();return
   	expect(carrier.path==0 and carrier.withdrawal==0 and not carrier.carrying(),"empty carrier returns without moving retained right foot")
   ```
4. In `game/workshop/tools/run_regressions.py`, replace
   ```python
   CASE_TIMEOUTS = {"m3_acceptance_test": 900.0}
   ```
   with
   ```python
   CASE_TIMEOUTS = {"m3_acceptance_test": 900.0, "arm_after_legs_test": 600.0, "arm_delivery_test": 600.0}
   ```
   The full sequence now runs past the 180 s default. Task 04 makes it fast again.
5. Run:
   ```sh
   python3 game/workshop/tools/run_regressions.py --only indexed_leg_rail_test arm_after_legs_test --jobs 2
   ```
   This takes up to ~5 minutes.
6. Read `<REGRESSION_OUTPUT dir>/results.json`.
   - **Both passed:** commit:
     ```sh
     git add -A
     git commit -m "Return the right-foot carrier before cassette delivery in the M3 sequence test"
     ```
   - **`arm_after_legs_test` failed at a different check:** do not fix it. Commit
     steps 3–4 anyway with the message above plus `(arm sequence still failing)`,
     and report the first `CHECK FAIL` line plus the last 40 lines of
     `<dir>/arm_after_legs_test.log`.
   - **The carrier `return` itself is rejected:** revert step 3 (`git checkout -- game/workshop/tests/indexed_leg_rail_test.gd`),
     don't commit, and report the rejection message.

## Report

Branch name, both commit hashes, per-case pass/fail with check counts and
`seconds`, and any failure text.
