# LG-01-3D-01 modelling notes

Decisions, dimensions resolved while modelling, and conflicts with the sources.

## Conflicts with sources

## Dimensions resolved while modelling

## Shape kit and materials

Phase 2, 2026-11-01. Source generators are in `src/kit/`; the scene/module API is
documented in `src/common.py`. No FA-01 or game files were changed. FA-01 supplied
the precedents for mesh emission, identity, profile sweeps and integral feature
shells; the new kit uses **metres throughout**, not FA-01's millimetres.

### Framework contract for later phases

- Author the **left** leg at the local ground origin: X robot-right (inner side),
  Y forward, Z up. Ankle, knee and hip centres are `(0,0,1.00)`, `(0,0,5.10)` and
  `(0,0,9.20)`. Whole-robot placement is the separate `(-1.10,0,0)` translation.
- Each part module exposes `build(ctx)`. `ctx.materials`, `ctx.parts`,
  `ctx.collections`, `ctx.joint_centres` and package paths are available.
  `ctx.register(...)` and `common.register(...)` have the same signature.
- Registration preserves the **exact CSV `name` text** in `part_name`, including
  rows sharing a part ID. Integer instance numbers are namespaced by that name;
  explicit suffixes such as `lug.03` are also supported. Duplicate instance IDs
  raise an error. Each inventory object owns an independent mesh datablock and
  moves into its subassembly collection. `step=-1` awaits phase 5.
- Plate and service constructors use local XY, back at Z=0 and front toward +Z.
  `kit.place(obj, origin, axis, roll)` aims a local feature; angles are radians.
  Turned primitives additionally accept `center` and `axis`. `combine()` bakes
  existing transforms into an integral mesh at the scene origin; place the
  resulting local component before registration. Helper docstrings specify the
  bearing planes, eye endpoints and inset coordinates.
- `build.py` imports available modules from the documented list, skips absent
  modules, and propagates errors from present modules. JSON/CSV manifests include
  identity, category, finish, location, world bounding boxes and triangle counts.
  `presentation` holds the studio camera/lights and is excluded from GLB exports,
  even if its objects are explicitly passed to `export_glb`.

### Geometry and finish choices

- Plates use explicit ring topology for broad, independent per-edge chamfers;
  width and depth can differ. Loft rings produce tapered outlines and multi-face
  noses. Convex, CCW outlines with noncollapsing offsets are the supported plate
  contract; split concave armor into appropriate panels before chamfering.
- Bent panel grooves use an applied exact-Boolean machining fallback because
  their paths can cross existing facets. The board uses real 25 mm wide, 15 mm
  deep blind grooves. Hatch frames, seams, tubes and nozzle walls use explicit
  profile/ring topology. Bolt wells are cut into the receiving plate; the hex
  heads sit below its outer face. The board's 75 mm bolts have 84 mm wells and
  heads recessed 25.5 mm. Fasteners use six-sided heads and 12-sided shafts and
  washers; threads are omitted from this visualization kit.
- Nozzles have an open throat, a closed wall section and a separate bronze lining
  material slot. Hydraulic cylinders use two eye centres and a retracted length,
  validate extension against their usable barrel stroke, and include a bored
  gland, polished rod and bored spherical eyes. Clevis ears have actual bores.
  Cable bundles use capped eight-sided sweeps with transported frames.
- Integral manufactured modules may contain intersecting **closed** shells,
  following the FA-01 visualization precedent. They are not fabrication solids.
  `bolt_group(..., separate=True)` returns individual fastener objects; the
  default combines a sample group. Where a CSV lists washers separately, use
  `ring()` and register those as independent physical instances.
- All bevels are applied geometry. Sharp-angle marking and baked weighted normals
  preserve hard edges. Paint wear is a per-corner `Wear` color multiplier, between
  0.94 and 1 on facets; broad faces remain unmarked. It exports as `COLOR_0`.
  Roughness stays a constant Principled PBR factor. No normal maps are used.
- The style-guide hex colors are converted from sRGB to linear shader values.
  Blender 5's exporter requires the current **Mix Color** multiply node to retain
  the constant paint factor; the legacy MixRGB version failed the first reload
  and was replaced. System Python/Pillow generates three small RGBA PNGs in
  `src/decals/`, linked directly into Principled base color and alpha.

### Verification and inspected evidence

Both requested commands exit 0 with Blender **5.2.3**, without manual setup:

```sh
blender --background --factory-startup --python-exit-code 1 --python models/leg-lg01/src/test_board.py
blender --background --factory-startup --python-exit-code 1 --python models/leg-lg01/src/build.py
```

The final test board contains **24 independent mesh objects / 14,160 triangles**.
The embedded geometry audit checks every disconnected shell for outward signed
volume, every edge for manifold closure, and verifies there are no unapplied
modifiers or shared mesh datablocks. A separate factory-startup Blender imports
the GLB from `work/`. [`output/kit/glb-reload.json`](output/kit/glb-reload.json)
reports **passed**: all **13 materials**, their numeric base colors, metallic and
roughness factors, all **three decal images and alpha links**, instance extras,
and **33 COLOR_0 primitives** survive. The supplied presentation objects are
excluded. The top-level build writes an empty manifest and a studio blend while
the eight part-module slots are absent, as intended for this phase.

Inspected [`test-board.jpg`](output/kit/test-board.jpg) and the final
[`comparison sheet`](output/kit/test-board-compare.jpg) after **three render
rounds**. Corrected initially washed-out lighting, a bolt-placement transform
error, the material export issue, grey camera background, and cable runs that
overlapped in projection. Final evidence shows broad plate chamfers, actual
octagonal wells around visible recessed heads, hatch shadow seams, raised rail
feet, vertical louvers, hollow bronze-lined bells and four distinct cables.
The final camera background is composited onto white while retaining the studio
world for reflections; the PNG intermediate and Blender scene remain in `work/`.
Deliverable renders are JPEG quality 90.

Final inspected comparison SHA-256:
`076a54d45f919540cd343e9ce9cb8a7fe4b396f27ff9b70b87834d9182cd2679`.
Matching reload-report SHA-256:
`43ccf17295675d7707029606b4f028da2b46d53bb7053cb503fbeb07a76c84e9`.

Remaining presentation limits: red stencils appear lighter under AgX studio
lighting than in the illustrated reference, despite verified exact texture RGB
and PBR factors. Wear is intentionally much lighter than the reference close-ups.
The generic exposed nozzle bell shows more bronze than the final recessed calf
installation will; phase 4's shroud will determine its visible balance. No further
render round was run after the three-round budget. Full-leg part counts,
interfaces, envelopes and assembly sequencing belong to later phases.

## Leg structure

P3A, 2026-11-01. `src/thigh.py`, `knee.py` and `shin_calf.py` implement
all 25 non-armor leg CSV rows as **49 independently registered inventory
objects**, including LG-310 (the shin-mounted kneecap bracket). Exact names,
subassembly, category and finish come from the CSV; repeated fastener IDs retain
separate names and instances. No kit, framework, game or FA-01 files were changed.
Armor, LG-460 and LG-470 remain Phase 4. Existing `build.py` already discovers
these modules and the parallel FA-02 module.

### Structural datums and fit

All values below are metres in the **left** leg frame (X inner/right, Y forward,
Z up). The integral LG-120 ball is R0.450 at `(0,0,9.20)`; neck R0.150 occupies
Z8.335–8.785, with a shallow collar key flat near Z8.46. The central spar is
0.300×0.200; separate-looking ribs, backing rails and machined reinforcement
segments are integral features of that same registered manufactured part.

- Spar flange: 0.680×0.600×0.040 at Z5.920–5.960. Fork flange: the same plan
  at Z5.880–5.920. Ø26 clearance / Ø21 tap-drill holes at X±0.250, Y±0.200.
  Four M24×100 bolts have head-bearing Z5.964 above separate 4 mm washers;
  their tips reach Z5.864. No threads are modelled.
- Fork cheeks: X−0.500…−0.360 and +0.360…+0.500, OD0.680 / bore0.210 at
  `(Y,Z)=(0,5.10)`. The upper webs step 10 mm inward from each cheek face to
  avoid coplanar overlapping-shell shading. Axle journal Ø0.200 spans X±0.500;
  its Ø0.300 shoulder occupies X−0.540…−0.500. Positive-X end pad ends at
  X0.535; cap occupies X0.535–0.559. The M12 cap screws point toward −X,
  with head-bearing X0.561, axes `(Y,Z)=(0,5.015)` and `(0,5.185)`.
- Bearings OD0.298/ID0.204×0.120 at X±0.210. Thrust spacers
  OD0.360/ID0.204×0.075 at X±0.3175 occupy ±0.280…±0.355, leaving 5 mm
  to each fork cheek. Shin boss OD0.560/bore0.300 spans X±0.280.
- Shin flange: 0.540×0.440×0.030, Z1.380–1.410; four Ø38 holes at
  X±0.200/Y±0.150. Its 0.182×0.102 female key recess ends at Z1.407,
  leaving a 3 mm roof and 7 mm above the foot key's Z1.400 top. The beam
  remains 0.300×0.200 through Z2.100, widens to 0.560×0.360 by Z2.420,
  and has integral side webs/lands to X±0.370. Foot-owned flange hardware
  is not duplicated in LG-100.
