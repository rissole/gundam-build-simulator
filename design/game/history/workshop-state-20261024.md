# Workshop: active plan and playtest state

> **Archived 2026-10-24.** Full text of the workshop state document before it was condensed. The [current version](../leg-workshop-next-steps.md) keeps the active rules and every feedback item.

Updated 2026-10-24. Read this before continuing workshop development. The default
base game is the supported-foot workshop: two heel pads and the pitch actuator.
The upright-hoist workshop and isolated M1 trial are retired. The M-series is a
prototype lane using profiles on reusable equipment, layout, assembly and save
modules; it is intended to fold back into the base game later.

## Current work: implement the wider M3 workshop

On 2026-10-24 the user paused the Codex implementation for intermediate review
after 6h20m, judging it too slow and suspecting the architecture. A review of the
session log and working tree found: 62 min waiting on one sandbox permission
prompt (Godot editor import of new part icons); about 25–35 min of model
generation per section that never decreased; and, per section, a bespoke receiver
controller, direct checks against other machines, growing crane-contract flags
and another layer in a linear test-inheritance chain whose fresh-scene restores
took about three quarters of its runtime. The user then deferred M3 saving and
checkpoints (see the [plan](../robot-workshop-plan.md#saves-and-checkpoints)) and
requested a `--m3-stage` development launch flag. Work resumes from the task
files in [handoff/README.md](m3-wide-handoff/README.md); they override older instructions
in this document where they differ.

The playtest checklist for the complete wider workshop is [robot-workshop-playtest-checklist.md](../robot-workshop-playtest-checklist.md); record results there and summarize them here.

Task 09 resumes from `94d37c2` with the user's 2026-10-24 shelf-enlargement
choice. Both M3 shelves now accept one 1.45 × 0.35 × 1.20 m panel on a 1.50 m
surface; the authored mask fits with its hook/bolt interfaces preserved. Sensor
carrier, faceplate, hooked mask and final crane crown are implemented on the
shared staged receiver. `--m3-stage=complete` prepares the retained/connected head
and parks the crane. See the [plan ledger](m3-wide-evidence-20261024.md#plan-implementation-ledger-through-task-09)
and [head implementation](../../head.md#robot-workshop-head-implementation--2026-10-24).
Mechanical checks remain separate from pending user walking, access and
presentation playtesting; M3 saving and full teardown remain deferred.

The last regression run before review passed 17 of 18 cases. The full sequence
stopped before cassette pickup because the test never returned the right-foot
carrier; task 01 adds that step. The isolated arm branch's 299 mechanical checks
do not replace the full-sequence check.

The user has now requested implementation of
[robot-workshop-plan.md](../robot-workshop-plan.md). Its implementation ledger
tracks the active work and evidence. The authored spatial foundation, shared
moving access platforms, two independent elevators/shelves and movable platform
are integrated. The revised left-leg route now covers source roll, parking,
indexing, actual docking, hip cartridges/pins/neutral locks, empty return and
local support reacquisition with fresh-scene interrupted restores. Both structural
legs now use independent mirrored stock, hip retention and the shared holder;
both prepared feet travel from separate bay supports via the four-end crane and
shared carrier. The second leg docks beside the first and the empty holder returns.
The pelvis/waist now starts on a height-adjustable bulky fixture and reaches the
gantry by the same four-end crane. Four physical hold-down jaws and both waist
neutral locks establish support before crane release or leg docking; interrupted
source contact and jaw closing survive fresh-scene saves. The prepared chest now
travels from its passive store through that same fixture onto the waist, with
exchangeable contact inserts, four bolt/washer pairs and two service leads.
Interrupted transfers and local supported correction have mechanical coverage.
The core now has its planned rear route, staged guide capture, folding equalizer,
four captive retaining bolts and rear interlock. Its full rigging envelope is
included in movement checks. The prepared backpack now transfers between its
passive store and the shared fixture, with interrupted restores and supported
return. Backpack delivery, separate hinge/strut pins and keepers, positive open
locks, two service connections and crane-assisted closure are now integrated.
Both lower draw latches precede rig release and service-cover closure. Local
correction reopens under crane support, with interrupted deployment, weight
transfer and hinge angles preserved through fresh-scene saves. Its source,
rigging and service-display geometry have preflight coverage; walking and
connection access remain the user's playtest. The later task-07–09 work adds
pauldrons and the complete head; the ledger above records that structure.
Historical evidence below does not establish fresh gameplay or usability approval.

Arm source preflight now includes both prepared arms, the connected cassette,
actual fixed shoulder drive brackets and the complete four-end rig/taglines.
The retained cassette now travels between passive parking and the shared station
using the existing four-end crane. Its floor locks take weight before rig release,
and station occupancy prevents the leg cradle from returning until the cassette
parks. Partial source/receiver contact and suspended saves restore the same arm
and cassette identities. Both arms now release from the cassette into the full
four-end rig, follow the checked upend/yaw/splay/seat route and receive separate
ring, brace, drive, pin/keeper and service stock through the chest manual. Brake
confirmation and progressive weight transfer precede crane release. The second
arm transfers from its passive store onto that same cleared cassette. Local
keeper correction retains the seated arm under crane support. Empty-cassette
clamps retract before folding and support interrupted manual adjustment.
Pauldron closure and restraint removal are still outstanding. The original 0.65 m pre-seat offset crossed
a fixed front drive clevis during forward approach. A checked 1.13 m offset
lowers the approach by 0.464 m, moves it 0.124 m farther outboard and then seats
along the same axis. The measured plan and shoulder specification record this
correction and the distinct source/model fixes. The user was offered the checked
lower approach or later bracket installation; the lower approach is the current
implementation choice, not a claim of explicit user approval.

The user's “wasn't this made clear in the plan—the rigging paths?” feedback
remains applicable: the earlier rear paths were explicit. Omitting full spreader,
cable and parked-equipment checks was an implementation/verification miss.
That must not be reframed as planning ambiguity. New actual-solid conflicts,
such as the shoulder clevis crossing, must be measured and documented separately.

On 2026-10-24 the user described the implemented M3 leg-to-gantry build as
“largely satisfying,” but said implementation took too long because agents
discovered access and movement in-game without a detailed measurement plan.
The current task is collaborative design: work backwards from the complete
robot, agree major-section installation, then develop each section's workflow.
Continue in the [final gantry and assembly plan](../final-assembly-plan.md).

The user selected the raised M3 pose as the access-planning baseline, leaving
eventual lowering undecided, and side elevators feeding shared front/rear work
platforms. The first selected delivery is the pelvis, socket housings and waist
mechanism prepared together at a workstation, then craned into the gantry.
The chest frame and cockpit are also prepared together at a workstation, then
craned onto that waist with connection areas left accessible. The selected manual
route is pelvis/waist → both legs → chest/cockpit → power core → backpack → both
arms → head. Component preparation remains independent; alternate installation
orders stay available where access permits. Each arm is prepared complete with its hand, delivered by
crane with shoulder armor off, and joined/connected/closed at the shoulder in the
gantry. The user accepts a shared long-limb workshop, with one arm station plus
one leg station as the alternative if needed; separate left/right workshops are
not wanted. Legs depart on their rail cradle, arms by crane. The
[measured plan](../final-assembly-plan.md) and [layout drawing](../final-assembly-layout.svg)
now propose coordinated bay, rail, crane, elevator and rear-service reservations.
The user likes the layout but correctly raised the risk that unresolved interfaces
would change its measurements. They authorized one GPT-6.1 Sol/xhigh owner per
component area to make decisions and edit its existing design documents, with
questions routed through the coordinator. The five
[interface passes](../final-assembly-plan.md#recommended-next-design-passes) now
record pelvis/hip/waist, chest/cockpit, core/backpack, shoulder/arm and head
contracts. These are selected working designs and bounded calculations, not
implemented geometry or gameplay approval. No blocking human choices remained.

The subsequent **fixture and route pass**, requested without subagents, is now
integrated into the same plan, drawings and component transport notes. It selects
an 11×12 m bulky bay, a 7×13 m common limb bay centredX14, separate passive
leg/arm parking, supported indexing to both hip lanes and an empty-fork return with1.4 m
rear withdrawal before the 2 m outboard shift. The complete calf requires a lower rear-spine contact and side frame pads;
source roll raises the supported axis toY3.1. The chest has a measured60°
bare-frame service pose before upright cockpit insertion.

Shared elevator centres move rearward toZ29.0; levels remain8.4/11.2/14.0/16.4.
Front wings swing forward for delivery, rear hip bridges fold upward in two leaves for leg travel,
with fixed aft service fingers for core access. A low braced pelvis
portal replaces the obstructing overhead gantry crown. Core and open backpack
travel low around the right side, rise in an outboard lifting well, cross above
the highest guards and lower into the central rear opening. Head work uses outer perimeter paths, leaving arm rigging lines open.
The same crane, two elevators and one movable platform serve all these jobs.

Bounded calculations include full leg/holder tilt, second-leg clearance, empty
return, leg source roll, chest tilt, arm upend/yaw/splay, rear cable/load routes
and head hook budget. The [layout](../final-assembly-layout.svg) includes floor,
work-level and rear-section views. These checks establish a coherent dimensioned
blockout contract, **not actual-solid, structural, gameplay or playtest approval**.
No new M3 scene changes, gameplay milestone or M4 work are implemented by this pass.

The active implementation is the [M3 wider-workshop adaptation](../robot-workshop-plan.md),
before detailed internal component workflows. The user selected replacing M3 in
place, with no old-save compatibility work, both simplified structural legs,
representative mounting connections on prepared major-section stand-ins, and
pause-menu playtest checkpoints. Build the complete workshop blockout and its
shared equipment/routes before deepening individual mechanisms.

The user will perform walking, visibility, reach and connection-access checks.
Automated verification is limited to content, equipment movement, support ownership,
interlocks and save/resume; do not run automated walked acceptance or access sweeps.
Runtime reach and obstruction rules remain active. Keep answers in the existing
component documents and shared workshop plan; temporary evidence stays outside the
design-document tree. Eventual whole-robot lowering remains undecided. Preserve
M3's satisfying scale, supported handling and local correction; full teardown
remains outside acceptance.

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

## M3 implementation baseline

On 2026-10-23 the user authorized implementing the
[complete M3 plan](leg-workshop-m3-plan.md), starting with a prepared complete foot
at dispatch and building the remaining structural left leg. The implementation
covers the supported foot handoff, three crane loads, full horizontal construction,
rail docking, both retaining halves, holder release and interrupted save/resume.
On 2026-10-24 the user stopped full reverse-sequence verification: reversing is
for correcting mistakes, not a full teardown completion gate. Keep implemented
undo/support safeguards. The
[M3 ledger](leg-workshop-m3-plan.md#deferred-reverse-investigation) preserves the
partial reverse evidence and unresolved fork-return investigation; do not reopen
it as required work. The user's positive assessment above is separate from the
automated evidence; it does not resolve every future workflow. No
rendered review has been requested. The final
[forward gate](../../../game/workshop/verification/regressions-20261023T203841.362193Z/results.json)
passes 636 ordinary-input checks, 30 real save/reopen checkpoints and 11
source-asset tests. The user-requested
[delivery retrospective](leg-workshop-m3-plan.md#delivery-retrospective--2026-10-24)
records elapsed time, complexity and avoidable work. M4 remains held while the
whole-robot workflow is designed.

## Completed architecture consolidation before M3

Shared profiles, equipment, layout data, recipe patches, validated saves and the
common regression runner are implemented. Production assembly projection is
generic. The integrated preservation review passed, and the user accepted the
M2 replay on 2026-10-23. The default-foot preservation replay remains unconfirmed;
retain its pinned save and source assets. Existing incompatible saves must remain
protected. The [consolidation regression report](../../../game/workshop/verification/regressions-20261023T114809.356593Z/results.json)
records the historical automated result; it is not fresh evidence for new work.

The M3 rail/lift/task geometry has its own layout data. Shell, gantry and crane
structure still include runtime dimensions; do not assume a profile JSON alone
supplies the complete spatial contract. See the sources in the final assembly plan.

## Player feedback and constraints to retain

| Feedback / positive finding | Current direction and unresolved question |
| --- | --- |
| Implementation took 6 h+; the user suspected poor architecture (2026-10-24) | Reviewed; see Current work. Before pauldrons/head, add one generic receiving interface and an occupancy register so new sections are mostly data. One fresh agent session and one commit per task; run the Godot import before work that adds part icons. |
| Saving and checkpoints keep adding work and are often wrong (2026-10-24) | Deferred for M3 until the structure exists. `--m3-stage=<name>` supplies earlier progress for inspection. Default foot and M2 saves are unchanged. |
| Rigging paths were already clear in the agreed plan; extra discovery iterations undermine its purpose | The core implementation initially swept the load without the full spreader/cable envelope and let parked access gates intrude into the reserved bypass. Treat this as an implementation/verification miss. Before expanding subsequent deliveries, compare source geometry, parked equipment, adapters, spreader and every cable against the existing measured route and handoff contract. Preserve the selected routes; record any actual design discrepancy before changing them. |
| M3 leg-to-gantry build is largely satisfying, but implementation relied too much on in-game discovery | Preserve its physical handling; define shared coordinates, load routes, work faces, player standing areas and equipment clearances before implementation. Work backwards through the [final assembly plan](../final-assembly-plan.md). |
| Prefer side elevators and walking onto shared front/rear work platforms | Selected for the full gantry; measure loading openings and access levels together. Keep M3's raised datum for planning; eventual lowering remains undecided. |
| Hip and shoulder connections should remain accessible using shared elevators | Reuse each side elevator across work levels; measure the full travel with arms fitted and reachable landings for both hip/shoulder work. Current M3 lift placement cannot be assumed suitable at upper levels. |
| Prefer shared left/right construction; a single long-limb workshop is acceptable, or separate arm/leg stations | Keep leg rail transport and arm crane transport distinct. Measure the common bay's cradle supports, routing to either hip, crane pickup and parking together; do not duplicate workshops by side. |
| Proposed workshop measurements look good, but unresolved interfaces could change them | Major-interface decisions are now recorded in the existing component specifications and integrated into the shared plan. The coordinated fixture/route pass now enlarges the bulky bay and specifies shared supports, parking, platform states and loaded routes. Actual-solid validation remains before implementation. |
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
parallel work. The later explicit implementation request authorizes M3 gameplay.

| Checkpoint | Player journey / acceptance question | Status / work held |
| --- | --- | --- |
| M1 layout and scale | Understand rail-to-robot support; walk routes and board/ride the lift | Corrected layout accepted, 2026-10-23; trial now retired, accepted geometry retained in M2 |
| M2 equipment interactions | Rig/deliver/fasten the Upper-leg beam; carry one retaining half via shelf, fit/undo/return it; judge console, walks, magnets and tactile controls | Human-accepted, 2026-10-23: “m2 plays great.” |
| M3 complete leg-to-robot journey | Build from prepared foot through crane delivery, rail docking, both halves and holder release, with interrupted save/resume | Implemented and forward-verified; user reports “largely satisfying,” 2026-10-24. Planning/process feedback remains active. Full teardown verification stopped by request. [Plan and evidence](leg-workshop-m3-plan.md) |
| M4 expanded workshop acceptance | Complete the combined scenario, revisit clutter/support/retention/lift issues, save/resume across workstations | Not started; requires earlier checkpoints and explicit acceptance |

At each checkpoint finish the coherent implementation and relevant checks, stop
all later-wave work, then present the runnable result and wait for feedback and
explicit go-ahead. A test pass or elapsed time never supplies that acceptance.
Keep mechanical checks, inspected presentation and human responses distinct.

### M2 replay acceptance — 2026-10-23

After the consolidation handoff, the user said “m2 plays great. please commit.”
This accepts the current M2 equipment checkpoint and authorizes committing the
verified consolidation. No new M2 issues were reported. Preserve the accepted
crane console/magnet and two-hand carrying/lift-shelf flows. At that checkpoint
the user had not confirmed replaying the default foot profile or authorized M3
implementation; the later M3 authorization is recorded above.

## Short preservation replay

Launch commands and controls are maintained in the
[workshop README](../../../game/workshop/README.md). Use these routes after the
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

The [full pre-consolidation continuation snapshot](workshop-pre-consolidation-state-20261023.md)
retains every earlier feedback item, proposed implementation sequence, acceptance
matrix, M2 routes and historical check report. Earlier team handoffs and the
delivery retrospective remain in
[the M1/M2 archive](leg-workshop-m1-m2-handoffs.md). The
[structural milestone](leg-milestone.md) and
[interface specification](../leg-prototype-interface.md) describe the historical
implemented subset; their headless passes do not approve the current UX.

M3 addresses the foot-to-horizontal-rail handoff, construction-face access,
pivot/travel geometry and empty-holder return on the active left track. Preserve
the user's positive overall assessment without treating it as approval of
unimplemented full-robot routes. The full-workshop plan now selects both supported hip routes, including
the first fitted leg and empty return, at conservative envelope level. Pelvis/torso connections, arm rigging, head/neck assembly and
backpack/core clearance now have selected contracts in their component documents.
Actual source solids, equipment strength, tool visibility and internal construction
still need the checks tracked in the
[final assembly plan](../final-assembly-plan.md). Most components build at workstations;
final-bay lift work concentrates on retention, services and connection closures.
Keep the existing head-on-neck sequence. A later PDA may reduce console walks;
its acquisition/progression rules remain open. Full loose-chain/swing physics,
detailed Blender leg assets, powered mechanisms, armor, additional robot branches
and AR are outside M3.

For future implementation, first model/check the selected equipment/access envelopes,
then prove one ordinary-control journey before expanding content. Audit affected
manual slots/inventory, actual geometry and mounted motion; exercise relevant
blocked paths, local mistake correction and fresh-scene interrupted restores.
Preserve canonical geometry separately from interchangeable consumed identities.
Rendered review still requires an explicit request.
