"""Authoritative LG-01 build sequence, in Blender metres.

Run with Blender (with or without the blend on its command line). Only the
package's output/leg-lg01.blend and viewer/build-steps.json are written. --steps
can select a different JSON destination. Plain Python --manifest PATH exports
steps without touching Blender. The audit imports make_sequence independently.

An install's approach points OUT from its assembled position. No scene transforms
are changed. All hardware IDs below retain the CSV instance identity, including
the foot-owned shin bolts. See MODELING_NOTES.md, Build sequence, for the single-
translation viewer's bench-assembly limitation and the conservative AABB scope.
"""
import argparse
from collections import defaultdict
import json
import math
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]
SCHEMA = 'leg-lg01-build-steps/1'
COORDINATES = ('Blender: X right (inner side of left leg), Y forward, Z up; '
               'the viewer converts to glTF Y-up (x, z, -y)')
X, Y, Z = (1, 0, 0), (0, 1, 0), (0, 0, 1)
NX, NY, NZ = (-1, 0, 0), (0, -1, 0), (0, 0, -1)


def unit(vector):
    length = math.sqrt(sum(v * v for v in vector))
    if not math.isfinite(length) or length == 0:
        raise ValueError(f'Invalid approach {vector}')
    return [v / length for v in vector]


def centre(row):
    return [(a + b) / 2 for a, b in zip(row['bbox_min'], row['bbox_max'])]