- Electrical sleeve: original Godot plug `(0.250,1.400,−0.100)` becomes
  `(0.250,+0.100,1.400)` here. Sleeve centre is 0.034 farther along normalized
  `(0.080,0.050,0.160)`; OD0.048/ID0.034×0.032. The small stay and the
  baseplate corner are actually relieved along that approach, not merely
  overlapped by a decorative ring.

### Exposed workshop support contacts

Fork pad bearing faces are **X±0.800**, Y−0.110…+0.170,
Z5.980–6.220, with 10 mm machined steel face shells on gunmetal backing
blocks. Backing blocks span Z5.950–6.250; diagonal load webs tie into the
cheeks/crossbar. The entire support stays below Z6.300. Phase 4 must leave a
visible gap between the lower thigh panels and knee guards around those faces.

Shin pad bearing faces are also **X±0.800**, Y±0.140,
Z2.690–2.910; backing blocks span Z2.660–2.940, with diagonal struts into the
main shin. Preserve access through the calf-shell sides. The 1.65 m calf armor
is wider than these faces, so a real cutout/recess is required. The old workshop
rear spine at Y−1.45 conflicts with the revised calf/thruster envelope: the model
uses the approved proportions; no workshop clearance approval is claimed.

### Hip lugs and services

The three actual pin axes run along Y, at:

| CSV part | Left-leg eye centre | Clevis geometry |
| --- | --- | --- |
| LG-240 outer front | `(−0.339,+0.339,7.400)` | 0.094 gap, 0.050 ears, Ø0.062 bore |
| LG-242 inner front | `(+0.464,+0.124,7.400)` | Same |
| LG-244 inner rear | `(−0.124,−0.464,7.400)` | Same |

Carrier roots occupy Z7.250–7.600. Each has a prepared saddle/keyway and two
M24×100 bolts with separate W-24 washers at Z7.310/7.540. Front carriers fasten
along X; the rear carrier fastens along Y. The rail tap-drill seats and carrier
clearance holes are real. Projecting arms remain compact and leave open channels;
no disk connects the eyes. Hip cylinders and their pins remain parent-assembly
inventory. The neck collar/stop tongues have no CSV row: only their receiving
key flat is prepared, as requested, rather than inventing new inventory.

LG-250's primary block is centred `(0.320,0.600,8.350)`, faces +Y, and measures
0.300×0.180×0.340 excluding its integral dry-break fittings. LG-255 has two
0.28650 straight legs and an R0.120 semicircle: nominal free centreline length
0.950 (sampled polygonal curve 0.94985); hose radius0.025. It stays in the
front-inner channel and is clipped back to the spar. LG-230 includes the rear
machined guard, captive cable clips and six protected rubber cable runs.

### Knee drive and thrusters

Both LG-340 cylinders connect **thigh spar to shin**, correcting the concept
sheet's thigh-to-fork drawing. Chosen neutral eyes:

| Side | Upper LG-345 / cylinder eye | Lower LG-346 / cylinder eye |
| --- | --- | --- |
| Outboard | `(−0.460,−0.460,6.400)` | `(−0.440,−0.500,4.300)` |
| Inner | `(+0.460,−0.460,6.400)` | `(+0.440,−0.500,4.300)` |

Eye span is **2.100476**. Selected retracted length1.650, neutral extension
**0.450476**, usable kit stroke **1.208**, maximum eye span2.858. BarrelØ0.260,
rodØ0.110, eyeØ0.221 and pin boreØ0.09503; bracket gap0.226, ears0.055.
Both shafts pass behind the axle, leaving the middle of the rear knee open.
The upper brackets attach at Z6.45 to the spar; lower brackets attach at Z4.24
to the shin. This is a neutral-pose fit, **not** a verified knee travel or
hydraulic force/stroke design. Knee eye pins/keepers have no CSV allocation;
the bored eyes and brackets are shown without inventing loose hardware.

LG-440 is an open two-ring cradle tied into the widened shin. Seat centres are
`(0,−0.720,3.980)` and `(0,−0.720,2.930)`; mount rings OD0.740/ID0.640×0.100
receive engine OD0.636, with 2 mm radial allowance and an axial flange.
Both exhaust axes are `(0,−0.978148,−0.207912)` (**12° down from rearward**).
Bell mouths are Ø0.790, with 24 mm solid walls and bronze lining. Mouth centres
are `(0,−1.404703,3.834462)` and `(0,−1.404703,2.784462)`. Rear-most lip is
Y−1.48683, leaving about113 mm to a Y−1.600 shroud limit. The lowest lip is
Z2.39809; openings have an approximately277 mm vertical gap around Z3.3–3.4
for the future bridge panel. Engine/thruster shells stay well above the ankle;
complete articulated knee/armor/heel sweeps remain future work.

### Local kit adaptations and audit contract

- `thigh.py` supplies a small standalone-bolt helper because `kit.bolt_washer`
  combines two objects that the CSV inventories separately. All hardware uses
  six-sided heads and 12-sided shanks/washers. Small integral service plugs and
  cartridge fittings are preassembled/captive features, not invented stock rows.
- The kit cylinder's eye-neck shells obstruct its pin tunnel. `knee.py` separates
  the returned cartridge's closed shells locally, drills obstructing necks and
  rejoins them; Boolean-cutting the complete overlapping-shell mesh was found
  to delete some eye geometry. The kit itself is unchanged. Cylinder hard lines
  and clamp bands are integral cartridge detail.
- Named `interface.*` vertex groups mark real manufactured surfaces. The audit
  measures those vertices, fits actual bore rims and ray-tests complete receiving
  solids. It does not accept stored endpoint/dimension properties as evidence.
- `verify_scene.py` reads **both CSVs**, including duplicate IDs by exact name;
  checks counts/unique instances, exact metadata, independent meshes, materials,
  finite vertices, closed manifold shells, outward normals and positive volume
  per connected shell. `--expect structure` uses `checks_foot.DEFERRED_ROWS` for
  foot deferrals; `--expect full` requires every row. `--only-leg` is an explicit
  isolated diagnosis and is labelled as such, never the default acceptance.
- `verify_interfaces.py` imports and runs `checks_foot.checks()` when available.
  Missing optional foot checks are stated explicitly. The default scene audit
  still fails if required foot inventory is missing.
- `render_quick.py` renders EEVEE three-quarter rear/outboard, side, back and
  knee views; `--armor hidden|shown`, optional `--views ...`. JPEGs use quality90
  and white compositing. Cameras/lights are changed only in the render process,
  not saved over the manufacturing scene. Local hashes are in
  `work/skeleton-render-evidence.json`; audits include the saved blend hash.

### P3A inspection evidence

Three render rounds were completed and inspected, including the comparison
sheet, side, back and knee close-up. Round1 found washed-out gunmetal, sparse
exposed rails, and incorrectly clocked thruster collar details. Round2 corrected
lighting, rail/cylinder detail and the collar plane. Round3 removed the fork's
coplanar web/cheek seam and included the parallel FA-02 internals for context.
The inspected structure shows distinct machined support pads, open rear knee,
continuous thigh-to-shin cylinders, three bored hip carriers and separate twin
engine mouths. No additional render-fix rounds were run.

The frame is cleaner and slimmer than the painted reference, particularly the
upper spar. The exact 300×200 spar, explicit lug channels, measured knee stack
and absent armor take precedence over the drawing's heavier overlapping forms.
No scratch textures or invented large fastener inventory were added. The model's
longer knee rams are a consequence of the corrected thigh-to-shin attachment;
the concept's short thigh-to-fork arrangement is intentionally not reproduced.
These are inspected presentation findings, not gameplay or user approval.

All **305 leg interface checks** pass, and all **49 leg inventory meshes** pass
individual geometry/metadata checks. Temporary in-memory negative probes also
confirmed rejection of a 25 mm displaced spar, one flipped cap face and a
duplicate bearing instance ID; no mutated scene was saved. The final combined
CSV/interface acceptance status is recorded in `output/audits/scene-structure.json`
and `interfaces-structure.json`. Their foot results may change as the separately
owned FA-02 module is repaired; its source files were not edited by P3A.
The round3 render hash is preserved in `work/skeleton-render-evidence.json`;
subsequent foot-only rebuilds do not imply a fresh render inspection.


## P3A2 leg structure revision — 2026-11-01

This supersedes P3A's justification for keeping the whole upper frame thin and
its Ø790 nozzle-mouth choice. The 300×200 sections are **local interfaces**;
the surrounding structure is now a substantial plated load frame. No inventory
rows were added: the leg remains **49 objects / 25 non-armor CSV rows**. Added
webs, doublers, captive plugs, cable trays and mounting lands belong to their
existing manufactured modules. Foot generators, shared kit, materials, game,
approved concept images and component specifications were not edited.

### Chosen structure and packaging dimensions

All dimensions are metres in the existing left-leg coordinate frame.

