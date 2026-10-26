#!/usr/bin/env python3
"""Freeze successful C5 runtime measurements and explicitly labelled design reservations."""
import hashlib
import json
from pathlib import Path
import subprocess

ROOT = Path(__file__).resolve().parents[4]
OUT = ROOT / 'design/game/gantry-v2'
SCRATCH = ROOT / 'game/workshop/verification/c5'

def git(*args):
    return subprocess.check_output(['git', *args], cwd=ROOT, text=True).strip()

def union(rows):
    return {'min': [min(r['min'][i] for r in rows) for i in range(3)],
            'max': [max(r['max'][i] for r in rows) for i in range(3)]}

def main():
    raw = json.loads((SCRATCH / 'runtime.json').read_text())
    log = (SCRATCH / 'probe.log').read_text()
    assert 'SCRIPT ERROR' not in log and 'ERROR:' not in log, 'Probe errors invalidate measurements'
    assert len(raw['runs']) == 16 and raw['runs'][-1]['stage'] == 'complete'
    assert len(raw['crane']) == 31
    assert len([r for r in raw['robot'] if r['stage'] == 'complete']) == 23
    branch = git('rev-parse', 'crane-operator-view')
    files = ['game/workshop/scripts/service_crane.gd', 'game/workshop/assets/workshop-layout.json']
    branch_files = {}
    for path, scratch in zip(files, ['branch_crane.gd', 'branch-layout.json']):
        data = subprocess.check_output(['git', 'show', f'crane-operator-view:{path}'], cwd=ROOT)
        assert data == (SCRATCH / scratch).read_bytes(), 'Branch changed since probe; remeasure'
        branch_files[path] = hashlib.sha256(data).hexdigest()
    layout = json.loads((ROOT / files[1]).read_text())
    now = raw['runs'][-1]['time_utc']
    for c in raw['crane']:
        c['branch_commit'] = branch
        c['payload_source_stage'] = 'left_leg_build' if c['id'] == 'pelvis' else 'pelvis'
        if c['id'] in ['core','core_store']:
            for pose in c['carry']:
                for i,part in enumerate(pose['rig_parts']):part['kind']='bar' if i==0 else 'line'
            c['rig_classification_source']='core_guide.gd:209-227; first record beam, remaining records lines with both connectors attached'
        c['highest_spreader_hook_y'] = max(part['bounds']['max'][1] for pose in c['carry'] for part in pose['rig_parts'] if part['kind'] in ['bar','spreader','equalizer','hook'])
        c['highest_cable_y'] = max(part['bounds']['max'][1] for pose in c['carry'] for part in pose['rig_parts'] if part['kind'] in ['line','hoist','suspension','tagline'])
        c['highest_hook_allowance_y'] = 22.85
        c['hook_source'] = 'branch service_crane.gd:120-123 top allowance; not a measured hook collider'
        c['mast_note'] = 'Highest line reaches authored overhead_y=23.0: intentional trolley attachment, not an under-trolley clearance.'
    reservations = []
    def reserve(id, box, source, kind, margin=.1, **extra):
        reservations.append(dict(id=id, **box, source=source, stage=extra.pop('stage', 'all'),
                                 time_utc=now, kind=kind, margin=margin, **extra))
    def box(lo, hi): return dict(min=lo, max=hi)
    reserve('leg_corridor', box([10.5,0,20.5],[15.5,7.7,30.6]),
            'layout workshop.rail.corridor; vertical top is existing cradle top per concept', 'invariant')
    reserve('upper_service', box([11.4,11.2,27.2],[14.6,23,35.3]),
            'final-assembly-plan.md:406-415; upper floor band starts at 11.2', 'invariant')
    reserve('aft_well', box([11.4,0,31.7],[14.6,23,35.3]),
            'final-assembly-plan.md:408-410; open vertically', 'invariant')
    reserve('rear_crane_well', box([22.8,0,31.7],[25.2,23,34.7]),
            'layout workshop.crane.rear_well_bounds', 'invariant')
    for side, spec in layout['workshop']['elevators'].items():
        x,_,z=spec['origin']
        # Shaft excludes landing portals; actual car travel is the collision volume.
        car = [r for r in raw['equipment'] if r['id'].startswith(f'lift/{side}/') and 'height' in r]
        for r in raw['equipment']:
            if r['id'].startswith(f'lift/{side}/piece/'):
                q=box(r['min'][:],r['max'][:])
                if r['moving_with_car']:q['min'][1]-=spec['levels'][-1]-spec['levels'][0]
                reserve(r['id'], q,r['source']+'; vertical sweep' if r['moving_with_car'] else r['source'],'lift',.02)
        for door in [-1,1]:
            # Open portal: no new steel in the body-height boarding space.
            for level in spec['levels'][1:]:
                edge=x+door*1.3
                reserve(f'door/{side}/{door}/{level}', box([min(edge,edge+door*.02),level,28.5],
                        [max(edge,edge+door*.02),level+2.2,30]), 'layout elevators + work_access_lift side doors', 'portal', 0)
    for side in ['left','right']:
        rows=[r for r in raw['equipment'] if r['id'].startswith(f'rail/{side}/')]
        for i,(a,b) in enumerate(zip(rows,rows[1:])):
            q=union([a,b]);q={k:[v+(-.03 if k=='min' else .03) for v in vs] for k,vs in q.items()}
            reserve(f'rail/{side}/{i:02}',q,'probe adjacent 0.05 path samples; 30 mm curvature bound','rail',.1,stage=f'{side}_leg_dock')
    pack=[r for r in raw['equipment'] if r['id'].startswith('backpack/')]
    for i,(a,b) in enumerate(zip(pack,pack[1:])):
        q=union([a,b]);q={k:[v+(-.01 if k=='min' else .01) for v in vs] for k,vs in q.items()}
        reserve(f'backpack/sweep/{i:02}',q,'probe adjacent 1/40 angle samples; 10 mm curvature bound','backpack',.1)
    mobile=layout['workshop']['mobile_platform']
    parked=next(r for r in raw['equipment'] if r['id']=='mobile/park')
    park=mobile['docks']['park']
    for dock, route in mobile['routes'].items():
        points=[park]+route
        if len(points)==1:points.append(park)
        for i,(a,b) in enumerate(zip(points,points[1:])):
            boxes=[{k:[parked[k][axis]+p[axis]-park[axis] for axis in range(3)] for k in ['min','max']} for p in [a,b]]
            q=union(boxes);q['max'][1]=max(q['max'][1],2.35) # standing rider + head allowance
            reserve(f'mobile/{dock}/{i}',q,'probe mobile/park translated along layout mobile_platform.routes; rider top 2.35 proposal','mobile',.1)
    # Core service kit does not exist in runtime. Keep the unmeasurable requirement explicit.
    missing=[{'id':'core_service_rails_crossframes','status':'not implemented; no runtime geometry to measure',
              'source':'final-assembly-plan.md:413-423; no matching generated solids or runtime kit',
              'stage':'core/backpack','time_utc':now,'pad_x':[11.1,14.9],'pad_z':[29.5,32.1],
              'crossbeam_top_y':12.60,'upstand_y':13.05,'withdrawal':5.0}]
    raw['provenance']={'base_commit':git('log','-1','--format=%H','--','game/workshop'),'branch_commit':branch,
        'branch_status':'provisional (unmerged branch)','branch_files_sha256':branch_files,
        'layout_sha256':hashlib.sha256((ROOT/files[1]).read_bytes()).hexdigest(),
        'godot':'4.7.2.stable.official.ed1daf0bf','probe_sha256':hashlib.sha256((OUT/'probe/c5_probe.gd').read_bytes()).hexdigest(),
        'method':'One headless boot; 16 supplied stage boundaries; geometry only, no gameplay acceptance.',
        'warnings':'Existing image-file export warnings. Successful final run: no script/engine errors.'}
    raw['reserved']=reservations
    raw['missing_runtime_geometry']=missing
    raw['door']={'visual_leaf':box([2.95,0,38.72],[23.05,20.9,38.84]),
        'visual_frame_opening':box([2.95,0,38.35],[23.05,20.9,38.85]),
        'collision_aperture':None,'collision_aperture_width':0,
        'blocker':'wall_z39','source':'hangar_dressing.gd:282-289 (non-colliding meshes); measured wall_z39',
        'stage':'complete','time_utc':now,'status':'Closed decorative leaf; continuous rear wall collider. No operable aperture.'}
    (OUT/'envelopes.json').write_text(json.dumps(raw,indent=2)+'\n')
    print(f'Frozen {len(raw["robot"])} component/stage bounds, {len(raw["equipment"])} equipment samples, {len(reservations)} reservations, 31 provisional crane tasks.')

if __name__=='__main__':main()
