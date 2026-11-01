# LG-01-3D-01 open questions

Questions raised while building the leg model. Each records the default chosen
so work could continue; the user can overturn any of them.

| # | Phase | Question | Default chosen |
| --- | --- | --- | --- |
| P2-01 | 2 | How should duplicate CSV part IDs retain distinct physical roles? | Preserve exact CSV `name` as `part_name`; namespace integer instance numbers by that name, or provide a stable explicit suffix such as `lug.03`. Never merge the rows by ID alone. |
| P2-02 | 2 | Should every integral helper be a fabrication-grade union? | Use independent closed shells within one manufactured-module mesh, as in FA-01. Audit closure and outward normals per shell; reserve Boolean unions and fabrication tolerances for a future engineering requirement. |
| P2-03 | 2 | How should subtle wear survive glTF without procedural shader dependencies? | Use 0–6% darker per-corner color on facets, exported as COLOR_0 with the current Mix Color node; keep Principled roughness constant. No normal maps. |
| P2-04 | 2 | Should AgX's lighter red stencils and the exposed test bell's large bronze area change the approved palette? | Keep exact approved sRGB colors and the separate bronze lining. Record the lighting difference; judge the final bell's visible bronze area inside phase 4's calf shroud. Stop after three inspected board renders. |
| P1-01 | 1 | How should the larger foot keep its original sections and mating joints? | Use rounded plan positions and pinned envelope X±730/Y−900…2460; retain all Z values, 180×240 rails, ankle/shin interfaces and hardware. Explicit per-part limits and exceptions are in the FA-02 revision of dimensions.md. |
| P1-02 | 1 | Can the forefoot hinge move while all actuator eyes remain globally fixed? | No: an unchanged fixed eye with H at Y1340 demands 751.66 mm at neutral, beyond 640. Translate both forefoot eyes +140Y, preserving its entire length sweep; pitch/roll eyes stay fixed and bracket arms reach the wider frame. |
| P1-03 | 1 | Should the transverse forefoot bearing stack scale with rail spacing? | Preserve the 1160 mm axle journal and existing lug/bushing/washer X stack; extend integral beam/support arms to widened rails. No new inventory pieces. |
| P1-04 | 1 | Should simply scaled carrier bolts stay near pad threaded holes? | Offset carrier Y centres to −670/170/1040 rear and 1640/2280 forefoot at X±560. Minimum pad/carrier axis spacing 69.46 mm; preserve bolt sizes/counts and verify solid bores later. |
| P1-05 | 1 | How should invalid FA-01 location suffixes and mirrored pieces become valid IDs? | Use the explicit FA-02 mapping table: rail A/B ledge-orientation variants exchange on mirroring; true foot-handed cradle/upper plate/guards/main lead use -L (future -R); nut plates, clevises and stops use A…F variants. Only one suffix. |
| P1-06 | 1 | Which actuator internals can share a part type before solids exist? | Reserve A/B/C packaging variants for FA-510…523; distinguish collar halves, eyes and gaskets by function; share sensors/connectors and same-sized roll/forefoot eye bearings, rings and pins. All family totals remain unchanged. |
| P1-07 | 1 | Must the controller and trim-to-fit harnesses also grow? | Keep box placement and stated cut-length allowances; extend integral frame ears and review actual routes, particularly the translated forefoot drive, in phase 3. No additional clips or connectors. |
| P1-08 | 1 | Does the JPEG-only instruction authorize deleting original FA-01 PNG references? | Interpret it as no new FA-02 PNGs in the repo; preserve seven existing FA-01 PNGs under the explicit historical-output protection. FA-02 outputs and retained drafts are quality 92 JPEG. |
| P1-09 | 1 | Which structural sheet should win when the final correction improves rails but corrupts an ID? | Retain v2 as fa02-structure.jpg because its labels are correct; v3 incorrectly calls the axle FA-105. Two-correction limit reached. Register remaining extra-rail, hinge-axis and leader errors; dimensions/CSV govern modelling. |
| P1-10 | 1 | Does the newly assembled foot adopt image-added guard ochre, extra bolt wells or small hatches as physical parts? | No new objects: preserve five shells with four captive bolts each and the documented toe accent band. Record those image additions as drawing drift; use the written shell owners/removal axes. |
| P3A-01 | 3 | How do wider thigh/calf shells coexist with the old X±0.80 support contacts and Y−1.45 workshop spine? | Preserve exposed structural bearing faces at X±0.800 (fork Z5.980–6.220, shin Z2.690–2.910); Phase 4 needs real openings. Use the approved larger calf envelope; revise workshop fixtures later, outside this model task. |
| P3A-02 | 3 | What knee drive geometry and travel are specified? | Neutral eyes (±0.460,−0.460,6.400) to (±0.440,−0.500,4.300), span2.100476, retracted1.650, extension0.450476, kit stroke1.208. This corrects the concept drawing; joint travel/forces/full swept clearance remain unverified. |
| P3A-03 | 3 | Where are neck collar/tongues and knee-cylinder eye pins allocated? | They have no current leg CSV rows. Prepare the neck key flat and actual bracket/eye bores; do not invent separately registered inventory. Coordinator should resolve their later inventory/retention treatment. |
| P3A-04 | 3 | How should calf engines fit the revised rear envelope? | Two seats at (0,−0.720,3.980)/(0,−0.720,2.930), 12° rear/down, Ø0.790 mouths; rear lip Y−1.48683 leaves113 mm to the shroud's −1.600 limit. |
| P3B-01 | 3 | How should 745 foot objects fit the triangle budget? | Keep every physical instance; omit hidden fastener helices, use 12-sided shanks/socket heads, retain the three lead-screw helices and real bores/chamfers. No merged inventory or proxy parts. |
| P3B-02 | 3 | Which complete foot rows belong to Phase 4? | Defer 14 rows / 143 objects: all five shells, six pads, 24 sleeves, 20 captive collars, plus the pad and armor bolt/washer rows. Build 602 objects now. Fit integral armor receivers with the final shells; carrier pad-hole axes are already present. |
| P3B-03 | 3 | How should the enlarged crossmembers meet the rails without losing their X±650 span? | Use upper half-lap ends, continuous lower rail walls and inward ledge webs outside the nut-plate keeper ears. Preserve all tabled M36 axes and Z430 washer seats; recess the taller hinge beam around its heads. |
| P3B-04 | 3 | How should Blender 5 handle coincident cuts in the inherited multi-shell generators? | Machine closed integral shells separately, skip remote no-op cuts and use 0.05 mm bore clearance. Relieve the hinge beam front face 0.5 mm to Y1544.5, retaining rear Y1425; this avoids a tangent n-gon at the Y1545 bolt row within the 10 mm model tolerance. |
| P3B-05 | 3 | Does neutral geometry validation establish full mechanism and wiring clearance? | No. Preserve the repaired pitch branch and original roll/forefoot packaging; measure neutral eye/pin/clevis coincidence and the exact shin plug. Full stop-contact sweeps, flexible harness bend/slack/contact review and tool/extraction paths remain future work. Harness lengths remain trim-to-fit allowances. |


