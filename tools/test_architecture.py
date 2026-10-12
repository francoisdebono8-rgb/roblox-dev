"""Exercise forbidden direct/transitive imports and the Motion Lab exception."""
from pathlib import Path
import tempfile
import unittest
from check_architecture import check


class BoundaryTests(unittest.TestCase):
    def audit(self, files):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            for name, text in files.items():
                path = root / name
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_text(text)
            return check(root)[0]

    def test_game_cannot_import_plugin(self):
        self.assertTrue(self.audit({'games/ninja-duel/src/main.luau': 'require("../../../plugins/forge/Engine")', 'plugins/forge/Engine.luau': 'return {}'}))

    def test_plugin_cannot_import_game(self):
        self.assertTrue(self.audit({'plugins/forge/Main.luau': 'require(game.ReplicatedStorage.NinjaDuel.Config)'}))

    def test_game_cannot_import_motion_lab(self):
        self.assertTrue(self.audit({'games/ninja-duel/src/main.luau': 'require("../motion-lab/adapter")', 'games/ninja-duel/motion-lab/adapter.luau': 'return {}'}))

    def test_motion_lab_adapter_can_import_game(self):
        self.assertFalse(self.audit({'games/ninja-duel/motion-lab/adapter.luau': 'require(game.ReplicatedStorage.NinjaDuel.Config)', 'games/ninja-duel/src/main.luau': 'return {}'}))

    def test_shared_cannot_hide_forbidden_import(self):
        self.assertTrue(self.audit({'games/ninja-duel/src/main.luau': 'require("../../../shared/bridge")', 'shared/bridge.luau': 'require("../plugins/forge/Engine")', 'plugins/forge/Engine.luau': 'return {}'}))

    def test_rojo_cannot_embed_other_workspace(self):
        self.assertTrue(self.audit({'plugins/forge/release.project.json': '{"tree":{"$path":"../../games/ninja-duel/src"}}', 'games/ninja-duel/src/main.luau': 'return {}'}))

    def test_assertion_about_excluded_motion_lab_is_not_an_import(self):
        self.assertFalse(self.audit({'games/ninja-duel/tests/check.py': "assert 'motion-lab' not in path"}))

    def test_pathlib_cannot_hide_motion_lab_runtime_dependency(self):
        self.assertTrue(self.audit({'games/ninja-duel/src/check.py': "path = ROOT / 'motion-lab' / 'code.luau'"}))

    def test_playground_can_import_plugin(self):
        self.assertFalse(self.audit({'plugins/forge-playground/default.project.json': '{"tree":{"$path":"../forge/Engine.luau"}}', 'plugins/forge/Engine.luau': 'return {}'}))


if __name__ == '__main__':
    unittest.main()
