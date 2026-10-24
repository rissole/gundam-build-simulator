# M3 complete leg to robot journey

Implementation authorized on 2026-10-23. The user selected a completed foot at
dispatch, followed by player construction of the remaining structural left leg.
This checkpoint ends with a leg secured to the supplied pelvis and a working
holder release. M4 and other robot branches remain separate work.

Player feedback, 2026-10-24: the user finds the complete journey “largely
satisfying,” but wants detailed measurement and access planning to reduce future
implementation effort. Continue the design discussion in the
[final gantry and assembly plan](final-assembly-plan.md); this ledger retains M3's
implementation evidence and retrospective rather than becoming the full-robot plan.

Scope update, 2026-10-24: the user stopped full reverse-sequence verification.
Reversing is for correcting mistakes, not a requirement to dismantle the complete
leg and return everything to stock. Keep implemented undo/support safeguards;
finish one fresh forward journey through full retention and holder release.
Do not reopen full teardown validation as an M3 completion gate.

Current continuation: the user selected [replacing M3 with the wider workshop](m3-wide-workshop-plan.md)
before detailed component workflows. That plan supersedes this historical
implementation scope and its automated access gates; the user owns walking and
connection-access playtesting for the adaptation.
Implementation is now active in that plan's ledger. The wider spatial/access
foundation is integrated; the historical leg route below is awaiting adaptation.
The complete wider-workshop handoff remains outstanding.

## Starting boundary and completion

Supply the existing complete foot branch, retaining its 135 physical identities,
on its dispatch carrier. Leave every left-leg and pelvis installation slot empty.
The existing structural graph supplies 40 further physical pieces and two child
mounts: 42 M3 installation slots. The preassembled pelvis and socket housings
remain gantry-supported context. Logical assemblies add no physical inventory.

Create a dedicated `leg_bay_m3` profile, `--m3-workshop` launch alias and independent
save slot. Preserve the supported-foot default, its pinned save, and the two
accepted M2 trials. Keep procedural structural geometry and the existing foot GLB.

## Implementation sequence

1. Agree one spatial and state contract for the foot carrier, receiving fixture,
   racks, crane, rail, personnel lift and walking routes. Add receiving foot
   contacts that support the build before the shin exists. Use a guided carrier
   handoff and indexed turnover for the prepared foot. Reuse the accepted crane
   interaction for shin, knee fork and Upper-leg beam.
2. Prove dispatch foot to horizontal fixture to crane-installed, secured shin,
   followed by shin source return and foot return. Use ordinary player controls,
   real support contacts and a fresh-scene interrupted restore. Establish this
   representative loop before expanding all equipment tasks.
3. Complete the horizontal construction and corresponding manuals: foot, shin,
   ankle fastening, harness, bearings/spacers, fork, axle/cap, beam and flange
   fastening. Keep valid independent construction order. Rail departure requires
   structural readiness and released handling equipment.
4. Complete rail travel, tilt and upward docking; carry and fasten both retaining
   halves using the finite lift shelf; release the holder only after full
   retention. Prove empty withdrawal and return without moving the mounted leg,
   then reacquire support before permitting any retention undo.
5. Preserve supported mistake correction and interrupted save/resume. Finish the
   fresh forward journey, relevant preservation checks and normal launch, then
   present runnable M3 for human playtest. Full teardown verification was stopped
   by the user's scope update above.

## Shared constraints

- Keep local Advance/Stop/Return, the central crane's Up/Down/Go controls, and
  ordinary E/click/Q carrying and magnets. Preserve the accepted console modal,
  centered held magnets, lift boarding and hip approach. Do not add an external
  stabilizer/capture command.
- Retain one active left-leg rail and the second-leg reserve. Prove actual empty
  holder withdrawal against the stationary attached leg; a support ID is not
  evidence of physical clearance or contact.
- Each physical item has one owner/location. Equipment assistance is distinct
  from assembly ownership, seating and fastening. Exactly one authority moves
  each supported hierarchy. Mounted foot, pads and actuator inherit the parent
  pose, including between input and physics ticks.
