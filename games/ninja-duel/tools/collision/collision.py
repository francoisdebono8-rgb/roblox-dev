#!/usr/bin/env python3
"""The collision robot: what the player goes through in Konoha (OUTILLEUR, passe commune 1).

In a Play of the game's place (DEC-052: PLACES/NinjaDuel.rbxlx, no copy), the robot is
injected in the Client first (python3 tools/robots/inject.py collision). Then, Client, in Konoha:

    python3 tools/collision/collision.py --survey [max] [only]   the drawing against the solids, every unit (seconds)
    python3 tools/collision/collision.py --walk [max] [only]     the body against each façade, then on each roof (~5 s a building)
    python3 tools/collision/collision.py --state                 where it is
    python3 tools/collision/collision.py --by-model              the survey, one line a model (save it as …_par_modele.txt)
    python3 tools/collision/collision.py --walk-lines [from] [count]   the walk, one line a building (save it as …_marche.txt)
    python3 tools/collision/collision.py --rays [max] [only]     (24/11) the buildings by rays, against whatever collides there
    python3 tools/collision/collision.py --rays-lines [from] [count]   the rays, one line a building (save it as …_rayons.txt)

Then, here:

    python3 tools/collision/collision.py --report PAR_MODELE.txt [MARCHE.txt]
           [--avant OLD_PAR_MODELE.txt [OLD_MARCHE.txt]] [--md R.md] [--html R.html]
    python3 tools/collision/collision.py --compare AVANT_RAYONS.txt APRES_RAYONS.txt
           [--marche AVANT_MARCHE.txt APRES_MARCHE.txt] [--labels "avant" "après"] [--md R.md] [--html R.html]

The rays (Bot.rays) measure what the body meets whatever makes the place solid (the
server's parts, or since bba7af8c the drawn pieces themselves): the same measure before
and after a pass. --compare puts the two side by side, by group and by model.
"""
import html
import re
import sys

REQ = '(_G.NDCollisionBot or error("NDCollisionBot absent : python3 tools/robots/inject.py collision (pendant le Play)"))'
GAP = 1.5          # the robot's Bot.GAP: farther than this from a solid, the body feels it
INTO = .5          # the body's front this deep in the drawn façade: he walks into the wall
SINK = .75         # his feet this far under the drawn roof: he stands in the roof

# The groups of the report: the houses and buildings of the plan first (what François
# walks against), then the cliff, the trees, the rest.
CLIFF = ("HokageCliff", "FacesTerrace", "HeadSlot")
TREES = ("TreeA", "TreeB", "TreeC", "academy_tree")


def group(model: str) -> str:
    if model.startswith(CLIFF):
        return "falaise"
    if model in TREES:
        return "arbres"
    if model[:1].islower():
        return "bâtiments"
    return "objets et murs"


def snippet(args):
    cmd = args[0]
    if cmd in ("--survey", "--walk", "--rays"):
        opts = []
        if len(args) > 1 and args[1] not in ("", "0"):
            opts.append(f"max={int(args[1])}")
        if len(args) > 2:
            opts.append(f'only="{args[2]}"')
        return f"return {REQ}.{cmd[2:]}({{{','.join(opts)}}})"
    if cmd == "--state":
        return f"return {REQ}.result.state"
    if cmd == "--by-model":
        return f"return {REQ}.byModel()"
    if cmd == "--walk-lines":
        frm = int(args[1]) if len(args) > 1 else 1
        count = int(args[2]) if len(args) > 2 else 400
        return f"return {REQ}.walkLines({frm},{count})"
    if cmd == "--rays-lines":
        frm = int(args[1]) if len(args) > 1 else 1
        count = int(args[2]) if len(args) > 2 else 400
        return f"return {REQ}.raysLines({frm},{count})"
    return None


def num(x):
    try:
        return float(x)
    except (TypeError, ValueError):
        return None


def table_lines(path):
    """The '|' lines of a file, after its header line (the one naming the columns)."""
    if not path:
        return []
    with open(path, encoding="utf-8") as f:
        lines = [l.rstrip("\n") for l in f if l.strip() and not l.startswith("#")]
    head = None
    out = []
    for l in lines:
        cells = l.split("|")
        if head is None:
            head = cells
            continue
        out.append(dict(zip(head, cells)))
    return out


