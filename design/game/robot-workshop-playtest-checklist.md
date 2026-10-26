# Robot workshop playtest

Walk the complete wider workshop yourself. A stage jump only sets the scene.

## Machine operation and gantry access — 2026-10-26

**Player evidence.** The foot building bay matches the vision: bays help build the
part and assist access. The foot rig (dispatch → leg rig), the leg rig (Limb Bay →
hip) and the crane console are unsatisfying because the player just presses Next or
Move until the job is done. The fixed gantry is frustrating at the hip: it feels
asymmetric, and it has small gaps that are easy to fall through. Its fixed rear
catwalks and crosshead mean the robot can never leave through the hangar door.

**Rigs (decided, not yet implemented):** jog buttons held with E while mouselook
stays free; a ghost target with per-axis readouts; interlocks instead of step
order; SEAT within tolerance. The manual teaches each procedure in detail the
first time and gives only the goal plus a procedure link on repeats.
[Operated rigs brief](handoff/operated-machines/B-operated-rigs.md).

**Crane operator view: rejected (2026-10-27).** A top-down CCTV view (WASD strafe,
held approach from a glowing entry point, reshaping spreader) was built on the
unmerged `crane-operator-view` branch. The user playtested it: "crane view is bad
and i wont merge". Reasons (user, 2026-10-27): the camera view was flat and you
couldn't tell what anything was; holding Space did all the interesting work, so it
was no more satisfying than the console; and the workshop's silhouette reads poorly
from above, so a top-down view is unlikely to work at all. The crane keeps its
console. Any future crane redesign must keep the player's own in-world viewpoint and
make them drive the motions rather than hold one key. Auto-attach from the crane
remains a possible later power-up.

**Gantry fixes: accepted (2026-10-27).** Ten fixed plates close the 300 mm
lift-landing slots, eight rails guard the outer hinge-apron edges, and the
lowest-level right wing and rear-leaf guards now mirror the left (the right side
had been a 180° copy). The user: "the gantry changes are good". The 1.55 m opening
between each hip finger and the hip apron is a deliberate robot/leg work opening.

