"""LG-01 structural thigh; metres, left-leg coordinates. No armor inventory.

Local helpers fill the kit's inventory-fastener/feature-tag gaps without changing
the Phase 2 API. Interface groups identify real vertices, never proxy markers.
"""
import csv
import math
from pathlib import Path
from mathutils import Vector
from kit import (chamfered_box, cylinder, tube, sphere, combine, difference,
                 finish, place, hex_prism, swept_bar, cable_bundle, loft, chamfered_rect)

ROWS = list(csv.DictReader((Path(__file__).resolve().parents[3] /
                           'design/legs/leg-components.csv').open()))
LUGS = [('LG-240',(-.339,.339,7.40),(-.15,.035,7.40),-1),
        ('LG-242',(.464,.124,7.40),(.15,.025,7.40),1),
        ('LG-244',(-.124,-.464,7.40),(-.07,-.10,7.40),-1)]


def tag(obj, label):
    group = obj.vertex_groups.new(name='interface.'+label)
    group.add(list(range(len(obj.data.vertices))), 1., 'REPLACE')
    return obj


def register(ctx, obj, part_id, instance=1, name=None):
    rows = [r for r in ROWS if r['part_id']==part_id and (name is None or r['name']==name)]
    if len(rows)!=1:
        raise ValueError(f'Ambiguous CSV row: {part_id} / {name}')
    r=rows[0]
    return ctx.register(obj,part_id,r['name'],r['subassembly'],r['category'],r['finish'],instance)


def box(size, center, mat, bevel=.012, label=None):
    obj=chamfered_box(size,center,bevel,mat)
    return tag(obj,label) if label else obj


def strut(a,b,width,depth,mat):
    a,b=Vector(a),Vector(b)
    return place(chamfered_box((width,depth,(b-a).length),bevel=min(width,depth)*.12,
                               material=mat), (a+b)/2,b-a)


def bore(obj, radius, center, axis, length):
    return difference(obj,cylinder(radius,length,center,axis,32,0))


def bolt(diameter,length,bearing,axis,mat,label=None):
    """Standalone inventory bolt: head at bearing plane, shaft along -axis."""
    pieces=[cylinder(diameter/2,length,(0,0,-length/2),segments=12,
                     bevel=.0004,material=mat),
            hex_prism(diameter*.82,diameter*.65,center=(0,0,diameter*.325),
                      bevel=.0008,material=mat)]
    obj=place(combine(pieces,'Standalone hex bolt'),bearing,axis)
    return tag(obj,label) if label else obj


def hardware(ctx,part_id,name,washer_name,instance,bearing,axis,diameter,length,washer_t):
    p,w=Vector(bearing),Vector(axis).normalized()
    washer=tube(diameter*.95,diameter*.535,washer_t,p-w*washer_t/2,w,12,.0003,
                ctx.materials['steel'])
    register(ctx,tag(washer,'washer'),f'W-{round(diameter*1000)}',instance,washer_name)
    return register(ctx,bolt(diameter,length,p,w,ctx.materials['steel'],'bolt'),
                    part_id,instance,name)


def captive_detail(center,axis,mat,r=.018):
    """Small integral cast/captive service plug, not additional CSV hardware."""
    return combine([tube(r*1.3,r*.84,.008,center,axis,12,.001,mat),
                    hex_prism(r*.78,.009,center=Vector(center)+Vector(axis)*.003,
                              axis=axis,bevel=.001,material=mat)],'Captive service plug')


