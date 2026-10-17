> Snapshot historique avant harmonisation des fiches le18/10/2026. Conserver les idées et preuves ; état/priorités dans docs/active, nouvelle fiche au chemin d’origine.

> Documentation spécialisée de référence ; état dans [CURRENT_STATE](../../../active/CURRENT_STATE.md), travail et critères dans [MASTER_BACKLOG](../../../active/MASTER_BACKLOG.md). Les anciennes propositions et statuts ci-dessous ne fixent pas les priorités globales.

# Sasuke — jeune prodige

Code : `Lion`. IDs : CHR-SAS-001/002, CHR-CORE-001/002. Les données réelles viennent de Fighters/MoveGraphs/Attacks et [inventaire](../../../current/COMBAT_INVENTORY.json) ; le label lore n’est pas automatiquement prouvé par le nom du move.

## Expression visée

Agressif, kicks/rotations, poursuite air et pression mix-range. Fil et DragonFlame convertissent un contexte, Chidori garde engagement/récupération lisibles. Certains clips héritent de Flashstep ; la spécialisation doit servir le corps, pas quantité de variants.

## Conversions à rechercher, pas à ajouter aveuglément

Launch→AirPursuit→RotationalStrike→GroundSpike ; wire→DragonFlame→reentry ; angle kick→side switch→disengage. Protéger routes et nettoyages existants.

Pour chaque exemple : source/âge/scene/timecode, label lore, état initial/contact/réaction/résultat/followup, brique commune et expression spécifique, input/camera/air/wall/risque. Vérifier d’abord si le code satisfait déjà l’intention. Lire le blueprint complet dans [ROSTER_MOVESETS_10_PRODIGIES](../../../characters/ROSTER_MOVESETS_10_PRODIGIES.md) et les passages propres à Sasuke dans [CLAUDE_FINAL_PASS](../../missions/CLAUDE_FINAL_PASS.md).

## Validation

Baseline native + garde/course/strafe/dash/jump, contact/defense/throw/outil/jutsu/air/mur/KO ; duel contre les quatre IA et manette. Même scénario avant/après ; motion/export sélectionné par Claude, contrats/costs/timings protégés. Reconnaissance de Sasuke sans jutsu ; vérifier jeunesse et contre-jeu. Un headless PASS technique ne clôt pas cette identité visuelle.

## Fiche FIGHTER_TEMPLATE — audit 2026-10-16

> Audit Claude du 2026-10-16 (CHR-CORE-001/002, bloc 4 du plan approuvé le 2026-10-14). Décrit le code réel de `claude/ninja-duel-2026-10-14` ; les références `fichier:ligne` ont pu glisser avec les correctifs du bloc 3 (`f93d866`) — le nom de fonction fait foi. Les sources canon marquées « à vérifier » ne sont pas confirmées. Les propositions sont des candidates, non implémentées ; les labels REJECT_ADULT_ONLY signalent un écart code ↔ décision DEC-005 à trancher, pas un changement fait.

Rédigée le 2026-10-16 à partir du code réel, sans modification du dépôt.

Légende :
- **EXISTE** : présent dans le code (`fichier:ligne`).
- **MANQUE** : écart au gabarit.
- **DÉCISION** : absence volontaire proposée, à confirmer car non tracée dans `DECISIONS.md`.

Les dégâts sont bruts. Il faut encore appliquer `CombatDamage` 1.05 et le scaling de combo : 2 coups pleins, puis −12 % par coup, plancher 35 %, 11 coups maximum (`Config.luau:17`).

⚠ `Combat.luau`, `Brawler.luau` et `VelmoraDefense.luau` étaient modifiés en parallèle pendant la lecture (2026-10-16, 00:12–00:15). Leurs numéros de ligne sont indicatifs : les noms de fonction font foi.