| Feature | P3A2 selection |
| --- | --- |
| Thigh load boxes | 0.660 wide × 0.540 deep at Z6.020–7.200 and Z7.660–8.240; chamfered side webs, edge flanges and doublers increase the main frame to about 0.90 wide. The rear guard reaches Y−0.550, giving about 0.85 depth to the front flanges. Captive heads project slightly beyond these structural faces. |
| Upper transition | Shoulder tapers from 0.660×0.540 at Z8.160 to 0.300×0.200 at Z8.300. Original neck, ball, carrier roots and eye centres retained. |
| Lug band | Rear corner rails 0.120×0.340 span Z7.140–7.720 at X±0.370/Y−0.190. The rear guard has a real opening for LG-244; cross ties avoid that pin route. |
| Thigh armor lands | Side land faces X±0.740 in the upper thigh and X±0.500 near the knee; front lands Y+0.740 / +0.460. With 60 mm armor, the upper lands reserve about 0.10 m to inner faces; captive heads reduce it to about 0.08 m. These are packaging selections, not final armor-solid verification. |
| Cable guard | Panel 0.280×0.100×1.940 at Y−0.500; six Ø0.052 protected runs in two bundles, with 0.760-wide ties. |
| Knee fork | Original axle, cheeks, flange, bearings and washers unchanged. Octagonal OD0.780/ID0.490 × 0.075 cheek doublers and 0.560-deep upper webs add load-bearing mass outside the journal. Cylinder mounts now bed against the deeper frame at Y−0.290. Eye centres and cylinder dimensions remain unchanged. |
| Shin | Exact 0.300×0.200 from Z1.410 through Z2.100; expands to 0.640×0.620 by Z2.420, maintained through Z4.680. Edge rails and pocketed side doublers reach about 0.900 overall width. Upper taper joins the original knee boss. |
| Shin lands | Side land faces X±0.665; front faces Y+0.440. These leave 0.100 m to 60 mm armor inside the 1.650-wide calf and front plate at Y+0.600. Existing exposed handling pads stay at X±0.800 and still require armor cutouts. |
| Cradle LG-440 | Two heavy hexagonal rings, outer/inner circumradii 0.600/0.400, axial depth 0.180, around the unchanged OD0.740/ID0.640 machined engine seats. Ring across-flats width is about 1.039; reinforced ties connect to the shin. A second 40 mm face ring and 140×200 mm longitudinal rails provide stepped edges. |
| Engines LG-450 | Mouth Ø0.640, 0.600 axial bell length, 24 mm walls; unchanged seat centres, engine Ø0.636 and 12° downward/rearward axes. Both mouths remain at Y−1.404703, with rear-most vertices **Y−1.471235**. |
| Rear allowance | Front armor Y+0.600 minus calf depth 2.240 gives rear outer Y−1.640. Assuming 60 mm shroud thickness gives inner Y−1.580: **108.8 mm** remains behind the actual engine lip. Bodies and bells fit inside this future shroud; recessed openings are Phase 4. |

The narrow lower shin and its 540×440 mm ankle flange remain intact, preserving
foot access. They are not expanded merely to imitate the illustration's wider
foot-end. The modeled FA-02 foot is shown as context in the complete-leg views.

### Rendering and inspected evidence

Completed **three render/inspect rounds** for P3A2. Round 1 confirmed the new
mass but over-lit it to pale silver. Round 2 restored gunmetal and tightened the
knee view. Round 3 bridges the lug band, adds front shin armor lands, and adds a
labeled engines-removed frame view so both open hexagonal rings can be compared
with the concept. The complete three-quarter, side and rear views retain both
engines. Inspected all final views, the knee inset and the comparison sheet.

`render_quick.py` retains the exact #4C4C4B material, uses AgX Medium High
Contrast, exposure −0.25, white world strength 0.35, key/fill/edge powers
2800/1100/2000 W and a 700 W full-height soft fill. The transparent studio render
is composited onto white. Full-leg alpha bounds occupy **85.2–86.7%** of image
height. The comparison includes an outlined knee inset and crop connectors.
Final gunmetal faces and pocket shadows remain distinct, with readable machined
edges and rods; painted-reference wear and irregular surface detail are still
more complex. This is inspected presentation, not coordinator/player approval.

Final comparison: [skeleton-vs-lg01-structure.jpg](output/compare/skeleton-vs-lg01-structure.jpg).
[structure-review.json](output/audits/structure-review.json) retains scene/source/
image hashes, measured framing, the three round findings and limitations.
Rounds 1–2 are preserved locally under `work/p3a2/round1` and `round2`.

### Verification and concurrent-foot boundary

- **319/319 leg interface checks pass**, including the existing datums, bores,
  hardware and cylinder eyes, the broader box sections, Ø640 mouths, rear
  allowance and 17-ray samples along each 340 mm / R80 lug pin-tool corridor.
  See [interfaces-structure-leg.json](output/audits/interfaces-structure-leg.json).
  The new `--only-leg` option states its scope explicitly; default verification
  still checks the foot and fails when its checks fail.
- **651/651 scene meshes pass** the full `verify_scene.py --expect structure`
  CSV/identity/material/manifold/orientation/volume audit. Leg structure:
  **102,686 triangles**, 17.1% of its 600,000 budget. The captured leg-plus-foot
  scene totals **421,086 triangles**, leaving about 2.079 M of the complete
  2.5 M budget for remaining geometry.
- The combined interface report retains **two FA-106 clear-bore failures** in
  this concurrent foot snapshot. All leg checks pass. A read-only check of the
  other agent's then-current main scene also found two FA-106 seat-plane
  failures; its work was still changing. Those are not waived or repaired here.
- Scene/manifests were built to **`work/p3a2/structure.blend`** and its sibling
  manifests to avoid overwriting the parallel agent's shared outputs. The final
  audits and renders refer to that exact scratch blend. A later shared rebuild
  consumes the revised leg generators but does not refresh these captured images.
  No commit was made.

Reproduce the owned-leg audit and presentation from the captured scene:

```sh
blender --background models/leg-lg01/work/p3a2/structure.blend --python-exit-code 1 --python models/leg-lg01/src/verify_interfaces.py -- --only-leg
blender --background models/leg-lg01/work/p3a2/structure.blend --python-exit-code 1 --python models/leg-lg01/src/verify_scene.py -- --expect structure
blender --background models/leg-lg01/work/p3a2/structure.blend --python-exit-code 1 --python models/leg-lg01/src/render_quick.py -- --armor hidden
```

Remaining design limits: full knee/hip/ankle articulation and the actual armor
inner surfaces/openings are not verified by neutral-frame geometry. The longer
thigh-to-shin knee cylinders deliberately differ from the erroneous concept
attachment. No game regressions, gameplay changes or fabrication-solid claims
are part of this model-only revision.

P3A2's complete captured-scene reports are preserved separately as
[scene-structure-p3a2.json](output/audits/scene-structure-p3a2.json) and
[interfaces-structure-p3a2.json](output/audits/interfaces-structure-p3a2.json),
using the audit scripts' new optional `--report PATH`. This avoids the concurrent
foot build replacing this evidence in the default report files. Their exact hashes
are linked from `structure-review.json`; the foot failures remain visible.

## FA-02 foot internals

P3B, 2026-11-01. `src/foot_fa02.py` adapts the FA-01 generators through
`foot_geometry.py`, `foot_frame.py`, `foot_actuators.py`,
`foot_pitch_interfaces.py` and `foot_services.py`. Helpers retain millimetre
construction coordinates and emit metres into the unchanged left-leg frame.
FA-01 is read-only, including its source-identity registry. No game files changed.

The generated inventory has **602 independent physical meshes across 168 complete
CSV rows**: 174 components, 214 fasteners and 214 separate washers. Every object
has the exact FA-02 CSV ID, name, subassembly, category and finish. Instance IDs
are unique; legacy source IDs remain provenance only. Pitch collar registration
follows the repaired geometry: the positive-Y clearance half is FA-524-A and
the negative-Y threaded half is FA-524-B. Front/rear gasket numbering also follows
the CSV's functional order instead of the source emission order.

`checks_foot.DEFERRED_ROWS` reserves **14 whole rows / 143 objects** for Phase 4:
FA-302/303/304 pads, FA-305 sleeves, FA-400/401-L/402/403-L/404-L shells, FA-405
collars, and both the bolt and washer rows for Sole pad mounts and Armor captive
bolts. No partial hardware-use row is emitted. Integral armor receiver/tab fitting
belongs with Phase 4's final shell geometry; the carrier pad-hole patterns are
already present.

### Geometry decisions

- Rear/forefoot rail centres are X±560 mm, with explicit 20 mm exterior chamfers
  and hollow 180×240 mm sections. Crossmember half-lap ends retain X±650 while
  the lower rail walls remain continuous. Inward ledges, keeper-ear pockets and
  separated reinforcing webs retain the specified nut-plate and bolt positions.
- The cradle stays open. Its braces avoid the M36 heads; frame washer seats are
  Z430, with bolt bearing planes Z436. The taller hinge beam has real octagonal
  wells. Its front face has a 0.5 mm relief (Y1544.5, rear Y1425) to avoid an exactly
  tangent Boolean at the Y1545 bolt row; this is within the 10 mm model tolerance.
- H is (0,1340,350); the axle journal/bushing stack is unscaled. Both forefoot
  actuator eyes move +140Y. Pitch and roll eyes, the ankle core and its short
  opposed pins retain their original positions. Pitch uses the repaired FA-01
  internal/clevis interfaces; roll and forefoot retain their reference packaging.
- The adapter flange ends at Z1380, its 180×100×20 key at Z1400, and the four
  shin-interface bolts use the **leg** stack: washers Z1410…1416, heads bearing
  at Z1416, axes X±200/Y±150. The main harness's existing upper plug collar and
  oblique axis match the shin receiving-sleeve datum.
- Both carriers include all future pad holes and distinct 6/4 mounting bores.
  Carrier counterbores reach Z172 for the washers at Z168…172. The junction box
  has integral receiving ears on the front frame, placed clear of its M36 bores,
  plus actual board/lid receiving bosses and mounting holes.
