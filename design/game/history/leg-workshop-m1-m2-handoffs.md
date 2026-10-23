# Leg workshop: historical handoffs (M1–M2)

Archived 2026-10-23 from [leg-workshop-next-steps.md](../leg-workshop-next-steps.md)
during the pre-M3 architecture consolidation. These records are kept verbatim
for context. File names, launch flags and test suites they mention may since
have been retired or renamed. The hoist leg workshop, M1 trial and `m1_*`/`m2_*`
modules no longer exist. The active plan and checkpoint table remain in the
continuation note.

## Delivery team and ownership

The user explicitly prefers stronger models when uncertain and has ample usage.
Use these assignments for execution; do not infer a resource cap from the earlier
retrospective. Model choices match the full outcome, including integration and
verification. Planning reviews used Astra/xhigh for spatial feasibility, Sol/xhigh
for interactions and Astra/high for validation; they made no gameplay changes.

The primary coordinates decisions, owns this active plan and cross-system
acceptance, reviews evidence and resolves conflicts. Implementation and repair
remain with the responsible owners. Do not routinely move unfinished integration
back to the primary.

| Owner | Model / effort | Coherent outcome and file ownership |
| --- | --- | --- |
| A: spatial/equipment integration lead | `gpt-6-astra` / `xhigh` | Complete supported leg journey, fixture/rail/tilt/dock geometry, personnel access, retaining-half prototype and equipment persistence. Own `leg_workshop_layout.gd`, `leg_equipment.gd`, affected `supported_fixture.gd` / `work_access_lift.gd`, and integration edits to `workshop.gd`, `assembly_model.gd`, `assembly_runtime.gd`, `component_interaction.gd`, `hud.gd`, `workshop_save.gd` and `save_model.gd` only as needed. Own the relevant equipment/lift/build/save behavior checks. |
| B: crane interaction owner | `gpt-6.1-sol` / `xhigh` | Complete magnetic rigging, central console and one reusable crane transfer, with its own motion/attachment state, validators and focused tests. Own new dedicated crane/rigging/console scripts. Consume A's anchors, routes and support rules; deliver clear integration calls/signals to A rather than editing A's files independently. |
| C: assembly content/manual owner | `gpt-6.1-sol` / `xhigh` | Author compatible supports, rigging metadata and instructions for the new workflow. Own `tools/author_leg_prototype.py`, generated `leg-prototype-definitions.json` / `leg-prototype-content.json`, affected generated catalogue data, `leg-prototype-interface.md` and focused content/audit tests. Coordinate support IDs and metadata with A/B before generation. |
| D: independent acceptance reviewer | `gpt-6-astra` / `high` | Review the integrated player journey, attack support/restore invariants and report failures with reproductions. Own separately named acceptance tests if needed; do not edit implementation concurrently. Start after a slot is free. |

There are four concurrent slots including the primary: run A/B/C together, then
reuse C's freed slot for independent D once its content handoff is complete.
Do not add another parallel persistence or spatial team. A integrates B's complete
module and C's data against the agreed contract; B remains responsible for fixes
inside its crane module. Each equipment owner implements its own capture,
validation and restoration; A owns the world-save seam and combined validation.
Subagents do not delegate further unless explicitly assigned.

### Shared contract before parallel implementation

A owns the coordinated layout and resolves the contract with B/C. Record the
agreed values in this plan or the existing interface specification; source code
and authored metadata retain their normal authoritative roles. Do not create
another next-steps document.

- Coordinate frames, fixture pivot/poses, source racks, receiving contacts,
  attachment points, complete swept envelopes and reachable operating positions.
- Stable support IDs and compatible source/destination declarations. Model
  ownership transfers exactly once: rack -> crane -> receiver, or rail fixture
  -> seated/secured parent. Workshop cable ends do not create robot inventory.
- One authority moves each loaded assembly. Rigging or the assist arm never
  competes with a second carry/physics transform.
- Equipment actions, availability/error reasons, state/status signals, input
  candidates and console lifecycle. Reuse E/click/Q and existing reach/occlusion
  rules. A wires desktop dispatch; B owns console/rigging implementation.
- Versioned equipment snapshot fields: phase, progress, relevant poses, load ID,
  engaged contacts, rigging endpoints and reserved source/destination. Validate
  against a detached saved model before replacing live state.
- Per-half retention and whole-hip release rules, manual step references,
  return/undo outputs and behavior when paused, blocked or interrupted.

A/B/C may choose implementation details within these constraints. Preserve user
choices; do not replace bolted rings, add a new control mode, assume a PDA unlock
system, or silently treat the proposed retaining arm as an accepted final design.

### Execution waves

1. **Spatial contract and risk proof.** A solves the loaded horizontal/tilt/dock
   geometry and player routes. B defines the concrete console/rigging journey;
   C audits required support/manual changes. Integrate their conclusions before
   committing to equipment placement or multiplying operations. Produce the
   runnable layout/motion blockout and stop at human checkpoint M1 below.
