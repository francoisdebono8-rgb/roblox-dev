#!/usr/bin/env python3
"""Tests du comparateur de kits (OUTILLEUR, 20/11), sur l'empreinte réelle du
20/11 (Studio, sources 053395e4) : tools/kits/empreintes/.

    python3 tools/kits/test_empreinte.py
"""
import copy
import io
import json
import os
import sys
import unittest
from contextlib import redirect_stdout

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import empreinte as E  # noqa: E402

BASE = os.path.join(HERE, "empreintes", "2026-11-20_053395e4.json")


class Comparateur(unittest.TestCase):
    def setUp(self):
        with open(BASE, encoding="utf-8") as f:
            self.data = json.load(f)

    def test_the_eight_kits_get_five_notes_out_of_100(self):
        sc = E.scores(self.data)
        self.assertEqual(len(sc), 8)
        for kid, notes in sc.items():
            self.assertEqual(list(notes), E.AXES)
            for axis, v in notes.items():
                self.assertTrue(0 < v <= 100, f"{kid} {axis} {v}")
        # an axis mixes two or three measures, each a share of its own best:
        # the best kit on the axis is close to 100, not always exactly
        for axis in E.AXES:
            self.assertGreater(max(n[axis] for n in sc.values()), 85, axis)

    def test_what_a_kit_has_on_its_own(self):
        mine = E.own(self.data)
        self.assertIn("Byakugan", mine["GentleFist"])
        self.assertIn("Deflect", mine["Leaf"])
        self.assertIn("Copy", mine["Copycat"])
        self.assertNotIn("Sharingan", mine["Mirage"], "three kits have the Sharingan: not Itachi's alone")

    def test_the_closest_pair_comes_first(self):
        pairs = E.closest(E.scores(self.data))
        self.assertEqual(len(pairs), 28)
        self.assertLessEqual(pairs[0][0], pairs[-1][0])

    def test_the_same_print_twice_moves_nothing(self):
        text = E.diff(self.data, copy.deepcopy(self.data))
        self.assertEqual(text.count("rien ne bouge"), 8)

    def test_a_change_shows_up_with_its_numbers(self):
        after = copy.deepcopy(self.data)
        lee = after["kits"]["Leaf"]["versions"]["prodige"]
        lee["string"]["dps"] = 30
        lee["jutsu"]["list"].append({"id": "Lotus2", "damage": 10, "cooldown": 5})
        text = E.diff(self.data, after)
        line = next(l for l in text.splitlines() if l.strip().startswith("Rock Lee"))
        self.assertIn("dégâts/s", line)
        self.assertIn("+Lotus2", text)
        self.assertIn("dégâts/s corde 15.63→30", text)

    def test_the_tree_view_compares_a_players_start_and_the_full_tree(self):
        text = E.diff(self.data, self.data, "depart", "arbre")
        self.assertIn("PV 150→158", text)  # Naruto's tree adds health
        self.assertNotIn("rien ne bouge", text.split("Naruto")[1].splitlines()[0])

    def test_the_command_and_the_page(self):
        out = io.StringIO()
        page = os.path.join(HERE, "_test_page.html")
        try:
            with redirect_stdout(out):
                self.assertEqual(E.main([BASE, "--html", page]), 0)
            with open(page, encoding="utf-8") as f:
                html = f.read()
            self.assertEqual(html.count("<figure>"), 8)
            self.assertIn("Les deux kits les plus proches", out.getvalue())
        finally:
            if os.path.exists(page):
                os.remove(page)


if __name__ == "__main__":
    result = unittest.main(exit=False, verbosity=1).result
    print(f"Empreinte: {result.testsRun - len(result.failures) - len(result.errors)} passed")
    sys.exit(0 if result.wasSuccessful() else 1)
