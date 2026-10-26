# 07 — Carry loose parts resting on moving decks

Status: implemented 2026-10-26; mechanical checks recorded in the
[implementation evidence](README.md#implementation-evidence--2026-10-26).
Player recheck and detail-pass obligations below remain open. The work order is
retained as the original scope, not an instruction to repeat completed work.

## Problem and confirmed decision

A component dropped onto the lift currently blocks Up until the player picks it
up. User decision on 2026-10-26: **carry parts resting on the deck; stop for real
obstructions**. This supersedes the initial suggestion to knock parts off.
Task 05 separately makes PV-120/PV-200 securable on the shelf.

Implement this in the shared equipment/riding system, consistent with the rule
that a moving support carries what rests on it. Do not add a lift-only exemption
that ignores all loose objects in a shaft or corridor.

## Sources and implementation

Read `scripts/equipment.gd`, `equipment_registry.gd`, `work_access_lift.gd`,
`lift_shelf.gd`, `motion_sweep.gd`, `loose_part.gd` and mobile-platform motion.
The registry currently carries the player and hand load through deck transforms;
those passengers are excluded from self-obstruction checks.

1. Extend shared passenger/support detection to loose components genuinely
   resting on a moving deck. Require support contact/overlap and a stable
   relative pose; mere presence in the deck's bounding box is insufficient.
2. Move supported cargo by the same deck transform, synchronizing physics and
   preserving loose model ownership. Avoid double transforms from physics,
   parenting, player-held load handling or shelf storage.
3. Include loose deck cargo in the moving envelope for collisions with the world.
   Exclude it as an obstacle to its own supporting machine only. A long component
   hitting a landing or rail must hold the trip with a useful explanation.
4. Recompute support on pickup, drop, departure from the deck, stopping, reversing
   and changing decks. An item straddling a fixed obstruction must not be silently
   claimed and dragged through it. No pushes or impulses to clear obstacles.
5. Preserve shelf support ownership and the current save rule returning loose
   parts to drawers. Coordinate task 06 so hand pickup while riding transfers
   cleanly between loose-deck and hand-load handling.

## Acceptance and verification

- PV-120/PV-200 resting on the lift ride upward/downward without the old workaround.
  Ordinary loose parts behave the same on the mobile platform through shared code.
- A loose obstruction in the shaft/route still holds motion; removing it resumes
  the trip. Cargo protruding into the world is also checked.
- Pick up/drop during a ride, Stop, return and support loss produce no duplication,
  jitter, unexplained launch or double movement. Shelf cargo moves exactly once.
- Add isolated support/cargo fixtures to `equipment_motion_test`, and run relevant
  `access_lift_test`, `mobile_platform_test` and `centered_carry_test` cases.
- Human recheck: drop a part on the deck, press Up, pick it up while riding, then
  repeat with a genuine obstacle and verify the pause/resume explanation.

Update the shared riding rule and guarded-motion contract. The mobile-platform
lane-marking task remains separate; this work does not complete that obligation.
