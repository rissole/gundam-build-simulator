"""Measure actual scene vertices, bores and bearing planes (10 mm tolerance).

Feature vertex groups select manufactured surfaces, not locator empties. Tests
derive bounds/circle fits from those vertices and ray-test complete part meshes
to catch obstructed holes. No stored dimensional custom property is accepted as
measurement. Foot checks() is called when supplied by the parallel foot module.
"""
import argparse
import hashlib
import importlib.util
import json
import math
from pathlib import Path
import sys
import bpy
import numpy as np
from mathutils import Vector

SRC=Path(__file__).resolve().parent
sys.path.insert(0,str(SRC))
TOL=.010


def objects(pid,name=None):
    return sorted([o for o in bpy.context.scene.objects if o.get('part_id')==pid and
                   (name is None or o.get('part_name')==name)],key=lambda o:o['instance_id'])


def vertices(obj,label=None):
    if label is None: return np.array([tuple(obj.matrix_world@v.co) for v in obj.data.vertices])
    group=obj.vertex_groups.get('interface.'+label)
    if group is None: raise ValueError(f'{obj.name}: missing interface group {label}')
    points=[tuple(obj.matrix_world@v.co) for v in obj.data.vertices
            if any(g.group==group.index and g.weight>.5 for g in v.groups)]
    if not points: raise ValueError(f'{obj.name}: empty interface group {label}')
    return np.array(points)


def basis(axis):
    w=np.array(axis,dtype=float); w/=np.linalg.norm(w)
    ref=np.array((0,0,1) if abs(w[2])<.9 else (0,1,0))
    u=np.cross(ref,w); u/=np.linalg.norm(u)
    return u,np.cross(w,u),w


class Audit:
    def __init__(self): self.results=[]

    def value(self,name,measured,expected,tol=TOL):
        m,e=np.array(measured,dtype=float),np.array(expected,dtype=float)
        error=float(np.max(np.abs(m-e)))
        self.results.append({'check':name,'passed':bool(np.isfinite(m).all() and error<=tol+1e-6),
                             'measured':m.tolist(),'expected':e.tolist(),'error_m':error,'tolerance_m':tol})

    def condition(self,name,passed,**detail):
        self.results.append({'check':name,'passed':bool(passed),**detail})

    def bounds(self,name,obj,label,lo,hi):
        p=vertices(obj,label)
        self.value(name+' minimum',p.min(axis=0),lo)
        self.value(name+' maximum',p.max(axis=0),hi)

    def ring(self,name,obj,label,center,axis,outer,inner,length):
        p=vertices(obj,label); u,v,w=basis(axis); c=np.array(center)
        q=np.stack((p@u,p@v,p@w),axis=1)
        qc=(q.max(axis=0)+q.min(axis=0))/2
        measured=qc[0]*u+qc[1]*v+qc[2]*w
        self.value(name+' centre',measured,c)
        radial=np.sqrt((q[:,0]-qc[0])**2+(q[:,1]-qc[1])**2)
        self.value(name+' outer diameter',radial.max()*2,outer*2)
        self.value(name+' bore diameter',radial.min()*2,inner*2)
        self.value(name+' length',q[:,2].max()-q[:,2].min(),length)

    def hole(self,name,obj,label,center,axis,radius,span):
        """Fit both entry/exit rim circles; also prove a clear through tunnel."""
        p=vertices(obj,label); c=np.array(center); u,v,w=basis(axis)
        d=p-c; xy=np.stack((d@u,d@v),axis=1); axial=d@w
        rad=np.linalg.norm(xy,axis=1)
        selected=(abs(rad-radius)<.003)&(abs(axial)<span/2+.003)
        q=xy[selected]
        if len(q)<12:
            self.condition(name+' bore rims',False,vertices_found=len(q)); return
        # Least squares algebraic circle, using points on both cylindrical rims.
        A=np.column_stack((2*q[:,0],2*q[:,1],np.ones(len(q))))
        cx,cy,k=np.linalg.lstsq(A,np.sum(q*q,axis=1),rcond=None)[0]
        radius_fit=math.sqrt(max(0,k+cx*cx+cy*cy))
        self.value(name+' axis position',c+cx*u+cy*v,c)
        self.value(name+' bore diameter',2*radius_fit,2*radius)
        self.value(name+' axial rim span',[axial[selected].min(),axial[selected].max()],[-span/2,span/2])
        # Complete receiving solid, so an unrelated integral shell blocking the
        # nominal bore cannot pass just because circular rim vertices exist.
        inverse=obj.matrix_world.inverted(); direction=(inverse.to_3x3()@Vector(w)).normalized()
        clear=True; hits=[]
        for offset in (np.zeros(3),u*radius*.65,-u*radius*.65,v*radius*.65,-v*radius*.65):
            origin=c+offset-w*(span/2+.002)
            hit,loc,normal,index=obj.ray_cast(inverse@Vector(origin),direction,distance=span+.004)
            if hit: clear=False; hits.append(tuple(obj.matrix_world@loc))
        self.condition(name+' unobstructed tunnel',clear,hits=hits)