2. **Representative implementation.** A builds rail handling and the retaining
   interaction with save/undo from the start. B builds the crane module against
   the agreed anchors and support API. C authors the matching data and manuals.
   Each owns focused checks. A integrates the actual player journey, including
   shared scene/input/save files; tests staged through direct controller calls
   alone do not complete this wave. The first complete leg journey depends on
   both B's real LG-120 crane handoff and the retaining-half interaction below;
   the numbered work packages are not separate claims of end-to-end completion.
   Geometry tests may stage a populated leg, but final journey acceptance may
   not bypass these new construction/retention interactions. Stop at M2 when the
   first crane and retaining-half interactions are ready, before expanding them
   or committing to the proposed assist arm as the final interaction.
3. **Independent review and repairs.** After C's handoff, D reviews a stable
   integrated slice. Return implementation findings to A/B/C in coherent batches;
   reassign C only when content repair is needed. The primary verifies fixes and
   technical evidence, then stops at M3 for human assessment of the combined
   journey. Technical acceptance does not replace this requested human check.
4. **Expand existing content and regress.** Apply the proven interaction to the
   remaining current equipment-handled parts, then run affected regressions and
   normal-launch checks. Keep new body branches and PDA progression deferred.
   Stop at M4 for the final human playtest before marking the iteration accepted.

Each handoff includes owned files, decisions, runnable checks, evidence paths,
remaining issues and integration instructions. At the representative-loop
checkpoint, record remaining design risks, rework/handoffs and available usage;
reassess owner/model capacity if coupled work expands. Do not downgrade an owner
merely to keep all slots busy.

### Initial M2 implementation handoff — 2026-10-23 (historical)

The following records the initial implementation and its checks. Its carrier and
console procedures are superseded by the feedback revision above.


Both examples are implemented and verified. The final headless run passed
**52 cases / 5,944 checks**, with code/asset inputs unchanged throughout. Report:
`game/workshop/verification/regressions-20261023T064526.893787Z/results.json`.
This is the M2 equipment checkpoint, awaiting human feedback. M3 is unstarted.

Launch from the repository root:

```sh
./play.command -- --m2-workshop
```

The selector opens before the world loads. Choose **Resume / start Hip retainer**
or **Resume / start Crane delivery**; each **Reset** button resets only its named
example. After entering a trial, use the pause menu's **Choose M2 trial** to save
and return to the selector. A failed save prevents switching. Saves are separate:
`user://m2-retention-save.json` and `user://m2-crane-save.json`. Normal, foot and
session-only M1 profiles remain separate; incompatible files are protected.

**Hip retainer route.** This example supplies the complete 165-identity structural
leg on its home rail, one retaining half and its two washer/bolt pairs: 170 physical
identities total. The pelvis seat starts empty. Walk the rail controls through
travel, tilt and docking; docking performs a real model/runtime mount into pelvis
while the holder continues assisting. Board the lift, collect the hardware and
use E to acquire the half with the visible guided carrier. Aim/click seats it;
fit both washer/bolt pairs normally. Q releases the now-empty carrier. E on the
fastened half reacquires assistance; Z in the pelvis manual removes hardware and
seating, and Q returns the same half to stow. Return then unseats the leg onto its
real rail support and reverses docking, tilt and travel. Try blocked Advance and
Return while retention remains fitted, and Q before the half is fully fastened.

**Crane route.** This example supplies 156 staged identities: the finished foot
and the horizontal shin/knee/fork/cap graph. The real Upper-leg beam and all eight
flange fasteners remain to fit: 165 total identities. At the central console call
the crane, walk to the rack, E-pick and aim/click each magnetic end onto a marked
point; Q stows a held end. Either end fits either free point. Walk back to command
transfer, then fit the four ordinary washer/bolt pairs at the receiving flange.
E detaches each end after fastening; Q stows it. Park the empty crane at the console.
Before fastening, loaded Return recovers the supported beam; fitted hardware must
be undone with Z before Return can unseat it. Try Stop/resume, partial rigging and
blocked commands. The physical console closes when the player leaves reach or
visibility, Q closes it, and Escape preserves pause behavior.

Support remains continuous: actual beam saddles replace the old rack gap; source
ownership remains until both magnets take weight, receiver contact precedes the
final .20 m axial seating, and crane assistance remains through fastening. The
carrier stays with the same half through placement and supported removal. The
accepted rail/lift geometry is preserved; no sample capture frame or appearing
support substitutes for retention. Real rail, crane and carrier support IDs are
used instead of the legacy rack-install shortcuts.

