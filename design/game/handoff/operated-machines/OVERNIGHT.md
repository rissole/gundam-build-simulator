# Overnight coordination log — 2026-10-27

The user handed over coordination overnight. Everything below is for their morning
review. Mechanical checks are listed separately from things only a playtest can judge.

## Standing assumptions (made without the user)

1. **Human gates hold.** B3 (operated leg rig) does not start before the crane
   playtest (checkpoint A). B5 (foot rig) and any v2 gantry build do not start
   either. Overnight work is limited to A (crane), C2/C3 (gantry fixes) and their
   Grok tasks.
2. **C3 scope.** "Mirrored railings" means making the left/right wing and rear
   hip-bridge guards true mirrors, as found in the C1 audit (a 180° copy reversed the
   fore/aft guards). It also means giving both sides the same side access to the hip
   assembly from the lowest level. No new walkways beyond that.
3. **Merging.** I merge `gantry-access` (C2 + C3) into `main` only if its routine
   suites pass when I re-run them. These are small fixed-collision changes, so you
   can playtest them with the normal `./play.command`. `crane-operator-view` stays
   **unmerged** on its branch for your playtest, because it replaces the crane
   console. Launch it from its worktree (see below).
4. **Failures.** If an agent's work fails acceptance and one coordinator
   repair run doesn't fix it, I stop that branch and record it here. I don't loop.

## Timeline

- C1 audit, C2 task file and C4 concept committed on `gantry-access`; C4 approved
  as direction.
- A1 audit stopped as specified; you chose approach entry; A resumed from A2.
- B1/B2 helpers and the B3 design committed on `operated-rigs`; paused at gate A.
- Grok C2 committed `cd94428` (10 landing plates, 8 hinge-edge rails). Parent re-run: blockout `--check` byte-identical; gantry_dressing 137, wide_elevators 93, smoke 31, access_lift 45 checks pass (10.1 s). Mechanical only.
- C phase 2 done: `15154c6` C2 review (no defects), `7d2ea40` C3 mirror repair, `f3b8ef2` C4 marked approved as direction.
  Cause found: the right wing was a 180° copy, so its rail crossed the hip-finger entrance (Z24.68)
  and the right rear-leaf guards faced the hip. Guards now mirror about X13 in all 7 modes and 30
  fold poses (new assertions in `gantry_dressing_test`).
- **Merged `gantry-access` into `main`** (`b42733f`). Checklist conflict resolved with the branch
  version. Parent re-run on main: blockout `--check` passes; gantry_dressing 219, wide_elevators 93,
  smoke 31, access_lift 45 checks pass. Mechanical only.
- A phase 1 done on `crane-operator-view`: `49772cf` A2 guarded travel at per-task carry
  heights, `688a342` A3 CCTV view, `1a6edc0` A4 capture gate + held approaches + spreader
  deploy, `45fc7f3` A6 first-use/repeat manual. A reports 13 routine suites passing.
- Grok chain (sequential, crane worktree): `dd85790` A5 staging/save fixtures drive the crane
  through `crane_drive`; `dddc326` A7 new routine `crane_operator_test`; `1771456` A8 deferred
  auto-attach power-up recorded beside the open PDA decision.
- A phase 2: `741c47a` fixes held input not being released after a refused automated
  approach; `b937dec` playtest guide + report. Stopped at checkpoint A.
- Parent re-run on `crane-operator-view`: 12 suites pass (crane_operator 78, crane_console 8,
  crane_policy 26, manual objectives/progress/completion/panel/control-guidance
  109/33/38/14/40, stage_contract 12, equipment_motion 83, save_roundtrip 29, smoke 31;
  21.2 s). Mechanical only; no rendered review, no walking.
- Backed up your save to `~/Library/Application Support/Godot/app_userdata/Gundam Build
  Simulator/workshop-save.main-backup-20261027.json` (see the crane warning below).

## Where everything is

| Branch | State | Merged? |
| --- | --- | --- |
| `gantry-access` | C1–C3 done, C4 approved as direction | **Yes** (`b42733f`) |
| `crane-operator-view` | A1–A8 done, integration reviewed | No: waiting for your checkpoint A |
| `operated-rigs` | B1/B2 helpers + B3 design | No: B3 waits for checkpoint A |

## Morning review steps

### Gantry (on `main` now): `./play.command -- --stage=pelvis` (or your normal save)

1. Lowest level (Y8.4), both sides of the hip assembly: do the railings now match? Can you
   reach the side of the hip assembly equally from left and right?
2. Walk onto and off each elevator at every level: are the old 300 mm landing slots gone,
   and does the car still run cleanly past the new plates (20 mm clearance)?
3. Check the hinge-apron edges on the outer walkways: is there a new railing where you
   could previously walk off?
4. **Assumption to confirm:** C kept the 1.55 m opening between each hip finger (ends Z25.8)
   and the hip apron (starts Z27.35) as a *deliberate* robot/leg work opening. If that is
   one of the "gaps easy to fall through", say so; it needs a guard or a removable plate.

### Crane view (branch only): checkpoint A

**Save warning:** both checkouts use the same save file, and the crane branch changes
the crane's save data. Invalid saves are deleted, not migrated. Saving on the crane branch
(Save, Save & quit, or closing the window after a build change) can therefore make `main`
delete that save later. Your current save is backed up (path above). To restore it, copy the
backup over `workshop-save.json`.

```sh
cd /private/tmp/gbs-crane
./play.command -- --stage=pelvis
```

1. Press **M** for the hip assembly delivery page (first use: detailed steps).
2. Aim at the crane console, press **E** to enter the CCTV view. Use **WASD** to strafe,
   **Shift** for fine movement. Is the view readable? Can you tell the target, the drop line
   and the carry height apart?
3. Move the reticle away from the gold approach-entry ring: does it explain why you
   can't descend? Then align it.
4. **Hold Space** to run the approach and release it to pause. Watch the spreader reshape for
   the load. Does holding feel good, or tedious on long approaches (chest, arms)?
5. The view exits after the descent. Walk over and hand-attach the connectors. Re-enter,
   hold Space to lift, strafe to the delivery entry and hold Space again. **R** switches
   between delivery and Put back. **Esc/Q** leaves the view.
6. On a later crane trip, the manual should give only the goal plus a working
   **Procedure: p.N** link.
7. **Assumption to confirm:** each load travels at its own carry height. That doesn't
   guarantee it can pass over every part of the robot, so it may stop with a named
   obstruction. Say if those stops are annoying.

After the crane playtest, say "go" for B3 (operated leg rig) or list changes first. B's
open questions for checkpoint B (jog speeds, panel grouping, foot lead-in) are in the
checklist on the `operated-rigs` branch.

