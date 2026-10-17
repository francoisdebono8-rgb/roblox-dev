> Historique remplacé par DEC-026 : ancien roster et ancienne définition de fiche, pas cible V1 à exécuter.

# Deidara — fiche de référence

ID runtime **`Clay`** · version documentaire du **18/10/2026** · données lues au HEAD **`1cabd7f`** (runtime `bc7faa3`). [Index/comparaison](../../../characters/ROSTER_20.md) · [contrat commun](../../../characters/FIGHTER_TEMPLATE.md).

**Portée :** intention utilisateur et méthode dans [DEC-025](../../../active/DECISIONS.md#dec-025--fiches-personnages-et-identité-perceptible). Cette fiche propose la cible détaillée ; elle n’annonce ni validation lore complète, ni implémentation, ni autorisation de nouvelle passe. Priorités/acceptation : [MASTER_BACKLOG](../../../active/MASTER_BACKLOG.md). État global : [CURRENT_STATE](../../../active/CURRENT_STATE.md).

## 1. Version et promesse

Artiste explosif jeune ; âge15 runtime, origine exacte des techniques à cet âge en review.

**Signature irremplaçable :** Poser→menacer une trajectoire→faire choisir→Katsu ; charge identifiable et consommée une seule fois.

**Faiblesse/contre-jeu :** Rush, destruction/contournement des objets selon règle retenue et réserve ; la mine ne doit pas ignorer Range26.

## 2. Tenue, silhouette et mouvement — cible

**Vêtements/armes visibles :** Tenue jeune d’Iwa proposée, blond avec mèche latérale et attache haute, poches d’argile accessibles ; mains lisibles ; pas cape Akatsuki comme raccourci d’identité.

**Course, sprint, strafe, dash et esquive :** Déplacements de placement/recul, mains qui façonnent ; rush court pour changer l’angle, pas vol d’oiseau permanent.

**Air, poursuite, réception et mur :** Air : jeter/placer puis redescendre ; mur : positionner un objet selon portée/LOS, pas vol libre. Une réception ramène à des appuis stables ; la caméra ne doit pas masquer la source d’un coup.

## 3. Chakra — distinguer nature, contrôle et quantité

**Nature/capacité particulière proposée :** Argile explosive et Bakuton comme référence de design à sourcer pour ce stade ; ne pas présenter tout effet d’explosion comme Katon. Doton/Raiton et contre électrique à confirmer avant règle système.

**Réserve, efficacité et faible chakra :** Réserve moyenne, contrôle précis des objets ; budget dépensé à poser/préparer plutôt qu’à poursuivre physiquement. À sec : outils et petit reposition, pas champ de mines gratuit.

**Interaction concrète à rendre perceptible :** Argile, oiseaux et araignées ; ratés peuvent rester en charges ; distinguer projectile, mine et détonation.

Le profil d’infusion actuel est **`Basic`**, d’après [ChakraTuning](../../../../src/Server/ChakraTuning.luau). Ce nom décrit l’interpréteur actuel, pas toutes ses capacités ni une maîtrise acquise par le joueur. Un fallback Basic n’annule pas ses jutsus ; il signale l’absence de spécialisation explicite dans ce mapping.

## 4. Repères du build actuel — pas des stats canon

| Paramètre runtime | Valeur brute |
|---|---:|
| Âge affiché | 15 |
| Santé | 118 |
| Réservoir de chakra | 125 |
| Paramètre ChakraRegen | 8.2 |
| Speed de base | 18.5 |
| Coefficient SprintScale | 1.1 |
| JumpScale / AirControlScale | 1.05 / 1.05 |
| AccelerationScale | 1 |
| Distance préférée configurée | 16 |

Sources : [définition](../../../../src/Shared/Wave3.luau), [mouvement](../../../../src/Server/Motor.luau), [régénération](../../../../src/Server/Combat.luau). Speed est une base en studs/s, pas une vitesse native mesurée ; le sprint dépend du profil de mouvement et des états, **pas simplement Speed×SprintScale**. Regen est également modulée en combat. Ne pas retuner ces nombres sur la seule lecture de la fiche.

**Habiletés cibles relatives (1–5, proposition de design, aucun multiplicateur runtime ni score officiel) :** Taijutsu 2/5, Ninjutsu 5/5, Genjutsu 1/5, Contrôle 4/5, Outils/armes 3/5, Endurance 3/5. Les axes désignent des spécialisations, pas un total de puissance à maximiser ; Lee1 en ninjutsu ne signifie pas absence de chakra.

## 5. Moveset et défense — cible à confronter au kit

**Chaîne légère représentative :** Paume de dégagement → frappe courte → ClayPop qui recrée de l’espace ; peu d’intérêt à boxer longtemps.

**Routes :** Haut : launcher générique à personnaliser sobrement ; bas : petit dégagement ; côté : feinte de placement ; lourd : ClayPop. Pièges préparent, mais direction+Light ne détonne pas une route avant hit.

**Garde, parade, esquive/substitution et reprise :** Garde et petit burst de dégagement ; pression rapprochée doit le forcer à abandonner un setup. La substitution garde coût, charges, fenêtre et destination autorisés du système commun ; aucun échappatoire gratuit implicite.

**Outils :** Argile, oiseaux et araignées ; ratés peuvent rester en charges ; distinguer projectile, mine et détonation.

**Routes réellement déclarées :** airDown=`AirSpike`, airSide=`AirSwitch`, airUp=`AirDrive`, down=`Sweep`, side=`FeintStep`, up=`Launcher` ; lourd après un hit : `ClayPop`. [MoveGraphs](../../../../src/Shared/MoveGraphs.luau). Ces noms ne prouvent pas les animations ni les contacts. Invariant : avant premier hit confirmé, direction+Light ne déclenche aucune route spéciale.

## 6. Techniques présentes et admissibilité de période

Snapshot du kit actuel ; temps = **channel / active / recovery**, en secondes. Coûts/cooldowns/portées sont configurés, pas validés par cette documentation. REVIEW_REQUIRED signifie provenance/période non établie ici ; ne pas désactiver la technique sur ce seul label.

| Technique / fonction actuelle | Coût | C/A/R | CD | Portée | Statut de période |
|---|---:|---|---:|---:|---|
| `ClayBirds` — C1: Clay Birds : Two clay birds fly at the body and burst • a bird that misses lands and waits (a charge) | 18 | 0.3/0.06/0.3 | 4.5 | 40 | REVIEW_REQUIRED (technique et âge exact) |
| `ClaySpiders` — C1: Clay Spiders : Three spiders run the floor and pop under the body (launches) • those that miss stop and wait as charges | 16 | 0.26/0.06/0.28 | 5 | 30 | REVIEW_REQUIRED (technique et âge exact) |
| `ClayMine` — Clay Landmine : A charge buried where he aims • it blasts whoever steps on it • Katsu! sets it off from anywhere | 12 | 0.2/0.1/0.25 | 5 | 26 | REVIEW_REQUIRED (technique et âge exact) |
| `Katsu` — Katsu! : KATSU! Every charge he has laid goes off where it lies • and the clay at his feet bursts (a close attacker thrown far) | 16 | 0.06/0.2/0.3 | 9 | 6 | REVIEW_REQUIRED (technique et âge exact) |

**Capacités possibles / limites :** les variantes de mouvement, routes et chakra décrites ici sont des **GAMEPLAY_LIBERTY proposées** lorsqu’aucune source de période ne les atteste ; une possibilité n’est pas un bouton supplémentaire à implémenter. Préférer faire mieux fonctionner une interaction existante avant d’ajouter un jutsu.

## 7. Éveil, boucles et habileté du joueur

**Éveil actuellement nommé :** `ART IS AN EXPLOSION`. **Cible/contrat :** ChainCharges déjà existant : armement/chaîne de détonations, lisibilité avant spectaculaire.

**Boucle agressive :** approche propre au personnage → ouverture/hit confirmé → route utile → choix outil/jutsu ou sortie ; priorité : Poser→menacer une trajectoire→faire choisir→Katsu ; charge identifiable et consommée une seule fois.

**Boucle défensive/faible chakra :** Garde et petit burst de dégagement ; pression rapprochée doit le forcer à abandonner un setup. Réserve moyenne, contrôle précis des objets ; budget dépensé à poser/préparer plutôt qu’à poursuivre physiquement. À sec : outils et petit reposition, pas champ de mines gratuit.

**Plafond de maîtrise du joueur :** Débutant : oiseau/Katsu. Intermédiaire : poser sur une sortie. Expert : retarder une détonation pour forcer un détour.

**Hors kit / incohérences de période à résoudre :** C2/C3/C4/C0, suicide, vol géant ; pas multiplication d’explosifs pour compenser une mine illisible.

## 8. Acceptation Studio et sources

**Scénario distinctif :** Mine dedans/dehors portée ; avant/après armement puis Katsu ; reconnaître posé/armé/consommé sans F8 et rejouer face à Lee.

Puis jouer en continu :20s sans jutsu pour reconnaître silhouette/déplacements/contacts ; séquence garde/whiff/hit ; faible chakra puis éveil ; KO/reset. Ne pas replacer les acteurs entre tous les coups et ne pas annoncer un PASS sur un simple spawn. Comparer au fighter le plus proche et garder une faiblesse perceptible. Preuves datées par build dans CURRENT_STATE/rapports, pas badge inventé dans cette fiche.

Provenance du stade et de chaque technique jeune encore à compléter par chapitre/épisode/source primaire ; le runtime et les choix de design ne valent pas preuve canon.
