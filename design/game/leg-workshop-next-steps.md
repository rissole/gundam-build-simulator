# Workshop: current state and next steps

Updated 2026-10-25. Read this before continuing workshop development. Keep it short:
current state, active rules, open decisions and player feedback. When a piece of
work finishes, move its narrative and evidence into [history/](history/) and leave
a one-line summary here. Earlier versions of this file are
[history/workshop-state-20261024.md](history/workshop-state-20261024.md) and
[history/workshop-state-20261025.md](history/workshop-state-20261025.md), the
last version before consolidation.

## Where things stand

- **Performance (2026-10-25):** shadows stay enabled with the same 4096 atlas,
  65 m coverage, split blending and approved lighting. Two cascades replace four;
  distant shadows trade detail for fewer caster draws. Targeting now counts stock
  once per pass, rejects distant static connection groups using their authored
  target bounds, and keeps articulated/child targets and access rules live.
  CPU probe: ~7.0→1.7 ms targeting. Same explicit-draw arrival sweep: ~35–36→43–44
  FPS; normal rendering also completed validly at ~42–45 FPS. All 29 routine
  cases passed (7.6 s), then the expanded 20-check targeting fixture passed.
  **60 FPS is not achieved.** Reported 6003×3750 render texture, later-stage
  performance and broader hardware remain unresolved. Shadow appearance awaits
  user playtest; no rendered visual review. Evidence: local
  `verification/shadows-targeting-report.json`; benchmark usage in the workshop README.

- **Fast verification (2026-10-25):** the default runner now selects isolated tests
  and one fresh-workshop smoke. Expensive investigations require explicitly requested
  named diagnostics, never automatic full-suite verification. A 60-second warning
  calls for improving tests, not extending timeouts. See the
  [coverage migration](../../game/workshop/tests/TESTING.md). The new staging test
  caught and fixed right-pad fallback consuming left sleeves; mirrored staging now
  keeps fallback stock within authored mirrored sources. All 28 routine cases passed
  three warm runs in 8.82 s, 8.72 s and 8.77 s (existing imports; no import timed).
  An existing lift test now yields between simulated frames after a Jolt worker
  exhaustion failure; assertions are unchanged. No diagnostics or rendered review
  ran. Mechanical checks only.

- **One workshop, one command (2026-10-25):** at the user's request,
  `./play.command` is the only launcher and the robot workshop is the only game.
  The foot-only workshop, the leg-bay equipment trials and their trial selector,
  the single- and two-pad regression scenarios, the prepared-foot development
  scenario and every save system were removed, with the tests that only covered
  them. `--stage=<name>` is the one game flag. Tests boot the same workshop and
  reach a stage with `boot_workshop("<stage>")`. `edit.command` was folded into
  `./play.command --editor`. Mechanical checks only; see the feedback table.
- **Robot workshop (2026-10-24):** the base foot build (two heel pads and the
  pitch actuator) happens in the final-assembly hangar, then the build continues
  in the same session: pelvis → both legs → chest → core → backpack → both arms
  → pauldrons → head → crown. `--stage=complete` is the final boundary. The left
  foot rests in the turning foot fixture, which stands in for its bay store
  (store masts and soles removed, no dispatch rails). The crane collects it from
  the same pose once it is upright. The foot's 35 cabinets sit on the hangar's
  rear wall, and the grid skips the preparation stations, tray and actuator
  start. **Awaiting the user's playtest.** The [design contract](robot-workshop-plan.md)
  and the [spatial contract](final-assembly-plan.md) are both current.
- **Leg-bay equipment trials:** accepted by the user on 2026-10-23, then removed
  in the consolidation. Their accepted handling rules are kept below.
