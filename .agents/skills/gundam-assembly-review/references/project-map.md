# Project sources and review entry points

All paths below are relative to the Gundam Build Simulator repository. Inspect the
current files and discover new module equivalents; this map is not a fixed module
or page inventory.

## Product and assembly design

- `GAME_DESIGN.md`: collecting/manual-focused gameplay, desktop first, future AR,
  comfortable carrying, current pockets and storage behavior.
- `ROBOT_DESIGN.md` and `design/legs/foot-and-ankle/`: mechanical design and assembly
  references. Start with `assembly-and-review.md`, `actuators.md` and `hardware.csv`
  when working on the foot/actuators.
- `design/game/foot-prototype-plan.md`: shared assembly architecture and the
  **Manual and assembly visual review** section. Read that section when planning
  or performing rendered review. Derive the current affected-page inventory from
  definitions rather than preserving the plan's historical page count.
- `models/foot-fa01/output/parts-manifest.json`: physical source identities, family
  IDs and metadata. Use the corresponding source package for another module.
- `models/foot-fa01/README.md`: model provenance and export/import details.

## Authoring and runtime

The current desktop project is `game/heel-pad-demo/`:

| Path within project | Responsibility |
| --- | --- |
| `README.md` | Current launch controls, verification commands and known limits |
| `assets/assembly-definitions.json` | Shared pad/parent recipes and part definitions |
| `assets/heel-pads.json`, `assets/pitch-workshop.json` | Scenario inventory, build instances and initial locations |
| `assets/pitch-actuator-definitions.json` | Generated actuator/parent recipe overlay |
| `tools/author_pitch_actuator.py` | Authoritative pitch recipe generator; edit before regenerating JSON |
| `assets/foot-fa01.glb` | Imported mesh geometry and poses; preserve this export unless source-model work is in scope |
| `scripts/assembly_model.gd` | Input-independent slots, ownership, prerequisites, inventory and undo |
| `scripts/assembly_state.gd` | Pad projection and regression scenario setup |
| `scripts/component_interaction.gd` | Generic targeting, geometry projection and component carrying |
| `scripts/workshop.gd` | Scene setup, parent transforms, stations, carrying and input |
| `scripts/hud.gd`, `scripts/manual_diagram.gd` | Runtime component lists and model-based illustrations |
| `scripts/part_storage.gd`, `tools/render_part_images.py` | Storage labels, catalogue images and their generation |

Use imported GLB transforms when deriving Godot poses. The manifest's custom
Blender-axis position metadata is not a Godot transform. Compatible hardware can
have different baked mesh orientations even when node bases match. A receiving
slot's `pose_source` identifies both its expected source geometry and pose; the
slot occupant's UID identifies the consumed inventory piece.

## Verification and capture

Run from the repository root, choosing the suites affected by the change:

```sh
./play-heel-pad.command --headless --script tests/assembly_model_test.gd
./play-heel-pad.command --headless --script tests/pitch_model_test.gd
./play-heel-pad.command --headless --script tests/pitch_interface_test.gd
./play-heel-pad.command --headless --fixed-fps 60 -- --pitch-test
./play-heel-pad.command --headless --fixed-fps 60 -- --multi-test
./play-heel-pad.command --headless --fixed-fps 60 -- --single-pad --demo-test
./play-heel-pad.command --headless --fixed-fps 60 -- --pockets-test
```

The README also lists the state and pocket-model suites. Input tests drive the
normal desktop adapter and actual targeting/physics. `tests/pitch_build_test.gd`
compares installed mesh vertices with slot source geometry; `tests/multi_build_test.gd`
reproduces continuous rotation between input and physics ticks. Extend those paths
or add a focused module runner when introducing new behavior.
`tests/pitch_interface_test.gd` also checks actual triangles for receiving bores,
surrounding material and seat/head clearance. Its ray tests use millimetres to
avoid metre-scale triangle epsilon false negatives. These tests do not replace
visual inspection or establish complete collision-free assembly paths.

`tests/pitch_visual_review.gd` extends the pitch build runner's page/placement
checkpoints with real-renderer captures. From the repository root:

```sh
./play-heel-pad.command --disable-render-loop --fixed-fps 60 -- --pitch-test --pitch-review
python3 game/heel-pad-demo/tools/build_pitch_review_gallery.py --input /path/printed/as/REVIEW_OUTPUT
```

Use both flags. Add `--review-pages=pitch-04,foot-06` after `--pitch-review` to
capture only selected pages, including their placements and views. Choose dependent
pages explicitly: filtering does not infer downstream impact. The runner still
performs the normal build/ownership checks; it skips unrelated image capture.
Rotation is captured when the selection includes `pitch-14` or `foot-06`.
Each run prints `REVIEW_OUTPUT` with its unique local evidence directory; pass
that path to the gallery helper. Keep targeted runs separate when comparing them.

The capture mode rejects a headless dummy renderer. It records
before/preview/after placements, two inspection angles, opaque/service/exposed
views, actual HUD pages and continuous rotation. The gallery helper needs Pillow.
Evidence, hashes and page decisions belong together in the run's ignored local
`verification/` directory. The repaired 2026-10-21 pitch review historically
passed all 14 child pages and three parent installation pages, including
receiving frames and full assembly preview. Its inspected images and exact input
hashes are no longer kept in Git. Recreate and inspect local evidence for the
affected scope before granting fresh visual approval. A generated gallery alone
is not approval. Within a local review, compare recorded hashes with current
inputs and retain unchanged applicable evidence; report or skill changes alone
do not invalidate unchanged rendered geometry.

`tests/demo_test.gd` also has a rendered `capture()` helper. A generalized capture
runner for all default-workshop/pad pages remains to be implemented. Inspect
current support before invoking any command; no `--review-manuals` flag exists.

Keep generated project evidence under the ignored local
`game/heel-pad-demo/verification/` directory or the new module's equivalent.
Examples produced by the current checks include `pitch-build-audit.json` and
`multi-build-audit.json`. Inspect the run's scope, date and hashes; historical
passing results do not approve new actuator or module content.
