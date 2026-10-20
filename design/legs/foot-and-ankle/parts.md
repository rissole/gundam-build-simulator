# Foot and ankle — numbered inventory FA-01

Revision: FA-01 · 2026-10-20

[Component overview](../foot-and-ankle.md) · [Dimensions](dimensions.md) · [Build sequence](assembly-and-review.md)

Quantities are for **one foot**, including its ankle adapter and four shin-interface bolts. Mirror the geometry and double quantities for a pair. The shin beam/baseplate and its mating electrical socket belong to the shin, not this inventory.

An ID identifies a part family. Add `-IN/-OUT`, `-F/-R`, `-P/-R/-F` or an instance number where the table calls for handed or sized variants. A family quantity is the total across its variants, not the count of each variant. For example FA-220 comprises exactly six clevises.

Hardware is listed separately after the component tables. Do not add the FA-500 actuator assembly labels as extra parts: their contents are already counted here. Integral tabs, ledges, keys, bosses and locating tongues are features of their parent parts.

## Frame

| ID | Part | Qty | Connection / purpose |
| --- | --- | ---: | --- |
| FA-100 | Rear side rail, inner/outer | 2 | Carries frame seats and sole carrier |
| FA-101 | Rear crossmember | 1 | Four main frame bolts |
| FA-102 | Front crossmember with fixed hinge supports | 1 | Four main frame bolts; carries hinge and forefoot drive base |
| FA-103 | Fixed ankle cradle with outer actuator outrigger | 1 | Four main frame bolts; supports pitch pins |
| FA-104 | Forefoot rail, inner/outer | 2 | Moving toe frame |
| FA-105 | Toe crossmember | 1 | Four main frame bolts |
| FA-106 | Hinge beam with moving lugs | 1 | Four main frame bolts |
| FA-107 | Two-hole frame nut plate | 10 | Receives 20 M36 bolts; two keeper screws each |

Nine main structural pieces, plus ten nut plates.

## Joints, clevises and stops

| ID | Part | Qty | Connection / purpose |
| --- | --- | ---: | --- |
| FA-200 | Angular pitch ring | 1 | Rotates in cradle; carries roll supports |
| FA-201 | Roll adapter with keyed shin flange | 1 | Rotates in ring; remains with foot |
| FA-202 | Short pitch pin | 2 | Fixed to cradle |
| FA-203 | Short roll pin | 2 | Fixed to ring |
| FA-204 | Pitch sleeve bushing | 2 | Fits ring bosses |
| FA-205 | Roll sleeve bushing | 2 | Fits adapter bosses |
| FA-206 | Pitch thrust washer | 2 | Between ring and cradle |
| FA-207 | Roll thrust washer | 2 | Between adapter and ring |
| FA-208 | Pitch pin retaining cap | 2 | Two bolts each |
| FA-209 | Roll pin retaining cap | 2 | Two bolts each |
| FA-210 | Continuous forefoot axle | 1 | Anti-rotation head faces outer side |
| FA-211 | Forefoot sleeve bushing | 2 | Fits moving hinge lugs |
| FA-212 | Forefoot thrust washer | 2 | Between moving and fixed hinge lugs |
| FA-213 | Forefoot axle retaining cap | 1 | Two bolts, inner side |
| FA-220 | Actuator clevis bracket, six location-specific variants | 6 | Two per actuator; two mount bolts each |
| FA-221 | Actuator attachment pin, two Ø50 / four Ø40 | 6 | One per actuator eye |
| FA-222 | Keyed actuator-pin keeper plate | 6 | One keeper screw each |
| FA-230 | Mechanical stop block, six angle-specific variants | 6 | Two per motion axis; two bolts each |

The five main pivot retainers are FA-208 ×2, FA-209 ×2 and FA-213 ×1. The six small actuator-pin keeper plates are a different family.

## Soles and armor

| ID | Part | Qty | Connection / purpose |
| --- | --- | ---: | --- |
| FA-300 | Rear sole carrier | 1 | Six bolts to rear frame |
| FA-301 | Forefoot sole carrier | 1 | Four bolts to moving frame |
| FA-302 | Heel grip pad | 2 | Four bolts and four sleeves each |
| FA-303 | Midfoot grip pad | 2 | Four bolts and four sleeves each |
| FA-304 | Forefoot grip pad | 2 | Four bolts and four sleeves each |
| FA-305 | Pad compression sleeve | 24 | One per pad bolt |
| FA-400 | Toe cap | 1 | Forefoot-owned |
| FA-401 | Upper foot plate | 1 | Rear-frame-owned |
| FA-402 | Heel cover | 1 | Rear-frame-owned |
| FA-403 | Inner ankle guard | 1 | Cradle-owned |
| FA-404 | Outer ankle guard | 1 | Cradle-owned |
| FA-405 | Captive armor-bolt retaining collar | 20 | One per armor bolt; separate from washer |

