# P6V2 — fresh visual review, round 2

2026-11-01. **Major calf mismatches remain; most round-one repairs are visible.** Reviewed existing images afresh before reading r1. No new renders, model changes, Blender saves, behavior tests or commits.
Coordinates and proposed fixes are leg-local metres: **X inner+, Y forward+, Z up; origin under ankle**. Proposed dimensions are modelling targets, not measurements from concept pixels. Written envelopes, interfaces and drawing-error registers govern.

| Section | Silhouette | Plate breakup | Colour placement | Detail density | Signature details |
| --- | ---: | ---: | ---: | ---: | ---: |
| Thigh | 3 | 3 | 4 | 3 | 3 |
| Knee | 3 | 4 | 4 | 3 | 4 |
| Shin and calf | 3 | 3 | 4 | 3 | 3 |
| Foot | 3 | 3 | 4 | 3 | 3 |

Scale: 1 poor correspondence; 3 recognizable with substantial differences; 5 close after correcting drawing errors. Lighting is assessed separately; specified openings and hardware counts are not penalized.

## Thigh

- **Minor T5 — weak outer-side service breakup.** Concept: LG-01 assembled three-quarter, outer thigh side has a distinct inset service outline; armor LG-210 has articulated corner details. Model: broad side field with an isolated L-shaped groove. **Fix:** complete one integral 0.50 Y × 0.95 Z outline centered near (X−0.87,Y−0.18,Z7.22), following the tapered surface; use a 0.025-wide/0.015-deep groove, no new panel object. Keep the forward rod channel and Z6.10 lifting-pad opening clear.
- **Minor T6 — irregular folded faces.** Concept: LG-01 assembled front, lower thigh facets and caution-panel rim have clean straight transitions. Model: lower corners and the groove above the caution panel produce wedge-shaped dark edges. Read-only mesh inspection finds painted LG-200 quads deviating up to 0.018 m from their face planes. **Fix:** split/rebuild returns at Z6.05/6.65 and project groove floors onto each local plane; use explicit planar facets, 0.025 groove width and 0.035 backed seams. Preserve X/Y±0.90 and lower width 1.32.

## Knee

- **Minor K3 — knee width/readability remains open.** Concept: LG-01 assembled front and turnaround front show a compact, substantial joint flanking the shield. Model: narrow frontal hinge mass and edge-on guards leave long dark slots; measured guard span is 1.34, shield width 0.78. **Fix:** first form 0.08–0.12-wide front-facing guard returns within |X|0.55…0.67, Y+0.42…+0.50, Z4.88…5.38. Retain axis (0,0,5.10), bearing seats and recessed caps; do not widen the axle from concept pixels. No authoritative revised knee width is selected.
- **Minor K4 — pale shield returns are warped.** Concept: LG-01 armor, detached LG-300 left of knee, has deliberate planar chisel flanks. Model: volume and pale rim are now present, but measured rim quads deviate up to 0.014 m from planar. **Fix:** divide flank patches at the Z5.17 ridge and into intentional planar triangles; retain X±0.39, Z4.69…5.48, front Y+0.85 and perimeter Y+0.61…+0.64. Keep the rear open around the bracket.

## Shin and calf

- **Major C5 — cradle emerges through the upper shroud.** Concept: LG-01 assembled back, white brow with red caution above the upper nozzle; armor LG-420 encloses the cradle. Model: dark stacked triangular metal breaks through that brow. Current-scene rear rays at X0/Z4.45…4.55 hit LG-440 ahead of LG-420; cradle reaches Z4.629, shroud stops Z4.60. **Fix:** reprofile the upper cradle crown to Z≤4.55 and reform the local shroud brow near Y−1.20/Z4.40…4.60, leaving ≥0.030 solid clearance. Preserve engine seats, total depth ≤2.24 and the central rear knee opening; check cylinder clearance after reshaping.
- **Major C6 — upper shin outline reverses the concept's knee recess.** Concept: LG-01 assembled front and turnaround front, raised lateral shoulders flank a lowered central saddle beneath the kneecap. Model: LG-400 rises centrally to Z4.67, with a drawn chevron below; it reads as a capped column. **Fix:** shape the front top into a saddle: shoulder peaks near X±0.60/Z4.60, descending to X±0.28/Z4.36 across the centre, on Y≈+0.54. Fold 0.08–0.12 shoulder facets into the existing plate/side shells; preserve maximum width 1.65 and knee-bracket access.
- **Minor C7 — lower caution-panel border still disappears.** Concept: LG-01 assembled front, a small framed inset terminates the shin. Model: caution text and two bolts remain, but the enclosing outline is not readable even in the enlarged front render. **Fix:** recut a closed 0.65×0.30 outline around X0/Z2.05, projected onto the actual front skin, 0.025 wide/0.015 deep with a dark floor. Keep it integral to LG-400 and preserve the ankle taper.
- **Minor C8 — exposed bells lack the reference's barrel detail.** Concept: LG-01 assembled side and style-sheet calf detail show dark circumferential bands behind bronze lips. Model: enlarged mouths are exposed correctly, but the side silhouette reads as two plain flared cones. **Fix:** add integral 0.04–0.06 axial collar bands immediately forward of the lips at (0,−1.55,2.73)/(0,−1.55,3.88), retaining Ø0.78 mouths, 12° downward axes and Y≥−1.64. Keep most engine bodies enclosed.
- **Minor C9 — shroud return topology remains uneven.** Concept: LG-01 armor, LG-420 side folds are deliberate planar surfaces. Model: rear-side folds have abrupt diagonal bands; current LG-420 has painted quads with up to 0.032 m nonplanarity. **Fix:** reconstruct the returns around |X|0.60…0.81, Y−1.20…−1.40, Z2.40…4.25 as planar patches at each profile station; keep 0.035 seams and independent nozzle apertures. This is separate from the C5 interference and cannot be fixed by lights.

