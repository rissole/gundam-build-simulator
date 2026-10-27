# Overhead rope access — concept, 2026-10-27

**Implemented on `gantry-v2`; user approved merging into main on 2026-10-27.**
The implemented layout, rope controls, crane routes and evidence are recorded below.
Replaces C6's upper catwalk levels (11.2/14/16.4) and tower hip beams. The robot,
hip datum (13,10.6,26), bearing caps, jaws and today's low rear hip frame stay.

3D block mock (live reach/clearance checks per connection):
[mock/overhead-access.html](mock/overhead-access.html), published at
https://claude.ai/artifact/5TYsCiNM2vnjYYn9znaRTd.

## Layout (user decisions, 2026-10-27)

- **Workshop-side walkway: two hinged leaves** at deck Y20.6 (underside 20.3, 0.9 m
  over the head top Y19.41). They share the 8.4 m wings' vertical axles at
  (X5, Z24) and (X21, Z24) and the same split at X13: each leaf X5..12.98 /
  13.02..21, Z23.4..24.6, 1.2 m wide, 1.1 m guards. Not hung from the ceiling:
  each leaf has a short mast and tie kept below the crane bridge (Y22.65).
  Following player feedback, the workshop-side lift shaft carries the left
  hinge through brackets below the decks; the opposite column stands beyond
  the far outer apron corner. There are no through-posts at the hinge axes.
  Hinge aprons at 20.6 match the 8.4 ones (X3.5..5 and mirror).
- **Opening for the crane:** like the wings, both leaves swing 90° toward the
  workshop and park along the hall at X4.4..5.6 / 20.4..21.6. The crane then uses
  its current front approach down the middle. Once the part hangs over the robot
  at Z26, the leaves close under the crane bridge (cables drop at Z26, clear of the
  leaves), so rope work from the front continues while the crane holds the part.
  Interlocks: nobody on a leaf while it swings; leaves open before the crane
  crosses Z23.4..24.6; trolley near X13 while passing open leaves.
