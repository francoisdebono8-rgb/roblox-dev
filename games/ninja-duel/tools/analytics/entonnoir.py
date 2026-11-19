#!/usr/bin/env python3
"""Lecteur de l'entonnoir des nouveaux joueurs (OUTILLEUR, 19/11).

Demande : `claude/vague-2-taches-2026-11-19`, § 2 OUTILLEUR 1. Il lit le fichier
exporté de l'analytique Roblox (page Entonnoirs du tableau de bord créateur),
sans clé API, et dit à quelle étape les nouveaux joueurs partent.

Il lit aussi les lignes `[NinjaDuelFirst]` que le serveur écrit dans la sortie
(Studio, test avec de vrais joueurs) : même entonnoir, avec le temps de chaque
étape et l'endroit où les joueurs sont partis.

Les étapes attendues viennent du jeu lui-même (`Matches.FUNNEL`, ou tout appel
`LogOnboardingFunnelStepEvent(joueur, n, "nom")` dans `src/`) : quand le DEV
change les étapes, le lecteur suit sans modification.

    python3 tools/analytics/entonnoir.py EXPORT.csv [AUTRE.csv ...]
    python3 tools/analytics/entonnoir.py sortie_studio.log
    python3 tools/analytics/entonnoir.py EXPORT.csv --json
    python3 tools/analytics/entonnoir.py --etapes      # les étapes du jeu

Le format exact de l'export n'est pas documenté par Roblox (« timestamps and
values of each datapoint per KPI » pour les graphiques). Le lecteur accepte donc
plusieurs formes : une ligne par étape ; une ligne par jour et par étape ; une
colonne par étape ; avec ou sans répartition (plateforme, âge...) ; en
nombres ou en pourcentages ; virgule, point-virgule ou tabulation ; en anglais
ou en français. À défaut d'export, une saisie à la main (« arrivée 120 ») marche
aussi.
"""
from __future__ import annotations

import argparse
import csv
import io
import json
import re
import statistics
import sys
import unicodedata
from dataclasses import dataclass, field
from pathlib import Path

GAME = Path(__file__).resolve().parents[2]
SRC = GAME / "src"

# Le nom des étapes, pour le rapport. Une étape inconnue garde son nom.
LABELS = {
    "joined": "arrivée", "join": "arrivée", "arrival": "arrivée", "arrivee": "arrivée", "arrive": "arrivée",
    "outfit": "tenue", "dressed": "tenue", "dress": "tenue", "tenue": "tenue",
    "starter": "inspiration", "inspiration": "inspiration", "kit": "inspiration", "choosestarter": "inspiration",
    "input": "première entrée", "firstinput": "première entrée",
    "jutsu": "premier jutsu", "firstjutsu": "premier jutsu",
    "duel": "premier duel", "firstduel": "premier duel", "duelstart": "premier duel", "premierduel": "premier duel",
    "hit": "premier coup", "firsthit": "premier coup", "premiercoup": "premier coup",
    "win": "première victoire", "victory": "première victoire", "firstwin": "première victoire",
    "premierevictoire": "première victoire",
    "purchase": "premier achat", "buy": "premier achat", "firstpurchase": "premier achat",
    "firstbuy": "premier achat", "achat": "premier achat", "premierachat": "premier achat",
}
# Sous ce nombre de joueurs à la première étape, le rapport parle de piste.
SMALL = 30


def norm(text: str) -> str:
    """Minuscules, sans accents ni ponctuation : « Première Victoire » → premierevictoire."""
    text = unicodedata.normalize("NFKD", str(text)).encode("ascii", "ignore").decode()
    return re.sub(r"[^a-z0-9]", "", text.lower())


def label(step_id: str) -> str:
    return LABELS.get(norm(step_id), step_id)


# ---------------------------------------------------------------- le jeu

def game_steps(src: Path = SRC) -> list[tuple[int, str]]:
    """Les étapes que le jeu envoie, dans l'ordre : [(1, "joined"), ...]."""
    found: dict[int, str] = {}
    for path in sorted(src.rglob("*.luau")):
        text = path.read_text(encoding="utf-8", errors="replace")
        for body in re.findall(r"\bFUNNEL\s*=\s*\{([^}]*)\}", text):
            pairs = re.findall(r"\[?\s*\"?([A-Za-z_][\w]*)\"?\s*\]?\s*=\s*(\d+)", body)
            if pairs:
                for name, order in pairs:
                    found.setdefault(int(order), name)
                continue
            indexed = re.findall(r"\[\s*(\d+)\s*\]\s*=\s*\"([^\"]+)\"", body)
            if indexed:
                for order, name in indexed:
                    found.setdefault(int(order), name)
                continue
            for i, name in enumerate(re.findall(r"\"([^\"]+)\"", body), 1):
                found.setdefault(i, name)
        for order, name in re.findall(r"LogOnboardingFunnelStepEvent\(\s*[^,()]+,\s*(\d+)\s*,\s*\"([^\"]+)\"", text):
            found.setdefault(int(order), name)
    return sorted(found.items())