def survey(path):
    groups = {}
    models = []
    for r in table_lines(path):
        m = {"model": r["model"], "n": int(r["n"]), "group": group(r["model"]), "pieces": r.get("pieces", "")}
        for k in ("facadeArea", "facadeCross", "facadeMax", "roofArea", "roofCross", "roofMax", "ghost", "faces", "ghostMax"):
            m[k] = num(r.get(k)) or 0.0
        models.append(m)
        g = groups.setdefault(m["group"], {"n": 0, "facadeArea": 0.0, "facadeCross": 0.0, "roofArea": 0.0, "roofCross": 0.0, "ghost": 0.0, "faces": 0.0})
        for k in g:
            g[k] += m[k] if k != "n" else m["n"]
    return {"models": models, "groups": groups}


def walk(path):
    rows = []
    for r in table_lines(path):
        rows.append({"u": r["u"], "model": r["model"], "at": r["x,z"],
                     "drawn": num(r["facadeDrawn"]), "solid": num(r["facadeSolid"]), "went": num(r["went"]), "into": num(r["into"]),
                     "skip": r.get("facadeSkip", ""), "roofDrawn": num(r["roofDrawn"]), "roofSolid": num(r["roofSolid"]),
                     "feet": num(r["feet"]), "sink": num(r["sink"]), "roofSkip": r.get("roofSkip", "")})
    # the body that did not move at all: a measure that failed (the client held by a long call)
    still = [r for r in rows if r["went"] is not None and abs(r["went"]) < .2]
    fac = [r for r in rows if r["into"] is not None and r not in still]
    roofs = [r for r in rows if r["sink"] is not None]
    return {"rows": rows, "walked": len(fac), "dropped": len(roofs), "still": still,
            "into": sorted([r for r in fac if r["into"] > INTO], key=lambda r: -r["into"]),
            "through": [r for r in fac if r["solid"] is None and r["into"] > INTO],
            "sink": sorted([r for r in roofs if r["sink"] > SINK], key=lambda r: -r["sink"]),
            "fell": [r for r in roofs if r["sink"] > 6],
            "sinks": sorted(r["sink"] for r in roofs)}


RAY_KEYS = ("solids", "meshes", "fN", "fThrough", "fGhost", "fMaxThrough", "fMaxGhost", "rN", "rSink", "rFloat", "rMaxSink", "rMaxFloat")


def rays(path):
    """The rays, one line a building -> by group and by model."""
    rows, groups, models = [], {}, {}
    for r in table_lines(path):
        row = {"u": r["u"], "model": r["model"], "at": r["x,z"], "skip": r.get("skip", "")}
        for k in RAY_KEYS:
            row[k] = num(r.get(k))
        rows.append(row)
        if row["fN"] is None:
            continue
        for key, bag in ((group(row["model"]), groups), (row["model"], models)):
            b = bag.setdefault(key, {"n": 0, "fN": 0, "fThrough": 0, "fGhost": 0, "rN": 0, "rSink": 0, "rFloat": 0,
                                     "fMaxThrough": 0.0, "rMaxSink": 0.0, "noSolid": 0, "meshSolid": 0})
            b["n"] += 1
            for k in ("fN", "fThrough", "fGhost", "rN", "rSink", "rFloat"):
                b[k] += int(row[k] or 0)
            b["fMaxThrough"] = max(b["fMaxThrough"], row["fMaxThrough"] or 0)
            b["rMaxSink"] = max(b["rMaxSink"], row["rMaxSink"] or 0)
            b["noSolid"] += 1 if not row["solids"] else 0
            b["meshSolid"] += 1 if (row["meshes"] or 0) > 0 else 0
    return {"rows": rows, "groups": groups, "models": models}


