# Left leg high-definition 3D model: build plan

Written 2026-11-01 for a long-running `/goal` agent loop in a fresh context.
**Authorised by the user:** `gpt-6-astra` agents at **xhigh** reasoning for any
task in this plan. This is a handoff brief: when the goal finishes, fold its
lasting facts into the model README and design documents and delete this file
(project rule: no finished briefs left in the repository).

## Goal prompt

Paste after `/goal`:

> Execute `design/visual-design/leg-model-plan.md` in the Gundam Build Simulator
> repository. Build a high-definition, separately modelled 3D left leg (hip ball
> to sole, foot included, with all armor) that matches the approved look and
> the LG-01 and new FA-02 concept sheets, then open the drag-to-scrub build
> timeline viewer. Work phase by phase on branch `model/leg-lg01`, verify each
> phase's acceptance checks yourself, commit per phase, and use `gpt-6-astra`
> xhigh sub-agents as the plan describes. Don't stop for questions: record
> them, choose the documented default and continue. Finish with the viewer
> open and a summary of what passed, what was inspected and what is still open.

## What "done" means

1. A Blender-generated left leg from the hip ball (Z 9.20) to the sole, with
   every part in the [leg component list](../legs/leg-components.csv) and the
   foot's component list modelled as separate, named objects with real
   thickness. Armor is on.
2. It reads as the robot in the [approved turnaround and style guide](turnaround/README.md)
   and the [LG-01 sheets](../legs/images/README.md), plus new FA-02 foot sheets
   (phase 1). Rendered side-by-side comparisons against those images are
   inspected, and their findings are fixed or recorded.
3. The joint heights and envelopes in the [approved proportions](../proportions.md)
   hold to within 10 mm. Interfaces follow the component specifications.
4. A local HTML viewer plays the build as a timeline. A slider drags through
   every step, and parts move into place as you scrub. The viewer is open in
   the browser at the end.
5. Documentation, component lists and modelling notes are updated, every
   phase is committed on the branch, and the work is ready for the user to
   review and merge.

**Out of scope:** the Godot game (no game file changes, no game regressions
needed), the right leg as a separate model (mirroring is verified, not
delivered), the torso, arms and head, workshop clearance updates, and
fabrication-grade solids.

## Sources and authority

Highest authority first. Where a lower source conflicts with a higher one,
follow the higher source and record the conflict in `MODELING_NOTES.md`.

1. [Proportions](../proportions.md): joint heights and the 2026-11-01 envelopes
   (thigh 1.80 → 1.32, calf 1.65 → 1.06 and 2.24 deep, foot 3.36 × 1.46).
2. Component specifications: [thigh and hip](../legs/thigh-and-hip.md),
   [knee](../legs/knee.md), [shin and calf](../legs/shin-and-calf.md),
   [foot and ankle](../legs/foot-and-ankle.md) with its detail packet
   (`dimensions.md`, `parts.md`, `actuators.md`, `assembly-and-review.md`,
   `hardware.csv`) and the [leg prototype interface](../game/leg-prototype-interface.md)
   for LG-100 to LG-150. Their detailed interface numbers predate the silhouette
   revision. Keep joint centres and mating interfaces, and fit armor to the new
   envelopes.
3. [Style guide](turnaround/README.md): palette `#D2C8BC` / `#4C4C4B` /
   `#D4861D` / `#C2332A`, chamfers, panel lines, recessed hex bolts, hatches,
   grab rails, stencils, light wear.
4. Concept images: [LG-01](../legs/images/README.md) (with its **known drawing
   errors**; for example, the knee cylinders must run thigh to shin, not thigh
   to fork), FA-02 from phase 1, and the [turnaround](turnaround/turnaround-v3.jpg).
5. The [FA-01 model](../../models/foot-fa01/README.md): working generator code
   and lessons ([modelling notes](../../models/foot-fa01/MODELING_NOTES.md)). Keep
   it intact; the game's foot asset came from it.

## Rules for the loop

- **Branch:** create a worktree `../gundam-leg-model` on a new branch
  `model/leg-lg01` from `main`. Commit at the end of each phase with a clear
  message and the attribution line the session requires. Don't merge into
  `main`; the user merges after reviewing the viewer.
- **Never modify:** `game/`, the approved images in `design/visual-design/`,
  the silhouette mannequin, or the FA-01 package's outputs.
