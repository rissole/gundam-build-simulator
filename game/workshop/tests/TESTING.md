# Routine tests and named diagnostics

The default command is `python3 game/workshop/tools/run_regressions.py`.
It runs the explicit routine inventory in `tools/test_inventory.py`, with four
workers. `--only NAME ...` narrows it; `--list` lists routine cases only. New
runnable suites must be classified or discovery fails before starting anything.

A run exceeding 60 seconds prints a warning immediately and continues. Improve
the slow tests; increasing a timeout does not resolve a performance warning.
The final report includes wall time, slowest cases, correctness, input hashes and
whether the warning fired. Existing timeouts protect against hung processes and
are separate from the 60-second target. An assertion/engine error, nonzero exit,
missing summary, empty Python discovery, stalled exit or changed input fails.

Import assets separately with `./play.command --headless --editor --import --quit`.
The runner refuses to trigger an initial import implicitly. Warm run timing includes
fingerprinting, process startup, tests and final input checks, but no asset import.

Expensive investigations require an explicit user request and named cases:

```sh
python3 game/workshop/tools/run_diagnostics.py --list
python3 game/workshop/tools/run_diagnostics.py --only arm_preflight_test
```

There is no default or `--all` diagnostic selection, and routine verification
cannot select diagnostic cases. Do not enumerate the diagnostic inventory to
simulate a run-all command. Diagnostics default to one worker. Files remain in
place where useful to existing visual-review inheritance; classification, not
filename suffix, determines which runner can execute them.

## Coverage migration

This table maps the previous runnable inventory to its retained assertions and
replacements. Cases retained as diagnostics have not been claimed as freshly
passing. The fixture setup is supplied state, not evidence of player access.

| Previous cases / assertions | Routine replacement or retained diagnostic |
| --- | --- |
| assembly_model, state, pitch_model, pockets_model, supported_model | Retained unchanged as routine model suites: inventory, dependency cycles, wrong variants, exact identity, supported transfers, atomic rejection and undo. |
| robot_content, leg_content, part_variants, source_assets | Routine data/source coverage retained. Robot content now consumes the production content loader. |
| zone_register, geometry_surface_audit, interaction_outline, manual_diagram_cache | Routine small fixtures retained; geometry algorithm coverage does not imply a whole-workshop surface audit. |
| nested_runtime, centered_carry, access_lift, rail_gates, mobile_platform, wide_elevators | Routine real-physics fixtures retained. Shared equipment fixture extracted into `kit/equipment_fixture.gd`; no dependency on the wide-access test body. |
| pitch_interface | Routine actual imported triangles and interface checks retained. |
| chest_content, shoulder_content | All existing assertions retained in isolated source fixtures using production procedural mesh and collision projection. No preceding build or hangar boot. |
| workshop_launch | Replaced by workshop_smoke: one actual startup, explicit initialized/paused state, equipment registration, ownership, initial manual, fresh boundary and Escape input. |
| stage_flag | Redundant replay deleted. stage_contract tests actual orchestration with controlled completion, failure/invalid boundary stopping, unknown-stage rejection and paused handover restoring both input modes. Actual complete-boundary checks remain in diagnostic stage_sequence; CLI argument launch remains stage_launch. |
| crane_pickup | Routine crane_policy checks actual authored ordering, refusal without skipping, carry/delivery/put-back menus, interrupted Stop/Resume, incomplete rig rejection and exact reacquisition. Full physical transfer/beam continuity remains a diagnostic. |
| pelvis_delivery, chest_delivery, core_delivery, backpack_delivery, arm_delivery, pauldron_delivery, head_crane, head_closure | Routine receiver_contract checks real model seating, wrong source/occupied-zone rejection, actual mounted transform, retention, partial rig, release and closure gates. Specialized controller behavior, complete delivery sequences, correction paths and full-scene interactions remain named diagnostics. |
| arm_cassette, backpack_fixture, indexed_leg_rail | Named diagnostics retain their unique shared fixture, clamp and rail sequence coverage. They are not silently substituted with fake controller decisions. |
| arm_preflight, backpack_preflight, pauldron_preflight, head_preflight, core_content | Named diagnostics retain full payload/rig paths and unique obstruction/clocking checks. |
| mirrored_leg_content, stock | Named diagnostics retain physical source contacts, holder switching, canonical runtime stock bodies and task-switch identity checks. |
| parent_sequence, pitch_desktop, pitch_swapped_desktop, pockets_desktop, manual_candidates | Named diagnostics retain full desktop/manual integration. Pitch build helper stays available to explicitly requested visual review. |
| robot_workshop, wide_foundation, wide_access, stage_sequence, stage_launch | Named diagnostics retain stage journeys, actual equipment integration and full-blockout motion. Startup and local controller coverage are routine; long sequence success is not inferred. |

New staging_policy exercises production right-foot preparation with a real model,
checks preservation of left-foot source stock, candidate filtering and foot-carrier
undo at the fixture versus after departure. It found the shared right-pad recipe's
fallback consuming left sleeves; mirrored fallback now stays in authored mirrored
stock. Presentation collaborators are inert only in this model-focused fixture.

The long existing lift fixture yields 1 ms of wall time per simulated physics
frame to let Jolt workers drain; its physics ticks and assertions are unchanged.
A benchmark exposed worker-pool exhaustion without pacing; this is not retried
or ignored by the runner.

New runner_contracts uses tiny Python subprocesses for classification, named-only
diagnostics, error/exit/stall gates, changed input rejection and warning behavior.
It does not recursively execute Godot suites.

The previously deleted old-room geometry, walking, targeting and access suites
remain retired. Human playtesting owns walking, visibility, reach and usability;
no automated result in this table establishes those outcomes. No rendered review
is implied or required by routine verification.

## Measured result — 2026-10-25

Three final warm runs passed all 28 routine cases in **8.82 s, 8.72 s and
8.77 s** wall time measured around the entire runner process. The runner's own
reported times were 8.762 s, 8.668 s and 8.719 s. Each run retained unchanged input
hashes and passed 2,151 Godot assertions plus 20 Python tests (9 runner contracts,
11 source-asset checks). No asset import was performed; existing imports were used.
The 29 named diagnostics and rendered reviews were not run.

Local machine-readable evidence: `verification/fast-suite-warm-benchmark.json`
and the three report paths it records (ignored verification artifacts).
The earlier failed worker-exhaustion run is also retained locally; final timings
include the lift fixture's scheduling fix and are not automatic retries.
