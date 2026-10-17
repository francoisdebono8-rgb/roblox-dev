> Historique remplacé par DEC-026 : ancien roster et ancienne définition de fiche, pas cible V1 à exécuter.

# Orochimaru — fiche de référence

ID runtime **`Serpent`** · version documentaire du **18/10/2026** · données lues au HEAD **`1cabd7f`** (runtime `bc7faa3`). [Index/comparaison](../../../characters/ROSTER_20.md) · [contrat commun](../../../characters/FIGHTER_TEMPLATE.md).

**Portée :** intention utilisateur et méthode dans [DEC-025](../../../active/DECISIONS.md#dec-025--fiches-personnages-et-identité-perceptible). Cette fiche propose la cible détaillée ; elle n’annonce ni validation lore complète, ni implémentation, ni autorisation de nouvelle passe. Priorités/acceptation : [MASTER_BACKLOG](../../../active/MASTER_BACKLOG.md). État global : [CURRENT_STATE](../../../active/CURRENT_STATE.md).

## 1. Version et promesse

Orochimaru élève/prodige ; âge12 runtime. Les serpents/venin et techniques nommées à12 restent REVIEW_REQUIRED.

**Signature irremplaçable :** Toucher à distance courte/moyenne, ramener sans dépasser son corps puis exploiter une fenêtre de venin.

**Faiblesse/contre-jeu :** Prévisibilité de l’allonge, whiff et coût ; ne doit pas cumuler saisie, poison et invulnérabilité sans décision.

## 2. Tenue, silhouette et mouvement — cible

**Vêtements/armes visibles :** Tenue de jeune élève de Konoha, claire/terre, cheveux noirs longs et regard pâle ; accessoires serpent limités, pas uniforme de dirigeant d’Oto adulte.

**Course, sprint, strafe, dash et esquive :** Pas souples bas, entrée glissante et longue portée de main ; garder une trajectoire physique, pas dash démoniaque identique à tous.

**Air, poursuite, réception et mur :** Air : attraper puis ramener au sol ; mur : angle de serpent à ligne de vue, aucune traversée arbitraire. Une réception ramène à des appuis stables ; la caméra ne doit pas masquer la source d’un coup.

## 3. Chakra — distinguer nature, contrôle et quantité

**Nature/capacité particulière proposée :** Pas d’affinité élémentaire jeune prouvée ici. Serpents, allongement/liaison et venin = techniques/capacités, pas élément Poison ; ne pas recopier les cinq natures adultes.

**Réserve, efficacité et faible chakra :** Réserve cible assez élevée, contrôle technique ; entretien/liaison et attaques venimeuses coûtent un vrai engagement. À sec : allonge corporelle bornée et outils.

**Interaction concrète à rendre perceptible :** Serpents comme tirs de traction/entrave, outil secondaire simple ; poison visible sans bloquer tous les inputs.

Le profil d’infusion actuel est **`Basic`**, d’après [ChakraTuning](../../../../src/Server/ChakraTuning.luau). Ce nom décrit l’interpréteur actuel, pas toutes ses capacités ni une maîtrise acquise par le joueur. Un fallback Basic n’annule pas ses jutsus ; il signale l’absence de spécialisation explicite dans ce mapping.

## 4. Repères du build actuel — pas des stats canon

| Paramètre runtime | Valeur brute |
|---|---:|
| Âge affiché | 12 |
| Santé | 130 |
| Réservoir de chakra | 130 |
| Paramètre ChakraRegen | 8 |
| Speed de base | 18.5 |
| Coefficient SprintScale | 1.08 |
| JumpScale / AirControlScale | 1 / 1 |
| AccelerationScale | 1 |
| Distance préférée configurée | 9 |

Sources : [définition](../../../../src/Shared/Wave2.luau), [mouvement](../../../../src/Server/Motor.luau), [régénération](../../../../src/Server/Combat.luau). Speed est une base en studs/s, pas une vitesse native mesurée ; le sprint dépend du profil de mouvement et des états, **pas simplement Speed×SprintScale**. Regen est également modulée en combat. Ne pas retuner ces nombres sur la seule lecture de la fiche.

**Habiletés cibles relatives (1–5, proposition de design, aucun multiplicateur runtime ni score officiel) :** Taijutsu 3/5, Ninjutsu 4/5, Genjutsu 3/5, Contrôle 4/5, Outils/armes 3/5, Endurance 4/5. Les axes désignent des spécialisations, pas un total de puissance à maximiser ; Lee1 en ninjutsu ne signifie pas absence de chakra.

## 5. Moveset et défense — cible à confronter au kit

**Chaîne légère représentative :** Main qui sonde → frappe allongée → venin/coupe de séparation ; montrer d’où vient le serpent et quand le corps est exposé.

**Routes :** Haut : launcher d’allonge ; bas : saisie/balayage bas ; côté : feinte souple ; lourd : VenomFang et poison borné.

**Garde, parade, esquive/substitution et reprise :** Feinte et recul, pas régénération immortelle ; liaison peut être évitée/interrompue et laisse une sortie. La substitution garde coût, charges, fenêtre et destination autorisés du système commun ; aucun échappatoire gratuit implicite.

**Outils :** Serpents comme tirs de traction/entrave, outil secondaire simple ; poison visible sans bloquer tous les inputs.

**Routes réellement déclarées :** airDown=`AirSpike`, airSide=`AirSwitch`, airUp=`AirDrive`, down=`Sweep`, side=`FeintStep`, up=`Launcher` ; lourd après un hit : `VenomFang`. [MoveGraphs](../../../../src/Shared/MoveGraphs.luau). Ces noms ne prouvent pas les animations ni les contacts. Invariant : avant premier hit confirmé, direction+Light ne déclenche aucune route spéciale.

## 6. Techniques présentes et admissibilité de période

Snapshot du kit actuel ; temps = **channel / active / recovery**, en secondes. Coûts/cooldowns/portées sont configurés, pas validés par cette documentation. REVIEW_REQUIRED signifie provenance/période non établie ici ; ne pas désactiver la technique sur ce seul label.

| Technique / fonction actuelle | Coût | C/A/R | CD | Portée | Statut de période |
|---|---:|---|---:|---:|---|
| `ShadowSnake` — Striking Shadow Snakes : A snake from the sleeve bites and drags the body to him • venom | 16 | 0.26/0.06/0.3 | 4 | 26 | REVIEW_REQUIRED (technique et âge exact) |
| `SnakeCoil` — Hidden Shadow Snake Hands : Two snakes coil round the body and hold it • then they squeeze | 22 | 0.34/0.08/0.3 | 9 | 20 | REVIEW_REQUIRED (technique et âge exact) |
| `SnakeLunge` — Snake Lunge : A lunge with a fang in it: poison | 14 | 0.14/0.05/0.1 | 5 | 12 | REVIEW_REQUIRED (technique et âge exact) |

**Capacités possibles / limites :** les variantes de mouvement, routes et chakra décrites ici sont des **GAMEPLAY_LIBERTY proposées** lorsqu’aucune source de période ne les atteste ; une possibilité n’est pas un bouton supplémentaire à implémenter. Préférer faire mieux fonctionner une interaction existante avant d’ajouter un jutsu.

## 7. Éveil, boucles et habileté du joueur

**Éveil actuellement nommé :** `SNAKE CONTRACT`. **Cible/contrat :** SnakeContract OnHit/BindScale existants ; changer choix de contact/entrave, pas ajouter immortalité.

**Boucle agressive :** approche propre au personnage → ouverture/hit confirmé → route utile → choix outil/jutsu ou sortie ; priorité : Toucher à distance courte/moyenne, ramener sans dépasser son corps puis exploiter une fenêtre de venin.

**Boucle défensive/faible chakra :** Feinte et recul, pas régénération immortelle ; liaison peut être évitée/interrompue et laisse une sortie. Réserve cible assez élevée, contrôle technique ; entretien/liaison et attaques venimeuses coûtent un vrai engagement. À sec : allonge corporelle bornée et outils.

**Plafond de maîtrise du joueur :** Débutant : tirer/punir. Intermédiaire : lire la sortie. Expert : choisir poison ou reposition sans vider la réserve.

**Hors kit / incohérences de période à résoudre :** Kusanagi adulte, transfert de corps, EdoTensei, huit têtes, arsenal Sannin complet ; valider chaque candidat jeune.

## 8. Acceptation Studio et sources

**Scénario distinctif :** Traction depuis près et loin ne dépasse pas Orochimaru ; garde et esquive donnent des réponses différentes ; poison/entrave expirent/nettoient au KO.

Puis jouer en continu :20s sans jutsu pour reconnaître silhouette/déplacements/contacts ; séquence garde/whiff/hit ; faible chakra puis éveil ; KO/reset. Ne pas replacer les acteurs entre tous les coups et ne pas annoncer un PASS sur un simple spawn. Comparer au fighter le plus proche et garder une faiblesse perceptible. Preuves datées par build dans CURRENT_STATE/rapports, pas badge inventé dans cette fiche.

Provenance du stade et de chaque technique jeune encore à compléter par chapitre/épisode/source primaire ; le runtime et les choix de design ne valent pas preuve canon.
