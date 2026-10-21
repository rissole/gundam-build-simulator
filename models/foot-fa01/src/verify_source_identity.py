"""Build in a different emission order and audit all existing source identities.

Blender --background --factory-startup --python models/foot-fa01/src/verify_source_identity.py
No model/manifest/GLB export is written. Compares the rebuilt source objects with
current manifest labels and paired hardware. The manifest intentionally retains
unselected geometry from older exports, so this identity audit does not compare
historical topology/positions or export geometry. The GLB compaction regression
separately proves exact preservation of every current imported mesh/transform.
"""
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import geometry as g
import build
import frame_parts
import actuator_parts
import finish_parts
from pitch_interfaces import rebuild_pitch
from source_connections import pitch_instance_ids


def main():
    expected = {part['instance_id']: part for part in json.loads((g.OUT / 'parts-manifest.json').read_text())['parts']}
    g.init()
    # These frame branches are independent. Electrical and armor retain their
    # real geometry dependencies. Actuator order deliberately differs from build.
    for fn in (frame_parts.build_stops, frame_parts.build_toe_joint,
               frame_parts.build_ankle, frame_parts.build_frames): fn()
    actuator_parts.build_one('F', (0,650,520), (0,1260,570), 110,365,425,32.5,220,40, (0,1400,1000))
    actuator_parts.build_one('R', (500,-450,850), (200,-450,1320), 110,380,440,32.5,230,40, (1600,-700,1000))
    actuator_parts.build_one('P', (-540,800,480), (-540,300,1000), 140,500,570,45,320,50, (-1600,-200,700))
    rebuild_pitch(actuator_parts.ACTUATORS['P'])
    for fn in (finish_parts.build_soles, finish_parts.build_electrical, finish_parts.build_armor): fn()
    build.inventory_audit()
    actual = {obj['instance_id']: obj for obj in g.PARTS}
    assert set(actual) == set(expected)
    for uid, obj in actual.items():
        old = expected[uid]
        for key in ('part_id', 'source_role', 'label', 'paired_instance_id'):
            assert old.get(key) == obj.get(key), (uid, key)
        assert len(obj.data.vertices) > 0 and len(obj.data.polygons) > 0, (uid, 'empty geometry')
    assert len(pitch_instance_ids()) == 109
    assert set(g.IDENTITIES.claimed) == set(g.IDENTITIES.identities)
    print('SOURCE_IDENTITY_AUDIT_PASSED: all 745 identities/roles, labels and hardware pairs survived reordered frame/actuator generation; no assets exported.', flush=True)


if __name__ == '__main__': main()
