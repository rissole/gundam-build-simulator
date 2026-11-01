"""Requested EEVEE inspection views; never changes the saved manufacturing scene.

blender --background output/leg-lg01.blend --python src/render_quick.py -- --armor hidden
Named --views: three-quarter side back knee. White camera background is composited
with system Python/Pillow; the neutral studio world is retained for reflections.
"""
import argparse
import hashlib
import json
from pathlib import Path
import shutil
import subprocess
import sys

SRC=Path(__file__).resolve().parent
PACKAGE=SRC.parent
OUT=PACKAGE/'output'
WORK=PACKAGE/'work'
VIEWS={
    'frame':((-12,-18,8.5),(0,-.1,4.82),11.05,(1000,1500)),
    'three-quarter':((-12,-18,8.5),(0,-.1,4.82),11.05,(1000,1500)),
    'side':((-18,0,5.4),(0,0,4.82),11.20,(1000,1500)),
    'back':((0,-20,5.2),(0,-.1,4.82),11.20,(1000,1500)),
    'knee':((-8,-11,7.0),(0,-.12,5.55),2.95,(1400,1400)),
}


def compose(names):
    from PIL import Image,ImageDraw,ImageOps
    coverage={}
    for name in names:
        source=Image.open(WORK/f'skeleton-{name}.png').convert('RGBA')
        bounds=source.getchannel('A').getbbox()
        coverage[name]={'alpha_bounds_px':bounds,'height_fraction':(bounds[3]-bounds[1])/source.height}
        result=Image.new('RGB',source.size,'white'); result.paste(source,mask=source.getchannel('A'))
        result.save(OUT/'renders'/f'skeleton-{name}.jpg',quality=90)
    (WORK/'skeleton-frame-coverage.json').write_text(json.dumps(coverage,indent=2)+'\n')
    needed=[OUT/'renders'/f'skeleton-{name}.jpg' for name in ('frame','knee')]
    if not all(p.exists() for p in needed): return
    left=Image.new('RGB',(1536,1024),'white'); draw=ImageDraw.Draw(left)
    draw.text((28,22),'LG-01 / STRUCTURE MODEL - REAR OUTER + KNEE',fill='#17222b',font_size=29)
    draw.text((45,67),'FRAME / ENGINES REMOVED',fill='#365d8d',font_size=20)
    full_bounds=None
    for path,rect in zip(needed,[(30,95,660,965),(735,205,1495,925)]):
        png=Image.open(WORK/(path.stem+'.png')).convert('RGBA')
        bounds=png.getchannel('A').getbbox()
        img=Image.open(path).crop(bounds)
        crop=ImageOps.contain(img,(rect[2]-rect[0],rect[3]-rect[1]))
        left.paste(crop,(rect[0]+(rect[2]-rect[0]-crop.width)//2,
                         rect[1]+(rect[3]-rect[1]-crop.height)//2))
        if full_bounds is None:
            full_bounds=(rect[0]+(rect[2]-rect[0]-crop.width)//2,
                         rect[1]+(rect[3]-rect[1]-crop.height)//2,crop.width,crop.height)
    # Concept-style framed knee inset, with an explicit crop callout.
    blue='#365d8d'
    draw.rectangle((720,185,1510,940),outline=blue,width=3)
    draw.text((738,145),'KNEE / THIGH-TO-SHIN DRIVE',fill=blue,font_size=23)
    x,y,w,h=full_bounds
    callout=(x+w*.18,y+h*.30,x+w*.94,y+h*.59)
    draw.rectangle(callout,outline=blue,width=2)
    draw.line((callout[2],callout[1],720,185),fill=blue,width=2)
    draw.line((callout[2],callout[3],720,940),fill=blue,width=2)
    draw.text((28,985),'METRES  |  Hip 9.20  /  Knee 5.10  /  Ankle 1.00  |  Thigh-to-shin cylinders',fill='#4c4c4b',font_size=21)
    concept=Image.open(SRC.parents[2]/'design/legs/images/lg01-structure-v3.jpg').convert('RGB')
    concept=ImageOps.contain(concept,(1536,1024))
    sheet=Image.new('RGB',(3072,1024),'white'); sheet.paste(left,(0,0)); sheet.paste(concept,(1536,0))
    sheet.save(OUT/'compare/skeleton-vs-lg01-structure.jpg',quality=90)


def render(names,armor):
    sys.path.insert(0,str(SRC))
    import bpy
    from mathutils import Vector
    from common import setup_studio
    from verify_scene import inventory,deferred
    for folder in (OUT/'renders',OUT/'compare',WORK): folder.mkdir(parents=True,exist_ok=True)
    deferred_keys={(r['part_id'],r['name']) for r in inventory() if deferred(r)}
    for obj in bpy.context.scene.objects:
        if obj.type=='MESH' and obj.get('part_id'):
            is_armor=(obj.get('part_id'),obj.get('part_name')) in deferred_keys
            obj.hide_render=armor=='hidden' and is_armor
    scene=bpy.context.scene
    # Remove old presentation cameras/lights only; parts/registrations stay intact.
    for obj in list(bpy.data.objects):
        if obj.type in {'LIGHT','CAMERA'}: bpy.data.objects.remove(obj,do_unlink=True)
    camera=setup_studio()
    scene.render.film_transparent=True
    scene.view_settings.exposure=-.25
    scene.view_settings.look='AgX - Medium High Contrast'
    scene.world.node_tree.nodes.get('Background').inputs['Strength'].default_value=.35
    energies={'Soft key':2800,'Fill':1100,'Edge':2000}
    for obj in bpy.context.scene.objects:
        if obj.type=='LIGHT':
            obj.data.energy=energies.get(obj.name,3200)
            obj.data.size=5.0
    light_data=bpy.data.lights.new('Full height fill','AREA')
    light_data.energy=700; light_data.shape='RECTANGLE'
    light_data.size=5.0; light_data.size_y=10.0
    light=bpy.data.objects.new('Full height fill',light_data)
    scene.collection.objects.link(light)
    light.location=(-2,-6,5)
    light.rotation_euler=(Vector((0,0,4.8))-light.location).to_track_quat('-Z','Y').to_euler()
    scene.eevee.taa_render_samples=48
    for name in names:
        for obj in bpy.context.scene.objects:
            if obj.get('part_id')=='LG-450': obj.hide_render=name=='frame'
        location,target,scale,resolution=VIEWS[name]
        camera.location=location
        camera.rotation_euler=(Vector(target)-camera.location).to_track_quat('-Z','Y').to_euler()
        camera.data.ortho_scale=scale
        scene.render.resolution_x,scene.render.resolution_y=resolution
        scene.render.resolution_percentage=100
        scene.render.image_settings.file_format='PNG'; scene.render.image_settings.color_mode='RGBA'
        scene.render.filepath=str(WORK/f'skeleton-{name}.png')
        bpy.ops.render.render(write_still=True)
    subprocess.run([shutil.which('python3'),str(Path(__file__).resolve()),'--compose','--views',*names],check=True)
    # Fingerprints stay with local review evidence; audits carry the saved blend hash.
    record={'blend':bpy.data.filepath,'blend_sha256':hashlib.sha256(Path(bpy.data.filepath).read_bytes()).hexdigest(),
            'armor':armor,'views':names,'blender':bpy.app.version_string,
            'images':{name:hashlib.sha256((OUT/'renders'/f'skeleton-{name}.jpg').read_bytes()).hexdigest()
                      for name in names},
            'source_sha256':{name:hashlib.sha256((SRC/name).read_bytes()).hexdigest()
                             for name in ('thigh.py','knee.py','shin_calf.py','render_quick.py')},
            'frame_coverage':json.loads((WORK/'skeleton-frame-coverage.json').read_text()),
            'comparison_sha256':hashlib.sha256((OUT/'compare/skeleton-vs-lg01-structure.jpg').read_bytes()).hexdigest()}
    (WORK/'skeleton-render-evidence.json').write_text(json.dumps(record,indent=2)+'\n')


def main():
    parser=argparse.ArgumentParser()
    parser.add_argument('--views',nargs='+',choices=VIEWS,default=list(VIEWS))
    parser.add_argument('--armor',choices=('hidden','shown'),default='hidden')
    parser.add_argument('--compose',action='store_true')
    argv=sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else sys.argv[1:]
    args=parser.parse_args(argv)
    if args.compose: compose(args.views)
    else: render(args.views,args.armor)


if __name__=='__main__': main()
