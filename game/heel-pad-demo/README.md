# FA-01 pads and pitch-actuator workshop

Godot 4.7.2 · GDScript · Jolt Physics · macOS desktop · Shared assembly model and nested manuals

A first-person workshop using the existing full-size foot model. Prepare two independent heel pads and a complete **91-piece pitch actuator**, then install them on the foot. The actuator installation adds **18 mounting pieces**, for **135 playable source identities**. The other 610 source pieces remain preassembled context or staged armor. No source objects have been removed from the 745-piece inventory.

The FA-510 actuator barrel starts on the floor beside preparation C. Pick it up with E, then click the empty station to suspend it. Its manual has 14 pages covering the internal drive, shaft retention, rod, sensors, seals, closure, eyes, and installation handoff. The foot manual owns both clevises and the two retained eye-pin connections.

## Launch

Double-click [play-heel-pad.command](../../play-heel-pad.command) in Finder. The demo opens in **non-exclusive (borderless) fullscreen** by default. Click **Start building**. Escape releases the mouse and opens the grouped controls menu; **Resume** returns to the build. Godot uses a fullscreen desktop on macOS.

To inspect or edit the project, double-click [edit-heel-pad.command](../../edit-heel-pad.command), or open [project.godot](project.godot) in Godot 4.7.2.

From a terminal at the repository root:

```sh
./play-heel-pad.command
./edit-heel-pad.command
```

The launcher uses the task-local Godot installation at `$HOME/.cache/gundam-tools/Godot-4.7.2/Godot.app/Contents/MacOS/Godot`. It also accepts `GODOT_BIN` and can find a `godot` command or `/Applications/Godot.app`. The official macOS download was checked against its published SHA-512 manifest before installation. The launcher imports assets automatically when the import cache is absent.

## Collecting and building

1. Walk to the **wall cabinets**. Small parts have closed drawers with a **part ID, image, name and stock count**. Larger components remain visible on shelves. Storage has two rows, with the upper row at chest height.
2. Press **E** on a drawer to fill a pocket with up to **20 copies** from the available stock. A matching pocket is topped up; otherwise an empty pocket is used and selected. When all ten pockets are occupied, E replaces the selected stack and returns the displaced pieces to their drawer. An empty drawer never evicts stock.
3. The **ten persistent pockets** are hotkeyed to **1 2 3 4 5 6 7 8 9 0**. Their images, IDs and quantities show what you actually have. Switching manuals or pages never changes the bar. There is no shared item-count limit.
4. **B clears the selected pocket anywhere**, returning the whole stack to its drawer. Small parts never become loose world objects. **Q** sets down a carried shelf component or assembly. Hands operate separately from the hotbar; no numbered key is reserved for hands.
5. Open the **Foot** manual. **C** cycles the foot and individual builds; **Enter** opens the linked child and **Backspace** returns to the foot. Arrows turn pages; **Page Up / Page Down** scroll longer instructions. Each page lists the same part IDs as the drawers and shelves, with names as clarification.
6. Carry either FA-302 heel pad with E and click an empty preparation station. Stock FA-305, W-24 and H-24120 in separate pockets. Fit four FA-305 sleeves, seat the pad at either heel position, then fit W-24 before H-24120 at each connection.
7. Pick up FA-510 from the floor beside preparation C and suspend it there to start the FA-500-P pitch build. Follow its 14 child pages, collecting the displayed IDs. Internal retention, sensors and seals precede cap closure. The foot manual then covers both FA-220 clevises, seating FA-500-P, and retaining both ends with FA-221, FA-222, W-12 and H-12030.

**Undo follows the selected manual.** Mounted children must be detached through the parent history before editing their internals. A detached child returns intact to a free preparation station. Small undone parts return to their matching or an empty pocket; if no suitable pocket has space, they return to their drawer. Undo never replaces another stack. Larger undone components appear on the output tray.

The earlier scenarios remain available:

```sh
./play-heel-pad.command -- --single-pad
./play-heel-pad.command -- --pads-only
```

## Controls

