# Structural left leg and hip assembly prototype

Revision: 2026-10-22. This is the playable structural subset selected for the
expanded workshop. It develops the existing confirmed shin, detachable knee fork,
integral thigh ball and hip assembly split-ring concept. Dimensions below are selected
prototype working interfaces, not a completed engineering design or a change to
the confirmed robot proportions.

The authoritative generator is
[`author_leg_prototype.py`](../../game/workshop/tools/author_leg_prototype.py).
It produces `leg-prototype-definitions.json`, the scenario additions in
`leg-prototype-content.json`, and schematic catalogue SVGs. Independent meshes
are constructed from its descriptors by `leg_source_geometry.gd`. FA-01 meshes
continue to come from the existing GLB; this extension does not regenerate it.

## Frame and scope

All source dimensions are metres, with Godot X toward robot right, Y upward and
−Z forward. The leg's logical origin is the ground reference below its ankle;
joint heights remain ankle 1.0, knee 5.1, hip 9.2. The existing `foot` keeps its
definition and physical children and mounts in `left_leg.foot` at
`[0, 0.8, -0.7]`, compensating its existing `FOOT_CENTER` frame. Its existing
`complete` milestone is required before docking. The leg adds no inventory object
for its logical container.

The hip assembly frame has hips at X±1.1, Y0, Z0. Its left leg mount puts the leg origin
at `[-1.1, -9.2, 0]`. At the gantry's selected Y10.6 hip height, the standing leg's
ground reference is therefore Y1.4. This lift is a workshop placement, not a change
to the robot's proportions.

`structural_ready` means all structural pieces and connection hardware in this
prototype are fitted. Hydraulic knee/hip actuators, electrical and hydraulic
services beyond the main ankle disconnect, armor, calf thrusters and functional articulation are deferred. The
ankle and knee remain mechanically braced by handling equipment. Braces are
equipment context and are not false robot inventory. The original foot's other
preassembled structures and mechanisms retain their previous boundary.

## Physical parts and ownership

| Owner | Physical pieces | Quantity |
| --- | --- | ---: |
| Left leg | LG-100 structural shin | 1 |
| Left leg | LG-110 detachable knee fork | 1 |
| Left leg | LG-120 spar, neck and ball as one manufactured part | 1 |
| Left leg | LG-130 knee journal bearing | 2 |
| Left leg | LG-135 knee thrust spacer | 2 |
| Left leg | LG-140 shouldered knee axle | 1 |
| Left leg | LG-150 axle retaining cap | 1 |
| Left leg | Existing H-36090 and W-36 flange pairs | 4 + 4 |
| Left leg | Existing FA-605 complete main harness, with both plugs | 1 |
| Left leg | LG-H12050 cap screws and LG-W12 washers | 2 + 2 |
| Left leg | LG-H24100 fork bolts and LG-W24 washers | 4 + 4 |
| Hip assembly | PV-120 semicircular retaining halves | 2 |
| Hip assembly | PV-H24140 ring bolts and shared LG-W24 washers | 4 + 4 |

There are **40 new active physical identities**, including nine reused GLB
hardware sources that were previously static context. Combined with the original
135 playable foot/pad/actuator identities, there are **175 active pieces**, six
logical assemblies, 31 left-leg slots and 11 hip assembly slots. The preassembled hip assembly
bridge, both distinct bolted socket housings and four socket-to-bridge bolts are
source geometry only; they add no stock or installation slots. The right socket
is context without a right leg or ring supplies.

Numbered instances of LG-130, LG-135 and PV-120 are interchangeable within each
type. The PV-120 rear destination rotates an identical semicircular half by 180°
around Y; it is not a handed variant. All eight LG-W24 washers share one stock type
across the fork and hip assembly. Compatible identity, source geometry and destination
pose remain separate, including when these copies are swapped.

## Ankle and shin

The source adapter FA-201 has its existing 520×440 flange ending at Y1.380 and an
integral **180×100×20 mm** key ending at Y1.400. The new shin baseplate is
540×440×30 mm at Y1.380–1.410, with a real 182×102 mm female recess, closed above
by the 300×200 mm narrow beam. The small recess allowance is a selected prototype
fit; it follows the actual source key rather than assuming an 80×60 key.

