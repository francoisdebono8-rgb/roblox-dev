#!/usr/bin/env python3
"""Le pré-vol de publication (OUTILLEUR, étape 5 « Ouverture », DEC-049).

Il passe la liste « prêt à publier » sur la place qui serait publiée (la build
release, dist/NinjaDuel.rbxlx) et sur les sources, et rend chaque point VERT,
ROUGE (bloque la publication) ou ORANGE (à regarder, ne bloque pas) :

  Offres      chaque offre affichée a un ID ; aucune offre retirée n'est encore
              affichée ; aucun ID en double ; chaque offre a son effet côté
              serveur (le jeu sait la donner)
  Outils      aucun outil de debug ni de tournage dans la place ; profil release
  Version     la ligne de version (SourceCommit) est le commit des sources,
              sans changement non commité ; même moteur que les autres profils
  DataStore   les noms des DataStore sont ceux du jeu publié (une liste de
              référence : un nom qui change, ce sont des données perdues) ; le
              jeu publié sauvegarde (Progression.Live) ; Studio a les siens
  Test        aucun code de test dans la place (specs, banc, robots)
  Codes       3 codes actifs au plus en même temps (règle du CM), dates valides

Les autres points de la liste (données à la fermeture, fluidité sur téléphone,
premières minutes, contenu, page, test à plusieurs) se prouvent ailleurs : le
rapport dit où.

    python3 tools/preflight/preflight.py                  # le rapport, code 1 si un point est ROUGE
    python3 tools/preflight/preflight.py --build          # reconstruit la release d'abord (build.py)
    python3 tools/preflight/preflight.py --md R.md --json R.json --html R.html
    python3 tools/preflight/preflight.py --today 2026-11-27   # les codes à cette date

Lecture seule : il ne change rien dans le jeu ni dans dist/ (sauf --build).
"""
import argparse
import datetime
import html
import json
import re
import subprocess
import sys
import xml.etree.ElementTree as ET
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SRC = ROOT / "src"
DIST = ROOT / "dist"
HERE = Path(__file__).resolve().parent
REFERENCE = HERE / "datastores.json"

GREEN, RED, ORANGE = "VERT", "ROUGE", "ORANGE"

# (DEC-049, étape 5) ce qui est retiré de la vente : pas de puissance, pas ce qui est déjà donné,
# pas ce qui n'existe pas encore ; les auras se gagnent, jamais en Robux (règle du 20/11).
RETIRED_PASSES = {
    "EarlyAccess": "il n'y a pas encore de 9e prodige : on n'en vend pas l'accès",
    "BuildSlots": "chacun a déjà 8 constructions par kit, gratuitement",
}
RETIRED_SLOTS = {"aura": "les auras se gagnent au mérite, jamais en Robux"}

# Les modules Studio seulement (build.py DEBUG_SOURCES, tests/test_build_isolation.py) et les outils
# de tournage (tools/capture/studio) : jamais dans la place publiée.
sys.path.insert(0, str(ROOT / "tests"))
try:
    import test_build_isolation as _iso  # noqa: E402
    DEBUG_ONLY = set(_iso.DEBUG_ONLY) | {"NativeQA"}
    CAPTURE_TOOLS = set(_iso.CAPTURE_TOOLS)
    MARKERS = tuple(_iso.MARKERS)
except Exception:  # the test file moved: the build's own list still holds
    DEBUG_ONLY, CAPTURE_TOOLS, MARKERS = {"NativeQA"}, set(), ()
# Les robots et outils de l'OUTILLEUR et des autres (insérés à la main dans une copie LAB, jamais dans
# les sources) et le banc de test.
TEST_NAMES = {"NDDuelBot", "NDVillageBot", "NDCabineTool", "NDNewPlayerBot", "NDCollisionBot", "NDScreenTour", "NDPerfProbe", "Harness", "TestEZ", "JestGlobals",
              "Jest", "NDFactory"}
TEST_MARKERS = ("@lune/", "require(\"../../tests", "tests/Harness", "NDBotLog", "NDVillageLog", "NDNewPlayerLog")


# ------------------------------------------------------------------ reading the sources

def read(rel):
    return (SRC / rel).read_text(encoding="utf-8")


