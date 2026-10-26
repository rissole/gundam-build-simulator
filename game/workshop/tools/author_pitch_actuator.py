"""Author the pitch workshop from exact source identities; no mesh regeneration.
Run from any directory. Prerequisites below follow access/closure, not animation phases.
"""
import json
import sys
from pathlib import Path
from standard_hardware import CATALOGUE, canonical_part, audit_standard_hardware
ROOT = Path(__file__).resolve().parents[3]
ASSETS = ROOT / 'game/workshop/assets'
sys.path.insert(0, str(ROOT / 'models/foot-fa01/src'))
from source_connections import pitch_pairs, pitch_instance_ids
manifest = json.loads((ROOT / 'models/foot-fa01/output/parts-manifest.json').read_text())['parts']
source_ids = pitch_instance_ids()
source = [p for p in manifest if p['instance_id'] in source_ids]
assert len(source) == 109
by_id = {p['instance_id']: p for p in source}
def uid(family, n=1): return f'{family}__{n:03}'
# Compatibility describes manufactured parts, not their numbered source instances.
# These pitch pairs have the same shape/fit at both endpoints (pitch_interfaces.py).
# Keep their physical identities and each slot's source mesh/pose independently.
shared_titles = {
    'FA-526': 'Spherical eye bearing', 'FA-527': 'Eye retaining ring',
    'FA-528': 'End sensor', 'FA-221': 'Eye pin', 'FA-222': 'Pin keeper',
}
variant_names = {
    uid('FA-524'): ('Receiver collar half', 'Receiver'),
    uid('FA-524',2): ('Clearance collar half', 'Clearance'),
    uid('FA-525'): ('Base eye housing', 'Base'),
    uid('FA-525',2): ('Rod eye housing', 'Rod'),
    uid('FA-529'): ('Rear cap gasket', 'Rear'),
    uid('FA-529',2): ('Front cap gasket', 'Front'),
    uid('FA-220'): ('Cradle clevis', 'Cradle'),
    uid('FA-220',2): ('Ring clevis', 'Ring'),
}
parts = {}
instances = []
for p in source:
    family = p['part_id']
    kind = p['instance_id'].lower() if family.startswith('FA-') else family.lower()
    if family in shared_titles: kind = family.lower()+'-pitch'
    if family == 'W-24': kind = 'washer'
    if kind not in parts:
        title = p['label'].removeprefix('P ') if family.startswith('FA-') else {'W-12':'M12 washer','W-24':'M24 washer','H-12030':'M12 × 30 screw','H-12040':'M12 × 40 screw','H-12050':'M12 × 50 cap screw','H-24070':'M24 × 70 clevis bolt'}[family]
        title = shared_titles.get(family,title)
        title, variant_label = variant_names.get(p['instance_id'],(title,''))
        variant = ('pitch-'+variant_label.lower() if variant_label else 'pitch') if family.startswith('FA-') else 'standard'
        parts[kind] = dict(family=family, variant=variant, title=family+' · '+title, short_title=title, carry_class='two_hand' if family in ['FA-510','FA-516','FA-518','FA-220'] else ('hand' if family in ['FA-511','FA-512','FA-513','FA-514','FA-517','FA-519','FA-521','FA-525','FA-526','FA-221'] else 'pocket'))
        if variant_label: parts[kind]['variant_label'] = variant_label
    instances.append(dict(instance_id=p['instance_id'],part_id=family,kind=kind))
for standard in CATALOGUE:
    parts[standard] = canonical_part(standard)
audit_standard_hardware(parts)
kinds = {p['instance_id']: p['kind'] for p in instances}
slots = {}; pages = []; last = ['base']
def slot(id, requires):
    sid = 'base' if id == uid('FA-513') else id
    slots[sid] = dict(accepts=kinds[id],requires=requires,pose_source=id,label=parts[kinds[id]]['short_title'])
    return sid
