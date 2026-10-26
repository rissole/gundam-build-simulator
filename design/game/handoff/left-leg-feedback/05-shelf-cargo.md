# 05 — Secure PV-120 and PV-200 on lift shelves

Status: implemented 2026-10-26; mechanical checks recorded in the
[implementation evidence](README.md#implementation-evidence--2026-10-26).
Player recheck and detail-pass obligations below remain open. The work order is
retained as the original scope, not an instruction to repeat completed work.

## Problem and settled behavior

The player cannot store these two-hand components on the shelf and resorts to
dropping them on the lift. Each must have a deliberate supported storage pose.
Capacity remains two one-hand parts or one two-hand part. Loose deck riding is
task 07; it does not substitute for a secure shelf operation.

`lift_shelf.gd::capacity_error()` compares source mesh AABB axes with an upright
panel capacity; `_pose()` uses an identity basis. A valid stow orientation may
therefore be rejected. This is a lead to verify, not a completed diagnosis.

## Sources and implementation

Read `scripts/lift_shelf.gd`, `work_access_lift.gd`, `solid_handling.gd`,
`equipment_registry.gd`, model supported-item methods, both part generators,
`assets/workshop-layout.json` shelf geometry, and the shared spatial contract.

1. Measure both parts' transformed visual/collision bounds and current shelf
   fit. Inspect support permissions, capacity, place-target access and transfer
   sweep separately so the fix addresses the actual rejection.
2. Add data-driven shelf stow orientation/placement using the existing handling
   metadata pattern. Validate bounds in that same orientation. Keep shelf logic
   generic; do not hardcode PV IDs as exemptions.
3. Author a visibly supported pose and any small captive shelf restraint needed
   for credible secure storage. If geometry must change, measure both lifts'
   landing, hip-work and cargo travel clearances before changing the spatial
   contract. Do not enlarge capacity numbers around unsupported overhangs.
4. Store through the existing click operation and retrieve with E, retaining the
   exact UID. Use task 04's surface targeting for retrieval. Clear occupied/full
   and obstruction feedback must distinguish capacity from path problems.
5. Include secured cargo in the moving load envelope; it must not obstruct its
   own shelf/lift. Keep external collision checks, support ownership and current
   save/reset semantics consistent. Coordinate with task 07 to avoid treating
   shelf-owned parts as loose deck riders.

## Acceptance and verification

- Either PV-120 half and every PV-200 copy can be stored, carried to a work level,
  retrieved and fitted using both lifts. Swapped identical copies behave alike.
- One two-hand part consumes the full shelf; two one-hand parts remain supported.
  Full shelves reject further cargo without dropping or duplicating it.
- Fit uses transformed geometry. Shelf and cargo clear each other while genuine
  external obstacles still hold the trip and clearing them allows it to resume.
- Ownership remains coherent across store/take, undo-returned hardware and
  existing save/load behavior. Do not expand save persistence for loose stock.
- Add an isolated shelf fixture if needed; classify it in the test inventory.
  Run it with relevant `supported_model_test`, `access_lift_test`,
  `equipment_motion_test`, `save_roundtrip_test` and content/source checks.
- Human recheck: carry, store, ride, retrieve and install each part without the
  drop/press-Up/pick-up workaround.

Detail pass: document supported cargo orientations and physical shelf contacts
for future components rather than increasing a universal size allowance.
