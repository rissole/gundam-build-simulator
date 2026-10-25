# Thigh and hip

Last updated: 2026-10-24

[Design index](../../ROBOT_DESIGN.md) · [Shared design rules](../global.md)

The right leg will mirror this design.

Connected assemblies and clearance checks: [knee](knee.md), [hip assembly](../torso/pelvis-and-waist.md).

Dimensions and reference pose: [shared proportion layout](../proportions.md#legs-and-feet).

## Confirmed design

### Thigh

- **Silhouette:** athletic upper thigh, slightly broader than the calf, tapering toward the knee.
- **Skeleton:** a central box-section spar incorporating the hip ball and neck at its upper end, with a detachable lower knee fork and separate mounting brackets for armor and knee actuators.
- **Armor:** a broad front plate, separate inner and outer side plates, and two narrower rear covers flanking a central service channel.
- **Rear exposure:** a narrow, recessed service channel showing part of the frame and protected cable runs; the knee actuators remain visible farther down.

### Hip ball and leg interface

- **Joint type:** ball and socket.
- **Confirmed movement:** forward swing, outward splay, and limited inward/outward thigh twist through the ball joint.
- **Leg-side component:** the ball and neck form the integral upper end of the thigh skeleton. Use this as the current interpretation of the user's preference for the ball to be part of the thigh skeleton; fabrication details remain open.
- **Torso-side component:** the matching socket belongs to the hip assembly on the torso.
- **Socket retention:** a socket bowl with a removable two-piece retaining ring bolted to the socket housing. Seat the ball in the bowl, then fit the ring halves around the neck and secure them to capture the ball while preserving bearing clearance for movement.
- **Twist limits:** use mechanical stops to limit inward/outward thigh rotation. The working interface below selects ±10° twist; no separate thigh swivel bearing is required by this concept.
- **Visibility:** retain a narrow mechanical gap above the thigh armor, exposing part of the hip mechanism and inner frame. The exact ball/socket surfaces visible through this gap remain to be defined.
- **Working detail:** the interface contract below resolves movement bounds, three-cylinder attachment geometry and structural retention from the established prototype. Final bearing/stop contact and armor sweeps remain model-verification work.

The earlier nested-pivot and separate thigh rotary-bearing proposal was not adopted. The leg-to-hip assembly connection is now defined by the ball/socket interface; the earlier proposal for a complete leg-side hip module bolted to the hip assembly is not an approved attachment method.

## Open design work

### Thigh refinement

- Detailed armor length, taper, and beam cross-section within the [shared leg dimensions](../proportions.md#legs-and-feet).
- Attachment between the central spar and detachable knee fork.
- Armor mounting brackets, panel seams, and removal access.
- Rear service-channel geometry, cable protection, and routing around moving joints.
- Knee-actuator brackets and clearance beneath the lower thigh armor.
- Geometry of the integral hip ball and neck at the upper end of the spar.
- Component inventory, part identifiers, fasteners, and assembly sequence.

## Working leg-to-hip assembly interface — 2026-10-24

This develops the leg-side boundary under delegated design authority. The
[hip assembly specification](../torso/pelvis-and-waist.md#working-interface-specification--2026-10-24)
owns the complete receiving mechanism, hardware allocation, support/release
conditions and detailed access checks; keep that packet authoritative for
hip assembly-owned pieces. Dimensions below are a coordinated leg manufacturing
interface, not a new playable build or a claim of solid-model verification.

Use robot X right/Y forward/Z up, metres. Hip centre is
`H=(s×1.10,0,9.20)`, `s=+1` right/`−1` left. Workshop comparison uses
`world=(13+X,1.4+Z,26−Y)`. A leg's local datum is its ball centre, with the
reference spar vertical below it. Left/right lug carriers and stop tongues are
mirrored in X. Identical hydraulic cylinders and removable pins are shared
compatible types; mirrored destination geometry does not create a cylinder type.

### Ball, neck, spar and retained movement

Preserve the leg journey's **integral Ø.900 ball and Ø.300 neck**, ball at H; the neck
continues down into the .300 X ×.200 Y central upper spar. Its current source
neck occupies approximately H.Z−.865..−.415, overlapping the spar transition.
The sphere, neck and spar remain one leg-owned manufactured structural item,
LG-120; collars, lugs or a diagram must not silently split it into a separately
bolted hip-ball module. The lower detachable knee fork remains unchanged.

The hip assembly socket receives the ball vertically upwards with its retaining ring
removed. Retain spherical inner/outer radii .456/.530 and entry radius .460.
The two existing interchangeable retaining halves occupy hip-relative
Z−.430..−.350, thickness .080, inner/outer radii .300/.680. Four upward
M24×140 bolts with .004 washers on the R.575 diagonal bolt circle retain them.
These are hip assembly-manual supplies. Structural retention requires both halves and
all four pairs; none becomes leg inventory during collection or undo.

Working motion is forward/back **+15°/−10°**, outward/inward **+15°/−6°**,
twist **±10°**, with total swing inside a **16° cone**. The right-leg transform
is `Ry(−splay) Rx(forward) Rz(twist)` about H; mirror X for the left. The
twist occurs about the tilted leg axis. The cone test is
`acos(cos(forward)cos(splay))≤16°`; the two 15° maxima cannot coexist. At
16° the neck's conservative ring-hole radius demand is .279 against .300,
leaving .021 m; the inherited ring reaches its geometric limit around18.3°.
Do not advertise wide strides without revisiting that established joint.

Fit a two-piece leg-owned neck collar below the cage's conical lip, with body
radius .160 and two integral tongues reaching radius .220,
Z=H.Z−.76..−.72. Its positive key/flat on the spar
transition prevents collar rotation without changing the ball diameter or neck
section. The hip assembly owns a removable two-piece stop cage of outer radius .46
around it, Z=H.Z−.82..−.60: the .335-radius conical lip at Z=H.Z−.62 limits swing to16° and
spherical window flanks limit tongue twist to±10° through the allowed cone.
Prepare the collar/tongues with the leg; install the hip assembly cage only after the
retaining ring. The cage carries end-stop contact and protects the gap, not the
ball's structural retention. Future source solids must prove window contact,
neck clearance and tool access before the inherited ring is loaded as a stop.

### Three hydraulic lower-lug connections

The hip assembly owns three identical double-acting hydraulic cylinder cartridges per
hip. Each lower spherical eye connects to a separate leg-owned lug carrier bolted
to the spar. The carriers provide three non-coplanar moment arms; there is no
separate rotary hip actuator or thigh swivel. Right-hip-relative neutral lug-eye
centres are the following; mirror X for the left:

| Carrier position | Eye centre relative to H | Pin entry/extraction | Neutral raised-world target, right / left |
| --- | --- | --- | --- |
| Outer/front | `(+.339,+.339,−1.800)` | Robot +Y | `(14.439,8.800,25.661)` / `(11.561,8.800,25.661)` |
| Inner/front | `(−.464,+.124,−1.800)` | Robot +Y | `(13.636,8.800,25.876)` / `(12.364,8.800,25.876)` |
| Inner/rear | `(+.124,−.464,−1.800)` | Robot −Y | `(14.224,8.800,26.464)` / `(11.776,8.800,26.464)` |

Carrier-to-spar roots occupy Z=H.Z−1.95..−1.60 and bear on keyed side/front/rear
saddle faces of the box spar. Each is a separate physical bracket, using two
M24×100 bolts/two .004 washers into its prepared backing rail; integral keys
carry shear. The radial projecting arm terminates at the listed eye centre and
stays inside a .10-radius structural envelope about the root-to-eye segment.
Do not replace the spar with a solid .96-diameter disk between these points:
leave open front/rear service and cylinder approach channels.

Use .094 clevis gap for a .090-wide spherical eye, .050 cheeks, Ø.062 bores,
and hip assembly-owned Ø.060×.220 shouldered pins with captive far-side keepers.
Reserve .34 m along the stated ±Y entry side plus R.08 for the complete pin and
release tool. The keeper has a captive release accessible from that same side;
it does not require reaching behind the spar for a loose nut. Both leg sides use
this same front/front/rear access convention, avoiding extraction into the
opposite leg. Carriers are handed; all six hip cylinder cartridges/twelve eye
pins are interchangeable after clocking spherical eyes/neutral-lock access.

The hip assembly upper eyes lie on R.78 at angles0°/120°/240°, Z−.60; lower eyes
lie on R.48 at45°/165°/285°, Z−1.80. The selected cylinder eye-distance range
is1.02..1.68, neutral1.323, stroke.66, barrelØ.140/rodØ.070. A bounded
5,720-pose sample gives1.059..1.625 eye distances and no zero/sign change in
the length Jacobian determinant (minimum .296 m³). The sampled right-hip centreline
endpoint box is X−.664..+.851/Y−.784..+.846/Z−1.863..−.600, enlarged by
.08 for cartridge/fittings. This box moves relative to the fixed hip assembly; thigh
armor must leave genuine channels instead of hiding intersections. Exact sphere-eye
angles, force/pressure sizing and continuously swept solids remain later checks.

### Services, armor gaps and preparation boundary

The leg-side power/data and hydraulic dry-break block is centred
`(s×.78,+.60,8.35)`, facing +Y, with .18 forward withdrawal/R.10 hand space.
The hip assembly mate is at `(s×.78,+.70,9.05)`. A leg-owned .95-free-length protected
U-loop, minimum bend radius .12, follows the front-inner channel and clips to
the spar before thigh armor. It does not share a pin tube, cross the ring or
route across the gap into the opposite leg. Existing ankle harness ownership is
unchanged; a hip-tail assembly is distinct from the foot's FA-605 main input.

Keep the mechanical gap above thigh armor and recess the three upper-thigh rod/
lug channels rather than expanding the fixed thigh armor beyond its1.50×1.50
neutral envelope. Individual moving fittings may occupy the documented joint
sweep outside that envelope. Upper front/inner/rear service closures stay off
through ring work, cylinder pins, neutral locks and service checks. Compact hip assembly
front/outer guards belong to the torso; do not duplicate them as thigh panels.
A full armor/guard sweep is required before final channel edges are modeled.

The leg workstation prepares its spar, neck collar/tongues, three keyed lug
carriers, leg service block/loop and all internal leg connections. The rail holds
the unpowered leg during horizontal construction, tilt/rise and upward ball
seating. The parent hip assembly workflow then installs both retaining halves/four
bolt pairs, the stop cage, three supported cylinders and six eye pins/keepers,
and the service loop connection. The player carries each neutral-length cartridge
upright with ordinary assisted two-hand carrying from the finite elevator shelf
along the landing; its approximate envelope is1.49×.24×.24, with at least.90
clear walking width. No shelf-mounted arm spans from the distant elevator.
Hip assembly-clevis parking hooks capture the upper-eye lugs and visibly close a
captive catch, freeing both hands for the upper pin/keeper. The secured upper
eye then carries the cartridge while its lower eye is guided into the leg
clevis's open-top rest. A captive parking gate holds alignment and frees both
hands for the lower pin/keeper. Keep that rest below the eye's outer rim, clear
of the ±Y pin tube and the cylinder neck above it. Engage the external neutral
index lock after both pins/keepers are secure, then stow the parking catches
clear of spherical-eye motion. These local bracket features hold the cartridge
visibly during pin work; the rail still holds the leg. The hip assembly packet owns
the matching upper rest and the complete carry/seat/retain/release sequence.

**Holder release requires all three cylinder neutral locks and all six pins/
keepers as well as complete ring retention.** Those external mechanical locks
hold all three actuator lengths independently of pressure and free the rail and
shared crane. Hydraulic load-holding valves alone do not establish pose restraint.
Knee/ankle transport restraint remains the relevant joint/rail workflow's concern.
Before undoing an actuator or retaining hardware, reacquire rail support, engage
all neutral locks, remove blocking guards, disconnect relevant services and then
reverse the affected connection. Keep the same physical identities throughout.

All three lower pins are reachable from world deck8.40 with open front/rear inner
edges at robotY+1.40/−1.35 (worldZ24.60/27.35), standingY+1.70/−1.65. Align playerX with the listed targetX;
front/front/rear eye-to-target distances are about1.83/2.00/1.71 m for a1.63 m
eye height. The .34 pin tubes remain inside the open inner edge. These bounded
face/reach calculations require future walked visibility/solid checks with the
first leg present during second-leg work; historical leg-journey side-ring access does
not prove the new lower-pin operation.

### Shared cradle boundary

The [coordinated fixture/route plan](../game/final-assembly-plan.md#shared-limb-workshop-with-different-departure-routes)
uses exposed fork-side transport pads near robotX±0.80/Z6.10 plus shin pads
atZ2.80, rather than a high rear contact that obstructs hip pins/platforms.
Upper holder extent isZ6.30; the rear spine is atY−1.45, clear of the calf
thrusters. The rail retains knee/ankle neutral pose, and an empty fork withdraws
rearward then shifts outboard before returning. These are workshop support
contacts, not a change to the integral ball, ring or hip-cylinder interfaces.

### Review scope and remaining work

Keep leg internal build refinement above independent of this hip interface pass.
Before source/game implementation, audit ball/neck/ring and stop-cage contacts,
all three keyed lug roots, both handed carrier sets, cartridge/armor/loop sweeps,
pin extraction volumes, simultaneous two-leg clearance and rail-to-neutral-lock
handoff. A future manual must allocate each new carrier/hardware only to leg
preparation and each cylinder/ring/eye pin only to the hip assembly mounting pages.
Test compatible-cylinder/pin/ring swaps, wrong-variant rejection and supported
local undo with identity conservation when implemented. No gameplay tests or
rendered review were run for this design-only revision.
