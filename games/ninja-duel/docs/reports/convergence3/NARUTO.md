# Naruto — test de charge « plusieurs corps » (convergence 3)

Branche `claude/nd-vrs-naruto`, base `2aba0ca` (`claude/ninja-duel-2026-10-14`). Mission : [NEXT_VALIDATION_ROSTER_SCALE](../../missions/NEXT_VALIDATION_ROSTER_SCALE.md) §9 (avec §8 et §10). Fiche : [NARUTO](../../characters/NARUTO.md). Cadre : [PRODUCTION_FRAMEWORK](../../characters/PRODUCTION_FRAMEWORK.md).

## En bref

- **Naruto (`Legion`, Partie I, 13 ans) est jouable et sélectionnable** : kit serveur sur les systèmes partagés, IA, famille de mouvement, costume, couche visuelle `NarutoFX`, case du roster. **Studio n'a pas été ouvert : tout est prouvé en headless** (`tests/Naruto.spec.luau`, 33 cas), rien n'est « joué en Studio ».
- **Le moteur supposait deux corps** (`Combat:separate`, projectiles contre `p.a.target`, snapshot `human`/`bot`). Les clones passent par un **composant serveur réutilisable**, `Server/Bodies` (hook H12) : des corps qui ne sont pas des acteurs, avec contrôleur, durée, volume de coup, dissipation en un coup, coups portés jugés depuis leur position (`hitOrigin`), liste `bodies` du snapshot dessinée par `Client/BodyViews`. Le verrouillage, la cible de l'IA et la caméra restent sur le vrai Naruto. Les 23 autres suites passent sans changement.
- Mécanique signature : **clones d'ombre** (2 au plus, 12 chakra, 6 s, un coup les dissipe dans un nuage de fumée) qui **portent ses routes** (3e coup depuis le dos, frappe de flanc, Rendan Uzumaki), **forment son Rasengan** (frapper le clone l'annule), naissent de son **kunai transformé** (Z + R) et servent à la **substitution** (« c'était un clone ! »). Éveil : **chakra de Kyûbi** — plus aucun clone, des griffes, un Rasengan sans clone, un corps plus vif.

## Implémenté (preuve headless uniquement)

| Capacité | Où | Test (`tests/Naruto.spec.luau`) |
|---|---|---|
| Données : HP 140, chakra 160 (la plus grande réserve), regen 6,5, `Bodies.clone={Max=2,Cost=12,Life=6}`, `Substitution.Mode="clone"`, outil kunai avec `Transform="clone"` | `Shared/Fighters.luau` (`Legion`) | « kit » |
| Clone d'ombre (12, canal 0,18) : un corps à côté de lui, jamais un acteur ; deux au plus ; 6 s puis fumée ; près de l'adversaire il part sur un flanc | `Server/Legion.luau`, `Server/Bodies.luau` | « Shadow Clone », « goes to the opponent's flank » |
| Un coup le dissipe : la frappe adverse qui l'atteint d'abord s'y dépense (comme une garde : la string recommence) ; une lame s'y arrête, un jutsu (boule de feu) le traverse ; un balayage large efface tous les clones qu'il couvre et touche quand même Naruto | `Bodies.strike/projectile`, crochets `Brawler.hit`, `Combat:updateProjectiles` | « one blow dispels », « blades stop » |
| Le stick choisit le clone : un premier coup poussé vers un clone en portée le vise (le verrou reste sur Naruto) ; dans une string le stick choisit des routes, jamais un clone | `Bodies.aim`, `Brawler.start`, `Combat.swingAt` | « the stick picks the clone » |
| 3e coup avec un clone dehors : le clone frappe **depuis le dos** de l'adversaire (jugé depuis le clone : la garde frontale ne couvre pas), puis il se dissipe ; sans clone, son coup de pied | `MoveGraphs.Legion.proxy`, `Bodies.route/bind`, `p.from` | « the third hit » |
| ←→ après un coup : un clone frappe depuis ce flanc, la string continue ; sans clone dehors il en paie un (12) ; sans chakra, son 2e coup | `Attacks.MirrorClone` | « side after one hit » |
| ↑ après deux coups (ou lourd) : **Rendan Uzumaki** — un clone lance le corps par-dessous, deux autres le relancent (« U-ZU-MA »), E puis lourd en l'air = **NARUTO UZUMAKI RENDAN** (talon d'en haut) | `Legion` (paiement `uzumaki`), `airFinisher` | « Uzumaki Barrage » |
| ↓ après deux coups : son tacle dans les jambes ; lourd après un coup : coup de tête | `Attacks.Tackle/Headbutt` | « away after two hits » |
| **Rasengan** (22) : un clone dehors vient à sa main et le forme pendant le canal (0,45 s) ; sans clone il en crée un (+12, 0,6 s) ; **frapper ce clone fait échouer le Rasengan** (chakra et recharge perdus) | `Techniques.CloneRasengan` (crochet `start`) | « Rasengan with a clone out », « strike the shaping clone » |
| Multi clone d'ombre (30) : deux clones jaillissent des deux côtés et chargent | `Techniques.MassShadowClone` | « Multi Shadow Clone » |
| Outil : kunai ; Z + R = kunai transformé (16) qui redevient un clone près de la cible et frappe depuis son flanc ; avec deux clones dehors, le même accord renforce seulement le kunai ; profil chakra `ShadowClone` | `ToolMastery.Transform`, `Bodies.transform`, `ChakraTuning` | « the chakra chord on his kunai » |
| Substitution « c'était un clone ! » : il prend la place d'un clone, le clone part en fumée là où il était frappé ; sans clone, le saut commun (et sa bûche) | `Combat:substitute` (mode `clone`) | « substitution with a clone out » |
| Éveil **CHAKRA DE KYÛBI** (≤ 35 %) : les clones éclatent, aucun clone ne revient, les routes de clones deviennent ses griffes (portée 9,5–10), Rasengan sans clone en 0,2 s, toutes ses récupérations ×0,78 | `Awakening.NoBodies/Recovery`, `Bodies.blocked` | « the Nine-Tails chakra », « in the cloak » |
| Relance « legion » : côté d'arrivée irrégulier (`shuffle`), un angle plus large une fois sur trois ; un clone sur un flanc charge l'autre côté (tenaille) | `MoveGraphs.Legion.reengage`, `Brawler.rushPlan` | « re-engage » |
| Contre-jeu des autres : la Rotation de Neji balaie les clones, chaque coup de clone coûte une charge au bouclier de Gaara, tout réveil souffle les clones proches | `Combat:stepRotation`, `Combat:awaken` | « other fighters » |
| Nettoyage : fin de manche, KO, propriétaire à terre ; snapshot = clones vivants seulement | `Bodies.clear/view`, `Matches:view` | « clean-up », « the snapshot » |
| IA : clones en neutre, Rasengan avec clone, Rendan après la poursuite, kunai transformé ; **toute IA répond aux clones** (frappe celui qui arme son coup à côté d'elle) ; DASH/CHASE de Naruto | `Server/AI.luau` | « the AI uses his kit », « every fighter's AI » |
| Duels IA semés contre Minato, Itachi, Neji, Sasuke, Gaara, Lee, **dans les deux ordres, jusqu'au KO, sans blocage > 2,5 s** ; jamais plus de 2 clones | — | « AI duels » |
| Client : famille de mouvement à lui (garde basse et ouverte, démarche lourde aux bras larges, string crochet / direct / poussée), intro pouce levé ; clips des clones (coup de pied dans le dos, coup montant, crochet de flanc, coup de la rafale), Rendan, griffes, sceau en croix, clone qui façonne ; aucun saut de pose (pire 38,0°/image) | `VelmoraMotionEngine` | « motion family », « his clips », « without a snap » |
| `BodyViews` : chaque clone est une copie posée de **son propre modèle** (costume compris, sans Humanoid ni arme), sur une trajectoire lissée, rangée dans une réserve | `Client/BodyViews.luau`, `Presentation` | « client: each clone is drawn » |
| `NarutoFX` : fumée pour chaque façon d'apparaître / disparaître, pas de bûche dans son échange, Rasengan qui se forme avec le clone, « U-ZU-MA-KI » écrit à chaque coup, manteau rouge (queue, yeux rouges) | `Client/NarutoFX.luau` | « client: a puff » |
| Costume Partie I (combinaison orange, épaules bleues, col blanc, spirale rouge, bandeau bleu, moustaches, cheveux en pics) ; SmoothPlastic, aucun Fabric | `World.dressNaruto` | « his costume » |
| Sélectionnable ; compteur « CLONES n » sur sa plaque ; cues de clone et de rafale affichées | `UI.luau` | « he is selectable » |

Duels IA de la suite (une seule graine par ordre : échantillon minuscule, aucun réglage d'équilibre fait) : Naruto gagne 7 sur 12 ; il perd contre Gaara dans les deux ordres, contre Minato, Itachi et Lee quand ils commencent. 87 clones créés, 59 dissipés par les adversaires, 14 routes, 3 Rendan. Endurance hors suite (script jetable, quatre graines × treize paires dont le miroir, 52 duels jusqu'au KO) : **aucune erreur, aucun blocage, aucun corps laissé après un KO, jamais plus de deux clones** ; 199 clones d'ombre, 34 multi clones, 61 kunai transformés, 43 Rasengan (3 cassés), 35 rafales, 23 Rendan.

## Ce que le test de charge a cassé (corrections génériques)

1. **Deux corps partout (H12).** → `Server/Bodies` : liste `c.bodies`, contrôleurs par mode, `onDispel` / `transforms` par type, durée, volume (rayon 1,2, demi-hauteur 2,7), coups portés (`MoveGraphs.proxy` + `Attacks.proxy`), interception des frappes et projectiles, `area`, `aim`, `view`, `clear`.
2. **Une frappe se jugeait toujours depuis la racine de l'attaquant.** → `Combat:targetValid(..., from)` et `Bangla.tryHit` lisent `p.from` (volume, validation, `hitOrigin`), `Brawler.hit` pousse depuis ce repère.
3. **La règle du clash annulait le coup d'un clone** quand l'adversaire frappait Naruto au même instant (trouvé par le test) → une frappe portée par un corps est exclue du clash des deux côtés.
4. **Aucun crochet au début d'un canal** : une technique à deux corps doit appeler son aide quand le canal commence → `technique.start` (une ligne dans `Combat:request`). Défaut évité : la fin de ce crochet écrasait le canal allongé du tutoriel ; il garde le plus long.
5. **Paiements de route fermés** (chaîne `if` dans `Brawler.routePayoff`) → registre `Brawler.payoffs`.
6. **Un éveil ne pouvait pas changer les récupérations** → `Awakening.Recovery` lu par `Brawler.start`.
7. **Relance strictement alternée** → option `reengage.shuffle`.
8. **L'accord chakra ne savait qu'infuser un élément** → `ToolMastery.Transform` (un outil qui devient un corps), coût payé au lieu d'une infusion.
9. Ordre des lames : un clone derrière Naruto ne vole pas la lame qui l'atteint d'abord ; un coup large efface tous les clones couverts.

Constats non corrigés : dans le harness, la marche avance de `WalkSpeed / 60` par pas de 0,01 s (≈ 1,67 × trop vite ; corriger change tous les duels IA existants) ; les lames sans rayon ne touchent jamais un corps headless (le volume des clones, lui, est géométrique et donc identique headless et natif) ; la famille d'armes « palms » n'a qu'une lame de repli headless (le kunai de lancer ne se vérifie qu'en Studio).

