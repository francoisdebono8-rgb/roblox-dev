#!/usr/bin/env python3
"""The street robot's report (OUTILLEUR, passe commune 3, 26/11; DEC-055).

    python3 tools/streetfight/report.py JOURNAL.json [--md RAPPORT.md]
    python3 tools/streetfight/report.py --start           Serveur : _G.NDStreetLog.start()
    python3 tools/streetfight/report.py --read            Serveur : le journal (JSON)

JOURNAL.json is _G.NDStreetLog.read() (tools/streetfight/street_log.luau, server): what each
street blow met, each challenge between two players, each player's session as it changed,
the props broken then put back.
"""
import json
import sys

LOG_LUA = '(_G.NDStreetLog or error("NDStreetLog absent : python3 tools/robots/inject.py --server streetlog (pendant le Play)"))'
WHAT = {
    "dummy": "le mannequin",
    "broke": "un objet cassé",
    "world": "le décor",
    "thug": "un voyou : son combat",
    "challenger": "le prodige qui attend : son défi",
    "boss": "l'Ōtsutsuki",
    "bandit": "le bandit de la forêt",
    "body": "un corps (sans suite)",
    "nil": "rien (trop loin)",
    "player:challenge": "un joueur : défi",
    "player:accept": "un joueur : riposte, le duel",
    "player:wait": "un joueur : trop tôt (10 s entre deux défis)",
    "player:busy": "un joueur occupé",
}


def lands(rows: list) -> list:
    return [r for r in rows if r.get("kind") == "land"]


QUIET = ("dummy", "broke", "world", "nil", "body", "player:challenge", "player:wait", "player:busy")
# A duel that starts more than this long after a blow was not started by it.
STARTS_WITHIN = 2.0


def duels_started(rows: list) -> list:
    """The duels a blow started: (the blow, the first duel state of its player, seconds).
    A blow that started nothing (the Ōtsutsuki not open yet) has no duel."""
    out = []
    for i, s in enumerate(rows):
        if s.get("kind") != "state" or not str(s.get("state", "")).startswith("Duel"):
            continue
        before = [r for r in rows[:i] if r.get("kind") == "land" and r.get("who") == s.get("who")
                  and r.get("result") not in QUIET and s["t"] - r["t"] <= STARTS_WITHIN]
        if before:
            r = before[-1]
            out.append((r, s, round(s["t"] - r["t"], 2)))
    return out


def report(rows: list) -> str:
    lines = ["# Les coups de rue", "", "| heure | qui | coup | ce qu'il touche |", "|---|---|---|---|"]
    t0 = rows[0]["t"] if rows else 0
    for r in lands(rows):
        lines.append(f"| +{r['t'] - t0:.1f} s | {r.get('who')} | {r.get('move')} | {WHAT.get(r.get('result'), r.get('result'))} |")
    started = duels_started(rows)
    if started:
        lines += ["", "| le coup | le duel commence | après |", "|---|---|---|"]
        for r, s, dt in started:
            at = s.get("at") or []
            lines.append(f"| {WHAT.get(r.get('result'), r.get('result'))} | {str(s.get('state')).replace('|', ' · ')} à {tuple(at)} | {dt} s |")
    worlds = [r for r in rows if r.get("kind") == "world"]
    if worlds:
        lines += ["", "Les objets cassés : " + " ; ".join(
            f"{'cassé' if w.get('broken') else 'remis'} à +{w['t'] - t0:.1f} s (calme {w.get('calm')} s)" for w in worlds)]
    return "\n".join(lines)


def main(argv=None):
    args = argv if argv is not None else sys.argv[1:]
    if not args:
        print(__doc__)
        return 2
    if args[0] == "--start":
        print(f"return {LOG_LUA}.start()")
        return 0
    if args[0] == "--read":
        print(f"return {LOG_LUA}.read()")
        return 0
    with open(args[0], encoding="utf-8") as f:
        rows = json.load(f)
    text = report(rows)
    if "--md" in args:
        with open(args[args.index("--md") + 1], "w", encoding="utf-8") as f:
            f.write(text + "\n")
    print(text)
    return 0


if __name__ == "__main__":
    sys.exit(main())
