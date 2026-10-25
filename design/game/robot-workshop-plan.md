# Robot workshop: whole-robot blockout

Agreed 2026-10-24. Implemented through the head crown; awaiting the user's playtest.

[Active workshop state](workshop-state.md) · [Fixture and route contract](final-assembly-plan.md) · [Dimensioned layout](final-assembly-layout.svg) · [Original leg journey (archived)](history/leg-workshop-m3-plan.md) · [This plan as agreed (archived)](history/robot-workshop-plan-20261024.md)

## Goal and settled decisions

Replace the original leg-to-robot journey in place with a playable, simplified
whole-robot workshop. Preserve its existing structural leg construction, extend it to both legs, and add dimensioned
stand-ins for the remaining major sections with representative mounting work.
Build the wider workshop before deepening individual component mechanisms.

The completed fixture and route plan is the spatial contract. Component documents
own the external mounting interfaces; the shared plan owns equipment dimensions,
source poses, loaded routes and access configurations.

The user owns **walking, visibility, reach and connection-access playtesting**.
Automated verification covers content, equipment movement, support ownership,
interlocks and stage progression. Do not run automated walked acceptance journeys,
reach/visibility sweeps or rendered-review campaigns for this adaptation.
Runtime reach, visibility and collision rules remain active.

Explicit user decisions:

- Replace the original leg journey's layout completely.
- Discard its save compatibility. No migration or legacy layout branch.
- Build both legs using the existing simplified structural construction.
- Give new sections representative manual connections rather than automatic retention.
- Add pause-menu playtest checkpoints for inspecting later workshop stages quickly. *Deferred 2026-10-24; see [Saves and checkpoints](#saves-and-checkpoints).*
- Retain the current centered crane controls and shared equipment approach.

On 2026-10-25 the user consolidated everything into this one workshop: the
foot-only workshop, the leg-bay equipment trials, the regression scenarios and
all save code were removed (see the [workshop state](workshop-state.md)).

### Status — 2026-10-24

Implemented through the head crown (handoff tasks 01–10 and 04b).
`--stage=complete` is the final development boundary. These are mechanical results;
walking, reach, visibility, connection access and presentation await the user's
[playtest](robot-workshop-playtest-checklist.md). Since the user's 2026-10-24 request,
`./play.command` launches one robot game. The base foot build comes first, in a
turning fixture at the left foot's store, and the structure follows in the same
session. The per-increment implementation ledger
and evidence are [archived](history/m3-wide-evidence-20261024.md).
Component-specific implementation detail lives in each component document's
"Robot workshop … — 2026-10-24" section. Deferred items are listed in the
[workshop state](workshop-state.md#deferred-needs-a-decision).

The subsequent [equipment UI revision](history/equipment-ui-20261024.md) separates
crane load selection from motion and gives the lifts explicit Up/Down controls.
Screenshots were inspected; the user requested no regression run for that revision.
Its [focused verification checklist](robot-workshop-playtest-checklist.md#focused-controls-check--2026-10-24)
remains pending alongside the wider workshop playtest.

## 1. Build the workshop and adapt the leg journey

Implement these stages in order. Use internal integration checks rather than
approval gates between stages, and complete the wider blockout before handing it
over for the user's playtest.

### A. Establish the complete spatial blockout

Update `game/workshop/assets/workshop-layout.json` as the common source for runtime
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

Preserve the original journey's prepared foot, structural parts, fasteners and construction dependencies.

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
| Both legs | Perform the simplified structural builds. Retain the existing hip rings/hardware; represent additional hip cartridges as complete parts with mounting pins and neutral locks. |
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
  route phases and retention milestone. They are hidden routes. The player never
  picks one: the console's pickup serves the first route in `crane.order` whose
  load waits at its source. A new section adds its route to `crane.order` and its
  supports to `crane.places`, never a console entry.
- Support loose structural parts and prepared assemblies through the same crane
  controller. Use each task's required two- or four-end configuration rather than
  assuming every task has exactly two ends.
- Remove the original journey's rule requiring the pelvis to remain at its initial gantry pose.
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

**Implemented 2026-10-25 as a lightweight snapshot.** One local slot,
`user://workshop-save.json`, is written each time the normalised assembly model
changes: a component set, mounted, seated or undone. It holds the model and
each machine's `capture()` at its last stop, so motion is never saved halfway. The
service crane is not saved. It reloads parked, and no save is taken while a load
hangs on it. Loading is synchronous: restore the model, place assembly bodies, let
each machine `apply()` its at-rest state, re-sync visuals. The player, pockets,
loose and held parts and the manual reset. An invalid file (unreadable, a different
`FORMAT`, changed identities, slots or machine fields, or failed integrity) is
deleted; there are no migrations, checksums or backups. Tests, tools and `--stage`
launches never touch the slot. The pause menu's **New workshop** deletes it. The one
ongoing rule: a machine's `capture()`/`apply()` must round-trip its at-rest state,
including where its supported load sits. `save_roundtrip_test` checks a fresh boot;
the explicit-request diagnostic `save_roundtrip_stages_test` checks every stage
boundary. A replayed action log was rejected because late-game loads would be too
slow. The removed mid-motion design is [archived](history/save-resume.md).
Handoff: [design/game/handoff/save/](handoff/save/README.md).

*Original requirements (superseded by the design above; pause-menu checkpoints remain unimplemented):*

Use one workshop save slot. Start fresh; no migration support is required. Retain normal validation and atomic saving for
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
explicitly replaces the current session and starts paused. Use the same content
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
- Stop/resume during representative transfers.
- Independent elevator/shelf state.
- Valid stage boundaries and the `--stage` launch.
- Relevant shared-system regressions affected by these changes.

Use the fast routine runner and model/equipment harnesses for mechanical checks.
Expensive sequence and route diagnostics require an explicit user request and
named `run_diagnostics.py --only` cases; never run them as automatic extra verification.
See [coverage migration](../../game/workshop/tests/TESTING.md). Do not automate walking,
targetability, connection-access acceptance or rendered inspection. Replace the
old walked acceptance gate with the human playtest handoff. Do not run a broad
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

Update the existing plan, workshop state and design documents in place so
**wider workshop first** is the active direction. Preserve the original leg
journey's results as historical evidence and the user's "largely satisfying" assessment. Keep
temporary verification output outside the design-document tree.
