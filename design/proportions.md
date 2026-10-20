# Robot proportions and dimensional layout

Last updated: 2026-10-20

[Design index](../ROBOT_DESIGN.md) · [Shared design rules](global.md)

## Status and visual reference

The user accepted both proposed proportion batches and asked the assistant to choose the remaining proportions to match a typical Gundam. The first two tables record the explicitly accepted recommendations. The subsequent layout and component envelopes are assistant-selected working dimensions under that direction; they can be refined when the detailed geometry is developed.

Use the RX-78-2 as the visual benchmark for the classic silhouette. The assistant's visual interpretation is broad shoulder armor, a narrow waist, a small helmet relative to the body, long legs, and angular feet. Reference: [official RX-78-2 Gundarium model gallery](https://en.gundam-official.com/feature/gundarium/), particularly its [full-body photograph](https://en.gundam-official.com/feature/gundarium/images/slide_01.jpg).

The numbers here are dimensions for this original robot, not published RX-78-2 specifications or measurements taken from the photograph. Preserve the agreed samurai helmet, calf thrusters, hinged backpack, and assembly boundaries.

All dimensions are in metres. These are external envelopes and joint locations; detailed surfaces, moving clearances, panel thicknesses, and fastener dimensions remain open.

## Confirmed proportions and reference pose

| Choice | Confirmed specification | Design intent |
| --- | --- | --- |
| Height convention | Measure 18.0 m from the ground beneath the soles to the crest tips; helmet roof at 17.4 m | Give the complete silhouette a consistent total height |
| Leg landmarks | Hip-ball centers at 9.2 m, knee-hinge axes at 5.1 m, and ankle-pivot intersections at 1.0 m above the ground | Equal 4.1 m hip-to-knee and knee-to-ankle spans, preserving the athletic humanlike direction |
| Body widths | 5.6 m across the outer pauldrons in the reference pose; 4.0 m across the chest armor and 3.0 m across the fixed pelvis armor, excluding thigh armor and hinged hip guards | Establish broad shoulders and a narrower lower torso |
| Reference pose | Stand upright with straight knees and parallel feet; arms held 15 degrees away from the torso, elbows straight, palms facing inward | Make the limb outlines and joint gaps easier to inspect |

The leg heights describe joint centers, not removable-part lengths; sockets, forks, and armor overlap those boundaries. The 5.6 m shoulder width is measured across the pauldrons, not across the outward-angled arms and hands.

## Confirmed upper-body dimensions

| Choice | Confirmed specification | Measurement and intent |
| --- | --- | --- |
| Upper-body landmarks | Waist rotary-bearing center at 10.5 m, shoulder-ball centers at 14.4 m, and head-baseplate mounting plane at 15.4 m above ground | Establish the torso height and head position; the waist lean-pivot offset remains open |
| Head envelope | 2.0 m from baseplate mounting plane to helmet roof, 2.0 m wide across the side guards, and 1.8 m deep from mask front to rear guards | Excludes the decorative crest; roof remains at 17.4 m and crest tips at 18.0 m |
| Arm lengths | 3.0 m shoulder-ball center to elbow axis, 2.6 m elbow axis to wrist-ball center, and 1.8 m wrist-ball center to the extended middle fingertip | Measure along the limb; with elbows, wrists, and fingers straight in the 15-degree reference pose, fingertips sit about 7.25 m above ground, near mid-thigh |
| Torso and backpack depth | Chest armor envelope 2.4 m front to back, with the closed backpack projecting up to 1.0 m beyond the rear torso armor, including nozzle mouths | Keep a compact rear profile; cockpit, core, spine, and opening clearances still need to be laid out inside and around these envelopes |

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
| Shoulder-ball centers | ±2.20 | 14.40 | Selected spacing; confirmed height |
| Elbow-axis centers | ±2.98 | 11.50 | Derived from 3.0 m upper arms at 15 degrees |
| Wrist-ball centers | ±3.65 | 8.99 | Derived from upper-arm and forearm lengths |
| Extended middle fingertips | ±4.12 | 7.25 | Derived with straight wrists and fingers |
| Head-baseplate center | 0 | 15.40 | Confirmed mounting-plane height |

