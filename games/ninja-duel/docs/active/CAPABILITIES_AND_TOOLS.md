# Capacités et outils disponibles

Depuis la racine du repository, dépendances Python 3, Luau et Lune ; aucun binaire système ni login Studio n’est garanti par GitHub. `tests/run.sh` cherche LUAU/LUNE, NINJA_DUEL_TOOLS, puis PATH ; les builders documentent aussi les chemins locaux. Installer les outils requis dans le nouvel environnement avant de conclure PASS.

```sh
bash games/ninja-duel/tests/run.sh
python3 games/ninja-duel/build.py
python3 games/ninja-duel/build.py --debug
python3 games/ninja-duel/build.py --qa
python3 -m unittest discover -s games/ninja-duel/tests -p test_build_isolation.py
python3 tools/check_architecture.py
python3 games/ninja-duel/tools/check_project_docs.py
python3 games/ninja-duel/motion-lab/build.py
```

Les builds du jeu exécutent les 14 suites et vérifient leurs sources embarquées. Lire les manifests : un résultat SKIPPED faute d’outil n’est pas PASS. Motion Lab construit le binaire, teste 45 cas et simule ses événements UI ; une simulation n’est pas Studio réel.

| Capacité | Où / contrat | Limite |
|---|---|---|
| Jeu normal | `dist/NinjaDuel.rbxlx` | Ouvrir en Studio puis Test ; ne contient aucun outil QA optionnel |
| Debug | `dist/NinjaDuel-Debug.rbxlx`, F8 en Studio | Remote debug opt-in, inspect/trace/contracts lecture seule ; peut être désactivé |
| QA | `dist/NinjaDuel-QA.rbxlx` | DevHooks/NativeQA séparés du normal ; consulter handoff et matrice |
| Inventaire de combat | [COMBAT_INVENTORY](../current/COMBAT_INVENTORY.json), `tools/combat_inventory.luau` | Données extraites, pas un jugement artistique |
| Mapping motion/attaque | [MOTION_ATTACK_MAPPING](../current/MOTION_ATTACK_MAPPING.md) | 84 mappings, clips hérités visibles ; ne pas remplacer par fallback |
| Contrats combat | [COMBAT_CONTRACTS](../current/COMBAT_CONTRACTS.md) | Phases, états, cancellation, outils/hooks : préciser les frontières avant modification |
| Laboratoire | [README Lab](../../motion-lab/README.md), `motion-lab/build.py` | Preview, A/B, L/R, mixer/DNA, variantes, séquences, export JSON/poses inert |
| Adapter | `motion-lab/ForgeMotionLab/Modules/NinjaDuelAdapter.luau` | Intégration manuelle choisie par Claude ; aucune dépendance runtime vers Lab |
| Simulation de balance | `tests/Balance.sim.luau` | Non incluse dans les 14 suites ; ne pas annoncer exécution sans commande/preuve |

La disponibilité réelle d’un hook/provider de contrôle Studio dépend de la session et de l’environnement. Une UI visible ne constitue pas une exécution de protocole. Ni replay.sh ni sweep.lua mentionnés dans de vieux briefs ne sont garantis : vérifier leur existence avant usage. La publication demande accès/permission et autorisation correspondant au plan, pas des suppositions tirées d’archives.

Codex prépare preuves, outils, contrats, recherche et scaffolding utile. Claude conserve le jugement natif sur feel, techniques, corps et intégration. [Structure du projet](../tools/PROJECT_STRUCTURE.md) ; [handoff technique détaillé](../current/CLAUDE_TECHNICAL_HANDOFF.md).

Modifications sûres dans cette préparation : documentation, registres et outils de lecture/validation sans mutation du combat. Pour une implémentation approuvée, privilégier une correction ciblée ; préserver les moteurs/contrats existants, validation serveur, source mapping/héritages, profils Lab et exports inertes. Ne remplacer ni moteur de combat ni pipeline d’animation à cause d’une ancienne mission. Ne retuner dégâts/costs/timings/camera pendant une passe documentaire.
