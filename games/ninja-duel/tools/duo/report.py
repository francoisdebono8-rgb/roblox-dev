#!/usr/bin/env python3
"""The two-player run, measured (OUTILLEUR, 19/11, vague 2 OUTILLEUR 3).

Reads the records of the two clients (tools/duo/recorder.luau,
`shared.NDDuo.json()` saved to a file each) and gives the timeline of a
challenge in Konoha: the challenge, the invitation, the answer, the pick, the
duel in the street, its rounds, the result and the way back to Konoha. The
times are the server's (GetServerTimeNow), the same on both clients.

    python3 tools/duo/report.py client1.json client2.json [--json]

The challenger is the client whose lobby says `sent`.
"""
import json
import sys


def first(events, kind, pred=lambda d: True, after=None):
    for e in events:
        if e["k"] == kind and (after is None or e["t"] >= after) and pred(e.get("d") or {}):
            return e
    return None


def measure(a, b):
    """a, b: the two records. Returns the steps, in order, with their times."""
    sent_a = first(a["events"], "lobby", lambda d: d.get("kind") == "sent")
    challenger, other = (a, b) if sent_a else (b, a)
    C, O = challenger["events"], other["events"]
    steps = []

    def add(name, who, e, detail=""):
        steps.append({"step": name, "who": who, "t": e["t"] if e else None, "detail": detail})
        return e

    sent = add("défi envoyé", challenger["who"], first(C, "lobby", lambda d: d.get("kind") == "sent"))
    t0 = sent and sent["t"]
    add("invitation reçue", other["who"], first(O, "lobby", lambda d: d.get("kind") == "invite", t0))
    closed = first(O, "lobby", lambda d: d.get("kind") == "closed", t0)
    accepted = first(O, "lobby", lambda d: d.get("kind") == "status" and "ACCEPTED" in str(d.get("text")), t0)
    add("invitation acceptée", other["who"], accepted or closed)
    pick = [first(r, "phase", lambda d: d.get("phase") == "Pick", t0) for r in (C, O)]
    add("choix du combattant", "les deux", min((p for p in pick if p), key=lambda e: e["t"], default=None))
    duel = [first(r, "phase", lambda d: d.get("phase") == "Duel", t0) for r in (C, O)]
    d0 = min((p for p in duel if p), key=lambda e: e["t"], default=None)
    where = ""
    if d0:
        d = d0["d"]
        where = (f"dans la rue « {d.get('site') or d.get('inStreet')} »" if d.get("street") or d.get("inStreet")
                 else "au stade (pas dans la rue)")
        if d.get("me") or d.get("them"):
            where += f", {d.get('me')} contre {d.get('them')}"
    add("duel", "les deux", d0, where)
    body = first(C, "body", lambda d: d.get("state") == "duel", t0)
    add("corps du duel", challenger["who"], body,
        f"à {body['d'].get('at')}" + (f", rue « {body['d']['street']} »" if body and body["d"].get("street") else "") if body else "")
    hit = first(C, "hp", after=d0 and d0["t"]) or first(O, "hp", after=d0 and d0["t"])
    add("premier coup", "", hit)
    rounds = [e for e in C if e["k"] == "round" and d0 and e["t"] >= d0["t"]]
    result = [first(r, "phase", lambda d: d.get("phase") == "Result", t0) for r in (C, O)]
    r0 = min((p for p in result if p), key=lambda e: e["t"], default=None)
    add("résultat", "les deux", r0, "manches " + " → ".join(e["d"]["wins"] for e in rounds) if rounds else "")
    for rec in (challenger, other):
        back = first(rec["events"], "body", lambda d: d.get("state") == "konoha", r0 and r0["t"])
        add("retour à Konoha", rec["who"], back,
            (f"à {back['d'].get('at')}" + (f", rue « {back['d']['street']} »" if back["d"].get("street") else ""))
            if back else "")
    for s in steps:
        s["since"] = round(s["t"] - t0, 2) if (s["t"] is not None and t0 is not None) else None
    prev = None
    for s in steps:
        if s["t"] is not None:
            s["gap"] = round(s["t"] - prev, 2) if prev is not None else 0.0
            prev = s["t"]
    return {"challenger": challenger["who"], "challenged": other["who"], "steps": steps,
            "complete": all(s["t"] is not None for s in steps)}


def text(m):
    out = [f"Défi dans Konoha : {m['challenger']} défie {m['challenged']}"]
    for s in m["steps"]:
        when = f"{s['since']:6.2f} s" if s["since"] is not None else "   —    "
        gap = f"(+{s['gap']:.2f})" if s.get("gap") is not None else "        "
        who = f" [{s['who']}]" if s["who"] else ""
        missing = "" if s["t"] is not None else "  PAS VU"
        out.append(f"  {when} {gap:>9}  {s['step']}{who}{(' : ' + s['detail']) if s['detail'] else ''}{missing}")
    out.append("Parcours complet." if m["complete"] else "Parcours incomplet : une étape n'a pas été vue.")
    return "\n".join(out)


def main(argv):
    files = [a for a in argv if not a.startswith("--")]
    if len(files) != 2:
        print(__doc__)
        return 2
    recs = []
    for f in files:
        with open(f, encoding="utf-8") as h:
            recs.append(json.load(h))
    m = measure(*recs)
    print(json.dumps(m, ensure_ascii=False, indent=1) if "--json" in argv else text(m))
    return 0 if m["complete"] else 1


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
