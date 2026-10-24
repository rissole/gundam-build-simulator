# M3 adaptation: wider workshop blockout

Agreed 2026-10-24. Implementation active; the spatial foundation is integrated.

[Active workshop state](leg-workshop-next-steps.md) · [Fixture and route contract](final-assembly-plan.md) · [Dimensioned layout](final-assembly-layout.svg) · [Existing M3 baseline](leg-workshop-m3-plan.md)

## Goal and settled decisions

Replace M3 in place with a playable, simplified whole-robot workshop. Preserve its
existing structural leg construction, extend it to both legs, and add dimensioned
stand-ins for the remaining major sections with representative mounting work.
Build the wider workshop before deepening individual component mechanisms.

The completed fixture and route plan is the spatial contract. Component documents
own the external mounting interfaces; the shared plan owns equipment dimensions,
source poses, loaded routes and access configurations.

The user owns **walking, visibility, reach and connection-access playtesting**.
Automated verification covers content, equipment movement, support ownership,
interlocks and save/resume. Do not run automated walked acceptance journeys,
reach/visibility sweeps or rendered-review campaigns for this adaptation.
Runtime reach, visibility and collision rules remain active.

Explicit user decisions:

- Replace the existing M3 profile/layout completely; retain its launch aliases.
- Discard old M3 save compatibility. No migration or legacy M3 layout branch.
- Build both legs using the existing simplified M3 structural construction.
- Give new sections representative manual connections rather than automatic retention.
- Add pause-menu playtest checkpoints for inspecting later workshop stages quickly. *Deferred 2026-10-24; see [Saves and checkpoints](#saves-and-checkpoints).*
- Retain the current centered crane controls and shared equipment approach.

The full wider-workshop journey is not complete yet. The implementation ledger
below distinguishes integrated equipment from the remaining assembly work.
The current default supported-foot profile and independent M2 trials remain their
existing scenarios. Replacement applies to M3.

### Implementation ledger — 2026-10-24

- Task 08 adds four head crane pieces on staged receivers, upright bulky-fixture
  inserts and store transfers, separate retention/loom stock, and `head_sensors`.
  Full-payload/full-rig preflight and supported-correction/manual checks cover
  this structural subset; hand-carried closures and crown remain task 09.
  See [head implementation details](../head.md#wider-m3-head-implementation--2026-10-24)
  for source locations, contact tolerance and the hub relief deviation. Walking,
  reach/visibility and rendered presentation have not been reviewed.

- Task 07 adds content-driven guided receivers, `game.zones` occupancy for the
  shared limb station, and both pauldron carriers, M20 bolt units, independent
  shelf-carried panels and local restraint release. The `head` development stage
  starts with closed pauldrons, released restraints and a parked crane. See the
  [pauldron implementation detail](../arms/shoulder-and-upper-arm.md#wider-m3-pauldron-implementation--2026-10-24)
  for passive stores, mounting reliefs/shoes, harness clearance and panel sizes.
  Payload/full-rig preflight and mechanical regression evidence are separate from
  the user's pending walking/access playtest; presentation remains unreviewed.

Integrated foundation:

- `tools/author_workshop_blockout.py` authors the `workshop` spatial contract in
  `assets/leg-bay-m3-layout.json`: bays, raised robot datums, rail/holder envelopes,
  dispatch, source contacts, parking, mobile-platform docks, crane coverage and
  routes, gantry and access geometry. Current output has 540 solid/marking records
  and 76 equipment frames. `workshop_blockout.gd` projects the actual solids.
- M3 uses the new 25 m shell, expanded crane structure, low pelvis portal, shared
  walks, front wings/fingers and upward-folding rear hip leaves. Access movement
  retracts fingers and guards before rotating decks, rejects occupied sweeps,
  and retains interrupted phases. The local hinge aprons are explicit machine
  bearing contacts; their exclusions do not include the surrounding walks.
- Both side elevators and independent shelves replace the former single hip lift.
  Side doors open at each stopped landing. Shelf support IDs and cargo are
  independent, and their movement uses the existing collision/ownership systems.
- Normal M3 aliases launch; access/elevator/shelf states use the existing equipment
  registry and validated atomic session saves. A fresh-scene disk restore of an
  interrupted access configuration passes. The earlier M3 walking, hip-access and
  carried-route suites are excluded from regression-runner discovery.
- The movable work platform has authored paths to all bulky/limb docks, grounded
  travel, guarded height stops, occupied-deck rejection for transfers, swept
  obstruction stops, explicit reversal and interrupted resume. It parks before
  source roll; the later bulky/arm controllers still need that shared interlock.
- The common X14 leg holder replaces M3's old rail controller. The prepared foot
  raises, advances and turns through three supported carrier phases; the three
  crane tasks then deliver the same physical shin/fork/spar identities. Frame
  crossmembers provide the holder's exposed contacts. Supported roll raises to
  Y3.1; the cradle can park/retrieve at X22, stow its bolster and index to a hip lane.
- The left-leg route opens shared access, travels, turns and docks at the actual
  socket. The rear socket gusset and supported turn were corrected for measured
  solid contacts: during the first22.5° of turning the root lowers0.30 m, then
  docks upward1.20 m to the unchanged final sole datum1.40 m. The source height
  stays1.85 m. Dimensions for all new holder members are authored in layout data.
- Hip work now includes stop-cage halves/four screw pairs, three complete carried
  cartridges/six eye pins and three operated captive neutral locks. These extend
  the existing ring, with compatible physical copies and ordinary manual slots.
  The holder requires both retained hardware and all neutral locks before release.
  It opens, lowers, withdraws1.4 m, compacts and shifts2 m outboard before returning
  empty. Local reacquisition leaves the retained leg stationary. This is local
  correction coverage, not a resumed full-teardown acceptance campaign.
- Interrupted carrier, source roll, withdrawal and reacquired-holder sessions
  save atomically and restore into fresh scenes. JSON numeric stop validation and
  resuming a stopped roll were corrected. Invalid unsupported/lock states are
  rejected. Old cabinet solids no longer remain behind the relocated M3 bins.
- Ground crossing gates close before rail travel, remain outside the empty-holder
  sweep and reopen at the source/dock. Their swept arcs and the ground corridor
  have occupancy interlocks, with stop/resume and saved angles. The central crane
  console moves to(7.8,0,22.8), clear of the gate arc and mobile-platform parking.
- Both legs now have independent physical stock and hip connections. Right-hand
  source meshes and receiving transforms are reflected together while runtime
  frames remain right handed; the knee axle enters from outward+X. Shared hardware
  remains interchangeable. The current content audit, including shoulder connections, covers335 extension identities and
  209 playable leg/hip/torso slots, with135 additional prepared-foot identities retained
  from the base scenario. The shared holder can select an empty build, rejects
  replacing occupied construction and saves its selected assembly and hip lane.
- Both prepared feet start in the foot bay on separate sole supports. Four crane
  ends attach to exposed FA-100 rail faces and deliver either existing assembly
  through the authored lift/Z7/cross-workshop/lower route. The same crane retains
  the two-end structural-part tasks. The carrier accepts the matching foot only
  at dispatch, then performs its three-phase handoff. Its empty return leaves the
  mounted foot stationary and extends the sole pads ready for the second load.
- The two-leg mechanical sequence now covers both source deliveries, all six
  structural crane loads, distinct hip retention/neutral locks, second-leg docking
  beside the first fitted leg and both empty-holder returns. Saves reopen in fresh
  scenes while either prepared foot is suspended and after both legs are retained.
  Stock racks are staggered longitudinally because adjacent1.6 m crossmembers
  otherwise overlapped at1.5 m rack spacing.
- The prepared pelvis/waist now starts on the bulky fixture. Its braked height
  adjustment carries the same assembly, and four source clamps open only while
  four crane ends take weight. The source/gantry poses replace the former fixed
  pelvis rule. The shared crane requests the upper-platform delivery configuration,
  follows the authored rise/cross/approach/lower route and transfers ownership only
  at the exact bearing-contact pose. Four local gantry jaws and two captive waist
  neutral pins establish release and leg-docking security. Interrupted source
  contact, fixture height and jaw closing restore in fresh scenes; a stopped jaw
  resumes at its own handle.
- Prepared pelvis context now includes the waist bearing/yoke/cradle, lean
  cartridges, chest seats/keys and lifting eyes. These are supplied simplified
  internals. Actual solid integration trimmed the waist-level work fingers away
  from the socket crowns, put fixed jaw handles below the deck/outside the bridge,
  and raised the lifting-eye support bars above the docking balls. The prepared
  handling envelope now includes the existing descending clevises/catches;
  those were omitted from the earlier socket-only bound.

- The chest/cockpit starts on a passive storage support, transfers by four-end
  crane to the emptied bulky fixture, then travels upright onto the waist. The
  single fixture changes physical contact inserts only when empty and lowered;
  four chest clamps close after seat contact. Interrupted clamp and height phases
  preserve the same assembly identity. Task switching never spawns or repositions
  the chest. Its four outward lifting handles are distinct from the load pads.
- The pelvis manual adds the chest seat, four separate M36 washer/bolt pairs and
  two service leads. Structural retention precedes rig release; service work
  requires the shoes stowed. Prepared context preserves the rear core portal,
  waist key/bolt bores and projected neck pilot. Local supported correction lifts
  and reinstalls the same chest; unrelated leg-holder support no longer blocks
  chest undo. Details and source/storage coordinates are in the
  [chest implementation record](../torso/chest-and-cockpit.md#wider-m3-prepared-implementation--2026-10-24).

- The prepared core uses the same bulky fixture with keyed saddles, a passive
  source store and two crane ends. Rear delivery follows the measured low bypass,
  outboard lift and high crossing. Captured guides take forward support before
  bridge release; the unloaded equalizer folds/shifts aft before further insertion.
  Four captive bolts and rear connection remain separate local operations. Saves
  preserve handoff, rig adjustment, one-end insertion and supported correction.
  Core geometry, guides and rigging are checked against the receiving chest.
- Rigging-path verification initially omitted complete spreader/cable geometry.
  The resulting gate-parking and equalizer-envelope conflicts were implementation
  misses against the existing plan. Inboard barrier parking preserves the selected
  bypass; subsequent core sweeps include the full rig. Apply this complete-envelope
  preflight before expanding backpack and arm deliveries. The user's feedback is
  retained in the active next-steps document.
- The prepared backpack now has physical source/storage geometry, matched bulky
  inserts, two-ended storage transfer, height adjustment and supported return to
  clear the shared fixture. Full source/rig preflight follows the selected rear
  waypoints and checks the closure sweep with articulated strut geometry. It also
  checks the rig against its own payload and rejects low-crossing/low-spreader
  counterexamples. The chest manual now owns seating, two hinge pin/keeper pairs,
  two strut-base pin/keeper pairs and two interchangeable service runs. Captive
  open locks establish support before rig release; closure requires both crane
  ends to take weight before either lock releases. Two lower draw latches precede
  rig release and small service covers. The same crane console operates weight
  transfer and Stop/Resume/Open/Close; local controls operate struts/locks/latches.
  Articulated parent poses, telescope deployment and partial weight transfer save
  and restore, and supported keeper correction preserves stock identity.
  Dimensions and the exact playable boundary
  are in the [backpack source record](../torso/backpack-and-power.md#wider-m3-backpack-source-and-route-preflight--2026-10-24).

- Both prepared arms now have 22 source pieces each, declared passive supports,
  actual structural contact/lifting pads and handed B eyes. The chest contains
  fixed A clevises/C-bridges during source preflight. The single retained cassette
  has connected feet/rails, six folding clamps and four lifting pads; floor
  bearings are flush to preserve leg-wheel travel. Complete-body/full-rig checks
  include the cassette crossing above the real horizontal foot, both mirrored
  upend/yaw/splay paths, the fitted torso/legs/opposite arm and parked equipment.
  The source check found the 0.65 m pre-seat approach crossed a fixed front A
  clevis. The authored correction uses 1.13 m along the same seating axis;
  upper rig anchors also stay outboard of the fixed cup. Both corrections have
  negative counterexample checks. See the [arm source record](../arms/shoulder-and-upper-arm.md#wider-m3-source-and-full-rig-preflight--2026-10-24).
  The subsequent retained-cassette and arm-delivery controls are integrated below.
  Pauldrons and release of the supplied joint/digit restraints remain incomplete.

- The cassette is now one tracked reusable equipment assembly, projected from
  the same blockout source plus four captive floor-lock pins/handles. The old
  duplicate static cassette is disabled. The shared crane transfers this same
  cassette and its retained arm between front parking and the common station.
  It carries the complete frame/arm/rig geometry; the hook trims over the combined
  nominal source mass centre. Floor locks release while the crane takes weight
  and engage at receiving contact before any end can release. The arm keeps its
  original support, identity and manual state throughout. Shared occupancy blocks
  the leg cradle until the cassette parks again. Interrupted source lock release,
  suspension and receiving lock engagement survive fresh-scene saves.

- Both arms now use the same four-end crane after it puts the retained cassette
  at the station. Six telescopic clamps retract0.40 m before folding; this clears
  the forearm ports throughout motion. The live route preserves all measured
  rotations and sweeps the full7.6 m rotation radius, complete rig and taglines.
  The right arm transfers from its passive store onto the cleared cassette.
  Each chest-manual branch adds31 external pieces across32 slots: complementary
  ring halves, four washer/bolt pairs, a handed keyed brace and two pin/keeper
  pairs, three compatible drive cartridges with six pin/keeper pairs, and an
  isolated service harness. Brake confirmation and a progressive load-transfer
  phase establish independent support before services and rig release.
  Interrupted clamp, upend and weight-transfer states restore; local keeper
  correction preserves the arm and consumed hardware identities. Source fit
  checks cover both assembled shoulder bores and neutral brace/drive clearance.

Mechanical evidence for every increment, through the paused 18-case run, is in
the [evidence record](history/m3-wide-evidence-20261024.md). These are mechanical
results only; walking, reach, visibility, connection access and presentation
remain the user's playtest.

Remaining work, in implementation order. The executable task breakdown is in
[handoff/README.md](handoff/README.md); its task files override older wording here.

1. Baseline commit and the right-foot carrier return in the full-sequence test (task 01).
2. Turn off M3 saving and remove save/restore checks from M3 tests (tasks 03–04).
   See [Saves and checkpoints](#saves-and-checkpoints).
3. Extract the scripted stage sequence shared by tests and the `--m3-stage=<name>`
   development launch flag (tasks 05–06).
4. Add one generic receiving interface and a shared occupancy register, then the
   pauldron carriers/panels and release of the supplied arm joint/digit restraints (task 07).
5. Head, in its specified order: crane pieces, then hand-carried pieces and crown
   (tasks 08–09), including the head-piece bulky-fixture inserts.
6. User playtest handoff checklist (task 10).

Deferred and unassigned: M3 saves and checkpoints; the chest's 60° bare-frame
service tilt (only needed once chest preparation is built; the prepared chest stays
upright); removing the historical M3 branch in `leg_rail.gd` and obsolete geometry
keys; migrating the existing core, backpack and shoulder receivers.

## 1. Build the workshop and adapt the leg journey

Implement these stages in order. Use internal integration checks rather than
approval gates between stages, and complete the wider blockout before handing it
over for the user's playtest.

### A. Establish the complete spatial blockout

Update `game/workshop/assets/leg-bay-m3-layout.json` as the common source for runtime
geometry, authored content and mechanical checks. Use the exact coordinates and
motion envelopes in the fixture and route contract, including:

- Existing 40 × 48 m floor, proposed 25 m roof and expanded crane coverage.
- 11 × 12 m bulky-module bay.
- 7 × 13 m shared limb bay centred at X14.
- Passive leg parking at X22 and the front arm-cassette parking berth.
- Low pelvis-support gantry, with the specified bearing contacts and operating handles.
- Two side elevators centred at X6.6/19.4, Z29, serving ground and levels 8.4,
  11.2, 14.0 and 16.4.
- Shared front wings, retracting work fingers, upward-folding two-leaf rear hip
  bridges, fixed rear flanks and rear crossover.
- Foot preparation/dispatch area, stock storage and one movable work platform.

Use simple readable geometry with actual collision volumes, support surfaces and
moving equipment. Preserve precision around mounting faces, fixtures and transport
envelopes; defer decorative detailing. Keep occupied dimensions, load datums,
fixture contacts and source/destination transforms in authored data rather than
scattering coordinates through controller code.

### B. Adapt the existing left-leg loop first

Preserve M3's prepared foot, structural parts, fasteners and construction dependencies.

1. Deliver the prepared foot to the new dispatch position.
2. Transfer it onto the cradle at the common limb station.
3. Crane in and fasten the shin, knee fork and upper-leg beam.
4. Select the left hip lane through the transverse rail table.
5. Travel, turn upright and dock while continuously supported.
6. Complete hip retention and neutral support.
7. Withdraw the empty holder 1.4 m rearward, compact it, shift it 2 m outboard
   and return it to the station.

Implement the revised cradle contacts and horizontal height, supported source
roll, opening bridges and empty-return motion from the spatial contract.
Complete this representative mechanical loop before expanding other deliveries.
Do not run an automated walked acceptance journey.

### C. Reuse the station for the right leg and arms

Mirror the existing structural leg content for the right side, with distinct
physical identities and outward knee-axle insertion.

The single rail cradle serves either hip. It can park a supported unfinished leg,
but cannot start another leg while occupied. Add the removable arm cassette and
its passive parking transfer. Switching between leg and arm work physically clears
the station and preserves the displaced assembly's progress. Equipment never
duplicates, resets or silently relocates a build.

## 2. Add the major-section assembly journey

Use prepared assemblies for new sections. Their internal mechanisms are supplied
complete; the player performs handling, mounting, retention and representative
service work.

| Stage | Playable work |
| --- | --- |
| Pelvis/waist | Rig the prepared unit at the bulky fixture, deliver it, close the gantry hold-downs and establish neutral locks before releasing the crane. |
| Both legs | Perform the simplified M3 structural builds. Retain the existing hip rings/hardware; represent additional hip cartridges as complete parts with mounting pins and neutral locks. |
| Chest/cockpit | Deliver the prepared frame and fitted cockpit upright. Install four waist bolt/washer pairs, release rigging and connect side services. |
| Core | Follow the rear crane route, transfer forward support to the captured guide, complete flange retention and connect the rear interface. |
| Backpack | Deliver it open, secure hinges and struts, connect services, then reacquire crane support for closure. |
| Both arms | Put each prepared arm on the shared cassette, restrain it, attach four crane ends, execute the guided upend/yaw/splay and shoulder approach, complete retention and representative services, then fit the pauldron. |
| Head | Preserve baseplate → sides → top → sensors → faceplate → mask → crown. Use the specified crane and hand-carried handling modes. |

Use the existing component documents for external connection locations, hardware
families and release prerequisites. Do not invent alternate mounting systems for
stand-in meshes. Detailed mechanism construction inside the prepared sections is
deferred. The torso's fixed neck spoke belongs to the prepared chest.

All prepared sections and required stock exist as physical instances on declared
supports. Moving them into a work bay uses the shared crane or carrier. Author
source poses and storage-to-fixture routes in the layout data before testing them
in-game. A shared station has one occupant; changing the selected task does not
spawn a replacement payload or teleport the previous occupant away.

The manual recommends the agreed order, but dependencies enforce actual support,
occupancy and connection requirements rather than a global stage counter.

## 3. Extend the shared runtime systems

### Equipment and support interfaces

Keep the existing equipment registry, hand ownership and assembly model. Generalize
current single-load assumptions:

- Rail and foot carrier receive the active assembly, receiving slot and destination
  lane instead of hardcoding `left_leg`.
- Each elevator and shelf gets its own equipment/support identities.
- Crane tasks describe payload, source support, receiver, required lifting ends,
  route phases and retention milestone.
- Support loose structural parts and prepared assemblies through the same crane
  controller. Use each task's required two- or four-end configuration rather than
  assuming every task has exactly two ends.
- Remove the M3 rule requiring the pelvis to remain at its initial gantry pose.
  Its position follows its current fixture, crane or secured gantry support.

Represent equipment movement as explicit phases with resumable progress. The
assembly model remains authoritative for ownership; equipment controls temporary
support and pose. A seat positions a load; structural retention and neutral
restraint establish the release conditions. Take weight before releasing old
support, and secure the receiver before releasing handling equipment.

### Movement and interaction

Implement the planned routes: rail indexing, loaded travel, docking, parking and
empty return; arm upending/yaw/splay and shoulder seating; rear low bypass,
outboard lift, high crossing and central lowering; high head-piece/pauldron
deliveries; shared work-platform positioning and height adjustment.

A delivery requests its shared access configuration. Work fingers retract before
front wings swing. Rear hip bridges fold upward without crossing the held cradle.
Gates and occupancy interlocks prevent movement through occupied areas. Restore
working platforms only after payloads and rigging clear their moving envelopes.

Retain Up/Down/Go and Advance/Stop/Return. Show contextual destinations and specific
blocking reasons; do not add a permanent console for each component. Preserve
ordinary collection, manual targeting and fastening. The user's access playtest
is not a reason to allow remote fastening or disable obstruction handling.

### Saves and checkpoints

**Deferred on 2026-10-24.** The user removed M3 saving and the pause-menu
checkpoints from this adaptation until the broad workshop structure exists.
Maintaining interrupted-motion saves for every new machine added large amounts
of work and was repeatedly wrong. M3 launches without a save slot, and Restart
starts again from the launch point. Mechanical tests no longer save or restore
M3 sessions. To inspect later stages, the development flag `--m3-stage=<name>`
runs the same scripted equipment sequence as the mechanical tests and then starts
paused. That is supplied progress, not playtest evidence, and not a save. When
saves return, save only at rest (no equipment moving, every load on a support),
which removes mid-motion validation. The default foot workshop and the M2 trials
keep their existing saves. The original requirements below are preserved for
that later work.

*Preserved requirements (not active):*

Continue using the M3 save slot. Start fresh when replacing the old M3 scenario;
no migration support is required. Retain normal validation and atomic saving for
the new workshop, including active loads, fixture occupancy, lane selection,
equipment phases, crane ends, platform states, both elevators/shelves and each
assembly's independent progress.

Add a clearly labelled **Playtest checkpoints** section to the pause menu:

- Fresh workshop.
- Left-leg construction / left-leg docking.
- Right-leg construction / right-leg docking.
- Chest delivery.
- Core delivery.
- Backpack delivery.
- Left-arm delivery / right-arm delivery.
- Head construction.
- Completed robot.

Construction and docking entries are separate starting stages. Loading a checkpoint
explicitly replaces the current M3 session and starts paused. Use the same content
and equipment configuration as normal play, populating preceding work through
valid model/support staging. Label it as supplied progress rather than completed
playtest evidence. Normal save/resume works after loading any checkpoint.

## 4. Verification and handoff

### Automated mechanical checks

Update the existing authoring pipeline alongside generated assets. Run focused
checks for:

- Unique identities, mirrored content, stock counts and manual-slot coverage.
- Correct mounting transforms and child motion during equipment movement.
- Support handoffs and rejection of premature crane/cradle release.
- Both hip destinations, occupied parking/station rejection and empty-holder return.
- Required crane-end counts, route phases and platform interlocks.
- Payload/equipment collision sweeps using blockout geometry.
- Stop/resume and save/reload during representative transfers.
- Independent elevator/shelf state.
- Valid checkpoint staging and M3 launch.
- Relevant shared-system regressions affected by these changes.

Use model/equipment harnesses for mechanical checks. Do not automate walking,
targetability, connection-access acceptance or rendered inspection. Replace the
old M3 walked acceptance gate with the human playtest handoff. Do not run a broad
suite that silently reintroduces those access checks; select relevant logic tests.

### User playtest handoff

Provide the complete wider workshop, its checkpoints and a short checklist covering
walking/elevator boarding, connection visibility/reach/tool approach, rigging
attachment/release, carrying/shelves, equipment controls and overall flow.

Report mechanical checks separately from human playtest results. The user will
perform walking and connection-access checks. Record their findings and positive
results in the active state document for subsequent iteration.

### Boundaries and documentation

This milestone covers initial major-section assembly and local supported correction.
Detailed component internals, finished art, whole-robot lowering and full teardown
are deferred. Reserve documented rear maintenance space; the complete removable-
guide/core-maintenance workflow is later work.

Update the existing M3 plan, workshop state and design documents in place so
**wider workshop first** is the active direction. Preserve the previous M3 results
as historical evidence and the user's "largely satisfying" assessment. Keep
temporary verification output outside the design-document tree.
