# Gundam Build Simulator

A first-person mecha workshop prototype: organise parts, follow illustrated manuals, and assemble a giant robot one component at a time.

The full-game design targets an **18 m piloted mecha**. The current prototype is one continuous build in a Godot hangar. Build the left foot's heel pads and pitch actuator, then assemble the robot's structure: pelvis, both legs, torso, arms and head. The hangar includes component stations, a turning foot fixture, a service crane, lifting equipment, personnel platforms and linked manuals. Its FA-01 foot retains **745 separate source parts** and a reproducible Blender generation pipeline.

![FA-01 assembled foot, with separate armor, frame, ankle mechanisms, and sole pads](models/foot-fa01/output/foot-fa01-assembled.png)

## Watch the assembly

![FA-01 foot separating from its assembled form into an exploded view](models/foot-fa01/output/foot-fa01-exploding.gif)

## Play the workshop

![Compact crane movement controls with a separate Change load button](docs/images/workshop-crane-controls.png)

*Current M3 crane controls. Choose a load separately, then operate the crane from
one compact panel. The manual and pockets return when you close the console.*

![Mobile platform with labelled Up, Down and Move buttons](docs/images/workshop-mobile-controls.png)

*Dedicated height controls and a Move menu for choosing a destination. Elevators use only Up/Down
onboard, with Call buttons at landings. See the [load chooser and elevator
screenshots](game/workshop/README.md#equipment-controls) and the
[verification checklist](design/game/m3-wide-playtest-checklist.md#focused-controls-check--2026-10-24).
These are rendered UI fixtures; hands-on acceptance is pending. Regressions were
not run for this revision, at the user's request.*

Use **Godot 4.7.2**. On macOS, double-click [play.command](play.command), or run it from the repository root:

```sh
./play.command
```

The launcher finds Godot on your PATH, in `/Applications/Godot.app`, or in the existing local tool cache. You can also specify an executable:

```sh
GODOT_BIN=/path/to/godot ./play.command
```

On other platforms, open [game/workshop/project.godot](game/workshop/project.godot) in Godot and run the project. The first launch imports the model.

The game starts in the final-assembly hangar. Prepare two independent heel pads and the pitch actuator at the preparation stations, then secure them to the left foot, which waits in a turning fixture in the foot bay. Use **E** at the fixture controls to turn the foot to a working position. Labelled wall drawers supply small hardware; shelves hold larger components. The foot manual links to each build, remembers your pages, and tracks preparation and installation. A ghost preview shows valid placements.

With the foot upright, the wider workshop continues. Deliver the pelvis to the gantry, then crane the foot to dispatch and build the structural leg on the shared holder. The right leg, chest, core, backpack, arms, pauldrons and head follow, using the crane console, personnel lifts and local equipment controls.

To start later in the build, add a stage. The game supplies the earlier work by script:

```sh
./play.command -- --stage=actuator      # heel pads fitted; build the pitch actuator
./play.command -- --stage=pelvis        # foot complete; deliver the pelvis
./play.command -- --stage=left_arm      # any later stage, up to --stage=complete
```

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

See the [workshop README](game/workshop/README.md) for every stage name, the build sequence, controls and limitations. The robot game does not save yet: quitting or restarting begins again from the launch's starting stage. The earlier saved foot-only workshop remains a development profile (`./play.command -- --profile=foot`) and keeps its separate save. This is a structural blockout: detailed actuators, armor and finished art remain future work.

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
| [Current workshop state](design/game/leg-workshop-next-steps.md) | Current status, active rules, player feedback, and which design document to read when |
| [Wider M3 workshop plan](design/game/m3-wide-workshop-plan.md) | Whole-robot workshop stages, equipment and verification scope |
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
