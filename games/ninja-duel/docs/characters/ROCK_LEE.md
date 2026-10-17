# Rock Lee — fiche de référence

ID runtime **`Leaf`** · version documentaire du **18/10/2026** · données lues au HEAD **`1cabd7f`** (runtime `bc7faa3`). [Index/comparaison](ROSTER_20.md) · [contrat commun](FIGHTER_TEMPLATE.md).

**Portée :** intention utilisateur et méthode dans [DEC-025](../active/DECISIONS.md#dec-025--fiches-personnages-et-identité-perceptible). Cette fiche propose la cible détaillée ; elle n’annonce ni validation lore complète, ni implémentation, ni autorisation de nouvelle passe. Priorités/acceptation : [MASTER_BACKLOG](../active/MASTER_BACKLOG.md). État global : [CURRENT_STATE](../active/CURRENT_STATE.md).

## 1. Version et promesse

Examen chûnin, Lee apte au combat ; âge13 runtime.

**Signature irremplaçable :** Maîtriser la distance au corps, lancer puis convertir physiquement ; vitesse acquise au prix de l’effort.

**Faiblesse/contre-jeu :** Portée, punition du whiff, fatigue et prise de risque des Portes.

## 2. Tenue, silhouette et mouvement — cible

**Vêtements/armes visibles :** Combinaison verte, gilet jeune selon référence retenue, bandages et jambières orange/poids ; pieds et mains très lisibles.

**Course, sprint, strafe, dash et esquive :** Course et accélération corporelles les plus franches du roster ; changements d’appui et freinages visibles, poids/Portes expliquent les différences ; rafale d’air/poussière, pas téléport rouge.

**Air, poursuite, réception et mur :** Air : Lotus et poursuite physique quand autorisés ; mur : impulsion et sortie corporelle, pas saut élémentaire. Une réception ramène à des appuis stables ; la caméra ne doit pas masquer la source d’un coup.

## 3. Chakra — distinguer nature, contrôle et quantité

**Nature/capacité particulière proposée :** Aucune nature élémentaire active requise. Lee emploie l’énergie corporelle/chakra via taijutsu et Portes ; ne pas écrire qu’il est dépourvu de chakra ou biologiquement incapable d’en avoir.

**Réserve, efficacité et faible chakra :** La jauge technique actuelle est100, mais elle finance un effort de combat dans cette abstraction. Cible : endurance/risque corporel, Portes avec récupération ; pas de mana élémentaire ni infusion de kunai.

**Interaction concrète à rendre perceptible :** Touche outil = coup de pied déviant, pas projectile inventé ; bandages/poids ne deviennent pas quatre gadgets nouveaux.

Le profil d’infusion actuel est **`Taijutsu`**, d’après [ChakraTuning](../../src/Server/ChakraTuning.luau). Ce nom décrit l’interpréteur actuel, pas toutes ses capacités ni une maîtrise acquise par le joueur. Un fallback Basic n’annule pas ses jutsus ; il signale l’absence de spécialisation explicite dans ce mapping.

## 4. Repères du build actuel — pas des stats canon

| Paramètre runtime | Valeur brute |
|---|---:|
| Âge affiché | 13 |
| Santé | 125 |
| Réservoir de chakra | 100 |
| Paramètre ChakraRegen | 9.5 |
| Speed de base | 20 |
| Coefficient SprintScale | 1.2 |
| JumpScale / AirControlScale | 1.15 / 1.12 |
| AccelerationScale | 1.22 |
| Distance préférée configurée | 4.5 |

Sources : [définition](../../src/Shared/Fighters.luau), [mouvement](../../src/Server/Motor.luau), [régénération](../../src/Server/Combat.luau). Speed est une base en studs/s, pas une vitesse native mesurée ; le sprint dépend du profil de mouvement et des états, **pas simplement Speed×SprintScale**. Regen est également modulée en combat. Ne pas retuner ces nombres sur la seule lecture de la fiche.

**Habiletés cibles relatives (1–5, proposition de design, aucun multiplicateur runtime ni score officiel) :** Taijutsu 5/5, Ninjutsu 1/5, Genjutsu 1/5, Contrôle 3/5, Outils/armes 1/5, Endurance 5/5. Les axes désignent des spécialisations, pas un total de puissance à maximiser ; Lee1 en ninjutsu ne signifie pas absence de chakra.

## 5. Moveset et défense — cible à confronter au kit

**Chaîne légère représentative :** Jab de placement → coup de pied corps → rotation brève de jambe ; impact physique et retour d’appui, pas vol stationnaire.

**Routes :** Haut : LeafRising ; bas : LeafHurricane ; côté : LeafWhirlwind ; lourds et poursuites doivent montrer poids et engagement.

**Garde, parade, esquive/substitution et reprise :** Parade, déviation de pied et dodge au footwork ; défense à lire, pas aura qui absorbe tout. La substitution garde coût, charges, fenêtre et destination autorisés du système commun ; aucun échappatoire gratuit implicite.

**Outils :** Touche outil = coup de pied déviant, pas projectile inventé ; bandages/poids ne deviennent pas quatre gadgets nouveaux.

**Routes réellement déclarées :** airDown=`AirSpike`, airSide=`AirSwitch`, airUp=`AirDrive`, down=`LeafHurricane`, side=`LeafWhirlwind`, up=`LeafRising` ; lourd après un hit : `KneeStrike`. [MoveGraphs](../../src/Shared/MoveGraphs.luau). Ces noms ne prouvent pas les animations ni les contacts. Invariant : avant premier hit confirmé, direction+Light ne déclenche aucune route spéciale.

## 6. Techniques présentes et admissibilité de période

Snapshot du kit actuel ; temps = **channel / active / recovery**, en secondes. Coûts/cooldowns/portées sont configurés, pas validés par cette documentation. REVIEW_REQUIRED signifie provenance/période non établie ici ; ne pas désactiver la technique sur ce seul label.

| Technique / fonction actuelle | Coût | C/A/R | CD | Portée | Statut de période |
|---|---:|---|---:|---:|---|
| `LeafGreatWhirlwind` — Leaf Great Whirlwind : A spinning kick across the gap • knocks away • E to chase • ends a clean string | 10 | 0.08/0.05/0.1 | 2.6 | 15 | CANON_YOUNG (taijutsu ; paramètres GAMEPLAY_LIBERTY) |

**Capacités possibles / limites :** les variantes de mouvement, routes et chakra décrites ici sont des **GAMEPLAY_LIBERTY proposées** lorsqu’aucune source de période ne les atteste ; une possibilité n’est pas un bouton supplémentaire à implémenter. Préférer faire mieux fonctionner une interaction existante avant d’ajouter un jutsu.

## 7. Éveil, boucles et habileté du joueur

**Éveil actuellement nommé :** `FIFTH GATE`. **Cible/contrat :** Cinquième Porte : changement de mobilité/pression et coût corporel ; représenter le risque, garder une fin claire.

**Boucle agressive :** approche propre au personnage → ouverture/hit confirmé → route utile → choix outil/jutsu ou sortie ; priorité : Maîtriser la distance au corps, lancer puis convertir physiquement ; vitesse acquise au prix de l’effort.

**Boucle défensive/faible chakra :** Parade, déviation de pied et dodge au footwork ; défense à lire, pas aura qui absorbe tout. La jauge technique actuelle est100, mais elle finance un effort de combat dans cette abstraction. Cible : endurance/risque corporel, Portes avec récupération ; pas de mana élémentaire ni infusion de kunai.

**Plafond de maîtrise du joueur :** Débutant : entrer/chaîne. Intermédiaire : lancer/poursuivre. Expert : rythme, distance et décision d’ouvrir les Portes.

**Hors kit / incohérences de période à résoudre :** Ninjutsu/genjutsu offensifs, huitième Porte, téléportations et attaques élémentaires inventées.

## 8. Acceptation Studio et sources

**Scénario distinctif :** Sans jutsu : reconnaître accélération/appuis et absence de téléport ; outil dévie un projectile ; après Portes, observer la contrepartie et le retour au neutral.

Puis jouer en continu :20s sans jutsu pour reconnaître silhouette/déplacements/contacts ; séquence garde/whiff/hit ; faible chakra puis éveil ; KO/reset. Ne pas replacer les acteurs entre tous les coups et ne pas annoncer un PASS sur un simple spawn. Comparer au fighter le plus proche et garder une faiblesse perceptible. Preuves datées par build dans CURRENT_STATE/rapports, pas badge inventé dans cette fiche.

[Source officielle Lee](https://naruto-official.com/fr/news/01_1652) — taijutsu et Portes, pas absence de chakra.

[Ancienne fiche conservée](../archive/characters/2026-10-18-before-profiles/ROCK_LEE.md) : détails historiques et candidats non repris sans validation. Les anciens noms/valeurs/plans ne remplacent pas cette séparation cible/existant.