Focused owner checks passed: content **102**, retention controls **156** across
both compatible half UIDs, retention saves **609** across 16 captured states,
crane service/controls/saves **45 / 89 / 87**, and independent acceptance **48**
plus **128** malformed nested-field attacks. Native disk save/fresh resume,
immediate and next-tick descendant physics, isolated resets, wrong/occupied
targets, interrupted movement and zero-mutation rejection were exercised.
The complete runner also passed normal/foot/M1 launches, the M2 selector and both
example launches, all existing build/manual/save suites and the earlier desktop
scenarios. The 128 malformed-field attacks are additional to the 5,944 check
count. `git diff --check` passed. Preservation fingerprints confirm 22 unchanged
files, including the original root README/GAME_DESIGN edits, legacy content and
equipment/save resources, and preexisting M1 scripts/tests; evidence is
`game/workshop/verification/m2-preservation-audit.json`.
Evidence is under `game/workshop/verification/`: `m2-content-audit.json`,
`m2-retention-*-audit.json`, `m2-independent-acceptance.json`,
`m2-crane/summary.json` and adjacent logs/hashes. Manual pages cover exactly five
retention and nine crane installation slots; status pages add no supplies.

Known boundaries: one half never secures the whole hip, and holder departure,
both-half handling, additional crane loads and the combined construction journey
remain M3. Released-beam reacquisition/full disassembly remains M3; reset the
crane example to replay from stock. All geometry is still procedural blockout.
Automated behavior and contact checks do not establish visual or human acceptance;
no rendered review was requested or performed.

Assess these three points before authorizing another milestone:

- Are magnetic attachment, central-console tasks and the walks understandable?
- Does the guided carrier's pickup/seat/release/reacquire/undo flow feel natural?
- Do blocked commands explain the remaining work while preserving the rail and
  elevator experience accepted in M1?

Execution review: A retained every coupled runtime/spatial/save implementation
and repair; B delivered the crane module, C delivered content, and D independently
attacked the integrated state and contacts. The representative loop exposed
drawer/control access issues; owner and independent checks then repaired unsafe
save-field comparisons, native restore transforms, carrier contact/approach and a
StringName key rejected by actual disk serialization. The first full run found
one legacy prompt-label regression; A repaired it and the final complete rerun
passed. No runtime implementation fell back to the primary. One server restart
was recovered from saved files. About one hour elapsed; per-agent usage/cost was
unavailable. All agents have handed off and stopped at M2. Preserve the human
checkpoint before expanding operations or choosing the carrier as final design.

### M2 implementation brief — implemented; retained design contract

The user authorized implementation and verification after the planning handoff.
Execution used A (`gpt-6-astra` / `xhigh`) for the complete spatial/runtime/save
integration, B (`gpt-6.1-sol` / `xhigh`) for the crane module and C
(`gpt-6.1-sol` / `xhigh`) for generated trial data and manuals. D
(`gpt-6-astra` / `high`) independently reviewed the integrated examples. The
existing 15 modified/untracked files were
snapshotted before work; original planning edits remain preserved. The primary
owns this continuation record, launch documentation and final regression review.
The intermediate notes below are historical; final results are in the M2 handoff.

Representative-loop checkpoint: the first walked retention loop passed 45 checks,
including real pelvis mounting, carrier pickup/seating, supported undo/stow and
loaded Return. Save validation covered moving rail/lift and the carrier states.
At that intermediate point, fastening/release/reacquisition, crane integration,
fresh-scene recovery and independent attacks remained in progress. Content passed
102 M2 checks and 373 legacy leg checks. About 18 minutes elapsed to this point,
including one server restart recovered from saved files. Per-agent usage was not
available. Spatial integration and fixes remained with A; no runtime work fell
back to the primary. D then reviewed independent ownership/restore risks.

**Deliverable and boundary.** Deliver two separately resettable, saved examples:
one retaining half fitted, bolted, supported during removal and returned to stow;
one real crane delivery of LG-120, the **Upper-leg beam**, followed by ordinary
flange fastening and cable release. Stop all agents at the combined M2 handoff
for human feedback. Do not expand to other crane loads, the second retaining-half
workflow, whole-holder departure, a full construction journey or PDA progression.
One fastened half must never be presented as a secured hip. Both-half completion
and the real empty-holder route remain M3; no fabricated second-half completion
or sample capture frame substitutes for them.

**Launch and staging.** Use one M2 entry,
`./play.command -- --m2-workshop`, with **Hip retainer** and **Crane delivery**
choices before the world loads. This entry is implemented. Each
example has its own clearly labelled resume/reset slot:
`user://m2-retention-save.json` and `user://m2-crane-save.json`. Keep normal/foot
profiles and the accepted, session-only M1 launch intact. Switching examples must
not reset the other's progress. Disclose supplied construction on each start card.

- Hip retainer starts with the complete existing leg on its home rail, not
  already fastened or secretly mounted. Pelvis seating/retention starts empty.
  Supply one representative half and its two washer/bolt pairs; keep the unused
  half outside the playable example rather than showing an uncollectable teaser.
  Automated replay swaps the compatible half UID without inventing a variant.
- Crane delivery starts with the completed foot and the horizontal leg through
  shin/knee/fork/cap. Derive staging from the authored graph, excluding `spar`
  and `fork/*` additions (currently 22 pre-spar leg slots). The sole LG-120
  remains real rack stock; all four LG-W24 washers and LG-H24100 bolts remain
  collectable. Do not supply an already-installed beam or auto-fit its hardware.

