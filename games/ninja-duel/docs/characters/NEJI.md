# Neji — jeune prodige

Code : `GentleFist`. IDs : CHR-NEJ-001/002, CHR-CORE-001/002. Les données réelles viennent de Fighters/MoveGraphs/Attacks et [inventaire](../current/COMBAT_INVENTORY.json) ; le label lore n’est pas automatiquement prouvé par le nom du move.

## Expression visée

Paumes précises, défense circulaire, contrôle de distance/appuis et pression des tenketsu. Rotation a appui/centre ; paumes ne ressemblent pas à des punches génériques. Certains clips air/throws héritent de Mirage : héritage préservé, qualité Neji encore à juger.

## Conversions à rechercher, pas à ajouter aveuglément

RedirectDefense→OutsideStep→PrecisionCounter ; palm pressure→déplacement→conversion ; air/throw→réception circulaire. Pas remplacer inheritance avant preuve qu’il nuit à l’identité.

Pour chaque exemple : source/âge/scene/timecode, label lore, état initial/contact/réaction/résultat/followup, brique commune et expression spécifique, input/camera/air/wall/risque. Vérifier d’abord si le code satisfait déjà l’intention. Lire le blueprint complet dans [ROSTER_MOVESETS_10_PRODIGIES](ROSTER_MOVESETS_10_PRODIGIES.md) et les passages propres à Neji dans [CLAUDE_FINAL_PASS](../archive/missions/CLAUDE_FINAL_PASS.md).

## Validation

Baseline native + garde/course/strafe/dash/jump, contact/defense/throw/outil/jutsu/air/mur/KO ; duel contre les quatre IA et manette. Même scénario avant/après ; motion/export sélectionné par Claude, contrats/costs/timings protégés. Reconnaissance de Neji sans jutsu ; vérifier jeunesse et contre-jeu. Un headless PASS technique ne clôt pas cette identité visuelle.

## Fiche FIGHTER_TEMPLATE — audit 2026-10-16

> Audit Claude du 2026-10-16 (CHR-CORE-001/002, bloc 4 du plan approuvé le 2026-10-14). Décrit le code réel de `claude/ninja-duel-2026-10-14` ; les références `fichier:ligne` ont pu glisser avec les correctifs du bloc 3 (`f93d866`) — le nom de fonction fait foi. Les sources canon marquées « à vérifier » ne sont pas confirmées. Les propositions sont des candidates, non implémentées ; les labels REJECT_ADULT_ONLY signalent un écart code ↔ décision DEC-005 à trancher, pas un changement fait.

Gabarit : `docs/characters/FIGHTER_TEMPLATE.md`. IDs : CHR-NEJ-001 (DONE technique), CHR-NEJ-002 (OPEN), CHR-CORE-001/002 (PARTIAL), SYS-003, DEF-002/003.
Convention : **Existe** = lu dans le code (chemins relatifs à `games/ninja-duel/`) ; **MANQUE** = exigence du gabarit non couverte ; **DÉCISION** = absence volontaire *documentée* (source citée). « DÉCISION proposée » = choix non encore approuvé (DECISIONS : aucune approbation inventée). Timings = valeurs effectives après `AttackProfile` (concordent avec `docs/current/MOTION_ATTACK_MAPPING.md:51-70`). Aucun verdict visuel : tout reste N (natif) à valider.
Lignes relevées le 2026-10-16 vers 00:15 ; `Combat.luau` et `Brawler.luau` étaient modifiés en parallèle pendant la lecture (pas de changement de comportement Neji constaté) : revérifier les numéros avant usage.