## Viewer decisions (P7A)

| # | Phase | Question | Default chosen |
| --- | --- | --- | --- |
| P7A-01 | 7 | How can viewer work proceed before armor and the real build sequence arrive? | Export the current 651-part saved scene and generate 40 clearly labeled development steps from the manifest. These are display groups, not verified assembly dependencies or insertion paths. The placeholder generator refuses to overwrite a real sequence. Phase 5 replaces the JSON without viewer code changes. |
| P7A-02 | 7 | Which parts count as armor, and what does the current ghost capture establish? | The real sequence's `parts[id].armor` is authoritative. Placeholder classification includes armor/accent panels and service guards/covers; the current structural snapshot contains only one matching service guard. 15% opacity and visibility behavior are tested, but full armor appearance awaits new captures after Phase 4/5. |
| P7A-03 | 7 | Should playback transforms or three.js's cleaned names alter source identity? | No source blend changes. Export evaluated, unparented assembled nodes named exactly by instance ID; recover IDs from GLB associations/extras in the browser and convert approach vectors `(x,y,z)` to `(x,z,-y)`. Unknown IDs warn/skip; unassigned nodes remain assembled. |
| P7A-04 | 7 | Should the viewer work offline and how should slow local-server startup behave? | Keep the required pinned jsDelivr import map; first use needs internet. The launcher waits for HTTP readiness before opening, allowing 90 s because this Mac's reverse DNS delayed Python HTTPServer startup. Closing its Terminal window or Ctrl-C stops the server; closing only the browser tab does not. |

## Leg armor decisions (P4A)