**One coordinated spatial contract.** A owns all rack, cradle, rail, carrier,
lift and travel geometry. Preserve accepted rail X11.9, knee-home Z14.5, bay Z26,
lift `[9.6,0,24.3]`, 2.6 m square deck and .15/8.4 m stops unless a measured new
interaction requires a documented bounded change. Agree support IDs, exact
contacts, swept volumes, pickup/work positions, input priority and snapshot
versions with B/C before parallel implementation.

The existing beam rack is a reservation, not a proved source fixture: its stands
end at Y.96 while the horizontal beam stem underside is Y1.25, leaving roughly
.29 m at the near stand. A must author actual mesh-contact saddles and receiving
contacts, clear the hip ball and preserve access to both magnets, flange tools,
rail jaws and the 1.2 m knee aisle. Do not add decorative rigging to an unsupported
load. Use the existing provisional source/receiver/magnetic-point table in the
interface specification as the starting geometry. Final seating is the .20 m
axial approach toward −Z; a vertical drop cannot mate these horizontal flanges.

**Hip-retainer player loop and model seam.** Implement this representative loop
before expanding content or carrier mechanisms:

1. Walk the rail controls, travel, tilt and dock. At the verified authored mount
   pose, install the leg from its real rail support into `pelvis.left_leg` and
   runtime-mount it without a pose jump. The pelvis becomes the sole model parent
   and transform authority; the holder remains visibly engaged as assistance.
   It must stop independently writing the mounted leg's transform.
2. Board the lift, collect hardware normally and use E to acquire the half with
   a visible lift-mounted guided carrier. Aim/click seats it through normal
   reach, occlusion and supported approach checks. The carrier supports the same
   UID continuously; installed ownership transfers to pelvis exactly once.
3. Fit that half's two washer/bolt pairs. Keep carrier assistance until all four
   hardware identities are installed. Q can retract the empty carrier only then;
   E on the secured half reacquires assistance before undo. There are no separate
   arm-joint controls and no new permanent part-specific button cluster.
4. Use **Z**, the existing manual-scoped undo, to remove hardware and then seating
   while the carrier is engaged. Q returns the now carrier-owned half to its stow.
   Q on a partly fastened seated half explains what must be completed or undone;
   it cannot silently drop or uninstall it. Backspace remains manual-parent
   navigation. Check wrong variants, either equivalent UID and occupied stow.
5. Any fitted half/hardware blocks loaded Return and holder departure. After the
   last retention part is removed and the carrier is clear, Return must perform
   real supported undo of the pelvis seat, reparent the leg to the rail at its
   unchanged world pose, refresh physics/collisions and then reverse docking.
   Seated with no retention must also allow this recovery. Holder departure
   remains unavailable with this one-half example; no external stabilizer or
   appearing receiver is added.

Carrier states must distinguish stowed, carrying an uninstalled half, assisting
an installed half, and released after that half is fully bolted. Assistance is a
physical contact, not a second inventory owner. Interlock lift/rail/carrier
movement where simultaneous operations would break contact or collide. Rejected
commands explain the reason in physical panels, prompt and toast without changing
UID, ownership, history, pose or active movement.

**Crane player loop and ownership.** At the central physical console call the
beam, walk to the source, E-pick and aimed-click each magnetic end, and Q-stow a
held end. Either end can use either free compatible point; duplicate occupation,
wrong points and competing hand payloads are rejected. Walk back to command the
transfer, then to the receiver to fit all four flange washer/bolt pairs and
detach/stow both cables. Park the empty crane. Console requests recheck reach
and visibility; walking away closes/disables it. Preserve Escape's pause behavior.
Commands remain independent of console UI for a future PDA.

Ownership moves once from `leg_spar_rack` to the real crane support, then to
`left_leg.spar`. Both endpoints must be engaged and the crane visibly taking
weight before the rack releases. The receiving cradle takes contact before
installation; the crane remains assisting until all four fastener pairs are
secured. Cable ends are equipment, not robot inventory. The rail stays home and
rejects movement while crane rigging is attached or the beam connection unsecured.
One authority moves each load.

Stop/pause/obstructions preserve support and progress. Before seating, Return
recovers the suspended beam to its rack. If seated with no flange hardware and
still crane-assisted, Return first performs real supported undo of the beam slot,
then reverses the axial approach and travel. Any flange washer or bolt blocks
load Return until normally undone. Unsupported installation undo is rejected;
manual Z and console Return must share the same assistance/ownership rules.
Stowing ends/parking the empty crane are distinct from returning a load. Full released-beam
reacquisition and disassembly can wait for M3. Remove the current direct
`leg_spar_rack` → `left_leg.spar` authorization and `install:UID` shortcut from
the **M2 profile**, so magnetic handling cannot be bypassed.

