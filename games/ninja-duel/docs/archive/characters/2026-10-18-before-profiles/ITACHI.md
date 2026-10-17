> Snapshot historique avant harmonisation des fiches le18/10/2026. Conserver les idées et preuves ; état/priorités dans docs/active, nouvelle fiche au chemin d’origine.

> Documentation spécialisée de référence ; état dans [CURRENT_STATE](../../../active/CURRENT_STATE.md), travail et critères dans [MASTER_BACKLOG](../../../active/MASTER_BACKLOG.md). Les anciennes propositions et statuts ci-dessous ne fixent pas les priorités globales.

# Itachi — jeune prodige

Code : `Mirage`. IDs : CHR-ITA-001/002, CHR-CORE-001/002. Les données réelles viennent de Fighters/MoveGraphs/Attacks et [inventaire](../../../current/COMBAT_INVENTORY.json) ; le label lore n’est pas automatiquement prouvé par le nom du move.

## Expression visée

Calme et précis ; peu de mouvement pour lire/feinter/faire perdre la ligne. Shuriken/ricochet/geometry et feu créent un angle ou une menace, pas simple spam. Défense et courtes frappes propres ; costume jeune, pas Akatsuki, pas capacités adultes transférées sans filtre.

## Conversions à rechercher, pas à ajouter aveuglément

Projectile collision→RedirectTrajectory ; feinte→outside angle→counter court ; geometry→fire lane→conversion. Geometry actuel prouvé, nouveau conflit généralisé à évaluer séparément.

Pour chaque exemple : source/âge/scene/timecode, label lore, état initial/contact/réaction/résultat/followup, brique commune et expression spécifique, input/camera/air/wall/risque. Vérifier d’abord si le code satisfait déjà l’intention. Lire le blueprint complet dans [ROSTER_MOVESETS_10_PRODIGIES](../../../characters/ROSTER_MOVESETS_10_PRODIGIES.md) et les passages propres à Itachi dans [CLAUDE_FINAL_PASS](../../missions/CLAUDE_FINAL_PASS.md).

## Validation

Baseline native + garde/course/strafe/dash/jump, contact/defense/throw/outil/jutsu/air/mur/KO ; duel contre les quatre IA et manette. Même scénario avant/après ; motion/export sélectionné par Claude, contrats/costs/timings protégés. Reconnaissance de Itachi sans jutsu ; vérifier jeunesse et contre-jeu. Un headless PASS technique ne clôt pas cette identité visuelle.

## Fiche FIGHTER_TEMPLATE — audit 2026-10-16

> Audit Claude du 2026-10-16 (CHR-CORE-001/002, bloc 4 du plan approuvé le 2026-10-14). Décrit le code réel de `claude/ninja-duel-2026-10-14` ; les références `fichier:ligne` ont pu glisser avec les correctifs du bloc 3 (`f93d866`) — le nom de fonction fait foi. Les sources canon marquées « à vérifier » ne sont pas confirmées. Les propositions sont des candidates, non implémentées ; les labels REJECT_ADULT_ONLY signalent un écart code ↔ décision DEC-005 à trancher, pas un changement fait.

Statut : audit du code réel (lecture seule). IDs : CHR-ITA-001 (DONE technique), CHR-ITA-002, CHR-CORE-001/002, SYS-003 (PARTIAL).
Chemins relatifs à `games/ninja-duel/src/`. Valeurs = données brutes (avant `CombatDamage` 1.1 sur la mêlée).

### 1. Identité

- **Fantasy** : prodige Uchiha calme, qui lit, trompe et frappe depuis un angle où il n'est pas. Titre `THE SHARINGAN PRODIGY` (`Shared/Fighters.luau:31`).
- **Stade jeune retenu** : ~11–12 ans, période ANBU, Sharingan 3 tomoe, **avant** le Mangekyō (mort de Shisui, ~13 ans).
  **ÉCART** : le code déclare `Age = 13` et le commentaire « three tomoe at 13 » (`Fighters.luau:31,36`). 13 ans est l'âge canonique du Mangekyō/massacre. **DÉCISION requise** : passer à 12, ou documenter « 13 ans, avant la mort de Shisui ».
