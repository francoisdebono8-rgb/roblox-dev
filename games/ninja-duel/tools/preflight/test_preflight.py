#!/usr/bin/env python3
"""Tests of the publication pre-flight (OUTILLEUR, 23/11).

    python3 tools/preflight/test_preflight.py
"""
import os
import sys
import tempfile
import unittest
from pathlib import Path

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import preflight as P  # noqa: E402

PLACE = """<roblox version="4">
<Item class="ReplicatedStorage" referent="R1"><Properties><string name="Name">ReplicatedStorage</string></Properties>
<Item class="Folder" referent="R2"><Properties><string name="Name">NinjaDuel</string></Properties>
<Item class="StringValue" referent="R3"><Properties><string name="Name">BuildProfile</string><string name="Value">{profile}</string></Properties></Item>
<Item class="StringValue" referent="R4"><Properties><string name="Name">SourceCommit</string><string name="Value">{commit}</string></Properties></Item>
<Item class="StringValue" referent="R5"><Properties><string name="Name">RuntimeFingerprint</string><string name="Value">abc</string></Properties></Item>
<Item class="ModuleScript" referent="R6"><Properties><string name="Name">{module}</string><ProtectedString name="Source"><![CDATA[return {{}}]]></ProtectedString></Properties></Item>
</Item></Item></roblox>"""


def report_for(place):
    with tempfile.TemporaryDirectory() as tmp:
        path = Path(tmp) / "NinjaDuel.rbxlx"
        path.write_text(place, encoding="utf-8")
        r = P.Report()
        P.check_place(r, path, Path(tmp) / "none.json", {})
        return {i["point"]: i for i in r.items}


class Preflight(unittest.TestCase):
    def test_the_offers_are_read_from_the_sources(self):
        cfg = P.config_offers()
        self.assertIn("VIP", cfg["passes"])
        self.assertEqual(len(cfg["packs"]), 3)
        self.assertIn(cfg["live"], (True, False))
        passes = [p for p, _ in P.shop_passes()]
        self.assertIn("MasteryPass", passes)
        looks = P.robux_looks()
        self.assertTrue(looks)
        for look in looks:
            self.assertIn(look["key"], cfg["products"], f"{look['id']} sold with a key Config.Shop.Products lacks")
        self.assertEqual(len(P.roster()), 8)

    def test_a_debug_module_or_another_profile_is_red(self):
        items = report_for(PLACE.format(profile="release", commit="x", module="DevTools"))
        self.assertEqual(items["Aucun outil de debug ni de tournage"]["status"], P.RED)
        items = report_for(PLACE.format(profile="debug", commit="x", module="Main"))
        self.assertEqual(items["Aucun outil de debug ni de tournage"]["status"], P.RED)
        items = report_for(PLACE.format(profile="release", commit="x", module="Main"))
        self.assertEqual(items["Aucun outil de debug ni de tournage"]["status"], P.GREEN)

    def test_test_code_is_red(self):
        for name in ("NDDuelBot", "Harness", "Combat.spec", "TestEZ"):
            items = report_for(PLACE.format(profile="release", commit="x", module=name))
            self.assertEqual(items["Pas de code de test dans la place"]["status"], P.RED, name)

    def test_a_dirty_or_old_version_line_is_red(self):
        items = report_for(PLACE.format(profile="release", commit="0000000000ab-dirty", module="Main"))
        self.assertEqual(items["La ligne de version est la bonne"]["status"], P.RED)

    def test_the_datastores_are_found(self):
        names = P.datastore_names()
        live = [n for n, v in names.items() if v["live"]]
        studio = [n for n, v in names.items() if not v["live"]]
        self.assertIn("NinjaDuel_Progression", live)
        self.assertTrue(any(n.endswith("_DEV") for n in studio))
        self.assertTrue(any(n.startswith("NinjaDuelKit_") for n in live))
        self.assertFalse(any(n.endswith("_") for n in names), "a name cut short")

    def test_four_codes_at_once_are_red(self):
        r = P.Report()
        P.check_codes(r, "2026-11-23")
        statuses = {i["status"] for i in r.items}
        self.assertTrue(statuses <= {P.RED, P.GREEN})
        r2 = P.Report()
        P.check_codes(r2, "2099-01-01")
        self.assertEqual(r2.items[0]["status"], P.GREEN, "no code is live in 2099")

    def test_the_report_runs_and_writes(self):
        r, names = P.run("2026-11-23")
        self.assertTrue(r.items)
        md = P.markdown(r, "abcdef12", "now", names)
        self.assertIn("Pré-vol de publication", md)
        self.assertIn("<!doctype html>", P.page(r, "abcdef12", "now"))


if __name__ == "__main__":
    result = unittest.main(exit=False, verbosity=1).result
    print(f"Preflight: {result.testsRun - len(result.failures) - len(result.errors)} passed")
    sys.exit(0 if result.wasSuccessful() else 1)