- Frame finishes use the shared gunmetal palette; exposed rods/pins use polished
  steel. Hidden fastener helices are omitted, with 12-sided plain shanks and
  recessed hex sockets. All three lead screws retain geometric helices. Every
  bevel is applied. No cosmetic fasteners or extra inventory objects were added.
- Exact Boolean cuts are performed on individual closed integral shells where
  necessary, then retained in one component mesh. Remote no-op cuts are skipped;
  bores have a 0.05 mm numerical clearance to avoid coincident surfaces. The
  generator repairs outward normals before registration. This preserves the
  existing visualization-solid convention, rather than implying fabrication unions.

### Verification and inspected evidence

The final foot has **317,888 triangles**, leaving 482,112 of the 800,000 target
for the Phase 4 rows. All three requested Blender commands completed with exit 0
on Blender **5.2.3 LTS**:

```sh
blender --background --factory-startup --python-exit-code 1 --python models/leg-lg01/src/build.py
blender --background models/leg-lg01/output/leg-lg01.blend --python-exit-code 1 --python models/leg-lg01/src/verify_scene.py -- --expect structure
blender --background models/leg-lg01/output/leg-lg01.blend --python-exit-code 1 --python models/leg-lg01/src/verify_interfaces.py
```

The combined scene audit passes **651 objects** (602 foot + 49 leg), including
unique meshes, exact row counts/metadata, closed edges, positive-volume shells,
outward normals and applied modifiers. `checks_foot.checks()` passes **478
checks** measured from actual world-space geometry. Its `(name, ok, detail)`
records cover ankle journals, shin flange/key/bolt stacks, the hinge and all six
actuator eye/pin/clevis connections, frame lands/ledges and unobstructed bores,
M36 washer-seat planes, carrier bores, crossmember spans, the shin plug collar,
ground/envelope bounds and the triangle budget. The whole-leg interface runner
passes its 320 top-level checks, including the foot aggregate. Evidence is in
[scene-structure.json](output/audits/scene-structure.json) and
[interfaces-structure.json](output/audits/interfaces-structure.json).

Completed **two render/inspection rounds**. The first exposed overly square
rails and a cropped top view. The second was inspected in the
[comparison](output/compare/foot-skeleton-vs-fa02-structure.jpg),
[three-quarter](output/renders/foot-skeleton-three-quarter.jpg),
[rear](output/renders/foot-skeleton-rear.jpg) and
[top](output/renders/foot-skeleton-top.jpg) views. It shows real rail chamfers,
separate forefoot and rear frames, an open cradle/ring, keyed adapter, side pitch
drive, rear roll drive and central forefoot drive. The axle crosses the interleaved
hinge lugs rather than the toe crossmember; the reference's extra long rail is
not reproduced. The top view now contains the complete foot. The inspected
surface finish is deliberately cleaner and less weathered than the illustration;
small shading seams at integral-shell intersections remain. No extra cosmetic
fasteners were added to imitate erroneous drawing counts.

Comparison SHA-256: `944721f45cc980ebdfde10945a75b520060911b638e7b35da27aeb1fc4e1f7e8`. The matching blend, render and source hashes are
recorded in `work/foot-render-evidence.json`; the local capture script is
`work/render_foot.py`. The foot-only views hide the shin baseplate, so the four
flange bolts retain the correct leg-installed height above the exposed adapter.

These are static source-model and inspected presentation results. Full angular
stop/contact sweeps, flexible cable slack/bend/contact checks, full insertion/tool
paths and roll/forefoot internal interface refinement remain unverified. The
legacy harness route/clip arrangement is retained apart from connection to the
translated forefoot socket; nominal cable lengths remain trim-to-fit allowances.
No game behavior, gameplay or user approval is implied. Armor/pads and final
shell receivers remain Phase 4 work. No game regressions or diagnostics were run,
and no commit was made by P3B.


## Viewer — P7A (2026-11-01)

Implemented against the saved **651-part structural scene**, with a **40-step
development placeholder**. No model generator, source blend, game file or FA-01
asset was changed by this task; no commit was made. Phase 4 armor and Phase 5's
real sequence can replace the inputs without changing the viewer code.

### Export and identity contract

`src/export_viewer.py` opens `output/leg-lg01.blend`, freezes evaluated meshes and
world matrices into temporary unparented objects, and uses `common.export_glb`
to export `viewer/leg-lg01.glb`. It never saves over the blend. Presentation
objects are excluded. Every node name is exactly its `instance_id`; extras retain
`part_id`, `part_name`, `instance_id`, `subassembly`, `category`, `finish` and `step`
when present. Materials, vertex colors and assembled transforms are preserved;
Draco is off. A source receipt inside the GLB records the source blend SHA-256,
scene part count, evaluated triangle count and used materials.

The audited snapshot is **13.804 MB, 420,574 triangles, 7 materials, 651 nodes**.
`src/verify_export.py` reads the binary glTF JSON directly with standard Python;
checks node roots, exact identity/extras, material references/count, triangle
count and budgets; compares the manifest; and validates the shared step schema,
unit approach vectors and one-to-one installs/metadata/node coverage. Missing,
extra and duplicate IDs are explicit in `output/audits/export.json`. A changed
manifest requires a fresh export and matching sequence.

### Viewer behavior

The local page uses the pinned three.js **0.170.0** import map, GLTFLoader,
OrbitControls and RoomEnvironment PMREM. Neutral lighting, ACES tone mapping and
sRGB output sit on `#f3f2ef`. The bottom timeline supports fractional scrubbing
with easeInOutCubic, per-step ticks, previous/next, playback at 0.5/1/2/4×, arrow
keys and Space. Base speed is 1.4 seconds per step. The panel groups identical
part-number/name pairs with quantities; active parts pulse on per-instance
cloned materials. A hover tooltip names the part.

Positions and bounds are cached at load; scrubbing updates only affected step
ranges. Blender `(x,y,z)` approach vectors become glTF `(x,z,-y)`. Front faces
Blender +Y / glTF −Z, back +Z, and the outer side of the left leg is −X. The
loader recovers dotted instance IDs from GLB node associations/extras rather
than trusting three.js's sanitized Object3D names. Parent inverse conversion is
also supported, although this exporter flattens parents. Unknown installs are
warned/skipped; unassigned GLB parts stay assembled.

Follow step smoothly fits active-part bounds. Armor is shown, ghosted at **15%**,
or hidden, driven only by the schema's `parts[id].armor`. Show all exploded keeps
the slider's saved position and restores it when toggled off. Hashes `#t=0`,
`#t=mid`, `#t=end`, and `#armor=ghost` support deterministic captures (ghost alone
uses the assembled pose). `window.__viewerState` exposes readiness, load timing,
mismatches, `snapshot()`, `setTime()`, `setArmor()`, `setExploded()` and `fit()` for
browser checks. Snapshots include all part positions and interpolation endpoints.

### Verification and inspected presentation

- Export and schema audits pass: all **651 instances appear exactly once** in
  both the GLB and placeholder installs, with no missing or extra IDs.
- `src/check_viewer.py --browser` passed **321 slider samples** in eighth-step
  increments, all **41 step/text states**, and motion of **all 651 parts**. The
  maximum interpolation error was zero in this snapshot. It also checked reverse
  scrubbing, exploded-preview restoration, coordinate conversion, every speed,
  keyboard/button controls, camera directions, follow and armor states.
- An intercepted mismatched sequence tested unknown-ID skipping and assembled
  retention without modifying files. Only the two expected mismatch warnings
  appeared; baseline and mismatch runs had **zero console/page errors**.
- Page load after server readiness measured **2.41 s on the first run**, and
  **0.252 s on the final warm run**. The machine's Python HTTPServer startup can
  separately wait on macOS reverse DNS; the launcher prints startup status and
  allows 90 seconds for actual HTTP readiness before opening the browser.
- The executable `open-viewer.command` was launched from `/tmp`, served the page
  and all assets, opened the default browser, exited 0 on Ctrl-C, and released
  its port. See `output/audits/viewer-launcher.json`.
- Inspected the final **1280×800** JPEGs: [start](output/viewer-shots/viewer-start.jpg),
  [middle](output/viewer-shots/viewer-mid.jpg), [assembled](output/viewer-shots/viewer-end.jpg),
  and [ghosted](output/viewer-shots/viewer-ghost.jpg). The model is unclipped,
  controls and step labels fit, and the parts list scrolls. Tightened framing
  after inspection. Corrected the capture harness to reapply an unchanged hash
  and assert each capture's exact timeline/armor state.

This is viewer behavior and inspected presentation evidence, **not approval of
an engineering assembly sequence**. The placeholder groups subassembly/category
batches for development; it does not establish mount dependencies, retained
fastener grouping or collision-free approaches. The present model has only one
armor-classified service guard, so the ghost image differs subtly from assembled;
full armor presentation still needs fresh captures after Phase 4/5 inputs arrive.

### Run and regenerate

From the repository root (the launcher also works when double-clicked in Finder):

```sh
blender --background --factory-startup --python-exit-code 1 --python models/leg-lg01/src/export_viewer.py
python3 models/leg-lg01/work/placeholder_steps.py
python3 models/leg-lg01/src/verify_export.py
python3 models/leg-lg01/src/check_viewer.py
models/leg-lg01/work/viewer-venv/bin/python models/leg-lg01/src/check_viewer.py --browser
models/leg-lg01/open-viewer.command
```