# ---------------------------------------------------------------- nombres

def number(cell) -> tuple[float | None, bool]:
    """« 1 234 », « 1,234 », « 45,2 % », « 0.452 » → (valeur, en pourcentage ?)."""
    if cell is None:
        return None, False
    s = str(cell).strip().replace(" ", "").replace(" ", "").replace(" ", "").replace(" ", "")
    if s in ("", "-", "—", "–", "N/A", "n/a", "NA", "null", "None"):
        return None, False
    pct = s.endswith("%")
    s = s.rstrip("%")
    if not re.fullmatch(r"[-+]?[\d.,]+", s):
        return None, False
    if "," in s and "." in s:
        # le dernier séparateur est la décimale
        if s.rfind(",") > s.rfind("."):
            s = s.replace(".", "").replace(",", ".")
        else:
            s = s.replace(",", "")
    elif "," in s:
        parts = s.split(",")
        if len(parts) > 2 or (len(parts[1]) == 3 and parts[0].lstrip("+-") not in ("", "0")):
            s = s.replace(",", "")  # 1,234 ou 1,234,567 : milliers
        else:
            s = s.replace(",", ".")
    elif s.count(".") > 1:
        s = s.replace(".", "")  # 1.234.567
    try:
        return float(s), pct
    except ValueError:
        return None, False


# ---------------------------------------------------------------- l'entonnoir

@dataclass
class Step:
    order: int | None
    id: str
    users: float | None = None   # joueurs arrivés à cette étape
    pct: float | None = None     # ou bien la part de la première étape, en %
    seconds: list[float] = field(default_factory=list)  # depuis l'arrivée (sortie du serveur)

    @property
    def name(self) -> str:
        return label(self.id)


@dataclass
class Funnel:
    group: str                 # « tous », ou une valeur de répartition (« Mobile »...)
    steps: list[Step]
    source: str = ""
    period: str = ""
    left: dict[str, int] = field(default_factory=dict)  # sortie du serveur : partis pendant <étape de la première minute>


def match_step(raw: str, known: list[tuple[int, str]]) -> tuple[int | None, str]:
    """« Step 3: jutsu », « 3 - jutsu », « 3. Premier jutsu », « jutsu (3) », « 3 » → (3, "jutsu")."""
    raw = str(raw).strip()
    m = (re.match(r"^(?:step|etape|étape|stage)?\s*#?\s*(\d+)\s*[.:\-–—)]?\s*(.*)$", raw, re.I)
         or None)
    order, name = None, raw
    if m:
        order, name = int(m.group(1)), m.group(2).strip()
    else:
        m = re.match(r"^(.*?)\s*\(\s*(\d+)\s*\)\s*$", raw)
        if m:
            order, name = int(m.group(2)), m.group(1).strip()
    by_name = {norm(n): (o, n) for o, n in known}
    by_label = {norm(label(n)): (o, n) for o, n in known}
    key = norm(name)
    if key in by_name:
        o, n = by_name[key]
        return (order or o), n
    if key in by_label:
        o, n = by_label[key]
        return (order or o), n
    if not name and order is not None:
        for o, n in known:
            if o == order:
                return o, n
        return order, f"étape {order}"
    return order, name


# ---------------------------------------------------------------- fichiers

