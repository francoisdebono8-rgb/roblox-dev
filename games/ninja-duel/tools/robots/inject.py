#!/usr/bin/env python3
"""The robots, injected into the game during a Play (OUTILLEUR, passe commune 1, DEC-052).

DEC-052: one place only, PLACES/NinjaDuel.rbxlx, and we test in the game. No copy of the
place any more (tools/lab/lab_place.py is gone): the robots are sent into the client of
a Play of that place, as code, and live in _G until the Play stops. Nothing is written
into the place, and Edit is never touched.

    python3 tools/robots/inject.py collision screens   the code to run in the Client (eval_client_runtime)
    python3 tools/robots/inject.py all                 every robot
    python3 tools/robots/inject.py --check             Client: which robots are there, and from which commit
    python3 tools/robots/inject.py --list              the robots and their names

  duel       NDDuelBot       the simulated player (tools/duelbot: PlayerSim + the client driver)
  village    NDVillageBot    the village robot (tools/villagebot)
  newplayer  NDNewPlayerBot  the new player's ten minutes (tools/newplayer; brings duel and village)
  perf       NDPerfProbe     the fluidity probe (tools/perf)
  collision  NDCollisionBot  what the player goes through in Konoha (tools/collision)
  screens    NDScreenTour    the screens of the path and their red lines (tools/screens)

The commands of each tool (collision.py, releve.py, studio_code.py…) look the robot up in
_G and say which line to run when it is not there. A Play that stops takes them away:
inject again after each Play. The published game never has them (the pre-vol,
tools/preflight, refuses their names in the place).
"""
import os
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
TOOLS = os.path.dirname(HERE)
sys.path.insert(0, os.path.join(TOOLS, "duelbot"))
import studio_code as duel  # noqa: E402

# short name -> (the module's name in _G, its source file or None for the duel bot, the robots it needs)
ROBOTS = {
    "duel": ("NDDuelBot", None, []),
    "village": ("NDVillageBot", "villagebot/village_bot.luau", []),
    "newplayer": ("NDNewPlayerBot", "newplayer/newplayer_bot.luau", ["duel", "village"]),
    "perf": ("NDPerfProbe", "perf/perf_probe.luau", []),
    "collision": ("NDCollisionBot", "collision/collision_bot.luau", []),
    "screens": ("NDScreenTour", "screens/screen_tour.luau", []),
}
SHORT = {mod: short for short, (mod, _, _) in ROBOTS.items()}


def source(short: str) -> str:
    """The robot's module, comments and indentation stripped (what the client runs)."""
    mod, rel, _ = ROBOTS[short]
    if rel is None:
        src = duel.module_source()
    else:
        with open(os.path.join(TOOLS, rel), encoding="utf-8") as f:
            src = duel.strip(f.read())
    body = "\n".join(line.strip() for line in src.split("\n"))
    assert body.rstrip().splitlines()[-1].startswith("return "), f"{mod}: the module must end with its return"
    return body


def lookup(mod: str) -> str:
    """A Luau expression: the injected robot, or an error that says how to inject it."""
    return f'(_G.{mod} or error("{mod} absent : python3 tools/robots/inject.py {SHORT[mod]} (pendant le Play)"))'


def commit() -> str:
    try:
        return subprocess.run(["git", "rev-parse", "--short=8", "HEAD"], cwd=TOOLS, capture_output=True,
                              text=True, timeout=10).stdout.strip() or "?"
    except Exception:
        return "?"


def order(names: list) -> list:
    """The robots asked for, with what they need first, each once."""
    out = []

    def add(n):
        if n not in ROBOTS:
            raise KeyError(f"unknown robot {n!r} (try --list)")
        for dep in ROBOTS[n][2]:
            add(dep)
        if n not in out:
            out.append(n)

    for n in (list(ROBOTS) if names == ["all"] else names):
        add(n)
    return out


def snippet(names: list, stamp: str = "") -> str:
    """The code for eval_client_runtime: each robot built in a pcall, put in _G, reported."""
    names = order(names)
    stamp = stamp or commit()
    parts = ['local out={}',
             'local function put(name,f) local ok,m=pcall(f) if ok and m then _G[name]=m '
             'table.insert(out,name) else table.insert(out,name.." ERREUR "..tostring(m)) end end']
    for n in names:
        mod = ROBOTS[n][0]
        parts.append(f'put("{mod}",function()\n{source(n)}\nend)')
    parts.append('_G.NDRobots={commit="' + stamp + '",names=out}')
    parts.append('return "robots ' + stamp + ' : "..table.concat(out,", ")')
    return "\n".join(parts)


CHECK = ('local r=_G.NDRobots if not r then return "aucun robot : python3 tools/robots/inject.py …" end '
         'local have={} for _,n in r.names do table.insert(have,n..(_G[n] and "" or " (parti)")) end '
         'return "robots "..r.commit.." : "..table.concat(have,", ")')


def main(argv=None):
    args = argv if argv is not None else sys.argv[1:]
    if not args or args[0] in ("-h", "--help"):
        print(__doc__)
        return 2
    if args[0] == "--list":
        for short, (mod, rel, deps) in ROBOTS.items():
            print(f"{short:10} {mod:15} {rel or 'duelbot/PlayerSim.luau + studio_bot.luau'}"
                  + (f"  (avec {', '.join(deps)})" if deps else ""))
        return 0
    if args[0] == "--check":
        print(CHECK)
        return 0
    try:
        print(snippet(args))
    except KeyError as e:
        print(e.args[0], file=sys.stderr)
        return 2
    return 0


if __name__ == "__main__":
    sys.exit(main())
