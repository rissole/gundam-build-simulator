# Supported left-leg milestone

Structural blockout implemented and verified headlessly 2026-10-22. The first
player feedback on 2026-10-23 identifies unresolved controls, handling affordances
and visible transport issues. The historical checks below establish mechanical
behavior; they do not establish acceptance of the workshop experience.

Continue from [playtest feedback and next steps](leg-workshop-next-steps.md).
The upright-hoist workflow described below was retired during the 2026-10-23
architecture consolidation. Default launch now selects the foot base game;
M2 uses separate rail/crane trial profiles. This document retains the historical
milestone and its evidence. The
[pre-consolidation continuation snapshot](history/workshop-pre-consolidation-state-20261023.md)
preserves the later feedback and handoff details.
The next iteration should establish a coherent equipment interaction and visible
handling loop before expanding construction detail. Detailed production assets
remain deferred.

The user approved a larger workshop containing the existing component workshop,
a supported structural-leg assembly area, an open transfer corridor, and a final
bay with a pelvis-supporting gantry, hoist, and player access equipment. The final
journey includes construction, transfer, hip retention, supported removal, undo,
and save/resume. Starting with an assembled pelvis and socket housings is a new
prototype choice, not an earlier confirmed opening sequence.

## Implementation checks recorded 2026-10-22

| Requirement | Evidence | Current state |
| --- | --- | --- |
| Expanded walkable workshop | `leg_workshop_test.gd`, `leg_controls_test.gd`, `access_lift_test.gd`: actual room, walking, buttons and occupied lifts | Passed |
| Existing foot gameplay preserved | Original foot/model/manual/desktop suites; separate `--foot-workshop` profile | Passed |
| Structural left-leg construction | `leg_content_test.gd`, `leg_build_test.gd`: interfaces, stock, manual pages and normal desktop installation | Passed |
| Supported movement | `leg_equipment_test.gd`: fixture pickup, collision-checked transfer, approach and seating | Passed |
| Hip retention | Both halves, all washers/bolts, ordinary reach and visible targets from the hip deck | Passed |
| Load release and removal | Equipment interlocks, stabilization, reacquiring support, full return and dismantling | Passed |
| Save/resume | `leg_save_test.gd`: interrupted equipment/lift motion, nested attachments, partial retention and separate profile | Passed |
| Inventory/ownership | Supported model/content/runtime suites: 175 unique identities, compatible swaps, prerequisites and nested transforms | Passed |
| Future space | Marked torso/second-leg floor reserve and unused second socket; no playable extra builds | Implemented |

## Working layout

Godot units are metres, Y up, robot forward -Z. The expanded hangar has usable
limits X -13.8…25.8, Z -8.5…38.5, roof underside Y22. The existing foot and small
preparation stations retain their locations. The leg fixture's ground reference
is (2.3, 0.75, 14.4). The pelvis frame reference is (13, 10.6, 26), with hip centers
at X ±1.1 locally. The 10.6 m installation height provides 1.4 m above the standing
robot's 9.2 m hip height; the approach leg sole is 0.5 m above the floor. Its ball
crown is 10.15 m high, clearing the socket skirt's 10.25 m underside before
upward insertion. The earlier 0.8 m sole height intersected that skirt. These are
selected prototype dimensions; the integration suites check actual movement and
access within this blockout.

The overhead crane is separate from the robot-supporting gantry. The gantry holds
the pelvis throughout the milestone. A separate service bridge handles the foot,
structural pieces and retaining halves while the main hoist can keep holding the
leg. The foot carrier stays at dispatch; the service hoist lifts the foot through
the front aisle into the leg fixture. Whole-leg movement exits toward Z10.2 before
crossing to the final bay, leaving the fixed rear fixture crossbars solid.
Retracting heel pads support the foot before the shin exists; shaft jaws support
the later leg. Their contact positions and release behavior are measured against
the actual part geometry. Ground-anchored guide masts carry the personnel decks.

Two leg-side personnel lifts serve opposite sides of the knee, with deck stops
at 0.15, 1.2, 3.8, 5.2 and 8.7 m. The final hip lift has stops at 0.15 and 8.4 m.
The ankle stop exposes the flange hardware and main disconnect; the opposing
knee positions provide real axle insertion and cap access. Temporary
fixture/transport restraints and a
gantry leg stabilizer retain the unpowered knee, ankle and spherical hip. They are
equipment, not extra robot inventory or proof of an operational powered leg.

The first scenario exposes the existing foot branch plus structural shin,
knee/fork and integral-ball thigh assembly. Detailed powered actuators, thrusters,
armor, waist and torso branches remain outside this prototype's playable scope.
The milestone must be described as structural readiness rather than operational
robot completion. Refer to the companion interface specification for geometry,
part ownership, selected dimensions, supplies and page dependencies.

## Asset and gameplay scope

The component-pipeline and assembly-review skills guided the parts/interface
specification, ownership, recipe/manual dependencies, source geometry pairing and
behavior audits. The new pieces are procedural Godot blockouts with separate
physical identities and actual receiving holes, bearing seats and split rings.
They have not completed the full exploded-reference and detailed Blender asset
stages used for the foot. The existing foot GLB is unchanged by this expansion.

Normal launch selects this scenario. `./play.command -- --foot-workshop` opens
the previous foot-only workshop. The new `user://leg-workshop-save.json` and old
`user://workshop-save.json` profiles are separate; no migration or reset of the
earlier save is required.

## Verification policy

Use headless authored-data, geometry, equipment, ordinary interaction, normal
application launch and persistence checks. Preserve existing working files and save profiles. Rendered
assembly review was not requested and is not a completion prerequisite; do not
claim visual approval. Human assessment of scale and handling remains distinct
from automated behavior evidence.

## Final verification

`python3 game/workshop/tools/run_regressions.py` passed **38 cases / 4,539
checks**, including both normal application launches. The final run retained
logs and SHA-256 hashes for 140 input files; inputs remained unchanged throughout.
The local [results report](../../game/workshop/verification/regressions-20261022T124455.194604Z/results.json)
records each command, result and log. `git diff --check` also passed.

The new desktop build audit passed 539 checks across all 35 hand/pocket
installations, including ordinary carrying of all seven hand pieces and occupied
lift travel. Equipment controls passed 296 checks through actual targeting and
E input. Equipment lifecycle/contact checks passed 320, lift checks passed 30,
leg persistence passed 318, and the focused content suite passed 373. The
authoring generator reproduced all 18 generated JSON/SVG files byte for byte.

These results cover the selected structural prototype. They do not claim
rendered approval, engineering load analysis, production-ready assets or a human
assessment of the expanded workshop's pacing and comfort.