# Explicit hardware ownership ranges are populated below. Ranges refer only to
# stable numeric instance suffixes, never mesh creation order or nearest geometry.
FOOT_HARDWARE = [
    ('H-12030', 1, 2, 'FA-107-A.001'),
    ('H-12030', 5, 6, 'FA-107-A.002'),
    ('H-12030', 11, 12, 'FA-107-A.003'),
    ('H-12030', 15, 16, 'FA-107-A.004'),
    ('H-12030', 3, 4, 'FA-107-B.001'),
    ('H-12030', 13, 14, 'FA-107-B.002'),
    ('H-12030', 7, 8, 'FA-107-C.001'),
    ('H-12030', 9, 10, 'FA-107-C.002'),
    ('H-12030', 17, 18, 'FA-107-C.003'),
    ('H-12030', 19, 20, 'FA-107-C.004'),
    ('H-12030', 29, 29, 'FA-222-A.001'),
    ('H-12030', 30, 30, 'FA-222-A.002'),
    ('H-12030', 39, 39, 'FA-222-B.001'),
    ('H-12030', 40, 40, 'FA-222-B.002'),
    ('H-12030', 49, 49, 'FA-222-B.003'),
    ('H-12030', 50, 50, 'FA-222-B.004'),
    ('H-12030', 23, 24, 'FA-515-A.001'),
    ('H-12030', 33, 34, 'FA-515-B.001'),
    ('H-12030', 43, 44, 'FA-515-C.001'),
    ('H-12030', 27, 28, 'FA-521-A.001'),
    ('H-12030', 37, 38, 'FA-521-B.001'),
    ('H-12030', 47, 48, 'FA-521-C.001'),
    ('H-12030', 25, 26, 'FA-524-A.001'),
    ('H-12030', 35, 36, 'FA-524-C.001'),
    ('H-12030', 45, 46, 'FA-524-E.001'),
    ('H-12030', 21, 21, 'FA-528.001'),
    ('H-12030', 22, 22, 'FA-528.002'),
    ('H-12030', 31, 31, 'FA-528.003'),
    ('H-12030', 32, 32, 'FA-528.004'),
    ('H-12030', 41, 41, 'FA-528.005'),
    ('H-12030', 42, 42, 'FA-528.006'),
    ('H-12030', 51, 51, 'FA-607.001'),
    ('H-12030', 52, 52, 'FA-607.002'),
    ('H-12030', 53, 53, 'FA-607.003'),
    ('H-12030', 54, 54, 'FA-607.004'),
    ('H-12030', 55, 55, 'FA-607.005'),
    ('H-12030', 56, 56, 'FA-607.006'),
    ('H-12030', 57, 57, 'FA-607.007'),
    ('H-12030', 58, 58, 'FA-607.008'),
    ('H-12030', 59, 59, 'FA-607.009'),
    ('H-12030', 60, 60, 'FA-607.010'),
    ('H-12030', 61, 61, 'FA-607.011'),
    ('H-12030', 62, 62, 'FA-607.012'),
    ('H-12040', 5, 8, 'FA-513-A.001'),
    ('H-12040', 21, 24, 'FA-513-B.001'),
    ('H-12040', 37, 40, 'FA-513-C.001'),
    ('H-12040', 9, 12, 'FA-514-A.001'),
    ('H-12040', 25, 28, 'FA-514-B.001'),
    ('H-12040', 41, 44, 'FA-514-C.001'),
    ('H-12040', 13, 14, 'FA-517-A.001'),
    ('H-12040', 29, 30, 'FA-517-B.001'),
    ('H-12040', 45, 46, 'FA-517-C.001'),
    ('H-12040', 15, 16, 'FA-523-A.001'),
    ('H-12040', 31, 32, 'FA-523-B.001'),
    ('H-12040', 47, 48, 'FA-523-C.001'),
    ('H-12040', 1, 2, 'FA-525-A.001'),
    ('H-12040', 3, 4, 'FA-525-B.001'),
    ('H-12040', 17, 18, 'FA-525-C.001'),
    ('H-12040', 19, 20, 'FA-525-D.001'),
    ('H-12040', 33, 34, 'FA-525-E.001'),
    ('H-12040', 35, 36, 'FA-525-F.001'),
    ('H-12040', 49, 52, 'FA-600.001'),
    ('H-12040', 53, 56, 'FA-601.001'),
    ('H-12040', 57, 60, 'FA-603.001'),
    ('H-12050', 5, 8, 'FA-511-A.001'),
    ('H-12050', 13, 16, 'FA-511-B.001'),
    ('H-12050', 21, 24, 'FA-511-C.001'),
    ('H-12050', 1, 4, 'FA-512-A.001'),
    ('H-12050', 9, 12, 'FA-512-B.001'),
    ('H-12050', 17, 20, 'FA-512-C.001'),
    ('H-24060', 1, 2, 'FA-208.001'),
    ('H-24060', 5, 6, 'FA-208.002'),
    ('H-24060', 3, 4, 'FA-209.001'),
    ('H-24060', 7, 8, 'FA-209.002'),
    ('H-24060', 9, 10, 'FA-213.001'),
    ('H-24070', 13, 14, 'FA-220-A.001'),
    ('H-24070', 15, 16, 'FA-220-B.001'),
    ('H-24070', 17, 18, 'FA-220-C.001'),
    ('H-24070', 19, 20, 'FA-220-D.001'),
    ('H-24070', 21, 22, 'FA-220-E.001'),
    ('H-24070', 23, 24, 'FA-220-F.001'),
    ('H-24070', 1, 2, 'FA-230-A.001'),
    ('H-24070', 3, 4, 'FA-230-B.001'),
    ('H-24070', 5, 6, 'FA-230-C.001'),
    ('H-24070', 7, 8, 'FA-230-D.001'),
    ('H-24070', 9, 10, 'FA-230-E.001'),
    ('H-24070', 11, 12, 'FA-230-F.001'),
    ('H-24070', 25, 30, 'FA-300.001'),
    ('H-24070', 31, 34, 'FA-301.001'),
    ('H-36090', 1, 4, 'FA-201.001'),
    ('H-36140', 1, 4, 'FA-101.001'),
    ('H-36140', 5, 8, 'FA-102.001'),
    ('H-36140', 17, 20, 'FA-103-L.001'),
    ('H-36140', 9, 12, 'FA-105.001'),
    ('H-36140', 13, 16, 'FA-106.001'),
    ('W-12', 1, 2, 'FA-107-A.001'),
    ('W-12', 5, 6, 'FA-107-A.002'),
    ('W-12', 11, 12, 'FA-107-A.003'),
    ('W-12', 15, 16, 'FA-107-A.004'),
    ('W-12', 3, 4, 'FA-107-B.001'),
    ('W-12', 13, 14, 'FA-107-B.002'),
    ('W-12', 7, 8, 'FA-107-C.001'),
    ('W-12', 9, 10, 'FA-107-C.002'),
    ('W-12', 17, 18, 'FA-107-C.003'),
    ('W-12', 19, 20, 'FA-107-C.004'),
    ('W-12', 53, 53, 'FA-222-A.001'),
    ('W-12', 54, 54, 'FA-222-A.002'),
    ('W-12', 87, 87, 'FA-222-B.001'),
    ('W-12', 88, 88, 'FA-222-B.002'),
    ('W-12', 121, 121, 'FA-222-B.003'),
    ('W-12', 122, 122, 'FA-222-B.004'),
    ('W-12', 31, 34, 'FA-511-A.001'),
    ('W-12', 65, 68, 'FA-511-B.001'),
    ('W-12', 99, 102, 'FA-511-C.001'),
    ('W-12', 27, 30, 'FA-512-A.001'),
    ('W-12', 61, 64, 'FA-512-B.001'),
    ('W-12', 95, 98, 'FA-512-C.001'),
    ('W-12', 35, 38, 'FA-513-A.001'),
    ('W-12', 69, 72, 'FA-513-B.001'),
    ('W-12', 103, 106, 'FA-513-C.001'),
    ('W-12', 39, 42, 'FA-514-A.001'),
    ('W-12', 73, 76, 'FA-514-B.001'),
    ('W-12', 107, 110, 'FA-514-C.001'),
    ('W-12', 43, 44, 'FA-515-A.001'),
    ('W-12', 77, 78, 'FA-515-B.001'),
    ('W-12', 111, 112, 'FA-515-C.001'),
    ('W-12', 45, 46, 'FA-517-A.001'),
    ('W-12', 79, 80, 'FA-517-B.001'),
    ('W-12', 113, 114, 'FA-517-C.001'),
    ('W-12', 51, 52, 'FA-521-A.001'),
    ('W-12', 85, 86, 'FA-521-B.001'),
    ('W-12', 119, 120, 'FA-521-C.001'),
    ('W-12', 47, 48, 'FA-523-A.001'),
    ('W-12', 81, 82, 'FA-523-B.001'),
    ('W-12', 115, 116, 'FA-523-C.001'),
    ('W-12', 49, 50, 'FA-524-A.001'),
    ('W-12', 83, 84, 'FA-524-C.001'),
    ('W-12', 117, 118, 'FA-524-E.001'),
    ('W-12', 21, 22, 'FA-525-A.001'),
    ('W-12', 23, 24, 'FA-525-B.001'),
    ('W-12', 55, 56, 'FA-525-C.001'),
    ('W-12', 57, 58, 'FA-525-D.001'),
    ('W-12', 89, 90, 'FA-525-E.001'),
    ('W-12', 91, 92, 'FA-525-F.001'),
    ('W-12', 25, 25, 'FA-528.001'),
    ('W-12', 26, 26, 'FA-528.002'),
    ('W-12', 59, 59, 'FA-528.003'),
    ('W-12', 60, 60, 'FA-528.004'),
    ('W-12', 93, 93, 'FA-528.005'),
    ('W-12', 94, 94, 'FA-528.006'),
    ('W-12', 123, 126, 'FA-600.001'),
    ('W-12', 127, 130, 'FA-601.001'),
    ('W-12', 131, 134, 'FA-603.001'),
    ('W-12', 135, 135, 'FA-607.001'),
    ('W-12', 136, 136, 'FA-607.002'),
    ('W-12', 137, 137, 'FA-607.003'),
    ('W-12', 138, 138, 'FA-607.004'),
    ('W-12', 139, 139, 'FA-607.005'),
    ('W-12', 140, 140, 'FA-607.006'),
    ('W-12', 141, 141, 'FA-607.007'),
    ('W-12', 142, 142, 'FA-607.008'),
    ('W-12', 143, 143, 'FA-607.009'),
    ('W-12', 144, 144, 'FA-607.010'),
    ('W-12', 145, 145, 'FA-607.011'),
    ('W-12', 146, 146, 'FA-607.012'),
    ('W-24', 1, 2, 'FA-208.001'),
    ('W-24', 5, 6, 'FA-208.002'),
    ('W-24', 3, 4, 'FA-209.001'),
    ('W-24', 7, 8, 'FA-209.002'),
    ('W-24', 9, 10, 'FA-213.001'),
    ('W-24', 23, 24, 'FA-220-A.001'),
    ('W-24', 25, 26, 'FA-220-B.001'),
    ('W-24', 27, 28, 'FA-220-C.001'),
    ('W-24', 29, 30, 'FA-220-D.001'),
    ('W-24', 31, 32, 'FA-220-E.001'),
    ('W-24', 33, 34, 'FA-220-F.001'),
    ('W-24', 11, 12, 'FA-230-A.001'),
    ('W-24', 13, 14, 'FA-230-B.001'),
    ('W-24', 15, 16, 'FA-230-C.001'),
    ('W-24', 17, 18, 'FA-230-D.001'),
    ('W-24', 19, 20, 'FA-230-E.001'),
    ('W-24', 21, 22, 'FA-230-F.001'),
    ('W-24', 35, 40, 'FA-300.001'),
    ('W-24', 41, 44, 'FA-301.001'),
    ('W-36', 1, 4, 'FA-101.001'),
    ('W-36', 5, 8, 'FA-102.001'),
    ('W-36', 17, 20, 'FA-103-L.001'),
    ('W-36', 9, 12, 'FA-105.001'),
    ('W-36', 13, 16, 'FA-106.001'),
    ('W-36', 21, 24, 'FA-201.001'),
]


