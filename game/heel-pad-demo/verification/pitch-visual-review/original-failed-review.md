Historical review record. Its raw images were pruned after the repaired build passed review.

# Pitch actuator visual review — 2026-10-21

**Review complete for all 14 FA-500-P manual pages. Visual approval: FAILED.**
Reviewer: Codex. The current build remains playable, but its source geometry does
not consistently depict parts fastening together. These are open findings from a
review; this pass adds capture tooling and evidence, not a mechanical redesign.

Browse the rendered evidence · Machine-readable review
· Capture/identity manifest · Code and asset hashes

## What was inspected

The actual Godot 4.7.2 Compatibility renderer on macOS captured normal desktop
collection, targeting and placement: all 90 additions to the starting FA-510,
plus 18 parent mounting pieces. All 14 child pages have runtime HUD text/diagrams,
beginning/end views, two inspection angles, and before/preview/after images for
every installed component. Internal views include opaque, translucent service,
and explicitly labelled **exposed** inspection (only the barrel is removed).
Exposed views copy the live meshes and transforms; they are not altered source
illustrations. The full-resolution originals were later pruned after the repaired build passed review; the recorded findings and current compact evidence remain.

I inspected every child placement contact sheet, all child manual sheets and
opaque/service overviews, the working-view sheets, and the rotation sequences.
The manifest records each accepted slot, consumed identity and pose. There are
251 checkpoints and 1,598 referenced PNG captures, including supplementary parent
views. Capturing an image does not approve it.

The rendered behavior run passed **287 checks**; a separate ordinary headless run
passed **285 checks**. The two additional checks exercise continuous R-drag at
preparation C and on the foot, comparing the live actuator geometry before the
next physics tick. Collection, identity conservation, prerequisites, mounting and
nested undo passed. A dummy-renderer invocation was rejected with exit code 2.
These results do not validate receiving holes, contact surfaces or tool access.

## Page-by-page findings

All page component lists use IDs and match their installation slots. The 13 build
pages cover 90 distinct additions; FA-510 is the initial root. Page 14 correctly
shows assembly progress without requesting new supplies. FA-511 appears once.

| Page | Required new pieces | Visual finding and disposition |
| --- | --- | --- |
| **1 — Motor** | FA-513 ×1; W-12 ×4; H-12040 ×4 | **Fail.** All four washers land on a closed motor end face; there are no receiving holes or a clear fastening interface to the housing. Heads remain visible, but the diagram is too small to explain their positions. Placements, manual. |
| **2 — Reduction drive** | FA-514 ×1; W-12 ×4; H-12040 ×4 | **Fail.** The four washers and screw heads disappear inside the already fitted motor at the gearbox joint. The green preview looks available even though the final fastening surfaces are buried. The manual omits the motor receiver. Placements, manual. |
| **3 — Coupling & bearing** | FA-515 ×1; FA-522 ×1 | **Fail.** Both pieces are coaxial, but the coupling sits on a closed gearbox face with no visible output shaft, and the bearing lacks an illustrated housing seat. FA-515 is a plain tube without clamp features. The diagram omits the gearbox. Placements. |
| **4 — Lead screw** | FA-516 ×1; W-12 ×2; H-12030 ×2 | **Fail.** No radial receiving holes or clamp split. Both washers overlap and both screw heads intersect. The manual omits the already fitted coupling and bearing. Source inspection additionally confirms that the screw does not extend into the coupling. Before/after, second screw, manual. |
| **5 — Retain the shaft** | FA-523 ×1; FA-524 half 1 ×1 and half 2 ×1; W-12 ×4; H-12040 ×2; H-12030 ×2 | **Fail.** Retainer and collar receiving holes are absent. Collar geometry overlaps the coupling/support stack. H-12030__025 points outward, leaving its threaded shaft in free space. Retainer washer clearance around FA-516 also needs correction. The diagram omits the shaft/bearing being retained. Collar installation, retainer, reversed screw. |
| **6 — Travelling nut** | FA-517 ×1 | **Fit acceptable at the represented game scale; diagram fails.** The nut is centered on the lead screw with no obvious external inversion or offset. The manual shows an isolated nut instead of the screw it fits over. This is not a thread-engagement simulation. Placement, manual. |
| **7 — Output rod** | FA-518 ×1; W-12 ×2; H-12040 ×2 | **Fail.** The rod and nut meet coaxially, but both washers and screw heads are completely buried in the rod wall. There are no access pockets or visible fastening holes. The diagram omits the travelling nut. Placements, manual. |
| **8 — Guide key** | FA-521 ×1; W-12 ×2; H-12030 ×2 | **Fail.** There is no matching longitudinal slot in FA-518. The narrow key has no screw holes or housing mounting lands; the lower screw protrudes past the key without a defined housing receiver. The upper connection intersects the moving rod/nut region. The wording should explain a housing-fixed guide engaging the rod slot, consistent with the construction design. Key, fasteners, manual. |
| **9 — End sensors** | FA-528 sensor 1 ×1 and sensor 2 ×1; FA-530 ×1; W-12 ×2; H-12030 ×2 | **Fail.** Both sensor screws run through the blue sensor feature rather than a separate mounting hole. The connector has no corresponding barrel opening. Sensor/connector positions are tiny and unlabelled in the diagram. Sensor screws, connector, manual. |
| **10 — Front guide & seals** | FA-519 ×1; FA-520 ×1; FA-529 gasket 1 ×1 and gasket 2 ×1 | **Needs revision with page 11.** Rings are coaxial and the bushing/wiper order is coherent. Their receiving seats are not explained, and the subsequent cap does not have a recess accommodating the bushing. The two gasket locations and front-guide stack need separate close-ups. Placements, gaskets, manual. |
| **11 — Close the housing** | FA-511 ×1; FA-512 ×1; W-12 ×8; H-12050 ×8 | **Fail.** All eight washer sites are on unbored cap faces; barrel bosses also lack the mating holes. The front cap overlaps the bushing because its central bore has no bearing recess. Cap/gasket seating needs explicit geometry. Closure also precedes the inaccessible base-eye fastening in page 12. The front/rear counts are correct. Cap fit, rear fasteners, front fasteners. |
| **12 — Base eye** | FA-525 base ×1; FA-526 base ×1; FA-527 base ×1; W-12 ×2; H-12040 ×2 | **Fail.** The eye's integral block obstructs the bearing/pin opening; fitted screw tips project into that opening. Washer/head locations are inside the already fitted rear cap. The retaining ring has no clear groove/retaining feature. The diagram shows an edge-on lump and omits the rear cap. Eye/bearing, fasteners, manual. |
| **13 — Rod eye** | FA-525 rod ×1; FA-526 rod ×1; FA-527 rod ×1; W-12 ×2; H-12040 ×2 | **Fail.** The eye block and screw tips obstruct this pin opening too. Heads/washers are buried within the output rod. The retaining-ring connection is not represented. The diagram omits the output rod and does not expose the fitting direction. Eye/bearing, fasteners, manual. |
| **14 — Ready to install** | None | **Status/navigation pass; completed build not approved.** The page correctly reports 91/91 and directs the player to the parent manual. The assembled silhouette is coherent, but the closed barrel hides the unresolved internal defects. Manual, opaque/service result. |