### 1. Identité
- **EXISTE** (`Fighters.luau:94-122`) : Sasuke Uchiha, `Age = 12`, « THE ROOKIE OF THE YEAR ». Stade retenu : l'examen chûnin (commentaire `:94-97`).
- **Profil** : rôle de rushdown acrobatique mix-range, rythme rapide et impulsif, `PreferredRange = 6` (lu par `AI.luau:85`).
- **Forces** : il convertit une ouverture en séquence verticale, garantit des dégâts avec fil→feu et fait peser la menace du Chidori.
- **Faiblesses** : c'est le corps le plus fragile du noyau (`Health 120`, contre 125/145/135). Sa réserve de chakra est de 105 et son Chidori est punissable.
- **Signature** : LionKick → ShadowLeaf (chasse gratuite) → Lion Combo (`MoveGraphs.luau:57-66` ; `Brawler.routePayoff`, branche `shadowLeaf`).
- **Question à laquelle répond son gameplay** : « une seule ouverture suffit-elle ? » Il mise tout sur la conversion et paie chaque engagement raté.
- **Intro** : mains dans les poches (`VelmoraMotionEngine.luau:1709-1711`).
- **MANQUE** : aucun label lore dans le code ni dans la spec. Voir la table plus bas (CHR-CORE-002, PARTIAL).

### 2. Mouvement
- **EXISTE** : **Stance** `STANCE.Lion` (`VelmoraMotionEngine.luau:257-260`) : position basse (y −.5, pitch 10, yaw 30), main avant sortie, main arrière au menton, tempo 7. **Gait** « springy », partagé avec Minato (`:263`). `GAIT.Lion` (`:1062`) : stride 1.08, cadence 1.02, arm 44, lean 6, bob 1.05, guard .15. C'est très proche de Minato (1.12/.98/50/5/1.15/0). **Vitesses** (`Fighters.luau:102`, `Config.luau:39-45`, `Place1Movement.luau:7-16`) : marche 19, sprint 45×1.1 = 49.5, accélération au sol ≈ 190 ; saut 58×1.15 ≈ 66.7, le plus haut des quatre ; accélération en l'air ≈ 87. **Dodge** directionnel : 14×1.08 ≈ 15 studs en .32 s (`BanglaEvade.luau:7-8`). **Running taijutsu** commun : au-delà d'une vitesse de 30, le strike devient FlyingKick et le heavy SlideSweep (`Brawler.request`, bloc « Running taijutsu »). Les clips Lion viennent de `runningClips` (`VelmoraMotionEngine.luau:561`). **Mur** : wall run et WallDive appartiennent au système commun (`Config.luau:33-37`).
- **MANQUE** : Ni strafe, ni changement d'appui, ni landing propres (MOV-003/005). Pas d'entrée ni de sortie de mur identitaires. Le seul mouvement signature est ShadowLeaf (§9).

### 3. Neutral / entrée en combat
- **Fermer la distance** : Rush : 10 de chakra, entre 7 et 48 studs, CD .9 (`Config.luau:20`). Il débouche sur un DashAttack (flying knee Lion, `VelmoraMotionEngine.luau:690`). Sprint → FlyingKick.
- **Tenir la distance** : Paire de shuriken : 4 de chakra, 92 studs/s, portée 62, recover .6. Phoenix Flower. Lane brûlante d'un Great Fireball raté : rayon 7.5 pendant 3.2 s (`Combat:fireExplosion`).
- **Forcer une réaction** : Phoenix : 5 flammes re-visées sur la cible et 2 lames cachées, ce qui force un pas de côté. WireTrap (34 studs) : sans garde ni esquive, la cible est Bound.
- **Poke** : Light1 (startup .081, portée 6).
- **Feintes** : Feinte de Heavy : commune, 4 de chakra. Feinte de Great Fireball (`Feintable`) : 35 % du coût remboursé si elle intervient avant la mi-canal (action `Feint` dans `Combat:request`).
- **Sortie** : arrière+Tool dans un string déclenche un disengage. C'est un hop de 6 studs couvert par 2 shuriken (`Brawler.disengage:111`), avec les mêmes paramètres que chez Itachi.
- **À respecter par l'adversaire** : 2 coups propres + avant = LionKick. Une recovery entre 4 et 16 studs = Chidori (règle IA, `AI.luau:263`).
- **MANQUE** : Aucun outil de lecture au neutral : le Sharingan n'a pas de bouton. Le disengage est un clone de celui d'Itachi.

