# Gundam Build Simulator

A first-person mecha workshop prototype: organise parts, follow illustrated manuals, and assemble a giant robot one component at a time.

The full-game design targets an **18 m piloted mecha**. The current playable milestone is a **135-piece workshop with a supported foot bay, two pads, a complete pitch actuator, and linked manuals** in Godot, backed by an FA-01 foot model with **745 separate parts** and a reproducible Blender generation pipeline.

![FA-01 assembled foot, with separate armor, frame, ankle mechanisms, and sole pads](models/foot-fa01/output/foot-fa01-assembled.png)

## Watch the assembly

![FA-01 foot separating from its assembled form into an exploded view](models/foot-fa01/output/foot-fa01-exploding.gif)

## Play the workshop

![Heel-pad assembly in the workshop, with the illustrated manual, placement preview and square inventory pockets](docs/images/heel-pad-demo.png)

*Earlier workshop view; the default scene now uses a supported foot fixture.*

Use **Godot 4.7.2**. On macOS, double-click [play.command](play.command), or run it from the repository root:

```sh
./play.command
```

The launcher finds Godot on your PATH, in `/Applications/Godot.app`, or in the existing local tool cache. You can also specify an executable:

```sh
GODOT_BIN=/path/to/godot ./play.command
```

On other platforms, open [game/workshop/project.godot](game/workshop/project.godot) in Godot and run the project. The first launch imports the model.

Prepare two independent heel pads and a pitch actuator at the workshop stations, then secure them to the foot. Labelled drawers supply small hardware; shelves hold larger components. The parent foot manual links to each build, remembers your pages, and tracks preparation and installation. A ghost preview shows valid placements.

The foot stays in a visible mechanical cradle. Walk around it or use the access platform, and press **E** at the bay controls to select a supported working position. Once both pads and the actuator are secured, transfer the upright foot along its rail carriage to the handoff area. Return it to the bay before undoing construction. Small preparation stations retain free rotation.

| Input | Action |
| --- | --- |
| WASD / mouse | Move / look |
| Space | Jump |
| E | Stock a pocket / carry a component / operate bay controls |
| 1–0 | Select one of ten small-part pockets |
| Left click | Attach at the highlighted point |
| Q / B | Set down carried component / clear selected pocket |
| Hold R + mouse / double-tap R | Rotate / reset a preparation station |
| Tab or M | Toggle the manual |
| N | Browse the manual tree and steps |
| Enter / Backspace | Open child / parent manual |
| C / V | Cycle manuals / open inspected build |
| Z | Undo in the selected manual |
| Escape | Release the mouse and open help |

See the [workshop README](game/workshop/README.md) for the complete controls, behavior, verification, and limitations. Progress lasts for the current session. The rest of the foot is preassembled context; full-foot progression and the remaining robot are future work. The original heel-pad demo remains available as a small regression scenario.

## Explore the model and design

The foot measures approximately **3.0 m long × 1.3 m wide**. Its inventory contains 229 other pieces or manufactured modules, 258 bolts/screws, and 258 matching washers. Parts retain individual identities for construction, export, and inspection.

| Start here | Contents |
| --- | --- |
| [Game design](GAME_DESIGN.md) | Workshop loop, carrying, targeting, manuals, dependencies, and undo |
| [Robot design](ROBOT_DESIGN.md) | Whole-robot scope and links to each body assembly |
| [Foot and ankle specification](design/legs/foot-and-ankle.md) | Dimensions, parts, actuators, hardware, and assembly sequence |
| [Reference sheets](design/legs/foot-and-ankle/images/README.md) | Engineering-style images and their generation prompts |
| [FA-01 model](models/foot-fa01/README.md) | Model deliverables, Blender workflow, exports, and audit records |
| [Modeling notes](models/foot-fa01/MODELING_NOTES.md) | Geometry decisions and visualization scope |
| [Prototype expansion plan](design/game/foot-prototype-plan.md) | Proposed stages beyond the playable heel-pad milestone |

![Foot mechanisms with the armor hidden](models/foot-fa01/output/foot-fa01-skeleton.png)

## Development

Open the Godot editor with `./edit.command`. Gameplay scripts, the workshop scene, tests, and source-part metadata live in [game/workshop](game/workshop/).

Run the state and interaction checks headlessly from the repository root:

```sh
./play.command --headless --script tests/state_test.gd
./play.command --headless --script tests/assembly_model_test.gd
./play.command --headless -- --single-pad --demo-test
./play.command --headless -- --multi-test
```

The model generator uses Blender's built-in Python API. With **Blender 4.5 or later** available as `blender`, regenerate the scene and exports with:

```sh
blender --background --factory-startup --python-exit-code 1 --python models/foot-fa01/src/build.py
```

The [model README](models/foot-fa01/README.md#reproduce-the-build) documents rendering and verification. Git retains the playable game's GLB, the editable Blender scene, final presentation images, and the construction film. The model output GLBs and ZIP archives are generated locally and ignored, along with rendered video frames, inspection previews, engine caches, logs, Python bytecode, and Blender backups.
