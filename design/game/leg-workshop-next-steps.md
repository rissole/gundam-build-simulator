# Workshop: active plan and playtest state

Updated 2026-10-23. Read this before continuing workshop development. The default
base game is the supported-foot workshop: two heel pads and the pitch actuator.
The upright-hoist workshop and isolated M1 trial are retired. The M-series is a
prototype lane using profiles on reusable equipment, layout, assembly and save
modules; it is intended to fold back into the base game later.

## Current work: architecture consolidation before M3

The continuation request is to verify the Cursor consolidation plan and finish
its remaining architecture, test and documentation work without changing gameplay.
The first verification found phase 4 partially implemented despite its completed
status: the layout still had runtime/Python literals, overlays copied whole
recipes, crane security used a prefix/count, and trial saves skipped common
world validation. These gaps have been repaired and the integrated regression gate passed.
The user accepted the M2 replay on 2026-10-23. The default-foot preservation
replay is still unconfirmed; it does not block the requested commit.
The local Cursor plan is
`/Users/blakeyboy/.cursor/plans/workshop_architecture_consolidation_aa30c8a8.plan.md`.

| Work | State |
| --- | --- |
| Default foot profile; retire hoist/M1; shared profile/equipment modules | Implemented; preservation review passed |
| Phase 4: authoritative layout data, recipe patches, unified validated saves | Complete; integrated gate passed |
| Phase 5: shared test kit and one regression runner including source assets | Complete; integrated gate passed |
| Phase 6: generic foot component projection; remove runtime pad cursors; cached materials | Complete; integrated gate passed |
| Phase 7: active/history split and current launch/module docs | Implemented |
| Independent preservation review | Fresh final review found no actionable preservation defects |
| Human replay of default foot and both M2 trials | M2 accepted, 2026-10-23; default-foot replay unconfirmed |

Every phase must preserve the recorded foot fingerprint and load the captured
pre-consolidation save into a fresh scene. Old M2 trial saves may require an
explicit Reset. Existing incompatible saves must remain protected. Headless
checks establish bounded behavior; presentation and player acceptance are
separate evidence. No rendered review has been requested for consolidation.

## Consolidation verification — 2026-10-23

The final [regression report](../../game/workshop/verification/regressions-20261023T114809.356593Z/results.json) passed
**52 cases / 4,309 Godot checks**, plus **11 Python tests** and **96** malformed
equipment-field attacks, with unchanged input hashes. It includes all five
canonical profiles, launch aliases, both M2 ordinary-control journeys and saves,
single/two-pad and pitch construction, source geometry, mounted rotation, undo,
common-world snapshot rejection and shifted-layout authority checks. The
[baseline report](../../game/workshop/verification/regressions-20261023T112919.316152Z/results.json)
passed 46 cases / 4,289 checks before repairs. Generator `--check` reproduced all
base/trial JSON and catalogue assets; `git diff --check` passed.

The captured pre-consolidation foot save loads in a fresh scene with fingerprint
`8c6c1c21c92c0bdf24d45f655606de580816d1f6ccb3806ebbe35e09d37b9293`.
Foot/pitch scenario and definition files and the source GLB remain byte-identical.
The unified session codec keeps the existing `workshop_save.gd` filename.
`HeelAssemblyState` remains only as a standalone compatibility view for historical
tests; production uses explicit owners and generic component projection.

A fresh independent preservation review found no actionable defects. The primary
reviewed the final feedback/driver repairs and the complete frozen-input run.
The newly integrated Python authoring check tolerates float-only roundoff within
1e-12 (observed maximum 4.44e-16); identity/structure and GLB byte checks remain
exact. No protected foot assets were regenerated. No rendered review was requested
or performed. Automated verification and the M2 human acceptance below are
separate evidence; M3 still requires explicit go-ahead.

### Crane console UI revision — 2026-10-24

The user subsequently reported that the crane controls fill the screen and
initially authorized a compact panel attached visually to the physical console,
like the existing E-to-pick-up prompts. During implementation they changed the
placement to the center of the screen and requested no acceptance run, reserving
verification for manual play. They selected a fixed view while operating it.
This local UI change is separate from the final-gantry design and M4.

