# Leg-bay trial contracts (archived 2026-10-25)

*Moved verbatim from [leg-prototype-interface.md](../leg-prototype-interface.md) when the trials were removed.*

## Provisional M1 layout and support contract — 2026-10-23

This addendum describes the isolated M1 scale trial in the
[active continuation plan](../leg-workshop-next-steps.md), pending the requested
human playtest. The preceding sections remain the implemented normal workshop
contract. M1 does not change the generator, recipes, physical stock, canonical
source geometry or existing manuals. Its dedicated layout/controller/staging
scripts are authoritative for the runnable trial; the dimensions below record
the coordinated spatial decisions, not approval of the later gameplay workflow.

### Frames, staged load and ownership

Keep metres, Godot X right/Y up/−Z forward and the existing leg ground-reference
origin. Apply horizontal orientation to the `left_leg` parent only. Its foot
mount remains `[0, .8, -.7]`; the foot runtime's `−FOOT_CENTER` source frame
already compensates that offset. The pads and pitch actuator retain their own
source/anchor transforms and mounted identities. Do not rotate source vertices,
rewrite slot poses or apply another foot-center correction.

The disclosed test load contains the complete existing foot branch and all
31 structural-leg slots: **165 installed physical identities**, including the
two pads and complete pitch actuator. The remaining ten identities are the two
pelvis retaining halves and their eight washers/bolts; they are not part of the
sample leg. Six logical assemblies remain containers, without extra inventory.
Preparation uses normal model installation/support rules and runtime mounting,
then syncs installed visuals and the compound collision. This is staged content,
not evidence that the new construction or retention interactions are playable.

The corrected M1 uses scenario-local `m1_leg_rail` support without rewriting
production support declarations. The holder owns and visibly supports the load
through horizontal travel, tilt, upward docking and loaded Return. Socket entry
does not release it or transfer ownership to a sample receiver. The appearing
receiver and its automatic empty-fixture loop are removed by the M1 correction.
One controller moves the top-level load; mounted children inherit that transform
with frozen child physics, rather than competing carry motion.

Advance at the dock explains that the hip retainers must be secured. Return is
available before retention begins and is rejected once any retaining half or its
hardware is fitted. Partial retention cannot release the holder; the complete
authored set is both halves and all four washer/bolt pairs, with genuine pelvis
ownership. M1 does not expose fastening, mounting or holder-release gameplay,
so the playable trial ends at docking and returns the unfastened leg. No pretend
attachment-complete control substitutes for the M2 interaction. An externally
staged pelvis-owned test state is distinct from normal rail-owned M1 docking;
M1 must reject unsupported movement rather than transform a pelvis-owned child
through the rail controller. Ball seating alone is not retention.

The trial uses a session-only save adapter with no save-store or normal save-codec
dependency. It neither loads nor writes either normal save profile or backups.
Restarting the trial reconstructs the staged sample. Normal content and the
fingerprinted legacy layout/equipment/lift files remain separate from the M1
scripts. Persistent rail/crane state is later work, requiring explicit versions
and validation rather than interpreting legacy hoist saves as rail saves.

### Selected provisional spatial dimensions

A coordinated these values with B/C before implementation. All remain subject
to the actual M1 sweeps and human feedback; the runnable source supersedes this
table if a subsequent clearance repair changes a value.

