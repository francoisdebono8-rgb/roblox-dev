#!/usr/bin/env python3
"""Tests of the new-player robot's Studio code (OUTILLEUR, 23/11).

    python3 tools/newplayer/test_studio_code.py
"""
import os
import sys
import unittest

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import studio_code as S  # noqa: E402


class NewPlayer(unittest.TestCase):
    def test_the_funnel_keeps_the_first_of_each_step(self):
        text = ("[NinjaDuelFirst] -1 joined 0.0s\n[NinjaDuelFirst] -1 started 29.0s\n"
                "[NinjaDuelFirst] -1 won 74.3s\n[NinjaDuelFirst] -1 won 300.0s\nnoise")
        self.assertEqual(S.funnel(text), {"joined": 0.0, "started": 29.0, "won": 74.3})

    def test_the_report_says_what_was_not_reached(self):
        log = {"minutes": 10, "kit": "Legion",
               "steps": [{"t": 1.0, "step": "joined", "ok": True}, {"t": 600, "step": "rooftop race", "ok": True, "time": 2153},
                         {"t": 620, "step": "rooftop race", "ok": True, "time": 1951}],
               "screens": [{"t": 0, "at": "first screen", "phase": "Selection", "words": ["[DUELS]", "[SHOP]"]}]}
        text = S.report(log, {"joined": 0.0, "won": 74.3})
        self.assertIn("bought", text)
        self.assertIn("(pas atteint)", text)
        self.assertIn("courses des toits : 2", text)
        self.assertIn("[DUELS]", text)

    def test_the_snippets(self):
        self.assertEqual(S.main(["--start", "10", "Legion"]), 0)
        self.assertIn('kit="Legion"', S.START.format(minutes=10, kit="Legion"))
        self.assertIn("[NinjaDuelFirst]", S.FUNNEL)


if __name__ == "__main__":
    result = unittest.main(exit=False, verbosity=1).result
    print(f"NewPlayer: {result.testsRun - len(result.failures) - len(result.errors)} passed")
    sys.exit(0 if result.wasSuccessful() else 1)
