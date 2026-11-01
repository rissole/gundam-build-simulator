"""Acceptance audit for LG-01 steps; JSON evidence in output/audits/sequence.json.

python3 models/leg-lg01/src/verify_sequence.py
blender --background models/leg-lg01/output/leg-lg01.blend --python-exit-code 1 \
    --python models/leg-lg01/src/verify_sequence.py

Plain Python delegates to Blender to inspect the saved model, not a possibly stale
manifest. --manifest PATH is an explicitly labelled authoring/debug alternative.
The sweep uses eleven samples (0..1 at .1 increments), skips progress >= .85,
and shrinks each face by 5 mm. Thin bounds that collapse are empty after erosion.
Only actual mounts/insertion receivers and documented exact exception pairs are
exempt; same-step parts never excuse intersections with earlier unrelated parts.
"""
import argparse
from collections import Counter
import hashlib
import json
import math
from pathlib import Path
import re
import shutil
import subprocess
import sys
import time

sys.path.insert(0, str(Path(__file__).resolve().parent))
from sequence import ROOT, SCHEMA, make_sequence, scene_rows

SHRINK = .005
SAMPLES = tuple(n / 10 for n in range(11))
INSERTION = .85

# The first exception is conditional: freshly measured mesh evidence must prove
# that an aggregate box's empty space caused the finding. The second is a real
# source-geometry/one-translation limitation, explicitly NOT called mesh-clear.
CLEARANCE_EXCEPTIONS = [
    dict(id='nonconvex-envelope', pairs=[],
         reason='A single AABB fills open frames, shell notches and cable loops. '
                'Except only when fresh evaluated-mesh surface AND connected-solid '
                'containment checks find no contact at every offending sample. '
                'All applied pairs and samples are enumerated in the audit.'),
    dict(id='upper-plate-locator-lift',
         pairs=[['FA-401-L.upper-foot-plate.01','FA-103-L.001']],
         reason='The upper plate must lift along +Z, but its integral low skirt/locator '
                'geometry crosses a high cradle guard receiver at 60-80% of the 3 m descent '
                'in the Phase 6 round-1 scene. A tipped/multiple-segment placement or receiver '
                'revision is needed. The schema has only one straight translation and '
                'P5 cannot edit generators. This exact pair remains an acknowledged '
                'path limitation, not a hollow-box or collision-free claim.',
         progress=[.6,.7,.8]),
]


class MeshClearance:
    """Disambiguate coarse boxes conservatively using evaluated closed meshes.

    Disjoint surfaces alone are insufficient: a small solid could be completely
    buried in another. Test one vertex of each connected shell in both directions
    against each candidate closed shell. Treat uncertainty as a collision.
    """
    def __init__(self):
        import bpy
        from mathutils.bvhtree import BVHTree
        self.BVH = BVHTree
        self.objects = {o['instance_id']: o for o in bpy.context.scene.objects
                        if o.type == 'MESH' and o.get('instance_id')}
        self.graph = bpy.context.evaluated_depsgraph_get()
        self.data, self.translated = {}, {}

    def geometry(self, iid):
        if iid in self.data: return self.data[iid]
        obj = self.objects[iid].evaluated_get(self.graph)
        mesh = obj.to_mesh()
        try:
            points = [obj.matrix_world @ v.co for v in mesh.vertices]
            polygons = [tuple(p.vertices) for p in mesh.polygons]
            roots = list(range(len(points)))
            def root(i):
                while roots[i] != i:
                    roots[i] = roots[roots[i]]; i = roots[i]
                return i
            for edge in mesh.edges:
                a,b = edge.vertices; roots[root(a)] = root(b)
            from collections import defaultdict
            groups = defaultdict(list)
            for poly in polygons: groups[root(poly[0])].append(poly)
            shells = []
            for faces in groups.values():
                indices = set(i for face in faces for i in face)
                lo = tuple(min(points[i][a] for i in indices) for a in range(3))
                hi = tuple(max(points[i][a] for i in indices) for a in range(3))
                shells.append((lo,hi,points[min(indices)],self.BVH.FromPolygons(points,faces)))
            result = (points,polygons,self.BVH.FromPolygons(points,polygons),shells)
            self.data[iid] = result
            return result
        finally:
            obj.to_mesh_clear()

    @staticmethod
    def inside(point, shells):
        from mathutils import Vector
        direction = Vector((1,.37139,.12917)).normalized()
        for lo,hi,_,tree in shells:
            if not all(lo[a]+1e-6 < point[a] < hi[a]-1e-6 for a in range(3)): continue
            origin=point.copy(); crossings=0
            for _ in range(256):
                location,_,index,_=tree.ray_cast(origin,direction)
                if index is None: break
                crossings+=1; origin=location+direction*1e-6
            else:
                return True  # uncertain ray: do not waive
            if crossings % 2: return True
        return False

    def clear(self, moving, obstacle, delta):
        from mathutils import Vector
        vector=Vector(delta)
        a=self.geometry(moving); b=self.geometry(obstacle)
        key=(moving,tuple(delta))
        if key not in self.translated:
            self.translated[key]=self.BVH.FromPolygons([p+vector for p in a[0]],a[1])
        if self.translated[key].overlap(b[2]): return False
        if any(self.inside(shell[2]+vector,b[3]) for shell in a[3]): return False
        if any(self.inside(shell[2]-vector,a[3]) for shell in b[3]): return False
        return True


