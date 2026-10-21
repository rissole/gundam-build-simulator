# Pitch actuator visual review — passed

Reviewed by Codex on 2026-10-21 using Godot 4.7.2-stable (official) / gl_compatibility.

**Approved scope:** all 14 FA-500-P child pages and the three parent mounting pages. Every placement sheet, normal HUD/working view, both inspection angles, opaque/service overviews and both continuous rotation sequences was inspected. No remaining visual finding blocks this assisted desktop build/install milestone.

[Open the rendered gallery](index.html). [Machine-readable page decisions](review.json), [capture records and consumed identities](captures.json), [input fingerprints](fingerprints.json), [inspected image hashes](inspected-images.json), and [evidence audit](evidence-audit.json) accompany this report.

## Per-page results

| Page | Result | Findings |
| --- | --- | --- |
| [foot-04 — Base clevis](index.html#foot-04) | Pass | Base clevis seats on the FA-103 outrigger. Both M24 washer/bolt stacks align with full-depth bores through the plate and integral braces. The eye relief, pin passage and outboard keeper boss remain clear. |
| [foot-05 — Ring clevis](index.html#foot-05) | Pass | Rod clevis seats on the FA-200 upper land. Both M24 bolts align with bracket and frame holes, with accessible heads. The bridge leaves the eye and pin approaches clear. |
| [foot-06 — Seat & pin actuator](index.html#foot-06) | Pass | Full 91-piece mounting preview matches the seated actuator. Both eyes fit between clevis ears. Pins pass through the aligned bearing/clevis bores; keeper plates retain the outboard heads and have seated washer/screw stacks. Mounted rotation and nested undo retain child geometry and identities. |
| [pitch-01 — Motor](index.html#pitch-01) | Pass | Four motor washers seat on the rear flange. Axial screws pass through distinct bores into the housing seat; upper-flange cutouts expose their heads. Housing cap bosses clear the flange scallops. |
| [pitch-02 — Reduction drive](index.html#pitch-02) | Pass | Gearbox flange contacts the motor. Four screws and washers use the upper bolt circle with exposed heads and distinct motor receiving posts; motor fastening precedes closure by this flange. |
| [pitch-03 — Coupling & bearing](index.html#pitch-03) | Pass | Coupling accepts the gearbox journal. Thrust bearing sits on the integral housing shoulder with a clear central passage. Two labelled HUD panels show the separate connections. |
| [pitch-04 — Lead screw](index.html#pitch-04) | Pass | Lead-screw journal enters the coupling and bearing. Two separated transverse clamp holes receive two washers and screws on flat ears; heads remain accessible and neither screw crosses the shaft. |
| [pitch-05 — Retain the shaft](index.html#pitch-05) | Pass | Retainer contacts the bearing and bolts into housing bosses. Collar halves meet around the smooth journal; their transverse fasteners clear the retainer heads and begin below the lead-screw thread. |
| [pitch-06 — Travelling nut](index.html#pitch-06) | Pass | Travelling nut is concentric with the lead screw; its rod receiving holes remain exposed. This page requests only FA-517. |
| [pitch-07 — Output rod](index.html#pitch-07) | Pass | Rod flange contacts the nut. Two head-access pockets expose washers and axial screw heads; screws align with the nut receiving posts. The rod end remains small enough for later guide and cap placement. |
| [pitch-08 — Guide key](index.html#pitch-08) | Pass | Guide tongue engages the longitudinal rod slot. Offset ears and screws attach to fixed housing lands; screw heads clear the moving rod. Separate HUD panels show slot engagement and fastening. |
| [pitch-09 — End sensors](index.html#pitch-09) | Pass | Both probes occupy housing openings. Separate mounting ears have real bores and body lands. Mounting screws are offset from cap-bolt paths; the rear land stays above the rear closure face. Connector flange seats at its separate port. |
| [pitch-10 — Front guide & seals](index.html#pitch-10) | Pass | Bushing seats at the housing shoulder around the rod. Wiper occupies the front-cap recess position. Face gaskets match the housing ends; rear reliefs clear the eye receiver bosses. |
| [pitch-11 — Close the housing](index.html#pitch-11) | Pass | Exactly one FA-511 and one FA-512 close the two ends. All eight washer/screw stacks align with cap bores and housing bosses. Rear screw tips, sensor fastener and closure land have separate space; the front guide and wiper remain concentric. |
| [pitch-12 — Base eye](index.html#pitch-12) | Pass | Base eye flange contacts the rear cap and clears the already fitted cap heads. Its two fasteners enter separate cap receiver bosses. Bearing seats against the far shoulder and the near clip occupies its groove; the pin opening remains clear. |
| [pitch-13 — Rod eye](index.html#pitch-13) | Pass | Rod eye attaches at the rod end with two exposed fastening scallops. Bearing and clip fit their seat and groove. Both mounting screw heads clear the bearing and the pin passage stays open. |
| [pitch-14 — Ready to install](index.html#pitch-14) | Pass | Prepared view matches the completed 91-piece actuator. The HUD shows assembly status and navigation with no new component shopping list. Preparation rotation retains all fitted geometry. |

## Verification and model reuse

- 251 rendered checkpoints; 1,598 PNG captures; all 112 page sheets plus 23 additional working/rotation/service images inspected.
- 289 rendered behavior checks; 286 headless pitch interaction checks; 114 model checks; 69 imported-triangle clearance checks; 65 two-pad interaction checks; 44 pocket/manual workshop checks, including the 31-view runtime manual audit.
- The 69 clearance checks fail 40 times against the original model. The retained sensor negative control also reproduces the crossed sensor/cap fasteners. These checks supplement the images; neither capture generation nor source-pose agreement alone grants approval.
- 90 child additions and 18 parent additions consume 108 distinct stocked identities. The barrel is the existing child root; the prepared mount transfers those 91 existing pieces. With 26 pad pieces the scenario still has 135 physical identities. Exactly one FA-511 is installed.
- The pitch exporter replaces 109 pitch/mounting instances plus the two receiving frames, FA-103 and FA-200. The [reuse audit](pitch-reuse-audit.json) proves all 634 unrelated node records and original mesh/material/accessor data are preserved, including 55,666,432 original binary bytes. Shared hardware templates and the roll/forefoot actuators remain unchanged.
- A final replay corrected source-tree fingerprint traversal. All 1,717 captured/derived images compared byte-for-byte with the inspected run; the corrected replay records all 89 current input fingerprints.

Verified [game GLB](../../assets/foot-fa01.glb) SHA-256: `77bb4b6d92c1967e86c1f6e424cebe4d1651159fe550f32be3764e94eb42cc5e`.

## Retained evidence and scope

The [original failed review findings](original-failed-review.md) and [sensor-conflict negative control](sensor-conflict-negative-control.json) remain available. This compact archive retains every image inspected for approval: 112 page sheets, seven working/rotation sheets and 16 full-resolution close-ups. Other raw captures were pruned after review; their original hashes and capture records remain. Preserve this accepted baseline before future geometry, pose, parenting or framing changes.

This review accepts visible fit, step instructions and assisted game behavior. The service view permits internal work without simulating manufacturing insertion, threading or torque. Strength, actuator motion and external wiring are outside this milestone. The remaining default-workshop/pad visual review and human pacing/comfort playtest remain separate work.
