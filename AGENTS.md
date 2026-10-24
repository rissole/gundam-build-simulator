# Project skills

When continuing the workshop prototype, read the current
[playtest feedback and next steps](design/game/leg-workshop-next-steps.md) before
planning changes. It records unresolved player-facing issues beyond the historical
headless milestone results, and its document table says which other design
documents a task needs. Files in `design/game/history/` are archives: open one
only when a current document links to it for a specific fact.

For taking a robot component from its high-level design Markdown through detailed
parts/interfaces, exploded references, source models and playable manuals, read
and apply [gundam-component-pipeline](.agents/skills/gundam-component-pipeline/SKILL.md).
Continue from the requested stage; do not restart completed design or expand a
local fix into a full component pipeline.

For designing, implementing, extending or reviewing in-game assembly manuals or
module builds, read and apply
[gundam-assembly-review](.agents/skills/gundam-assembly-review/SKILL.md) automatically.
Also apply it to shared placement, geometry or mounted-assembly behavior changes
that affect those builds.

Scale the workflow to the task: design-only work needs a review plan; implemented
builds need the relevant part/manual audit and behavior checks. Run a rendered
visual review only when the user explicitly requests one. Visual review is not a
prerequisite for committing or pushing changes. Unrelated UI, general documentation
and skill maintenance do not require the full assembly review workflow.

# Working with feedback

Treat feedback as a design problem to evaluate, not a checklist to follow blindly.
Point out overlooked constraints, conflicting requirements and practical tradeoffs.
Push back with a concrete reason when a requested change would hurt usability or
correctness, and ask focused questions when the answer materially changes the work.
Make reasonable implementation choices and continue authorized work while resolving
independent questions. This applies to all feedback, not only UI changes.

When feedback is deferred, preserve every item, positive findings and unresolved
options in the relevant state/next-steps document. Link it from the milestone so
the next session can resume without treating historical test passes as usability
approval. Keep automated behavior, inspected presentation and player feedback
distinct when reporting completion.

# Routine verification

Use `python3 game/workshop/tools/run_regressions.py` (or `--only NAME ...`) for
routine verification. It selects fast model/component/source tests and one startup
smoke, warns above 60 seconds, and reports slowest cases. Improve slow tests; do
not increase the performance budget or interpret a warning as a correctness pass.

Expensive diagnostics require an explicit user request and named cases through
`python3 game/workshop/tools/run_diagnostics.py --only NAME ...`. Never run them
as automatic extra verification, enumerate all names to emulate a full suite, or
fall back to them after routine failures. Keep new tests isolated; classify every
runnable suite in `game/workshop/tools/test_inventory.py`. See
[coverage migration](game/workshop/tests/TESTING.md). Retired old-room/access tests
stay retired; human playtesting and optional requested visual review remain separate.
