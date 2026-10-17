# Neji Hyuga — fiche de référence

ID runtime **`GentleFist`** · version documentaire du **18/10/2026** · données lues au HEAD **`1cabd7f`** (runtime `bc7faa3`). [Index/comparaison](ROSTER_20.md) · [contrat commun](FIGHTER_TEMPLATE.md).

**Portée :** intention utilisateur et méthode dans [DEC-025](../active/DECISIONS.md#dec-025--fiches-personnages-et-identité-perceptible). Cette fiche propose la cible détaillée ; elle n’annonce ni validation lore complète, ni implémentation, ni autorisation de nouvelle passe. Priorités/acceptation : [MASTER_BACKLOG](../active/MASTER_BACKLOG.md). État global : [CURRENT_STATE](../active/CURRENT_STATE.md).

## 1. Version et promesse

PartieI, examen chûnin/récupération de Sasuke ; âge13 runtime.

**Signature irremplaçable :** Fermer des points puis choisir interrompre, repousser ou convertir en64paumes.

**Faiblesse/contre-jeu :** Portée courte, angles multiples et coût d’une Rotation ratée ; pas de neutralisation définitive du joueur adverse.

## 2. Tenue, silhouette et mouvement — cible

**Vêtements/armes visibles :** Tenue claire crème/beige de jeune Neji, cheveux longs bruns attachés bas, bandeau et bandages ; paumes ouvertes, pied avant léger.

**Course, sprint, strafe, dash et esquive :** Petits pas circulaires et centre stable ; rush bref qui entre à portée de paume ; dodge par lecture et décalage de ligne, sans disparition ni dash rouge.

**Air, poursuite, réception et mur :** Air : paumes de contrôle, pas acrobaties de Lee ; mur : pression de paume et sortie latérale, pas source d’un nouveau pouvoir. Une réception ramène à des appuis stables ; la caméra ne doit pas masquer la source d’un coup.

## 3. Chakra — distinguer nature, contrôle et quantité

**Nature/capacité particulière proposée :** Jûken = émission précise dans le réseau de chakra ; Byakugan = dōjutsu de perception. Ne pas appeler ce style « élément Air » parce que les paumes projettent une pression.

**Réserve, efficacité et faible chakra :** Réserve moyenne, contrôle très élevé et dépense précise. Son avantage est de perturber l’accès adverse au chakra ; à sec, footwork et paumes restent utiles, les verrous ne sont pas gratuits.

**Interaction concrète à rendre perceptible :** Kunai secondaire ; la touche chakra/outils du profil GentleFist devient une paume. Pas d’infusion élémentaire obligatoire sur lame.

Le profil d’infusion actuel est **`GentleFist`**, d’après [ChakraTuning](../../src/Server/ChakraTuning.luau). Ce nom décrit l’interpréteur actuel, pas toutes ses capacités ni une maîtrise acquise par le joueur. Un fallback Basic n’annule pas ses jutsus ; il signale l’absence de spécialisation explicite dans ce mapping.

## 4. Repères du build actuel — pas des stats canon

| Paramètre runtime | Valeur brute |
|---|---:|
| Âge affiché | 13 |
| Santé | 135 |
| Réservoir de chakra | 115 |
| Paramètre ChakraRegen | 7.6 |
| Speed de base | 18.5 |
| Coefficient SprintScale | 1 |
| JumpScale / AirControlScale | 0.98 / 0.95 |
| AccelerationScale | 1.02 |
| Distance préférée configurée | 5 |

Sources : [définition](../../src/Shared/Fighters.luau), [mouvement](../../src/Server/Motor.luau), [régénération](../../src/Server/Combat.luau). Speed est une base en studs/s, pas une vitesse native mesurée ; le sprint dépend du profil de mouvement et des états, **pas simplement Speed×SprintScale**. Regen est également modulée en combat. Ne pas retuner ces nombres sur la seule lecture de la fiche.

**Habiletés cibles relatives (1–5, proposition de design, aucun multiplicateur runtime ni score officiel) :** Taijutsu 5/5, Ninjutsu 3/5, Genjutsu 1/5, Contrôle 5/5, Outils/armes 2/5, Endurance 3/5. Les axes désignent des spécialisations, pas un total de puissance à maximiser ; Lee1 en ninjutsu ne signifie pas absence de chakra.

## 5. Moveset et défense — cible à confronter au kit

**Chaîne légère représentative :** Paume d’entrée → fermeture d’un point → paume de déséquilibre ; les contacts portent sur des cibles précises, pas une boxe avec étincelles bleues.

**Routes :** Haut : paume montante ; bas : déséquilibre/balayage ; côté : CircleStep vers angle mort. Les points n’autorisent une conversion que sur contact confirmé.

**Garde, parade, esquive/substitution et reprise :** Rotation comme réponse coûteuse et annoncée, lecture du contact et angle mort à respecter hors état spécial. La substitution garde coût, charges, fenêtre et destination autorisés du système commun ; aucun échappatoire gratuit implicite.

**Outils :** Kunai secondaire ; la touche chakra/outils du profil GentleFist devient une paume. Pas d’infusion élémentaire obligatoire sur lame.

**Routes réellement déclarées :** airDown=`AirSpike`, airSide=`AirSwitch`, airUp=`AirDrive`, down=`Sweep`, side=`CircleStep`, up=`Launcher` ; lourd après un hit : `PalmThrust`. [MoveGraphs](../../src/Shared/MoveGraphs.luau). Ces noms ne prouvent pas les animations ni les contacts. Invariant : avant premier hit confirmé, direction+Light ne déclenche aucune route spéciale.

## 6. Techniques présentes et admissibilité de période

Snapshot du kit actuel ; temps = **channel / active / recovery**, en secondes. Coûts/cooldowns/portées sont configurés, pas validés par cette documentation. REVIEW_REQUIRED signifie provenance/période non établie ici ; ne pas désactiver la technique sur ce seul label.

| Technique / fonction actuelle | Coût | C/A/R | CD | Portée | Statut de période |
|---|---:|---|---:|---:|---|
| `Rotation` — Rotation : Spinning dome • repels strikes and blades • counter after | 24 | 0.04/0.55/0.24 | 6 | 7 | CANON_YOUNG (Rotation) |
| `VacuumPalm` — Vacuum Palm : Air-pressure palm • pushes into walls • ends a clean string | 14 | 0.18/0.06/0.26 | 2.8 | 32 | REVIEW_REQUIRED (technique et âge exact) |
| `SixtyFourPalms` — 64 Palms : Point blank • each closed point adds palms and seal time • four closed: the guard collapses | 30 | 0.22/0.12/0.4 | 10 | 5 | CANON_YOUNG (64paumes) |

**Capacités possibles / limites :** les variantes de mouvement, routes et chakra décrites ici sont des **GAMEPLAY_LIBERTY proposées** lorsqu’aucune source de période ne les atteste ; une possibilité n’est pas un bouton supplémentaire à implémenter. Préférer faire mieux fonctionner une interaction existante avant d’ajouter un jutsu.

## 7. Éveil, boucles et habileté du joueur

**Éveil actuellement nommé :** `BYAKUGAN FULL FIELD`. **Cible/contrat :** NoBlindSpot/Points/Drain/ChannelCut existants : rendre visibles fermeture de points et expiration, avec contre-jeu.

**Boucle agressive :** approche propre au personnage → ouverture/hit confirmé → route utile → choix outil/jutsu ou sortie ; priorité : Fermer des points puis choisir interrompre, repousser ou convertir en64paumes.

**Boucle défensive/faible chakra :** Rotation comme réponse coûteuse et annoncée, lecture du contact et angle mort à respecter hors état spécial. Réserve moyenne, contrôle très élevé et dépense précise. Son avantage est de perturber l’accès adverse au chakra ; à sec, footwork et paumes restent utiles, les verrous ne sont pas gratuits.

**Plafond de maîtrise du joueur :** Débutant : paumes/Rotation. Intermédiaire : compter les points. Expert : couper une canalisation et gérer l’angle mort sans surdépenser.

**Hors kit / incohérences de période à résoudre :** Pouvoirs adultes non nécessaires ; VacuumPalm à13 reste REVIEW_REQUIRED jusqu’à référence de période précise.

## 8. Acceptation Studio et sources

**Scénario distinctif :** Comparer sans jutsu à Hinata : cercle offensif et points vs réaction protectrice ; fermer puis laisser expirer un point ; Rotation baitée doit laisser une fenêtre.

Puis jouer en continu :20s sans jutsu pour reconnaître silhouette/déplacements/contacts ; séquence garde/whiff/hit ; faible chakra puis éveil ; KO/reset. Ne pas replacer les acteurs entre tous les coups et ne pas annoncer un PASS sur un simple spawn. Comparer au fighter le plus proche et garder une faiblesse perceptible. Preuves datées par build dans CURRENT_STATE/rapports, pas badge inventé dans cette fiche.

[Source officielle Neji](https://naruto-official.com/en/news/01_1817) — Jûken et combat PartieI, pas validation de chaque variante.

[Ancienne fiche conservée](../archive/characters/2026-10-18-before-profiles/NEJI.md) : détails historiques et candidats non repris sans validation. Les anciens noms/valeurs/plans ne remplacent pas cette séparation cible/existant.
