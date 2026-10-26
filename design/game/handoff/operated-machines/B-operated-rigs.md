# B — Operated rigs (coordinator brief)

Branch `operated-rigs`, worktree `/private/tmp/gbs-rigs`. Coordinator: Astra High.
Read the [README](README.md) shared rules first.

## Player problem

The foot rig (`foot_carrier.gd`: dispatch → raise → travel → turn/seat) and the leg
rig (`indexed_leg_rail.gd`: `next_action()` walks bolster → index → travel →
upright → dock → release) are each one scalar `path` along authored stops, with a
NEXT button. The player presses Next until the job is done. The foot *building*
bay feels right because its equipment assists the player rather than replacing them.

## Target experience (user-decided)

Principle: **the rig moves along its real joints, the player drives each joint, the
game shows where it must end up, and the interlocks are the puzzle.**

- **Jog buttons on the existing panel** replace NEXT: paired arrows per axis.
  **Holding E on a button jogs that axis; mouselook stays free while E is held**
  (the press latches to that button until E is released). The player can then look
  up at the hip while driving. The game will be AR, so it is fine that the target
  only needs to be in sight via mouselook. Keep panel positions (`spec.panels`)
  where the target is visible.
- **Ghost target:** a pulsing translucent copy of the carried assembly at the next
  target pose (reuse `manual_control_glow.gdshader`), plus per-axis readouts on the
  panel sign (e.g. "INDEX +0.32  RISE −0.41"), each turning green in tolerance.
- **SEAT commits:** `install_supported` runs only on SEAT within tolerance, after a
  short guided lead-in over the last few cm (guide pins). Satisfying, not fiddly.
- **Interlocks replace step order**, with named panel refusals instead of failure
  states. Examples: tilt only clear of the transverse table; rise only when upright
  under the hip; travel only with `rail_gates` closed. Existing guarded motion still
  stops on contact.
- **Manual curve** (uses A's first-use/repeat mechanism): the left leg/foot gets one
  objective per axis with exact keys; the right leg/foot gets one goal plus a
  procedure link. `manual_state()` reports axis-in-tolerance/seated evidence instead
  of stop numbers.

## Phase 1 — this run (before A merges): B1 and B2 only

Do not edit `manual_objectives.gd`, `manual_progress.gd`, `manual-chapters.json`
or the crane files in this phase.

1. **B1 Hold-E latch + mouselook.** In `desktop_input.gd`, `targeting.gd` and
   `equipment_button.gd`, add a generic "held control" path. Pressing E on a
   control that declares itself holdable latches that control, then reports
   held/released each physics frame while E is down. Aiming away does not release
   it; mouselook continues. Releasing E, pausing or opening a modal releases it.
   Existing tap controls behave exactly as before. Add an isolated test.
2. **B2 Ghost target + axis readout helper.** Add a reusable script: given an
   assembly id and a target `Transform3D`, show a pulsing translucent copy, and
   given axis deltas/tolerances, format a panel readout and report "all in
   tolerance". It must be cheap: build the copy once, move it, and hide it when idle.
   It must not add collision or targeting. Add an isolated test.
3. **Design B3 in writing** (no rig code yet): add a section to
   `design/game/robot-workshop-plan.md` defining each leg rig axis (range, speed,
   jog keys), the target poses, tolerances, interlocks with refusal text, the SEAT
   lead-in and the save fields. Base it on the existing `snapshot_pose`, `spec`
   values and `action_error` rules. Do the same briefly for the foot rig. List open
   questions for the user.

Stop after 1–3 and report.

## Later phases (gated)

- After A merges and **human checkpoint A**: rebase on `main`, then **B3** implements
  the leg rig axes. Write the Grok task file **B4** (leg manual pages through A's
  mechanism, automation helper for `build_stages.gd`, tests: limits, interlocks,
  SEAT gating, ghost pose == install pose, save round-trip).
- After **human checkpoint B**: **B5** converts the foot rig (Raise, Travel, Turn,
  SEAT). Grok task **B6** handles its manual and tests.
