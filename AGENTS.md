# Project skills

When continuing the workshop prototype, read the current
[playtest feedback and next steps](design/game/leg-workshop-next-steps.md) before
planning changes. It records unresolved player-facing issues beyond the historical
headless milestone results.

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
criteria. Assign a coherent outcome with end-to-end acceptance criteria, shared
interfaces, dependencies and an integration point. State which decisions the
agent can make independently. For implementation work, assign distinct file
ownership where possible and coordinate shared-file edits. Avoid duplicate
investigations and overlapping edits. Subagents should return completed work with
concise findings, checks, evidence paths and unresolved issues, and should not
delegate further unless explicitly assigned to do so.

The primary agent remains responsible for the whole request: continue useful
independent work while subagents run, collect and review their results, integrate
changes, resolve conflicts and perform appropriate final validation. Report what
was completed and any remaining limitations. Delegation does not expand the
task's authorization or bypass project skills, permissions or required reviews.

The primary agent is accountable for acceptance of the player journey across
delegated systems. Delegate implementation and integration of tightly coupled
systems to a capable owner; the primary should review evidence and resolve
cross-owner decisions without routinely reconstructing agents' work. For a new
workshop interaction, establish one representative loop through ordinary player
controls before expanding the remaining content. Give tightly coupled racks,
cranes, fixtures, lifts and travel routes one coordinated spatial owner; agree
their shared dimensions and interaction boundaries before parallel implementation.
Delegate independent content or bounded implementation against that contract.

## Subagent model and effort selection

This is explicit authorization to choose and override each subagent's model and
reasoning effort independently of the orchestrator.

Before spawning, assess the task's ambiguity, reasoning difficulty, scope and
verification requirements across the full assignment. Optimize for total delivery
cost, including coordination, integration and rework, rather than the cheapest
individual agent. Give complex assignments enough reasoning capacity from the
start; reassess model, effort and ownership when scope expands.

Use these starting points:

- `gpt-6-luna` / `low`: extraction, inventories, mechanical edits and
  straightforward checks with clear acceptance criteria.
- `gpt-6-luna` / `high`: bounded code exploration and tracing with clear
  questions and evidence requirements.
- `gpt-6.1-sol` / `medium`: bounded implementation, debugging and review with
  clear interfaces and limited cross-system dependencies.
- `gpt-6.1-sol` / `high`: starting point for complex implementation, cross-system
  geometry, state and interaction work, subtle edge cases and ambiguous
  investigations.
- `gpt-6-astra` / `high`: unusually difficult architecture, diagnosis or
  synthesis where stronger reasoning materially improves the result.
- `gpt-6.1-sol` or `gpt-6-astra` / `xhigh`: highly coupled or ambiguous work
  where a concrete reasoning challenge justifies the additional effort.

Do not inherit an expensive orchestrator configuration automatically. Choose
model and effort explicitly for each delegated task.

When selecting a coordinator for a future run, start with `gpt-6.1-sol` / `high`
for briefs, integration decisions and acceptance checks. Reserve more expensive
configurations for identified reasoning needs. This is configuration guidance,
not a claim that an active agent can change its own model.

Use only combinations supported by the current client. When overrides require a
fresh context, use `fork_turns="none"` if that is the available mechanism and
provide a self-contained task brief including relevant constraints, file
ownership and validation criteria.

Escalate when evidence shows the initial choice is insufficient. Pass existing
findings to the replacement agent to avoid repeating work.

At significant integration checkpoints, review remaining design risks, elapsed
time and token usage when available before expanding or reopening assignments.
Track why assignments reopen and how much implementation falls back to the
coordinator. Repeated handoffs or repairs call for revisiting ownership, contracts
or agent capacity. Batch follow-ups into coherent outcomes; use lighter agents
for genuinely bounded work without fragmenting coupled problems to reduce cost.
Use concise findings and evidence paths rather than rereading successful logs.
These checkpoints do not introduce approval gates or an unrequested resource cap.

Briefly report each subagent's task, selected model/effort and reason. The primary
agent remains responsible for reviewing and validating results.

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
