# Forearm and wrist

Last updated: 2026-10-24

[Design index](../../ROBOT_DESIGN.md) · [Shared design rules](../global.md)

The right arm will mirror this design.

Connected assemblies and clearance checks: [upper arm and elbow](shoulder-and-upper-arm.md), [hand](hand.md).

Dimensions and reference pose: [shared proportion layout](../proportions.md#arms-and-hands).

## Confirmed design

### Forearm and wrist

- **Forearm silhouette:** an angular gauntlet slightly fuller than the upper arm, tapering toward the wrist.
- **Frame and armor:** a central structural beam with a removable internal service tray, a substantial outer armor shell, and a separate inner service cover. Detailed tray contents and attachment geometry remain open.
- **Wrist joint and hand connection:** a smaller ball-and-socket joint, with the ball and wrist stem integral to the palm chassis and the socket in the forearm cuff. A bolted two-piece retaining collar captures the ball; detailed geometry, liners, and other hardware remain open.
- **Wrist movement and appearance:** forward/backward flexion, sideways tilt, and limited twist through the ball joint, with a short angular cuff and a narrow gap exposing part of the wrist stem. Exact travel limits, stops, actuation, and service routing remain open.

## Selected shared-arm transport boundary

The [shoulder/interface design](shoulder-and-upper-arm.md#shared-long-limb-preparation-and-supported-upending)
prepares upper arm, forearm and hand together at the shared long-limb fixture.
Preserve the 2.60 m elbow-to-wrist span and 1.10 × 1.10 maximum forearm
cross-section. Elbow and wrist remain straight/neutral on removable structural
bridge restraints during source pickup, continuously guided upending and crane
delivery. The hand's complete thumb/digit bounds are included in that contract.

Reserve forearm structural fixture contact near shoulder station t4.05 and a
front/rear lifting-pad pair at `C+4.40u+0.10e±0.68f`, using the shoulder
sheet's axes. These are beam hardpoints exposed through small armor access
ports, not supports on the service tray, cuff, wrist collar or actuator rods.
The same shared fixture/crane handles either arm; no forearm-specific powered
station is selected. Distal rigging releases from the 11.2 m world deck with
front/rear worker eyes near robot `(±2.95,±1.70,11.43)`, approximately 1.69 m
from the actual pad targets. The shoulder sheet owns the supported delivery,
receiver handoff, local correction and later ordinary-input/solid review plan.

This interface reservation does not select new elbow/wrist mechanisms or a
complete forearm inventory. Check the pad/support load path and service-cover
removal with actual source solids when detailing this component.

## Open design work

### Forearm and wrist refinement

- Forearm dimensions, structural-beam geometry, and interface with the elbow.
- Service-tray contents, mounts, removal access, and connections.
- Outer armor-shell and inner service-cover geometry and fasteners.
- Wrist ball, stem, socket, liners, retaining-collar geometry, and installation access.
- Wrist actuation, movement ranges, mechanical stops, and service routing across the joint.
- Cuff clearances and visible joint-gap dimensions.
- Component inventory, part identifiers, fasteners, and assembly sequence.