def build(ctx):
    m=ctx.materials; gun=m['gunmetal']; steel=m['steel']
    spar=box((.30,.20,2.49),(0,0,7.205),gun,.018,'spar')
    # Blind machining leaves a continuous load-bearing web.
    for z in (6.36,6.88,7.92,8.20):
        difference(spar,box((.17,.07,.26),(0,.10,z),gun,.025))
    flange=box((.680,.600,.040),(0,0,5.940),gun,.004)
    for x in (-.25,.25):
        for y in (-.20,.20): bore(flange,.013,(x,y,5.94),(0,0,1),.10)
    pieces=[spar,tag(flange,'spar_flange'),
            tag(sphere(.450,(0,0,9.20),gun,segments=64,rings=32),'hip_ball')]
    neck=cylinder(.150,.450,(0,0,8.560),segments=48,bevel=.004,material=gun)
    # Prepared antirotation key flat, for a collar not allocated in this CSV.
    difference(neck,box((.08,.16,.09),(.178,0,8.46),gun,0))
    pieces.append(tag(neck,'neck'))
    pieces.append(box((.33,.25,.18),(0,0,8.34),gun,.028))
    # The 300 x 200 neck is an interface, not the whole thigh envelope.
    # Deep flanged webs form a fabricated box around the continuous spar.
    # Leave the three keyed lug roots and their pin-entry corridors open.
    for low,high in ((6.02,7.20),(7.66,8.24)):
        mid=(low+high)/2; height=high-low
        core=box((.66,.54,height),(0,-.015,mid),gun,.035)
        for z in (low+height*.27,low+height*.73):
            difference(core,box((.38,.12,height*.27),(0,.265,z),gun,.025))
        pieces.append(tag(core,'thigh_box_lower' if low<7 else 'thigh_box_upper'))
        for s in (-1,1):
            web=box((.10,.68,height-.06),(s*.37,-.045,mid),gun,.025)
            for z in (low+height*.27,low+height*.73):
                difference(web,box((.055,.40,height*.25),(s*.421,-.045,z),gun,.025))
            pieces.append(web)
            # Continuous edge flanges and bolted structural doubler faces.
            for y in (-.37,.28):
                pieces.append(box((.16,.07,height-.10),(s*.37,y,mid),gun,.012))
            for z in (low+.13,high-.13):
                pieces.append(box((.115,.58,.105),(s*.425,-.045,z),gun,.014))
                for y in (-.23,.14):
                    pieces.append(captive_detail((s*.488,y,z),(s,0,0),steel,.026))
    # Broad shoulder tapers back into the exact upper neck transition.
    shoulder=loft([(8.16,chamfered_rect(.66,.54,.05)),
                   (8.30,chamfered_rect(.30,.20,.015))],gun,'Spar shoulder')
    pieces.append(shoulder)
    # Rear corner rails bridge the lug band without crossing any pin approach.
    # Step the faces 10 mm past the neighboring webs to avoid coincident skins.
    for s in (-1,1):
        pieces.append(box((.12,.34,.58),(s*.37,-.19,7.43),gun,.018))
    # Armor lands reach within 100 mm of the planned 60 mm armor inner faces.
    for z,extent in ((6.62,.50),(7.94,.74)):
        for s in (-1,1):
            pieces += [strut((s*.37,.02,z-.13),(s*(extent-.08),.02,z),.12,.18,gun),
                       box((.16,.28,.14),(s*(extent-.08),.02,z),gun,.016)]
            for y in (-.075,.115):
                pieces.append(captive_detail((s*(extent+.006),y,z),(s,0,0),steel,.022))
        reach=.46 if z<7 else .74
        pieces += [strut((0,.24,z-.15),(0,reach-.06,z),.24,.13,gun),
                   box((.38,.12,.14),(0,reach-.06,z),gun,.016)]
    # Ribs and keyed carrier backing rails are integral spar features.
    for s in (-1,1):
        pieces.append(box((.075,.25,1.98),(s*.18,0,7.03),gun,.012))
        for z in (6.48,7.04,7.82,8.16):
            pieces.append(box((.12,.32,.07),(s*.19,0,z),gun,.01))
            pieces.append(captive_detail((s*.19,.167,z),(0,1,0),steel,.022))
        # Machined rail segments remain clear of the three lug/pin channels.
        for z,height in ((6.78,.67),(7.96,.55)):
            rail=box((.10,.31,height),(s*.265,0,z),gun,.019)
            difference(rail,box((.07,.17,height-.16),(s*.307,0,z),gun,.022))
            pieces.append(rail)
            for dz in (-height/2+.075,height/2-.075):
                pieces.append(captive_detail((s*.320,0,z+dz),(s,0,0),steel,.025))
        for z in (6.52,7.04,7.75,8.16):
            pieces.append(box((.20,.22,.065),(s*.22,0,z),gun,.01))
    for pid,eye,root,s in LUGS:
        if pid=='LG-244':
            rail=box((.25,.09,.35),(-.055,-.127,7.425),gun,.012)
            key=box((.06,.035,.22),(-.07,-.184,7.42),steel,.003)
            for z in (7.31,7.54): bore(rail,.0105,(-.07,-.127,z),(0,1,0),.16)
        else:
            rail=box((.09,.23,.35),(s*.19,root[1],7.425),gun,.012)
            key=box((.035,.06,.22),(s*.244,root[1],7.42),steel,.003)
            for z in (7.31,7.54): bore(rail,.0105,(s*.19,root[1],z),(1,0,0),.16)
        pieces += [rail,key]
    # Front service-block outrigger, keeping the upper pin approach tubes open.
    pieces += [strut((.10,.08,8.30),(.32,.50,8.35),.10,.11,gun),
               box((.24,.07,.22),(.32,.49,8.35),gun,.015)]
    register(ctx,combine(pieces,'Spar and integral ball'),'LG-120')

    for pid,eye,root,s in LUGS:
        e=Vector(eye); root=Vector(root)
        # Both ears are open, drilled along Y; no invented hip pins in leg stock.
        ears=[]
        for t in (-1,1):
            c=e+Vector((0,t*.072,0))
            ears.append(tag(tube(.085,.031,.050,c,(0,1,0),32,.004,gun),pid+'_eye'))
        # Arm lands below the eye so the bore and open-top parking rest stay clear.
        arm_end=e-Vector((0,0,.075))
        arm=strut(root,arm_end,.10,.10,gun)
        bore(arm,.031,e,(0,1,0),.30)
        ears += [arm,
                 box((.11,.194,.045),e-Vector((0,0,.075)),gun,.008)]
        if pid=='LG-244':
            mounting=box((.20,.065,.35),(-.07,-.185,7.425),gun,.010)
            # Keyway is actual female geometry in the removable root.
            difference(mounting,box((.062,.040,.224),(-.07,-.165,7.42),gun,0))
            axes=[((-.07,-.221,z),(0,-1,0)) for z in (7.31,7.54)]
        else:
            mounting=box((.065,.20,.35),(s*.25,root.y,7.425),gun,.010)
            difference(mounting,box((.040,.062,.224),(s*.225,root.y,7.42),gun,0))
            axes=[((s*.2865,root.y,z),(s,0,0)) for z in (7.31,7.54)]
        for p,axis in axes: bore(mounting,.013,p,axis,.18)
        ears.append(mounting)
        register(ctx,combine(ears,pid+' keyed lug carrier'),pid)
        for j,(p,axis) in enumerate(axes):
            hardware(ctx,'LG-H24100','M24x100 lug carrier bolt','M24 washer (lug carriers)',
                     f'{pid.lower()}.{j+1}',p,axis,.024,.100,.004)

    # Service body is symmetrical about the specified centre; fittings are integral.
    service=[tag(box((.30,.18,.34),(.32,.60,8.35),gun,.022),'service_body')]
    for x in (.245,.395):
        for z in (8.27,8.43):
            service += [tube(.037,.023,.06,(x,.71,z),(0,1,0),16,.004,steel),
                        cylinder(.021,.008,(x,.695,z),(0,1,0),12,.001,m['recess'])]
    for x in (.20,.44):
        for z in (8.21,8.49): service.append(captive_detail((x,.695,z),(0,1,0),steel,.012))
    register(ctx,combine(service,'Dry break service block'),'LG-250')

    # Exact 0.95 m free centreline: two straight legs plus a R0.12 semicircle.
    r=.12; straight=(.95-math.pi*r)/2; ztop=8.20; zc=ztop-straight
    path=[(.32,.60,ztop),(.32,.60,zc)]
    path += [(.20+r*math.cos(t),.60,zc-r*math.sin(t))
             for t in [math.pi*i/32 for i in range(1,33)]]
    path += [(.08,.60,ztop)]
    loop=[swept_bar(path,.025,12,m['rubber'])]
    for x in (.08,.32):
        loop.append(tube(.033,.025,.055,(x,.60,8.185),segments=12,bevel=.002,material=steel))
    loop += [strut((.08,.58,8.18),(.08,.09,8.18),.065,.055,gun),
             tube(.032,.026,.04,(.08,.60,8.17),segments=12,bevel=.002,material=gun)]
    register(ctx,combine(loop,'Protected U loop'),'LG-255')

    # Rear guard and captive looms; a raised central spine protects cable runs.
    guard=[]
    guard_panel=box((.28,.10,1.94),(0,-.50,7.18),gun,.025)
    for z in (6.68,7.22,7.77):
        difference(guard_panel,box((.17,.055,.32),(0,-.548,z),gun,.018))
    # Rear hip pin/tool withdrawal crosses this guard: provide a real opening.
    difference(guard_panel,box((.48,.28,.30),(-.124,-.50,7.40),gun,.025))
    guard.append(guard_panel)
    for x in (-.285,.285):
        guard.append(cable_bundle([(x,-.26,8.25),(x,-.435,8.02),
                                  (x,-.435,6.58),(x*.85,-.28,6.06)],
                                 3,.026,.060,m['rubber']))
    for z in (6.39,6.94,7.66,8.05):
        guard += [box((.76,.09,.075),(0,-.415,z),gun,.012),
                  captive_detail((0,-.559,z),(0,-1,0),steel,.026)]
    register(ctx,combine(guard,'Rear guard and captive cable runs'),'LG-230')
