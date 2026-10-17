# Naruto Uzumaki — fiche de référence

ID runtime **`Legion`** · version documentaire du **18/10/2026** · données lues au HEAD **`1cabd7f`** (runtime `bc7faa3`). [Index/comparaison](ROSTER_20.md) · [contrat commun](FIGHTER_TEMPLATE.md).

**Portée :** intention utilisateur et méthode dans [DEC-025](../active/DECISIONS.md#dec-025--fiches-personnages-et-identité-perceptible). Cette fiche propose la cible détaillée ; elle n’annonce ni validation lore complète, ni implémentation, ni autorisation de nouvelle passe. Priorités/acceptation : [MASTER_BACKLOG](../active/MASTER_BACKLOG.md). État global : [CURRENT_STATE](../active/CURRENT_STATE.md).

## 1. Version et promesse

Fin PartieI, Rasengan appris avec clone ; âge13 runtime.

**Signature irremplaçable :** Créer plusieurs origines de menace, forcer un choix puis préparer un Rasengan aidé.

**Faiblesse/contre-jeu :** Clones fragiles, préparation interrompue, dépense inefficace et vraies ouvertures du corps principal.

## 2. Tenue, silhouette et mouvement — cible

**Vêtements/armes visibles :** Veste orange/bleu, col clair, bandeau et cheveux blonds courts ; attitude inclinée et expressive ; clones portent la même silhouette.

**Course, sprint, strafe, dash et esquive :** Course insistante et appuis moins raffinés ; rush corporel avec clones qui changent l’origine des coups ; manteau autorisé seulement dans son état spécial.

**Air, poursuite, réception et mur :** Air : clone porteur et poursuite ; mur : point d’attaque d’un clone sans traversée gratuite du décor. Une réception ramène à des appuis stables ; la caméra ne doit pas masquer la source d’un coup.

## 3. Chakra — distinguer nature, contrôle et quantité

**Nature/capacité particulière proposée :** Fûton latent à distinguer de sa maîtrise : pas de jutsu Vent actif dans ce stade. Rasengan = forme sans nature ajoutée ; Kyûbi = source particulière, pas un élément.

**Réserve, efficacité et faible chakra :** Plus grande réserve cible, contrôle moins efficace que Neji/Kabuto ; clones et répétition consomment, Rasengan demande préparation. À sec : bagarre/outils, pas clones gratuits.

**Interaction concrète à rendre perceptible :** Kunai, transformation kunai→clone déjà particulière ; pas infusion Vent avancée au prétexte de l’affinité future.

Le profil d’infusion actuel est **`ShadowClone`**, d’après [ChakraTuning](../../src/Server/ChakraTuning.luau). Ce nom décrit l’interpréteur actuel, pas toutes ses capacités ni une maîtrise acquise par le joueur. Un fallback Basic n’annule pas ses jutsus ; il signale l’absence de spécialisation explicite dans ce mapping.

## 4. Repères du build actuel — pas des stats canon

| Paramètre runtime | Valeur brute |
|---|---:|
| Âge affiché | 13 |
| Santé | 140 |
| Réservoir de chakra | 160 |
| Paramètre ChakraRegen | 6.5 |
| Speed de base | 18.5 |
| Coefficient SprintScale | 1.12 |
| JumpScale / AirControlScale | 1.1 / 1 |
| AccelerationScale | 1.08 |
| Distance préférée configurée | 6 |

Sources : [définition](../../src/Shared/Fighters.luau), [mouvement](../../src/Server/Motor.luau), [régénération](../../src/Server/Combat.luau). Speed est une base en studs/s, pas une vitesse native mesurée ; le sprint dépend du profil de mouvement et des états, **pas simplement Speed×SprintScale**. Regen est également modulée en combat. Ne pas retuner ces nombres sur la seule lecture de la fiche.

**Habiletés cibles relatives (1–5, proposition de design, aucun multiplicateur runtime ni score officiel) :** Taijutsu 3/5, Ninjutsu 4/5, Genjutsu 1/5, Contrôle 2/5, Outils/armes 3/5, Endurance 5/5. Les axes désignent des spécialisations, pas un total de puissance à maximiser ; Lee1 en ninjutsu ne signifie pas absence de chakra.

## 5. Moveset et défense — cible à confronter au kit

**Chaîne légère représentative :** Poing d’entrée → coup au corps → coup de pied/attaque de clone depuis autre angle ; le vrai Naruto reste la cible clairement identifiée.

**Routes :** Haut : UzumakiKick ; bas : Tackle ; côté : MirrorClone ; lourd : Headbutt. Convertir par corps présent, pas simple double VFX de la même hitbox.

**Garde, parade, esquive/substitution et reprise :** Garde simple, substitution/échange avec clone si autorisé par le kit ; clone dissipable et vraie santé unique. La substitution garde coût, charges, fenêtre et destination autorisés du système commun ; aucun échappatoire gratuit implicite.

**Outils :** Kunai, transformation kunai→clone déjà particulière ; pas infusion Vent avancée au prétexte de l’affinité future.

**Routes réellement déclarées :** airDown=`AirSpike`, airSide=`AirSwitch`, airUp=`AirDrive`, down=`Tackle`, side=`MirrorClone`, up=`UzumakiKick` ; lourd après un hit : `Headbutt`. [MoveGraphs](../../src/Shared/MoveGraphs.luau). Ces noms ne prouvent pas les animations ni les contacts. Invariant : avant premier hit confirmé, direction+Light ne déclenche aucune route spéciale.

## 6. Techniques présentes et admissibilité de période

Snapshot du kit actuel ; temps = **channel / active / recovery**, en secondes. Coûts/cooldowns/portées sont configurés, pas validés par cette documentation. REVIEW_REQUIRED signifie provenance/période non établie ici ; ne pas désactiver la technique sur ce seul label.

| Technique / fonction actuelle | Coût | C/A/R | CD | Portée | Statut de période |
|---|---:|---|---:|---:|---|
| `ShadowClone` — Shadow Clone : A clone at his side (two at most) • one blow dispels it • routes, the Rasengan and the swap use them | 12 | 0.18/0.05/0.12 | 1.2 | 30 | CANON_YOUNG (clones) |
| `CloneRasengan` — Rasengan : A clone shapes it at his side • strike the clone and it fails • ends a clean string | 22 | 0.45/0.08/0.45 | 6 | 10 | CANON_YOUNG (Rasengan aidé) |
| `MassShadowClone` — Multi Shadow Clone : Clones burst out on both sides and charge | 30 | 0.3/0.08/0.2 | 10 | 26 | CANON_YOUNG (concept ; plafond GAMEPLAY_LIBERTY) |

**Capacités possibles / limites :** les variantes de mouvement, routes et chakra décrites ici sont des **GAMEPLAY_LIBERTY proposées** lorsqu’aucune source de période ne les atteste ; une possibilité n’est pas un bouton supplémentaire à implémenter. Préférer faire mieux fonctionner une interaction existante avant d’ajouter un jutsu.

## 7. Éveil, boucles et habileté du joueur

**Éveil actuellement nommé :** `NINE-TAILS CHAKRA`. **Cible/contrat :** Chakra Kyûbi : changement corporel qui peut retirer les clones, pas réserve infinie ni bijû géant.

**Boucle agressive :** approche propre au personnage → ouverture/hit confirmé → route utile → choix outil/jutsu ou sortie ; priorité : Créer plusieurs origines de menace, forcer un choix puis préparer un Rasengan aidé.

**Boucle défensive/faible chakra :** Garde simple, substitution/échange avec clone si autorisé par le kit ; clone dissipable et vraie santé unique. Plus grande réserve cible, contrôle moins efficace que Neji/Kabuto ; clones et répétition consomment, Rasengan demande préparation. À sec : bagarre/outils, pas clones gratuits.

**Plafond de maîtrise du joueur :** Débutant : clones/pression. Intermédiaire : Rasengan préparé. Expert : choisir origine et sacrifice des clones.

**Hors kit / incohérences de période à résoudre :** Rasenshuriken, mode ermite, KCM et formes de guerre ; pas d’amélioration Fûton de son Rasengan PartieI.

## 8. Acceptation Studio et sources

**Scénario distinctif :** Détruire le clone qui aide au Rasengan doit avoir une conséquence ; lire vrai corps et origine secondaire ; comparer low-chakra à Neji sans gonfler HP.

Puis jouer en continu :20s sans jutsu pour reconnaître silhouette/déplacements/contacts ; séquence garde/whiff/hit ; faible chakra puis éveil ; KO/reset. Ne pas replacer les acteurs entre tous les coups et ne pas annoncer un PASS sur un simple spawn. Comparer au fighter le plus proche et garder une faiblesse perceptible. Preuves datées par build dans CURRENT_STATE/rapports, pas badge inventé dans cette fiche.

[Source officielle fin PartieI](https://naruto-official.com/en/news/01_1296), [Rasengan puis évolution Vent](https://naruto-official.com/fr/news/01_1521).

[Ancienne fiche conservée](../archive/characters/2026-10-18-before-profiles/NARUTO.md) : détails historiques et candidats non repris sans validation. Les anciens noms/valeurs/plans ne remplacent pas cette séparation cible/existant.