- Carrier withdrawal must leave the foot on real receiving contacts. An empty
  carrier must not reposition the mounted foot. The foot carrier's M3 state must
  not alter the pinned default-foot save schema.
- Crane tasks use the same physical equipment. Task switching requires released
  cargo, stowed endpoints and stopped motion. Each source and receiving route has
  authored contacts, marked points, fastening clearance and a supported reverse.
  Reacquisition of installed pieces requires a stopped rail in the matching home
  pose. Security is derived from the task's actual authored retention milestone.
- The knee axle's 1.2 m extraction aisle remains clear. Test both knee sides and
  the actual ankle/fork fastener faces from ordinary player positions. Add work
  poses only where demonstrated access requires them.
- Complete hip retention means the seated leg, both interchangeable PV-120
  halves and all four washer/bolt pairs. Partial retention blocks loaded Return.
  Empty holder Return leaves the leg mounted. Departed support blocks the first
  retaining-hardware undo, not merely the final child unmount. Required unpowered
  joint restraints remain explained after holder departure.
- The shelf holds one two-hand half or two one-hand pieces. Both halves therefore
  make distinct lift journeys. Small hardware stays in persistent pockets.
- Keep canonical destination geometry and `pose_source` separate from consumed
  identity. Bearings, spacers and retaining halves remain interchangeable within
  their types. All eight LG-W24 washers share stock; fork and ring bolt variants
  remain incompatible.

## Manual and dependency contract

The leg manual owns its internal construction. The pelvis manual owns mounting
the prepared leg and retaining it. Every installation slot appears once in the
relevant step component lists, including prepared child assemblies on mount
pages. Overview, readiness, equipment-only and recovery pages have no supply list.
Horizontal directions must describe actual receiving faces and controls.

The minimum construction outline is:

| Work | Supplies and dependency boundary |
| --- | --- |
| Foot handoff | Prepared complete `foot` child |
| Shin seating | LG-100 on authorized handling support |
| Ankle flange | Four W-36/H-36090 pairs, washer before matching bolt |
| Main disconnect | One FA-605 complete harness after ankle fastening |
| Knee preparation | Two LG-130 bearings, then two LG-135 spacers |
| Fork and axle | LG-110 after spacers, LG-140 after fork |
| Axle retention | LG-150 plus two LG-W12/LG-H12050 pairs |
| Beam delivery | LG-120 after axle retention |
| Beam fastening | Four LG-W24/LG-H24100 pairs |
| Structural readiness | All leg slots, including harness and complete foot |
| Pelvis seating | Same prepared `left_leg`, delivered by rail |
| First retaining half | `ring_1` and pairs 3/4, or equivalent valid opposite-half order |
| Second retaining half | `ring_2` and pairs 1/2; no false cross-half prerequisite |
| Holder release and recovery | No new robot supplies |

Harness and knee work remain independent after ankle fastening. Manual page order
does not create dependencies. Both halves can independently seat and fasten after
the leg is seated. Recovery must remove dependent hardware before separating its
receiving component, preserving the same physical identities.

## Verification and acceptance ledger

The final [forward gate](../../game/workshop/verification/regressions-20261023T203841.362193Z/results.json)
passes 636 ordinary-input checks and 11 source-asset tests with unchanged run
inputs. The [journey evidence](../../game/workshop/verification/m3-independent-acceptance.json)
records 30 real-file/fresh-scene checkpoints, no staged player poses and no debug
fixture. It starts from the prepared foot and ends after full retention and
holder release. Human playtest acceptance remains separate.

