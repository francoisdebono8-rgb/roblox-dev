#!/usr/bin/env python3
"""Le comparateur de kits (OUTILLEUR, 20/11 ; DEC-043, étape 1, OUTILLEUR 2).

Il lit l'empreinte des kits que sort KitPrint.luau (dans Studio ou avec lune),
et la rend lisible :
  - pour chaque kit, cinq notes de 0 à 100 relatives aux huit (portée, vitesse,
    mobilité, dégâts par seconde, tenue) et ce qu'il a en propre ;
  - les deux kits les plus proches : si deux kits se ressemblent, ça se voit ;
  - avant / après : ce qui a bougé entre deux empreintes (deux commits, ou le
    départ d'un joueur et l'arbre complet).

    python3 tools/kits/empreinte.py EMPREINTE.json                    le rapport
    python3 tools/kits/empreinte.py EMPREINTE.json --version depart   un joueur sans nœud
    python3 tools/kits/empreinte.py AVANT.json APRES.json             avant / après
    python3 tools/kits/empreinte.py EMPREINTE.json --arbre            départ → arbre complet
    python3 tools/kits/empreinte.py EMPREINTE.json --natures          les 5 natures sur chaque kit
    python3 tools/kits/empreinte.py AVANT.json [APRES.json] --etape2  Naruto, Sasuke, Lee : départ réduit,
                                                                      arbre complet, les 5 natures
    ... --html page.html                                              la même chose en page

Les notes sont une part du meilleur : 100 = le meilleur des huit sur ce point,
80 = 80 % de ce que fait le meilleur. Elles disent comment les kits se placent
les uns par rapport aux autres, pas s'ils sont équilibrés.
"""
from __future__ import annotations

import html
import json
import math
import sys

AXES = ["portée", "vitesse", "mobilité", "dégâts/s", "tenue"]


def raw(k: dict) -> dict:
    """Les mesures brutes d'une version de kit."""
    s, mv, body, j = k["string"], k["move"], k["body"], k["jutsu"]
    return {
        "reach": k.get("reach") or 0, "far": j.get("farthest") or 0,
        "first": k.get("firstHit") or 1, "hps": (s.get("count") or 0) / max(s.get("time") or 1, 0.01),
        "run": (mv.get("run") or 0) * (mv.get("accel") or 1), "jump": mv.get("jump") or 1, "air": mv.get("air") or 1,
        "dash": mv.get("dash") or 1, "jumps": (j.get("teleports") or 0) + 0.5 * (j.get("mobile") or 0),
        "dps": (s.get("dps") or 0) + (j.get("dps") or 0),
        "health": body.get("health") or 0, "chakra": body.get("chakra") or 0, "regen": body.get("regen") or 0,
    }


def raws_of(data: dict, version: str) -> dict:
    return {kid: raw(e["versions"][version]) for kid, e in data["kits"].items() if version in e["versions"]}


def scores(data: dict, version: str = "prodige", against: list | None = None) -> dict:
    """{kit: {axe: 0..100}} : chaque note est une part du meilleur des kits (100 = le meilleur),
    sans étirer les écarts : deux kits proches restent proches. `against` : d'autres mesures
    brutes qui comptent pour « le meilleur » (avant / après sur la même échelle)."""
    raws = raws_of(data, version)
    if not raws:
        return {}
    pool = list(raws.values()) + list(against or [])
    best = {key: max(r[key] for r in pool) for key in next(iter(raws.values()))}
    fastest = min(r["first"] for r in pool)

    def part(r, key):
        return r[key] / best[key] if best[key] else 1.0
    out = {}
    for kid, r in raws.items():
        out[kid] = {
            "portée": 0.5 * part(r, "reach") + 0.5 * part(r, "far"),
            "vitesse": 0.5 * (fastest / r["first"]) + 0.5 * part(r, "hps"),
            "mobilité": (2 * part(r, "run") + part(r, "jump") + part(r, "air") + part(r, "dash")
                         + (part(r, "jumps") if best["jumps"] else 1)) / 6,
            "dégâts/s": part(r, "dps"),
            "tenue": 0.6 * part(r, "health") + 0.2 * part(r, "chakra") + 0.2 * part(r, "regen"),
        }
        out[kid] = {a: round(100 * v, 1) for a, v in out[kid].items()}
    return out


