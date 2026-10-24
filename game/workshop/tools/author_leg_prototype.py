"""Author the structural left-leg extension and its leg-bay scenarios without
regenerating the FA-01 GLB.

Run with Python 3 from any directory; --check audits and byte-compares every
generated asset without writing. This script authors parts and interfaces;
assets/leg-bay-layout.json owns shared placement data. This prototype does not
claim a powered or armored leg.
"""
import json
import math
import argparse
from copy import deepcopy
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
ASSETS = ROOT / "game/workshop/assets"
MANIFEST = {p["instance_id"]: p for p in json.loads(
    (ROOT / "models/foot-fa01/output/parts-manifest.json").read_text())["parts"]}
parts, stock, sources = {}, [], {}
# Shared layout authority: authoring and runtime read the same declared data.
LAYOUT = json.loads((ASSETS / "leg-bay-layout.json").read_text())
RAIL = LAYOUT["rail"]
CRANE_SUPPORT = LAYOUT["crane"]["support"]


def layout_document():
    return deepcopy(LAYOUT)


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
kind("lg-m12-50", "LG-H12050", "M12 × 50 axle-cap screw", "pocket", "M12x50")
kind("lg-w24", "LG-W24", "M24 washer", "pocket", "M24")
kind("lg-w12", "LG-W12", "M12 washer", "pocket", "M12")
kind("pv-ring-half", "PV-120", "Hip retaining ring half", "two_hand", "semicircular")
parts["pv-ring-half"]["handling"] = dict(distance=.85, rotation_degrees=[90, 0, 0])
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
        shapes = [tube([0, 0, 0], diameter*.92, diameter*.55, .004, axis)]
    else:
        # Origin is the head-bearing face. Shank points down unless specified.
        sign = 1 if upward else -1
        if axis == "x":
            shapes = [tube([sign*length/2, 0, 0], diameter/2, 0, length, axis),
                      tube([-sign*diameter/2, 0, 0], diameter*.75, 0, diameter, axis)]
        else:
            shapes = [tube([0, sign*length/2, 0], diameter/2, 0, length, axis),
                      tube([0, -sign*diameter/2, 0], diameter*.75, 0, diameter, axis)]
    source(uid, family, position, shapes)
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


def page(pages, title, body, ids, context=()):
    pages.append(dict(title=title, body=body, slots=list(ids), view="components", context_sources=list(context)))


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
    w = hardware("LG-W12", "lg-w12", n, [.572, 5.1, z], .012, 0, True, axis="x")
    b = hardware("LG-H12050", "lg-m12-50", n, [.574, 5.1, z], .012, .05, axis="x")
    ws = slot(leg_slots, f"cap/washer_{n}", "lg-w12", w, ["cap"], target_offset=[.003, 0, 0])
    cap_slots += [ws, slot(leg_slots, f"cap/screw_{n}", "lg-m12-50", b, [ws], target_offset=[.014, 0, 0])]
page(leg_pages, "Retain the knee axle", "Fit LG-150 on the exposed axle end. Fit two LG-W12 washers and two LG-H12050 screws from the right side into the axle end pad. Both screw heads remain outside the fork.", cap_slots, ["LG-110__001", "LG-140__001"])
slot(leg_slots, "spar", "lg-thigh-spar", "LG-120__001", cap_slots,
     support_required=True, source_supports=[CRANE_SUPPORT])
spar_slots = ["spar"]
for n, (x, z) in enumerate(((x, z) for x in (-.25, .25) for z in (-.20, .20)), 1):
    w = hardware("LG-W24", "lg-w24", n, [x, 5.962, z], .024, 0, True)
    b = hardware("LG-H24100", "lg-m24-100", n, [x, 5.964, z], .024, .1)
    ws = slot(leg_slots, f"fork/washer_{n}", "lg-w24", w, ["spar"], target_offset=[0, .003, 0])
    spar_slots += [ws, slot(leg_slots, f"fork/bolt_{n}", "lg-m24-100", b, [ws], target_offset=[0, .026, 0])]
