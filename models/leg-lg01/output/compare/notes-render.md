# P6R3 — rendering round 2, R5–R9

**Tone targets PASS.** This receipt is regenerated from the current render evidence, not copied from a previous scene.

Loaded scene SHA-256: `f60bc18feb862a8ffba4185b7c7ad31ce3536679bae38429723f2ed20733d994`.
Scene SHA-256 at render end: `f60bc18feb862a8ffba4185b7c7ad31ce3536679bae38429723f2ed20733d994`.
Disk source changed during rendering: **False**. The renderer does not save the blend or rebuild geometry.

## Measured tone

Median RGB / Rec.709-weighted sRGB code value Y′, measured from the delivered individual JPEGs. Lit thigh/calf: 215–228 and each channel ≤235; shade: 165–190; lit−shade ≥30. Ochre: (205,135,40) ±20/channel; knee: 55–100. Invalid geometry anchors have no measured tone and cannot pass separation.

| Region | Concept RGB / Y′ | Front RGB / Y′ | Three-quarter RGB / Y′ |
| --- | --- | --- | --- |
| lit_thigh | (224, 214, 204) / 215.4 | (232, 222, 210) / 223.3 **PASS** | (232, 222, 210) / 223.3 **PASS** |
| shaded_thigh | (191, 174, 160) / 176.6 | (190, 181, 170) / 182.1 **PASS** | (183, 174, 165) / 175.3 **PASS** |
| ochre_kneecap | (230, 148, 52) / 158.5 | (211, 135, 39) / 144.2 **PASS** | (210, 134, 36) / 143.1 **PASS** |
| dark_knee | (50, 50, 50) / 50.0 | (74, 73, 71) / 73.1 **PASS** | (67, 67, 65) / 66.9 **PASS** |
| calf_front | (222, 211, 201) / 212.6 | (226, 216, 204) / 217.3 **PASS** | (225, 215, 203) / 216.3 **PASS** |
| background | — | (255, 255, 255) / 255.0 **PASS** | (255, 255, 255) / 255.0 **PASS** |
| Lit − shaded Y′ | 38.8 | 41.2 PASS | 48.0 PASS |


Concept: `design/legs/images/lg01-assembled-v3.jpg`; fixed 9×9 px patches. The front shaded probe is the LG-200 outer fold; the oblique probe is the LG-210 outer skin. Anchors are ray-cast onto the loaded mesh; every pixel footprint plus a one-pixel border must hit the same part and palette material. No pixel-brightness search, image recoloring or local tone correction is used.

| View / region | Part | World point | Pixel / radius | Validated rays |
| --- | --- | --- | --- | --- |
| front / lit_thigh | LG-200 | 0.0000, 0.8785, 7.0000 | [410, 572] / 4 | 121/121 |
| front / shaded_thigh | LG-200 | -0.8200, 0.7589, 7.0000 | [560, 572] / 1 | 25/25 |
| front / ochre_kneecap | LG-300 | 0.0000, 0.8318, 5.1000 | [410, 920] / 4 | 121/121 |
| front / calf_front | LG-400 | 0.0000, 0.5447, 3.3000 | [410, 1249] / 4 | 121/121 |
| front / dark_knee | LG-110 | -0.4300, 0.3400, 5.1000 | [489, 920] / 4 | 121/121 |
| three-quarter / lit_thigh | LG-200 | 0.0000, 0.8785, 7.0000 | [368, 601] / 4 | 121/121 |
| three-quarter / shaded_thigh | LG-210 | -0.8785, -0.2500, 7.0000 | [606, 589] / 4 | 121/121 |
| three-quarter / ochre_kneecap | LG-300 | 0.0000, 0.8318, 5.1000 | [373, 920] / 4 | 121/121 |
| three-quarter / calf_front | LG-400 | 0.0000, 0.5447, 3.3000 | [403, 1216] / 4 | 121/121 |
| three-quarter / dark_knee | LG-330 | -0.5920, 0.0000, 5.1000 | [541, 910] / 4 | 121/121 |

## Rendering and finish

