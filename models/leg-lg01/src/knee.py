"""Detachable knee fork, journal stack and thigh-to-shin hydraulic drive."""
import bpy
from mathutils import Vector
from kit import (tube,cylinder,combine,hydraulic_cylinder,finish,swept_bar)
from thigh import box,bore,strut,tag,register,hardware,captive_detail

UPPER_EYES=[(-.46,-.46,6.40),(.46,-.46,6.40)]
LOWER_EYES=[(-.44,-.50,4.30),(.44,-.50,4.30)]
EYE_RADIUS=.13*.85
PIN_RADIUS=EYE_RADIUS*.43


def mount(ctx,eye,upper,side):
    m=ctx.materials; g=m['gunmetal']; p=Vector(eye)
    parts=[]
    # Two 55 mm ears, 226 mm gap around the 221 mm spherical eye.
    for s in (-1,1):
        q=p+Vector((s*.1405,0,0))
        parts.append(tag(tube(.145,PIN_RADIUS,.055,q,(1,0,0),32,.006,g),'mount_eye'))
        root=(q.x,-.29,eye[2]+(.05 if upper else -.06))
        parts.append(strut(root,(q.x,eye[1]+.10,eye[2]),.070,.10,g))
    z=eye[2]+(.05 if upper else -.06)
    parts += [box((.40,.14,.24),(side*.34,-.29,z),g,.018),
              strut((side*(.16 if upper else .25),-.20,z),(side*.34,-.29,z),.15,.16,g)]
    for x in (side*.20,side*.46):
        for dz in (-.075,.075):
            parts.append(captive_detail((x,-.367,z+dz),(0,-1,0),m['steel'],.02))
    return register(ctx,combine(parts,'Cylinder mount'), 'LG-345' if upper else 'LG-346',
                    1 if side<0 else 2)


