#!/bin/bash
# Ninja Duel — reconstruit LA place du jeu depuis GitHub et la range dans
# ~/Documents/NinjaDuel/PLACES/NinjaDuel.rbxlx (DEC-052 : un seul jeu, une seule place,
# avec ses outils de dev, de tournage et les robots qu'on y lance).
#
#   bash ~/Documents/NinjaDuel/_outils/actualiser_places.sh                  # branche canonique
#   bash ~/Documents/NinjaDuel/_outils/actualiser_places.sh <branche|commit> # autre référence
#
# Fermer la place concernée dans Studio avant. Une place modifiée dans Studio
# (son sha256 ne correspond plus à son manifeste) n'est jamais écrasée : elle est
# mise de côté dans _maintenance/places-modifiees-dans-studio/.
# Une ancienne version se reconstruit à l'identique : actualiser_places.sh <sha>.
set -euo pipefail
REF="${1:-claude/ninja-duel-2026-10-14}"
REPO="https://github.com/francoisdebono8-rgb/roblox-dev"
DOCS="$HOME/Documents"; [ -d "$HOME/mnt/Documents" ] && DOCS="$HOME/mnt/Documents"
ND="$DOCS/NinjaDuel"; PLACES="$ND/PLACES"
SRC="$(mktemp -d "${TMPDIR:-/tmp}/ninja-duel-src.XXXXXX")"
echo "Source : $REPO @ $REF"
git clone -q --filter=blob:none --no-checkout "$REPO" "$SRC"
git -C "$SRC" checkout -q "$REF"
COMMIT="$(git -C "$SRC" rev-parse HEAD)"
cd "$SRC/games/ninja-duel"
python3 build.py --capture > /dev/null
python3 - "$SRC/games/ninja-duel/dist" "$PLACES" "$ND" "$COMMIT" "$REF" <<'PY'
import hashlib, json, os, shutil, sys, time
dist, places, nd, commit, ref = sys.argv[1:]
names = {'NinjaDuel-Capture': 'NinjaDuel'}
man = {k: json.load(open(os.path.join(dist, k + '.json'))) for k in names}
runtime = {m['runtimeFingerprint'] for m in man.values()}
assert len(runtime) == 1, 'les profils n\'ont pas le même runtime'
os.makedirs(places, exist_ok=True)
stamp = time.strftime('%Y-%m-%d_%H%M')
def sha(p):
    h = hashlib.sha256()
    with open(p, 'rb') as f:
        for c in iter(lambda: f.read(1 << 22), b''): h.update(c)
    return h.hexdigest()
# Ouverte dans Studio : rien n'est touché.
opened = [n for n in names.values() if os.path.exists(os.path.join(places, n + '.rbxlx.lock'))]
if opened:
    sys.exit('Ouverte(s) dans Studio : ' + ', '.join(opened) + ' — aucune place modifiée. Fermer puis relancer.')
for k, n in names.items():
    target = os.path.join(places, n + '.rbxlx')
    old_manifest = os.path.join(places, n + '.json')
    if os.path.exists(target) and os.path.exists(old_manifest):
        if sha(target) != json.load(open(old_manifest)).get('sha256'):
            keep = os.path.join(nd, '_maintenance', 'places-modifiees-dans-studio')
            os.makedirs(keep, exist_ok=True)
            os.rename(target, os.path.join(keep, f'{stamp}_{n}.rbxlx'))
            print(f'  ! {n} avait été modifiée dans Studio : mise de côté dans _maintenance/places-modifiees-dans-studio/')
    shutil.copyfile(os.path.join(dist, k + '.rbxlx'), target)
    shutil.copyfile(os.path.join(dist, k + '.json'), old_manifest)
role = {'NinjaDuel': 'le jeu : y jouer et y tester (outils de dev F6 / F7, tournage, robots)'}
with open(os.path.join(places, 'VERSION.md'), 'w', encoding='utf-8') as f:
    source = {m['sourceCommit'] for m in man.values()}.pop()
    f.write(f'# La place du jeu Ninja Duel\n\nConstruites le {time.strftime("%d/%m/%Y à %H:%M")} depuis GitHub `{ref}`, commit `{commit[:12]}` (sources du commit `{source[:12]}`).\n')
    f.write(f'Runtime : `{runtime.pop()[:12]}`.\n\n')
    f.write('| Fichier | Pour | Profil | buildFingerprint | sha256 |\n|---|---|---|---|---|\n')
    for k, n in names.items():
        m = man[k]
        f.write(f'| {n}.rbxlx | {role[n]} | {m["profile"]} | `{m["buildFingerprint"][:12]}` | `{m["sha256"][:12]}` |\n')
    f.write('\nAu Play, la sortie Studio affiche `[NinjaDuel] BUILD … | RUNTIME … | <profil> @ <commit>`.\n'
            'Pour une autre version : `bash ~/Documents/NinjaDuel/_outils/actualiser_places.sh <branche|commit>`.\n')
print(open(os.path.join(places, 'VERSION.md'), encoding='utf-8').read())
PY
echo "(source temporaire : $SRC — peut être effacée)"