slot(uid('FA-513'), [])
def page(title, goal, components, hardware=(), where={}, note=None):
    global last
    current = []
    component_slots = []
    for id in components:
        sid = slot(id, list(last))
        current.append(sid)
        component_slots.append(sid)
    hardware_slots = []
    for connection in hardware:
        created = []
        for screw, washer in pitch_pairs(connection):
            assert by_id[screw]['paired_instance_id'] == washer
            assert by_id[washer]['paired_instance_id'] == screw
            w = slot(washer,list(current[:len(components)]) or list(last))
            s = slot(screw,[w])
            current += [w,s]
            created += [w,s]
        hardware_slots.append((connection, created))
    objectives = []
    order = []
    grouped = {}
    for sid in component_slots:
        kind = slots[sid]['accepts']
        if kind not in grouped:
            order.append(kind)
            grouped[kind] = []
        grouped[kind].append(sid)
    for kind in order: objectives.append(dict(op='fit', slots=grouped[kind]))
    for connection, created in hardware_slots:
        objective = dict(op='fit', slots=created)
        if connection in where: objective['where'] = where[connection]
        objectives.append(objective)
    record = dict(title=title, goal=goal, slots=current, objectives=objectives, view='components')
    if note: record['note'] = note
    pages.append(record)
    last = current
page('Drive cartridge','Put FA-513 (motor) in the preparation C fixture and mount the gearbox on it.',[uid('FA-514')],['gearbox'],{'gearbox':'upper holes'})
page('Coupling & bearing','Fit the coupling on the gearbox shaft and position the bearing.',[uid('FA-515'),uid('FA-522')],note={'at':0,'text':'Leave FA-515 unclamped for now.'})
page('Lead screw','Slide the lead screw into the bearing and clamp the coupling.',[uid('FA-516')],['coupling'],{'coupling':'coupling clamp'})
page('Retain the shaft','Lock the lead screw in place with the retainer and collar.',[uid('FA-523'),uid('FA-524'),uid('FA-524',2)],['collar'],{'collar':'through the clearance half'})
page('Travelling nut','Thread the travelling nut onto the lead screw.',[uid('FA-517')])
page('Output rod','Join the output rod to the travelling nut.',[uid('FA-518')],['rod'])
page('Enclose the drive','Close the housing around the drive and bolt it to the motor and retainer.',[uid('FA-510')],['motor','retainer'],{'motor':'motor, from the open rear','retainer':'retainer, from outside'})
page('Guide key','Fit the guide key so the rod slides without turning.',[uid('FA-521')],['guide'],{'guide':'key ears to housing'})
page('End sensors','Fit both end-stop probes and the barrel plug.',[uid('FA-528'),uid('FA-528',2),uid('FA-530')],['rear-sensor','front-sensor'],{'rear-sensor':'rear probe','front-sensor':'front probe'})
page('Front guide & seals','Fit the front guide, the wiper and both cap gaskets.',[uid('FA-519'),uid('FA-520'),uid('FA-529'),uid('FA-529',2)],note={'at':2,'text':'The gasket with extra clearance holes goes at the motor end.'})
page('Close the housing','Fit both end caps and bolt them shut.',[uid('FA-511'),uid('FA-512')],['rear-cap','front-cap'],{'rear-cap':'rear cap','front-cap':'front cap'})
page('Base eye','Build the base eye: housing, bearing, then retaining ring.',[uid('FA-525'),uid('FA-526'),uid('FA-527')],['base-eye'])
page('Rod eye','Build the rod eye: housing, bearing, then retaining ring.',[uid('FA-525',2),uid('FA-526',2),uid('FA-527',2)],['rod-eye'])
# Within each eye, and guide/seal layer, enforce the explicitly illustrated order.
for chain in [[uid('FA-525'),uid('FA-526'),uid('FA-527')],[uid('FA-525',2),uid('FA-526',2),uid('FA-527',2)],[uid('FA-519'),uid('FA-520')]]:
    for a,b in zip(chain,chain[1:]): slots[b]['requires'].append(a)
