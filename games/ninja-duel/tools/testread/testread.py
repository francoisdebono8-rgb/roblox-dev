#!/usr/bin/env python3
"""La lecture du test à 3–5 joueurs (OUTILLEUR, étape 5 « Ouverture », DEC-049).

Une page faite des signalements (bouton SIGNALER) et des relevés par joueur de la place
de test privée, plus les réponses aux trois questions que François ajoute. Le format lu
est dans tools/testread/CONTRAT.md.

    python3 tools/testread/testread.py --dump            # le code à coller dans Studio (Édition de la place de test)
    python3 tools/testread/testread.py DUMP.json [--reponses R.json] --html page.html [--md page.md]
    python3 tools/testread/testread.py --exemple DUMP.json   # un dump d'exemple, données inventées (pour voir la page)

La page dit :
  - l'entonnoir : combien de joueurs atteignent chaque étape, et en combien de temps ;
  - chaque joueur : son temps par écran, ses duels, ce qu'il a quitté, la course, ses
    signalements et ses réponses ;
  - tous les signalements, par lieu, dans l'ordre ;
  - ce qui revient (le même lieu signalé par plusieurs joueurs).
Elle ne décide pas ce qui est bloquant : c'est au DEV, avec François.
"""
import html
import json
import statistics
import sys

FUNNEL = ["joined", "inspiration", "dressed", "started", "hit", "duel", "won", "bought", "node"]
FUNNEL_FR = {"joined": "arrivé", "inspiration": "inspiration choisie", "dressed": "habillé", "started": "1er combat lancé",
             "hit": "1er coup qui touche", "duel": "1er duel fini", "won": "1er duel gagné", "bought": "1er achat (Ryō)",
             "node": "1er nœud de l'arbre"}
QUESTIONS = [("pensait", "Qu'est-ce que tu pensais pouvoir faire ?"), ("perdu", "Pourquoi as-tu perdu ?"),
             ("retenter", "Qu'as-tu envie de retenter ?")]

# The DEV's live store (Server/Reports, 23/11: one key per report, "r_<at>_<UserId>_<n>"),
# and the store of the per-player records asked in CONTRAT.md (keys "s_" or "session_").
STORES = ["NinjaDuelReports", "NinjaDuelTest"]
STORE = STORES[0]

DUMP = """-- (OUTILLEUR, tools/testread) Édition de la place de test, accès aux API activé :
-- les signalements et les relevés des DataStore %s, avec les pseudos, en JSON.
local H=game:GetService("HttpService")
local out={}
local users={}
for _,name in {%s} do
	local okS,ds=pcall(function() return game:GetService("DataStoreService"):GetDataStore(name) end)
	if okS then
		local okP,pages=pcall(function() return ds:ListKeysAsync() end)
		while okP and pages do
			for _,k in pages:GetCurrentPage() do
				local ok,v=pcall(function() return ds:GetAsync(k.KeyName) end)
				if ok and type(v)=="string" then local ok2,t=pcall(H.JSONDecode,H,v) v=ok2 and t or nil end
				if ok and type(v)=="table" then
					v.key=k.KeyName;v.store=name;table.insert(out,v)
					local id=v.user or v.userId
					if type(id)=="number" then users[id]=true end
				end
			end
			if pages.IsFinished then break end
			pages:AdvanceToNextPageAsync()
		end
	end
end
for id in users do
	local ok,n=pcall(function() return game:GetService("Players"):GetNameFromUserIdAsync(id) end)
	if ok then table.insert(out,{kind="name",userId=id,name=n}) end
end
return H:JSONEncode(out)
""" % (" et ".join(STORES), ",".join('"%s"' % n for n in STORES))


def mmss(s):
    if s is None:
        return "—"
    s = int(round(s))
    return f"{s // 60}:{s % 60:02d}"


