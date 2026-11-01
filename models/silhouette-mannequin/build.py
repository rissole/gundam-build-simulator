"""Whole-robot silhouette mannequin, built from design/proportions.md.

Run headless from the repository root:

    blender -b --python models/silhouette-mannequin/build.py

It writes orthographic front/side/back views (with and without the scale
column and 1.75 m person), silhouette fills, a three-quarter view and a low
heroic view to models/silhouette-mannequin/output/, plus an editable
mannequin.blend (ignored by Git; rerun to regenerate). compose_sheet.py then
assembles the turnaround sheets.

This is the approved whole-robot silhouette (2026-11-01, approved for now) and
the proportion guide for concept art. It is not a finished design: every solid
is a simple chamfered loft, and shapes only hint at the confirmed features
(crest, pauldrons, calf thrusters, backpack, hip guards) so concepts keep the
approved landmarks and masses without inheriting a surface look.

Units are metres. Robot axes: X toward the robot's right, Y forward, Z up,
origin on the ground midway between the ankles (proportions.md).
"""
import math
import os
import sys

import bpy
from mathutils import Matrix, Vector

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "output")

ARMOR, FRAME, MECH, SCALE_DARK, SCALE_LIGHT, PERSON = (
    "armor", "frame", "mechanism", "scale_dark", "scale_light", "person")
COLORS = {
    ARMOR: (0.80, 0.81, 0.83, 1),
    FRAME: (0.16, 0.17, 0.19, 1),
    MECH: (0.42, 0.44, 0.47, 1),
    SCALE_DARK: (0.10, 0.10, 0.10, 1),
    SCALE_LIGHT: (0.92, 0.92, 0.92, 1),
    PERSON: (0.85, 0.45, 0.10, 1),
}

# --------------------------------------------------------------------------
# Geometry helpers


def ring_z(z, x0, x1, y0, y1, c=0.1):
    """Chamfered rectangle (octagon) in a horizontal plane."""
    c = min(c, (x1 - x0) / 2.01, (y1 - y0) / 2.01)
    return [(x0 + c, y0, z), (x1 - c, y0, z), (x1, y0 + c, z), (x1, y1 - c, z),
            (x1 - c, y1, z), (x0 + c, y1, z), (x0, y1 - c, z), (x0, y0 + c, z)]


def ring_y(y, x0, x1, z0, z1, c=0.1):
    """Chamfered rectangle in a plane of constant Y (for lofts along Y)."""
    c = min(c, (x1 - x0) / 2.01, (z1 - z0) / 2.01)
    return [(x0 + c, y, z0), (x1 - c, y, z0), (x1, y, z0 + c), (x1, y, z1 - c),
            (x1 - c, y, z1), (x0 + c, y, z1), (x0, y, z1 - c), (x0, y, z0 + c)]


def ring_x(x, y0, y1, z0, z1, c=0.05):
    c = min(c, (y1 - y0) / 2.01, (z1 - z0) / 2.01)
    return [(x, y0 + c, z0), (x, y1 - c, z0), (x, y1, z0 + c), (x, y1, z1 - c),
            (x, y1 - c, z1), (x, y0 + c, z1), (x, y0, z1 - c), (x, y0, z0 + c)]


def disc(center, axis, radius, n=16):
    axis = Vector(axis).normalized()
    a = axis.orthogonal().normalized()
    b = axis.cross(a)
    center = Vector(center)
    return [tuple(center + radius * (math.cos(t) * a + math.sin(t) * b))
            for t in (2 * math.pi * i / n for i in range(n))]


