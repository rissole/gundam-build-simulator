"""LG-01 hard-surface kit; all distances METRES, angles RADIANS.

Constructors return independent mesh objects with applied bevel geometry and
outward normals. Plates/service features face +Z in local XY. Turned primitives
accept center/axis; place(obj, origin, axis, roll) aims any local feature. Only
register() in common.py grants inventory identity. See module docstrings for
coordinate contracts and permitted intersecting integral shells.
"""
from .core import (frame, mesh_object, normals, finish, place, combine, difference,
                   chamfered_rect, prism, chamfered_box, lathe, cylinder, tube,
                   ring, hex_prism, rectangular_ring, sphere)
from .plates import plate, loft, faceted_nose, inset_outline, panel_line
from .hardware import bolt_washer, recessed_hex_bolt, bolt_group
from .mechanisms import (bell_nozzle, swept_bar, cable_bundle, spherical_eye,
                         hydraulic_cylinder, clevis, smooth_path)
from .service import access_hatch, grab_rail, louvered_intake