**Content, controls and persistence.** C authors generated M2 overlays/scenarios
through the authoritative generator, leaving legacy output/fingerprints intact.
Authorize real rail, crane and carrier sources/undo outputs; do not alias them to
`leg_hoist` or ring racks to satisfy old validators. Preserve kind/physical IDs;
use Upper-leg beam in player-facing text. Update only the two examples' manuals:
one beam plus four flange pairs, and one half plus its own two pairs. Preserve the
existing ring mapping (`ring_1`: pairs 3/4; `ring_2`: pairs 1/2), compatible halves,
pooled washer stock, unique slot coverage and overview pages without supplies.
Full horizontal construction/foot-handoff instructions remain M3 work.

A owns desktop dispatch and all shared scene/model/runtime/HUD/save integration;
B owns dedicated crane/rigging/console files and tests; C owns data/manuals/audits.
Agree an adapter using existing conventions: `action_error`, `request`,
`controls`/candidates, status/changed signal, `physics`, `capture`, detached-model
`validate`, and `apply`, with an equipment-aware hook before generic manual undo.
Allow one hand payload across ordinary components,
magnetic ends and the retaining carrier. B/C deliver against A's agreed contract
and do not independently edit A's shared integration files.

Persistence is part of M2 from the first loop. Use explicit scenario/equipment
versions and independent fingerprints for both trial slots. The legacy
`workshop_save.gd._validate_leg()` assumes upright hoist poses and equipment;
reusing it unchanged is insufficient. Reuse storage/model validation where valid,
with a trial codec/adapter that validates a detached saved model and the complete
saved world before touching live state. Save rail phase/progress/goal, parent and
assisting contacts, carrier occupant/pose/phase, crane route-profile version,
segment/progress/load/beam, source/destination reservations, endpoint stable IDs
and stowed/held/attached point states, player/lift and manual state. Derive cable
lengths from validated poses and routes from authorized motion profiles; reject
invented waypoints or contradictory ownership/fastening. Restore parent-first
into a fresh paused scene. Preserve incompatible saves with an explanation;
never reinterpret old hoist saves or overwrite them with a trial.

**Execution, checks and human stop.** Keep the existing A/B/C/D execution model
and file ownership above. First agree contacts/API/data/save contracts; A then
proves real dock → half acquisition → seating → supported undo → loaded Return
through ordinary controls. B can implement the independent crane module and C
the agreed overlays/manuals concurrently. Integrate one walked crane loop;
then D independently attacks the stable examples and owners repair their files.
Review elapsed time, available usage and rework before expanding anything.

Generator/definition audits precede behavior checks. Add focused trial tests for
normal walked E/click/Q/Z, console lifecycle, partial rigging, wrong/occupied
targets, actual contacts/sweeps, stop/blocked/reverse handling, every retention
interlock and failed-input atomicity. Compare all mounted descendant scene/mesh/
physics poses, including between input and physics ticks. Fresh-scene restoration
must cover moving rail/lift, a half on its carrier, seated with zero/partial
hardware, carrier released/reacquired, a held cable, one endpoint attached,
suspended transfer, stopped/blocked travel and seated/partly fastened beam.
Malformed snapshots must produce zero live mutation. Tests may stage unrelated
construction; they may not bypass the new pickup, rigging, fastening or undo.

Proposed new cases: `m2_retention_controls_test`, `m2_retention_save_test`,
`service_crane_test`, `m2_crane_controls_test`, `m2_crane_save_test`,
`m2_acceptance_test`, plus selector and both example launch smokes. These are
planned names, not existing tests. Reuse affected existing `leg_content_test`,
`supported_model_test`, `access_lift_test`, `nested_runtime_test`, `save_model_test`,
`save_store_test` and M1 suites, then run the complete runner and `git diff --check`
once integrated. Retain separate logs and hashes; bounded controller tests do not
replace the actual walked desktop route. No future check is claimed passed now.

At handoff provide exact launch/resume/reset instructions, the supplied-construction
boundary, a short route for each example, current evidence and known limitations.
Ask the human to judge magnetic attachment/console walks, carrier pickup/placement/
undo complexity, and retention-error clarity while preserving lift satisfaction.
Stop all agents for that M2 feedback before repeating other loads or committing
the assist design. Rendered review remains by explicit request. This brief was
authored before implementation; current results are in the M2 handoff above.

### Current M1 correction handoff — 2026-10-23

The selected corrections are implemented. The holder visibly supports the same
leg through travel, tilt, upward docking and loaded Return. The synthetic
receiver, capture ownership, automatic empty-holder loop, spare lane and crossrails
are removed. The existing rail journey, lift footprint and work stops are retained.
The reserved rack is labelled **Upper-leg beam**, with an explanation that this
knee-to-hip beam is already fitted to the supplied sample.

At docking, **Advance** is rejected with “Secure the hip retainers before releasing
the holder.” Both consoles, the aim prompt and the E/click error explain the gate.
**Return** can withdraw the unfastened leg on its holder. Any fitted retaining half
or associated hardware blocks Return; both halves and all four washer/bolt pairs
are required for complete-retention classification. Rejected commands preserve
the pose, motion and physical identities. Panels refresh when the model changes.