# The housing collides as a solid box around its hollow bore. The bearing center
# is 66–81 mm behind the face a standing player looks at, past the 65 mm
# near-surface test, so the placement preview never appears. 120 mm covers that
# proxy and still rejects a look along the closed barrel.
for n in (1, 2): slots[uid('FA-526', n)]['sight_depth'] = 0.12
assert len(slots)==91
pages.append(dict(title='Ready to install',body='FA-500-P is ready. Seat it in the foot.',slots=list(slots),view='prepared'))
actuator = dict(part_id='FA-500-P',title='FA-500-P · Pitch actuator',root_slot='base',frame_source=uid('FA-510'),bounds=[0.24,0.80,0.80],interaction='components',service_access='open_station',work_locations=['station'],slots=slots,milestones={'prepared':list(slots),'enclosed':[uid('FA-510')]+pages[10]['slots']},enclosure_source=uid('FA-510'),manual=pages)
foot = json.loads((ASSETS/'assembly-definitions.json').read_text())['assemblies']['foot']
foot['title']='Foot · pads and pitch actuator'
parent = foot['slots']
parent_pages=[]
# Exposed outboard connection points measured on the current imported meshes.
# Coordinates are source-mesh-local; targeting offsets do not move snap geometry.
parent_target_offsets = {
    uid('FA-220'): [-.083,0,0], uid('FA-220',2): [-.156,0,0],
    **{uid('FA-221',n): [-.071,0,0] for n in (1,2)},
    **{uid('FA-222',n): [-.005,0,0] for n in (1,2)},
}
# Cradle and keeper heads expose source -X; ring mounting heads expose +Y.
for connection, screw_offset, washer_offset in [
    ('cradle',[-.047,0,0],[-.002,0,0]),
    ('ring',[0,.047,0],[0,.002,0]),
    ('base-keeper',[-.021,0,0],[-.00125,0,0]),
    ('rod-keeper',[-.021,0,0],[-.00125,0,0]),
]:
    for screw, washer in pitch_pairs(connection):
        parent_target_offsets[screw] = screw_offset
        parent_target_offsets[washer] = washer_offset
assert len(parent_target_offsets) == 18
def pslot(id, requires):
    sid='pitch/'+id
    parent[sid]=dict(accepts=kinds[id],requires=requires,pose_source=id,label=parts[kinds[id]]['short_title'],presentation="components",target_offset=parent_target_offsets[id])
    return sid
brackets=[]
for end,n in [('base',1),('rod',2)]:
    c=pslot(uid('FA-220',n),[]); group=[c]
    for s, washer in pitch_pairs('cradle' if n==1 else 'ring'):
        w=pslot(washer,[c]); group += [w,pslot(s,[w])]
    brackets+=group
    receiver = 'FA-103' if n==1 else 'FA-200'
    clevis_name = 'Cradle clevis' if n==1 else 'Ring clevis'
    parent_pages.append(dict(title=clevis_name,goal=f'Bolt the {clevis_name.lower()} to {receiver}.',slots=group,objectives=[dict(op='fit',slots=group[:1]),dict(op='fit',slots=group[1:])],view='components',child_slot='pitch',context_sources=[uid(receiver)]))
parent['pitch']=dict(assembly='pitch_actuator',milestone='prepared',requires=brackets,pose_source=uid('FA-510'),label='Pitch actuator',service_access='assisted',connections=[uid('FA-220'),uid('FA-220',2)])
group=['pitch']
for n in [1,2]:
    screw_id, washer_id = pitch_pairs('base-keeper' if n==1 else 'rod-keeper')[0]
    pin=pslot(uid('FA-221',n),['pitch']); keeper=pslot(uid('FA-222',n),[pin]); w=pslot(washer_id,[keeper]); screw=pslot(screw_id,[w]); group +=[pin,keeper,w,screw]
base_end, rod_end = group[1:5], group[5:9]
assert base_end + rod_end == group[1:] and base_end == ['pitch/FA-221__001','pitch/FA-222__001','pitch/W-12__053','pitch/H-12030__029']
parent_pages.append(dict(title='Seat & pin actuator',goal='Seat the prepared actuator between the clevises and pin both ends.',slots=group,objectives=[dict(op='seat',slot='pitch'),dict(op='fit',slots=base_end,where='base end'),dict(op='fit',slots=rod_end,where='rod end')],view='components',child_slot='pitch',context_sources=[uid('FA-220'),uid('FA-220',2)]))
foot['manual']+=parent_pages
foot['manual'][0]['title']='Foot workshop'
foot['manual'][0]['body']='Build both heel pads and the pitch actuator, then fit them to the foot.'
foot['manual'][0]['slots']=list(parent)
for index, heel in ((1,'heel_1'),(2,'heel_2')):
    step = foot['manual'][index]
    s = step['slots']
    assert s[0] == heel
    del step['body']
    step['goal'] = 'Seat a prepared heel pad here and bolt it down.'
    step['objectives'] = [dict(op='seat',slot=s[0]),dict(op='fit',slots=s[1:])]