- **Rôle** : contrôleur à mi-distance. `PreferredRange = 10`, contre 5–6 pour les trois autres (`Fighters.luau:35`).
- **Rythme** : lent et économe : `Speed 18`, `SprintScale 1.0`, `Accel .98`. **Corps** : `Health 145`, le plus élevé du noyau. **Réserve** : `Chakra 125`, la plus grande, mais `Regen 7.2`, la plus faible (`:34`).
- **Forces** : défense de lecture, outils hors-axe, punition des engagements. **Faiblesse principale** : peu de mobilité, mêlée plus lente (startup ×0.96–1.02, `:48-51`) et jutsus coûteux en chakra.
- **Signature mécanique** : lames qui arrivent par le flanc (Geometry/ricochet), Read et punition d'un coup dans le vide (whiff).
- **Question à laquelle répond son gameplay** : « Que fais-tu quand chaque engagement que tu prends devient son ouverture ? »
- **Labels lore** : voir la table « Labels lore par capacité ».

### 2. Mouvement

- **Existe** : stance droite et carrée, main gauche prête : `root.y=-.2` (Minato -.42, Neji -.62, Sasuke -.5), `breath .7`, `tempo 5` (`Client/VelmoraMotionEngine.luau:248-250`) ; démarche « controlled », non springy (`:262-264`) ; GAIT `stride 1.0`, `cadence .94`, `arm 24`, `lean -1`, `bob .7`, `guard .35` : la garde reste portée en courant (`:1060`) ; intro immobile (`:1703-1708`).
- **Valeurs communes** : marche 18, sprint 45 (`Config.luau:39`, `Server/Motor.luau:206`) ; saut ×0.98, air ×0.95 ; dodge 13.7 studs (`DashScale .98`, `Server/BanglaEvade.luau:7`) ; wall-run/WallDive communs, clip propre en talon, main de shuriken prête (`VelmoraMotionEngine.luau:527-533`) ; FlyingKick/SlideSweep de course (`:546-561`).
- **Mouvement signature** : FeintStep, orbit 34 + image rémanente (`Shared/Attacks.luau:47,109` ; `Server/Brawler.luau:81-84`).
- **MANQUE** : pas de micro-pas ni de « strafe lent » propre en neutral (marche commune) ; repositionnement limité au hop du disengage ; pas de wall exit propre.
- **DÉCISION : volontairement absent** — pas de téléportation (réservée à Minato) ; mobilité basse, assumée comme coût du contrôle.

### 3. Neutral / entrée en combat

- **Poke principal** : paire de shuriken (`ToolMastery`, `Fighters.luau:44`) : 2 lames, vitesse 84, dégâts 2, portée 62, release .13 s, intervalle .08 s, récupération .75 s, coût 4 chakra en neutral (`Config.luau:10` ; `Server/Combat.luau:610-656`).
- **Forcer une réaction** : Shuriken Geometry (côté + outil) : la lame redirigée arrive par le flanc et passe une garde frontale (`Combat.luau:639-644,1135-1172` ; test `tests/Tools.spec.luau:36`).
- **Lecture / feinte** : Read (`Fighters.luau:55`), Genjutsu Mirage (`:57`), feinte de Great Fireball (`Feintable`, `Combat.luau:555-566`).
- **Fermer / sortir** : fermeture par le chakra dash commun (10, 7–48 studs, `Config.luau:20`), rien de propre ; sortie par disengage (arrière + outil en chaîne) ou annulation outil sur garde (`blockCancels.Tool`).
- **À respecter** : toute approche frontale (Read, parry 0.30 s), une lame qui peut venir de côté ou rebondir sur un mur, une ligne de feu.
- **IA** : lance plus souvent (.11 contre .09) et choisit Geometry dans 40 % des lancers (`Server/AI.luau:244-249`).

### 4. Taijutsu et combos

Grammaire : `Shared/MoveGraphs.luau:31-43`. Clips : `VelmoraMotionEngine.luau:351-460,582-631`.

