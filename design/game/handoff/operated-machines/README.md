# Operated machines — active handoffs

Follows the
[2026-10-26 machine-operation finding](../../robot-workshop-playtest-checklist.md#machine-operation-and-gantry-access--2026-10-26).
Read that finding, [workshop state](../../workshop-state.md) and repository
`AGENTS.md` before starting. Delete each brief once its work is merged and recorded
in the permanent design documents.

The game will eventually be AR, so controls stay physical and in sight.

| Branch | Worktree | Brief | State |
| --- | --- | --- | --- |
| `gantry-v2-plan` | `/private/tmp/gbs-gantry-v2` | [C6 — v2 coarse plan](C6-v2-coarse-plan.md) | Design only; C5 candidate blocked, revising |
| `operated-rigs` | `/private/tmp/gbs-rigs` | [B — Operated rigs](B-operated-rigs.md) | B1/B2 helpers and B3 design done; leg rig next |

Each branch has one Astra High coordinator (Codex). It does the judgment work and
writes self-contained **Grok task files** into this folder for unambiguous pieces:
exact anchors (quoted strings verified to match once), exact replacement code or
data, run commands, acceptance greps/tests and stop conditions. The parent session
launches Grok; the coordinator then reviews and integrates.

## Shared rules

- Commit scoped, one commit per task, on your branch only. Never touch `main` or
  another worktree.
- Verification: `python3 game/workshop/tools/run_regressions.py --only <touched suites> --jobs 4`.
  No `run_diagnostics.py`, no full suite, no rendered review, and no automated
  walking/reach sweeps. Classify every new suite in `game/workshop/tools/test_inventory.py`.
- Follow the active rules in `workshop-state.md`: saves are snapshots at rest, with
  no migrations (invalid saves are deleted). One workshop, reached through
  `--stage`. Guarded equipment motion pauses rather than refuses. Report mechanical
  evidence separately from player acceptance.
- If you need new part icons, stop and ask for the editor import. Do not run it
  inside the sandbox.
- End every run with a short report: commits, tests run with results, open
  questions, and the Grok task files written.
