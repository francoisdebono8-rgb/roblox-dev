#!/usr/bin/env python3
"""The Studio code of the new-player robot (OUTILLEUR, 23/11; étape 5).

In a Play of the game's place (DEC-052), after python3 tools/robots/inject.py newplayer:

    python3 tools/newplayer/studio_code.py --start [minutes] [kit]   Client: the ten minutes start
    python3 tools/newplayer/studio_code.py --read                    Client: progress and the log (JSON)
    python3 tools/newplayer/studio_code.py --funnel                  Server: the funnel lines ([NinjaDuelFirst])
    python3 tools/newplayer/studio_code.py --report LOG.json FUNNEL.txt   the summary (text)
"""
import json
import re
import sys

START = 'return (_G.NDNewPlayerBot or error("NDNewPlayerBot absent : python3 tools/robots/inject.py newplayer (pendant le Play)")).start({{minutes={minutes},kit="{kit}"}})'
READ = ('local p=game:GetService("Players").LocalPlayer '
        'return tostring(p:GetAttribute("NDNewPlayerState"))..\" | \"..tostring(p:GetAttribute("NDNewPlayerLog"))')
FUNNEL = ('local out={} for _,m in game:GetService("LogService"):GetLogHistory() do '
          'if string.find(m.message,"[NinjaDuelFirst]",1,true) then table.insert(out,m.message) end end '
          'return table.concat(out,"\\n")')
STEPS = ["joined", "input", "started", "hit", "jutsu", "duel", "won", "inspiration", "dressed", "bought", "node"]


def funnel(text: str) -> dict:
    """[NinjaDuelFirst] <UserId> <step> <seconds>s -> {step: seconds} (the first of each)."""
    out = {}
    for _, step, sec in re.findall(r"\[NinjaDuelFirst\] (-?\d+) (\w+) ([\d.]+)s", text):
        out.setdefault(step, float(sec))
    return out


def report(log: dict, steps: dict) -> str:
    lines = ["Le robot nouveau joueur, " + str(log.get("minutes", 10)) + " minutes, kit " + str(log.get("kit")), "",
             "L'entonnoir du serveur (secondes depuis l'arrivée) :"]
    for s in STEPS:
        lines.append(f"  {s:12} {steps[s]:6.1f} s" if s in steps else f"  {s:12}    —   (pas atteint)")
    lines += ["", "Ce qu'il a fait :"]
    for s in log.get("steps", []):
        extra = {k: v for k, v in s.items() if k not in ("t", "step", "ok")}
        lines.append(f"  {s.get('t', 0):6.1f} s  {s['step']}{'' if s.get('ok') else '  (non)'}  {json.dumps(extra, ensure_ascii=False)}")
    races = [s.get("time") for s in log.get("steps", []) if s.get("step") == "rooftop race" and s.get("time")]
    if races:
        secs = sorted(t / 100 for t in races)
        lines.append(f"  courses des toits : {len(secs)}, de {secs[0]:.1f} à {secs[-1]:.1f} s, médiane {secs[len(secs) // 2]:.1f} s")
    for r in log.get("refusals", []):
        lines.append(f"  refus à {r['t']} s : {r['notice']}")
    lines += ["", "Ce qu'il avait à l'écran :"]
    for sc in log.get("screens", []):
        lines.append(f"  {sc['t']:6.1f} s  {sc['at']} ({sc.get('phase')}) : " + " · ".join(sc.get("words", [])[:12]))
    return "\n".join(lines)


def main(argv=None):
    args = argv if argv is not None else sys.argv[1:]
    if not args:
        print(__doc__)
        return 2
    if args[0] == "--start":
        print(START.format(minutes=int(args[1]) if len(args) > 1 else 10, kit=args[2] if len(args) > 2 else "Legion"))
    elif args[0] == "--read":
        print(READ)
    elif args[0] == "--funnel":
        print(FUNNEL)
    elif args[0] == "--report":
        with open(args[1], encoding="utf-8") as f:
            log = json.load(f)
        with open(args[2], encoding="utf-8") as f:
            steps = funnel(f.read())
        print(report(log, steps))
    else:
        print(__doc__)
        return 2
    return 0


if __name__ == "__main__":
    sys.exit(main())