- **Exit-side walkway: fixed**, X5..18, Z30.3..31.7, standing on posts (west post
  from the floor near X4.8, east end on the right lift's structure). Nothing may hang
  from the roof: the crane bridge travels the whole hall at Y22.65..23.4. It sits
  at Z31 so the core's lifting cables (about Z29.2 during insertion) clear it.
  Core and backpack deliveries approach from the workshop side over the chest;
  no delivery crosses this walkway. The crane console stays in use.
- **Rappel points:** davits along each walkway's robot-side edge swing out up to
  2.0 m toward the robot at Y21.8, below the crane bridge. Controlled descender, no
  swinging. Pull-in lanyards reach up to about 1.6 m (user-accepted). No rappelling
  from a leaf while it is open.
- **Lifts, one per walkway (option (b)):** stops 0.15, 8.4 and 20.6. The left lift
  moves outboard of the left hinge post (X0.3..3.5, Z22.45..25.65) and opens onto
  the hinge apron at both 8.4 and 20.6. The right lift moves aft
  (X18..21.2, Z29.4..32.6) and opens onto the exit-side walkway. The upper side
  runs now connect both landings without a trip downstairs. The crane bridge passes over both lifts,
  so shaft structure ends at Y20.2 and cars are open-topped.
- **Kept:** the 8.4 m landing (outer walkways, hip aprons, rear hip decks, front
  swing wings). The fixed rear crossover is removed.
- **Upper perimeter (player follow-up):** fixed 1.5 m side runs join the front
  landings to the rear walkway. The right route turns in front of the rear lift
  shaft, keeping the loop connected even with the car downstairs. The front
  leaves still open for crane crossings; the sides and rear stay fixed.

## How each connection is reached

| # | Connection | Access | Mock result |
| --- | --- | --- | --- |
| 1 | Get onto the walkways | Each lift's top stop | Works |
| 1a | Crane delivery from the workshop | Both leaf levels open; current front approach | Works |
| 2 | Hip onto frame: 4 jaws, waist locks | 8.4 m rear hip deck, as today | Unchanged |
| 3 | Hip lifting adapters off (Y11.35) | Workshop-side rope, davit 0.3 m | Works (reach 0.40) |
| 4 | Leg → hip: ring, bolts, cylinders, pins | 8.4 m front wings and rear decks, as today | Unchanged |
| 5 | Chest → waist, front | Workshop-side rope while crane holds the chest | Works (0.60) |
| 6 | Chest → waist, rear | Exit-side rope, davit 2.0 m, pull-in | Pull-in (1.50) |
| 7 | Core → chest: rear flange, bolts | Exit-side rope beside the core path | Works (0.70) |
| 8 | Backpack hinge and strut pins | — | **Open challenge** (user will propose something) |
| 9 | Arm → shoulder: seat, split ring | Workshop-side rope while crane holds the arm | Works (0.80) |
| 10 | Pauldron | Workshop-side rope, forward and outboard | Pull-in (1.00) |
| 11 | Head → neck | Workshop-side rope | Works (0.70) |
| 12 | Head top and crown | Workshop-side rope, short drop | Works (0.80) |

Reach is from the hanging worker's shoulders: ≤0.85 m works, ≤1.6 m works with a
pull-in lanyard. Robot blocks are C5 measured unions without growth, so these are
coarse indications only.

## Costs and follow-ups

- Every delivery approaches from the workshop side. Core and backpack routes
  change to pass over the chest. Head pieces and pauldrons travel high (bottoms
  Y18–19): keep the trolley near X13 while passing the open leaves.
- Each upper leaf is an 8 m cantilever at 20.6 m, carried by the shaft or outer
  corner column through an under-deck bracket; structure is a budget, not engineered.
- The right shaft is 0.1 m from the hip frame's right foot (coarse).

## Decisions and open items (user, 2026-10-27)

1. Backpack hinge: **open challenge**, deliberately unsolved.
2. Pull-in lanyards: **accepted** as a mechanic.
3. Walkways: two rappel sides, one lift each (**option (b)**), now joined by an
   upper perimeter loop. Workshop side is **hinged on the 8.4 m wing axles** so
   the crane can come down the hall; the sides and exit side are fixed.
4. Exit: the robot is released and lowered to the ground, then needs a clear run.
   The rear hip frame and 8.4 m rear decks/aprons sit behind it. Use whatever is
   simplest yet satisfying; not designed yet. The robot passes under the exit-side
   walkway (underside 20.3 m vs grown top 20.16 m, more once lowered).


## Implemented A1 layout — 2026-10-27

The branch implementation supersedes the concept's preliminary 0.3 m deck depth:
upper decks are **0.2 m**, top Y20.6 / underside Y20.4. Shared hinge axes remain
at X5/X21, Z24. The original through-posts were removed in the player correction
below; the later deck cleanup removes their caps and notched filler plates too.
Mast/tie and boom members remain below the crane bridge. Both upper
leaves keep the 8.4 swing and split at X13, with no upper fingers. Low hip frame,
jaws, bearing datums and the retained hip finger work patches are unchanged.

Lifts sit at (1.9,24.05) and (19.6,31), with stops 0.15, 8.4 and 20.6. The left
opens east at every stop; the right opens east at ground/8.4 and west at 20.6.
Open-topped cars retain their 2.6 m size and shelves. Fixed guides end at Y20.2;
sliding carriage masts maintain support through the final 0.6 m of car travel
without pushing the ground-level shoes through the floor. Both right guides
are west of the car, clear of the retained right outer walk.

The rear walkway spans X5..18, Z30.3..31.7, widening to 1.5 m at its east landing.
Its west support stands at **X5.24**, clear of the 8.4 walk and inner guard;
X4.8 would intersect that walk. The east support posts/header sit alongside the
right lift at X17.9 and end at Y20.2. There are no roof hangers. Four 2 m fixed
booms end at Z28.3/Y21.8. Eight fixed front davits end at Z24.75/Y21.8. Adjacent
front stations only 0.7 m apart share the union of their 0.9 m guard openings;
rope equipment owns the protective barriers. Jamb piers carry the davits/booms.

Removing the old shafts would disconnect the rear hip aprons. Fixed 1.5 m links
replace that path: left Z28.5..30; right Z27.6..29.1 to clear the new shaft.
Left lift landings extend the hinge apron's depth by 0.1 m at each end. Fixed
thresholds leave a 20 mm car gap. The right car's east face X20.9 is 0.1 m from
the retained X21 outer walk, so its flush plate spans X20.92..21 without a
coplanar overlap. Lower sliding access gates remain; upper apron ends now join
the perimeter side runs. New/retained members keep the accepted
finish and the signs read **8.4 HIP / 20.6 ROPE ACCESS**.

Initial A1 mechanical evidence: eleven selected routine suites passed, **728 checks in
19.307 s**, including full-height shelf cargo, guide engagement/hardware travel,
station transforms, post clearance at every swing angle, coarse grown-robot and
nearby equipment boxes, save roundtrip, rider/nudge policy and startup. The
layout generator verifies 591 solids / 79 frames. No diagnostics, rendered review
or automated walking/reach/visibility campaign ran. This is not player acceptance;
[the player recheck remains open](../robot-workshop-playtest-checklist.md#gantry-v2-rope-access--2026-10-27).
The crane routes and crossing interlocks are recorded below.

## Walkway support and lighting correction — 2026-10-27

The player found the tall front hinge posts obstructing the walkways and lights
floating between the former levels. Both through-posts are removed completely.
At the workshop-side lift, fixed brackets connect the rear shaft guide to the
left hinge below both decks. The opposite column moves beyond the far outer
corner to **X22.64/Z23.26**, ends at the upper deck underside Y20.4, and carries
its hinge through under-deck brackets. The hinge axes, swing and deck heights
stay fixed. This first correction used flush 0.24 m square bearing caps; the
follow-up below removes those caps and the surrounding notch fillers.

The obsolete fixed-height strips and unsupported downlights are removed. Housed
LED strips attach directly to the undersides of both upper leaves, the rear
walkway and its landing; the two retained lower outer walks also keep mounted
strips. Three shadowless downlights follow the main upper fixtures. All moving
lights inherit their leaf's transform, with no new collision bodies.

Six selected routine cases pass in **10.803 s**: layout (168 checks), dressing
(152), lifts (45), crane (198), rope access (104) and startup (32). This includes
shaft/bracket contact, clear former post positions, full lift-hardware travel,
hinge clearance and fixture attachment through leaf rotation. The author verifies
**602 solids / 79 frames**, byte-identical to the generated asset. Local evidence:
`game/workshop/verification/regressions-20261027T103231.445157Z/results.json`.
No rendered review or automated walking/reach/visibility acceptance ran. The
[player recheck remains open](../robot-workshop-playtest-checklist.md#gantry-v2-rope-access--2026-10-27).

## Upper perimeter and deck cleanup — 2026-10-27

The player liked the post/lighting correction ("Really great!") and requested
plain landings, no floating rappel labels, and a complete upper circuit.
Both levels now use single rectangular hinge landings and leaf decks separated
by a 20 mm seam. The small pole caps and four notch fillers at each hinge are
removed. Hinge support stays underneath the decks; front swing behavior remains.

At Y20.6 the left side spans X3.5..5/Z24.7..31.7. The right side spans
X21..22.5/Z24.7..29.2, then turns across X16.5..21/Z27.7..29.2 and connects to
the existing rear lift landing through X16.5..18/Z29.2..30.25. This inset corner
keeps the route outside the shaft and independent of the lift car. The shaft-side
guard is inset 0.1 m to clear its sliding guide sleeve. Removed end guards open
the deck joins; remaining edges are guarded. Under-deck girders join the side
runs to the existing supported corners. The square-like perimeter is complete
when the front leaves are closed; opening them retains a fixed route around the
sides and rear between the front landings. Rappel anchors and crane routes stay
at their existing positions.

The four new fixed deck sections carry attached strip housings, with no extra
light sources. Rappel stations no longer create floating instruction labels;
normal hover tooltips, control glow and the rope HUD remain.

Six selected routine cases pass in **12.308 s**: layout (188 checks), dressing
(160), crane (235), rope access (104), lifts (45) and startup (32). Checks cover
deck adjacency and open joins, full lift/carriage travel, loaded and empty crane
envelopes against the fixed perimeter, existing rope behavior, and strip attachment.
The author verifies **609 solids / 79 frames**, with generated byte equality.
Local evidence: `game/workshop/verification/regressions-20261027T104714.045559Z/results.json`.
No rendered review or automated walking/reach/visibility acceptance ran; the
new circuit and deck presentation await the player's recheck.

## Rope operation and guidance — 2026-10-27

Physical **UPPER LEAVES / OPEN / CLOSE** panels beside the left lift, at ground
and on its fixed upper landing, let the player close the leaves after delivery.
The panels stay on supported ground/landing geometry. The crane console keeps
its existing movement controls. Manual guidance points to Close when front rope
access needs it, then to an appropriate station after closure; normal range and
occlusion checks still apply.

At a station, **E** clips in and opens the protected passage. Adjacent gates trim
their overlapping barriers to preserve the selected full 0.9 m opening. Space
ascends and Ctrl descends: taps move at 0.6 m/s for the first 0.12 seconds, then
held input accelerates at 8 m/s² up to 4.5 m/s (about 0.61 seconds after pressing).
Release locks height immediately; reversal starts a fresh slow tap. Pause,
collision/end limits, lanyard use and reload reset the transient acceleration.
WASD gives bounded slack at its existing speed. Boarding uses the existing
crouch capsule beneath the solid davits/booms, including after reload. The rear
boom has a collision-resolved top traverse back to its walkway. **G** clips or
releases the pull-in lanyard while hanging. **Q** unclips only on a floor; while
attached it never drops a carried component, even when unclipping is refused.
Outside rope use Q keeps its normal set-down action. A free
rope can be clipped from below or recalled at its station. Existing hand carrying,
targeting and solid obstruction rules remain active.

Clip-in success keeps the permanent rope HUD and suppresses the duplicate
temporary status toast, for both station clips and hanging ends, through E or
click. Errors still use normal feedback; other equipment keeps its status toasts.

Front lines must be recalled before the upper leaves move. An unclipped worker
standing on a leaf also holds its motion. Crane cables in the crossing hold
Close, including with the crane manually stopped; closing is available once the
crane is clear over the robot. These holds leave lower access independent.

Rope snapshots retain station, line length, attachment and pull-in state with the
current player pose. Invalid attachment/length/player/leaf combinations are
rejected before live restoration, with no migration. This narrow rope safeguard
does not introduce a wider per-machine save-validation framework. Manual changes
are limited to goals and notes; objectives, slots and component quantities are
unchanged. Backpack hinge worker access remains deliberately unresolved.

## Corner flashing and rope-control follow-up — 2026-10-27

The player called the upper loop "Near perfect" and reported flashing corner
geometry near the workshop-side elevator. Two rear landing-extension plates
overlapped the side-walk floor over X3.5..4.8/Z24.7..24.8, at both 8.4 and
20.6 m. Removing those redundant plates retains the existing continuous floor.
The dressed fixed walkway meshes now pass a pairwise coplanar top-face check.
This also implements the player's requested Q unclip, permanent-only clip status,
and fast held rappelling with slow taps described above.

Five selected routine cases pass in **7.938 s**: rope access (121 checks),
gantry dressing (161), layout (188), centered carrying (14) and startup (32).
Rope checks cover E/click feedback, errors, Q versus set-down, both travel
directions, repeated taps, reversal, instant stopping, frame-rate-independent
acceleration and reload reset. Existing landing, boom, collision and save checks
also pass. The author verifies **607 solids / 79 frames**, byte-identical to
the generated asset. Local evidence:
`game/workshop/verification/regressions-20261027T110404.141596Z/results.json`.
No rendered review or automated walking/reach/visibility acceptance ran; corner
appearance and rappelling feel remain player rechecks.

## Crane route implementation — 2026-10-27

The actual prepared chest source, including its neck, tops out at **Y16.98**
(chest seat 12.7 + local 4.28). The earlier crane brief's approximate 18.7 m chest
height did not match that source. The front route uses the current geometry:

- **Core:** horizontal cartridge root at Y18.0, bottom 17.53, clearing the chest by
  about 0.55 m. The removable lifting bridge is included. The spreader is at 19.75
  (top 19.84). Travel along X13 to root Z28.6, descend behind the chest, then retain
  the existing root (13,13.35,28.2) guided approach. The mast stays at X13/Z29.2
  during rear descent; the complete lower rig remains below the fixed booms.
- **Backpack:** retain the open 90° source orientation; hinge datum travels at
  Y17.6, with its lowest hinge surface 17.535, about 0.55 m above the chest. The
  spreader is at 19.68 (top 19.77). Travel along X13 to the existing Z27.2 hinge
  approach, then lower through Y15.7 to the unchanged hinge seat (13,15.5,27.2).
  The mast is at X13/Z28.6, with the wide lower rig beneath the booms.
- **Other deliveries:** their existing front routes remain; upper leaf crossing
  uses the cable/contact/spreader envelope. Head pieces and pauldrons stay inside
  the open-leaf corridor. The upper leaves are requested only for the next
  crossing segment, including reverse and empty travel. At the robot they can
  close while the crane still supports the component. A deployed front rope or
  a worker standing on a leaf holds the trip with its named reason; clearing the
  condition resumes it. A Close request also waits while crane cables already
  occupy the band, including a manually stopped crane; leaf physics checks that
  hold before moving. The arm's 8.4 m needs remain a separate lower configuration.
- **Empty crane:** the old direct diagonal from parking to rear stock crossed
  the relocated left lift. All empty pickup, parking, return and receiver-reacquire
  paths now lift the beam to at least 20.6 m, travel fore to the Z13 transfer lane,
  change X/height there, and descend at the destination. Stowed ends clear the
  eventual head before moving over it. Start pose and progress reconstruct the
  same symmetric path after stopping or saving; console controls are unchanged.

These are coarse source/rig bounds and mechanical checks. The backpack hinge
**worker access remains the user's open challenge**. No walking, reach, visibility
or rendered review is implied by the crane delivery implementation.

## Integrated verification — 2026-10-27

Parent verification on the combined prototype passes **20 selected routine
cases in 23.409 s**, with unchanged inputs and no performance warning. This
includes the new layout (152 checks), rope/input/control (104), crane/route (198)
fixtures, plus lifts, shelves, motion, rail endpoints, save roundtrip, startup,
manual objectives/progress/completion/guidance, stage contract, shoulders and
source-asset checks. Both authoring byte-equality checks and `git diff --check`
pass. Local evidence:
`game/workshop/verification/regressions-20261027T095513.924029Z/results.json`.

The parent independently verified the exact manual source edits and recursively
compared generated definitions with goal/note fields removed: objectives, slots,
quantities and other content remain unchanged. Astra's source/spatial reviews
found and repaired overlapping gates, boom boarding, lift-car interference,
occupied-crossing closure and missing physical leaf controls. The control fixture
uses normal E targeting, checks named hold messages, prerequisite cue switching,
and panels against closed, intermediate and open leaf solids.

These are mechanical and source-review results. No rendered review, automated
walking/reach/visibility acceptance, diagnostic suite or gameplay FPS measurement
ran. The [player checklist](../robot-workshop-playtest-checklist.md#gantry-v2-rope-access--2026-10-27)
retains its detailed rechecks. The user subsequently approved merging into main
after the [docking renderer repair](../robot-workshop-playtest-checklist.md#left-leg-docking-renderer-errors--2026-10-27).
Backpack hinge worker access and eventual lowering/departure remain open design work.

## Main integration checks — 2026-10-27

After the docking renderer repair, twelve selected routine cases pass across
three runs: render lifecycle, outlines, nested mounts, rail endpoints, startup,
gantry layout, rope controls, crane policy/crossings, elevators, save roundtrip
and source assets. Run totals: 9.697 s, 17.361 s and 2.648 s, with unchanged
inputs and no performance warnings. Local reports:

- `game/workshop/verification/regressions-20261027T111610.647045Z/results.json`
- `game/workshop/verification/regressions-20261027T111736.609530Z/results.json`
- `game/workshop/verification/regressions-20261027T111835.796404Z/results.json`

The isolated Metal/Forward+ light-pairing reproduction goes from two engine
errors to zero with the workaround. No full-scene FPS measurement or rendered
visual review is claimed. The user authorized merging `gantry-v2` into main
once this repair was complete; detailed player rechecks remain open.
