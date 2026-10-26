#!/usr/bin/env python3
"""Conservative dimension checker, NOT a game regression or acceptance test.

All proposed solids are checked against all applicable reserved boxes. A moving
box is bounded over each angular interval, including a Lipschitz padding for
intermediate angles. Thus a pass cannot hide an in-between collision. A failed
AABB overlap can require finer geometry; it is not proof of mesh penetration.
Full pair results go to ignored verification/c5/clearances.csv.gz.
"""
import argparse
import csv
from functools import lru_cache
import gzip
import hashlib
import json
import math
from pathlib import Path
import sys

HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[2]
EPS=1e-6

def bounds(row):return tuple(row['min']+row['max'])
def rowbox(b):return {'min':list(b[:3]),'max':list(b[3:])}
def union(bs):return tuple([min(b[i] for b in bs) for i in range(3)]+[max(b[i] for b in bs) for i in range(3,6)])
def grow(b,d):return tuple([x-d for x in b[:3]]+[x+d for x in b[3:]])
def overlap(a,b):return all(min(a[i+3],b[i+3])-max(a[i],b[i])>EPS for i in range(3))
@lru_cache(maxsize=1500000)
def clearance(a,b):
    gaps=[max(b[i]-a[i+3],a[i]-b[i+3],0) for i in range(3)]
    if any(gaps):return math.sqrt(sum(x*x for x in gaps))
    return -min(min(a[i+3],b[i+3])-max(a[i],b[i]) for i in range(3))
def nearest(a,b):
    x=[];y=[]
    for i in range(3):
        if a[i+3]<b[i]:x.append(a[i+3]);y.append(b[i])
        elif b[i+3]<a[i]:x.append(a[i]);y.append(b[i+3])
        else:
            mid=(max(a[i],b[i])+min(a[i+3],b[i+3]))/2;x.append(mid);y.append(mid)
    return x,y

def posed(s,m,angle,retracted=False):
    b=bounds(s);shift=s.get('retract',[0,0,0]) if retracted else [0,0,0]
    if not m:return b
    px,_,pz=m['pivot'];a=math.radians(angle);c=math.cos(a);sn=math.sin(a)
    corners=[]
    for x in [b[0],b[3]]:
        for z in [b[2],b[5]]:
            dx=x+shift[0]-px;dz=z+shift[2]-pz
            corners.append((px+c*dx-sn*dz,pz+sn*dx+c*dz))
    return (min(x for x,z in corners),b[1]+shift[1],min(z for x,z in corners),max(x for x,z in corners),b[4]+shift[1],max(z for x,z in corners))

def solid_geometry(s,m,parked,step):
    """Endpoint plus full retract/swing envelope for a stowing transition."""
    if not m:return [('fixed',bounds(s))]
    if not parked:return [('docked',posed(s,m,0))]
    result=[('parked',posed(s,m,m['parked_degrees'],True))]
    # Retraction is a linear translation with a fixed orientation.
    if s.get('retract'):result.append(('retract',union([posed(s,m,0),posed(s,m,0,True)])))
    n=math.ceil(abs(m['parked_degrees'])/step)
    for i in range(n):
        a=m['parked_degrees']*i/n;b=m['parked_degrees']*(i+1)/n
        # Nearest endpoint angular travel <= delta/2. Inflating X/Z with r*delta/2
        # encloses the entire swept solid. No Y padding for rotation about Y.
        pad=m['radius']*math.radians(abs(b-a))/2
        q=union([posed(s,m,a,True),posed(s,m,b,True)])
        result.append(('swing', (q[0]-pad,q[1],q[2]-pad,q[3]+pad,q[4],q[5]+pad)))
    return result

