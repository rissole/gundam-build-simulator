# First playable foot build — proposed next steps

Prepared: 2026-10-21

[Agreed game design](../../GAME_DESIGN.md) · [Robot design](../../ROBOT_DESIGN.md) · [Foot assets](../../models/foot-fa01/README.md)

**Status:** the user subsequently authorized a goal to build the Godot heel-pad demo. The [first playable project](../../game/heel-pad-demo/README.md) implements stages 1–3 below; its README and audit files record the delivered behavior and verification. Later stages remain proposed. The plan below preserves the rationale and expansion path.

## Engine recommendation

Use **Godot 4 with GDScript and built-in Jolt Physics** for the first desktop playable. The user accepted this direction by authorizing the Godot demo; the implemented project uses Godot 4.7.2.

- The existing assembled GLB can enter Godot through its supported glTF/GLB import pipeline. [Official format documentation](https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/importing_3d_scenes/available_formats.html).
- Jolt is built into Godot and is the default for new projects in the current stable documentation. It supplies the foundation for loose-object and carrying collisions; the desired handling feel still needs custom behavior and tuning. [Official Jolt documentation](https://docs.godotengine.org/en/stable/tutorials/physics/using_jolt_physics.html).
- The official editor supports macOS, including Apple Silicon, and desktop exports including Windows. [Official platform FAQ](https://docs.godotengine.org/en/stable/about/faq.html).
- Godot is free and open source under the MIT license. [Official license](https://godotengine.org/license/).

The official [macOS download page](https://godotengine.org/download/macos/) lists **4.7.2** when checked on 2026-10-21. The first demo is pinned to that release and runs on this Mac with mouse and keyboard; shipping platforms remain open.

GDScript is the proposed implementation language to keep this first project within Godot's standard toolchain. There is no requirement here for engine-specific advanced rendering or a literal Source-engine recreation. Existing expertise in another engine could outweigh this recommendation.

## What already exists, and what is missing

| Existing material | Use in the game | Work still required |
| --- | --- | --- |
| [Assembled GLB](../../models/foot-fa01/output/foot-fa01-assembled.glb) | Detailed visual geometry, 745 separate nodes and meshes, assembled transforms | Import validation, carry pivots, collision proxies, interaction ownership |
| [Parts manifest](../../models/foot-fa01/output/parts-manifest.json) | Family IDs, unique instance IDs, names, groups, positions; some hardware ownership metadata | Carry classes, attachment slots, prerequisite relationships, subassembly definitions |
| [Written construction sequence](../legs/foot-and-ankle/assembly-and-review.md) and [actuator construction](../legs/foot-and-ankle/actuators.md) | Authoring references for dependencies and manuals | Review and encode the actual dependencies and valid independent branches |
| [Hardware schedule](../legs/foot-and-ankle/hardware.csv) | Exact families and counts by use | Map compatible hardware to individual locations |
| [Animated GLB](../../models/foot-fa01/output/foot-fa01-animated.glb) | Visual reference for the existing assembly presentation | Interactive state must be authored separately; animation timing is not game logic |

The original planning inspection on 2026-10-21 confirmed 745 nodes, 745 distinct meshes, and approximately 1.17 million triangles in the static GLB. Inventory and export checks passed. Import and the rendered heel-pad interaction loop have since been verified in Godot; see the [demo delivery audit](../../game/heel-pad-demo/verification/delivery-audit.json). Full-foot gameplay performance and pacing remain future work.

Important import details:

- Use the static assembled GLB as the initial visual source. Preserve its authored transforms when deriving snap poses.
- The source manifest and custom `assembled_position_m` metadata use Blender axes: X right, Y forward, Z up. Actual GLB transforms have already been converted to glTF axes. Do not apply the manifest coordinates directly as Godot positions or convert GLB transforms twice. Prefer imported transforms as the canonical pose source.
- Object centers are not necessarily connection points. Author a separate accessible connection point for reach and targeting.
- A family ID alone does not prove interchangeability: nut plates, actuator variants, clevises, and other components have dimensional or handed variants. Match type and variant; allow genuinely identical pieces to fill equivalent slots regardless of source instance number.
- Existing `assembly_phase` values order an explanatory film. They do not encode the dependency graph that allows independent valid operations.

## First playable milestone: one complete heel-pad operation

Start with one heel pad on a full-size foot context. This is a deliberately small first playable milestone on the path to the full foot, not a new reduced-detail foot specification.

| Player-built contents | Quantity |
| --- | ---: |
| FA-302 heel pad | 1 |
| FA-305 compression sleeves | 4 |
| H-24120 pad-mount bolts | 4 |
| W-24 fastener washers | 4 |
| **Individual pieces** | **13** |

The initial scene provides a preassembled supporting foot frame and rear sole carrier, with this pad and its hardware absent. Display the context so the target is visible, and allow rotation of the full-size workpiece. The 13 active objects come from the existing model and must not remain duplicated in the displayed context.

The player prepares the pad with its four sleeves as a small subassembly, carries that assembly to the larger workpiece, seats it on the rear sole carrier, then fits its four washers and bolts. The small manual feeds into the parent manual. Bolts attach after their matching washers, pad preparation, and the receiving carrier are ready. Independent mounting points can be completed in any valid order. Final hardware belongs to the carrier-mounted stage; it must not appear to secure a freestanding pad to nothing.

A plain test corner needs labelled hardware bins, freely placeable larger parts, a nearby preparation surface, a small suspension station, and a suspension station for the foot context. The layout should offer room for solid carrying and station rotation. Its purpose is to expose the real interaction and scale, using simple workshop geometry.

This milestone contains:

- First-person movement, component tooltips, picking up, setting down, and solid carrying.
- Pockets and hand capacity, selection of carried items, and preparing nearby supplies.
- A freely toggled HUD manual with illustrations, quantities, and progress.
- Generous area targeting, a placement ghost, reach checks, dependency checks, and descriptive errors.
- One-click placement, persistent unfinished builds during the session, simple build undo, and a sound/glow on completion.
- A completed small subassembly used in a larger assembly.

Proposed convenience: after placing an item, keep that type selected when more are carried. This was suggested during discussion and should be checked during implementation rather than treated as a separately confirmed control rule.

## Implementation sequence and review points

| Stage | Concrete result | Evidence before expanding |
| --- | --- | --- |
| 1. Import and scale | Walk around the true-size foot; inspect the selected pad and separate hardware; rotate the workpiece | IDs and geometry survive import; foot length is about 3 m; no doubled coordinate conversion; comfortable visibility and acceptable baseline frame time |
| 2. Placement interaction | Pick up one item, target its local connection, see a stable ghost, and attach with one click | Adjacent points can be selected predictably; invalid order and out-of-reach attempts explain the problem; no automatic distant attachment |
| 3. Complete the 13-piece loop | Fetch, prepare, build the pad, install it, undo, resume, and finish using the HUD manual | Every piece is accounted for; actual dependencies are enforced; completion occurs at the right moment; user can complete the task without verbal guidance |
| 4. Exercise organisation and interruption | Add the second heel pad and allow the two builds to proceed independently | Preparing local stock is useful; carrying limits matter without tedious trips; returning to an unfinished build restores its manual state |
| 5. Expand to the full foot | Add frame, ankle/forefoot joints, all three detailed actuators, remaining soles, electrical parts, and armor through nested manuals | Each branch is reachable, complete, and compatible with parent assembly; full-foot performance and pacing are measured |

Stage 4 involves 26 active pieces, including 24 small items, so it begins to exercise the initial 20-item pocket capacity. One 13-piece pad alone cannot establish whether the full carrying/organisation loop works over longer sessions.

Expansion at stage 5 retains the 745-object source inventory. One boundary needs an explicit scenario rule: the inventory includes four shin-interface bolts and four washers, but the mating shin is not present. Recommended standalone-foot convention: account for all 745 objects, with those eight reserved for the later leg manual and the remaining 737 placed in the standalone foot. Confirm this convention before authoring the full-foot completion condition; do not create impossible shin attachments or silently discard those pieces.

The complete hangar, elevators, launch sequence, and other body sections follow after the foot loop has useful playtest evidence. Their full-game design remains recorded in the game-design file.

## Rules that make the first build reliable

Use a shared assembly description for placement, manual progress, error explanations, and completion. Separate scripts with different notions of the correct next piece would create confusing contradictions.

That description needs part type/variant, physical instance identity, parent assembly, attachment slot, local snap transform, accessible connection point, prerequisite slots or subassembly states, manual step, and completion grouping. Carry category and collision representation belong to the item definitions. An installed piece must have exactly one owner.

Geometry and physics have separate jobs. Retain the detailed visible meshes and use simpler primitive or convex collision shapes for carried parts. Mounted components should form a stable assembly instead of simulating every bolt as an independent connected rigid body. Preserve open working areas when choosing collision shapes: a single solid box around a hollow frame would obstruct valid connections. Godot's [collision-shape guidance](https://docs.godotengine.org/en/stable/tutorials/physics/collision_shapes_3d.html) recommends primitive shapes for dynamic objects and describes the limits of concave shapes.

Solid carrying remains a requirement. Moving a held mesh directly through shelves is not an acceptable substitute. At a valid connection, controlled snapping should complete the placement without requiring physical insertion of threads. Collision handling must distinguish the receiving assembly from unrelated obstacles, so snap assistance cannot be used to install through scenery.

Recommended undo semantics for the prototype: undo the latest placement in the selected build, retain the identities of returned pieces, and return them to available carrying capacity or a designated clear output spot. Undoing a child build already installed into a parent must first restore the child's independence; it cannot invalidate the parent invisibly. These are implementation proposals for the agreed simple history, not a new arbitrary-disassembly system.

Keep station rotation, world organisation, and walking outside build history. A completed subassembly retains its child pieces when transferred into a parent; no duplicate module inventory is created. Manual progress follows the physical assembly, not whichever station happens to hold it.

## What to learn from the playable

The first success condition is that a new player can follow the HUD instructions and finish the pad operation using only in-game feedback, with predictable placement and no lost or duplicated parts. They can undo and continue, leave a build unfinished, and return to it.

Observe time spent finding/carrying, preparing, consulting instructions, and placing parts; ambiguous target selections; repeated error attempts; unwanted collisions; and the player's desire to continue to the next assembly. These are diagnostic measures, not a timer or score imposed on the player.

Use the second pad to assess whether organisation and stocking supplies improve the experience. Use the later actuator and full-foot passes to assess repetition, subassembly navigation, larger carrying, and longer-term progress. A pleasant 13-piece task alone does not establish that all 745 objects are enjoyable to assemble.

The initial implementation deliverable is stages 1–3: a runnable desktop test containing the real foot context and one complete heel-pad build/install loop. This is now implemented in the [heel-pad demo](../../game/heel-pad-demo/README.md). The first human play session found the fetch-and-attach loop satisfying and approved the generous targeting. Its carry, HUD, rotation, crouch, and display feedback is recorded in the [game design](../../GAME_DESIGN.md#first-playtest-feedback-and-interaction-revision). Before stages 4–5, the proposed next development pass is to separate reusable assembly definitions from station behavior and prove them with a differently structured subassembly. The second pad remains useful for organisation and interruption testing.