### 1. Identité
- **Existe** (`src/Shared/Fighters.luau:64-93`) : « THE HYUGA GENIUS », 13 ans, examen chûnin. Health 135, Chakra 115, ChakraRegen 7.6, Speed 18.5, Sprint 1.0, Jump 0.98, AirControl 0.95, Accel 1.02, CombatDamage **0.95** (le plus bas des quatre), GuardStrength 0.1, **PreferredRange 5** (le plus court des quatre).
- Rôle : déni technique / contrôle au contact (`docs/characters/ROSTER_MOVESETS_10_PRODIGIES.md:595`). Rythme : contrôlé, coups courts, peu de déplacement. Force : chaque contact attaque la ressource adverse ; défense circulaire. Faiblesse : portée et mobilité moyennes, outils faibles, angle mort arrière, Rotation à long cooldown.
- Signature mécanique : Gentle Fist (`Fighters.luau:80`, `src/Server/Brawler.luau:431-439`) : drain de 6 chakra par coup propre, 3 à travers la garde, fermeture d’un tenketsu (max 4, −15 % de régénération par point, 5 s).
- Question unique : *« Combien de chakra peux-tu encore perdre avant de ne plus pouvoir te défendre ? »*
- Labels lore : voir la table dédiée plus bas (CHR-CORE-002).

### 2. Mouvement
- **Existe** : stance de profil, basse, paume avant tendue (`src/Client/VelmoraMotionEngine.luau:252-256`) ; famille de gait « contrôlée » partagée avec Itachi (`:262-264`) ; GAIT `stride .84, cadence 1.12, arm 16, lean 0, bob .55, guard .8` (`:1061`) = pas courts et rapides, garde portée en marchant ; la main avant reste en garde à basse vitesse (`:1276-1279`) ; intro « deux doigts aux yeux » (Byakugan, `:1712-1715`). Run, sprint, jump, wall-run et dash : API commune Motor/Place1 (`docs/FOUR_CHARACTER_COMBAT_MATRIX.md:8`).
- **MANQUE** : aucun mouvement signature hors combo (CircleStep n’existe qu’à l’intérieur d’une chaîne, `Attacks.luau:48,110`) ; pas de strafe/pivot propre ; entrée/sortie de mur sans interprétation Neji ; WallDive avec clip Mirage hérité. Jugement natif des appuis : N (CHR-CORE-001).

### 3. Neutral / entrée en combat
- Poke principal : Light1 paume avant, 0.083/0.12/0.252 s, portée 6.4 (`Fighters.luau:82`, `Attacks.luau:9`). Fermeture : Rush commun (coût 10, 48 studs max, min 7, CD 0.9 ; `src/Shared/Config.luau:20`) puis DashAttack « paume glissée » (0.066/0.15/0.27 s, `Brawler.luau:167`). Mi-distance : Vacuum Palm (portée 32).
- Maintien de distance / sortie : disengage Kunai (stick arrière + outil dans une chaîne, `src/Shared/MoveGraphs.luau:46`, `Brawler.luau:111-124`) ; knockback de PalmThrust / Vacuum Palm.
- Forcer une réaction : la menace de drain à travers la garde (bloquer n’est plus gratuit) ; quand Rotation est prête, frappes et projectiles à 7–8.5 studs deviennent risqués.
- À respecter avant le premier combo : garde Byakugan qui couvre les flancs (`src/Server/Combat.luau:163-166`) → les angles (FTG de Minato, Geometry d’Itachi) ne passent que dans l’arc arrière (~±26°, `BlindSpot .9`).
- **MANQUE** : outil de feinte propre (seule la feinte de Heavy commune, `Combat.luau:564-569`) ; pas de lecture active (Itachi a Read).

