"""Reproduce the FA-01 reference-envelope review; this is not a CAD solver.

Run from any directory with Python 3. Results are written beside this file.
Units: millimetres and degrees. Positive pitch leans the shin forward.
"""

import collections
import csv
import itertools
import json
import math
from pathlib import Path


def add(a, b):
    return tuple(x + y for x, y in zip(a, b))


def sub(a, b):
    return tuple(x - y for x, y in zip(a, b))


def rx(p, degrees):
    x, y, z = p
    c, s = math.cos(math.radians(degrees)), math.sin(math.radians(degrees))
    return x, c * y - s * z, s * y + c * z


def ry(p, degrees):
    x, y, z = p
    c, s = math.cos(math.radians(degrees)), math.sin(math.radians(degrees))
    return c * x + s * z, y, -s * x + c * z


def distance(a, b):
    return math.sqrt(sum(v * v for v in sub(a, b)))


def box_vertices(bounds):
    return list(itertools.product(*bounds))


def clip_box_below(vertices, height):
    """Corners and exact edge intersections of a convex box clipped by Z."""
    result = [p for p in vertices if p[2] <= height]
    for i in range(8):
        for bit in (1, 2, 4):
            j = i ^ bit
            if j <= i:
                continue
            a, b = vertices[i], vertices[j]
            if (a[2] - height) * (b[2] - height) < 0:
                t = (height - a[2]) / (b[2] - a[2])
                result.append(tuple(x + t * (y - x) for x, y in zip(a, b)))
    return result


def stroke_result(lengths, limits):
    lo, hi = min(lengths), max(lengths)
    differences = [b - a for a, b in zip(lengths, lengths[1:])]
    monotonic = all(d > 0 for d in differences) or all(d < 0 for d in differences)
    return {
        "minimum_length_mm": round(lo, 2),
        "maximum_length_mm": round(hi, 2),
        "specified_length_limits_mm": limits,
        "retraction_margin_mm": round(lo - limits[0], 2),
        "extension_margin_mm": round(limits[1] - hi, 2),
        "monotonic_over_sampled_range": monotonic,
        "passes": limits[0] < lo and hi < limits[1] and monotonic,
    }


def inventory_result():
    folder = Path(__file__).parent
    by_bolt = collections.Counter()
    by_washer = collections.Counter()
    with (folder / "hardware.csv").open() as handle:
        for row in csv.DictReader(handle):
            quantity = int(row["quantity_per_foot"])
            by_bolt[row["bolt_id"]] += quantity
            by_washer[row["washer_id"]] += quantity
    tables = {}
    for line in (folder / "parts.md").read_text().splitlines():
        cells = [cell.strip() for cell in line.strip("|").split("|")]
        if len(cells) >= 3 and cells[0].startswith(("FA-", "H-", "W-")) and cells[2].isdigit():
            tables[cells[0]] = int(cells[2])
    parts = sum(q for part_id, q in tables.items() if part_id.startswith("FA-"))
    bolts, washers = sum(by_bolt.values()), sum(by_washer.values())
    agrees = all(tables.get(k) == q for k, q in (by_bolt | by_washer).items())
    return {
        "component_pieces_and_modules": parts,
        "bolts_and_screws": bolts,
        "fastener_washers": washers,
        "total_assembly_objects": parts + bolts + washers,
        "documented_schedule_matches_csv": agrees,
        "passes": agrees and (parts, bolts, washers) == (229, 258, 258),
    }


