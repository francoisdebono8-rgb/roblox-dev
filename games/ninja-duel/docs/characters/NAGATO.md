# Nagato Uzumaki — fiche de référence

ID runtime **`Rinnegan`** · version documentaire du **18/10/2026** · données lues au HEAD **`1cabd7f`** (runtime `bc7faa3`). [Index/comparaison](ROSTER_20.md) · [contrat commun](FIGHTER_TEMPLATE.md).

**Portée :** intention utilisateur et méthode dans [DEC-025](../active/DECISIONS.md#dec-025--fiches-personnages-et-identité-perceptible). Cette fiche propose la cible détaillée ; elle n’annonce ni validation lore complète, ni implémentation, ni autorisation de nouvelle passe. Priorités/acceptation : [MASTER_BACKLOG](../active/MASTER_BACKLOG.md). État global : [CURRENT_STATE](../active/CURRENT_STATE.md).

## 1. Version et promesse

Enfant entraîné par Jiraiya, âge12 runtime ; répulsion/attraction/absorption de combat à12 non prouvées ici, convention V1 à arbitrer.

**Signature irremplaçable :** Attirer pour forcer une décision, repousser l’engagement ou lire un projectile pour l’absorber.

**Faiblesse/contre-jeu :** Lecture ratée, melee sous absorption, cooldown et corps exposé ; absorption ne doit pas tout annuler.

## 2. Tenue, silhouette et mouvement — cible

**Vêtements/armes visibles :** Tenue simple d’orphelin d’Ame, cheveux roux, corps fin, yeux Rinnegan visibles ; pas robe Pain/Akatsuki ni récepteurs du corps de Yahiko.

**Course, sprint, strafe, dash et esquive :** Course sobre, peu de déplacements explosifs ; maintenir la distance par technique engagée, pas même dash rouge de mêlée.

**Air, poursuite, réception et mur :** Air : anti-air/poussée limitée puis sol ; mur : repoussement avec vraie collision, pas téléportation. Une réception ramène à des appuis stables ; la caméra ne doit pas masquer la source d’un coup.

## 3. Chakra — distinguer nature, contrôle et quantité

**Nature/capacité particulière proposée :** Rinnegan = dōjutsu, pas nature Gravité. Les cinq natures connues à une période ultérieure ne donnent pas cinq jutsus actifs à cet enfant ; rester sur fonctions du kit sous label de période.

**Réserve, efficacité et faible chakra :** Réserve élevée cible, contrôle et canalisation encore coûteux ; attraction/répulsion/absorption sont des choix concurrents, pas une économie positive infinie.

**Interaction concrète à rendre perceptible :** Kunai secondaire et paumes ; pas projectiles gravitationnels rendus comme simples boules de feu violettes.

Le profil d’infusion actuel est **`Basic`**, d’après [ChakraTuning](../../src/Server/ChakraTuning.luau). Ce nom décrit l’interpréteur actuel, pas toutes ses capacités ni une maîtrise acquise par le joueur. Un fallback Basic n’annule pas ses jutsus ; il signale l’absence de spécialisation explicite dans ce mapping.

## 4. Repères du build actuel — pas des stats canon

| Paramètre runtime | Valeur brute |
|---|---:|
| Âge affiché | 12 |
| Santé | 112 |
| Réservoir de chakra | 140 |
| Paramètre ChakraRegen | 9 |
| Speed de base | 18 |
| Coefficient SprintScale | 1.06 |
| JumpScale / AirControlScale | 1 / 1 |
| AccelerationScale | 0.98 |
| Distance préférée configurée | 10 |

Sources : [définition](../../src/Shared/Wave3.luau), [mouvement](../../src/Server/Motor.luau), [régénération](../../src/Server/Combat.luau). Speed est une base en studs/s, pas une vitesse native mesurée ; le sprint dépend du profil de mouvement et des états, **pas simplement Speed×SprintScale**. Regen est également modulée en combat. Ne pas retuner ces nombres sur la seule lecture de la fiche.

**Habiletés cibles relatives (1–5, proposition de design, aucun multiplicateur runtime ni score officiel) :** Taijutsu 2/5, Ninjutsu 5/5, Genjutsu 2/5, Contrôle 4/5, Outils/armes 2/5, Endurance 3/5. Les axes désignent des spécialisations, pas un total de puissance à maximiser ; Lee1 en ninjutsu ne signifie pas absence de chakra.

## 5. Moveset et défense — cible à confronter au kit

**Chaîne légère représentative :** Paume courte → déviation → RepellingPalm de séparation ; le corps reste fragile si la technique est baitée.

**Routes :** Haut : launcher de paume ; bas : dégagement bas ; côté : cercle prudent ; lourd : RepellingPalm. Attraction rapproche avant une décision, pas auto-combo garanti.

**Garde, parade, esquive/substitution et reprise :** Absorb fenêtre2.5s et Repulsion ; melee reste dangereux ; son reflet d’éveil conserve un trajet et une propriété cohérents. La substitution garde coût, charges, fenêtre et destination autorisés du système commun ; aucun échappatoire gratuit implicite.

**Outils :** Kunai secondaire et paumes ; pas projectiles gravitationnels rendus comme simples boules de feu violettes.

**Routes réellement déclarées :** airDown=`AirSpike`, airSide=`AirSwitch`, airUp=`AirDrive`, down=`Sweep`, side=`CircleStep`, up=`Launcher` ; lourd après un hit : `RepellingPalm`. [MoveGraphs](../../src/Shared/MoveGraphs.luau). Ces noms ne prouvent pas les animations ni les contacts. Invariant : avant premier hit confirmé, direction+Light ne déclenche aucune route spéciale.

## 6. Techniques présentes et admissibilité de période

Snapshot du kit actuel ; temps = **channel / active / recovery**, en secondes. Coûts/cooldowns/portées sont configurés, pas validés par cette documentation. REVIEW_REQUIRED signifie provenance/période non établie ici ; ne pas désactiver la technique sur ce seul label.

| Technique / fonction actuelle | Coût | C/A/R | CD | Portée | Statut de période |
|---|---:|---|---:|---:|---|
| `Repulsion` — Repulsion : Everything round him pushed away: blades, bodies (into walls) | 22 | 0.1/0.2/0.35 | 7 | 8 | REVIEW_REQUIRED (technique et âge exact) |
| `Attraction` — Attraction : The body pulled to him • then the string, or Repulsion | 16 | 0.2/0.05/0.25 | 4 | 30 | REVIEW_REQUIRED (technique et âge exact) |
| `Absorb` — Absorbing Seal : 2.5 s: every jutsu or blade that reaches him is drunk (chakra, a little health) • blows still land | 8 | 0.06/0.05/0.15 | 8 | 20 | REVIEW_REQUIRED (technique et âge exact) |

**Capacités possibles / limites :** les variantes de mouvement, routes et chakra décrites ici sont des **GAMEPLAY_LIBERTY proposées** lorsqu’aucune source de période ne les atteste ; une possibilité n’est pas un bouton supplémentaire à implémenter. Préférer faire mieux fonctionner une interaction existante avant d’ajouter un jutsu.

## 7. Éveil, boucles et habileté du joueur

**Éveil actuellement nommé :** `RINNEGAN`. **Cible/contrat :** ReflectClear existant, Absorbed2 observé en Studio : montrer fenêtre et renvoi ; pas nouvelle mécanique de ressources.

**Boucle agressive :** approche propre au personnage → ouverture/hit confirmé → route utile → choix outil/jutsu ou sortie ; priorité : Attirer pour forcer une décision, repousser l’engagement ou lire un projectile pour l’absorber.

**Boucle défensive/faible chakra :** Absorb fenêtre2.5s et Repulsion ; melee reste dangereux ; son reflet d’éveil conserve un trajet et une propriété cohérents. Réserve élevée cible, contrôle et canalisation encore coûteux ; attraction/répulsion/absorption sont des choix concurrents, pas une économie positive infinie.

**Plafond de maîtrise du joueur :** Débutant : repousser. Intermédiaire : choisir attirer/absorber. Expert : lire la source et forcer une mauvaise réponse adverse.

**Hors kit / incohérences de période à résoudre :** SixPaths, corps Pain, ChibakuTensei, invocation géante, RinneRebirth ; l’existence du Rinnegan ne valide pas leur maîtrise à12.

## 8. Acceptation Studio et sources

**Scénario distinctif :** Absorb contre projectile puis coup de poing ; fermeture de fenêtre visible ; repoussement vers mur sans perte de contrôle de caméra.

Puis jouer en continu :20s sans jutsu pour reconnaître silhouette/déplacements/contacts ; séquence garde/whiff/hit ; faible chakra puis éveil ; KO/reset. Ne pas replacer les acteurs entre tous les coups et ne pas annoncer un PASS sur un simple spawn. Comparer au fighter le plus proche et garder une faiblesse perceptible. Preuves datées par build dans CURRENT_STATE/rapports, pas badge inventé dans cette fiche.

Provenance du stade et de chaque technique jeune encore à compléter par chapitre/épisode/source primaire ; le runtime et les choix de design ne valent pas preuve canon.