- **Equipment controls:** the crane console is movement only. There is no load
  list: the empty crane offers **Move to pickup** for the next load in
  `crane.order`, and a carried load offers **Move to delivery** or **Put back**
  (2026-10-25, see the feedback table). Labelled physical buttons, elevator Up/Down and separate mobile
  height controls and a single Move destination menu. Screenshots inspected.
  [Change and evidence](history/equipment-ui-20261024.md); use the
  [focused controls checklist](robot-workshop-playtest-checklist.md#focused-controls-check--2026-10-24).
- **Workshop visuals:** minimal engineering palette and calmer signs/markings
  ([2026-10-24 refresh](history/workshop-visual-refresh-20261024.md)). Hangar
  lighting and room finish rebuilt 2026-10-25 from a Blender preview the user
  approved (`scripts/hangar_dressing.gd`): pooled bay task beams, 17 spotlights,
  slabs, cladding, clerestories, services and a north hangar door. Headless boot
  only; **no regressions, surface audit or rendered review run**, at the user's
  request. User found it too dark in game (2026-10-25): ambient 0.11→0.42, key
  0.16→0.5, exposure 1.25 (frame median 22→75/255) was then too bright; settled
  between at ambient 0.24, key 0.35, exposure 1.1 (median 46/255). User approved this brightness in game.
- **Expanded workshop acceptance:** held while the whole-robot workflow is designed.

## Next

1. The user playtests the robot workshop with the
   [playtest checklist](robot-workshop-playtest-checklist.md), from the foot build in the
   hangar onward. Record results there and summarize them in the feedback table
   below.
2. Pick from the deferred items below only after a decision.

## Active rules

- **The user owns playtesting** of walking, visibility, reach and connection access.
  Automated checks cover content, equipment movement, support ownership and
  interlocks. Don't run automated walked acceptance, reach/visibility sweeps or
  rendered review unless the user asks for them. Runtime reach and obstruction
  rules stay active; a pending playtest is no reason to allow remote fastening.
- **Report evidence by kind.** Keep mechanical checks, inspected presentation and
  player responses separate. A test pass or elapsed time never counts as acceptance.
  At a human checkpoint, finish the coherent work, stop, present it and wait for
  explicit go-ahead.
- **One workshop.** Don't add launch profiles or separate scenarios. Development
  and tests reach later progress through `--stage` / `boot_workshop(stage)`.
- **Nothing is saved.** `--stage=<name>` gives supplied progress for inspection. It
  is not a save and not playtest evidence.
- **New sections are data.** Add them on the shared staged receiver and the
  `game.zones` occupancy register. Don't add bespoke receiver controllers,
  pairwise machine checks or new crane-contract flags.
- **Check the full rigging envelope first.** Before expanding a delivery, compare
  source geometry, parked equipment, adapters, the spreader and every cable
  against the measured route. Record a real design discrepancy before changing a
  selected route.
- **Process.** Use one fresh session and one commit per task. Before work that adds
  part icons, ask the user to run `./play.command --headless --editor --import --quit`
  (no sandbox escalation). Regression runner:
  `python3 game/workshop/tools/run_regressions.py` (or `--only <cases>`).
  Expensive `run_diagnostics.py --only <cases>` runs require an explicit user request.
  Do not run every diagnostic or use diagnostics as automatic fallback.
- **Where answers go.** Put decisions in the existing component documents and the
  shared plan. Keep temporary evidence outside the design-document tree.
- **Preserve:** the robot workshop's scale, supported handling and local
  correction. Reversing is for correcting mistakes; full teardown is outside
  acceptance. Keep the head-on-neck sequence.
- **Riding is shared.** Anything the player stands on carries them and the load in
  their hands as it moves (`EquipmentRegistry.physics`). Equipment treats its rider
  and hand load as part of its moving envelope (`WorkshopEquipment.passengers()`),
  not as obstacles. Don't add per-platform rider code.
- **Handling rules kept from the leg-bay trials:** the lift shelf holds two one-hand
  parts or one two-hand part, on the side opposite the hip working corner. Keep
  the accepted boarding and hip approach clear. Source and receiver support stay
  distinct from fastening, and decorative cables can't stand in for a supported
  transfer. Fitted retention blocks Return, and the holder stays engaged until a
  complete ring is secured. Don't reintroduce the external capture/stabilizer
  command rejected in the layout-trial correction.

## Deferred: needs a decision

- Saving, save validation and pause-menu checkpoints. When they return, save
  only at rest: no equipment moving, every load on a support. The original
  requirements are preserved in the plan's
  [Saves and checkpoints](robot-workshop-plan.md#saves-and-checkpoints); the
  removed foot save design is [archived](history/save-resume.md).
- The chest's 60° bare-frame service tilt. It only matters once chest preparation
  is built; the prepared chest stays upright.
- Obsolete top-level layout keys (the single-task `crane` fields and `rail` values
  that predate the crane task list).
- Migrating the core, backpack and shoulder receivers onto the generic staged receiver.
- The arm's lower 1.13 m pre-seat approach, which clears a fixed front drive clevis.
  The user was offered this or later bracket installation. The lower approach is
  the current implementation choice, not an explicit user approval.
- Eventual whole-robot lowering (the raised workshop pose is the planning baseline).
- The partial reverse/fork-return investigation is
  [archived](history/leg-workshop-m3-plan.md#deferred-reverse-investigation). It is
  not required work.
- A later PDA could reduce console walks; how it is acquired and unlocked is open.
- Out of scope for now: detailed component internals, finished art, loose-chain or
  swing physics, detailed Blender leg assets, powered mechanisms, armor, more robot
  branches and AR.

## Player feedback to retain

| Feedback / positive finding | Current direction and open question |
| --- | --- |
| Generally low FPS, with much more component detail still to come; wants 60 FPS on entry gaming hardware and Apple Silicon. Explicitly rejects disabling shadows because it makes the world flat (2026-10-25) | Preserve shadows and approved brightness. Two-cascade shadows plus targeting improvements implemented and mechanically measured as above. This is a gain, not a 60 FPS pass. Remaining options: verify/control actual render resolution, reduce repeated geometry submissions, then measure later stages and component growth. Far-shadow detail needs the user's judgment. The initial focus-lost benchmark was rejected; subsequent normal rendering passed the frame-validity guard. |
| Regression verification took 10–15 minutes per change; agents kept running full suites despite documentation. Wants unit-style tests around one minute, separate named diagnostics, and a warning rather than a 60-second timeout (2026-10-25) | Default runner structurally selects routine tests only. Shared content, local crane/receiver/staging contracts and isolated chest/shoulder geometry replace routine journeys. Unique full-scene checks remain named-only diagnostics; never automatically selected. Warn and improve tests above 60 seconds; do not raise the budget. Existing fast model/physics tests were a positive baseline. See the coverage migration linked above. |
| Wanted everything consolidated into a single play command (the full workshop) with flags such as `--stage=` to skip stages or support tests, and no milestone references outside history (2026-10-25) | Implemented as described under “Where things stand”. The user chose to remove the foot workshop with its save code, and to delete the leg-bay trials with their tests. Removed with them: the single/two-pad, trial and save suites, the broken walked-journey suites, the stale single-leg geometry review, and (at the user's request, who will verify the foot build by hand) the foot-room suites that depended on the old room's coordinates: jump, snap discovery, manual navigation, free-build targeting, interaction feedback, workshop geometry, supported fixture and crane console panel. Porting the foot suites found and fixed three robot-game bugs: the journey filter removed carry, station and mount targets (the pads and actuator could not be picked up, suspended or mounted); staging the supplied right foot consumed the left foot's own identities; and the foot carrier refused undo of the left foot while it was still in its fixture. The stock grid now also keeps a 1.6 m aisle clear in front of the preparation stations, tray and actuator start. Preparation-station rotation (hold R) is enabled, as it was in the foot workshop; the hangar had disabled it. Mechanically checked only; awaiting the user's check of the foot build. |
| Workshop was ugly/crowded, lighting needed improvement, and overlapping surfaces flickered prolifically (2026-10-24) | Minimal practical engineering style implemented for the workshop only; robot models remain for later detail. 142 initial surface overlaps repaired, with moving equipment/alternate fixtures checked too. [Screenshots and evidence](history/workshop-visual-refresh-20261024.md); awaiting user judgment. |
| Implementation took 6 h+; the user suspected poor architecture (2026-10-24) | Addressed by the handoff tasks: a generic staged receiver, an occupancy register and the shared stage sequence. Keep new sections as data. |
| Saving and checkpoints keep adding work and are often wrong (2026-10-24) | Deferred until the structure exists; `--stage` replaces checkpoints. All save code is now removed. |
| Wanted one command to launch the game, with the base foot build combined with the wider workshop, while flags still skip to progress points (2026-10-24) | Implemented with `foot` and `actuator` stages ahead of the structural stages. The combined game has no saves. The fixture's store position and raised work height (foot origin 2.0 m, previously 1.55 m) are an implementation choice; reaching the heel seats and upper fasteners there is untested. Walking from the rear-wall cabinets is untested. One grid drawer spills to (−10.8, 3.6), outside the authored stock bay. |
| Rigging paths were already clear in the agreed plan; extra discovery iterations undermine its purpose | The core sweep first omitted the full spreader/cable envelope, and parked gates intruded into the bypass. That was an implementation/verification miss, not planning ambiguity. See the rigging rule above. |
| The original leg-to-gantry build is “largely satisfying”, but implementation relied too much on in-game discovery (2026-10-24) | Preserve its physical handling. Define coordinates, load routes, work faces, standing areas and equipment clearances before implementing, working backwards through the [final assembly plan](final-assembly-plan.md). |
| Prefer side elevators and walking onto shared front/rear work platforms | Selected for the full gantry. Keep the raised workshop datum; lowering is undecided. |
| Hip and shoulder connections should remain accessible using shared elevators | Each side elevator serves every work level. Needs the user's playtest with arms fitted. |
| Prefer shared left/right construction: one long-limb workshop, or separate arm and leg stations | One shared limb station. Legs leave on the rail cradle, arms by crane. No per-side workshops. |
| Proposed workshop measurements look good, but unresolved interfaces could change them | Interfaces are now recorded in the component documents and the shared plan. Actual-solid checks happen per delivery. |
| Overlapping, intricate leg-area controls and labels were hard to use | Local tactile rail/lift controls. Judge grouping, labels and explanations in ordinary play; targetability alone doesn't prove readability. |
| Final-bay task buttons had the same clutter | Crane tasks use one central physical console; rail/lift operation stays local. |
| Final-bay lift scale and onboard ascent were close to the intended experience | Preserve boarding, travel, reach and scale. Primitive art is not the visual target. Rails and elevators were praised at the corrected layout-trial acceptance. |
| Large components appeared to float; transport and support were unclear | The leg rail, visible holder contact and individually attached crane magnets must show support through collection, travel, seating, fastening and release. |
| PV-120 halves looked collectible but were static | Ordinary two-hand carrying and a finite lift shelf replace the rejected positioning arm. Small hardware stays in pockets. |
| Initial crane-trial delivery and magnetic attachment broadly worked | Console captures mouse/look; arrows + E operate it and Q closes. Held magnets are centered. The trial replay was accepted 2026-10-23. |
| The mobile work platform needs a stop button, and bonks the player around instead of carrying them while it moves (2026-10-25) | Added a STOP key under MOVE on the deck panel; the sign then says how to resume (MOVE resume/return, or UP/DOWN). Bonking had two causes, both shared: the player body also followed the deck's platform velocity on top of the registry's exact carry (now disabled, so stepping off no longer flings either), and Jolt applies a kinematic deck's new pose only at the next step, so the player moved against the stale deck. The player now moves before equipment each tick. The platform test now runs the rider's own move each tick. Mechanically checked only; awaiting the user's ride. Elevators and the lift shelf share the change but were not ridden in a test with the player's move. |
| The mobile work platform (“bulky platform”) wouldn't move with the player on it; any moveable platform should carry the player, even when they're holding something, as a shared system (2026-10-24) | Ground transfers now accept a rider on the lowered deck; loose loads on the deck still block. Riding moved into the shared registry, and elevators and the lift shelf use it too. Mechanically checked only; awaiting the user's ride. |
| Crane controls fill the screen; first asked for placement like pickup prompts, then chose the center of the screen | Centered placement and fixed view preserved. Movement stays visible on the main view. Screenshots inspected, awaiting the user's manual check. |
| Crane menu is confusing/cluttered; simplify other inputs, especially elevators and the mobile lift. Prefer Up/Down without Stop (2026-10-24) | Elevator's third onboard button was Ground; replaced the onboard trio with labelled Up/Down, retaining separate landing Call buttons. Mobile lift separates Up/Down from travel; the follow-up replaces Dock/Move with one Move destination menu, including interrupted-trip recovery. Other physical equipment keys now carry labels. Screenshots and README refreshed. See the focused controls checklist. |
| Too many crane load types, unclear; the crane should be generic with controls focused on movement. A place-picker draft still felt like "a million options" (2026-10-25) | Pickup/Deliver: at most Lower/Raise, Move to pickup · place, Move to delivery · place, Put back, Park. The next load is the first in `crane.order` still at its source. A blocked load explains why (receiver, prerequisite or source equipment) instead of the crane skipping ahead. An undo points the pickup at that connection. The 31 authored routes stay hidden. Places only name locations (`crane.places`). Out-of-order deliveries are no longer possible from the console. `crane_pickup_test` passes (mechanical); the screenshots still show the old chooser. Awaiting the user's check. |
| Replace mobile platform Dock/Move with one Move button and a crane-style destination menu (2026-10-25) | Implemented: choose a destination to start travel; Q/Close cancels, and interrupted travel offers Resume/Return in the same menu. Screenshots refreshed. Hands-on verification remains pending. |
| Workshop looks flat and bright; wanted improved lighting and workshop details, previewed in Blender before building in game (2026-10-25) | Blender preview of the live scene (exported from Godot) rendered; user: “a lot better… the rest of the workshop lighting is great.” Follow-ups applied in the preview: near-black ceiling replaced by a lighter ribbed deck with faint emission standing in for floor bounce; red fire points made small, matte and muted so they don't read as interactive; spotlights cut from 34 to 17 to stay within Compatibility's default 32 per frame / 8 spot per mesh without raising limits (general high-bay fixtures are emissive only; ambient + shadowed key carry general fill). Lighting: cool ambient ~0.11, AgX, light depth fog, key 0.5; 9 roof task beams pooled on bays (two on stock and leg parking); 4 column floods; 2 clerestory fills; 2 gantry under-deck downlights + LED strips. Details: 8 m slabs with joints, tonal epoxy bay pads, precast dado, ribbed cladding, window band, truss webs above the crane (23.8 m+), cable tray/duct, wall panels, hazard sleeves, north hangar door. Built in game 2026-10-25 with 4 m slabs (a cone-coverage estimate puts at most 8 spots on any slab, at most 2 on any wall panel) and the energy conversion from the preview's watts; **brightness is uncalibrated against Godot until the user's check.** Open: in-game brightness/contrast, AgX rendering in Compatibility, the dim green panel status lamps (asked whether they read as interactive, no answer yet), and the style audit on the new floor/wall layers. |

## Human checkpoints

| Checkpoint | Status |
| --- | --- |
| Leg-bay layout and scale | Corrected layout accepted 2026-10-23. Trial retired; its geometry lives on in the hangar. |
| Leg-bay equipment interactions | Accepted 2026-10-23; the trials were removed in the 2026-10-25 consolidation. |
| Original leg-to-robot journey | Forward-verified; the user called it “largely satisfying”, 2026-10-24. Replaced in place by the robot workshop. [Archived plan and evidence](history/leg-workshop-m3-plan.md). |
| Robot workshop (foot build + structure) | Implemented and mechanically verified; **awaiting the user's playtest**, starting with the two foot rows of the [checklist](robot-workshop-playtest-checklist.md). |
| Expanded workshop acceptance | Not started. Needs the earlier checkpoints and explicit acceptance. |

## Documents: what to read when

Read only what the task needs. Specific sections are linked from the rules above.

| Document | Read it when |
| --- | --- |
| [robot-workshop-playtest-checklist.md](robot-workshop-playtest-checklist.md) | Playtesting, or recording findings |
| [robot-workshop-plan.md](robot-workshop-plan.md) | Changing the robot workshop's stages, equipment or verification scope |
| [final-assembly-plan.md](final-assembly-plan.md) and [layout](final-assembly-layout.svg) | You need coordinates, routes, equipment dimensions or the assembly order |
| Component documents (`design/torso/`, `design/arms/`, `design/head.md`, `design/legs/`) | You need mounting interfaces. Each one's “Robot workshop … — 2026-10-24” section records what was built |
| [leg-prototype-interface.md](leg-prototype-interface.md) | Touching structural-leg parts, ownership or manual dependencies |
| [foot-prototype-plan.md](foot-prototype-plan.md) | Changing the shared assembly architecture, or doing a requested rendered review |
| [pitch-interface-repair.md](pitch-interface-repair.md) | Touching the pitch actuator |
| [Workshop README](../../game/workshop/README.md) | Launch commands, controls and the test runner |
| [history/](history/) | Archives only. Open a file there only when a current document links to it |

Contents of `history/`: the [wide-workshop handoff tasks 01–10](history/m3-wide-handoff/README.md),
[wide-workshop evidence and ledger](history/m3-wide-evidence-20261024.md), the
[original leg-journey plan](history/leg-workshop-m3-plan.md), the
[structural-leg milestone](history/leg-milestone.md),
[layout and equipment trial handoffs](history/leg-workshop-m1-m2-handoffs.md), the
[removed save design](history/save-resume.md), and the state snapshots from
[2026-10-23](history/workshop-pre-consolidation-state-20261023.md),
[2026-10-24](history/workshop-state-20261024.md) and
[2026-10-25](history/workshop-state-20261025.md).
