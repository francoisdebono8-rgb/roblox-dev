"""Negative checks for the release packaging guard; not product/native tests."""

from pathlib import Path
import tempfile
import unittest
import xml.etree.ElementTree as ET

from verify_freeze import inspect_model


class PackagingGuardTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        source = Path(self.tmp.name) / "Main.luau"
        source.write_text("return true\n")
        self.expected = {"Main": ("Script", source), "Modules/Engine": ("ModuleScript", source)}
        self.root = ET.fromstring('''<Item class="Model"><Properties>
          <string name="Name">Product</string></Properties>
          <Item class="Script"><Properties><string name="Name">Main</string>
          <ProtectedString name="Source">return true\n</ProtectedString></Properties></Item>
          <Item class="Folder"><Properties><string name="Name">Modules</string></Properties>
          <Item class="ModuleScript"><Properties><string name="Name">Engine</string>
          <ProtectedString name="Source">return true\n</ProtectedString></Properties></Item>
          </Item></Item>''')

    def test_exact_sources_pass(self):
        self.assertEqual(set(inspect_model(self.root, self.expected)), set(self.expected))

    def test_changed_source_fails(self):
        self.root.find("Item/Properties/ProtectedString").text = "return false"
        with self.assertRaisesRegex(AssertionError, "Source mismatch"):
            inspect_model(self.root, self.expected)

    def test_disabled_entry_fails(self):
        ET.SubElement(self.root.find("Item/Properties"), "bool", name="Disabled").text = "true"
        with self.assertRaises(AssertionError):
            inspect_model(self.root, self.expected)

    def test_extra_demo_fails(self):
        demo = ET.SubElement(self.root, "Item", attrib={"class": "Folder"})
        ET.SubElement(ET.SubElement(demo, "Properties"), "string", name="Name").text = "Demo"
        with self.assertRaisesRegex(AssertionError, "Unexpected container"):
            inspect_model(self.root, self.expected)

    def test_duplicate_source_fails(self):
        self.root.append(ET.fromstring(ET.tostring(self.root.find("Item"))))
        with self.assertRaisesRegex(AssertionError, "Unexpected script"):
            inspect_model(self.root, self.expected)

    def test_missing_source_fails(self):
        self.root.remove(self.root.find("Item"))
        with self.assertRaisesRegex(AssertionError, "Missing production sources"):
            inspect_model(self.root, self.expected)

    def test_wrong_class_fails(self):
        self.root.find("Item").set("class", "ModuleScript")
        with self.assertRaisesRegex(AssertionError, "Wrong script class"):
            inspect_model(self.root, self.expected)


if __name__ == "__main__":
    unittest.main()
