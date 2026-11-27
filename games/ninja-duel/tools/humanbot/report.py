#!/usr/bin/env python3
"""The human robot's report (OUTILLEUR, 27/11): what went wrong while the hands played.

    python3 tools/humanbot/report.py MESURE.json [--md RAPPORT.md]
    python3 tools/humanbot/report.py --start         Client : _G.NDHumanWatch.start(true)
    python3 tools/humanbot/report.py --read          Client : le journal compact (JSON)
    python3 tools/humanbot/report.py --server        Serveur : _G.NDHumanServer.read()

MESURE.json is {"client": the compact journal (--read), "server": NDHumanServer.read()}.
The compact journal keeps the bugs with the steps before them, the scenes, the menus
opened, the long frames, and the counts of clicks, keys and buttons that answered.
"""
import json
import sys

WATCH = '(_G.NDHumanWatch or error("NDHumanWatch absent : python3 tools/robots/inject.py human (pendant le Play)"))'
SERVER = '(_G.NDHumanServer or error("NDHumanServer absent : python3 tools/robots/inject.py --server humanserver"))'
# The compact journal, made in the client (the whole one repeats the steps of each bug).
READ_LUA = """local H=game:GetService("HttpService")
local j=H:JSONDecode(%s.read())
local function short(s) return (tostring(s or ""):gsub(" @%%-?%%d+,%%-?%%d+","")) end
local bugs={}
for _,x in j.bugs do
 local st={} for _,s in x.steps do table.insert(st,{t=s.t,k=s.kind=="in" and s.key or s.kind,on=s.on and short(s.on) or nil}) end
 table.insert(bugs,{kind=x.kind,key=x.key,count=x.count,t=x.t,stage=x.state and x.state.stage,menus=x.state and x.state.menus,mouse=x.state and x.state.mouse,place=x.state and x.state.place,detail=x.detail,steps=st})
end
local hitches,ev,clicks,keys,acts={}, {},0,0,0
for _,r in j.rows do
 if r.kind=="hitch" then table.insert(hitches,{t=r.t,dt=r.dt})
 elseif r.kind=="in" and r.down then if r.key:find("Mouse") then clicks+=1 else keys+=1 end
 elseif r.kind=="act" then acts+=1
 elseif r.kind=="scene" or r.kind=="menus" or r.kind=="note" then table.insert(ev,{t=r.t,kind=r.kind,v=r.open or r.value or r.text}) end
end
return H:JSONEncode({seconds=j.seconds,clicks=clicks,keys=keys,answers=acts,hitches=hitches,events=ev,bugs=bugs})""" % WATCH

# What each kind of bug means for a player (the witness's names).
MEANING = {
    "erreur rouge": "une ligne rouge dans la sortie du client",
    "erreur rouge (serveur)": "une ligne rouge dans la sortie du serveur",
    "clic mort": "un clic sur un bouton visible qui ne répond pas",
    "menus ensemble": "plusieurs menus ouverts l'un sur l'autre",
    "souris bloquée": "un menu ouvert, la souris bloquée au centre : on ne peut viser aucun bouton",
    "hors écran": "un bouton d'un menu hors de l'écran, sans liste qui défile",
    "texte coupé": "un texte qui ne tient pas dans sa case",
    "corps bloqué": "le corps poussé par les touches ne bouge pas",
    "chute": "le corps sous la carte ou au-dessus du vide",
    "projeté": "le corps lancé trop vite",
    "à-coup": "une image de plus de 0,5 s",
    "tenue en double": "deux tenues ou deux jeux de pièces sur le corps",
    "corps nu": "le corps sans haut ou sans bas",
    "tenue fausse": "une pièce équipée qui n'est pas portée",
    "payé deux fois": "un paiement pris deux fois pour la même chose",
    "Ryō faux": "des Ryō négatifs ou impossibles",
    "refus muet": "un bouton qui répond, une demande que le serveur refuse sans rien dire au joueur",
}
ORDER = ["erreur rouge", "erreur rouge (serveur)", "payé deux fois", "Ryō faux", "refus muet", "tenue en double", "corps nu",
         "tenue fausse", "clic mort", "souris bloquée", "menus ensemble", "hors écran", "texte coupé",
         "corps bloqué", "chute", "projeté", "à-coup"]
# What a street blow met (Server/HubFight.land), for a human.
STREET = {"nil": "rien (dans le vide)", "world": "le décor", "broke": "une caisse cassée", "thug": "un voyou",
          "dummy": "le mannequin", "challenger": "un prodige", "boss": "l'Ōtsutsuki"}
# A frame this long (s) is felt; the witness notes every frame over 0.25 s.
FELT = 0.4