Coordinates derived from angles are rounded to two decimals; the confirmed lengths and angles take precedence. With 1.30 m-wide feet, the 2.20 m center spacing leaves a 0.90 m gap between the inner foot edges. The approximately 8.23 m span between middle fingertips is not an outer-hand bounding dimension.

## Component envelopes

These assistant-selected values complete the initial proportion layout. Width and depth describe outer armor unless otherwise stated. Limb cross-sections are measured perpendicular to the limb's length, not as projected widths in the reference pose.

### Legs and feet

| Component | Working dimensions | Notes |
| --- | --- | --- |
| Each foot | 3.00 long × 1.30 wide | Heel edge 0.80 behind the ankle center; toe tip 2.20 ahead of it |
| Forefoot hinge position | Transverse axis 2.00 forward of the heel edge; Y = +1.20 and Z = 0.35 | Accepted with the forefoot construction; leaves a 1.00 m hinged toe section within the foot's total length |
| Main foot shell | Maximum height 0.70 above ground | Includes sole pads; excludes the ankle mechanism and separate side guards |
| Ankle side guards | Top at 1.60 above ground | Preserve a visible joint around the confirmed 1.00 m pivot height; exact guard outline remains open |
| Thigh armor | Maximum width 1.50 and depth 1.50; width tapers to 1.10 near the knee | Thigh remains slightly broader than the calf |
| Calf armor | Maximum width 1.40, tapering to 0.90 toward the ankle; maximum depth 1.90 including rear thruster enclosure | Keep the paired engines integrated into the calf |

Hip-to-knee and knee-to-ankle joint spans are both 4.10 m. Armor lengths and end gaps must be fitted around the knee, hip, and ankle mechanisms rather than equated to these spans.

### Torso and backpack

| Component | Working dimensions or placement | Notes |
| --- | --- | --- |
| Waist outer envelope | 2.20 wide × 1.60 deep | Narrowest main torso region; bearing and pivot sizes still open |
| Fixed pelvis armor | 3.00 wide × 1.80 deep | Width already confirmed; hinged hip guards excluded |
| Chest envelope placement | Front at Y = +1.20, rear at Y = −1.20 | Uses confirmed 2.40 m depth; shape tapers toward the waist |
| Closed backpack | 2.40 wide × 2.80 high; top at Z = 14.10, bottom at Z = 11.30 | Envelope includes its nozzles; detailed top hinge axis and opening travel remain open |
| Backpack rear limit | Y = −2.20 | Uses the confirmed maximum 1.00 m projection beyond the rear torso armor |

Leave fixed torso surface visible on each side of the backpack for the vertical vent strips. The internal cockpit, power cartridge, and spine require a separate packaging pass; these outer dimensions do not settle their internal shapes or prove access clearance.

### Arms and hands

| Component | Working cross-section | Notes |
| --- | --- | --- |
| Upper-arm armor | Maximum 0.90 wide × 1.00 deep | Excludes the pauldron; taper toward the elbow |
| Forearm armor | Maximum 1.10 wide × 1.10 deep | Slightly fuller than the upper arm |
| Wrist cuff | 0.75 wide × 0.75 deep | External cuff envelope, not the socket or ball diameter |
| Palm chassis with armor | 0.90 wide × 0.45 thick | Excludes the projecting thumb; digit lengths and full hand spread remain open |

Fit the rigid pauldrons to the confirmed 5.60 m total shoulder width and the selected shoulder-joint spacing. Their local dimensions and top height must be resolved against the sloping upper chest and neck; the maximum chest width need not occur at shoulder-joint height.

### Head and crest

The helmet envelope is the confirmed 2.00 m high × 2.00 m wide × 1.80 m deep. Place its front mask limit at Y = +0.90 and rear guard limit at Y = −0.90, with the baseplate at Z = 15.40 and roof at Z = 17.40. Use a 2.60 m tip-to-tip crest width as the working silhouette target; the crest reaches the confirmed Z = 18.00 height.

## Remaining dimensional work

- Detailed armor outlines, overlap, and gaps within these envelopes.
- Joint diameters, bearing stacks, waist lean-pivot position, movement limits, and actuator geometry.
- Cockpit, core, spine, sensors, thrusters, and service-route packaging.
- Hatch, backpack, guard, and limb movement clearances.
- Individual plates, brackets, pins, fasteners, part identifiers, and installation access.

Record dimensional changes here and explain them in the decision history so component sheets continue to use one shared layout.