The browser check uses Playwright and installed Google Chrome, serves its own
free localhost port, writes `output/audits/viewer.json`, saves the four JPEGs,
and shuts down its browser/server. Recreate its local environment if needed:

```sh
python3 -m venv models/leg-lg01/work/viewer-venv
models/leg-lg01/work/viewer-venv/bin/pip install playwright
```

Standard-library static checks need no dependencies. The browser loads the
pinned modules from jsDelivr, so first use requires internet access. The
placeholder generator **refuses to overwrite a non-placeholder sequence**; stop
using it when Phase 5 supplies `viewer/build-steps.json`. Regenerate the GLB and
rerun the checks/captures after updating the saved model and real sequence.

## Leg armor

P4A, 2026-11-01. `thigh_armor.py`, `knee_armor.py` and
`shin_calf_armor.py` add **19 objects / 16 CSV rows**. Together with P3 there
are **68 leg objects / all 41 leg CSV rows**, with exact CSV identity and
handedness. The module names were already present in `build.py`; its module
list needed no edit. No leg structure, foot source, shared kit, materials,
game, FA-01 or approved image files were changed by P4A. No commit was made.

### Geometry and selected dimensions

- Main skins have **60 mm extrusion thickness**, broad **75 mm edge facets**,
  25×15 mm blind panel grooves, and grouped 25 mm captive hex bolts seated
  in 42 mm radius / 32 mm deep octagonal wells. The small bridge uses smaller
  edge facets to fit its 155 mm height. Surface-normal thickness decreases
  on the steepest folded rear slopes; these remain visualization shells.
- Thigh front starts at Z5.750 and tops out at Z8.230; side plates start
  Z5.770 and rear covers Z5.890. The lower sides have real openings around
  the fork pads at Z6.100. Upper front/side channels extend down to Z7.250,
  exposing the lug band. The central rear channel remains open around LG-230.
  Neutral R80 cartridge corridors to the three mirrored upper eyes pass.
  The hip ball/neck gap follows the requested Z8.0–8.3 armor-top default;
  no torso-owned guards were added. Full articulated hip solid clearance is
  still open; the sampled endpoint box is not treated as an exact swept solid.
- LG-310 was already present on the upper shin and was reused. LG-300 is a
  thin folded ochre shield, with a chisel ridge at Z5.170. LG-320/325 have
  real circular openings; LG-330 covers have integral rear tabs reaching
  the guards. The rear knee centre remains open and the correct long
  thigh-to-shin cylinders remain visible.
- Calf skins start at Z1.650. Side shells have separate through-openings
  for the two LG-460 hatches and exposed Z2.800 handling pads. Hatches have
  integral tabs bridging their seams. Ochre LG-470 rails sit over real
  recesses with mounting feet reaching the shell. LG-420 includes folded
  60 mm side returns and separate octagonal exhaust apertures; LG-430 is
  the removable bridge between them. The P3 Ø640 nozzles remain unchanged,
  recessed behind the Y−1.640 outer rear shroud.
- All plate standoffs are integral to the owning armor object and meet
  existing P3 lands/frame ties. **No new structural mounting lands** were
  needed. Decal sheets are joined into their parent plate mesh, preserving
  texture/material slots without adding inventory objects. Front/outboard
  stencil UVs are reversed during construction so lettering reads correctly.
- Local armor helpers centre plate outlines before kit machining, split
  faces at each taper break before bending them, and dissolve collapsed
  bevel edges. This avoids numerical inset errors, twisted groove floors
  and zero-area armor faces without changing the shared kit.

Final measured envelopes, including service/rail details:

| Section | Measured | Target / permitted maximum |
| --- | --- | --- |
| Thigh width / depth | 1.8260 / 1.8000 m | 1.80 / 1.80; maxima 1.85 / 1.85 |
| Thigh lowest 300 mm width | 1.3200 m | 1.32; permitted 1.20–1.37 |
| Calf width / depth | 1.6899 / 2.2400 m | 1.65 / 2.24; maxima 1.70 / 2.29 |
| Calf lowest 300 mm width | 1.06335 m | 1.06; maximum 1.11 |
| Concurrent FA-02 width / length | 1.4600 / 3.3603 m | 1.46 / 3.36; maxima 1.51 / 3.41 |

The thigh's maximum includes the integral outer ochre accent; the calf maximum
includes the two grab rails. Both are within −0.10/+0.05 of their targets.
Excess beyond the old X±0.800 transport bound is reported as **INFO**, not
shrunk away or treated as workshop approval.

### Audits and ankle clearance

`verify_envelopes.py` clips actual mesh edges against 100 mm Z slabs and
checks the lowest 300 mm band separately. It also ray-tests handling-pad
access, the three neutral hip cartridge corridors and the open rear knee.
The foot check requires all five shells and the three pad families by default;
`--only-leg` is an explicit temporary scope, not a default exemption.

The ankle check uses the **measured FA-02 guard inner faces at |X|0.710**, with
conservative guard bounding prisms. It rotates every relevant lower-calf vertex
and edge samples no more than 25 mm apart around `(0,0,1)`, using
`Rx(pitch) @ Ry(roll)`: pitch ±20°, roll ±10°, a 0.5° grid (**3,321 poses**).
Minimum sampled clearance is **43.45 mm**. Subtracting the angular Lipschitz
allowance (21.02 mm) and edge spacing allowance (12.5 mm) leaves a conservative
**9.93 mm continuous vertex/edge clearance bound**. This is not a complete
swept-facet or whole-ankle mechanism proof.

`verify_mirror.py` duplicates meshes, bakes world X scale −1, reverses winding,
and dissolves coincident bevel edges at 1 micrometre before checking every
closed shell's outward orientation/positive volume, zero-area faces and mirrored
bounds. The copy is deleted without saving. P3's unchanged LG-100 mesh contains
112 collapsed bevel faces; its temporary mirror needs this cleanup. Final
leg-only mirroring passes all 68 objects. The source structure was not repaired
or represented as having passed a new zero-area-face audit.

Final retained reports are [envelopes.json](output/audits/envelopes.json),
[scene-full.json](output/audits/scene-full.json),
[interfaces-full.json](output/audits/interfaces-full.json) and
[mirror.json](output/audits/mirror.json). **Scene, interfaces and mirror are
explicitly `leg-only`** while P4B is unfinished: all 68 meshes and all 319 leg
interface checks pass. Envelopes include the current foot and pass. Default
commands remain strict and require the complete combined result.

### Three inspected render rounds

Used the existing `render_quick.py` lighting/render function through a local
capture driver, with a front camera and front/outboard three-quarter camera.
P3 images and the renderer source were preserved. Inspected all four views in
[armor-vs-lg01-assembled.jpg](output/compare/armor-vs-lg01-assembled.jpg), plus
individual front, three-quarter and rear images where details were ambiguous.

1. Found over-short thigh armor, misplaced rail transforms and a 2 mm lower
   calf slice excess. Extended the thigh while cutting pad windows, corrected
   rail transforms, tightened the lower taper and closed rear-shroud side gaps.
2. Found mirrored stencils, partly buried rails and triangulation artifacts
   across taper breaks. Corrected UV assignment, recessed the rails, split
   the bending faces, and opened the lug channels down to their root band.
3. Inspected the final plated leg with the parallel foot armor as context.
   Stencils read correctly; rails, pad windows, hatches, open rear knee,
   rear cable channel and two recessed nozzle mouths are visible. Stopped at
   the three-round limit.

Remaining presentation differences: the explicit hip channels are much more
open than the drawing, and the long exposed neck/corrected knee drive make
larger mechanical gaps. The side calf remains flatter and boxier, the frame
and bronze interiors lighter, and wear/detail density lower than the painted
reference. These are recorded limits, not a claim of final visual approval.
Foot presentation and foot geometry repairs belong to P4B.

### Shared scene and unresolved combined build

The last successful whole-source `build.py` run preceded P4B's completed armor
rows. A subsequent full build fails in `foot_fa02.py`: its internal-only count
assertion imports `checks_foot.DEFERRED_ROWS`, which P4B has now emptied for
final verification. Its internal boundary must instead exclude the separately
built armor rows. P4B has supplied `work/foot-internal-boundary.patch`; P4A did
not apply it because foot files are read-only for this task.

An interim combined audit also found a non-manifold/non-positive toe-cap shell
and foot receiver-bore checks still under P4B repair. Those are not waived.
P4A captured its final scene at `work/p4a/final-preview.blend`, then merged
**only its 19 owned meshes** into the latest `output/leg-lg01.blend` and updated
manifests. Per-mesh digests prove all **794 unowned meshes** were preserved.
`work/p4a/final-merge.json` records this boundary; `work/p4a/round3/` holds the
capture evidence. The four final reports were rerun on the merged shared scene.
The final capture's foot is context and can become stale as P4B continues.
After the foot integration fix, the coordinator must rebuild and rerun the
unscoped scene/interface/envelope/mirror commands. No more P4A render-fix rounds
were performed, and no game regressions or gameplay approval are claimed.

P4A final inspection fingerprints:

- Comparison JPEG SHA-256: `1cf1b7f58ac76d81939bb1c6433e8b76a4a6a3157fb5e6e7324524de6149b8cd`.
- Captured scene SHA-256: `c6fd5cf5ce8b99268a6d76336bdcd4fa5603bb9242d029bb04b7a280ff113406`.
- Merged shared scene / final audit SHA-256: `f1a376a5c3a7e333d6d10a568d8e045184b4f6181a4067b9dff7bb0543dbe807`.