def erode(row):
    lo = tuple(x + SHRINK for x in row['bbox_min'])
    hi = tuple(x - SHRINK for x in row['bbox_max'])
    return (lo, hi) if all(a < b for a, b in zip(lo, hi)) else None


def intersect(a, b, delta):
    lo, hi = a
    other_lo, other_hi = b
    return all(lo[i]+delta[i] < other_hi[i] and hi[i]+delta[i] > other_lo[i] for i in range(3))


def audit(rows, document, check_scene_steps=False, mesh_clearance=None):
    errors = []
    by_id = {r['instance_id']: r for r in rows}
    if len(by_id) != len(rows): errors.append('Scene has duplicate instance IDs')
    expected, parents, retained = make_sequence(rows)
    if document.get('schema') != SCHEMA or document.get('units') != 'm':
        errors.append('Wrong schema/units')
    if document.get('placeholder') or 'placeholder' in document.get('metadata',{}):
        errors.append('Development placeholder is not a production sequence')
    if document.get('parts') != expected['parts']:
        errors.append('Parts metadata differs from scene/authoritative armor rules')
    steps = document.get('steps', [])
    if not 40 <= len(steps) <= 80: errors.append(f'Step count {len(steps)} outside 40–80')
    all_installs = [i for s in steps for i in s.get('installs',[])]
    counts = Counter(i['instance_id'] for i in all_installs)
    duplicates = sorted(i for i,n in counts.items() if n!=1)
    missing = sorted(set(by_id)-set(counts))
    unknown = sorted(set(counts)-set(by_id))
    if duplicates or missing or unknown: errors.append('Instances must appear exactly once, with no unknown IDs')
    indices, moves = {}, {}
    titles = []
    stop_words = {'the','and','with','to','of','in','on','for','two','three','four','six','a','m12','m24','m36'}
    for n,step in enumerate(steps,1):
        if step.get('index')!=n or step.get('id')!=f'S{n:03d}': errors.append(f'Invalid step index/ID at {n}')
        title=step.get('title','')
        tokens=set(re.findall(r'[a-z]+',title.lower()))-stop_words
        names=' '.join(by_id[i['instance_id']]['part_name'] for i in step.get('installs',[]) if i['instance_id'] in by_id)
        named=bool(tokens & (set(re.findall(r'[a-z]+',names.lower()))-stop_words))
        if not re.match(r'^(Fit|Bolt|Insert|Route|Close|Seat|Mount|Attach|Connect)\s+\S',title) or not named:
            titles.append(dict(step=n,title=title))
        if not step.get('installs'): errors.append(f'Empty step {n}')
        for install in step.get('installs',[]):
            iid=install['instance_id']; indices[iid]=n; moves[iid]=install
            direction=install.get('approach'); offset=install.get('offset')
            if (not isinstance(direction,list) or len(direction)!=3 or
                any(not isinstance(v,(int,float)) or isinstance(v,bool) or not math.isfinite(v) for v in direction) or
                abs(sum(v*v for v in direction)-1)>1e-6): errors.append(f'Invalid approach {iid}')
            if not isinstance(offset,(int,float)) or isinstance(offset,bool) or not math.isfinite(offset) or not .4<=offset<=3.0:
                errors.append(f'Offset outside .4–3 m: {iid}')
    if titles: errors.append('Titles must start with a verb and name fitted parts')
    if document.get('steps')!=expected['steps']: errors.append('Export differs from authoritative sequence.py')
    dependency_errors = []
    for iid,receivers in parents.items():
        for receiver in receivers:
            if receiver not in by_id or indices.get(receiver,math.inf)>indices.get(iid,-1):
                dependency_errors.append(dict(instance_id=iid,parent=receiver,step=indices.get(iid),parent_step=indices.get(receiver)))
    if dependency_errors: errors.append('Mount dependency order failed')
    active, done = set(), set()
    def visit(iid):
        if iid in active: raise ValueError(f'Mount dependency cycle at {iid}')
        if iid in done: return
        active.add(iid)
        for p in parents[iid]: visit(p)
        active.remove(iid); done.add(iid)
    for iid in parents: visit(iid)
    for iid,owner in retained.items():
        if indices.get(iid)!=indices.get(owner): errors.append(f'Fastener/sleeve separated from retained part: {iid}')
        elif iid in moves and owner in moves and any(moves[iid][k]!=moves[owner][k] for k in ('approach','offset')):
            errors.append(f'Fastener does not travel with retained part: {iid}')
    if check_scene_steps:
        wrong=[i for i,r in by_id.items() if r.get('step')!=indices.get(i)]
        if wrong: errors.append(f'{len(wrong)} scene step properties differ from JSON')
    exceptions = {}
    for rule in CLEARANCE_EXCEPTIONS:
        if not rule['reason'].strip(): errors.append('Exception without justification')
        for moving,obstacle in rule['pairs']:
            if moving not in by_id or obstacle not in by_id: errors.append(f'Unknown exception pair: {moving}, {obstacle}')
            if (moving,obstacle) in exceptions: errors.append('Duplicate exception pair')
            exceptions[moving,obstacle]=rule
    boxes={i:erode(row) for i,row in by_id.items()}
    def contacts(iid):
        result=set(parents[iid])
        # A retaining screw/washer shares its retained part's actual receiver.
        # Ordinary structural ancestors are intentionally NOT included.
        if iid in retained: result.update(contacts(retained[iid]))
        return result
    collisions, waived, earlier = [], [], []
    comparisons=0
    if not missing and not unknown and not duplicates and not errors:
        for step in steps:
            for install in step['installs']:
                iid=install['instance_id']; moving=boxes[iid]
                if moving is None: continue
                skip=contacts(iid)
                for obstacle in earlier:
                    if obstacle in skip or boxes[obstacle] is None: continue
                    hits=[]
                    for progress in SAMPLES:
                        if progress>=INSERTION: continue
                        delta=[v*install['offset']*(1-progress) for v in install['approach']]
                        comparisons+=1
                        if intersect(moving,boxes[obstacle],delta): hits.append(progress)
                    if hits:
                        record=dict(step=step['index'],moving=iid,obstacle=obstacle,progress=hits)
                        key=(iid,obstacle)
                        # Recheck changed meshes on every production run. A
                        # manifest-only check cannot establish this exception.
                        nonclear=[]
                        for progress in hits:
                            delta=[v*install['offset']*(1-progress) for v in install['approach']]
                            if mesh_clearance is None or not mesh_clearance.clear(iid,obstacle,delta):
                                nonclear.append(progress)
                        if not nonclear:
                            record['exception']='nonconvex-envelope'
                            record['evidence']='no intersecting surfaces or contained connected solids'
                            waived.append(record)
                        elif key in exceptions and set(nonclear)<=set(exceptions[key].get('progress',SAMPLES)):
                            record['exception']=exceptions[key]['id']
                            record['mesh_contact_progress']=nonclear
                            waived.append(record)
                        else:
                            record['mesh_contact_or_unverified_progress']=nonclear
                            collisions.append(record)
            earlier.extend(i['instance_id'] for i in step['installs'])
    if collisions: errors.append(f'{len(collisions)} unexcepted moving/placed AABB intersections')
    return dict(passed=not errors, errors=errors, scene_part_count=len(rows), step_count=len(steps),
                install_count=len(all_installs), missing=missing, unknown=unknown, duplicates=duplicates,
                title_failures=titles, dependency_errors=dependency_errors,
                mount_parents=parents, retained_parts=retained,
                clearance=dict(method='world AABB, straight translation; not mesh/tool/articulation clearance',
                               shrink_each_face_m=SHRINK,progress_samples=list(SAMPLES),
                               insertion_exempt_from=INSERTION,comparisons=comparisons,
                               eroded_empty_bounds=sum(b is None for b in boxes.values()),
                               strict_aabb_clear=not collisions and not waived,
                               exception_counts=dict(Counter(c['exception'] for c in waived)),
                               violations=collisions,documented_exceptions=CLEARANCE_EXCEPTIONS,
                               excepted_intersections=waived))


