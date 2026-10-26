# C — Gantry access (coordinator brief)

Branch `gantry-access`, worktree `/private/tmp/gbs-gantry`. Coordinator: Astra High.
Read the [README](README.md) shared rules first.

## Player problem

Walking the fixed gantry to reach the hip assembly is frustrating. It feels
asymmetric, and there are small gaps that are easy to fall through. The fixed rear
crossover (Z35.8..37.3 on levels 8.4/11.2/14.0/16.4) and the crosshead
(X8.5..17.5/Y10.5..11.1/Z31.1) also mean the robot can never leave through the
hangar door directly behind it (`hangar_dressing.gd` DOOR X2.25..23.75 at Z38.78).
The user is wary of a large redesign while the robot parts are still temporary
prefabs.

The static solids in `game/workshop/assets/workshop-layout.json` are mirrored
left/right. The asymmetry is probably in the runtime fold states
(`workshop.access.modes`: wings, fingers, rear hip bridge leaves per mode) or in
one-sided equipment. The user will name the spot (C0); do not guess-fix symmetry
before then.

## Phase 1 — this run

1. **C1 Gap audit.** Write a scratch script (keep it out of the repo, or under
   `game/workshop/verification/` uncommitted) that boots the workshop headless at
   the hip and leg stages. For each `access.modes` state, it lists walkable-deck
   seams and unguarded edges larger than the player capsule could fall through or
   catch on. Measure the actual runtime blockout and lift collision, not just the
   JSON. Focus on where the hip-level finger, flank, branch, apron, wing-hinge and
   elevator-landing decks meet. Also check side-by-side for any left/right
   difference in the runtime states. Output a table: location, gap size, mode,
   proposed fill plate/toe-board (exact box center/size/parent), and the clearance
   it must keep. The service clearances X11.4..14.6/Z27.2..35.3 and the aft lifting
   well stay open, folding parts must still fold, and the leg corridor stays clear.
2. **Write `C2-fill-plates.md`**, a Grok task with exact JSON/blockout edits,
   commands (`gantry_dressing_test` plus any access/lift suites touched) and
   acceptance. If a fix is a moving part (a finger or leaf length), do it yourself
   instead of handing it to Grok.
3. **C4 v2 "launch cage" concept (design only).** Add a dated section to
   `design/game/final-assembly-plan.md`: two symmetric side towers around the
   existing elevator shafts (X6.6/19.4, Z29), swing-arm catwalks per level that dock
   flush to the robot and swing clear, the hip carried by tower arms instead of the
   rear crosshead, no fixed rear crossover, and a roll-out exit state toward the
   door (all arms clear, robot lowered — currently a deferred item). List every
   delivery clearance a build would re-audit: core rails/crossframes, backpack
   sweep, pauldron/arm/head routes, leg corridor, mobile platform. Note the
   dependency on branch A's crane carry height. Estimate the build effort and say
   what part work it does **not** block (parts mount to the hip datum, Y10.97
   bearing caps). Add an SVG sketch only if it materially helps. Stop for **human
   checkpoint C**.

Stop and report after 1–3.

## Later phases

- I launch Grok for C2; then a coordinator integration run reviews it and runs
  `gantry_dressing_test`, the access/lift suites and the startup smoke.
- **C3 Mirror fold states.** C0 answered on 2026-10-27: on the **lowest level, left and
  right of the hip assembly**, the railings don't match, and the side of the hip assembly
  can be reached from that level on one side but not the other. Find the runtime cause
  (fold/leaf state, guard, finger length, apron vs. landing), then make both sides offer
  the same access and matching railings.
