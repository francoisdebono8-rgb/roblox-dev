> Snapshot historique avant harmonisation des fiches le18/10/2026. Conserver les idées et preuves ; état/priorités dans docs/active, nouvelle fiche au chemin d’origine.

> Documentation spécialisée de référence ; état dans [CURRENT_STATE](../../../active/CURRENT_STATE.md), travail et critères dans [MASTER_BACKLOG](../../../active/MASTER_BACKLOG.md). Les anciennes propositions et statuts ci-dessous ne fixent pas les priorités globales.

# Gaara — forteresse de sable (vague d'archétypes)

Code : `Sand` — **existe côté serveur avec 10 tests, caché du menu** (DEC-001, CHR-EXT-001). IDs : CHR-EXT-001, CHR-EXT-002, CHR-CORE-002 (labels), SYS-003, DEF-005.

> Fiche de conception Claude du 2026-10-16 (mission [COMBAT_CONVERGENCE_ONLINE_ROSTER](../../missions/COMBAT_CONVERGENCE_ONLINE_ROSTER.md) §18–21, DEC-012/DEC-013). Code lu sur `c2d797c` : `fichier:ligne` indicatif, le nom de fonction fait foi ; chemins relatifs à `games/ninja-duel/src/`. **EXISTE** = code réel ; **MANQUE** = écart au [gabarit](../../../characters/FIGHTER_TEMPLATE.md) ; **PROPOSÉ** = candidat non implémenté ; **DÉCISION** = absence volontaire. Valeurs proposées = points de départ à régler en natif. Sources canon « à vérifier » non confirmées. Plan d'ensemble : [ROSTER_WAVE_PLAN](../../../characters/ROSTER_WAVE_PLAN.md) ; hooks `H01…H17` : [ROSTER_WAVE_HOOKS](../../../characters/ROSTER_WAVE_HOOKS.md).

## Stade retenu (DEC-013)

**Examen chûnin → récupération de Sasuke (12–13 ans).** Racines présentes : bouclier de sable automatique, Cercueil/Enterrement du désert, shuriken de sable, transformation partielle (bras de Shukaku). Échelle adulte/endgame absente : pas de Shukaku complet (géant), pas de Kazekage (sable volant, bouclier de la ville, tsunami de sable), pas des techniques de terrain géantes contre Kimimaro (cascade de sable mouvant) — canon jeune, mais hors échelle de duel.

## Pourquoi il mérite une place (système éprouvé)

1. **Défense automatique dans le pipeline de dégâts** : `Combat:damage` consomme des charges de bouclier avant `Defense.resolve` (`Server/Combat.luau:183-201`). Aucun autre fighter n'a une couche défensive qui agit sans input.
2. **Mêlée décalée du corps** : les fouets de sable frappent un volume détaché (`AttackProfile` `range 8.5–9`, `depth`, `offset 4.3–4.5`, `Fighters.luau:141-146`) → éprouve la validation de portée (`Combat:targetValid`/`HitDetection.resolve`) et le retour de contact à distance (le corps ne touche jamais).
3. **Premier fighter hors CORE4 à traverser tout le pipeline** : son serveur est complet, son client ne l'est pas. Il valide H01 (identité client par données) avant qu'un kit neuf ne s'y ajoute.
4. **Projectile au sol qui lie** (`sandwave` → `Bound` → enterrement planifié, contre par substitution) : seul bind « à distance par le sol » du roster.

## Mécanique signature