| Requirement | Required evidence | State |
| --- | --- | --- |
| Prepared-foot-only opening | Exact supplied identities; empty leg/pelvis slots; normal M3 launch | Passed fresh opening and launch checks |
| Foot-and-shin representative loop | Walked ordinary input, supported transfer and interrupted restore | Covered by final fresh forward proof; earlier representative-loop evidence retained |
| Complete horizontal construction | All 42 slot/manual audit; actual reachable placement; independent order | Passed authoring, runtime HUD and fresh ordinary construction |
| Three crane loads | Rig, deliver, secure, detach and park for each load | Passed fresh forward journey |
| Loaded rail journey | Readiness gates, obstruction/Stop/pause and travel/tilt/dock | Passed fresh forward journey and bounded geometry checks |
| Both retaining halves | Separate carry/shelf/lift/fit/fasten loops, compatible swaps | Passed both actual lift trips and all four fastening pairs |
| Holder release | Complete ring permits holder release while the leg remains secured | Passed final forward endpoint and fresh-scene restore |
| Mistake correction | Retain support/dependency guards and existing undo | Implemented; full teardown verification explicitly stopped |
| Geometry and physics | Real support contact, swept clearances, growing-load collision, nested between-tick transforms | Corrected review passed 84 checks; final axle-grip refinement leaves installed/equipment geometry unchanged |
| Persistence | Detached rejection without mutation; fresh scenes across forward ownership and motion boundaries | Prior 174 staged checks/104 malformed snapshots; final 30 actual forward save/reopen checkpoints pass |
| Preservation | Foot pinned save/source assets and relevant shared-system checks | Pinned foot, launch and source checks pass; 85 baseline assets unchanged; completed M2/geometry checks reused |
| Human M3 acceptance | User replay of the complete runnable checkpoint | Ready for playtest; not yet accepted |

Final save checkpoints include foot handoff, partial rigging, crane transport and
fastening, rail motion, a loaded lift trip, both retaining halves and holder
disengagement. Full reverse interruption coverage is no longer a completion gate.
Reject contradictory ownership, task, endpoint, reservation and engagement states
before mutating the live scene. Protect incompatible saves until explicit reset.

Routine verification is headless. Rendered review runs only if explicitly
requested and is separate from human playtest and automated behavior evidence.

### Authoring checkpoint

The integrated `m3_content_test.gd` run passed 318 model/content checks, with evidence
in [m3-content-audit.json](../../game/workshop/verification/m3-content-audit.json).
It covers the 135-piece supplied foot boundary, all 42 installation slots,
independent harness/knee order, pooled washers, swapped retaining halves, wrong
variants, security milestones and complete supported model reversal. Hand-carried
leg components now return their consumed identities to hands at removal. The generator check
reproduced the new assets. All 85 captured existing source/content asset hashes
matched the starting commit `c12d8b4`. M3 source-rack positions now derive from
the authoritative M3 layout. The final generator and ordinary-input checks also
cover the later axle-grip/manual refinement. This is authored-data evidence;
the model setup helpers do not establish a playable construction journey.

### First integration checkpoint

The representative ordinary-control foot-and-shin loop passed 152 checks and
seven actual file/fresh-scene checkpoints. The route starts at dispatch, raises
and seats the prepared foot, rigs and delivers the shin, installs eight ankle
fasteners, reverses them through normal undo, returns the shin to its rack and
returns the same foot to dispatch. It also audits all 42 runtime manual slots and
HUD component quantities. The retained foundation evidence is under
`game/workshop/verification/`; the final fresh forward proof above supersedes its
partial-journey scope.

The first proof exposed and resolved active-build/save serialization and physical
walking/access issues. The separate snapshot suite exposed missing type guards
and cross-equipment interlocks. Carrier and holder support/contact/clearance
checks were subsequently completed in the corrected review below. Runtime repairs
stayed with the equipment owner; the primary owned the bounded malformed-snapshot
suite, runner and docs. This first proof preceded the remaining construction work.

### Geometry and validation checkpoint

The initial independent geometry review passed 69 checks against recorded input
hashes; its world-clearance coverage was subsequently corrected as described
below. It covered 81 carrier poses,
grounded positive foot support and withdrawal, all three crane rack/receiver and
runway support chains, 783 mounted meshes over 121 loaded poses, 163 holder
release/empty-return/reacquisition poses, both knee aisles, passive joint braces,
interchangeable geometry, payload/equipment obstructions and immediate physics
alignment. Minimum measured loaded floor clearance is 0.50000006 m. The empty
holder withdraws from the load before using its bounded left cross-slide; the
bogie stays on the active left track and the right-leg reserve remains clear.

