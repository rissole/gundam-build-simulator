# Left-leg playtest feedback — task handoffs

Written and implemented 2026-10-26. All nine work orders are integrated; player
recheck remains open.
The user completed the left leg and found the access challenge satisfying in
places. Preserve that physical assembly experience while removing unexplained
targeting failures, accidental loss and automatic support appearances.

[Player findings and decisions](../../robot-workshop-playtest-checklist.md#left-leg-completed--2026-10-26)
are the acceptance record. [Workshop state](../../workshop-state.md) remains the
current project entry point. Read both and repository AGENTS.md before execution.

## Work orders

Each file is a bounded task for one implementation agent. All nine plans are
implemented. The original scopes and human rechecks remain available below.

| Task | Outcome | Coordination |
| --- | --- | --- |
| [01 — Explicit transport braces](01-explicit-transport-braces.md) | Attached ankle/knee braces with local engagement handles and manual steps | Coordinate generator edits with 03; expose control metadata for 08 |
| [02 — Crane retention wording](02-crane-retention-wording.md) | Remove the redundant raw count; retain understandable blocked-action feedback | Independently scoped; inspect recent console work first |
| [03 — Reuse standard hardware](03-reuse-standard-hardware.md) | Merge functionally interchangeable washers and prevent build-specific duplicates | Coordinate generator/data edits with 01 and 05 |
| [04 — Pick up visible part surfaces](04-pickup-surfaces.md) | Pick up PV-120/PV-200 by aiming at visible material | Shared targeting owner; integrate before 09 |
| [05 — Secure bulky shelf cargo](05-shelf-cargo.md) | Store/retrieve PV-120/PV-200 in physically suitable shelf poses | Consume 04 pickup behavior; coordinate collision helpers with 06 |
| [06 — Recover stuck hand loads](06-carry-recovery.md) | Return a badly separated held object to a clear hand pose without losing ownership | Shared carrying owner; integrate before 07 and 09 |
| [07 — Loose cargo rides the deck](07-loose-deck-cargo.md) | Carry resting loose parts through shared equipment motion; stop for real obstacles | Build on 06; coordinate shelf ownership with 05 |
| [08 — Highlight manual controls](08-manual-control-guidance.md) | Current manual action highlights its relevant local control, across machines | Consume 01 control metadata; inspect existing cylinder-note fix |
| [09 — Forgiving connection discovery](09-connection-discovery.md) | Explain blocked targets and tolerate small aim/receiver-proxy errors | After 04; coordinate with 08 presentation and 06 placement checks |

The user subsequently authorized execution. Implementation used isolated agent
worktrees, scoped commits and parent review/integration. Grok 4.7 Fast completed
task 02 through `agent`; Sol 6.1 High handled the complex delegated tasks. The
parent implemented carry recovery and shelf storage and verified the integration.

## Shared execution rules

- Recheck the working tree and recent commits. Other agents have been changing
  the console, manuals and tests. Preserve their work and verify whether any
  requested behavior is already fixed before editing it.
- Use one fresh implementation session and one scoped commit per task. Read this
  index and the numbered work order. Never commit unrelated paths.
- Read `gundam-assembly-review` for build/manual/geometry/support changes. Do not
  expand these local repairs into the component pipeline. Update authoritative
  generators and their generated data together.
- Shared generators, `targeting.gd`, motion helpers, the test inventory and status
  documents need coordinated ownership. Use separate worktrees for concurrent
  tasks; otherwise serialize overlapping edits. The integrating agent reconciles
  shared documents and runs the relevant combined checks.
- Verify through `python3 game/workshop/tools/run_regressions.py --only NAME ...`.
  Select current case names from `test_inventory.py`; classify every new runnable
  suite. Add small isolated reproductions for changed behavior. No expensive
  diagnostics, walked acceptance or rendered review without explicit request.
- The task files name initial relevant suites, not a requirement to repeatedly
  run unrelated passing tests. Routine checks prove behavior, not player approval.
- No new part icons are needed by these plans. If implementation requires new
  icons, follow the project's user-run import rule before doing that work.
- Preserve normal reach, physical support and ownership checks. Changes to
  discovery feedback do not grant placement permission. Carry recovery is an
  explicit accessibility exception to a blocked carry path, not to final placement.
- Update findings with implementation evidence and a short focused human recheck.
  Leave visual/usability acceptance pending until the player supplies it.

## Confirmed design choices

- Braces remain attached, visibly fold/slide into position, and have local handles.
- Loose objects resting on a moving deck ride with it; real obstructions stop it.
  The proposed knock-aside behavior was superseded by this user decision.
- Add a note plus guidance glow for this entire class of manual-directed control
  tasks. The cylinder note may already be handled by another agent; inspect it.
- Reuse existing compatible hardware. A component prefix alone is not a reason
  to create another part type.
- Preserve the enjoyable challenge of reaching and assembling physical interfaces.

## Later detail-pass obligations

The current fixes establish reusable behavior. Later component work must author
credible brace stow/contact geometry, truthful pickup/collision surfaces, usable
shelf orientations, visible local controls and accessible connection targets.
Audit existing hardware before creating a new type. Do not use this pass to add
detailed internals, powered joints, finished brace art or full teardown.
Each task records its own remaining detail obligations, so prototype fixes do
not become accidental final-design approval.

## Implementation evidence — 2026-10-26

| Task | Integrated result | Focused evidence |
| --- | --- | --- |
| 01 | Persistent shin/fork-mounted ankle, knee and beam braces; 12 local handles, guarded sliding, explicit saved locks, supported correction and manual/transport gates | `joint_restraints_test` 305; manual/stage/save checks and startup |
| 02 | Removed raw retention counter; named blocked release/lift instructions retain interlocks | Crane console 9 + policy 23 |
| 03 | Canonical W-24, W-12 and H-12050 types/drawers/stacks; corrected prototype dimensions, preserved physical identities and slot-specific geometry; duplicate-spec audit | Leg content 800, variants 414, model/pocket/content/source/interface checks |
| 04 | Cached mesh-BVH pickup for loose/shelf parts, true surfaces and real gaps, surface reach and occlusion | Pickup surfaces 18; actual aim/E, source variants, gap and wall fixtures |
| 05 | PV-120 upright, PV-200 at 50°; unchanged shelf capacity, captive contact clamps, exact UID store/retrieve | Shelf storage 140, wide elevators 93; real upward/downward trips and capacity rejection |
| 06 | Size-aware separation recovery to one of five clear hand poses; retains held identity, waits if blocked, synchronizes nested physics; floor rescue only for loose builds | Centered carry 14 + nested runtime 37; normal collision/explicit drop remain active |
| 07 | Shared stable-contact loose deck passengers, separate shelf ownership, full cargo obstacle envelopes | Equipment motion 83, mobile platform 132, access lift 45; actual PV-120/PV-200 cargo |
| 08 | Tracked-action note plus nearby unobstructed gold control contours; all current manual machine classes and brace metadata | Guidance 41 + manual panel 11; objective/progress/outline checks |
| 09 | Discover relevant blocked connections; explain compatibility, prerequisites, reach and obstruction; bounded 20 mm aim / 25 mm mesh-verified proxy assistance | Discovery 19, targeting 20, eye-bearing 94; actual click remains physically gated |

The combined routine run selected **45 suites**, completing in **46.473 s**.
It passed 44 and exposed a stale shelf-bounds cache when source mesh dimensions
changed. After correcting the cache key to include current source bounds, stow
basis and collision-profile signature, the affected wide-elevator, shelf and
shared-motion suites all passed (**93 + 140 + 83 checks**, **4.543 s**).
No other implementation changed after the combined run. Local logs:
`game/workshop/verification/regressions-20261026T082439.899650Z/` and
`game/workshop/verification/regressions-20261026T082610.154417Z/`.
Both leg and blockout generator byte-equality audits pass. No diagnostics,
rendered review, walked acceptance or performance measurement ran.

The reported carry loss was not replayed from a player save. Source inspection
found snagged grip motion and an overbroad below-floor assembly rescue; recovery
now preserves identity and the rescue only applies to loose builds. This does
not claim that either mechanism explains every reported loss.

PV-200 geometry locates every lock handle at its midpoint, not its lower end;
the generated note explicitly follows both end pins and describes that midpoint.
No new icons were added. Shelf volume, routes, normal placement reach and true
obstruction rules remain intact. Mobile-platform lane marking and full component
detailing are separate outstanding work.

**Human recheck:** use the nine original work orders' focused rechecks and record
results in the linked playtest record. Preserve the player's positive finding
about physical connection access. Automated checks do not approve appearance,
control readability, walking/reach comfort or the complete workshop journey.
