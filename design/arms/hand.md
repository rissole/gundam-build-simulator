# Hand

Last updated: 2026-10-24

[Design index](../../ROBOT_DESIGN.md) · [Shared design rules](../global.md)

The right arm will mirror this design.

Connected assemblies and clearance checks: [forearm and wrist](forearm-and-wrist.md).

Dimensions and reference pose: [shared proportion layout](../proportions.md#arms-and-hands).

## Confirmed design

### Hand layout and construction

- **Digit layout:** four fingers and an opposable thumb, with broadly humanlike hand proportions.
- **Finger shape and segmentation:** slightly chunky angular fingers with beveled edges and flat-ended fingertips; three articulated segments on each of the four fingers, and two main thumb segments on a separate pivoting base.
- **Palm skeleton:** a rigid palm chassis incorporating the wrist stem and ball, separate bolted finger-base mounting blocks, and a removable back-of-hand armor plate.
- **Contact surfaces:** segmented composite grip pads on the palm and finger undersides, with small armor plates over the finger backs and knuckles.

### Hand joints, actuation, and servicing

- **Finger hinges:** transverse pins through forked segment ends, with replaceable bushings and recessed retaining caps. Dimensions, exact joint stacks, and travel limits remain open.
- **Finger drives:** a compact geared rotary drive cartridge at each bending joint, allowing the joints to bend independently. Package each drive beneath removable armor/side covers; detailed gearing and packaging remain open.
- **Finger spread and thumb opposition:** limited sideways spread at the four finger bases, plus a two-axis thumb base allowing the thumb to sweep and fold across the palm. Thumb segments also bend at their hinges; exact axes, actuator arrangement, and clearances remain open.
- **Service layout:** protected wiring channels inside the palm, with an accessible local connector for each digit behind the back-of-hand plate. Each finger or thumb can be removed as a subassembly by disconnecting its wiring and undoing its base mounting bolts.

## Selected shared-arm transport boundary

The [shoulder/interface design](shoulder-and-upper-arm.md#shared-long-limb-preparation-and-supported-upending)
delivers the hand already connected to the complete arm. Preserve the 1.80 m
wrist-to-extended-middle-fingertip centreline and 0.90 × 0.45 palm envelope;
neither dimension bounds the projecting thumb or a transport cradle.

Reserve complete restrained hand/thumb/caps bounds relative to the wrist of
longitudinal t−0.15..+1.85 m, frontal cross-axis e±0.30 m and robot forward
Y−0.50..+0.75 m, using the shoulder sheet's axes. Fingers remain straight and
together, the thumb folds alongside/across the palm, and a retained digit cradle
prevents free movement. The allowance includes thumb projection and protective
caps; it is a working envelope to verify during digit modeling. It does not
replace the confirmed independent hinges/drives or require a special folded
finger pose to make the elevator clear.

A generic source clamp near shoulder station t6.05 engages structural palm
chassis/backplate receiver rails. The palm chassis carries that support; fingers,
thumb drives, grip pads and cosmetic armor carry no rigging/support load.
Restrain the wrist independently before lifting the connected arm. These
temporary supports are shared workshop equipment, not new robot inventory.

With both arms at locked 15° splay, the complete hand allowance reaches
|X|4.418, world X8.582..17.418, leaving 0.382 m to the selected elevator shaft
boxes. Those shafts now lie behind the arms at worldZ27.4..30.6,
with shelves/guards inside their reservations; see the
[coordinated access plan](../game/final-assembly-plan.md#shared-elevator-access-to-hips-and-shoulders).
Check the actual thumb/digit/cradle solids and full elevator travel with
both hands fitted before implementation; the 8.23 m fingertip-centre span is
not a cargo-clearance check. The shoulder sheet owns the full transport,
reachable rigging release, local correction and future review sequence.

## Open design work

### Hand refinement

- Palm, finger, and thumb dimensions; relative digit lengths and spacing.
- Integral wrist-ball/stem geometry and transition into the palm chassis.
- Finger-base mounting blocks, joint axes, pins, bushings, retaining hardware, and assembly access.
- Finger/thumb movement limits, mechanical stops, opposition, and grip clearances.
- Actuator and transmission packaging, mounting, access covers, and service connections.
- Wiring paths through the palm, fingers, and moving wrist.
- Back-of-hand and knuckle armor, finger plates, grip-pad segmentation, and attachment details.
- Component inventory, part identifiers, fasteners, and assembly sequence.