- **Sub-agents:** launch spatial, modelling, rendering and image tasks with

  ```sh
  codex exec --dangerously-bypass-approvals-and-sandbox -m gpt-6-astra \
    -c model_reasoning_effort='"xhigh"' -C ../gundam-leg-model "$(cat task.md)" \
    [-i ref.jpg ...] < /dev/null > log.txt 2>&1 &
  ```

  - Always add `< /dev/null`; without it a backgrounded `codex exec` hangs
    waiting for stdin.
  - Give each agent a self-contained task file listing the files it owns,
    its acceptance checks and its stop conditions.
  - Run at most three agents at once, and give them disjoint files.
  - Check each running agent every 180 s (process alive, log growing,
    files appearing); stop a stalled one and relaunch it with a narrower task.
  - The coordinator reruns every acceptance check itself and commits; agents
    don't commit.
- **Questions:** don't block. Append to `models/leg-lg01/OPEN_QUESTIONS.md`
  with the default chosen, and continue.
- **Iteration budget:** at most three comparison-and-fix rounds per section in
  phase 6. Record what remains, then move on.
- **Temporary files** go in a gitignored `models/leg-lg01/work/`. Generated
  GLBs and `.blend` backups are ignored (as in FA-01); the scene `.blend`,
  manifests, audits, comparison sheets (JPEG, quality 90) and the viewer source
  are committed.

## Package layout

```
models/leg-lg01/
  README.md            deliverables, how to rebuild and open the viewer
  MODELING_NOTES.md    decisions, resolved dimensions, conflicts with sources
  OPEN_QUESTIONS.md    questions raised and defaults chosen
  src/
    kit/               shared hard-surface shape library (phase 2), reusable later
    materials.py       style-guide PBR materials and decals
    thigh.py knee.py shin_calf.py foot_fa02.py   part generators
    sequence.py        build steps and exploded offsets
    build.py           whole scene, manifest and exports
    verify_*.py        scene, envelope, interface, mirror and export audits
    render_compare.py  views matching each concept sheet, side by side
  output/              leg-lg01.blend, manifest JSON/CSV, audits, renders
  viewer/              index.html, viewer.js, build-steps.json, leg-lg01.glb (ignored)
  open-viewer.command  starts a local server and opens the viewer
```

## Phases

Each phase ends with its acceptance checks passing (run by the coordinator)
and a commit.

### Phase 0: set up and read

- Create the worktree and branch. Read this plan, the sources above, the
  [component pipeline skill](../../.agents/skills/gundam-component-pipeline/SKILL.md)
  (sections 2–3 and the rendering contract) and FA-01's `build.py`,
  `geometry.py` and `MODELING_NOTES.md`.
- Confirm Blender (`blender --version`; 5.2.3 was tested) with glTF export and
  Pillow are available.
- Write `models/leg-lg01/README.md` (skeleton) and `OPEN_QUESTIONS.md`.
- **Accept when:** the branch exists, and the README states the scope, the
  sources and their authority order.

### Phase 1: foot concept sheets and component list (FA-02)

The foot has no sheets in the approved look, and its approved size changed
from 3.00 × 1.30 to 3.36 × 1.46.

- **FA-02 dimensions.** Decide how the plan scales from FA-01 and record it in
  a new "FA-02 revision" section of
  [dimensions.md](../legs/foot-and-ankle/dimensions.md). The default:
  - **Fixed:** heights, the ankle pivot at Z 1.00, guard tops at Z 1.60, the
    shin flange interface and the actuator internals.
  - **Scaled:** frame rails, crossmembers, soles, shells and the forefoot
    hinge position, about the ankle in plan.
- **Component list.** Create `design/legs/foot-and-ankle/foot-components.csv`
  with the same columns as the [leg list](../legs/leg-components.csv), derived
  from `parts.md`. Update `hardware.csv` only if counts change. Part numbers
  must match the project format (`tools/part_numbers.py`): one suffix only,
  and handed parts take -L/-R.
- **Sheets.** Launch one Astra xhigh agent with Codex's built-in `image_gen`
  (imagegen skill), using the same task format as LG-01 (see
  `design/legs/images/` prompts and `notes.md`). It produces
  `fa02-assembled`, `fa02-armor` (shells, soles, labelled from the CSV) and
  `fa02-structure` sheets in `design/legs/foot-and-ankle/images/`, with up to
  two corrections per sheet.
  - **References:** turnaround v3, style sheet v3, `lg01-assembled-v3.jpg`
    (the leg the foot attaches to) and FA-01's sheets, for mechanism layout
    only.
  - **Keep each image's prompt next to it.**
  - **Convert the final sheets to JPEG.**
