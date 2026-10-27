# Robot workshop: whole-robot blockout

Agreed 2026-10-24. Implemented through the head crown; partial left-leg playtest
received 2026-10-26, with the wider journey still awaiting acceptance.

[Active workshop state](workshop-state.md) · [Fixture and route contract](final-assembly-plan.md) · [Dimensioned layout](final-assembly-layout.svg) · [Original leg journey (archived)](history/leg-workshop-m3-plan.md) · [This plan as agreed (archived)](history/robot-workshop-plan-20261024.md)

## Goal and settled decisions

### Left-leg feedback follow-up — 2026-10-26

The user completed one leg and found the physical access challenge partly
satisfying. Preserve that finding alongside every reported issue in the
[playtest checklist](robot-workshop-playtest-checklist.md#left-leg-completed--2026-10-26).
The [nine discrete task plans](handoff/left-leg-feedback/README.md) cover systemic
repairs and identify obligations for later component detailing. All nine are now
implemented; their [mechanical evidence](handoff/left-leg-feedback/README.md#implementation-evidence--2026-10-26)
is separate from the pending player recheck and wider workshop acceptance.

Confirmed direction: attached transport braces with local engagement handles;
loose components resting on moving decks ride with them while genuine obstacles
still stop motion; notes and a current-control guidance glow apply across the
class of manual-directed local operations. Existing compatible hardware must be
reused. Preserve the actual supported assembly sequence and useful access
challenge while improving pickup, carrying, shelf use and target explanations.

Stable loose components on equipment decks ride through the shared passenger
system, retaining loose ownership. Their full collision envelopes stop for real
obstacles; pickup, shelf transfer and support loss change handling immediately.
Shelf cargo remains separately support-owned. A snagged held part or nested
assembly may recover to a bounded clear hand pose without losing its identity;
if no pose is clear it stays held and asks the player to move clear. This recovery
exception never bypasses final placement reach, access or approach checks.

### Original milestone scope

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

Landing **CALL** buttons use a 0.9-second arrival with cubic deceleration,
independent of travel distance (2026-10-27). Onboard **Up/Down** keep their
0.75 m/s ride speed. Calls retain guarded motion, rider/cargo transport and
automatic resume; obstruction and pause time do not consume the arrival time.
A landing CALL interrupts an active trip at its current height and starts a fresh
0.9-second arrival to that landing, including during another call.

## 1. Build the workshop and adapt the leg journey

Implement these stages in order. Use internal integration checks rather than
approval gates between stages, and complete the wider blockout before handing it
over for the user's playtest.

### A. Establish the complete spatial blockout

Update `game/workshop/assets/workshop-layout.json` as the common source for runtime
geometry, authored content and mechanical checks. Use the exact coordinates and
motion envelopes in the fixture and route contract, including:

- Existing 40 × 48 m floor, proposed 25 m roof and expanded crane coverage.
- 11 × 12 m Heavy Module Bay.
- 7 × 13 m shared limb bay centred at X14.
- Passive leg parking at X22 and the front arm-cassette parking berth.
- Low hip assembly-support gantry, with the specified bearing contacts and operating handles.
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
| Hip assembly | Rig the prepared unit on the heavy module rig, deliver it, close the gantry hold-downs and establish neutral locks before releasing the crane. |
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
- Remove the original journey's rule requiring the hip assembly to remain at its initial gantry pose.
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

Existing equipment retains Up/Down/Go and Advance/Stop/Return until its operated
conversion below. Show contextual destinations and specific
blocking reasons; do not add a permanent console for each component. Preserve
ordinary collection, manual targeting and fastening. The user's access playtest
is not a reason to allow remote fastening or disable obstruction handling.

### Operated rigs — Phase 1 design, 2026-10-27

**Design only for B3/B5.** B1 supplies an opt-in Hold E callback on a physical
button; B2 supplies `scripts/rig_target.gd`. Neither rig uses them yet. This section
supersedes the NEXT-driven delivery design when those later tasks are implemented.
Follow the [branch handoff](handoff/operated-machines/B-operated-rigs.md): implement
the leg slice now; complete **checkpoint B before B5**. B owns the shared manual
first-use/repeat mechanism.
Preserve the successful foot *building* bay and the useful physical access challenge
recorded in the [machine-operation finding](robot-workshop-playtest-checklist.md#machine-operation-and-gantry-access--2026-10-26).

#### Input, target and panel contract

Keep the existing `spec.panels`: leg `(8.78,0,14.5)` and `(8.5,0,24)`, facing
−X, and foot `spec.panel = (11.1,0,7)`. Reflow buttons on these panels; do not move
panels or claim sightline acceptance without the user. Each delivery axis has
physical minus/plus arrow keys, an axis name and one signed readout. The keyboard
binding for every arrow is **hold E while aimed at that button**, not an extra
letter key. Only one arrow can be latched; release E to choose another. Mouselook
remains free. E release, pause, manual/modal opening or STOP ends the jog. No
queued movement survives a new press. Existing tap actions remain taps.

`equipment_button.set_hold_handler(button, callback)` receives `(held, delta)`;
controllers can bind their action after those arguments. `targeting.latch_control`
checks normal reach, sightline and `action_error` on press. Each held tick must
recheck the machine interlocks, clamp displacement to the real joint limits and
use the existing guarded-motion policy. A new obstacle **pauses**, names the
player/loose part/hand load, and resumes only while E remains held. Looking away
does not release the latch. Mechanical prerequisite refusals name the correction;
they never teleport, drop ownership or consume a manual step.

Create one `rig_target` outside the carried assembly, using the shared runtime.
`show_target(assembly_id, world_transform)` reuses its mesh copies; `clear()` hides
at idle. Model changes invalidate it; explicit articulation changes must call
`invalidate()` before showing again. Copies include nested assemblies and captive
hardware, exclude render proxies/outlines, and have no collisions or targeting.
For each axis supply `target - current`, tolerance and unit to `axis_readout`.
Assign each returned row's text/color to a separate Label3D: **each** matching
axis turns green. Keep the name/sign/number, so color is not the only cue. Readout
values and the ghost derive from the same target record, never an independent
pose guess. During final alignment the ghost is the exact runtime install pose.

#### Leg joints and pose

Baseline: `indexed_leg_rail.gd::snapshot_pose`, `action_error`, `_travel_scale`,
and `assets/workshop-layout.json::workshop.rail`; geometry and clearance rationale
remain in [the shared limb workshop](final-assembly-plan.md#shared-limb-workshop-with-different-departure-routes).
Coordinates below are Godot world metres, angles in degrees. Speeds are initial
values derived from today's `.12` path units/s, `.8` index m/s, `20` roll deg/s
and `.3` bolster/roll-height units/s; they are not player-approved tuning.

| Joint / saved field | Range and speed | Panel arrows (internal actions) | Alignment tolerance |
| --- | --- | --- | --- |
| INDEX / `index_x` | X11.9..22.0; 0.8 m/s. Home 14.0, left 11.9, right 14.1, parking 22.0 | INDEX − / + (`index-`, `index+`) | ±0.02 m at the selected lane/home/parking target |
| TRAVEL / `travel_z` | Bogie Z14.5..26.0; 1.38 m/s (=11.5×.12) | TRAVEL − / + (`travel-`, `travel+`) | ±0.02 m |
| TILT / `tilt_deg` | 0° lying..90° upright; 10.8°/s | TILT − / + (`tilt-`, `tilt+`) | ±0.10° |
| RISE / `rise_m` | 0..1.20 m; 0.144 m/s. Loaded jog ceiling 1.17 m; last 0.03 m belongs to SEAT | RISE − / + (`rise-`, `rise+`) | Final target 1.20 m, ±0.04 m capture window, plus connection-space check below |
| Construction ROLL / `roll_deg` | Cyclic 0..360°; 20°/s; work detents 0/90/180/270° | ROLL − / + (`roll-`, `roll+`) | ±0.5° at a work detent; exact neutral required before departure |
| Construction LIFT / `roll_height_m` | 0..1.25 m above Y1.85; 0.375 m/s (=1.25×.3) | LIFT − / + (`lift-`, `lift+`) | ±0.01 m at ends |
| Foot BOLSTER / `bolster` | 0 supported..1 stowed; 0.3 stroke/s; retain authored spread/lift linkage | BOLSTER − / + (`bolster-`, `bolster+`) | Exact end stop; never release support at an approximate stop |

The delivery and construction coordinates are independent state, not aliases for `path`.
For an engaged, neutral-roll delivery let `theta = deg_to_rad(90 - tilt_deg)`:

```
lower = spec.delivery_lower * clamp(tilt_deg / (90 * spec.lower_during_turn), 0, 1)
root = (index_x,
        spec.base_y + spec.lying_lift*sin(theta) - lower + rise_m,
        travel_z - spec.pivot*sin(theta))
basis = Basis(RIGHT, theta)
```

This retains the physical tilt's coupled translation: `base_y=.5`,
`lying_lift=1.35`, `pivot=5.1`, `delivery_lower=.30`, `lower_during_turn=.25`.
Do not replace it with a rotation about the root or move the lowering into travel.
At the home construction pose, `root.y = 1.85 + roll_height_m` and multiply the
lying basis by `Basis(UP, deg_to_rad(roll_deg))`, as the existing source roll does.
Only the selected joint changes on a jog tick. Endpoint clamps establish exact
mechanical stops; capture tolerances do not silently snap a loaded travel axis.

Targets are records rather than automatic moves:

| Target | INDEX / TRAVEL / TILT / RISE | Assembly root (neutral source roll) |
| --- | --- | --- |
| Build home | 14 / 14.5 / 0° / 0 | (14,1.85,9.4), X rotation 90° |
| Selected hip track | lane X / 14.5 / 0° / 0 | (lane,1.85,9.4), X rotation 90° |
| Clear turn position | lane X / 26 / 0° / 0 | (lane,1.85,20.9), X rotation 90° |
| Upright below hip | lane X / 26 / 90° / 0 | (lane,.20,26), identity basis |
| Seated | lane X / 26 / 90° / 1.20 | (lane,1.40,26), identity basis; must equal `runtime.mount_pose(receiver, receiver_slot, active_assembly)` |
| Passive parking | 22 / 14.5 / 0° / 0 | (22,1.85,9.4), X rotation 90° |

Target selection describes the next unmet physical condition, not permission to
press NEXT. Restore construction roll/lift, stow bolster, align track, move to
turn clearance, stand upright, then align to the seated ghost. Reversing a joint
selects the corresponding correction target; right-leg targets use X14.1 and the
right receiving slot. No second set of hardcoded installed transforms is allowed.

#### Leg interlocks and named refusals

Keep `busy_reason("rail")`, `busy_reason("source_roll")`, explicit captive
`joint_restraints.required_error(active_assembly)`, and the model's support and
retention checks. Apply relevant checks each tick, including reverse motion.
Use a small positional epsilon only for exact physical detents; use the table's
tolerances for player alignment. Being inside a tolerance never bypasses a sweep.

| Requested motion | Required physical condition / refusal |
| --- | --- |
| Any motion while paused | “Resume the workshop before moving the leg rig.” |
| Index, park or depart with construction roll/lift active | “Restore neutral roll and construction height before indexing.” |
| INDEX away from transverse table | Bogie at home, tilt lying, rise zero. “Return the leg rig to the transverse table first.” |
| INDEX with bolster supporting foot | Stow only after retained joints are braced. “Stow the foot bolster before indexing.” Keep unfinished-leg parking available once its retained joints are locked. |
| Loaded departure toward hip | Matching lane, `structural_ready`, engaged holder, complete required braces, secured gantry. Preserve “Select the left/right hip lane for this leg.”, “Complete the structural leg and every retaining connection before delivery.” and “Deliver the hip assembly, close all four gantry jaws and insert both waist lock pins before leg delivery.” |
| TRAVEL off a track / with nonneutral delivery pose | At matching lane within 0.02 m, lying, rise zero. “Align INDEX with the selected hip track.” / “Lower and lay the leg down before travelling.” Parking X22 has no longitudinal track. |
| TRAVEL/TILT/RISE with access unavailable | Request existing `rail_gates.request_closed(true)` and `workshop_access.request_mode("leg")`; hold motion until ready. “Waiting for the ground crossing gates to close.” / “Waiting for the hip access platforms to clear.” Preserve the gate occupancy message “Leave the ground rail corridor before moving the leg rig.” |
| TILT near the transverse table | At selected lane, bogie at Z26 within 0.02 m, rise zero. “Travel to the clear turn position before tilting.” / “Lower the leg before tilting.” The known-clear Z26 pose is the first slice's turn envelope; do not infer a safe earlier turn from table bounds alone. |
| RISE while misaligned | Upright within 0.10°, selected lane and Z26 within 0.02 m. “Stand the leg upright under the selected hip before raising.” |
| Roll/lift away from construction home | Engaged at station, foot received, bolster supports it; `source_roll` zone clear. “Roll only with the leg rig occupied in the Limb Bay.” / “Transfer the prepared foot onto the leg rig first.” Lift fully before nonneutral roll; restore roll before lowering: “Raise the construction axis before rolling.” / “Restore neutral roll before lowering the construction axis.” |
| Any load motion after seating | Require explicit UNSEAT/reacquisition and no hip retention. “Remove hip retention before returning the loaded leg.” Do not move a parented load with the holder. |
| RELEASE before receiver retention | “Complete hip retention and the cylinder lock pins before releasing the leg rig.” Keep `retention_state() == complete`, including neutral locks. |
| BUILD while away or occupied | Preserve home/neutral/empty checks and existing occupied-rig refusal; never switch identity while supporting an unfinished leg. |

STOP cancels the latched input and any guided lead-in/service request. Gates stay
closed at intermediate coordinates; open only at a stable home or dock with no
pending motion. Obstacle waiting is distinct from a prerequisite refusal and must
remain reversible. Do not port today's foot-carrier behavior that clears `moving`
on contact into either new jog controller.

#### SEAT, retention and empty return

**SEAT is a tap, only while all jog inputs are released.** Recheck axis tolerances,
matching assembly/slot, engaged support, gantry/access readiness, model placement
error and current mount pose. In addition to axis tolerances, require the mating
connection's positional residual ≤0.05 m and angular residual ≤0.10° against the
actual receiving frame. Otherwise say “Align the green axis marks before seating.”
This limits the long leg's angular tip displacement; a generous angle at the root
would exceed the promised few-centimetre guide capture.

On a valid tap, guide the last 3 cm upward at 0.06 m/s (nominal 0.5 s), blending
remaining in-tolerance lateral/angular error to the exact runtime mount pose.
Sweep the payload, holder and passengers through the lead-in with existing
intentional-contact exclusions only. Contact pauses with named feedback; STOP
or pause leaves the current supported pose, and another SEAT tap revalidates and
resumes the remaining short lead-in. If the receiver changes, halt and revalidate.
Only on actual arrival call `install_supported` once, then `runtime.mount` and
refresh collision. Simply reaching a jog tolerance never installs or releases.
Retain `leg_holder` engagement throughout hip fastening. A seated state is model
ownership plus exact mounted pose, not a remembered button press or stop number.

Retain separate tap **RELEASE / REACQUIRE / UNSEAT / BUILD / PARK target** controls.
PARK selects the X22 target; INDEX drives there. UNSEAT performs the supported undo
only after the holder has reacquired the load and retention is absent. It then
permits reverse RISE, TILT, TRAVEL and INDEX; it does not auto-return to the bay.
For the first leg slice, propose retaining the existing constrained support-head
service linkage (`release` 0..5 at .6 units/s) behind RELEASE/REACQUIRE, with STOP
and named guarded pauses. It opens jaws .15 m, lowers .30 m, withdraws 1.40 m,
compacts to 2.00 m, then shifts the head 2.00 m outboard. This is an explicit
support handoff, not another delivery NEXT sequence. Whether the player should
jog these service joints too is an open question below.

Empty return keeps the bogie on the selected rail and the released head outboard
(left X9.9/right X16.1). Use today's empty-root formula
`y = 1.1 + 2.25*sin(theta)` with withdrawal/outboard transforms; do not apply the
loaded rise formula to an empty head. Jog empty TILT back to lying at Z26, then
TRAVEL home, then INDEX to station. Empty longitudinal travel requires release=5,
rise=0 and lying tilt; no return alongside the robot with an unwithdrawn fork.
Re-centre/extend at home only, before BUILD or a new pickup. Reacquiring at the hip
reverses this service sequence with the same contact exclusions. The existing
head return envelope remains the constraint for all new joint combinations.

#### At-rest save fields and manual evidence

Proposed leg `capture()` shape: `version`, `assembly`, `receiver`, `slot`, `lane`,
`index_x`, `travel_z`, `tilt_deg`, `rise_m`, `roll_deg`, `roll_height_m`, `bolster`,
`release`, `engaged`. `release` is the physical support-head linkage coordinate;
`engaged` is the support relationship. Model ownership is authoritative for seated
and retained states. Do not persist the E latch, axis direction, goals, motion mode,
lead-in timer, target ghost, refusal text or manual stop number. On `apply`, restore
coordinates and supported pose, reset input/motion, rebuild support geometry and
sync mounted children. A later explicit SEAT/RELEASE/REACQUIRE request derives its
remaining movement from the stopped geometry and ownership.

Every released jog position is a legitimate braked rest position. Pause releases
input before saving. During an active service move or lead-in, use the shared
registry's last at-rest snapshot; advance the rest snapshot at ownership handoff
before starting withdrawal so model and support cannot disagree. Preserve the
shared rider snapshot behavior. B3/B5 must check those transitions through real
`save_capture`/`apply`, not add per-machine save validators or store in-flight
commands. Changed save shapes are incompatible: invalidate/delete through the
shared save format policy, with **no migrations** from `path`/`goal` saves.

B3 exposes axis-in-tolerance, braked/home, bolster-stowed, seated, retained and
holder-released evidence through `manual_state()`, scoped by active assembly and
receiving slot. Construction/return evidence must not depend on floor(path).
B4 uses the shared first-use/repeat mechanism: teach the left leg one axis at a time with
exact panel names and Hold E; right leg gets the goal plus procedure link. Design
the manual and stage driver with the same axis commands and explicit SEAT, not a
test-only shortcut to `install_supported`. No shared manual files change in Phase 1.

#### Foot rig — B5 design after checkpoint B

Use `foot_carrier.gd::pose_at`, `action_error` and its actual `spec.sole_route`, not
the legacy `route` root positions as independent joint coordinates. Let
`sole = (14, 1.20 + raise_m, 7 + travel_m)`, `basis = Basis(RIGHT, deg_to_rad(turn_deg))`, and
`frame = Transform3D(basis, sole) * Transform3D(IDENTITY, spec.root_offset)`;
`root_offset=(0,.8,-.7)`. This preserves the rotating sole datum and mast bearing.

| Axis / arrows | Range, initial speed | Target and tolerance |
| --- | --- | --- |
| RAISE − / + (`raise-`, `raise+`) | 0..0.65 m, 0.1625 m/s (=.65/4) | .65 m, ±.02 m |
| TRAVEL − / + (`travel-`, `travel+`) | 0..2.40 m, .48 m/s (=2.4/5) | 2.40 m, ±.02 m |
| TURN − / + (`turn-`, `turn+`) | 0..90°, 11.25°/s (=90/8) | 90°, ±1.1° capture tolerance; jog ceiling 89° reserves the final guide turn |

Targets: dispatch root `(14,2.0,6.3)` upright; raised root `(14,2.65,6.3)`;
travel root `(14,2.65,8.7)`; final root `(14,2.55,10.2)` with X rotation 90°.
All derive from sole frames; final ghost must match
`runtime.mount_pose(receiving_assembly, "foot", assembly_id)` on either leg.
The final 1° about the sole datum moves the root about 1.9 cm. Use **1.1° for
both TURN's green readout and SEAT capture**, so all green marks can be achieved
before SEAT. This proposed tolerance and guide motion need player confirmation.
Use the same ≤.05 m connection-space capture bound. Guide 89°→90° in .5 s
(2°/s, proportionally shorter for a resumed arc), correct residual raise/travel,
sweep, then `install_supported` exactly once. Do not invent a new translating
slide merely to obtain a linear lead-in; the existing real joint is the turn.

Preserve matching active-leg/engaged-home checks: “Select the matching leg and
return its engaged leg rig home before transferring this foot.” Preserve “Crane
the prepared foot onto the empty foot rig first.” Require `busy_reason("foot_transfer")`
to clear. TRAVEL requires full raised height and upright foot: “Raise the foot
and restore upright before travelling.” TURN requires raised height and receiver
travel position: “Raise and travel to the leg rig before turning.” Lower only at
dispatch and upright: “Return upright to dispatch before lowering.” The receiving
bolster stays engaged; ownership changes only at SEAT. Guarded obstacles wait
and resume, with reverse jog available after E release. After seating, retain the
existing 0..1 withdrawal stroke (.45 m, 2 s) as a guarded support service action.
No leg motion until withdrawal is complete. BACK/UNSEAT may reacquire and undo
only at the matching home leg rig and while foot is still the last history entry;
otherwise name the retained structural work that blocks reversal.

Foot save fields: `version`, `assembly`, `receiver`, `raise_m`, `travel_m`,
`turn_deg`, `withdrawal`; mounted state derives from model ownership. Use the
same at-rest/ownership-boundary rules as the leg. Remove persisted `path`, `goal`,
`moving`, `blocked_reason`, `handoff` from the new shape; no migration. B6 teaches
the left foot RAISE/TRAVEL/TURN/SEAT and gives the right foot a goal/procedure link.

#### Later verification and open questions

B3/B4's isolated mechanical tests must cover both signs and limits of every joint,
wrong-lane rejection, prerequisites and named refusals, required braces, gates and
access waiting, obstruction hold/resume/reverse, and carried/nested geometry through
intermediate rotations. Compare the new pose function with today's `snapshot_pose`
at home, lane, travel, upright, dock and empty-return endpoints. Test “within
tolerance without SEAT” leaves ownership unchanged; interrupted/blocked SEAT keeps
support; arrival matches both ghost and actual install pose; no duplicate install;
retention gates release and reversal. Exercise real desktop press/look/release on
one small controller fixture. Verify stopped intermediate coordinates, lead-in and
ownership-boundary saves through the shared snapshot system, including mounted
children. B5/B6 repeat these for sole-frame turns, both foot identities, receiver
matching and withdrawal. Classify new isolated suites in `test_inventory.py` and
run only touched routine suites with `--jobs 4`. Do not run diagnostic journeys,
walking/reach sweeps or rendered reviews as automatic verification.

The user owns the representative journey: approach the existing panel, find the
axis, hold E and look at the target, correct in both directions, SEAT, reach and
retain the connection, release the holder and return. First-use/repeat instruction
clarity, green marks, ghost pulse/readability, panel grouping and jog feel are
**unreviewed**, not established by the helper tests. Preserve these questions in
the [playtest checklist](robot-workshop-playtest-checklist.md#operated-rigs-open-questions--phase-1):

- Are the initial speeds comfortable while looking away from the panel, or is a
  slower final-approach rate needed? Proposed default: one constant jog rate per
  axis; tune from checkpoint B before adding another mode.
- Should RELEASE/REACQUIRE retain the constrained support-head service sequence,
  or should jaw/lower/withdraw/compact/outboard joints also get arrows? Proposed
  first slice: service taps, delivery axes fully jogged; do not silently expand B3.
- Do construction ROLL/LIFT/BOLSTER need all arrow pairs on the same face, or a
  clearly labelled construction bank? Proposed grouping: delivery and construction
  banks on the existing panels, with no relocated panel or hidden modal.
- Is the final foot guide turn acceptable as the short lead-in? Proposed default:
  1.1° green capture window and 0.5 s guide, preserving the existing sole pivot.

### Saves and checkpoints

**Implemented 2026-10-25 as a lightweight snapshot.** One local slot,
`user://workshop-save.json`, is written only when the player saves: the pause
menu's **Save** or **Save & quit**, or closing the window, which counts as Save &
quit. **Quit without saving** asks for confirmation when the build or a machine
changed since the last save. (Saving on every fit was dropped the same day at the
user's request; a crash loses work since the last save.) The slot holds the model,
each machine's `capture()` at its last stop, so motion is never saved halfway, and
the player's position, facing and look pitch. A save taken while the player rides
a moving machine stores where they last stood with nothing moving under them: the
deck at the stop that machine reloads at. A save without a player entry starts at
the spawn. A save is never refused. The service crane is the one machine saved
mid-move (`saves_in_motion()`): its pickups and transfers happen partway through a
move and the source/receiver contact follows its progress, so it is saved where it
is, stopped, as its own Stop leaves it, and Resume continues. Its load hangs where
it was. A crane end in the player's hand goes back to its stow. Saves from before
the crane was saved reload it parked. If writing the file fails, Save & quit and
a window close stay open on the pause menu with the reason. Loading is
synchronous: restore the model, place assembly bodies, let each machine `apply()`
its at-rest state, re-sync visuals, then stand the player where they saved.
Pockets, loose and held parts and the manual reset. An invalid file (unreadable, a different
`FORMAT`, changed identities, slots or machine fields, or failed integrity) is
deleted; there are no migrations, checksums or backups. Tests, tools and `--stage`
launches never touch the slot. The pause menu's **New workshop** deletes it. The one
ongoing rule: a machine's `capture()`/`apply()` must round-trip its at-rest state
(for the crane, any stopped point on a route), including where its supported load
sits. `save_roundtrip_test` checks a fresh boot, a mid-ride save and a mid-lift
crane save; the explicit-request diagnostic `save_roundtrip_stages_test` checks
every stage boundary and two points of each stage's first crane delivery. A replayed action log was rejected because late-game loads would be too
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
