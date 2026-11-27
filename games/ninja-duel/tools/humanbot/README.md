# Le robot humain (OUTILLEUR, 27/11)

François a demandé : « simule des comportements humains partout : clique plusieurs fois pour choisir des tenues, ouvre et ferme des menus, mouvements illogiques pour un robot, les clics dans la boutique, les menus, en combat… ».

Le robot a deux parties, et ne prend jamais l'écran, la souris ni le clavier du Mac (DEC-052).

1. **Les mains** sont les outils d'entrée de Studio : `user_mouse_input` et `user_keyboard_input` du MCP Roblox Studio.
   - Un seul appel joue une liste de clics, de touches et d'attentes dans le Play, pas sur le Mac.
   - `chaos.py` écrit ces listes à la manière d'un joueur pressé et maladroit. Les attentes sont irrégulières : parfois une rafale, parfois une hésitation.
   - Une graine (`--seed`) rejoue exactement la même suite de gestes.
2. **Le témoin** regarde ce qui casse pendant que les mains jouent. Il a une partie client (`human_watch.luau`, `NDHumanWatch`) et une partie serveur (`human_server.luau`, `NDHumanServer`).
   - Pour chaque bug, il garde les derniers gestes qui l'ont précédé : c'est la façon de le reproduire.

## Ce que fait chaque humeur (`chaos.py`)

| Humeur | Ce que fait le joueur | Mains |
|---|---|---|
| `frenzy` | clique en rafale sur les cases du menu ouvert (tenues, boutique, tablettes de kits), souvent deux ou trois fois la même | souris + scan |
| `dither` | ouvre puis ferme, clique la même chose deux fois, puis une autre | souris + scan |
| `everything` | chaque bouton visible une fois, dans le désordre | souris + scan |
| `wander` | marche sans logique : une touche puis l'opposée, des sauts en plein virage, Shift par à-coups, le double saut à répétition | clavier |
| `roam` | (27/11, deuxième partie) court partout : W et Shift tenus longtemps, dérive avec A ou D, sauts (double espace) par-dessus ce qui gêne, demi-tour avec S | clavier |
| `mash` | se bat sans plan : rafales de touches, esquive répétée, garde lâchée au milieu, chiffres des techniques, touches des menus en plein combat | clavier |
| `mashclicks` | la souris d'un combat : rafales de clics gauches, un clic droit de temps en temps | souris |
| `menukeys` | les touches des menus enchaînées et superposées (M, B, Tab, G, Backspace, Return, E) | clavier |

Ce que les mains ne font pas :
- **Échap** : c'est le menu de Roblox, il arrêterait les mains, pas le jeu.
- **Les boutons en Robux** : la fenêtre d'achat attendrait un humain.
- **Les outils de développement** (F4, Freecam…).

## Ce que voit le témoin

Sur le client :
- **clic mort** : un clic sur un bouton visible qui ne répond pas. Un bouton redessiné au moment du clic compte comme une réponse.
- **erreur rouge** : une ligne rouge dans la sortie.
- **menus ensemble** : deux menus ouverts l'un sur l'autre.
- **souris bloquée** : un menu ouvert avec la souris bloquée au centre.
- **hors écran** : un bouton d'un menu hors de l'écran, sans liste qui défile.
- **texte coupé** : un texte qui ne tient pas dans sa case.
- **corps bloqué** : le corps demande à bouger mais ne bouge pas.
- **chute**, **projeté**, **à-coup** (une image de plus de 0,5 s ; toutes celles de plus de 0,25 s sont notées).
- **tenue** : une tenue en double, un corps nu, une pièce équipée mais pas portée.

Sur le serveur :
- chaque commande du profil (achat, équipement, choix, apprentissage), avec les Ryō avant et après ;
- un paiement pris deux fois ;
- des Ryō faux ;
- les lignes rouges.

Les coups de rue (`_G.NDHumanWatch.fists(secondes, graine)`) passent par le code du client du jeu (`HubFightClient:press`, ce que son clic appelle), au rythme d'un joueur : rafales de légers, un lourd de temps en temps, une esquive, des pauses. Les mains de Studio ne les déclenchent pas (voir plus bas).

## Lancer

Les commandes se lancent pendant un Play de la place du jeu, dans une Studio à soi (voir `tools/robots/README.md`).