Blender 5.2.3 LTS; EEVEE; 32 samples; Standard transform, exposure 0, gamma 1. Lighting inputs: `{"fill_ratio": 0.72, "key_energy": 1170, "rim_energy": 350, "world_strength": 0.045}`. Key azimuth/elevation 45°/25°, opposing fill elevation 15°, rear rim elevation 10°. Distant softboxes use a 24× distance/size scale and 576× power. Front and oblique share world-space lighting; other views rotate the studio rig. Actual camera/light transforms are in the evidence JSON.

Assembled leg: orthographic three-quarter, 38° off front and 11° elevation. Assembled foot and exploded diagrams are also orthographic. Remaining structure presentation cameras use 120 mm. Contact shadows are retained under assembled three-quarter views. Side images are reflected for reference alignment and labeled.

Approved palette hex values are unchanged. Source material factors retain glTF Principled compatibility: armor roughness 0.49; bronze 0.43; recess metallic 0.03 / roughness 0.90. The loaded scene receives the same factors in memory. Bronze receives local cavity AO (0.85 m, exponent 2.5) plus an axial cavity attenuation (0.025 at the throat, rising cubically to 1 at the rim) in the studio shader; the open throat and mouth geometry are untouched. Existing Wear attribute variation is amplified 1.65× (at most about 10% darkening on small lands/edges; broad sloped faces stay clean). Painted facets use geometric normals on mesh copies. Foot recessed faces reuse Dark recess; no added or resized fasteners. These appearance overrides are renderer-only except the source material factors.

Source script SHA-256: `{"compose_compare.py": "917bb8cb168249c9509c805419cacc5ad3e1cc5fa3fdacdfb089d0adeb96d7ad", "materials.py": "d23e8dd50997c3c948d1b9b80084012a6ff25d255acbc1a35b73231275aeb56c", "render_compare.py": "dd6215060bdc7622741a5465b099289dbf9fca93f8e014ca4d9e1ead87c41069", "tone_probe.py": "07ae777df9040c6ecf82780c952025e7d8845d431709a2dd3824db4bbb86a80d"}`.

Dark foot-well faces: `{"FA-400.toe-cap.01": 936, "FA-401-L.upper-foot-plate.01": 940, "FA-402.heel-cover.01": 937, "FA-403-L.inner-ankle-guard.01": 1206, "FA-404-L.outer-ankle-guard.01": 1206}`.

## Exploded display and evidence

Leg plates and two engines occupy separated rows/columns around the frame; major pieces have part-number labels and short leaders. Foot shells and carriers are spread above/around the assembled frame, with all six pads separately shown from below at a common scale, with grazing illumination across the tread. Captive hardware follows its owner. Rear skins and engines turn to show their exterior. These are display transforms only; they neither modify nor certify installation paths.

Evidence: `/Users/blakeyboy/gundam-leg-model/models/leg-lg01/work/renders/compare-evidence.json`; sibling `tone-probe.json`, `tone-probe.md` and `tone-patches-*.png` contain diagnostic results and overlays. A failed standalone probe exits 1 and prints TONE PROBE FAILURE, while render_compare.py still completes the sheets.

| Sheet | SHA-256 |
| --- | --- |
| cmp-lg01-assembled.jpg | `1f046dd3eb66c0063776729562f757f131d997e4d3ec8117e68672c3de577f43` |
| cmp-lg01-armor.jpg | `194f60ec45de40d89f90b8b6a67d2fa8c07b15005dee0869838f34202e231e2c` |
| cmp-lg01-structure.jpg | `76ec0b2e9087c7e5e5a7ee0dbdfb4fc1d312c5019c2cf2cb33f81ae82594ec13` |
| cmp-fa02-assembled.jpg | `e27092e1ac4112b43c68e0b4519d28a13ea5383cb9941bfaa572336bb0924cdc` |
| cmp-fa02-armor.jpg | `2e73be38a7e64f4b6d05a69d287d86ed45c896f79d4eec8707d1864604c86b2e` |
| cmp-fa02-structure.jpg | `92af4f75c3ae33ea661a96184ed9abef11b245cc1c33161e1ea955051560569b` |
| cmp-turnaround-leg.jpg | `73e18edfaf3e5695f02e9365c8fc0e7095cc3dd35959cfaebadd4f66e8351a49` |

Automated receipt: image generation and tone measurements only. Human inspection findings and material-board verification are recorded below after review; generation alone is not visual approval.
