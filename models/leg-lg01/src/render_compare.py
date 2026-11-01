"""Read-only EEVEE comparison renders for all seven LG-01 / FA-02 sheets.

blender --background models/leg-lg01/output/leg-lg01.blend \
    --python-exit-code 1 --python models/leg-lg01/src/render_compare.py \
    -- --only lg01-assembled,fa02-assembled --samples 24 --res-scale 0.5

Never saves a blend or imports generators. Facet shading uses mesh copies;
presentation transforms and foot-stub shader clipping exist only in memory.
PNG intermediates and evidence live in work/renders; deliverables are JPEG q90.
--out selects the comparison directory (individual JPEGs go in its ../renders).
Composition uses system Python + Pillow, not Blender's Python installation.
"""
import argparse
import hashlib
import json
import math
from pathlib import Path
import shutil
import subprocess
import sys
import time

SRC = Path(__file__).resolve().parent
PACKAGE = SRC.parent
WORK = PACKAGE / 'work' / 'renders'
NAMES = ('lg01-assembled', 'lg01-armor', 'lg01-structure', 'fa02-assembled',
         'fa02-armor', 'fa02-structure', 'turnaround-leg')
LEG_GROUPS = {'thigh', 'knee', 'shin-calf'}
SHELLS = {'FA-400', 'FA-401-L', 'FA-402', 'FA-403-L', 'FA-404-L'}
SOLES = {'FA-300', 'FA-301', 'FA-302', 'FA-303', 'FA-304'}
STUB_TOP = 1.90


def arguments():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('--only', default=','.join(NAMES), metavar='NAME[,NAME]')
    parser.add_argument('--samples', type=int, default=32)
    parser.add_argument('--res-scale', type=float, default=1.0)
    parser.add_argument('--key-energy', type=float, default=1170)
    parser.add_argument('--fill-ratio', type=float, default=.72)
    parser.add_argument('--rim-energy', type=float, default=350)
    parser.add_argument('--world-strength', type=float, default=.045)
    parser.add_argument('--exposure', type=float, default=0)
    parser.add_argument('--view-transform', choices=('Standard', 'AgX'), default='Standard')
    parser.add_argument('--work', type=Path, default=WORK)
    parser.add_argument('--out', type=Path, default=PACKAGE / 'output' / 'compare')
    argv = sys.argv[sys.argv.index('--') + 1:] if '--' in sys.argv else []
    args = parser.parse_args(argv)
    args.only = list(dict.fromkeys(s.strip() for s in args.only.split(',')))
    unknown = set(args.only) - set(NAMES)
    if unknown:
        parser.error(f'Unknown sheets: {sorted(unknown)}; choose from {", ".join(NAMES)}')
    if args.samples < 1 or not math.isfinite(args.res_scale) or not 0.1 <= args.res_scale <= 2:
        parser.error('--samples must be positive; --res-scale must be between 0.1 and 2')
    args.out = args.out.expanduser().resolve()
    args.work = args.work.expanduser().resolve()
    return args


