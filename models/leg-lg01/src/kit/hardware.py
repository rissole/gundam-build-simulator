"""Low-count fasteners. Shaft/head/washer have actual thickness; no threads."""
import bpy
from mathutils import Vector, Matrix
from .core import cylinder, tube, hex_prism, combine, difference, finish, place


def bolt_washer(diameter=.06,length=.12,head_height=None,material=None,
                washer_material=None,name='Hex bolt and washer'):
    """Local bearing plane Z=0; shaft extends -Z, head/washer extend +Z.

    One mesh represents this kit feature. Inventory authors can model washers
    separately with ring() when their CSV lists a distinct washer instance.
    """
    h=head_height or diameter*.65
    wt=diameter*.13
    pieces=[cylinder(diameter*.5,length,center=(0,0,-length/2),segments=12,
                     bevel=diameter*.025,material=material),
            tube(diameter*.95,diameter*.52,wt,center=(0,0,wt/2),segments=12,
                 bevel=diameter*.02,material=washer_material or material),
            hex_prism(diameter*.82,h,center=(0,0,wt+h/2),
                      bevel=diameter*.055,material=material)]
    return combine(pieces,name)


def recessed_hex_bolt(receiver,center,diameter=.06,well_radius=None,well_depth=None,
                      material=None,name='Recessed hex bolt'):
    """Cut an octagonal BLIND well in a receiving plate, then seat a bolt.

    center is on the outer face in receiver LOCAL coordinates. The recess axis
    is local Z. The head top is below that face; receiver must be thick enough
    for the well. Return the separate fastener mesh, leaving receiver modified.
    """
    p=Vector(center)
    bpy.context.view_layer.update()
    r=well_radius or diameter*1.35
    d=well_depth or diameter*1.12
    cutter=cylinder(r,d+.004,center=p-Vector((0,0,d/2-.002)),
                    segments=8,bevel=0,name='Octagonal pocket cutter')
    cutter.matrix_world=receiver.matrix_world@cutter.matrix_world
    difference(receiver,cutter)
    bolt=bolt_washer(diameter,diameter*1.2,material=material,name=name)
    bolt.matrix_world=receiver.matrix_world@Matrix.Translation(p-Vector((0,0,d)))
    bolt['well_depth_m']=d
    bolt['head_recess_m']=d-diameter*(.65+.13)
    finish(receiver,wear=True)
    return bolt


def bolt_group(receiver,points,diameter=.06,material=None,separate=False,**kwargs):
    bolts=[recessed_hex_bolt(receiver,p,diameter,material=material,**kwargs) for p in points]
    return bolts if separate else combine(bolts,'Recessed bolt group')
