# Killer Bee — fiche de référence

ID runtime **`Ink`** · version documentaire du **18/10/2026** · données lues au HEAD **`1cabd7f`** (runtime `bc7faa3`). [Index/comparaison](ROSTER_20.md) · [contrat commun](FIGHTER_TEMPLATE.md).

**Portée :** intention utilisateur et méthode dans [DEC-025](../active/DECISIONS.md#dec-025--fiches-personnages-et-identité-perceptible). Cette fiche propose la cible détaillée ; elle n’annonce ni validation lore complète, ni implémentation, ni autorisation de nouvelle passe. Priorités/acceptation : [MASTER_BACKLOG](../active/MASTER_BACKLOG.md). État global : [CURRENT_STATE](../active/CURRENT_STATE.md).

## 1. Version et promesse

Bee jinchûriki jeune ; âge14 runtime. Lariat, encre/tentacule et contrôle du manteau à14 demandent validation de période.

**Signature irremplaçable :** Entrer au corps, forcer garde ou recul, convertir en lariat/prise puis maintenir une pression lisible.

**Faiblesse/contre-jeu :** Engagement du lariat, distance longue et adversaire qui dévie ; garde ne doit pas être ignorée par tous les coups.

## 2. Tenue, silhouette et mouvement — cible

**Vêtements/armes visibles :** Tenue d’entraînement de Kumo proposée, cheveux blonds courts, signes distinctifs et épaules de lutteur ; pas équipement adulte complet à sept sabres.

**Course, sprint, strafe, dash et esquive :** Course puissante et centre bas, prise d’élan lisible pour Lariat ; dash physique engagé, aura uniquement sous manteau approprié.

**Air, poursuite, réception et mur :** Air : interception/retombée lourde ; mur : pression d’épaule et sortie au corps, pas vol. Une réception ramène à des appuis stables ; la caméra ne doit pas masquer la source d’un coup.

## 3. Chakra — distinguer nature, contrôle et quantité

**Nature/capacité particulière proposée :** Raiton candidat à confirmer pour ce stade ; chakra de Gyûki = source spéciale, encre/tentacule = capacités associées, pas élément Encre.

**Réserve, efficacité et faible chakra :** Réserve cible élevée mais accès à la source spéciale borné ; fort effort physique, manteau à fenêtre. À sec : lutte/pression physique, pas de bijû gratuit.

**Interaction concrète à rendre perceptible :** Outils simples secondaires ; encre gêne lecture/placement et tentacule immobilise brièvement sous règle, pas sept sabres ajoutés.

Le profil d’infusion actuel est **`Basic`**, d’après [ChakraTuning](../../src/Server/ChakraTuning.luau). Ce nom décrit l’interpréteur actuel, pas toutes ses capacités ni une maîtrise acquise par le joueur. Un fallback Basic n’annule pas ses jutsus ; il signale l’absence de spécialisation explicite dans ce mapping.

## 4. Repères du build actuel — pas des stats canon

| Paramètre runtime | Valeur brute |
|---|---:|
| Âge affiché | 14 |
| Santé | 150 |
| Réservoir de chakra | 115 |
| Paramètre ChakraRegen | 7.6 |
| Speed de base | 19 |
| Coefficient SprintScale | 1.1 |
| JumpScale / AirControlScale | 1.04 / 1 |
| AccelerationScale | 1.02 |
| Distance préférée configurée | 5 |

Sources : [définition](../../src/Shared/Wave3.luau), [mouvement](../../src/Server/Motor.luau), [régénération](../../src/Server/Combat.luau). Speed est une base en studs/s, pas une vitesse native mesurée ; le sprint dépend du profil de mouvement et des états, **pas simplement Speed×SprintScale**. Regen est également modulée en combat. Ne pas retuner ces nombres sur la seule lecture de la fiche.

**Habiletés cibles relatives (1–5, proposition de design, aucun multiplicateur runtime ni score officiel) :** Taijutsu 5/5, Ninjutsu 3/5, Genjutsu 1/5, Contrôle 3/5, Outils/armes 3/5, Endurance 5/5. Les axes désignent des spécialisations, pas un total de puissance à maximiser ; Lee1 en ninjutsu ne signifie pas absence de chakra.

## 5. Moveset et défense — cible à confronter au kit

**Chaîne légère représentative :** Contact d’épaule → crochet au corps → bras/lariat de séparation ; rythme de lutteur distinct d’un kick fighter.

**Routes :** Haut : launcher de bras ; bas : fauchage ; côté : pas de lutte/pivot ; lourd : LariatArm. La prise doit changer positions et risque, pas nom d’attaque seulement.

**Garde, parade, esquive/substitution et reprise :** Garde forte et trade sous manteau ; saisie/punition de Lariat raté restent possibles. La substitution garde coût, charges, fenêtre et destination autorisés du système commun ; aucun échappatoire gratuit implicite.

**Outils :** Outils simples secondaires ; encre gêne lecture/placement et tentacule immobilise brièvement sous règle, pas sept sabres ajoutés.

**Routes réellement déclarées :** airDown=`AirSpike`, airSide=`AirSwitch`, airUp=`AirDrive`, down=`Sweep`, side=`CircleStep`, up=`Launcher` ; lourd après un hit : `LariatArm`. [MoveGraphs](../../src/Shared/MoveGraphs.luau). Ces noms ne prouvent pas les animations ni les contacts. Invariant : avant premier hit confirmé, direction+Light ne déclenche aucune route spéciale.

## 6. Techniques présentes et admissibilité de période

Snapshot du kit actuel ; temps = **channel / active / recovery**, en secondes. Coûts/cooldowns/portées sont configurés, pas validés par cette documentation. REVIEW_REQUIRED signifie provenance/période non établie ici ; ne pas désactiver la technique sur ce seul label.

| Technique / fonction actuelle | Coût | C/A/R | CD | Portée | Statut de période |
|---|---:|---|---:|---:|---|
| `Lariat` — Lariat : Charging arm across the gap • flattens the body | 18 | 0.16/0.05/0.1 | 6 | 16 | REVIEW_REQUIRED (technique et âge exact) |
| `InkMist` — Octopus Ink : A cloud of ink: legs stuck, slowed hard while in it | 14 | 0.2/0.1/0.25 | 9 | 22 | REVIEW_REQUIRED (technique et âge exact) |
| `OctoHold` — Octopus Hold : A tentacle grabs the body and holds it • then slams it | 22 | 0.3/0.08/0.3 | 9 | 18 | REVIEW_REQUIRED (technique et âge exact) |

**Capacités possibles / limites :** les variantes de mouvement, routes et chakra décrites ici sont des **GAMEPLAY_LIBERTY proposées** lorsqu’aucune source de période ne les atteste ; une possibilité n’est pas un bouton supplémentaire à implémenter. Préférer faire mieux fonctionner une interaction existante avant d’ajouter un jutsu.

## 7. Éveil, boucles et habileté du joueur

**Éveil actuellement nommé :** `EIGHT-TAILS CLOAK`. **Cible/contrat :** EightTailsCloak Heavy/Armor existant : fenêtre de trade lisible, pas transformation géante.

**Boucle agressive :** approche propre au personnage → ouverture/hit confirmé → route utile → choix outil/jutsu ou sortie ; priorité : Entrer au corps, forcer garde ou recul, convertir en lariat/prise puis maintenir une pression lisible.

**Boucle défensive/faible chakra :** Garde forte et trade sous manteau ; saisie/punition de Lariat raté restent possibles. Réserve cible élevée mais accès à la source spéciale borné ; fort effort physique, manteau à fenêtre. À sec : lutte/pression physique, pas de bijû gratuit.

**Plafond de maîtrise du joueur :** Débutant : entrer/lariat. Intermédiaire : lire garde/esquive. Expert : choisir trade, prise ou arrêt d’élan.

**Hors kit / incohérences de période à résoudre :** Sept sabres, Gyûki complet, Bijûdama géante et contrôle parfait adulte ; capacités précoces en review.

## 8. Acceptation Studio et sources

**Scénario distinctif :** Comparer Bee/Lee sans jutsu : poids vs cadence ; bait de Lariat et punition ; manteau augmente capacité de trade sans effacer garde/substitution.

Puis jouer en continu :20s sans jutsu pour reconnaître silhouette/déplacements/contacts ; séquence garde/whiff/hit ; faible chakra puis éveil ; KO/reset. Ne pas replacer les acteurs entre tous les coups et ne pas annoncer un PASS sur un simple spawn. Comparer au fighter le plus proche et garder une faiblesse perceptible. Preuves datées par build dans CURRENT_STATE/rapports, pas badge inventé dans cette fiche.

Provenance du stade et de chaque technique jeune encore à compléter par chapitre/épisode/source primaire ; le runtime et les choix de design ne valent pas preuve canon.