def _report(d):
    """A report in the page's form. The DEV's live one (Server/Reports) is {user, text, at,
    phase, kit, where = "<écran> @ x,y,z", version}; the contract's own fields are kept."""
    r = dict(d)
    r["kind"] = "report"
    if r.get("userId") is None and r.get("user") is not None:
        r["userId"] = r["user"]
    if r.get("build") is None and r.get("version"):
        r["build"] = r["version"]
    where = r.get("where")
    if isinstance(where, str) and r.get("position") is None:
        place, _, at = where.partition(" @ ")
        if not at and place.count(",") == 2:
            place, at = "", place
        try:
            r["position"] = [float(x) for x in at.split(",")] if at else None
        except ValueError:
            r["position"] = None
        r["where"] = place or ("?" if at else where)
    return r


def _is(d, kind, prefixes):
    key = str(d.get("key", ""))
    return d.get("kind") == kind or any(key.startswith(p) for p in prefixes)


def load(path):
    with open(path, encoding="utf-8") as f:
        data = json.load(f)
    if isinstance(data, dict):
        data = data.get("items") or data.get("records") or []
    names = {d.get("userId"): d.get("name") for d in data if d.get("kind") == "name"}
    sessions = [d for d in data if _is(d, "session", ("session_", "s_"))]
    reports = [_report(d) for d in data if _is(d, "report", ("report_", "r_")) and not _is(d, "session", ("session_", "s_"))]
    # a player's last record is the one kept (records are written every 2 minutes)
    last = {}
    for s in sessions:
        uid = s.get("userId")
        if uid not in last or (s.get("seconds") or 0) >= (last[uid].get("seconds") or 0):
            last[uid] = s
    for r in reports:
        if not r.get("name"):
            r["name"] = names.get(r.get("userId")) or (last.get(r.get("userId")) or {}).get("name") or f"joueur {r.get('userId')}"
        # the seconds since he arrived, from his record when the report has none
        joined = (last.get(r.get("userId")) or {}).get("joined")
        if r.get("session") is None and joined and r.get("at"):
            r["session"] = r["at"] - joined
    return sorted(reports, key=lambda r: r.get("at") or 0), sorted(last.values(), key=lambda s: s.get("joined") or 0)


def funnel(sessions):
    rows = []
    n = len(sessions)
    for step in FUNNEL:
        times = [s["funnel"][step] for s in sessions if isinstance(s.get("funnel"), dict) and s["funnel"].get(step) is not None]
        rows.append({"step": step, "label": FUNNEL_FR[step], "players": len(times), "of": n,
                     "median": statistics.median(times) if times else None, "max": max(times) if times else None})
    # in the order players reach them (the game's numbering is Matches.FUNNEL's, older than the first combat)
    rows.sort(key=lambda f: (f["median"] is None, f["median"] if f["median"] is not None else 0))
    return rows


def repeated(reports):
    by = {}
    for r in reports:
        by.setdefault(r.get("where") or "?", set()).add(r.get("userId"))
    return sorted(((w, len(u)) for w, u in by.items() if len(u) > 1), key=lambda x: -x[1])


def read(dump, answers=None):
    reports, sessions = load(dump)
    answers = answers or {}
    names = {s.get("userId"): s.get("name") for s in sessions}
    for r in reports:
        names.setdefault(r.get("userId"), r.get("name"))
    with open(dump, encoding="utf-8") as f:
        raw = json.load(f)
    example_ = isinstance(raw, list) and any(d.get("kind") == "meta" and d.get("example") for d in raw)
    return {"reports": reports, "sessions": sessions, "funnel": funnel(sessions), "repeated": repeated(reports), "example": example_,
            "answers": answers, "names": names,
            "builds": sorted({str(x.get("build")) for x in reports + sessions if x.get("build")})}