def build(ctx):
    m=ctx.materials; gun=m['gunmetal']; steel=m['steel']
    flange=box((.680,.600,.040),(0,0,5.900),gun,.004)
    for x in (-.25,.25):
        for y in (-.20,.20): bore(flange,.0105,(x,y,5.90),(0,0,1),.10)
    fork=[tag(flange,'fork_flange'),box((.86,.36,.20),(0,0,5.78),gun,.028)]
    for s in (-1,1):
        x=s*.43
        cheek=tube(.340,.105,.140,(x,0,5.10),(1,0,0),64,.010,gun)
        fork.append(tag(cheek,'fork_cheek_'+str(s)))
        # 10 mm step from the cheek faces avoids coplanar overlapping shells.
        web=box((.12,.37,.65),(x,0,5.61),gun,.025)
        bore(web,.105,(x,0,5.10),(1,0,0),.30)
        # Lightening pocket: shallow on the exposed cheek face, leaves 90 mm web.
        difference_center=(x+s*.065,0,5.62)
        from kit import difference
        difference(web,box((.055,.18,.22),difference_center,gun,.025))
        fork.append(web)
        # Faceted cheek doubler and deep upper web transfer the broad spar load
        # into the unchanged axle/bearing stack; the rear rod corridor stays open.
        fork.append(tube(.390,.245,.075,(s*.4775,0,5.10),(1,0,0),8,.008,gun))
        doubler=box((.065,.56,.55),(s*.485,.035,5.61),gun,.024)
        difference(doubler,box((.035,.30,.28),(s*.519,.035,5.61),gun,.025))
        fork.append(doubler)
        for y in (-.15,.22):
            for z in (5.43,5.79):
                fork.append(captive_detail((s*.523,y,z),(s,0,0),steel,.025))
        fork += [strut((x,.06,5.70),(s*.72,.06,6.10),.15,.22,gun),
                 box((.12,.34,.30),(s*.735,.03,6.10),gun,.012),
                 tag(box((.010,.28,.24),(s*.795,.03,6.10),steel,.003),'fork_pad_'+str(s))]
        for y in (-.20,.20):
            fork.append(captive_detail((s*.506,y,5.31),(s,0,0),steel,.028))
        # Cast outer cheek rib and lubrication boss sit outside the journal bore.
        fork += [strut((s*.494,.19,5.33),(s*.494,.13,5.72),.028,.06,gun),
                 captive_detail((s*.506,-.20,5.29),(s,0,0),steel,.025),
                 tube(.131,.108,.012,(s*.506,0,5.10),(1,0,0),48,.002,steel)]
    register(ctx,combine(fork,'Detachable fork with transport pads'),'LG-110')
    for i,(x,y) in enumerate([(x,y) for x in (-.25,.25) for y in (-.20,.20)],1):
        hardware(ctx,'LG-H24100','M24x100 knee fork bolt','M24 washer (knee fork)',
                 i,(x,y,5.964),(0,0,1),.024,.10,.004)

    axle=[tag(cylinder(.10,1.,(0,0,5.10),(1,0,0),64,.002,steel),'axle_journal'),
          tag(cylinder(.15,.04,(-.52,0,5.10),(1,0,0),48,.004,gun),'axle_shoulder')]
    pad=cylinder(.143,.035,(.5175,0,5.10),(1,0,0),48,.004,gun)
    for z in (5.015,5.185): bore(pad,.005,(.52,0,z),(1,0,0),.10)
    axle.append(pad)
    register(ctx,combine(axle,'Shouldered knee axle'),'LG-140')
    for i,s in enumerate((-1,1),1):
        register(ctx,tag(tube(.149,.102,.120,(s*.210,0,5.10),(1,0,0),64,.001,steel),
                         'bearing'),'LG-130',i)
        register(ctx,tag(tube(.180,.102,.075,(s*.3175,0,5.10),(1,0,0),64,.0015,gun),
                         'spacer'),'LG-135',i)
    cap=cylinder(.150,.024,(.547,0,5.10),(1,0,0),48,.003,gun)
    for z in (5.015,5.185): bore(cap,.0065,(.547,0,z),(1,0,0),.10)
    register(ctx,tag(cap,'axle_cap'),'LG-150')
    for i,z in enumerate((5.015,5.185),1):
        hardware(ctx,'H-12050','M12x50 axle cap screw','M12 washer (axle cap)',i,
                 (.561,0,z),(1,0,0),.012,.050,.002)

    # Shield bridge is attached to the upper SHIN, forward of the moving journal.
    bracket=[box((.38,.10,.18),(0,.41,4.71),gun,.018),
             box((.44,.10,.33),(0,.49,4.99),gun,.025)]
    for s in (-1,1):
        bracket += [strut((s*.18,.14,4.60),(s*.18,.44,4.87),.09,.10,gun),
                    captive_detail((s*.15,.548,5.04),(0,1,0),steel,.024)]
    register(ctx,combine(bracket,'Shin-mounted kneecap bracket'),'LG-310')
    for i,(a,b) in enumerate(zip(UPPER_EYES,LOWER_EYES),1):
        mount(ctx,a,True,-1 if i==1 else 1)
        mount(ctx,b,False,-1 if i==1 else 1)
        ram=hydraulic_cylinder(a,b,1.65,.13,.055,gun,m['chrome'],steel,(1,0,0))
        # Kit eye-neck shells cross the pin tunnel. Split integral closed shells
        # before machining: Exact Boolean on overlapping shells can drop an eye.
        props=dict(ram.items())
        bpy.ops.object.select_all(action='DESELECT')
        ram.select_set(True); bpy.context.view_layer.objects.active=ram
        bpy.ops.object.mode_set(mode='EDIT'); bpy.ops.mesh.select_all(action='SELECT')
        bpy.ops.mesh.separate(type='LOOSE'); bpy.ops.object.mode_set(mode='OBJECT')
        shells=list(bpy.context.selected_objects)
        for shell in shells:
            for p in (a,b):
                hit,_,_,_=shell.ray_cast(Vector(p)-Vector((.20,0,0)),Vector((1,0,0)),distance=.40)
                if hit: bore(shell,PIN_RADIUS,p,(1,0,0),.40)
        ram=combine(shells,'Hydraulic cylinder with continuous pin bores')
        for key,value in props.items(): ram[key]=value
        # Tag actual spherical-eye bore vertices after machining.
        for label,p in [('cylinder_upper',a),('cylinder_lower',b)]:
            group=ram.vertex_groups.new(name='interface.'+label)
            indices=[v.index for v in ram.data.vertices if (v.co-Vector(p)).length<EYE_RADIUS+.003]
            group.add(indices,1,'REPLACE')
        # Cartridge-owned plumbing and clamp bands; no extra stock identities.
        w=(Vector(b)-Vector(a)).normalized(); side=-1 if i==1 else 1
        details=[ram]
        for distance in (.25,1.20):
            q=Vector(a)+w*distance
            details += [tube(.139,.130,.046,q,w,32,.003,gun),
                        cylinder(.033,.08,q+Vector((side*.15,0,0)),(1,0,0),12,.003,steel)]
        details.append(swept_bar([Vector(a)+w*.25+Vector((side*.19,0,0)),
                                  Vector(a)+w*.33+Vector((side*.205,0,0)),
                                  Vector(a)+w*1.12+Vector((side*.205,0,0)),
                                  Vector(a)+w*1.20+Vector((side*.19,0,0))],
                                 .014,10,steel,smooth=True))
        ram=combine(details,'Hydraulic cartridge and captive hard line')
        for key,value in props.items(): ram[key]=value
        register(ctx,finish(ram),'LG-340',i)