def block(text, start_pattern):
    """The text of the `{ ... }` that opens at the first match of start_pattern (balanced braces,
    strings and comments not special-cased: the data tables read here have none inside)."""
    m = re.search(start_pattern, text)
    if not m:
        return None
    i = text.index("{", m.start())
    depth = 0
    for j in range(i, len(text)):
        if text[j] == "{":
            depth += 1
        elif text[j] == "}":
            depth -= 1
            if depth == 0:
                return text[i + 1:j]
    return None


def strip_comments(text):
    return re.sub(r"--[^\n]*", "", text)


def number_map(body):
    return {k: int(v) for k, v in re.findall(r"\b([A-Za-z_]\w*)\s*=\s*(\d+)", body or "")}


def config_offers():
    cfg = strip_comments(read("Shared/Config.luau"))
    shop = block(cfg, r"\bShop\s*=\s*\{")
    prog = block(cfg, r"\bProgression\s*=\s*\{")
    products = number_map(block("Shop = {" + shop + "}", r"\bProducts\s*=\s*\{")) if shop else {}
    passes = number_map(block("Shop = {" + shop + "}", r"\bPasses\s*=\s*\{")) if shop else {}
    packs_body = block("Shop = {" + shop + "}", r"\bRyoPacks\s*=\s*\{") if shop else ""
    packs = [{"amount": int(a), "product": int(p)}
             for a, p in re.findall(r"amount\s*=\s*(\d+)\s*,\s*product\s*=\s*(\d+)", packs_body or "")]
    kit_products = number_map(block("P = {" + prog + "}", r"\bProducts\s*=\s*\{")) if prog else {}
    mastery = re.search(r"MasteryPass\s*=\s*(\d+)", prog or "")
    live = re.search(r"\bLive\s*=\s*(true|false)", prog or "")
    # (23/11) the bundles (Config.Shop.Bundles: the 8 outfits), each a product
    bundles_body = block("Shop = {" + shop + "}", r"\bBundles\s*=\s*\{") if shop else ""
    bundles = [{"id": i, "product": int(n)} for i, n in re.findall(r'id\s*=\s*"(\w+)"\s*,\s*product\s*=\s*(\d+)', bundles_body or "")]
    return {"products": products, "passes": passes, "packs": packs, "kits": kit_products, "bundles": bundles,
            "mastery": int(mastery.group(1)) if mastery else 0, "live": (live.group(1) == "true") if live else None}


def shop_passes():
    body = block(strip_comments(read("Shared/Shop.luau")), r"Shop\.Passes\s*=\s*\{")
    return re.findall(r"\{id=\"(\w+)\",name=\"([^\"]+)\"", body or "")


def robux_looks():
    out = []
    for rel in ("Shared/Catalog.luau", "Shared/CatalogStyle.luau"):
        text = strip_comments(read(rel))
        for m in re.finditer(r"\{id=\"(\w+)\",slot=\"(\w+)\"[^\n]*?name=\"([^\"]+)\"[^\n]*?robux=\"(\w+)\"", text):
            out.append({"id": m.group(1), "slot": m.group(2), "name": m.group(3), "key": m.group(4), "file": rel})
    return out


def roster():
    return re.findall(r"\"(\w+)\"", strip_comments(read("Shared/BetaRoster.luau")))


def server_sources():
    return {p.name: p.read_text(encoding="utf-8") for p in (SRC / "Server").rglob("*.luau")}


# ------------------------------------------------------------------ reading the place

def place_scripts(rbxlx):
    out = {}
    values = {}
    for item in ET.parse(rbxlx).iter("Item"):
        props = item.find("Properties")
        if props is None:
            continue
        name = props.findtext("string[@name='Name']")
        cls = item.get("class")
        if cls in ("Script", "LocalScript", "ModuleScript"):
            out.setdefault(name, []).append(props.findtext("*[@name='Source']") or "")
        elif cls == "StringValue":
            values[name] = props.findtext("string[@name='Value']")
    return out, values


def git(*args):
    try:
        return subprocess.run(["git", *args], cwd=ROOT, capture_output=True, text=True, timeout=20).stdout.strip()
    except Exception:
        return ""