The [save validation report](../../game/workshop/verification/m3-save-validation.json)
passes 174 staged checks, including 104 malformed snapshots and fresh scenes for
full retention, release, empty return and reacquisition. This suite explicitly
stages its model/holder states; the separate walked suite supplies ordinary-input
and real-file interruption evidence. The final forward gate supplies the current
walked interruption proof; the staged suite is retained as bounded earlier evidence.

The bounded [carrying-route check](../../game/workshop/verification/m3-route-clearance.json)
passes 19 checks with an actual two-hand PV-120 half. It walks both directions
around the crane console, reaches the leg work aisle and boards the lift through
its front ramp. Its complete-leg starting state is explicitly staged; this is
clearance evidence, separate from the full construction journey. Harness
insertion now passes ordinary pickup, walking and placement from the knee side
of the ankle, on the side away from the crane racks. The closer attempted stance
started the upright carried bundle against the ankle brace; no collision bypass
or brace removal was needed. The manual explains the successful approach.

Repeated direct diagonal walks in the full driver exposed avoidable fixture
collisions. The equipment and acceptance owners consolidated transitions between
stock/console, both fixture sides and the lift-front route. The final forward
proof uses those routes. Further connection-side recovery verification was stopped
by the later scope update.

The continuation has reached both separately carried retaining halves. It exposed
two integration omissions: inactive crane loads needed persistent visible/solid
rack bodies, and the second half's far fasteners needed a clearer lift work
position. The stock projection now passes 88 focused checks and the M2 crane's
63 checks. The M3 lift moves 0.25 m toward the hip, with its ramp, shelf and
controls following the authoritative origin. Height, size and M2 layout remain
unchanged. The [hip-access check](../../game/workshop/verification/m3-hip-access.json)
passes 23 checks: nine legal standing positions reach and see all four far-half
fasteners, and an ordinary local walk and four fastening actions succeed from
the working corner. Its initial retained-leg state is explicitly staged.
The 19 carrying-route checks pass on this layout. The earlier 69-check geometry
pass is superseded: it omitted the lift subtree from loaded-world comparisons
and checked empty-holder geometry only against the stationary leg. The corrected
74-check suite exposes loaded lift interference and empty holder/lift/floor
conflicts. Its failing evidence is preserved in
`verification/m3-geometry-world-before-fix.json`. Direct upright travel home was
rejected because it crosses the stationary robot.

An independent [trajectory probe](../../game/workshop/verification/m3-left-route-design-probe.json)
established a viable active-left contract: outboard lift guides, stepped holder
support, an explicit withdrawal bearing link and extra empty-holder tilt height.
It preserves the usable hip work area and original foot support width. The probe
passes 61 loaded world sweeps and 602 release/empty-return samples against world
geometry and the stationary robot; every sample has a connected support chain
from floor rails to ladder. Moving geometry remains at or left of x12.78, keeping
the reserved right lane clear. This is design-probe evidence. Runtime integration,
reciprocal sweeps and actual cantilever support were subsequently integrated and
verified as follows. The later user scope update removed full ordinary recovery
from the final gate.

The final independent [geometry report](../../game/workshop/verification/m3-geometry-review.json)
passes 84 checks: 61 loaded and 284 empty reciprocal world intervals, 345
support/physics samples, static robot clearances, and lift support chains at
ground, intermediate and upper height. The shifted lift uses two grounded
outboard guides with connected cantilever deck beams. The empty holder uses the
measured stepped support, bearing link and raised tilt path; its bogie remains
on the active left rail. Strict before/after world-pose checks apply to static
rail/carrier/brace supports. The kinematic passenger deck's shapes agree locally
immediately and globally after the physics step, preserving platform velocity
semantics. The [review](../../game/workshop/verification/m3-geometry-review.md)
records the evidence boundary and engine-source rationale. No rendered review
was requested or performed.

