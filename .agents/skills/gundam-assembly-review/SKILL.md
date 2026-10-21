---
name: gundam-assembly-review
description: >-
  Design, implement and verify assembly manuals and module builds in Gundam Build
  Simulator. Use when adding or changing module recipes, manual steps, part
  allocation, attachment geometry, or mounted assembly behavior. Includes
  step-specific component audits and rendered visual review. Does not apply to
  unrelated UI, general documentation, or other games' manuals.
---

# Gundam assembly and visual review

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
  inventory/manual audit, gameplay checks and visual review below. Shared geometry
  or parenting changes also affect other builds using that behavior.
- **Small instruction edit:** audit the affected instructions and component lists.
  Run broader gameplay or rendered checks when the edit changes sequence, targets,
  quantities or visual presentation.

## Author the assembly and its instructions together

Use the source manifest and construction design to identify exact physical
instances, compatible variants, receiving connections and starting context. Derive
current quantities from data; historical totals are not acceptance criteria.

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
mounted, kinematic mode while carried and dynamic physics when dropped. Exercise
continuous rotation **between input and physics ticks**, not only a single pose
change followed by settling. Check child body, mesh and physics poses through
rotation, reset, pickup, mounting, undo and reinstallation, including multiple
mounted children. Preserve solid carrying and scenery obstruction checks.

## Review the rendered construction

Follow the repository's **Manual and assembly visual review** plan linked in the
project map. For implemented build changes, capture and inspect the affected pages
with the actual renderer: beginning of the step, valid preview and installed result;
the HUD/manual and working view; close-ups of individual fasteners; and at least
two unobstructed inspection angles. Check internal work in opaque and service
views, then continuously rotate the assembled result around multiple axes.

Inspect hole/shaft alignment, bearing-face contact, gaps, inversion, intersections,
accessible insertion and fastening surfaces, closure order, variant recognition,
and diagram readability at normal HUD size. Use authored camera/offset data where
a shared view obscures the connection. Test the affected compatible placements and
physical instances rather than assuming a shared recipe proves them all.

Keep routine tests headless and respect the current execution preferences. Prefer
unattended/offscreen rendered capture when supported. If the task includes visual
verification and capture support is missing, implement the smallest reusable
capture path needed within that task's authorized scope. A design-only task should
specify that work instead. If rendering cannot run under current constraints,
finish independent work and record the exact missing evidence and runnable next
step. Dummy-renderer runs, generated illustrations and old screenshots cannot
serve as current rendered verification.

## Record evidence and complete the task

Run checks appropriate to the changes: inventory/ownership/dependency validation,
normal collection and placement, reach/occlusion, independent order, shared stock,
carrying, rotation and nested undo as affected. Prefer regressions that reproduce
a reported failure and compare real geometry/state over tests of generated wording.

Keep a per-page result with page/build/slot IDs, required quantities, consumed
identities, capture paths, inspection views, reviewer/date, findings, engine version
and verified code/asset hashes. Distinguish authored-data checks, headless behavior,
captured images and completed visual inspection. Fix findings and recapture affected
and dependent steps; retain accepted baselines. Shared geometry, snap poses,
parenting or framing changes invalidate the relevant baselines.

Report what changed, what actually ran, visual findings and remaining review work.
Do not mark a build visually verified until its rendered evidence has been inspected.
Do not report historical check totals or stale captures as results of the current run.