### 4. Taijutsu et combos
- **Existe** (`MoveGraphs.luau:44-56`, clips `VelmoraMotionEngine.luau:462-512, 575-593, 632-649`) :
  - Neutral : Light1 paume avant (5) → Light2 paume arrière (10) → Light3 double paume (18, Knockback impulseZ 54) (`src/Shared/BanglaCombo.luau:25`, `Fighters.luau:82-83`).
  - `up` (≥2 coups) : Launcher paume sous le menton (0.167/0.14/0.28, impulseY 56).
  - `down` (≥2) : Sweep rotatif bas (0.12/0.14/0.34, Knockdown) + payoff `tenketsu` = 2e point fermé (`Brawler.luau:330-332`).
  - `left/right` (≥1) : CircleStep (0.09/0.12/0.22, orbit 28, garde la chaîne).
  - Air : AirDrive double paume (Knockback 48), AirSpike paume descendante (Spiked −72), AirSwitch paume tournante (orbit 40) (`Brawler.luau:243-255`).
  - Heavy après 1 coup propre : PalmThrust (0.11/0.14/0.34, 10 dégâts, Knockback impulseZ 62) (`Brawler.luau:237`, `Attacks.luau:32`).
  - Finisher contextuel : avec ≥3 points fermés, Light3 devient PalmThrust (`Brawler.luau:285-287`).
  - Cancel : Vacuum Palm termine une chaîne propre (channel 0.18 → 0.14, `MoveGraphs.luau:52`, `Combat.luau:737`). `blockCancels={}` : rien sur coup bloqué.
  - Grab/Throw/ThrowUp, route mur (WallDive, splat/pin/bounce), pursuit, FlyingKick/SlideSweep en course : communs (`Brawler.luau:205-214`).
- **MANQUE** : frappes du bout des doigts / redirections du blueprint (`ROSTER_MOVESETS_10_PRODIGIES.md:186-197`) ; grab/catch identitaire ; **7 clips hérités de Mirage** via `setmetatable(CLIPS.GentleFist,{__index=CLIPS.Mirage})` (`VelmoraMotionEngine.luau:510-512`) : Air1 (genou), Air2 (crochet tournant), Slam (axe kick), Grab, Throw, ThrowUp, WallDive. À signaler (CHR-NEJ-002). Overlap structurel : PalmThrust occupe les mêmes slots `heavyAfterOne` + `readCounter` que CounterPalm d’Itachi (`MoveGraphs.luau:39,42` vs `51,55`).

### 5. Armes et ninja tools
- **Existe** : `ToolMastery = {kunai, Count 1, Speed 86, Damage 3, Recover .85}` (`Fighters.luau:72`) : la récupération la plus lente des quatre. Throw neutre : 4 chakra, portée 62 ; en cancel de chaîne : gratuit, portée 20, recover 0.42 (`Combat.luau:619-666`). Kunai visible seulement en main de lancer (`VelmoraMotionEngine.luau:1552-1556, 1596-1597`).
- **DÉCISION** : maîtrise volontairement absente (pas de Geometry/Ricochet/AirSpread/wire) parce que les outils doivent rester secondaires au Gentle Fist (`ROSTER_MOVESETS_10_PRODIGIES.md:41, 206` ; `FIGHTER_TEMPLATE.md:15`).
- **MANQUE** : tool→melee/pursuit propre, outil planté, interaction projectile spécifique (hors Rotation).

### 6. Jutsus / techniques
Trois techniques (Minato 5, Itachi 5, Sasuke 4) (`Fighters.luau:88-92`, `src/Server/Techniques.luau:427-507`).

| Technique | Coût | Channel / Active / Recovery | CD | Portée | Mouvement | Effet / conversions | Contre-jeu |
|---|---|---|---|---|---|---|---|
| Rotation | 24 | 0.04 / 0.55 / 0.24 (≈0.83 s engagé), non interruptible | 6 s | 7 (projectiles 8.5) | enraciné (`Combat.luau:818`) | invulnérable (`Combat.luau:157`, `Techniques.luau:433-434`) ; supprime les projectiles proches ; repousse l’adversaire une fois (6 dégâts, Knockback 48/18) ; s’il attaquait → contre 0.9 s → prochaine frappe = PalmThrust (`Combat.luau:1022-1052`, `Brawler.luau:257-258`) | ne pas s’engager, punir la recovery 0.24, rester hors 7–8.5 studs, attendre le CD de 6 s, lui vider le chakra (<24) |
| Vacuum Palm | 14 | 0.18 (0.14 en cancel) / 0.06 / 0.26 | 2.8 s | 32, vitesse 96 | interruptible | projectile `palm` (rayon 1.5, croissance 2.5), 7 dégâts, Knockback 54/12 → mur → splat (`Techniques.luau:439-450`, `Combat.luau:1112-1116`) ; **ne draine pas** | garde (pas de knockback), dodge latéral, interruption du channel |
| 64 Palms | 30 | 0.22 / 0.12 / 0.4 (0.7 si gardé, 0.85 si raté) | 10 s | 5 | Neji enraciné | paume d’ouverture gardable ; si elle passe : 7 frappes toutes les 0.15 s (dernière ×2.5), 8 drains, 4 points, **techniques scellées 3.5 s**, Knockback 46 (`Techniques.luau:451-507`) | garde, Rotation miroir, invulnérabilité, **substitution pendant le flurry** (test `tests/Neji.spec.luau:107-132`) |