## FA-02 foot armor

P4B, 2026-11-01. `src/foot_fa02_armor.py` implements the **14 formerly deferred
CSV rows / 143 independent physical objects**: five shells, six pads, 24
compression sleeves, 20 captive retaining collars, 44 bolts and 44 separate
washers. The complete foot now has **745 objects / 182 complete rows** and
**436,404 triangles**, below the 800,000 foot budget. The existing `build.py`
module list already includes `foot_fa02_armor`; no list change was needed.
`checks_foot.DEFERRED_ROWS` is empty. No commit was made.

### Geometry and receiving parts

- Shells use warm off-white, a painted ochre toe band/nose and a small red heel
  caution bar. Plan corners are 60–120 mm facets, with broad folded roof edges
  and real 20 mm skins; the front upper plate has one 25 mm shallow panel score.
  The toe preserves the two-stage roof and moving-frame ownership. The upper
  plate has the rear-open X±590 notch and the fixed outer actuator relief.
  The 290 mm hinge channel remains open between Y1210 and Y1500.
- Guard wall faces are X±710…730, with tops Z1600. The guards have open front,
  rear and top, and no bridge over the shin. Their small local 30 mm lands reach
  |X|684 and locator tabs reach |X|680. Those local features, the supporting
  cradle arms and actual neighboring lower shin/calf meshes passed the sampled
  sweep below. This uses the present `shin_calf_armor.py`, rather than the
  fallback assumption for an absent leg model.
- Each shell has exactly four captive M12×50 bolts, four W-12 washers, four
  separate FA-405 collars and two 10 mm engagement sliding locators. The bolt
  wells are 16 mm deep; 30 mm lands and 2.5 mm washers leave 17.5 mm receiver
  engagement. Each 4 mm collar occupies its own back counterbore. Head planes
  are recessed, with vertical toe/upper axes, rearward heel access and lateral
  guard access. Per-object owner and removal-direction metadata are retained.
- **All receiver additions are made by the armor module to existing registered
  objects.** FA-104-A/B each gain two toe bolt bosses and one locator socket;
  FA-100-A/B each gain two upper-plate and two heel bosses plus two locator
  sockets; FA-103-L gains eight guard bosses/posts and four locator sockets.
  Their support braces are drilled through the receiving axes. These are
  integral features, not new inventory parts. Crossmembers, existing bearing
  interfaces, carrier holes and the internal generator source are unchanged.
- The six pads use the FA-02 paired limits, a 50 mm center gap, 20 mm bevels,
  30×12 grooves on 120 mm pitch, protected circular bolt lands and Ø56
  counterbores. Sleeves are ID26/OD42×76 at Z64…140; washers are Z60…64;
  upward M24×120 bolts have their lowest head points at Z36 and tips at Z180.
  The existing carriers supply 40 mm engagement. Rear/forefoot ownership stays
  separate. Pads remain interchangeable within each pair.
- Closed manufactured features are machined separately before rejoining their
  one inventory mesh. This prevents Boolean welding of coincident folded-skin
  seams. All final geometry has applied modifiers, outward normals and closed,
  positive-volume feature shells, under the existing visualization-solid rule.

### Verified results and the protected build boundary

Blender **5.2.3 LTS** verified the fresh scene. `verify_scene.py -- --expect full`
passes **813 objects, zero failures**, including every foot row and the present
leg armor. `checks_foot.checks()` passes **1,414 checks** with no deferred rows.
The checks measure actual vertices and bore/seat ray intersections: all 24 pad
stacks, 20 shell lands/receivers/collars/washer planes, pad grooves, ownership,
guard tops, open notch/actuator relief/channel, and the existing internal checks.
Triangle intersection checks find no guard or cradle-arm contact with the actual
shin beam and calf shells at **231 poses**, pitch −20…20 and roll −10…10 in
2-degree increments. This is sampled geometric evidence, not a continuous
motion or extraction-path certification.

Measured bounds are X **−0.730…0.730**, Y **−0.900300…2.460**, Z **0…1.600**.
The extra 0.3 mm at the rear is the caution-paint geometry and is inside the
10 mm model tolerance. Non-guard shells stay at or below Z700.

**One source-boundary change remains pending the requested scope clarification.**
`foot_fa02.py` currently imports `DEFERRED_ROWS` to validate its internal-only
602-object stage. Emptying that public set makes the ordinary `build.py` fail
before the separate armor module runs. The task makes this file read-only except
for receivers; it was therefore left unchanged. The precise prepared fix is:

```diff
-from checks_foot import DEFERRED_ROWS
+from foot_fa02_armor import ARMOR_ROWS as DEFERRED_ROWS
```

The local `work/build_foot_armor_candidate.py` applies **only that replacement in
memory**, then calls the unchanged `build.main()`. That fresh build exits **0**,
produces the final 813-object scene and manifests, and is the source of the final
passed audits and renders. This is not a claim that the unmodified normal build
command passes. `work/foot-internal-boundary.patch` contains the reviewable patch;
the coordinator must apply/authorize it and rerun `build.py` to close acceptance.
Reports/logs are in `work/foot-armor-scene.json`, `work/foot-armor-checks.json`
and `work/foot-armor-candidate-build.log`.

### Render inspection

Inspected the final [assembled comparison](output/compare/foot-vs-fa02-assembled.jpg)
and [armor/soles comparison](output/compare/foot-vs-fa02-armor.jpg) beside the two
FA-02 references, plus the [underside](output/renders/foot-armor-underside.jpg)
and top/three-quarter/side/front/rear views. Seven final JPEG captures use quality
90. The exploded view turns and lays out the pads for inspection; it is explicitly
labeled as display offsets, not insertion paths. Five detached shells, two
carriers and all six pads are separately visible; the underside shows all 24
recessed pad bolts, groove interruptions, bevels and the separated hinge region.

Completed **three fix rounds**: (1) broad folded edge facets, corrected exploded
pad transforms and uncropped/lit underside; (2) more separated pad display
positions; (3) a foreground row making all six pads independently countable.
No further visual iteration was performed. Earlier comparisons and capture hashes
are retained under `work/foot-armor-round1/`, `round2/` and `round3/` (each directory
uses the full `foot-armor-` prefix). The final recipe is
`work/render_foot_armor.py`; hashes and inspection decisions are in
`work/foot-armor-evidence.json`.

The guards have broader crowns than the drawing because the specified two upper
bolt axes at Y±500/Z1450 need material around them. The written rear notch and
hinge channel also leave more machinery visible than the concept sheet. Exact
M12/M24 sizes produce smaller-looking fasteners than its exaggerated wells.
Surfaces are cleaner and less weathered. These differences are recorded rather
than replacing the specified geometry or adding unlisted cosmetic fasteners,
guard ochre, extra panels or a roof across the shin. Full continuous sweeps,
flexible service motion and extraction/tool paths remain outside this static
source-model evidence. No game tests, game changes or user visual approval are
implied.

## Coordinator verification, phase 4 (2026-11-01)

Fresh isolated rebuild: 813 objects (68 leg, 745 foot), 572,656 triangles. Scene
(`--expect full`), interface (320 leg + 1,414 foot checks), envelope and mirror
audits all pass. Integration fix applied by the coordinator: `foot_fa02.py` now
checks its own rows against `foot_fa02_armor.ARMOR_ROWS` instead of the emptied
`checks_foot.DEFERRED_ROWS`.

**Open mesh-quality item:** 22 source meshes (for example LG-100, FA-103-L,
FA-104-A/B, FA-106, FA-200) contain 1,969 zero-area faces left by collapsed
bevels. They render correctly, and the mirror audit dissolves them (1 µm)
before checking winding and volume, but a clean-up pass in the generators
would remove them at source.

## Phase 6 round 1 — leg

P6F1-LEG, 2026-11-01. Scoped source changes for review-r1 T1–T4, K1–K2
and C1–C4; no foot/rendering-source edits and no commit. Built/tested in sibling
`models/leg-lg01-f1leg`, with evidence retained in `work/p6f1-leg` before scratch
cleanup. The existing game and production `output/leg-lg01.blend` are untouched.

- **T1:** broadened the thigh above Z6.65, keeping its 1.80 m maximum and lower
  knee taper. Front and rear plates now carry folded corners and integral dark
  seam backing; side seams are nominally 35 mm instead of open wedges.
- **T2:** preserved the channel throat positions/widths and top-open approach;
  faceted their entry mouths by 80 mm and added inward dark front-channel lips.
  Neutral cartridge-corridor checks remain separate from a full articulated hip
  sweep, which is still open.
- **T3:** moved the outer shoulder's angular ochre patch to its forward edge,
  following the existing channel cut and staying within |X|0.90. No hip guards
  or new inventory objects.
- **T4:** front inserts are 150 × 850 mm, with 25 mm surrounding recesses and
  gunmetal faces 20 mm below the painted surface. Centres move to X±0.69
  rather than the suggested ±0.60 to clear the inner/front channel. Intersecting
  backing/paint solids receive the same channel cut individually before joining
  the plate, so details cannot reclose a required opening.
- **K1:** kept X±0.39/Z4.69–5.48; the ochre chisel face rises toward Y0.85 and
  its 80 mm pale perimeter folds back to Y0.64. The rim splits at the same
  ridge as the face so its folded flanks meet continuously. Rear bracket space
  remains open.
