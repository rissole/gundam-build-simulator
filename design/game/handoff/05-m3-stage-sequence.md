# Task 05 — Shared M3 stage sequence, and flatten the test chain

**Model:** Sol (xhigh) · **Depends on:** 04 · **Expected size:** 1 new script, M3 tests restructured; no equipment behaviour changes

## Why

The full M3 sequence currently exists only inside a linear test-inheritance chain:
`indexed_leg_rail_test → chest_delivery_test → core_delivery_test → backpack_delivery_test → arm_delivery_test`,
with `*_after_legs_test` files that flip a flag and replay everything. One failure
hides everything downstream, and the previous agent worked around the replay with a
`/tmp` snapshot. Two things are needed:

1. a reusable **happy-path sequence** that both the tests and the `--m3-stage`
   launch flag (task 06) can call;
2. section tests that start from that sequence instead of inheriting each other.

## Rules

- Change no equipment behaviour. The only new file in `scripts/` is `m3_stages.gd`;
  don't edit other scripts. If the happy path fails because of a product bug, stop
  and report it with the failing command and message. Don't weaken interlocks.
- Keep every non-save check that exists today (task 04 already removed the save ones).
  Moving checks between files is fine; deleting one needs a line in your report.
- No M3 save code. No automated walking, reach/visibility or rendered review.
  Don't touch `m3_acceptance_test.gd`, `m3_hip_access_test.gd` or `m3_route_clearance_test.gd`.
- Don't request sandbox escalation; ask the user to run the Godot import if needed.
- Match the surrounding GDScript style (compact; tabs; `;`-joined short statements).

## Required API — task 06 depends on this exactly

File `game/workshop/scripts/m3_stages.gd`:

```gdscript
extends RefCounted
## Scripted M3 progression: the same equipment commands the mechanical tests use.
## Fastenings and rig attachments are supplied (Staging.fill / supplied rig state);
## this is never playtest evidence and never a save.

const STAGES = ["pelvis","left_leg_build","left_leg_dock","right_leg_build","right_leg_dock","chest","core","backpack","left_arm","right_arm","pauldrons"]
const TITLES = {"pelvis":"Pelvis delivery", ...}   # one short title per stage

func _init(workshop: Node) -> void
## Errors describing why the workshop is not at the start of `stage`; empty when it is.
func stage_errors(stage: String) -> Array[String]
## Runs the work of `stage` itself, taking the workshop from that stage's start
## to the start of the next stage. Requires stage_errors(stage) to be empty.
## Returns "" or "<step>: <error>". Not valid for the last stage.
func complete(stage: String) -> String
## From a fresh workshop: for each stage before `stage`, check stage_errors, then complete.
## Finally checks stage_errors(stage). Calls progress.call(TITLES[s]) before each stage
## when progress is valid, and awaits one process frame between stages.
func run_to(stage: String, progress: Callable = Callable()) -> String
## Shared helpers moved from indexed_leg_rail_test.gd. Return "" or an error string.
func settle(controller: Node, limit: int = 1600) -> String
func command(controller: Node, action: String) -> String
func supply_rig(crane: Node, attached: bool) -> void
```

`run_to` must return an error (not crash) for an unknown stage or a non-fresh
workshop. `"pauldrons"` is the last stage for now: start of pauldron work, both arms
secured. Tasks 07–09 append `head`, `head_sensors` and `complete`.

## Stage boundaries

Each row says what is true at the **start** of the stage. These are the
`stage_errors` checks. Use the existing APIs; the names below come from the current
tests, so verify each one.