def markdown(r):
    lines = [f"# Lecture du test : {len(r['sessions'])} joueurs, {len(r['reports'])} signalements", ""]
    if r.get("example"):
        lines += ["**EXEMPLE : données inventées pour montrer la page, pas un vrai test.**", ""]
    if r["builds"]:
        lines.append("Version : " + ", ".join(r["builds"]) + ".")
        lines.append("")
    lines += ["## L'entonnoir", "", "| Étape | Joueurs | Médiane | Le plus tard |", "|---|---|---|---|"]
    for f in r["funnel"]:
        lines.append(f"| {f['label']} | {f['players']} / {f['of']} | {mmss(f['median'])} | {mmss(f['max'])} |")
    lines += ["", "## Les joueurs", ""]
    for s in r["sessions"]:
        d = s.get("duels") or {}
        lines.append(f"- **{s.get('name')}** : {mmss(s.get('seconds'))} ; duels {d.get('played', 0)} "
                     f"({d.get('won', 0)} gagnés, {d.get('lost', 0)} perdus, {d.get('left', 0)} quittés)")
    lines += ["", "## Les signalements", ""]
    for rep in r["reports"]:
        lines.append(f"- {mmss(rep.get('session'))} · {rep.get('where', '?')} · {r['names'].get(rep.get('userId'))} : « {rep.get('text', '')} »")
    return "\n".join(lines) + "\n"


CSS = """
:root{--bg:#f4f1ea;--card:#fffdf8;--ink:#1c1a17;--soft:#6f685d;--line:#ddd6c8;--red:#b8322a;--bar:#2f6f8f}
@media (prefers-color-scheme:dark){:root:not([data-theme=light]){--bg:#171513;--card:#211e1b;--ink:#ece6da;--soft:#a39b8d;--line:#3a352f;--red:#e0574d;--bar:#5aa7c9}}
:root[data-theme=dark]{--bg:#171513;--card:#211e1b;--ink:#ece6da;--soft:#a39b8d;--line:#3a352f;--red:#e0574d;--bar:#5aa7c9}
*{box-sizing:border-box} body{margin:0;background:var(--bg);color:var(--ink);font:15px/1.45 system-ui,sans-serif}
main{max-width:1100px;margin:0 auto;padding:20px 16px 48px} h1{margin:0 0 4px;font-size:24px} h2{margin:28px 0 10px;font-size:18px}
.soft{color:var(--soft)} .grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(320px,1fr));gap:12px}
.card{background:var(--card);border:1px solid var(--line);border-radius:8px;padding:14px}
table{border-collapse:collapse;width:100%;background:var(--card)} td,th{border-bottom:1px solid var(--line);padding:7px 8px;text-align:left;vertical-align:top}
.bar{height:10px;background:var(--line);border-radius:5px;overflow:hidden;display:flex} .bar i{display:block;height:100%}
.tag{display:inline-block;border:1px solid var(--line);border-radius:10px;padding:0 8px;font-size:12px;margin:2px 4px 2px 0}
.q{margin:6px 0 0} .q b{display:block;font-size:12px;color:var(--soft)} .warn{color:var(--red);font-weight:600}
.example{background:var(--red);color:#fff;padding:6px 10px;border-radius:6px;display:inline-block;margin:8px 0}
"""
PALETTE = ["#2f6f8f", "#b8322a", "#7a8b3c", "#c58a2a", "#6b5b95", "#3c8d7a", "#8a5a44", "#5a6b7a"]


