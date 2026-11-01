# Whole-robot visual design

Started 2026-11-01 · **Silhouette approved (for now); direction B, industrial service, selected; step 3 turnaround in progress**

[Design index](../../ROBOT_DESIGN.md) · [Shared design rules](../global.md) ·
[Proportions](../proportions.md) · [Reference-image workflow](../reference-images.md)

The robot has an approved silhouette (proportions and masses, 2026-11-01,
approved for now) and confirmed features, but no approved surface look. Colours, materials, finishes and markings are open in
[global.md](../global.md#open-whole-robot-design-work). The FA-01 foot sheets
were drawn before any whole-robot reference and are **not** the target look.
This document runs the visual design from silhouette to an approved turnaround,
before any further component art or detailed in-game models.

## Process

| Step | Output | Status |
| --- | --- | --- |
| 1. Silhouette | [Blender mannequin and turnaround sheets](../../models/silhouette-mannequin/README.md) | **Approved for now, 2026-11-01**, after two rounds of studies; envelopes recorded in [proportions.md](../proportions.md) |
| 2. Concept exploration | Four whole-robot directions, each a front/side/back turnaround plus a three-quarter view, generated from the brief below with the mannequin as proportion guide | Done 2026-11-01: [four directions](concepts/README.md); the user selected **B, industrial service, turnaround v1** |
| 3. Approved turnaround and style sheet | One iterated front/side/back reference plus a style sheet: edge treatment, plate layering, panel lines, detail density and placement, palette, markings | Not started |
| 4. Component concept sheets | Per-section sheets consistent with step 3, starting with the leg; the FA-01 foot sheets are redrawn | Not started |
| 5. In-game visual models | Generated visual meshes per part from traced profiles, layered over the unchanged gameplay geometry | Not started |

Step 3's turnaround becomes the "approved whole-robot reference" that
[reference-images.md](../reference-images.md#working-method-for-preparing-images)
step 4 requires for every later sheet. Workshop gameplay does not wait for this
work: step 5 adds visual meshes on top of the gameplay shapes, keyed by part ID,
and leaves colliders, aim points, slots and manuals unchanged.

## Step 2: concept exploration brief

### Fixed: every concept must keep these

From [proportions.md](../proportions.md) and the component specifications:

- **Scale and landmarks:** 18.00 m to the crest tips, helmet roof 17.40,
  head baseplate 15.40, shoulder balls 14.40 at |X| 2.45, waist bearing
  10.50, hip balls 9.20, knees 5.10, ankles 1.00. Use the mannequin turnaround
  as the proportion guide; image generators drift, so review against the
  annotated sheet.
- **Masses (approved silhouette):** pauldrons reaching **outward**, not up,
  7.24 m across, tops near chin level and level with the chest top; a dominant
  upper chest 4.80 m wide projecting forward (front Y +1.65) and rising into a
  collar so no neck shows; a narrow 2.20 m waist; 3.60 m hip armor with front
  guards over the thighs; full forearms (1.45 m) heavier than the upper arms;
  heavy thighs (1.80 m) and calves (1.65 m); large fists; 3.36 × 1.46 m feet
  with elongated toes; 2.00 m helmet set into the collar.
- **Pose:** upright, straight knees, parallel feet, arms 15° out, elbows
  straight, palms facing inward. Left and right mirror.
- **Construction:** a mechanical skeleton with removable armor over it. Armor is
  crisp angular plates with broad clean surfaces, a few recessed bolts and
  access panels; mechanical detail is concentrated in the gaps.
- **Head:** samurai-style helmet with an angular top, a pronounced overhanging
  brow, flared stepped side and rear guards; a stern mask with angular cheek
  plates, raised nose bridge and squared chin; two narrow recessed eye
  openings; two broad upswept crest blades on a central forehead mount.
- **Torso:** two broad angular pectoral plates either side of an opaque
  upward-opening sternum hatch; three overlapping abdomen segments with narrow
  side gaps; humanlike taper to the waist; a hinged backpack with two modest
  rear nozzles and visible vent strips beside it.
- **Arms:** boxy pauldrons rigid with the arm, a narrow gap beneath exposing the
  shoulder socket rim; strong angular upper arm; recessed circular elbow caps
  inside angular guards with short actuator rods visible; a fuller angular
  forearm gauntlet; short angular wrist cuff; chunky angular four-finger hands
  with bevelled flat-ended fingertips.
- **Hips and legs:** two short front hip guards over the thigh tops and small
  hinged outer hip plates; a narrow mechanical gap above each thigh; athletic
  thigh slightly broader than the calf; a compact faceted kneecap, wider at the
  top; recessed circular knee bearing caps and partly exposed rear knee
  cylinders; a long front shin plate; an integrated calf with two vertically
  stacked circular bell nozzles in angular rear recesses either side of an
  armored bridge panel; a visible ankle mechanism between separate side guards;
  a long low forefoot and short substantial heel.

### Open: what the concepts explore

- **Shape language:** how faceted the plates are, how much they overlap and
  step, and how hard the edges are.
- **Detail density and placement:** how many panel breaks, and how much frame
  shows in gaps and at the back.
- **Colour scheme and markings:** palette, colour blocking, number of colours,
  emblem and stencil style.
- **Armor bulk within the envelopes:** how full each section is, and where the
  silhouette is broadest.
- **Face and helmet character** within the samurai brief.

### Four directions

Each is a starting point for comparison, not a commitment. All four are
original designs: do not copy a specific existing mobile suit's chest vents,
shield, face, crest shape, colour placement or markings.

| | Direction | Shape language | Detail | Palette |
| --- | --- | --- | --- | --- |
| A | Heroic flagship | Large clean plates, moderate facets, bold silhouette | Low; detail mostly in joint gaps | Off-white primary; deep blue and red blocks; small yellow accents |
| B | Industrial service machine | Squarer plates with more panel breaks and access hatches | Medium-high; exposed frame, grab rails, stencils | Warm off-white and gunmetal; safety-ochre accents echoing the hangar machinery |
| C | Samurai lacquer | Layered stepped plates like armor lames, strong brow and guard flare | Medium; layering instead of mechanical clutter | Dark navy or charcoal; crimson and muted gold trim |
| D | Sharp prototype | Fewer, larger plates on the same heavy masses; sharp facets; tight seams | Low; crisp seams and few panels | White with black frame; small orange test-unit markings |

### Prompt

Generate each direction as two images with the image-generation tool used for
FA-01, attaching
[turnaround-clean.png](../../models/silhouette-mannequin/output/turnaround-clean.png)
as the proportion and pose reference. Record the exact prompts used, including
corrections, next to the saved images in `concepts/`.

**Turnaround (shared text, then the direction paragraph):**

> Concept turnaround sheet of an original 18-metre humanoid piloted robot,
> heroic and imposing, in the spirit of classic real-robot anime mecha but not a
> copy of any existing design. Three orthographic views side by side at the
> same scale: FRONT, SIDE (facing right), BACK. Clean white background, crisp
> industrial-design rendering with soft studio shading, no scenery, no text
> except the three view labels. Match the attached grey mannequin's
> proportions, joint heights, widths and pose exactly: upright, straight knees,
> parallel feet, arms 15 degrees out from the body, elbows straight, fists
> closed with palms facing inward. Replace the mannequin's placeholder blocks with finished
> armor; do not change where things are or how big they are.
>
> Construction: a dark mechanical skeleton with removable armor plates over
> it. Mechanical detail lives in the gaps at shoulders, elbows, hips, knees,
> ankles and the back of the calves. Samurai-style helmet with overhanging
> brow, flared stepped side and rear guards, stern angular face mask, two
> narrow recessed eyes and two broad upswept crest blades on a central
> forehead mount, set down into a raised chest collar with no visible neck.
> A broad, dominant upper chest that projects forward, with two angular
> pectoral plates either side of an opaque sternum hatch; three overlapping
> abdomen plates over a narrow waist. Large boxy pauldrons that reach outward,
> not upward, their tops level with the chest top; a narrow gap below them.
> Strong upper arms; heavier angular forearm gauntlets; large angular fists.
> Two front hip guards over the thighs and small outer hip plates.
> Heavy thighs, compact faceted kneecaps, long front shin plates, calves
> with two vertically stacked round bell thruster nozzles on the back,
> visible ankle mechanism between side guards, long low feet with elongated
> toes. Left and right sides mirror.
>
> *Direction paragraph, one of:*
> **A:** Large clean armor plates with moderate facets and a bold silhouette;
> very little surface detail outside the joint gaps. Off-white primary armor
> with deep blue and red colour blocks and small yellow accents.
> **B:** Squarer plates with more panel lines, access hatches, grab rails and
> stencilled markings; more frame visible in gaps and at the back. Warm
> off-white and gunmetal armor with safety-ochre accents.
> **C:** Layered, stepped armor plates like samurai armor lames, a strong brow
> and flared guards; detail comes from layering rather than mechanical clutter.
> Dark navy or charcoal armor with crimson and muted gold trim.
> **D:** Fewer, larger armor plates with sharp facets and tight seams on the
> same heavy masses; minimal panel detail. White armor, black frame, small orange test-unit markings.

**Three-quarter view:** the same text, attaching
[mannequin-hero_low.png](../../models/silhouette-mannequin/output/mannequin-hero_low.png),
and replacing the first paragraph's view and pose instructions with "A single
low three-quarter view from the front right, as seen by a person standing on
the hangar floor, on a clean white background, matching the attached
mannequin's proportions. Wide, planted stance with fists closed."

### Reviewing the concepts

Compare the four directions side by side, then judge the favourite against:

1. **Silhouette:** does it read as one strong shape in a flat black fill at
   gantry-deck distance? Compare with the mannequin silhouettes.
2. **Proportions:** overlay the annotated sheet; landmark heights and widths
   should line up within about a plate thickness. Note drift instead of
   accepting it.
3. **Construction plausibility:** removable plates over a visible skeleton;
   gaps where the specifications put joints and mechanisms.
4. **Buildable in game:** plate forms that can be traced as profiles and
   extruded, lofted and chamfered. Prefer faceted planes over organic curves.
5. **Detail at 18 m scale:** detail that reads from a few metres away on the
   gantry, not tiny noise.
6. **Originality:** no recognisable existing mobile suit.

Expect to mix: for example, one direction's shape language with another's
palette. Iterate the chosen mix into the step 3 turnaround and style sheet.
Record choices in [decisions.md](../decisions.md) and the colour decision in
[global.md](../global.md).
