"""Small closed mesh primitives, in metres. Z is the default extrusion axis.

Each public constructor returns an independent mesh object, linked to the scene.
Use ``place`` for a rigid transform and ``combine`` for integral manufactured
features. Combined objects may contain intersecting closed shells, as in FA-01;
these are visualization solids, not fabrication B-reps. No live modifiers remain.
"""
import math
import bpy
import bmesh
from mathutils import Vector, Matrix


def frame(axis):
    w = Vector(axis)
    if w.length < 1e-9:
        raise ValueError("An axis must be nonzero")
    w.normalize()
    # Preserve local X/Y for the common Z-up case.
    ref = Vector((0, 1, 0)) if abs(w.y) < .9 else Vector((1, 0, 0))
    u = ref.cross(w).normalized()
    return u, w.cross(u).normalized(), w


def activate(obj):
    bpy.ops.object.select_all(action='DESELECT')
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj


def normals(obj):
    bm = bmesh.new()
    bm.from_mesh(obj.data)
    bmesh.ops.recalc_face_normals(bm, faces=list(bm.faces))
    bm.to_mesh(obj.data)
    bm.free()
    obj.data.update()
    return obj


def mesh_object(name, vertices, faces, material=None, indices=None):
    mesh = bpy.data.meshes.new(name + " mesh")
    mesh.from_pydata(vertices, [], faces)
    mesh.update()
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.scene.collection.objects.link(obj)
    mats = material if isinstance(material, (tuple, list)) else [material]
    for mat in mats:
        if mat is not None:
            mesh.materials.append(mat)
    if indices is not None:
        for face, index in zip(mesh.polygons, indices):
            face.material_index = index
    attr = mesh.color_attributes.new(name='Wear', type='FLOAT_COLOR', domain='CORNER')
    mesh.color_attributes.active_color = attr
    for item in attr.data:
        item.color = (1, 1, 1, 1)
    return normals(obj)


def finish(obj, bevel=0, segments=1, angle=35, wear=False):
    """Apply real bevels, split sharp edges, then bake weighted corner normals.

    Optional Wear is a CORNER color multiplier (mostly white, at most 6% dark)
    consumed by materials.py and exported as COLOR_0. No normal maps are used.
    """
    activate(obj)
    if bevel > 0:
        mod = obj.modifiers.new('Applied machined chamfer', 'BEVEL')
        mod.width = bevel
        mod.segments = segments
        mod.limit_method = 'ANGLE'
        mod.angle_limit = math.radians(25)
        bpy.ops.object.modifier_apply(modifier=mod.name)
    normals(obj)
    obj.data.set_sharp_from_angle(angle=math.radians(angle))
    for face in obj.data.polygons:
        face.use_smooth = True
    mod = obj.modifiers.new('Baked weighted normals', 'WEIGHTED_NORMAL')
    mod.keep_sharp = True
    mod.weight = 50
    bpy.ops.object.modifier_apply(modifier=mod.name)
    if wear:
        attr = obj.data.color_attributes.get('Wear') or obj.data.color_attributes.new(
            name='Wear', type='FLOAT_COLOR', domain='CORNER')
        obj.data.color_attributes.active_color = attr
        for face in obj.data.polygons:
            chamfer = max(abs(v) for v in face.normal) < .999
            amount = .94 + .04 * ((face.index * 17 % 13) / 12) if chamfer else 1.0
            for loop in face.loop_indices:
                attr.data[loop].color = (amount, amount, amount, 1)
    return obj


def place(obj, origin=(0, 0, 0), axis=(0, 0, 1), roll=0):
    """Place local Z on axis; local X stays global X when axis is Z. Radians."""
    u, v, w = frame(axis)
    basis = Matrix((u, v, w)).transposed().to_4x4()
    obj.matrix_world = Matrix.Translation(Vector(origin)) @ basis @ Matrix.Rotation(roll, 4, 'Z')
    return obj


def combine(objects, name='Integral component'):
    """Join closed feature shells, preserving materials, UVs and color layers."""
    objects = list(objects)
    if not objects:
        raise ValueError('Cannot combine an empty collection')
    activate(objects[0])
    for obj in objects:
        obj.select_set(True)
    bpy.ops.object.join()
    result = bpy.context.object
    result.name = name
    result.data.transform(result.matrix_world)
    result.matrix_world = Matrix.Identity(4)
    return result


def difference(obj, cutter):
    """Applied exact machining fallback for bores or paths crossing topology."""
    # Exact Boolean imports cutter material slots for generated faces. Give an
    # unpainted tool the receiver finish instead of introducing a null slot.
    if not cutter.data.materials and obj.data.materials:
        cutter.data.materials.append(obj.data.materials[0])
    activate(obj)
    mod = obj.modifiers.new('Applied machining', 'BOOLEAN')
    mod.operation = 'DIFFERENCE'
    mod.solver = 'EXACT'
    mod.object = cutter
    bpy.ops.object.modifier_apply(modifier=mod.name)
    data = cutter.data
    bpy.data.objects.remove(cutter, do_unlink=True)
    if not data.users:
        bpy.data.meshes.remove(data)
    return normals(obj)