## Why the earlier checks missed this

The earlier orientation fixes corrected the pairing of a slot's source mesh and
pose. They successfully prevent a compatible inventory screw with a differently
baked orientation from rendering incorrectly at its destination. They cannot
identify an incorrect destination or a missing hole in that same source.

The rendered per-step review had not been executed. Calling source agreement a
sufficient review was the gap; it was not caused by the preference for headless
routine tests. This run uses a real renderer separately from those tests.

The source confirms the visible problems:

- `models/foot-fa01/src/actuator_parts.py` creates the coupling as a simple tube,
  then emits two radial fasteners at local Y = −6 and +6 mm. The washers have
  24 mm outer diameter and the heads 18 mm diameter, so 12 mm center spacing
  necessarily overlaps both. The coupling ends at local Z = 214 mm while the
  lead-screw body starts at 215 mm; there is no connecting journal.
- The same source gives both collar screws direction `(0,-1,0)` even though they
  are on opposite sides. That explains the outward-pointing H-12030__025.
- Most actuator fastening features are emitted without bores. In
  `geometry.py`, passing `owner=` to `hardware()` records ownership metadata;
  it **does not cut a hole**. Explicit `bore()` calls exist for the clevises,
  but not these internal fastener interfaces.
- `hud.gd` includes the current step and root barrel in component diagrams.
  Previous receivers are absent unless `context_sources` is authored; the
  actuator pages do not provide that context. The fixed whole-barrel framing
  and uniform highlighted material make small connections indistinguishable.

## Parent installation observations

The same run also exercised all three pitch-related foot pages, including all
18 parent components. Their lists and prepared-child count are correct. The
supplementary placement sheets were inspected: the base clevis has hardware
intruding into its pin region, the keeper plates lack visible screw holes, and
the rod-end keeper/fastener is obscured by surrounding bracket geometry. The
parent seat diagram renders the child's barrel without its complete eyes/rod,
so it does not explain the two receiving connections.

These parent captures are **not an accepted visual baseline**. Their isolated
inspection omits the receiving FA-200/FA-201 frame context, and the generic HUD
camera still points at the preparation area on the two clevis pages. That needs
receiver-specific framing during the parent repair/review. The child-manual
review above has complete page and placement coverage.

Continuous station and mounted rotation preserved attachment poses throughout
both drags. Preparation sequence · Mounted sequence.
The mounted working view is partly occluded by the foot until it rotates; numerical
geometry checks cover every drag sample rather than inferring hidden behavior
from the screenshots. This pass does not reapprove the separate pad manuals.

## Repair order and acceptance

1. **Define the actual interfaces before changing recipes.** For every fastening
   group record the receiving part, hole/seat, insertion axis, washer bearing face,
   head clearance and access order. Keep comfortable assisted placement. The game
   needs visible, consistent connections, not precision threading controls.
2. **Repair the actuator source geometry as a connected build.** Start with the
   drive/coupling/shaft/retainer stack (pages 1–5), then the nut/rod/guide/sensors
   (6–9), then guide/caps/eyes (10–13) and parent retention. Fix holes and mounting
   lands together with axes, spacings, shaft engagement and closure access.
   Preserve inventory IDs where possible; do not add arbitrary extra parts to
   hide missing integral features. Regenerate the GLB and affected part images.
3. **Author diagrams around each connection.** Show already fitted receivers as
   context without putting them in the supplies list. Use close-up framing,
   separate end views where necessary, and insertion offsets consistent with the
   actual axis. The workpiece and manual should visibly explain the same joint.
4. **Repeat this capture and review.** Recheck every changed interface and its
   later closures/parent mounting. Keep this failed baseline. Approve a page only
   when a visible receiver exists, hardware seats without overlaps or buried
   heads, access order works, and the normal-size diagram explains the fit.

No geometry, inventory allocation or instruction text was changed during this
review. Repairs remain open; successful gameplay checks are not a visual pass.