class Builder:
    def __init__(self):
        self.parts = []  # (name, material, verts, faces)

    def loft(self, name, rings, mat=ARMOR, matrix=None):
        n = len(rings[0])
        verts = [Vector(p) for r in rings for p in r]
        if matrix is not None:
            verts = [matrix @ v for v in verts]
        faces = []
        for i in range(len(rings) - 1):
            for j in range(n):
                k = (j + 1) % n
                faces.append((i * n + j, i * n + k, (i + 1) * n + k, (i + 1) * n + j))
        faces.append(tuple(reversed(range(n))))
        last = (len(rings) - 1) * n
        faces.append(tuple(range(last, last + n)))
        self.parts.append((name, mat, verts, faces))

    def box(self, name, x0, x1, y0, y1, z0, z1, mat=ARMOR, c=0.04, matrix=None):
        self.loft(name, [ring_z(z0, x0, x1, y0, y1, c), ring_z(z1, x0, x1, y0, y1, c)],
                  mat, matrix)

    def cylinder(self, name, a, b, r0, r1=None, mat=FRAME, n=20, matrix=None):
        axis = Vector(b) - Vector(a)
        self.loft(name, [disc(a, axis, r0, n), disc(b, axis, r1 if r1 else r0, n)],
                  mat, matrix)

    def plate(self, name, profile_yz, x0, x1, mat=ARMOR):
        """Side plate: a (y, z) outline extruded across X."""
        self.loft(name, [[(x0, y, z) for y, z in profile_yz],
                         [(x1, y, z) for y, z in profile_yz]], mat)

    def sphere(self, name, center, r, mat=FRAME, n=16):
        rings = []
        for i in range(1, n):
            t = math.pi * i / n
            rings.append(disc((center[0], center[1], center[2] - r * math.cos(t)),
                              (0, 0, 1), r * math.sin(t), n))
        self.loft(name, rings, mat)

    def scale_xy(self, start, cx, cy, sx, sy=None):
        """Scale parts added since `start` horizontally about (cx, cy)."""
        sy = sx if sy is None else sy
        for i in range(start, len(self.parts)):
            name, mat, verts, faces = self.parts[i]
            verts = [Vector((cx + (v.x - cx) * sx, cy + (v.y - cy) * sy, v.z)) for v in verts]
            self.parts[i] = (name, mat, verts, faces)

    def mirrored(self, fn):
        """Call fn(side, name_suffix) for the robot's right (+1) and left (-1)."""
        for side, suffix in ((1, "R"), (-1, "L")):
            start = len(self.parts)
            fn(side, suffix)
            if side < 0:
                # Mirror geometry authored for the right side and fix winding.
                for i in range(start, len(self.parts)):
                    name, mat, verts, faces = self.parts[i]
                    verts = [Vector((-v.x, v.y, v.z)) for v in verts]
                    faces = [tuple(reversed(f)) for f in faces]
                    self.parts[i] = (name, mat, verts, faces)


# --------------------------------------------------------------------------
# Robot, authored for the right side (+X) and mirrored where symmetric

FOOT_X = 1.10            # ankle/knee/hip centre spacing (proportions.md)
ANKLE_Z, KNEE_Z, HIP_Z = 1.00, 5.10, 9.20
ARM_SPLAY = math.radians(15)

# Approved silhouette, 2026-11-01 ("broad wide", approved for now). The
# component envelopes in proportions.md were derived from these values:
# - limbs, feet and hip armor: horizontal scale factors applied to the base
#   shapes below about each limb's own axis (joint positions unchanged);
# - pauldrons: rings across X as (|x|, half depth, z0, z1, chamfer), reaching
#   outward with tops near chin level, sloping down outboard;
# - chest: rings up Z as (z, half width, rear y, front y, chamfer); the upper
#   chest projects forward to Y +1.65 and rises into a collar at the chin;
# - shoulder balls at |X| 2.45 so each arm hangs under its pauldron's middle.
P = dict(
    upper_arm=1.12, forearm=1.32, hand=1.20, thigh=1.20, calf=1.18, foot=1.12, hip=1.20,
    hip_guard_bottom=7.85, shoulder_x=2.45, chest_front=1.60,
    pauldron_x=[(1.95, .82, 13.55, 15.50, .14), (3.10, .95, 13.30, 15.40, .20),
                (3.62, .85, 13.45, 14.95, .30)],
    chest=[(11.40, 1.05, -1.00, .95, .16), (12.30, 1.45, -1.20, 1.15, .22),
           (13.10, 2.05, -1.20, 1.55, .26), (14.80, 2.40, -1.15, 1.65, .26),
           (15.35, 2.05, -1.00, 1.55, .20), (15.62, 1.05, -.80, .90, .15)])


