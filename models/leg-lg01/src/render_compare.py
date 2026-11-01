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
    parser.add_argument('--key-energy', type=float, default=1850)
    parser.add_argument('--fill-ratio', type=float, default=.30)
    parser.add_argument('--rim-energy', type=float, default=500)
    parser.add_argument('--world-strength', type=float, default=.055)
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


def placeholder(value):
    if isinstance(value, dict):
        return value.get('placeholder') is True or any(placeholder(v) for v in value.values())
    return isinstance(value, list) and any(placeholder(v) for v in value)


def offsets():
    path = PACKAGE / 'viewer' / 'build-steps.json'
    if not path.exists():
        return {}, {'mode': 'radial fallback', 'reason': 'No build-steps.json'}
    data = json.loads(path.read_text())
    if placeholder(data) or not data.get('steps'):
        return {}, {'mode': 'radial fallback', 'reason': 'Placeholder or empty build steps'}
    result = {}
    for step in data['steps']:
        for item in step['installs']:
            direction = item['approach']
            distance = item['offset']
            if len(direction) != 3 or not all(math.isfinite(v) for v in direction):
                raise ValueError(f'Invalid approach: {item}')
            if not math.isfinite(distance) or distance < 0:
                raise ValueError(f'Invalid explosion distance: {item}')
            result[item['instance_id']] = [v * distance * .5 for v in direction]
    return result, {'mode': 'build steps × 0.5', 'sha256': sha256(path), 'steps': len(data['steps'])}


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
    camera.data.lens = 50
    scene.camera = camera
    lights = []
    # Camera-left is +X in the front view. One soft key at 45° az / 35° el;
    # the opposite fill is about one quarter of its power at the same distance.
    for name, delta, energy, size in (
            ('Key / upper left', (.57923, .57923, .57358), args.key_energy, .50),
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


def tone_points(scene, camera, parts, resolution):
    """Hit known part surfaces, then project them; never hand-pick render pixels.

    The front view cannot see a side bearing face, so its knee sample uses the
    exposed front of the hinge. The oblique view samples the outer bearing.
    Occlusion and first-hit material are recorded to reject invalid samples.
    """
    from mathutils import Vector
    from bpy_extras.object_utils import world_to_camera_view
    specs = {
        'lit_thigh': ('LG-200', (0, 3, 7.0), (0, -1, 0)),
        'shaded_thigh': ('LG-210', (-.85, 3, 7.0), (0, -1, 0)),
        'ochre_kneecap': ('LG-300', (0, 3, 5.10), (0, -1, 0)),
        'calf_front': ('LG-400', (0, 3, 3.30), (0, -1, 0)),
    }
    if camera.data.type == 'PERSP':
        specs['shaded_thigh'] = ('LG-210', (-3, -.25, 7.0), (1, 0, 0))
    depsgraph = scene.view_layers[0].depsgraph
    result = {}
    for name, (pid, origin, direction) in specs.items():
        obj = next(o for o in parts if o.get('part_id') == pid)
        inv = obj.matrix_world.inverted()
        hit, local, normal, index = obj.ray_cast(inv @ Vector(origin), inv.to_3x3() @ Vector(direction))
        if not hit:
            # A diagnostic probe must not block rendering after geometry changes.
            print(f'WARNING: tone anchor misses {pid}: {name}')
            result[name] = {'part_id': pid, 'missed': True}
            continue
        point = obj.matrix_world @ local
        p = world_to_camera_view(scene, camera, point)
        # Cast from the actual camera ray (parallel for orthographic cameras).
        ray = (point - camera.location).normalized() if camera.data.type == 'PERSP' else camera.rotation_euler.to_quaternion() @ Vector((0, 0, -1))
        hit2, co2, _, face2, obj2, _ = scene.ray_cast(depsgraph, point - ray * 30, ray)
        result[name] = {'part_id': pid, 'instance_id': obj['instance_id'],
                        'world': list(point), 'normal': list(normal),
                        'pixel': [round(p.x * resolution[0]), round((1-p.y) * resolution[1])],
                        'radius': (max(1, round(resolution[0] / 820)) if name == 'shaded_thigh' and camera.data.type == 'ORTHO'
                                   else max(2, round(4 * resolution[0] / 820))),
                        'visible': bool(hit2 and (co2 - point).length < .025),
                        'first_hit': obj2.get('instance_id') if hit2 else None,
                        'material': obj.data.materials[obj.data.polygons[index].material_index].name}
    # A camera-visible gunmetal patch on the knee hinge, with the same projection
    # and occlusion validation as the painted patches.
    pid = 'LG-330' if camera.data.type == 'PERSP' else 'LG-110'
    obj = next((o for o in parts if o.get('part_id') == pid), None)
    if obj:
        origin, direction = ((-3, 0, 5.10), (1, 0, 0)) if pid == 'LG-330' else ((-.43, 3, 5.10), (0, -1, 0))
        inv = obj.matrix_world.inverted()
        hit, co, _, index = obj.ray_cast(inv @ Vector(origin), inv.to_3x3() @ Vector(direction))
        if hit:
            point = obj.matrix_world @ co
            p = world_to_camera_view(scene, camera, point)
            ray = (point-camera.location).normalized() if camera.data.type == 'PERSP' else Vector((0,-1,0))
            h, c, _, _, o, _ = scene.ray_cast(depsgraph, point-ray*30, ray)
            result['dark_knee'] = {'part_id': pid, 'instance_id': obj['instance_id'], 'world': list(point),
                'pixel': [round(p.x*resolution[0]),round((1-p.y)*resolution[1])],
                'radius': max(2,round(4*resolution[0]/820)), 'visible':bool(h and (c-point).length<.025),
                'first_hit':o.get('instance_id') if h else None,
                'material':obj.data.materials[obj.data.polygons[index].material_index].name}
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
                'view_transform': args.view_transform, 'exposure': args.exposure,
                'lighting': {'key_energy': args.key_energy, 'fill_ratio': args.fill_ratio,
                             'rim_energy': args.rim_energy, 'world_strength': args.world_strength},
                'side_display': 'Outer (-X), horizontally reflected to match the reference toe direction'}
    approach, evidence['explosion'] = offsets()
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
            explode = ('exploded' in kind and visible and
                       (is_shell(obj) or pid in SOLES or pid == 'LG-450' or
                        obj.get('subassembly') in {'foot-armor', 'soles'}))
            if explode:
                delta = approach.get(obj['instance_id'])
                stats = evidence['explosion'].setdefault('instances', {}).setdefault(kind, {})
                stats[obj['instance_id']] = 'steps' if delta is not None else 'radial fallback'
                if delta is None:
                    corners = world_corners(obj)
                    centre = sum(corners, Vector()) / len(corners)
                    radial = Vector((centre.x, centre.y, 0))
                    if radial.length < .001:
                        radial = Vector((0, 1, 0))
                    delta = radial.normalized() * .6
                obj.matrix_world.translation += Vector(delta)
        if kind == 'foot':
            for slot, _, material in original_materials:
                slot.link = 'OBJECT'
                slot.material = clip_materials[material.name]
        bpy.context.view_layer.update()
        return [p for o in parts if not o.hide_render
                for p in world_corners(o, STUB_TOP if kind == 'foot' and o.get('part_id') == 'LG-100' else None)]

    def render(key, kind, direction, size, perspective=False, fixed_height=None, region=None):
        points = state(kind)
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
            light.location = light_target + subject_size * 6 * (right * delta.x + horizontal * delta.y + Vector((0, 0, delta.z)))
            light.rotation_euler = (light_target - light.location).to_track_quat('-Z', 'Y').to_euler()
            light.data.energy = energy * (subject_size / 10) ** 2 * 36
            light.data.size = size * subject_size * 6
        ground.hide_render = True
        bpy.context.view_layer.update()
        projected = [world_to_camera_view(scene, camera, p) for p in points]
        extents = [min(p.x for p in projected), min(p.y for p in projected),
                   max(p.x for p in projected), max(p.y for p in projected)]
        if not region and not all(.015 < v < .985 for v in extents):
            raise RuntimeError(f'{key}: geometry would be clipped: {extents}')
        probes = tone_points(scene, camera, parts, resolution) if key in {
            'lg01-assembled-front', 'lg01-assembled-three-quarter'} else None
        path = args.work / f'r-{key}.png'
        scene.render.filepath = str(path)
        began = time.monotonic()
        print(f'COMPARE {key}: {resolution}, {len([o for o in parts if not o.hide_render])} parts', flush=True)
        bpy.ops.render.render(write_still=True)
        shadow_paths = None
        if perspective and 'exploded' not in kind and not region:
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
                                   'tone_points': probes, 'camera_location': list(camera.location),
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
        render('lg01-assembled-three-quarter', 'leg', (-math.sin(math.radians(38)), math.cos(math.radians(38)), math.tan(math.radians(11))), (820, 1940), True)
    if {'lg01-assembled', 'turnaround-leg'} & set(args.only):
        for name, direction in [('side', (-1, 0, 0)), ('front', (0, 1, 0)), ('back', (0, -1, 0))]:
            render('lg01-assembled-' + name, 'leg', direction, (820, 1940), fixed_height=height)
    if 'lg01-armor' in args.only:
        render('lg01-armor-exploded', 'leg-exploded', (-1, 1.5, .65), (2800, 1940), True)
    if 'lg01-structure' in args.only:
        render('lg01-structure-rear-outer', 'leg-structure', (-.85, -1.4, .22), (1280, 1940), True)
        render('lg01-structure-knee', 'leg-structure', (-1, -1.4, .45), (1780, 1580), True,
               region=((-1.05, -.95, 4.05), (1.05, .50, 6.65)))
    if 'fa02-assembled' in args.only:
        render('fa02-assembled-three-quarter', 'foot', (-.85, 1.3, .85), (1660, 1280), True)
        render('fa02-assembled-side', 'foot', (-1, 0, 0), (1600, 900))
        render('fa02-assembled-front', 'foot', (0, 1, 0), (770, 950))
        render('fa02-assembled-back', 'foot', (0, -1, 0), (770, 950))
        render('fa02-assembled-top', 'foot', (0, 0, 1), (1660, 640))
    if 'fa02-armor' in args.only:
        render('fa02-armor-exploded', 'foot-exploded', (-1, 1.25, 1.1), (3300, 1900), True)
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
        subprocess.run([python, str(probe), '--evidence', str(evidence_path)])  # diagnostic only; never fails the render
    print(f'COMPARE complete: {len(args.only)} sheets in {time.monotonic() - start:.1f}s; {args.out}', flush=True)
    if evidence['source_changed_during_render']:
        print('NOTE: another process replaced the blend during rendering; views use the scene loaded at startup.')


if __name__ == '__main__':
    main()
