# Foot and ankle

Last updated: 2026-10-20 · Reference revision **FA-01**

[Design index](../../ROBOT_DESIGN.md) · [Shared design rules](../global.md) · [Whole-robot proportions](../proportions.md#legs-and-feet) · [Shin and calf](shin-and-calf.md)

The left foot is the master; mirror it for the right. This overview preserves the confirmed choices. The linked detail packet contains the assistant-selected dimensions and assembly details developed under the user's instruction to proceed with recommendations and verification.

## Completion status

**The foot-and-ankle reference-design detail pass is complete, with three reference sheets generated for review.** This is a fictional mechanical design with a documented inventory and bounded envelope review, not fabrication-ready engineering. Exact solid geometry, flexible-cable motion and real load sizing remain later modeling work.

- [x] Rear chassis breakdown and connection scheme.
- [x] Ankle arrangement, shin interface, and movement targets.
- [x] Ankle bearing-hardware counts and electric actuator choice.
- [x] Forefoot arrangement, hinge hardware, electric drive, and movement targets.
- [x] Sole pads, armor panels, and their attachments.
- [x] Reference dimensions, fastener sizes/counts, actuator internals, service routing, and part identifiers.
- [x] Assembly sequence, bounded movement-clearance and tool-access review, and reference-sheet readiness.

The user requested explicit notification of this milestone. Image review is a separate step; images do not override the written design.

## Detail packet

| Document | Contents |
| --- | --- |
| [Dimensions and interfaces](foot-and-ankle/dimensions.md) | Datums, rail seats, joint stacks, sole recesses, shell boundaries, stop contact datums |
| [Actuators and wiring](foot-and-ankle/actuators.md) | Three electric screw drives, attachment coordinates, internal breakdown, controller and harness routes |
| [Numbered parts and hardware](foot-and-ankle/parts.md) | Component IDs, module boundaries, quantities and bolt/washer schedule |
| [Hardware data](foot-and-ankle/hardware.csv) | Counts by installation location |
| [Assembly sequence and review](foot-and-ankle/assembly-and-review.md) | Build steps, service dependencies, numerical results and later CAD boundaries |
| [Reference images and prompts](foot-and-ankle/images/README.md) | Assembled views, structural explosion, armor/sole/services and known image limitations |
| [Review script](foot-and-ankle/review_geometry.py) / [results](foot-and-ankle/review-results.json) | Reproducible sampled envelope calculations |

Read this overview, shared rules and only the relevant detail files for an image brief. Do not load the whole robot's decision history into each prompt.

## Confirmed design

### Foot shape and articulation

A long, low chisel-toed foot with a short substantial heel, crisp removable armor and visible ankle mechanics between two guards. The foot is 3000 long and 1300 wide. Its separate forefoot hinges 2000 forward of the heel, leaving a 1000 mm toe section. A recessed transverse armor channel exposes the joint without a rigid panel bridging it.

### Rear foot chassis and frame connections

Five separate main structural pieces: two longitudinal box-section rails, front crossmember, rear crossmember and fixed ankle cradle. Rails have chamfered corners and integral inner ledges. Crossmembers lower into locating recesses; two bolts at each end give eight M36 bolts. The cradle seats separately with four more M36 bolts.

Every bolt has a separate washer. Six replaceable two-hole nut plates receive the twelve rear-frame bolts; each plate has two M12 keeper screws. Install nut plates before lowering and fastening the structural members.

### Ankle construction and shin connection

The fixed cradle has raised side cheeks supporting an angular ring on a transverse pitch axis. The ring carries a separate shin adapter on a fore/aft roll axis. Four opposing short pins leave the center clear; do not draw two intersecting solid shafts.

There are four replaceable sleeve bushings, four thrust washers and four retaining caps with two M24 bolts each. Pin shoulders and anti-rotation flats retain the pins without clamping the moving members.

The adapter's keyed flange bolts to the structural shin beam with four M36 bolts. The adapter belongs to the foot and stays with it when disconnected. The ankle axes intersect 1000 mm above the ground. Accepted movement targets are ±20° pitch and ±10° roll. The ring carries the roll axis as it pitches.

### Electric actuators and mechanical stops

Three electric screw actuators: cradle-to-ring for pitch, ring-to-adapter for roll, and rear-frame-to-forefoot for toe movement. Each has a motor with feedback, reduction gearbox, coupling, supported screw, travelling nut, guided hollow rod, cylindrical housing, removable caps, two end sensors and a keyed connector.

Each actuator has two ball-jointed eyes, two separately bolted clevises and two removable pins. Across the foot this gives six clevises with twelve M24 mount bolts, six attachment pins, and six keyed keeper plates with one M12 screw each.

Six replaceable stops—two per movement axis—seat in locating recesses and use two M24 bolts each. Pitch stops belong to the cradle, roll stops to the ring, forefoot stops to the rear frame. Hydraulic actuation remains reserved for larger leg joints including the knees.

### Forefoot construction and hinge

Four main pieces: two short rails, toe crossmember and hinge beam. Four located rail-to-crossmember connections use eight M36 bolts and washers, with four two-hole nut plates and eight M12 keeper screws.

The transverse hinge is at local Y1200/Z350. One continuous removable axle connects interleaved fixed and moving lugs. It has two bushings, two thrust washers, an anti-rotation shoulder at the outer end and a retaining cap with two M24 bolts at the inner end. It extracts outward, away from the other foot.

The forefoot actuator connects to a lever incorporated into its moving clevis. Movement is flat to 30° toe-up. Toe cap, forefoot frame, carrier and two forefoot pads move together.

### Sole and armor attachments

Six replaceable composite grip pads form heel, midfoot and forefoot pairs. Rear carrier supports four pads; forefoot carrier supports two. Each pad uses four deeply recessed M24 bolts, separate washers and compression sleeves: twenty-four of each. Six bolts mount the rear carrier and four mount the front carrier.

Pads have transverse grooves, beveled edges and a centerline gap. Break the sole at the hinge and recess its edges clear of the sweep.

Five separate shells each have two integral locating tabs and four captive M12 bolts, washers and retaining collars:

- Toe cap: moving forefoot frame; lifts upward.
- Upper foot plate: fixed rear frame; lifts upward through an open-backed ankle notch.
- Heel cover: fixed rear frame; removes rearward.
- Inner and outer ankle guards: fixed cradle; remove sideways.

Panels remove without dismantling bearings or removing sole pads. Side guards expose pitch caps; upper and heel openings expose roll caps. Mechanical detail remains concentrated at the gaps.

### Wiring and service

One removable three-channel control/junction box sits beneath the upper plate. A main harness leads to the keyed shin disconnect; three plug-in branches feed the actuators. Twelve bolted clips and protected moving loops keep wiring on the inner frame and away from joint pinch points. The shin owns the mating input socket.

### Fastener and inventory scope

Three nominal recessed hex-socket families: M36 structural, M24 mechanism/sole/stop, M12 armor/service. The detailed inventory accounts for **258 bolts/screws, 258 fastener washers and 229 other pieces/modules: 745 assembly objects per foot**.

This counting convention treats motors, gearboxes, bearing cartridges and electronics as manufactured modules. Their installation hardware is included; their internal windings, gear elements and circuits are not expanded into separate puzzle parts.

## 3D model and animation

The [FA-01-3D-01 model package](../../models/foot-fa01/README.md) preserves all 745 inventory objects as separate meshes and animates construction followed by an exploded view. Read its [modeling notes](../../models/foot-fa01/MODELING_NOTES.md) for dimensional refinements discovered during solid layout. This is a polygon visualization asset; engineering validation remains a separate task.

## Later modeling work

### Prepared feet in the wider M3 workshop — 2026-10-24

M3 supplies two internally prepared feet with independent consumed identities.
The right-foot sources and receiving geometry are reflected through X; the
canonical left-foot asset and default foot-workshop build remain unchanged. Each
prepared foot has its own sole support in the foot bay. The shared crane uses
four exposed FA-100 rail-top contacts, transfers the existing assembly to the
dispatch carrier, then the carrier raises, advances and turns it onto the shared
leg holder. Ankle and forefoot stay neutral during this supplied transport stage.

Contacts in the playable foot-root frame are X±0.50/Y−0.36/Z−0.20 and1.20 m;
their positions are checked against the imported structural rail triangles.
Both crane deliveries, carrier handoffs, mirrored geometry, support ownership and
interrupted saves have mechanical coverage in the
[M3 implementation ledger](../game/history/m3-wide-evidence-20261024.md#plan-implementation-ledger-through-task-09).
That evidence does not establish player reach, rigging usability or rendered
approval. The complete wider workshop and its later major-section deliveries are
still in development.

The detail packet records chosen dimensions, stop datums, wiring routes and access provisions. Full CAD must still check solid bracket/stop contours, all simultaneous motion combinations, complete insertion/tool paths and flexible harness movement. Real strength, power, fit tolerances and torques are outside the current fictional-reference scope. See the [review boundaries](foot-and-ankle/assembly-and-review.md#boundaries-for-later-solid-modeling).
