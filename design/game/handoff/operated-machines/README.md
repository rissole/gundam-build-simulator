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
| `gantry-v2-plan` | `/private/tmp/gbs-gantry-v2` | [C5 — v2 dimensioned plan](C5-v2-dimensioned-plan.md) | Design only; anytime |

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
| C0 — user names the asymmetric gantry spot | Answered 2026-10-27: lowest level beside the hip; C3 authorized and repaired below |
| C — v2 concept approval | Direction approved 2026-10-27; build not approved, waiting for crane operator view and less temporary parts |

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

### C4 direction status and phase completion

Changed the launch cage section status to **approved as direction 2026-10-27;
build not approved**. Construction waits for the crane operator view and less
temporary robot parts. Updated the checkpoint and player-finding records to keep
that distinction explicit; no v2 construction is included.

Task commits on `gantry-access`: `15154c6` (C2 review), `7d2ea40` (C3 mirror
repair), followed by the C4 documentation commit containing this final report.
All three task commits carry the requested Codex co-author trailer. The final
code/layout verification is the four-suite 9.359 s pass above; C4 changes only
documentation, checked with `git diff --check`. No extra suite was touched or
created. Open items: player recheck of C2/C3 and separate future v2 build approval.
No new Grok task files were written in phase 2; [C2](C2-fill-plates.md) remains
the reviewed phase 1 specification. No work on another branch or worktree.

## C5 report — 2026-10-27

**Design complete at the specified conflict stop; candidate blocked, build not
approved.** [Dimensioned plan](../../gantry-v2/README.md),
[plan source](../../gantry-v2/plan.json),
[measured envelopes](../../gantry-v2/envelopes.json), and
[lowest-level drawing](../../gantry-v2/drawings/level-8.4.svg).
All work is on `gantry-v2-plan`; no other branch/worktree was edited.

### Commits and scope

- `856d4f9` — probe and measured/provisional envelopes.
- `01b5023` — candidate plan, stdlib checker, numeric source register and drawings.
- Records commit: this commit, **Record C5 dimensioned-plan conflict checkpoint**,
  linking the plan from the concept, state document table and playtest checklist
  and adding this report. Its hash is supplied in the coordinator's final reply.

Each commit ends with `Co-Authored-By: Codex <noreply@openai.com>`.
No game code, layout JSON, generator, game test or test-inventory changes.
No Grok task files were written: unresolved geometry and lack of build approval
preclude exact construction edits. Section 8 of the plan assigns Astra judgment/
integration and future Grok edits after exact anchors can be specified.

### Checker and drawing result

`python3 design/game/gantry-v2/check.py` returns **FAIL, exit 1**: all 39 states
have below-margin comparisons. It records **5,106,010** member/reservation/state
pairs, all 310 solids/10 mirrored motions, **32/32 passing seams** and **92/122
passing analytical walking-width/support/headroom cases**. Four support
root/handle solids escape their proposed parking pockets. Negative box overlaps
are conservative conflict evidence, not proof of physical mesh penetration.
No datum, route or reserved volume was moved to make the checker pass.

The five tightest positive clearances (all below the 0.100 m required margin):

| Proposed solid | Reserved envelope | Clearance m | State / phase |
| --- | --- | ---: | --- |
| `L_gantry_jaw_11.6_26.55_handle` | `crane/left_arm/approach/6` | 0.003208 | `delivery/left_arm` / docked |
| `R_gantry_jaw_11.6_26.55_handle` | `crane/right_arm/approach/6` | 0.003208 | `delivery/right_arm` / docked |
| `L_arm_11.2_fore_post1` | `robot/chest` | 0.010000 | `delivery/left_arm` / swing |
| `L_arm_11.2_aft_post1` | `robot/chest` | 0.010000 | `delivery/left_arm` / swing |
| `R_arm_11.2_fore_post1` | `robot/chest` | 0.010000 | `delivery/left_arm` / swing |

Crane constraints in that table and throughout the plan are **provisional
(unmerged branch)**, read using `git show crane-operator-view:<path>` at
`b937decaf64c05e3229cfa148e40313b92b95148`. No checkout or edit of that branch.
The final rig measurements include the cassette's retained arm, core bridge,
adapter spreaders/hooks, magnetic connectors and cables. They are not a
branch-A workshop boot or player acceptance.

