# Workshop: current state and next steps

Updated 2026-10-25. Read this before continuing workshop development. Keep it short:
current state, active rules, open decisions and player feedback. When a piece of
work finishes, move its narrative and evidence into [history/](history/) and leave
a one-line summary here. The full text of this file before it was condensed is
[history/workshop-state-20261024.md](history/workshop-state-20261024.md).

## Where things stand

- **One robot game (2026-10-24):** at the user's request, `./play.command`
  launches profile `robot`. The base foot build (two heel pads and the pitch
  actuator) happens in the M3 hangar, then the wider M3 workshop continues in the
  same session. `--stage=<name>` starts later: `foot`, `actuator`, then the M3
  stages. The left foot rests in the turning foot fixture, which stands in for its
  bay store (store masts and soles removed, no dispatch rails). The crane collects
  it from the same pose once it is upright. The foot's 35 cabinets sit on the
  hangar's rear wall, and the grid skips the preparation stations, tray and
  actuator start. Mechanically checked (`robot_workshop_test`); **awaiting the
  user's playtest.** The foot-only workshop (`--profile=foot`, with its save),
  the M2 trials and `leg_bay_m3` (prepared foot) stay as development profiles.
  The upright-hoist workshop and isolated M1 trial remain retired.
- **M2 trials:** accepted by the user, 2026-10-23 (“m2 plays great”).
- **Wider M3 workshop:** implemented on branch `m3-wide-structure`, not merged or
  pushed. It covers pelvis → both legs → chest → core → backpack → both arms →
  pauldrons → head → crown, and `--stage=complete` is the final boundary. The
  last full regression run passed 41 of 41 cases. That is mechanical evidence
  only. The [design contract](m3-wide-workshop-plan.md) and the
  [spatial contract](final-assembly-plan.md) are both current.
