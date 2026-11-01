# LG-01-3D-01 modelling notes

2026-11-01. Final dimensions. [README](README.md) owns scope, authority and rebuild commands;
[questions](OPEN_QUESTIONS.md) retain defaults and unresolved choices.

## Coordinates, conventions and framework contract

Metres, left-leg frame: ground beneath ankle, +X inner, +Y forward, +Z up. Ankle/knee/hip centres:
(0,0,1.00), (0,0,5.10), (0,0,9.20). Whole-robot placement adds (−1.10,0,0).
Foot helpers construct in millimetres and emit metres. Mirror X for the right;
glTF converts Blender (X,Y,Z) to (X,Z,−Y).

Each module exposes `build(ctx)` and registers every physical instance through
`ctx.register`. Preserve exact CSV part ID **and name**: repeated IDs can have
different roles. Each instance has a unique ID and independent mesh, subassembly,
category and finish. Integral ribs, wells, decals and captive detail stay with
their owner; separately inventoried hardware remains separate. Build manifests
contain bounds/triangles; `sequence.py` then assigns scene steps and viewer JSON.

Kit plates use local XY, back Z0 and front +Z; `kit.place` uses radians.
Applied bevels and geometric/weighted normals preserve hard edges. Manufactured
modules may contain intersecting closed shells, not fabrication-grade unions.
Presentation cameras/lights are excluded from exports. Approved off-white
#D2C8BC, gunmetal #4C4C4B, ochre #D4861D and red #C2332A use Principled materials.
Subtle per-corner `Wear`, the current Mix Color multiply node and decal textures
survive glTF export; no normal maps. Hidden fastener helices are omitted; the
three foot lead screws retain theirs.

## Dimensions resolved while modelling

Values are metres unless marked otherwise; working selections, not manufacturing tolerances.

| Item | Final value | Source / why |
| --- | --- | --- |
| Hip ball / neck | Ø0.900 at Z9.20; neck Ø0.300, Z8.335…8.785 | Thigh/hip interface; integral with spar |
| Thigh load boxes | 0.660 × 0.540 at Z6.020…7.200 and 7.660…8.240 | Local 0.300 × 0.200 interfaces do not constrain the whole frame |
| Spar / fork flanges | 0.680 × 0.600; spar Z5.920…5.960, fork Z5.880…5.920; bolts X±0.250/Y±0.200 | Detachable joint, four M24×100 and separate washers |
| Fork support faces | X±0.800, Y−0.110…+0.170, Z5.980…6.220 | Exposed structural pads; backing below Z6.300 |
| Knee drive eyes | Upper (±0.460,−0.460,6.400), lower (±0.440,−0.500,4.300) | Thigh-to-shin connection corrects the drawing |
| Knee drive span / travel | Neutral 2.100476; retracted 1.650; extension 0.450476; usable kit stroke 1.208 | Neutral fit; maximum span 2.858 is not a verified knee travel range |
| Shin flange / key recess | 0.540 × 0.440 × 0.030, Z1.380…1.410; Ø38 mm bores X±0.200/Y±0.150; recess 0.182 × 0.102 to Z1.407 | Adapter mates at Z1.380, key top Z1.400; foot owns four M36 bolts |
| Shin section / support faces | 0.300 × 0.200 through Z2.100, expanding to 0.640 × 0.620 by Z2.420 through Z4.680; pads X±0.800/Y±0.140/Z2.690…2.910 | Narrow foot interface and broader calf frame |
| Thruster seats | (0,−0.865296,4.025538) and (0,−0.865296,2.875538) | Final exposed-bell packaging |
| Thruster mouths / axes | Ø0.780; centres (0,−1.550,3.880)/(0,−1.550,2.730); 12° rear/down, axis (0,−0.978148,−0.207912) | Separate apertures; rear limit Y−1.640 retained |
| Measured thigh / calf | Thigh 1.800 wide/deep, lower width 1.320; calf 1.651557 wide, 2.231085 deep including nozzles, lower width 1.064912 | Envelope audit; lower widths use the lowest 300 mm |
| Foot envelope / hinge | Nominal X±0.730/Y−0.900…2.460; measured 1.460022 × 3.360300; hinge (0,1.340,0.350) | FA-02 rounded plan revision; rear caution paint adds 0.3 mm |
| Foot frame / drive translation | Rail centres X±0.560, sections 0.180 × 0.240; both forefoot drive eyes +0.140Y | Preserve bearing stack, heights and actuator length sweep |
| Foot shells / guards | Five 20 mm shells; upper roof Z0.700, underside Z0.680; guard walls at absolute X0.710…0.730, tops Z1.600 | FA-02 contract; four captive bolts per shell |
| Upper plate removal | 3.0 m straight +Z; conservative plate/cradle separation 16.00 mm | Relief slots and revised integral supports remove the former exception |
| Calf / guard clearance | 38.76 mm sampled; 6.495 mm continuous vertex/edge lower bound | 3,321 poses with allowances; not a swept-facet solid proof |

