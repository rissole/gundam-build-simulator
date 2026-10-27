"""Author the structural left-leg extension and the robot workshop content
without regenerating the FA-01 GLB.

Run with Python 3 from any directory; --check audits and byte-compares every
generated asset without writing. This script authors parts and interfaces;
assets/workshop-layout.json owns shared placement data. This prototype does
not claim a powered or armored leg.
"""
import json
import math
import argparse
from copy import deepcopy
from collections import Counter
from pathlib import Path
from standard_hardware import CATALOGUE, canonical_part, audit_standard_hardware

ROOT = Path(__file__).resolve().parents[3]
ASSETS = ROOT / "game/workshop/assets"
MANIFEST = {p["instance_id"]: p for p in json.loads(
    (ROOT / "models/foot-fa01/output/parts-manifest.json").read_text())["parts"]}
parts, stock, sources = {}, [], {}
# Shared layout authority: authoring and runtime read the same declared data.
LAYOUT = json.loads((ASSETS / "workshop-layout.json").read_text())
RAIL = LAYOUT["rail"]
CRANE_SUPPORT = LAYOUT["crane"]["support"]
# The base leg recipe secures the Upper-leg beam; the robot content adds the
# shin and fork tasks.
SPAR_SECURED = "spar_secured"
SPAR_UID = "LG-120__001"
CRANE = "service_crane"
RELEASE = [dict(op="detach", machine=CRANE), dict(op="operate", machine=CRANE, command="up"), dict(op="operate", machine=CRANE, command="go:park")]


def kind(key, family, title, carry="hand", variant="structural"):
    parts[key] = dict(family=family, variant=variant, title=f"{family} · {title}",
                      short_title=title, carry_class=carry)


def primitive(shape, **values):
    return dict(shape=shape, **values)


def box(center, size):
    return primitive("box", center=center, size=size)


def tube(center, outer, inner, length, axis="y"):
    return primitive("tube", center=center, outer=outer, inner=inner, length=length, axis=axis)


def plate(center, size, holes=(), axis="y"):
    return primitive("plate", center=center, size=size, holes=list(holes), axis=axis)


def hole(x, z, radius):
    return [x, z, radius]


def source(uid, family, position, shapes, rotation=(0, 0, 0)):
    sources[uid] = dict(family=family, position=position, rotation_degrees=rotation, primitives=shapes)


def item(uid, key, location="bin"):
    stock.append(dict(instance_id=uid, source_id=uid, part_id=parts[key]["family"],
                      kind=key, location=location))


kind("lg-shin", "LG-100", "Structural shin", "equipment")
kind("lg-knee-fork", "LG-110", "Detachable knee fork", "equipment")
kind("lg-thigh-spar", "LG-120", "Upper-leg beam", "equipment")
kind("lg-knee-bearing", "LG-130", "Knee journal bearing")
kind("lg-knee-thrust", "LG-135", "Knee thrust spacer")
kind("lg-knee-axle", "LG-140", "Shouldered knee axle", "two_hand")
kind("lg-knee-cap", "LG-150", "Knee axle retaining cap")
kind("lg-m24-100", "LG-H24100", "M24 × 100 fork bolt", "pocket", "M24x100")
# Reuse proven FA-01 stock types; source instance IDs stay unchanged.
for standard in ("h-12050", "washer", "w-12"):
    parts[standard] = canonical_part(standard)
kind("pv-ring-half", "PV-120", "Hip retaining ring half", "two_hand", "semicircular")
parts["pv-ring-half"]["handling"] = dict(distance=.85, rotation_degrees=[90, 0, 0], shelf_rotation_degrees=[90, 0, 0],
    shelf_clamps=[[x, y, -.1] for x in (-.5, .5) for y in (-.04, .04)])
kind("pv-m24-140", "PV-H24140", "M24 × 140 ring bolt", "pocket", "M24x140")
kind("lg-m36-90", "H-36090", "M36 × 90 shin bolt", "pocket", "M36x90")
kind("lg-w36", "W-36", "M36 washer", "pocket", "M36")
kind("lg-main-input", "FA-605", "Main input harness with both plugs", "two_hand", "main-input")

# All new source meshes are local to their source transform; no exploded offsets.
ankle_holes = [hole(x, z, .019) for x in (-.2, .2) for z in (-.15, .15)]
source("LG-100__001", "LG-100", [0, 1.395, 0], [
    plate([0, 0, 0], [.54, .03, .44], ankle_holes),
    # Female key receives the actual GLB adapter's 180×100×20 integral key.
    box([0, 1.6375, 0], [.30, 3.245, .20]),
    tube([0, 3.705, 0], .28, .15, .56, "x"),
    box([0, 3.32, 0], [.30, .35, .20]),
])
# Cut the key through the bottom flange too; its top is closed by the beam above.
sources["LG-100__001"]["primitives"][0]["rect_holes"] = [[0, 0, .182, .102]]
item("LG-100__001", "lg-shin", "support:leg_shin_rack")
# Source-authoritative main harness endpoint, converted Blender -> Godot.
plug_axis = [.080, .160, -.050]
plug_axis = [v/math.sqrt(sum(x*x for x in plug_axis)) for v in plug_axis]
plug_center = [.250, 1.400, -.100]
socket_center = [p+.034*a for p, a in zip(plug_center, plug_axis)]
bracket_start = [socket_center[0], socket_center[1], socket_center[2]+.030]
bracket_end = [.145, 1.46, -.04]
bracket_axis = [b-a for a, b in zip(bracket_start, bracket_end)]
bracket_center = [(a+b)/2 for a, b in zip(bracket_start, bracket_end)]
disconnect = [tube(socket_center, .024, .017, .032, plug_axis),
              tube(bracket_center, .010, 0, math.sqrt(sum(v*v for v in bracket_axis)), bracket_axis)]
sources["LG-100__001"]["primitives"] += [
    dict(shape, center=[p-o for p, o in zip(shape["center"], sources["LG-100__001"]["position"])])
    for shape in disconnect]
shin_collision = [
    dict(type="box", position=[0, 0, 0], size=[.54, .03, .44]),
    dict(type="box", position=[0, 1.6375, 0], size=[.30, 3.245, .20]),
    dict(type="box", position=[0, 3.32, 0], size=[.30, .35, .20]),
]
# A localized annular compound preserves the transverse knee opening without
# projecting its Ø560 boss envelope over the full 300×200 shin shaft. Sixteen
# tangent boxes conservatively cover the actual ring, with at most 5.4mm of
# exterior allowance at their corners; the central axle passage remains open.
boss_segments = 16
boss_inner_face = .15*math.cos(math.pi/boss_segments)
boss_outer_face = .28
boss_center = (boss_inner_face+boss_outer_face)/2
for index in range(boss_segments):
    angle = math.tau*index/boss_segments
    shin_collision.append(dict(type="box",
        position=[0, 3.705+boss_center*math.cos(angle), boss_center*math.sin(angle)],
        size=[.56, boss_outer_face-boss_inner_face, 2*.28*math.sin(math.pi/boss_segments)],
        rotation_degrees=[math.degrees(angle), 0, 0]))
shin_collision.append(dict(type="sphere", radius=.030,
                           position=[p-o for p, o in zip(socket_center, sources["LG-100__001"]["position"])]))
stay_length = math.sqrt(sum(v*v for v in bracket_axis))
stay_direction = [v/stay_length for v in bracket_axis]
shin_collision.append(dict(type="capsule", radius=.010, height=stay_length+.020,
    position=[p-o for p, o in zip(bracket_center, sources["LG-100__001"]["position"])],
    rotation_degrees=[math.degrees(math.atan2(stay_direction[2], stay_direction[1])), 0,
                      -math.degrees(math.asin(stay_direction[0]))]))
