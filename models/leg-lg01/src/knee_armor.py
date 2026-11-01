"""Volumetric chisel shield, faceted guards and stepped recessed bearing caps."""
from kit import combine, tube, cylinder, difference, mesh_object
from kit.plates import inset_outline
from thigh import register, box
from thigh_armor import panel, mapped, attach, profile, clean, folded_strip


def build(ctx):
    m=ctx.materials
    if not any(o.get('part_id')=='LG-310' for o in ctx.parts):
        raise RuntimeError('Kneecap requires the P3 shin-mounted LG-310 bracket')
    outline=[(-.22,4.69),(.22,4.69),(.39,5.26),(.31,5.48),(-.31,5.48),(-.39,5.26)]
    inner=inset_outline(outline,.080)
    ridge=profile([(4.69,.665),(5.17,.790),(5.48,.715)])
    shield=panel(ctx,inner,bolts=[(-.23,5.29),(.23,5.29),(-.12,4.83),(.12,4.83)],
                 accent='ochre',chamfer=.012)
    mapped(shield,'front',ridge)
    # Annular folded rim: perimeter at Y.64, ochre chisel front at Y.85.
    # The rear stays open around the shin bracket and hinge movement space.
    # Split the rim at the chisel ridge too, so its inner edge meets the
    # bent face continuously instead of leaving a triangular side opening.
    outer_ring=[]; inner_ring=[]
    for i,(a,b) in enumerate(zip(inner,inner[1:]+inner[:1])):
        ts=[0.]
        if abs(b[1]-a[1])>1e-8:
            t=(5.17-a[1])/(b[1]-a[1])
            if 0<t<1: ts.append(t)
        c,d=outline[i],outline[(i+1)%len(outline)]
        for t in sorted(ts):
            inner_ring.append(tuple(x+(y-x)*t for x,y in zip(a,b)))
            outer_ring.append(tuple(x+(y-x)*t for x,y in zip(c,d)))
    outline,inner=outer_ring,inner_ring
    verts=[(x,.640,z) for x,z in outline]+[(x,ridge(z)+.052,z) for x,z in inner]
    verts += [(x,.610,z) for x,z in outline]+[(x,ridge(z)+.012,z) for x,z in inner]
    n=len(outline); faces=[]
    for i in range(n):
        j=(i+1)%n
        patches=[(i,j,n+j,n+i),(2*n+i,3*n+i,3*n+j,2*n+j),
                 (i,2*n+i,2*n+j,j),(n+i,n+j,3*n+j,3*n+i)]
        for a,b,c,d in patches:
            faces.extend([(a,b,c),(a,c,d)])
    rim=clean(mesh_object('Pale folded kneecap returns',verts,faces,m['armor']))
    shield=combine([shield,rim],'Ochre chisel shield with pale folded rim')
    attach(ctx,shield,'LG-300',[( (x,.54,5.04),(x,.76,5.04)) for x in (-.15,.15)])
    for s,pid in [(-1,'LG-320'),(1,'LG-325')]:
        outline=[(-.25,4.62),(.20,4.62),(.42,4.88),(.42,5.38),(.19,5.59),(-.25,5.57),(-.42,5.35),(-.42,4.87)]
        guard=panel(ctx,outline,chamfer=.075,bolts=[(-.22,4.79),(.21,5.43)])
        cutter=cylinder(.285,.20,(0,5.10,.03),segments=48,bevel=0)
        difference(guard,cutter)
        # Sculpt the central guard land inward; outer perimeter stays |X|.67.
        # Facets span 60–80 mm outside the recessed concentric bearing cover.
        mapped(guard,'side',profile([(4.62,.580),(4.88,.610),(5.35,.610),(5.59,.580)]),s)
        # 110 mm front-facing return adds joint mass beside the shield without
        # widening the bearing/axle. Ends fold back to the original guard edge.
        rows=[((s*x,.415,z),(s*inner,y,z)) for z,x,inner,y in
              [(4.82,.654,.610,.440),(4.88,.670,.560,.490),
               (5.35,.670,.560,.490),(5.38,.666,.560,.490),
               (5.44,.658,.610,.440)]]
        guard=combine([guard,folded_strip(rows,m['armor'],'Knee guard front return',.025)],
                      'Faceted guard and frontal return')
        attach(ctx,guard,pid,[((s*.515,y,z),(s*.62,y,z)) for y,z in [(.25,5.34),(.25,4.92)]])
        cover=combine([tube(.274,.239,.045,(s*.6025,0,5.10),(1,0,0),64,.006,m['gunmetal']),
                       tube(.238,.206,.026,(s*.616,0,5.10),(1,0,0),64,.004,m['steel']),
                       tube(.205,.179,.025,(s*.598,0,5.10),(1,0,0),64,.004,m['gunmetal']),
                       cylinder(.178,.024,(s*.580,0,5.10),(1,0,0),64,.004,m['gunmetal']),
                       *[box((.045,.12,.065),(s*.603,y,5.10),m['gunmetal'],.005) for y in (-.28,.28)]],
                      'Two stepped rings and recessed bearing cover')
        register(ctx,cover,'LG-330',1 if s<0 else 2)
