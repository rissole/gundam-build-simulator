# Operated rigs — pick up here

Branch `operated-rigs`, rebased on `main` at `302066a` on 2026-10-27. Paused on
2026-10-27, when the user moved this work to a separate agent. Nothing on this
branch is merged into `main`.

Before starting, read:
- repository `AGENTS.md`, then [workshop state](../../workshop-state.md)
- the [machine-operation finding](../../robot-workshop-playtest-checklist.md#machine-operation-and-gantry-access--2026-10-26)
- the [B3 design](../../robot-workshop-plan.md#operated-rigs--phase-1-design-2026-10-27)
- this folder's [B brief](B-operated-rigs.md).

## Goal

The foot rig (dispatch → leg rig) and the leg rig (Limb Bay → hip) currently reduce
to pressing NEXT until the job is done. Replace that with machinery the player drives
joint by joint:
- **Hold-E jog buttons** on the existing panels, with mouselook free while E is held.
  The game will eventually be AR, so the target only needs to be in sight.
- A **pulsing ghost** of the carried assembly at the target pose, with per-axis
  readouts that turn green within tolerance.
- **Interlocks** with named refusals instead of a fixed step order.
- **SEAT**, which commits only within tolerance, after a lead-in of a few centimetres.
- The manual teaches each procedure in detail the first time; repeats give the goal
  plus a procedure link.

The foot *building* bay already feels right. Keep it, and keep the physical assembly
challenge the user liked.

**Lesson from the rejected crane operator view (2026-10-27):** it failed partly
because holding Space ran every interesting motion. Don't add a hold-to-run sequence
or an auto-align. The player drives each axis.

## Done on this branch

| Commit | What |
| --- | --- |
| `eab2ec8` | B1: a held-control latch. E latches the aimed equipment button until released; mouselook stays free; a pause or modal releases it. Tested by `held_control_test`. |
| `a0506fc` | B2: `scripts/rig_target.gd`, a cached translucent ghost plus axis-tolerance readout formatting. No collision or targeting. Tested by `rig_target_test`. |
| `b87b9a7` | B3 design in `design/game/robot-workshop-plan.md`: leg joints, ranges, interlocks and refusal text, SEAT lead-in, save fields; the foot rig (B5) design; and the open questions in the playtest checklist. |
| `04c2e7b` | Removed the obsolete dependency on the rejected crane branch from the design. |
| `d145866` | The shared manual mechanism: detailed objectives on first use, then the goal plus a "Procedure: p.N" link. Changes `manual_objectives.gd`, `manual_progress.gd`, `manual_browser.gd`, `hud.gd` and `tools/author_manual_progress.py`. No chapter uses it yet. |

Verified by the parent session on 2026-10-27: `run_regressions.py --only
manual_objectives_test manual_progress_test manual_panel_test held_control_test
rig_target_test workshop_smoke_test --jobs 4` passes 112/33/11/21/25/31 checks in
10.4 s. This is mechanical evidence only; nobody has played it.

## Next, in order

1. **B3: convert the leg rig** (`game/workshop/scripts/indexed_leg_rail.gd`). Not
   started; the worktree was clean when the coordinator was stopped. Implement the B3
   design:
   - NEXT becomes jog pairs, wired through the B1 hold latch, plus BOLSTER, RELEASE
     and SEAT
   - the authored stops become per-axis limits, reusing `snapshot_pose`
   - the interlocks and named refusals
   - the B2 ghost and readout
   - SEAT gating `install_supported`
   - `manual_state()` reporting axis/seat evidence
   - the new at-rest save fields (no migration: invalid saves are deleted).

   Use the design's proposed defaults for its open questions: one constant jog rate
   per axis; service taps for the holder's jaw/lower/withdraw sequence, with fully
   jogged delivery axes; panel banks as designed. Apply the
   `gundam-assembly-review` skill: the carried leg and its mounted children must
   follow every intermediate pose.
2. **B4: leg manual, automation and tests.** The left leg gets one objective per axis;
   the right leg gets the goal plus a procedure link (the `d145866` mechanism). Add an
   automation helper so `build_stages.gd` and the tests can drive the axes. Tests
   cover:
   - limits and interlocks
   - SEAT gating
   - ghost pose equal to the install pose
   - the save round-trip
   - the other cases under "Later verification and open questions" in the B3 design.

   This part is mostly mechanical once B3 exists and suits a well-specified task file.
3. **Checkpoint B:** the user playtests the leg rig. Merge into `main` after the user
   accepts it, or fix their findings first. Record the results in the checklist's
   "Operated rigs open questions" section.
4. **B5/B6: the foot rig** (`foot_carrier.gd`: RAISE, TRAVEL, TURN, SEAT), with its
   manual and tests in the same shape, only after checkpoint B.

## Rules

- Work on this branch only.
- Verification: `python3 game/workshop/tools/run_regressions.py --only <touched suites> --jobs 4`.
  Likely suites are the six above, plus `equipment_motion_test`, `save_roundtrip_test`,
  `stage_contract_test` and any leg-rail suite in `tools/test_inventory.py`.
- Don't run `run_diagnostics.py` or the full suite without an explicit request, and
  don't run a rendered review or walking/reach sweeps. Classify each new suite in
  `tools/test_inventory.py`.
- Saves are snapshots at rest. Guarded motion pauses rather than refuses.
- Report mechanical checks separately from player acceptance.
- When this work merges, fold the lasting facts into the permanent docs (workshop
  state, playtest checklist, robot workshop plan). Then delete this folder's handoff
  files.