def page(r, example=False):
    e = html.escape
    screens = sorted({k for s in r["sessions"] for k in (s.get("screens") or {})})
    colour = {k: PALETTE[i % len(PALETTE)] for i, k in enumerate(screens)}
    head = (f"<h1>Lecture du test</h1><p class='soft'>{len(r['sessions'])} joueurs · {len(r['reports'])} signalements"
            + (" · version " + e(", ".join(r["builds"])) if r["builds"] else "") + "</p>")
    if example:
        head += "<p class='example'>EXEMPLE : données inventées pour montrer la page, pas un vrai test.</p>"
    rows = "".join(
        f"<tr><td>{e(f['label'])}</td><td>{f['players']} / {f['of']}</td><td>{mmss(f['median'])}</td><td>{mmss(f['max'])}</td>"
        f"<td style='width:34%'><div class='bar'><i style='width:{100 * f['players'] / max(1, f['of']):.0f}%;background:var(--bar)'></i></div></td></tr>"
        for f in r["funnel"])
    funnel_html = ("<h2>L'entonnoir</h2><table><tr><th>Étape</th><th>Joueurs</th><th>Médiane</th><th>Le plus tard</th><th></th></tr>"
                   + rows + "</table>")
    cards = []
    for s in r["sessions"]:
        total = sum((s.get("screens") or {}).values()) or 1
        bar = "".join(f"<i title='{e(k)} {mmss(v)}' style='width:{100 * v / total:.1f}%;background:{colour[k]}'></i>"
                      for k, v in sorted((s.get("screens") or {}).items(), key=lambda x: -x[1]))
        legend = "".join(f"<span class='tag' style='border-color:{colour[k]}'>{e(k)} {mmss(v)}</span>"
                         for k, v in sorted((s.get("screens") or {}).items(), key=lambda x: -x[1]))
        d = s.get("duels") or {}
        quit_ = "".join(f"<span class='tag warn'>quitte {e(str(q.get('what')))} à {mmss(q.get('at'))}</span>" for q in s.get("quit") or [])
        race = s.get("race") or {}
        mine = [rep for rep in r["reports"] if rep.get("userId") == s.get("userId")]
        reps = "".join(f"<li>{mmss(rep.get('session'))} · {e(str(rep.get('where', '?')))} : « {e(str(rep.get('text', '')))} »</li>" for rep in mine)
        ans = r["answers"].get(str(s.get("userId"))) or {}
        qa = "".join(f"<p class='q'><b>{e(q)}</b>{e(str(ans[k]))}</p>" for k, q in QUESTIONS if ans.get(k))
        cards.append(f"<div class='card'><h3 style='margin:0'>{e(str(s.get('name')))}</h3>"
                     f"<p class='soft' style='margin:2px 0 8px'>{mmss(s.get('seconds'))} de jeu · kit {e(str(s.get('kit', '?')))}</p>"
                     f"<div class='bar' style='height:14px'>{bar}</div><p>{legend}</p>"
                     f"<p>Duels : {d.get('played', 0)} joués, {d.get('won', 0)} gagnés, {d.get('lost', 0)} perdus, {d.get('left', 0)} quittés"
                     + (f" · course : {race.get('runs', 0)} essais, meilleur {race.get('best')} s" if race.get("runs") else "")
                     + f"</p><p>{quit_}</p>"
                     + (f"<p><b>Ses signalements</b></p><ul>{reps}</ul>" if reps else "")
                     + qa + "</div>")
    players = "<h2>Les joueurs</h2><div class='grid'>" + "".join(cards) + "</div>"
    by = {}
    for rep in r["reports"]:
        by.setdefault(rep.get("where") or "?", []).append(rep)
    groups = []
    for where, reps in sorted(by.items(), key=lambda x: -len(x[1])):
        lines = "".join(
            f"<tr><td>{mmss(rep.get('session'))}</td><td>{e(str(r['names'].get(rep.get('userId'))))}</td>"
            f"<td>« {e(str(rep.get('text', '')))} »</td><td class='soft'>{e(str(rep.get('phase', '')))}"
            + (f" · {', '.join(str(round(v)) for v in rep['position'])}" if rep.get("position") else "") + "</td></tr>" for rep in reps)
        groups.append(f"<h3>{e(where)} ({len(reps)})</h3><table><tr><th>Quand</th><th>Qui</th><th>Ce qu'il dit</th><th>Où</th></tr>{lines}</table>")
    again = "".join(f"<li><b>{e(w)}</b> : signalé par {n} joueurs</li>" for w, n in r["repeated"])
    reports = ("<h2>Les signalements</h2>" + (f"<p>Ce qui revient :</p><ul>{again}</ul>" if again else "")
               + ("".join(groups) or "<p class='soft'>Aucun signalement.</p>")
               + "<p class='soft'>Ce qui est bloquant se décide avec le DEV et François : la page ne le décide pas.</p>")
    return (f"<!doctype html><html lang='fr'><head><meta charset='utf-8'><meta name='viewport' content='width=device-width,initial-scale=1'>"
            f"<title>Lecture du test</title><style>{CSS}</style></head><body><main>{head}{funnel_html}{players}{reports}</main></body></html>\n")


