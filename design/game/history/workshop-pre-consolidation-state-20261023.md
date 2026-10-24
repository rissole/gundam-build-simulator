# Workshop continuation state before consolidation completion

Historical snapshot, retained in full on 2026-10-23. Resume from
[the active continuation note](../leg-workshop-next-steps.md). Statements about
launches, completed consolidation or verification below describe that earlier
state; they do not override the active note.

Updated 2026-10-23. This is the current continuation note for the expanded
workshop. The [milestone record](../leg-milestone.md) and
[interface specification](../leg-prototype-interface.md) describe the implemented
structural subset and its historical verification. Superseded M1/M2 handoffs,
the earlier delivery-team assignments and the delivery retrospective are archived
in [history/leg-workshop-m1-m2-handoffs.md](leg-workshop-m1-m2-handoffs.md).

## Architecture consolidation — 2026-10-23

Before M3, the workshop was consolidated without intended gameplay changes.
Default `./play.command` now opens the foot workshop (pads plus pitch actuator),
the only base game. The upright-hoist leg workshop and the M1 trial are retired.
M2 trials run as scenario profiles on shared feature modules (leg bay layout,
leg rail, equipment registry, hand slot, motion sweep, session codec) rather
than `m1_*`/`m2_*` classes. The intent is that the M-series prototypes are later
folded back into the base game by changing profiles, not by rewriting them.
Foot saves keep their recorded fingerprint. Old M2 trial saves may need Reset.
Headless regressions cover this, but the human replay of the foot default and
both M2 trials is still outstanding.

## Current state

The structural leg, supported transfers, hip retention, removal and save/resume
are implemented. The 2026-10-22 headless run passed 38 cases / 4,539 checks. Those
results establish bounded mechanical behavior, not acceptance of the player
experience. The new parts remain procedural Godot blockouts; detailed Blender
assets, powered leg mechanisms, armor and further robot branches are deferred.

The corrected M1 layout/scale trial is now human-accepted: on 2026-10-23 the user
said “Yep looks good - plan next milestone.” Rails and elevators remain positive
constraints. The user subsequently authorized “OK implement and verify M2.” M2
initial implementation was playtested. The current M2 feedback revision below
replaces the console interaction and retaining carrier with modal crane controls
and ordinary two-hand carrying plus a lift shelf. This revision awaits another
human playtest; M3 remains unstarted and requires explicit go-ahead.

The user supplied the feedback below after an initial, incomplete playthrough.
It was explicitly deferred for a subsequent prototype iteration. The follow-up
authorized recording this state and improving skills/instructions; it did not
start the gameplay redesign.

