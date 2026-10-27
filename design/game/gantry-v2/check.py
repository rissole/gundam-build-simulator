#!/usr/bin/env python3
"""C6 coarse design check, stdlib only. Exit 1 means unresolved geometry.

Signed AABB distance: Euclidean separation, or negative least-axis penetration.
Whole-route boxes deliberately retain false positives. No contact is silently
excluded; neither a box failure nor a pass establishes detailed mechanism fit.
"""
import json
import math
from pathlib import Path

HERE = Path(__file__).resolve().parent

def read():
    return (json.loads((HERE / 'plan.json').read_text()),
            json.loads((HERE / 'envelopes.json').read_text()))

def box(lo, hi, name=''):
    return dict(min=lo, max=hi, id=name)

def mirror(b, x=13):
    return box([2*x-b['max'][0], b['min'][1], b['min'][2]],
               [2*x-b['min'][0], b['max'][1], b['max'][2]], 'R/'+b.get('id',''))

def distance(a, b):
    gaps = [max(a['min'][i]-b['max'][i], b['min'][i]-a['max'][i]) for i in range(3)]
    return math.sqrt(sum(max(0, g)**2 for g in gaps)) if max(gaps) > 0 else max(gaps)

def pair_min(a, b):
    return min((distance(x,y), x['id'], y['id']) for x in a for y in b)

def geometry(p, state):
    c = p['catwalk']; fixed = [dict(t) for t in p['towers']]
    # Towers are gross reserved volumes: lift, landings, parked roots and supports
    # are contained pockets, not a claim that the shaft is filled solid.
    if state == 'exit':
        return fixed, []
    support = []
    for i,(root,cap) in enumerate(zip(p['hip_support']['roots'],p['hip_support']['caps'])):
        support.append(box([min(root[0],cap[0])-.3,9.6,min(root[2],cap[2])-.35],
                           [max(root[0],cap[0])+.3,11.4,max(root[2],cap[2])+.35],f'support/{i}'))
    if state == 'delivery':
        return fixed, support
    decks=[]
    for a in c['arms']:
        y=a['level'];x=c['root_x'];z=a['root_z'];w=c['deck_width']/2
        # Deck + guards + standing-person headroom; telescoping root is a walkway.
        for b in [box([x-w,y-c['deck_depth'],z-w],[x+w,y+p['criteria']['headroom'],c['root_z_park']+w],f'root/{y}'),
                  box([x,y-c['deck_depth'],z-w],[x+a['length'],y+p['criteria']['headroom'],z+w],f'arm/{y}')]:
            decks.extend([b,mirror(b,p['mirror_x'])])
    return fixed+decks,support

