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


if __name__ == "__main__":
    result = unittest.main(exit=False, verbosity=1).result
    print(f"Planche: {result.testsRun - len(result.failures) - len(result.errors)} passed")
    sys.exit(0 if result.wasSuccessful() else 1)
