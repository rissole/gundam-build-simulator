# Equipment controls revision — 2026-10-24

The user found the crane menu confusing and cluttered, requested clearer physical
buttons including both lift types, and asked for screenshot verification. They
then requested **no regressions**, a commit, updated README screenshots and a
checklist for their own verification.

## Changes

- The centered crane panel now shows movement first. **Change load…** opens a
  separate searchable, scrollable chooser. Parking no longer offers an unusable
  Lower command. Raise/Lower and named destinations use explicit labels; blocked
  actions retain their explanations and controller guards.
- The panel is opaque for readability. The manual and inventory temporarily hide
  while operating the console. Closing restores the HUD and ordinary input.
- Elevators have a vertical **Up / Down** pair onboard. The third button was a
  Ground shortcut, not Stop; separate landing-call buttons remain. Each direction
  travels one authored level and stops automatically.
- Mobile platform height has dedicated **Up / Down** buttons. **DOCK ›** chooses
  a destination and **MOVE** travels there at ground level. Down at ground cannot
  unexpectedly return to parking. Interrupted travel exposes **RESUME / ← BACK**;
  normal use has no Stop button. Existing controller commands remain available
  for internal compatibility and correction.
- A shared physical-key visual labels rail, carrier, fixture and lift controls.
  Their interaction prompts sit beside the nearby button group. Signs are
  smaller; the mobile controls have a visible backing panel. Rail/crane/fixture
  Stop and recovery behavior remain because those controls handle other workflows.

## Evidence and limits

The real Godot 4.7.2 compatibility renderer produced 12 fixture screenshots in
`game/workshop/verification/equipment-ui-commit-602181/`. The capture manifest
records unchanged code/asset inputs, camera poses and image hashes. Local
`review.json` records the presentation findings. Final captures are byte-identical
to the preceding inspected render after a keyboard-focus-only repair; the four
README images were inspected again from the final output.

The crane's movement view fits at 1280×720 without scrolling. The separate chooser
shows a bounded list and filters to the pelvis. Supplied pickup/lowered states
show the relevant vertical action. The elevator and mobile key labels are
readable, and the equipment prompt no longer covers neighbouring buttons. Rail,
foot-carrier and bulky-fixture key faces were inspected too.

The four curated screenshots are in `docs/images/workshop-*-controls.png` and
`docs/images/workshop-crane-loads.png`, with provenance in
`docs/images/workshop-controls-captures.json`. Both READMEs embed them. Reproduce
with the command in the [workshop README](../../../game/workshop/README.md#equipment-controls).

**No regression tests were run.** The render fixture loaded and completed without
script errors, and `git diff --check` passed. Existing console test expectations
and navigation helpers were adjusted for the revised interface but remain unrun.
Rendered fixtures do not establish walking, target comfort, rider/cargo motion,
rigging, fastening or interrupted-transfer behavior. M2 and the right elevator
were not separately rendered. Existing assembly recipes and load/support routes
were not redesigned.

## User verification

Use the [focused controls checklist](../m3-wide-playtest-checklist.md#focused-controls-check--2026-10-24).
Prioritize one full crane delivery, both elevator rides, mobile height versus
dock selection, recovery after blockage, and keyboard/search/Close behavior.
Retain the previously praised physical handling, boarding and workshop scale.
Hands-on usability acceptance remains pending.


## Follow-up — 2026-10-25

The user requested replacing mobile Dock/Move with one Move button and a menu
like the crane's. The three physical keys are now **Up, Down, Move**. Move opens
a centered destination picker; selecting a destination dispatches the existing
route and closes the menu. Current dock is omitted. Ground-height, occupancy and
local reach/visibility guards remain active. Interrupted travel exposes Resume
and Return in the same menu; Q/Close cancels without changing the route. The old
controller commands remain internal for compatibility, but no longer appear as
physical controls. The sign now names the current location instead of a cycled
selection.

Captured four views with `equipment_ui_review.gd -- --platform-only` into
`game/workshop/verification/equipment-ui-destination-menu-final-624747/`.
Inspected the physical panel, destination list and supplied interrupted-route
menu: all choices and Close fit, with readable labels and no prompt overlap.
Both READMEs show the updated physical panel; the workshop README also embeds
the destination menu. `docs/images/platform-move-captures.json` records their
source/image hashes. The local `review.json` records the inspection limits.

No regressions ran. The render fixture completed without script errors and
`git diff --check` passed. Selecting destinations, cancellation, raised-platform
feedback, riding and recovery still need the user's focused controls checklist.
