# Overhead rope access — concept, 2026-10-27

**Design only; build not approved. Branch-only until playtested and approved.**
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
  at Z31 so the core's lifting cables (about Z29.2 during insertion) clear it. The
  core and backpack stores are west of the robot, so those loads come in sideways
  behind the robot, west of this walkway. **Superseded for the build:** core and
  backpack come from the front over the chest instead (see the build brief), so no
  delivery crosses this walkway.
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

- Current front crane routes stay; only the core and backpack come in sideways
  behind the robot. Head pieces and pauldrons travel high (bottoms Y18–19): keep
  the trolley near X13 while passing the open leaves.
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