foot['milestones']['pitch_secured']=brackets+group
foot['milestones']['complete']=list(parent)
base=json.loads((ASSETS/'heel-pads.json').read_text())
base['parts']+=instances
base['builds'].append(dict(id='pitch',definition='pitch_actuator',label='Pitch actuator',base=uid('FA-513'),home=[-6.4,0.235,0.4]))
base['mounts'].append(dict(id='pitch',source=uid('FA-510'),label='Pitch actuator'))
base['definitions']='res://assets/pitch-actuator-definitions.json'
base['context_storage_families']=['FA-400','FA-401','FA-402','FA-403','FA-404','FA-405']
# Static receiving frames retain their actual openings for connection access.
base['context_collision']={uid('FA-103'):'mesh',uid('FA-200'):'mesh'}
assert len(base['parts'])==135 and len({p['instance_id'] for p in base['parts']})==135
# Connection-scale diagrams. Receivers are visual context, never extra supplies.
# Directions are authored in pitch-local coordinates and converted to Godot axes.
import math
axis=(0,-500/math.hypot(500,520),520/math.hypot(500,520))
side=(0,axis[2],-axis[1])
def godot_vector(p):
    x=p[0]; y=side[1]*p[1]+axis[1]*p[2]; z=side[2]*p[1]+axis[2]*p[2]
    return [x,z,-y]
def diagram(title, sources, context=(), look=(1,1,1)):
    offsets={}
    for id in sources:
        part=by_id[id]
        if 'insertion_axis' not in part:continue
        a=part['insertion_axis']; distance=.030 if id.startswith('H-') else .012
        offsets[id]=[-a[0]*distance,-a[2]*distance,a[1]*distance]
    return dict(title=title,sources=list(sources),context=list(context),direction=godot_vector(look),up=godot_vector((0,0,1)),offsets=offsets)
def fasts(*connections):
    return [id for connection in connections for screw, washer in pitch_pairs(connection) for id in (washer, screw)]
barrel=uid('FA-510')
# Only pieces fully enclosed by the closed housing/rod are hidden. Exterior
# seals, guide ears, sensors, eyes and their fasteners stay visible.
enclosed_sources=[uid(f) for f in ['FA-513','FA-514','FA-515','FA-516','FA-517','FA-519','FA-522','FA-523','FA-524']]+[uid('FA-524',2)]+fasts('motor','gearbox','rod')+fasts('coupling','collar')
for d in slots.values():d['enclosed']=d['pose_source'] in enclosed_sources
views=[
    [diagram('FA-514 → FA-513',pages[0]['slots'],[uid('FA-513')],(1,1,2))],
    [diagram('FA-515 • output shaft',[uid('FA-515')],[uid('FA-514')],(1,1,1)),diagram('FA-522 • fixture position',[uid('FA-522')],[uid('FA-514')],(1,1,2))],
    [diagram('FA-516 into FA-515 • two clamps',[uid('FA-515')]+fasts('coupling'),[uid('FA-516'),uid('FA-514'),uid('FA-522')],(1,2,.5))],
    [diagram('FA-523 • bearing face',[uid('FA-523')],[uid('FA-522'),uid('FA-516')],(1,1,2)),diagram('FA-524 • split collar',[uid('FA-524'),uid('FA-524',2)]+fasts('collar'),[uid('FA-516'),uid('FA-523')],(1,2,.5))],
    [diagram('FA-517 onto FA-516',[uid('FA-517')],[uid('FA-516')],(1,1,1))],
    [diagram('FA-518 → FA-517 • open screw pockets',fasts('rod'),[uid('FA-518'),uid('FA-517')],(1,1,2))],
    [diagram('FA-513 • rear fastening',fasts('motor'),[barrel,uid('FA-513')],(1,1,-2)),diagram('FA-523 • external screws',fasts('retainer'),[barrel,uid('FA-523')],(1,2,2))],
    [diagram('FA-521 • rod slot',[uid('FA-521')],[uid('FA-518')],(2,1,.4)),diagram('FA-521 • housing ears',fasts('guide'),[uid('FA-521'),barrel],(2,-1,.3))],
    [diagram('FA-528 • both ends',[uid('FA-528')]+fasts('rear-sensor'),[barrel],(2,1,.5)),diagram('FA-530 • barrel port',[uid('FA-530')],[barrel],(2,1,.5))],
    [diagram('FA-519 / FA-520',[uid('FA-519'),uid('FA-520'),uid('FA-529',2)],[barrel,uid('FA-518')],(1,1,1)),diagram('FA-529 • rear gasket',[uid('FA-529')],[barrel],(1,1,-1))],
    [diagram('FA-512 • rear cap',[uid('FA-512')]+fasts('rear-cap'),[barrel,uid('FA-529')],(1,1,-2)),diagram('FA-511 • front cap',[uid('FA-511')]+fasts('front-cap'),[barrel,uid('FA-519'),uid('FA-520'),uid('FA-529',2)],(1,1,2))],
    [diagram('FA-525 • screws',[uid('FA-525')]+fasts('base-eye'),[uid('FA-512')],(2,1,-.8)),diagram('FA-526 / FA-527',[uid('FA-525'),uid('FA-526'),uid('FA-527')],[],(2,1,.3))],
    [diagram('FA-525 • screws',[uid('FA-525',2)]+fasts('rod-eye'),[uid('FA-518')],(2,1,.8)),diagram('FA-526 / FA-527',[uid('FA-525',2),uid('FA-526',2),uid('FA-527',2)],[],(2,1,.3))],
    [diagram('FA-500-P • prepared',list(slots_source['pose_source'] for slots_source in slots.values()),[],(1,1,.25))]
]
for n in (1,2):
    views[10+n][0]['offsets']={}
    views[10+n][1]['offsets']={uid('FA-526',n):[.075,0,0],uid('FA-527',n):[.12,0,0]}