def leg_checks(a):
    for pid,count in [('LG-120',1),('LG-110',1),('LG-100',1),('LG-140',1),('LG-150',1),
                      ('LG-130',2),('LG-135',2),('LG-240',1),('LG-242',1),('LG-244',1),
                      ('LG-250',1),('LG-340',2),('LG-345',2),('LG-346',2),('LG-440',1),('LG-450',2)]:
        a.condition(pid+' instance count',len(objects(pid))==count,actual=len(objects(pid)),expected=count)
    spar=objects('LG-120')[0]; fork=objects('LG-110')[0]; shin=objects('LG-100')[0]
    a.bounds('Hip ball',spar,'hip_ball',[-.45,-.45,8.75],[.45,.45,9.65])
    a.bounds('Hip neck',spar,'neck',[-.15,-.15,8.335],[.15,.15,8.785])
    for name,low,high in [('lower',6.02,7.20),('upper',7.66,8.24)]:
        a.bounds('Thigh structural box '+name,spar,'thigh_box_'+name,
                 [-.33,-.285,low],[.33,.255,high])
    p=vertices(spar,'spar'); neck_section=p[p[:,2]>8.40]
    a.value('Upper spar interface section',np.ptp(neck_section,axis=0)[:2],[.30,.20])
    a.bounds('Spar flange',spar,'spar_flange',[-.34,-.30,5.920],[.34,.30,5.960])
    a.bounds('Fork flange',fork,'fork_flange',[-.34,-.30,5.880],[.34,.30,5.920])
    bolts=objects('LG-H24100','M24x100 knee fork bolt')
    washers=objects('W-24','M24 washer (knee fork)')
    a.condition('Four fork bolts',len(bolts)==4,actual=len(bolts))
    for i,(x,y) in enumerate([(x,y) for x in (-.25,.25) for y in (-.20,.20)]):
        a.hole(f'Spar bolt bore {i}',spar,'spar_flange',(x,y,5.94),(0,0,1),.013,.04)
        a.hole(f'Fork tapped bore {i}',fork,'fork_flange',(x,y,5.90),(0,0,1),.0105,.04)
        p=vertices(bolts[i]); center=(p.max(axis=0)+p.min(axis=0))/2
        a.value(f'Fork bolt {i} axis',center[:2],[x,y])
        a.value(f'Fork bolt {i} ends',[p[:,2].min(),p[:,2].max()],[5.864,5.9796])
        a.ring(f'Fork washer {i}',washers[i],'washer',(x,y,5.962),(0,0,1),.0228,.01284,.004)
    for i,s in enumerate((-1,1)):
        a.ring('Fork cheek '+str(s),fork,'fork_cheek_'+str(s),(s*.43,0,5.1),(1,0,0),.34,.105,.14)
        a.hole('Fork axle bore '+str(s),fork,'fork_cheek_'+str(s),(s*.43,0,5.1),(1,0,0),.105,.14)
        a.ring('Bearing '+str(s),objects('LG-130')[i],'bearing',(s*.21,0,5.1),(1,0,0),.149,.102,.120)
        a.ring('Spacer '+str(s),objects('LG-135')[i],'spacer',(s*.3175,0,5.1),(1,0,0),.180,.102,.075)
        a.bounds('Fork pad '+str(s),fork,'fork_pad_'+str(s),
                 [min(s*.79,s*.80),-.11,5.98],[max(s*.79,s*.80),.17,6.22])
        a.bounds('Shin pad '+str(s),shin,'shin_pad_'+str(s),
                 [min(s*.79,s*.80),-.14,2.69],[max(s*.79,s*.80),.14,2.91])
    a.ring('Shin knee boss',shin,'shin_boss',(0,0,5.1),(1,0,0),.28,.15,.56)
    a.hole('Shin knee bearing bore',shin,'shin_boss',(0,0,5.1),(1,0,0),.15,.56)
    axle=objects('LG-140')[0]
    a.bounds('Axle journal',axle,'axle_journal',[-.50,-.10,5.0],[.50,.10,5.2])
    a.bounds('Axle shoulder',axle,'axle_shoulder',[-.54,-.15,4.95],[-.50,.15,5.25])
    cap=objects('LG-150')[0]
    a.bounds('Axle cap',cap,'axle_cap',[.535,-.15,4.95],[.559,.15,5.25])
    for i,z in enumerate((5.015,5.185)):
        a.hole('Cap screw bore '+str(i),cap,'axle_cap',(.547,0,z),(1,0,0),.0065,.024)
        p=vertices(objects('H-12050','M12x50 axle cap screw')[i])
        a.value('Cap screw axis '+str(i),(p.max(axis=0)+p.min(axis=0))[1:]/2,[0,z])
        a.value('Cap screw ends '+str(i),[p[:,0].min(),p[:,0].max()],[.511,.5688])
        a.ring('Cap washer '+str(i),objects('W-12','M12 washer (axle cap)')[i],
               'washer',(.560,0,z),(1,0,0),.0114,.00642,.002)
    a.bounds('Shin flange',shin,'shin_flange',[-.27,-.22,1.38],[.27,.22,1.41])
    p=vertices(shin,'shin_beam')
    lower=p[p[:,2]<=2.1001]; upper=p[(p[:,2]>=2.4199)&(p[:,2]<=4.6801)]
    a.value('Shin ankle interface section',np.ptp(lower,axis=0)[:2],[.30,.20])
    a.value('Shin upper box section',np.ptp(upper,axis=0)[:2],[.64,.62])
    for i,(x,y) in enumerate([(x,y) for x in (-.20,.20) for y in (-.15,.15)]):
        a.hole('Shin flange bore '+str(i),shin,'shin_flange',(x,y,1.395),(0,0,1),.019,.030)
    # Recess is 182x102, reaches 1.407, and leaves a 3 mm roof before the beam.
    p=vertices(shin,'shin_flange')
    recess=p[(np.abs(p[:,0])<.093)&(np.abs(p[:,1])<.053)]
    a.condition('Female key recess has vertices',len(recess)>=8,vertices_found=len(recess))
    if len(recess):
        a.value('Key recess plan extent',np.ptp(recess,axis=0)[:2],[.182,.102])
        a.value('Key recess roof',recess[:,2].max(),1.407)
    direction=np.array([.080,.050,.160]); direction/=np.linalg.norm(direction)
    center=np.array([.250,.100,1.400])+direction*.034
    a.ring('Ankle electrical sleeve',shin,'electrical_sleeve',center,direction,.024,.017,.032)
    a.hole('Ankle electrical sleeve',shin,'electrical_sleeve',center,direction,.017,.032)
    for pid,eye in [('LG-240',(-.339,.339,7.40)),('LG-242',(.464,.124,7.40)),
                    ('LG-244',(-.124,-.464,7.40))]:
        obj=objects(pid)[0]
        p=vertices(obj,pid+'_eye')
        a.value(pid+' paired eye centre',(p.max(axis=0)+p.min(axis=0))/2,eye)
        for side in (-1,1):
            c=np.array(eye)+np.array((0,side*.072,0))
            a.hole(pid+' eye '+str(side),obj,pid+'_eye',c,(0,1,0),.031,.050)
        # Gap 94 mm and cheeks 50 mm measured from the tube axial faces.
        delta=p[:,1]-eye[1]
        a.value(pid+' clevis gap',min(abs(delta))*2,.094)
        a.value(pid+' total clevis width',max(delta)-min(delta),.194)
        # New box webs and trays must not consume the existing pin/tool route.
        direction=Vector((0,-1 if pid=='LG-244' else 1,0))
        obstructions=[]
        offsets=[Vector((0,0,0))]+[Vector((.08*math.cos(t),0,.08*math.sin(t)))
                    for t in [math.tau*j/16 for j in range(16)]]
        for receiver in (spar,objects('LG-230')[0],objects('LG-250')[0],objects('LG-255')[0]):
            inv=receiver.matrix_world.inverted()
            for offset in offsets:
                start=Vector(eye)+direction*.100+offset
                hit,loc,normal,index=receiver.ray_cast(inv@start,
                      (inv.to_3x3()@direction).normalized(),distance=.34)
                if hit:
                    obstructions.append({'part_id':receiver['part_id'],
                                         'hit':tuple(receiver.matrix_world@loc)})
        a.condition(pid+' sampled pin/tool corridor clear of frame and services',
                    not obstructions,obstructions=obstructions,radius_m=.08,length_m=.34,rays_per_part=17)
    a.bounds('Service block body',objects('LG-250')[0],'service_body',[.17,.51,8.18],[.47,.69,8.52])
    # Compare cylinder bore axes to bracket bore axes from both real geometries.
    for i,s in enumerate((-1,1)):
        ram=objects('LG-340')[i]
        measured_eyes=[]
        for label,pid,eye in [('cylinder_upper','LG-345',(s*.46,-.46,6.40)),
                              ('cylinder_lower','LG-346',(s*.44,-.50,4.30))]:
            bracket=objects(pid)[i]
            points=vertices(ram,label)
            # Sphere bore rings at +-sqrt(R^2-r^2); Boolean tessellation has <1 mm error.
            radial=np.sqrt((points[:,1]-eye[1])**2+(points[:,2]-eye[2])**2)
            rim=points[np.abs(radial-.047515)<.002]
            a.condition(label+str(s)+' actual bore rim exists',len(rim)>=16,vertices_found=len(rim))
            if len(rim):
                rc=(rim.min(axis=0)+rim.max(axis=0))/2
                bp=vertices(bracket,'mount_eye'); bc=(bp.min(axis=0)+bp.max(axis=0))/2
                a.value(label+str(s)+' cylinder eye position',rc,eye)
                a.value(label+str(s)+' bracket eye position',bc,eye)
                a.value(label+str(s)+' cylinder/bracket coincidence',rc,bc)
                measured_eyes.append(rc)
            a.hole(label+str(s)+' cartridge pin tunnel',ram,label,eye,(1,0,0),.047515,.200)
            for side in (-1,1):
                c=np.array(eye)+np.array((side*.1405,0,0))
                a.hole(pid+str(s)+' ear '+str(side),bracket,'mount_eye',c,(1,0,0),.047515,.055)
        if len(measured_eyes)==2:
            a.value('Cylinder eye distance '+str(s),np.linalg.norm(measured_eyes[1]-measured_eyes[0]),2.1004761365)
    axis=np.array([0,-math.cos(math.radians(12)),-math.sin(math.radians(12))])
    cradle=objects('LG-440')[0]
    for i,z in enumerate((4.025538,2.875538)):
        engine=objects('LG-450')[i]; seat=np.array([0,-.865296,z])
        a.ring('Cradle ring '+str(i),cradle,'thruster_seat_'+str(i+1),seat,axis,.370,.320,.100)
        a.ring('Engine seat '+str(i),engine,'engine_seat',seat-axis*.12,axis,.318,.170,.40)
        pts=vertices(engine,'nozzle'); along=(pts-seat)@axis
        a.value('Nozzle axial ends '+str(i),[along.min(),along.max()],[.10,.70])
        radial=(pts-seat)-np.outer(along,axis)
        a.value('Nozzle mouth diameter '+str(i),np.linalg.norm(radial,axis=1).max()*2,.780)
        full=vertices(engine)
        a.condition('Thruster rear envelope '+str(i),full[:,1].min()>=-1.64,
                    measured_min_y=float(full[:,1].min()),limit=-1.64)
        # C2 replaces the old burial allowance with deliberate exposed bells.
        # Recess face Y−1.40; the 12° mouth projects while respecting Y−1.64.
        a.condition('Thruster exposed beyond recess '+str(i),full[:,1].min()<=-1.55,
                    projection_m=float(-1.40-full[:,1].min()),minimum=.15,
                    recess_face_y_m=-1.40)