Four Ø38 bores lie at X±200/Z±150 mm. The existing exact source pairs are
`H-36090__001..004` with `W-36__021..024`, respectively. The source geometry was
authored at a head-bearing datum Y1.386, before the shin's 30 mm plate existed.
Each explicit slot snap origin therefore moves its existing source origin
**+30 mm in Y**, preserving its baked orientation. Washers then occupy
Y1.410–1.416, and the bolt head bears at Y1.416. A 90 mm downward bolt crosses
the 6 mm washer and 30 mm plate and engages 54 mm into the adapter. Heads remain
outside the 300×200 beam with the existing Ø80×120 tool approach envelope.

The main electrical connection is a single playable FA-605 installation after
the four ankle bolts. Its original source ID `FA-605__001` includes the complete
routed cable and both plugs. The junction socket FA-604 and existing guide clips
remain preassembled foot context. No second cable or plug inventory is created.
The source's upper plug center is `[.250, 1.400, -.100]` with its outward axis
parallel to `[.080, .160, -.050]`. A receiving sleeve integral to LG-100 follows
that exact axis, centered 34 mm beyond the plug center. It is Ø48 outside/Ø34
inside×32 long; the source's Ø32 plug collar has 1 mm radial sleeve clearance.
A small integral side stay connects the receiving sleeve to the shin beam while
clearing the plug approach. Electrical contacts and the keyed disconnect's
production detail remain simplified; the original source plug is retained.

The manual includes a full-route diagram and a close connection view. Its three
`*-V-*` diagram sources are documented subsets of the socket, source plug and hip
ball; they are neither stock nor additional in-world components. Ankle bolt and
washer diagram offsets include the same +30 mm correction as their actual slots.

## Knee and detachable fork

The knee hinge is transverse along X at Y5.1. The shin's integral boss is
560 mm wide with a Ø300 bearing bore and Ø560 exterior. Two identical bearings
are OD298/ID204×120 mm, centered at X±210 mm; the selected 1 mm radial seat gap
and 2 mm radial journal gap are prototype running allowances.

The fork's two cheeks occupy X−500…−360 and +360…+500 mm. Each has a real Ø210
axle bore and Ø680 exterior. The axle's Ø200 journal spans X−500…+500 mm, and its
integral Ø300×40 shoulder sits immediately outside the negative-X cheek. The
positive-X end has an integral pad for two cap screws. The separate LG-150 cap
bears against that pad and is retained by two M12×50 screws, with heads accessible
from positive X. Bearings install before the fork, which straddles the boss, then
the axle enters from negative X. The cap closes the other side.

Two OD360/ID204×75 thrust spacers fill the spaces between shin boss ends and fork
cheeks, leaving **5 mm axial allowance per side**. They install before the fork
and axle. The fixture carries the parts while the unpowered hinge is unretained.
Reserve a full 1.2 m extraction aisle outside the negative-X knee side.

The fork crossbar connects both cheeks to its 680×600×40 mounting flange ending
at Y5.920. The spar's matching flange begins at Y5.920 and ends at Y5.960.
Four Ø26 clearance bores in the spar align with Ø21 tap-drill representations
in the fork at X±250/Z±200 mm. Four M24×100 bolts point downward through
4 mm washers, spanning both flanges, engaging the 40 mm threaded lower flange
and projecting 16 mm below it. Production thread detail is simplified.
Their head and tool access lies outside the central 300×200 spar and outside the
crossbar's 360 mm depth. A separate lower fork is a real bolted connection, not
a decorative seam in an integral thigh.

## Hip retention

LG-120's ball is Ø900 at Y9.2 and is integral with a Ø300 neck and the spar.
The matching socket is a spherical upper bowl of inner radius456/outer530 mm,
with **6 mm radial ball clearance**. Its lower cylindrical opening has radius460
and is open below; the lower mounting flange has radius490 clearance. The Ø900
ball can therefore enter vertically from beneath while the ring is absent.

Each identical PV-120 half is an 80 mm thick annular semicircle with inner
radius300 and outer680 mm. Installed halves occupy hip-relative
Y−430…−350 mm and close around the neck. At the top of the ring the ball section
has radius283 mm, leaving about17 mm radial clearance. The ring hole is smaller
than the 450 mm ball radius and captures the ball while clearing the 150 mm neck
radius. These are neutral-pose clearances; unrestricted articulation has not been
claimed or verified.

Four Ø26 clearance bores at 45°,135°,225°,315° on a radius575 bolt circle mate to
Ø21 tap-drill representations in the threaded socket flange.
Four M24×140 bolts enter upward from below through 4 mm washers, cross
the 80 mm ring and engage 56 mm into the 70 mm socket flange. The two halves can
be independently positioned after seating the ball. Each half's washer/bolt
dependencies require that half; releasing hoist load requires **both halves and
all four bolts**. The parent hip assembly manual owns the child seating and this
retention; the leg manual owns internal construction.

