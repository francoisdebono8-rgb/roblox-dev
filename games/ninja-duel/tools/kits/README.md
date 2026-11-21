# Le comparateur de kits (OUTILLEUR, 20/11 ; étape 2 le 21/11)

Une empreinte chiffrée par kit, puis la comparaison des kits entre eux et d'une version à l'autre. C'est la preuve que les différences se voient (DEC-043, étape 1, OUTILLEUR 2).

| Fichier | Rôle |
|---|---|
| `KitPrint.luau` | Calcule l'empreinte depuis les vrais modules du jeu, avec les règles du combat (`Server/Brawler`). Un coup = son démarrage, son actif et sa récupération mis à l'échelle par l'`AttackProfile` du perso, son pas en avant par `CombatTravel`, ses dégâts par `CombatDamage` |
| `studio_kitprint.luau`, `studio_code.py` | La même chose dans Studio (Edit) : `studio_code.py` sort le code à coller |
| `kitprint_lune.luau` | La même chose sans écran, avec lune : `lune run tools/kits/kitprint_lune.luau > empreinte.json` |
| `empreinte.py` | Le rapport, la comparaison avant / après, la page |
| `empreintes/` | Les empreintes enregistrées (la première : 20/11, sources `053395e4`) |
| `test_empreinte.py` ; `tests/KitPrint.spec.luau` | Les tests |
| `NodeCheck.luau` ; `tests/Nodes.spec.luau` | (21/11) Chaque nœud des arbres, avec et sans lui : ce qu'il change. Un nœud `Major` qui ne change rien fait échouer le test |
| `noeuds_lus.py` ; `test_noeuds_lus.py` | (21/11) Le code du jeu qui lit ce que les nœuds changent : chaque effet d'un nœud `Major` des arbres des kits, et les champs que l'arbre du ninja écrit (`def.Ninja`) |

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
- **Gaara se détache** : portée 54, vitesse 55, dégâts/s 38, mais tenue 86. (Corrigé le 21/11 : la course n'est pas la vitesse du kit × `SprintScale`, mais `Config.Movement.SprintSpeed` × `SprintScale`, comme le jeu la règle. Gaara court à 38,25, plus vite qu'il ne marche.)
- **Le départ d'un joueur et l'arbre complet se ressemblent.** Un arbre complet ajoute :
  - 0 à 8 PV ;
  - 2 à 25 % de dégâts/s pour les jutsu ;
  - quelques propriétés (Minato : 5).

  Les cinq notes bougent de 0 à 8 points, et l'écart moyen entre les kits passe de 19 à 20. C'est mesuré : on ne voit pas la différence entre 2 nœuds et l'arbre complet. L'étape 2 (deux arbres) devra faire monter ces chiffres.
- La portée du « lanceur » de Naruto (3,4) ne veut rien dire : c'est le coup d'un clone, sans pas en avant.

## Étape 2 (21/11, mesuré dans Studio)

L'empreinte passe en version 3 :
- la course suit le jeu : `Config.Movement.SprintSpeed` × `SprintScale` (DEC-044). Naruto et Minato courent à 50,4, Lee à 54, Gaara à 38,25 ;
- une technique que le joueur n'a pas encore gagnée (`Locked`) est listée à part et n'est plus comptée ;
- les cinq natures de l'arbre du ninja, chiffrées depuis le contrat `NinjaTree.Infusion` (que `Server/NinjaArts` applique), pour chaque kit ;
- le nœud de transformation de chaque kit (`Transform = true`), ou aucun.

| Empreinte | Place |
|---|---|
| `empreintes/2026-11-21_632931f2.json` (v2) | ND-JEU `632931f2` : avant le départ réduit |
| `empreintes/2026-11-21_b1c21d57.json` (v3) | ND-JEU `b1c21d57` : après DEV 2/4, 3/4 et 4/4 |

```sh
python3 tools/kits/empreinte.py tools/kits/empreintes/2026-11-21_632931f2.json tools/kits/empreintes/2026-11-21_b1c21d57.json --etape2
python3 tools/kits/empreinte.py EMPREINTE.json --natures          # les cinq natures, kit par kit
python3 tools/kits/studio_code.py nodes                           # le contrôle des nœuds, à coller dans Studio (Edit)
python3 tools/kits/noeuds_lus.py                                  # qui lit ce que les nœuds changent
```

Ce qui est mesuré :
- **Le départ réduit se voit.** Au départ, Naruto, Sasuke et Lee ont 2 techniques (avant : 4, 4 et 3). L'arbre complet leur rend les autres :
  - Naruto : Rasengan, Multi-clonage. Au départ, il garde le Clone et le Rendan : 0 dégâts/s de jutsu compté (4,58 avec l'arbre), car le Rendan est une suite de coups, que l'empreinte ne compte pas (voir Limites) ;
  - Sasuke : Chidori, Fil piégé ; 3,53 → 6,62 dégâts/s de jutsu ;
  - Lee : Lotus primaire, Retirer les poids ; 6,06 → 7,58.

  Notes départ → arbre : Naruto dégâts/s 48 → 63 et portée 48 → 55 ; Sasuke dégâts/s 82 → 92 ; Lee 71 → 76. Les cinq autres kits ne bougent pas.
- **Transformation** : seul Sasuke a son nœud (Wall Chidori). Naruto et Lee n'en ont pas encore : ils viendront avec les clips de l'ANIMATEUR.
- **Les natures sont les mêmes pour tous les kits**, plafonnées à un effet toutes les 4 s : Feu +1,1 dégâts/s (+4 à 6 %) ; Foudre, l'adversaire gelé 9,4 % du temps ; Terre, +15 sur la garde toutes les 4 s ; Eau, l'adversaire 8,4 % plus lent en moyenne ; Vent, le lancer 30 % plus loin et le dernier coup qui envoie le corps 30 % plus loin. Seul le Vent change d'un kit à l'autre : Lee et Gaara, qui ne lancent aucune lame, n'en ont que la poussée.
- **Chaque nœud `Major` des huit arbres change le kit** (0 échec sur 64, ND-JEU `b1c21d57`). 53 changent une seule règle (un champ qui passe à vrai). Les 6 nœuds `Learn*` d'une technique la débloquent ; ceux de l'éveil, et Poids, la Gourde et le Tanto, ouvrent un objet. Les 13 nœuds de l'arbre du ninja changent tous `def.Ninja`.
- **Le jeu lit tout ce que les nœuds changent** (`noeuds_lus.py`) : 64 nœuds `Major` des kits, 109 champs et clés ; les dix champs de `def.Ninja` (`Server/NinjaArts`, `Server/Motor`). Il reste l'attribut `NinjaNature`, que le client ne lit pas encore (ANIMATEUR, `Infusion.<Nature>`). Un nœud qui changerait un champ que personne ne lit fait échouer `test_noeuds_lus.py`.

## Limites

- Ce sont les chiffres de la donnée, avec les règles du combat. Ils ne disent pas le ressenti, ni qui gagne : l'IA, l'adresse et les contres n'y sont pas.
- Le chakra chargé, le kunai sorti et l'éveil ne sont pas comptés dans les coups.
- Une technique de la famille `Sequence` (le Rendan de Naruto, le Lotus de Lee) fait ses dégâts par les coups qu'elle enchaîne : l'empreinte la compte à 0.