- [x] Lowest-level asymmetry and landing gaps fixed; player-accepted 2026-10-27.
- [x] Crane operator view playtested; rejected 2026-10-27.
- [ ] Leg rig jog slice playtest, before converting the foot rig.
- [x] [Launch cage v2 concept](final-assembly-plan.md#launch-cage-v2-concept--2026-10-27) approved as direction only, 2026-10-27: two mirrored towers, swinging catwalks, independent hip-bearing arms and deferred lowering/transport.
- **Superseded by rope access (2026-10-27):** the branch prototype is integrated, with player checks below. C6 remains a design record.
- **2026-10-27 — C6 design only:** [Aft-tower coarse plan](gantry-v2/README.md) clears the proposed parked exit but retains blocking hip-support/route/headroom overlaps; larger building, carrier-at-current-height and alternate support topology remain open choices. Keep accepted finish, gap/mirror repairs and assembly challenge; no new player acceptance.

**Open choices retained:** whether to redesign the crane (for example, an in-world pendant using the rigs' hold-E jog pattern); rope-access player approval; lowering and roll-out support. The accepted gantry appearance and
physical assembly challenge remain constraints. Parts can continue at the existing
hip datum/Y10.97 bearing caps while these equipment choices wait.

## Left-leg docking renderer errors — 2026-10-27

**Player report:** many `BUG, indexing did not unpair geometries from light.`
errors while docking the left leg, accompanied by substantial lag. The captured
Godot 4.7.2 Metal/Forward+ gameplay log contained 30 occurrences. Earlier positive
leg-performance feedback remains a constraint; it does not dismiss this report.

**Repair:** assembly batching changed live source meshes' render layers to zero,
triggering [Godot issue #121989](https://github.com/godotengine/godot/issues/121989).
The workaround withdraws each affected render instance before changing its mask
and immediately restores its visibility. Node visibility, child outlines, original
meshes and component identities are preserved. Docking/undocking now retains
local render batches and outstanding CPU work across reparenting; it no longer
waits for compilation and discards batches on every tree exit. Final destruction
still joins outstanding work and restores surviving source meshes.

**Evidence:** five focused routine suites pass, 116 checks in 9.697 s, covering
render lifecycle, outlines, nested assemblies, rail endpoints and startup.
`game/workshop/verification/regressions-20261027T111610.647045Z/results.json`.
A separate tiny renderer reproduction on Godot 4.7.2 / Metal / Apple M2 produced
two light-unpair errors with the old mask change and zero errors with the helper.
Script and both logs: `game/workshop/verification/light-unpair-repro/`.
This was an isolated renderer experiment, not a visual review or a full gameplay
performance measurement. No expensive diagnostic suites ran.

- [ ] Restart the game to load the fix, dock and release the left leg, and confirm
  the errors and hitch are gone. Full-scene smoothness still needs this recheck.

## Gantry v2 rope access — 2026-10-27

**Merge into main approved by the user (2026-10-27); detailed rope-access checks remain open.** The prototype replaces
11.2/14/16.4 decks with 20.6 rope access, relocates both lifts and preserves the
8.4 hip working geometry and low hip frame. Rope work, physical upper-leaf controls,
manual cues and crane routes are integrated. [Implementation and mechanical evidence](gantry-v2/overhead-access.md).
No rendered inspection or player acceptance is claimed by the fixture tests.

Keep the accepted finish ("looks great"), gap/mirror repairs ("the gantry changes
are good"), leg-delivery performance and physical assembly challenge. Passing
mechanical tests do not approve the relocated paths or the new rope experience.

**Player finding — walkway posts and floating lights (2026-10-27).** A tall pole
obstructs the route from the workshop-side elevator. Remove that through-post
and make the elevator shaft support that corner; move the opposite post to the
far outer corner. Replace the floating lights between walkways with strips
under the upper walkways. Implemented directly on `gantry-v2`: under-deck shaft
brackets, relocated opposite column, flush hinge bearings and deck-mounted
lighting that follows the leaves. Six selected routine cases pass in 10.803 s;
[geometry and evidence](gantry-v2/overhead-access.md#walkway-support-and-lighting-correction--2026-10-27).
The player responded "Really great!" to this correction; specific rechecks and
the broader rope-access journey remain open.

**Follow-up — plain decks and an upper loop (2026-10-27).** The player still sees
the old pole-shaped cap and four rectangular fillers at the walkway hinge. They
asked to remove that geometry, remove floating rappel instructions because hover
tooltips suffice, and connect the upper walkways into a square perimeter (an
elevator gap is acceptable). Implemented plain landing/leaf plates at both
levels, tooltip-only station labels, and fixed upper side runs with a short
bypass in front of the rear elevator. The existing front leaves still open for
the crane. The new lighting continues beneath the added decks. Six selected
routine cases pass in 12.308 s; player rechecks remain open.
[Layout and mechanical evidence](gantry-v2/overhead-access.md#upper-perimeter-and-deck-cleanup--2026-10-27).

**Player response — "Near perfect" (2026-10-27).** Preserve the upper loop and
plain decks. The player reports flashing/clipping at walkway corners, especially
the upper workshop-side elevator, and requests Q to unclip, removal of the
temporary duplicate clip-in message, and quick held ascent/descent acceleration
with slow taps. Removed the two overlapping rear landing-extension plates,
implemented Q unclip while attached (normal set-down otherwise), kept permanent
rope status without a success toast, and added a 0.6→4.5 m/s ramp over about
0.6 seconds. Five selected routine cases pass in 7.938 s.
[Diagnosis and mechanical evidence](gantry-v2/overhead-access.md#corner-flashing-and-rope-control-follow-up--2026-10-27).

- [ ] Walk over the corners, particularly the workshop-side elevator at both
  heights, and confirm the floor no longer flashes.
- [ ] Clip at a station and a hanging end: only the permanent rope status should
  appear on success. Check that failed operations still explain the problem.
- [ ] Q unclips on a floor without dropping a carried part; G operates the
  pull-in lanyard. Once unclipped, Q still sets down carried parts.
- [ ] Tap Space/Ctrl for small height adjustments, hold for fast travel, reverse
  direction and release. Confirm the ramp and instant stop feel controllable
  near decks, booms and connections.

- [ ] Inspect both hinge landings: plain deck sections, no old pole cap or four
  isolated filler blocks, and a narrow seam into the long leaf.
- [ ] Walk the upper circuit with the front leaves closed, including the turn
  around the rear elevator with its car downstairs. Check joins, guard edges and
  carrying space. With the leaves open, use the fixed route via the rear.
- [ ] Confirm rappel stations have no floating instructions and their existing
  hover tooltips still make clipping and recall clear.

- [ ] Exit the workshop-side elevator at both heights and pass the former pole
  position. Check the opposite corner and that neither support obstructs walking.
- [ ] Inspect the shaft-supported corner and relocated opposite column. Check
  the under-deck strips with the upper leaves closed and open: attached fixtures,
  useful light and no floating remnants between the former levels.
- [ ] Ride both lifts with shelf cargo: east exits at 8.4, then left east/right
  west exits at 20.6. Check calls, labels, doorway nudge, turning space and the
  sliding guide support near the top.
- [ ] Walk the retained 8.4 fingers, outer walks, new fixed hip links and rear
  hip decks. Confirm the left landing joins its outer walk and the offset right
  link reads clearly; recheck the unchanged hip work openings and jaw access.
- [ ] Inspect the 20.6 leaf aprons and rear walkway landing, guard edges, mast/tie
  supports, booms and accepted finish. Level signs should read HIP / ROPE ACCESS.
- [ ] Check clipping, protected gates, recall and the leaf
  interlock, especially adjacent front stations with overlapping openings.
  Confirm the jamb-supported davits allow the intended hang/return movement.
- [ ] Play the front deliveries and restore the leaves
  while the crane holds the part. Head/crown access and both rappel sides need
  real player feedback; automated geometry is not connection-access approval.

- [ ] Use both physical UPPER LEAVES panels beside the left lift (ground and
  fixed upper landing). Aim and press E for OPEN/CLOSE; confirm the panel stays
  clear through the swing. A stopped crane in the crossing holds Close, but a
  crane over the robot permits it. Manual glow leads to Close, then a rope station.

- [ ] Find a station from the tracked manual's control glow. Read **Clip in** and
  **Recall rope** at the gate/reel; E works at normal reach. Unclipped gates block
  passage and only the attached station's gate opens.
- [ ] Step off the front leaf and rear walkway without a fall. Check the rear
  boom's top traverse, return boarding, and the small outward clearance adjustment
  as the capsule passes a front deck edge. Height locks on release; Space rises,
  Ctrl lowers, mouselook remains free, and WASD slack feels useful without swing.
- [ ] G clips a visible nearby robot surface, draws to working distance, and G
  releases toward plumb. Check that collisions feel like resting against the robot.
- [ ] Use normal E/placement and existing hand carrying for hip lifting eyes,
  waist, core, shoulders, pauldrons and head/crown connections. Do not treat the
  automated collision fixture as proof of reach, visibility or connection access.
- [ ] Descend to an 8.4 m deck and ground, unclip with Q, and clip the hanging end
  with E for another ascent. Return to the upper walkway and unclip there.
- [ ] Request leaf motion with a front rope occupied and then free/deployed.
  Read the named recall reason; return through the still-open occupied gate,
  unclip and recall the line. The waiting trip resumes. Rear ropes do not block
  the front leaves. A grounded clipped platform rider must unclip before travel.
- [ ] Save/reload while hanging and pulled in; confirm position, view, locked
  height, line length and lanyard state. Check the HUD line alongside carry/manual UI.
- [ ] Inspect station/gate presentation and crane/rope
  coexistence in the actual layout. Backpack hinge access is still unresolved;
  this work does not choose a solution for that challenge.

**Open choices retained:** backpack hinge access remains the deliberately open
challenge; lowering and final exit are undesigned. Pull-in lanyards remain
accepted as a mechanic. No change here grants acceptance to the wider journey.

### Operated rigs open questions — Phase 1

B1/B2 helpers have isolated mechanical checks; the rigs are not converted and no
new presentation or player acceptance is claimed. The [B3/B5 design](robot-workshop-plan.md#operated-rigs--phase-1-design-2026-10-27)
keeps the accepted foot building bay and physical access challenge. At checkpoint B:

- [ ] Judge initial jog speeds and correction while looking away from the panel;
  constant rates are proposed, a slower final-approach mode remains an option.
- [ ] Choose service taps versus individual arrows for the holder's jaw, lower,
  withdraw, compact and outboard motions. The proposed first slice retains the
  constrained RELEASE/REACQUIRE sequence alongside independently jogged delivery.
- [ ] Review delivery/construction button grouping on the existing panels:
  ROLL/LIFT/BOLSTER in a labelled bank is proposed; no panel relocation is approved.
- [ ] Before B5, confirm the foot's final 1° guide turn (.5 s, green 1.1° capture
  window) versus another lead-in. Preserve its existing sole pivot and support.
- [ ] Check per-axis green marks, signed readouts, ghost pulse and first-use/repeat
  guidance in play. Helper tests establish none of their readability or usability.

## Left leg completed — 2026-10-26

**Player evidence:** the user completed construction of the left leg. Finding
ways to access connections and fit screws was challenging “in a somewhat good
way”. Preserve that physical assembly challenge. This is partial workshop
playtest evidence, not acceptance of the entire robot journey.

The user first requested discrete task plans and subsequently authorized their
implementation. All nine are now integrated; see the
[task index and current mechanical evidence](handoff/left-leg-feedback/README.md#implementation-evidence--2026-10-26).
No rendered review or new player acceptance has been supplied.

| Finding | Scope / implementation | Status |
| --- | --- | --- |
| Supports instantly appear after some completed steps, breaking immersion; engaging them should precede transport. | [01 — Explicit braces](handoff/left-leg-feedback/01-explicit-transport-braces.md): replaced milestone-triggered appearances with persistent attached braces, local engagement and manual/interlock state. | Implemented attached sliders and local handles; player recheck pending |
| “Connection retention” in the crane console is unexplained and appears irrelevant. | [02 — Crane wording](handoff/left-leg-feedback/02-crane-retention-wording.md): the underlying hardware prevents premature crane release. Remove the redundant count and keep actionable blocked-command feedback. | Implemented; release/lift interlocks retained; player recheck pending |
| LG-W24 seems functionally identical to W24; avoid build-specific duplicates and always check existing stock. | [03 — Standard hardware](handoff/left-leg-feedback/03-reuse-standard-hardware.md): compared actual interfaces, corrected prototype discrepancies and pooled proven interchangeable W-24, W-12 and H-12050 copies. | Measured and merged W-24/W-12/H-12050; player recheck pending |
| PV-120 pickup seems to require aiming in its empty gap; PV-200 has the same problem. | [04 — Pickup surfaces](handoff/left-leg-feedback/04-pickup-surfaces.md): use visible part surfaces and faithful shapes for shared pickup targeting. | Implemented; player recheck pending |
| PV-120 cannot be secured to the lift shelf; the same applies to PV-200. | [05 — Shelf cargo](handoff/left-leg-feedback/05-shelf-cargo.md): measure fit and author supported stow orientations with correct capacity and transfer checks. | Implemented; player recheck pending |
| Workaround: drop a part on the lift, press Up, then pick it up to clear the obstruction. Initial suggestion was that the lift knock the part off. | [07 — Deck cargo](handoff/left-leg-feedback/07-loose-deck-cargo.md): carry genuinely resting loose cargo through shared deck motion and include it in the moving envelope. | Implemented “Carry deck parts; stop for obstructions”; knock-aside superseded; player recheck pending |
| Carried parts can catch on the world and be lost; excessive separation should return them to the hands. | [06 — Carry recovery](handoff/left-leg-feedback/06-carry-recovery.md): retain ownership and recover to a clear hand pose, with a bounded fallback if the intended pose is obstructed. | Implemented bounded recovery; original loss not replayed; player recheck pending |
| At least the first cylinder lock-pin step needs “After fitting both end pins, aim at the small gold handle near the cylinder’s lower end”; even the game's author could not find it. A glow may help. | [08 — Manual control guidance](handoff/left-leg-feedback/08-manual-control-guidance.md): verify the note against the actual handle and use a shared current-objective glow for this entire class of control task. | Implemented glow across machine classes; actual handle is at midpoint. The handle-location note was later removed at the user's request (glow carries it); player recheck pending |
| Line of sight feels too strict; sometimes not even a yellow highlight appears and the reason is unclear. | [09 — Connection discovery](handoff/left-leg-feedback/09-connection-discovery.md): improve discovery, bounded surface tolerance and blocked-action explanations while retaining physical placement checks. | Implemented shared discovery/feedback; exact original targets unknown; player recheck pending |

**Detail-pass constraint:** substantial model, part and step detail remains.
The shared handling/guidance repairs are implemented;
preserve obligations for credible brace stow geometry, shelf support, pickup
surfaces, control placement, connection access and catalogue reuse in subsequent
component detailing. Current tests or these task plans do not approve unfinished
presentation. Record positive and negative recheck findings here after each fix.

**Control cue follow-up (2026-10-26):** the user asked for the familiar game
highlight that oscillates from bright to dim. Rejected so far: an additive
full-surface glow (0.35–5× energy; reverted) and a thick pulsing/blooming outline
("looks terrible close and far"). Current version: an alpha-blended gold tint
over the control's own faces pulses smoothly from 12% to 55% on a 1.4-second
cycle, with a fresnel rim so the silhouette reads, plus the original steady
1.25 px gold outline so small parts stay visible at range. Cue range is 10 m
(was 5 m). The pickup/obstruction contour is unchanged. Eligibility, occlusion,
clearing and pickup priority are unchanged. Look up close and far awaits player
recheck; no rendered review requested. Guidance, outline, manual-panel and
startup routines pass (108 checks, 9.457 s; headless, so the shader isn't
compiled there). At the user's request, the generated "Nearby available controls
… glow gold" sentence and the pelvis waist-pin note ("The pins stop the waist
twisting or tilting…", including its pin locations) were removed; other authored
notes remain. Similar notes were also removed: the hip-cylinder note now keeps
only "Keep the leg rig docked and engaged." (handle location and E prompt removed),
and "The leg rig only lets go once all three cylinder lock pins are in." is gone.
Warnings and fitting hints (orientation, insertion side, hardware size) remain. The crane console no longer glows
(crane moves, backpack and shoulder console commands): the user wants the cue
only on small on-rig controls such as pins, and liked it on the crane magnetic
connectors. Rig panel buttons (leg/foot rig NEXT/BACK/BUILD/PARK,
core guide, heavy module rig UP/DOWN and INSERT) no longer glow either: "rig
controls don't get a glow". Glow remains on pins, captive bolts, latches, gantry
jaws, brace handles, receiver handles and crane magnetic connectors.

### Focused left-leg recheck

- [ ] Notice stowed braces on source members, engage both local handles when prompted, transport/dock the leg, and confirm braces remain after rig release.
- [ ] Attempt early crane release, finish the named connection, and release; confirm the new refusal explains what to do.
- [ ] Use standard washer/screw stacks across compatible foot, leg and hip slots.
- [ ] Aim at PV-120/PV-200 material after dropping/rotating; verify gaps and nearby parts do not steal pickup.
- [ ] Store each bulky part, ride either lift, retrieve and fit it; assess the shelf support/clamp appearance.
- [ ] Snag a held part, walk clear and recover it; deliberately drop and re-collect it.
- [ ] Drop cargo on a deck, ride, pick up/drop during travel, and verify a genuine obstacle still pauses/resumes movement.
- [ ] Find a cylinder lock and another machine control from the current-step note/glow, including with the manual hidden.
- [ ] Fasten from imperfect plausible angles; preserve the enjoyable access challenge and record exact targets/positions for confusing failures.

## Gantry jaw hitch — 2026-10-26

- Player reports that opening and closing the hip assembly gantry momentarily
  freezes the whole game. The gantry may be redesigned before launch; avoid a
  deep gantry-specific fix.
- Player also reports severe lag moving the leg into the hip assembly, clarified
  as happening **while moving along the rails**. The separate rail cleanup and
  remaining playtest are recorded below.
- User would accept jaws clipping through obstacles if removing collision checks
  solved the hitch; otherwise prefers the shared performance cleanup. Sweeps
  remain enabled because removing them alone leaves broad physics updates.
- Code inspection found a jaw's three colliders caused all 556 blockout bodies
  to be published each tick, with nine full insert-selection scans and full
  blockout scans for sweep membership. Shared updates now publish only changed
  groups and descendants, skip unchanged insert settings, and index collision
  membership. Crane anchor updates use the same selective path.
- Initial cleanup was code-only. Follow-up isolated headless tests now pass:
  `gantry_dressing_test` (63 checks) and `rail_gates_test` (16 checks), including
  selective updates and same-tick descendant physics poses. No workshop launch,
  rendered review or gameplay timing ran. The hitch's cause and resolution are
  not yet measured; manual refresh at jaw-state changes remains another
  candidate if a start/stop hitch persists.
- [ ] Opening and closing each jaw stays responsive; confirm the hitch is gone.

## Rail travel lag — 2026-10-26

- Player reports severe lag while the loaded leg travels along the rails and
  requests a systemic fix. No approval of subsequent travel smoothness yet.
- Code diagnosis: each tick recollected the leg's complete collision subtree,
  allocated holder boxes for every sampled pose, and rewrote unchanged live
  holder dimensions. A typical 0.25 m straight look-ahead used ten intervals:
  eleven overlap queries and ten casts per shape, despite a straight rigid path.
- Shared `MotionSweep` now accepts explicitly linear groups: two endpoint
  overlaps plus one continuous cast per shape. The rail uses this for straight
  track/index travel; crane loads and hand-carried bodies use it on straight
  segments too. Curves, changing holder dimensions and pose-dependent contact
  exclusions retain sampling. Obstruction results are always queried live.
- Rail load geometry and excluded body IDs are cached together, keyed by payload
  identity and collision revision, with explicit invalidation on model changes,
  commands and restore. Unversioned bodies fall back to live collection. Holder
  query boxes are reused separately from live colliders; unchanged live sizes
  and transforms are not rewritten.
- Mechanical evidence: five isolated headless routine cases pass, **144 checks**
  in 7.936 s: equipment motion (51), centered carrying (8), rail endpoint (6),
  gantry dressing (63), rail gates (16). Coverage includes thin obstacles,
  endpoint overlaps, live waiting/resume, curved paths, contact exclusions,
  changed/disabled/switched payload geometry and query/live shape separation.
  Local evidence: `game/workshop/verification/regressions-20261026T064236.904199Z/`.
  The first run caught a test-local variable redeclaration and sandbox-blocked
  editor-settings writes; the corrected isolated run passed.
- Analytical work reduction: about 21 to 3 queries per shape for clear straight
  travel (630 to 90 for the 30-member holder, plus the payload). This is not a
  measured FPS gain. No full workshop boot, rendered review or expensive
  diagnostics ran; complete-scene performance remains unmeasured.
- [ ] Loaded left and right legs travel smoothly along the rails in normal play.
- [ ] Turning upright, docking, release and empty return remain responsive;
  these articulated phases retain sampled collision checks.

## Leg docking lag — 2026-10-26

- Player reports rail travel and lane changes are now fast, but lag remains
  the first time the gantry opens and during the leg's final ascent into the
  hip assembly. User asked for a systemic fix: the gantry will be rebuilt and
  more moving equipment added.
- Measured (user-authorised, headless CPU only, scratch driver pressing Next
  through live 60 Hz physics from `--stage=left_leg_dock`, per-machine timing):
  - Both stalls were `workshop_access.request_mode()` sweeping the platforms'
    whole travel before moving: 1,006 poses × 54 shapes, ~360–380 ms. It runs
    when travel starts (gantry opens) and again at dock arrival.
  - Turn upright and dock rise: the rail's sampled sweep cost 13.7 ms and
    15.6 ms per tick (169 leg shapes + 30 rig shapes, 8–11 poses, overlap + cast).
- Changes:
  - **User decision:** the gantry's access platforms clip through loose parts
    and players; they no longer sweep for clearance (request or per tick). A
    rider still moves with a deck.
  - Shared `MotionSweep.sweep` bounds each shape over its whole sweep and
    queries once; shapes in clear space skip detailed queries. Reported
    contacts are unchanged. Every sweeping machine benefits without opting in.
  - The loaded leg's dock rise is a straight lift, so its load uses the
    linear path; the telescoping rig stays sampled.
- After (same driver, left and right legs): travel press 384 → 8 ms; arrival
  stall gone; rail tick p50 upright 6.2 ms, dock rise 4.4 ms; travel 2.6 ms.
  The dock-arrival frame remains ~25–36 ms (install, mount, collision rebuild).
  Isolated one-off spikes moved between runs (OS noise). No rendered frame
  timing, windowed run or FPS measurement; rendering cost is not included.
- Routine regressions: 45 cases pass (47.7 s). `wide_access_test` was updated
  for clipping platforms but is a diagnostic and was not run; nor was
  `indexed_leg_rail_test`.
- Observed while measuring, unchanged: lowering a **loaded** leg back out of
  the dock holds on the closed rear deck floor, because Return does not reopen
  the platforms. Players release the rig instead; unclear if reachable.
- **Deferred (user, 2026-10-26: "lets ignore the shoving for now") — machines
  shoving loose parts.** User likes the idea.
  Tradeoffs presented: machines are teleported static bodies today, so true
  shoving needs kinematic bodies with velocity (one shared posing change);
  pinch points against structure/build eject or bury parts; parts can be lost
  in unreachable places (needs a return-home rule); the player is not pushed by
  physics (keep a hold); fitted assemblies should still make machines wait. It
  reverses the 2026-10-25 "pointed at, never pushed" choice and would drop the
  lane-marking condition. Suggested hybrid: push loose parts, hold for player
  and assemblies, skip checks against fixed structure. Not started; the
  2026-10-25 "pointed at, never pushed" rule stays in force.
- **Player acceptance (2026-10-26):** "performance looked good"; the user
  accepted the docking performance fix. No FPS figure was supplied.
- [x] Gantry opening and the final ascent stay smooth in normal play.
- [x] Platforms clipping through parts/players looks acceptable (user, 2026-10-26:
  "gantry parts clipping is fine").

## Progress video feedback — 2026-10-25

- User rejected the foot-rotation film ("it's bad") and requested its deletion
  and a replacement. No specific framing or pacing reason was given. The foot
  preset and its generated captures were removed; earlier mechanical checks did
  not establish that the film was appealing.
- Replacement: final head-crown installation followed by a pullback revealing
  the assembled robot. On 2026-10-25 the user approved the progress films as
  specified in the workshop README: the crown, pelvis and leg edits. That is
  approval of those shot recipes, not a separate notes pass on saved frames and
  not gameplay approval.
- The refreshed local clips and the historical `cebf6b7` before/after leg
  comparison were deleted with the rest of `game/workshop/verification`. They are
  not retained evidence. Re-record from the README when a new copy is needed.

## How to launch

Fresh start, from the repository root. Since 2026-10-24 this begins with the
left foot's heel pads and pitch actuator, built in the hangar:

```sh
./play.command
```

One stage:

```sh
./play.command -- --stage=<stage>
```

Stage preparation is supplied progress and nothing is saved. Wait for the overlay to close before using the controls. Restart re-runs the shortcut.

## Visual uplift spike — 2026-10-25

User direction: the supplied dream reference's warm industrial lighting, cool
fill, atmospheric depth, reflective worn floor and detailed hangar. Preserve the
previous positive approval of the workshop's intermediate brightness and the
manual's readability. Player response on 2026-10-25: "wow, it looks so much
better and runs much more performantly too." This is positive visual and
performance feedback from actual play, without a measured FPS figure or
confirmation of every detailed check below.

The user approved the gantry ("looks great") and requested merging into main.
Use the **main worktree**, `/Users/blakeyboy/gundam-build-simulator`:

```sh
cd /Users/blakeyboy/gundam-build-simulator
./play.command
# Later, to inspect the final-assembly lighting with a robot present:
./play.command -- --stage=complete
```

Main retains its normal save directory. The old spike save remains separately
on disk; the spike worktree is retired. To compare renderer support with the
same materials, use `./play.command --rendering-method gl_compatibility`;
this disables the advanced effects.

Mechanical evidence: startup smoke passes all 28 checks. Player evidence: the
user reports substantially better appearance and performance. No agent rendered
inspection or GPU benchmark ran. [Roadmap assessment and scope](final-assembly-plan.md#visual-uplift-spike--2026-10-25).

- [ ] At the foot preparation bench, can you identify small washers, sockets and magnetic connectors without relying on outlines?
- [ ] Compare the warm floor pools, dark walls and cool roof with the reference. Is the atmosphere welcome, or too dark/washed out?
- [ ] Are the ochre railings, equipment buttons, bay signs and manual text clear at normal viewing distance?
- [ ] Walk and turn while looking at the floor. Check reflection popping at the screen edge, noisy highlights, fog trails and obvious texture repetition.
- [ ] View the gantry from ground level and its working decks. Are the new shadows helpful, or do they obscure connections?
- [ ] Record FPS at the preparation bench and facing the completed robot, using the same display/window conditions as main. Note hitches separately; no 60 FPS claim has been made.

Deferred user proposals, retained for the next decision:

- Previous scope decision: remain on the visual worktree; expand the column study
  into the whole final mech gantry, preserving accurate measurements and blockouts,
  then implement. The [full gantry design](final-assembly-plan.md#full-gantry-detail--2026-10-25)
  is now implemented. No sound or console screens yet. The focused checks below
  remain open; the earlier positive player feedback predates this detail pass.

- ACES/Filmic versus existing AgX; darker ambient/near-black background versus readable working bays; stronger warm beams and cool perimeter fill. This spike keeps AgX and the approved ambient/key/exposure values as its starting point.
- Photo-quality oily concrete, worn yellow paint and matte structural metal. Procedural roughness/normal maps are the first material experiment; authored wear and richer texture sources remain open.
- Decal-projected warning stripes, `02 / FINAL ASSEMBLY` and floor markings. Existing labels/hazard marks remain; route-specific marking and additional decals are deferred.
- One or two modular industrial/hangar/crane kits from Fab, Unity Asset Store or Sketchfab, with FBX/glTF import and incremental visual swaps that preserve gameplay scripts. Supplier, budget, licence, style, dimensions and performance remain to be evaluated.
- AI-assisted UI feedback, levers and procedural cable animation. Preserve current movement, riding and support rules; generic Tween crane motion cannot replace them.
- SubViewport console screens, emissive green/amber buttons, motor hums and mechanical thuds. Trial one screen and spatial audio before a wider UI conversion; camera shake is optional and needs precision-work comfort feedback.
- Proposed timing: lighting today, materials this week, kit replacement next week. Keep the order, but gate each next phase on actual readability/performance and import effort.

## Focused controls check — 2026-10-24

The crane/lift UI revision has **no regression run**, at the user's request.
Rendered UI screenshots were inspected; these steps still need your hands-on check.
Start with `./play.command -- --stage=pelvis` so the crane and lifts are ready.

- [ ] Open the crane with E. Movement should be visible immediately; the manual and pockets should return when you close it. Mouse look must stay fixed while open.
- [ ] The crane shows no load list. Parked and empty, it should name the next pickup and offer **Move to pickup · <place>**. Carrying, it should offer only **Move to delivery** or **Put back**. When the next load is blocked, the panel should say why.
- [ ] Use mouse and ↑/↓ + E/Enter; Tab should reach Close. Q closes; Esc pauses. Check your usual window size.
- [ ] Follow one crane delivery: move to pickup → Lower crane → close and rig → Raise crane → move to receiver → Lower crane. Check blocked-command explanations, fastening, release, and that the next pickup advances to the following load.
- [ ] Board both side elevators. Up and Down should each travel one level and stop automatically. Try top/bottom limits and call the elevator from a landing. Repeat carrying a component and using the shelf.
- [ ] On the mobile platform, press **MOVE**, choose a destination from the menu, and ride it. Try mouse and ↑/↓ + E/Enter. Q/Close must cancel without moving; Esc must pause. Up/Down only change height. Down at ground must not send it to parking. To park, choose **Parking bay** from Move. Try Move while raised and check the explanation.
- [ ] Try a blocked mobile transfer. Clear the obstacle, open **MOVE** and choose **Resume to…**, or choose **Return to…** to reverse along the route. Check the rider and anything carried stay with the deck.
- [ ] Read and target the labelled rail, foot-rig and heavy-module-rig buttons. Confirm neighbouring buttons are distinct and the smaller signs remain legible. Their Stop/recovery controls remain available.

Report confusing wording, missed targets, unexpected motion and positive findings
in the table below. The complete workshop journey remains a separate playtest.

## Full gantry detail — 2026-10-25

Implemented and accepted visually by the user ("looks great"); merged into main.
Individual checks below remain open. Mechanical evidence: 52 geometry/control
checks and 29 startup checks pass in 4.626 s. The actual replacement bounds,
collision identities, moving parents, intermediate folding poses, raised lift
poses and jaw outlines are checked. No rendered inspection or FPS benchmark ran.
Use `./play.command -- --stage=complete` for the complete structure; use normal
progress or a relevant earlier stage to operate the gantry during assembly.

- [ ] From ground level, inspect both foundations and columns. Do recessed anchors, covers, bevels and restrained wear read as fixed machinery? Does the crosshead lettering sit naturally on the face?
- [ ] Ride both elevators and inspect tread contrast, edge strips and level labels; note texture repetition or shimmer. The old 11.2/14/16.4 checks are superseded on gantry v2 by the 8.4/20.6 recheck above.
- [ ] Open/fold access wings, fingers and rear bridge as the build requires. Watch joints and guards for visible clipping, seams or drifting detail through motion.
- [ ] Aim at and operate the four gantry jaw handles. Their shapes, outlines and prompts should remain easy to distinguish from decorative fasteners.
- [ ] Inspect the rear core/backpack opening and aft lifting well. Check that existing approach, connection sight lines and cable routes remain visually understandable.
- [ ] Compare FPS and hitches with the previous visual spike under the same display/window and build conditions. The earlier reported improvement is a constraint, not evidence for this new shader/geometry pass.

## Manual redesign check — 2026-10-25

### PV-200 and leg-reset progression failures — 2026-10-26

**Repair implemented, awaiting player re-check:** shared progression now uses
actual mounted slots, cumulative state across machines, load/build scope and
explicit physical completion evidence. Starting another page cannot complete
an omitted lock or reset. Completed deliveries remain Done after equipment
reuse, and both manual views share the resolved ticks. A blocked manual reports
“Assembly work remains”; robot completion requires every action step Done.
All six PV-200 pages now locate the amber captive handle and say to press E at
the lock objective. Eye-pin insertion directions remain on their fitting line.

Mechanical evidence for this repair:

- All 40 routine suites passed in 43.357 s before the final guided-receiver and
  backpack-reacquisition refinements. Local report:
  `game/workshop/verification/regressions-20261026T073607.440541Z/`.
- After distinguishing crane arrival from guided mounting, manual completion,
  objectives, progress, panel and crane policy passed: five suites, 197 checks,
  8.500 s (`regressions-20261026T073853.121584Z`).
- After preserving the backpack strut step during intentional crane
  reacquisition, completion and objective suites passed: 37 + 109 checks,
  4.115 s (`regressions-20261026T074029.392009Z`). The completion suite includes
  every chapter in a completed-robot state fixture, omitted/undone locks,
  other-leg rig poses, partial resets, subsequent foot delivery, returned stock,
  crane reuse, blocked tracking, core capture/seating and backpack closure.
- The content generator audit and byte comparison pass. Save format and physical
  interaction rules are unchanged. No diagnostics or rendered review ran.

Player re-check: skip one cylinder lock and work on another cylinder; verify
the first stays unfinished in both views. Use the new handle instruction,
complete all locks, then watch each rig reset objective tick only as its work
finishes. Continue into right-foot delivery and docking; confirm completed
left-leg work stays Done and “Robot structure complete” does not appear early.
Handle visibility/reach and the full player journey remain unreviewed.

**Player report:** the PV-200 “Insert lock pin” instruction did not explain how
to operate it. After moving on and completing only the first two objectives for
other cylinders, the sidebar said Done while the detailed lock objective still
said In progress. Finishing the PV-200 installation produced “Robot structure
complete”. Leg reset steps also said Done despite unfinished preparation for the
right leg. These findings block acceptance of manual progression; the earlier
positive response to the checklist layout remains a constraint.

**Original source diagnosis (before the repair):**

- `tools/author_hip_interfaces.py` gives cylinder pages a note only at objective
  1 (eye-pin insertion). Objective 2 is a captive-control operation with no
  location/interaction hint. `scripts/captive_controls.gd` creates a 6 × 2.5 ×
  2.5 cm amber handle beside the cylinder's midpoint. It requires both eye pins
  fitted and the matching leg rig docked and engaged. The intended interaction
  is aim at that handle and press E; no loose lock pin is collected. Actual
  visibility/reach from the player's position has not been established.
- `ManualObjectives.done_states()` accepts all fit/seat objectives plus *any*
  progress on the next page as completion, even with the current machine
  objective unfinished. Starting cylinder 2 can therefore mark cylinder 1 Done
  with its lock still out. Sidebar status uses that inferred completion, while
  objective rows use `evaluate()`'s live ticks, causing the contradiction.
- `evaluate()` overwrites a `seat` objective's actual occupied-slot check with
  the result of its `via` machine sequence. Both leg-docking pages use the same
  foot rig and phases without a build identity. With the foot rig at stop 3,
  the right-foot seat can tick despite its slot being empty. `done_states()`
  then propagates completion backward through “Deliver the foot” and “Release
  the leg rig”, even while right-leg preparation is unfinished. This is a
  source-derived failure path, not a replay of the player's saved state.
- Machine-sequence matching checks only the machine for the current objective,
  then ticks the earlier prefix across all machines. A foot rig already at home
  can tick the preceding leg-rig release and return without those states being
  satisfied. The final Build objective likewise does not require the foot rig's
  home state to match.
- `ManualProgress.tracked()` returns an empty result when only Done/Locked steps
  remain. `HUD._fill_step_panel()` treats that as “Robot structure complete”
  without checking actual completion. A blocked progression can thus display
  success while the robot is unfinished.

**Repair rationale:** keep persistent requirements (mounted child, captive locks and
required reset states) authoritative; scope shared-machine state to the relevant
build and check the cumulative state across machines. Later-page progress alone
must not erase required work. Preserve completed transport history only through
specific downstream evidence, so later crane movement does not reopen genuinely
finished trips. Derive sidebar and objective presentation from consistent
completion semantics, distinguish blocked tracking from robot completion, and
add a lock-specific location/interaction hint. Do not solve this by forcing all
cylinders to be built in order; their independent work is valid.

**Original verification plan:** isolated regressions for skipping a cylinder lock and
starting the next cylinder; a left foot at docking stop with the right-foot slot
empty; each partial reset state with the other rig already home; starting later
work before release finishes; and a manual with unfinished but locked steps.
Also cover genuine completed deliveries after crane reuse and undo/relock.
The existing three manual suites ran before these specific reports: 144
assertions passed, but the runner failed because its launcher could not save
Godot editor settings outside the sandbox. They do not cover the failure paths
above. Local evidence: `game/workshop/verification/regressions-20261026T070844.281111Z/`.
No additional tests, diagnostics, gameplay replay or rendered review ran during
that source diagnosis. The implementation evidence above supersedes its testing
status; player re-check remains pending.

Mechanical checks only: no rendered review. Start with `./play.command` (fresh
workshop) and later `./play.command -- --stage=pelvis`.

- [ ] The top-right panel reads like a short task: chapter · step, one-sentence goal, checklist. Is it brain-off scannable? Is anything missing that the old prose told you?
- [ ] Items tick themselves as you work (fit counts like 2/4, crane steps as the crane arrives). Nothing should flicker while a machine is moving; raising a load back up should un-tick cleanly.
- [ ] The note appears only for the current item. Do the notes carry the safety details you need (bolt direction, keep connectors attached)?
- [ ] Tab hides/shows the panel; the diagram is always shown. Is the translucent panel readable over the bright bays? Is the diagram size right for tall parts?
- [ ] M opens the manual. Can you tell at a glance where you are? Do Done / In progress / Ready to start / Locked match reality? Enter on another step tracks it.
- [ ] Holding a part shows "For: <step> · <chapter>". Useful or noise?
- [ ] Hip assembly delivery (`--stage=pelvis` is past it; start fresh or after the foot): pins, crane trip and gantry jaws are each a checklist item.
- [ ] Left leg: **Deliver the foot** is a new crane step before docking. Then docking, shin, flange (release and park), fork, axle, beam.
- [ ] Z undoes in the build you aim at, otherwise in the current step's build.
- [ ] Steps not yet converted still show prose. Note the worst ones to convert next.

## Stages

| Command | What to try | What to watch for |
| --- | --- | --- |
| `./play.command` (Left-foot heel pads) | Collect pad hardware from the rear-wall cabinets, build both pads at the preparation stations, carry them to the foot bay and fit them. Turn the fixture with its controls. | Cabinet and station walking distances; reaching both heel seats at the raised store height; the fixture platform and controls beside the store |
| `./play.command -- --stage=actuator` (Left-foot pitch actuator) | Build the actuator at preparation C, fit it and the foot's ring hardware, then set the foot upright. | Upper fasteners from the access platform; the turned poses near the right foot store; crane rigging refused until the foot is upright |
| `./play.command -- --stage=pelvis` (Hip assembly delivery) | Rig the hip assembly, deliver it, close the gantry hold-downs and set the waist locks before crane release. | Fixture clearance, crane-end reach, hold-down handles. |
| `./play.command -- --stage=left_leg_build` (Left-leg construction) | Seat the foot, then crane and fasten the shin, knee fork and upper-leg beam. | Cradle access, console use, fastening reach. |
| `./play.command -- --stage=left_leg_dock` (Left-leg docking) | Travel, stand and dock the leg; finish hip retention and locks; return the empty holder. | Support through the move, hip reach, empty-return path. |
| `./play.command -- --stage=right_leg_build` (Right-leg construction) | Build the right leg on the returned holder, knee axle outward. | Clearance beside the docked left leg. |
| `./play.command -- --stage=right_leg_dock` (Right-leg docking) | Dock the right leg beside the left and return the empty holder. | Side-by-side hip access. |
| `./play.command -- --stage=chest` (Chest delivery) | Deliver the upright chest, fit four waist bolt pairs, release the rig and connect the side services. | Waist reach and service-lead access. |
| `./play.command -- --stage=core` (Core delivery) | Follow the rear route, capture the guide, fit the flange bolts and connect the rear interface. | Rear walking space and connection visibility. |
| `./play.command -- --stage=backpack` (Backpack delivery) | Deliver it open, pin the hinges and struts, connect services, then close and latch under crane support. | Hinge reach, latches, crane reacquisition. |
| `./play.command -- --stage=left_arm` (Left-arm delivery) | Bring the cassette to the station, rig the arm and run the seat route, then retain and connect it. | Cassette boarding, four-end rig, shoulder reach. |
| `./play.command -- --stage=right_arm` (Right-arm delivery) | Transfer the right arm from its store onto the cleared cassette and seat it. | Store pickup and the opposite shoulder approach. |
| `./play.command -- --stage=pauldrons` (Pauldron fitting) | Fit both pauldrons and their shelf-carried panels, then release the local restraints. | Panel carry and how close each pauldron sits. |
| `./play.command -- --stage=head` (Head fitting) | Crane on the baseplate, sides and top; retain them and connect the central loom. | Fixture transfers, loom reach, rig stow. |
| `./play.command -- --stage=head_sensors` (Head sensor fitting) | Fit the sensor carrier, faceplate and hooked mask; connect sensor power and data; then crane on the crown. | Shelf fit, hook and bolt reach, crown keys, camera sight lines. |
| `./play.command -- --stage=complete` (Robot structure complete) | Walk the retained, connected robot with the crane parked. | Anything that still blocks access. |

## Checks

- [ ] Walking and elevator boarding at every level.
- [ ] Connection visibility, reach and tool approach.
- [ ] Rigging attachment and release.
- [ ] Carrying and shelves.
- [ ] Equipment controls (crane console, lift Up/Down, mobile dock selection, labelled local buttons, locks and latches).
- [ ] Overall flow and the manual's suggested order.

The right elevator's local button panel moved to the opposite front corner.
The shelves were enlarged for the mask.
The pauldron route's tightest clearance is about 1 mm at seating.

## Findings

| Date | Stage | Issue or positive finding | Severity |
| --- | --- | --- | --- |
| 2026-10-27 | Elevators | User requests landing CALL buttons to bring the car within about one second and decelerate on arrival, with Up/Down unchanged. Implemented 0.9-second cubic ease-out for calls; onboard travel stays 0.75 m/s. Follow-up: CALL interrupts an active trip at its current height and starts a fresh call to that landing, including during another call. Obstructions still hold and resume the trip. **Player accepts the feel:** "it feels really good." Specific landings, interruption cases and ordinary Up/Down rides were not separately reported. Review found an optional internal-action validation cleanup and a coverage opportunity for a full-height fast call with loose deck cargo; the user requested no code changes based on that assessment. | Accepted; detailed checks remain open |
| 2026-10-25 | Launch (visual worktree) | User asks to stop the pause menu appearing at startup. Implemented direct entry for fresh/restored launches and successful stage handover; Escape still opens/closes pause. Mechanical startup and stage checks pass; player should check a normal launch, a stage launch and Escape. | Fixed, re-check |
| 2026-10-25 | Visual uplift spike | "wow, it looks so much better and runs much more performantly too." Preserve this lighting/material direction. Reported improvement is player evidence; FPS, tested stage and individual readability checks were not specified. User asks what comes next; proposed next work is integration of this baseline followed by one bay's surface and equipment detail, then sound and a single console screen trial. | Positive |
| 2026-10-25 | Any (workshop save) | Asked for Save & quit, Quit without saving, and the player position kept. Implemented: saving is manual (pause-menu Save, Save & quit, or closing the window), Quit without saving confirms unsaved build changes, and position and view are restored. The user disliked refused saves: a mid-ride save now reloads the player on the deck at the machine's last stop; a crane caught mid-move is saved stopped where it is with its load hanging, and Resume continues. Re-check: walk somewhere, Save & quit, relaunch; save mid-lift; save with a load on the moving crane and press Resume after reloading; then fit a part and Quit without saving. | Request |
| 2026-10-25 | Any (manual) | Positive: "I love this new manual — no notes, perfection." Requested: M opens the manual (was N), Tab hides the panel, the diagram is always shown, translucent panel. Done. | Positive |
| 2026-10-25 | Hip assembly delivery | "Insert both pins" appeared in the world as "Engage/Unlock waist yaw neutral pin", which made no sense to the player. From the hip assembly design: the waist has a twist (yaw) joint and a tilt (lean) joint, both unpowered during assembly; each captive pin holds its joint straight so the waist cannot twist or tilt while the hip assembly hangs from the crane and while the chest seats. Now "Waist: Insert twist lock pin" / "tilt lock pin" in the world and "Waist: Insert both lock pins" with a note in the manual. | Fixed, re-check |
| 2026-10-25 | Hip assembly delivery (crane) | The manual said only "Move to pickup" and the console said "Move to pickup · Heavy Module Bay". Fixed systemically: every machine line is "<Where>: <exact control text>" from one label function per machine, the console shows "Move to Heavy Module Bay" (pickup or delivery is implied by the load), and the manual says "Crane console: Move to Heavy Module Bay". Foot rig prompts now match their NEXT/STOP/BACK buttons. | Fixed, re-check |
| 2026-10-25 | Foot (pitch actuator) | Positive: building the actuator feels good. Keep its pace and part handling when the manual is redesigned. | Positive |
| 2026-10-25 | Any (manual) | Step text is too long. The user wants a one- or two-sentence goal and a checklist they can act on without thinking. Crane and between-machine steps fail most: the prose sequence is hard to follow and can disagree with the real controls. The full-screen browser, Suggested only and the nested tree make it hard to know where you are. Redesign agreed: [manual plan](manual-plan.md). | Request |
| 2026-10-25 | Foot (actuator into foot) | The clevis step order sent the player to fit the clevis that was refused first. De-scoped by the user for now; not investigated. Both FA-220 clevises are separate variants (`fa-220__001` cradle, `fa-220__002` ring) with no prerequisite between them. | Deferred |
| 2026-10-24 | Any (mobile work platform) | Couldn't stay on the work platform while it moved between docks. Fixed: riding is now shared by every moving platform, hand load included. Re-check by riding it. | Blocking |
| 2026-10-25 | Hip assembly delivery | No manual step told the player to insert the waist pins. The delivery page said "engage the captive yaw and lean locks," and Suggested only hides that overview. The pins are the two controls on the hip assembly; the crane will not lift until both are in. The page now says to aim at each pin and press E. It still does not appear while Suggested only is on. | Blocking |
| 2026-10-25 | Hip assembly delivery | The four gantry hold-down grips could not be seen from the rear deck. Each grip was a 12 cm block centred inside its post, so one grip hid the other, and the Use prompt never appeared because the aim point was inside that solid. The forward grip now sticks outboard of the post and the rear grip reaches back toward the deck; aiming at the grip shows Close gantry hold-down jaw. Re-check from the 8.4 m rear hip deck before detaching the crane. | Blocking |

Mechanical test passes are separate from these playtest results.
