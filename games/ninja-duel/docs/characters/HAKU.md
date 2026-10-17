# Haku Yuki — fiche de référence

ID runtime **`Mirror`** · version documentaire du **18/10/2026** · données lues au HEAD **`1cabd7f`** (runtime `bc7faa3`). [Index/comparaison](ROSTER_20.md) · [contrat commun](FIGHTER_TEMPLATE.md).

**Portée :** intention utilisateur et méthode dans [DEC-025](../active/DECISIONS.md#dec-025--fiches-personnages-et-identité-perceptible). Cette fiche propose la cible détaillée ; elle n’annonce ni validation lore complète, ni implémentation, ni autorisation de nouvelle passe. Priorités/acceptation : [MASTER_BACKLOG](../active/MASTER_BACKLOG.md). État global : [CURRENT_STATE](../active/CURRENT_STATE.md).

## 1. Version et promesse

Pays des Vagues ; âge15 runtime.

**Signature irremplaçable :** Construire un espace de miroirs puis changer l’origine des salves pour déplacer l’attention adverse.

**Faiblesse/contre-jeu :** Hors dôme, coût d’installation et assaut direct ; une issue du dispositif doit rester lisible.

## 2. Tenue, silhouette et mouvement — cible

**Vêtements/armes visibles :** Kimono/tunique vert doux avec bord clair, longs cheveux noirs attachés, masque de chasseur selon choix de visibilité ; senbon aux doigts, gestes fins.

**Course, sprint, strafe, dash et esquive :** Course légère et appuis fins ; déplacement entre miroirs uniquement dans le dispositif prévu ; hors dôme, pas de téléport gratuit vers tout le monde.

**Air, poursuite, réception et mur :** Air : tir d’angle et retour vers le dispositif ; mur : miroir/angle sous règle autorisée, pas surface mondiale téléportable. Une réception ramène à des appuis stables ; la caméra ne doit pas masquer la source d’un coup.

## 3. Chakra — distinguer nature, contrôle et quantité

**Nature/capacité particulière proposée :** Hyôton, kekkei genkai combinant Eau/Vent ; ne pas donner automatiquement toutes les techniques Suiton/Fûton. Ice n’est pas un simple skin bleu de Fire.

**Réserve, efficacité et faible chakra :** Réserve moyenne à élevée, contrôle très fin ; coût du dôme et des traversées structure le combat, dépendance à sa zone. À sec : senbon et mobilité corporelle.

**Interaction concrète à rendre perceptible :** Senbon rapides, visée de points et ralentissement borné ; source réelle de la volée dans le dôme.

Le profil d’infusion actuel est **`Basic`**, d’après [ChakraTuning](../../src/Server/ChakraTuning.luau). Ce nom décrit l’interpréteur actuel, pas toutes ses capacités ni une maîtrise acquise par le joueur. Un fallback Basic n’annule pas ses jutsus ; il signale l’absence de spécialisation explicite dans ce mapping.

## 4. Repères du build actuel — pas des stats canon

| Paramètre runtime | Valeur brute |
|---|---:|
| Âge affiché | 15 |
| Santé | 115 |
| Réservoir de chakra | 125 |
| Paramètre ChakraRegen | 8.4 |
| Speed de base | 20 |
| Coefficient SprintScale | 1.12 |
| JumpScale / AirControlScale | 1.08 / 1.12 |
| AccelerationScale | 1.12 |
| Distance préférée configurée | 11 |

Sources : [définition](../../src/Shared/Wave1.luau), [mouvement](../../src/Server/Motor.luau), [régénération](../../src/Server/Combat.luau). Speed est une base en studs/s, pas une vitesse native mesurée ; le sprint dépend du profil de mouvement et des états, **pas simplement Speed×SprintScale**. Regen est également modulée en combat. Ne pas retuner ces nombres sur la seule lecture de la fiche.

**Habiletés cibles relatives (1–5, proposition de design, aucun multiplicateur runtime ni score officiel) :** Taijutsu 3/5, Ninjutsu 5/5, Genjutsu 1/5, Contrôle 5/5, Outils/armes 4/5, Endurance 3/5. Les axes désignent des spécialisations, pas un total de puissance à maximiser ; Lee1 en ninjutsu ne signifie pas absence de chakra.

## 5. Moveset et défense — cible à confronter au kit

**Chaîne légère représentative :** Pique senbon → frappe précise → poussée courte de séparation ; pas grands coups de pied lourds empruntés sans adaptation.

**Routes :** Haut : launcher léger/contrôle ; bas : déséquilibre à la senbon ; côté : IceSlide à distinguer d’une glissade commune ; lourd = SenbonStab précis.

**Garde, parade, esquive/substitution et reprise :** Esquive propre et défense par distance ; miroir ne donne pas invulnérabilité passive universelle. La substitution garde coût, charges, fenêtre et destination autorisés du système commun ; aucun échappatoire gratuit implicite.

**Outils :** Senbon rapides, visée de points et ralentissement borné ; source réelle de la volée dans le dôme.

**Routes réellement déclarées :** airDown=`AirSpike`, airSide=`AirSwitch`, airUp=`AirDrive`, down=`Sweep`, side=`IceSlide`, up=`Launcher` ; lourd après un hit : `SenbonStab`. [MoveGraphs](../../src/Shared/MoveGraphs.luau). Ces noms ne prouvent pas les animations ni les contacts. Invariant : avant premier hit confirmé, direction+Light ne déclenche aucune route spéciale.

## 6. Techniques présentes et admissibilité de période

Snapshot du kit actuel ; temps = **channel / active / recovery**, en secondes. Coûts/cooldowns/portées sont configurés, pas validés par cette documentation. REVIEW_REQUIRED signifie provenance/période non établie ici ; ne pas désactiver la technique sur ce seul label.

| Technique / fonction actuelle | Coût | C/A/R | CD | Portée | Statut de période |
|---|---:|---|---:|---:|---|
| `WaterNeedles` — Thousand Flying Water Needles : A fan of ice needles • each one slows • hard to dodge sideways | 16 | 0.3/0.05/0.3 | 4.5 | 34 | REVIEW_REQUIRED (technique d’aiguilles d’eau ; représentation glacée du runtime à préciser) |
| `MirrorStep` — Ice Mirror Step : Outside the dome: out of a mirror at his flank, senbon to a vital point • inside it: from mirror to mirror round the body, a volley from each | 14 | 0.1/0.04/0.2 | 3.6 | 30 | CANON_YOUNG (déplacement entre miroirs), GAMEPLAY_LIBERTY hors dôme |
| `IceMirrors` — Demonic Ice Mirrors : A dome of mirrors round the opponent • it slows and cuts • his mirror step strikes harder inside | 28 | 0.55/0.2/0.35 | 12 | 30 | CANON_YOUNG (dôme ; géométrie de jeu) |

**Capacités possibles / limites :** les variantes de mouvement, routes et chakra décrites ici sont des **GAMEPLAY_LIBERTY proposées** lorsqu’aucune source de période ne les atteste ; une possibilité n’est pas un bouton supplémentaire à implémenter. Préférer faire mieux fonctionner une interaction existante avant d’ajouter un jutsu.

## 7. Éveil, boucles et habileté du joueur

**Éveil actuellement nommé :** `CRYSTAL ICE MIRRORS`. **Cible/contrat :** ZoneFree/Ring déjà présents : traversées/volées particulières dans la zone ; pas ajout d’un nouveau moteur de miroirs.

**Boucle agressive :** approche propre au personnage → ouverture/hit confirmé → route utile → choix outil/jutsu ou sortie ; priorité : Construire un espace de miroirs puis changer l’origine des salves pour déplacer l’attention adverse.

**Boucle défensive/faible chakra :** Esquive propre et défense par distance ; miroir ne donne pas invulnérabilité passive universelle. Réserve moyenne à élevée, contrôle très fin ; coût du dôme et des traversées structure le combat, dépendance à sa zone. À sec : senbon et mobilité corporelle.

**Plafond de maîtrise du joueur :** Débutant : senbon/dôme. Intermédiaire : changer l’angle. Expert : décider quand rester dans le dispositif ou abandonner une zone devenue dangereuse.

**Hors kit / incohérences de période à résoudre :** Réseau de miroirs physiques cassables/HP : candidat historique, pas implémenté ni demandé pour cette passe. Aucun gel/stun infini.

## 8. Acceptation Studio et sources

**Scénario distinctif :** Même duel dedans/dehors le dôme ; arrivée et volée partent du miroir cohérent ; faible chakra doit réduire ses options sans casser le taijutsu.

Puis jouer en continu :20s sans jutsu pour reconnaître silhouette/déplacements/contacts ; séquence garde/whiff/hit ; faible chakra puis éveil ; KO/reset. Ne pas replacer les acteurs entre tous les coups et ne pas annoncer un PASS sur un simple spawn. Comparer au fighter le plus proche et garder une faiblesse perceptible. Preuves datées par build dans CURRENT_STATE/rapports, pas badge inventé dans cette fiche.

[Source officielle des miroirs](https://naruto-official.com/fr/anime/naruto1/list/01_238) ; [source secondaire Eau/Vent](https://naruto.fandom.com/wiki/Haku), période de chaque détail à confirmer.

[Ancienne fiche conservée](../archive/characters/2026-10-18-before-profiles/HAKU.md) : détails historiques et candidats non repris sans validation. Les anciens noms/valeurs/plans ne remplacent pas cette séparation cible/existant.
