"""Author the pitch workshop from exact source identities; no mesh regeneration.
Run from any directory. Prerequisites below follow access/closure, not animation phases.
"""
import json
import sys
from pathlib import Path
ROOT = Path(__file__).resolve().parents[3]
ASSETS = ROOT / 'game/heel-pad-demo/assets'
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
kinds = {p['instance_id']: p['kind'] for p in instances}
slots = {}; pages = []; last = ['base']
def slot(id, requires):
    sid = 'base' if id == uid('FA-513') else id
    slots[sid] = dict(accepts=kinds[id],requires=requires,pose_source=id,label=parts[kinds[id]]['short_title'])
    return sid
slot(uid('FA-513'), [])
def page(title, body, components, hardware=()):
    global last
    current = []
    for id in components: current.append(slot(id, list(last)))
    for connection in hardware:
        for screw, washer in pitch_pairs(connection):
            assert by_id[screw]['paired_instance_id'] == washer
            assert by_id[washer]['paired_instance_id'] == screw
            w = slot(washer,list(current[:len(components)]) or list(last))
            current += [w,slot(screw,[w])]
    pages.append(dict(title=title,body=body,slots=current,view='components'))
    last = current
page('Drive cartridge','Start with FA-513 (motor) beside preparation C. Place it in the fixture, seat FA-514 on its flange, then fit four W-12 washers and four H-12040 screws in the upper holes.',[uid('FA-514')],['gearbox'])
page('Coupling & bearing','Fit FA-515 on the already fitted FA-514 output shaft. Position FA-522 in the preparation fixture; the fixture supports the exposed drive while you assemble it. Leave FA-515 unclamped.',[uid('FA-515'),uid('FA-522')])
page('Lead screw','Carry FA-516 (lead screw) from its shelf into the already fitted FA-522 bearing and FA-515 coupling. Clamp FA-515 with two W-12 washers and two H-12030 screws.',[uid('FA-516')],['coupling'])
page('Retain the shaft','Seat FA-523 against the already fitted FA-522 bearing. Fit the FA-524 receiver collar half and clearance collar half around the shaft. Fit two W-12 washers and H-12030 screws through the clearance half into the receiver half.',[uid('FA-523'),uid('FA-524'),uid('FA-524',2)],['collar'])
page('Travelling nut','Fit FA-517 (travelling nut) onto the already fitted FA-516 lead screw.',[uid('FA-517')])
page('Output rod','Carry FA-518 (output rod) from its shelf. Join it to the already fitted FA-517 travelling nut with two W-12 washers and two H-12040 screws.',[uid('FA-518')],['rod'])
page('Enclose the drive','Fit FA-510 around the exposed drive held by the preparation fixture. From the open rear end, secure the already fitted FA-513 motor with four W-12 and H-12040 pairs. Secure the already fitted FA-523 retainer from outside the housing with two more pairs.',[uid('FA-510')],['motor','retainer'])
page('Guide key','Engage FA-521 (guide key) in the longitudinal slot of the already fitted FA-518 rod. Its offset ears attach to the FA-510 housing with two W-12 washers and two H-12030 screws; the rod slides along the key.',[uid('FA-521')],['guide'])
page('End sensors','Seat both FA-528 probes in the FA-510 openings. Each external mounting flange takes W-12 and H-12030. Fit FA-530 in the round barrel port.',[uid('FA-528'),uid('FA-528',2),uid('FA-530')],['rear-sensor','front-sensor'])
page('Front guide & seals','Slide FA-519 along the already fitted FA-518 rod into the FA-510 front shoulder. Place FA-520 on the rod. Fit the FA-529 rear cap gasket, with its extra clearance holes, at the motor end; fit the front cap gasket at the rod end.',[uid('FA-519'),uid('FA-520'),uid('FA-529'),uid('FA-529',2)])
page('Close the housing','Fit one FA-511 (front cap) and one FA-512 (rear cap). Secure each cap with four W-12 washers and four H-12050 screws.',[uid('FA-511'),uid('FA-512')],['rear-cap','front-cap'])
page('Base eye','Fit FA-525 (base eye housing), one FA-526 spherical eye bearing, then one FA-527 eye retaining ring. Secure the housing with two W-12 washers and H-12040 screws.',[uid('FA-525'),uid('FA-526'),uid('FA-527')],['base-eye'])
page('Rod eye','Fit FA-525 (rod eye housing), one FA-526 spherical eye bearing, then one FA-527 eye retaining ring. Secure the housing with two W-12 washers and H-12040 screws.',[uid('FA-525',2),uid('FA-526',2),uid('FA-527',2)],['rod-eye'])
# Within each eye, and guide/seal layer, enforce the explicitly illustrated order.
for chain in [[uid('FA-525'),uid('FA-526'),uid('FA-527')],[uid('FA-525',2),uid('FA-526',2),uid('FA-527',2)],[uid('FA-519'),uid('FA-520')]]:
    for a,b in zip(chain,chain[1:]): slots[b]['requires'].append(a)
assert len(slots)==91
pages.append(dict(title='Ready to install',body='FA-500-P is ready after all 91 pieces. Open the parent foot manual for installation.',slots=list(slots),view='prepared'))
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
    parent_pages.append(dict(title=clevis_name,body=f'Carry FA-220 ({clevis_name.lower()}) from its shelf and fit it to {receiver}. Secure it with two W-24 washers and two H-24070 bolts.',slots=group,view='components',child_slot='pitch',context_sources=[uid(receiver)]))
parent['pitch']=dict(assembly='pitch_actuator',milestone='prepared',requires=brackets,pose_source=uid('FA-510'),label='Pitch actuator',service_access='assisted',connections=[uid('FA-220'),uid('FA-220',2)])
group=['pitch']
for n in [1,2]:
    screw_id, washer_id = pitch_pairs('base-keeper' if n==1 else 'rod-keeper')[0]
    pin=pslot(uid('FA-221',n),['pitch']); keeper=pslot(uid('FA-222',n),[pin]); w=pslot(washer_id,[keeper]); screw=pslot(screw_id,[w]); group +=[pin,keeper,w,screw]
parent_pages.append(dict(title='Seat & pin actuator',body='Carry the prepared FA-500-P and seat it here. At each end fit FA-221 (pin), FA-222 (keeper), W-12, then H-12030. The FA-500-P child manual covers its preparation.',slots=group,view='components',child_slot='pitch',context_sources=[uid('FA-220'),uid('FA-220',2)]))
foot['manual']+=parent_pages
foot['manual'][0]['title']='Foot workshop'
foot['manual'][0]['body']='Prepare both FA-302 heel pads and FA-500-P (pitch actuator). Follow each branch to install and secure it on the foot.'
foot['manual'][0]['slots']=list(parent)
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
