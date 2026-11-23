#!/usr/bin/env python3
"""Ce qui a été fait et n'est pas dans le jeu (23/11, François : « tout ce qui a été fait doit
être ajouté »).

Liste chaque branche distante qui a du travail absent de la branche commune. Un fichier compte
comme absent quand sa version de la branche n'a jamais été sur la branche commune depuis leur
point commun (ni aujourd'hui, ni dans son histoire). Une version remplacée plus tard ne compte
donc pas.

Ne sont pas listés :
- les brouillons, dont chaque commit commence par « wip », « scratch » ou « work: », ou dit
  « not for merge » ;
- les branches déjà jugées dans `ALREADY_JUDGED` (avec la raison) ;
- les branches sans histoire commune (on ne les fusionne jamais).

    python3 tools/branches/unmerged.py          # code 1 s'il reste du travail à intégrer
    python3 tools/branches/unmerged.py --all    # brouillons et branches jugées compris

Le DEV le lance à chaque passe, avant d'annoncer une étape (DEC-050).
"""
import subprocess
import sys

COMMON = "origin/claude/ninja-duel-2026-10-14"
# Branches regardées une fois et laissées de côté, avec leur raison (CURRENT_STATE, 23/11).
ALREADY_JUDGED = {
    "origin/claude/minato-hiraishin-kunai": "le kunai à trois branches de Minato adulte, rejeté",
    "origin/claude/b1-lot4-paused": "essai de performance mis en pause (FadePool)",
    "origin/codex/weapon-forge-tycoon-v0": "un autre jeu",
    "origin/claude/ninja-duel-tutorial-v2": "récupéré le 23/11 (docs/archive/2026-11-05-tutorial-v2) ; le code vers Discord n'est pas repris",
    "origin/codex/ninja-fight-continuity": "récupéré le 23/11 ; ses tests d'octobre ne sont pas repris",
    "origin/codex/ninja-chakra-interactions": "documents archivés le 23/11 ; code remplacé (ChakraFlow)",
    "origin/codex/ninja-devtools-online": "documents archivés le 23/11 ; code remplacé (Online)",
    "origin/codex/ninja-progression-foundations": "documents archivés le 23/11 ; code remplacé (Progression)",
    "origin/codex/forge-motion-lab-ui-edit": "documents archivés le 23/11 ; script Kimi non repris",
    "origin/codex/forge-motion-lab": "Motion Lab d'octobre, remplacé par la version de la branche commune",
    "origin/claude/nd-v35-correctifs": "correctifs sur la v35 (05/11), repris dans les v36-v39",
    "origin/claude/boutique-robux-marche": "deux comptoirs de la boutique (14/11), écrans refaits depuis par la DESIGN",
    "origin/work/cm-etape2-fiches": "une entrée de boîte de réception du 21/11 ; les fiches sont sur la branche commune",
    "origin/claude/vfx-redesign": "fusionnée le 23/11",
    "origin/claude/qa-combats-2026-11-14": "fusionnée le 23/11",
    "origin/cm/codes-ouverture": "fusionnée le 23/11",
}
# Generated files: rebuilt by build.py, never integrated by hand.
GENERATED = ("/dist/",)
DRAFT = ("wip", "scratch", "work:", "views")


def git(*args):
    r = subprocess.run(["git", *args], capture_output=True, text=True)
    return r.stdout.strip() if r.returncode == 0 else None


def history_blobs(path, base, cache):
    key = (path, base)
    if key not in cache:
        blobs = set()
        for c in (git("rev-list", COMMON, "^" + base, "--", path) or "").split():
            b = git("rev-parse", f"{c}:{path}")
            if b:
                blobs.add(b)
        cache[key] = blobs
    return cache[key]


def lines_landed(base, branch, path):
    """The lines the branch added to a text file are (nearly all) in the common file: its edit
    landed, rebased among the others' (SINCE_LAST_CLAUDE, CURRENT_STATE...)."""
    diff = git("diff", base, branch, "--", path) or ""
    added = [l[1:].strip() for l in diff.splitlines() if l.startswith("+") and not l.startswith("+++") and len(l.strip()) > 8]
    if not added or "Binary files" in diff:
        return False
    common = set(l.strip() for l in (git("show", f"{COMMON}:{path}") or "").splitlines())
    return sum(1 for l in added if l in common) >= .9 * len(added)


def main():
    show_all = "--all" in sys.argv
    git("fetch", "-q", "origin")
    cache, todo = {}, 0
    landed = set((git("log", "--format=%s", COMMON) or "").splitlines())
    for b in (git("branch", "-r") or "").splitlines():
        b = b.strip()
        if "->" in b or b == COMMON:
            continue
        if not int(git("rev-list", "--count", f"{COMMON}..{b}") or 0):
            continue
        base = git("merge-base", COMMON, b)
        if not base:
            if show_all:
                print(f"{b} : sans histoire commune (jamais fusionnée)")
            continue
        # its own commits: those whose subject never reached the common branch (a commit
        # rebased onto it keeps its subject)
        own = [line.split(" ", 1) for line in (git("log", "--no-merges", "--format=%H %s", f"{COMMON}..{b}") or "").splitlines()]
        own = [(h, s) for h, s in own if s not in landed]
        if not own:
            continue
        draft = all(s.lower().startswith(DRAFT) or "not for merge" in s.lower() for _, s in own)
        if (draft or b in ALREADY_JUDGED) and not show_all:
            continue
        files = set()
        for h, _ in own:
            files.update((git("diff-tree", "--no-commit-id", "--name-only", "-r", h) or "").splitlines())
        missing = []
        for f in sorted(files):
            if any(g in f for g in GENERATED):
                continue
            blob = git("rev-parse", f"{b}:{f}")
            if not blob or blob == git("rev-parse", f"{COMMON}:{f}") or blob in history_blobs(f, base, cache):
                continue
            if lines_landed(base, b, f):
                continue
            missing.append(f)
        if not missing:
            continue
        why = ALREADY_JUDGED.get(b) or ("brouillon" if draft else None)
        if not why:
            todo += 1
        print(f"{b} ({git('log', '-1', '--format=%cs', b)}) : {len(missing)} fichiers absents" + (f" — {why}" if why else " — À INTÉGRER"))
        for f in missing[:10]:
            print("   " + f)
    print(f"{todo} branche(s) avec du travail à intégrer")
    return 1 if todo else 0


if __name__ == "__main__":
    sys.exit(main())
