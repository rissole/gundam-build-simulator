# Robot proportions and dimensional layout

Last updated: 2026-11-01

[Design index](../ROBOT_DESIGN.md) · [Shared design rules](global.md)

## Status and visual reference

**Approved silhouette, 2026-11-01 (approved for now).** The user found the
earlier envelopes weak ("a total weenie", chiefly the shoulders) and approved a
heavier silhouette with pauldrons reaching outward, a prominent forward-projecting
chest, fuller limbs, a wider hip skirt and larger hands and feet. Every joint
height is unchanged; the shoulder balls move out to |X| 2.45. The
[silhouette mannequin](../models/silhouette-mannequin/README.md) is the
geometric source of the revised envelopes below, and its turnaround is the
proportion guide for [whole-robot concept art](visual-design/README.md).
Values marked *(2026-11-01)* replace earlier accepted or working values, which
are kept in [decision history](decisions.md). Component specifications whose
detailed interfaces predate the revision say so at the top; their interface
numbers still need updating to these envelopes. The workshop game still builds
the earlier envelopes.

The user accepted both proposed proportion batches and asked the assistant to choose the remaining proportions to match a typical Gundam. The first two tables record the explicitly accepted recommendations. The subsequent layout and component envelopes are assistant-selected working dimensions under that direction; they can be refined when the detailed geometry is developed.

Use the RX-78-2 as the visual benchmark for the classic silhouette. The assistant's visual interpretation is broad shoulder armor, a narrow waist, a small helmet relative to the body, long legs, and angular feet. Reference: [official RX-78-2 Gundarium model gallery](https://en.gundam-official.com/feature/gundarium/), particularly its [full-body photograph](https://en.gundam-official.com/feature/gundarium/images/slide_01.jpg).

The numbers here are dimensions for this original robot, not published RX-78-2 specifications or measurements taken from the photograph. Preserve the agreed samurai helmet, calf thrusters, hinged backpack, and assembly boundaries.

All dimensions are in metres. This document owns shared landmarks, external envelopes and reference pose. The linked component specifications own detailed interfaces, moving clearances and fastening geometry; their 2026-10-24 interface designs are selected working dimensions, with solid/behavior verification still pending.

## Confirmed proportions and reference pose

| Choice | Confirmed specification | Design intent |
| --- | --- | --- |
| Height convention | Measure 18.0 m from the ground beneath the soles to the crest tips; helmet roof at 17.4 m | Give the complete silhouette a consistent total height |
| Leg landmarks | Hip-ball centers at 9.2 m, knee-hinge axes at 5.1 m, and ankle-pivot intersections at 1.0 m above the ground | Equal 4.1 m hip-to-knee and knee-to-ankle spans, preserving the athletic humanlike direction |
| Body widths | *(2026-11-01)* 7.24 m across the outer pauldrons in the reference pose; 4.80 m across the upper chest armor and 3.60 m across the fixed hip assembly armor, excluding thigh armor and hinged hip guards. Earlier: 5.6, 4.0 and 3.0 m | Broad shoulders reaching outward, a dominant upper chest and a narrow waist |
| Reference pose | Stand upright with straight knees and parallel feet; arms held 15 degrees away from the torso, elbows straight, palms facing inward | Make the limb outlines and joint gaps easier to inspect |

The leg heights describe joint centers, not removable-part lengths; sockets, forks, and armor overlap those boundaries. The 7.24 m shoulder width is measured across the pauldrons, not across the outward-angled arms and hands.

## Confirmed upper-body dimensions

| Choice | Confirmed specification | Measurement and intent |
| --- | --- | --- |
| Upper-body landmarks | Waist rotary-bearing center at 10.5 m, shoulder-ball centers at 14.4 m, and head-baseplate mounting plane at 15.4 m above ground | Establish the torso height and head position; the later working waist and chest interfaces are recorded below |
| Head envelope | 2.0 m from baseplate mounting plane to helmet roof, 2.0 m wide across the side guards, and 1.8 m deep from mask front to rear guards | Excludes the decorative crest; roof remains at 17.4 m and crest tips at 18.0 m |
| Arm lengths | 3.0 m shoulder-ball center to elbow axis, 2.6 m elbow axis to wrist-ball center, and 1.8 m wrist-ball center to the extended middle fingertip | Measure along the limb; with elbows, wrists, and fingers straight in the 15-degree reference pose, fingertips sit about 7.25 m above ground, near mid-thigh |
| Torso and backpack depth | *(2026-11-01)* Chest armor envelope 2.85 m front to back (Y −1.20…+1.65; earlier 2.4 m), with the closed backpack projecting up to 1.0 m beyond the rear torso armor, including nozzle mouths | Keep a compact rear profile; cockpit, core, spine, and opening clearances still need to be laid out inside and around these envelopes |

