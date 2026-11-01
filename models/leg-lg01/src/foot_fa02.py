"""FA-02 internal build. Source helpers use mm and emit metre meshes.

Adapters retain FA-01 source roles until the repaired pitch interfaces finish;
registration then maps every object to the exact FA-02 CSV row. No FA-01 writes.
Phase 4 supplies the complete rows listed in checks_foot.DEFERRED_ROWS.
"""
import csv
from collections import Counter
from pathlib import Path
import bpy
import bmesh
import foot_geometry as g
import foot_frame
import foot_actuators
import foot_services

SPEC=Path(__file__).resolve().parents[3]/'design/legs/foot-and-ankle'


def row_for(obj,rows):
    pid=obj['part_id']; label=obj['label'].replace(' ','_')
    if pid.startswith(('H-','W-')):
        use=obj['hardware_use']
        return next(r for r in rows if r['part_id']==pid and r['name'].endswith(' - '+use))
    if pid in {'FA-100','FA-104'}:pid+='-A' if label.endswith('OUT') else '-B'
    elif pid in {'FA-103','FA-605'}:pid+='-L'
    elif pid=='FA-107':pid+='-B' if '_pitch_200' in label else '-C' if '_pitch_80' in label else '-A'
    elif pid=='FA-230':
        index=['Pitch_back','Pitch_forward','Roll_outer','Roll_inner','Toe_flat','Toe_limit'].index(label[:-5])
        pid+='-'+chr(65+index)
    elif pid=='FA-606':pid+='-'+{'Pitch_branch':'A','Roll_branch':'B','Forefoot_branch':'C'}[label]
    elif pid in {'FA-220','FA-524','FA-525','FA-529'}:
        kind=label[0]; n=int(label[-1])-1
        if pid=='FA-529':n=1-n # source order rear/front; CSV order front/rear
        if pid=='FA-524' and kind=='P':n=1-n # repaired source: threaded first, clearance second
        pid+='-'+chr(65+{'P':0,'R':2,'F':4}[kind]+n)
    elif pid in {'FA-221','FA-222','FA-526','FA-527'}:pid+='-A' if label[0]=='P' else '-B'
    elif pid.startswith('FA-5') and 510<=int(pid[3:])<=523:
        pid+='-'+{'P':'A','R':'B','F':'C'}[label[0]]
    matches=[r for r in rows if r['part_id']==pid]
    if len(matches)!=1:raise ValueError((pid,label,matches))
    return matches[0]


def build(ctx):
    g.init(ctx); foot_actuators.ACTUATORS.clear()
    for label,fn in [('frame',foot_frame.build_frames),('ankle',foot_frame.build_ankle),
                     ('hinge',foot_frame.build_toe_joint),('stops',foot_frame.build_stops),
                     ('actuators',foot_actuators.build),('carriers',foot_services.build_soles),
                     ('electrical',foot_services.build_electrical)]:
        print('FA02',label,flush=True); fn()
    rows=list(csv.DictReader((SPEC/'foot-components.csv').open()))
    counts=Counter(); old_to_new={}
    for obj in g.PARTS:
        row=row_for(obj,rows); pid=row['part_id']; counts[pid]+=1
        old=obj['instance_id']; obj['fa01_source_id']=old
        # All machining is already applied; apply real edge geometry before audit/export.
        bm=bmesh.new();bm.from_mesh(obj.data)
        bad=sum(not e.is_manifold for e in bm.edges)
        if bad:print('FA02 pre-bevel topology',pid,obj['label'],bad,flush=True)
        bm.free()
        bpy.context.view_layer.objects.active=obj
        for mod in list(obj.modifiers):bpy.ops.object.modifier_apply(modifier=mod.name)
        bm=bmesh.new(); bm.from_mesh(obj.data)
        bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces)); bm.to_mesh(obj.data); bm.free()
        obj.data.update()
        obj.data.set_sharp_from_angle(angle=.65)
        for poly in obj.data.polygons:poly.use_smooth=True
        uid=f'{pid}.{counts[pid]:03d}'
        ctx.register(obj,pid,row['name'],row['subassembly'],row['category'],row['finish'],uid)
        obj['spec_revision']='FA-02'; obj['component']='foot'; old_to_new[old]=uid
    for obj in g.PARTS:
        if 'paired_instance_id' in obj:obj['paired_instance_id']=old_to_new[obj['paired_instance_id']]
        if 'owner_instance' in obj:
            source=obj['owner_instance'].split('__')
            old='__'.join(source[:2]); obj['owner_instance']=old_to_new.get(old,obj['owner_instance'])
    for col in g.COLLECTIONS.values():
        if not col.objects:bpy.data.collections.remove(col)
    from foot_fa02_armor import ARMOR_ROWS as DEFERRED_ROWS
    actual=Counter((o['part_id'],o['part_name']) for o in g.PARTS)
    expected={(r['part_id'],r['name']):int(r['qty_per_leg']) for r in rows
              if (r['part_id'],r['name']) not in DEFERRED_ROWS}
    assert actual==expected,(actual- Counter(expected),Counter(expected)-actual)
    triangles=0
    for o in g.PARTS:o.data.calc_loop_triangles(); triangles+=len(o.data.loop_triangles)
    assert triangles<800000,triangles
    print('FA02 COMPLETE:',len(g.PARTS),'independent meshes;',triangles,'triangles',flush=True)
