The shared test kit

SceneTree suites extend `harness.gd`, or `workshop_suite.gd` when they need model
fixtures. In-scene suites extend `node_runner.gd`. Both adapters use the same
expectation recorder, frame waiter and checked JSON evidence writer.

`boot_workshop(stage)` and the desktop entry scripts share `instantiate_workshop()`.
`boot_workshop("pelvis")` supplies earlier work exactly as `--stage=pelvis` does.
`workshop_suite.stage()` uses `scenario_staging.gd` and checks every supplied
identity; this setup is distinct from player-input evidence.

`player_driver.gd` sends keys, clicks and look motion through desktop input. Its
`walk()` follows real character collision. Teleport setup must use `stage_pose()`
or `stage_aim()` with a descriptive label. The historical foot connection suites
stage views.

`build_state(workshop, owner)` is an explicitly bound compatibility view used by
historical heel assertions. It does not select or mutate a runtime build cursor.
Run routine checks through `python3 game/workshop/tools/run_regressions.py`.
Expensive journeys require explicitly requested names through `run_diagnostics.py`;
there is no default full-suite run. See [coverage and migration](../TESTING.md).

Use `model_workshop.gd` for authored model/staging rules (presentation is inert),
`equipment_fixture.gd` for small real-physics scenes, and `source_fixture.gd` for
selected authored meshes with production collision projection. Tests of real
controller transitions must not stub those transitions. `boot_workshop(stage)`
remains for named diagnostic journeys; the routine smoke boots only once at foot.
