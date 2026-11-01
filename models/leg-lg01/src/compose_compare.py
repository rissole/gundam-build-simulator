"""Pillow composition for render_compare.py; no Blender dependency.

python3 models/leg-lg01/src/compose_compare.py --evidence ... --out ...
All panels are composed at one scale; output sheets are 2400 px tall by default.
Side images are reflected ONLY for display, to match the concept's toe direction.
"""
import argparse
import json
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont, ImageOps, ImageMath, ImageFilter

ROOT = Path(__file__).resolve().parents[3]
BASE = (1536, 1024)
INK = '#15252f'
BLUE = '#426388'
CONCEPTS = {
    'lg01-assembled': 'design/legs/images/lg01-assembled-v3.jpg',
    'lg01-armor': 'design/legs/images/lg01-armor-v3.jpg',
    'lg01-structure': 'design/legs/images/lg01-structure-v3.jpg',
    'fa02-assembled': 'design/legs/foot-and-ankle/images/fa02-assembled.jpg',
    'fa02-armor': 'design/legs/foot-and-ankle/images/fa02-armor.jpg',
    'fa02-structure': 'design/legs/foot-and-ankle/images/fa02-structure.jpg',
}
# Inspected on the 1502 × 1047 turnaround-v3. Anatomical left = image-right
# in front, image-left in back. Same y limits and resize factor in all views.
# Side includes the existing hand occlusion; do not retouch the approved art.
TURNAROUND_CROPS = {'front': (303, 500, 456, 990),
                    'side': (617, 500, 906, 990),
                    'back': (1037, 500, 1198, 990)}


