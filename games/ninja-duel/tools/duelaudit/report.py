#!/usr/bin/env python3
"""The duel watcher's report (OUTILLEUR, passe commune 2, 26/11; DEC-054).

The watcher (duel_audit.luau, NDDuelAudit) and the server's journal (server_log.luau,
NDServerLog) are read in the Play with eval_client_runtime / eval_server_runtime; their
JSON goes into one file, {"audit": <NDDuelAudit.read()>, "server": <NDServerLog.read()>,
"meta": {...}}. This prints the table, per duel and per kind of incoherence.

    python3 tools/duelaudit/report.py MESURE.json              the table (text)
    python3 tools/duelaudit/report.py MESURE.json --md OUT.md  the same, Markdown

The Studio code (Client, during a Play, after python3 tools/robots/inject.py duel audit):
    python3 tools/duelaudit/report.py --plan               the 8 kits, each against another of the 8
    python3 tools/duelaudit/report.py --start              Client: the watcher, then the duels
    python3 tools/duelaudit/report.py --read               Client: the watcher's JSON
    python3 tools/duelaudit/report.py --show RUN I [back|seen]  Client: the frame of an incident
"""
import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(os.path.dirname(HERE), "duelbot"))
import studio_code as duel  # noqa: E402

BETA = ["Lion", "Legion", "Sand", "Leaf", "GentleFist", "Mirage", "Copycat", "Flashstep"]
NAMES = {"Lion": "Sasuke", "Legion": "Naruto", "Sand": "Gaara", "Leaf": "Lee", "GentleFist": "Neji",
         "Mirage": "Itachi", "Copycat": "Kakashi", "Flashstep": "Minato"}
# what each kind means, in the order of the table
KINDS = [
    ("bloque", "corps bloqué", "le stick tenu, le corps libre, il ne bouge pas (1 s)"),
    ("fige", "état figé", "un corps tenu 6 s dans un état autre que libre"),
    ("superposes", "corps l'un dans l'autre", "les deux racines à moins de 1,4 stud, hors prise"),
    ("traverse", "coup qui traverse", "une main, un pied, un avant-bras ou un tibia à plus de 0,35 stud dans le torse, le bassin ou la tête de l'autre"),
    ("de_loin", "coup de loin", "le coup compte alors qu'aucun membre n'est à moins de 2,5 studs du corps"),
    ("dans_le_sol", "dans le sol", "le point le plus bas du corps à plus de 0,7 stud sous le sol"),
    ("sous_le_sol", "sous le sol", "la racine 2,5 studs sous sa hauteur de départ"),
    ("camera_mur", "caméra dans un mur", "la caméra dans une pièce dessinée"),
    ("camera_objet", "caméra dans un objet", "la caméra dans la boîte (réduite à 80 %) d'un maillage du décor"),
    ("camera_terrain", "caméra dans le terrain", "la caméra dans le terrain"),
    ("cache", "combattant caché", "la tête et la racine cachées par le décor 0,5 s"),
    ("erreur", "erreur en rouge", "une ligne rouge de la sortie du client"),
]
INFO = [("pousse_rival", "pousse l'adversaire"), ("pousse_mur", "pousse un mur")]


def plan(seed: int = 1, level: str = "normal") -> list:
    """The 8 kits, each against the next one of the 8 (every kit is a rival once)."""
    return [{"mode": "duel", "kit": k, "rival": BETA[(i + 1) % len(BETA)], "level": level, "seed": seed,
             "profile": "joueur", "limit": 420} for i, k in enumerate(BETA)]


AUDIT = '(_G.NDDuelAudit or error("NDDuelAudit absent : python3 tools/robots/inject.py duel audit (pendant le Play)"))'


def start_code(runs: list) -> str:
    return f"local a={AUDIT}.start() return a..\" | \"..{duel.ROBOT}.start({duel.lua_value(runs)})"


