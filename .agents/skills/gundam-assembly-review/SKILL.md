---
name: gundam-assembly-review
description: >-
  Design, implement and verify assembly manuals and module builds in Gundam Build
  Simulator. Use when adding or changing module recipes, manual steps, part
  allocation, attachment geometry, or mounted assembly behavior. Includes
  step-specific component audits and optional rendered visual review. Does not apply to
  unrelated UI, general documentation, or other games' manuals.
---

# Gundam assembly review

Keep collecting pieces and following the manual at the center of play. Preserve
the desktop-playable, future-AR direction and comfortable assisted handling.

Use [the project map](references/project-map.md) to find current authoring sources,
runtime code, construction references and verification commands. Resolve project
paths against the active repository, including when this skill is installed by
symlink. Read the relevant design and construction files before authoring a build.

## Match the requested work

- **Design only:** produce the parts/slot/dependency design, step outlines and
  concrete verification plan. Do not implement content or run a capture campaign
  merely because this skill is active.
- **New or changed build implementation:** complete the relevant authoring,
  inventory/manual audit and gameplay checks. Shared geometry or parenting changes
  also affect other builds using that behavior. Rendered review is optional and runs
  only when the user explicitly asks for it; it is never a commit or push gate.
- **Small instruction edit:** audit the affected instructions and component lists.
  Run broader gameplay checks when the edit changes sequence, targets or quantities.

## Keep review proportional

Choose the scope before running tools: changed parts/pages, affected receiving
connections and downstream closures, relevant tests, and the evidence needed to
finish. Use the accepted baseline for unchanged work. A whole-module review is
appropriate for a new module, an explicit whole-manual request, or changes whose
effects span the module. Shared code changes require an impact assessment, not an
automatic review of the entire workshop.

- Batch related repairs before export/import. Run cheap geometry/data checks
  before broader gameplay checks. Rerun passing tests only for new changes or
  unresolved concerns.
- When visual review is explicitly requested, inspect contact sheets first and
  open individual images only for ambiguous connections. Retain capture hashes;
  never relabel old evidence as freshly captured.
- Keep logs, fingerprints, image inventories and page decisions in files. Read
  summaries and failures into context, not full manifests or successful logs.
  Maintain one compact review status with remaining findings and evidence paths
  so a continuation can resume without replaying completed work.
- Use the fast routine runner for normal verification. Named expensive diagnostics
  require an explicit user request; never run them automatically as extra verification.
  A runtime warning calls for faster tests, not a larger performance budget.
- Stop when relevant checks for the requested scope pass.
  Report unrelated findings separately rather than extending the task. If work
  expands materially, explain the cause and revised scope in a short update.

## Review the player loop across equipment

For a new handling flow or substantial workshop-equipment change, review one
representative journey early: find the part, recognize its handling mode, operate
the equipment, observe supported movement, reach and secure the connection, then
undo or return it.
Exercise the actual aim/input route; direct controller calls cover a different
layer. Check normal application launch when scenario selection or startup changes.

Check that visible supports, staging and movement explain the intended handling,
and that pickup-looking stock does not silently require an unrelated console.
Evaluate control grouping, labels and manual guidance as player-facing design;
the ability to target every button does not establish readable or understandable
controls. Keep tightly coupled equipment clearances coordinated before expanding
the full set of operations.

Report automated behavior evidence separately from inspected presentation and
player feedback. Record unresolved usability findings even when mechanical
checks pass. Rendered review still runs only on explicit request; without that
evidence, describe the presentation as unreviewed rather than inferring approval.
Preserve positive playtest findings as constraints for subsequent iteration.

## Author the assembly and its instructions together

Use the source manifest and construction design to identify exact physical
instances, compatible variants, receiving connections and starting context. Derive
current quantities from data; historical totals are not acceptance criteria.

Separate compatible part types from physical instance IDs. Pool interchangeable
copies in one storage location and pocket stack (when pocket-sized); accept any
copy at matching slots while retaining the consumed identity. Distinct types need
an actual fit/function difference, verified against geometry and interfaces. Use
functional variant names consistently across storage, pockets, instructions and
placement feedback; keep source instance numbers internal. Test swapped copies,
wrong variants at ready slots, and undo when changing compatibility. For the wider
component-design-to-model workflow, use
[gundam-component-pipeline](../gundam-component-pipeline/SKILL.md).

