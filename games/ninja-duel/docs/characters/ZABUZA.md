# Zabuza Momochi — fiche de référence

ID runtime **`Mist`** · version documentaire du **18/10/2026** · données lues au HEAD **`1cabd7f`** (runtime `bc7faa3`). [Index/comparaison](ROSTER_20.md) · [contrat commun](FIGHTER_TEMPLATE.md).

**Portée :** intention utilisateur et méthode dans [DEC-025](../active/DECISIONS.md#dec-025--fiches-personnages-et-identité-perceptible). Cette fiche propose la cible détaillée ; elle n’annonce ni validation lore complète, ni implémentation, ni autorisation de nouvelle passe. Priorités/acceptation : [MASTER_BACKLOG](../active/MASTER_BACKLOG.md). État global : [CURRENT_STATE](../active/CURRENT_STATE.md).

## 1. Version et promesse

Épéiste jeune, âge14 runtime ; possession/maîtrise du couperet et des techniques exactes à cet âge = REVIEW_REQUIRED.

**Signature irremplaçable :** Masquer la lecture de sa position puis engager une coupe lourde depuis un angle préparé.

**Faiblesse/contre-jeu :** Whiff de lame, sortie de brume, punition des longues récupérations ; brume n’efface pas la défense adverse.

## 2. Tenue, silhouette et mouvement — cible

**Vêtements/armes visibles :** Tenue de mission de Kiri sobre, bouche bandée, cheveux courts noirs, grands avant-bras et couperet ; silhouette d’épéiste, pas cape de déserteur adulte imposée.

**Course, sprint, strafe, dash et esquive :** Course engagée au poids de la lame, freinages plus longs ; pivots qui déplacent le couperet ; SilentKilling sous condition, distinct d’un dash corporel.

**Air, poursuite, réception et mur :** Air : CleaverDive engagé ; mur : compression d’angle et rejet, pas pirouettes légères de Temari malgré clips hérités. Une réception ramène à des appuis stables ; la caméra ne doit pas masquer la source d’un coup.

## 3. Chakra — distinguer nature, contrôle et quantité

**Nature/capacité particulière proposée :** Suiton pour brume/prison ; le couperet et le meurtre silencieux sont des capacités physiques/tactiques. Brume n’est pas un genjutsu générique.

**Réserve, efficacité et faible chakra :** Réserve moyenne ; choix entre maintenir avantage de brume et payer l’engagement. À sec : arme lourde et marche de pression, pas disparition répétée.

**Interaction concrète à rendre perceptible :** Couperet et outil secondaire ordinaire ; il ne doit pas laisser l’arme au dos pendant que sa hitbox frappe.

Le profil d’infusion actuel est **`Basic`**, d’après [ChakraTuning](../../src/Server/ChakraTuning.luau). Ce nom décrit l’interpréteur actuel, pas toutes ses capacités ni une maîtrise acquise par le joueur. Un fallback Basic n’annule pas ses jutsus ; il signale l’absence de spécialisation explicite dans ce mapping.

## 4. Repères du build actuel — pas des stats canon

| Paramètre runtime | Valeur brute |
|---|---:|
| Âge affiché | 14 |
| Santé | 150 |
| Réservoir de chakra | 110 |
| Paramètre ChakraRegen | 7 |
| Speed de base | 18.5 |
| Coefficient SprintScale | 1.1 |
| JumpScale / AirControlScale | 1 / 0.95 |
| AccelerationScale | 0.98 |
| Distance préférée configurée | 6.5 |

Sources : [définition](../../src/Shared/Wave1.luau), [mouvement](../../src/Server/Motor.luau), [régénération](../../src/Server/Combat.luau). Speed est une base en studs/s, pas une vitesse native mesurée ; le sprint dépend du profil de mouvement et des états, **pas simplement Speed×SprintScale**. Regen est également modulée en combat. Ne pas retuner ces nombres sur la seule lecture de la fiche.

**Habiletés cibles relatives (1–5, proposition de design, aucun multiplicateur runtime ni score officiel) :** Taijutsu 4/5, Ninjutsu 4/5, Genjutsu 1/5, Contrôle 3/5, Outils/armes 4/5, Endurance 4/5. Les axes désignent des spécialisations, pas un total de puissance à maximiser ; Lee1 en ninjutsu ne signifie pas absence de chakra.

## 5. Moveset et défense — cible à confronter au kit

**Chaîne légère représentative :** Talon/manche de placement → coupe horizontale → taille lourde de sortie ; arme tenue à la source du contact.

**Routes :** Haut : CleaverRise ; bas : CleaverDrop ; côté : CleaverArc ; lourd après un hit = CleaverHilt. Allonge et récupération donnent sa cadence.

**Garde, parade, esquive/substitution et reprise :** Garde au couperet et perte de lecture adverse dans brume ; préserver le contre-jeu manuel et restaurer correctement lock/visée à la sortie. La substitution garde coût, charges, fenêtre et destination autorisés du système commun ; aucun échappatoire gratuit implicite.

**Outils :** Couperet et outil secondaire ordinaire ; il ne doit pas laisser l’arme au dos pendant que sa hitbox frappe.

**Routes réellement déclarées :** airDown=`CleaverDive`, airUp=`AirDrive`, down=`CleaverDrop`, side=`CleaverArc`, up=`CleaverRise` ; lourd après un hit : `CleaverHilt`. [MoveGraphs](../../src/Shared/MoveGraphs.luau). Ces noms ne prouvent pas les animations ni les contacts. Invariant : avant premier hit confirmé, direction+Light ne déclenche aucune route spéciale.

## 6. Techniques présentes et admissibilité de période

Snapshot du kit actuel ; temps = **channel / active / recovery**, en secondes. Coûts/cooldowns/portées sont configurés, pas validés par cette documentation. REVIEW_REQUIRED signifie provenance/période non établie ici ; ne pas désactiver la technique sur ce seul label.

| Technique / fonction actuelle | Coût | C/A/R | CD | Portée | Statut de période |
|---|---:|---|---:|---:|---|
| `HiddenMist` — Hidden Mist : A thick mist round him • inside it the opponent loses sight of him (he fades to a shadow, no lock) • the Silent Killing strikes far harder there | 20 | 0.4/0.2/0.3 | 14 | 16 | REVIEW_REQUIRED (technique et âge exact) |
| `SilentKilling` — Silent Killing : Gone, then the cleaver from behind • far harder in his mist | 22 | 0.14/0.04/0.25 | 6 | 32 | REVIEW_REQUIRED (technique et âge exact) |
| `WaterPrison` — Water Prison : Short range: a sphere of water holds the body • then it bursts | 24 | 0.3/0.06/0.3 | 10 | 16 | REVIEW_REQUIRED (technique et âge exact) |

**Capacités possibles / limites :** les variantes de mouvement, routes et chakra décrites ici sont des **GAMEPLAY_LIBERTY proposées** lorsqu’aucune source de période ne les atteste ; une possibilité n’est pas un bouton supplémentaire à implémenter. Préférer faire mieux fonctionner une interaction existante avant d’ajouter un jutsu.

## 7. Éveil, boucles et habileté du joueur

**Éveil actuellement nommé :** `DEMON OF THE MIST`. **Cible/contrat :** DemonOfMist/Heavy existant : une pression lourde mieux incarnée, sans immunité complète aux contrôles.

**Boucle agressive :** approche propre au personnage → ouverture/hit confirmé → route utile → choix outil/jutsu ou sortie ; priorité : Masquer la lecture de sa position puis engager une coupe lourde depuis un angle préparé.

**Boucle défensive/faible chakra :** Garde au couperet et perte de lecture adverse dans brume ; préserver le contre-jeu manuel et restaurer correctement lock/visée à la sortie. Réserve moyenne ; choix entre maintenir avantage de brume et payer l’engagement. À sec : arme lourde et marche de pression, pas disparition répétée.

**Plafond de maîtrise du joueur :** Débutant : allonge. Intermédiaire : brume→angle. Expert : retarder une coupe et punir l’orientation adverse.

**Hors kit / incohérences de période à résoudre :** Arsenal Suiton adulte géant, invisibilité absolue, téléport à travers murs ; techniques à14 non certifiées par l’apparence.

## 8. Acceptation Studio et sources

**Scénario distinctif :** Dans/hors brume, vérifier caméra/aim ; garder puis faire whiff une coupe ; lame/main/contact et recovery doivent coïncider.

Puis jouer en continu :20s sans jutsu pour reconnaître silhouette/déplacements/contacts ; séquence garde/whiff/hit ; faible chakra puis éveil ; KO/reset. Ne pas replacer les acteurs entre tous les coups et ne pas annoncer un PASS sur un simple spawn. Comparer au fighter le plus proche et garder une faiblesse perceptible. Preuves datées par build dans CURRENT_STATE/rapports, pas badge inventé dans cette fiche.

Provenance du stade et de chaque technique jeune encore à compléter par chapitre/épisode/source primaire ; le runtime et les choix de design ne valent pas preuve canon.
