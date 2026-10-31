# Robot workshop playtest

Walk the complete wider workshop yourself. A stage jump only sets the scene.

## Control cues through models — 2026-10-31

- [x] **Player rule:** the glowing "use machine" steps follow the same rules as
  the held-part destination glow: infinite distance and through models.
- [x] **Change:** the gold control cue lost its 10 m range and sightline checks;
  its pulsing tint draws without a depth test. Offscreen controls stay uncued so
  the eight cue slots go to visible ones. The thin contour keeps its depth test
  (an inverted hull without one fills the silhouette), so it shows only in plain
  view. Rope stations cued for the work follow the same rule; which ropes
  are cued is unchanged.
- [x] **Automated:** `manual_control_guidance_test` (57 checks) now expects a cue
  200 m away and behind a real obstruction; six other affected routine suites
  pass. No rendered review.
- [ ] Through-model gold cues stay readable next to the amber part glow and are
  not mistaken for "operable from here". E still needs reach and sight.
- [ ] Open, shared with the part glow: fade or stop beyond some distance?

## Aim point audit — 2026-10-31

- [x] **Request:** "build that audit as one of the expensive tests that i only
  run after major changes", after the strut finding below.
- [x] **Built:** diagnostic `aim_point_audit_test`; method and scope in
  [TESTING.md](../../game/workshop/tests/TESTING.md#aim-point-audit). With the
  strut fix temporarily undone it fails both Extend controls (3 of 513
  viewpoints), matching the headless probe.
- [ ] **First run, 308 targets: 74 buried (fail), 10 narrow.** Not confirmed in
  game; no player has fitted these yet. Each buried aim point sits inside a
  fitted part or behind a shell, the hinge-pin and strut signature:
  - Both arms, 27 connections per side: ring_front/rear (inside the ball
    beam), ring washers and bolts (inside SH-RING-FRONT/REAR), brace, brace pins
    and keepers (inside SH-BRACE), drive pins and keepers (inside SH-DRIVE, behind
    CH-*-DRIVE-BRIDGE). Seen from 0–4 of about 450 viewpoints.
  - Pauldron bolts 1–4 each side (inside or behind the arm ball beam and pauldron
    shell), 0–10 of about 430.
  - Head: M24×160 ×4 and M12×100 /001, /003 behind the baseplate; M12×160 ×4
    behind the head top; sensor M10×160 ×2 behind the mask. 0–8 of about 450.
- [ ] **Narrow, review:** chest services 1–2 (PV-320 shell, 10%); arm drive_1_b
  keepers (11%); head M12×100 /002, /004 (6%).
- [x] **Backpack lower latches and service covers (narrow, about 11%):** aim
  point inside their own lever or cover, the strut family. Fixed the same way
  (own body see-through). Probe on the closed pack: latches 493/500 and 482/491,
  covers 464/475 and 460/472; the rest is the chest frame. 4 routine suites pass;
  the audit itself was not rerun.
- [ ] In game: close the backpack, engage both lower latches, close both service
  covers.
- [ ] **Not audit-caused:** the shared sequence stops in head sensor fitting
  (`service_crane up` waits for "wing left 20 6 floorSolid"). Plain
  `run_to("complete")` stops at the same point, so the crown and `complete`
  stage are unaudited until it is fixed.
- [ ] **Unmatched:** `left_lift ground` has no control under that action name.

## Backpack struts would not extend — 2026-10-31

- [x] **Finding:** "I can't seem to extend the backpack struts, I think they are
  within geometry. This is a common problem."
- [x] **Cause:** each strut's Extend control aimed at the centre of its own
  handle eye, and the stowed handle sits against the backpack shell and frame.
  The sight check counted both as obstructions. A headless probe saw Extend from
  3 and 6 of about 600 clear viewpoints within 2.2 m, and the strut locks from
  about 35 of 600. Same family as the foot support (e012430) and the hinge pins
  above: an aim point buried in its own model.
- [x] **Change:** strut handles and strut locks treat the backpack body as their
  own, like gantry jaws, cassette clamps and joint restraints
  (`allowed` + `allow_body_hit`). Same probe after: all clear viewpoints see
  Extend and the locks. When extended, Retract is visible from about 45%; the
  rest is the chest clevis around the eye, as intended. Rope prediction now uses
  the operate check's `allow_body_hit` instead of a separate `sight_self` flag,
  so ropes predict service for these controls.
- [x] **Automated:** 7 affected routine suites pass. A new check in the
  diagnostic `backpack_delivery_test` aims at each Extend handle from the outer
  rear rope position. **Not run** (diagnostics need an explicit request).
- [ ] **Tradeoff:** the backpack's own shell no longer hides these controls, so
  they can be operated through it from the inboard side.
- [ ] In game: hang from an outer rear rope beside the open backpack, extend
  both struts, pin them and lock them open.
- [ ] **Open:** the lower latch controls were not probed (they need the closed
  pose). A general audit of control aim points would catch the next case early.

## Backpack hinge pins obstructed — 2026-10-31

- [x] **Finding:** "the first bolts and washers for the backpack seem
  uninstallable, just get constant 'obstructed' error" (Retain both backpack
  hinges).