def own(data: dict, version: str = "prodige") -> dict:
    """Ce que chaque kit a en propre : ses champs, familles et éléments que les autres n'ont pas."""
    marks = {}
    for kid, e in data["kits"].items():
        k = e["versions"].get(version)
        if not k:
            continue
        m = set(k.get("own") or [])
        for t in k["jutsu"]["list"]:
            if t.get("family"):
                m.add("jutsu " + t["family"])
            if t.get("element"):
                m.add("élément " + t["element"])
        if k.get("style"):
            m.add("style " + k["style"])
        if k["tool"].get("kind"):
            m.add("outil " + str(k["tool"]["kind"]))
        marks[kid] = m
    out = {}
    for kid, m in marks.items():
        others = set().union(*(v for o, v in marks.items() if o != kid)) if len(marks) > 1 else set()
        out[kid] = sorted(m - others)
    return out


def closest(sc: dict) -> list:
    """Les paires de kits, de la plus proche à la plus éloignée (distance sur les 5 notes)."""
    ids = list(sc)
    pairs = []
    for i, a in enumerate(ids):
        for b in ids[i + 1:]:
            d = math.sqrt(sum((sc[a][x] - sc[b][x]) ** 2 for x in AXES)) / math.sqrt(len(AXES))
            pairs.append((round(d, 1), a, b))
    return sorted(pairs)


def name(data, kid):
    e = data["kits"][kid]
    return f"{e.get('name') or kid}"


def bar(v: float, width: int = 10) -> str:
    n = int(round(v / 100 * width))
    return "█" * n + "·" * (width - n)


def report(data: dict, version: str = "prodige") -> str:
    sc = scores(data, version)
    mine = own(data, version)
    lines = [f"Empreinte des kits — version « {version} » ({len(sc)} kits)", ""]
    head = f"{'kit':<12}" + "".join(f"{a:>14}" for a in AXES)
    lines.append(head)
    for kid in data.get("order") or sc:
        if kid not in sc:
            continue
        lines.append(f"{name(data, kid):<12}" + "".join(f"  {bar(sc[kid][a])} {sc[kid][a]:>3.0f}" for a in AXES))
    lines.append("")
    lines.append("En chiffres (corde de coups, premier coup, portée du coup simple, course, PV) :")
    for kid in data.get("order") or sc:
        if kid not in sc:
            continue
        k = data["kits"][kid]["versions"][version]
        s, mv, b, j = k["string"], k["move"], k["body"], k["jutsu"]
        lines.append(f"  {name(data, kid):<11} {s['count']} coups, {s['damage']:.0f} dégâts en {s['time']:.2f} s "
                     f"({s['dps']:.1f}/s) · 1er coup {k['firstHit']:.2f} s · portée {k['reach']:.1f} · course {mv['run']:.1f} · "
                     f"PV {b['health']:.0f} · {j['count']} jutsu ({j['dps']:.1f}/s, {j['teleports']} téléport.)")
    lines.append("")
    lines.append("Ce qu'il a en propre :")
    for kid in data.get("order") or sc:
        if kid in mine:
            lines.append(f"  {name(data, kid):<11} " + (", ".join(mine[kid]) if mine[kid] else "RIEN qu'un autre n'ait pas"))
    pairs = closest(sc)
    if pairs:
        d, a, b = pairs[0]
        lines.append("")
        lines.append(f"Les deux kits les plus proches : {name(data, a)} et {name(data, b)} (écart {d:.0f}/100).")
        far = pairs[-1]
        lines.append(f"Les plus éloignés : {name(data, far[1])} et {name(data, far[2])} (écart {far[0]:.0f}/100).")
    return "\n".join(lines)


