"""Tapered shin, handed service shells and twin recessed exhaust openings."""
import math
from kit import (combine, plate, difference, chamfered_box, chamfered_rect,
                 rectangular_ring, grab_rail, finish, mesh_object)
from thigh import register,box
from thigh_armor import panel, mapped, attach, interp,profile,clean


def build(ctx):
    m=ctx.materials
    lateral_points=[(1.65,.455),(1.95,.455),(3.85,.765),(4.30,.765),(4.65,.60)]
    lateral=profile(lateral_points)
    front=profile([(1.65,.32),(1.95,.37),(3.95,.54),(4.45,.54),(4.67,.35)])
    rear=profile([(1.65,.35),(1.95,.43),(2.40,1.38),(2.62,1.58),(4.16,1.58),(4.60,1.22)])
    outline=[(-.40,1.65),(.40,1.65),(.53,1.93),(.70,3.96),(.64,4.38),(.38,4.67),(-.38,4.67),(-.64,4.38),(-.70,3.96),(-.53,1.93)]
    skin=panel(ctx,outline,bolts=[(-.32,1.88),(.32,1.88),(-.51,4.22),(.51,4.22)],
               grooves=[[(-.32,1.82),(-.36,2.10),(.36,2.10),(.32,1.82)],
                        [(-.63,4.07),(-.40,4.31),(0,4.46),(.40,4.31),(.63,4.07)]],
               slots=[(-.52,2.95,.12,.83),(.52,2.95,.12,.83)],
               marks=[('caution',0,2.20,.35),('unit01',.19,3.54,.22)])
    mapped(skin,'front',front)
    attach(ctx,skin,'LG-400',[( (0,.44,z),(0,front(z)+.01,z)) for z in (3.22,4.44)])
    for s,pid in [(-1,'LG-410'),(1,'LG-415')]:
        outline=[(-.30,1.65),(.26,1.65),(.45,1.94),(.51,4.16),(.24,4.61),(-.64,4.61),(-1.15,4.27),(-1.25,2.50)]
        # Polygon is convex; the rear tapers steeply below the engine cradle.
        skin=panel(ctx,outline,bolts=[(.29,2.13),(.30,4.18),(-.71,4.25),(-.72,2.48)],
                   grooves=[[(-.92,2.75),(-.96,3.85),(-.72,4.13)]],
                   cuts=[((0,2.80,.03),(.40,.38,.24)),
                         ((-.57,3.40,.03),(.64,1.08,.24)),
                         ((.22,3.58,.03),(.16,.61,.24))],
                   marks=[('red_marks',-.86,2.67,.20)])
        mapped(skin,'side',lateral,s)
        attach(ctx,skin,pid,[((s*.665,.04,z),(s*(lateral(z)+.01),.04,z)) for z in (3.22,4.44)])
        # Independent handed hatch, with real through-opening in its side shell.
        houtline=[(u-.57,v+3.40) for u,v in chamfered_rect(.62,1.06,.07)]
        hatch=panel(ctx,houtline,bolts=[(u-.57,z+3.40) for u in (-.22,.22) for z in (-.43,.43)],
                    slots=[(-.35,3.40,.055,.20)])
        mapped(hatch,'side',profile(lateral_points,-.012),s)
        attach(ctx,hatch,'LG-460',[((s*(lateral(z)-.020),-.18,z),(s*(lateral(z)+.005),-.36,z)) for z in (2.98,3.82)],1 if s<0 else 2)
        rail=grab_rail(.67,.095,.033,m['ochre'],m['gunmetal'])
        # Kit rail runs X: rotate to local panel Y (vertical), then map to side.
        rail.rotation_euler.z=math.pi/2
        rail.location=(.22,3.58,.002)
        # Recess the side skin behind the rail enough to retain the width target.
        mapped(rail,'side',profile(lateral_points,-.05),s)
        feet=[box((.09,.18,.10),(s*(lateral(z)-.015),.22,z),m['gunmetal'],.008) for z in (3.245,3.915)]
        register(ctx,clean(combine([rail,*feet],'Rail with recessed mounting feet')),'LG-470',1 if s<0 else 2)
    outline=[(-.38,1.65),(.38,1.65),(.54,2.08),(.68,2.62),(.73,4.09),(.52,4.60),(-.52,4.60),(-.73,4.09),(-.68,2.62),(-.54,2.08)]
    shroud=panel(ctx,outline,bolts=[(-.44,2.40),(.44,2.40),(-.45,4.33),(.45,4.33)],
                 marks=[('caution',0,4.38,.35)])
    # Separate octagonal openings, each around one existing Ø640 nozzle mouth.
    from kit import prism
    lips=[]
    for z in (2.784462,3.834462):
        loop=[(u,v+z) for u,v in chamfered_rect(.82,.86,.16)]
        difference(shroud,prism(loop,.22,'Exhaust aperture cutter',z=-.08))
        outer=[(u,v+z) for u,v in chamfered_rect(.87,.91,.17)]
        inner=[(u,v+z) for u,v in chamfered_rect(.81,.85,.15)]
        lip=rectangular_ring(outer,inner,.105,m['gunmetal'],z=-.060)
        lips.append(lip)
    # Removable bridge replaces the skin between openings; no doubled panel.
    difference(shroud,chamfered_box((.88,.175,.22),(0,3.309462,.03),.025))
    mapped(shroud,'back',rear)
    for lip in lips: mapped(lip,'back',rear)
    # Folded 60 mm return walls close the side-to-rear seams. They belong to
    # LG-420 and remain visible as actual thickness in an exploded view.
    returns=[]
    rings=[(1.70,-.32,-.36,.45,.39),(2.62,-1.19,-1.60,.63,.67),
           (4.09,-1.11,-1.60,.765,.73),(4.58,-.65,-1.28,.62,.53)]
    for s in (-1,1):
        verts=[]
        for z,front_y,back_y,front_x,back_x in rings:
            verts.extend([(s*front_x,front_y,z),(s*back_x,back_y,z),
                          (s*(back_x-.06),back_y,z),(s*(front_x-.06),front_y,z)])
        faces=[(3,2,1,0),(12,13,14,15)]
        faces += [(k*4+i,k*4+(i+1)%4,(k+1)*4+(i+1)%4,(k+1)*4+i)
                  for k in range(3) for i in range(4)]
        returns.append(finish(mesh_object('Shroud folded side return',verts,faces,m['armor']),wear=True))
    shroud=combine([shroud,*lips,*returns],'Rear shroud and recessed exhaust collars')
    attach(ctx,shroud,'LG-420',[((s*.48,-.69,z),(s*.56,-rear(z)-.01,z)) for s in (-1,1) for z in (2.51,4.30)])
    bridge=panel(ctx,[(u,z+3.309462) for u,z in chamfered_rect(.86,.155,.025)],
                 bolts=[(-.32,3.309462),(.32,3.309462)])
    mapped(bridge,'back',rear)
    attach(ctx,bridge,'LG-430',[((x,-.79,3.45),(x,-1.59,3.309462)) for x in (-.30,.30)])