def main():
    parser=argparse.ArgumentParser()
    parser.add_argument('--only-leg',action='store_true',
                        help='Explicit scoped audit while the separately owned foot is in progress')
    parser.add_argument('--report',type=Path,help='Preserve a scene-specific report during parallel builds')
    args=parser.parse_args(sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else [])
    audit=Audit()
    try: leg_checks(audit)
    except Exception as exc: audit.condition('Leg audit exception',False,error=repr(exc))
    foot='not audited (leg-only scope)' if args.only_leg else 'not available'
    if not args.only_leg and importlib.util.find_spec('checks_foot'):
        try:
            from checks_foot import checks
            result=checks()
            foot=result
            # Foot module contract accepts a list of check records or a report.
            if isinstance(result,dict):
                passed=result.get('passed',result.get('ok',False))
            elif isinstance(result,list):
                passed=all(r.get('passed',r.get('ok',False)) for r in result)
            else: passed=bool(result)
            audit.condition('Foot checks()',passed)
        except Exception as exc:
            foot=repr(exc); audit.condition('Foot checks() exception',False,error=repr(exc))
    report={'audit':'measured-interfaces','tolerance_m':TOL,'blend':bpy.data.filepath,
            'scope':'leg-only' if args.only_leg else 'leg-and-foot',
            'passed':all(r['passed'] for r in audit.results),'checks':audit.results,'foot':foot}
    if bpy.data.filepath:
        report['blend_sha256']=hashlib.sha256(Path(bpy.data.filepath).read_bytes()).hexdigest()
    path=args.report or SRC.parent/'output/audits'/('interfaces-structure-leg.json' if args.only_leg else 'interfaces-structure.json')
    path.parent.mkdir(parents=True,exist_ok=True)
    path.write_text(json.dumps(report,indent=2)+'\n')
    failed=[r for r in audit.results if not r['passed']]
    print(f"INTERFACE AUDIT: {'PASS' if report['passed'] else 'FAIL'}; {len(audit.results)} checks; {len(failed)} failures")
    for r in failed: print(r)
    if failed: raise SystemExit(1)


if __name__=='__main__': main()