```sh
python3 tools/robots/inject.py human                  # Client : le témoin
python3 tools/robots/inject.py --server humanserver   # Serveur : puis _G.NDHumanServer.start()
python3 tools/humanbot/report.py --start              # Client : _G.NDHumanWatch.start(true)
# Client : _G.NDHumanWatch.scan()  →  les boutons cliquables (x, y pour user_mouse_input)
python3 tools/humanbot/chaos.py frenzy --seed 8 --scan SCAN.json --n 22   # → user_mouse_input
python3 tools/humanbot/chaos.py wander --seed 12 --n 30                   # → user_keyboard_input
python3 tools/humanbot/report.py --read               # Client : le journal compact
python3 tools/humanbot/report.py --server             # Serveur : ses commandes
python3 tools/humanbot/report.py MESURE.json --md RAPPORT.md
```

Mesures du 27/11 : coordonnées, gestes et outils, avec deux pièges :
- **Les coordonnées** de `user_mouse_input` sont celles de l'interface (`AbsolutePosition`), soit le y de l'écran moins la barre de Roblox (58 px dans cette Studio). Le scan les donne telles quelles.
- **Un chemin d'objet** (`instance_path`) n'est pas utilisable : les cadres du HUD s'appellent tous `Frame`, donc un chemin en désigne plusieurs.
- **Les gestes** arrivent dans le jeu marqués « déjà traités » (`gameProcessedEvent` vrai), pour les deux outils de Studio.
  - Le combat de duel (ContextActionService) et la marche les reçoivent.
  - Les coups de rue (`Client/HubFightClient`, qui ignore une entrée « traitée ») ne les reçoivent pas.
  - Les coups de rue ne se testent donc pas avec ces mains : `tools/streetfight` les presse par le code du jeu.
- **`VirtualInputManager`** n'est appelable ni depuis `eval_client_runtime` ni depuis `execute_luau` (« lacking capability RobloxScript ») : les mains ne peuvent pas vivre dans le Luau.

## Le 27/11 : un nouveau joueur maladroit, de la forêt au duel

Conditions (NATIVE_STUDIO) :
- place `PLACES/_prochaine/NinjaDuel.rbxlx` (`ac418a18`), dans une Studio à soi, Play solo, profil neuf ;
- 4 fenêtres Studio ouvertes sur le Mac ;
- 16 minutes de jeu : 243 clics et 152 touches ; 140 boutons ont répondu ; 9 commandes du profil, toutes acceptées ;
- aucune ligne rouge, ni client ni serveur ;
- aucun paiement en double, aucune tenue en double.

Fichiers : `mesures/2026-11-27_ac418a18/` (`journal.json`, `rapport.md`, `images/`). Ce qui suit vient des mesures et des captures de Claude, pas de l'avis de François.

1. **Dans la forêt, B ouvre l'écran du tournoi**, et on y prend son kit de départ avant la porte.
   - Le bandeau du bas dit « B DUELS » pendant l'intro, et « THE GREAT GATE IS AHEAD » reste au milieu de l'écran du tournoi.
   - Après des clics sur ONLINE DUEL, HOST PRIVATE DUEL et JOIN, les kits perdent leurs marques LOCKED et START, et le bouton devient « ENTER THE STAGE ».
   - Deux clics sur ENTER THE STAGE : le serveur fait `chooseStarter Lion`.
   - Le profil est alors `intro` vide, `kits.selected = Lion`, `needsIntro = false` : à la session suivante, plus de forêt ni de carte de création.
   - Images : `01`, `02`, `03`.
2. **La carte de création (WHO ARE YOU?) déborde**, à la hauteur de cette Studio.
   - Onglet HAIR : la 5e rangée passe sous NEXT et THAT'S ME, et la suite sort de la carte et de l'écran. TOPKNOT, LONG BRAID, UNDERCUT CREST, CURTAINS et **YOUR OWN HAIR** sont inatteignables, sans défilement.
   - Onglet COLOUR : six couleurs sortent aussi.
   - La carte est en tailles fixes (cases de 150 px) : un écran plus petit en cache davantage.
   - Image : `04`.
3. **Des menus s'empilent** : les boutons DUELS, SHOP, RANKS, QUESTS et THE 8 restent cliquables à côté d'un menu ouvert.
   - RANKS puis SHOP puis DUELS laisse LEADERBOARDS, SHOP et l'écran du tournoi ouverts ensemble.
   - Tab pendant la carte de création ouvre CONTROLS dessous, et CONTROLS reste ouvert à l'arrivée dans Konoha.
   - Images : `06`, `07`, `08`.
