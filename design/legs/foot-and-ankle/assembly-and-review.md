# Foot and ankle — assembly and review FA-01

Revision: FA-01 · 2026-10-20

[Component overview](../foot-and-ankle.md) · [Dimensions](dimensions.md) · [Inventory](parts.md) · [Actuators](actuators.md)

The foot-and-ankle **reference-design detail pass is complete**. Its parts, major dimensions, attachment ownership, fastener quantities, sequence and drawing requirements are recorded. The [first three reference sheets](images/README.md) have been generated for user review. This status does not mean a manufacturing design or fully collision-checked CAD model is complete.

## Review summary

| Assembly group | Contents per foot |
| --- | --- |
| Structural frame | Five rear-chassis pieces, four forefoot pieces, ten nut plates |
| Main joints | Pitch ring, shin adapter, four short ankle pins, one forefoot axle, six bushings, six thrust washers, five retaining caps |
| Drives and stops | Three electric screw actuators, six clevises, six attachment pins with six keepers, six stop blocks |
| Sole | Two carriers, six pads, twenty-four compression sleeves |
| Armor | Five separate shells with twenty captive bolts and collars |
| Electrical | One control box/controller, four external harnesses, twelve cable clips |
| Hardware | 258 bolts/screws and 258 matching washers; exact allocation in the inventory |

There are 229 other listed pieces/modules and 516 bolts/washers, giving **745 assembly objects**. Purchased-style cartridges are counted once each. Bolt counts do not include hidden manufacturing fasteners inside those cartridges.

## Recommended build sequence

This is the assembly logic for reference images and the future puzzle. It is not an operating procedure for a real giant machine.

