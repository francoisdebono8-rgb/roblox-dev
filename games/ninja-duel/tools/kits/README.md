# Le comparateur de kits (OUTILLEUR, 20/11)

Une empreinte chiffrée par kit, puis la comparaison des kits entre eux et d'une version à l'autre. C'est la preuve que les différences se voient (DEC-043, étape 1, OUTILLEUR 2).

| Fichier | Rôle |
|---|---|
| `KitPrint.luau` | Calcule l'empreinte depuis les vrais modules du jeu, avec les règles du combat (`Server/Brawler`). Un coup = son démarrage, son actif et sa récupération mis à l'échelle par l'`AttackProfile` du perso, son pas en avant par `CombatTravel`, ses dégâts par `CombatDamage` |
| `studio_kitprint.luau`, `studio_code.py` | La même chose dans Studio (Edit) : `studio_code.py` sort le code à coller |
| `kitprint_lune.luau` | La même chose sans écran, avec lune : `lune run tools/kits/kitprint_lune.luau > empreinte.json` |
| `empreinte.py` | Le rapport, la comparaison avant / après, la page |
| `empreintes/` | Les empreintes enregistrées (la première : 20/11, sources `053395e4`) |
| `test_empreinte.py` ; `tests/KitPrint.spec.luau` | Les tests |

## Trois versions de chaque kit

- `prodige` : le prodige tel que le jouent l'IA et les maîtres (`Fighters`).
- `depart` : le kit d'un joueur sans aucun nœud. Les objets de kit qu'il n'a pas gagnés lui sont retirés (`SkillBuilds.build`, gated).
- `arbre` : le kit d'un joueur avec tous les nœuds branchés de son arbre. Pour un choix exclusif, c'est le premier qui est pris (`SkillBuilds.apply`).

## Ce qui est mesuré

| Note | Ce qu'elle mélange |
|---|---|
| portée | La portée du coup simple (pas en avant + contact + 1 stud) et le jutsu qui frappe le plus loin |
| vitesse | Le démarrage du premier coup, et le nombre de coups de la corde par seconde |
| mobilité | La course (× l'accélération), le saut, le contrôle en l'air, le dash, les téléportations et les jutsu lancés en courant |
| dégâts/s | La corde (dégâts ÷ temps) et les jutsu (dégâts ÷ recharge) |
| tenue | Les PV, le chakra et sa recharge |

Chaque note est une **part du meilleur** : 100 pour le meilleur des huit, 80 pour 80 % de ce qu'il fait. Les écarts ne sont pas étirés. Le rapport donne aussi :
- les chiffres de chaque kit ;
- ce que chaque kit a **en propre** : ses champs, ses familles de jutsu, ses éléments et son style, quand aucun autre kit ne les a ;
- les deux kits les plus proches et l'écart moyen entre les kits.

```sh
python3 tools/kits/empreinte.py tools/kits/empreintes/2026-11-20_053395e4.json            # le rapport
python3 tools/kits/empreinte.py AVANT.json APRES.json                                     # avant / après
python3 tools/kits/empreinte.py EMPREINTE.json --arbre                                    # départ → arbre complet
python3 tools/kits/empreinte.py EMPREINTE.json --version depart --html kits.html          # une page avec un radar par kit
```

Avant / après, les deux empreintes sont notées sur la même échelle : le meilleur se cherche dans les deux.

## Le 20/11 (sources `053395e4`, mesuré dans Studio)

- **Kakashi et Sasuke sont les deux kits les plus proches** : écart de 6 sur 100. L'écart moyen entre les huit kits est de 20.
- **Minato a le maximum en vitesse et en dégâts/s, et 94 en mobilité.** Sa tenue est la plus basse (81).
- **Gaara se détache** : portée 54, vitesse 55, dégâts/s 38, mais tenue 86. Sa course (14,0) est plus lente que sa marche (16,5), car son `SprintScale` est inférieur à 1.
- **Le départ d'un joueur et l'arbre complet se ressemblent.** Un arbre complet ajoute :
  - 0 à 8 PV ;
  - 2 à 25 % de dégâts/s pour les jutsu ;
  - quelques propriétés (Minato : 5).

  Les cinq notes bougent de 0 à 8 points, et l'écart moyen entre les kits passe de 19 à 20. C'est mesuré : on ne voit pas la différence entre 2 nœuds et l'arbre complet. L'étape 2 (deux arbres) devra faire monter ces chiffres.
- La portée du « lanceur » de Naruto (3,4) ne veut rien dire : c'est le coup d'un clone, sans pas en avant.

## Limites

- Ce sont les chiffres de la donnée, avec les règles du combat. Ils ne disent pas le ressenti, ni qui gagne : l'IA, l'adresse et les contres n'y sont pas.
- Le chakra chargé, le kunai sorti et l'éveil ne sont pas comptés dans les coups.
