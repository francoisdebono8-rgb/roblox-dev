#!/usr/bin/env python3
"""Tests of the LAB copy with the robots in it (OUTILLEUR, 23/11).

    python3 tools/lab/test_lab_place.py
"""
import os
import sys
import tempfile
import unittest
import xml.etree.ElementTree as ET

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import lab_place as L  # noqa: E402

PLACE = """<roblox version="4"><Item class="Workspace" referent="RBX1"><Properties><string name="Name">Workspace</string></Properties></Item>
<Item class="ReplicatedStorage" referent="RBX2"><Properties><string name="Name">ReplicatedStorage</string></Properties>
<Item class="Folder" referent="RBX3"><Properties><string name="Name">NinjaDuel</string></Properties></Item></Item></roblox>"""


def modules_in(text):
    root = ET.fromstring(text)
    rs = [i for i in root.iter("Item") if i.get("class") == "ReplicatedStorage"][0]
    out = {}
    for child in rs.findall("Item"):
        props = child.find("Properties")
        out[props.findtext("string[@name='Name']")] = props.findtext("ProtectedString[@name='Source']") or props.findtext("string[@name='Value']")
    return out


class LabPlace(unittest.TestCase):
    def test_the_robots_go_in_replicated_storage(self):
        mods = L.modules()
        self.assertEqual(set(mods), {"NDDuelBot", "NDVillageBot", "NDNewPlayerBot", "NDPerfProbe", "NDCollisionBot", "NDScreenTour"})
        text = L.inject(PLACE, mods, "tools test")
        found = modules_in(text)
        for name, src in mods.items():
            self.assertEqual(found[name], src)
        self.assertIn("NinjaDuel", found)
        self.assertEqual(found["NDLabTools"], "tools test")
        for src in mods.values():
            self.assertRegex(src.rstrip(), r"return (Bot|Probe|Tour)$")

    def test_a_copy_of_a_copy_keeps_one_of_each(self):
        mods = L.modules()
        twice = L.inject(L.inject(PLACE, mods, "a"), mods, "b")
        root = ET.fromstring(twice)
        names = [i.find("Properties").findtext("string[@name='Name']") for i in root.iter("Item")]
        for name in list(mods) + ["NDLabTools"]:
            self.assertEqual(names.count(name), 1, name)
        self.assertEqual(modules_in(twice)["NDLabTools"], "b")

    def test_never_into_places(self):
        with tempfile.TemporaryDirectory() as tmp:
            src = os.path.join(tmp, "a.rbxlx")
            with open(src, "w") as f:
                f.write(PLACE)
            os.makedirs(os.path.join(tmp, "PLACES"))
            self.assertEqual(L.main([src, os.path.join(tmp, "PLACES", "b.rbxlx")]), 2)
            self.assertEqual(L.main([src, src]), 2)
            out = os.path.join(tmp, "lab.rbxlx")
            self.assertEqual(L.main([src, out]), 0)
            self.assertIn("NDNewPlayerBot", modules_in(open(out).read()))


if __name__ == "__main__":
    result = unittest.main(exit=False, verbosity=1).result
    print(f"LabPlace: {result.testsRun - len(result.failures) - len(result.errors)} passed")
    sys.exit(0 if result.wasSuccessful() else 1)
