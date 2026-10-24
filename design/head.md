# Head

Last updated: 2026-10-24

[Design index](../ROBOT_DESIGN.md) · [Shared design rules](global.md)

Connected assemblies and clearance checks: [torso frame](torso/chest-and-cockpit.md), [shoulder pauldrons](arms/shoulder-and-upper-arm.md), [backpack](torso/backpack-and-power.md).

Dimensions and reference pose: [shared proportion layout](proportions.md#head-and-crest).

## Confirmed design

- **Primary purpose:** aesthetic presence and intimidation.
- **Appearance:** samurai-style helmet.
- **Equipment:** three small sensors: two cameras and one forehead range sensor.

### Samurai helmet, face, and sensors

- **Helmet silhouette:** an angular helmet top, a pronounced overhanging brow, and flared, stepped armor guards around the sides and back.
- **Face mask:** a stern warrior-like expression formed by angular cheek plates, a raised nose bridge, and a squared chin; use a removable mask assembly.
- **Crest:** two broad, upward-swept ornamental blades on a central forehead mount. Treat the crest as decorative; antenna functionality is not specified.
- **Sensors:** two small cameras recessed behind narrow eye openings, plus one small range sensor in the forehead below the crest mount. Colors, illumination, and detailed sensor technology remain open.

### Baseplate construction and assembly order

In the selected [whole-robot workshop route](game/final-assembly-plan.md#2-agree-the-major-section-assembly-sequence),
head construction follows the rear modules and both arms. Measure upper-platform
and crane access with the arms, shoulder armor and backpack already installed.
This overall order preserves the head's construction sequence below.

The user specified this construction sequence:

1. Begin with a simple neck “spoke” on the torso skeleton.
2. Attach the head baseplate to the spoke.
3. Attach the head sides to the baseplate.
4. Attach the head top to the baseplate-supported assembly.
5. Insert the sensors.
6. Attach the front faceplate.
7. Attach the samurai mask.
8. Attach the crown.

Use **top shell** for the structural roof installed at step 4 and **decorative crown/crest** for the ornament installed last. Keep the front faceplate and outer samurai mask as distinct components.

Preserve front access for sensor installation after the sides and top are in place. Sensor fasteners and connectors must remain accessible before the front faceplate closes the opening. Camera and range-sensor apertures must remain clear through the final faceplate, mask, and crest arrangement.

### Head mounting and installation details

- **Neck mount:** a fixed keyed neck spoke with a central wiring passage and a bolted baseplate attachment. The head has no independent neck articulation.
- **Rear closure:** two side-shell assemblies wrap around to meet at the back, carrying the flared rear guard plates. This preserves the user's side-then-top sequence without adding a separate main rear-shell step.
- **Sensor installation:** three separate sensor modules mount on a common carrier that slides into the open front after the top shell is fitted. Plug in the accessible sensor connections before fitting the front faceplate.
- **Panel attachments:** locating tabs and recessed bolts attach the side and top pieces to short mounting uprights on the baseplate. The front faceplate, outer mask, and decorative crown retain separate attachment points; the selected interfaces and access directions follow below.

## Working interface and access contract — 2026-10-24

These are selected working dimensions under the user's delegated detail-design
authority, preserving the confirmed concepts above. They are a bounded interface
and assembly-access design, not a manufactured inventory, structural certification,
source-solid check, playable implementation, or inspected render. The
[component-pipeline](../.agents/skills/gundam-component-pipeline/SKILL.md) and
[assembly-review](../.agents/skills/gundam-assembly-review/SKILL.md) workflows apply
to the later stages. No complete head is delivered by crane.

### Coordinates, fixed boundary, and ownership

Use robot coordinates **X right, Y forward, Z up**, metres, nominal soles Z0.
Head-local origin is `(0,0,15.40)` with robot-aligned axes. Raised workshop world
coordinates are `(13+X, 1.4+Z, 26−Y)`. Work requires neutral locked waist and
restrained shoulders at the 15° reference pose. The fixed head follows the chest
through waist motion; it has no neck bearing, motor, rotation, or tilt.

Preserve helmet X±1.00/Y±0.90/Z15.40..17.40, mask front Y+0.90, crest tips Z18.00
and working crest width 2.60. The flared side/rear guards remain part of the two
wraparound side assemblies. Bounds below allocate interfaces within that shape;
they do not turn the head into a rectangular solid.

| Connection or piece | Physical owner and installation responsibility |
| --- | --- |
| Neck bridge, spoke, seating flange, integral key, captive flange threads and loom through the spoke | Torso skeleton; prepared with the chest. This sheet specifies the mating contract. |
| Baseplate, receiving hub, short side portal uprights, lower panel seats and head harness | Head; its first gantry step seats/bolts/connects the baseplate onto the existing spoke. |
| Left/right wraparound sides, structural top and their integral frames/tabs/pads | Head; large pieces prepared separately, craned onto the already retained baseplate. The sides are handed geometries. |
| Two identical cameras, distinct range sensor, carrier and its short loom | Head sensor child; prepare the three modules on one carrier at the bench. The head manual owns installing/retaining/connecting that prepared child. |
| Front faceplate, samurai mask, decorative crown/crest | Three separate head closures with separate structural mounts and retention. Neither mask nor crown hangs from the faceplate. |

An assembly groups existing physical pieces rather than adding duplicate stock.
Hardware counts below cover these connections only. Repeated identical hardware
shares a compatible type; different thread/length or handed geometry does not.

### Torso spoke to baseplate

| Feature | Selected geometry and access |
| --- | --- |
| Spoke below the seat | Hollow Ø0.40 post centred X0/Y0; its Ø0.88 upper flange occupies Z15.30..15.40. The bridge remains within X±0.48/Y−0.95..+0.48/Z14.85..15.40, above the capsule roof Z14.75. |
| Hard seat | Flange upper face Z15.40; the head plate underside seats here. Load does not rest on a key tip, wire connector or bolt head. |
| Pilot and unique front key | Ø0.32 pilot rises **0.18 m above the unchanged seat**, to Z15.58. Integral front key X±0.04/Y+0.16..+0.20, Z15.42..15.58; upper 0.02 m is lead chamfer. Its orientation rejects a reversed head. |
| Receiving hub | Head plate X±0.72/Y±0.62/Z15.40..15.52; central Ø0.52 raised hub ends at Z15.64. Receiver bore Ø0.324, key slot 0.084 wide, forward end Y+0.204. These are working clearances, subject to actual mating-solid checks. |
| Seating stroke | Approach plate underside at Z15.64, 0.06 m clear of the pilot; lower 0.06 m to entry, then 0.18 m onto the seat. Total final approach 0.24 m. |
| Retention | Four **M24×160 bolts and 4 mm washers**, axes `(X±0.27,Y±0.27)`, enter down along −Z into torso-owned captive flange threads. Head/washer targets near Z15.56; no underside nut operation. Reserve R0.06 vertical tool cylinders to Z16.06. |
| Central services | Clear Ø0.12 axial passage through spoke and hub. Torso brings an isolated power/data loom and bond to front-facing disconnects near `(±0.10,+0.25,15.69)`. Head owns the mating connectors, strain relief and onward harness; plug/connect after all four bolts are retained, before the sides close access. |

Select approximately 0.04 m thread engagement within the upper flange for the
M24 joint; flange strength, final grip/thread length and bearing fits remain
engineering checks. The bolt-axis radius is 0.382 m; a 0.025 m washer radius
leaves about 0.033 m to the flange's 0.44 m outer radius. The R0.06 tool cylinders
remain outside the Ø0.52 hub by about 0.062 m. Keep bolt bores separate from the
Ø0.12 loom; an unconnected wire bundle is never a locating feature.

The pilot extension changes prepared-chest transport height to **4.28 m** from
seat Z11.30 to tip Z15.58: raised world top Y16.98, or source top Y5.13 at the
chest fixture's selected Y0.85 seat. It does not move the confirmed head plane.

Baseplate preparation includes two short side portal frames: front/rear uprights
near `(±0.64,±0.45)`, Z15.52..16.20, linked along each side at their upper end.
The craned baseplate includes these frames. Two upward-facing structural magnetic
pads at `(±0.62,0,16.20)` lie above its working centre of mass; the plate, rather
than the loom or pilot, remains crane-supported through seating and retention.
After all four bolts and service strain relief are complete, detach/stow both
ends from the open front **before fitting either side shell**. The upper portal
rail and absence of shells leave both pads and attached magnetic-end handles
visible from that work face.

### Wraparound side shells, rear seam, and structural top

Each side assembly includes its angular helmet side, flared guard plates, half
the rear closure, and an inner structural frame. Working bounds are the owning
half of X±1.00, Y−0.90..+0.58, Z15.52..17.08, with complementary narrow returns
at the centre rear seam. Both can be prepared upright on reusable fixtures; do
not add a separate main rear-shell stage.

The lower feet bear on baseplate seats. Rear vertically entered hooks engage the
rear uprights near `(±0.64,−0.45)`, with separated locating/capture regions near
Z15.78/16.10. The front feet locate on the front uprights. Lower the final **0.22 m**
into these tabs; captured rear geometry restrains fore/aft and lateral movement.
Two recessed **M12×100 bolts per side**, at `(±0.66,+0.52,15.80)` and
`(±0.66,+0.52,16.18)`, enter rearward along −Y into captive upright threads and
prevent uplift. Front-facing recesses remain outside the sensor opening. Rear
hooks and front retention supply the joint; no hidden rear nut or seam-bolting
operation is assumed.

The two rear returns use a vertical tongue/rebate seam open to entry from above.
Their fore/aft-offset returns occupy complementary material around X0, within
Y−0.90..−0.76; they are not two solids occupying the same overlap. Either side may
be fitted first. Lowering the other closes the seam while each remains separately
retained to its own uprights. Final skin overlap and weather sealing need actual
solid detail; a separate cover across this seam is not a main assembly step.

Each side uses two magnetic attachments on exposed **front- and rear-facing**
structural pad faces at `(±0.62,+0.58,16.90)` and `(±0.62,−0.90,16.90)`. The pad
pair brackets its working centre of mass fore/aft. The crane stays attached until
both front bolts are retained and the rear hooks are fully engaged. Release the
front end from the front landing and rear end from the matching rear flank. The
rear magnetic end is on the outer rear face, not an inward pad hidden behind the
wraparound skin. Remove both ends before installing the top. Small pad pockets
and attached-end handles face their work area directly.

The structural top is a hollow angular roof and pronounced brow within
X±0.92/Y−0.90..+0.70/Z17.08..17.40, with four corner fastening ears descending
to Z16.96. Four ledges on the side frames at Z17.08 support it;
vertical locating tabs engage during the final **0.22 m** lowering. Its front
underside stays at or above Z17.22 across the sensor aperture X±0.60. Side ledges
and fastening ears are outside that aperture.

Four recessed **M12×160 bolts** retain the top: front heads at
`(±0.66,+0.68,17.02)` enter −Y; rear heads at `(±0.66,−0.90,17.02)` enter +Y.
Use captive side-frame threads, with front receiving bosses in Y+0.52..+0.58
and rear receiving bosses in Y−0.80..−0.74. The longer top bolts bridge its
mounting ears; they are a different compatible length from the side bolts.
The rear ears enter open exterior recesses in the side frames/skin, rather than
overlapping intact wraparound material. Receiving bosses remain below the
side-frame top Z17.08. Reserve R0.045 horizontal tool cylinders forward to
Y+0.98 and rearward to Y−1.20. These horizontal faces are visible from the
upper work deck; upward bolts recessed behind the roof/brow would not be visible
from the selected eye height. Rear heads are exposed in those outward recesses,
with no rear skirt across the tool lanes.

Use the shared adjustable four-end spreader for the top, with exposed front/rear
pad faces `(±0.62,+0.70,17.28)` and `(±0.62,−0.90,17.28)`. Individual magnetic
ends and their handles remain on the outside of the skin. All four bolts, ledge
seating and tab engagement must be complete before any end is detached. Front
ends are released from the front landing; rear ends from the flanks. Keep front
rigging lines at Y≥+0.95 and rear lines at Y≤−1.15 above the load using the shared
spreader/short stand-offs, so no line is pinched under the roof. The top can be
supported and returned before retention, or reacquired for local correction after
removing dependent closures; no complete-head lifting operation is introduced.

### Sensor carrier: bench preparation and exact open-front path

Prepare **two interchangeable camera modules** and the **distinct forehead range
sensor** on one carrier at the small bench, two M6 retaining screws per module.
Module centres are approximately `(±0.27,+0.35,16.66)` for the cameras and
`(0,+0.35,17.02)` for range. The prepared child's complete insertion bounds,
including module projections, captive heads and ears, are
**X±0.53/Y+0.08..+0.50/Z16.48..17.14**.
It is ordinary assisted two-hand stock, not a crane load or loose sensors placed
individually inside a closed helmet. Bench wiring joins the three modules to one
accessible keyed connector on the carrier.

With both sides and the **structural top already retained and rigging removed**,
the open front at Y+0.58 is **X±0.60/Z16.35..17.22**. Start the carrier at a +1.00 m
Y translation: bounds Y+1.08..+1.50, unchanged X/Z. A worker near Y+1.95 holds its
lower-front grips near Z16.50; move it straight **−Y by 1.00 m**, without tilting
or entering from above. Initial hand support continues until the lower keyed
rails, X≈±0.55 and Y+0.10..+0.68, capture the carrier. Capture lips supply pitch
and uplift restraint during the remaining insertion; a hard rear stop defines
the final pose. Allow supported withdrawal while unretained. A wider right guide
rejects a reversed/rolled carrier without changing camera compatibility.

The opening leaves **0.07 m each side, 0.13 m below and 0.08 m above** its complete
prepared envelope. The roof overhang has no downward rib through this straight
prism. Rail mouths and guide shoes require actual swept-solid checking, including
the carried hands and the initial hand-to-rail transfer.

Four captive **M8 carrier bolts**, front heads near
`(±0.49,+0.50,16.52)` and `(±0.49,+0.50,17.08)`, enter −Y into the side-frame
carrier ears. Reserve R0.035 front tool lanes to Y+0.95. The rails support the
child while all four bolts are secured; slide friction or its cable never supplies
final retention. Plug the carrier into the head loom from the front near
`(+0.43,+0.57,16.46)`, then clip its short service loop within
X+0.32..+0.58/Y+0.38..+0.63/Z16.35..16.57, minimum working bend radius 0.04 m.
The loom rises on the right portal at X≈+0.57, clear of neck bolts and guides.
Check power/data before closing the faceplate. No connection behind the fitted
carrier or through the roof is required.

### Separate faceplate, mask, and decorative crown mounts

| Closure | Seat, movement and retention |
| --- | --- |
| Front faceplate | Approximately X±0.65/Y+0.64..+0.72/Z16.13..17.18. Approach 0.18 m forward and translate −Y onto two lower support ledges and independent side-frame locators. Four M10×80 front bolts at X±0.55/Y+0.73/Z16.20 and 17.12 enter −Y into dedicated frame bosses. The ledges support fastening, but all four bolts are needed for retained closure. |
| Samurai mask | Separate angular cheek/nose/chin assembly within X±0.70/Y+0.70..+0.90/Z15.76..16.92. With faceplate complete, approach 0.16 m forward and 0.10 m high, translate −Y then lower 0.10 m onto two hooks at `(±0.68,+0.74,16.50)`. These mounts lie outside the faceplate edges. Two M10×160 front bolts at `(±0.56,+0.88,15.98)` enter −Y into lower portal bosses extending to Y+0.76 below the faceplate. The hooks supply temporary hands-free support; both bolts prevent uplift. |
| Decorative crown/crest | Separate structural forehead roots tied to the top's front crossbar, clear of the faceplate/mask, within Y+0.44..+0.62. Two unique keyed prongs at `(±0.20,+0.52)`, Z17.22..17.34, accept crown feet; crown lower root is Z17.20 and seating plane Z17.22. Final approach is 0.18 m down, including 0.06 m clear lead above the 0.12 m key. Two M12×100 front bolts at `(±0.20,+0.66,17.28)` enter −Y into those roots and block uplift. Neither decorative blade is a sensor or an antenna. |

Faceplate and mask use ordinary assisted two-hand carrying and a finite elevator
shelf, one piece at a time, with protective edge grips. Reserve an upright shelf
contact width **1.45 m × 0.35 m depth**, retaining a piece up to 1.20 m high
(user shelf-enlargement decision, 2026-10-24); this
is a use of the shared shelf, not a dedicated head machine. They remain separate
collect/place/fasten steps. Carrier transport uses its own padded support on that
same shelf; no invisible equipment load or pocketing of a large panel is assumed.

Faceplate camera slits are centred X±0.27/Z16.66, approximately 0.26 W × 0.10 H;
the range aperture is centred X0/Z17.02, 0.18 W × 0.10 H. Keep clear frusta from
the recessed module apertures at Y+0.48 through the faceplate to the mask-front
plane Y+0.90: camera clear ends at least 0.34 W × 0.14 H, range 0.22 W × 0.15 H.
Mask cheek reliefs preserve those two eye corridors; its raised nose bridge stays
between them. The crown root's Z17.20 lower edge stays above the range corridor's
Z17.095 upper edge. These are protected geometric apertures, not a selected field
of view or sensor technology; check the final optical paths once that is chosen.

The crown is the final crane load because of its 2.60 m span and elevated keys.
Keep its blade plane and mounting frame within approximately Y+0.44..+0.82, with
tips at X±1.30/Z18.00. Two high **front-facing** structural magnetic pads at
`(±0.58,+0.68,17.76)` sit on the exposed inner blade shoulders, above the working
centre of mass. Shape the upper blade sweep outboard of their rigging lines;
short stand-offs put those lines at Y≥+0.95. The pad load line is a source-balance
target, subject to actual mass and trim. With both keyed feet fully seated and
both M12 bolts complete, release/stow the two visible ends from the front landing.
No fastener or magnetic end is hidden behind the fitted crown. Reacquire both ends
before releasing crown retention for a local mistake correction.

### Supported source-to-head handling and overhead envelope

Use the **shared bulky bay and reusable adjustable fixtures**, sequentially, for
baseplate, each side, top and crown. Keep each piece upright in its installed yaw
and pitch. Map its lowest installed Z to fixture world height **0.60 m for the
baseplate, 0.85 m for the sides, top and crown**;
the shared fixture centre `(3.25,*,13.00)` lies in the selected11×12 m
bulky bay. Thus a point maps as
`(3.25+X, Hsource+Z−Zmin, 13.00−Y)` for the current piece, using that selected
source height. Contact structural feet or
roof ledges in padded adjustable saddles, not flared armor edges, optics or crest
tips. Brace each upright source against tipping until all rigging is attached and
tensioned. Source rigging-pad heights are approximately **1.40 m baseplate**, 2.23 m
side, 1.17 m top and 1.41 m crown. The upward baseplate pad faces are therefore
visible below the standing eye at 1.63 m; the other pieces' outward pad faces
remain visible from their source approach. Floor-level approach and supported trim establish
their handling; no assembled head or new dedicated positioning machine is needed.

For each load: find its supported fixture; attach each magnetic end individually;
take up the shared crane, confirm balanced support, then release fixture clamps.
Use the established central **Up / Down / Go** vocabulary with current work
context. Source supports and crane pickup must be visibly distinct. No permanent
button for each head part, hidden remote capture action, or full swing simulation
is selected by this design.

Move above the final-bay head opening with the current piece's lowest point at
**robot Z17.60**. This clears the tallest previously fitted helmet surface Z17.40
by 0.20 m; during side installation it also clears the first side Z17.08 and portal
frames Z16.20. Lower in final alignment, with open-bottom shell pockets admitting
the portal uprights before the last 0.22 m keyed travel. Each shell's keep-out
volume and line paths must remain clear while descending; a final-pose bounding
box does not prove that. Retain before releasing rigging, then park the empty
crane for the ordinary carrier/faceplate/mask work.

Select a **1.20 m pad-to-highest-rigging allowance**, including spreader and stand-offs.
The side load governs: 17.60 + (16.90−15.52) + 1.20 + world offset 1.40 =
**world Y21.58**, leaving 1.42 m to the proposed lowest overhead obstruction Y23.00.
Its lifted shell top is world Y20.56. Crown's same above-roof transfer gives
highest rigging about world Y20.76 and tip Y19.80, before its lower final approach.
The final crest remains world Y19.40. Replace these allowances if actual rated
rigging needs more height; they are not crane capacity or cable-angle proof.
Front/rear-facing magnetic pads need rated shear/peel resistance and source
balance validation; their visible access is not a capacity calculation.

Keep the backpack **closed and latched during head construction** to clear the
rear work and crane legs. This is a safe work state, not a claim that the head
prevents later opening. Backpack maintenance retains its full selected sweep:
body X±1.20/Y−4.173..−1.20/Z≤15.10, planning allowance
X±1.30/Y−4.30..−1.10/Z≤15.20. All head pieces, fixed supports and tucked services
stay at Z≥15.40, with rear skin Y≥−0.90: at least 0.20 m vertical and 0.20 m
fore/aft separation to the planning allowance where applicable. The head adds no
rear hanging cable, step, crane line or permanent platform through that sweep.

### Standing areas, tool visibility, and fitted-neighbor checks

The upper deck **world Y16.40 = robot Z15.00** gives nominal eye Z16.63
(world Y18.03). A player is 1.70 m tall, diameter 0.52 m, with 2.35 m interaction
reach; use unobstructed routine targets near or below 1.80 m where practical.
The lower deck world Y14.00 remains shoulder/cockpit access. It is not an extra
closely stacked head stop, and is not credited with seeing through the helmet.

| Work position / representative target | Allocated distance from upper-deck eye |
| --- | --- |
| Front worker `(±0.27,+1.70,16.63)` → front/rear neck bolt `(±0.27,±0.27,15.56)` | 1.79 / 2.24 m. The deeper rear pair is an explicit reach exception, before the shells are fitted; open central sightline and R0.06 vertical tool lanes must be retained. |
| Front worker `(±0.90,+1.70,16.63)` → lower side bolt `(±0.66,+0.52,15.80)` | 1.46 m; upper bolt closer. |
| Same front worker → top front magnetic end near `(±0.62,+0.80,17.28)` | 1.15 m, approached from the exposed outer brow face. |
| Rear worker `(±2.00,−1.70,16.63)` → rear side pad `(±0.62,−0.90,16.90)` | 1.62 m; exterior pad face avoids occlusion by rear armor. |
| Same rear worker → rear top bolt `(±0.66,−0.90,17.02)` | 1.61 m; forward tool approach from the rear uses the exposed ear recess. |
| Front worker `(±0.49,+1.70,16.63)` → carrier upper bolt `(±0.49,+0.50,17.08)` | 1.28 m; connector and lower bolt closer. |
| Front worker `(±0.58,+1.70,16.63)` → crown pad `(±0.58,+0.68,17.76)` | 1.52 m; front-facing attachment and handle remain visible after retention. |

These positions require real floor patches, not isolated eye points. Front worker
centres use robot X−1.20..+1.20/Y+1.70..+2.00 on the existing head landing
world X11.0..15.0/Z23.4..24.6. Carrier insertion begins at Y+1.95 so the carried
front edge Y+1.50 does not overlap the 0.26 m body radius. Rear worker centres are
X±2.00/Y−1.70, with body footprints inside head-level rear flanks
world X9.7..11.4 and 14.6..16.3, starting at worldZ27.4. This clears the prepared chest roots during delivery;
the rear head stance is worldZ27.7, fully on that floor. They lie outside
the central rear opening X11.4..14.6 and outside the backpack sweep plus body
radius. Keep tools/magnetic ends and safety rails out of their aim corridors.

The fitted pauldrons occupy reference bounds |X|1.62..2.80/Y±0.65/Z≤15.05,
with relieved inner cavities. The 0.62 m helmet-to-pauldron lateral envelope gap
is **not** a credited worker passage. World deck Y16.4 passes through the top
0.05 m of the pauldron bounding band, so retract/notch the former side fingers
there. Connect the front and rear head work by outer walks, selected in the
[shared access plan](game/final-assembly-plan.md#shared-elevator-access-to-hips-and-shoulders)
as worldX3.5..5.0 and21.0..22.5/Z23.4..37.3, connected through the
rear crossoverZ35.8..37.3 and the side elevators centredZ29.0. The earlier
short inner walks are removed: they would intersect the arms’ vertical rigging
lines. Use these outer routes to reach the unchanged front/rear work patches. No walking through shoulder armor or stepping on
the helmet is part of the sequence. The head's lowest fixed point Z15.40 is
0.35 m above the pauldron's highest reference point; crest |X|≤1.30 remains
0.32 m inboard of its inner envelope. Actual moving pauldron clearance is still
the shoulder owner's solid/sweep check, not implied by these reference margins.

### Manual dependencies and remaining verification

The required installation order remains exactly:

1. Existing torso spoke, fixed and wired with the prepared chest.
2. Crane baseplate onto the spoke; seat, retain all four neck bolts, connect/clip
   services, release both magnetic ends.
3. Crane the two prepared wraparound sides, either side first; seat rear hooks,
   secure that side's two front bolts and release both ends before the top.
4. Crane the structural top; seat four ledges/tabs, retain four horizontal bolts,
   release all four ends.
5. Carry the bench-prepared three-sensor carrier through the open **front**;
   capture, seat, retain four bolts, connect/clip/check services.
6. Carry/seat/retain the front faceplate on its own frame bosses.
7. Carry/hook/retain the samurai mask on its separate frame mounts.
8. Crane/seat/retain the decorative crown/crest, then release its two ends.

Preparation of the sensor child and individual shells may happen independently
at the bench/fixture, but it does not advance the mounted head past those physical
dependencies. Prepared, seated, retained, connected, closed and crane-released
are separate states. Closure is blocked while its covered connection, tool lane
or rigging release is incomplete. Local correction removes the necessary later
closures, isolates covered services, reacquires proper support, then releases the
affected retention. Do not turn that supported correction into a required full
robot teardown test.

This pass checked written envelopes, pilot/bolt/tool margins, straight carrier
clearances, illustrative reach, shoulder/work-deck conflicts and loaded overhead
arithmetic. It produced no models, gameplay changes, automated game checks or
rendered review. Before later implementation:

1. Check both neck mating solids, key orientation/entry, actual thread grip,
   all four bolt lanes and visible rear-bolt aiming from the stated front patch.
   Resolve any obstruction before closing the sides; do not substitute a hidden
   nut or optimistic centreline reach.
2. Sweep both handed wraparound shells past the uprights and existing neighbor
   side; verify rear hooks, complementary seam material, front retention, roof
   tabs/ledges and all horizontal tool cylinders. Check each attached magnetic
   end's visible handle and pickup/release stroke after retention, including
   spreader legs, full load routes, actual balance and capacity.
3. Sweep the complete sensor child plus carried hands through the post-top
   opening; prove hand-to-captured-rail support, stop/bolts/connector access,
   harness clipping, and all three optical paths through every final closure.
4. Check faceplate support, mask hook/bolt approach, crown keys/bolts, ordinary
   carry/shelf/elevator fit, full body/guard clearance on front and rear patches,
   and walking around both complete arms/pauldrons via the outer routes.
5. Check backpack opening and later core maintenance with the complete head,
   crest and both arms present, plus neutral/articulated waist and shoulder
   solid sweeps. Keep the central rear service region clear.
6. Author one ordinary-input collection → supported crane installation → visible
   fastening → magnetic release journey early, then the sensor/front-closure
   journey. Audit unique stock/slots, hardware types, ownership/prerequisites,
   compatible-camera swaps, wrong-variant rejection, local undo/reinstallation
   and save/resume through supported handoffs. Inspect gameplay reach/aim and
   label readability; rendered review runs only if explicitly requested.

Remaining detail work is final helmet/mask/crest surfaces, member and thread
strength, rated magnets/rigging and mass distribution, optical technology,
weather seals, full manufactured inventory/part identifiers, source models and
playable manuals. These selected interfaces supersede the earlier open interface
questions; they are not additional user-approved dimensions or gameplay evidence.

## Robot workshop head implementation — 2026-10-24

- `game/workshop/tools/author_head.py` authors the baseplate, handed rear-wrap
  sides and structural roof from the interface/handling sections above and the
  final-assembly plan's fixture, crane-route and work-patch tables.
- Four passive upright stores in the bulky bay feed the shared fixture at
  X3.25/Z13; exchangeable saddles/jaws use 0.60 m baseplate and 0.85 m shell seats.
  The fixture's common upper members now end at Y0.58 to clear the low plate.
- Separate M24×160 bolts/4 mm washers, M12×100 side bolts, M12×160 roof bolts
  and the head-owned loom belong to the chest manual; preparation is supplied.
- Receiver milestones gate retention/services; rig zones require every preceding
  end stowed before shells/roof. `head_sensors` starts after structural retention,
  loom connection, rig release and crane parking, with the front slide open.
- Blockout deviation: the raised hub has a faceted, flared front-key relief;
  moving bearing-face proxies use 2 mm contact tolerance around the 1 mm sweep
  margin. Actual source seats retain the specified planes and keyed pilot bore.
- Payload/full-rig preflight includes fitted neighbors/hardware and rejects low
  crossings and reversed plate entry. Mechanical/manual checks are automated;
  walking, reach/visibility, manufactured detail and presentation remain unreviewed.
- The 2026-10-24 user decision resolves the task-09 shelf blocker: both workshop shelves
  are 1.50 m wide, accepting one 1.45 × 0.35 × 1.20 m panel; the leg-bay trial shelf was unchanged.
- Task 09 adds shelf-carried HD-SENSORS, HD-FACE and HD-MASK, followed by the
  upright two-end crown crane load; the chest manual owns all external slots.
- Bench preparation supplies two identical cameras, one range sensor and six M6
  screws. The carrier has four locally tightened captive M8 bolts and one keyed
  power/data connection; closure requires retention and the connection check.
- The compact carrier occupies 1.06 × 0.32 × 0.66 m inside the stated insertion
  envelope. Faceplate and mask retain their specified bolt/hook coordinates.
- Ordinary item seating uses the hip-cylinder parking-catch ownership pattern:
  the hooked mask frees both hands before its two uplift bolts are fitted.
- Roof key pockets and panel reliefs clear fitted guides/hooks; M12×100 crown/side
  bolts stay interchangeable. `complete` requires head retention/services and parked rig.
- Closure tests cover shelf transfers, order, optical corridors and mask correction;
  full payload/rig preflight covers the crown with fitted head closures. The new
  surfaces remain blockout geometry; walking, reach and presentation await the user.
