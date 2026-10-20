# FA-01 foot reference images

2026-10-20 · **Initial concept set for user review; not user-approved**

[Design specification](../../foot-and-ankle.md) · [Parts inventory](../parts.md) · [Build steps and verification](../assembly-and-review.md)

Generated with the **built-in image generation tool**, using the imagegen skill. Grayscale and blue are drawing conventions, not a confirmed robot paint scheme. Original generated files were copied into this project so the references do not depend on an external cache.

## Selected sheets

| Sheet | File | Purpose |
| --- | --- | --- |
| 01 | [Assembled views](01-assembled-v3.png) | Silhouette, five-shell appearance, side/front views and six-pad sole layout |
| 02 | [Structure and joints](02-structure-v2.png) | Five-piece rear chassis, four-piece forefoot, angular ring, adapter, main pivots and three actuator roles |
| 03 | [Armor, sole and services](03-shells-soles-v2.png) | Removable shell ownership, two sole carriers, six pads, compression sleeves and electrical layout |

The complete source specification is **FA-01**: [dimensions](../dimensions.md), [actuators](../actuators.md), [parts](../parts.md), [hardware data](../hardware.csv) and [review](../assembly-and-review.md). The images are visual guides to those documents, not additional design decisions.

## Prompts and reference lineage

All prompts are preserved verbatim:

1. [Assembled sheet prompt](prompt-01-assembled.txt), followed by its [mechanical correction prompt](prompt-01-correction.txt). The correction used the first assembled draft as its edit target. A final [gimbal correction](prompt-01-gimbal-correction.txt) used assembled v2 as the target and structural v2 as the mechanism reference, producing selected assembled v3.
2. [Structural sheet prompt](prompt-02-structure.txt), using assembled v2 for style/silhouette only, followed by its [hardware correction prompt](prompt-02-correction.txt).
3. [Armor/sole sheet prompt](prompt-03-shells-soles.txt), using assembled v2 for shell shapes and drawing style, followed by its [panel and hardware correction](prompt-03-correction.txt).

The `*-draft-v1.png` files and assembled v2 preserve superseded image iterations for comparison. They are not the preferred reference sheets.

## Image review and authority

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
