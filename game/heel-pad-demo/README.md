# FA-01 heel-pad workshop demo

Godot 4.7.2 · GDScript · Jolt Physics · macOS desktop · First playable milestone

A first-person workshop study using the existing full-size foot model. Prepare one heel pad with four sleeves, carry it to the suspended foot, and install four washers and four bolts. All **13 playable pieces** come from the original FA-01 geometry; the rest of the foot provides preassembled context.

## Launch

Double-click [play-heel-pad.command](../../play-heel-pad.command) in Finder. The demo opens in **non-exclusive (borderless) fullscreen** by default. Click **Start building**. Escape releases the mouse and opens the grouped controls menu; **Resume** returns to the build. Godot uses a fullscreen desktop on macOS.

To inspect or edit the project, double-click [edit-heel-pad.command](../../edit-heel-pad.command), or open [project.godot](project.godot) in Godot 4.7.2.

From a terminal at the repository root:

```sh
./play-heel-pad.command
./edit-heel-pad.command
```

The launcher uses the task-local Godot installation at `$HOME/.cache/gundam-tools/Godot-4.7.2/Godot.app/Contents/MacOS/Godot`. It also accepts `GODOT_BIN` and can find a `godot` command or `/Applications/Godot.app`. The official macOS download was checked against its published SHA-512 manifest before installation. The launcher imports assets automatically when the import cache is absent.

## First build

1. Approach the labelled bins. **Shift + E** takes the four available pieces from a bin; gather sleeves, washers, and bolts into your pockets.
2. Look at the heel pad on its table and press **E** to carry it. Look into the small preparation station and **click** to suspend it.
3. Select sleeves with **1**. Aim near each opening, wait for the green preview, and click. Each point can be completed independently. Four sleeves produce a sound and glow.
4. Look at the prepared pad and press **E**. Carry it to the missing heel position on the full-size foot. With hands selected (**4**), aim at the opening and click to mount it.
5. Select washers with **2**, then bolts with **3**. Each bolt requires its own washer. Complete the four points in any order. The manual records **13 / 13** and the completed pad sounds and glows.

The four-slot action bar shows actual 3D part models, part IDs, available quantities, and the selected slot. The HUD manual illustrates the build sequence and records current progress. General controls live in the Escape menu; there is no workshop header or permanent controls strip. You can prepare supplies on the nearby tray, put down an unfinished pad, or switch tasks. Build state stays with the pad for the current session.

## Controls

| Input | Action |
| --- | --- |
| WASD / mouse | Move / look |
| Shift while moving | Move faster |
| Hold Ctrl | Crouch for a lower inspection view; release to stand when there is headroom |
| E | Pick up pad or loose hardware; take one piece from a bin |
| Shift + E | Take remaining matching bin stock, subject to pocket capacity |
| 1 / 2 / 3 | Select sleeves / washers / bolts |
| 4 | Select hands / carried pad |
| Left click | Attach at the highlighted connection or place the pad in a station |
| Q | Set down the pad or drop one selected pocket item |
| B while looking at its bin | Return one selected hardware piece to storage |
| Hold R + move mouse | Rotate the station you are looking at |
| Double-tap R | Restore that station's working orientation (F remains an alternate binding) |
| Mouse wheel | Inspect zoom |
| Tab or M | Open/close HUD manual |
| Left/right arrows | Change manual page |
| Z | Undo the latest build action |
| Escape | Open grouped controls, resume, restart the build, or quit; restarting asks for confirmation |

Pockets hold up to 20 small pieces; this scenario supplies 12. The heel pad occupies both hands. No other hand-sized object class is needed by this scene. Attachment reach is initially 2.35 m from the camera/player to the actual connection, and each small connection has a generous 15 cm targeting radius. These are tunable prototype values.

## Implemented behavior

- Real source geometry and metre scale: 745 source meshes, with exactly 13 identities removed from the preassembled context and used in the playable inventory.
- Firm two-handed carrying. A collision-aware kinematic grip follows the camera without a spring or angular momentum. Translation is swept against scenery and turning checks intermediate orientations. Dropping restores normal rigid-body physics. Placement still checks the swept approach and destination against scenery and loose obstacles.
- Stable suspended assemblies with free station rotation, double-tap R to reset, and a contextual rotation tutorial beside nearby stations. Holding R locks rotation to the station you began inspecting.
- Hold-to-crouch movement with a lower camera/collision capsule and an overhead clearance check before standing.
- Four model-based action slots, a compact inventory summary, and a grouped Escape menu with keyboard focus, clear resume/restart actions, and no permanent general-controls strip.
- Non-exclusive fullscreen at launch, with the HUD scaled to the display.
- Finite labelled bins, physical dropped hardware, a preparation tray, and object ID/name tooltips.
- Interchangeable matching hardware. The chosen socket supplies the destination, while the installed object retains its physical identity.
- A shared build-state model for dependencies, progress, compatibility errors, completion, and undo.
- Independent mounting-point order, a ghost preview, reach/occlusion checks, and explicit failure feedback.
- A three-page illustrated HUD manual, automatic progress, and a short generated completion chord/glow.
- Simple build undo: hardware returns to pockets (or the output tray if full); undoing the parent mounting action returns the prepared pad to the small station. Walking, carrying, and storage arrangement are not rewound.

