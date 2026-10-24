# Task 04b — Fix failures exposed once fresh-scene restores stopped masking them

**Model:** Sol (xhigh) · **Depends on:** 04 (commit `b627cb4`) · **Branch:** `m3-wide-structure`

## Context

Task 04 removed M3 save/restore checks. `reopen()` in `tests/indexed_leg_rail_test.gd`
is now a two-frame wait instead of rebuilding the scene from a snapshot. Most M3
tests pass. These four failures remain:

1. **`arm_delivery_test` and `arm_after_legs_test`**: `left_arm physics body follows between input and physics ticks`
   and the same check for `right_arm`, at `tests/arm_delivery_test.gd` ~line 56. The
   test asserts, immediately after `crane.physics(.45);crane.request("stop")` during
   the guided upend, that `PhysicsServer3D.body_get_state(...TRANSFORM)` equals the
   arm node's `global_transform`. This passed (1173 checks) while every stop went
   through a fresh-scene restore, and fails in continuous play.
   **Treat it as a likely product bug:** the player plays continuously, so the arm's
   collision may lag its visual during upend. `service_crane.gd` `_refresh()` pushes
   `load_body` state; `arm_cassette.gd` `_pose()` and `assembly_runtime.gd` `mount()`
   also move arm bodies. Find which writer leaves the server state stale, and why a
   fresh scene hides it.
2. **`mobile_platform_test`**: `continuous transfer reaches bulky_rear: Clear the work platform ground route (bulky_backpack_crossbeam_2_4Solid).`
   It last passed at 02:36 UTC, before the backpack bulky-fixture inserts were added.
   The platform's authored route to the bulky rear dock now crosses a backpack insert
   crossbeam. Decide whether the route, the dock or the insert's enable state is
   wrong per [final-assembly-plan.md](../../final-assembly-plan.md) (bulky fixture and
   mobile platform sections), and fix the authored data, not the test.
3. **`m3_stock_test`**: `SCRIPT ERROR: Invalid access to property or key 'foot'`.
   **`m3_content_test`**: `M3 supplies 135 foot identities and 40 extension identities`
   and `Eight M24 washers are one shared stock type`. Both last passed at 00:26 UTC,
   before the wider content landed. They look like stale expectations from the old
   single-leg M3. Update them to the current wider content where their intent still
   applies (stock projection, shared stock types, identity counts from the content
   audit). Delete only checks that no longer have a meaning, and list them.

## Rules

- Fix real behaviour bugs in `scripts/` or authored data. Don't weaken or delete
  checks to make them pass, except stale old-M3 expectations in (3), which you must list.
- No M3 save code. No automated walking, reach/visibility or rendered review. Don't
  touch `m3_acceptance_test.gd`, `m3_hip_access_test.gd` or `m3_route_clearance_test.gd`.
- If you change authored data, regenerate through the authoring tools
  (`tools/author_workshop_blockout.py`, `tools/author_leg_prototype.py`) and make
  sure their `--check` passes.
- Don't request sandbox escalation; if Godot needs an editor import, stop and say so.
- Match the surrounding GDScript style.

## Acceptance

Run this; every case must pass:

```sh
python3 game/workshop/tools/run_regressions.py --only indexed_leg_rail_test pelvis_delivery_test chest_delivery_test chest_after_legs_test core_delivery_test core_after_legs_test backpack_delivery_test backpack_after_legs_test backpack_fixture_test arm_cassette_test arm_delivery_test arm_after_legs_test chest_content_test core_content_test mirrored_leg_content_test arm_preflight_test backpack_preflight_test shoulder_content_test wide_foundation_test wide_access_test wide_elevators_test mobile_platform_test rail_gates_test m3_stock_test m3_content_test shared_crane_payload_test m3_workshop_launch m2_crane_launch m2_retention_launch default_workshop_launch source_assets --jobs 4
```

## Finish

Commit: `Fix continuous-play failures exposed by removing M3 restores`.

## Report

- Root cause of each failure, and whether it affects real play.
- Files changed.
- Per-case pass/fail with check counts and `seconds`.
- Any checks deleted as stale, with the reason.
- The commit hash.
