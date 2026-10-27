# Overhead rope access — concept, 2026-10-27

**Prototype integrated on `gantry-v2`; branch-only until playtested and approved.**
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
  each leaf is a cantilever from its post, with a short mast and tie kept below
  the crane bridge (Y22.65). Posts run floor to Y22.3. Hinge aprons at 20.6 match
  the 8.4 ones (X3.5..5 and mirror).
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
  (X18..21.2, Z29.4..32.6) and opens onto the exit-side walkway. Crossing between
  walkways means going down and back up. The crane bridge passes over both lifts,
  so shaft structure ends at Y20.2 and cars are open-topped.
- **Kept:** the 8.4 m landing (outer walkways, hip aprons, rear hip decks, front
  swing wings). The fixed rear crossover is removed.

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
- Each upper leaf is an 8 m cantilever at 20.6 m from a tall post; structure is a
  budget, not engineered.
- The right shaft is 0.1 m from the hip frame's right foot (coarse).

## Decisions and open items (user, 2026-10-27)

1. Backpack hinge: **open challenge**, deliberately unsolved.
2. Pull-in lanyards: **accepted** as a mechanic.
3. Walkways: two rappel sides, one lift each (**option (b)**). Workshop side is **hinged on the
   8.4 m wing axles** so the crane can come down the hall; exit side is fixed.
4. Exit: the robot is released and lowered to the ground, then needs a clear run.
   The rear hip frame and 8.4 m rear decks/aprons sit behind it. Use whatever is
   simplest yet satisfying; not designed yet. The robot passes under the exit-side
   walkway (underside 20.3 m vs grown top 20.16 m, more once lowered).


## Implemented A1 layout — 2026-10-27

The branch implementation supersedes the concept's preliminary 0.3 m deck depth:
upper decks are **0.2 m**, top Y20.6 / underside Y20.4. Shared 0.24 m square
hinge posts at X5/X21, Z24 end at Y22.3; deck notches clear them throughout the
swing. Mast/tie and boom members remain below the crane bridge. Both upper
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
coplanar overlap. Lower sliding access gates remain; upper apron ends are guarded
because there is no upper outer walkway. New/retained members keep the accepted
finish and the signs read **8.4 HIP / 20.6 ROPE ACCESS**.

Mechanical evidence: eleven selected routine suites pass, **728 checks in
19.307 s**, including full-height shelf cargo, guide engagement/hardware travel,
station transforms, post clearance at every swing angle, coarse grown-robot and
nearby equipment boxes, save roundtrip, rider/nudge policy and startup. The
layout generator verifies 591 solids / 79 frames. No diagnostics, rendered review
or automated walking/reach/visibility campaign ran. This is not player acceptance;
[the player recheck remains open](../robot-workshop-playtest-checklist.md#gantry-v2-rope-access--2026-10-27).
The crane routes and crossing interlocks are recorded below.

## Rope operation and guidance — 2026-10-27

Physical **UPPER LEAVES / OPEN / CLOSE** panels beside the left lift, at ground
and on its fixed upper landing, let the player close the leaves after delivery.
The panels stay on supported ground/landing geometry. The crane console keeps
its existing movement controls. Manual guidance points to Close when front rope
access needs it, then to an appropriate station after closure; normal range and
occlusion checks still apply.

At a station, **E** clips in and opens the protected passage. Adjacent gates trim
their overlapping barriers to preserve the selected full 0.9 m opening. Space
ascends, Ctrl descends, and WASD gives bounded slack. Boarding uses the existing
crouch capsule beneath the solid davits/booms, including after reload. The rear
boom has a collision-resolved top traverse back to its walkway. **G** clips or
releases the pull-in lanyard while hanging, and unclips only on a floor. A free
rope can be clipped from below or recalled at its station. Existing hand carrying,
targeting and solid obstruction rules remain active.

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
remains unticked. Keep this prototype on `gantry-v2` until the user playtests and
explicitly approves. Backpack hinge worker access and eventual lowering/departure
remain open design work.
