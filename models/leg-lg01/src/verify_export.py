"""Validate the GLB and shared step contract without Blender or third-party packages.

python3 models/leg-lg01/src/verify_export.py
Also runs through Blender --python (arguments go after --).
"""
import argparse
from collections import Counter
import hashlib
import json
import math
from pathlib import Path
import struct
import sys

ROOT = Path(__file__).resolve().parents[1]
VIEWER = ROOT.parents[1] / 'design/legs/viewer'  # viewer app lives with the leg design docs
SCHEMA = 'leg-lg01-build-steps/1'
MAX_BYTES = 150_000_000
MAX_TRIANGLES = 2_500_000


def read_glb(path):
    data = Path(path).read_bytes()
    if len(data) < 20:
        raise ValueError('Truncated GLB')
    magic, version, length = struct.unpack_from('<4sII', data)
    if magic != b'glTF' or version != 2 or length != len(data):
        raise ValueError('Invalid GLB 2 header/length')
    chunks = []
    offset = 12
    while offset < length:
        size, kind = struct.unpack_from('<II', data, offset)
        offset += 8
        if size % 4 or offset + size > length:
            raise ValueError('Invalid GLB chunk length')
        chunks.append((kind, data[offset:offset + size]))
        offset += size
    if not chunks or chunks[0][0] != 0x4E4F534A:
        raise ValueError('GLB has no leading JSON chunk')
    return json.loads(chunks[0][1]), chunks


def write_glb(path, document, chunks):
    payload = json.dumps(document, separators=(',', ':'), ensure_ascii=True).encode()
    payload += b' ' * (-len(payload) % 4)
    chunks = [(0x4E4F534A, payload), *chunks[1:]]
    body = b''.join(struct.pack('<II', len(data), kind) + data for kind, data in chunks)
    Path(path).write_bytes(struct.pack('<4sII', b'glTF', 2, 12 + len(body)) + body)


def triangle_count(document):
    """Count rendered instances, including every material primitive of each mesh."""
    total = 0
    for node in document.get('nodes', []):
        if 'mesh' not in node:
            continue
        for primitive in document['meshes'][node['mesh']]['primitives']:
            accessor = primitive.get('indices', primitive['attributes']['POSITION'])
            count = document['accessors'][accessor]['count']
            mode = primitive.get('mode', 4)
            if mode == 4 and count % 3 == 0:
                total += count // 3
            elif mode in (5, 6):
                total += max(0, count - 2)
            else:
                raise ValueError(f'Non-triangle or malformed primitive: mode={mode}, count={count}')
    return total


def duplicates(values):
    return sorted(key for key, count in Counter(values).items() if count > 1)


def validate_steps(steps, nodes):
    """Shared, strict schema/identity check used by both command-line checks."""
    errors = []
    if steps.get('schema') != SCHEMA or steps.get('units') != 'm':
        errors.append('Expected schema leg-lg01-build-steps/1 and units m')
    if not isinstance(steps.get('coordinates'), str) or not steps['coordinates']:
        errors.append('Missing coordinates description')
    parts = steps.get('parts', {})
    sequence = steps.get('steps', [])
    if not isinstance(parts, dict) or not isinstance(sequence, list) or not sequence:
        raise ValueError('parts must be a dictionary and steps a nonempty array')
    for iid, part in parts.items():
        for key in ('part_id', 'part_name', 'subassembly', 'category'):
            if not isinstance(part.get(key), str) or not part[key]:
                errors.append(f'{iid}: missing part metadata {key}')
        if not isinstance(part.get('armor'), bool):
            errors.append(f'{iid}: armor must be a boolean')
    installs = []
    step_ids = []
    for index, step in enumerate(sequence, 1):
        step_ids.append(step.get('id'))
        if step.get('index') != index:
            errors.append(f'Step {index}: index must be consecutive and one-based')
        for key in ('id', 'title', 'section', 'group'):
            if not isinstance(step.get(key), str) or not step[key]:
                errors.append(f'Step {index}: missing {key}')
        if not isinstance(step.get('installs'), list) or not step['installs']:
            errors.append(f'Step {index}: installs must be a nonempty array')
            continue
        for install in step['installs']:
            iid = install.get('instance_id')
            if not isinstance(iid, str) or not iid:
                errors.append(f'Step {index}: missing instance_id')
                continue
            installs.append(iid)
            vector = install.get('approach')
            valid = (isinstance(vector, list) and len(vector) == 3 and
                     all(isinstance(v, (int, float)) and not isinstance(v, bool) and math.isfinite(v) for v in vector))
            if not valid or abs(sum(v * v for v in vector) - 1) > 1e-4:
                errors.append(f'{iid}: approach must be a finite unit vector')
            offset = install.get('offset')
            if isinstance(offset, bool) or not isinstance(offset, (int, float)) or not math.isfinite(offset) or offset < 0:
                errors.append(f'{iid}: offset must be finite and nonnegative')
    node_names = {n.get('name', '') for n in nodes}
    installed = set(installs)
    missing = sorted(installed - node_names)
    extra = sorted(node_names - installed)
    duplicate_installs = duplicates(installs)
    if missing or extra:
        errors.append('Step installs and GLB node names are not one-to-one')
    if duplicate_installs:
        errors.append('Some instances appear in more than one install')
    if len(set(step_ids)) != len(step_ids):
        errors.append('Step IDs are not unique')
    if set(parts) != installed:
        errors.append('parts metadata and step installs are not one-to-one')
    for node in nodes:
        part = parts.get(node.get('name'))
        if part:
            for key in ('part_id', 'part_name', 'subassembly', 'category'):
                if part.get(key) != node.get('extras', {}).get(key):
                    errors.append(f'{node.get("name")}: {key} differs between steps and GLB')
    return dict(errors=errors, step_count=len(sequence), install_count=len(installs),
                missing_from_glb=missing, extra_glb_nodes=extra,
                duplicate_installs=duplicate_installs,
                parts_without_installs=sorted(set(parts) - installed),
                installs_without_metadata=sorted(installed - set(parts)))