- [x] **Cause:** each 60 mm hinge pin aimed at the centre of its shank, inside the
  open backpack's hinge eye. That eye's collision belongs to the backpack, not the
  receiving chest, so the sight check failed from almost every side. A headless
  probe saw the target from 40 of 1,100 clear viewpoints within 2.2 m, and no rope
  predicted service, so none glowed. The 40 mm strut pins had the same defect
  (32 of 1,136).
- [x] **Change:** all four pins aim at their exposed outboard head
  (`target_offset` in `tools/author_backpack.py`), like bolt heads elsewhere.
  Same probe after: hinge pins 649 of 1,107, strut pins 819 of 1,140. The outer
  rear ropes (X11.0 left, X15.0 right) now predict service for the pins. Keeper
  targets are unchanged; they were already exposed on their inboard side.
- [x] **Automated:** 14 affected routine suites pass; the generator byte check
  passes. A new check in the diagnostic `backpack_delivery_test` aims at each pin
  through the real targeting path from the outer rear rope's hanging position.
  **Not run** (diagnostics need an explicit request).
- [ ] **Open, access design:** keepers sit on the inboard pin ends. The probe found
  them visible crouched at the front edge of the open backpack's top (about
  1.8 m), but from no hanging rope pose, so no rope glows for them. Backpack hinge
  access remains the [open challenge](gantry-v2/overhead-access.md#decisions-and-open-items-user-2026-10-27).
- [ ] In game: hang beside the open backpack from an outer rear rope, near hinge
  height, and fit each hinge pin; then fit its keeper. Note where the keeper
  could be reached from.

## Pockets not saved — 2026-10-31

- [x] **Finding:** "Saving doesn't remember your pockets." Pockets had been
  reset on load since the 2026-10-25 save design, alongside hands and loose parts.
- [x] **Change:** saves keep every pocket stack and the selected pocket; filling
  or emptying a pocket is an unsaved change, so Quit without saving warns.
  Held and loose parts still go back to their drawers.
- [x] **Automated:** `save_roundtrip_test` stocks a pocket before saving and
  checks the reload keeps its type, count and selection (34 checks pass);
  `rope_access_test` passes.
- [x] **Player approved** the change before an in-game recheck.
- [ ] In game: fill pockets, Save & quit, relaunch; the same stacks are there.

## Held-part destination glow — 2026-10-31

**Player request:** when holding the correct part for the next manual step, always
glow where it goes, through walls and geometry, so the player can find it.

**Implemented:** while the held or selected-pocket part matches the tracked step's
current objective, every empty destination that the recipe would accept now shows
the part's ghost with a soft amber pulse (1.4 s, fresnel rim, no depth test).
That covers fit slots, hand-seated assembly mounts and, when holding the step's
own build, the nearest free preparation station large enough for it.
Machine-guided seats keep their control cues instead. Reach, sightline and access
are not checked for the glow; clicking still checks them. Aiming at the
connection replaces the pulse with the usual steady snap preview (green ready /
amber distant). `manual_placement_guidance_test` (16 checks) plus six affected
routine suites pass; a headless probe on the real heel-pad step showed the station
glow, then four sleeve glows. No rendered review.

**Player feedback, same day:** the first version pulsed green at any distance and
through obstructions, but green must mean a left click will place the part. The pulse
is now amber (the existing "not placeable yet" preview colour). Green appears only
from the aimed snap preview, which already requires reach, a visible connection,
access and recipe order: the checks the click runs. **Player approved** the
amber/green revision (2026-10-31).

**Recheck:**
- [ ] Green appears only when left click places the part; amber everywhere else.
- [ ] The glow is easy to spot through the gantry, rig and walls without becoming noise.
- [ ] The amber pulse reads as "goes here", distinct from the steady amber/green snap preview and the gold control cues.
- [ ] Large bolt sets (4+ glows) and whole-assembly ghosts are not overwhelming.
- [ ] Open: should the glow fade or stop beyond some distance, or when the part is already in reach?

## Manual regresses after core rig delivery — 2026-10-31

**Player report:** after lowering the core onto the heavy module rig and
detaching the magnetic connectors, the current step jumps back to objective 2
(crane pickup) as if the trip had not started. The player sees this as a
systemic problem with manual progression.

**Source diagnosis:** on "Bring the core to the heavy module rig", the detach, up
and go:park objectives carry `requires_state` for crane task `core` (the next
trip, to the chest) instead of `core_store`. That guard can never pass during this
trip. Detaching also breaks the earlier prefixes (they expect connectors attached),
so `evaluate()` falls back to the last prefix that still matches: the untouched rig
inserts. Cause: `author_core.py` shared one `park` objective list between this page and
"Retain and connect the core", and `bind()` wrote the later page's guards into it.

**Repaired; player approved 2026-10-31:** each page builds its own park objectives;
authoring rejects reused objective dicts; load validation rejects a crane guard
outside the page's crane scope; the new routine `manual_walk_test` walks every
action step forwards (fails on the old data with "current is 2", as reported).
All 54 routine cases pass (59.1 s). User declined a runtime hold-progress safety
net for now so this class of bug stays visible. Recheck: lower the core on the
heavy module rig, detach both connectors; the step should advance to raising.
Player approved the repair.

## Recheck sweep passed — 2026-10-31

Player reports all outstanding rechecks passed: focused left-leg recheck, gantry v2
rope access (corners, movement feel), boarding ramp and moving-platform flicker,
free platform driving/nudging, left-leg docking smoothness and the coplanar
geometry repair. Open-ended detail items in those sections are superseded by this
pass. **Still open:** the player finds the crane and the rigs "not great"; a full
playthrough follows to pin down why. Record those findings in a new section.

## Jumping on the elevators — 2026-10-30

- Player request: “you simply must be able to jump while on the elevators, my
  players need to stim!”
- **Player verified (2026-10-30):** “good job, verified.”
- Diagnosis: Space already jumped (~0.97 m), but the rider check reached only
  0.6 m above a deck. Near each apex the left/right lift lost its rider, saw the
  player in its shaft and held with “Step back out of the lift doorway.” A probe
  of repeated jumps on a 4 s onboard ride covered 1.16 m instead of 3 m.
- Fix: the shared rider check now reaches 1.05 m, a full jump plus margin. It applies to every carrier:
  lifts, the scissor platform and gantry decks. A lift also reserves the jumping
  rider's current height above the deck in its overhead sweep, so it waits
  rather than carry an airborne head into a solid (relevant for fast calls).
- Evidence: real-workshop probe (both lifts; onboard up/down and calls) shows
  no holds and on-time arrivals while jumping repeatedly. `access_lift_test`
  gains two checks; each fails on the old code. Eight affected routine suites
  pass (740 checks). No rendered review.
- [x] Spam-jump on both lifts riding up, down and on a landing call: the car
  never pauses or shows a waiting message, and landings feel natural.
- [x] Jumping near the top stop under the crane bridge: any brief hold reads
  sensibly, or say if it should behave differently. Player: “it's fine” — keep
  the brief hold and the existing waiting message.

## Rope swinging — 2026-10-30

**Player accepted (2026-10-30):** “it feels good” after the hold retune, then
“love it” after the 1.5 m cap. Open items below are optional detail checks.

**Player decision:** “I dont like the lanyard thing. Very unintuitive, and just
another keybind. I'd rather swinging mechanic, so you can build momentum to get
to hard to reach places.” This reverses the 2026-10-27 lanyard acceptance.

**Implemented:** the lanyard, its visual, G binding/help and saved fields are
removed. Below the boarding clearance, WASD pumps a pendulum relative to the
camera's horizontal facing, with free mouse look, arc motion and overshoot.
Holding into a contacted surface braces at zero velocity for ordinary E/click
work; releasing returns toward plumb. The same capsule/world mask resolves
contact with no bounce. Space/Ctrl retain precise taps and accelerating holds,
changing radius along the current angle. Top boarding, the front outward bias,
deck landings, grounded 0.35 m slack and hanging/platform interlocks remain.
Pause/modal input freezes motion. Snapshot v2 restores the position at rest,
without velocity or a saved brace; old saves are invalid, with no migration.

**Tuning:** restoring coefficient **24/9 s⁻²** (effective gravity scales with
length, giving a **3.85 s** period instead of a sluggish long-rope swing);
tangential pump **1.3 m/s²** (retuned from 2.8, see below); input damping **0.1 s⁻¹** (from 0.45), released damping
**2.8 s⁻¹**. Lighter damping while pumping builds momentum; stronger released
damping permits a prompt return. Offset cap **1.5 m** (was 2.5 m; see the second retune below), also limited to **60°** on
short lines so the bob stays below the anchor. Maximum physics step **1/120 s**;
boarding clearance **1.9 m** below deck.

**Player feedback (same day):** “rappelling feels good without the lanyard. i
think the swinging is slightly too much: if I hold S, i shouldnt be able to go the
full 2.4m just hovering along. it should take a swing to reach max distance.”
Cause: a held key is a constant push, which shifts the pendulum's rest point to
pump ÷ restore (1.05 m) and lightly damped overshoot doubled it. Retuned so a held
key only leans about 0.5 m and range needs pumping in time with the swing. In the
nine-metre fixture, holding one key from rest peaks at **0.93 m** in six seconds;
pumping with motion-following reversals reaches the cap at **5.72 s** (about 1.5
swings of the 3.85 s period); after four released seconds the offset is
**0.010 m**. All 53 routine cases pass (139 rope checks).

**Second retune (player):** “it feels good, just reduce maximum swing distance by
like 40%.” Cap **2.5 → 1.5 m**. Pumping now reaches the cap at **3.45 s**, about one
swing; holding one key still peaks at 0.93 m. Re-measured serving ropes on a
converted copy of the player's backup save: washer/bolt 1 — front 10.8, front 15.2,
rear 13.6; 2 — front 10.8, rear 12.4, rear 13.6; 3 — front 10.8, front 15.2, rear
12.4; 4 — front 15.2, rear 12.4, rear 13.6. The four centre front ropes stay
uncued. All 53 routine cases pass (139 rope checks).

**Measured cue sets (2.5 m cap, superseded by the second retune above):** on a disposable copy of the player's seated-chest save,
with waist hardware returned to stock in that copy. Only the copy's rope schema
was adapted for the measurement fixture; the live save was never loaded or
written and its SHA-256 was unchanged. The probe was deleted afterwards.
Cues use normal **2.35 m** reach and the shared sight check, from plumb or a
capsule sweep stopped at a braceable surface within the cap. Empty-air extremes
do not qualify. The per-point cache and one-new-prediction-per-frame budget
remain; there are no station/part/recipe lists.

| Waist washer | World point (m) | Serving station IDs |
| --- | --- | --- |
| 1 | (12.16, 12.803, 25.42) | `front_l_9.3`, `front_l_10.8`, `front_r_15.2`, `rear_13.6` |
| 2 | (12.16, 12.803, 26.58) | `front_l_10.8`, `rear_12.4`, `rear_13.6`, `rear_15.0` |
| 3 | (13.84, 12.803, 25.42) | `front_l_10.8`, `front_r_15.2`, `front_r_16.7`, `rear_12.4` |
| 4 | (13.84, 12.803, 26.58) | `front_r_15.2`, `rear_11.0`, `rear_12.4`, `rear_13.6` |

The four centre front ropes (11.9, 12.6, 13.4, 14.1) remain uncued: their plumb
capsules stop at feet **14.88–15.95 m** on the chest shoulders. Other front lines
reach about **8.34–8.39 m**; rear lines reach **9.30–10.94 m**. These numerical
cue results are not walking, visibility or player acceptance. Local evidence:
`game/workshop/verification/rope-swing-stations.json` and
`game/workshop/verification/rope-swing-probe.log`.

**Automated evidence:** `python3 game/workshop/tools/run_regressions.py` reports
`REGRESSIONS PASS 53 cases; inputs unchanged=True`, **54.383 s**, below the
60-second warning budget. The isolated rope suite passes **138 checks** covering
pumping/cap/settling (retuned values above), long lines, collision/bracing and E work, length changes,
pause/modals, save/restore, deck landings and cue obstruction/budget behavior.
Local report:
`game/workshop/verification/regressions-20261030T074021.624268Z/results.json`.
No diagnostics or rendered review; player acceptance remains open. The coordinator reviews/commits this
uncommitted implementation; the existing cue, auto-stow, Q/drop and per-corner
crane-release work is retained.

- [ ] Pump with WASD relative to the view; reverse with the motion to build useful
      momentum. Check the feel of reaching the cap in about 5–6 seconds (retuned).
- [ ] Retune: holding one key only leans (~0.5–0.9 m); reaching the 1.5 m cap takes
      about one pumped swing.
- [ ] Release input: the return, overshoot and 3–4 second settling feel comfortable.
- [ ] Swing into structure and keep holding toward it: the working pose stays
      pinned while aiming, selecting and fitting parts. Release swings away.
- [ ] At each waist corner, use a listed serving rope, swing/brace and place the
      washer and bolt without timing a passing extreme. The four centre ropes
      stay uncued; only still-open connections influence the glow.
- [ ] Robot, gantry and guard contacts stop the capsule without clipping or bounce;
      swing and change length near surfaces, deck landings and boarding passages.
- [ ] Space/Ctrl taps remain precise and holds accelerate mid-swing; mouse look
      stays free, pause/manual modals freeze motion, and hanging never rides a lift.
- [ ] Save while offset/braced, restore at that position at rest, then resume the
      swing. Confirm old-save invalidation is expected for this version.

## Chest waist hardware and rope cues — 2026-10-30

**Player finding:** the chest's four CH-W36 waist washers seemed impossible to
fit; the prompt always said “approach its exposed side”. Standing on the waist
beams (~10.9 m) puts the eye ~0.2 m below the flange top where the washers sit
(12.8 m), so they are hidden from every standable spot. Rope access works, but
the manual glowed **every** rope station within ~4 m. The four centre front
ropes stop on the chest shoulders at ~15–16 m, and the outer rear ropes cannot
see their corners even with pull-in. The upper gantry was also open, which
swings the front ropes away. **Player confirmed** closing the upper gantry and
using the right ropes works, and called the all-stations glow very unintuitive.

**Initial implementation (superseded by swinging above):** rope cues predict
real service, generically. The player's capsule descends the plumb line until it meets a floor, then normal reach and the
shared placement sight check are judged from plumb or the lanyard pull-in pose.
Only open connections count; predictions are cached and spread one per frame.
For the waist hardware this cues front 10.8 (corners 1–2), front 15.2 (3–4),
rear 12.4 (2) and rear 13.6 (4). Line of sight, reach and rope rules are unchanged.
Six new `rope_access_test` checks; all 53 routine cases pass. Verified against a
copy of the player's save; no rendered review.

Deferred options: the obstruction prompt could say “approach from above” when
the player is below a connection; the manual's rope hint could name corner groups.

**Second round of player feedback (same day) and decisions:**
- Rope ends left within a person's height (1.8 m) of their davit now stow on
  unclip, and opening or closing the upper gantry stows every front rope nobody
  is clipped to. Only a clipped rider still holds the leaves.
- Crane connectors release per corner: fastener slots belong to their nearest
  lifting point, so each connector comes off once its own hardware is in while
  another still holds. The last attached connector still needs full retention.
  Guided and fixture-supported loads keep their existing rule. The chest note now
  says so and no longer asks to recall front ropes.
- Q while **hanging** with something in hand drops it (unclipping needs a floor
  anyway). On a floor Q still unclips without dropping. *Pushback:* always
  dropping when full would drop a carried part when the player lands and unclips.
- The player rejects the pull-in lanyard (“very unintuitive, just another
  keybind”) and asked for a swinging mechanic to build momentum. Implemented
  in [Rope swinging](#rope-swinging--2026-10-30) above; feel awaits player recheck.

- [ ] Unclip at the top deck: the rope stows itself. Close the gantry with a free
      rope out: it stows instead of refusing.
- [ ] Bolt one waist corner, detach that corner's connector on the same descent;
      the others refuse until their own corners are in.
- [ ] Holding a connector while hanging, Q drops it; on a floor Q unclips.

- [ ] At the waist hardware step on the 20.6 m deck, only serving ropes glow
      (the swing table above replaces the original four; UPPER GANTRY Close is
      cued while the leaves are open).
- [ ] The glow appears without a noticeable hitch on reaching the deck.
- [ ] Each glowing rope reaches its corners by lowering to just above the flange.
- [ ] Other rope-cued steps still glow a usable rope.

## Free-drive mobile platform — 2026-10-28

**Player decision:** “Can we make the moveable platform free drive? It should
nudge stuff out of the way.” Clarification: **WASD at onboard control**. This
supersedes the platform's fixed destination routes and the earlier no-pushing /
route-lane marking obligation for this machine's ground motion only.

**Player feedback and refinements:** the first implementation's fixed deck axes
were unintuitive (having to hold A to go toward the view); “but you cant turn”.
The user requested slight acceleration/deceleration, explicitly chose **A/D
steers; W/S drives; mouse looks freely**, requested a non-square platform with a
clear front, and supplied a wheeled scissor-lift reference. The initial three
button proposal (held Up/Down plus Drive, no Stop) was superseded by their final
choice: **one big red button with tooltip Operate**, then WASD plus held
Space/Ctrl like rappelling. No positive acceptance of the implemented version
has been supplied.

**Implemented:** 1.6 × 3.6 m wheeled chassis, tapered/lit nose, 1.2 × 2.2 m railed
deck, two scissor stages and rear ramp. Entering Operate faces forward; W/S
drives and A/D turns, including in place. Mouse look stays independent. Ground
speed ramps to 0.8 m/s in ~0.33 s, brakes in ~0.2 s; steering has short ramps too.
Held Space/Ctrl moves the deck between 0.45 and 2.40 m and stops on release.
There are no separate Up/Down/Stop buttons, fixed height stops or destination
routes. Height input brakes travel; driving and steering remain available when
the deck is raised.
E/Q leaves, Escape pauses and focus loss releases operation immediately.

**Player correction (2026-10-28):** remove the physical status screen and let the
lift drive while raised. Implemented: the deck display is gone, and W/S driving
and A/D turning work at any selected height. Raised travel checks the chassis,
scissor arms, deck, rider, held load and loose deck cargo through its full sweep.
The existing red-button tooltip and operating hint remain. Player recheck pending.

**Player follow-up:** the bottom ramp flickers/clips; a player who jumps off a
raised lift needs to call it down. Geometry inspection found a hidden underside
drawn flush with the floor and a front face sharing the chassis plane. Removed
those visual triangles, keeping the full convex walking collider. A low
rear-right **CALL ↓** post moves with the chassis and starts a guarded descent
from any raised height. The call waits for a blocker and resumes after clearance.
Four focused routine suites pass (199 checks), including the ramp triangle audit,
retained ramp collision, call access/arrival, pause and blocked descent. These
are mechanical checks; rendered flicker and player reach/feel need recheck.

**Player recheck, same day:** CALL feels too slow compared with the elevators;
the ramp has missing/open faces and still looks bad. The earlier face-removal fix
was rejected. A closed thin steel plate now encloses the ramp, with yellow edges
and treads. Its full walking collider is retained. CALL descends with the same
0.9-second ease-out as the landing lifts; its timer pauses when blocked. Three
routine suites pass (170 checks). Real-renderer rear and oblique views before
and after were inspected. The final views show a continuous slope and closed
sides without a broad coplanar floor face. The local capture report is
`game/workshop/verification/equipment-ui-ramp-final-641098/captures.json`
(`inputs_unchanged=true`). This is inspected presentation, not player acceptance
or a moving-frame flicker check.

Movement and turning nudge small loose piles (up to 16 bodies) only after
every body's swept path is clear. Pinned/fixed/held/mounted/supported blockers
stop the whole step without partial nudges. Shared rider/cargo support carries
translation and rotation; rope interlocks stay active. Height sweeps include the
scissor bars. The parking berth tests the actual rotated footprint, allowing
0.25 m clearance on each side, rather than requiring an exact centre/yaw.

**Mechanical evidence:** 358 passing checks: `mobile_platform_test` (38),
`equipment_motion_test` (85), `gantry_layout_test` (171), `workshop_smoke_test`
(31) and `save_roundtrip_test` (33). The last five-case run took 19.424 s and
exposed an exact floating-point comparison in the new JSON-height assertion;
using approximate comparison passes the platform follow-up in 4.060 s. Other
four cases passed on the same production code. Local logs:
`game/workshop/verification/regressions-20261028T073131.852281Z/` and
`regressions-20261028T073406.330752Z/`. Authoring audit and generated-layout byte
equality pass. Checks cover platform input/geometry/motion, shared cargo, gantry
parking clearance, startup and save/reload. Snapshots use
version 3 for arbitrary position, heading and height; older workshop saves are
invalid under the existing no-migration policy. No recipes, part allocation,
manual objectives or mounted interfaces changed. The rendered UI helper was
updated but not run. No inspected presentation or player acceptance is claimed.

**Correction checks:** `mobile_platform_test` (42), `equipment_motion_test` (85),
`workshop_smoke_test` (31) and `save_roundtrip_test` (33) pass: 191 mechanical
checks in 16.681 s. The platform fixture covers raised travel/turning and a
fixed blocker at raised deck height. Rendered presentation and player feel still
await recheck.

**Player recheck:**

- [ ] Longer scissor lift reads clearly: front, rear boarding ramp, red Operate button.
- [ ] W/S driving, A/D turning, free mouse look and entry facing feel natural.
- [ ] Slight acceleration/braking feels responsive; steering/turning in place is useful.
- [ ] Space/Ctrl reaches comfortable work heights and stops when released.
- [ ] Drive and steer while raised; check clearance, stability and rider feel.
- [ ] The red Operate button is understandable without a status screen.
- [ ] Nudge loose pieces/a small pile while driving and turning; judge gentleness.
- [ ] A pinned pile or fixed obstacle stops it; reversing/steering away is clear.
- [ ] Rider, held component and loose deck cargo follow turns without drift.
- [ ] Return inside the parking mark; rig interlock clears without fiddly alignment.
- [ ] Pause/focus loss/exit stops immediately; a new save restores position, heading and height.
- [ ] The rear ramp no longer flickers against the floor/chassis; boarding stays smooth.
- [ ] Jump off at a raised work position and find **CALL ↓** beside the chassis.
- [ ] Calling lowers to boarding height; a person or object beneath holds the deck until clear.

## Interchangeable heel pads — 2026-10-28

**Player evidence.** Clean workshop: placing a heel pad at a preparation station
marked *Prepare heel pad 2* in progress instead of the tracked *Prepare heel pad 1*.
The two pads are identical, so a hidden identity is unintuitive and raises doubt
about how the manual identifies interchangeable parts.

**Cause.** The physical model already treats them as interchangeable: either pad
seats in either heel position (slots accept the `heel_pad` definition). The manual
does not. Chapter steps name build instances (`pad_1`, `pad_2`), each bound to one
physical base (FA-302__001/__002), and hover labels show "Heel pad A/B".

**Change (2026-10-28, implemented):** the steps read "Prepare a heel pad (1 of 2)"
and "(2 of 2)" and bind to pads in the order the player starts them (hung at a
station or a sleeve fitted). Hover shows "FA-302 · Heel pad". Mechanical checks
only (`manual_progress_test`, 85 checks, and 13 other affected suites); no rendered review.

**Player recheck:**
- [ ] Hang either pad first: the tracked step stays *Prepare a heel pad (1 of 2)* and
      becomes In progress for that pad.
- [ ] Start the second pad: it reads *(2 of 2)*; finishing either pad ticks only its own step.
- [ ] Hover both pads: neither suggests a hidden A/B identity.
- [ ] Seat each pad in either heel position.

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

- [ ] Use the UPPER GANTRY panel on the 20.6 m landing beside the left lift
  (the ground bank was removed on 2026-10-28). Aim and press E for OPEN/CLOSE; confirm the panel stays
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

### Operated leg rig playtest — 2026-10-27

**Player verdict:** the first operated leg rig (one 2 m panel per end, hold-E
arrows) is "awful". Findings, in the user's terms:

- [ ] A button must operate one mechanism only. TRAVEL also closed the crossing
  gates and swung the gantry access wings open; the player wants to operate those
  themselves.
- [ ] Labels don't explain the operation. "BOLSTER" means nothing to a player.
- [ ] Controls need not share one interface. Group them by mechanism.
- [ ] The ghost must always show the target objective. Holding INDEX swapped the
  ghost between lanes, because a minus jog switched to the return targets.
- [ ] Design the control interface before implementing. The fantasy is
  engineering: concrete impact with control.

Status: [control interface v2](robot-workshop-plan.md#leg-rig-control-interface-v2-2026-10-27-approved) was agreed in discussion (drag the foot support, a transfer table lever, a combined RISE, E taps on the clamps, a simple gantry front, no crossing gates). The user approved it on 2026-10-27. The branch controller stays
unmerged, and the questions below still apply to whatever replaces it.

### Operated leg rig v2 and gantry fronts — ready to play 2026-10-28

**Accepted by the user and merged to main, 2026-10-28.** Unticked rechecks below
stay open as usability notes, not blockers.

Built on gantry v2 (`operated-rigs`). Automated: 28 routine suites; the leg, arm,
cassette, preflight and chest diagnostics pass; `head_crane_test` fails the same
15 stale "Parts for this step" HUD checks as `main`. A real-scene probe docks and
returns both legs. No presentation or player acceptance is claimed. Launch
`./play.command -- --stage=left_leg_dock`.

- [ ] Leg rig controls, one mechanism each: drag the foot support (hold E on its
  pad and walk), throw the transfer table lever (LEFT HIP · RIGHT HIP/BUILD ·
  PARK), the bogie box (TO BAY / TO TABLE, RISE / LOWER, NEXT LEG), the turnover
  box (now at X19.5 Z19.8, moved out of the table's path to PARK) and the LEG
  CLAMPS switch by the foot. Are the lamps enough to know what is still needed?
- [ ] The ghost shows only the current manual objective's target. Does it stay
  put while you work other controls?
- [ ] Gantry: LOWER GANTRY OPEN/CLOSE stands on the 8.4 m landing and UPPER
  GANTRY on the 20.6 m landing, both beside the left lift. RISE needs the lower open;
  CLOSE refuses while the leg is tilted up but not yet seated.
- [ ] Decision taken for you (reversible): **the crane never opens the gantry.**
  It waits with "Open the upper gantry (UPPER GANTRY panel at 20.6 m beside
  the left lift)" before every crossing, including the empty return to park, and arm
  deliveries wait for the lower front. The manual adds OPEN/CLOSE steps to every
  crane delivery page. Is that worth the extra trips to the panel, or should the
  crane keep v2's automatic opening?
- [ ] Clearances are tight but measured: the bogie box clears the rig's travel by
  40 mm and the turnover box clears the table by 150 mm (conservative bounds).

**First play, 2026-10-28 (user):** "I can't even tell where the foot support
is" — it should glow like other on-rig controls — and it should stop glowing
while you're grabbing it, as feedback that you've found it. E-key messages were
unhelpful: random errors, "Aim at a drawer, shelf or loose component", and "This
fixture stays at its work station" when pressing E on the leg. Rule: an E
refusal answers only an action the target's E prompt offered.

Fixed (routine checks only, player recheck pending):

- The foot support's sight check aimed at the centre of its own pad, so every
  view hit the pad itself; it had neither the glow nor a Hold E prompt. The pad
  and its link now count as the control. A real-scene probe shows the glow and
  Hold E from either side of the rig. From the foot end, the foot carrier's sole
  crossbar hides it, so the manual note and lamp refusals now say "under the
  foot, from either side of the rig".
- A control's glow rests while E holds it and returns when released (every held
  control, not only the foot support).
- Leg rig glow follows the on-rig rule: foot support, transfer table lever and
  LEG CLAMPS switch glow; bogie box buttons do not, like other rig panel
  buttons. The gantry front panel rows still glow as gantry v2 had them.
- E at a target whose prompt offers no E (or at nothing) is silent. Successful
  actions are unchanged, and refusals still show for prompted actions.

- [ ] Recheck: find the foot support from its glow, grab it (glow goes out),
  pull it away. Press E around the rig and the leg: no stray messages.
- [x] Is the lever's glow wanted? No (user, 2026-10-28): removed.

**Second play, 2026-10-28 (user):** "Overall I really like this direction, much
more satisfying." Findings and decisions:

- Looking at the sole, only the left pad moved the foot support. Fixed: the
  drag follows whichever pad you grab.
- Rename to "lower gantry" and "upper gantry" instead of leaves/front. Done
  everywhere players read it.
- Design principle: **when looking at the button that operates something, the
  player should see the machinery it operates**, for immediate feedback. The
  gantry panels failed it. Measured: the upper gantry is 12.2 m above the 8.4 m
  level, so only a 20.6 m panel shows it. User chose: split by level, with LOWER
  GANTRY at 8.4 m and UPPER GANTRY at 20.6 m, both beside the left lift, and no
  ground bank. Accepted cost: lift rides on each crane delivery.
- Closing the lower gantry at the end of the seat page highlighted "open the
  lower gantry" while it animated closed. Fixed: an opened gantry keeps its OPEN
  step ticked while closing.
- Transfer table lever: the user had expected two positions and asked why PARK
  exists. It clears the Limb Bay for the arm rig, so it stays. Decision: a
  stick-shift gate with no labels. Seen from the foot end looking at the sole,
  the order is PARK, a long gap, RIGHT HIP · BUILD, a short gap, LEFT HIP
  ("|____|__|"). The TRANSFER TABLE sign goes, and the stick moves down by the
  sole so you look at the rails while operating it. It starts in the detent
  matching the table, which begins at RIGHT HIP · BUILD.
- Landed 2026-10-28 (routine checks plus the leg rail and arm rig diagnostics;
  no rendered review). The LOWER GANTRY bank is at (4.80, 8.4, 24.40) and the
  UPPER GANTRY bank at (4.55, 20.6, 24.35). From each bank, most of the nearer
  wing or leaf is in the camera view at every phase. The rear leaves are not
  visible (behind the robot), and a completed robot's arms may hide the closed
  lower finger. The transfer stick is at (16.8, 0, 7.0) in front of the sole,
  with detents 0.56 m / 0.28 m apart. Most of the rails and table stay in view
  from every detent. Manual text names detents from the foot end, for example
  "the right end (LEFT HIP)".
- [ ] Recheck all of the above: panel and stick reach, the view of the
  machinery while operating, and whether "right end (LEFT HIP)" reads clearly.
- Third round, 2026-10-28: the stick's floating lamp text is removed (the E
  prompt still explains a locked stick). The ghost now moves to the next
  objective's target as soon as that step is current, with no control input.
- Fourth round, 2026-10-28 (routine checks; no rendered review): the leg rig
  ghost is dimmer and more translucent (lower alpha, less bright tint). Both
  gantry banks are now panels hung from the yellow front guard rail of each
  hinge apron at (3.92, 8.4/20.6, 23.30), facing the apron, so nothing stands
  on the walkway. The earlier visibility figures were not re-measured.
- [x] Accepted by the player on 2026-10-28: dimmer ghost and rail-hung panels.

### Operated rigs open questions — Phase 1

These questions were written for the rejected v1 rig. Items about the 2 m
panels, INDEX stops, REACQUIRE, BOLSTER grouping and per-axis readouts are
superseded by v2 (above); the jog speed, foot guide turn and ghost visibility
questions still apply. The leg rig is converted on the `operated-rigs` branch
(2026-10-27) and has routine mechanical checks only. The foot rig is not converted, and no presentation
or player acceptance is claimed. The [B3/B5 design](robot-workshop-plan.md#operated-rigs--phase-1-design-2026-10-27)
keeps the accepted foot building bay and physical access challenge. To play it,
launch `./play.command -- --stage=left_leg_dock`. At checkpoint B:

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
- [ ] INDEX stops at each track and ROLL at each 90° detent; a fresh press is
  needed to continue. Is that acceptable, or does it read as a hidden NEXT? (Free
  stopping at 0.8 m/s gives a 50 ms window.)
- [ ] The two panels are now 2.0 m wide, with up to 22 arrows and 8 taps. Are they
  readable and reachable? Is splitting construction controls onto the Limb Bay
  panel only the right call?
- [ ] REACQUIRE also extends the empty holder at the station before BUILD. Is the
  name clear for that use, or does it need its own tap?
- [ ] Ghost policy: shown only for a carried leg away from construction home and
  hidden when seated. Is it visible enough during TRAVEL and TILT?

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

## Coplanar flicker regression — 2026-10-28

- Player reports coplanar faces cause distracting flicker and requests a fast
  regression. Synthetic-only coverage was explicitly rejected as insufficient.
- Added routine coverage of 648 actual dressed blockout/lift/mobile-platform
  meshes at parked and open/raised poses. Latest setup and scans: 1.297 seconds;
  focused runner including startup and detector fixtures: 5.155 seconds.
- Automated result: detector's 31 checks and real-asset duplicate injection pass;
  content gate fails on 113 parked / 111 open-raised overlapping mesh pairs.
  Named triangles and paths are recorded in
  `game/workshop/verification/workshop-surfaces.json`. No allowlist was added.
- Open: repair reported overlaps and recheck flicker in play. Robot geometry,
  hangar dressing, other equipment constructors, internal same-node overlaps and
  intermediate motion remain outside this test's scope. No rendered review ran.

- Repair in progress: cassette ties/clamps, rope davit/boom arms and duplicate
  posts now use non-overlapping visible geometry; lift shoe and platform rail/
  parking joints were adjusted while preserving collisions. The actual-scene
  scan reports 34 parked and 36 open/raised pairs (652 meshes, 1.017 seconds);
  cassette and rope arm assertions pass in both poses. Remaining findings include
  support girders, guard connections and lift carriages. Gantry layout and
  dressing and access-lift checks pass, though the runner reported changed input
  hashes during that run. A subsequent stable run passed all 52 mobile-platform
  checks and confirmed the remaining surface findings. No rendered review or
  player recheck has been performed.

- Repair completed for the checked poses: the fixture now finds zero pairs in
  both, including the gantry girders, guards and lift carriage joints. Visible
  geometry was trimmed or recessed at the joins; collision boxes are unchanged.
  Focused scan: 652 meshes, 0.982 seconds. All 53 routine cases pass in 54.358
  seconds with unchanged inputs. No rendered review was requested; player
  recheck of flicker remains open. Exclusions listed above remain unverified.
