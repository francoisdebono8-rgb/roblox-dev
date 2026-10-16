# Plan de vague du roster — architecture à ~20 fighters

> Plan Claude du 2026-10-16 (CHR-EXT-001/002, mission [COMBAT_CONVERGENCE_ONLINE_ROSTER](../missions/COMBAT_CONVERGENCE_ONLINE_ROSTER.md) §18–21, DEC-012/DEC-013). Documentation et conception seulement : aucun code, aucune valeur validée en natif. Code lu sur `c2d797c`. Le pool de 25 noms du 2026-10-13 et les familles d'archétypes viennent de [ROSTER_ARCHETYPES_32](../../design_research/02_character_architecture/ROSTER_ARCHETYPES_32.md) ; le contrat de fiche est [FIGHTER_TEMPLATE](FIGHTER_TEMPLATE.md) ; les hooks `H01…H17` sont décrits dans [ROSTER_WAVE_HOOKS](ROSTER_WAVE_HOOKS.md). Le menu prévoit déjà 20 emplacements (`ROSTER_SLOTS=20`, `Client/UI.luau:56`).

## 1. Principes

- **Un fighter = un système éprouvé ou tordu.** La popularité ne qualifie pas ; chaque fiche nomme le système qu'elle met à l'épreuve.
- **Grammaire commune, expression distincte** (DEC-006) : ~70 % partagé, ~30 % propre ([ROSTER_ARCHETYPES_32](../../design_research/02_character_architecture/ROSTER_ARCHETYPES_32.md)).
- **Stade, pas âge** (DEC-013) : racines d'identité présentes, échelle adulte/endgame absente ; labels DEC-005 par capacité.
- **Jouable pour éprouver le moteur** ≠ terminé : périmètre minimal de chaque fiche + duels IA contre tout le roster + test sans jutsu + 30 s de déplacement et 60 s de combat observés en natif ([FIGHTER_TEMPLATE](FIGHTER_TEMPLATE.md), validation Studio). DEC-012 rend chaque fighter de la vague sélectionnable **quand** il atteint ce seuil (proposition de définition, à confirmer).

## 2. Architecture à ~20

| # | Fighter | Code | Stade (DEC-013) | Familles (n° de ROSTER_ARCHETYPES_32) | Système éprouvé / tordu | Statut |
|---|---|---|---|---|---|---|
| 1 | Minato | `Flashstep` | ~13, prototype de sceau | 1, 10, 4 | réseau de destinations, relocation | CORE4 jouable ([fiche](MINATO.md)) |
| 2 | Itachi | `Mirage` | ~12, pré-Mangekyō | 3, 8, 7 | lecture, géométrie de projectiles, leurre | CORE4 jouable ([fiche](ITACHI.md)) |
| 3 | Neji | `GentleFist` | 13, examen chûnin | 4, 3, 16 | perturbation de ressource | CORE4 jouable ([fiche](NEJI.md)) |
| 4 | Sasuke | `Lion` | 12, examen chûnin | 5, 8, 12 | conversion agressive, fil → feu | CORE4 jouable ([fiche](SASUKE.md)) |
| 5 | Gaara | `Sand` | 12–13, examen → récupération | 6, 14, 12 | défense automatique, mêlée décalée | serveur + tests, caché ([fiche](GAARA.md)) |
| 6 | Rock Lee | `Lotus` | 12–13, préliminaires | 5, 18 | grammaire sans jutsu, vitesse, PV comme coût | vague ([fiche](ROCK_LEE.md)) |
| 7 | Temari | `Gale` | 15–16, examen → récupération | 12, 17 | zones directionnelles, longue portée | vague ([fiche](TEMARI.md)) |
| 8 | Kisame | `Shark` | « jeune épéiste de Kiri » (liberté) | 11, 16, 12, 15 | vol de chakra, armure, eau | vague ([fiche](KISAME.md)) |
| 9 | Kakashi | `Kannabi` | 13, Gaiden, pré-Mangekyō | 20, 3, 15, 14 | copie (portabilité), posture payée, terrain | vague ([fiche](KAKASHI.md)) |
| 10 | Haku | `Crystal` | 15, Pays des Vagues | 8, 1, 14, 4 | objets solides cassables, origines multiples | vague ([fiche](HAKU.md)) |
| 11 | Naruto | `Legion` | 13, Vallée de la Fin I | 7, 5 | corps multiples | vague ([fiche](NARUTO.md)) |
| 12 | Shikamaru | `Imitation` | 12–13, examen → récupération | 10, 3 | possession (intention imposée), ombres du terrain | vague ([fiche](SHIKAMARU.md)) |
| 13 | Shisui | — | ~13–16, sans Kotoamatsukami en boucle | 2, 3 | positions fictives sous latence | candidat |
| 14 | Kimimaro | — | ~15, Partie I (malade) | 6, 15, 17 | armure osseuse, postures-danses | candidat |
| 15 | Sasori | — | adolescent, avant son corps-marionnette | 13, 10 | **entité pilotée** à distance, poison | candidat |
| 16 | Deidara | — | jeune bombardier d'Iwa (à vérifier) | 18, 10, 12 | déclenchement à distance, aérien | candidat |
| 17 | Orochimaru | — | jeune génin/chûnin sous Hiruzen | 9, 10, 13 | portée décorrélée du corps, souterrain | candidat |
| 18 | Nagato | — | jeune, Rinnegan sans les Six Chemins | 1, 6 | forces radiales (répulsion/attraction) | candidat |
| 19 | Killer Bee | — | jeune, aux côtés de A (à vérifier) | 15, 17, 5 | rythme comme identité, multi-armes | candidat |
| 20 | Konan | — | jeune d'Ame formée par Jiraiya | 8, 18 | corps dispersé, formes de papier | candidat |

