# P6R4 — rendering round 3, R10–R12

**Tone targets PASS.** This receipt is regenerated from the current render evidence, not copied from a previous scene.

Loaded scene SHA-256: `f45531bd2e6e738aa54363204ebca64c6f42c9b43b2a256ffc14a5dabb2b6fbc`.
Scene SHA-256 at render end: `f45531bd2e6e738aa54363204ebca64c6f42c9b43b2a256ffc14a5dabb2b6fbc`.
Disk source changed during rendering: **False**. The renderer does not save the blend or rebuild geometry.

## Measured tone

Median RGB / Rec.709-weighted sRGB code value Y′, measured from the delivered individual JPEGs. Lit thigh/calf: 215–228 and each channel ≤235; shade: 165–190; lit−shade ≥30. Ochre: (205,135,40) ±20/channel; knee: 55–100. Invalid geometry anchors have no measured tone and cannot pass separation.

| Region | Concept RGB / Y′ | Front RGB / Y′ | Three-quarter RGB / Y′ |
| --- | --- | --- | --- |
| lit_thigh | (224, 214, 204) / 215.4 | (230, 220, 208) / 221.3 **PASS** | (229, 219, 207) / 220.3 **PASS** |
| shaded_thigh | (191, 174, 160) / 176.6 | (188, 179, 168) / 180.1 **PASS** | (182, 173, 164) / 174.3 **PASS** |
| ochre_kneecap | (230, 148, 52) / 158.5 | (211, 135, 39) / 144.2 **PASS** | (210, 134, 36) / 143.1 **PASS** |
| dark_knee | (50, 50, 50) / 50.0 | (74, 73, 71) / 73.1 **PASS** | (67, 67, 65) / 66.9 **PASS** |
| calf_front | (222, 211, 201) / 212.6 | (226, 216, 204) / 217.3 **PASS** | (225, 215, 203) / 216.3 **PASS** |
| background | — | (255, 255, 255) / 255.0 **PASS** | (255, 255, 255) / 255.0 **PASS** |
| Lit − shaded Y′ | 38.8 | 41.2 PASS | 46.0 PASS |


Concept: `design/legs/images/lg01-assembled-v3.jpg`; fixed 9×9 px patches. The front shaded probe is the LG-200 outer fold; the oblique probe is the LG-210 outer skin. Anchors are ray-cast onto the loaded mesh; every pixel footprint plus a one-pixel border must hit the same part and palette material. No pixel-brightness search, image recoloring or local tone correction is used.

| View / region | Part | World point | Pixel / radius | Validated rays |
| --- | --- | --- | --- | --- |
| front / lit_thigh | LG-200 | 0.0000, 0.8487, 7.0000 | [410, 572] / 4 | 121/121 |
| front / shaded_thigh | LG-200 | -0.8200, 0.7701, 7.6000 | [560, 463] / 1 | 25/25 |
| front / ochre_kneecap | LG-300 | 0.0000, 0.8318, 5.1000 | [410, 920] / 4 | 121/121 |
| front / calf_front | LG-400 | 0.0000, 0.5447, 3.3000 | [410, 1249] / 4 | 121/121 |
| front / dark_knee | LG-110 | -0.4300, 0.3400, 5.1000 | [489, 920] / 4 | 121/121 |
| three-quarter / lit_thigh | LG-200 | 0.0000, 0.8487, 7.0000 | [371, 600] / 4 | 121/121 |
| three-quarter / shaded_thigh | LG-210 | -0.8367, -0.2500, 7.0000 | [601, 588] / 4 | 121/121 |
| three-quarter / ochre_kneecap | LG-300 | 0.0000, 0.8318, 5.1000 | [373, 920] / 4 | 121/121 |
| three-quarter / calf_front | LG-400 | 0.0000, 0.5447, 3.3000 | [403, 1216] / 4 | 121/121 |
| three-quarter / dark_knee | LG-330 | -0.5920, 0.0000, 5.1000 | [541, 910] / 4 | 121/121 |

## Rendering and finish

Blender 5.2.3 LTS; EEVEE; 32 samples; Standard transform, exposure 0, gamma 1. Lighting inputs: `{"fill_ratio": 0.72, "key_energy": 1170, "rim_energy": 350, "world_strength": 0.045}`. Key azimuth/elevation 45°/25°, opposing fill elevation 15°, rear rim elevation 10°. Distant softboxes use a 24× distance/size scale and 576× power. Front and oblique share world-space lighting; other views rotate the studio rig. Actual camera/light transforms are in the evidence JSON.

Assembled leg: orthographic three-quarter, 38° off front and 11° elevation. Assembled foot and exploded diagrams are also orthographic. Remaining structure presentation cameras use 120 mm. Contact shadows are retained under assembled three-quarter views. Side images are reflected for reference alignment and labeled.

