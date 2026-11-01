"""System Python + Pillow: fixed concept patches vs Blender-projected part points.

python3 models/leg-lg01/work/tone_probe.py --evidence .../compare-evidence.json
RGB is the per-channel median in a small square. Y' is Rec.709-weighted sRGB
code value (not linear luminance). Surface anchors and visibility come from
world_to_camera_view / ray casts in render_compare.py; no render-pixel tuning.
"""
import argparse
import json
from pathlib import Path
from PIL import Image, ImageDraw, ImageStat

ROOT = Path(__file__).resolve().parents[3]
CONCEPT = ROOT / 'design/legs/images/lg01-assembled-v3.jpg'
CONCEPT_POINTS = {
    'lit_thigh': (1030, 270),
    'shaded_thigh': (960, 360),
    'ochre_kneecap': (1030, 452),
    'dark_knee': (1090, 425),
    'calf_front': (1030, 550),
}


def patch(image, pixel, radius):
    x, y = pixel
    box = (x-radius, y-radius, x+radius+1, y+radius+1)
    if box[0] < 0 or box[1] < 0 or box[2] > image.width or box[3] > image.height:
        raise ValueError(f'Patch outside image: {box}')
    rgb = ImageStat.Stat(image.crop(box)).median
    return {'rgb': rgb, 'y_srgb': round(sum(c*w for c,w in zip(rgb, (.2126,.7152,.0722))), 1),
            'pixel':pixel, 'radius':radius}


def meets(name, p):
    if not p.get('visible', True):
        return 'OCCLUDED'
    y = p['y_srgb']
    if name in {'lit_thigh','calf_front'}:
        return 'PASS' if 215 <= y <= 228 and max(p['rgb']) <= 235 else 'MISS'
    if name == 'shaded_thigh':
        return 'PASS' if 165 <= y <= 190 else 'MISS'
    if name == 'ochre_kneecap':
        return 'PASS' if all(abs(c-t)<=20 for c,t in zip(p['rgb'], (205,135,40))) else 'MISS'
    if name == 'dark_knee':
        return 'PASS' if 55 <= y <= 100 else 'MISS'
    return 'PASS' if p['rgb'] == [255]*3 else 'MISS'


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--evidence', type=Path, required=True)
    parser.add_argument('--render-dir',type=Path)
    args=parser.parse_args()
    data=json.loads(args.evidence.read_text())
    result={'concept':{},'views':{},'blend_sha256':data['blend_sha256_at_start']}
    im=Image.open(CONCEPT).convert('RGB')
    for name,pixel in CONCEPT_POINTS.items():
        result['concept'][name]=patch(im,pixel,4)
    table=['| Region | Concept RGB / Y′ | Front RGB / Y′ | Three-quarter RGB / Y′ |',
           '| --- | --- | --- | --- |']
    for view in ('front','three-quarter'):
        key='lg01-assembled-'+view
        info=data['renders'][key]
        # Probe actual composed JPEGs, including the white background/shadow.
        path=(args.render_dir / ('r-'+key+'.jpg')) if args.render_dir else Path(info['jpg'])
        image=Image.open(path).convert('RGB')
        overlay=image.copy(); draw=ImageDraw.Draw(overlay)
        values={}
        for name,point in info['tone_points'].items():
            if point.get('missed'):
                values[name]={'status':'missed anchor','part_id':point['part_id']}; continue
            p=patch(image,point['pixel'],point['radius'])
            p.update(visible=point['visible'], part_id=point['part_id'], world=point['world'])
            p['status']=meets(name,p); values[name]=p
            x,y=point['pixel'];r=point['radius']+2
            draw.rectangle((x-r,y-r,x+r,y+r),outline='magenta',width=1)
            draw.text((x+r+2,y),name,fill='magenta')
        values['background']=patch(image,(20,20),4)
        values['background']['status']=meets('background',values['background'])
        values['difference']=round(values['lit_thigh']['y_srgb']-values['shaded_thigh']['y_srgb'],1)
        result['views'][view]=values
        overlay.save(args.evidence.parent/('tone-patches-'+view+'.png'))
    def cell(p):
        return f"{tuple(p['rgb'])} / {p['y_srgb']}" + (f" **{p['status']}**" if 'status' in p else '')
    for name in (*CONCEPT_POINTS,'background'):
        table.append('| '+name+' | '+('—' if name=='background' else cell(result['concept'][name]))+' | '+
                     ' | '.join(cell(result['views'][view][name]) if name in result['views'][view] else 'MISSING' for view in ('front','three-quarter'))+' |')
    table.append('| Lit − shaded Y′ | '+str(round(result['concept']['lit_thigh']['y_srgb']-result['concept']['shaded_thigh']['y_srgb'],1))+' | '+
                 ' | '.join(str(result['views'][v]['difference'])+' '+('PASS' if result['views'][v]['difference']>=30 else 'MISS') for v in ('front','three-quarter'))+' |')
    result['all_targets_met'] = all(
        all(v.get('status') == 'PASS' for k,v in view.items() if k != 'difference')
        and view['difference'] >= 30 for view in result['views'].values())
    text='\n'.join(table)+'\n'
    print(text,flush=True)
    (args.evidence.parent/'tone-probe.json').write_text(json.dumps(result,indent=2)+'\n')
    (args.evidence.parent/'tone-probe.md').write_text(text)

if __name__=='__main__':
    main()
