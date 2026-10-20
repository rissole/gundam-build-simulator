# Foot and ankle — actuators and wiring FA-01

Revision: FA-01 · 2026-10-20

[Component overview](../foot-and-ankle.md) · [Dimensions](dimensions.md) · [Parts and fasteners](parts.md)

All three units are enclosed electric screw actuators with cylindrical bodies, visible rods and spherical eyes. They are separate assemblies designated FA-500-P, FA-500-R and FA-500-F. These assembly names do not add three extra objects to the component inventory.

## Attachment geometry and size variants

Coordinates use the [foot datums](dimensions.md#coordinates-and-movement). Positions below are pin centers, not body corners.

| Detail | Pitch P | Roll R | Forefoot F |
| --- | --- | --- | --- |
| Parent → moving member | Cradle → ring | Ring → adapter | Rear frame → hinge beam |
| Base eye | Foot coordinate (−540,800,480) | Ring coordinate relative to C: (500,−450,−150) | Foot coordinate (0,650,520) |
| Rod eye | Ring coordinate relative to C: (−540,300,0) | Adapter coordinate relative to C: (200,−450,320) | Forefoot coordinate relative to H: (0,60,220) |
| Body outside diameter | 140 | 110 | 110 |
| Barrel length | 500 | 380 | 365 |
| Base-eye center to front guide | 570 | 440 | 425 |
| Extending rod outside diameter | 90 | 65 | 65 |
| Nominal usable eye-to-eye limits | 640…860 | 480…640 | 470…640 |
| Available extension stroke | 220 | 160 | 170 |
| Required length over joint range | 665.31…809.97 | 496.48…615.20 | 494.55…612.05 |
| Attachment pin diameter | 50 | 40 | 40 |
| Screw major diameter / reference lead | 40 / 10 per revolution | 30 / 8 per revolution | 30 / 8 per revolution |

Roll's base and rod eye both receive the ring's pitch transformation. Consequently ankle pitch does not change the required roll-actuator length. Forefoot travel is independent of the ankle.

The values establish plausible visual packaging; motor power, gear ratio, screw stress and cycle life are not sized. Do not present these choices as sufficient to move a real 18 m machine.

The pitch body runs outside the ring's outer side. The roll body sits behind the ring at local Y−450; the adapter-side bracket reaches rearward to meet it. The forefoot body runs along the center beneath the upper plate. Its base clevis extends rearward from the front crossmember to Y650. Its rod clevis includes the forefoot lever; do not add a fourth actuator or a separately counted lever.

Each of the six clevises is a separately bolted component with two M24 × 70 mounting bolts, 30 mm mounting lands and locating keys. Pitch clevises have 35 mm ears around a 60 mm eye width and an approximately 132 mm pin working span. Roll/forefoot clevises use 25 mm ears around a 45 mm eye width and a 97 mm span. Leave 2 mm total visual axial clearance. Each pin has an integral head and a keyed keeper plate retained by one M12 × 30 screw.

Bracket shapes are specific to the coordinates; the long adapter bracket is open underneath to preserve rear roll-pin access. Spherical bearings accommodate small mounting misalignments. They do not replace the defined hinge axes.

## Internal construction

Explode each actuator into the following layers; part IDs and quantities are in the [inventory](parts.md#actuator-internals).

1. Rear cap and gasket; motor cartridge with integrated position feedback.
2. Reduction gearbox cartridge attached to the rear cap.
3. Clamp coupling between gearbox output and lead screw.
4. Rear combined radial/thrust bearing cartridge, bearing retainer plate and split shaft collar.
5. Lead screw, travelling nut and hollow extending rod.
6. Anti-rotation guide key attached to the housing and engaging the rod's longitudinal slot.
7. Front guide bushing, rod wiper, gasket and removable front cap.
8. Base and rod eye housings, spherical bearings and bearing retaining rings.
9. Two internal end-position sensors and the external keyed connector.

The travelling nut bolts to the hollow rod with two M12 screws. The screw enters the hollow rod as it retracts. The guide key prevents the rod and nut from rotating, so screw rotation produces extension. Bearings and the shaft collar prevent the screw from moving axially.

Use four M12 bolts at each cap, four on each motor flange and four at each gearbox flange. Two M12 screws clamp the coupling; two retain the bearing plate; two join the split collar halves; two secure the guide key; and two attach each eye housing. Each end sensor uses one M12 screw. These are exposed assembly fasteners listed separately, not hidden inside the motor or gearbox cartridge.

Use nominal 20 mm cap thicknesses and 2 mm face gaskets, with local bosses as required. The cap/barrel details must preserve the external pin-to-guide dimensions above. Sensor wires are supplied as a captive loom with the sensor pair and terminate at the actuator connector; no extra loose internal harness is required.

Set end-position sensing just inside the usable actuator limits. Normal joint commands stop at the specified angular range, where the six mechanical stops contact. The table leaves travel margin before the actuator's own end limits.

**Assembly granularity:** motor, reduction gearbox, bearing cartridge, sensor, connector and controller are manufactured modules. Their windings, gear teeth, bearing rolling elements, contact pins and circuit components are not individual assembly objects in FA-01. Their separate installation, housings, retention hardware and connections are represented. Expand a module in a later revision only if assembling its interior adds useful puzzle detail.

## Controller and external harnesses

FA-600/601 form a removable 300 × 300 × 160 junction box at X150…450, Y650…950, Z460…620. It bolts to integral frame ears, clears the central forefoot actuator, and leaves 60 mm below the upper plate. Use a gasketed lid and one three-channel motor-controller board.

- Four M12 × 40 screws mount the enclosure.
- Four M12 × 40 screws retain its lid.
- Four M12 × 40 screws mount the board on integral standoffs.
- Four threaded-bulkhead sockets serve one input and three actuator branches.
- Each socket includes its own mounting ring and seal as part of the connector module; no separate M12 socket screws.

There are **four removable external harness assemblies**: one main power/control lead and three actuator branches. Each has two keyed plugs and protective sleeving included. Do not count those plugs again as separate parts.

The main lead plugs into the box and ends at a keyed disconnect next to the shin flange. Its mating socket belongs to the shin and is excluded from the foot inventory. Each actuator branch connects a box socket to its actuator's socket. This accounts for four box sockets, three actuator sockets and eight harness plugs; the eighth mating socket is shin-owned.

### Routes and installation allowances

Use twelve separate bolted cable clips, each with one M12 × 30 screw:

| Harness | Nominal cut length | Clips | Route and motion allowance |
| --- | ---: | ---: | --- |
| Main input | 2200 | 5 | Inner rail → cradle → ring → adapter → shin disconnect; separate protected loops at pitch and roll |
| Pitch branch | 1800 | 3 | Front frame → outer outrigger → pitch actuator body; small eye-pivot flex loop |
| Roll branch | 2200 | 3 | Inner frame → pitch loop → ring rear → roll actuator body |
| Forefoot branch | 900 | 1 | Box → central fixed clevis → actuator body; keep clear of rod and hinge |

Route the main input's moving loops through the ring's open center, on the inner side of the structural beam. Keep cables out of bolt-tool corridors and the lower stop-tab lanes. Use 100 mm minimum loop radius as a reference drawing allowance; reserve 300 mm of free cable at each ankle crossing. Service loops are drawn as actual loops, not straight lines spanning moving members.

These harness lengths include working slack and remain trim-to-fit values for later modeling. Bend limits, clip positions and swept cable contact require a flexible-harness review in CAD. The rigid-envelope script does not validate them.
