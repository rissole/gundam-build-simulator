"""System-Python image steps: RGBA stencils and q90 JPEG board composition.

python3 models/leg-lg01/src/make_decals.py
python3 models/leg-lg01/src/make_decals.py --compose
The Blender test-board script invokes both steps with system python3.
"""
import argparse
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont, ImageOps

ROOT=Path(__file__).resolve().parents[1]
REPO=ROOT.parents[1]
DECALS=ROOT/'src/decals'


def font(size,bold=False):
    choices=['/System/Library/Fonts/Supplemental/Arial Bold.ttf' if bold else '/System/Library/Fonts/Supplemental/Arial.ttf',
             '/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf' if bold else '/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf']
    for path in choices:
        if Path(path).exists(): return ImageFont.truetype(path,size)
    return ImageFont.load_default(size=size)


def generate():
    DECALS.mkdir(parents=True,exist_ok=True)
    red=(194,51,42,255)
    caution=Image.new('RGBA',(1024,200))
    draw=ImageDraw.Draw(caution)
    draw.rectangle((18,42,166,158),fill=red)
    draw.text((202,22),'CAUTION',font=font(142,True),fill=red,stroke_width=0)
    # Sparse stencil bridges in the ink, with genuinely transparent gaps.
    for x in (240,360,484,624,726,864):
        draw.rectangle((x,38,x+5,156),fill=(0,0,0,0))
    caution.save(DECALS/'caution.png',optimize=True)
    unit=Image.new('RGBA',(320,256))
    draw=ImageDraw.Draw(unit)
    draw.text((14,-7),'01',font=font(244,True),fill=(89,88,83,255))
    for x in (76,232): draw.rectangle((x,25,x+7,231),fill=(0,0,0,0))
    unit.save(DECALS/'unit01.png',optimize=True)
    marks=Image.new('RGBA',(640,192))
    draw=ImageDraw.Draw(marks)
    for y in (34,76,118):
        draw.rectangle((32,y,605,y+23),fill=red)
        draw.rectangle((400,y,410,y+23),fill=(0,0,0,0))
    marks.save(DECALS/'red_marks.png',optimize=True)
    print('DECALS:',', '.join(p.name for p in sorted(DECALS.glob('*.png'))))


def compose():
    import json
    out=ROOT/'output/kit'
    source=Image.open(ROOT/'work/test-board.png').convert('RGBA')
    raw=Image.alpha_composite(Image.new('RGBA',source.size,'white'),source).convert('RGB')
    canvas=Image.new('RGB',(1600,1120),'white')
    canvas.paste(raw,(0,80))
    draw=ImageDraw.Draw(canvas)
    draw.text((45,20),'LG-01 / SHAPE KIT',font=font(30,True),fill='#29343B')
    draw.text((770,29),'METRES  /  APPLIED GEOMETRY  /  PBR + COLOR_0',font=font(18),fill='#62686C')
    # Labels use projected world positions, so they follow camera framing.
    labels=json.loads((ROOT/'work/board-labels.json').read_text())
    for entry in labels:
        x,y=entry['pixel']
        box=draw.textbbox((0,0),entry['text'],font=font(19,True))
        w=box[2]-box[0]
        draw.text((x-w/2,y+80),entry['text'],font=font(19,True),fill='#444B50')
    draw.text((45,1084),'60–120 mm armor facets  ·  25 × 15 mm grooves  ·  recessed 6-sided heads  ·  subtle edge wear',
              font=font(18),fill='#62686C')
    canvas.save(out/'test-board.jpg',quality=90,subsampling=0)
    reference=Image.open(REPO/'design/visual-design/turnaround/style-sheet-v3.jpg').convert('RGB')
    sheet=Image.new('RGB',(3200,1190),'white')
    sheet.paste(canvas,(0,70))
    ref=ImageOps.contain(reference,(1580,1110),Image.Resampling.LANCZOS)
    sheet.paste(ref,(1610+(1580-ref.width)//2,70+(1110-ref.height)//2))
    draw=ImageDraw.Draw(sheet)
    draw.text((45,20),'GENERATED KIT / EEVEE',font=font(28,True),fill='#29343B')
    draw.text((1640,20),'APPROVED STYLE SHEET / v3',font=font(28,True),fill='#29343B')
    draw.line((1600,20,1600,1165),fill='#DBDDDE',width=2)
    sheet.save(out/'test-board-compare.jpg',quality=90,subsampling=0)
    print('COMPARISON:',out/'test-board-compare.jpg')


if __name__=='__main__':
    parser=argparse.ArgumentParser()
    parser.add_argument('--compose',action='store_true')
    args=parser.parse_args()
    compose() if args.compose else generate()