def same_sources(a, b):
    """Whether two commits ship the same game (what build.py reads: src, assets, build.py, vendor and
    the filming tools)."""
    try:
        return subprocess.run(["git", "diff", "--quiet", a, b, "--", "src", "assets", "build.py", "vendor", "tools/capture"],
                              cwd=ROOT, timeout=20, capture_output=True).returncode == 0
    except Exception:
        return False


# ------------------------------------------------------------------ the checks

class Report:
    def __init__(self):
        self.items = []

    def add(self, area, point, status, proof, fix=""):
        self.items.append({"area": area, "point": point, "status": status, "proof": proof, "fix": fix})

    @property
    def red(self):
        return [i for i in self.items if i["status"] == RED]


def check_offers(r):
    cfg = config_offers()
    passes = shop_passes()
    looks = robux_looks()
    kits = roster()
    server = server_sources()
    every_server = "\n".join(server.values())

    shown = []  # (kind, id, label, number)
    for pid, name in passes:
        number = cfg["mastery"] if pid == "MasteryPass" else cfg["passes"].get(pid, 0)
        shown.append(("passe", pid, name, number))
    for look in looks:
        shown.append(("apparence", look["id"], look["name"], cfg["products"].get(look["key"], 0)))
    for i, pack in enumerate(cfg["packs"]):
        shown.append(("Ryō", f"RyoPack{i + 1}", f"{pack['amount']} RYŌ", pack["product"]))
    # a bundle counts once a client screen shows it (Client/*: "Bundles")
    clients = "\n".join(p.read_text(encoding="utf-8") for p in (SRC / "Client").rglob("*.luau"))
    bundle_shown = "Bundles" in clients
    for b in cfg["bundles"]:
        if bundle_shown:
            shown.append(("lot", b["id"], b["id"], b["product"]))
    if cfg["bundles"] and not bundle_shown:
        r.add("Offres", "Les lots", ORANGE,
              f"{len(cfg['bundles'])} lot(s) dans Config.Shop.Bundles ({', '.join(b['id'] for b in cfg['bundles'])}), "
              "pas encore affiché(s) dans la boutique.",
              "Quand la boutique les montre, ils comptent dans « chaque offre affichée a un ID ».")

    missing = [s for s in shown if not s[3]]
    if missing:
        names = ", ".join(f"{label} ({kind})" for kind, _, label, _ in missing)
        r.add("Offres", "Chaque offre affichée a un ID", RED,
              f"{len(missing)} offres sur {len(shown)} affichent SOON, faute d'ID : {names}.",
              "François crée les offres sur la page du jeu et envoie les ID ; le DEV les met dans Shared/Config. "
              "Ou bien l'offre n'est plus affichée.")
    else:
        r.add("Offres", "Chaque offre affichée a un ID", GREEN, f"Les {len(shown)} offres affichées ont un ID.")

    unsold_kits = [k for k in kits if not cfg["kits"].get(k)]
    if unsold_kits:
        r.add("Offres", "Les kits en vente", ORANGE,
              f"{len(unsold_kits)} kits sur {len(kits)} sans ID (Config.Progression.Products) : ils ne sont pas affichés "
              f"en vente, seulement « TRY » ({', '.join(unsold_kits)}).",
              "Les 8 kits sont dans la liste des offres à créer ; sans ID, ils ne se vendent pas.")
    else:
        r.add("Offres", "Les kits en vente", GREEN, f"Les {len(kits)} kits ont un ID.")

    retired = []
    for pid, name in passes:
        if pid in RETIRED_PASSES:
            retired.append(f"{name} ({RETIRED_PASSES[pid]})")
    for look in looks:
        if look["slot"] in RETIRED_SLOTS:
            retired.append(f"{look['name']} ({RETIRED_SLOTS[look['slot']]})")
    if retired:
        r.add("Offres", "Aucune offre retirée n'est encore affichée", RED,
              "Encore dans la boutique : " + " ; ".join(retired) + ".",
              "DEC-049 : les retirer de Shared/Shop (passes) et de la vente en Robux (auras : récompenses ou Ryō, ANIMATEUR).")
    else:
        r.add("Offres", "Aucune offre retirée n'est encore affichée", GREEN, "Ni EARLY ACCESS, ni MORE BUILDS, ni aura en Robux.")

    numbers = {}
    for kind, oid, label, number in shown + [("kit", k, k, cfg["kits"].get(k, 0)) for k in kits]:
        if number:
            numbers.setdefault(number, []).append(label)
    dups = {n: labels for n, labels in numbers.items() if len(labels) > 1}
    if dups:
        r.add("Offres", "Aucun ID en double", RED,
              " ; ".join(f"{n} : {', '.join(labels)}" for n, labels in dups.items()) + ".",
              "Un ID = une offre : l'achat donnerait la première trouvée (Progression.productFor).")
    else:
        r.add("Offres", "Aucun ID en double", GREEN, f"{len(numbers)} ID, tous différents.")

    # Le jeu sait donner : un produit passe par Progression.productFor (kits, apparences, Ryō) ; une passe
    # doit être lue côté serveur (UserOwnsGamePassAsync avec son ID).
    receipts = "P.processReceipt" in every_server and "MarketplaceService\").ProcessReceipt" in every_server
    given_products = all(k in server.get("Progression.luau", "") for k in
                         ("P.config().Products", "P.shopConfig().Products", "P.shopConfig().RyoPacks"))
    if receipts and given_products:
        r.add("Offres", "Chaque produit a son effet", GREEN,
              "Kits, apparences et paquets de Ryō passent par le reçu (Server/Progression : processReceipt, productFor).")
    else:
        r.add("Offres", "Chaque produit a son effet", RED, "Le reçu des achats (ProcessReceipt / productFor) n'est pas trouvé.")
    owned_reads = re.findall(r"UserOwnsGamePassAsync\([^)]*\)", every_server)
    no_effect = []
    for pid, name in passes:
        if pid == "MasteryPass":
            ok = any("pass" in o for o in owned_reads) and "MasteryPass" in every_server
        else:
            ok = bool(re.search(r"Passes\s*(?:\.|\[\s*\")" + pid, every_server)) and bool(owned_reads)
        if not ok:
            no_effect.append(name)
    if no_effect:
        r.add("Offres", "Chaque passe a son effet", RED,
              f"Aucune lecture côté serveur de : {', '.join(no_effect)} (la passe s'achète, rien ne change).",
              "DEV, étape 5 n° 2 : l'effet de chaque passe vendue (VIP…), ou la passe n'est pas affichée.")
    else:
        r.add("Offres", "Chaque passe a son effet", GREEN, "Chaque passe affichée est lue côté serveur.")


