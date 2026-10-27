# C6 — Launch cage v2: coarse plan with the workshop free to change (coordinator brief)

Branch `gantry-v2-plan`, worktree `/private/tmp/gbs-gantry-v2`. Coordinator: Astra
High. Read the [README](README.md) shared rules and the current C5 candidate in
`design/game/gantry-v2/README.md` (especially "7. Conflicts and decisions") first.
**Design only.** No game code, layout JSON, generator or test changes. A v2 build is
still not approved.

## User decisions — 2026-10-27

- C5's candidate is blocked, mostly because it treated the workshop, the hangar door
  and the elevators as fixed. **You may now change the workshop building, the door and
  the elevators** (positions, shafts, guides, cars, landings, door size, type and
  location) as the design requires.
- "The robot model is likely going to change significantly, so I'm not convinced this
  much detail in tolerances is valuable." C5 produced 5.1 million checked pairs and 69
  close-up sheets. Replace that with a coarse plan. Size the design around generous
  envelopes so it survives the robot changing.
- The crane operator view was rejected. The crane keeps `main`'s authored routes.
  Do not use the `crane-operator-view` branch for anything.

Unchanged: the robot and its hip datum (13, 10.6, 26), and the crane rail and trolley.
The design must still provide:
- a mirrored layout about X13
- no fixed rear crossover and no rear crosshead
- a clear exit route for the whole robot
- level, guarded walkways with no fall-through gaps.

## Method

- **Robot envelope:** use a handful of boxes, one per major component (feet, legs,
  hip, core/chest, backpack, each arm, head), taken from the C5 measurements. Inflate
  each by a stated growth margin; propose about 0.5 m, and more where future armor is
  likely to grow. State the margins once, in one table.
- **Crane envelope:** one swept box per delivery route from `main`'s crane data,
  inflated the same way.
- **The checker** (`check.py`) reports pass or fail and the minimum clearance for each
  state and reserved volume: tens of lines, not millions. Keep the mirror,
  walkway-width (1.20 m, 1.50 m at landings) and seam checks. Keep it stdlib-only.
- **Drawings:** `draw.py` generates only the seven overview sheets (four level
  plans, front, side, exit route). Dimension the main layout: tower positions and
  sizes, elevator positions, door aperture, walkway widths, arm lengths and swing
  arcs, and the exit corridor. Do not dimension every small clearance.

## Resolve C5's conflicts with the new freedom

For each of C5-01 to C5-08, either solve it (moved or rebuilt elevators, a wider or
relocated door and rear wall, retracting walkways or roots, re-sited towers) or
explain why it no longer matters at coarse scale. Pick one design and justify it
briefly; don't survey every option. Cover:
- a door that opens, and its aperture, for the whole robot plus carrier
- the elevator layout, and whether elevators live inside the towers
- how work catwalks and hip supports clear the exit
- tower headroom under the crane routes
- core rail/crossframe support.

## Deliverables (replace C5's, on this branch)

1. Rewrite `design/game/gantry-v2/README.md` as a concise plan, roughly 150–250
   lines. Sections:
   1. Decisions and margins
   2. Workshop, door and elevator changes
   3. Towers and catwalks per level
   4. Hip support
   5. States: assembly, delivery, exit
   6. Exit route
   7. What a build changes in the game: files and systems, such as the layout
      generator, `hangar_dressing.gd`, the lifts, saves and the tests to update
   8. Prototype slice and task list, with an agent type for every task (Astra for
      judgment and integration; Grok only for unambiguous edits with exact anchors)
   9. Open questions for the user
   10. Mechanical evidence, kept separate from player acceptance
2. Simplify `plan.json`. Slim `envelopes.json` to the coarse envelopes, and keep the
   probe so the fine data can be regenerated.
3. Delete:
   - `drawings/tight-*.svg`
   - `drawings/tight-index.json`
   - `datums.csv` and `exit-inventory.csv`, unless the README genuinely needs them.

   Remove any tracked `__pycache__`. Target: the whole `design/game/gantry-v2/` folder
   under 1 MB.
4. Records:
   - Add one line under the concept section in `final-assembly-plan.md` linking the
     plan and stating that the build is not approved.
   - Add one dated line to the playtest checklist's machine-operation section.
   - Keep the existing `workshop-state.md` document-table row, updating its wording.

**Stop condition:** if a conflict needs the robot or its hip datum to move, don't move
it. Finish everything else, list the conflict in the open questions with a
recommendation, and stop.

No regression suites are needed (no game changes). No `run_diagnostics.py`, rendered
review or walking sweeps. Commit scoped on `gantry-v2-plan` only. End every commit
message with `Co-Authored-By: Codex <noreply@openai.com>`. Do not push. End with a
short report as your final reply: commits, the checker result, the chosen layout in
five lines and the open questions. Do not append a report to the handoff README.
