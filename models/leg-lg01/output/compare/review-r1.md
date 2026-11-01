# P6V1 — fresh visual review, round 1

2026-11-01. **Major mismatches remain in all four sections.** Existing renders inspected afresh; no new renders, geometry edits, saves to Blender, or behavioral tests. Blender 5.2.3 opened the scene read-only for mesh bounds.
Coordinates below are leg-local metres: X inner+, Y forward+, Z up, origin under ankle. Fix dimensions are proposed modelling targets, not measurements inferred from concept pixels. Preserve written interfaces and movement corridors.

| Section | Silhouette | Plate breakup | Colour placement | Detail density | Signature details |
| --- | ---: | ---: | ---: | ---: | ---: |
| Thigh | 2 | 2 | 3 | 2 | 2 |
| Knee | 3 | 2 | 4 | 3 | 3 |
| Shin and calf | 2 | 2 | 4 | 2 | 2 |
| Foot | 3 | 2 | 4 | 2 | 3 |

Scale: 1 poor correspondence; 3 recognizable with substantial differences; 5 close correspondence after correcting drawing errors. Lighting is assessed separately.

## Thigh

- **Major T1 — disconnected plate corners.** Concept: LG-01 assembled three-quarter/front, upper thigh has broad shoulder facets and closely fitted front/side plates. Model: LG-200/210/215 read as thin separated screens, with long open corner wedges. **Fix:** form folded corner returns across X≈±0.65…0.90, Y≈+0.55…+0.90, Z6.2…8.23; use 0.08…0.12-wide transition facets and 0.025…0.040 assembly seams. Keep the 1.80 maximum width/depth and 1.32 lower taper; preserve required rod channels.
- **Minor T2 — square channel mouths.** Concept: LG-01 armor, upper central thigh, channels sit within shaped shoulders. Model: two rectangular front cuts dominate Z7.25…8.23 and make a castellated top. **Fix:** retain channels around X−0.339/+0.464 and their required swept clearance; facet their mouths 0.06…0.10 wide and return the edges inward 0.06…0.10 to frame the exposed mechanism. Do not bridge the cylinder paths just to match the drawing.
- **Minor T3 — misplaced shoulder accent.** Concept: LG-01 assembled three-quarter, ochre wraps the outer/front upper corner. Model: a small rounded patch sits on the outer/rear side at Y−0.44, Z7.91 and protrudes to X−0.926. **Fix:** paint an angular approximately 0.25×0.40 region on the existing forward shoulder around X−0.82, Y+0.55, Z8.0; follow its facets and keep paint inside X−0.90. Add no hip-guard part.
- **Minor T4 — thin black marks.** Concept: LG-01 assembled front and armor LG-200, broad dark inserts flank the clean central plate. Model: 0.08×0.62 slots look like narrow cuts. **Fix:** use approximately 0.15×0.85 gunmetal inset faces near X±0.60, Z7.25, following the front surface in Y; give each a 0.025 border and about 0.02 relief without enlarging the envelope.

## Knee

- **Major K1 — kneecap lacks volume.** Concept: LG-01 armor, detached LG-300 at left, has an ochre chisel face, substantial folded flanks and a pale rim. Model: side render shows a thin bent sheet hanging forward on its bracket; all visible shield faces are ochre. **Fix:** retain X±0.39 and Z4.69…5.48, keep the leading ridge near Y+0.85, and fold the perimeter back toward Y+0.62…0.68 with 0.08…0.12-wide facets. Paint the narrow side returns off-white, keeping the main face ochre and the bracket/joint clearance open.
- **Minor K2 — flat guards and caps.** Concept: LG-01 assembled side and armor LG-320/325, the bearing reads as layered concentric metal inside a sculpted angular guard. Model: an almost planar white octagon surrounds a plain dark disc. **Fix:** keep the axis at (0,0,5.10), guard outer faces at X±0.67 and cap diameter about 0.55; form 0.06…0.08-wide guard facets and two stepped cap rings with 0.015…0.025 axial relief. Preserve the recessed face and open central rear knee.

## Shin and calf