M1 still has no player fastening, mounting or holder-release interaction. Its
playable endpoint is docking; there is no substitute capture or attachment-complete
button. Tests alone stage real pelvis ownership and compatible retention parts to
verify the gates. A complete staged fixture is reported as complete, with an
explicit message that holder release is outside M1. Deliberate mounted-leg
recovery and empty-holder departure remain later interaction work.

Launch from the repository root:

```sh
./play.command -- --m1-blockout
```

Choose **Start trial**. This remains a disclosed preassembled, session-only sample;
quit and relaunch to reset it. No normal save codec or saved progress is used.

1. Inspect the horizontal station and the **Upper-leg beam** reservation. Use
   **E or click** on Advance / Stop / Return; try Stop and partial Return.
2. Follow the west aisle and Advance through the three motions: travel, tilt,
   docking. Try Advance again. The holder must stay attached and the error must
   explain why; no supports should appear and no empty-return loop should begin.
3. Board and ride the lift using **Up / Ground**, inspect hip access, then use
   Return three times to lower, tilt and bring the same supported leg home.

Assess whether the supported dock-and-return journey is now understandable,
whether the reservation label explains the upper-leg beam, and whether the rail
and elevator experience you liked is preserved. Actual retention and crane
interaction still await M2; this correction does not accept or begin that wave.

Focused checks passed **269 checks plus launch**: 28 core, 55 ordinary controls
and 186 acceptance checks. Evidence covers 725 load meshes, 111 collision shapes,
368 forward/reverse motion samples, 245 independent pose observations, at least
.4999998 m load floor clearance and 3.125 m conservative separation from the
reserved rack. All eight authored hip fastener targets retain safely grounded,
visible work positions within ordinary reach. Retention checks use real model
installation/undo in both half orders, including the first half at a stopped
near-dock boundary. They do not claim playable fastening.

The independent reviewer reran controls and acceptance with no blocking finding;
evidence is `game/workshop/verification/m1-corrections-independent-review.json`
and the adjacent review logs. The complete regression run passed **42 cases /
4,808 checks**, including normal/foot/M1 launch and all existing build, equipment
and save suites, with unchanged input hashes. Report:
`game/workshop/verification/regressions-20261023T034358.163075Z/results.json`.
`git diff --check` passed; normal save fingerprints were unchanged through final
validation. Original root README/GAME_DESIGN edits and legacy fingerprinted
equipment, content and save resources are preserved. No separate agent-rendered
review was requested or performed. The user's subsequent replay accepted the
corrected M1 layout; new M2 interaction usability remains unassessed.

One spatial/equipment owner (Astra/xhigh) retained all runtime, test and repair
work; an independent reviewer (Astra/high) checked the frozen slice. The primary
updated this existing plan/interface and performs final regression validation.
Existing uncommitted work was snapshotted before edits. The integration checkpoint
reported 13 minutes elapsed and 280,280 goal tokens; per-role cost data was
unavailable. No new planning document, content regeneration or M2 interaction was
introduced. Both agents have handed off and stopped. The user subsequently
accepted M1 and requested the M2 plan above; M2 implementation has not started.

### Initial M1 handoff — 2026-10-23 (historical)

The initial route and results below describe the superseded sample-capture
blockout. Use the correction record for the current playable boundary; these
historical passes do not validate the requested corrections.

The isolated, runnable blockout is implemented and its focused checks pass.
M1 is **awaiting human feedback**, not accepted. No M2 work has started; crane
rigging, retaining-half handling, revised construction manuals and equipment
persistence remain held. The original feedback and positive lift findings above
remain unresolved player-facing acceptance criteria.

Launch from the repository root:

```sh
./play.command -- --m1-blockout
```

Choose **Start trial**. The scenario supplies the complete existing structural
left leg: **165 installed physical identities**, including the foot, both heel
pads, pitch actuator and all structural hardware. The ten pelvis-retention
identities remain uninstalled. This is disclosed staging for scale/motion review,
not completion of the new construction journey. M1 constructs a codec-free,
session-only adapter: no save/resume, normal-save loading or normal-save writes.
Quit and relaunch to reset the sample. Ordinary `./play.command` continues to
select the normal workshop; `./play.command -- --foot-workshop` retains the foot
profile. Legacy fingerprinted layout/equipment/lift scripts, generated content,
GLB and save codecs are unchanged. The pre-existing uncommitted planning edits
were preserved; the root README and GAME_DESIGN edits remain byte-for-byte intact.

Try this route:

1. Walk around the horizontal leg, marked foot-loading position and 1.2 m knee
   extraction aisle. Trace the shaft-contact jaws through the rotating ladder,
   telescoping mast, bogie and rails. The foot-loading mark reserves a handoff;
   the actual foot transfer is not implemented in M1.