## Conflicts with sources and resolutions

| Conflict | Resolution |
| --- | --- |
| Old 1.60 m transport width and Y−1.45 rear spine versus approved armor | Keep revised envelopes and exposed pads; revise workshop fixtures on integration |
| Older 900 × 900 lower-armor box for Z1.650…2.100 | Retain narrow beam; model revised calf taper and test actual guards. Old box is superseded for this model |
| Armor top below lug roots versus tall thigh | Main top Z8.230 with top-open channels to Z7.250; retain three neutral R80 mm cartridge corridors |
| LG-01 short knee drives, near-equal limb widths and high ankle | Written joint centres, thigh-to-shin eyes and proportions win |
| Turnaround hip skirts | Torso-owned; no hip guards in leg inventory |
| FA-02 tall instep, narrow fins, extra rails/bolts and misplaced axle | Keep flat roof, fixed guard seats, two rear/two forefoot rails, five shells, four bolts each and axle at hinge |
| Concept explosion versus installation motion | Comparison offsets are display arrangements; sequence carries separate approach data |
| Comparison finish versus viewer | Renderer-only cavity shading, crevice wear and lighting preserve source palette/geometry; viewer parity is not certified |

## Thigh

The spar expands into plated boxes and tapers back to 0.300 × 0.200 at Z8.300.
Carrier pin axes run along Y at (−0.339,+0.339,7.400), (+0.464,+0.124,7.400)
and (−0.124,−0.464,7.400): 94 mm gap, 50 mm ears, Ø62 mm bore. Roots occupy
Z7.250…7.600. Hip cylinders and pins belong to the parent assembly.

Front/side/rear armor begins at Z5.750/5.770/5.890; main top is Z8.230.
Exterior half-width/depth stations are 0.660/0.760/0.840/0.900 at
Z6.050/6.350/6.850/7.880. Folded corners retain 35 mm dark backed seams,
60 mm skins, top-open channels and genuine Z6.100 pad openings. Front inserts
are 150 × 850 mm at X±0.690, recessed 20 mm. The 500 × 950 mm outer service
field at Y−0.180/Z7.220 is recessed 12 mm; its 55 × 160 mm latch at Y+0.010
is 24 mm below the original skin. Both remain integral detail.

Service block centre is (0.320,0.600,8.350); U-loop length is 0.950 m with
R0.120 bend and 0.2865 m straight legs. Rear guard and six protected Ø52 mm
runs retain an open channel. Neck collar/stop tongues lack a leg CSV allocation;
only their receiving key flat is prepared.

## Knee

Axle Ø0.200 spans X±0.500 at Z5.100, entering from outboard −X. Fork cheeks
occupy absolute X0.360…0.500. Bearings OD0.298/ID0.204 × 0.120 at X±0.210 and
spacers OD0.360/ID0.204 × 0.075 at X±0.3175 leave 5 mm to each cheek.
Shin boss is OD0.560/bore0.300; retaining cap occupies X0.535…0.559.

Drive barrels/rods are Ø0.260/0.110, eyes Ø0.221 with Ø0.09503 bores; bracket
gaps/ears are 0.226/0.055. Keep the rear knee open. Eye pins/keepers have no leg
inventory allocation; travel and force sizing remain open. Shield bounds stay
X±0.390/Z4.690…5.480, leading Y0.850. Ochre extends 35 mm onto the 80 mm rim;
lateral returns stay pale. Guard front returns are 110 mm within absolute X0.670;
stepped covers are Ø0.548. No wider joint was selected.

## Shin and calf

The keyed flange retains the foot plug datum (0.250,0.100,1.400) and sleeve along
normalised (0.080,0.050,0.160). Armor starts Z1.650 with Z2.800 pad openings.
The front saddle is Z4.360 at X±0.280, rising to Z4.600 at X±0.500…0.600.
A 650 × 300 mm caution groove at Z2.050 is 25 mm wide / 15 mm deep, enclosing
heads at X±0.250/Z1.970; front inserts are 160 mm wide.