Prepared status pages now show actual assembly progress when their supply list
is empty, instead of a misleading `0 / 0` footer. The manual-navigation regression
passes 22 checks; the M3 runtime audit also checks this readiness count.

### Deferred reverse investigation

Before the scope change, ordinary controls had demonstrated the empty-holder
round trip/reacquisition, both retainer-half recoveries, loaded leg return and
beam source return. The subsequent fork-Up test failed after cap/axle undo. The
test had checked their identities and model locations but had not established
that their physical bodies had cleared the joint; a carrying/stance issue remained
an unconfirmed explanation. No production fix was made for that failure.
Full disassembly diagnosis and verification stopped at the user's request. The
retained diagnostic reports are historical, partial evidence, not M3 completion
criteria or proof of a complete reverse route.

## Delivery retrospective — 2026-10-24

The task had taken about 2 hours 24 minutes of recorded active time (about 2 hours
32 minutes of elapsed time) when the scope was narrowed. These
are approximate elapsed checkpoint windows from retained logs, not exclusive
effort accounting; implementation and reviews overlapped.

Final forward closure brought recorded task time to approximately 2¾ hours. The
final run passed 636 checks and 30 save/reopen checkpoints. Its only additional
product repair was the M3-specific axle grip; no further reverse work was done.
UTC timestamps span longer than recorded task time, so the larger wall-clock gap
is not treated here as measured implementation effort.

| UTC window | Elapsed | Main work and complexity |
| --- | --- | --- |
| 12:13–12:38 | 25 min | Initial implementation, content/save work and the first foot/shin loop |
| 12:38–13:32 | 54 min | Forward walking routes, carried-part approaches, crane transitions and far-half lift access |
| 13:32–14:24 | 52 min | Coupled lift/holder clearance; corrected geometry coverage; supported empty-return design and integration |
| 14:24–14:45 | 21 min | Full reverse-path driver, shelf transfer, completed-manual navigation and fork-return diagnosis |

The largest avoidable expansion was making complete teardown and the empty-holder
round trip completion gates. That drove substantial mechanism and test work beyond
the essential forward journey and local mistake correction. This was a scope and
sequencing mistake, not simply unavoidable implementation time.

The initial geometry suite also gave incomplete confidence: it omitted the lift
from important collision comparisons. A lift-access adjustment then exposed
interactions with the holder, guides and floor. Those mechanisms should have been
checked together before treating the layout as stable. One later lift assertion
also confused a kinematic target with its current simulated pose, causing a false
failure that needed an oracle correction rather than a runtime workaround.

Several delays were in the test driver: diagonal shortcuts through equipment,
too-close carrying stances, assuming a targeted shelf command had transferred
ownership, and using unfinished-work suggestions to select a completed build.
Retained checkpoints helped later, but the fresh forward proof came too late.
That proof exposed a real axle-grip issue: rotating the sideways-held shaft clipped
the holder spine. The M3-only lengthwise grip and stand-back approach address it.

For the next milestone: define the smallest player finish condition first; prove
each new handling type and work face in a bounded scene; run one complete fresh
forward journey early; keep undo checks local to correcting mistakes; and reuse
passing checks unless relevant inputs change. Give coupled equipment one spatial
owner and escalate a cross-system geometry problem after the first failed local
repair. Do not build a comprehensive reverse-verification project before the
forward milestone is playable.

## Ownership and integration

One equipment owner implements and integrates the coupled runtime, layout,
profile/staging/save behavior and representative loop. The content owner authors
M3 recipe patches, stock, manuals and audits against that contract. The primary
owns scope, integration acceptance, runner registration and documentation, with an
independent review of the integrated result. Return defects to their coherent
owner rather than distributing interdependent geometry repairs.

At each integration checkpoint record remaining design risks, evidence and any
reopened assignments. The full objective remains M3, even while the first proof
is smaller. Stop further expansion at the runnable M3 human checkpoint.