def example():
    """A made-up dump to show the page (EXEMPLE)."""
    base = 1795400000
    sess = [
        {"kind": "session", "userId": 1, "name": "Testeur A", "joined": base, "left": base + 1800, "seconds": 1800, "kit": "Legion",
         "screens": {"Konoha": 900, "Duel": 600, "Shop": 150, "Tree": 90, "Race": 60},
         "funnel": {"joined": 0, "started": 38, "hit": 45, "duel": 92, "won": 92, "inspiration": 140, "dressed": 170, "bought": 820, "node": 1300},
         "duels": {"played": 7, "won": 4, "lost": 3, "left": 0}, "quit": [], "race": {"runs": 3, "best": 34.2}, "build": "acfb00d6"},
        {"kind": "session", "userId": 2, "name": "Testeur B", "joined": base + 60, "left": base + 1260, "seconds": 1200, "kit": "Lion",
         "screens": {"Konoha": 700, "Duel": 380, "Shop": 120},
         "funnel": {"joined": 0, "started": 55, "hit": 70, "duel": 140, "won": 140, "inspiration": 200, "dressed": 260},
         "duels": {"played": 4, "won": 1, "lost": 2, "left": 1}, "quit": [{"what": "duel", "at": 1150}], "build": "acfb00d6"},
        {"kind": "session", "userId": 3, "name": "Testeur C", "joined": base + 30, "left": base + 630, "seconds": 600, "kit": "Leaf",
         "screens": {"Konoha": 420, "Duel": 180}, "funnel": {"joined": 0, "started": 120, "hit": 131},
         "duels": {"played": 1, "won": 0, "lost": 0, "left": 1}, "quit": [{"what": "duel", "at": 300}], "build": "acfb00d6"},
    ]
    reps = [
        {"kind": "report", "userId": 2, "name": "Testeur B", "at": base + 900, "session": 840, "text": "je reste bloqué sous un toit",
         "where": "Konoha", "phase": "Selection", "position": [120.4, 3.0, -88.1], "build": "acfb00d6"},
        {"kind": "report", "userId": 3, "name": "Testeur C", "at": base + 320, "session": 290, "text": "je comprends pas comment faire le jutsu",
         "where": "Duel", "phase": "Duel", "build": "acfb00d6"},
        {"kind": "report", "userId": 1, "name": "Testeur A", "at": base + 700, "session": 700, "text": "la carte cache tout",
         "where": "Konoha", "phase": "Selection", "build": "acfb00d6"},
    ]
    return [{"kind": "meta", "example": True, "note": "EXEMPLE : données inventées pour montrer la page"}] + sess + reps


def main(argv=None):
    args = argv if argv is not None else sys.argv[1:]
    if not args:
        print(__doc__)
        return 2
    if args[0] == "--dump":
        print(DUMP)
        return 0
    if args[0] == "--exemple":
        with open(args[1], "w", encoding="utf-8") as f:
            json.dump(example(), f, ensure_ascii=False, indent=1)
        print(args[1])
        return 0
    dump = args[0]
    answers = {}
    if "--reponses" in args:
        with open(args[args.index("--reponses") + 1], encoding="utf-8") as f:
            answers = json.load(f)
    r = read(dump, answers)
    sample = r["example"]
    if "--html" in args:
        with open(args[args.index("--html") + 1], "w", encoding="utf-8") as f:
            f.write(page(r, example=sample))
    if "--md" in args:
        with open(args[args.index("--md") + 1], "w", encoding="utf-8") as f:
            f.write(markdown(r))
    print(markdown(r))
    return 0


if __name__ == "__main__":
    sys.exit(main())
