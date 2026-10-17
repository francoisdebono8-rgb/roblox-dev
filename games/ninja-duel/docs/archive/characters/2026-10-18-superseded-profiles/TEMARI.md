> Historique remplacé par DEC-026 : ancien roster et ancienne définition de fiche, pas cible V1 à exécuter.

# Temari of the Sand — fiche de référence

ID runtime **`Gale`** · version documentaire du **18/10/2026** · données lues au HEAD **`1cabd7f`** (runtime `bc7faa3`). [Index/comparaison](../../../characters/ROSTER_20.md) · [contrat commun](../../../characters/FIGHTER_TEMPLATE.md).

**Portée :** intention utilisateur et méthode dans [DEC-025](../../../active/DECISIONS.md#dec-025--fiches-personnages-et-identité-perceptible). Cette fiche propose la cible détaillée ; elle n’annonce ni validation lore complète, ni implémentation, ni autorisation de nouvelle passe. Priorités/acceptation : [MASTER_BACKLOG](../../../active/MASTER_BACKLOG.md). État global : [CURRENT_STATE](../../../active/CURRENT_STATE.md).

## 1. Version et promesse

PartieI examen chûnin/récupération ; âge15 runtime, donc hors slogan uniforme12–14.

**Signature irremplaçable :** Forcer un déplacement avec un couloir de vent puis contrôler sa sortie.

**Faiblesse/contre-jeu :** Corps à corps serré, flancs et gros gestes interrompus ; feu/vent peut aussi aider l’ennemi.

## 2. Tenue, silhouette et mouvement — cible

**Vêtements/armes visibles :** Tenue claire/lilas de Suna selon modèle PartieI retenu, cheveux en quatre couettes, grand éventail aux trois lunes ; objet central lisible fermé et ouvert.

**Course, sprint, strafe, dash et esquive :** Pas latéraux larges, réorientation de l’éventail, recul contrôlé ; dash/retrait par appui et petite bourrasque sous condition, pas même rush que Lee.

**Air, poursuite, réception et mur :** Air : contrôle d’angle/descente avec éventail, pas vol libre ; mur : souffle de sortie et canalisation d’une ligne. Une réception ramène à des appuis stables ; la caméra ne doit pas masquer la source d’un coup.

## 3. Chakra — distinguer nature, contrôle et quantité

**Nature/capacité particulière proposée :** Fûton : volumes, coupe et déviation. L’éventail est le support ; le feu adverse peut interagir avec le vent selon règle système, pas selon avantage arbitraire.

**Réserve, efficacité et faible chakra :** Réserve moyenne, contrôle de volumes élevé ; payer ouverture/zone, éviter rafales infinies. À sec : éventail fermé et reposition, pas vent gratuit puissant.

**Interaction concrète à rendre perceptible :** Éventail/FanGust et infusion WindFan ; pas kunai standard comme signature principale.

Le profil d’infusion actuel est **`WindFan`**, d’après [ChakraTuning](../../../../src/Server/ChakraTuning.luau). Ce nom décrit l’interpréteur actuel, pas toutes ses capacités ni une maîtrise acquise par le joueur. Un fallback Basic n’annule pas ses jutsus ; il signale l’absence de spécialisation explicite dans ce mapping.

## 4. Repères du build actuel — pas des stats canon

| Paramètre runtime | Valeur brute |
|---|---:|
| Âge affiché | 15 |
| Santé | 130 |
| Réservoir de chakra | 120 |
| Paramètre ChakraRegen | 8 |
| Speed de base | 17.5 |
| Coefficient SprintScale | 0.95 |
| JumpScale / AirControlScale | 1 / 1.3 |
| AccelerationScale | 0.95 |
| Distance préférée configurée | 16 |

Sources : [définition](../../../../src/Shared/Fighters.luau), [mouvement](../../../../src/Server/Motor.luau), [régénération](../../../../src/Server/Combat.luau). Speed est une base en studs/s, pas une vitesse native mesurée ; le sprint dépend du profil de mouvement et des états, **pas simplement Speed×SprintScale**. Regen est également modulée en combat. Ne pas retuner ces nombres sur la seule lecture de la fiche.

**Habiletés cibles relatives (1–5, proposition de design, aucun multiplicateur runtime ni score officiel) :** Taijutsu 2/5, Ninjutsu 5/5, Genjutsu 1/5, Contrôle 4/5, Outils/armes 4/5, Endurance 3/5. Les axes désignent des spécialisations, pas un total de puissance à maximiser ; Lee1 en ninjutsu ne signifie pas absence de chakra.

## 5. Moveset et défense — cible à confronter au kit

**Chaîne légère représentative :** Bord d’éventail fermé → poussée au manche → balayage d’air lisible ; contact physique séparé du volume de vent.

**Routes :** Haut : Updraft ; bas : FanSlam ; côté : FanPirouette ; lourd : FanBackhand. La zone prépare une distance plutôt qu’une mêlée interminable.

**Garde, parade, esquive/substitution et reprise :** Garde à l’éventail, repousser les projectiles à bon timing ; punissable si éventail ouvert ou récupération longue. La substitution garde coût, charges, fenêtre et destination autorisés du système commun ; aucun échappatoire gratuit implicite.

**Outils :** Éventail/FanGust et infusion WindFan ; pas kunai standard comme signature principale.

**Routes réellement déclarées :** airDown=`FanDive`, airUp=`AirDrive`, down=`FanSlam`, side=`FanPirouette`, up=`Updraft` ; lourd après un hit : `FanBackhand`. [MoveGraphs](../../../../src/Shared/MoveGraphs.luau). Ces noms ne prouvent pas les animations ni les contacts. Invariant : avant premier hit confirmé, direction+Light ne déclenche aucune route spéciale.

## 6. Techniques présentes et admissibilité de période

Snapshot du kit actuel ; temps = **channel / active / recovery**, en secondes. Coûts/cooldowns/portées sont configurés, pas validés par cette documentation. REVIEW_REQUIRED signifie provenance/période non établie ici ; ne pas désactiver la technique sur ce seul label.

| Technique / fonction actuelle | Coût | C/A/R | CD | Portée | Statut de période |
|---|---:|---|---:|---:|---|
| `Kamaitachi` — Kamaitachi : A wind scythe • its lane slows the way up, carries the way down, turns blades aside • knocks away (walls) | 12 | 0.3/0.06/0.3 | 2.8 | 46 | REVIEW_REQUIRED (technique et âge exact) |
| `GreatGust` — Great Gust : Three moons: blades blown away, the body thrown back • a wide lane stays | 22 | 0.5/0.2/0.42 | 7 | 30 | REVIEW_REQUIRED (technique et âge exact) |
| `Cyclone` — Rising Whirlwind : A whirlwind rises where the opponent stood • keep moving | 16 | 0.24/0.05/0.3 | 5.5 | 34 | REVIEW_REQUIRED (technique et âge exact) |

**Capacités possibles / limites :** les variantes de mouvement, routes et chakra décrites ici sont des **GAMEPLAY_LIBERTY proposées** lorsqu’aucune source de période ne les atteste ; une possibilité n’est pas un bouton supplémentaire à implémenter. Préférer faire mieux fonctionner une interaction existante avant d’ajouter un jutsu.

## 7. Éveil, boucles et habileté du joueur

**Éveil actuellement nommé :** `KIRIKIRI MAI`. **Cible/contrat :** Kamatari/KirikiriMai existant à échelle duel : nouvelle pression de zone, pas simple boost de dégâts.

**Boucle agressive :** approche propre au personnage → ouverture/hit confirmé → route utile → choix outil/jutsu ou sortie ; priorité : Forcer un déplacement avec un couloir de vent puis contrôler sa sortie.

**Boucle défensive/faible chakra :** Garde à l’éventail, repousser les projectiles à bon timing ; punissable si éventail ouvert ou récupération longue. Réserve moyenne, contrôle de volumes élevé ; payer ouverture/zone, éviter rafales infinies. À sec : éventail fermé et reposition, pas vent gratuit puissant.

**Plafond de maîtrise du joueur :** Débutant : pousser. Intermédiaire : placer le couloir. Expert : décider quand le vent coupe un trajet ou favorise l’adversaire.

**Hors kit / incohérences de période à résoudre :** Techniques de jônin adulte, tempêtes de terrain et vol permanent.

## 8. Acceptation Studio et sources

**Scénario distinctif :** Projectile qui rencontre le couloir ; entrer/sortir d’une ligne et voir pieds/corps ; éventail fermé reconnaissable sans lancer de jutsu.

Puis jouer en continu :20s sans jutsu pour reconnaître silhouette/déplacements/contacts ; séquence garde/whiff/hit ; faible chakra puis éveil ; KO/reset. Ne pas replacer les acteurs entre tous les coups et ne pas annoncer un PASS sur un simple spawn. Comparer au fighter le plus proche et garder une faiblesse perceptible. Preuves datées par build dans CURRENT_STATE/rapports, pas badge inventé dans cette fiche.

Provenance du stade et de chaque technique jeune encore à compléter par chapitre/épisode/source primaire ; le runtime et les choix de design ne valent pas preuve canon.

[Ancienne fiche conservée](../2026-10-18-before-profiles/TEMARI.md) : détails historiques et candidats non repris sans validation. Les anciens noms/valeurs/plans ne remplacent pas cette séparation cible/existant.
