"""Verify built artifacts exclude debug/Motion Lab code from normal play."""
from pathlib import Path
import json
import unittest
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]


def scripts(filename):
    result = {}
    for item in ET.parse(ROOT / 'dist' / filename).iter('Item'):
        if item.get('class') in ('Script', 'LocalScript', 'ModuleScript'):
            properties = item.find('Properties')
            name = properties.findtext("string[@name='Name']")
            # Both the client and server entry points are named Main.
            key = item.get('class') + ':' + name if name == 'Main' else name
            result[key] = properties.findtext("*[@name='Source']") or ''
    return result


class BuildIsolation(unittest.TestCase):
    def test_normal_artifact_has_no_diagnostic_modules_or_motion_lab(self):
        code = scripts('NinjaDuel.rbxlx')
        self.assertTrue({'DevHooks', 'CombatInspector', 'CombatDebug', 'NativeQA'}.isdisjoint(code))
        self.assertNotIn('NinjaDuelDebug\",true', '\n'.join(code.values()))
        self.assertNotIn('NinjaDuelAdapter', code)
        self.assertNotIn('ForgeMotionLab', code)
        manifest = json.loads((ROOT / 'dist/NinjaDuel.json').read_text())
        self.assertFalse(manifest['debugOnly'])
        self.assertTrue(all('motion-lab' not in path for path in manifest['sources']))

    def test_debug_place_contains_observer_and_has_no_automatic_native_qa(self):
        code = scripts('NinjaDuel-Debug.rbxlx')
        self.assertTrue({'DevHooks', 'CombatInspector', 'CombatDebug'} <= code.keys())
        self.assertNotIn('NativeQA', code)
        self.assertTrue(any('SetAttribute("NinjaDuelDebug",true)' in source for source in code.values()))
        self.assertFalse(any('SetAttribute("NinjaDuelQA",true)' in source for source in code.values()))

    def test_qa_place_is_explicitly_opted_in(self):
        code = scripts('NinjaDuel-QA.rbxlx')
        self.assertTrue({'DevHooks', 'CombatInspector', 'CombatDebug', 'NativeQA'} <= code.keys())
        self.assertTrue(any('SetAttribute("NinjaDuelQA",true)' in source for source in code.values()))

    def test_debug_and_qa_keep_the_exact_normal_engine_sources(self):
        normal = scripts('NinjaDuel.rbxlx')
        for variant in ('NinjaDuel-Debug.rbxlx', 'NinjaDuel-QA.rbxlx'):
            other = scripts(variant)
            for name, source in normal.items():
                if not name.endswith(':Main'):
                    self.assertEqual(source, other[name], (variant, name))


if __name__ == '__main__':
    unittest.main()
