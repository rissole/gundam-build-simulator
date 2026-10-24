# Wider M3 workshop playtest

Walk the complete wider workshop yourself. A stage jump only sets the scene.

## How to launch

Fresh start, from the repository root:

```sh
./play.command -- --m3-workshop
```

One stage:

```sh
./play.command -- --m3-stage=<stage>
```

Stage preparation is supplied progress and nothing is saved. Wait for the overlay to close before using the controls. Restart re-runs the shortcut.

## Focused controls check — 2026-10-24

The crane/lift UI revision has **no regression run**, at the user's request.
Rendered UI screenshots were inspected; these steps still need your hands-on check.
Start with `./play.command -- --m3-workshop`.

- [ ] Open the crane with E. Movement should be visible immediately; the manual and pockets should return when you close it. Mouse look must stay fixed while open.
- [ ] Choose **Change load…**, search for `pelvis` (including typing E), select **Pelvis and waist**, and return to the movement controls. Try a search with no results, clear it, and scroll to the final load.
- [ ] Use mouse and ↑/↓ + E/Enter; Tab should reach the search and Close buttons. Q closes when not typing; Esc pauses even when typing. Check your usual window size.
- [ ] Follow one crane delivery: move to pickup → Lower crane → close and rig → Raise crane → move to receiver → Lower crane. Check blocked-command explanations, fastening, release and parking before changing load.
- [ ] Board both side elevators. Up and Down should each travel one level and stop automatically. Try top/bottom limits and call the elevator from a landing. Repeat carrying a component and using the shelf.
- [ ] On the mobile platform, choose a dock with **DOCK ›**, press **MOVE**, and ride it. Up/Down must only change height, even with a different dock selected; Down at ground must not send it to parking. To park, choose `park` and press Move.
- [ ] Try a blocked mobile transfer. Clear the obstacle and use **RESUME**, or use **← BACK** to return along the route. Check the rider and anything carried stay with the deck.
- [ ] Read and target the labelled rail, foot-carrier and bulky-fixture buttons. Confirm neighbouring buttons are distinct and the smaller signs remain legible. Their Stop/recovery controls remain available.

Report confusing wording, missed targets, unexpected motion and positive findings
in the table below. The complete workshop journey remains a separate playtest.

## Stages

| Command | What to try | What to watch for |
| --- | --- | --- |
| `./play.command -- --m3-stage=pelvis` (Pelvis delivery) | Rig the pelvis, deliver it, close the gantry hold-downs and set the waist locks before crane release. | Fixture clearance, crane-end reach, hold-down handles. |
| `./play.command -- --m3-stage=left_leg_build` (Left-leg construction) | Seat the foot, then crane and fasten the shin, knee fork and upper-leg beam. | Cradle access, console use, fastening reach. |
| `./play.command -- --m3-stage=left_leg_dock` (Left-leg docking) | Travel, stand and dock the leg; finish hip retention and locks; return the empty holder. | Support through the move, hip reach, empty-return path. |
| `./play.command -- --m3-stage=right_leg_build` (Right-leg construction) | Build the right leg on the returned holder, knee axle outward. | Clearance beside the docked left leg. |
| `./play.command -- --m3-stage=right_leg_dock` (Right-leg docking) | Dock the right leg beside the left and return the empty holder. | Side-by-side hip access. |
| `./play.command -- --m3-stage=chest` (Chest delivery) | Deliver the upright chest, fit four waist bolt pairs, release the rig and connect the side services. | Waist reach and service-lead access. |
| `./play.command -- --m3-stage=core` (Core delivery) | Follow the rear route, capture the guide, fit the flange bolts and connect the rear interface. | Rear walking space and connection visibility. |
| `./play.command -- --m3-stage=backpack` (Backpack delivery) | Deliver it open, pin the hinges and struts, connect services, then close and latch under crane support. | Hinge reach, latches, crane reacquisition. |
| `./play.command -- --m3-stage=left_arm` (Left-arm delivery) | Bring the cassette to the station, rig the arm and run the seat route, then retain and connect it. | Cassette boarding, four-end rig, shoulder reach. |
| `./play.command -- --m3-stage=right_arm` (Right-arm delivery) | Transfer the right arm from its store onto the cleared cassette and seat it. | Store pickup and the opposite shoulder approach. |
| `./play.command -- --m3-stage=pauldrons` (Pauldron fitting) | Fit both pauldrons and their shelf-carried panels, then release the local restraints. | Panel carry and how close each pauldron sits. |
| `./play.command -- --m3-stage=head` (Head fitting) | Crane on the baseplate, sides and top; retain them and connect the central loom. | Fixture transfers, loom reach, rig stow. |
| `./play.command -- --m3-stage=head_sensors` (Head sensor fitting) | Fit the sensor carrier, faceplate and hooked mask; connect sensor power and data; then crane on the crown. | Shelf fit, hook and bolt reach, crown keys, camera sight lines. |
| `./play.command -- --m3-stage=complete` (Robot structure complete) | Walk the retained, connected robot with the crane parked. | Anything that still blocks access. |

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
| 2026-10-24 | Any (mobile work platform) | Couldn't stay on the work platform while it moved between docks. Fixed: riding is now shared by every moving platform, hand load included. Re-check by riding it. | Blocking |

Mechanical test passes are separate from these playtest results.
