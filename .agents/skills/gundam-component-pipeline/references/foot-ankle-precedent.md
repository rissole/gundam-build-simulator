# Foot/ankle precedent and source map

Paths are repository-relative. This describes the inspected proof of concept on
2026-10-21; verify current files before reusing details. Foot counts, mechanisms,
filenames and revision IDs are examples, not templates for every body component.

## What the existing pipeline accomplished

| Stage | Evidence and reusable decision |
| --- | --- |
| Component overview | `design/legs/foot-and-ankle.md` captures confirmed form, articulation and neighbor ownership; links to shared rules/proportions and a focused detail packet. Other component starting points already exist under `design/legs/`, `design/arms/` and `design/torso/`. |
| Detail design | `design/legs/foot-and-ankle/{dimensions,actuators,parts,assembly-and-review}.md` and `hardware.csv` resolve datums, individual interfaces, module boundaries, hardware counts, sequence and access. `review_geometry.py`/`review-results.json` provide bounded numerical checks. |
| Exploded/concept references | `design/legs/foot-and-ankle/images/README.md` indexes assembled, structural, and armor/sole/services sheets, exact prompts, superseded iterations and drawing mistakes. These were generated for review and are explicitly not user-approved. Written dimensions/counts govern. |
| Separate 3D source | `models/foot-fa01/src/build.py`, `geometry.py`, `frame_parts.py`, `actuator_parts.py`, `finish_parts.py` generate physical instances, animation and exports. `output/parts-manifest.json` maps IDs and source metadata. `MODELING_NOTES.md` records dimensional refinements discovered during layout. |
| Model validation/presentation | `verify_scene.py`, `verify_exports.py`, preview/inspection/film scripts and package audits distinguish scene inventory, export contents and visual presentation. Full construction/explosion film is an existing deliverable, not mandatory for every recipe edit. |
| Playable selection | `design/game/foot-prototype-plan.md`, `GAME_DESIGN.md` and `game/heel-pad-demo/README.md` define the collection/manual loop, child preparation, parent mounting and incremental expansion. Start from a complete small playable branch. |
| Recipe/scenario authoring | `game/heel-pad-demo/assets/assembly-definitions.json` supplies shared pad/parent definitions; `tools/author_pitch_actuator.py` generates the pitch overlay and scenario from source identities. Definitions describe types/slots/manuals; scenario data describes actual stock/build instances and starting locations. |
| Runtime projection | `scripts/assembly_model.gd` owns gameplay state; `component_interaction.gd`/`workshop.gd` project geometry and input. `hud.gd`, `manual_diagram.gd` and `part_storage.gd` expose the same types and instructions. `tools/render_part_images.py` builds catalogue images. |
| Implemented review | `.agents/skills/gundam-assembly-review/references/project-map.md` locates current commands, test runners and capture support. Historical pitch review outcomes are summarized in `design/game/pitch-interface-repair.md`; inspected images and input hashes are no longer kept in Git. |

## What should not be mistaken for complete gameplay

The detailed reference and original 3D package contain 745 physical objects for
one foot. The playable workshop exposes 135 source identities across two heel pads
and one pitch actuator with parent installation hardware; other pieces remain
context/staged parts. An assembly container adds no physical inventory. Verify
current quantities from the manifest/definitions before stating them.

The standalone-foot proposal reserves the shin interface for later leg assembly.
Do not duplicate foot-owned adapter or connection hardware when moving to the
shin; confirm the scenario boundary from current design and stock allocation.

The repaired pitch branch has its own interface revision:
`design/game/pitch-interface-repair.md` and
`models/foot-fa01/src/pitch_interfaces.py`. The selective exporter
`export_pitch_revision.py` updates the relevant JSON manifest records, and
`game/heel-pad-demo/tools/merge_pitch_meshes.py` merges the pitch pieces plus the
cradle/ring receiving frames into the game GLB while auditing unrelated geometry.
Read the game README before using this path. It keeps one pre-iteration base
snapshot; repeatedly merging against newly merged assets accumulates unused data.

After that selective repair, the full Blender scene, film, CSV and standalone
exports remain historical until regenerated. Roll and forefoot actuators remain
reference geometry awaiting their own gameplay/interface reviews. Reusing their
structure does not inherit the pitch branch's visual approval.

At inspection time the pitch review covered the child build and parent
installation; remaining default-workshop/pad rendered review and save/resume were
still separate work. Historical audit totals do not validate a new change.
The accepted images and hashes are no longer kept in Git; capture and inspect
the affected scope again before claiming visual approval.

## Compatibility lesson from the prototype

The pitch generator originally used each numbered `FA-` instance as an inventory
type. This made matching eye bearings, retaining rings, sensors, pins and keepers
reject equivalent copies. Conversely, eye housings, gaskets, collar halves and
clevis brackets include real fit differences. The reusable rule is to classify
physical interchangeability explicitly, then use descriptive variant names.
Do not infer compatibility from the foot family prefix, instance number or mesh
object count. The same family can contain multiple sizes across other actuators.