## Actuator internals

The three size variants share this construction. See the [actuator specification](actuators.md) for dimensions, endpoint coordinates and module boundaries.

| ID | Part | Qty across all three actuators |
| --- | --- | ---: |
| FA-510 | Cylindrical barrel | 3 |
| FA-511 | Front guide cap | 3 |
| FA-512 | Rear drive cap | 3 |
| FA-513 | Motor cartridge with position feedback | 3 |
| FA-514 | Reduction gearbox cartridge | 3 |
| FA-515 | Clamp coupling | 3 |
| FA-516 | Lead screw | 3 |
| FA-517 | Travelling nut | 3 |
| FA-518 | Hollow extending rod | 3 |
| FA-519 | Front guide bushing | 3 |
| FA-520 | Rod wiper seal | 3 |
| FA-521 | Anti-rotation guide key | 3 |
| FA-522 | Rear radial/thrust bearing cartridge | 3 |
| FA-523 | Bearing retaining plate | 3 |
| FA-524 | Split shaft-collar half | 6 |
| FA-525 | Actuator eye housing | 6 |
| FA-526 | Spherical eye bearing | 6 |
| FA-527 | Eye bearing retaining ring | 6 |
| FA-528 | End-position sensor with captive wiring | 6 |
| FA-529 | End-cap gasket | 6 |
| FA-530 | Actuator bulkhead connector module | 3 |

Each actuator has 27 listed non-fastener pieces/modules and 32 external assembly screws with 32 washers. The connector module includes its threaded mounting ring and seal. Cartridge internals are deliberately not double-counted as loose parts.

## Wiring and control

| ID | Part | Qty |
| --- | --- | ---: |
| FA-600 | Junction box lower housing | 1 |
| FA-601 | Junction box lid | 1 |
| FA-602 | Junction box lid gasket | 1 |
| FA-603 | Three-channel controller board module | 1 |
| FA-604 | Junction box bulkhead connector module | 4 |
| FA-605 | Main input harness, including two plugs | 1 |
| FA-606 | Actuator branch harness, including two plugs | 3 |
| FA-607 | Cable clip | 12 |

## Fastener schedule

The authoritative count by installation location is [hardware.csv](hardware.csv). Every listed bolt/screw has **one separate washer**, including captive armor bolts. Bearing thrust washers are different components and are already in the joint table.

| Bolt ID | Nominal size | Qty |
| --- | --- | ---: |
| H-36140 | M36 × 140 | 20 |
| H-36090 | M36 × 90 | 4 |
| H-24060 | M24 × 60 | 10 |
| H-24070 | M24 × 70 | 34 |
| H-24120 | M24 × 120 | 24 |
| H-12030 | M12 × 30 | 62 |
| H-12040 | M12 × 40 | 60 |
| H-12050 | M12 × 50 | 24 |
| H-12050-C | M12 × 50, captive armor variant | 20 |

| Washer ID | ID / OD / thickness | Qty |
| --- | --- | ---: |
| W-36 | 38 / 66 / 6 | 24 |
| W-24 | 26 / 44 / 4 | 68 |
| W-12 | 13 / 24 / 2.5 | 166 |

Total: **258 bolts/screws and 258 fastener washers per foot**. There are 229 other listed pieces/modules, including the 20 captive collars, for **745 assembly objects** under this module-counting convention. These are inventory totals, not a recommended number of player interactions.

Use recessed cylindrical hex-socket heads throughout: reference envelopes Ø54 × 36 for M36, Ø36 × 24 for M24, and Ø18 × 12 for M12. No cosmetic rivets or unlisted loose nuts.

M36 frame bolts engage replaceable nut plates. Other bolts engage tapped bosses in their owning metal parts, except collar/coupling clamp screws, which thread into the other clamp half. M24 × 70 mechanism mounts use a 30 mm land plus a 4 mm washer, leaving 36 mm engagement. M24 × 60 pivot-cap bolts similarly leave 26 mm engagement.

For M12 hardware, use reinforced lands of 10–20 mm and tapped bosses that preserve at least 17 mm thread engagement; provide open-backed threaded holes where a selected screw extends through a thin land. Captive armor bolts have a 30 mm land plus washer, giving 17.5 mm engagement. Exact tap drill, pitch, strength grade, surface treatment, torque and manufacturing fit are intentionally outside this fictional reference revision.
