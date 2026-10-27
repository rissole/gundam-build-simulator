# A3 — Crane through the leaves; core and backpack from the front (coordinator brief)

Branch `gv2/crane` (from `gantry-v2` after A1 merges), worktree `/private/tmp/gv2-crane`.
Coordinator: Astra High. Read the [README](README.md) and [A1](A1-layout.md) first.

## Rules (decided)

- **Every crane delivery approaches from the front**, through the workshop-side
  leaves at 20.6. Crane cables may cross the leaf band (Z23.4..24.6, trolley within
  X4.4..21.6) **only while the leaves are open**. No cable or load may ever cross the
  exit-side walkway (Z30.3..31.7, X5..18) or its booms (X11.0/12.4/13.6/15.0,
  Z28.3..30.3, Y21.8); aft of Z28.3 keep cables within X13±0.4.
- **Leaves follow the crane, not the task:** a crane motion segment that crosses
  the band requests the 20.6 leaves open and pauses (named reason) until they are;
  segments that don't cross it don't hold them open. Once a load hangs over the
  robot (Z26), the player may close the leaves and rope down from the front while
  the crane still holds the part. When the crane leaves back through the band it
  re-requests them open. If front ropes are deployed (A2's `front_ropes_clear()`,
  or a stub returning true until A2 merges), opening pauses with A2's named reason.
  Replace whole-task `access_mode`/`restore_access` behaviour where it conflicts;
  8.4 wing needs (leg, arm) keep their current behaviour.
- **Core and backpack routes** (currently via the east side/rear well and over
  Z31.8) are re-authored to come from the front over the chest: lift above the
  chest top (≈18.7 + margin, coarse boxes), travel aft at X13, descend behind the
  chest to the core's rear-approach pose (axis Y13.35, support around Z29.2) and the
  pack's hinge approach (hinge seat (13,15.5,27.2), pack open 90°). Keep loads below
  Y20.3 wherever they pass under a closed structure and the hook below the crane
  bridge. Aft of Z28.3, spreaders and rigging stay below Y21.6 (booms at Y21.8). Head pieces/pauldrons/arms keep their routes; verify each crosses the band
  only with leaves open and stays clear of the open leaves (X4.4..5.6/20.4..21.6,
  Z16..24, Y20.3..21.7) — adjust waypoints coarsely if not.
- Keep the crane console and its controls; this is not a crane UX redesign.

## Tests

Extend routine crane coverage (`crane_policy_test`, `crane_console_test`,
`equipment_motion_test`, `save_roundtrip_test` as touched) with: leaf-band crossing
requires open leaves; pause/resume with named reason; leaves closable while a load
hangs at Z26; no route segment crosses the exit walkway/booms; core/backpack route
waypoints end at their existing seat/approach poses. Route-data/expectation edits
are good Grok tasks. Don't run diagnostics such as `backpack_delivery_test` or
`core_content_test`; if they need fixture edits to stay loadable, edit only.

## Stop conditions

Stop and report if a load cannot pass over the chest below Y20.3 with the hook under
the crane bridge, or if the core's rear approach needs crane support aft of Z28.3
outside X13±0.4.