def leg(b, side, s):
    x = FOOT_X
    # Base foot 3.00 x 1.30 (heel 0.80 behind the ankle, toe 2.20 ahead, shell
    # <= 0.70), scaled to the approved 3.36 x 1.46 below.
    start = len(b.parts)
    b.box(f"sole_{s}", x - .62, x + .62, -.80, 2.15, 0, .16, FRAME, .06)
    b.loft(f"foot_shell_{s}", [
        ring_y(-.80, x - .58, x + .58, .12, .52, .14),
        ring_y(-.62, x - .65, x + .65, .10, .70, .14),
        ring_y(.85, x - .65, x + .65, .10, .64, .14),
        ring_y(1.12, x - .64, x + .64, .10, .60, .12)])
    # Hinged toe section: final 1.00 m ahead of the Y+1.20 hinge.
    b.loft(f"toe_cap_{s}", [
        ring_y(1.22, x - .62, x + .62, .04, .58, .12),
        ring_y(1.95, x - .56, x + .56, .04, .40, .12),
        ring_y(2.20, x - .44, x + .44, .04, .24, .08)])
    # Ankle mechanism and side guards (guard tops at 1.60).
    b.box(f"ankle_{s}", x - .42, x + .42, -.42, .42, .62, 1.38, FRAME, .08)
    for g, (gx0, gx1) in (("out", (x + .58, x + .72)), ("in", (x - .72, x - .58))):
        b.plate(f"ankle_guard_{g}_{s}",
                [(-.55, .45), (.70, .45), (.22, 1.60), (-.38, 1.60)], gx0, gx1)
    b.scale_xy(start, x, 0, P["foot"])
    start = len(b.parts)
    # Shin stem, then calf: base 0.90 x 0.90 from Z1.65, widening to 1.40 W and
    # 1.90 D including the rear thruster enclosure, tapering to the knee
    # (scaled x1.18 below).
    b.box(f"shin_stem_{s}", x - .26, x + .26, -.22, .22, 1.20, 1.80, FRAME, .05)
    b.loft(f"lower_leg_{s}", [
        ring_z(1.65, x - .45, x + .45, -.45, .45, .10),
        ring_z(2.20, x - .50, x + .50, -.62, .48, .12),
        ring_z(3.40, x - .70, x + .70, -1.32, .56, .18),
        ring_z(4.25, x - .68, x + .68, -1.12, .58, .16),
        ring_z(4.78, x - .60, x + .60, -.72, .56, .14)])
    # Two stacked calf thrusters, mouths angled rearward and downward.
    for i, (y, z) in enumerate(((-.95, 2.70), (-1.22, 3.45))):
        b.cylinder(f"calf_nozzle_{i}_{s}", (x, y + .12, z + .20), (x, y - .10, z - .18),
                   .12, .24, FRAME)
    # Knee: joint block, side bearing caps, faceted kneecap wider at the top.
    b.box(f"knee_joint_{s}", x - .50, x + .50, -.50, .42, 4.70, 5.55, FRAME, .10)
    for cx in (x - .52, x + .52):
        b.cylinder(f"knee_cap_side_{s}", (cx - .03, 0, KNEE_Z), (cx + .03, 0, KNEE_Z), .30,
                   mat=MECH)
    b.loft(f"kneecap_{s}", [
        ring_z(4.55, x - .22, x + .22, .52, .70, .06),
        ring_z(5.25, x - .48, x + .48, .50, .86, .10),
        ring_z(5.70, x - .52, x + .52, .46, .80, .10)])
    b.scale_xy(start, x, 0, P["calf"])
    start = len(b.parts)
    # Thigh: base 1.50 x 1.50 maximum, tapering to 1.10 near the knee (x1.20).
    b.loft(f"thigh_{s}", [
        ring_z(5.55, x - .55, x + .55, -.52, .52, .12),
        ring_z(6.10, x - .60, x + .60, -.62, .62, .14),
        ring_z(7.80, x - .75, x + .75, -.75, .75, .18),
        ring_z(8.50, x - .72, x + .72, -.68, .70, .18)])
    b.scale_xy(start, x, 0, P["thigh"])
    # Hip ball and neck, visible through the gap above the thigh armor.
    b.cylinder(f"hip_neck_{s}", (x, 0, 8.45), (x, 0, HIP_Z), .26, mat=FRAME)
    b.sphere(f"hip_ball_{s}", (x, 0, HIP_Z), .45, FRAME)


def hip_guards(b, side, s):
    # Two short front guards overlapping the thigh tops; small outer plates.
    start = len(b.parts)
    b.loft(f"front_hip_guard_{s}", [
        ring_z(P["hip_guard_bottom"], .45, 1.30, .92, 1.06, .04),
        ring_z(9.95, .25, 1.40, .82, .98, .04)])
    b.plate(f"outer_hip_plate_{s}",
            [(-.62, 8.85), (.62, 8.85), (.55, 10.0), (-.55, 10.0)], 1.40, 1.58)
    b.scale_xy(start, 0, 0, P["hip"], 1.0)