- IA (`src/Server/AI.luau:35-37, 148-151, 224-227, 268-270`) : Rotation seulement réactive (55 % contre un projectile <11 studs, 30 % contre une frappe <6.5), jamais en neutral ; Vacuum Palm à 7–24 studs ou en fin de chaîne ; 64 Palms <4.6 studs sur Recovery/Stunned/channel adverse.
- Raison lore : voir la table des labels. **MANQUE** : interaction terrain/mur propre à Rotation ; « Chakra Seal » séparé et « defensive redirection counter » du blueprint non implémentés (`ROSTER_MOVESETS_10_PRODIGIES.md:209-214`).

### 7. Garde / défense
- **Existe** : garde Byakugan quasi-360° sauf l’arc arrière (`Fighters.luau:77`, `Combat.luau:163-166`) ; parry/perfect dodge communs (0.20 s / Bloodstep 0.13, `src/Shared/VelmoraCombatConfig.luau:4-11`) sans bonus Neji (Itachi 0.30/0.22, Sasuke 0.24/0.18) ; Riposte = clip Light1 (`VelmoraMotionEngine.luau:735`, `Brawler.luau:142-148`) ; counter = Rotation → PalmThrust ; anti-air de fait : Rotation contre dive/pursuit (l’état `Pursuit` compte comme attaque, `Combat.luau:1036`) ; guard break commun (chakra 0 → GuardStun 0.6, `Brawler.luau:487-498`) ; clash commun.
- **MANQUE** : déviation corporelle lisible propre (DEF-003) ; anti-air dédié hors Rotation ; défense en l’air/au mur propre.

### 8. Esquive et substitution
- **Existe** : dodge commun (10 chakra, CD 0.8, 0.32 s, i-frames 0.22 ; `Config.luau:8`) ; substitution commune (15 chakra, 2 charges, recharge 9 s, CD 1.1, fenêtre 0.42, 8 studs, suivi attaquant 0.75 ; `Config.luau:14`). Neji réapparaît en mode « hop » générique (`Combat.luau:392-454`), alors que Minato a le sceau et Itachi le corbeau.
- **MANQUE** : twist de substitution/esquive propre (la lecture/footwork annoncée par `FIGHTER_TEMPLATE.md:15`).

### 9. Rush / poursuite
- **Existe** : Rush et Pursuit communs (Pursuit 8 chakra, 46 studs, fenêtre 1.15 s après Launched ; `Config.luau:10`, `Brawler.luau:515`) ; knockback → « E TO CHASE » 0.8 s (`Brawler.luau:517-521`) ; wall splat → pursuit 0.8 s (`Brawler.luau:351-372`). Conversions Neji : PalmThrust / Vacuum Palm / AirDrive poussent vers le mur.
- **MANQUE** : poursuite propre (pas d’équivalent Shadow Leaf ou FTG) ; re-entry identitaire. Contre-jeu commun : substitution, wall tech (12 chakra), dodge.

### 10. Chakra
- **Existe** : réserve 115, régén 7.6/s (base 100/9), coupée en channel/stun (`Combat.luau:800-804`). Spécialité = **déni chez l’adversaire** : régén × max(0.2, 1 − 0.15 × points) → 4 points = 40 % ; le chakra drainé disparaît (aucun gain pour Neji). HUD : « CHAKRA POINTS −n×15 % » / « CHAKRA SEALED » (`src/Client/UI.luau:309-310`, `src/Server/Matches.luau:151-153`).
- Seuils exploités : substitution ≥15, dodge ≥10, technique ≥ son coût, garde >0 (`Combat.luau:396`, `:717`, `src/Shared/Rules.luau:13,34`).
- **MANQUE** : état low-chakra propre à Neji (comportement générique) ; aucun coût réduit ciblé (Itachi a CostScale à l’éveil).