| # | Phase | Question | Default chosen |
| --- | --- | --- | --- |
| P4A-01 | 4 | How can armor top be literally below the carrier roots at Z7.25–7.60 while using the requested Z8.0–8.3 top? | Use Z8.23 for the main upper silhouette, with real top-open channels down to Z7.25 and an open rear service channel. Check neutral R80 cartridge corridors; full articulated hip solid clearance remains open. |
| P4A-02 | 4 | Should thigh plates stop above Z6.3 to expose the fork pads? | That made the thigh too short in round 1. Extend front/sides to Z5.75/5.77, above the knee mechanism, and retain genuine side openings around Z6.1 pads. All pad-access rays pass. |
| P4A-03 | 4 | Which lower-calf constraint replaces the old 900×900 first-450 rule? | Lowest 300 mm measures 1.06335 wide; armor begins Z1.65. Use actual FA-02 |X|0.710 inner guard walls. The 3,321-pose vertex/edge sweep has 43.45 mm sampled clearance, 9.93 mm after conservative sampling allowances; full swept-facet solids remain open. |
| P4A-04 | 4 | How should decals and captive plate features affect inventory? | Join decals, bolt wells/heads, local accent patches and mounting standoffs into their owning plate mesh. Preserve separate LG-460 hatches and LG-470 rails exactly as the CSV specifies; no extra stock rows. |
| P4A-05 | 4 | How should mirroring handle inherited collapsed bevel geometry without changing read-only P3 sources? | Dissolve coincident edges at 1 micrometre on the temporary reflected copy, then independently check normals, each closed-shell volume, face degeneracy and bounds. Report source degeneracy and cleanup counts; never save the mirrored copy. |
| P4A-06 | 4 | Does passing the leg scope complete the combined Phase 4 gate? | No. P4B's emptied DEFERRED_ROWS currently breaks the internal-only generator count assertion, and its interim foot geometry checks still fail. Preserve strict default audits, label partial reports leg-only, and leave the foot-owned repair/coordinator rerun explicit. |


## FA-02 foot armor decisions (P4B)

| # | Phase | Question | Default chosen / status |
| --- | --- | --- | --- |
| P4B-01 | 4 | How can the internal-only count assertion coexist with an empty final `DEFERRED_ROWS`? | Prepared the one-line `foot_fa02.py` import of `ARMOR_ROWS` shown in MODELING_NOTES. Tested it in memory through a fresh complete build; left the protected source unchanged pending the requested scope clarification. This is the sole normal-build acceptance blocker. |
| P4B-02 | 4 | Should guard crowns follow the narrower illustration or the four specified bolt axes? | Preserve the written axes, 20 mm walls and Z1600 tops. Use broader faceted crowns with no roof. Actual guards, local lands/tabs and receiver arms clear the actual neighboring shin/calf at 231 sampled pitch/roll poses. |
| P4B-03 | 4 | Where should shell receivers live without adding bracket inventory or changing internal generator files? | Add integral drilled bosses, braces and open locator sockets to the two rear rails, two forefoot rails and fixed cradle from `foot_fa02_armor.py`; the exact additions are recorded in MODELING_NOTES. |
| P4B-04 | 4 | How should captive retention and tread details be represented? | Separate 4 mm collars seated in dedicated back counterbores, nominal shafts without hidden helical threads, separate washers/sleeves, and real underside grooves interrupted around solid bolt lands. No decorative bolts. |
| P4B-05 | 4 | Should exploded display positions be mistaken for assembly removal paths? | No. Retain documented per-object removal vectors in the neutral model; turn and lay out all six pads in a foreground row only for the labeled exploded inspection. Stop at three visual fix rounds. |

## Phase 6 round 1 — leg

| # | Phase | Question | Default chosen / status |
| --- | --- | --- | --- |
| P6F1-LEG-01 | 6 | Which appearance-driven thruster numbers replace the buried-nozzle layout? | Ø780 mouths, 12° rear/down, lip centres (0,−1.550,3.880)/(0,−1.550,2.730); seats (0,−0.865296,4.025538)/(0,−0.865296,2.875538). Preserve machined seat diameters/depths and Y≥−1.64. Update only corresponding chosen expectations in verify_interfaces.py. |
| P6F1-LEG-02 | 6 | How should close-fitting armor preserve removal and hip-cylinder channels? | Fold returns into their existing plates, retain nominal 35 mm dark backed side seams, keep the front/front/rear channel approaches and the open rear knee. No added inventory or torso-owned hip guards. Full articulated hip/armor solid sweeps remain open. |
| P6F1-LEG-03 | 6 | Should calf depth include the exposed nozzle geometry? | Existing verify_envelopes.py measures armor/service geometry only, but the 2.24 m target includes the rear thruster enclosure. Requested permission for the narrow depth-only LG-450 inclusion because that audit is outside the assigned source ownership. Prepared/tested `work/p6f1-leg/include-nozzles-in-depth.patch`: candidate exits 0, measuring 2.231085 m; unchanged audit exits 1, measuring armor alone at 2.000 m. Still pending authorization. Width, lower taper and all safety/clearance bounds stay unchanged. |
| P6F1-LEG-04 | 6 | How can the broader front inserts coexist with the inner/front channel? | Shift their centres to X±0.69 from the suggested ±0.60; preserve 150 × 850 mm faces. Cut intersecting detail solids individually before joining, keeping all meshes closed and the channel open. |
| P6F1-LEG-05 | 6 | Does this pass settle nozzle lining tone and renderer sampling? | No: R2 remains separate. Scratch-only front tone probe moves from LG-210/X−0.76 to the LG-200 folded corner/X−0.82 because the old ray misses the reshaped part. Shared renderer remains owned by its parallel agent. |