def diff(before: dict, after: dict, vb: str = "prodige", va: str = "prodige", label=("avant", "après")) -> str:
    """Ce qui bouge entre deux empreintes : les notes, les chiffres, ce qui apparaît ou disparaît en propre."""
    # la même échelle pour les deux : le meilleur se cherche dans l'avant et l'après
    rb, ra = raws_of(before, vb), raws_of(after, va)
    sb, sa = scores(before, vb, list(ra.values())), scores(after, va, list(rb.values()))
    ob, oa = own(before, vb), own(after, va)
    lines = [f"Avant / après — {label[0]} ({vb}) → {label[1]} ({va})", ""]
    ids = [k for k in (after.get("order") or sa) if k in sb and k in sa]
    for kid in ids:
        kb, ka = before["kits"][kid]["versions"][vb], after["kits"][kid]["versions"][va]
        moved = []
        for a in AXES:
            d = sa[kid][a] - sb[kid][a]
            if abs(d) >= 1:
                moved.append(f"{a} {sb[kid][a]:.0f}→{sa[kid][a]:.0f}")
        facts = []
        for label_, get in (("dégâts/s corde", lambda k: k["string"]["dps"]), ("1er coup", lambda k: k["firstHit"]),
                            ("portée", lambda k: k["reach"]), ("course", lambda k: k["move"]["run"]),
                            ("PV", lambda k: k["body"]["health"]), ("jutsu", lambda k: k["jutsu"]["count"]),
                            ("dégâts/s jutsu", lambda k: k["jutsu"]["dps"])):
            x, y = get(kb), get(ka)
            if x != y:
                facts.append(f"{label_} {x}→{y}")
        names_b = {t["id"] for t in kb["jutsu"]["list"]}
        names_a = {t["id"] for t in ka["jutsu"]["list"]}
        gained, lost = sorted(names_a - names_b), sorted(names_b - names_a)
        own_gained = sorted(set(oa.get(kid, [])) - set(ob.get(kid, [])))
        own_lost = sorted(set(ob.get(kid, [])) - set(oa.get(kid, [])))
        if not (moved or facts or gained or lost or own_gained or own_lost):
            lines.append(f"  {name(after, kid):<11} rien ne bouge")
            continue
        lines.append(f"  {name(after, kid):<11} " + ("; ".join(moved) if moved else "notes inchangées"))
        if facts:
            lines.append(f"  {'':<11} " + ", ".join(facts))
        if gained or lost:
            lines.append(f"  {'':<11} jutsu " + " ".join([f"+{g}" for g in gained] + [f"-{x}" for x in lost]))
        if own_gained or own_lost:
            lines.append(f"  {'':<11} en propre " + " ".join([f"+{g}" for g in own_gained] + [f"-{x}" for x in own_lost]))
    pb, pa = closest(sb), closest(sa)
    if pb and pa:
        lines.append("")
        lines.append(f"Les deux plus proches : {name(before, pb[0][1])}–{name(before, pb[0][2])} {pb[0][0]:.0f}/100 → "
                     f"{name(after, pa[0][1])}–{name(after, pa[0][2])} {pa[0][0]:.0f}/100")
        mean_b = sum(p[0] for p in pb) / len(pb)
        mean_a = sum(p[0] for p in pa) / len(pa)
        lines.append(f"Écart moyen entre les kits : {mean_b:.0f} → {mean_a:.0f} (plus haut = des kits plus différents)")
    return "\n".join(lines)


NATURES = ["Fire", "Wind", "Lightning", "Earth", "Water"]
FR = {"Fire": "Feu", "Wind": "Vent", "Lightning": "Foudre", "Earth": "Terre", "Water": "Eau"}
TRIO = ["Legion", "Lion", "Leaf"]  # Naruto, Sasuke, Lee : les trois kits de l'étape 2 (DEC-045)


def effect(n: dict, dps: float) -> str:
    """Ce qu'une nature fait à ce kit, en une ligne (d'après KitPrint.nature)."""
    gap = n.get("gap") or 4
    if "burnDps" in n:
        b = n["burnDps"]
        return f"+{b:.2f} dégâts/s de brûlure, soit +{100 * b / dps:.0f} % de ce qu'il fait par seconde" if b else "RIEN"
    if "kunaiRange" in n:
        r, push = n["kunaiRange"], n.get("push")
        parts = []
        if r > 1:
            parts.append(f"le lancer vole {100 * (r - 1):.0f} % plus loin et plus vite "
                         f"({n.get('kunaiSpeedBase') or 0:.0f} → {n.get('kunaiSpeed') or 0:.0f} studs/s)")
        if push and push > 1:
            parts.append(f"le dernier coup envoie le corps {100 * (push - 1):.0f} % plus loin")
        if parts:
            return " ; ".join(parts) + ("" if r > 1 else " (il ne lance aucune lame)")
        if push is None:
            # empreinte d'avant le 21/11 (v2) : la poussée du dernier coup n'y est pas
            return "rien sur le lancer : il ne lance aucune lame (poussée du dernier coup non mesurée)"
        return "RIEN"
    if "frozen" in n:
        f = n["frozen"]
        return f"l'adversaire est gelé {100 * f:.1f} % du temps ({f * gap:.2f} s toutes les {gap:g} s)" if f else "RIEN"
    if "guardDps" in n:
        g = n["guardDps"]
        return f"+{g * gap:.0f} dégâts sur sa garde toutes les {gap:g} s ({g:.2f}/s)" if g else "RIEN"
    if "slowed" in n:
        s = n["slowed"]
        return f"l'adversaire est {100 * s:.1f} % plus lent en moyenne" if s else "RIEN"
    return "?"


