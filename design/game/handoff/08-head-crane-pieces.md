# Task 08 — Head: baseplate, side shells, structural top

**Model:** Sol (high/xhigh) · **Depends on:** 07

## Goal

Implement the first three head installation steps on the fixed neck spoke, using
task 07's `staged_receiver` and zone register:

1. **Baseplate** (crane);
2. **left/right wraparound sides** (crane; handed geometry);
3. **structural top** (crane).

Source of truth: [head.md](../../head.md), sections "Baseplate construction and
assembly order", "Torso spoke to baseplate", "Wraparound side shells, rear seam, and
structural top", "Supported source-to-head handling and overhead envelope" and
"Standing areas, tool visibility, and fitted-neighbor checks". Also use the head
rows of [final-assembly-plan.md](../final-assembly-plan.md) (bulky-fixture source
table, crane route table, work-patch table).

## Rules

- **New code budget:** head pieces must be data on `staged_receiver`, plus authoring
  Python. If a piece needs a new controller script or new crane-contract keys, stop
  and report why before writing it.
- New interlocks go through `requires` milestones or the zone register, never through
  another machine's fields.
- **Preflight first:** check full payload plus full rig (spreader, ends, cables)
  against the fitted torso, both arms and pauldrons, the backpack, head-level decks
  and parked equipment along each authored route, before runtime motion.
- No M3 save code. No automated walking, reach/visibility or rendered review.
  Apply the assembly-review skill's part/manual audit.
- Don't request sandbox escalation; ask the user for the Godot import when you add
  part icons.
- One commit at the end. If it grows large, commit per piece.

## Key facts (verify against head.md)

- **Order:** fixed spoke → baseplate → sides/rear wraps → structural top → sensors →
  faceplate → mask → crown. This task stops after the top. The front sensor opening
  must stay open.
- **Baseplate:**
  - Approach with the plate underside at Z15.64, lower 0.06 m to entry, then 0.18 m
    onto the seat. Unique front key; reversed orientation rejected.
  - 4 M24×160 bolts + 4 mm washers at `(X±0.27, Y±0.27)`, entering −Z.
  - Two upward structural magnetic pads at `(±0.62,0,16.20)` (two-end task). The
    crane stays attached through seating and retention.
  - Connect the central power/data loom after all four bolts, before the sides close
    access. Stow both ends from the open front before either side shell.
- **Sides:**
  - Handed. Lower feet on baseplate seats; rear vertically-entered hooks on the rear
    uprights near `(±0.64,−0.45)`; locating tabs and recessed bolts on the short
    mounting uprights.
  - Prepared upright on reusable fixtures. Use the bulky fixture with upright
    head-piece inserts at X3.25/Z13, other pieces at Y0.85; add insert templates in
    layout data.
- **Top:** structural roof on the side frames, leaving the front sensor slide
  accessible (underside ≥ Z17.22 across the sensor aperture X±0.60).
- **Route (all crane pieces):** from source X3.25/Z13, raise until the lowest load is
  Y19.0, cross to X13, then to Z26, then lower to the piece's specified approach.
  Front wings stay closed. Highest hook Y21.58.
- **Workers:** 16.4 m deck work patches, front X11..15/Z23.4..24.6 and rear flanks;
  rear neck bolts ≈2.24 m before the shells.
- **Coordinates:** head-local origin `(0,0,15.40)` robot; world = `(13+X, 1.4+Z, 26−Y)`.

## Deliverables

1. `tools/author_m3_head.py`, hooked into `author_leg_prototype.py`: parts, the head
   assembly/slots/manual pages, receivers, bulky-fixture head inserts, crane tasks.
   `--check` byte-matches.
2. `tests/head_preflight_test.gd`: full body plus rig per route, with a
   counterexample (a lower crossing must be rejected).
3. `tests/head_crane_test.gd`, from `run_to("head")`. Cover:
   - order enforced (side before baseplate retained → rejected; top before both
     sides → rejected);
   - reversed baseplate rejected;
   - premature rig release rejected;
   - loom connection required before the sides;
   - one supported local correction.
4. Append stage `head_sensors` to `M3Stages` and implement `complete("head")`. At the
   start of `head_sensors`: baseplate, both sides and top retained, rig released,
   crane parked.
5. Docs: a short "Wider M3 head implementation — <date>" section in head.md (≤20
   lines: sources, deviations), plus one plan ledger bullet.

## Acceptance

- Task 07's acceptance command plus `head_preflight_test`, `head_crane_test` and
  `m3_stage_flag_test` all pass. Add `"head_sensors"` to the flag test's stage list.
- No new controller scripts and no new crane-contract keys (report the key-set
  command output from task 07).

## Report

- Files and line counts.
- Test pass/fail with `seconds`.
- Preflight minimum clearances.
- Deviations from head.md.
- Commit hash(es).
- Whether you think task 09 can go to a Grok model: list exactly which files and
  functions a new hand-carried piece or crane piece needs.
