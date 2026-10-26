# 01 — Engage attached transport braces deliberately

Status: implemented 2026-10-26; mechanical checks recorded in the
[implementation evidence](README.md#implementation-evidence--2026-10-26).
Player recheck and detail-pass obligations below remain open. The work order is
retained as the original scope, not an instruction to repeat completed work.

## Problem and settled design

The player sees supports appear immediately after construction steps. In
`scripts/passive_joint_restraints.gd`, `sync()` sets brace visibility and collision
directly from `shin_secured` / `fork_secured`; `capture()` is empty. This identifies
the ankle/knee braces as a concrete source of the reported behavior, not proof
that every perceived support appearance comes from this script.

User decision: attached braces, local handles, visible fold/slide motion. Both
legs need the same interaction. Braces remain equipment, not loose robot parts.
The construction milestone makes engagement available; it must not engage it.

## Sources and edit boundary

Read `final-assembly-plan.md` (leg support/transport), `leg-prototype-interface.md`,
`manual-plan.md`, and the assembly-review skill. Paths below are within
`game/workshop/`:

- `scripts/passive_joint_restraints.gd`, `indexed_leg_rail.gd`, `equipment.gd`,
  `equipment_registry.gd`, `build_stages.gd`, `scenario_staging.gd`.
- `assets/workshop-layout.json` (`restraints`), `tools/author_leg_prototype.py`,
  the mirrored robot-content generation and generated definitions/manuals.
- Shared motion/collision and save code only where this brace behavior needs it.

## Implementation work

1. Map each current brace's physical attachment, contact pair and prerequisite.
   Author a persistent stowed pose on an existing physical member. It travels
   with that member before installation and with the leg afterward; it must not
   appear on an empty logical assembly. Check source pickup and receiving poses.
2. Add real engagement state and a local handle per independently operated brace
   group. Reuse the equipment/manual control contracts. A mirrored pair may use
   one handle only if the geometry visibly explains the linked operation.
3. Move from parked to engaged geometry through a short controlled fold/slide.
   Use the same pose for collision and rendering; respect obstructions and stop
   safely. Record actual stowed and swept envelopes before changing any route.
4. Add explicit self-ticking manual objectives when each receiving connection is
   retained, before its next movement requiring restraint. Use machine labels
   shared with prompts. Expose the relevant handle identity for task 08.
5. Require the appropriate braces for loaded roll, indexing, parking and delivery,
   including unfinished-leg parking where relevant. Keep empty-rig return valid.
   Audit crane release, bolster handoff and leg-rig release: never leave an
   unpowered joint unsupported between construction and transport. Do not add
   a blanket gate before a prerequisite component can physically be delivered.
6. Provide safe local disengagement for correction only when the stationary rig
   or another defined support carries the joint. Block undo of brace attachments
   while engaged. The rig leaving the mounted leg must not remove these braces.
7. Save and restore engaged/stowed states through the existing at-rest snapshot
   contract. Stage preparation executes the same objectives and produces coherent
   supplied states. Do not infer engagement from construction completion on load
   or add save migrations.

## Acceptance and verification

- Completing shin/fork retention leaves the applicable brace visibly parked.
  Operating its handle engages it, updates the checklist and permits the next
  supported movement. Partial/moving engagement does not count as locked.
- Both mirrored legs work; commands, return and supported correction preserve
  physical identities and continuous support. Empty equipment remains usable.
- Engagement state survives save/load, stage boundaries and mounted parenting.
  Brace geometry and physics follow intermediate leg rotations, not just stops.
- Add an isolated brace suite to `test_inventory.py`; run it with relevant
  `manual_objectives_test`, `manual_progress_test`, `leg_content_test`,
  `robot_content_test`, `rail_endpoint_test`, `stage_contract_test`,
  `save_roundtrip_test` and one startup smoke as affected. Extend fixture coverage
  for interlocks rather than automatically running the expensive rail diagnostic.
- Human recheck: notice parked braces, find each handle, engage before moving,
  transport/dock the left leg, confirm the braces remain after rig release.

## Documentation and detail pass

Update the leg support contract and interface notes to replace automatic
engagement with explicit operations. Keep final hinge/slide construction,
materials and detailed manufacture for component detailing. Prototype stow and
motion geometry must already be credible and fit the measured envelope.