parts["lg-shin"]["collision_shapes"] = shin_collision
# Diagram-only subsets are explicitly not inventory or extra robot components.
source("LG-V-DISCONNECT", "LG-100", [0, 0, 0], disconnect)
source("LG-V-INPUT-PLUG", "FA-605", plug_center, [
    tube([0, 0, 0], .014, 0, .030, plug_axis),
    tube([a*.016 for a in plug_axis], .016, .007, .006, plug_axis)])
item("FA-605__001", "lg-main-input")
fork_holes = [hole(x, z, .013) for x in (-.25, .25) for z in (-.20, .20)]
fork_taps = [hole(x, z, .0105) for x in (-.25, .25) for z in (-.20, .20)]
source("LG-110__001", "LG-110", [0, 5.1, 0], [
    tube([x, 0, 0], .34, .105, .14, "x") for x in (-.43, .43)
] + [box([x, .46, 0], [.14, .48, .26]) for x in (-.43, .43)] + [
    box([0, .73, 0], [1.0, .10, .36]),
    plate([0, .80, 0], [.68, .04, .60], fork_taps),
])
item("LG-110__001", "lg-knee-fork", "support:leg_fork_rack")
source("LG-120__001", "LG-120", [0, 5.94, 0], [
    plate([0, 0, 0], [.68, .04, .60], fork_holes),
    box([0, 1.27, 0], [.30, 2.50, .20]),
    tube([0, 2.62, 0], .15, 0, .45),
    primitive("sphere", center=[0, 3.26, 0], radius=.45),
])
item("LG-120__001", "lg-thigh-spar", "support:leg_spar_rack")
parts["lg-thigh-spar"]["collision_shapes"] = [
    dict(type="box", position=[0, 0, 0], size=[.68, .04, .60]),
    dict(type="box", position=[0, 1.27, 0], size=[.30, 2.50, .20]),
    dict(type="capsule", position=[0, 2.62, 0], radius=.15, height=.45),
    dict(type="sphere", position=[0, 3.26, 0], radius=.45),
]
for n, x in enumerate((-.21, .21), 1):
    uid = f"LG-130__{n:03}"
    source(uid, "LG-130", [x, 5.1, 0], [tube([0, 0, 0], .149, .102, .12, "x")])
    item(uid, "lg-knee-bearing")
for n, x in enumerate((-.3175, .3175), 1):
    uid = f"LG-135__{n:03}"
    source(uid, "LG-135", [x, 5.1, 0], [tube([0, 0, 0], .18, .102, .075, "x")])
    item(uid, "lg-knee-thrust")
source("LG-140__001", "LG-140", [0, 5.1, 0], [
    tube([0, 0, 0], .1, 0, 1.0, "x"),
    tube([-.52, 0, 0], .15, 0, .04, "x"),
    # Tapped cap bores are represented as through bores in the shallow end pad.
    plate([.52, 0, 0], [.04, .18, .30], [hole(0, z, .005) for z in (-.10, .10)], "x"),
])
item("LG-140__001", "lg-knee-axle")
source("LG-150__001", "LG-150", [.555, 5.1, 0], [
    plate([0, 0, 0], [.03, .20, .32], [hole(0, z, .0065) for z in (-.10, .10)], "x")])
item("LG-150__001", "lg-knee-cap")


def hardware(family, key, n, position, diameter, length, washer=False, upward=False, axis="y"):
    uid = f"{family}__{n:03}"
    if washer:
        spec = CATALOGUE[key]["specification"]
        shapes = [tube([0, 0, 0], spec["outside"]/2000, spec["bore"]/2000, spec["thickness"]/1000, axis)]
    else:
        # Origin is the head-bearing face. Shank points down unless specified.
        sign = 1 if upward else -1
        if axis == "x":
            shapes = [tube([sign*length/2, 0, 0], diameter/2, 0, length, axis),
                      tube([-sign*diameter/2, 0, 0], diameter*.75, 0, diameter, axis)]
        else:
            shapes = [tube([0, sign*length/2, 0], diameter/2, 0, length, axis),
                      tube([0, -sign*diameter/2, 0], diameter*.75, 0, diameter, axis)]
    source(uid, parts[key]["family"], position, shapes)
    item(uid, key)
    return uid


leg_slots = {
    "foot": dict(assembly="foot", milestone="complete", requires=[], pose_source="FA-201__001", snap_position=[0, .8, -.7],
                 label="Prepared foot", support_required=True, source_supports=["foot_carrier"]),
    "shin": dict(accepts="lg-shin", requires=["foot"], pose_source="LG-100__001",
                 label="LG-100 · Structural shin", support_required=True, source_supports=["leg_shin_rack"]),
}
leg_pages = []


def slot(slots, sid, key, uid, requires, **extra):
    slots[sid] = dict(accepts=key, pose_source=uid, requires=list(requires), label=parts[key]["title"], **extra)
    return sid


def page(pages, title, body, ids, context=(), goal=None, objectives=None, note=None):
    if goal is None:
        pages.append(dict(title=title, body=body, slots=list(ids), view="components", context_sources=list(context)))
        return
    record = dict(title=title, goal=goal, slots=list(ids), objectives=objectives, view="components", context_sources=list(context))
    if note is not None: record["note"] = note
    pages.append(record)


page(leg_pages, "Dock the prepared foot", "Complete the foot manual, then use its carrier to dock the prepared foot on the supported leg. The rail holder supports the foot and locks ankle motion during structural work.", ["foot"])
page(leg_pages, "Lower the structural shin", "Use the shin rack controls to lower LG-100 onto the already fitted foot adapter. Align the female key with the adapter tongue; the equipment carries the load while it is unbolted.", ["shin"], ["FA-201__001"])
flange_slots = []
for n in range(1, 5):
    bolt_uid = f"H-36090__{n:03}"
    washer_uid = MANIFEST[bolt_uid]["paired_instance_id"]
    assert washer_uid == f"W-36__{n+20:03}"
    for uid, key in ((washer_uid, "lg-w36"), (bolt_uid, "lg-m36-90")):
        item(uid, key)
        # Preserve source-local geometry and its baked orientation. Only the
        # source origin moves +30mm to accommodate the real 30mm shin flange.
        p = MANIFEST[uid]["assembled_position_m"]
        pose = [p[0], p[2]+.03, -p[1]]
        sid = f"ankle/{uid}"
        required = ["shin"] if uid == washer_uid else [f"ankle/{washer_uid}"]
        slot(leg_slots, sid, key, uid, required, snap_position=pose,
             target_offset=[0, .065 if uid == bolt_uid else .004, 0])
        flange_slots.append(sid)
page(leg_pages, "Secure the ankle flange", "Fit four W-36 washers on the LG-100 flange, then four H-36090 M36 × 90 bolts downward into the already fitted FA-201 adapter. Heads are accessible above the flange outside the narrow shin beam.", flange_slots, ["LG-100__001", "FA-201__001"])
input_position = MANIFEST["FA-605__001"]["assembled_position_m"]
input_origin = [input_position[0], input_position[2], -input_position[1]]
# Copy the source generator's Catmull-Rom centerline sampling. Narrow capsules
# preserve the real cable route instead of treating its enclosing air as solid.
input_points = [[.210, .550, -.646], [.210, .550, -.590], [.470, .510, -.500],
                [.540, .650, -.150], [.530, .850, .120], [.400, 1.100, .170],
                [.200, 1.160, .170], [.170, 1.240, -.050], [.250, 1.400, -.100]]