- **Major C1 — boxy calf and open front corners.** Concept: LG-01 assembled side/three-quarter, the calf has an upper bulge, sloped shoulders and joined faceted armor. Model: the large side plate and high rear wall form a box, while daylight separates shin and side plates. **Fix:** join front/side edges with 0.08…0.12 folded facets and 0.025…0.040 seams around X±0.65…0.825, Y+0.45…+0.60, Z2.2…4.35. Slope the rear shoulder from approximately (Y−1.40,Z4.15) to (Y−0.75,Z4.60); retain 1.65 upper width, 1.06 ankle taper and 2.24 total depth including nozzles.
- **Major C2 — buried signature nozzles.** Concept: LG-01 assembled side/back and style-sheet “CALF NOZZLES,” two broad dark bells with bronze rims remain visible beyond the surrounding recess. Model: Ø0.64 mouths end at Y≈−1.47 behind shroud Y−1.64; side view loses both bells, and back view reads as small bright funnels. **Fix:** bring the local recess face forward to Y≈−1.38…−1.42; target Ø0.76…0.80 mouths centered near (0,−1.55,2.73)/(0,−1.55,3.88), retaining approximately 12° downward axes. Keep every lip at Y≥−1.64, reshape each angular opening around its bell, and adjust the cradle locally. Keep most engine bodies enclosed.
- **Minor C3 — bridge and rail too slight.** Concept: LG-01 armor LG-430 and LG-470 beside calf hatches, a substantial bridge and bent ochre handle have clear depth. Model: bridge skin is only 0.155 high; the rail resembles a thin stripe. **Fix:** with C2 spacing, make the bridge about 0.22 high centered at Z3.305, Y≈−1.40, with 0.025 seams; use a 0.05…0.06 rail section, 0.08 stand-off and 0.65 span centered near Y+0.22/Z3.58. Recess its mounting pocket so outer X stays within ±0.825.
- **Minor C4 — weak lower shin panel and inserts.** Concept: LG-01 assembled front, a framed caution panel terminates the shin and broad black inserts flank it. Model: the bottom reads as a blank end strip; 0.12-wide slots are visually thin. **Fix:** complete an integral inset outline approximately 0.65×0.30 centered at X0/Z2.05 on the front surface, using a 0.025-wide, 0.015-deep groove; widen the existing inserts to about 0.16 near X±0.52/Z2.95. Preserve LG-400 as one removable plate.

## Foot

- **Major F1 — gaps within individual shells.** Concept: FA-02 armor, detached toe/upper/heel shells, folded roofs meet their side walls continuously. Model: close-ups show triangular holes at toe nose corners, upper-plate front shoulders and heel roof/side junctions. These are separate from the required open hinge channel. **Fix:** make continuous 0.020-thick folded skins at X≈±0.63…0.73/Y2.36…2.46/Z0.40…0.52, X≈±0.65…0.73/Y1.13…1.21/Z0.54…0.70, and heel X≈±0.63…0.73/Y−0.90…−0.50/Z0.50…0.60. Resolve corners with 0.06…0.10 facets within each existing shell, retaining five shells.
- **Major F2 — ankle guards conceal the joint from the side.** Concept: FA-02 assembled side/three-quarter concentrates visible mechanics around the ankle; the written design requires guards to expose pitch caps. Model: each broad uninterrupted guard hides the cap and ankle core in the side render. **Fix:** cut a chamfered access window approximately 0.40 in Y ×0.36 in Z, centered at (Y0,Z1.00), through each 0.020 wall at X±0.71…0.73; use 0.06 corner cuts. Retain the four prescribed bolt sites, top Z1.60, separate lateral removal and open guard top/front/rear. Do not narrow the whole guard to the inconsistent concept outline.
- **Minor F3 — featureless guard perimeter.** Concept: FA-02 armor, detached guards, perimeter facets and local recessed lands articulate the surface. Model: the broad white wall has a roughly 0.005 edge bevel and tiny undifferentiated wells. **Fix:** form 0.06…0.10-wide shallow perimeter facets within the 0.020 wall, and octagonal depressions around the existing four M12 seats at (Y,Z)=(−0.60,0.72),(+0.70,0.72),(−0.50,1.45),(+0.50,1.45); preserve the screws and receiver axes, with no extra fasteners or ochre guard strips.

## Rendering, lighting and surface finish — separate from geometry

