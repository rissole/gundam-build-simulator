"""Geometry and inventory helpers. Source dimensions are mm; Blender units are m."""
import bpy
import bmesh
import math
import csv
import collections
from pathlib import Path
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[3]
OUT = Path(__file__).resolve().parents[1] / "output"
SPEC = ROOT / "design/legs/foot-and-ankle"
PARTS = []
COUNTS = collections.Counter()
USES = collections.Counter()
SCHEDULE = {r["use"]: r for r in csv.DictReader((SPEC / "hardware.csv").open())}
MATERIALS = {}
COLLECTIONS = {}


def vec(p):
    return Vector(p)


def frame(axis):
    w = vec(axis).normalized()
    reference = Vector((1, 0, 0)) if abs(w.x) < .8 else Vector((0, 1, 0))
    u = reference.cross(w).normalized()
    return u, w.cross(u).normalized(), w


def material(name, color, metal=0, rough=.35):
    m = bpy.data.materials.new(name)
    m.diffuse_color = (*color, 1)
    m.use_nodes = True
    p = m.node_tree.nodes.get("Principled BSDF")
    p.inputs["Base Color"].default_value = (*color, 1)
    p.inputs["Metallic"].default_value = metal
    p.inputs["Roughness"].default_value = rough
    MATERIALS[name] = m
    return m


def init():
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    for name, col, metal, rough in [
        ("Armor", (.59, .65, .70), .35, .32),
        ("Frame", (.045, .075, .095), .45, .36),
        ("Steel", (.20, .27, .32), .7, .28),
        ("Pin", (.45, .53, .60), .8, .24),
        ("Bronze", (.42, .24, .09), .7, .3),
        ("Rubber", (.028, .04, .048), .05, .62),
        ("Cable", (.018, .025, .03), .1, .45),
        ("Board", (.035, .17, .13), .2, .5),
        ("Copper", (.62, .30, .10), .7, .3),
        ("Indicator", (.04, .45, .7), .4, .25),
    ]:
        material(name, col, metal, rough)
    for name in ["01 Rear frame", "02 Ankle", "03 Forefoot", "04 Actuators",
                 "05 Soles", "06 Electrical", "07 Armor", "08 Fasteners"]:
        c = bpy.data.collections.new(name)
        bpy.context.scene.collection.children.link(c)
        COLLECTIONS[name] = c