def main():
    start=time.monotonic()
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--steps',type=Path,default=ROOT/'viewer/build-steps.json')
    parser.add_argument('--report',type=Path,default=ROOT/'output/audits/sequence.json')
    parser.add_argument('--manifest',type=Path)
    parser.add_argument('--blend',type=Path,default=ROOT/'output/leg-lg01.blend')
    argv=sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else (sys.argv[1:] if 'bpy' not in sys.modules else [])
    args=parser.parse_args(argv)
    if not args.manifest and 'bpy' not in sys.modules:
        blender=shutil.which('blender')
        if not blender: parser.error('Blender is required to audit the saved scene; --manifest is only a snapshot check')
        result=subprocess.run([blender,'--background',str(args.blend),
                               '--python-exit-code','1','--python',str(Path(__file__).resolve()),'--',*argv])
        raise SystemExit(result.returncode)
    source=args.manifest or args.blend
    if args.manifest:
        rows=json.loads(args.manifest.read_text())['parts']
    else:
        import bpy
        if Path(bpy.data.filepath).resolve()!=source.resolve(): bpy.ops.wm.open_mainfile(filepath=str(source))
        rows=scene_rows()
    try:
        report=audit(rows,json.loads(args.steps.read_text()),not args.manifest,
                     MeshClearance() if not args.manifest else None)
    except (ValueError,KeyError,TypeError,IndexError) as exc:
        report=dict(passed=False,errors=[f'{type(exc).__name__}: {exc}'])
    report.update(source=str(source),source_sha256=hashlib.sha256(source.read_bytes()).hexdigest(),
                  scope='manifest snapshot' if args.manifest else 'full saved Blender scene',
                  steps_sha256=hashlib.sha256(args.steps.read_bytes()).hexdigest(),
                  sequence_source_sha256=hashlib.sha256(Path(__file__).with_name('sequence.py').read_bytes()).hexdigest(),
                  audit_source_sha256=hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
                  elapsed_seconds=round(time.monotonic()-start,3))
    args.report.parent.mkdir(parents=True,exist_ok=True)
    args.report.write_text(json.dumps(report,indent=2)+'\n')
    print(f'SEQUENCE AUDIT: {"PASS" if report["passed"] else "FAIL"}: '
          f'{report.get("scene_part_count",0)} parts, {report.get("step_count",0)} steps; {args.report}')
    for error in report['errors']: print('  '+error)
    if report.get('clearance',{}).get('exception_counts'):
        print('  Documented exceptions: '+json.dumps(report['clearance']['exception_counts'],sort_keys=True))
    if not report['passed']: raise SystemExit(1)


if __name__=='__main__':
    main()