def kit(k):
    return f"{NAMES.get(k, k)} ({k})" if k else "?"


def table(data: dict) -> list:
    audit = data.get("audit") or {}
    runs = audit.get("runs") or []
    lines = []
    head = ["duel", "s", "manches"] + [label for _, label, _ in KINDS]
    lines.append("| " + " | ".join(head) + " |")
    lines.append("|" + "---|" * len(head))
    total = {k: 0 for k, _, _ in KINDS}
    for r in runs:
        counts = r.get("counts") or {}
        row = [f"{kit(r.get('kit'))} contre {kit(r.get('rival'))}" + (" (avatar)" if r.get("avatar") else ""),
               f"{r.get('seconds', 0):.0f}", str(r.get("rounds") or 0)]
        for k, _, _ in KINDS:
            n = counts.get(k, 0)
            total[k] += n
            row.append(str(n) if n else "·")
        lines.append("| " + " | ".join(row) + " |")
    lines.append("| **total** | | | " + " | ".join(f"**{total[k]}**" if total[k] else "·" for k, _, _ in KINDS) + " |")
    return lines


def details(data: dict) -> list:
    audit = data.get("audit") or {}
    out = []
    for r in audit.get("runs") or []:
        inc = r.get("incidents") or []
        real = [x for x in inc if x.get("kind") not in dict(INFO)]
        if not real:
            continue
        out.append(f"\n**{kit(r.get('kit'))} contre {kit(r.get('rival'))}** (run {r.get('index')})")
        for x in real:
            img = " · image" if x.get("framed") else ""
            out.append(f"- {x.get('t', 0):.1f} s, manche {x.get('round')}, {x.get('who')} : **{x.get('kind')}** — {x.get('detail')}{img}")
    return out


def server_lines(data: dict) -> list:
    server = data.get("server") or {}
    out = []
    errs = server.get("errors") or []
    out.append(f"\nErreurs rouges du serveur : {len(errs)} texte(s) différent(s).")
    for e in errs[:12]:
        out.append(f"- ×{e.get('n')} : `{e.get('msg')}`")
    cerrs = (data.get("audit") or {}).get("errors") or []
    out.append(f"\nErreurs rouges du client : {len(cerrs)} texte(s) différent(s).")
    for e in cerrs[:12]:
        out.append(f"- ×{e.get('n')} ({e.get('kit') or e.get('phase')}) : `{e.get('msg')}`")
    return out


def report(data: dict) -> str:
    meta = data.get("meta") or {}
    lines = [f"# Robot de duel — {meta.get('place', '?')}", ""]
    if meta:
        lines.append(f"Place : {meta.get('place')} · {meta.get('note', '')}")
        lines.append("")
    lines += table(data)
    lines.append("")
    for k, label, what in KINDS:
        lines.append(f"- *{label}* : {what}.")
    info = {}
    for r in (data.get("audit") or {}).get("runs") or []:
        for k, _ in INFO:
            info[k] = info.get(k, 0) + (r.get("counts") or {}).get(k, 0)
    lines.append(f"- Pas des incohérences : le stick a poussé l'adversaire {info.get('pousse_rival', 0)} fois, un mur {info.get('pousse_mur', 0)} fois.")
    lines += details(data)
    lines += server_lines(data)
    return "\n".join(lines)


def main(argv=None):
    args = argv if argv is not None else sys.argv[1:]
    if not args:
        print(__doc__)
        return 2
    if args[0] == "--plan":
        print(json.dumps(plan(), indent=1))
        return 0
    if args[0] == "--start":
        print(start_code(plan(int(args[1]) if len(args) > 1 else 1)))
        return 0
    if args[0] == "--read":
        print(f"return {AUDIT}.read()")
        return 0
    if args[0] == "--show":
        view = f'"{args[3]}"' if len(args) > 3 else "nil"
        print(f"return {AUDIT}.show({int(args[1])},{int(args[2])},{view})")
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
