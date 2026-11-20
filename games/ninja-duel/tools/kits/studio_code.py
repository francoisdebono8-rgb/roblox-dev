#!/usr/bin/env python3
"""Prints the Luau to run in Studio (Edit) for the kits' fingerprint:
studio_kitprint.luau with KitPrint.luau inside. Paste it in the command bar
(or Roblox_Studio execute_luau, Edit), save the JSON it returns.

    python3 tools/kits/studio_code.py > /tmp/kitprint_studio.luau
"""
import os

HERE = os.path.dirname(os.path.abspath(__file__))
body = open(os.path.join(HERE, "KitPrint.luau"), encoding="utf-8").read()
wrapper = open(os.path.join(HERE, "studio_kitprint.luau"), encoding="utf-8").read()
print(wrapper.replace("\t--[[ KitPrint.luau ]]\n", body), end="")
