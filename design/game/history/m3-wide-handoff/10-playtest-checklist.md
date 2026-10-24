# Task 10 — User playtest handoff checklist

**Model:** Grok · **Depends on:** 09 · **Expected size:** 1 new Markdown file, 2 small doc edits

## Goal

Write the short checklist the user follows to playtest the complete wider M3
workshop. This replaces the old walked-acceptance gate (plan §4, "User playtest
handoff"). Docs only: don't edit code or tests.

## Rules

- Create/edit only the files named below.
- Use the stage names that actually exist in `game/workshop/scripts/m3_stages.gd`
  (`STAGES`), and copy each stage's title from `TITLES`.
- Keep it under ~80 lines. Plain, practical wording; no evidence narratives.

## Steps

1. Read `game/workshop/scripts/m3_stages.gd` (STAGES, TITLES), §4 "User playtest
   handoff" in `design/game/robot-workshop-plan.md`, and the M3 launch section in
   `game/workshop/README.md`.
2. Create `design/game/robot-workshop-playtest-checklist.md` with:
   - **How to launch:** `./play.command -- --m3-workshop` for a fresh start, and
     `./play.command -- --m3-stage=<stage>` for each stage. Note that stage
     preparation is supplied progress and nothing is saved.
   - **A table, one row per stage:** command, what to try, what to watch for.
   - **These checks, each as a checkbox line:** walking and elevator boarding at
     every level; connection visibility, reach and tool approach; rigging
     attachment and release; carrying and shelves; equipment controls (crane
     console, local Advance/Stop/Return, locks, latches); overall flow and the
     manual's suggested order.
   - **A "Findings" section** with an empty table: date | stage | issue or positive
     finding | severity.
   - **A closing line:** mechanical test passes are separate from these playtest
     results.
3. In `design/game/leg-workshop-next-steps.md`, below the paragraph that ends
   `they override older instructions in this document where they differ.`, add:
   `The playtest checklist for the complete wider workshop is [robot-workshop-playtest-checklist.md](robot-workshop-playtest-checklist.md); record results there and summarize them here.`
4. In `design/game/handoff/README.md`, change the row for task 10 so its Notes
   column reads `Done — see ../robot-workshop-playtest-checklist.md`.

## Finish

Commit: `Add the wider M3 playtest checklist`.

## Report

The file path and the commit hash.