## Foot

- **Minor F4 — lower shell sides remain slab-like.** Concept: FA-02 assembled three-quarter/side, toe and upper-shell sides turn inward toward the sole with distinct lower facets. Model: continuous corners are repaired, but broad vertical side walls read as rectangular blocks. **Fix:** introduce a 0.08–0.10-high lower facet over Z0.20…0.30, bringing the bottom edge inward to X±0.70 from ±0.73. Preserve 0.020 skin, roof/bolt datums, the rear notch and hinge channel; check frame/receiver clearance before adopting the inset.
- **Minor F5 — ankle guards read as thin walls in front (known open).** Concept: FA-02 front shows substantial faceted white cheeks; model front shows almost hairline edges and prominent receiver arms. The specified wall really is only 0.020, at |X|0.710…0.730. **Fix boundary:** a 0.06–0.08 front-facing return would require a revised guard/clearance contract; it cannot be added inside the current wall band without consuming the moving-core clearance. Retain the correct walls and Z1.60 tops for now; do not silently bulk them up to the drawing.

## Separate assembly limitation

- **Major open sequence exception — FA-401-L upper plate versus FA-103-L cradle.** The FA-02 armor sheet suggests vertical separation, but its arrows do not prove access. Current sequence audit records actual mesh contact at step 40, progress 0.60/0.70/0.80: the low skirt/locator region crosses a high cradle receiver on the +Z approach/removal corridor (offsets +1.20/+0.90/+0.60 during a 3 m descent). Revise the skirt relief or receiver support to retain ≥0.010 clearance throughout that corridor while preserving the four shell bolt axes and two 0.010-engagement tabs; otherwise author a verified tipped/multiple-segment path. The existing straight-translation exception is not a clearance pass. Not included in visual scores; no fresh motion test performed here.

## Rendering, lighting and surface finish — not geometry

- **Major R5 — tonal evidence is stale and the current thigh is overbright.** Concept: LG-01 front retains warm paint and shaded corner separation. Current model front/side shoulders approach white; the foot's pale wells lose depth. Keep the palette; rebalance key/fill and recapture visible, correctly placed tone probes. `notes-render.md` describes scene `e2ae7efd…`, not the later render receipt `97360c2a…`; its passing swatches cannot certify these sheets. The later `work/renders/tone-probe.json` reports front thigh RGB 246/234/220 and an occluded shaded-thigh probe, so its separation metric is unusable.
- **Minor R6 — bronze still reads as a bright funnel.** Concept: style-sheet calf close-up has dark throats and restrained gold rims. Model: broad uniformly gold interiors dominate the rear. Use directional reflections and stronger interior occlusion while retaining bronze lining/gunmetal exterior; do not shrink mouths to solve tone.
- **Minor R7 — weak surface history and pale foot wells.** Concept: style-sheet bolts/hatches and FA-02 guards have dark recessed wells, restrained chips and local grime. Model: pristine broad fields, large white guard depressions and tiny dark heads. Improve recessed-face material contrast and subtle wear/roughness around existing lands; retain four M12 bolts per shell and avoid enlarging heads or adding fasteners.
- **Minor R8 — three-quarter perspective distortion remains open.** The 50 mm horizontal-fit portrait camera exaggerates the near foot and reduces upper-leg mass relative to the concept. Use orthographic or a more distant long-lens camera with matched view angles/framing for shape judgment; keep perspective only as a separate presentation view. The reflected side label is correct. Concept views do not share a reliable dimensional scale.
- **Minor R9 — exploded evidence is cramped.** Concept armor sheets separate and label plates, engines and all six pads. Model LG-01 explosion overlaps rear parts; FA-02 pads/carriers overlap and show their uninformative upper faces. Increase display offsets, label instances and add an underside pad view; preserve actual installation paths. Ground contact shadow and the missing LG-01 armor/turnaround sheets from r1 are now supplied.

## Round-one disposition

