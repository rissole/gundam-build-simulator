# Mecha workshop — game design

Last updated: 2026-10-21

This records the agreed game design from the workshop-loop discussion. Robot geometry, engineering detail, and part inventories remain in [ROBOT_DESIGN.md](ROBOT_DESIGN.md). Recommendations for reaching a playable foot build are recorded separately in the [foot prototype plan](design/game/foot-prototype-plan.md).

**Status:** the core experience and interaction rules below are agreed. The user authorized the Godot heel-pad demo, and the [first playable project](game/heel-pad-demo/README.md) implements that milestone. Its controls, reach values, collision approximations, and layout are initial implementation choices for playtesting; later stages in the linked plan remain proposed.

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

The current station concept is a cube-like work volume that suspends an unfinished assembly and permits free rotation. Access to the work should feel convenient and reliable. Operating the station is not intended to be a substantial challenge. Exact station dimensions, appearance, controls, and number of sizes remain open.

Objects remain at their designed scale. Large assemblies travel through an open hangar; narrow-doorway maneuvering is not an intended challenge. Hoists are excluded from the intended interaction. Transporting heavy assemblies should occupy a modest part of the experience.

Teleportation is the accepted approach to travel beyond the available physical space when AR support is added. It does not require shrinking the machinery. Exact destinations, transition presentation, and handling of carried assemblies during teleportation remain to be designed; travel should preserve inventory and build state and provide clear arrival space. Reach to the actual connection still governs attachment after arrival.

## Organisation and identification

- Small hardware belongs in labelled bins.
- Larger pieces are available as loose physical objects. Players choose how to organise them on shelves and around the workshop.
- Looking at a component shows its ID and name in an on-screen tooltip. Recognition by silhouette or distinguishing nearly identical fasteners by eye is not required.
- Players can bring supplies over in advance and arrange them beside the current build, including in nearby trays or storage.
- Freely organising larger pieces has a practical payoff: knowing where items are and reducing repeated storage trips.
- There is no agreed mandatory layout, sorting score, or automatic re-scattering system.

## Pockets, hands, and carrying

The action bar contains ten persistent small-part pockets, hotkeyed 1–0. Each pocket holds one item type and up to 20 copies. There is no shared item-count limit. Hand-sized components and whole assemblies are carried separately from the bar.

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
- Manuals remember progress for each physical unfinished assembly and mark installed components automatically.
- Players can leave one build unfinished, work on another, and resume without losing their place.
- Valid construction dependencies govern placement. The manual offers an understandable sequence, but independent operations may be performed in another valid order.
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

Godot is selected for the authorized heel-pad demo. Its [README](game/heel-pad-demo/README.md) records implemented control bindings, carry classifications, reach, undo behavior, and current limits. These are initial prototype defaults rather than locked full-game tuning. Cross-session saving, full-game progression, replenishment rules, additional carry classes, and larger workshop layouts remain open.

Update this file when gameplay decisions are accepted. Keep proposals visibly separate from agreed rules. Update the robot specifications only when the robot itself changes. Import or optimization work must preserve the source assets and inventory unless a later decision explicitly changes them.

## First playtest feedback and interaction revision

The user found fetching the correct parts and clicking them into place satisfying. Generous connection targeting worked well and remains unchanged. The two-handed pad felt floppy, and the original HUD and controls presentation obscured too much of the workshop.

The feedback pass implements:

- A firm, collision-aware grip for two-handed carrying, with ordinary physics restored when set down.
- Removal of the workshop-title header and permanent general-controls strip.
- A compact action bar showing part images, IDs, quantities and selection. The later pocket rebuild below establishes ten persistent slots and a separate carrying indicator.
- A grouped Escape controls menu with a prominent resume action and confirmed restart.
- Double-tap R to reset the inspected station, alongside hold-R rotation and a contextual tutorial hint.
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

The original single-pad loop remains a regression scenario. The construction model is independent of desktop input. The actuator extension is described below; cross-session save/load and AR support remain later increments. See the [workshop README](game/heel-pad-demo/README.md) for controls and verification.


## Pitch actuator milestone

Increment 3 adds the complete pitch actuator and its installation to the default workshop: 91 child pieces and 18 parent mounting pieces, alongside the 26 pad pieces. All 135 active identities come from the unchanged 745-object source. Armor is staged aside; the remaining source items stay accounted for as context. External wiring and actuator motion remain future branches.

FA-510 starts on the floor beside preparation C; the player picks it up and suspends it at the empty station. Fourteen authored child pages cover drive modules, shaft/rod retention, sensors, guide/seals, cap closure, both eyes, and the handoff. The parent manual covers base/ring clevises, their washers and bolts, seating the completed child, and both eye-pin keeper stacks. Prerequisites require internal work before closure and both secured clevises before mounting. Each physical build retains its manual page and progress.

The compact action bar now represents ten persistent small-part pockets independently of the selected manual. Each stack holds up to 20 copies. Shelf components and whole assemblies use the assisted solid grip separately from those pockets. Internal work exposes the barrel with a translucent service view and generous slot previews; no precision threading or torque minigame is added.

Verification is headless: the actuator's complete build/install/undo path uses the desktop adapter, source transforms and physics. The original single- and two-pad regressions remain available. Human assessment of cabinet layout, manual readability and the longer collecting loop is still needed. Save/resume is the next planned increment; current progress remains session-only.


## Pockets and wall storage rebuild

The action bar is the source of truth for collected small items. E loads up to 20 available copies into an existing matching pocket or an empty pocket, then selects it. If all ten pockets are occupied by other types, E replaces the selected stack and returns those identities to their drawer. An empty drawer does not clear or change another pocket. B clears the selected stack anywhere. Undo returns small pieces to a suitable pocket or their drawer without replacing existing stock.

Cabinets sit against the wall with two low rows. Every drawer has its source part ID, cached source-mesh image, optional name, and available quantity. Small stock never exists as loose scene meshes or physics bodies. Hand-sized components remain on shelves and can be picked up with E and set down with Q. Installed small parts and valid attachment previews retain source geometry.

Manual instructions and parts lists use the same IDs as storage. Names clarify those IDs, including different base/rod variants. Page Up/Down scroll longer lists. Manual navigation does not change pocket contents, ordering or selection. Static part images replace live hotbar/catalogue viewports, and component installation adds/removes only the changed visual. Headless checks cover behavior and reduced preview workload; frame-rate and visual comfort need a human playtest.

The manual audit removes future-step reminders and gives every construction page a distinct list of only its required new components, including prepared subassemblies at their mounting steps. Summary pages show assembly progress. Receiving parts already fitted in earlier steps are described as such. FA-511 and FA-512 are required only on the housing-closure page.

The rotation/orientation repair keeps mounted and suspended builds fixed relative to their parent during continuous R-drag. Installed hardware uses the receiving slot's oriented source geometry, matching its preview while retaining the consumed physical identity. Next, perform the [manual and assembly visual review](design/game/foot-prototype-plan.md#manual-and-assembly-visual-review) before expanding content: per-step rendered comparisons, fastener close-ups, multiple angles, rotation recordings and a reviewed baseline. Headless geometry checks are necessary but do not replace that review.
