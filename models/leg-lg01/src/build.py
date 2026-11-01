"""Build registered LG-01 modules, save the scene and JSON/CSV manifests.

blender --background --factory-startup --python-exit-code 1 --python models/leg-lg01/src/build.py
See common.py for the build(ctx) API and coordinate/identity contracts. Missing
modules are deliberately skipped; exceptions INSIDE existing modules propagate.
"""
import importlib
from pathlib import Path
import sys
sys.path.insert(0,str(Path(__file__).resolve().parent))
import bpy
from common import init_scene, setup_studio, write_manifest

MODULES=('thigh','knee','shin_calf','foot_fa02','thigh_armor','knee_armor',
         'shin_calf_armor','foot_fa02_armor')


def main():
    ctx=init_scene()
    for name in MODULES:
        if importlib.util.find_spec(name) is None:
            print('SKIP missing part module:',name,flush=True)
            continue
        module=importlib.import_module(name)
        print('BUILD',name,flush=True)
        module.build(ctx)
    setup_studio()
    manifest=write_manifest(ctx)
    bpy.context.scene['part_count']=len(ctx.parts)
    bpy.context.scene['revision']='LG-01-3D-01'
    bpy.ops.wm.save_as_mainfile(filepath=str(ctx.output/'leg-lg01.blend'))
    print('BUILD COMPLETE:',manifest['object_count'],'objects;',manifest['triangles'],'triangles',flush=True)


if __name__=='__main__': main()