- **Resolved in inspected views:** T1 corner daylight, T2 square channel mouths, T3 rearward shoulder accent, T4 narrow inserts; K1 sheet-like shield, K2 plain cap discs; C2 buried/small nozzle mouths, C3 undersized bridge/thin rail; F1 shell-corner holes, F2 hidden pitch caps, F3 absent guard facets/wells. Keep these repairs.
- **Partly resolved:** C1 front/side joins and rear slope improved, but C5/C6 remain; C4 wider inserts fixed, lower inset still fails visually (C7). R1 warmer/darker separation improved but is not accepted (R5); R2 bright bronze and R3 pristine finish remain. R4 missing sheets/contact shadow resolved; matched perspective, scale and exploded readability remain open.

## Drawing errors and constraints where the model is right

- **LG-01 knee cylinders:** structure drawing terminates them on the thigh-side fork. Model correctly spans thigh eyes (X±0.46,Y−0.46,Z6.40) to shin eyes (X±0.44,Y−0.50,Z4.30); preserve the longer visible rods and independent rear opening.
- **Proportions:** ignore nearly equal drawn thigh/calf widths and exaggerated ankle height. Preserve hip/knee/ankle Z9.20/5.10/1.00; thigh 1.80 wide/deep →1.32; calf 1.65 →1.06 and 2.24 depth including engines; foot 3.36×1.46 and guards Z1.60. Existing envelope audit reports 1.800/1.800 thigh, 1.652 calf width, 2.231 depth and 1.065 lower width; these are prior audit measurements, not new acceptance tests.
- **Hip ownership and access:** turnaround hip skirts belong to torso, not thigh. Correct model has no hip guards, a mechanical gap above Z8.23 armor, and three fixed lug carriers. Retain rod channels and exposed lifting pads at Z6.10/2.80 despite indistinct drawing leaders; central rear knee stays unarmored.
- **Foot openings/shape:** LG-01 foot is placeholder context; FA-02 view scale, tall-looking guards and shallow notch are unreliable. Correct rear-open notch is X±0.59, Y−0.50…+0.55; upper plate top Z0.70; unbridged hinge channel Y1.21…1.50. Do not fill the ankle opening, raise the roof, narrow the guard crown past its bolt sites or add a roof across the shin.
- **Foot inventory/paint:** retain five shells, four captive bolts each, two carriers and six pads. Drawn extra shell bolts/hatches and ochre guard/heel accents are drift; model's toe-only ochre and compact heel are correct. Forefoot pads 0.96 long versus heel pads 0.74 follow the spec, unlike the armor drawing.
- **Foot mechanisms:** correct two rear/two forefoot rails, independent three drives with roll behind the ring, four short ankle pins and FA-210 through hinge H=(0,1.34,0.35). Do not copy the extra central rail, axle through toe crossmember, connected actuator eyes or the rejected v3's FA-105 axle label. Carrier mounts remain 6/4; schematic holes/leaders are not hardware authority.

## Evidence and limits

Inspected all seven current comparison JPEGs; all direct LG-01 v3 concepts, preferred FA-02 sheets and retained variants, turnaround v3 and style-sheet v3; enlarged current leg front/side/back and foot front/side/explosion renders. Read both image registers, proportions, relevant component/FA-02 specifications, generators, r1, render notes and existing sequence/envelope evidence. Blender 5.2.3 opened read-only for bounds, face-planarity measurements and rear visibility rays; no save or new rendered approval.
Current scene hash below differs from the render receipt's `97360c2a…` and the older lighting note's `e2ae7efd…`. Scores apply to the hashed JPEGs; current-scene measurements corroborate findings but do not establish capture/source identity or motion clearance.

| Reviewed file | SHA-256 |
| --- | --- |
| cmp-lg01-assembled.jpg | `45ee6e2747c89cf63ee0d21745a068891595505a54921e365bb1d688ae6fc8bf` |
| cmp-lg01-armor.jpg | `3be67a1e6e241e6ec72221053e49e3ef69876e814700d6f84d6999f55511962f` |
| cmp-lg01-structure.jpg | `638fb70ac9ba4d9b1d871ba737f685436c3faf340767f12febc911b7a8ddd448` |
| cmp-fa02-assembled.jpg | `49f6ec06f78a8b29731257c324208d9843ef19113df7fad329751cf4d7ee006a` |
| cmp-fa02-armor.jpg | `bb88a494e6e2cec48dc7fcfd6900c4a8a537594b4ac8a34f80b9b00c136c2e74` |
| cmp-fa02-structure.jpg | `811d9a82c795a2d338f3f8b2279b5a7183bccb3ab9a534737eedce2e8e6fec99` |
| cmp-turnaround-leg.jpg | `96859622414bed9b74048b480ad978a6f4ade09c6070d9deef0938e2eeb91fef` |
| ../leg-lg01.blend (measured, unsaved) | `71838631325edabb9883d3b484bd55aeedfb8e16e3f1427e37b87e03cc5ef09f` |
