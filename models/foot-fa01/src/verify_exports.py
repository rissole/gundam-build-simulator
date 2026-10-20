"""Inspect GLB binary data and the individual-part archive without Blender."""
import bisect
import hashlib
import json
import math
import struct
import zipfile
from pathlib import Path

OUT=Path(__file__).resolve().parents[1]/"output"
manifest=json.loads((OUT/"parts-manifest.json").read_text())
expected={p["instance_id"]:p for p in manifest["parts"]}


def glb(path):
    raw=path.read_bytes()
    magic,version,length=struct.unpack_from("<III",raw,0)
    assert magic==0x46546C67 and version==2 and length==len(raw)
    offset=12;doc=None;binary=None
    while offset<len(raw):
        size,kind=struct.unpack_from("<II",raw,offset)
        chunk=raw[offset+8:offset+8+size]
        if kind==0x4E4F534A:doc=json.loads(chunk)
        if kind==0x004E4942:binary=chunk
        offset+=8+size
    assert doc is not None and binary is not None
    return doc,binary


def accessor(doc,binary,index):
    a=doc["accessors"][index]
    view=doc["bufferViews"][a["bufferView"]]
    n={"SCALAR":1,"VEC2":2,"VEC3":3,"VEC4":4}[a["type"]]
    fmt={5126:"f",5125:"I",5123:"H",5121:"B"}[a["componentType"]]
    size=struct.calcsize("<"+fmt)*n
    stride=view.get("byteStride",size)
    start=view.get("byteOffset",0)+a.get("byteOffset",0)
    return [struct.unpack_from("<"+fmt*n,binary,start+i*stride) for i in range(a["count"])]


def evaluate(times,values,mode,t):
    if t<=times[0]:return values[1] if mode=="CUBICSPLINE" else values[0]
    if t>=times[-1]:return values[-2] if mode=="CUBICSPLINE" else values[-1]
    i=bisect.bisect_right(times,t)-1
    dt=times[i+1]-times[i];u=(t-times[i])/dt
    if mode=="STEP":return values[i]
    if mode=="LINEAR":return tuple(a*(1-u)+b*u for a,b in zip(values[i],values[i+1]))
    p0=values[i*3+1];m0=values[i*3+2]
    p1=values[(i+1)*3+1];m1=values[(i+1)*3]
    return tuple((2*u**3-3*u*u+1)*a+(u**3-2*u*u+u)*dt*b+
                 (-2*u**3+3*u*u)*c+(u**3-u*u)*dt*d
                 for a,b,c,d in zip(p0,m0,p1,m1))


def converted(p):
    return p[0],p[2],-p[1]


def dist(a,b):
    return math.sqrt(sum((x-y)**2 for x,y in zip(a,b)))


report={}
for filename in ("foot-fa01-assembled.glb","foot-fa01-animated.glb"):
    path=OUT/filename;doc,binary=glb(path)
    nodes={i:n for i,n in enumerate(doc["nodes"]) if n.get("extras",{}).get("is_assembly_part")}
    ids={n["extras"]["instance_id"] for n in nodes.values()}
    assert ids==set(expected)
    assert len(nodes)==745 and len({n["mesh"] for n in nodes.values()})==745
    item={"part_nodes":len(nodes),"distinct_meshes":745,"sha256":hashlib.sha256(path.read_bytes()).hexdigest()}
    if "animated" in filename:
        assert len(doc["animations"])==1
        a=doc["animations"][0]
        channels={c["target"]["node"]:c for c in a["channels"] if c["target"]["path"]=="translation"}
        assert set(channels)==set(nodes)
        max_error=0;durations=[]
        for index,n in nodes.items():
            p=expected[n["extras"]["instance_id"]]
            sampler=a["samplers"][channels[index]["sampler"]]
            times=[v[0] for v in accessor(doc,binary,sampler["input"])]
            values=accessor(doc,binary,sampler["output"])
            mode=sampler.get("interpolation","LINEAR")
            assembled=converted(p["assembled_position_m"])
            exploded=converted([x+y for x,y in zip(p["assembled_position_m"],p["explosion_offset_m"])])
            errors=[
                dist(evaluate(times,values,mode,times[0]),exploded),
                dist(evaluate(times,values,mode,times[0]+439/24),assembled),
                dist(evaluate(times,values,mode,times[-1]),exploded)]
            max_error=max(max_error,*errors)
            durations.append(times[-1]-times[0])
        assert max_error<1e-4,max_error
        assert min(durations)>40 and max(durations)<42
        item.update({"animations":1,"animated_part_nodes":len(channels),
                     "maximum_pose_error_m":max_error,"duration_seconds":max(durations)})
    else:
        errors=[dist(n.get("translation",(0,0,0)),converted(expected[n["extras"]["instance_id"]]["assembled_position_m"]))
                for n in nodes.values()]
        assert max(errors)<1e-4
        item.update({"animations":0,"maximum_pose_error_m":max(errors)})
    report[filename]=item
with zipfile.ZipFile(OUT/"individual-parts-745.zip") as z:
    assert z.testzip() is None
    objs={Path(n).stem:n for n in z.namelist() if n.endswith(".obj")}
    assert set(objs)==set(expected)
    for name in objs.values():
        content=z.read(name).decode()
        assert content.count("\nv ")>=8 and content.count("\nf ")>=6
    report["individual-parts-745.zip"]={"obj_files":745,"archive_integrity":"passed"}
report["passed"]=True
(OUT/"export-audit.json").write_text(json.dumps(report,indent=2)+"\n")
print(json.dumps(report,indent=2))
