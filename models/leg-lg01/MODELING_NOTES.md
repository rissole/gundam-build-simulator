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
