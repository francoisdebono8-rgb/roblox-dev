# Ninja Duel V0.2 — prototype Roblox Studio

Prototype de duel ninja 1 contre 1 contre une IA. Ouvrir **`dist/NinjaDuel.rbxlx`** dans Roblox Studio, puis cliquer sur **Test**. Aucun plugin, asset externe ni compte de publication n'est nécessaire. Les personnages Flashstep et Mirage sont des prototypes originaux destinés à tester deux boucles de combat différentes. Les références de la mission à des personnages de fiction restent internes et ne sont pas des assets du jeu.

## Commandes

| Action | Commande |
| --- | --- |
| Déplacer / tourner autour de l'adversaire verrouillé | WASD |
| Sprinter | Ctrl maintenu |
| Grand saut / saut court en relâchant | Espace |
| Esquive directionnelle, utilisable une fois par saut | Q + direction |
| Chaîne de quatre coups | Clic gauche, à répéter pendant l'ouverture après un coup confirmé |
| Poursuivre un adversaire lancé par le quatrième coup | E |
| Garde | F maintenu |
| Techniques | 1, 2, 3 |
| Basculer le verrouillage et la caméra | Maj gauche |

Flashstep est plus rapide et contrôle mieux l'air ; sa lame peut créer une ancre pour un déplacement risqué. Mirage préfère la moyenne distance, peut lire une attaque frontale et poser un leurre. Les techniques consomment du chakra, ont un délai et peuvent généralement être interrompues pendant leur préparation.

## Construction et vérification

La source Luau est sous `src/Shared`, `src/Server` et `src/Client`. Le serveur valide actions, portée, ligne de vue, coûts, temps de récupération, mouvement et entrées réseau. `build.py` incorpore ces sources dans des places Roblox XML autonomes et écrit des manifestes de hachage SHA-256. La place QA inclut seule `NativeQA.luau`; celle destinée au jeu ne l'embarque pas.

```sh
python3 games/ninja-duel/build.py
python3 games/ninja-duel/build.py --qa
```

Pour le test natif, ouvrir `dist/NinjaDuel-QA.rbxlx`, lancer **Test**, puis chercher `[NinjaDuelQA] TOTAL` dans la fenêtre Output. Le test couvre rig R15, accélération/saut, chaîne/poursuite, esquive aérienne, quatre appariements, techniques/interruption, IA, validation distante et deux rematches. `tests/Rules.spec.luau` couvre séparément les règles pures avec Luau CLI si installé.

L'animation actuelle est **procédurale et provisoire**. Elle apporte des poses distinctes et des transitions amorties sur un rig R15, mais n'atteint pas encore la qualité d'animations authored. Voir [ANIMATION_TODO.md](ANIMATION_TODO.md) pour le travail Studio restant. Le verdict sur le plaisir du déplacement et du combat après 30 secondes doit venir d'un essai humain ; les tests automatisés ne le remplacent pas.