Keep ownership and prerequisites distinct. Every physical piece has one location
and owner. An assembly groups those pieces without adding another physical item.
Multiple receiving connections do not imply multiple owners. Encode dependencies
for actual construction constraints, including access before closure; animation
phases and page order are not dependency rules. Preserve valid independent order.

Author part/assembly slots, prerequisites, milestones, snap poses, accessible
targets and manual references through the existing shared model. Update generators
as well as generated assets. Keep stations recipe-independent and gameplay state
independent of desktop bindings. Parent manuals own child mounting and retention;
child manuals own their internal construction. Distinguish prepared, seated and
secured states, including undo across that boundary.

## Audit every affected manual page

- Use part IDs consistently in prose, component lists, storage labels and target
  feedback. Names may clarify IDs; distinguish incompatible variants.
- Derive the component list and quantities from that step's installation slots.
  Include prepared subassemblies being installed in that step. Do not list prior
  or future parts as supplies, or add future-part reminders to the prose.
- Identify an already fitted receiving part only when needed to explain this
  step's connection. Make its existing state clear.
- Overview and readiness pages show status and navigation without a component
  shopping list or a count labelled as new step components.
- Audit unique installation coverage by physical slot, excluding summary pages.
  Reconcile all build instances and parent hardware against available scenario
  stock. Reused IDs in prerequisites or summaries do not request more copies.
- Check actual runtime HUD text as well as authored JSON. Switching pages/builds
  must preserve pocket contents, selection and each physical build's progress.

## Verify geometry and attachment behavior

Imported node transforms alone do not establish orientation: source instances can
have different rotations baked into their mesh vertices. Keep the slot's source
geometry and pose paired for previews, diagrams and installed rendering. Preserve
the consumed physical identity separately in the model and visual metadata.
Compare transformed geometry with the expected source, including washer planes,
screw axes and head direction. Agreement with a flawed source is not proof of a
mechanically sensible fit.

Attached builds must inherit the parent's motion without competing carrying
physics. The current implementation uses static freeze mode when suspended or
mounted, kinematic mode while carried and dynamic physics when dropped. When
attachment, physics or mounted geometry changes, exercise
continuous rotation **between input and physics ticks**, not only a single pose
change followed by settling. Check child body, mesh and physics poses through
rotation, reset, pickup, mounting, undo and reinstallation, including multiple
mounted children. Preserve solid carrying and scenery obstruction checks.

## Rendered construction review, when explicitly requested

If the user explicitly requests visual review, follow the repository's **Manual
and assembly visual review** plan linked in the project map. Capture the affected pages
with the actual renderer: beginning of the step, valid preview and installed result;
the HUD/manual and working view; close-ups of individual fasteners; and at least
two unobstructed inspection angles. Check internal work in opaque and service
views. Include continuous multi-axis rotation when attachment or mounted geometry
changes, and for the first complete module review.

Inspect hole/shaft alignment, bearing-face contact, gaps, inversion, intersections,
accessible insertion and fastening surfaces, closure order, variant recognition,
and diagram readability at normal HUD size. Use authored camera/offset data where
a shared view obscures the connection. Test the affected compatible placements and
physical instances rather than assuming a shared recipe proves them all.

Keep routine tests headless and respect the current execution preferences. Prefer
unattended/offscreen rendered capture when supported. If visual verification was
explicitly requested and capture support is missing, implement the smallest reusable
capture path needed within that task's authorized scope. A design-only task should
specify that work instead. If rendering cannot run under current constraints,
finish independent work and record the exact missing evidence and runnable next
step. Dummy-renderer runs and generated illustrations cannot establish visual
approval. Earlier screenshots can support unchanged scope only when the input
comparison and retained approval establish their applicability.

## Record evidence and complete the task

Run checks appropriate to the changes: inventory/ownership/dependency validation,
normal collection and placement, reach/occlusion, independent order, shared stock,
carrying, rotation and nested undo as affected. Prefer regressions that reproduce
a reported failure and compare real geometry/state over tests of generated wording.

When visual review was explicitly requested, keep a per-page result with page/build/
slot IDs, required quantities, consumed identities, capture paths, inspection views,
reviewer/date, findings, engine version and verified code/asset hashes. Distinguish
authored-data checks, headless behavior, captured images and completed visual inspection.

Report what changed and what actually ran. If visual review was requested, report its
findings and remaining work. Do not mark a build visually verified until its rendered
evidence has been inspected.
Do not report historical check totals or stale captures as results of the current run.