def chamfered_rect(width, height, corner=.06):
    if not 0 <= corner < min(width, height) / 2:
        raise ValueError('Corner must fit inside the rectangle')
    x, y, c = width / 2, height / 2, corner
    if c == 0:
        return [(-x, -y), (x, -y), (x, y), (-x, y)]
    return [(-x+c, -y), (x-c, -y), (x, -y+c), (x, y-c),
            (x-c, y), (-x+c, y), (-x, y-c), (-x, -y+c)]


def prism(outline, thickness, name='Prism', material=None, z=0):
    if thickness <= 0 or len(outline) < 3:
        raise ValueError('A prism needs a polygon and positive thickness')
    n = len(outline)
    vertices = [(x, y, h) for h in (z, z+thickness) for x, y in outline]
    faces = [tuple(reversed(range(n))), tuple(range(n, 2*n))]
    faces += [(i, (i+1)%n, (i+1)%n+n, i+n) for i in range(n)]
    return mesh_object(name, vertices, faces, material)


def chamfered_box(size, center=(0, 0, 0), bevel=.01, material=None, name='Chamfered box'):
    x, y, z = size
    if min(size) <= 0:
        raise ValueError('Box dimensions must be positive')
    obj = prism(chamfered_rect(x, y, 0), z, name, material, -z/2)
    obj.location = center
    return finish(obj, bevel)


def lathe(profile, segments=32, material=None, indices=None, name='Turned part'):
    """Revolve a CLOSED (radius,z) section. Use a small bore rather than r=0.

    indices assigns one material slot per profile edge, including the closing
    edge. A bell uses distinct inner and outer profile edges, with a solid lip.
    """
    if segments < 6 or len(profile) < 3 or min(p[0] for p in profile) <= 0:
        raise ValueError('Lathe needs positive radii, >=3 profile points, >=6 sides')
    vertices = [(r*math.cos(i*math.tau/segments), r*math.sin(i*math.tau/segments), z)
                for r, z in profile for i in range(segments)]
    faces, mats = [], []
    for k in range(len(profile)):
        for i in range(segments):
            j, h = (i+1)%segments, (k+1)%len(profile)
            faces.append((k*segments+i, k*segments+j, h*segments+j, h*segments+i))
            mats.append(indices[k] if indices else 0)
    return finish(mesh_object(name, vertices, faces, material, mats))


def cylinder(radius, depth, center=(0, 0, 0), axis=(0, 0, 1), segments=24,
             bevel=.003, material=None, name='Cylinder'):
    if min(radius, depth) <= 0 or segments < 6:
        raise ValueError('Cylinder dimensions must be positive; >=6 sides')
    outline = [(radius*math.cos(i*math.tau/segments), radius*math.sin(i*math.tau/segments))
               for i in range(segments)]
    return place(finish(prism(outline, depth, name, material, -depth/2), bevel), center, axis)


def tube(outer_radius, inner_radius, depth, center=(0, 0, 0), axis=(0, 0, 1),
         segments=24, bevel=.003, material=None, name='Tube'):
    if not 0 < inner_radius < outer_radius or depth <= 0:
        raise ValueError('Tube needs a positive wall and depth')
    b = min(bevel, (outer_radius-inner_radius)*.3, depth*.2)
    r, q, h = outer_radius, inner_radius, depth/2
    profile = [(r-b,-h), (r,-h+b), (r,h-b), (r-b,h),
               (q+b,h), (q,h-b), (q,-h+b), (q+b,-h)] if b else [
               (r,-h), (r,h), (q,h), (q,-h)]
    return place(lathe(profile, segments, material, name=name), center, axis)


def ring(outer_radius, inner_radius, thickness, **kwargs):
    return tube(outer_radius, inner_radius, thickness, **kwargs)


def hex_prism(radius, depth, **kwargs):
    return cylinder(radius, depth, segments=6, **kwargs)


def rectangular_ring(outer, inner, depth, material=None, name='Recess frame', z=0):
    """Matching CCW outline loops, straight walls and two real annular faces."""
    if len(outer) != len(inner):
        raise ValueError('Frame loops need matching vertex counts')
    n = len(outer)
    vertices = [(x,y,h) for h in (z,z+depth) for loop in (outer,inner) for x,y in loop]
    faces = []
    for i in range(n):
        j = (i+1)%n
        faces += [(i,j,2*n+j,2*n+i), (n+i,3*n+i,3*n+j,n+j),
                  (2*n+i,2*n+j,3*n+j,3*n+i), (i,n+i,n+j,j)]
    return mesh_object(name, vertices, faces, material)


def sphere(radius, center=(0,0,0), material=None, name='Spherical eye', segments=24, rings=12):
    bm = bmesh.new()
    bmesh.ops.create_uvsphere(bm, u_segments=segments, v_segments=rings, radius=radius)
    data = bpy.data.meshes.new(name+' mesh')
    bm.to_mesh(data)
    bm.free()
    obj = bpy.data.objects.new(name, data)
    bpy.context.scene.collection.objects.link(obj)
    if material:
        data.materials.append(material)
    obj.location = center
    return finish(obj)