The implementation replaces the opaque backdrop with a transparent input shield
and a centered 340 px control panel. It stays within viewport margins and scrolls
commands on short screens.
Current load, crane status, feedback and Close remain visible. Mouse buttons and
↑/↓ with E/Enter operate commands; Q/Close returns to play, and Esc pauses.
Walking/look remain captured, outside clicks stay isolated and the ordinary
interaction prompt is hidden. Crane mechanics, support rules and saves are
unchanged. Before the centering revision, the panel/input and three focused crane
suites passed 363 headless checks. The in-progress full M3 acceptance run was
interrupted at the user's request; it is not completed acceptance evidence.
No acceptance run or rendered review was performed for the final centered layout.
Verification and player readability remain awaiting the user's manual playtest.


## Player feedback and constraints to retain

| Feedback / positive finding | Current direction and unresolved question |
| --- | --- |
| Overlapping, intricate leg-area controls and labels were hard to use | Local tactile rail/lift controls; evaluate grouping, labels and explanations in ordinary play. Targetability alone does not establish readability. |
| Final-bay task buttons had the same clutter | Crane tasks use a central physical console; retain local rail/lift operation. |
| Final-bay lift scale and onboard ascent were close to the intended experience | Preserve boarding, travel, reach and scale. Primitive art is not the accepted visual target. Rails/elevators were praised at corrected M1 acceptance. |
| Large components appeared to float; transport/support was unclear | Horizontal leg rail, visible holder contact and individually attached crane magnets must explain support through collection, travel, seating, fastening and release. |
| PV-120 halves looked collectible but were static | Ordinary two-hand carrying and a finite lift shelf replace the rejected positioning arm. Small hardware stays in pockets. |
| Initial M2 crane delivery and magnetic attachment broadly worked | Fullscreen Up/Down/Go to console now captures mouse/look; keyboard arrows + E and Q close. Held magnets are centered. M2 replay accepted, 2026-10-23; no new detailed issues reported. |
| Crane controls fill the screen; initially requested positioning like pickup prompts, then selected the center of the screen | Implemented compact centered controls with a fixed view and visible workshop. Acceptance run stopped at the user's request; final layout awaits their manual verification. |

The console's fullscreen backdrop was deliberately unchanged during consolidation;
the user accepted that M2 replay before requesting the UI revision above. The shelf holds two one-hand
components or one two-hand component, on the side opposite the hip working
corner. Keep the accepted boarding and hip approach clear. Source and receiver
support must remain distinct from fastening; decorative cables cannot replace
real supported transfer. Retention blocks Return, and the holder remains engaged
until a complete ring is secured. Do not reintroduce the extra external
capture/stabilizer command rejected in the M1 correction.

## Human checkpoints and authorization

The user accepted corrected M1 on 2026-10-23: “Yep looks good - plan next
milestone.” M2 was authorized, implemented, playtested and revised. Its most
recent feedback pass explicitly requested no subagents; that restriction applied
to that completed pass. Current repository instructions authorize bounded
parallel work. Architecture consolidation does not authorize M3 gameplay.

| Checkpoint | Player journey / acceptance question | Status / work held |
| --- | --- | --- |
| M1 layout and scale | Understand rail-to-robot support; walk routes and board/ride the lift | Corrected layout accepted, 2026-10-23; trial now retired, accepted geometry retained in M2 |
| M2 equipment interactions | Rig/deliver/fasten the Upper-leg beam; carry one retaining half via shelf, fit/undo/return it; judge console, walks, magnets and tactile controls | Human-accepted, 2026-10-23: “m2 plays great.” M3 remains held for explicit go-ahead. |
| M3 complete leg-to-robot journey | Follow construction/manual through crane delivery, rail travel/tilt/upward docking, both halves, release/reacquire and interrupted save/resume | Not started; requires explicit go-ahead after M2 feedback |
| M4 expanded workshop acceptance | Complete the combined scenario, revisit clutter/support/retention/lift issues, save/resume across workstations | Not started; requires earlier checkpoints and explicit acceptance |

