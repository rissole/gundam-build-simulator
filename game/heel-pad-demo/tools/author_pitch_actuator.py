"""Author the pitch workshop from exact source identities; no mesh regeneration.
Run from any directory. Prerequisites below follow access/closure, not animation phases.
"""
import json
from pathlib import Path
ROOT = Path(__file__).resolve().parents[3]
ASSETS = ROOT / 'game/heel-pad-demo/assets'
manifest = json.loads((ROOT / 'models/foot-fa01/output/parts-manifest.json').read_text())['parts']
start = next(i for i, p in enumerate(manifest) if p['label'] == 'P Barrel')
end = next(i for i, p in enumerate(manifest) if p['label'] == 'R Barrel')
source = manifest[start:end]
assert len(source) == 109
by_id = {p['instance_id']: p for p in source}
def uid(family, n=1): return f'{family}__{n:03}'
parts = {}
instances = []
for p in source:
    family = p['part_id']
    # Geometrically different halves/eyes/clevises must not become interchangeable.
    kind = p['instance_id'].lower() if family.startswith('FA-') else family.lower()
    if family == 'W-24': kind = 'washer'
    if kind not in parts:
        title = p['label'].removeprefix('P ') if family.startswith('FA-') else {'W-12':'M12 washer','W-24':'M24 washer','H-12030':'M12 × 30 screw','H-12040':'M12 × 40 screw','H-12050':'M12 × 50 cap screw','H-24070':'M24 × 70 clevis bolt'}[family]
        parts[kind] = dict(family=family, variant='pitch-'+p['instance_id'] if family.startswith('FA-') else 'standard', title=family+' · '+title, short_title=title, carry_class='two_hand' if family in ['FA-510','FA-516','FA-518','FA-220'] else ('hand' if family in ['FA-511','FA-512','FA-513','FA-514','FA-517','FA-519','FA-521','FA-525','FA-526','FA-221'] else 'pocket'))
    instances.append(dict(instance_id=p['instance_id'],part_id=family,kind=kind))
kinds = {p['instance_id']: p['kind'] for p in instances}
slots = {}; pages = []; last = ['base']
def slot(id, requires):
    sid = 'base' if id == uid('FA-510') else id
    slots[sid] = dict(accepts=kinds[id],requires=requires,pose_source=id,label=parts[kinds[id]]['short_title'])
    return sid
slot(uid('FA-510'), [])
def page(title, body, components, hardware=()):
    global last
    current = []
    for id in components: current.append(slot(id, list(last)))
    for family, nums in hardware:
        for n in nums:
            screw = uid(family,n)
            index = next(i for i,p in enumerate(source) if p['instance_id']==screw)
            washer = source[index+1]['instance_id']
            assert washer.startswith('W-')
            w = slot(washer,list(current[:len(components)]) or list(last))
            current += [w,slot(screw,[w])]
    pages.append(dict(title=title,body=body,slots=current,view='components'))
    last = current
page('Motor','FA-510 starts beside preparation C. Suspend it there, then fit FA-513 on its rear seat. Secure it through the four access cutouts with W-12 and H-12040.',[uid('FA-513')],[('H-12040',range(5,9))])
page('Reduction drive','Seat FA-514 (gearbox) on the already fitted FA-513 flange. Add four W-12 washers and four H-12040 screws in the exposed upper holes.',[uid('FA-514')],[('H-12040',range(9,13))])
page('Coupling & bearing','Fit FA-515 (coupling) and FA-522 (thrust bearing). Leave FA-515 unclamped.',[uid('FA-515'),uid('FA-522')])
page('Lead screw','Carry FA-516 (lead screw) from its shelf into the already fitted FA-522 bearing and FA-515 coupling. Clamp FA-515 with two W-12 washers and two H-12030 screws.',[uid('FA-516')],[('H-12030',range(23,25))])
page('Retain the shaft','Fit FA-523 (retainer) and both FA-524 collar halves. Secure FA-523 with W-12 and H-12040; secure FA-524 with W-12 and H-12030.',[uid('FA-523'),uid('FA-524'),uid('FA-524',2)],[('H-12040',range(15,17)),('H-12030',range(25,27))])
page('Travelling nut','Fit FA-517 (travelling nut) onto the already fitted FA-516 lead screw.',[uid('FA-517')])
page('Output rod','Carry FA-518 (output rod) from its shelf. Join it to the already fitted FA-517 travelling nut with two W-12 washers and two H-12040 screws.',[uid('FA-518')],[('H-12040',range(13,15))])
page('Guide key','Engage FA-521 (guide key) in the longitudinal slot of the already fitted FA-518 rod. Its offset ears attach to the FA-510 housing with two W-12 washers and two H-12030 screws; the rod slides along the key.',[uid('FA-521')],[('H-12030',range(27,29))])
page('End sensors','Seat both FA-528 probes in the FA-510 openings. Each external mounting flange takes W-12 and H-12030. Fit FA-530 in the round barrel port.',[uid('FA-528'),uid('FA-528',2),uid('FA-530')],[('H-12030',range(21,23))])
page('Front guide & seals','Slide FA-519 along the already fitted FA-518 rod into the FA-510 front shoulder. Place FA-520 on the rod and one FA-529 gasket on each barrel end.',[uid('FA-519'),uid('FA-520'),uid('FA-529'),uid('FA-529',2)])
page('Close the housing','Fit one FA-511 (front cap) and one FA-512 (rear cap). Secure each cap with four W-12 washers and four H-12050 screws.',[uid('FA-511'),uid('FA-512')],[('H-12050',range(1,9))])
page('Base eye','Fit FA-525 (base eye), FA-526 (base bearing), then FA-527 (base retaining ring). Secure FA-525 with two W-12 washers and H-12040 screws.',[uid('FA-525'),uid('FA-526'),uid('FA-527')],[('H-12040',range(1,3))])
page('Rod eye','Fit FA-525 (rod eye), FA-526 (rod bearing), then FA-527 (rod retaining ring). Secure FA-525 with two W-12 washers and H-12040 screws.',[uid('FA-525',2),uid('FA-526',2),uid('FA-527',2)],[('H-12040',range(3,5))])
# Within each eye, and guide/seal layer, enforce the explicitly illustrated order.
for chain in [[uid('FA-525'),uid('FA-526'),uid('FA-527')],[uid('FA-525',2),uid('FA-526',2),uid('FA-527',2)],[uid('FA-519'),uid('FA-520')]]:
    for a,b in zip(chain,chain[1:]): slots[b]['requires'].append(a)