extended = [input_points[0], *input_points, input_points[-1]]
sampled = []
for index in range(1, len(extended)-2):
    a, b, c, d = extended[index-1:index+3]
    for sample in range(5):
        t = sample/5
        sampled.append([.5*(2*b[j]+(-a[j]+c[j])*t+(2*a[j]-5*b[j]+4*c[j]-d[j])*t*t+
                            (-a[j]+3*b[j]-3*c[j]+d[j])*t*t*t) for j in range(3)])
sampled.append(input_points[-1])
input_collision = []
for begin, end in zip(sampled, sampled[1:]):
    delta = [b-a for a, b in zip(begin, end)]
    length = math.sqrt(sum(v*v for v in delta))
    direction = [v/length for v in delta]
    input_collision.append(dict(type="capsule", radius=.011, height=length+.022,
        position=[(a+b)/2-o for a, b, o in zip(begin, end, input_origin)],
        rotation_degrees=[math.degrees(math.atan2(direction[2], direction[1])), 0,
                          -math.degrees(math.asin(direction[0]))]))
for endpoint in (input_points[0], input_points[-1]):
    input_collision.append(dict(type="sphere", radius=.026,
                                position=[p-o for p, o in zip(endpoint, input_origin)]))
parts["lg-main-input"]["collision_shapes"] = input_collision
slot(leg_slots, "main_input", "lg-main-input", "FA-605__001", flange_slots,
     snap_position=[input_position[0], input_position[2], -input_position[1]],
     target_offset=[a-b for a, b in zip(plug_center, [input_position[0], input_position[2], -input_position[1]])])
page(leg_pages, "Connect the shin disconnect", "Fit FA-605 as one main input harness, including both attached plugs. Seat its box end in the already fitted FA-604 main socket, follow the existing foot guide clips, then push its upper keyed plug into the angled socket integral to LG-100 beside the ankle flange. Undo this step to unplug the harness before separating foot and shin.", ["main_input"], ["LG-V-DISCONNECT", "FA-604__001"])
bearings = []
for n in (1, 2):
    bearings.append(slot(leg_slots, f"bearing_{n}", "lg-knee-bearing", f"LG-130__{n:03}", flange_slots))
    leg_slots[f"bearing_{n}"]["target_offset"] = [-.061 if n == 1 else .061, 0, 0]
thrust = [slot(leg_slots, f"thrust_{n}", "lg-knee-thrust", f"LG-135__{n:03}", bearings) for n in (1, 2)]
for n in (1, 2):
    leg_slots[f"thrust_{n}"]["target_offset"] = [-.039 if n == 1 else .039, 0, 0]
page(leg_pages, "Seat bearings and thrust spacers", "Fit both LG-130 journal bearings from opposite sides into the already fitted shin's circular knee boss. Add one LG-135 thrust spacer against each boss end. The two bearings share one type; the two spacers share another.", bearings+thrust, ["LG-100__001"])
slot(leg_slots, "fork", "lg-knee-fork", "LG-110__001", thrust,
     support_required=True, source_supports=["leg_fork_rack"])
slot(leg_slots, "axle", "lg-knee-axle", "LG-140__001", ["fork"], target_offset=[-.542, 0, 0])
page(leg_pages, "Fork and axle", "Use the fork rack to straddle the already fitted shin boss with LG-110. Insert LG-140 from the left side through the aligned fork and bearings until its shoulder rests against the fork. The rail holder keeps the unpowered knee straight.", ["fork", "axle"], ["LG-100__001", "LG-130__001", "LG-130__002"])
slot(leg_slots, "cap", "lg-knee-cap", "LG-150__001", ["axle"], target_offset=[.017, 0, 0])
cap_slots = ["cap"]
for n, z in enumerate((-.10, .10), 1):
    w = hardware("LG-W12", "w-12", n, [.57125, 5.1, z], .012, 0, True, axis="x")
    b = hardware("LG-H12050", "h-12050", n, [.5725, 5.1, z], .012, .05, axis="x")
    ws = slot(leg_slots, f"cap/washer_{n}", "w-12", w, ["cap"], target_offset=[.003, 0, 0])
    cap_slots += [ws, slot(leg_slots, f"cap/screw_{n}", "h-12050", b, [ws], target_offset=[.014, 0, 0])]
page(leg_pages, "Retain the knee axle", "Fit LG-150 on the exposed axle end. Fit two W-12 washers and two H-12050 cap screws from the right side into the axle end pad. Both screw heads remain outside the fork.", cap_slots, ["LG-110__001", "LG-140__001"])
slot(leg_slots, "spar", "lg-thigh-spar", "LG-120__001", cap_slots,
     support_required=True, source_supports=[CRANE_SUPPORT])
spar_slots = ["spar"]
for n, (x, z) in enumerate(((x, z) for x in (-.25, .25) for z in (-.20, .20)), 1):
    w = hardware("LG-W24", "washer", n, [x, 5.962, z], .024, 0, True)
    b = hardware("LG-H24100", "lg-m24-100", n, [x, 5.964, z], .024, .1)
    ws = slot(leg_slots, f"fork/washer_{n}", "washer", w, ["spar"], target_offset=[0, .003, 0])
    spar_slots += [ws, slot(leg_slots, f"fork/bolt_{n}", "lg-m24-100", b, [ws], target_offset=[0, .026, 0])]
page(leg_pages, "Join the thigh spar", "Use the service crane to lower LG-120 onto the already fitted LG-110 fork flange. The hip ball and neck are integral to LG-120. Fit four W-24 washers and four LG-H24100 bolts downward through the exposed flange corners.", spar_slots, ["LG-110__001"])
leg_pages.append(dict(title="Structural leg ready", body="The load-bearing prototype is structurally ready. Use the leg rail to carry it to the gantry. Knee and ankle transport braces belong to the handling equipment; powered knee and hip actuators, services, armor and calf thrusters remain deferred. Open the hip assembly manual for seating and retention.", slots=list(leg_slots), view="prepared"))
leg = dict(title="Left leg · structural prototype", carry_class="equipment", bounds=[1.4, 9.65, 3.0],
           work_locations=["support"], interaction="components", service_access="assisted",
           slots=leg_slots, milestones={"structural_ready": list(leg_slots),
                                      SPAR_SECURED: spar_slots}, manual=leg_pages)

# Pelvis sources live in a frame whose Y0 plane passes through both hip centers.
source("PV-100__001", "PV-100", [0, .50, .65], [
    box([0, 0, 0], [2.7, .26, .30]),
    box([0, .35, 0], [.48, .45, .50]),
    box([-.50, .15, 0], [.18, .42, .24]),
    box([.50, .15, 0], [.18, .42, .24]),
])
source("PV-V-HIP-BALL", "LG-120", [-1.1, 0, 0], [
    primitive("sphere", center=[0, 0, 0], radius=.45), tube([0, -.64, 0], .15, 0, .45)])
ring_holes = [hole(.575*math.cos(a), .575*math.sin(a), .013)
              for a in (math.pi/4, 3*math.pi/4, 5*math.pi/4, 7*math.pi/4)]