def check_place(r, rbxlx, manifest_path, manifests):
    if not rbxlx.exists():
        r.add("Outils", "La place publiée existe", RED, f"{rbxlx.relative_to(ROOT)} n'existe pas.", "python3 build.py")
        return
    scripts, values = place_scripts(rbxlx)
    names = set(scripts)
    sources = "\n".join(s for srcs in scripts.values() for s in srcs)

    debug = sorted(names & DEBUG_ONLY)
    capture = sorted(names & CAPTURE_TOOLS)
    markers = [m for m in MARKERS if m in sources]
    flags = [f for f in ("NinjaDuelDebug", "NinjaDuelQA") if f'workspace:SetAttribute("{f}",true)' in sources]
    profile = values.get("BuildProfile")
    bad = debug + capture + markers + flags + ([] if profile == "release" else [f"BuildProfile={profile}"])
    if bad:
        r.add("Outils", "Aucun outil de debug ni de tournage", RED, "Dans la place : " + ", ".join(bad) + ".",
              "Publier la build release (python3 build.py), jamais Debug, QA ou Capture.")
    else:
        r.add("Outils", "Aucun outil de debug ni de tournage", GREEN,
              f"Profil release ; aucun des {len(DEBUG_ONLY)} modules Studio, des {len(CAPTURE_TOOLS)} outils de tournage, "
              f"des {len(MARKERS)} marqueurs de debug ; pas de drapeau NinjaDuelDebug/QA.")

    tests = sorted(n for n in names if n in TEST_NAMES or re.search(r"(\.spec|Spec|_spec|Test)$", n or ""))
    found = [m for m in TEST_MARKERS if m in sources]
    if tests or found:
        r.add("Test", "Pas de code de test dans la place", RED,
              "Dans la place : " + ", ".join(tests + found) + ".", "Ces fichiers restent dans tests/ et tools/.")
    else:
        r.add("Test", "Pas de code de test dans la place", GREEN,
              f"{len(names)} scripts : aucun spec, banc de test, robot ni outil de cabine.")

    head = git("rev-parse", "HEAD")
    dirty = bool(git("status", "--porcelain", "--", "src", "assets", "build.py", "vendor"))
    commit = values.get("SourceCommit") or ""
    manifest = json.loads(manifest_path.read_text()) if manifest_path.exists() else {}
    proof = f"Ligne de version de la place : SourceCommit {commit}, RuntimeFingerprint {(values.get('RuntimeFingerprint') or '')[:12]}."
    problems = []
    if not commit or commit.endswith("-dirty"):
        problems.append("la place a été construite avec des changements non commités")
    elif head and not head.startswith(commit[:12]) and not same_sources(commit[:12], head):
        problems.append(f"la place est du commit {commit[:8]}, les sources ont changé depuis (commit {head[:8]}) : reconstruire")
    if dirty:
        problems.append("des changements non commités dans src/, assets/ ou build.py")
    if manifest and manifest.get("runtimeFingerprint") != values.get("RuntimeFingerprint"):
        problems.append("le manifeste ne correspond pas à la place")
    others = {name: m.get("runtimeFingerprint") for name, m in manifests.items()}
    differ = [n for n, fp in others.items() if fp and fp != values.get("RuntimeFingerprint")]
    if differ:
        problems.append("le moteur diffère de celui de " + ", ".join(differ) + " (pas le même commit)")
    if problems:
        r.add("Version", "La ligne de version est la bonne", RED, proof + " " + " ; ".join(problems) + ".",
              "python3 build.py (et les 3 autres profils) sur le commit à publier, sans changement non commité.")
    else:
        r.add("Version", "La ligne de version est la bonne", GREEN,
              proof + f" Les sources n'ont pas changé depuis (HEAD {head[:8]}), sans changement non commité ; "
              f"même moteur que {', '.join(others) or 'les autres profils'}.")