### 11. Infusion / interactions de chakra
- **Existe** (formule `Objet + chakra + déclencheur → résultat`) : paume + chakra + contact → drain/tenketsu ; corps entier + émission + Rotation → dôme qui supprime les projectiles (kunai, shuriken, feu, fil, sable) ; paume + chakra + pression d’air → projectile `palm` qui porte au mur ; Byakugan + genjutsu → MirageCast annulé (`Techniques.luau:273-276`).
- **DÉCISION proposée** : pas de nature élémentaire ni d’infusion d’outil (aucune nature montrée pour Neji en Partie 1, à vérifier ; outils secondaires). **MANQUE** : infusion générale absente côté système (SYS-001, TOOL-006).

### 12. Éveil — BYAKUGAN FULL FIELD
- **Existe** (`Fighters.luau:74`, `Combat.luau:483-511`) : condition ≤35 % PV, 1×/match, 12 s (`Config.luau:22`) ; à l’activation : +40 chakra, cooldowns remis à zéro, 0.45 s d’invulnérabilité, onde Knockback 34 (<9 studs). Règles : **plus d’angle mort** (`Combat.luau:165-166`) ; **drain ×1.8** (10.8 propre / 5.4 gardé, `Brawler.luau:433`). Chiffres : Speed ×1.08, Damage ×1.06, Regen ×1.5, CD ×0.6.
- **MANQUE** : contrepartie/risque (Sasuke a HealthDrain, Neji rien) ; sortie d’éveil sans état ; items du blueprint non faits (efficacité de Rotation, conscience des projectiles, ciblage des points faibles, `ROSTER_MOVESETS_10_PRODIGIES.md:225-232`). SYS-003 : deux vraies règles existent, encore mêlées de bonus chiffrés.

### 13. États et réactions
- Crée : HitStun (lights, CircleStep), Knockback (Light3, PalmThrust, AirDrive, Vacuum Palm, repel de Rotation, fin des 64), Knockdown (Sweep, Heavy), Launched (Launcher), Juggled (Air1/2, AirSwitch), Spiked (AirSpike), WallSplat (par carry), Grabbed (commun), GuardStun (chakra vidé). Perturbation de ressource : drain, tenketsu, **Sealed** (bloque seulement `Technique*`, pas outil/dodge/substitution/éveil, `Combat.luau:731`). Reset propre en fin de round (`Combat.luau:1330`).
- Grammaire : `paume (contact) → point fermé (état de ressource) → seuil atteint → PalmThrust/64 Palms (conversion Neji)`.
- **MANQUE** : états OffBalance / GuardOpen dédiés (`FOUR_CHARACTER_COMBAT_MATRIX.md:21`, COM-007).

### 14. Boucle de jeu
Boucle représentative : `pas courts à 5 studs → Light1 (drain + point) → CircleStep (point) → ↓ Sweep (2 points, knockdown) → reprise : Light, Light, Light3 = PalmThrust (≥3 points) → mur → splat → E → Vacuum Palm de fin ou disengage kunai`
- Agressive : `Rush → DashAttack paume → Light2 → ↑ Launcher → E pursuit → AirDrive vers le mur → splat → Heavy (bounce) → E`.
- Défensive : `garde Byakugan (flancs couverts) → l’adversaire s’engage → Rotation sur son Startup → repel + contre 0.9 s → PalmThrust → mur`.
- Low-chakra (<24, pas de Rotation) : `garde + Riposte (Light1) → string de paumes (drain gratuit) → disengage kunai si menacé` ; le drain ramène l’adversaire au même plancher.
- Anti-zoning : `projectile entrant <8.5 studs → Rotation → Rush → 64 Palms sur la recovery adverse`.