2. Aim at **Advance / Stop / Return** near the station and use **E or left click**.
   Advance starts one named motion. Try Stop partway and Return to reverse the
   partial motion. Escape pauses movement. If the route is blocked, step clear;
   retry Advance or use Return to recover.
3. Follow the west aisle to the final-bay panel. Advance through travel, tilt and
   upward docking. Further advances engage the explicitly labelled **sample
   capture frame**, withdraw the empty fixture, traverse west, tilt and return
   it home. This receiver substitutes for retention only in the scale trial;
   it does not install the split ring or establish a secured hip.
4. Walk to the front of the personnel lift, board via its ramp and use onboard
   **Up / Ground**. Inspect access at 8.4 m, then return to the bay panel and use
   repeated Return to retrace the empty route, reacquire the same load and bring
   it back to the horizontal station.

Assess these three questions:

- Can you understand where the leg goes and what supports it throughout travel,
  tilt, docking, capture and empty-fixture recovery?
- Do the station, foot-loading position, walking routes and machine movements
  convey the intended workshop scale, with enough room to work?
- Does boarding and riding the lift preserve the satisfying ascent and provide
  useful hip access? Flag awkward views, walks, labels or controls.

The coordinated dimensions are recorded in the
[provisional interface contract](leg-prototype-interface.md#provisional-m1-layout-and-support-contract--2026-10-23).
The final sample uses active rail X11.9, empty return lane X6.3 and a front-left
2.6 m square lift at `[9.6, 0, 24.3]`, yaw π. Empty withdrawal includes a .40 m
rearward bogie detour before transverse travel, keeping the lift clear. The
future 19.4 m crest has 1.2 m clearance to the reserved overhead underside.
These choices remain provisional until M1 feedback; the right leg, crane console,
thigh source, arm approaches and rear access are reservations only.

Current evidence (Godot 4.7.2, headless; **no rendered review**):

- Content audit passed without regeneration; native content checks passed 373.
  Evidence: `game/workshop/verification/m1-content-contract-audit.json` and the
  current regression report's `leg_content_test` log. B's generated-mesh crane
  reservation probe and log are under `verification/m1-crane-contract/`;
  they establish bounded geometry plausibility, not crane gameplay.
- Core M1: **46 checks**, 840 forward/reverse samples, 725 actual load meshes,
  111 collision shapes and at least .5 m load floor clearance. Includes thin
  obstacles, supported recovery, pause, matching proposed/visible machinery,
  socket tilt clearance and the extraction aisle.
- Ordinary controls: **32 checks**, walking from spawn without player teleports,
  actual E/click travel/Stop/Return, sample capture and empty return, ramp
  boarding and occupied lift ascent/descent.
- Independent acceptance: **33 checks / 323 pose observations**, including
  untagged foot context, support connectivity and actual jaw contacts, nested
  scene/physics poses, empty-fixture/load separation, receiver/lift separation,
  save isolation and build-input guards. All eight authored hip fastener targets
  have safely grounded, unobstructed work positions within ordinary reach.
  Immediate capture → Stop → Return reacquires rail support before lowering.
  Evidence: `game/workshop/verification/m1-acceptance-audit.json`.
- Complete runner: **42 cases / 4,650 checks passed**, with unchanged input
  hashes, including default/foot/M1 launches and all existing build/save suites.
  Report: `game/workshop/verification/regressions-20261023T003301.300042Z/results.json`.
  `git diff --check` passed. Presentation readability, believable support,
  comfort and scale have not been visually or human-approved.

Reproduce the focused checks with:

```sh
python3 game/workshop/tools/run_regressions.py --only m1_blockout_test m1_controls_test m1_acceptance_test m1_blockout_launch
```

Execution review: A/B/C ran in the planned parallel roles, then D used C's freed
slot. A retained all coupled implementation and repairs; the primary integrated
documentation and reviewed evidence without taking over runtime implementation.
Review found and repaired mast connectivity, lift/load interference, empty
post/foot interference, hip reach/occlusion and the immediate-capture recovery
boundary. Roughly 38 minutes elapsed from the preserved baseline snapshot to
final verification; the complete runner used 119.91 seconds across its cases.
Per-agent token/cost metrics were unavailable. Remaining risks are the human
scale/support/control assessment and the explicitly held M2 interactions. All
owners have handed off and stopped; await feedback and explicit go-ahead.

### M1 player feedback — 2026-10-23

The user reports: “I love the rails and elevators.” Preserve these as positive
findings when refining the layout and later interactions. This does not establish
acceptance of every route, control or hip connection.

The user also asked why M1 uses a separate launch command and whether attaching
the leg to the hip can be tested. Clarified that the command isolates the staged,
session-only trial from normal workshop progress. Advance through travel, tilt
and Dock upward tests ball/socket positioning; the next Advance uses the labelled
sample capture frame. Actual retaining-half installation and bolting are not
playable in M1. Their usability and the complete hip-retention journey remain
outstanding for the later checkpoints. No additional implementation or M2
go-ahead was requested; remain stopped for feedback.

Additional M1 comprehension feedback:

- The user sees supports appear from nowhere after the leg enters the socket.
  Confirmed implementation shortcut: the entire sample receiver is hidden until
  capture, then shown instantly, without a deployed/stowed mechanism. Its label
  does not make that handoff understandable. This is an unresolved presentation
  issue, not accepted support behavior. The real workflow still requires bolted
  split-ring retention and stabilization before the rail fixture releases.
  The subsequent decision below selects removal of this placeholder handoff;
  keeping or animating the extra capture frame is no longer the proposed fix.
- The empty holder's return loop is unclear, and the user reports it goes through
  the thigh-spar source area. The loop withdraws, traverses aside, tilts and
  returns to avoid sweeping through the standing leg and personnel lift; it
  performs no collection task at that source. LG-120, labelled thigh spar, is the
  main upper-leg structural beam between knee and hip, including its integral
  ball. The reserved rack is empty because that piece is already in the staged
  leg. Terminology, separation of the rack from the empty return path, and any
  actual rack/holder intersection require review; passing bounded headless
  checks does not dismiss the observed confusion or establish visual clearance.
  Consider a clearer player-facing name such as upper-leg beam. No route or
  naming change is implemented yet.

Rails and elevators remain positive findings. M1 acceptance and M2 go-ahead
remain pending; this feedback has been recorded without advancing implementation.

### Selected holder-release behavior — M1 feedback, 2026-10-23

The user specifies that the holder continues supporting and moving the leg until
it is attached to the pelvis. No extra supports should appear after socket entry.
Once attachment is secure, Advance releases the holder's implied latches and
moves the empty holder away; latch animation is unnecessary. Console errors
must explain blocked Advance and Return commands.

Use these distinct gates:

- **Seated, no retention fitted:** the leg remains supported by the holder.
  Return can withdraw the same leg. Advance past docking is blocked, with an
  instruction to attach the leg to the pelvis.
- **Retention partly fitted:** block both holder departure and loaded Return.
  Beginning attachment is enough to prevent pulling the leg away, but is not
  enough to release its support.
- **Retention complete:** both retaining halves and all required washer/bolt
  pairs are fitted. Advance may implicitly unlatch the holder and move it empty,
  leaving the leg attached to the pelvis. Return must not pull the attached leg
  away; display an error while retention remains fitted.

Ball/socket seating alone does not count as fastening. Use complete existing
retention as the release condition rather than an arbitrary first part or bolt.
This decision supersedes the M1 sample receiver and the proposed extra external
stabilizer command as prerequisites for holder departure. Later deliberate
disassembly must still acquire holder support before undoing retention; its
recovery interaction remains to be reconciled with the Return restriction.

The corrected M1 implements the holder-support and rejection rules, removes its
sample receiver and discloses that player fastening and holder release are still
outside this trial. See the current correction handoff above for the runnable
boundary and current evidence. The complete future release/retention interaction
is not made playable by test-only model staging.

## Delivery lessons for the next session

The preceding goal recorded 66 minutes 26 seconds and 1,047,608 tokens. It used
three implementation agents, 12 follow-up assignments and 25 root-to-agent
messages. The final complete regression run took about 75 seconds. These are
recorded usage figures, not a monetary cost estimate.

Technical ownership was split across content/interfaces, support/equipment and
access lifts/persistence. Several support structures, routes and actual control
checks were resolved late. The primary agent is accountable for player-journey
acceptance; a capable implementation owner should handle the coupled spatial and
interaction work. Successful subsystem checks alone do not establish product
acceptance.

The bounded runtime investigation used Luna high and was a useful fit. The
content and support/runtime agents already used Sol high; the lift agent used
Sol medium while its scope expanded into persistence, controls and physical
support geometry. The primary used Astra xhigh. Stronger agents alone would not
resolve the ownership and integration problems, but the expanded lift assignment
warranted reassessing its model and effort. The user found coordination
unsatisfactory and the primary too expensive for synthesis work.

For the next task, follow the revised delegation policy in [AGENTS.md](../../../AGENTS.md):
agree shared spatial and interaction constraints before parallel implementation,
assign coherent outcomes with independent decision authority and evidence-backed
handoffs, and match capacity to the full assignment. Use Sol high as a starting
point for complex implementation, with Sol xhigh or Astra high/xhigh where the
reasoning challenge warrants it. When configuring the next coordinator, start
with Sol high and keep its role focused on decisions and acceptance. Keep Luna
for bounded investigations and checks.

Evaluate this approach on one bounded implementation slice: whether the player
journey works, why assignments reopen, how much implementation returns to the
coordinator, elapsed time and available usage by role. Compare monetary costs
only when reliable cost data is available. Optimize total delivery cost including
rework and coordination; do not assume cheaper individual agents produce a
cheaper result. Review these measures after the representative loop and before
expansion. Do not create an automatic approval gate or an arbitrary budget from
this retrospective.
