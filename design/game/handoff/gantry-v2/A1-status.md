# A1 complete — 2026-10-27

**Ready for parent review/integration.** All work is committed on `gv2/layout`
in `/private/tmp/gv2-layout`; no merge or other worktree/branch changes. Parent
orchestration is Codex. A2 rope behavior and A3 crane routing remain separate.
The earlier asset-import stop is resolved by the user's continuation authorization
and the import already performed in this worktree. No new part icons were needed.

## Commits

- `6ce4c0b`: initial authored layout, station contract, access modes, lift doors.
- `c5f38a4`: initial fixture edits and import-blocked checkpoint (superseded here).
- `4963e00`: completed geometry/guide repairs and new routine layout coverage.
- `06883e8`: stage preparation and diagnostic fixture updates.
- The final documentation commit records this report and permanent player checks.

## Result and implementation choices

- Only 8.4 and 20.6 access levels remain. Upper leaves share the existing X5/X21,
  Z24 axles; square 0.24 m posts end at Y22.3. Deck notches clear the post's
  circumscribed circle at every swing angle. Upper leaves have no fingers.
- New upper leaves, guarded aprons, rear walkway, fixed booms, davits and their
  jamb supports retain the accepted gantry finish. All twelve station records
  match the shared contract and resolve to its closed world anchors.
- Lifts are at (1.9,24.05) and (19.6,31), with stops 0.15/8.4/20.6. Left doors
  face east throughout; right doors face east at ground/8.4 and west at 20.6.
  Exactly one landing call is supplied per stop. Cars remain open-topped.
- Fixed guides end at 20.2. A short sliding mast connects each guide carriage to
  the car: during the final 0.6 m, the carriage stops on its guide and the car's
  sleeve rises along the mast. Both shoes engage at every stop; no ground-floor
  penetration or raised roof/gear. The right guide pair is on the west side,
  since the east shaft band overlaps the retained outer walkway. Moving hardware
  clears the complete fixed blockout through its full vertical travel.
- Fixed 1.5 m hip links replace the access path formerly supplied by the old
  shafts. Left link Z28.5..30; right Z27.6..29.1 clears the new right shaft.
  The low hip frame is identical to pre-A1: 37 solids and four jaw groups.
- Left hinge landings extend 0.1 m fore/aft for the 1.5 m doorway. Their fixed
  thresholds stop 20 mm short of the car. The right lower car face is X20.9
  and retained walk begins at X21: an 0.08 m plate closes that actual gap to
  20 mm, without overlapping the outer deck. No accepted station was moved.
- West rear-walk post is X5.24, rather than near X4.8, to clear the lower walk
  and its inner guard. East support posts/header sit at X17.9, alongside the
  right lift, and end at Y20.2; a short bracket supports the deck underside.
- Front station openings only 0.7 m apart necessarily share a guard cutout.
  Every individual 0.9 m opening is clear. A2 must preserve its unclipped-player
  barriers over the overlapping openings; A1 supplies no gate mechanics.
- Lower outer-walk sliding gates are preserved. Upper aprons use fixed end
  guards because there is no upper outer walk. The obsolete 11.2-only
  `arm_services_stowed` flag/callback and snapshot field are removed. Old
  snapshots are rejected, with no migration. Core/backpack modes are ready for A3.

## Verification

Final command (all PASS, unchanged inputs, no 60-second warning):

```sh
python3 game/workshop/tools/run_regressions.py --only gantry_layout_test wide_elevators_test gantry_dressing_test access_lift_test equipment_motion_test rail_endpoint_test save_roundtrip_test workshop_smoke_test stage_contract_test shelf_storage_test shoulder_content_test --jobs 4
```

| Suite | Checks |
| --- | ---: |
| gantry_layout_test | 152 |
| gantry_dressing_test | 132 |
| wide_elevators_test | 65 |
| access_lift_test | 45 |
| equipment_motion_test | 83 |
| rail_endpoint_test | 6 |
| save_roundtrip_test | 29 |
| workshop_smoke_test | 31 |
| stage_contract_test | 12 |
| shelf_storage_test | 140 |
| shoulder_content_test | 33 |
| **Total** | **728** |

Wall time **19.307 s**. Local runner evidence:
`game/workshop/verification/regressions-20261027T093606.683672Z/`.
`author_workshop_blockout.py --check` passes with **591 solids / 79 frames** and
byte-identical generated JSON. `git diff --check` passes.

The new isolated routine covers exact station anchors, guard apertures, shared
axles and complete-angle post clearance, exit walkway/booms, upper height budget,
coarse grown robot boxes, open-leaf/floor-equipment envelopes, lift positions and
per-stop doors/calls, guide engagement, hardware travel and access snapshot modes.
Earlier failing checkpoint tests identified and drove repairs to the right hip
link, guide placement, and two floating-point comparisons; they are superseded
by the final passing run, not counted as acceptance.

Diagnostic fixture audit: removed the obsolete arm service-stow write, changed
pauldron shelf delivery to the new top stop, replaced the removed 16.4-floor
notch checks with 20.6 overhead-floor checks. Stage preparation now selects the
configured final stop rather than hard-coding `stop4`. Diagnostics were **edited
only, not run**. No rendered, automated walking/reach/visibility review or new
player acceptance. Existing generic rider/nudge and loose/shelf cargo tests pass.

## Remaining integration/player work

No unresolved A1 implementation blocker. Parent owns central validation and
integration with A2/A3. In particular, verify A2's overlapping gate barriers and
leaf/rope interlock against these exact anchors and jamb-supported davits.
The rope mechanic, front crane routes, backpack work challenge and eventual
lowering/exit remain outside A1. Human checks are preserved in the
[gantry v2 player recheck](../../robot-workshop-playtest-checklist.md#gantry-v2-rope-access--2026-10-27).
Permanent layout decisions and mechanical scope are recorded in
[overhead access](../../gantry-v2/overhead-access.md#implemented-a1-layout--2026-10-27).

**Grok briefs:** none written; Grok was not run.