def audit(glb=VIEWER / 'leg-lg01.glb', steps=VIEWER / 'build-steps.json',
          manifest=ROOT / 'output/parts-manifest.json'):
    document, _ = read_glb(glb)
    nodes = document.get('nodes', [])
    errors = []
    source = document.get('asset', {}).get('extras', {}).get('lg01_export', {})
    source_count = source.get('scene_part_count')
    if len(nodes) != source_count or not nodes:
        errors.append(f'Node count {len(nodes)} != exported scene part count {source_count}')
    invalid_nodes = []
    for node in nodes:
        extras = node.get('extras', {})
        if ('mesh' not in node or any(not extras.get(k) for k in
                ('part_id', 'part_name', 'instance_id', 'subassembly', 'category')) or
                node.get('name') != extras.get('instance_id')):
            invalid_nodes.append(node.get('name', '<unnamed>'))
        if node.get('children'):
            errors.append(f'{node.get("name")}: export must have unparented part nodes')
    if invalid_nodes:
        errors.append('Nodes are missing identity/mesh metadata or have mismatched names')
    duplicate_nodes = duplicates([n.get('name', '') for n in nodes])
    if duplicate_nodes:
        errors.append('Duplicate GLB node names')
    roots = document.get('scenes', [{}])[document.get('scene', 0)].get('nodes', [])
    if sorted(roots) != list(range(len(nodes))):
        errors.append('Active scene must contain every part exactly once as a root node')
    if document.get('animations'):
        errors.append('Assembled GLB must not contain animations')
    triangles = triangle_count(document)
    size = Path(glb).stat().st_size
    materials = len(document.get('materials', []))
    if triangles > MAX_TRIANGLES:
        errors.append(f'Triangle budget exceeded: {triangles} > {MAX_TRIANGLES}')
    if size >= MAX_BYTES:
        errors.append(f'Size budget exceeded: {size} >= {MAX_BYTES}')
    if not materials or materials != source.get('material_count'):
        errors.append(f'Material count {materials} != export receipt {source.get("material_count")}')
    if triangles != source.get('evaluated_triangles'):
        errors.append('GLB triangle count differs from evaluated scene geometry')
    manifest_data = json.loads(Path(manifest).read_text())
    manifest_names = {p['instance_id'] for p in manifest_data['parts']}
    node_names = {n.get('name') for n in nodes}
    if manifest_data['object_count'] != len(nodes) or manifest_names != node_names:
        errors.append('Current manifest differs from exported scene; export and regenerate steps together')
    for node in nodes:
        for primitive in document['meshes'][node['mesh']]['primitives']:
            if 'material' not in primitive or not 0 <= primitive['material'] < materials:
                errors.append(f'{node.get("name")}: invalid material reference')
    steps_report = validate_steps(json.loads(Path(steps).read_text()), nodes)
    errors.extend(steps_report.pop('errors'))
    return dict(ok=not errors, errors=errors, glb=str(glb),
                glb_sha256=hashlib.sha256(Path(glb).read_bytes()).hexdigest(),
                bytes=size, megabytes=round(size / 1e6, 3), triangle_count=triangles,
                material_count=materials, node_count=len(nodes), scene_part_count=source_count,
                source=source, invalid_nodes=invalid_nodes, duplicate_nodes=duplicate_nodes,
                missing_manifest_nodes=sorted(manifest_names - node_names),
                extra_manifest_nodes=sorted(node_names - manifest_names), **steps_report)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--glb', type=Path, default=VIEWER / 'leg-lg01.glb')
    parser.add_argument('--steps', type=Path, default=VIEWER / 'build-steps.json')
    parser.add_argument('--manifest', type=Path, default=ROOT / 'output/parts-manifest.json')
    parser.add_argument('--report', type=Path, default=ROOT / 'output/audits/export.json')
    argv = sys.argv[sys.argv.index('--') + 1:] if '--' in sys.argv else sys.argv[1:]
    args = parser.parse_args(argv)
    try:
        report = audit(args.glb, args.steps, args.manifest)
    except Exception as exc:
        report = dict(ok=False, errors=[f'{type(exc).__name__}: {exc}'])
    args.report.parent.mkdir(parents=True, exist_ok=True)
    args.report.write_text(json.dumps(report, indent=2) + '\n')
    print(json.dumps(report, indent=2))
    return 0 if report['ok'] else 1


if __name__ == '__main__':
    raise SystemExit(main())
