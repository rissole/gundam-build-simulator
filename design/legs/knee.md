# Knee

Last updated: 2026-11-01

[Design index](../../ROBOT_DESIGN.md) · [Shared design rules](../global.md)

The right leg will mirror this design.

Connected assemblies and clearance checks: [shin and calf](shin-and-calf.md), [thigh and hip](thigh-and-hip.md).

Dimensions and reference pose: [shared proportion layout](../proportions.md#legs-and-feet).

> **Concept sheets, 2026-11-01:** [LG-01](images/README.md) draws the knee in the approved look; part numbers are in the [leg component list](leg-components.csv). The sheets' knee cylinders are drawn wrongly (thigh to fork); this specification governs.

> **Modelled 2026-11-01:** [LG-01-3D-01](../../models/leg-lg01/README.md) includes the hinge, thigh-to-shin cylinders and knee armor.
> Neutral interfaces pass the recorded audits; joint travel, force sizing and game integration remain open.

## Model-settled working values — 2026-11-01

Coordinates are **leg-local metres**, ground origin beneath the ankle, +X inner,
+Y forward, +Z up. The workshop interface below predates the silhouette revision;
its transport bound and Z6.300 flange reference are not the model's final geometry.

- Cylinder eyes are (±0.460,−0.460,6.400) on the thigh and
  (±0.440,−0.500,4.300) on the shin. Neutral span is 2.100476; retracted length
  1.650, extension 0.450476 and usable kit stroke 1.208. These do not prove knee travel.
- Axle Ø0.200 spans X±0.500 at Z5.100 and enters from outboard −X. Bearings
  are OD0.298/ID0.204 × 0.120 at X±0.210; spacers are 0.075 long at X±0.3175.
- Fork transport bearing faces are X±0.800, Y−0.110…+0.170,
  Z5.980…6.220; backing remains below Z6.300. Spar/fork flanges meet at Z5.920.
  Revised thigh armor requires openings and a later workshop-fit revision.
- Knee eye pins/keepers still lack inventory allocation. Guard returns remain
  within absolute X0.670; no wider knee interface has been selected.

## Confirmed design

### Knee

| Component | Confirmed concept |
| --- | --- |
| Main joint | One primary hinge with a horizontal axle |
| Thigh-side connection | The lower thigh frame ends in a fork around the top of the shin |
| Joint hardware | Separate bearings, retaining caps, and brackets for the eventual assembly breakdown |
| Kneecap | Compact, faceted shield, wider at the top and tapering downward |
| Kneecap mounting | Separate bracket attached to the upper shin, with clearance behind the shield for the joint |
| Side details | Visible circular bearing caps recessed inside angular guards |
| Knee actuators | A pair of partially exposed hydraulic cylinders at the rear sides of the knee |
| Upper actuator mounts | Tucked under the thigh armor |

Leave the central rear knee open. Position the calf thruster enclosure below the knee's movement space. Exact clearances, actuator geometry, and joint travel remain to be defined.

## Workshop support and axle access — 2026-10-24

The [shared limb/rail plan](../game/final-assembly-plan.md#shared-limb-workshop-with-different-departure-routes)
uses the existing structural connection as its baseline. Select **outboard
axle insertion**: left from−X, right mirrored from+X, with1.20 m clear extraction
space. Reserve transport frame pads near robotX±0.80/Z6.10 on the thigh-side
fork, clear of axleZ5.10 and flangeZ6.30. The cradle's upper extent stops at
Z6.30 so it clears the gantry hip deck and lower actuator pins. Tie the pads
into structural material and leave them exposed; neither rear knee cylinders
nor cosmetic caps carry the leg. Actual fork/axle/drive solids and the internal
build sequence remain the knee detail pass. Keep the complete transport knee
bound within X±0.80/Y±0.75 for this workshop contract, or explicitly revise
that contract when detail requires more space.

## Open design work

### Knee refinement

- Axle diameter, bearing arrangement, retaining hardware, and installation access.
- Thigh-fork and upper-shin geometry at the main hinge.
- Joint travel limits and mechanical stops.
- Hydraulic-cylinder construction, upper and lower attachment points, stroke, hose routing, and movement clearances.
- Kneecap bracket geometry and armor clearances through the bend.
- Clearances between the rear knee mechanisms and the calf thruster enclosure.
- Component inventory, part identifiers, fasteners, and assembly sequence.
