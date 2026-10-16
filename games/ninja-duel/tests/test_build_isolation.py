"""Verify built artifacts exclude debug/Motion Lab code from normal play."""
from pathlib import Path
import ast
import hashlib
import json
import re
import subprocess
import sys
import tempfile
import unittest
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
# Studio-only modules that must never reach the normal place: the inspector,
# Codex's dev tools (F6 panel, setups, profiler, report, self-test) and its
# chakra lab (docs/tools/DEVTOOLS.md). build.py's DEBUG_SOURCES must list them.
INSPECTOR = {'DevHooks', 'CombatInspector', 'CombatDebug'}
DEV_TOOLS = {'DevTools', 'DevCommands', 'DevScenarios', 'DevProfiler', 'DevReport', 'DevQA', 'DevMetrics',
             'DevClient', 'DevVolumes', 'ChakraLab', 'ChakraDev', 'ChakraStudioView', 'ChakraStudioQA'}
DEBUG_ONLY = INSPECTOR | DEV_TOOLS
# Strings that only the debug-only modules contain (remote, GUI, Output and folder names).
MARKERS = ('NinjaDuelDevControl', 'NinjaDuelDevPanel', 'NinjaDuelDevMeasure', 'DevObservedVolume', '[NinjaDuelPerf]',
           '[NinjaDuelDevQA]', '[NinjaDuelChakraQA]', 'NinjaDuelChakraLab', 'NinjaDuelCombatDebug')


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


def debug_sources():
    """build.py's DEBUG_SOURCES, read without running the build."""
    tree = ast.parse((ROOT / 'build.py').read_text(encoding='utf-8'))
    for node in ast.walk(tree):
        if isinstance(node, ast.Assign) and any(isinstance(t, ast.Name) and t.id == 'DEBUG_SOURCES' for t in node.targets):
            return ast.literal_eval(node.value)
    raise AssertionError('DEBUG_SOURCES not found in build.py')


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

    def test_normal_artifact_has_none_of_the_dev_tools(self):
        code = scripts('NinjaDuel.rbxlx')
        self.assertEqual(DEBUG_ONLY & set(code), set(), 'debug-only module in the normal place')
        text = '\n'.join(code.values())
        for marker in MARKERS:
            self.assertNotIn(marker, text, marker)
        manifest = json.loads((ROOT / 'dist/NinjaDuel.json').read_text())
        shipped = {Path(path).name.split('.')[0] for path in manifest['sources']}
        self.assertEqual(DEBUG_ONLY & shipped, set(), 'debug-only source in the normal manifest')
        # The fingerprint covers exactly the shipped sources, so it differs from Debug's.
        debug = json.loads((ROOT / 'dist/NinjaDuel-Debug.json').read_text())
        self.assertNotEqual(manifest['buildFingerprint'], debug['buildFingerprint'])

    def test_debug_sources_are_declared_and_exist(self):
        declared = {name.split('.')[0] for name in debug_sources()}
        self.assertTrue(DEBUG_ONLY <= declared, DEBUG_ONLY - declared)
        present = {p.name for p in (ROOT / 'src').rglob('*.luau')}
        for name in debug_sources():
            self.assertIn(name, present, name + ' is listed in DEBUG_SOURCES but missing from src')

    def test_no_shipped_module_requires_a_debug_only_module(self):
        # Only Main.server may name one, inside its Studio + NinjaDuelDebug/QA guards;
        # Main.client looks DevClient up with FindFirstChild under IsStudio.
        stems = DEBUG_ONLY | {'NativeQA'}
        allowed = {('Script:Main', 'DevHooks'), ('Script:Main', 'NativeQA')}
        code = scripts('NinjaDuel.rbxlx')
        for name, source in code.items():
            for target in re.findall(r'require\(\s*script\.Parent\.(\w+)', source):
                if target in stems:
                    self.assertIn((name, target), allowed, f'{name} requires debug-only {target}')
        self.assertRegex(code['Script:Main'], r'IsStudio\(\) and workspace:GetAttribute\("NinjaDuelDebug"\)==true then\s+require\(script\.Parent\.DevHooks\)')
        client = code['LocalScript:Main']
        self.assertIn('RunService:IsStudio() and script.Parent:FindFirstChild("DevClient")', client)
        self.assertNotRegex(client, r'require\(\s*script\.Parent\.Dev')

    def test_debug_place_contains_observer_and_has_no_automatic_native_qa(self):
        code = scripts('NinjaDuel-Debug.rbxlx')
        self.assertTrue({'DevHooks', 'CombatInspector', 'CombatDebug'} <= code.keys())
        self.assertTrue(DEV_TOOLS <= code.keys(), DEV_TOOLS - code.keys())
        self.assertNotIn('NativeQA', code)
        self.assertTrue(any('SetAttribute("NinjaDuelDebug",true)' in source for source in code.values()))
        self.assertFalse(any('SetAttribute("NinjaDuelQA",true)' in source for source in code.values()))

    def test_qa_place_is_explicitly_opted_in(self):
        code = scripts('NinjaDuel-QA.rbxlx')
        self.assertTrue({'DevHooks', 'CombatInspector', 'CombatDebug', 'NativeQA'} <= code.keys())
        # Same rule as the inspector: QA = Debug + NativeQA, so the dev tools are there too.
        self.assertTrue(DEV_TOOLS <= code.keys(), DEV_TOOLS - code.keys())
        self.assertTrue(any('SetAttribute("NinjaDuelQA",true)' in source for source in code.values()))

    def test_debug_and_qa_keep_the_exact_normal_engine_sources(self):
        normal = scripts('NinjaDuel.rbxlx')
        for variant in ('NinjaDuel-Debug.rbxlx', 'NinjaDuel-QA.rbxlx'):
            other = scripts(variant)
            for name, source in normal.items():
                if not name.endswith(':Main'):
                    self.assertEqual(source, other[name], (variant, name))


