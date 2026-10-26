# C5 — Launch cage v2 dimensioned plan (coordinator brief)

Branch `gantry-v2-plan`, worktree `/private/tmp/gbs-gantry-v2`, from `main` at the
gantry-access merge. Coordinator: Astra High. Read the [README](README.md) shared
rules, the [launch cage concept](../../final-assembly-plan.md#launch-cage-v2-concept--2026-10-27)
and the C1 probe method (`git show b42733f:design/game/handoff/operated-machines/C1-gap-audit.md`) first.

Requested by the user on 2026-10-27: "can you make a dimensioned plan please". This is
the concept's first build step: a dimensioned collision/support plan. It is
**design only**. Do not change game code, layout JSON, the blockout generator or tests.
Building v2 is still not approved.

## Deliverables

All in a new folder `design/game/gantry-v2/`:

1. **`plan.json`**: the single source of every proposed v2 solid and motion, in workshop
   world metres (X, Y, Z as `workshop-layout.json`):
   - tower members, foundation pads and landing decks
   - swing-arm pivots, arm boxes, docked and parked poses, swing arcs (centre,
     radius, angles, deck Y)
   - docking tongues and their extended/retracted lengths
   - hip support arms, bearing contacts and retention
   - guards and toe-boards
   - parking pockets
   - per-state docked/parked sets for the five concept states (assembly,
     delivery/service per delivery, prepare for exit, lower and transfer, roll-out ready)
   - the existing solids v2 removes, by layout id: rear crossover on all levels, rear
     crosshead, and anything else the plan retires.
2. **`check.py`**: a stdlib-only Python checker. Run it as `python3 design/game/gantry-v2/check.py`.
   - Loads `plan.json`, `game/workshop/assets/workshop-layout.json`, and the
     measured envelopes file (item 4).
   - Reports, per state, the minimum clearance between every proposed solid or swept
     arc and every reserved volume.
   - Fails (non-zero exit) on any intersection or on a clearance under the margin the
     plan states for that volume.
   - Checks mirror symmetry about X13, including fore/aft guard placement.
   - Checks the continuous clear walking width (1.20 m, 1.50 m at primary landings).
   - Checks seams at moving joints (≤ 40 mm, the C1 threshold).
   - It is a design tool, not a game regression suite. Do not add it to
     `test_inventory.py` or `run_regressions.py`.
3. **`draw.py`** plus generated SVGs, drawn from `plan.json` and the layout so they
   stay dimensionally true:
   - a plan view per work level (8.4, 11.2, 14.0, 16.4): docked arms solid, parked
     arms dashed, swing arcs, reserved volumes hatched, dimension lines on every
     clearance the checker reports as tight (< 0.30 m)
   - a front elevation (looking +Z)
   - a side elevation (looking −X) with the crane's per-task carry heights and the
     trolley underside
   - an exit-route plan from the robot to the door.

   Use readable stroke/label sizes and a light background. Keep each SVG under
   ~300 KB.
4. **`envelopes.json`** plus the scratch probe that made it. Commit the probe under
   `design/game/gantry-v2/probe/`, as a Godot `--script` like C1's `c1_gap_probe.gd`.
   It measures actual runtime geometry at the named stages:
   - the assembled robot's world bounds per component, in the raised pose, at each
     stage where that component is installed
   - leg rig loaded/tilt/rise envelopes at the poses `indexed_leg_rail.gd` authors
   - backpack sweep, core rails and crossframes, mobile platform park and routes
   - elevator cars, doors and shafts
   - the hip bearing caps and hold-downs, and the hangar door's collision aperture
     (`hangar_dressing.gd`)

   Record the stage, source and time for each envelope.
5. **Crane envelopes** from `main`'s authored crane routes (`workshop-layout.json`
   `crane`, `service_crane.gd`): per-task route and via points, lowest carried solid,
   highest spreader/cable and the trolley underside Y22.875. The crane operator view
   (`crane-operator-view` branch) was **rejected on 2026-10-27**; do not use its
   per-task carry heights or approach entries as constraints. Combine the crane data
   with the probe envelopes in `envelopes.json`.
6. **`README.md`**: the dimensioned plan itself. Sections:
   1. Datums and sources: a table of every number used and where it came from (file +
      id/line, or probe output).
   2. Towers: footprint, heights, member sections, foundation pads, and how they wrap
      the X6.6/19.4, Z29 shafts without touching car/guide/door volumes. Include the
      clearance table.
   3. Swing catwalks per level: pivot, length, width, docked and parked footprint,
      arc, dock datum on the robot work patches, tongues, seams, guards and locks.
      Include the clearance table.
   4. Hip support: arm geometry from the tower to the bearing patches (X12.35/13.65,
      Z26.52..26.78, cap top Y10.97), the hip datum (13, 10.6, 26) unchanged, and
      retention. Include a game-plausibility section estimate (state the load
      assumption, span, section and an order-of-magnitude deflection). This is not
      certification.
   5. State table: what is docked, parked or engaged in each of the five states and
      each delivery, with checker results.
   6. Exit corridor: a dimensioned envelope from the robot to Z38.78, the measured door
      aperture, everything currently in it, and what v2 removes or still needs
      (lowering and transport remain deferred).
   7. Conflicts and decisions: every place the concept does not fit as written, each
      with options and a recommendation. Do not silently move a datum, route or
      reserved volume to make the plan pass.
   8. Prototype slice: the concept's "one mirrored level and the hip support handoff".
      Recommend which level (the user's asymmetry and gap finding was the lowest level,
      Y8.4, beside the hip). Give its exact scope, the files a build would touch, a test
      plan using the existing focused suites, and a task list with an agent type per
      task (Astra for judgment and integration; Grok only for unambiguous edits with
      exact anchors).
   9. Mechanical evidence vs. open player questions, kept separate.

## Constraints

- Keep every concept invariant:
  - the hip datum (13, 10.6, 26), bearing cap top Y10.97, four hold-downs and the
    waist locks
  - the leg corridor X10.5..15.5 / Z20.5..30.6, with no floor-level braces in it
  - the service opening X11.4..14.6 / Z27.2..35.3 and the aft well Z31.7..35.3 stay
    open
  - the elevators keep their stops, 2.60 m cars and 1.50 m landing doors
  - the mobile platform lanes stay clear
  - no fixed rear crossover and no rear crosshead
  - the robot itself is not redesigned to fit.
- Measure; don't trust the concept's numbers. Where a measurement disagrees with the
  concept text, use the measurement and list the difference in section 7.
- **Stop condition:** if the towers or arms cannot clear a reserved volume without
  moving a datum, route or reserved volume, do not move it. Finish everything else,
  record the conflict with options in section 7, and stop.
- No `run_diagnostics.py`, no full regression suite, no rendered review, and no
  walking/reach sweeps. The headless probe boots, like C1's, are allowed. If the
  fresh worktree needs imports, run `./play.command --headless --editor --import --quit`
  once.
- Commit scoped on `gantry-v2-plan` only:
  - one commit for the probe and envelopes
  - one for the plan, checker and drawings
  - one for the records.

  Never touch `main` or another worktree.
- Records:
  - Link the new plan from the concept section in `final-assembly-plan.md` (one line).
  - Add a row to the `workshop-state.md` document table.
  - Add a dated line to the playtest checklist's machine-operation section stating
    that the plan exists and that the build is still not approved.

## End-of-run report

Append "## C5 report — 2026-10-27" to [README](README.md) with:

- the commits
- the `check.py` result, with the tightest five clearances
- the probe runs, with their stages and outcomes
- the conflicts list
- the recommended prototype slice
- the open questions for the user.
