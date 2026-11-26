#!/usr/bin/env python3
"""The training robot's report (OUTILLEUR, passe commune 2, 26/11; DEC-054).

The robot (training_bot.luau, NDTrainingBot) plays each step of the practice of each kit
through the game's remote; the server's journal (tools/duelaudit/server_log.luau,
NDServerLog) keeps the game's own verdict of each step, its [NinjaDuelTutorial] lines.
Both JSON go into one file: {"robot": <NDTrainingBot.read()>, "server": <NDServerLog.read()>}.

    python3 tools/training/report.py MESURE.json              where each kit blocks (text)
    python3 tools/training/report.py MESURE.json --md OUT.md

The Studio code (Client, during a Play, after python3 tools/robots/inject.py training,
and on the Server python3 tools/robots/inject.py --server serverlog):
    python3 tools/training/report.py --start [KIT ...]        the practice of the kits (all 8 by default)
    python3 tools/training/report.py --read                   Client: the robot's JSON
"""
import json
import os
import re
import sys

import importlib.util

HERE = os.path.dirname(os.path.abspath(__file__))
_spec = importlib.util.spec_from_file_location("nd_duelaudit_report_for_training",
                                               os.path.join(os.path.dirname(HERE), "duelaudit", "report.py"))
_duel = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(_duel)
BETA, NAMES = _duel.BETA, _duel.NAMES

ROBOT = '(_G.NDTrainingBot or error("NDTrainingBot absent : python3 tools/robots/inject.py training (pendant le Play)"))'
LINE = re.compile(r"\[NinjaDuelTutorial\] (\w+) (\d+)/(\d+) (\w+): (PASS|STUCK|SKIP) ([\d.]+)s(.*)")


def plan(kits=None) -> list:
    kits = kits or BETA
    return [{"kit": k, "rival": BETA[(BETA.index(k) + 1) % len(BETA)] if k in BETA else "Mirage"} for k in kits]


def lua(v):
    if isinstance(v, dict):
        return "{" + ",".join(f"{k}={lua(x)}" for k, x in v.items()) + "}"
    if isinstance(v, list):
        return "{" + ",".join(lua(x) for x in v) + "}"
    return json.dumps(v)


def verdicts(server: dict) -> dict:
    """(fighter, index, id) -> the server's line, parsed."""
    out = {}
    for entry in (server or {}).get("tutorial") or []:
        m = LINE.search(entry.get("line", ""))
        if not m:
            continue
        fighter, index, total, sid, status, secs, rest = m.groups()
        out[(fighter, int(index), sid)] = {"status": status, "seconds": float(secs), "rest": rest.strip(), "total": int(total)}
    return out


def kit(k):
    return f"{NAMES.get(k, k)} ({k})"


def rows(data: dict) -> list:
    robot = (data.get("robot") or {}).get("results") or []
    seen = verdicts(data.get("server") or {})
    out = []
    for r in robot:
        steps = r.get("steps") or []
        for s in steps:
            v = seen.get((r.get("kit"), s.get("index"), s.get("id")))
            out.append({"kit": r.get("kit"), "index": s.get("index"), "total": s.get("total"), "id": s.get("id"),
                        "title": s.get("title"), "key": s.get("key"), "robot": s.get("outcome"), "seconds": s.get("seconds"),
                        "tries": s.get("tries"), "cues": s.get("cues") or [], "note": s.get("note") or s.get("error"),
                        "server": v and v["status"], "detail": v and v["rest"], "win": s.get("win")})
    return out


