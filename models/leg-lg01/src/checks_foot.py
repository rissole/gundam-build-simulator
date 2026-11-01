"""Measured neutral FA-02 interfaces. All tolerances are <=10 mm.

No geometric check compares custom-property datums. Bore rings are selected and
fitted from actual world-space vertices, with ray checks through receiver solids.
"""
import csv
import math
from pathlib import Path
from collections import Counter
import bpy
import numpy as np
from mathutils import Vector

CSV=Path(__file__).resolve().parents[3]/'design/legs/foot-and-ankle/foot-components.csv'
ROWS=list(csv.DictReader(CSV.open()))
DEFERRED_ROWS={(r['part_id'],r['name']) for r in ROWS
               if r['part_id'] in {'FA-302','FA-303','FA-304','FA-305','FA-400','FA-401-L',
                                   'FA-402','FA-403-L','FA-404-L','FA-405'}
               or r['name'].endswith((' - Sole pad mounts',' - Armor captive bolts'))}
TOL=.010


class Check(tuple):
    """Tuple contract, plus record access for the existing generic leg runner."""
    def __new__(cls,name,ok,detail):return tuple.__new__(cls,(name,bool(ok),detail))
    def get(self,key,default=None):
        return {'name':self[0],'check':self[0],'ok':self[1],'passed':self[1],'detail':self[2]}.get(key,default)


