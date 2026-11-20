#!/usr/bin/env python3
"""Planches de la cabine d'essayage (OUTILLEUR, 20/11 ; DEC-043, étape 1,
OUTILLEUR 3) : les captures de face et de dos de Studio, recadrées et nommées
avatar par avatar.

Entrée : un dossier de captures Studio (1920 × 1080, depuis Cabine.camera)
nommées <Tenue>_front.jpg et <Tenue>_back.jpg ; Nu_front.jpg en option.
Sortie : une planche par tenue (face au-dessus, dos dessous, chaque avatar
nommé sous sa silhouette) et deux planches d'ensemble (toutes les faces,
tous les dos).

    python3 tools/tenues/planche.py <captures> <sortie>

Les noms, l'ordre des avatars et l'ordre des tenues sont lus dans
cabine.luau : la planche suit la cabine sans qu'on la recopie.
"""
import math
import os
import re
import sys

from PIL import Image, ImageDraw, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
FONTS = ["/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", "/Library/Fonts/Arial Bold.ttf",
         "/System/Library/Fonts/Supplemental/Arial Bold.ttf", "/System/Library/Fonts/Helvetica.ttc"]
FOV = 70  # Studio's default camera field of view (vertical, degrees)
CROP = (250, 730)  # the rows of a 1080 capture that hold the avatars
WIDTH = 1440
INK, PAPER, SOFT = (26, 24, 30), (244, 240, 230), (110, 104, 96)
NAMES = {"Nu": "SANS TENUE (le corps de l'avatar)", "SetNaruto": "SET NARUTO", "SetSasuke": "SET SASUKE",
         "SetLee": "SET LEE", "SetNeji": "SET NEJI", "SetGaara": "SET GAARA (la gourde est l'objet du kit, hors tenue)",
         "SetKakashi": "SET KAKASHI", "SetItachi": "SET ITACHI", "SetMinato": "SET MINATO",
         "BaseA": "BASE A : tunique marine, pantalon sombre, bandes, sandales, bandeau bleu",
         "BaseB": "BASE B : col haut, pantalon sable, protège-bras, bottes noires, bandeau noir",
         "BaseC": "BASE C : sans manches, short, sandales, bandeau rouge",
         "Accessoires": "ACCESSOIRES : base A + masque, cape de voyage, rouleau dans le dos"}


def font(size):
    for path in FONTS:
        if os.path.exists(path):
            try:
                return ImageFont.truetype(path, size)
            except OSError:
                pass
    return ImageFont.load_default()


def room():
    """The avatars' labels in row order, the looks' order, the spacing and
    the camera distance, read from cabine.luau."""
    text = open(os.path.join(HERE, "cabine.luau"), encoding="utf-8").read()
    avatars = re.findall(r'\{key="(\w+)",label="([^"]+)"', text)
    order = re.findall(r'"(\w+)"', re.search(r"Cabine\.ORDER=\{([^}]*)\}", text).group(1))
    spacing = float(re.search(r"Cabine\.SPACING=([\d.]+)", text).group(1))
    factor = float(re.search(r"\(#Cabine\.AVATARS\*Cabine\.SPACING\)\*([\d.]+)", text).group(1))
    return avatars, order, spacing, len(avatars) * spacing * factor


def columns(view, avatars, spacing, dist, width=1920, height=1080):
    """Where each avatar stands across the capture. The front camera looks
    down +Z, so the first avatar (x=0) is on the right; from the back, on
    the left."""
    focal = (height / 2) / math.tan(math.radians(FOV / 2))
    mid = (len(avatars) - 1) * spacing / 2
    out = []
    for i, (_, label) in enumerate(avatars):
        dx = i * spacing - mid
        sx = width / 2 + (dx if view == "back" else -dx) * focal / dist
        out.append((sx, label))
    return out


def strip(path, view, avatars, spacing, dist):
    """One capture, cropped to the avatars, scaled, with each avatar named."""
    im = Image.open(path).convert("RGB")
    w, h = im.size
    top, bottom = (int(CROP[0] * h / 1080), int(CROP[1] * h / 1080))
    im = im.crop((0, top, w, bottom))
    k = WIDTH / w
    im = im.resize((WIDTH, int(im.height * k)), Image.LANCZOS)
    band = 30
    out = Image.new("RGB", (WIDTH, im.height + band), PAPER)
    out.paste(im, (0, 0))
    d = ImageDraw.Draw(out)
    f = font(15)
    for sx, label in columns(view, avatars, spacing, dist, w, h):
        x = sx * k
        tw = d.textlength(label, font=f)
        d.text((x - tw / 2, im.height + 7), label, fill=INK, font=f)
    return out


def titled(rows, title, subtitle=None):
    head = 54 if subtitle else 40
    side = 26
    height = head + sum(r.height + side for _, r in rows)
    sheet = Image.new("RGB", (WIDTH, height), PAPER)
    d = ImageDraw.Draw(sheet)
    d.text((18, 10), title, fill=INK, font=font(22))
    if subtitle:
        d.text((18, 35), subtitle, fill=SOFT, font=font(13))
    y = head
    for label, r in rows:
        d.text((18, y + 4), label, fill=SOFT, font=font(14))
        y += side
        sheet.paste(r, (0, y))
        y += r.height
    return sheet


def main(src, dst):
    avatars, order, spacing, dist = room()
    os.makedirs(dst, exist_ok=True)
    note = "Studio, mode Édition, avatars posés à leur repos (C0/C1), habillés par Outfit + OutfitDress + Headband"
    made, fronts, backs = [], [], []
    for look in ["Nu"] + order:
        rows = []
        for view, word in (("front", "FACE"), ("back", "DOS")):
            path = os.path.join(src, f"{look}_{view}.jpg")
            if os.path.exists(path):
                r = strip(path, view, avatars, spacing, dist)
                rows.append((word, r))
                (fronts if view == "front" else backs).append((NAMES.get(look, look), r))
        if not rows:
            continue
        name = os.path.join(dst, f"{look}.jpg")
        titled(rows, NAMES.get(look, look), note).save(name, quality=82, optimize=True)
        made.append(name)
    for rows, file, title in ((fronts, "tout-face.jpg", "TOUTES LES TENUES, DE FACE"),
                              (backs, "tout-dos.jpg", "TOUTES LES TENUES, DE DOS")):
        if rows:
            small = [(t, r.resize((WIDTH // 2, r.height // 2), Image.LANCZOS)) for t, r in rows]
            half = math.ceil(len(small) / 2)
            left, right = small[:half], small[half:]
            col = lambda part: titled([(t, r) for t, r in part], "")  # noqa: E731
            a, b = col(left), col(right) if right else None
            top = 4  # the columns' own empty title band holds the sheet's title
            sheet = Image.new("RGB", (WIDTH, max(a.height, b.height if b else 0) + top), PAPER)
            sheet.paste(a.crop((0, 0, WIDTH // 2, a.height)), (0, top))
            if b:
                sheet.paste(b.crop((0, 0, WIDTH // 2, b.height)), (WIDTH // 2, top))
            ImageDraw.Draw(sheet).text((18, 10), title, fill=INK, font=font(20))
            path = os.path.join(dst, file)
            sheet.save(path, quality=82, optimize=True)
            made.append(path)
    return made


if __name__ == "__main__":
    if len(sys.argv) != 3:
        sys.exit(__doc__)
    for path in main(sys.argv[1], sys.argv[2]):
        print(path)