HEAD = {
    "step": ("step", "etape", "stage", "funnelstep", "stepname", "nom", "name", "event", "evenement", "eventname"),
    "order": ("stepnumber", "stepno", "stepindex", "numero", "order", "ordre", "index", "no", "n"),
    "users": ("users", "user", "players", "player", "utilisateurs", "utilisateur", "joueurs", "joueur", "count",
              "nombre", "value", "valeur", "total", "uniqueusers", "uniques", "entered", "completed", "reached",
              "usersreached", "userscompleted"),
    "pct": ("conversion", "conversionrate", "rate", "taux", "tauxdeconversion", "percent", "pourcentage", "share",
            "part", "ofstep1", "duepart"),
    "drop": ("drop", "dropoff", "dropoffrate", "abandon", "abandons", "perte", "pertes", "depart", "departs",
             "tauxdabandon"),
    "date": ("date", "day", "jour", "time", "timestamp", "horodatage", "cohort", "cohorte", "week", "semaine",
             "datetime", "periode", "period"),
    "group": ("breakdown", "segment", "platform", "plateforme", "os", "device", "devicetype", "appareil", "age",
              "agegroup", "tranchedage", "gender", "genre", "sexe", "country", "pays", "locale", "langue", "language",
              "customfield", "customfield01", "customfield02", "customfield03", "champ", "repartition", "ventilation"),
}


def column_kind(header: str) -> str | None:
    k = norm(header)
    if not k:
        return None
    for kind in ("order", "drop", "pct", "date", "group", "users", "step"):
        if k in HEAD[kind]:
            return kind
    for kind, words in (("drop", ("dropoff", "abandon", "perte")), ("pct", ("conversion", "taux", "rate", "percent")),
                        ("date", ("date", "timestamp", "cohort", "cohorte")), ("order", ("stepnumber", "numero")),
                        ("users", ("users", "joueurs", "utilisateurs", "players", "count")),
                        ("step", ("step", "etape", "stage")), ("group", ("breakdown", "segment", "customfield"))):
        if any(w in k for w in words):
            return kind
    return None


def read_text(path: Path) -> str:
    raw = path.read_bytes()
    if raw.startswith(b"\xff\xfe") or raw.startswith(b"\xfe\xff"):
        return raw.decode("utf-16")
    for enc in ("utf-8-sig", "cp1252", "latin-1"):
        try:
            return raw.decode(enc)
        except UnicodeDecodeError:
            continue
    return raw.decode("utf-8", errors="replace")


def rows_of(text: str) -> list[list[str]]:
    lines = [ln for ln in text.splitlines() if ln.strip()]
    sample = "\n".join(lines[:40])
    counts = {d: sum(ln.count(d) for ln in lines[:40]) for d in (",", ";", "\t", "|")}
    delim = max(counts, key=counts.get) if max(counts.values()) > 0 else None
    if delim is None:
        return [[ln] for ln in lines]
    try:
        dialect = csv.Sniffer().sniff(sample, delimiters=delim)
        reader = csv.reader(io.StringIO("\n".join(lines)), dialect)
    except csv.Error:
        reader = csv.reader(io.StringIO("\n".join(lines)), delimiter=delim)
    return [[c.strip() for c in row] for row in reader]


def find_header(rows: list[list[str]]) -> int | None:
    """La première ligne d'au moins deux cases suivie d'une ligne qui contient un nombre."""
    for i, row in enumerate(rows[:-1]):
        cells = [c for c in row if c]
        if len(cells) < 2:
            continue
        if any(number(c)[0] is not None for c in cells):
            continue  # une ligne de données, pas un en-tête
        nxt = rows[i + 1]
        if len(nxt) >= 2 and any(number(c)[0] is not None for c in nxt):
            return i
    return None


def hand_typed(text: str, known: list[tuple[int, str]], source: str) -> list[Funnel]:
    """« arrivée 120 » / « 2. tenue : 95 » / « inspiration 80 % », une étape par ligne."""
    steps = []
    for line in text.splitlines():
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        m = re.match(r"^(.*?)[\s:=;,\t]+([-+]?[\d\s.,  ]+%?)$", line)
        if not m:
            continue
        value, pct = number(m.group(2))
        if value is None:
            continue
        order, sid = match_step(m.group(1).strip(" :;-"), known)
        steps.append(Step(order, sid, None if pct else value, value if pct else None))
    return [Funnel("tous", tidy(steps), source)] if steps else []


def tidy(steps: list[Step]) -> list[Step]:
    """Fusionne les doublons (plusieurs jours) et range par numéro d'étape, sinon dans l'ordre du fichier."""
    merged: dict[str, Step] = {}
    order: list[str] = []
    for st in steps:
        key = norm(st.id) or str(st.order)
        if key not in merged:
            merged[key] = Step(st.order, st.id, st.users, st.pct, list(st.seconds))
            order.append(key)
            continue
        m = merged[key]
        if st.users is not None:
            m.users = (m.users or 0) + st.users
        if st.pct is not None and m.pct is None:
            m.pct = st.pct
        m.seconds += st.seconds
        if m.order is None:
            m.order = st.order
    out = [merged[k] for k in order]
    if all(s.order is not None for s in out):
        out.sort(key=lambda s: s.order)
    return out