| Input | Action |
| --- | --- |
| WASD / mouse | Move / look |
| Shift while moving | Move faster |
| Hold Ctrl | Crouch for a lower inspection view; release to stand when there is headroom |
| E | Stock/refill a pocket from a drawer, or carry a shelf component/assembly |
| 1 2 3 4 5 6 7 8 9 0 | Select one of the ten pockets |
| Left click | Attach the selected small part, or place the carried component/assembly |
| Q | Set down the carried component or assembly |
| B | Clear the selected pocket anywhere; its stack returns to storage |
| Hold R + move mouse | Rotate the station you are looking at |
| Double-tap R | Restore that station's working orientation (F remains an alternate binding) |
| Mouse wheel | Inspect zoom |
| Tab or M | Open/close HUD manual |
| Left/right arrows | Change page in the selected manual |
| Page Up / Page Down | Scroll longer instructions and part lists |
| Enter / Backspace | Open child / return to parent foot manual |
| C | Cycle the foot and individual build manuals |
| V | Open the inspected build manual |
| Z | Undo the latest action in the selected manual |
| Escape | Open grouped controls, resume, restart the build, or quit; restarting asks for confirmation |

Each of the ten pockets holds one small-part type, with up to 20 copies per stack. Assemblies and shelf components are carried separately using the assisted grip. Attachment reach is initially 2.35 m from the camera/player to the actual connection, and pad connections use a 15 cm targeting radius; actuator component targets use 24 cm. These are tunable prototype values.

## Implemented behavior

- Real source geometry and metre scale: 745 source meshes, with exactly 135 identities removed from the preassembled context and used in the playable inventory.
- Firm two-handed carrying. A collision-aware kinematic grip follows the camera without a spring or angular momentum. Translation is swept against scenery and turning checks intermediate orientations. Dropping restores normal rigid-body physics. Placement still checks the swept approach and destination against scenery and loose obstacles.
- Stable suspended assemblies with free station rotation, double-tap R to reset, and a contextual rotation tutorial beside nearby stations. Holding R locks rotation to the station you began inspecting.
- Hold-to-crouch movement with a lower camera/collision capsule and an overhead clearance check before standing.
- Ten persistent pockets with baked part images, IDs and per-stack counts, a separate carrying summary, and a grouped Escape menu with keyboard focus, clear resume/restart actions, and no permanent general-controls strip.
- Non-exclusive fullscreen at launch, with the HUD scaled to the display.
- Finite labelled drawers for small parts, open shelves for larger components, a preparation tray, and part-ID tooltips. Small stock has no loose 3D meshes or physics bodies; installed parts and attachment previews still use their source geometry.
- Interchangeable matching hardware. The chosen socket supplies the destination, while the installed object retains its physical identity.
- Preview and installed rendering use the receiving slot's source mesh and pose together. Some source fasteners bake their orientation into their vertices, so reusing another instance's mesh with only a new node transform gives an incorrect fit. The consumed physical identity remains in the assembly model and visual metadata.
- Suspended and mounted assemblies use static freeze mode to follow their parent through continuous rotation. Pickup restores the collision-aware carrying mode; dropping restores dynamic physics.
- A shared, input-independent assembly model for slot prerequisites, compatible types/variants, milestones, unique ownership, and undo. Two pad instances use one authored definition; their parent owns the seating and fastening slots.
- Independent mounting-point order, a ghost preview, reach/occlusion checks, and explicit failure feedback.
- A parent foot manual and three independent child manual sessions, with authored steps, remembered pages, model-based illustrations, automatic progress, and completion sound/glow.
- Manual-scoped build undo: small hardware returns to pockets or its drawer; undoing a mounting action returns the prepared child to an empty station. Walking, carrying, and storage arrangement are not rewound.

## Verification

The linked test scripts generate local JSON audits under `verification/`. Generated audits, screenshots, meshes and review galleries are excluded from new commits. Previously tracked evidence remains historical.

- [Manual page audit](tests/pockets_workshop_test.gd): 31 runtime page views across the single-pad, two-pad and pitch scenarios, covering step-only lists, quantities, prepared assemblies, instruction references, unique installation coverage and available stock. Overview/readiness pages have no component shopping list.
- [Pocket model audit](tests/pockets_model_test.gd): ten stacks of 20, top-up, full-bar replacement, clearing, empty-drawer atomicity, undo overflow and exact physical identities.
- [Pocket workshop audit](tests/pockets_workshop_test.gd): all ten number keys, immediate hotbar counts, manual independence, drawer/shelf images and IDs, two storage rows, clearing away from storage, separate carrying, scrolling and layout. Hotbar/catalogue images use no live 3D viewports.

