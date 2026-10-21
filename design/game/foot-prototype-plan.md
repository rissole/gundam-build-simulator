# First playable foot build — proposed next steps

Prepared: 2026-10-21

[Agreed game design](../../GAME_DESIGN.md) · [Robot design](../../ROBOT_DESIGN.md) · [Foot assets](../../models/foot-fa01/README.md)

**Status:** the user subsequently authorized a goal to build the Godot heel-pad demo. The [first playable project](../../game/heel-pad-demo/README.md) implements stages 1–3 below; its README and audit files record the delivered behavior and verification. Increments 1–3 of the multiple-build milestone below are now implemented: shared assembly rules, two pads, the complete pitch actuator and its installation, interchangeable preparation stations, and linked parent/child manuals. Save/resume and later full-foot work remain proposed. The plan below preserves the rationale and expansion path.

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
| [Assembled GLB](../../game/heel-pad-demo/assets/foot-fa01.glb) | Detailed visual geometry, 745 separate nodes and meshes, assembled transforms | Import validation, carry pivots, collision proxies, interaction ownership |
| [Parts manifest](../../models/foot-fa01/output/parts-manifest.json) | Family IDs, unique instance IDs, names, groups, positions; some hardware ownership metadata | Carry classes, attachment slots, prerequisite relationships, subassembly definitions |
| [Written construction sequence](../legs/foot-and-ankle/assembly-and-review.md) and [actuator construction](../legs/foot-and-ankle/actuators.md) | Authoring references for dependencies and manuals | Review and encode the actual dependencies and valid independent branches |
| [Hardware schedule](../legs/foot-and-ankle/hardware.csv) | Exact families and counts by use | Map compatible hardware to individual locations |
| [Animation model package](../../models/foot-fa01/README.md) | Visual reference for the existing assembly presentation | Interactive state must be authored separately; animation timing is not game logic |

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

Stage 4 involves 26 active pieces, including 24 small items. The pocket rebuild gives each of ten part types its own stack of up to 20; test that organisation across longer sessions rather than imposing a shared item-count limit.

Expansion at stage 5 retains the 745-object source inventory. One boundary needs an explicit scenario rule: the inventory includes four shin-interface bolts and four washers, but the mating shin is not present. Recommended standalone-foot convention: account for all 745 objects, with those eight reserved for the later leg manual and the remaining 737 placed in the standalone foot. Confirm this convention before authoring the full-foot completion condition; do not create impossible shin attachments or silently discard those pieces.

The complete hangar, elevators, launch sequence, and other body sections follow after the foot loop has useful playtest evidence. Their full-game design remains recorded in the game-design file.

## Recommended next milestone: multiple builds and nested manuals

**Proposal following the user's positive heel-pad feedback:** build a desktop workshop containing two heel-pad builds and one complete pitch actuator, with a parent foot manual for their installation. This expands the earlier stage 4 before committing to full-foot content authoring. The interaction priorities remain collecting pieces, following illustrated instructions, and comfortable handling. No headset milestone is required.

**Implementation status:** increments 1–3 below are delivered in the default 135-piece desktop workshop. The source-backed 91-piece pitch actuator and 18 mounting pieces join the two existing pad builds. Authored component targets, pocket and two-hand profiles, staged closure prerequisites, nested manual navigation, and parent undo now cover this longer branch. The pocket/storage rebuild adds ten persistent stacks, ID/image drawers and separate shelf carrying. Save/resume remains next.

### Playable scope

| Work | Physical pieces | What it tests |
| --- | ---: | --- |
| Two heel pads, including their sleeves and mounting hardware | 26 | Two instances of one definition, independent progress, shared hardware stock, interruption |
| One pitch actuator, FA-500-P | 91 | Different geometry, longer dependencies, internal components, multiple hardware families |
| Pitch actuator mounting components | 18 | Two clevises, four bolts/four washers, two eye pins, two keepers, two keeper screws/two washers; child-to-parent installation |
| **Proposed active total** | **135** | Several manuals within an exposed foot context |

These counts have been verified against the exact 135 source identities in the manifest and imported GLB. The remaining 610 source items stay explicitly accounted for as preassembled context or stored scenario items. Keep access open by staging obstructing context armor separately. This is a partial-foot scenario completion condition, not completion of the entire foot. The actuator's external wiring belongs to the later electrical branch.

Start with the existing pad migrated to the shared model, then add its second instance, then the actuator and its parent installation. Keep each increment playable. The 91-piece actuator is the substantial second test, not a requirement to finish all new content before testing the model. Use the written actuator sequence to author dependencies and review cap closure/access; animation phases alone cannot establish a valid construction order.

### Shared data model

