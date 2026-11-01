"""Bulging faceted calf, fitted corner seams and exposed twin exhaust bells."""
import math
from kit import (combine, difference, chamfered_box, chamfered_rect,
                 rectangular_ring, grab_rail, prism)
from thigh import register, box
from thigh_armor import panel, mapped, attach, profile, clean, corner_returns


def build(ctx):
    m=ctx.materials
    lateral_points=[(1.65,.455),(1.95,.455),(2.50,.550),(3.30,.755),
                    (3.95,.765),(4.25,.755),(4.65,.60)]
    lateral=profile(lateral_points)
    front=profile([(1.65,.32),(1.95,.37),(3.95,.54),(4.50,.54),(4.60,.48)])
    # Broad rear brow encloses the flattened cradle crown with solid clearance.
    rear=profile([(1.65,.35),(1.95,.43),(2.40,1.30),(2.62,1.34),
                  (4.15,1.34),(4.40,1.20),(4.60,1.14)])
    front_edge=profile([(1.65,.40),(1.93,.53),(2.50,.60),(3.30,.71),
                        (3.95,.735),(4.38,.69),(4.60,.60)])
    zs=[1.65,1.93,1.95,2.50,3.30,3.95,4.25,4.38,4.50,4.60]
    outline=[(-front_edge(z),z) for z in reversed(zs)]+[(front_edge(z),z) for z in zs]
    # Return along a lowered central saddle, instead of capping the knee gap.
    outline += [(.50,4.60),(.28,4.36),(-.28,4.36),(-.50,4.60)]
    caution=[(-.325,1.90),(.325,1.90),(.325,2.20),(-.325,2.20),(-.325,1.90)]
    skin=panel(ctx,outline,chamfer=0,bolts=[(-.25,1.97),(.25,1.97),(-.51,4.22),(.51,4.22)],
               grooves=[caution],
               inserts=[(-.52,2.95,.16,.83),(.52,2.95,.16,.83)],
               marks=[('caution',0,2.09,.42),('unit01',.19,3.54,.22)])
    mapped(skin,'front',front)
    # Returns stop before the narrow ankle skirt to keep its existing sweep.
    fold_zs=[1.96,2.40,2.50,2.62,3.30,3.95,4.15,4.25,4.38,4.50,4.60]
    skin=combine([skin,*[obj for side in (-1,1) for obj in
                         corner_returns(ctx,fold_zs,front_edge,front,lateral,side)]],
                 'Shin plate and continuous folded front corners')
    # The upper stand-off meets the lowered skin; beam-side land stays Z4.44.
    attach(ctx,skin,'LG-400',[((0,.44,3.22),(0,front(3.22)+.01,3.22)),
                             ((0,.44,4.44),(0,front(4.30)+.01,4.30))])
    side_zs=[1.65,1.95,2.40,2.50,2.62,3.30,3.95,4.15,4.25,4.40,4.50,4.60]
    for s,pid in [(-1,'LG-410'),(1,'LG-415')]:
        outline=[(-rear(z)+.140,z) for z in reversed(side_zs)]
        outline += [(front(z)-.140,z) for z in side_zs]
        skin=panel(ctx,outline,chamfer=0,
                   bolts=[(.19,2.13),(.25,4.18),(-.71,4.25),(-.72,2.48)],
                   # 67.5 mm from the 25 mm groove edge to the hatch outline;
                   # stop below its top corner instead of drawing a diagonal.
                   grooves=[[(-.96,2.75),(-.96,3.80)]],
                   cuts=[((0,2.80,.03),(.40,.38,.24)),
                         ((-.57,3.40,.03),(.67,1.11,.24)),
                         ((.22,3.58,.03),(.22,.82,.24))],
                   marks=[('red_marks',-.86,2.67,.20)])
        mapped(skin,'side',lateral,s)
        attach(ctx,skin,pid,[((s*.665,.04,z),(s*(lateral(z)+.01),.04,z)) for z in (3.22,4.44)])
        # 25 mm assembly seam around each removable hatch.
        houtline=[(u-.57,v+3.40) for u,v in chamfered_rect(.62,1.06,.07)]
        hatch=panel(ctx,houtline,bolts=[(u-.57,z+3.40) for u in (-.22,.22) for z in (-.43,.43)],
                    slots=[(-.35,3.40,.055,.20)],chamfer=.025)
        mapped(hatch,'side',profile(lateral_points,-.012),s)
        attach(ctx,hatch,'LG-460',[((s*(lateral(z)-.020),-.18,z),(s*(lateral(z)+.005),-.36,z)) for z in (2.98,3.82)],1 if s<0 else 2)
        # 55 mm octagonal bar and 80 mm stand-off from its recessed pocket.
        rail=grab_rail(.65,.115,.0275,m['ochre'],m['gunmetal'])
        rail.rotation_euler.z=math.pi/2
        rail.location=(.22,3.58,0)
        mapped(rail,'side',profile(lateral_points,-.090),s)
        pocket=panel(ctx,[(u+.22,z+3.58) for u,z in chamfered_rect(.215,.815,.045)],
                     accent='gunmetal',chamfer=.012)
        mapped(pocket,'side',profile(lateral_points,-.120),s)
        feet=[box((.09,.18,.10),(s*(lateral(z)-.080),.22,z),m['gunmetal'],.008) for z in (3.255,3.905)]
        register(ctx,clean(combine([rail,pocket,*feet],'Bent ochre rail and recessed mounting pocket')),'LG-470',1 if s<0 else 2)
    rear_edge=profile([(1.65,.38),(2.08,.54),(2.62,.68),(3.30,.715),
                       (4.09,.73),(4.60,.52)])
    rear_zs=[1.65,1.95,2.08,2.40,2.50,2.62,3.30,3.95,4.09,4.15,4.25,4.40,4.60]
    outline=[(-rear_edge(z),z) for z in reversed(rear_zs)]+[(rear_edge(z),z) for z in rear_zs]
    shroud=panel(ctx,outline,chamfer=0,bolts=[(-.49,2.40),(.49,2.40),(-.45,4.33),(.45,4.33)],
                 marks=[('caution',0,4.45,.35)])
    lips=[]
    for z in (2.73,3.88):
        # A broad octagonal recess exposes the black bell exterior and bronze lip.
        loop=[(u,v+z) for u,v in chamfered_rect(.92,.92,.17)]
        difference(shroud,prism(loop,.22,'Exhaust aperture cutter',z=-.08))
        outer=[(u,v+z) for u,v in chamfered_rect(.98,.98,.18)]
        inner=[(u,v+z) for u,v in chamfered_rect(.92,.92,.17)]
        lips.append(rectangular_ring(outer,inner,.065,m['gunmetal'],z=-.025))
    # 220 mm removable bridge, 25 mm top/bottom seams, no doubled armor.
    difference(shroud,chamfered_box((.95,.270,.22),(0,3.305,.03),.015))
    mapped(shroud,'back',rear)
    for lip in lips: mapped(lip,'back',rear)
    returns=[obj for side in (-1,1) for obj in
             corner_returns(ctx,[1.96,2.08,2.40,2.50,2.62,3.30,3.95,4.09,4.15,4.25,4.40,4.60],
                            rear_edge,rear,lateral,side,True)]
    shroud=combine([shroud,*lips,*returns],'Rear shroud with sloped shoulders and exposed-bell recesses')
    attach(ctx,shroud,'LG-420',[((s*.48,-.835296,z),(s*.56,-rear(z)-.01,z)) for s in (-1,1) for z in (2.51,4.30)])
    bridge=panel(ctx,[(u,z+3.305) for u,z in chamfered_rect(.90,.220,.025)],
                 bolts=[(-.32,3.305),(.32,3.305)],chamfer=.025)
    mapped(bridge,'back',rear)
    attach(ctx,bridge,'LG-430',[((x,-.835296,3.45),(x,-1.35,3.305)) for x in (-.30,.30)])
