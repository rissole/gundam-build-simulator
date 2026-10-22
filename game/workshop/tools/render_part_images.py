"""Bake small catalogue images from the unchanged GLB, without opening a window.
Pure Python + Pillow; orthographic triangle rendering, shared by drawers and HUD.
"""
import json, math, struct
from pathlib import Path
from PIL import Image, ImageDraw
ASSETS = Path(__file__).resolve().parents[1] / 'assets'
raw = (ASSETS/'foot-fa01.glb').read_bytes()
length, kind = struct.unpack_from('<II',raw,12)
gltf = json.loads(raw[20:20+length])
binary = raw[28+length:]
def accessor(index):
    a=gltf['accessors'][index];v=gltf['bufferViews'][a['bufferView']]
    n={'SCALAR':1,'VEC2':2,'VEC3':3,'VEC4':4}[a['type']]
    fmt={5121:'B',5123:'H',5125:'I',5126:'f'}[a['componentType']]
    size=struct.calcsize('<'+fmt*n);stride=v.get('byteStride',size)
    offset=v.get('byteOffset',0)+a.get('byteOffset',0)
    return [struct.unpack_from('<'+fmt*n,binary,offset+i*stride) for i in range(a['count'])]
def unit(v):
    length=math.sqrt(sum(x*x for x in v))
    return tuple(x/length for x in v) if length else (0,0,0)
def dot(a,b):return sum(x*y for x,y in zip(a,b))
def sub(a,b):return tuple(x-y for x,y in zip(a,b))
def cross(a,b):return (a[1]*b[2]-a[2]*b[1],a[2]*b[0]-a[0]*b[2],a[0]*b[1]-a[1]*b[0])
look=unit((0.8,1.2,1.7));right=unit(cross((0,1,0),look));up=cross(look,right);light=unit((-0.5,1.0,1.2))
scenario=json.loads((ASSETS/'pitch-workshop.json').read_text())
source={p['kind']:p['instance_id'] for p in scenario['parts']}
nodes={'__'.join(n.get('name','').split('__')[:2]):n for n in gltf['nodes'] if 'mesh' in n}
output=ASSETS/'part-images';output.mkdir(exist_ok=True)
for kind,uid in source.items():
    triangles=[]; all_points=[]
    for prim in gltf['meshes'][nodes[uid]['mesh']]['primitives']:
        points=accessor(prim['attributes']['POSITION']);indices=[x[0] for x in accessor(prim['indices'])]
        projected=[(dot(p,right),dot(p,up),dot(p,look)) for p in points]
        all_points+=projected
        color=gltf.get('materials',[])[prim.get('material',0)].get('pbrMetallicRoughness',{}).get('baseColorFactor',[0.65,0.75,0.80,1])
        for i in range(0,len(indices),3):
            a,b,c=[indices[i+j] for j in range(3)];normal=unit(cross(sub(points[b],points[a]),sub(points[c],points[a])))
            # Keep back faces too, so washers and other open surfaces stay legible.
            shade=0.42+0.58*max(0,dot(normal,light))
            rgb=tuple(max(25,min(255,int((v**(1/2.2))*255*shade))) for v in color[:3])+(255,)
            face=[projected[j] for j in [a,b,c]]
            triangles.append((sum(p[2] for p in face)/3,face,rgb))
    xmin=min(p[0] for p in all_points);xmax=max(p[0] for p in all_points)
    ymin=min(p[1] for p in all_points);ymax=max(p[1] for p in all_points)
    size=512;scale=440/max(xmax-xmin,ymax-ymin);cx=(xmin+xmax)/2;cy=(ymin+ymax)/2
    im=Image.new('RGBA',(size,size));draw=ImageDraw.Draw(im)
    for _,face,color in sorted(triangles,key=lambda t:t[0]):draw.polygon([(256+(p[0]-cx)*scale,256-(p[1]-cy)*scale) for p in face],fill=color)
    im.resize((192,192),Image.Resampling.LANCZOS).save(output/(kind+'.png'))
print('Baked',len(source),'source-mesh catalogue images')