- **K2:** shaped the angular guard's end facets and layered each Ø548 bearing
  cover with two concentric steps; the cover remains below |X|0.67.
- **C1:** upper calf width remains 1.65 m, with broader middle/upper stations;
  folded front/rear returns and backed 35 mm side seams join the faceted skins.
  The rear shoulder slopes from Y−1.40/Z4.15 toward Y−0.75/Z4.60. Lower ankle
  geometry is retained for the existing bounded vertex/edge sweep.
- **C2:** mouths increase Ø640 → Ø780 and retain 12° rear/down axes. Seats move
  from `(0,−0.720,3.980)/(0,−0.720,2.930)` to
  `(0,−0.865296,4.025538)/(0,−0.865296,2.875538)`, putting lip centres at
  `(0,−1.550,3.880)/(0,−1.550,2.730)`. Cradle ribs follow the revised seat
  positions; machined seat radii and depths are unchanged. Shroud recess faces
  move to Y−1.40 and use separate 920 mm octagonal apertures. Corresponding
  `verify_interfaces.py` expected seat/mouth values change; the obsolete
  requirement to bury mouths at least 80 mm inside a rear wall is replaced by
  an exposed-bell check. The Y≥−1.64 rear limit is retained.
- **C3:** bridge becomes 900 × 220 mm at Z3.305 with 25 mm top/bottom gaps.
  Bent ochre rails have 55 mm octagonal sections, 650 mm span and 80 mm rise
  from their feet, recessed to stay inside |X|0.825.
- **C4:** added a closed 650 × 300 mm caution-panel groove centred Z2.05,
  25 mm wide/15 mm deep, and widened the two shin inserts to 160 mm. All
  features remain integral to LG-400.

### P6F1-LEG validation and inspected presentation

Final frozen-source build: **813 objects, 578,994 triangles**. `build.py`,
`verify_scene.py -- --expect full`, `verify_interfaces.py` and `verify_mirror.py`
all exit **0** on the scratch scene. All 68 leg meshes also pass the focused
closed-mesh audit. No game regression or player acceptance is implied.

**The required all-zero gate is not yet complete.** The authoritative
`verify_envelopes.py` exits **1**, solely because its calf-depth measurement
includes armor/service objects but excludes LG-450. It reports 2.000 m against
2.140…2.290 while the complete calf with exposed nozzles is **2.231085 m**.
The out-of-ownership file was left unchanged. A precise
[prepared patch](work/p6f1-leg/include-nozzles-in-depth.patch), tested as a separate
scratch audit, exits **0** on the exact final scene. It includes LG-450 only for
depth; width, taper, all tolerances and clearance checks are unchanged. Approval
for that narrow scope extension was requested and has not arrived.

Measured thigh width/depth **1.800/1.800 m**, lowest-300-mm width **1.320 m**;
calf width **1.651557 m**, lower width **1.064912 m**. Pad access, all three neutral
rod corridors and central rear-knee openness pass. The bounded ankle vertex/edge
sweep retains **6.495 mm** conservative clearance after sampling allowances;
this is not a full swept-solid proof.

Two completed comparison/inspection rounds; final EEVEE captures use 32 samples
and full resolution. Inspected the
[assembled comparison](work/p6f1-leg/final/compare/cmp-lg01-assembled.jpg), all
four individual assembled views, and the
[structure comparison](work/p6f1-leg/final/compare/cmp-lg01-structure.jpg) including
the knee close-up. Final inspection confirms connected faceted corners, broader
thigh/calf masses, visible forward-shoulder ochre, pale kneecap returns, layered
bearing caps, larger inserts, framed shin termination, bridge/rail depth and
both bells visible beyond the shroud in side view. Flat armor facet normals
remove the false triangular dents seen in round 1.

| Review item | Result | Qualification |
| --- | --- | --- |
| T1 | Done | Broad thigh and folded corners with backed 35 mm side seams. |
| T2 | Done within constraints | Faceted mouths/inward returns; required deep channels remain visibly larger than the concept. |
| T3 | Done | Ochre wraps the existing forward shoulder facet, inside the envelope. |
| T4 | Done with offset | 150 × 850 mm inserts at X±0.69 to preserve the inner/front channel. |
| K1 | Done | Ochre chisel face with pale folded flanks; bracket space remains open. |
| K2 | Done | Guard facets and concentric stepped recessed caps. |
| C1 | Done | Broad upper calf, joined corner returns and sloped rear shoulder. |
| C2 | Geometry done; audit integration pending | Ø780 mouths exposed in side view at the chosen 12° axes; the separate depth-audit patch still needs authorization. |
| C3 | Done | 220 mm bridge, 55 mm rail section and recessed 80 mm stand-off. |
| C4 | Done | Closed caution-panel groove and 160 mm inserts remain integral to LG-400. |

The bronze interiors remain brighter/more funnel-like than the style-sheet
close-up; R2 lighting/finish is still a separate review item, not a claim that
this geometry pass completed surface-finish work. The true cylinder span,
hip/knee/ankle datums, three lug carriers, open rear knee, handling pads and
omission of torso-owned hip guards are retained. No fresh-reviewer or user
visual approval is claimed.

Renderer handoff: the current renderer's orthographic `shaded_thigh` ray at
X−0.76 misses LG-210 after the shape change. **Only in the scratch renderer**, the
sample moved to the new LG-200 corner at X−0.82 (same Y/Z/ray). The shared render
files were not edited. Its owner should choose the corresponding probe for the
integrated model. Rendering did not change the saved scene.

[Evidence index](work/p6f1-leg/evidence.json) retains source/capture hashes,
original and candidate audit results, logs and per-item status. The final scene
is retained locally at `work/p6f1-leg/final/leg-lg01.blend`, SHA-256
`dfa0b2114829df4610f269e3438580b179f6e90b0a6e156772966a9790b0f7da`.
The source snapshot preserves the foot baseline used for these leg-only edits;
concurrent foot/rendering changes need the coordinator's integrated rebuild.
The sibling scratch directory was deleted after evidence retention. No commit.



## Phase 6 round 1 — foot

P6F1-FOOT, 2026-11-01. Implemented Foot F1–F3 from
[review-r1](output/compare/review-r1.md), using the FA-02 assembled and armor
references. Source changes are confined to `src/foot_fa02_armor.py` and
`src/checks_foot.py`. **Receiver edits: none; `src/foot_fa02.py` is unchanged.**
No commit was made. Shared scene, manifests, comparison outputs and the other
agents' leg/render sources were not overwritten.

| Item | Implemented result | Evidence |
| --- | --- | --- |
| **Major F1** | Toe, upper plate and heel now share roof/wall vertices along their folded perimeter, then thicken inward by 20 mm. Paint and roof-slope regions remain part of one continuous skin. The 80–100 mm corner facets close the former triangular holes without closing the separate hinge channel. | All five shells pass closed-solid/normal checks; six independent rays cross the former corner holes. Inspected assembled side/three-quarter/back and armor explosion. |
| **Major F2** | Each guard has a 400 mm Y × 360 mm Z through-window centered at Y0/Z1000, with 60 mm corner cuts. Walls remain at X±710…730, tops at Z1600, with four prescribed bolt axes and separate lateral removal. | Measured window bounds, 20 mm wall thickness, all eight chamfer vertices, aperture samples and retained corner material pass. Nine rays per side reach the actual pitch cap without other foot parts intervening. The cap and its retention screws are visible in the side render. |
| **Minor F3** | Guard perimeter facets are 80 mm wide with 6 mm surface relief inside the existing wall. Each original M12 seat gains a 130 mm octagonal depression ending at the existing 16 mm recessed seat. Planar guard shading preserves those shallow faces instead of smoothing them away. | Perimeter relief and all eight recessed lands pass ray measurements. Side and oblique renders show the facets and octagonal wells. No new fasteners or guard ochre. |

The pre-render audit caught a Boolean operation that discarded the outer guard
when a broad recess was cut through already combined, intersecting lands. All
four depressions are now machined while the guard is a single wall, before the
lands and locator features are added. The final ordinary build and strict audits
pass; the failed preliminary logs are retained separately in the evidence folder.

Preserved the review's written constraints: five shells with four captive bolts
each; toe-only ochre; open guard top/front/rear; rear-open upper notch X±590 to
Y550; unbridged Y1210…1500 hinge channel; shell/guard heights 700/1600; compact
heel; six four-bolt pads with 960 mm forefoot versus 740 mm heel lengths. Two
rear/two forefoot rails, FA-210 at Y1340/Z350, three independent drives, rear roll
actuator and the short ankle pins are unchanged. The captured leg sources retain
the specified joint heights, cylinders, hip ownership, rear knee and lifting pads.

### Scratch verification and inspected renders

Built and verified only in `models/leg-lg01-f1foot/`, from an initial copy of all
source files followed by syncs of the two owned files. Blender **5.2.3 LTS**:

- `build.py`: exit **0**, **813 objects / 571,708 triangles**; foot **745 objects /
  435,456 triangles**.
- `verify_scene.py -- --expect full`: exit **0**, **813 objects**, no failures.
- `verify_interfaces.py`: exit **0**, **320 top-level checks** and **1,468 foot
  checks** (54 added to the prior 1,414), no failures.
- `verify_envelopes.py`: exit **0**. Foot bounds X±0.730,
  Y−0.900300…2.460, Z0…1.600; the rear 0.3 mm is existing caution paint.
  Existing 3,321-pose calf vertex/edge clearance lower bound remains **9.93 mm**.
