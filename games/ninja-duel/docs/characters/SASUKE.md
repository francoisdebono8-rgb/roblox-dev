# Sasuke Uchiha — fiche de référence

ID runtime **`Lion`** · version documentaire du **18/10/2026** · données lues au HEAD **`1cabd7f`** (runtime `bc7faa3`). [Index/comparaison](ROSTER_20.md) · [contrat commun](FIGHTER_TEMPLATE.md).

**Portée :** intention utilisateur et méthode dans [DEC-025](../active/DECISIONS.md#dec-025--fiches-personnages-et-identité-perceptible). Cette fiche propose la cible détaillée ; elle n’annonce ni validation lore complète, ni implémentation, ni autorisation de nouvelle passe. Priorités/acceptation : [MASTER_BACKLOG](../active/MASTER_BACKLOG.md). État global : [CURRENT_STATE](../active/CURRENT_STATE.md).

## 1. Version et promesse

PartieI après entraînement avec Kakashi, avant arsenal de PartieII ; âge12 runtime.

**Signature irremplaçable :** Convertir une ouverture agressive en enchaînement jambes→fil→feu ou Chidori risqué.

**Faiblesse/contre-jeu :** Engagement, ressource et récupération des attaques fortes ; pression ne doit pas devenir une boucle garantie.

## 2. Tenue, silhouette et mouvement — cible

**Vêtements/armes visibles :** Tenue bleue jeune Uchiha avec col haut et short clair, cheveux noirs en pointes, sacoche et fil ; posture penchée vers l’avant, jambes disponibles.

**Course, sprint, strafe, dash et esquive :** Course agressive, freinage court et changements de niveau ; rush engagé qui expose si raté ; foudre seulement si une action Raiton le justifie.

**Air, poursuite, réception et mur :** Air : poursuite agressive et changement de côté ; mur : charge/angle Chidori existant sous condition, pas course électrique permanente. Une réception ramène à des appuis stables ; la caméra ne doit pas masquer la source d’un coup.

## 3. Chakra — distinguer nature, contrôle et quantité

**Nature/capacité particulière proposée :** Katon maîtrisé dans le kit ; Raiton via Chidori. Fil/métal conduisent selon règle de jeu sourcée ; Sharingan n’est pas une nature.

**Réserve, efficacité et faible chakra :** Réserve moyenne limitée, pic coûteux du Chidori et contrôle en développement ; à sec : kicks, fil et outils. Pas réserve ou récupération de version adulte.

**Interaction concrète à rendre perceptible :** Shuriken et fil ; fil→DragonFlame, métal→foudre si profil autorisé ; ne pas confondre outil qui blesse et fil qui prépare.

Le profil d’infusion actuel est **`LightningWire`**, d’après [ChakraTuning](../../src/Server/ChakraTuning.luau). Ce nom décrit l’interpréteur actuel, pas toutes ses capacités ni une maîtrise acquise par le joueur. Un fallback Basic n’annule pas ses jutsus ; il signale l’absence de spécialisation explicite dans ce mapping.

## 4. Repères du build actuel — pas des stats canon

| Paramètre runtime | Valeur brute |
|---|---:|
| Âge affiché | 12 |
| Santé | 120 |
| Réservoir de chakra | 105 |
| Paramètre ChakraRegen | 7.5 |
| Speed de base | 19 |
| Coefficient SprintScale | 1.1 |
| JumpScale / AirControlScale | 1.15 / 1.15 |
| AccelerationScale | 1.12 |
| Distance préférée configurée | 6 |

Sources : [définition](../../src/Shared/Fighters.luau), [mouvement](../../src/Server/Motor.luau), [régénération](../../src/Server/Combat.luau). Speed est une base en studs/s, pas une vitesse native mesurée ; le sprint dépend du profil de mouvement et des états, **pas simplement Speed×SprintScale**. Regen est également modulée en combat. Ne pas retuner ces nombres sur la seule lecture de la fiche.

**Habiletés cibles relatives (1–5, proposition de design, aucun multiplicateur runtime ni score officiel) :** Taijutsu 4/5, Ninjutsu 4/5, Genjutsu 2/5, Contrôle 3/5, Outils/armes 4/5, Endurance 3/5. Les axes désignent des spécialisations, pas un total de puissance à maximiser ; Lee1 en ninjutsu ne signifie pas absence de chakra.

## 5. Moveset et défense — cible à confronter au kit

**Chaîne légère représentative :** Entrée de jambe → frappe corps → coup de pied montant/retourné bref ; pression vive qui se termine par une décision outil ou poursuite.

**Routes :** Haut : LionKick ; bas : balayage de récupération ; côté : VaultKick/angle de pression ; lourd après un hit = genou. Fil peut ouvrir une conversion de feu.

**Garde, parade, esquive/substitution et reprise :** Garde active, Sharingan et déviation ; un dodge trop prévisible se punit, Chidori raté ne s’annule pas gratuitement. La substitution garde coût, charges, fenêtre et destination autorisés du système commun ; aucun échappatoire gratuit implicite.

**Outils :** Shuriken et fil ; fil→DragonFlame, métal→foudre si profil autorisé ; ne pas confondre outil qui blesse et fil qui prépare.

**Routes réellement déclarées :** airDown=`AirSpike`, airSide=`AirSwitch`, airUp=`AirDrive`, down=`Sweep`, side=`VaultKick`, up=`LionKick` ; lourd après un hit : `KneeStrike`. [MoveGraphs](../../src/Shared/MoveGraphs.luau). Ces noms ne prouvent pas les animations ni les contacts. Invariant : avant premier hit confirmé, direction+Light ne déclenche aucune route spéciale.

## 6. Techniques présentes et admissibilité de période

Snapshot du kit actuel ; temps = **channel / active / recovery**, en secondes. Coûts/cooldowns/portées sont configurés, pas validés par cette documentation. REVIEW_REQUIRED signifie provenance/période non établie ici ; ne pas désactiver la technique sur ce seul label.

| Technique / fonction actuelle | Coût | C/A/R | CD | Portée | Statut de période |
|---|---:|---|---:|---:|---|
| `FireBloom` — Great Fireball : On a wired opponent: Dragon Flame runs along the wire | 24 | 0.5/0.4/0.36 | 5.5 | 70 | CANON_YOUNG (Katon) |
| `PhoenixFlower` — Phoenix Flower : Flames with two shuriken hidden inside | 20 | 0.28/0.32/0.3 | 5 | 56 | CANON_YOUNG (Katon/outils) |
| `WireTrap` — Wire Trap : A wired shuriken binds • then 1 for Dragon Flame | 18 | 0.18/0.08/0.3 | 6 | 34 | PLAUSIBLE_YOUNG (fil ; nom/contrôle de jeu) |
| `Chidori` — Chidori : Charge, then a lightning thrust • a miss leaves him open | 34 | 0.62/0.05/0.1 | 9 | 20 | CANON_YOUNG (PartieI) |

**Capacités possibles / limites :** les variantes de mouvement, routes et chakra décrites ici sont des **GAMEPLAY_LIBERTY proposées** lorsqu’aucune source de période ne les atteste ; une possibilité n’est pas un bouton supplémentaire à implémenter. Préférer faire mieux fonctionner une interaction existante avant d’ajouter un jutsu.

## 7. Éveil, boucles et habileté du joueur

**Éveil actuellement nommé :** `CURSE MARK`. **Cible/contrat :** Marque maudite : extension/puissance avec coût corporel et vulnérabilité lisibles ; pas un simple recolor violet.

**Boucle agressive :** approche propre au personnage → ouverture/hit confirmé → route utile → choix outil/jutsu ou sortie ; priorité : Convertir une ouverture agressive en enchaînement jambes→fil→feu ou Chidori risqué.

**Boucle défensive/faible chakra :** Garde active, Sharingan et déviation ; un dodge trop prévisible se punit, Chidori raté ne s’annule pas gratuitement. Réserve moyenne limitée, pic coûteux du Chidori et contrôle en développement ; à sec : kicks, fil et outils. Pas réserve ou récupération de version adulte.

**Plafond de maîtrise du joueur :** Débutant : kicks/feu. Intermédiaire : fil→conversion. Expert : choisir Chidori, feinte ou sortie selon lecture.

**Hors kit / incohérences de période à résoudre :** Susanoo, Amaterasu, Rinnegan, Kirin et arsenal de sabre PartieII ; autres niveaux de marque hors kit de base.

## 8. Acceptation Studio et sources

**Scénario distinctif :** Comparer à Lee sur chaîne sans jutsu ; rater Chidori et subir la punition ; montrer fil→feu et foudre/métal comme interactions distinctes.

Puis jouer en continu :20s sans jutsu pour reconnaître silhouette/déplacements/contacts ; séquence garde/whiff/hit ; faible chakra puis éveil ; KO/reset. Ne pas replacer les acteurs entre tous les coups et ne pas annoncer un PASS sur un simple spawn. Comparer au fighter le plus proche et garder une faiblesse perceptible. Preuves datées par build dans CURRENT_STATE/rapports, pas badge inventé dans cette fiche.

[Source officielle PartieI](https://naruto-official.com/en/news/01_1282) et [fin PartieI](https://naruto-official.com/en/news/01_1296).

[Ancienne fiche conservée](../archive/characters/2026-10-18-before-profiles/SASUKE.md) : détails historiques et candidats non repris sans validation. Les anciens noms/valeurs/plans ne remplacent pas cette séparation cible/existant.