def state_volumes(plan,env,layout,state):
    out=[]
    for r in env['reserved']:
        if r['kind']=='rail' and not r['id'].startswith('rail/'+state.get('rail','NONE')+'/'):continue
        if r['kind']=='backpack' and not state.get('backpack_sweep'):continue
        out.append(r)
    for r in env['robot']:
        if r['stage']!=state['robot_stage']:continue
        q=dict(r,id='robot/'+r['id'],kind='robot',margin=.1)
        if state.get('lowered'):
            q['min']=[r['min'][0],r['min'][1]-1.4,r['min'][2]];q['max']=[r['max'][0],r['max'][1]-1.4,r['max'][2]]
        elif state.get('lowering_envelope'):q['min']=[r['min'][0],r['min'][1]-1.4,r['min'][2]]
        out.append(q)
    if state.get('crane_task'):
        c=next(r for r in env['crane'] if r['id']==state['crane_task'])
        # Free strafe can cross any X/Z; no invented centreline route. Include
        # all authored approach segments using a conservative orientation ball.
        low=min(v['lowest_solid'] for v in c['carry']);high=max(v['highest_rig'] for v in c['carry'])
        out.append(dict(id='crane/'+c['id']+'/free_carry',kind='crane',margin=.1,min=[-14,low,-9],max=[26,high,39],provisional=c['provisional']))
        carry_entry=c['carry'][-1]
        entry_box=union([bounds(carry_entry['load']),bounds(carry_entry['rig']),bounds(c['approach'][0]['bounds'])])
        out.append(dict(id='crane/'+c['id']+'/carry_to_entry',kind='crane',margin=.1,**rowbox(entry_box),provisional=c['provisional']))
        source_carry=c['carry'][0]
        # Source pose and first lifted point share orientation in every authored task.
        # Lower only the load/rig minimum; mast attachment remains at overhead Y23.
        delta=c['authored_positions'][0][1]-source_carry['origin'][1]
        source_box=union([bounds(source_carry['load']),bounds(source_carry['rig'])])
        source_box=tuple(source_box[i]+(delta if i==1 else 0) for i in range(6))
        out.append(dict(id='crane/'+c['id']+'/source_lift',kind='crane',margin=.1,**rowbox(source_box),provisional=c['provisional']))
        app=c['approach']
        for i,(a,b) in enumerate(zip(app,app[1:])):
            bb=union([bounds(a['bounds']),bounds(b['bounds'])])
            rotations=c['authored_rotations']
            rotating=bool(rotations and rotations[a['index']]!=rotations[b['index']])
            if rotating:
                # An orientation ball about both authored origins includes every
                # possible rotation, deliberately conservative for arm upending.
                loc=bounds(c['payload_local']);radius=math.sqrt(sum(max(abs(loc[j]),abs(loc[j+3]))**2 for j in range(3)))+4
                origins=[c['authored_positions'][a['index']],c['authored_positions'][b['index']]]
                bb=union([bb,tuple([min(v[j] for v in origins)-radius for j in range(3)]+[max(v[j] for v in origins)+radius for j in range(3)])])
            out.append(dict(id=f'crane/{c["id"]}/approach/{i}',kind='crane',margin=.1,**rowbox(bb),provisional=c['provisional']))
    removed=set(plan['remove_layout_ids'])
    for r in env['layout_solids']:
        if r['id'] in removed or not r['enabled']:continue
        # Floor is an intended support contact; don't call a foundation on it a collision.
        if r['id']=='floor':continue
        out.append(dict(r,id='retained/'+r['id'],kind='retained',margin=.02))
    if state.get('exit'):
        out.append(dict(id='exit/corridor',kind='exit',margin=0,**{k:plan['exit'][k] for k in ['min','max']}))
    return out

def interval_covered(lo,hi,intervals,gap):
    reach=lo
    for a,b in sorted(intervals):
        if b<reach-EPS:continue
        if a>reach+gap+EPS:return False
        reach=max(reach,b)
        if reach>=hi-EPS:return True
    return reach>=hi-EPS