def compare_md(old_r, new_r, old_w=None, new_w=None, labels=("avant", "après")):
    a, b = labels
    L = ["# Collisions de Konoha : " + a + " et " + b, "",
         "Les mêmes rayons dans les deux places, quel que soit ce qui rend la place solide. Pour chaque bâtiment, "
         f"des rayons de tout autour, à hauteur du corps (1, 3, 5 et 8 studs), vers son milieu, et des rayons d'en haut sur son emprise. "
         f"Un rayon **traverse** quand le dessin vient d'abord et le solide plus de {GAP} stud derrière (ou pas du tout) : "
         f"le corps entre dans ce qu'il voit. Il est **fantôme** quand le solide vient plus de {GAP} stud avant le dessin : un mur invisible. "
         f"Sur les toits, même seuil : les pieds dans le toit, ou posés au-dessus du dessin.", ""]
    L += [f"| Groupe | Bâtiments {a} / {b} | Façades traversées {a} | {b} | Murs invisibles {a} | {b} | Toits où l'on s'enfonce {a} | {b} | Toits invisibles {a} | {b} |",
          "|---|---|---|---|---|---|---|---|---|---|"]
    for name in ("bâtiments", "falaise", "objets et murs", "arbres"):
        o, n = old_r["groups"].get(name), new_r["groups"].get(name)
        if not o and not n:
            continue
        o = o or {"n": 0, "fN": 0, "fThrough": 0, "fGhost": 0, "rN": 0, "rSink": 0, "rFloat": 0}
        n = n or {"n": 0, "fN": 0, "fThrough": 0, "fGhost": 0, "rN": 0, "rSink": 0, "rFloat": 0}
        L.append(f"| {name} | {o['n']} / {n['n']} | {pct(o['fThrough'], o['fN'])} | **{pct(n['fThrough'], n['fN'])}** | "
                 f"{pct(o['fGhost'], o['fN'])} | **{pct(n['fGhost'], n['fN'])}** | {pct(o['rSink'], o['rN'])} | **{pct(n['rSink'], n['rN'])}** | "
                 f"{pct(o['rFloat'], o['rN'])} | **{pct(n['rFloat'], n['rN'])}** |")
    L += ["", "## Par modèle", "",
          f"| Modèle | Bâtiments {a} / {b} | Façades traversées {a} | {b} | au pire ({b}) | Toits où l'on s'enfonce {a} | {b} | au pire ({b}) | Murs invisibles {b} |",
          "|---|---|---|---|---|---|---|---|---|"]
    names = sorted(set(old_r["models"]) | set(new_r["models"]),
                   key=lambda m: -((new_r["models"].get(m) or {}).get("fThrough", 0) + (new_r["models"].get(m) or {}).get("rSink", 0)))
    for m in names:
        o, n = old_r["models"].get(m), new_r["models"].get(m)
        if (n and group(m) not in ("bâtiments", "falaise")) or (not n and group(m) not in ("bâtiments", "falaise")):
            continue
        cell = lambda x, k, t: pct(x[k], x[t]) if x else "—"
        L.append(f"| {m} | {o['n'] if o else 0} / {n['n'] if n else 0} | {cell(o, 'fThrough', 'fN')} | **{cell(n, 'fThrough', 'fN')}** | "
                 f"{n['fMaxThrough']:.1f} | {cell(o, 'rSink', 'rN')} | **{cell(n, 'rSink', 'rN')}** | {n['rMaxSink']:.1f} | {cell(n, 'fGhost', 'fN')} |"
                 if n else f"| {m} | {o['n']} / 0 | {cell(o, 'fThrough', 'fN')} | — | — | {cell(o, 'rSink', 'rN')} | — | — | — |")
    L.append("")
    worst = sorted([r for r in new_r["rows"] if r["fN"] and r["fThrough"] and r["fThrough"] / r["fN"] >= .25],
                   key=lambda r: -(r["fThrough"] / r["fN"]))
    if worst:
        L += [f"### {b} : les bâtiments dont un quart des façades ou plus se traverse", "",
              "| Bâtiment | Plan (x, z) | Rayons traversés | au pire (studs) | Solides |", "|---|---|---|---|---|"]
        for r in worst[:25]:
            L.append(f"| {r['u']} ({r['model']}) | {r['at']} | {int(r['fThrough'])} / {int(r['fN'])} | {r['fMaxThrough']} | {int(r['solids'] or 0)} |")
        L.append("")
    if old_w or new_w:
        L += ["## Le corps : la marche contre la façade, la chute sur le toit", "",
              "Le corps du joueur marche vers la façade côté rue jusqu'à ce que le solide l'arrête ; puis il tombe au milieu du toit.", "",
              f"| | {a} | {b} |", "|---|---|---|"]

        def facts(w):
            if not w:
                return ["—"] * 5
            s = w["sinks"]
            return [f"{len(w['into'])} sur {w['walked']}", f"{len(w['through'])}", f"{len(w['sink'])} sur {w['dropped']}",
                    f"{median(s):.1f} studs" if s else "—", f"{len(w['fell'])}"]
        fo, fn = facts(old_w), facts(new_w)
        for label, x, y in zip([f"Façades où le corps entre de plus de {INTO} stud", "dont rien ne l'arrête à hauteur du corps",
                                f"Toits où les pieds finissent à plus de {SINK} stud sous le dessin", "enfoncement médian des pieds (toutes les chutes)",
                                "chutes à plus de 6 studs sous le toit"], fo, fn):
            L.append(f"| {label} | {x} | **{y}** |")
        L.append("")
        if new_w and new_w["into"]:
            L += [f"### {b} : les façades où le corps entre", "",
                  "| Bâtiment | Plan (x, z) | Façade dessinée à | Solide à | Le corps entre de |", "|---|---|---|---|---|"]
            for r in new_w["into"][:20]:
                L.append(f"| {r['u']} ({r['model']}) | {r['at']} | {r['drawn']} | {r['solid'] if r['solid'] is not None else 'rien'} | **{r['into']}** |")
            L.append("")
        if new_w and new_w["sink"]:
            L += [f"### {b} : les toits où l'on s'enfonce", "",
                  "| Bâtiment | Plan (x, z) | Toit dessiné à | Solide à | Pieds à | Sous le toit de |", "|---|---|---|---|---|---|"]
            for r in new_w["sink"][:20]:
                L.append(f"| {r['u']} ({r['model']}) | {r['at']} | {r['roofDrawn']} | {r['roofSolid']} | {r['feet']} | **{r['sink']}** |")
            L.append("")
    return "\n".join(L)