def arm(b, side, s):
    # Authored hanging straight down from the shoulder ball (local -Z), then
    # splayed 15 degrees outward: elbow (3.23, 0, 11.50), wrist (3.90, 0, 8.99).
    shoulder = (P["shoulder_x"], 0.0, 14.40)
    m = (Matrix.Translation(shoulder) @ Matrix.Rotation(-ARM_SPLAY, 4, "Y"))

    def scaled(k):
        return m @ Matrix.Diagonal((P[k], P[k], 1, 1))
    mu, mf, mh = scaled("upper_arm"), scaled("forearm"), scaled("hand")
    b.sphere(f"shoulder_ball_{s}", shoulder, .40, FRAME)
    b.loft(f"upper_arm_{s}", [
        ring_z(-.70, -.42, .42, -.46, .46, .10),
        ring_z(-2.65, -.35, .35, -.42, .42, .10)], matrix=mu)
    b.box(f"elbow_joint_{s}", -.32, .32, -.36, .30, -3.30, -2.62, FRAME, .08, matrix=m)
    for cx in (-.34, .34):
        b.cylinder(f"elbow_cap_{s}", (cx - .03, -.03, -3.0), (cx + .03, -.03, -3.0), .22,
                   mat=MECH, matrix=m)
    b.loft(f"forearm_{s}", [
        ring_z(-3.20, -.46, .46, -.50, .50, .12),
        ring_z(-3.90, -.55, .55, -.55, .55, .14),
        ring_z(-5.15, -.42, .42, -.42, .42, .10)], matrix=mf)
    b.box(f"wrist_cuff_{s}", -.375, .375, -.375, .375, -5.40, -5.12, ARMOR, .06, matrix=mf)
    b.sphere(f"wrist_ball_{s}", tuple(m @ Vector((0, 0, -5.60))), .20, FRAME)
    # Relaxed fist for concept guidance; the dimensioned reference pose keeps
    # fingers extended to 7.25 m (proportions.md). Palm faces inward (local -X).
    b.box(f"back_of_hand_{s}", -.20, .24, -.45, .45, -6.30, -5.68, ARMOR, .07, matrix=mh)
    b.loft(f"curled_fingers_{s}", [ring_z(-6.22, -.34, .22, -.44, .42, .08),
                                   ring_z(-6.78, -.30, .20, -.40, .38, .10)], FRAME, matrix=mh)
    b.loft(f"thumb_{s}", [ring_y(.30, -.36, -.08, -6.20, -5.85, .05),
                          ring_y(.50, -.40, -.12, -6.55, -6.20, .05)], FRAME, matrix=mh)
    # Pauldron reaching outward: |X| 1.95..3.62, Y +-0.95, Z 13.30..15.50.
    b.loft(f"pauldron_{s}", [ring_x(x, -d, d, z0, z1, c)
                             for x, d, z0, z1, c in P["pauldron_x"]])


def torso(b):
    # Fixed hip assembly armor, base 3.00 W x 1.80 D, scaled to 3.60 W.
    start = len(b.parts)
    b.loft("hip_assembly", [
        ring_z(8.70, -.42, .42, -.55, .72, .10),
        ring_z(9.25, -1.35, 1.35, -.85, .86, .16),
        ring_z(10.15, -1.50, 1.50, -.90, .90, .18)])
    b.scale_xy(start, 0, 0, P["hip"], 1.0)
    # Waist: 2.20 W x 1.60 D mechanical band; three overlapping abdomen plates.
    b.box("waist", -1.10, 1.10, -.80, .80, 10.10, 11.40, MECH, .18)
    for i, (z0, z1, w) in enumerate(((10.20, 10.66, .74), (10.58, 11.06, .84),
                                     (10.98, 11.52, .96))):
        b.loft(f"abdomen_{i}", [ring_z(z0, -w + .06, w - .06, .76, .92, .04),
                                ring_z(z1, -w, w, .76, .96, .04)])
    # Chest: 4.80 W at Z14.80, front projecting to Y+1.65, tapering to the waist.
    b.loft("chest", [ring_z(z, -w, w, y0, y1, c) for z, w, y0, y1, c in P["chest"]])
    # Opaque sternum hatch between two pectoral plates, on the chest front.
    f = P["chest_front"]
    b.box("sternum_hatch", -.52, .52, f - .04, f + .07, 12.95, 14.45, MECH, .05)
    for sx in (1, -1):
        b.loft(f"pectoral_{'R' if sx > 0 else 'L'}", [
            ring_x(sx * .58, f - .10, f + .04, 13.00, 14.55, .03),
            ring_x(sx * 1.90, f - .10, f + .04, 13.35, 14.50, .03)])
    # Neck (fixed spoke) up to the Z15.40 head baseplate.
    b.cylinder("neck", (0, 0, 14.85), (0, 0, 15.45), .34, mat=FRAME)
    # Closed backpack: 2.40 W x 2.80 H, Z11.30..14.10, rear limit Y-2.20.
    b.loft("backpack", [
        ring_z(11.30, -1.05, 1.05, -1.95, -1.15, .16),
        ring_z(13.70, -1.20, 1.20, -2.05, -1.15, .20),
        ring_z(14.10, -1.10, 1.10, -1.90, -1.15, .18)])
    for sx in (1, -1):
        b.cylinder(f"backpack_nozzle_{'R' if sx > 0 else 'L'}",
                   (sx * .55, -1.95, 11.90), (sx * .55, -2.20, 11.55), .14, .24, FRAME)