| Element / frame | M1 selection |
| --- | --- |
| Left rail and reserved right rail | X11.9 active; X14.1 reserved, with no playable right leg |
| Knee reference | Leg-local `[0, 5.1, 0]`; world Z14.5 at construction, Z26 at the bay |
| Horizontal home leg root | `[11.9, 1.35, 9.4]`, rotation `Rx(+90°)` |
| Horizontal foot logical frame | `[11.9, 2.05, 10.2]`, derived through the unchanged child mount; a loading reservation, not an implemented foot transfer |
| Horizontal travel | Knee Z14.5 → 26, retaining Y1.35 and `Rx(+90°)` |
| Tilt root, θ90° → 0° | `[11.9, .5 + .85 sin θ, 26 − 5.1 sin θ]`, rotation `Rx(θ)`; equivalently knee Y `.5 + 5.1 cos θ + .85 sin θ` |
| Upright approach and dock | Root `[11.9, .5, 26]` → `[11.9, 1.4, 26]`; left hip ball reaches `[11.9, 10.6, 26]` |
| Pelvis frame | `[13, 10.6, 26]`, preserving local left mount `[-1.1, -9.2, 0]` |
| Rail ladder and contacts | Ladder on leg-local +Z side at `.48`; shin/thigh jaws at local Y2.8/7.0, world horizontal Z12.2/16.4; a telescoping mast and world-aligned crosshead connect the pivot to the bogie |
| Return route | Reverse the same loaded docking, tilt and travel route; the synthetic empty-holder detour is removed from M1 |
| Personnel lift | Origin `[9.6, 0, 24.3]`, deck 2.6 × 2.6 m, yaw π for front boarding; stops .15/8.4 m |
| Gantry | Columns X8/18 at Z30.8; pelvis support arms Y10.65 with bearing faces Y10.83; no sample capture arms |
| Local controls | Source panel `[9.2, 0, 11.4]`; bay panel `[5.1, 0, 24.2]`; Advance / Stop / Return, one sample motion at a time |

The initial blockout used a lateral empty-return lane after a synthetic capture;
that route was confusing in play and no longer belongs to the M1 trial. A real
empty-holder route can be evaluated after actual retention is playable. The
right-leg reservation remains separate. The 1.2 m negative-X knee extraction
aisle remains a constraint on supports, source equipment and operating positions
throughout horizontal construction; X-axis tilt preserves the axle/cap's opposing
work faces. These reservations do not prove walking, tool access or swept
clearance by themselves.

### Crane reservation for the later representative loop

M1 labels the **empty** source rack as the **Upper-leg beam** source and explains
that this knee-to-hip beam is already installed in the supplied leg. There is no
second LG-120 identity, interactive cable or transfer shortcut. Its passive console
pedestal and the rack reserve the following M2 design. Their agreed
anchors reserve the following M2 design; no crane commands are implemented by
this contract.

| Element | Selected reservation |
| --- | --- |
| LG-120 source flange origin | `[7.6, 1.35, 15.34]`, `Rx(+90°)`; source Z span15.32–19.05 |
| Receiving flange origin | `[11.9, 1.35, 15.34]`, `Rx(+90°)`, rail at home only |
| Magnetic marked points | LG-120 source-local `[0, .65, -.10]` and `[0, 2.74, -.15]`; source-world `[7.6, 1.45, 15.99]` and `[7.6, 1.50, 18.08]` |
| Lowered beam | Y2.15; keep vertical cable approach clear of fork and flange fasteners |
| Console | Passive pedestal center `[4.9, .6, 21]`, approached along the west route; interactive console design remains held |
| Transfer flange waypoints | `[7.6, 1.35, 15.34]` → `[7.6, 2.10, 15.34]` → `[11.9, 2.10, 15.54]` → `[11.9, 1.35, 15.54]` → `[11.9, 1.35, 15.34]`, retaining `Rx(+90°)` |

The final .20 m move is axial seating toward −Z: the original horizontal flange
plane becomes vertical under `Rx(+90°)`. Rail jaws must leave both marked points,
fork-flange bolts and their tool approach exposed. B's generated-mesh probe found
both floor-eye rays reachable (under .87 m), clear vertical cable rays and at
least 52.9 mm analytic ball clearance around the far 80 mm pad. Its coarse volume
center estimate lies between the two points; this is support plausibility, not
load engineering. The probe and log are retained under
`game/workshop/verification/m1-crane-contract/`.
Actual rack/receiver/beam/player sweeps and the walked attachment journey remain
M2 checks; this probe does not complete them.

### Later content/manual changes, held after M1 (historical proposal)

The M2 feedback revision below supersedes this proposal’s retaining arm and
call/transfer command vocabulary. Other future construction work remains held.

The existing support and manual audit found no required content regeneration for
the scale trial. Following M1 acceptance, the representative workflow will need:

- A real rail support and parent mount declaration replacing the whole-leg hoist
  route, while preserving the same completed `left_leg` identity. The complete
  foot needs an authored source-to-horizontal-fixture handoff; the M1 populated
  sample does not establish that handling route.
