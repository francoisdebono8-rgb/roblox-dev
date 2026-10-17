> Historique remplacé par DEC-026 : ancien roster et ancienne définition de fiche, pas cible V1 à exécuter.

# Minato Namikaze — fiche de référence

ID runtime **`Flashstep`** · version documentaire du **18/10/2026** · données lues au HEAD **`1cabd7f`** (runtime `bc7faa3`). [Index/comparaison](../../../characters/ROSTER_20.md) · [contrat commun](../../../characters/FIGHTER_TEMPLATE.md).

**Portée :** intention utilisateur et méthode dans [DEC-025](../../../active/DECISIONS.md#dec-025--fiches-personnages-et-identité-perceptible). Cette fiche propose la cible détaillée ; elle n’annonce ni validation lore complète, ni implémentation, ni autorisation de nouvelle passe. Priorités/acceptation : [MASTER_BACKLOG](../../../active/MASTER_BACKLOG.md). État global : [CURRENT_STATE](../../../active/CURRENT_STATE.md).

## 1. Version et promesse

Prodige pré-Hokage ; âge13 du code conservé comme repère provisoire. FTG/Rasengan à cet âge précis non établis ici ; leur présence est une convention de kit existante, pas une preuve canon.

**Signature irremplaçable :** Préparer des destinations puis convertir un angle en attaque ; sa vitesse spatiale dépend du terrain préparé.

**Faiblesse/contre-jeu :** Préparation détruite/contournée, chakra épuisé et erreur de destination ; ne doit pas gagner tous les échanges en course pure.

## 2. Tenue, silhouette et mouvement — cible

**Vêtements/armes visibles :** Tenue de mission bleu sombre, protections légères, cheveux blonds en pointes, pochette et kunai marqués visibles ; silhouette légère, buste peu chargé.

**Course, sprint, strafe, dash et esquive :** Course directe économique ; pivot court et appuis propres ; rush corporel court. FTG uniquement vers marque valide : rupture de position explicable par destination, pas déplacement instantané universel. Éclat bref doré/pâle associé au sceau, pas aura permanente.

**Air, poursuite, réception et mur :** Poursuite par marque seulement si préparée ; air = kunai puis angle choisi ; mur = point d’ancrage visible, sortie punissable si l’adversaire couvre la marque. Une réception ramène à des appuis stables ; la caméra ne doit pas masquer la source d’un coup.

## 3. Chakra — distinguer nature, contrôle et quantité

**Nature/capacité particulière proposée :** Aucune affinité élémentaire précoce certifiée ici. FTG = ninjutsu spatio-temporel/marquage ; Rasengan = mise en forme du chakra, pas automatiquement Fûton. Le WindBlade du runtime est une liberté à arbitrer pour ce stade.

**Réserve, efficacité et faible chakra :** Réserve moyenne ; contrôle très élevé. Le prix vient des déplacements en série et de la préparation des marques, pas du simple sprint. À sec : kunai ordinaires, petites esquives et taijutsu précis ; pas de FTG gratuit.

**Interaction concrète à rendre perceptible :** Kunai standard et marqué : lire destination, surface et portée ; décider poser un réseau ou convertir un hit ; aucune téléportation sans destination.

Le profil d’infusion actuel est **`WindBlade`**, d’après [ChakraTuning](../../../../src/Server/ChakraTuning.luau). Ce nom décrit l’interpréteur actuel, pas toutes ses capacités ni une maîtrise acquise par le joueur. Un fallback Basic n’annule pas ses jutsus ; il signale l’absence de spécialisation explicite dans ce mapping.

## 4. Repères du build actuel — pas des stats canon

| Paramètre runtime | Valeur brute |
|---|---:|
| Âge affiché | 13 |
| Santé | 125 |
| Réservoir de chakra | 110 |
| Paramètre ChakraRegen | 8 |
| Speed de base | 19.5 |
| Coefficient SprintScale | 1.12 |
| JumpScale / AirControlScale | 1.1 / 1.15 |
| AccelerationScale | 1.15 |
| Distance préférée configurée | 6 |

Sources : [définition](../../../../src/Shared/Fighters.luau), [mouvement](../../../../src/Server/Motor.luau), [régénération](../../../../src/Server/Combat.luau). Speed est une base en studs/s, pas une vitesse native mesurée ; le sprint dépend du profil de mouvement et des états, **pas simplement Speed×SprintScale**. Regen est également modulée en combat. Ne pas retuner ces nombres sur la seule lecture de la fiche.

**Habiletés cibles relatives (1–5, proposition de design, aucun multiplicateur runtime ni score officiel) :** Taijutsu 4/5, Ninjutsu 4/5, Genjutsu 2/5, Contrôle 5/5, Outils/armes 5/5, Endurance 3/5. Les axes désignent des spécialisations, pas un total de puissance à maximiser ; Lee1 en ninjutsu ne signifie pas absence de chakra.

## 5. Moveset et défense — cible à confronter au kit

**Chaîne légère représentative :** Paume d’entrée → genou au buste → coup de pied qui libère une fenêtre de kunai ; corps compact, peu de rotation gratuite.

**Routes :** Haut : genou/launcher ; bas : balayage + espace pour marquer ; côté : sortie de ligne vers marque/kunai. La direction avant premier hit reste un Light1.

**Garde, parade, esquive/substitution et reprise :** Garde courte, déviation au kunai, esquive serrée ; substitution universelle puis reposition selon marque autorisée, sans invulnérabilité continue. La substitution garde coût, charges, fenêtre et destination autorisés du système commun ; aucun échappatoire gratuit implicite.

**Outils :** Kunai standard et marqué : lire destination, surface et portée ; décider poser un réseau ou convertir un hit ; aucune téléportation sans destination.

**Routes réellement déclarées :** airDown=`AirSpike`, airSide=`AirSwitch`, airUp=`AirDrive`, down=`Sweep`, side=`AngleStep`, up=`Launcher` ; lourd après un hit : `KneeStrike`. [MoveGraphs](../../../../src/Shared/MoveGraphs.luau). Ces noms ne prouvent pas les animations ni les contacts. Invariant : avant premier hit confirmé, direction+Light ne déclenche aucune route spéciale.

## 6. Techniques présentes et admissibilité de période

Snapshot du kit actuel ; temps = **channel / active / recovery**, en secondes. Coûts/cooldowns/portées sont configurés, pas validés par cette documentation. REVIEW_REQUIRED signifie provenance/période non établie ici ; ne pas désactiver la technique sur ce seul label.

| Technique / fonction actuelle | Coût | C/A/R | CD | Portée | Statut de période |
|---|---:|---|---:|---:|---|
| `MarkedBlade` — Marked Kunai : Plants a seal (two held at most) • a hit seals the body | 10 | 0.12/0.02/0 | 2.2 | 66 | REVIEW_REQUIRED (technique et âge exact) |
| `Flashstep` — Flying Thunder God : Stick picks the seal and the side • strike or 3 on arrival | 16 | 0.06/0.04/0.2 | 1.5 | 90 | REVIEW_REQUIRED (technique et âge exact) |
| `BurstStrike` — Rasengan : Instant after a teleport • plunges when airborne • ends a clean string | 24 | 0.3/0.08/0.5 | 5.5 | 8 | REVIEW_REQUIRED (technique et âge exact) |
| `Quickstep` — Quickstep : Create an angle • no guaranteed hit | 12 | 0.11/0.08/0.21 | 2.3 | 12 | REVIEW_REQUIRED (technique et âge exact) |
| `WindCut` — Wind Cut : Thrown on the run • cuts blades in its lane • a cut body is marked: 2 lands beside it | 14 | 0.16/0.02/0 | 3.2 | 40 | REVIEW_REQUIRED (technique et âge exact) |

**Capacités possibles / limites :** les variantes de mouvement, routes et chakra décrites ici sont des **GAMEPLAY_LIBERTY proposées** lorsqu’aucune source de période ne les atteste ; une possibilité n’est pas un bouton supplémentaire à implémenter. Préférer faire mieux fonctionner une interaction existante avant d’ajouter un jutsu.

## 7. Éveil, boucles et habileté du joueur

**Éveil actuellement nommé :** `YELLOW FLASH`. **Cible/contrat :** Conserver FlashWake/FlashPursuit et arrivée contextualisée ; montrer la destination et la fenêtre de punition, aucune simple multiplication de flashs.

**Boucle agressive :** approche propre au personnage → ouverture/hit confirmé → route utile → choix outil/jutsu ou sortie ; priorité : Préparer des destinations puis convertir un angle en attaque ; sa vitesse spatiale dépend du terrain préparé.

**Boucle défensive/faible chakra :** Garde courte, déviation au kunai, esquive serrée ; substitution universelle puis reposition selon marque autorisée, sans invulnérabilité continue. Réserve moyenne ; contrôle très élevé. Le prix vient des déplacements en série et de la préparation des marques, pas du simple sprint. À sec : kunai ordinaires, petites esquives et taijutsu précis ; pas de FTG gratuit.

**Plafond de maîtrise du joueur :** Débutant : marque→attaque. Intermédiaire : deux destinations et sortie. Expert : choisir timing, côté d’arrivée et conditionner les déplacements adverses.

**Hors kit / incohérences de période à résoudre :** Manteau de Hokage, Kurama/KCM, mode ermite, pouvoirs de guerre. WindCut précoce et Rasengan/FTG à13 : REVIEW_REQUIRED, pas suppression automatique.

## 8. Acceptation Studio et sources

**Scénario distinctif :** Poser deux marques puis masquer les jutsus : reconnaître course/pivot/kunai ; adversaire couvre une marque, FTG vers l’autre puis sortie sans spam ; refaire à faible chakra.

Puis jouer en continu :20s sans jutsu pour reconnaître silhouette/déplacements/contacts ; séquence garde/whiff/hit ; faible chakra puis éveil ; KO/reset. Ne pas replacer les acteurs entre tous les coups et ne pas annoncer un PASS sur un simple spawn. Comparer au fighter le plus proche et garder une faiblesse perceptible. Preuves datées par build dans CURRENT_STATE/rapports, pas badge inventé dans cette fiche.

[Source officielle : Rasengan et évolution](https://naruto-official.com/fr/news/01_1521) — ne prouve pas le kit à13.

[Ancienne fiche conservée](../2026-10-18-before-profiles/MINATO.md) : détails historiques et candidats non repris sans validation. Les anciens noms/valeurs/plans ne remplacent pas cette séparation cible/existant.