## Reference coordinates and stance

Working coordinate convention:

- Origin: on the ground halfway between the ankle centers.
- X: positive toward the robot's right; Y: positive forward; Z: positive upward.
- Arms extend outward in the frontal plane. Wrists are straight and fingers extended for dimensioned reference views.
- Hip, knee, and ankle centers align vertically on each side in the reference pose.
- Hip, knee, ankle, and arm joint centers lie at Y = 0 for the starting layout. The waist and head-baseplate centers also lie at Y = 0. Detailed joints may require explicitly recorded offsets later.

| Landmark | X position | Height Z | Basis |
| --- | --- | --- | --- |
| Hip-ball centers | ±1.10 | 9.20 | Selected spacing; confirmed height |
| Knee-axis centers | ±1.10 | 5.10 | Vertical leg alignment |
| Ankle-pivot intersections | ±1.10 | 1.00 | Sets a 2.20 m foot-center spacing |
| Waist rotary-bearing center | 0 | 10.50 | Confirmed height |
| Waist lean axis | 0 | 10.90 | Working transverse X axis at Y0; [hip assembly interface](torso/pelvis-and-waist.md) |
| Chest receiving plane | 0 | 11.30 | Working neutral seat; distinct from the rotary-bearing centre |
| Power cartridge axis | 0 | 11.95 | Working front–back Y axis, below the cockpit; [core interface](torso/backpack-and-power.md) |
| Shoulder-ball centers | ±2.45 | 14.40 | *(2026-11-01)* approved silhouette, earlier ±2.20; confirmed height |
| Elbow-axis centers | ±3.23 | 11.50 | Derived from 3.0 m upper arms at 15 degrees |
| Wrist-ball centers | ±3.90 | 8.99 | Derived from upper-arm and forearm lengths |
| Extended middle fingertips | ±4.37 | 7.25 | Derived with straight wrists and fingers |
| Head-baseplate center | 0 | 15.40 | Confirmed mounting-plane height |
| Fixed neck pilot tip | 0 | 15.58 | Working insertion feature above the unchanged head seat; [head interface](head.md) |

Coordinates derived from angles are rounded to two decimals; the confirmed lengths and angles take precedence. With 1.46 m-wide feet, the 2.20 m center spacing leaves a 0.74 m gap between the inner foot edges. The approximately 8.74 m span between middle fingertips is not an outer-hand bounding dimension.

## Component envelopes

These assistant-selected values complete the initial proportion layout. Width and depth describe outer armor unless otherwise stated. Limb cross-sections are measured perpendicular to the limb's length, not as projected widths in the reference pose.

### Legs and feet

| Component | Working dimensions | Notes |
| --- | --- | --- |
| Each foot | *(2026-11-01)* 3.36 long × 1.46 wide; earlier 3.00 × 1.30 | Heel edge 0.90 behind the ankle center; toe tip 2.46 ahead of it. The FA-01 detailed foot is still built to 3.00 × 1.30 |
| Forefoot hinge position | Transverse axis 2.00 forward of the heel edge; Y = +1.20 and Z = 0.35 (FA-01; scaling with the 2026-11-01 foot would put it near Y +1.34, to be decided in the foot revision) | Accepted with the forefoot construction; leaves a 1.00 m hinged toe section within the foot's total length |
| Main foot shell | Maximum height 0.70 above ground | Includes sole pads; excludes the ankle mechanism and separate side guards |
| Ankle side guards | Top at 1.60 above ground | Preserve a visible joint around the confirmed 1.00 m pivot height; exact guard outline remains open |
| Thigh armor | *(2026-11-01)* Maximum width 1.80 and depth 1.80; width tapers to 1.32 near the knee. Earlier 1.50 / 1.10 | Thigh remains slightly broader than the calf |
| Calf armor | *(2026-11-01)* Maximum width 1.65, tapering to 1.06 toward the ankle; maximum depth 2.24 including rear thruster enclosure. Earlier 1.40 / 0.90 / 1.90 | Keep the paired engines integrated into the calf |

Hip-to-knee and knee-to-ankle joint spans are both 4.10 m. Armor lengths and end gaps must be fitted around the knee, hip, and ankle mechanisms rather than equated to these spans.

