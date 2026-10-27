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

B3 and the leg part of B4 (2026-10-27) convert the leg
rig: hold-E jog arrows for INDEX/TRAVEL/TILT/RISE and ROLL/LIFT/BOLSTER, taps for
STOP/SEAT/RELEASE/REACQUIRE/UNSEAT/LANE/PARK/BUILD, the ghost and per-axis readouts,
named interlocks, the guided SEAT lead-in and the new save shape. The left leg's
manual teaches one axis per objective; the right leg's pages are tagged repeats
(`leg_delivery`, `leg_return` in `manual-chapters.json`). `build_stages.gd`
drives the same arrows through `jog()` / `index_to()`. Choices the design left
open are listed under "B3 implementation notes" in the
[plan](../../robot-workshop-plan.md#b3-implementation-notes-2026-10-27).

Mechanical evidence: the new routine `leg_rig_jog_test` (128 checks) plus the 23
other routine suites touching the rig, crane, foot rig, gates, braces, saves,
content, manual and startup pass (`run_regressions.py --only ...`, 28.6 s).
Diagnostics that drive the leg rig (`indexed_leg_rail_test`, `arm_*`,
`pelvis_delivery_test`) were converted and parse-checked with `--check-only`, and
`stage_sequence_test` now reaches the leg stages through the new driver, but none
were **run**; the real-content seat pose and full stage
journey are therefore unverified until one is requested. Nobody has played it.

## Next, in order

1. **Checkpoint B: the user playtests the leg rig.** Launch
   `./play.command -- --stage=left_leg_dock` (left leg built, braces engaged, hip
   secured) and follow the manual. `--stage=right_leg_build` exercises the new
   left-leg docking driver during preparation and is unverified.
2. Remaining B4 coverage, if the playtest keeps this shape: run the converted
   diagnostics on request; a real-content check that the seated joint pose equals
   `runtime.mount_pose` for both legs.
3. Merge into `main` after the user accepts the leg rig, or fix their findings
   first. Record the results in the checklist's "Operated rigs open questions".
4. **B5/B6: the foot rig** (`foot_carrier.gd`: RAISE, TRAVEL, TURN, SEAT), with its
   manual and tests in the same shape, only after checkpoint B.

## Rules

- Work on this branch only.
- Verification: `python3 game/workshop/tools/run_regressions.py --only <touched suites> --jobs 4`.
  Leg rig suites: `leg_rig_jog_test`, `rail_endpoint_test`, `equipment_motion_test`,
  `joint_restraints_test`, the `manual_*` suites, `save_roundtrip_test`,
  `stage_contract_test` and `workshop_smoke_test`.
- Don't run `run_diagnostics.py` or the full suite without an explicit request, and
  don't run a rendered review or walking/reach sweeps. Classify each new suite in
  `tools/test_inventory.py`.
- Saves are snapshots at rest. Guarded motion pauses rather than refuses.
- Report mechanical checks separately from player acceptance.
- When this work merges, fold the lasting facts into the permanent docs (workshop
  state, playtest checklist, robot workshop plan). Then delete this folder's handoff
  files.

## v2 rebuild status — 2026-10-27 (session stopped at usage limit)

Merged on `operated-rigs`: T1 Limb Bay at X14.1, T2 crossing gates removed, T3
gantry front OPEN/CLOSE, T4 leg rig v2 controller and stage driver (plus the
empty-rig lever fix `c9ccc4c`). A real-content probe docked and returned both legs
through the v2 controls. Diagnostics: `chest_delivery_test` passes (66);
`head_crane_test` fails the same 15 stale "Parts for this step" HUD checks as the
pre-v2 base `ca82c96` (142 others pass).

Open:
- **T5a** (leg manual pages, Astra, worktree `/private/tmp/gbs-t5a-manual`) was
  still running. Verify its commit and merge it.
- **T5b** (leg tests, worktree `/private/tmp/gbs-t5b-tests`, commit `2506aa4` +
  merge of the lever fix): `leg_rig_controls_test` 174/175. One failure: "interrupted
  table motion saves its last stop". Diagnose whether it is a test-fixture or
  controller fault. Then T5b still owes the routine test conversions, diagnostic
  conversions plus parse checks and the recorder (see its brief in the session
  scratchpad, mirrored by `T5-shared-api.md`).
- Then run `indexed_leg_rail_test`, `arm_delivery_test`, `arm_cassette_test` and
  `arm_preflight_test` (approved). The user playtests with
  `./play.command -- --stage=left_leg_dock`.
- The v1 leg tests on `operated-rigs` still fail until T5b merges.

## Rebased onto gantry v2 — 2026-10-27

`operated-rigs` was rebuilt on `main` `9bb629c` (gantry v2 rope access). Replayed
B1–B3, the v1 checkpoint, T2 (gates removed), T1 (Limb Bay X14.1) and T4 (leg rig
v2). T3 (single gantry-front state) was left out: gantry v2 rewrote the same access
and crane code. The pre-rebase branch is `operated-rigs-pre-gantry`. On the rebased
branch: generators pass; startup and the gantry v2 suites pass (10 cases, 952
checks). A real-content probe docks up to RISE, which stops at 46° against the
closed rear leaf, because nothing yet lets the player open the 8.4 m front. The
re-plan awaits the user's decisions on crane access and the lower-front control.

## Re-plan on gantry v2 — 2026-10-27

The user said to begin without choosing, so the recommended options were taken
(both are easy to reverse):

- **The crane never opens the gantry.** It waits with "Open the upper leaves
  (UPPER LEAVES panel beside the left lift)" before every crossing, loaded, empty
  or reverse, and arm deliveries wait for the lower front. v2's automatic opening
  and `restore_access` reset are removed.
- **Two fronts, one mechanism each**, both on the panel banks beside the left lift:
  the existing UPPER LEAVES row (20.6 m) and a new LOWER FRONT row (8.4 m wings plus
  rear leaves). Closing refuses while something is in that front's swing
  (`gantry_occupant(front)`).

The shared contract for all three tasks is kept with the coordinator's
scratchpad briefs and summarised here once merged. Tasks (Sol xhigh replaces
Astra for non-spatial work, per the user):

| Task | Agent | Branch | Scope |
| --- | --- | --- | --- |
| R1 | Astra High | `rigs-r1-access` | Fronts API and LOWER FRONT row, crane waits, occupancy bands, crane stage driver, access/crane tests, leg-dock spatial check |
| R2 | Coordinator | `operated-rigs` `c7756f8` | Leg rig checks `front_open("lower")`; `gantry_front(front, open)`; occupant per front |
| R3 | Sol xhigh | `rigs-r3-manual` | Leg v2 manual pages (port of `5a3e0d5`) and crane-page front objectives |
| R4 | Sol xhigh | `rigs-r4-tests` | Leg rig routine tests, diagnostics conversion, recorder |

Merge order R1, R3, R4; then remove the leg rig's temporary `has_method("front_open")`
guard, rerun the dock probe for both legs and the routine suites, then the approved
diagnostics, then the user's playtest (`./play.command -- --stage=left_leg_dock`).
