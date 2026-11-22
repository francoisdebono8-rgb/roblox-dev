#!/usr/bin/env python3
"""Planches de la cabine d'essayage (OUTILLEUR, 20/11 ; DEC-043, étape 1,
OUTILLEUR 3) : les captures de face et de dos de Studio, recadrées et nommées
avatar par avatar.

Entrée : un dossier de captures Studio (1920 × 1080, depuis Cabine.camera)
nommées <Tenue>_front.jpg et <Tenue>_back.jpg ; Nu_front.jpg en option.
Sortie : une planche par tenue (face au-dessus, dos dessous, chaque avatar
nommé sous sa silhouette) et deux planches d'ensemble (toutes les faces,
tous les dos).

    python3 tools/tenues/planche.py <captures> <sortie> [<place>]
    python3 tools/tenues/planche.py --avant-apres <captures avant> <captures après> <sortie>.jpg [<mot avant> <mot après>]
    python3 tools/tenues/planche.py --cheveux <captures> <sortie>.jpg [<place>]

La troisième forme fait le nuancier des couleurs de cheveux de la boutique
(Shared/CatalogStyle) : une ligne par couleur, les têtes des avatars
recadrées dans les captures Hair_<id>_front.jpg (Cabine.hairLooks).

La seconde forme met côte à côte, tenue par tenue, deux séries de captures
de la même cabine (deux places) : ce qu'un changement a fait à chaque tenue.

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
         "Accessoires": "ACCESSOIRES : base A + masque, cape de voyage, rouleau dans le dos",
         "SetEmberMonk": "EMBER MONK (tenue inventée, kit Lee)", "SetMistHunter": "MIST HUNTER (tenue inventée, kit Itachi)",
         "SetStormCourier": "STORM COURIER (tenue inventée, kit Naruto)",
         "SetShadowScout": "SHADOW SCOUT (tenue inventée, kit Kakashi)",
         "SetLeafMedic": "LEAF MEDIC (tenue inventée, kit Neji)", "SetSandNomad": "SAND NOMAD (tenue inventée, kit Gaara)",
         "Accessoires2": "ACCESSOIRES 2 : base A + masque de renard, cape à capuche, sabre dans le dos, bandeau au cou"}


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


def main(src, dst, place=None):
    avatars, order, spacing, dist = room()
    os.makedirs(dst, exist_ok=True)
    note = "Studio, mode Édition, avatars posés à leur repos (C0/C1), habillés par Outfit + OutfitDress + Headband"
    if place:
        note += " ; place " + place
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


def compare(before, after, out, view="front", labels=("AVANT", "APRÈS")):
    """Before | after, side by side, for every look captured in both folders
    (the same room, two places): what a change did to each outfit."""
    avatars, order, spacing, dist = room()
    rows = []
    for look in ["Nu"] + order:
        a, b = (os.path.join(d, f"{look}_{view}.jpg") for d in (before, after))
        if os.path.exists(a) and os.path.exists(b):
            ra, rb = (strip(p, view, avatars, spacing, dist) for p in (a, b))
            pair = Image.new("RGB", (WIDTH, ra.height // 2), PAPER)
            pair.paste(ra.resize((WIDTH // 2 - 4, ra.height // 2), Image.LANCZOS), (0, 0))
            pair.paste(rb.resize((WIDTH // 2 - 4, rb.height // 2), Image.LANCZOS), (WIDTH // 2 + 4, 0))
            rows.append((NAMES.get(look, look), pair))
    if not rows:
        return None
    word = "DE FACE" if view == "front" else "DE DOS"
    sheet = titled(rows, f"{labels[0]} | {labels[1]}, {word}",
                   f"à gauche {labels[0].lower()}, à droite {labels[1].lower()} : la même cabine, la même caméra")
    sheet.save(out, quality=82, optimize=True)
    return out


CATALOG_STYLE = os.path.join(HERE, "..", "..", "src", "Shared", "CatalogStyle.luau")
HEADS = (195, 340)  # the rows of a 725 capture that hold the heads (and Big Bill's cloud)


def hair_colours(path=CATALOG_STYLE):
    """The shop's hair colours, in its order: (id, name, price, rgb or None),
    read from Shared/CatalogStyle (the DEV's data)."""
    out = []
    for line in open(path, encoding="utf-8"):
        if 'slot="hairColor"' not in line:
            continue
        item = re.search(r'id="(\w+)"', line).group(1)
        name = re.search(r'name="([^"]+)"', line).group(1)
        ryo = re.search(r"ryo=(\d+)", line)
        price = (f"{int(ryo.group(1))} Ryō" if ryo else "Robux" if "robux=" in line
                 else "de base" if "base=true" in line else "gagnée" if "earned" in line else "?")
        rgb = re.search(r"Hair=rgb\((\d+),(\d+),(\d+)\)", line)
        out.append((item, name, price, tuple(int(v) for v in rgb.groups()) if rgb else None))
    return out


def hair_sheet(src, out, place=None):
    """The hair colours on the room's avatars, one row a colour: the heads
    cropped from the front captures Hair_<id>_front.jpg, the colour's swatch,
    name and price beside each row, each avatar named above its column."""
    avatars, _, spacing, dist = room()
    label_w, gap = 300, 8
    rows = []
    for item, name, price, rgb in hair_colours():
        path = os.path.join(src, f"Hair_{item}_front.jpg")
        if not os.path.exists(path):
            continue
        im = Image.open(path).convert("RGB")
        w, h = im.size
        cols = columns("front", avatars, spacing, dist, w, h)
        xs = [x for x, _ in cols]
        half = (spacing * ((h / 2) / math.tan(math.radians(FOV / 2))) / dist) * .62
        x0, x1 = int(min(xs) - half), int(max(xs) + half)
        crop = im.crop((x0, int(HEADS[0] * h / 725), x1, int(HEADS[1] * h / 725)))
        rows.append((item, name, price, rgb, crop, [(x - x0, label) for x, label in cols]))
    if not rows:
        return None
    cw = max(r[4].width for r in rows)
    ch = max(r[4].height for r in rows)
    head, names = 64, 34
    sheet = Image.new("RGB", (label_w + cw + 16, head + names + len(rows) * (ch + gap) + 40), PAPER)
    d = ImageDraw.Draw(sheet)
    d.text((18, 10), "COULEURS DE CHEVEUX SUR LES 7 AVATARS TYPES", fill=INK, font=font(24))
    note = "Studio, mode Édition, Outfit.hairColor sur la tenue de base A"
    if place:
        note += " ; place " + place
    d.text((18, 40), note, fill=SOFT, font=font(14))
    f = font(14)
    for x, label in rows[0][5]:
        tw = d.textlength(label, font=f)
        d.text((label_w + x - tw / 2, head + 8), label, fill=INK, font=f)
    y = head + names
    for item, name, price, rgb, crop, _ in rows:
        sheet.paste(crop, (label_w, y))
        sw = 34
        if rgb:
            d.rectangle((18, y + ch / 2 - sw / 2, 18 + sw, y + ch / 2 + sw / 2), fill=rgb, outline=INK)
        else:
            d.rectangle((18, y + ch / 2 - sw / 2, 18 + sw, y + ch / 2 + sw / 2), outline=SOFT)
        d.text((64, y + ch / 2 - 22), name, fill=INK, font=font(17))
        d.text((64, y + ch / 2 + 2), price, fill=SOFT, font=font(14))
        y += ch + gap
    d.text((18, y + 8), "Korblox, Garçon Roblox et Bloc R15 n'ont pas de cheveux : la couleur ne se voit pas sur eux.",
           fill=SOFT, font=font(14))
    sheet.save(out, quality=86, optimize=True)
    return out


if __name__ == "__main__":
    args = sys.argv[1:]
    if args[:1] == ["--cheveux"] and len(args) in (3, 4):
        print(hair_sheet(*args[1:]))
    elif args[:1] == ["--avant-apres"] and len(args) in (4, 6):
        labels = tuple(args[4:6]) if len(args) == 6 else ("AVANT", "APRÈS")
        for view, suffix in (("front", "face"), ("back", "dos")):
            out = args[3].replace(".jpg", "") + f"-{suffix}.jpg"
            if compare(args[1], args[2], out, view, labels):
                print(out)
    elif len(args) in (2, 3):
        for path in main(*args):
            print(path)
    else:
        sys.exit(__doc__)
