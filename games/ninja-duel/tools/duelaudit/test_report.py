#!/usr/bin/env python3
"""Tests of the passe commune 2 robots' reports (OUTILLEUR, 26/11; DEC-054), without Studio:
the duel watcher (tools/duelaudit), the training robot (tools/training), the outfit
check (tools/outfitcheck).

    python3 tools/duelaudit/test_report.py
"""
import importlib.util
import json
import os
import sys
import tempfile
import unittest

HERE = os.path.dirname(os.path.abspath(__file__))
TOOLS = os.path.dirname(HERE)


def load(rel, name):
    spec = importlib.util.spec_from_file_location(name, os.path.join(TOOLS, rel))
    mod = importlib.util.module_from_spec(spec)
    sys.path.insert(0, os.path.dirname(os.path.join(TOOLS, rel)))
    spec.loader.exec_module(mod)
    return mod


R = load("duelaudit/report.py", "nd_duelaudit_report")
T = load("training/report.py", "nd_training_report")
O = load("outfitcheck/report.py", "nd_outfit_report")


class DuelAudit(unittest.TestCase):
    def test_the_plan_plays_the_eight_kits_each_against_another(self):
        plan = R.plan()
        self.assertEqual([r["kit"] for r in plan], R.BETA)
        self.assertEqual(sorted(r["rival"] for r in plan), sorted(R.BETA))
        self.assertTrue(all(r["kit"] != r["rival"] for r in plan))
        self.assertIn("NDDuelAudit", R.start_code(plan))
        self.assertIn(".start({{mode=\"duel\",kit=\"Lion\"", R.start_code(plan))

    def test_the_table_counts_each_kind_per_duel(self):
        data = {"audit": {"runs": [
            {"index": 1, "kit": "Lion", "rival": "Legion", "avatar": True, "seconds": 61, "rounds": 2,
             "counts": {"traverse": 2, "pousse_rival": 5}, "incidents": [
                 {"kind": "traverse", "who": "joueur", "detail": "Light1 : RightHand dans UpperTorso", "t": 3.2, "round": 1, "framed": True},
                 {"kind": "pousse_rival", "who": "joueur", "detail": "pousse", "t": 4, "round": 1}]}],
            "errors": [{"msg": "UltimateFX:590: attempt to index boolean", "n": 1, "kit": "Sand"}]},
            "server": {"errors": [], "warnings": []}}
        text = R.report(data)
        self.assertIn("Sasuke (Lion) contre Naruto (Legion) (avatar)", text)
        self.assertIn("| **2** |", text)
        self.assertIn("Light1 : RightHand dans UpperTorso · image", text)
        self.assertNotIn("**pousse_rival**", text, "pushing the rival is no incoherence")
        self.assertIn("poussé l'adversaire 5 fois", text)
        self.assertIn("UltimateFX:590", text)

    def test_the_command_line(self):
        self.assertEqual(R.main(["--read"]), 0)
        self.assertEqual(R.main(["--show", "2", "3", "back"]), 0)
        self.assertEqual(R.main([]), 2)


class Training(unittest.TestCase):
    SERVER = {"tutorial": [
        {"t": 3, "line": "[NinjaDuelTutorial] Lion 1/30 move: PASS 1.8s"},
        {"t": 30, "line": "[NinjaDuelTutorial] Lion 6/30 wall: SKIP 22.1s  refused: Committedx3"},
    ], "errors": [{"msg": "boom", "n": 2}]}
    ROBOT = {"results": [{"kit": "Lion", "rival": "Legion", "steps": [
        {"index": 1, "total": 30, "id": "move", "title": "Move", "key": "WASD", "outcome": "fini", "seconds": 1.9, "tries": 1, "cues": []},
        {"index": 6, "total": 30, "id": "wall", "title": "Run up the wall", "key": "Move into the wall, then Space", "outcome": "abandonné",
         "seconds": 22, "tries": 6, "cues": ["COOLDOWN"]},
    ]}]}

    def test_the_server_lines_are_read(self):
        v = T.verdicts(self.SERVER)
        self.assertEqual(v[("Lion", 1, "move")]["status"], "PASS")
        self.assertEqual(v[("Lion", 6, "wall")]["status"], "SKIP")
        self.assertIn("Committedx3", v[("Lion", 6, "wall")]["rest"])

    def test_the_report_says_where_each_kit_blocks(self):
        text = T.report({"robot": self.ROBOT, "server": self.SERVER})
        self.assertIn("| Sasuke (Lion) | 2 | 1 | 1 | 6 wall |", text)
        self.assertIn("l'écran a dit : COOLDOWN", text)
        self.assertIn("refused: Committedx3", text)
        self.assertIn("2 texte(s)", text.replace("1 texte(s)", "2 texte(s)"))

    def test_the_plan_and_the_code(self):
        plan = T.plan()
        self.assertEqual(len(plan), 8)
        self.assertTrue(all(p["kit"] != p["rival"] for p in plan))
        self.assertEqual(T.plan(["Leaf"])[0]["rival"], "GentleFist")
        self.assertIn('{kit="Lion",rival="Legion"}', T.lua(plan))


class Outfits(unittest.TestCase):
    def piece(self, item, piece, inside, off, loose=False):
        return {"item": item, "piece": piece, "on": "RightLowerArm", "loose": loose,
                "rest": {"inside": inside, "off": off}, "worstIn": {"inside": inside, "maxIn": .3},
                "worstInPose": "Lion.Heavy@0.3", "worstOff": {"off": off, "maxOff": .6}, "worstOffPose": "repos"}

    def test_a_piece_goes_through_or_stands_off(self):
        self.assertEqual([v[0] for v in O.verdict(self.piece("ArmsWraps", "Wrap", .4, .5))], ["traverse", "flotte"])
        self.assertEqual(O.verdict(self.piece("ArmsWraps", "Wrap", .02, .1)), [])
        self.assertEqual([v[0] for v in O.verdict(self.piece("CapeShortRed", "Cape", .02, .9, loose=True))], [],
                         "a cape hangs off the body by design")

    def test_the_table_has_one_column_per_body(self):
        with tempfile.TemporaryDirectory() as d:
            path = os.path.join(d, "ArmsWraps.json")
            with open(path, "w", encoding="utf-8") as f:
                json.dump({"look": "ArmsWraps", "bodies": {
                    "bigbill": {"pieces": [self.piece("ArmsWraps", "Wrap", .3, .1)]},
                    "francois": {"pieces": [self.piece("ArmsWraps", "Wrap", .01, .6)]}}}, f)
            text = O.report([path])
        self.assertIn("| ArmsWraps / Wrap | traverse |", text)
        self.assertIn("30 % · 0.30", text)
        self.assertIn("| ArmsWraps / Wrap | flotte | 60 % · 0.60", text)
        self.assertIn("Big Bill (large, Rthro)", text)

    def test_the_looks_put_bandages_and_bracelets_first(self):
        names = list(O.LOOKS)
        self.assertEqual(names[0], "ArmsWraps")
        self.assertTrue(all(n.startswith("Arms") for n in names[:8]))
        self.assertIn("dress({top=\"TopTunicNavy\"", O.lua(O.LOOKS["ArmsWraps"]).join(["dress(", ")"]))


if __name__ == "__main__":
    result = unittest.main(exit=False, verbosity=1).result
    print(f"Robots passe 2: {result.testsRun - len(result.failures) - len(result.errors)} passed")
    sys.exit(0 if result.wasSuccessful() else 1)
