#!/usr/bin/env python3
"""The outfit check's report (OUTILLEUR, passe commune 2, 26/11; DEC-054: « il dit quelle
pièce traverse ou flotte, sur quel corps »).

In a Play of the game's place: the server builds the row of avatars
(outfit_bodies.luau, NDOutfitBodies), dresses it in a look; the client measures each
modelled piece (outfit_check.luau, NDOutfitCheck). One JSON per look; this reads them all.

    python3 tools/outfitcheck/report.py MESURES/*.json             the table (text)
    python3 tools/outfitcheck/report.py MESURES/*.json --md OUT.md

The Studio code:
    python3 tools/outfitcheck/report.py --looks                    the looks, in the order of the check
    python3 tools/outfitcheck/report.py --dress LOOK               Server: the row dressed in LOOK
    python3 tools/outfitcheck/report.py --measure LOOK             Client: the measure (JSON)
A piece "traverse" on a body when more than INSIDE_SHARE of its points are inside the body
(the body shows through) in the rest pose or in a frame of the clips; it "flotte" when
more than OFF_SHARE of its points stand more than 0.25 stud off the body, for a piece made
to hug it (not a cape, a scroll, a sword, hair).
"""
import glob
import json
import sys

INSIDE_SHARE = 0.10
OFF_SHARE = 0.35
BASE = {"top": "TopTunicNavy", "bottom": "BottomPantsDark", "feet": "FeetSandals", "headband": "HeadbandBlue"}
# bandages and bracelets first (DEC-054: « ils rendent mal »), then the rest
LOOKS = {
    "ArmsWraps": dict(BASE, arms="ArmsWraps"),
    "ArmsGuards": dict(BASE, arms="ArmsGuards"),
    "ArmsBracers": dict(BASE, arms="ArmsBracers"),
    "ArmsGauntlets": dict(BASE, arms="ArmsGauntlets"),
    "ArmsWarmers": dict(BASE, arms="ArmsWarmers"),
    "ArmsFingerless": dict(BASE, arms="ArmsFingerless"),
    "ArmsElbowPads": dict(BASE, arms="ArmsElbowPads"),
    "ArmsLongSleeves": dict(BASE, arms="ArmsLongSleeves"),
    "FeetWrapped": dict(BASE, feet="FeetWrapped", bottom="BottomWrapPants"),
    "SetLee": {"set": "SetLee", "headband": "HeadbandBlue"},
    "SetNaruto": {"set": "SetNaruto", "headband": "HeadbandBlue"},
    "SetSasuke": {"set": "SetSasuke", "headband": "HeadbandBlue"},
    "SetNeji": {"set": "SetNeji", "headband": "HeadbandBlue"},
    "SetGaara": {"set": "SetGaara"},
    "SetKakashi": {"set": "SetKakashi", "headband": "HeadbandBlue"},
    "SetItachi": {"set": "SetItachi", "headband": "HeadbandBlue"},
    "SetMinato": {"set": "SetMinato", "headband": "HeadbandBlue"},
    "SetShadowScout": {"set": "SetShadowScout", "headband": "HeadbandBlue"},
    "SetEmberMonk": {"set": "SetEmberMonk"},
    "SetMistHunter": {"set": "SetMistHunter", "headband": "HeadbandBlue"},
}
ORDER = ["francois", "bloc", "femme", "garcon", "vanessa", "bigbill", "korblox"]
BODIES = {"francois": "François", "bloc": "Bloc R15", "femme": "Femme (mince)", "garcon": "Garçon (petit)",
          "vanessa": "Vanessa (grand, Rthro)", "bigbill": "Big Bill (large, Rthro)", "korblox": "Korblox (armure)"}
BODIES_LUA = '(_G.NDOutfitBodies or error("NDOutfitBodies absent : python3 tools/robots/inject.py --server outfitbodies (pendant le Play)"))'
CHECK_LUA = '(_G.NDOutfitCheck or error("NDOutfitCheck absent : python3 tools/robots/inject.py outfit (pendant le Play)"))'


def lua(v):
    if isinstance(v, dict):
        return "{" + ",".join(f"{k}={lua(x)}" for k, x in v.items()) + "}"
    if isinstance(v, list):
        return "{" + ",".join(lua(x) for x in v) + "}"
    return json.dumps(v)


def verdict(p: dict) -> list:
    """What is wrong with one piece on one body: [("traverse", share, depth, pose)…]."""
    out = []
    wi = p.get("worstIn") or {}
    if (wi.get("inside") or 0) > INSIDE_SHARE:
        out.append(("traverse", wi.get("inside"), wi.get("maxIn"), p.get("worstInPose")))
    wo = p.get("worstOff") or {}
    if not p.get("loose") and (wo.get("off") or 0) > OFF_SHARE:
        out.append(("flotte", wo.get("off"), wo.get("maxOff"), p.get("worstOffPose")))
    return out


def collect(files: list) -> list:
    rows = []
    for path in files:
        with open(path, encoding="utf-8") as f:
            data = json.load(f)
        look = data.get("look") or path
        for key, body in (data.get("bodies") or {}).items():
            for p in body.get("pieces") or []:
                for kind, share, depth, pose in verdict(p):
                    rows.append({"look": look, "body": key, "item": p.get("item"), "piece": p.get("piece"), "on": p.get("on"),
                                 "kind": kind, "share": share, "depth": depth, "pose": pose,
                                 "rest": (p.get("rest") or {}).get("inside" if kind == "traverse" else "off")})
    return rows


