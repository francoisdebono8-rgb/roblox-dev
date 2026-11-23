#!/usr/bin/env python3
"""The survey of the player's screens, with the red lines of the output (OUTILLEUR, passe commune 1).

In a Play of the game's place (DEC-052: PLACES/NinjaDuel.rbxlx, no copy), NDScreenTour is
injected in the Client first (python3 tools/robots/inject.py screens). The tour is played as a player: a click (robloxstudio-mcp simulate_mouse_input at the centre --find
gives) or a key, then a capture of the viewport (capture_screenshot). Between two screens:

    python3 tools/screens/releve.py --look            Client: buttons, big texts, new red lines of the client
    python3 tools/screens/releve.py --find TEXT       Client: the centre of the button that says TEXT
    python3 tools/screens/releve.py --red-server [N]  Server: the red and orange lines from line N on

The Studio output itself (both sides, in order) is read with robloxstudio-mcp get_runtime_logs,
its cursor kept from one screen to the next: what it gives at each screen goes in the step.

The survey is written as a JSON (see mesures/): the steps, their image, how they were
reached, the red lines of each side, what was seen. Then:

    python3 tools/screens/releve.py --page RELEVE.json [--avant OLD.json] --html R.html [--md R.md]
           [--images DIR] [--avant-images DIR]   where the page finds each survey's images
"""
import html
import json
import os
import re
import sys

REQ = '(_G.NDScreenTour or error("NDScreenTour absent : python3 tools/robots/inject.py screens (pendant le Play)"))'
RED_SERVER = ('local out={{}} local all=game:GetService("LogService"):GetLogHistory() '
              'for i={n},#all do local m=all[i] '
              'if m.messageType==Enum.MessageType.MessageError then table.insert(out,"red "..i..": "..string.sub(m.message,1,300)) '
              'elseif m.messageType==Enum.MessageType.MessageWarning then table.insert(out,"orange "..i..": "..string.sub(m.message,1,300)) end end '
              'return game:GetService("HttpService"):JSONEncode({{n=#all,lines=out}})')


def snippet(args):
    if args[0] == "--look":
        return f"return {REQ}.look()"
    if args[0] == "--find":
        text = " ".join(args[1:]).replace('"', "'")
        return f'return {REQ}.find("{text}")'
    if args[0] == "--red-server":
        return RED_SERVER.format(n=int(args[1]) if len(args) > 1 else 1)
    return None


def load(path):
    with open(path, encoding="utf-8") as f:
        return json.load(f)


def kind(line: str) -> str:
    """A red line, sorted by what it is about."""
    low = line.lower()
    if "editablemesh" in low or "memory budget" in low:
        return "maillages (budget mémoire)"
    if "http" in low or "asset" in low or "failed to load" in low:
        return "chargement d'asset"
    if "datastore" in low:
        return "DataStore"
    if "infinite yield" in low:
        return "attente infinie"
    return "script"


LEVELS = {"red": "rouge (erreur)", "orange": "orange (avertissement)"}


def summary(rel):
    """The red lines (errors) and the orange ones (warnings) of the output, both sides."""
    steps = rel.get("steps", [])
    lines = []
    for s in steps:
        for level in LEVELS:
            for side in ("client", "server"):
                for line in s.get(level, {}).get(side, []):
                    lines.append((level, side, line))
    counts = {}
    for level, side, line in lines:
        key = (LEVELS[level], side, kind(line), re.sub(r"\d{4,}", "#", line)[:140])
        counts[key] = counts.get(key, 0) + 1
    red = [l for l in lines if l[0] == "red"]
    return {"steps": len(steps), "red": len(red), "orange": len(lines) - len(red),
            "client": sum(1 for r in red if r[1] == "client"), "server": sum(1 for r in red if r[1] == "server"),
            "kinds": sorted(counts.items(), key=lambda kv: (kv[0][0], -kv[1])),
            "notes": sum(len(s.get("notes", [])) for s in steps)}


def markdown(rel, old=None):
    s = summary(rel)
    L = [f"# Relevé des écrans — {rel.get('title', '')}", "",
         f"Place : {rel.get('place', '?')}. Écran : {rel.get('screen', '?')}. {s['steps']} écrans, "
         f"**{s['red']} lignes rouges** ({s['client']} client, {s['server']} serveur), {s['orange']} orange, {s['notes']} remarques.", ""]
    if old:
        o = summary(old)
        L += [f"Avant ({old.get('place', '?')}) : {o['steps']} écrans, {o['red']} lignes rouges, {o['orange']} orange, {o['notes']} remarques.", ""]
    if rel.get("caveat"):
        L += [f"*{rel['caveat']}*", ""]
    if s["kinds"]:
        L += ["## La sortie, regroupée", "", "| Niveau | Côté | Genre | Ligne | Fois |", "|---|---|---|---|---|"]
        for (level, side, k, line), n in s["kinds"][:30]:
            L.append(f"| {level} | {side} | {k} | `{line}` | {n} |")
        L.append("")
    L += ["## Écran par écran", ""]
    for i, st in enumerate(rel.get("steps", []), 1):
        L += [f"### {i}. {st.get('name')}", "", f"*Comment* : {st.get('how', '')}"]
        if st.get("image"):
            L.append(f"![{st.get('name')}]({st['image']})")
        for n in st.get("notes", []):
            L.append(f"- {n}")
        for level in LEVELS:
            for side in ("client", "server"):
                for line in st.get(level, {}).get(side, [])[:8]:
                    L.append(f"- {LEVELS[level]} ({side}) : `{line[:200]}`")
        L.append("")
    return "\n".join(L)