### 15. Skill ceiling
- Débutant : enchaîne les paumes, lance Rotation par réflexe (souvent sur un whiff : pas de contre, l’adversaire n’attaquait pas), tente 64 Palms en neutral (recovery 0.85 si raté).
- Intermédiaire : compte les points (3 → PalmThrust), utilise ↓ pour 2 points, place l’adversaire dos au mur avant Vacuum Palm, garde Rotation pour les projectiles.
- Expert : vise des **seuils de chakra adverses** (<15 = plus de substitution, <10 = plus de dodge, 0 = garde brisée) ; réserve 64 Palms pour une recovery quand l’adversaire n’a plus 15 chakra (pas d’évasion) ; place Rotation sur Startup/Pursuit ; oriente son corps pour cacher l’arc arrière ; joue autour des 6 s de CD.
- Séparateurs : lecture de la jauge adverse, timing de Rotation, placement par rapport au mur, gestion de l’orientation.

### 16. Signature irremplaçable
Neji est le seul fighter dont **le contact lui-même**, même bloqué, taxe la ressource qui finance toute la défense universelle adverse (garde, dodge, substitution, jutsu). Ce n’est pas un bouton : c’est un passif câblé dans le pipeline de coup partagé (`Brawler.luau:479`), qui change les décisions adverses (bloquer coûte, garder 15 chakra pour s’échapper devient vital, la régénération ralentit). Avec 64 Palms qui scelle les techniques, Rotation (invulnérabilité circulaire déclenchable) et une garde Byakugan sans flancs, aucun kit « mêmes stats + quatre jutsus » ne reproduit cette pression sur les ressources défensives.

### Exigence de différenciation

| Axe | Neji (`GentleFist`) | Minato (`Flashstep`) | Itachi (`Mirage`) | Sasuke (`Lion`) | Risque Neji |
|---|---|---|---|---|---|
| Neutral | portée 5, paumes, menace de drain | 6, kunai marqué/angles | 10, shuriken, Read | 6, pression kicks/shuriken | — |
| Movement | stride .84 / cadence 1.12, contrôlé | stride 1.12, springy, 19.5 | stride 1.0, contrôlé | springy, jump 1.15 | même famille de gait qu’Itachi |
| Silhouette taijutsu | paumes ouvertes | slashes kunai en reverse grip | jab/paume/kick | coups de pied | 7 clips Mirage hérités |
| Launcher | paume au menton (56) | kick + sceau sur le corps (62) | paume montante + lames (53) | LionKick + Shadow Leaf | — |
| Pursuit | commune | FTG vers un sceau | commune + lames | Shadow Leaf auto | aucune identité |
| Mur | carry PalmThrust/Vacuum Palm | sceaux de surface | ricochet + pin aux lames | fil/Chidori | carry ≈ CounterPalm |
| Air | paumes Drive/Spike/Switch | flash switch | fan de 3 shuriken | Lion Combo | Air1/Air2 = kicks d’Itachi |
| Outils | 1 kunai, recover .85 | 1 kunai .55 + marqué | 2 shuriken, Geometry | 2 shuriken + fil | voulu secondaire |
| Chakra | déni adverse | dépense en mobilité | Read +10, coût ×0.6 à l’éveil | Chidori 34 | — |
| Défense | Byakugan + Rotation | fenêtres communes, sceau | Sharingan .30/.22 | Sharingan .24/.18 | parry générique |
| Éveil | sans angle mort, drain ×1.8 | vitesse 1.18, CD .4 | fenêtres ×1.5 | dégâts 1.18, HealthDrain | pas de contrepartie |
| Rule-bending | drain via la garde, scellement | téléportation | leurre/lecture | auto-poursuite, fil→feu | — |

Overlaps à traiter : PalmThrust occupe les mêmes slots que CounterPalm ; CircleStep laisse un `afterimage` comme FeintStep (`Brawler.luau:88-90`, ghost teinté HYUGA `src/Client/Effects.luau:478`) ; clips air/throws de Mirage.

### Labels lore par capacité
Stade visé : ~13 ans, de l’examen chûnin à l’arc de récupération de Sasuke (Partie 1). Numéros d’épisode/chapitre non garantis : marqués « à vérifier ».

