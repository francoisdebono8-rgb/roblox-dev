#!/usr/bin/env python3
"""La place commune automatique (OUTILLEUR, 20/11 ; DEC-043, étape 1, OUTILLEUR 1).

Après chaque lot poussé sur `claude/ninja-duel-2026-10-14`, les 4 places
(ND-JEU, ND-DEV, ND-QA, ND-FILM) sont reconstruites au même commit et posées
dans ~/Documents/NinjaDuel/PLACES, sans que personne ait à le lancer.

Un agent macOS (launchd) lance `place_commune.py --une-fois` toutes les 2 min :
  1. il lit le dernier commit de la branche sur GitHub (`git ls-remote`) ;
  2. il attend que la branche n'ait pas bougé depuis 3 min : un lot de plusieurs
     poussées n'est construit qu'une fois, à la fin ;
  3. il construit les 4 profils de ce commit (`build.py`, `--debug`, `--qa`,
     `--capture`) dans son propre clone, vérifie qu'ils ont le même runtime, et
     les range dans PLACES/_prochaine/ : elles sont prêtes ;
  4. si aucune des 4 places n'est ouverte dans Studio (pas de `.lock`), il les
     pose dans PLACES et récrit VERSION.md ; sinon elles attendent dans
     _prochaine, et il les pose au premier passage où plus rien n'est ouvert.
     Une place modifiée dans Studio n'est jamais écrasée : elle est mise de
     côté, comme le fait actualiser_places.sh ;
  5. une notification macOS dit ce qui s'est passé.

Rien n'est effacé : les places sont déplacées (os.replace), une ancienne place
modifiée dans Studio est rangée dans _maintenance/places-modifiees-dans-studio.

    python3 place_commune.py --une-fois      un passage (ce que lance l'agent)
    python3 place_commune.py --etat          où en est la place commune
    python3 place_commune.py --installer     copie le script dans _outils et installe l'agent
    python3 place_commune.py --desinstaller  arrête l'agent (le script reste)

Journal : ~/Documents/NinjaDuel/_maintenance/place-commune/journal.log
"""
from __future__ import annotations

import argparse
import hashlib
import json
import os
import shutil
import subprocess
import sys
import time

REPO = "https://github.com/francoisdebono8-rgb/roblox-dev"
BRANCH = "claude/ninja-duel-2026-10-14"
LABEL = "com.ninjaduel.placecommune"
STABLE = 180          # s sans nouvelle poussée avant de construire
INTERVAL = 120        # s entre deux passages de l'agent
NAMES = {"NinjaDuel": "ND-JEU", "NinjaDuel-Debug": "ND-DEV", "NinjaDuel-QA": "ND-QA", "NinjaDuel-Capture": "ND-FILM"}
PROFILES = {"NinjaDuel": [], "NinjaDuel-Debug": ["--debug"], "NinjaDuel-QA": ["--qa"], "NinjaDuel-Capture": ["--capture"]}
ROLE = {"ND-JEU": "tester le jeu comme un joueur", "ND-DEV": "développer (outils de dev, devcall, F6)",
        "ND-QA": "tests natifs automatiques (agents)", "ND-FILM": "filmer (DEV + outils de tournage)"}
PYTHONS = ["/Library/Frameworks/Python.framework/Versions/Current/bin/python3", "/usr/local/bin/python3",
           "/opt/homebrew/bin/python3", "/usr/bin/python3"]


