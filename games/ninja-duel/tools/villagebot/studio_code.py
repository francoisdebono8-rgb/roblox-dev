#!/usr/bin/env python3
"""The Studio code of the village robot (OUTILLEUR, 21/11).

    python3 tools/robots/inject.py village
        Client datamodel, during a Play of the game (DEC-052): the robot as _G.NDVillageBot.
    python3 tools/villagebot/studio_code.py --start '{"routes":true,"roofs":16}'
        Client datamodel, during a Play, in the village: starts the walk.
    python3 tools/villagebot/studio_code.py --read
"""
import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "duelbot"))
from studio_code import lua_value, strip  # noqa: E402


ROBOT = '(_G.NDVillageBot or error("NDVillageBot absent : python3 tools/robots/inject.py village (pendant le Play)"))'


def module_source() -> str:
    with open(os.path.join(HERE, "village_bot.luau"), encoding="utf-8") as f:
        return strip(f.read())


READ = ('local p=game:GetService("Players").LocalPlayer '
        'return tostring(p:GetAttribute("NDVillageState"))..\" | \"..tostring(p:GetAttribute("NDVillageLog"))')


def main(argv=None):
    args = argv if argv is not None else sys.argv[1:]
    if not args:
        print(__doc__)
        return 2
    if args[0] == "--module":
        print("DEC-052 : plus de module dans l'Édition. Pendant le Play : python3 tools/robots/inject.py village", file=sys.stderr)
        return 2
    elif args[0] == "--read":
        print(READ)
    elif args[0] == "--start":
        plan = json.loads(args[1]) if len(args) > 1 else {"routes": True, "roofs": 16}
        print("return " + ROBOT + ".start(" + lua_value(plan) + ")")
    return 0


if __name__ == "__main__":
    sys.exit(main())
