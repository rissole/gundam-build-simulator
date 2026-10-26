# 02 — Remove the crane's unexplained retention counter

Status: implemented 2026-10-26; mechanical checks recorded in the
[implementation evidence](README.md#implementation-evidence--2026-10-26).
Player recheck and detail-pass obligations below remain open. The work order is
retained as the original scope, not an instruction to repeat completed work.

## Problem and decision

The player does not understand `Connection retention: n/n` or why it appears on
the movement console. `service_crane.gd::status_text()` reports occupied
`fastener_slots`. The associated gameplay rule is significant: installed loads
cannot lose crane support until their receiving connection is secure. The raw
count is not an extra activity; the manual already lists the required hardware.

Remove the redundant raw count. Keep the release/lifting interlocks and explain
the missing action when it blocks a command. This applies to the shared status
text used by both the console and the physical crane sign.

## Sources and work

- Inspect recent work in `scripts/service_crane_console.gd`, `scripts/hud.gd` and
  `tests/crane_console_test.gd` before editing; console cleanup has been underway.
- Trace `service_crane.gd::status_text`, `hardware_count`, `secured`, rig detach,
  raise and move requests, including receiving-support adapters.
- Remove the numeric retention line without inventing a second progress system.
  Keep useful location, motion, magnetic-connector and obstruction information.
- A blocked detach or lift must say what to finish or undo in normal player
  language, preferably naming the connection and pointing to the manual. Do not
  imply every receiver is secured by bolts alone: some use jaws, pins or guides.
- Do not turn the movement console into a manual, add more repeated status text,
  or change retention milestones, hardware quantities or release permissions.

## Acceptance and verification

- No `Connection retention` counter appears in the console or physical sign.
- Incomplete receiving retention still prevents detachment. Partial hardware
  still prevents lifting a seated component out. Completing the actual receiving
  requirements enables the existing commands.
- Blocked commands give an actionable explanation; an empty/parked crane does
  not show stale connection information.
- Use `crane_console_test` and `crane_policy_test`, extending behavior coverage
  only for missing cases. No rendered review is requested.
- Human recheck: deliver and secure one leg component, attempt early release,
  then finish it and detach. Ask whether the reason is now clear.

Record the gameplay significance and resolution in the playtest finding. No
component detail work is required for this task.