page(leg_pages, "Join the thigh spar", "Use the service crane to lower LG-120 onto the already fitted LG-110 fork flange. The hip ball and neck are integral to LG-120. Fit four LG-W24 washers and four LG-H24100 bolts downward through the exposed flange corners.", spar_slots, ["LG-110__001"])
leg_pages.append(dict(title="Structural leg ready", body="The load-bearing prototype is structurally ready. Use the leg rail to carry it to the pelvis gantry. Knee and ankle transport braces belong to the handling equipment; powered knee and hip actuators, services, armor and calf thrusters remain deferred. Open the pelvis manual for seating and retention.", slots=list(leg_slots), view="prepared"))
leg = dict(title="Left leg · structural prototype", carry_class="equipment", bounds=[1.4, 9.65, 3.0],
           work_locations=["support"], interaction="components", service_access="assisted",
           slots=leg_slots, milestones={"structural_ready": list(leg_slots),
                                      LAYOUT["crane"]["secured"]["milestone"]: spar_slots}, manual=leg_pages)

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
page(pelvis_pages, "Seat the supported leg", "The braced pelvis bridge and both bolted socket housings are already fitted on the gantry. With the left ring removed, use the leg rail to dock the LG-120 hip ball upward into the left socket's open underside. Keep rail support until all retaining bolts are fitted.", ["left_leg"], context_sources)
for n in (1, 2):
    slot(pelvis_slots, f"ring_{n}", "pv-ring-half", f"PV-120__{n:03}", ["left_leg"])
page(pelvis_pages, "Fit the split retaining ring", "Carry and fit both PV-120 semicircular halves around the already seated LG-120 neck from opposite sides. Either identical half fits either destination. Their inward lips capture the ball with clearance around the neck.", ["ring_1", "ring_2"], ["PV-110__001", "LG-120__001"])
ring_fasteners = []
for n, (x, z, _) in enumerate(ring_holes, 1):
    w = hardware("LG-W24", "lg-w24", n+4, [-1.1+x, -.432, z], .024, 0, True)
    b = hardware("PV-H24140", "pv-m24-140", n, [-1.1+x, -.434, z], .024, .14, upward=True)
    ring_sid = "ring_1" if z < 0 else "ring_2"
    ws = slot(pelvis_slots, f"ring/washer_{n}", "lg-w24", w, [ring_sid], target_offset=[0, -.003, 0])
    ring_fasteners += [ws, slot(pelvis_slots, f"ring/bolt_{n}", "pv-m24-140", b, [ws], target_offset=[0, -.026, 0])]
