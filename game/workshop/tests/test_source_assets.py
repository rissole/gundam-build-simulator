"""Source identity, recipe order independence and compact scoped GLB regressions.

Run: python3 -B -m unittest discover -s game/workshop/tests -p test_source_assets.py
"""
import copy
import importlib.util
import json
import random
import runpy
import struct
import sys
import unittest
from pathlib import Path
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(ROOT / 'models/foot-fa01/src'))
from source_identity import SourceRegistry
from source_connections import pitch_pairs, pitch_instance_ids

spec = importlib.util.spec_from_file_location('merge_pitch_meshes', ROOT / 'game/workshop/tools/merge_pitch_meshes.py')
merge_tool = importlib.util.module_from_spec(spec); spec.loader.exec_module(merge_tool)


class StableSourceTests(unittest.TestCase):
    def assert_authored_equal(self, authored, current, path="asset"):
        """Keep authored structure exact; libm can differ at float roundoff."""
        if isinstance(authored, dict) and isinstance(current, dict):
            self.assertEqual(authored.keys(), current.keys(), path)
            for key in authored:
                self.assert_authored_equal(authored[key], current[key], path + "/" + key)
        elif isinstance(authored, list) and isinstance(current, list):
            self.assertEqual(len(authored), len(current), path)
            for index, (value, expected) in enumerate(zip(authored, current)):
                self.assert_authored_equal(value, expected, path + "/" + str(index))
        elif isinstance(authored, float) and isinstance(current, float):
            self.assertAlmostEqual(authored, current, delta=1e-12,
                                   msg=f"{path}: authored {authored!r}, current {current!r}")
        else:
            self.assertEqual(authored, current, path)

    def test_all_existing_ids_and_pairing_are_registered(self):
        registry = SourceRegistry()
        parts = json.loads((ROOT / 'models/foot-fa01/output/parts-manifest.json').read_text())['parts']
        self.assertEqual(len(parts), 745)
        self.assertEqual(set(registry.identities.values()), {p['instance_id'] for p in parts})
        by_id = {p['instance_id']: p for p in parts}
        for part in parts:
            self.assertEqual(registry.resolve(part['source_role'], part['part_id']), part['instance_id'])
            if 'paired_instance_id' in part:
                paired = by_id[part['paired_instance_id']]
                self.assertEqual(paired['paired_instance_id'], part['instance_id'])
                self.assertEqual(paired['hardware_use'], part['hardware_use'])
        self.assertEqual(len(pitch_instance_ids()), 109)

    def test_reordering_and_deliberate_addition_never_renumbers(self):
        original = SourceRegistry().identities
        expanded = dict(original, **{'FA-510/Test_addition': 'FA-510__004'})
        registry = SourceRegistry(expanded)
        roles = list(expanded); random.Random(147).shuffle(roles)
        emitted = {role: registry.claim(role, expanded[role].split('__')[0]) for role in roles}
        self.assertEqual({role: emitted[role] for role in original}, original)

    def test_unknown_duplicate_wrong_family_and_reused_id_fail(self):
        registry = SourceRegistry({'frame/rear': 'FA-100__001'})
        with self.assertRaisesRegex(ValueError, 'Unknown source role'): registry.claim('frame/new', 'FA-100')
        with self.assertRaisesRegex(ValueError, 'not FA-200'): registry.claim('frame/rear', 'FA-200')
        registry.claim('frame/rear', 'FA-100')
        with self.assertRaisesRegex(ValueError, 'Duplicate source role'): registry.claim('frame/rear', 'FA-100')
        with self.assertRaisesRegex(ValueError, 'Duplicate source IDs'):
            SourceRegistry({'a': 'FA-100__001', 'b': 'FA-100__001'})

    def test_named_hardware_sites_match_explicit_manifest_pairs(self):
        manifest = json.loads((ROOT / 'models/foot-fa01/output/parts-manifest.json').read_text())['parts']
        by_id = {p['instance_id']: p for p in reversed(manifest)}
        for connection in ('motor', 'gearbox', 'cradle', 'ring', 'base-keeper', 'rod-keeper'):
            for screw, washer in pitch_pairs(connection):
                self.assertEqual(by_id[screw]['paired_instance_id'], washer)
        normal = pitch_pairs('motor')
        reversed_pairs = pitch_pairs('motor', ('y-negative', 'x-negative', 'y-positive', 'x-positive'))
        self.assertEqual(reversed_pairs, list(reversed(normal)))
        with self.assertRaises(ValueError): pitch_pairs('motor', ('unknown-site',))
        with self.assertRaises(ValueError): pitch_pairs('motor', ('x-positive', 'x-positive'))

    def test_recipe_survives_reordered_manifest_and_nonadjacent_washers(self):
        manifest_path = ROOT / 'models/foot-fa01/output/parts-manifest.json'
        manifest = json.loads(manifest_path.read_text())
        manifest['parts'].reverse()
        read_text, writes = Path.read_text, {}
        def read(path, *args, **kwargs):
            return json.dumps(manifest) if path == manifest_path else read_text(path, *args, **kwargs)
        def write(path, text, *args, **kwargs): writes[path.name] = json.loads(text); return len(text)
        with patch.object(Path, 'read_text', read), patch.object(Path, 'write_text', write):
            runpy.run_path(str(ROOT / 'game/workshop/tools/author_pitch_actuator.py'))
        for name, authored in writes.items():
            current = json.loads((ROOT / 'game/workshop/assets' / name).read_text())
            if name == 'pitch-workshop.json':
                authored['parts'].sort(key=lambda p: p['instance_id']); current['parts'].sort(key=lambda p: p['instance_id'])
            self.assert_authored_equal(authored, current, name)