- [Pitch model audit](tests/pitch_model_test.gd): inventory counts, manual construction order, cap dependencies, carrying exclusivity, long-part recovery, and combined 135-piece completion.
- [Pitch desktop audit](tests/pitch_build_test.gd): 285 checks. Collects and fits all 90 pieces onto the barrel through desktop controls, compares actual installed vertices against the source at every construction page, carries and installs the completed actuator with all 18 mounting parts, checks station/foot rotation, and undoes the parent installation while retaining child progress.

- [Original state regression](tests/state_test.gd): 57 checks through the new model, including independent order, finite stock, pocket clearing/refilling, identity, completion, and full undo.
- [Generic model audit](tests/assembly_model_test.gd): 45 checks including invalid references/cycles, duplicate ownership, incompatible variants, shared stock, nested undo, and a separate three-slot recipe with a differently named parent. The alternate recipe is a state-level fixture, not new playable content.
- [Original interaction regression](tests/demo_test.gd): the single-pad interaction suite, including movement, firm carrying, reach/occlusion, crouch, station rotation, fullscreen, and restart cancellation.
- [Two-build interaction audit](tests/multi_build_test.gd): 65 checks through the public controls and real targeting/physics, including shared stock, manual navigation, station exchange, swapped heel positions, completed installations, nested undo, and continuous R-drag between physics ticks. Rotation checks compare body, mesh and physics poses for both mounted pads.
- Local captures `verification/07-multiple-builds.png` and `verification/08-two-pads-complete.png` show the independent builds and completed pads. They were captured and visually inspected earlier in this implementation pass; final verification runs headlessly. Tracked single-pad milestone views 01–06 are historical.

```sh
./play-heel-pad.command --headless --script tests/state_test.gd
./play-heel-pad.command --headless --script tests/assembly_model_test.gd
./play-heel-pad.command --headless --script tests/pitch_model_test.gd
./play-heel-pad.command --headless --script tests/pockets_model_test.gd
./play-heel-pad.command --headless -- --single-pad --demo-test
./play-heel-pad.command --headless -- --multi-test
./play-heel-pad.command --headless -- --pitch-test
./play-heel-pad.command --headless -- --pockets-test
```

All eight commands run headlessly. The last four exercise the desktop input adapter and actual physics/targeting without opening a window. Test input is isolated from live desktop events. The pitch test can also use `--fixed-fps 60` to advance simulated time faster. Headless runs skip audio playback. Rendered verification is a separate, explicitly requested check. Automated checks verify functionality; human play remains the test of pacing and comfort.

The local 2026-10-21 actuator visual review (`verification/pitch-visual-review/review.md`) inspected all 14 actuator pages and every component placement. **Visual approval failed:** missing receiving holes, overlapping or buried hardware, obstructed eye openings and unclear diagrams require repairs before expanding assembly content. Component lists and behavior checks passed. Source geometry agreement alone does not establish mechanical correctness or readable instructions.

Reproduce the actuator captures using the real renderer, then generate the review gallery (Pillow required):

```sh
./play-heel-pad.command --disable-render-loop --fixed-fps 60 -- --pitch-test --pitch-review
python3 game/heel-pad-demo/tools/build_pitch_review_gallery.py
```

