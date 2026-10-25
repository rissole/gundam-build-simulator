# Robot design record

Last updated: 2026-10-24

This is the working record for the robot and its engineering-style reference images. Update it as decisions are made so later design sessions and diagrams preserve the same details.

The record is now split by assembly. Start here, read the shared rules, then open only the components needed for the current design discussion or image brief. Left and right limbs share specifications because they mirror each other.

## Current status

The main construction concepts and proportions are established for all six body sections. Detailed work is proceeding assembly by assembly. This record governs the robot itself; the agreed workshop gameplay is recorded separately in [GAME_DESIGN.md](GAME_DESIGN.md). The first [Godot heel-pad demo](game/workshop/README.md) now implements a playable 135-piece workshop with two pads and the complete pitch actuator with shared construction rules and linked manuals; the [foot prototype plan](design/game/foot-prototype-plan.md) records the expansion path.

**The foot-and-ankle reference-design detail pass is complete (FA-01).** Its linked packet records dimensions, numbered components, 258 fasteners with washers per foot, actuator internals, wiring, assembly order and bounded envelope checks. Three engineering-style reference sheets have been generated for review; see the [image register and prompts](design/legs/foot-and-ankle/images/README.md). Exact CAD validation and real engineering sizing remain outside this milestone. Other body assemblies still need their own detail passes.

The current pass develops the final robot's major interfaces after the implemented leg-to-gantry prototype. The user authorized component owners to select details in the existing hip assembly/hip, chest/cockpit, backpack/core, shoulder/arm and head specifications. These now define assembly boundaries, mating hardware, support handoffs and measured access requirements. The [final assembly plan](design/game/final-assembly-plan.md) integrates their workshop consequences; actual equipment geometry, solid sweeps and detailed internal workflows remain. This is design work, not authorization for a new gameplay milestone.

## 3D assembly work

The first [FA-01 3D model package](models/foot-fa01/README.md) contains all 745 inventory objects as separate editable meshes, plus static/animated GLBs and individual OBJ exports. The saved scene, export and decoded-video audits pass. The completed 41-second construction/deconstruction film is included in the model package. [Modeling notes](models/foot-fa01/MODELING_NOTES.md) record the nut-plate variants, toe-roof clearance correction and other resolved details.

## Shared documents

- [Shared robot design](design/global.md): scope, 18 m scale, appearance, assembly boundaries, detail-development approach, and whole-robot open questions.
- [Proportions and dimensional layout](design/proportions.md): accepted dimensions, working component envelopes, reference coordinates, stance, and visual benchmark.
- [Final gantry and assembly plan](design/game/final-assembly-plan.md): active workshop access and major-section installation discussion, working backwards from the completed robot; mechanical dimensions remain in the component specifications.
- [Reference-image requirements and workflow](design/reference-images.md): confirmed style, proposed sheet contents, and how to prepare focused briefs and review consistency.
- [Decision history](design/decisions.md): the preserved record of choices and superseded proposals.

## Component specifications

Each file contains its confirmed design, selected working detail, remaining refinement and links to connected assemblies.

| Body section | Component specifications |
| --- | --- |
| Legs — mirrored | [Foot and ankle](design/legs/foot-and-ankle.md) · [Shin and calf](design/legs/shin-and-calf.md) · [Knee](design/legs/knee.md) · [Thigh and hip](design/legs/thigh-and-hip.md) |
| Torso | [Hip assembly](design/torso/pelvis-and-waist.md) · [Chest, abdomen, and cockpit](design/torso/chest-and-cockpit.md) · [Backpack, power, and cooling](design/torso/backpack-and-power.md) |
| Arms — mirrored | [Shoulder, upper arm, and elbow](design/arms/shoulder-and-upper-arm.md) · [Forearm and wrist](design/arms/forearm-and-wrist.md) · [Hand](design/arms/hand.md) |
| Head | [Helmet, sensors, mounting, and assembly sequence](design/head.md) |

## Maintenance rules

- Update the relevant component file after each batch of confirmed decisions; update shared rules when a change affects the whole robot.
- Distinguish confirmed choices, assistant proposals, and unresolved details.
- Do not silently turn a plausible detail into an approved specification.
- If a decision changes, update the active specification and record the change in [decision history](design/decisions.md).
- Before producing diagrams, review the shared rules, target component, and connected interfaces for unresolved dependencies and conflicting details.
- Keep gameplay decisions in [GAME_DESIGN.md](GAME_DESIGN.md) and game-development plans separate from the robot specifications.
- Keep each detailed construction specification and local interface dimensions in its component file and link to it from connected assemblies. Shared landmarks/envelopes belong in the proportion layout; derived equipment dimensions belong in the workshop plan.
- Keep historical proposals out of active image briefs. Use decision history only to understand why a choice was made or changed.