def page(rel, old=None, images="", old_images=""):
    """One page: the steps side by side with the old survey when there is one."""
    s = summary(rel)
    olds = {st.get("key") or st.get("name"): st for st in (old or {}).get("steps", [])}

    def esc(t):
        return html.escape(str(t))

    def img(st, base):
        if not st or not st.get("image"):
            return "<div class=none>—</div>"
        src = os.path.join(base, st["image"]) if base else st["image"]
        return f"<img loading=lazy src='{esc(src)}' alt='{esc(st.get('name'))}'>"

    def reds(st):
        out = []
        for level in LEVELS:
            for side in ("client", "server"):
                for line in (st or {}).get(level, {}).get(side, [])[:6]:
                    out.append(f"<li class={level}><b>{side}</b> {esc(line[:220])}</li>")
        return "".join(out)
    cards = []
    for i, st in enumerate(rel.get("steps", []), 1):
        before = olds.get(st.get("key") or st.get("name"))
        notes = "".join(f"<li>{esc(n)}</li>" for n in st.get("notes", []))
        pair = (f"<div class=pair><figure><figcaption>avant</figcaption>{img(before, old_images)}</figure>"
                f"<figure><figcaption>après</figcaption>{img(st, images)}</figure></div>") if old else img(st, images)
        cards.append(f"<section><h2>{i}. {esc(st.get('name'))}</h2><p class=how>{esc(st.get('how', ''))}</p>{pair}"
                     f"<ul>{notes}{reds(st)}</ul></section>")
    kinds = "".join(f"<tr><td>{esc(level)}</td><td>{esc(side)}</td><td>{esc(k)}</td><td><code>{esc(line)}</code></td><td>{n}</td></tr>"
                    for (level, side, k, line), n in s["kinds"][:30])
    css = (":root{--bg:#f7f4ee;--fg:#1d1b18;--mute:#6b645a;--line:#d9d2c4;--red:#b3261e;--orange:#9a5b00;--card:#fffdf8}"
           "@media (prefers-color-scheme:dark){:root{--bg:#171512;--fg:#ece7de;--mute:#a39b8e;--line:#3a352d;--red:#f2867c;--orange:#f0b45a;--card:#201d19}}"
           "body{background:var(--bg);color:var(--fg);font:15px/1.5 system-ui,sans-serif;margin:0;padding:16px}"
           "main{max-width:1200px;margin:auto}section{background:var(--card);border:1px solid var(--line);border-radius:8px;padding:12px;margin:14px 0}"
           "img{max-width:100%;border-radius:4px;display:block}.pair{display:grid;grid-template-columns:1fr 1fr;gap:10px}"
           "@media (max-width:700px){.pair{grid-template-columns:1fr}}figure{margin:0}figcaption{color:var(--mute);font-size:13px}"
           ".how{color:var(--mute);margin:0 0 8px}.red{color:var(--red)}.orange{color:var(--orange)}.t{overflow-x:auto}.none{color:var(--mute);padding:20px}"
           "table{border-collapse:collapse}td,th{border:1px solid var(--line);padding:4px 8px;text-align:left}"
           "h1{font-size:24px}h2{font-size:17px;margin:0 0 4px}code{font-size:12px}")
    head = (f"<h1>Relevé des écrans — {esc(rel.get('title', ''))}</h1><p>Place {esc(rel.get('place', '?'))}, écran "
            f"{esc(rel.get('screen', '?'))} : {s['steps']} écrans, <b class=red>{s['red']} lignes rouges</b> "
            f"({s['client']} client, {s['server']} serveur), {s['orange']} orange, {s['notes']} remarques.</p>"
            + (f"<p class=how>{esc(rel['caveat'])}</p>" if rel.get("caveat") else "")
            + (f"<p class=how>Avant : {esc(old.get('place', '?'))}, {summary(old)['steps']} écrans, {summary(old)['red']} lignes rouges, "
               f"{summary(old)['orange']} orange.</p>" if old else ""))
    table = (f"<h2>La sortie, regroupée</h2><div class=t><table><tr><th>Niveau</th><th>Côté</th><th>Genre</th><th>Ligne</th><th>Fois</th></tr>"
             f"{kinds}</table></div>") if kinds else ""
    return (f"<!doctype html><html lang=fr><meta charset=utf-8><meta name=viewport content='width=device-width,initial-scale=1'>"
            f"<title>Relevé des écrans</title><style>{css}</style><body><main>{head}{table}{''.join(cards)}</main></body></html>")


def main(argv=None):
    args = argv if argv is not None else sys.argv[1:]
    if not args:
        print(__doc__)
        return 2
    code = snippet(args)
    if code:
        print(code)
        return 0
    if args[0] != "--page":
        print(__doc__)
        return 2
    rel = load(args[1])
    opts = dict(zip(args[2::2], args[3::2]))
    old = load(opts["--avant"]) if "--avant" in opts else None
    if "--html" in opts:
        with open(opts["--html"], "w", encoding="utf-8") as f:
            f.write(page(rel, old, opts.get("--images", ""), opts.get("--avant-images", "")))
    if "--md" in opts:
        with open(opts["--md"], "w", encoding="utf-8") as f:
            f.write(markdown(rel, old) + "\n")
    if "--html" not in opts and "--md" not in opts:
        print(markdown(rel, old))
    return 0


if __name__ == "__main__":
    sys.exit(main())
