# Task 07 — Generic receiver, occupancy register, then pauldrons

**Model:** Sol (xhigh) · **Depends on:** 05 · **Optional review:** Opus, after the commit

## Why

Each section so far got its own receiver controller (`core_guide.gd` 285 lines,
`backpack_hinge.gd` 334, `shoulder_support.gd` 199, `arm_cassette.gd` 261). Each
re-implements the plan's one protocol:

> seat → retain → (lock / transfer weight) → release rig → services/closure

with its own state, sweeps and save code. Each also reaches into other machines'
internals (`arm_cassette.gd:118` reads `carrier.path` and `rail.index_x`;
`shoulder_support.gd:62` writes `workshop_access.arm_services_stowed`).
`service_crane.gd` now has 19 tasks, 22 optional contract keys and 27
`complete_journey` branches. The head adds ~6 more receivers and the pauldrons 2,
so this pattern must stop **before** them.

The goal of this task: the pauldron is mostly **data** on a generic receiver, and
task 08 can add head pieces with little new code.

## Rules

- **No new keys** in crane task contracts beyond those already used
  (`guided_receiver`, `receiver_equipment`, `rig_adapter`, `access_mode`,
  `handle_points`, …).
- Edits to `service_crane.gd` are allowed only to generalize its existing
  guided-receiver hook, at most ~20 lines. If you need more, stop and report why.
- Don't migrate `core_guide`, `backpack_hinge` or `shoulder_support`. Only the
  limb-station interlock moves to the occupancy register (Part B).
- Don't build features no consumer uses yet: no weight-transfer phase unless the
  pauldron needs it.
- No M3 save code: rely on the base-class defaults for `capture`/`validate`/`apply`.
- No automated walking, reach/visibility or rendered review.
- Apply `.agents/skills/gundam-assembly-review/SKILL.md` for the part/manual audit,
  but no rendered review.
- **Preflight before integration.** Check the complete payload *and* complete rig
  (spreader, ends, cables) against fitted neighbours and parked equipment along the
  whole authored route before writing runtime motion. Missing the full rig envelope
  is the documented failure from the core/backpack work.
- Don't request sandbox escalation. New SVG part icons need a Godot import; ask the
  user to run `./play.command --headless --editor --import --quit`, and don't wait
  silently.
- Make one commit per part (A, B, C) so each can be reviewed or reverted.

## Part A — guided-receiver protocol and generic receiver

1. **Write down the protocol the crane already calls.** `service_crane.gd` calls
   these on `_guide()`: `active`, `accept`, `secured`, `retained`,
   `receiving_error`, `rig_error`, `departure_error`, `depart`, `request`,
   `action_error`, `crane_options`, `load_pose`, `beam_pose`, `rig`, `spec`,
   `rig_changed`, `capture`, `validate_crane`. Create `scripts/guided_receiver.gd`
   (extends `equipment.gd`) declaring each with safe defaults and a one-line comment
   on what the crane expects. Don't change the existing receivers.
2. **Create `scripts/staged_receiver.gd`** (extends `guided_receiver.gd`): one
   instance per receiving connection, configured entirely from content JSON
   (`equipment.receivers.<id>`, authored in Python). Minimum fields:
   - `uid` (payload assembly), `owner`, `slot`, `seat` (pose relative to owner),
     `crane_task`;
   - `requires`: `["assembly:milestone", ...]`, all true before the crane may lower here;
   - `retention_slots`: slots that must be filled before rig release;
   - `closure_slots`: slots blocked while any crane end is attached (via
     `placement_error`/`access_error`).

   State: idle → seated (crane holds) → retained → released. Undo of a retention
   slot is allowed only while the matching crane task has all ends attached at the
   receiver, mirroring today's supported-correction rule.
3. **Registration:** M3 equipment is listed in `scenario_profile.gd`
   (`p.equipment`), constructed in `workshop.gd` (`_build_equipment`) and registered
   in `equipment_registry.gd`. Build one `staged_receiver` per
   `equipment.receivers` entry at that construction point, so adding a receiver
   needs no new profile edit.

Commit A: `Add a data-driven staged receiver behind the crane's guided-receiver hook`.

## Part B — occupancy register (limb station pilot)

1. Create `scripts/zone_register.gd`: `claim(zone, holder) -> String` (error if
   another holder has it), `release(zone, holder)`, `holder(zone) -> String`. No
   saving. Expose it as `game.zones`, or as registered equipment `zones`; pick one
   and say which.
2. Declare zones in layout data (`tools/author_workshop_blockout.py` →
   `workshop.zones`). Start with just `limb_station`.
3. Pilot: the leg cradle (while not at X22 parking), the foot carrier (while
   `path>0`, moving or mid-handoff) and the arm cassette (while at the station)
   claim and release `limb_station` in their existing state transitions. Replace the
   direct cross-reads in `arm_cassette.gd` `receiving_error` (rail `index_x`, carrier
   `path`) with `game.zones.holder("limb_station")`, keeping the same player-facing
   messages. Keep behaviour identical: `m3_sequence_test`, `arm_cassette_test` and
   `indexed_leg_rail_test` must still pass unchanged.
4. Every new interlock in this and later tasks goes through zones or `requires`
   milestones, never through another machine's fields.