### 4. Taijutsu et combos
| Entrée | Move (clip) | Startup / Active / Recovery (s) | Dégâts | Réaction | Fonction |
|---|---|---|---|---|---|
| Strike 1 / 2 / 3 | jab / roundhouse / spinning heel kick (Lion) | .081/.12/.266 · .095/.12/.27 · .126/.14/.24 | 5 / 10 / 18 | HitStun, HitStun, Knockback | opener, pression, ender (`Fighters.luau:112`, `BanglaCombo.luau:25`) |
| Heavy | front kick (Lion) | .30/.17/.52 | 14 | Knockdown | punition |
| ≥ 2 coups + avant | **LionKick** (Lion) | .15/.14/.28 | 8 | Launched Y50, 1.25 s | launcher, déclenche ShadowLeaf (`Attacks.luau:56`) |
| ≥ 2 coups + arrière | Sweep (Lion) | .12/.14/.34 | 7 | Knockdown | route basse |
| ≥ 1 coup + côté | **VaultKick** (Lion) | .12/.12/.24 | 7 | HitStun, orbit 50 | passe de l'autre côté (> 100°) sans casser la chaîne (`Attacks.luau:57,113`) |
| Heavy après 1 coup | KneeStrike (**clip Minato**) | .08/.12/.30 | 7 | Juggled | relance au sol |
| Heavy après ≥ 2 coups | Launcher générique (**clip Minato**) | .17/.14/.28 | 8 | Launched Y58 | **ne déclenche pas** ShadowLeaf |
| Air 1/2, air ↑/↓/côté | Air1, Air2, AirDrive, AirSpike, AirSwitch (**clips Minato**) | ≈.074–.10 / .12–.14 / .18–.24 | 6–7 | Juggled / Knockback / Spiked | grammaire air commune |
| Heavy en l'air | Slam (**clip Minato**), ou **LionBarrage** pendant `lionUntil` | .15/.20/.38 | 11, ou 17 | Knockdown, impulse −90 | finisher (`Brawler.request`, bloc Lion Combo) |
| Sprint + strike / heavy | FlyingKick / SlideSweep (Lion) | .10/.16/.32 · .12/.18/.38 | 9 / 8 | Knockback / Knockdown | entrée |
| Riposte | Light1 (Lion) | .05/.12/.26 | 8 | HitStun | après un block (.34 s) ou un perfect dodge (.5 s) |

- **Cancels** : La chaîne ne continue que sur un hit propre (`chainOpen`, dans `Combat.updateActor`). `stringCancels={Chidori=true}` : le canal du Chidori tombe à .14 s. Tool-cancel gratuit (recover .42, portée 20). `blockCancels={}` : après un string bloqué, il ne reste que le dodge. Flow commun : ×1.15. Grab et throw sont communs, avec des clips Minato.
- **MANQUE** : Deux launchers coexistent, et seul LionKick déclenche ShadowLeaf. Le LionBarrage est un coup unique (un Slam re-paramétré), pas un barrage. 12 des 22 actions du mapping (25 en comptant ChidoriThrust, FlyingKick et SlideSweep) jouent un **clip Flashstep hérité**. Cause : `setmetatable(CLIPS.Lion,{__index=CLIPS.Flashstep})` (`VelmoraMotionEngine.luau:729-731` ; `MOTION_ATTACK_MAPPING.md:71-92`). Clips concernés : Launcher, KneeStrike, Air1, Air2, Slam, AirDrive, AirSpike, AirSwitch, Grab, Throw, ThrowUp, WallDive. Le timing de LionBarrage reprend celui d'`Attacks.Slam` (`:860`). Suivi : CHR-SAS-002.
- **DÉCISION possible** : pas de grab identitaire.

### 5. Armes et ninja tools
- **EXISTE** : `ToolMastery={Kind="shuriken", Count=2, Speed=92, Damage=2, Recover=.6}` (`Fighters.luau:104-106`). Lancer neutre : 4 de chakra, portée 62. Lancer en chain-cancel : gratuit, portée 20. En l'air, 2 lames (pas d'`AirSpread`). Une lame sur un corps en WallSplat prolonge le pin de .34 s (`Combat:projectileHit`, règle générique). Le fil passe par WireTrap (§6). Le Phoenix cache 2 shuriken (`Elements.luau:48-57`). Aucune arme de mêlée : `MELEE.Lion={}` (`VelmoraMotionEngine.luau:1526`). Le shuriken n'est visible que tenu en main ou pendant le canal du WireTrap (`:1602-1603`).
- **DÉCISION implicite à confirmer** : pas de kunai, pour se distinguer de Minato et de Neji.
- **MANQUE** : Pas d'outil planté. Pas de collision projectile contre projectile (DEF-005). Pas de tool→pursuit spécifique (TOOL-005, PARTIAL).

