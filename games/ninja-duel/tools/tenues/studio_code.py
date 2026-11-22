#!/usr/bin/env python3
"""Prints the Luau to run in Studio (Edit) for the fitting room: cabine.luau,
then one call.

    python3 tools/tenues/studio_code.py setup             builds the avatars
    python3 tools/tenues/studio_code.py dress SetNaruto    dresses them in a look
    python3 tools/tenues/studio_code.py camera front|back  where to capture from
    python3 tools/tenues/studio_code.py hairs              the hair looks to dress (one per article of the shop's hair slots)
"""
import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
body = open(os.path.join(HERE, "cabine.luau"), encoding="utf-8").read()
body = body[: body.rindex("return Cabine")]
args = sys.argv[1:] or ["setup"]
if args[0] == "setup":
    call = "Cabine.setup()"
elif args[0] == "dress":
    call = f"Cabine.dress({json.dumps(args[1])})"
elif args[0] == "hairs":
    call = "select(2,Cabine.hairLooks())"
elif args[0] == "camera":
    call = f"Cabine.camera({json.dumps(args[1] if len(args) > 1 else 'front')})"
else:
    sys.exit(__doc__)
print(body + f"return game:GetService(\"HttpService\"):JSONEncode({call})")
