# C6-G1 — Design pointers and seven overview sheets

Agent type: Grok. Branch `gantry-v2-plan` only, `/private/tmp/gbs-gantry-v2`.
Read repository `AGENTS.md`, `design/game/workshop-state.md`, this folder’s
`README.md` and `C6-v2-coarse-plan.md`. Design only; no game/layout/generator/test
changes, no push, no other worktree. This is an exact mechanical task; any new
geometry, interpretation or changed anchor goes back to Astra High.

Status: the C6 coordinator applied and reviewed this task as part of the scoped
C6 commit. A parent-launched Grok replay should detect the exact after-text and
leave it unchanged. Do not launch yourself or create a separate commit.

## Exact replacements

Each BEFORE anchor was verified to match once before the coordinator applied it.
For each file: if AFTER exists exactly once, skip; otherwise require BEFORE once
and replace it once with AFTER. If neither condition holds, stop without guessing.

File: `design/game/final-assembly-plan.md`

BEFORE:
```text
**approved as direction 2026-10-27; build not approved**
```

AFTER:
```text
**approved as direction 2026-10-27; build not approved**

**C6, 2026-10-27:** [Coarse aft-tower plan](gantry-v2/README.md) supersedes this concept’s fixed shell/shaft assumptions; hip support remains unresolved and the build is not approved.
```

File: `design/game/robot-workshop-playtest-checklist.md`

BEFORE:
```text
- [ ] Dimensioned v2 plan (in progress), then separate v2 build approval. No v2 construction is approved or implemented.
```

AFTER:
```text
- [ ] Review the coarse v2 plan and resolve support, then separate v2 build approval. No v2 construction is approved or implemented.
- **2026-10-27 — C6 design only:** [Aft-tower coarse plan](gantry-v2/README.md) clears the proposed parked exit but retains blocking hip-support/route/headroom overlaps; larger building, carrier-at-current-height and alternate support topology remain open choices. Keep accepted finish, gap/mirror repairs and assembly challenge; no new player acceptance.
```

File: `design/game/workshop-state.md`

BEFORE:
```text
| [gantry-v2/README.md](gantry-v2/README.md) | Reviewing the dimensioned two-tower candidate, measured envelopes, collision conflicts or proposed Y8.4 support-handoff slice; design only, build not approved |
```

AFTER:
```text
| [gantry-v2/README.md](gantry-v2/README.md) | Reviewing C6’s coarse aft-tower layout, enlarged shell/door, rebuilt lifts, growth envelopes and unresolved hip-support gates before a Y8.4 slice; design only, build not approved |
```

## Exact generation and acceptance

From the worktree root:

```sh
python3 design/game/gantry-v2/draw.py
python3 design/game/gantry-v2/check.py
```

`draw.py` must report seven sheets. The checker intentionally returns1 while
support gates remain: its last line is `FAIL: 46/67 coarse checks pass; 21
unresolved. No gameplay/player acceptance.` Do not change geometry to force0.
The committed coordinator report is the authority if a later authorized plan
revision changes that count; stop and ask the parent to refresh this task.

Acceptance: exactly `level-8.4.svg`, `level-11.2.svg`, `level-14.svg`,
`level-16.4.svg`, `front.svg`, `side.svg`, `exit-route.svg`; all parse as XML.
Every AFTER block above appears exactly once. No tight sheets/index, CSV datum
inventory or `__pycache__` remain. Entire gantry-v2 folder stays below1,000,000
bytes. Review `git diff --check` and `git diff --name-only`: only design artifacts
and the three records above may change. No game or test files may change.

Stop after returning the exact file list, generation/checker results and any
unexpected mismatch to the coordinator. No regression/diagnostic run, probe,
editor import, game launch, rendered review, walking/reach sweep or build work.
The parent session owns any Grok launch; Astra owns judgment and final integration.