assert len(slots)==91
pages.append(dict(title='Ready to install',body='FA-500-P is ready after all 91 pieces. Backspace opens the foot manual for installation.',slots=list(slots),view='prepared'))
actuator = dict(part_id='FA-500-P',title='FA-500-P · Pitch actuator',root_slot='base',bounds=[0.24,0.80,0.80],interaction='components',work_locations=['station'],slots=slots,milestones={'prepared':list(slots)},manual=pages)
foot = json.loads((ASSETS/'assembly-definitions.json').read_text())['assemblies']['foot']
foot['title']='Foot · pads and pitch actuator'
parent = foot['slots']
parent_pages=[]
def pslot(id, requires):
    sid='pitch/'+id
    parent[sid]=dict(accepts=kinds[id],requires=requires,pose_source=id,label=parts[kinds[id]]['short_title'],presentation="components")
    return sid
brackets=[]
for end,n in [('base',1),('rod',2)]:
    c=pslot(uid('FA-220',n),[]); group=[c]
    for j in range(13+(n-1)*2,15+(n-1)*2):
        s=uid('H-24070',j); i=next(i for i,p in enumerate(source) if p['instance_id']==s)
        w=pslot(source[i+1]['instance_id'],[c]); group += [w,pslot(s,[w])]
    brackets+=group
    receiver = 'FA-103' if n==1 else 'FA-200'
    parent_pages.append(dict(title=('Base' if n==1 else 'Ring')+' clevis',body=f'Carry FA-220 (clevis {n}) from its shelf and fit it to {receiver}. Secure it with two W-24 washers and two H-24070 bolts.',slots=group,view='components',child_slot='pitch',context_sources=[uid(receiver)]))
parent['pitch']=dict(assembly='pitch_actuator',milestone='prepared',requires=brackets,pose_source=uid('FA-510'),label='Pitch actuator',connections=[uid('FA-220'),uid('FA-220',2)])
group=['pitch']
for n in [1,2]:
    pin=pslot(uid('FA-221',n),['pitch']); keeper=pslot(uid('FA-222',n),[pin]); w=pslot(uid('W-12',52+n),[keeper]); screw=pslot(uid('H-12030',28+n),[w]); group +=[pin,keeper,w,screw]
parent_pages.append(dict(title='Seat & pin actuator',body='Carry the prepared FA-500-P and seat it here. At each end fit FA-221 (pin), FA-222 (keeper), W-12, then H-12030. Enter opens the FA-500-P manual.',slots=group,view='components',child_slot='pitch',context_sources=[uid('FA-220'),uid('FA-220',2)]))
foot['manual']+=parent_pages
foot['manual'][0]['title']='Foot workshop'
foot['manual'][0]['body']='Prepare both FA-302 heel pads and FA-500-P (pitch actuator). Follow each branch to install and secure it on the foot.'
foot['manual'][0]['slots']=list(parent)
foot['milestones']['pitch_secured']=brackets+group
foot['milestones']['complete']=list(parent)
base=json.loads((ASSETS/'heel-pads.json').read_text())
base['parts']+=instances
base['builds'].append(dict(id='pitch',definition='pitch_actuator',label='Pitch actuator',base=uid('FA-510'),home=[-6.4,0.235,0.4]))
base['mounts'].append(dict(id='pitch',source=uid('FA-510'),label='Pitch actuator'))
base['definitions']='res://assets/pitch-actuator-definitions.json'
base['context_storage_families']=['FA-400','FA-401','FA-402','FA-403','FA-404','FA-405']
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
def fasts(family,nums):
    ids=[]
    for n in nums:
        screw=uid(family,n); i=next(i for i,p in enumerate(source) if p['instance_id']==screw)
        ids += [source[i+1]['instance_id'],screw]
    return ids
