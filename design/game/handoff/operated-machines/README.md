# Operated machines and gantry access — branch handoffs

Written 2026-10-27 from the
[2026-10-26 playtest](../../robot-workshop-playtest-checklist.md#machine-operation-and-gantry-access--2026-10-26).
Read that finding, [workshop state](../../workshop-state.md) and repository
`AGENTS.md` before starting.

Goal: operating a machine becomes a skill the player learns once and recalls later.
The gantry should stop blocking both walking and the robot's exit. The game will
eventually be AR, so controls stay physical and in sight.

## Branches

| Branch | Worktree | Coordinator brief | Merge order |
| --- | --- | --- | --- |
| `crane-operator-view` | `/private/tmp/gbs-crane` | [A — Crane operator view](A-crane-operator-view.md) | 2nd |
| `operated-rigs` | `/private/tmp/gbs-rigs` | [B — Operated rigs](B-operated-rigs.md) | 3rd, rebased on A |
| `gantry-access` | `/private/tmp/gbs-gantry` | [C — Gantry access](C-gantry-access.md) | Fixes 1st; v2 doc anytime |

Each branch has one Astra High coordinator (Codex). The coordinator does the
judgment work and writes **Grok task files** for unambiguous pieces into this folder
(`A5-….md`, etc.). Each Grok task file is self-contained: exact anchors (quoted
strings verified to match once), exact replacement code or data, run commands,
acceptance greps/tests and stop conditions. The parent session launches Grok, then
the coordinator reviews and integrates. A coordinator run ends at its phase's stop
point. It never waits for Grok.

## Shared rules

- **Contention.** A and B both touch `manual_objectives.gd`, `manual_progress.gd`,
  `assets/manual-chapters.json`, `desktop_input.gd` and `hud.gd`. A owns the shared
  manual "first use vs. repeat" mechanism; B consumes it. Before A merges, B edits
  only its input-latch and ghost-target helpers (B1, B2).
- Commit scoped, one commit per task, on your branch only. Never touch `main` or
  another worktree.
- Verification: `python3 game/workshop/tools/run_regressions.py --only <touched suites> --jobs 4`.
  No `run_diagnostics.py`, no full suite, no rendered review, and no automated
  walking/reach sweeps. Classify every new suite in `game/workshop/tools/test_inventory.py`.
- Follow the active rules in `workshop-state.md`: saves are snapshots at rest, with
  no migrations (invalid saves are deleted). One workshop, reached through
  `--stage`. Guarded equipment motion pauses rather than refuses. Report mechanical
  evidence separately from player acceptance.
- If you need new part icons, stop and ask for the editor import. Do not run it
  inside the sandbox.
- End every run with a short report: commits, tests run with results, open
  questions, and the Grok task files written.

## Human checkpoints

| Checkpoint | Gate |
| --- | --- |
| A — crane operator view playtest | Before B3 (leg rig axes) starts |
| B — leg rig jog slice playtest | Before B5 (foot rig) starts |
| C0 — user names the asymmetric gantry spot | Before C3 |
| C — v2 concept approval | Before any v2 build |

## Branch C phase 2 report — 2026-10-27

### C2 integration review

Reviewed Grok commit `cd94428` against [C2](C2-fill-plates.md): no defect found.
The parsed layout delta is exactly 34 new fixed solids: ten plates, eight rails
and sixteen posts. Every prior solid, group and other layout field is unchanged;
generator and runtime assertions match the specification. No implementation
repair was needed.

Fresh verification: generator `--check` passes (676 solids, 91 frames, byte
equality); `run_regressions.py --only gantry_dressing_test access_lift_test
wide_elevators_test workshop_smoke_test --jobs 4` passes 137/45/93/31 checks in
9.189 s, inputs unchanged. Evidence:
`game/workshop/verification/regressions-20261026T132834.773580Z`.
No diagnostics or rendered review. Landing catches and usability still await
player recheck. No new Grok task files; C2 is the existing task file reviewed.

### C3 mirror repair

C0 answered: the lowest level, left and right of the hip assembly, has mismatched
railings and access to the hip's side on only one side. This authorizes C3.

Runtime cause: the right wing is a 180-degree Y copy, which reverses local Z.
Disabling the local rear rail on both wings left the right rail across the hip
finger entrance at world Z24.68 (left rail Z23.32). The right rear-leaf guards
were likewise at Z27.31, facing the hip, instead of the left's Z28.59. Corrected
the right wing's open local edge at every level using the shared authoring rule,
and reflected the two right rear guards' local Z positions. Both hip approaches
now have the same deck and guard geometry, including while folding.

Excluded causes: shared fold channels and mode goals already match; both hip
fingers extend 1.20 m to Z25.8, and both fixed aprons begin at Z27.35. The 1.55 m
finger-to-apron opening is a deliberate robot/leg work opening, not a missing
landing. No new walkway or longer finger is needed. All floor geometry, group
transforms, joint sequencing, modes, supports and delivery data remain unchanged.
The only layout delta is 24 right wing guard visibility/collision flags and two
right rear guard positions. Corrected guards stay within the original wing
Z23.3..24.7 / parked X4.3..5.7 and20.3..21.7 envelopes and the existing rear
bridge Z27.35..28.63 envelope. Upper service and aft openings remain untouched;
folded rear leaves retain their existing outboard position beside the leg corridor.

Extended the classified `gantry_dressing_test`: actual visual and physics box
corners reflect about X13 in all seven modes and 30 supplied intermediate/channel
poses, with waist services available and stowed. Checks include the fixed
landings/aprons, moving decks, guard visibility/collision, the hip-finger entrance
band and the rear guards' work-facing clearance. Fixed end-post numbering is
paired spatially. The test reproduced the pre-fix right entrance obstruction and
rear guard defects (77 failures), then passed with the repair.

Fresh final checks: generator `--check` passes (676 solids, 91 frames, byte
equality); the same four requested suites pass **219/45/93/31 checks in 9.359 s**,
inputs unchanged. Evidence:
`game/workshop/verification/regressions-20261026T133120.780366Z`.
No diagnostics, rendered review or walking/reach sweeps. Automated geometry is
verified; appearance, walking and fastening usability await the
[player recheck](../../robot-workshop-playtest-checklist.md#machine-operation-and-gantry-access--2026-10-26).
No new Grok task files or unresolved implementation questions for C2/C3.
