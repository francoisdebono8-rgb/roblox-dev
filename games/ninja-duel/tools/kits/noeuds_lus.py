#!/usr/bin/env python3
"""Ce que le jeu lit des nœuds de l'arbre du ninja (OUTILLEUR, 21/11 ; DEC-045,
étape 2, OUTILLEUR 2).

Un nœud change quelque chose s'il change le kit (tests/Nodes.spec.luau) ET si
le jeu lit ce qu'il change. Les nœuds de l'arbre du ninja écrivent dans
`def.Ninja` (Shared/NinjaTree, champ `Set`) ; le combat doit lire chacun de
ces champs, et le client l'attribut `NinjaNature` (les effets Infusion.<Nature>
de l'ANIMATEUR). Ce script cherche, dans src/, qui les lit :
  - `.Ninja.<champ>` ou `.Ninja["<champ>"]` ;
  - `<alias>.<champ>` dans un fichier où `local <alias> = ….Ninja` ;
  - pour l'attribut : `GetAttribute("NinjaNature")` ou `:GetAttributeChangedSignal("NinjaNature")`.
Les fichiers qui écrivent ou transportent ces champs ne comptent pas comme
lecteurs : NinjaTree lui-même, le profil, la progression, le kit du duel.

Les arbres des kits (Shared/SkillTrees) aussi : chaque effet d'un nœud `Major`
(`def.<champ>`, `tech.<technique>.<champ>`, `graph.<champ>`, et les clés d'une
table posée par `set`) doit avoir un lecteur dans le jeu, hors des fichiers qui
le transportent (SkillTrees, SkillBuilds, TreeView, KitTexts, DevGateCheck).

    python3 tools/kits/noeuds_lus.py          ce que chaque nœud écrit, et qui le lit
"""
from __future__ import annotations

import glob
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
GAME = os.path.normpath(os.path.join(HERE, "..", ".."))
NINJA = os.path.join(GAME, "src", "Shared", "NinjaTree.luau")
# qui écrit ou transporte def.Ninja, sans en tirer d'effet
PLUMBING = {"Shared/NinjaTree.luau", "Server/ProfileSchema.luau", "Server/Progression.luau", "Server/Matches.luau",
            "Server/SkillBuilds.luau", "Shared/TreeView.luau"}


def _read(path: str) -> str:
    with open(path, encoding="utf-8") as f:
        return f.read()


def fields(text: str | None = None) -> dict:
    """{champ: [nœuds qui l'écrivent]} d'après les `Set={…}` de NinjaTree, plus `Infusion`
    (que NinjaTree.def ajoute avec la nature)."""
    text = text if text is not None else _read(NINJA)
    out: dict = {}
    for m in re.finditer(r'\{\s*Id\s*=\s*"(\w+)"[^\n]*?Set\s*=\s*\{([^}]*)\}', text):
        node, body = m.group(1), m.group(2)
        for key in re.findall(r'(\w+)\s*=', body):
            out.setdefault(key, []).append(node)
    if "Nature" in out:
        out.setdefault("Infusion", ["(avec la nature)"])
    return out


def sources(root: str | None = None) -> dict:
    root = root or os.path.join(GAME, "src")
    out = {}
    for path in glob.glob(os.path.join(root, "**", "*.luau"), recursive=True):
        rel = os.path.relpath(path, root).replace(os.sep, "/")
        if re.search(r"OutfitMeshData\d+\.luau$", rel):
            continue  # des maillages, pas du code
        out[rel] = _read(path)
    return out


def readers(key: str, files: dict) -> list:
    """Les fichiers qui lisent def.Ninja.<key> (directement ou par un alias local)."""
    direct = re.compile(r'\.Ninja\s*\.\s*' + re.escape(key) + r'\b|\.Ninja\s*\[\s*"' + re.escape(key) + r'"\s*\]')
    found = []
    for rel, text in files.items():
        if rel in PLUMBING:
            continue
        if direct.search(text):
            found.append(rel)
            continue
        aliases = re.findall(r'local\s+(\w+)\s*=\s*[\w.:()\[\]"]*\.Ninja\b(?!\s*\.)', text)
        if any(re.search(r'\b' + re.escape(alias) + r'\s*\.\s*' + re.escape(key) + r'\b', text) for alias in aliases):
            found.append(rel)
            continue
        # (21/11, Server/NinjaArts) un accesseur rend def.Ninja (`function A.of(a) return a.def.Ninja end`,
        # puis `n.Nature`) : un fichier qui va chercher def.Ninja et lit `.<champ>` le lit
        if re.search(r'\.Ninja\b(?!Tree)', text) and key in _fields_of(rel, text):
            found.append(rel)
    return sorted(found)


def attribute_readers(name: str, files: dict) -> list:
    pat = re.compile(r'(GetAttribute|GetAttributeChangedSignal)\s*\(\s*"' + re.escape(name) + r'"')
    return sorted(rel for rel, text in files.items() if rel not in PLUMBING and pat.search(text))