context_sources = ["PV-100__001"]
for n, x in enumerate((-1.1, 1.1), 1):
    uid = f"PV-110__{n:03}"
    source(uid, "PV-110", [x, 0, 0], [
        primitive("hemisphere_shell", center=[0, 0, 0], inner=.456, outer=.53),
        tube([0, -.14, 0], .53, .46, .28),
        primitive("ring_plate", center=[0, -.315, 0], outer=.68, inner=.49, length=.07,
                  holes=[[h[0], h[1], .0105] for h in ring_holes]),
        box([0, .42, .50], [.46, .24, .40]),
    ])
    context_sources.append(uid)
    # The socket-to-bridge bolts are preassembled context, never loose supplies.
    for j, dx in enumerate((-.15, .15), 1):
        bolt_uid = f"PV-C-H24090__{(n-1)*2+j:03}"
        source(bolt_uid, "PV-C-H24090", [x+dx, .54, .60], [
            tube([0, -.045, 0], .012, 0, .09), tube([0, .012, 0], .018, 0, .024)])
        context_sources.append(bolt_uid)
for n, rotation in ((1, 0), (2, 180)):
    uid = f"PV-120__{n:03}"
    # Same manufactured half, rotated for the other side of the neck.
    source(uid, "PV-120", [-1.1, -.39, 0], [
        primitive("ring_plate", center=[0, 0, 0], inner=.30, outer=.68, length=.08,
                  start_degrees=180, end_degrees=360,
                  holes=[h for h in ring_holes if h[1] < 0])], [0, rotation, 0])
    item(uid, "pv-ring-half")
pelvis_slots = {"left_leg": dict(assembly="left_leg", milestone="structural_ready", requires=[],
                  pose_source="PV-V-HIP-BALL", snap_position=[-1.1, -9.2, 0], label="Structural left leg",
                  support_required=True, source_supports=[RAIL["support"]])}
pelvis_pages = []
page(pelvis_pages, "Seat the supported leg", "The braced hip bridge and both bolted socket housings are already fitted on the gantry. With the left ring removed, use the leg rail to dock the LG-120 hip ball upward into the left socket's open underside. Keep rail support until all retaining bolts are fitted.", ["left_leg"], context_sources)
for n in (1, 2):
    slot(pelvis_slots, f"ring_{n}", "pv-ring-half", f"PV-120__{n:03}", ["left_leg"])
page(pelvis_pages, "Fit the split retaining ring", "Carry and fit both PV-120 semicircular halves around the already seated LG-120 neck from opposite sides. Either identical half fits either destination. Their inward lips capture the ball with clearance around the neck.", ["ring_1", "ring_2"], ["PV-110__001", "LG-120__001"])
ring_fasteners = []
for n, (x, z, _) in enumerate(ring_holes, 1):
    w = hardware("LG-W24", "washer", n+4, [-1.1+x, -.432, z], .024, 0, True)
    b = hardware("PV-H24140", "pv-m24-140", n, [-1.1+x, -.434, z], .024, .14, upward=True)
    ring_sid = "ring_1" if z < 0 else "ring_2"
    ws = slot(pelvis_slots, f"ring/washer_{n}", "washer", w, [ring_sid], target_offset=[0, -.003, 0])
    ring_fasteners += [ws, slot(pelvis_slots, f"ring/bolt_{n}", "pv-m24-140", b, [ws], target_offset=[0, -.026, 0])]
page(pelvis_pages, "Bolt the ring to the socket", "Fit four W-24 washers and four PV-H24140 bolts upward from the split ring's exposed underside into the left socket flange. Both halves must be fitted and all four bolts installed before releasing rail support. To remove the leg, reacquire rail support first, then reverse the retention steps.", ring_fasteners, ["PV-110__001", "PV-120__001", "PV-120__002"])
pelvis_pages.append(dict(title="Left leg structurally mounted", body="The left ball is captured by both bolted ring halves. The gantry and mechanical transport braces support this unpowered prototype. This is structural readiness; hydraulic actuators, services and armor remain deferred.", slots=list(pelvis_slots), view="prepared"))
pelvis = dict(title="Hip assembly · left leg installation", bounds=[3.6, 1.5, 1.5], work_locations=["fixture"],
              interaction="components", context_sources=context_sources, slots=pelvis_slots,
              milestones={"left_leg_secured": list(pelvis_slots), "structural_ready": list(pelvis_slots)}, manual=pelvis_pages)

foot = json.loads((ASSETS / "pitch-actuator-definitions.json").read_text())["assemblies"]["foot"]
foot.update(carry_class="equipment", work_locations=["support"])


def diagram(title, source_ids, context=(), offsets=None, direction=(1, 1, 1)):
    return dict(title=title, sources=list(source_ids), context=list(context),
                offsets=offsets or {}, direction=list(direction), up=[0, 1, 0], context_padding=.08)


for definition in (leg, pelvis):
    for step in definition["manual"]:
        if step["view"] != "components":
            continue
        physical = [definition["slots"][sid]["pose_source"] for sid in step["slots"]
                    if "pose_source" in definition["slots"][sid]]
        context = ["PV-V-HIP-BALL" if uid == "LG-120__001" and definition is pelvis else uid
                   for uid in step.get("context_sources", [])]
        if physical:
            # Imported future flange hardware sits 30mm below its new installed
            # seat; diagrams use the same translation as the installation slots.
            offsets = {uid: [0, .03, 0] for uid in physical if uid.startswith(("H-36090", "W-36"))}
            step["diagram_views"] = [diagram(step["title"], physical, context, offsets)]
        if step["title"] == "Connect the shin disconnect":
            step["diagram_views"] = [
                diagram("FA-605 · one complete routed harness", ["FA-605__001"], ["FA-604__001"]),
                diagram("Upper keyed plug → shin socket", ["LG-V-DISCONNECT"], ["LG-V-INPUT-PLUG"], direction=(1, .3, -1))]
        if step["title"] == "Join the thigh spar":
            step["diagram_views"] = [
                diagram("LG-120 · lower onto fork", ["LG-120__001"], ["LG-110__001"]),
                diagram("Four exposed flange bolts", physical[1:], ["LG-110__001", "LG-120__001"])]
        if step["title"] == "Seat the supported leg":
            step["diagram_views"] = [diagram("Ball enters open left socket from below", ["PV-V-HIP-BALL"], ["PV-110__001"], direction=(1, -.4, -1))]

supports = {
    "foot_carrier": {"assemblies": ["foot"]},
    RAIL["support"]: {"assemblies": ["left_leg"], "assembly_ids": ["left_leg"]},
    CRANE_SUPPORT: {"parts": ["lg-thigh-spar"], "item_ids": [SPAR_UID]},
    "leg_shin_rack": {"parts": ["lg-shin"]},
    "leg_fork_rack": {"parts": ["lg-knee-fork"]},
    "leg_spar_rack": {"parts": ["lg-thigh-spar"]},
}
content = dict(version=1, parts=stock, parents=[
    dict(id="left_leg", definition="left_leg", label="Structural left leg", location="support:"+RAIL["support"], home=LAYOUT["parent_homes"]["left_leg"]),
    dict(id="pelvis", definition="pelvis", label="Gantry", location="fixture", home=LAYOUT["parent_homes"]["pelvis"]),
], supports=supports, sources=sources, context_sources=context_sources,
               source_units="metres", source_axes="Godot X robot right, Y up, -Z forward",
               joint_heights=dict(ankle=1.0, knee=5.1, hip=9.2),
               readiness="structural_ready",
               diagram_only_sources=["LG-V-DISCONNECT", "LG-V-INPUT-PLUG", "PV-V-HIP-BALL"])