| Entrée | Move réel | Fonction / valeurs |
|---|---|---|
| String neutre | jab (L1, portée 6.6) → paume + lancer d'aiguille (L2, portée 7) → side kick (L3, impulseZ 60) | L2 `chainTool` : 1 shuriken (vitesse 88, portée 11, dégâts 2) part au premier frame actif, même si le coup rate (`Brawler.luau:447-449`). L3/Air2 confirmés : recul de 9 studs/s pour **créer l'espace** (`Combat.luau:972-973`) |
| ↑ (2 coups et plus) | Launcher, paume montante (Y53/Z20) | `coverBlades` : 2 shuriken (vitesse 92, portée 30, dégâts 1.5) +0.2 s après le contact (`Brawler.luau:299-307`) |
| ↓ (2 coups et plus) | Sweep, faucheuse | Knockdown, hauteur 3.5, fin du string (`Attacks.luau:26,104`) |
| ←→ (1 coup et plus) | FeintStep | startup .1, dégâts 6, orbit 34 ; le string continue ; afterimage purement visuel (`Attacks.luau:47`) |
| Heavy après 1 coup | CounterPalm | startup .05, dégâts 10, Knockback 46, casse le bouclier de sable (`Combat.luau:149`) |
| Heavy neutre | back kick tournant | (`VelmoraMotionEngine.luau:370`) |
| Air | Air1 genou, Air2 hook ; AirDrive (side kick, + `coverBlades`), AirSpike (marteau, ground bounce), AirSwitch (orbit 40) ; Slam (axe kick) | grammaire commune, clips propres |
| Read / counter | `readCounter = CounterPalm` sur la pression suivante (`Brawler.luau:250-253`) | |

- **Cancels** : `stringCancels = {}`, aucun jutsu dans un string (DÉCISION implicite : Itachi ne finit pas au jutsu) ; outil en chaîne confirmée gratuit (portée 20) ; outil après un coup gardé (seul du noyau avec `blockCancels.Tool`). Grab, throw et clash communs.
- **MANQUE** : le steering « vers un mur » annoncé pour CounterPalm (`MoveGraphs.luau:37-38`) n'est pas codé, l'impulsion suit le `LookVector` (`Brawler.luau:495`) ; pas de route wall propre ; pas de finisher dédié (L3 générique) ; FeintStep ne laisse aucun leurre jouable.

### 5. Armes et ninja tools

- **Kunai** : aucun. **DÉCISION** : identité shuriken ; reste à trancher le kunai de mêlée (le clip L2 « flicks a blade »).
- **Shuriken** : paire en neutral ; éventail de 3 en l'air (`AirSpread`, intervalle .05, `Combat.luau:646`) ; tenus dans la main gauche (`VelmoraMotionEngine.luau:1524-1553`).
- **Geometry** : coût 4 chakra ; 2 lames à 0 dégât se rejoignent 6 studs à côté de la cible et 1.5 au-delà ; à l'expiration de la première, 2 lames redirigées (vitesse 88, portée 18, dégâts 2.5), jugées depuis le flanc (`hitOrigin`, `Combat.luau:155-158,1162-1172`) ; recharge outil .8 s.
- **Ricochet** : une fois par lame, sur surface verticale, cible à 36 studs ou moins et ligne libre ; vitesse ×.9, portée 40 ; vaut pour **toutes** ses lames, Shadow Shuriken compris (`Combat.luau:1121-1133`).
- **Outil ↔ mêlée** : mêlée → outil par chain cancel gratuit (portée 20, recharge .42) ou disengage (hop 6 studs + 2 shuriken portée 22, `Brawler.luau:103-119`) ; outil → mêlée : le lancer ne bloque l'attaque que jusqu'à la release (`Combat.luau:568-573`).
- **Lancer en mouvement** : oui, l'état reste Neutral (`beginThrow`, `Combat.luau:320-341`) ; un dodge annule le lancer.
- **Mur** : une lame qui touche un corps en WallSplat le pin +.34 s (`Combat.luau:1097-1101`) ; commenté « Itachi » mais **commun** à tous.
- **MANQUE** : pas de vraie collision projectile-vs-projectile (Geometry = expiration scriptée, la seconde lame disparaît sans effet, DEF-005) ; pas de lame plantée ni persistante (TOOL-002) ; pas de wire, smoke ni tags. **DÉCISION** : wire réservé à Sasuke.

### 6. Jutsus / techniques

Sources : `Fighters.luau:55-59`, `Server/Techniques.luau`, `Server/Elements.luau`.