def datastore_names():
    """The DataStores the server opens, read from the sources: {name: where}."""
    server = server_sources()
    out = {}
    repo = server.get("ProfileRepository.luau", "")
    store = re.search(r'StoreName="([^"]+)"', repo)
    dev = re.search(r'DevStoreName="([^"]+)"', repo)
    scope = re.search(r'Scope="([^"]+)"', repo)
    if store:
        out[store.group(1)] = {"where": "Server/ProfileRepository (profils)", "scope": scope.group(1) if scope else None,
                               "live": True}
    if dev:
        out[dev.group(1)] = {"where": "Server/ProfileRepository (Studio)", "scope": scope.group(1) if scope else None,
                             "live": False}
    for file, pattern in (("WeeklyExam.luau", r'W\.(STORE|CLIFF_STORE)="([^"]+)"'),
                          ("ChampionCliff.luau", r'Cliff\.(STORE)="([^"]+)"')):
        for const, name in re.findall(pattern, server.get(file, "")):
            suffix = "_<examen>" if const == "STORE" and file == "WeeklyExam.luau" else ""
            out[name + suffix] = {"where": f"Server/{file[:-5]}", "live": True}
    boards = server.get("Leaderboards.luau", "")
    for m in re.finditer(r'\{id="(\w+)",[^}]*store="([^"]+)",?([^}]*)\}', boards):
        rest = m.group(3)
        suffix = "_<semaine>" if "weekly=true" in rest else "_<examen>" if "exam=true" in rest else ""
        out[m.group(2) + suffix] = {"where": "Server/Leaderboards (classement, ordonné)", "live": True}
    kit_store = re.search(r'store="(\w+)_"\.\.kit', boards)
    if kit_store:
        for kit in roster():
            out[f"{kit_store.group(1)}_{kit}"] = {"where": "Server/Leaderboards (classement par kit)", "live": True}
    # (23/11) every other server file that opens a DataStore: a name written in the call,
    # or a constant *STORE*="…" of the file (Server/Reports: Reports.STORE="NinjaDuelReports")
    known = ("ProfileRepository.luau", "WeeklyExam.luau", "ChampionCliff.luau", "Leaderboards.luau")
    for file, text in server.items():
        if file in known or not re.search(r"Get(Ordered)?DataStore\(", text):
            continue
        found = set(re.findall(r'Get(?:Ordered)?DataStore\("([^"]+)"', text))
        found |= {name for _, name in re.findall(r'\b\w+\.(\w*STORE\w*)\s*=\s*"([^"]+)"', text)}
        for name in found:
            out.setdefault(name, {"where": f"Server/{file[:-5]}", "live": True})
    return out