### 6. Jutsus / techniques
Sources : `Fighters.luau:117-120`, `Techniques.luau`, `Elements.luau`.

| Technique | Coût | Canal / Actif / Rec. | CD | Portée, vitesse | Dégâts | Comportement réel | Contre-jeu |
|---|---|---|---|---|---|---|---|
| Great Fireball (`FireBloom`) | 24 | .5 / .4 / .36 | 5.5 | 70, 58 | 15 | boule qui grossit, knockback ; un raté laisse un hazard (rayon 7.5, 3.2 s, 45 %) ; feintable | pas de côté puis punition de la recovery ; garde ou parade (projectile dévié) |
| → **Dragon Flame** (cible Bound par son fil) | 24 | canal .16 | 5.5 | — | 15 directs | aucun projectile, impossible à esquiver ; Knockdown .8 s (`Techniques.luau:299-318`, wireCancel dans `Combat:request`) | substitution pendant le Bound ; bloquer le fil en amont |
| Phoenix Flower | 20 | .28 / .32 / .3 | 5 | 56, 72 | 4×5 + 2×2 | flammes toutes les .06 s, décalages ±5/±2.5 ; lames à .21 et .28 s ; zone de feu de 3.4 pendant 1.8 s (`Elements.luau:32-59`) | grand pas latéral, garde |
| Wire Trap | 18 | .18 / .08 / .3 | 6 | 34, 86 | 3 | Bound pendant 1.0 s si le coup n'est pas gardé (`Techniques.wireBind:328`) | garde (le fil ne lie pas sur une garde), dodge, substitution |
| Chidori | 34 | .62 (déplacement limité à 7 studs/s, interruptible), puis ChidoriThrust .04 / .26 / .62 | 9 | course ≈ 17 (15×1.12), hitbox 7×4.5 | 22 | Knockback (0,12,70) ; string-cancel à .14 (`Techniques.luau:338-349`, `Attacks.luau:58,114`) | interrompre la charge (InterruptStun .42), pas de côté ; un raté reste ouvert ≥ .45 s (`Sasuke.spec.luau:87-107`) |

- Les quatre techniques ont `Interruptible=true`.
- `Range=20` du Chidori n'est pas lu par `execute`. À mesurer en natif.
- **MANQUE** : Pas de « shuriken pressure action » dédiée, alors que le blueprint en prévoit une. Les poses de cast Fire et Phoenix sont identiques à celles d'Itachi (`castSpec`, `VelmoraMotionEngine.luau:986-1003`). Le Lion Combo est une route et non une technique. C'est conforme à DEC-006.

### 7. Garde / défense
- **EXISTE** : **Garde commune** : stamina 100, −9 par coup bloqué, dégâts ×.24, −12/s tant qu'elle est tenue, guard break de .65 s (`VelmoraDefense.luau`). **Garde et chakra** : un Heavy ou un Slam bloqué coûte 25 de chakra ; à 0, GuardStun de .6 s (`Brawler.hit`, code en cours de modification). **Sharingan 2 tomoe** (`Fighters.luau:108`) : fenêtre de parade .24 (base .20) ; perfect dodge .18 (base .13) ; `Counter .7` ; la garde suit un téléport pendant .7 s (`Combat:damage`, « Sharingan tracking »). **Wall tech** commun.
- **MANQUE** : `counterUntil` est **sans effet pour le joueur**, car `MoveGraphs.Lion` n'a pas de `readCounter`. Seule l'IA l'utilise (`AI.luau:178`). Pas d'anti-air dédié. `GuardStrength=0.08` n'est lu nulle part. Pas de clash d'armes.

### 8. Esquive et substitution
- **Dodge** : 10 de chakra, CD .8, durée .32 s, i-frames .22, environ 15 studs ; un seul air dodge par phase aérienne ; perfect dodge (.18) : ×1.35 sur le coup suivant (.8 s) et fenêtre de riposte de .5 s.
- **Kawarimi générique** (`Combat:substitute`, mode `hop`) : coût et charges : 15 de chakra, 2 charges, recharge 9 s, CD 1.1 ; utilisable dans les .42 s qui suivent un coup reçu ; hop de 8 studs à l'opposé de l'attaquant, glissement le long d'un mur ; l'attaquant peut traquer la réapparition avec E pendant .75 s.
- **MANQUE** : pas de variante propre. Minato réapparaît sur un sceau, Itachi en corbeau ; Sasuke fait un simple hop.

