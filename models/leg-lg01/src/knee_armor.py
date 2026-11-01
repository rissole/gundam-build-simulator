"""Upper-shin shield, angular guards and two recessed bearing covers."""
from kit import combine, tube, cylinder, difference, finish
from thigh import register, strut, box
from thigh_armor import panel, mapped, attach,profile


def build(ctx):
    m=ctx.materials
    if not any(o.get('part_id')=='LG-310' for o in ctx.parts):
        raise RuntimeError('Kneecap requires the P3 shin-mounted LG-310 bracket')
    outline=[(-.22,4.69),(.22,4.69),(.39,5.26),(.31,5.48),(-.31,5.48),(-.39,5.26)]
    shield=panel(ctx,outline,bolts=[(-.23,5.29),(.23,5.29),(-.12,4.83),(.12,4.83)],accent='ochre')
    # Chisel ridge, with a broader top and a long taper to the tip.
    mapped(shield,'front',profile([(4.69,.638),(5.17,.790),(5.48,.692)]))
    attach(ctx,shield,'LG-300',[( (x,.54,5.04),(x,.76,5.04)) for x in (-.15,.15)])
    for s,pid in [(-1,'LG-320'),(1,'LG-325')]:
        outline=[(-.25,4.62),(.20,4.62),(.42,4.88),(.42,5.38),(.19,5.59),(-.25,5.57),(-.42,5.35),(-.42,4.87)]
        guard=panel(ctx,outline,bolts=[(-.22,4.79),(.21,5.43)])
        # A real circular opening reveals a separately removable circular cap.
        cutter=cylinder(.285,.20,(0,5.10,.03),segments=48,bevel=0)
        difference(guard,cutter)
        mapped(guard,'side',lambda z:.61,s)
        attach(ctx,guard,pid,[((s*.515,y,z),(s*.62,y,z)) for y,z in [(.25,5.34),(.25,4.92)]])
        cover=combine([tube(.274,.229,.045,(s*.6025,0,5.10),(1,0,0),48,.006,m['gunmetal']),
                       cylinder(.228,.024,(s*.607,0,5.10),(1,0,0),48,.006,m['gunmetal']),
                       *[box((.045,.12,.065),(s*.603,y,5.10),m['gunmetal'],.005) for y in (-.28,.28)]],
                      'Recessed circular bearing cover')
        register(ctx,cover,'LG-330',1 if s<0 else 2)