## Partagé contre sur mesure

| Couche | Réutilisé | Propre à Naruto |
|---|---|---|
| Corps supplémentaires | `Server/Bodies` (générique), `Client/BodyViews` (copie du modèle du propriétaire) | contrôleurs `guard` / `flank` / `barrage` / `shape`, `onDispel` (Rasengan cassé), `transforms.clone` (`Server/Legion`) |
| Grammaire de combo | string, routes, air routes, lanceur, poursuite, `airFinisher` | 3 routes + 3e coup portés par clones, tacle, coup de tête |
| Techniques / outil | pipeline jutsu, `DashAttack` du Rasengan, profil chakra | Clone d'ombre, Rasengan à deux corps, Multi clone, kunai transformé |
| Défense / éveil | substitution (charges, fenêtre, i-frames), cadre d'éveil | mode `clone`, `NoBodies`, `Recovery` |
| Client | moteur de mouvement, registre `FX.layers` | posture, démarche, 20 clips, `NarutoFX` |

Environ un tiers sur mesure (le reste vient des familles partagées), mais la part réutilisable a grandi : la prochaine fiche à corps multiples (marionnettes de Kankuro, chiens de Kakashi) se branche sur `Bodies` par des données (`Fighters[id].Bodies`, `MoveGraphs.proxy`, `Attacks.proxy`) et un module de contrôleurs.

