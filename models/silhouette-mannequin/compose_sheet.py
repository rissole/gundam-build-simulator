"""Assemble the mannequin's orthographic renders into turnaround sheets.

Run after build.py, with any Python that has Pillow:

    python3 models/silhouette-mannequin/compose_sheet.py

Writes output/turnaround-clean.png (front/side/back only, for image-generation
guidance) and output/turnaround-annotated.png (adds a metre scale and the
accepted landmark heights from design/proportions.md, for human review).
"""
import os

from PIL import Image, ImageDraw, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "output")

# build.py renders 1200 x 1500 orthographic views, ortho scale 20 m across the
# 1500 px height, centred on Z 9.25: 75 px per metre.
PX_PER_M = 75.0
CENTER_Z, CENTER_ROW = 9.25, 750.0
# Horizontal half-width (m) kept from each view, centred on the robot.
CROPS = {"front": 4.9, "side": 3.0, "back": 4.9}
LANDMARKS = [  # proportions.md
    (18.00, "crest tips 18.00"),
    (17.40, "helmet roof 17.40"),
    (15.40, "head baseplate 15.40"),
    (14.40, "shoulder balls 14.40"),
    (11.30, "chest seat 11.30"),
    (10.50, "waist bearing 10.50"),
    (9.20, "hip balls 9.20"),
    (5.10, "knee axes 5.10"),
    (1.00, "ankle pivots 1.00"),
    (0.00, "ground 0.00"),
]


def row(z):
    return round(CENTER_ROW - (z - CENTER_Z) * PX_PER_M)


def font(size):
    for path in ("/System/Library/Fonts/Helvetica.ttc",
                 "/System/Library/Fonts/Supplemental/Arial.ttf",
                 "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"):
        if os.path.exists(path):
            return ImageFont.truetype(path, size)
    return ImageFont.load_default()


def crop(view):
    img = Image.open(os.path.join(OUT, f"clean-{view}.png")).convert("RGB")
    half = round(CROPS[view] * PX_PER_M)
    top, bottom = row(18.6), row(-0.4)
    return img.crop((600 - half, top, 600 + half, bottom)), top


def sheet(annotated):
    views = [(v, *crop(v)) for v in ("front", "side", "back")]
    gap, margin_l, margin_r = 60, (260 if annotated else 60), 60
    header, footer = (110 if annotated else 40), (70 if annotated else 40)
    width = margin_l + sum(im.width for _, im, _ in views) + gap * 2 + margin_r
    height = header + views[0][1].height + footer
    out = Image.new("RGB", (width, height), "white")
    draw = ImageDraw.Draw(out)
    x = margin_l
    top = views[0][2]
    places = []
    for name, im, _ in views:
        out.paste(im, (x, header))
        places.append((name, x, im.width))
        x += im.width + gap
    if annotated:
        def y_of(z):
            return header + row(z) - top
        line_end = width - margin_r
        for z, label in LANDMARKS:
            y = y_of(z)
            draw.line([(margin_l - 20, y), (line_end, y)], fill=(70, 130, 220), width=1)
            draw.text((20, y - 11), label, fill=(40, 90, 180), font=font(18))
        # Metre scale beside the labels.
        sx = margin_l - 45
        for m in range(18):
            draw.rectangle([sx, y_of(m + 1), sx + 12, y_of(m)],
                           fill=(30, 30, 30) if m % 2 == 0 else (215, 215, 215))
        draw.text((20, 24), "WHOLE ROBOT  |  APPROVED SILHOUETTE (FOR NOW) 2026-11-01",
                  fill=(25, 30, 40), font=font(34))
        draw.text((20, 68), "Proportions and masses only; surfaces are placeholders. "
                  "Landmarks from design/proportions.md; metres.", fill=(90, 95, 105),
                  font=font(20))
        for name, px, w in places:
            label = name.upper()
            tw = draw.textlength(label, font=font(24))
            draw.text((px + (w - tw) / 2, height - footer + 22), label, fill=(25, 30, 40),
                      font=font(24))
    suffix = "annotated" if annotated else "clean"
    path = os.path.join(OUT, f"turnaround-{suffix}.png")
    out.save(path)
    return path


if __name__ == "__main__":
    for flag in (False, True):
        print(sheet(flag))