**Le sable paie à sa place** : 3 charges de bouclier qui arrêtent seules un coup propre (une charge par coup, tout d'un coup sur un lourd, un 3e coup de string, un Rasengan ou ≥ 17 dégâts), rechargées une à une. Le bouclier ne joue **pas** pendant ses propres attaques ni sa récupération : chaque fouet raté est l'ouverture. PROPOSÉ : le sable qu'il disperse reste au sol (« sable répandu », H06) et devient le terrain de ses binds.

## Fiche FIGHTER_TEMPLATE

### 1. Identité
- **EXISTE** (`Shared/Fighters.luau:125-154`) : « THE SAND PRODIGY », `Age = 12`, HP 140, chakra 130, regen 7, vitesse 16.5 (la plus lente), sprint ×0.85, saut ×0.9, air ×0.85, accél. ×0.85, `CombatTravel = 0.2` (il ne marche presque pas en frappant), `PreferredRange = 11` (la plus longue du code), `Tool = "Sand"`.
- Fantasy : l'enfant qui ne bouge pas ; le sable frappe, protège et enterre. Rôle : forteresse/zoning défensif. Rythme : lent, patient, punitions lourdes. Distance : 9–30.
- Forces : défense passive, portée de mêlée, bind au sol. Faiblesse : lenteur, récupérations longues (×1.3–1.35), bouclier vidé par la pression (lourds, 3e coup), aucune mobilité aérienne.
- Question : « Combien de coups faut-il pour toucher un garçon que son sable protège seul ? »
- **MANQUE** : pas de champ `Routes` (le panneau de routes du menu reste vide, `Client/UI.luau:248`) ; labels lore : table plus bas.

### 2. Mouvement
- **EXISTE serveur** : esquive remplacée par un *sand flicker* (12 studs instantanés, `warpSerial`, i-frames 0.24, coût 10, `Combat.luau:715-728`) ; pas de flicker en l'air (esquive commune).
- **MANQUE critique (client)** : aucune `STANCE`/`GAIT`/`CLIPS` `Sand` → repli sur Minato : démarche *springy* (`springy()` vrai pour tout id inconnu, `Client/VelmoraMotionEngine.luau:264`), stance et clips de Minato (`:261`, `:879`), et **kunai en prise inversée visible** sur Light1/2, DashAttack, Air1 (`weaponsFor` traite tout id inconnu comme Minato, `:1551`). Intro = moulinet de kunai de Minato (branche `else` de l'intro, `:1715`).
- PROPOSÉ (H01) : stance bras croisés, droit, immobile (respiration 0.4) ; démarche « glaciale » `stride .8, cadence .85, arm 0, lean -2, bob .3, guard 0` ; sprint = marche pressée portée par un tapis de sable visible (les pieds restent plantés sur le sable qui avance — pas de glisse de pieds nus). DÉCISION : pas de course murale (`WallRun=false`, petite donnée lue par `Motor.tryWall`) : la forteresse ne grimpe pas.

### 3. Neutral / entrée en combat
- **EXISTE** : fouets à 8.5–9 (un poing porte à 6–7) ; balle de sable (outil) vitesse 90, portée 56, 3 dégâts, récupération 0.6 (`Combat.luau:652-659`) ; Sand Shuriken 6 lames à 38 ; Cercueil à 30. L'IA adverse sait déjà qu'elle est « out-ranged » et force l'entrée (`Server/AI.luau:286-292`).
- Il ne ferme pas la distance : il la **fait payer**. Sortie : flicker arrière, Desert Wave à bout portant.
- À respecter : chaque charge visible de bouclier ; le sol où il a déjà lancé du sable (PROPOSÉ H06).

### 4. Taijutsu et combos
- **EXISTE** (`Shared/MoveGraphs.luau:67-73`) : string de 3 fouets (Light1/2 startup ×1.45, récup ×1.3, dégâts ×0.8/×0.5 ; Light3 ×1.5, `impulseZ 56`) ; ↑ (≥2) et lourd après 1 coup = `SandPillar` (le sable jaillit sous l'adversaire à 12.5 studs, Launched, `Shared/Attacks.luau:43,107`) ; ↓ = Sweep commun ; `stringCancels = {SandCoffin}` ; `blockCancels = {Tool}` ; lourd neutre = `SandPillar` (`HeavyMove`/`LauncherMove`, `Brawler.luau:242-243`).
- **MANQUE** : pas de route latérale, pas de routes aériennes, pas de disengage ; aucun clip propre.
- PROPOSÉ :
  - `side` = **SandClamp** : un fouet latéral qui enserre et ramène l'adversaire 2 studs devant lui (anti-flanc ; garde la string). Fonction : annuler le changement d'angle adverse, l'inverse d'AngleStep/FeintStep.
  - payoff `onRoute.SandPillar = "sandCatch"` : un Cercueil lancé dans les 1.2 s **attrape le corps à son atterrissage** (canal 0.2, pas de vague au sol). Il convertit sans jamais poursuivre en l'air.
  - `disengage = "Sand"` : recul 5 studs derrière une balle de sable (extension de `Brawler.disengage`, aujourd'hui kunai/shuriken seulement, `Brawler.luau:115-129`).
  - Air : DÉCISION, pas de routes aériennes (Air1/Air2 = fouets courts) ; son anti-air est le Pillar.

### 5. Armes et ninja tools
- **EXISTE** : outil = balle de sable (pas de kunai) ; en cancel de string : gratuite, portée 20, récupération 0.42.
- **MANQUE (client)** : les projectiles `sand`/`sandwave` n'ont pas de constructeur → **rendus comme des kunai** (`BUILD[p.kind] or BUILD.kunai`, `Client/Effects.luau:259`).
- DÉCISION : ni kunai ni shuriken (le sable est l'arme ; source : gourde).

### 6. Jutsus / techniques (`Fighters.luau:149-153`, `Server/Techniques.luau:349-426`)
| Technique | Coût | Canal/actif/récup | CD | Portée | Effet réel | Contre-jeu |
|---|---|---|---|---|---|---|
| Sand Coffin | 26 | .35/.1/.35 | 8 | 30, vitesse 46 | vague au sol (rayon 1.8) → `Bound` 1.25 s → enterrement à +1.05 s, 18 dégâts, Knockdown | sauter/esquiver la vague, garde (pas de bind), **substitution pendant le bind** (test `tests/Gaara.spec.luau:97`) |
| Sand Shuriken | 16 | .25/.08/.25 | 3.5 | 38 | 6 lames de sable (±0.25 rad, vitesse 80) | garde, pas de côté large |
| Desert Wave | 22 | .26/.2/.3 | 6 | 12 | avale les projectiles devant lui, repousse un attaquant proche (7 dégâts, Knockback 48) | ne pas entrer de face, attendre le CD |

PROPOSÉ : Desert Wave laisse un **mur de sable** bas 2.5 s (H11 option : surface de splat et d'arrêt des projectiles) ; toutes les techniques de sable laissent du **sable répandu** (H06 : rayon 5, 6 s, 3 au plus). Sur ce sable : Cercueil à canal 0.2 qui part du sol sous la cible ; sprint adverse ×0.85.

### 7. Garde / défense
- **EXISTE** : bouclier (3 charges, recharge 3.5 s/charge, casse ≥ 17 dégâts, `SHIELD_BREAKERS` : Heavy, Launcher, Light3, Slam, KneeStrike, FlyingKick, PalmThrust, CounterPalm, WallDive, SandPillar ; casse = 0 charge + Stunned 0.5) ; la string adverse garde son rythme (`attacker.hitConfirmed=true`) ; garde/parry communs en plus.
- **À trancher (lecture de code, à confirmer par test)** : (a) une projection n'a pas d'effet tant qu'il reste une charge : `releaseGrab` vide `grabbedBy` avant `c:damage`, le bouclier absorbe donc les dégâts du Throw (`Brawler.luau:446-452,478-480`) ; (b) `SHIELD_BREAKERS` lit `attacker.attackName` même pour un projectile (déjà consigné au journal du bloc 3).
- PROPOSÉ : la saisie **contourne** le bouclier (on attrape le garçon, pas le sable) : contre-jeu lisible et universel (GAMEPLAY_LIBERTY), qui récompense le corps à corps contre une forteresse.

### 8. Esquive et substitution
- **EXISTE** : sand flicker (§2) ; substitution commune en mode `hop`.
- PROPOSÉ (H05) : **le sable se substitue** : s'il lui reste une charge, la substitution coûte 1 charge + 8 chakra (au lieu de 15) et laisse un tas de sable au départ. Contre-jeu : vider le bouclier d'abord prive Gaara de son évasion bon marché.

### 9. Rush / poursuite
- **EXISTE** : Rush/poursuite communs. DÉCISION : il ne poursuit pas en l'air ; sa conversion après Pillar est `sandCatch` (PROPOSÉ §4) ou Sand Shuriken sur le corps qui retombe.
- Casser sa « poursuite » : rester en l'air (air dodge), atterrir hors du sable, substitution pendant le bind.

### 10. Chakra
- **EXISTE** : 130 / 7 par s ; kit coûteux (26/16/22) ; flicker 10. Spécialité : la défense passive ne coûte pas de chakra (charges).
- PROPOSÉ : bas chakra = plus de Cercueil → il ne reste que fouets, balle et bouclier : il redevient une forteresse pure (boucle low-chakra §14).

### 11. Infusion / interactions de chakra
- **EXISTE** : `sable + sol + contact → Bound` ; `sable + projectile adverse + Desert Wave → absorbé`.
- PROPOSÉ (H07, différable) : vent de Temari → disperse le sable répandu ; eau de Kisame → sable mouillé (Cercueil plus lent, bouclier −1 charge max) ; le Pillar sur du sable répandu sort sans délai.

### 12. Éveil — SHUKAKU'S SAND
- **EXISTE** (`Fighters.luau:139`, `Combat.luau:497-524,821-824`) : ≤ 35 % PV, 12 s ; vitesse ×1.12, dégâts ×1.12, regen ×1.6, CD ×0.5, recharge du bouclier ×2. **MANQUE (SYS-003)** : multiplicateurs seulement.
- PROPOSÉ (**transformation partielle**) : (1) le lourd devient le **bras de Shukaku** : balayage à 14 studs, démarrage armé (H13 : les coups légers ne l'interrompent pas) ; (2) un bouclier cassé ne l'étourdit plus ; (3) contrepartie : pas de flicker (le sable est dans le bras), vitesse ×0.9 au lieu de ×1.12, retirer le ×1.12 de dégâts. Sortie : 2 s sans bouclier (le sable se reforme).

### 13. États et réactions
- Crée : Launched (Pillar), Bound (Cercueil), Knockdown (enterrement, Sweep), Knockback (Light3, Desert Wave), Stunned **sur lui-même** quand le bouclier casse.
- Exploite : PROPOSÉ `sandCatch` (corps en chute), sable répandu (terrain).
- **MANQUE** : aucun OffBalance/GuardOpen dédié (comme CORE4).

### 14. Boucle de jeu
- Représentative : `garder 11 studs → balle de sable → fouet ×2 (l'adversaire entre) → bouclier absorbe la riposte → ↑ Pillar → Cercueil sandCatch → enterrement`.
- Agressive (rare) : `Sand Shuriken → l'adversaire bloque → Cercueil en string-cancel → enterrement`.
- Défensive : `charges pleines → laisser frapper → Desert Wave à bout portant → flicker arrière → reset`.
- Low-chakra : `fouets + balles gratuites en cancel → bouclier → attendre 26 chakra`.

### 15. Skill ceiling
- Débutant : fouets en boucle, Cercueil au hasard.
- Intermédiaire : ne frappe que lorsque le bouclier est plein (ses attaques le suspendent) ; Pillar anti-saut ; Cercueil en cancel.
- Expert : anticipe le coup qui cassera son bouclier et le laisse casser contre une riposte prête (Desert Wave, flicker), joue `sandCatch`, prépare le sol (PROPOSÉ), garde 8 chakra + 1 charge pour la substitution.

### 16. Signature irremplaçable
Gaara est le seul dont la **défense agit sans input** et dont la mêlée **ne touche jamais avec le corps**. Mêmes stats et quatre jutsus différents ne reproduiraient ni la suspension du bouclier pendant ses propres attaques (le rythme « attaquer = s'exposer »), ni la portée décalée, ni la conversion par le sol.

## Différenciation

| Axe | Gaara | Minato | Itachi | Neji | Sasuke |
|---|---|---|---|---|---|
| Neutral | 9–30, fouets/balles, attend | 6, sceaux | 10, Geometry | 5, paumes | 6, pression |
| Mouvement | le plus lent, flicker, pas de mur | le plus vif | contrôlé | pas courts | acrobatique |
| Launcher | Pillar à distance → `sandCatch` | sceau corporel | lames de couverture | paume | LionKick |
| Défense | **automatique** (charges) | mobilité | lecture | Rotation | Sharingan |
| Règle tordue | le bouclier remplace l'input | téléport | flanc/whiff | drain | chasse gratuite |

| Vague | Recouvrement | Ce qui les sépare |
|---|---|---|
| Kisame | lent, gros PV, mi-distance | Kisame frappe au corps (Samehada), vole le chakra et a une armure *active* ; Gaara ne touche jamais et sa défense est passive |
| Temari | zoning à distance | Temari peint des couloirs mobiles et repousse ; Gaara fixe le sol et lie |
| Shikamaru | contrôle par le sol | l'ombre de Shikamaru se dirige et possède ; le sable de Gaara attrape et écrase |
| Haku | cage / terrain | Haku bouge entre ses miroirs ; Gaara ne bouge pas |
| Lee | — | contre naturel : Lee « plus rapide que le sable » (PROPOSÉ ROCK_LEE §7) |
| Naruto, Kakashi | — | aucun recouvrement de système |

## Labels lore par capacité

| Capacité (code) | Label | Source / justification |
|---|---|---|
| Bouclier de sable automatique (`SandShield`) | CANON_YOUNG | Préliminaires de l'examen chûnin, contre Lee (ch. à vérifier) |
| Charges, casse, suspension pendant ses attaques | GAMEPLAY_LIBERTY | Contre-jeu : pression, lourds, whiff punis |
| Fouets de sable (Light1–3) | CANON_YOUNG (concept) | le sable poursuit Lee aux préliminaires ; timings = liberté |
| Sand Coffin / enterrement | CANON_YOUNG | Forêt de la mort (équipe d'Ame) et préliminaires (ch. à vérifier) |
| Substitution qui échappe à l'enterrement | GAMEPLAY_LIBERTY | Contre-jeu obligatoire d'un bind |
| Sand Shuriken | CANON_YOUNG | Partie I (scène à vérifier) |
| Sand Pillar | GAMEPLAY_LIBERTY | jaillissement sous la cible, sans nom canon |
| SandClamp, recul derrière une balle (PROPOSÉS) | GAMEPLAY_LIBERTY | « lateral clamp » du blueprint ([ROSTER_MOVESETS_10_PRODIGIES](../../../characters/ROSTER_MOVESETS_10_PRODIGIES.md) §6) |
| Desert Wave | GAMEPLAY_LIBERTY | nom non canon ; mur de sable proche du bouclier |
| Sand flicker | PLAUSIBLE_YOUNG | apparition en tourbillon de sable à l'examen (à vérifier) |
| Balle de sable (outil) | PLAUSIBLE_YOUNG | projection de sable de la gourde ; nom à vérifier |
| Tapis de sable du sprint (PROPOSÉ) | PLAUSIBLE_YOUNG | arrivée portée par le sable contre Kimimaro (à vérifier) |
| `sandCatch` (PROPOSÉ) | CANON_YOUNG (concept) | le sable saisit le bras et la jambe de Lee après le Lotus inversé |
| Substitution payée par une charge (PROPOSÉ) | GAMEPLAY_LIBERTY | le sable prend le coup ; Suna Bunshin canon jeune à vérifier |
| Éveil : bras de Shukaku (PROPOSÉ) | CANON_YOUNG | finale contre Sasuke et forêt contre Sasuke/Naruto |
| Shukaku complet (géant) | REJECT_ADULT_ONLY | échelle endgame (DEC-013 vise l'échelle, pas l'âge) |
| Cascade de sable mouvant / grand enterrement du désert | CANON_YOUNG, **hors kit** | contre Kimimaro ; échelle de terrain hors duel |
| Sable volant, bouclier de la ville, tsunami de sable | REJECT_ADULT_ONLY | Kazekage, Partie II |
| Troisième œil | CANON_YOUNG, **hors kit** | ferait doublon avec la vision du Byakugan de Neji |

## Plan d'implémentation

**Réutilisé tel quel** : tout le serveur (`Fighters.Sand`, `MoveGraphs.Sand`, `Attacks.SandPillar`, `Techniques.SandCoffin/SandShuriken/DesertWave/bindInSand`, bouclier et flicker dans `Combat`), règles IA `SandCoffin/SandShuriken/DesertWave` (`AI.luau:266-268`), costume `dressGaara` (`Server/World.luau`, gourde), clip `Bound` commun (`VelmoraMotionEngine.luau:1371`).

**Nouvelles données** : `Fighters.Sand.Routes` ; PROPOSÉ `WallRun=false`, `MoveGraphs.Sand.routes.side="SandClamp"`, `onRoute={SandPillar="sandCatch"}`, `disengage="Sand"` ; `Attacks.SandClamp` (startup .1, portée 8, orbite 0, traction 2 studs) ; indices IA par technique (H03).

**Hooks** : H01 (obligatoire) ; H03 ; H06 (sable répandu, option) ; H05 (substitution par charge, option) ; H17 (mode de substitution « sable », `disengage` de sable) ; H13 (bras de Shukaku, éveil) ; H11 (mur de sable, option).

**Motion (H01)** : stance + démarche + intro (bras croisés, sable qui sort de la gourde) ; clips à créer : Light1–3 (commandes de bras courtes : le sable fait le travail), SandPillar, Sweep (paume au sol), DashAttack, Grab (main de sable), Throw/ThrowUp, Air1/Air2, Riposte, SandClamp ; `castSpec` pour SandCoffin (poing qui se ferme), SandShuriken (balayage de bras), DesertWave (deux paumes vers le sol) ; **aucune arme tenue** (corriger le repli Minato de `weaponsFor`).

**Effets/UI** : constructeurs `sand`/`sandwave` ; styles `sandshield`, `sandhit`, `sandburst`, `sandwall`, `sandflicker`, `sandburial` (aujourd'hui sans branche dans `FX:impact`, seul `CONTACT_FALLBACK` de `Client/VelmoraHitFeedback.luau:77`) ; HUD des charges (déjà dans le snapshot : `shield`, `shieldMax`, `Server/Matches.luau`) ; ajouter `"Sand"` à `playable` (`Client/UI.luau:74`) quand l'acceptation native est faite.

**Tests** : ajouter les paires `Lion` au duel IA (`tests/Gaara.spec.luau:139` ne couvre pas Sasuke) ; ajouter `Sand` à `tests/Preparation.spec.luau:6` et à `tests/Balance.sim.luau` (cible 40–60 %, l'ancien sim l'avait à 96 % avant la baisse des fouets — [ROADMAP_WEEK](../../plans/ROADMAP_WEEK.md)) ; cas « saisie vs bouclier » une fois tranché ; test sans jutsu (`match.techniquesDisabled`, `Combat.luau:744`) : le bouclier et les fouets suffisent à le reconnaître.

**Effort** : **S** pour le périmètre minimal, **M** avec sable répandu, routes et éveil à règle.

**Périmètre minimal jouable pour éprouver le moteur** : H01 complet pour `Sand` (stance, démarche, clips, effets de sable, HUD charges, pas de kunai), `Routes`, tests Lion + balance, décision saisie/bouclier. Hors minimal : sable répandu, SandClamp, `sandCatch`, éveil à règle.

## Points à vérifier
- Numéros de chapitres/épisodes cités ; nom canon de la balle de sable ; existence d'un Suna Bunshin jeune.
- Comportement réel « projection contre bouclier chargé » (lecture de code ci-dessus) et `SHIELD_BREAKERS` sur projectiles.
- Équilibre IA (ancien 96 %) après exposition du client.