def pct(a, b):
    return f"{100 * a / b:.0f} %" if b else "—"


def median(xs):
    return xs[len(xs) // 2] if xs else None


def markdown(s, w, old_s=None, old_w=None):
    L = ["# Collisions de Konoha : ce qu'on traverse", ""]
    if s:
        L += ["## Le dessin contre ce qui arrête (toutes les unités du village)", "",
              f"Un point du dessin est **traversable** s'il est à plus de {GAP} stud de tout solide de son unité : le corps y entre avant d'être arrêté. "
              f"Un point d'une face solide est **fantôme** s'il est à plus de {GAP} stud du dessin : on y bute sur du vide.", "",
              "| Groupe | Unités | Façades traversables | Toits traversables | Solide sans dessin |" + (" Avant (façades / toits / fantôme) |" if old_s else ""),
              "|---|---|---|---|---|" + ("---|" if old_s else "")]
        for name in ("bâtiments", "falaise", "objets et murs", "arbres"):
            g = s["groups"].get(name)
            if not g:
                continue
            row = (f"| {name} | {g['n']} | {g['facadeCross']:.0f} / {g['facadeArea']:.0f} studs² ({pct(g['facadeCross'], g['facadeArea'])}) | "
                   f"{g['roofCross']:.0f} / {g['roofArea']:.0f} ({pct(g['roofCross'], g['roofArea'])}) | {g['ghost']:.0f} / {g['faces']:.0f} ({pct(g['ghost'], g['faces'])}) |")
            if old_s:
                o = old_s["groups"].get(name)
                row += (f" {pct(o['facadeCross'], o['facadeArea'])} / {pct(o['roofCross'], o['roofArea'])} / {pct(o['ghost'], o['faces'])} |" if o else " — |")
            L.append(row)
        L += ["", "### Par modèle (bâtiments, falaise)", "",
              "| Modèle | Unités | Façades traversables | au pire | Toits traversables | au pire | Solide sans dessin | Morceaux |", "|---|---|---|---|---|---|---|---|"]
        for m in sorted(s["models"], key=lambda m: -(m["facadeCross"] + m["roofCross"])):
            if m["group"] not in ("bâtiments", "falaise") or (m["facadeCross"] + m["roofCross"] + m["ghost"]) == 0:
                continue
            L.append(f"| {m['model']} | {m['n']} | {pct(m['facadeCross'], m['facadeArea'])} | {m['facadeMax']:.1f} | {pct(m['roofCross'], m['roofArea'])} | "
                     f"{m['roofMax']:.1f} | {pct(m['ghost'], m['faces'])} | {m['pieces'].replace(',', ', ')} |")
        L.append("")
    if w:
        sinks = w["sinks"]
        L += ["## Le corps : la marche contre la façade, la chute sur le toit", "",
              f"Pour chaque bâtiment, le corps marche vers la façade côté rue jusqu'à ce que le solide l'arrête ; puis il tombe sur le toit, au milieu.", "",
              f"- **Façades** : {w['walked']} marchées. Le corps entre de plus de {INTO} stud dans le dessin devant **{len(w['into'])}**"
              + (f", dont {len(w['through'])} où rien ne l'arrête à hauteur du corps" if w["through"] else "") + "."
              + (f" ({len(w['still'])} marches ratées, le corps n'a pas bougé : écartées.)" if w["still"] else "")
              + (f" Avant : {len(old_w['into'])} sur {old_w['walked']}." if old_w else ""),
              f"- **Toits** : {w['dropped']} chutes. Les pieds finissent à plus de {SINK} stud sous le toit dessiné sur **{len(w['sink'])}**"
              + (f" (médiane {median(sinks):.1f} studs, au pire {sinks[-1]:.1f})" if sinks else "")
              + f" ; {len(w['fell'])} à plus de 6 studs." + (f" Avant : {len(old_w['sink'])} sur {old_w['dropped']}." if old_w else ""), ""]
        if w["into"]:
            L += ["| Bâtiment | Plan (x, z) | Façade dessinée à | Solide à | Le corps entre de |", "|---|---|---|---|---|"]
            for r in w["into"][:25]:
                L.append(f"| {r['u']} ({r['model']}) | {r['at']} | {r['drawn']} | {r['solid'] if r['solid'] is not None else 'rien'} | **{r['into']}** |")
            L.append("")
        if w["sink"]:
            L += ["| Bâtiment | Plan (x, z) | Toit dessiné à | Solide à | Pieds à | Sous le toit de |", "|---|---|---|---|---|---|"]
            for r in w["sink"][:25]:
                L.append(f"| {r['u']} ({r['model']}) | {r['at']} | {r['roofDrawn']} | {r['roofSolid']} | {r['feet']} | **{r['sink']}** |")
            L.append("")
    return "\n".join(L)


def page(md_text, title="Collisions de Konoha"):
    """The markdown as a plain page (tables and lists), light and dark."""
    out, table = [], []

    def flush():
        if table:
            out.append("<div class=t><table>" + "".join(
                "<tr>" + "".join(f"<{'th' if i == 0 else 'td'}>{c}</{'th' if i == 0 else 'td'}>" for c in r) + "</tr>"
                for i, r in enumerate(table)) + "</table></div>")
            table.clear()

    def inline(t):
        t = html.escape(t)
        t = re.sub(r"\*\*(.+?)\*\*", r"<b>\1</b>", t)
        t = re.sub(r"`(.+?)`", r"<code>\1</code>", t)
        return t
    for line in md_text.split("\n"):
        if line.startswith("|"):
            cells = [inline(c.strip()) for c in line.strip("|").split("|")]
            if all(set(c) <= set("-: ") for c in cells):
                continue
            table.append(cells)
            continue
        flush()
        if line.startswith("### "):
            out.append(f"<h3>{inline(line[4:])}</h3>")
        elif line.startswith("## "):
            out.append(f"<h2>{inline(line[3:])}</h2>")
        elif line.startswith("# "):
            out.append(f"<h1>{inline(line[2:])}</h1>")
        elif line.startswith("- "):
            out.append(f"<ul><li>{inline(line[2:])}</li></ul>")
        elif line.strip():
            out.append(f"<p>{inline(line)}</p>")
    flush()
    css = (":root{--bg:#f7f4ee;--fg:#1d1b18;--line:#d9d2c4;--head:#ece5d8}"
           "@media (prefers-color-scheme:dark){:root{--bg:#171512;--fg:#ece7de;--line:#3a352d;--head:#24211c}}"
           "body{background:var(--bg);color:var(--fg);font:15px/1.5 system-ui,sans-serif;margin:0;padding:16px;max-width:1100px}"
           ".t{overflow-x:auto}table{border-collapse:collapse;margin:8px 0 18px}td,th{border:1px solid var(--line);padding:4px 8px;text-align:left}"
           "th{background:var(--head)}h1{font-size:24px}h2{font-size:19px;margin-top:28px}h3{font-size:16px}ul{margin:4px 0;padding-left:20px}")
    return (f"<!doctype html><html lang=fr><meta charset=utf-8><meta name=viewport content='width=device-width,initial-scale=1'>"
            f"<title>{html.escape(title)}</title><style>{css}</style><body>{''.join(out)}</body></html>")


def main(argv=None):
    args = argv if argv is not None else sys.argv[1:]
    if not args:
        print(__doc__)
        return 2
    code = snippet(args)
    if code:
        print(code)
        return 0
    if args[0] == "--compare":
        return compare_main(args[1:])
    if args[0] != "--report":
        print(__doc__)
        return 2
    rest, opts = [], {}
    i = 1
    while i < len(args):
        if args[i] == "--avant":
            j = i + 1
            old = []
            while j < len(args) and not args[j].startswith("--"):
                old.append(args[j])
                j += 1
            opts["avant"] = old
            i = j
        elif args[i] in ("--md", "--html"):
            opts[args[i]] = args[i + 1]
            i += 2
        else:
            rest.append(args[i])
            i += 1
    s = survey(rest[0]) if rest else None
    w = walk(rest[1]) if len(rest) > 1 else None
    old = opts.get("avant") or []
    old_s = survey(old[0]) if old else None
    old_w = walk(old[1]) if len(old) > 1 else None
    text = markdown(s, w, old_s, old_w)
    if "--md" in opts:
        with open(opts["--md"], "w", encoding="utf-8") as f:
            f.write(text + "\n")
    if "--html" in opts:
        with open(opts["--html"], "w", encoding="utf-8") as f:
            f.write(page(text))
    if "--md" not in opts and "--html" not in opts:
        print(text)
    return 0


def compare_main(args):
    files, opts, i = [], {}, 0
    while i < len(args):
        if args[i] == "--marche":
            opts["marche"] = args[i + 1:i + 3]
            i += 3
        elif args[i] == "--labels":
            opts["labels"] = tuple(args[i + 1:i + 3])
            i += 3
        elif args[i] in ("--md", "--html"):
            opts[args[i]] = args[i + 1]
            i += 2
        else:
            files.append(args[i])
            i += 1
    if len(files) != 2:
        print(__doc__)
        return 2
    marche = opts.get("marche") or [None, None]
    text = compare_md(rays(files[0]), rays(files[1]), walk(marche[0]) if marche[0] else None,
                      walk(marche[1]) if marche[1] else None, opts.get("labels") or ("avant", "après"))
    if "--md" in opts:
        with open(opts["--md"], "w", encoding="utf-8") as f:
            f.write(text + "\n")
    if "--html" in opts:
        with open(opts["--html"], "w", encoding="utf-8") as f:
            f.write(page(text, "Collisions de Konoha, avant et après"))
    if "--md" not in opts and "--html" not in opts:
        print(text)
    return 0


if __name__ == "__main__":
    sys.exit(main())
