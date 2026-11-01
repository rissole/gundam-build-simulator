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