def head(b):
    # Helmet 2.00 H x 2.00 W x 1.80 D, baseplate Z15.40, roof Z17.40.
    b.loft("helmet", [
        ring_z(15.45, -.62, .62, -.58, .66, .12),
        ring_z(16.20, -.80, .80, -.80, .84, .16),
        ring_z(16.90, -.86, .86, -.86, .86, .18),
        ring_z(17.40, -.60, .60, -.70, .52, .16)])
    b.box("face_mask", -.48, .48, .78, .88, 15.52, 16.50, MECH, .05)
    b.loft("brow", [ring_z(16.58, -.78, .78, .80, .92, .03),
                    ring_z(16.98, -.82, .82, .80, .98, .03)])
    for sx in (1, -1):
        s = "R" if sx > 0 else "L"
        b.box(f"eye_{s}", min(sx * .12, sx * .44), max(sx * .12, sx * .44), .86, .90,
              16.34, 16.46, FRAME, .01)
        # Flared, stepped side guards.
        x0, x1 = (.84, 1.00) if sx > 0 else (-1.00, -.84)
        b.loft(f"side_guard_{s}", [
            ring_z(15.62, x0 + sx * 0, x1 + sx * 0, -.86, .42, .04),
            ring_z(16.95, x0 - sx * .06, x1 - sx * .06, -.82, .30, .04)])
        # Crest blade from the forehead mount to its tip (2.60 wide, Z18.00).
        base, tip = Vector((sx * .10, .88, 16.92)), Vector((sx * 1.30, .74, 18.00))
        d = (tip - base).normalized()
        p = Vector((-d.z, 0, d.x)) * sx
        y = Vector((0, 1, 0))
        rings = []
        for c, w, t in ((base, .22, .05), (tip, .05, .03)):
            rings.append([tuple(c + p * w / 2 + y * t / 2), tuple(c - p * w / 2 + y * t / 2),
                          tuple(c - p * w / 2 - y * t / 2), tuple(c + p * w / 2 - y * t / 2)])
        b.loft(f"crest_{s}", rings, ARMOR)
    b.box("rear_guard", -.76, .76, -.92, -.82, 15.58, 16.80, ARMOR, .04)
    b.box("crest_mount", -.14, .14, .80, .96, 16.80, 17.06, MECH, .03)


def scale_props(b):
    # 1 m alternating scale column to 18 m, behind and outside the left foot.
    for i in range(18):
        b.box(f"scale_{i:02d}", -6.25, -5.95, 2.60, 2.90, i, i + 1,
              SCALE_DARK if i % 2 == 0 else SCALE_LIGHT, 0)
    # 1.75 m person beside the right foot.
    px, py = 3.20, 1.60
    b.cylinder("person_legs", (px, py, 0), (px, py, .85), .13, .17, PERSON)
    b.cylinder("person_body", (px, py, .85), (px, py, 1.48), .20, .17, PERSON)
    b.sphere("person_head", (px, py, 1.62), .12, PERSON)


def build_robot():
    b = Builder()
    b.mirrored(lambda side, s: leg(b, side, s))
    b.mirrored(lambda side, s: hip_guards(b, side, s))
    b.mirrored(lambda side, s: arm(b, side, s))
    torso(b)
    head(b)
    scale_props(b)
    return b


# --------------------------------------------------------------------------
# Blender scene and renders


def reset_scene():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    scene = bpy.context.scene
    scene.unit_settings.system = "METRIC"
    return scene