- **Major R1:** all model sheets have weak contact/cavity shadows; armor approaches flat white and frame approaches mid-grey. The concepts retain warm paint, darker joints and stronger facet separation. Preserve palette values; reduce fill/world contribution relative to the soft key, improve contact shadows, and compare equal-exposure material swatches before changing paint colours.
- **Minor R2:** bronze interiors are uniformly bright, suppressing nozzle depth. Use more directional studio reflections and stronger interior occlusion; keep bronze on lining/lips and gunmetal on external bodies. Reassess after C2.
- **Minor R3:** concepts show restrained edge chipping/grime and readable caution bars; model surfaces look pristine and markings become faint at sheet scale. Strengthen subtle wear/roughness variation and decal contrast locally, without copying the style-sheet close-ups' heavier wear or adding geometry.
- **Minor R4:** model and concept panels use different scales, framing and perspective; pure-white compositing provides no floor contact shadow. Align joint landmarks and pixels per metre for orthographic comparisons, add a soft ground shadow, and retain separate detail crops. Existing sheets do not include the requested LG-01 armor explosion or a matched turnaround-leg comparison.

## Drawing errors and constraints where the model is right

- **LG-01 cylinders:** structure sheet incorrectly ends them on the thigh-side fork. Model runs from thigh eyes (X±0.46,Y−0.46,Z6.40) to shin eyes (X±0.44,Y−0.50,Z4.30); preserve this span, even though it looks longer than the drawing.
- **LG-01 proportions:** do not equalize thigh/calf widths or raise the ankle to match pixels. Model/source preserve hip/knee/ankle Z9.20/5.10/1.00, thigh body 1.80×1.80 tapering to 1.32, calf body 1.65 tapering to approximately 1.06, and 2.24 depth. Including accents/rails, current extrema are 1.826/1.690 wide; these are not exact 1.80/1.65 measurements.
- **Hip ownership/gap:** the turnaround's overlying hip guards belong to the torso. Model correctly omits them, exposes the ball/neck above the thigh, and includes three distinct lug carriers; do not add guards or move carriers to imitate vague leaders. Required rod channels remain necessary despite T2.
- **Rear knee and lifting pads:** model leaves the central rear unarmored and exposes structural pads near Z6.10/2.80. Do not cover them to mimic indistinct dark details in LG-01.
- **Foot envelope/upper opening:** LG-01's foot is placeholder context; FA-02 views have inconsistent scale and shallow notch depictions. Model follows X±0.73/Y−0.90…+2.46, shell top Z0.70, guards Z1.60, rear-open notch X±0.59 to Y+0.55, and unbridged Y1.21…1.50 hinge channel. These openings are not F1 defects.
- **Foot shell count/colour:** model's five shells, four captive bolts per shell, compact heel and toe-only ochre follow the written design. Do not add the drawings' extra panels, bolts, ochre guard/heel edges, or a roof across the shin.
- **Foot structure:** preferred FA-02 structure v2 adds a third rear rail and misplaces the long axle. Model has two rear/two forefoot rails and FA-210 at Y1.34/Z0.35 through the hinge; its three drives remain independent, with roll behind the ring. Preserve the short ankle-pin arrangement rather than inventing a crossing shaft or connecting actuator eyes together.
- **Soles:** model's forefoot pads are longer than heel pads (0.96 versus 0.74 in Y), with six pads and four bolts each. The armor drawing's shorter forefoot pair and schematic excess carrier holes must not replace the specified geometry/counts.

## Evidence

Inspected all five comparison JPEGs; direct LG-01 v3 sheets, final FA-02 sheets and retained variants (v2 is the selected structure), turnaround v3 and style-sheet v3; enlarged leg three-quarter/side/back and foot side/three-quarter renders. Read both image registers, proportions, component specifications, FA-02 dimensional revision and relevant generators. This is visual review plus read-only measurement, not movement-clearance approval.

SHA-256 of reviewed comparison files and measured scene:

- `armor-vs-lg01-assembled.jpg`: `1cf1b7f58ac76d81939bb1c6433e8b76a4a6a3157fb5e6e7324524de6149b8cd`
- `skeleton-vs-lg01-structure.jpg`: `e984215f7dd192ddf2a1e4073552b1bfb2408b223f70cf6455cbbc2cc081dd13`
- `foot-skeleton-vs-fa02-structure.jpg`: `944721f45cc980ebdfde10945a75b520060911b638e7b35da27aeb1fc4e1f7e8`
- `foot-vs-fa02-assembled.jpg`: `f73942aee1a3f9387b461092b969d73f401e4a2b1c3592258cf6c32ba0f8c7ba`
- `foot-vs-fa02-armor.jpg`: `47aa46439cf23581bd7326cddf6c4ee2f8ca6873face1f249cf2e22fcde1029d`
- `../leg-lg01.blend`: `c8257a9bf42e97a4fa93c50acb0b0b13a1159b234fe6b2d9f350ea97b2275616`