def report(files: list) -> str:
    rows = collect(files)
    lines = ["# Contrôle des tenues : quelle pièce traverse ou flotte, sur quel corps", ""]
    items = sorted({(r["item"], r["piece"], r["kind"]) for r in rows})
    lines.append("| pièce | défaut | " + " | ".join(BODIES[k] for k in ORDER) + " |")
    lines.append("|---|---|" + "---|" * len(ORDER))
    for item, piece, kind in items:
        cells = []
        for key in ORDER:
            hit = [r for r in rows if r["item"] == item and r["piece"] == piece and r["kind"] == kind and r["body"] == key]
            if hit:
                r = max(hit, key=lambda x: x["share"] or 0)
                cells.append(f"{int(round((r['share'] or 0) * 100))} % · {r['depth']:.2f}")
            else:
                cells.append("·")
        lines.append(f"| {item} / {piece} | {kind} | " + " | ".join(cells) + " |")
    lines.append("")
    lines.append(f"Chaque case : la part des points de la pièce en défaut, dans la pire pose, et la profondeur (traverse) "
                 f"ou l'écart (flotte) le plus grand, en studs. Seuils : traverse au-delà de {int(INSIDE_SHARE * 100)} % des points "
                 f"à plus de 0,05 stud dans le corps ; flotte au-delà de {int(OFF_SHARE * 100)} % des points à plus de 0,25 stud du corps "
                 "(pas pour une cape, un rouleau, un sabre, des cheveux).")
    return "\n".join(lines)


# (26/11) The summary the check returns for many looks at once (NDOutfitCheck.summary):
# {look: {item: {i: "share/depth", ip: pose, ipc: piece, o: "share/gap", op, opc,
# r: "rest in/rest off", k: kind, l: loose, n: pieces, diff: {body: "i o"}}}}, the numbers
# of François's body, and the bodies whose numbers differ.
def summary_report(data: dict) -> str:
    def pair(v):
        try:
            a, b = (v or "0/0").split("/")
            return float(a), float(b)
        except ValueError:
            return 0.0, 0.0
    lines = ["# Contrôle des tenues : quelle pièce traverse ou flotte, sur quel corps", "",
             "| tenue | pièce | traverse (part · profondeur · pose) | flotte (part · écart · pose) | au repos (dedans / décollé) | corps différents |",
             "|---|---|---|---|---|---|"]
    rows = []
    for look, items in data.items():
        for item, it in items.items():
            ish, idp = pair(it.get("i"))
            osh, odp = pair(it.get("o"))
            rin, rout = pair(it.get("r"))
            bad_in = ish > INSIDE_SHARE
            bad_off = osh > OFF_SHARE and not it.get("l")
            if not (bad_in or bad_off or it.get("diff")):
                continue
            diff = it.get("diff") or {}
            diff_txt = "; ".join(f"{BODIES.get(b, b)} {v}" for b, v in sorted(diff.items())) if isinstance(diff, dict) else ""
            rows.append((0 if item.startswith(("Arms", "FeetWrapped")) else 1, look, item,
                         f"**{int(round(ish * 100))} %** · {idp:.2f} · {it.get('ip') or ''} ({it.get('ipc') or ''})" if bad_in else f"{int(round(ish * 100))} %",
                         f"**{int(round(osh * 100))} %** · {odp:.2f} · {it.get('op') or ''} ({it.get('opc') or ''})" if bad_off else f"{int(round(osh * 100))} %",
                         f"{int(round(rin * 100))} % / {int(round(rout * 100))} %", diff_txt))
    seen = set()
    for _, look, item, a, b, c, d in sorted(rows):
        key = (item, a, b, d)
        if key in seen:
            continue
        seen.add(key)
        lines.append(f"| {look} | {item} | {a} | {b} | {c} | {d} |")
    lines.append("")
    lines.append(f"Seuils : traverse au-delà de {int(INSIDE_SHARE * 100)} % des points à plus de 0,05 stud dans le membre ; "
                 f"flotte au-delà de {int(OFF_SHARE * 100)} % des points à plus de 0,25 stud du membre (pas pour une cape, un rouleau, "
                 "un sabre, des cheveux). Les chiffres sont ceux de l'avatar de François ; « corps différents » donne ceux des corps qui "
                 "s'en écartent (traverse puis flotte, part/profondeur). Une même pièce portée dans plusieurs tenues n'est écrite qu'une fois.")
    return "\n".join(lines)


def main(argv=None):
    args = argv if argv is not None else sys.argv[1:]
    if not args:
        print(__doc__)
        return 2
    if args[0] == "--looks":
        for name, look in LOOKS.items():
            print(name, json.dumps(look))
        return 0
    if args[0] == "--dress":
        print(f"return {BODIES_LUA}.dress({lua(LOOKS[args[1]])})")
        return 0
    if args[0] == "--measure":
        print(f'return {CHECK_LUA}.measure({{look="{args[1]}"}})')
        return 0
    files = []
    for a in args:
        if a == "--md":
            break
        files += glob.glob(a)
    with open(files[0], encoding="utf-8") as f:
        first = json.load(f)
    text = report(files) if "bodies" in first else summary_report(first)
    if "--md" in args:
        with open(args[args.index("--md") + 1], "w", encoding="utf-8") as f:
            f.write(text + "\n")
    print(text)
    return 0


if __name__ == "__main__":
    sys.exit(main())