def walking(plan, parked=()):
    """Sweep rectangular corridors analytically over floor edges; no player simulation.

    At every change in floor/obstacle coverage, check the entire transverse width,
    support union and clear headroom. 40 mm seams may join supported slabs.
    """
    results=[];solids=[];gap=plan['criteria']['max_seam']
    motions={m['id']:m for m in plan['motions']}
    for s in plan['solids']:
        m=motions.get(s['motion']);q=posed(s,m,m['parked_degrees'] if m and m['id'] in parked else 0,bool(m and m['id'] in parked))
        solids.append(dict(s,**rowbox(q)))
    for path in plan['walking_routes']:
        owner=path['id'][:2]+'arm_'+str(path['level'])
        if owner in parked and not path['primary']:continue
        level=path['level'];width=path['width'];required=1.5 if path['primary'] else 1.2
        floors=[bounds(s) for s in solids if s['kind']=='floor' and abs(s['max'][1]-level)<EPS]
        obstacles=[s for s in solids if s['min'][1]<level+2.2-EPS and s['max'][1]>level+EPS]
        problems=[]
        if width+EPS<required:problems.append('declared width below requirement')
        for a,b in zip(path['points'],path['points'][1:]):
            axis=0 if abs(a[0]-b[0])>EPS else 2;cross=2 if axis==0 else 0
            pos=0 if axis==0 else 1;other=1-pos
            lo,hi=sorted([a[pos],b[pos]]);middle=a[other]
            rectangle=[0,level,0,0,level+2.2,0]
            rectangle[axis]=lo;rectangle[axis+3]=hi;rectangle[cross]=middle-width/2;rectangle[cross+3]=middle+width/2
            cuts={lo,hi}
            for f in floors:
                cuts.update(v for v in [f[axis],f[axis+3]] if lo<v<hi)
            cuts=sorted(cuts)
            unsupported=[]
            for u,v in zip(cuts,cuts[1:]):
                mid=(u+v)/2
                strips=[(f[cross],f[cross+3]) for f in floors if f[axis]-EPS<=mid<=f[axis+3]+EPS]
                if not interval_covered(middle-width/2,middle+width/2,strips,gap):unsupported.append((u,v))
            # Only a narrow seam, bounded on both sides by deck, is acceptable.
            for u,v in unsupported:
                if v-u>gap+EPS or u<=lo+EPS or v>=hi-EPS:problems.append(f'unsupported corridor {u:.3f}..{v:.3f}')
            for s in obstacles:
                if overlap(tuple(rectangle),bounds(s)):problems.append('width/headroom obstruction '+s['id'])
        results.append(dict(id=path['id'],width=width,required=required,passed=not problems,problems=sorted(set(problems))))
    return results