### 9. Rush / poursuite
- **Pursuit commune** : 8 de chakra, fenêtre de 1.15 s après un Launched, portée 46.
- **ShadowLeaf** (`Brawler.routePayoff`) : .12 s après un LionKick, si la cible est encore Launched ou Juggled, une Pursuit **gratuite** se déclenche (chakra remboursé, fonctionne même à 0). Sasuke reste collé derrière et sous le corps pendant .5 s (`Combat.updateActor`, `shadowUntil`) ; `airHold` 1.1 s. Pendant `lionUntil` (2.1 s), le Heavy le replace au-dessus de la cible : c'est le LionBarrage.
- **Contre-jeu** : substitution, air dodge, ou sortie de l'état Launched avant .12 s.
- **MANQUE** : poursuite assistée par outil (traction du fil) et re-entry après un disengage.

### 10. Chakra
- **EXISTE** : réserve de 105, regen de 7.5/s. La regen s'arrête pendant les canaux et les stuns.
- **Coûts** :

| Action | Coût |
|---|---|
| Dodge | 10 |
| Outil | 4 |
| Pursuit | 8 |
| Rush | 10 |
| Substitution | 15 |
| Wall tech | 12 |
| Great Fireball | 24 |
| Phoenix Flower | 20 |
| Wire Trap | 18 |
| Chidori | **34** (32 % de la réserve) |
| Fil + Dragon Flame | 42 |

- **MANQUE** : Pas d'état low-chakra côté joueur ; seule l'IA recule sous 18 (`AI.luau:243`). Suivi : SYS-001. Aucune spécialité déclarée. Spécialité de fait : la route ShadowLeaf ne coûte rien.

### 11. Infusion / interactions de chakra
- **EXISTE** : fil + Katon + cible Bound → Dragon Flame ; shuriken + Katon → lames cachées ; corps + Raiton → ChidoriThrust ; feu + sol → hazards.
- **DÉCISION recommandée** : pas de foudre transmise par le fil. Cela évoque le Chidori Nagashi et la Partie 2 (à vérifier).
- **MANQUE** : pas de système général (TOOL-006, SYS-002).

### 12. Éveil — CURSE MARK
Sources : `Fighters.luau:110`, `Combat:awaken`, `Combat.updateActor`.

- **Condition** : PV ≤ 35 % (42 PV). Une seule fois par **match** : `awakened` n'est jamais remis à zéro.
- **Activation** : +40 de chakra, cooldowns remis à zéro, .45 s d'invulnérabilité. Si l'adversaire est à moins de 9 studs, il est repoussé (knockback 34).
- **Durée : 12 s** : vitesse ×1.15, dégâts ×1.18, regen ×1.3 ; cooldowns ×0.6 (le Chidori revient en 5.4 s) ; **drain de 1.4 PV/s, sans pouvoir tuer** : 16.8 PV au maximum (14 %).
- **Visuel** : manteau générique violet (`Effects.luau:893`).
- **MANQUE** (SYS-003) : l'éveil reste purement numérique, avec un risque. Ce que promet le blueprint (`ROSTER_MOVESETS_10_PRODIGIES.md:278-287`) n'existe pas : enders modifiés ; Chidori renforcé ; routes feu/foudre amplifiées.

### 13. États et réactions
- **États créés**

| État | Source |
|---|---|
| HitStun | L1, L2, VaultKick |
| Knockback | L3, ChidoriThrust, AirDrive, Fireball |
| Knockdown | Heavy, Sweep, LionBarrage, Dragon Flame, SlideSweep |
| Launched | LionKick, Launcher |
| Juggled | KneeStrike, attaques aériennes |
| Spiked | AirSpike |
| **Bound** | WireTrap, 1.0 s |
| Interrupt, WallSplat, Grabbed | systèmes communs |

- **États exploités** : Launched → ShadowLeaf → LionBarrage. Bound → Dragon Flame. L'IA tente aussi le Chidori sur une cible Bound. Recovery adverse → Chidori.
- **MANQUE** : pas de GuardOpen ni d'OffBalance, pas de perturbation de ressource.

