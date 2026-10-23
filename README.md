# Gundam Build Simulator

A first-person mecha workshop prototype: organise parts, follow illustrated manuals, and assemble a giant robot one component at a time.

The full-game design targets an **18 m piloted mecha**. The current prototype is a **175-piece supported left-leg workshop**: build the foot and structural leg, hoist it into a pelvis held by a gantry, then fasten the hip retainers. The expanded Godot hangar includes component stations, lifting equipment, personnel platforms, linked manuals and save/resume. Its FA-01 foot retains **745 separate source parts** and a reproducible Blender generation pipeline.

![FA-01 assembled foot, with separate armor, frame, ankle mechanisms, and sole pads](models/foot-fa01/output/foot-fa01-assembled.png)

## Watch the assembly

![FA-01 foot separating from its assembled form into an exploded view](models/foot-fa01/output/foot-fa01-exploding.gif)

## Play the workshop

![Heel-pad assembly in the workshop, with the illustrated manual, placement preview and square inventory pockets](docs/images/heel-pad-demo.png)

*Earlier component-workshop view; the default scene now includes leg assembly and a final bay.*

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

The foot stays in a mechanical cradle. Use **E** at its controls to select a working position, then transfer the completed upright foot to dispatch. The leg-area hoist moves it into the assembly fixture. Fit the shin, knee and thigh, using the personnel lifts to reach each connection. Transfer the supported leg to the final bay, seat its integral hip ball, fit both retaining halves and their hardware, engage the stabilizer and release the hoist. Small preparation stations retain free rotation.

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

See the [workshop README](game/workshop/README.md) for the build sequence, controls and limitations. The default workshop saves locally every 30 seconds of active play, on pause and on quit, then resumes into the pause menu. The earlier foot-only workshop remains available with `./play.command -- --foot-workshop` and retains its separate save. This is a structural leg blockout: the pelvis starts assembled; detailed leg actuators, armor, torso and second leg remain future work.

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
| [Current workshop plan](design/game/leg-workshop-next-steps.md) | Playtest feedback, agreed handling direction, and implementation steps |
| [Supported left-leg milestone](design/game/leg-milestone.md) | Expanded workshop, equipment, construction scope and verification |
| [Leg and pelvis interfaces](design/game/leg-prototype-interface.md) | Physical parts, dimensions, ownership and manual dependencies |

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
