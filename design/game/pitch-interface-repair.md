# Pitch actuator interface repair

The repaired pitch build passed rendered review on 2026-10-21: all 14 child pages
and the three parent installation pages. The [accepted report](../../game/heel-pad-demo/verification/pitch-visual-review/review.md)
records per-page findings, capture paths and exact input hashes. The original
failed findings and the sensor-conflict negative control are preserved in the
compact accepted review archive.

## Scope and reuse

`models/foot-fa01/src/pitch_interfaces.py` remodels the existing pitch instances
after their inventory identities are allocated. It does not change shared screw,
washer, roll-actuator or forefoot-actuator generation. The gameplay export merges
only the 109 pitch pieces plus the specific FA-103 cradle and FA-200 ring receiving
frames. All other exported nodes, mesh buffers and materials remain unchanged.
`verification/pitch-reuse-audit.json` records this preservation check.

The two frame changes are local pitch interfaces: relief around the base eye at
the cradle outrigger, side mounting holes on that outrigger, and mounting holes
on the ring's existing upper land. Their parent fit and adjacent structure require
rendered inspection; preserving other instance data does not approve these frames.

## Connection decisions

Coordinates below are millimetres along the pitch axis from the base eye. These
replace the conflicting reference packaging for the playable pitch prototype;
roll and forefoot geometry remain reference models awaiting their own reviews.

| Interface | Receiving geometry and access |
| --- | --- |
| FA-510 barrel | 90–550; 460 mm tube, 140 mm outside diameter. Integral motor, thrust-bearing and guide seats, cap bosses and guide/sensor lands. Base/rod pin centers and 570 mm front guide datum retained. |
| FA-513 motor | Rear flange 110–118 on housing seat. Upper flange has access cutouts for the four lower screws. Gearbox closes these accesses only after motor fastening. |
| FA-514 gearbox | Flange 158–166 seats on motor. Output journal 194–220. Upper screws sit outside the cartridge core. |
| FA-515 coupling | Split clamp 194–245; two distinct transverse screws 26 mm apart. Receives gearbox journal and lead-screw journal, each 24 mm diameter. |
| FA-516 screw | Journal 220–245, bearing/collar journal 245–304; threaded section begins beyond collar. |
| FA-522 / 523 / 524 | Bearing 250–272 in housing seat; retainer 272–280, two screws on a separate bolt axis; split collar 280–304, screws through joining ears. |
| FA-517 / 518 | Nut and rod meet at the original nut datum. Flange pockets expose axial screw heads. Rod now ends 68 mm before rod-eye center to clear the eye neck. |
| FA-521 guide | Tongue engages a real longitudinal rod slot. Offset ears fasten to fixed housing lands without crossing the moving rod. |
| FA-528 / 530 | Sensor probes retain their sensing datums; mounting ears and screws move 28 mm sideways to clear cap bolts. Rear sensor land starts at the 90 mm barrel face, clear of the rear cap. Connector has its own bulkhead opening and flange. |
| FA-519 / 520 / 529 / caps | Bushing seats in housing shoulder; wiper in front cap recess. Gaskets on end faces. Eight bored cap sites mate to bored housing bosses. |
| FA-525 / 526 / 527 | Clear spherical-bearing/pin openings, far shoulder and near retaining-clip groove. Axial eye fastening flanges lie outside the cap/rod and pin opening. |
| FA-220 / 221 / 222 | Base clevis attaches to FA-103, rod clevis to FA-200. Mounting bolts clear the eye. Full-depth mounting bores clear the integral braces. Both pin heads and keeper screws are accessible from the outboard side. |

The existing 91 child pieces and 18 parent pieces remain the inventory. New holes,
seats, bosses and reliefs are integral manufacturing features, not extra supplies.
Assisted placement remains unchanged; the game does not require threading or tool
alignment as player mechanics.

## Verification

The accepted report records 69 imported-triangle clearance checks, 286 headless
pitch desktop checks, 114 model checks, 65 two-pad interaction checks and 44
pocket/manual workshop checks. The original asset fails 40 of the current 69
clearance checks. An intermediate negative control also reproduces the crossed
sensor/cap fasteners.

The real Godot renderer captured 251 checkpoints and 1,598 images across the 17
pages. Visual inspection covered all 112 page sheets, working views, both rotation
sequences and additional full-resolution service close-ups. The full prepared
assembly now appears in its mounting preview. The source merge retains all 745
physical identities and verifies preservation of the 634 unrelated instances.

This accepts the assisted gameplay build and its visible connections. Internal
placement uses the service view; continuous collision-free manufacturing paths,
threading, torque, strength, actuator motion and external wiring are outside this
milestone. Save/resume and the remaining default-workshop/pad visual review are
separate next steps.