def read_table(text: str, known: list[tuple[int, str]], source: str) -> list[Funnel]:
    rows = rows_of(text)
    h = find_header(rows)
    if h is None:
        return hand_typed(text, known, source)
    meta = [" ".join(c for c in r if c) for r in rows[:h]]
    period = next((m for m in meta if re.search(r"\d{4}|date|jours|days|plage|range", m, re.I)), "")
    header = rows[h]
    kinds = [column_kind(c) for c in header]
    data = [r for r in rows[h + 1:] if any(c for c in r)]

    def numeric_column(i):
        cells = [r[i] for r in data if i < len(r) and r[i]]
        return bool(cells) and sum(number(c)[0] is not None for c in cells) > len(cells) / 2

    # « Step » avec 1, 2, 3 dessous, à côté d'un nom d'étape : le numéro de l'étape.
    # « Step 1: joined » avec des nombres dessous, seul : une colonne par étape.
    named = [i for i, k in enumerate(kinds) if k == "step" and not numeric_column(i)]
    kinds = [("order" if named else None) if k == "step" and numeric_column(i) else k for i, k in enumerate(kinds)]
    col = {k: [i for i, kk in enumerate(kinds) if kk == k] for k in HEAD}
    steps_by_group: dict[str, list[Step]] = {}

    def group_of(row):
        vals = [row[i] for i in col["group"] if i < len(row) and row[i]]
        return " / ".join(vals) if vals else "tous"

    if col["step"] or col["order"]:
        # une ligne par étape (et par jour, par groupe...)
        name_i = col["step"][0] if col["step"] else None
        order_i = col["order"][0] if col["order"] else None
        if col["users"]:
            value_i, pct_mode = col["users"][0], False
        elif col["pct"]:
            value_i, pct_mode = col["pct"][0], True
        else:
            # la première colonne numérique qui n'est ni l'étape ni le numéro
            cand = [i for i in range(len(header)) if i not in (name_i, order_i) and kinds[i] not in ("date", "group", "drop")]
            value_i = next((i for i in cand if any(number(r[i])[0] is not None for r in data if i < len(r))), None)
            pct_mode = False
            if value_i is None:
                return []
        for row in data:
            if value_i >= len(row):
                continue
            value, pct = number(row[value_i])
            if value is None:
                continue
            raw = row[name_i] if name_i is not None and name_i < len(row) else ""
            if order_i is not None and order_i < len(row) and number(row[order_i])[0] is not None:
                raw = f"{int(number(row[order_i])[0])} {raw}".strip()
            if not raw:
                continue
            order, sid = match_step(raw, known)
            is_pct = pct_mode or pct
            if is_pct and value <= 1 and not pct:
                value *= 100  # 0,45 → 45 %
            steps_by_group.setdefault(group_of(row), []).append(
                Step(order, sid, None if is_pct else value, value if is_pct else None))
    else:
        # une colonne par étape (et une ligne par jour, par groupe...)
        step_cols = [i for i, k in enumerate(kinds) if k not in ("date", "group", "drop", "pct") and header[i]]
        step_cols = [i for i in step_cols if any(number(r[i])[0] is not None for r in data if i < len(r))]
        for row in data:
            g = group_of(row)
            for i in step_cols:
                if i >= len(row):
                    continue
                value, pct = number(row[i])
                if value is None:
                    continue
                order, sid = match_step(header[i], known)
                steps_by_group.setdefault(g, []).append(Step(order, sid, None if pct else value, value if pct else None))
    funnels = [Funnel(g, tidy(st), source, period) for g, st in steps_by_group.items()]
    if len(funnels) > 1 and all(all(s.users is not None for s in f.steps) for f in funnels):
        everyone: list[Step] = []
        for f in funnels:
            everyone += [Step(s.order, s.id, s.users) for s in f.steps]
        funnels.insert(0, Funnel("tous", tidy(everyone), source, period))
    return funnels


LOG = re.compile(r"\[NinjaDuelFirst\]\s+(\S+)\s+(\S+)\s+([\d.]+)s(?:\s+\(stage\s+([^)]*)\))?")