**Temari** n'appartient pas au pool de 25 (elle y est candidate secondaire) mais la mission utilisateur du 2026-10-16 la nomme : la demande la plus récente prime. Les 12 places au-delà de 20 (cible ~32) restent ouvertes.

### Candidats ultérieurs (13–20) : pourquoi eux

| Candidat | Ce que lui seul éprouve | Distinct de |
|---|---|---|
| Shisui | images rémanentes **sans corps** dont le joueur choisit la vraie ré-entrée : rendu client vs vérité serveur sous latence (NET-001), H12 v0 | Naruto (corps réels), Haku (reflets dans des objets), Minato (destinations préparées) |
| Kimimaro | armure **corporelle** (H13) + danses = postures d'arme (H09) + os comme terrain réduit (H11) ; canon jeune | Kisame (armure payée en chakra volé), Gaara (défense passive à distance) |
| Sasori | un **second corps piloté** par le joueur (H12 v2 + H10 : fils coupables) | Naruto (clones autonomes, 1 PV) |
| Deidara | explosifs **déclenchés à distance**, mines (H06/H11), monture aérienne (CAM-002) ; dépend de TOOL-004 (DEFERRED) | Temari (vent), Haku (tir) |
| Orochimaru | allonge **sans projectile** (hitbox décorrélée du corps), état souterrain ciblable plus tard | Gaara (sable décalé mais fixe), Kisame (allonge d'arme) |
| Nagato | **impulsions omnidirectionnelles** sur corps et projectiles (H04 forces + H08 renvoi global) | Temari (couloirs persistants orientés) |
| Killer Bee | le **rythme** (`Config.Flow`, aujourd'hui bonus discret) devient le cœur ; sept sabres en prises différentes | Lee (élan par le mouvement), Kakashi (arme unique) |
| Konan | **dispersion du corps** (état non ciblable qui se reforme ailleurs), ailes, papier explosif (TOOL-004) | Haku (objets solides), Deidara (explosion à distance) |

**Différés** (pool, recouvrement ou stade faible) : Kabuto (le soin casse l'économie de PV en 1v1 ; précision recoupe Haku/Neji) ; Tobirama (eau + espace : recoupe Minato et Kisame) ; Hiruzen (généraliste : recoupe Kakashi, jeunesse peu documentée) ; Obito (pré-Mangekyō : identité jeune proche de Sasuke/Itachi ; Kamui exclu par DEC-013) ; Darui (foudre/eau mi-distance : recoupe Kakashi/Kisame, jeunesse non documentée) ; **Yagura** (bâton-crochet, miroir d'eau qui **renvoie** les techniques : réserve n°1, à départager avec Haku et Kakashi).

## 3. Matrice de couverture des systèmes

● = système au cœur du kit, ○ = secondaire.

| Fighter | Mobilité spatiale | Projectiles | Zones | Objets de terrain | Entités | Contrôle / bind | Ressource / perturbation | Posture / charge | Défense auto / armure | Air / mur | Nature × contexte | Mêlée pure / arme | Réseau sensible |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Minato | ● | ○ | | | | | | | | ○ | | ○ | ● |
| Itachi | | ● | ○ | | | ○ | | | ○ | | ○ | ○ | ○ |
| Neji | | | | | | ○ | ● | | ○ | | | ● | |
| Sasuke | | ○ | ○ | | | ○ | ○ | | | ○ | ● | ○ | ○ |
| Gaara | | ○ | ○ | ○ | | ● | ○ | | ● | | ○ | | |
| Lee | | | | | | | ● | ○ | | ○ | | ● | ● |
| Temari | ○ | ○ | ● | | | | | ● | | ○ | ○ | ○ | ○ |
| Kisame | | ○ | ● | | | ○ | ● | | ● | | ○ | ○ | |
| Kakashi | | ○ | | ● | | | ○ | ● | | ○ | ● | ○ | ○ |
| Haku | ○ | ● | ○ | ● | ○ | ○ | ○ | | | | ○ | ○ | ○ |
| Naruto | | ○ | | | ● | ○ | ○ | ○ | ○ | | | ○ | ● |
| Shikamaru | | | ○ | ○ | | ● | ○ | ○ | | | | | ● |
| Shisui | ● | ○ | | | ○ | | | | ○ | | | ○ | ● |
| Kimimaro | | | | ○ | | | ○ | ● | ● | | | ● | |
| Sasori | | ○ | ○ | | ● | ○ | ○ | | | | | | ● |
| Deidara | ○ | ○ | ● | ○ | ○ | | | | | ● | ○ | | ○ |
| Orochimaru | ○ | | | | ○ | ○ | | | | | | ● | ○ |
| Nagato | ○ | ○ | | | | ● | | | ○ | | | | ○ |
| Killer Bee | | | | | | | ○ | ● | ○ | ○ | ○ | ● | ○ |
| Konan | ○ | ● | ○ | | ○ | | | | ○ | ● | | | ○ |

Lacune assumée : **spécialiste du mur** (famille 19) — aucun candidat du pool ne l'incarne nettement ; à réévaluer après ARENA-001 (Lee et Shisui sont les plus proches).

## 4. Différenciation des 12 (CORE4 + vague)

| Fighter | String | ↑ et conversion | Poursuite | Substitution | Outil (R) | Ressource propre | Éveil (règle) |
|---|---|---|---|---|---|---|---|
| Minato | 3, kunai revers, dérive d'angle | sceau corporel → FTG | FTG | vers un sceau | kunai rapide | regen 8 | stats/CD (à refaire, SYS-003) |
| Itachi | 3, recul auto | lames de couverture | commune | corbeau derrière | 2 shuriken, Geometry | réserve 125 | fenêtres ×1.5 |
| Neji | 3 paumes qui drainent | paume au menton | commune | hop | kunai secondaire | drain adverse | sans angle mort |
| Sasuke | 3 coups de pied | LionKick → Kage Buyō gratuit | se poursuit | hop | 2 shuriken, fil | coûts lourds | stats + perte de PV |
| Gaara | 3 fouets à 9 studs | Pillar → `sandCatch` au sol | aucune | sable (1 charge) | balle de sable | charges de bouclier | bras de Shukaku |
| Lee | **4**, le bas relance | LeafRising → Kage Buyō payé 1 Élan | se poursuit | **Rupture** sur place | coup de pied de déviation | Élan + PV | Lotus inversé, esquive en PV |
| Kakashi | 3 tantō + GuardKick sur garde | RisingCut | Chidori dirigé | hop + relais | kunai-relais | drain de l'œil | œil sans drain, Copie ×2 |
| Temari | 3 qui **repousse** | Updraft → conversion à distance | aucune | 14 studs arrière | Bourrasque (renvoie) | zoning cher | 3e lune rapide, Kamatari |
| Kisame | **2** lourds, transfert | SharkRise (+chakra) | aucune (mur, prison) | clone d'eau (flaque) | jet d'eau (flaque) | vol + surcharge | armure totale |
| Haku | **4** rapide, crans | FrostCrescent **garde la string** | aucune (sol) | dans le miroir | senbon (depuis miroir) | crans adverses | dôme de miroirs |
| Naruto | 3, L3 par un clone | UzumakiKick, clones qui jonglent | **déléguée** | échange avec un clone | kunai-clone | 160 + sursaut | manteau : perd les clones |
| Shikamaru | **2** qui repousse | aucun | aucune | hop (justifié) | kunai + fil-piège | durée = chakra | ombre double |

## 5. Ordre d'implémentation recommandé

Ordre fixé par **dépendances et coût**, pas par popularité : chaque phase construit un hook une fois et le fighter suivant l'étend.

| Phase | Contenu | Hooks construits | Dépend de | Effort |
|---|---|---|---|---|
| 0 — Socle | identité client par données, IA par données, registre des twists de verbes communs (migration seal/crow de CORE4 sans changement de comportement), strings par fighter, modificateurs de mouvement + correctif `speedScale` ; tests générés depuis la liste des fighters ; liste jouable lue dans les données ; découpage des données de clips (ARC-002) | H01, H03, H17, H02, H04 | QA-001 (baseline pour comparer CORE4) | M |
| 1 — **Gaara** | exposer le kit existant : client, VFX de sable, HUD de charges, tests Lion, balance | (valide H01/H03) | phase 0 | S |
| 2 — **Rock Lee** | grammaire sans jutsu, vitesse, Élan, PV, déviation, Lotus | H05 v1, H08 v1, H09 v1, H14 | phase 0 (H04 obligatoire) | M |
| 3 — **Temari** | zones vectorielles, renvoi, maintien/relâchement, vent × feu | H06 v1, H08 v2, H09 v2, H07 v1 (une règle, différable) | ARENA-001 (distances), CAM-002 | M |
| 4 — **Kisame** | transfert/surcharge, armure, eau propriétaire, absorption, prison | H05 v2, H13, H06 v2, H08 v3, H10 v1 | phase 3 (H06) | M |
| 5 — **Kakashi** | posture payée, mur de terre, conduction, Copie | H09 v3, H11 v1, H07 v2, H16 | phase 3/4 (H07, H09) | M/L |
| 6 — **Haku** | miroirs (PV, origines, voyage), reflets visuels, crans, glace, saisie→technique | H11 v2, H12 v0, H10 v2 | phase 5 (H11) | L |
| 7 — **Naruto** | clones touchables, routage des coups, snapshot `entities`, sursaut, manteau | H12 v1, H05 v3, H13 (réutilisé) | phase 6 (H12 v0) ; NET-001 si le PvP est actif | L |
| 8 — **Shikamaru** | possession, ombre dirigeable, relais d'objets/entités/arène | H10 v3, H15 | phases 5–7 (objets, entités), ARENA-001 (régions d'ombre), NET-001 (suspendre la prédiction du possédé) | L |

- Parallélisable : phases 2 et 3 après la phase 1 ; H11 (phase 5) peut commencer pendant H13 (phase 4).
- Sortie de chaque phase : périmètre minimal de la fiche, duels IA contre tout le roster jouable, test sans jutsu, nettoyage (fin de manche, KO, sélection), journal et backlog mis à jour ; acceptation native séparée (DEC-007).
- Alternative écartée : Naruto en premier (popularité) — il exigerait H12, le hook le plus lourd, avant tout socle, et ferait porter le risque réseau sur la première livraison.

## 6. Règles anti-homogénéité

1. **String propre** (H02) : chaque fighter déclare sa string (2 à 5 coups) avec des clips à lui ; deux fighters ne partagent pas le même triplet (longueur, réactions des coups, coup final). Des multiplicateurs d'`AttackProfile` seuls ne différencient pas.
2. **Pas d'héritage de clips** pour la string, le launcher et les routes signatures (`setmetatable(CLIPS.X,{__index=…})`, aujourd'hui `GentleFist→Mirage` et `Lion→Flashstep`) ; toléré temporairement pour saisies et coups aériens génériques, listé dans la fiche avec un ID (comme CHR-NEJ-002, CHR-SAS-002). Les nouveaux fighters partent à zéro héritage.
3. **Launcher = conversion distincte** : deux fighters ne partagent pas le même payoff de ↑ sans coût et finisher distincts (Kage Buyō : gratuit → Lion Combo pour Sasuke ; 1 Élan → Lotus pour Lee).
4. **Routes latérales variées** : au plus la moitié du roster en orbite (CORE4 : 4 orbites) ; la vague n'en ajoute qu'une conditionnelle (ReadStep de Kakashi).
5. **Relation à l'outil déclarée** : maîtrise (règle propre), secondaire (générique assumé), remplacé (action contextuelle sur R), aucun. Jamais « le même kunai avec d'autres chiffres ».
6. **Twist défensif** (H17) : chaque fighter change par une règle au moins un verbe parmi substitution, perfect dodge, parry, garde. Substitution `hop` pure : 3 fighters au plus sur 20, chacun justifié (aujourd'hui Neji, Sasuke, Shikamaru).
7. **3 à 4 techniques** en base (le 5e emplacement reste libre pour la Copie ou la progression) ; chacune interagit avec au moins un autre système (route, outil, zone, état, autre technique) ; aucune technique « dégâts seulement ».
8. **Éveil à règles** : au moins deux règles modifiées ([AWAKENING_DESIGN](../../design_research/02_character_architecture/AWAKENING_DESIGN.md)), un contre-jeu nommé, une sortie/risque ; multiplicateur de dégâts ≤ ×1.08.
9. **Signature transversale** : elle touche au moins trois couches (mouvement, taijutsu, outil, technique, défense, IA, HUD).
10. **Test sans jutsu** : duel headless avec `match.techniquesDisabled` (`Server/Combat.luau:744`) où l'événement signature apparaît encore, ou décision écrite dans la fiche (Naruto, comme le Sharingan d'Itachi) ; reconnaissance native (CHR-CORE-001).
11. **L'IA exerce la signature** : un test vérifie que l'IA déclenche l'événement signature (compteurs `Brawler.event`) contre chaque adversaire.
12. **Données avant code** : aucun nouveau `if a.fighterId=="X"` dans Combat, Brawler, AI, Effects ou la motion ; champs de `def` et tables de handlers (H01, H03, H17). Les chaînes CORE4 existantes migrent progressivement (principe du [brouillon de bible](../archive/missions/legacy-v0/foundation/GAMEPLAY_BIBLE_DRAFT.md), section « Vingt combattants »).
13. **Ne jamais muter `a.def`** (table partagée entre acteurs, duels miroirs) : état et modificateurs par acteur.
14. **Lore avant code** : label par capacité (DEC-005/DEC-013), échelle adulte rejetée, réductions d'échelle écrites.
15. **Registre des recouvrements** (§7) tenu à jour : tout nouveau recouvrement nomme la règle qui sépare les deux fighters avant implémentation.
16. **Contrôle final** ([ROSTER_ARCHETYPES_32](../../design_research/02_character_architecture/ROSTER_ARCHETYPES_32.md)) : si deux fighters répondent presque pareil à au moins 8 des 12 axes de différenciation du gabarit, l'un est redessiné.

