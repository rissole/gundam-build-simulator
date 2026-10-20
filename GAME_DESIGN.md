# Mecha workshop — game design

Last updated: 2026-10-21

This records the agreed game design from the workshop-loop discussion. Robot geometry, engineering detail, and part inventories remain in [ROBOT_DESIGN.md](ROBOT_DESIGN.md). Recommendations for reaching a playable foot build are recorded separately in the [foot prototype plan](design/game/foot-prototype-plan.md).

**Status:** the core experience and interaction rules below are agreed. The user authorized the Godot heel-pad demo, and the [first playable project](game/heel-pad-demo/README.md) implements that milestone. Its controls, reach values, collision approximations, and layout are initial implementation choices for playtesting; later stages in the linked plan remain proposed.

## Experience and purpose

A first-person organisation and instruction-following game about constructing an 18 m piloted mecha in a large workshop/hangar. The user's reference is advanced 3D LEGO: organise a dishevelled workspace, consult illustrated instructions, build intricate components, and combine them into larger assemblies.

The intended pleasure comes from finding the right pieces, preparing supplies, following construction dependencies, and seeing a machine take shape. Identification and placement are forgiving. Individual screws and washers retain their detail, but require no manual threading, torque operation, or precision alignment.

Design the baseline experience without power-ups. They may be considered later. Carrying strength and convenient assembly stations are part of the baseline fiction; an exoskeleton or gravity-gun-like explanation is sufficient, and the lore is undecided.

## Core loop

1. Open the relevant manual or manual section and inspect the next construction step.
2. Find the required components in storage or among freely arranged larger pieces.
3. Gather a load within pocket and hand capacity; optionally prepare supplies beside the build in advance.
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
| Organisation and storage | Labelled bins for small hardware; shelves, drawers, and space to arrange larger pieces |
| Assembly/workbench area | Prepare supplies and build components at stations appropriate to their size |
| Mecha bay | Assemble major body sections into the standing robot; elevators on either side provide access to high connections; eventual launch destination |

The foot is approximately 3 m long and 1.3 m wide. Conventional furniture-sized workbenches alone cannot accommodate all construction. A roughly 5 × 5 m staging area was discussed as a possibility, not a fixed specification.

The current station concept is a cube-like work volume that suspends an unfinished assembly and permits free rotation. Access to the work should feel convenient and reliable. Operating the station is not intended to be a substantial challenge. Exact station dimensions, appearance, controls, and number of sizes remain open.

Objects remain at their designed scale. Large assemblies travel through an open hangar; narrow-doorway maneuvering is not an intended challenge. Hoists are excluded from the intended interaction. Transporting heavy assemblies should occupy a modest part of the experience.

## Organisation and identification

- Small hardware belongs in labelled bins.
- Larger pieces are available as loose physical objects. Players choose how to organise them on shelves and around the workshop.
- Looking at a component shows its ID and name in an on-screen tooltip. Recognition by silhouette or distinguishing nearly identical fasteners by eye is not required.
- Players can bring supplies over in advance and arrange them beside the current build, including in nearby trays or storage.
- Freely organising larger pieces has a practical payoff: knowing where items are and reducing repeated storage trips.
- There is no agreed mandatory layout, sorting score, or automatic re-scattering system.

## Pockets, hands, and carrying

The agreed capacity concept is approximately 20 bolt/washer-sized items in pockets, plus hand capacity for two hand-sized objects or one two-handed object. These are initial capacity targets; exact classification thresholds and tuning are still open.

Size and available carrying slots provide the limitation. Realistic mass does not prevent carrying a huge component. Large held objects remain solid and should collide with the environment; turning them into ghosts that pass through everything was rejected.

The requested physical feel is comparable to basic Source-engine object handling. This describes the feel, not a requirement to use the Source engine. Held-object distance, rotation controls, visibility, and collision response still need practical tuning.

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
- Do pocket/hand limits encourage preparation without making restocking dominate the session?
- Does generous targeting reliably select the intended connection, including near adjacent fasteners?
- Are small components, names, and manual illustrations readable at a comfortable first-person distance?
- Do solid held objects obstruct the camera or snag often enough to make transport frustrating?
- Can station rotation expose all relevant connections without becoming work in its own right?
- Do repeated small placements remain satisfying between meaningful completion moments?

At 20 small items per pocket load, the foot's 516 fastener pieces alone imply at least 26 loads if every item is carried once from storage. This is a pacing consideration, not a reason to silently remove detail or change the agreed capacity.

## Open details and record maintenance

Godot is selected for the authorized heel-pad demo. Its [README](game/heel-pad-demo/README.md) records implemented control bindings, carry classifications, reach, undo behavior, and current limits. These are initial prototype defaults rather than locked full-game tuning. Cross-session saving, full-game progression, replenishment rules, additional carry classes, and larger workshop layouts remain open.

Update this file when gameplay decisions are accepted. Keep proposals visibly separate from agreed rules. Update the robot specifications only when the robot itself changes. Import or optimization work must preserve the source assets and inventory unless a later decision explicitly changes them.

## First playtest feedback and interaction revision

The user found fetching the correct parts and clicking them into place satisfying. Generous connection targeting worked well and remains unchanged. The two-handed pad felt floppy, and the original HUD and controls presentation obscured too much of the workshop.

The feedback pass implements:

- A firm, collision-aware grip for two-handed carrying, with ordinary physics restored when set down.
- Removal of the workshop-title header and permanent general-controls strip.
- A four-slot MMO-style action bar showing actual 3D part models, family IDs, quantities, selection, and two-hand occupancy.
- A grouped Escape controls menu with a prominent resume action and confirmed restart.
- Double-tap R to reset the inspected station, alongside hold-R rotation and a contextual tutorial hint.
- Hold Ctrl to crouch for better inspection; standing requires overhead clearance.
- Non-exclusive fullscreen by default so the demo fills the display.

These changes preserve the source inventory, construction dependencies, one-click attachment, and generous hitboxes. Automated verification covers functionality; the revised carrying and presentation still need the user's feel assessment.

**Next direction, proposed after this feedback pass:** replace heel-pad-specific state and station assumptions with reusable assembly definitions and interchangeable work volumes. An assembly instance should own its progress, child identities, and manual position. A station should supply suspension, rotation, and size limits; it should not own the recipe. Attachment poses, compatible types/variants, prerequisites, and illustrated manual steps should read from shared authored data.

Prove that separation with another differently structured subassembly on the same station before expanding to the full foot. A second identical pad helps assess organisation and independent progress, but by itself does not prove that the construction system supports other kinds of machinery. This generic-system work has not been implemented in the feedback pass.
