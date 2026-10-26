# A — Crane operator view (coordinator brief)

Branch `crane-operator-view`, worktree `/private/tmp/gbs-crane`. Coordinator:
Astra High. Read the [README](README.md) shared rules first.

## Player problem

The crane console (`game/workshop/scripts/service_crane_console.gd`) is a menu:
**Move to pickup**, **Move to delivery**, **Put back**. The player makes no spatial
decisions, so the most-used machine in the workshop feels like a sequence of button
presses.

## Target experience (user-decided)

- At the existing crane console, the player **enters a top-down CCTV view** from the
  trolley. Esc/Q leaves. Reuse the `desktop_input.push_modal/pop_modal` pattern
  the console already uses.
- **WASD strafes** the bridge/trolley along the roof at a fixed safe carry height.
  Shift gives fine speed. The view shows a reticle, a drop line and load status.
- Valid targets glow, using the same gold glow language as the manual control cues.
  With an empty crane, the target is the next load in `crane.order`. With a load, it
  is the delivery seat, or the source seat for Put back.
- **Click/Space descends only while the reticle is inside the target's capture
  radius.** Otherwise descend is disabled and the HUD says why ("Not over the hip
  assembly lifting eyes"). Descend snaps to the target XY, then plays the authored
  final approach.
- On a descend over a confirmed load, the **spreader reshapes** from a neutral stowed
  form into that task's rigging (bar length, cable count/positions from the existing
  per-task contract: `_configure_task`, `END_IDS`, `rig_center`, cable endpoints).
  This is a short visible animation.
- **Connectors stay hand-attached.** The view exits after the descent, and the
  player walks over and attaches the magnetic connectors as today. Lift is enabled
  in the view once the required ends are attached. Auto-attach from the crane is a
  **later power-up**: record it as deferred and do not build it.
- Horizontal travel keeps guarded motion (`EquipmentRegistry.Motion`, existing
  `motion_error`). It pauses short of the gantry or robot and names the obstruction,
  so free roaming can never clip.

## Phase 1 — this run

1. **A1 Route and carry-height audit (first; stop condition).** Measure every crane
   task's current route/via points against one fixed carry height that clears the
   gantry 16.4 deck plus its guards, the robot at every stage, and the cable/rigging
   envelopes (`final-assembly-plan.md` "Check the full rigging envelope first";
   pauldrons route via front distribution Z13 at lowest load Y18). Output: the
   carry height, each task's final-approach pose, and any task that still needs a
   via point or an authored approach longer than vertical. Record it in
   `design/game/final-assembly-plan.md` under a new dated section. **If no single
   carry height works and the exceptions are not small, commit the audit and stop
   with a report.** Do not invent a workaround.
2. **A2 Free XY travel** in `service_crane.gd` (station-to-station →
   bridge/trolley XY at carry height; authored approach after descend; save/apply
   XY + height at rest, with no migration).
3. **A3 CCTV operator view** (replace the menu panel; keep the console as the
   entry point).
4. **A4 Target capture, descend gate, spreader reshape, lift gate.**
5. **A6 Manual mechanism + crane pages.** Add the shared first-use vs. repeat
   mechanism to `manual_objectives.gd`/`manual_progress.gd`/`manual-chapters.json`.
   The first occurrence of a procedure gets detailed objectives with exact keys;
   later occurrences get one goal plus a "procedure: p.N" link to the detailed page.
   Rig pages (branch B) will reuse this, so make it generic per procedure id. Then
   rewrite the crane pages: detailed on the first crane trip, goal-only after.
6. **Write Grok task files** (exact anchors/code/commands/acceptance/stop
   conditions) in this folder:
   - `A5-crane-automation.md`: one `workshop_automation.gd` helper that drives the
     crane to target/descend/lift for `build_stages.gd` and tests. List every old
     menu-command call site to replace.
   - `A7-crane-tests.md`: isolated tests (descend refused outside the radius and
     allowed inside it; strafe pauses at the gantry; spreader matches the task;
     at-rest save round-trip), classified in `tools/test_inventory.py`.
   - `A8-crane-records.md`: deferred auto-attach power-up in `workshop-state.md`
     (link it to the open PDA/unlock item), and a status line in the checklist.

   If a call site or test fixture is too entangled for Grok, do that part yourself
   and say so.

Keep the stages and tests runnable at each commit. If an old command must stay
temporarily for `build_stages.gd`, keep it internal (not on the console) until A5
lands.

## Phase 2 — integration run (after Grok)

Review A5/A7/A8 commits, fix issues, run the touched routine suites (crane, manual,
stage_contract, save_roundtrip, startup smoke), and report. Stop for **human
checkpoint A**.
