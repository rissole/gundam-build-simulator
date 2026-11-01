"""Measured armor envelopes and bounded ankle vertex/edge sweep, in Blender.

Run on output/leg-lg01.blend with --python-exit-code 1. --only-leg permits an
explicit partial report while foot armor is in progress; default requires it.
Slices clip actual mesh edges at slab boundaries, not object bounding boxes.
"""
import argparse
import hashlib
import json
import math
from pathlib import Path
import sys
import bpy
import numpy as np
from mathutils import Matrix

OUT=Path(__file__).resolve().parents[1]/'output/audits'


def vertices(obj):
    return np.array([tuple(obj.matrix_world@v.co) for v in obj.data.vertices])


def geometry(objects):
    points=[]; edges=[]; offset=0
    for obj in objects:
        p=vertices(obj); points.append(p)
        edges.extend((a+offset,b+offset) for a,b in (e.vertices for e in obj.data.edges))
        offset+=len(p)
    return np.concatenate(points),np.array(edges,dtype=int)


def slab(points,edges,low,high):
    selected=[points[(points[:,2]>=low-1e-7)&(points[:,2]<=high+1e-7)]]
    a,b=points[edges[:,0]],points[edges[:,1]]
    dz=b[:,2]-a[:,2]
    for z in (low,high):
        crossing=(np.minimum(a[:,2],b[:,2])<z)&(np.maximum(a[:,2],b[:,2])>z)&(abs(dz)>1e-9)
        t=(z-a[crossing,2])/dz[crossing]
        selected.append(a[crossing]+t[:,None]*(b[crossing]-a[crossing]))
    p=np.concatenate(selected)
    if not len(p): return None
    return {'z_range_m':[float(low),float(high)],'min':p.min(0).tolist(),'max':p.max(0).tolist(),
            'width_m':float(np.ptp(p[:,0])),'depth_m':float(np.ptp(p[:,1]))}


def sweep(calf,guards):
    p,e=geometry(calf)
    # All vertices plus edge samples <=25 mm apart: a long facet cannot evade
    # a short ankle guard simply because both endpoint vertices lie outside it.
    cloud=[p]
    for a,b in e:
        if min(p[a,2],p[b,2])>2.65: continue
        count=max(1,math.ceil(float(np.linalg.norm(p[b]-p[a]))/.025))
        if count>1: cloud.append(np.linspace(p[a],p[b],count+1)[1:-1])
    p=np.concatenate(cloud); p=p[p[:,2]<=2.65]
    local=p-np.array([0,0,1.])
    # Guard wall inner faces are the FA-02 planes; confirm these exist in the
    # delivered guard meshes. Integral mounting feet are not the wall plane.
    measured=[]; guard_boxes=[]
    for obj in guards:
        v=vertices(obj); s=1 if v[:,0].mean()>0 else -1
        wall=v[(abs(abs(v[:,0])-.710)<.002)&(v[:,2]>.80)]
        if not len(wall):
            return {'passed':False,'error':'Cannot identify guard inner wall at |X|=.710','object':obj.name}
        inner=float(np.median(abs(wall[:,0])))
        measured.append(inner)
        # Conservative entire wall bounding prism, includes the empty chamfer
        # corners. Clearance to it is stronger than to just the drawn outline.
        guard_boxes.append((s,inner,float(v[:,1].min()),float(v[:,1].max()),.60,float(v[:,2].max())))
    if not guard_boxes: guard_boxes=[(s,.710,-.730,.950,.600,1.600) for s in (-1,1)]
    best=1e9; worst=None; inside=0
    for pitch in np.linspace(-20,20,81):
        for roll in np.linspace(-10,10,41):
            mat=np.array(Matrix.Rotation(math.radians(pitch),3,'X') @ Matrix.Rotation(math.radians(roll),3,'Y'))
            q=local@mat.T+np.array([0,0,1.])
            for s,x,ymin,ymax,zmin,zmax in guard_boxes:
                # Signed distance to a prism extending outboard indefinitely.
                dx=x-s*q[:,0]
                dy=np.maximum(ymin-q[:,1],q[:,1]-ymax)
                dz=np.maximum(zmin-q[:,2],q[:,2]-zmax)
                outside=np.sqrt(np.maximum(dx,0)**2+np.maximum(dy,0)**2+np.maximum(dz,0)**2)
                signed=np.where((dx<0)&(dy<0)&(dz<0),np.maximum.reduce([dx,dy,dz]),outside)
                idx=int(np.argmin(signed)); distance=float(signed[idx])
                inside+=int(np.sum(signed<0))
                if distance<best:
                    best=distance; worst={'pitch_deg':pitch,'roll_deg':roll,'side':s,'point_m':q[idx].tolist()}
    # Distance to a fixed set is 1-Lipschitz. A half-cell in each rotation can
    # move a point at most r*(0.25+0.25) degrees. Edge samples add <=12.5 mm.
    # This turns the finite grid into a conservative continuous vertex/edge
    # bound, without claiming that unsampled facet interiors were swept solids.
    angular_allowance=float(np.linalg.norm(local,axis=1).max())*math.radians(.5)
    conservative=best-angular_allowance-.0125
    return {'passed':conservative>0,'minimum_sampled_clearance_m':best,'worst_pose':worst,
            'continuous_vertex_edge_clearance_lower_bound_m':conservative,
            'angular_sampling_allowance_m':angular_allowance,'edge_sampling_allowance_m':.0125,
            'poses':3321,'samples_per_pose':len(p),'interior_samples':inside,
            'rotation':'Rx(pitch) @ Ry(roll) about (0,0,1); guards fixed to cradle',
            'guard_inner_faces_abs_x_m':measured or [.710,.710],
            'guard_source':'measured FA-02 walls' if guards else 'FA-02 dimensional contract; foot not yet present',
            'method':'vertices + <=25 mm edge samples, 0.5 degree grid, guard bounding prisms, Lipschitz sampling allowance',
            'limitation':'continuous vertex/edge clearance bound; not a complete swept-facet solid proof'}


