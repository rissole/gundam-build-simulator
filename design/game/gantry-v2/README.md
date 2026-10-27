# Gantry v2 — rope access, 2026-10-27

**Prototype implemented on `gantry-v2`; kept off main until playtested and approved.**
The [overhead rope-access implementation](overhead-access.md) and
[player recheck](../robot-workshop-playtest-checklist.md#gantry-v2-rope-access--2026-10-27)
record the current build. It keeps the low hip
frame and 8.4 m access, replaces the upper floors with rope access at 20.6 m, and
uses hinged workshop-side leaves plus a fixed exit-side walkway. Backpack hinge
access and eventual lowering/departure remain open design work.

## Superseded C6 study

The aft-tower study below is retained for comparison. Its long hip-support beams
failed the coarse checks; it is not the implementation plan. Use the overhead
rope-access plan for current work.

[plan.json](plan.json) owns proposed dimensions; [envelopes.json](envelopes.json)
owns eight grown component boxes, 31 whole-route crane boxes and eight other
reservations. This replaces C5's detailed candidate and close-up campaign.
Seven drawings: levels [8.4](drawings/level-8.4.svg),
[11.2](drawings/level-11.2.svg), [14](drawings/level-14.svg),
[16.4](drawings/level-16.4.svg), [front](drawings/front.svg),
[side](drawings/side.svg), [exit](drawings/exit-route.svg).

## 1. Decisions and margins

Metres; Y up, +Z toward the exit. Reflect X as **26−X**, never rotate a copy.
Keep hip datum **(13,10.6,26)**, bearing caps Y10.97, robot mounting interfaces,
and the crane rail/trolley. The console and **main's authored routes** remain.
No rejected operator-view routes, carry heights or free-strafe assumptions apply.
Building, door and lifts may change under the user's 2026-10-27 decision.

| Envelope | Growth on every face | Basis / treatment |
| --- | ---: | --- |
| Feet; legs; hip | 0.50 | C5 complete-stage own-mesh unions, rounded outward to centimetres |
| Core/chest; backpack; head | 0.75 | Larger armor, equipment and crown allowance |
| Each arm, including its pauldron | 1.00 | Shoulder armor and lateral silhouette uncertainty |
| Every crane delivery | 0.75 | Main route + baseline LOCAL payload/adapter bounds; 1.00 rig allowance before growth |
| Loaded leg routes; mobile routes | 0.50 | Union of C5 measured motion reservations |
| Backpack swing | 0.75 | C5 measured sweep plus its existing interpolation enclosure |
| Service wells / leg corridor | Existing reservation | Preserve the named opening; growth is already on the moving loads |

These are space budgets, not millimetre fit claims or permission to enlarge parts.
Crane boxes include source lift, all route legs, descent, payload, adapter and
cables to Y23. Changing arm orientation uses an origin-centred sphere enclosing
continuous rotation. Constant 0°/X90° payload transforms are exact box transforms.
The additional rig allowance is a design budget, not a newly measured rig fit.
One box loses the empty spaces inside dogleg routes: overlap is a **FAIL requiring
review**, not proof of contact, and never silently waived. Report all 31 routes.
The source commit/hash and local payload bounds are retained in the JSON. C5's
local payload geometry came from the baseline runtime; its branch-dependent
world rig poses, routes and carry results have been discarded.

## 2. Workshop, door and elevator changes

Choose **aft towers**, wholly behind the conservative deliveries. This trades
longer walk/support reaches for generous crane separation, without rerouting it.
Extend the building to X−14..40, Z−9..48, roof Y26; extend the level apron to Z54.
The expanded shell is mirrored about X13; existing bay contents need not move.
Rebuild roof members, lighting and utilities outside the unchanged crane envelope.
No new intertower tie, fixed rear crossover or rear crosshead is permitted.

Replace the continuous Z39 wall and decorative leaf with an operable **14×22 m**
aperture, X6..20/Y0..22 at Z48. Two floor-supported sliding leaves move 7.50 m
outward into X−1.5..6 and20..27.5 pockets. Their panels, handles and colliders move
together; roof tracks stay above the aperture. A flush threshold has no floor rail.
The local OPEN/CLOSE control uses guarded pause/resume and named obstructions.
A closed door blocks departure; open leaf pockets stay outside the exit corridor.

Both elevators live **inside rebuilt towers**, centres X2.4/23.6, Z43.2.
Reserve 3.20-square shafts and 2.60-square cars; stops remain 0.15/8.4/11.2/14/16.4.
Rebuild mirrored guides, car doors and call positions; retire the old shafts.
Inner car edges meet 1.50-wide landings and continuous return lanes, with flush
bridge plates at the 0.02 m joints. Guide members and buttons stay out of those
lanes. Keep shelves, shared riders/cargo, doorway nudge and no landing gates.
A parked catwalk must not obstruct the return lane or either car's boarding path.

## 3. Towers and catwalks per level

Tower envelopes, including bases, pockets and all fixed landings:
**left X0.5..7, right X19..25.5, both Z40..45/Y0..18.6**: 6.50×5.00 footprints.
Use independent braced/moment frames; the boxes reserve space, not solid shafts.
Lift shafts occupy the outer part; retracting equipment parks at the inner edge.
Left return lane X3.7..5.2/Z40.2..43.95 is reflected on the right; a flush fore
landing connects it to the arm root. Its clear 1.50 width survives arm parking.

| Floor Y | Left deployed root X,Z | Main arm | Root travel aft to Z41 |
| --- | --- | --- | --- |
| 8.4 | 6.2,29.2 | 4.30, ending X10.50 | 11.80 |
| 11.2 | 6.2,32.0 | 4.30, ending X10.50 | 9.00 |
| 14.0 | 6.2,32.0 | 4.30, ending X10.50 | 9.00 |
| 16.4 | 6.2,32.0 | 4.30, ending X10.50 | 9.00 |

Right roots X19.8 and tips15.5 mirror the left at identical Z. Decks are1.40 wide,
leaving1.20 between guards; primary landings are1.50 clear. Deck depth0.20,
guards1.10, joints0.02 with captured flush covers; no uncovered telescoping slots.
Top two floors retain2.20 clear headroom; hinges/drives sit beside the walking
surface. The checker separately flags the **support beams'** headroom conflict.

For parking, empty and gate the path, retract the arm4.30→3.00, rotate90° aft
(left +X→+Z; right −X→+Z), then telescope the whole root/path aft toZ41.
This clears fixed inboard roots as well as distal arms. Full parked guards fit
X5.5..6.9/Z40.3..44.7 and its mirror, wholly inside the towers.
Continuous swing/translation bounds are checked against grown robot boxes.
Physical controls stay at the fixed landing; closure gates prevent entering a
missing floor. No one rides a retracting walkway; ordinary elevator riding stays.
Positive extension/rotation locks carry the walking load. Tips are work-space
budgets, **not verified reachable fastening positions**; do not add remote reach.

## 4. Hip support

Keep independent supports, the two original cap patches at X12.35/13.65,
Z26.52..26.78, topY10.97, four hold-downs and the robot's twist/tilt locks.
Propose two retracting diagonal beams from tower roots X6.2/19.8,Z40 to the caps;
loads go through their tower sockets, bracing and foundations, never catwalk hinges.
The provisional0.60-wide,1.00-deep beam/retention reservation is Y9.6..11.4.
Approximately14.7 m plan reaches are a serious cost of aft towers. Sections,
structural capacity and deflection are **not established** by these boxes.

**Blocking C5-02/C5-05:** whole support boxes overlap grown arms/hip, hip-level
headroom, loaded-leg paths and service wells. Some overlap comes from boxing a
diagonal; the bearing is also an intentional interface. Neither explains away
all conflicts. No contact exemption is used. A smaller section or imagined void
cannot count as a solution. Recommend a focused support-topology decision at the
existing caps, including intermediate load transfer, before any build task.
If resolution would require moving the robot or hip datum, stop and return that
choice to the user. This plan retains both and stops construction here.

Only after an independently supported carrier takes weight may jaws release and
the complete unloaded beams retract into X5..7 /19..21, Z40..45 pockets.
Carrier support and brakes precede release; weight returns before reversing it.
No hidden owner swap, decorative cable, or catwalk stow can substitute for support.

## 5. States: assembly, delivery, exit

| State | Catwalk / support / reserved-volume contract |
| --- | --- |
| Assembly | Needed paths extended, flush and locked; hip supported and retained. Current support geometry remains blocked. |
| Delivery | All paths retract into towers for this coarse candidate; lifts remain usable. Hip supports stay engaged. Main routes unchanged; their boxed overlaps remain failures. |
| Core service | Crane travel stopped; removable rails/crossframes supported and locked before core retention releases. Stow kit before normal delivery/exit. |
| Exit | Carrier takes weight; release retention, stow all supports/paths, stow service kit, open door, then roll +Z. |

Core service retains pads X11.1/14.9 atZ29.5/32.1, two crossframes with beam
topsY12.60/upstands13.05 and5.00 withdrawal. Replace lost deck supports with two
removable tower-socket carrier beams, one per side, carrying the fore/aft pad
pairs; crossframes and rails lock to these. They are independent of catwalks.
Their temporarily deployed spans enter the service reservation intentionally;
no permanent tie remains. Store the disassembled kit behind each tower outside
the exit. Load capacity, deployment geometry and the guided withdrawal still
need a service-specific design; this is a load-path proposal, not floating rails
or a claim of a checked installed kit. No new robot parts/slots are authorized.

| C5 conflict | C6 disposition |
| --- | --- |
| C5-01 parked arms/roots | Entire arm AND root retract into tower; exit and park/return checks pass. Work-tip reach remains player review. |
| C5-02 hip supports | Unresolved and blocking; preserve contacts/datum, propose independent retracting load path; do not waive coarse collisions. |
| C5-03 door | Replace wall/leaf with the dimensioned sliding aperture and level apron; exit aperture checks pass. |
| C5-04 core supports | Removable tower-socket beams carry both pad pairs and crossframes; installed service mechanism remains a future design gate. |
| C5-05 headroom/access | Side-mounted hinges and0.20 decks retain2.20; support obstruction remains C5-02. No reach claim. |
| C5-06 crane/tower | Main routes replace free strafe; aft towers clear all31 route boxes. Engaged-support overlaps remain failures. |
| C5-07 lift asymmetry | Rebuild both internal lifts/guides/landings as reflections; return lanes avoid parked arms and guide reservations. |
| C5-08 backpack | Keep measured sweep with the stated growth; reserved sweep clears proposed cage. Service opening unchanged. |

## 6. Exit route

Reserve **X7.5..18.5/Y0..21/Z22..54**, straight +Z, with no fixed crossing.
Use a proposed10×8 m carrier footprint X8..18/Z22.5..30.5, chassis below the
soles and adjustable pads up to their present Y1.40. Transfer at the raised pose;
no lowering or hip-datum change is needed for the aperture budget. Expanded feet
may require lower pad settings; carrier/chassis and transfer engineering are open.
Grown robot width10.68 and top20.16 fit the11×21 lane; the remaining lateral
clearance is0.16 per side **after** the robot's growth allowances.
The14×22 door gives additional room. The carrier's approach, sole load capacity,
retention/braking and departure gameplay are not implemented or approved.

## 7. What a build changes in the game

Paths below are under `game/workshop/`; no such files changed for C6.

| Files / systems | Required future change |
| --- | --- |
| `tools/author_workshop_blockout.py`, `assets/workshop-layout.json` | Shell/aperture, tower/lift/landing/pocket data; retire old gantry and Z39 wall; keep robot/crane datums/routes |
| `scripts/hangar_dressing.gd`, `gantry_dressing.gd` | New shell/door and moving steel, retain accepted finish; visuals and collision agree |
| `scripts/work_access_lift.gd`, `workshop_access.gd`, `leg_bay_layout.gd` | Mirrored guides, calls, bridge plates, catwalk roots, guards and locks |
| `scripts/module_supports.gd`, shared equipment/zone and staged-receiver systems | Explicit supported handoff, hold-downs, motion interlocks, carrier/door state; avoid bespoke receiver pairs |
| Equipment `capture()`/`apply()`, save integration | At-rest positions and supported children round-trip; invalid saves deleted, no migrations |
| Manual authoring / generated chapters | Physical machine labels, support/retention objectives and undo; one goal plus typed checklist |
| Focused tests and `tools/test_inventory.py` | Retire old layout expectations, cover new geometry/support/lift states; classify any new suite |

## 8. Prototype slice and task list

First candidate slice remains **both Y8.4 paths plus hip handoff**, after support
resolution and explicit build approval. Include necessary relocated lift/tower
interfaces; exclude upper catwalks, door/carrier departure and core service kit.

| Task | Agent type | Gate / result |
| --- | --- | --- |
| Resolve support topology, bearing approach, headroom and long reach | Astra High | Passing credible support proposal at unchanged datum; otherwise stop |
| Review route-box overlaps without recreating C5's tolerance campaign | Astra High | Explain actual topology/contact vs broad-box overlap; never suppress failure without a bounded basis |
| Define slice parts, ownership, locks, physical control/step outline | Astra High | User reviews concrete design, then separate build approval |
| Write exact game edit tasks against approved revision | Astra High | Unique quoted anchors, full replacements, focused commands and stop conditions |
| Apply those future bounded edits | Grok | Only after approval and task authoring; no engineering decisions delegated |
| Integrate, audit affected manuals and focused behavior | Astra High | One coherent checkpoint, no automatic diagnostics or rendered review |
| Walk, operate and assemble at both sides | User | Acceptance or findings preserved in the linked playtest record |

Step outline: identify source/support → take crane weight → seat on both caps →
close four hold-downs and waist locks → release crane → stow paths for leg entry →
restore access → secure leg ring/pins → withdraw empty holder. Undo transfers
weight first. Parent motion must carry every mounted child and its collision pose.
Future routine plan: touched `gantry_dressing_test`, `access_lift_test`,
`wide_elevators_test`, `supported_model_test`, `receiver_contract_test`,
`rail_endpoint_test`, `rail_gates_test`, `zone_register_test`,
`equipment_motion_test`, `nested_runtime_test`, `save_roundtrip_test`,
`manual_objectives_test`, `manual_progress_test` and one startup smoke, selected
via `run_regressions.py --only <touched suites> --jobs 4`. Check actual aim/control
handoff, premature release, undo, blocked motion and at-rest supported reload.
No automatic walking/reach sweeps; rendered review only if requested.

## 9. Open questions for the user

1. Accept the aft-tower space tradeoff (larger shell and long telescoping paths),
   subject to resolving support? Recommend treating it as a layout reservation,
   not approving the14.7 m hip beams or construction.
2. Allow a focused alternate **hip support topology at the same datum/caps**?
   Recommend yes before any prototype; the present envelopes fail. If no credible
   path fits, retain the current gantry rather than move the robot.
3. Use a carrier at the current raised sole height for eventual departure?
   Recommend this clearance baseline; carrier/transfer and core-service engineering
   remain separate gates. Lowering is still deferred, not silently authorized.

## 10. Mechanical evidence, separate from player acceptance

`python3 design/game/gantry-v2/check.py`: **FAIL, 46/67 pass, 21 unresolved**.
Signed clearance is Euclidean separation, or negative least-axis box penetration.
All31 routes clear fixed tower volumes (minimum0.45 m); failures involve engaged
supports. Support/robot and support/headroom also fail, as do their service/leg
reservations. Failed diagonal boxes do not prove every physical beam will collide.
The passing exit budget does not prove supported transfer or carrier operation.
`python3 design/game/gantry-v2/draw.py` regenerates exactly seven overview SVGs.
Package size is about140 KB. JSON/SVG syntax, deterministic generation, source-route correspondence and checker
mutation guards are design-tool checks only. Fine runtime probe **not run**;
no regressions, diagnostics, game launch, rendered review or walking sweeps ran.

The retained `probe/run.py` can regenerate fine data against `main` after a
separately requested measurement run on an imported project. It writes only to
ignored `game/workshop/verification/c6/`; it does not replace coarse envelopes.
The updated probe is unexecuted. C5 measurements are reused evidence, not fresh
mechanical tests. Accepted gantry finish, repaired gaps/mirroring and physical
assembly challenge remain constraints. **No C6 player acceptance.** Findings and
unresolved choices stay in the [machine-operation checklist](../robot-workshop-playtest-checklist.md#machine-operation-and-gantry-access--2026-10-26).
