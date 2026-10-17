# Kimimaro Kaguya — fiche de référence

ID runtime **`Bone`** · version documentaire du **18/10/2026** · données lues au HEAD **`1cabd7f`** (runtime `bc7faa3`). [Index/comparaison](ROSTER_20.md) · [contrat commun](FIGHTER_TEMPLATE.md).

**Portée :** intention utilisateur et méthode dans [DEC-025](../active/DECISIONS.md#dec-025--fiches-personnages-et-identité-perceptible). Cette fiche propose la cible détaillée ; elle n’annonce ni validation lore complète, ni implémentation, ni autorisation de nouvelle passe. Priorités/acceptation : [MASTER_BACKLOG](../active/MASTER_BACKLOG.md). État global : [CURRENT_STATE](../active/CURRENT_STATE.md).

## 1. Version et promesse

Prodige Kaguya ; âge13 runtime alors que sa période de combat connue est fréquemment donnée15 : REVIEW_REQUIRED, pas correction d’âge silencieuse.

**Signature irremplaçable :** Entrer en danse d’os, choisir toucher précis ou trade défensif puis sortir de pression.

**Faiblesse/contre-jeu :** Portée relative, timing des buffs et punition des engagements ; adversaire doit voir quand l’armure change.

## 2. Tenue, silhouette et mouvement — cible

**Vêtements/armes visibles :** Tunique claire, ceinture violette, pantalon sombre, cheveux blancs séparés et marques rouges ; os émergeant du corps sous geste cohérent.

**Course, sprint, strafe, dash et esquive :** Déplacements fluides proches, pivots sans lourde inertie ; esquive par angle autour d’une lame d’os ; pas apparition instantanée générique.

**Air, poursuite, réception et mur :** Air : percer puis atterrir proprement ; mur : angle court/anti-poursuite, pas forêt d’os mondiale. Une réception ramène à des appuis stables ; la caméra ne doit pas masquer la source d’un coup.

## 3. Chakra — distinguer nature, contrôle et quantité

**Nature/capacité particulière proposée :** Shikotsumyaku = capacité héréditaire corporelle, pas élément Os ni Terre. La modification du corps et la marque maudite restent distinctes.

**Réserve, efficacité et faible chakra :** Réserve moyenne, bon contrôle corporel ; arme/armure ont une fenêtre, pas un bonus permanent empilé. À sec : taijutsu compact et allonge déjà présente.

**Interaction concrète à rendre perceptible :** Os en main et petits projectiles d’os, pas kunai repeints sans pose appropriée.

Le profil d’infusion actuel est **`Basic`**, d’après [ChakraTuning](../../src/Server/ChakraTuning.luau). Ce nom décrit l’interpréteur actuel, pas toutes ses capacités ni une maîtrise acquise par le joueur. Un fallback Basic n’annule pas ses jutsus ; il signale l’absence de spécialisation explicite dans ce mapping.

## 4. Repères du build actuel — pas des stats canon

| Paramètre runtime | Valeur brute |
|---|---:|
| Âge affiché | 13 |
| Santé | 140 |
| Réservoir de chakra | 105 |
| Paramètre ChakraRegen | 7.4 |
| Speed de base | 19 |
| Coefficient SprintScale | 1.1 |
| JumpScale / AirControlScale | 1.04 / 1 |
| AccelerationScale | 1.04 |
| Distance préférée configurée | 5 |

Sources : [définition](../../src/Shared/Wave1.luau), [mouvement](../../src/Server/Motor.luau), [régénération](../../src/Server/Combat.luau). Speed est une base en studs/s, pas une vitesse native mesurée ; le sprint dépend du profil de mouvement et des états, **pas simplement Speed×SprintScale**. Regen est également modulée en combat. Ne pas retuner ces nombres sur la seule lecture de la fiche.

**Habiletés cibles relatives (1–5, proposition de design, aucun multiplicateur runtime ni score officiel) :** Taijutsu 5/5, Ninjutsu 3/5, Genjutsu 1/5, Contrôle 4/5, Outils/armes 3/5, Endurance 4/5. Les axes désignent des spécialisations, pas un total de puissance à maximiser ; Lee1 en ninjutsu ne signifie pas absence de chakra.

## 5. Moveset et défense — cible à confronter au kit

**Chaîne légère représentative :** Pique d’os → coupe courte → poussée de séparation ; différence avec Zabuza par poids faible et vitesse de main.

**Routes :** Haut : launcher d’os ; bas : balayage compact ; côté : CamelliaArc ; lourd : BoneThrust. Camellia renforce une intention d’escrime, pas toutes les statistiques sans signe.

**Garde, parade, esquive/substitution et reprise :** Armure du corps et gestion du trade ; Larch repousse au bon timing ; super-armure ne rend pas invincible. La substitution garde coût, charges, fenêtre et destination autorisés du système commun ; aucun échappatoire gratuit implicite.

**Outils :** Os en main et petits projectiles d’os, pas kunai repeints sans pose appropriée.

**Routes réellement déclarées :** airDown=`AirSpike`, airSide=`AirSwitch`, airUp=`AirDrive`, down=`Sweep`, side=`CamelliaArc`, up=`Launcher` ; lourd après un hit : `BoneThrust`. [MoveGraphs](../../src/Shared/MoveGraphs.luau). Ces noms ne prouvent pas les animations ni les contacts. Invariant : avant premier hit confirmé, direction+Light ne déclenche aucune route spéciale.

## 6. Techniques présentes et admissibilité de période

Snapshot du kit actuel ; temps = **channel / active / recovery**, en secondes. Coûts/cooldowns/portées sont configurés, pas validés par cette documentation. REVIEW_REQUIRED signifie provenance/période non établie ici ; ne pas désactiver la technique sur ce seul label.

| Technique / fonction actuelle | Coût | C/A/R | CD | Portée | Statut de période |
|---|---:|---|---:|---:|---|
| `Camellia` — Dance of the Camellia : A bone sword drawn from the palm: his blows hit harder for 8 s | 18 | 0.3/0.05/0.2 | 14 | 20 | REVIEW_REQUIRED (technique et âge exact) |
| `Larch` — Dance of the Larch : Bones burst from his whole body • blades cut down, a close attacker thrown off • the floor stays spiked | 20 | 0.1/0.25/0.32 | 8 | 6.5 | REVIEW_REQUIRED (technique et âge exact) |
| `Willow` — Dance of the Willow : A lunge of bone blades across the gap | 16 | 0.18/0.05/0.1 | 5 | 14 | REVIEW_REQUIRED (technique et âge exact) |

**Capacités possibles / limites :** les variantes de mouvement, routes et chakra décrites ici sont des **GAMEPLAY_LIBERTY proposées** lorsqu’aucune source de période ne les atteste ; une possibilité n’est pas un bouton supplémentaire à implémenter. Préférer faire mieux fonctionner une interaction existante avant d’ajouter un jutsu.

## 7. Éveil, boucles et habileté du joueur

**Éveil actuellement nommé :** `DANCE OF THE CLEMATIS`. **Cible/contrat :** Camellia et éveil composés ont été corrigés ; rendre Heavy/Armor perceptibles et nettoyer au round.

**Boucle agressive :** approche propre au personnage → ouverture/hit confirmé → route utile → choix outil/jutsu ou sortie ; priorité : Entrer en danse d’os, choisir toucher précis ou trade défensif puis sortir de pression.

**Boucle défensive/faible chakra :** Armure du corps et gestion du trade ; Larch repousse au bon timing ; super-armure ne rend pas invincible. Réserve moyenne, bon contrôle corporel ; arme/armure ont une fenêtre, pas un bonus permanent empilé. À sec : taijutsu compact et allonge déjà présente.

**Plafond de maîtrise du joueur :** Débutant : lance d’os. Intermédiaire : Camellia/trade. Expert : provoquer une pression puis Larch et conversion courte.

**Hors kit / incohérences de période à résoudre :** Guerre/Edo, forêt géante d’os ; danses nommées et marque à13 restent à sourcer.

## 8. Acceptation Studio et sources

**Scénario distinctif :** Camellia→éveil dans les deux ordres ; coup léger reçu vs gros contrôle ; low-chakra et reset sans effet résiduel.

Puis jouer en continu :20s sans jutsu pour reconnaître silhouette/déplacements/contacts ; séquence garde/whiff/hit ; faible chakra puis éveil ; KO/reset. Ne pas replacer les acteurs entre tous les coups et ne pas annoncer un PASS sur un simple spawn. Comparer au fighter le plus proche et garder une faiblesse perceptible. Preuves datées par build dans CURRENT_STATE/rapports, pas badge inventé dans cette fiche.

[Source secondaire Kimimaro](https://naruto.fandom.com/wiki/Kimimaro) — signale15, à recouper avant arbitrage de période.