This opens a window and captures before/preview/after placements, opaque/service/exposed inspection angles, HUD pages and continuous rotation. `--headless` is rejected for this mode. Local evidence and code/asset hashes are in `verification/pitch-visual-review/`; capture generation does not grant visual approval. Preserve this failed baseline before rerunning after repairs. Supplementary parent views need better receiver context, and the remaining default-workshop pages still need the [full review process](../../design/game/foot-prototype-plan.md#manual-and-assembly-visual-review).

## Scope and current limits

This milestone delivers increments 1–3 of the multiple-build plan. Save/resume is the next increment; full-foot progression, lifts, AR input, and remaining robot assemblies are future work. Progress currently lasts for the session only.

The reusable construction model owns prerequisites, inventory, carrying capacity, milestones and undo. `component_interaction.gd` projects arbitrary authored component slots into desktop collection, grip, placement, and service views. Pad connections retain their established four-opening adapter. The generic model supports the new content without requiring pad-shaped rules.

Collision uses simplified shapes. Internal work uses an assisted service view through the enclosing build, while scenery and carried-part approaches remain solid. It does not simulate threading, torque, or the real insertion of each sealed internal component. Actuator motion and external wiring are outside this build/install milestone. The revised cabinet layout and manual pacing still need human playtesting. The visual review does not measure an on-screen frame-rate improvement. Earlier pad captures are historical.

The room is a functional workshop blockout. Its layout, lighting, carrying distances, and targeting tolerance remain suitable subjects for the first human playtest. Completion feedback is intentionally a sound and glow.

## Data model and project structure

- [workshop.gd](scripts/workshop.gd): room, imported geometry, player, targeting, carrying, station interaction, and completion presentation.
- [part_storage.gd](scripts/part_storage.gd): low cabinets, shelves, cached catalogue images and stock labels. Images are generated from the source GLB by `python3 game/heel-pad-demo/tools/render_part_images.py` (Pillow required only for regeneration).
- [component_interaction.gd](scripts/component_interaction.gd): authored component targeting, shelf-piece carrying, incremental installed visuals, and service views.
- [assembly_model.gd](scripts/assembly_model.gd): reusable ownership, transfer, placement validation, milestones, and scoped history.
- [assembly_state.gd](scripts/assembly_state.gd): pad-specific desktop projection over the shared model, plus the single-pad regression configuration.
- [loose_part.gd](scripts/loose_part.gd): solid carried and dropped objects.
- [hud.gd](scripts/hud.gd) and [manual_diagram.gd](scripts/manual_diagram.gd): instructions, inventory, tooltips, help, and live illustrations.
- [assembly-definitions.json](assets/assembly-definitions.json): part types, child and parent slots, prerequisites, milestone sets, work locations, geometry references, and manual steps.
- [heel-pads.json](assets/heel-pads.json): 26 source identities, physical build instances, starting positions, and parent destinations.
- [pitch-workshop.json](assets/pitch-workshop.json) and [pitch-actuator-definitions.json](assets/pitch-actuator-definitions.json): 135-piece scenario and the actuator/parent recipe overlay. Regenerate with `python3 game/heel-pad-demo/tools/author_pitch_actuator.py`; the authoring script resolves the exact pitch block in the source manifest and explicitly authors prerequisites separately from animation phases.
- [heel-pad.json](assets/heel-pad.json): original 13-piece regression scenario metadata.
- [Original model package](../../models/foot-fa01/README.md), [game design](../../GAME_DESIGN.md), and [prototype plan](../../design/game/foot-prototype-plan.md).

A slot accepts one part-type key (which includes a specific variant) or a child assembly definition with a required milestone. `requires` lists local slot IDs. Slots refer to imported GLB transforms through `pose_source`; accessible targets are authored separately. Manual steps reference the same slot IDs. Root parts begin assigned to their child assembly; logical containers never create extra physical inventory. Child placement transfers that container into a parent slot while retaining all descendant identities.

Stations provide occupancy, rotation, and work-volume checks. Collection and construction rules do not depend on keyboard bindings or camera transforms; desktop targeting supplies the reach/occlusion and placement poses. Future AR input can call the same model operations.

The copied GLB is unchanged from the source export. Its imported transforms govern placement; the source manifest's Blender-axis custom position metadata must not be applied directly as Godot coordinates. The animation's assembly phases are not used as gameplay dependencies.

Godot is used under its [MIT license](https://godotengine.org/license/). Engine references: [GLB import](https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/importing_3d_scenes/available_formats.html), [Jolt Physics](https://docs.godotengine.org/en/stable/tutorials/physics/using_jolt_physics.html), [3D collision shapes](https://docs.godotengine.org/en/stable/tutorials/physics/collision_shapes_3d.html), and [rigid-body behavior](https://docs.godotengine.org/en/stable/classes/class_rigidbody3d.html).

Carry implementation references: [kinematic freeze mode](https://docs.godotengine.org/en/stable/classes/class_rigidbody3d.html#enum-rigidbody3d-freezemode), [collision-aware body movement](https://docs.godotengine.org/en/stable/classes/class_physicsbody3d.html#class-physicsbody3d-method-move-and-collide), and [non-exclusive fullscreen](https://docs.godotengine.org/en/stable/classes/class_displayserver.html#enum-displayserver-windowmode).

Attached assemblies use the [static freeze mode](https://docs.godotengine.org/en/stable/classes/class_rigidbody3d.html#enum-rigidbody3d-freezemode), which leaves their movement to scene code. The rotation regression reproduces the old carrying-mode transform conflict during input between physics ticks, rather than relying only on settled transforms.
