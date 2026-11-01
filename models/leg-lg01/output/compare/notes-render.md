# P6R2 — measured lighting and camera round

2026-11-01. **Four lighting rounds completed; targets are not all met.** All seven
comparison sheets and 14 individual views were regenerated from the current shared
blend. No commit; no generator edits; the shared blend was never saved.

Lit thigh/calf, ochre, knee gunmetal and white-background patches pass. The front
side-facet sample remains too bright (196.9 versus 165–190), with only 19.4 points
of separation versus the required 30. The three-quarter side facet is slightly
too dark (163.3), while its separation passes at 54.0. Stopped at the requested
four-round limit; this is measured progress, not complete tonal acceptance.

## Final probe table

Per-channel median sRGB, followed by Rec.709-weighted **sRGB code value Y′**, not
linear luminance. Neutral brightness ranges are tested on Y′; lit armor also
requires every RGB channel ≤235. Ochre is checked per channel against
(205,135,40) ±20. These are patch checks, not a guarantee that every specular edge
in every sheet stays below 235.

| Region | Concept RGB / Y′ | Front RGB / Y′ | Three-quarter RGB / Y′ |
| --- | --- | --- | --- |
| lit_thigh | (224, 214, 204) / 215.4 | (225, 215, 203) / 216.3 **PASS** | (226, 216, 204) / 217.3 **PASS** |
| shaded_thigh | (191, 174, 160) / 176.6 | (202, 196, 191) / 196.9 **MISS** | (171, 162, 153) / 163.3 **MISS** |
| ochre_kneecap | (230, 148, 52) / 158.5 | (223, 144, 43) / 153.5 **PASS** | (220, 141, 38) / 150.4 **PASS** |
| dark_knee | (50, 50, 50) / 50.0 | (67, 66, 64) / 66.1 **PASS** | (85, 85, 83) / 84.9 **PASS** |
| calf_front | (222, 211, 201) / 212.6 | (227, 217, 205) / 218.3 **PASS** | (226, 216, 204) / 217.3 **PASS** |
| background | — | (255, 255, 255) / 255.0 **PASS** | (255, 255, 255) / 255.0 **PASS** |
| Lit − shaded Y′ | 38.8 | 19.4 MISS | 54.0 PASS |

Concept image: `design/legs/images/lg01-assembled-v3.jpg` (1536 × 1024).
Fixed concept patch centres, radius 4 px: thigh `(1030,270)`, shaded side facet
`(960,360)`, kneecap `(1030,452)`, knee joint `(1090,425)`, calf `(1030,550)`.
The concept itself is not forced into the target bands: its selected ochre is
redder/brighter than the target and its knee joint is darker.

Render patches are derived by ray casting onto named parts, then using
`bpy_extras.object_utils.world_to_camera_view`. JSON records the world point,
part/instance, material, screen position and camera-ray visibility. Most patches
are 9 × 9 px. The front view exposes only a thin side facet, requiring 3 × 3 px;
its value is therefore especially sensitive to a grazing highlight. No subject
recoloring or local tone correction is applied during composition.

| Region | Surface anchor | Front pixel | Three-quarter pixel |
| --- | --- | --- | --- |
| lit_thigh | LG-200: 0.000, 0.752, 7.000 | (408, 572) | (374, 623) |
| shaded_thigh | LG-210: -0.760, 0.666, 7.000; oblique LG-210: -0.775, -0.250, 7.000 | (547, 572) | (564, 628) |
| ochre_kneecap | LG-300: 0.000, 0.828, 5.100 | (408, 920) | (368, 925) |
| dark_knee | LG-110: -0.430, 0.340, 5.100; oblique LG-330: -0.619, 0.000, 5.100 | (486, 920) | (518, 919) |
| calf_front | LG-400: 0.000, 0.545, 3.300 | (408, 1249) | (396, 1175) |

The front knee sample is the exposed LG-110 fork face; the oblique sample is the
LG-330 outer bearing cover. The side-facet samples both belong to LG-210: its
forward bevel in front view and its broad outer surface in three-quarter view.
They are visible representatives of the same region, not an identical face.

## Final settings

- Blender 5.2.3 LTS, EEVEE, 32 samples, ray tracing and fast GI enabled. Standard
  transform, look None, exposure 0, gamma 1. AgX was replaced because its highlight
  compression/desaturation made the ochre hard to keep saturated at the desired
  plate brightness. White world strength 0.055 (previous renderer: 0.06).
- Three area lights, no overhead fill. Leg-view key: **66,600 W**, disk diameter
  **30 m**, at `(34.754,34.754,39.215)`, aimed at `(0,0,4.8)` — azimuth 45°,
  elevation 35°. Opposing fill: **19,980 W**, diameter **36 m**, elevation 15°,
  **30% of key**. Rear outer rim: **18,000 W**, diameter **24 m**, elevation 10°.
  The distant large sources reduce thigh-to-calf inverse-square brightness
  variation while retaining soft shadows. Power scales with subject size squared.
  CLI key/rim values 1850/500 are normalized at 10 m; the sixfold distance scale
  multiplies actual wattage by 36.
