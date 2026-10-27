# A1 — Layout, lifts, walkways, access modes (coordinator brief)

Branch `gv2/layout`, worktree `/private/tmp/gv2-layout`. Coordinator: Astra High.
Read the [README](README.md) first, including the `rope_stations` contract.

## Goal

Replace the gantry's upper access levels (11.2, 14, 16.4) with the rope-access
structure, move both lifts, and keep the 8.4 m level. World metres, Y up, +Z toward
the exit door, robot centred X13/Z26, hip datum (13,10.6,26). Source of truth for
geometry: `game/workshop/tools/author_workshop_blockout.py` → regenerate
`game/workshop/assets/workshop-layout.json`. Runtime: `workshop_access.gd`,
`work_access_lift.gd`, `leg_bay_layout.gd`, `gantry_dressing.gd`, `hangar_dressing.gd`.

## Required geometry

1. **Remove** every 11.2/14/16.4 element (wings, fingers incl. the 11.2 middle
   finger, outer walkways, hinge aprons, guards, gates, landing fills, lift stops)
   and the 8.4 **rear crossover** (`rear_crossover_8.4_*`, Z36.55). Keep the rest of
   8.4: outer walkways, hinge aprons, front swing wings + fingers, hip aprons, rear
   outer/inner hip decks, gates. Keep the low rear hip frame (columns, crosshead,
   cantilevers, bearing caps, jaws) unchanged.
2. **Workshop-side upper leaves (level 20.6):** two `wing` joint groups
   `wing_left_20.6` at (5,20.6,24) yaw 0 and `wing_right_20.6` at (21,20.6,24) yaw 180,
   same length (8), width (1.2) and swing as the 8.4 wings, split at X13, **no
   fingers**. Deck depth 0.2 (top 20.6). Guards 1.1 m on both long edges; the
   robot-side (world +Z when closed) guard has 0.9 m gate openings centred on each
   front rope station (see contract), each with a short fixed davit carrying its
   anchor. Each leaf is a cantilever from its axle: add a short mast and tie that
   stay below Y22.4. Nothing may reach Y≥22.5 anywhere under the crane runway span:
   the crane bridge (underside about Y22.65) travels the whole hall.
3. **Shared hinge posts:** one vertical post per side at the wing axle (X5/X21, Z24),
   floor to Y22.3, section ≤0.3. Both the 8.4 wing and the 20.6 leaf turn on it;
   notch the decks so nothing collides with the post through the full swing.
4. **Hinge aprons at 20.6:** X3.5..5 and X21..22.5, Z23.4..24.7, guarded on their
   outer edges, like the 8.4 ones. The left apron is the left lift's 20.6 landing.
5. **Exit-side fixed walkway (20.6):** deck X5..18, Z30.3..31.7, guards both long
   edges, 0.9 m gate openings in the robot-side (Z30.3) guard at each rear station,
   west end closed. Fixed **booms** from the edge to each rear anchor
   (X11.0/12.4/13.6/15.0, Z30.3→28.3, Y21.8, section ≤0.15). Supported on posts from
   the floor (west end near X4.8 clear of the 8.4 left outer walkway; east end on the
   right lift structure ≤Y20.2) — **no roof hangers**. Give the lift door a 1.5 m
   landing at the east end.
6. **Lifts:** keep car 2.6, shaft 3.2, shelves, riders, nudge, calls and no landing
   gates. Stops become **0.15, 8.4, 20.6**. Left centre **(1.9, 24.05)**: doors onto
   the hinge apron at 8.4 and 20.6 (east face X3.5). Right centre **(19.6, 31.0)**:
   8.4 door east onto the right outer walkway (bridge the 0.2 m gap with a flush
   plate), 20.6 door west onto the exit walkway landing; ground door your choice,
   kept clear of the leg rail gates and mobile-platform routes. Shaft guides/structure
   end at Y20.2; the car is **open-topped** (no roof) so the crane bridge can pass
   over a car at the top stop. Retire the old shafts at X6.6/19.4, Z29 and their
   landing fills. If `work_access_lift.gd` assumes one door side for all stops, make
   door side per stop, data-driven.
7. **Access modes** (`spec.access`): `levels` = [8.4, 20.6]. 20.6 open for every crane
   delivery that crosses the front: `pelvis:[20.6]`, `chest:[20.6]`, `arm:[8.4,20.6]`,
   `head:[20.6]`, `leg:[8.4]`, `work:[]`, `rear:[]`; add `core:[20.6]` and
   `backpack:[20.6]` if those crane tasks will need them (A3 wires them). Remove the
   11.2-finger special case and `arm_services_stowed` if they exist only for 11.2;
   otherwise keep and say why. Access snapshot keys may change (old saves are invalid
   and deleted — no migration).
8. **`rope_stations`**: author exactly the README contract under `workshop`.
9. **Dressing:** keep the accepted gantry finish on all retained and new members;
   the level signs become 8.4 `HIP` and 20.6 `ROPE ACCESS`. Visuals and collision agree.
10. **Coarse clearance:** with leaves open (swung 90° toward −Z) they occupy
    X4.4..5.6/20.4..21.6, Z16..24; check against crane console (7.8,0,22.8),
    leg rail gates (X8.4/17.6, Z20.5), mobile-platform park/routes and the bulky bay.
    Closed leaves must not hit the robot's grown boxes (head top ≈19.41+0.75).

## Tests

Update the routine suites this touches (likely `access_lift_test`,
`wide_elevators_test`, `gantry_dressing_test`, `equipment_motion_test`,
`rail_endpoint_test`, `save_roundtrip_test`, `workshop_smoke_test`) and any diagnostic
suites whose fixtures reference removed levels — edit diagnostics only to keep them
loadable; don't run them. Add coverage for: lift stops/doors at the new positions,
leaf swing on the shared axles at both levels, exit walkway + booms present, no
geometry above Y22.4 under the runway, `rope_stations` resolve to the listed world
anchors with leaves closed. Mechanical test-expectation edits are good Grok tasks.

## Stop conditions

Stop and report (don't improvise) if: a lift stop can't get a 1.5 m landing without
moving another accepted station; the hinge posts can't share the 8.4 axle without
changing accepted 8.4 behaviour; or a retained test proves an accepted interaction
breaks.
