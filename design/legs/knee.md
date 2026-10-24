# Knee

Last updated: 2026-10-24

[Design index](../../ROBOT_DESIGN.md) · [Shared design rules](../global.md)

The right leg will mirror this design.

Connected assemblies and clearance checks: [shin and calf](shin-and-calf.md), [thigh and hip](thigh-and-hip.md).

Dimensions and reference pose: [shared proportion layout](../proportions.md#legs-and-feet).

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
