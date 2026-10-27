# A2 — Rope access mechanic (coordinator brief)

Branch `gv2/rope`, worktree `/private/tmp/gv2-rope`. Coordinator: Astra High.
Read the [README](README.md) first. You **read** `spec.rope_stations` (contract in
the README); you do **not** edit `author_workshop_blockout.py` or
`workshop-layout.json` — A1 owns them and is working in parallel. Build and test
against the contract with a fixture (e.g. inject the station list into the spec in
your test) so your branch is green before A1 merges.

## Player experience (decided)

Upper connection work (hip lifting eyes, waist, core, backpack, shoulders,
pauldrons, head) is now reached by lowering yourself on a rope from a walkway at
20.6 m. It must feel physical and safe, never fiddly. No swinging physics.

1. **Clip in** at a rope station while standing on its walkway (interact, normal
   reach). The station's guard gate then lets you through; unclipped players can't
   pass a gate.
2. **Hang:** stepping off the edge while clipped puts you on the rope. No free fall:
   the line holds you plumb under the anchor. Hold **Space to ascend, Ctrl to
   descend** (about 1 m/s, stops on release; locked when released). Mouselook stays
   free. W/A/S/D give a small slack offset (≤0.35 m from the plumb line), resolved
   with normal collision so you rest against the robot rather than inside it.
3. **Pull-in lanyard:** while hanging, aim at robot structure within 1.6 m
   horizontally of your line and press a dedicated key (pick one unused in
   `desktop_input.gd`; F if free) to clip a lanyard; you're drawn to about 0.45 m from
   that point and held there. Press again to release back to plumb.
4. **Work while hanging:** normal interaction (E, reach from camera,
   `game.REACH`) works on the rope. Carrying follows existing hand rules; don't
   add new carry exceptions.
5. **Land and unclip:** descending onto any floor (8.4 decks, ground) stands you up,
   still clipped. The rope key unclips while standing on a floor, leaving the rope
   hanging from its davit. A hanging rope end can be clipped into from below (so ropes
   double as a way between levels). Ascending to the top and stepping onto the deck
   returns you to the walkway; unclip there the same way. **Recall rope** at the
   station hauls a free rope back up.
6. **Leaves interlock:** front stations ride on the workshop-side leaves. Expose a
   query (e.g. `front_ropes_clear()`) that is false while any front rope is deployed
   or occupied; the access equipment must refuse/pause leaf motion with a named reason
   ("Recall the ropes on the workshop-side leaves") — wire the refusal in
   `workshop_access.gd` minimally. A rider on a moving leaf is never possible because
   ropes must be recalled first.
7. **Feedback:** HUD status line for rope state (clipped/hanging/length/pull-in),
   manual control glow on stations when a manual objective needs rope access (reuse
   `manual_control_guidance.gd`), clear prompts on gates/stations.

## Architecture

New equipment script (e.g. `scripts/rope_access.gd`) registered like other
equipment (see `workshop.gd` and `equipment_registry.gd`), with
`capture()/validate()/apply()` for saves: per-station rope state (stowed/deployed,
length) and the player's attachment (station, length, pull-in point or none).
Snapshots at rest; invalid snapshots rejected (save deleted, no migration). Player
movement while roped is a mode of `player_controller.gd` (keep it small and
readable); the rope never moves the player through solids. Station world anchors
follow their parent group (leaves swing), so resolve them through the blockout's
group transforms each frame.

## Tests

New routine suite `rope_access_test` (fast, isolated fixture, classified in
`test_inventory.py`): clip/unclip only on floors, gate pass only when clipped,
ascend/descend limits (anchor down to floor), slack bound, pull-in reach limit and
release, landing on a deck, rope-end clip from below, recall, leaf interlock refusal,
save round-trip while hanging and while pulled in, invalid snapshot rejection. Also
run `save_roundtrip_test`, `workshop_smoke_test`, `equipment_motion_test` if touched.

## Stop conditions

Stop and report if the existing interaction/reach system can't target from a
hanging pose without changing shared targeting rules, or if the rope mode requires
changes to rider/platform carrying in `equipment_registry.gd` beyond a hook.
