# La fluidité sur téléphone (OUTILLEUR, étape 5 « Ouverture », DEC-049)

La tâche du DEV : « la matrice d'appareils de Studio sur le village (225 maisons, ~348 000 triangles) et sur un duel, en images/s et en mémoire, avant et après ».

Le travail se fait dans un Play de la place du jeu (DEC-052, `PLACES/NinjaDuel.rbxlx`), avec :
- la sonde `NDPerfProbe` (`perf_probe.luau`), envoyée dans le client : `python3 tools/robots/inject.py perf` ;
- le simulateur d'appareils de Studio ;
- les outils de `robloxstudio-mcp` : MicroProfiler, composition des triangles, mémoire, captures par appareil.

```sh
python3 tools/perf/studio_code.py --measure "a06 village place" 10   # Client : un tour de caméra, mesuré
python3 tools/perf/studio_code.py --go 0 15.6                        # Client : le corps à un lieu de Konoha (coordonnées du plan)
python3 tools/perf/studio_code.py --groups                           # Client : ce que coûte chaque groupe du village
python3 tools/perf/studio_code.py --cull 160                         # Client : décor, vie et passants cachés au-delà de 160 studs
python3 tools/perf/studio_code.py --report mesures/<fichier>.json    # le tableau
```

**Mettre le simulateur avant de lancer le Play.** Le jeu construit ses commandes tactiles au démarrage du client (`Client/TouchControls`). Un simulateur mis pendant le Play montre un téléphone sans commandes.

## Ce qu'on peut mesurer dans Studio, et ce qu'on ne peut pas

| Mesure | Dans Studio | Ce qui vaut pour un téléphone |
|---|---|---|
| **Images/s** | **Non.** Studio en arrière-plan dessine 15 images/s, même vers le ciel (MicroProfiler : `render_throttled`). Au premier plan, ce sont les images/s du Mac. | Il faut un vrai téléphone : la console de développement de Roblox, onglet des performances. |
| **Le poids de la scène** | Oui : les triangles et les appels de dessin envoyés au rendu (`Stats`), les pièces du client. | Oui : c'est ce que le téléphone devra dessiner, au même réglage de qualité. |
| **La mémoire** | En partie. Studio met l'édition, le serveur et le client dans un seul processus : le total (5 Go) ne veut rien dire. Les lignes `Graphics*` sont au client seul. | Les lignes `Graphics*` et le nombre de pièces. |
| **La simulation** | Oui : 60 pas par seconde, la durée de chaque image. | Une indication : le Mac est plus rapide. |
| **Les écrans** | Oui : les captures par appareil (`capture_device_matrix`). | Oui, sauf les indications du clavier : le simulateur garde le clavier. |

## Le 23/11 (ND-JEU `acfb00d6`, Galaxy A06 simulé)

Fichier : `mesures/2026-11-23_studio_acfb00d6.json` ; images dans `mesures/`.

### Le poids de la scène

| Où | Triangles (moyenne / pic) | Appels de dessin (moyenne / pic) |
|---|---|---|
| Village, la porte, tour de caméra | 41 000 / 59 000 | 98 / 161 |
| **Village, la place, tour de caméra** | **174 000 / 266 000** | **190 / 283** |
| Duel contre Sasuke (easy), caméra du jeu | 77 000 / 103 000 | 94 / 193 |
| Premier combat, Naruto et ses 8 clones | 137 000 / 243 000 | 121 / 148 |

- **Le client a tout le village** : `StreamingEnabled` est éteint. Il tient 10 622 pièces, dont 4 574 MeshParts.

  | Groupe | Pièces | dont MeshParts |
  |---|---|---|
  | Les maisons (`NinjaDuelHub`) | 3 287 | 551 |
  | Le décor (`NinjaDuelHubDress`) | 2 969 | 2 969 |
  | Les arènes (`NinjaDuels`) | 1 626 | 707 |
  | Le décor des arènes (`NinjaDuelArenaDress`) | 1 042 | — |
  | La vie (`KonohaLife`) | 826 | — |
  | Les passants (`KonohaFolk`) | 692 | 250 |

- **Mémoire graphique du client** : textures 50 Mo, MeshParts 40 Mo, terrain 37 Mo, particules 16 Mo, pièces 11 Mo, soit environ 155 Mo.
- **La simulation** (MicroProfiler, 3 s dans le village) :
  - 60 pas par seconde, une image de 16,7 ms en médiane, 18,4 ms au pire 1 % ;
  - aucune image au-delà de 33 ms ;
  - le rendu prend environ 4 ms du Mac par image dessinée.
- **La place est l'endroit le plus lourd.** Caméra fixe à hauteur d'yeux, dans 4 directions : 91 000 à 136 000 triangles, 102 à 227 appels. En cachant un groupe à la fois :
  - les maisons font 30 000 à 60 000 triangles ;
  - le décor fait 15 à 30 appels de dessin, mais le cacher fait voir plus loin : les triangles montent ;
  - les arènes et leur décor ne coûtent rien depuis le village. Elles sont loin, hors de la vue.

### Avant / après : le décor lointain caché

C'est un essai dans le LAB, pas une modification du jeu. Le décor, la vie et les passants à plus de 160 studs du joueur (3 750 pièces) sont rendus invisibles côté client. La mesure se fait sur la place, avec la même caméra.

