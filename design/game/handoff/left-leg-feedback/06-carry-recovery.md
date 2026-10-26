# 06 — Recover stuck held objects without losing them

Status: implemented 2026-10-26; mechanical checks recorded in the
[implementation evidence](README.md#implementation-evidence--2026-10-26).
Player recheck and detail-pass obligations below remain open. The work order is
retained as the original scope, not an instruction to repeat completed work.

## Problem and behavior

The player reports losing a carried part after it catches on world geometry.
They request that excessive separation return it to their hands. Implement a
bounded carry-recovery rule for ordinary parts and hand-carried assemblies.

Normal carrying remains solid. If the actual grip becomes excessively separated
from the desired grip, recover to a clear pose near the hands while retaining
ownership. Recovery may bypass the snagged translation path; final placement
still requires ordinary reach, access, prerequisites and an unobstructed approach.

## Sources and implementation

- `scripts/loose_part.gd` (`WorkshopPart.update_grip`),
  `workshop.gd::apply_carry_intent`, `component_interaction.gd`,
  `solid_handling.gd`, `hand_slot.gd`, `targeting.gd` and shared rider motion.
- `tests/centered_carry_test.gd`, `nested_runtime_test.gd` and existing item/assembly
  ownership tests. The current grip loop sweeps motion but contains no obvious
  explicit distance-based drop; trace the reported loss before claiming its cause.

1. Reproduce catch/separation and follow ownership, body freeze/held state,
   clipping, world rescue and drop paths. Cover both loose components and nested
   carried assemblies. Distinguish a stuck visual from a real ownership loss.
2. Measure separation using the intended grip/geometry rather than an arbitrary
   source origin. Choose a named distance threshold with size-aware handling and
   hysteresis so normal pickup approach, turning and riding do not repeatedly snap.
3. When recovery is needed, first try the intended hand pose, then a bounded set
   of nearby clear poses. Query destination overlap against scenery. Do not
   teleport into walls, floor, machinery or another part. If no pose is clear,
   retain the hand item and explain that the player must move into clear space;
   recover as soon as a valid pose becomes available.
4. Move the existing body and all mounted children coherently, synchronize
   physics, reset stale velocity and retain the exact UID/held ownership. Do not
   spawn a replacement or implicitly drop/return it to a drawer.
5. Explicit drop, store and installation remain the only normal release actions.
   Exclude crane magnetic connectors and equipment-only loads unless their own
   contract explicitly supports this behavior. Share this mechanism between
   ordinary parts and carried assemblies, not per component.

## Acceptance and verification

- A caught part exceeding the threshold recovers to a clear hand pose without
  losing inventory. Normal unblocked carrying does not snap or jitter.
- No clear pose: ownership persists and recovery waits. When clear, the same
  physical item returns. Explicit drop still works and does not trigger recovery.
- Off-origin geometry, PV-120/PV-200, mounted child assemblies, rotation between
  physics ticks, pause/resume and moving-platform riding preserve coherent poses.
- Recovery does not enable fastening through a wall or outside normal reach.
- Extend `centered_carry_test` and `nested_runtime_test` with isolated snag,
  recovery, blocked-destination and ownership cases. Use relevant
  `equipment_motion_test` and model checks only where changed.
- Human recheck: snag both reported parts against scenery, walk clear, recover
  them, then deliberately drop and re-collect.

Detail pass: retain comfortable grip centres and faithful collision profiles.
Recovery is a shared usability rule, not a replacement for fixing malformed shapes.
