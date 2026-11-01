"""Measure composed JPEGs at geometry-validated anchors; never block rendering.

Standalone failures exit 1 and write a report. render_compare.py deliberately
ignores that diagnostic status, so all requested sheets still get delivered.
Y′ is Rec.709-weighted sRGB code value, not linear luminance.
"""
import argparse
import hashlib
import json
from pathlib import Path
from PIL import Image, ImageDraw, ImageStat

ROOT = Path(__file__).resolve().parents[3]
CONCEPT = ROOT / 'design/legs/images/lg01-assembled-v3.jpg'
CONCEPT_POINTS = {'lit_thigh': (1030, 270), 'shaded_thigh': (960, 360),
                  'ochre_kneecap': (1030, 452), 'dark_knee': (1090, 425),
                  'calf_front': (1030, 550)}
VIEWS = ('front', 'three-quarter')


def sha256(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def patch(image, pixel, radius):
    x, y = pixel
    box = (x-radius, y-radius, x+radius+1, y+radius+1)
    if box[0] < 0 or box[1] < 0 or box[2] > image.width or box[3] > image.height:
        raise ValueError(f'Patch outside image: {box}')
    rgb = ImageStat.Stat(image.crop(box)).median
    return {'rgb': rgb, 'y_srgb': round(sum(c*w for c,w in zip(rgb, (.2126,.7152,.0722))), 1),
            'pixel': pixel, 'radius': radius}


def meets(name, p):
    y = p['y_srgb']
    if name in {'lit_thigh', 'calf_front'}:
        passed = 215 <= y <= 228 and max(p['rgb']) <= 235
    elif name == 'shaded_thigh':
        passed = 165 <= y <= 190
    elif name == 'ochre_kneecap':
        passed = all(abs(c-t) <= 20 for c,t in zip(p['rgb'], (205,135,40)))
    elif name == 'dark_knee':
        passed = 55 <= y <= 100
    else:
        passed = p['rgb'] == [255]*3
    return 'PASS' if passed else 'MISS'


def cell(p):
    if 'rgb' not in p:
        return '**' + p['status'] + '**'
    return f"{tuple(p['rgb'])} / {p['y_srgb']}" + (f" **{p['status']}**" if 'status' in p else '')


def write_notes(path, data, result, table, evidence_path):
    passed = result['all_targets_met']
    lines = ['# P6R4 — rendering round 3, R10–R12', '',
             '**Tone targets ' + ('PASS' if passed else 'FAIL — see diagnostic table') + '.** '
             'This receipt is regenerated from the current render evidence, not copied from a previous scene.', '',
             f"Loaded scene SHA-256: `{result['blend_sha256']}`.",
             f"Scene SHA-256 at render end: `{data['blend_sha256_at_end']}`.",
             f"Disk source changed during rendering: **{data['source_changed_during_render']}**. "
             'The renderer does not save the blend or rebuild geometry.', '',
             '## Measured tone', '',
             'Median RGB / Rec.709-weighted sRGB code value Y′, measured from the delivered '
             'individual JPEGs. Lit thigh/calf: 215–228 and each channel ≤235; shade: '
             '165–190; lit−shade ≥30. Ochre: (205,135,40) ±20/channel; knee: 55–100. '
             'Invalid geometry anchors have no measured tone and cannot pass separation.', '', table, '',
             'Concept: `design/legs/images/lg01-assembled-v3.jpg`; fixed 9×9 px patches. '
             'The front shaded probe is the LG-200 outer fold; the oblique probe is the '
             'LG-210 outer skin. Anchors are ray-cast onto the loaded mesh; every pixel '
             'footprint plus a one-pixel border must hit the same part and palette material. '
             'No pixel-brightness search, image recoloring or local tone correction is used.', '',
             '| View / region | Part | World point | Pixel / radius | Validated rays |',
             '| --- | --- | --- | --- | --- |']
    for view in VIEWS:
        info = data['renders'].get('lg01-assembled-'+view,{})
        for name, point in (info.get('tone_points') or {}).items():
            world = ', '.join(f'{v:.4f}' for v in point.get('world',[])) or 'missing'
            lines.append(f"| {view} / {name} | {point['part_id']} | {world} | {point.get('pixel')} / {point.get('radius')} | {point.get('matching_rays',0)}/{point.get('patch_rays',0)} |")
    lines += ['', '## Rendering and finish', '',
              f"Blender {data['blender']}; EEVEE; {data['samples']} samples; {data['view_transform']} "
              f"transform, exposure {data['exposure']}, gamma 1. Lighting inputs: `{json.dumps(data['lighting'], sort_keys=True)}`. "
              'Key azimuth/elevation 45°/25°, opposing fill elevation 15°, rear rim elevation 10°. '
              'Distant softboxes use a 24× distance/size scale and 576× power. '
              'Front and oblique share world-space lighting; other views rotate the studio rig. '
              'Actual camera/light transforms are in the evidence JSON.', '',
              'Assembled leg: orthographic three-quarter, 38° off front and 11° elevation. '
              'Assembled foot and exploded diagrams are also orthographic. Remaining structure '
              'presentation cameras use 120 mm. Contact shadows are retained under assembled '
              'three-quarter views. Side images are reflected for reference alignment and labeled.', '',
              'Approved palette hex values and materials.py are unchanged. Source materials retain glTF '
              'Principled compatibility: armor roughness 0.49; bronze 0.43; recess metallic '
              '0.03 / roughness 0.90. Viewer GLB is unchanged; the following finish is renderer-only.', '',
              '**R10:** mouth positions/depths are measured from the loaded bronze meshes. '
              'A cubic aperture-visibility approximation (1 at the lip, 0.012 at/behind the throat), '
              'with local cavity AO on bronze (0.85 m, power 1.3), attenuates the entire BSDF, including '
              'metal reflections. The engine bore and rear-facing LG-100 receiving surfaces share '
              'the cavity shadow; the beam front and external barrel remain unaffected. '
              'Receiver attenuation is disabled when the engines are moved away in the exploded '
              'display. No disc, cap, geometry edit, palette replacement or image-space correction is used.', '',
              '**R11:** spatial noise gates existing small edge lands and 0.055 m crevice AO. '
              'Maximum localized linear-value reduction is 32%, roughness increase 0.17; '
              'broad sloped fields are excluded from the source Wear heuristic. The mask is '
              'constant per face before shader noise, avoiding random vertex-gradient fans.', '',
              '**R12:** structure views use a 1.25× key with a narrower softbox, 0.65× fill, '
              '3.2× rear rim and a dedicated tall reflection strip. Assembled lighting stays '
              'unchanged. Painted faces use geometric split normals on mesh copies; mechanical '
              'smoothing is preserved. Both carriers are also shown from below, with the six '
              'pad undersides retained. Foot recesses still reuse Dark recess; no hardware added.', '',
              f"Source script SHA-256: `{json.dumps(data['script_sha256'], sort_keys=True)}`.", '',
              f"Dark foot-well faces: `{json.dumps(data['finish_audit']['dark_well_faces'], sort_keys=True)}`.", '',
              '## Exploded display and evidence', '',
              'Leg plates and two engines occupy separated rows/columns around the frame; '
              'major pieces have part-number labels and short leaders. Foot shells and carriers '
              'are spread above/around the assembled frame, with all six pads separately shown '
              'from below at a common scale, with grazing illumination across the tread. Both carrier undersides have their own labelled inset. Captive hardware follows its owner. Rear skins and engines turn to show their exterior. These are '
              'display transforms only; they neither modify nor certify installation paths.', '',
              f"Evidence: `{evidence_path}`; sibling `tone-probe.json`, `tone-probe.md` and "
              '`tone-patches-*.png` contain diagnostic results and overlays. '
              'A failed standalone probe exits 1 and prints TONE PROBE FAILURE, while '
              'render_compare.py still completes the sheets.', '',
              '| Sheet | SHA-256 |', '| --- | --- |']
    for sheet in data['sheets']:
        file = path.parent / ('cmp-'+sheet+'.jpg')
        if file.exists(): lines.append(f'| {file.name} | `{sha256(file)}` |')
    lines += ['', '## Rear-throat diagnostic', '', result.get('throat_table', 'Not sampled.'), '',
              'The fixed rear rays must hit LG-100 through both open engines. Target Y′ ≤35 is a rendering diagnostic, separate from the unchanged R5 tone targets.', '']
    lines += ['', 'Automated receipt: image generation and tone measurements only. '
              'Human inspection findings and material-board verification are recorded below '
              'after review; generation alone is not visual approval.', '']
    path.write_text('\n'.join(lines))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--evidence', type=Path, required=True)
    parser.add_argument('--render-dir', type=Path)
    parser.add_argument('--notes', type=Path)
    args = parser.parse_args()
    data = json.loads(args.evidence.read_text())
    result = {'concept': {}, 'views': {}, 'blend_sha256': data['blend_sha256_at_start'],
              'source_changed_during_render': data['source_changed_during_render']}
    concept = Image.open(CONCEPT).convert('RGB')
    for name, pixel in CONCEPT_POINTS.items():
        result['concept'][name] = patch(concept, pixel, 4)
    for view in VIEWS:
        key = 'lg01-assembled-'+view
        info = data['renders'].get(key, {})
        values = {}
        try:
            path = args.render_dir / ('r-'+key+'.jpg') if args.render_dir else Path(info['jpg'])
            image = Image.open(path).convert('RGB')
            result.setdefault('jpeg_sha256', {})[view] = sha256(path)
            overlay = image.copy(); draw = ImageDraw.Draw(overlay)
            for name in CONCEPT_POINTS:
                point = (info.get('tone_points') or {}).get(name, {})
                if not point.get('valid'):
                    values[name] = {'status': point.get('error', 'MISSING ANCHOR'), 'part_id': point.get('part_id')}
                    continue
                try:
                    p = patch(image, point['pixel'], point['radius'])
                    p.update(part_id=point['part_id'], world=point['world'], valid=True)
                    p['status'] = meets(name, p); values[name] = p
                    x,y = point['pixel']; r = point['radius']+2
                    draw.rectangle((x-r,y-r,x+r,y+r),outline='magenta',width=1)
                    draw.text((x+r+2,y), name, fill='magenta')
                except (KeyError, ValueError) as error:
                    values[name] = {'status': 'INVALID PATCH', 'error': str(error)}
            values['background'] = patch(image, (20,20), 4)
            values['background']['status'] = meets('background', values['background'])
            overlay.save(args.evidence.parent / ('tone-patches-'+view+'.png'))
        except (OSError, KeyError) as error:
            values = {name: {'status':'MISSING IMAGE', 'error':str(error)} for name in (*CONCEPT_POINTS,'background')}
        lit, shade = values['lit_thigh'], values['shaded_thigh']
        values['difference'] = round(lit['y_srgb']-shade['y_srgb'],1) if lit.get('valid') and shade.get('valid') else None
        result['views'][view] = values
    table = ['| Region | Concept RGB / Y′ | Front RGB / Y′ | Three-quarter RGB / Y′ |', '| --- | --- | --- | --- |']
    for name in (*CONCEPT_POINTS, 'background'):
        table.append('| '+name+' | '+('—' if name=='background' else cell(result['concept'][name]))+' | '+
                     ' | '.join(cell(result['views'][view][name]) for view in VIEWS)+' |')
    differences = [result['views'][view]['difference'] for view in VIEWS]
    table.append('| Lit − shaded Y′ | '+str(round(result['concept']['lit_thigh']['y_srgb']-result['concept']['shaded_thigh']['y_srgb'],1))+' | '+
                 ' | '.join('**INVALID**' if value is None else str(value)+(' PASS' if value>=30 else ' MISS') for value in differences)+' |')
    result['all_targets_met'] = not data['source_changed_during_render'] and all(
        all(v.get('status') == 'PASS' for k,v in view.items() if k != 'difference') and
        view['difference'] is not None and view['difference'] >= 30 for view in result['views'].values())
    back = data['renders'].get('lg01-assembled-back', {})
    throat_table = ['| Throat | Receiving part / world point | RGB / Y′ | Rays | Status |',
                    '| --- | --- | --- | --- | --- |']
    result['throats'] = {}
    if back.get('jpg'):
        rear = Image.open(back['jpg']).convert('RGB')
        for name, point in (back.get('throat_points') or {}).items():
            value = patch(rear,point['pixel'],point['radius']) if point.get('valid') else {}
            value['status'] = 'PASS' if point.get('valid') and value['y_srgb'] <= 35 else 'MISS'
            result['throats'][name] = value
            throat_table.append(f"| {name} | {point.get('part_id')} / {point.get('world')} | {value.get('rgb')} / {value.get('y_srgb')} | {point['matching_rays']}/{point['patch_rays']} | {value['status']} |")
    result['throat_targets_met'] = len(result['throats']) == 2 and all(v['status']=='PASS' for v in result['throats'].values())
    result['throat_table'] = '\n'.join(throat_table)
    text = '\n'.join(table)+'\n'
    if not result['all_targets_met']:
        text = '**TONE PROBE FAILURE — invalid anchors or targets not met. Rendering is not blocked.**\n\n'+text
    print(text, flush=True)
    print(result['throat_table'], flush=True)
    (args.evidence.parent/'tone-probe.json').write_text(json.dumps(result,indent=2)+'\n')
    (args.evidence.parent/'tone-probe.md').write_text(text)
    if args.notes:
        write_notes(args.notes, data, result, text, args.evidence)
    return 0 if result['all_targets_met'] and result['throat_targets_met'] else 1


if __name__ == '__main__':
    raise SystemExit(main())