The subsequent 2026-10-23 design interview established the direction below.
This file is the single active continuation plan, combining the original
feedback, agreed direction, remaining questions and proposed implementation
sequence. The execution team (now archived) and checks below were developed
through three read-only subagent planning reviews. M1 implementation began on 2026-10-23;
later checkpoints remain held for explicit human go-ahead. Confirmed gameplay choices are
also recorded in [GAME_DESIGN.md](../../../GAME_DESIGN.md#final-assembly-workflow).

## Player feedback to carry forward

| Item | Observation | Next-iteration concern |
| --- | --- | --- |
| Leg-area controls | A messy, overlapping cluster of 14 buttons beside the knee lift. Procedures are intricate and specific to individual parts; labels overlap and are difficult to read. The interaction is not functional or engaging. | Use local tactile station buttons for leg machinery; resolve grouping, readable labels and feedback without exposing every internal operation. |
| Final-bay controls | The seven buttons near final assembly have similar problems. | Separate crane tasks at the central console from local rail/lift operation; remove the overlapping task-button clusters. |
| Final assembly lift | Very close to what the user imagined; a positive result. | Preserve the scale, satisfying onboard operation and physical ascent alongside the robot. Its primitive appearance is not the accepted visual target. |
| Large-part support and transport | Leg pieces appear to float. The user cannot see or understand geometry, rails or cranes that would move them into the leg assembly area and then to the final gantry. This breaks immersion and omits an important part of the larger workshop picture. | Use the agreed leg construction rail and crane rigging to show continuous support. Verify staging, visibility, connection to loads and the complete route; controller state alone does not resolve the observation. |
| PV-120 retaining halves | They look like parts the player can pick up, but remain static on a table. | Resolve collection and placement on the lift. The latest M2 feedback rejects the positioning arm. Use ordinary two-hand pickup and a lift shelf; keep small hardware in pockets. |

## Agreed direction

- Most component assembly happens at workstations. Final-bay lift work focuses
  on mechanical retention, service connections and connection-area closures.
- The torso grows in its supporting gantry from prepared sections and modules.
- Build each leg horizontally on a supported rail fixture, travel toward the
  robot, tilt upright, then raise the ball into its socket. Keep it supported
  until the original two-piece retaining ring is fully bolted. The player uses
  the personnel lift for retention and services. The latest M1 feedback
  ([archived](leg-workshop-m1-m2-handoffs.md)) replaces the extra capture/support-frame handoff with holder-release interlocks.
- Other major sections use crane delivery. At the source, the player attaches
  individual magnetic cable ends to marked points on the component; cable
  length adjusts automatically.
- Crane movement uses **Up**, **Down** and **Go to <location>** at a central
  physical console. Travel options appear only while Up. The fullscreen modal
  freezes player look/movement, supports mouse or ↑/↓ plus E, and closes with Q.
  A later PDA upgrade
  reduces return trips; upgrade timing and acquisition remain open.
- Leg stations use local tactile buttons. Preserve satisfying onboard lift
  operation. Button grouping and motion semantics remain to be designed.
- Keep the existing head-on-neck assembly sequence. Dedicated leg rails followed
  by crane-served upper-body work provide novelty and progression.

## Human playtest checkpoints

These are explicit stop points requested by the user. At each checkpoint, finish
the relevant implementation, integration and focused checks so the user receives
a runnable result. Then stop progression and wait for their feedback and explicit
go-ahead before starting the next wave. A passing test suite, completed agent
assignment or elapsed waiting time does not authorize proceeding. The user may
explicitly combine or waive checkpoints later.

The primary coordinates the stop across agents: do not leave agents implementing
the next wave in the background. Work already in flight must reach a coherent
handoff before the checkpoint is presented. Feedback-driven repairs stay within
the same checkpoint and are presented again when ready; do not quietly advance
while acceptance remains unresolved.

| Milestone | Runnable result and what the human does | What to judge | Work held until accepted | Status |
| --- | --- | --- | --- | --- |
| M1: workshop layout and scale | Walk a rough but functional equipment blockout. Inspect the horizontal leg station, foot-loading position, rails and final bay; operate sample travel/tilt/docking with a disclosed preassembled test load; board and ride the personnel lift. | Is the rail-to-robot journey understandable? Does the machinery visibly support the load? Do the workspace, movement and lift convey the intended scale, with useful access rather than floating parts? | Fixing the layout as the implementation contract, detailed controls and expansion of equipment operations. | Accepted after corrections — 2026-10-23; rails/elevators praised |
| M2: hands-on equipment interactions | Use the central console, walk to the lowered beam, attach both magnetic ends and deliver the Upper-leg beam. Separately carry one retaining half via the lift shelf, seat and bolt it, then undo and bring it down. | Is attaching the crane satisfying? Are console tasks clear, and are the walks acceptable before the future PDA? Does the retaining-half interaction use familiar controls without becoming another operating system? Are tactile rail controls readable and understandable? | Multiplying crane operations and declaring the combined player journey ready for acceptance. | Feedback revision implemented — 2026-10-23; awaiting replay |
| M3: complete leg-to-robot journey | Follow the updated manual through the new horizontal construction/handling work, actual crane delivery, rail travel, tilt, upward seating and lift-based retention. Secure both halves, release support, then reacquire support and try removal/return. Pause, save, quit and resume an unfinished portion. Previously completed foot work may be supplied to avoid repeating unrelated construction; disclose that staging. | Does assembly remain the main activity? Does the rail sequence feel substantial and varied? Is connection work on the lift satisfying and reachable? Can the player understand support release, recovery and instructions without developer explanation? | Extending the approach to the remaining existing equipment-handled parts or treating the example as accepted. | Not started |
| M4: expanded workshop acceptance | Play the expanded current scenario from normal startup, switch between workstations, use the relevant crane and rail operations, interrupt with save/quit/resume and finish hip retention. Revisit any issues from M1–M3. | Have button clutter, floating-load presentation and static retaining halves actually been resolved? Are the successful lift scale/operation and small-part assembly experience preserved? Is any remaining friction or bug acceptable for this iteration? | Marking this iteration accepted/completed and moving into later feature branches. | Not started |

M1 is a geometry/scale blockout, not a polished art milestone. Staged loads belong
to an isolated test setup that preserves the normal saved workshop. M2's crane and
retainer examples can be developed concurrently after M1; each must be runnable
through normal controls before presenting the combined checkpoint. M3 depends
on both interactions and their matching manuals. Do not implement extra robot
branches or PDA progression to populate a checkpoint.

For every handoff, include the exact launch command and scenario/save instructions,
a short list of actions to try, known limitations, the focused check results and
two or three concrete feedback prompts. Keep a reproducible test setup available
so feedback does not require rebuilding hours of already verified components.
The primary records the user's response and status in this table or directly
below it, with date and outstanding issues. Keep all checkpoint records here.

### M1 acceptance and M2 planning — 2026-10-23

After replaying the corrections, the user said “Yep looks good - plan next
milestone.” M1 is accepted for its layout/scale boundary. Preserve the rails,
elevator experience, continuously supported docking, clear rejection messages and
loaded Return. This does not establish acceptance of the unimplemented crane,
retaining carrier, complete ring or holder-departure journey. Earlier pending
M1 statuses in the [archived handoffs](leg-workshop-m1-m2-handoffs.md)
are historical records, superseded by this acceptance.

### M2 playtest feedback revision — 2026-10-23 (current)

The user requested these changes with **no subagents**. This revision was handled
solo; the earlier delivery-team assignments do not apply to this feedback pass.
The original uncommitted planning/M1/M2 work was preserved. The following choices
supersede the carrier and console procedures in the
[archived M2 brief](leg-workshop-m1-m2-handoffs.md).

| Feedback | Current response |
| --- | --- |
| Crane delivery broadly works; console UX needs a complete rework. Commands should be Down, Up and Go to each valid location, with travel offered only while Up. Mouse look made menu selection unintuitive. | Fullscreen modal console captures pointer interaction and suppresses movement/look. Mouse buttons or ↑/↓ and E select commands; Q closes; Escape pauses. Up/Down and horizontal travel are separate motions. Invalid travel is rejected by the controller as well as hidden by the menu. Stop/resume remain available during a motion. |
| Magnetic attachment is broadly right, but cable ends were off-centre and awkward to manipulate. | Held magnetic ends stay exactly on the camera axis. A holding prompt explains aim/click attachment and Q stow; free/occupied marked targets retain the existing reach and ownership checks. The feel still needs player assessment. |
| Remove the elevator arm; the retaining half is a two-hand piece. | The arm and its support state are removed from M2. E picks up the ordinary solid component, click installs it, and Z returns the unfastened half to hands at the connection. Both equivalent physical half UIDs are tested against the slot's canonical geometry. |
| Elevator components were useful, but pockets make drawers unnecessary. Replace them with a shelf for two one-hand or one two-hand component. | Ground stock supplies the ring and pocket hardware. A finite shelf on the side opposite the hip work corner travels with the lift; click stores the held component, E retrieves it. Stored identities, capacity, solid travel and save/resume are verified. No drawers remain on the lift. |

**Launch:** `./play.command -- --m2-workshop`. In the selector, use **Reset Hip
retainer** / **Reset Crane delivery** for these changed trials. Previous M2 saves
have an incompatible fingerprint and are preserved until an explicit reset;
normal/foot saves and M1 remain separate. Pause → **Choose M2 trial** saves the
selected example and returns to the selector.

**Hip retainer route:** Advance the supplied leg through travel, tilt and docking.
Collect both washers and bolts into pockets from ground stock near the lift,
then E-pick the ring half with both hands. Board, aim at the shelf and click to
store it. Use Up, E-pick the half from the shelf, aim/click the hip connection,
then fit its two washer/bolt pairs normally. Z in the pelvis manual removes the
hardware and then puts the half back in your hands. Store it on the shelf and
ride Ground to recover it. Q can drop it as a solid component and E retrieves it.
Rail Return stays blocked while any retention is fitted. Once all retention is
removed, Return withdraws the supported leg and brings it home.

**Crane route:** E opens the central console. Choose **Go to Upper-leg beam rack**,
then **Down**. Q closes the console. Walk to the rack, E-pick each magnetic end,
aim at a marked point and click; Q stows a held end. Return to the console: **Up**,
**Go to Leg cradle**, then **Down**. Close the console and fit the four ordinary
washer/bolt pairs. E-detach and Q-stow both ends, then **Up** and **Go to Parking
bay**. Before any hardware is fitted, Up at the cradle unseats the supported
beam; Go to its rack and Down returns it. Undo fitted flange hardware before
lifting a loaded beam. Both magnets remain attached until the flange is secured.

The shelf was first placed across the back of the deck; a walked check caught
it obstructing the hip working corner. It now sits along the opposite side,
leaving the accepted boarding and hip approach open. The ordinary-control loops
cover both half UIDs, fitting/removal, the shelf ride, dropped-component recovery,
the complete crane fastening loop and loaded reverse travel. Additional checks
cover keyboard/mouse modal isolation, screen-centred magnets, both shelf capacity
configurations, obstruction sweeps, native disk resume and malformed saves.

Final headless verification passed **54 cases / 6,019 checks**, plus **100**
malformed save-field attacks, with code/asset/test inputs unchanged throughout.
Report: `game/workshop/verification/regressions-20261023T092828.720004Z/results.json`.
Focused results: content 106; retention controls 162 across both half UIDs;
retention saves 579; crane controls 102, saves 113 and service/recovery 63;
console input 17; shelf capacity/physics 22; adversarial acceptance 47 plus the
100 attacks. Normal/foot/M1 launches and all legacy suites passed. Generator
`--check-m2` and `git diff --check` also passed. Current focused evidence and
preservation details are in `game/workshop/verification/m2-feedback-20261023/`.
The original root planning changes and M1 files remain byte-identical to the
pre-feedback snapshot; this plan and affected M2 files were intentionally updated.
No subagents were used. No rendered review was requested or performed; automated
behavior does not establish human acceptance. The ring remains a procedural blockout, only one half is supplied,
and full hip security, holder departure, additional loads and released-beam
disassembly remain outside this M2 checkpoint.

Assess whether the console commands and keyboard selection are clear, whether
magnetic ends now feel natural to aim, and whether carrying the ring via the
shelf works comfortably at both lift stops. Stop here for that feedback; do not
advance to M3.

## Proposed implementation plan

### 1. Establish the complete equipment layout

Plan each major final-assembly connection before fixing the room layout. For
each, identify source support, approach direction, transport attachment, receiving
support, player fastening/service access, safe release and removal sequence.

| Section | Working workflow | Remaining design |
| --- | --- | --- |
| Pelvis | Supported by the main gantry as the robot grows | Player-built pelvis workflow and gantry mounting access; current prototype starts preassembled |
| Waist/chest | Torso grows in the gantry using prepared sections/modules | Module boundaries, insertion paths and support points; keep cockpit access before armor |
| Each leg | Horizontal rail construction, travel, tilt upright, upward docking, bolted split-ring retention | Foot handoff, construction-face access, pivot and travel geometry, second-leg routing |
| Each arm | Crane delivers prepared arm; player connects from personnel lift | Socket insertion direction, rigging clear of joint, retaining-ring and service access |
| Head | Existing baseplate-on-neck then in-place head construction | Delivery of supported pieces and high-level working access |
| Backpack/core | Rear-access installation; core enters rearward-facing guides | Receiving supports, hinge installation and open-backpack clearances |
| Connection covers | Close after underlying retention and services | Which panels remain at workstations versus final bay |

The table does not settle unresolved robot interfaces or authorize new playable
body branches. Define only the equipment envelopes needed for this iteration;
keep future insertion/access requirements explicit.

Give rails, fixtures, cranes, platforms and routes one coordinated spatial owner.
Resolve actual visible contact points and swept clearances, not only support IDs.
Plan reachable controls at both ends of travel and access after docking. Select
one-station reuse or separate left/right leg tracks before finalizing the route.
Prove the empty fixture can withdraw and return after the first leg is attached;
reserve the second-leg path without adding playable right-leg content.

Preserve canonical source poses and rotate the supported assembly through its
parent transform. Current `AssemblyRuntime` already composes local slot and child
anchor transforms; rotating mesh/source data as well would double-transform it.
Start by evaluating a horizontal rotation about the knee's X axis to preserve
axle/cap-side access, including the specified 1.2 m axle extraction aisle.
Do not freeze this axis or pivot until checking the actual loaded foot: its toe,
heel, knee and supports must clear the floor and gantry across the whole tilt.

Check future headroom now. At the current 1.4 m raised robot datum, the eventual
crest reaches 19.4 m, equal to the existing main hoist height. Resolve overhead
clearance alongside arm approaches and rear core/backpack access, rather than
assuming today's crane/gantry can serve the completed robot unchanged.

### 2. Prove one leg journey

Use existing structural content to build a supported horizontal fixture. Expose
the ankle, both knee sides and thigh connections through reachable work poses;
retain the foot's need for underside access at its own construction stage.
Define its handoff onto the leg fixture explicitly.

Use a small, readable local physical button group for machine motions. Candidate
intents are travel, tilt and docking lift, with clear stop/return behavior. Exact
labels, press-versus-hold behavior and grouping need the representative prototype;
these are not settled controls. Avoid controls for each stock identity.

Prove horizontal construction -> rail travel -> tilt upright -> raise ball into
socket -> retain with both halves and all hardware -> connect available services
-> release support. Preserve required stabilization of unpowered joints. Do not
invent service-installation completion for mechanisms outside current content.
The selected M1 correction makes full retention the holder-departure gate and
removes the extra external capture/stabilizer control; do not reintroduce that
control while implementing this later journey.

Exercise the reverse journey using the same physical assembly. Reacquire support
before undoing retention. Pause, blocked routes and interrupted saves must leave
the load visibly supported and recoverable.

Persistence is part of this slice, not a later assignment. Current leg saves
fingerprint content and layout/controller/lift scripts, and validators assume the
upright hoist workflow. Explicitly version the new equipment state. Default to
preserving incompatible leg saves with a clear incompatibility message; do not
silently reset, overwrite or reinterpret old hoist motion as rail motion. Keep
the established foot profile intact. Migration is a separate scope unless a
bounded, verified mapping is established. Test restoration into a fresh scene.

### 3. Resolve retaining-half handling on the lift

The static, pickup-looking PV-120 halves must become understandable equipment
or carried interactions. Prototype one half end to end before choosing the final
handling mechanism.

Candidate: stow halves beside the personnel platform and use a small assist arm
that follows normal E pickup, aimed assisted placement, click seating and Q return.
The arm has no independent joint-control interface. Check reachable pickup/stow,
bounded motion, obstructions and support until the half is fastened; then it can
release and handle the other half. This is a proposal, not a confirmed feature.
If it introduces awkward controls or excessive complexity, simplify the handling
while retaining an understandable physical support and collection path.

C must make the manual match a single supported-half workflow: seat one half,
fit its two washer/bolt pairs, release the assist arm/carrier, then repeat for
the other half. Current data permits this but the manual groups both halves
before the fastening page. Rework the affected page/slot grouping without adding
false prerequisites or losing unique hardware coverage. Both halves remain
interchangeable; final hip support release still requires the complete ring.

### 4. Prove the crane journey

Use LG-120, the existing thigh spar, for the first crane loop: a low horizontal
rack -> magnetic rigging -> receiving cradle on the horizontal leg fixture ->
manual flange fastening -> cable detachment. Do not restore whole-leg crane
transport. Check both marked magnetic attachment points are actually reachable
and clear of the fork flange, bolt tools and hip ball.

The player calls the crane at its central console, walks to the lowered beam,
attaches individual magnetic cable ends at marked points, returns to the console
and selects the transfer. Automatic cable-length adjustment and assisted
attachment keep this comfortable. Define endpoint access before choosing rigging
positions; elevated points need reachable platform access.

Show the crane taking weight before a source fixture releases. At the destination,
show the receiving fixture or secured assembly taking weight before cables detach.
For the initial spar slice, keep crane assistance until the flange hardware is
secured. Source pickup, seating, fastening and equipment release remain distinct
states; source support authorization must include the real crane. Decorative
cables around the old rack-to-slot installation shortcut do not meet this plan.
Keep rigging clear of installation surfaces. Use controlled supported movement;
full loose-chain and swinging-load simulation is outside the proposed slice.

The console selects understandable source/destination tasks and explains invalid
placements without dropping or consuming the load. Preserve support when travel
is blocked. Keep crane commands independent of the console so a later PDA upgrade
can expose the same actions. PDA visuals, unlock rules and economy are later work.

### 5. Expand and verify

Evaluate one complete rail journey, one retaining-half interaction and one crane
transfer through ordinary aim/input before extending the proven interactions.
Record comprehension, readable controls, believable support and lift satisfaction
separately from mechanical checks. Follow existing explicit-request-only policy
for rendered review; do not claim visual or player acceptance from headless tests.

Focused checks cover motion sweeps, support transitions, blocked/incompatible
destinations, retention before release, inventory identity, mounted-child poses,
reverse travel/undo and save/resume during movement and partial installation.
Run affected regressions after integration, preserving the original small-part
collection and assembly loop. Detailed new robot assets and extra body branches
remain outside this handling iteration.

### Acceptance and evidence

| Feedback / risk | Required evidence |
| --- | --- |
| Cluttered controls | Walk actual operating routes and use normal aim/input for relevant tactile buttons, console tasks, stop/return and invalid-action feedback. No overlapping permanent part-specific button cluster. Readability requires player or explicitly requested visual assessment. |
| Floating components | Trace visible contacts and rack/equipment/receiver ownership through pickup, travel, seating and release. Sample fully populated geometry across the motion, including between input and physics ticks. Partial rigging cannot release source support. |
| Lift satisfaction | Board, ride and return using onboard controls; reach both retention halves and actual fasteners without remote attachment. Preserve scale, walking access and useful work at height. |
| Static retaining halves / arm complexity | Collect, support, seat, bolt and return the same half through normal inputs; repeat with the other interchangeable identity. The arm remains a prototype with no independent joint controls. |
| Unsafe docking/release | Reject departure with incomplete retention, Return with any fitted retention, wrong destinations and blocked routes while preserving holder support. Reacquire support before deliberate undo/removal; no extra external capture/stabilizer command. |
| Persistence | Fresh-scene restore during rail travel, tilt, docking, partial rigging and partial retention; reject contradictory snapshots without mutating live state. Preserve incompatible saves and the foot-only profile. |
| Identity/geometry regressions | Installed source orientation, swapped equivalent parts, mounted foot/actuator descendants and collision poses remain correct throughout motion, undo and reinstall. |

New journey checks must walk console/source/destination routes and operate every
new handling action normally. Staging unrelated already-verified foot construction
is acceptable if disclosed; do not bypass the new rail, rigging or retention
interaction.

Run generator/definition audits first. Then select affected `leg_content`,
`m2_*`, `access_lift`, supported fixture/model, mounted-runtime and save suites with
`python3 game/workshop/tools/run_regressions.py --only ...` using actual case
names from `--list`. Add narrowly scoped new rail/rigging/acceptance cases where
existing tests miss the reported failure. After integration, run the complete
existing headless runner, including default/foot launches and shared pad, pitch,
pockets and multi-build regressions; repeat only for relevant new changes or
failures. Also run `git diff --check`.

Report behavior verified, presentation inspected and player acceptance separately.
Prepare a short playtest route covering construction, rail docking, lift retention,
crane rigging and return; do not claim the user's readability/immersion concerns
resolved solely because headless suites pass. M1–M4 above are the requested human
checks; reaching M4 does not establish acceptance until the user responds.
Rendered review is still by explicit request. The M1 evidence above covers only
the isolated blockout; the future M2–M4 journey checks remain unrun.