`python3 design/game/gantry-v2/draw.py` generated 76 SVGs: seven overview sheets
and 69 enlarged tight-dimension sheets, covering 818 positive tight pairs. Every
SVG parses and is below 300 KB (largest 151,492 bytes). Plan sheets include all
their tight-gap dimensions and links to spatial details. Hash consistency,
reflection (including fore/aft guards), retirement IDs and intentional mutation
checks for mirrors, seam width and walking width were checked. Intermediate
swing bounds were checked independently. `git diff --check` passes; an initial
CSV CRLF whitespace failure was corrected in the drawing exporter.
Full pair/report evidence remains in ignored `game/workshop/verification/c5/`.

### Probe runs and outcomes

One authorized fresh-worktree editor import completed. The final headless probe
reached **foot → actuator → pelvis → left_leg_build → left_leg_dock →
right_leg_build → right_leg_dock → chest → core → backpack → left_arm →
right_arm → pauldrons → head → head_sensors → complete**, checking the supplied
stage contract at each boundary. It measured 158 installed component/stage
bounds, 321 equipment samples and 31 provisional crane tasks, then collected 278
reservations. Both loaded leg paths have 61 supplied poses; backpack has 41;
lifts cover every authored stop and individual moving/fixed shapes; all mobile
routes derive from measured platform geometry and unchanged route data. The
actual continuous rear wall is included in the door collision measurement.

Final probe window: **2026-10-26T20:44:35Z–2026-10-26T20:45:05Z**,
27 October Sydney, Godot 4.7.2. All 16 boundaries passed; no script/engine errors.
Existing image-file export warnings remain. Earlier scratch iterations were
invalidated or superseded while correcting probe-only cradle record keys,
component grouping, branch-adapter binding and shape classification. Their
outputs are not acceptance evidence. The core removal rails/crossframes have
no runtime implementation, so their absence and conceptual datums are recorded
explicitly instead of inventing measurements.

No regression suite, diagnostic, rendered review or automated walking/reach
sweep ran. The analytical design checker is not a player trajectory simulation
and was not added to the game test inventory.

### Conflicts and stop

- **C5-01:** parked catwalks, roots and fixed inner landings occupy the exit;
  parked guards obstruct return paths. Recommend studying retracting roots/
  landings with folds, preserving the robot and exit reservation.
- **C5-02:** hip cantilevers/retention overlap conservative robot/leg envelopes;
  unloaded supports also exceed pocket/exit bounds. Refine actual contact/void
  geometry and loaded/unloaded load paths together at the existing cap patches.
- **C5-03:** visible door clear width is 20.10 m, not the concept's21.50 m outside
  frame span. The rear wall has **no collision aperture**; door/lowering/carrier
  work remains deferred.
- **C5-04:** core service rails/two crossframes are unimplemented; removing aft
  decks removes intended support. Specify removable support at unchanged pad
  datums before claiming core removal/service.
- **C5-05:** upper pivot leaves 1.80 m headroom rather than 2.20; rear work patches
  do not prove front fastening access. Arm-mouth guards and park-lock geometry
  remain design decisions.
- **C5-06:** branch A's provisional head-height rule puts chest bottom at 17.410,
  meeting 17.80 tower tops in the free-strafe reservation. Do not invent a bypass;
  reconcile crane operating space before fixing tower heights/parking.
- **C5-07:** existing lift guides use the same diagonal, not reflected diagonals;
  the mirrored hip landing meets the right guide, and new guard runs meet call
  boxes. Preserve hardware/doors and redesign candidate cutouts/guards.
- **C5-08:** measured backpack sweep Z30.086/Y16.490 differs from the concept's
  Z30.173 plus 30.3/16.6 allowance. Use measured bounds with interpolation margin;
  keep the service opening unchanged.

No construction follows this report. The candidate demonstrates unresolved fit;
it does not prove every possible two-tower topology impossible.

### Recommended slice and open user questions

Recommend **one mirrored Y8.4 level plus the independent hip support handoff**,
the user's named problem location, only after the relevant conflicts and separate
build approval. Section 8 defines exact scope, source files, manual/support audit,
focused existing routine suites and agent assignments. No upper expansion, core
removal kit, lowering, carrier or door implementation belongs in that slice.

Open questions: investigate retracting roots/landings and supports while keeping
all datums fixed; confirm Y8.4 as the eventual first slice after branch A and
less temporary parts; determine essential front/side work patches and physical
park guards/controls in play; retain the separate deferral of core removal,
door, lowering and transport. The recommendation is recorded, not presumed
approval. Existing positive appearance/assembly-challenge findings and the
C2/C3 player recheck remain in the linked playtest record.