def run():
    ankle = (0, 0, 1000)
    hinge = (0, 1200, 350)
    pitch_angles = range(-20, 21)
    roll_angles = range(-10, 11)
    toe_angles = [i / 2 for i in range(61)]

    pitch_lengths = [
        distance((-540, 800, 480), add(ankle, rx((-540, 300, 0), -p)))
        for p in pitch_angles
    ]
    roll_lengths = [
        distance((500, -450, -150), ry((200, -450, 320), r))
        for r in roll_angles
    ]
    toe_lengths = [
        distance((0, 650, 520), add(hinge, rx((0, 60, 220), t)))
        for t in toe_angles
    ]

    shin = box_vertices(((-450, 450), (-450, 450), (650, 1100)))
    shin_gap = math.inf
    shin_pose = None
    for p, r in itertools.product(pitch_angles, roll_angles):
        vertices = [add(ankle, rx(ry(v, r), -p)) for v in shin]
        clipped = clip_box_below(vertices, 1600)
        if clipped:
            gap = 630 - max(abs(v[0]) for v in clipped)
            if gap < shin_gap:
                shin_gap, shin_pose = gap, [p, r]

    # Moving rail and toe-shell rear edges have a common Y=1340 limit.
    # Use the larger enclosing box (including empty space) conservatively.
    toe_shell = box_vertices(((-650, 650), (140, 1000), (-150, 250)))
    hinge_gap = math.inf
    upper_seam_gap = math.inf
    for t in toe_angles:
        vertices = [add(hinge, rx(v, t)) for v in toe_shell]
        below_lug_top = clip_box_below(vertices, 440)
        if below_lug_top:
            hinge_gap = min(hinge_gap, min(v[1] for v in below_lug_top) - 1280)
        upper_seam_gap = min(upper_seam_gap, min(v[1] for v in vertices) - 1080)

    sole = box_vertices(((-620, 620), (120, 980), (-350, -210)))
    ground_gap = min(
        add(hinge, rx(v, t))[2] for t in toe_angles for v in sole
    )
    flange = box_vertices(((-260, 260), (-220, 220), (320, 380)))
    flange_gap = min(ry(v, r)[2] for r in roll_angles for v in flange) - 100

    # Conservative sphere around roll-actuator base, compared to heel-cover top.
    roll_base_height = min(
        add(ankle, rx((500, -450, -150), -p))[2] - 55
        for p in pitch_angles
    )
    checks = {
        "lower_shin_to_guard": {
            "minimum_lateral_clearance_mm": round(shin_gap, 2),
            "limiting_pitch_roll_degrees": shin_pose,
            "passes": shin_gap >= 25,
        },
        "moving_toe_to_fixed_hinge_lug": {
            "minimum_fore_aft_clearance_mm": round(hinge_gap, 2),
            "passes": hinge_gap >= 25,
        },
        "toe_shell_to_fixed_upper_plate": {
            "minimum_fore_aft_clearance_mm": round(upper_seam_gap, 2),
            "passes": upper_seam_gap >= 25,
        },
        "forefoot_pad_to_ground": {
            "minimum_height_mm": round(ground_gap, 2),
            "passes": ground_gap >= -1e-9,
        },
        "shin_flange_above_ring_boss_envelope": {
            "minimum_vertical_clearance_in_ring_frame_mm": round(flange_gap, 2),
            "passes": flange_gap >= 25,
        },
        "roll_actuator_base_above_heel_cover": {
            "minimum_vertical_clearance_mm": round(roll_base_height - 600, 2),
            "passes": roll_base_height - 600 >= 25,
        },
    }
    result = {
        "revision": "FA-01",
        "scope": "Sampled reference envelopes, not full part collision or strength validation.",
        "sample_counts": {"combined_ankle_poses": 861, "forefoot_poses": 61},
        "actuators": {
            "pitch": stroke_result(pitch_lengths, [640, 860]),
            "roll": stroke_result(roll_lengths, [480, 640]),
            "forefoot": stroke_result(toe_lengths, [470, 640]),
        },
        "clearances": checks,
        "inventory": inventory_result(),
    }
    result["all_listed_checks_pass"] = all(
        v["passes"] for group in ("actuators", "clearances") for v in result[group].values()
    ) and result["inventory"]["passes"]
    path = Path(__file__).with_name("review-results.json")
    path.write_text(json.dumps(result, indent=2) + "\n")
    print(json.dumps(result, indent=2))
    return result["all_listed_checks_pass"]


if __name__ == "__main__":
    raise SystemExit(0 if run() else 1)