# Menus made to sit over another (NDHumanWatch W.OVERLAYS): the tournament's
# entry and PLAYERS ONLINE over the VS screen, CONTROLS (Tab) over anything.
OVERLAYS = {"CupEntry", "« CONTROLS »", "« PLAYERS ONLINE »"}
# Where the body is his own avatar walked by his keys (NDHumanWatch W.VILLAGE).
VILLAGE = "Workspace"


def false_positive(bug):
    """The witness's own mistakes of the first versions of 27/11, fixed since: a button
    of a list that scrolls is not out of the screen; an id "…None" or the hair colour
    wears no piece; a dialog over its screen is not two menus; in a duel, on the
    bracket or watching, the body is a fighter the server moves, not his avatar."""
    detail = bug.get("detail") or {}
    if not isinstance(detail, dict):
        detail = {}
    kind = bug.get("kind")
    if kind == "hors écran" and "ScrollingFrame" in (detail.get("path") or ""):
        return True
    if kind == "tenue fausse" and (str(detail.get("equipped", "")).endswith("None") or bug.get("key") == "hairColor"):
        return True
    if kind == "menus ensemble":
        names = [n.strip() for n in str(bug.get("key", "")).split(" + ")]
        if len([n for n in names if n not in OVERLAYS]) < 2:
            return True
    if kind in ("corps nu", "corps bloqué") and bug.get("place") not in (None, VILLAGE):
        return True
    return False


def grouped(bugs):
    """The real bugs by kind, in the order that matters to a player."""
    out = {}
    for b in bugs:
        if false_positive(b):
            continue
        out.setdefault(b["kind"], []).append(b)
    return sorted(out.items(), key=lambda kv: ORDER.index(kv[0]) if kv[0] in ORDER else len(ORDER))


def steps_text(steps, n=6):
    parts = []
    for s in steps[-n:]:
        k = s.get("k")
        if k == "act":
            parts.append(f"→ {s.get('on')} répond")
        elif s.get("on"):
            parts.append(f"clic {s.get('on')}" if str(k).startswith("Mouse") else f"{k} ({s.get('on')})")
        elif str(k).startswith("MouseButton"):
            parts.append("clic droit" if k == "MouseButton2" else "clic")
        else:
            parts.append(str(k))
    return " · ".join(parts)


# (27/11 soir) A Studio capture freezes the Play about 0.47 s: the long frame in
# this time after a "capture" note (NDHumanWatch.shot) is the capture's, not the game's.
CAPTURE_FREEZE = 2.0


def hitches(rows, events=None):
    shots = [e["t"] for e in (events or []) if e.get("kind") == "note" and e.get("v") == "capture"]
    rows = [h for h in rows if not any(0 <= h.get("t", 0) - s <= CAPTURE_FREEZE for s in shots)]
    felt = [h for h in rows if h.get("dt", 0) >= FELT]
    return {"felt": len(felt), "max": max((h["dt"] for h in rows), default=0.0),
            "every": round(sum(b["t"] - a["t"] for a, b in zip(felt, felt[1:])) / max(1, len(felt) - 1), 1) if len(felt) > 1 else None}


# What a pose of the village is called for a player (Client/HubMove: HubPose).
POSES = {"climb": "monte le mur", "wallstand": "debout sur le mur", "siderunR": "court le long (droite)",
         "siderunL": "court le long (gauche)", "leap": "saut", "kick": "appel sur le mur", "vault": "passe le haut"}


def stands(duel):
    """Each time a fighter stood on a wall in a duel: how long, and whether a blow
    he took ended it (his health lower on the row that leaves the wall)."""
    out, on = [], {}
    for r in duel:
        who = r.get("who")
        if r.get("mode") == "stand" and who not in on:
            on[who] = r
        elif r.get("mode") != "stand" and who in on:
            start = on.pop(who)
            out.append({"who": who, "from": start["t"], "seconds": round(r["t"] - start["t"], 1),
                        "hit": r.get("hp", 0) < start.get("hp", 0), "y": start.get("y")})
    return out


def walls_text(walls):
    lines = []
    poses = {}
    for p in walls.get("pose", []):
        poses[p["pose"]] = poses.get(p["pose"], 0) + 1
    if poses:
        lines.append("En ville : " + ", ".join(f"{POSES.get(k, k)} {v}" for k, v in sorted(poses.items(), key=lambda kv: -kv[1]) if k != "none") + ".")
    st = stands(walls.get("duel", []))
    if st:
        hit = [s for s in st if s["hit"]]
        lines.append(f"En duel : {len(st)} fois debout sur un mur (de {min(s['seconds'] for s in st)} à {max(s['seconds'] for s in st)} s) ; "
                     f"{len(hit)} fin(s) sur un coup reçu.")
    br = walls.get("breach", [])
    if br:
        lines.append(f"Maisons ouvertes : {len(br)} (énergie {min(b['energy'] for b in br)} à {max(b['energy'] for b in br)}).")
    for n in walls.get("notes", []):
        lines.append(f"- {n}")
    return lines