- **Equipment controls:** compact crane movement view with a separate searchable
  load chooser; labelled physical buttons, elevator Up/Down and separate mobile
  height controls and a single Move destination menu. Screenshots inspected; **no regressions run**, as requested.
  [Change and evidence](history/equipment-ui-20261024.md); use the
  [focused controls checklist](m3-wide-playtest-checklist.md#focused-controls-check--2026-10-24).
- **Workshop visuals:** minimal engineering palette, calmer signs/markings and
  neutral lighting implemented. Workshop surface audit passes 14 checks; rendered
  screenshots inspected. User style/playtest acceptance remains pending.
  [Changes, screenshots and verification](history/workshop-visual-refresh-20261024.md).
- **M4:** held while the whole-robot workflow is designed.

## Next

1. The user playtests the robot game with the
   [playtest checklist](m3-wide-playtest-checklist.md), from the foot build in the
   hangar onward. Record results there and summarize them in the feedback table
   below.
2. Decide whether to merge `m3-wide-structure`.
3. Pick from the deferred items below only after a decision.

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
- **M3 has no saves**, so neither does the robot game that now contains the foot
  build. `--stage=<name>` (older spelling `--m3-stage`) gives supplied progress for
  inspection. It is not a save and not playtest evidence. The foot-only profile
  and M2 saves are unchanged and are no longer read by the default launch.
  Existing incompatible saves must stay protected.
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
  `python3 game/workshop/tools/run_regressions.py --only <cases> --jobs 4`.
- **Where answers go.** Put decisions in the existing component documents and the
  shared plan. Keep temporary evidence outside the design-document tree.
- **Preserve:** M3's scale, supported handling and local correction. Reversing is
  for correcting mistakes; full teardown is outside acceptance. Keep the
  head-on-neck sequence.
- **Riding is shared.** Anything the player stands on carries them and the load in
  their hands as it moves (`EquipmentRegistry.physics`). Equipment treats its rider
  and hand load as part of its moving envelope (`WorkshopEquipment.passengers()`),
  not as obstacles. Don't add per-platform rider code.
- **Handling rules kept from M1/M2:** the lift shelf holds two one-hand parts or one
  two-hand part, on the side opposite the hip working corner. Keep the accepted
  boarding and hip approach clear. Source and receiver support stay distinct from
  fastening, and decorative cables can't stand in for a supported transfer.
  Fitted retention blocks Return, and the holder stays engaged until a complete
  ring is secured. Don't reintroduce the external capture/stabilizer command
  rejected in the M1 correction.

## Deferred: needs a decision

- M3 saving, save validation and pause-menu checkpoints. When they return, save
  only at rest: no equipment moving, every load on a support. The original
  requirements are preserved in the plan's
  [Saves and checkpoints](m3-wide-workshop-plan.md#saves-and-checkpoints).
- The chest's 60° bare-frame service tilt. It only matters once chest preparation
  is built; the prepared chest stays upright.
- Removing the historical M3 branch in `leg_rail.gd` (M2 still uses that
  controller) and obsolete geometry keys.
- Migrating the core, backpack and shoulder receivers onto the generic staged receiver.
- The arm's lower 1.13 m pre-seat approach, which clears a fixed front drive clevis.
  The user was offered this or later bracket installation. The lower approach is
  the current implementation choice, not an explicit user approval.
- Eventual whole-robot lowering (the raised M3 pose is the planning baseline).
- The default-foot preservation replay is unconfirmed; keep its pinned save and
  source assets. The steps are in the [archived state](history/workshop-state-20261024.md#short-preservation-replay).
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
| Workshop was ugly/crowded, lighting needed improvement, and overlapping surfaces flickered prolifically (2026-10-24) | Minimal practical engineering style implemented for the workshop only; robot models remain for later detail. 142 initial surface overlaps repaired, with moving equipment/alternate fixtures checked too. [Screenshots and evidence](history/workshop-visual-refresh-20261024.md); awaiting user judgment. |
| Implementation took 6 h+; the user suspected poor architecture (2026-10-24) | Addressed by the handoff tasks: a generic staged receiver, an occupancy register and the shared stage sequence. Keep new sections as data. |
| Saving and checkpoints keep adding work and are often wrong (2026-10-24) | Deferred for M3 until the structure exists; `--stage` replaces checkpoints. |
| Wanted one command to launch the game, with the base foot build combined with M3, while flags still skip to progress points (2026-10-24) | Implemented as the `robot` profile with `foot` and `actuator` stages ahead of M3's. Open: the combined game loses the foot workshop's saves until M3 saving returns. The fixture's store position and raised work height (foot origin 2.0 m, previously 1.55 m) are an implementation choice; reaching the heel seats and upper fasteners there is untested. Walking from the rear-wall cabinets is untested. One grid drawer spills to (−10.8, 3.6), outside the authored stock bay. |
| Rigging paths were already clear in the agreed plan; extra discovery iterations undermine its purpose | The core sweep first omitted the full spreader/cable envelope, and parked gates intruded into the bypass. That was an implementation/verification miss, not planning ambiguity. See the rigging rule above. |
| M3 leg-to-gantry build is “largely satisfying”, but implementation relied too much on in-game discovery (2026-10-24) | Preserve its physical handling. Define coordinates, load routes, work faces, standing areas and equipment clearances before implementing, working backwards through the [final assembly plan](final-assembly-plan.md). |
| Prefer side elevators and walking onto shared front/rear work platforms | Selected for the full gantry. Keep the raised M3 datum; lowering is undecided. |
| Hip and shoulder connections should remain accessible using shared elevators | Each side elevator serves every work level. Needs the user's playtest with arms fitted. |
| Prefer shared left/right construction: one long-limb workshop, or separate arm and leg stations | One shared limb station. Legs leave on the rail cradle, arms by crane. No per-side workshops. |
| Proposed workshop measurements look good, but unresolved interfaces could change them | Interfaces are now recorded in the component documents and the shared plan. Actual-solid checks happen per delivery. |
| Overlapping, intricate leg-area controls and labels were hard to use | Local tactile rail/lift controls. Judge grouping, labels and explanations in ordinary play; targetability alone doesn't prove readability. |
| Final-bay task buttons had the same clutter | Crane tasks use one central physical console; rail/lift operation stays local. |
| Final-bay lift scale and onboard ascent were close to the intended experience | Preserve boarding, travel, reach and scale. Primitive art is not the visual target. Rails and elevators were praised at the corrected M1 acceptance. |
| Large components appeared to float; transport and support were unclear | The leg rail, visible holder contact and individually attached crane magnets must show support through collection, travel, seating, fastening and release. |
| PV-120 halves looked collectible but were static | Ordinary two-hand carrying and a finite lift shelf replace the rejected positioning arm. Small hardware stays in pockets. |
| Initial M2 crane delivery and magnetic attachment broadly worked | Console captures mouse/look; arrows + E operate it and Q closes. Held magnets are centered. M2 replay accepted 2026-10-23. |
| The mobile work platform (“bulky platform”) wouldn't move with the player on it; any moveable platform should carry the player, even when they're holding something, as a shared system (2026-10-24) | Ground transfers now accept a rider on the lowered deck; loose loads on the deck still block. Riding moved into the shared registry, and elevators and the lift shelf use it too. Mechanically checked only; awaiting the user's ride. |
| Crane controls fill the screen; first asked for placement like pickup prompts, then chose the center of the screen | Centered placement and fixed view preserved. Movement now stays visible on the main view; load selection is a separate searchable page. Screenshots inspected, awaiting the user's manual check. |
| Crane menu is confusing/cluttered; simplify other inputs, especially elevators and the mobile lift. Prefer Up/Down without Stop (2026-10-24) | Elevator's third onboard button was Ground; replaced the onboard trio with labelled Up/Down, retaining separate landing Call buttons. Mobile lift separates Up/Down from travel; the follow-up replaces Dock/Move with one Move destination menu, including interrupted-trip recovery. Other physical equipment keys now carry labels. No regressions run at the user's request; screenshots and README refreshed. See the focused controls checklist. |

| Replace mobile platform Dock/Move with one Move button and a crane-style destination menu (2026-10-25) | Implemented: choose a destination to start travel; Q/Close cancels, and interrupted travel offers Resume/Return in the same menu. Screenshots refreshed; no regressions run. Hands-on verification remains pending. |

## Human checkpoints

| Checkpoint | Status |
| --- | --- |
| M1 layout and scale | Corrected layout accepted 2026-10-23 (“Yep looks good - plan next milestone”). Trial retired; its geometry lives on in M2. |
| M2 equipment interactions | Accepted 2026-10-23 (“m2 plays great”). |
| M3 original leg-to-robot journey | Forward-verified; the user called it “largely satisfying”, 2026-10-24. Replaced in place by the wider workshop. [Archived plan and evidence](history/leg-workshop-m3-plan.md). |
| M3 wider workshop | Implemented and mechanically verified; **awaiting the user's playtest**. |
| One robot game (foot build + M3) | Implemented 2026-10-24 and mechanically verified; **awaiting the user's playtest**, starting with the two foot rows of the [checklist](m3-wide-playtest-checklist.md). |
| M4 expanded workshop acceptance | Not started. Needs the earlier checkpoints and explicit acceptance. |

## Documents: what to read when

Read only what the task needs. Specific sections are linked from the rules above.

| Document | Read it when |
| --- | --- |
| [m3-wide-playtest-checklist.md](m3-wide-playtest-checklist.md) | Playtesting, or recording findings |
| [m3-wide-workshop-plan.md](m3-wide-workshop-plan.md) | Changing the wider M3 workshop's stages, equipment or verification scope |
| [final-assembly-plan.md](final-assembly-plan.md) and [layout](final-assembly-layout.svg) | You need coordinates, routes, equipment dimensions or the assembly order |
| Component documents (`design/torso/`, `design/arms/`, `design/head.md`, `design/legs/`) | You need mounting interfaces. Each one's “Wider M3 … — 2026-10-24” section records what was built |
| [leg-prototype-interface.md](leg-prototype-interface.md) | Touching structural-leg parts, ownership or manual dependencies |
| [foot-prototype-plan.md](foot-prototype-plan.md) | Changing the shared assembly architecture, or doing a requested rendered review |
| [save-resume.md](save-resume.md), [pitch-interface-repair.md](pitch-interface-repair.md) | Touching base-game saves or the pitch actuator |
| [Workshop README](../../game/workshop/README.md) | Launch commands, controls and the test runner |
| [history/](history/) | Archives only. Open a file there only when a current document links to it |

Contents of `history/`: the [M3 wide handoff tasks 01–10](history/m3-wide-handoff/README.md),
[M3 wide evidence and ledger](history/m3-wide-evidence-20261024.md), the
[original M3 plan](history/leg-workshop-m3-plan.md), the
[structural-leg milestone](history/leg-milestone.md),
[M1–M2 handoffs](history/leg-workshop-m1-m2-handoffs.md), and the state snapshots from
[2026-10-23](history/workshop-pre-consolidation-state-20261023.md) and
[2026-10-24](history/workshop-state-20261024.md).
