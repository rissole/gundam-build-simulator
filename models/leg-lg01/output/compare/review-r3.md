# P6V3 — fresh visual review, round 3

2026-11-01. **The foot remains the principal geometry mismatch; nozzle-cavity lighting also needs correction.** Final-round priorities below concern achievable changes, not literal reproduction of inconsistent drawings.
Reviewed current images before consulting r1/r2; opened Blender 5.2.3 read-only for bounds and visibility rays. No new renders, model edits, saved scene, tests or commits.
All coordinates/fix targets are **leg-local metres: X inner+, Y forward, Z up, origin under ankle**. Targets are proposals, not pixel-derived measurements. Scores exclude known drawing errors and assess lighting separately.

| Section | Silhouette | Plate breakup | Colour placement | Detail density | Signature details |
| --- | ---: | ---: | ---: | ---: | ---: |
| Thigh | 3 | 3 | 4 | 3 | 3 |
| Knee | 3 | 4 | 4 | 3 | 4 |
| Shin and calf | 3 | 4 | 4 | 3 | 4 |
| Foot | 3 | 2 | 5 | 3 | 3 |

Scale: 1 poor; 3 recognizable but visibly different; 5 close within the written contract.

## Thigh

- **Minor T7 — service outline reads as a drawn rectangle.** Concept: LG-01 assembled outer side, middle of thigh, and style-sheet ACCESS HATCH show a recessed service face with a latch. Model: the closed outline is repaired, but its interior remains flush and featureless. **Fix:** recess the existing 0.50 Y × 0.95 Z field at Y−0.18/Z7.22 by 0.010–0.015 from its local outer skin; form one integral 0.055 Y × 0.16 Z latch recess at Y+0.01/Z7.22. Follow the taper near X−0.88; retain the rod channel, pad opening and existing inventory.
- **Minor T8 — taper changes too abruptly.** Concept: LG-01 assembled front/side, lower half of thigh, narrows through several deliberate planes. Model: a long nearly straight barrel ends in one conspicuous horizontal belt around Z6.65. **Fix:** distribute the lower transition through exterior half-width/depth stations 0.66 at Z6.05, 0.76 at Z6.35, 0.84 at Z6.85, reaching 0.90 at Z7.88; rebuild adjacent folds on the same stations with 0.035 backed seams. Retain upper channels and Z6.10 pad access; no extra plates or hip guards.

## Knee

- **Minor K5 — pale frontal bezel competes with the ochre shield.** Concept: LG-01 assembled front and detached LG-300 at armor-sheet left show a dominant ochre chisel with pale side returns. Model: the broad pale rim reduces the frontal ochre patch. **Fix:** retain the existing approximately 0.080 folded rim, but carry ochre 0.030–0.040 farther across its front-facing portion; leave lateral returns pale. Keep X±0.39, Z4.69…5.48, leading Y≈0.85 and the recessed bearing stack unchanged.
- No remaining major knee geometry mismatch in these views. The long rear cylinders and exposed central mechanism are required; shortening them to reproduce the concept would be wrong.

## Shin and calf

- **Minor C10 — side hatch has competing outlines.** Concept: LG-01 assembled side, central calf hatch, uses one clear perimeter with nearby restrained seams. Model: a second long groove almost meets the hatch's upper/rear corner and draws an oversized diagonal above it. **Fix:** keep the hatch at Y−0.88…−0.26/Z2.87…3.93; terminate the adjacent rear groove around Y−0.96/Z3.80, at least 0.060 clear of the hatch outline. Retain its 0.025 width/0.015 depth and the exposed Z2.80 pad.
- The lowered front saddle, white rear brow, separate nozzle apertures, bridge and exposed barrel collars now read correctly. Overall calf facets remain simpler than the drawing; do not enlarge the calf or expose whole engine bodies in this last round. The pale nozzle centres are assessed under rendering below.

## Foot — major geometry priorities, highest visual impact first

