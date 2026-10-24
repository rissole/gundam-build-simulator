# Task 02 — Record the save/checkpoint deferral and trim the plan ledger

**Model:** Grok · **Depends on:** 01 · **Expected size:** 3 Markdown files edited, 1 created

## Rules

- Edit only the files named here. Insert the replacement text exactly as given.
- Locate passages by the quoted start/end phrases, not by line numbers. The files
  are hard-wrapped, so a phrase may continue onto the next line; treat a line break
  inside a phrase as a space when matching.
- If a quoted phrase isn't found exactly once, stop and report it.
- Do not run Godot or tests; this task is docs only.

## Edit A — move the evidence narrative out of the plan

File: `design/game/m3-wide-workshop-plan.md`.

1. Find the passage that **starts** with `Earlier foundation mechanical evidence:` and
   **ends** with the sentence `Preserve subsequent human feedback separately from these mechanical results.`
   (inclusive; it is about 120 lines long and sits just before `Remaining work, in implementation order:`).
2. Create `design/game/history/m3-wide-evidence-20261024.md` containing:
   ```markdown
   # M3 wider workshop — mechanical evidence through the paused review, 2026-10-24

   Moved verbatim from the plan's implementation ledger. Mechanical results only;
   walking, reach, visibility, connection access and presentation remain the user's
   playtest. Linked run directories are local and not committed.

   ```
   followed by the passage, verbatim. Then fix relative links in the moved text:
   replace every `](../../game/` with `](../../../game/` and every `](../arms/`
   with `](../../arms/`.
3. In the plan, replace the removed passage with this single paragraph:
   ```markdown
   Mechanical evidence for every increment, through the paused 18-case run, is in
   the [evidence record](history/m3-wide-evidence-20261024.md). These are mechanical
   results only; walking, reach, visibility, connection access and presentation
   remain the user's playtest.
   ```

## Edit B — replace the plan's "Remaining work" list

Same file. Find the passage that **starts** with `Remaining work, in implementation order:`
and **ends** with `Pause for that review; do not describe it as the completed workshop or full milestone acceptance.`
(inclusive). Replace it with:

```markdown
Remaining work, in implementation order. The executable task breakdown is in
[handoff/README.md](handoff/README.md); its task files override older wording here.

1. Baseline commit and the right-foot carrier return in the full-sequence test (task 01).
2. Turn off M3 saving and remove save/restore checks from M3 tests (tasks 03–04).
   See [Saves and checkpoints](#saves-and-checkpoints).
3. Extract the scripted stage sequence shared by tests and the `--m3-stage=<name>`
   development launch flag (tasks 05–06).
4. Add one generic receiving interface and a shared occupancy register, then the
   pauldron carriers/panels and release of the supplied arm joint/digit restraints (task 07).
5. Head, in its specified order: crane pieces, then hand-carried pieces and crown
   (tasks 08–09), including the head-piece bulky-fixture inserts.
6. User playtest handoff checklist (task 10).

Deferred and unassigned: M3 saves and checkpoints; the chest's 60° bare-frame
service tilt (only needed once chest preparation is built; the prepared chest stays
upright); removing the historical M3 branch in `leg_rail.gd` and obsolete geometry
keys; migrating the existing core, backpack and shoulder receivers.
```

## Edit C — the "Saves and checkpoints" section

Same file. Find the heading `### Saves and checkpoints`. Directly below the heading
(before the paragraph starting `Continue using the M3 save slot.`), insert:

```markdown
**Deferred on 2026-10-24.** The user removed M3 saving and the pause-menu
checkpoints from this adaptation until the broad workshop structure exists.
Maintaining interrupted-motion saves for every new machine added large amounts
of work and was repeatedly wrong. M3 launches without a save slot, and Restart
starts again from the launch point. Mechanical tests no longer save or restore
M3 sessions. To inspect later stages, the development flag `--m3-stage=<name>`
runs the same scripted equipment sequence as the mechanical tests and then starts
paused. That is supplied progress, not playtest evidence, and not a save. When
saves return, save only at rest (no equipment moving, every load on a support),
which removes mid-motion validation. The default foot workshop and the M2 trials
keep their existing saves. The original requirements below are preserved for
that later work.

*Preserved requirements (not active):*
```

Also in the same file, find the bullet
`- Add pause-menu playtest checkpoints for inspecting later workshop stages quickly.`
and replace it with
`- Add pause-menu playtest checkpoints for inspecting later workshop stages quickly. *Deferred 2026-10-24; see [Saves and checkpoints](#saves-and-checkpoints).*`

## Edit D — active state document

File: `design/game/leg-workshop-next-steps.md`.

1. Under the heading `## Current work: implement the wider M3 workshop`, find the
   passage that **starts** with `The user requested an **intermediate human review on 2026-10-24**`
   and **ends** with `that does not replace the failed full-sequence integration check.`
   (two paragraphs, inclusive). Replace it with:
   ```markdown
   On 2026-10-24 the user paused the Codex implementation for intermediate review
   after 6h20m, judging it too slow and suspecting the architecture. A review of the
   session log and working tree found: 62 min waiting on one sandbox permission
   prompt (Godot editor import of new part icons); about 25–35 min of model
   generation per section that never decreased; and, per section, a bespoke receiver
   controller, direct checks against other machines, growing crane-contract flags
   and another layer in a linear test-inheritance chain whose fresh-scene restores
   took about three quarters of its runtime. The user then deferred M3 saving and
   checkpoints (see the [plan](m3-wide-workshop-plan.md#saves-and-checkpoints)) and
   requested a `--m3-stage` development launch flag. Work resumes from the task
   files in [handoff/README.md](handoff/README.md); they override older instructions
   in this document where they differ.

   The last regression run before review passed 17 of 18 cases. The full sequence
   stopped before cassette pickup because the test never returned the right-foot
   carrier; task 01 adds that step. The isolated arm branch's 299 mechanical checks
   do not replace the full-sequence check.
   ```
2. In the table under `## Player feedback and constraints to retain`, add these two
   rows directly below the header separator row (`| --- | --- |`):
   ```markdown
   | Implementation took 6 h+; the user suspected poor architecture (2026-10-24) | Reviewed; see Current work. Before pauldrons/head, add one generic receiving interface and an occupancy register so new sections are mostly data. One fresh agent session and one commit per task; run the Godot import before work that adds part icons. |
   | Saving and checkpoints keep adding work and are often wrong (2026-10-24) | Deferred for M3 until the structure exists. `--m3-stage=<name>` supplies earlier progress for inspection. Default foot and M2 saves are unchanged. |
   ```

## Finish

```sh
git add -A
git commit -m "Record M3 save/checkpoint deferral and point the plan at the handoff tasks"
```

## Report

List each edit (A–D) as done or not found, and give the commit hash.
