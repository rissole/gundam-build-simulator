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
Run all headless suites, the launch smoke check and Python source assets through
`python3 game/workshop/tools/run_regressions.py`. Rendered review is separate.
