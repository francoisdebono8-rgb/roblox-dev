#!/usr/bin/env python3
"""Tests of the fluidity tools (OUTILLEUR, 23/11).

    python3 tools/perf/test_perf.py
"""
import os
import re
import sys
import unittest

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import studio_code as S  # noqa: E402


class Perf(unittest.TestCase):
    def probe(self):
        with open(os.path.join(HERE, "perf_probe.luau"), encoding="utf-8") as f:
            return f.read()

    def test_the_probe_only_calls_what_a_game_script_may(self):
        code = "\n".join(l.split("--", 1)[0] for l in self.probe().split("\n"))
        # settings() needs the Plugin capability: in a Play it stops the whole measure
        self.assertIsNone(re.search(r"\bsettings\(\)", code))
        self.assertIn("SceneTriangleCount", code)
        self.assertIn("RenderStepped", code)

    def test_the_studio_snippets(self):
        self.assertIn('label="village place"', S.MEASURE.format(seconds=8, label="village place"))
        go = S.GO.format(x=0.0, z=15.6)
        self.assertIn("HM.world(Vector3.new(0.0,0,15.6))", go)
        groups = S.groups_code()
        for g in S.GROUPS_LIST:
            self.assertIn(f'"{g}"', groups)
        self.assertIn("LocalTransparencyModifier", groups)
        cull = S.cull_code(120)
        self.assertIn(">120", cull)
        self.assertIn("row.cull120", cull)
        self.assertIn("hide(far,false)", cull)
        self.assertNotIn("%s", groups + cull)

    def test_the_report(self):
        text = S.report([{"label": "a06 village", "triangles": 1000, "trianglesMax": 2000, "drawcalls": 90,
                          "drawcallsMax": 120, "fps": 15, "scene": {"parts": 10}}])
        self.assertIn("a06 village", text)
        self.assertIn("1000 /    2000", text)


if __name__ == "__main__":
    result = unittest.main(exit=False, verbosity=1).result
    print(f"Perf: {result.testsRun - len(result.failures) - len(result.errors)} passed")
    sys.exit(0 if result.wasSuccessful() else 1)