- **Major F6, priority 1 — weak shell hierarchy/segmented-toe read.** Concept: FA-02 assembled three-quarter and upper-right side show a chisel toe, distinct nose boundary and broad shell shoulder facets; armor-sheet upper-left repeats these folds. Model: the toe reads as one low slab with a painted band, and the upper shell as a horizontal shelf with vertical skirts. **Fix:** retain the mandated roof profiles; move the toe shoulder crease from |X|0.63 to 0.61, dropping 0.090 to the side at |X|0.73. Cut one 0.025-wide, 0.004-deep transverse groove at Y2.24, following the roof and continuing down the sides to Z0.30; darken its floor. This gives an apparent nose segment within FA-400, not a sixth shell. On FA-401, keep the flat central roof/bolt lands at Z0.70 and |X|≤0.65; increase the existing side-shoulder drop from 0.080 to 0.100 across |X|0.65…0.73. Retain the lower inset to |X|0.70 at Z0.20, all receiver-relief slots, the actuator relief, rear notch and hinge channel.
- **Major F7, priority 2 — broad flat guard crown still reads as a windowed shield.** Concept: FA-02 assembled side and armor-sheet top-right show tapered fins. Model: each guard has a 0.90-long horizontal crown and a large rectangular field around the cap window. **Fix:** replace only the upper contour with (Y,Z)=(-0.73,1.05),(-0.60,1.50),(-0.16,1.60),(+0.16,1.60),(+0.60,1.50),(+0.85,1.09), joining the retained lower outline. This shortens the flat crown to 0.32 while retaining both upper bolt wells. Keep walls |X|0.710…0.730, shallow 0.060–0.080 perimeter facets, all four seats, and the 0.40 Y × 0.36 Z pitch-cap window at Y0/Z1.00. A narrow single-point fin or thick frontal cheek is incompatible with the fixed seats/wall band; do not promise that silhouette.
- **Minor F8 — guard recesses dominate the hardware.** Concept: FA-02 assembled side, four guard fasteners, shows small recessed collars. Model: four 0.130-wide black octagons read as patches around tiny M12 heads. **Fix:** reduce each depression mouth to about 0.080 across, retaining the approximately 0.050 bore/floor and existing land, bolt and depth; centres remain (Y,Z)=(-0.60,0.72),(+0.70,0.72),(-0.50,1.45),(+0.50,1.45). Do not enlarge the screws or add fasteners.

### What the written FA-02 dimensions actually permit

- **Toe slope already exists:** source and side render show Y1.50/Z0.60 → Y2.40/Z0.52 → Y2.46/Z0.40. Measured FA-400 bounds are X±0.73/Y1.50…2.46/Z0.20…0.60. Preserve that profile and the four roof bolt lands; a steeper, taller toe is not an available fix.
- **Upper plate is explicitly flat at Z0.70, underside Z0.68**, not merely bounded by a maximum. Its broad rear-open notch reaches Y0.55 at X±0.59. The concept's tall rising instep cannot be copied; F6 changes shoulder folds and surface segmentation only. Heel remains within Y−0.90…−0.50/Z≤0.60.
- **Guard outline can change, bolt locations cannot.** Upper seats at Y±0.50/Z1.45 require substantial material on both sides of a narrower crown. The window exposes the specified pitch cap; filling it to imitate the concept loses a resolved access/readability feature. No roof or crossbar across the shin.
- Keep exactly five 0.020-thick shells, four captive bolts each, six pads, X±0.73/Y−0.90…2.46 and the open Y1.21…1.50 hinge channel. New folds must remain continuous skins; retain the recently added skirt clearances rather than cosmetically closing them. Recheck affected seats/removal after modelling; this review proves no new clearance.

## Rendering, lighting and finish — not geometry

- **Major R10 — pale objects remain visible inside both nozzle throats.** Concept: style-sheet CALF NOZZLES and LG-01 assembled back have dark centres with restrained bronze rims. Model: grey circular patches read as plugs inside the improved dark bronze lining. Read-only rear rays at X0/Z2.80 and 3.95 pass through LG-450 and hit the gunmetal LG-100 surface at Y−0.31: these are open throats, not capped bells. **Fix:** make cavity occlusion/shadows include the engine bore and visible receiving surfaces, rather than attenuating only bronze; reduce interior fill/reflection until the throat reads dark. Retain real openings, mouth diameter and palette; do not add a black disc or change the shin beam to conceal lighting.
- **Minor R11 — broad faces remain too pristine.** Concept: style-sheet PLATE EDGE/ACCESS HATCH and FA-02 three-quarter have restrained edge wear and local grime. Model: warm paint now separates well, but the panels still look uniformly clean. Add sparse roughness/value variation at existing seams, wells and exposed corners; preserve clean broad fields and avoid the style close-ups' heavier chipping.
- **Minor R12 — mechanical detail loses contrast at sheet scale.** Concept: both structure sheets distinguish rims, polished rods and recessed heads. Model: the dark skeleton and carrier faces merge; some foot guard faces show diagonal tonal fans. Tune the structure-view rim/fill and reset coplanar face normals where needed; leave painted facets crisp. Show carrier undersides alongside the already supplied pad undersides instead of inventing top-side holes.
- **Resolved rendering evidence:** all seven JPEG hashes and the scene match current `notes-render.md`; its probes now land on actual visible surfaces. White background, warm armor, ochre, contact shadow, orthographic three-quarter, separated labelled armor and six pad undersides are present. The recorded tone pass does not resolve R10 or establish viewer-material parity; cavity overrides are renderer-only.

## Round-one disposition, checked against current views

