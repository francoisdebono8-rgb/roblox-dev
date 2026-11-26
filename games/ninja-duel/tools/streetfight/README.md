# Les coups de rue et le défi par le coup (OUTILLEUR, passe commune 3, 26/11, DEC-055)

La demande : « le défi par le coup entre deux clients, jamais vu en jeu : A frappe B (défi), B riposte dans les 5 s, et le duel doit démarrer sur place, sans écran de choix, chacun avec son kit. Relève tout corps bloqué. Les coups de rue : le mannequin, une caisse (casse puis revient après 25 s de calme), un voyou, un prodige qui attend (son défi), l'Ōtsutsuki dans la cour de l'Examen. Le coup se tourne vers la cible à moins de 7 studs. »

Trois robots travaillent ensemble, dans un Play de la place du jeu (DEC-052) :

- **`NDStreetBot`** (`street_bot.luau`, client) presse les touches du DEV (`Client/HubFightClient` : `press("Light")`, `"Heavy"`, `"Dodge"`). Il se place d'abord comme un joueur : à quelques studs de la cible, le corps tourné ailleurs, la caméra regardant un peu à côté. Pour chaque coup, il note l'angle du corps vers la cible avant et après la pression : le coup doit se tourner vers la cible (`Shared/HubFight.aim` : 7 studs, 65°). Le second client arme une riposte (`armRiposte(delai)`) : il rend le coup quand un défi le frappe.
- **`NDStreetLog`** (`street_log.luau`, serveur) tient le journal du serveur :
  - ce que chaque coup a touché (`Server/HubFight.land`) ;
  - chaque défi (`strikePlayer` : `challenge`, `accept`, `wait`, `busy`) ;
  - la session de chaque joueur quand elle change : rue ou duel, quel dossier, où, quels kits ;
  - les objets cassés puis remis.
- **`NDDuelBot` et `NDDuelAudit`** (`tools/duelbot`, `tools/duelaudit`) jouent le duel qui démarre, sur chaque client (`NDDuelBot.playHere`), et relèvent les corps bloqués, les coups qui traversent, etc. Le témoin reconnaît maintenant un duel entre deux joueurs (`Duelist1`, `Duelist2` dans `NinjaDuels.Online_<n>`).

## Lancer

Deux clients : `multiplayer_playtest` (`action: "start"`, `numPlayers: 2`) dans une Studio à soi, puis :

```sh
python3 tools/robots/inject.py --server streetlog     # Serveur : _G.NDStreetLog.start()
python3 tools/robots/inject.py street duel audit      # chaque client
python3 tools/streetfight/report.py --read            # Serveur : le journal
python3 tools/streetfight/report.py JOURNAL.json --md RAPPORT.md
```

Dans un Play à plusieurs clients de Studio, les joueurs ont des numéros négatifs (-1, -2). Leur profil est refusé (« Profile id required ») : tous les kits sont ouverts et aucun n'est choisi. Le 26/11, chaque client a reçu, dans ce Play seulement, un profil en mémoire (`u_910001`, `u_910002`), son kit (Lion, Leaf) et une tenue.

Les captures d'écran d'un Play à plusieurs clients ne marchent pas sur le Mac : la fenêtre d'un client donne une icône de 48 px. Les images se prennent dans un Play solo.

## Le 26/11 (place `6c673043`, sources du DEV de la nuit)

Fichiers : `mesures/2026-11-26_6c673043/` (`journal_serveur_1_defi.txt`, `journal_serveur_2.json`, `rapport_coups.md`, `duel_joueurs.json`, `audit_client1_tout.json`, l'image de la caisse).

- **Le défi par le coup ne marche pas tel quel.** Les deux coups entre joueurs touchent « le décor » (`world`). `Server/HubFight` cherche le modèle d'une pièce en remontant tant que le parent est un `Model`. Or `Workspace` est lui-même un `Model` : pour un corps de joueur, posé directement sous `Workspace`, la remontée va jusqu'à `Workspace`, et le joueur n'est jamais reconnu. Les voyous, les prodiges et l'Ōtsutsuki sont dans des dossiers (`Folder`) : pour eux, ça marche. La correction est d'une ligne (s'arrêter sous `Workspace`) : elle est au DEV.
- **Avec cette ligne corrigée à chaud dans le Play :**
  - A frappe B : défi. B rend le coup 1,3 s après : `accept`. Le duel démarre 0,06 s plus tard, sans écran de choix, chacun avec son kit (Lion, Leaf).
  - Il se joue sur la place la plus proche (`Plaza`), à environ 21 studs de là où ils se tenaient, les deux à 42 studs l'un de l'autre.
  - 3 manches : 26,9 s, 32,3 s et 72,1 s. Lion gagne 2 à 1.
- **Pendant ce duel** :
  - 10 corps bloqués (Lion) et 16 (Leaf). Beaucoup sont au bord de l'anneau (36 studs du centre) : le corps s'arrête sans mur visible. D'autres sont à 15 studs du centre avec une vitesse serveur de 49,5, sans rien de solide dans le village à cet endroit : sans doute un effet du duel.
  - 3 et 5 coups qui traversent, et 11 et 14 passages dans le sol, surtout aux chutes (1,5 à 1,8 stud).
  - La caméra dans le tronc d'un arbre de la place, 5 fois, et les combattants cachés par ce tronc 4 fois.
  - Aucune erreur rouge.
- **Les coups de rue** (un client) :
  - **Le mannequin** : 3 légers et 1 lourd le touchent. Le corps, tourné à 120° du mannequin, se tourne vers lui (3° d'écart). À 9 studs, rien ne se tourne et le coup ne touche rien.
  - **La caisse** : un lourd la « casse ». À l'écran, elle reste entière, avec quelques éclats et des morceaux verts à côté (image). Tout est remis 25,2 s après le dernier coup.
  - **Un voyou** : son combat démarre 0,19 s après le coup. **Le prodige qui attend** (Gaara ce jour-là) : son défi démarre aussitôt.
  - **L'Ōtsutsuki** : premier coup, il répond « 0 seals of eight. Go get the rest. ». Avec la finale ouverte pour l'essai, le coup suivant lance la finale sur place, 0,44 s après, dans la cour (origine 0, -2491), avec la musique de la finale.
- **Limite** : le Mac avait 7 fenêtres Studio ouvertes. Le client est tombé à 1 à 5 images par seconde pendant le combat du voyou, le défi de Gaara et la finale. Les incidents de ces trois combats ne comptent pas : seul le duel entre joueurs (50 images/s) et le racket (53) sont mesurés.

Ce sont des mesures de Claude (TECHNICAL / NATIVE_STUDIO), pas l'avis de François.