4. **Les clics traversent MY NINJA** : un clic sur l'aperçu du ninja, à gauche, sélectionne la carte YOU de l'écran du tournoi caché derrière. C'est arrivé 15 fois dans la rafale (image `09`).
5. **CONTROLS en plein duel garde la souris bloquée au centre** : la carte s'ouvre avec son bouton CLOSE, mais le curseur ne peut pas l'atteindre ; seul Tab la ferme. `Camera:mouse` ne libère la souris que pour le panneau de développement.
6. **La rafale de tenues tient.**
   - Sur la carte de création : 32 clics, 1 seule création au serveur malgré 3 clics sur THAT'S ME en 130 ms.
   - Dans MY NINJA : 43 clics, 4 équipements ; une seule tenue et un seul jeu de pièces sur le corps, et ce sont celles équipées.
7. **Le duel** contre l'IA facile, en tapant au hasard : perdu 1-2.
   - REMATCH puis BACK TO KONOHA puis REMATCH, à 100 ms d'écart : la revanche gagne, sans état cassé.
   - Images longues : 14 de 0,43 à 0,47 s, à intervalles irréguliers de 25 à 120 s, dans la forêt, à Konoha et en duel, puis 2 de 1,2 s à l'écran de résultat. À refaire dans une Studio seule avant d'accuser le jeu.
8. **CONTROLS (TAB)** est sous BACK TO KONOHA, en haut à droite de l'écran du tournoi : on ne peut pas le cliquer.

Pas testé :
- les coups de rue (voir les mains, plus haut) ;
- deux joueurs ;
- la manette et le tactile ;
- l'achat avec des Ryō : le profil neuf avait 0 Ryō, donc on ne savait pas si un double paiement était possible.

## Le 27/11, deuxième partie : courir partout, frapper, se battre, acheter des tenues

François : « courir un peu partout, envoyer des coups, se battre, acheter des tenues ». Fichiers : `mesures/2026-11-27b_ac418a18/` (`journal.json`, `rapport.md`, `images/`).

Préparation par le serveur, notée dans le journal :
- la porte passée comme la carte de création la passe (`Forest.atGate`, puis `Forest.create`) ;
- le kit de l'Avenger (`chooseStarter`) et 3 000 Ryō (`earnRyo`) ;
- puis `Matches:selection` pour que le HUD les montre ;
- deux fois, le joueur a été posé près de sa cible : à 14 studs du voyou de la Plaza et à 8 studs du marché.

9 minutes : 185 touches, 87 clics, 214 coups de rue. Aucune ligne rouge, aucun paiement en double, aucune tenue en double.

1. **Courir partout** : trois courses `roam` (graines 21, 22 et 23), avec Shift, des sauts et des demi-tours.
   - Le joueur est monté jusqu'aux têtes des Hokage, puis il est ressorti par la porte dans la forêt : la mini-carte y est vide (image `15`).
   - Au pied des têtes, la caméra est restée derrière les poutres d'un échafaudage, le corps caché (image `16`).
   - Aucun corps bloqué ni chute ; une image de 1,6 s en courant dans la forêt.
2. **Frapper** : 214 coups (195 pendant que le corps pouvait frapper).
   - Sur 116 coups arrivés au serveur : 102 dans le vide, 11 dans le décor, 2 caisses cassées, 1 voyou.
   - Coups seuls, sans cible, ils n'ont rien cassé d'autre que deux caisses.
3. **Se battre** : un lourd sur le voyou de la Plaza lance le combat (ROGUE NINJA, image `12`). En tapant au hasard (clavier et souris) : perdu 0-2.
   - Le résultat dit « WHAT YOU EARNED : HE TOOK 20 RYŌ OFF » (image `13`) : un titre « ce que tu as gagné » au-dessus d'une perte.
   - La défaite rapporte quand même 30 de maîtrise.
   - Pendant le combat, le corps a été lancé à 220 studs/s, 10 fois, à 11 studs de haut : un coup du voyou, à juger par le DEV.
4. **Acheter des tenues** : au marché (E devant le marchand), 5 hauts à 600 Ryō, en rafale.
   - BUY double-cliqué, deux prix cliqués à la suite, BUY puis un autre prix aussitôt.
   - Le serveur a fait 5 achats, chacun une fois, de 3 005 à 5 Ryō ; le dernier haut acheté est porté.
   - Une seule tenue et un seul jeu de pièces sur le corps, ceux équipés (image `14`).
   - Le second clic de BUY tombe sur la case derrière (« NEED 595 MORE »), qui répond sans rien acheter.
   - Avec la nouvelle tenue, une dernière course avec des coups ne fait rien tomber.
