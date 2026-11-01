"""Faceted armor. XY outlines must be simple, CCW, with noncollapsing offsets."""
import math
from mathutils import Vector
from .core import mesh_object, finish, prism, difference, chamfered_rect


def inset_outline(outline, distances):
    """Intersect offset edge lines; distances[i] belongs to edge i -> i+1.

    Intended for convex armor outlines. Concave offsets that collapse or cross
    themselves must be split by the caller into simpler manufactured panels.
    """
    n = len(outline)
    ds = [distances]*n if isinstance(distances, (int,float)) else list(distances)
    if len(ds) != n or min(ds) < 0:
        raise ValueError('Supply a nonnegative chamfer for every outline edge')
    area = sum(outline[i][0]*outline[(i+1)%n][1]-outline[(i+1)%n][0]*outline[i][1] for i in range(n))
    if area <= 0:
        raise ValueError('Outline must be counterclockwise')
    lines = []
    for i in range(n):
        a, b = Vector(outline[i]), Vector(outline[(i+1)%n])
        d = (b-a).normalized()
        lines.append((a+Vector((-d.y,d.x))*ds[i], d))
    result=[]
    cross=lambda a,b: a.x*b.y-a.y*b.x
    for i in range(n):
        a,u = lines[i-1]
        b,v = lines[i]
        den = cross(u,v)
        p = b if abs(den)<1e-9 else a+u*(cross(b-a,v)/den)
        result.append(tuple(p))
    # A point outside any inward half-plane indicates a collapsed convex inset.
    if any(cross(d,Vector(p)-a)<-1e-7 for p in result for a,d in lines):
        raise ValueError('Chamfer collapses the outline; reduce its width')
    return result


def plate(outline, thickness=.16, chamfer=.06, chamfer_depth=None,
          material=None, name='Armor plate', wear=True):
    """Extrude an outline with independent per-edge top AND bottom chamfers.

    chamfer is a scalar or list aligned with outline edges. Width and depth are
    independent, allowing a broad 60–120 mm facet on comparatively thin armor.
    The back is Z=0 and the outer face is Z=thickness. No booleans are used.
    """
    ds = [chamfer]*len(outline) if isinstance(chamfer,(int,float)) else list(chamfer)
    if thickness <= 0:
        raise ValueError('Plate thickness must be positive')
    if max(ds) == 0:
        return finish(prism(outline,thickness,name,material),wear=wear)
    depth = min(max(ds)*.6, thickness*.3) if chamfer_depth is None else chamfer_depth
    if not 0 < depth < thickness/2:
        raise ValueError('Chamfer depth must leave a positive side wall')
    inset = inset_outline(outline,ds)
    return loft([(0,inset),(depth,outline),(thickness-depth,outline),(thickness,inset)],
                material=material,name=name,wear=wear)


def loft(sections, material=None, name='Faceted loft', wear=True, bevel=0):
    """Closed loft from [(z, CCW outline), ...], equal vertex count per ring.

    Use chamfered_rect for octagonal limb outlines. Additional rings create
    multi-face leading noses and shoulders without a smoothing subdivision.
    """
    if len(sections)<2 or len({len(p) for z,p in sections}) != 1:
        raise ValueError('Loft requires >=2 outlines with matching vertex counts')
    if any(b[0] <= a[0] for a,b in zip(sections,sections[1:])):
        raise ValueError('Loft heights must increase')
    n=len(sections[0][1])
    vertices=[(x,y,z) for z,outline in sections for x,y in outline]
    faces=[tuple(reversed(range(n))), tuple(range((len(sections)-1)*n,len(sections)*n))]
    faces += [(k*n+i,k*n+(i+1)%n,(k+1)*n+(i+1)%n,(k+1)*n+i)
              for k in range(len(sections)-1) for i in range(n)]
    return finish(mesh_object(name,vertices,faces,material),bevel=bevel,wear=wear)


def faceted_nose(width=1.8, height=1.3, depth=.35, material=None, name='Faceted nose'):
    """A broad shoulder and smaller chisel face, ready to aim onto a toe/knee."""
    return loft([(0,chamfered_rect(width,height,.12)),
                 (depth*.58,chamfered_rect(width*.91,height*.86,.14)),
                 (depth,chamfered_rect(width*.65,height*.64,.09))],material,name)


def _ribbon(path,width):
    pts=[Vector(p[:2]) for p in path]
    if len(pts)<2 or any((b-a).length<1e-8 for a,b in zip(pts,pts[1:])):
        raise ValueError('A groove needs two or more distinct path points')
    sides=[]
    for i,p in enumerate(pts):
        a=(pts[min(i+1,len(pts)-1)]-pts[max(0,i-1)]).normalized()
        n=Vector((-a.y,a.x))
        # Miter compensation at bends, capped to avoid spikes on a U-turn.
        next_d=(pts[min(i+1,len(pts)-1)]-p).normalized() if i<len(pts)-1 else a
        factor=max(.3,abs(n.dot(Vector((-next_d.y,next_d.x)))))
        sides.append((p+n*width/(2*factor),p-n*width/(2*factor)))
    return [tuple(a) for a,b in sides]+[tuple(b) for a,b in reversed(sides)]


def panel_line(obj,path,surface_z,width=.025,depth=.015,material=None):
    """Machine a real blind groove in obj's LOCAL XY top face, and return obj.

    Arbitrary bent paths can cross existing bevel topology: use the exact
    Boolean fallback here. Insets/lofts/hatch seams use explicit ring topology.
    A remaining floor is required; paths may exit the plate edge deliberately.
    """
    if min(width,depth)<=0:
        raise ValueError('Groove dimensions must be positive')
    cutter=prism(_ribbon(path,width),depth+.004,'Panel groove cutter',z=surface_z-depth)
    cutter.matrix_world=obj.matrix_world.copy()
    difference(obj,cutter)
    if material:
        if material.name not in obj.data.materials:
            obj.data.materials.append(material)
        mi=obj.data.materials.find(material.name)
        for f in obj.data.polygons:
            if abs(f.center.z-(surface_z-depth))<.0001 and f.normal.z>.9:
                f.material_index=mi
    return finish(obj,wear=True)