### 14. Boucle de jeu
- **Représentative** : `paire de shuriken (probe) → pas de côté forcé → rush → jab → roundhouse → ↑ LionKick → ShadowLeaf (gratuit) → Air1 → Heavy = Lion Combo → Knockdown → Phoenix sur le relevé`.
- **Agressive**, deux variantes : `Phoenix → l'adversaire bouge → Wire Trap → Bound 1 s → Dragon Flame (canal .16) → Knockdown → rush` ; `jab → roundhouse propre → Chidori en string-cancel (.14)`.
- **Défensive** : `garde fraîche → parade Sharingan (.24) → riposte jab → roundhouse → VaultKick → arrière+Tool (hop + 2 shuriken) → neutral`.
- **Low-chakra** : `sprint → FlyingKick (0 chakra) → jab → roundhouse → LionKick → ShadowLeaf (gratuit) → Lion Combo`. Pas de dodge (10) ni de substitution (15) ; le chain-tool reste gratuit.
- **Air / mur** (communs, validation N en natif à faire) : `wall run → WallDive → carry → WallSplat → shuriken (pin +.34 s) → string` ; `LionKick près d'un mur → ShadowLeaf → AirDrive vers le mur → WallSplat`.

### 15. Skill ceiling
- **Débutant** : enchaîne L1–L3 et lance le Fireball ou le Chidori à distance. Il se fait punir sur la recovery de .62 et vide ses 105 de chakra.
- **Intermédiaire** : lance « 2 coups propres + avant » ; place le Heavy dans les 2.1 s de `lionUntil` ; déclenche le Dragon Flame pendant la seconde de Bound ; ne lance le Chidori qu'en string-cancel ou sur une recovery ; utilise le disengage.
- **Expert** : Flow timing (−.07/+.13 s) ; feinte de Fireball pour appâter un dodge avant le fil ; parade à .24, perfect dodge à .18 ; garde 34 de chakra pour punir, ou 42 pour fil+feu ; utilise le VaultKick pour orienter le carry vers un mur ; traque la substitution adverse (E dans les .75 s) ; déclenche le Curse Mark quand il peut se permettre 16.8 PV de drain.

### 16. Signature irremplaçable
Sasuke est le seul du noyau à :
1. convertir une ouverture en séquence aérienne **sans payer de chakra** (ShadowLeaf) ;
2. transformer un outil en **garantie élémentaire** : fil → Dragon Flame impossible à esquiver ;
3. porter l'engagement le plus lourd (Chidori, 34 de chakra, au moins .45 s d'ouverture s'il rate) sur le corps le plus fragile (120 PV), avec un éveil qui le blesse.

Avec d'autres jutsus, il garderait LionKick, ShadowLeaf, LionBarrage et VaultKick. **Limite** : sans jutsu, il reste à moitié Minato (même famille de gait et 12 clips hérités). CHR-CORE-001 n'est donc pas atteint visuellement.

### Exigence de différenciation
| Axe | Minato `Flashstep` | Itachi `Mirage` | Neji `GentleFist` | Sasuke `Lion` |
|---|---|---|---|---|
| Neutral | 1 kunai, sceaux, angles | portée 10, Geometry, Read | portée 5, paumes, Rotation | portée 6, 2 shuriken rapides, Phoenix, fil |
| Mouvement | 19.5, sprint ×1.12, springy | 18, contrôlé | 18.5, pas courts | 19, sprint ×1.1, **saut ×1.15**, springy proche de Minato ⚠ |
| Silhouette taijutsu | coupes au kunai | paumes, feinte | paumes, rotation | **coups de pied** |
| Launcher | sceau sur le corps | lames de couverture | Launcher simple | LionKick + ShadowLeaf |
| Poursuite | téléport sur sceau | commune | commune | ShadowLeaf collée et gratuite |
| Mur | sceaux de surface | les lames prolongent le pin | VacuumPalm vers le mur | **commun seulement** (MANQUE) |
| Air | RasenganDrop | éventail de 3 lames | commun | Lion Combo |
| Outils | kunai marqués | Geometry, Ricochet | kunai secondaires | fil, lames cachées |
| Chakra | 110 / 8 | 125 / 7.2, CostScale | 115 / 7.6, drain | 105 / 7.5, coûts lourds, route gratuite |
| Défense | substitution vers le sceau | Sharingan .30/.22 + readCounter, corbeau | Byakugan, Rotation | Sharingan .24/.18 **sans** readCounter, hop |
| Éveil | CD ×.4 | Windows ×1.5 | NoBlindSpot, Drain ×1.8 | stats + drain de PV |
| Règle tordue | FTG | genjutsu, Read | tenketsu | chasse gratuite, feu garanti, Chidori en cancel |

