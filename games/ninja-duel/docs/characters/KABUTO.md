# Kabuto Yakushi — fiche de référence

ID runtime **`Medic`** · version documentaire du **18/10/2026** · données lues au HEAD **`1cabd7f`** (runtime `bc7faa3`). [Index/comparaison](ROSTER_20.md) · [contrat commun](FIGHTER_TEMPLATE.md).

**Portée :** intention utilisateur et méthode dans [DEC-025](../active/DECISIONS.md#dec-025--fiches-personnages-et-identité-perceptible). Cette fiche propose la cible détaillée ; elle n’annonce ni validation lore complète, ni implémentation, ni autorisation de nouvelle passe. Priorités/acceptation : [MASTER_BACKLOG](../active/MASTER_BACKLOG.md). État global : [CURRENT_STATE](../active/CURRENT_STATE.md).

## 1. Version et promesse

Kabuto espion/médical jeune, âge13 runtime ; scalpel/soin expert à cet âge non certifiés.

**Signature irremplaçable :** Limiter l’option adverse par une coupe puis choisir drain, petit soin ou sortie.

**Faiblesse/contre-jeu :** Allonge et burst faibles, poursuite après soin et gaspillage d’une fenêtre médicale.

## 2. Tenue, silhouette et mouvement — cible

**Vêtements/armes visibles :** Tenue de jeune agent/médic gris-lilas, cheveux gris attachés, lunettes rondes ; paumes disponibles et port compact ; pas corps serpent de guerre.

**Course, sprint, strafe, dash et esquive :** Pas courts, posture compacte et retrait diagonal ; rush modéré orienté placement du scalpel, pas shunshin de Shisui.

**Air, poursuite, réception et mur :** Air : frappe courte pour retomber ; mur : sortie diagonale, pas spécialisation aérienne. Une réception ramène à des appuis stables ; la caméra ne doit pas masquer la source d’un coup.

## 3. Chakra — distinguer nature, contrôle et quantité

**Nature/capacité particulière proposée :** Ninjutsu médical = précision/contrôle du chakra, pas élément Vert. Aucune affinité élémentaire imposée pour remplir la fiche.

**Réserve, efficacité et faible chakra :** Réserve moyenne, contrôle élevé ; efficacité locale, drain et soin sous fenêtre/risque. À sec : anatomie/paumes et recul, aucun soin infini.

**Interaction concrète à rendre perceptible :** Kunai/shuriken sobres et mains au scalpel ; feedback de précision au contact, pas large aura de dégâts.

Le profil d’infusion actuel est **`Basic`**, d’après [ChakraTuning](../../src/Server/ChakraTuning.luau). Ce nom décrit l’interpréteur actuel, pas toutes ses capacités ni une maîtrise acquise par le joueur. Un fallback Basic n’annule pas ses jutsus ; il signale l’absence de spécialisation explicite dans ce mapping.

## 4. Repères du build actuel — pas des stats canon

| Paramètre runtime | Valeur brute |
|---|---:|
| Âge affiché | 13 |
| Santé | 130 |
| Réservoir de chakra | 125 |
| Paramètre ChakraRegen | 9 |
| Speed de base | 19 |
| Coefficient SprintScale | 1.08 |
| JumpScale / AirControlScale | 1.02 / 1 |
| AccelerationScale | 1.04 |
| Distance préférée configurée | 4.5 |

Sources : [définition](../../src/Shared/Wave2.luau), [mouvement](../../src/Server/Motor.luau), [régénération](../../src/Server/Combat.luau). Speed est une base en studs/s, pas une vitesse native mesurée ; le sprint dépend du profil de mouvement et des états, **pas simplement Speed×SprintScale**. Regen est également modulée en combat. Ne pas retuner ces nombres sur la seule lecture de la fiche.

**Habiletés cibles relatives (1–5, proposition de design, aucun multiplicateur runtime ni score officiel) :** Taijutsu 4/5, Ninjutsu 3/5, Genjutsu 2/5, Contrôle 5/5, Outils/armes 3/5, Endurance 3/5. Les axes désignent des spécialisations, pas un total de puissance à maximiser ; Lee1 en ninjutsu ne signifie pas absence de chakra.

## 5. Moveset et défense — cible à confronter au kit

**Chaîne légère représentative :** Paume de contrôle → coupe de tendon → poussée/retrait ; rythme clinique et gestes petits, distincts des Hyûga.

**Routes :** Haut : launcher de déséquilibre ; bas : TendonCut ; côté : cercle de retrait ; lourd : ScalpelSlice. Couper une action ne signifie pas drainer tout le chakra.

**Garde, parade, esquive/substitution et reprise :** Garde/parade précise et MendingRetreat ; soin engagé, punissable et plafonné, pas invulnérabilité pendant retraite. La substitution garde coût, charges, fenêtre et destination autorisés du système commun ; aucun échappatoire gratuit implicite.

**Outils :** Kunai/shuriken sobres et mains au scalpel ; feedback de précision au contact, pas large aura de dégâts.

**Routes réellement déclarées :** airDown=`AirSpike`, airSide=`AirSwitch`, airUp=`AirDrive`, down=`Sweep`, side=`CircleStep`, up=`Launcher` ; lourd après un hit : `ScalpelSlice`. [MoveGraphs](../../src/Shared/MoveGraphs.luau). Ces noms ne prouvent pas les animations ni les contacts. Invariant : avant premier hit confirmé, direction+Light ne déclenche aucune route spéciale.

## 6. Techniques présentes et admissibilité de période

Snapshot du kit actuel ; temps = **channel / active / recovery**, en secondes. Coûts/cooldowns/portées sont configurés, pas validés par cette documentation. REVIEW_REQUIRED signifie provenance/période non établie ici ; ne pas désactiver la technique sur ce seul label.

| Technique / fonction actuelle | Coût | C/A/R | CD | Portée | Statut de période |
|---|---:|---|---:|---:|---|
| `ChakraScalpel` — Chakra Scalpel : Blades of chakra on his hands for 8 s: every blow cuts a muscle (slows) and drains | 18 | 0.25/0.05/0.2 | 12 | 20 | REVIEW_REQUIRED (technique et âge exact) |
| `TendonCut` — Scalpel: Tendon Cut : A low cut at the legs: the body slows hard | 12 | 0.12/0.05/0.1 | 4.5 | 10 | REVIEW_REQUIRED (technique et âge exact) |
| `MendingRetreat` — Mystical Palm Retreat : A flicker out of reach, the Mystical Palm closing his wounds | 20 | 0.1/0.04/0.2 | 11 | 11 | REVIEW_REQUIRED (technique et âge exact) |

**Capacités possibles / limites :** les variantes de mouvement, routes et chakra décrites ici sont des **GAMEPLAY_LIBERTY proposées** lorsqu’aucune source de période ne les atteste ; une possibilité n’est pas un bouton supplémentaire à implémenter. Préférer faire mieux fonctionner une interaction existante avant d’ajouter un jutsu.

## 7. Éveil, boucles et habileté du joueur

**Éveil actuellement nommé :** `MEDICAL GENIUS`. **Cible/contrat :** MedicalGenius/OnHit composé garde drain+slow : correction existante à conserver ; la lecture médicale doit devenir perceptible.

**Boucle agressive :** approche propre au personnage → ouverture/hit confirmé → route utile → choix outil/jutsu ou sortie ; priorité : Limiter l’option adverse par une coupe puis choisir drain, petit soin ou sortie.

**Boucle défensive/faible chakra :** Garde/parade précise et MendingRetreat ; soin engagé, punissable et plafonné, pas invulnérabilité pendant retraite. Réserve moyenne, contrôle élevé ; efficacité locale, drain et soin sous fenêtre/risque. À sec : anatomie/paumes et recul, aucun soin infini.

**Plafond de maîtrise du joueur :** Débutant : coupe/retrait. Intermédiaire : soin sûr. Expert : punir une habitude et utiliser peu de chakra pour une fenêtre utile.

**Hors kit / incohérences de période à résoudre :** Mode ermite, greffes multiples, régénération extrême et pouvoirs de guerre ; talents avancés à13 en review.

## 8. Acceptation Studio et sources

**Scénario distinctif :** Scalpel+éveil conserve les deux effets ; retraite soignante se poursuit/punit ; à HP max aucun heal excédentaire, KO nettoie les buffs.

Puis jouer en continu :20s sans jutsu pour reconnaître silhouette/déplacements/contacts ; séquence garde/whiff/hit ; faible chakra puis éveil ; KO/reset. Ne pas replacer les acteurs entre tous les coups et ne pas annoncer un PASS sur un simple spawn. Comparer au fighter le plus proche et garder une faiblesse perceptible. Preuves datées par build dans CURRENT_STATE/rapports, pas badge inventé dans cette fiche.

Provenance du stade et de chaque technique jeune encore à compléter par chapitre/épisode/source primaire ; le runtime et les choix de design ne valent pas preuve canon.
