# Thigh and hip

Last updated: 2026-10-20

[Design index](../../ROBOT_DESIGN.md) · [Shared design rules](../global.md)

The right leg will mirror this design.

Connected assemblies and clearance checks: [knee](knee.md), [pelvis and waist](../torso/pelvis-and-waist.md).

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
- **Torso-side component:** the matching socket belongs to the pelvis on the torso.
- **Socket retention:** a socket bowl with a removable two-piece retaining ring bolted to the socket housing. Seat the ball in the bowl, then fit the ring halves around the neck and secure them to capture the ball while preserving bearing clearance for movement.
- **Twist limits:** use mechanical stops to limit inward/outward thigh rotation. Exact angles and stop geometry remain open; no separate thigh swivel bearing is required by this concept.
- **Visibility:** retain a narrow mechanical gap above the thigh armor, exposing part of the hip mechanism and inner frame. The exact ball/socket surfaces visible through this gap remain to be defined.
- **Unresolved:** backward travel, inward swing toward the body centerline, numerical movement limits, actuator count and detailed layout, ball/neck/frame geometry, bearing liners, and retention-hardware details.

The earlier nested-pivot and separate thigh rotary-bearing proposal was not adopted. The leg-to-pelvis connection is now defined by the ball/socket interface; the earlier proposal for a complete leg-side hip module bolted to the pelvis is not an approved attachment method.

## Open design work

### Thigh refinement

- Detailed armor length, taper, and beam cross-section within the [shared leg dimensions](../proportions.md#legs-and-feet).
- Attachment between the central spar and detachable knee fork.
- Armor mounting brackets, panel seams, and removal access.
- Rear service-channel geometry, cable protection, and routing around moving joints.
- Knee-actuator brackets and clearance beneath the lower thigh armor.
- Geometry of the integral hip ball and neck at the upper end of the spar.
- Component inventory, part identifiers, fasteners, and assembly sequence.

### Hip and pelvis-interface refinement

- Ball diameter, neck geometry, and transition into the thigh frame.
- Socket housing, bearing liners, split-ring geometry, retaining fasteners, and assembly access.
- Socket orientation and housing geometry around the hip centers in the [shared reference layout](../proportions.md#reference-coordinates-and-stance).
- Forward and splay ranges, backward/inward swing, permitted twist angles, and mechanical-stop geometry.
- Hip-actuator count, detailed drive arrangement, jointed end connections, stroke, and mounting points, following the hydraulic preference recorded in [hip actuation](../torso/pelvis-and-waist.md#hip-actuation).
- Hip-guard mounting, front-guard movement, and clearance around the joint.
- Protected service connectors and routing across the leg-to-torso boundary.
- Component inventory, part identifiers, fasteners, and assembly sequence.