class Place:
    """Les chemins d'une installation (ND = ~/Documents/NinjaDuel par défaut)."""

    def __init__(self, nd: str, repo: str = REPO, branch: str = BRANCH, stable: float = STABLE,
                 python: str | None = None, notify=None, clock=time.time):
        self.nd = nd
        self.places = os.path.join(nd, "PLACES")
        self.staging = os.path.join(self.places, "_prochaine")
        self.work = os.path.join(nd, "_maintenance", "place-commune")
        # (le clone git vit hors de Documents sur le Mac : un dossier partagé avec
        # une session Claude n'accepte pas les suppressions que git fait)
        cache = os.path.expanduser("~/Library/Caches") if sys.platform == "darwin" else self.work
        self.clone = os.path.join(cache, "ninja-duel-place-commune") if sys.platform == "darwin" else os.path.join(self.work, "depot")
        self.state_path = os.path.join(self.work, "etat.json")
        self.journal = os.path.join(self.work, "journal.log")
        self.repo, self.branch, self.stable = repo, branch, stable
        self.python = python or pick_python()
        self.notify = notify if notify is not None else mac_notify
        self.clock = clock

    # ---------------------------------------------------------------- outils
    def log(self, text: str) -> None:
        os.makedirs(self.work, exist_ok=True)
        with open(self.journal, "a", encoding="utf-8") as f:
            f.write(time.strftime("%Y-%m-%d %H:%M:%S ", time.localtime(self.clock())) + text + "\n")

    def state(self) -> dict:
        try:
            with open(self.state_path, encoding="utf-8") as f:
                return json.load(f)
        except (FileNotFoundError, ValueError):
            return {}

    def save(self, st: dict) -> None:
        os.makedirs(self.work, exist_ok=True)
        tmp = self.state_path + ".tmp"
        with open(tmp, "w", encoding="utf-8") as f:
            json.dump(st, f, ensure_ascii=False, indent=1)
        os.replace(tmp, self.state_path)

    def git(self, *args: str, cwd: str | None = None, timeout: int = 300) -> str:
        r = subprocess.run(["git", *args], cwd=cwd, capture_output=True, text=True, timeout=timeout)
        if r.returncode != 0:
            raise RuntimeError(f"git {' '.join(args)} : {r.stderr.strip()[-300:]}")
        return r.stdout.strip()

    # ---------------------------------------------------------------- étapes
    def remote_head(self) -> str:
        out = self.git("ls-remote", self.repo, "refs/heads/" + self.branch, timeout=60)
        if not out:
            raise RuntimeError("branche introuvable : " + self.branch)
        return out.split()[0]

    def opened(self) -> list[str]:
        """Les places ouvertes dans Studio (Studio pose un .lock à côté)."""
        return [n for n in NAMES.values() if os.path.exists(os.path.join(self.places, n + ".rbxlx.lock"))]

    def build(self, sha: str) -> dict:
        """Construit les 4 profils de `sha` et les range dans _prochaine. Renvoie l'info du commit."""
        if not os.path.isdir(os.path.join(self.clone, ".git")):
            os.makedirs(self.work, exist_ok=True)
            self.git("clone", "-q", "--filter=blob:none", "--no-checkout", self.repo, self.clone, timeout=900)
        self.git("fetch", "-q", "origin", f"+refs/heads/{self.branch}:refs/remotes/origin/{self.branch}",
                 cwd=self.clone, timeout=900)
        self.git("checkout", "-q", "-f", "--detach", sha, cwd=self.clone, timeout=900)
        game = os.path.join(self.clone, "games", "ninja-duel")
        subject = self.git("log", "-1", "--format=%s", sha, cwd=self.clone)
        when = self.git("log", "-1", "--format=%cd", "--date=format:%d/%m %H:%M", sha, cwd=self.clone)
        dist = os.path.join(game, "dist")
        for key, flags in PROFILES.items():
            r = subprocess.run([self.python, "build.py", *flags], cwd=game, capture_output=True, text=True, timeout=900)
            if r.returncode != 0:
                raise RuntimeError(f"build.py {' '.join(flags) or '(release)'} : {(r.stderr or r.stdout).strip()[-400:]}")
        manifests = {}
        for key in NAMES:
            with open(os.path.join(dist, key + ".json"), encoding="utf-8") as f:
                manifests[key] = json.load(f)
        runtimes = {m.get("runtimeFingerprint") for m in manifests.values()}
        if len(runtimes) != 1:
            raise RuntimeError("les 4 profils n'ont pas le même runtime : " + ", ".join(sorted(map(str, runtimes))))
        os.makedirs(self.staging, exist_ok=True)
        for key, name in NAMES.items():
            shutil.copyfile(os.path.join(dist, key + ".rbxlx"), os.path.join(self.staging, name + ".rbxlx"))
            shutil.copyfile(os.path.join(dist, key + ".json"), os.path.join(self.staging, name + ".json"))
        info = {"commit": sha, "subject": subject, "when": when, "runtime": runtimes.pop(),
                "built": time.strftime("%d/%m/%Y à %H:%M", time.localtime(self.clock()))}
        with open(os.path.join(self.staging, "commit.json"), "w", encoding="utf-8") as f:
            json.dump(info, f, ensure_ascii=False, indent=1)
        with open(os.path.join(self.staging, "LISEZ-MOI.md"), "w", encoding="utf-8") as f:
            f.write(f"# Places prêtes, pas encore posées\n\nCommit `{sha[:12]}` ({when}) : {subject}\n\n"
                    "Elles seront posées dans PLACES dès qu'aucune place n'est ouverte dans Studio. "
                    "Pour les poser tout de suite : fermer ND-JEU, ND-DEV, ND-QA et ND-FILM dans Studio, puis\n"
                    "`python3 ~/Documents/NinjaDuel/_outils/place_commune.py --une-fois`.\n")
        return info

    def staged(self) -> dict | None:
        try:
            with open(os.path.join(self.staging, "commit.json"), encoding="utf-8") as f:
                info = json.load(f)
        except (FileNotFoundError, ValueError):
            return None
        if all(os.path.exists(os.path.join(self.staging, n + ".rbxlx")) for n in NAMES.values()):
            return info
        return None

    def install(self, info: dict) -> list[str]:
        """Pose les 4 places de _prochaine dans PLACES (toutes ou aucune). Renvoie les mises de côté."""
        aside = []
        stamp = time.strftime("%Y-%m-%d_%H%M", time.localtime(self.clock()))
        for name in NAMES.values():
            target = os.path.join(self.places, name + ".rbxlx")
            manifest = os.path.join(self.places, name + ".json")
            if os.path.exists(target) and os.path.exists(manifest):
                with open(manifest, encoding="utf-8") as f:
                    expected = json.load(f).get("sha256")
                if expected and sha256(target) != expected:
                    keep = os.path.join(self.nd, "_maintenance", "places-modifiees-dans-studio")
                    os.makedirs(keep, exist_ok=True)
                    os.replace(target, os.path.join(keep, f"{stamp}_{name}.rbxlx"))
                    aside.append(name)
        for name in NAMES.values():
            os.replace(os.path.join(self.staging, name + ".rbxlx"), os.path.join(self.places, name + ".rbxlx"))
            os.replace(os.path.join(self.staging, name + ".json"), os.path.join(self.places, name + ".json"))
        self.write_version(info)
        os.replace(os.path.join(self.staging, "commit.json"), os.path.join(self.work, "derniere-pose.json"))
        return aside

    def write_version(self, info: dict) -> None:
        man = {}
        for name in NAMES.values():
            with open(os.path.join(self.places, name + ".json"), encoding="utf-8") as f:
                man[name] = json.load(f)
        source = {m.get("sourceCommit", "") for m in man.values()}.pop()
        with open(os.path.join(self.places, "VERSION.md"), "w", encoding="utf-8") as f:
            f.write("# Places de travail Ninja Duel\n\n")
            f.write(f"Posées automatiquement le {info['built']} (place commune, `_outils/place_commune.py`) "
                    f"depuis GitHub `{self.branch}`, commit `{info['commit'][:12]}` ({info['when']}) : {info['subject']}\n")
            f.write(f"Sources du commit `{source[:12]}`. Runtime commun (le même jeu dans les 4) : `{str(info['runtime'])[:12]}`.\n\n")
            f.write("| Fichier | Pour | Profil | buildFingerprint | sha256 |\n|---|---|---|---|---|\n")
            for name in NAMES.values():
                m = man[name]
                f.write(f"| {name}.rbxlx | {ROLE[name]} | {m.get('profile')} | `{str(m.get('buildFingerprint'))[:12]}` | `{str(m.get('sha256'))[:12]}` |\n")
            f.write("\nAu Play, la sortie Studio affiche `[NinjaDuel] BUILD … | RUNTIME … | <profil> @ <commit>`.\n"
                    "Journal de la place commune : `_maintenance/place-commune/journal.log`.\n"
                    "Pour une autre version : `bash ~/Documents/NinjaDuel/_outils/actualiser_places.sh <branche|commit>`.\n")

    def same_as_installed(self) -> bool:
        """Les places prêtes sont-elles octet pour octet celles qui sont déjà posées ?"""
        for name in NAMES.values():
            try:
                with open(os.path.join(self.staging, name + ".json"), encoding="utf-8") as f:
                    new = json.load(f).get("sha256")
                with open(os.path.join(self.places, name + ".json"), encoding="utf-8") as f:
                    old = json.load(f).get("sha256")
            except (FileNotFoundError, ValueError):
                return False
            if not new or new != old or not os.path.exists(os.path.join(self.places, name + ".rbxlx")):
                return False
        return True

    # ---------------------------------------------------------------- un passage
    def tick(self) -> str:
        """Un passage. Renvoie ce qui s'est passé, en une ligne (aussi écrite au journal)."""
        st = self.state()
        now = self.clock()
        try:
            head = self.remote_head()
        except Exception as e:  # pas de réseau : on réessaie au passage suivant
            return self.done(st, "GitHub injoignable : " + str(e), quiet=True)
        if head != st.get("seen"):
            st["seen"], st["seenAt"] = head, now
            self.save(st)
        if st.get("built") != head:
            if now - st.get("seenAt", now) < self.stable:
                return self.done(st, f"{head[:8]} vu, attend la fin du lot ({int(self.stable - (now - st['seenAt']))} s)", quiet=True)
            try:
                info = self.build(head)
            except Exception as e:
                first = st.get("failed") != head
                if first:
                    st["failed"] = head
                    self.save(st)
                    self.notify("Place commune : construction impossible", f"{head[:8]} : {str(e)[:120]}")
                return self.done(st, f"échec de la construction de {head[:8]} : {e}", quiet=not first)
            st["built"] = head
            st.pop("failed", None)
            st.pop("waitingFor", None)
            self.save(st)
            self.log(f"{head[:8]} construit : {info['subject']}")
        info = self.staged()
        if not info:
            return self.done(st, f"à jour ({head[:8]})", quiet=True)
        if self.same_as_installed():
            # même jeu octet pour octet : les places restent, seuls leurs
            # manifestes et VERSION.md passent au nouveau commit (les copies
            # prêtes restent dans _prochaine, récrites à la prochaine construction)
            for name in NAMES.values():
                os.replace(os.path.join(self.staging, name + ".json"), os.path.join(self.places, name + ".json"))
            self.write_version(info)
            os.replace(os.path.join(self.staging, "commit.json"), os.path.join(self.work, "derniere-pose.json"))
            return self.done(st, f"{info['commit'][:8]} : places identiques aux places posées, VERSION.md mis à jour")
        opened = self.opened()
        if opened:
            if st.get("waitingFor") != info["commit"]:
                st["waitingFor"] = info["commit"]
                self.save(st)
                self.notify("Place commune prête", f"{info['commit'][:8]} attend : fermer {', '.join(opened)} dans Studio")
            return self.done(st, f"{info['commit'][:8]} prêtes dans PLACES/_prochaine, ouvertes : {', '.join(opened)}", quiet=True)
        aside = self.install(info)
        st.pop("waitingFor", None)
        self.save(st)
        line = f"{info['commit'][:8]} posées dans PLACES : {info['subject']}"
        if aside:
            line += " (mises de côté, modifiées dans Studio : " + ", ".join(aside) + ")"
        self.notify("Places Ninja Duel à jour", f"{info['commit'][:8]} — {info['subject'][:90]}")
        return self.done(st, line)

    def done(self, st: dict, line: str, quiet: bool = False) -> str:
        # les attentes répétées ne remplissent pas le journal : une ligne quand elles changent
        if not quiet or st.get("lastQuiet") != line.split(" (")[0]:
            self.log(line)
            if quiet:
                st["lastQuiet"] = line.split(" (")[0]
                self.save(st)
        return line

    def status(self) -> str:
        st = self.state()
        lines = [f"Branche : {self.branch}"]
        try:
            lines.append(f"Sur GitHub : {self.remote_head()[:12]}")
        except Exception as e:
            lines.append(f"Sur GitHub : injoignable ({e})")
        lines.append(f"Dernier construit : {str(st.get('built', '—'))[:12]}")
        info = self.staged()
        lines.append(f"Prêtes, pas encore posées : {info['commit'][:12]} ({info['subject']})" if info else "Rien en attente.")
        if self.opened():
            lines.append("Ouvertes dans Studio : " + ", ".join(self.opened()))
        try:
            with open(os.path.join(self.places, "VERSION.md"), encoding="utf-8") as f:
                lines.append(f.read().split("\n\n")[1].strip())
        except (FileNotFoundError, IndexError):
            pass
        return "\n".join(lines)