def audit(plan,env,layout):
    errors=[];byid={s['id']:s for s in plan['solids']}
    layout_ids={s['id'] for s in layout['workshop']['solids']}
    if len(byid)!=len(plan['solids']):errors.append('duplicate solid IDs')
    if plan['datums']['hip']!=[13,10.6,26] or plan['datums']['bearing_cap_top']!=10.97 or plan['datums']['mirror_x']!=13:errors.append('protected hip/bearing/mirror datum changed')
    if plan['datums']['levels']!=[8.4,11.2,14,16.4]:errors.append('protected elevator work stops changed')
    for id in plan['remove_layout_ids']:
        if id not in layout_ids:errors.append('unknown retirement '+id)
    for s in plan['solids']:
        r=byid.get(s.get('mirror_of',''))
        expected=(26-s['max'][0],s['min'][1],s['min'][2],26-s['min'][0],s['max'][1],s['max'][2])
        if not r or any(abs(a-b)>EPS for a,b in zip(bounds(r),expected)):errors.append('mirror including fore/aft failed '+s['id'])
        if s.get('retract') and r.get('retract')!=[-s['retract'][0],*s['retract'][1:]]:errors.append('tongue retraction mirror '+s['id'])
    motions={m['id']:m for m in plan['motions']}
    for m in plan['motions']:
        mate=motions.get(('R_' if m['id'].startswith('L_') else 'L_')+m['id'][2:])
        if not mate or abs(mate['pivot'][0]-(26-m['pivot'][0]))>EPS or mate['pivot'][1:]!=m['pivot'][1:] or mate['parked_degrees']!=-m['parked_degrees']:errors.append('motion mirror '+m['id'])
    for pocket in plan['parking_pockets']:
        m=motions[pocket['id']];pb=bounds(pocket)
        for solid in plan['solids']:
            if solid['motion']!=m['id']:continue
            sb=posed(solid,m,m['parked_degrees'],True)
            if any(sb[i]<pb[i]-EPS or sb[i+3]>pb[i+3]+EPS for i in range(3)):errors.append('parked solid outside pocket '+solid['id'])
    for state in plan['states']:
        if set(state['docked']) & set(state['parked']) or set(state['docked']+state['parked'])!=set(motions):errors.append('incomplete/excess state membership '+state['id'])
    seams=[]
    for seam in plan['seams']:
        distance=math.dist(seam['a'],seam['b']);step=abs(seam['a'][1]-seam['b'][1])
        seams.append(dict(id=seam['id'],gap=distance,step=step,passed=distance<=.04+EPS and step<=.04+EPS))
    if env['provenance']['layout_sha256']!=hashlib.sha256((ROOT/'game/workshop/assets/workshop-layout.json').read_bytes()).hexdigest():errors.append('measured layout hash is stale')
    return errors,seams

def evaluate(plan,env,layout,pair_path=None):
    errors,seams=audit(plan,env,layout);walk=[]
    configurations={tuple(sorted(state['parked'])) for state in plan['states']}
    for parked in sorted(configurations):
        for w in walking(plan,parked):
            w['parked']=list(parked);walk.append(w)
    motions={m['id']:m for m in plan['motions']};geometry={}
    for s in plan['solids']:
        for parked in [False,True]:geometry[s['id'],parked]=solid_geometry(s,motions.get(s['motion']),parked,plan['criteria']['arc_step_degrees'])
    summaries=[];tight={};pair_count=0;nearest_cache={}
    sink=gzip.open(pair_path,'wt',newline='',compresslevel=1) if pair_path else None
    writer=csv.writer(sink) if sink else None
    if writer:writer.writerow(['state','solid','reserved','clearance_m','required_m','phase','passed'])
    for state in plan['states']:
        volumes=state_volumes(plan,env,layout,state);minimum={};violations=[];per_solid=[]
        for s in plan['solids']:
            parked=s['motion'] in state['parked'];pieces=geometry[s['id'],parked]
            # Roll-out checks parked endpoint only: arms moved while weight supported
            # in prior state. Earlier prepare/lower states still audit full motion.
            if state.get('lowered'):pieces=[q for q in pieces if q[0] in ['fixed','parked']]
            best=None
            for v in volumes:
                vb=bounds(v);key=(s['id'],parked,bool(state.get('lowered')),vb)
                if key not in nearest_cache:
                    phase,ab=min(pieces,key=lambda q:clearance(q[1],vb));nearest_cache[key]=(phase,ab,clearance(ab,vb))
                phase,ab,distance=nearest_cache[key]
                # Zero-area face contacts are allowed only where margin is zero.
                passed=distance>=v['margin']-EPS
                row=dict(state=state['id'],solid=s['id'],reserved=v['id'],clearance=distance,margin=v['margin'],phase=phase,passed=passed,kind=v['kind'],a=list(ab),b=list(vb))
                if best is None or distance<best['clearance']:best=row
                if v['id'] not in minimum or distance<minimum[v['id']]['clearance']:minimum[v['id']]=row
                if not passed:violations.append(row)
                if EPS<distance<.30:
                    # Every unique tight pair; repeated states have identical geometry.
                    key=(s['id'],v['id'],tuple(round(x,6) for x in ab),tuple(round(x,6) for x in vb))
                    tight[key]=row
                pair_count+=1
                if writer:writer.writerow([state['id'],s['id'],v['id'],f'{distance:.6f}',v['margin'],phase,passed])
            per_solid.append(best)
        summaries.append(dict(id=state['id'],passed=not violations,violations=len(violations),minimum=min(x['clearance'] for x in minimum.values()),by_volume=list(minimum.values()),by_solid=per_solid,worst=sorted(violations,key=lambda r:r['clearance'])[:12]))
    if sink:sink.close()
    self_intersections=[]
    for i,a in enumerate(plan['solids']):
        for b in plan['solids'][i+1:]:
            # Same-parent fabricated contacts are intentional. Independent moving
            # assemblies must never use that exemption.
            if not a['motion'] or not b['motion'] or a['motion']==b['motion']:continue
            if overlap(bounds(a),bounds(b)):self_intersections.append([a['id'],b['id']])
    exit_box=bounds(plan['exit']);exit_inventory=[]
    for r in env['layout_solids']:
        if r['enabled'] and overlap(exit_box,bounds(r)):
            exit_inventory.append(dict(id=r['id'],removed=r['id'] in plan['remove_layout_ids'],**{k:r[k] for k in ['min','max']}))
    blockers=list(errors)
    if self_intersections:blockers.append('independent proposed moving assemblies intersect at docked pose')
    if any(not x['passed'] for x in walk):blockers.append('walking support/width/headroom checks fail')
    if any(not x['passed'] for x in seams):blockers.append('joint seams fail')
    if env['missing_runtime_geometry']:blockers.append('core service kit has no runtime geometry/support design')
    if env['door']['collision_aperture'] is None:blockers.append('door has no collision aperture')
    if any(not x['passed'] for x in summaries):blockers.append('reserved clearance failures')
    return dict(status='FAIL' if blockers else 'PASS',blockers=blockers,pair_count=pair_count,states=summaries,input_hashes={name:hashlib.sha256((HERE/name).read_bytes()).hexdigest() for name in ['plan.json','envelopes.json']},
                walking=walk,seams=seams,self_intersections=self_intersections,tight=list(tight.values()),exit_inventory=exit_inventory,
                method='Conservative box bounds and continuously enclosed swing intervals. Negative values are envelope overlap; refine before asserting physical mesh collision.')