The preassembled 2.7 m hip bridge is behind the sockets at Z+.65, clearing the
balls. Both socket housings have rear attachment lugs with two existing-context
bolts each. These contextual bridge connections are simplified blockout geometry;
they are not an additional playable hip assembly-building branch.

## Handling and manual contract

The foot starts at `support:foot_carrier` and the logical leg at
`support:leg_fixture`. Shin, fork and spar start at their own named racks;
retaining halves start at `pelvis_ring_rack_1/2`. These pieces use
`carry_class: equipment`. Smaller bearings, thrust spacers, axle and cap are hand
or two-hand carried; loose fasteners use pockets. Each equipment slot names the
authorized source support. The hoist receives the structurally ready leg and is
the authorized source/output for the hip assembly's `left_leg` slot. It must be
reacquired before releasing retention or removing the supported leg.

The foot carrier remains at dispatch during transfer. Its prepared foot is
reacquired by the separately authorized `foot_hoist`, lifted clear, moved through
the front aisle, and lowered into the leg fixture. Both `foot_carrier` and
`foot_hoist` are authorized sources for the leg's foot slot; the controller owns
the continuous equipment transition. A carrier traveling with the mounted leg
would obstruct the later full-leg route.

The selected personnel platforms include a 1.2 m ankle work stop: ground-level
views approach below the receiving adapter's upper flange and key, obscuring
some upper washer and bolt seats. Knee parts use the 3.8 m stop from
their own outward-facing sides; fork bolts use the 5.2 m stop. Authored hardware
targets lie on exposed head/washer faces rather than the shank's bounding center.

`content.equipment` supplies bounded source rack positions and slot ownership to
the equipment controller. These staging positions may be relocated with the
workshop layout; physical source coordinates and snap poses must remain intact.

The manual has eight installation pages plus one structural status page for the
leg, and three installation pages plus one status page for the hip assembly. Component
lists derive only from each installation page's unique slots. Status pages are
progress/navigation and add no supplies. Assembly readiness and child completion
are retained when the hoist removes and reinstalls the leg.

## Validation evidence and limits

Run `python3 game/workshop/tools/author_leg_prototype.py` to regenerate content and
run its stock, source identity, dependency and unique manual coverage audit. Run
`./play.command --headless --script tests/leg_content_test.gd` for the focused
content/model/interface checks. The suite constructs the full original foot
branch, docks it, builds the structural leg and main disconnect, transfers and seats it, installs
retention, saves/restores exact nested state, reverses retention, and reinstalls
the same leg. It deliberately swaps compatible copies. Triangle checks inspect
the actual generated key recess, shin and fork bores, bearing journals, socket
insertion/seat clearance, and the reused GLB hardware pose correction.

The procedural pieces are blockout meshes assembled from simple closed
primitives; integral features may contain internal overlapping faces. Fastener
threads and production surface details are simplified. The checks are authored
graph and bounded geometric/behavior evidence, not structural analysis, complete
collision-free motion planning or rendered approval. No rendered visual review
was requested or performed. Workshop equipment clearance, access-lift reach,
motion sweeps and end-to-end save UI behavior require their integration suites.

The integrated desktop audit is
`./play.command --headless --fixed-fps 60 --script tests/leg_build_test.gd`.
Its latest 2026-10-22 run passed **539 checks and all 35 new hand/pocket
installations**. It stages only the separately regressed original foot branch;
new equipment pieces use the real controller and movement, and all new hand/pocket
connections use actual drawer/shelf E collection, ordinary desktop target,
valid preview and click. Every operator setup settles on the actual floor or
specified work deck at its expected height. All seven hand-carried parts travel
through real walking and occupied personnel-lift physics, including the axle
from the west side and cap from the east. Opposite compatible bearing/spacer
copies retain their consumed identities and match destination source triangles.
The audit also rejects a wrong-size washer without consumption, checks runtime
page quantities and diagram updates, and reaches every underside hip fastener.
Evidence is `game/workshop/verification/leg-build-audit.json`; the routine's
stdout was retained at `/tmp/leg-build-test.log`. No images were captured.

## Leg-bay trial contracts (archived)

The layout-trial and equipment-trial contracts that followed this structural
leg (2026-10-23) are [archived](history/leg-prototype-trial-contracts.md). Those
trials were removed when the workshop became one robot game; their accepted
handling rules are kept in the [workshop state](workshop-state.md#active-rules).
