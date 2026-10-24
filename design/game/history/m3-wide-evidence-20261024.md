# M3 wider workshop — mechanical evidence through the paused review, 2026-10-24

Moved verbatim from the plan's implementation ledger. Mechanical results only;
walking, reach, visibility, connection access and presentation remain the user's
playtest. Linked run directories are local and not committed.

Earlier foundation mechanical evidence: `indexed_leg_rail_test`172 checks,
`rail_gates_test`16 checks,
`mobile_platform_test`103 checks, `wide_access_test`43 checks,
`wide_elevators_test` 67 checks and `wide_foundation_test` 16 checks. Shared
`access_lift_test` (30) and `m2_lift_shelf_test` (22) also passed. Both M3 launch
forms, both M2 trials and default launch passed. Authoring audits and diff checks
pass. Logs and JSON are in `game/workshop/verification/`; the combined14-case
run is `regressions-20261024T023603.920310Z/results.json`. It includes11 source-asset
tests and reports unchanged inputs. The final exposed stop-cage ear revision is
covered by the subsequent172-check holder run
`regressions-20261024T023858.517650Z/results.json`, also with unchanged inputs.
These checks establish the integrated subset, **not completed M3 adaptation or human access acceptance**.
No automated walking, reach/visibility sweep or rendered review was run.

The earlier two-leg update passes `indexed_leg_rail_test`340 checks,
`shared_crane_payload_test`21 M2 preservation checks, `wide_foundation_test`16,
M3/M2/default launches and11 source-asset tests in
`regressions-20261024T030330.591351Z/results.json`, with unchanged inputs. That
combined run reports failure because the first structural-contact test used the
frame's conservative collision boxes to infer contact. The corrected test checks
the actual source triangles; its27 checks pass in
`regressions-20261024T030542.352370Z/results.json`. Mirrored source positions,
right-handed frames and shared support ownership are covered there too. The
authoring audits byte-match generated content. No human access or visual approval
is implied by these results.

The current pelvis-plus-both-legs sequence passes385 checks, with57 focused
pelvis fixture/transfer/save checks,21 M2 crane preservation checks,27 mirrored
geometry/ownership checks,43 access-motion checks,16 foundation checks,
M3/M2/default launches and11 source-asset tests. The full selected10-case run is
`regressions-20261024T032854.444020Z/results.json`, with unchanged inputs. After
correcting the declared prepared-envelope and manual framing metadata, the
pelvis/foundation checks also pass in
`regressions-20261024T033215.964429Z/results.json`. These remain mechanical
results; the wider workshop, other major sections and playtest checkpoints are
not complete.

The pelvis → both legs → chest sequence, including chest local correction, passes
496 mechanical checks. Source chest envelope/bolt-bore/key-pocket/core-portal
checks pass16; pelvis57, mirrored sources27, shared M2 crane21, moving access43,
foundation16, assembly model45, support model82 and save model151 also pass.
M3/M2/default launches and11 source-asset tests pass in the selected14-case run
`regressions-20261024T034926.581111Z/results.json`, with unchanged inputs. This
verifies the integrated chest branch and affected shared behavior. It does not
complete the wider workshop or supply human access/presentation approval.

The extended pelvis → both legs → chest → core sequence passes653 mechanical
checks, including the complete core rig envelope, captured handoff, equalizer
adjustment, retention, local correction and return to the original store to free
the shared fixture. Core source/interface checks pass14, shared M2 crane21,
foundation16, M3 launch and11 source-asset tests also pass in
`regressions-20261024T042823.174761Z/results.json`; all6 cases pass with unchanged
inputs. The preceding15-case run,
`regressions-20261024T042320.376978Z/results.json`, also covered chest/pelvis,
mirrored geometry, access-equipment motion, assembly/support/save models and
M3/M2/default launches. These are mechanical checks only; walking, reach,
visibility, connection access and presentation remain for the user's playtest.

The backpack source increment passes28 whole-load/rig preflight checks and215
fixture-exchange checks, including interrupted contact, height and reacquisition
restores. The affected combined11-case run,
`regressions-20261024T044622.635031Z/results.json`, passes with unchanged inputs:
the653-check assembly-through-core sequence, core14, chest16, shared M2 crane21,
foundation16, M3/M2/default launches and11 source-asset tests also pass. Both
authoring checks byte-match generated assets. This proves the source/exchange
and measured-geometry subset, preceding the installation/closure work below.

The completed backpack branch extends the pelvis → both legs → chest → core →
backpack sequence to868 mechanical checks, including local supported correction,
articulated mesh/collision agreement and fresh-scene interrupted restores.
Backpack preflight passes29 checks and the independent storage/fixture exchange
passes215. The selected14-case run,
`regressions-20261024T051113.482577Z/results.json`, passes with unchanged inputs:
core14, chest16, shared M2 crane21, foundation16, assembly model45, supported
model82, save model151, M3/M2/default launches and11 source-asset tests also pass.
Both generators byte-match their authored assets. This verifies the integrated
backpack branch and affected shared behavior; the remaining arms/head, fixture
work and checkpoints below still prevent a complete workshop handoff.

The arm/cassette source increment passes69 mechanical preflight checks. The
[selected15-case run](../../../game/workshop/verification/regressions-20261024T053918.004196Z/results.json)
passes with unchanged inputs, including the868-check sequence through backpack
closure, backpack preflight29, fixture exchange215, chest16, core14, shared
crane21, foundation16, assembly45, supported model82, save model151,
M3/M2/default launches and11 source-asset tests. The earlier run exposed raised
cassette floor pads obstructing the right-leg bogie; the final flush bearings
pass that same delivery. This evidence covers source geometry and preservation
of existing gameplay. It does not establish arm/cassette installation gameplay,
walking/access or rendered approval.

The retained-cassette increment passes72 mechanical round-trip/save checks and
the updated arm/cassette preflight passes70. The
[selected16-case run](../../../game/workshop/verification/regressions-20261024T061244.400723Z/results.json)
passes with unchanged inputs and no rendering. It retains the868-check assembly
sequence through backpack closure, backpack preflight29 and fixture exchange215,
the content/model/support/save suites, M3/M2/default launches and11 source-asset
tests. Both authoring checks byte-match their outputs. This proves the retained
cassette transfer and existing-workflow preservation. Arm release/delivery and
shoulder installation were still outstanding at that increment.

The arm installation increment's final
[18-case run](../../../game/workshop/verification/regressions-20261024T065004.057954Z/results.json)
passed17 cases with unchanged inputs and no rendering. Arm/cassette source
preflight70, actual shoulder fit32, retained cassette72, backpack source29 and
fixture215, chest16, core14, shared crane21, foundation16, assembly45,
supported model82, save model151, default/M2/M3 launches and11 source-asset tests
passed. Both authoring checks byte-match their generated assets.

`arm_after_legs_test` failed at check873, before arm delivery: after the previous
leg/torso/backpack sequence, **Cassette to station → go:source** hit the foot
carrier clearance guard. The sequence had not returned the carrier to its
required state. This is an unresolved integration finding; the guard must not be
bypassed merely to make the test pass. The isolated arm branch earlier passed299
checks, including interrupted clamps/upend/load transfer, both shoulder builds,
compatible washer copies, handed-brace rejection and supported keeper correction.
Those results do not establish that the complete sequence passes.

The user explicitly requested stopping after this run for intermediate human
review. No fix or rerun follows this failed full-sequence case; the active goal
is paused, and pauldrons/head work has not started. Preserve subsequent human
feedback separately from these mechanical results.
