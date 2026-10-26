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

## Morning review steps

### Gantry (on `main` now): `./play.command --stage=pelvis` (or your normal save)

1. Lowest level (Y8.4), both sides of the hip assembly: do the railings now match? Can you
   reach the side of the hip assembly equally from left and right?
2. Walk onto and off each elevator at every level: are the old 300 mm landing slots gone,
   and does the car still run cleanly past the new plates (20 mm clearance)?
3. Check the hinge-apron edges on the outer walkways: is there a new railing where you
   could previously walk off?
4. **Assumption to confirm:** C kept the 1.55 m opening between each hip finger (ends Z25.8)
   and the hip apron (starts Z27.35) as a *deliberate* robot/leg work opening. If that is
   one of the "gaps easy to fall through", say so; it needs a guard or a removable plate.