def check_datastores(r, cfg):
    names = datastore_names()
    live = {n: v for n, v in names.items() if v["live"]}
    reference = json.loads(REFERENCE.read_text(encoding="utf-8")) if REFERENCE.exists() else None
    suspicious = [n for n in live if re.search(r"(?i)(dev|test|qa|debug|tmp|temp|lab)", n)]
    if suspicious:
        r.add("DataStore", "Les noms sont ceux du jeu publié", RED,
              "Un nom de DataStore du jeu publié ressemble à un nom de test : " + ", ".join(suspicious) + ".")
    elif reference is None:
        r.add("DataStore", "Les noms sont ceux du jeu publié", ORANGE,
              f"{len(live)} DataStore du jeu publié, sans liste de référence : " + ", ".join(sorted(live)) + ".",
              f"python3 tools/preflight/preflight.py --reference écrit {REFERENCE.relative_to(ROOT)}.")
    else:
        ref = set(reference.get("live", []))
        gone = sorted(ref - set(live))
        new = sorted(set(live) - ref)
        if gone:
            r.add("DataStore", "Les noms sont ceux du jeu publié", RED,
                  "Disparus depuis la référence : " + ", ".join(gone) + (" ; nouveaux : " + ", ".join(new) if new else "")
                  + ". Un nom changé, ce sont les données des joueurs perdues.",
                  "Remettre l'ancien nom, ou migrer les données, puis mettre à jour la référence (--reference).")
        elif new:
            r.add("DataStore", "Les noms sont ceux du jeu publié", ORANGE,
                  f"{len(live)} DataStore, dont nouveaux depuis la référence : " + ", ".join(new) + ".",
                  "Si c'est voulu : --reference pour l'enregistrer.")
        else:
            r.add("DataStore", "Les noms sont ceux du jeu publié", GREEN,
                  f"Les {len(live)} DataStore du jeu publié sont ceux de la référence ({REFERENCE.name}, "
                  f"{reference.get('date', '?')}).")
    profiles = [n for n, v in names.items() if v["where"].startswith("Server/ProfileRepository")]
    if cfg["live"] is not True:
        r.add("DataStore", "Le jeu publié sauvegarde les profils", RED,
              f"Config.Progression.Live = {cfg['live']} : sur un vrai serveur, rien n'est sauvegardé.",
              "Live = true (Shared/Config).")
    elif len(profiles) == 2:
        studio = [n for n in profiles if not names[n]["live"]][0]
        main = [n for n in profiles if names[n]["live"]][0]
        r.add("DataStore", "Le jeu publié sauvegarde les profils ; Studio a les siens", GREEN,
              f"Live = true ; profils dans {main} (portée {names[main].get('scope')}) ; Studio écrit dans {studio}.")
    else:
        r.add("DataStore", "Le jeu publié sauvegarde les profils ; Studio a les siens", RED,
              "ProfileRepository n'a pas un nom pour le jeu publié et un pour Studio.")
    return names


