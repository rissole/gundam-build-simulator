# Robot workshop playtest

Walk the complete wider workshop yourself. A stage jump only sets the scene.

## How to launch

Fresh start, from the repository root. Since 2026-10-24 this begins with the
left foot's heel pads and pitch actuator, built in the hangar:

```sh
./play.command
```

One stage:

```sh
./play.command -- --stage=<stage>
```

Stage preparation is supplied progress and nothing is saved. Wait for the overlay to close before using the controls. Restart re-runs the shortcut.

## Visual uplift spike — 2026-10-25

User direction: the supplied dream reference's warm industrial lighting, cool
fill, atmospheric depth, reflective worn floor and detailed hangar. Preserve the
previous positive approval of the workshop's intermediate brightness and the
manual's readability. No player response to this spike has been received yet.

Use the **new worktree**, `/Users/blakeyboy/gundam-build-simulator-visual-uplift`,
branch `spike/hangar-visual-uplift`:

```sh
cd /Users/blakeyboy/gundam-build-simulator-visual-uplift
./play.command
# Later, to inspect the final-assembly lighting with a robot present:
./play.command -- --stage=complete
```

The spike has a separate save directory. Its later-stage shortcuts still save
within that separate directory under the normal stage-save rules. To compare
renderer support with the same new materials, use
`./play.command --rendering-method gl_compatibility`; this disables the advanced
effects, so it is not a reproduction of main's old appearance.