| Technique | Coût | Channel / Actif / Récup | CD | Portée | Effet réel | Contre-jeu |
|---|---|---|---|---|---|---|
| Sharingan Read | 14 | .1 (non interruptible) / 1.0 / .2 | 3.6 | — | `readUntil` 1 s ; le premier coup **de mêlée frontal** est lu. Sur l'attaquant : Stunned .48. Pour Itachi : bonus ×1.35 pendant 1.4 s, CounterPalm pendant 1.0 s, +10 chakra (`Techniques.luau:233-240`, `Combat.luau:171-177`) | Projectiles, flanc/dos, grab : le grab ne passe pas par `damage`. Ou attendre : Itachi reste engagé 1.2 s, déplacement 12 (`Motor.luau:206-210`) |
| Shadow Shuriken | 18 | .26 / .08 / .26 | 3.6 | 56 | Éventail de 5 lames (±0.2 rad, vitesse 74, dégâts 2), puis 2 lames cachées à +.32 et +.38 s, visées sur l'esquive (avance de .18 s) (`:241-265`) | Garde ; un dodge tardif ; frapper Itachi pendant le channel (les lames cachées sont annulées) |
| Genjutsu : Mirage | 32 | .9 / .08 / .45 | 8 | 23 (cible) | Leurre 3 s à 7 studs à droite. **Tout** coup dans le vide de la victime pendant l'illusion : counter + bonus 1.1 s pour Itachi, +.32 s de récupération pour la victime (`:266-285`, `Combat.luau:826-835`) | Byakugan immunisé ; interrompre le channel de .9 ; ne pas frapper à vide ; projectiles. IA leurrée à 65 % (`AI.luau:75-80`) |
| Great Fireball | 26 | .55 / .42 / .36 | 5.5 | 76, vitesse 58 | Volume de rayon 2.4 (+2.2/s), dégâts 16, Knockback 44. Raté : sol brûlant de rayon 7.5 pendant 3.2 s, plus une éclaboussure de 8 (`Elements.luau:15-28`, `Combat.luau:1054-1068`) | Pas de côté ; la garde absorbe (pas de sol brûlant) ; punir la récupération. Feinte : remboursement de 35 % |
| Phoenix Flower | 20 | .3 / .32 / .3 | 5 | 60, vitesse 72 | 5 flammes (dégâts 4) à .06 s d'écart, latérales ±5/±2.5, petites zones de brûlure (`Elements.luau:32-59`) | Garde ; avancer en diagonale |

- **Mouvement pendant l'usage** : channel 7 studs/s, actif/récupération 12 (`Motor.luau:206-210`). Pas de jutsu en l'air ni au mur (`Rules.canAct`).
- **MANQUE** : aucune technique ne convertit avec une autre (feu ↔ lames, cf. ITACHI.md « geometry → fire lane ») ; Fireball et Phoenix **quasi identiques à Sasuke** (`Fighters.luau:117-118`).

### 7. Garde / défense

- **Sharingan** (passif, `Fighters.luau:39`, `Server/VelmoraDefense.luau:17-41`) : parry 0.30 s (base 0.20), perfect dodge 0.22 s (base 0.13) ; chacun ouvre un counter de 0.9 s → CounterPalm.
- **Suivi de téléportation** : garde levée et attaquant téléporté depuis moins de .7 s → coup traité en frontal, Itachi pivote (`Combat.luau:164-170`).
- **Garde, guard break, clash** : communs (stamina, `VelmoraCombatConfig`) ; garde à chakra 0 sur Heavy/Slam → GuardStun (`Brawler.luau:486-487`). Anti-air : Launcher et Read, rien de dédié. Air / mur : wall tech commun (coût 12).
- **MANQUE** : aucune garde propre face aux projectiles (Read les ignore) ; pas de déviation lame contre lame (DEF-005). **DÉCISION** : `GuardStrength .08` est une donnée morte (aucun usage dans `src/`).

### 8. Esquive et substitution

