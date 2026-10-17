> Snapshot historique avant harmonisation des fiches le18/10/2026. Conserver les idées et preuves ; état/priorités dans docs/active, nouvelle fiche au chemin d’origine.

> Documentation spécialisée de référence ; état dans [CURRENT_STATE](../../../active/CURRENT_STATE.md), travail et critères dans [MASTER_BACKLOG](../../../active/MASTER_BACKLOG.md). Les anciennes propositions et statuts ci-dessous ne fixent pas les priorités globales.

# Kakashi — généraliste adaptatif (vague d'archétypes)

Code proposé : `Kannabi` (absent du code ; le nom marque le stade). IDs : CHR-EXT-002, SYS-001/002, TOOL-002/006, DEF-001/003, PROG-001 (portabilité des techniques).

> Fiche de conception Claude du 2026-10-16 (mission [COMBAT_CONVERGENCE_ONLINE_ROSTER](../../missions/COMBAT_CONVERGENCE_ONLINE_ROSTER.md) §18–21, DEC-012/DEC-013). Rien n'est implémenté ; valeurs = points de départ à régler en natif. Code lu sur `c2d797c` (chemins relatifs à `games/ninja-duel/src/`, le nom de fonction fait foi). Sources canon « à vérifier » non confirmées. Plan : [ROSTER_WAVE_PLAN](../../../characters/ROSTER_WAVE_PLAN.md) ; hooks : [ROSTER_WAVE_HOOKS](../../../characters/ROSTER_WAVE_HOOKS.md).

## Stade retenu (DEC-013)