class Mesh:
    def __init__(self):
        self.v = []
        self.f = []
        self.mi = []

    def add(self, vertices, faces, mat=0):
        start = len(self.v)
        self.v.extend([tuple(v) for v in vertices])
        self.f.extend([tuple(start + j for j in f) for f in faces])
        self.mi.extend([mat] * len(faces))
        return self

    def box(self, center, size, mat=0, basis=None):
        c = vec(center)
        q = [Vector((x * size[0]/2, y * size[1]/2, z * size[2]/2))
             for z in (-1, 1) for y in (-1, 1) for x in (-1, 1)]
        if basis:
            u, v, w = map(vec, basis)
            q = [u*p.x+v*p.y+w*p.z for p in q]
        faces = [(0, 2, 3, 1), (4, 5, 7, 6), (0, 1, 5, 4),
                 (2, 6, 7, 3), (0, 4, 6, 2), (1, 3, 7, 5)]
        return self.add([c+p for p in q], faces, mat)

    def prism(self, polygon, low, high, axis="Z", mat=0):
        # Counterclockwise 2D polygon, extruded along the chosen coordinate.
        def point(p, t):
            if axis == "Z": return (p[0], p[1], t)
            if axis == "X": return (t, p[0], p[1])
            return (p[1], t, p[0])
        n = len(polygon)
        vertices = [point(p, t) for t in (low, high) for p in polygon]
        faces = [tuple(reversed(range(n))), tuple(range(n, 2*n))]
        faces.extend((i, (i+1)%n, (i+1)%n+n, i+n) for i in range(n))
        return self.add(vertices, faces, mat)

    def tube(self, center, outer, inner, length, axis=(0, 0, 1), n=40, mat=0):
        u, v, w = frame(axis)
        c = vec(center)
        rings = []
        for r, h in [(outer, -length/2), (outer, length/2),
                     (inner, -length/2), (inner, length/2)]:
            rings.extend(c+w*h+(u*math.cos(2*math.pi*i/n)+v*math.sin(2*math.pi*i/n))*r
                         for i in range(n))
        faces = []
        for i in range(n):
            j = (i+1)%n
            faces += [(i, j, j+n, i+n), (i+2*n, i+3*n, j+3*n, j+2*n),
                      (i, i+2*n, j+2*n, j), (i+n, j+n, j+3*n, i+3*n)]
        return self.add(rings, faces, mat)

    def cyl(self, center, radius, length, axis=(0, 0, 1), n=40, mat=0):
        u, v, w = frame(axis)
        c = vec(center)
        vertices = [c+w*h+(u*math.cos(2*math.pi*i/n)+v*math.sin(2*math.pi*i/n))*radius
                    for h in (-length/2, length/2) for i in range(n)]
        faces = [tuple(reversed(range(n))), tuple(range(n, 2*n))]
        faces.extend((i, (i+1)%n, (i+1)%n+n, i+n) for i in range(n))
        return self.add(vertices, faces, mat)

    def beam(self, a, b, width, depth=None, mat=0):
        a, b = vec(a), vec(b)
        basis = frame(b-a)
        return self.box((a+b)/2, (width, depth or width, (b-a).length), mat, basis)

    def poly_tube(self, points, radius, n=10, mat=0):
        points = [vec(p) for p in points]
        vs = []
        for i, p in enumerate(points):
            direction = points[min(i+1, len(points)-1)]-points[max(0, i-1)]
            u, v, w = frame(direction)
            vs.extend(p+(u*math.cos(j*2*math.pi/n)+v*math.sin(j*2*math.pi/n))*radius
                      for j in range(n))
        fs = [tuple(reversed(range(n))), tuple(range((len(points)-1)*n, len(points)*n))]
        for i in range(len(points)-1):
            for j in range(n):
                k = (j+1)%n
                fs.append((i*n+j, i*n+k, (i+1)*n+k, (i+1)*n+j))
        return self.add(vs, fs, mat)

    def transform(self, origin, basis):
        o = vec(origin); u, v, w = map(vec, basis)
        self.v = [tuple(o+u*p[0]+v*p[1]+w*p[2]) for p in self.v]
        return self

    def helical_thread(self, origin, axis, radius, length, pitch, depth, mat=0):
        o = vec(origin); u, v, w = frame(axis)
        turns = max(1, length/pitch)
        steps = max(16, int(turns*16))
        vs = []
        for i in range(steps+1):
            t = i/steps
            a = t*turns*2*math.pi
            r = u*math.cos(a)+v*math.sin(a)
            for rr, zz in [(radius-depth, -.28*pitch), (radius, 0), (radius-depth, .28*pitch)]:
                vs.append(o+r*rr+w*(t*length+zz))
        fs = [(0, 2, 1), (steps*3, steps*3+1, steps*3+2)]
        for i in range(steps):
            for j in range(3):
                k = (j+1)%3
                fs.append((i*3+j, (i+1)*3+j, (i+1)*3+k, i*3+k))
        return self.add(vs, fs, mat)


def chamfer_rect(x0, x1, y0, y1, b=20):
    return [(x0+b,y0), (x1-b,y0), (x1,y0+b), (x1,y1-b),
            (x1-b,y1), (x0+b,y1), (x0,y1-b), (x0,y0+b)]


def emit(family, label, mesh, group, phase, explosion=(0, 0, 0),
         materials=("Frame",), bevel=2, role=None):
    COUNTS[family] += 1
    uid = f"{family}__{COUNTS[family]:03d}"
    name = f"{uid}__{label}"
    minv = Vector(tuple(min(p[a] for p in mesh.v) for a in range(3)))
    maxv = Vector(tuple(max(p[a] for p in mesh.v) for a in range(3)))
    center = (minv+maxv)/2
    data = bpy.data.meshes.new(name+"_mesh")
    data.from_pydata([(vec(v)-center)/1000 for v in mesh.v], [], mesh.f)
    data.update()
    bm=bmesh.new()
    bm.from_mesh(data)
    bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces))
    bm.to_mesh(data)
    bm.free()
    for mat in materials: data.materials.append(MATERIALS[mat])
    for poly, mi in zip(data.polygons, mesh.mi):
        poly.material_index = min(mi, len(materials)-1)
    obj = bpy.data.objects.new(name, data)
    COLLECTIONS[group].objects.link(obj)
    obj.location = center/1000
    obj["part_id"] = family
    obj["instance_id"] = uid
    obj["label"] = label.replace("_", " ")
    obj["assembly_group"] = group
    obj["assembly_phase"] = phase
    obj["assembled_position_m"] = list(obj.location)
    obj["explosion_offset_m"] = [x/1000 for x in explosion]
    obj["is_assembly_part"] = True
    obj["spec_revision"] = "FA-01"
    if role: obj["role"] = role
    if bevel:
        mod = obj.modifiers.new("Machined edge radii", "BEVEL")
        mod.width = bevel/1000
        mod.segments = 2
        mod.limit_method = "ANGLE"
    PARTS.append(obj)
    return obj


