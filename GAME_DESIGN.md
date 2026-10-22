# Mecha workshop — game design

Last updated: 2026-10-22

This records the agreed game design from the workshop-loop discussion. Robot geometry, engineering detail, and part inventories remain in [ROBOT_DESIGN.md](ROBOT_DESIGN.md). Recommendations for reaching a playable foot build are recorded separately in the [foot prototype plan](design/game/foot-prototype-plan.md).

**Status:** the core experience and interaction rules below are agreed. The [playable project](game/workshop/README.md) now includes the original foot branches and a structural left-leg milestone in an expanded hangar. Its controls, reach values, collision approximations and layout are prototype choices for playtesting. Historical increments below record their own scope; the latest supported-leg section describes the default scenario.

## Experience and purpose

A first-person organisation and instruction-following game about constructing an 18 m piloted mecha in a large workshop/hangar. The user's reference is advanced 3D LEGO: organise a dishevelled workspace, consult illustrated instructions, build intricate components, and combine them into larger assemblies.

The intended pleasure comes from finding the right pieces, preparing supplies, following construction dependencies, and seeing a machine take shape. Identification and placement are forgiving. Individual screws and washers retain their detail, but require no manual threading, torque operation, or precision alignment.

Desktop is a fully playable and testable target. Build the interaction systems so AR support can be added later without replacing the construction rules. Life-size machinery remains central to the vision. Collecting the pieces and following the manual are the main activities; carrying should use whichever handling feels most comfortable and should not become a dexterity challenge. An AR prototype is not a prerequisite for further desktop development.

Design the baseline experience without power-ups. They may be considered later. Carrying strength and convenient assembly stations are part of the baseline fiction; an exoskeleton or gravity-gun-like explanation is sufficient, and the lore is undecided.

## Core loop

1. Open the relevant manual or manual section and inspect the next construction step.
2. Find the required components in storage or among freely arranged larger pieces.
3. Stock the small-part pockets and choose what to carry; optionally prepare supplies beside the build in advance.
4. Carry the pieces to the appropriate assembly station.
5. Select a held piece and aim generously around its intended connection area.
6. A ghost previews a valid attachment when the piece is compatible, prerequisites are met, and the connection is within reach. Click once to attach it.
7. Continue until a significant assembly is complete; completion produces a sound and glow.
8. Use that completed assembly as a component in a larger manual. Eventually move major completed sections to the mecha bay and attach them to the robot.

Organisation can happen before or during construction. Players may switch freely between unfinished assemblies and return later.

## Workshop and scale

The full-game vision has three main areas:

| Area | Purpose |
| --- | --- |
| Organisation and storage | Part-ID/image drawers for small hardware; shelves and space to arrange larger pieces |
| Assembly/workbench area | Prepare supplies and build components at stations appropriate to their size |
| Mecha bay | Assemble major body sections into the standing robot; elevators on either side provide access to high connections; eventual launch destination |

The foot is approximately 3 m long and 1.3 m wide. Conventional furniture-sized workbenches alone cannot accommodate all construction. A roughly 5 × 5 m staging area was discussed as a possibility, not a fixed specification.