## Fichiers partagés touchés (ajouts courts)

- `Server/Combat.luau` : `require` de Bodies ; `targetValid(…, from)` ; mode de substitution `clone` (+ cue) ; outil `Transform` (5 lignes) ; crochet `technique.start` ; `Combat.swingAt` (déplacement et rotation vers un clone visé) ; Rotation et réveil → `Bodies.area` ; projectiles → `Bodies.transform/projectile` ; `Bodies.step` dans `update`, `Bodies.clear` dans `clear` ; `transform` copié dans `Combat:projectile`.
- `Server/Brawler.luau` : `require` ; `Brawler.payoffs` ; `shuffle` dans `rushPlan` ; `start` (route / liaison au corps, premier coup visé sur un clone, `Awakening.Recovery`) ; `hit` (`p.lost`, `Bodies.strike`, clash exclu, poussée depuis `p.from`) ; `clash` (frappe portée exclue).
- `Server/BanglaCombat.luau` : repère `p.from` (3 lignes). `Server/AI.luau` : `DASH/CHASE.Legion`, réponse aux clones (5 lignes), trois jutsus. `Server/Matches.luau` : `bodies` dans le snapshot. `Server/Techniques.luau` : une ligne d'installation de `Legion`. `Server/ChakraTuning.luau` : profil `ShadowClone`. `Server/World.luau` : `dressNaruto` + une ligne. `Shared/Fighters`, `MoveGraphs`, `Attacks` : entrées en fin de table.
- Client : `VelmoraMotionEngine` (bloc Naruto après Lee, `VARIANT_OF`, `GAIT`, poses de canal, intro) ; `Effects` (une ligne `require` de `NarutoFX`) ; `Presentation` (`BodyViews` : 3 lignes) ; `UI` (roster, compteur, cues).
- `build.py` / `tests/run.sh` : `Naruto.spec` ajouté (une ligne chacun).