def check_codes(r, today):
    text = strip_comments(read("Shared/Codes.luau"))
    body = block(text, r"C\.List\s*=\s*\{") or ""
    codes = []
    for m in re.finditer(r"\{code=\"(\w+)\"([^\n]*)\}", body):
        rest = m.group(2)
        starts = re.search(r'starts="(\d{4}-\d\d-\d\d)"', rest)
        ends = re.search(r'ends="(\d{4}-\d\d-\d\d)"', rest)
        codes.append({"code": m.group(1), "starts": starts.group(1) if starts else None, "ends": ends.group(1) if ends else None})
    bad_dates = [c["code"] for c in codes if not c["ends"] or (c["starts"] and c["starts"] > c["ends"])]

    def live_on(day):
        return [c["code"] for c in codes if (not c["starts"] or c["starts"] <= day) and (c["ends"] and day <= c["ends"])]

    days = sorted({today} | {c["starts"] for c in codes if c["starts"] and c["starts"] >= today})
    worst = max(((d, live_on(d)) for d in days), key=lambda x: len(x[1]), default=(today, []))
    over = len(worst[1]) > 3
    expired = [c["code"] for c in codes if c["ends"] and c["ends"] < today]
    if bad_dates:
        r.add("Codes", "Les codes ont des dates valides", RED, "Sans fin ou fin avant le début : " + ", ".join(bad_dates) + ".")
    elif over:
        r.add("Codes", "3 codes actifs au plus en même temps", RED,
              f"Le {worst[0]}, {len(worst[1])} codes sont actifs : {', '.join(worst[1])}.",
              "La règle du CM : 3 au plus. Le CM décale une date (Shared/Codes).")
    else:
        r.add("Codes", "3 codes actifs au plus en même temps", GREEN,
              f"Au plus {len(worst[1])} codes actifs à la fois à partir du {today} ({len(codes)} codes"
              + (f", expirés : {', '.join(expired)}" if expired else "") + ").")


ELSEWHERE = [
    ("Achats", "Un achat donne une seule fois (reçu) ; un achat sur téléphone marche",
     "tests/Progression.spec (reçus) ; un achat réel dans la place de test (François)"),
    ("Données", "Rien ne se perd : déconnexion, changement de serveur, serveur qui ferme",
     "DEV, étape 5 n° 3 ; un essai dans la place de test"),
    ("Fluidité", "30 images/s ou plus sur un téléphone moyen, dans le village et en duel",
     "tools/perf (la matrice d'appareils de Studio)"),
    ("Premières minutes", "Un nouveau joueur fait son premier combat en moins de 2 minutes et le gagne",
     "tools/newplayer (le robot des 10 premières minutes) ; tests/DuelBot.spec"),
    ("Contenu", "Les 8 kits ont leur départ, leur arbre et leur transformation", "tools/kits (le comparateur)"),
    ("Page", "Icône, 3 images, description, bande-annonce, codes datés", "DESIGN et CM ; la page du jeu (François)"),
    ("Test", "3 à 5 joueurs ; leurs signalements bloquants sont corrigés", "tools/testread (la page de lecture du test)"),
]


# ------------------------------------------------------------------ output

def markdown(r, head, when, names):
    count = {s: sum(1 for i in r.items if i["status"] == s) for s in (GREEN, RED, ORANGE)}
    verdict = "PRÊT" if not r.red else "PAS PRÊT"
    lines = [f"# Pré-vol de publication : {verdict}", "",
             f"Commit {head[:8]}, {when}. {count[GREEN]} vert, {count[RED]} rouge, {count[ORANGE]} orange.", "",
             "| Domaine | Point | État | Preuve | Ce qu'il faut faire |", "|---|---|---|---|---|"]
    for i in r.items:
        lines.append(f"| {i['area']} | {i['point']} | **{i['status']}** | {i['proof']} | {i['fix']} |")
    lines += ["", "## Ce que le pré-vol ne prouve pas (la preuve est ailleurs)", "",
              "| Domaine | Point | Où |", "|---|---|---|"]
    lines += [f"| {a} | {p} | {w} |" for a, p, w in ELSEWHERE]
    lines += ["", "## Les DataStore du jeu", "", "| Nom | Où | Jeu publié |", "|---|---|---|"]
    lines += [f"| `{n}` | {v['where']} | {'oui' if v['live'] else 'non (Studio)'} |" for n, v in sorted(names.items())]
    return "\n".join(lines) + "\n"