Risques de recouvrement : le feu est partagé avec Itachi (mêmes `Elements`, mêmes poses) ; le corps et la marche sont partagés avec Minato.

### Labels lore par capacité
| Capacité (code) | Label | Justification / source canon (âge) |
|---|---|---|
| Jab / roundhouse / heel kick | PLAUSIBLE_YOUNG | taijutsu à base de coups de pied, cohérent avec la Partie 1 ; les formes exactes ne sont pas canon |
| LionKick + ShadowLeaf | CANON_YOUNG | Konoha Kage Buyō copié de Lee au Sharingan, utilisé contre Yoroi Akadō aux éliminatoires chûnin (12 ans) ; chapitre et épisode à vérifier |
| LionBarrage | CANON_YOUNG / GAMEPLAY_LIBERTY | Shishi Rendan, même scène ; la relocation au-dessus de la cible et le coup unique sont des libertés de lisibilité |
| Sweep, VaultKick | PLAUSIBLE_YOUNG | acrobaties plausibles ; scène précise à vérifier |
| KneeStrike, Launcher, attaques aériennes, FlyingKick, SlideSweep, grab, rush | PLAUSIBLE_YOUNG | grammaire commune ; l'entraînement de vitesse avec Kakashi avant la finale est à vérifier en détail |
| Shuriken, chain-cancel, disengage | CANON_YOUNG / PLAUSIBLE_YOUNG | shuriken Fūma contre Zabuza (Pays des Vagues) ; Sōfūsha contre Orochimaru ; les cancels sont plausibles |
| Wire Trap | CANON_YOUNG / GAMEPLAY_LIBERTY | Sōfūsha San no Tachi : Orochimaru attaché à un arbre (Forêt de la mort, 12 ans). Le bind d'une seconde sans point d'ancrage est une liberté (contre-jeu : garde, substitution, CD 6) |
| Dragon Flame | CANON_YOUNG / GAMEPLAY_LIBERTY | Katon Ryūka le long du fil, même scène. Le fait qu'il ne puisse pas rater est une liberté, payée 42 de chakra |
| Great Fireball (+ feinte) | CANON_YOUNG (+ GAMEPLAY_LIBERTY) | Gōkakyū au test des clochettes et contre Orochimaru ; la feinte est une liberté |
| Phoenix Flower + lames cachées | CANON_YOUNG, **à vérifier** | Hōsenka avec shuriken dans les flammes, contre Zaku sous le sceau (Forêt de la mort) ; sinon PLAUSIBLE_YOUNG |
| Chidori | CANON_YOUNG | appris de Kakashi pendant le mois d'entraînement ; utilisé en finale contre Gaara, chargé après une course sur le mur de l'arène (12 ans) |
| Chidori en string-cancel (.14) | GAMEPLAY_LIBERTY | le canon exige une charge ; compensé par 34 de chakra, un CD de 9 et un raté punissable |
| Sharingan (fenêtres, suivi des téléports) | CANON_YOUNG / PLAUSIBLE_YOUNG | éveillé contre Haku (Pays des Vagues) ; 2 tomoe pendant l'examen, 3 à la Vallée de la Fin (tomoe par scène à vérifier) ; le suivi des téléports est plausible |
| Sharingan toujours allumé (`Effects.luau:880`) | GAMEPLAY_LIBERTY | en Partie 1 il l'active volontairement ; choix de lisibilité |
| Curse Mark (niveau 1) | CANON_YOUNG / GAMEPLAY_LIBERTY | sceau d'Orochimaru (Forêt de la mort), activé contre Zaku, douleur pendant la finale ; drain, seuil et durée sont des libertés |
| Substitution | CANON_YOUNG | Kawarimi de l'Académie ; scène propre à Sasuke à vérifier |
| Wall run / WallDive | CANON_YOUNG / PLAUSIBLE_YOUNG | marche sur les arbres au Pays des Vagues, course sur le mur de l'arène contre Gaara |
| Absents (grep `src` et `tests` vide) : Mangekyō, Amaterasu, Susanoo, Kirin, Chidori Nagashi / Eisō (Sharp Spear) / Senbon, Kusanagi, invocations | REJECT_ADULT_ONLY | Partie 2 ; confirmés absents |
| Curse Mark niveau 2 | CANON_YOUNG, absent | Vallée de la Fin ; DÉCISION à prendre (transformation lourde) |

