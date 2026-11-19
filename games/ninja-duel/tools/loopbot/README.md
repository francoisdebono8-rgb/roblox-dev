# Robot de la boucle (OUTILLEUR, 19/11)

Il joue la boucle d'un nouveau joueur avec les vrais modules du serveur, sans écran. C'est la demande `claude/plan-vrai-jeu-taches-2026-11-19` § 4, OUTILLEUR 1.

| Étape | Ce que le robot fait | Il échoue si |
|---|---|---|
| `arrivee` | Charge le profil (magasin en mémoire) | Le joueur a déjà un kit, ou il arrive habillé (l'écran de tenue ne s'ouvrirait pas) |
| `tenue` | Met un haut, un bas et des sandales gratuits (`EquipItem`) | Un choix est refusé, ou il n'est toujours pas habillé |
| `inspiration` | Choisit une des trois inspirations (`ChooseStarter`) | Le kit n'est pas appris ou pas choisi |
| `duel` | Lance la première minute (`First`). Il bouge vers le partenaire, puis frappe (`Move`, puis `Attack`, par `Matches:request`) jusqu'au **premier coup qui touche vraiment**. Il passe ensuite les consignes et gagne le vrai duel | Aucun coup ne touche en 45 s, la consigne « bouger » n'est passée qu'au bout de son délai, ou le duel ne finit pas |
| `gains` | Lit ce que reçoit l'écran de résultat (`progress`) et sa ligne (`MastersView.result`) | Il n'y a ni maîtrise, ni Ryō, ni la première victoire du jour |
| `marche` | Enchaîne des duels gagnés jusqu'à pouvoir payer l'objet le moins cher du marché, puis l'achète | L'achat est refusé, l'objet n'est pas porté, ou il reste hors de portée après 60 duels |
| `arbre` | Attend de pouvoir payer le nœud le moins cher du premier palier, puis l'apprend (`LearnNode`) | Le nœud n'est pas dans la build |

Il le fait pour les trois inspirations du départ (Naruto, Sasuke, Lee).

```sh
# depuis games/ninja-duel
lune run tests/Loop.spec.luau              # le test (échoue si une étape casse)
lune run tools/loopbot/run.luau            # le rapport des trois inspirations
lune run tools/loopbot/run.luau Lion       # une seule
lune run tools/loopbot/run.luau --json     # en JSON
```

## Le temps jusqu'au premier coup

L'estimation additionne trois choses :
- **Les écrans.** Ce sont des hypothèses, réunies dans `LoopBot.UI` : arrivée 3 s, 2,5 s par choix de tenue, 5 s pour choisir l'inspiration, 2 s pour demander le duel.
- **Les marches dans Konoha.** Elles sont comptées en ligne droite, à la vitesse de marche lue dans `Client/HubClient` (16 studs/s). Le trajet va de la porte aux trois inspirations, puis jusque chez celle choisie (`Shared/HubMap`).
- **La première minute jusqu'au coup.** Elle est **simulée**, avec 1 s de lecture par consigne.

L'objectif du plan est de 60 s. Le rapport détaille chaque part :

```
Premier coup estimé : 44 s (objectif 60 s : tenu)
       3.0 s  arrivée, écran de tenue lu
       7.5 s  tenue (3 choix)
       ...
```

*(Ces chiffres sont un exemple de forme, pas une mesure.)*

## La boucle

Le rapport dit aussi après combien de duels gagnés l'objet le moins cher du marché, puis le nœud le moins cher de l'arbre, deviennent abordables. Il traduit ce nombre en minutes de jeu : un duel compte pour 90 s, plus 20 s entre deux duels (hypothèses de `LoopBot`).

## Ce que le robot ne prouve pas

- Les écrans, la caméra, les chemins réels dans Konoha et le rythme d'un vrai joueur. C'est le rôle du parcours joué dans Studio par le MCP, sur PC et sur téléphone : tâche 3, à venir dans ce dossier.
- L'argent réel : le robot ne touche ni à MarketplaceService ni aux Robux.
