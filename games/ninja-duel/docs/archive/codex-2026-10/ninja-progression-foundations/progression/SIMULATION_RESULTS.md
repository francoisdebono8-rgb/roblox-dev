# Simulations de travail

Seed 42 ; pack Training ; 100 packs par profil. Les monnaies initiales sont fournies artificiellement pour la simulation. Aucun rythme de gain ni prix réel n'est validé. `--roster 20` ajoute quinze fiches synthétiques uniquement à la config du simulateur, avec le même seuil de fragments et de nouveaux poids ; ce n'est pas une comparaison à probabilités constantes.

| Mesure | 5 personnages, 100 profils | 20 fiches, 1 000 profils |
|---|---:|---:|
| Ouvertures | 10 000 | 100 000 |
| Premier nouveau personnage, moyenne parmi les succès | 11,79 packs | 27,847 packs |
| Doublons de personnages déjà possédés | 80 % | 26,566 % |
| Collection moyenne à 25 packs | 3,73 / 5 | 1,44 / 20 |
| Collection moyenne à 50 packs | 4,93 / 5 | 3,816 / 20 |
| Collection moyenne à 100 packs | 5 / 5 | 10,185 / 20 |
| Collection complète | 100 / 100 | 0 / 1 000 |
| Packs pour compléter, moyenne parmi les succès | 36,07 | Non observable à cet horizon |
| Fragments moyens accumulés sur personnages possédés | 800 | 265,66 |

Fréquences réelles sur les 10 000 tirages : Flashstep 5,26 %, GentleFist 25,17 %, Lion 25,07 %, Mirage 15,12 %, Sand 29,38 %. La protection/garantie peut modifier les poids bruts : se servir des fréquences effectives, pas seulement de weight/total.

Problèmes à décider avant équilibrage : pas d'usage défini pour les fragments déjà possédés ; ajouter des entrées dilue les probabilités et ralentit nettement le premier déblocage ; beaucoup de collections incomplètes à vingt fiches. Le simulateur expose pour chaque personnage le taux de déblocage, les profils censurés et le temps moyen **parmi les succès**. Ne jamais annoncer une moyenne de complétion pour le deuxième lot : les 1 000 profils sont censurés à 100 packs. Ces échantillons ne prouvent pas une rétention ni une viabilité commerciale.

Fichiers complets : `reports/packs-10000.json`, `reports/packs-100000-roster20.json`. `reports/profiles-1000.json` vérifie 1 000 profils isolés : grant, XP, monnaie, save/release et relecture. Backend mémoire simulant UpdateAsync, 2 000 écritures ; temps machine indicatif, aucune revendication de débit DataStore réel.