- **Dodge** : commun (coût 10, CD .8, durée .32, i-frames .22, 13.7 studs) ; fenêtre parfaite élargie à .22 s, ×1.5 en éveil.
- **Substitution** (`Config.luau:14`) : coût 15, 2 charges, recharge 9 s, CD 1.1 ; fenêtre .42 s après avoir été touché ; tracking .75 s pour l'attaquant.
- **Twist Itachi** : mode `crow`. Réapparition à 5.5 studs **derrière l'attaquant**, face à lui, si l'emplacement est libre et en ligne de vue ; sinon hop de 8 studs (`Combat.luau:397-405,444` ; test `tests/Phase4.spec.luau:96`). VFX : 10 corbeaux (`Client/Effects.luau:688-692`).
- **Punition / bait** : tracking E .75 s, et le crow est prévisible derrière soi. Retour au neutral : Recovery .14.
- **SIGNALÉ (lore)** : « crow clone » = imagerie d'Itachi adulte → voir la table lore.

### 9. Rush / poursuite

- **Existe** : chase commun (coût 8, 46 studs) après Launcher (1.15 s), knock-away (.8 s), splat ou rebond ; Rush commun ; poursuite assistée par outil : les `coverBlades` gardent le corps en l'air et occupent la récupération adverse.
- **Casser la poursuite** : substitution, wall tech, dodge aérien.
- **MANQUE** : pas de re-entry propre après disengage ; un ricochet ou une Geometry qui touche n'ouvre aucune fenêtre `pursuitUntil`.

### 10. Chakra

- **Réserve et recharge** : 125 max, 7.2/s (plein en ~17 s) ; pas de recharge en channel ni en Stunned (`Combat.luau:786-792`). Kit complet : 110 chakra pour les 5 techniques.
- **Spécialités** : remboursement Read +10, feinte de Fireball (+35 % du coût), éveil `CostScale .6`.
- **Low chakra** : aucun état dédié ; restent gratuits le chain tool et le disengage ; l'IA recule sous 18 (`AI.luau:243`).
- **MANQUE (SYS-001)** : le low-chakra n'a pas de conséquence propre sur la défense, hors guard break à 0.

### 11. Infusion / interactions de chakra

