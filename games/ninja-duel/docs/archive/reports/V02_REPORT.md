# Ninja Duel V0.2 — état du prototype

V0.2 répond à `games/ninja-duel/docs/archive/missions/legacy-v0/COMBAT_FEEL_V02.md` par une refonte du déplacement et de la mêlée, sans élargir le roster. La place jouable est `../../dist/NinjaDuel.rbxlx`; `../../dist/NinjaDuel-QA.rbxlx` ajoute les seuls tests Studio natifs. Les manifestes JSON adjacents donnent les SHA-256 et contrôlent que chaque source embarquée correspond à `../../src`.

## Changements de la phase 2

- `../../src/Server/Motor.luau`, `Combat.luau` et `Config.luau` : accélération/freinage, sprint, contrôle aérien, grand saut avec relâchement, dash directionnel au sol ou en l'air, atterrissage, chaîne de quatre coups avec déplacement, lancement et poursuite à coût en chakra. Les actions et déplacements restent arbitrés côté serveur ; les traversées vérifient la géométrie.
- `../../src/Server/World.luau` et `Fighters.luau` : deux rigs R15, joints standard, poses procédurales amorties ; Flashstep a davantage de vitesse et de contrôle aérien, Mirage davantage de portée tactique et une boucle de lecture/leurre.
- `../../src/Client/Input.luau`, `Main.client.luau`, `Camera.luau`, `UI.luau` : nouvelles commandes, verrouillage, cadrage à deux combattants, FOV lié à la vitesse, impulsion de caméra sur dégâts et informations de poursuite/chaîne.
- `../../src/Server/AI.luau` : sprint d'approche, cercle, esquive, saut occasionnel, poursuite après lancement et latence de réaction conservée. `Matches.luau`, `Rules.luau` et `Techniques.luau` maintiennent sélection, rematch, validation réseau, coûts/cooldowns, interruptions et particularités des deux combattants.
- `../../build.py` produit les places autonomes. `NativeQA.luau` est inclus uniquement dans la place QA.

## Vérifications effectuées

Le 9 octobre 2026, la compilation Luau de toutes les sources et des tests a réussi. La suite de règles pures a produit **7 PASS**. La place QA reconstruite à partir des sources finales (`SHA-256 f47cf8608e8bace684a7178abe54293929e85156660b7698611854239f4e4cfa`) a été ouverte et exécutée dans Roblox Studio 0.742.0.7421053 : **18 PASS / 0 FAIL**. Elle couvre notamment le saut visible, les quatre coups mobiles, la poursuite, l'esquive aérienne unique, les quatre appariements, les techniques et interruptions, l'IA, la validation des requêtes et deux rematches. Une inspection en jeu confirme que la sélection, le duel, l'arène, les deux rigs et le HUD s'affichent. Aucun `CreatorError` lié au jeu n'a été relevé pendant ce passage ; Studio a émis l'avertissement non bloquant `Player:Move called, but player currently has no character` lors du chargement client.

## Qualité encore provisoire

Les rigs R15 et leurs poses, les portraits, les impacts et l'arène sont volontairement faits de formes simples. Les animations ne sont pas des clips authored, les sons ne sont pas encore intégrés, et les marqueurs de synchronisation audio/VFX restent à faire. Le ressenti « envie de refaire un match » exige un essai humain de trente secondes à une minute avec les deux personnages ; les scénarios automatisés démontrent que les systèmes fonctionnent, pas que ce ressenti est atteint. La procédure précise d'animation est dans `../current/ANIMATION_TODO.md`.

Les trois améliorations les plus rentables ensuite : (1) réaliser et intégrer un jeu d'animations R15 originales avec transitions et marqueurs ; (2) affiner les fenêtres de mêlée, réactions, sons et impacts après captures/essais humains ; (3) tester latence et prédiction de déplacement sur deux vrais clients avant de préparer du PvP.
