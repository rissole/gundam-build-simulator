# A1 checkpoint — stopped for required editor import, 2026-10-27

**Incomplete; do not integrate as a finished A1.** Work remains on `gv2/layout`
in `/private/tmp/gv2-layout`. No other branch/worktree was changed.

## Implemented checkpoint

`6ce4c0b` authors the replacement levels, upper leaves and shared notched axles,
fixed rear walkway and booms, moved lifts, per-stop side doors, short guides,
new access modes, exact twelve-station contract and gantry finishes/signs.
The obsolete 11.2-only `arm_services_stowed` field and its shoulder callback are
removed. No crane routes or rope mechanics were changed.

The following fixture edits update new stops, shelf world bounds, landing
thresholds, signs and intentional fixed-landing asymmetry. They have not run.

## Evidence and blocking instruction

- `python3 game/workshop/tools/author_workshop_blockout.py --check`: PASS,
  557 solids, 81 frames, generated JSON byte equality.
- `git diff --check`: PASS before checkpoint commits.
- `python3 game/workshop/tools/run_regressions.py --only wide_elevators_test gantry_dressing_test workshop_smoke_test --jobs 4`:
  runner exited 2 before any tests, because assets need importing.
- No diagnostics, rendered review, automated walking/reach sweep or player
  acceptance. No Grok files written or Grok invocation.

The README explicitly says: “If you need new part icons or an editor import,
stop and ask.” The runner requests
`./play.command --headless --editor --import --quit`.
**That command has not been run; approval is required to continue.**

## Implementation choices for review

- Fixed 8.4 hip links occupy the vacated old shaft footprints: removing those
  lifts otherwise severs the retained hip-apron path from each outer walk.
- The left lift threshold extends the 1.3 m apron depth by 0.1 m at each end,
  providing the specified 1.5 m doorway. The axle notch remains open.
- West rear-walk support is at X5.24 rather than near X4.8: X4.8 falls inside the
  retained 8.4 outer walk. X5.24 clears its inner guard; no roof hangers.
- The 0.9 m openings at front stations only 0.7 m apart are merged in the fixed
  guard. All anchors are unchanged; A2 owns clipped-player barriers.
- Ground doors both face east. Right raised doors face east at 8.4 and west at
  20.6. Left doors all face east. Default generic lifts retain both-side behavior.

## Remaining work after approval

1. Import assets, then run the three selected routines. Fix implementation defects;
   stop/report if a retained test proves an accepted interaction breaks.
2. Review underslung guide shoes at **both** endpoints. The initial fixed negative
   shoe offset engages the shortened guide at the top but appears to put the shoe
   below the guide/floor at the ground stop. Resolve before claiming completion.
3. Finish the new mechanical coverage: exact world rope anchors, shared-axle
   notches throughout the swing, exit walkway/booms, upper structural height limit,
   authored lift positions/doors and guide engagement, and coarse grown-robot and
   nearby equipment envelopes. No walking or reach campaign.
4. Complete diagnostic fixture audit for removed levels (edit only, never run).
   `arm_preflight_test` no longer writes the removed service-stow field;
   `pauldron_preflight_test` still refers to the old 16.4-floor notch.
5. Verify selected affected routines through the routine runner with `--jobs 4`,
   including access lifts, equipment motion, rail endpoint, save roundtrip and
   startup. Classify any newly introduced suite.
6. Review thresholds/guard openings and retained 8.4 behavior; update permanent
   evidence/player-recheck links only when the implementation is complete. Human
   usability remains unreviewed. Parent owns merging and central validation.
