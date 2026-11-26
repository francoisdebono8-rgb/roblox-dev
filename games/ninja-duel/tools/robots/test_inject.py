#!/usr/bin/env python3
"""Tests of the robots injected during a Play (OUTILLEUR, passe commune 1, DEC-052).

    python3 tools/robots/test_inject.py
"""
import glob
import importlib.util
import os
import re
import sys
import unittest

HERE = os.path.dirname(os.path.abspath(__file__))
TOOLS = os.path.dirname(HERE)
sys.path.insert(0, HERE)
import inject as I  # noqa: E402


def load(rel, name):
    spec = importlib.util.spec_from_file_location(name, os.path.join(TOOLS, rel))
    mod = importlib.util.module_from_spec(spec)
    sys.path.insert(0, os.path.dirname(os.path.join(TOOLS, rel)))
    spec.loader.exec_module(mod)
    return mod


class Inject(unittest.TestCase):
    def test_a_robot_comes_with_what_it_needs(self):
        self.assertEqual(I.order(["newplayer"]), ["duel", "village", "newplayer"])
        self.assertEqual(I.order(["collision", "screens", "collision"]), ["collision", "screens"])
        self.assertEqual(len(I.order(["all"])), len(I.ROBOTS))
        with self.assertRaises(KeyError):
            I.order(["lab"])

    def test_the_snippet_puts_each_robot_in_G(self):
        code = I.snippet(["collision", "screens"], stamp="abc12345")
        self.assertEqual(code.count('put("NDCollisionBot",function()'), 1)
        self.assertEqual(code.count('put("NDScreenTour",function()'), 1)
        self.assertIn("return Bot\nend)", code, "the module's own return closes its function")
        self.assertIn('_G.NDRobots={commit="abc12345"', code)
        self.assertTrue(code.rstrip().splitlines()[-1].startswith("return "))
        self.assertFalse([l for l in code.splitlines() if l.startswith("--")], "comments stripped")
        self.assertNotIn("ReplicatedStorage\"):WaitForChild(\"ND", code)
        self.assertNotIn("Instance.new(\"ModuleScript\")", code, "nothing is put into the place")

    def test_every_robot_builds(self):
        for short in I.ROBOTS:
            src = I.source(short)
            self.assertGreater(len(src), 1000, short)
            self.assertFalse(src.startswith("\t"))

    def test_the_tools_look_the_robots_up_in_G(self):
        col = load("collision/collision.py", "nd_collision")
        rel = load("screens/releve.py", "nd_releve")
        perf = load("perf/studio_code.py", "nd_perf_code")
        new = load("newplayer/studio_code.py", "nd_newplayer_code")
        duel = load("duelbot/studio_code.py", "nd_duel_code")
        village = load("villagebot/studio_code.py", "nd_village_code")
        self.assertEqual(col.REQ, I.lookup("NDCollisionBot"))
        self.assertEqual(rel.REQ, I.lookup("NDScreenTour"))
        self.assertIn(I.lookup("NDPerfProbe"), perf.MEASURE)
        self.assertIn(I.lookup("NDNewPlayerBot"), new.START)
        self.assertEqual(duel.ROBOT, I.lookup("NDDuelBot"))
        self.assertEqual(village.ROBOT, I.lookup("NDVillageBot"))

    def test_no_robot_is_looked_for_in_the_place_any_more(self):
        names = "|".join(mod for mod, _, _ in I.ROBOTS.values())
        pattern = re.compile(r'WaitForChild\("(' + names + r')"|ReplicatedStorage\.(' + names + r')\b')
        found = []
        for path in glob.glob(os.path.join(TOOLS, "*", "*.py")) + glob.glob(os.path.join(TOOLS, "*", "*.luau")):
            if os.path.basename(path).startswith("test_"):
                continue
            with open(path, encoding="utf-8") as f:
                for n, line in enumerate(f, 1):
                    if pattern.search(line):
                        found.append(f"{os.path.relpath(path, TOOLS)}:{n}")
        self.assertEqual(found, [])

    def test_the_server_robots(self):
        # (26/11, passe 2) the server's robots go through eval_server_runtime
        code = I.snippet(["serverlog", "outfitbodies"], stamp="abc12345", server=True)
        self.assertIn('put("NDServerLog",function()', code)
        self.assertIn('put("NDOutfitBodies",function()', code)
        self.assertIn('_G.NDServerRobots={commit="abc12345"', code)
        self.assertNotIn("_G.NDRobots=", code)
        self.assertIn("--server serverlog", I.lookup("NDServerLog"))
        with self.assertRaises(KeyError):
            I.order(["serverlog"])  # not a client robot
        self.assertEqual(I.order(["training"]), ["duel", "training"])
        self.assertEqual(I.main(["--server", "serverlog"]), 0)
        self.assertEqual(I.main(["--check-server"]), 0)

    def test_the_command_line(self):
        self.assertEqual(I.main(["--list"]), 0)
        self.assertEqual(I.main(["--check"]), 0)
        self.assertEqual(I.main(["lab"]), 2)
        self.assertIn("_G.NDRobots", I.CHECK)


if __name__ == "__main__":
    result = unittest.main(exit=False, verbosity=1).result
    print(f"Robots: {result.testsRun - len(result.failures) - len(result.errors)} passed")
    sys.exit(0 if result.wasSuccessful() else 1)
