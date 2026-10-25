# Workshop save — task handoff

Written 2026-10-25. Each numbered file is a self-contained work order for one
agent. Where a task file and other docs disagree, the task file wins.

## Design in one paragraph

One local slot, `user://workshop-save.json`, written each time the normalised
assembly model changes (a component set, mounted, seated or undone). The file has
`format`, the assembly model, and each machine's `capture()` from its last stop.
The service crane is not saved and always reloads parked. Loading is
synchronous: restore the model, place assembly bodies, `apply()` each machine,
re-sync visuals. The player, pockets, loose and held parts and the manual all
reset. Any invalid file is deleted. There are no migrations, checksums or backups.
A save is only taken when no load is hanging on the crane ("save after delivery").
Tests, tools and `--stage` launches never touch the human save.

Replaying recorded actions was rejected because late-game loads would be too slow.
The previous snapshot system ([archive](../../history/save-resume.md)) was removed
because restoring machines mid-motion and validating each machine cost too much.
This design avoids both.

## Order, models and dependencies

| # | Task | Model | Needs |
|---|---|---|---|
| 01 | [Model capture/restore](01-model-capture-restore.md) | Grok 4.7 High | — |
| 02 | [Equipment last-stop capture + save helpers](02-equipment-rest-capture.md) | Grok 4.7 High | — (parallel with 01; disjoint files) |
| 03 | [Save store, load and workshop hooks](03-save-store-and-hooks.md) | Grok 4.7 High | 01, 02 |
| 04 | [Pause menu: New workshop](04-pause-menu.md) | Grok 4.7 High | 03 |
| 05 | [Round-trip test and at-rest apply fixes](05-roundtrip-test-and-fixes.md) | Grok 4.7 High | 04 |
| 06 | [Stage diagnostic and docs](06-diagnostic-and-docs.md) | Grok 4.7 High | 05 |

## Launching

```
agent -p --force --sandbox disabled --trust --model grok-4.7-high \
  --workspace /Users/blakeyboy/gundam-save \
  "Read AGENTS.md, then read and execute design/game/handoff/save/NN-<name>.md exactly."
```

The tasks run in the git worktree `/Users/blakeyboy/gundam-save` on branch
`save-system`, so another session on `main` is unaffected. Every task commits
**only its own paths** (`git commit -m "…" -- <paths>`), never `git add -A`.

## Rules for every task

- Work in the workspace root (`/Users/blakeyboy/gundam-save`). All paths are relative to it. Touch only the files the task lists.
- Before each edit, confirm that its anchor matches exactly once with `grep -cF`. If the
  count is not 1, stop and report. Don't improvise a different location.
- Verify only with `python3 game/workshop/tools/run_regressions.py --only <names>`.
  Never run `run_diagnostics.py`, never run `run_regressions.py` without `--only`, and
  never raise a time budget.
- If the task creates a new `.gd` file, run
  `./play.command --headless --editor --import --quit` once afterwards so Godot writes
  its `.uid` file. Commit that `.uid` file with the task.
- Never use `class_name` in new scripts. Use `preload` constants, so no global class
  cache update is needed.
- Stop and report (don't loop) after two failed attempts at the same acceptance
  check. Include the failing output.
- Finish with a short report: files changed, the commands you ran with their PASS/FAIL
  lines, and the commit hash.
