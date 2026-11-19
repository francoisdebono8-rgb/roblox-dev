#!/usr/bin/env python3
"""The catalogue's looks, read from the Luau source, and what each one has
(OUTILLEUR, 19/11; vague 2, OUTILLEUR 2 and 4). No Blender needed.

  python3 tools/icons/catalogue.py            the coverage: icon, model in the game, model for the icon
  python3 tools/icons/catalogue.py --gate     the same, exit 1 if a look lacks its icon or its model
  python3 tools/icons/catalogue.py --manquantes   only the ids still without an icon (for render_icons.py)

Sources (read, never changed):
  looks      Shared/Shop.luau (Shop.Items) and, once the DEV adds it,
             Shared/Catalog.luau (vague 2, DEV 2): every `{id="...",slot="..."}`
  slots      Shop.Slots (`kind`, `outfit=true`) and the same in Catalog
  icons      tools/icons/renders/<id>.png and icons.json (render_icons.py)
  in game    an outfit slot: the ANIMATEUR's modelled pieces (Shared/OutfitMeshes
             Items -> OutfitMeshData models); a weapon or the headband: the props
             the game builds itself (Client/Effects, Server/Headband)
  for icon   outfit_models.ITEMS (tools/blender), fx_models (kunai, shuriken,
             tanto), look_gaara.py (gourd), the game's headband geometry
"""
import ast
import json
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
GAME = os.path.dirname(os.path.dirname(HERE))
SHARED = os.path.join(GAME, "src", "Shared")
BLENDER_TOOLS = os.path.join(GAME, "tools", "blender")
RENDERS = os.path.join(HERE, "renders")
# The props the game builds itself from code, by slot (no modelled piece).
BUILT_BY_GAME = {"kunai": "Client/Effects", "shuriken": "Client/Effects", "tanto": "Client/Effects",
                 "gourd": "Client/Effects", "headband": "Server/Headband"}
# What the icon renderer builds each slot from (render_icons.BUILD).
ICON_SOURCE = {"kunai": "fx_models", "shuriken": "fx_models", "tanto": "fx_models",
               "gourd": "look_gaara", "headband": "géométrie du jeu"}


def read(path):
    try:
        with open(path, encoding="utf-8") as f:
            return f.read()
    except FileNotFoundError:
        return ""


def parse_items(text):
    """Every `{id="X",...slot="Y"...}` look of a Luau source, in order."""
    items = []
    for chunk in re.split(r"\{\s*id\s*=\s*", text)[1:]:
        head = re.match(r'"(\w+)"', chunk)
        if not head:
            continue
        # the look ends where the next one starts; its own `pieces=` (cloth) are not its colours
        slot = re.search(r'\bslot\s*=\s*"(\w+)"', chunk)
        name = re.search(r'\bname\s*=\s*"([^"]+)"', chunk)
        if not slot or not name:
            continue
        own = chunk.split("pieces=")[0]
        item = {"id": head.group(1), "slot": slot.group(1), "name": name.group(1)}
        item["none"] = re.search(r"\bnone\s*=\s*true", own) is not None
        m = re.search(r"\bryo\s*=\s*(\d+)", own)
        item["counter"] = "shop" if re.search(r'\brobux\s*=\s*"', own) else ("market" if m else "free")
        if m:
            item["ryo"] = int(m.group(1))
        k = re.search(r'\bkit\s*=\s*"(\w+)"', own)
        if k:
            item["kit"] = k.group(1)
        mdl = re.search(r'\bmodel\s*=\s*"(\w+)"', own)
        if mdl:
            item["model"] = mdl.group(1)
        item["colors"] = {key: (int(r), int(g), int(b))
                          for key, r, g, b in re.findall(r"(\w+)\s*=\s*\{\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*\}", own)}
        items.append(item)
    return items


def catalogue(shared=SHARED):
    """Shop.Items, then the looks of Catalog.luau (a Catalog look replaces a Shop look of the same id)."""
    shop = read(os.path.join(shared, "Shop.luau"))
    block = ""
    if "Shop.Items={" in shop:
        start = shop.index("Shop.Items={")
        end = shop.find("local byId", start)
        block = shop[start:end if end > 0 else len(shop)]
    found = {}
    order = []
    for item in parse_items(block) + parse_items(read(os.path.join(shared, "Catalog.luau"))):
        if item["id"] not in found:
            order.append(item["id"])
        found[item["id"]] = item
    return [found[i] for i in order]


def slots(shared=SHARED):
    """{slot: {"kind": ..., "outfit": bool}} from Shop.Slots and Catalog."""
    out = {}
    for text in (read(os.path.join(shared, "Shop.luau")), read(os.path.join(shared, "Catalog.luau"))):
        m = re.search(r"\bSlots\s*=\s*\{(.*?)\n\}", text, re.S)
        if not m:
            continue
        for name, body in re.findall(r"\b(\w+)\s*=\s*\{([^{}]*)\}", m.group(1)):
            kind = re.search(r'kind\s*=\s*"(\w+)"', body)
            out[name] = {"kind": kind.group(1) if kind else None,
                         "outfit": re.search(r"\boutfit\s*=\s*true", body) is not None}
    return out