Use explicit authored definitions and separate runtime instances. A small versioned JSON format, consistent with the existing asset configuration, is sufficient initially; validate it at load time. Do not build a general recipe editor before these examples work.

| Record | Responsibility |
| --- | --- |
| Part definition | Family plus compatible variant, display name, source mesh reference, carry class, collision/handling profile |
| Part instance | Unique physical identity and one location/owner: storage, pocket, loose world, carry state, or assembly slot |
| Assembly definition | Stable local frame, root/base role, required part and child-assembly slots, milestones, completion rules |
| Attachment slot | Accepted part/assembly type and variant, snap pose, accessible target point, receiving connection references, prerequisite slot/milestone IDs |
| Assembly instance | Definition ID, actual slot occupants and child identities, world/parent location, action history; progress derived from occupants |
| Manual definition | Ordered illustrated steps referencing slot/milestone IDs, required quantities, authored view/highlight information, child-manual links |
| Manual session | Selected assembly instance and remembered page per instance; independent of the occupied station |
| Station | Available work volume, suspended assembly, rotation and presentation; no recipe-specific construction rules |
| Scenario | Source inventory allocation, initial placements, preassembled context, available builds, scenario completion condition |

An assembly is a logical container of existing physical pieces, not an additional inventory object. Keep physical ownership as a tree, with exactly one owner per piece. Prerequisites form a separate acyclic graph. Connection references can link several receiving parts without giving an item multiple owners: for example, the pitch actuator connects the cradle and ring while belonging once to the foot assembly. This avoids treating every connection as a scene-parent relationship.

For the pad, preparation completes when its four sleeve slots are filled. The parent foot accepts that prepared child into a heel position. Parent mounting washers require that seated child; each mounting bolt requires its matching washer. The parent reports the pad secured only after all four bolts. This separates **prepared**, **seated**, and **secured**, instead of a single completion flag doing all three jobs. The same distinction supports actuator preparation, placement between clevises, and pin retention.

Derive manual progress, ghost validity, compatibility messages, and completion from the same slot rules. Manual page order suggests a useful sequence but does not add dependencies: independent bolts or branches remain buildable in any valid order. Physical targeting still supplies reach and obstruction checks alongside these logical rules.

Reuse imported GLB poses to author assembly-local snap transforms; explicitly author accessible connection points and variants. Hardware ownership metadata can seed slot assignments, but must be reviewed. Do not infer interchangeability solely from a family name or infer prerequisites from export order.

### How the manuals interact

The parent foot manual lists the two heel positions and pitch actuator branch with separate preparation and installation status. Selecting a child opens that physical build's manual with a breadcrumb back to the parent. A build list permits returning to any unfinished assembly. Two identical pad instances share the same manual definition but retain separate progress and last-viewed pages.

Opening a manual chooses instructions; it does not reserve interchangeable parts for that build. A prepared compatible pad can fill either compatible heel slot, retaining its identity and history. Any parent request initially associated with the other pad must resolve to the actual installed child. Distinct actuator variants remain distinct even when they share a manual template later.

Looking at another object should offer its manual without silently replacing the player's current page. Child completion updates the parent and offers a return to installation instructions. Show per-step remaining quantities and distinguish prepared stock from mounted/secured components. Keep an optional compact current-step view rather than opening several large manuals at once.

Replace the bespoke four-hole drawing with reusable model-based instruction views: authored camera angle, highlighted current components, faded surrounding context, and optional exploded offsets/arrows. Use the same referenced slots for diagrams and progress. Replace the fixed sleeve/washer/bolt action slots with a compact selector driven by carried item types; adding an actuator should not require a keyboard binding for every family.

### Implementation and review order

