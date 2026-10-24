# Final gantry and robot assembly plan

Updated 2026-10-24 after the coordinated fixture and route pass. This is the
canonical full-workshop layout and major-section assembly plan. It selects
fixture contacts, equipment motions, parking, loaded routes and worker access
against the component contracts. These are **dimensioned design envelopes**, not
implemented equipment, structural certification or actual-solid clearance proof.
That documentation pass did not change the M3 scene, saves or runtime. Subsequent
implementation is tracked in the [M3 adaptation ledger](history/m3-wide-evidence-20261024.md#plan-implementation-ledger-through-task-09);
its partial equipment checks do not establish full-workshop or human access approval.

[Active workshop state](leg-workshop-next-steps.md) · [Layout drawing](final-assembly-layout.svg)
· [Robot dimensions](../proportions.md)

## Status and agreed direction

- Install **pelvis/waist → both legs → chest/cockpit → power core → backpack →
  both arms → head**. Preparation remains independent; gate installation on real
  support and access dependencies.
- Retain M3's raised pose: soles world Y1.40. Eventual whole-robot lowering is
  undecided and is not included in these equipment motions.
- Use two side elevators and shared front/rear work platforms. Each elevator
  serves hip, waist, shoulder and head work.
- Use **one long-limb build station**, with one rail cradle and one removable arm
  jig. One passive parking place for each prevents a half-built limb monopolizing
  the station. Legs travel by rail; complete arms, including hands, travel by crane.
- Prepare pelvis/socket/waist together and chest/frame/cockpit together. Keep
  shoulder armor off during arm connection. Build the head on its fixed neck.
- Reuse a single crane, an adjustable bulky fixture, one mobile work platform,
  the two elevators and contextual equipment controls. Do not add per-part machines.
- Preserve the satisfying M3 handling and local mistake correction. Full teardown
  and rendered-game review are not acceptance gates for this design pass.

The user approved the assembly direction and asked for this coordinated pass
without subagents. The derived dimensions below are selected planning decisions;
remaining detailed modeling must stay inside their reservations or revise this
plan explicitly. Component documents own mechanisms and fasteners; this document
owns equipment, routes and access. No competing planning snapshots are needed.

### Coordinate frame

Workshop coordinates are **world metres: X right, Y up, −Z forward**. Robot
coordinates are X right, Y forward, Z up. The raised mapping is:

`world = (13 + robot.X, 1.4 + robot.Z, 26 - robot.Y)`

| Landmark | Raised world datum |
| --- | --- |
| Sole / ankle / knee | Y1.40 / 2.40 / 6.50 |
| Left / right hip | (11.90 / 14.10, 10.60, 26) |
| Waist bearing / lean axis | Y11.90 / 12.30 |
| Chest mating plane / approach | Y12.70 / 12.88 |
| Core axis | X13, Y13.35; front–back |
| Left / right shoulder | (10.80 / 15.20, 15.80, 26) |
| Head base / helmet roof / crest | Y16.80 / 18.80 / 19.40 |
| Final feet | X11.25–12.55 / 13.45–14.75; Z23.80–26.80 |

## 1. Measured workshop and gantry layout

### Floor zoning and equipment quantities

Keep the existing **40 × 48 m floor**, world X−14..26/Z−9..39. Wall inner
faces are approximately X−13.85/25.85 and Z−8.85/38.85. Raise the proposed
full-workshop roof to Y25.0; the current M3 overhead equipment is insufficient.
The floor layout replaces conflicting prototype stock positions in a future
implementation; it does not claim to preserve every current rack.

| Area | Selected clear reservation / datum | Purpose |
| --- | --- | --- |
| Bulky-module bay | **11 × 12 m**, X−2.25..8.75/Z6..18 | Pelvis, chest/cockpit, core, open backpack and head-shell preparation on one adjustable fixture. Chest seat source (3.25,0.85,13). |
| Shared long-limb bay | **7 × 13 m**, X10.5..17.5/Z7.8..20.8 | Both legs and arms, one at a time; centre X14, knee Z14.5. |
| Passive leg parking | X20..24/Z8..20.5; cradle centre X22, knee Z14.5 | Same rail cradle, parked horizontally; no build console or turning here. |
| Passive arm parking | X11.8..16.2/Z−7..2.5 | Supported arm cassette, about 2 × 9 m; shoulder source (14,1.55,−6.3). Crane transfers the whole retained jig. |
| Foot/small-component bay | X−11.5..−3.5/Z5..16 | Continue the existing detailed foot workflow; prepared-foot datum (−7,1.2,8). Internal full-foot tooling is the next component pass. |
| Small preparation and stock | X−11.5..8.75/Z−5..2 | Carryable mechanisms, hardware, sensors and reusable adapters. Keep stock ≤3.2 m high under the distribution routes. |
| Foot dispatch | (14,1.2,7); foot Z4.8..7.8 | Shared guided carrier into the supported leg root at Z9.4. |
| Mobile platform parking | X5.5..7.9/Z18.3..20.3 | One guarded adjustable work platform, stabilized footprint 2.4 × 2.0 m. |
| Loaded leg floor corridor | **X10.5..15.5/Z20.5..30.6** | Both hip approaches, tilt/rise and loaded holder; excludes pedestrians during motion. |

Main ground aisles are X8.9..10.4 and X17.65..19.15; front crosswalk
Z2.8..4.3 and gantry crosswalk Z20.5..22.0 connect them. Gate the latter during
rail travel and the left aisle during outboard empty-holder return. The front/right
alternative stays available. Rail crossings are flush, with moving-table gaps
covered/locked before pedestrian crossing. The implemented crosswalk gates hinge
at X8.4/17.6,Z20.5, outside the empty holder's X8.9..17.1 envelope. They swing
outward to open and close along the crosswalk entrances, with swept collision
checks. A separate ground occupancy interlock covers X8.9..17.1/Z20.5..30.6;
entry from another direction stops the rail. The shared crane console is now at
(7.8,0,22.8), clear of both the gate arc and the movable platform's parking berth.

**Equipment count:** one overhead crane/spreader; one transverse rail table;
one leg cradle; one removable arm jig; one adjustable bulky fixture with exchangeable
contact inserts; one mobile work platform; two gantry elevators. Parking pedestals,
source dollies, removable guide beams and contact adapters are passive equipment.
The foot retains its existing supported fixture and dispatch carrier. These have
different physical jobs and do not create a new permanent console for each part.

### Shared limb workshop with different departure routes

**Leg support.** Raise the horizontal leg root from M3's Y1.35 to **Y1.85** for
the complete calf/holder envelope. Home knee is (14,1.85,14.5), root Z9.4.
Use a rear holder spine at robot Y−1.45, bounded −1.55..−1.35, behind the
calf's Y−1.15 rear bound. C-shaped yokes reach structural side pads at robot
X≈±0.80/Z2.80 and Z6.10; they avoid the central calf thrusters, knee axle Z5.10
and fork flange Z6.30. Permanent exposed frame pads avoid a late inaccessible
armor closure. Upper holder extent is robot Z6.30, not the former high contact.

Build contacts engage as their receiving frames are retained. A removable foot
receiving bolster supports the prepared foot before shin frames exist. A temporary
spar rest may guide a crane-held spar, but the crane releases only after its actual
fasteners are secured. The finished frame then supplies both transport hardpoints.
Neither ankle drives nor knee rods carry the transport load.

The sweep uses these leg-local **robot-axis** transport bounds; later internal
workflows must preserve them or reopen the affected route explicitly:

| Loaded region | X about leg centre | Y front/back | Z above sole |
| --- | --- | --- | --- |
| Complete FA-01 foot/guards | ±0.65 | −0.80..+2.20 | 0..1.60 |
| Shin/calf | ±0.80 | −1.15..+0.75 | 1.60..4.60 |
| Knee / thigh | ±0.80 | ±0.75 | 4.60..5.60 /5.60..8.77 |
| Hip ball/collar tip | ±0.45 | ±0.45 | 8.75..9.65 |
| Holder rear spine | ±0.12 | −1.55..−1.35 | 2.65..6.25 |
| Side yokes | ±0.78..1.05 | −1.50..+0.05 | 2.80±0.13 and 6.10±0.13 |

Keep fixed yoke side arms outside |X|0.90 wherever they overlap calf depth;
only the moving contact fingers reach inward to the frame pads. Their0.15 m
opening stroke clears the body before the holder lowers/withdraws.

The cradle is 2.10 m wide normally, 2.30 m with its jaws open. Its bogie is
1.50 × 1.65 m, ≤0.60 m high, on the inherited 1.24 m rail gauge. A flush
transverse table spans **X10.5..23.4/Z13.25..15.75**. It moves the short bogie
while the supported leg overhangs it. Index from common X14 to left X11.9
(−2.1 m), right X14.1 (+0.1 m), or parking X22 (+8.0 m). Align and pin the
track ends before longitudinal movement; retain all four wheel contacts and
anti-tip restraints throughout indexing. Parking movement is horizontal only.

For a robot-local point `(a,b,c)` relative to the leg centreline, the selected
loaded transition is:

```
world.X = lane + a
lower = 0.30 clamp((90deg - theta) / 22.5deg, 0, 1)
world.Y = 0.5 + 1.35 sin(theta) - lower + dock + c cos(theta) + b sin(theta)
world.Z = kneeZ + (c - 5.1) sin(theta) - b cos(theta)
```

First travel knee Z14.5→26 with theta=90° and dock=0; then turn theta90°→0°;
then raise dock0→1.2. The leg root ends at Y1.4. This preserves M3's supported
travel/turn/rise pattern while increasing horizontal floor clearance. Open the
hip front wings and stow the rear hip bridge before travel. The conservative
full leg and cradle sweep reaches Z30.572. The updated payload floor minimum is
0.200 m at the upright pre-dock pose; the original 0.300 m estimate below is
historical. The 0.30 m lowering is an implementation correction from the actual
rear cylinder parking-hook collision during the final turn. It begins only after
rotation starts, reaching full lowering at 67.5°; lowering during horizontal travel
would put the holder bearing into the floor. Source construction height stays1.85.
The implemented structural leg clears these actual solids in the mechanical test;
the complete armored leg envelope still needs its later actual-solid check.
Hold the leg throughout hip retention, cylinders, pins, services and neutral locks.

For rear construction at the station, raise the long rotation axis to **Y3.10**
and roll the supported leg about its long axis. Foot sweep radius is 2.294 m:
X11.706..16.294 and minimum Y0.806. Park the mobile platform and close the work
zone before rolling; work only at locked stops. Restore neutral roll and Y1.85
before indexing. At a stationary work pose, the platform can dock at left
X10.55..12.95 or right X15.05..17.45. Reserve an unobstructed **1.20 m knee-axle
corridor outward**: left axle enters from −X, right mirrored axle from +X.

**Empty holder return is a separate measured motion.** After the hip supports
and restrains the leg, open jaws 0.15 m, lower the fork 0.30 m and withdraw it
**1.40 m rearward**, putting its nearest tip0.20 m behind the calf.
Fold the released side yokes inward to the 2.00 m empty width, then shift the *fork head* 2.00 m outboard, to X9.9 or 16.1; the
bogie remains on its original hip rails beneath the feet. Cross-slide/linkage
height ≤1.0 leaves ≥0.4 m below the raised soles. The outboard mast and rear fork
clear both legs; no extra full-length return tracks are required. Keep the compact
fork within local X±1.0/Y−2.95..−1.35/Z2.65..6.30. Turn it back to horizontal
with root height `1.1 + 2.25 sin(theta)` while returning: its floor margin is
0.40 m and highest point 7.464 m. Re-centre only at home, clear of the robot,
then restore source settings. A loaded cradle never uses this outboard release path.

**Prepared-foot carrier handoff.** At dispatch, keep ankle/forefoot neutral
and the carrier's structural contacts engaged. Raise the upright sole datum
Y1.20→1.85, advance it Z7→9.4, then turn90° about worldX into the horizontal
leg pose. For foot-local `(a,b,c)`, the turn maps to
`(14+a, 1.85+c*cos(theta)+b*sin(theta), 9.4+c*sin(theta)-b*cos(theta))`.
The FA-01 foot box X±0.65/Y−0.80..2.20/Z0..1.60 stays within
worldX13.35..14.65/Z7.20..11.189 during the turn, with minimumY1.05.
The receiving bolster clamps the frame before the carrier releases/retracts;
stow that bolster only after the retained shin/frame supplies the next support.
This is a full-workshop source setting for M3's existing supported handoff pattern,
not a claim that today's carrier already reaches the new datum. No platform or
loose supply occupies the transfer volume during the turn.

**Arm support and parking.** A removable 2 × 9 m cassette carries three adjustable
structural saddles/clamps at arm stations t1.35/4.05/6.05, joint bridge restraints
and the digit cradle. It shares the build bay but not the leg's contact geometry.
A four-end lift moves the whole retained cassette to/from the front parking
pedestals, with its lowest point at least Y4.80. After the arm lifts clear, fold released cassette clamps belowY1.70 before
upending the suspended load. Keep the cassette horizontal;
park any loose parts in stock first. Every partly built member must be positively
held by the cassette before switching bays. Passive parking for **both** carriers
allows a swap without needing a vacant station to hold the displaced carrier.

### Bulky fixture and source access

The shared fixture uses adjustable crossbeams with structural saddles, clamps,
height adjustment and a braked tilt pivot. Change contact inserts for each load;
these are equipment, not robot inventory. Record occupied supports and locks in
future saves. Never release the last load-bearing clamp just to change pose.

| Load | Source support / access setting |
| --- | --- |
| Pelvis/waist | Hip datum (3.25,1.20,13); prepared bounds X±2.01/Y0.49..3.42 including the descending cylinder clevises/catches. Support the bridge's existing bearing patches and hold-down faces, leaving sockets and waist work open. Upper work uses the shared platform. |
| Chest/cockpit | Seat datum (3.25,0.85,13); mapping `(3.25+X, 0.85+Z-11.30, 13-Y)`. Prepared bounds X0.51..5.99/Z11.80..14.35, top Y5.13. |
| Bare chest service pose | Before cockpit insertion, shift the supported seat to (3.25,1.30,14.60), then tilt up to 60° forward about world X. Swept bounds X0.51..5.99/Y0.261..5.788/Z10.293..15.95. Return upright and to the normal seat before inserting the capsule. |
| Cockpit insertion | Supported source dolly/fixture guides, 2.40 m forward approach and 0.05 m final lowering. The front approach reaches Z9.50. No tilting the loaded capsule. |
| Core | Horizontal saddles under structural rings; preserve forward bridge and rear pad access. Use adjustable height/roll to expose connections, then lock for pickup. |
| Backpack | Open 90°, face down on perimeter contacts, clear of nozzles, strut eyes and services. Transfer in that same restrained orientation. |
| Head pieces | Upright structural feet/flange contacts centred X3.25/Z13; baseplate bottom Y0.60, other pieces Y0.85. |

The **one mobile guarded platform** has a stabilized 2.40 × 2.00 m footprint,
clear standing deck approximately 1.20 × 1.40 m and deck settings 1.60–2.40 m
with ground boarding/lowering. The player may ride it, with a hand load, between
docks on the lowered deck; loose loads on the deck block a transfer. It must not need a separate fixed staircase
outside that footprint. Chest side docks are left X−2.15..0.25 or right
X6.25..8.65, leaving 0.26 m to the upright load and the opposite side open for
walking. Front dock Z7.8..9.8 leaves **0.493 m** to the bare-frame tilt sweep.
Rear dock Z14.6..16.6 is used only in the normal upright source pose; stow it
before shifting or tilting the bare frame. Do not draw the one platform in all
positions as if multiple platforms existed. It parks outside both crane pickup
and limb rolling envelopes. Its guards, stabilizers and controls must fit these
bounds; actual footing/stability remains equipment engineering.

### Shared elevator access to hips and shoulders

Move both elevator shafts **behind the shoulder line**, to centres
**(6.6,*,29.0) and (19.4,*,29.0)**. This frees the front bridge swing and puts
shaft structure behind the arms. The same car services ground0.15, hips8.4,
waist11.2, shoulders14.0 and head16.4. With 0.20 m decks the minimum overhead
walking clearance is 2.20 m; car roof/gear must fit within 2.10 m above its deck.

| Access element | Selected world bounds / clear size |
| --- | --- |
| Complete shafts | X5.0..8.2 /17.8..21.0; Z27.4..30.6 |
| Cars | 2.6 × 2.6 m: X5.3..7.9 /18.1..20.7; Z27.7..30.3 |
| Shelf | Inside car's front wall, Z27.8..28.2; 1.50 m wide, left X5.60..7.10/right 18.90..20.40; shelf surface +0.65 above deck |
| Shelf capacity | One two-hand panel up to 1.45 × 0.35 × 1.20 m, or two one-hand parts. Panel top +1.85 fits the 2.10 m roof/gear budget. Car retains a 2.6 × 2.1 m rear turning area. |
| Car doors | Inboard and outboard, 1.5 m clear across Z28.5..30.0. Guides stay in corner bands Z27.4..27.7/30.3..30.6. |
| Outer walks, all elevated levels | Left X3.5..5.0/right 21.0..22.5, Z23.4..37.3; 1.5 m clear, rails add ≤0.10 m outside |
| Rear crossover | X5.0..21.0/Z35.8..37.3; 1.5 m clear, behind the rear lifting well |
| Inboard rear branches | X7.9..9.7 /16.3..18.1; Z28.5..30.0 |
| Rear work flanks, upper levels | X9.7..11.4 /14.6..16.3; Z27.4..30.1 at all three upper levels |
| Aft core fingers, only level 11.2 | Same X bounds, Z31.7..35.8, reached from rear crossover; worker centre ≥Z31.96. |

No inner head-level shortcut passes beside the shoulder. It would obstruct the
arm's vertical crane lines. Walk from the front to the rear via the **outer
perimeter and elevator landings**, keeping the central body and cable wells open.
Both exits connect to useful work paths; opening a cargo bridge never traps a
player on an isolated landing. Normal continuous paths are ≥1.2 m clear, primary
paths 1.5 m. Gates and structure belong outside those widths.

The implemented sliding access barriers stow **inboard**, behind the closed
wings: their parked spans are X5.1..6.6 /19.4..20.9 at Z24.85. They slide across
the outer walks before wing unlocking. Outboard parking would intrude into the
already reserved X23.7 crane-line bypass and is excluded.

**Front bridge motion.** At each elevated level, two 8 m wings run from outer
roots (X5/Z24 and X21/Z24) to X13, with clear width Z23.4..24.6. Floors and
side trusses/rails fit Z23.3..24.7; truss/guard height 1.10 m, floor depth 0.20 m.
Use supported outer hinges and positive centre/outer locks. Each wing swings
90° **forward in plan**. Main stowed strips are X4.3..5.7 and 20.3..21.7/Z16..24;
work fingers telescope into/beneath their wing before it swings. This leaves a
**14.6 m open delivery window** (X5.7..20.3), more than the prepared chest's 5.8 m requirement.
Gate the outer walk before Z24.7 while stowed; its elevator/rear portion remains
connected. Wings move only empty, with the load outside their swept footprint;
close them only after the seated load and all lifting lines clear their sweep.
Extend work fingers only after the main wing is locked. Hip fingers extend1.2 m;
waist fingers use two telescoping stages for2.0 m extension. Both stow inside the
1.2 m wing depth and 0.2 m deck band with rails collapsed. Waist service fingers
stay stowed once arms arrive. These sequenced movements use the same access
configuration; the player does not operate each extension separately.

**Rear hip bridge motion.** At deck 8.4 two 2.9 m bridges run inward from
X10.1/15.9 toX13 acrossZ27.35..28.55. Each has **two 1.45 m leaves**: fold the
inner leaf back above the outer, then raise that stack90° at its root. Folded
guards stay inside the 0.40 m stack thickness; stowed bounds are nearX10.1/15.9
±0.20, Y8.4..10.05. This is below the next deck underside11.0 and outside the
loaded cradle by≥0.45 m. Both leaves fold **upward**, keeping the moving floor
above Y8.20 and clear of the held cradle below. A single leaf folding down
would sweep through the rear holder while closing.
Root aprons X8.2..10.1 /15.9..17.8,Z27.35..30.1 connect to the cars, supported
from lift towers/perimeter without ground posts in rail/empty-fork routes. The
calf ends atZ27.15, leaving0.20 m to the bridge. Closed deck undersideY8.2
clears loaded holder top 7.7 by 0.50 m. Unfold after docking while the cradle
still carries the leg; lock both joints before workers enter for rear pin work.
The bridge's fold height stays below the gantry bearing arms atY10.65.

| Work patch | Deck / eye height | Access and target |
| --- | --- | --- |
| Hip ring | 8.4 /10.03 | Front fingers X9.6..10.8 /15.2..16.4,Z24.3..25.8. Preserve M3 stance near (10.4,8.4,25.4), mirror for right. Far ring bolt about 2.16 m from eye. |
| Hip cylinder pins | 8.4 /10.03 | Front standing Z24.30, rear 27.65, X aligned with target. Lower pins Y8.80, eye distances1.71–2.00 m. Two front/one rear insertion, reserve0.34 m plus tool clearance. |
| Gantry hold-down handles | 8.4 /10.03 | Rear stance X11.6/14.4,Z27.75; fixed handles X11.60/14.40,Y10.80,Z26.55/26.75, below the waist deck and outside the bridge. Approximately1.43 m to the farther handle. |
| Waist bolts / side services | 11.2 /12.83 | Front/rear pockets X12.16/13.84,Y12.80–12.86,Z25.42/26.58. Side fingers X10.35..11.50 /14.50..15.65,Z24.6..26.6 clear the socket crowns; they are used before arms, then stowed before arm delivery. |
| Distal arm rig release | 11.2 /12.83 | Front patch X9.1..11.0 /15.0..16.9 and rear flanks; standing X10.05/15.95,Z24.3/27.7, reach≈1.69 m. |
| Shoulder retention / proximal rig | 14.0 /15.63 | Standing X10.6/15.4,Z24.3/27.7; ring heads≤1.48 m, rig≈1.15 m, drive pins≤1.77 m. |
| Core initial work | 11.2 /12.83 | Rear standing X11.1/14.9,Z27.8; maximum selected flange-bolt reach 2.231 m. |
| Backpack hinge / struts | 14.0 /15.63 | Rear flanks at X11.1/14.9,Z27.75..28.2, selected targets≤1.454 m. |
| Core maintenance re-rig | 11.2 /12.83 | Aft fingers: forward contact/handle from X14.9,Z32.0, distances≈2.14/2.05 m; rear pad from Z32.2≈2.04 m. |
| Head | 16.4 /18.03 | Front X11..15/Z23.4..24.6 and rear flanks. Rear neck bolts≈2.24 m before shells; crown rig≈1.52 m. |

Player body is Ø0.52 ×1.70 m; eye1.63 above deck, maximum interaction reach
2.35 m. Routine targets should be nearer1.8 m. Reach exceptions above require
open tool lanes and clear sight; they are not permission to fasten through solids.
Work-edge gates/guard sections open only for the active supported connection,
with outer guards retained. Do not put a solid toe board across downward hip pin
or ring sight lines. Shared shelves deliver cylinders and small head panels;
local clevis parking catches free the hands for fastening, without another lift arm.

### Gantry support and rear service reservation

Replace the old tall gantry crown with a **low, rear-braced pelvis portal**.
An overhead bar across the rear would intersect the core/backpack crane cables.
Columns centred X8.8/17.2,Z31.1 are0.60 m square, topY11.10. Crosshead bounds
X8.5..17.5/Y10.5..11.1/Z30.8..31.4. Feet occupy
X8.1..9.5 /16.5..17.9,Z30.9..32.5; rear braces stay Z31.4..33.0 near their
columns, outside the work flanks and beyond the elevator shafts.

Two cantilever arms occupy X12.35/13.65±0.18,Y10.65..10.95,Z26.5..31.1.
Bearing caps rise to **Y10.97** at Z26.52..26.78, mating the pelvis bridge
patches. Their undersides leave **2.25 m** over the rear hip deck. Four jaws
contact the selected bridge faces at Y11.23, with complete jaw envelope≤11.30.
Outboard handles at the coordinates above operate linked jaws, so workers see
and reach them beside the beams. Waist locks remain robot hardware, distinct
from gantry clamps. Structural capacity, bracing sections and bearing fits need
engineering; the load path and occupied envelope are now specified.

Keep the rear upper central opening **X11.4..14.6/Z27.2..35.3** clear of fixed
upper floors. The crosshead occupies only its stated lower band. The aft lifting
well is X11.4..14.6/Z31.7..35.3, open vertically to the crane. The closed pack
reaches Z28.2; its normal90° sweep reaches Z30.173, with conservative allowance
toZ30.3/Y16.6. Outer rear flanks remain usable with it open.

For later core service, fit two removable guide rails and **two crossframes**
anchored on the low rear-flank/aft-finger pads at X11.1/14.9,Z29.5 and 32.1.
Crossbeam topsY12.60; guide upstands contact nearY13.05. This supports rails to
Z32.3 without imaginary posts in the central floor opening. Core bottomY12.88
clears the crossbeams by≥0.28 m. A guarded chain/handwheel at robot
(+0.75,−2.75,10.9), before the crosshead, drives the captured carriage. Withdraw
**5.0 m** before vertical crane pickup; re-rig from the aft fingers, then remove
and stow this generic fixture kit. The waist is locked neutral for rear service.

### One crane and measured loaded routes

Useful crane coverage is **X−11..24/Z−7..36**. Runway columns at X−12.5/25.4
(width 0.60) and Z−7/3/19/37 stay outside the work aisles. Keep feet inside the
walls. RoofY25.0, truss underside24.5, bridge 23.70..24.25 and lowest trolley/
fitting **Y23.0** define the overhead budget. Put lights/services above that
limit outside the routes. One configurable two/four-end spreader, lifting shoes,
equalizing bridges and restrained payout serve all loads. These are new capabilities
beyond M3's two-end crane, not claims about current implementation.

| Load | Source-to-destination path, in world metres | Support handoff / access state |
| --- | --- | --- |
| Prepared foot | From (−7,1.2,8), lift sole datumY5.0; move toZ7, across toX14, lower to(14,1.2,7). Keep structural carrier and ankle/forefoot locks engaged. | Guided dispatch carrier hands to temporary leg receiving bolster at rootZ9.4/Y1.85; receiver retains before carrier releases. Preserve the existing foot identity and supported turn. |
| Parked arm cassette | Whole retained cassette lifts with lowest pointY4.8; alongX14 between shoulder Z9.9 and−6.3. | Four lifting ends; parking pedestals/clamps take load before release. This passes ≥0.75 m above the horizontal foot envelope. |
| Pelvis/waist | Hip datum (3.25,1.2,13)→Y10.8→X13→Z26→Y10.6. Prepared bottom during carry10.09, top13.02 including the upper clevises/catches; rig budget≤14.5. | Open front wings11.2/14/16.4. Hip front/rear work decks stay available. Four jaws and waist locks before crane release; restore upper access for rig release. |
| Chest/cockpit | Seat (3.25,0.85,13)→Y12.88→X13→Z26→Y12.70. Rig budget≤18.23. | Open front 14/16.4; waist11.2 stays closed, guard top 12.3 is0.58 below incoming chest. Four bolts and waist locks before release from upper decks. |
| Complete arm | Source shoulder(14,1.55,9.9); raise horizontal toY9.6, perform the restrained upend/yaw/splay below, raise toY14.709, advance toZ19.5, align X10.508/15.492, advance toZ26, seat1.13 m up/in. | Open all four front levels before entering. Keep four ends/taglines tensioned. Close clear wings after seating, complete ring/neutral restraint/drives/services, then release proximal/distal rig and fit armor. |
| Core | From bulky bay, at axisY6.0 cross alongZ13 toX23.7; travel rear to frame-originZ32.4; shift outboard toX24; raise axisY18.47 (lowest point18.0); cross toX13; lower axisY13.35; advance originZ28.2 then insert2.2 m toZ26. | All rear floors stay fixed. Raise outside the outer walks, then cross above their highest guards. At captured-guide engagement0.32 m, transfer forward support before removing its bridge; rear end stays attached through retention. |
| Open backpack | From bulky bay at hingeY5.5, cross alongZ13 toX23.7, move hingeZ31.8, shift outboard toX24, raise hingeY18.0, cross toX13, lower hingeY15.7, advance hingeZ27.2, lower0.2 m. | All rear floors stay fixed. Body during low travelY5.5..6.5; high crossingY18.0..19.0. Hinge pins, strut pins and positive open locks before release. Crane takes weight again before closure. |
| Head pieces | Source X3.25/Z13; raise until **lowest loadY19.0**, cross toX13 thenZ26, lower to the component's specified approach/seat. | Front wings remain closed; transit clears head-level guard top 17.5 by 1.5 m. Highest hookY21.58,1.42 below lowest obstruction. |
| Pauldrons | Source bottomY0.75; lift to **lowest loadY18.0**, route via front distributionZ13 to the shoulder X, thenZ26. Descend over the clear destination to the 1.6 m final approach and seat. | Keep upper platform cable wells open. Body top 19.4 and hook≈20.53; the final approach alone is not the across-workshop carry height. |

**Arm reorientation.** The source axes are u=+worldZ along the arm,
e=+worldY and f=+worldX, with the left jig mirrored. This exposes both rigging
pairs from the two bay sides instead of hiding one pair underneath. The conservative
box is t−0.43..7.45/e±0.55/f±0.75. Source bounds are
X13.25..14.75/Y1.00..2.10/Z9.47..17.35. At shoulderY9.6:

1. Upend90° about worldX: `u=(0,-sin(phi),cos(phi))`,
   `e=(0,cos(phi),sin(phi))`, `f=(1,0,0)`.
2. Yaw the vertical arm90° about worldY, mirrored appropriately:
   `u=(0,-1,0)`, `e=(sin(psi),0,cos(psi))`, `f=(cos(psi),0,-sin(psi))`.
3. Splay15° to its side: final `u=(±sin15,-cos15,0)`,
   `e=(±cos15,sin15,0)`, `f=(0,0,-1)`.

Use continuous constrained motions with four equalized ends and tensioned taglines;
the intermediate yaw is not a free suspended spin. Across both sides the upending
and splay body envelope stays X11.54..16.46/Z8.97..17.371, minimumY2.129.
Reserve1.80 m above the shoulder datum for the spreader/hook. Final seated
rigging planes are Z25.32/26.68, clear of front platforms ending24.7 and rear
platforms starting27.3. Actual cable fan-out must stay inside that clear corridor;
there are no head-side shortcut decks crossing it.

The 2026-10-24 source preflight corrects the final approach offset from 0.65 m
to **1.13 m**. At the earlier height, the ball advanced through the fixed front
drive clevis at t0.64; checking only the axial socket entry missed that transverse
collision. The corrected ball approach is 0.464 m lower and 0.124 m farther
outboard, then seats along the same −u axis. Both mirrored complete-body/full-rig
paths pass against the actual torso, fitted legs, opposite arm, cassette and
parked equipment. The upper rig anchors also stay outboard of the cup.
Actual swivel-end cable centres use f±0.72, 0.04 m beyond the nominal pad faces;
the spreader and cable solids stay within Z25.23..26.77 at the seated pose.
The main spreader is 1.35 m above the shoulder, with its hook top at +1.67 m,
inside the existing 1.80 m budget. These are mechanical source checks, not
walking, reach, rendered review or an implemented arm-installation workflow.

The core's guide handoff also changes the equalizer configuration. At captured
engagement, stow the forward bridge, then fold its unloaded spreader arm and
shift the head aft while the core remains stationary. The compact head clears
the rear spine/cockpit during one-end insertion. Restore the full rig at capture
before refitting the forward bridge for return. Authored dimensions and actual
solid checks are recorded in the [core implementation](../torso/backpack-and-power.md#wider-m3-core-implementation--2026-10-24).

The [backpack source preflight](../torso/backpack-and-power.md#wider-m3-backpack-source-and-route-preflight--2026-10-24)
includes its actual hinge eyes, stowed struts, pad shoes, spreader and all cables.
Hinge-eye material extends0.065 m below/forward of the nominal open-body rectangle,
inside the reserved mechanism/lifting-well margin. Actual high-crossing guard
clearance is0.435 m and lowering-point crosshead clearance0.335 m. The waypoints
above remain unchanged. During closure, the head stays at least2.08 m above the
hinge while the cables pay out; following the lowering pads with a short fixed
drop would put the spreader inside the cover. Player-operated installation and
closure are now integrated, including take-weight, open locks and lower draw
latches. Source/rig preflight and mechanical save/restore checks remain distinct
from the user's walking and connection-access playtest.

**Rear route has a low bypass and an outboard lifting well.** During low
travel at X23.7, core/backpack cable/spreader projection stays within X±0.90
of the route centre. Its inner edge22.8 clears the outer-walk rail edge22.6
by 0.20 m. The pack body reachesX24.9, leaving0.20 m to the right runway column
inner face25.1. Its inner edge22.5 passes *under* the outer walk, with1.70 m
vertical clearance from body top 6.5 to first-deck underside8.2.

**Do not cross inward at this low height:** vertical suspension lines would
intersect the continuous outer walks and aft work fingers. At the rear waypoint
(core frame-originZ32.4 / pack hingeZ31.8), shift the crane centre outboard to
**X24.0**, then raise until the lowest point is **Y18.0**. This outboard lifting
well reserves X22.8..25.2/Z31.7..34.7 throughY23.0, between runway columns
atZ19 and 37. Pack side clearance to the outer-walk rail is0.20 m; its right
edge25.2 leaves0.65 m to the wall, and its rear 34.6 is2.10 m before the next
column. Crane spreader/lines stay withinX23.1..24.9. Core uses this same well.

Traverse inward toX13 **above** the highest guard topY17.5, with0.50 m load
clearance. Core axis is18.47 (flange radius 0.47); its highest rig allowance is
about 20.25. Open-pack hinge is18.0, body top 19.0 and hook about 20.08. Both
fit belowY23.0. Once centred in the rear opening, lower core axis to 13.35 or
pack hinge to 15.7, then approach the robot. At that lowering position, core
frontZ31.75 clears crosshead rear 31.4 by 0.35 m; pack front 31.8 clears by 0.40 m
and its rear 34.6 clears crossover rail front 35.7 by 1.10 m. Its sides leave0.40 m
to the aft work fingers. The rear gantry has no high crown across these lines.
All rear walks/fingers remain fixed and usable outside the excluded cargo well.
Reverse these waypoints for a supported return; do not lower into the crosshead
or drag suspended lines through a walkway.

### Equipment states and interaction economy

| Delivery state | Front wings open | Rear hip leaves | Player route while moving |
| --- | --- | --- | --- |
| Pelvis | 11.2,14.0,16.4 | Closed | Hip level and rear/perimeter routes |
| Leg travel/tilt/rise | 8.4 | Folded up in two leaves | Other levels and rear perimeter; ground corridor gated |
| Leg connection / holder release | None required | Closed | Both front/rear hip work patches, same elevator |
| Chest | 14.0,16.4 | Closed | Waist level, rear and perimeter routes |
| Arm upending/delivery | 8.4,11.2,14.0,16.4 | Closed | Rear/perimeter routes; restore front after seating |
| Core / backpack | None | Closed | Rear flanks and fixed aft fingers; low bypass, outboard lift, high crossing |
| Head / pauldron | None | Closed | Head/shoulder work patches; high transit above guards |

A delivery selects a **shared access configuration**, not eight independent
bridge puzzles. The same Advance/Stop/Return and crane Up/Down/Go vocabulary
operates contextual destinations and supported poses. Before movement, verify
occupancy clear, load retained, route ready and locks engaged; show the actual
reason if blocked. Bridge opening can be part of the guided delivery sequence,
with visible machines and gates. Connections still require walking to the part.
Temporary support exchanges are explicit: take weight → release old support →
move → seat/retain → release equipment. Preserve build identity, interrupted
states and local return; parking does not reset progress or duplicate stock.

## 2. Agree the major-section assembly sequence

The recommended player order remains selected. Preparation can happen independently;
installation prerequisites must represent real support or access constraints.
The table defines prepared deliveries and their receiving work, rather than a
complete inventory of every mechanism inside them. Mechanical dimensions and
hardware allocations belong to the linked component specifications.

| Order | Preparation and handling | Gantry connection / support release |
| --- | --- | --- |
| 1 — Pelvis/waist | Bulky bay: build bridge, both socket housings, yaw/lean mechanism and neutral locks. Prepared envelope **4.02 W × 1.80 D × 2.93 H**, including the descending cylinder clevises and parking catches. Four structural lifting eyes; leave cylinders, rings and guards off. | Seat bridge bearing patches at world Y **10.97** and close four gantry hold-downs. Release crane only with structural support and waist locks confirmed. |
| 2 — Both legs | Shared limb bay: prepare each leg on its rail cradle, with integral hip ball, leg-side lugs and service tail. Index to the appropriate lane; travel, tilt and raise. | M3 ring retention, split stop cage, three hydraulic cartridges/six eye pins, positive neutral locks and services. Keep rail support through this work; withdraw empty cradle, then close guards. Repeat on the other side. |
| 3 — Chest/cockpit | Bulky bay: upright frame with retained cockpit, refitted front ties, sockets and fixed neck. Current width **5.48 m**, depth **2.55 m**; height **4.28 m**, including the keyed neck tip. Four structural crane pads. | Seat at world Y **12.70** through **0.18 m** final lowering. Fit four M36 bolts/washers, verify support/waist locks, detach rigging, connect side services and close connection areas. |
| 4 — Power core | Shared fixture: horizontal **Ø0.84 m** cartridge, **Ø0.94 m** rear flange, **1.81 m** total axial bounds. Crane supports the initial rear approach at world Y **13.35** axis height. | Advance **2.20 m** towards the front. At 0.32 m captured-guide engagement transfer forward support to the guide, then seat flange, secure four captive bolts and rear interlock before final crane release. |
| 5 — Backpack | Bulky bay: prepare **2.40 W × 2.80 H × 1.00 D** pack on perimeter supports in its 90° open orientation. Reuse crane and adjustable spreader. | Approach hinge 0.20 m high, lower, fit two hinge pins and two strut-base pins, lock both open struts, release crane and connect services. Reattach crane for controlled closure, seat both locators and latch. |
| 6 — Both arms | Shared limb bay: connected upper arm, forearm and hand; shoulder armor off. Restrain elbow/wrist/digits. Crane lifts horizontal shoulder datum to world Y **9.60**, then performs the guided upending motion. | Align the ball **1.13 m** down/out from its seat, advance up/in, retain split ring, establish neutral restraint and complete actuation/services. Release crane from accessible pads; fit pauldron. Repeat opposite arm. |
| 7 — Head | Small sensor preparation at bench; reusable supported fixtures and crane for larger shells. Build on the torso's fixed neck, with arms and backpack already fitted. | Baseplate → sides/rear wraps → structural top → sensors/connections → front faceplate → mask → decorative crown. Each lifted piece is retained before rigging release; keep front sensor path open until its work is complete. |

### First delivery: pelvis and waist

The [pelvis specification](../torso/pelvis-and-waist.md) owns sockets, bearing
patches, hold-down faces, lifting eyes and waist locks. Build this unit on the
bulky fixture, leaving leg rings/cylinders/guards off. The crane puts its bridge
on the new Y10.97 contacts. From the rear hip deck, operate the four outboard
jaw handles and verify waist locks. Restore access above only when the load/rig
clears the wing sweep; detach the four lifting adapters from the 11.2 level.
The robot is then supported independently of the crane.

### Both legs: rail delivery and hip completion

Retain M3's Ø0.90 ball/Ø0.30 neck, socket, interchangeable ring halves and four
upward M24×140 bolts/washers per hip. Complete leg-side lugs/services at the
station. Use the rail route above, then close the hip access bridges while the
cradle remains engaged. Fit ring, stop cage, three cylinders/six eye pins,
services and positive neutral locks. Cylinders ride the finite shelf and use
local clevis catches/resting saddles. Only then execute empty-holder withdrawal
and close guards. The opened holder leaves0.25 m to the first leg's conservative
±0.80 m body bound on the 2.20 m-spaced lanes. Enforce the selected transport
bounds through later armor design; a wider calf requires revisiting this route.

The wider M3 implementation now exercises both structural legs through this
route, with distinct mirrored source/receiving geometry and independent retention.
Both prepared feet begin on separate bay supports, at sole datums(−7,1.2,8)
and(−7,1.2,13). Four magnetic contacts use the exposed FA-100 rail tops at
foot-root X±0.50/Y−0.36/Z−0.20 and1.20. The crane takes support, lifts the sole to
Y5.0, moves toZ7, crosses toX14 and lowers onto the dispatch carrier. The carrier
returns empty after seating each foot; selecting another leg never moves an
occupied build. Source-rack right-side frames start0.7 m behind their left partners
to separate the exposed1.6 m crossmembers. These are mechanically checked blockout
details; walking, rigging access and connection usability await the user's playtest.

### Chest delivery: prepared frame and cockpit

The [chest specification](../torso/chest-and-cockpit.md) and
[packaging drawing](../torso/chest-and-cockpit-layout.svg) own the lower core
portal, capsule allocation and removable ties. Build the bare frame using the
supported tilted service pose, return it upright, insert/retain/connect the
capsule, refit ties, then lift the prepared unit. Four M36×160 bolts plus6 mm
washers retain it after 0.18 m lowering. Keep the crane attached and waist locked
until those fasteners are complete. Upper front/rear patches reach the reusable
lift-shoe handles;11.2 m side fingers reach waist services before the arms arrive.

### Rear modules before arms and head

The [core/backpack specification](../torso/backpack-and-power.md) owns capture,
retention, hinge, struts and services. The low outboard bypass, outboard lift/high crossing and aft lowering
well serve both deliveries without an overhead gantry obstruction. The core's
forward equalizing bridge detaches only after captured guides take that load;
complete flange retention/interlock before rear crane release. For the open
backpack, complete hinges and both locked struts before release, connect service
loops from rear flanks, then re-rig for controlled closure and latching.

Later core removal uses the reusable supported 5 m withdrawal described above,
with the complete robot fitted. This access provision does not reopen the
user-stopped full teardown acceptance investigation.

### Arm delivery: connected upper arm, forearm and hand

The [shoulder/arm specification](../arms/shoulder-and-upper-arm.md) owns the
angled socket, ring, actuators, rigging points and restrained hand envelope.
Build one connected arm on the shared cassette. Lock elbow/wrist/digits and
attach all four ends from visible side faces; take weight before unclamping.
Follow the continuous upend/yaw/splay route and 1.13 m up/in socket entry.
After seating, restore clear front bridges, fit ring and neutral restraint,
complete drives/services, then release proximal rig at 14.0 and distal rig at 11.2.
Fit the pauldron afterwards using its high carry route and front/rear tool faces.
The first arm remains restrained while the second is delivered.

Complete restrained hands occupy worldX8.582..17.418, with0.382 m lateral
clearance to shaft boundaries; the corrected pre-seat offset reduces the lateral
projection gap to approximately 0.090 m. Shaft depth Z27.4..30.6 independently
leaves at least 0.65 m behind the conservative arm depth around Z26, preserving
the 0.20 m minimum clearance to actual shaft structure. Keep
shelves, guides and cables inside the shaft reservation through **all** lift levels.

### Head construction at the gantry

The [head specification](../head.md) owns the exact order:
fixed spoke → baseplate → sides/rear wraps → structural top → sensors/connections
→ front faceplate → mask → decorative crown. Mount all head pieces from 16.4 m
work patches. The top leaves the front sensor slide accessible. Carry face/mask
on the shared shelf; crane the larger shells and crown on structural pads.
Use the outer perimeter to reach rear patches. No closely stacked extra lift
stop or platform through the shoulder/rigging corridor is required.

## 3. Design status and next implementation boundary

### Recommended next design passes

The five component-interface passes and this coordinated fixture/route pass are
complete **at dimensioned-envelope level**. The layout now includes real support
contacts, source work poses, carrier quantities, parking transfers, both hip lanes,
empty return, moving bridges, elevator/shelf volumes and cargo waypoints. The
selected changes are integrated into existing component documents and drawings.

Next, implement the [M3 wider-workshop blockout](m3-wide-workshop-plan.md)
before detailed component workflows. Replace M3 in place, build both simplified
structural legs, and exercise the major-section routes with prepared stand-ins
and representative mounting work. The user owns walking and connection-access
playtesting; automated checks cover mechanical movement, support, content and saves.
Detailed leg/arm/torso mechanisms follow that broader workshop experience.

Before runtime expansion, author a single shared equipment blockout from these
coordinates and compare its actual solids, tool cylinders, worker capsules and
cables against the routes. Prioritize leg support/empty return and pelvis/clamp
access, then chest source/delivery, then arm/rear/head overlays. Structural
capacity, real mass/rigging balance, wheel/tilt mechanisms and guard design remain
engineering work; the rectangles alone do not certify them.

### Validation and evidence scope

The coordinated pass reviewed component interfaces and sampled conservative
payload/holder boxes at 0.1° angular steps (source roll at 1°), plus route and
reach arithmetic. Rear crane routes were also sampled at≤0.025 m translation
steps with separate body and rigging prisms against conservative fixed platform,
guard, shaft, portal, column and wall boxes; both complete routes passed. These
checks reject a low inward cable crossing through the outer walkway. Pelvis and
chest front deliveries also passed sampled equipment-box checks, using the
chest’s separate frame/socket/root bounds rather than fictitious box corners.

| Bounded check | Result / limiting margin |
| --- | --- |
| Full leg tilt, including rear spine/yokes | Original minimum floor0.300 m, revised to0.200 m by the supported lowering correction above; rear limitZ30.572 unchanged |
| Second leg with first fitted | 0.250 m lateral gap to opened holder |
| Empty fork turn/return | Minimum floor 0.400 m; highestY7.464 below rear hip deck underside8.2;1.40 m withdrawal clears the calf before sideways movement |
| Supported leg source roll | Minimum floor 0.806 m; X11.706..16.294 inside shared bay |
| Bare chest60° service sweep | Minimum floor 0.261 m; front platform gap 0.493 m |
| Complete-arm guided upend/yaw/splay | Minimum floor 2.129 m; body remains within shared bay's lateral envelope |
| Low rear bypass | 0.200 m cable-to-walk and body-to-column margins;1.700 m below first deck |
| Outboard lift / high crossing / aft lowering | Pack clears outer-walk rail by 0.200 m; high crossing clears highest guard by 0.500 m. Central lowering clears crosshead by 0.350/0.400 m and rear crossover by 1.100 m |
| Rear hip bridge folding | Upward two-leaf floor sweepY8.20..9.864, above held cradle top7.70 and below next floor11.0 |
| Rear hip walk under bearing arms | 2.250 m headroom |
| Highest head hook | Y21.580;1.420 m below lowest overhead obstruction |

These bounded checks are not continuous mesh collision detection, manufactured
fits, every connection's occlusion proof, gameplay tests or human playtest approval.
The retained M3 hip access regression establishes only its existing structural
connection. The user will playtest walking, visibility, reach and connection
access through ordinary controls. Automated adaptation checks cover content,
movement, support, interlocks and interrupted saves; they do not run walked
acceptance or access sweeps. No runtime tests or
rendered-game review were run for this documentation change.

Keep future intermediate calculations/captures in temporary or ignored verification
storage. Record one compact result in the relevant milestone; maintain these
canonical documents/drawings rather than adding parallel verification narratives.

Sources: [M3 layout](../../game/workshop/assets/leg-bay-m3-layout.json),
[layout structure](../../game/workshop/scripts/leg_bay_layout.gd),
[leg interfaces](leg-prototype-interface.md),
[player controller](../../game/workshop/scripts/player_controller.gd),
[pelvis](../torso/pelvis-and-waist.md), [chest](../torso/chest-and-cockpit.md),
[core/backpack](../torso/backpack-and-power.md),
[shoulder/arm](../arms/shoulder-and-upper-arm.md), [head](../head.md).