Cradle seats remain OD0.740/ID0.640 with Ø0.636 engines. Its upper fabricated
crown ends at Z4.500. Shroud back-skin stations are Y−1.340/Z4.150,
−1.200/4.400, −1.140/4.600, with 60 mm outward skin. Two 920 mm octagonal
apertures expose the bells, each with two 50 mm collar bands. Bridge size is
900 × 220 mm at Z3.305, with 25 mm gaps. Rails have 55 mm sections, 650 mm span
and 80 mm rise within absolute X0.825. Rear hatch groove is at Y−0.960,
Z2.750…3.800, leaving 67.5 mm from its edge to the hatch perimeter.

## Foot

FA-02 retains heights, ankle core, pitch/roll eyes, actuator internals and hardware
counts. The 1.160 m forefoot axle journal/stack stays unscaled. Widened rails use
half-lap seats and integral arms. The hinge-beam front face is relieved 0.5 mm
to Y1.5445 to avoid a tangent cut. Carrier mounts use X±0.560 with rear
Y−0.670/+0.170/+1.040 and forefoot Y+1.640/+2.280.

Toe roof: Y1.500/Z0.600 → Y2.400/Z0.520 → Y2.460/Z0.400. Shoulder crease
X±0.610 drops 90 mm to X±0.730. A 25 × 4 mm score at Y2.240 continues down to
Z0.300, leaving 16 mm backing. Upper shoulders drop 100 mm across absolute
X0.650…0.730. Lower side folds reach X±0.700/Z0.200, tapering out before plan
corners. Keep rear-open X±0.590 notch to Y0.550, actuator relief and open hinge
channel Y1.210…1.500.

Upper-plate slots start at absolute X0.625: Y−0.540…−0.440, +0.460…+0.540,
+0.660…+0.830. Each 18 mm cradle backbone lies at X±0.650/Z0.580,
Y−0.650…+0.790, with posts to unchanged seats/sockets. Toe tabs are at
(±0.680,1.850,0.472889), sockets 15 mm below, with unchanged 10 mm engagement.
Socket side/roof gaps are 5.00/9.69 mm.

Guard upper (Y,Z) stations: (−0.730,1.050), (−0.600,1.500), (−0.160,1.600),
(+0.160,1.600), (+0.600,1.500), (+0.850,1.090); flat crown length 320 mm.
Each has a 400 × 360 mm pitch-cap window at Y0/Z1.000, 80 mm facets and 6 mm
relief. Well mouths are 80 mm, depth 16 mm; bolt axes stay at (Y,Z)
(−0.600,0.720), (+0.700,0.720), (±0.500,1.450).

Each shell has four M12×50 bolts, separate washers/4 mm collars and two locators;
receivers are integral to rails/cradle. Six four-bolt pads retain a 50 mm centre
gap, 20 mm bevels and 30 × 12 mm grooves on 120 mm pitch. Sleeves ID26/OD42 × 76 mm
span Z0.064…0.140; upward M24×120 heads end at Z0.036, carrier engagement 40 mm.

## Build sequence and clearance

69 steps cover 42 foot and 27 leg operations, all 813 instances once. Foot order
follows its assembly packet. Shin/flange bolts precede bearings/spacers, prepared
fork/spar, outboard axle and cap. Fit forefoot drive before pitch base clevis,
and thruster cradle before knee cylinders. Engines precede armor; hardware travels
with owners. Forefoot frame, each 91-piece actuator and fork/spar are prepared
groups: one translation per instance cannot show bench assembly then relocation.

Mount parents are explicit and acyclic. Approach vectors point from assembled
pose to start; offsets are 0.6–3.0 m. The audit makes 1,324,584 box comparisons,
shrinking faces 5 mm; 250 thin bounds collapse and are counted. Receiving parts
and the final 15% insertion interval are exempt. All 293 nonconvex-box exceptions
require fresh surface-intersection and connected-solid containment checks at each
flagged sample. The former upper-plate/cradle contact exception is removed:
slots/supports give 16.00 mm continuous separation over the full 3 m +Z path.

Calf/guard checks use 3,321 pitch/roll poses (±20°/±10°, 0.5° grid), measured
walls and vertex/edge samples with conservative allowances. Foot checks test
actual guard/receiver/shin triangles at 231 poses. Pitch-cap extraction gives
30.14/30.74 mm conservative separation over 300 mm lateral travel. These bounded
checks do not certify complete articulation, insertion, flexible services or tools.

## Viewer

Export flattens evaluated assembled meshes without saving the scene, one node per
instance with identity/step extras. Three.js 0.170.0, GLTFLoader, OrbitControls
and RoomEnvironment use pinned jsDelivr imports. Fractional cubic-eased scrubbing,
step ticks, previous/next, arrow keys, play/pause, Space and 0.5/1/2/4× speeds
support review. Progress shows loading; unknown IDs warn and skip, while unassigned
meshes stay assembled. The panel groups part IDs/names and quantities.