| Capacité (code) | Label | Justification | Source canon (âge) |
|---|---|---|---|
| Paumes Jūken (Light1/2, Heavy, DashAttack, Riposte) | CANON_YOUNG | style Hyūga à paume ouverte | Examen chûnin : préliminaires vs Hinata, finale vs Naruto (13 ans) ; ép./ch. à vérifier |
| Drain par contact | CANON_YOUNG (concept) / GAMEPLAY_LIBERTY (valeurs 6/3) | le Jūken vise le réseau de chakra ; valeurs = équilibrage | préliminaires vs Hinata (13 ans) |
| Drain à travers la garde | GAMEPLAY_LIBERTY | une garde n’arrête pas une frappe interne ; formulation canon explicite à vérifier ; coût réduit à 3 | idem, à vérifier |
| Fermeture de tenketsu (4 max, −15 %/pt, 5 s) | CANON_YOUNG (concept) / GAMEPLAY_LIBERTY (chiffres) | Neji ferme les tenketsu de Hinata | préliminaires vs Hinata (13 ans) |
| Drain sur kicks/projections (passif sur tout coup Brawl) | GAMEPLAY_LIBERTY à corriger | le Jūken passe par la paume ou les doigts | — (voir proposition 2) |
| Byakugan : garde quasi-360°, angle mort arrière | CANON_YOUNG (angle mort) / GAMEPLAY_LIBERTY (vision → blocage) | angle mort exploité par Kidōmaru | Récupération de Sasuke, Neji vs Kidōmaru (13 ans) ; ép./ch. à vérifier |
| Byakugan annule MirageCast | PLAUSIBLE_YOUNG | le Byakugan voit le chakra ; immunité générale au genjutsu non établie (à vérifier) | — |
| Rotation (Hakkeshō Kaiten) | CANON_YOUNG | technique développée seul par Neji | finale vs Naruto ; réemployée vs Kidōmaru (13 ans) |
| Invulnérabilité totale 0.55 s | GAMEPLAY_LIBERTY | en canon, Naruto la contourne par le sol ; compensée par coût 24, CD 6, enracinement | finale vs Naruto |
| Rotation dévie feu/fil/sable | PLAUSIBLE_YOUNG | canon : dévie les armes de jet (finale, Kidōmaru) ; feu/fil = extension | idem |
| Contre post-Rotation → PalmThrust | PLAUSIBLE_YOUNG | punition logique après le repel | — |
| 64 Palms (Hakke Rokujūyon Shō) | CANON_YOUNG | technique de la finale | finale vs Naruto (13 ans) |
| Scellement des jutsu 3.5 s + évasion par substitution | CANON_YOUNG (effet) / GAMEPLAY_LIBERTY (durée, évasion) | Naruto ne peut plus mouler son chakra après les 64 | finale vs Naruto |
| Vacuum Palm (Hakke Kūshō) | PLAUSIBLE_YOUNG (provisoire) | même école Hakke, projectile modeste et contrable ; première apparition **à vérifier** (Partie 1 tardive ou Partie 2) ; distincte de Hakkeshō Kūheki | à vérifier |
| PalmThrust (double paume, finisher à ≥3 points) | PLAUSIBLE_YOUNG / GAMEPLAY_LIBERTY (règle ≥3) | paume Jūken de projection, sans nom canon | — |
| Launcher paume au menton | PLAUSIBLE_YOUNG | paume Jūken ; la verticalité relève de la grammaire du jeu | — |
| CircleStep | PLAUSIBLE_YOUNG ; afterimage = GAMEPLAY_LIBERTY | footwork circulaire cohérent avec Hakke | — |
| Sweep rotatif (2e point) | GAMEPLAY_LIBERTY | balayage commun + règle de jeu | — |
| AirDrive/AirSpike/AirSwitch (paumes) | GAMEPLAY_LIBERTY | jongles aériens = grammaire commune | — |
| Air1/Air2/Slam/WallDive/Grab/Throw/ThrowUp (clips Mirage) | GAMEPLAY_LIBERTY, identité non-Neji | héritage technique (CHR-NEJ-002) | — |
| FlyingKick / SlideSweep (course) | GAMEPLAY_LIBERTY | taijutsu commun | — |
| Kunai secondaire | PLAUSIBLE_YOUNG | équipement standard de genin ; scène précise d’usage par Neji à vérifier | — |
| Substitution (hop) | CANON_YOUNG | Kawarimi = technique de base de l’Académie | Partie 1 (général) |
| Rush / wall-run | PLAUSIBLE_YOUNG | chakra aux pieds = compétence de genin | scène Neji à vérifier |
| Éveil BYAKUGAN FULL FIELD | GAMEPLAY_LIBERTY | retire l’angle mort canon : acceptable seulement comme état temporaire (12 s, 1×/match, ≤35 % PV) | — |
| Hors kit : 128 paumes | non retenue ; datation canon à vérifier | escalade chiffrée des 64, sans nouvelle règle | à vérifier |
| Hors kit : Hakkeshō Kūheki | REJECT_ADULT_ONLY | Partie 2, hors stade jeune | Partie 2 (contexte exact à vérifier) |

