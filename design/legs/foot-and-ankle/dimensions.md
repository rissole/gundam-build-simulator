# Foot and ankle — dimensional layout FA-01

Revision: FA-01, incorporating FA-01-3D-01 refinements · 2026-10-21

[Component overview](../foot-and-ankle.md) · [Parts](parts.md) · [Actuators](actuators.md) · [Assembly and review](assembly-and-review.md)

These are assistant-selected working dimensions under the user's instruction to proceed with recommendations. They preserve the confirmed construction and overall proportions. All dimensions here are **millimetres**, with angles in degrees. They describe fictional reference geometry, not production tolerances or a load-rated machine.

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