class Recipe:
    def __init__(self, rows):
        self.rows = {r['instance_id']: r for r in rows}
        if len(self.rows) != len(rows):
            raise ValueError('Duplicate scene instance IDs')
        self.families = defaultdict(list)
        for iid, r in sorted(self.rows.items()):
            self.families[r['part_id']].append(iid)
        self.steps, self.parents, self.retained, self.moves = [], {}, {}, {}

    def ids(self, *families):
        return [i for f in families for i in self.families[f]]

    def one(self, family, number=1):
        return self.families[family][number - 1]

    def mount(self, children, parents=()):
        if isinstance(children, str):
            children = [children]
        if isinstance(parents, str):
            parents = [parents]
        for iid in children:
            if iid in self.parents:
                raise ValueError(f'Duplicate mount rule: {iid}')
            self.parents[iid] = list(parents)

    def move(self, ids, direction, distance):
        if isinstance(ids, str):
            ids = [ids]
        for iid in ids:
            self.moves[iid] = (unit(direction), distance)

    def fit(self, title, ids, direction=Z, distance=1.2, section='foot', group=None):
        if not ids:
            raise ValueError(f'Empty step: {title}')
        for iid in ids:
            self.moves.setdefault(iid, (unit(direction), distance))
        self.steps.append(dict(title=title, section=section,
                               group=group or self.rows[ids[0]]['subassembly'], ids=ids))

    def retain(self, hardware, owner):
        if hardware in self.retained:
            raise ValueError(f'Duplicate fastener rule: {hardware}')
        self.retained[hardware] = owner
        self.mount(hardware, owner)

    def finish(self):
        # Recursive attachment also includes pad sleeves and armor captive collars.
        children = defaultdict(list)
        for iid, owner in self.retained.items():
            children[owner].append(iid)
        steps = []
        for index, spec in enumerate(self.steps, 1):
            installs = []
            def add(iid):
                direction, offset = self.moves[iid]
                installs.append(dict(instance_id=iid, approach=direction, offset=offset))
                for child in sorted(children[iid]):
                    self.moves[child] = (direction, offset)
                    add(child)
            for iid in spec['ids']:
                add(iid)
            steps.append(dict(id=f'S{index:03d}', index=index, title=spec['title'],
                              section=spec['section'], group=spec['group'], installs=installs))
        seen = [i['instance_id'] for s in steps for i in s['installs']]
        if len(seen) != len(set(seen)) or set(seen) != set(self.rows):
            raise ValueError(f'Coverage mismatch; missing={sorted(set(self.rows)-set(seen))}; '
                             f'duplicate count={len(seen)-len(set(seen))}')
        if set(self.parents) != set(self.rows):
            raise ValueError(f'Missing mount rules: {set(self.rows)-set(self.parents)}')
        armor = {i for i, r in self.rows.items()
                 if r['category'] in {'armor', 'accent'} or r['part_id'] in
                 {'LG-230', 'LG-330', 'LG-430', 'LG-460', 'LG-470'}}
        for iid, owner in self.retained.items():
            if owner in armor:
                armor.add(iid)
        parts = {i: dict(**{k: r[k] for k in ('part_id', 'part_name', 'subassembly', 'category')},
                         armor=i in armor) for i, r in sorted(self.rows.items())}
        return dict(schema=SCHEMA, units='m', coordinates=COORDINATES, parts=parts, steps=steps)