def sha256(path: str) -> str:
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(1 << 22), b""):
            h.update(chunk)
    return h.hexdigest()


def pick_python() -> str:
    for p in PYTHONS:
        if os.path.exists(p):
            return p
    return sys.executable


def mac_notify(title: str, text: str) -> None:
    if sys.platform != "darwin":
        return
    script = f'display notification {json.dumps(text)} with title {json.dumps(title)}'
    subprocess.run(["osascript", "-e", script], capture_output=True, timeout=15)


def default_nd() -> str:
    docs = os.path.expanduser("~/Documents")
    if os.path.isdir(os.path.expanduser("~/mnt/Documents")):
        docs = os.path.expanduser("~/mnt/Documents")
    return os.path.join(docs, "NinjaDuel")


# ---------------------------------------------------------------- l'agent macOS
def plist(script: str, python: str, nd: str) -> str:
    logs = os.path.join(nd, "_maintenance", "place-commune")
    return f"""<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key><string>{LABEL}</string>
  <key>ProgramArguments</key>
  <array><string>{python}</string><string>{script}</string><string>--une-fois</string></array>
  <key>StartInterval</key><integer>{INTERVAL}</integer>
  <key>RunAtLoad</key><true/>
  <key>LowPriorityIO</key><true/>
  <key>Nice</key><integer>10</integer>
  <key>StandardOutPath</key><string>{logs}/agent.out.log</string>
  <key>StandardErrorPath</key><string>{logs}/agent.err.log</string>
</dict>
</plist>
"""


