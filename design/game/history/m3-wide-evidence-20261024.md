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

## Plan implementation ledger, through task 09

Moved verbatim from the plan on 2026-10-24 after handoff tasks 01–10 finished.
Its "Remaining work" list is complete; the deferred items are tracked in the
[workshop state](../workshop-state.md).

- Task 09 resolves the stop recorded in `94d37c2` using the user's 2026-10-24
  shelf decision: both M3 shelves are 1.50 m wide with a 1.45 × 0.35 × 1.20 m
  single-panel capacity; M2's shelf contract is unchanged. Adds the prepared sensor
  carrier/captive M8 actions and power/data connection, separate faceplate and
  hands-free hooked mask, then the two-key crown via the shared fixture/crane.
  `complete` is the final development boundary. Manual/stock, shelf/elevator,
  optical, supported correction and full-rig route checks are mechanical evidence;
  walking, reach/visibility and rendered presentation remain unreviewed.
  See [head details](../../head.md#robot-workshop-head-implementation--2026-10-24) and
  [task 09](m3-wide-handoff/09-head-hand-pieces-and-crown.md) for scope and acceptance.

- Task 08 adds four head crane pieces on staged receivers, upright bulky-fixture
  inserts and store transfers, separate retention/loom stock, and `head_sensors`.
  Full-payload/full-rig preflight and supported-correction/manual checks cover
  this structural subset; hand-carried closures and crown remain task 09.
  See [head implementation details](../../head.md#robot-workshop-head-implementation--2026-10-24)
  for source locations, contact tolerance and the hub relief deviation. Walking,
  reach/visibility and rendered presentation have not been reviewed.

- Task 07 adds content-driven guided receivers, `game.zones` occupancy for the
  shared limb station, and both pauldron carriers, M20 bolt units, independent
  shelf-carried panels and local restraint release. The `head` development stage
  starts with closed pauldrons, released restraints and a parked crane. See the
  [pauldron implementation detail](../../arms/shoulder-and-upper-arm.md#robot-workshop-pauldron-implementation--2026-10-24)
  for passive stores, mounting reliefs/shoes, harness clearance and panel sizes.
  Payload/full-rig preflight and mechanical regression evidence are separate from
  the user's pending walking/access playtest; presentation remains unreviewed.

Integrated foundation:

- `tools/author_workshop_blockout.py` authors the `workshop` spatial contract in
  `assets/leg-bay-m3-layout.json`: bays, raised robot datums, rail/holder envelopes,
  dispatch, source contacts, parking, mobile-platform docks, crane coverage and
  routes, gantry and access geometry. Current output has 540 solid/marking records
  and 76 equipment frames. `workshop_blockout.gd` projects the actual solids.
- M3 uses the new 25 m shell, expanded crane structure, low pelvis portal, shared
  walks, front wings/fingers and upward-folding rear hip leaves. Access movement
  retracts fingers and guards before rotating decks, rejects occupied sweeps,
  and retains interrupted phases. The local hinge aprons are explicit machine
  bearing contacts; their exclusions do not include the surrounding walks.
- Both side elevators and independent shelves replace the former single hip lift.
  Side doors open at each stopped landing. Shelf support IDs and cargo are
  independent, and their movement uses the existing collision/ownership systems.
- Normal M3 aliases launch; access/elevator/shelf states use the existing equipment
  registry and validated atomic session saves. A fresh-scene disk restore of an
  interrupted access configuration passes. The earlier M3 walking, hip-access and
  carried-route suites are excluded from regression-runner discovery.
- The movable work platform has authored paths to all bulky/limb docks, grounded
  travel, guarded height stops, occupied-deck rejection for transfers, swept
  obstruction stops, explicit reversal and interrupted resume. It parks before
  source roll; the later bulky/arm controllers still need that shared interlock.
- The common X14 leg holder replaces M3's old rail controller. The prepared foot
  raises, advances and turns through three supported carrier phases; the three
  crane tasks then deliver the same physical shin/fork/spar identities. Frame
  crossmembers provide the holder's exposed contacts. Supported roll raises to
  Y3.1; the cradle can park/retrieve at X22, stow its bolster and index to a hip lane.
- The left-leg route opens shared access, travels, turns and docks at the actual
  socket. The rear socket gusset and supported turn were corrected for measured
  solid contacts: during the first22.5° of turning the root lowers0.30 m, then
  docks upward1.20 m to the unchanged final sole datum1.40 m. The source height
  stays1.85 m. Dimensions for all new holder members are authored in layout data.
- Hip work now includes stop-cage halves/four screw pairs, three complete carried
  cartridges/six eye pins and three operated captive neutral locks. These extend
  the existing ring, with compatible physical copies and ordinary manual slots.
  The holder requires both retained hardware and all neutral locks before release.
  It opens, lowers, withdraws1.4 m, compacts and shifts2 m outboard before returning
  empty. Local reacquisition leaves the retained leg stationary. This is local
  correction coverage, not a resumed full-teardown acceptance campaign.
- Interrupted carrier, source roll, withdrawal and reacquired-holder sessions
  save atomically and restore into fresh scenes. JSON numeric stop validation and
  resuming a stopped roll were corrected. Invalid unsupported/lock states are
  rejected. Old cabinet solids no longer remain behind the relocated M3 bins.
- Ground crossing gates close before rail travel, remain outside the empty-holder
  sweep and reopen at the source/dock. Their swept arcs and the ground corridor
  have occupancy interlocks, with stop/resume and saved angles. The central crane
  console moves to(7.8,0,22.8), clear of the gate arc and mobile-platform parking.
- Both legs now have independent physical stock and hip connections. Right-hand
  source meshes and receiving transforms are reflected together while runtime
  frames remain right handed; the knee axle enters from outward+X. Shared hardware
  remains interchangeable. The current content audit, including shoulder connections, covers335 extension identities and
  209 playable leg/hip/torso slots, with135 additional prepared-foot identities retained
  from the base scenario. The shared holder can select an empty build, rejects
  replacing occupied construction and saves its selected assembly and hip lane.
- Both prepared feet start in the foot bay on separate sole supports. Four crane
  ends attach to exposed FA-100 rail faces and deliver either existing assembly
  through the authored lift/Z7/cross-workshop/lower route. The same crane retains
  the two-end structural-part tasks. The carrier accepts the matching foot only
  at dispatch, then performs its three-phase handoff. Its empty return leaves the
  mounted foot stationary and extends the sole pads ready for the second load.
- The two-leg mechanical sequence now covers both source deliveries, all six
  structural crane loads, distinct hip retention/neutral locks, second-leg docking
  beside the first fitted leg and both empty-holder returns. Saves reopen in fresh
  scenes while either prepared foot is suspended and after both legs are retained.
  Stock racks are staggered longitudinally because adjacent1.6 m crossmembers
  otherwise overlapped at1.5 m rack spacing.
- The prepared pelvis/waist now starts on the bulky fixture. Its braked height
  adjustment carries the same assembly, and four source clamps open only while
  four crane ends take weight. The source/gantry poses replace the former fixed
  pelvis rule. The shared crane requests the upper-platform delivery configuration,
  follows the authored rise/cross/approach/lower route and transfers ownership only
  at the exact bearing-contact pose. Four local gantry jaws and two captive waist
  neutral pins establish release and leg-docking security. Interrupted source
  contact, fixture height and jaw closing restore in fresh scenes; a stopped jaw
  resumes at its own handle.
- Prepared pelvis context now includes the waist bearing/yoke/cradle, lean
  cartridges, chest seats/keys and lifting eyes. These are supplied simplified
  internals. Actual solid integration trimmed the waist-level work fingers away
  from the socket crowns, put fixed jaw handles below the deck/outside the bridge,
  and raised the lifting-eye support bars above the docking balls. The prepared
  handling envelope now includes the existing descending clevises/catches;
  those were omitted from the earlier socket-only bound.

- The chest/cockpit starts on a passive storage support, transfers by four-end
  crane to the emptied bulky fixture, then travels upright onto the waist. The
  single fixture changes physical contact inserts only when empty and lowered;
  four chest clamps close after seat contact. Interrupted clamp and height phases
  preserve the same assembly identity. Task switching never spawns or repositions
  the chest. Its four outward lifting handles are distinct from the load pads.
- The pelvis manual adds the chest seat, four separate M36 washer/bolt pairs and
  two service leads. Structural retention precedes rig release; service work
  requires the shoes stowed. Prepared context preserves the rear core portal,
  waist key/bolt bores and projected neck pilot. Local supported correction lifts
  and reinstalls the same chest; unrelated leg-holder support no longer blocks
  chest undo. Details and source/storage coordinates are in the
  [chest implementation record](../../torso/chest-and-cockpit.md#robot-workshop-prepared-implementation--2026-10-24).

- The prepared core uses the same bulky fixture with keyed saddles, a passive
  source store and two crane ends. Rear delivery follows the measured low bypass,
  outboard lift and high crossing. Captured guides take forward support before
  bridge release; the unloaded equalizer folds/shifts aft before further insertion.
  Four captive bolts and rear connection remain separate local operations. Saves
  preserve handoff, rig adjustment, one-end insertion and supported correction.
  Core geometry, guides and rigging are checked against the receiving chest.
- Rigging-path verification initially omitted complete spreader/cable geometry.
  The resulting gate-parking and equalizer-envelope conflicts were implementation
  misses against the existing plan. Inboard barrier parking preserves the selected
  bypass; subsequent core sweeps include the full rig. Apply this complete-envelope
  preflight before expanding backpack and arm deliveries. The user's feedback is
  retained in the active next-steps document.
- The prepared backpack now has physical source/storage geometry, matched bulky
  inserts, two-ended storage transfer, height adjustment and supported return to
  clear the shared fixture. Full source/rig preflight follows the selected rear
  waypoints and checks the closure sweep with articulated strut geometry. It also
  checks the rig against its own payload and rejects low-crossing/low-spreader
  counterexamples. The chest manual now owns seating, two hinge pin/keeper pairs,
  two strut-base pin/keeper pairs and two interchangeable service runs. Captive
  open locks establish support before rig release; closure requires both crane
  ends to take weight before either lock releases. Two lower draw latches precede
  rig release and small service covers. The same crane console operates weight
  transfer and Stop/Resume/Open/Close; local controls operate struts/locks/latches.
  Articulated parent poses, telescope deployment and partial weight transfer save
  and restore, and supported keeper correction preserves stock identity.
  Dimensions and the exact playable boundary
  are in the [backpack source record](../../torso/backpack-and-power.md#robot-workshop-backpack-source-and-route-preflight--2026-10-24).

- Both prepared arms now have 22 source pieces each, declared passive supports,
  actual structural contact/lifting pads and handed B eyes. The chest contains
  fixed A clevises/C-bridges during source preflight. The single retained cassette
  has connected feet/rails, six folding clamps and four lifting pads; floor
  bearings are flush to preserve leg-wheel travel. Complete-body/full-rig checks
  include the cassette crossing above the real horizontal foot, both mirrored
  upend/yaw/splay paths, the fitted torso/legs/opposite arm and parked equipment.
  The source check found the 0.65 m pre-seat approach crossed a fixed front A
  clevis. The authored correction uses 1.13 m along the same seating axis;
  upper rig anchors also stay outboard of the fixed cup. Both corrections have
  negative counterexample checks. See the [arm source record](../../arms/shoulder-and-upper-arm.md#robot-workshop-source-and-full-rig-preflight--2026-10-24).
  The subsequent retained-cassette and arm-delivery controls are integrated below.
  Pauldrons and release of the supplied joint/digit restraints remain incomplete.

- The cassette is now one tracked reusable equipment assembly, projected from
  the same blockout source plus four captive floor-lock pins/handles. The old
  duplicate static cassette is disabled. The shared crane transfers this same
  cassette and its retained arm between front parking and the common station.
  It carries the complete frame/arm/rig geometry; the hook trims over the combined
  nominal source mass centre. Floor locks release while the crane takes weight
  and engage at receiving contact before any end can release. The arm keeps its
  original support, identity and manual state throughout. Shared occupancy blocks
  the leg cradle until the cassette parks again. Interrupted source lock release,
  suspension and receiving lock engagement survive fresh-scene saves.

- Both arms now use the same four-end crane after it puts the retained cassette
  at the station. Six telescopic clamps retract0.40 m before folding; this clears
  the forearm ports throughout motion. The live route preserves all measured
  rotations and sweeps the full7.6 m rotation radius, complete rig and taglines.
  The right arm transfers from its passive store onto the cleared cassette.
  Each chest-manual branch adds31 external pieces across32 slots: complementary
  ring halves, four washer/bolt pairs, a handed keyed brace and two pin/keeper
  pairs, three compatible drive cartridges with six pin/keeper pairs, and an
  isolated service harness. Brake confirmation and a progressive load-transfer
  phase establish independent support before services and rig release.
  Interrupted clamp, upend and weight-transfer states restore; local keeper
  correction preserves the arm and consumed hardware identities. Source fit
  checks cover both assembled shoulder bores and neutral brace/drive clearance.

Mechanical evidence for every increment, through the paused 18-case run, is in
the [evidence record](m3-wide-evidence-20261024.md). These are mechanical
results only; walking, reach, visibility, connection access and presentation
remain the user's playtest.

Remaining work, in implementation order. The executable task breakdown is in
[handoff/README.md](m3-wide-handoff/README.md); its task files override older wording here.

1. Baseline commit and the right-foot carrier return in the full-sequence test (task 01).
2. Turn off M3 saving and remove save/restore checks from M3 tests (tasks 03–04).
   See [Saves and checkpoints](../robot-workshop-plan.md#saves-and-checkpoints).
3. Extract the scripted stage sequence shared by tests and the `--m3-stage=<name>`
   development launch flag (tasks 05–06).
4. Add one generic receiving interface and a shared occupancy register, then the
   pauldron carriers/panels and release of the supplied arm joint/digit restraints (task 07).
5. Head, in its specified order: crane pieces, then hand-carried pieces and crown
   (tasks 08–09), including the head-piece bulky-fixture inserts.
6. User playtest handoff checklist (task 10).

Deferred and unassigned: M3 saves and checkpoints; the chest's 60° bare-frame
service tilt (only needed once chest preparation is built; the prepared chest stays
upright); removing the historical M3 branch in `leg_rail.gd` and obsolete geometry
keys; migrating the existing core, backpack and shoulder receivers.
