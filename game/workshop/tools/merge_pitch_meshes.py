"""Replace scoped source meshes and compact reachable rigid, untextured GLB data.

Repeated repairs are deterministic: obsolete mesh/accessor/view/material records
and their bytes are discarded. Retained nodes, material records and accessor bytes
are checked semantically, since compaction necessarily changes resource indices.
"""
import argparse
import copy
import hashlib
import json
import struct
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
GAME = ROOT / 'game/workshop'
TARGET = GAME / 'assets/foot-fa01.glb'
REVISION = ROOT / 'models/foot-fa01/output/pitch-revision.glb'


def read(path):
    raw = Path(path).read_bytes()
    if len(raw) < 28 or struct.unpack_from('<III', raw) != (0x46546C67, 2, len(raw)):
        raise ValueError('Expected a complete GLB 2.0 file')
    chunks = {}; offset = 12
    while offset < len(raw):
        size, kind = struct.unpack_from('<II', raw, offset); offset += 8
        if offset + size > len(raw) or kind in chunks:
            raise ValueError('Invalid or duplicate GLB chunk')
        chunks[kind] = raw[offset:offset + size]; offset += size
    return json.loads(chunks[0x4E4F534A]), chunks.get(0x004E4942, b'')


def encode(data, binary):
    encoded = json.dumps(data, separators=(',', ':'), ensure_ascii=False).encode()
    encoded += b' ' * (-len(encoded) % 4)
    binary += b'\0' * (-len(binary) % 4)
    return (struct.pack('<III', 0x46546C67, 2, 28 + len(encoded) + len(binary)) +
            struct.pack('<II', len(encoded), 0x4E4F534A) + encoded +
            struct.pack('<II', len(binary), 0x004E4942) + binary)


def uid(node):
    return node.get('extras', {}).get('instance_id') or '__'.join(node.get('name', '').split('__')[:2])


def validate_supported(data, binary):
    # Fail before writing rather than dropping opaque references in future assets.
    if any(data.get(k) for k in ('animations', 'skins', 'images', 'textures', 'samplers', 'extensionsUsed', 'extensionsRequired')):
        raise ValueError('Scoped merge supports rigid, untextured GLBs without extensions only')
    def extensions(value):
        if isinstance(value, dict):
            if value.get('extensions'):
                raise ValueError('Cannot remap opaque GLTF extension references')
            for key, child in value.items():
                if key != 'extras': extensions(child)
        elif isinstance(value, list):
            for child in value: extensions(child)
    extensions(data)
    buffers = data.get('buffers', [])
    if len(buffers) != 1 or 'uri' in buffers[0] or buffers[0]['byteLength'] > len(binary):
        raise ValueError('Expected one embedded GLB buffer')
    for view in data.get('bufferViews', []):
        start = view.get('byteOffset', 0)
        if view.get('buffer', 0) != 0 or start < 0 or start + view['byteLength'] > buffers[0]['byteLength']:
            raise ValueError('Buffer view is outside the embedded buffer')


def semantic_nodes(data, binary):
    """Index-independent fingerprints, including exact accessor bytes/materials.

    Includes node transforms/extras, primitive attributes, morphs and sparse data;
    unchanged fingerprints prove the same geometry and oriented scene placement.
    """
    def view(index):
        result = copy.deepcopy(data['bufferViews'][index])
        start = result.pop('byteOffset', 0); result.pop('buffer', None)
        result['content_sha256'] = hashlib.sha256(binary[start:start + result['byteLength']]).hexdigest()
        return result
    def accessor(index):
        result = copy.deepcopy(data['accessors'][index])
        if 'bufferView' in result: result['bufferView'] = view(result['bufferView'])
        if 'sparse' in result:
            for field in ('indices', 'values'):
                item = result['sparse'][field]; item['bufferView'] = view(item['bufferView'])
        return result
    def mesh(index):
        result = copy.deepcopy(data['meshes'][index])
        for primitive in result['primitives']:
            primitive['attributes'] = {key: accessor(value) for key, value in primitive['attributes'].items()}
            if 'indices' in primitive: primitive['indices'] = accessor(primitive['indices'])
            if 'material' in primitive: primitive['material'] = data['materials'][primitive['material']]
            if 'targets' in primitive:
                primitive['targets'] = [{key: accessor(value) for key, value in target.items()} for target in primitive['targets']]
        return result
    result = []
    for node in data['nodes']:
        item = copy.deepcopy(node)
        if 'mesh' in item: item['mesh'] = mesh(item['mesh'])
        result.append(hashlib.sha256(json.dumps(item, sort_keys=True, separators=(',', ':')).encode()).hexdigest())
    return result


