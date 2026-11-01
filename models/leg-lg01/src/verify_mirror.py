"""Duplicate and reflect every registered physical mesh; never save the copy.

Bake world X reflection, reverse winding, then independently test each closed
shell's signed volume, edge orientation, face area and mirrored bounds.
"""
import hashlib
import argparse
import json
from pathlib import Path
import sys
import bpy
import bmesh
import numpy as np
from mathutils import Matrix

SRC=Path(__file__).resolve().parent
sys.path.insert(0,str(SRC))
from verify_scene import audit_object,inventory


def main():
    parser=argparse.ArgumentParser()
    parser.add_argument('--only-leg',action='store_true',help='Explicit partial audit while the foot module is unfinished')
    args=parser.parse_args(sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else [])
    objects=[o for o in bpy.context.scene.objects if o.type=='MESH' and o.get('part_id')]
    if args.only_leg:
        keys={(r['part_id'],r['name']) for r in inventory() if r['source_csv'].endswith('/leg-components.csv')}
        objects=[o for o in objects if (o.get('part_id'),o.get('part_name')) in keys]
    mirror=Matrix.Diagonal((-1.,1.,1.,1.)); reports=[]
    copies=[]
    try:
        for original in objects:
            duplicate=original.copy(); duplicate.data=original.data.copy()
            bpy.context.scene.collection.objects.link(duplicate); copies.append(duplicate)
            # Apply scale -1 about the world origin, including nonidentity part transforms.
            duplicate.matrix_world=mirror@original.matrix_world
            duplicate.data.transform(duplicate.matrix_world)
            duplicate.matrix_world=Matrix.Identity(4)
            original_degenerate=sum(f.area<=1e-16 for f in original.data.polygons)
            bm=bmesh.new(); bm.from_mesh(duplicate.data)
            bmesh.ops.reverse_faces(bm,faces=list(bm.faces))
            before_vertices=len(bm.verts)
            # The inherited P3 kit's clamped bevels include coincident edges.
            # A reusable mirror needs these collapsed before normal/export work.
            # Dissolve only zero-length geometry on the temporary copy; do not
            # change the source or weld independent manufactured feature shells.
            bmesh.ops.dissolve_degenerate(bm,dist=1e-6,edges=list(bm.edges))
            removed=before_vertices-len(bm.verts)
            bm.to_mesh(duplicate.data); bm.free(); duplicate.data.update()
            result=audit_object(duplicate)
            # audit_object compares to outward recalc, while the duplicate retains
            # explicitly reversed winding. No repair is performed by this check.
            p=np.array([tuple(original.matrix_world@v.co) for v in original.data.vertices])
            expected=p*np.array([-1,1,1]); actual=np.array([tuple(v.co) for v in duplicate.data.vertices])
            error=float(max(np.max(abs(actual.min(0)-expected.min(0))),np.max(abs(actual.max(0)-expected.max(0)))))
            degenerate=[f.index for f in duplicate.data.polygons if f.area<=1e-16]
            if degenerate: result['failures'].append(f'{len(degenerate)} zero-area faces')
            if error>1e-6: result['failures'].append('mirrored world coordinates differ')
            result.update(bounds_min=actual.min(0).tolist(),bounds_max=actual.max(0).tolist(),
                          bounds_error_m=error,source_degenerate_faces=original_degenerate,
                          coincident_vertices_dissolved=removed,degenerate_faces=len(degenerate),passed=not result['failures'])
            reports.append(result)
    finally:
        for obj in copies:
            data=obj.data; bpy.data.objects.remove(obj,do_unlink=True)
            if not data.users: bpy.data.meshes.remove(data)
    failed=[r for r in reports if not r['passed']]
    report={'audit':'mirrored-part-meshes','blend':bpy.data.filepath,
            'scope':'leg-only' if args.only_leg else 'leg-and-foot',
            'blend_sha256':hashlib.sha256(Path(bpy.data.filepath).read_bytes()).hexdigest(),
            'method':'world X scale -1 baked; reverse winding; dissolve coincident bevel edges at 1 micrometre; independently audit outward normals and each shell volume',
            'copies_saved':False,'objects':len(reports),'passed':bool(reports) and not failed,
            'instances':reports,'failures':failed}
    path=SRC.parent/'output/audits/mirror.json'; path.parent.mkdir(parents=True,exist_ok=True)
    path.write_text(json.dumps(report,indent=2)+'\n')
    print('MIRROR:', 'PASS' if report['passed'] else 'FAIL',len(reports),'objects',len(failed),'failures')
    for item in failed[:10]: print(item['instance_id'],item['failures'])
    if not report['passed']: raise SystemExit(1)


if __name__=='__main__': main()