### Propositions (candidates, non implémentées)
1. **CHR-NEJ-002 / CHR-CORE-001** : remplacer les 7 clips hérités par des paumes (Air1 paume montante, Air2 paume tournante, Slam = pose AirSpike, Throw/ThrowUp = saisie du poignet + double paume, WallDive = paume plongeante). Timings et hitboxes inchangés → contre-jeu identique. PLAUSIBLE_YOUNG.
2. **CHR-CORE-002** : réserver le drain Gentle Fist aux coups paume (`kind` ou clip), en excluant FlyingKick, SlideSweep et les kicks hérités. Contre-jeu : l’adversaire sait quels coups drainent ; Neji arbitre entre la portée/vitesse d’un kick et le drain. CANON_YOUNG (concept Jūken).
3. **CHR-CORE-001** : CircleStep sans afterimage (trace de pas au sol) pour se distinguer de FeintStep ; orbit 28 et timings conservés. Contre-jeu : suivre le corps réel, pas un leurre. PLAUSIBLE_YOUNG.
4. **DEF-003** : parry de Neji = déviation. Avec la fenêtre commune (0.20 s, coût 16, pas d’élargissement), l’attaquant est réorienté de côté et perd 1 point au lieu du seul stun. Contre-jeu : feinte de Heavy, grab, projectiles. PLAUSIBLE_YOUNG (redirection du blueprint ; scène canon à vérifier).
5. **SYS-003** : contrepartie d’éveil « fatigue du Byakugan ». Après 12 s, angle mort élargi (~±60°) pendant 3 s, à la place de Damage ×1.06. Contre-jeu : temporiser puis attaquer de dos. GAMEPLAY_LIBERTY.

Manque de test : les duels IA de `tests/Neji.spec.luau:153-154` n’incluent pas Sasuke/`Lion`.

Sources code lues : src/Shared/Fighters.luau, src/Shared/MoveGraphs.luau, src/Shared/Attacks.luau, src/Shared/Config.luau, src/Shared/BanglaCombo.luau, src/Shared/Rules.luau, src/Shared/VelmoraCombatConfig.luau, src/Server/Techniques.luau, src/Server/Brawler.luau, src/Server/Combat.luau, src/Server/AI.luau, src/Server/VelmoraDefense.luau (extraits), src/Server/Matches.luau (extrait), src/Client/VelmoraMotionEngine.luau, src/Client/UI.luau et Effects.luau (extraits), tests/Neji.spec.luau, docs/characters/{FIGHTER_TEMPLATE,NEJI,CORE_ROSTER,ROSTER_MOVESETS_10_PRODIGIES}.md, docs/active/{DECISIONS,MASTER_BACKLOG,SINCE_LAST_CLAUDE}.md, docs/FOUR_CHARACTER_COMBAT_MATRIX.md, docs/current/MOTION_ATTACK_MAPPING.md (lignes Neji).
