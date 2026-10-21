"""Merge a Blender pitch-only export without re-exporting shared game geometry.
Run export_pitch_revision.py in Blender first. Non-pitch node/mesh/accessor data
and binary bytes are retained exactly; IDs and inventory allocations are stable.
"""
import argparse,copy,hashlib,json,struct
from pathlib import Path
ROOT=Path(__file__).resolve().parents[3]
GAME=ROOT/'game/heel-pad-demo'
TARGET=GAME/'assets/foot-fa01.glb'

def read(path):
    raw=path.read_bytes();jlen=struct.unpack_from('<I',raw,12)[0]
    data=json.loads(raw[20:20+jlen]);off=20+jlen
    blen=struct.unpack_from('<I',raw,off)[0]
    return data,raw[off+8:off+8+blen]
def uid(node):return '__'.join(node.get('name','').split('__')[:2])

def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--base',type=Path,default=TARGET,help='Explicit baseline for repeated repair iterations; defaults to current game asset.')
    args=parser.parse_args()
    old_hash=hashlib.sha256(args.base.read_bytes()).hexdigest()
    base,bb=read(args.base);new,nb=read(ROOT/'models/foot-fa01/output/pitch-revision.glb')
    original=copy.deepcopy(base)
    assert not base.get('animations') and not new.get('animations')
    counts={k:len(base.get(k,[])) for k in ('materials','meshes','accessors','bufferViews')}
    for m in new.get('materials',[]):base.setdefault('materials',[]).append(m)
    for view in new['bufferViews']:
        view['buffer']=0;view['byteOffset']=view.get('byteOffset',0)+len(bb)
        base['bufferViews'].append(view)
    for a in new['accessors']:
        assert 'sparse' not in a
        if 'bufferView' in a:a['bufferView']+=counts['bufferViews']
        base['accessors'].append(a)
    for mesh in new['meshes']:
        for p in mesh['primitives']:
            p['attributes']={k:v+counts['accessors'] for k,v in p['attributes'].items()}
            if 'indices' in p:p['indices']+=counts['accessors']
            if 'material' in p:p['material']+=counts['materials']
        base['meshes'].append(mesh)
    updates={uid(n):n for n in new['nodes'] if 'mesh' in n}
    changed=[]
    for i,node in enumerate(base['nodes']):
        if uid(node) not in updates:continue
        replacement=updates[uid(node)].copy();replacement['mesh']+=counts['meshes']
        assert not replacement.get('children')
        base['nodes'][i]=replacement;changed.append(uid(node))
    assert len(changed)==len(updates)==111
    assert all(n==base['nodes'][i] for i,n in enumerate(original['nodes']) if uid(n) not in updates)
    for k in counts:assert base[k][:counts[k]]==original[k]
    binary=bb+nb;base['buffers']=[{'byteLength':len(binary)}]
    encoded=json.dumps(base,separators=(',',':')).encode();encoded+=b' '*((-len(encoded))%4)
    binary+=b'\x00'*((-len(binary))%4)
    raw=struct.pack('<III',0x46546c67,2,28+len(encoded)+len(binary))+struct.pack('<II',len(encoded),0x4e4f534a)+encoded+struct.pack('<II',len(binary),0x004e4942)+binary
    TARGET.write_bytes(raw)
    audit={'passed':True,'input_sha256':old_hash,'output_sha256':hashlib.sha256(raw).hexdigest(),'replaced_instances':changed,'unchanged_instance_count':len(original['nodes'])-len(changed),'preserved_original_binary_bytes':len(bb),'proof':'Unselected nodes and all original mesh/material/accessor/buffer-view records are equal; original binary prefix retained verbatim.'}
    path=GAME/'verification/pitch-reuse-audit.json';path.parent.mkdir(exist_ok=True);path.write_text(json.dumps(audit,indent=2)+'\n')
    print('Replaced',len(changed),'pitch instances; preserved all unrelated nodes and mesh bytes.')
if __name__=='__main__':main()