def page(r, head, when):
    colour = {GREEN: "#2e7d4f", RED: "#c0392b", ORANGE: "#d68910"}
    rows = "".join(
        f"<tr><td>{html.escape(i['area'])}</td><td>{html.escape(i['point'])}</td>"
        f"<td><span class='s' style='background:{colour[i['status']]}'>{i['status']}</span></td>"
        f"<td>{html.escape(i['proof'])}</td><td>{html.escape(i['fix'])}</td></tr>" for i in r.items)
    rest = "".join(f"<tr><td>{html.escape(a)}</td><td>{html.escape(p)}</td><td>{html.escape(w)}</td></tr>"
                   for a, p, w in ELSEWHERE)
    verdict = "PRÊT À PUBLIER" if not r.red else f"PAS PRÊT : {len(r.red)} point(s) rouge(s)"
    return f"""<!doctype html><html lang="fr"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Pré-vol de publication</title><style>
body{{font:15px/1.45 system-ui,sans-serif;margin:24px;color:#1b1b1f;background:#f6f3ee}}
h1{{margin:0 0 4px}} .v{{font-weight:700;color:{'#2e7d4f' if not r.red else '#c0392b'}}}
table{{border-collapse:collapse;width:100%;margin:12px 0 24px;background:#fff}}
td,th{{border:1px solid #ddd;padding:8px;vertical-align:top;text-align:left}}
.s{{color:#fff;padding:2px 8px;border-radius:4px;font-weight:700;font-size:13px}}
</style></head><body><h1>Pré-vol de publication</h1>
<p class="v">{verdict}</p><p>Commit {html.escape(head[:8])}, {html.escape(when)}.</p>
<table><tr><th>Domaine</th><th>Point</th><th>État</th><th>Preuve</th><th>Ce qu'il faut faire</th></tr>{rows}</table>
<h2>Ce que le pré-vol ne prouve pas</h2>
<table><tr><th>Domaine</th><th>Point</th><th>Où est la preuve</th></tr>{rest}</table></body></html>
"""


def run(today=None):
    r = Report()
    cfg = config_offers()
    check_offers(r)
    manifests = {}
    for name in ("NinjaDuel-Debug.json", "NinjaDuel-QA.json", "NinjaDuel-Capture.json"):
        p = DIST / name
        if p.exists():
            manifests[name[:-5]] = json.loads(p.read_text())
    check_place(r, DIST / "NinjaDuel.rbxlx", DIST / "NinjaDuel.json", manifests)
    names = check_datastores(r, cfg)
    check_codes(r, today or datetime.date.today().isoformat())
    return r, names


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--build", action="store_true", help="python3 build.py (release) first")
    ap.add_argument("--md")
    ap.add_argument("--json")
    ap.add_argument("--html")
    ap.add_argument("--today", help="the day the codes are checked at (YYYY-MM-DD)")
    ap.add_argument("--reference", action="store_true", help=f"write today's DataStore names to {REFERENCE.name}")
    a = ap.parse_args(argv)
    if a.build:
        subprocess.run([sys.executable, "build.py"], cwd=ROOT, check=True, capture_output=True)
    if a.reference:
        names = datastore_names()
        REFERENCE.write_text(json.dumps({"date": datetime.date.today().isoformat(), "commit": git("rev-parse", "HEAD")[:8],
                                         "live": sorted(n for n, v in names.items() if v["live"]),
                                         "studio": sorted(n for n, v in names.items() if not v["live"])},
                                        ensure_ascii=False, indent=1) + "\n", encoding="utf-8")
        print(f"wrote {REFERENCE.relative_to(ROOT)}")
        return 0
    r, names = run(a.today)
    head = git("rev-parse", "HEAD")
    when = datetime.datetime.now().strftime("%d/%m/%Y %H:%M")
    for i in r.items:
        print(f"{i['status']:6} {i['area']:10} {i['point']} : {i['proof']}")
    print(("PRÊT À PUBLIER" if not r.red else f"PAS PRÊT : {len(r.red)} rouge(s)"))
    if a.md:
        Path(a.md).write_text(markdown(r, head, when, names), encoding="utf-8")
    if a.json:
        Path(a.json).write_text(json.dumps({"commit": head, "when": when, "ready": not r.red, "items": r.items,
                                            "datastores": names}, ensure_ascii=False, indent=1), encoding="utf-8")
    if a.html:
        Path(a.html).write_text(page(r, head, when), encoding="utf-8")
    return 0 if not r.red else 1


if __name__ == "__main__":
    sys.exit(main())