Active parts pulse ochre; parts beyond the next step default to 20% desaturated
ghosts. Armor shows, hides or ghosts at 15%. Spread is 1–3×, default 1.6×;
exploded preview restores timeline position. Front/side/back/three-quarter presets,
fit-all and follow are available. Follow frames current/assembled active bounds,
pauses during orbit and for three seconds afterwards, then preserves direction.
Neutral studio lighting and a light background support close inspection.

Browser checks use installed Google Chrome. From the repo root:

```sh
python3 -m venv models/leg-lg01/work/viewer-venv
models/leg-lg01/work/viewer-venv/bin/pip install playwright
```

No browser download is needed for the default Chrome path. First use needs internet
for pinned modules. The checker serves its own port, writes audit/captures and
closes its browser/server. Automated behaviour is separate from user acceptance.

## Triangle and file-size budget

Current [scene](output/audits/scene-full.json) / [export](output/audits/export.json); MB is decimal.
Simplify hidden internals first if needed; preserve armor edges and inventory identities.

| Measure | Actual | Budget |
| --- | ---: | ---: |
| Scene / GLB triangles | 582,230 (23.3%) | 2,500,000 |
| Foot triangles | 435,868 | 800,000 local target |
| Leg structure triangles | 105,782 | 600,000 local target |
| GLB | 22,452,080 bytes / 22.452 MB (15.0%) | 150 MB |
| Compressed Blender scene | 4,797,766 bytes / 4.798 MB | No separate limit |

## Remaining mismatches with the concept sheets

The coordinator inspected all seven final comparisons after three rounds.
Evidence: [round 1](output/compare/review-r1.md),
[round 2](output/compare/review-r2.md), [round 3](output/compare/review-r3.md).
The table records differences remaining after final repairs; user approval is separate.

| Item | Why it remains | What would fix it |
| --- | --- | --- |
| Thigh reads taller and simpler | Minor; broad faceted mass and large dark side inserts remain less pronounced; round 3 scores mostly 3 | Further facet/insert refinement within channels and envelope |
| Calf is squarer and less bulging | Side mass partly improved; no envelope growth justified | Refine facets within the envelope |
| Knee reads narrow frontally | Narrow hinge between edge-on guards; returns partly improve it; no authoritative wider knee | Revised knee-width/interface decision |
| Ankle guards expose frame and actuators frontally | Fixed 20 mm lateral walls | Revised guard/moving-core contract for thicker returns |
| Foot shells remain boxier than FA-02 | Flat Z0.700 upper plate and fixed toe roof; shoulder/segment/crown changes improved the read | Revise roof/guard contract for a closer silhouette |
| Finish is cleaner and less dense | Wear stays subtle per style guide; no invented inventory detail | Approved finish/detail revision preserving broad clean surfaces |
| Drawing errors deliberately omitted | Thigh-to-fork cylinders, wrong proportions, torso hip guards, extra foot rail, misplaced axle, extra bolts/accents and crossing ankle shaft conflict with specs | Correct drawings; retain written mechanism/counts |

Final recorded round 3 scores, before that round's repairs; no later rescore.
Scale: 1 poor, 3 recognisable but visibly different, 5 close within the contract.

| Section | Silhouette | Plate breakup | Colour placement | Detail density | Signature details |
| --- | ---: | ---: | ---: | ---: | ---: |
| Thigh | 3 | 3 | 4 | 3 | 3 |
| Knee | 3 | 4 | 4 | 3 | 4 |
| Shin and calf | 3 | 4 | 4 | 3 | 4 |
| Foot | 3 | 2 | 5 | 3 | 3 |

## Known open items

- **22 meshes retain 1,937 zero-area collapsed-bevel faces**, per the current mirror
  report. Temporary copies dissolve edges at 1 µm; source generators need repair.
- Toe/front-upper plan-chamfer contacts with rail ends and actuator/frame contacts
  remain outside local relief fixes; no whole-foot interference certification.
- Full joint motion/stop contacts, knee force/stroke sizing, flexible cable motion,
  and general tool/extraction access remain open; no fabrication-solid claim.
- Allocate neck collar/stop tongues and knee eye pins/keepers before claiming a
  complete engineering inventory or playable assembly.
- Guard-well shading still uses a 67 mm centroid mask in the shared renderer;
  the 45 mm whole-face mask used for local inspection remains to be integrated.
- Broader silhouette revisions, workshop fit, game integration, viewer finish parity
  and user acceptance remain separate work.
