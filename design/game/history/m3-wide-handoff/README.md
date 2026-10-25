# M3 wider workshop: restructure and finish — task handoff

> **Archived 2026-10-24.** All tasks are done. The current state, rules and deferred items are in [the workshop state](../../workshop-state.md).

Written 2026-10-24 after reviewing the paused 6h20m Codex run on
[robot-workshop-plan.md](../../robot-workshop-plan.md). Each numbered file is a
self-contained work order for one agent. Where a task file and older plan text
disagree, the task file wins.

## Why these tasks exist

- The run cost ~25–35 min of model generation per section, and that never came down.
  Every section added its own receiver controller, direct checks against other machines,
  more crane-contract flags, its own authoring script and another layer in a test chain.
- 62 min was one blocked permission prompt: a Godot editor import for new part icons.
- Fresh-scene save restores were about 75% of the full-sequence test runtime
  (each M3 boot ≈2.8 s, ~33 restores before the arms).
- The user deferred M3 saving and pause-menu checkpoints until the broad structure
  exists. A development launch flag, `--m3-stage=<name>`, replaces checkpoints for
  inspecting later stages.

## Order, models and dependencies

| # | Task | Model | Needs | Notes |
|---|---|---|---|---|
| 01 | [Baseline commit + right-foot carrier return](01-baseline-and-carrier-return.md) | Grok | — | Creates branch `m3-wide-structure` |
| 02 | [Record the deferral and trim the plan ledger](02-docs-deferral.md) | Grok | 01 | Docs only; can run alongside 03 |
| 03 | [Turn off M3 saving](03-disable-m3-saves.md) | Grok | 01 | Small |
| 04 | [Remove save/restore checks from M3 tests](04-strip-m3-save-tests.md) | Grok | 01, 03 | Mechanical, with a grep acceptance check |
| 05 | [Shared M3 stage sequence + flatten the test chain](05-m3-stage-sequence.md) | Sol (xhigh) | 04 | Defines the API that 06 uses |
| 06 | [`--m3-stage` launch flag](06-m3-stage-flag.md) | Grok | 05 | You can playtest late stages after this |
| 07 | [Generic receiver, occupancy register, pauldrons](07-receiver-occupancy-pauldrons.md) | Sol (xhigh) | 05 | Architecture change; optional Opus review afterwards |
| 08 | [Head: baseplate, sides, top](08-head-crane-pieces.md) | Sol | 07 | Should be mostly data on 07's receiver |
| 09 | [Head: sensors, faceplate, mask, crown](09-head-hand-pieces-and-crown.md) | Sol (Grok possible) | 08 | See the note in the file |
| 10 | [Playtest handoff checklist](10-playtest-checklist.md) | Grok | 09 | Done — see ../robot-workshop-playtest-checklist.md |

Run them in order. Only 02 is safe to run in parallel with another task (it touches
docs only). Everything else shares tests and the regression runner.

**Opus, if you have budget:** a short review after 05 (is the stage API clean?) and
after 07 (is the pauldron mostly data, with no new crane flags?) is worth more than
using Opus for any implementation task.

## What you do

1. **Before a task that adds part icons (07, 08, 09)**, and whenever an agent asks,
   run the Godot import yourself: `./play.command --headless --editor --import --quit`
   (or `! ./play.command --headless --editor --import --quit` inside Claude Code).
   Every task tells agents not to request sandbox escalation for it.
2. **Start each task in a fresh session** with:
   `Read AGENTS.md, then read and execute design/game/handoff/NN-<name>.md exactly.`
3. **Check each agent's report** before starting the next task. Every task ends
   with a commit, so a bad task can be reverted with `git revert`.
4. **Playtest** with `./play.command -- --m3-stage=<name>` once 06 is done. Record
   findings in the [playtest checklist](../../robot-workshop-playtest-checklist.md).

## Deferred and unassigned (do not start without a decision)

- M3 saving, save validation and pause-menu checkpoints. When they return, save
  only at rest: no equipment moving, every load on a support.
- The chest's 60° bare-frame service tilt. It only matters once chest *preparation*
  is built; the prepared chest stays upright.
- Removing the historical M3 branch in `leg_rail.gd` (M2 still uses that controller)
  and obsolete geometry keys.
- Migrating the existing core, backpack and shoulder receivers onto task 07's
  generic receiver.

## Rules every task repeats

- Repo root `/Users/blakeyboy/gundam-build-simulator`; Godot project `game/workshop`.
- Branch `m3-wide-structure`; one commit at the end with the given message.
- No automated walking, reach/visibility sweeps or rendered review. The user
  playtests those.
- No sandbox escalation for Godot imports; ask the user instead.
- No M3 save code or save checks.
- Regression runner: `python3 game/workshop/tools/run_regressions.py --only <cases> --jobs 4`.
  It prints `REGRESSION_OUTPUT <dir>`; read `<dir>/results.json` (`passed`, and
  per-case `summaries`/`errors`/`seconds`); logs are `<dir>/<case>.log`.