def report(mesure):
    c, s = mesure.get("client", {}), mesure.get("server", {})
    lines = ["# Le robot humain", ""]
    cmds = s.get("rows", [])
    refused = [r for r in cmds if not r.get("ok")]
    lines.append(f"{round(c.get('seconds', 0) / 60)} min de jeu : {c.get('clicks', 0)} clics et {c.get('keys', 0)} touches, "
                 f"{c.get('answers', 0)} boutons qui ont répondu ; {len(cmds)} commandes du profil côté serveur, "
                 f"{len(refused)} refusées.")
    if c.get("fists"):
        lines.append(f"Coups de rue pressés par le code du jeu : {c['fists']} ({c.get('fistsLive', 0)} pendant que le corps pouvait frapper).")
    street = (s.get("street") or {}).get("lands")
    if street:
        lines.append("Ce que les coups de rue ont touché : " + ", ".join(f"{STREET.get(k, k)} {v}" for k, v in sorted(street.items(), key=lambda kv: -kv[1])) + ".")
    lines.append("")
    groups = grouped(c.get("bugs", []) + s.get("bugs", []))
    if not groups:
        lines.append("Aucun bug relevé.")
    for kind, bugs in groups:
        lines.append(f"## {kind} — {MEANING.get(kind, '')}")
        lines.append("")
        lines.append("| quoi | combien de fois | à l'écran | les gestes juste avant |")
        lines.append("|---|---|---|---|")
        for b in bugs:
            where = " + ".join(b.get("menus") or []) or (b.get("stage") or "le jeu")
            note = (b.get("detail") or {}).get("note") if isinstance(b.get("detail"), dict) else None
            if note:
                where += f" ({note})"
            lines.append(f"| {b.get('key')} | {b.get('count', 1)} | {where} | {steps_text(b.get('steps') or [])} |")
        lines.append("")
    h = hitches(c.get("hitches", []), c.get("events"))
    lines.append(f"Images longues : {h['felt']} de {FELT} s ou plus (la plus longue {h['max']} s)"
                 + (f", une toutes les {h['every']} s en moyenne." if h["every"] else "."))
    lines.append("")
    duels = mesure.get("duels") or []
    if duels:
        lines.append("## Les duels")
        lines.append("")
        lines.append("| quoi | contre | qui tenait la manette | résultat |")
        lines.append("|---|---|---|---|")
        for d in duels:
            lines.append(f"| {d.get('what')} | {d.get('vs')} | {d.get('pilot')} | {d.get('wins')} |")
        lines.append("")
    walls = mesure.get("murs")
    if walls:
        lines.append("## Les murs")
        lines.append("")
        lines.extend(walls_text(walls))
        lines.append("")
    two = mesure.get("deux_joueurs")
    if two:
        lines.append("## Deux joueurs")
        lines.append("")
        for step in two.get("steps", []):
            lines.append(f"- {step}")
        lines.append("")
        for who, c2 in (two.get("clients") or {}).items():
            kept = grouped(c2.get("bugs", []))
            felt = hitches(c2.get("hitches", []))["felt"]
            found = "; ".join(f"{kind} : " + ", ".join(f"{b.get('key')} ×{b.get('count', 1)}" for b in bugs) for kind, bugs in kept) or "aucun bug"
            lines.append(f"- {who} : {c2.get('clicks', 0)} clics, {c2.get('keys', 0)} touches, {felt} images de {FELT} s ou plus ; {found}.")
        lines.append("")
    if cmds:
        lines.append("Le serveur : " + ", ".join(f"{r['cmd']} {'ok' if r.get('ok') else 'refusé (' + str(r.get('result')) + ')'}" for r in cmds) + ".")
    return "\n".join(lines)


def main(argv=None):
    args = argv if argv is not None else sys.argv[1:]
    if not args:
        print(__doc__)
        return 2
    if args[0] == "--start":
        print(f"return {WATCH}.start(true)")
        return 0
    if args[0] == "--read":
        print(READ_LUA)
        return 0
    if args[0] == "--server":
        print(f"return {SERVER}.read()")
        return 0
    with open(args[0], encoding="utf-8") as f:
        mesure = json.load(f)
    text = report(mesure)
    if "--md" in args:
        with open(args[args.index("--md") + 1], "w", encoding="utf-8") as f:
            f.write(text + "\n")
    print(text)
    return 0


if __name__ == "__main__":
    sys.exit(main())
