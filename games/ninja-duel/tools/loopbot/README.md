# Robot de la boucle (OUTILLEUR, 19/11)

Il joue la boucle d'un nouveau joueur avec les vrais modules du serveur, sans écran. C'est la demande `claude/plan-vrai-jeu-taches-2026-11-19` § 4, OUTILLEUR 1.

| Étape | Ce que le robot fait | Il échoue si |
|---|---|---|
| `arrivee` | Charge le profil (magasin en mémoire) | Le joueur a déjà un kit, ou il arrive habillé |
| `inspiration` | Choisit une des trois inspirations (`ChooseStarter`) | Le kit n'est pas appris ou pas choisi |
| `tenue` | Met un haut, un bas et des sandales gratuits (`EquipItem`). Dans le jeu, la fiche « YOUR NINJA » s'ouvre une fois l'inspiration choisie | Un choix est refusé, ou il n'est toujours pas habillé |
| `duel` | Lance la première minute (`First`). Il bouge vers le partenaire, puis frappe (`Move`, puis `Attack`, par `Matches:request`) jusqu'au **premier coup qui touche vraiment**. Il passe ensuite les consignes et gagne le vrai duel | Aucun coup ne touche en 45 s, la consigne « bouger » n'est passée qu'au bout de son délai, ou le duel ne finit pas |
| `gains` | Lit ce que reçoit l'écran de résultat (`progress`) et sa ligne (`MastersView.result`) | Il n'y a ni maîtrise, ni Ryō, ni la première victoire du jour |
| `marche` | Enchaîne des duels gagnés jusqu'à pouvoir payer l'objet le moins cher du marché, puis l'achète | L'achat est refusé, l'objet n'est pas porté, ou il reste hors de portée après 60 duels |
| `arbre` | Attend de pouvoir payer le nœud le moins cher du premier palier, puis l'apprend (`LearnNode`) | Le nœud n'est pas dans la build |
| `garderobe` | Parcourt tous les emplacements du catalogue, dont les nouveaux (masque, cape, dos) dès qu'ils existent. Dans chaque emplacement qui a un objet gratuit, il le porte (`EquipItem`) | Un emplacement de `Shop.Slots` n'est pas montré par la garde-robe (`Shop.SlotOrder`), ou un objet gratuit n'est pas porté |

Il le fait pour les trois inspirations du départ (Naruto, Sasuke, Lee).

**La collection** (vague 2) : un test à part de `Loop.spec` vérifie que chaque objet du catalogue a :
- son icône, dans `tools/icons/renders` ;
- son modèle dans le jeu : les pièces modélisées de l'ANIMATEUR (`Shared/OutfitMeshes`) pour une pièce de tenue, ou l'objet que le jeu construit lui-même pour les armes et le bandeau.

Le même contrôle existe sans lune : `python3 tools/icons/catalogue.py --gate`.

**Pas encore dans le jeu** : les quêtes du jour (DEV 5). Le robot le dit dans son rapport, sans échouer. Il les jouera quand le module existera.

```sh
# depuis games/ninja-duel
lune run tests/Loop.spec.luau              # le test (échoue si une étape casse)
lune run tools/loopbot/run.luau            # le rapport des trois inspirations
lune run tools/loopbot/run.luau Lion       # une seule
lune run tools/loopbot/run.luau --json     # en JSON
```

## Le temps jusqu'au premier coup

L'estimation additionne trois choses :
- **Les écrans.** Ce sont des hypothèses, réunies dans `LoopBot.UI` : arrivée 3 s, 1 s pour parler à l'inspiration, 5 s pour la choisir, 2,5 s par choix de tenue et 1 s pour DONE, 2 s pour YOUR FIRST DUEL.
- **La marche dans Konoha.** Elle est comptée en ligne droite, à la vitesse de marche lue dans `Client/HubClient` (16 studs/s), de la porte aux trois inspirations (`Shared/HubMap`). Le premier duel se demande à la porte, sur la fiche de l'inspiration (vu dans Studio le 19/11). La marche jusque chez elle est encore calculée, pour information, mais elle n'entre plus dans l'estimation.
- **La première minute jusqu'au coup.** Elle est **simulée**, avec 1 s de lecture par consigne.

L'objectif du plan est de 60 s. Le rapport détaille chaque part :

```
Premier coup estimé : 26 s (objectif 60 s : tenu)
       3.0 s  arrivée, objectif lu
       2.8 s  marche de la porte aux inspirations (44 studs)
       1.0 s  E à l'inspiration, sa fiche
       ...
```