class DevToolsCli(unittest.TestCase):
    """tools/dev.py and the inert lab/ data (Codex's BuildTools checks, ported)."""

    def dev(self, *args):
        return subprocess.run([sys.executable, '-I', str(ROOT / 'tools/dev.py'), *args], cwd=ROOT,
                              capture_output=True, text=True, encoding='utf-8', errors='replace')

    def test_lab_catalogue_is_valid_and_outside_every_build(self):
        data = json.loads((ROOT / 'lab/combat-library.json').read_text(encoding='utf-8'))
        self.assertEqual(len(data['archetypes']), 10)
        self.assertGreaterEqual(len(data['entries']), 30)
        source = '\n'.join(p.read_text(encoding='utf-8') for p in (ROOT / 'src').rglob('*.luau'))
        for name in ('combat-library', 'combat-tags', 'lab/templates'):
            self.assertNotIn(name, source)
        proc = self.dev('catalogue', '--archetype', 'acrobatique')
        self.assertEqual(proc.returncode, 0, proc.stderr)
        self.assertIn('air_side', proc.stdout)
        for filename in ('NinjaDuel.json', 'NinjaDuel-Debug.json', 'NinjaDuel-QA.json'):
            manifest = json.loads((ROOT / 'dist' / filename).read_text())
            self.assertTrue(all(path.startswith('src/') for path in manifest['sources']), filename)

    def test_report_export_requires_complete_rows_of_the_exact_build(self):
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            artifact = root / 'place.rbxlx'
            artifact.write_bytes(b'fixture')
            manifest = root / 'place.json'
            manifest.write_text(json.dumps({'buildFingerprint': 'exact', 'sha256': hashlib.sha256(b'fixture').hexdigest()}))
            log, out = root / 'log', root / 'out.json'

            def command():
                return self.dev('report', '--log', str(log), '--manifest', str(manifest), '--out', str(out))
            rows = [{'kind': 'begin', 'clientPresent': True}, {'kind': 'meta', 'side': 'server', 'enabled': False, 'seconds': 3},
                    {'kind': 'metric', 'side': 'server', 'name': 'cost', 'value': {'mean': 1}},
                    {'kind': 'meta', 'side': 'client', 'enabled': False, 'seconds': 3}, {'kind': 'end', 'rows': 3}]

            def write(fingerprint, end=True, suffix=''):
                log.write_text('\n'.join('12:00:00.000  [NinjaDuelPerf] ' + json.dumps(dict(r, id='fixture', build=fingerprint)) + suffix
                                         for r in (rows if end else rows[:-1])), encoding='utf-8')
            write('other')
            self.assertNotEqual(command().returncode, 0, 'a foreign build was accepted')
            write('exact', end=False)
            self.assertNotEqual(command().returncode, 0, 'a truncated capture was accepted')
            write('exact', suffix='  -  Server - DevReport:11')
            proc = command()
            self.assertEqual(proc.returncode, 0, proc.stderr)
            result = json.loads(out.read_text(encoding='utf-8'))
            self.assertTrue(result['report']['complete'])
            self.assertEqual(result['report']['server']['stats']['cost'], {'mean': 1})
            artifact.write_bytes(b'rebuilt')
            self.assertNotEqual(command().returncode, 0, 'an artifact that differs from its manifest was accepted')


if __name__ == '__main__':
    unittest.main()
