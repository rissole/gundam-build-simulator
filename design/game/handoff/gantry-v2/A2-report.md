# A2 rope access — implementation report

2026-10-27 · worktree `/private/tmp/gv2-rope` · branch `gv2/rope`.

## Commits

- `250c4e9` — collision-resolved rope access, station gates, pull-in, saves,
  input/HUD/manual cues, leaf interlock and the classified fixture suite.
- `16d2a98` — restore validation, boarding and platform interlocks, real E/G
  input coverage, guidance checks and player controls documentation.
- This report and the linked pending player checklist are a separate documentation commit.

## Result and integration boundary

`rope_access.gd` reads all twelve `workshop.rope_stations` records; world anchors
resolve through current leaf transforms each physics tick. The branch's existing
layout has no stations, so A2 uses the exact contract as an isolated fixture.
**A1 still supplies the actual station data, davits and guard openings.** Neither
`author_workshop_blockout.py` nor `workshop-layout.json` was changed.

The new equipment registers through the ordinary factory/registry. Player motion
uses swept capsule collisions, without shared targeting or carrying exceptions.
The only registry rider change is a four-line hook excluding suspended players
from the nearby-deck rider probe. A grounded clipped rider blocks a platform trip
through the existing travel guard. Front leaf trips wait with “Recall the ropes
on the workshop-side leaves”; recall remains available during that wait and the
occupied gate stays open for return boarding.

The save loader validates rope state before restoring anything, uses the actual
attached player's pose instead of an old rider pose, and deletes invalid files.
Hanging and pulled-in state round-trip; malformed lengths, identities, player
poses and incompatible leaf state are rejected. No migration was added.

## Verification

All verification used the routine runner with named cases and `--jobs 4`.

| Suite | Latest result |
| --- | --- |
| `rope_access_test` | PASS, 61 checks |
| `save_roundtrip_test` | PASS, 29 checks |
| `workshop_smoke_test` | PASS, 32 checks |
| `equipment_motion_test` | PASS, 83 checks |
| `manual_control_guidance_test` | PASS, 40 checks |

The five-case run passed in 15.478 s:
`game/workshop/verification/regressions-20261027T091829.739598Z/`.
After focused rope-only refinements, the final 61-check rope run passed in 3.214 s:
`game/workshop/verification/regressions-20261027T092306.256554Z/`.
Logs are local ignored evidence. `git diff --check` passed.

Earlier fixture failures found a recall deadlock, collision sliding beyond the
slack envelope/under a landing, and front deck/capsule clearance. They were
corrected before the passing runs. Expected warnings from deliberately invalid
save files are deletion checks, not unexplained engine errors.

No full suite, diagnostics, automated walking/reach sweeps or rendered review ran.
These are mechanical checks; presentation and player acceptance remain open in the
[focused playtest checklist](../../robot-workshop-playtest-checklist.md#gantry-v2-rope-access--pending-player-checks-2026-10-27).

## Decisions and deviations

- **G** is the dedicated rope/lanyard key because F already resets a rig. This is
  the unused-key choice requested by the brief; Space/Ctrl and E retain the specified roles.
- At the **top boarding height only**, a narrow collision-resolved corridor
  reaches the rear walkway from its fixed boom tip, 2 m away. This is an explicit
  exception to the ordinary 0.35 m hanging slack limit: without it the given rear
  station cannot be boarded or left. Below the top, slack remains bounded; idle
  suspended boarding motion draws toward plumb. A 0.14 m outward bias within the
  slack allowance clears the front deck's edge with the 0.26 m-radius capsule.
- The normal save loader only checked machine field names, so a narrow rope
  validator hook was necessary to satisfy invalid-snapshot rejection before apply.
- No stop condition required broader targeting or rider-carry changes. No part
  icons, asset generation, Grok files or Grok execution were needed.

## Open items

Parent session: integrate A1/A2/A3 into `gantry-v2` and run central validation;
keep off `main` until the user approves. Reconcile the small factory/access hooks
with A1's changes. This branch makes no claim about integrated crane/rope clearance.

User: playtest station readability, top boarding, rope work, saving and the actual
upper connections. The backpack hinge remains deliberately unresolved. No new
question blocks this handoff. **Grok task files written: none.**