- **Register.** Update the image register README to mark FA-01 as superseded
  in look, and record known drawing errors.
- **Accept when:** three FA-02 sheets with correct, legible labels; the CSV
  validates (ids match the format, and quantities match `parts.md`); the
  dimensions are recorded.

### Phase 2: shape kit and materials

Build the reusable hard-surface library in `src/kit/`, driven by numbers
rather than hand-modelling:

- **Plates:** a 2D outline extruded to a thickness, with a per-edge chamfer
  and bevel, plus faceted noses (more than one face on the leading edge).
- **Lofts** between outlines, with chamfered corners, for tapered limbs.
- **Panel lines:** grooves about 25 mm wide and 15 mm deep along a path on a
  plate, cut with booleans or by inset and extrude.
- **Fasteners:** recessed hex bolts in octagonal wells, in groups.
- **Service parts:** access hatches (an inset panel with a seam and a latch),
  grab rails (bent bar with feet and bolts), and louvered intakes.
- **Turned parts:** bell nozzles (lathe profile with a bronze inner lining),
  hydraulic cylinders (barrel, gland, polished rod, spherical eyes) and
  clevises.
- **Cables:** bundles swept along curves.
- **Finishing:** weighted normals or auto-smooth with sharp edges, so hard
  edges stay crisp. Use real bevel geometry; don't rely on normal maps.
- **`materials.py`:** satin painted armor (`#D2C8BC`, roughness about 0.45),
  gunmetal frame (`#4C4C4B`, metallic 0.6, roughness 0.5), safety ochre,
  polished rod chrome, bronze nozzle lining, rubber, and amber emissive for
  sensors.
  - **Stencils** ("CAUTION" bar, unit "01", small red marks) are decal planes
    with textures generated by Pillow.
  - **Wear** stays subtle: a baked edge-wear mask, or a darker-roughness
    vertex-colour layer on chamfers.
  - **Everything must survive glTF export:** principled BSDF only, baked
    textures where needed.
- **Test plate.** A script builds and renders a sample board of these
  features, framed like the [style sheet](turnaround/style-sheet-v3.jpg)
  close-ups (plate edge, hex bolts, access hatch, grab rail, stencil, chest
  intake, calf nozzles), and composes it side by side with the style sheet.
- **Accept when:** the board renders. The coordinator inspects it next to the
  style sheet: chamfers read clearly at 1–3 m viewing distance, bolts are
  recessed, colours match. It exports to GLB and reloads with materials
  intact.

### Phase 3: skeleton, joints and mechanisms

Model every non-armor leg part in the leg component list, plus the FA-02 foot
internals.

- **Interfaces.**
  - **Hip ball and spar (LG-120):** ball Ø0.90 at Z 9.20 with its neck.
  - **Lug carriers:** three of them (LG-240/242/244), with eyes at the
    positions in thigh-and-hip.md.
  - **Knee fork and joint:** LG-110 fork, axle (LG-140) at Z 5.10, with
    bearings, spacers and cap (LG-130/135/150) and the four LG-H24100 bolts.
  - **Knee cylinders:** LG-340 with LG-345/346 mounts, running thigh to
    shin, and partly visible at the rear sides.
  - **Shin beam (LG-100):** includes the exposed workshop pads near Z 2.80
    and Z 6.10 on the fork, and the four-bolt ankle flange at Z 1.38.
  - **Thrusters:** cradle LG-440 with two LG-450 units, stacked vertically,
    mouths angled slightly rearward and downward.
  - **Services:** service block LG-250, U-loop LG-255, cable guard LG-230.
- **Foot.** Regenerate the FA-02 internals with FA-01's generators,
  parameterised to the phase 1 dimensions, by importing or adapting them in
  `foot_fa02.py`; don't edit FA-01 in place. Keep the shin flange mating
  exactly.
- **Audits.**
  - `verify_interfaces.py` checks joint centres, flange planes, bolt circles
    and the hip lug-eye positions, all within 10 mm.
  - `verify_scene.py` checks the scene counts against both component lists,
    instance by instance.
- **Accept when:** both audits pass, and a skeleton render (armor hidden) is
  inspected next to `lg01-structure-v3.jpg` and `fa02-structure`. The
  knee-cylinder drawing error is corrected in the model, not copied.

