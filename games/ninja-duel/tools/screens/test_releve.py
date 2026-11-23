#!/usr/bin/env python3
"""Tests of the survey of the screens (OUTILLEUR, passe commune 1).

    python3 tools/screens/test_releve.py
"""
import json
import os
import sys
import tempfile
import unittest

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import releve as R  # noqa: E402

REL = {"title": "t", "place": "p", "screen": "s", "steps": [
    {"key": "a", "name": "Arrivée", "how": "début", "image": "01.jpg", "notes": ["le bandeau cache le haut"],
     "red": {"client": ["Script error 12345 at line 4"], "server": []},
     "orange": {"client": ["Failed to create empty EditableMesh ... memory budget limits."], "server": []}},
    {"key": "b", "name": "Boutique", "how": "SHOP", "image": "02.jpg", "notes": [], "red": {"client": [], "server": ["DataStore request was added to queue"]}}]}


class Releve(unittest.TestCase):
    def test_red_and_orange_are_counted_apart(self):
        s = R.summary(REL)
        self.assertEqual((s["red"], s["orange"], s["client"], s["server"]), (2, 1, 1, 1))
        kinds = {k[2] for k in dict(s["kinds"])}
        self.assertIn("maillages (budget mémoire)", kinds)
        self.assertIn("DataStore", kinds)

    def test_the_page_puts_before_and_after_side_by_side(self):
        old = json.loads(json.dumps(REL))
        old["steps"][0]["image"] = "avant/01.jpg"
        page = R.page(REL, old)
        self.assertIn("avant/01.jpg", page)
        self.assertIn("01.jpg", page)
        self.assertIn("class=pair", page)
        self.assertIn("prefers-color-scheme:dark", page)
        md = R.markdown(REL, old)
        self.assertIn("Avant (p)", md)

    def test_the_studio_snippets(self):
        self.assertIn(".look()", R.snippet(["--look"]))
        self.assertIn('.find("TAKE IT")', R.snippet(["--find", "TAKE", "IT"]))
        self.assertIn("for i=12,#all", R.snippet(["--red-server", "12"]))

    def test_the_first_survey_reads(self):
        path = os.path.join(HERE, "mesures", "2026-11-23_avant_d0678d90", "releve.json")
        rel = R.load(path)
        for st in rel["steps"]:
            self.assertTrue(os.path.exists(os.path.join(os.path.dirname(path), st["image"])), st["image"])
        with tempfile.TemporaryDirectory() as tmp:
            out = os.path.join(tmp, "r.html")
            self.assertEqual(R.main(["--page", path, "--html", out]), 0)
            self.assertTrue(os.path.getsize(out) > 1000)

    def test_the_tour_module_cuts_text_by_characters(self):
        with open(os.path.join(HERE, "screen_tour.luau"), encoding="utf-8") as f:
            src = f.read()
        # a cut inside « 始め » is not UTF-8 and JSONEncode refuses the whole look (23/11)
        self.assertIn("utf8.offset", src)
        self.assertIn("function Tour.look()", src)


if __name__ == "__main__":
    result = unittest.main(exit=False, verbosity=1).result
    print(f"Releve: {result.testsRun - len(result.failures) - len(result.errors)} passed")
    sys.exit(0 if result.wasSuccessful() else 1)