- A real `service_crane` support authorized by `left_leg.spar`, with ownership
  moving from `leg_spar_rack` to that crane before supported installation. Source
  support cannot release with zero or one magnetic endpoint. After seating, the
  model owns LG-120 in the spar slot, while crane assistance remains until all
  four fork washer/bolt pairs are secured. Receiver contact precedes detachment;
  rail movement is unavailable while the crane remains attached.
- Instructions for horizontal foot/shin/fork/spar construction, reachable work
  faces, local rail travel/tilt/docking and central-console crane delivery. The
  present rack-control and whole-leg-hoist prose remains production behavior
  until those interactions are implemented. Parent pelvis instructions continue
  to own child seating and retention; leg instructions own internal construction.
- Per-half retention pages: `ring_1` plus `ring/washer_3`, `ring/bolt_3`,
  `ring/washer_4`, `ring/bolt_4`; then `ring_2` plus washer/bolt pairs 1 and 2.
  These mappings follow the actual angular slot enumeration. Existing dependency
  edges already permit this order. Each page must list its one half and four
  fasteners exactly once, then explain release of that half's assist before the
  next half. Keep identical halves interchangeable and all eight LG-W24 washers
  shared between fork and pelvis; do not invent handed variants or cross-half
  fastening prerequisites.
- Support authorization for the eventual retaining-half assist/carrier, including
  its return output and occupied-support rejection. The arm/carrier remains a
  proposed interaction. Both halves and every retaining washer/bolt pair are
  mandatory before holder departure. The latest user decision removes the extra
  external stabilizer/capture-frame control from that release gate. Reacquire
  holder support before undo; deliberate recovery must be reconciled with the
  restriction on Return while retention is fitted.

Crane cable ends are workshop equipment, not robot inventory. B owns a dedicated
console-independent command/status module; A owns spatial integration and ordinary
input dispatch. The proposed actions are call, transfer, stop/resume and return,
with E pickup, aimed click attachment and Q return/stow for individual endpoints.
The console opens through E and closes through Q/Escape, dispatching only within
reach. Status identifies phase, attachment count, support owner and the current
availability/blockage reason. A later PDA can reuse the commands without an
unlock or UI commitment at M1.

The later versioned crane snapshot must identify its allowed task/motion profile,
phase and progress, load/beam poses, source/destination reservations, engaged
contacts and each stable endpoint's stowed/held/attached state and point ID.
Derived cable lengths must follow validated load/beam/player poses. Validate
against a detached saved model before applying live state; reject contradictory
ownership, endpoint, route and fastening claims without mutation. Partial rigging,
seated-but-unfastened assistance and blocked travel need fresh-scene restoration
checks when those interactions are implemented.

### Audit evidence and unresolved acceptance

On 2026-10-23 the unchanged generator's in-memory stock/source/dependency/manual
audit passed without writing assets. Generated JSON matched the authority within
`1e-13` numeric tolerance, with existing catalogue paths checked; six harness
rotation values differed only by host floating-point rounding below `1e-14`.
The focused native command
`./play.command --headless --log-file /tmp/gundam-m1-content-engine.log --script tests/leg_content_test.gd`
passed **373 checks**. Evidence is
`game/workshop/verification/m1-content-contract-audit.json`,
`game/workshop/verification/leg-content-audit.json` and that engine log. These
results establish unchanged content behavior, not M1 route clearance or acceptance.

The M1 spatial review must sample every actual descendant mesh, including
preassembled foot context: `runtime.visual_pieces()` alone omits that untagged
context. Check loaded toe/heel, pads, actuator, knee and support geometry across
travel, tilt and docking, including between input and physics ticks, then the
supported loaded Return. Empty-fixture withdrawal needs actual retention and is
held for the later interaction checkpoint. Keep the negative-X knee extraction aisle,
both fastening sides, personnel boarding/work access and second-leg reservation
clear. Future upper-body headroom and rear/arm approaches remain layout constraints,
not new playable branches. No rendered review was requested or performed; player
judgment of support readability, walking routes, lift scale and the provisional
layout remains the M1 checkpoint.