def install_agent(nd: str) -> str:
    if sys.platform != "darwin":
        return "L'agent ne s'installe que sur macOS."
    outils = os.path.join(nd, "_outils")
    os.makedirs(outils, exist_ok=True)
    os.makedirs(os.path.join(nd, "_maintenance", "place-commune"), exist_ok=True)
    script = os.path.join(outils, "place_commune.py")
    if os.path.abspath(__file__) != os.path.abspath(script):
        shutil.copyfile(os.path.abspath(__file__), script)
    python = pick_python()
    agents = os.path.expanduser("~/Library/LaunchAgents")
    os.makedirs(agents, exist_ok=True)
    path = os.path.join(agents, LABEL + ".plist")
    with open(path, "w", encoding="utf-8") as f:
        f.write(plist(script, python, nd))
    uid = str(os.getuid())
    subprocess.run(["launchctl", "bootout", f"gui/{uid}/{LABEL}"], capture_output=True)
    r = subprocess.run(["launchctl", "bootstrap", f"gui/{uid}", path], capture_output=True, text=True)
    if r.returncode != 0:
        return f"agent écrit ({path}) mais pas lancé : {r.stderr.strip()}"
    return f"Agent installé : {path}, toutes les {INTERVAL} s, avec {python}."


def uninstall_agent() -> str:
    if sys.platform != "darwin":
        return "Rien à faire hors de macOS."
    path = os.path.expanduser(f"~/Library/LaunchAgents/{LABEL}.plist")
    r = subprocess.run(["launchctl", "bootout", f"gui/{os.getuid()}/{LABEL}"], capture_output=True, text=True)
    if os.path.exists(path):
        os.replace(path, path + ".arrete")
    return "Agent arrêté." if r.returncode == 0 else f"Agent arrêté (il ne tournait pas : {r.stderr.strip()[:80]})."


def main(argv=None) -> int:
    ap = argparse.ArgumentParser(description="La place commune : les 4 places reconstruites après chaque lot.")
    ap.add_argument("--une-fois", action="store_true", help="un passage (l'agent)")
    ap.add_argument("--etat", action="store_true", help="où en est la place commune")
    ap.add_argument("--installer", action="store_true", help="installe l'agent macOS")
    ap.add_argument("--desinstaller", action="store_true", help="arrête l'agent macOS")
    ap.add_argument("--nd", default=None, help="le dossier NinjaDuel (par défaut ~/Documents/NinjaDuel)")
    args = ap.parse_args(argv)
    nd = args.nd or default_nd()
    if args.installer:
        print(install_agent(nd))
        return 0
    if args.desinstaller:
        print(uninstall_agent())
        return 0
    place = Place(nd)
    if args.etat:
        print(place.status())
        return 0
    print(place.tick())
    return 0


if __name__ == "__main__":
    sys.exit(main())
