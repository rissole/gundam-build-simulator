# Shoulder, upper arm, and elbow

Last updated: 2026-10-20

[Design index](../../ROBOT_DESIGN.md) · [Shared design rules](../global.md)

The right arm will mirror this design.

Connected assemblies and clearance checks: [chest and cockpit](../torso/chest-and-cockpit.md), [forearm and wrist](forearm-and-wrist.md), [head](../head.md), [backpack](../torso/backpack-and-power.md).

Dimensions and reference pose: [shared proportion layout](../proportions.md#arms-and-hands).

## Confirmed design

### Shoulder

- **Joint and assembly boundary:** a ball-and-socket joint, with the ball integral to the upper-arm skeleton and the socket at the outer end of the torso's shoulder crossmember. A removable two-piece retaining ring captures the ball, repeating the hip's retention principle. Shoulder dimensions, actuation, movement limits, and hardware remain open.
- **Armor silhouette:** a boxy pauldron for a more mechanical appearance. Exact width, overhang, and panel geometry remain open within the overall humanlike-proportion direction.
- **Armor mounting:** rigid relative to the upper-arm skeleton, moving with the arm. The pauldron belongs to the arm assembly and has no independent articulation. Rigid mounting does not change the overall removable-armor construction principle; attachment hardware remains open.
- **Joint visibility:** a narrow mechanical gap beneath the pauldron exposes part of the socket rim and inner frame.
- **Clearance requirement:** check the rigid pauldron against the chest, neck, and backpack through shoulder movement. Set achievable travel and stops during the geometry pass.

The earlier compact-cap and independent armor-hinge recommendations were not adopted.

### Upper arm and elbow

- **Upper-arm silhouette:** a relatively slim, angular upper arm with a mild taper toward the elbow, giving the boxy shoulder armor visual prominence.
- **Frame and armor:** a central box-section beam incorporating the confirmed shoulder ball, with a detachable lower elbow fork and removable front/rear armor shells.
- **Elbow joint:** one main hinge with a transverse axle, separate bearings, and visible circular retaining caps recessed within angular guards. The upper-arm fork straddles the top of the forearm.
- **Elbow actuators:** a pair of compact linear actuators in rear-side channels of the upper arm, mostly covered by armor, with short rod sections visible beside the elbow. Actuator type, endpoints, stroke, and clearance remain unresolved.

## Open design work

### Shoulder refinement

- Ball/neck dimensions, socket orientation, bearing liners, retaining-ring geometry, and assembly access.
- Shoulder movement ranges, stops, actuation, and service connections.
- Boxy pauldron dimensions, panel breakdown, and rigid removable mounts.
- Joint-gap dimensions and visible mechanism surfaces.
- Clearance between the rigid pauldron, chest, neck, and backpack through arm movement and backpack opening.
- Component inventory, part identifiers, fasteners, and assembly sequence.

### Upper-arm and elbow refinement

- Upper-arm dimensions and beam cross-section, including the integral shoulder ball/neck.
- Detachable elbow-fork attachment and clearance within the forearm connection.
- Elbow axle, bearings, retaining caps, travel limits, and mechanical stops.
- Paired actuator types, endpoints, stroke, mounting brackets, and movement clearances.
- Front/rear armor-shell boundaries, mounts, and service access.
- Connections and routing between shoulder, upper arm, and forearm.
- Component inventory, part identifiers, fasteners, and assembly sequence.