def game_models(shared=SHARED):
    """OutfitMeshes.Items (look id -> model) and the models its data really holds."""
    text = read(os.path.join(shared, "OutfitMeshes.luau"))
    m = re.search(r"OutfitMeshes\.Items\s*=\s*\{([^}]*)\}", text)
    items = dict(re.findall(r'(\w+)\s*=\s*"(\w+)"', m.group(1))) if m else {}
    models = set()
    for name in sorted(os.listdir(shared)) if os.path.isdir(shared) else []:
        if name.startswith("OutfitMeshData") and name.endswith(".luau"):
            models |= set(re.findall(r'^\s*\{"(\w+)","\w+","\w+"', read(os.path.join(shared, name)), re.M))
    return items, models


def blender_items(tools=BLENDER_TOOLS):
    """outfit_models.ITEMS without running Blender (the module imports bpy)."""
    try:
        tree = ast.parse(read(os.path.join(tools, "outfit_models.py")))
    except SyntaxError:
        return {}
    for node in tree.body:
        if isinstance(node, ast.Assign) and any(isinstance(t, ast.Name) and t.id == "ITEMS" for t in node.targets):
            try:
                return ast.literal_eval(node.value)
            except ValueError:
                return {}
    return {}


def coverage(shared=SHARED, renders=RENDERS, tools=BLENDER_TOOLS):
    """One row per look: its icon, its model in the game, the model its icon is made from."""
    items = catalogue(shared)
    kinds = slots(shared)
    mesh_items, mesh_models = game_models(shared)
    bl = blender_items(tools)
    manifest = {}
    try:
        with open(os.path.join(renders, "icons.json"), encoding="utf-8") as f:
            manifest = {e["id"]: e for e in json.load(f).get("icons", [])}
    except (FileNotFoundError, ValueError):
        pass
    rows = []
    for it in items:
        row = {"id": it["id"], "slot": it["slot"], "name": it["name"], "counter": it["counter"]}
        if it["none"]:
            row.update(none=True, icon=True, model=True, iconSource=True, note="aucun objet : case vide")
            rows.append(row)
            continue
        png = os.path.join(renders, it["id"] + ".png")
        row["icon"] = os.path.isfile(png) and manifest.get(it["id"], {}).get("icon") is not None
        slot = kinds.get(it["slot"], {})
        if it["slot"] in BUILT_BY_GAME:
            row["model"] = True
            row["modelFrom"] = BUILT_BY_GAME[it["slot"]]
            row["iconSource"] = True
            row["iconFrom"] = ICON_SOURCE[it["slot"]]
        else:
            model = it.get("model") or mesh_items.get(it["id"])
            row["model"] = bool(model and model in mesh_models)
            row["modelFrom"] = ("OutfitMeshes · " + model) if row["model"] else (
                "OutfitMeshes · " + model + " (modèle absent des données)" if model else
                ("aucun (tissu de secours)" if slot.get("outfit") else "aucun : emplacement inconnu de l'outil"))
            row["iconSource"] = it["id"] in bl
            row["iconFrom"] = ("outfit_models.py · " + bl[it["id"]]) if row["iconSource"] else "pas dans outfit_models.ITEMS"
        rows.append(row)
    return rows


def report(rows):
    lines = []
    real = [r for r in rows if not r.get("none")]
    no_icon = [r for r in real if not r["icon"]]
    no_model = [r for r in real if not r["model"]]
    no_src = [r for r in real if not r["iconSource"]]
    lines.append(f"Catalogue : {len(rows)} objets, dont {len(rows) - len(real)} « aucun ».")
    lines.append(f"  icône : {len(real) - len(no_icon)}/{len(real)}   modèle dans le jeu : "
                 f"{len(real) - len(no_model)}/{len(real)}   modèle pour l'icône : {len(real) - len(no_src)}/{len(real)}")
    by_slot = {}
    for r in real:
        by_slot.setdefault(r["slot"], []).append(r)
    lines.append("  par emplacement : " + ", ".join(f"{s} {len(v)}" for s, v in by_slot.items()))
    for title, group, key in (("Sans icône", no_icon, None), ("Sans modèle dans le jeu", no_model, "modelFrom"),
                              ("Sans modèle pour son icône", no_src, "iconFrom")):
        if group:
            lines.append(f"{title} ({len(group)}) :")
            for r in group:
                lines.append(f"  {r['id']:<20} {r['slot']:<9} {r[key] if key else r['name']}")
    if not (no_icon or no_model or no_src):
        lines.append("Chaque objet a son icône et son modèle.")
    return "\n".join(lines)


def main(argv):
    rows = coverage()
    if "--manquantes" in argv:
        print(" ".join(r["id"] for r in rows if not r.get("none") and not r["icon"]))
        return 0
    if "--json" in argv:
        print(json.dumps(rows, ensure_ascii=False, indent=1))
    else:
        print(report(rows))
    if "--gate" in argv and any(not r["icon"] or not r["model"] for r in rows):
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