def cut(obj, cutter_mesh):
    data = bpy.data.meshes.new("Boolean tooling")
    # Cutter vertices are in world coordinates; cutters are discarded afterward.
    data.from_pydata([vec(v)/1000 for v in cutter_mesh.v], [], cutter_mesh.f)
    data.update()
    cutter = bpy.data.objects.new("Temporary machining tool", data)
    bpy.context.scene.collection.objects.link(cutter)
    mod = obj.modifiers.new("Machined holes and recesses", "BOOLEAN")
    mod.operation = "DIFFERENCE"
    mod.solver = "EXACT"
    mod.object = cutter
    mod.use_self = True
    # Evaluate holes before final edge bevel.
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.modifier_move_to_index(modifier=mod.name, index=0)
    bpy.ops.object.modifier_apply(modifier=mod.name)
    bpy.data.objects.remove(cutter, do_unlink=True)
    if data.users == 0: bpy.data.meshes.remove(data)


def bore(obj, holes):
    cutter = Mesh()
    for center, radius, length, axis in holes:
        cutter.cyl(center, radius, length, axis, n=24)
    if cutter.v: cut(obj, cutter)


def screw_mesh(p, axis, diameter, length):
    # p is the underside of the head. Shaft extends along insertion direction.
    p = vec(p); u, v, d = frame(axis)
    m = Mesh()
    h = diameter
    r = diameter*.75
    pitch = {12: 1.75, 24: 3, 36: 4}[diameter]
    m.cyl(p+d*length/2, diameter*.44, length, d, n=24)
    m.helical_thread(p+d*pitch, d, diameter/2, max(pitch, length-2*pitch),
                     pitch, diameter*.07)
    n = 36
    loops = []
    for z, outer in [(-h, True), (0, True), (-h, False), (-h*.45, False)]:
        for i in range(n):
            a = 2*math.pi*i/n
            # Intersection with a regular hexagon creates the socket walls.
            rr = r if outer else diameter*.34/math.cos((a+math.pi/6)%(math.pi/3)-math.pi/6)
            loops.append(p+d*z+(u*math.cos(a)+v*math.sin(a))*rr)
    fs = [tuple(range(n, 2*n)), tuple(reversed(range(3*n, 4*n)))]
    for i in range(n):
        j = (i+1)%n
        fs += [(i, j, j+n, i+n), (i, i+2*n, j+2*n, j),
               (i+2*n, i+3*n, j+3*n, j+2*n)]
    return m.add(loops, fs)


def hardware(use, points, axis=(0,0,-1), phase=3, explosion=(0,0,800),
             group="08 Fasteners", owner=None):
    row = SCHEDULE[use]
    diameter = int(row["thread"][1:])
    length = int(row["length_mm"])
    wt = {12:2.5,24:4,36:6}[diameter]
    wi = {12:13,24:26,36:38}[diameter]/2
    wo = {12:24,24:44,36:66}[diameter]/2
    for idx, point in enumerate(points):
        d = vec(axis).normalized()
        ex = vec(explosion)+d*(-90-idx*6)
        bolt = emit(row["bolt_id"], use.replace(" ","_"), screw_mesh(point,d,diameter,length),
                    group, phase+.025*(idx%4), ex, ("Pin",), 0)
        washer = emit(row["washer_id"], "Fastener_washer",
                      Mesh().tube(vec(point)+d*wt/2,wo,wi,wt,d,n=24),
                      group, phase-.08+.025*(idx%4), ex+d*45, ("Steel",), .3)
        for obj in (bolt,washer):
            obj["hardware_use"] = use
            if owner: obj["owner_instance"] = owner.name
        USES[use] += 1


def translated(mesh, delta):
    mesh.v = [tuple(vec(v)+vec(delta)) for v in mesh.v]
    return mesh


def add_feature(obj, feature):
    """Add integral cast/machined details without creating another assembly object."""
    bm=bmesh.new()
    bm.from_mesh(obj.data)
    origin=vec(obj["assembled_position_m"])
    verts=[bm.verts.new(vec(p)/1000-origin) for p in feature.v]
    for f in feature.f:
        try: bm.faces.new([verts[i] for i in f])
        except ValueError: pass
    bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces))
    bm.to_mesh(obj.data)
    bm.free()
    obj.data.update()


def find_part(family, label_contains=None):
    return next(o for o in PARTS if o["part_id"]==family
                and (label_contains is None or label_contains in o.name))


def smooth_path(points, steps=5):
    p=[vec(points[0]),*[vec(x) for x in points],vec(points[-1])]
    out=[]
    for i in range(1,len(p)-2):
        a,b,c,d=p[i-1:i+3]
        for j in range(steps):
            t=j/steps
            out.append(.5*((2*b)+(-a+c)*t+(2*a-5*b+4*c-d)*t*t+(-a+3*b-3*c+d)*t*t*t))
    out.append(p[-1])
    return out