def natures_report(data: dict, kits: list | None = None) -> str:
    """Les cinq natures sur chaque kit (arbre complet, toute la branche INFUSION)."""
    kits = [k for k in (kits or data.get("order") or []) if data["kits"].get(k, {}).get("natures")]
    if not kits:
        return "Pas de nature dans cette empreinte (KitPrint sans NinjaTree, ou avant le 21/11)."
    lines = ["Les cinq natures de l'arbre du ninja, avec kunai infusé, lame infusée et maîtrise",
             "(chiffres du contrat NinjaTree.Infusion, que le combat lit dans Server/NinjaArts depuis DEV 3/4)", ""]
    for kid in kits:
        e = data["kits"][kid]
        arbre = e["versions"]["arbre"]
        dps = (arbre["string"]["dps"] or 0) + (arbre["jutsu"]["dps"] or 0)
        carriers = e["natures"]["Fire"].get("carriers") or []
        porte = " et ".join({"blade": "le 3e coup", "kunai": "le kunai", "shuriken": "le shuriken"}.get(c, c) for c in carriers)
        lines.append(f"  {name(data, kid)} — porté par {porte or 'rien'} ; {dps:.1f} dégâts/s avec son arbre")
        for nat in NATURES:
            n = e["natures"].get(nat)
            if n:
                lines.append(f"    {FR[nat]:<7} {effect(n, dps)}   [réponse : {n.get('answer')}]")
    # ce qui change d'un kit à l'autre : les natures dont les chiffres diffèrent
    same, differ = [], []
    for nat in NATURES:
        values = {json.dumps({k: v for k, v in data["kits"][kid]["natures"][nat].items() if k != "carriers"}, sort_keys=True)
                  for kid in kits if nat in data["kits"][kid]["natures"]}
        (same if len(values) <= 1 else differ).append(FR[nat])
    lines.append("")
    if same:
        lines.append(f"Les mêmes chiffres sur tous ces kits : {', '.join(same)}. L'effet part au plus une fois toutes les "
                     f"{data['kits'][kits[0]]['natures']['Fire'].get('gap', 4):g} s, et chaque kit touche plus souvent que ça : "
                     "la nature ne dépend pas du kit, seulement de sa part dans ce qu'il fait.")
    if differ:
        lines.append(f"Ce qui change d'un kit à l'autre : {', '.join(differ)}.")
    return "\n".join(lines)


def techniques(k: dict) -> list:
    return [t["id"] for t in k["jutsu"]["list"]]


def etape2(before: dict, after: dict | None = None, kits: list | None = None) -> str:
    """Les 3 kits de l'étape 2 : le départ d'un joueur avant / après le départ réduit,
    ce que l'arbre lui rend, et l'écart départ → arbre complet."""
    after = after or before
    kits = [k for k in (kits or TRIO) if k in after["kits"] and k in before["kits"]]
    lines = ["Étape 2 — Naruto, Sasuke, Lee : le départ d'un joueur, et ce que l'arbre lui donne", ""]
    for kid in kits:
        b, a = before["kits"][kid]["versions"], after["kits"][kid]["versions"]
        d0, d1, t1 = techniques(b["depart"]), techniques(a["depart"]), techniques(a["arbre"])
        locked = a["depart"]["jutsu"].get("locked") or []
        lines.append(f"  {name(after, kid)}")
        lines.append(f"    départ, avant : {len(d0)} techniques ({', '.join(d0)})")
        if after is before or d0 == d1:
            lines.append("    départ, après : pas encore changé (le départ réduit n'est pas dans cette empreinte)")
        else:
            lines.append(f"    départ, après : {len(d1)} techniques ({', '.join(d1)})")
        gained = [t for t in t1 if t not in d1]
        lines.append(f"    l'arbre complet : {len(t1)} techniques" + (f", dont {', '.join(gained)} gagnées dans l'arbre" if gained else ""))
        if locked:
            lines.append(f"    verrouillé au départ : {', '.join(locked)}")
        tree = after["kits"][kid].get("tree") or {}
        if "transform" in tree:  # KitPrint v3 (21/11)
            tr = tree["transform"]
            lines.append("    transformation : " + (", ".join(f"{t.get('name') or t['id']} ({t['id']})" for t in tr)
                                                    if tr else "pas encore de nœud (Transform)"))
    lines.append("")
    lines.append(diff(after, after, "depart", "arbre", ("départ d'un joueur", "arbre complet")))
    return "\n".join(lines)


