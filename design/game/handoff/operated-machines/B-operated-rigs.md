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
- **Manual curve** (B owns the first-use/repeat mechanism; see phase 2): the left leg/foot gets one
  objective per axis with exact keys; the right leg/foot gets one goal plus a
  procedure link. `manual_state()` reports axis-in-tolerance/seated evidence instead
  of stop numbers.

## Done (phase 1)

`2fe447e` B1 hold-E latch with mouselook (`held_control_test`), `559c938` B2 ghost
target and axis readout (`rig_target.gd`, `rig_target_test`), `0ac87c0` B3 design
in `design/game/robot-workshop-plan.md`, with its open questions in the checklist.

## Phase 2 — leg rig (now)

**Lesson from the rejected crane view:** it failed partly because holding Space ran
every interesting motion. Do not add a hold-to-run sequence or an auto-align. The
player drives each axis, and the SEAT lead-in only covers the last few centimetres.

The crane operator view (branch A) was **rejected and will not merge**. Nothing in
B waits for it any more, and B now owns the shared manual mechanism.

1. **Rebase** `operated-rigs` onto `main`. Resolve the checklist conflict by keeping
   main's machine-operation section and adding B's open-questions section after it.
   Remove every reference to branch A, checkpoint A or "A's mechanism" from B's
   design text.
2. **Manual first-use/repeat mechanism.** Detailed objectives the first time a
   procedure is used; later pages give the goal plus a working "Procedure: p.N"
   link. Implement it in `manual_objectives.gd`, `manual_progress.gd`,
   `manual_browser.gd`, `hud.gd` and `tools/author_manual_progress.py`. You may read
   the rejected crane branch's version (`git show 45fc7f3`) and port the generic
   mechanism only. Do not port its crane pages, its `robot-definitions.json` crane
   changes or anything in `service_crane*.gd`. Extend `manual_objectives_test` and
   `manual_progress_test`.
3. **B3 Leg rig axes.** Implement the B3 design in `indexed_leg_rail.gd`:
   - jog pairs held with E (B1) and the ghost plus readout (B2)
   - per-axis limits and interlocks with named refusals
   - SEAT within tolerance after the guided lead-in
   - `manual_state()` evidence and the new save fields (no migration).

   Use the design's proposed defaults for its open questions: one constant jog rate
   per axis; service taps with fully jogged delivery axes; the panel grouping as
   designed. Record each default in the checklist as awaiting playtest.
4. **Write the Grok task file `B4-leg-manual-and-tests.md`** in this folder:
   - left-leg pages with one objective per axis; right-leg pages with goal plus
     procedure link
   - the automation helper that drives the axes for `build_stages.gd`
   - the tests listed under "Later verification" in the B3 design.

   Stop there. The parent launches Grok, then runs your integration review.

## Later phases

- **B4 integration review**, then the player playtests the leg rig slice
  (checkpoint B).
- After checkpoint B: **B5** converts the foot rig (Raise, Travel, Turn, SEAT), and
  Grok task **B6** handles its manual and tests.
