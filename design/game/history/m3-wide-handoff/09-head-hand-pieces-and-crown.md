# Task 09 — Head: sensor carrier, faceplate, mask, crown

**Model:** Sol by default. If task 08's report gives a concrete per-piece recipe
(exact files/functions to add) and needed no new controller, a Grok model can do
this task with that recipe pasted in below. · **Depends on:** 08

## Goal

Finish the head in its specified order after the structural top:

| Step | Piece | Handling |
|---|---|---|
| 1 | Sensor carrier: two identical cameras and one range sensor, prepared on one carrier at the bench | Two-hand stock via the elevator shelf |
| 2 | Front faceplate | Two-hand stock via the shelf |
| 3 | Samurai mask | Two-hand stock via the shelf; rests on its hooks hands-free before bolting |
| 4 | Decorative crown/crest | Crane, last |

Source of truth: [head.md](../../../head.md), sections "Sensor carrier: bench preparation
and exact open-front path", "Separate faceplate, mask, and decorative crown mounts",
"Supported source-to-head handling and overhead envelope", "Standing areas, tool
visibility, and fitted-neighbor checks" and "Manual dependencies and remaining
verification".

## User decision, 2026-10-24: enlarge the shelf

The first run stopped at the shelf-fit gate (commit `94d37c2`). The mask is
~1.40 W × 0.20 D × 1.16 H and its hooks alone span 1.36 m, against the 1.35 × 0.35
× 1.10 m single-panel limit. **The user chose to enlarge the shared shelf** rather
than crane, shrink or split the mask. Implement it as part of this task:

- Single two-hand panel capacity becomes **1.45 × 0.35 × 1.20 m**. The two-one-hand-part
  capacity is unchanged.
- Physical shelf width becomes **1.50 m**: left X5.60..7.10, right X18.90..20.40, with
  the same Z27.8..28.2 band and +0.65 m height above the deck. Its top is 1.85 m above
  the deck, inside the car's 2.10 m roof/gear budget. The 2.6 × 2.1 m rear turning
  area is unchanged.
- Apply to **both** elevators through the authored layout data
  (`author_workshop_blockout.py`) and the shelf/lift scripts that read it. Keep
  M2's shelf (`leg-bay-layout.json` / `lift_shelf.gd` M2 path) unchanged unless the
  code is shared; if shared, prove the M2 shelf tests still pass.
- Check the wider shelf against the car doors (1.5 m clear), car walls and shaft
  guides. Re-run `wide_elevators_test` and the pauldron panel shelf checks.
- Update the shelf rows of the access table in `design/game/final-assembly-plan.md`
  ("Shelf" and "Shelf capacity"), and replace the task-09 blocker note in
  `design/head.md` with the resolution (one or two lines).
- Then implement the rest of this task as written. The mask must fit the new
  capacity using its actual authored geometry, with mounts unchanged.

## Rules

Same as task 08: data on `staged_receiver` plus authoring Python; no new controllers
or crane keys without stopping to report; interlocks via `requires`/zones; preflight
before motion; no M3 save code; no automated walking, reach/visibility or rendered
review; no sandbox escalation; assembly-review part/manual audit.

## Key facts (verify against head.md)

- **Sensor carrier:**
  - Three modules on one carrier, two M6 screws per module (bench preparation is
    supplied).
  - The carrier slides into the open front after the top is fitted.
  - Plug its power/data connections before the faceplate. The faceplate must be
    blocked while any sensor connection is open.
- **Faceplate:**
  - ≈X±0.65 / Y+0.64..+0.72 / Z16.13..17.18.
  - Approach 0.18 m forward and translate −Y onto two lower support ledges plus
    side-frame locators.
  - 4 M10×80 front bolts at X±0.55 / Y+0.73 / Z16.20 and 17.12, entering −Y. The
    ledges support it while fastening; all four bolts are required to count as
    retained.
- **Mask:**
  - X±0.70 / Y+0.70..+0.90 / Z15.76..16.92; only after the faceplate is complete.
  - Approach 0.16 m forward and 0.10 m high, translate −Y, lower 0.10 m onto two
    hooks at `(±0.68,+0.74,16.50)`. The hooks give temporary hands-free support:
    the player can let go once it's hooked.
  - 2 M10×160 bolts at `(±0.56,+0.88,15.98)` prevent uplift.
  - The hooked-but-unbolted state is new. Check whether the existing hip-cylinder
    "local clevis parking catch" support covers it before adding anything.
- **Crown:**
  - Final crane load (2.60 m span). Two unique keyed prongs at `(±0.20,+0.52)`,
    Z17.22..17.34. Final approach 0.18 m down, including a 0.06 m clear lead.
  - 2 M12×100 front bolts at `(±0.20,+0.66,17.28)`.
  - Keep the camera and range-sensor optical corridors clear through faceplate, mask
    and crown (head.md gives the aperture positions).
- **Shelf capacity (after the enlargement above):** one two-hand piece up to
  1.45 × 0.35 × 1.20 m. If the faceplate or mask still doesn't fit with its actual
  geometry, stop and report.

## Deliverables

1. Extend `tools/author_m3_head.py` (content, slots, manual pages, receivers, stores,
   crown crane task). `--check` byte-matches.
2. Extend `head_preflight_test.gd` with the crown route (full body plus rig).
3. `tests/head_closure_test.gd`, from `run_to("head_sensors")`. Cover:
   - order enforced (faceplate before sensors connected, mask before faceplate,
     crown before mask → all rejected);
   - mask hook support lets the hands go free before bolting;
   - optical corridors clear;
   - one local correction (remove and refit the mask).
4. Append stage `complete` to `M3Stages` and implement `complete("head_sensors")`.
   At the start of `complete`: the whole head is retained and the crane parked.
   Add `"complete"` to `m3_stage_flag_test`.
5. Docs: extend head.md's implementation section (≤15 more lines) and add one plan
   ledger bullet.

## Acceptance

- All prior M3 cases plus `head_closure_test` and `m3_stage_flag_test` pass.
- `m3_sequence_test` reaches `complete`; report its `seconds`.
- No new controllers or crane keys (or a stop-and-report explaining why).

## Report

Files, test results with `seconds`, deviations from head.md, and commit hash(es).

<!-- If assigning to Grok: paste task 08's per-piece recipe here. -->
