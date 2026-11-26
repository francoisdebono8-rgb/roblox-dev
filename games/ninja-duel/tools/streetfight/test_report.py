#!/usr/bin/env python3
"""Tests of the passe 3 robots' reports (OUTILLEUR, 26/11): the street's blows
(tools/streetfight), the sound check (tools/sounds), the kits' bench (tools/kitbench).

    python3 tools/streetfight/test_report.py
"""
import importlib.util
import os
import sys

TOOLS = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def load(name, rel):
    spec = importlib.util.spec_from_file_location(name, os.path.join(TOOLS, rel))
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


street = load("street_report", "streetfight/report.py")
sounds = load("sounds_report", "sounds/report.py")
bench = load("bench_report", "kitbench/report.py")


def test_a_blow_that_starts_a_duel():
    rows = [
        {"t": 10.0, "kind": "land", "who": "P1", "move": "Light1", "result": "thug"},
        {"t": 10.2, "kind": "state", "who": "P1", "state": "Duel|nil|PlayerFighter|Duel_1", "at": [1, 3, 2]},
    ]
    started = street.duels_started(rows)
    assert len(started) == 1 and started[0][2] == 0.2


def test_a_blow_that_starts_nothing_is_not_blamed():
    # the Ōtsutsuki not open yet: the first blow says a word, the second (open) starts the final
    rows = [
        {"t": 10.0, "kind": "land", "who": "P1", "move": "Light1", "result": "boss"},
        {"t": 26.0, "kind": "land", "who": "P1", "move": "Light1", "result": "boss"},
        {"t": 26.4, "kind": "state", "who": "P1", "state": "Duel|nil|PlayerFighter|Duel_1"},
    ]
    started = street.duels_started(rows)
    assert len(started) == 1 and started[0][0]["t"] == 26.0


def test_quiet_blows_start_nothing():
    rows = [
        {"t": 1.0, "kind": "land", "who": "P1", "move": "Heavy", "result": "dummy"},
        {"t": 1.1, "kind": "state", "who": "P1", "state": "Duel|x"},
    ]
    assert street.duels_started(rows) == []


def test_street_report_names_what_was_hit():
    rows = [{"t": 0.0, "kind": "land", "who": "P1", "move": "Light1", "result": "player:accept"}]
    assert "riposte" in street.report(rows)


def test_sound_verdicts():
    ok = {"loaded": True, "length": 30, "measured": 30.1, "level": 40, "effective": 38}
    assert sounds.verdicts(ok) == []
    assert sounds.verdicts({"loaded": False}) == ["ne se charge pas"]
    long_ = dict(ok, measured=12)
    assert any("durée" in v for v in sounds.verdicts(long_))
    low = dict(ok, effective=20)
    assert any("sous son niveau" in v for v in sounds.verdicts(low))
    hit = {"loaded": True, "layer": "street", "effectivePeak": 40}
    assert any("couvert" in v for v in sounds.verdicts(hit, music_peak=70))
    assert sounds.verdicts(hit, music_peak=30) == []


def test_sound_licences_cover_the_bank():
    lic = sounds.licences()
    for key in ("81439427476164", "9112749254", "9117971636"):
        assert lic[key]["verified"] is True


def test_bench_borrowed_clips():
    clips = {"Sand": {"Heavy": {"clip": "Lion.Heavy", "own": False, "length": 0.76},
                      "Light1": {"clip": "Sand.Light1", "own": True, "length": 0.5}}}
    assert bench.borrowed(clips) == [("Sand", "Heavy", "Lion.Heavy")]
    assert "Gaara Heavy" in bench.report(clips)


def main():
    tests = [v for k, v in sorted(globals().items()) if k.startswith("test_")]
    for t in tests:
        t()
    print(f"Robots passe 3: {len(tests)} passed")
    return 0


if __name__ == "__main__":
    sys.exit(main())