content["equipment"] = dict(
    foot_mount=dict(parent="left_leg", slot="foot", support="foot_carrier"),
    leg_mount=dict(parent="pelvis", slot="left_leg", support=RAIL["support"]),
    parts={uid: dict(owner=owner, slot=sid, support=support, stock_position=position)
           for uid, owner, sid, support, position in [
               ("LG-100__001", "left_leg", "shin", "leg_shin_rack", [-2, 1.5, 14]),
               ("LG-110__001", "left_leg", "fork", "leg_fork_rack", [-2, 1.5, 18]),
               ("LG-120__001", "left_leg", "spar", "leg_spar_rack", [-2, 1.5, 22]),
           ]})


def catalogue_images(check=False, definitions=None, inventory=None, descriptors=None):
    """Small schematic thumbnails derived from actual descriptor primitive sizes.

    These support catalogue recognition, not rendered construction approval.
    """
    import html
    for key, definition in (parts if definitions is None else definitions).items():
        if key in CATALOGUE:  # Existing canonical PNGs; no component-specific icons.
            continue
        record = next(p for p in (stock if inventory is None else inventory) if p["kind"] == key)
        shapes = (sources if descriptors is None else descriptors).get(record["source_id"], {}).get("primitives", [])
        if not shapes:  # Existing source hardware keeps its physical FA-01 mesh.
            shapes = [tube([0, 0, 0], .033, .019, .006)] if key == "lg-w36" else [
                tube([0, -.045, 0], .018, 0, .09), tube([0, .018, 0], .027, 0, .036)]
        if key == "lg-main-input":
            shapes = [box([0, .0, 0], [.07, .04, .04]),
                      box([.09, .14, 0], [.04, .28, .04]),
                      box([.18, .28, 0], [.18, .04, .04]),
                      box([.27, .35, 0], [.04, .14, .04]),
                      box([.27, .44, 0], [.07, .05, .04])]
        top = "ring" in key or key.endswith("w24") or key.endswith("w12") or key == "lg-w36"
        axial = key in ("lg-knee-bearing", "lg-knee-thrust")
        elements, limits = [], []
        for shape in shapes:
            p = shape.get("center", [0, 0, 0])
            x, y = (p[2], p[1]) if axial else (p[0], p[2] if top else p[1])
            if shape["shape"] in ("tube", "ring_plate"):
                radius = shape["outer"]
                axis = shape.get("axis", "y")
                face = (axis == "x" and axial) or (axis == "y" and top)
                width = radius*2 if face or axis == "y" else shape["length"]
                height = radius*2 if face or axis == "x" else shape["length"]
                if shape["shape"] == "ring_plate":
                    face, width, height = True, radius*2, radius*2
                if face:
                    elements.append(f'<circle cx="{x}" cy="{-y}" r="{radius}"/>')
                    if shape["inner"]:
                        elements.append(f'<circle cx="{x}" cy="{-y}" r="{shape["inner"]}" fill="#152032"/>')
                else:
                    elements.append(f'<rect x="{x-width/2}" y="{-y-height/2}" width="{width}" height="{height}"/>')
            elif shape["shape"] == "sphere":
                width = height = shape["radius"]*2
                elements.append(f'<circle cx="{x}" cy="{-y}" r="{shape["radius"]}"/>')
            else:
                size = shape.get("size", [.2, .2, .2])
                width, height = size[0], size[2] if top else size[1]
                elements.append(f'<rect x="{x-width/2}" y="{-y-height/2}" width="{width}" height="{height}"/>')
            limits += [(x-width/2, -y-height/2), (x+width/2, -y+height/2)]
        lowx, lowy = min(p[0] for p in limits), min(p[1] for p in limits)
        highx, highy = max(p[0] for p in limits), max(p[1] for p in limits)
        scale = 76/max(highx-lowx, highy-lowy)
        tx, ty = 50-(lowx+highx)*scale/2, 46-(lowy+highy)*scale/2
        label = html.escape(definition["family"])
        svg = ('<svg xmlns="http://www.w3.org/2000/svg" width="128" height="128" viewBox="0 0 100 100">'
               '<rect width="100" height="100" rx="9" fill="#152032"/>'
               f'<g fill="#a8c4d5" stroke="#68d7bc" stroke-width="{.8/scale}" transform="translate({tx} {ty}) scale({scale})">'
               + ''.join(elements) + '</g>'
               f'<text x="50" y="95" text-anchor="middle" font-family="sans-serif" font-size="8" fill="#ffffff">{label}</text></svg>\n')
        path = ASSETS / "part-images" / f"{key}.svg"
        if check:
            assert path.read_text() == svg, f"Regenerate {path.name}"
        else:
            path.write_text(svg)
        definition["catalogue_image"] = f"res://assets/part-images/{key}.svg"


def audit():
    audit_standard_hardware(parts)
    ids = [p["instance_id"] for p in stock]
    assert len(ids) == len(set(ids)) == 40, len(ids)
    assert len(leg_slots) == 31 and len(pelvis_slots) == 11
    assert set(ids) == {s["pose_source"] for d in (leg, pelvis) for s in d["slots"].values() if "accepts" in s}
    for definition in (leg, pelvis):
        coverage = Counter(s for p in definition["manual"] if p["view"] == "components" for s in p["slots"])
        assert coverage == Counter({s: 1 for s in definition["slots"]})
        resolved = set()
        for p in definition["manual"]:
            if p["view"] != "components":
                continue
            for sid in p["slots"]:
                assert set(definition["slots"][sid]["requires"]) <= resolved, sid
                resolved.add(sid)
    base = json.loads((ASSETS / "pitch-workshop.json").read_text())
    assert not set(ids) & {p["instance_id"] for p in base["parts"]}
    assert all(p["source_id"] in sources or p["source_id"] in MANIFEST for p in stock)
    for definition in (leg, pelvis):
        for spec in definition["slots"].values():
            assert all(sid in supports for sid in spec.get("source_supports", []))
    for record in stock:
        if record["location"].startswith("support:"):
            assert record["location"].removeprefix("support:") in supports


def record_patch(base, changed):
    """Replace declared fields and explicitly remove absent fields."""
    patch = {}
    updates = {key: deepcopy(value) for key, value in changed.items()
               if key not in base or base[key] != value}
    removed = [key for key in base if key not in changed]
    if updates: patch["set"] = updates
    if removed: patch["remove"] = removed
    return patch


def assembly_patch(base, changed):
    patch = record_patch({k: v for k, v in base.items() if k != "slots"},
                         {k: v for k, v in changed.items() if k != "slots"})
    assert base["slots"].keys() == changed["slots"].keys(), "Slot inventory changes need explicit recipe authoring"
    slots = {sid: record_patch(base["slots"][sid], values)
             for sid, values in changed["slots"].items() if base["slots"][sid] != values}
    if slots: patch["slots"] = slots
    return patch


def materialize_overlay(base, overlay):
    """Audit the same shallow field / slot patch contract as runtime."""
    data = deepcopy(base)
    for field in ("parts", "assemblies"):
        data.setdefault(field, {}).update(deepcopy(overlay.get(field, {})))
    for owner, patch in overlay.get("assembly_patches", {}).items():
        definition = data["assemblies"][owner]
        for key in patch.get("remove", []): definition.pop(key, None)
        definition.update(deepcopy(patch.get("set", {})))
        for sid, fields in patch.get("slots", {}).items():
            slot = definition["slots"][sid]
            for key in fields.get("remove", []): slot.pop(key, None)
            slot.update(deepcopy(fields.get("set", {})))
    return data