1. **Prepare the rear frame.** Fit six nut plates beneath the two long rails and retain them with twelve M12 screws. Lower the front and rear crossmembers into their located seats. Install eight M36 frame bolts with washers.
2. **Mount the cradle.** Seat the fixed ankle cradle and its integral outer outrigger; fit its four M36 bolts. Add the two pitch stop blocks while the interior is open.
3. **Build the moving ankle core on the bench.** Fit the two roll bushings into the adapter. Fit the roll stops to the ring, place the adapter inside it, add the two roll thrust washers, insert the two short roll pins, and fit their two retaining caps/four M24 bolts. Check that the adapter turns without being clamped.
4. **Install the ankle core.** Fit the ring's two pitch bushings. Place the core between the cradle cheeks with two thrust washers. Insert the two short pitch pins from the sides, engage their anti-rotation flats, and fit two caps/four bolts. The two pivot axes share a center but have no intersecting shafts.
5. **Build the forefoot frame.** Fit four nut plates and eight keeper screws to the two short rails. Seat the hinge beam and toe crossmember; secure with eight M36 bolts. Add its moving hinge bushings.
6. **Join the forefoot.** Interleave the moving hinge lugs with the front crossmember's fixed supports and insert two thrust washers. Slide the continuous axle in from the outer side; engage its shouldered head. Fit the inner retaining cap with two bolts. Install the two forefoot stop blocks.
7. **Build the three actuators.** Follow the internal sequence in [actuators.md](actuators.md#internal-construction): motor/gearbox, screw support and coupling, screw/nut/rod, guides and caps, eyes and sensors. Each unit has 27 listed components/modules plus 32 screws and washers.
8. **Install the drives.** Fit six keyed clevises with twelve M24 bolts. Put each actuator in its specified P/R/F location; insert its two eye pins and fit their keeper plates/screws. Confirm pitch, roll and forefoot motion against the stop datums before closing the armor.
9. **Fit soles with the assembly supported.** Bolt the rear and forefoot carriers to their frames using six and four bolts. Insert twenty-four compression sleeves into the six pads; fit each pad with four recessed bolts and washers. Pad ownership must follow the hinge.
10. **Wire and inspect.** Mount the controller in its box, fit the box to its frame ears, connect the main lead and three branches, and fit twelve clips. Dress loops across pitch and roll, away from pins, stops and tool corridors. Close the box lid.
11. **Attach to the shin when building the leg.** Seat the keyed shin baseplate and fit four M36 bolts with washers. Mate the electrical disconnect. For a standalone foot display, leave the flange exposed and retain these four bolts as interface hardware.
12. **Fit the five armor shells.** Install the toe cap on the moving frame; heel cover and upper plate on the rear frame; and inner/outer guards on the cradle. Engage two tabs and tighten four captive bolts per shell. Keep the hinge channel and ankle openings clear.

Build order can be rearranged where access permits; the dependencies below are the important constraints.

## Access and removal review

| Item | Access requirement / dependency |
| --- | --- |
| Frame nut plates | Install before the main bolts. Slide from accessible ledge pockets; keeper screws are not under the main bolt heads |
| Cradle bolts | Best installed before the ring. For service, remove heel cover and use a short socket with a right-angle drive through the open underside of the joint |
| Pitch pins | Remove respective guard; withdraw sideways. Reserve approximately 300 mm straight extraction space beyond each support |
| Roll pins | Remove upper plate for front pin or heel cover for rear pin; reserve approximately 300 mm along the shaft axis |
| Forefoot axle | Remove side shell as needed; extract outward into a 1300 mm workspace corridor. Do not aim it into the gap between the feet |
| Actuator pins | Remove the appropriate shell, disconnect that actuator, remove small keeper, withdraw pin; do not remove a main ankle pin |
| Shin flange | Remove guards/upper plate as needed. Four Ø80 × 120 mm socket corridors remain beside the narrow lower shin beam |
| Sole carrier bolts | Remove relevant pads first. Carrier bolt heads are recessed above the carrier underside |
| Sole pad bolts | Accessible directly from below; compression sleeves preserve pad thickness |
| Armor | No shell requires bearing disassembly or pad removal. Upper plate has an open rear notch so it lifts off around an attached shin |
| Electrical | Box lid accessible after upper plate removal. Keyed plugs and loose service loops allow individual actuator removal |

These are reviewed access provisions, not a full simulation of every tool movement. Images must preserve the openings rather than fill them with decorative structure.

## Numerical envelope review

Run `python3 design/legs/foot-and-ankle/review_geometry.py` from the project root. It regenerates [review-results.json](review-results.json). The script checks 861 pitch/roll pose combinations at 1° increments and 61 forefoot poses at 0.5° increments. Box-edge clipping measures the lower shin against the guard top and the toe against the fixed hinge supports.

| Check | Result |
| --- | --- |
| Pitch actuator required range | 665.31…809.97 within 640…860 mm |
| Roll actuator required range | 496.48…615.20 within 480…640 mm |
| Forefoot actuator required range | 494.55…612.05 within 470…640 mm |
| Actuator length vs joint angle | Monotonic throughout each sampled range; no sampled reversal |
| Lower shin vs guard inner walls | At least 31.59 mm lateral clearance in sampled combined poses |
| Moving toe envelope vs fixed hinge lugs | At least 29.70 mm fore/aft clearance |
| Moving toe shell vs fixed upper plate | At least 116.24 mm fore/aft gap |
| Forefoot pads vs ground | Minimum 0 mm, at the flat pose; no sampled penetration |
| Shin flange vs ring boss top | At least 169.99 mm in ring coordinates |
| Roll-actuator base envelope vs heel cover | At least 50.14 mm vertical clearance |

The 25 mm threshold for the listed moving-envelope clearances is a **reference-layout allowance**, not a manufacturing tolerance. The results are sampled checks, not a proof of continuous collision freedom. They do not cover every actuator body surface, bracket, fastener, stop, cable, or simultaneous forefoot/ankle interaction.

The layout deliberately includes:

- A recessed toe hinge channel and forefoot rail starts at Y1340.
- Open-front/open-rear ankle guards with 20 mm walls.
- An upper-plate relief for the outer pitch actuator.
- Short opposed ankle pins and outward forefoot-axle extraction.
- Separate stop and actuator lanes.

## Boundaries for later solid modeling

Keep these explicit so future work does not mistake reference drawings for manufacturing drawings:

- Model all bracket contours, stop tabs/ears and bolt pockets as solids; check complete joint sweeps, assembly insertion paths and tool volumes.
- Verify flexible harness loops, connector orientations and bend radii across all poses.
- Resolve actual bearing fits, thread engagement tolerances, material strengths, actuator ratings and fastener torques only if the project later needs engineering analysis.
- Motors, gearboxes, bearing cartridges and electronics remain installable modules in this revision.
- Review AI-generated sheets for geometry drift, false seams, extra mechanisms, incorrect labels and omitted parts. Written specifications and the inventory take precedence.

These follow-up modeling tasks do not prevent generating the requested concept references. They do prevent describing FA-01 as a fully engineered or fabrication-ready design.
