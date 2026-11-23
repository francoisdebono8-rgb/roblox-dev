#!/usr/bin/env python3
"""Tests de la place commune (OUTILLEUR, 20/11) : un faux dépôt git local, un
faux build.py, un faux dossier NinjaDuel. Ni GitHub, ni macOS, ni Studio.

    python3 tools/mac/test_place_commune.py
"""
import json
import os
import subprocess
import sys
import tempfile
import unittest

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import place_commune as P  # noqa: E402

FAKE_BUILD = r'''
import argparse, hashlib, json, os, pathlib, sys
ap = argparse.ArgumentParser()
for f in ("--qa", "--debug", "--capture"): ap.add_argument(f, action="store_true")
a = ap.parse_args()
root = pathlib.Path(__file__).parent
if (root / "CASSE").exists(): sys.exit("build cassé")
game = (root / "game.txt").read_text()
key = "NinjaDuel-QA" if a.qa else "NinjaDuel-Capture" if a.capture else "NinjaDuel-Debug" if a.debug else "NinjaDuel"
body = (game + "|" + key).encode()
(root / "dist").mkdir(exist_ok=True)
(root / "dist" / (key + ".rbxlx")).write_bytes(body)
rt = hashlib.sha256(game.encode()).hexdigest()
(root / "dist" / (key + ".json")).write_text(json.dumps({"sha256": hashlib.sha256(body).hexdigest(),
    "runtimeFingerprint": rt, "buildFingerprint": hashlib.sha256(body).hexdigest(), "profile": key,
    "sourceCommit": "x" * 40}))
'''


def sh(*args, cwd):
    subprocess.run(args, cwd=cwd, check=True, capture_output=True)


class Clock:
    def __init__(self):
        self.t = 1_000_000.0

    def __call__(self):
        return self.t


