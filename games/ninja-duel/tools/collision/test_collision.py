#!/usr/bin/env python3
"""Tests of the collision robot's report (OUTILLEUR, passe commune 1).

    python3 tools/collision/test_collision.py
"""
import os
import re
import sys
import tempfile
import unittest

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import collision as C  # noqa: E402

SURVEY = """# 4 units
model|n|facadeArea|facadeCross|facadeMax|roofArea|roofCross|roofMax|ghost|faces|ghostMax|pieces
machiya|2|1000|100|8.2|500|250|8.4|0|800|0.0|Tiles,Timber
HokageCliff|1|400|200|20.0|100|60|20.0|30|90|20.0|Cliff
TreeA|1|300|290|20.0|200|200|20.0|0|50|2.0|Leaves
Crate|1|50|0|0.0|10|0|0.0|0|20|0.0|
"""
WALK = """u|model|x,z|facadeDrawn|facadeSolid|went|into|facadeSkip|roofDrawn|roofSolid|feet|sink|roofSkip
machiya|machiya|1,2|7.6|7.8|7|0|nil|22.1|17.4|17.4|4.7|
machiya|machiya|3,4|13.5|nil|38.2|25.3|nil|21.5|17|17|4.5|
clan_house|clan_house|5,6|10|10|9.2|-0.2|nil|nil|nil|nil|nil|no drawing above the middle
"""


class Collision(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.s = os.path.join(self.tmp.name, "s.txt")
        self.w = os.path.join(self.tmp.name, "w.txt")
        with open(self.s, "w", encoding="utf-8") as f:
            f.write(SURVEY)
        with open(self.w, "w", encoding="utf-8") as f:
            f.write(WALK)

    def tearDown(self):
        self.tmp.cleanup()

    def test_the_survey_groups_buildings_cliff_trees_and_props(self):
        s = C.survey(self.s)
        self.assertEqual(set(s["groups"]), {"bâtiments", "falaise", "arbres", "objets et murs"})
        self.assertEqual(s["groups"]["bâtiments"]["facadeCross"], 100)

    def test_the_walk_finds_what_the_body_goes_through(self):
        w = C.walk(self.w)
        self.assertEqual(w["walked"], 3)
        self.assertEqual([r["into"] for r in w["into"]], [25.3])
        self.assertEqual(len(w["through"]), 1, "no solid ahead at the body's height")
        self.assertEqual(w["dropped"], 2)
        self.assertEqual(len(w["sink"]), 2)

    def test_the_report_and_its_page(self):
        text = C.markdown(C.survey(self.s), C.walk(self.w), C.survey(self.s), C.walk(self.w))
        self.assertIn("machiya", text)
        self.assertIn("Avant", text)
        page = C.page(text)
        self.assertIn("<table>", page)
        self.assertIn("prefers-color-scheme:dark", page)

    def test_the_studio_snippets(self):
        self.assertIn(".survey({max=3})", C.snippet(["--survey", "3"]))
        self.assertIn('.walk({max=5,only="machiya"})', C.snippet(["--walk", "5", "machiya"]))
        self.assertIn(".walkLines(41,40)", C.snippet(["--walk-lines", "41", "40"]))

    def test_the_bot_has_what_the_snippets_call(self):
        with open(os.path.join(HERE, "collision_bot.luau"), encoding="utf-8") as f:
            src = f.read()
        for name in ("survey", "walk", "byModel", "walkLines", "read", "rays", "raysOne", "raysLines"):
            self.assertIn(f"function Bot.{name}(", src)
        # an if-expression has no `end` (the one Studio refused on 23/11)
        self.assertIsNone(re.search(r'else "[^"]*" end return', src))

    def test_the_rays_before_and_after(self):
        old = """u|model|x,z|solids|meshes|fN|fThrough|fGhost|fMaxThrough|fMaxGhost|rN|rSink|rFloat|rMaxSink|rMaxFloat|skip
machiya|machiya|1,2|3|0|40|10|2|6.5|1.8|49|30|0|7|0|
GreatGate|great_gate|0,269|5|0|60|30|20|20|20|40|20|10|20|5|
"""
        new = """u|model|x,z|solids|meshes|fN|fThrough|fGhost|fMaxThrough|fMaxGhost|rN|rSink|rFloat|rMaxSink|rMaxFloat|skip
machiya|machiya|1,2|7|7|40|1|0|2|0|49|2|0|1|0|
edo_inn|edo_inn|3,4|9|9|40|20|0|12|0|49|0|0|0|0|
"""
        with tempfile.TemporaryDirectory() as tmp:
            a, b = os.path.join(tmp, "a.txt"), os.path.join(tmp, "b.txt")
            open(a, "w").write(old)
            open(b, "w").write(new)
            ra, rb = C.rays(a), C.rays(b)
            self.assertEqual(rb["groups"]["bâtiments"]["fThrough"], 21)
            self.assertEqual(rb["models"]["machiya"]["meshSolid"], 1)
            text = C.compare_md(ra, rb, C.walk(self.w), C.walk(self.w))
            self.assertIn("| bâtiments | 2 / 2 | 40 % | **26 %** |", text)
            self.assertIn("| great_gate | 1 / 0 |", text, "a model gone after the pass still shows")
            self.assertIn("edo_inn (edo_inn)", text, "half its façades go through: listed")
            out = os.path.join(tmp, "r.html")
            self.assertEqual(C.main(["--compare", a, b, "--html", out]), 0)
        self.assertIn(".raysLines(1,50)", C.snippet(["--rays-lines", "1", "50"]))
        self.assertIn(".rays({max=4})", C.snippet(["--rays", "4"]))


if __name__ == "__main__":
    result = unittest.main(exit=False, verbosity=1).result
    print(f"Collision: {result.testsRun - len(result.failures) - len(result.errors)} passed")
    sys.exit(0 if result.wasSuccessful() else 1)
