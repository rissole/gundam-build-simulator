---
name: gundam-component-pipeline
description: >-
  Develop a Gundam Build Simulator component from its high-level design Markdown
  into a detailed parts/interface specification, exploded reference, separate 3D
  parts, and playable assembly recipes/manuals. Use for deepening a component
  such as foot, leg or torso, or continuing one of those pipeline stages. For
  isolated manual/placement fixes use gundam-assembly-review; unrelated UI and
  general documentation do not need this pipeline.
---

# Component design to playable manual

Continue the user's selected component and requested stage. Inspect existing work
before adding artifacts; a design request needs a design and review plan, while a
request to implement a playable branch needs its models, instructions and checks.
Do not automatically rebuild a whole robot or render a film for a local change.

Read the component overview, `design/global.md`, relevant proportions and neighbor
interfaces. Use [the foot/ankle precedent](references/foot-ankle-precedent.md) to
locate worked examples and understand their limits. Resolve project paths against
the active repository, including when this skill is installed by symlink.

For assembly design, recipes/manuals, geometry or mounting implementation, also
apply [gundam-assembly-review](../gundam-assembly-review/SKILL.md). It owns the
proportional manual and behavior review procedure, plus rendered review when explicitly
requested; do not duplicate or
replace its acceptance criteria here.

## 1. Establish the component contract

Preserve confirmed choices in the high-level Markdown and distinguish selected
working dimensions, unresolved choices and later engineering questions. Identify:

- Physical boundary, coordinate origin, axes, units, handedness and neutral pose.
- Envelope and articulation; which child moves with which parent.
- Neighbor mating geometry, pins/keys, fasteners and electrical/service interface.
- Which component owns each connecting part and which assembly installs it.
- The requested deliverable and playable subset; preassembled context, reserved
  interface hardware and remaining branches stay explicitly accounted for.

Develop only the detail packet the component needs: dimensions/interfaces,
parts/hardware allocation, mechanisms/services, assembly/access sequence. The foot
packet is an example structure, not a mandatory set of files for every piece.
Record modeling discoveries back into the appropriate specification or clearly
linked revision so later stages do not silently follow conflicting designs.

## 2. Decompose physical parts and compatibility

Choose meaningful puzzle parts and manufactured modules. A motor cartridge can
remain one component; integral bosses, tabs and holes stay part of their owning
mesh. A logical subassembly contains its physical pieces and adds no inventory
object. Allocate external installation hardware to actual connections, including
separate washers, sleeves and retainers where specified. Derive totals from those
allocations rather than copying a historical component count.

Keep four concepts separate throughout the pipeline:

| Concept | Purpose |
| --- | --- |
| Family | Design/catalogue grouping; may contain several incompatible variants |
| Compatible type/variant | What a slot accepts and inventory stacks together |
| Physical instance ID | Unique identity retained through collection, placement and undo |
| Installation slot/source | Destination, receiving context and expected oriented geometry |

Identical interchangeable copies share one compatible type, storage category and
pocket stack with a quantity. Any copy may fill any matching slot. Keep instance
numbers internal. A location alone does not create a variant: two identical end
sensors remain one type even when their destination labels are front and rear.

Create distinct variants only for actual differences affecting fit or function,
including handed geometry, dimensions, hole patterns or mating interfaces.
Verify shape and interfaces; matching family IDs or similar appearance are
insufficient. A rotated identical part is reusable; a true mirror may be handed.

Name variants by the difference a player can use: base/rod eye housing,
front/rear gasket, cradle/ring clevis, or thread size/length. For complementary
halves use a real distinguishing feature, such as clearance-hole/threaded half,
when that matches the geometry. Avoid unexplained `1`/`2` and opaque instance
suffixes in player labels. Use the same family ID plus functional name in storage,
pockets, component lists, prose, diagrams and placement/rejection feedback.

Maintain an explicit family/variant-to-instance mapping in the authoring data.
Classify compatibility deliberately; do not automatically pool an entire family
or automatically make every numbered source mesh its own type.

## 3. Explain and build the geometry

Use an assembled view to establish silhouette and exploded views to communicate
part groups, interfaces and construction order. Keep drawings traceable to the
written inventory. AI reference sheets can guide appearance; their counts,
measurements and hidden mechanisms do not override the written design. Preserve
useful prompts and record known drawing errors when such sheets are produced.

Model each physical inventory object separately with stable identity, family and
variant metadata, owner/group and assembled pose. Preserve repeated pieces as
separate physical instances even when they share a compatible type. Document
source units and coordinate conversion. Export separate meshes/nodes and a
manifest sufficient to reconnect instances to their game definitions.

Make the intended connection visible in geometry: mating seats, receiving bores,
washer faces, screw axes/head access, pin shoulders and removable closures. Check
both sides of each connection, including parent geometry. Distinguish bounded
reference-envelope checks from actual solid/interface and rendered verification.

Keep exploded display offsets and animation phases separate from assembled snap
poses, insertion directions and gameplay prerequisites. Animation demonstrates an
order; it does not establish valid access or a collision-free insertion path.

Edit authoritative generators along with generated assets. Regenerate only the
needed deliverables, preserve unrelated geometry during scoped repairs, and
record which manifests, scenes, exports and illustrations match the new revision.
Do not overwrite a repaired gameplay asset with a stale whole-model export.

## 4. Author a playable branch and its manual together

Use the existing shared assembly model. Define compatible types, physical stock,
child/root instances, installation slots, prerequisites, milestones, snap sources,
accessible targets, carrying/work locations and manual references as data.
Keep desktop controls and station behavior independent of a particular recipe.

Ownership is a single-parent physical relationship. Prerequisites represent real
construction/access constraints and may have multiple predecessors. Encode
retention before closure, and preserve independent build order where access allows.
A parent's manual owns seating and retention of a prepared child; the child's
manual owns its internal build. Prepared, seated and secured are distinct states.

Derive each page's required components from its installation slots. Count only new
supplies for that page, including a prepared child when mounted. Identify an
already fitted receiving part as context. Status/overview pages carry progress
and navigation, without a shopping list. Author views at the connection scale,
with offsets and cameras that reveal the relevant seat, washer or fastener.

Use imported transforms for game poses. In this project a slot's `pose_source`
selects expected source geometry **and** orientation; the consumed inventory UID
remains separate. Compatible source meshes may have different rotations baked
into their vertices. Swapping equivalent copies must preserve both correct
installed geometry and the consumed physical identity.

Integrate one complete collection → preparation → installation → undo loop before
expanding the next branch. Reuse definitions for truly shared construction, while
keeping build progress and manual position attached to each physical assembly.

## 5. Validate and leave a truthful handoff

Follow the assembly-review skill for the affected scope. In particular, verify
stock conservation, unique slot coverage, valid prerequisites and ownership,
compatible-copy swaps, wrong-variant rejection, inventory grouping, manual labels
at normal HUD size, and undo/reinstallation of the same identities. When visual
review is explicitly requested, inspect rendered interfaces rather than treating
source agreement as proof of good fit.

For design-only work, leave concrete checks and expected evidence. For implemented
work, distinguish authored-data audits and behavioral tests. If visual review was
explicitly requested, distinguish rendered captures from inspected visual evidence;
if rendering is unavailable, record the missing evidence and runnable next step.
Do not label a build visually approved without inspected rendered evidence.

Update the component's status with completed stages, revision/source links,
playable boundary, review evidence and remaining work. Reference drawings, exported
models and playable manuals can be at different revisions; make that explicit.
