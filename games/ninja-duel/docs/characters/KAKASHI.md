# Kakashi Hatake — fiche de référence

ID runtime **`Copycat`** · version documentaire du **18/10/2026** · données lues au HEAD **`1cabd7f`** (runtime `bc7faa3`). [Index/comparaison](ROSTER_20.md) · [contrat commun](FIGHTER_TEMPLATE.md).

**Portée :** intention utilisateur et méthode dans [DEC-025](../active/DECISIONS.md#dec-025--fiches-personnages-et-identité-perceptible). Cette fiche propose la cible détaillée ; elle n’annonce ni validation lore complète, ni implémentation, ni autorisation de nouvelle passe. Priorités/acceptation : [MASTER_BACKLOG](../active/MASTER_BACKLOG.md). État global : [CURRENT_STATE](../active/CURRENT_STATE.md).

## 1. Version et promesse

Kakashi jeune avec Sharingan ; âge14 runtime. Ancienne fiche Kannabi≈13 et code14 diffèrent : sélectionner une période cohérente avant d’étendre les capacités.

**Signature irremplaçable :** Lire et préparer une seule réponse adaptée, puis engager sa réserve dans une punition précise.

**Faiblesse/contre-jeu :** Coût de l’œil, engagement du Chidori et pression prolongée ; pas spécialiste supérieur aux autres dans chaque domaine.

## 2. Tenue, silhouette et mouvement — cible

**Vêtements/armes visibles :** Tenue jeune de mission bleu sombre, masque facial, cheveux argentés, un œil couvert par bandeau ; tantō seulement si stade/modèle validés, pas accessoire adulte automatique.

**Course, sprint, strafe, dash et esquive :** Déplacements courts tactiques, appuis bas, orientation d’outil ; différence nette entre course libre et engagement du Chidori.

**Air, poursuite, réception et mur :** Air : contre/outil précis ; mur : relais d’angle éventuel, pas liste entière d’éléments copiés. Une réception ramène à des appuis stables ; la caméra ne doit pas masquer la source d’un coup.

## 3. Chakra — distinguer nature, contrôle et quantité

**Nature/capacité particulière proposée :** Raiton pour Chidori ; Eau du WaterDragon existant demande validation de période. Sharingan = perception/copie, pas une nature ; ne pas confondre arsenal adulte et aptitude à copier.

**Réserve, efficacité et faible chakra :** Réserve moyenne et dépense du Sharingan transplanté à rendre significative ; contrôle élevé mais coût de lecture réel. À sec : kunai/taijutsu, ne pas garder toutes les aides gratuitement.

**Interaction concrète à rendre perceptible :** Kunai principal ; ninken et WaterDragon déjà présents restent en review de stade. Copie libre de tous les pouvoirs exclue.

Le profil d’infusion actuel est **`Basic`**, d’après [ChakraTuning](../../src/Server/ChakraTuning.luau). Ce nom décrit l’interpréteur actuel, pas toutes ses capacités ni une maîtrise acquise par le joueur. Un fallback Basic n’annule pas ses jutsus ; il signale l’absence de spécialisation explicite dans ce mapping.

## 4. Repères du build actuel — pas des stats canon

| Paramètre runtime | Valeur brute |
|---|---:|
| Âge affiché | 14 |
| Santé | 135 |
| Réservoir de chakra | 120 |
| Paramètre ChakraRegen | 7.6 |
| Speed de base | 19 |
| Coefficient SprintScale | 1.08 |
| JumpScale / AirControlScale | 1.05 / 1.05 |
| AccelerationScale | 1.06 |
| Distance préférée configurée | 7 |

Sources : [définition](../../src/Shared/Fighters.luau), [mouvement](../../src/Server/Motor.luau), [régénération](../../src/Server/Combat.luau). Speed est une base en studs/s, pas une vitesse native mesurée ; le sprint dépend du profil de mouvement et des états, **pas simplement Speed×SprintScale**. Regen est également modulée en combat. Ne pas retuner ces nombres sur la seule lecture de la fiche.

**Habiletés cibles relatives (1–5, proposition de design, aucun multiplicateur runtime ni score officiel) :** Taijutsu 4/5, Ninjutsu 4/5, Genjutsu 3/5, Contrôle 4/5, Outils/armes 4/5, Endurance 3/5. Les axes désignent des spécialisations, pas un total de puissance à maximiser ; Lee1 en ninjutsu ne signifie pas absence de chakra.

## 5. Moveset et défense — cible à confronter au kit

**Chaîne légère représentative :** Contrôle au kunai/main → coup de pied court → sortie d’angle ; si tantō retenu, sa portée change réellement le geste.

**Routes :** Haut : launcher technique ; bas : balayage de sortie ; côté : feinte/lecture ; lourd après hit ne doit pas rester un KneeStrike générique sans intention.

**Garde, parade, esquive/substitution et reprise :** Sharingan et déviation au timing, décision de couvrir/découvrir comme candidat ; défaut de tunnel du Chidori à représenter si période Gaiden retenue. La substitution garde coût, charges, fenêtre et destination autorisés du système commun ; aucun échappatoire gratuit implicite.

**Outils :** Kunai principal ; ninken et WaterDragon déjà présents restent en review de stade. Copie libre de tous les pouvoirs exclue.

**Routes réellement déclarées :** airDown=`AirSpike`, airSide=`AirSwitch`, airUp=`AirDrive`, down=`Sweep`, side=`FeintStep`, up=`Launcher` ; lourd après un hit : `KneeStrike`. [MoveGraphs](../../src/Shared/MoveGraphs.luau). Ces noms ne prouvent pas les animations ni les contacts. Invariant : avant premier hit confirmé, direction+Light ne déclenche aucune route spéciale.

## 6. Techniques présentes et admissibilité de période

Snapshot du kit actuel ; temps = **channel / active / recovery**, en secondes. Coûts/cooldowns/portées sont configurés, pas validés par cette documentation. REVIEW_REQUIRED signifie provenance/période non établie ici ; ne pas désactiver la technique sur ce seul label.

| Technique / fonction actuelle | Coût | C/A/R | CD | Portée | Statut de période |
|---|---:|---|---:|---:|---|
| `LightningBlade` — Lightning Blade : Charge, then a lightning thrust • a miss leaves him open | 32 | 0.5/0.05/0.12 | 9 | 20 | REVIEW_REQUIRED (technique et âge exact) |
| `TrackingFang` — Summoning: Tracking Fang : His hounds burst from the ground and hold the body • then the blade | 22 | 0.3/0.08/0.3 | 8 | 30 | REVIEW_REQUIRED (technique et âge exact) |
| `WaterDragon` — Water Dragon : A copied dragon of water that throws the body far | 28 | 0.55/0.3/0.36 | 7 | 52 | REVIEW_REQUIRED (technique et âge exact) |

**Capacités possibles / limites :** les variantes de mouvement, routes et chakra décrites ici sont des **GAMEPLAY_LIBERTY proposées** lorsqu’aucune source de période ne les atteste ; une possibilité n’est pas un bouton supplémentaire à implémenter. Préférer faire mieux fonctionner une interaction existante avant d’ajouter un jutsu.

## 7. Éveil, boucles et habileté du joueur

**Éveil actuellement nommé :** `SHARINGAN UNCOVERED`. **Cible/contrat :** SharinganUncovered existant : lecture visible et coût cohérent ; la copie à liste blanche de l’ancienne fiche reste candidate, non promise comme déjà codée.

**Boucle agressive :** approche propre au personnage → ouverture/hit confirmé → route utile → choix outil/jutsu ou sortie ; priorité : Lire et préparer une seule réponse adaptée, puis engager sa réserve dans une punition précise.

**Boucle défensive/faible chakra :** Sharingan et déviation au timing, décision de couvrir/découvrir comme candidat ; défaut de tunnel du Chidori à représenter si période Gaiden retenue. Réserve moyenne et dépense du Sharingan transplanté à rendre significative ; contrôle élevé mais coût de lecture réel. À sec : kunai/taijutsu, ne pas garder toutes les aides gratuitement.

**Plafond de maîtrise du joueur :** Débutant : outil→punition. Intermédiaire : lire l’attaque. Expert : choisir la bonne réponse en gardant de la réserve.

**Hors kit / incohérences de période à résoudre :** Kamui/Susanoo/arsenal adulte ; TrackingFang/WaterDragon à14 et appellation Raikiri : REVIEW_REQUIRED. Pas réécriture automatique vers Kannabi.

## 8. Acceptation Studio et sources

**Scénario distinctif :** Chidori raté punissable ; œil visible/masqué et coût compréhensibles ; distinguer ses décisions de celles de Sasuke.

Puis jouer en continu :20s sans jutsu pour reconnaître silhouette/déplacements/contacts ; séquence garde/whiff/hit ; faible chakra puis éveil ; KO/reset. Ne pas replacer les acteurs entre tous les coups et ne pas annoncer un PASS sur un simple spawn. Comparer au fighter le plus proche et garder une faiblesse perceptible. Preuves datées par build dans CURRENT_STATE/rapports, pas badge inventé dans cette fiche.

[Source officielle Kakashi Gaiden](https://naruto-official.com/de/anime/naruto2/list/01_564) ; vérifier les capacités une par une.

[Ancienne fiche conservée](../archive/characters/2026-10-18-before-profiles/KAKASHI.md) : détails historiques et candidats non repris sans validation. Les anciens noms/valeurs/plans ne remplacent pas cette séparation cible/existant.