def results(p,e):
    rows=[]
    def add(name, clearance, detail=''):
        rows.append((name,clearance>=-1e-7,clearance,detail))
    def compare(name,a,b):
        d,x,y=pair_min(a,b);add(name,d,f'{x} / {y}')
    c=p['catwalk'];crit=p['criteria']
    delta=0.0
    for left,right in [(p['towers'][0],p['towers'][1]),
                       (p['hip_support']['parked'][0],p['hip_support']['parked'][1]),
                       (p['building']['door_leaf_pockets'][0],p['building']['door_leaf_pockets'][1])]:
        reflected=mirror(left,p['mirror_x'])
        delta=max(delta,max(abs(right[k][i]-reflected[k][i]) for k in ['min','max'] for i in range(3)))
    for pair in [p['hip_support']['roots'],p['hip_support']['caps'],[l['centre'] for l in p['lifts']]]:
        delta=max(delta,abs(pair[0][0]+pair[1][0]-2*p['mirror_x']),
                  abs(pair[0][1]-pair[1][1]),abs(pair[0][2]-pair[1][2]))
    for key in ['shaft_size','car_size']:
        delta=max(delta,max(abs(a-b) for a,b in zip(p['lifts'][0][key],p['lifts'][1][key])))
    add('mirror',-delta,'X -> 26-X; deck/right paths derived by reflection')
    invariant=max(abs(a-b) for a,b in zip(p['hip_datum'],[13,10.6,26]))
    for cap,expected in zip(p['hip_support']['caps'],[[12.35,10.97,26.65],[13.65,10.97,26.65]]):
        invariant=max(invariant,max(abs(a-b) for a,b in zip(cap,expected)))
    invariant=max(invariant,abs(p['hip_support']['hold_down_count']-4))
    add('hip datum',-invariant,'datum, bearing caps and four hold-downs preserved')
    add('walkway width',min(c['clear_width'],c['deck_width']-.2)-crit['walkway'],'clear after guards')
    add('landing width',min(c['landing_width'],c['landing_left']['max'][0]-c['landing_left']['min'][0],c['return_left']['max'][0]-c['return_left']['min'][0])-crit['landing'])
    add('running seams',crit['seam_max']-c['seam'],'flush bridge plates at root/car/tongue')
    add('interlevel headroom',min(b-a-c['deck_depth'] for a,b in zip(p['levels'],p['levels'][1:]))-crit['headroom'])
    # Parked arm/root reservation includes guard width; all moving steel inside tower.
    park=box([c['root_x']-.7,8.2,c['root_z_park']-.7],
             [c['root_x']+.7,17.5,c['root_z_park']+c['parked_length']+.7],'parked catwalk')
    for index,(name,b,t) in enumerate([('L pocket',park,p['towers'][0]),('R pocket',mirror(park),p['towers'][1])]):
        add(name,min(min(q['min'][i]-t['min'][i],t['max'][i]-q['max'][i]) for q in [b,p['hip_support']['parked'][index]] for i in range(3)))
    landing=c['return_left'];add('parked return lane',park['min'][0]-landing['max'][0])
    lift=p['lifts'][0];add('shaft to pocket',park['min'][0]-(lift['centre'][0]+lift['shaft_size'][0]/2))
    assembly,support=geometry(p,'assembly');delivery,held=geometry(p,'delivery');exit_fixed,_=geometry(p,'exit')
    for r in e['robot']:
        compare('assembly/'+r['id'],assembly,[r])
    compare('assembly/support interfaces',support,e['robot'])
    compare('assembly/support headroom',support,[s for s in assembly if s['id'].startswith(('arm/','R/arm/','root/','R/root/'))])
    # Swept root/wing motion: full quarter-circle enclosed by its X/Z rectangle,
    # then linear root translation. Empty decks only; all work-edge gates shut.
    motion=[]
    for a in c['arms']:
        radius=math.hypot(a['length'],c['deck_width']/2)
        b=box([c['root_x']-.7,a['level']-.2,a['root_z']-.7],
              [c['root_x']+radius,a['level']+1.1,c['root_z_park']+c['parked_length']+.7],f'work motion/{a["level"]}')
        motion.extend([b,mirror(b)])
    compare('assembly/catwalk motion',motion,e['robot'])
    for r in e['crane']:
        # The hip remains supported on all later deliveries. Coarse source/seat
        # boxes overlap intentional contacts too: these remain FAIL, not exemptions.
        d,x,y=pair_min(delivery+held,[r])
        fixed_gap,_,_=pair_min(delivery,[r])
        add('delivery/'+r['id'],d,f'{x}; tower clearance {fixed_gap:+.3f} m')
    for r in e['reserved']:
        fixtures=delivery+held if r['id'].startswith('loaded_leg') or r['id']=='backpack_swing' else assembly+support
        compare('reserved/'+r['id'],fixtures,[r])
    corridor=dict(p['exit']['corridor'],id='exit corridor')
    compare('exit/parked cage',exit_fixed,[corridor])
    # No lowering assumed. The carrier takes the soles at their existing Y1.4.
    robot=box([min(r['min'][i] for r in e['robot']) for i in range(3)],
              [max(r['max'][i] for r in e['robot']) for i in range(3)],'grown robot')
    carrier=p['exit']['carrier'];door=p['building']['door']
    add('exit/robot and carrier lateral',min(min(b['min'][0]-corridor['min'][0],corridor['max'][0]-b['max'][0]) for b in [robot,carrier]))
    add('exit/robot headroom',corridor['max'][1]-robot['max'][1])
    add('exit/open aperture',min(corridor['min'][0]-door['min'][0],door['max'][0]-corridor['max'][0],door['max'][1]-corridor['max'][1]))
    add('exit/open leaves',min(corridor['min'][0]-p['building']['door_leaf_pockets'][0]['max'][0],p['building']['door_leaf_pockets'][1]['min'][0]-corridor['max'][0]))
    add('exit/threshold',-abs(p['building']['threshold']))
    # In service only: removable crossframes intentionally enter the core channel.
    add('core kit/stowed clear',min(distance(b,corridor) for b in p['core_kit']['stow']))
    return rows

def main():
    p,e=read();rows=results(p,e)
    for name,ok,d,detail in rows:
        print(f'{"PASS" if ok else "FAIL"} {name:36s} {d:+7.3f} m  {detail}')
    failed=sum(not r[1] for r in rows)
    print(f'{"FAIL" if failed else "PASS"}: {len(rows)-failed}/{len(rows)} coarse checks pass; {failed} unresolved. No gameplay/player acceptance.')
    return bool(failed)

if __name__=='__main__':
    raise SystemExit(main())