## Phase 6 round 1 — foot

| # | Phase | Question | Default chosen / status |
| --- | --- | --- | --- |
| P6F1-01 | 6 | Should visible mechanics be recovered by narrowing the guard to the drawing? | No. Preserve the four specified M12 axes, full crown and Z1600 top; add a 400×360 mm window at Y0/Z1000 with 60 mm chamfers. Both pitch caps are visible through the installed assembly. Resolved. |
| P6F1-02 | 6 | Are the triangular corner holes required articulation openings? | No. Close roof/side joins within each of the existing toe, upper and heel shells with a continuous 20 mm folded skin. Preserve the rear-open X±590 notch and Y1210…1500 hinge channel. Resolved. |
| P6F1-03 | 6 | How can broad perimeter facets and wells remain readable inside a 20 mm guard wall? | Use 80 mm facets with 6 mm relief and 130 mm octagonal depressions at the existing seats, retaining all screw/receiver axes. Machine the recesses before adding intersecting lands and use planar guard shading. Confirmed in the second/final render round; no receiver or foot_fa02.py edits needed. |
| P6F1-04 | 6 | Do the scratch passes approve the concurrently changing combined leg or the concept's extra panels/accents? | No. Retain five shells, toe-only ochre and every written constraint in review-r1. All requested commands pass on the captured scratch source snapshot; coordinator integration and the separate rendering work remain. No F1–F3 major is open in the inspected final views. |


## Build sequence decisions (P5)

| # | Phase | Question | Default chosen / status |
| --- | --- | --- | --- |
| P5-01 | 5 | Does spar/fork before shin respect the mount dependencies? | No. Foot → shin with foot-owned M36 flange bolts → bearings/spacers → bolted fork/spar unit → outboard axle and cap. The unit's internal fork/spar relationship is preserved in the mount graph. |
| P5-02 | 5 | How can one translation per instance show bench preparation and later installation? | Keep the forefoot frame, each 91-piece actuator and the fork/spar as prepared groups, retaining every instance and internal parent. Pitch/roll bushings travel with their receiving ring/adapter; exposed pins remain axial steps. Full bench choreography needs a richer viewer schema. |
| P5-03 | 5 | Which independent order changes preserve approach access? | Fit the forefoot drive and its outboard pins before the pitch base clevis. Fit the thruster cradle before the knee cylinders and use side approaches for those brackets/cartridges; keep engine installation after services and before armor. |
| P5-04 | 5 | Should filled-in bounding boxes waive all collisions around hollow frames? | No unconditional family waiver. Recheck evaluated mesh surfaces and connected-solid containment at every flagged sample; retain all 291 mesh-proven pair records. This is sampled geometry evidence, not a continuous/tool/flexible-cable clearance claim. |
| P5-05 | 5 | Can the upper plate's low skirt/locators follow the required straight upward removal path past the cradle receivers? | The audited Phase 4 snapshot still contacts the cradle at 80% of a 3 m descent. Preserve a single exact-pair/sample exception, separate from box false positives. Receiver revision or a tipped/multiple-segment path remains open; P5 does not modify generators or claim that path is clear. |
| P5-06 | 5 | Which scene and viewer export were verified while geometry repairs were concurrent? | Audit the complete 813-part scratch snapshot, retain it in work/p5, publish the production steps and refresh the stale 651-part viewer GLB through the existing exporter. Leave the production blend untouched; coordinator reruns sequence/audit/export on the final repaired scene. |


## Viewer decisions (P7B)