class PlaceCommune(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        root = self.tmp.name
        self.src = os.path.join(root, "depot")
        game = os.path.join(self.src, "games", "ninja-duel")
        os.makedirs(game)
        with open(os.path.join(game, "build.py"), "w") as f:
            f.write(FAKE_BUILD)
        self.game = game
        self.write("game.txt", "v1")
        sh("git", "init", "-q", "-b", P.BRANCH, cwd=self.src)
        sh("git", "-c", "user.email=t@t", "-c", "user.name=t", "add", "-A", cwd=self.src)
        sh("git", "-c", "user.email=t@t", "-c", "user.name=t", "commit", "-qm", "premier lot", cwd=self.src)
        self.nd = os.path.join(root, "NinjaDuel")
        os.makedirs(os.path.join(self.nd, "PLACES"))
        self.notes = []
        self.clock = Clock()
        self.place = P.Place(self.nd, repo=self.src, stable=180, python=sys.executable,
                             notify=lambda t, x: self.notes.append((t, x)), clock=self.clock)

    def tearDown(self):
        self.tmp.cleanup()

    def write(self, name, text):
        with open(os.path.join(self.game, name), "w") as f:
            f.write(text)

    def commit(self, msg, **files):
        for name, text in files.items():
            self.write(name, text)
        sh("git", "-c", "user.email=t@t", "-c", "user.name=t", "add", "-A", cwd=self.src)
        sh("git", "-c", "user.email=t@t", "-c", "user.name=t", "commit", "-qm", msg, cwd=self.src)

    def placed(self, name="NinjaDuel"):
        with open(os.path.join(self.nd, "PLACES", name + ".rbxlx")) as f:
            return f.read()

    def version(self):
        with open(os.path.join(self.nd, "PLACES", "VERSION.md"), encoding="utf-8") as f:
            return f.read()

    def test_a_lot_is_built_once_it_has_stopped_moving_then_placed(self):
        self.assertIn("attend la fin du lot", self.place.tick())
        self.assertFalse(os.path.exists(os.path.join(self.nd, "PLACES", "NinjaDuel.rbxlx")))
        self.clock.t += 200
        line = self.place.tick()
        self.assertIn("posées dans PLACES", line)
        # (DEC-052) one game, one place: the game with its tools
        self.assertEqual(sorted(f for f in os.listdir(os.path.join(self.nd, "PLACES")) if f.endswith(".rbxlx")), ["NinjaDuel.rbxlx"])
        self.assertEqual(self.placed(), "v1|NinjaDuel-Capture")
        self.assertIn("premier lot", self.version())
        self.assertEqual(self.notes[-1][0], "Places Ninja Duel à jour")
        # nothing new: nothing happens
        self.clock.t += 120
        self.assertIn("à jour", self.place.tick())

    def test_a_push_during_the_wait_restarts_it(self):
        self.place.tick()
        self.clock.t += 150
        self.commit("deuxième commit du lot", **{"game.txt": "v2"})
        self.assertIn("attend", self.place.tick())
        self.clock.t += 100
        self.assertIn("attend", self.place.tick())
        self.clock.t += 100
        self.assertIn("posées", self.place.tick())
        self.assertEqual(self.placed(), "v2|NinjaDuel-Capture")

    def test_an_open_place_keeps_them_ready_until_studio_lets_go(self):
        self.place.tick(); self.clock.t += 200; self.place.tick()
        self.commit("lot 2", **{"game.txt": "v2"})
        self.place.tick(); self.clock.t += 200
        lock = os.path.join(self.nd, "PLACES", "NinjaDuel.rbxlx.lock")
        open(lock, "w").close()
        line = self.place.tick()
        self.assertIn("prêtes dans PLACES/_prochaine", line)
        self.assertEqual(self.placed(), "v1|NinjaDuel-Capture", "an open place is never replaced")
        self.assertTrue(os.path.exists(os.path.join(self.nd, "PLACES", "_prochaine", "NinjaDuel.rbxlx")))
        waiting = [n for n in self.notes if n[0] == "Place commune prête"]
        self.assertEqual(len(waiting), 1)
        self.clock.t += 120
        self.place.tick()
        self.assertEqual(len([n for n in self.notes if n[0] == "Place commune prête"]), 1, "told once")
        os.rename(lock, lock + ".parti")
        self.clock.t += 120
        self.assertIn("posées", self.place.tick())
        self.assertEqual(self.placed(), "v2|NinjaDuel-Capture")
        self.assertIsNone(self.place.staged())

    def test_a_place_changed_in_studio_is_put_aside_not_overwritten(self):
        self.place.tick(); self.clock.t += 200; self.place.tick()
        with open(os.path.join(self.nd, "PLACES", "NinjaDuel.rbxlx"), "w") as f:
            f.write("modifiée à la main")
        self.commit("lot 2", **{"game.txt": "v2"})
        self.place.tick(); self.clock.t += 200
        line = self.place.tick()
        self.assertIn("NinjaDuel", line)
        aside = os.listdir(os.path.join(self.nd, "_maintenance", "places-modifiees-dans-studio"))
        self.assertEqual(len(aside), 1)
        self.assertTrue(aside[0].endswith("_NinjaDuel.rbxlx"))

    def test_a_commit_that_does_not_change_the_game_only_moves_version(self):
        self.place.tick(); self.clock.t += 200; self.place.tick()
        before = os.stat(os.path.join(self.nd, "PLACES", "NinjaDuel.rbxlx")).st_ino
        self.commit("docs seulement", **{"NOTES.md": "rien pour le jeu"})
        self.place.tick(); self.clock.t += 200
        self.assertIn("identiques", self.place.tick())
        self.assertEqual(os.stat(os.path.join(self.nd, "PLACES", "NinjaDuel.rbxlx")).st_ino, before)
        self.assertIn("docs seulement", self.version())
        self.assertIsNone(self.place.staged())

    def test_a_broken_build_is_told_once_and_places_stay(self):
        self.place.tick(); self.clock.t += 200; self.place.tick()
        self.commit("casse", **{"game.txt": "v3", "CASSE": "1"})
        self.place.tick(); self.clock.t += 200
        self.assertIn("échec", self.place.tick())
        self.clock.t += 120
        self.place.tick()
        broken = [n for n in self.notes if "impossible" in n[0]]
        self.assertEqual(len(broken), 1)
        self.assertEqual(self.placed(), "v1|NinjaDuel-Capture")

    def test_the_agent_runs_the_script_it_installed(self):
        text = P.plist("/x/_outils/place_commune.py", "/usr/bin/python3", "/x")
        self.assertIn("<string>--une-fois</string>", text)
        self.assertIn(f"<integer>{P.INTERVAL}</integer>", text)
        self.assertIn(P.LABEL, text)


if __name__ == "__main__":
    result = unittest.main(exit=False, verbosity=1).result
    print(f"PlaceCommune: {result.testsRun - len(result.failures) - len(result.errors)} passed")
    sys.exit(0 if result.wasSuccessful() else 1)
