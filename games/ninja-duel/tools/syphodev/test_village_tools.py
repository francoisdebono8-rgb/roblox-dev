#!/usr/bin/env python3
"""Tests of the village tools of step 3 (OUTILLEUR, 21/11): the dump carried through a
CI log (ci_dump.py) and the plan's roofs at the prover (konoha_plan_roofs.py).

    python3 tools/syphodev/test_village_tools.py
"""
import os
import sys
import unittest

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import ci_dump  # noqa: E402
import konoha_plan_roofs as roofs  # noqa: E402


class Dump(unittest.TestCase):
    def test_a_dump_comes_back_whole_from_a_log(self):
        data = {"origin": [0, 0, -2400], "scale": 1.3,
                "parts": [{"name": f"Roof{i}", "pos": [i, 20.5, -i], "size": [24, 1, 20]} for i in range(400)]}
        lines = ci_dump.encode(data)
        self.assertGreater(len(lines), 1, "long enough to need several lines")
        self.assertTrue(all(len(line) <= ci_dump.WIDTH + 3 for line in lines))
        # as GitHub prints them: a job, a step and a time before each line
        log = "\n".join(f"suite\tLuau suites\t2026-11-21T16:14:12.29Z {line}" for line in lines)
        self.assertEqual(ci_dump.decode("noise\n" + log + "\nmore noise"), data)


class PlanRoofs(unittest.TestCase):
    SPEC = {"name": "KonohaPlan", "intent": {"reachable": ["Ground"]}, "parts": [
        {"id": "Ground", "roles": ["arena_floor"], "pos": [0, 0, 0], "size": [100, 1, 100]},
        {"id": "tank_house_H1", "roles": ["cover"], "decor": True, "mesh": "tank_house", "pos": [10, 9, 10], "size": [20, 18, 20]},
        {"id": "apartment_H2", "roles": ["cover"], "decor": True, "mesh": "apartment", "pos": [-10, 12, 10], "size": [20, 24, 20]},
        {"id": "lamp_1", "roles": ["cover"], "decor": True, "mesh": "lamp", "pos": [0, 2, 0], "size": [1, 4, 1]},
    ]}

    def test_each_house_becomes_a_roof_to_reach_and_nothing_else_changes(self):
        variant, houses = roofs.roofs_spec(self.SPEC)
        self.assertEqual(houses, ["tank_house_H1", "apartment_H2"])
        by_id = {p["id"]: p for p in variant["parts"]}
        self.assertEqual(by_id["tank_house_H1"]["roles"], ["high_ground"])
        self.assertNotIn("decor", by_id["apartment_H2"])
        self.assertTrue(by_id["lamp_1"]["decor"], "a lamp stays decoration")
        self.assertIn("tank_house_*", variant["intent"]["reachable"])
        self.assertTrue(self.SPEC["parts"][1]["decor"], "the plan's own spec is not touched")

    def test_the_prover_text_reads_as_roofs(self):
        text = ("[FAIL         ] P3  Intent match\n"
                "                  - apartment_H2: intended reachable, but only via the generous envelope\n"
                "                  - WaterTower: possibly reachable and not declared\n"
                "[FAIL         ] P6  Overlap\n"
                "                  - HyugaWallN and tank_house_H1 overlap by 5.85 studs\n"
                "                  - Gate and Plaza overlap by 1.00 studs\n"
                "RESULT: FAIL\n")
        s = roofs.summary(text, ["tank_house_H1", "apartment_H2"])
        self.assertEqual(s["walking"], 1)
        self.assertEqual(s["runup"], ["apartment_H2"])
        self.assertEqual(s["never"], [])
        self.assertEqual(s["walls"], [("HyugaWallN", "tank_house_H1", 5.85)], "only a house in a wall")
        never = roofs.summary("- tank_house_H1: intended reachable, but NO route exists\n", ["tank_house_H1"])
        self.assertEqual(never["never"], ["tank_house_H1"])
        self.assertEqual(never["walking"], 0)


if __name__ == "__main__":
    result = unittest.main(exit=False, verbosity=1).result
    print(f"VillageTools: {result.testsRun - len(result.failures) - len(result.errors)} passed")
    sys.exit(0 if result.wasSuccessful() else 1)