| Direction | Triangles avant → après | Appels avant → après |
|---|---|---|
| nord | 90 800 → 69 900 (−23 %) | 225 → 201 (−11 %) |
| est | 136 500 → 94 700 (−31 %) | 190 → 151 (−21 %) |
| sud | 120 500 → 90 900 (−25 %) | 102 → 80 (−22 %) |
| ouest | 122 900 → 46 300 (−62 %) | 141 → 125 (−11 %) |

C'est une proposition au DEV : une distance d'affichage pour le décor de Konoha, ou `StreamingEnabled` pour lui. Le gain en images/s reste à mesurer sur un vrai téléphone.

### Les écrans des téléphones

- **La minicarte déborde sur tout le côté gauche.**
  - Le cadre de la minicarte est tourné de 1° (`Client/MiniMap.luau`, `mini.Rotation=1`). Roblox ne découpe pas ce qui est dans un cadre tourné. La carte entière du village (507 × 417 points) sort donc de la minicarte. Elle couvre la moitié gauche de l'écran sur le A06, le A16, l'iPhone 13 et l'iPhone 7, sous le stick.
  - Avec la minicarte à 0°, la carte reste dans son cadre, et la carte du lieu (« KONOHA · THE PLAZA ») réapparaît.
  - Images : `2026-11-23_a06_village_minicarte_avant.jpg` et `…_minicarte_0deg.jpg`.
- **Le duel au début d'une manche (A06)** : le nom de gauche est coupé (« THE » pour THE LOUDMOUTH), et le titre de la manche est sous « 始め! BEGIN ».
- **Les commandes tactiles du combat** (□ △ ○ × GUARD) sont en bas à droite. Le bouton du jutsu (« RASENGAN ») a un texte trop petit pour être lu sur le A06.
- **Dans le village**, la bulle du passant est sous le bloc Ryō / DUELS / SHOP. Le bandeau de quête traverse l'écran à hauteur du personnage.

## Le 26/11, avant la passe commune 2 (place commune `f28b8ba1`, fenêtre du Mac)

La demande (DEC-054) : « la fluidité (images par seconde et à-coups) dans la ville et en duel, avant et après la passe ».

Fichier : `mesures/2026-11-26_avant_passe2_f28b8ba1.json`.

### La mesure qui ne bloque pas

`_G.NDPerfProbe.start({label=…})` puis `.stop()`. Entre les deux, les robots jouent : un duel, une marche. L'appel ne gèle donc pas le client, comme le faisait `measure`. La sonde garde :
- **les images dessinées** (`RenderStepped`) ;
- **les pas de la simulation** (`Heartbeat`) ;
- **les à-coups** : les images de plus de 50 et 100 ms, la pire image ;
- **les saccades des corps**, image par image. Une saccade est une image où un corps qui bouge s'arrête net ou saute : son pas fait moins du quart ou plus du triple de celui des images voisines.

Côté serveur, `_G.NDServerLog.perfStart(label)` et `.perfStop()` donnent les pas du serveur et ses à-coups.

### Résultats

| Mesure | Images dessinées /s | Pas de simulation /s (pire image) | Images > 50 ms (client / serveur) | Triangles (moy. / pic) | Appels de dessin (moy. / pic) | Saccades (lui / l'adversaire) |
|---|---|---|---|---|---|---|
| Ville, la porte, tour de caméra 12 s | 40 | 58,9 (236 ms) | 1 / 2 | 212 000 / 311 000 | 226 / 503 | 0 % / — |
| Ville, la place, tour de caméra 12 s | 15 (Studio en arrière-plan) | 60,0 (20 ms) | 0 / — | 198 000 / 351 000 | 191 / 309 | — |
| Duel, Sasuke (l'avatar) contre Naruto, 40 s | 15 (Studio en arrière-plan) | 59,9 (39 ms) | 0 / 0 | 177 000 / 375 000 | 210 / 481 | 19 % / 12 % |

- **La simulation tient ses 60 pas.** Il y a un seul à-coup, de 236 ms à la porte, sur le client comme sur le serveur au même instant. Le serveur en a vu un de 433 ms pendant une capture d'écran : c'est la capture qui fige Studio. Il ne faut pas capturer pendant une mesure.
- **Les images dessinées ne se comparent qu'à fenêtre égale.** Studio au premier plan : 30 à 40 images/s. En arrière-plan : 15, quoi qu'il dessine. La mesure « après » doit se faire dans le même état de fenêtre, sinon seules la simulation, les triangles et les saccades se comparent.
- **Les saccades d'un duel ne sont pas toutes des défauts.** Un arrêt de coup (hitstop) ou une esquive est voulu. Le chiffre sert à comparer avant et après, sur le même duel : mêmes kits, même graine.

### Refaire « après »

Dans le même état de fenêtre, avec la même place commune reposée après la passe :

```sh
python3 tools/perf/studio_code.py --go 0 190      # la porte ; puis start, lookAround(12), stop
python3 tools/perf/studio_code.py --go 0 15.6     # la place
# duel : NDDuelBot.start({{mode="duel",kit="Lion",rival="Legion",level="normal",seed=1,profile="joueur"}}), start, 40 s, stop
```

## Ce qu'il ne prouve pas

- Les images/s d'un téléphone. Il faut un vrai téléphone, de préférence un Android d'entrée de gamme, pendant le test à 3–5 joueurs.
- La qualité graphique qu'un téléphone choisira : Roblox la règle seul, et elle change ce qui est dessiné.
- La mémoire d'un téléphone. Studio ne sépare pas le client du serveur.
