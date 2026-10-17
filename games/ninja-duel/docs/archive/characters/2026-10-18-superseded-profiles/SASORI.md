> Historique remplacé par DEC-026 : ancien roster et ancienne définition de fiche, pas cible V1 à exécuter.

# Sasori of the Red Sand — fiche de référence

ID runtime **`Puppet`** · version documentaire du **18/10/2026** · données lues au HEAD **`1cabd7f`** (runtime `bc7faa3`). [Index/comparaison](../../../characters/ROSTER_20.md) · [contrat commun](../../../characters/FIGHTER_TEMPLATE.md).

**Portée :** intention utilisateur et méthode dans [DEC-025](../../../active/DECISIONS.md#dec-025--fiches-personnages-et-identité-perceptible). Cette fiche propose la cible détaillée ; elle n’annonce ni validation lore complète, ni implémentation, ni autorisation de nouvelle passe. Priorités/acceptation : [MASTER_BACKLOG](../../../active/MASTER_BACKLOG.md). État global : [CURRENT_STATE](../../../active/CURRENT_STATE.md).

## 1. Version et promesse

Jeune marionnettiste de Suna ; âge14 runtime. Parents-puppets attestés dans l’enfance, arsenal de poison précis non daté ici.

**Signature irremplaçable :** Tenir un poste avec un corps distant, déplacer le maître et choisir quand engager le porteur.

**Faiblesse/contre-jeu :** Corps maître vulnérable, porteur destructible et laisse ; route proxy ne doit pas tuer elle-même la marionnette.

## 2. Tenue, silhouette et mouvement — cible

**Vêtements/armes visibles :** Tenue de jeune Suna brun/ocre, cheveux roux courts, mains de marionnettiste et fils visibles ; marionnette en bois distincte, pas corps-pantin adulte de Sasori.

**Course, sprint, strafe, dash et esquive :** Corps sobre et plutôt lent, micro-reposition du maître ; marionnette se place plus vite indépendamment ; dash du maître ne mime pas un combattant de mêlée.

**Air, poursuite, réception et mur :** Air : attaque portée ou sortie du maître ; mur : angle de fil et laisse bornée, pas marionnette qui traverse gratuitement. Une réception ramène à des appuis stables ; la caméra ne doit pas masquer la source d’un coup.

## 3. Chakra — distinguer nature, contrôle et quantité

**Nature/capacité particulière proposée :** Fils de chakra et marionnettes = contrôle technique ; poison = substance/rider, pas nature élémentaire. Ne pas ajouter Magnétisme via le Troisième Kazekage.

**Réserve, efficacité et faible chakra :** Réserve moyenne, contrôle très élevé et attention partagée ; invoquer/piloter/lancer demande des fenêtres. À sec : outils/retrait, pas armée autonome.

**Interaction concrète à rendre perceptible :** Aiguilles, marionnette, FatherMother et fils ; la marionnette persistante est réutilisée, pas reconstruite à chaque coup.

Le profil d’infusion actuel est **`Basic`**, d’après [ChakraTuning](../../../../src/Server/ChakraTuning.luau). Ce nom décrit l’interpréteur actuel, pas toutes ses capacités ni une maîtrise acquise par le joueur. Un fallback Basic n’annule pas ses jutsus ; il signale l’absence de spécialisation explicite dans ce mapping.

## 4. Repères du build actuel — pas des stats canon

| Paramètre runtime | Valeur brute |
|---|---:|
| Âge affiché | 14 |
| Santé | 118 |
| Réservoir de chakra | 120 |
| Paramètre ChakraRegen | 8 |
| Speed de base | 18 |
| Coefficient SprintScale | 1.06 |
| JumpScale / AirControlScale | 1 / 0.95 |
| AccelerationScale | 0.98 |
| Distance préférée configurée | 11 |

Sources : [définition](../../../../src/Shared/Wave3.luau), [mouvement](../../../../src/Server/Motor.luau), [régénération](../../../../src/Server/Combat.luau). Speed est une base en studs/s, pas une vitesse native mesurée ; le sprint dépend du profil de mouvement et des états, **pas simplement Speed×SprintScale**. Regen est également modulée en combat. Ne pas retuner ces nombres sur la seule lecture de la fiche.

**Habiletés cibles relatives (1–5, proposition de design, aucun multiplicateur runtime ni score officiel) :** Taijutsu 2/5, Ninjutsu 4/5, Genjutsu 2/5, Contrôle 5/5, Outils/armes 5/5, Endurance 2/5. Les axes désignent des spécialisations, pas un total de puissance à maximiser ; Lee1 en ninjutsu ne signifie pas absence de chakra.

## 5. Moveset et défense — cible à confronter au kit

**Chaîne légère représentative :** Ordre des doigts → coup porté par le corps distant → reprise du fil ; sans marionnette, attaque de défense courte et vulnérable.

**Routes :** Haut : PuppetRise ; bas : PuppetSweep ; côté : feinte/reposition du maître ; lourd : PuppetBlade. Source du hit = position réelle du porteur.

**Garde, parade, esquive/substitution et reprise :** PuppetShield/contre sous fenêtre ; frapper la marionnette expose le maître. Poison ne traverse pas une garde réussie par accident. La substitution garde coût, charges, fenêtre et destination autorisés du système commun ; aucun échappatoire gratuit implicite.

**Outils :** Aiguilles, marionnette, FatherMother et fils ; la marionnette persistante est réutilisée, pas reconstruite à chaque coup.

**Routes réellement déclarées :** airDown=`AirSpike`, airUp=`AirDrive`, down=`PuppetSweep`, side=`FeintStep`, up=`PuppetRise` ; lourd après un hit : `PuppetBlade`. [MoveGraphs](../../../../src/Shared/MoveGraphs.luau). Ces noms ne prouvent pas les animations ni les contacts. Invariant : avant premier hit confirmé, direction+Light ne déclenche aucune route spéciale.

## 6. Techniques présentes et admissibilité de période

Snapshot du kit actuel ; temps = **channel / active / recovery**, en secondes. Coûts/cooldowns/portées sont configurés, pas validés par cette documentation. REVIEW_REQUIRED signifie provenance/période non établie ici ; ne pas désactiver la technique sur ce seul label.

| Technique / fonction actuelle | Coût | C/A/R | CD | Portée | Statut de période |
|---|---:|---|---:|---:|---|
| `Marionette` — Puppet: Marionette : His puppet on its threads: it holds a post by the opponent and strikes on its own (poison) • cast again: it lunges • one clean blow breaks it | 18 | 0.3/0.05/0.2 | 3 | 30 | REVIEW_REQUIRED (technique et âge exact) |
| `FatherMother` — Father and Mother: Embrace : Two puppets close on the body from both sides and hold it • then crush | 22 | 0.34/0.08/0.3 | 9 | 20 | REVIEW_REQUIRED (technique et âge exact) |
| `NeedleRain` — Poison Needle Rain : A fan of poisoned needles from a puppet's arm | 18 | 0.3/0.06/0.3 | 6 | 30 | REVIEW_REQUIRED (technique et âge exact) |
| `PuppetShield` — Puppet Shield : A puppet steps in front • the blow it takes is answered with a poisoned blade | 14 | 0.04/0.04/0.2 | 7 | 6 | REVIEW_REQUIRED (technique et âge exact) |

**Capacités possibles / limites :** les variantes de mouvement, routes et chakra décrites ici sont des **GAMEPLAY_LIBERTY proposées** lorsqu’aucune source de période ne les atteste ; une possibilité n’est pas un bouton supplémentaire à implémenter. Préférer faire mieux fonctionner une interaction existante avant d’ajouter un jutsu.

## 7. Éveil, boucles et habileté du joueur

**Éveil actuellement nommé :** `PUPPET MASTER`. **Cible/contrat :** PuppetMaster poison/entrave présents ; pas cent pantins ou invulnérabilité du cœur.

**Boucle agressive :** approche propre au personnage → ouverture/hit confirmé → route utile → choix outil/jutsu ou sortie ; priorité : Tenir un poste avec un corps distant, déplacer le maître et choisir quand engager le porteur.

**Boucle défensive/faible chakra :** PuppetShield/contre sous fenêtre ; frapper la marionnette expose le maître. Poison ne traverse pas une garde réussie par accident. Réserve moyenne, contrôle très élevé et attention partagée ; invoquer/piloter/lancer demande des fenêtres. À sec : outils/retrait, pas armée autonome.

**Plafond de maîtrise du joueur :** Débutant : invoquer/lunge. Intermédiaire : séparer maître et porteur. Expert : choisir origine de hit et sauver une marionnette sans s’exposer.

**Hors kit / incohérences de période à résoudre :** Corps-pantin adulte, Troisième Kazekage/Sable de fer, armée de cent ; poison et FatherMother de combat à14 nécessitent preuve ou liberté explicite.

## 8. Acceptation Studio et sources

**Scénario distinctif :** Route proxy conserve le corps ; garder un jab empêche poison ; détruire le porteur, vérifier reprise/KO et comparaison avec clones Naruto.

Puis jouer en continu :20s sans jutsu pour reconnaître silhouette/déplacements/contacts ; séquence garde/whiff/hit ; faible chakra puis éveil ; KO/reset. Ne pas replacer les acteurs entre tous les coups et ne pas annoncer un PASS sur un simple spawn. Comparer au fighter le plus proche et garder une faiblesse perceptible. Preuves datées par build dans CURRENT_STATE/rapports, pas badge inventé dans cette fiche.

[Source officielle Sasori](https://naruto-official.com/en/news/01_1641) — enfance et parents-puppets, pas arsenal complet à14.