def read_log(text: str, known: list[tuple[int, str]], source: str) -> list[Funnel]:
    """Les lignes `[NinjaDuelFirst] <joueur> <étape> <s>` du serveur : qui est allé jusqu'où."""
    reached: dict[str, dict[str, float]] = {}
    left: dict[str, int] = {}
    for user, step, secs, stage in LOG.findall(text):
        if step == "left":
            left[stage or "?"] = left.get(stage or "?", 0) + 1
            reached.setdefault(user, {})
            continue
        reached.setdefault(user, {}).setdefault(step, float(secs))
    if not reached:
        return []
    order_of = {n: o for o, n in known}
    names = {s for r in reached.values() for s in r}
    # les étapes inconnues du jeu se rangent par leur temps médian
    extra = sorted((n for n in names if n not in order_of),
                   key=lambda n: statistics.median([r[n] for r in reached.values() if n in r]))
    # les étapes du jeu jusqu'à la plus lointaine que la sortie contient : au-delà,
    # cette version ne les envoie peut-être pas encore (le rapport les dit absentes)
    seen = [o for o, n in known if n in names]
    ordered = [n for o, n in known if seen and o <= max(seen)] + extra
    steps = []
    for idx, name in enumerate(ordered):
        # dans l'entonnoir Roblox, une étape passée compte les précédentes : idem ici
        later = ordered[idx:]
        users = [r for r in reached.values() if any(s in r for s in later)]
        secs = [r[name] for r in reached.values() if name in r]
        steps.append(Step(order_of.get(name, len(known) + extra.index(name) + 1 if name in extra else None),
                          name, float(len(users)), None, secs))
    return [Funnel("tous", steps, source, left=left)]


def read(path: Path, known: list[tuple[int, str]]) -> list[Funnel]:
    text = read_text(path)
    if "[NinjaDuelFirst]" in text:
        return read_log(text, known, path.name)
    return read_table(text, known, path.name)


# ---------------------------------------------------------------- le rapport

def analyse(f: Funnel, known: list[tuple[int, str]]) -> dict:
    steps = f.steps
    base = steps[0].users if steps and steps[0].users else None
    rows, warnings = [], []
    prev = None
    for st in steps:
        share = st.pct if st.users is None else (100 * st.users / base if base else None)
        row = {"order": st.order, "id": st.id, "name": st.name, "users": st.users, "share": share}
        if st.seconds:
            row["median_s"] = round(statistics.median(st.seconds), 1)
        if prev is not None:
            if st.users is not None and prev["users"]:
                row["lost"] = prev["users"] - st.users
                row["lost_rate"] = 100 * row["lost"] / prev["users"]
            elif share is not None and prev["share"]:
                row["lost_points"] = prev["share"] - share
                row["lost_rate"] = 100 * (prev["share"] - share) / prev["share"]
            if row.get("lost_rate") is not None and row["lost_rate"] < -0.5:
                warnings.append(f"« {st.name} » compte plus de joueurs que « {prev['name']} » : ce n'est sans "
                                "doute pas un nombre de joueurs arrivés à l'étape (vérifier la colonne lue).")
        rows.append(row)
        prev = row
    pairs = [r for r in rows[1:] if r.get("lost_rate") is not None]
    worst = max(pairs, key=lambda r: (r.get("lost", r.get("lost_points", 0)), r["lost_rate"]), default=None)
    worst_rate = max(pairs, key=lambda r: r["lost_rate"], default=None)
    ids = {norm(r["id"]) for r in rows}
    missing = [label(n) for _, n in known if norm(n) not in ids]
    unknown = [r["name"] for r in rows if known and norm(r["id"]) not in {norm(n) for _, n in known}]
    if base is not None and base < SMALL:
        warnings.append(f"{int(base)} joueurs à la première étape : c'est une piste, pas une preuve.")
    return {"group": f.group, "source": f.source, "period": f.period, "steps": rows,
            "worst": worst and {"from": rows[rows.index(worst) - 1]["name"], "to": worst["name"],
                                "lost": worst.get("lost"), "lost_points": worst.get("lost_points"),
                                "lost_rate": worst["lost_rate"]},
            "worst_rate": worst_rate and {"from": rows[rows.index(worst_rate) - 1]["name"], "to": worst_rate["name"],
                                          "lost_rate": worst_rate["lost_rate"]},
            "missing": missing, "unknown": unknown, "left": f.left, "warnings": warnings}


def fmt(x: float | None, digits: int = 0) -> str:
    if x is None:
        return "—"
    s = f"{x:,.{digits}f}".replace(",", " ").replace(".", ",")
    return "0" if s.lstrip("-").strip("0,") == "" else s


