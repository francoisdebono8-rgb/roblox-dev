# Itachi Uchiha — fiche de référence

ID runtime **`Mirage`** · version documentaire du **18/10/2026** · données lues au HEAD **`1cabd7f`** (runtime `bc7faa3`). [Index/comparaison](ROSTER_20.md) · [contrat commun](FIGHTER_TEMPLATE.md).

**Portée :** intention utilisateur et méthode dans [DEC-025](../active/DECISIONS.md#dec-025--fiches-personnages-et-identité-perceptible). Cette fiche propose la cible détaillée ; elle n’annonce ni validation lore complète, ni implémentation, ni autorisation de nouvelle passe. Priorités/acceptation : [MASTER_BACKLOG](../active/MASTER_BACKLOG.md). État global : [CURRENT_STATE](../active/CURRENT_STATE.md).

## 1. Version et promesse

Itachi jeune/prodige ; âge13 runtime. La fiche historique proposait12 : conflit conservé, pas changement d’âge silencieux.

**Signature irremplaçable :** Faire agir l’autre puis frapper sa réponse, à travers lecture et géométrie de projectiles.

**Faiblesse/contre-jeu :** Corps à corps prolongé et erreurs de lecture ; illusion lisible/contrable et budget limité.

## 2. Tenue, silhouette et mouvement — cible

**Vêtements/armes visibles :** Tenue Uchiha bleu très sombre, col haut, emblème clan discret, bandeau ; posture calme et shuriken à portée de main. Tenue de mission jeune, sans cape Akatsuki.

**Course, sprint, strafe, dash et esquive :** Petits pas glissés mais pieds plantés, changements d’angle mesurés ; esquive courte qui laisse éventuellement une image trompeuse, distincte d’un FTG de Minato.

**Air, poursuite, réception et mur :** Air : volées contrôlées et sortie ; mur : ricochet de shuriken et angle de retour, pas avantage aérien permanent. Une réception ramène à des appuis stables ; la caméra ne doit pas masquer la source d’un coup.

## 3. Chakra — distinguer nature, contrôle et quantité

**Nature/capacité particulière proposée :** Katon pour les techniques de feu ; genjutsu/Sharingan = manipulation/perception, pas une variante de feu. Les autres natures ne sont pas requises pour ce kit jeune.

**Réserve, efficacité et faible chakra :** Réserve moyenne, précision et efficacité élevées ; le regard, les feintes et la géométrie offrent des choix plutôt que du spam. À sec : shuriken, angles et punition de whiff.

**Interaction concrète à rendre perceptible :** Shuriken, trajectoires retardées/ricochets et outils cachés ; origine et collision visibles ; les tirs de feu doivent changer l’espace.

Le profil d’infusion actuel est **`FireBlade`**, d’après [ChakraTuning](../../src/Server/ChakraTuning.luau). Ce nom décrit l’interpréteur actuel, pas toutes ses capacités ni une maîtrise acquise par le joueur. Un fallback Basic n’annule pas ses jutsus ; il signale l’absence de spécialisation explicite dans ce mapping.

## 4. Repères du build actuel — pas des stats canon

| Paramètre runtime | Valeur brute |
|---|---:|
| Âge affiché | 13 |
| Santé | 145 |
| Réservoir de chakra | 125 |
| Paramètre ChakraRegen | 7.2 |
| Speed de base | 18 |
| Coefficient SprintScale | 1 |
| JumpScale / AirControlScale | 0.98 / 0.95 |
| AccelerationScale | 0.98 |
| Distance préférée configurée | 10 |

Sources : [définition](../../src/Shared/Fighters.luau), [mouvement](../../src/Server/Motor.luau), [régénération](../../src/Server/Combat.luau). Speed est une base en studs/s, pas une vitesse native mesurée ; le sprint dépend du profil de mouvement et des états, **pas simplement Speed×SprintScale**. Regen est également modulée en combat. Ne pas retuner ces nombres sur la seule lecture de la fiche.

**Habiletés cibles relatives (1–5, proposition de design, aucun multiplicateur runtime ni score officiel) :** Taijutsu 4/5, Ninjutsu 4/5, Genjutsu 5/5, Contrôle 5/5, Outils/armes 5/5, Endurance 3/5. Les axes désignent des spécialisations, pas un total de puissance à maximiser ; Lee1 en ninjutsu ne signifie pas absence de chakra.

## 5. Moveset et défense — cible à confronter au kit

**Chaîne légère représentative :** Déviation de main → frappe courte au corps → recul/pivot ; un geste minimal prépare l’outil plutôt qu’un long tourbillon.

**Routes :** Haut : launcher après ouverture ; bas : balayage de punition ; côté : feinte qui invite une réponse. Read et contre exigent une lecture, pas une attaque automatique.

**Garde, parade, esquive/substitution et reprise :** Lecture, déviation, esquive parfaite et contre court ; erreur de lecture exposée. Un genjutsu laisse une information exploitable, pas un stun inévitable. La substitution garde coût, charges, fenêtre et destination autorisés du système commun ; aucun échappatoire gratuit implicite.

**Outils :** Shuriken, trajectoires retardées/ricochets et outils cachés ; origine et collision visibles ; les tirs de feu doivent changer l’espace.

**Routes réellement déclarées :** airDown=`AirSpike`, airSide=`AirSwitch`, airUp=`AirDrive`, down=`Sweep`, side=`FeintStep`, up=`Launcher` ; lourd après un hit : `CounterPalm`. [MoveGraphs](../../src/Shared/MoveGraphs.luau). Ces noms ne prouvent pas les animations ni les contacts. Invariant : avant premier hit confirmé, direction+Light ne déclenche aucune route spéciale.

## 6. Techniques présentes et admissibilité de période

Snapshot du kit actuel ; temps = **channel / active / recovery**, en secondes. Coûts/cooldowns/portées sont configurés, pas validés par cette documentation. REVIEW_REQUIRED signifie provenance/période non établie ici ; ne pas désactiver la technique sur ce seul label.

| Technique / fonction actuelle | Coût | C/A/R | CD | Portée | Statut de période |
|---|---:|---|---:|---:|---|
| `Read` — Sharingan Read : Read one frontal strike: he slips aside, it bites the afterimage • strike in the stance = instant counter | 14 | 0.1/1/0.2 | 3.6 | 10 | REVIEW_REQUIRED (technique et âge exact) |
| `NeedleFan` — Shadow Shuriken : Five blades, then two hidden ones aimed at the dodge | 18 | 0.26/0.08/0.26 | 3.6 | 56 | REVIEW_REQUIRED (technique et âge exact) |
| `MirageCast` — Genjutsu: Mirage : His image stays, he withdraws behind it • a swing at the image is caught • trust the body | 26 | 0.42/0.06/0.2 | 7 | 23 | REVIEW_REQUIRED (technique et âge exact) |
| `FireBloom` — Great Fireball : Where it passes him the ground burns: a lane that cuts his path | 26 | 0.55/0.42/0.36 | 5.5 | 76 | REVIEW_REQUIRED (technique et âge exact) |
| `PhoenixFlower` — Phoenix Flower : Five small flames fanned at the opponent • pressure | 20 | 0.3/0.32/0.3 | 5 | 60 | REVIEW_REQUIRED (technique et âge exact) |

**Capacités possibles / limites :** les variantes de mouvement, routes et chakra décrites ici sont des **GAMEPLAY_LIBERTY proposées** lorsqu’aucune source de période ne les atteste ; une possibilité n’est pas un bouton supplémentaire à implémenter. Préférer faire mieux fonctionner une interaction existante avant d’ajouter un jutsu.

## 7. Éveil, boucles et habileté du joueur

**Éveil actuellement nommé :** `SHARINGAN FOCUS`. **Cible/contrat :** GuardRead/WhiffRead/Windows existants : avantage de lecture perceptible, pas bouton de défense absolue.

**Boucle agressive :** approche propre au personnage → ouverture/hit confirmé → route utile → choix outil/jutsu ou sortie ; priorité : Faire agir l’autre puis frapper sa réponse, à travers lecture et géométrie de projectiles.

**Boucle défensive/faible chakra :** Lecture, déviation, esquive parfaite et contre court ; erreur de lecture exposée. Un genjutsu laisse une information exploitable, pas un stun inévitable. Réserve moyenne, précision et efficacité élevées ; le regard, les feintes et la géométrie offrent des choix plutôt que du spam. À sec : shuriken, angles et punition de whiff.

**Plafond de maîtrise du joueur :** Débutant : Read au bon moment. Intermédiaire : feinte→shuriken. Expert : ricochet/retard et lecture du choix adverse.

**Hors kit / incohérences de période à résoudre :** Susanoo/Amaterasu/Tsukuyomi non requis pour V1 ; leur disponibilité jeune n’est pas résolue par la seule étiquette13. Ne pas importer son kit adulte.

## 8. Acceptation Studio et sources

**Scénario distinctif :** Duel sans feu : le reconnaître par retrait/lecture/outils ; montrer un Read baité puis puni ; un ricochet atteint le flanc, une trajectoire anticipée est esquivable.

Puis jouer en continu :20s sans jutsu pour reconnaître silhouette/déplacements/contacts ; séquence garde/whiff/hit ; faible chakra puis éveil ; KO/reset. Ne pas replacer les acteurs entre tous les coups et ne pas annoncer un PASS sur un simple spawn. Comparer au fighter le plus proche et garder une faiblesse perceptible. Preuves datées par build dans CURRENT_STATE/rapports, pas badge inventé dans cette fiche.

Provenance du stade et de chaque technique jeune encore à compléter par chapitre/épisode/source primaire ; le runtime et les choix de design ne valent pas preuve canon.

[Ancienne fiche conservée](../archive/characters/2026-10-18-before-profiles/ITACHI.md) : détails historiques et candidats non repris sans validation. Les anciens noms/valeurs/plans ne remplacent pas cette séparation cible/existant.
