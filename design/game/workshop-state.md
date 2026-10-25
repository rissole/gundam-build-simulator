# Workshop: current state

Updated 2026-10-25. Read this before continuing workshop development. Keep it short:
current state, active rules and open decisions. Record player findings in the
[playtest checklist](robot-workshop-playtest-checklist.md). When a piece of
work finishes, move its narrative and evidence into [history/](history/) and leave
a one-line summary here. Earlier versions of this file are
[history/workshop-state-20261024.md](history/workshop-state-20261024.md) and
[history/workshop-state-20261025.md](history/workshop-state-20261025.md), the
last version before consolidation.

## Where things stand

- **Manual redesign (2026-10-25, whole robot converted):** every action step is a
  one-sentence goal plus a self-ticking checklist generated from typed objectives;
  every machine line reads "<Where>: <exact control text>" from one label function
  per machine (prompts and the crane console use the same text). The user approved
  the pilot ("no notes, perfection"); M opens the manual, Tab hides the translucent
  panel. Waist yaw/lean neutral pins are now twist/tilt lock pins. New steps cover
  crane trips that had no page. All 35 routine cases pass (`stage_contract_test`'s
  fixture now supplies the `save` that commit 0721744 started calling). No diagnostics or rendered review ran. **Awaiting the
  user's playtest of the converted chapters.** [Manual plan](manual-plan.md).

- **Workshop save (2026-10-25):** saving is manual: pause-menu **Save**,
  **Save & quit**, or closing the window. **Quit without saving** confirms when
  there are unsaved build changes. A save holds the model, every machine's last
  stop and the player's position and view. Saved mid-ride, the player reloads on
  the deck at that machine's last stop. Saves are never refused: a moving crane
  is saved stopped where it is, load hanging, and Resume continues. A reload
  puts hands, pockets and loose parts back in drawers. Invalid saves are
  deleted, never migrated. The pause menu offers **New workshop**. Mechanical
  checks: `save_roundtrip_test` (fresh boot, mid-ride, mid-lift crane) and the
  diagnostic `save_roundtrip_stages_test` (145 checks), which passes at every stage
  boundary and mid-way through each stage's first crane delivery. Its first run
  found that reloads left the pelvis on the heavy module rig. Every build mounted on
  the pelvis moved with it, and the fall-through-floor rescue sent the sunken heel
  pads and pitch actuators home. `module_supports.apply` now seats the pelvis on
  the gantry. Reload feel awaits the user's playtest. Design:
  [Saves and checkpoints](robot-workshop-plan.md#saves-and-checkpoints).

- **Retina rendering (2026-10-25):** disabling HiDPI made UI text blurry in the
  user's playtest. HiDPI is restored; on macOS only the 3D render scale is now
  divided by the display scale (0.5 on a 2× Retina screen), keeping the HUD at
  native resolution. Moving between screens updates the scale. In-world labels
  remain part of the lower-resolution 3D scene. Restart to apply; sharpness and
  FPS await the user's playtest. Earlier performance measurements predate this change.
  The first scaling implementation caused a blank blue screen: a nonexistent
  `Window.screen_changed` signal aborted startup. Replaced it with `dpi_changed`;
  the startup smoke now covers the signal connection even in headless mode.

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
  `./play.command --editor`. Mechanical checks only. Player findings are in the playtest checklist.
- **Robot workshop (2026-10-24):** the base foot build (two heel pads and the
  pitch actuator) happens in the final-assembly hangar, then the build continues
  in the same session: pelvis → both legs → chest → core → backpack → both arms
  → pauldrons → head → crown. `--stage=complete` is the final boundary. The left
  foot rests on the turning foot rig, which stands in for its bay store
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
  (2026-10-25). Labelled physical buttons, elevator Up/Down and separate mobile
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
- **Guarded equipment motion (2026-10-25):** the workshop will hold thousands of
  loose parts, so moving equipment must not need a clear line along its whole
  route. Design, agreed with the user:
  - Obstructions never refuse a request. The trip starts and pauses short of
    anything in the next stretch of travel (`LOOKAHEAD`), then resumes on its own
    once it clears.
  - The pause names what it is waiting for: the player, a named loose part, or
    the hand load.
  - A held trip accepts a new destination, so a rider is never trapped.
  - Loose parts in a path are pointed at, never pushed aside (user's choice), so
    the path itself must be very visibly marked.
  - Elevators take the simplest form: no landing gates. A player may lean up to
    `PLAYER_TOLERANCE` (0.2 m) into the shaft; the arriving car nudges them back
    onto the landing. Anyone further in holds the car above their head with
    "Step back out of the lift doorway."

  **Elevators done.** A player at the CALL button stood 0.01–0.25 m inside the
  old whole-route reservation, so every landing call was refused with a generic
  "loose parts" message. `access_lift_test` now covers held trips, retargeting,
  and leaning 0.08/0.18/0.26 m. A temporary full-workshop probe also checked the
  real lifts: calls from the button reach the ground, 8.4 m and 11.2 m landings
  and nudge the player onto solid floor. Mechanically checked only; awaiting the
  user's ride. The named diagnostics `pauldron_delivery_test` and
  `wide_foundation_test` drive lifts and were not run.

  **Shared policy implemented (2026-10-25):** elevators, mobile platform,
  shelf cargo, loaded crane/rig and rail now use `EquipmentRegistry.Motion` for
  short look-ahead, obstacle masks and named feedback. Platform and rail
  obstructions wait and resume automatically; loose blockers use the existing
  outline. Manual Stop remains explicit. All 29 routine cases passed in 9.353 s;
  mechanical evidence only. [Scope, constraints and evidence](history/shared-equipment-motion-20261025.md).

  **Remaining:**
  - The mobile platform's route lane still needs visible floor marking (the
    user's condition for pointing at parts instead of pushing them).
  - User playtest of waiting/resuming, held-trip return controls, obstruction
    wording/outline visibility and the elevator nudge. No rendered review ran.

## Next

1. The user playtests the robot workshop with the
   [playtest checklist](robot-workshop-playtest-checklist.md), from the foot build in the
   hangar onward. Record results there.
2. Finish guarded equipment motion (see “Where things stand”): mark the mobile
   platform's route lane, then playtest the shared waiting/resuming behavior.
3. Pick from the deferred items below only after a decision.

## Active rules

- **Player language:** a bay is a crane destination (Heavy Module Bay, Limb Bay, Foot Bay, Final Assembly Bay, Parking bay). Every holder except the gantry is a rig. The gantry is the only named machine. Crane lines are crane cables; the ends are magnetic connectors. Internal ids stay as they are.
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
- **Saves are snapshots at rest.** A normal launch saves each set component; a
  machine's `capture()`/`apply()` must round-trip its at-rest state, including its
  supported load. No migrations, mid-motion state or per-machine validators.
  `--stage=<name>` gives supplied progress and is not playtest evidence. It never
  loads the save, but Save overwrites the slot with the stage plus the player's
  progress (user decision, 2026-10-25); closing the window saves only after a build
  change since the stage, and Restart re-runs the stage without deleting the save.
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

- Pause-menu playtest checkpoints. Saving itself is implemented; the original
  checkpoint list is in the plan's
  [Saves and checkpoints](robot-workshop-plan.md#saves-and-checkpoints).
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
| [manual-plan.md](manual-plan.md) | Changing manual steps, the current-step panel or the manual view |
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
