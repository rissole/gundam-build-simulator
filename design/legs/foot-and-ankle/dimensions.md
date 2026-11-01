# Foot and ankle — dimensional layout FA-01

Revision: FA-01, incorporating FA-01-3D-01 refinements · 2026-10-21

[Component overview](../foot-and-ankle.md) · [Parts](parts.md) · [Actuators](actuators.md) · [Assembly and review](assembly-and-review.md)

These are assistant-selected working dimensions under the user's instruction to proceed with recommendations. They preserve the confirmed construction and overall proportions. All dimensions here are **millimetres**, with angles in degrees. They describe fictional reference geometry, not production tolerances or a load-rated machine.

## FA-02 revision (2026-11-01)

> **Modelled 2026-11-01:** [LG-01-3D-01](../../../models/leg-lg01/README.md) contains the complete FA-02 foot.
> Model-settled relief and clearance values below supplement this revision; the FA-01 sections remain historical interfaces, not full solid-clearance evidence.

This section supersedes **only the listed dimensions and part-number mappings** for
FA-02. The FA-01 sections below remain intact as interface/mechanism history.
[Approved proportions](../../proportions.md#legs-and-feet) govern the envelope;
[foot-components.csv](foot-components.csv) is the FA-02 physical inventory and
[the FA-02 sheets](images/README.md) guide appearance, not measured geometry.
Units are **mm**. Left foot master: ground beneath ankle is (0,0,0), +X inner,
+Y forward, +Z up; mirror X for the other foot. Neutral pose and rotation signs
remain as below. These are reference-design decisions, not manufacturing limits.

### Scaling rule and fixed interfaces

Plan positions start from X × 1460/1300 = **1.1230769**, Y × 3360/3000 =
**1.12** about the ankle, then are rounded to useful 5/10 mm coordinates. Explicit
values here win over applying the factors again. Outer ends are pinned to the
approved −900/+2460, rather than the raw scaled −896/+2464. Sections, wall
thicknesses, bolt diameters/lengths, bearing stacks and all Z values remain fixed;
rail lengths, transverse spans, seat positions and cover/pad plan outlines grow.
The frame is not a uniformly scaled solid. Integral arms connect widened frame
seats to the unchanged ankle core. No additional physical components or bolts.

| Datum / retained interface | FA-02 value |
| --- | --- |
| Neutral outer envelope | X −730…730; Y −900…2460; length 3360, width 1460 |
| Ankle pivot C | (0,0,1000), unchanged |
| Forefoot hinge H | (0,1340,350), axis X; +140 in Y |
| Main shell / guard maximum | Z700 / Z1600, unchanged |
| Shin flange / bolt centres | Mating plane Z1380; X±200, Y±150; four M36×90 and W-36 |
| Adapter flange / key | 520×440×60, Z1320…1380; key180×100×20, unchanged |
| Ring / adapter / ankle journals | All FA-200…209 envelopes, bores, pin lengths, bosses and bearing stacks below unchanged; ring X±440, Y±360, Z940…1060, opening X±300/Y±220 |
| Fixed cradle cheeks | X450…550 and −550…−450; Y−140…140; Z800…1150, unchanged |
| Articulation | Pitch −20…20°, roll −10…10°, forefoot 0…30°, unchanged |
| Lower shin / tool corridors | Beam300×200, baseplate Z1380…1410; four Ø80×120 socket corridors; armor starts Z1650, first450 high stays within900×900 |
| Stance / axle removal | Ankle spacing2200; foot inner gap740; preserve1300 clear workspace OUTSIDE the outer foot for axle extraction |

### Frame limits and bolt-centre schedule

All rail box sections remain180×240, walls20, rail Z200…440, chamfers20.
Crossmember bodies retain their fore/aft section depths (200 rear/front,160 toe),
Z200…440; their transverse spans and integral seats grow. Limits below include
listed connection lands but not separately stated local hinge ears/clevis arms.

| Part / quantity | FA-02 plan limits and placement |
| --- | --- |
| FA-100-A/B rear rails, one each | Centres X±560; inner rail X470…650, outer rail X−650…−470; Y−785…1265, length2050 |
| FA-101 rear crossmember | X−650…650; Y−660…−460; end seats at X±395 |
| FA-102 front crossmember | X−650…650; body Y1020…1220; local fixed hinge supports extend toY1420 around H |
| FA-103-L cradle feet / outriggers | Four feet centred X±395,Y±110; each land X centre±60,Y centre±40,Z390…430. Open arms reach the unchanged cheeks; integral outer truss reaches fixed pitch eye (−540,800,480). No solid underside block |
| FA-104-A/B forefoot rails, one each | X/Z as rear rails; Y1500…2440, length940 |
| FA-105 toe crossmember | X−650…650; Y2270…2430; end seats at X±395 |
| FA-106 hinge beam | Main beam X−450…450,Y1425…1545,Z220…480; mounting feet extend Y1500…1680 to seats X±395; moving lugs project rearward to H |
| Rail ledges and joint lands | Ledges X335…470 and mirror,Z350…390; widened inward to put bolts atX±395 while meeting rail inner faces±470. Joint lands X335…455 and mirror,Z390…430; keep5-deep locating tongues clear of bolt bores |
| FA-107-A nut plates, four | 80 wide×200 long×54 thick, hole pitch110; centres (±395,−560) and (±395,1120) |
| FA-107-B nut plates, two | 80×310×54, hole pitch220; centres (±395,0) |
| FA-107-C nut plates, four | 80×180×54, hole pitch90; centres (±395,1590) and (±395,2350) |

Nut plates stay atZ296…350. M36 frame bolt under-head planeZ436, tipZ296;
6 mm washer,40 mm land,40 mm ledge,54 mm thread engagement unchanged.
For each nut plate place its two M12 keeper axes at (plate centre X±55,
plate centre Y); integral lateral ears provide10 mm lands atZ350…360, leaving17.5 mm
thread engagement after the2.5 mm washer.
These ears, pockets and screw approaches must stay outside the M36 bores.

| Connection / owner | FA-02 bolt centres in foot X,Y | Count / hardware |
| --- | --- | --- |
| Rear crossmember / rear rails | X±395; Y−615,−505 | 4 H-36140 |
| Front crossmember / rear rails | X±395; Y1065,1175 | 4 H-36140 |
| Cradle / rear rails | X±395; Y−110,110 | 4 H-36140 |
| Hinge beam / forefoot rails | X±395; Y1545,1635 | 4 H-36140 |
| Toe crossmember / forefoot rails | X±395; Y2305,2395 | 4 H-36140 |
| Nut-plate keepers | For each of10 centres above, Xcentre±55,Ycentre | 20 H-12030 |
| Rear carrier / rear rails | X±560; Y−670,170,1040 | 6 H-24070 |
| Forefoot carrier / forefoot rails | X±560; Y1640,2280 | 4 H-24070 |
| Shin flange | X±200; Y±150; unchanged | 4 H-36090 |

The forefoot bearing stack is an explicit exception to lateral scaling: preserve
fixed lugs X460…580 and mirror, moving lugs X310…450 and mirror, journalØ120
spanningX−580…580, bushings140 long and washers8 thick in10 mm gaps. Translate
all to H atY1340; extend their integral arms to the new beam/frame, do not stretch
the bushings or axle. FA-210 remains1160 journal/1185 extraction length. Beam rear
faceY1425 is85 ahead of H, leaving25 to the Ø120 axle surface (was15).

### Actuator endpoints, stops and services

Actuator internals, eye sizes and pin-to-guide lengths in [actuators.md](actuators.md)
are unchanged. The pitch **clevis eyes are not scaled**: extend the cradle's
outrigger/receiving arms to the widened frame, retaining the original eyes.
Roll stays wholly on the unchanged ring/adapter. Forefoot needs a controlled
translation: keeping its old fixed eye atY650 while moving H140 forward would
make its neutral length751.66, outside its640 usable maximum. Therefore translate
both forefoot eye trajectories +140Y; keep its lever vector and internal stroke.
This is the only actuator placement exception to the default of fixed clevis eyes.

| Drive | FA-02 neutral base eye | FA-02 neutral rod eye | Neutral eye-to-eye / change | Required range |
| --- | --- | --- | --- | --- |
| Pitch | (−540,800,480), cradle | (−540,300,1000), ring | 721.39 / 0.00 | 665.31…809.97 within640…860 |
| Roll | (500,−450,850), ring | (200,−450,1320), adapter | 557.58 / 0.00 | 496.48…615.20 within480…640 |
| Forefoot | (0,790,520), front-frame clevis | (0,1400,570), H+(0,60,220) | 612.05 / 0.00 | 494.55…612.05 within470…640 |

These lengths follow the written rotation transforms, not image pixels. Six
FA-220 brackets retain two M24×70 each and unchanged eye/pin stacks. Bracket
arms/receiving ears can change while eyes remain at these coordinates; their
mounting pairs use the original local keyed interface, not globally scaled holes.
Pitch/roll stops remain on their unscaled joint datums. Forefoot stops and contact
lever translate+140Y with H, retaining X≈220, local(Y60,Z220),0°/30° contacts,
140×80 flanges and80 mm bolt pitch. All six stops keep two M24×70 each.

The controller box remains X150…450,Y650…950,Z460…620, with300×300×160 body.
Extend its integral frame ears to meet the new frame. Keep four box screws, four
lid screws, four board screws, four box sockets, three actuator sockets and twelve
clips. Harness lengths2200/1800/2200/900 remain trim-to-fit allowances, not a proved
routing solution; preserve100 minimum loop radius and300 free cable per ankle
crossing. Recheck the shifted forefoot branch route in the source-model stage.

### Sole limits, pads and underside bolt centres

| Part / pair | FA-02 X limits | FA-02 Y limits | Z / size |
| --- | --- | --- | --- |
| FA-300 rear carrier | −685…685 | −850…1230 | Z140…200;60 thick |
| FA-301 forefoot carrier | −685…685 | 1470…2450 | Z140…200;60 thick |
| FA-302 heel pads,2 | −695…−25 and25…695 | −850…−110 | Z0…140;670×740×140 each |
| FA-303 midfoot pads,2 | Same as heel pair | −70…1220 | Z0…140;670×1290×140 each |
| FA-304 forefoot pads,2 | Same as heel pair | 1480…2440 | Z0…140;670×960×140 each |

The central pad gap rounds to50; pads overhang carrier edges10. Tread grooves
remain30×12 on120 pitch, ending40 from edges; pad bevel20. Each pad still has
four corners with bolt centres100 inward, twenty-four sleeves total.

| Pad pair | X bolt coordinates (two per pad) | Y bolt coordinates | Count |
| --- | --- | --- | ---: |
| Heel | Outer pad−595,−125; inner pad125,595 | −750,−210 | 8 |
| Midfoot | Same | 30,1120 | 8 |
| Forefoot | Same | 1580,2340 | 8 |

Pad bolts stay M24×120 pointing upward, under-headZ60; washersZ60…64,
ID26/OD42×76 sleevesZ64…140,40 engagement. Carrier bolts stay M24×70,
under-headZ168, washerZ168…172, landZ172…200,38 engagement. Pad and carrier
holes are distinct: carrier Y centres deliberately depart from simple scaling
to separate theirØ56 counterbores from pad threaded holes/sleeve axes; minimum
plan centre distance is69.46 (35 lateral,60 longitudinal). A naive rounded scale
would put some centres only35 apart. Preserve this offset in the solid model. Access remains from below:
remove pads to expose carrier fasteners.

### Shell look, limits, ownership and removal

Match the approved turnaround feet: angular chamfered/faceted plates, broad warm
off-white **#D2C8BC**, gunmetal **#4C4C4B** frame/sole carriers, dark rubber tread,
small red **#C2332A** caution bars and a safety-ochre **#D4861D toe accent band**.
Ochre is paint on the toe cap, not an extra inventory shell. No foot nozzles or
bronze accents. Broad60…120 visual edge facets must be formed in the shell outline,
not a bevel larger than its20 mm material thickness. Use sparse25-wide panel
lines and recessed hex wells; avoid an invented crowd of separate cover plates.

| Shell | FA-02 envelope / relief | Owner / removal |
| --- | --- | --- |
| FA-400 toe cap | X±730; rearY1500/Z600 toY2400/Z520, chisel tipY2460/Z400; lowerZ200,20 thick; chamfer plan corners inward | Forefoot; upward+Z |
| FA-401-L upper foot plate | X±730; Y−500…1210; topZ700/underside680; rear-open notch X±590 fromY−500 to550. Outer actuator relief stays X−620…−450,Y550…870 because pitch actuator stays fixed | Rear frame; upward+Z around attached shin |
| FA-402 heel cover | X±730; Y−900…−500; Z200…600; open front meets upper-plate boundary | Rear frame; rearward−Y |
| FA-403-L inner ankle guard | Outer wallX730, inner wallX710; Y−730…950; Z600…1600; faceted lateral outline within these bounds | Fixed cradle; inward+X |
| FA-404-L outer ankle guard | Outer wallX−730, inner wallX−710; Y−730…950; Z600…1600; mirrored lateral wall with outer service details | Fixed cradle; outward−X |

Guard walls remain20 thick, now1420 apart internally. Both ends and the top of
the guard pair remain OPEN. No armor roof, bridge or stiff crossbar across the
moving shin. Fixed upper plate endsY1210; moving toe startsY1500; the290-wide
hinge channel includes H at1340 and must not be bridged. All five shells retain
two10-engagement sliding tabs and four captive M12×50 bolts/retaining collars.
Thirty-thick lands, washers and17.5 engagement are unchanged. Integral receivers
must meet the following selected neutral bolt axes; four per shell, no extras.

| Shell attachment axes | Four FA-02 centres / head approach |
| --- | --- |
| Toe cap | X±560 atY1630 and2310, vertical axes; heads above roof lands |
| Upper plate | X±650 atY−300 and1060, vertical axes; outside notch and fixed actuator relief |
| Heel cover | X±560 atZ300 and500, Y−900 rear-face axes; rear access |
| Inner guard | X730, (Y,Z)=(-600,720),(700,720),(-500,1450),(500,1450); lateral axes, inner access |
| Outer guard | X−730, same(Y,Z); lateral axes, outer access |

Guard receiver arms extend from the fixed cradle at those sites; keep them outside
the moving core, pitch actuator and the open tool corridors. Their contour and
all shell lands/tab sweeps remain source-model checks; dimensions select intended
seats, not already collision-tested solids.

### Model-settled relief and clearance — 2026-11-01

All values here are **mm**. Keep the flat upper roof/underside Z700/680 and
rear-open X±590 notch to Y550. Three relief slots per side start at absolute
X625 and span Y−540…−440, +460…+540 and +660…+830. Integral cradle backbones
run at X±650/Z580, Y−650…+790. Together they give a conservative 16.00 mm
plate/cradle separation over the full 3000 mm vertical removal; no contact waiver remains.

Toe locator tabs are centred (±680,1850,472.889), sockets 15 mm below, with
10 mm engagement and measured side/roof gaps 5.00/9.69 mm. Bolt axes are unchanged.
Guard walls remain at absolute X710…730 and top Z1600, with 400 × 360 windows
at Y0/Z1000 and a 320 mm crown. These refinements retain all five shells and hardware.

The earlier 900 × 900 lower-shin armor box is superseded for this model by the
revised calf taper and measured guard checks: 38.76 mm sampled clearance,
6.495 mm continuous vertex/edge lower bound. The 300 × 200 structural beam stays.
Full swept-facet articulation, general tool access and existing shell/rail contacts
remain open; see the [model notes](../../../models/leg-lg01/MODELING_NOTES.md).

### FA-02 part-number and compatibility mapping

The CSV uses exactly the leg-list columns; its source paths are relative to
`design/legs/` (as requested, e.g. `foot-and-ankle/parts.md#frame`). `qty_per_leg`
means one complete foot, including its four shin bolts. No FA-500 assembly objects
are added. Hardware is one row per **use and part**, so identical hardware IDs
repeat with use-qualified names; they remain one compatible hardware type.

| FA-01 working family / suffix | FA-02 IDs and decision |
| --- | --- |
| FA-100-IN/OUT; FA-104-IN/OUT | -A/-B, one each: A has ledge on its +X side (outer rail of left foot), B on its −X side (inner rail). These are distinct ledge orientations, not loose instance numbers. Mirror the pair by exchanging A/B for the right foot; neither means left/right foot handedness. Keep common section and fore/aft hole pattern |
| FA-101/102/105/106 | Retain numbers; centred, laterally symmetric interfaces. Local electrical mounting provision is paired so mirroring does not require another counted bracket |
| FA-103 | FA-103-L for true left-foot outer-outrigger geometry; right-foot counterpart FA-103-R |
| FA-107 | -A crossmember plates×4, -B cradle plates×2, -C forefoot plates×4; lengths/pitches differ as tabulated |
| FA-200…213 | Retain numbers and family quantities; pins/bushings/caps are reusable rotated copies; axle inserted from outer side, not a separately handed axle |
| FA-220 six location variants | -A pitch cradle, -B pitch ring, -C roll ring, -D roll adapter, -E forefoot fixed, -F forefoot lever; one each, with symmetric keyed local receiving interfaces; mirrored placement uses the same bracket type |
| FA-221/222 | -A pitchØ50 pins/keepers×2, -B roll+forefootØ40 pins/keepers×4; same-sized eye interfaces share copies |
| FA-230 six angular variants | -A pitch rear limit, -B pitch forward limit, -C roll outer limit, -D roll inner limit, -E forefoot flat, -F forefoot raised; one each. These describe stop angles/functions, never use -R for rear or roll |
| FA-300…305 /400/402/405 | Retain numbers; symmetric carrier/pad/hardware shapes and toe/heel shells. Pair pads are interchangeable copies, not separate handed IDs |
| FA-401/403/404 | FA-401-L/403-L/404-L: asymmetric relief/tab/service layout mirrors for right foot as -R on the same base number; inner/outer guard families retain their separate ownership names |
| FA-510…523 actuator pieces | -A pitch, -B roll, -C forefoot, one each per family. Reserve distinct packaging/fit variants even when a bore diameter happens to match; do not infer interchangeability without the later solid interface audit |
| FA-524 collar halves | -A/B pitch clearance-hole/threaded half; -C/D roll equivalents; -E/F forefoot equivalents; one each |
| FA-525 eye housings | -A/B pitch base/rod; -C/D roll base/rod; -E/F forefoot base/rod; one each |
| FA-526/527 | -A pitch bearings/rings×2; -B roll+forefoot bearings/rings×4; share the same specified eye size |
| FA-528 /530 | Common end sensors×6 / common actuator sockets×3; locations do not create variants |
| FA-529 gaskets | -A/B pitch front/rear; -C/D roll front/rear; -E/F forefoot front/rear; one each |
| FA-600…604/607 | Retain IDs; unchanged housing/lid/gasket/controller, four sockets and twelve interchangeable clips |
| FA-605 /606 | FA-605-L matches existing handed main-harness convention (right FA-605-R); FA-606-A pitch1800, -B roll2200, -C forefoot900 branches, one each; branch routing flexes, length/connectors distinguish them |
| Hardware from hardware.csv | Retain all IDs, including H-12050-C captive variant; one optional suffix only. Counts and hardware.csv unchanged |

All IDs match `[A-Z]+(-[A-Z])?-[A-Z]?\d+(-[A-Z])?`. Only true foot-handed
parts use -L/-R; the left-foot CSV lists -L only. Variants of one family use
-A/-B/etc, never doubled suffixes or words such as -IN/-OUT. Mapping is a
concept-level compatibility decision; it does not modify existing game IDs.

### Review plan and evidence boundary

The [notes](images/notes-fa02.md) record the inventory validation and inspection of
the generated sheets. Preserve the existing assembly dependencies: nut plates
before frame bolts, core/pins before closures, sleeves before pad bolts, accessible
wiring before upper-plate closure. The forefoot owns its rails/beam/carrier/two
pads/toe shell; the fixed cradle owns both guards. Hardware allocations stay745
objects total. No game/source-model geometry changes are part of this revision.

Next source-model checks: verify the20 scaled frame bolt seats,10 carrier seats,
24 pad seats and20 shell seats; unscaled ankle/shin mating interfaces; translated
forefoot eye/stop trajectories; pad versus carrier counterbore clearance; full
joint sweeps, bracket/guard/tab contacts, extraction/tool paths and flexible harness
loops. The FA-01 review script still describes FA-01 and must not be run or cited
as FA-02 clearance evidence. Analytical actuator length preservation is narrower
than collision-free solids or successful playable assembly.

## Coordinates and movement

Use the **left foot** as the master. X points toward the robot's right, Y forward, Z upward. The origin is on the ground directly beneath the ankle. Thus +X is the inner side of this foot. Mirror X for the right foot, including brackets, wiring and axle extraction direction.

| Datum | Value |
| --- | --- |
| Outer foot envelope, neutral | X −650…650; Y −800…2200 |
| Ankle pivot C | (0, 0, 1000) |
| Forefoot hinge H | (0, 1200, 350), axis parallel to X |
| Neutral shin flange mating plane | Z 1380 |
| Main foot armor height | Up to Z 700 |
| Side guard top | Z 1600 |
| Lower shin armor start | Z 1650 in neutral |

Positive ankle pitch φ leans the shin forward: rotate the ring by **Rx(−φ)** about C, −20° ≤ φ ≤ 20°. Roll ρ rotates the adapter by **Ry(ρ)** within that ring, −10° ≤ ρ ≤ 10°. Apply roll first, then pitch. Forefoot rotation is **Rx(θ)** about H, 0° ≤ θ ≤ 30°, lifting the toe.

These are independent reference ranges. They are not a walking or balance specification. Global ankle spacing remains 2200 mm; see the [whole-robot layout](../../proportions.md).

## Frame pieces and bolted seats

Part identifiers are defined in the [inventory](parts.md).

| Part | Working geometry / placement |
| --- | --- |
| FA-100 rear rails, two | Centers X ±500; rectangular box section 180 wide × 240 high; Z 200…440; Y −700…1130; 1830 long |
| FA-101 rear crossmember | End connection region Y −600…−400; spans both rails |
| FA-102 front crossmember | Main connection region Y 900…1100; integral hinge support lugs extend to Y 1280 |
| FA-103 fixed cradle | Four seated feet at X ±350, Y ±100; side cheeks X 450…550 and −550…−450, Y −140…140, Z 800…1150 |
| FA-104 forefoot rails, two | Same section and X/Z positions as rear rails; Y 1340…2180; 840 long |
| FA-105 toe crossmember | End connection region Y 2020…2180 |
| FA-106 rear hinge beam | Central beam X −400…400, Y 1275…1395, Z 220…480; end mounting feet extend into Y 1340…1500 |
| FA-107 two-hole nut plates | Ten plates, all 80 wide × 54 thick: four rear-crossmember plates 180 long / 100 mm thread pitch, two cradle plates 280 long / 200 mm pitch, four forefoot plates 160 long / 80 mm pitch; two M12 keeper screws per plate |

Rail walls are nominally 20 thick, with reinforced solid bosses around threaded holes and ledges; these wall sizes are visual construction choices. Outside corners have 20 mm chamfers.

Rail ledges occupy X 290…410 on the inner rail and its mirror on the outer rail, Z 350…390 at connection seats. Crossmember/cradle feet have 40 mm thick bolt lands, Z 390…430. Add 5 mm deep locating tongues outside the bolt lands, seated in matching recesses. The tongues locate parts; they do not replace bolts.

Frame bolts point downward. Their under-head plane is Z 436 after the 6 mm washer. M36 × 140 reaches Z 296: 86 mm of foot/ledge/washer stack and 54 mm in the nut plate. Nut plates sit below the ledges at Z 296…350 and slide into side-access pockets. Two keeper screws attach lateral plate ears, outside the main bolt paths.

| Connection | Bolt centers | Count |
| --- | --- | ---: |
| Rear crossmember | X ±350; Y −550, −450 | 4 |
| Front crossmember | X ±350; Y 950, 1050 | 4 |
| Cradle | X ±350; Y −100, 100 | 4 |
| Forefoot hinge beam | X ±350; Y 1380, 1460 | 4 |
| Toe crossmember | X ±350; Y 2060, 2140 | 4 |

The cradle includes an outer outrigger supporting the pitch actuator's lower clevis at (−540, 800, 480). This is integral to the cradle, with an open trussed shape along the outer rail. Keep the central underside of the ankle open for tools. Do not turn the cradle into a solid block.

## Ankle ring, adapter and four short pins

FA-200 is an angular open ring: main outline X ±440, Y ±360, Z 940…1060; central opening X ±300, Y ±220. Local bearing bosses and stop-mount ears extend beyond that main outline.

FA-201 adapter body occupies X ±180, Y ±130, Z 930…1320 in neutral. Its roll-bearing bosses extend to Y ±210. The flange is 520 wide × 440 deep × 60 thick, Z 1320…1380. An integral 180 × 100 × 20 key rises into the shin plate.

| Bearing stack | Pitch, each side | Roll, each end |
| --- | --- | --- |
| Axis | X through C | Y through C, carried by ring |
| Pin journal | Ø120 × 250 long | Ø100 × 250 long |
| Moving-member bushing | ID120 / OD150 × 140 | ID100 / OD130 × 100 |
| Bushing location | X 300…440 and mirror | Y 110…210 and mirror |
| Supporting member | Cradle cheek X 450…550 and mirror | Ring boss Y 220…360 and mirror |
| Thrust washer | ID122 / OD170 × 8 | ID102 / OD150 × 8 |
| Washer space | 10 between boss and support | 10 between boss and support |
| Head and cap | 25 pin-head shoulder + 20 cap | 25 pin-head shoulder + 20 cap |
| Outer hardware limit | X ±595 | Y ±405 |
| Retention | One cap with two M24 × 60 | One cap with two M24 × 60 |

The nominal 2 mm remaining washer space is a visible running-clearance allowance, not a fit tolerance. Pins have anti-rotation flats engaging their fixed supports. Capturing a pin head must not squeeze the rotating boss or washer stack.

Pitch bearing bosses have a 180 mm outer diameter around their journals. Roll support bosses have a 200 mm outer envelope. Caps use a 30 mm thick mounting land around the two retaining bolts, with recessed heads; the thinner central cap captures the pin head.

No pin crosses the empty center. Do not draw intersecting full-width ankle shafts.

### Shin interface and access

The shin provides a 30 mm baseplate, Z 1380…1410, keyed to the adapter. Four M36 × 90 bolts point downward at X ±200, Y ±150, with 6 mm washers. They engage 54 mm into the adapter.

Keep the structural shin beam within a 300 × 200 section immediately above this flange. A 120 mm long, Ø80 socket envelope above each bolt clears that beam and the lower armor start at Z 1650.

For the first 450 mm of lower shin armor, use a conservative 900 × 900 box envelope: X/Y ±450, Z 1650…2100 in neutral. It moves with the adapter. This restriction is also recorded in the [shin specification](../shin-and-calf.md). Wider calf armor must begin above that interface region.

## Forefoot hinge

The fixed FA-102 support lugs occupy X 460…580 and their mirror. FA-106 moving lugs occupy X 310…450 and their mirror. Both center on H. Their axial gaps are 10 mm per side, containing an 8 mm thrust washer and 2 mm reference running allowance.

Use one Ø120 axle with a 1160 mm journal spanning X −580…580 and a 25 mm shouldered anti-rotation head at the outer end. The inner end uses one retaining cap with two M24 × 60 bolts. Total shaft extraction length is 1185 mm.

The two moving bushings are ID120 / OD150 × 140; thrust washers are ID122 / OD170 × 8. Relieve the hinge beam around the shaft, preserving at least 15 mm between the central shaft surface and the beam's Y 1275 rear face. Model the hinge lugs as local projections; do not extend a solid crossmember through the moving frame.

Reserve **1300 mm of clear workspace outside the outer side** for shaft removal. The neutral gap between the two feet is only 900 mm, so extraction must face outward.

## Soles, carriers and recessed hardware

Both carrier plates are 60 thick, Z 140…200. Rear carrier FA-300 spans X ±610, Y −760…1100. Moving carrier FA-301 spans X ±610, Y 1310…2190.

Pads are 140 thick, Z 0…140. Each pair occupies X −620…−20 and X 20…620, leaving a 40 mm center gap.

| Pad pair | Y limits | Size of each pad |
| --- | --- | --- |
| FA-302 heel | −760…−100 | 600 × 660 × 140 |
| FA-303 midfoot | −60…1090 | 600 × 1150 × 140 |
| FA-304 forefoot | 1320…2180 | 600 × 860 × 140 |

Use broad transverse grooves, 30 wide × 12 deep on 120 mm pitch, terminating 40 mm before pad edges. Bevel pad edges 20 mm. Maintain solid circular lands around bolt counterbores.

Each pad's four bolt centers are 100 mm inward from its rectangular corners. M24 × 120 pad bolts point upward. Their under-head plane is Z 60; a 4 mm washer occupies Z 60…64; a separate ID26 / OD42 × 76 compression sleeve spans Z 64…140. Thread engagement in the carrier is 40 mm.

The Ø56 pad counterbores accept a Ø46 socket envelope. Bolt heads are Ø36 × 24, with their lowest point 36 mm above ground, or 24 mm above the deepest tread groove. The sleeves carry bolt clamp force without crushing the pads.

Carrier-to-frame bolts are M24 × 70 pointing upward, with recessed Ø56 counterbores. Their under-head plane is Z 168; washer Z 168…172; carrier land Z 172…200; frame engagement 38 mm. Heads remain above the carrier's underside and do not require pad cutouts.

Carrier bolt centers:

- Rear: X ±500, Y −650, 150, 1000 — six.
- Forefoot: X ±500, Y 1420, 2100 — four.

Remove pads to expose carrier fasteners. Carrier and pad bolt holes are separate.

## Armor envelopes and openings

All five shells are nominally 20 thick, with integral 30 mm attachment lands, two locating tabs per shell and four captive M12 × 50 bolts. Use short sliding tabs, 10 mm engagement, that release along the stated removal direction. Threaded receivers are integral bosses on the owning frame, with at least 17 mm engagement.

| Shell | Shape and boundary | Owner / removal |
| --- | --- | --- |
| FA-400 toe cap | Roof from Y1340/Z600 to Y2145/Z520, then a short chisel nose to Y2200/Z400; lower edge Z200 | Forefoot only; lifts upward |
| FA-401 upper foot plate | Top at Z700, underside Z680, front edge Y1080; open ankle notch connected to rear edge | Rear frame; lifts upward |
| FA-402 heel cover | Y −800…−450; no higher than Z600 | Rear frame; withdraws rearward |
| FA-403 inner guard | Inner wall X630, outer wall X650; approximate Y −650…850, Z600…1600 | Fixed cradle; withdraws inward |
| FA-404 outer guard | Mirror of inner guard | Fixed cradle; withdraws outward |

The upper plate has an outer-side actuator relief around X −620…−450, Y 550…870. Shape its boundary around the pitch actuator envelope; the outer guard shelters this opening. The ankle notch is open to the rear so the plate cannot become trapped around the attached shin.

The two-stage toe roof is a 3D refinement: the original single slope to the 400 mm tip intersected the front frame bolt heads. The revised roof preserves that tip height while clearing the heads; see the [modeling notes](../../../models/foot-fa01/MODELING_NOTES.md).

The broad recessed forefoot channel runs between the fixed plate at Y1080 and moving toe shell at Y1340. The pivot sits within this channel at Y1200/Z350. Do not close the channel with a rigid bridge.

The guards are lateral walls, open at front and rear. Never add a solid guard roof or bridge across the moving shin. Their 20 mm wall thickness gives inner faces at ±630.

## Stop blocks and contact datums

FA-230 comprises six separate handed/angled blocks. Each has a nominal 140 × 80 mounting flange, 30 mm bolt land, two M24 × 70 bolts on 80 mm centers, and a locating tongue. Shape the contact extension to its angular datum.

| Pair | Support | Integral moving contact feature | Face-setting datum |
| --- | --- | --- | --- |
| Pitch | Cradle | Ring tab in the inner-side lane, X≈420, radius 220 below C | Contact at φ=−20° and +20° |
| Roll | Ring, on integral lower mounting ears | Adapter tab in the central lane, radius 220 below C | Contact at ρ=−10° and +10° within ring |
| Forefoot | Front crossmember | Hinge-beam lever in inner lane X≈220, radial vector (Y60,Z220) from H | Contact at θ=0° and 30° |

Faces are tangent to the appropriate tab sweep at the end angles, with material on the overtravel side. The pitch and roll contacts occupy different X lanes; the forefoot actuator uses the center lane and its stops use the inner lane. Stop mounts are local ears on existing structural pieces, not additional unlisted brackets.

These datums define how to place stops in reference diagrams. Final block contours, fillets, contact patches and mounting-ear collision checks belong to the later solid-model pass. They are **not** included in the numerical envelope clearance results.
