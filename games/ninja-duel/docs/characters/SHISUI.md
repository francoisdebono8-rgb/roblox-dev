# Shisui Uchiha — fiche de référence

ID runtime **`Flicker`** · version documentaire du **18/10/2026** · données lues au HEAD **`1cabd7f`** (runtime `bc7faa3`). [Index/comparaison](ROSTER_20.md) · [contrat commun](FIGHTER_TEMPLATE.md).

**Portée :** intention utilisateur et méthode dans [DEC-025](../active/DECISIONS.md#dec-025--fiches-personnages-et-identité-perceptible). Cette fiche propose la cible détaillée ; elle n’annonce ni validation lore complète, ni implémentation, ni autorisation de nouvelle passe. Priorités/acceptation : [MASTER_BACKLOG](../active/MASTER_BACKLOG.md). État global : [CURRENT_STATE](../active/CURRENT_STATE.md).

## 1. Version et promesse

Shisui jeune ; âge13 runtime non certifié par cette fiche. Distinguer manga, romans, anime et jeux pour chaque capacité.

**Signature irremplaçable :** Demande utilisateur : des mirages et déplacements particuliers. Candidat concret : après-images non autonomes qui prolongent brièvement le trajet/feinte ; seule la position réelle porte le hit. Coût, durée et nombre restent à régler, pas des clones Naruto avec dégâts.

**Faiblesse/contre-jeu :** Lecture adverse du vrai départ/arrêt, attaque de zone, garde qui couvre l’arrivée et chakra épuisé ; aucune invisibilité absolue.

## 2. Tenue, silhouette et mouvement — cible

**Vêtements/armes visibles :** Tenue Uchiha sombre à col haut, touches vertes sobres, cheveux noirs courts, bandeau et petit tantō si validé par référence ; posture mobile, pas robe Akatsuki.

**Course, sprint, strafe, dash et esquive :** Course nerveuse, accélération courte, freinage et rupture d’angle ; cible produit : rafales courtes traçables et après-images liées au trajet, retour du vrai corps lisible. Distinguer cette mobilité d’un warp vers marque de Minato.

**Air, poursuite, réception et mur :** Air : croisement bref puis retour, pas vol ; mur : rebond/angle qui laisse une trace de départ, sans ignorer obstacles. Une réception ramène à des appuis stables ; la caméra ne doit pas masquer la source d’un coup.

## 3. Chakra — distinguer nature, contrôle et quantité

**Nature/capacité particulière proposée :** Katon et genjutsu comme candidats du kit ; le Shunshin n’est ni FTG ni automatiquement Fûton. Les mirages sont une interprétation de vitesse/perception, pas un nouvel élément.

**Réserve, efficacité et faible chakra :** Réserve moyenne, contrôle et dépense de burst élevés ; budget des feintes/angles plutôt que chakra infini. À sec : déplacement corporel rapide, aucun mirage offensif gratuit.

**Interaction concrète à rendre perceptible :** Tantō/kunai/shuriken avec rôle court ; feu force la réaction à distance, genjutsu ouvre une lecture au lieu de remplacer tout le combat.

Le profil d’infusion actuel est **`Basic`**, d’après [ChakraTuning](../../src/Server/ChakraTuning.luau). Ce nom décrit l’interpréteur actuel, pas toutes ses capacités ni une maîtrise acquise par le joueur. Un fallback Basic n’annule pas ses jutsus ; il signale l’absence de spécialisation explicite dans ce mapping.

## 4. Repères du build actuel — pas des stats canon

| Paramètre runtime | Valeur brute |
|---|---:|
| Âge affiché | 13 |
| Santé | 122 |
| Réservoir de chakra | 120 |
| Paramètre ChakraRegen | 8.4 |
| Speed de base | 20.5 |
| Coefficient SprintScale | 1.14 |
| JumpScale / AirControlScale | 1.1 / 1.15 |
| AccelerationScale | 1.18 |
| Distance préférée configurée | 7 |

Sources : [définition](../../src/Shared/Wave2.luau), [mouvement](../../src/Server/Motor.luau), [régénération](../../src/Server/Combat.luau). Speed est une base en studs/s, pas une vitesse native mesurée ; le sprint dépend du profil de mouvement et des états, **pas simplement Speed×SprintScale**. Regen est également modulée en combat. Ne pas retuner ces nombres sur la seule lecture de la fiche.

**Habiletés cibles relatives (1–5, proposition de design, aucun multiplicateur runtime ni score officiel) :** Taijutsu 5/5, Ninjutsu 4/5, Genjutsu 4/5, Contrôle 5/5, Outils/armes 4/5, Endurance 3/5. Les axes désignent des spécialisations, pas un total de puissance à maximiser ; Lee1 en ninjutsu ne signifie pas absence de chakra.

## 5. Moveset et défense — cible à confronter au kit

**Chaîne légère représentative :** Coupe courte/paume d’entrée → angle de flanc → frappe de déséquilibre ; les appuis trompent avant le jutsu, pas la même chaîne de boxe.

**Routes :** Haut : launcher court ; bas : coupe basse de désengagement ; côté : FlickerStep avec feinte d’angle ; lourd : FlickerCut. Départ direction+Light avant hit reste Light1.

**Garde, parade, esquive/substitution et reprise :** Esquive et lecture Sharingan ; un mirage peut attirer une réponse mais n’absorbe pas indéfiniment les attaques et ne garantit pas une contre-attaque. La substitution garde coût, charges, fenêtre et destination autorisés du système commun ; aucun échappatoire gratuit implicite.

**Outils :** Tantō/kunai/shuriken avec rôle court ; feu force la réaction à distance, genjutsu ouvre une lecture au lieu de remplacer tout le combat.

**Routes réellement déclarées :** airDown=`AirSpike`, airSide=`AirSwitch`, airUp=`AirDrive`, down=`Sweep`, side=`FlickerStep`, up=`Launcher` ; lourd après un hit : `FlickerCut`. [MoveGraphs](../../src/Shared/MoveGraphs.luau). Ces noms ne prouvent pas les animations ni les contacts. Invariant : avant premier hit confirmé, direction+Light ne déclenche aucune route spéciale.

## 6. Techniques présentes et admissibilité de période

Snapshot du kit actuel ; temps = **channel / active / recovery**, en secondes. Coûts/cooldowns/portées sont configurés, pas validés par cette documentation. REVIEW_REQUIRED signifie provenance/période non établie ici ; ne pas désactiver la technique sur ce seul label.

| Technique / fonction actuelle | Coût | C/A/R | CD | Portée | Statut de période |
|---|---:|---|---:|---:|---|
| `BodyFlicker` — Body Flicker : Gone and at his flank in a blink • a cut on arrival • cheap: chain it | 10 | 0.06/0.03/0.16 | 1.8 | 34 | REVIEW_REQUIRED (technique et âge exact) |
| `FlickerOut` — Afterimage Retreat : Out of reach in a blink • an afterimage takes the blow | 8 | 0.04/0.03/0.12 | 3 | 13 | REVIEW_REQUIRED (technique et âge exact) |
| `ShisuiFireball` — Fire Release: Great Fireball : A great fireball • throws the body back | 22 | 0.42/0.12/0.34 | 6 | 40 | REVIEW_REQUIRED (technique et âge exact) |
| `ShisuiGenjutsu` — Genjutsu: Sharingan : Eye contact up close: the opponent's jutsu sealed 2.5 s, his legs heavy | 18 | 0.12/0.1/0.3 | 10 | 7 | REVIEW_REQUIRED (technique et âge exact) |

**Capacités possibles / limites :** les variantes de mouvement, routes et chakra décrites ici sont des **GAMEPLAY_LIBERTY proposées** lorsqu’aucune source de période ne les atteste ; une possibilité n’est pas un bouton supplémentaire à implémenter. Préférer faire mieux fonctionner une interaction existante avant d’ajouter un jutsu.

## 7. Éveil, boucles et habileté du joueur

**Éveil actuellement nommé :** `SHUNSHIN NO SHISUI`. **Cible/contrat :** ChainTeleport est déjà réel (4casts/4hits/3refreshs vus en Studio). Il n’implémente pas à lui seul la fantasy de mirages : conserver la chaîne, compléter mouvement/perception quand la passe est autorisée.

**Boucle agressive :** approche propre au personnage → ouverture/hit confirmé → route utile → choix outil/jutsu ou sortie ; priorité : Demande utilisateur : des mirages et déplacements particuliers. Candidat concret : après-images non autonomes qui prolongent brièvement le trajet/feinte ; seule la position réelle porte le hit. Coût, durée et nombre restent à régler, pas des clones Naruto avec dégâts.

**Boucle défensive/faible chakra :** Esquive et lecture Sharingan ; un mirage peut attirer une réponse mais n’absorbe pas indéfiniment les attaques et ne garantit pas une contre-attaque. Réserve moyenne, contrôle et dépense de burst élevés ; budget des feintes/angles plutôt que chakra infini. À sec : déplacement corporel rapide, aucun mirage offensif gratuit.

**Plafond de maîtrise du joueur :** Débutant : coupe et sortie. Intermédiaire : feinte d’angle. Expert : faire répondre à une trace puis frapper depuis un vrai angle choisi.

**Hors kit / incohérences de période à résoudre :** Kotoamatsukami, Susanoo et variantes jeux/OVA hors scopeV1 ; pas les déclarer tous adultes par erreur. Après-images anime = support séparé à confirmer, pas canon manga automatique.

## 8. Acceptation Studio et sources

**Scénario distinctif :** Comparer Shisui/Minato/Lee sans jutsu et mêmes couleurs désactivées ; mirage suit un trajet puis disparaît, aucun hit depuis un faux corps ; garde/whiff ne rendent pas sa chaîne.

Puis jouer en continu :20s sans jutsu pour reconnaître silhouette/déplacements/contacts ; séquence garde/whiff/hit ; faible chakra puis éveil ; KO/reset. Ne pas replacer les acteurs entre tous les coups et ne pas annoncer un PASS sur un simple spawn. Comparer au fighter le plus proche et garder une faiblesse perceptible. Preuves datées par build dans CURRENT_STATE/rapports, pas badge inventé dans cette fiche.

[Source secondaire Shisui](https://naruto.fandom.com/wiki/Shisui_Uchiha) — distingue après-images anime et variantes jeux ; référence primaire/âge à confirmer.