Small preparation work uses freely rotatable suspension stations. The 2026-10-22 playtest found the whole-foot version floaty and immersion-breaking. The default workshop now uses a mechanically supported foot fixture, indexed working positions, an access platform and a rail carrier, described in [Supported foot milestone](#supported-foot-milestone). Broader equipment and construction stages remain proposals in [Construction scales and supported workflow](#construction-scales-and-supported-workflow).

Objects remain at their designed scale. Large assemblies travel through an open hangar; narrow-doorway maneuvering is not an intended challenge. The earlier exclusion of hoists is reopened by the 2026-10-22 playtest: the user wants to explore conveyors, scaffolding, elevators, and hoists for larger construction. Transporting heavy assemblies should occupy a modest part of the experience; the amount of direct equipment control remains open.

Teleportation is the accepted approach to travel beyond the available physical space when AR support is added. It does not require shrinking the machinery. Exact destinations, transition presentation, and handling of carried assemblies during teleportation remain to be designed; travel should preserve inventory and build state and provide clear arrival space. Reach to the actual connection still governs attachment after arrival.

## Organisation and identification

- Small hardware belongs in labelled bins.
- Larger pieces are available as loose physical objects. Players choose how to organise them on shelves and around the workshop.
- Looking at a component shows its ID and name in a compact prompt beside its projected world position. Reachable, usable objects receive a thin outline. Recognition by silhouette or distinguishing nearly identical fasteners by eye is not required.
- Players can bring supplies over in advance and arrange them beside the current build, including in nearby trays or storage.
- Freely organising larger pieces has a practical payoff: knowing where items are and reducing repeated storage trips.
- There is no agreed mandatory layout, sorting score, or automatic re-scattering system.

## Pockets, hands, and carrying

The action bar contains ten persistent small-part pockets, hotkeyed 1–0. Each pocket holds one item type and up to 20 copies. There is no shared item-count limit. Hand-sized components and whole assemblies are carried separately from the bar.

The in-game HUD uses subtle translucent backgrounds, plain engineering typography
and keyboard keycaps. Pause, help and manual browser windows are opaque, with the
workshop visible around them and no full-screen backdrop.
Square pocket cards prioritize part images while retaining readable IDs, functional
variants and quantities. A separate hands status appears only while carrying a
component or assembly; it does not repeat the selected pocket or trigger a pickup popup.
Valid attachment ghosts provide the placement
cue without a repeated click instruction; unavailable actions keep brief explanations.
Rotation controls stay in the pause menu without a persistent tutorial banner.
Hand and two-hand components are held at screen center, accounting for the object's
actual bounds. Size-aware distance and collision constraints still apply.

With no part selected, unfinished assemblies have one whole-object pickup prompt.
Selecting a part gives nearby connections priority over their assembly's pickup
target; the pickup key still acts on the containing assembly. Wrong-part feedback
remains available, and ordinary reach and obstruction checks apply to both actions.

Size and available carrying slots provide the limitation. Realistic mass does not prevent carrying a huge component. Large held objects remain solid and should collide with the environment; turning them into ghosts that pass through everything was rejected.

The requested physical feel is comparable to basic Source-engine object handling. This describes the feel, not a requirement to use the Source engine. Held-object distance, rotation controls, visibility, and collision response still need practical tuning.

Comfort takes priority over literal hand simulation. Pockets are an abstract small-item store. E fills or tops up a matching stack from a labelled drawer; otherwise it uses an empty pocket, or replaces the selected pocket when all ten are occupied. B clears the selected pocket from anywhere and returns its contents to storage. Physical pocket gestures, retrieving every fastener into a tracked hand, and precise two-hand grips are not required. Hand capacity describes what the player can carry; it need not impose continuous grip gestures. Keep forgiving previews and assisted placement on desktop and in eventual AR controls. Oversized assemblies may use assisted suspension with a comfortable view and clearance while retaining their scale and solidity; the exact handling remains a playtest choice.

The player can set objects down and prepare loads. A completed subassembly becomes one carryable assembly while retaining its constituent pieces and their build state.

## Placement, targeting, and reach

The selected interaction is **choosing the connection area with generous targeting**. Looking near a relevant mounting point should be enough to select it. The player does not have to align a bolt axis or click an exact pixel-sized hole.

When several attachment points accept the same piece, aiming selects the intended area. The game does not automatically fill arbitrary compatible locations across the whole assembly. A ghost makes the selected destination clear before the click.

A valid click places the piece in its authored position and orientation. No separate tightening effort is required. Bolts and washers remain individual pieces under the retained detail level.

Attachment is limited by the character's reach to the actual connection point. This supports the purpose of platforms and elevators. Carrying a large object must not extend attachment reach to a distant connection merely because the object itself reaches it.

Reach distance, targeting tolerance, and target-switching behavior are tuning variables. Predictable selection of adjacent mounting points is important. Hidden or blocked connections must not become accessible merely because the player's aim is near them.

## Manuals and construction dependencies

- Manuals are LEGO-like illustrated instructions, spanning small components through major body sections.
- Each significant subassembly has a manual or section; a parent manual uses completed subassemblies as its components.
- The manual is a HUD item that can be opened and closed freely. It does not need to be carried as a physical book.
- Manuals remember progress for each physical unfinished assembly and mark installed components automatically. Clickable breadcrumbs show the parent/build path. N opens a larger, paused browser with expandable build folders and selectable steps; closing it returns to the chosen page in the compact manual.
- Players can leave one build unfinished, work on another, and resume without losing their place.
- Valid construction dependencies govern placement. The manual offers an understandable sequence, but independent operations may be performed in another valid order.
- A valid connection remains available regardless of which manual or page is open. Looking at another build does not require changing manuals before placing a compatible piece there.
- Unfinished assemblies keep their chosen recipes. The manual offers matching build/page suggestions from the held piece or the assembly being worked on, becoming more specific as construction identifies that assembly. Players explicitly flick through suggestions; discovery does not silently change the open page or reserve compatible stock.
- Example: either of two independent brackets can be fitted first. A cover that would prevent required internal construction should wait until its prerequisites are complete.

The manual is a guide, and the game also supplies explicit placement assistance. The experience does not rely on concealing compatibility information or forcing players to solve unexplained failures.

## Errors and assistance

Errors should be as descriptive as possible. The user's example for an unsupported component is:

> Compatible next components are: FA-203.

That ID is an illustration of the message format, not an additional assembly dependency. The engineering inventory defines actual part identities.

Feedback should distinguish incompatible parts, missing prerequisites, and out-of-reach connections. Where appropriate, identify the compatible next components and the unmet prerequisite. A missing ghost alone is insufficient feedback.

Recommended presentation refinement: show names alongside IDs and scope suggestions to the targeted assembly/connection. Make clear when a completed subassembly is needed. A long unfiltered list of every available part in the entire foot would be difficult to use.

## Undo and completion

Undo applies to build actions through a simple history. It does not rewind general walking, carrying, or storage organisation. Arbitrary mechanical disassembly was proposed earlier; the user's selected approach is simple build-history undo.

The exact history scope across multiple builds, return location for undone pieces, and behavior when a subassembly has already been installed into a parent still need implementation rules. Undo must preserve part counts and dependency validity.

Completing a significant assembly produces a sound and glow. Functional demonstrations, actuator motion tests, extra reward systems, and elaborate completion cinematics are not required for this baseline.

## Retained robot detail

The existing [FA-01 foot model](models/foot-fa01/README.md) has 745 separate inventory objects:

- 229 other pieces/manufactured modules.
- 258 bolts/screws.
- 258 matching fastener washers.

The three actuator assemblies each contain 27 other pieces/modules, 32 screws, and 32 washers: 91 objects each. Prebuilt-actuator and hardware-bundling alternatives were discussed, but the user chose to retain the existing detail for now. No reduction to the foot inventory is approved.

Separate source meshes, physical inventory items, and completed carryable subassemblies are related concepts with different purposes. Combining completed pieces into a carryable subassembly must not add another copy of those pieces to the inventory.

The robot is plausible fictional machinery. The baseline game does not require physically simulating the mecha's structural loads, every screw thread, or functioning joint mechanics.

## Questions for hands-on evaluation

The current rules form a coherent loop. The remaining major uncertainties concern feel:

- Does preparing and organising supplies make construction noticeably more pleasant?
- Do the ten persistent pockets and shelf carrying make collecting comfortable without making restocking dominate the session?
- Does generous targeting reliably select the intended connection, including near adjacent fasteners?
- Are small components, names, and manual illustrations readable at a comfortable first-person distance?
- Do solid held objects obstruct the camera or snag often enough to make transport frustrating?
- Can station rotation expose all relevant connections without becoming work in its own right?
- Do repeated small placements remain satisfying between meaningful completion moments?

The full foot retains all 516 fastener pieces. Each small-part pocket can hold 20 copies independently; test the resulting drawer visits and stack replacement against the longer assembly sequence.

## Open details and record maintenance

Godot is selected for the playable workshop. Its [README](game/workshop/README.md) records implemented control bindings, carry classifications, reach, undo behavior and current limits. These are prototype defaults rather than locked full-game tuning. The supported-foot and expanded leg workshops have separate local saves. Full-game progression and replenishment rules remain open.

Update this file when gameplay decisions are accepted. Keep proposals visibly separate from agreed rules. Update the robot specifications only when the robot itself changes. Import or optimization work must preserve the source assets and inventory unless a later decision explicitly changes them.

## First playtest feedback and interaction revision

The user found fetching the correct parts and clicking them into place satisfying. Generous connection targeting worked well and remains unchanged. The two-handed pad felt floppy, and the original HUD and controls presentation obscured too much of the workshop.

The feedback pass implements:

- A firm, collision-aware grip for two-handed carrying, with ordinary physics restored when set down.
- Removal of the workshop-title header and permanent general-controls strip.
- A compact action bar showing part images, IDs, quantities and selection. The later pocket rebuild below establishes ten persistent slots and a separate carrying indicator.
- A grouped Escape controls menu with a prominent resume action and confirmed restart.
- Double-tap R to reset the inspected station, alongside hold-R rotation. The later HUD revision removes the persistent tutorial hint.
- Hold Ctrl to crouch for better inspection; standing requires overhead clearance.
- Non-exclusive fullscreen by default so the demo fills the display.

These changes preserve the source inventory, construction dependencies, one-click attachment, and generous hitboxes. Automated verification covers functionality; the revised carrying and presentation still need the user's feel assessment.

Subsequent feedback: the user is fairly happy with the heel-pad demo and wants to explore more complex foot construction, interacting manuals, and a generic model of how parts fit together. The next proposed milestone is detailed in the [prototype plan](design/game/foot-prototype-plan.md#recommended-next-milestone-multiple-builds-and-nested-manuals).

**Next direction, proposed after this feedback pass:** replace heel-pad-specific state and station assumptions with reusable assembly definitions and interchangeable work volumes. An assembly instance should own its progress, child identities, and manual position. A station should supply suspension, rotation, and size limits; it should not own the recipe. Attachment poses, compatible types/variants, prerequisites, and illustrated manual steps should read from shared authored data.

Prove that separation with another differently structured subassembly on the same station before expanding to the full foot. A second identical pad helps assess organisation and independent progress, but by itself does not prove that the construction system supports other kinds of machinery. This generic-system work has not been implemented in the feedback pass.

The desktop-first, future-AR direction also requires separating gameplay actions from input and presentation. Collection, selection, carrying, placement, and undo should operate on shared assembly/inventory state. Desktop camera targeting and carry poses are input-specific choices; later AR targeting and tracked poses should invoke the same rules. Keep physical identities, capacity, prerequisites, connection reach, and completion independent of keyboard bindings, HUD widgets, and headset APIs. This is an architectural direction for the next implementation pass, not a claim that the current demo already provides those boundaries.

## Two-pad workshop implementation

Increments 1 and 2 introduced the two-pad regression scene, which contains both heel pads and 24 hardware pieces, with shared hardware stock and two interchangeable preparation stations. Either prepared pad fits either compatible heel position. The parent foot owns seating and fastening; each child retains its four sleeves and physical identity.

The shared assembly model reads authored types, slots, prerequisites, milestones, and manual references. The parent and child manuals retain independent pages and show model-based illustrations. Looking at another build does not replace the selected manual. Undo acts on the selected manual; installed children must be detached through parent history before their internal preparation can be undone. Mount undo uses a free preparation station and explains when none is available.

The original single-pad loop remains a regression scenario. The construction model is independent of desktop input. The actuator extension is described below; local save/load is implemented as described below, while AR support remains a later increment. See the [workshop README](game/workshop/README.md) for controls and verification.


## Pitch actuator milestone

Increment 3 adds the complete pitch actuator and its installation to the default workshop: 91 child pieces and 18 parent mounting pieces, alongside the 26 pad pieces. All 135 active identities come from the preserved 745-object source inventory; scoped interface repairs update the playable pitch geometry. Armor is staged aside; the remaining source items stay accounted for as context. External wiring and actuator motion remain future branches.

FA-513 starts on the floor beside preparation C; the player picks up the motor and suspends it at the empty station. The exposed drive is built first, supported by the preparation fixture. FA-510 is added after the rod, on page 7. Rear-access motor screws and exterior radial retainer screws secure the drive before the caps close it. Fourteen authored child pages cover drive modules, shaft/rod retention, sensors, guide/seals, cap closure, both eyes, and the handoff. The parent manual covers base/ring clevises, their washers and bolts, seating the completed child, and both eye-pin keeper stacks. Prerequisites require internal work before closure and both secured clevises before mounting. Each physical build retains its manual page and progress.

The compact action bar now represents ten persistent small-part pockets independently of the selected manual. Each stack holds up to 20 copies. Shelf components and whole assemblies use the assisted solid grip separately from those pockets. The first six pages need no barrel or transparency. The fitted barrel stays opaque: subsequent motor fastening uses the open rear, and retainer fastening uses exterior lands. Once the caps are secured, the assembly hides explicitly enclosed meshes, including in its placement preview; undo restores those internals without making the barrel translucent. Authored diagram geometry is cached across progress changes and normal play is capped at 60 FPS. Generous slot previews remain, with no precision threading or torque minigame.

Headless verification covers the actuator's complete build/install/undo path through the desktop adapter, source transforms and physics. Rendered review inspects changed manual stages and interfaces separately. The original single- and two-pad regressions remain available. Human assessment of cabinet layout, manual readability and the longer collecting loop is still needed. The later save/resume increment preserves progress in the default supported-foot workshop. The later scale playtest below motivates evaluating supported foot handling before further content expansion.


## Pockets and wall storage rebuild

The action bar is the source of truth for collected small items. E loads up to 20 available copies into an existing matching pocket or an empty pocket, then selects it. If all ten pockets are occupied by other types, E replaces the selected stack and returns those identities to their drawer. An empty drawer does not clear or change another pocket. B clears the selected stack anywhere. Undo returns small pieces to a suitable pocket or their drawer without replacing existing stock.

Cabinets sit against the wall with two low rows. Every drawer has its source part ID, cached source-mesh image, optional name, and available quantity. Small stock never exists as loose scene meshes or physics bodies. Hand-sized components remain on shelves and can be picked up with E and set down with Q. Installed small parts and valid attachment previews retain source geometry.

Manual instructions and parts lists use the same IDs as storage. Names clarify those IDs, including different base/rod variants. Page Up/Down scroll longer lists. Manual navigation does not change pocket contents, ordering or selection. Static part images replace live hotbar/catalogue viewports, and component installation adds/removes only the changed visual. Headless checks cover behavior and reduced preview workload; frame-rate and visual comfort need a human playtest.

The manual audit removes future-step reminders and gives every construction page a distinct list of only its required new components, including prepared subassemblies at their mounting steps. Summary pages show assembly progress. Receiving parts already fitted in earlier steps are described as such. FA-511 and FA-512 are required only on the housing-closure page.

The rotation/orientation repair keeps mounted and suspended builds fixed relative to their parent during continuous R-drag. Installed hardware uses the receiving slot's oriented source geometry, matching its preview while retaining the consumed physical identity. Next, perform the [manual and assembly visual review](design/game/foot-prototype-plan.md#manual-and-assembly-visual-review) before expanding content: per-step rendered comparisons, fastener close-ups, multiple angles, rotation recordings and a reviewed baseline. Headless geometry checks are necessary but do not replace that review.

## Construction scales and supported workflow

### Playtest feedback on 2026-10-22

The user finds stocking small hardware into the action bar, preparing hand-sized components, and rotating small workpieces satisfying. Two-handed heel-pad carrying and attachment also feel good. Manipulating the whole foot to install the actuator feels floaty and breaks immersion. Carrying objects more than a couple of metres wide feels clunky, raising concerns about larger skeleton and torso builds.

The user proposes larger preparation areas with scaffolding, conveyors to move completed pieces toward the robot, and renewed consideration of elevators and hoists for final assembly. This revises the earlier preference against hoists. The full workflow below remains a design proposal; its first supported-foot increment is implemented in [Supported foot milestone](#supported-foot-milestone).

### Dimensions and handling implications

The [foot dimensions](design/legs/foot-and-ankle/dimensions.md), [actuator specification](design/legs/foot-and-ankle/actuators.md), and [hardware inventory](design/legs/foot-and-ankle/parts.md) provide detailed working sizes. The [whole-robot proportions](design/proportions.md) distinguish confirmed proportions from selected working envelopes. Lengths between joint centers are not removable-part lengths. Dimensions describe geometry; masses are not specified.

| Foot item | Documented size | Proposed handling |
| --- | --- | --- |
| Fasteners and washers | M12–M36 bolts, 30–140 mm under-head lengths; washer outside diameters 24–66 mm | Existing small-part pockets |
| Compression sleeve FA-305 | 42 mm outside diameter × 76 mm long | Existing small-part pockets |
| Frame nut plates FA-107 | 160, 180 or 280 × 80 × 54 mm | Small stock or shelf component according to comfort and variant; do not infer pocket eligibility from the name |
| Ankle bushings and thrust washers | Bushings up to 150 mm outside diameter × 140 mm long; thrust washers up to 170 mm outside diameter | Hand-scale preparation candidates |
| Pitch motor / gearbox FA-513 / FA-514 | Approximately 126 / 122 mm across the largest flange and 58 / 62 mm axial extent in the current source geometry | Hand-sized bench work; nominal source envelopes, not newly measured mesh bounds |
| Heel pad FA-302 | 600 × 660 × 140 mm | Two-handed carrying, already positively playtested |
| Forefoot / midfoot pads FA-304 / FA-303 | 600 × 860 × 140 / 600 × 1150 × 140 mm | Two-handed carrying candidates; verify the larger pads separately |
| Pitch actuator | 140 mm barrel diameter, 460 mm barrel length; 640–860 mm eye-center distance | Bench assembly and supported handoff; potentially comfortable to carry because it is slender. Eye spacing excludes the outer eye tips |
| Roll / forefoot actuator | 110 mm barrel diameter; 480–640 / 470–640 mm eye-center distance | Bench assembly and handoff candidates; detailed loose-part handling still needs classification |
| Rear / forefoot rails | 1830 / 840 mm long, 180 × 240 mm box section before local features | Long-part rack and frame fixture; test the slender rear rail before assigning it to hand carrying |
| Forefoot axle | 120 mm journal diameter; 1185 mm extraction length including head | Long-part staging; keep a 1300 mm outward extraction corridor |
| Ankle ring FA-200 | Main outline 880 × 720 × 120 mm; bearing bosses and mounting ears extend beyond it | Dedicated supported ankle-core fixture rather than treating the complete core as a small hand prop |
| Rear / forefoot sole carrier | 1220 × 1860 × 60 / 1220 × 880 × 60 mm | Supported staging and assisted placement, especially for the broad rear plate |
| Complete foot and ankle | 3000 long × 1300 wide; main shell top 700 mm, guard tops 1600 mm above sole datum | Floor assembly bay; supported repositioning and transport |

The motor/gearbox estimates come from the primitive extents in the current [pitch interface generator](models/foot-fa01/src/pitch_interfaces.py); flanges and journals are included. Other foot rows use the linked dimensional specifications. The actuator's body can be bench-sized even when the frame receiving it needs a floor bay.

| Larger assembly | Documented scale, metres | Basis and handling implication |
| --- | --- | --- |
| Shin / calf | 4.1 knee-to-ankle joint span; up to 1.4 wide × 1.9 deep armor | Confirmed span, working cross-section; long supported fixture |
| Thigh | 4.1 hip-to-knee joint span; up to 1.5 × 1.5 armor cross-section | Confirmed span, working cross-section; long supported fixture |
| Upper arm / forearm | 3.0 shoulder-to-elbow / 2.6 elbow-to-wrist span; up to 0.9 × 1.0 / 1.1 × 1.1 armor cross-section | Confirmed spans, working cross-sections; limb fixtures and supported transfers |
| Robot hand | 1.8 wrist-to-middle-fingertip; palm 0.9 wide × 0.45 thick excluding thumb | Confirmed length, working palm envelope; the whole robot hand needs a fixture even if its individual parts can be prepared on benches |
| Pelvis / waist | 3.0 wide × 1.8 deep / 2.2 wide × 1.6 deep | Pelvis width confirmed, other extents working; frame fixture and access platforms |
| Chest | 4.0 wide × 2.4 deep | Confirmed envelope dimensions; walk-around torso bay. Individual spine, cockpit and frame-member dimensions remain open |
| Backpack | 2.4 wide × 2.8 high; up to 1.0 rear projection | Width/height working, maximum projection confirmed; assembly stand and supported installation |
| Head | 2.0 high × 2.0 wide × 1.8 deep, excluding crest | Confirmed envelope; elevated construction access. Working crest width is 2.6 |
| Final robot interfaces | Hip centers 9.2 high; shoulder centers 14.4; head mounting plane 15.4 | Confirmed heights; scaffold/lift access and supported alignment |

The foot is the only component with a detailed inventory and size packet. Knee cylinders, thrusters, cockpit/core modules, finger segments, and other non-foot individual parts still need sizing. Do not assign their loose parts to pocket, hand, or equipment categories solely from their names.

### Proposed construction stages

These stages describe work at increasing scales. Small preparation branches remain available throughout larger builds; the player does not permanently graduate away from bolts and bench work.

| Stage | Player activity | Work support and movement | Completion boundary |
| --- | --- | --- | --- |
| 1. Stock and prepare small parts | Collect hardware into pockets; assemble eye bearings, drive modules, sensors or control-box contents where dimensions permit | Existing storage and small rotatable preparation fixtures | Prepared small components retain their constituent identities |
| 2. Prepare carryable subassemblies | Fit pad sleeves; assemble slender actuators on a bench; prepare other modules once sized | Bench clamps/fixtures; ordinary one- or two-handed carrying where comfortable | Prepared child, ready for its receiving parent |
| 3. Build supported components | Assemble the foot frame, joints, drives, sole, services and armor; later construct robot hands and other bulky modules | Open frame fixture, adjustable work height and access platforms; visibly supported, controlled repositioning | Secured component, with future interface hardware and access preserved |
| 4. Integrate body sections | Join foot/shin/knee/thigh into a leg; hand/forearm/elbow/upper arm into an arm; build pelvis/waist/torso frame | Long fixtures, transfer pallets and assisted hoist alignment | Body section ready for final attachment; closing armor waits for covered work |
| 5. Assemble the robot in its bay | Seat hip and shoulder balls, fit retaining rings, connect services, complete head construction and remaining closures | Robot support gantry, lifting equipment, platforms/elevators, front/side/rear access | Seated, secured and connected sections; equipment releases only after retention is complete |

Hand-carry suitability depends on shape, length, camera clearance and comfortable control, not just width or fictional mass. A slender actuator can stay manageable when a similarly long broad carrier plate does not. A long arm beam can require support despite being less than a metre wide. Assign handling per compatible type and assembly state, with gradual growth from handwork into fixture-supported work.

### Proposed foot construction sequence

The [reference assembly sequence](design/legs/foot-and-ankle/assembly-and-review.md) remains the mechanical baseline. Use its actual access dependencies, rather than turning these workshop stages into a rigid global order.

1. **Prepare supplies in parallel.** Sleeve the six pads and build the three actuators on small fixtures. Build the moving ankle core on its own supported fixture. A pad's parent mounting washers and bolts remain foot-installation work.
2. **Build the rear frame on located supports.** Retain its six nut plates before installing crossmember bolts. Seat and bolt the cradle; install the pitch stops while access is open. The fixture supports the work without covering the nut-plate pockets or later sole connections.
3. **Install the ankle core.** Add pitch bushings and thrust washers, seat the prepared core, then insert side pins and retainers. Keep the ring/adapter ownership and pitch/roll axes intact.
4. **Build and join the forefoot.** Assemble its four nut plates and frame on a separate fixture, then support it at the hinge for axle insertion. Keep the 1300 mm outward corridor clear of scaffold posts and storage; add forefoot stops.
5. **Mount the three prepared drives.** Fit and secure the clevises, seat each actuator, then install pins and keepers. The current pitch repair provides outboard access to its pin heads and keeper screws. Expose the appropriate side using player access or a supported fixture pose, rather than freely floating the whole foot.
6. **Fit carriers, then prepared pads.** Expose the underside using the fixture. Secure each carrier to the frame before covering its fasteners with the pads. Seat the pads and fit their parent-owned washers and bolts. A complete carrier-plus-pads cassette would conceal the carrier fasteners and is not the default installation sequence.
7. **Install services before closure.** Mount the control box/controller, route all four external harnesses, fit clips and close the box. Preserve movement loops, connector access and mounting-tool corridors.
8. **Complete the appropriate handoff.** A standalone foot leaves the keyed shin flange accessible and reserves its four bolts/four washers for leg assembly. When building the leg, seat and secure the shin and connect the disconnect before any closure that blocks access. Fit the five removable armor shells after their covered work is complete, keeping each shell on its designed owner.

### Equipment and access proposal

Start with a mechanically supported foot fixture: visible frame saddles/clamps, height adjustment, and deliberate supported tilt or indexed working poses. Walking around the workpiece and using a platform should expose ordinary connections. Repositioning controls should communicate a machine moving a supported load; exact speed, poses and controls need playtesting. The fixture must avoid pad/carrier bolts, side-pin corridors and wiring access, including when an incomplete build is moved.

A flat bench or conveyor under the sole would block upward-facing carrier and pad bolts. An open-center carrier or a fixture with supported turnover is needed. A roughly 6 × 6 m clear foot bay is an initial blockout candidate, not a validated layout: allow the 3 × 1.3 m foot, access on both sides, the 1.3 m axle corridor, fixture motion, stairs/platforms and local supplies. Measure the resulting clearances before selecting its final size.

For transport, prefer a conveyor carrying a located pallet or fixture, rather than a finished foot balancing on its pads or loose parts moving past the player. A rail trolley could serve the same role if it integrates better with the bay. Transport should be visible and purposeful, while avoiding repetitive delivery trips or precision driving. The default proposal is to choose a destination or work pose, let the equipment perform a constrained move, then make the connections by hand; direct assisted controls remain an alternative to evaluate.

Hoists and lifts have different roles: hoists support and position large pieces; platforms/elevators bring the player and supplies within reach of the real connection. Neither should grant remote fastening. Keep a load supported until its retainers are fitted. The final robot needs a support gantry while incomplete, so the workflow does not depend on balancing unfinished legs or suspending an unsecured section from one preliminary connection.

Preserve the specified interfaces: integral leg/arm balls seat in torso sockets and are captured by split retaining rings. The head's confirmed sequence starts on the torso's neck spoke, then baseplate, sides, top, sensors, faceplate, mask and crest; do not silently replace it with a prebuilt-head hoist. Torso work also requires rear access for power-core insertion/extraction and backpack hinges, and cockpit installation before front armor. Final bay equipment must serve the rear as well as the front.

### Next prototype and review plan

Evaluate a supported foot bay using the existing pad and pitch-actuator content before expanding the foot inventory. Retain the satisfying pockets, small preparation and pad-carry loop. Compare a fixed accessible pose with a deliberately repositioned fixture; test conveyance only after installation access feels good. The local save/resume increment below supports longer play sessions before further full-foot expansion.

- Map every current installation slot to a usable work pose and standing/platform position. Verify actual connection reach, view/approach obstruction, upward sole access and outboard pitch hardware. A nearby fixture control must not make a distant connection attachable.
- Verify support through frame growth, fixture movement, mounted children, undo and transfer. Fixture/pallet/scaffold are workshop equipment, not additional copies of robot inventory. Progress and manual position follow the physical build, independently of station or support.
- Distinguish **prepared**, **positioned by equipment**, **seated**, and **secured**. Positioning alone must not fill retention slots, award completion or permit premature release. Undo returns an unsecured module to suitable support without losing its physical identities or requiring it to be hand-carried.
- For future implemented changes, run the affected placement, ownership, mounted-transform, collision and undo checks. During fixture movement, children must remain attached between input and physics ticks. Loading/unloading must not duplicate bodies or allow equipment to bypass scenery.
- Human playtesting should assess whether the supported foot feels substantial, whether its connections are accessible without wrestling with the workpiece, and whether transport adds a satisfying scale transition without dominating construction. Rendered manual review remains separate and runs when explicitly requested.

Before authoring later stages, detail the next component's actual parts and interfaces. Resolve fixture contact points, supported handoff rules, useful equipment controls, working heights and bay clearances through this prototype. Neither a physical load calculation nor a full crane simulation is required by the proposed gameplay.

## Supported foot milestone

The playable project is now `game/workshop`, titled **Gundam Build Simulator**, with `play.command` and `edit.command` launchers. The foot is its first construction area. Single-pad and two-pad scenarios retain the earlier suspension setup for regression checks.

The default 135-piece workshop keeps its existing child builds and adds a visible foot carrier with end bearings and frame clamps. The foot starts upright, with its sole datum 0.75 m above the floor. Local bay controls select Upright, Sole left or Sole right; powered rotation is constrained to the foot's long axis. A ramp reaches the 0.55 m side platform. Small preparation stations keep R-drag and reset; the foot uses its own physical controls.

Once both pads and the pitch actuator are secured, the upright foot can transfer 6.2 m along floor rails to a handoff area and return. This is a supported transport prototype; final robot hoists and elevators remain future work. Equipment moves at a controlled rate, stops for path obstructions, and pauses with the game. The foot retains its existing assembly identity and mounted children throughout.

Placement and undo on the foot are available only while it is stationary in the work bay. The player must reach and see each real connection; equipment controls do not extend fastening reach. Construction on independent preparation stations remains available. The parent overview explains the bay controls and secured-transfer requirement without adding supplies to its component list.

Headless verification covers equipment behavior and the existing build rules. The user accepted the current workshop playtest after the refinements below on 2026-10-22. This records a human playtest, not a new rendered manual review.

### Supported-foot playtest refinements

Aiming at the bounds of an in-progress workpiece reveals a ready destination for the selected or carried compatible part in yellow within 6 m. The prompt asks the player to move closer or aim at the highlighted connection; the preview turns green when the connection is both in reach and directly aimed at. Discovery preserves prerequisites, equipment access and scenery occlusion, and never permits remote attachment. This applies to individual components, pad hardware and carried subassemblies.

Rotation and transfer controls are mounted on the platform's parallel outer railing, facing inward, so the player can operate them while standing on the deck. The walking lane remains open. Space jumps from the ground or platform; holding it does not repeat the jump, and carrying remains subject to solid collision.


## Accepted workshop playtest and local save/resume

After the pickup-only cached outlines, performance fixes and broad yellow workpiece discovery were delivered, the user accepted the current workshop playtest on 2026-10-22: “ok im happy with the current playtest!” The next authorized increment is saving, rather than more construction content or another presentation revision.

The default supported-foot workshop now has one versioned local slot with autosaves every 30 seconds of active play, on pause and on quit. Startup restores into the pause menu. Save writes immediately; Reload save confirms reverting unsaved changes; New workshop confirms replacing the current save. Failure leaves the running session open and makes quitting without saving an explicit choice.

The snapshot retains physical identities, pockets and ownership, build history, loose/carried object physics, station occupants/rotation, supported-foot current and destination motion, player pose/view and manual session state. Whole-payload validation precedes live replacement; atomic writes, a checksum, content fingerprint and last-good backup protect recovery. Unsupported/newer content is preserved until an explicit new-workshop decision. Legacy scenarios, captures and headless tests do not touch the normal profile.

The [save/resume plan and implementation contract](design/game/save-resume.md) records the scope and verification evidence. All 28 headless regression suites pass, including 430 save-specific checks of model/storage and the real workshop scene. This increment does not claim a new human playtest or rendered review. Migrations, cloud sync and multiple slots remain outside this increment.

## Supported left leg and expanded workshop

The next authorized milestone expands the workshop before integrating the new
construction route. The default scenario has a 39.6 × 47 m hangar with a 22 m
roof underside, the existing component stations and supported foot carrier, a
structural-leg fixture with access on both sides, a clear transfer aisle, and a
final bay containing a pelvis-supporting gantry. Overhead equipment moves large
pieces; three personnel lifts bring the player and supplies to actual fastening
positions. Future torso and second-leg work has reserved space.

The pelvis bridge and its two separately bolted socket housings start assembled
and clamped in the gantry. This is a selected prototype starting arrangement;
player construction of the pelvis is deferred. The robot's standing hip height
remains 9.2 m. The gantry holds the pelvis at 10.6 m to provide handling clearance.
The complete leg approaches with its sole at 0.5 m, passing its ball crown below
the socket skirt before rising into the socket.

The existing 135-piece foot/pad/pitch branch remains playable. Forty additional
active identities make the structural leg and hip retention, including nine
existing foot-source hardware/harness identities promoted from context. The
player joins the shin to the ankle flange and connects its main disconnect,
assembles the knee bearings/spacers/fork/axle/cap, then bolts on the thigh spar
with its integral hip ball. The hoist transfers the supported leg into the
pelvis; the player installs the two retaining-ring halves through handling
controls and fits their washers and bolts from the hip lift.

Seating, retention and releasing support are separate states. Both halves and
all retention hardware must be installed, and the gantry stabilizer engaged,
before releasing the hoist. Removal requires reacquiring the hoist first. The
same leg can return to its fixture and be dismantled, preserving physical part
identities, mounted child progress and manual state. Equipment pauses with the
game and stops for path obstructions.

The expanded scenario saves to `user://leg-workshop-save.json`, including
interrupted hoist/lift movement and partial retention. Launching with
`--foot-workshop` retains the previous layout and `user://workshop-save.json`.
Starting the expanded prototype does not overwrite that earlier profile.

This establishes structural readiness only. Detailed leg actuators, additional
services, armor, thrusters, waist/torso and the second leg remain deferred. The
[milestone record](design/game/leg-milestone.md) tracks verification; the
[interface specification](design/game/leg-prototype-interface.md) records the
selected geometry, parts and manuals. Headless behavior/geometry evidence does
not establish a human playtest or rendered approval for this expansion.