**Kakashi Gaiden, pont de Kannabi (≈13 ans), pré-Mangekyō** (exemple explicite de DEC-013) : jônin de fraîche date, sabre de chakra blanc de son père (tantō), Chidori **prototype** (vision en tunnel), Sharingan d'Obito tout juste greffé, qu'il ne peut pas éteindre (il n'est pas Uchiha). Échelle absente : Kamui et tout Mangekyō, Raikiri « nommé », Chien de foudre, Susanoo, ninken.

## Pourquoi il mérite une place (système éprouvé)

1. **Portabilité des techniques** (H16) : sa Copie exécute la technique d'un autre fighter avec Kakashi comme acteur. Cela oblige les modules de `Server/Techniques.luau` à être indépendants de `a.def` du lanceur d'origine — une exigence que la progression (PROG-001 : nœuds qui débloquent des variantes) aura aussi. Constat de lecture : `Elements.fire/phoenix/wind`, `NeedleFan`, `WireTrap` sont portables ; `bindInSand` (lit `owner.def.Techniques`, `:359`) et `SixtyFourPalms` (lit `a.def.GentleFist`, `:501`) ne le sont pas.
2. **Posture à coût continu** (H09 + H05) : Sharingan découvert = fenêtres et Copie, contre un drain de chakra par seconde, visible par l'adversaire.
3. **Terrain dynamique** (H11) : le mur de terre est un vrai objet (stoppe les projectiles et la ligne de vue, surface de splat et de **course murale**). Le moteur exige déjà l'attribut `NinjaWall` pour courir (`Server/Motor.luau:46`) et pour le splat (`Server/Brawler.luau:349`), et ignore tout ce qui est rangé dans `match.effects` (`Server/Combat.luau:66-71`).
4. **Objet + nature + contexte** (H07, TOOL-006) : la foudre conduite par le métal planté (le sien, les sceaux de Minato, les senbon de Haku) et par l'eau de Kisame — l'exemple de la mission « lightning conducted through wire/metal ».

## Mécanique signature

**L'œil d'Obito, couvert ou découvert.** Couvert (défaut) : aucun drain, fenêtres communes, Chidori en vision de tunnel. Découvert (technique 1, bandeau relevé : lisible) : drain 2.5 chakra/s, parry 0.26 / perfect dodge 0.2 / counter 0.8, **Mémoire** (chaque technique copiable vue à ≤ 35 studs dans ±90° remplit l'emplacement Copie), Chidori **dirigeable**. Toute la puissance de Kakashi dépend de ce qu'il a vu de l'adversaire et de combien il paie pour regarder.

## Fiche FIGHTER_TEMPLATE

### 1. Identité
- PROPOSÉ `Fighters.Kannabi` : « THE WHITE FANG'S SON » (à valider), `Age = 13`, HP 130, chakra 115, regen 7.8, vitesse 19, sprint ×1.08, saut ×1.05, air ×1.05, accél. ×1.1, esquive ×1.08, `CombatDamage 1.02`, `PreferredRange 7`, `Tool = "Kunai"`.
- Fantasy : le génie qui apprend en combattant. Rôle : généraliste adaptatif. Rythme : mesuré, puis punition exacte. Distance : 6–12.
- Forces : réponses à tout (perforation, mur, copie, foudre). Faiblesse : aucun extrême ; Sharingan coûteux ; contre un kit sans technique copiable (Lee, Neji, Gaara, Haku, Shikamaru, et Naruto tant que H12 n'est pas généralisé), la Copie reste vide : son kit de base doit suffire.
- Question : « Que vaut ton kit une fois que je l'ai vu ? »

### 2. Mouvement
- PROPOSÉ : stance basse et économe, tantō en prise directe main droite, main gauche prête au sceau ; démarche `stride 1.04, cadence 1.0, arm 28, lean 3, bob .8, guard .2` — entre Minato (springy) et Itachi (contrôlé), pour éviter les deux familles existantes (`Client/VelmoraMotionEngine.luau:262-264`).
- Mur : commun, plus **son propre mur** (Doryūheki) comme surface de course et de WallDive.
- Mouvement signature : relever le bandeau (pose courte, sans arrêter les jambes).

### 3. Neutral / entrée en combat
- Poke : kunai (vitesse 94, récupération 0.6) qui **se plante** et devient relais (§5).
- Fermer : Rush commun ; mur pour couper la ligne d'un zoneur et s'approcher à couvert.
- Lecture : découvrir l'œil quand l'adversaire va lancer une technique (il la verra) ; feinte de lourd commune.
- À respecter : le bandeau (découvert = fenêtres larges + Copie), ses relais plantés (cage de foudre).

### 4. Taijutsu et combos (tantō)
| Entrée | Move proposé | Fonction |
|---|---|---|
| L1 → L2 → L3 | **taille rapide** (portée 7, démarrage ×0.9) → **coupe croisée** → **estoc** (Knockback 40) | lame : portée et récupération propres, pas de kicks CORE4 |
| Bloqué → Lourd | **GuardKick** (low kick : −30 stamina de garde, garde brisée si vide) | **adaptation** : `blockCancels.Heavy` (n'existe que pour `Tool`, `Server/Combat.luau:635`) |
| ↑ (≥2) | **RisingCut** (taille montante, Launched 52) | launcher |
| ↓ (≥2) | **KunaiDrop** (balayage + kunai planté où l'adversaire tombe) | payoff `relay` (relais de foudre, ≠ sceau de Minato : pas de destination) |
| ←→ (≥1) | **ReadStep** (orbite 24) | découvert : un coup adverse pendant la phase active est esquivé et ouvre le counter |
| Lourd après 1 coup | **PiercingThrust** (estoc perforant) | drapeau `pierce` : casse l'armure (Kisame) et compte comme brise-bouclier (Gaara) |
| Read counter | `readCounter = "PiercingThrust"` | après parry/perfect dodge découverts |
| Air | Air1/Air2 tantō ; AirDrive/AirSpike/AirSwitch communs, clips propres | |

### 5. Armes et ninja tools
- **Tantō** (sabre de chakra blanc) : objet tenu (H01), arme des strings.
- **Kunai-relais** (TOOL-002) : un kunai qui touche une surface reste planté 8 s (3 au plus, le plus ancien disparaît). Pendant le Chidori, chaque relais à ≤ 10 studs de l'adversaire **décharge** sur lui (0.3 s d'étourdissement, 4 dégâts, une fois par relais). Conducteurs tiers : sceaux plantés de Minato, senbon persistants de Haku, zones d'eau de Kisame (H07).
- Substitution : laisse un relais au départ (§8).

### 6. Jutsus / techniques
| Technique | Coût | Canal/actif/récup | CD | Effet | Contre-jeu |
|---|---|---|---|---|---|
| Sharingan (bascule) | 0 + 2.5/s découvert | .15 (découvrir) / .1 (couvrir) | 1 | posture (signature) | ne rien montrer ; le forcer à rester découvert pour le vider |
| Chidori (prototype) | 30 | .55 interruptible (7 studs/s) / .26 / .62 couvert, .4 découvert | 8 | poussée de 18 studs, 20 dégâts, Knockback ; **couvert = ligne droite** (dépassement si raté) ; **découvert = dirigeable** (`Combat:turnToward` 360°/s) ; décharge les relais | pas de côté contre la version couverte ; interrompre la charge |
| Doton : Doryūheki | 20 | .3 / — / .25 | 9 | mur 8×6×1.5 à 4–12 studs, 40 PV, 6 s ; stoppe projectiles et ligne de vue ; `NinjaWall` (splat + course) | contourner, casser (lourds, feu ×1, Rasengan) |
| Copie | celle de l'original ×1.2 | celle de l'original | 6 | rejoue la dernière technique copiable vue, dégâts ×0.8 | ne pas montrer de technique copiable quand l'œil est découvert |

Liste blanche initiale de la Copie (H16) : Great Fireball, Phoenix Flower, Wind Cut, Shadow Shuriken, Wire Trap, Kamaitachi (1re lune), Suikōdan. **Non copiables** : kekkei genkai (sable, glace, Byakugan et tout le Jūken), hiden (ombre Nara), fūinjutsu (kunai marqué, téléport), clones (avant H12), techniques corporelles (Lee), genjutsu du Sharingan, Rasengan, Chidori (déjà le sien).

### 7. Garde / défense
- Couvert : garde/parry communs. Découvert : fenêtres Sharingan (via une surcharge de `def.Sharingan` portée par la posture — aujourd'hui champ statique lu par `Server/VelmoraDefense.luau:21` et le suivi de téléport `Combat.luau:169`).
- Anti-air : RisingCut ; défense contre zoneurs : Doryūheki.
- Clash d'arme : tantō contre lame (clash commun, `Brawler.clash`) — DÉCISION : pas de clash spécial.

### 8. Esquive et substitution
- Esquive commune. **Substitution « kawarimi + kunai »** : hop commun, un kunai-relais planté au point de départ. Contre-jeu commun (suivi 0.75 s) ; le relais est visible.

### 9. Rush / poursuite
- Poursuite commune ; Chidori découvert comme poursuite au sol (dirigeable) ; WallDive depuis son propre mur.
- Casser : sortir de la portée des relais, frapper la charge du Chidori.

### 10. Chakra
- 115 / 7.8 ; l'œil découvert coûte 2.5/s : 10 s découvert = 25 chakra. Low-chakra : il recouvre l'œil et redevient un épéiste à kunai ; la Copie reste chargée mais inutilisable.
- Spécialité : il **choisit quand payer pour l'information**.

### 11. Infusion / interactions de chakra (H07)
- `foudre + métal planté → décharge` ; `foudre + zone d'eau → choc dans la zone` ; `terre + projectile → arrêt` ; `tantō + estoc → perforation` (propriété d'attaque, pas une nature).

### 12. Éveil — L'ŒIL D'OBITO
- Règles (12 s) : (1) aucun drain découvert ; (2) la Copie garde **deux** techniques ; (3) Chidori à 2 charges, dirigeable même couvert ; (4) parry 0.3.
- Contrepartie : **œil épuisé** 6 s à la sortie (impossible de découvrir). Pas de multiplicateur de dégâts.

### 13. États et réactions
- Crée : Launched (RisingCut), Knockdown (KunaiDrop), Knockback (estoc, Chidori), Stunned court (décharge), garde brisée (GuardKick).
- Exploite : garde adverse (GuardKick), armure/bouclier (perforation), techniques adverses (Copie), métal et eau sur le terrain (relais).

### 14. Boucle de jeu
- Représentative : `kunai planté ×2 autour de l'adversaire → L1 L2 → ↓ KunaiDrop (3e relais) → découvrir → Chidori dirigeable → décharges → couvrir`.
- Adaptative : `découvrir pendant le Fireball adverse → Copie = Fireball → mur contre le suivant → Copie rejouée`.
- Défensive : `Doryūheki contre zoneur → course sur le mur → WallDive`.
- Low-chakra : `œil couvert, tantō + kunai, GuardKick contre la garde`.

### 15. Skill ceiling
- Débutant : string + Chidori en ligne droite (souvent raté), œil toujours découvert (se vide).
- Intermédiaire : découvre seulement pour voir/parer, place les relais avant le Chidori, mur contre les projectiles.
- Expert : rythme couvert/découvert serré, Copie choisie (il laisse passer une technique pour copier la plus utile), relais tiers (sceaux de Minato, eau de Kisame), GuardKick au bon moment, perforation contre armure et bouclier.

### 16. Signature irremplaçable
Kakashi est le seul fighter dont **le kit dépend de l'information prise sur l'adversaire pendant le combat** et dont **l'information se paie en continu**. Quatre jutsus fixes le rendraient générique ; sa Copie et son œil en font une réponse différente à chaque matchup.

## Différenciation

| Axe | Kakashi | Minato | Itachi | Neji | Sasuke |
|---|---|---|---|---|---|
| Neutral | 7, tantō + kunai-relais | 6, sceaux (destinations) | 10, Geometry | 5, paumes | 6, pression |
| Sharingan | **basculé, payé**, + Copie | — | permanent, Read | (Byakugan) | permanent, plus étroit |
| Chidori | prototype : tunnel couvert / dirigé découvert ; pas de string-cancel | — | — | — | string-cancel 0.14, finisher |
| Kunai planté | relais de foudre | sceau de téléport | — | — | — |
| Terrain | **crée** un mur | marque le sol | ricochet sur murs | pousse vers murs | commun |
| Éveil | règles de l'œil | vitesse/CD | fenêtres | sans angle mort | stats + drain PV |

| Vague | Recouvrement | Ce qui les sépare |
|---|---|---|
| Shikamaru | relais posés sur le terrain | les relais de Kakashi conduisent **sa** foudre ; Shikamaru emprunte **l'ombre de tous** les objets |
| Lee | taijutsu complet | Lee = élan et vitesse, sans arme ; Kakashi = arme, information, réponse |
| Kisame | — | perforation contre armure ; foudre dans son eau |
| Temari | — | Copie de Kamaitachi (1re lune) ; mur contre ses couloirs |
| Haku | métal planté | ses senbon persistants conduisent ; sa glace n'est pas copiable |
| Gaara | — | perforation = brise-bouclier ; sable non copiable |
| Naruto | clones | Kage Bunshin non copiable avant H12 |

## Labels lore par capacité

| Capacité | Label | Source / justification |
|---|---|---|
| Sharingan d'Obito greffé à 13 ans | CANON_YOUNG | Kakashi Gaiden, ch. 239–244 (pont de Kannabi) |
| Impossible à éteindre, drain de chakra | CANON (énoncé adulte, Partie I) → PLAUSIBLE_YOUNG | non-Uchiha ; il le couvre du bandeau (scène à vérifier) |
| Bascule couvert/découvert à volonté | GAMEPLAY_LIBERTY | coût continu + information visible |
| Fenêtres Sharingan découvert | PLAUSIBLE_YOUNG | perception du Sharingan (même logique que CORE4) |
| Copie | PLAUSIBLE_YOUNG | pouvoir inné du Sharingan ; le millier de techniques est adulte |
| Copie ×0.8, liste blanche, pas de kekkei genkai | GAMEPLAY_LIBERTY (règle canon pour les kekkei genkai) | le Sharingan ne copie pas un kekkei genkai (à vérifier) |
| Chidori prototype, vision en tunnel | CANON_YOUNG | Gaiden ; défaut expliqué par Kakashi en Partie I (scène à vérifier) |
| Chidori dirigé par le Sharingan | CANON (concept) / GAMEPLAY_LIBERTY (contrôle) | le Sharingan corrige le tunnel |
| Sabre de chakra blanc (tantō) | CANON_YOUNG | Gaiden (le sabre s'y brise, à vérifier) |
| String au tantō, GuardKick, perforation | PLAUSIBLE_YOUNG | jônin à 12 ans ; coups exacts non canon |
| Kunai-relais, décharge | GAMEPLAY_LIBERTY | foudre conduite par le métal (exemple de la mission) |
| Doryūheki | PLAUSIBLE_YOUNG | montré en Partie II ; affinité Terre à vérifier |
| Kamui, Mangekyō, Susanoo | REJECT_ADULT_ONLY | post-Rin / Partie II (DEC-013 : pré-Mangekyō) |
| Chien de foudre, nom « Raikiri », ninken | hors stade | Partie II ou datation à vérifier |

## Plan d'implémentation

**Réutilisé** : `Techniques.Chidori` et `Attacks.ChidoriThrust` (paramétrés : direction, recouvrement) ; `Combat:turnToward` (`:360`) pour diriger ; `def.Sharingan` et ses lectures (`VelmoraDefense.resolve`, suivi de téléport) ; `readCounter` (`Brawler.luau:261`) ; plantation de projectile (`onSurface`, `Combat:projectileSurface` `:1160`) ; `Brawler.splatSurface` et `Motor.tryWall` (attribut `NinjaWall`) pour le mur ; modules `Elements.*`, `NeedleFan`, `WireTrap` pour la Copie.

**Nouvelles données** : `Fighters.Kannabi` (stats §1, `ToolMastery={Kind="kunai",Count=1,Speed=94,Damage=3,Recover=.6,Relay={Life=8,Max=3}}`, `Stances={Covered=…,Uncovered={Drain=2.5,Sharingan={ParryWindow=.26,PerfectDodge=.2,Counter=.8}}}`) ; `MoveGraphs.Kannabi` (`routes={up="RisingCut",down="KunaiDrop",side="ReadStep",…}`, `onRoute={KunaiDrop="relay"}`, `heavyAfterOne="PiercingThrust"`, `blockCancels={Heavy=true}`, `readCounter="PiercingThrust"`, `disengage="Kunai"`) ; `Attacks` : `TantoSlash/TantoCross/TantoThrust` (H02), `GuardKick`, `RisingCut`, `KunaiDrop`, `ReadStep`, `PiercingThrust` (drapeau `pierce`) ; `Techniques` : `SharinganToggle`, `ChidoriProto`, `Doryuheki`, `Copy` ; IA : découvrir quand l'adversaire canalise, recouvrir sous 30 chakra, planter avant le Chidori, mur contre projectiles lents.

**Hooks** : H16 (Copie), H09 (posture), H05 (drain continu), H11 (mur), H07 (conduction), H08 (option : renvoi au tantō), H17 (substitution + relais), H02, H03, H01 ; petit hook `blockCancels.Heavy` dans `Brawler.request`.

**Motion** : stance, démarche, intro (il ajuste son bandeau sur l'œil gauche) ; clips propres : string tantō, GuardKick, RisingCut, KunaiDrop, ReadStep, PiercingThrust, Air1/Air2, Grab/Throw, Riposte ; poses : bandeau relevé/baissé, Chidori (charge main gauche ou droite à fixer), Doryūheki (mains au sol) ; objet tenu tantō.

**Effets/UI** : œil visible (Sharingan sur un seul œil), emplacement Copie dans la barre (icône de la technique copiée), relais plantés, arcs de décharge, mur de terre.

**Tests** (`tests/Kakashi.spec.luau`) : drain découvert, fenêtres seulement découvert ; Mémoire (vue, portée, angle) ; Copie exécutée avec Kakashi comme acteur, liste blanche respectée (refus du sable, de la glace, du Jūken) ; Chidori couvert en ligne droite, découvert dirigé ; relais : plantation, limite 3, décharge pendant le Chidori ; mur : bloque un projectile, ligne de vue IA, splat, course murale, destruction et nettoyage ; `blockCancels.Heavy` → GuardKick ; duels IA contre les 12 ; test sans jutsu (tantō + kunai reconnaissables).

**Effort** : **M/L** (L à cause de la Copie et du mur).

**Périmètre minimal jouable** : string tantō + GuardKick + perforation, bascule de l'œil avec drain et fenêtres, Chidori couvert/découvert, kunai-relais et décharge. Hors minimal : Doryūheki (attend H11), Copie (attend H16), conduction tierce et eau, éveil à règles.

## Points à vérifier
- Âge exact dans le Gaiden, sort du sabre, première apparition de Doryūheki, règle canon « pas de copie des kekkei genkai ».
- Main du Chidori et pose du bandeau (référence visuelle).
- Coût réseau de la Mémoire (événements de cast déjà dans le flux `cast`, `Combat.luau:793`).