page(pelvis_pages, "Bolt the ring to the socket", "Fit four LG-W24 washers and four PV-H24140 bolts upward from the split ring's exposed underside into the left socket flange. Both halves must be fitted and all four bolts installed before releasing rail support. To remove the leg, reacquire rail support first, then reverse the retention steps.", ring_fasteners, ["PV-110__001", "PV-120__001", "PV-120__002"])
pelvis_pages.append(dict(title="Left leg structurally mounted", body="The left ball is captured by both bolted ring halves. The gantry and mechanical transport braces support this unpowered prototype. This is structural readiness; hydraulic actuators, services and armor remain deferred.", slots=list(pelvis_slots), view="prepared"))
pelvis = dict(title="Pelvis · left leg installation", bounds=[3.6, 1.5, 1.5], work_locations=["fixture"],
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
    CRANE_SUPPORT: {"parts": ["lg-thigh-spar"], "item_ids": [LAYOUT["crane"]["load_uid"]]},
    "leg_shin_rack": {"parts": ["lg-shin"]},
    "leg_fork_rack": {"parts": ["lg-knee-fork"]},
    "leg_spar_rack": {"parts": ["lg-thigh-spar"]},
}
content = dict(version=1, parts=stock, parents=[
    dict(id="left_leg", definition="left_leg", label="Structural left leg", location="support:"+RAIL["support"], home=LAYOUT["parent_homes"]["left_leg"]),
    dict(id="pelvis", definition="pelvis", label="Pelvis gantry", location="fixture", home=LAYOUT["parent_homes"]["pelvis"]),
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


def catalogue_images(check=False):
    """Small schematic thumbnails derived from actual descriptor primitive sizes.

    These support catalogue recognition, not rendered construction approval.
    """
    import html
    for key, definition in parts.items():
        record = next(p for p in stock if p["kind"] == key)
        shapes = sources.get(record["source_id"], {}).get("primitives", [])
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
    crane = LAYOUT["crane"]
    assert crane["load_uid"] in ids and crane["owner"] == "left_leg" and crane["slot"] in leg_slots
    assert crane["route_positions"][0] == crane["source_pose"]["position"]
    assert crane["route_positions"][-1] == crane["receiver_pose"]["position"]
    assert len(crane["endpoint_ids"]) == len(crane["magnetic_points"]) == 2
    assert len(set(crane["endpoint_ids"])) == 2
    assert len(crane["route_positions"]) == 5
    assert all(len(point) == 3 and all(isinstance(v, (float, int)) and math.isfinite(v) for v in point)
               for point in crane["route_positions"] + list(crane["magnetic_points"].values()))


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


def m2_documents():
    """Small trial overlays on the shared leg-bay recipes.

    Keep full recipes and readiness criteria for safe staging and validation.
    Only trial installation pages are replaced. `playable_slots` is the manual
    coverage boundary, not a smaller definition of a structurally secured hip.
    """
    layout = layout_document()
    rail, crane = layout["rail"]["support"], layout["crane"]["support"]
    hand_kinds = {kind for kind, spec in parts.items() if spec.get("carry_class") in ("hand", "two_hand")} | {"pv-ring-half"}
    for asset in ("assembly-definitions.json", "pitch-actuator-definitions.json"):
        for kind, spec in json.loads((ASSETS / asset).read_text())["parts"].items():
            if spec.get("carry_class") in ("hand", "two_hand"): hand_kinds.add(kind)
    beam_slots = ["spar"] + [sid for sid in leg_slots if sid.startswith("fork/")]
    half_slots = ["ring_1", "ring/washer_3", "ring/bolt_3", "ring/washer_4", "ring/bolt_4"]
    pre_spar = [sid for sid in leg_slots if sid != "spar" and not sid.startswith("fork/")]
    added_supports = {
        rail: dict(assemblies=["left_leg"], assembly_ids=["left_leg"]),
        crane: dict(parts=["lg-thigh-spar"], item_ids=["LG-120__001"]),
        "m2_lift_shelf_0": dict(parts=sorted(hand_kinds)),
        "m2_lift_shelf_1": dict(parts=sorted(hand_kinds)),
    }
    beam = deepcopy(parts["lg-thigh-spar"])
    beam.update(title="LG-120 · Upper-leg beam", short_title="Upper-leg beam",
                catalogue_image="res://assets/part-images/lg-thigh-spar.svg")
    crane_metadata = {key: deepcopy(layout["crane"][key]) for key in
                      ("support", "source_support", "load_uid", "source_pose", "receiver_pose",
                       "magnetic_points", "endpoint_ids", "approach", "route_positions")}
    crane_metadata.update(destination=dict(owner=layout["crane"]["owner"], slot=layout["crane"]["slot"]),
                          route_version=2, fastener_slots=beam_slots[1:])
    documents = {}
    for example in ("retention", "crane"):
        trial_leg, trial_pelvis = deepcopy(leg), deepcopy(pelvis)
        trial_leg["slots"]["spar"].update(label=beam["title"], source_supports=[crane])
        trial_pelvis["slots"]["left_leg"]["source_supports"] = [rail]
        for sid in ("ring_1", "ring_2"):
            trial_pelvis["slots"][sid].pop("source_supports", None)
            trial_pelvis["slots"][sid].pop("support_required", None)
        trial_leg["manual"] = [dict(title="Supplied leg construction", view="overview", slots=[],
            body="The complete existing foot and structural leg are supplied on the home rail for this hip-retainer example. Open the pelvis manual; internal construction is outside this example.")]
        trial_pelvis["manual"] = [dict(title="Hip work is outside this example", view="overview", slots=[],
            body="This example ends with the Upper-leg beam fastened and the empty crane parked. The horizontal foot, shin, knee, fork and cap are supplied. Hip mounting and retention belong to the separate Hip retainer example.")]
        if example == "retention":
            for sid in ("ring_1", "ring_2"):
                trial_pelvis["slots"][sid]["undo_to"] = "hands"
            trial_pelvis["manual"] = [dict(title="Travel, tilt and seat the supported leg", view="overview", slots=[],
                body="The complete leg starts on its home rail; the pelvis socket and retaining connections are empty. Walk the rail controls through travel, tilt and upward docking. The rail seats the hip ball and remains engaged as assistance. Board the personnel lift and use Up. One retaining half and its two washer/bolt pairs are supplied; this example cannot secure the complete hip.",
                context_sources=["PV-110__001"])]
            page(trial_pelvis["manual"], "Seat one hip retaining half",
                 "Collect the two washer/bolt pairs into your pockets at ground level. E picks up PV-120 with both hands. Carry it onto the lift and click the component shelf to store it. The shelf holds two one-hand components or one two-hand component. Ride Up, E-pick the half from the shelf, then aim and click the underside connection of the already seated socket. Either identical half fits.",
                 half_slots[:1], ["PV-110__001", "PV-V-HIP-BALL"])
            page(trial_pelvis["manual"], "Fasten the supported half",
                 "Fit the pocketed LG-W24 washers and PV-H24140 bolts upward through the seated half into the socket flange, each washer before its bolt. Z reverses these steps. Undoing the half returns that same component to your hands at the connection; store it on the lift shelf to bring it down. Retention blocks rail Return until every fitted retention piece is removed.",
                 half_slots[1:], ["PV-110__001", "PV-120__001"])
            trial_pelvis["manual"].append(dict(title="One-half example complete", view="prepared", slots=[],
                body="One bolted half does not secure the hip. Holder departure is unavailable. Undo with Z, return the half on the lift shelf, then use rail Return to withdraw the supported leg. Both-half completion remains outside M2."))
        else:
            trial_leg["manual"] = [dict(title="Supplied horizontal receiving assembly", view="overview", slots=[],
                body="The complete existing foot and the horizontal shin, bearings, spacers, knee fork, axle and cap are supplied on the home rail. The real LG-120 Upper-leg beam remains on its rack; four LG-W24 washers and four LG-H24100 bolts remain loose stock. No beam or flange hardware is preinstalled.")]
            page(trial_leg["manual"], "Deliver the Upper-leg beam",
                 "At the central crane console, choose Go to Upper-leg beam rack, then Down. The console captures the view: click a command or use arrow keys and E; Q closes it. Travel destinations appear only while Up. Walk to its source rack, E-pick a magnetic end and aim/click a free marked point; repeat for the other end. Either end fits either point; Q stows a held end. Return to the console and choose Up, then Go to Leg cradle, then Down. The crane takes the same LG-120 from the rack, reaches the receiving cradle and seats the flange through the final 0.20 m axial approach toward −Z. These horizontal flanges cannot mate by a vertical drop. Keep both cables attached during fastening.",
                 beam_slots[:1], ["LG-110__001"])
            page(trial_leg["manual"], "Fasten the Upper-leg beam flange",
                 "Collect four LG-W24 washers and four LG-H24100 bolts normally. On the already seated Upper-leg beam, fit each washer and then its bolt through the four exposed flange corners into the existing fork. On the horizontal assembly, work from the exposed +Z head faces and insert toward −Z. Keep crane assistance until all four pairs are fitted, then detach and stow both magnetic ends and park the empty crane. For recovery before any flange hardware is fitted, Up at the leg cradle removes the supported beam and reverses the axial approach. Choose Go to Upper-leg beam rack, then Down to return it. Undo all fitted flange hardware with Z before lifting a loaded beam.",
                 beam_slots[1:], ["LG-110__001", "LG-120__001"])
            trial_leg["manual"].append(dict(title="Crane-delivery example complete", view="prepared", slots=[],
                body="The Upper-leg beam is fastened to the supplied horizontal leg and the magnetic ends can be stowed before parking the empty crane. Full released-beam disassembly and the whole leg-to-robot journey remain outside this example."))
        for definition in (trial_leg, trial_pelvis):
            for step in definition["manual"]:
                if step["view"] != "components":
                    continue
                physical = [definition["slots"][sid]["pose_source"] for sid in step["slots"]]
                step["diagram_views"] = [diagram(step["title"], physical, step.get("context_sources", []))]
        allowed = {s["pose_source"] for s in leg_slots.values() if "accepts" in s}
        if example == "retention":
            allowed.update(pelvis_slots[sid]["pose_source"] for sid in half_slots)
        trial_stock = [deepcopy(p) for p in stock if p["instance_id"] in allowed]
        for record in trial_stock:
            if record["kind"] == "pv-ring-half":
                record["location"] = "bin"
        parents = deepcopy(content["parents"])
        parents[0]["location"] = "support:" + rail
        equipment = dict(leg_mount=dict(parent="pelvis", slot="left_leg", support=rail),
                         parts={"LG-120__001": dict(owner="left_leg", slot="spar", support="leg_spar_rack", delivery_support=crane,
                                                  stock_position=list(layout["crane"]["source_pose"]["position"]))})
        trial = dict(version=1, parts=trial_stock, parents=parents, supports=deepcopy(added_supports), equipment=equipment,
            m2=dict(scenario_id="m2-" + example, scenario_version=2, equipment_version=2, route_version=2,
                    remove_supports=[],
                    save_path="user://m2-" + example + "-save.json",
                    staged_slots={"left_leg": list(leg_slots) if example == "retention" else pre_spar, "pelvis": []},
                    playable_slots={"left_leg": [] if example == "retention" else beam_slots,
                                    "pelvis": half_slots if example == "retention" else []},
                    controlled_mount_slots=["pelvis.left_leg"] if example == "retention" else [],
                    representative_half="ring_1", retention_uid="PV-120__001" if example == "retention" else "",
                    crane=deepcopy(crane_metadata),
                    supplied_construction=trial_pelvis["manual"][0]["body"] if example == "retention" else trial_leg["manual"][0]["body"]))
        documents[f"m2-{example}-definitions.json"] = dict(version=2, parts={"lg-thigh-spar": deepcopy(beam), "pv-ring-half": dict(deepcopy(parts["pv-ring-half"]), carry_class="two_hand", catalogue_image="res://assets/part-images/pv-ring-half.svg", handling=dict(distance=.85, rotation_degrees=[90, 0, 0]))},
            assembly_patches={"left_leg": assembly_patch(leg, trial_leg),
                              "pelvis": assembly_patch(pelvis, trial_pelvis)})
        documents[f"m2-{example}-content.json"] = trial
    return documents


def audit_m2(documents):
    """Inventory, dependencies, slot ownership and step shopping-list boundary."""
    for example in ("retention", "crane"):
        overlay = documents[f"m2-{example}-definitions.json"]
        definitions = materialize_overlay(dict(parts=parts, assemblies={"left_leg": leg, "pelvis": pelvis}), overlay)
        assert "assemblies" not in overlay and overlay["assembly_patches"], "Trials must patch the base recipes"
        trial = documents[f"m2-{example}-content.json"]
        recipe = definitions["assemblies"]
        ids = [record["instance_id"] for record in trial["parts"]]
        assert len(ids) == len(set(ids))
        assert recipe["pelvis"]["milestones"] == pelvis["milestones"]
        assert recipe["left_leg"]["milestones"] == leg["milestones"]
        assert recipe["left_leg"]["slots"]["spar"]["source_supports"] == ["m2_service_crane"]
        assert recipe["pelvis"]["slots"]["left_leg"]["source_supports"] == ["m2_leg_rail"]
        assert all(not recipe["pelvis"]["slots"][sid].get("support_required", False) for sid in ("ring_1", "ring_2"))
        assert definitions["parts"]["pv-ring-half"]["carry_class"] == "two_hand"
        for owner, definition in recipe.items():
            coverage = Counter(sid for step in definition["manual"] if step["view"] == "components" for sid in step["slots"])
            assert coverage == Counter({sid: 1 for sid in trial["m2"]["playable_slots"][owner]})
            assert all(not step["slots"] for step in definition["manual"] if step["view"] != "components")
            resolved = set(trial["m2"]["staged_slots"][owner])
            if owner == "pelvis" and example == "retention":
                resolved.add("left_leg")  # Real rail-controlled mounting precedes manual work.
            for step in definition["manual"]:
                if step["view"] != "components":
                    continue
                for sid in step["slots"]:
                    assert set(definition["slots"][sid]["requires"]) <= resolved, (example, owner, sid)
                    assert definition["slots"][sid]["pose_source"] in ids
                    resolved.add(sid)
        if example == "retention":
            assert len(ids) == 35 and "PV-120__001" in ids and "PV-120__002" not in ids
            assert [sid for sid in trial["m2"]["playable_slots"]["pelvis"] if sid.startswith("ring/")] == ["ring/washer_3", "ring/bolt_3", "ring/washer_4", "ring/bolt_4"]
            assert Counter(record["kind"] for record in trial["parts"])["pv-m24-140"] == 2
        else:
            assert len(ids) == 30 and len(trial["m2"]["staged_slots"]["left_leg"]) == 22
            assert not any(record["kind"].startswith("pv-") for record in trial["parts"])
            assert next(record for record in trial["parts"] if record["instance_id"] == "LG-120__001")["location"] == "support:leg_spar_rack"
        assert recipe["pelvis"]["slots"]["ring_1"]["accepts"] == recipe["pelvis"]["slots"]["ring_2"]["accepts"] == "pv-ring-half"
        assert all(recipe["pelvis"]["slots"][sid].get("undo_to") == ("hands" if example == "retention" else None) for sid in ("ring_1", "ring_2"))
        assert recipe["pelvis"]["slots"]["ring/washer_3"]["accepts"] == recipe["left_leg"]["slots"]["fork/washer_1"]["accepts"] == "lg-w24"



def m3_documents():
    """Complete prepared-foot journey, patching the canonical slot graph."""
    rail, crane = RAIL["support"], CRANE_SUPPORT
    m3_layout = json.loads((ASSETS / "leg-bay-m3-layout.json").read_text())
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
    pages.append(dict(title="Prepared foot, empty leg rail", view="overview", slots=[], body="The complete 135-piece foot is supplied on its carrier. The horizontal leg rail and pelvis connections are empty. Build the leg here, then open the pelvis manual for rail travel, seating and retention. Knee and ankle transport braces are equipment, not loose parts."))
    page(pages, "Dock the prepared foot", "At the foot carrier, Advance raises the complete foot; Advance again turns and seats it in the horizontal rail holder. The guided carrier keeps support until the holder takes contact and locks ankle motion. Keep the rail at its home construction position.", ["foot"])
    def delivery(title, task, uid, receiver):
        task_title = m3_layout["crane"]["tasks"][task]["title"]
        page(pages, title, "At the central crane console, with the empty crane parked and both magnetic ends stowed, select the " + task_title + " task. Choose Go to its rack, then Down. Q closes the console; click commands or use arrow keys and E. At the rack E picks up a magnetic end; aim and click either free marked point, then attach the other end. Either end fits either point. Q stows a held end. Choose Up to take weight, Go to Leg cradle, then Down to seat " + uid + " against the already fitted " + receiver + ". The crane lowers the component, then approaches along the leg to mate the connection. Keep both ends attached until this task's retaining hardware is complete.", [task])
    delivery("Deliver the structural shin", "shin", "LG-100", "foot adapter")
    page(pages, "Secure the ankle flange", "Collect four W-36 washers and four H-36090 bolts into pockets. Fit each washer before its bolt on the exposed shin flange. Approach the bolt heads from the knee side of the flange and insert toward the foot into the already fitted FA-201 adapter. After all four pairs, detach and stow both magnetic ends, raise and park the empty crane before changing task.", flange_slots, ["LG-100__001", "FA-201__001"])
    page(pages, "Connect the shin disconnect", "Carry FA-605 with both attached plugs. Approach from the side away from the crane racks, standing back toward the knee. Leave room for the upright harness to turn clear of the ankle brace before fitting it. Seat its box end in the already fitted FA-604 socket, follow the foot guide clips and seat the upper keyed plug in LG-100's angled socket. The harness and knee-bearing branches can be completed in either order after the ankle bolts. Unplug this harness before separating foot and shin.", ["main_input"], ["FA-604__001", "LG-100__001"])
    page(pages, "Seat bearings and thrust spacers", "Carry and fit the two LG-130 bearings from opposite sides of the shin knee boss, then one LG-135 thrust spacer against each end. Bearings are interchangeable with bearings; spacers are interchangeable with spacers. Keep the marked knee axle extraction aisle clear.", bearings + thrust, ["LG-100__001"])
    delivery("Deliver the knee fork", "fork", "LG-110", "shin knee boss and thrust spacers")
    page(pages, "Insert the knee axle", "Carry LG-140 lengthwise with both hands. Stand back at the marked axle extraction aisle so the shaft can align with the bore, then insert through the already seated fork and bearings until its shoulder contacts the fork. The rail brace keeps the knee straight and crane assistance remains attached.", ["axle"], ["LG-110__001"])
    page(pages, "Retain the knee axle", "Walk to the opposite side from the marked axle extraction aisle. Fit LG-150 on the exposed axle end, then two LG-W12 washers and two LG-H12050 screws, each washer before its screw. With the axle and both cap pairs complete, detach and stow both magnetic ends, raise and park the empty crane.", cap_slots, ["LG-110__001", "LG-140__001"])
    delivery("Deliver the Upper-leg beam", "spar", "LG-120", "fork flange")
    page(pages, "Fasten the Upper-leg beam flange", "Pocket four LG-W24 washers and four LG-H24100 bolts. Fit each washer and then its bolt through the exposed flange corners into the already fitted fork. Approach the bolt heads from the hip side of the flange and insert toward the knee. These M24 x 100 bolts differ from the pelvis M24 x 140 bolts. After every pair is fitted, detach and stow both magnetic ends, then raise and park the empty crane.", spar_slots[1:], ["LG-110__001", "LG-120__001"])
    pages.append(dict(title="Structural leg ready", view="prepared", slots=[], body="All leg construction is complete. Confirm the empty crane is parked with both magnetic ends stowed, then open the pelvis manual. The rail continues to support the complete leg."))
    pages.append(dict(title="Supported construction recovery", view="overview", slots=[], body="Return the supported leg home before construction disassembly. Select the affected crane task, lower at the leg cradle and attach both magnetic ends to reacquire support before Z removes its retaining hardware. Reverse each task: remove all flange pairs before lifting shin or beam; remove cap screws, washers, cap and axle before lifting the fork. Up withdraws the supported part through the reverse axial approach; Go to its rack and Down returns it. Detach and stow only after rack contact. Undo FA-605 before shin removal. With all structural work removed and the rail home, foot-carrier Return reacquires the foot and reverses one guided phase per press; Return again lowers it to the dispatch position."))
    trial_leg["manual"] = pages
    pages = [dict(title="Travel and seat the supported leg", view="overview", slots=[], body="The pelvis bridge, both sockets and their bridge bolts are supplied context. Keep the rail engaged throughout travel, tilt and upward docking. Use local rail Advance controls through each supported stage; Stop holds the current stage. Retention is performed from the personnel lift. Retention blocks loaded Return.")]
    page(pages, "Seat the leg in the pelvis", "With the completed leg and parked empty crane, operate the rail through travel and tilt, then Advance upward into the open left socket. The rail seats the hip ball and stays engaged. Ball seating alone does not secure the leg.", ["left_leg"], context_sources)
    for half, pairs in ((1, (3, 4)), (2, (1, 2))):
        page(pages, "Carry retaining half " + str(half), "E picks up either PV-120 half with both hands. Carry it onto the personnel lift and click the shelf to store it. The shelf holds one two-hand component or two one-hand components; take one half per trip. Ride Up, E-pick it from the shelf, then aim and click its underside connection around the already seated hip neck. Either physical half fits either destination.", ["ring_" + str(half)], ["PV-110__001", "PV-V-HIP-BALL"])
        ids = [sid for n in pairs for sid in ("ring/washer_" + str(n), "ring/bolt_" + str(n))]
        access_note = "Move toward the hip-facing end of the lift's working corner to see the far underside washer seats past the beam. " if half == 2 else ""
        page(pages, "Fasten retaining half " + str(half), "Pocket two LG-W24 washers and two PV-H24140 M24 x 140 bolts at ground level. " + access_note + "Fit each washer then its bolt upward from the seated half's underside into the existing socket flange. The shared LG-W24 stock also supplies the fork flange. Keep rail assistance engaged; a single fastened half cannot retain the complete hip.", ids, ["PV-110__001", "PV-120__%03d" % half])
    pages.append(dict(title="Left leg structurally secured", view="prepared", slots=[], body="Both halves and all four washer/bolt pairs are required. With the complete retention set fitted, press rail Advance to release the holder jaws. The pelvis now owns and supports the mounted leg. Return now withdraws the empty holder one phase per press along its reverse docking, tilt and travel route; the mounted leg stays at the pelvis. Powered actuators, services and armor remain deferred."))
    pages.append(dict(title="Reacquire support and recover", view="overview", slots=[], body="If the empty holder has returned home, use Advance through travel, tilt and upward docking to bring it back under the mounted leg. The final docking motion automatically closes the holder jaws and reacquires support. If the released holder is already docked, Advance directly reacquires support. Wait for the holder to report engaged before any retention undo. Z removes the most recent bolt, washer and half in reverse order. Each half returns to your hands at the actual connection; store it on the lift shelf and ride to Ground. Remove every fitted retention piece before rail Return can unseat the leg, lower, reverse tilt and travel home, one phase per press. The same physical components can be installed again. Never remove retention while the holder is released."))
    trial_pelvis["manual"] = pages
    for definition in (trial_leg, trial_pelvis):
        for step in definition["manual"]:
            if step["view"] == "components":
                physical = [definition["slots"][sid]["pose_source"] for sid in step["slots"]]
                step["diagram_views"] = [diagram(step["title"], physical, step.get("context_sources", []))]
    added_supports = deepcopy(m2_documents()["m2-crane-content.json"]["supports"])
    added_supports[crane] = dict(parts=["lg-shin", "lg-knee-fork", "lg-thigh-spar"], item_ids=["LG-100__001", "LG-110__001", "LG-120__001"])
    equipment = deepcopy(content["equipment"])
    for task in m3_layout["crane"]["tasks"].values():
        info = equipment["parts"][task["load_uid"]]
        assert info["slot"] == task["slot"] and info["support"] == task["source_support"]
        info["delivery_support"] = task["support"]
        info["stock_position"] = list(task["source_pose"]["position"])
    trial = dict(version=1, parts=deepcopy(stock), parents=deepcopy(content["parents"]), supports=added_supports, equipment=equipment,
        m3=dict(scenario_id="leg_bay_m3", scenario_version=1, equipment_version=1, route_version=1, remove_supports=[], save_path="user://m3-workshop-save.json", prepared_foot=True,
                staged_slots={"left_leg": [], "pelvis": []}, playable_slots={"left_leg": list(leg_slots), "pelvis": list(pelvis_slots)}, controlled_mount_slots=["left_leg.foot", "pelvis.left_leg"], security_slots=security))
    trial_parts = {"lg-knee-axle": deepcopy(parts["lg-knee-axle"])}
    trial_parts["lg-knee-axle"]["handling"] = dict(rotation_degrees=[90, 90, 0])
    return {"m3-definitions.json": dict(version=1, parts=trial_parts, assembly_patches={"left_leg": assembly_patch(leg, trial_leg), "pelvis": assembly_patch(pelvis, trial_pelvis)}), "m3-content.json": trial}


def audit_m3(documents):
    overlay, trial = documents["m3-definitions.json"], documents["m3-content.json"]
    recipes = materialize_overlay(dict(parts=parts, assemblies={"left_leg": leg, "pelvis": pelvis}), overlay)["assemblies"]
    assert "assemblies" not in overlay
    assert len(trial["parts"]) == len({p["instance_id"] for p in trial["parts"]}) == 40
    assert Counter(p["kind"] for p in trial["parts"])["lg-w24"] == 8
    assert sum(len(r["slots"]) for r in recipes.values()) == 42
    for owner, recipe in recipes.items():
        coverage = Counter(sid for step in recipe["manual"] if step["view"] == "components" for sid in step["slots"])
        assert coverage == Counter({sid: 1 for sid in recipe["slots"]})
        assert all(not step["slots"] for step in recipe["manual"] if step["view"] != "components")
        resolved = set()
        for step in recipe["manual"]:
            for sid in step["slots"]:
                assert set(recipe["slots"][sid]["requires"]) <= resolved
                resolved.add(sid)
        for sid, spec in recipe["slots"].items():
            assert spec["requires"] == ({"left_leg": leg, "pelvis": pelvis}[owner])["slots"][sid]["requires"]
            assert spec["pose_source"] == ({"left_leg": leg, "pelvis": pelvis}[owner])["slots"][sid]["pose_source"]
    assert recipes["pelvis"]["milestones"] == pelvis["milestones"]
    assert trial["m3"]["staged_slots"] == {"left_leg": [], "pelvis": []}
    for task in ("shin", "fork", "spar"):
        assert recipes["left_leg"]["slots"][task]["source_supports"] == [CRANE_SUPPORT]
        assert all(recipes["left_leg"]["slots"][sid]["undo_requires_support"] == CRANE_SUPPORT for sid in trial["m3"]["security_slots"][task])


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true", help="Audit and byte-compare all generated base and trial assets")
    parser.add_argument("--m2", action="store_true", help="Compatibility alias; regenerate shared base and trial assets")
    parser.add_argument("--check-m2", action="store_true", help="Compatibility alias for --check")
    args = parser.parse_args()
    checking = args.check or args.check_m2
    audit()
    # Catalogue images are stable inputs in this consolidation; a recipe check
    # still verifies their generator bytes and records their authored paths.
    catalogue_images(check=checking)
    generated = {
        "leg-prototype-definitions.json": dict(version=1, parts=parts, assemblies={"left_leg": leg, "pelvis": pelvis, "foot": foot}),
        "leg-prototype-content.json": content,
        **m2_documents(),
        **m3_documents(),
    }
    audit_m2(generated)
    audit_m3(generated)
    assert LAYOUT["version"] == 1
    secure = LAYOUT["crane"]["secured"]["milestone"]
    assert secure in leg["milestones"] and leg["milestones"][secure] == spar_slots
    assert not {"leg_hoist", "leg_fixture", "pelvis_ring_rack_1", "pelvis_ring_rack_2"} & supports.keys()
    assert all(record["location"] == "bin" for record in stock if record["kind"] == "pv-ring-half")
    for name, document in generated.items():
        encoded = json.dumps(document, indent=2, ensure_ascii=False) + "\n"
        if checking:
            assert (ASSETS / name).read_text() == encoded, f"Regenerate {name} with author_leg_prototype.py"
        else:
            (ASSETS / name).write_text(encoded)
    print("LEG_CONTENT_AUDIT PASS: shared layout; 40 base identities; two M2 trials and complete M3; M3 40 extension identities, 42 playable slots; byte equality="+str(checking))