def checks():
    result=[]
    objs=[o for o in bpy.context.scene.objects if o.type=='MESH' and o.get('component')=='foot']
    def record(name,ok,detail):result.append(Check(name,ok,detail))
    def near(name,actual,expected,tol=TOL):
        a=np.array(actual); e=np.array(expected); error=float(np.max(abs(a-e)))
        record(name,np.isfinite(a).all() and error<=tol+1e-6,{'measured':a.tolist(),'expected':e.tolist(),'max_error_m':error})
    def get(pid):return sorted([o for o in objs if o['part_id']==pid],key=lambda o:o['instance_id'])
    def vertices(o):return np.array([tuple(o.matrix_world@v.co) for v in o.data.vertices])
    def bounds(o):
        p=vertices(o);return p.min(axis=0),p.max(axis=0)
    def circle(name,o,center,axis,radius,span=None,clear=False,rim_chamfer=0):
        p=vertices(o); c=np.array(center); w=np.array(axis,dtype=float);w/=np.linalg.norm(w)
        ref=np.array([0,0,1] if abs(w[2])<.9 else [0,1,0]);u=np.cross(ref,w);u/=np.linalg.norm(u);v=np.cross(w,u)
        d=p-c; xy=np.column_stack((d@u,d@v)); z=d@w
        selected=abs(np.linalg.norm(xy,axis=1)-radius)<.002
        if span is not None:selected &= abs(z)<=span/2+.003
        q=xy[selected]
        record(name+' rim exists',len(q)>=12,{'rim_vertices':len(q)})
        if len(q)<12:return None
        A=np.column_stack((2*q,np.ones(len(q))));cx,cy,k=np.linalg.lstsq(A,(q*q).sum(axis=1),rcond=None)[0]
        axial_rim=selected
        if rim_chamfer:
            rad=np.linalg.norm(xy,axis=1)
            axial_rim=(rad>=radius-.002)&(rad<=radius+rim_chamfer+.002)&(abs(z)<=span/2+.003)
        axial=(z[axial_rim].min()+z[axial_rim].max())/2
        measured=c+u*cx+v*cy+w*axial
        near(name+' centre',measured,c)
        near(name+' diameter',2*math.sqrt(max(0,k+cx*cx+cy*cy)),2*radius)
        if span is not None:near(name+' span',z[axial_rim].max()-z[axial_rim].min(),span)
        if clear:
            inv=o.matrix_world.inverted(); direction=(inv.to_3x3()@Vector(w)).normalized();hits=[]
            for offset in (np.zeros(3),u*radius*.6,-u*radius*.6,v*radius*.6,-v*radius*.6):
                hit,point,normal,idx=o.ray_cast(inv@Vector(c+offset-w*(span/2+.001)),direction,distance=span+.002)
                if hit:hits.append(tuple(o.matrix_world@point))
            record(name+' clear bore',not hits,{'hits':hits})
        return measured
    counts=Counter((o['part_id'],o['part_name']) for o in objs)
    expected=Counter({(r['part_id'],r['name']):int(r['qty_per_leg']) for r in ROWS if (r['part_id'],r['name']) not in DEFERRED_ROWS})
    # Phase 4 can add the deferred complete rows later.
    active=Counter({k:v for k,v in counts.items() if k not in DEFERRED_ROWS})
    record('FA02 internal row counts',active==expected,{'actual':sum(active.values()),'expected':sum(expected.values())})
    record('FA02 independent meshes',len({o.data.as_pointer() for o in objs})==len(objs),{'objects':len(objs)})
    if not get('FA-201'):return result+[Check('FA02 geometry exists',False,'Missing adapter')]
    for pid,axis,rad,centers,span in [
        ('FA-202',(1,0,0),.060,[(-.425,0,1),(.425,0,1)],.250),
        ('FA-203',(0,1,0),.050,[(0,-.235,1),(0,.235,1)],.250),
        ('FA-204',(1,0,0),.060,[(-.370,0,1),(.370,0,1)],.140),
        ('FA-205',(0,1,0),.050,[(0,-.160,1),(0,.160,1)],.100),
        ('FA-210',(1,0,0),.060,[(0,1.340,.350)],1.160),
        ('FA-211',(1,0,0),.060,[(-.380,1.340,.350),(.380,1.340,.350)],.140)]:
        for i,(o,c) in enumerate(zip(get(pid),centers)):circle(pid+str(i),o,c,axis,rad,span)
    adapter=get('FA-201')[0];p=vertices(adapter)
    flange=p[(p[:,2]>1.319)&(p[:,2]<1.381)&((abs(p[:,0])>.19)|(abs(p[:,1])>.14))]
    near('Adapter flange bounds',np.array([flange.min(axis=0),flange.max(axis=0)]),[[-.260,-.220,1.320],[.260,.220,1.380]])
    key=p[p[:,2]>1.3801];near('Adapter key top and plan',[*np.ptp(key,axis=0)[:2],key[:,2].max()],[.180,.100,1.400])
    for i,(x,y) in enumerate([(x,y) for x in (-.2,.2) for y in (-.15,.15)]):
        circle('Adapter bolt bore '+str(i),adapter,(x,y,1.350),(0,0,1),.018,.060,True)
        bolt=get('H-36090')[i];lo,hi=bounds(bolt)
        near('Shin bolt axis '+str(i),(lo+hi)[:2]/2,[x,y]);near('Shin bolt tip/head '+str(i),[lo[2],hi[2]],[1.326,1.452])
        head=vertices(bolt);head=head[(np.linalg.norm(head[:,:2]-[x,y],axis=1)>.020)]
        record('Shin bolt bearing above baseplate '+str(i),head[:,2].min()>=1.416-.0001,{'minimum_head_z':float(head[:,2].min())})
        washer=next(o for o in objs if o['instance_id']==bolt['paired_instance_id'])
        lo,hi=bounds(washer);near('Shin washer planes '+str(i),[lo[2],hi[2]],[1.410,1.416])
    schedules=[('Rear frame joints',[(-560,110), (1120,110),(0,220)]),('Forefoot frame joints',[(2350,90),(1590,90)])]
    for use,sites in schedules:
        actual=[]
        for o in objs:
            if o.get('hardware_use')==use and o['part_id']=='H-36140':
                lo,hi=bounds(o);actual.append((round((lo[0]+hi[0])/2,6),round((lo[1]+hi[1])/2,6),lo[2],hi[2]))
        expected_points=sorted([(s*.395,(y+dy)/1000,.296,.472) for y,spacing in sites for s in (-1,1) for dy in (-spacing/2,spacing/2)])
        near(use+' bolt axes and ends',sorted(actual),expected_points)
    # Measure the receiving lands as well as the matching fastener shafts.
    for pid,y,pitch in [('FA-101',-.560,.110),('FA-102',1.120,.110),
                         ('FA-103-L',0,.220),('FA-105',2.350,.090),('FA-106',1.590,.090)]:
        for sign in (-1,1):
            x=sign*.395
            rail_id=('FA-104-' if pid in {'FA-105','FA-106'} else 'FA-100-')+('A' if sign<0 else 'B')
            for dy in (-pitch/2,pitch/2):
                circle(pid+f' land bore {x} {dy}',get(pid)[0],(x,y+dy,.410),(0,0,1),.019,.040,True,rim_chamfer=.020)
                circle(rail_id+f' ledge bore {y} {dy}',get(rail_id)[0],(x,y+dy,.370),(0,0,1),.019,.040,True,rim_chamfer=.020)
                receiver=get(pid)[0];inv=receiver.matrix_world.inverted()
                hit,point,normal,index=receiver.ray_cast(inv@Vector((x+.026,y+dy,.600)),Vector((0,0,-1)),distance=.25)
                record(pid+f' washer seat exists {x} {dy}',hit,{})
                if hit:near(pid+f' washer seat plane {x} {dy}',(receiver.matrix_world@point).z,.430,.001)

    for pid in ('FA-101','FA-102','FA-105'):
        lo,hi=bounds(get(pid)[0]);near(pid+' transverse span',[lo[0],hi[0]],[-.650,.650])
    harness=get('FA-605-L')[0]
    plug_axis=np.array([.08,.05,.16]);plug_axis/=np.linalg.norm(plug_axis)
    circle('Main harness shin plug collar',harness,np.array([.250,.100,1.400])+plug_axis*.016,
           plug_axis,.016,.006)
    for pid,ys in [('FA-300',[-.670,.170,1.040]),('FA-301',[1.640,2.280])]:
        carrier=get(pid)[0]
        for x in (-.560,.560):
            for y in ys:circle(pid+f' carrier bore {x} {y}',carrier,(x,y,.186),(0,0,1),.013,.028,True)
        lo,hi=bounds(carrier);near(pid+' thickness',[lo[2],hi[2]],[.140,.200])
    # Bearings are symmetric actual solids; compare their fitted bore axes with
    # the corresponding pin and clevis rims, including the oblique roll basis.
    for kind,base,tip,r in [('P',(-.54,.8,.48),(-.54,.3,1),.025),
                            ('R',(.5,-.45,.85),(.2,-.45,1.32),.020),
                            ('F',(0,.79,.52),(0,1.4,.57),.020)]:
        d=np.array(tip)-base;d/=np.linalg.norm(d);axis=np.array([1.,0,0]);axis-=d*np.dot(d,axis);axis/=np.linalg.norm(axis)
        for i,c in enumerate((base,tip)):
            bearing=next(o for o in objs if o['part_id'].startswith('FA-526') and o['label']==f'{kind} Spherical eye bearing {i+1}')
            pin=next(o for o in objs if o['part_id'].startswith('FA-221') and o['label']==f'{kind} Eye pin {i+1}')
            clevis=next(o for o in objs if o['part_id'].startswith('FA-220') and o['label']==f'{kind} Clevis {i+1}')
            bc=circle(kind+str(i)+' eye',bearing,c,axis,r,.054 if kind=='P' else .039)
            pc=circle(kind+str(i)+' pin',pin,c,axis,r,.132 if kind=='P' else .097)
            cc=circle(kind+str(i)+' clevis',clevis,c,axis,r+.0004 if kind=='P' else r,.132 if kind=='P' else .097,True)
            if bc is not None and pc is not None:near(kind+str(i)+' eye/pin alignment',bc,pc)
            if bc is not None and cc is not None:near(kind+str(i)+' eye/clevis alignment',bc,cc)
    allp=np.concatenate([vertices(o) for o in objs]);lo=allp.min(axis=0);hi=allp.max(axis=0)
    record('Foot stays above ground',lo[2]>=-.010,{'min_z':float(lo[2])})
    record('Foot within FA02 neutral envelope',lo[0]>=-.740 and hi[0]<=.740 and lo[1]>=-.910 and hi[1]<=2.470 and hi[2]<=1.610,{'min':lo.tolist(),'max':hi.tolist()})
    triangles=0
    for o in objs:o.data.calc_loop_triangles();triangles+=len(o.data.loop_triangles)
    record('Foot triangle budget',triangles<=800000,{'triangles':triangles,'limit':800000})
    return result