### Écarts code ↔ docs à signaler
- `FOUR_CHARACTER_COMBAT_MATRIX.md:13` annonce « Chidori/wire » pour le mur. Le code n'a rien de spécifique.
- `FOUR_CHARACTER_COMBAT_MATRIX.md:14-15` dit « pas de défense spécifique », alors que le `Sharingan` existe (`Fighters.luau:108`).
- `counterUntil` et `GuardStrength` sont morts pour le joueur.
- Le Heavy après 2 coups utilise le Launcher générique.
- Le `Range` du Chidori n'est pas utilisé.

### Propositions (candidates, non implémentées)
1. **`LauncherMove="LionKick"`** : le Heavy après 2 coups devient aussi Kage Buyō. Gain : supprime le doublon de launcher et un clip Minato. IDs : CHR-SAS-002, CHR-CORE-001. Contre-jeu : celui du LionKick (bloquable, .28 de recovery sur un raté). Label : CANON_YOUNG.
2. **Chidori depuis la course murale** : canal accroché au mur, puis descente en ligne droite. IDs : CHR-SAS-002, COM-004, MOV-005. Contre-jeu : charge visible et interruptible, pas de côté, 34 de chakra. Label : CANON_YOUNG (finale contre Gaara).
3. **Fil près d'un mur → pin contre la surface**. IDs : TOOL-003, TOOL-005, COM-004. Contre-jeu : garde, substitution, ne fonctionne que près d'un mur, CD 6. Label : CANON_YOUNG (Orochimaru attaché à un arbre).
4. **`readCounter="VaultKick"`** : une lecture Sharingan réussie mène à un changement de côté. `counterUntil` devient utile, et l'effet se distingue de la CounterPalm d'Itachi. IDs : CHR-SAS-002, DEF-001, DEF-003. Contre-jeu : fenêtres plus étroites que celles d'Itachi (.24/.18). Label : PLAUSIBLE_YOUNG.
5. **Curse Mark à règle** : pendant l'éveil, le chakra manquant est payé en PV (1 pour 1, sans pouvoir tuer), et le Chidori peut être annulé depuis un coup aérien. IDs : SYS-003, CHR-CORE-002. Contre-jeu : temporiser pendant les 12 s. Label : GAMEPLAY_LIBERTY appuyée sur l'état CANON_YOUNG.

### État — convergence 2 (identité, 2026-10-16)

Code de `claude/nd-ccc2-identity` ; détails, tests et poses demandées : [IDENTITY_JUTSU](../../reports/convergence2/IDENTITY_JUTSU.md). Validé en headless uniquement. Fil, feu et foudre : laissés à l'agent chakra.

- **Curse Mark = le flux change** :
  - le troisième coup et l'AirDrive ne lâchent pas (chancellement, la chaîne reste ouverte, une fois par échange) ;
  - tout lanceur devient la Danse de la feuille (chase gratuite, puis Lion Combo) ;
  - le drain double s'il ne touche plus et s'arrête après chaque coup porté ;
  - le corps maudit encaisse +12 % ;
  - dégâts ×1,12 au lieu de ×1,18.
- **MANQUE toujours** : posture maudite dédiée (pose demandée) et validation Studio.

Sources code lues : `src/Shared/` : `Fighters`, `MoveGraphs`, `Attacks`, `Config`, `Rules`, `BanglaCombo`, `VelmoraCombatConfig` ; `src/Server/` : `Techniques`, `Elements`, `Brawler`, `Combat`, `AI`, `VelmoraDefense`, `BanglaCombat`, `BanglaEvade`, `Motor` (extrait), `Place1Movement` (extrait) ; `src/Client/` : `VelmoraMotionEngine`, `Effects` (extraits) ; `tests/Sasuke.spec.luau` ; Docs : `FIGHTER_TEMPLATE`, `SASUKE`, `CORE_ROSTER`, `DECISIONS`, `FOUR_CHARACTER_COMBAT_MATRIX`, `ROSTER_MOVESETS_10_PRODIGIES` (§4), `MASTER_BACKLOG` (extraits), `MOTION_ATTACK_MAPPING`, `COMBAT_INVENTORY.json` (Lion), `CLAUDE_FINAL_PASS` (§10C).
