# Shared guarded equipment motion — 2026-10-25

Implemented the “one shared version of this logic” follow-up from the elevator
conversation. Current work remains in the
[workshop state](../workshop-state.md). Player findings are in the
[playtest checklist](../robot-workshop-playtest-checklist.md).

## Implementation

`EquipmentRegistry.Motion` exposes `scripts/equipment_motion.gd`. It owns the
0.25 m look-ahead (at least the actual physics step), route-distance conversion,
obstacle-category masks, collider classification and player-facing obstruction
messages. Physics broadphase queries find nearby bodies; the policy does not
scan the workshop's inventory. `MotionSweep` remains the reusable low-level
query layer for equipment and ordinary carrying. Its continuous casts now retain
the identity of thin obstacles between samples and support articulated world-pose
shapes as well as shapes in a rigid frame.

Elevator clearance, shelf cargo, mobile platform travel/height, loaded crane/rig
and rail holder/load checks use the policy. Each controller retains its real
geometry, supported ownership and intentional mating exclusions. Crane receiver
contact exclusions are evaluated at each sampled pose so a look-ahead starting
outside the mating zone can enter permitted contact without deadlocking. Rail
load and rig samples follow the same articulated poses, and withdrawal/path
reservations stop at contact-phase boundaries.

The mobile platform and rail retain their destination while obstructed and retry
on subsequent physics ticks. Elevator and loaded crane waiting behavior uses the
same policy. Manual Stop remains stopped until an explicit request. A waiting
platform/rail can return, and a waiting source-to-receiver crane transport can
reverse its exact route without changing its physical pose or load ownership.
Crane vertical lifting/lowering keeps its support-transfer interlocks; this change
does not introduce arbitrary vertical reversal or retarget an empty crane's
cross-task pickup travel.

The registry exposes a waiting loose obstacle to the existing pickup outline.
Aimed pickups keep their own contour; otherwise the obstacle remains indicated
without requiring aim. Pausing, stopping, clearance and freed bodies clear the
relevant focus. Messages distinguish a person, loose part and hand load. Elevator
doorway tolerance remains 0.2 m, with its specific step-back message and existing
arrival nudge.

## Preserved constraints and remaining work

- Fixed structure remains in short runtime queries. Structure and moving
  equipment currently share layer 1; there is no proof that would justify
  disabling fixed-geometry checks. Parts, assemblies and player use their
  existing separate masks. This change does not relayer the workshop.
- Support/retention rules, crossing-corridor occupancy, crossing gates and access
  interlocks remain separate from swept-path obstruction policy. A rail request
  waiting for crossing/access clearance stays pending and retries.
- The mobile platform still requires a lowered deck clear of loose loads for
  ground travel. Rider and hand-load exclusion/carry remain shared. Automatic
  carriage of arbitrary loose parts was not added.
- The user's required **visible floor lane remains outstanding**. Parts are
  pointed at, never pushed. No layout or route authoring changed here.
- Empty crane travel and other fixtures' independent mechanism controls were
  not expanded into a new collision model. This integrates the existing checks
  of the five requested equipment types rather than redesigning every machine.
- No manual pages, parts, recipes, source geometry or mounting interfaces changed.
  Impact review therefore focused on equipment motion, support ownership, shared
  carrying, intentional contacts and interaction feedback.

## Evidence

`python3 game/workshop/tools/run_regressions.py` passed all **29 routine cases**
in **9.353 seconds**, with unchanged input hashes and no 60-second warning.
This includes 32 new isolated shared-motion assertions, 132 platform assertions,
45 access-lift assertions, 93 wide-elevator assertions, crane policy, support and
receiver contracts, nested runtime/carrying, outline behavior and real startup.

Local report directory:
`game/workshop/verification/regressions-20261025T002535.625359Z/`.
The earlier lift failures were assertions tied to superseded messages; they now
check collider identity and category without weakening movement/clearance checks.
A new platform blocker fixture was corrected to intersect the moving deck rather
than float above it; its collision and Stop/return assertions now pass.

This is mechanical evidence only. No named expensive diagnostic, walked journey,
rendered review or human playtest ran. Full authored load journeys remain named
diagnostics; user feedback is still needed on waiting/resuming, return controls,
message readability, outline visibility and the elevator nudge. Existing positive
feedback on elevator scale and rail handling remains a constraint.