views[-1][0]['offsets']={}
views[7][0]['offsets']={uid('FA-521'):godot_vector((0,.025,0))}
views[7][0]['context_padding']=.05
context_ranges=[[(145,220)],[(182,245),(245,274)],[(192,250)],[(250,290),(276,310)],[(330,380)],[(340,405)],[(85,125),(264,288)],[(410,510),(410,510)],[(80,140),(165,205)],[(530,574),(65,95)],[(65,95),(530,576)],[(-55,110),(-55,110)],[(math.hypot(500,520)-110,math.hypot(500,520)+55)]*2,[]]
assert len(pages)==len(views)==len(context_ranges)==14
clip_axis=godot_vector((0,0,1))
clip_datum=sum(a*b for a,b in zip(clip_axis,[-.54,.48,-.8]))
for page,diagrams,ranges in zip(pages,views,context_ranges):
    for view,(low,high) in zip(diagrams,ranges):
        view['clip_axis']=clip_axis
        view['clip_range']=[clip_datum+low/1000,clip_datum+high/1000]
    page['diagram_views']=diagrams
for n,page in enumerate(parent_pages[:2],1):
    receiver=uid('FA-103' if n==1 else 'FA-200')
    page['diagram_views']=[diagram('FA-220 • '+('cradle' if n==1 else 'ring'),[parent[s]['pose_source'] for s in page['slots']],[receiver],(1,1,1))]
parent_pages[2]['diagram_views']=[diagram('Base • pin and keeper',[uid('FA-220'),uid('FA-221'),uid('FA-222')]+fasts('base-keeper'),[uid('FA-525'),uid('FA-526'),uid('FA-527'),uid('FA-103')],(2,1,.5)),diagram('Rod • pin and keeper',[uid('FA-220',2),uid('FA-221',2),uid('FA-222',2)]+fasts('rod-keeper'),[uid('FA-525',2),uid('FA-526',2),uid('FA-527',2),uid('FA-200')],(2,1,.5))]

# Overlay uses shared pad definitions and part types at load time.
overlay=dict(version=1,parts=parts,assemblies=dict(pitch_actuator=actuator,foot=foot))
for name,data in [('pitch-actuator-definitions.json',overlay),('pitch-workshop.json',base)]:
    (ASSETS/name).write_text(json.dumps(data,indent=2,ensure_ascii=False)+'\n')
print('Authored 91 actuator pieces + 18 mounting pieces + 26 pad pieces = 135')
