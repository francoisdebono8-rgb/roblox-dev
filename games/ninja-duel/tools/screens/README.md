# Le relevé des écrans du parcours (OUTILLEUR, passe commune 1, DEC-051)

François, 23/11 : « les UI ne sont pas assez jolies et il y a des erreurs ».

Le parcours d'un nouveau joueur est joué comme un joueur, écran après écran, dans un Play de la place du jeu (DEC-052, `PLACES/NinjaDuel.rbxlx`, sans copie), `NDScreenTour` envoyé dans le client (`python3 tools/robots/inject.py screens`). À chaque écran :
- **un clic ou une touche** : robloxstudio-mcp `simulate_mouse_input`, au centre que donne `--find` ou `--look`, en points de la fenêtre de jeu, cible `client-1` ; ou `simulate_keyboard_input` ;
- **une capture** de la fenêtre (`capture_screenshot`) ;
- **la sortie de Studio depuis l'écran d'avant** : `get_runtime_logs`, dont on garde le curseur. Les lignes rouges sont les erreurs, les orange les avertissements.

`NDScreenTour` dit ce qui est à l'écran : les boutons (texte et centre), les grands textes, les nouvelles lignes rouges du client.

```sh
python3 tools/screens/releve.py --look              # Client : boutons, grands textes, lignes rouges nouvelles
python3 tools/screens/releve.py --find "TAKE IT"    # Client : le centre du bouton
python3 tools/screens/releve.py --red-server 1      # Server : lignes rouges et orange depuis la ligne 1
python3 tools/screens/releve.py --page mesures/<dossier>/releve.json --html releve.html --md releve.md
python3 tools/screens/releve.py --page APRES.json --avant AVANT.json --avant-images ../<dossier d'avant> --html releve.html   # les deux côte à côte
```

Chaque relevé est un dossier de `mesures/` :
- **les captures**, en 1334 px de large ;
- **`releve.json`** : pour chaque écran, comment on y arrive, l'image, les remarques, et les lignes rouges et orange de chaque côté ;
- **la page**, en Markdown et en HTML.

## Avant la passe (23/11 au soir, place commune `d0678d90` de `890f237a`)

`mesures/2026-11-23_avant_d0678d90/` : 21 écrans, de l'arrivée à la défaite contre l'IA, en passant par la boutique et TRY THIS KIT. Fenêtre de 1334 × 590, clavier et souris.

- **Aucune ligne rouge.** Il y a des orange, toutes au démarrage :
  - 9 « Failed to create empty EditableImage » et 30 « EditableMesh … memory budget » ;
  - 4 images d'effets que Roblox ne sert pas (`VfxHit`), 9 autres (`AwakenFX`) ;
  - des assets refusés (« not authorized », 4 identifiants) et un introuvable.
- **Ce qui se voit**, écran par écran, est dans `releve.md` : le bandeau d'inspiration qui cache le haut, le portrait vide, une victoire qui ne dit pas ce qu'on a gagné, PAID WITH ROBUX au-dessus de kits gratuits, TRY THIS KIT qui annonce un adversaire et en montre un autre, des touches qui ne collent pas (ZQSD et WASD), des textes coupés ou qui débordent.

## Après la passe (24/11, place commune `c40cc16d`, sources `db13098f`, `PLACES/NinjaDuel.rbxlx`, profil capture)

`mesures/2026-11-24_apres_c40cc16d/` : les 21 mêmes écrans, et 3 nouveaux, le racket (l'offre, le combat, la défaite). La page `releve.html` les met à côté de ceux d'avant.

- **Toujours aucune ligne rouge.** Les orange : 20 « EditableMesh … memory budget » (30 avant), 9 « EditableImage », les images de `VfxHit` et `AwakenFX`, les 4 assets refusés. L'asset introuvable n'y est plus.
- **Corrigé par la passe** : le but CHOOSE YOUR INSPIRATION ne barre plus le haut de l'écran ; la bulle du passant est au-dessus de sa tête ; TRY THIS KIT montre une étape à la fois dans la légende du coach ; un seul onglet de la boutique a l'air choisi ; le classement vide s'explique ; les flèches de YOUR NINJA se voient ; le portrait du premier duel a une image ; la tunique a un revers et une ceinture.
- **Pas encore** : la victoire du premier duel ne dit rien de ce qu'on a gagné et les Ryō restent à 0 ; PAID WITH ROBUX au-dessus des kits gratuits ; THE PERFECT BROTHER coupé ; « CHAKRA » qui déborde des cartes ; la carte et ses noms qui se chevauchent ; G qui n'ouvre rien ; les tenues SOON en pictogrammes et l'aperçu vide ; les combattants presque noirs dans DUELS ; les kits de départ verrouillés sans prévenir ; le corps du joueur effacé en duel.
- **Nouveau à regarder** : l'adversaire de TRY THIS KIT a des cheveux jaunes alors que l'écran annonce THE FATED GENIUS ; l'essai dit CTRL pour courir, Konoha dit SHIFT ; le panneau du racket cache le voyou et la ligne des touches ; perdu contre le voyou, l'écran dit « +20 RYŌ » alors que la bourse ne bouge pas (le voyou a pris 20) ; « 1 POINTS TO SPEND ».
- **La pastille F4 et les deux traits rouges** des captures sont l'outil de tournage du profil capture (DEC-052), pas le jeu.

## Ce qu'il ne prouve pas

- Ce qui est joli : les remarques sont celles de Claude, pas l'avis de François.
- Les touches 1, 2, 3 du panneau du racket : le clavier simulé de Studio les refuse (une limite de l'outil, pas forcément du jeu).
- Un téléphone : ce relevé est en fenêtre d'ordinateur. Le simulateur de téléphone doit être mis avant le Play (`tools/perf`).
- Les écrans du jeu publié qui ont besoin des DataStore (classements, Examen) : ils sont vides dans Studio.