| # | Phase | Question | Decision |
| --- | --- | --- | --- |
| P7B-01 | 7 | How should pending ghosts interact with armor ghosting and spread? | Pending parts beyond current panel step + 1 use 20% desaturated ghosts at their scaled start positions. Armor ghosting wins at 15%; hidden armor stays hidden. Default spread is 1.6× with a 1–3× control; authored offsets and sequence files are unchanged. |
| P7B-02 | 7 | How can default follow coexist with manual camera control? | Frame current plus assembled active-part bounds; suspend during manual orbit/pan/zoom and for 3 s after release, then resume at that viewing direction. Fit all turns follow off; turning follow off returns to whole-layout framing. |
| P7B-03 | 7 | Which section totals should the panel display? | Use the production JSON's actual 42 foot / 27 leg steps. Step 35 reads Foot 35/42 · Leg 0/27; the task's 44/25 values were illustrative. |
| P7B-04 | 7 | Does the polish require extra outline geometry or revised offsets? | The larger follow view and sustained emissive pulse make the active board/sockets readable without extra shells. Three inspected rounds show a separated kit at 1.6×; no offset change is proposed. Coordinator/user acceptance of the interaction remains open. |

## Phase 6 round 2 — leg

| # | Phase | Question | Default chosen / status |
| --- | --- | --- | --- |
| P6F2-LEG-01 | 6 | How can the shroud enclose the cradle without moving engine interfaces? | Flatten only the upper fabricated ring crown to Z4.500. Use shroud back-skin stations Y−1.34/Z4.15, −1.20/Z4.40 and −1.14/Z4.60, with 60 mm outward skin. Neutral crown/brow clearance lower bound 67.85 mm; cylinder/shroud ≥221.80 mm and cylinder/side-shell ≥116.51 mm. Seats, mouths and interface expectations remain unchanged. Full articulated clearance remains separate. |
| P6F2-LEG-02 | 6 | Should the old central shin peak become another drawn seam? | No. Cut a real saddle at X±0.28/Z4.36 with shoulders at X±0.50…0.60/Z4.60 and 100 mm upper facets. Move only the armor-side upper stand-off endpoint to Z4.30; its structural land remains Z4.44. Preserve bracket access and the open knee. Resolved in the final front/three-quarter views. |
| P6F2-LEG-03 | 6 | Does the requested knee readability fix establish a wider joint? | No authoritative replacement width is selected. Add 110 mm frontal returns within the existing |X|0.67 envelope and retain the axle, bearings and stepped caps. The requested local return geometry is done; any broader knee-width revision stays open. |
| P6F2-LEG-04 | 6 | How should grooves, folds and nozzle collars avoid new surface defects? | Explicit triangles at every fold/profile station; 25 × 15 mm straight groove cuts; geometric corner normals after bending. Complete the 500 × 950 mm thigh outline and 650 × 300 mm shin frame. Put lower shin bolts at X±0.25/Z1.97 inside the frame. Two 50 mm collars per bell have tapered insides matching its exterior, preserving the bronze lining and Ø780 mouths. No new inventory. |
| P6F2-LEG-05 | 6 | What do the final scratch checks and two render rounds approve? | All five required commands and 48 focused geometry checks pass on the retained 813-part snapshot. The assigned C5/C6 majors and seven minors are implemented and inspected within the recorded constraints. No fresh user acceptance, full motion proof, R5–R9 tonal approval or integrated parallel foot/renderer verification is implied. See MODELING_NOTES “Phase 6 round 2 — leg” and work/p6f2-leg/evidence.json. |

## Phase 6 round 2 — foot

| # | Phase | Question | Default chosen / status |
| --- | --- | --- | --- |
| P6F2-FOOT-01 | 6 | Can FA-401-L keep a straight +Z path without moving its bolts or tabs? | Yes. Added skirt/roof clearance slots and rerouted the integral FA-103-L guard supports below the roof, with a Z580 backbone above the earlier forefoot-pin corridor. The full 3 m continuous bound is 16.00 mm. Removed only `upper-plate-locator-lift`; sequence now passes without an actual-contact waiver. Supersedes P5-05. No `foot_fa02.py` changes. |
| P6F2-FOOT-02 | 6 | How should the 30 mm lower inset meet the existing corners? | Use a 100 mm-high lateral facet and taper the inset out over 80 mm before each plan chamfer. Preserve 20 mm skin, roof/bolt datums, notch, hinge channel and tabs. New facet/frame separation is at least 30.44 mm. Resolved within the changed lateral surfaces. |
| P6F2-FOOT-03 | 6 | Should F5's thin guard edges be bulked up now? | No. Leave the current 20 mm walls and Z1600 crowns intact. Open: a 60–80 mm front-facing return needs a revised guard/moving-core clearance contract. |
| P6F2-FOOT-04 | 6 | Do these passes certify all existing shell/rail contacts? | No. Read-only checks of the original scene confirm rail-end contacts at the toe and front upper-plate plan chamfers; retain those unchanged corners in this scoped repair and record a separate rail/chamfer follow-up. The new F4 facets/tapers and complete upper-plate/cradle path are independently checked. See the round-2 foot notes and `work/p6f2-foot/corner-baseline.log`. |
