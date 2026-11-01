"""Strict physical-instance audit against BOTH leg and foot CSVs.

Run inside Blender: --python verify_scene.py -- --expect structure|full.
No mutation, normal repair or automatic count exemption happens in this audit.
"""
import argparse
from collections import Counter
import csv
import hashlib
import importlib.util
import json
import math
from pathlib import Path
import sys
import bpy
import bmesh

SRC=Path(__file__).resolve().parent
sys.path.insert(0,str(SRC))
ROOT=SRC.parents[2]


def inventory():
    rows=[]
    for relative in ('design/legs/leg-components.csv',
                     'design/legs/foot-and-ankle/foot-components.csv'):
        path=ROOT/relative
        if path.exists():
            for row in csv.DictReader(path.open()):
                row['source_csv']=relative
                rows.append(row)
    return rows


def deferred(row):
    pid,name=row['part_id'],row['name']
    if row['source_csv'].endswith('/leg-components.csv'):
        return row['category']=='armor' or pid in {'LG-460','LG-470'} or (
            row['category']=='hardware' and 'armor' in name.lower())
    if importlib.util.find_spec('checks_foot'):
        from checks_foot import DEFERRED_ROWS
        return (pid,name) in DEFERRED_ROWS or pid in DEFERRED_ROWS
    # Fallback until the parallel foot module supplies its precise row set.
    return (row['subassembly'] in {'foot-armor','pads'} or row['category']=='sole' or
            pid=='FA-305' or 'Sole pad mounts' in name or 'Armor captive bolts' in name)


def audit_object(obj):
    failures=[]
    mesh=obj.data
    mesh.calc_loop_triangles()
    if mesh.users!=1: failures.append('mesh datablock is shared')
    if not mesh.vertices or not mesh.polygons: failures.append('empty mesh')
    if any(not math.isfinite(c) for v in mesh.vertices for c in (obj.matrix_world@v.co)):
        failures.append('non-finite world vertex')
    if not mesh.materials: failures.append('missing material slots')
    if any(p.material_index>=len(mesh.materials) or mesh.materials[p.material_index] is None
           for p in mesh.polygons):
        failures.append('face has no assigned material')
    if obj.modifiers: failures.append('unapplied modifier: source audit would miss evaluated geometry')
    bm=bmesh.new(); bm.from_mesh(mesh); bm.normal_update()
    bm.faces.ensure_lookup_table()
    if any(not e.is_manifold for e in bm.edges): failures.append('non-manifold/open edges')
    before=[f.normal.copy() for f in bm.faces]
    bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces))
    flipped=sum(a.dot(f.normal)<-.5 for a,f in zip(before,bm.faces))
    if flipped: failures.append(f'{flipped} faces disagree with outward recalculated normals')
    # Check each connected closed shell; total signed volume could hide inversion.
    unseen=set(bm.faces); volumes=[]; thickness=[]
    while unseen:
        start=unseen.pop(); component={start}; pending=[start]
        while pending:
            for edge in pending.pop().edges:
                for face in edge.link_faces:
                    if face in unseen:
                        unseen.remove(face); component.add(face); pending.append(face)
        verts={v for f in component for v in f.verts}
        extent=[max(v.co[i] for v in verts)-min(v.co[i] for v in verts) for i in range(3)]
        thickness.append(min(extent))
        volume=0.
        for face in component:
            a=face.verts[0].co
            for j in range(1,len(face.verts)-1):
                volume+=a.dot(face.verts[j].co.cross(face.verts[j+1].co))/6
        volumes.append(volume*obj.matrix_world.to_3x3().determinant())
    bm.free()
    if any(v<=1e-14 for v in volumes): failures.append('non-positive volume shell')
    if any(t<=1e-7 for t in thickness): failures.append('zero-thickness shell')
    return {'instance_id':obj.get('instance_id'),'part_id':obj.get('part_id'),
            'part_name':obj.get('part_name'),'vertices':len(mesh.vertices),
            'triangles':len(mesh.loop_triangles),
            'shells':len(volumes),'volume_m3':sum(volumes),
            'min_shell_bbox_thickness_m':min(thickness,default=0),
            'unused_empty_material_slots':sum(m is None for m in mesh.materials),
            'flipped_faces':flipped,'passed':not failures,'failures':failures}