def sha256(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


# These coordinates are display centres in the camera plane (right, up).
# They are not approaches, snap poses or a proposed installation sequence.
LEG_LAYOUT = {
    'LG-200': (-5.0, 7.3), 'LG-210': (-2.7, 7.3),
    'LG-215': (2.5, 7.3), 'LG-220': (4.2, 7.3), 'LG-225': (5.7, 7.3),
    'LG-300': (-5.0, 5.1), 'LG-320': (-2.7, 5.1), 'LG-325': (2.5, 5.1),
    'LG-400': (-5.0, 2.7), 'LG-410': (-2.7, 2.7), 'LG-415': (2.5, 2.7),
    'LG-420': (4.8, 2.7), 'LG-430': (4.8, .45),
}
FOOT_LAYOUT = {
    'FA-400': (-4.6, 3.5), 'FA-401-L': (-2.2, 3.5), 'FA-402': (0, 3.5),
    'FA-403-L': (2.2, 3.5), 'FA-404-L': (4.6, 3.5),
    'FA-300': (-3.5, .1), 'FA-301': (3.5, .1),
}
PADS = {'FA-302', 'FA-303', 'FA-304'}


def is_foot(obj):
    return obj.get('subassembly') not in LEG_GROUPS


def is_shell(obj):
    return obj.get('part_id') in SHELLS or obj.get('category') in {'armor', 'service'}


def setup_studio(scene, args):
    import bpy
    from mathutils import Vector
    engines = {x.identifier for x in scene.render.bl_rna.properties['engine'].enum_items}
    scene.render.engine = next(e for e in ('BLENDER_EEVEE_NEXT', 'BLENDER_EEVEE') if e in engines)
    scene.render.film_transparent = True
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = 'PNG'
    scene.render.image_settings.color_mode = 'RGBA'
    scene.render.image_settings.color_depth = '8'
    scene.render.use_file_extension = True
    scene.render.use_compositing = False
    scene.render.use_sequencer = False
    scene.view_settings.view_transform = args.view_transform
    scene.view_settings.look = 'AgX - Medium High Contrast' if args.view_transform == 'AgX' else 'None'
    scene.view_settings.exposure = args.exposure
    scene.view_settings.gamma = 1
    eevee = scene.eevee
    for key, value in {'taa_render_samples': args.samples, 'use_raytracing': True,
                       'use_fast_gi': True, 'fast_gi_quality': .5,
                       'fast_gi_ray_count': 2, 'fast_gi_step_count': 12,
                       'fast_gi_distance': 2.0, 'use_gtao': True,
                       'gtao_distance': 1.5, 'gtao_factor': 1.15}.items():
        if hasattr(eevee, key):
            setattr(eevee, key, value)
    # The camera sees transparency; this dim neutral environment serves metal only.
    scene.world = bpy.data.worlds.new('Comparison studio environment')
    scene.world.use_nodes = True
    bg = scene.world.node_tree.nodes.get('Background')
    bg.inputs['Color'].default_value = (1, 1, 1, 1)
    bg.inputs['Strength'].default_value = args.world_strength
    for obj in scene.objects:
        if not obj.get('instance_id'):
            obj.hide_render = True
    collection = bpy.data.collections.new('Comparison presentation (unsaved)')
    scene.collection.children.link(collection)
    data = bpy.data.cameras.new('Comparison camera')
    camera = bpy.data.objects.new(data.name, data)
    collection.objects.link(camera)
    camera.data.clip_start = .01
    camera.data.clip_end = 250
    camera.data.lens = 120
    scene.camera = camera
    lights = []
    # Camera-left is +X in the front view. One soft key at 45° az / 25° el;
    # the opposing fill preserves shade detail without flattening the folds.
    for name, delta, energy, size in (
            ('Key / upper left', (.64086, .64086, .42262), args.key_energy, .50),
            ('Fill', (-.68301, .68301, .25882), args.key_energy * args.fill_ratio, .60),
            ('Rim / back', (-.6064, -.7762, .17365), args.rim_energy, .40)):
        light_data = bpy.data.lights.new(name, 'AREA')
        light_data.shape = 'DISK'
        light_data.use_shadow = True
        light = bpy.data.objects.new(name, light_data)
        collection.objects.link(light)
        lights.append((light, Vector(delta), energy, size))
    # EEVEE lacks Cycles' shadow-catcher pass. Render a white diffuse floor
    # with/without the subject, then composite their lighting ratio onto white.
    # This captures actual soft contact shadows without alpha-hashed noise.
    bpy.ops.mesh.primitive_plane_add(size=2, location=(0, 0, -.008))
    ground = bpy.context.object
    ground.name = 'Comparison white shadow catcher (unsaved)'
    for col in list(ground.users_collection):
        col.objects.unlink(ground)
    collection.objects.link(ground)
    ground.scale = (120, 120, 1)
    mat = bpy.data.materials.new('Comparison white diffuse floor')
    mat.use_nodes = True
    nodes, links = mat.node_tree.nodes, mat.node_tree.links
    nodes.clear()
    output = nodes.new('ShaderNodeOutputMaterial')
    diffuse = nodes.new('ShaderNodeBsdfDiffuse')
    diffuse.inputs['Color'].default_value = (1, 1, 1, 1)
    links.new(diffuse.outputs[0], output.inputs['Surface'])
    ground.data.materials.append(mat)
    return camera, lights, ground


def prepare_facets(parts):
    """Preserve smooth hardware; use geometric normals on painted armor only."""
    audit = {'materials': {}, 'flat_shaded_copies': {}}
    for obj in parts:
        if not is_shell(obj):
            continue
        painted = {i for i, m in enumerate(obj.data.materials) if m and
                   m.get('palette_srgb') in {'#D2C8BC', '#D4861D'}}
        count = sum(p.use_smooth and p.material_index in painted for p in obj.data.polygons)
        if count:
            obj.data = obj.data.copy()
            for polygon in obj.data.polygons:
                if polygon.material_index in painted:
                    polygon.use_smooth = False
            obj.data.update()
            audit['flat_shaded_copies'][obj['instance_id']] = count
        for material in obj.data.materials:
            if not material or material.name in audit['materials'] or not material.get('palette_srgb'):
                continue
            bsdf = next(n for n in material.node_tree.nodes if n.type == 'BSDF_PRINCIPLED')
            audit['materials'][material.name] = {
                'palette_srgb': material.get('palette_srgb'),
                'base_color_linear': list(bsdf.inputs['Base Color'].default_value),
                'base_color_linked': bsdf.inputs['Base Color'].is_linked,
                'emission_strength': bsdf.inputs['Emission Strength'].default_value}
    return audit


def tone_points(scene, camera, parts, resolution, oblique=False):
    """Geometry anchors, validated over the entire patch, without reading pixels.

    Front shade is the visible LG-200 outer fold, not the concealed LG-210
    return. Oblique shade is LG-210's broad outer skin. Missing/occluded/wrong
    material patches remain explicit failures; no brightness-based reselection.
    """
    from mathutils import Vector
    from bpy_extras.object_utils import world_to_camera_view
    specs = {
        'lit_thigh': ('LG-200', (0, 3, 7), (0, -1, 0), '#D2C8BC'),
        'shaded_thigh': ('LG-200', (-.82, 3, 7), (0, -1, 0), '#D2C8BC'),
        'ochre_kneecap': ('LG-300', (0, 3, 5.10), (0, -1, 0), '#D4861D'),
        'calf_front': ('LG-400', (0, 3, 3.30), (0, -1, 0), '#D2C8BC'),
        'dark_knee': ('LG-110', (-.43, 3, 5.10), (0, -1, 0), '#4C4C4B'),
    }
    if oblique:
        specs['shaded_thigh'] = ('LG-210', (-3, -.25, 7), (1, 0, 0), '#D2C8BC')
        specs['dark_knee'] = ('LG-330', (-3, 0, 5.10), (1, 0, 0), '#4C4C4B')
    depsgraph = scene.view_layers[0].depsgraph
    result = {}
    rotation = camera.rotation_euler.to_quaternion()
    ray = rotation @ Vector((0, 0, -1))
    pixel_size = camera.data.ortho_scale / max(resolution)
    for name, (pid, origin, direction, palette) in specs.items():
        row = {'part_id': pid, 'expected_palette': palette, 'valid': False}
        result[name] = row
        obj = next((o for o in parts if o.get('part_id') == pid), None)
        if obj is None:
            row['error'] = 'MISSING PART'; continue
        inv = obj.matrix_world.inverted()
        hit, local, normal, index = obj.ray_cast(inv @ Vector(origin), inv.to_3x3() @ Vector(direction))
        if not hit:
            row['error'] = 'MISSED ANCHOR'; continue
        point = obj.matrix_world @ local
        p = world_to_camera_view(scene, camera, point)
        material = obj.data.materials[obj.data.polygons[index].material_index]
        radius = max(1, round(resolution[0] / 820)) if name == 'shaded_thigh' and not oblique else max(2, round(4 * resolution[0] / 820))
        # Validate every pixel footprint, including half a pixel for rounding.
        hits = []
        for dx in range(-radius-1, radius+2):
            for dy in range(-radius-1, radius+2):
                offset = rotation @ Vector((dx * pixel_size, dy * pixel_size, 0))
                origin2 = point + offset - ray * 30
                h, co, _, face, first, _ = scene.ray_cast(depsgraph, origin2, ray)
                matching = bool(h and first.get('instance_id') == obj['instance_id'])
                if matching:
                    matching = first.data.materials[first.data.polygons[face].material_index].get('palette_srgb') == palette
                hits.append(matching)
        visible = all(hits)
        row.update(instance_id=obj['instance_id'], world=list(point), normal=list(normal),
                   pixel=[round(p.x * resolution[0]), round((1-p.y) * resolution[1])],
                   radius=radius, visible=visible, material=material.name,
                   matching_rays=sum(hits), patch_rays=len(hits),
                   valid=visible and material.get('palette_srgb') == palette and 0 < p.x < 1 and 0 < p.y < 1)
        if not row['valid']:
            row['error'] = 'OCCLUDED / WRONG MATERIAL / OUTSIDE FRAME'
    for name, row in result.items():
        if not row['valid']:
            print(f"TONE PROBE FAILURE: {name}: {row.get('error')}", flush=True)
    return result


def prepare_finish(parts):
    """Unsaved material/attribute overrides; no vertex or fastener changes.

    The source material factors stay glTF compatible. Cavity AO is a studio
    shader only, applied to bronze; dark foot well floors reuse Dark recess.
    """
    import bpy
    from mathutils import Vector
    sys.path.insert(0, str(SRC))
    from materials import PALETTE
    audit = {'material_factors': {}, 'dark_well_faces': {}, 'wear_corners': {}}
    for _, (name, palette, metal, rough) in PALETTE.items():
        mat = bpy.data.materials.get('LG01 ' + name)
        if not mat: continue
        bsdf = next(n for n in mat.node_tree.nodes if n.type == 'BSDF_PRINCIPLED')
        bsdf.inputs['Metallic'].default_value = metal
        bsdf.inputs['Roughness'].default_value = rough
        audit['material_factors'][name] = {'palette': palette, 'metallic': metal, 'roughness': rough}
        if palette == '#A77738':
            nodes, links = mat.node_tree.nodes, mat.node_tree.links
            ao = nodes.new('ShaderNodeAmbientOcclusion')
            ao.inputs['Distance'].default_value = .85
            ao.only_local = True
            power = nodes.new('ShaderNodeMath'); power.operation = 'POWER'
            power.inputs[1].default_value = 2.5
            links.new(ao.outputs['AO'], power.inputs[0])
            multiply = nodes.new('ShaderNodeMixRGB'); multiply.blend_type = 'MULTIPLY'
            multiply.inputs[0].default_value = 1
            multiply.inputs[1].default_value = bsdf.inputs['Base Color'].default_value
            cavity = nodes.new('ShaderNodeVertexColor'); cavity.layer_name = 'NozzleCavity'
            attenuation = nodes.new('ShaderNodeMath'); attenuation.operation = 'MULTIPLY'
            links.new(power.outputs[0], attenuation.inputs[0])
            links.new(cavity.outputs['Color'], attenuation.inputs[1])
            links.new(attenuation.outputs[0], multiply.inputs[2])
            links.new(multiply.outputs[0], bsdf.inputs['Base Color'])
            audit['bronze_cavity'] = {'distance_m': .85, 'power': 2.5, 'only_local': True, 'axial_cavity_floor': .025, 'axial_exponent': 3.0}
    recess = bpy.data.materials.get('LG01 Dark recess')
    for obj in parts:
        if obj.get('part_id') == 'LG-450':
            obj.data = obj.data.copy()
            mesh = obj.data
            axis = Vector((0, -math.cos(math.radians(12)), -math.sin(math.radians(12))))
            bronze_faces = [f for f in mesh.polygons if mesh.materials[f.material_index].get('palette_srgb') == '#A77738']
            depths = [(obj.matrix_world @ mesh.vertices[v].co).dot(axis) for f in bronze_faces for v in f.vertices]
            low, high = min(depths), max(depths)
            cavity = mesh.color_attributes.new(name='NozzleCavity', type='FLOAT_COLOR', domain='CORNER')
            for face in bronze_faces:
                for loop in face.loop_indices:
                    point = obj.matrix_world @ mesh.vertices[mesh.loops[loop].vertex_index].co
                    t = max(0, min(1, (point.dot(axis)-low)/(high-low)))
                    value = .025 + .975*t**3
                    cavity.data[loop].color = (value,value,value,1)
        if not is_shell(obj): continue
        obj.data = obj.data.copy()
        mesh = obj.data
        wear = mesh.color_attributes.get('Wear')
        touched = 0
        if wear:
            for face in mesh.polygons:
                mat = mesh.materials[face.material_index]
                if not mat or mat.get('palette_srgb') not in {'#D2C8BC', '#D4861D'}: continue
                for loop in face.loop_indices:
                    value = wear.data[loop].color[0]
                    if .90 < value < .995:
                        # The source heuristic treats all sloped faces as wear;
                        # reserve it for small lands/edges, not whole sloped plates.
                        amount = 1 if face.area > .03 else 1 - 1.65 * (1 - value)
                        wear.data[loop].color = (amount, amount, amount, 1)
                        touched += 1
        audit['wear_corners'][obj['instance_id']] = touched
        pid = obj.get('part_id')
        if pid not in SHELLS or recess is None: continue
        if pid in {'FA-403-L', 'FA-404-L'}:
            sign = 1 if pid == 'FA-403-L' else -1
            sites = [(Vector((sign*.730, y, z)), Vector((sign,0,0)), .067)
                     for y,z in ((-.600,.720),(.700,.720),(-.500,1.450),(.500,1.450))]
        elif pid == 'FA-400':
            sites = [(Vector((x,y,.600-(y-1.500)*(.080/.900))),Vector((0,0,1)),.027)
                     for x in (-.560,.560) for y in (1.630,2.310)]
        elif pid == 'FA-401-L':
            sites = [(Vector((x,y,.700)),Vector((0,0,1)),.027)
                     for x in (-.650,.650) for y in (-.300,1.060)]
        else:
            sites = [(Vector((x,-.900,z)),Vector((0,-1,0)),.027)
                     for x in (-.560,.560) for z in (.300,.500)]
        slot = next((i for i,m in enumerate(mesh.materials) if m == recess), None)
        if slot is None:
            slot = len(mesh.materials); mesh.materials.append(recess)
        count = 0
        for face in mesh.polygons:
            mat = mesh.materials[face.material_index]
            if not mat or mat.get('palette_srgb') != '#D2C8BC': continue
            center = obj.matrix_world @ face.center
            for site, normal, radius in sites:
                delta = center-site; depth = -delta.dot(normal)
                radial = (delta + normal*depth).length
                if .0015 < depth < .047 and radial < radius:
                    face.material_index = slot; count += 1; break
        audit['dark_well_faces'][obj['instance_id']] = count
    return audit


def display_layout(parts, kind, camera):
    """Space silhouettes in the view plane; attached hardware follows its owner."""
    from mathutils import Vector, Matrix
    import bpy
    q = camera.rotation_euler.to_quaternion()
    right, up = q @ Vector((1,0,0)), q @ Vector((0,1,0))
    layout = LEG_LAYOUT if kind == 'leg-exploded' else FOOT_LAYOUT
    original = {o['instance_id']:o.matrix_world.copy() for o in parts}
    by_id = {o['instance_id']:o for o in parts}
    transforms = {}
    pads = sorted((o for o in parts if o.get('part_id') in PADS), key=lambda o:o['instance_id'])
    for obj in parts:
        if obj.hide_render: continue
        pid = obj.get('part_id'); position = layout.get(pid)
        if kind == 'leg-exploded' and pid == 'LG-450':
            position = (7.1, 3.8 if obj['instance_id'].endswith('.01') else 2.0)
        if kind == 'foot-pads':
            position = ((pads.index(obj)-2.5)*1.7, 0) if pid in PADS else None
        if position is None: continue
        center = sum(world_corners(obj), Vector())/8
        rotation = Matrix.Identity(4)
        if kind == 'leg-exploded' and pid in {'LG-215','LG-220','LG-225','LG-415','LG-420','LG-430','LG-450'}:
            rotation = Matrix.Translation(center) @ Matrix.Rotation(math.pi,4,'Z') @ Matrix.Translation(-center)
        delta = right*(position[0]-center.dot(right)) + up*(position[1]-center.dot(up))
        transforms[obj['instance_id']] = Matrix.Translation(delta) @ rotation
    # Leg service modules have no owner metadata in the shared scene. Their
    # matching side-shell relationship is explicit and uses the same transform.
    for obj in parts:
        if kind == 'leg-exploded' and obj.get('part_id') in {'LG-460', 'LG-470'}:
            pid = 'LG-410' if obj['instance_id'].endswith('.01') else 'LG-415'
            owner = next(o for o in parts if o.get('part_id') == pid)
            transforms[obj['instance_id']] = transforms[owner['instance_id']]
    for _ in range(5):
        for obj in parts:
            owner = obj.get('owner_instance')
            if owner in transforms and obj['instance_id'] not in transforms:
                transforms[obj['instance_id']] = transforms[owner]
    for iid, transform in transforms.items():
        by_id[iid].matrix_world = transform @ original[iid]
    bpy.context.view_layer.update()
    return {iid:[list(row) for row in transform] for iid,transform in transforms.items()}


def label_points(scene, camera, parts, resolution, kind):
    from bpy_extras.object_utils import world_to_camera_view
    ids = set(LEG_LAYOUT) | {'LG-450'} if kind == 'leg-exploded' else set(FOOT_LAYOUT)
    if kind == 'foot-pads': ids = PADS
    result = []
    for obj in parts:
        if obj.hide_render or obj.get('part_id') not in ids: continue
        pts = [world_to_camera_view(scene,camera,p) for p in world_corners(obj)]
        box = [min(p.x for p in pts)*resolution[0], (1-max(p.y for p in pts))*resolution[1],
               max(p.x for p in pts)*resolution[0], (1-min(p.y for p in pts))*resolution[1]]
        pid = obj['part_id']
        label = pid + (' / '+obj['instance_id'].split('.')[-1] if pid in PADS|{'LG-450'} else '')
        result.append({'text':label,'instance_id':obj['instance_id'],'bounds':box})
    return result


def clipped_material(material):
    """Render-only cut at the lower shin stub; no mesh edits or source writes."""
    copy = material.copy()
    copy.name = 'Comparison stub / ' + material.name
    nodes, links = copy.node_tree.nodes, copy.node_tree.links
    output = next(n for n in nodes if n.type == 'OUTPUT_MATERIAL' and n.is_active_output)
    surface = output.inputs['Surface'].links[0].from_socket
    geometry = nodes.new('ShaderNodeNewGeometry')
    xyz = nodes.new('ShaderNodeSeparateXYZ')
    links.new(geometry.outputs['Position'], xyz.inputs[0])
    above = nodes.new('ShaderNodeMath')
    above.operation = 'GREATER_THAN'
    above.inputs[1].default_value = STUB_TOP
    links.new(xyz.outputs['Z'], above.inputs[0])
    transparent = nodes.new('ShaderNodeBsdfTransparent')
    mix = nodes.new('ShaderNodeMixShader')
    links.new(above.outputs[0], mix.inputs[0])
    links.new(surface, mix.inputs[1])
    links.new(transparent.outputs[0], mix.inputs[2])
    links.new(mix.outputs[0], output.inputs['Surface'])
    return copy


def world_corners(obj, zmax=None):
    from mathutils import Vector
    points = [obj.matrix_world @ Vector(v) for v in obj.bound_box]
    if zmax is not None:
        points = [Vector((p.x, p.y, min(p.z, zmax))) for p in points]
    return points


def orient(camera, direction):
    from mathutils import Vector
    camera.rotation_euler = (-Vector(direction)).to_track_quat('-Z', 'Y').to_euler()
    if abs(direction[0]) + abs(direction[1]) < .001:
        camera.rotation_euler.z = math.pi / 2  # top view: +Y toe points right


def frame(camera, points, direction, resolution, perspective=False, fixed_height=None):
    """Fit actual projected bounds with margin; share height across orthos."""
    from mathutils import Vector
    orient(camera, direction)
    q = camera.rotation_euler.to_quaternion()
    inverse = q.inverted()
    local = [inverse @ p for p in points]
    low = Vector([min(p[i] for p in local) for i in range(3)])
    high = Vector([max(p[i] for p in local) for i in range(3)])
    target = q @ ((low + high) * .5)
    aspect = resolution[0] / resolution[1]
    height = fixed_height or max(high.y - low.y, (high.x - low.x) / aspect) * 1.12
    camera.data.type = 'PERSP' if perspective else 'ORTHO'
    camera.data.sensor_fit = 'HORIZONTAL'
    if perspective:
        tan_x = camera.data.sensor_width / (2 * camera.data.lens)
        tan_y = tan_x / aspect
        relative = [inverse @ (p - target) for p in points]
        distance = max(max(abs(p.x) * 1.12 / tan_x, abs(p.y) * 1.12 / tan_y) + p.z
                       for p in relative)
    else:
        # Blender ortho_scale is the horizontal sensor width in landscape,
        # vertical sensor height in portrait when sensor_fit is AUTO.
        camera.data.sensor_fit = 'AUTO'
        camera.data.ortho_scale = height * max(1, aspect)
        distance = 30
    camera.location = target + Vector(direction).normalized() * distance
    return target


def main():
    args = arguments()
    import bpy
    from mathutils import Vector
    from bpy_extras.object_utils import world_to_camera_view
    start = time.monotonic()
    args.work.mkdir(parents=True, exist_ok=True)
    args.out.mkdir(parents=True, exist_ok=True)
    scene = bpy.context.scene
    source = Path(bpy.data.filepath)
    if not source.is_file():
        raise RuntimeError('Open output/leg-lg01.blend with --background before running this script')
    parts = [o for o in scene.objects if o.type == 'MESH' and o.get('instance_id')]
    if not parts:
        raise RuntimeError('No registered parts in the loaded blend')
    evidence = {'blend': str(source), 'blend_sha256_at_start': sha256(source),
                'blender': bpy.app.version_string, 'samples': args.samples,
                'res_scale': args.res_scale, 'sheets': args.only, 'renders': {},
                'script_sha256': {name:sha256(SRC/name) for name in ('render_compare.py','compose_compare.py','tone_probe.py','materials.py')},
                'view_transform': args.view_transform, 'exposure': args.exposure,
                'lighting': {'key_energy': args.key_energy, 'fill_ratio': args.fill_ratio,
                             'rim_energy': args.rim_energy, 'world_strength': args.world_strength},
                'side_display': 'Outer (-X), horizontally reflected to match the reference toe direction'}
    evidence['explosion'] = {'mode': 'Separated display layout; installation poses unchanged', 'instances': {}}
    evidence['finish_audit'] = prepare_finish(parts)
    original = {o.name: (o.matrix_world.copy(), o.hide_render) for o in parts}
    original_materials = [(slot, slot.link, slot.material) for o in parts
                          if o.get('part_id') == 'LG-100' for slot in o.material_slots]
    clip_materials = {slot.material.name: clipped_material(slot.material)
                      for slot, _, _ in original_materials if slot.material}
    evidence['shading_audit'] = prepare_facets(parts)
    camera, lights, ground = setup_studio(scene, args)

    def state(kind):
        for slot, link, material in original_materials:
            slot.link = link
            slot.material = material
        for obj in parts:
            obj.matrix_world = original[obj.name][0]
            foot = is_foot(obj)
            pid = obj.get('part_id')
            visible = True
            if kind == 'leg-exploded':
                visible = not foot
            elif kind == 'leg-structure':
                visible = not is_shell(obj) and obj.get('subassembly') != 'foot-armor'
            elif kind.startswith('foot'):
                visible = foot or (kind == 'foot' and pid == 'LG-100')
                if kind == 'foot-structure':
                    visible = foot and not (is_shell(obj) or pid in SOLES or
                                            obj.get('subassembly') in {'foot-armor', 'soles'})
            obj.hide_render = not visible
            if kind == 'foot-exploded' and (pid in PADS or obj.get('hardware_use') == 'Sole pad mounts' or pid == 'FA-305'):
                obj.hide_render = True
            if kind == 'foot-pads':
                obj.hide_render = pid not in PADS
        if kind == 'foot':
            for slot, _, material in original_materials:
                slot.link = 'OBJECT'
                slot.material = clip_materials[material.name]
        bpy.context.view_layer.update()
        return [p for o in parts if not o.hide_render
                for p in world_corners(o, STUB_TOP if kind == 'foot' and o.get('part_id') == 'LG-100' else None)]

    def render(key, kind, direction, size, perspective=False, fixed_height=None, region=None):
        points = state(kind)
        if 'exploded' in kind or kind == 'foot-pads':
            orient(camera, direction)
            evidence['explosion']['instances'][kind] = display_layout(parts, kind, camera)
            bpy.context.view_layer.update()
            points = [p for o in parts if not o.hide_render for p in world_corners(o)]
        if region:
            low, high = map(Vector, region)
            points = [Vector((x, y, z)) for x in (low.x, high.x)
                      for y in (low.y, high.y) for z in (low.z, high.z)]
        resolution = tuple(max(64, round(v * args.res_scale)) for v in size)
        scene.render.resolution_x, scene.render.resolution_y = resolution
        target = frame(camera, points, direction, resolution, perspective, fixed_height)
        subject_size = 10 if kind.startswith('leg') else 4
        if region:
            subject_size = 6
        horizontal = Vector((direction[0], direction[1], 0)).normalized()
        light_target = target
        if key in {'lg01-assembled-front', 'lg01-assembled-three-quarter'}:
            horizontal = Vector((0, 1, 0))
            light_target = Vector((0, 0, 4.8))
        if horizontal.length < .01:
            horizontal = Vector((-1, 0, 0))
        right = Vector((horizontal.y, -horizontal.x, 0))
        for light, delta, energy, size in lights:
            # A distant, proportionately larger softbox keeps the calf from
            # going dark while the upper thigh clips. Angular softness is kept.
            lighting_delta = delta.copy()
            light_power, light_size = energy, size
            if kind == 'foot-pads':
                # A small grazing source casts real shadows across 12 mm tread
                # cuts; a soft weak fill keeps the rubber from becoming black.
                if light.name.startswith('Key'):
                    lighting_delta = Vector((.98481, 0, -.17365))
                    light_power *= 3; light_size = .08
                elif light.name.startswith('Fill'):
                    lighting_delta = Vector((-.5, -.5, -.70711))
                    light_power *= .25; light_size = .35
                else:
                    lighting_delta = Vector((0, .95106, -.30902))
                    light_power *= .5
            light.location = light_target + subject_size * 24 * (right * lighting_delta.x + horizontal * lighting_delta.y + Vector((0, 0, lighting_delta.z)))
            light.rotation_euler = (light_target - light.location).to_track_quat('-Z', 'Y').to_euler()
            light.data.energy = light_power * (subject_size / 10) ** 2 * 576
            light.data.size = light_size * subject_size * 24
        ground.hide_render = True
        bpy.context.view_layer.update()
        projected = [world_to_camera_view(scene, camera, p) for p in points]
        extents = [min(p.x for p in projected), min(p.y for p in projected),
                   max(p.x for p in projected), max(p.y for p in projected)]
        if not region and not all(.015 < v < .985 for v in extents):
            raise RuntimeError(f'{key}: geometry would be clipped: {extents}')
        probes = None
        if key in {'lg01-assembled-front', 'lg01-assembled-three-quarter'}:
            try:
                probes = tone_points(scene, camera, parts, resolution, key.endswith('three-quarter'))
            except Exception as error:
                # Diagnostics must never prevent the requested image delivery.
                print(f'TONE PROBE FAILURE: {key}: {error}', flush=True)
                probes = {'diagnostic_error': {'part_id':'unknown', 'valid':False, 'error':str(error)}}
        path = args.work / f'r-{key}.png'
        scene.render.filepath = str(path)
        began = time.monotonic()
        print(f'COMPARE {key}: {resolution}, {len([o for o in parts if not o.hide_render])} parts', flush=True)
        bpy.ops.render.render(write_still=True)
        shadow_paths = None
        if key.endswith('three-quarter') and 'exploded' not in kind and not region:
            # Half-resolution shadows are softly filtered during composition.
            visibility = [(obj, obj.hide_render) for obj in parts]
            ground.hide_render = False
            scene.render.resolution_percentage = 50
            for suffix in ('shadow', 'clear'):
                if suffix == 'clear':
                    for obj in parts:
                        obj.hide_render = True
                scene.render.filepath = str(args.work / f'r-{key}-floor-{suffix}.png')
                bpy.ops.render.render(write_still=True)
            shadow_paths = {suffix: str(args.work / f'r-{key}-floor-{suffix}.png')
                            for suffix in ('shadow', 'clear')}
            for obj, hidden in visibility:
                obj.hide_render = hidden
            ground.hide_render = True
            scene.render.resolution_percentage = 100
        evidence['renders'][key] = {'png': str(path), 'seconds': round(time.monotonic() - began, 2),
                                   'bounds_normalized': extents, 'resolution': resolution,
                                   'tone_points': probes, 'labels': label_points(scene,camera,parts,resolution,kind) if 'exploded' in kind or kind == 'foot-pads' else [], 'camera_location': list(camera.location),
                                   'camera_target': list(target),
                                   'elevation_degrees': math.degrees(math.atan2(direction[2], math.hypot(*direction[:2]))),
                                   'azimuth_off_front_degrees': math.degrees(math.atan2(abs(direction[0]), direction[1])),
                                   'lights': [{'name': light.name, 'location': list(light.location),
                                               'watts': light.data.energy, 'size': light.data.size}
                                              for light, _, _, _ in lights],
                                   'floor_passes': shadow_paths, 'kind': kind, 'projection': camera.data.type,
                                   'lens_mm': camera.data.lens if perspective else None,
                                   'ortho_scale': camera.data.ortho_scale if not perspective else None,
                                   'mirror_display': key.endswith('-side'),
                                   'z0': world_to_camera_view(scene, camera, Vector((0, 0, 0))).y,
                                   'z825': world_to_camera_view(scene, camera, Vector((0, 0, 8.25))).y}

    # Uniform narrow panels keep the leg's orthographic image scales identical.
    leg_points = state('leg')
    zmin, zmax = min(p.z for p in leg_points), max(p.z for p in leg_points)
    height = max((zmax - zmin) * 1.10, 3.6 / (820 / 1940))
    if 'lg01-assembled' in args.only:
        render('lg01-assembled-three-quarter', 'leg', (-math.sin(math.radians(38)), math.cos(math.radians(38)), math.tan(math.radians(11))), (820, 1940))
    if {'lg01-assembled', 'turnaround-leg'} & set(args.only):
        for name, direction in [('side', (-1, 0, 0)), ('front', (0, 1, 0)), ('back', (0, -1, 0))]:
            render('lg01-assembled-' + name, 'leg', direction, (820, 1940), fixed_height=height)
    if 'lg01-armor' in args.only:
        render('lg01-armor-exploded', 'leg-exploded', (-1, 1.5, .65), (3300, 1940))
    if 'lg01-structure' in args.only:
        render('lg01-structure-rear-outer', 'leg-structure', (-.85, -1.4, .22), (1280, 1940), True)
        render('lg01-structure-knee', 'leg-structure', (-1, -1.4, .45), (1780, 1580), True,
               region=((-1.05, -.95, 4.05), (1.05, .50, 6.65)))
    if 'fa02-assembled' in args.only:
        render('fa02-assembled-three-quarter', 'foot', (-.85, 1.3, .85), (1660, 1280))
        render('fa02-assembled-side', 'foot', (-1, 0, 0), (1600, 900))
        render('fa02-assembled-front', 'foot', (0, 1, 0), (770, 950))
        render('fa02-assembled-back', 'foot', (0, -1, 0), (770, 950))
        render('fa02-assembled-top', 'foot', (0, 0, 1), (1660, 640))
    if 'fa02-armor' in args.only:
        render('fa02-armor-exploded', 'foot-exploded', (-1, 1.25, 1.1), (3300, 1500))
        render('fa02-armor-underside', 'foot-pads', (0, -.45, -1), (3300, 420))
    if 'fa02-structure' in args.only:
        render('fa02-structure-three-quarter', 'foot-structure', (-1, 1.25, 1.05), (3300, 1900), True)
    evidence['blend_sha256_at_end'] = sha256(source)
    evidence['source_changed_during_render'] = evidence['blend_sha256_at_start'] != evidence['blend_sha256_at_end']
    evidence['seconds_before_composition'] = round(time.monotonic() - start, 2)
    evidence_path = args.work / 'compare-evidence.json'
    evidence_path.write_text(json.dumps(evidence, indent=2) + '\n')
    python = shutil.which('python3')
    if not python:
        raise RuntimeError('System python3 with Pillow is required for composition')
    subprocess.run([python, str(SRC / 'compose_compare.py'), '--evidence', str(evidence_path),
                    '--out', str(args.out)], check=True)
    probe = SRC / 'tone_probe.py'
    if probe.is_file() and 'lg01-assembled' in args.only:
        subprocess.run([python, str(probe), '--evidence', str(evidence_path), '--notes', str(args.out / 'notes-render.md')])  # diagnostic only; never fails the render
    print(f'COMPARE complete: {len(args.only)} sheets in {time.monotonic() - start:.1f}s; {args.out}', flush=True)
    if evidence['source_changed_during_render']:
        print('NOTE: another process replaced the blend during rendering; views use the scene loaded at startup.')


if __name__ == '__main__':
    main()