- **Resolved:** T1 disconnected corners; T2 square channel mouths; T3 misplaced shoulder ochre; T4 narrow inserts; K1 thin/all-ochre shield; K2 plain cap discs; C2 buried/small nozzle mouths; C3 slight bridge/rail; C4 missing shin caution outline/inserts; F1 shell-corner holes; F2 hidden pitch caps; F3 absent guard facets/wells. Preserve these repairs; F7/F8 refine their appearance, not their function.
- **Partly resolved:** C1 now has joined front corners and a sloped rear shoulder, but the side mass still looks simpler and squarer than the concept. No envelope growth is justified. R1 washout/separation and R4 missing views, perspective and explosion overlap are resolved; concept views still cannot serve as a shared dimensional scale. R2 bronze brightness improved, but R10 remains; R3 surface history remains minor R11.
- **Round-two follow-through:** T5 closed service outline, K3 frontal guard returns, C5 enclosed cradle brow, C6 front saddle, C7 caution border, C8 nozzle collars and F4 lower shell folds are visible. Prior warped-face complaints are not reasserted without new measurements. F5's thin frontal guard edge remains a written constraint. The current matching-scene sequence receipt reports no violations; its sampled checks are not a fresh motion/clearance test by this reviewer.

## Known drawing errors / constraints where the model is right

- **Knee drives:** LG-01 structure incorrectly ends them on the thigh-side fork. Current cylinders connect thigh (X±0.46,Y−0.46,Z6.40) to shin (X±0.44,Y−0.50,Z4.30); preserve the longer span and open central rear knee.
- **Proportions:** do not copy near-equal drawn thigh/calf widths or excessive ankle height. Retain hip/knee/ankle Z9.20/5.10/1.00, thigh 1.80 wide/deep →1.32, calf 1.65 →1.06 with depth≤2.24, foot 3.36×1.46, guards Z1.60. The lower-shin interface remains within 0.90×0.90 over Z1.65…2.10.
- **Hip and support details:** turnaround hip skirts belong to torso; their absence is correct. Preserve the mechanical gap above thigh, three fixed lug carriers and visible lifting pads at Z6.10/2.80 despite indistinct concept leaders. Do not close service/rod channels to match the drawing's uninterrupted thigh.
- **Foot shape/paint/counts:** LG-01's foot is placeholder context; FA-02's tall instep, shallow notch, inconsistent guard outlines and front-like rear cover are unreliable. Model correctly retains compact heel, rear-open notch, toe-only ochre, five shells/four bolts each; extra guard/heel ochre, hatch panels and shell bolts are drawing drift.
- **Foot mechanisms/soles:** current two rear/two forefoot rails, three independent drives, roll behind ring, four short ankle pins and continuous forefoot axle at (0,1.34,0.35) follow the specification. Reject the concept's third rail, axle at toe crossmember, ambiguous connected drive eyes and crossing ankle shaft. Six pads, forefoot length 0.96 versus heel 0.74, and 6/4 carrier mounts are correct despite the schematic drawing.

## Evidence

Inspected all seven comparison sheets and direct LG-01 v3 assembled/armor/structure, preferred FA-02 assembled/armor/structure, turnaround-v3 and style-sheet-v3; enlarged current leg front/side/back and foot side/three-quarter/armor renders. Read both drawing-error registers, proportions, component specifications, FA-02 dimensions, relevant generators, r1/r2 and current render notes. Only this review file written.

| Reviewed file | SHA-256 |
| --- | --- |
| cmp-lg01-assembled.jpg | `1f046dd3eb66c0063776729562f757f131d997e4d3ec8117e68672c3de577f43` |
| cmp-lg01-armor.jpg | `194f60ec45de40d89f90b8b6a67d2fa8c07b15005dee0869838f34202e231e2c` |
| cmp-lg01-structure.jpg | `76ec0b2e9087c7e5e5a7ee0dbdfb4fc1d312c5019c2cf2cb33f81ae82594ec13` |
| cmp-fa02-assembled.jpg | `e27092e1ac4112b43c68e0b4519d28a13ea5383cb9941bfaa572336bb0924cdc` |
| cmp-fa02-armor.jpg | `2e73be38a7e64f4b6d05a69d287d86ed45c896f79d4eec8707d1864604c86b2e` |
| cmp-fa02-structure.jpg | `92af4f75c3ae33ea661a96184ed9abef11b245cc1c33161e1ea955051560569b` |
| cmp-turnaround-leg.jpg | `73e18edfaf3e5695f02e9365c8fc0e7095cc3dd35959cfaebadd4f66e8351a49` |
| ../leg-lg01.blend (read-only) | `f60bc18feb862a8ffba4185b7c7ad31ce3536679bae38429723f2ed20733d994` |

This is inspected visual evidence plus limited measurements, not animation, assembly-path or player approval. Apply the ranked feasible fixes once; record any remaining appearance differences after this final round.
