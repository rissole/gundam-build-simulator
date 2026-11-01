"""Self-contained service fixtures, back face Z=0 and front toward +Z."""
from .core import (chamfered_rect, rectangular_ring, chamfered_box, combine,
                   finish, place, prism)
from .plates import plate
from .hardware import bolt_group, bolt_washer
from .mechanisms import swept_bar


def access_hatch(width=1.05,height=1.3,depth=.14,seam=.025,material=None,
                 dark=None,steel=None,name='Recessed access hatch'):
    """Explicit inset ring, inset lid, continuous shadow seam and flush latch."""
    outer=chamfered_rect(width,height,.09)
    inner=chamfered_rect(width-.13,height-.13,.065)
    border=finish(rectangular_ring(outer,inner,depth,material),.009,wear=True)
    backing=prism(outer,.025,'Hatch backing',dark)
    lid=plate(chamfered_rect(width-.13-2*seam,height-.13-2*seam,.055),
              depth-.045,.018,material=material,name='Inset hatch lid')
    lid.location.z=.025
    points=[(sx*(width/2-.17),sy*(height/2-.17),depth-.045)
            for sx in (-1,1) for sy in (-1,1)]
    bolts=bolt_group(lid,points,.038,material=steel or dark)
    latch=chamfered_box((.085,.29,.035),(width/2-.19,0,depth-.015),.012,dark,'Flush latch recess')
    lever=chamfered_box((.033,.18,.018),(width/2-.19,0,depth+.002),.005,steel,'Flush latch')
    return combine([backing,border,lid,bolts,latch,lever],name)


def grab_rail(length=1.05,rise=.20,radius=.055,material=None,steel=None,name='Ochre grab rail'):
    """Faceted bent bar along X, two feet with visibly seated 6-sided bolts."""
    half=length/2
    path=[(-half,0,.035),(-half,0,rise*.65),(-half+rise*.35,0,rise),
          (half-rise*.35,0,rise),(half,0,rise*.65),(half,0,.035)]
    pieces=[swept_bar(path,radius,8,material)]
    for x in (-half,half):
        pieces.append(chamfered_box((radius*3.6,radius*4.8,.045),(x,0,.0225),.016,steel))
        for y in (-radius*1.6,radius*1.6):
            bolt=bolt_washer(.033,.035,material=steel)
            bolt.location=(x,y,.046)
            pieces.append(bolt)
    return combine(pieces,name)


def louvered_intake(width=1.1,height=1.6,depth=.22,slats=5,material=None,
                    dark=None,name='Vertical louvered intake'):
    """Ochre opening with vertical gunmetal louvers and a recessed back wall."""
    frame=finish(rectangular_ring(chamfered_rect(width,height,.12),
                                  chamfered_rect(width-.19,height-.19,.07),
                                  depth,material),.025,wear=True)
    back=prism(chamfered_rect(width-.12,height-.12,.09),.035,'Intake darkness',dark)
    pieces=[frame,back]
    for i in range(slats):
        x=(i-(slats-1)/2)*(width-.28)/slats
        blade=chamfered_box((.055,height-.26,depth*.68),(x,0,depth*.48),.008,dark,'Vertical intake blade')
        # A modest cant exposes a real blade flank in the frontal view.
        blade.rotation_euler.y=.18
        pieces.append(blade)
    return combine(pieces,name)