1. **Migrate one pad — implemented.** Introduce definitions, runtime ownership, and shared placement validation. Preserve the currently successful controls and pass the existing pad behavior checks through the new implementation. Desktop handlers supply gameplay actions and poses through an input boundary suitable for later AR adapters.
2. **Add the second pad and parent manual — implemented.** Prove independent page/progress state, interchangeable stock, any-order work, station exchange, and prepared-child installation. Stations must accept different compatible assemblies rather than own their recipes.
3. **Build and mount the pitch actuator — implemented.** Author its complete 91-piece definition and 18 mounting pieces. Exercise internal prerequisites, cover closure, multiple receiving connections, different carry profiles, and generic illustrated steps.
   **Next: repair the actuator visual-review findings.** The [2026-10-21 review](../../game/heel-pad-demo/README.md#verification) inspected all 14 child pages and every placement using the new rendered capture harness. Visual approval failed despite passing component-list and behavioral checks. Repair receiving geometry, hardware clearance/access, and instruction diagrams, then recapture dependent pages before expanding content. Parent views need receiving-frame context; the full default-workshop review remains open.
4. **Support longer sessions.** Add versioned local save/resume for inventory, assembly ownership, loose placements, station occupants, manual positions, and undo history. Validate loading before replacing live state; test a save with several unfinished builds and another with a mounted child.
5. **Play the combined scenario.** Follow only the in-game instructions, switch branches midway, move unfinished builds, undo a mounting action, quit/reload, and finish all three installations. Check that collection and instructions occupy the player's attention while handling remains comfortable.

Proposed undo scope is the selected assembly's latest build action. An installed child's internal history is unavailable until its parent mounting/retention actions are undone in reverse order; explain this and offer navigation to the parent. Do not silently dismantle dependent work. Undo returns the same physical identities to available capacity or a clear output location, and detached children retain their internal progress. Station movement and world organisation remain outside build history.

Definition validation should reject unknown references, cyclic prerequisites/ownership, incompatible initial occupants, duplicate identities, and unreachable required slots. Behavioral checks should cover independent completion orders, wrong variants, blocked closure, two instances sharing one definition, identity conservation through nested install/undo, and save/load. Keep the existing rendered reach, targeting, and collision checks as desktop regressions.

### Manual and assembly visual review

The reusable [gundam-assembly-review skill](../../.agents/skills/gundam-assembly-review/SKILL.md)
applies this workflow automatically to future manual/module design and implementation.
The repository's `AGENTS.md` routes relevant work to it.

The current automated checks compare installed mesh vertices against each receiving slot's source geometry, and rotate mounted assemblies continuously between input and physics ticks. They catch incorrect baked fastener orientations and children drifting from their parent. They do not establish that the source assembly is mechanically sensible, that a manual diagram is legible, or that the chosen working view exposes the intended connection.

Apply the review in three increments (the actuator capture harness and first failed review are implemented):

1. **Capture reproducible review views.** Extend the existing desktop build runners with an opt-in capture mode using the real renderer. Advance through the normal placement path and pause at the beginning of each page, each valid placement preview, and the completed page. Record the manual page, required IDs/quantities, accepted slot, consumed identity, scene transforms, engine version and asset/code hashes beside the images. Include close-ups before and after each fastener, since the completed page can hide a washer under its screw. Use the source assembly as a separately labelled reference. Keep ordinary automated checks headless; a run with a dummy renderer must not claim a visual pass.
2. **Review the manual and workpiece together.** Produce a contact sheet per page with the actual HUD diagram/list, the player's working view, and at least two unobstructed inspection angles. Capture both opaque and service views for internal actuator steps. Review all 22 distinct manual pages in the default scenario, and both physical pads at both compatible heel positions. Record the result for every row below; every row must pass before that page is visually approved. If the source itself is wrong, record a source-model issue rather than treating agreement with it as approval.
3. **Keep reviewed baselines and replay changes.** Save a page-by-page pass/fail record with image paths, reviewer/date, findings and the verified hashes. Fix the data, source model or runtime behavior as appropriate, then recapture the affected page and any dependent pages. Retain an accepted baseline for comparison. Changes to shared stock geometry, attachment transforms, assembly parenting, or diagram framing require the affected pages to be reviewed again.

| Review | What to verify |
| --- | --- |
| Required parts | Only this step's new components and prepared assemblies appear in its list; quantities and variants match stock. Prior receiving parts are clearly described as already fitted. No reminders to collect future parts. Overview/readiness pages show progress rather than shopping lists. |
| Placement | Preview and installed geometry agree. Washer planes match bearing faces; screw shafts align with holes and heads face the accessible side. Check for gaps, inverted parts, intersections and disconnected components. |
| Instruction order | Required surfaces remain accessible; a seal, collar, retainer or internal fastener is not hidden by an earlier closure. Confirm the prose, highlighted diagram and actual available targets agree. |
| Diagram | The current components are distinguishable at the game's normal HUD size. Labels match shelves/drawers. Camera and exploded offsets expose the connection without suggesting an incorrect insertion direction. Author per-step camera/offset data when a shared view fails. |
| Rotation and ownership | Capture a short continuous R-drag around multiple axes at preparation stations and at the foot, then reset. Include both mounted pads, the mounted actuator, parent fasteners, loose nearby pieces and carried/undo transitions. Child meshes and collision shapes must retain their attachment poses throughout, including between physics ticks. |
| Completion and recovery | The completed page matches its illustration. Undo and reinstall reproduce the same fit and inventory counts. Returning from the parent manual does not imply another copy of a completed component. |

The actuator first pass now covers all 14 child pages, 90 additions, and continuous preparation/mounted rotation. Supplementary parent captures cover 18 additions but omit some receiver context, so they are not an accepted baseline. Resolve the recorded actuator findings, complete parent framing, and review both mounted pads and remaining default pages before marking the workshop visually verified. Existing pad screenshots remain historical; they are not approval of the current actuator/manual changes.

### Expansion after this milestone

Expand by playable branches: rear/forefoot frames and joints; remaining actuator variants; all carriers and pads; electrical assembly and harnesses; then armor closure. Reuse definitions where variants really share construction. Each increment needs reachable completion and instructions before adding the next branch. Keep all 745 source identities accounted for. The standalone-foot proposal remains 737 installed items with eight shin-interface fasteners reserved for the leg; confirm that scenario boundary before full-foot completion is authored.

The success criterion is that adding another assembly primarily means authoring its slots, dependencies, handling data, and manual views, without new assembly-specific placement code. Exceptions exposed by wiring or captive hardware should extend explicit data/rules deliberately rather than accumulate hidden special cases in input handlers.

## Rules that make the first build reliable

Use a shared assembly description for placement, manual progress, error explanations, and completion. Separate scripts with different notions of the correct next piece would create confusing contradictions.

That description needs part type/variant, physical instance identity, parent assembly, attachment slot, local snap transform, accessible connection point, prerequisite slots or subassembly states, manual step, and completion grouping. Carry category and collision representation belong to the item definitions. An installed piece must have exactly one owner.

Desktop remains the immediate playable and testable target, with AR support deferred. As the state becomes reusable, expose gameplay actions independently of keyboard/mouse handlers, camera-relative carry poses, and HUD rendering. Let desktop input supply targeting and carry intent to shared collection, capacity, placement, and undo rules; future AR input can supply those intents through a different adapter. Do not require tracked hands or headset testing to advance this milestone.

Evaluate carrying by comfort and how quickly it lets players resume collecting and following the manual. Abstract pockets, batch collection, generous targeting, and assisted placement remain appropriate. Precise physical pocket retrieval or sustained two-hand gestures are not requirements. Test larger assemblies for visibility and clearance before choosing their carry poses. Teleportation is accepted for future AR traversal beyond physical room space; its arrival-clearance and carried-item behavior remain future implementation work.

Geometry and physics have separate jobs. Retain the detailed visible meshes and use simpler primitive or convex collision shapes for carried parts. Mounted components should form a stable assembly instead of simulating every bolt as an independent connected rigid body. Preserve open working areas when choosing collision shapes: a single solid box around a hollow frame would obstruct valid connections. Godot's [collision-shape guidance](https://docs.godotengine.org/en/stable/tutorials/physics/collision_shapes_3d.html) recommends primitive shapes for dynamic objects and describes the limits of concave shapes.

Solid carrying remains a requirement. Moving a held mesh directly through shelves is not an acceptable substitute. At a valid connection, controlled snapping should complete the placement without requiring physical insertion of threads. Collision handling must distinguish the receiving assembly from unrelated obstacles, so snap assistance cannot be used to install through scenery.

Recommended undo semantics for the prototype: undo the latest placement in the selected build, retain the identities of returned pieces, and return them to available carrying capacity or a designated clear output spot. Undoing a child build already installed into a parent must first restore the child's independence; it cannot invalidate the parent invisibly. These are implementation proposals for the agreed simple history, not a new arbitrary-disassembly system.

Keep station rotation, world organisation, and walking outside build history. A completed subassembly retains its child pieces when transferred into a parent; no duplicate module inventory is created. Manual progress follows the physical assembly, not whichever station happens to hold it.

## What to learn from the playable

The first success condition is that a new player can follow the HUD instructions and finish the pad operation using only in-game feedback, with predictable placement and no lost or duplicated parts. They can undo and continue, leave a build unfinished, and return to it.

Observe time spent finding/carrying, preparing, consulting instructions, and placing parts; ambiguous target selections; repeated error attempts; unwanted collisions; and the player's desire to continue to the next assembly. These are diagnostic measures, not a timer or score imposed on the player.

Use the second pad to assess whether organisation and stocking supplies improve the experience. Use the later actuator and full-foot passes to assess repetition, subassembly navigation, larger carrying, and longer-term progress. A pleasant 13-piece task alone does not establish that all 745 objects are enjoyable to assemble.

The initial implementation deliverable is stages 1–3: a runnable desktop test containing the real foot context and one complete heel-pad build/install loop. This is now implemented in the [heel-pad demo](../../game/heel-pad-demo/README.md). The first human play session found the fetch-and-attach loop satisfying and approved the generous targeting. Its carry, HUD, rotation, crouch, and display feedback is recorded in the [game design](../../GAME_DESIGN.md#first-playtest-feedback-and-interaction-revision). The shared construction model, second pad, and complete pitch actuator branch are now implemented. Save/resume is the next proposed increment. The two-pad scene remains the organisation and interruption regression.