def load():return (json.loads((HERE/'plan.json').read_text()),json.loads((HERE/'envelopes.json').read_text()),json.loads((ROOT/'game/workshop/assets/workshop-layout.json').read_text()))
def main():
    parser=argparse.ArgumentParser(description=__doc__);parser.add_argument('--output',type=Path,default=ROOT/'game/workshop/verification/c5');args=parser.parse_args()
    args.output.mkdir(parents=True,exist_ok=True)
    report=evaluate(*load(),pair_path=args.output/'clearances.csv.gz')
    (args.output/'check.json').write_text(json.dumps(report,indent=2)+'\n')
    print('C5 '+report['status']+' — '+str(report['pair_count'])+' solid/reservation/state comparisons')
    for s in report['states']:print(f"{s['id']}: {'PASS' if s['passed'] else 'FAIL'}; minimum {s['minimum']:.3f} m; {s['violations']} below margin")
    print('Walking:',sum(r['passed'] for r in report['walking']),'/',len(report['walking']),'Seams:',sum(r['passed'] for r in report['seams']),'/',len(report['seams']))
    print('Tightest five positive clearances (zero-margin contacts listed separately in full report):')
    for r in sorted(report['tight'],key=lambda r:r['clearance'])[:5]:print(f" {r['clearance']:.6f} m / required {r['margin']:.3f}: {r['solid']} ↔ {r['reserved']} ({r['state']}, {r['phase']})")
    print('Blockers: '+'; '.join(report['blockers']));print('Full pairs and report:',args.output)
    return 1 if report['status']=='FAIL' else 0
if __name__=='__main__':sys.exit(main())
