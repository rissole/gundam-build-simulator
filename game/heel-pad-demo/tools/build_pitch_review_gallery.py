"""Build labelled contact sheets/index from actual Godot review captures (Pillow).
Run after --pitch-test --pitch-review. Does not assign visual approval.
"""
import argparse
import hashlib
import html
import json
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

PROJECT = Path(__file__).resolve().parents[1]
ROOT = PROJECT.parents[1]
OUT = PROJECT / 'verification/pitch-visual-review'
try:
    FONT = ImageFont.truetype('/System/Library/Fonts/Helvetica.ttc', 18)
except OSError:
    FONT = ImageFont.load_default(size=18)

def tile(canvas, path, xy, size, label):
    im = Image.open(OUT / path).convert('RGB')
    im.thumbnail((size[0], size[1] - 28))
    canvas.paste(im, (xy[0] + (size[0]-im.width)//2, xy[1]+28))
    ImageDraw.Draw(canvas).text((xy[0]+5, xy[1]+5), label, font=FONT, fill='white')

def main():
    global OUT
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--input', type=Path, required=True, help='Capture directory printed as REVIEW_OUTPUT by the runner.')
    OUT = parser.parse_args().input.resolve()
    data = json.loads((OUT/'captures.json').read_text())
    sheets = {}
    working = [(p, f'{r["owner"]} {r["page"]}: {r["phase"]}') for r in data['records']
               if r['phase'] in ('end','ready') for p in r['captures'] if p.endswith('-hud.png')]
    for start in range(0,len(working),4):
        canvas=Image.new('RGB',(1920,1260),'#111a22')
        for i,(path,label) in enumerate(working[start:start+4]):tile(canvas,path,((i%2)*960,(i//2)*630),(960,630),label)
        canvas.save(OUT/f'working-views-{start//4+1}.jpg',quality=94)
    for r in data['records']:
        paths=[p for p in r['captures'] if 'rotation-' in p]
        if not paths:continue
        canvas=Image.new('RGB',(1440,1280),'#111a22')
        for i,path in enumerate(paths):tile(canvas,path,((i%3)*480,(i//3)*320),(480,320),f'{r["owner"]} R-drag frame {i*4}')
        canvas.save(OUT/f'{r["owner"]}-rotation.jpg',quality=94)
        frames=[]
        for path in paths:
            im=Image.open(OUT/path).convert('RGB');im.thumbnail((1008,630));frames.append(im)
        frames[0].save(OUT/f'{r["owner"]}-rotation.gif',save_all=True,append_images=frames[1:],duration=140,loop=0)
    for key, page in data['pages'].items():
        rows = [r for r in data['records'] if r['owner']==page['owner'] and r['page']==page['page']]
        images = []
        for r in rows:
            if r['phase'] in ('begin','end','ready','mounted','mount-preview'):
                images += [(p, r['phase']+' '+p.split(r['phase']+'-')[-1].removesuffix('.png')) for p in r['captures'] if 'rotation' not in p and 'hud' not in p]
        # Separate HUD sheets preserve the actual diagram/text at readable size.
        hud = [(p, r['phase']+(' scrolled' if 'scrolled' in p else '')) for r in rows for p in r['captures'] if 'hud' in p]
        if hud:
            canvas = Image.new('RGB',(480*len(hud),840),'#111a22')
            for i,(path,label) in enumerate(hud):
                im = Image.open(OUT/path).convert('RGB')
                im = im.crop((int(im.width*.74),0,im.width,int(im.height*.76)))
                im.thumbnail((480,800))
                canvas.paste(im,(i*480,30))
                ImageDraw.Draw(canvas).text((i*480+5,5),label,font=FONT,fill='white')
            name=key+'-manual.jpg';canvas.save(OUT/name,quality=94)
            sheets.setdefault(key,[]).append(name)
        for start in range(0,len(images),6):
            batch=images[start:start+6]
            canvas=Image.new('RGB',(1440,780),'#111a22')
            for i,(path,label) in enumerate(batch):tile(canvas,path,((i%3)*480,(i//3)*390),(480,390),label)
            name=f'{key}-overview-{start//6+1}.jpg';canvas.save(OUT/name,quality=94)
            sheets.setdefault(key,[]).append(name)
        # Interrupted/failed gameplay runs can still contain useful diagnostic
        # pages. Only paired placements belong in the before/after sheet.
        slots=[r for r in rows if r['phase']=='preview' and any(
            end['phase']=='installed' and end['slot']==r['slot'] for end in rows)]
        for start in range(0,len(slots),2):
            batch=slots[start:start+2]
            canvas=Image.new('RGB',(1440,1160),'#111a22')
            for j,preview in enumerate(batch):
                installed=next(r for r in rows if r['phase']=='installed' and r['slot']==preview['slot'])
                for angle in range(2):
                    for col,(record,state) in enumerate([(preview,'before'),(preview,'preview'),(installed,'installed')]):
                        paths=[p for p in record['captures'] if p.endswith(f'-{state}-exposed-{angle}.png')]
                        if not paths:paths=[p for p in record['captures'] if p.endswith(f'-{state}-service-{angle}.png')]
                        tile(canvas,paths[0],(col*480,(j*2+angle)*290),(480,290),f'{preview["slot"]} {state} / {angle}')
            name=f'{key}-placements-{start//2+1}.jpg';canvas.save(OUT/name,quality=95)
            sheets.setdefault(key,[]).append(name)
    hashes={}
    files=[]
    for folder in ['scripts','tests','assets','tools']:
        files += [p for p in (PROJECT/folder).rglob('*') if p.is_file() and p.suffix in ('.gd','.py','.json','.glb')]
    files += list((ROOT/'models/foot-fa01/src').glob('*.py'))
    files += [ROOT/'models/foot-fa01/output/parts-manifest.json',PROJECT/'project.godot',ROOT/'.agents/skills/gundam-assembly-review/SKILL.md']
    for p in sorted(files):hashes[str(p.relative_to(ROOT))]=hashlib.sha256(p.read_bytes()).hexdigest()
    if data.get('fingerprints'):
        # Provenance is captured before the run, never inferred from later files.
        hashes={str((PROJECT/k.removeprefix('res://')).resolve().relative_to(ROOT)):v for k,v in data['fingerprints'].items()}
    (OUT/'fingerprints.json').write_text(json.dumps(hashes,indent=2)+'\n')
    (OUT/'sheets.json').write_text(json.dumps(sheets,indent=2)+'\n')
    content=['<!doctype html><meta charset="utf-8"><title>Pitch actuator visual review</title><style>body{background:#111a22;color:#eee;font:16px system-ui;margin:24px}a{color:#8fdfbd}img{max-width:100%;height:auto}details{margin:20px 0}figure{margin:10px 0}nav a{margin-right:16px}</style><h1>Pitch actuator: rendered review evidence</h1><p>Live game placements, Godot Compatibility renderer. Exposed inspection hides only the barrel; service and opaque views retain it. Capture success is not visual approval. See review.md for findings.</p><nav>']
    content += [f'<a href="#{key}">{key}</a>' for key in sheets]
    content += ['</nav>']
    for key,names in sheets.items():
        page=data['pages'][key]
        content += [f'<h2 id="{key}">{key}: {html.escape(page["title"])}</h2><p>{html.escape(page["body"])}</p>']
        content += [f'<details><summary>{name}</summary><a href="{name}"><img loading="lazy" src="{name}"></a></details>' for name in names]
        content += ['<details><summary>Full-resolution captures</summary>']
        content += [f'<a href="{p}">{p}</a><br>' for r in data['records'] if r['owner']==page['owner'] and r['page']==page['page'] for p in r['captures']]
        content += ['</details>']
    (OUT/'index.html').write_text('\n'.join(content))
    print(f'{len(sheets)} pages; {sum(map(len,sheets.values()))} sheets; {len(hashes)} fingerprints')

if __name__=='__main__':main()
