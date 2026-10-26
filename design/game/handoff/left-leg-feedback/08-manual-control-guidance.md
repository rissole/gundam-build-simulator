# 08 — Guide the current manual's local control action

Status: implemented 2026-10-26; mechanical checks recorded in the
[implementation evidence](README.md#implementation-evidence--2026-10-26).
Player recheck and detail-pass obligations below remain open. The work order is
retained as the original scope, not an instruction to repeat completed work.

## Problem and confirmed scope

The player could not locate the hip-cylinder lock pin, even knowing the game.
Requested note: “After fitting both end pins, aim at the small gold handle near
the cylinder’s lower end”. They approved **note plus glow for all tasks of this
class**, not just this one cylinder. They also report another agent may already
have fixed the note: inspect current work before changing it.

Apply a reusable cue to the physical control(s) for the current actionable manual
objective: lock pins, brace handles, jaws and comparable local operations across
machines. Use a subtle unobstructed glow; no through-wall marker or new waypoint
system. Do not glow every future control or every robot part simultaneously.

## Sources and implementation

- `scripts/manual_objectives.gd`, `manual_progress.gd`, `captive_controls.gd`,
  `equipment.gd`, `equipment_registry.gd`, `module_supports.gd`,
  `interaction_outline.gd`, machine controls, and task 01 brace controls.
- `tools/author_hip_interfaces.py`, generated manuals and `manual-plan.md`.
  At inspection, the generator note says “beside the middle”; control positions
  use cylinder-local coordinates. Verify actual geometry and recent changes
  before claiming the player's proposed lower-end wording matches every cylinder.

1. Audit the note on all three cylinders and the mirrored leg. If already fixed,
   preserve the change and report it as existing work. Otherwise ensure the note
   explicitly follows fitting both end pins and describes the actual handle's
   position/color. Keep one source of truth in the generator.
2. Add a generic objective-to-control reference through machine metadata. Reuse
   typed manual objectives and existing control IDs; do not parse English text or
   build a list of cylinder-specific IDs in the renderer.
3. Enumerate current applicable manual operations across machines. For a grouped
   objective highlight its remaining eligible controls; for a console operation
   cue the relevant access/control if it has a physical target. Record any case
   that cannot resolve a control rather than silently supporting only cylinders.
4. Resolve from the tracked step's current actionable objective. Update on state
   changes, manual tracking, undo, stage preparation and load. Fade/clear cues when
   completed, unavailable or superseded. Manual-panel hiding should not change
   the tracked objective or disable an otherwise useful world cue.
5. Keep cue visibility bounded by nearby unobstructed view. Preserve meaningful
   aim outlines and obstruction feedback; guidance does not grant reach or bypass
   lock prerequisites. Share visibility/outline machinery and avoid per-frame
   scans of every manual step or material allocations.

## Acceptance and verification

- Fitting both pins leads naturally to the relevant cylinder handle, without
  highlighting an already locked or other cylinder's handle. Undo restores cues.
- The same behavior works for task 01 braces and other applicable manual-directed
  local controls, including grouped jaws and mirrored builds.
- Switching tracked steps, reloading, pausing and hiding the manual leave no stale
  glows. Fully occluded controls do not shine through world geometry.
- Add isolated objective/control resolution and cue lifecycle tests. Run relevant
  `manual_objectives_test`, `manual_progress_test`, `manual_panel_test`,
  `interaction_outline_test` and startup smoke. These do not establish readability.
- Human recheck: find an unfamiliar cylinder lock and another machine's control
  from its manual step; assess whether the glow is helpful and restrained.

Update `manual-plan.md` with this bounded physical-control guidance exception to
its earlier deferred waypoint scope. Final handle shapes, markings and detailed
mechanisms remain detail-pass work, with obvious controls as a design requirement.
