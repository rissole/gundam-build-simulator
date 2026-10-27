# Gantry v2 rope access — build handoffs

Implements the [overhead rope access concept](../../gantry-v2/overhead-access.md)
(user decisions 2026-10-27) in the workshop. Read that document, the
[mock](../../gantry-v2/mock/overhead-access.html), [workshop state](../../workshop-state.md)
and repository `AGENTS.md` before starting. **Everything stays on branch
`gantry-v2` until the user playtests and approves; never touch `main`.** Delete these
briefs once the work is merged into `gantry-v2` and recorded in permanent docs.

The parent session (Claude) orchestrates, merges task branches into `gantry-v2`,
and runs the central validation. Coordinators do judgment work and may write
self-contained **Grok task files** into this folder for unambiguous pieces (exact
anchors verified to match once, exact replacement code/data, run commands,
acceptance greps/tests, stop conditions). The parent launches Grok.

| Task | Branch / worktree | Agent | Depends on | Brief |
| --- | --- | --- | --- | --- |
| A1 Layout, lifts, walkways, access modes, rope station data | `gv2/layout` · `/private/tmp/gv2-layout` | Astra High | — | [A1](A1-layout.md) |
| A2 Rope access mechanic | `gv2/rope` · `/private/tmp/gv2-rope` | Astra High | station data contract below (not A1's code) | [A2](A2-rope.md) |
| A3 Crane: front approach through the leaves, core/backpack routes | `gv2/crane` · `/private/tmp/gv2-crane` | Astra High | A1 merged | [A3](A3-crane.md) |
| Grok tasks | as written by coordinators | Grok 4.7 High Fast | per file | — |
| Integration, central validation | `gantry-v2` | Claude | A1–A3 | — |
| Walk, rappel, assemble | — | User | integration | playtest checklist |

## Fixed contract shared by A1 and A2: `workshop.rope_stations`

A1 authors this list in `tools/author_workshop_blockout.py` (and regenerates
`assets/workshop-layout.json`); A2 reads it and must not edit the author script or
layout JSON. Values are exact.

```json
[
 {"id":"front_l_9.3",  "parent":"wing_left_20.6",  "anchor":[4.3,1.2,0.75],  "edge":"front"},
 {"id":"front_l_10.8", "parent":"wing_left_20.6",  "anchor":[5.8,1.2,0.75],  "edge":"front"},
 {"id":"front_l_11.9", "parent":"wing_left_20.6",  "anchor":[6.9,1.2,0.75],  "edge":"front"},
 {"id":"front_l_12.6", "parent":"wing_left_20.6",  "anchor":[7.6,1.2,0.75],  "edge":"front"},
 {"id":"front_r_13.4", "parent":"wing_right_20.6", "anchor":[7.6,1.2,-0.75], "edge":"front"},
 {"id":"front_r_14.1", "parent":"wing_right_20.6", "anchor":[6.9,1.2,-0.75], "edge":"front"},
 {"id":"front_r_15.2", "parent":"wing_right_20.6", "anchor":[5.8,1.2,-0.75], "edge":"front"},
 {"id":"front_r_16.7", "parent":"wing_right_20.6", "anchor":[4.3,1.2,-0.75], "edge":"front"},
 {"id":"rear_11.0",    "parent":"", "anchor":[11.0,21.8,28.3], "edge":"rear"},
 {"id":"rear_12.4",    "parent":"", "anchor":[12.4,21.8,28.3], "edge":"rear"},
 {"id":"rear_13.6",    "parent":"", "anchor":[13.6,21.8,28.3], "edge":"rear"},
 {"id":"rear_15.0",    "parent":"", "anchor":[15.0,21.8,28.3], "edge":"rear"}
]
```

`anchor` is in the parent group's local frame (wing groups sit at Y20.6, so local
Y1.2 is world Y21.8; closed left leaf world X = 5 + local X, world Z = 24 + local Z;
the right leaf is yawed 180°). Empty parent means world coordinates. Front anchors
sit 0.15 m beyond the leaf edge on short fixed davits (rope plumb at world Z24.75);
rear anchors are the tips of fixed 2.0 m booms from the exit walkway edge (Z30.3).
Each station has a 0.9 m gate opening in the robot-side guard, centred on its X.

## Shared rules

- One commit per logical step, on your branch only. Never touch `main` or another
  worktree. Merge `gantry-v2` into your branch if you need upstream changes.
- Verification: `python3 game/workshop/tools/run_regressions.py --only <touched suites> --jobs 4`.
  No `run_diagnostics.py`, no full suite, no rendered review, no automated walking
  or reach sweeps. Classify every new suite in `game/workshop/tools/test_inventory.py`.
  Retired old-room/access tests stay retired.
- Active rules from `workshop-state.md`: saves are snapshots at rest with no
  migrations (invalid saves are deleted); one workshop reached through `--stage`;
  guarded equipment motion pauses rather than refuses, with a named reason. Report
  mechanical evidence separately from player acceptance.
- Coarse tolerances: the robot parts are temporary. Use a few boxes per component
  plus about 0.5 m margin; don't build millimetre clearance campaigns.
- Controls stay physical and in sight (future AR). Reuse existing patterns (hold-E
  latch, manual control glow, HUD status) before inventing new ones.
- If you need new part icons or an editor import, stop and ask.
- End with a short report: commits, tests run with results, deviations from the
  brief with reasons, open questions, Grok task files written.