- Front and three-quarter share the same world-space lighting. Other views rotate
  the rig around the subject for readable side/back/structure presentation; their
  unsampled plate tones are not certified by the front/three-quarter probe.
- Assembled three-quarter: perspective **50 mm**, 36 mm horizontal sensor fit,
  camera `(-4.728,6.439,6.228)`, target `(0.288,0.019,4.644)`, **11° elevation**,
  **38° off front toward −X outer side**. Projected full-leg height **88.66%**.
  The narrow portrait render uses a wide vertical field of view; this is not a
  standard full-frame portrait sensor crop. Side/front/back remain orthographic,
  scale 10.615 m. Outer side is still reflected for display and labelled.
- Transparent subject renders are composited onto RGB `(255,255,255)`. Actual
  white-floor shadow/clear passes supply a grey contact shadow; a soft mask keeps
  distant shadows from ending abruptly at the panel boundary. No new lighting
  round was run for that composition cleanup. On the final oblique JPEG, the
  isolated neutral-grey contact-shadow pixels in the bottom 20% (excluding a
  dilated subject mask, restricted to values 180–245) have median **225**,
  observed range **191–245**, 21,446 pixels. This conditional statistic describes
  retained shadow, not the entire background.

## Material and generator findings

The loaded armor base color is linear `(0.644480,0.577580,0.502886)`, correctly
converted from sRGB **#D2C8BC**. It is multiplied by the existing Wear attribute;
emission strength is **0**. Ochre remains **#D4861D** and gunmetal **#4C4C4B**.
No palette or material shader edits were needed.

**Generator shading issue:** the loaded armor uses smooth faces and baked custom
normals; `kit/core.py::finish` uses a 35° sharp-angle threshold. The renderer makes
mesh copies and disables smoothing only on painted armor polygons: **9,433 faces
across 22 objects**. Hardware and joint smoothing is preserved. Fix the authored
facet normals in the generators; this override exists only in memory.

Flat shading reveals strong diagonal facet bands and highlight changes around
some armor details. A separate read-only planarity check found **12 painted
nonplanar polygons in LG-420**, with maximum vertex deviation **55.7 mm** from
the polygon-normal plane. This needs a generator geometry/triangulation review;
lighting cannot establish correct manufactured facets. No armor source was
changed by this task. Geometry conformity and the concurrent fix agents' future
blend revisions are outside this render acceptance.

## Rounds and reproducibility

1. Standard, flat painted facets, key 3200 / fill 25% / rim 900, world 0.025,
   distance scale 1: thigh clipped to 255; calf 245/254. Printed probe table.
2. Fixed front/oblique lighting; distant softboxes (scale 3), key 2150 / fill 25%
   / rim 1200, world 0.04: thigh 230.5/232.7; calf 223.7/222.7. Inspection found
   the initial shaded sample crossed a seam. Reprojected LG-210 anchors onto the
   same existing renders and printed a corrected table; no extra rendering.
3. Distance scale 6, key 1970 / fill 30% / rim 800, world 0.055: lit thigh
   222.7/223.7, shaded facet 155.3/181.3, gunmetal 69.1/47.9. Printed table.
4. Key 1850 / fill 30%; rim lowered to 10° and 500. Final table above. All seven
   sheets rendered in this round. No fifth lighting round.

Local evidence is in `work/p6r2-round1` through `work/p6r2-round4`, with logs beside
those directories. Round 2's corrected coordinates are in
`p6r2-round2/reproject-evidence.json`. Final `compare-evidence.json` contains all
camera/light settings, projected bounds, material audit, source hash and timings;
`tone-probe.json`, `tone-probe.md` and the annotated `tone-patches-*.png` retain
measurement evidence. `work/tone_probe.py` uses system Python + Pillow.

```sh
/Applications/Blender.app/Contents/MacOS/Blender --background models/leg-lg01/output/leg-lg01.blend \
  --python-exit-code 1 --python models/leg-lg01/src/render_compare.py \
  -- --work models/leg-lg01/work/renders
```

The renderer now runs the probe after composition when `work/tone_probe.py` is
present and the assembled leg is requested. Standalone probe:

```sh
python3 models/leg-lg01/work/tone_probe.py \
  --evidence models/leg-lg01/work/p6r2-round4/compare-evidence.json
```

## Verification and scope

The final render command exited 0; 47.94 seconds before composition. All seven
7200 × 2400 comparison JPEGs and 14 individual views decode at their expected
sizes. Every sampled centre passes the visibility ray check; projected subject
bounds pass framing checks. Both render/composition scripts and the probe compile.
The assembled sheet was inspected at enlarged display size, and all seven sheets
were inspected as a contact sheet for presentation. These checks are not player
feedback, geometry approval or full-resolution inspection of every detail.

Loaded and final disk blend SHA-256:
`e2ae7efdb8fece7bfe5b24f04a52ab35dd8fff67ecc297d89a56b6d12b40f559`.
The source hash was unchanged at render start, render end and final verification.
Only renderer/compositor, the requested local probe/evidence, render JPEGs and
this note were changed by P6R2. No shared blend save, generator edits or commit.