def robot_documents(check=False):
    """Complete prepared-foot journey, patching the canonical slot graph."""
    rail, crane = RAIL["support"], CRANE_SUPPORT
    workshop_layout = json.loads((ASSETS / "workshop-layout.json").read_text())
    trial_leg, trial_pelvis = deepcopy(leg), deepcopy(pelvis)
    security = {
        "shin": ["shin"] + flange_slots,
        "fork": ["fork", "axle"] + cap_slots,
        "spar": spar_slots,
    }
    for task, secured in security.items():
        trial_leg["slots"][task]["source_supports"] = [crane]
        trial_leg["milestones"][task + "_secured"] = list(secured)
        for sid in secured:
            trial_leg["slots"][sid]["undo_requires_support"] = crane
    for sid in trial_pelvis["slots"]:
        if sid != "left_leg":
            trial_pelvis["slots"][sid]["undo_requires_support"] = rail
    for sid in ("ring_1", "ring_2"):
        trial_pelvis["slots"][sid]["undo_to"] = "hands"
    for sid in ("main_input", "bearing_1", "bearing_2", "thrust_1", "thrust_2", "axle", "cap"):
        trial_leg["slots"][sid]["undo_to"] = "hands"
    pages = []
    pages.append(dict(title="Prepared foot, empty leg rail", view="overview", slots=[], body="The complete 135-piece foot is supplied on its rig. The leg rig and hip assembly connections are empty. Build the leg here, then open the hip assembly manual for rail travel, seating and retention. Knee and ankle transport braces are equipment, not loose parts."))
    page(pages, "Deliver the foot", "", [], goal="Crane the finished foot from its turning rig onto the foot rig.", objectives=[
        dict(op="operate", machine=CRANE, command="pickup", task="foot"),
        dict(op="operate", machine=CRANE, command="down"),
        dict(op="connect", machine=CRANE),
        dict(op="operate", machine=CRANE, command="up"),
        dict(op="operate", machine=CRANE, command="go:receiver", task="foot"),
        dict(op="operate", machine=CRANE, command="down"),
        dict(op="detach", machine=CRANE),
        dict(op="operate", machine=CRANE, command="up"),
        dict(op="operate", machine=CRANE, command="go:park")])
    page(pages, "Dock the prepared foot", "", ["foot"], goal="Hand the foot from the foot rig to the leg rig.", objectives=[
        dict(op="operate", machine="foot_carrier", command="advance:1"),
        dict(op="operate", machine="foot_carrier", command="advance:2"),
        dict(op="seat", slot="foot", via=dict(machine="foot_carrier", command="advance:3"))],
        note=dict(at=0, text="The leg rig must be home in the Limb Bay with neutral roll."))
    def delivery(title, task, uid, receiver):
        page(pages, title, "", [task], goal=f"Crane {uid} from its rig onto the {receiver}.", objectives=[
            dict(op="operate", machine=CRANE, command="pickup", task=task),
            dict(op="operate", machine=CRANE, command="down"),
            dict(op="connect", machine=CRANE),
            dict(op="operate", machine=CRANE, command="up"),
            dict(op="operate", machine=CRANE, command="go:receiver", task=task),
            dict(op="seat", slot=task, via=dict(machine=CRANE, command="down")),
        ], note=dict(at=2, text="Keep both connectors attached until this connection is bolted."))
    def engage(group):
        return [dict(op="operate", machine="joint_restraints", command=f"engage:left_leg:{group}:{side}")
                for side in ("outboard", "inboard")]
    delivery("Deliver the structural shin", "shin", "LG-100", "foot adapter")
    page(pages, "Secure the ankle flange", "", flange_slots, ["LG-100__001", "FA-201__001"], goal="Bolt the shin flange, engage both ankle braces, then release and park the crane.", objectives=[dict(op="fit", slots=list(flange_slots))] + engage("ankle") + deepcopy(RELEASE), note=dict(at=0, text="Insert the bolts from the knee side, toward the foot."))
    page(pages, "Connect the shin disconnect", "", ["main_input"], ["FA-604__001", "LG-100__001"], goal="Plug the shin harness into the foot socket and the shin.", objectives=[dict(op="fit", slots=["main_input"])], note=dict(at=0, text="Approach from the side away from the part rigs, standing back toward the knee."))
    page(pages, "Seat bearings and thrust spacers", "", bearings + thrust, ["LG-100__001"], goal="Fit both knee bearings, then a thrust spacer at each end of the knee boss.", objectives=[dict(op="fit", slots=list(bearings)), dict(op="fit", slots=list(thrust))], note=dict(at=0, text="Keep the marked knee axle aisle clear."))
    delivery("Deliver the knee fork", "fork", "LG-110", "shin knee boss and thrust spacers")
    page(pages, "Insert the knee axle", "", ["axle"], ["LG-110__001"], goal="Slide the knee axle through the fork and bearings.", objectives=[dict(op="fit", slots=["axle"])], note=dict(at=0, text="Carry it lengthwise with both hands from the marked axle aisle."))
    assert cap_slots[0] == "cap"
    page(pages, "Retain the knee axle", "", cap_slots, ["LG-110__001", "LG-140__001"], goal="Cap the axle, engage both knee braces, then release and park the crane.", objectives=[dict(op="fit", slots=[cap_slots[0]]), dict(op="fit", slots=list(cap_slots[1:]))] + engage("knee") + deepcopy(RELEASE), note=dict(at=0, text="Work from the side opposite the axle aisle."))
    delivery("Deliver the Upper-leg beam", "spar", "LG-120", "fork flange")
    page(pages, "Fasten the Upper-leg beam flange", "", spar_slots[1:], ["LG-110__001", "LG-120__001"], goal="Bolt the beam flange, engage both flange braces, then release and park the crane.", objectives=[dict(op="fit", slots=list(spar_slots[1:]))] + engage("beam") + deepcopy(RELEASE), note=dict(at=0, text="Insert the bolts from the hip side, toward the knee. These are M24 × 100, not the hip assembly M24 × 140."))
    pages.append(dict(title="Structural leg ready", view="prepared", slots=[], body="All leg construction is complete. Park the empty crane with both magnetic connectors stowed. The leg rig can park an unfinished leg on the transverse table (Park, then hold INDEX +) and retrieve it without losing progress. For rear work, park the movable platform, hold LIFT + on the Limb Bay panel to raise the supported axis, then hold ROLL + or ROLL − to turn to the next locked orientation; each press stops at a detent. Restore neutral ROLL, then hold LIFT − to return to construction height. Open the hip assembly manual for delivery."))
    pages.append(dict(title="Supported construction recovery", view="overview", slots=[], body="Return the supported leg home before construction disassembly. Select the affected crane task, lower at the leg rig and attach both magnetic connectors to reacquire support before Z removes its retaining hardware. Reverse each task: remove all flange pairs before lifting shin or beam; remove cap screws, washers, cap and axle before lifting the fork. Raise crane withdraws the supported part through the reverse axial approach; Put back and Lower crane returns it. Detach and stow only after it is seated on its rig. Undo FA-605 before shin removal. With all structural work removed and the rail home, foot rig Return reacquires the foot and reverses one guided phase per press; Return again lowers it to dispatch."))
    trial_leg["manual"] = pages
    pages = []
    page(pages, "Seat the leg in the hip assembly", "", ["left_leg"], context_sources,
         goal="Jog the finished leg on its rig to the Final Assembly Bay, stand it under the left hip and seat it.",
         objectives=[
             dict(op="operate", machine="leg_rail", command="bolster:stow"),
             dict(op="operate", machine="leg_rail", command="index:lane"),
             dict(op="operate", machine="leg_rail", command="travel:bay"),
             dict(op="operate", machine="leg_rail", command="tilt:upright"),
             dict(op="operate", machine="leg_rail", command="rise:dock"),
             dict(op="seat", slot="left_leg", via=dict(machine="leg_rail", command="seat")),
         ],
         note=dict(at=0, text="Park the empty crane first. Hold E on a panel arrow to jog one axis; you can look away while E is held. Each axis stops at its track or end stop. The pulsing outline shows the next target, and each readout turns green when its axis is aligned. The leg rig stays attached until the hip is pinned."))
    for half, pairs in ((1, (3, 4)), (2, (1, 2))):
        ordinal = "first" if half == 1 else "second"
        page(pages, "Carry retaining half " + str(half), "", ["ring_" + str(half)], ["PV-110__001", "PV-V-HIP-BALL"],
             goal=f"Fit the {ordinal} retaining half around the hip neck.",
             objectives=[dict(op="fit", slots=["ring_" + str(half)])],
             note=dict(at=0, text="Take it up on the lift shelf, one half per trip. Either half fits either side."))
        ids = [sid for n in pairs for sid in ("ring/washer_" + str(n), "ring/bolt_" + str(n))]
        fasten_note = "Insert each washer and bolt upward from the underside." if half == 1 else "Work from the 8.4 m hip decks and front wings; insert each washer and bolt upward from the underside."
        page(pages, "Fasten retaining half " + str(half), "", ids, ["PV-110__001", "PV-120__%03d" % half],
             goal=f"Bolt the {ordinal} half to the socket flange from underneath.",
             objectives=[dict(op="fit", slots=list(ids))],
             note=dict(at=0, text=fasten_note))
    pages.append(dict(title="Release the leg rig", view="components", slots=[],
        goal="Let the hip carry the leg, then drive the empty rigs home.",
        objectives=[
            dict(op="operate", machine="leg_rail", command="release"),
            dict(op="operate", machine="leg_rail", command="tilt:lying"),
            dict(op="operate", machine="leg_rail", command="travel:home"),
            dict(op="operate", machine="leg_rail", command="index:station"),
            dict(op="operate", machine="leg_rail", command="extend"),
            dict(op="operate", machine="foot_carrier", command="return:home"),
            dict(op="operate", machine="leg_rail", command="build"),
        ],
        note=dict(at=1, text="The released holder stays clear of the leg while it lies down and travels home. Reacquire at the station extends it again.")))
    pages.append(dict(title="Reacquire support and recover", view="overview", slots=[], body="If the empty leg rig has returned home, Release compacts the empty holder for travel; hold INDEX to the hip track, TRAVEL + and TILT + to bring it back under the mounted leg, then Reacquire closes the holder on it. If the released leg rig is still docked, Reacquire directly. Wait for the leg rig to report engaged before any retention undo. Z removes the most recent bolt, washer and half in reverse order. Each half returns to your hands at the actual connection; store it on the lift shelf and ride to Ground. Remove every fitted retention piece before Unseat lifts the leg back onto the rig; then hold RISE −, TILT −, TRAVEL − and INDEX to return it. The same physical components can be installed again. Never remove retention while the leg rig is released."))
    trial_pelvis["manual"] = pages
    for definition in (trial_leg, trial_pelvis):
        for step in definition["manual"]:
            if step["view"] == "components":
                physical = [definition["slots"][sid]["pose_source"] for sid in step["slots"]]
                step["diagram_views"] = [diagram(step["title"], physical, step.get("context_sources", []))]
    hand_kinds = {kind for kind, spec in parts.items() if spec.get("carry_class") in ("hand", "two_hand")} | {"pv-ring-half"}
    for asset in ("assembly-definitions.json", "pitch-actuator-definitions.json"):
        for kind, spec in json.loads((ASSETS / asset).read_text())["parts"].items():
            if spec.get("carry_class") in ("hand", "two_hand"): hand_kinds.add(kind)
    shelf_support = dict(parts=sorted(hand_kinds))
    added_supports = {rail: dict(assemblies=["left_leg"], assembly_ids=["left_leg"]), crane: {}}
    for lift in workshop_layout["workshop"]["elevators"].values():
        for support_id in lift["shelf"]["supports"]:
            added_supports[support_id] = deepcopy(shelf_support)
    added_supports[crane] = dict(parts=["lg-shin", "lg-knee-fork", "lg-thigh-spar"], item_ids=["LG-100__001", "LG-110__001", "LG-120__001"])
    equipment = deepcopy(content["equipment"])
    for task in workshop_layout["crane"]["tasks"].values():
        if task["load_uid"] not in equipment["parts"]:continue
        info = equipment["parts"][task["load_uid"]]
        assert info["slot"] == task["slot"] and info["support"] == task["source_support"]
        info["delivery_support"] = task["support"]
        info["stock_position"] = list(task["source_pose"]["position"])
    trial = dict(version=1, parts=deepcopy(stock), parents=deepcopy(content["parents"]), supports=added_supports, equipment=equipment,
        robot=dict(staged_slots={"left_leg": [], "pelvis": []}, playable_slots={"left_leg": list(leg_slots), "pelvis": list(pelvis_slots)}, controlled_mount_slots=["left_leg.foot", "pelvis.left_leg"], security_slots=security))
    trial_parts = {"lg-knee-axle": deepcopy(parts["lg-knee-axle"])}
    trial_parts["lg-knee-axle"]["handling"] = dict(rotation_degrees=[90, 90, 0])
    # Exposed frame crossmembers provide the measured transport contacts. They
    # belong to the structural frames, not to drives, armor or extra inventory.
    trial["sources"] = {}
    for uid in ("PV-110__001", "PV-110__002"):
        descriptor = deepcopy(sources[uid])
        # The old rear gusset intruded into the ball's swept volume at the
        # final 47 mm of docking. Keep the socket centre and mounting interface;
        # lift the gusset's lower face above the spherical bearing cavity.
        descriptor["primitives"][-1]["center"][1] = .48
        trial["sources"][uid] = descriptor
    for kind, uid, height in [("lg-shin", "LG-100__001", 2.8), ("lg-thigh-spar", "LG-120__001", 6.1)]:
        descriptor = deepcopy(sources[uid])
        center = [0, height-descriptor["position"][1], 0]
        descriptor["primitives"].append(dict(shape="box", center=center, size=[1.6,.24,.20]))
        trial["sources"][uid] = descriptor
        trial_parts[kind] = deepcopy(parts[kind])
        trial_parts[kind]["collision_shapes"].append(dict(type="box", position=center, size=[1.6,.24,.20]))
    from author_hip_interfaces import extend
    extend(trial, trial_parts, trial_leg, trial_pelvis, diagram)
    from author_right_leg import extend as right_leg_content
    mirrored=right_leg_content(ASSETS,trial,trial_parts,trial_leg,trial_pelvis,parts,sources)
    from author_pelvis import extend as prepared_pelvis
    prepared_pelvis(trial,trial_pelvis,workshop_layout)
    from author_chest import extend as prepared_chest
    chest=prepared_chest(trial,trial_parts,trial_pelvis,workshop_layout,diagram)
    from author_core import extend as prepared_core
    core=prepared_core(trial,chest,workshop_layout,diagram)
    from author_backpack import extend as prepared_backpack
    backpack=prepared_backpack(trial,chest,workshop_layout,trial_parts,diagram)
    from author_arms import extend as prepared_arms
    arms=prepared_arms(trial,workshop_layout,chest)
    from author_cassette import extend as prepared_cassette
    cassette=prepared_cassette(trial,workshop_layout)
    from author_shoulders import extend as shoulder_connections
    shoulder_connections(trial,chest,arms,trial_parts,diagram)
    from author_pauldrons import extend as pauldrons_content
    pauldrons=pauldrons_content(trial,chest,arms,trial_parts,workshop_layout,diagram)
    from author_head import extend as head_content
    head=head_content(trial,chest,trial_parts,workshop_layout,diagram)
    from author_manual_progress import bind, bind_procedures
    chapter_document = json.loads((ASSETS / "manual-chapters.json").read_text())
    bound = {"left_leg": trial_leg, "pelvis": trial_pelvis, "chest": chest, **mirrored}
    bind(bound, chapter_document["chapters"])
    # The left leg teaches each leg rig axis; the right leg repeats the goal
    # with a link back to that first procedure page.
    titled = lambda title: [["pelvis", i] for i, p in enumerate(trial_pelvis["manual"]) if p["title"] == title]
    procedures = bind_procedures(bound, chapter_document["chapters"], {
        "leg_delivery": dict(title="Jog the leg to its hip", machines=["leg_rail"], pages=titled("Seat the leg in the hip assembly")),
        "leg_return": dict(title="Release the leg rig and drive it home", machines=["leg_rail"], pages=titled("Release the leg rig")),
    })
    assert chapter_document.get("procedures") == procedures, "Set manual-chapters.json procedures to " + json.dumps(procedures)
    for task in workshop_layout["crane"]["tasks"].values():
        if task.get("payload")!="assembly":trial["equipment"]["parts"][task["load_uid"]]["stock_position"]=list(task["source_pose"]["position"])
    catalogue_images(check, {key: value for key,value in trial_parts.items() if key not in parts and "catalogue_image" not in value},trial["parts"],trial["sources"])
    return {"robot-definitions.json": dict(version=1, parts=trial_parts, assemblies={"pelvis": trial_pelvis,"chest":chest,"core":core,"backpack":backpack,"arm_cassette":cassette,**arms,**pauldrons,**head,**mirrored}, assembly_patches={"left_leg": assembly_patch(leg, trial_leg)}), "robot-content.json": trial}