### Phase 4: armor

Model every armor, service and accent part.

- **Thigh, LG-200/210/215/220/225:**
  - the broad front plate, outer and inner side plates, and two rear covers
    flanking a recessed service channel;
  - the mechanical gap above the thigh exposing the hip ball, neck and lug
    carriers;
  - recessed channels for the three hip-cylinder rods and lugs;
  - **no hip guards**, which belong to the torso.
- **Knee, LG-300/320/325/330:**
  - an ochre faceted kneecap, wider at the top, on bracket LG-310;
  - off-white angular side guards with recessed bearing covers;
  - the central rear of the knee left open.
- **Shin and calf, LG-400/410/415/420/430/460/470:**
  - the front shin plate, calf shells and rear shroud;
  - each nozzle in its own angular recess, with bridge panel LG-430 between
    them;
  - access hatches and ochre grab rails.
- **Foot:** the five FA-02 shells and six sole pads in the new look.
- **Envelopes** (`verify_envelopes.py`): measure the armor's outer bounds per
  section against the proportions and the LG-01 dimensions (thigh 1.80
  tapering to 1.32, calf 1.65 tapering to 1.06, calf depth 2.24, foot
  3.36 × 1.46, ankle guard tops 1.60), with no more than +0.05 m over.
  - The calf and thigh are broader than the workshop's 1.60 m transport
    bound. That is expected; record it, don't shrink the leg.
- **Mirroring** (`verify_mirror.py`): mirror the whole leg and check it builds
  with valid normals and winding.
- **Accept when:** all audits pass, and every CSV row has a modelled object
  with that part number in its custom properties.

### Phase 5: build sequence and exploded offsets

