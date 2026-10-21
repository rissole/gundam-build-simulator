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
page('Motor','Pick up FA-510 (barrel) from the floor beside preparation C with E, then click the station to suspend it. Carry FA-513 (motor) from its shelf; fit four W-12 washers and four H-12040 screws. The barrel becomes translucent for internal work.',[uid('FA-513')],[('H-12040',range(5,9))])
page('Reduction drive','Fit FA-514 (gearbox), then four W-12 washers and four H-12040 screws.',[uid('FA-514')],[('H-12040',range(9,13))])
page('Coupling & bearing','Fit FA-515 (coupling) and FA-522 (thrust bearing). Leave FA-515 unclamped.',[uid('FA-515'),uid('FA-522')])
page('Lead screw','Carry FA-516 (lead screw) from its shelf into the already fitted FA-522 bearing and FA-515 coupling. Clamp FA-515 with two W-12 washers and two H-12030 screws.',[uid('FA-516')],[('H-12030',range(23,25))])
page('Retain the shaft','Fit FA-523 (retainer) and both FA-524 collar halves. Secure FA-523 with W-12 and H-12040; secure FA-524 with W-12 and H-12030.',[uid('FA-523'),uid('FA-524'),uid('FA-524',2)],[('H-12040',range(15,17)),('H-12030',range(25,27))])
page('Travelling nut','Fit FA-517 (travelling nut) onto the already fitted FA-516 lead screw.',[uid('FA-517')])
page('Output rod','Carry FA-518 (output rod) from its shelf. Join it to the already fitted FA-517 travelling nut with two W-12 washers and two H-12040 screws.',[uid('FA-518')],[('H-12040',range(13,15))])
page('Guide key','Fit FA-521 (guide key) into the already fitted FA-518 output rod. Secure it with two W-12 washers and two H-12030 screws.',[uid('FA-521')],[('H-12030',range(27,29))])
page('End sensors','Fit both FA-528 end sensors and FA-530 (connector). Each FA-528 takes one W-12 washer and one H-12030 screw.',[uid('FA-528'),uid('FA-528',2),uid('FA-530')],[('H-12030',range(21,23))])
page('Front guide & seals','Fit FA-519 (guide bushing), then FA-520 (wiper), and both FA-529 gaskets.',[uid('FA-519'),uid('FA-520'),uid('FA-529'),uid('FA-529',2)])
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
    receiver = 'FA-200' if n==1 else 'FA-201'
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
# Overlay uses shared pad definitions and part types at load time.
overlay=dict(version=1,parts=parts,assemblies=dict(pitch_actuator=actuator,foot=foot))
for name,data in [('pitch-actuator-definitions.json',overlay),('pitch-workshop.json',base)]:
    (ASSETS/name).write_text(json.dumps(data,indent=2,ensure_ascii=False)+'\n')
print('Authored 91 actuator pieces + 18 mounting pieces + 26 pad pieces = 135')