def audit_robot(documents):
    overlay, trial = documents["robot-definitions.json"], documents["robot-content.json"]
    audit_standard_hardware({**parts, **overlay["parts"]})
    recipes = materialize_overlay(dict(parts=parts, assemblies={"left_leg": leg, "pelvis": pelvis}), overlay)["assemblies"]
    assert set(overlay["assemblies"]) == {"pelvis","chest","core","backpack","arm_cassette","left_arm","right_arm","left_pauldron","right_pauldron","right_leg","right_foot","right_heel_pad","right_pitch_actuator","head_baseplate","head_left","head_right","head_top","head_crown"}
    for side in ["left","right"]:
        recipe=recipes[side+"_arm"]
        assert len(recipe["context_sources"])==22 and recipe["slots"]=={}
        assert recipe["supplied_milestones"]==["prepared"]
        mass=sum(trial["sources"][uid]["mass_kg"] for uid in recipe["context_sources"])
        moment=sum(trial["sources"][uid]["mass_kg"]*trial["sources"][uid]["mass_center"][2] for uid in recipe["context_sources"])
        assert mass==2033 and .75<moment/mass<4.40
    assert set(recipes["left_arm"]["context_sources"]).isdisjoint(recipes["right_arm"]["context_sources"])
    assert len(trial["parts"]) == len({p["instance_id"] for p in trial["parts"]}) == 380
    assert Counter(p["kind"] for p in trial["parts"])["washer"] == 28
    playable={owner:recipes[owner] for owner in ["left_leg","right_leg","pelvis","chest"]}
    assert sum(len(r["slots"]) for r in playable.values()) == 261
    for owner, recipe in playable.items():
        coverage = Counter(sid for step in recipe["manual"] if step["view"] == "components" for sid in step["slots"])
        assert coverage == Counter({sid: 1 for sid in recipe["slots"]})
        assert all(not step["slots"] for step in recipe["manual"] if step["view"] != "components")
        resolved = set()
        for step in recipe["manual"]:
            for sid in step["slots"]:
                assert set(recipe["slots"][sid]["requires"]) <= resolved
                resolved.add(sid)
        for sid, spec in recipe["slots"].items():
            if owner not in ["left_leg","pelvis"] or sid not in {"left_leg": leg, "pelvis": pelvis}[owner]["slots"]:continue
            assert spec["requires"] == ({"left_leg": leg, "pelvis": pelvis}[owner])["slots"][sid]["requires"]
            assert spec["pose_source"] == ({"left_leg": leg, "pelvis": pelvis}[owner])["slots"][sid]["pose_source"]
    assert recipes["pelvis"]["milestones"]["left_ring_secured"] == pelvis["milestones"]["left_leg_secured"]
    left=set(recipes["pelvis"]["milestones"]["left_leg_secured"])
    right=set(recipes["pelvis"]["milestones"]["right_leg_secured"])
    assert left.isdisjoint(right) and left|right|set(recipes["pelvis"]["milestones"]["chest_connected"])==set(recipes["pelvis"]["slots"])
    needed=Counter(spec["accepts"] for recipe in playable.values() for spec in recipe["slots"].values() if "accepts" in spec)
    extension_ids={part["instance_id"] for part in stock}|{"R-"+part["instance_id"] for part in stock}
    extension_ids |= {part["instance_id"] for part in trial["parts"] if part["kind"].startswith(("pv-","ch-","bp-","sh-","pd-","hd-")) or part["instance_id"].startswith(("LG-W12__","R-LG-W12__"))}
    assert needed == Counter(part["kind"] for part in trial["parts"] if part["instance_id"] in extension_ids)
    assert trial["robot"]["staged_slots"] == {"left_leg": [], "right_leg": [], "pelvis": []}
    for task in ("shin", "fork", "spar"):
        assert recipes["left_leg"]["slots"][task]["source_supports"] == [CRANE_SUPPORT]
        assert all(recipes["left_leg"]["slots"][sid]["undo_requires_support"] == CRANE_SUPPORT for sid in trial["robot"]["security_slots"][task])


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true", help="Audit and byte-compare all generated base and robot assets")
    args = parser.parse_args()
    checking = args.check
    audit()
    # Catalogue images are stable inputs in this consolidation; a recipe check
    # still verifies their generator bytes and records their authored paths.
    catalogue_images(check=checking)
    generated = {
        "leg-prototype-definitions.json": dict(version=1, parts=parts, assemblies={"left_leg": leg, "pelvis": pelvis, "foot": foot}),
        "leg-prototype-content.json": content,
        **robot_documents(checking),
    }
    audit_robot(generated)
    assert leg["milestones"][SPAR_SECURED] == spar_slots
    assert not {"leg_hoist", "leg_fixture", "pelvis_ring_rack_1", "pelvis_ring_rack_2"} & supports.keys()
    assert all(record["location"] == "bin" for record in stock if record["kind"] == "pv-ring-half")
    for name, document in generated.items():
        encoded = json.dumps(document, indent=2, ensure_ascii=False) + "\n"
        if checking:
            assert (ASSETS / name).read_text() == encoded, f"Regenerate {name} with author_leg_prototype.py"
        else:
            (ASSETS / name).write_text(encoded)
    print("LEG_CONTENT_AUDIT PASS: shared layout; 40 base identities; robot workshop 380 extension identities, 261 playable leg/hip/torso slots; byte equality="+str(checking))
