# Shared robot design

Last updated: 2026-10-20

[Design index](../ROBOT_DESIGN.md)

Read this alongside the relevant component specification. These rules apply across the robot; component files hold the detailed construction choices.

## Scope and status

- **Current focus:** design the robot in detail before creating its reference diagrams.
- **Future context:** a puzzle game set in a 3D first-person workshop, where the player assembles a giant piloted machine from scratch.
- **Game implementation:** outside the current task. Do not start building the game.
- **Long-term assembly ambition:** support a breakdown down to individual nuts, bolts, and other small components.
- **Six major body sections:** left leg, right leg, torso, left arm, right arm, and head.
- **Leg-to-torso boundary:** each hip ball belongs to its leg; the matching socket sits in the pelvis, which belongs to the torso.
- **Arm-to-torso boundary:** each shoulder ball is integral to its upper-arm skeleton; the matching socket sits at the end of the torso's shoulder crossmember. The pauldron belongs to the arm.
- **Head-to-torso boundary:** a fixed keyed neck spoke with a central wiring passage belongs to the torso skeleton; the head's baseplate bolts onto it and supports the head assembly.
- **Working design order:** legs, torso, arms, then head. Develop the left leg first and mirror it for the right.
- **Diagram status:** the FA-01 foot-and-ankle concept reference set has been generated for review; see the [image register](legs/foot-and-ankle/images/README.md). Other assemblies still need their own detail passes before diagrams.

“Confirmed” below means the user selected a choice or accepted the assistant's recommendation. A confirmed concept does not imply that its dimensions, detailed geometry, or fastener schedule have been resolved.

## Confirmed whole-robot direction

| Attribute | Decision |
| --- | --- |
| Inspiration | Gundam-like giant piloted robot |
| Height | 18 metres from the ground beneath the soles to the crest tips |
| Overall character | Sleek and heroic |
| Proportions | Humanlike, using the classic RX-78-2 silhouette as a visual benchmark; dimensions are recorded in the shared proportion layout |
| Symmetry | Mirror left and right limbs for now |
| Mechanical approach | Plausible fictional machinery |
| Actuation direction | Electric screw actuators for the ankles; reserve hydraulics for larger leg joints, including the knees. Other joint choices remain component-specific |
| Construction | Internal mechanical skeleton with removable armor attached over it |
| Armor geometry | Crisp, angular plates |
| Surface detail | Broad, clean armor surfaces; a few recessed bolts and access panels; mechanical detail concentrated in gaps |
| Rear-leg treatment | More visible mechanisms around the back, particularly calf thrusters; engine bodies remain mostly housed |
| Feet | Elongated toes for a mechanical silhouette |
| Color and markings | Deferred until the structure is established |

## Detail-development approach

The working approach is to develop a hierarchy rather than invent every fastener immediately:

1. Establish the overall silhouette, proportions, and body-section interfaces.
2. Define each major assembly and its purpose.
3. Separate structural members, joints, actuators, armor, and other components.
4. Specify their attachment methods and smaller hardware once the connected parts are understood.

For each eventual part, record its name, purpose, attachment points, movement if any, and installation dependencies. Reuse compatible connection and fastener families where appropriate.

An earlier suggestion was to make a future first playable leg from roughly 8–12 substantial pieces, then subdivide assemblies later. **This is a deferred prototype suggestion, not a confirmed limit on robot parts or authorization to implement the game.**

## Shared leg silhouette

### Overall appearance

- Clean, angular armor on the front.
- More mechanical interest at the back, especially the recessed calf thrusters.
- An integrated, athletic calf: wider in its upper half, tapering toward the ankle.
- Thrusters integrated into the calf silhouette rather than carried in a strongly projecting external engine pod.
- An athletic upper thigh, slightly broader than the calf, tapering toward the knee.
- A visible ankle mechanism protected by separate side guards.
- A long, low forefoot and a short but substantial heel.

## Open whole-robot design work

- Detailed geometry and movement clearances within the [shared dimensional layout](proportions.md).
- Colors, materials, surface finishes, markings, and any accessories.

The main design and construction approach for every body section, both proposed proportion batches, and reference pose are confirmed. Additional component envelopes have been selected under the user's direction to use the recommended proportions. Detailed geometry, clearances, component inventories, fastener schedules, finish, and reference-sheet format still need refinement.

## Shared dimensions

Use [Robot proportions and dimensional layout](proportions.md) as the single source for dimensions, reference coordinates, and stance. It distinguishes explicitly accepted dimensions from assistant-selected working envelopes. Read its relevant sections alongside each component file when preparing diagrams.