def merge(base, base_binary, revision, revision_binary, expected_count=None):
    for data, binary in ((base, base_binary), (revision, revision_binary)):
        validate_supported(data, binary)
    updates = {}
    for node in revision['nodes']:
        if 'mesh' not in node: continue
        key = uid(node)
        if not key or key in updates or node.get('children'):
            raise ValueError(f'Duplicate, unnamed or non-leaf replacement: {key}')
        updates[key] = node
    base_ids = [uid(node) for node in base['nodes']]
    if len(base_ids) != len(set(base_ids)):
        raise ValueError('Duplicate source identities in baseline nodes')
    if not updates or set(updates) - set(base_ids):
        raise ValueError('Replacement source identities must already exist in baseline')
    if expected_count is not None and len(updates) != expected_count:
        raise ValueError(f'Expected {expected_count} replacements, got {len(updates)}')
    result = copy.deepcopy(base)
    for field in ('meshes', 'materials', 'accessors', 'bufferViews'): result[field] = []
    binary = bytearray(); cache = {}; material_cache = {}
    sources = ((base, base_binary), (revision, revision_binary))
    def resource(source, kind, index):
        key = (source, kind, index)
        if key in cache: return cache[key]
        data, content = sources[source]
        if not isinstance(index, int) or index < 0 or index >= len(data.get(kind, [])):
            raise ValueError(f'Invalid {kind} reference: {index}')
        item = copy.deepcopy(data[kind][index])
        if kind == 'bufferViews':
            start = item.get('byteOffset', 0)
            binary.extend(b'\0' * (-len(binary) % 4))
            item['buffer'] = 0; item['byteOffset'] = len(binary)
            binary.extend(content[start:start + item['byteLength']])
        elif kind == 'accessors':
            if 'bufferView' in item: item['bufferView'] = resource(source, 'bufferViews', item['bufferView'])
            if 'sparse' in item:
                for field in ('indices', 'values'):
                    sparse = item['sparse'][field]
                    sparse['bufferView'] = resource(source, 'bufferViews', sparse['bufferView'])
        elif kind == 'meshes':
            for primitive in item['primitives']:
                primitive['attributes'] = {key: resource(source, 'accessors', value) for key, value in primitive['attributes'].items()}
                if 'indices' in primitive: primitive['indices'] = resource(source, 'accessors', primitive['indices'])
                if 'material' in primitive: primitive['material'] = resource(source, 'materials', primitive['material'])
                if 'targets' in primitive:
                    primitive['targets'] = [{key: resource(source, 'accessors', value) for key, value in target.items()} for target in primitive['targets']]
        if kind == 'materials':
            canonical = json.dumps(item, sort_keys=True, separators=(',', ':'))
            if canonical in material_cache:
                cache[key] = material_cache[canonical]; return cache[key]
            material_cache[canonical] = len(result[kind])
        cache[key] = len(result[kind]); result[kind].append(item)
        return cache[key]
    changed = []
    for i, node in enumerate(base['nodes']):
        source = int(uid(node) in updates)
        replacement = copy.deepcopy(updates[uid(node)] if source else node)
        if source: changed.append(uid(node))
        if 'mesh' in replacement: replacement['mesh'] = resource(source, 'meshes', replacement['mesh'])
        result['nodes'][i] = replacement
    result['buffers'] = [{'byteLength': len(binary)}]
    before = semantic_nodes(base, base_binary); after = semantic_nodes(result, binary)
    revision_fingerprints = dict(zip([uid(n) for n in revision['nodes']], semantic_nodes(revision, revision_binary)))
    for index, key in enumerate(base_ids):
        expected = revision_fingerprints[key] if key in updates else before[index]
        if after[index] != expected: raise AssertionError(f'Changed geometry or node data for {key}')
    return result, bytes(binary), changed


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--base', type=Path, default=TARGET)
    parser.add_argument('--revision', type=Path, default=REVISION)
    parser.add_argument('--output', type=Path, default=TARGET)
    parser.add_argument('--audit', type=Path, default=GAME / 'verification/pitch-reuse-audit.json')
    args = parser.parse_args()
    base, bb = read(args.base); revision, rb = read(args.revision)
    result, binary, changed = merge(base, bb, revision, rb, expected_count=111)
    raw = encode(result, binary)
    # Byte-level fixed point catches accidental growth or unstable traversal.
    repeated, repeated_binary, _ = merge(result, binary, revision, rb, expected_count=111)
    if raw != encode(repeated, repeated_binary): raise AssertionError('Merge is not idempotent')
    audit = {'passed': True, 'input_sha256': hashlib.sha256(args.base.read_bytes()).hexdigest(),
             'output_sha256': hashlib.sha256(raw).hexdigest(), 'replaced_instances': changed,
             'unchanged_instance_count': len(base['nodes']) - len(changed),
             'geometry_equivalent_to_input_count': sum(a == b for a, b in zip(semantic_nodes(base, bb), semantic_nodes(result, binary))),
             'idempotent': True,
             'input_bytes': args.base.stat().st_size, 'output_bytes': len(raw),
             'resource_counts': {key: len(result[key]) for key in ('meshes', 'materials', 'accessors', 'bufferViews')},
             'proof': 'All retained node transforms/metadata, resolved mesh/accessor/material records and buffer-view bytes match their baseline fingerprints. Replacement nodes match the revision. A second merge is byte-identical.'}
    args.output.write_bytes(raw)
    args.audit.parent.mkdir(parents=True, exist_ok=True)
    args.audit.write_text(json.dumps(audit, indent=2) + '\n')
    print(f'Replaced {len(changed)} instances; preserved {audit["unchanged_instance_count"]}; compacted {audit["input_bytes"]} -> {len(raw)} bytes; repeat is byte-identical.')


if __name__ == '__main__': main()