def run(only_leg=False):
    objects=[o for o in bpy.context.scene.objects if o.type=='MESH' and o.get('part_id')]
    checks=[]; sections={}
    def check(name,value,low,high):
        checks.append({'check':name,'actual_m':float(value),'min_m':low,'max_m':high,
                       'passed':bool(low-1e-6<=value<=high+1e-6)})
    for name,subassembly,width,depth,lower in [('thigh','thigh',1.80,1.80,1.32),('calf','shin-calf',1.65,2.24,1.06)]:
        parts=[o for o in objects if o.get('subassembly')==subassembly and o.get('category') in {'armor','service'}]
        armor=[o for o in parts if o.get('category')=='armor']
        if not armor:
            checks.append({'check':name+' armor exists','passed':False}); continue
        p,e=geometry(parts); ap,ae=geometry(armor)
        lo,hi=p.min(0),p.max(0); zlo,zhi=ap[:,2].min(),ap[:,2].max()
        slices=[slab(p,e,z,min(z+.10,zhi)) for z in np.arange(zlo,zhi,.10)]
        bottom=slab(ap,ae,zlo,zlo+.30)
        widths=float(np.ptp(p[:,0])); depth_points=p
        # The calf depth contract includes the exposed nozzle mouths (C2).
        # Keep armor/service width, lower taper and sweep inputs unchanged.
        engines=[o for o in objects if name=='calf' and o.get('part_id')=='LG-450']
        if engines: depth_points=np.concatenate([p,geometry(engines)[0]])
        depths=float(np.ptp(depth_points[:,1]))
        sections[name]={'objects':[o['instance_id'] for o in parts],'bounds_min':lo.tolist(),'bounds_max':hi.tolist(),
                        'width_m':widths,'depth_m':depths,'target_width_m':width,'target_depth_m':depth,
                        'depth_bounds_y_m':[float(depth_points[:,1].min()),float(depth_points[:,1].max())],
                        'depth_includes_nozzles':bool(engines),
                        'lowest_300mm':bottom,'z_slices_100mm':slices}
        check(name+' maximum width target',widths,width-.10,width+.05)
        check(name+' maximum depth target',depths,depth-.10,depth+.05)
        check(name+' lowest 300mm width',bottom['width_m'],1.20 if name=='thigh' else lower-.10,lower+.05)
    foot=[o for o in objects if o.get('part_id','').startswith('FA-') and o.get('category') in {'armor','sole'}]
    guards=[o for o in foot if o.get('part_id') in {'FA-403-L','FA-404-L'}]
    required={'FA-400','FA-401-L','FA-402','FA-403-L','FA-404-L','FA-302','FA-303','FA-304'}
    complete=required.issubset({o['part_id'] for o in foot})
    if complete:
        p,e=geometry(foot); lo,hi=p.min(0),p.max(0)
        sections['foot']={'bounds_min':lo.tolist(),'bounds_max':hi.tolist(),'width_m':float(hi[0]-lo[0]),
                          'length_m':float(hi[1]-lo[1])}
        check('foot length',hi[1]-lo[1],3.26,3.41); check('foot width',hi[0]-lo[0],1.36,1.51)
        check('foot heel',lo[1],-.95,-.85); check('foot toe',hi[1],2.41,2.51)
        for obj in guards: check(obj['part_id']+' top',vertices(obj)[:,2].max(),1.55,1.65)
        shell=[o for o in foot if o not in guards]
        check('foot shell height',geometry(shell)[0][:,2].max(),.60,.75)
    elif not only_leg: checks.append({'check':'complete foot armor and sole rows present','passed':False})
    lower=[o for o in objects if o.get('subassembly')=='shin-calf' and o.get('category') in {'armor','service'}]
    sweep_report=sweep(lower,guards) if lower else {'passed':False,'error':'missing calf armor'}
    checks.append({'check':'lower calf vs ankle guards swept clearance',**sweep_report})
    # Support faces must remain accessible after mounting armor.
    from mathutils import Vector
    legarmor=[o for o in objects if o.get('category')=='armor' and o.get('part_id','').startswith('LG-')]
    for z,ys in [(6.10,(-.08,.03,.14)),(2.80,(-.10,0,.10))]:
        for s in (-1,1):
            hits=[]
            for y in ys:
                for dz in (-.08,0,.08):
                    start=Vector((s*1.3,y,z+dz)); direction=Vector((-s,0,0))
                    for obj in legarmor:
                        inv=obj.matrix_world.inverted()
                        hit,*_=obj.ray_cast(inv@start,inv.to_3x3()@direction,distance=.495)
                        if hit: hits.append(obj['part_id'])
            checks.append({'check':f'handling pad access Z{z} side{s}','passed':not hits,'blocking_parts':sorted(set(hits))})
    # Neutral hip cartridge corridors from the specified lower eyes to the
    # mirrored R780 upper eyes. Full hip motion is owned by the torso packet.
    channels=[('outer front',(-.339,.339,7.40),(-.780,0,8.60)),
              ('inner front',(.464,.124,7.40),(.390,.67550,8.60)),
              ('inner rear',(-.124,-.464,7.40),(.390,-.67550,8.60))]
    thigharmor=[o for o in legarmor if o.get('subassembly')=='thigh']
    for label,lower_eye,upper_eye in channels:
        a,b=Vector(lower_eye),Vector(upper_eye); direction=(b-a).normalized()
        u=direction.cross(Vector((0,1,0))).normalized();v=direction.cross(u)
        offsets=[Vector((0,0,0))]+[.08*(u*math.cos(t*math.tau/16)+v*math.sin(t*math.tau/16)) for t in range(16)]
        hits=[]
        for offset in offsets:
            for obj in thigharmor:
                inv=obj.matrix_world.inverted()
                hit,*_=obj.ray_cast(inv@(a+offset),inv.to_3x3()@direction,distance=(b-a).length)
                if hit:hits.append(obj['part_id'])
        checks.append({'check':'neutral hip rod channel '+label,'passed':not hits,
                       'corridor_radius_m':.08,'rays':17,'blocking_parts':sorted(set(hits)),
                       'scope':'neutral cartridge only; complete articulated hip sweep remains open'})
    # A front shield must not silently close the centre rear of the knee.
    rear_hits=[]
    for x in (-.15,0,.15):
        for z in (4.85,5.10,5.35):
            for obj in legarmor:
                inv=obj.matrix_world.inverted()
                hit,*_=obj.ray_cast(inv@Vector((x,-1.5,z)),inv.to_3x3()@Vector((0,1,0)),distance=1.15)
                if hit:rear_hits.append(obj['part_id'])
    checks.append({'check':'central rear knee stays open','passed':not rear_hits,'blocking_parts':sorted(set(rear_hits))})
    info=[{'severity':'INFO','section':name,'transport_bound_abs_x_m':.80,
           'excess_m':max(0,max(abs(section['bounds_min'][0]),abs(section['bounds_max'][0]))-.80)}
          for name,section in sections.items() if name!='foot']
    return {'audit':'armor-envelopes','units':'metres','scope':'leg-only' if only_leg else 'leg-and-foot',
            'passed':all(c['passed'] for c in checks),'sections':sections,'checks':checks,'information':info}


def main():
    parser=argparse.ArgumentParser(); parser.add_argument('--only-leg',action='store_true')
    args=parser.parse_args(sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else [])
    report=run(args.only_leg); report['blend']=bpy.data.filepath
    report['blend_sha256']=hashlib.sha256(Path(bpy.data.filepath).read_bytes()).hexdigest()
    OUT.mkdir(parents=True,exist_ok=True); (OUT/'envelopes.json').write_text(json.dumps(report,indent=2)+'\n')
    failed=[c for c in report['checks'] if not c['passed']]
    print('ENVELOPES:', 'PASS' if report['passed'] else 'FAIL',len(failed),'failures')
    for item in failed: print(item)
    if failed: raise SystemExit(1)


if __name__=='__main__': main()