### Torso and backpack

| Component | Working dimensions or placement | Notes |
| --- | --- | --- |
| Waist outer envelope | 2.20 wide × 1.60 deep | Narrowest main torso region; neutral mechanical detail in [hip assembly](torso/pelvis-and-waist.md) |
| Fixed hip assembly armor | *(2026-11-01)* 3.60 wide × 1.80 deep; earlier 3.00 | Hinged hip guards excluded; front hip guards now reach down to Z 7.85 over the thighs |
| Chest envelope placement | *(2026-11-01)* Front at Y = +1.65, rear at Y = −1.20; earlier front +1.20 | The upper chest is the dominant mass: widest (4.80 m) and furthest forward around Z 13.1–15.35, rising into a collar to Z 15.62 around the head base so no neck shows; tapers toward the waist below Z 13.1 |
| Closed backpack | 2.40 wide × 2.80 high; top at Z = 14.10, bottom at Z = 11.30 | Envelope includes its nozzles; selected X-axis hinge at Y−1.20/Z14.10, opening 90° |
| Backpack rear limit | Y = −2.20 | Uses the confirmed maximum 1.00 m projection beyond the rear torso armor |

Leave fixed torso surface visible on each side of the backpack for the vertical vent strips. The [torso packaging design](torso/chest-and-cockpit.md) places the capsule above the core and uses a lower portal in the rear spine. Its [dimensioned sections](torso/chest-and-cockpit-layout.svg) distinguish internal allocations from the external envelope. Actual solid, articulation and access checks remain required; use the component documents for capsule/core dimensions and removal paths.

### Arms and hands

| Component | Working cross-section | Notes |
| --- | --- | --- |
| Upper-arm armor | *(2026-11-01)* Maximum 1.01 wide × 1.12 deep; earlier 0.90 × 1.00 | Excludes the pauldron; taper toward the elbow |
| Forearm armor | *(2026-11-01)* Maximum 1.45 wide × 1.45 deep; earlier 1.10 | Slightly fuller than the upper arm |
| Wrist cuff | *(2026-11-01)* 0.99 wide × 0.99 deep; earlier 0.75 | External cuff envelope, not the socket or ball diameter |
| Palm chassis with armor | *(2026-11-01)* 1.08 wide × 0.54 thick; earlier 0.90 × 0.45 | Excludes the projecting thumb; digit lengths and full hand spread remain open |

*(2026-11-01)* Each rigid pauldron's envelope is |X| 1.95–3.62, Y ±0.95, Z 13.30–15.50 (7.24 m total width): it reaches outward with its top near chin level, level with the chest top, sloping down outboard, and each arm hangs below its middle. Earlier: |X| 1.62–2.80, Y ±0.65, Z 13.65–15.05. The [shoulder specification](arms/shoulder-and-upper-arm.md)'s reference top at Z15.05, relieved inner skirt and fixed-frame interface predate this revision. The maximum chest width need not occur at shoulder-joint height. Complete-arm handling uses its separate piecewise hand/thumb bounds and a restrained 15° pose; arbitrary finger spread or shoulder motion is not covered by the elevator clearance calculation.

### Head and crest

The helmet envelope is the confirmed 2.00 m high × 2.00 m wide × 1.80 m deep. Place its front mask limit at Y = +0.90 and rear guard limit at Y = −0.90, with the baseplate at Z = 15.40 and roof at Z = 17.40. Use a 2.60 m tip-to-tip crest width as the working silhouette target; the crest reaches the confirmed Z = 18.00 height.

## Remaining dimensional work

- Revising component interfaces, handling envelopes and the FA-01 foot to the 2026-11-01 silhouette: shoulder sockets and crossmember ends at |X| 2.45, the deeper chest and sternum hatch, the larger pauldrons, limbs, hip armor and feet.
- Detailed armor outlines, overlap, and gaps within these envelopes.
- Detailed solids and bearing stacks implementing the selected waist, hip and other component interfaces.
- Pilot/manikin, service-route and tool-path verification of the selected cockpit/core/spine packaging; detailed sensor and thruster internals.
- Hatch, backpack, guard, and limb movement clearances.
- Individual plates, brackets, pins, fasteners, part identifiers, and installation access.

Record changes to shared landmarks/envelopes here and explain them in the decision history. Keep local connection hardware and interface dimensions in their owning component sheets rather than duplicating their full specifications here.