def make_objects(b):
    mats = {}
    for key, rgba in COLORS.items():
        m = bpy.data.materials.new(key)
        m.diffuse_color = rgba
        mats[key] = m
    coll = bpy.data.collections.new("mannequin")
    bpy.context.scene.collection.children.link(coll)
    for name, mat, verts, faces in b.parts:
        mesh = bpy.data.meshes.new(name)
        mesh.from_pydata([tuple(v) for v in verts], [], faces)
        mesh.validate()
        mesh.update()
        obj = bpy.data.objects.new(name, mesh)
        obj.data.materials.append(mats[mat])
        for poly in obj.data.polygons:
            poly.use_smooth = False
        coll.objects.link(obj)
    return coll


def setup_render(scene, silhouette=False):
    scene.render.engine = "BLENDER_WORKBENCH"
    scene.render.resolution_x, scene.render.resolution_y = 1200, 1500
    scene.render.film_transparent = False
    scene.render.dither_intensity = 0  # noise-free flat fills compress far better
    scene.render.image_settings.color_mode = "RGB"
    sh = scene.display.shading
    sh.light = "FLAT" if silhouette else "STUDIO"
    sh.color_type = "SINGLE" if silhouette else "MATERIAL"
    sh.single_color = (0.05, 0.05, 0.06)
    sh.show_object_outline = not silhouette
    sh.object_outline_color = (0.08, 0.08, 0.1)
    sh.show_cavity = not silhouette
    sh.background_type = "VIEWPORT"
    sh.background_color = (1, 1, 1)
    scene.display.render_aa = "16"
    scene.view_settings.view_transform = "Standard"


def camera(scene, name, location, target, ortho=True, lens=60):
    cam_data = bpy.data.cameras.new(name)
    cam = bpy.data.objects.new(name, cam_data)
    scene.collection.objects.link(cam)
    cam.location = location
    direction = Vector(target) - Vector(location)
    cam.rotation_euler = direction.to_track_quat("-Z", "Y").to_euler()
    if ortho:
        cam_data.type = "ORTHO"
        cam_data.ortho_scale = 20.0
    else:
        cam_data.lens = lens
    cam_data.clip_end = 500
    return cam


def render(scene, cam, path, hide=()):
    hidden = [o for o in scene.objects if o.name in hide or any(o.name.startswith(h) for h in hide)]
    for o in hidden:
        o.hide_render = True
    scene.camera = cam
    scene.render.filepath = path
    bpy.ops.render.render(write_still=True)
    for o in hidden:
        o.hide_render = False


def views_for(scene):
    mid = (0, 0, 9.25)
    return {
        "front": camera(scene, "cam_front", (0, 60, 9.25), mid),
        "side": camera(scene, "cam_side", (60, 0, 9.25), mid),
        "back": camera(scene, "cam_back", (0, -60, 9.25), mid),
        "three_quarter": camera(scene, "cam_34", (19, 24, 13.5), (0, 0, 9.0), ortho=False,
                                lens=50),
        # Low heroic angle from the front right, eye level of a person on the floor.
        "hero_low": camera(scene, "cam_hero", (11, 20, 1.7), (0, 0, 8.6), ortho=False,
                           lens=36),
    }


def render_reference_set(scene, views, props):
    """The deliverables referenced by the README and the visual design brief."""
    for name in ("front", "side", "back", "three_quarter", "hero_low"):
        setup_render(scene)
        render(scene, views[name], os.path.join(OUT, f"mannequin-{name}.png"),
               hide=props if name in ("three_quarter", "hero_low") else ())
        if name in ("front", "side", "back"):
            render(scene, views[name], os.path.join(OUT, f"clean-{name}.png"), hide=props)
    for name in ("front", "side", "back"):
        setup_render(scene, silhouette=True)
        render(scene, views[name], os.path.join(OUT, f"silhouette-{name}.png"), hide=props)


def main():
    os.makedirs(OUT, exist_ok=True)
    props = ("scale_", "person_")
    scene = reset_scene()
    make_objects(build_robot())
    views = views_for(scene)
    render_reference_set(scene, views, props)
    setup_render(scene)
    scene.camera = views["three_quarter"]
    bpy.ops.wm.save_as_mainfile(filepath=os.path.join(OUT, "mannequin.blend"))
    print(f"MANNEQUIN_PARTS {len([o for o in scene.objects if o.type == 'MESH'])}")


if __name__ == "__main__":
    main()
    sys.exit(0)
