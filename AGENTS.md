# Project skills

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

# Self-directed delegation

This is a standing, explicit request to use subagents and parallel agent work
when doing so would materially improve speed, quality or context management.
Choose when and how to delegate without asking for permission again, unless the
user gives a different instruction for the current task.

For feedback containing multiple items, track every item, identify dependencies
and delegate bounded, independent work where useful. Keep closely coupled
changes coordinated and work sequentially when delegation adds more overhead
than value. Do not spawn agents just to increase parallelism.

Give each subagent a clear scope, relevant context, expected output and validation
criteria. For implementation work, assign distinct file ownership where possible
and coordinate shared-file edits. Avoid duplicate investigations and overlapping
edits. Subagents should return concise findings, changes, checks and unresolved
issues, and should not delegate further unless explicitly assigned to do so.

The primary agent remains responsible for the whole request: continue useful
independent work while subagents run, collect and review their results, integrate
changes, resolve conflicts and perform appropriate final validation. Report what
was completed and any remaining limitations. Delegation does not expand the
task's authorization or bypass project skills, permissions or required reviews.

## Subagent model and effort selection

This is explicit authorization to choose and override each subagent's model and
reasoning effort independently of the orchestrator.

Before spawning, assess the task's ambiguity, reasoning difficulty, scope and
verification requirements. Choose the lightest available combination likely to
complete it reliably.

Use these starting points:

- `gpt-6-luna` / `low`: extraction, inventories, mechanical edits and
  straightforward checks with clear acceptance criteria.
- `gpt-6-luna` / `high`: bounded code exploration and tracing with clear
  questions and evidence requirements.
- `gpt-6.1-sol` / `medium`: default for implementation, debugging and
  substantive review.
- `gpt-6.1-sol` / `high`: complex logic, cross-file changes, subtle edge
  cases and ambiguous investigations.
- `gpt-6-astra` / `high`: unusually difficult architecture, diagnosis or
  synthesis where stronger reasoning materially improves the result.
- `xhigh` or `max`: exceptional tasks with a concrete reason that the
  additional reasoning is likely to help.

Do not inherit an expensive orchestrator configuration automatically. Choose
model and effort explicitly for each delegated task.

Use only combinations supported by the current client. When overrides require a
fresh context, use `fork_turns="none"` if that is the available mechanism and
provide a self-contained task brief including relevant constraints, file
ownership and validation criteria.

Escalate when evidence shows the initial choice is insufficient. Pass existing
findings to the replacement agent to avoid repeating work.

Briefly report each subagent's task, selected model/effort and reason. The primary
agent remains responsible for reviewing and validating results.

# Working with feedback

Treat feedback as a design problem to evaluate, not a checklist to follow blindly.
Point out overlooked constraints, conflicting requirements and practical tradeoffs.
Push back with a concrete reason when a requested change would hurt usability or
correctness, and ask focused questions when the answer materially changes the work.
Make reasonable implementation choices and continue authorized work while resolving
independent questions. This applies to all feedback, not only UI changes.