- `verify_mirror.py`: exit **0**, **813 objects**, no failures.
- Foot checks retain **231** sampled actual shin/guard/receiver-arm poses with
  no intersections. These bounded checks do not certify complete swept solids,
  flexible services or tool/extraction paths.

Ran `src/render_compare.py --only fa02-assembled,fa02-armor` through Blender,
exit **0**, twice: first inspection accepted the closed corners and cap windows;
second inspection confirmed the improved guard facets and wells after the shading
adjustment. **Two render rounds total; no further round.** Inspected both final
comparison sheets plus side, three-quarter, back and exploded detail images.
No F1–F3 major remains in those inspected views. The broad crowns, large notch
and open hinge remain deliberate specification differences. Lighting, wear and
the compact exploded layout remain the separate rendering scope; no user visual
approval or game testing is implied.

Evidence is retained locally under [work/p6f1-foot](work/p6f1-foot/evidence.json):
[assembled comparison](work/p6f1-foot/compare/cmp-fa02-assembled.jpg),
[armor comparison](work/p6f1-foot/compare/cmp-fa02-armor.jpg), final audit JSON/logs,
source snapshot/hashes, earlier render round and preliminary failure logs. The
scratch directory and its build scene were deleted after retention. Shared
outputs still need the coordinator's combined rebuild with the other agents'
changes; these passes apply to the captured leg/render source snapshot.

Final fingerprints:

- Scratch scene: `16242b7c8da4b67560e1143a602110747c26adc339a8819954ec20a09fbd2746`.
- Assembled comparison: `69963f0c8c1571750a90db97aa5f10349213e608054079c270b50478523e4190`.
- Armor comparison: `a3da7e71ca4ed46972f0376b2e23b555803ef45bbf47ddcba39ba0b6f637dc14`.


## Build sequence

P5, 2026-11-01. `src/sequence.py` is authoritative for **813 physical instances
in 69 steps**. It emits the exact `leg-lg01-build-steps/1` viewer contract, with
no placeholder marker or `Preview · ` titles. The existing placeholder generator
actually protects production files by their title prefix, not a JSON flag.
`src/verify_sequence.py` writes [sequence.json](output/audits/sequence.json).
No generator, game or design-document source was changed, and no commit was made.

### Order and preparation boundaries

| Steps | Installation |
| --- | --- |
| 1–15 | Rear rails/nut plates/crossmembers, cradle, stops, pitch ring and roll adapter, bushings, thrust washers, short pins and caps |
| 16–19 | Bolted forefoot frame, hinge bushings/washers, outboard axle, retaining cap and stops |
| 20–28 | Forefoot, pitch, then roll drive: clevis pair, prepared actuator, axial eye pins/keepers |
| 29–33 | Two sole carriers and three paired pad groups with sleeves and hardware |
| 34–37 | Junction box, controller/sockets, main and branch harnesses/clips, lid |
| 38–42 | Toe cap, heel cover, upper plate, inner and outer ankle guards |
| 43–54 | Shin/flange hardware, knee bearing stack, fork/spar, axle/cap, cradle, cylinders, hip lugs, services, engines |
| 55–69 | Thigh plates, knee bracket/shield/guards/covers, shin/calf/shroud/bridge, hatches and rails |

The following are deliberate deviations from the prose plan, not extra inventory:

- **Shin before upper leg:** S43 seats LG-100 on FA-201 with the four foot-owned
  H-36090 bolts and W-36 washers. S44 fits bearings/spacers, S45 offers the bolted
  LG-110/LG-120 fork/spar unit over the shin boss, then S46 inserts LG-140 from
  outboard (−X). The fork's bolts travel with that unit. This removes the unsupported
  spar/fork-before-shin ordering. The foot main lead is routed with its upper plug
  parked at the flange; seating the shin mates that disconnect.
- **Prepared pieces in one translation:** the contract gives each instance only
  one start position and one installation. It cannot show building a unit on a
  bench followed by moving that assembled unit again. The forefoot frame and each
  91-piece actuator are therefore coherent prepared groups, with every separate
  physical object and its internal mount dependencies preserved. Pitch bushings
  travel with the ring and roll bushings with the adapter; otherwise their larger
  diameters would be driven through the smaller surrounding pin bores. Exposed
  retaining pins still have separate axial installation steps.
- **Forefoot drive before pitch:** its outboard base-pin path passes through the
  later pitch base-clevis location. Install each drive's clevises immediately before
  that drive, securing the forefoot pins before the pitch clevis arrives.
- **Cradle before knee cylinders:** fit LG-440 at S48, before cylinder brackets and
  cartridges at S49–50. The rear approach crosses the cylinders if they are already
  present. Brackets and cylinders approach from their respective sides; the two
  engines remain after the services at S54. All armor remains after mechanisms.

Every part has an explicit mount-parent rule; only the two founding rear rails
have no parent. Same-step preparation is permitted, but the parent graph is acyclic.
Separate fasteners, washers, pad sleeves and captive collars travel exactly with
the part they retain. Hardware ownership uses stable instance-ID ranges, not
nearest-mesh guesses. Foot inventory ownership of the shin bolts is explicitly
overridden for **installation** onto LG-100. Armor flags include the removable
service/accent panels and their separate captive hardware.

### Approaches and exploded layout

Approaches point from the assembled position toward the start, in Blender metres.
Offsets are **0.6–3.0 m**. The layout uses coherent lanes: soles below the frame,
frame/core pieces above it, side armor and guards outside their respective sides,
front plates forward, heel/rear covers rearward, prepared drives beside their
mounting region. The tall shin and fork/spar use 2.5/2.8 m upward offsets.
Both long axles enter from −X, shin bolts from +Z; roll pins follow Y and pitch
pins X. Actuator pins follow their actual local axes, including the tilted roll
axis and opposite pin/keeper sides on the roll and forefoot drives. The upper
plate/toe cap move upward, heel cover rearward, and guards inward/outward as
specified. These are authored display/installation directions, not rendered
presentation approval or a full continuous motion certificate.

### Acceptance and the two documented clearance exceptions

Blender **5.2.3 LTS** generated the sequence on a copy of the complete post-armor
813-part model. The production blend was left untouched while other agents edited
geometry. The audited input is retained locally at
`work/p5/sequence-scene.blend` (SHA-256
`0bb9f5c6b803e2b33bb54fb82bc2c170942b899a6bcd349478c10ec6b9c7c2a8`).
The sibling scratch directory was removed after verification. This is a Phase 4
geometry snapshot; the coordinator must rerun on the final repaired blend.

The audit passes unique coverage, scene `step` properties, exact exported contract,
40–80-step count, nonempty verb/part titles, normalized directions, offset limits,
acyclic mount order, and hardware grouping. Its 11-point straight sweep checks
progress 0.0–0.8, exempting the final 15% insertion interval and actual receiving
parts. Shrinking every AABB face 5 mm collapses **250 thin bounds**; these empty
bounds are explicitly counted, not claimed as separately collision-checked.
There are **1,324,584 sampled box comparisons**, **zero unexcepted violations**,
and two documented exception rules:

1. **Nonconvex envelopes: 291 part pairs.** A single box fills frame openings,
   cable loops, shell notches and cowl apertures. These findings are accepted only
   after a fresh evaluated-mesh check at every offending sample finds neither
   intersecting surfaces nor containment of a connected solid in another solid.
   Containment is checked in both directions and per closed shell. Every affected
   pair/sample remains listed in the report. This conditional evidence is rebuilt
   on every Blender audit; it is not a category-wide unconditional waiver.
2. **Upper plate locator lift: one real path limitation.**
   `FA-401-L.upper-foot-plate.01` against `FA-103-L.001` still has mesh contact
   at 80% of the 3 m vertical descent: the plate's low skirt/locator geometry
   crosses a high cradle receiver. Only this exact pair and sample are excepted.
   It needs a revised receiver or a tipped/multiple-segment placement; neither
   is certified by P5's one-vector animation. No generator was altered to hide it.
   A changed model that introduces contact at other sampled positions fails.

The static `python3 models/leg-lg01/src/check_viewer.py` check passes with **813
nodes and 69 steps**. Its previous GLB contained only the 651-part structural
snapshot, so the existing, unmodified exporter was run on the audited scratch
scene and its generated GLB was refreshed beside the real steps JSON. The source
blend and viewer code remain untouched. The JSON has no placeholder flag.
Six negative probes reject duplicate/unknown IDs, nonverb titles, nonunit vectors,
excessive offsets and reversed mount order. A second sequence run proved identical
JSON, world matrices, meshes and step assignments. Local evidence is under
`work/p5/` (`check-viewer.json`, `idempotence.json`, `negative-probes.json`).
No browser/render review, gameplay tests or player approval is claimed.

Coordinator rerun after integrating the geometry fixes:

```sh
blender --background models/leg-lg01/output/leg-lg01.blend --python-exit-code 1 --python models/leg-lg01/src/sequence.py
python3 models/leg-lg01/src/verify_sequence.py
blender --background --factory-startup --python-exit-code 1 --python models/leg-lg01/src/export_viewer.py
python3 models/leg-lg01/src/check_viewer.py
```

Plain Python auditing launches Blender to read the actual saved scene. An explicit
`--blend PATH` can select the retained P5 snapshot; `--manifest PATH` is labelled a
snapshot-only authoring check and cannot grant the mesh-proven envelope exceptions.
