# FA-01 separately modeled foot assembly

Completed: 2026-10-21 · Revision FA-01-3D-01

The [design documents](../../design/legs/foot-and-ankle.md) and [build order](../../design/legs/foot-and-ankle/assembly-and-review.md) have been translated into 745 independent 3D objects.

## Deliverables

The repository includes the editable Blender scene, looping GIF and images, manifests, and audit records. The model GLBs, source MP4 and ZIP archives are local generated deliverables excluded from Git; regenerate them with the [build instructions](#reproduce-the-build). The playable game retains its own assembled GLB in [game/workshop/assets](../../game/workshop/assets/).

| File | Use |
| --- | --- |
| [foot-fa01.blend](output/foot-fa01.blend) | Editable Blender scene, every part separate, with construction and explosion animation |
| [foot-fa01-animated.glb](output/foot-fa01-animated.glb) | Portable model with all 745 animated part nodes in one animation |
| [foot-fa01-assembled.glb](output/foot-fa01-assembled.glb) | Assembled model with all 745 separate meshes and part metadata |
| [individual-parts-745.zip](output/individual-parts-745.zip) | One centered OBJ file per inventory object, plus materials and assembly-position manifest |
| [foot-fa01-exploding.gif](output/foot-fa01-exploding.gif) | Looping preview of the foot opening into an exploded view |
| [parts-manifest.csv](output/parts-manifest.csv) / [JSON](output/parts-manifest.json) | Part IDs, names, groups, assembly phases and positions |
| [Scene audit](output/scene-audit.json) | Independent verification of the saved Blender scene |
| [Export audit](output/export-audit.json) | GLB node/mesh counts, decoded animation poses and the individual OBJ archive |
| [Assembled poster](output/foot-fa01-assembled.png) / [Exploded poster](output/foot-fa01-exploded.png) | Still frames from the final render |
| [Skeleton inspection render](output/foot-fa01-skeleton.png) | Assembled mechanisms with armor hidden |

**Verified source delivery:** 745 independent meshes, 745 animated GLB nodes, 745 individual OBJ files, and a decoded 984-frame / 41-second MP4 at 1280 × 720 and 24 fps. The [video audit](output/video-audit.json) and [delivery audit](output/delivery-audit.json) record those source checks; the repository retains the GIF preview, while the MP4 can be regenerated locally. Construction paths are schematic; this is a visualization asset rather than fabrication geometry.

## Open and inspect

Open the `.blend` in Blender 4.5 or later. It opens at **frame 440**, with the assembled foot in camera view. Set the timeline to frame 1 and press Space to watch the full sequence. Frame 1 shows the separated starting arrangement; frame 984 is the final exploded view.

On this Mac, double-click [open-in-blender.command](open-in-blender.command) to launch the scene using the task-local Blender installation.

- Units: **metres**. Blender/OBJ axes are X right, Y forward, Z up. GLB uses the standard glTF coordinate conversion.
- Timeline: **984 frames at 24 fps**, approximately 41 seconds.
- Eight numbered part collections separate rear frame, ankle, forefoot, actuators, soles, electrical, armor and fasteners.
- The presentation collection contains the camera, lighting, ground and captions. It is excluded from model exports.
- Object names begin with their inventory family and unique instance identifier. The Object Custom Properties panel contains the corresponding part metadata.
- Each OBJ is centered around its individual object pivot. Restore the assembled position from `parts-manifest.csv`; OBJ itself has no animation.
- The assembled and animated GLBs preserve separate nodes; no assembly meshes have been combined into one object.

Read [modeling decisions and scope](MODELING_NOTES.md) for resolved dimensions and the distinction between a visualization model and fabrication geometry.

Source identities are fixed by [source-identities.json](src/source-identities.json).
Each part or named hardware site resolves an explicit semantic role to its existing
ID; generator emission order no longer assigns identity. Add new roles with unused
IDs deliberately, and preserve old mappings when changing labels or geometry.
[source_connections.py](src/source_connections.py) records pitch hardware sites and
bolt/washer pairs independently of manifest order. Unknown roles, duplicate claims
and reused IDs fail before export.

The gameplay asset merger compacts obsolete resources and verifies repeated merges
are byte-identical. Its audit compares retained geometry, materials and transforms
independently of GLB resource indices. See the [workshop source-update procedure](../../game/workshop/README.md#data-model-and-project-structure)
for scoped exports, checks and current generated-artifact boundaries.

### Runtime rendering derivatives

The separate source meshes remain authoritative. The workshop now builds local
material batches and distance-based detail levels from the currently installed
pieces, preserving inventory, slot identity, individual source geometry and undo.
Completion is not permission to permanently reduce close-up detail. Opaque closure
may omit authored enclosed internals; opening it restores them. Moving children
remain separate rigid groups. See the
[workshop rendering implementation](../../game/workshop/README.md#performance-measurements)
and the [component rendering contract](../../.agents/skills/gundam-component-pipeline/SKILL.md#rendering-contract-for-construction-games).

## Reproduce the build

The generator uses Blender's built-in Python API, without third-party Python packages. Blender 4.5.14 LTS was downloaded from the [official release directory](https://download.blender.org/release/Blender4.5/) and checked against its official SHA-256 manifest. The installed task-local executable is:

```text
/Users/blakeyboy/.cache/gundam-tools/Blender-4.5.14.app/Contents/MacOS/Blender
```

From the project root, substitute your Blender executable for `blender`:

```sh
blender --background --factory-startup --python-exit-code 1 --python models/foot-fa01/src/build.py
blender --background models/foot-fa01/output/foot-fa01.blend --python-exit-code 1 --python models/foot-fa01/src/verify_scene.py
python3 models/foot-fa01/src/verify_exports.py
blender --background models/foot-fa01/output/foot-fa01.blend --python-exit-code 1 --python models/foot-fa01/src/render_preview.py
blender --background models/foot-fa01/output/foot-fa01.blend --python-exit-code 1 --python models/foot-fa01/src/render_film.py
blender --background --factory-startup --python-exit-code 1 --python models/foot-fa01/src/encode_film.py
blender --background --factory-startup --python-exit-code 1 --python models/foot-fa01/src/verify_video.py
```

`render_film.py` can take a start and end frame after `--`, and skips completed nonempty frames so an interrupted render can resume. When changing geometry, lighting or camera, use a fresh frame folder or archive the old frames before rendering the changed sequence.

API references used: [Blender Python API](https://docs.blender.org/api/4.5/), [glTF export options](https://docs.blender.org/api/4.5/bpy.ops.export_scene.html).
