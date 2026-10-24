# Shoulder, upper arm, and elbow

Last updated: 2026-10-24

[Design index](../../ROBOT_DESIGN.md) · [Shared design rules](../global.md)

The right arm will mirror this design.

Connected assemblies and clearance checks: [chest and cockpit](../torso/chest-and-cockpit.md), [forearm and wrist](forearm-and-wrist.md), [head](../head.md), [backpack](../torso/backpack-and-power.md).

Dimensions and reference pose: [shared proportion layout](../proportions.md#arms-and-hands).

## Confirmed design

### Shoulder

- **Joint and assembly boundary:** a ball-and-socket joint, with the ball integral to the upper-arm skeleton and the socket at the outer end of the torso's shoulder crossmember. A removable two-piece retaining ring captures the ball, repeating the hip's retention principle. The working dimensions, drives and access below develop this confirmed concept.
- **Armor silhouette:** a boxy pauldron for a more mechanical appearance, within the confirmed 5.60 m total shoulder width. The selected envelope and removable carrier/panels below develop its construction.
- **Armor mounting:** rigid relative to the upper-arm skeleton, moving with the arm. The pauldron belongs to the arm assembly and has no independent articulation. Rigid mounting preserves removable armor; selected carrier/panel hardware is recorded below.
- **Joint visibility:** a narrow mechanical gap beneath the pauldron exposes part of the socket rim and inner frame.
- **Clearance requirement:** check the rigid pauldron against the chest, neck, and backpack through shoulder movement. Set achievable travel and stops during the geometry pass.

The earlier compact-cap and independent armor-hinge recommendations were not adopted.

### Upper arm and elbow

- **Upper-arm silhouette:** a relatively slim, angular upper arm with a mild taper toward the elbow, giving the boxy shoulder armor visual prominence.
- **Frame and armor:** a central box-section beam incorporating the confirmed shoulder ball, with a detachable lower elbow fork and removable front/rear armor shells.
- **Elbow joint:** one main hinge with a transverse axle, separate bearings, and visible circular retaining caps recessed within angular guards. The upper-arm fork straddles the top of the forearm.
- **Elbow actuators:** a pair of compact linear actuators in rear-side channels of the upper arm, mostly covered by armor, with short rod sections visible beside the elbow. Actuator type, endpoints, stroke, and clearance remain unresolved.

## Selected shoulder interface and delivery design

This is the 2026-10-24 **design-only interface pass**, continuing the confirmed
construction above. Dimensions below are selected working dimensions, not an
engineered bearing design or a verified model. The earlier detailed elbow,
forearm, wrist and digit concepts remain in force. No complete arm inventory,
gameplay, source model or rendered review is supplied by this pass.

### Datums and boundary

Use metres and the [shared robot axes](../proportions.md#reference-coordinates-and-stance):
X right, Y forward, Z up, with soles at Z0. Right shoulder centre is
`C=(2.20,0,14.40)`; mirror X for the left. For the right reference arm define
`u=(sin 15°,0,−cos 15°)` down/out along the straight limb,
`e=(cos 15°,0,sin 15°)` across its frontal cross-section, and `f=(0,1,0)` forward.
Mirror the X components of u and e for the left. Coordinates written
`C+t u+a e+b f` use this basis. Shoulder/elbow/wrist/middle fingertip centreline
stations remain t0/3.00/5.60/7.40. Forearm and hand rotate with the upper arm
during delivery because their temporary restraints are installed.

World mapping is `(13+X,1.40+Z,26−Y)`. Final shoulder world centres are
`(10.80/15.20,15.80,26.00)`. These are distinct from source fixture coordinates.

The torso owns the crossmember, socket roots/cups, fixed liners, retaining halves and their fastening hardware, actuator A ears,
three shoulder drive cartridges and their eye pins, fixed service face and
removable shoulder service brace. The arm owns the
integral ball/neck, moving actuator B lugs, lifting/support hardpoints, and rigid
removable pauldron. The gantry parent manual owns mounting/retaining the prepared
arm, completing shoulder drives/services, and mounting/closing its pauldron.
Arm preparation owns the upper arm, elbow, forearm, wrist and hand internals.

### Socket entry, ball and retaining ring

The socket opens **downward/outward along u**, matching the arm at 15° splay.
Insert the prepared arm along −u. A purely lateral X opening would collide with
the downward neck; it is not the selected construction.

| Item | Selected geometry / installation |
| --- | --- |
| Integral ball | Ø0.68, centred at C; no separate inventory ball |
| Neck | Ø0.22 cylindrical section by t0.43; fillet stays within the ball profile where retained and clears the declared exit cone; central beam continues toward the elbow |
| Cup | Inboard/upward hemisphere, nominal outer spherical radius 0.43; replaceable liner inner spherical radius 0.345, approximately 0.02 liner thickness, structural backing outside it |
| **Unretained ball-entry opening** | True Ø0.70 clear bore from the equator through the short entry counterbore to t+0.08; no fixed lip smaller than the ball crosses this insertion path |
| Fixed rim/boss flange | Outer radius 0.465, t−0.04..+0.08; threaded retention bosses outside the entry bore |
| Two-piece retaining ring | Front/rear halves split at Y0, outerØ0.96, t+0.08..+0.26; fitted radially from ±Y after ball seating. Concave replaceable liner continues the spherical support and ends at a **Ø0.48 neck exit** |
| Ring retention | Four M24 bolts with four separate washers; head axes parallel u, bolts enter along−u into cup bosses. Recessed head/washer operating faces stay within t0.26; axes at radius 0.405/angles 45°,135°,225°,315°, where angle 0 points along e and angle 90 along f |

The Ø0.48 exit retains the ball **after** the ring is fitted; it is not the
ball-entry bore. Locate ring halves by fitted shoulders and complementary seam
keys before tightening. Front/rear halves are complementary variants until actual
geometry proves they are interchangeable; four matching bolt/washer copies are
shared compatible types. The quoted liner clearances are packaging allowances,
not production fit tolerances or load ratings.

Ring heads are approximately right-side `(2.544,+0.286,14.223)`,
`(1.991,+0.286,14.075)` and their rear mirrors. Reserve R0.05 tool cylinders
0.30 m outward along+u from each head. This provides downward/outward approach
around the neck while the pauldron is absent. Ring-half entry sweeps extend
0.60 m forward/rearward; do not route services across them beforehand.

Before insertion, the centre is `C+1.13u`: world right
`(15.492,14.709,26)` or left `(10.508,14.709,26)`. The ball's leading spherical
surface is t0.79, leaving 0.71 m to the fixed t0.08 mouth. Advance 1.13 m along−u
without changing the straight restrained arm pose. The cup and both crane pad
pairs support the load while the ring is installed; seating alone permits no
crane release. Detailed mouth lead-in and actual partial-contact solids remain
to be modeled.

The source preflight replaced the earlier **0.65 m** approach offset. That
offset cleared the socket mouth but put the ball at the fixed C-bridge's t0.64
station while advancing from the front. The front A eye at e−0.080/f+0.453
blocked that transverse approach. The 1.13 m offset puts the leading ball
surface 0.05 m below the lowest fixed root at t0.74 before crossing, then uses
the existing central opening for axial seating. This is a measured route
correction, separate from earlier implementation omissions in rigging checks.

The socket/ring allowance is conservatively each side |X|1.74..2.74,
Y±0.48,Z13.95..14.85, excluding rear root extensions below. This refines the
chest's provisional reservation without moving the shoulder centre.

### Socket roots and crossmember contract

Each cup is carried by a boxed rear dogleg tied to the existing crossmember,
rather than a floating socket at Y0. Root placement stays within
|X|1.68..2.34,Y−1.12..−0.32,Z14.10..14.72, with shaped forward arms meeting the
cup's rear/outboard quadrants. It is a member allocation, not a solid block.

The rear overlap plate occupies |X|1.68..1.85,Y−1.12..−0.82,Z14.18..14.62
against the existing main beam X±1.85,Y−1.10..−0.65,Z14.18..14.62. Each side
uses four M24 bolts, with heads at |X|1.72/1.81 crossed with Z14.27/14.53,
Y−1.12, entering+Y into captive beam nuts. Reserve R0.04 rear tool cylinders
to Y−1.42. Two Ø0.04 locating dowels on each side, around |X|1.765 and
Z14.34/14.46, establish position separately from bolt clamping. These dowels are
fixed root hardware; the source-detail stage must resolve actual plate/beam
sections, thread engagement and local edge distances before accepting the joint.

All eight root bolts are installed during chest preparation. The roots remain
0.98 m or more laterally from the X±0.70 capsule, do not enter the neck bridge
X±0.48, and leave the rear worker flanks outside the backpack sweep. They refine
the prepared chest to maximum width 5.48 m, rounded 5.50 for workshop planning;
depth stays Y−1.35..+1.20 because the backpack fixed roots still project farther
rearward. A 5.80 m clear loading opening leaves at least 0.15 m each side of the
rounded load. Shared torso/layout documents own that derived change.

### Shoulder drives, stops, restraint and services

Select three compact electric screw-drive cartridges **below the retaining
ring**, carried by an inboard C-shaped receiver bridge. Keep cartridge bodies
and support brackets outside the ball entry, retaining annulus and ring tools
using the explicit separation bounds below.

The right-side eye coordinates, relative to C, are:

`A(i)=+0.64u+0.46[cosθ(i)e+sinθ(i)f]`

`B(i)=+1.50u+0.34[cos(θ(i)+45°)e+sin(θ(i)+45°)f]`,

with θ=100°,180°,260°. These are respectively front/inboard/rear fixed eyes;
the moving eyes are skewed 45° from them. Mirror the actual X coordinates for
the left arm, including the skewed B lugs; do not reuse an unmirrored set of
brackets. Matching manufactured drive cartridges can remain compatible across
sides; bracket/lug handedness is real geometry.

Select maximum cartridge/eye envelope radius 0.05 m, eye lengths 0.74..1.23 m,
and spherical bearings at both ends. Neutral eye length is 0.9196 m. The three
skewed lines provide distinct tilt/twist constraints; final force authority,
stability, screw packaging and bearing travel remain engineering checks. Each
module uses two Ø0.04 pins/keepers, six pin/keeper pairs per shoulder.

The torso-owned fixed support has two connected regions:

- A root spine runs from the existing rear socket dogleg at t−0.15 to t+0.64,
  centred at e−0.58/f−0.48, with maximum section radius 0.04 m. Its radial
  distance is 0.753 m, so it descends **outside** the cup, ring and ring tools.
  A short upper elbow at t−0.15 connects e−0.50 to e−0.58 before descent.
  That elbow is above the ring-half entry band; throughout that band the spine
  lies at e≤−0.54, leaving 0.06 m to the halves' e−0.48 outer edge even while
  they translate along±Y. A spine at e−0.50 would obstruct that lateral entry.
  Its upper junction joins the existing side-frame/root band; this is an
  intentional structural joint, not a bracket passing through an unrelated
  solid frame member. Keep the existing crossmember bolt pattern unchanged.
- At t0.61..0.67, an inboard C-bridge has inner radius 0.40, outer radius 0.46,
  and angular coverage 100..260°. It connects the three A clevises and remains
  open on the outboard side. A shaped radial return at this same lower station
  joins the spine to the inboard arc; it never cuts across the central entry
  opening. A-eyes have no material inward of radius 0.41 except the explicitly
  bounded inboard pin-port root below. No fixed hoop crosses the ball's path.

Pin axes are Y. Front A 100 and rear A 260 have heads 0.10 m outward along their
respective ±Y; A 180 is serviced from the front. Its reinforced clevis/root is
bounded by t0.54..0.74,e−0.58..−0.40,f±0.12 and includes a real R0.04
front-access tool bore along f through `(t0.64,e−0.46)`. Upper/lower bypass
webs carry load around that port; do not fill it with a continuous annular wall.
The other two A-pin tools leave directly away from the arc. All three clevises
have downward-open cartridge throats around their spherical eyes; the receiving
pin/eye contact is intentional, while the moving cartridge body must clear the
relieved throat. Reserve 0.22 m outward withdrawal from each pin head.
B-pin tools approach from the side of
that eye's Y sign; their heads are 0.12 m outward, with 0.22 m withdrawal.
Their radial line stays outside the central beam. Install/connect drive modules
after ring retention and the positive service brace; remove them under crane
support before withdrawing the arm.

The neck stays Ø0.22 through t1.05, then blends to a box beam contained in
R0.17 by t1.20 through the B-lug region. Full-width upper-arm armor starts below
t1.20; do not extend a 0.90×1.00 solid shell through the fixed C-bridge. The
outboard pauldron mounts and the removable brace use the open side of this
receiver. More substantial beam sections below t1.60 remain available within
the confirmed upper-arm envelope; detailed sections/strength remain source work.

The fixed descending hardware, including eyes and the pin-port root, stays
within right-side X1.56..2.42,Y−0.53..+0.51,Z13.50..14.46. Existing cup/ring
and rear roots still set the prepared chest's outer bounds; no growth beyond
X±2.74,Y−1.35..+1.20,Z11.30..15.58 is required. The drive capsules in reference
pose are approximately X1.87..2.83,Y±0.51,Z12.82..13.82; their lower portion
is within the upper-arm region, below the pauldron. A deliberately conservative
full 20°-cone drive bound is X1.68..3.39,Y±0.89,Z12.80..13.82. These moving
bounds are not additions to the prepared chest. The locked-reference forearm/
hand bounds still govern elevator separation.

Select initial hard-stop targets of 15..35° outward splay, fore/aft tilt±15°,
and axial twist±15°, additionally limited to a 20° cone from the 15° reference
axis. Combined extremes outside that cone are unavailable. Integral cup/collar
stops and drive limits must agree. These remain working travel targets pending
actual continuous solids; the cartridge/ring intersection has already been
removed by the axial/radial separation below. Lock the 15° straight service pose
for delivery, backpack/core maintenance and head construction.

A removable keyed U-shaped service brace seats on separate C-bridge tabs near
radius 0.43/angles 130° and 230°, clear of the A-eye seats. Its staggered arm-owned
keys are `C+1.05u+0.05e+0.25f` at the front and
`C+1.05u−0.15e−0.25f` at the rear. These offsets clear the three neutral drive
lines and keep both pin tools inboard of the outboard harness channel.
Two Ø0.04 pins/keepers, with operating heads near
f±0.35, retain its keyed seat and establish all three reference angles without
motor power. Its branches stay on the outboard side of the three drive lines;
it is fitted only in the neutral pose and removed/stowed before any shoulder
movement. The moving keyed pads are far enough below the fixed bridge to clear
its axial band over the selected cone. Install the brace after ring retention;
it never substitutes for the ring. Keep it until all drives/brakes are checked
and intentional motion is requested; reapply it for later supported correction.

Keep the isolated arm power/control bulkhead near `(±2.00,+0.50,14.46)`.
Route the harness first across the high front channel near Z14.46, then down
its outboard loop channel |X|2.60..2.78,Y+0.50..+0.60,Z13.35..14.46 to the
arm connection near `C+1.10u+0.26e+0.50f`. Select 1.80 m protected run and
working bend radius≥0.10 m. This route is above the A-pin tools before turning
down, and outboard of the front drive/its pin corridor; it replaces the earlier
loop through the lower-front work faces. Connect/check it after mechanical
retention and pinning, before closure. Retained flex and the selected mechanical
windows must remain clear throughout movement; exact loop shapes remain source
work. Fixed drive plugs remain on their own brackets. No connector/cable carries
arm weight; downstream elbow/wrist service concepts remain unchanged.

The separation checks governing this arrangement are explicit:

- Cup/ring solids end at t0.26. Both endpoints of every drive lie at t≥0.64
  over the full cone: `B_t≥1.50cos20°−0.34sin20°=1.293`. Every straight
  centre segment therefore has t≥0.64; its radius 0.05 capsule has t≥0.59,
  leaving 0.33 m to the ring. No line crosses the retaining annulus.
- Ring-bolt tool axes end at t0.56. The main bridge starts t0.61 and drive
  capsules start t0.59, leaving respective axial gaps 0.05/0.03 m. The local
  A 180 pin-port root extends higher, but is more than 0.19 m laterally from
  the nearest ring-tool centreline before its R0.05 allowance. The outer
  spine's inner radius 0.713 exceeds ring radius 0.48 by 0.233 m and the
  tools' radial outer bound 0.455 by 0.258 m. The upper connection elbow is
  separately above the ring-half band.
- During the entire 1.13 m insertion/withdrawal, the ball centre translates
  t1.13..0 with maximum radial radius 0.34. The C-bridge bore radius 0.40 and
  local pin-port root minimum radius 0.40 both leave 0.06 m.
  The Ø0.22 neck passes the same opening. Full beam/armor starts at local
  t1.20, so it never enters the fixed t0.54..0.74 band; its minimum delivered
  t is 1.20. Outboard carrier bosses remain on the open side, while upper
  crane pads at e+0.10/f±0.68 clear the arc and root spine. Ring halves enter
  at t0.08..0.26, separately above all new lower brackets.
- For tilt, the neck crossing the main bridge's t0.67 plane needs at most
  `0.67tan20°+0.11/cos 20°=0.361 m` radial clearance, below the 0.40 bore.
  The pin-port root's lower plane t0.74 needs 0.386 m, below its 0.40 local
  radius, leaving 0.014 m; preserve this clearance when adding actual fillets
  and tolerances, without reducing the entry bore.
- Sampling 1° tilt/6° azimuth/3° twist and 41 points on each capsule centreline
  gives eye lengths 0.7576..1.2035 m, and minimum cartridge-to-selected-moving-
  skeleton clearance about 0.020 m after subtracting radius 0.05 and the
  piecewise neck/beam radii. The corresponding moving carrier-boss to fixed
  A-eye clearance exceeds 0.17 m. These are sampled checks; continuous solid,
  fillet, bearing/pin, mutual-drive and force checks remain required.

### Rigid removable pauldron

The confirmed 5.60 m outer width is retained. Each pauldron's reference envelope
is |X|1.62..2.80,Y±0.65,Z13.65..15.05:1.18 W×1.30 D×1.40 H. It is a boxy
roof/outer-wall carrier with removable front/rear closure panels, rigidly bolted
to the arm skeleton. There is no armor hinge or separate armor articulation.

Reserve a ball-centred **R0.57 minimum free cavity** around the cup/ring. The
ring's maximum radius from C is√(0.48²+0.26²)=0.546 m, leaving 0.024 m to that
cavity under relative rotation. A 0.03 m outer wall can still end at X2.80.
The inboard side is open/notched: |X|1.62 is a sparse rim/corner boundary, not
a full vertical slab. Relieve the actual torso side-frame bands reaching
|X|1.70, root arms and service/drive sweeps by at least 0.08 m locally; split or
omit skirt sections wherever that relief removes them. Do not silently taper
a structural torso member or fill the R0.57 opening to obtain a closed box.
The outer roof/side silhouette and its narrow lower outboard gap remain boxy,
but the fixed descending brackets require permanent inner service relief. In
reference-arm coordinates, omit front panel material at |X|≤2.72 below Z14.20,
and rear panel material at |X|≤2.72 below Z14.80; the inboard side remains open.
The retained front/rear closure panels are the upper/outboard sections, not full
rectangles down to Z13.65. These windows are open during movement, not covers
that must be removed whenever the arm moves. Sampled fixed-bracket sweeps in
moving-armor coordinates breach the front inner face over X1.98..2.57,
Z13.81..14.05 and the rear face over X1.55..2.57,Z13.56..14.70; the selected
windows add margin and leave the outer wall/roof intact. A conservative projection
bound keeps the fixed hardware's outboard X≤2.703, giving at least 0.067 m to the
inner face of the 0.03 m outer wall. Check actual continuous surfaces before
shrinking these cutouts. This local inner/rear openness is a visible consequence
of fitting the mechanism inside the confirmed 5.60 m width.

Four M20 carrier bolts enter from front/rear along∓Y into arm-owned mounting
bosses. Working head positions are `C+t u+0.38e±0.11f`, t0.60/0.75. These outboard bosses use
the open side of the fixed receiver and stay within X2.80 including recessed
heads; the former wide front/rear boss locations are superseded. Fit the
carrier after the shoulder is secured/connected and all arm rigging is stowed.
The main carrier lowers 1.60 m from above with its bottom open and its inboard
cutouts aligned. At the start of this final approach its top is robot Z16.65/world Y18.05.
Across the workshop, use a higher carry pose: **lowest point worldY18.0**,
body top 19.4 and hook about 20.53, below the 23.0 overhead obstruction.
Route at frontZ13 to the shoulder X, then toZ26, before lowering to the final
approach. The lower final approach alone would not clear the head-level decks. Use two **vertical front/rear-facing rig plates** at the carrier roof edges,
centred near `(±2.35,±0.65,14.98)`, normals±Y, with visible attachment/release
handles on those same faces. Each 0.12 m-high plate remains below the 15.05 roof
limit; no upward-facing target is credited to the lower deck. At the source,
place the carrier upright on shared fixture saddles with its bottom worldY 0.75:
plate height is 2.08, visible/reachable from floor eye 1.63 at 0.80 m standoff
(about 0.92 m reach). The vacant long-limb fixture can provide this cap setting
once the arm has departed. In the gantry the existing 14.0 m deck workers face
the plates from front/rear, with about 1.30 m sight/reach distance. Fit both
articulated crane ends while source saddles carry the cap, take load, and lift;
retain all four carrier bolts before release;
then fit front/rear panels, each with four captive M12 closure screws. Those
panels may be completed independently once their own services/tools are clear.
Place their captive screws on retained upper/outboard material, never in the
mechanical windows; the rear upper strip can use two screw rows near Z14.86/14.98.

In locked reference pose, the inboard envelope has 0.62 m to helmet X±1.00,
0.32 m to the 2.60 m crest width, and 0.32 m to the conservative backpack
maintenance sweep X±1.30. The 0.35 m vertical gap from pauldron top 15.05 to
head base 15.40 remains. Rear workers at |X|1.90,Y−1.75..−2.20 are
behind its Y−0.65 limit; armor does not replace a check of their approach and
tool rays. Recheck these comparisons with actual solids, shoulder travel and
head/backpack fitted. The 16.4 m world deck has foot height robot Z15.0 and
must notch/retract around the pauldron rather than pass through its upper 0.05 m.

### Robot workshop pauldron implementation — 2026-10-24

Source: `tools/author_pauldrons.py` (within `game/workshop`), with two data-driven receivers.
Passive upright stores at world X−9/−5, Z1 replace the optional vacant limb fixture;
carrier bottoms are Y0.75 and tops Y2.15, within the small-stock height limit.
Both two-end rigs use the specified Y18.0 transit bottom, Z13 distribution and 1.60 m final descent.
Mount detail: bottom-open outer-wall reliefs pass the arm-owned bosses. Rigid inboard
ears crossed the fitted ring during descent, so captive clamp shoes travel with the four
M20 bolt units and fit after seating. Two proximal long-shoe and two distal short-shoe
units are distinct fitting variants; carrier/panel/fastener quantities stay as specified.
The harness centreline moves from |X|2.76 to 2.72 within its selected channel, leaving
0.033 m to the wall; segment colliders preserve the open loop rather than filling it.
Front/rear upper panels measure 1.15×0.046×0.82/0.22 m including captive screw heads;
both fit the unchanged shelf. Panel fitting includes fastening its four captive M12 screws.
The existing 16.4 m deck opening leaves 0.75 m fore/aft of the carrier; no deck enlargement is needed.
After both panels close and the rig releases, local handles release/re-engage the supplied
joint-restraint group (elbow/wrist together) and digit cradle; no new stock or controller.
Full payload/rig preflight and mechanical delivery checks do not establish walking/access or visual approval.

### Shared long-limb preparation and supported upending

Prepare one connected upper arm/forearm/hand at the same shared long-limb bay
used by either leg; legs leave by rail, arms by the shared crane. No dedicated
arm machine or permanent component-specific buttons are required. Contextual
manual/equipment actions express securing, taking load, rotating, delivering and
releasing; generic supports/controls remain recipe independent.

Keep upper-arm armor within its 0.90×1.00 cross-section and forearm within 1.10².
The restrained hand/thumb/caps use, relative to the wrist, t−0.15..+1.85,
a±0.30,b−0.50..+0.75: fingers together/straight, thumb folded alongside/across
the palm without assuming it disappears inside the 0.90×0.45 palm envelope.
This is a selected transport allowance for later digit modeling, not a changed
finger mechanism. Restrain the elbow straight, wrist neutral and all digits
before any lift. Use removable bridge restraints on structural joint hardpoints
and a retained digit cradle; no transport force is borne by a fingertip, thumb
drive, elbow actuator rod, armor shell or service cable.

Use adjustable saddles/clamps on structural access pads near arm stations
t1.35 (upper beam),4.05 (forearm beam) and 6.05 (palm chassis). Source saddle
contacts carry weight; separate clamps prevent roll/translation. The palm clamp
engages its chassis/backplate receiver rails and avoids the thumb/finger mounts.
Generic fixture reorientation can expose front/rear construction faces before
the connected arm is locked into its transport pose. Actual internal elbow and
wrist fasteners still need their own component-level access design.

Four integral structural lifting pads, with 0.12 m target faces and swivelling
crane-end clevises, form front/rear pairs at
`C+0.75u+0.10e±0.68f` and `C+4.40u+0.10e±0.68f`. Their local extension is
included in the transport allowance. The shared adjustable spreader uses four
individually attached, pair-equalized ends; paired tensioned generic taglines
restrain yaw/roll during upending. Fit attachments individually while all source
clamps/saddles carry the arm. Tension/equalize and establish a balanced lift
before releasing those clamps. A working mass-centre station near t3.2 lies
between the 0.75/4.40 pad pairs; actual source mass/trim must confirm this before
accepting the rig. Changes to pad positions for a measured mass problem must
be coordinated with gantry release reach.

The [coordinated fixture/route plan](../game/final-assembly-plan.md#shared-limb-workshop-with-different-departure-routes)
selects world bay **X10.5..17.5/Z7.8..20.8**, horizontal shoulder datum
`(14,1.55,9.90)`, and source axes **u=+worldZ, e=+worldY, f=+worldX**, mirrored
for the left. This puts both rigging pairs on visible side faces, rather than
crediting attachment to a hidden underside. Source load bounds are
X13.25..14.75/Y1.00..2.10/Z9.47..17.35. The three saddles belong to one
removable retained cassette; crane the whole cassette to front passive parking
when another limb needs the station. Parking contacts and route are owned by
the workshop plan; the connected arm's final delivery lifts it off the cassette.

1. Raise the horizontal shoulder datum toY9.60 with all four ends tensioned;
   source clamps release only after crane support is established. Fold the released
   cassette clamps belowY1.70 before the suspended upending motion.
2. Upend90° about worldX: `u=(0,−sinφ,cosφ)`, `e=(0,cosφ,sinφ)`,
   `f=(1,0,0)`. Hold datum `(14,9.60,9.90)` and all joints restrained.
3. Yaw the vertical arm90° about worldY, mirrored for its side:
   `u=(0,−1,0)`, `e=(sinψ,0,cosψ)`, `f=(cosψ,0,−sinψ)`.
   Then splay15° to the documented reference axes. Coordinated payout and
   tensioned taglines control every intermediate pose; no free suspended spin.
4. Raise the shoulder toY14.709, advance toZ19.5, align X10.508/15.492,
   advance toZ26, then seat1.13 m along−u. Open all four front wing levels
   before crossing. Stow the waist service fingers before this delivery.

For the conservative t−0.43..7.45/e±0.55/f±0.75 rotation box, minimum
upending/splay worldY is2.129; combined side bounds X11.54..16.46 and
Z8.97..17.371 remain in the shared bay. Reserve1.80 m above the raised datum
for spreader/hook: pre-seat≤16.509, seated≤17.60. These are body-envelope
calculations. Actual mass/trim, swivel ends, cable fan-out and tagline anchors
must be modeled inside the shared route contract. All four attached ends remain
tensioned through continuous upending, yaw and splay.

### Gantry access, support transfer and local correction

Use the existing shared elevators and front/rear fingers. Coordinates in this
table are robot **eye** positions, with world deck heights given separately;
mirror X for the left arm. Worker body radius is 0.26 m, height 1.70 m, eye above
deck 1.63 m; maximum target reach 2.35 m and routine aim under 1.80 m.

| Work | Deck / worker eye / illustrative reach |
| --- | --- |
| Front/rear ring bolts, service-brace pins, drive pin heads and services | World deck 14.0; eyes `(2.40,±1.70,14.23)`; same-side ring heads≤1.48 m, fixed drive pin heads≤1.77 m; brace heads approximately 1.62 m |
| Upper arm rigging release | Same deck/eyes; pads at `(2.491,±0.68,13.701)`; approximately 1.15 m |
| Distal forearm rigging release | World deck 11.2; eyes `(2.95,±1.70,11.43)`; pads at `(3.435,±0.68,10.176)`; approximately 1.69 m |
| Pauldron mounts/closure and roof rigging | World deck 14.0; same upper eyes; mounts approximately 1.69 m, front/rear-facing roof-edge plates approximately 1.30 m |
| Root bolts, if later serviced | Rear 14.0 deck, eyes near `(1.80,−1.85,14.23)`; rear bolt heads within 0.81 m, outside the central backpack sweep |

Front fingers must provide worker centres at world X15.40 and 15.95,
Z24.30; rear centres at the same X,Z27.70, with body/guard allowance on each
deck. Mirror for the left. Lower 11.2 m front/rear release patches are a real
requirement, not an assumption that only the shoulder centre must be reachable.
The proposed front X14.2..16.5/Z23.4..24.6 and rear
X14.6..16.3/Z27.4..30.1 allocations accommodate these centres numerically;
railings, actual stance, tool cylinders and continuous walking remain to check.
Both front/rear pad pairs must be directly targetable; never hide release behind
an attached shell or rely on reaching through the arm.

The final **piecewise** reference envelope gives forearm outer
|X|≤2.2+5.6sin15°+0.55cos15°≈4.181 and complete hand/thumb/caps
|X|≤2.2+7.45sin15°+0.30cos15°=4.418. Thus both fitted arms occupy world
X8.582..17.418, leaving 0.382 m to full elevator shaft boxes ending X8.20 and
starting 17.80. During the corrected 1.13 m pre-seat offset the lateral
projection gap reduces to approximately 0.090 m. The shaft depth
Z27.4..30.6 independently leaves at least 0.65 m behind the conservative
arm/hand depth around Z26; this preserves the 0.20 m minimum to actual fixed
shaft structure. Actual source/full-rig preflight includes both complete shaft
boxes. Do not reuse the old 0.214 m lateral-only estimate. The bare fingertip centreline
span is insufficient for this check. Full elevator cars/guards must travel at
every height with both arms/hands fitted and restrained in this reference pose.

The frontmost restrained thumb reaches world Z25.25; front landings end 24.60,
leaving 0.65 m after final seating. During upright approach the load crosses
those landings, so all front wings open before delivery and restore only after
the seated body and cable planes clear their swept footprints. Final cable
planes Z25.32/26.68 remain between the front/rear platforms. Inner head-level
shortcut walks are omitted because they would intersect these vertical lines. Keep elevator entry and walking access connected with the openings set;
do not consume the only shaft exit as a permanent crane corridor. Source-route
planning must also include an already fitted opposite arm, backpack, legs and
all temporary restraints.

Support/state sequence is explicit:

1. **Prepared/source-supported:** complete retained arm, restrained joints and
   digits, pauldron absent;3 saddles/clamps carry it and crane attachments are idle.
2. **Crane-supported:**4 ends take the full load; source clamps release; guided
   upending/travel/insertion remain restrained and equipment supported.
3. **Seated:** cup contact establishes position while crane still carries the
   unretained arm. Fit both ring halves/4 bolts/4 washers, then engage the keyed
   brace and both pins. Restore the front fingers only after load clearance.
4. **Secured/receiver-supported:** ring retained, service brace engaged,
   all 3 drive cartridges/6 pin pairs fitted and brakes checked. Transfer load
   progressively into cup/root, drives and brace; crane ends remain connected
   until support is confirmed. Connect/check isolated services. Only then visit
   upper/lower front/rear release targets and detach/stow all 4 ends.
5. **Closed:** mount/retain the pauldron carrier with the shared crane; release
   its 2 ends; close its 2 panels after all local work. The brace may stay engaged
   in service pose. Elbow/wrist/digit restraints can then be removed for later
   movement checks and are reapplied for the specified maintenance/access state.

For local shoulder correction, isolate services, restore straight joint/digit
restraints and the service brace, remove pauldron panels/carrier, and reattach
all 4 arm ends from the same reachable decks. Take load before releasing drive
pins, brace or ring retention. Disconnect the main harness and remove ring
halves only while crane support is established; withdraw 1.13 m along+u and
reverse the guided route to the source saddles. The cup cannot independently
retain an unringed arm. Internal elbow/wrist/hand corrections follow their own
supported child-manual boundaries; a full robot teardown is not required here.

### Interface allocation, evidence and next review

The defined external allocations are: torso socket roots with 8 M24 root bolts
and 4 fixed locating dowels across both sides; per shoulder 2 ring halves,
4 M24 bolts/4 washers,3 drive cartridges/6 pin-keeper pairs,1 service brace with
2 pin-keeper pairs,1 protected harness; per pauldron 1 carrier/4 M20 mounts,
2 closure panels with 4 captive M12 screws each. Liners belong to their receiving
cup/ring. Integral ball/neck/lugs/support pads/rigging pads are features of their
owning structures, not extra loose stock. Temporary fixture clamps, bridge
restraints, digit cradle and crane ends are reusable workshop equipment. Actual
inventory instances and compatibility variants are deferred to component detail;
these connection allocations are not a whole-arm parts count.

Bounded arithmetic in this pass checked the entry stroke/mouth allowance,
neck-exit cone allowance (`0.26tan20°+0.11/cos 20°=0.212<0.240 m` before fillet
solids), socket/pauldron/head/backpack envelopes, source upending/floor margins,
piecewise hand/shaft separation, and illustrative target reaches. The separated
below-ring drive/bracket checks and their sampling are recorded above; they
define the selected working clearance contract. No automated
gameplay test, imported-solid audit, ordinary-input run or rendered inspection
was performed.

Before implementing this branch:

1. Model/check actual cup entry and ball/fillet/neck solids, both ring-half
   insertion paths, liner seating, bolt/washers/threads/tools, root joint sections
   and frame load path. Verify keyed brace retention and all drive-eye assembly
   paths. Sweep the selected coupled shoulder limits with actuator bodies,
   harness bend/routing, pauldron cavity/cutouts, capsule/frame, helmet and
   backpack; limit travel if measured solids conflict.
2. Measure actual arm mass/rigging balance and full source-clamp→crane→cup
   support transfer; preserve all 4 attached ends through upending. Check each
   line, spreader/tagline path, overhead and front-bridge crossing continuously,
   including the first arm installed while the second travels. Check source
   fixture removal/re-engagement and all reachable rigging releases.
3. Check avatar, rails/guards and tool cylinders at every listed target and
   connected elevator landing. Run each elevator through its full travel with
   both arms/hands/caps, backpack and head fitted in the locked service pose;
   do not substitute an elevator-centre or joint-centre check. Preserve workshop
   entry/shaft exits when delivery tips are open.
4. Author exact physical slots, shared compatible stock and prerequisites; derive
   each manual page's supplies from its slots. Parent pages own prepared-arm
   seating/retention/closure; child pages keep elbow/wrist/digit internals.
   Exercise one ordinary-input collection→supported preparation→upending→seat→
   retention→release→closure journey, wrong/compatible hardware, interrupted
   save/resume at support handoffs, and the supported local correction/return.
   Review readable handling/target feedback and actual player access separately
   from automatic state checks. Rendered review runs only when requested.

Remaining upper-arm/elbow work is the beam/fork sections and actual elbow axle,
bearing/cap stacks, paired rear screw/hydraulic-drive selection/endpoints/stroke,
travel stops, armor mounts and internal wiring. Preserve the confirmed paired
rear-channel elbow-actuator concept. Forearm tray/cuff/wrist and hand digit
geometry remain in their owning sheets; their transport allowances above do not
replace those designs. Strength, materials/ratings and detailed drive technology
remain later engineering work.


## Robot workshop source and full-rig preflight — 2026-10-24

`author_arms.py` now supplies 22 separate source pieces per prepared arm,
with distinct mirrored identities, actual B-eye pin bores, neck/beam geometry,
restrained elbow/wrist, complete hand/thumb/digit cradle, three structural
support pads and four lifting faces. These are supplied representative sources,
not playable internal arm construction or a complete engineered arm inventory.
The left arm starts on the parked shared cassette; the right starts on passive
rests at shoulder datum (21,1.55,−6.3), clear of the cassette parking berth.

Each source has an explicit blockout mass allocation. The sum is 2033 kg with
longitudinal centre t3.305, between the t0.75/4.40 lifting pairs; the implied
horizontal pair reactions are approximately 30% proximal/70% distal. These
allocations establish reproducible prototype trim, not material strength,
crane ratings or a dynamic rigging simulation. The paired tensioned taglines,
four swivelling ends, adjustable spreader/equalizers and main hoist are included
in `arm_delivery_geometry.gd` and its collision queries. The runtime arm/crane
controller must consume this same geometry, including its positive outboard
upper-anchor offset; an inward upper anchor is a tested collision with the cup.

The prepared chest now includes actual fixed C-bridges and A clevises during
preflight. Relieved end arcs and upper webs preserve all six receiving pin
bores, including the inboard access port. The rear cup-root strut ends at chest
Z0.44 instead of Z0.25, so it joins the outside of the cup rather than penetrating
the ball cavity. A rear/inboard tie connects each descending bracket spine to
the existing dogleg. The source checks exposed the separate 0.65 m approach
conflict described above; the corrected 1.13 m stroke is now the authored route.

The single cassette has three saddles, six folding clamps, connected rails/ties,
four lifting pads and feet on flush floor bearing patches. Armor ports expose
the structural support pad and clamp faces at t4.05. Actual source rays confirm
all three saddle contacts; solid queries reject clamp/armor penetration. Folded
clamps end at Y1.68, below the Y1.70 limit. The retained cassette rises with its
lowest point at Y4.80 and crosses the actual horizontal prepared foot before
lowering into the clear shared station. Raised floor patches were rejected by
the combined right-leg delivery regression and replaced with flush bearings.

`arm_preflight_test.gd` stages real torso/leg geometry and the opposite arm,
keeps the parked cradle and source cassette as obstacles, and checks both full
paths plus the rig against its own payload through continuous upend/yaw/splay.
It also rejects the old 0.65 m approach, inward upper anchors, closed front
decks and a low cassette crossing. These are source/mechanical checks, not
walking, reach, presentation or installation-gameplay evidence. Cassette controls,
shared-station exchange, arm support handoffs, external shoulder stock/manuals,
pauldrons and interrupted saves remain to implement. The workshop implementation ledger records
the current verification result; do not mark the whole goal complete here.


### Retained cassette transfer — 2026-10-24

The same cassette is now a tracked equipment assembly on `cassette_park`,
`crane_rigging` or `cassette_station`. Its supported arm stays on
`arm_cassette` throughout transfer, rather than becoming a new inventory copy.
`author_cassette.py` derives 34 source pieces from the blockout and adds four
captive lock pins and four handles. These 42 prepared tool pieces are separate
from consumable robot stock. Runtime projects their exact meshes/colliders and
disables the original duplicate static cassette. The foot columns have actual
pin bores; the lock shafts/handles follow the crane's contact phase.

The existing crane's **Cassette to station** task handles both forward and
reverse transfer. Park the leg cradle, lower at cassette parking, fit all four
ends, then use Up / receiving station / Down. The first tenth of Up takes weight
and retracts the floor pins; the last tenth of Down engages them at contact.
Release the ends only after that support transfer. Return the empty crane to
parking when finished. To park the retained arm, reacquire at the receiving
station and reverse the same task. An occupied cassette prevents the leg cradle
from reclaiming the common station; parking the cassette restores leg operation.
No task switch clears or replaces arm construction.

The tool's nominal hollow-frame allocation is approximately559.86 kg, using
400 kg/m³ of outer frame-section volume plus steel pin/handle allocations.
With the supplied2033 kg arm, combined mass is approximately2592.86 kg and
longitudinal centre t3.438, between the t1.35/6.05 lifting pairs. The sliding hook
and main line align with that combined centre while the four end anchors retain
the checked positions. This is prototype trim, not a material/strength rating.
Both visible rig geometry and collision queries use that same hook position.

`arm_cassette_test.gd` exercises the retained round trip, shared-station
exclusion, same-arm identity, mesh/physics agreement between ticks and fresh-scene
restores during source lock release, suspension, receiving lock engagement and
both supported stops. Saves reject displaced retained arms, missing arm clamps,
lowered floor pins while airborne and mismatched crane/contact phases. A shared
save check was also corrected to apply bulky-fixture contact rules only to that
fixture, rather than every crane receiver. Rig-end attachment is staged in this
mechanical harness; walking, aim, readability and connection access remain the
user's playtest. The implementation ledger records the regression result.

That cassette increment preceded the arm installation work below; it did not
establish the full arm workflow or overall goal completion.

### Live delivery and shoulder connections — 2026-10-24

`author_shoulders.py` now supplies31 external pieces and32 chest-manual slots
per arm. The compatible types are the two complementary ring halves, M24 washers,
M24 ×240 bolts, Ø40 pins/keepers, complete screw-drive cartridges and the isolated
service harness. The staggered keyed brace is handed and has separate
left/right types. Physical stock identities stay independent of their receiving
slot geometry, including compatible copies exchanged across shoulders.

The live crane reads every authored orientation in the measured path. It takes
weight before the six cassette clamps release, raises horizontally, upends,
yaws, splays, traverses and seats along the1.13 m insertion axis. Full arm and
rig geometry remain collision checked. The initial clamp swing hit forearm
armour between its clear endpoints; each telescopic clamp now retracts0.40 m
outward through the existing port, then folds its remaining0.11 m reach.
Empty-cassette clamp adjustment also moves continuously and saves partway.
The second arm uses **Right arm to cassette**, lifting from its passive store
toY4.80, moving across toX14, passing forward toZ9.90 and lowering into the
same floor-locked tool. Receiving clamps close before rig release.

Seating retains full crane load. The chest manual then fits the ring halves and
four washer/bolt pairs, keyed brace and its two pin/keeper pairs, and three
drive cartridges with all six pin/keeper pairs. **Check shoulder brakes** and
**Transfer arm weight to shoulder** establish independent support; the latter
is a continuous, resumable phase. Connect the isolated harness before releasing
the four ends. The live rig and collision queries share the40 mm head take-up.
For local keeper correction, remove the isolated harness, refit all four ends,
use **Take arm weight**, then undo/refit the keeper. Removing structural hardware
invalidates brake confirmation. Recheck brakes, transfer weight and reconnect
services before release. The seated arm and hardware identities persist.

Source detail preserves the selected interfaces while clearing the actual
assembled parts:

- Ring liners use18 axial source slices approximating the R0.345 spherical
  clearance andØ0.48 exit. Front seam tongues fit relieved rear seams; recessed
  fastener faces remain inside t0.26. These are prototype source surfaces.
- A-ear supporting webs moved to t0.555..0.585, below the eye clearance. A180
  has paired backing plates outside the central eye, each preserving the R0.04
  tool port. Cross ties support both clevis ears without filling the throat.
- B-eye stems connect from t1.62 through narrow central webs, leaving cartridge
  forks clear. The three cartridge barrels have R0.018 end necks and open B
  forks; assembled source checks include their neighbouring arm lugs.
- Fixed brace tabs extend from t0.64 to0.80 at the selected radius/angles. The
  brace captures their sides/tips, then turns outboard before descending to the
  staggered keys. Narrow arm-key stems and a lower service-port support avoid
  the brace. These extra prepared solids pass the full arm approach check;
  the earlier t0.74 axial bound described the drive-clevis increment alone.
- The fixed service port follows robot(±2.00,+0.50,14.46). Its protected route
  crosses the high front channel and descends through |X|2.65..2.76 to the
  selected arm port. The visible harness is a bounded source proxy, not a
  constant-length or minimum-bend-radius engineering verification.

`shoulder_content_test.gd` checks actual bolt bores, Ø40 pin fit and assembled
neutral brace/drive clearance. `arm_delivery_test.gd` exercises both deliveries,
the second-arm cassette handoff, interrupted fresh-scene saves, compatible-copy
pose preservation, handed-brace rejection and supported keeper correction.
`arm_after_legs_test.gd` runs that sequence after both legs, chest, core and
backpack. These mechanical harnesses stage stock collection and rig attachment;
they do not establish walking, reach, input readability or rendered approval.
The workshop implementation ledger records the final retained regression evidence.

At the requested review pause, the final run passed the70-check source preflight
and32-check assembled shoulder fit audit. Its full sequence after both legs
stopped before cassette pickup at the foot-carrier clearance interlock; it did
not reach the new arm branch. The earlier isolated arm run passed299 checks.
Record that integration failure separately and resolve the carrier-return step
after human review rather than treating source clearance as a complete workflow
pass.

Pauldrons and removal of the supplied elbow/wrist/digit restraints remain
unfinished. The user requested an intermediate human review after the current
regression run; pause the active goal for that review rather than proceeding to
pauldrons or head construction.