SKILLTREES = os.path.join(GAME, "src", "Shared", "SkillTrees.luau")
KIT_PLUMBING = {"Shared/SkillTrees.luau", "Server/SkillBuilds.luau", "Shared/TreeView.luau", "Shared/KitTexts.luau",
                "Server/DevGateCheck.luau"}
# {"chemin", "op", valeur} ; la valeur peut être une table, avec une table dedans
EFFECT = re.compile(r'\{\s*"((?:def|tech|graph)\.[\w.]+)"\s*,\s*"(\w+)"\s*(?:,\s*(\{(?:[^{}]|\{[^{}]*\})*\}|[^{}]*?))?\s*\}')


_INDEX: dict = {}


def _fields_of(rel: str, text: str) -> set:
    """Les noms lus après un point ou entre crochets dans un fichier (une fois par fichier)."""
    key = (rel, len(text), hash(text))
    if key not in _INDEX:
        _INDEX[key] = {a or b for a, b in re.findall(r'\.\s*([A-Za-z_]\w*)|\[\s*"([A-Za-z_]\w*)"\s*\]', text)}
    return _INDEX[key]


def field_readers(key: str, files: dict, skip=KIT_PLUMBING) -> list:
    """Les fichiers qui lisent `.key` ou `["key"]`."""
    return sorted(rel for rel, text in files.items() if rel not in skip and key in _fields_of(rel, text))


def effect_keys(path: str, value: str | None) -> list:
    """Ce qu'un lecteur doit lire pour qu'un effet compte : le champ (pour `graph.<champ>.<coup>`,
    le champ, le coup étant une clé lue par table), puis les clés d'une table posée."""
    seg = path.split(".")
    keys = [seg[1] if seg[0] == "graph" else seg[-1]]
    if value and value.strip().startswith("{"):
        # les clés du premier niveau ; celles d'une table dedans sont des coups (Moves = {Tackle = true}),
        # lus par table
        top = re.sub(r'\{[^{}]*\}', "", value.strip()[1:-1])
        keys += [k for k in re.findall(r'(\w+)\s*=', top) if k not in keys]
    return keys


def kit_majors(text: str | None = None) -> list:
    """[(kit, nœud, [(chemin, [clés])])] : les nœuds Major des arbres des kits et leurs effets."""
    text = text if text is not None else _read(SKILLTREES)
    trees = [(m.start(), m.group(1)) for m in re.finditer(r'^\s*(\w+)\s*=\s*\{\s*Fighter\b', text, re.M)]
    starts = [(m.start(), m.group(1)) for m in re.finditer(r'\{\s*Id\s*=\s*"(\w+)"', text)]
    out = []
    for i, (pos, node) in enumerate(starts):
        chunk = text[pos:starts[i + 1][0] if i + 1 < len(starts) else len(text)]
        if not re.search(r'\bMajor\s*=\s*true', chunk):
            continue
        kit = next((name for at, name in reversed(trees) if at < pos), "?")
        effects = [(m.group(1), effect_keys(m.group(1), m.group(3))) for m in EFFECT.finditer(chunk)]
        out.append((kit, node, effects))
    return out


def kit_report(files: dict | None = None, text: str | None = None) -> list:
    """[(kit, nœud, [(chemin, clé, lecteurs)])] : pour chaque clé de chaque effet, qui la lit."""
    files = files if files is not None else sources()
    rows = []
    for kit, node, effects in kit_majors(text):
        reads = []
        for path, keys in effects:
            for key in keys:
                # un objet de kit (Item) : SkillBuilds.gate le lit, et retire au joueur ce que le nœud
                # n'a pas encore donné (`Without`, dont les effets sont vérifiés à côté)
                who = ["Server/SkillBuilds.luau (gate)"] if path.startswith("def.Items.") else field_readers(key, files)
                reads.append((path, key, who))
        rows.append((kit, node, reads))
    return rows


def report(files: dict | None = None, text: str | None = None) -> tuple[list, dict]:
    files = files if files is not None else sources()
    rows = []
    for key, nodes in sorted(fields(text).items()):
        rows.append((key, nodes, readers(key, files)))
    attr = attribute_readers("NinjaNature", files)
    return rows, {"NinjaNature": attr}


def main() -> int:
    rows, attrs = report()
    print("Arbre du ninja : ce que chaque nœud écrit dans def.Ninja, et qui le lit")
    for key, nodes, who in rows:
        print(f"  {key:<14} écrit par {', '.join(nodes):<38} lu par {', '.join(who) if who else 'PERSONNE'}")
    for name, who in attrs.items():
        print(f"  attribut {name:<5} lu par {', '.join(who) if who else 'PERSONNE'}")
    kits = kit_report()
    unread = [(kit, node, path, key) for kit, node, reads in kits for path, key, who in reads if not who]
    print(f"\nArbres des kits : {len(kits)} nœuds Major, "
          f"{sum(len(r) for _, _, r in kits)} effets lus" + (f", {len(unread)} sans lecteur :" if unread else ", tous lus"))
    for kit, node, path, key in unread:
        print(f"  {kit}.{node} : {path} ({key}) lu par PERSONNE")
    return 0


if __name__ == "__main__":
    sys.exit(main())
