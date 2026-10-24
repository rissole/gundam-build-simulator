# Backpack, power, and cooling

Last updated: 2026-10-24

[Design index](../../ROBOT_DESIGN.md) · [Shared design rules](../global.md) ·
[Proportions](../proportions.md#torso-and-backpack)

Connected interfaces: [chest/cockpit](chest-and-cockpit.md),
[pelvis/waist](pelvis-and-waist.md),
[shoulders](../arms/shoulder-and-upper-arm.md), [head](../head.md).
The [final assembly plan](../game/final-assembly-plan.md) owns derived workshop
dimensions; this document supplies its mechanical contracts.

## Scope, ownership, and coordinates

The confirmed compact backpack belongs to the torso. It opens upwards on two
separated brackets sharing a top horizontal hinge axis, with one support strut
per side and two recessed lower latches. The fictional cylindrical core remains
in the torso and moves straight front/back through a keyed rear dock. Its power
physics, internal machinery, output, and thermal performance remain unspecified.

The user delegated the interface decisions in this revision. Numeric choices
below are current working design decisions within the confirmed proportions,
coordinated with the chest and waist owners. They are inputs to source geometry
and access planning, not strength certification or inspected solid fit.

Use metres and robot coordinates: X right, Y forward, Z up, nominal sole datum
Z = 0. Workshop world mapping is (13 + X, 1.4 + Z, 26 − Y). Installation and
maintenance require the waist locked neutral, shoulders restrained in the reference
pose, and independent gantry support. Core, dock, and backpack follow the chest
during waist movement.

## Core packaging and interface

The core sits **below the cockpit**, avoiding competition for chest depth.
Chest owns the capsule, portal-shaped rear spine, surrounding frame, and structural
root pads; this document owns the cartridge, keyed guides, retention, and services.
No central spine member crosses the insertion path.

| Item | Current contract |
| --- | --- |
| Cartridge axis | X = 0, Z = 11.95, parallel to Y |
| Cylindrical body | Ø0.84; installed Y −1.03…+0.57 |
| Keyed forward nose | Extends to Y +0.65; fixed socket opens at Y +0.58 and ends at +0.72 |
| Rear flange | Ø0.94; Y −1.14…−1.03; two lower-diagonal guide-clearance slots |
| Complete core rear limit | Y −1.16, including recessed heads and service/lifting faces |
| Vertical bounds | Body Z 11.53…12.37; flange Z 11.48…12.42 |
| Fixed dock envelope | X ±0.56, Y −1.15…+0.72, Z 11.43…12.45 |
| Chest rear opening | Clear X ±0.72, Z 11.40…12.55 through the rear frame |
| Moving core/handling corridor | X ±0.65, Z 11.30…12.60, extending rearward from Y −1.15 |

The chest capsule begins at Z 12.55: 0.10 m above the dock and 0.13 m above the
flange. Its Y −0.55…+1.00 depth overlaps the core in plan, but the two are
separated vertically. Chest lower portal limbs X ±(1.08…1.32) bypass the opening
and waist tool windows; their low feet end at Z 11.38, 0.05 m below the dock.
The dock fits inside the chest's 2.4 m depth and remains inboard of waist tool
pockets starting at |X| 0.72.

### Guides, captive retention, and services

Two longitudinal lower-diagonal keys engage captured channels, nominal contact
lines X ±0.30, Z 11.65; ribs remain within radius 0.45. Different key widths reject
a rolled cartridge. Upper capture lips restrain pitch during supported insertion.
Channels span Y −1.10…+0.55, with rear/forward bearing regions
Y −1.10…−0.90 and +0.32…+0.52; a 0.10 m tapered mouth assists entry.
The rear flange slots pass those same continuous guides during removal.
The flange seats against a fixed ring; electrical contact compression is not the
hard stop. Contacts first engage near Y +0.63, allowing 0.02 m further guided
travel before the flange seats, with space remaining ahead of the nose.
Bearing fits, wear strips, and strength remain source-detail work within the
declared dock envelope.

Four recessed captive M16 retaining bolts enter forward along +Y into the fixed
ring. Their centres are cardinal points on radius 0.445:
(X,Z) = (±0.445,11.95), (0,11.505), (0,12.395), at rear face Y −1.14.
Heads stay within Y ≥−1.16. The 0.05 m radial flange annulus accommodates the
selected recessed M16 heads; actual counterbores and bolt variant require source
geometry confirmation. Cardinal bolts avoid the lower-diagonal guide slots.
All four retainers are required before crane release.

Fictional power/signal blocks mate at the forward keyed nose, isolated throughout
movement. There is no loose trailing core cable. Rear-facing interlock/enable and
isolation/status targets are respectively (+0.50,−1.16,12.18) and
(−0.50,−1.16,12.18), on the fixed dock outside the flange.
Retain, complete/check this rear connection, and confirm support before crane
release. Isolate/disconnect before undoing the bolts. Connector friction is never
retention; detailed contact technology and core circuitry remain outside this pass.

### Initial source-to-dock handoff

The prepared core rests horizontally on adjustable saddles of the shared bulky
fixture. Structural forward contacts, expressed installed, are two side-upper
pads (±0.30,+0.15,12.27). A removable equalizing bridge from the shared crane's
rigging set captures both pads and presents a centred magnetic-end attachment
(0,+0.15,12.53). Its right-side attachment/release handle is
(+0.42,+0.15,12.27). Use that visible handle from the robot-right flank; the
operator does not target an upward pad hidden behind the cylinder crown.
The bridge stays within X ±0.48, Z 12.22…12.56 and extends no farther forward
than Y +0.17 relative to the installed core. It leaves with the crane before
the core advances beyond the captured-guide handoff.

The aft magnetic end attaches directly to the rear-facing pad (0,−1.16,12.17),
separate from the upper flange bolt. Both effective lifting points lie on X =0,
so selecting a visible side contact does not introduce an offset suspension line.
The forward bridge shares load across its two contacts; the adjustable spreader
holds the cartridge horizontal. For the working mass-centre estimate
(0,−0.23,11.95), vertical reactions are approximately 71% forward/29% aft and
the centre is below the suspension line. Confirm actual source balance and trim
line lengths while the source saddles remain engaged; equal end loads are not
assumed. Both ends and both bridge contacts must carry securely before source
support release.

The body-cylinder access check uses R =0.42 about X =0,Z =11.95. From the
robot-right eye (1.90,−1.80,11.43) at the t =−1.35 handoff, rays to the
near contact (0.30,−1.20,12.27) and handle (0.42,−1.20,12.27) have minimum
cross-sectional radii 0.4386 and 0.5280 respectively, reached at their endpoints.
Thus both clear the nominal cylinder by 0.0186/0.1080 m; reach distances are
1.904/1.804 m. This checks the body cylinder, not unmodeled clamps or frame solids.

1. Before backpack installation, deliver at axial translation t = −2.20 m.
   Complete core bounds are Y −3.36…−1.55, leaving 0.40 m to the dock.
   Align keys, then advance along +Y with both crane ends supporting.
2. At t = −1.35, the body nose is at Y −0.78 and captured-guide overlap is
   0.32 m. The forward bridge remains outside, with its handle at Y −1.20 and
   forward edge Y −1.18. Stop and verify guide capture plus aft crane support;
   unload the forward end, release both bridge contacts from the right-side
   handle, and lift/stow bridge plus forward end. Then advance using rear crane
   support and captured guides, which supply complementary pitch/roll restraint.
3. At t = 0, both separated bearing regions support the core, the flange seats,
   and keyed services mate. Secure all four captive bolts and complete/check the
   rear interlock before detaching/stowing the aft crane end.

Seated, retained, connected, and crane-released are distinct states. Partial
insertion can return to the source with appropriate crane support. Do not release
the forward end before the 0.32 m captured handoff or close the backpack over rigging.

## Backpack attachment and motion

The complete closed envelope stays X ±1.20, Y −2.20…−1.20,
Z 11.30…14.10, including nozzles. Main rear shell is around Y −2.05; nozzle
mouths create the final rear projection. Front recesses accept the torso roots and
tucked struts; this envelope is not a solid block through those interfaces.

| Connection | Current location and ownership |
| --- | --- |
| Hinge axis | Along X at Y −1.20, Z 14.10; bracket centres X ±0.90 |
| Torso hinge roots | Chest pads X ±(0.80…1.00), Y −1.15…−0.95, Z 13.85…14.18, tied to spine/crossmember |
| Hinge pins | Two Ø0.06 × 0.24 working pins, axis X, 0.18 bracket stack; insert from outboard, one keeper each. Heads at |X| 1.02; 0.26 m outward extraction reaches |X| 1.28 |
| Fixed strut pivots A | (±1.08,−1.27,13.45); chest root rear limit Y −1.35 |
| Backpack strut pivots B, closed | (±1.08,−1.95,12.95); backpack owns struts and prepared B-end joints |
| Strut base attachment | One Ø0.04 working pin and keeper at each A end, axis X; outboard tool approach behind torso surface |
| Lower torso roots | X ±(1.05…1.18), Y −1.20…−1.00, Z 11.45…11.70, outside waist tool pockets ending at |X| 1.00 |
| Lower locators/strikers | Nominal (±1.11,−1.27,11.57); two tapered locating blocks and latch strikers near Z 11.55 |
| Latch operating faces | Two recessed rear-facing levers (±1.04,−2.04,11.55), linked to forward draw-hooks; backpack-owned |

Locating blocks establish closed position; the latches draw onto them. Tapered
entries accommodate the final closing arc. Neither a latch nor a partial hinge
pin supplies open support. Torso roots stay on the chest during backpack removal.

### Opening, struts, and sweep

Select **90° fully open**, with crane-assisted opening/closure. Passive telescopic
struts extend and lock positively at 90°. Both locks must be set before crane
release. Reacquire crane support before unlocking either strut for closure.

For a closed point, let r = −Y − 1.20 and d = 14.10 − Z. Over 0 ≤ θ ≤90°:

`Y(θ) = −1.20 − r cos θ − d sin θ`

`Z(θ) = 14.10 + r sin θ − d cos θ`

The bounding rectangle has 0 ≤r ≤1.0 and 0 ≤d ≤2.8. Rear excursion is
√(1²+2.8²) = 2.973 m at θ =70.35°, reaching Y −4.173. Maximum height is
Z 15.10 at 90°. Fully open bounds are X ±1.20, Y −4.00…−1.20,
Z 14.10…15.10. Reserve a planning margin X ±1.30, Y −4.30…−1.10,
Z 11.20…15.20 for the complete mechanism. This margin is not additional armor.

The rotating body stays behind the neck/head rear limits Y −0.95/−0.90, with
0.25/0.30 m separation before fittings. Shoulder and head geometry must respect
the full central rear sweep, including the side struts and services below.

At B, r =0.75 and d =1.15. Strut lengths are 0.844 m closed and 1.768 m open,
increasing monotonically. Select telescopic range 0.83…1.79 m and positive lock
at 1.768 m. Open B = (±1.08,−2.35,14.85).
A Ø0.08 body and 0.14 m-wide clevis/lock envelope fit |X| 1.01…1.15.
Eye articulation, telescope overlap, buckling, and lock strength require source
engineering; centre lengths do not establish those properties.

### Hinge services, vents, and nozzles

Two protected flexible service runs lie between the brackets, |X| 0.50…0.64,
above the core corridor and away from side struts. Fixed connector targets are
(±0.57,−1.24,13.88), rear-facing; backpack targets are
(±0.57,−1.48,13.96) closed and (±0.57,−1.34,14.38) open.
Select 0.95 m protected runs, minimum working bend radius 0.10 m. Retained loop
shapes must remain in Y −1.72…−1.24, Z 13.78…14.68 over the motion, and
Z ≤14.10 closed. Their lower bound is 1.18 m above the core handling corridor.
Connect/disconnect with the cover independently locked open. These loops supply
no lifting or core support.

Fixed recessed vent strips stay visible at |X| 1.36…1.64, rear surface Y −1.20,
upper extent Z 11.50…13.95. Aligned lower sections continue toward the pelvis
with a waist articulation break. Hinge-pin extraction at Z 14.10 passes above the
upper strip; preserve a clear tool cylinder radius 0.04 m. Individual slats,
lower-section mounts, and cooling internals remain later work.

Two modest Ø0.48 m nozzle mouths near (±0.55,−2.08,11.70) point rearward/down
15°. Their full bells/mounts must remain within the declared closed envelope,
especially Y ≥−2.20 and Z ≥11.30. No flight-performance requirement is implied.
Both rotate with the backpack and are included in the rectangular sweep.

## Backpack crane installation and closure

Prepare on the shared bulky fixture, front face down on adjustable perimeter
saddles, in the orientation corresponding to 90° installed opening. This exposes
rear construction faces without a dedicated backpack machine.
Structural crane pads (±0.72,−2.08,12.70) closed become
(±0.72,−2.60,14.98) open. The working mass-centre target is near
(0,−2.60,14.60) open, below the pad line. Trim the shared spreader and prove
balance on the source saddles; actual source mass distribution can change trim
without changing the hinge datum.

1. Attach both crane ends and lift from the fixture at the 90° orientation.
   Approach from rear with hinge datum 0.20 m above final, then lower to align
   both bracket stacks. Keep crane support while fitting both hinge pins/keepers.
2. Extend the prepared struts to both fixed A clevises, fit both base pins/keepers,
   and engage both 90° locks. Confirm load transfer to hinges plus both struts
   before releasing either crane end.
3. Detach/stow rigging from the upper rear flanks. Connect and retain both service
   loops with the backpack independently supported.
4. Reattach the crane to control closure, take load, release both strut locks, and
   close slowly. Check loop routing, locator seating, and both lower latches;
   then detach/stow crane ends and close small service covers.

Pads remain available after arms/head installation. Later opening starts with
crane support before lower-latch release; raise to 90°, engage both strut locks,
then detach the crane for core work. Use ordinary crane assistance and contextual
pin/lock/connection work. No permanent dedicated core/backpack console is required.
The wider-M3 implementation below now supplies these external operations on the
prepared stand-in; detailed internal source engineering remains deferred.

## Future core withdrawal with the complete robot

The 90° cover is a canopy above Y −4.0…−1.2. A vertical crane line to a core
withdrawn only 2.2 m would cross it. Initial insertion before backpack attachment
therefore cannot simply be replayed for later removal.

Use two removable **generic fixture guide rails/saddles**. Matching channels dock
to the existing guide ends (±0.30,−1.15,11.65) and extend to Y −6.30.
The [workshop fixture plan](../game/final-assembly-plan.md#gantry-support-and-rear-service-reservation)
supports them on two removable crossframes anchored to real low-deck flank
pads at worldX11.1/14.9,Z29.5 and 32.1. Crossbeam topsY12.60 and guide
upstands nearY13.05 leave≥0.28 m under the core. Do not place ungrounded posts
in the central platform opening or assume a free5 m cantilever. The narrow
central guide envelope remains robotX±0.45/Z11.45..11.80; crossframe feet
extend outside it to the side decks. Joined spans, locks and strength remain
equipment engineering. These are reusable fixture beams, not a dedicated machine.

Set up/secure the rails while the core remains bolted. Isolate/disconnect rear
services, establish rail capture, then release the four captive bolts.
An integral rear handgrip (0,−1.16,11.85) moves with the flange, below its lifting
pad. A removable fixture carriage captures that grip and uses a guarded reversible
chain drive along the generic rails. Its handwheel is fixed at
(+0.75,−2.75,10.90), below/outside the core corridor; operate from the accessible
forward rear-deck flank near (+1.90,−2.75,9.80), approximately 1.27 m eye-to-wheel
at the actual 1.63 m eye height.
Ordinary contextual crank/advance handling moves the supported core; a mechanical
brake and end stops retain every paused position. This is a reusable fixture
control, not a permanent core console. There is no need to walk beside the load
across the gantry crosshead or carry its weight.

Withdraw t =−5.00 m. Complete core bounds become Y −6.16…−4.35, fully aft
of the cover's conservative swept allowance Y −4.30. Both lifting locations are
also aft of that boundary. From the robot-right aft finger, place/capture the
forward bridge using its visible side handle, then attach its centred magnetic
end; attach the aft end to the rear-facing pad. The crane can then lift vertically
without crossing the cover. Keep rail support until both ends and both bridge
contacts take load, then return to the shared fixture. Reverse this supported
transfer to reinstall; secure and connect before fixture removal. This future
maintenance/local-correction contract is not a required full-teardown gameplay
acceptance run.

## Access, workshop consequences, and remaining evidence

The coordinated layout reserves the rear central opening through worldZ35.3
and puts the rear crossover atZ35.8..37.3. The normal cover sweep reaches
Z30.173; service rails reach 32.30 and extracted flange32.16. Aft work fingers
startZ31.7, beyond the revised low crosshead ending31.4. They remain fixed; rear deliveries cross above the platforms before
lowering in the central opening.

Initial core and open-backpack deliveries use the shared **low outboard bypass**
at worldX23.7, with core axisY6.0 or pack hingeY5.5. At rear frame originZ32.4
(core) or hingeZ31.8 (pack), shift outboard toX24.0 and raise the lowest point
toY18.0. Cross inward above the highest platform guards, then lower in the
central rear opening to core axisY13.35 or hingeY15.7. Only then approach the
robot. Low inward travel is excluded because its vertical crane lines would
cross the outer walks. All rear fingers and crossover stay fixed. The old high
gantry crown is removed because it would obstruct cables on the final approach.
The [workshop route contract](../game/final-assembly-plan.md#one-crane-and-measured-loaded-routes)
owns outboard-well dimensions, crane projections, guard/headroom margins and
supported return. It uses the same shared crane and no extra moving rear platforms.

| Work | Working position / clearance input |
| --- | --- |
| Core bolts/services | Existing outer rear flanks, world deck Y 11.2 = robot Z 9.8; worker centres X ±1.90,Y −1.80, eyes Z 11.43. Top bolt reach 2.231 m, nearest side bolt 1.680 m, lower centre bolt 2.013 m. Use each flank for its nearer side bolt/connector; do not reach the opposite side bolt across the core |
| Forward guide handoff | Same robot-right flank; visible bridge side handle 1.804 m away at t =−1.35, with body-cylinder ray clearance established above |
| Closed lower latches | Same deck, worker centres X ±1.90,Y −2.65, outside closed footprint |
| Hinges, strut joints/locks, services | Upper rear side fingers world Y 14.0 = robot deck Z 12.6; centres X ±1.90,Y −1.75…−2.20, eyes Z 14.23; the 0.26 m body radius stays inside the current outer flank |
| Upper reach examples | From (1.90,−1.85,14.23): hinge 1.200 m, fixed strut pivot 1.272 m; from (1.90,−2.20,14.23): open crane pad 1.454 m; mirror opposite side |
| Upper platform opening | Clear X ±1.30,Y −4.30…−1.10 over Z 11.20…15.20; worker centres outside sweep plus body radius |
| Maintenance fixture control | Fixed handwheel before worldZ30.1; crossframes span from actual side-deck pads. No continuous walk across the low crosshead worldZ30.8..31.4. |
| Aft rigging access | Low fingers start worldZ31.7, outside centralX11.4..14.6. Use forward eye robot(1.90,−6.00,11.43), worldZ32.00; at t=−5 the near bridge contact(0.30,−4.85,12.27) is≈2.142 m away and side handle(0.42,−4.85,12.27)≈2.053 m. Endpoint radial clearances to the cartridge remain0.0186/0.1080 m; actual handle/ray solids still need checking. Rear pad from eye(1.90,−6.20,11.43), worldZ32.20, remains≈2.039 m away. These fit2.35 m reach with real foot patches. |
| Rigging overhead | Open pad world Y 16.38; 0.20 m install approach +1.20 m rigging gives hook ≈17.78, below proposed 23.0 obstruction; actual fittings still require measurement |

Use the existing outer low flanks; no new inward service fingers are required.
The selected centres |X| 1.90 leave the player outside the backpack footprint.
The closed cover's Z 11.30 underside is only 1.50 m above the Z 9.80 deck, so
standing beneath it remains excluded. Core services/retention require the cover
locked open. Rear-face bolt/connector rays approach from behind the flange and
frame roots; source detail must retain that rear tool corridor. Assisted tool
heads align with the +Y bolt axes while operated from the outer flanks.

Straight-line reach is an allocation, not proof of tool/hand access, occlusion,
avatar clearance, label readability, or player approval. Upper side fingers and
their approach need fitted arm/pauldron/head geometry. No early-installation order
is used as a substitute for those future clearances.

For waist lean ±10° about X at Z 10.90, the conservative low/rear corner
(Y −2.20,Z 11.30) reaches Y −2.236,Z 10.912. The pelvis owner's fixed armor
ends at Y ≥−0.90,Z ≤10.40; fixed lean supports Y ≥−0.70,Z ≤11.08.
The moving waist cradle shares chest motion and has conservative rear/upper
bounds Y ≥−1.12,Z ≤11.48 over its motion. At the limiting low rear corner,
there is over 1 m fore/aft separation to the fixed pelvis. Full yaw ±25°/lean
solid clearance, including nozzles, guards, and gantry support arms, remains a
source-geometry check. Opening/core service require neutral waist locks.

### Interface allocation and review plan

Core preparation supplies one cartridge, integral flange/keys/lifting contacts/grip,
and four captive retainers. Chest preparation supplies dock/ring/guides, rear
service faces, hinge forks, strut A roots, lower blocks, and strikers.
Core installation owns seating, the four captive retaining operations, rear
connection, and crane release. Backpack preparation supplies its frame/cover,
nozzles, hinge eyes, both struts with prepared B ends, both latches, service runs,
and crane pads. Backpack installation adds two hinge-pin/keeper pairs and two
strut-base-pin/keeper pairs, makes services, and closes/latches. These are
interface allocations, not a complete manufactured inventory. Pool repeated
compatible hardware only when actual geometry is identical.

This pass checked written packaging, rectangular hinge rotation, strut lengths,
supported handoffs, canopy obstruction, exact 1.63 m eye-height reach, and rays
against the nominal body cylinder by arithmetic.
No models, gameplay, game tests, or rendered review were produced.

Before implementation:

1. Check actual capsule/spine/waist/dock solids; captured partial insertion;
   flange guide slots/counterbores; service mating; both crane handoffs.
2. Check hinge/pin entry, source balance/all crane-line paths, strut articulation,
   overlap/locks, loop bends, locator/latch closure through 0…90°, with head,
   arms/pauldrons, vents, and pelvis support arms fitted.
3. Check reusable rail joints/supports, fixed handwheel/chain/brake, and continuous support through 5 m
   withdrawal; actual core and both lifting pads must clear Y −4.30 before lift.
4. Author/check the ordinary-input initial build and supported local correction,
   hardware/slot conservation, and save/resume at handoffs. Inspect player access
   and readable targets in the eventual build; rendered review only when requested.

Strength, materials/ratings, complete inventories, internal power/cooling/thruster
machinery, and final cosmetic surfaces remain later work. Revise agreed interfaces
only for a measured conflict and coordinate the affected neighbors.

## Wider-M3 core implementation — 2026-10-24

`game/workshop/tools/author_m3_core.py` now supplies one prepared core, fixed
chest dock/guides and the external installation manual. Its existing physical
assembly moves from a passive store at world `(-7,1.30,31.30)` to the shared
bulky fixture at `(3.25,1.30,13)`. The storage route raises the axis to Y6,
travels to Z13 and crosses to the fixture. Core saddles contact its lower keys;
two upper clamps release after both crane ends take weight. Empty-fixture insert
selection and supported return to the same store preserve independent preparation
order. Internal power machinery is supplied; no extra loose stock is invented.

The rear task follows the selected X23.7 low bypass, X24 lifting well,
Y18.47 high crossing, X13 lowering and Z28.2 rear approach. The separate
`core_guide.gd` controller advances0.85 m to the 0.32 m captured overlap,
transfers ownership to the guide, and permits release of only the forward bridge.
Further insertion requires that bridge stowed and retains aft crane support.
Flange seating mounts the core into the already mounted chest. Four individually
operated PC-H16 captive bolts and the rear interlock precede aft-end release.
Isolation remains possible with structural retention intact; bolt release requires
aft support. Local correction returns to capture, restores both-ended support,
then returns out of the guides without changing physical identity.

Actual rigging is part of collision verification. At capture, the unloaded
forward equalizer folds and the crane head shifts aft before deeper insertion.
Return first reaches capture; a further Return extends the empty forward rig
before bridge reacquisition. Interrupted folding saves/restores independently of
insertion travel. In Godot core-local axes (Y up/Z rear), the full head centre is
`(0,1.75,0.60)` and the compact aft head is `(0,1.39,1.35)`; spreader dimensions
change from0.28×0.18×1.64 to0.28×0.18×0.34 m. These authored settings leave the
full beam's front at chest-local Z1.13 at capture, beyond the rear spine at1.10;
the compact beam front is1.18 when seated. Load contacts remain unchanged.
The removable bridge stays within the selected forward Y+0.17 limit. Its visible
adapter stays with the forward cable when held or stowed.

The fixed receiving ring now has reliefs for the two lower guides and permanent
upper lifting pads; a plain circular bore obstructed those pads. Side webs extend
to radius0.55 while the upper/lower cardinal bounds remain0.50, inside the
selected dock envelope. Four cardinal threaded bosses remain. A positive-X nose
key and matching receiver reject a rolled cartridge. Moving collision compounds
preserve cylinders, T keys and flange notches; they do not replace the core with
a bounding box or exclude the receiving chest from guided movement checks.

The original path contract already reserved crane-line clearance. Implementation
initially omitted complete rigging from sweeps and parked access barriers in that
reserved bypass. This was an implementation/verification miss, not an unresolved
route decision. Barriers now stow inboard behind the closed wings. Core route and
handoff sweeps include the spreader, loaded/stowed bridge, both end lines and the
mast cable; only the crane's own bridge/trolley contact hardware is exempt.

The wider-workshop ledger records mechanical/source checks and fresh-scene save
coverage. These do not establish walking, reach, visibility, inspected rendered
presentation, structural ratings or human approval. Backpack implementation and
its open-cover interlocks remain next; complete-robot maintenance extraction is
not represented by the initial-installation/local-correction fixture.

## Wider-M3 backpack source and route preflight — 2026-10-24

`game/workshop/tools/author_m3_backpack.py` supplies the prepared frame, rear
panel, two nozzles, hinge eyes, lifting pads, three-stage struts and lower latch
stand-ins. These16 source pieces belong to one prepared assembly and add no loose
consumable stock. The fixed hinge/strut clevises remain chest-owned. The source
uses the hinge as its origin, with Godot X right/Y up/Z rear in the90° open pose.
A+90° rotation about local X produces the closed pose without moving the hinge.
Internal construction is still supplied rather than another playable branch.

The passive store is at world `(-7,0.85,35)`; the common fixture hinge datum is
`(3.25,0.85,13)`. Storage transfer raises the hinge toY5.5, travels alongX−7
toZ13 and crosses to the fixture. It clears the chest while the chest is still
stored. Four perimeter pads contact the downward-facing frame at localX±1.18,
Z0.50/2.40, worldY0.96. Four upper clamps contact atY1.63. Fixture crossmembers
connect these inserts to its lifting frame; the passive store's floor legs are
not part of the moving insert. One contextual insert-selection button cycles the
empty fixture's sets. Height adjustment, interrupted contact, crane reacquisition
and return to the same store preserve the assembly identity.

The complete source and rig have been checked against the existing rear route:
hingeY5.5 → X23.7 → Z31.8 → X24 → Y18 → X13 → Y15.7 → Z27.2 → Y15.5.
No route waypoint changed. Actual hinge eyes extend0.065 m below/forward of the
ideal open-body rectangle. They remain inside the reserved lifting well and
mechanism margin: the high crossing's lowest material isY17.935,0.435 m above
the highest guard, and its front at the lowering waypoint isZ31.735,0.335 m
behind the crosshead. This hardware extension is included in actual-solid checks,
not silently rounded back to the nominal box. Pack width stays2.40 m, rear
reach2.80 m, and nozzle tops remain below hinge+1.00 m.

Two pads remain at open-local `(±0.72,0.88,1.40)`. The1.72×0.18×0.34 m spreader
uses anchorsX±0.72. Its head is at least2.08 m above the hinge throughout
closure, with cable payout accommodating the changing pad height. Following the
lowering pads with a fixed short drop would put the bar inside the closing cover;
the preflight explicitly rejects that configuration. The0.09 m magnetic shoes
seat on and rotate with the pad normals; cables attach at the shoes' outer faces,
so they do not graze the rotating pad edges. The mast, both suspension lines,
both ends and spreader are included in the route check and the separate
payload-against-own-rig check.

Hinge eyes are0.094 m wide in0.100 m fork openings, withØ0.061 m actual bores.
The chest root's rear relief and the pack's narrow hinge stems keep that gap open.
The lower side frame leaves0.01 m in front of the locator roots when closed.
Strut A/B eyes are0.074 m wide in0.080 m clevis openings, withØ0.041 m bores.
Three telescoping members fit the selected0.844…1.768 m centre lengths:
outer/middle/inner lengths0.72/0.70/0.70 m, radii0.040/0.031/0.023 m, with
positive overlap at both ends. Their articulated source solids are included in
the preflight closure sweep. This does not establish structural ratings.

`backpack_preflight_test.gd` checks actual source bounds, saddle contacts, hinge
bores, the entire loaded route and closure sweep against a staged receiving
chest/core. It rejects the forbidden inward low crossing and the self-colliding
spreader configuration. `backpack_fixture_test.gd` exercises source exchange and
fresh-scene interrupted restores. The implementation ledger records the combined
run. These are geometry and mechanical checks, not walking/access or rendered
approval. This source increment preceded the installation/closure implementation
recorded below; preflight articulation alone was not player-operation evidence.

## Wider-M3 backpack installation and closure — 2026-10-24

`backpack_hinge.gd` now owns temporary crane loading, continuous telescope
deployment, positive open locks, hinge angle, draw latches and service covers.
The24 prepared source pieces remain one physical backpack. Ten external stock
instances add twoBP-P60 hinge pins/twoBP-K60 keepers, twoBP-P40 strut-base
pins/twoBP-K40 keepers and twoBP-SERVICE protected runs. Compatible copies remain
interchangeable; the60 mm and40 mm variants cannot substitute for each other.
Pins have actual working shafts, heads and inner keeper grooves. The matching
forks/eyes retain their actual through bores. Parent chest pages own these11
mounting slots; captive operations are overview/status work, not invented loose
inventory. Authoring audits reconcile each slot and its source identity.

Backpack to hinges follows the already checked rear route, then lowers0.20 m
to the hinge datum. Seating mounts the existing assembly under the chest while
both ends retain its weight. Both hinge pin/keeper pairs precede telescope
deployment; both strut pin/keeper pairs precede either positive open lock. Both
locks are required for crane release. Service plugs require the independently
locked-open cover and stowed rigging.

For closure, the existing crane console offers Take backpack weight, followed
by Open/Close and Stop/Resume. Taking weight is an explicit resumable phase,
raising the head0.06 m without moving the payload. Only then can either open
lock release. Both serviced struts telescope throughout the controlled90°
movement. At the closed locator stop, two prepared draw-hooks capture the fixed
lower strikers; their levers draw the final2 mm into contact. Both latches precede
crane release, then the two small service covers close. The mesh and collision
poses of the telescopes, levers and covers follow the mounted assembly together.

Reopening requires opening the covers, refitting both ends and taking weight
before releasing either lower latch. At the open stop both positive strut locks
must engage before rig release or service removal. Supported local correction
disconnects the services, reacquires crane support, releases the locks and permits
pin/keeper correction. Hinges cannot be undone while either strut is still pinned
or extended. Full teardown is not a verification gate. Initial core correction
cannot bypass the fitted backpack; the complete removable maintenance-guide
workflow remains the separately deferred scope.

The mount projection and save validator derive backpack pose from its chest
parent and saved hinge angle. They reject displaced mounted poses, open locks
during closure, pinning an undeployed eye, incomplete connections before movement,
and a load that loses crane support before its open locks or closed latches secure
it. Captures include stopped telescope deployment, partial weight transfer,
partial closure, independent open support and completed closed covers.

The protected service runs use a bounded display/clearance proxy with tangential
entries into the moving sockets. The selected0.95 m supplied length and0.10 m
minimum internal bend radius remain source-engineering requirements; the visible
proxy does not model constant-length wire slack or certify internal bend radii.
Its external swept volume is checked against the receiving frame and the actual
rotating backpack, including its front crossmember. This is the M3 representative
service connection on prepared modules, not a completed detailed harness model.

The implementation ledger records the combined mechanical regression results.
No automated walking/connection-access sweep or rendered review is claimed.