def run(expect='structure',only_leg=False):
    rows=inventory()
    if only_leg: rows=[r for r in rows if r['source_csv'].endswith('/leg-components.csv')]
    objects=[o for o in bpy.context.scene.objects if o.type=='MESH' and o.get('part_id')]
    if only_leg:
        keys={(r['part_id'],r['name']) for r in rows}
        objects=[o for o in objects if (o.get('part_id'),o.get('part_name')) in keys]
    failures=[]
    if not only_leg:
        unregistered=[o.name for o in bpy.context.scene.objects if o.type=='MESH' and not o.get('part_id')
                      and not any(c.name=='presentation' for c in o.users_collection)]
        if unregistered: failures.append({'unregistered_meshes':unregistered})
    counts=Counter((o.get('part_id'),o.get('part_name')) for o in objects)
    instances=Counter(o.get('instance_id') for o in objects)
    duplicates=[k for k,v in instances.items() if not k or v!=1]
    if duplicates: failures.append({'duplicate_or_missing_instance_ids':duplicates})
    row_results=[]
    for r in rows:
        key=(r['part_id'],r['name']); target=int(r['qty_per_leg']); n=counts.pop(key,0)
        is_deferred=expect=='structure' and deferred(r)
        # Deferred rows may be absent or fully implemented, never partial/duplicated.
        passed=n==target or (is_deferred and n==0)
        record={'part_id':key[0],'part_name':key[1],'expected':target,'actual':n,
                'deferred':is_deferred,'passed':passed,
                'instances':[o.get('instance_id') for o in objects
                             if (o.get('part_id'),o.get('part_name'))==key]}
        row_results.append(record)
        if not passed: failures.append(record)
    if counts: failures.append({'unexpected_rows':[list(k)+[v] for k,v in counts.items()]})
    results=[]
    expected={(r['part_id'],r['name']):r for r in rows}
    for obj in objects:
        result=audit_object(obj)
        row=expected.get((obj.get('part_id'),obj.get('part_name')))
        if row:
            for field in ('subassembly','category','finish'):
                if obj.get(field)!=row[field]:
                    result['failures'].append('incorrect '+field)
        result['passed']=not result['failures']
        results.append(result)
        if not result['passed']: failures.append(result)
    leg_keys={(r['part_id'],r['name']) for r in inventory()
              if r['source_csv'].endswith('/leg-components.csv') and not deferred(r)}
    leg_triangles=sum(r['triangles'] for r in results if (r['part_id'],r['part_name']) in leg_keys)
    if leg_triangles>600000:
        failures.append({'leg_structure_triangle_budget':leg_triangles,'limit':600000})
    return {'audit':'physical-scene','expect':expect,'scope':'leg-only' if only_leg else 'leg-and-foot',
            'triangles':sum(r['triangles'] for r in results),'leg_structure_triangles':leg_triangles,
            'leg_structure_triangle_limit':600000,
            'blend':bpy.data.filepath,'objects':len(objects),'rows':row_results,
            'instances':results,'passed':not failures,'failures':failures}


def main():
    parser=argparse.ArgumentParser()
    parser.add_argument('--expect',choices=('structure','full'),default='structure')
    parser.add_argument('--only-leg',action='store_true',help='Explicit isolated diagnosis; default audits BOTH CSVs')
    parser.add_argument('--report',type=Path,help='Preserve a scene-specific report during parallel builds')
    args=parser.parse_args(sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else [])
    report=run(args.expect,args.only_leg)
    if bpy.data.filepath:
        report['blend_sha256']=hashlib.sha256(Path(bpy.data.filepath).read_bytes()).hexdigest()
    path=args.report or SRC.parent/'output/audits'/('scene-'+args.expect+('-leg' if args.only_leg else '')+'.json')
    path.parent.mkdir(parents=True,exist_ok=True)
    path.write_text(json.dumps(report,indent=2)+'\n')
    print(f"SCENE AUDIT: {'PASS' if report['passed'] else 'FAIL'}; {report['objects']} objects; "
          f"{len(report['failures'])} failures; {path}")
    for failure in report['failures'][:12]: print(failure)
    if not report['passed']: raise SystemExit(1)


if __name__=='__main__': main()