def page(data: dict, version: str, text: str) -> str:
    """Une page : un radar par kit, et le rapport en texte."""
    sc = scores(data, version)
    cards = []
    for kid in data.get("order") or sc:
        if kid not in sc:
            continue
        pts = []
        for i, a in enumerate(AXES):
            ang = -math.pi / 2 + i * 2 * math.pi / len(AXES)
            r = 10 + 60 * sc[kid][a] / 100
            pts.append(f"{90 + r * math.cos(ang):.1f},{90 + r * math.sin(ang):.1f}")
        axes = "".join(
            f'<line x1="90" y1="90" x2="{90 + 70 * math.cos(-math.pi / 2 + i * 2 * math.pi / len(AXES)):.1f}" '
            f'y2="{90 + 70 * math.sin(-math.pi / 2 + i * 2 * math.pi / len(AXES)):.1f}" class="ax"/>'
            f'<text x="{90 + 84 * math.cos(-math.pi / 2 + i * 2 * math.pi / len(AXES)):.1f}" '
            f'y="{94 + 84 * math.sin(-math.pi / 2 + i * 2 * math.pi / len(AXES)):.1f}">{html.escape(a)}</text>'
            for i, a in enumerate(AXES))
        cards.append(f'<figure><svg viewBox="-20 -10 220 200"><circle cx="90" cy="90" r="70" class="ring"/>{axes}'
                     f'<polygon points="{" ".join(pts)}" class="kit"/></svg>'
                     f'<figcaption>{html.escape(name(data, kid))}</figcaption></figure>')
    return f"""<!doctype html><html lang="fr"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Empreinte des kits</title><style>
:root{{--bg:#f6f3ec;--fg:#1d1b19;--mute:#8a8378;--kit:#c2392e}}
@media (prefers-color-scheme:dark){{:root{{--bg:#191714;--fg:#eee8dd;--mute:#8a8378;--kit:#e2574b}}}}
body{{background:var(--bg);color:var(--fg);font:15px/1.45 system-ui,sans-serif;margin:0;padding:24px 16px}}
h1{{font-size:20px;margin:0 0 12px}} .grid{{display:grid;grid-template-columns:repeat(auto-fill,minmax(180px,1fr));gap:12px}}
figure{{margin:0}} figcaption{{text-align:center;font-weight:600}} svg{{width:100%}}
.ring{{fill:none;stroke:var(--mute);stroke-opacity:.35}} .ax{{stroke:var(--mute);stroke-opacity:.35}}
text{{fill:var(--mute);font-size:10px;text-anchor:middle}} .kit{{fill:var(--kit);fill-opacity:.25;stroke:var(--kit);stroke-width:2}}
pre{{white-space:pre-wrap;overflow-x:auto;font-size:12px}}</style></head><body>
<h1>Empreinte des kits — {html.escape(version)}</h1><div class="grid">{''.join(cards)}</div><pre>{html.escape(text)}</pre></body></html>"""


def main(argv) -> int:
    files = [a for a in argv if not a.startswith("--") and not (argv.index(a) > 0 and argv[argv.index(a) - 1] in ("--version", "--html"))]
    version = argv[argv.index("--version") + 1] if "--version" in argv else "prodige"
    out_html = argv[argv.index("--html") + 1] if "--html" in argv else None
    if not files:
        print(__doc__)
        return 2
    data = [json.load(open(f, encoding="utf-8")) for f in files]
    if "--etape2" in argv:
        text = etape2(data[0], data[1] if len(data) == 2 else None) + "\n\n" + natures_report(data[-1], TRIO)
    elif "--natures" in argv:
        text = natures_report(data[-1])
    elif len(data) == 2:
        text = diff(data[0], data[1], version, version, (files[0], files[1]))
    elif "--arbre" in argv:
        text = diff(data[0], data[0], "depart", "arbre", ("départ d'un joueur", "arbre complet"))
    else:
        text = report(data[0], version)
    print(text)
    if out_html:
        with open(out_html, "w", encoding="utf-8") as f:
            f.write(page(data[-1], version if "--arbre" not in argv else "arbre", text))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