## M2 isolated content and equipment contract — 2026-10-23

M2 extends the accepted M1 layout with two separately saved examples behind
`./play.command -- --m2-workshop`: **Hip retainer** and **Crane delivery**.
The authoritative generator's `--m2` option writes only the four new files
`m2-retention-definitions.json`, `m2-retention-content.json`,
`m2-crane-definitions.json` and `m2-crane-content.json` under
`game/workshop/assets/`. Its `--check-m2` option audits those files without
writing. Normal generation, normal/foot saves and M1 remain separate.

### Loading, scope and identity

Load the selected definitions overlay after the normal pitch and leg overlays,
merging `parts` and `assemblies` with replacement. In the normal leg content,
replace `parts`, `parents` and `equipment` with the trial values. Erase every
support named by `content.m2.remove_supports`, then merge the trial `supports`.
The erased old ring racks restrict inventory to physical IDs omitted by M2;
leaving them behind would invalidate scenario configuration. They are not aliases
for the new lift shelf. Keep the original source descriptors and contextual meshes.
Append the selected extension stock to the original 135-piece pitch scenario;
the foot's initial location remains `support:foot_carrier`.

`content.m2.staged_slots` supplies the authored construction boundary and
`playable_slots` supplies each trial manual's unique installation coverage.
Full slot graphs, compatibility and structural milestones remain intact.
`controlled_mount_slots` identifies the pelvis seat performed by the rail,
explained on a supplies-free overview page. Equipment staging must use supported
model transfers/installations rather than write model ownership directly.

| Example | Supplied construction | Playable stock and instructions |
| --- | --- | --- |
| Hip retainer | Complete existing foot/leg: all 31 leg slots, 165 installed physical IDs; leg starts on its home rail, with empty pelvis mounting and retention | 170 total IDs: the supplied 165 plus `PV-120__001`, `LG-W24__007/008` and `PV-H24140__003/004`. Seat `ring_1`, then fit its washer/bolt pairs 3 and 4. |
| Crane delivery | Complete existing foot and the graph through shin/knee/fork/cap: all leg slots except `spar` and `fork/*`, currently 22 slots and 156 installed IDs | 165 total IDs: the supplied 156 plus the sole `LG-120__001` and four loose `LG-W24`/`LG-H24100` pairs. Deliver the beam, then fasten all four flange pairs. |

The unused retaining half and its hardware are absent from the playable stock.
Automated replay substitutes `PV-120__002` for the representative half; both
halves retain kind `pv-ring-half`. `ring_1` still owns pairs 3/4 and `ring_2`
pairs 1/2. All `LG-W24` copies remain one compatible stock and pocket type.
Consumed physical UID remains separate from the slot's canonical `pose_source`.
The catalogue and M2 instructions call `lg-thigh-spar` **Upper-leg beam**, while
preserving that kind, family LG-120 and physical UID.

Each example has two installation pages. Retention covers one half followed by
only its two washer/bolt pairs; crane covers the beam followed by only its four
pairs. Context, overview and status pages have empty `slots` and add no supplies.
Neither the manuals nor the graph claim that one fastened half secures the hip.
The original complete-ring milestone still requires both halves and all four
washer/bolt pairs. Full horizontal construction and both-half handling remain M3.

### Real supports, contacts and commands

| Real support | Compatibility / ownership use |
| --- | --- |
| `leg_holder` | The existing `left_leg` assembly only; authorized pelvis-seat source and supported undo output |
| `m2_lift_shelf_0` / `m2_lift_shelf_1` | Hand-carried components; shared capacity of two one-hand or one two-hand component |
| `crane_rigging` | The sole `LG-120__001`; sole `left_leg.spar` installation source and supported undo output |
| `leg_spar_rack` | Existing beam stock source; crane takes ownership before seating, with no direct rack-to-slot authorization in M2 |

The rail/crane use `transfer_supported_item/assembly`, `install_supported`
and `undo_supported` with their actual support IDs. The M2 ring-half overlay now
uses `two_hand`; ring slots accept ordinary held installation. Ground stock,
held, loose, shelf and installed locations keep the same physical identity.
`store_carried_item` / `carry_supported_item` move hand components to/from an
authorized shelf support. Shelf capacity and physical sweeps gate storage and
lift travel. The obsolete M2 retaining carrier and stow support are removed;
legacy normal-workshop ring handling is unchanged.