Mechanical evidence: startup smoke passes all 28 checks. No rendered inspection,
GPU benchmark or player acceptance. [Roadmap assessment and scope](final-assembly-plan.md#visual-uplift-spike--2026-10-25).

- [ ] At the foot preparation bench, can you identify small washers, sockets and magnetic connectors without relying on outlines?
- [ ] Compare the warm floor pools, dark walls and cool roof with the reference. Is the atmosphere welcome, or too dark/washed out?
- [ ] Are the ochre railings, equipment buttons, bay signs and manual text clear at normal viewing distance?
- [ ] Walk and turn while looking at the floor. Check reflection popping at the screen edge, noisy highlights, fog trails and obvious texture repetition.
- [ ] View the gantry from ground level and its working decks. Are the new shadows helpful, or do they obscure connections?
- [ ] Record FPS at the preparation bench and facing the completed robot, using the same display/window conditions as main. Note hitches separately; no 60 FPS claim has been made.

Deferred user proposals, retained for the next decision:

- ACES/Filmic versus existing AgX; darker ambient/near-black background versus readable working bays; stronger warm beams and cool perimeter fill. This spike keeps AgX and the approved ambient/key/exposure values as its starting point.
- Photo-quality oily concrete, worn yellow paint and matte structural metal. Procedural roughness/normal maps are the first material experiment; authored wear and richer texture sources remain open.
- Decal-projected warning stripes, `02 / FINAL ASSEMBLY` and floor markings. Existing labels/hazard marks remain; route-specific marking and additional decals are deferred.
- One or two modular industrial/hangar/crane kits from Fab, Unity Asset Store or Sketchfab, with FBX/glTF import and incremental visual swaps that preserve gameplay scripts. Supplier, budget, licence, style, dimensions and performance remain to be evaluated.
- AI-assisted UI feedback, levers and procedural cable animation. Preserve current movement, riding and support rules; generic Tween crane motion cannot replace them.
- SubViewport console screens, emissive green/amber buttons, motor hums and mechanical thuds. Trial one screen and spatial audio before a wider UI conversion; camera shake is optional and needs precision-work comfort feedback.
- Proposed timing: lighting today, materials this week, kit replacement next week. Keep the order, but gate each next phase on actual readability/performance and import effort.

## Focused controls check — 2026-10-24

The crane/lift UI revision has **no regression run**, at the user's request.
Rendered UI screenshots were inspected; these steps still need your hands-on check.
Start with `./play.command -- --stage=pelvis` so the crane and lifts are ready.

- [ ] Open the crane with E. Movement should be visible immediately; the manual and pockets should return when you close it. Mouse look must stay fixed while open.
- [ ] The crane shows no load list. Parked and empty, it should name the next pickup and offer **Move to pickup · <place>**. Carrying, it should offer only **Move to delivery** or **Put back**. When the next load is blocked, the panel should say why.
- [ ] Use mouse and ↑/↓ + E/Enter; Tab should reach Close. Q closes; Esc pauses. Check your usual window size.
- [ ] Follow one crane delivery: move to pickup → Lower crane → close and rig → Raise crane → move to receiver → Lower crane. Check blocked-command explanations, fastening, release, and that the next pickup advances to the following load.
- [ ] Board both side elevators. Up and Down should each travel one level and stop automatically. Try top/bottom limits and call the elevator from a landing. Repeat carrying a component and using the shelf.
- [ ] On the mobile platform, press **MOVE**, choose a destination from the menu, and ride it. Try mouse and ↑/↓ + E/Enter. Q/Close must cancel without moving; Esc must pause. Up/Down only change height. Down at ground must not send it to parking. To park, choose **Parking bay** from Move. Try Move while raised and check the explanation.
- [ ] Try a blocked mobile transfer. Clear the obstacle, open **MOVE** and choose **Resume to…**, or choose **Return to…** to reverse along the route. Check the rider and anything carried stay with the deck.
- [ ] Read and target the labelled rail, foot-rig and heavy-module-rig buttons. Confirm neighbouring buttons are distinct and the smaller signs remain legible. Their Stop/recovery controls remain available.

Report confusing wording, missed targets, unexpected motion and positive findings
in the table below. The complete workshop journey remains a separate playtest.

## Manual redesign check — 2026-10-25

Mechanical checks only: no rendered review. Start with `./play.command` (fresh
workshop) and later `./play.command -- --stage=pelvis`.

- [ ] The top-right panel reads like a short task: chapter · step, one-sentence goal, checklist. Is it brain-off scannable? Is anything missing that the old prose told you?
- [ ] Items tick themselves as you work (fit counts like 2/4, crane steps as the crane arrives). Nothing should flicker while a machine is moving; raising a load back up should un-tick cleanly.
- [ ] The note appears only for the current item. Do the notes carry the safety details you need (bolt direction, keep connectors attached)?
- [ ] Tab hides/shows the panel; the diagram is always shown. Is the translucent panel readable over the bright bays? Is the diagram size right for tall parts?
- [ ] M opens the manual. Can you tell at a glance where you are? Do Done / In progress / Ready to start / Locked match reality? Enter on another step tracks it.
- [ ] Holding a part shows "For: <step> · <chapter>". Useful or noise?
- [ ] Pelvis delivery (`--stage=pelvis` is past it; start fresh or after the foot): pins, crane trip and gantry jaws are each a checklist item.
- [ ] Left leg: **Deliver the foot** is a new crane step before docking. Then docking, shin, flange (release and park), fork, axle, beam.
- [ ] Z undoes in the build you aim at, otherwise in the current step's build.
- [ ] Steps not yet converted still show prose. Note the worst ones to convert next.

## Stages

| Command | What to try | What to watch for |
| --- | --- | --- |
| `./play.command` (Left-foot heel pads) | Collect pad hardware from the rear-wall cabinets, build both pads at the preparation stations, carry them to the foot bay and fit them. Turn the fixture with its controls. | Cabinet and station walking distances; reaching both heel seats at the raised store height; the fixture platform and controls beside the store |
| `./play.command -- --stage=actuator` (Left-foot pitch actuator) | Build the actuator at preparation C, fit it and the foot's ring hardware, then set the foot upright. | Upper fasteners from the access platform; the turned poses near the right foot store; crane rigging refused until the foot is upright |
| `./play.command -- --stage=pelvis` (Pelvis delivery) | Rig the pelvis, deliver it, close the gantry hold-downs and set the waist locks before crane release. | Fixture clearance, crane-end reach, hold-down handles. |
| `./play.command -- --stage=left_leg_build` (Left-leg construction) | Seat the foot, then crane and fasten the shin, knee fork and upper-leg beam. | Cradle access, console use, fastening reach. |
| `./play.command -- --stage=left_leg_dock` (Left-leg docking) | Travel, stand and dock the leg; finish hip retention and locks; return the empty holder. | Support through the move, hip reach, empty-return path. |
| `./play.command -- --stage=right_leg_build` (Right-leg construction) | Build the right leg on the returned holder, knee axle outward. | Clearance beside the docked left leg. |
| `./play.command -- --stage=right_leg_dock` (Right-leg docking) | Dock the right leg beside the left and return the empty holder. | Side-by-side hip access. |
| `./play.command -- --stage=chest` (Chest delivery) | Deliver the upright chest, fit four waist bolt pairs, release the rig and connect the side services. | Waist reach and service-lead access. |
| `./play.command -- --stage=core` (Core delivery) | Follow the rear route, capture the guide, fit the flange bolts and connect the rear interface. | Rear walking space and connection visibility. |
| `./play.command -- --stage=backpack` (Backpack delivery) | Deliver it open, pin the hinges and struts, connect services, then close and latch under crane support. | Hinge reach, latches, crane reacquisition. |
| `./play.command -- --stage=left_arm` (Left-arm delivery) | Bring the cassette to the station, rig the arm and run the seat route, then retain and connect it. | Cassette boarding, four-end rig, shoulder reach. |
| `./play.command -- --stage=right_arm` (Right-arm delivery) | Transfer the right arm from its store onto the cleared cassette and seat it. | Store pickup and the opposite shoulder approach. |
| `./play.command -- --stage=pauldrons` (Pauldron fitting) | Fit both pauldrons and their shelf-carried panels, then release the local restraints. | Panel carry and how close each pauldron sits. |
| `./play.command -- --stage=head` (Head fitting) | Crane on the baseplate, sides and top; retain them and connect the central loom. | Fixture transfers, loom reach, rig stow. |
| `./play.command -- --stage=head_sensors` (Head sensor fitting) | Fit the sensor carrier, faceplate and hooked mask; connect sensor power and data; then crane on the crown. | Shelf fit, hook and bolt reach, crown keys, camera sight lines. |
| `./play.command -- --stage=complete` (Robot structure complete) | Walk the retained, connected robot with the crane parked. | Anything that still blocks access. |

## Checks

- [ ] Walking and elevator boarding at every level.
- [ ] Connection visibility, reach and tool approach.
- [ ] Rigging attachment and release.
- [ ] Carrying and shelves.
- [ ] Equipment controls (crane console, lift Up/Down, mobile dock selection, labelled local buttons, locks and latches).
- [ ] Overall flow and the manual's suggested order.

The right elevator's local button panel moved to the opposite front corner.
The shelves were enlarged for the mask.
The pauldron route's tightest clearance is about 1 mm at seating.

## Findings

| Date | Stage | Issue or positive finding | Severity |
| --- | --- | --- | --- |
| 2026-10-25 | Any (workshop save) | Asked for Save & quit, Quit without saving, and the player position kept. Implemented: saving is manual (pause-menu Save, Save & quit, or closing the window), Quit without saving confirms unsaved build changes, and position and view are restored. The user disliked refused saves: a mid-ride save now reloads the player on the deck at the machine's last stop; a crane caught mid-move is saved stopped where it is with its load hanging, and Resume continues. Re-check: walk somewhere, Save & quit, relaunch; save mid-lift; save with a load on the moving crane and press Resume after reloading; then fit a part and Quit without saving. | Request |
| 2026-10-25 | Any (manual) | Positive: "I love this new manual — no notes, perfection." Requested: M opens the manual (was N), Tab hides the panel, the diagram is always shown, translucent panel. Done. | Positive |
| 2026-10-25 | Pelvis delivery | "Insert both pins" appeared in the world as "Engage/Unlock waist yaw neutral pin", which made no sense to the player. From the pelvis design: the waist has a twist (yaw) joint and a tilt (lean) joint, both unpowered during assembly; each captive pin holds its joint straight so the waist cannot twist or tilt while the pelvis hangs from the crane and while the chest seats. Now "Waist: Insert twist lock pin" / "tilt lock pin" in the world and "Waist: Insert both lock pins" with a note in the manual. | Fixed, re-check |
| 2026-10-25 | Pelvis delivery (crane) | The manual said only "Move to pickup" and the console said "Move to pickup · Heavy Module Bay". Fixed systemically: every machine line is "<Where>: <exact control text>" from one label function per machine, the console shows "Move to Heavy Module Bay" (pickup or delivery is implied by the load), and the manual says "Crane console: Move to Heavy Module Bay". Foot rig prompts now match their NEXT/STOP/BACK buttons. | Fixed, re-check |
| 2026-10-25 | Foot (pitch actuator) | Positive: building the actuator feels good. Keep its pace and part handling when the manual is redesigned. | Positive |
| 2026-10-25 | Any (manual) | Step text is too long. The user wants a one- or two-sentence goal and a checklist they can act on without thinking. Crane and between-machine steps fail most: the prose sequence is hard to follow and can disagree with the real controls. The full-screen browser, Suggested only and the nested tree make it hard to know where you are. Redesign agreed: [manual plan](manual-plan.md). | Request |
| 2026-10-25 | Foot (actuator into foot) | The clevis step order sent the player to fit the clevis that was refused first. De-scoped by the user for now; not investigated. Both FA-220 clevises are separate variants (`fa-220__001` cradle, `fa-220__002` ring) with no prerequisite between them. | Deferred |
| 2026-10-24 | Any (mobile work platform) | Couldn't stay on the work platform while it moved between docks. Fixed: riding is now shared by every moving platform, hand load included. Re-check by riding it. | Blocking |
| 2026-10-25 | Pelvis delivery | No manual step told the player to insert the waist pins. The delivery page said "engage the captive yaw and lean locks," and Suggested only hides that overview. The pins are the two controls on the pelvis; the crane will not lift until both are in. The page now says to aim at each pin and press E. It still does not appear while Suggested only is on. | Blocking |
| 2026-10-25 | Pelvis delivery | The four gantry hold-down grips could not be seen from the rear deck. Each grip was a 12 cm block centred inside its post, so one grip hid the other, and the Use prompt never appeared because the aim point was inside that solid. The forward grip now sticks outboard of the post and the rear grip reaches back toward the deck; aiming at the grip shows Close gantry hold-down jaw. Re-check from the 8.4 m rear hip deck before detaching the crane. | Blocking |

Mechanical test passes are separate from these playtest results.
