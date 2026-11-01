# Foot and ankle reference images — FA-02 / FA-01

2026-11-01 · **FA-02 concept references generated and inspected; not user-approved.**
FA-01 is **superseded in look and outer envelope**. Preserve it only as historical
mechanism/layout context; never copy its grey palette. The approved appearance is
the [whole-robot turnaround/style guide](../../../visual-design/turnaround/README.md).
The [FA-02 revision](../dimensions.md#fa-02-revision-2026-11-01) governs revised
sizes and interfaces, [foot-components.csv](../foot-components.csv) governs parts,
and the unchanged [hardware schedule](../hardware.csv) governs installation counts.

## Preferred FA-02 sheets

| Sheet | Final file | Selected generation | Purpose |
| --- | --- | --- | --- |
| Assembled | [fa02-assembled.jpg](fa02-assembled.jpg) | v2, one correction | Three-quarter, side, front, back and top; 3360×1460 envelope, ankle 1000 and guard 1600 |
| Armor / soles | [fa02-armor.jpg](fa02-armor.jpg) | v2, one correction | Five shells, two carriers and six labelled pads |
| Structure / joints | [fa02-structure.jpg](fa02-structure.jpg) | v2 retained after v3 regression; two corrections attempted | Bare frame, open ring/adapter, three actuator barrels and hinge; geometric errors below |

All final files are 1536×1024 JPEG, Pillow quality 92, produced using Codex's built-in
image_gen. No FA-02 PNGs were placed or retained in the repository. Existing FA-01
PNGs below were preserved because the task excludes changing historical outputs.

## FA-02 prompts and review

- Assembled: [v1 prompt](prompt-fa02-assembled-v1.txt), [v2 correction](prompt-fa02-assembled-v2.txt); [v1 draft](fa02-assembled-v1.jpg).
- Armor: [v1 prompt](prompt-fa02-armor-v1.txt), [v2 correction](prompt-fa02-armor-v2.txt); [v1 draft](fa02-armor-v1.jpg).
- Structure: [v1 prompt](prompt-fa02-structure-v1.txt), [v2 correction](prompt-fa02-structure-v2.txt), [v3 correction](prompt-fa02-structure-v3.txt); [v1 draft](fa02-structure-v1.jpg), [v2 source](fa02-structure-v2.jpg), [rejected v3](fa02-structure-v3.jpg).
- [Review notes, validation output and source lineage](notes-fa02.md). Inventory
  passes all 79 source families: 745 objects, including 258 bolts and 258 washers.

Label text was checked against the CSV; geometry/leader placement remains distinct
from text correctness. These are generated concept sheets, not inspected 3D models,
collision evidence, playable-build verification or user approval.

## Known drawing errors — FA-02

- **Assembled dimensions:** the printed 3360/1460/1000/1600 values are correct, but the side view is somewhat too tall for its length; the ankle-height leader and guard/flange proportions are approximate. The views do not share a reliable scale. Use the dimensional tables, never pixel measurements.
- **Assembled details:** the broad rear-open upper plate and horizontal ring read correctly after correction, but the rear/top views, actuator locations, hinge-channel width, guard outlines and small seams differ. The rear view resembles the front plate more than the specified compact heel cover. No guard roof crosses the shin; the small top plate is the structural shin flange.
- **Palette and shell fasteners:** all sheets add ochre to guard edges and sometimes heel edges beyond the specified toe band. Several shell surfaces show more than four bolt wells and the upper plate adds a small hatch-like detail. These are surface/drawing drift, not extra panels or hardware; model exactly five shells and four captive bolts per shell.
- **Armor explosion:** five detached shells, two carriers and six pads are countable and correctly named. The forefoot pads are drawn too short relative to the heel pair, and the upper plate notch/actuator relief is too shallow or incompletely revealed. Carrier holes are schematic; the rear carrier shows excess large wells. Use the CSV and dimensions for sizes and 6/4 carrier mounts. Dashed guard arrows point downward in places, although guard removal is sideways. Do not treat explosion arrows as verified removal paths.
- **Structure (preferred v2):** the labels are readable and valid, but a third long rail remains between the intended rear rails. FA-100/104 pair leaders do not unambiguously identify the correct two instances; FA-102's leader lands near a rail/toe joint instead of clearly on the fixed hinge-support crossmember. The inventory has exactly two rear rails and two forefoot rails.
- **Structure hinge (preferred v2):** the continuous axle is drawn in front of and aligned toward the toe crossmember instead of through the four interleaved hinge lugs. Fixed and moving lug ownership/alignment is ambiguous. Place FA-210 at H=(0,1340,350) through the specified fixed/moving lugs, never through FA-105.
- **Structure drives and joint stacks:** three labelled barrels are countable after removing the fourth cylinder, but eye/clevis connections, forefoot lever, opposed short pin stacks, stops, nut plates and complete adapter flange key are incomplete or schematic. The roll body projects sideways instead of clearly behind the ring. The exploded pitch/roll eyes appear close enough to suggest a false connection between drives; derive both ends independently from the endpoint table. No full ankle shaft may cross the open ring.
- **Rejected structure v3:** it reduces the extra-rail problem but changes the axle ID from FA-210 to FA-105, duplicates a toe-crossmember label/leader and still fails to place the axle through the hinge lugs. It is a retained failed correction, not the final reference. Do not use it for labels or geometry.

## Archived FA-01 set — superseded appearance

2026-10-20. The original historical register follows; its selected sheets apply
only to the FA-01 mechanism/layout precedent, not the FA-02 look or dimensions.

[Design specification](../../foot-and-ankle.md) · [Parts inventory](../parts.md) · [Build steps and verification](../assembly-and-review.md)

Generated with the **built-in image generation tool**, using the imagegen skill. Grayscale and blue are drawing conventions, not a confirmed robot paint scheme. Original generated files were copied into this project so the references do not depend on an external cache.

### Selected sheets

| Sheet | File | Purpose |
| --- | --- | --- |
| 01 | [Assembled views](01-assembled-v3.png) | Silhouette, five-shell appearance, side/front views and six-pad sole layout |
| 02 | [Structure and joints](02-structure-v2.png) | Five-piece rear chassis, four-piece forefoot, angular ring, adapter, main pivots and three actuator roles |
| 03 | [Armor, sole and services](03-shells-soles-v2.png) | Removable shell ownership, two sole carriers, six pads, compression sleeves and electrical layout |

The complete source specification is **FA-01**: [dimensions](../dimensions.md), [actuators](../actuators.md), [parts](../parts.md), [hardware data](../hardware.csv) and [review](../assembly-and-review.md). The images are visual guides to those documents, not additional design decisions.

### Prompts and reference lineage

All prompts are preserved verbatim:

1. [Assembled sheet prompt](prompt-01-assembled.txt), followed by its [mechanical correction prompt](prompt-01-correction.txt). The correction used the first assembled draft as its edit target. A final [gimbal correction](prompt-01-gimbal-correction.txt) used assembled v2 as the target and structural v2 as the mechanism reference, producing selected assembled v3.
2. [Structural sheet prompt](prompt-02-structure.txt), using assembled v2 for style/silhouette only, followed by its [hardware correction prompt](prompt-02-correction.txt).
3. [Armor/sole sheet prompt](prompt-03-shells-soles.txt), using assembled v2 for shell shapes and drawing style, followed by its [panel and hardware correction](prompt-03-correction.txt).

The `*-draft-v1.png` files and assembled v2 preserve superseded image iterations for comparison. They are not the preferred reference sheets.

### Image review and authority

The initial assembled image added unrequested ankle mechanisms and only two bolt wells per pad. The corrections restored four wells on each of six pads and replaced the upright fork-like ankle depiction with a horizontal open ring in assembled v3. The structural image's incorrect nut-plate caption and external-hex bolt illustrations were corrected in v2.

The finishing-sheet correction lowers the upper plate independently of the tall guards. Some small requested hardware corrections did not fully carry through into the generated image.

Known interpretation limits:

- The finishing sheet's ghosted assembly still uses the earlier joint depiction as background context. Use **assembled v3, the structural sheet and the written horizontal-ring specification** for the ankle architecture; do not derive it from that ghosted backdrop.
- Guard/flange heights, hidden roll pins and exact bracket locations are not consistent enough across generated views to measure from pixels. Use the local datums and mounting coordinates.
- Structural explosion spacing, pin alignment leaders, bearing stacks and the small hinge inset are schematic. Derive the actual bearing seats, four short pins, single long forefoot axle and assembly directions from the dimensional document.
- The finishing sheet still shows excess recesses on the upper plate, a side-facing bolt-drive mark in the stack inset, and an inconsistent clip illustration. Use **four captive bolts per shell, an axial internal-hex drive, and one mounting screw per cable clip**, as specified. These are drawing errors, not design changes.
- Small fasteners shown in the images are representative. The numbered inventory and CSV govern totals and placement; never infer all hardware counts from a drawing.
- AI-generated views are not a shared CAD model. The image set establishes appearance and communicates assembly groups, while the later solid-model pass resolves exact geometry.

No image changes the accepted ownership of a panel or joint, introduces extra mechanisms, or alters the specified bolt schedule.