def make_sequence(rows):
    """Return (viewer document, mount parents, retained part map), fail closed."""
    r = Recipe(rows)
    ids, one = r.ids, r.one
    # Manufactured parts mounted together may have a parent in the same step.
    # Same-step membership alone is never used to exempt an earlier obstacle.
    rear = ids('FA-100-A', 'FA-100-B')
    fore = ids('FA-104-A', 'FA-104-B')
    r.mount(rear)
    for iid in rear:
        r.move(iid, NX if centre(r.rows[iid])[0] < 0 else X, .8)
    r.fit('Fit the two rear frame rails', rear)
    for family, rails in [('FA-107-A', rear), ('FA-107-B', rear), ('FA-107-C', fore)]:
        for iid in ids(family):
            side = 0 if centre(r.rows[iid])[0] < 0 else 1
            r.mount(iid, rails[side])
            r.move(iid, X if side == 0 else NX, .65)
    r.fit('Fit the six rear frame nut plates and keeper screws', ids('FA-107-A', 'FA-107-B'))
    for family, title in [('FA-101', 'rear crossmember'), ('FA-102', 'front crossmember')]:
        r.mount(ids(family), rear + ids('FA-107-A'))
        r.fit('Bolt the ' + title + ' into the rail seats', ids(family), Z, 1.0)
    r.mount(ids('FA-103-L'), rear + ids('FA-107-B'))
    r.fit('Bolt the fixed ankle cradle onto the rear rails', ids('FA-103-L'), Z, 1.8)
    r.mount(ids('FA-230-A', 'FA-230-B'), ids('FA-103-L'))
    r.fit('Fit the pitch limit stops to the cradle', ids('FA-230-A', 'FA-230-B'), Z, .8)
    r.mount(ids('FA-200'), ids('FA-103-L'))
    r.fit('Fit the pitch ring with its bushings between the cradle cheeks', ids('FA-200'), Z, 1.8)
    r.mount(ids('FA-230-C', 'FA-230-D'), ids('FA-200'))
    r.fit('Fit the roll limit stops inside the pitch ring', ids('FA-230-C', 'FA-230-D'), Z, 1.2)
    r.mount(ids('FA-201'), ids('FA-200'))
    r.fit('Fit the keyed roll adapter with its bushings inside the pitch ring', ids('FA-201'), Z, 2.2)
    for axis, families, parent, title in [
        (1, ('FA-205', 'FA-207'), 'FA-201', 'roll bushings and thrust washers'),
        (1, ('FA-203',), 'FA-201', 'short roll pins'),
        (1, ('FA-209',), 'FA-203', 'roll pin caps and bolts'),
        (0, ('FA-204', 'FA-206'), 'FA-200', 'pitch bushings and thrust washers'),
        (0, ('FA-202',), 'FA-200', 'short pitch pins'),
        (0, ('FA-208',), 'FA-202', 'pitch pin caps and bolts'),
    ]:
        for family in families:
            for n, iid in enumerate(ids(family)):
                parents = ids(parent) if len(ids(parent)) == 1 else [one(parent, n + 1)]
                if family in {'FA-203', 'FA-209'}: parents += ids('FA-200', 'FA-205', 'FA-207')
                if family in {'FA-202', 'FA-208'}: parents += ids('FA-103-L', 'FA-204', 'FA-206')
                r.mount(iid, parents)
                direction = [0, 0, 0]
                direction[axis] = -1 if centre(r.rows[iid])[axis] < 0 else 1
                r.move(iid, direction, 1.0 if 'cap' in title else .7)
        fitted = ids(*families)
        for bushing, carrier, distance in [('FA-204','FA-200',1.8),('FA-205','FA-201',2.2)]:
            if bushing in families:
                prepared = ids(bushing)
                next(s for s in r.steps if one(carrier) in s['ids'])['ids'] += prepared
                r.move(prepared,Z,distance)
                fitted = [i for i in fitted if i not in prepared]
                title = title.replace('bushings and ', '')
        r.fit(('Insert the ' if 'pins' in title else 'Fit the ') + title, fitted)

    # The forefoot frame is offered to its existing fixed hinge supports while
    # its constituent rail/beam seats are prepared in the same installation step.
    r.mount(fore, ids('FA-102'))
    r.mount(ids('FA-106'), fore + ids('FA-107-C', 'FA-102'))
    r.mount(ids('FA-105'), fore + ids('FA-107-C'))
    moving_fore = fore + ids('FA-107-C', 'FA-105', 'FA-106')
    r.move(moving_fore, Z, 1.3)
    r.fit('Fit the bolted forefoot frame into the fixed hinge supports', moving_fore)
    for family in ('FA-211', 'FA-212'):
        for iid in ids(family):
            r.mount(iid, ids('FA-106', 'FA-102'))
            r.move(iid, NX if centre(r.rows[iid])[0] < 0 else X, .7)
    r.fit('Fit the forefoot hinge bushings and thrust washers', ids('FA-211', 'FA-212'))
    r.mount(ids('FA-210'), ids('FA-106', 'FA-102', 'FA-211', 'FA-212'))
    r.fit('Insert the forefoot axle from the outboard side', ids('FA-210'), NX, 1.8)
    r.mount(ids('FA-213'), ids('FA-210', 'FA-102'))
    r.move(ids('FA-213'), X, .9)
    r.mount(ids('FA-230-E', 'FA-230-F'), ids('FA-102'))
    r.fit('Fit the forefoot axle cap and hinge limit stops', ids('FA-213', 'FA-230-E', 'FA-230-F'), Z, .9)

    clevis_parents = ['FA-103-L', 'FA-200', 'FA-200', 'FA-201', 'FA-102', 'FA-106']
    for letter, parent in zip('ABCDEF', clevis_parents):
        r.mount(ids('FA-220-' + letter), ids(parent))
    r.move(ids('FA-220-A', 'FA-220-B'), NX, 1.3)
    r.move(ids('FA-220-B'), Z, 2.0)
    r.move(ids('FA-220-C', 'FA-220-D'), NY, 1.3)
    r.move(ids('FA-220-E', 'FA-220-F'), Z, 1.1)
    # The forefoot base pin's outboard route crosses the pitch base clevis;
    # secure the forefoot drive before offering the outer pitch drive mounts.
    for a in (2,0,1):
        name = ('pitch', 'roll', 'forefoot')[a]
        variant = 'ABC'[a]
        pair = 'ABCDEF'[a*2:a*2+2]
        f = lambda number: one(f'FA-{number}-{variant}')
        eye = [one('FA-525-' + p) for p in pair]
        bush = ids('FA-526-A') if a == 0 else ids('FA-526-B')[(a-1)*2:a*2]
        rings = ids('FA-527-A') if a == 0 else ids('FA-527-B')[(a-1)*2:a*2]
        pins = ids('FA-221-A') if a == 0 else ids('FA-221-B')[(a-1)*2:a*2]
        keepers = ids('FA-222-A') if a == 0 else ids('FA-222-B')[(a-1)*2:a*2]
        clevis = [one('FA-220-' + p) for p in pair]
        gasket = [one('FA-529-' + p) for p in pair]  # front, rear
        collar = [one('FA-524-' + p) for p in pair]
        sensors = ids('FA-528')[a*2:a*2+2]
        connector = one('FA-530', a+1)
        axial = unit([b-a for a,b in zip(centre(r.rows[eye[0]]),centre(r.rows[eye[1]]))])
        # Roll eye axes follow the pitched actuator frame, not global X.
        pin_axis = NX if a == 0 else unit((.47, 0, .30)) if a == 1 else X
        rear_axis = [-v for v in axial]
        for n in range(2):
            r.mount(eye[n], [clevis[n]] if n == 0 else [f(518), clevis[n]])
            r.mount(bush[n], eye[n]); r.mount(rings[n], [eye[n], bush[n]])
            r.mount(pins[n], [eye[n], bush[n], clevis[n]])
            r.mount(keepers[n], [pins[n], clevis[n]])
            r.move([bush[n], rings[n]], pin_axis, .6 + n*.15)
            # Pitch's repaired keepers are outboard. The unmodified roll/toe
            # pins have their shoulder on -local-X and their keeper on +local-X.
            r.move(pins[n], pin_axis if a == 0 else [-v for v in pin_axis], 1.1 if a == 0 else .6)
            r.move(keepers[n], pin_axis, 1.8)
        r.mount(f(512), eye[0]); r.mount(gasket[1], f(512)); r.mount(f(510), [f(512), gasket[1]])
        r.mount(f(514), f(512)); r.mount(f(513), f(514))
        first = [eye[0], bush[0], rings[0], f(512), gasket[1], f(510), f(514), f(513)]
        for part, parents in [(522,[510,512]), (523,[522,512]), (516,[522]),
                              (515,[514,516]), (517,[516]), (518,[517])]:
            r.mount(f(part), [f(p) for p in parents])
        r.mount(collar, [f(516), f(522)])
        drive = [f(n) for n in (522,523,516,515,517,518)] + collar
        for part, parents in [(521,[510,518]), (519,[518,510]), (520,[518,519]), (511,[510,519,520])]:
            r.mount(f(part), [f(p) for p in parents])
        r.mount(gasket[0], f(510))
        front = [f(n) for n in (521,519,520,511)] + [gasket[0],eye[1],bush[1],rings[1]]
        r.mount(sensors, f(510)); r.mount(connector, f(512))
        # The viewer has one start-to-finish translation per part, so a bench
        # build followed by relocation cannot be shown. Offer the complete unit
        # coherently, retaining its real internal mount graph for the audit.
        prepared = first + drive + front + sensors + [connector]
        r.move(prepared, NX if a == 0 else NY if a == 1 else Z, 1.6)
        r.fit(f'Bolt the two {name} actuator clevises to their receivers', clevis)
        r.fit(f'Fit the prepared {name} screw actuator between its clevises', prepared)
        r.fit(f'Insert the {name} eye pins and bolt their keeper plates', pins+keepers)

    r.mount(ids('FA-300'), rear)
    r.fit('Bolt the rear sole carrier beneath the rear frame', ids('FA-300'), NZ, 1.0)
    r.mount(ids('FA-301'), fore)
    r.fit('Bolt the forefoot sole carrier beneath the moving frame', ids('FA-301'), NZ, 1.0)
    for family, title, carrier in [('FA-302','heel','FA-300'),('FA-303','midfoot','FA-300'),('FA-304','forefoot','FA-301')]:
        r.mount(ids(family), ids(carrier))
        r.fit('Fit the two ' + title + ' pads with compression sleeves and bolts', ids(family), NZ, 1.6)

    r.mount(ids('FA-600'), ids('FA-102'))
    r.fit('Bolt the junction box housing to the frame ears', ids('FA-600'), Z, 1.5)
    r.mount(ids('FA-603', 'FA-604'), ids('FA-600'))
    r.move(ids('FA-604'), NY, .6)
    r.fit('Fit the controller board and four box sockets', ids('FA-603','FA-604'), Z, .9)
    r.mount(ids('FA-605-L'), ids('FA-604', 'FA-201'))  # park upper plug; shin mates later
    for n, family in enumerate(('FA-606-A','FA-606-B','FA-606-C'), 1):
        r.mount(ids(family), [one('FA-604',n+1),one('FA-530',n)])
    harnesses = ids('FA-605-L','FA-606-A','FA-606-B','FA-606-C')
    for n, iid in enumerate(ids('FA-607')):
        harness = harnesses[0 if n<5 else 1 if n<8 else 2 if n<11 else 3]
        r.mount(iid, [harness])
    r.fit('Route the main lead and three actuator harnesses with cable clips', harnesses+ids('FA-607'), Z, 3.0)
    r.mount(ids('FA-602'), ids('FA-600')); r.mount(ids('FA-601'),ids('FA-600','FA-602'))
    r.fit('Close the junction box with its gasket and bolted lid', ids('FA-602','FA-601'), Z, 1.2)
    for family, title, owners, direction, distance in [
        ('FA-400','toe cap',['FA-104-A','FA-104-B'],Z,1.9),
        ('FA-402','heel cover',['FA-100-A','FA-100-B'],NY,1.8),
        ('FA-401-L','upper foot plate',['FA-100-A','FA-100-B'],Z,3.0),
        ('FA-403-L','inner ankle guard',['FA-103-L'],X,1.8),
        ('FA-404-L','outer ankle guard',['FA-103-L'],NX,1.8),
    ]:
        r.mount(ids(family), ids(*owners))
        r.fit('Fit the ' + title + ' with captive bolts', ids(family),direction,distance)

    # Lower-to-upper structural dependencies override the plan's prose listing.
    def leg(title, families, parents, direction=Z, distance=1.8):
        r.mount(ids(*families), ids(*parents))
        r.fit(title, ids(*families),direction,distance,'leg')
    leg('Fit the shin beam and four M36 flange bolts onto the ankle adapter', ['LG-100'],['FA-201'],Z,2.5)
    for family in ('LG-130','LG-135'):
        r.mount(ids(family), ids('LG-100'))
        for iid in ids(family):
            r.move(iid,NX if centre(r.rows[iid])[0]<0 else X,.8 if family=='LG-130' else 1.1)
    r.fit('Fit the knee journal bearings and thrust spacers',ids('LG-130','LG-135'),section='leg')
    r.mount(ids('LG-110'),ids('LG-100','LG-135'))
    r.mount(ids('LG-120'),ids('LG-110'))
    r.fit('Fit the bolted fork and spar unit over the shin knee boss',ids('LG-110','LG-120'),Z,2.8,'leg')
    leg('Insert the knee axle from the outboard side',['LG-140'],['LG-110','LG-100','LG-130','LG-135'],NX,1.8)
    leg('Fit the knee axle retaining cap and screws',['LG-150'],['LG-140'],X,2.0)
    r.mount(ids('LG-345'),ids('LG-120')); r.mount(ids('LG-346'),ids('LG-100'))
    for iid in ids('LG-345','LG-346'):
        r.move(iid,NX if centre(r.rows[iid])[0]<0 else X,1.5)
    r.fit('Fit the upper and lower knee cylinder mounts',ids('LG-345','LG-346'),NY,1.2,'leg')
    for n,iid in enumerate(ids('LG-340'),1):
        r.mount(iid,[one('LG-345',n),one('LG-346',n)])
        r.move(iid,NX if centre(r.rows[iid])[0]<0 else X,2.0)
    r.fit('Fit the two thigh-to-shin knee cylinders',ids('LG-340'),NY,1.7,'leg')
    for family, direction in [('LG-240',NX),('LG-242',X),('LG-244',NY)]:
        r.mount(ids(family),ids('LG-120')); r.move(ids(family),direction,1.5)
    r.fit('Bolt the three hip cylinder lug carriers to the spar',ids('LG-240','LG-242','LG-244'),section='leg')
    leg('Fit the leg service block and protected U-loop',['LG-250'],['LG-120'],Y,1.5)
    r.mount(ids('LG-255'),ids('LG-250','LG-120'))
    r.steps[-1]['ids'] += ids('LG-255'); r.move(ids('LG-255'),Y,1.5)
    leg('Fit the rear service channel cable guard',['LG-230'],['LG-120'],NY,2.0)
    leg('Fit the twin-engine thruster cradle',['LG-440'],['LG-100'],NY,2.0)
    # Rear cylinder bodies occupy the cradle's otherwise open rear approach.
    # Fit the cradle immediately after the knee cap, before cylinder brackets.
    cradle_step = r.steps.pop()
    before_mounts = next(n for n,s in enumerate(r.steps) if one('LG-345') in s['ids'])
    r.steps.insert(before_mounts, cradle_step)
    leg('Insert the two thruster units into the cradle rings',['LG-450'],['LG-440'],(0,-.978147601,-.207911691),2.5)
    for title,families,parents,direction,distance in [
        ('thigh front plate',['LG-200'],['LG-120'],Y,2.4),
        ('outer thigh plate',['LG-210'],['LG-120'],NX,2.6),
        ('inner thigh plate',['LG-215'],['LG-120'],X,2.6),
        ('two thigh rear covers',['LG-220','LG-225'],['LG-120'],NY,2.6),
        ('kneecap bracket',['LG-310'],['LG-100'],Y,1.6),
        ('kneecap shield',['LG-300'],['LG-310'],Y,1.6),
        ('outer knee guard',['LG-320'],['LG-110'],NX,1.8),
        ('inner knee guard',['LG-325'],['LG-110'],X,1.8),
        ('front shin plate',['LG-400'],['LG-100'],Y,2.3),
        ('outer calf shell',['LG-410'],['LG-100'],NX,2.7),
        ('inner calf shell',['LG-415'],['LG-100'],X,2.7),
        ('rear engine shroud',['LG-420'],['LG-440'],NY,3.0),
        ('central bridge panel',['LG-430'],['LG-420'],NY,3.0),
    ]:
        leg('Fit the ' + title,families,parents,direction,distance)
        if families[0] in {'LG-320','LG-325'}:
            n=1 if families[0]=='LG-320' else 2
            cover=one('LG-330',n)
            r.mount(cover,ids(families[0])); r.move(cover,direction,2.2)
            r.steps[-1]['ids'].append(cover)
            r.steps[-1]['title'] += ' and bearing cover'
    for family,title in [('LG-460','calf access hatches'),('LG-470','calf grab rails')]:
        for n,iid in enumerate(ids(family)):
            r.mount(iid,ids('LG-410' if n==0 else 'LG-415'))
            r.move(iid,NX if n==0 else X,3.0)
        r.fit('Fit the two '+title,ids(family),section='leg')

    # Retained-part rules, with one deliberate override: foot-owned shin bolts
    # retain LG-100, not FA-201 (which owns them in the standalone foot inventory).
    for prefix, first, last, owner in FOOT_HARDWARE:
        for n in range(first,last+1):
            iid=f'{prefix}.{n:03d}'
            r.retain(iid, one('LG-100') if r.rows[iid]['part_name'].endswith(' - Shin flange') else owner)
    for family in ('FA-305','FA-405','H-24120','H-12050-C'):
        for n,iid in enumerate(ids(family)):
            owners = ids('FA-302','FA-303','FA-304') if family in {'FA-305','H-24120'} else ids('FA-400','FA-401-L','FA-402','FA-403-L','FA-404-L')
            r.retain(iid,owners[n//4])
    for iid,row in r.rows.items():
        if row['part_id'] not in {'W-24','W-12','LG-H24100','H-12050'} or iid in r.retained: continue
        name=row['part_name']
        if name.endswith(' - Sole pad mounts'):
            r.retain(iid,ids('FA-302','FA-303','FA-304')[(int(iid.rsplit('.',1)[1])-1)//4])
        elif name.endswith(' - Armor captive bolts'):
            r.retain(iid,ids('FA-400','FA-401-L','FA-402','FA-403-L','FA-404-L')[(int(iid.rsplit('.',1)[1])-1)//4])
        elif 'lug carrier' in name:
            r.retain(iid,one(iid.split('.')[1].upper()))
        elif 'knee fork' in name:
            r.retain(iid,one('LG-110'))
        elif 'axle cap' in name:
            r.retain(iid,one('LG-150'))
        else:
            raise ValueError(f'Unmapped hardware: {iid}')
    return r.finish(), r.parents, r.retained


def scene_rows():
    """Read fresh evaluated world AABBs; keep acceptance independent of manifests."""
    import bpy
    from mathutils import Vector
    graph = bpy.context.evaluated_depsgraph_get()
    rows = []
    for obj in bpy.context.scene.objects:
        if obj.type != 'MESH' or not obj.get('instance_id'):
            continue
        evaluated = obj.evaluated_get(graph)
        points = [evaluated.matrix_world @ Vector(p) for p in evaluated.bound_box]
        row = {k:obj[k] for k in ('instance_id','part_id','part_name','subassembly','category')}
        row.update(bbox_min=[min(p[i] for p in points) for i in range(3)],
                   bbox_max=[max(p[i] for p in points) for i in range(3)], step=obj.get('step'))
        rows.append(row)
    return rows


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--steps',type=Path,default=ROOT/'viewer/build-steps.json')
    parser.add_argument('--manifest',type=Path)
    argv=sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else (sys.argv[1:] if 'bpy' not in sys.modules else [])
    args=parser.parse_args(argv)
    if args.manifest:
        rows=json.loads(args.manifest.read_text())['parts']
    else:
        import bpy
        source=ROOT/'output/leg-lg01.blend'
        if Path(bpy.data.filepath).resolve()!=source.resolve():
            bpy.ops.wm.open_mainfile(filepath=str(source))
        rows=scene_rows()
    document,_,_=make_sequence(rows)
    if not args.manifest:
        indices={i['instance_id']:s['index'] for s in document['steps'] for i in s['installs']}
        for obj in bpy.context.scene.objects:
            if obj.get('instance_id') in indices:
                obj['step']=indices[obj['instance_id']]
        bpy.ops.wm.save_as_mainfile(filepath=str(source))
    args.steps.parent.mkdir(parents=True,exist_ok=True)
    args.steps.write_text(json.dumps(document,indent=2)+'\n')
    print(f'SEQUENCE: {len(rows)} instances / {len(document["steps"])} steps → {args.steps}')


if __name__=='__main__':
    main()
