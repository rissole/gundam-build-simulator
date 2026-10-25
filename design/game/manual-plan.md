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
  player pins another from the manual. Context never switches it. Holding or
  aiming at a part for another step adds a passive hint beside "Carrying…"
  ("For: Ring clevis · Foot").
- **Out of scope:** location objectives and in-world waypoints (a future
  milestone) and the clevis refusal during foot assembly (de-scoped by the
  user, still recorded in the checklist).

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
cumulative effect of objectives 1…*k*. The objectives ticked are 1…*k*, where *k*
is the **latest** objective whose expected state matches the live machine. The
crane changes `station` and `raised` only on arrival, so a move in progress keeps
the previous objective ticked. A crane that is raised again steps the list back
cleanly instead of flickering. A `seat` with `via` belongs to the machine sequence
too. This adds no machine flags: everything reads state that `capture()` already
saves (active rule: no new crane-contract flags). The same machine function
supplies both the console menu label and the objective text.

### When a step is done

Later steps move the machines on, so a finished step's machine sequence stops
matching. A step is **done** when all its `fit`/`seat` objectives are satisfied
and either its machine sequence is complete or the next step (in manual order)
has started. A step has started when any of its objectives is ticked or it is
done. Evaluate from the last step backwards. No completion is stored, so saves
are unaffected.

### Load-time validation

- Every installation slot is covered by exactly one `fit` or `seat` across the
  manual. Summary steps cover none. This replaces the existing coverage audits.
- A step's fit/seat slots equal its `slots` field, so the existing slot-based
  code keeps working during migration.
- No objective precedes a slot it requires.
- Every `operate` command exists on that machine, and every machine has effect
  data for the commands used.
- Text is generated: part names come from the part registry, control labels from
  the machine's `menu_options()` and `controls()` labels.

### The stage progression executes the manual

`build_stages.gd` walks the same objectives: `operate` sends the real command,
while `fit` and `connect` use the existing staging shortcuts (`Staging.fill`,
`supply_rig`). A wrong crane sequence in the manual then fails the routine stage
tests. This proves the machine sequence, not reach, visibility or feel, which
stay the user's playtest.

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
  current objective's parts. Other unblocked steps appear as a short line ("2
  more ready to start").
- **Manual** (N, pauses like now): a chapter list on the left with each step's
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

1. **Engine:** the objective schema, text generation, effect data and
   validation, with an isolated routine test. Pages without `objectives` keep
   rendering `body`.
2. **Pilot content:** the foot, the pitch actuator, and the left leg's shin
   delivery and ankle flange. The current step panel and manual are built from
   the chosen diffui layouts. `build_stages` walks the pilot's objectives.
3. **User playtest of the pilot.** Record the results in the checklist.
4. **Remaining content,** chapter by chapter in the author scripts
   (`tools/author_*.py`), then remove `body`, the browser tree and suggestions.
