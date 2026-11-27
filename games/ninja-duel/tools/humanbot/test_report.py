#!/usr/bin/env python3
"""Tests of the human robot (OUTILLEUR, 27/11): its hands (chaos.py) and its report.

    python3 tools/humanbot/test_report.py
"""
import importlib.util
import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))


def load(name, rel):
    spec = importlib.util.spec_from_file_location(name, os.path.join(HERE, rel))
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


chaos = load("humanbot_chaos", "chaos.py")
report = load("humanbot_report", "report.py")

SCAN = {"buttons": [
    {"label": "TOP @587,105", "x": 587, "y": 105, "menu": "MY NINJA"},
    {"label": "WEAR IT @741,164", "x": 741, "y": 164, "menu": "MY NINJA"},
    {"label": "BUY 400 R$ @900,300", "x": 900, "y": 300, "menu": "SHOP"},
    {"label": "F4 @40,-37", "x": 40, "y": -37, "menu": None, "onScreen": True},
    {"label": "FAR @741,900", "x": 741, "y": 900, "menu": "MY NINJA", "onScreen": False},
]}


def test_a_seed_comes_again():
    assert chaos.plan("frenzy", seed=3, scan=SCAN, n=8) == chaos.plan("frenzy", seed=3, scan=SCAN, n=8)
    assert chaos.plan("wander", seed=3, n=8) != chaos.plan("wander", seed=4, n=8)


def test_the_hands_click_where_the_button_is_never_robux_nor_off_screen():
    acts = chaos.plan("everything", seed=1, scan=SCAN, n=10)
    points = {(a["x"], a["y"]) for a in acts if a["action"] == "moveTo"}
    assert (900, 300) not in points          # a Robux purchase would wait for a human
    assert (741, 900) not in points          # off the screen: a human cannot reach it
    assert all("instance_path" not in a for a in acts)   # the HUD's frames are all "Frame"
    assert points <= {(587, 105), (741, 164), (40, -37)}


def test_a_frenzy_double_clicks_sometimes():
    acts = chaos.plan("frenzy", seed=11, scan=SCAN, n=20)
    moves = [(a["x"], a["y"]) for a in acts if a["action"] == "moveTo"]
    assert any(a == b for a, b in zip(moves, moves[1:]))


def test_the_walk_releases_every_key_it_holds():
    acts = chaos.plan("wander", seed=12, n=40)
    held = set()
    for a in acts:
        if a["action"] == "keyDown":
            held.add(a["key_code"])
        elif a["action"] == "keyUp":
            held.discard(a["key_code"])
    assert held == set()


def test_the_run_across_the_village_lets_go_of_every_key():
    acts = chaos.plan("roam", seed=21, n=40)
    held = set()
    for a in acts:
        if a["action"] == "keyDown":
            held.add(a["key_code"])
        elif a["action"] == "keyUp":
            held.discard(a["key_code"])
    assert held == set()
    assert sum(a.get("wait_time_ms", 0) for a in acts) > 20000   # a real run, not a twitch


def test_waits_are_a_humans():
    waits = [a["wait_time_ms"] for a in chaos.plan("mash", seed=2, n=60) if a["action"] == "wait"]
    assert min(waits) >= 40 and len(set(waits)) > 10


def test_escape_is_left_out():
    keys = {a.get("key_code") for a in chaos.plan("menukeys", seed=5, n=60)}
    assert "Escape" not in keys and "Tab" in keys


def test_false_positives_are_dropped():
    bugs = [
        {"kind": "hors écran", "key": "SOON", "detail": {"path": "X.ScrollingFrame.Frame.TextButton"}},
        {"kind": "hors écran", "key": "TOPKNOT", "detail": {"path": "X.Creator.Frame.Frame.TextButton"}},
        {"kind": "tenue fausse", "key": "feet", "detail": {"equipped": "FeetNone"}},
        {"kind": "tenue fausse", "key": "hairColor", "detail": {"equipped": "HairNight"}},
        {"kind": "tenue fausse", "key": "top", "detail": {"equipped": "TopHighCollar"}},
    ]
    kept = {(k, b["key"]) for k, group in report.grouped(bugs) for b in group}
    assert kept == {("hors écran", "TOPKNOT"), ("tenue fausse", "top")}


def test_the_report_orders_what_matters():
    bugs = [{"kind": "à-coup", "key": "1.2", "steps": []},
            {"kind": "menus ensemble", "key": "A + B", "steps": []},
            {"kind": "erreur rouge", "key": "x", "steps": []}]
    kinds = [k for k, _ in report.grouped(bugs)]
    assert kinds == ["erreur rouge", "menus ensemble", "à-coup"]


def test_the_steps_read_like_a_player():
    text = report.steps_text([{"k": "MouseButton1", "on": "RANKS"}, {"k": "act", "on": "RANKS"}, {"k": "Tab"}])
    assert text == "clic RANKS · → RANKS répond · Tab"


def test_the_report_of_the_27th():
    path = os.path.join(HERE, "mesures", "2026-11-27_ac418a18", "journal.json")
    with open(path, encoding="utf-8") as f:
        mesure = json.load(f)
    text = report.report(mesure)
    assert "menus ensemble" in text and "SOON" not in text and "FeetNone" not in text
    assert report.hitches(mesure["client"]["hitches"])["felt"] == 16


def test_the_street_blows_are_named():
    mesure = {"client": {"fists": 10, "fistsLive": 9, "bugs": [], "hitches": []},
              "server": {"rows": [], "street": {"lands": {"nil": 7, "thug": 1}}}}
    text = report.report(mesure)
    assert "rien (dans le vide) 7" in text and "un voyou 1" in text and "Coups de rue" in text


def main():
    tests = [v for k, v in sorted(globals().items()) if k.startswith("test_")]
    for t in tests:
        t()
    print(f"Robot humain: {len(tests)} passed")
    return 0


if __name__ == "__main__":
    sys.exit(main())
