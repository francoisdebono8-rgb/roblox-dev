#!/usr/bin/env python3
"""Tests of the Studio code of the simulated player and of the village robot
(OUTILLEUR, 21/11): what goes into Studio is the module, whole, with its plan.

    python3 tools/duelbot/test_studio_code.py
"""
import json
import os
import sys
import unittest

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import studio_code as S  # noqa: E402

sys.path.insert(0, os.path.join(HERE, "..", "villagebot"))
import importlib.util  # noqa: E402

_spec = importlib.util.spec_from_file_location("village_code", os.path.join(HERE, "..", "villagebot", "studio_code.py"))
V = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(V)


class StudioCode(unittest.TestCase):
    def test_the_module_carries_the_player_and_the_driver(self):
        code = S.module_source()
        self.assertIn("local PlayerSim=(function()", code)
        self.assertIn("debutant={", code)
        self.assertIn("function Bot.start(PLAN)", code)
        self.assertNotIn("--@", code)
        body = code
        self.assertFalse(any(line.strip().startswith("--") for line in body.splitlines()), "comments stripped")
        self.assertEqual(body.count("local PlayerSim=(function()"), 1)
        self.assertIn("return PlayerSim\nend)()", body, "the inline module is closed")

    def test_a_plan_from_the_command_line(self):
        plan = S.plan_from_args(["--first", "debutant", "1,2", "Lion,Leaf"])
        self.assertEqual(len(plan), 4)
        self.assertEqual(plan[0], {"mode": "first", "kit": "Lion", "seed": 1, "profile": "debutant"})
        duel = S.plan_from_args(["--duel", "joueur", "easy", "3", "Lion:Sand"])
        self.assertEqual(duel, [{"mode": "duel", "kit": "Lion", "rival": "Sand", "level": "easy", "seed": 3, "profile": "joueur"}])
        self.assertEqual(S.plan_from_args([json.dumps(plan)]), plan)
        call = S.start(plan[:1])
        self.assertEqual(call, 'return (_G.NDDuelBot or error("NDDuelBot absent : python3 tools/robots/inject.py duel (pendant le Play)"))'
                               '.start({{mode="first",kit="Lion",seed=1,profile="debutant"}})')
        self.assertEqual(S.main(["--module"]), 2, "DEC-052: nothing installed in Edit any more")

    def test_strip_keeps_code_and_strings(self):
        src = 'local a=1 -- a note\n-- a line\nlocal s="--not a comment"\n\nreturn a'
        self.assertEqual(S.strip(src), 'local a=1\nlocal s="--not a comment"\nreturn a')

    def test_the_village_robot_module(self):
        code = V.module_source()
        self.assertIn("function Bot.walkTo(goal,label,near)", code)
        self.assertIn("function Bot.race()", code)
        self.assertIn("function Bot.toward(goal,limit,done)", code)
        self.assertIn("function Bot.climb(roof)", code)
        self.assertIn("NDVillageLog", code)


if __name__ == "__main__":
    result = unittest.main(exit=False, verbosity=1).result
    print(f"BotCode: {result.testsRun - len(result.failures) - len(result.errors)} passed")
    sys.exit(0 if result.wasSuccessful() else 1)