## 7. Registre des recouvrements

| Recouvrement | Fighters | Règle qui les sépare |
|---|---|---|
| Rasengan | Minato / Naruto | Naruto : canon jeune, exige un clone, poussée longue ; Minato : instantané après FTG, nommé adulte en l'état (décision CHR-CORE-002) |
| Chidori | Sasuke / Kakashi | Sasuke : finisher en string-cancel ; Kakashi : prototype, tunnel couvert / dirigé découvert, décharge des relais |
| Kage Buyō | Sasuke / Lee | gratuit → Lion Combo / payé 1 Élan → Lotus (PV) |
| Réseaux posés | Minato / Haku / Kakashi / Shikamaru | destinations dispersées / cage solide cassable / conducteurs de foudre / ombres des objets de tous |
| Perturbation | Neji / Kisame / Haku | détruit le chakra / le vole / vise la mobilité |
| Sharingan | Itachi / Sasuke / Kakashi | permanent + Read / permanent étroit / basculé, payé, Copie |
| Feu | Itachi / Sasuke | déjà signalé (fiches CORE4) ; Temari ne recoupe pas : son vent nourrit le feu des autres |
| Vent | Minato (WindCut) / Temari | WindCut sans source jeune et redondant ([MINATO](MINATO.md)) : retrait ou recadrage proposé |
| Zoning | Gaara / Temari / Kisame | sol fixe qui lie / air mobile qui repousse / eau à son profit |
| Bind | Sasuke / Gaara / Kisame / Shikamaru / Haku | fil 1 s / bind → enterrement / prison qui fige le lanceur / possession en miroir / pied cloué, figé |
| Défense sans input | Gaara / Kisame / Naruto (manteau) | passive à charges / active payée en chakra / armure d'éveil |
| Conversion au sol | Gaara / Haku | attrape à l'atterrissage / garde la string et glace le relevé |

## 8. Décisions utilisateur à trancher

1. **Kisame jeune** : aucun stade canon ; cadrage « jeune épéiste de Kiri » à confirmer ([KISAME](KISAME.md)).
2. **Âge de Temari** (15–16) face au slogan « 12–14 ans » du menu.
3. **Rasengan** : canon jeune pour Naruto, adulte en l'état pour Minato ; et sort de WindCut.
4. **Définition de « jouable »** pour l'exposition au menu (proposée §1) — amendement de DEC-001 par DEC-012.
5. **Saisie contre bouclier de Gaara** ([GAARA](GAARA.md) §7).
6. **TOOL-004** (tags explosifs) reste DEFERRED jusqu'à Deidara/Konan.
7. Liste des 8 candidats ultérieurs et des 6 différés ; titres et ids de code proposés.