| Stage | Title (suggested) | True at start |
|---|---|---|
| `pelvis` | Pelvis delivery | Fresh workshop. Pelvis at `support:bulky_fixture`. |
| `left_leg_build` | Left-leg construction | Pelvis at `support:pelvis_gantry`, `module_supports.support_secured()`. Crane parked: `station=="park"`, raised, `attached_count()==0`, no motion. Left prepared foot still on its bay support. |
| `left_leg_dock` | Left-leg docking | `model.milestone("left_leg","structural_ready")`; foot mounted on `left_leg`; crane parked; `rail.can_construct()` with `rail.active_assembly=="left_leg"`. |
| `right_leg_build` | Right-leg construction | `left_leg` parent is `pelvis`, all `left_*` captive locks engaged. Holder home and released; foot carrier home (`path==0`, `withdrawal==0`, not carrying); `rail.active_assembly=="right_leg"` and `rail.can_construct()`. Right foot still on its bay support. |
| `right_leg_dock` | Right-leg docking | `right_leg` structural_ready, foot mounted, crane parked, holder at home with `right_leg` active. |
| `chest` | Chest delivery | Both legs parented to `pelvis` with their locks engaged; holder home/released; carrier home; crane parked; chest on its passive store. |
| `core` | Core delivery | `model.milestone("pelvis","chest_connected")`; bulky fixture empty; crane parked. |
| `backpack` | Backpack delivery | Core retained/connected and crane released (use the condition the core test checks after "core crane released"); fixture empty; crane parked. |
| `left_arm` | Left-arm delivery | Backpack closed, latched and covered (the backpack test's final condition); crane parked. Cassette at its passive parking with the left arm retained on it. |
| `right_arm` | Right-arm delivery | `left_shoulder.secured()`; crane parked with every end stowed; right arm on its passive store. |
| `pauldrons` | Pauldron fitting | Both shoulders `secured()`; crane parked; all arm crane ends stowed. |

## Happy path

The steps for each stage are the forward commands already in the tests:
`deliver_pelvis`, `deliver_foot`, the leg crane-task loop, rail advance/return, the
captive locks, the carrier return (added in task 01), `deliver_chest`,
`deliver_core`, `deliver_backpack` and `deliver_arms`. Include only what moves the
build forward:

- **Exclude:** rejected-command probes; source-roll/parking excursions; reacquisition
  cycles; stop/resume interruptions; local corrections (chest, backpack and shoulder
  keeper corrections); evidence writing.
- **Include:** real transfers through stores and the bulky fixture (for example
  `chest_store → bulky_fixture → waist`). That is the real route.
- **Supplied progress:** fastening uses `Staging.fill` exactly as the tests do;
  rigging uses `supply_rig`.

## Tests

1. New `tests/m3_sequence_test.gd` (extends `res://tests/kit/harness.gd`). Boot
   `leg_bay_m3`, then for each stage: expect `stage_errors(s)` empty, then
   `complete(s)` returns "". Finish at `pauldrons`. Print `M3_SEQUENCE PASS|FAIL <n> checks`.
   Report its `seconds`; the target is under 60 s.
2. Restructure the section tests so **none extends another M3 section test**. Each
   boots, calls `await stages.run_to("<its stage>")`, expects "", then runs its
   detailed flow and assertions. Detailed tests keep their negative checks and
   corrections; they may call `stages.command(...)` wrapped in `expect`.
   Suggested mapping: leg checks → `indexed_leg_rail_test` (from `left_leg_build`;
   keep the park/roll/reacquire checks); pelvis → `pelvis_delivery_test` (from
   `pelvis`); chest/core/backpack/arm tests from their own stage; `arm_cassette_test`
   from `left_arm`; `backpack_fixture_test` from `backpack` (or `core`, whichever its
   checks need).
3. Delete `chest_after_legs_test.gd`, `core_after_legs_test.gd`,
   `backpack_after_legs_test.gd`, `arm_after_legs_test.gd` and their `.uid` files.
   `m3_sequence_test` replaces them.
4. Remove every `reopen(` call and the no-op `reopen` function, plus the now-pointless
   equipment re-fetch lines after each call.
5. `tools/run_regressions.py`: drop `CASE_TIMEOUTS` entries for deleted tests. Add
   one for `m3_sequence_test` only if it needs more than 180 s.

## Acceptance

- `grep -rn "reopen(\|_after_legs" game/workshop/tests` prints nothing.
- `grep -rn 'extends "res://tests/\(indexed_leg_rail\|chest_delivery\|core_delivery\|backpack_delivery\|arm_delivery\)_test.gd"' game/workshop/tests` prints nothing.
- This runner command passes every case:
  ```sh
  python3 game/workshop/tools/run_regressions.py --only m3_sequence_test indexed_leg_rail_test pelvis_delivery_test chest_delivery_test core_delivery_test backpack_delivery_test backpack_fixture_test arm_cassette_test arm_delivery_test chest_content_test core_content_test mirrored_leg_content_test arm_preflight_test backpack_preflight_test shoulder_content_test wide_foundation_test wide_access_test wide_elevators_test mobile_platform_test rail_gates_test m3_stock_test m3_content_test shared_crane_payload_test m3_workshop_launch m2_crane_launch m2_retention_launch default_workshop_launch --jobs 4
  ```
- Before committing, `git status --short game/workshop/scripts` shows only
  `?? game/workshop/scripts/m3_stages.gd` (and its `.uid`), with no modified scripts.

## Finish

Commit: `Share the M3 stage sequence between tests and tooling; flatten the test chain`.

## Report

- `seconds` for `m3_sequence_test` and the slowest section test.
- Per-test check counts, before (task 04's run) and after.
- Any check labels removed or merged, with the reason.
- Any boundary predicate you had to define differently from the table.
- The commit hash.
