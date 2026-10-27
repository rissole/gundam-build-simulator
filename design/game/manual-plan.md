# Manual: steps as checklists from one source

Agreed with the user on 2026-10-25. Feedback that led here is in the
[playtest checklist](robot-workshop-playtest-checklist.md#findings).

## Goal

The manual should be read without effort: a short goal, then a checklist the
player can act on ("OK, I need to go do that"). Every instruction, including crane
and rig trips, comes from one typed source. That source generates the text,
checks itself when it loads, and is what the stage progression executes. The
manual and the real machine sequence cannot drift apart.

**Player language.** In game this is **the manual**. The always-visible panel is
the **current step**. The full view is the manual, grouped into **chapters**. Do
not use "quest" or "quest log" in the game; that was only the user's analogy
(World of Warcraft).

## Settled decisions

- Each step has a **title**, a one-sentence **goal**, a checklist of
  **objectives** and at most one **note**. The note shows only while its
  objective is the current one. Safety details go there ("bolt heads from the
  knee side", "keep connectors attached until bolted"). Long prose bodies are
  retired.
- Objectives tick from game state. There are no click-to-tick objectives; if a
  condition can't be read from state, drop it or make the machine report it.
- There are no "collect" objectives. "Fasten 0/4" says what to fetch.
- Step statuses: **Done**, **In progress** (something done), **Ready to start**
  (unblocked, nothing done) and **Locked** (blocked by unfinished work).
  Parallel unblocked steps are shown as Ready to start or In progress.
- Remove the full-screen browser's **Suggested only** filter, **C** build
  cycling and the nested tree. The manual has two levels: chapter → step.
- **Tracked step:** the first unfinished step in chapter order unless the
  player pins another from the manual. Context never switches it. The passive
  carried-part step hint was removed with the 2026-10-26 console cleanup.
- **Out of scope:** location objectives and in-world waypoints (a future
  milestone) and the clevis refusal during foot assembly (de-scoped by the
  user, still recorded in the checklist).

## Physical control guidance — 2026-10-26

The current actionable machine objective supplies a short control note and a
gold glow across its available physical control, smoothly pulsing from dim to
bright over 1.8 seconds. Emission uses the existing bloom settings; the original
control material remains beneath the additive glow. This bounded guidance
covers captive lock pins, each transport-brace handle, grouped jaws/pins/bolts,
rig buttons, crane connectors and the relevant console access point. A grouped
operation cues only unfinished eligible controls. Commands and control IDs are
machine metadata; the renderer never parses instruction text. A console is cued
only when it offers the current operation for the matching machine.

Cues stay within 5 m, the camera view and an unobstructed sightline. They do not
grant reach or bypass prerequisites. Pickup and obstruction outlines have
priority. Completion, undo, restaging, reload, pause and changing the tracked
step clear or refresh the cue. Hiding the manual panel keeps the tracked step.
This is a narrow physical-control exception to the deferred waypoint system.

PV-200's current source puts its gold handle at the cylinder midpoint, including
the mirrored copies. The note therefore says **after fitting both end pins**,
aim **halfway along the cylinder**, rather than claiming the handle is at its
lower end. Detail work must make handle shapes/markings and local access clear.
Automated resolver/lifecycle and sightline tests are mechanical evidence; no
rendered readability or player acceptance is implied.

## Objective operations

| Op | Arguments | Generated text | Done when |
| --- | --- | --- | --- |
| `fit` | `slots`, optional `label` | "Fit FA-514", "Fasten 4 × W-12 + H-12040" | Every slot is filled |
| `seat` | `slot` (an assembly slot) | "Seat the prepared FA-500-P" | The child is mounted in that slot |
| `operate` | `machine`, `command` | The machine's own control or menu label | The machine reaches that command's expected state (below) |
| `connect` | `machine`, `count` | "Attach magnetic connectors 1/2" | That many connectors are attached |
| `detach` | `machine` | "Detach and stow magnetic connectors" | None attached and none in hand |
| `set` | `machine`, `control`, optional `count` | "Close gantry jaws 2/4", "Insert waist pins" | The control(s) are in the stated state |

`fit` objectives within a step are unordered unless the slot `requires`
says otherwise, so valid independent order is preserved. Machine objectives
(`operate`, `connect`, `detach`, `set`) form an ordered sequence.

### Ticking machine sequences

Authors write commands only. Each machine declares, as data, the effect each
command has on a few keys of its existing `capture()` state, plus derived counts
(for example the crane's `attached`). For the crane, `pickup` gives
`task=T, station=source`; `down` gives `raised=false`; `up` gives `raised=true`;
and `go:X` gives `station=X`. The expected state after objective *k* is the
cumulative effect of objectives 1…*k*, checked across **all** involved machines.
The objectives ticked are 1…*k*, where *k* is the **latest** matching prefix. The
crane changes `station` and `raised` only on arrival, so a move in progress keeps
the previous objective ticked. A crane that is raised again steps the list back
cleanly instead of flickering. A `seat` with `via` belongs to the machine sequence
too, but its mounting tick always requires the actual occupied slot. Machine
scope identifies the crane task or the foot/leg rig's receiving build. Delivery
guards distinguish an initial parked crane from a finished trip, and arrival
at a guided receiver from final mounting. This adds no machine flags: everything reads state that `capture()` already
saves (active rule: no new crane-contract flags). The same machine function
supplies both the console menu label and the objective text.

### When a step is done

A step is **done** only when every resolved objective is ticked. Starting the
next page never completes earlier work. Sidebar status and objective rows use
the same evaluation.

Later machine reuse is handled by explicit `completed_by` physical evidence,
authored through `tools/author_manual_progress.py`. Predicates combine `all`/`any`
groups, occupied owner/slot pairs, machine states, and crane task phases
(`arrived`, `delivered`, `released`, `parked`). `requires_state` guards constrain
sequence prefixes; `machine_scope` binds a sequence to its load/build.

Installed parts prove their preceding delivery. A released/parked transport
requires its load still at the receiver or further along its authored route
graph; changing the selected task alone proves nothing. Persistent pins, jaws,
brakes, interlocks and restraints remain required. The next foot's actual
delivery proves that both shared rigs were reset. Explicit later physical
states can supersede temporary support instructions: latched backpack hinges
retire crane tension, and connected services allow the same crane to be
reacquired for closure without reopening the strut step. Missing retention
still reopens work.

These predicates resolve completed objective ticks as well as step status;
historical transport counts are omitted instead of showing Done beside 0/2.
No completion history is stored and the save format is unchanged. When no step
can be tracked, the HUD checks all steps before declaring the robot complete;
otherwise it says work remains and directs the player to the manual.

### Load-time validation

- Every installation slot is covered by exactly one `fit` or `seat` across the
  manual. Summary steps cover none. This replaces the existing coverage audits.
- A step's fit/seat slots equal its `slots` field, so the existing slot-based
  code keeps working during migration.
- No objective precedes a slot it requires.
- Every `operate` command exists on that machine, and every machine has effect
  data for the commands used.
- Completion predicates reference existing slots/machines and valid predicate
  shapes; machine scopes name registered manual machines.
- Text is generated: part names come from the part registry, control labels from
  the machine's `menu_options()` and `controls()` labels.

### The stage progression executes the manual

`build_stages.gd` walks the same objectives: `operate` sends the real command,
while `fit` and `connect` use the existing staging shortcuts (`Staging.fill`,
`supply_rig`). A wrong crane sequence in the manual then fails the routine stage
tests. This proves the machine sequence, not reach, visibility or feel, which
stay the user's playtest.

### When the manual recomputes

Only on change: the build model's `changed` signal, or the equipment registry's
`manual_state_changed`, which it emits after a physics tick in which any machine's
`manual_state()` differs from the previous tick. Several changes in one frame
recompute once at the end of that frame; tracking a step recomputes at once. No
timer polling.

## Data shape

New fields on existing manual pages; `body` is dropped once a page migrates.

```json
{"title": "Deliver the structural shin",
 "goal": "Crane the shin from its rig onto the foot adapter.",
 "slots": ["shin"],
 "objectives": [
   {"op": "operate", "machine": "service_crane", "command": "pickup", "task": "shin"},
   {"op": "operate", "machine": "service_crane", "command": "down"},
   {"op": "connect", "machine": "service_crane", "count": 2},
   {"op": "operate", "machine": "service_crane", "command": "up"},
   {"op": "operate", "machine": "service_crane", "command": "go:receiver"},
   {"op": "seat", "slot": "shin", "via": {"machine": "service_crane", "command": "down"}}],
 "note": {"at": 2, "text": "Keep both connectors attached until the ankle flange is bolted."},
 "view": "components", "diagram_views": ["…unchanged…"]}
```

An objective can name the `diagram_view` it belongs to; the current-step diagram
then follows the current objective. Chapters reuse the stage order in
`build_stages.gd` (`FOOT_STAGES + STAGES`). A child build (the pitch actuator)
is its own chapter, placed before the step that seats it.

## Interface

- **Current step panel** (top-right, replacing the compact manual): chapter ·
  step title, the goal, the checklist with counts and the current objective
  marked, the current objective's note, and a toggleable diagram showing the
  current objective's parts (always shown). Tab hides the panel; it is translucent. Other unblocked steps appear as a short line ("2
  more ready to start").
- **Manual** (M, pauses like now): a chapter list on the left with each step's
  status and "You are here" pinned. The selected step is on the right with a
  larger diagram. Pin a step to track it.
- **Chosen layouts (user, 2026-10-25):** current step panel = diffui panel
  option A (checkbox list, note below the list, diagram expanding beneath it,
  so tall vertical diagrams fit). Manual = diffui manual option C (step status
  as a second line instead of a pill, the diagram boxed beneath the objectives,
  most room for objectives). The diffui project is "Gundam workshop manual";
  local copies are in the gitignored `.diffui/` folder (`panel-a.webp`,
  `manual-c.webp`). The generated objective wording in those images is
  placeholder text, not content.

## Migration

**Repaired; player re-check pending, 2026-10-26:** player reports unclear PV-200 lock-pin
operation, premature Done statuses, unfinished leg resets marked Done and false
robot completion. Source diagnosis and the repair/verification plan are in the
[playtest finding](robot-workshop-playtest-checklist.md#pv-200-and-leg-reset-progression-failures--2026-10-26).
The shared completion rules above replace the premature next-page inference.
PV-200 pages now explain the captive handle at the lock objective and retain
eye-pin insertion direction on the fitting objective. The approved checklist
layout and independent cylinder assembly order are preserved. Automated evidence
is in the linked finding; visibility/reach and player acceptance remain separate.

1. **Engine — done 2026-10-25:** objective schema, generated text, machine
   labels/state/effects/counts (crane, foot rig, heavy module rig) and load-time
   validation (`scripts/manual_objectives.gd`, `manual_objectives_test`).
2. **Pilot content — done 2026-10-25:** heel pads, pitch actuator and foot
   installation; hip assembly delivery (waist pins, crane trip, gantry jaws); the left
   and right leg's new **Deliver the foot** crane step (no page covered that
   trip before), foot docking, crane deliveries and fastening steps. Other pages
   still render `body`.
3. **Interface — done 2026-10-25:** chapters are data (`assets/manual-chapters.json`,
   `scripts/manual_progress.gd`, `manual_progress_test` checks every action page is
   in exactly one chapter). Current step panel (diffui option A) and manual view
   (option C) replace the browser, suggestions, build cycling and parent/child
   navigation (`manual_panel_test`). Z undoes in the aimed build, else the current
   step's. No rendered review has run.
4. **Next:** `build_stages` walks the pilot's objectives (machine `manual_actions`
   for real requests, staging shortcuts for player actions) so stage runs prove
   the manual sequence. Proving it needs the named stage diagnostics, which run
   only on the user's request.
5. **User playtest of the pilot.** Done 2026-10-25: "no notes, perfection"; key changes and the label rule followed. Record results in the
   [checklist](robot-workshop-playtest-checklist.md).
6. **Review of unconverted steps (2026-10-25).** In play order:
   - **Leg docking (hip assembly pages):** rail Advance phases described in prose,
     "neutral lock" jargon for the hip cylinders, and the rig release/return has no
     step (only a summary page). Converting now (leg rig, hip cylinder lock pins).
   - **Chest, core, backpack, arms, pauldrons, head:** every crane page instructs
     task selection that no longer exists ("use Chest to waist", "Select Left arm
     to shoulder", "Select Head baseplate"); the console only offers
     Move/Raise/Lower and picks the next load itself. Mixed names for the same
     part ("lifting shoes", "ends", "magnetic connectors"), button names that don't
     match ("Up", "Down", "Travel"), and world coordinates ("X-9.0, Z1",
     "lowest load is Y19, cross to X13 at Z13"). Heavy module rig insert changes
     ("Select core saddles") need a `template` objective. Machines to wire up:
     core guide, backpack hinge, arm rig, shoulder support, guided receivers,
     joint restraints.
   - **Pitch actuator:** "Put FA-513 in the preparation C fixture" is in the goal
     but not checkable; a station objective could cover it.
7. **Whole robot converted — done 2026-10-25.** Leg docking, chest, core,
   backpack, arms, pauldrons, head and face are objectives; no action step keeps
   prose (`manual_objectives_test` asserts it). New steps cover crane trips that
   had no page: each section to the heavy module rig, the arm rig to the Limb Bay,
   the right arm onto the arm rig, and releasing the leg rig. Machines with the
   manual API: crane, foot rig, heavy module rig, leg rig, hip cylinder lock pins,
   core guide, backpack, shoulders, guided receivers.
   - Rules learnt: commands a guided machine adds to the crane console are
     "Crane console: <verb phrase>" (e.g. "Take backpack weight"); a parked, empty
     crane cannot return to an installed load, so a step that needs the crane again
     ends with `detach` and a note instead of parking; a single connector can be
     released with `detach` + `point`; an `operate` objective may list the slots its
     control fills (captive bolts) instead of a duplicate `fit`.
   - Old prose dropped on purpose: crane routes and coordinates (the console flies
     them), task selection, and fine approach distances that the guided motion now
     handles. Kept as notes where the player must act (insertion side, keep
     connectors attached, lift shelf trips).
8. **Next:** `build_stages` executes the objectives (it still differs for the
   backpack: it parks and sends the crane back with a command the menu never
   offers). Objective-specific diagram views. User playtest of the converted
   chapters.

### First use and repeated procedures — 2026-10-27

Pages may name a `procedure`. The `procedures` registry in manual-chapters supplies
its title, machine IDs and first `[owner, page]`. `bind_procedures` in
`author_manual_progress.py` tags explicitly selected pages and derives the first
page from chapter order. The first page shows all typed objectives; repeats hide
only that procedure's machine objectives and show a working **Procedure: p.N**
link in the current-step HUD and manual browser. Other equipment and hardware stay
explicit. Links open the original tutorial without changing tracked work, model
state, completion evidence, supplies or control cues. Numbering is stable chapter
order, independent of play history. B4 will register the leg procedures; existing
crane instructions are unchanged.