def report(data: dict) -> str:
    robot = (data.get("robot") or {}).get("results") or []
    all_rows = rows(data)
    lines = ["# Robot d'entraînement", ""]
    meta = data.get("meta") or {}
    if meta:
        lines += [f"Place : {meta.get('place')} · {meta.get('note', '')}", ""]
    lines.append("| kit | étapes | passées | bloquées | où il bloque |")
    lines.append("|---|---|---|---|---|")
    seen = verdicts(data.get("server") or {})
    for r in robot:
        k = r.get("kit")
        # the server's lines first: a step passed in a blink may never reach the robot's eye
        mine = sorted((idx, sid, v) for (f, idx, sid), v in seen.items() if f == k)
        if mine:
            passed = [m for m in mine if m[2]["status"] == "PASS"]
            blocked = [m for m in mine if m[2]["status"] in ("STUCK", "SKIP")]
            where = ", ".join(f"{idx} {sid}" for idx, sid, _ in blocked) or "—"
            lines.append(f"| {kit(k)} | {len(mine)} | {len(passed)} | {len(blocked)} | {where} |")
            continue
        rows_k = [x for x in all_rows if x["kit"] == k and x["id"] != "win"]
        blocked_r = [x for x in rows_k if x["robot"] == "abandonné"]
        where = ", ".join(f"{x['index']} {x['id']}" for x in blocked_r) or ("—" if rows_k else (r.get("error") or "pas commencé"))
        lines.append(f"| {kit(k)} | {len(rows_k)} | ? | {len(blocked_r)} | {where} |")
    lines.append("")
    lines.append("PASS : l'étape réussie (le serveur le dit). SKIP : le robot l'a sautée après 22 s, comme un joueur peut le faire. "
                 "STUCK : le serveur l'a passée seul au bout de son temps.")
    blocked = [x for x in all_rows if x["id"] != "win" and (x["server"] in ("STUCK", "SKIP") or (x["server"] is None and x["robot"] == "abandonné"))]
    if blocked:
        lines.append("\n## Les blocages, un par un\n")
        for x in blocked:
            cues = f" · l'écran a dit : {', '.join(x['cues'])}" if x["cues"] else ""
            detail = f" · serveur : {x['detail']}" if x.get("detail") else ""
            note = f" · {x['note']}" if x.get("note") else ""
            lines.append(f"- **{kit(x['kit'])}**, étape {x['index']}/{x['total']} `{x['id']}` « {x['title']} » "
                         f"(consigne : {x['key']}) : {x['server'] or x['robot']} après {x['seconds']} s, {x['tries']} essai(s){cues}{detail}{note}")
    frozen = [(f, idx, sid, v) for (f, idx, sid), v in sorted(verdicts(data.get("server") or {}).items()) if "FREEZES" in v["rest"]]
    if frozen:
        lines.append("\n## Passées, mais le corps a gelé\n")
        for f, idx, sid, v in frozen:
            lines.append(f"- **{kit(f)}**, étape {idx} `{sid}` : {v['status']} en {v['seconds']} s · serveur : {v['rest']}")
    wins = [x for x in all_rows if x["id"] == "win"]
    if wins:
        lines.append("\n## Le duel d'entraînement final\n")
        for x in wins:
            lines.append(f"- {kit(x['kit'])} : {x['robot']} ({x['seconds']} s)")
    errs = (data.get("server") or {}).get("errors") or []
    lines.append(f"\nErreurs rouges du serveur pendant l'entraînement : {len(errs)} texte(s).")
    for e in errs[:10]:
        lines.append(f"- ×{e.get('n')} : `{e.get('msg')}`")
    return "\n".join(lines)


def main(argv=None):
    args = argv if argv is not None else sys.argv[1:]
    if not args:
        print(__doc__)
        return 2
    if args[0] == "--start":
        print(f"return {ROBOT}.start({lua(plan(args[1:] or None))})")
        return 0
    if args[0] == "--read":
        print(f"return {ROBOT}.read()")
        return 0
    with open(args[0], encoding="utf-8") as f:
        data = json.load(f)
    text = report(data)
    if "--md" in args:
        with open(args[args.index("--md") + 1], "w", encoding="utf-8") as f:
            f.write(text + "\n")
    print(text)
    return 0


if __name__ == "__main__":
    sys.exit(main())
