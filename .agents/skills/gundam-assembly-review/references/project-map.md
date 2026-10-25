# Project sources and review entry points

All paths below are relative to the Gundam Build Simulator repository. Inspect the
current files and discover new module equivalents; this map is not a fixed module
or page inventory.

## Product and assembly design

- `GAME_DESIGN.md`: collecting/manual-focused gameplay, desktop first, future AR,
  comfortable carrying, current pockets and storage behavior.
- `design/game/workshop-state.md`: current status, active rules, open decisions,
  human checkpoints and a table of which design document to read when.
  Read it before continuing workshop work. Record player findings in
  `design/game/robot-workshop-playtest-checklist.md`. `design/game/history/` holds finished
  work orders, superseded plans and evidence; open those only when a current
  document links to a specific one.
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

The current desktop project is `game/workshop/`:

| Path within project | Responsibility |
| --- | --- |
| `README.md` | Current launch controls, verification commands and known limits |
| `assets/assembly-definitions.json` | Shared pad/parent recipes and part definitions |
| `assets/heel-pads.json`, `assets/pitch-workshop.json` | Scenario inventory, build instances and initial locations |
| `assets/pitch-actuator-definitions.json` | Generated actuator/parent recipe overlay |
| `tools/author_pitch_actuator.py` | Authoritative pitch recipe generator; edit before regenerating JSON |
| `assets/foot-fa01.glb` | Imported mesh geometry and poses; preserve this export unless source-model work is in scope |
| `scripts/assembly_model.gd` | Input-independent slots, ownership, prerequisites, inventory and undo |
| `scripts/workshop_content.gd` | Scenario loading and slot-level recipe patch materialization |
| `scripts/component_interaction.gd` | Generic targeting, geometry projection and component carrying |
| `scripts/workshop.gd` | Bootstrap and public interaction facade |
| `scripts/build_stages.gd` | Stage names, the `--stage` flag, boundary checks and scripted progression |
| `scripts/player_controller.gd`, `scripts/desktop_input.gd` | Player motion and desktop/modal input |
| `scripts/targeting.gd`, `scripts/workshop_world.gd`, `scripts/primitives.gd` | Target/ghost projection, world construction and cached materials |
| `scripts/equipment.gd`, `scripts/equipment_registry.gd`, `scripts/hand_slot.gd` | Equipment contract, interlocks and shared hand ownership |
| `scripts/motion_sweep.gd`, `scripts/pose_codec.gd` | Shared swept-motion checks and pose serialization |
| `assets/workshop-layout.json`, `tools/author_workshop_blockout.py` | Authoritative hangar, rail, lift, shelf, parent and crane geometry read by Python and runtime |
| `assets/leg-prototype-*.json`, `assets/robot-*.json`, `tools/author_leg_prototype.py` | Structural leg base content, the robot extension and generator/audits |
| `scripts/leg_bay_layout.gd`, `scripts/indexed_leg_rail.gd`, `scripts/service_crane.gd`, `scripts/lift_shelf.gd`, `scripts/work_access_lift.gd` | Hangar layout and its leg holder, crane, shelves and lifts |
| `scripts/scenario_staging.gd`, `scripts/workshop_automation.gd` | Declared setup and public automation seam |
| `tests/kit/` | Shared test harness, desktop player driver and JSON evidence output |
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
python3 game/workshop/tools/author_leg_prototype.py --check
python3 game/workshop/tools/run_regressions.py --list
python3 game/workshop/tools/run_regressions.py --only assembly_model_test pitch_interface_test staging_policy_test
python3 game/workshop/tools/run_regressions.py
```

The default runner selects fast model/component/source tests and one startup smoke.
It warns above 60 seconds and reports slow cases; improve tests instead of raising
the performance budget. Expensive journeys and route audits require an explicit
user request and named `run_diagnostics.py --only NAME ...` cases. There is no
run-all diagnostic mode or automatic fallback. See `game/workshop/tests/TESTING.md`
for coverage migration. Logs and hashes remain local; engine errors and changed
inputs invalidate results. The one game still launches through `./play.command`.
Human replay is tracked separately from automated passes.

The README also lists the state and pocket-model suites. Input tests drive the
normal desktop adapter and actual targeting/physics. `tests/pitch_build_test.gd`
compares installed mesh vertices with slot source geometry; `tests/pitch_build_test.gd`
also checks station and foot rotation. Extend those paths
or add a focused module runner when introducing new behavior.
`tests/pitch_interface_test.gd` also checks actual triangles for receiving bores,
surrounding material and seat/head clearance. Its ray tests use millimetres to
avoid metre-scale triangle epsilon false negatives. These tests do not replace
visual inspection or establish complete collision-free assembly paths.

`tests/pitch_visual_review.gd` extends the pitch build runner's page/placement
checkpoints with real-renderer captures. From the repository root:

```sh
./play.command --disable-render-loop --fixed-fps 60 --script tools/pitch_review.gd
python3 game/workshop/tools/build_pitch_review_gallery.py --input /path/printed/as/REVIEW_OUTPUT
```

Add `-- --review-pages=pitch-04,foot-06` after the review script path to
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

`tools/pitch_review.gd` and `tests/workshop_visual_review.gd` have rendered
capture helpers. A generalized capture runner for all foot/pad pages remains to
be implemented. Inspect
current support before invoking any command; no `--review-manuals` flag exists.

Keep generated project evidence under the ignored local
`game/workshop/verification/` directory or the new module's equivalent.
Examples produced by the current checks include `pitch-build-audit.json` and
`multi-build-audit.json`. Inspect the run's scope, date and hashes; historical
passing results do not approve new actuator or module content.