Commit B: `Route limb-station occupancy through a shared zone register`.

## Part C — pauldrons on the generic receiver

Source of truth:
[shoulder spec, "Rigid removable pauldron"](../../arms/shoulder-and-upper-arm.md#rigid-removable-pauldron)
and the state sequence in the same document (step 5, "Closed"), plus the pauldron
row of the crane-route table in [final-assembly-plan.md](../final-assembly-plan.md).
Key facts:

- **Per side:** 1 carrier (prepared assembly), 4 M20 carrier bolts, 2 closure panels.
  Each panel has 4 captive M12 screws: these are fastening operations, not separate
  stock. Envelope |X|1.62..2.80, Y±0.65, Z13.65..15.05 in reference-arm
  coordinates; the inboard side is open and notched (see the spec's window
  dimensions).
- **Rigging:** two crane ends on vertical front/rear rig plates near
  `(±2.35,±0.65,14.98)`, normals ±Y, with handles on the same faces. This is a
  two-end task.
- **Route:**
  1. lift until the lowest point is world Y18.0 (body top 19.4, hook ≈20.53);
  2. travel via front distribution Z13 to the shoulder X, then to Z26;
  3. lower to the final-approach start (carrier top world Y18.05), then lower
     1.60 m to seat, bottom open, inboard cutouts aligned.

  Front wings stay closed (the head/pauldron access state). Mirror for the right side.
- **Prerequisites (as `requires`):** the shoulder is secured, with every arm crane
  end stowed. The crane releases only after all 4 M20 bolts are fitted. Panels
  are allowed only after the carrier is retained and its rig released (`closure_slots`).
- **Bolts:** 4 M20 bolts at `C + t·u + 0.38e ± 0.11f`, t = 0.60/0.75, entering along ∓Y
  into arm-owned bosses. Derive world/arm-local positions from the existing arm
  geometry (`arm_delivery_geometry.gd`, `author_m3_shoulders.py`).
- **Source:** two passive upright stores, carrier bottom world Y0.75, on saddles,
  inside crane coverage in the small-stock area (X−11.5..8.75/Z−5..2, stock ≤3.2 m
  high). The spec also allows the vacant long-limb fixture; prefer passive stores so
  no cassette modes are needed, and record this in the shoulder doc.
- **Panels:** two-hand carried via an elevator shelf. Shelf capacity is
  1.35 × 0.35 × 1.10 m. If a panel doesn't fit, stop and report the dimensions
  instead of resizing the shelf.
- **Restraint release:** after both panels close, the arm's supplied
  elbow/wrist/digit restraints become releasable through local operations. Find
  their current representation (`grep -rn restraint tools/author_m3_arms.py scripts/arm_*.gd`).
  Re-engaging is allowed for local correction.
- **Deck clearance:** the 16.4 m deck must notch/retract around the pauldron top
  (spec). Check it in preflight against the actual blockout solids.

Implementation outline:

1. Author content in a new `tools/author_m3_pauldrons.py`, following
   `author_m3_shoulders.py`, and hook it into `author_leg_prototype.py`. Write
   receivers, parts, slots, manual pages, stores and crane tasks. `--check` must
   byte-match.
2. Add `tests/pauldron_preflight_test.gd`, mirroring `arm_preflight_test.gd`:
   full body plus rig along both routes. Include a counterexample: a cross-workshop
   carry at final-approach height must be rejected.
3. Add `tests/pauldron_delivery_test.gd`, starting from `run_to("pauldrons")`. Cover:
   - both sides;
   - premature rig release rejected;
   - panel before carrier retention rejected;
   - restraint release only after closure;
   - a local bolt correction only under crane support.
4. Append stage `head` to `M3Stages.STAGES`/`TITLES` and implement
   `complete("pauldrons")`. At the start of `head`: both pauldrons retained with
   panels closed, restraints released, crane parked.
5. Docs: in `shoulder-and-upper-arm.md`, add a short "Wider M3 pauldron
   implementation — <date>" section (≤20 lines: source location, any deviations).
   Add one bullet to the plan ledger. No run-ID narratives.

Commit C: `Add pauldron carriers and panels on the staged receiver`.

## Acceptance

- All M3 cases from task 05's acceptance command pass, plus `pauldron_preflight_test`,
  `pauldron_delivery_test` and `m3_stage_flag_test`.
- `git diff <task-05 commit>..HEAD --stat -- game/workshop/scripts/service_crane.gd`
  shows ≤ ~20 changed lines.
- No new crane-contract keys:
  ```sh
  python3 -c "import json,collections;d=json.load(open('game/workshop/assets/leg-bay-m3-layout.json'));print(sorted({k for t in d['crane']['tasks'].values() for k in t}))"
  ```
  The output must be a subset of the keys present before this task. Report the list.
- **Code size:** the pauldron itself adds **no new controller script**. If it needs
  one, stop after Part B and report why the staged receiver couldn't cover it.

## Report

- Per part: files changed, line counts for `staged_receiver.gd`/`zone_register.gd`,
  and the commit hash.
- Test pass/fail with `seconds`.
- Preflight margins (minimum clearances found).
- Any spec deviation, and whether a Godot import was needed.