def fixture():
    binary = struct.pack('<9f', 1, 2, 3, 4, 5, 6, 999, 999, 999)
    data = {'asset': {'version': '2.0'}, 'scene': 0, 'scenes': [{'nodes': [0, 1]}],
            'nodes': [{'name': 'FA-100__001__retained', 'mesh': 0, 'translation': [2, 3, 4]},
                      {'name': 'FA-510__001__replaced', 'mesh': 1}],
            'materials': [{'name': 'Steel'}, {'name': 'obsolete'}],
            'meshes': [{'primitives': [{'attributes': {'POSITION': i}, 'material': 0}]} for i in range(3)],
            'accessors': [{'bufferView': i, 'componentType': 5126, 'count': 1, 'type': 'VEC3'} for i in range(3)],
            'bufferViews': [{'buffer': 0, 'byteOffset': i * 12, 'byteLength': 12} for i in range(3)],
            'buffers': [{'byteLength': len(binary)}]}
    revision = copy.deepcopy(data)
    revision['nodes'] = [dict(data['nodes'][1], mesh=0)]
    revision['scenes'] = [{'nodes': [0]}]
    return data, binary, revision, struct.pack('<9f', 7, 8, 9, 0, 0, 0, 0, 0, 0)


class CompactMergeTests(unittest.TestCase):
    def test_compaction_preserves_retained_transforms_bytes_and_material(self):
        base, binary, revision, rb = fixture()
        before = copy.deepcopy(base)
        merged, mb, changed = merge_tool.merge(base, binary, revision, rb)
        self.assertEqual(base, before)
        self.assertEqual(changed, ['FA-510__001'])
        self.assertEqual(len(merged['meshes']), 2); self.assertEqual(len(merged['materials']), 1)
        self.assertEqual(len(merged['accessors']), 2); self.assertEqual(len(merged['bufferViews']), 2)
        self.assertEqual(len(mb), 24)
        self.assertEqual(merge_tool.semantic_nodes(base, binary)[0], merge_tool.semantic_nodes(merged, mb)[0])
        self.assertEqual(merge_tool.semantic_nodes(revision, rb)[0], merge_tool.semantic_nodes(merged, mb)[1])

    def test_many_repeated_merges_are_byte_identical(self):
        base, binary, revision, rb = fixture()
        merged, mb, _ = merge_tool.merge(base, binary, revision, rb)
        encoded = merge_tool.encode(merged, mb)
        for _ in range(8):
            merged, mb, _ = merge_tool.merge(merged, mb, revision, rb)
            self.assertEqual(merge_tool.encode(merged, mb), encoded)

    def test_shared_interleaved_view_sparse_and_morph_accessors_survive(self):
        base, binary, revision, rb = fixture()
        base['bufferViews'][0]['byteStride'] = 12
        base['accessors'][0]['sparse'] = {'count': 1, 'indices': {'bufferView': 1, 'componentType': 5121}, 'values': {'bufferView': 2}}
        base['meshes'][0]['primitives'][0]['targets'] = [{'POSITION': 2}]
        base['meshes'][0]['primitives'][0]['attributes']['NORMAL'] = 0
        merged, mb, _ = merge_tool.merge(base, binary, revision, rb)
        self.assertEqual(merge_tool.semantic_nodes(base, binary)[0], merge_tool.semantic_nodes(merged, mb)[0])
        attributes = merged['meshes'][0]['primitives'][0]['attributes']
        self.assertEqual(attributes['POSITION'], attributes['NORMAL'])

    def test_duplicate_unknown_and_nonleaf_replacements_fail(self):
        base, binary, revision, rb = fixture()
        revision['nodes'].append(copy.deepcopy(revision['nodes'][0]))
        with self.assertRaisesRegex(ValueError, 'Duplicate'): merge_tool.merge(base, binary, revision, rb)
        revision['nodes'] = [{'name': 'FA-999__001', 'mesh': 0}]
        with self.assertRaisesRegex(ValueError, 'already exist'): merge_tool.merge(base, binary, revision, rb)
        revision['nodes'] = [dict(base['nodes'][1], children=[0])]
        with self.assertRaisesRegex(ValueError, 'non-leaf'): merge_tool.merge(base, binary, revision, rb)

    def test_unsupported_buffer_references_fail_closed(self):
        for field, value in [('animations', [{}]), ('skins', [{}]), ('images', [{}]), ('extensionsUsed', ['CUSTOM_geometry'])]:
            base, binary, revision, rb = fixture(); base[field] = value
            with self.assertRaisesRegex(ValueError, 'supports rigid'): merge_tool.merge(base, binary, revision, rb)
        base, binary, revision, rb = fixture(); base['meshes'][0]['extensions'] = {'CUSTOM': {'bufferView': 0}}
        with self.assertRaisesRegex(ValueError, 'opaque'): merge_tool.merge(base, binary, revision, rb)
        base, binary, revision, rb = fixture(); base['bufferViews'][0]['byteLength'] = 1000
        with self.assertRaisesRegex(ValueError, 'outside'): merge_tool.merge(base, binary, revision, rb)

    def test_current_full_game_asset_equivalence_and_fixed_point(self):
        base, binary = merge_tool.read(merge_tool.TARGET)
        # A fresh checkout does not contain the ignored Blender pitch export.
        # Use the exact current scoped nodes for the compaction regression; the
        # synthetic cases above exercise genuinely changed replacement geometry.
        selected = pitch_instance_ids() | {'FA-103__001', 'FA-200__001'}
        revision = copy.deepcopy(base)
        revision['nodes'] = [copy.deepcopy(node) for node in base['nodes'] if merge_tool.uid(node) in selected]
        revision['scenes'] = [{'nodes': list(range(len(revision['nodes'])))}]
        rb = binary
        merged, mb, changed = merge_tool.merge(base, binary, revision, rb, expected_count=111)
        self.assertEqual(len(changed), 111); self.assertEqual(len(merged['nodes']), 745)
        self.assertEqual(len(merged['meshes']), 745)
        before = merge_tool.semantic_nodes(base, binary); after = merge_tool.semantic_nodes(merged, mb)
        self.assertEqual(before, after, 'All 745 node geometry/material/transform fingerprints must remain equal')
        repeated, repeated_binary, _ = merge_tool.merge(merged, mb, revision, rb, expected_count=111)
        self.assertEqual(merge_tool.encode(merged, mb), merge_tool.encode(repeated, repeated_binary))
        self.assertLessEqual(len(merge_tool.encode(merged, mb)), merge_tool.TARGET.stat().st_size)


if __name__ == '__main__': unittest.main()
