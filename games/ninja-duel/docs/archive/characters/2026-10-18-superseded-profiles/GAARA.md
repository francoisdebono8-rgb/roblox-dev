> Historique remplacé par DEC-026 : ancien roster et ancienne définition de fiche, pas cible V1 à exécuter.

# Gaara of the Sand — fiche de référence

ID runtime **`Sand`** · version documentaire du **18/10/2026** · données lues au HEAD **`1cabd7f`** (runtime `bc7faa3`). [Index/comparaison](../../../characters/ROSTER_20.md) · [contrat commun](../../../characters/FIGHTER_TEMPLATE.md).

**Portée :** intention utilisateur et méthode dans [DEC-025](../../../active/DECISIONS.md#dec-025--fiches-personnages-et-identité-perceptible). Cette fiche propose la cible détaillée ; elle n’annonce ni validation lore complète, ni implémentation, ni autorisation de nouvelle passe. Priorités/acceptation : [MASTER_BACKLOG](../../../active/MASTER_BACKLOG.md). État global : [CURRENT_STATE](../../../active/CURRENT_STATE.md).

## 1. Version et promesse

Examen chûnin/récupération PartieI ; âge12 runtime ; échelle de duel.

**Signature irremplaçable :** Tenir une distance avec le sable, forcer entrée ou esquive, enfermer puis choisir pression ou retrait.

**Faiblesse/contre-jeu :** Lenteur du corps, angles et punition des fouets ratés ; saisie/pression doivent offrir un contre-jeu explicite.

## 2. Tenue, silhouette et mouvement — cible

**Vêtements/armes visibles :** Tenue sable/brun-rouge, cheveux rouges courts, gourde volumineuse et sangle ; silhouette identifiable même de dos, bras peu mobiles.

**Course, sprint, strafe, dash et esquive :** Marche lourde calme, peu de gestes ; corps lent comparé à son sable ; rush comme déplacement protégé limité, pas téléport ni combo de boxe rapide.

**Air, poursuite, réception et mur :** Air : projection/contrôle court de sable ; mur : pression et garde d’angle, pas vol libre de Kazekage. Une réception ramène à des appuis stables ; la caméra ne doit pas masquer la source d’un coup.

## 3. Chakra — distinguer nature, contrôle et quantité

**Nature/capacité particulière proposée :** Sable contrôlé par chakra ; sable et Shukaku ne sont pas synonymes d’un Doton générique. Ne pas ajouter Magnétisme/Fûton adultes par déduction.

**Réserve, efficacité et faible chakra :** Réserve élevée pour contrôle/maintien, rythme de dépense posé ; défense non gratuite sans limite. À sec : sable proche et sortie prudente, pas bouclier illimité.

**Interaction concrète à rendre perceptible :** Projectiles et volumes de sable ; gourde = source visuelle et rythme, pas kunai tenu par défaut.

Le profil d’infusion actuel est **`Basic`**, d’après [ChakraTuning](../../../../src/Server/ChakraTuning.luau). Ce nom décrit l’interpréteur actuel, pas toutes ses capacités ni une maîtrise acquise par le joueur. Un fallback Basic n’annule pas ses jutsus ; il signale l’absence de spécialisation explicite dans ce mapping.

## 4. Repères du build actuel — pas des stats canon

| Paramètre runtime | Valeur brute |
|---|---:|
| Âge affiché | 12 |
| Santé | 140 |
| Réservoir de chakra | 130 |
| Paramètre ChakraRegen | 7 |
| Speed de base | 16.5 |
| Coefficient SprintScale | 0.85 |
| JumpScale / AirControlScale | 0.9 / 0.85 |
| AccelerationScale | 0.85 |
| Distance préférée configurée | 11 |

Sources : [définition](../../../../src/Shared/Fighters.luau), [mouvement](../../../../src/Server/Motor.luau), [régénération](../../../../src/Server/Combat.luau). Speed est une base en studs/s, pas une vitesse native mesurée ; le sprint dépend du profil de mouvement et des états, **pas simplement Speed×SprintScale**. Regen est également modulée en combat. Ne pas retuner ces nombres sur la seule lecture de la fiche.

**Habiletés cibles relatives (1–5, proposition de design, aucun multiplicateur runtime ni score officiel) :** Taijutsu 2/5, Ninjutsu 5/5, Genjutsu 1/5, Contrôle 4/5, Outils/armes 2/5, Endurance 4/5. Les axes désignent des spécialisations, pas un total de puissance à maximiser ; Lee1 en ninjutsu ne signifie pas absence de chakra.

## 5. Moveset et défense — cible à confronter au kit

**Chaîne légère représentative :** Ordre de bras → fouet de sable → repoussement ; le contact part du sable, le corps reste en retrait.

**Routes :** Haut : pilier de sable ; bas : sable au sol qui déséquilibre ; côté : déplacement protecteur à proposer sans route spéciale avant hit.

**Garde, parade, esquive/substitution et reprise :** Charges de bouclier, distinction entre défense automatique et garde volontaire ; attaquer expose le corps et les gros coups cassent la protection. La substitution garde coût, charges, fenêtre et destination autorisés du système commun ; aucun échappatoire gratuit implicite.

**Outils :** Projectiles et volumes de sable ; gourde = source visuelle et rythme, pas kunai tenu par défaut.

**Routes réellement déclarées :** down=`Sweep`, up=`SandPillar` ; lourd après un hit : `SandPillar`. [MoveGraphs](../../../../src/Shared/MoveGraphs.luau). Ces noms ne prouvent pas les animations ni les contacts. Invariant : avant premier hit confirmé, direction+Light ne déclenche aucune route spéciale.

## 6. Techniques présentes et admissibilité de période

Snapshot du kit actuel ; temps = **channel / active / recovery**, en secondes. Coûts/cooldowns/portées sont configurés, pas validés par cette documentation. REVIEW_REQUIRED signifie provenance/période non établie ici ; ne pas désactiver la technique sur ce seul label.

| Technique / fonction actuelle | Coût | C/A/R | CD | Portée | Statut de période |
|---|---:|---|---:|---:|---|
| `SandCoffin` — Sand Coffin : A wave of sand binds, then crushes • substitution escapes | 26 | 0.35/0.1/0.35 | 8 | 30 | REVIEW_REQUIRED (technique et âge exact) |
| `SandShuriken` — Sand Shuriken : Six hardened sand blades | 16 | 0.25/0.08/0.25 | 3.5 | 38 | REVIEW_REQUIRED (technique et âge exact) |
| `DesertWave` — Desert Wave : A wall of sand throws close attackers away | 22 | 0.26/0.2/0.3 | 6 | 12 | REVIEW_REQUIRED (technique et âge exact) |

**Capacités possibles / limites :** les variantes de mouvement, routes et chakra décrites ici sont des **GAMEPLAY_LIBERTY proposées** lorsqu’aucune source de période ne les atteste ; une possibilité n’est pas un bouton supplémentaire à implémenter. Préférer faire mieux fonctionner une interaction existante avant d’ajouter un jutsu.

## 7. Éveil, boucles et habileté du joueur

**Éveil actuellement nommé :** `SHUKAKU'S SAND`. **Cible/contrat :** Conserver l’état Shukaku du runtime à échelle réduite ; aucun géant. Les règles exactes restent celles du kit et de la revue, pas un nouveau bonus documentaire.

**Boucle agressive :** approche propre au personnage → ouverture/hit confirmé → route utile → choix outil/jutsu ou sortie ; priorité : Tenir une distance avec le sable, forcer entrée ou esquive, enfermer puis choisir pression ou retrait.

**Boucle défensive/faible chakra :** Charges de bouclier, distinction entre défense automatique et garde volontaire ; attaquer expose le corps et les gros coups cassent la protection. Réserve élevée pour contrôle/maintien, rythme de dépense posé ; défense non gratuite sans limite. À sec : sable proche et sortie prudente, pas bouclier illimité.

**Plafond de maîtrise du joueur :** Débutant : défense/zone. Intermédiaire : économiser charges. Expert : contrôler l’entrée tout en laissant une sortie possible.

**Hors kit / incohérences de période à résoudre :** Shukaku géant, tsunami et vol libre ; capacités jeunes mais trop grandes également hors échelle, pas toutes « adultes ».

## 8. Acceptation Studio et sources

**Scénario distinctif :** Reconnaissance sans jutsu par gourde/corps calme/sable actif ; casser bouclier puis punir un fouet raté ; caméra doit montrer le vrai corps.

Puis jouer en continu :20s sans jutsu pour reconnaître silhouette/déplacements/contacts ; séquence garde/whiff/hit ; faible chakra puis éveil ; KO/reset. Ne pas replacer les acteurs entre tous les coups et ne pas annoncer un PASS sur un simple spawn. Comparer au fighter le plus proche et garder une faiblesse perceptible. Preuves datées par build dans CURRENT_STATE/rapports, pas badge inventé dans cette fiche.

[Source officielle examen chûnin](https://naruto-official.com/en/news/01_1282).

[Ancienne fiche conservée](../2026-10-18-before-profiles/GAARA.md) : détails historiques et candidats non repris sans validation. Les anciens noms/valeurs/plans ne remplacent pas cette séparation cible/existant.