- **Steps.** Write `sequence.py` and export `viewer/build-steps.json`: an
  ordered list of steps, each with an id, a short title, the instance IDs it
  installs, and each part's approach direction and offset.
  - **Foot:** follow the build order in
    [assembly-and-review.md](../legs/foot-and-ankle/assembly-and-review.md#recommended-build-sequence).
  - **Leg:**
    1. Spar, then the knee fork with its bolts.
    2. Shin beam onto the ankle flange.
    3. Knee joint: bearings and spacers, the axle inserted from outboard,
       then the cap and screws.
    4. Knee cylinders and their mounts.
    5. Lug carriers with their bolts, then the service block, loop and cable
       guard.
    6. Thruster cradle, then the thruster units.
    7. Armor from the inside out: thigh plates, knee bracket, kneecap and
       guards, shin plate, calf shells, rear shroud, bridge panel, hatches,
       grab rails.
  - **Granularity:** about 40–80 steps in total, so each step is meaningful.
    Fasteners travel with the part they retain; they aren't steps of their
    own.
- **Accept when:**
  - every instance appears in exactly one step;
  - no part moves before what it mounts to has arrived;
  - approach paths keep clear of already-placed parts at their start
    positions (a bounding-box check is enough);
  - every step title says what is being fitted.

### Phase 6: render and compare against the concept art

- **Renders.** `render_compare.py` renders the finished leg in EEVEE with the
  style guide's lighting: white background, soft studio key, AgX or Standard
  view transform. Use cameras matching each sheet's views:
  - LG-01 assembled: three-quarter, side, front and back;
  - LG-01 armor: an exploded render using the phase 5 offsets;
  - LG-01 structure: armor hidden, plus a knee close-up;
  - FA-02: its matching views;
  - the turnaround's leg region.
- **Comparison sheets.** Compose each render beside its concept image as JPEG
  in `output/compare/`.
- **Fresh review.** Each round, launch a fresh Astra xhigh reviewer agent with
  the comparison sheets attached. It scores each section (thigh, knee, shin
  and calf, foot) for silhouette, plate breakup, colour placement, detail
  density and signature details. It lists mismatches as major or minor, and
  checks known drawing errors against the written spec rather than the
  image.
- **Fixes.** Fix the major mismatches in modelling agents, re-render and
  re-review, up to three rounds per section.
- **Accept when:** no major mismatches remain, or the remaining ones are
  recorded in `MODELING_NOTES.md` with the reason. The coordinator has
  inspected the final sheets.

### Phase 7: export and timeline viewer

- **Export.**
  - Export `viewer/leg-lg01.glb`, assembled pose, one node per instance.
  - Node `extras` carry `part_id`, name, subassembly and step.
  - **Size:** under about 150 MB, about 2.5 M triangles or fewer at full
    detail.
  - **Simplification:** if over budget, decimate hidden internals first
    (fastener threads, actuator internals), never visible armor edges.
  - `verify_export.py` reloads the GLB and checks node count, `extras` and
    material count.
- **Viewer** (`viewer/index.html` + `viewer.js`): use three.js with a version
  pinned by an import map from jsDelivr (for example `three@0.170.0`, with
  `GLTFLoader`, `OrbitControls` and `RoomEnvironment` from the matching
  `examples/jsm`).
  - **Timeline:**
    - a full-width slider from step 0 (all parts laid out exploded) to the
      last step (assembled);
    - **dragging scrubs continuously**, so a fractional position moves that
      step's parts part-way along their approach paths with easing;
    - step tick marks along the slider;
    - play/pause with speed control, previous/next step buttons, and arrow
      keys.
  - **Step panel:** the current step's number and title, plus a list of the
    parts it installs (part number and name). The parts being installed glow
    briefly.
  - **Camera:** orbit controls; front, side, back and three-quarter presets;
    and "follow step", which smoothly frames the active parts.
  - **Toggles:** show/hide armor (or ghost it at 15% opacity), and show all
    parts exploded.
  - **Lighting:** a neutral studio look matching the comparison renders (a
    room environment plus key and fill), and a light background.
  - **Robustness:** loads within a few seconds on a recent Mac; shows a
    progress bar while loading; keeps working if `build-steps.json` and the
    GLB disagree, by logging and skipping unknown IDs.
- **`open-viewer.command`:** serves `viewer/` with `python3 -m http.server`
  on a free port (a GLB can't load from `file://`) and opens it in the default
  browser.
- **Accept when:**
  - headless checks pass: a small Node or Python script validates that
    `build-steps.json` and the GLB node names match one-to-one;
  - the coordinator has opened the viewer and dragged the slider from 0 to the
    end, confirming parts move, the step text updates and armor toggles;
  - screenshots at the start, middle and end are saved to
    `output/viewer-shots/`.

### Phase 8: documentation and handoff

- **`models/leg-lg01/README.md`:** deliverables, rebuild commands (Blender
  build, then audits, compare renders and viewer export), and how to open the
  viewer. Use the same evidence labels as the final report: audits that pass,
  inspected renders, and anything not checked.
- **`MODELING_NOTES.md`:** dimensions resolved while modelling, conflicts with
  the concept sheets and how they were resolved, and the triangle and
  file-size budget used.
- **Component lists:** update both CSVs (leg and foot), and `hardware.csv` if
  counts changed. Add a status column value `modelled (LG-01-3D-01)` for the
  rows that are now modelled.
- **Specifications:**
  - Add a short "Modelled 2026-11-xx" note to the thigh, knee, shin and foot
    specs, linking the model.
  - Record any interface value the model had to settle. Don't rewrite the
    pre-revision interface sections wholesale; flag them.
- **Index:** update [ROBOT_DESIGN.md](../../ROBOT_DESIGN.md) and the
  [visual design process](README.md) (step 5 status: leg modelled, not yet in
  the game).
- **Close out:** fold anything lasting from this plan into those documents,
  delete this plan file, and commit.
- **Final step:** run `open-viewer.command`, so the viewer is open in the
  browser when the goal ends. Report:
  - the branch and commits;
  - which audits pass;
  - which renders were inspected;
  - mismatches still open;
  - open questions;
  - that merging is the user's decision.

## Risks and defaults

| Risk | Default |
| --- | --- |
| Concept sheets disagree with each other or with specifications | Specifications and proportions win; match the sheets' look, not their errors; record each case |
| FA-01 generators hard to rescale | Reuse internals unscaled where they fit; rebuild the frame rails, crossmembers, soles and shells to FA-02 dimensions |
| Model too heavy for the viewer | Decimate hidden internals and threads first; keep visible bevels; split the GLB by subassembly only if needed |
| Booleans fail or produce bad normals | Prefer inset and extrude grooves on clean topology; apply modifiers per part; check with `verify_scene.py` normals |
| Generated image refused by the service | Retry the identical prompt once, then soften wording (the LG-01 run saw one false violence flag) |
| Agent stalls or loops | 180 s check-ins; stop it, narrow the task and relaunch; record it |
| A phase can't meet its acceptance check | Record why in `MODELING_NOTES.md`, mark the item open, and continue to the next phase |