Preserve accepted rail X11.9, knee-home Z14.5, bay Z26 and lift origin
`[9.6,0,24.3]`, deck 2.6 m square, stops .15/8.4 m. The beam's source flange
origin is intentionally **`[7.6,1.35,15.40]`**, rather than the earlier reservation's
Z15.34. The receiving origin remains **`[11.9,1.35,15.34]`**. Both use `Rx(+90°)`.
The source's independent 60 mm offset does not alter source vertices or the
receiving snap pose. Both beam stems lie over mesh-contact saddles at
Z16.0/17.6. Their bearing top is Y1.25,
matching the horizontal stem underside; the old stand top Y.96 left a .29 m gap
and is superseded. Receiver contacts use the same bearing height and Z stations.
Actual sweeps and player access are integration checks, not consequences of
the content metadata alone.

Crane endpoint IDs are `magnet_a`/`magnet_b`; compatible marked-point IDs are
`beam_near`/`beam_far`, at beam-source-local `[0,.65,-.10]` and `[0,2.74,-.15]`.
Either endpoint can occupy either free point. The version-2 flange route is
`[7.6,1.35,15.40]` → `[7.6,3.52,15.40]` → `[11.9,3.52,15.54]` →
`[11.9,1.35,15.54]` → `[11.9,1.35,15.34]`. The last .20 m is axial toward −Z;
a vertical drop cannot mate the horizontal assembly's flanges. Cable ends are
equipment, without robot inventory IDs. Both endpoints engage and visibly take
weight before source release. The receiving cradle takes contact before seating;
crane assistance stays until every flange washer and bolt is installed.

The crane console is modal: mouse look and walking are suppressed while it is
open. Pointer clicks or ↑/↓ with E select commands; Q closes and Escape pauses.
Up and Down are explicit vertical motions, with Go to each valid other location
offered only while Up. The held magnetic end is camera-local `[0,0,-.65]`.
The canonical crane snapshot stores station, elevation, current motion/progress
and endpoint contacts; route poses derive from these values. Source weight-taking
precedes rack release, and Down at the cradle includes the final axial seating.

The lift shelf sits on the side opposite the hip work corner. Small hardware
stays in pockets; no drawers or retaining arm ride the lift. Z undoes hardware
normally and returns the unfastened half to hands at its actual connection.
Partial retention still blocks rail Return. Complete removal permits real
pelvis-seat undo back to the rail, then loaded Return. One-half M2 never
authorizes holder departure.

### Persistence and content evidence

The generated scenario/equipment/route versions and M2 session are now 2. Trial save paths are
`user://m2-retention-save.json` and `user://m2-crane-save.json`; fingerprints and
resume/reset slots remain independent. Routes derive from authorized profiles,
never saved arbitrary waypoints. Detached saved-model/world validation must
complete before live mutation, and restore must apply parent-first. These versions do not replace full snapshot validation or behavior checks.

The focused native content suite is
`./play.command --headless --script tests/m2_content_test.gd`. Its 106 checks
passed for the feedback revision on 2026-10-23 for both profiles, alternate equivalent half UID, exact
staging/loose-stock boundaries, unique manual coverage, real-support installation
and undo outputs, rejected direct rack-to-beam seating, and unchanged complete
hip milestones. Evidence and per-page component counts are in
`game/workshop/verification/m2-feedback-20261023/m2-content-audit.json`; current
logs and the full 54-case regression report are under
`game/workshop/verification/regressions-20261023T092828.720004Z/`. The two legacy generated JSON files and all
16 leg/pelvis catalogue SVGs match their existing bytes; hashes are retained in
`game/workshop/verification/m2-legacy-assets-audit.json`.

These are authored-data and model checks. Actual walked equipment controls,
contact/sweep safety, fresh-scene saves and the combined M2 handoff require the
integration evidence. No rendered review is requested or claimed, and player
assessment of the shelf/carrying and crane remains the M2 human checkpoint.
