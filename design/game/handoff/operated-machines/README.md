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