barrel=uid('FA-510')
views=[
    [diagram('FA-513 • rear flange',pages[0]['slots'],[barrel],(1,1,.7))],
    [diagram('FA-514 → FA-513',pages[1]['slots'],[uid('FA-513'),barrel],(1,1,2))],
    [diagram('FA-515 • output shaft',[uid('FA-515')],[uid('FA-514')],(1,1,1)),diagram('FA-522 • housing seat',[uid('FA-522')],[barrel],(1,1,2))],
    [diagram('FA-516 into FA-515 • two clamps',[uid('FA-515')]+fasts('H-12030',range(23,25)),[uid('FA-516'),uid('FA-514'),uid('FA-522')],(1,2,.5))],
    [diagram('FA-523 • retainer',[uid('FA-523')]+fasts('H-12040',range(15,17)),[uid('FA-522'),uid('FA-516'),barrel],(1,1,2)),diagram('FA-524 • split collar',[uid('FA-524'),uid('FA-524',2)]+fasts('H-12030',range(25,27)),[uid('FA-516'),uid('FA-523')],(1,2,.5))],
    [diagram('FA-517 onto FA-516',[uid('FA-517')],[uid('FA-516')],(1,1,1))],
    [diagram('FA-518 → FA-517 • open screw pockets',fasts('H-12040',range(13,15)),[uid('FA-518'),uid('FA-517')],(1,1,2))],
    [diagram('FA-521 • rod slot',[uid('FA-521')],[uid('FA-518')],(2,1,.4)),diagram('FA-521 • housing ears',fasts('H-12030',range(27,29)),[uid('FA-521'),barrel],(2,-1,.3))],
    [diagram('FA-528 • both ends',[uid('FA-528')]+fasts('H-12030',[21]),[barrel],(2,1,.5)),diagram('FA-530 • barrel port',[uid('FA-530')],[barrel],(2,1,.5))],
    [diagram('FA-519 / FA-520',[uid('FA-519'),uid('FA-520'),uid('FA-529',2)],[barrel,uid('FA-518')],(1,1,1)),diagram('FA-529 • rear gasket',[uid('FA-529')],[barrel],(1,1,-1))],
    [diagram('FA-512 • rear cap',[uid('FA-512')]+fasts('H-12050',range(1,5)),[barrel,uid('FA-529')],(1,1,-2)),diagram('FA-511 • front cap',[uid('FA-511')]+fasts('H-12050',range(5,9)),[barrel,uid('FA-519'),uid('FA-520'),uid('FA-529',2)],(1,1,2))],
    [diagram('FA-525 • screws',[uid('FA-525')]+fasts('H-12040',range(1,3)),[uid('FA-512')],(2,1,-.8)),diagram('FA-526 / FA-527',[uid('FA-525'),uid('FA-526'),uid('FA-527')],[],(2,1,.3))],
    [diagram('FA-525 • screws',[uid('FA-525',2)]+fasts('H-12040',range(3,5)),[uid('FA-518')],(2,1,.8)),diagram('FA-526 / FA-527',[uid('FA-525',2),uid('FA-526',2),uid('FA-527',2)],[],(2,1,.3))],
    [diagram('FA-500-P • prepared',list(slots_source['pose_source'] for slots_source in slots.values()),[],(1,1,.25))]
]
for n in (1,2):
    views[10+n][0]['offsets']={}
    views[10+n][1]['offsets']={uid('FA-526',n):[.075,0,0],uid('FA-527',n):[.12,0,0]}
views[-1][0]['offsets']={}
views[7][0]['offsets']={uid('FA-521'):godot_vector((0,.025,0))}
views[7][0]['context_padding']=.05
context_ranges=[[(85,165)],[(145,220)],[(182,245),(245,274)],[(192,250)],[(250,285),(276,310)],[(330,380)],[(340,405)],[(410,510),(410,510)],[(80,140),(165,205)],[(530,574),(65,95)],[(65,95),(530,576)],[(-55,110),(-55,110)],[(math.hypot(500,520)-110,math.hypot(500,520)+55)]*2,[]]
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
parent_pages[2]['diagram_views']=[diagram('Base • pin and keeper',[uid('FA-220'),uid('FA-221'),uid('FA-222')]+fasts('H-12030',[29]),[uid('FA-525'),uid('FA-526'),uid('FA-527'),uid('FA-103')],(2,1,.5)),diagram('Rod • pin and keeper',[uid('FA-220',2),uid('FA-221',2),uid('FA-222',2)]+fasts('H-12030',[30]),[uid('FA-525',2),uid('FA-526',2),uid('FA-527',2),uid('FA-200')],(2,1,.5))]

# Overlay uses shared pad definitions and part types at load time.
overlay=dict(version=1,parts=parts,assemblies=dict(pitch_actuator=actuator,foot=foot))
for name,data in [('pitch-actuator-definitions.json',overlay),('pitch-workshop.json',base)]:
    (ASSETS/name).write_text(json.dumps(data,indent=2,ensure_ascii=False)+'\n')
print('Authored 91 actuator pieces + 18 mounting pieces + 26 pad pieces = 135')
