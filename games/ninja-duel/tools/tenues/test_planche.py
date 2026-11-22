#!/usr/bin/env python3
"""Tests des planches de la cabine (OUTILLEUR, 20/11) : la planche lit la
cabine (avatars, tenues, caméra), place chaque nom sous son avatar, de face
comme de dos, et sort une planche par tenue. Sans Studio : des captures
fabriquées.

    python3 tools/tenues/test_planche.py
"""
import os
import sys
import tempfile
import unittest

try:
    from PIL import Image, ImageDraw
except ImportError:  # the sheets need Pillow; a machine without it has no sheet to test
    print("Planche: SKIP (pip install pillow)")
    sys.exit(0)

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import planche as P  # noqa: E402


class Planche(unittest.TestCase):
    def test_the_sheet_reads_the_room(self):
        avatars, order, spacing, dist = P.room()
        self.assertGreaterEqual(len(avatars), 5)
        self.assertIn("SetNaruto", order)
        self.assertEqual(len(order), len(set(order)))
        self.assertGreater(spacing, 0)
        self.assertGreater(dist, spacing)
        text = open(os.path.join(HERE, "cabine.luau"), encoding="utf-8").read()
        for look in order:
            self.assertIn(look + "=", text, look + " is in Cabine.LOOKS")

    def test_the_back_is_the_front_mirrored(self):
        avatars, _, spacing, dist = P.room()
        front = P.columns("front", avatars, spacing, dist)
        back = P.columns("back", avatars, spacing, dist)
        self.assertGreater(front[0][0], front[-1][0], "first avatar on the right, from the front")
        self.assertLess(back[0][0], back[-1][0], "and on the left, from the back")
        for (f, _), (b, _) in zip(front, back):
            self.assertAlmostEqual(f + b, 1920, places=6)
        for x, _ in front:
            self.assertTrue(0 < x < 1920)

    def test_a_name_lands_under_its_avatar(self):
        # an avatar painted where the room's geometry puts it, from the front
        avatars, _, spacing, dist = P.room()
        cols = P.columns("front", avatars, spacing, dist)
        with tempfile.TemporaryDirectory() as tmp:
            src, dst = os.path.join(tmp, "brut"), os.path.join(tmp, "rendus")
            os.makedirs(src)
            for view in ("front", "back"):
                im = Image.new("RGB", (1920, 1080), (120, 180, 220))
                d = ImageDraw.Draw(im)
                for x, _ in P.columns(view, avatars, spacing, dist):
                    d.rectangle((x - 40, 380, x + 40, 690), fill=(230, 120, 40))
                im.save(os.path.join(src, f"SetNaruto_{view}.jpg"))
            made = P.main(src, dst)
            names = sorted(os.path.basename(p) for p in made)
            self.assertEqual(names, ["SetNaruto.jpg", "tout-dos.jpg", "tout-face.jpg"])
            strip = P.strip(os.path.join(src, "SetNaruto_front.jpg"), "front", avatars, spacing, dist)
            k = P.WIDTH / 1920
            middle = strip.getpixel((int(cols[0][0] * k), int((530 - P.CROP[0]) * k)))
            self.assertGreater(middle[0], 180, "the first avatar's column is under its name")

    def test_before_and_after_side_by_side(self):
        with tempfile.TemporaryDirectory() as tmp:
            for folder, colour in (("avant", (230, 120, 40)), ("apres", (40, 120, 230))):
                os.makedirs(os.path.join(tmp, folder))
                for look in ("SetNaruto", "SetLee"):
                    Image.new("RGB", (1920, 1080), colour).save(os.path.join(tmp, folder, f"{look}_front.jpg"))
            # a look captured only after is left out: nothing to compare it to
            Image.new("RGB", (1920, 1080)).save(os.path.join(tmp, "apres", "SetNeji_front.jpg"))
            out = P.compare(os.path.join(tmp, "avant"), os.path.join(tmp, "apres"), os.path.join(tmp, "aa.jpg"))
            sheet = Image.open(out)
            self.assertEqual(sheet.width, P.WIDTH)
            y = sheet.height - 20
            self.assertGreater(sheet.getpixel((P.WIDTH // 4, y))[0], 180, "before on the left")
            self.assertGreater(sheet.getpixel((3 * P.WIDTH // 4, y))[2], 180, "after on the right")
            self.assertIsNone(P.compare(os.path.join(tmp, "avant"), os.path.join(tmp, "apres"),
                                        os.path.join(tmp, "dos.jpg"), view="back"))

    def test_the_hair_colours_come_from_the_shop(self):
        colours = P.hair_colours()
        ids = [c[0] for c in colours]
        self.assertGreaterEqual(len(colours), 2)
        self.assertEqual(len(ids), len(set(ids)))
        base = [c for c in colours if c[2] == "de base"]
        self.assertEqual(len(base), 1, "one colour is the player's own")
        self.assertIsNone(base[0][3])
        for item, name, price, rgb in colours:
            if rgb:
                self.assertEqual(len(rgb), 3)
                self.assertTrue(all(0 <= v <= 255 for v in rgb))
            self.assertNotEqual(price, "?", item)

    def test_the_hair_sheet_has_a_row_a_colour(self):
        avatars, _, spacing, dist = P.room()
        colours = P.hair_colours()[:3]
        with tempfile.TemporaryDirectory() as tmp:
            for item, _, _, rgb in colours:
                im = Image.new("RGB", (1920, 725), (120, 180, 220))
                d = ImageDraw.Draw(im)
                for x, _ in P.columns("front", avatars, spacing, dist, 1920, 725):
                    d.rectangle((x - 20, 250, x + 20, 300), fill=rgb or (90, 60, 40))
                im.save(os.path.join(tmp, f"Hair_{item}_front.jpg"))
            out = P.hair_sheet(tmp, os.path.join(tmp, "cheveux.jpg"), "test")
            self.assertTrue(os.path.exists(out))
            sheet = Image.open(out)
            self.assertGreater(sheet.height, 3 * (P.HEADS[1] - P.HEADS[0]))
            self.assertIsNone(P.hair_sheet(os.path.join(tmp, "vide"), os.path.join(tmp, "x.jpg")))


if __name__ == "__main__":
    result = unittest.main(exit=False, verbosity=1).result
    print(f"Planche: {result.testsRun - len(result.failures) - len(result.errors)} passed")
    sys.exit(0 if result.wasSuccessful() else 1)