## Verification

- [Delivery audit](verification/delivery-audit.json): 57 passing state checks, 92 passing rendered interaction checks, unchanged source GLB, and checksums for the verified code.
- [State audit](verification/state-audit.json): prerequisite rejection, independent order, finite stock, capacity, identity conservation, complete construction, and complete undo.
- [Rendered interaction audit](verification/demo-audit.json): public input handlers, actual camera targeting and physics, collecting/dropping/recollecting, preparation, parent installation, washers/bolts, reach, occlusion, rotation, manual/help controls, undo, solid carrying/placement, grip stability while moving/turning, crouch/headroom, double-tap versus drag behavior, action-bar models/counts, fullscreen mode, and restart cancellation.
- Captured rendered states: [workshop](verification/01-workshop.png), [preparation](verification/02-pad-preparation.png), [mounting preview](verification/03-mount-preview.png), [completion](verification/04-complete.png), [controls](verification/05-controls.png), [pause menu](verification/06-paused.png).

The interaction runner scripts camera locations and sends the same key/click handlers used in play. It checks the actual world queries and inventory results. This verifies functionality; a human play session is still needed to judge comfort and enjoyment.

To reproduce the checks from the repository root:

```sh
./play-heel-pad.command --headless --script tests/state_test.gd
./play-heel-pad.command -- --demo-test
```

The second command opens a rendered test window, saves the six images and audit, then exits. A headless alternative is `./play-heel-pad.command --headless -- --demo-test`; this runs 90 interaction checks, skipping the two display checks, and does not produce images. Generated verification files are local diagnostics.

## Scope and current limits

This milestone completes one heel-pad operation. The other foot components are visual context, and the second pad, full-foot progression, elevators, and remaining robot are future work. The existing source inventory has not been reduced.

Progress lasts for the current session; closing or resetting starts a fresh study. Long-term save/load is not implemented. Collision uses simplified shapes, and the rest of the foot is a stable assembly rather than a full mechanical simulation. The supplied bins contain exactly the required hardware. Two-handed carrying is exercised by the pad; two simultaneous hand-sized objects are not part of this scene.

The scene and assembly-state rules still explicitly describe a heel pad. Reusable assembly definitions, interchangeable stations, and manuals driven by those definitions are the proposed next pass, not delivered generic functionality.

The room is a functional workshop blockout. Its layout, lighting, carrying distances, and targeting tolerance remain suitable subjects for the first human playtest. Completion feedback is intentionally a sound and glow.

## Project structure and sources

- [workshop.gd](scripts/workshop.gd): room, imported geometry, player, targeting, carrying, station interaction, and completion presentation.
- [assembly_state.gd](scripts/assembly_state.gd): physical inventory, valid construction, and history.
- [loose_part.gd](scripts/loose_part.gd): solid carried and dropped objects.
- [hud.gd](scripts/hud.gd) and [manual_diagram.gd](scripts/manual_diagram.gd): instructions, inventory, tooltips, help, and live illustrations.
- [heel-pad.json](assets/heel-pad.json): selected source identities, part types, carry classes, and converted reference positions.
- [Original model package](../../models/foot-fa01/README.md), [game design](../../GAME_DESIGN.md), and [prototype plan](../../design/game/foot-prototype-plan.md).

The copied GLB is unchanged from the source export. Its imported transforms govern placement; the source manifest's Blender-axis custom position metadata must not be applied directly as Godot coordinates. The animation's assembly phases are not used as gameplay dependencies.

Godot is used under its [MIT license](https://godotengine.org/license/). Engine references: [GLB import](https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/importing_3d_scenes/available_formats.html), [Jolt Physics](https://docs.godotengine.org/en/stable/tutorials/physics/using_jolt_physics.html), [3D collision shapes](https://docs.godotengine.org/en/stable/tutorials/physics/collision_shapes_3d.html), and [rigid-body behavior](https://docs.godotengine.org/en/stable/classes/class_rigidbody3d.html).

Carry implementation references: [kinematic freeze mode](https://docs.godotengine.org/en/stable/classes/class_rigidbody3d.html#enum-rigidbody3d-freezemode), [collision-aware body movement](https://docs.godotengine.org/en/stable/classes/class_physicsbody3d.html#class-physicsbody3d-method-move-and-collide), and [non-exclusive fullscreen](https://docs.godotengine.org/en/stable/classes/class_displayserver.html#enum-displayserver-windowmode).
