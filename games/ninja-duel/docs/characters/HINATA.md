# Hinata Hyuga — fiche de référence

ID runtime **`Lavender`** · version documentaire du **18/10/2026** · données lues au HEAD **`1cabd7f`** (runtime `bc7faa3`). [Index/comparaison](ROSTER_20.md) · [contrat commun](FIGHTER_TEMPLATE.md).

**Portée :** intention utilisateur et méthode dans [DEC-025](../active/DECISIONS.md#dec-025--fiches-personnages-et-identité-perceptible). Cette fiche propose la cible détaillée ; elle n’annonce ni validation lore complète, ni implémentation, ni autorisation de nouvelle passe. Priorités/acceptation : [MASTER_BACKLOG](../active/MASTER_BACKLOG.md). État global : [CURRENT_STATE](../active/CURRENT_STATE.md).

## 1. Version et promesse

Hinata PartieI, âge12 runtime ; les noms de techniques PartieII déjà codés ne prouvent pas leur disponibilité à12.

**Signature irremplaçable :** Absorber la pression par déplacement/lecture puis reprendre par paume précise.

**Faiblesse/contre-jeu :** Portée, pression multi-angles et manque d’allonge ; ne pas être une Neji plus faible en tout.

## 2. Tenue, silhouette et mouvement — cible

**Vêtements/armes visibles :** Veste ample claire à capuche, pantalon sombre, cheveux courts bleu-noir et yeux Byakugan ; garde protectrice, épaules plus fermées que Neji.

**Course, sprint, strafe, dash et esquive :** Petits pas prudents, garde centrée, recul court puis retour ; dodge protecteur à côté du coup, pas rotation offensive de Neji ni dash énergétique universel.

**Air, poursuite, réception et mur :** Air : anti-air court et retour au sol ; mur : sortie protectrice, sans chorégraphie agressive imposée. Une réception ramène à des appuis stables ; la caméra ne doit pas masquer la source d’un coup.

## 3. Chakra — distinguer nature, contrôle et quantité

**Nature/capacité particulière proposée :** Jûken/contrôle du chakra et Byakugan ; pas une nature élémentaire. Ne pas attribuer une affinité au hasard pour compléter une case.

**Réserve, efficacité et faible chakra :** Réserve moyenne, contrôle fin et confiance en construction ; cadence défensive et reposition protègent son budget. À sec : paumes/footwork, sans drain gratuit permanent.

**Interaction concrète à rendre perceptible :** Outils ordinaires secondaires ; chakra surtout dans mains et défense, pas infusion de kunai par défaut.

Le profil d’infusion actuel est **`Basic`**, d’après [ChakraTuning](../../src/Server/ChakraTuning.luau). Ce nom décrit l’interpréteur actuel, pas toutes ses capacités ni une maîtrise acquise par le joueur. Un fallback Basic n’annule pas ses jutsus ; il signale l’absence de spécialisation explicite dans ce mapping.

## 4. Repères du build actuel — pas des stats canon

| Paramètre runtime | Valeur brute |
|---|---:|
| Âge affiché | 12 |
| Santé | 120 |
| Réservoir de chakra | 120 |
| Paramètre ChakraRegen | 8 |
| Speed de base | 18.5 |
| Coefficient SprintScale | 1.02 |
| JumpScale / AirControlScale | 1 / 1 |
| AccelerationScale | 1.04 |
| Distance préférée configurée | 4.5 |

Sources : [définition](../../src/Shared/Fighters.luau), [mouvement](../../src/Server/Motor.luau), [régénération](../../src/Server/Combat.luau). Speed est une base en studs/s, pas une vitesse native mesurée ; le sprint dépend du profil de mouvement et des états, **pas simplement Speed×SprintScale**. Regen est également modulée en combat. Ne pas retuner ces nombres sur la seule lecture de la fiche.

**Habiletés cibles relatives (1–5, proposition de design, aucun multiplicateur runtime ni score officiel) :** Taijutsu 4/5, Ninjutsu 3/5, Genjutsu 1/5, Contrôle 4/5, Outils/armes 2/5, Endurance 3/5. Les axes désignent des spécialisations, pas un total de puissance à maximiser ; Lee1 en ninjutsu ne signifie pas absence de chakra.

## 5. Moveset et défense — cible à confronter au kit

**Chaîne légère représentative :** Déviation douce → paume courte → poussée qui recrée la distance ; toucher moins de points mais protéger sa reprise.

**Routes :** Haut : launcher de paume sous ouverture ; bas : balayage de retrait ; côté : cercle défensif puis contre. Différencier visuellement de CircleStep de Neji.

**Garde, parade, esquive/substitution et reprise :** Lecture défensive, paume de protection et contre court ; doit pouvoir rater son timing et être débordée. La substitution garde coût, charges, fenêtre et destination autorisés du système commun ; aucun échappatoire gratuit implicite.

**Outils :** Outils ordinaires secondaires ; chakra surtout dans mains et défense, pas infusion de kunai par défaut.

**Routes réellement déclarées :** airDown=`AirSpike`, airSide=`AirSwitch`, airUp=`AirDrive`, down=`Sweep`, side=`CircleStep`, up=`Launcher` ; lourd après un hit : `PalmThrust`. [MoveGraphs](../../src/Shared/MoveGraphs.luau). Ces noms ne prouvent pas les animations ni les contacts. Invariant : avant premier hit confirmé, direction+Light ne déclenche aucune route spéciale.

## 6. Techniques présentes et admissibilité de période

Snapshot du kit actuel ; temps = **channel / active / recovery**, en secondes. Coûts/cooldowns/portées sont configurés, pas validés par cette documentation. REVIEW_REQUIRED signifie provenance/période non établie ici ; ne pas désactiver la technique sur ce seul label.

| Technique / fonction actuelle | Coût | C/A/R | CD | Portée | Statut de période |
|---|---:|---|---:|---:|---|
| `TwinLionFists` — Twin Lion Fists : Chakra lions on both fists: her blows hit harder for 7 s | 22 | 0.35/0.05/0.2 | 12 | 20 | REVIEW_REQUIRED (technique et âge exact) |
| `VacuumPalm` — Vacuum Palm : Air-pressure palm • pushes into walls • ends a clean string | 14 | 0.2/0.06/0.26 | 3.2 | 28 | REVIEW_REQUIRED (technique et âge exact) |
| `ProtectiveTrigrams` — Protective Trigrams : A sphere of palms: blades in reach are cut down, a close attacker thrown away and drained | 20 | 0.08/0.3/0.3 | 7 | 7 | REVIEW_REQUIRED (technique et âge exact) |

**Capacités possibles / limites :** les variantes de mouvement, routes et chakra décrites ici sont des **GAMEPLAY_LIBERTY proposées** lorsqu’aucune source de période ne les atteste ; une possibilité n’est pas un bouton supplémentaire à implémenter. Préférer faire mieux fonctionner une interaction existante avant d’ajouter un jutsu.

## 7. Éveil, boucles et habileté du joueur

**Éveil actuellement nommé :** `BYAKUGAN • RESOLVE`. **Cible/contrat :** Byakugan/Resolve : transformer une défense réussie en fenêtre de reprise. Règle exacte cible à confirmer ; aucune nouvelle statistique appliquée ici.

**Boucle agressive :** approche propre au personnage → ouverture/hit confirmé → route utile → choix outil/jutsu ou sortie ; priorité : Absorber la pression par déplacement/lecture puis reprendre par paume précise.

**Boucle défensive/faible chakra :** Lecture défensive, paume de protection et contre court ; doit pouvoir rater son timing et être débordée. Réserve moyenne, contrôle fin et confiance en construction ; cadence défensive et reposition protègent son budget. À sec : paumes/footwork, sans drain gratuit permanent.

**Plafond de maîtrise du joueur :** Débutant : garde/retrait. Intermédiaire : défense→contre. Expert : économiser un mouvement et retourner la pression sans surengagement.

**Hors kit / incohérences de période à résoudre :** TwinLionFists, ProtectiveTrigrams et VacuumPalm du runtime : REVIEW_REQUIRED pour12 ; options de période future, pas canon jeune validé. Ne pas les supprimer pendant cette préparation.

## 8. Acceptation Studio et sources

**Scénario distinctif :** Comparaison directe Neji/Hinata sans jutsu ; défense réussie→contre court ; les noms de techniques tardives ne valident pas son âge.

Puis jouer en continu :20s sans jutsu pour reconnaître silhouette/déplacements/contacts ; séquence garde/whiff/hit ; faible chakra puis éveil ; KO/reset. Ne pas replacer les acteurs entre tous les coups et ne pas annoncer un PASS sur un simple spawn. Comparer au fighter le plus proche et garder une faiblesse perceptible. Preuves datées par build dans CURRENT_STATE/rapports, pas badge inventé dans cette fiche.

Provenance du stade et de chaque technique jeune encore à compléter par chapitre/épisode/source primaire ; le runtime et les choix de design ne valent pas preuve canon.
