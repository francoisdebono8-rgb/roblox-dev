# Ninja Duel — tournoi de jeunes prodiges

Entrée unique pour une nouvelle session : [CLAUDE_START_HERE.md](CLAUDE_START_HERE.md). État et priorités : [CURRENT_STATE](docs/active/CURRENT_STATE.md) et [MASTER_BACKLOG](docs/active/MASTER_BACKLOG.md).

Version technique `0.13.0-arena-combo`. Ouvrir `dist/NinjaDuel.rbxlx` dans Roblox Studio puis Test. Sélectionner Minato, Itachi, Neji ou Sasuke, puis Duel ou Interactive Tutorial. Gaara reste serveur/tests et n’est pas sélectionnable dans le menu actuel. Match joueur contre IA ; validation native finale distincte des tests automatiques.

The build manifest records automated and native status separately (`automatedQA`, `nativeQA`, `visualAcceptance`, `controllerFeel`). Controller feel and native Studio behaviour remain human gates; open the exact normal artifact above for the final pass. Pass history and open items: `docs/reports/STABILITY_PASS.md` (0.6.0 bugs), `docs/reports/FLUIDITY_PASS.md` (0.6.1 feel), `docs/reports/ANIMATION_PASS.md` (0.7.0 body animation, reactions, impact).

| Controller | Action |
|---|---|
| Left stick / click LS | Move / toggle sprint |
| Right stick / click RS | Camera / lock |
| X / Square | Light; third light finishes horizontally; throw while grabbing |
| Y / Triangle | Heavy; launcher after two confirmed lights; air slam; upward throw |
| A / Cross | Jump / contextual chase / mantle / wall rebound |
| B / Circle | Directional evade / substitution after a fresh hit |
| LB / L1; LT / L2; RT / R2 | Guard; grab; kunai/shuriken |
| RB + A / X / Y / B | Techniques 1 / 2 / 3 / 4 |
| D-pad up; View / touchpad | Technique 5; skip tutorial |
| D-pad / left stick + A | Menu selection and activation |

### Keyboard (grouped around WASD)

| Key | Action |
|---|---|
| **WASD** | Move |
| **LMB** | Light chain (third light finishes; throws while grabbing) |
| **RMB** | Heavy — launcher after two confirmed lights, air slam, upward throw |
| **SPACE** | Jump / wall rebound / contextual chase |
| **Q** | Dodge (becomes substitution right after being hit) |
| **F** | Guard (hold) |
| **V** | Grab |
| **R** | Kunai / shuriken |
| **E** | Chase during the launch window |
| **X** | Substitution (accessible, but never next to the movement keys) |
| **G / C** | Feint / wall detach |
| **CTRL / SHIFT** | Sprint / lock-on |
| **1–5** | Jutsu |
| Mouse move / wheel | Free-look when unlocked; camera distance |
| **ESC** | Skip tutorial |

Every key is declared once in `src/Shared/Controls.luau`, which also feeds the on-screen help and the tutorial copy. A key can never drive two actions; `tests/Regression.spec.luau` enforces that.

Ground-to-air route: **light → light → heavy launcher → chase → air light → air light → heavy slam**. A third grounded light chooses Bangla's finisher instead. Whiffs retain recovery; substitution spends charge/chakra; knockdown has a protected wakeup.

## Build and tests

Depuis la racine du repository :

```
python3 games/ninja-duel/build.py          # normal place  -> dist/NinjaDuel.rbxlx
python3 games/ninja-duel/build.py --qa     # QA place      -> dist/NinjaDuel-QA.rbxlx
games/ninja-duel/tests/run.sh              # every headless suite
```

`build.py` runs all headless suites against the exact sources it embeds and refuses to write an artifact if one fails; the result is recorded in `dist/NinjaDuel.json` under `automatedQA`.

| Suite | Covers |
|---|---|
| `tests/Rules.spec.luau` | pure policy: states, costs, cooldowns, token bucket |
| `tests/Combat.spec.luau` | combat, donour migrations, controller callbacks, choreography |
| `tests/Sequences.spec.luau` | routes de séquences, camera, AI et joints ; matrice quatre personnages dans Preparation |
| `tests/Regression.spec.luau` | the bugs fixed in this pass, plus a randomised soak |
| `tests/Feedback.spec.luau` | contact feed and impact hierarchy |
| `tests/Animation.spec.luau` | stances, directional locomotion, hit reactions, knockdown/KO, weapons, and a full-fight no-snap contract |

Suites supplémentaires enregistrées dans `tests/run.sh` : Branches, Phase4, Neji, Systems, Tools, Sasuke, Gaara (serveur caché), Preparation. Total actuel : 14 suites /139 cas. L’isolation normal/debug/QA ajoute 4 tests Python.

The headless suites share `tests/Harness.luau`, a stubbed Roblox environment. They prove timing and state, not Studio physics, rendering or controller feel.

The native suite lives in `dist/NinjaDuel-QA.rbxlx`: open it in Studio, press **Test**, and read `[NinjaDuelQA] START 0.7.0-animation` followed by one `PASS`/`FAIL` line per case and the totals. `nativeQA` stays `PENDING` in the manifest until that run is recorded on the exact artifact.

## Acceptation native du normal

Suivre la [matrice quatre personnages](docs/FOUR_CHARACTER_COMBAT_MATRIX.md) : Minato, Itachi, Neji et Sasuke face à chaque IA (16 matchups). Course huit directions/orbite/sprint/stop, jump/air/ledge/wall, lock/free/swap/verticalité ; contact/whiff/light branches/heavy launcher/chase/airslam/throw ; guard/parry/dodge/substitution/counter/clash ; outils et chaque conversion de kit, ressources/awake ; KO/reset/rematch/menu/tutoriel et manette.

Noter artefact/hash/HEAD, erreurs et premier échange corporel ou contrôle non convaincant. Les vieux PASS et leurs bases sont dans reports/archive ; l’état présent est CURRENT_STATE. Notices/imports : `THIRD_PARTY.md`.

## Préparation technique Claude — quatre personnages

Depuis `games/ninja-duel` pour les commandes ci-dessous. Voir [la matrice](docs/FOUR_CHARACTER_COMBAT_MATRIX.md) et [le handoff](docs/current/CLAUDE_TECHNICAL_HANDOFF.md).

- `python3 build.py --debug` crée `dist/NinjaDuel-Debug.rbxlx` pour l’inspecteur Studio en lecture seule (F8).
- `python3 build.py` exclut DevHooks, CombatInspector, CombatDebug et NativeQA du build normal.
- `python3 build.py --qa` reste le build séparé de régression native ; il inclut aussi les diagnostics.
- `lune run tools/combat_inventory.luau` régénère le mapping des actions depuis le renderer actuel.
- `python3 -m unittest discover -s tests -p 'test_build_isolation.py'` vérifie les trois artefacts après leur build.
- `python3 motion-lab/build.py` extrait, teste et package Motion Lab ; aucune installation/publication automatique.

L’inspecteur ne crée pas de nouvel état de combat et ne modifie ni mouvements, dégâts, timings de combat, caméra, animations ou direction artistique.