## À valider dans Studio (place Debug, clavier)

Départ : `print(game.ServerStorage.NinjaDuelDev:Invoke("start","Legion","Mirage"))` ; bot immobile : `…:Invoke("freezeBot",true)` ; recharge : `…:Invoke("refill")` ; éveil : `…:Invoke("tool","awaken",{actor="human"})`. Côté adversaire : `…:Invoke("start","Mirage","Legion")`.

1. **Roster / intro / costume** : case orange « NARUTO » (7e), boutons des deux côtés ; intro pouce levé, poing sur la hanche ; combinaison orange, épaules bleues, col blanc montant, spirale rouge au dos, bandeau bleu, cheveux blonds en pics, trois moustaches par joue ; aucun rendu « osier ».
2. **Posture / démarche** : garde basse et carrée, deux poings levés, coudes écartés (ni kunai de Minato, ni main avant de Sasuke) ; marche et sprint aux bras larges, foulée rebondie.
3. **1 (Clone d'ombre) à ~20 studs** : sceau en croix, fumée blanche, un clone identique à côté de lui qui le suit au sprint ; deuxième pression : l'autre côté ; troisième : « TWO CLONES AT MOST » ; plaque « CLONES 2 » ; fumée au bout de 6 s.
4. **Approcher à ~10 studs** (bot libre) : les clones partent sur ses flancs et frappent ~toutes les 2 s quand il ne frappe pas ; sa garde frontale ne les arrête pas.
5. **LMB ×3 avec un clone dehors** : le 3e coup est un coup de pied du clone dans le dos de l'adversaire (le corps saute vers Naruto), puis fumée ; sans clone : poussée de Naruto.
6. **LMB, puis A ou D + LMB** : un clone surgit de ce flanc et frappe ; la string continue (12 chakra s'il n'y avait pas de clone).
7. **LMB, LMB, W + LMB (ou RMB)** : un clone lance le corps par-dessous (« U »), deux autres le relancent (« ZU », « MA ») ; **E** puis **RMB** : talon d'en haut, « KI! », NARUTO UZUMAKI RENDAN, corps au sol.
8. **LMB, LMB, S + LMB** : tacle aux jambes ; **LMB, RMB** : coup de tête.
9. **2 (Rasengan) à ~8 studs avec un clone dehors** : le clone court à sa main droite et la coiffe des deux mains ; sphère bleue qui grossit avec des filets de chakra venant du clone ; poussée, adversaire projeté en vrille ; fumée du clone. Sans clone : un clone apparaît d'abord (canal plus long). Contre-jeu (côté adversaire) : frapper le clone qui façonne → « RASENGAN • THE CLONE WAS BROKEN », pas de poussée.
10. **Z + R à ~18 studs** : le kunai part, près de l'adversaire il éclate en fumée, un clone saute sur le flanc et frappe ; avec deux clones dehors : kunai renforcé (gaine bleue).
11. **X après un coup reçu, un clone dehors** : Naruto réapparaît à la place du clone, fumée là où il était frappé, « SUBSTITUTION • IT WAS A CLONE! », pas de bûche ; sans clone : la bûche habituelle.
12. **Éveil** : éclat rouge-orangé, les clones éclatent en fumée rosée, queue de chakra rouge derrière les hanches, yeux rouges, manteau rouge ; 1 → « NINE-TAILS CHAKRA • NO CLONES » ; LMB puis A + LMB : griffe longue ; LMB, LMB, W + LMB : griffe montante ; 2 : Rasengan rouge presque instantané, sans clone.
13. **E (dash) verrouillé à ~20 studs, un clone sur un flanc** : arrivée sur un angle dont le côté varie d'un dash à l'autre ; le clone charge l'autre côté et frappe.
14. **Contre Naruto (bot)** : les clones ne projettent pas d'ombre, le vrai Naruto si ; pousser le stick vers un clone + LMB le dissipe (verrou et caméra restent sur Naruto) ; un kunai s'arrête dans un clone, la boule de feu d'Itachi le traverse et continue ; la Rotation de Neji efface les clones proches ; le bouclier de Gaara perd une charge par coup de clone.
15. **Endurance** : `ai_soak.luau` avec `PAIRS={{"Legion","Sand"},{"Lion","Legion"},{"Legion","GentleFist"},{"Leaf","Legion"}}` → aucune erreur ni avertissement. Effet figé : `fx_freeze.luau` avec `TARGET="ClonePuff"`, `"RasenganForming"`, `"FoxTail"` ou `"UzumakiCall"`. Images par seconde avec deux clones + rafale (quatre copies) : `fps.luau`.

## Risques et limites

- Rien n'a été vu en Studio : copie client du modèle (`Clone` côté client d'un modèle répliqué, racine ancrée, articulations posées), lissage des clones, fumées, caméra ; coût d'une copie (~80 pièces, réserve de 4).
- Les clones sont des points au sol : ils traversent arbres et rochers, ne montent pas sur la corniche (un adversaire en hauteur est hors de portée de leurs coups).
- Équilibre non jugé (8/12 en duels IA d'une graine) ; Gaara le bat dans les deux ordres (bouclier).
- `Combat.luau`, `Brawler.luau`, `AI.luau` restent les fichiers les plus disputés : crochets courts mais à revérifier à chaque fusion (agents Temari, chakra, CORE4 en parallèle).
- Non implémenté (fiche) : sursaut de chakra à 0, rugissement et armure du manteau, tenue aux jambes, tunnel, écho des frappes par le clone leurre.