def minus(rate: float) -> str:
    """Une perte : « −41 », « 0 », ou « +3 » quand l'étape compte plus de joueurs que la précédente."""
    r = round(rate)
    return "0" if r == 0 else (f"−{fmt(r)}" if r > 0 else f"+{fmt(-r)}")


def text(report: dict) -> str:
    lines = []
    title = "Entonnoir des nouveaux joueurs"
    if report["group"] != "tous":
        title += f" — {report['group']}"
    lines.append(title + (f" ({report['source']}" + (f", {report['period']}" if report["period"] else "") + ")"
                          if report["source"] else ""))
    width = max([len(r["name"]) for r in report["steps"]] + [8])
    for r in report["steps"]:
        num = f"{r['order']:>2}" if r["order"] is not None else " ·"
        cells = [f" {num} {r['name']:<{width}}"]
        cells.append(f"{fmt(r['users']):>8}" if r["users"] is not None else f"{'':>8}")
        cells.append(f"{fmt(r['share'], 0):>5} %" if r["share"] is not None else f"{'':>7}")
        if r.get("lost") is not None:
            gone = r["lost"]
            cells.append(f"   {minus(r['lost_rate'])} % ({fmt(gone)} {'part' if abs(gone) < 2 else 'partent'})")
        elif r.get("lost_points") is not None:
            cells.append(f"   {minus(r['lost_rate'])} % ({fmt(r['lost_points'], 1)} points de moins)")
        if r.get("median_s") is not None:
            cells.append(f"   à {fmt(r['median_s'], 1)} s (médiane)")
        lines.append("".join(cells))
    w = report["worst"]
    if w:
        who = (f"{fmt(w['lost'])} joueur{'s' if w['lost'] >= 2 else ''}, {fmt(w['lost_rate'], 0)} % de ceux qui arrivent à « {w['from']} »"
               if w["lost"] is not None else f"{fmt(w['lost_rate'], 0)} % de ceux qui arrivent à « {w['from']} »")
        lines.append(f"Où ils partent le plus : entre « {w['from']} » et « {w['to']} » ({who}).")
        wr = report["worst_rate"]
        if wr and (wr["from"], wr["to"]) != (w["from"], w["to"]):
            lines.append(f"La plus forte part : entre « {wr['from']} » et « {wr['to']} » ({fmt(wr['lost_rate'], 0)} %).")
    if report["left"]:
        parts = ", ".join(f"{k} ({v})" for k, v in sorted(report["left"].items(), key=lambda kv: -kv[1]))
        lines.append(f"Partis avant la fin du premier duel, pendant : {parts}.")
    if report["missing"]:
        lines.append("Étapes du jeu absentes : " + ", ".join(report["missing"])
                     + " (pas encore envoyées par cette version, ou personne n'y est arrivé).")
    if report["unknown"]:
        lines.append("Étapes inconnues du jeu actuel : " + ", ".join(report["unknown"]) + ".")
    for wmsg in report["warnings"]:
        lines.append("Attention : " + wmsg)
    return "\n".join(lines)


def main(argv=None) -> int:
    ap = argparse.ArgumentParser(description="Lit l'entonnoir des nouveaux joueurs (export Roblox ou sortie du serveur).")
    ap.add_argument("files", nargs="*", type=Path, help="export CSV du tableau de bord, saisie à la main, ou sortie du serveur")
    ap.add_argument("--json", action="store_true", help="le rapport en JSON")
    ap.add_argument("--etapes", action="store_true", help="les étapes que le jeu envoie, lues dans src/")
    ap.add_argument("--src", type=Path, default=SRC, help="le dossier src du jeu (par défaut celui de ce dépôt)")
    args = ap.parse_args(argv)
    known = game_steps(args.src) if args.src.exists() else []
    if args.etapes or not args.files:
        if not known:
            print("Aucune étape d'entonnoir trouvée dans", args.src)
            return 1
        for order, name in known:
            print(f"{order:>2} {name:<14} {label(name)}")
        return 0
    reports = []
    for path in args.files:
        funnels = read(path, known)
        if not funnels:
            print(f"{path.name} : aucune étape lue. Le format n'est pas reconnu ; envoyer le fichier à l'OUTILLEUR.",
                  file=sys.stderr)
            return 1
        reports += [analyse(f, known) for f in funnels]
    if args.json:
        print(json.dumps(reports, ensure_ascii=False, indent=2))
    else:
        print("\n\n".join(text(r) for r in reports))
    return 0


if __name__ == "__main__":
    sys.exit(main())