Approved palette hex values and materials.py are unchanged. Source materials retain glTF Principled compatibility: armor roughness 0.49; bronze 0.43; recess metallic 0.03 / roughness 0.90. Viewer GLB is unchanged; the following finish is renderer-only.

**R10:** mouth positions/depths are measured from the loaded bronze meshes. A cubic aperture-visibility approximation (1 at the lip, 0.012 at/behind the throat), with local cavity AO on bronze (0.85 m, power 1.3), attenuates the entire BSDF, including metal reflections. The engine bore and rear-facing LG-100 receiving surfaces share the cavity shadow; the beam front and external barrel remain unaffected. Receiver attenuation is disabled when the engines are moved away in the exploded display. No disc, cap, geometry edit, palette replacement or image-space correction is used.

**R11:** spatial noise gates existing small edge lands and 0.055 m crevice AO. Maximum localized linear-value reduction is 32%, roughness increase 0.17; broad sloped fields are excluded from the source Wear heuristic. The mask is constant per face before shader noise, avoiding random vertex-gradient fans.

**R12:** structure views use a 1.25× key with a narrower softbox, 0.65× fill, 3.2× rear rim and a dedicated tall reflection strip. Assembled lighting stays unchanged. Painted faces use geometric split normals on mesh copies; mechanical smoothing is preserved. Both carriers are also shown from below, with the six pad undersides retained. Foot recesses still reuse Dark recess; no hardware added.

Source script SHA-256: `{"compose_compare.py": "ff2e12dce0602571ec147918358aece42c08b8c16eb80bfeb7a94956b30a03a6", "materials.py": "d23e8dd50997c3c948d1b9b80084012a6ff25d255acbc1a35b73231275aeb56c", "render_compare.py": "e19b68880ea19ad3ded119a31a1dabb6544208e6596b7bf6b62298a3caa01de9", "tone_probe.py": "fe60f69ca3353a7fae11cd07d4123620a7603c75d8d6e421cecdbed859070898"}`.

Dark foot-well faces: `{"FA-400.toe-cap.01": 936, "FA-401-L.upper-foot-plate.01": 940, "FA-402.heel-cover.01": 937, "FA-403-L.inner-ankle-guard.01": 1207, "FA-404-L.outer-ankle-guard.01": 1207}`.

## Exploded display and evidence

Leg plates and two engines occupy separated rows/columns around the frame; major pieces have part-number labels and short leaders. Foot shells and carriers are spread above/around the assembled frame, with all six pads separately shown from below at a common scale, with grazing illumination across the tread. Both carrier undersides have their own labelled inset. Captive hardware follows its owner. Rear skins and engines turn to show their exterior. These are display transforms only; they neither modify nor certify installation paths.

Evidence: `/Users/blakeyboy/gundam-leg-model/models/leg-lg01/work/renders/compare-evidence.json`; sibling `tone-probe.json`, `tone-probe.md` and `tone-patches-*.png` contain diagnostic results and overlays. A failed standalone probe exits 1 and prints TONE PROBE FAILURE, while render_compare.py still completes the sheets.

| Sheet | SHA-256 |
| --- | --- |
| cmp-lg01-assembled.jpg | `db88aa4bf23b948615934015c6f0a88630e4c01ba6ced7a8ba2bd18b92bab8dd` |
| cmp-lg01-armor.jpg | `111da0d8628ce6c864b29907ae47cd700240dab02d38e25054ba569ca9af51d5` |
| cmp-lg01-structure.jpg | `c36e9439a46f71a73cce76233f18db2dbfacdcfd79ee8cfc1ed8d8f4271e88aa` |
| cmp-fa02-assembled.jpg | `ec3f0594cd22283b39c2d6bab1a7b403f4865dff3b1f9c0d59addfdccd134c5f` |
| cmp-fa02-armor.jpg | `0a0a089501894916b30a9606dd4c3e59512c63a593d67a9e228253ff04a4c152` |
| cmp-fa02-structure.jpg | `da80f44f67b955baf68af1b2516111de48a0e8d3b3957b7f91352116ada8d031` |
| cmp-turnaround-leg.jpg | `23e5ad98b9a36b208b8301bedbd4728235e6f4c6cd51d286a7d5e998bdf83f81` |

## Rear-throat diagnostic

| Throat | Receiving part / world point | RGB / Y′ | Rays | Status |
| --- | --- | --- | --- | --- |
| upper | LG-100 / [0.0, -0.309999942779541, 3.950000047683716] | [2, 2, 2] / 2.0 | 9/9 | PASS |
| lower | LG-100 / [0.0, -0.309999942779541, 2.799999952316284] | [2, 2, 2] / 2.0 | 9/9 | PASS |

The fixed rear rays must hit LG-100 through both open engines. Target Y′ ≤35 is a rendering diagnostic, separate from the unchanged R5 tone targets.


Automated receipt: image generation and tone measurements only. Human inspection findings and material-board verification are recorded below after review; generation alone is not visual approval.
