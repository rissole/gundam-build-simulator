# LG-01-3D-01 left leg model

2026-11-01 · Branch `model/leg-lg01` · **Modelled; not yet in the game**

The complete left leg, from hip ball to sole, includes the FA-02 foot and all
armor: **813 separate objects** across **223 component-list rows** (68 leg
objects / 41 rows; 745 foot objects / 182 rows). The local viewer presents a
69-step build. Comparison inspection is complete, with remaining differences
recorded in [modelling notes](MODELING_NOTES.md#remaining-mismatches-with-the-concept-sheets).
User review and merging remain separate decisions.

## Scope and authority

Every physical instance retains its own mesh, identity and part number from the
[leg list](../../design/legs/leg-components.csv) or
[foot list](../../design/legs/foot-and-ankle/foot-components.csv). Integral details
belong to their owning part. Mirroring is verified; a separate right leg is not
delivered. Out of scope: Godot integration, torso, arms, head, workshop clearance
changes and fabrication-grade solids. The approved images, silhouette mannequin
and [FA-01 package](../foot-fa01/README.md) remain unchanged.

Sources, highest authority first:

1. [Proportions](../../design/proportions.md): joint heights and revised envelopes.
2. Component specifications: [thigh](../../design/legs/thigh-and-hip.md),
   [knee](../../design/legs/knee.md), [shin/calf](../../design/legs/shin-and-calf.md),
   [foot](../../design/legs/foot-and-ankle.md) and its detail packet, plus the
   [leg prototype interface](../../design/game/leg-prototype-interface.md).
   Retain joint centres and mating interfaces; fit armor to revised envelopes.
   Model-settled exceptions to older constraints are flagged in the specifications.
3. [Approved style guide](../../design/visual-design/turnaround/README.md): palette,
   chamfers, recessed hardware, panel lines, hatches, rails, stencils and subtle wear.
4. [LG-01](../../design/legs/images/README.md),
   [FA-02](../../design/legs/foot-and-ankle/images/README.md) and turnaround images,
   subject to their drawing-error registers. Images are not dimensioned geometry.
5. FA-01 generator code and [modelling lessons](../foot-fa01/MODELING_NOTES.md).

Interface audit tolerance is 10 mm; envelope checks permit up to 50 mm above
the approved section sizes. Conflicts and final dimensions are in
[MODELING_NOTES.md](MODELING_NOTES.md).
[OPEN_QUESTIONS.md](OPEN_QUESTIONS.md) preserves questions, defaults and resolutions.
Temporary work belongs in ignored `work/`; GLBs and Blender backups are generated
locally. Keep the scene, manifests, audit reports, comparison JPEGs and viewer source.

## Deliverables

| Deliverable | Location / current result |
| --- | --- |
| Editable Blender scene | [leg-lg01.blend](output/leg-lg01.blend), 4.798 MB; 813 objects, 582,230 triangles |
| Per-instance manifests | [JSON](output/parts-manifest.json) / [CSV](output/parts-manifest.csv); identity, finish, bounds and triangle counts |
| Audit reports | [output/audits/](output/audits/); current reports listed below |
| LG-01 comparisons | [Assembled](output/compare/cmp-lg01-assembled.jpg), [armor](output/compare/cmp-lg01-armor.jpg), [structure](output/compare/cmp-lg01-structure.jpg) |
| FA-02 comparisons | [Assembled](output/compare/cmp-fa02-assembled.jpg), [armor/soles](output/compare/cmp-fa02-armor.jpg), [structure](output/compare/cmp-fa02-structure.jpg) |
| Whole-robot comparison | [Turnaround leg region](output/compare/cmp-turnaround-leg.jpg) |
| Review evidence | [Round 1](output/compare/review-r1.md), [round 2](output/compare/review-r2.md), [round 3](output/compare/review-r3.md), [render receipt](output/compare/notes-render.md) |
| Individual renders | [output/renders/](output/renders/); current comparison views use the `r-` prefix; earlier development views remain alongside them |
| Viewer and sequence | [viewer/](viewer/), [69 build steps](viewer/build-steps.json), generated `viewer/leg-lg01.glb`: 22.452 MB, 813 nodes, 13 materials |
| Viewer captures | [Start](output/viewer-shots/viewer-start.jpg), [middle](output/viewer-shots/viewer-mid.jpg), [assembled](output/viewer-shots/viewer-end.jpg), [ghost armor](output/viewer-shots/viewer-ghost.jpg) |
| Shape/material reference | [Test board](output/kit/test-board.jpg), [style comparison](output/kit/test-board-compare.jpg), [GLB reload audit](output/kit/glb-reload.json) |

## Rebuild and open

Run from the repository root with Blender on `PATH` (tested with 5.2.3 LTS),
Python 3 and Pillow available to the image-composition tools. For the browser
check, first create the Playwright environment using the
[Viewer recipe](MODELING_NOTES.md#viewer); it uses installed Google Chrome.

Run these commands in order. Sequence generation saves step assignments into the
scene; the build manifests retain their initial `step=-1`, so use the sequence
JSON and exported node extras for installation order.

```sh
blender --background --factory-startup --python-exit-code 1 --python models/leg-lg01/src/build.py
blender --background models/leg-lg01/output/leg-lg01.blend --python-exit-code 1 --python models/leg-lg01/src/sequence.py
blender --background models/leg-lg01/output/leg-lg01.blend --python-exit-code 1 --python models/leg-lg01/src/verify_scene.py -- --expect full
blender --background models/leg-lg01/output/leg-lg01.blend --python-exit-code 1 --python models/leg-lg01/src/verify_interfaces.py
blender --background models/leg-lg01/output/leg-lg01.blend --python-exit-code 1 --python models/leg-lg01/src/verify_envelopes.py
blender --background models/leg-lg01/output/leg-lg01.blend --python-exit-code 1 --python models/leg-lg01/src/verify_mirror.py
python3 models/leg-lg01/src/verify_sequence.py
blender --background models/leg-lg01/output/leg-lg01.blend --python-exit-code 1 --python models/leg-lg01/src/render_compare.py
blender --background --factory-startup --python-exit-code 1 --python models/leg-lg01/src/export_viewer.py
python3 models/leg-lg01/src/verify_export.py
models/leg-lg01/work/viewer-venv/bin/python models/leg-lg01/src/check_viewer.py --browser
models/leg-lg01/open-viewer.command
```

The launcher serves the viewer on a free localhost port and opens the default
browser. It waits for HTTP readiness, allowing up to 90 seconds for slow local
DNS. First use needs internet for pinned jsDelivr modules. Close the launcher
Terminal window or press Ctrl-C to stop the server; closing the browser is not
enough. A `file://` page cannot load the GLB.

## Evidence

**Audits that pass**

These are the saved results for the current scene, read during documentation
close-out; the documentation pass did not rebuild or rerun geometry audits.

| Audit | Result and scope |
| --- | --- |
| [Scene](output/audits/scene-full.json) | All 813 objects / 223 rows; counts, identity, independent meshes, materials, finite geometry, closed shells, normals and volume |
| [Interfaces](output/audits/interfaces-structure.json) | 320 top-level checks, including the aggregate of 1,718 foot checks; neutral geometry, bores, seats, datums and selected clearances |
| [Envelopes](output/audits/envelopes.json) | 22 checks; thigh 1.800 × 1.800 m, calf 1.6516 wide × 2.2311 deep, foot 3.3603 long × 1.4600 wide; access rays and bounded ankle checks |
| [Mirror](output/audits/mirror.json) | 813 temporary reflected meshes pass after 1 µm collapsed-edge cleanup; source defects remain |
| [Sequence](output/audits/sequence.json) | 813 installs in 69 steps; dependencies and hardware grouping pass; 1,324,584 box comparisons, 293 conditional nonconvex exceptions, no unexcepted violations |
| [Export](output/audits/export.json) | 813 nodes, 13 materials, 582,230 triangles, 22,452,080 bytes; identity, metadata and sequence coverage pass |
| [Viewer](output/audits/viewer.json) | 553 scrub samples, 70 panel states, all 813 parts moving, 252 mode samples; zero position error or console/page errors; recorded load 0.437 s after server readiness |
| [Launcher](output/audits/viewer-launcher.json) | HTTP 200 for all assets; launch from another directory and clean shutdown/port release |

Despite its name, `interfaces-structure.json` is the current combined leg and
foot report; `scene-structure.json` is phase 3 development evidence. The sequence exceptions
and bounded clearance methods are explained in the [notes](MODELING_NOTES.md#build-sequence-and-clearance).

**Inspected renders**

The coordinator inspected all seven final `cmp-*.jpg` sheets after three
review/fix rounds. The retained reviews record each round's findings; round 3
scores precede its final repairs and are not a new score for the repaired sheets.
The [remaining mismatches and scores](MODELING_NOTES.md#remaining-mismatches-with-the-concept-sheets)
record the final outcome. Earlier material-board, structure and armor views and
the four viewer captures also have recorded inspection evidence. Render-only
cavity shading and wear do not establish identical appearance in the viewer.

**Not checked**

Full hip/knee/ankle/forefoot solid motion sweeps, general insertion and tool access,
flexible-service motion, load sizing and fabrication solids remain open. Selected
ankle, upper-plate and pitch-cap checks do not certify the whole mechanism.
22 source meshes retain 1,937 zero-area collapsed-bevel faces. Existing foot
rail-end/plan-chamfer and actuator/frame contacts need separate review.
Game integration, workshop fit, user interaction acceptance and final user visual
approval are not established by these audits or inspections.