- **Existe** : `Katon + raté + sol` → couloir de feu ; `shuriken + mur + angle` → ricochet ; `shuriken + shuriken + timing` → redirection Geometry (ces deux derniers relèvent de la maîtrise d'outil, pas du chakra).
- **MANQUE** : aucune règle « Objet + Nature + Déclencheur » propre (TOOL-006 OPEN) ; pas de feu ↔ shuriken (lame enflammée). **DÉCISION** : pas de renforcement corporel ni de seal, non identitaires.

### 12. Éveil — SHARINGAN FOCUS

- **Paramètres** (`Fighters.luau:46`, `Combat.luau:472-502`) : PV ≤ 35 %, une fois par match, 12 s ; à l'entrée, +40 chakra, reset des CD, invulnérabilité .45 s, repousse à moins de 9 studs.
- **Règles** : fenêtres parry/perfect dodge ×1.5 (.45 / .33) ; coût des jutsus ×.6 (remboursement 40 %) ; CD ×.6 ; regen ×1.4 ; vitesse ×1.06 ; dégâts ×1.12. Contrepartie : aucune, hors durée.
- **MANQUE (SYS-003)** : modificateurs presque tous numériques, sans nouvelle règle de jeu (ni cancel, ni route ajoutée).
- **DÉCISION lore** : le Mangekyō du blueprint (`docs/characters/ROSTER_MOVESETS_10_PRODIGIES.md:168-175`) est absent du code (grep vide), à garder exclu.

### 13. États et réactions

- **Crée** : Knockback (CounterPalm, L3, AirDrive, Fireball) ; Knockdown (Sweep, Heavy) ; Launched, Juggled, Spiked (+ ground bounce) ; WallSplat via knockback, pin prolongé par lames ; Stunned (Read .48, parry .5) ; « exposed » (MirageCatch, +.32 s de récupération).
- **Exploite** : garde frontale → flanc (Geometry) ; engagement → Read ; whiff → genjutsu.
- **MANQUE** : pas d'OffBalance ni de GuardOpen dédiés ; aucun Bound ; aucune disruption de chakra adverse (`docs/FOUR_CHARACTER_COMBAT_MATRIX.md:21`).

### 14. Boucle de jeu

- **Représentative** : `garder 10 studs → paire de shuriken → Geometry côté (force la garde à tourner) → Read sur l'approche → CounterPalm → chase → coverBlades → AirSpike → reset à distance`
- **Agressive** : `L1 → L2 (aiguille) → FeintStep (flanc) → L3 (recul auto) → ↑ Launcher + coverBlades → E → Air1 → AirDrive vers mur → lames qui pin → Heavy rebond`
- **Défensive** : `garde haute → parry Sharingan .30 → CounterPalm (Knockback) → shuriken de couverture ; ou crow derrière l'attaquant → riposte`
- **Low-chakra** : `strings courts → chain tool gratuit → disengage gratuit (hop + 2 lames) → ricochets au mur → recharge 7.2/s → Read seulement quand ≥14`
- **Feu / zone** : `Great Fireball feinté (35 % rendus) → vraie boule → raté = couloir de 7.5 → Phoenix pousse dans la zone`
- **Air / mur** : `éventail de 3 lames en l'air → AirSpike → ricochet sur mur proche` (pas de route mur propre : voir §4).

### 15. Skill ceiling

- **Débutant** : spam de shuriken et Fireball, strings L1-L3, Read au hasard.
- **Intermédiaire** : Geometry contre une garde ; Read seulement sur un engagement frontal ; CounterPalm dans la fenêtre de .9–1.0 s ; feinte de Fireball.
- **Expert** : place l'adversaire entre lui et un mur pour les ricochets ; vise l'esquive prévisible avec les lames cachées de Shadow Shuriken ; conditionne au whiff sous Mirage ; gère 125/7.2 de chakra sans tomber sous 14+15 (Read + substitution) ; anticipe le tracking adverse après le crow.
- **Ce qui sépare les niveaux** : angle (côté de la Geometry), timing (Read 1 s, parry .3), position (mur), et non la longueur des inputs.

### 16. Signature irremplaçable

- **Ce qui le rend unique** : Itachi est le seul à **transformer l'action adverse en ouverture sans se déplacer** : coup frontal → Read ; coup dans le vide → Mirage ; garde frontale → lame de flanc (`hitOrigin`) ; mur → ricochet.
- **Ce qu'un clone ne reproduirait pas** : la règle d'origine latérale, `readCounter` et la punition de whiff. Mêmes stats et 4 autres jutsus ne suffiraient pas.
- **Fragilité** : feu partagé avec Sasuke ; Sharingan partagé ; aucune règle d'éveil.

### Exigence de différenciation

| Axe | Itachi (Mirage) | Minato (Flashstep) | Neji (GentleFist) | Sasuke (Lion) |
|---|---|---|---|---|
| Neutral | 10 studs, paire de shuriken, Geometry | 6, kunai et seals | 5, paumes | 6, shuriken agressifs et wire |
| Mouvement | 18 / sprint 45, droit, controlled | 19.5 / 50.4, springy | 18.5 / 45, bas et latéral | 19 / 49.5, springy |
| Silhouette taijutsu | paume, side kick, recul auto | coupes en angle | paumes | kicks |
| Launcher | + coverBlades | + seal sur corps | nu | LionKick + ShadowLeaf |
| Poursuite | commune + lames | FTG | commune | auto-chase |
| Mur | ricochet, CounterPalm (non steeré) | seals surface | VacuumPalm / PalmThrust | commun |
| Air | éventail 3 | RasenganDrop | commun (clips Itachi !) | LionBarrage |
| Outils | Geometry / ricochet / chain sur garde | marqués | secondaires | wire → Dragon Flame |
| Chakra | gros pool, regen basse, remboursements | regen 8 | draine l'adversaire | Curse : drain PV |
| Défense | Sharingan .30 / .22 + Read | commune | Byakugan 360 + Rotation | Sharingan .24 / .18, sans readCounter |
| Éveil | fenêtres et coûts (numérique) | vitesse / CD | NoBlindSpot, Drain ×1.8 | vitesse / dégâts, drain PV |
| Règle tordue | lame de flanc, whiff → punish | téléport | sceller le chakra | fil → feu |

**Chevauchements à traiter** : FireBloom/PhoenixFlower (mêmes IDs, chiffres proches de Sasuke) ; Sharingan (même mécanique que Sasuke, fenêtres plus étroites chez lui) ; Neji hérite des clips Mirage pour l'air et les throws (`VelmoraMotionEngine.luau:510-512`, CHR-NEJ-002).

### Labels lore par capacité

**Stade** : Itachi ~11–12 ans, ANBU, 3 tomoe, pré-Mangekyō. **Repères canon** (Databook / wiki, détails à vérifier) : académie à 7 ans, Sharingan à 8, chûnin à 10, ANBU vers 11, capitaine ANBU et massacre à 13.

| Capacité (code) | Label | Justification / source |
|---|---|---|
| Sharingan 3 tomoe passif (`Fighters:39`) | CANON_YOUNG (œil) ; fenêtres = GAMEPLAY_LIBERTY | Sharingan éveillé à 8 ans (Databook). Date exacte des 3 tomoe : à vérifier |
| Suivi de téléportation (`Combat:164`) | GAMEPLAY_LIBERTY | Règle de matchup contre FTG. Coût : garde levée et < .7 s |
| Sharingan Read | PLAUSIBLE_YOUNG | Perception du Sharingan (lecture des mouvements). Posture de counter d'1 s = mécanique de jeu |
| CounterPalm, Sweep, strings, side/back kick | PLAUSIBLE_YOUNG | Taijutsu d'élite. Scène jeune précise : à vérifier (anime « Itachi Shinden », Shippuden ép. ~451-458, à vérifier) |
| Paire de shuriken, éventail aérien | CANON_YOUNG | Démonstration d'entraînement devant Sasuke enfant, lancers en saut. Flashback de Sasuke, arc de la Vallée de la Fin (Partie I) ; n° de chapitre/épisode et âge exact (~11 ans, écart 5 ans) à vérifier |
| Shuriken Geometry | CANON_YOUNG | Même scène : une lame en dévie une autre pour toucher la cible cachée (angle mort) |
| Ricochet mur | PLAUSIBLE_YOUNG | Extension de la déviation de la même scène ; mur au lieu de lame |
| Shadow Shuriken (lames cachées) | PLAUSIBLE_YOUNG | Technique d'outil de Partie I (utilisée par Sasuke au pays des Vagues) ; usage jeune d'Itachi non montré |
| L2 « needle » (alias shuriken), cancels outil sur garde, disengage | GAMEPLAY_LIBERTY | Liberté ; dégâts 2, portée 11–22 |
| FeintStep (afterimage) | PLAUSIBLE_YOUNG | Shunshin / vitesse ; pas d'illusion réelle |
| Genjutsu : Mirage (leurre) | PLAUSIBLE_YOUNG | Genjutsu du Sharingan sans Mangekyō. Scène jeune exacte : à vérifier. **VFX de corbeaux** (`Effects:473-475`) = imagerie adulte, à requalifier |
| Great Fireball | PLAUSIBLE_YOUNG | Rite Katon Uchiha (scène de Sasuke enfant avec Fugaku) ; usage à l'écran par Itachi jeune : à vérifier |
| Couloir de feu (sol brûlant), feinte de jutsu | GAMEPLAY_LIBERTY | Contre-jeu : la garde absorbe, pas de côté, remboursement partiel seulement |
| Phoenix Flower | PLAUSIBLE_YOUNG | Katon Uchiha ; montré chez Itachi adulte (Partie II) ; usage jeune à vérifier |
| Substitution standard | CANON_YOUNG | Kawarimi, technique de base de l'académie |
| Substitution mode « crow clone » (`Combat:397-405`, `Effects:691`) | Mécanique GAMEPLAY_LIBERTY ; habillage **REJECT_ADULT_ONLY sauf source jeune** | Clone-corbeau = Itachi adulte (Partie II). Lien aux corbeaux de Shisui à ~13 ans : à vérifier. Présent dans le code : **à signaler** |
| Éveil SHARINGAN FOCUS | PLAUSIBLE_YOUNG | Concentration, sans Mangekyō. Qualité de règle insuffisante (SYS-003) |
| Mangekyō, Tsukuyomi, Amaterasu, Susanoo (blueprint `:168-175`) | REJECT_ADULT_ONLY | Postérieurs à la mort de Shisui (~13 ans). Absents du code |
| `Age = 13` (`Fighters:31`) | DÉCISION | Âge du Mangekyō : préférer 12 ou préciser « pré-Shisui » |
| Costume (`World.luau:455-470`) | OK | Pas d'Akatsuki dans `src/` |

### Propositions (candidates, non implémentées)

1. **Couloir de feu + Geometry** (CHR-ITA-002, SYS-002) — une lame redirigée qui traverse un sol brûlant d'Itachi devient « enflammée » (+1 dégât, petite zone de 2 s), ce qui distingue son feu de celui de Sasuke. Contre-jeu : zone visible ; garde de flanc ou dodge ; suppose un Fireball raté (−26). GAMEPLAY_LIBERTY.
2. **CounterPalm orienté mur** (CHR-CORE-001, COM-004) — coder le steering annoncé dans `MoveGraphs.luau:37-38` (mur à moins de 12 studs dans un cône de 45° → l'impulsion le vise). Contre-jeu : wall tech (Q), substitution. PLAUSIBLE_YOUNG.
3. **Éveil = règle** (SYS-003, CHR-CORE-002) — sous Focus, un parry ou Read réussi montre pendant .5 s la prochaine action adverse (télégraphe client) et la punition de whiff couvre aussi les jutsus ratés ; retirer le +12 % de dégâts. Contre-jeu : ne rien engager pendant 12 s ; projectiles. PLAUSIBLE_YOUNG (perception du Sharingan, sans Mangekyō).
4. **Substitution « de jeunesse »** (CHR-CORE-002, DEF-002) — garder la réapparition derrière l'attaquant, avec habillage kawarimi/bûche + afterimage et au plus 1–2 corbeaux (si une source jeune est confirmée). Contre-jeu inchangé (tracking .75 s). GAMEPLAY_LIBERTY.
5. **Ricochet → fenêtre de poursuite** (TOOL-005, TOOL-002) — un ricochet ou une Geometry qui touche ouvre `pursuitUntil` .5 s, pour lier outil et re-entry. Contre-jeu : garde de flanc ; Pursuit coûte 8. PLAUSIBLE_YOUNG.

### État — convergence 2 (identité, 2026-10-16)

Code de `claude/nd-ccc2-identity` ; détails, tests et poses demandées : [IDENTITY_JUTSU](../../reports/convergence2/IDENTITY_JUTSU.md). Validé en headless uniquement : le visuel et le ressenti restent à juger dans Studio.

- **Mirage refondu (kit de base)** :
  - l'image reste où il se tenait et il recule de 5,5 studs derrière elle, sur la ligne de l'adversaire ;
  - seul un coup qui atteint l'image est pris (étourdissement 0,55 s, puis CounterPalm qui traverse l'image) ;
  - l'illusion finit quand on la touche, sur un coup reçu ou porté, et face au Byakugan ;
  - l'image est dessinée chez la victime (copie exacte et liseré rouge) et chez Itachi (image rouge) ;
  - « ECHO? » supprimé ; canal 0,42 s, 26 chakra.
- **Read visible** : glissade de 2,2 studs, image rémanente mordue, lueur des yeux, counter avec allonge. Un coup pressé dans la posture part en counter instantané.
- **Sharingan Focus = règles** : la garde levée lit (une fois par levée), et les coups ratés près de lui sont lus. Bonus de dégâts retiré.
- **MANQUE toujours** : poses dédiées (glissade, posture Read, retrait Mirage) et validation Studio. Le substitut corbeau garde son habillage (DEC-005).

Sources code lues : `src/Shared/{Fighters,MoveGraphs,Attacks,Config,Rules,VelmoraCombatConfig,Controls(partiel)}.luau`, `src/Server/{Techniques,Elements,Brawler,Combat,VelmoraDefense,AI,Motor(partiel),World(dressItachi)}.luau`, `src/Client/{VelmoraMotionEngine(stance/gait/clips Mirage),Effects(corbeaux/Sharingan/Katon),Presentation(illusion)}.luau`, `tests/{Tools,Phase4}.spec.luau` ; docs FIGHTER_TEMPLATE, ITACHI, CORE_ROSTER, DECISIONS, FOUR_CHARACTER_COMBAT_MATRIX, ROSTER_MOVESETS_10_PRODIGIES §2, MASTER_BACKLOG, COMBAT_INVENTORY.json (survol).