def font(size):
    for path in ('/System/Library/Fonts/Supplemental/Arial.ttf',
                 '/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf'):
        if Path(path).exists():
            return ImageFont.truetype(path, size)
    return ImageFont.load_default(size=size)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--evidence', type=Path, required=True)
    parser.add_argument('--out', type=Path, required=True)
    args = parser.parse_args()
    data = json.loads(args.evidence.read_text())
    scale = 2400 / 1024 * data['res_scale']
    width, height = round(1536 * scale), round(1024 * scale)
    args.out.mkdir(parents=True, exist_ok=True)
    render_out = args.out.parent / 'renders'
    render_out.mkdir(parents=True, exist_ok=True)
    cache = {}
    for key, info in data['renders'].items():
        raw = Image.open(info['png']).convert('RGBA')
        # Geometry bounds come from Blender, independent of the catcher's alpha.
        image = Image.new('RGB', raw.size, 'white')
        if info.get('floor_passes'):
            passes = info['floor_passes']
            shaded = Image.open(passes['shadow']).convert('L').convert('F')
            clear_rgba = Image.open(passes['clear']).convert('RGBA')
            clear = clear_rgba.convert('L').convert('F')
            floor_mask = clear_rgba.getchannel('A').convert('F')
            if info['kind'].startswith('leg'):
                # A tall leg also casts a remote shadow far across the studio.
                # Keep the local contact patch beneath the foot for the sheet.
                end = 1 - info['z0'] - .035
                start = end - .10
                fade = Image.new('L', (1, shaded.height))
                fade.putdata([round(255 * min(1, max(0, (y / shaded.height - start) / (end - start))))
                              for y in range(shaded.height)])
                fade = fade.resize(shaded.size).convert('F')
                floor_mask = ImageMath.lambda_eval(lambda v: v['a'] * v['b'] / 255,
                                                  a=floor_mask, b=fade)
            alpha = raw.getchannel('A').resize(shaded.size, Image.Resampling.LANCZOS).convert('F')
            # Confine the retained shadow to contact near the subject. Without
            # this soft falloff a long rim-light shadow can meet the image edge
            # and leave a conspicuous rectangular cutoff on the white sheet.
            contact = alpha.convert('L').filter(ImageFilter.GaussianBlur(shaded.width * .07))
            contact = contact.point(lambda value: min(255, value * 4)).convert('F')
            floor_mask = ImageMath.lambda_eval(lambda v: v['a'] * v['b'] / 255,
                                              a=floor_mask, b=contact)
            # Suppress subject pixels: only the actual shadow cast on the floor
            # is retained. A ratio cancels the large softboxes' uneven lighting.
            floor = ImageMath.lambda_eval(
                lambda v: 255.5 - 160 * (1 - v['a'] / (v['b'] + .001)) * (1 - v['m'] / 255) * v['f'] / 255,
                a=shaded, b=clear, m=alpha, f=floor_mask).convert('L')
            floor = floor.filter(ImageFilter.GaussianBlur(.65)).resize(raw.size, Image.Resampling.LANCZOS)
            image = Image.merge('RGB', (floor, floor, floor))
        image.paste(raw, mask=raw.getchannel('A'))
        if info['mirror_display']:
            image = ImageOps.mirror(image)
        # Short leaders stay in the reserved gap below each part silhouette.
        # Source meshes and camera projections are never moved by composition.
        draw = ImageDraw.Draw(image)
        label_font = font(max(12, round(image.width * .0105)))
        for item in info.get('labels', []):
            x0,y0,x1,y1 = item['bounds']
            x = (x0+x1)/2
            y = min(image.height-20, y1 + image.height*.018)
            label = item['text']
            box = draw.textbbox((0,0), label, font=label_font)
            tx = min(image.width-(box[2]-box[0])-5, max(5, x-(box[2]-box[0])/2))
            draw.line((x,y1-2,x,y-3), fill=BLUE, width=max(1,round(data['res_scale']*2)))
            draw.rectangle((tx-4,y-2,tx+box[2]-box[0]+4,y+box[3]+2),fill='white')
            draw.text((tx,y),label,font=label_font,fill=BLUE)
        image.save(render_out / f'r-{key}.jpg', quality=90, subsampling=0)
        info['jpg'] = str((render_out / f'r-{key}.jpg').resolve())
        cache[key] = image

    # Retain the actual deliverable path for the independent Pillow tone probe.
    args.evidence.write_text(json.dumps(data, indent=2) + '\n')

    def text(canvas, xy, value, size=22, fill=INK):
        ImageDraw.Draw(canvas).text(tuple(round(v * scale) for v in xy), value,
                                   font=font(max(8, round(size * scale))), fill=fill)

    def put(canvas, image, rect):
        x, y, w, h = [round(v * scale) for v in rect]
        fitted = ImageOps.contain(image, (w, h), Image.Resampling.LANCZOS)
        canvas.paste(fitted, (x + (w - fitted.width) // 2, y + (h - fitted.height) // 2))

    def panel(title, subtitle):
        canvas = Image.new('RGB', (width, height), 'white')
        text(canvas, (32, 22), title, 38)
        text(canvas, (34, 70), subtitle, 19, BLUE)
        return canvas

    for name in data['sheets']:
        if name == 'lg01-assembled':
            left = panel('LEFT LEG / ASSEMBLED', 'LG-01  |  EEVEE MODEL COMPARISON')
            for i, view in enumerate(('three-quarter', 'side', 'front', 'back')):
                x = 28 + i * 376
                put(left, cache[f'{name}-{view}'], (x, 106, 350, 828))
                label = {'three-quarter': 'THREE-QUARTER / ORTHO', 'side': 'OUTER SIDE*'}.get(view, view.upper())
                text(left, (x + 25, 941), label, 18)
            text(left, (32, 989), 'Hip 9.20 m / Knee 5.10 m / Ankle 1.00 m   |   *Side display reflected; toe right.', 17, BLUE)
        elif name == 'fa02-assembled':
            left = panel('LEFT FOOT / ANKLE', 'FA-02  |  ASSEMBLED MODEL + LOWER SHIN STUB')
            for view, rect, label in (
                    ('three-quarter', (30, 118, 728, 528), (38, 111)),
                    ('top', (30, 714, 728, 252), (38, 679)),
                    ('side', (803, 120, 695, 351), (811, 111)),
                    ('front', (805, 530, 325, 423), (820, 503)),
                    ('back', (1162, 530, 325, 423), (1177, 503))):
                put(left, cache[f'{name}-{view}'], rect)
                text(left, label, 'OUTER SIDE*' if view == 'side' else view.upper(), 21)
            text(left, (32, 990), '3.36 × 1.46 m / Ankle 1.00 m / Guards 1.60 m   |   *Side display reflected.', 17, BLUE)
        elif name == 'lg01-structure':
            left = panel('STRUCTURE / JOINTS', 'LG-01  |  REAR OUTER + KNEE DETAIL')
            put(left, cache[f'{name}-rear-outer'], (35, 117, 565, 819))
            put(left, cache[f'{name}-knee'], (654, 221, 838, 680))
            ImageDraw.Draw(left).rectangle(tuple(round(v * scale) for v in (650, 218, 1495, 905)), outline=BLUE, width=max(1, round(scale)))
            text(left, (674, 174), 'KNEE / THIGH-TO-SHIN CYLINDERS', 23)
            text(left, (32, 980), 'Armor / service parts hidden; thrusters and foot internals retained.', 19, BLUE)
        elif name == 'lg01-armor':
            left = panel('ARMOR / THRUSTERS', 'LG-01  |  SEPARATED ARMOR / ENGINE DISPLAY')
            put(left, cache[f'{name}-exploded'], (55, 120, 1426, 815))
            text(left, (32, 980), 'Display offsets only; installation paths unchanged.  |  Foot omitted.', 19, BLUE)
        elif name == 'fa02-armor':
            left = panel('ARMOR / SOLES', 'FA-02  |  SHELLS / CARRIERS + SIX PAD UNDERSIDES')
            put(left, cache[f'{name}-exploded'], (44, 111, 1448, 626))
            text(left, (50, 744), 'PAD UNDERSIDES / COMMON SCALE', 19, BLUE)
            put(left, cache[f'{name}-underside'], (44, 775, 1448, 185))
            text(left, (32, 989), '5 shells / 2 carriers / 6 pads  |  Display offsets only; installation paths unchanged.', 17, BLUE)
        elif name == 'fa02-structure':
            left = panel('STRUCTURE / JOINTS', 'FA-02  |  ELEVATED FRONT OUTER')
            put(left, cache[f'{name}-three-quarter'], (44, 120, 1448, 815))
            text(left, (32, 980), 'Shells, sole carriers and pads hidden  |  Assembled frame and three screw actuators.', 19, BLUE)
        else:
            left = panel('LEFT LEG / TURNAROUND', 'LG-01 MODEL  |  COMMON ORTHOGRAPHIC SCALE / Z 0–8.25 m')
            for i, view in enumerate(('front', 'side', 'back')):
                key = 'lg01-assembled-' + view
                image = cache[key]
                info = data['renders'][key]
                top = max(0, round(image.height * (1 - info['z825'])))
                image = image.crop((0, top, image.width, image.height))
                put(left, image, (35 + i * 500, 122, 466, 815))
                text(left, (190 + i * 500, 948), view.upper() + ('*' if view == 'side' else ''), 24)
            text(left, (32, 991), '*Outer-side display reflected. Hip/upper-thigh crop matches the visible reference region.', 17, BLUE)
        if name == 'turnaround-leg':
            reference = panel('TURNAROUND / LEFT LEG REGIONS', 'APPROVED V3  |  FRONT / SIDE / BACK AT ONE SOURCE SCALE')
            source = Image.open(ROOT / 'design/visual-design/turnaround/turnaround-v3.jpg').convert('RGB')
            # Fix one scale for every crop (same source y range), not per-view fit.
            ratio = 815 * scale / 490
            for i, (view, box) in enumerate(TURNAROUND_CROPS.items()):
                crop = source.crop(box)
                crop = crop.resize((round(crop.width * ratio), round(crop.height * ratio)), Image.Resampling.LANCZOS)
                center = round((268 + i * 500) * scale)
                reference.paste(crop, (center - crop.width // 2, round(122 * scale)))
                text(reference, (190 + i * 500, 948), view.upper(), 24)
            text(reference, (32, 991), 'Anatomical left leg. Side hand occlusion and hip skirts belong to the source drawing.', 17, BLUE)
        else:
            reference = Image.open(ROOT / CONCEPTS[name]).convert('RGB').resize((width, height), Image.Resampling.LANCZOS)
        sheet = Image.new('RGB', (width * 2, height), 'white')
        sheet.paste(left, (0, 0))
        sheet.paste(reference, (width, 0))
        ImageDraw.Draw(sheet).line((width, 0, width, height), fill='#a0acb8', width=max(1, round(scale)))
        path = args.out / f'cmp-{name}.jpg'
        sheet.save(path, quality=90, subsampling=0)
        print(f'WROTE {path} {sheet.size}', flush=True)


if __name__ == '__main__':
    main()
