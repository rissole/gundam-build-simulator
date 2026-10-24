# Pelvis and waist

Last updated: 2026-10-24

[Design index](../../ROBOT_DESIGN.md) · [Shared design rules](../global.md)

Connected assemblies and clearance checks: [thigh and hip](../legs/thigh-and-hip.md), [chest and cockpit](chest-and-cockpit.md), [backpack, power, and cooling](backpack-and-power.md).

Dimensions and reference pose: [shared proportion layout](../proportions.md#torso-and-backpack).

## Confirmed design

### Interface and armor

- The pelvis belongs to the torso assembly.
- Each pelvis hip socket receives the ball at the top of its corresponding leg.
- Each socket retains its ball with a bolted, removable two-piece ring around the ball's neck.
- Two short front hip guards overlap the tops of the thighs.
- Small hinged outer hip plates attach to the pelvis.
- Keep these guards compact enough to preserve humanlike proportions and leave the upper thighs visually prominent.
- Preserve the narrow mechanical gap above each thigh's armor.

### Pelvis frame

- A braced structural bridge connects the left and right hip socket housings.
- The two socket housings are separate components bolted onto the frame.
- The waist mount sits above the center of the bridge.
- The working frame and socket attachment below develop this concept; they do not change the established ball/ring retention.

### Hip actuation

- Compact angled linear actuators with jointed ends connect pelvis brackets to attachment lugs below each hip ball.
- Most of each actuator is sheltered behind the hip guards; short rod sections remain visible through the gaps.
- Accessible removable pins at the thigh connections allow the actuator connections to detach when removing a leg.
- The user's direction is to reserve hydraulics for larger leg joints, including the knees. The selected working interpretation below uses three double-acting hydraulic cylinders per hip, retaining the ball's three rotational degrees of freedom.

### Waist connection

- A rotary waist bearing allows the chest to turn relative to the pelvis.
- A forward/backward pivot sits above the rotary bearing, allowing the chest to lean independently of the pelvis.
- Both mechanisms belong within the torso assembly.
- The working layout below selects movement limits, drive packaging and the chest receiving connection without changing these two joint concepts.

## Working interface specification — 2026-10-24

These are numerical design choices made under the user's delegated design
authority. Confirmed joint concepts and main proportions above remain in force.
This is a dimensioned design and assembly contract, not a load certification,
solid-model clearance result, implemented manual or inspected game presentation.
The [active workshop plan](../game/final-assembly-plan.md) owns equipment geometry;
its platform levels must accommodate these robot connections.

### Coordinates, ownership and delivery state

Use robot **X right / Y forward / Z up**, metres. Neutral hips are
`H = (s × 1.10, 0, 9.20)`, where `s=+1` is right and `s=−1` is left.
The waist bearing centre is `(0,0,10.50)`. For workshop comparison only,
`world=(13+X, 1.4+Z, 26−Y)`. World vertical Y11.90 is the bearing centre;
the chest seating plane is **robot Z11.30 / world Y12.70**.

The torso owns bridge, socket housings/liners, hip retaining rings/hardware,
pelvis-side cylinder brackets, six hip cylinder cartridges and their removable
pins, waist mechanisms, service disconnects and pelvis guards. The legs own their
integral balls/necks/spars, cylinder lug carriers, stop tongues and leg service
tails. The chest owns its lower flange and connecting bolts/washers; the waist
owns the receiving seats, keys and captive threads. Equipment supports and
rigging never become robot parts or additional assembly inventory.

Prepare bridge, both sockets, rotary bearing and lean mechanism together on the
bulky fixture. Leave hip retaining halves, cylinders, stop-cage closures and hip
guards off for upward ball entry and underside work. Engage both waist neutral
locks. The prepared delivery envelope is X±1.78, Y−.90..+.90,
Z8.85..11.42; its width comes from the existing socket flanges, not enlarged fixed
pelvis armor. Supply loose connection items separately. Chest preparation and its
fitted cockpit remain a distinct later crane load.

### Bridge, socket housings and gantry contacts

Retain a rear crossbeam centred `(0,−.65,9.70)`, 2.70 wide × .30 deep × .26 high,
developing the existing M3 rear bridge rather than putting a solid beam through
the balls. A central box pedestal occupies X±.24, Y−.50..+.25,
Z9.75..10.35; two separate diagonal braces run from `(±.95,−.65,9.80)`
to `(±.42,+.25,10.35)`, within .18-wide/.18-deep swept member envelopes.
The rotary baseplate sits at Z10.35..10.41, X±.73/Y±.73. Brace/frame joints
are made at the workstation before the bearing covers them. They remain a frame
subassembly; their detailed weld/bolt fabrication is outside this interface pass.

Each socket's rear saddle has a horizontal structural seat at Z9.74, centred
X=`s×1.10`, Y−.60, with a .46-wide × .30-deep tongue into an open pocket in
the crossbeam. Integral transverse shear keys take lateral load. Two downward
M36×160 bolts and two 6 mm washers per housing have axes
`(s×1.10±.15,−.60)`; a .06 bridge cap leaves approximately .094 thread
engagement. Keep Ø.16 tool access above these axes while the waist frame is being
built. Left/right housings with integral cylinder-bracket roots are a **mirrored
pair**: their three roots are reflected in X while both saddles stay rear. Their ball,
liner, ring and ring-bolt interfaces are identical. The small M3 contextual rear
blocks/four M24×90 representations are historical simplified construction, not a
validated hardware schedule for the finished pelvis. This new housing attachment
does **not** alter M3's four M24×140 ring bolts per hip.

Two gantry bearing patches on the rear crossbeam underside are centred
`(±.65,−.65,9.57)`, each .24 X × .26 Y. Their world centres are
`(12.35/13.65,10.97,26.65)`. Use four workshop hold-down jaws on the matching
top/rear crossbeam patches, X±.65/Y−.55 and −.75, with clamp contact at
Z9.83. Bottom seats carry weight; clamps prevent lift, slide and overturning.
The coordinated workshop portal uses outboard operating handles at world
X11.95/14.05,Y11.10,Z26.60/26.85, linked to these four jaw contacts. Operate
from rear hip-deck stances X11.6/14.4,Z27.75, beside rather than beneath the
bearing beams. The bulky source fixture supports the same bridge pads with hip
datum(3.25,1.20,13). See the [fixture plan](../game/final-assembly-plan.md#gantry-support-and-rear-service-reservation).

The jaws contact plain bridge material, not liners, guards, cylinder brackets or
waist bearings. Keep the jaw/arm envelope below Z9.90 and in the rear band
Y≤−.45. Existing M3 support arms need new bearing height/details; their present
shape is not proof of contact with this bridge.

Four structural lifting eyes are centred `(±1.15,±.70,9.95)`, each with a clear
Ø.10 rigging hole and a .16-radius attachment working volume. They sit on short
side outriggers from the bridge above each socket, separate from the ball entry.
A spreader with attachment corners X±1.35/Y±.90 keeps rigging outside the waist's
X±1.10/Y±.80 envelope; allocate at least .45 m between upper keys and the
spreader underside. Source fixture pads use the same crossbeam bearing patches
and release only after all lifting attachments take load. At the gantry, both
seats and all hold-downs plus engaged waist locks are required before rigging
release. Retain access to lifting eyes from front/side landings after seating.

### Established hip seating and structural retention

The [implemented structural interface](../game/leg-prototype-interface.md#hip-and-pelvis-retention)
remains authoritative here:

| Feature | Robot/hip-relative working geometry |
| --- | --- |
| Integral leg ball / neck | Ø.900 / Ø.300; neutral ball centre H |
| Socket bowl | Spherical inner radius .456, outer .530; lower entry radius .460; lower flange entry radius .490 |
| Retaining halves | Two identical semicircular PV-120 halves, .080 thick, inner/outer radii .300/.680; Z=H.Z−.430..H.Z−.350 |
| Ring bolt axes | Four at 45°,135°,225°,315° on R.575 in XY; Ø.026 clearance bores |
| Ring hardware | Four upward M24×140 and four .004 washers per hip; .080 ring plus .004 washer leaves .056 engagement in the .070 socket flange |
| Ball approach | Upward along +Z, ring and later stop cage absent; final .12 m guided seating stroke after ball/entry axes coincide |

These halves remain interchangeable by 180° rotation, including across hips;
their installed pose and consumed physical identity remain separate. Do not pool
M24×140 ring bolts with the leg's M24×100 fork bolts. Washers of the established
LG-W24 type remain shared compatible stock. Preserve each ring bolt's underside
approach: reserve R.08 about its vertical axis from Z=H.Z−.65 to H.Z−.43.
New descending brackets stay at radial distance ≥.76 through this height and do
not cover the ring bolt circle. Either retaining half may be installed first.
The ball is retained only after both halves and all four washer/bolt pairs.

For the finished joint, structural retention and independent pose support are
separate conditions. Keep the leg rail engaged through cylinder installation and
engagement of the three cylinder neutral locks described below. M3's earlier
structural-only holder-release endpoint used prototype mechanical restraints; it
does not establish that an unpowered freely swivelling ball supports a finished
leg pose.

### Hip articulation and mechanical limits

Select forward/back swing **+15°/−10°**, outward/inward splay **+15°/−6°**,
and thigh twist **±10°**. Combined swing is limited to a **16° cone**, so both
15° maxima cannot occur together. For the right hip, apply
`R=Ry(−splay) Rx(forward) Rz(twist)` about H; mirror X for the left hip.
The cone test is `acos(cos(forward) cos(splay))≤16°`; twist is about the
resulting leg axis. Cylinder calculations below used the stated explicit R sequence; authored
poses must preserve that sequence rather than mixing Euler conventions.

The authoritative ring is the limiting inherited geometry. At its lower face,
the tilted neck requires approximately
`.43 tan(16°)+.15/cos(16°)=.279 m` radius, leaving .021 m inside the .300 hole.
At roughly 18.3° it uses the full aperture. Wider walking strides cannot be
promised without changing the confirmed structural interface; this pass keeps it.

A removable split stop cage sits below the retaining ring, Z=H.Z−.82..−.60,
outer radius .46. Its conical bearing lip has radius .335 at Z=H.Z−.620,
meeting the bare neck at approximately 16° before it reaches the ring. A
leg-owned collar below that lip occupies Z=H.Z−.76..−.72, with .160 body
radius and two tongues reaching .220. Its swept tongues engage spherical side
windows in that cage to limit twist; do not put a .300-radius collar through the
.335 lip. Lower cage openings widen around the tilted collar.
The window flanks follow the permitted tilted-neck sweep with ±10° twist, rather
than using flat vertical slots that would bind during splay. The cage comprises
two identical halves, joined by four M12×60 bolts/four washers after ring
retention; it is a stop/guard, **not a second structural ball retainer**. Leave
its seams and bolts visible below the ring until the final guard step. Actual
flank contact and ball/neck transition clearance need the future solid sweep.

### Three-cylinder hydraulic hip drive

Three non-coplanar, double-acting cylinders control the three ball rotations.
One or two cylinders would leave at least one unrestrained degree of freedom;
six antagonistic cylinders add bulk without being needed for this working
double-acting layout. Each complete cartridge includes barrel, rod, spherical
eyes, local load-holding valves and a positive external neutral index lock.
Pressure supply/return comes from the pelvis manifold; actuator internals and
force/pressure ratings remain a later engineering task.

Define right-hip-relative upper centres A on radius .78 at angles 0°,120°,240°,
Z−.60, and lower centres B on radius .48 at angles 45°,165°,285°, Z−1.80.
Angles are measured from +X toward +Y. Mirror X for left; do not merely rotate a
right-handed lug carrier into the left leg. Rounded neutral coordinates:

| Cylinder position | A: pelvis spherical-eye centre | B: leg spherical-eye centre | Removable pin entry/extraction side |
| --- | --- | --- | --- |
| Outer/front | `(+.780,0,−.600)` | `(+.339,+.339,−1.800)` | Robot +Y at both ends |
| Inner/front | `(−.390,+.675,−.600)` | `(−.464,+.124,−1.800)` | Robot +Y at both ends |
| Inner/rear | `(−.390,−.675,−.600)` | `(+.124,−.464,−1.800)` | Robot −Y at both ends |

All coordinates are relative to H, with X mirrored on the left. Spherical eyes
accommodate the axis mismatch between the two parallel pin axes as the leg moves.
Use Ø.060×.220 shouldered pins, Ø.062 clevis bores, .090-wide spherical eyes
inside .094 clevis gaps and .050-thick cheeks. A head at the stated entry face
and a captive cross-keeper at the far face provide removable retention. Each pin
needs .34 m of unobstructed entry/extraction along its stated ±Y side and an R.08
tool/release tube. Keeper operation is from the same service side via a captive
release tab; do not put a loose nut behind the inaccessible cheek.

Pelvis clevises descend from the socket housing along R≥.76 outside the ring
and end **below** it at H.Z−.60; cylinders never pass through the retaining
annulus. Lower clevises are separate bolted lug carriers on the upper spar,
fitted during leg preparation. Preserve a plain spar/contact/service channel
between them; these lugs do not create a separate hip swivel. Bracket roots and
lug carriers are handed left/right pieces. All six cylinder cartridges, twelve
eye pins and their captive keepers are one compatible type per function: a
spherical eye and an external collar clockable at the workstation allow the same
cartridge to serve all positions and sides.

Select eye-centre length **1.02..1.68 m**, stroke .66, neutral length 1.323 m;
barrel Ø.140, rod Ø.070, spherical-eye outside Ø.160. The closed cartridge's
length budget is .76 for barrel/rod accommodation plus .26 for eyes/end fittings;
this is packaging, not a complete cylinder design. Keep .08 radius around the
actuator centreline and permit at least 30° spherical-eye articulation.

A document-level sample of 5,720 poses, stepping forward/splay by 1° and twist
by 2° inside the stated cone, gave lengths **1.059..1.625 m**. At neutral, the
length-change Jacobian rows are `B×(B−A)/|B−A|`, using rotated B at each pose; its determinant remains
positive and at least .296 m³ over these samples. This supports the chosen three
independent drive directions; it is not a force/conditioning certification or
proof between samples. The sampled right-hip endpoint box is
X−.664..+.851, Y−.784..+.846, Z−1.863..−.600 relative to H; enlarge by .08
for cartridges, fittings and initial guards. Mirror X on the other side. Fixed
armor stays 3.0 W × 1.8 D. The neutral outer hinged guards may reach X±1.96;
the front/rear cartridge bodies remain inside Y±.86. Check moving thigh armor
against the enlarged swept box instead of inflating the confirmed fixed armor.

Each cartridge's **external** telescoping index rail accepts a captive Ø.020 pin
only at neutral length. It bypasses the pressure chamber; never drill a lock
through the working rod. All three positive locks plus both eye pins/keepers of
all three cartridges constrain the unpowered neutral hip pose without crane or
leg holder. Load-holding valves provide hydraulic fault protection but do not
replace these positive workshop locks. Engage locks while the rail still holds
the neutral leg; then release and withdraw the rail. For powered motion
the index pins withdraw to captive parked detents. Reacquire the rail and engage
all locks before any cylinder or ring undo. General knee/ankle restraints remain
their owning components' responsibility.

### Hip services, guards and reachable work faces

Put one four-way service block on each pelvis housing at
`(s×.78,+.70,9.05)`, facing +Y: electrical power/data and a pair of dry-break
hydraulic supply/return connections. The leg-side matching block is at
`(s×.78,+.60,8.35)`; its leg-owned protected U-loop has .95 m available free
length and .12 minimum bend radius in the front-inner channel. Cylinder hoses
stay on the pelvis side, two ports per cartridge with local valves, routed around
the housing exterior before crossing into the manifold. No hose crosses a ring
bolt axis, ball entry, removable pin tube or the inner gap between the two legs.
Leave .18 m connector withdrawal and R.10 hand clearance toward +Y. Clips release
before a loop is unplugged; seal caps are captive. Core/power details do not
create duplicate leg harness items.

Two compact hinged front guards cover the pelvis-side cylinders/services and
overlap the thigh top. Their neutral bounds are each approximately
X=`s×(.45..1.45)`, Y+.76..+.92, Z8.35..9.50; an outboard hinge swings each
70° away from its front service face. Small outer hip plates cover the outer
clevis, approximately X=`s×(1.70..1.96)`, Y±.45, Z8.30..9.35, with an upper
hinge opening outward 65°. Rear cartridge fittings use a removable rear lower
service cover inside Y−.90, Z8.25..9.45. Guard open/closed poses do not authorize
hip movement. Keep guards removed for initial installation; fit/close only after
pin keepers, positive locks, service routing and leak/electrical checks are done.
Upper-thigh channels stay exposed around the rod/lug movement envelope. Final
guard outline and edge overlap require the later armor/solid pass.

Use shared **world deck Y8.40**, with front/rear open inner edges at robot
frontY+1.40 (worldZ24.60) and rearY−1.35 (worldZ27.35),
and standing lines robotY+1.70/−1.65
(world Z24.30/27.65). The eye is world Y10.03 using the current 1.63 m eye
height. Keep the existing M3 side finger for ring underside work; front/rear
strips add pin, hose and guard access. With the right leg at world X14.10, lower
pin standing X values are **14.439, 13.636, 14.224** for the table's three
positions. Left equivalents are **11.561, 12.364, 11.776**. The first two
positions use the front strip, the third the rear. Target height is world Y8.80;
their exact target Z values are 25.661,25.876,26.464. Eye-to-target distances
are approximately **1.83,2.00,1.71 m**, inside the 2.35 m interaction reach.
The sight lines cross the strip's open inner edge above world Y9.5, leaving
over 1.1 m above the deck; a floor reaching all the way beneath these pins would
obstruct the work. Pin extraction tubes stop before the deck edge.

Upper A-pin targets are world Y10.00, at right-side X14.880/13.710/13.710,
world Z26.000/25.325/26.675; left X11.120/12.290/12.290. The corresponding
front/front/rear standing lines place them 1.70/1.03/.98 m away horizontally.
At services, stand front world X12.22/13.78, Z24.30: upper/lower block targets
world Y10.45/9.75, Z25.30/25.40 are about1.09/1.14 m from the eye. Front
guard latches target `(s×1.25,+.90,8.80)`; rear-cover latches target
`(s×1.15,−.90,8.65)`, reached from the matching strip. Outer-plate latch
`(s×1.88,0,8.85)` uses the side finger or a front corner; at front standing
X=`13+s×1.88`, worldZ24.30 its reach is about1.69 m. These are exposed-face
reach/line estimates, not a walked visibility or tool sweep result.

Install each complete cylinder **after full ring retention**, with the rail still
engaged. The ordinary elevator shelf carries one cartridge at a time from its
stock/staging point. It remains a finite shelf at the elevator, with no arm
extending toward the hip. The player picks up the neutral-length cartridge with
assisted two-hand carrying and walks along the connected front/rear landing to
the stated service patch. Its upright carrying envelope is approximately
1.49 high ×.24 wide ×.24 deep, including both eyes and parking lugs; keep at least
.90 clear walking width through the 1.20-deep landing strip. The rail continues
to support the leg throughout this carry and installation.

Each pelvis clevis has two short **integral parking hooks** flanking its upper
eye, with a captive catch. The cartridge's upper-eye housing has two matching
parking lugs projecting along X to ±.11 from the eye centre, clear of the ±Y pin
tube. Lowering the carried upper eye .03 into the hooks seats those lugs; the
catch visibly closes over them. The hooks carry the cartridge's weight and the
catch prevents it lifting or swinging out. Only after this captured state may
the player release both hands and insert the upper pin/keeper. These are local
clevis features, not equipment reaching from the elevator, and do not substitute
for the installed eye pin. Keep the hook/catch envelope within .14 of A and
outside the specified pin axis/tool tube.

The secured upper eye then carries the full cartridge while the player guides
its lower end into the leg clevis. That clevis has an open-top lower-eye rest and
a captive parking gate: the rest bears the eye below its outer rim and the gate
holds the neutral alignment, leaving the pin bore exposed. Hands are free only
once the eye is resting and the gate is visibly closed; fit the lower pin/keeper,
then engage the cartridge's positive neutral index lock. Fold both temporary
parking catches clear into captive stowed detents after both pins and that lock
are secure, so they cannot restrict operational spherical-eye motion. Repeat
all three cylinders, connect services, confirm all three locks, then release/
withdraw the empty rail. The shared crane remains available for chest work.
For local removal, reacquire rail support and close the parking gates before
extracting pins; return the cartridge directly to two-hand carrying from its
captured upper rest, then the shelf. Future solids/player checks must verify
carrying width, parking contact/catch visibility and both hands-free pin stages.

### Waist rotary bearing, lean pivot and actuation

The rotary bearing is centred `(0,0,10.50)`, axis Z, OD1.40/ID.85,
height .18 at Z10.41..10.59. Its stationary base sits on the pedestal; its upper
ring carries the lean yoke. Working yaw travel is **±25°** with replaceable
mechanical stop blocks. A compact electric geared pinion occupies
X+.73..+1.05, Y±.16, Z10.35..10.68 and drives the ring gear. A brake holds
ordinary unpowered movement; a captive front neutral lock pin gives positive
assembly restraint at yaw0. Its target is `(0,+.70,10.57)`, vertical pin axis.

The lean axis is **X at `(0,0,10.90)`**, .40 above the rotary centre and
.40 below the chest seat. Two trunnions centred X±.78, outside the central
service space, use Ø.16 journals with .12 axial bearing length. Select
forward/back lean **±10°**, with paired yoke stops. The upper cradle and all
chest/core/backpack/head geometry follow this pivot after yaw. Two identical
hydraulic lean cartridges have lower eye centres `(±.66,+.50,10.65)` on the
rotating yoke and upper centres `(±.66,+.52,11.12)` on the cradle. Neutral
eye distance is .470; at ±10° it is .380/.558. Select .36.. .58 travel,
.22 stroke, Ø.10 barrel, Ø.04 rod; spherical-eye/pin detail follows the hip
principle at a smaller family size. Their positive external neutral locks engage
for chest handling. A captive lean index pin also enters from +X at
`(+.92,0,10.90)`, independently of hydraulic pressure. Both yaw and lean
positive locks are required to crane-seat or remove a chest.

The cradle occupies X±1.00/Y±.75, with its top structural seating plane Z11.30
and neutral upper solid limit11.35 except alignment keys. Its lower bridge
plates are Z11.22..11.30; under-cradle ribs stay outside the central
X±.40/Y±.30 service bay. At lean10°, a lower front corner has
Z=`10.90+.32cos10°−.75sin10°=11.085`, still .495 above the rotary top.
The cradle's upper swept Z is about11.48 and conservative rear Y≥−1.12 after
yaw/lean. Waist fixed outer armor remains 2.20 W ×1.60 D and ends below Z10.70;
overlapping moving armor carries the rest. Keep fixed upper pelvis armor at
Z≤10.40. Do not bridge either articulation with a rigid vent or armor plate.

The chest's rear spreader feet additionally occupy
X±(.72..1.32),Y−1.10..−.44,Z11.30..11.38, rigid to the chest. Their lowest
rear edge at lean10° is approximately
`10.90+.40cos10°−1.10sin10°=11.103`, .403 above the fixed waist armor and
.703 above fixed pelvis armor. Include these wider moving feet in the yaw sweep;
the 2.00-wide main flange alone is not the whole lower-frame bound.

A protected finite-travel service cassette runs through the .85 bearing opening
and central yoke space. Reserve X±.40/Y±.30/Z10.59..11.15 for power/data,
hydraulic and cooling U-loops, minimum bend radius .10. Rotation stops limit cable
twist; no unlimited yaw or extra whole-turn slack is assumed. Flex loops cross
only the moving joints; rigid manifolds and the chest connector blocks attach to
the cradle and move with the chest. Upper/lower rear vent strips terminate on
their respective structures, leaving a .20 neutral articulation break rather
than a continuous rigid spine cover. Detailed line count and electrical ratings
remain system engineering; the occupied route and disconnect faces are reserved.

### Chest receiving connection

Agreed with [chest/cockpit](chest-and-cockpit.md): a **2.00 X ×1.50 Y receiver**
at **Z11.30**, with four load pads under the chest's Z11.30..11.40 lower
flange, centred X±.84/Y±.58. Pad patches occupy X±(.72..1.00),
Y±(.44...72); linked cradle rails support all four. The central lower core bay
X±.56, Y−1.15..+.72, Z11.43..12.45 remains clear of waist hardware.

Four waist-owned tapered keys at `(±.92,±.25)` are .080 X ×.120 Y and project
Z11.30..11.42, with .020 tip chamfers. Chest-owned pockets are .084 X ×.124 Y,
ending atZ11.44. The keys guide orientation and take shear; seats take weight.
Lowering needs .12 key insertion plus .06 approach clearance: final crane approach
is **.18 m vertical**, neutral yaw/lean locked. Lift the retained chest at least
.18 before sideways travel on removal. There is no central stud through the core.

Four chest-owned **M36×160 bolts plus four 6 mm washers** enter downward at
X±.84/Y±.58. Through .100 chest flange and .006 washer they engage .054 into
waist-owned captive bosses in Z11.22..11.30. Reserve heads/washer at
Z11.40..11.46 and R.09 vertical tool cylinders up toZ12.45. Chest's open perimeter
pockets continue to front/rear outer faces; a fitted cockpit cannot require access
through the capsule. Do not add underside nuts requiring a hidden fastening face.

Two service coupling sets at `(±.80,0,11.15)` face outward ±X. Chest tails
occupy X±.80/Y±.25 and connect after structural fastening, with .18 lateral
withdrawal and R.10 hand clearance. Keep Y±.58 bolt pockets and Y±.25 keys
separate. Stand on world deck11.20 at `(12.16/13.84,11.20,24.30)` for the
front bolts or Z27.65 for rear bolts. With eyeY12.83 and head targetsY12.83,
horizontal distances are1.07 m. Couplings use side patches world
X11.30/14.70,Z26.0: eye-to-connector distance is approximately.94 m. Lean lock
is reached from the +X patch, yaw lock from the front. Actual pockets, tool
rotation and upper-body occlusion need the future solids and walked checks.

After keys/seats contact, the crane remains responsible until all four bolt pairs
are retained, gantry supports are clamped and both waist neutral locks confirmed.
The robot connection then carries the chest; disconnect rigging from the exposed
structural eyes before services and abdominal closures. Source chest fixture
release is owned by the chest workflow. Its lower frame/cockpit must already be
complete; the pelvis manual requests one prepared chest, not its internals again.

### Physical connection allocation and manual outline

This interface pass identifies meaningful physical families; it does not claim a
complete pelvis inventory or allocate hidden actuator internals as loose stock.

| Connection scope | Physical supplies / compatible types |
| --- | --- |
| Socket to bridge, workstation | Two handed housings/liners; four identical M36×160 bolts/four 6 mm washers; integral seats/keys belong to housings/frame |
| Each hip structural retention | Prepared leg; two identical PV-120 halves; four PV-H24140 bolts/four shared LG-W24 washers |
| Each hip stops | Two identical stop-cage halves/four M12×60 bolts/four washers; two leg-owned tongues prepared with spar |
| Each hip drive | Three identical complete cylinder cartridges; six identical Ø60 eye pins with captive keepers; cylinder neutral lock pins stay captive |
| Hip services/closures | One leg service-loop assembly per hip, fitted pelvis service blocks, two front guards, two outer plates and two rear service covers across the pelvis; exact small closure hardware follows armor detailing |
| Waist preparation | One rotary bearing/drive, rotating yoke, lean cradle/two trunnion bearings, two identical lean cartridges, captive yaw/lean index locks and service cassette |
| Chest mount | Prepared chest, four M36×160/four 6 mm washers owned by chest; receiver seats/keys/captive threads are fitted context |

The parent pelvis/waist manual owns gantry seating, each prepared leg's seating,
retention, actuation and service handoff, and the prepared chest's seating and
retention. Child manuals own leg and chest internal preparation. No shopping list
belongs on readiness/overview pages. Step supply lists derive from the physical
slots in that step; prior receiving parts are context. Preserve independent order
between the two retaining halves, the three cylinders after retention, both legs,
and front/rear fastener branches wherever their support/access requirements hold.

Sequence: fixture-build bridge/sockets → rotary/yoke/lean/cradle and locks →
crane/gantry seat/clamp/release → rail-seat one leg → both ring halves and all
four bolt pairs → stop cage → three supported cylinders/pins/neutral locks →
services → withdraw rail → guards. Repeat the opposite leg. Then crane-seat
prepared chest → four bolts → confirm support/locks → release rigging → services
→ abdomen closures. Guard installation may wait until both legs are fitted if its
open sweep occupies the next leg's route. Local undo first reacquires the relevant
source support and removes only closures/services blocking the connection.

### Required review before models or gameplay claim completion

1. Build source solids for both socket rear seats, ball/neck/ring and stop cage;
   sweep the full combined cone/twist set, especially the .021 neck/ring margin.
   Confirm real bearing/washer contact, bolt threads, clear lower entry and stop
   contact before inherited retaining geometry is exceeded.
2. Sweep all six cylinder cartridges, fittings, clevises, .34 pin tubes, hoses and
   guards with both legs and their armor present. Check all three Jacobian singular
   values and actuator loads; determinant samples alone are insufficient. Confirm
   sphere-eye angular demand and cylinder closed/stroke packaging.
3. Check fixture→rigging→gantry support contact and moment restraint; then leg
   rail→retaining ring→carried cylinders/clevis parking catches→positive locks→
   empty rail withdrawal. Ensure catches, keepers and lower pin work remain visible from the candidate8.4 strips with
   the first leg installed during second-leg work.
4. Sweep yaw/lean with the complete chest, closed backpack, vent breaks and
   service cassette; inspect cradle/rotary clearance, keys, core underside,
   abdomen edges and the backpack's lowest rear corner. Backpack maintenance is
   neutral/locked, as specified by its owning packet.
5. Check chest source rigging, .18 vertical seating/release, all four above-flange
   bolt tools and side service withdrawal with the cockpit fitted. Verify exposed
   lifting attachment release and gantry contacts before freeing the crane.
6. Future authored-data/manual audit must conserve physical stock, use one owner
   per part, distinguish prepared/seated/secured/pose-locked states and accept
   interchangeable rings/cylinders/pins on both sides. Exercise supported local
   undo/reinstallation and actual player reach/input paths. Rendered review runs
   only if explicitly requested; none was performed for this design revision.

Remaining engineering work is solid contact/sweep verification, load/pressure and
fatigue sizing, final guard outlines and the full manufacturing inventory. The
working counts, datums, connection directions, support/release rules and workshop
access requirements above are selected rather than deferred alternatives.
