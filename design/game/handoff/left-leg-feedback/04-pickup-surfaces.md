# 04 — Pick up parts by aiming at their visible surfaces

Status: implemented 2026-10-26; mechanical checks recorded in the
[implementation evidence](README.md#implementation-evidence--2026-10-26).
Player recheck and detail-pass obligations below remain open. The work order is
retained as the original scope, not an instruction to repeat completed work.

## Problem and scope

PV-120 and PV-200 are difficult to collect: aiming at empty space can work better
than aiming at the visible component. `targeting.gd` currently gives loose items
a small aim radius around their body origin. Shelf pickup uses mesh AABB centres.
Neither point is guaranteed to lie on visible material.

Fix pickup targeting generically for loose and supported hand-carried parts.
Task 09 separately owns installation-slot discovery and line-of-sight leniency.

## Sources and implementation

- `scripts/targeting.gd`, `component_interaction.gd`, `lift_shelf.gd`,
  `interaction_outline.gd`, `solid_handling.gd`, `leg_source_geometry.gd`.
- `tools/author_leg_prototype.py` (PV-120), `author_hip_interfaces.py` (PV-200),
  and `tests/targeting_candidates_test.gd`, `interaction_outline_test.gd`.

1. Reproduce aiming at visible edges, body and gaps using actual source geometry,
   both mirrored/source variants and representative dropped rotations. Identify
   whether origin choice, collision proxies or occlusion causes each failure.
2. Prefer a ray hit on the candidate's visible geometry or a faithful shape
   representation. Use the actual surface hit for reach and occlusion, with a
   modest shared aim tolerance. A large centre sphere alone does not solve a
   hollow ring's misleading interaction region.
3. Support pickup from loose state and shelf state using the same rule. If
   coarse collision fills a hole, supply a suitable shared surface query or
   correct the authored compound. Bound/cache queries so detailed meshes do not
   add a full triangle scan every frame.
4. Keep target priority stable near neighbouring objects and installed
   connections. Outline and pickup must refer to the same physical item.
   Preserve the existing keys, hand occupancy, ownership and collection flow.
5. Provide the reusable pickup behavior to task 05; coordinate `targeting.gd`
   ownership with task 09. Do not broadly change installation reach here.

## Acceptance and verification

- Aiming at PV-120's solid arc or PV-200's body selects and picks up that item.
  Aiming through a real empty gap can select a visible object behind it.
- Walls and intervening unrelated objects block pickup; proximity to another
  part does not steal its target. Reach is measured to the relevant surface.
- Off-origin meshes, rotated loose parts, shelf cargo and ordinary compact
  components all use a consistent rule without ID-specific runtime exceptions.
- Add isolated aim/ray fixtures to the routine targeting/outline suites. Test the
  actual selection-to-input path in a small fixture, not only direct collection.
  Do not run whole-workshop visibility sweeps or rendered review.
- Human recheck: drop/rotate both parts, collect by aiming at their material,
  and repeat after task 05 enables storage on each shelf.

Detail pass: author faithful pickup surfaces and collision compounds for new
hollow/elongated parts; do not rely on an invisible origin target.