*(Ces chiffres sont un exemple de forme, pas une mesure.)*

## La boucle

Le rapport dit aussi après combien de duels gagnés l'objet le moins cher du marché, puis le nœud le moins cher de l'arbre, deviennent abordables. Il traduit ce nombre en minutes de jeu : un duel compte pour 90 s, plus 20 s entre deux duels (hypothèses de `LoopBot`).

La vague 2 veut le premier achat dans la première séance. Le rapport dit s'il tombe dans une séance de 20 minutes (`Bot.FirstSession`, une hypothèse). Ce n'est pas un échec du test : le prix du marché est une décision de François.

## Le même parcours joué dans Studio (tâche 3)

Il se joue sur une copie de la place ND-JEU dans LAB, jamais dans les places des autres discussions. On lance une partie par le MCP et on pose l'enregistreur `studio_recorder.luau` dans le client. On joue ensuite avec de vraies entrées : marche, E ou tape, clics, glissé et □ sur téléphone. `shared.NDLoop.dump()` rend la chronologie, `shared.NDLoop.buttons()` la taille des boutons à l'écran.

Le temps qu'un agent met entre deux entrées est le sien, pas celui d'un joueur. On lit donc la part du jeu : l'écart entre une entrée et ce qu'elle déclenche.

**Le 19/11, ND-JEU de `bbcfffb7` (runtime `95213cc1e90d`), Lee choisi.**

Le parcours réel :
1. On arrive à la porte. Les trois inspirations sont à 30 à 44 studs, et la bannière dit « CHOOSE YOUR INSPIRATION ».
2. E (ou une tape) ouvre la fiche de Lee.
3. HE'S MY INSPIRATION.
4. La fiche « YOUR NINJA » s'ouvre : haut, bas, pieds, puis DONE.
5. Sur la fiche de Lee, YOUR FIRST DUEL.

Ce que le jeu met de lui-même :

| Étape | PC | Téléphone (iPhone 13 simulé, paysage) |
|---|---|---|
| Marche de la porte à Lee | 35 studs à 16 studs/s, environ 2,3 s | Pareil |
| Choix confirmé par le serveur | 0,13 s | 0,12 s |
| Tenue | 3 clics, puis DONE | 3 tapes, puis DONE |
| Du bouton YOUR FIRST DUEL au duel | 0,21 s | 0,20 s |
| Consigne « bouger » passée | 0,8 s de W | 1,2 s de glissé à gauche |
| Premier coup | Les 3 coups sont faits 1,5 s après le premier clic | Le partenaire perd des PV 0,15 s après la première tape sur □ |

Avec les mêmes hypothèses d'écran que le robot, **le premier coup arrive vers 25 s** de jeu, sur PC comme sur téléphone, contre 60 s visés. Il n'y a plus de marche jusque chez l'inspiration.

Ce qu'on a vu en jouant :
- L'écran de résultat montre la maîtrise et les Ryō (« +18 MASTERY • ROCK LEE 18 / 300 • +20 RYŌ » après une défaite 0-2). Il ne montre ni le prochain nœud, ni l'inspiration suivante (tâche DEV 6). Il dit aussi « MINATO NAMIKAZE ADVANCES », et l'intro du duel « PRODIGY TOURNAMENT », alors que c'est le premier duel.
- Le bandeau est posé sur les yeux de l'avatar (la liste du DEV).
- Je n'ai pas fait l'esquive : la consigne a tenu ses 25 s, puis elle est passée d'elle-même.
- **Sur téléphone :**
  - Lee est caché derrière le corps du joueur, et aucune bulle TALK n'apparaît dans la capture, mais une tape à sa place ouvre sa fiche (à vérifier sur un vrai téléphone).
  - La fiche « YOUR NINJA » couvre la moitié gauche de la fiche de Lee, dont le début de YOUR FIRST DUEL.
  - SKIP STEP couvre le titre de la consigne.
  - Boutons sous 44 px :
    - flèches de tenue : 31×31 ;
    - PICK A TOP / DONE : 32 de haut ;
    - SKILL TREE : 37 de haut ;
    - LATER : 30 de haut ;
    - DUELS et SHOP : 42 de haut.
  - Les boutons de combat font 70 px.

## Ce que le robot ne prouve pas

- Les écrans, la caméra, les chemins réels dans Konoha et le rythme d'un vrai joueur. C'est le rôle du parcours joué dans Studio (ci-dessus) et du test avec de vrais joueurs (tâche du CM).
- L'argent réel : le robot ne touche ni à MarketplaceService ni aux Robux.
