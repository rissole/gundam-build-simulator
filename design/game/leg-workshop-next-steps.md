# Leg workshop: playtest state and next steps

Updated 2026-10-23. This is the current continuation note for the expanded
workshop. The [milestone record](leg-milestone.md) and
[interface specification](leg-prototype-interface.md) describe the implemented
structural subset and its historical verification.

## Current state

The structural leg, supported transfers, hip retention, removal and save/resume
are implemented. The 2026-10-22 headless run passed 38 cases / 4,539 checks. Those
results establish bounded mechanical behavior, not acceptance of the player
experience. The new parts remain procedural Godot blockouts; detailed Blender
assets, powered leg mechanisms, armor and further robot branches are deferred.

The user supplied the feedback below after an initial, incomplete playthrough.
It was explicitly deferred for a subsequent prototype iteration. The follow-up
authorized recording this state and improving skills/instructions; it did not
start the gameplay redesign.

## Player feedback to carry forward

| Item | Observation | Next-iteration concern |
| --- | --- | --- |
| Leg-area controls | A messy, overlapping cluster of 14 buttons beside the knee lift. Procedures are intricate and specific to individual parts; labels overlap and are difficult to read. The interaction is not functional or engaging. | Redesign how the player selects and understands equipment actions. Manual integration or a small computer/function-selection screen are candidate directions, not an approved design. |
| Final-bay controls | The seven buttons near final assembly have similar problems. | Apply a coherent interaction approach across both areas rather than only respacing labels. |
| Final assembly lift | Very close to what the user imagined; a positive result. | Preserve its useful spatial/access concept while addressing related controls. |
| Large-part support and transport | Leg pieces appear to float. The user cannot see or understand geometry, rails or cranes that would move them into the leg assembly area and then to the final gantry. This breaks immersion and omits an important part of the larger workshop picture. | Establish visible, understandable support at rest and throughout transfer. Equipment existing in code does not resolve this player observation. Verify staging, visibility, connection to loads and the complete route. |
| PV-120 retaining halves | They look like parts the player can pick up, but remain static on a table. | Make the handling affordance match the intended interaction and connect it clearly to the equipment workflow. |

## Recommended next iteration

1. Define one representative player journey before adding more operations:
   identify a large part, recognize its handling mode, select the work, observe
   pickup and supported transport, install it, and return or undo it. Include the
   manual's role and visible equipment state. Use a leg structural part to prove
   transport and PV-120 to check that the interaction also explains those halves.
2. Choose the interaction from that journey. Evaluate contextual/manual-linked
   actions or a function-selection terminal; avoid reproducing every internal
   controller action or part instance as a permanent world button. Resolve label
   readability, available actions and feedback together.
3. Agree the spatial contract for racks, cranes, fixtures, lifts and routes under
   one coordinated owner. Show what supports each load, what moves it and where
   the player operates it. Simplified blockout geometry should still communicate
   a continuous handling system. Preserve the successful final-lift concept.
4. Implement and check the representative loop through normal player controls
   before expanding it across the remaining parts. Check real aim/input and
   movement early so controller-only tests do not hide interaction failures.
5. Expand the proven approach, then run the affected behavior, ownership,
   movement, undo and save checks. Keep player comprehension/readability findings
   separate from automated passes. Rendered review remains explicit-request
   only; do not claim presentation approval without inspected evidence.

These are recommendations for the next implementation task, not permission to
expand into detailed leg assets, new robot branches or a particular UI design.

## Delivery lessons for the next session

The preceding goal recorded 66 minutes 26 seconds and 1,047,608 tokens. It used
three implementation agents, 12 follow-up assignments and 25 root-to-agent
messages. The final complete regression run took about 75 seconds. These are
recorded usage figures, not a monetary cost estimate.

Technical ownership was split across content/interfaces, support/equipment and
access lifts/persistence. Several support structures, routes and actual control
checks were resolved late. The primary agent is accountable for player-journey
acceptance; a capable implementation owner should handle the coupled spatial and
interaction work. Successful subsystem checks alone do not establish product
acceptance.

The bounded runtime investigation used Luna high and was a useful fit. The
content and support/runtime agents already used Sol high; the lift agent used
Sol medium while its scope expanded into persistence, controls and physical
support geometry. The primary used Astra xhigh. Stronger agents alone would not
resolve the ownership and integration problems, but the expanded lift assignment
warranted reassessing its model and effort. The user found coordination
unsatisfactory and the primary too expensive for synthesis work.

For the next task, follow the revised delegation policy in [AGENTS.md](../../AGENTS.md):
agree shared spatial and interaction constraints before parallel implementation,
assign coherent outcomes with independent decision authority and evidence-backed
handoffs, and match capacity to the full assignment. Use Sol high as a starting
point for complex implementation, with Sol xhigh or Astra high/xhigh where the
reasoning challenge warrants it. When configuring the next coordinator, start
with Sol high and keep its role focused on decisions and acceptance. Keep Luna
for bounded investigations and checks.

Evaluate this approach on one bounded implementation slice: whether the player
journey works, why assignments reopen, how much implementation returns to the
coordinator, elapsed time and available usage by role. Compare monetary costs
only when reliable cost data is available. Optimize total delivery cost including
rework and coordination; do not assume cheaper individual agents produce a
cheaper result. Review these measures after the representative loop and before
expansion. Do not create an automatic approval gate or an arbitrary budget from
this retrospective.