At each checkpoint finish the coherent implementation and relevant checks, stop
all later-wave work, then present the runnable result and wait for feedback and
explicit go-ahead. A test pass or elapsed time never supplies that acceptance.
Keep mechanical checks, inspected presentation and human responses distinct.

### M2 replay acceptance — 2026-10-23

After the consolidation handoff, the user said “m2 plays great. please commit.”
This accepts the current M2 equipment checkpoint and authorizes committing the
verified consolidation. No new M2 issues were reported. Preserve the accepted
crane console/magnet and two-hand carrying/lift-shelf flows. The user did not
confirm replaying the default foot profile or authorize M3 implementation.

## Short preservation replay

Launch commands and controls are maintained in the
[workshop README](../../game/workshop/README.md). Use these routes after the
architecture gates pass:

1. `./play.command`: resume the existing foot save or start fresh; collect stock,
   carry/suspend a heel pad, fit sleeves, seat and fasten it, switch manuals,
   undo/reinstall, operate the supported foot and save/reopen.
2. `./play.command -- --m2-workshop`: choose **Reset Hip retainer** if its old save
   is incompatible. Advance the supplied leg through travel, tilt and docking.
   Pocket both washer/bolt pairs, carry the half onto the lift, click the shelf,
   ride Up, retrieve/seat/fasten it, then Z-undo it to hands, shelf it and return
   Ground. Return must remain blocked while retention is fitted.
3. From the selector choose **Reset Crane delivery** if needed. At the console:
   Go to Upper-leg beam rack, Down, Q. Walk to the rack, E-pick each magnetic end
   and aim/click a marked point. Return: Up, Go to Leg cradle, Down. Fit four
   ordinary washer/bolt pairs, detach/stow both ends and park the empty crane.
   Before fastening, test loaded return to the source. Pause/save/reopen partway.

Foot progress uses its existing slot; the two M2 slots are independent. Choosing
an example saves the current example first. Reset replaces only the named trial.
M2 supplies unrelated completed construction: one complete leg for retention,
and a complete foot plus pre-beam leg for the crane. It contains one retaining
half and one crane load; complete-ring security, holder departure and released
beam disassembly are outside M2.

Assess whether console selection and messages are clear, magnets feel natural
to aim, and carrying/shelving/fastening feels comfortable at both lift stops.
Record the user's response here with date and remaining issues.

## Deferred design and evidence

The [full pre-consolidation continuation snapshot](history/workshop-pre-consolidation-state-20261023.md)
retains every earlier feedback item, proposed implementation sequence, acceptance
matrix, M2 routes and historical check report. Earlier team handoffs and the
delivery retrospective remain in
[the M1/M2 archive](history/leg-workshop-m1-m2-handoffs.md). The
[structural milestone](leg-milestone.md) and
[interface specification](leg-prototype-interface.md) describe the historical
implemented subset; their headless passes do not approve the current UX.

Future work must resolve the foot-to-horizontal-rail handoff, construction-face
access, pivot/travel geometry, empty-holder return and one-station reuse versus
separate left/right tracks. Reserve a second-leg path without adding playable
right-leg content. Pelvis construction/gantry mounting, torso module boundaries,
arm rigging and lift access, head/neck sequence, backpack/core rear clearance and
connection covers remain design questions. Most components build at workstations;
final-bay lift work concentrates on retention, services and connection closures.
Keep the existing head-on-neck sequence. A later PDA may reduce console walks;
its acquisition/progression rules remain open. Full loose-chain/swing physics,
detailed Blender leg assets, powered mechanisms, armor, additional robot branches
and AR are outside this consolidation.

When M3 is authorized, first prove one ordinary-control journey before expanding
content. Audit affected manual slots/inventory, actual geometry and mounted
motion; exercise blocked/reverse paths and fresh-scene interrupted restores.
Preserve canonical geometry separately from interchangeable consumed identities.
Rendered review still requires an explicit request.
