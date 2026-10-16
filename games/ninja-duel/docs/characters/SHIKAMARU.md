# Shikamaru — contrôle et préparation (vague d'archétypes)

Code proposé : `Imitation` (absent du code ; Kagemane = imitation par l'ombre). IDs : CHR-EXT-002, NET-001 (autorité/prédiction), ARENA-001/003, AI-001, SYS-001.

> Fiche de conception Claude du 2026-10-16 (mission [COMBAT_CONVERGENCE_ONLINE_ROSTER](../missions/COMBAT_CONVERGENCE_ONLINE_ROSTER.md) §18–21, DEC-012/DEC-013). Rien n'est implémenté ; valeurs = points de départ à régler en natif. Code lu sur `c2d797c` (chemins relatifs à `games/ninja-duel/src/`, le nom de fonction fait foi). Sources canon « à vérifier » non confirmées. Plan : [ROSTER_WAVE_PLAN](ROSTER_WAVE_PLAN.md) ; hooks : [ROSTER_WAVE_HOOKS](ROSTER_WAVE_HOOKS.md).

## Stade retenu (DEC-013)

**Examen chûnin → récupération de Sasuke (12–13 ans)** : Kagemane, étranglement par l'ombre, usage des ombres du terrain (mur de l'arène, tunnel, parachute improvisé), réserve de chakra faible, génie tactique. Hors stade : Kage Nui, shuriken d'ombre, lames d'Asuma (Partie II) ; aucune échelle adulte à craindre.

## Pourquoi il mérite une place (système éprouvé)

1. **Contrôle par mimétisme** (H10) : pendant la possession, **le serveur remplace l'intention de mouvement de la victime** par celle de Shikamaru, en miroir. C'est le test le plus dur pour l'autorité serveur et la future prédiction client (NET-001) : un client possédé ne doit pas prédire ses propres pas. Aujourd'hui `a.move` est écrit par l'input (`Server/Matches.luau`) ou par l'IA (`Server/AI.luau:101-104`) sans arbitrage.
2. **Projectile au sol dirigeable** (H15) : l'ombre suit le sol et se dirige au stick ; le client ne sait reconstruire qu'une ligne droite (`Client/Effects.luau:310-358`).
3. **L'arène et les objets des autres comme ressources** : ombres statiques du stade (ARENA-001/003) et **ombres des objets** des autres fighters (mur de Kakashi, miroirs de Haku, mur de sable de Gaara, clones de Naruto) servent de relais. Il éprouve le registre d'objets (H11) et d'entités (H12) **en consommateur**.
4. **Identité « low-chakra »** : la plus petite réserve du roster ; la durée de contrôle dépend de son chakra.

## Mécanique signature

**Kagemane, imitation mutuelle** : l'ombre (lente, visible, dirigeable) touche les pieds d'un adversaire **au sol** → possession jusqu'à `min(2.5, 0.8 + chakra/40)` s, drain 8/s. La victime **copie ses mouvements** (il avance : elle avance ; il recule : elle recule, chacun dans son repère) et ne peut ni frapper ni lancer. Mais Shikamaru est lié aussi : il ne peut pas frapper normalement. Il gagne en **déplaçant** la victime : contre un mur (cambrure → la tête de la victime heurte le mur : splat), dans son fil-piège, sous son étranglement.

## Fiche FIGHTER_TEMPLATE

### 1. Identité
- PROPOSÉ `Fighters.Imitation` : « THE SHADOW STRATEGIST » (à valider), `Age = 12`, HP 125, **chakra 90** (le plus bas), regen 8.5, vitesse 17.5, sprint ×1.0, saut ×1.0, air ×0.95, accél. ×1.0, `CombatDamage 0.9`, `PreferredRange 14`, `Tool = "Kunai"`.
- Fantasy : le paresseux qui a déjà gagné dans sa tête. Rôle : contrôle/préparation. Rythme : lent, puis une capture qui décide l'échange. Distance : 12–25.
- Forces : contrôle total court, utilisation du terrain. Faiblesse : taijutsu faible, chakra minuscule, l'ombre lente s'évite en sautant, aucun dégât direct important.
- Question : « Où peux-tu marcher sans toucher mon ombre ? »

### 2. Mouvement
- PROPOSÉ : stance nonchalante (mains basses, épaules tombantes) ; démarche `stride .95, cadence .9, arm 14, lean -2, bob .6, guard .2` ; intro mains dans les poches **à éviter** (celle de Sasuke, `Client/VelmoraMotionEngine.luau:1709-1711`) → intro « soupir, doigts joints ».
- Pendant l'extension de l'ombre : déplacement lent (vitesse de canal 7, `Config.ChannelSpeed`).
- DÉCISION : pas de mouvement signature rapide ; course murale commune.

### 3. Neutral / entrée en combat
- Il n'entre pas : il **attend** qu'on traverse ses ombres. Poke : kunai (vitesse 88, récupération 0.7) ; fil-piège (§5).
- Forcer une réaction : l'ombre qui avance oblige à sauter ou à s'écarter ; un relais d'ombre proche de l'adversaire étend sa menace.
- Sortir : string de 2 (repousse), substitution commune.
- À respecter : chaque zone d'ombre de l'arène et des objets, le fil tendu, sa jauge de chakra (durée de possession).

### 4. Taijutsu et combos (H02 : string de 2)
| Entrée | Move proposé | Fonction |
|---|---|---|
| L1 → L2 | **paume qui repousse** (3 studs) → **front kick** (Knockback 30) | crée de l'espace, dégâts faibles (4/7) |
| ↓ (après 2) | **Trip** (croc-en-jambe, Knockdown) | au sortir du relevé (invulnérabilité finie, comme pour le Cercueil de Gaara), l'adversaire ne peut pas sauter tout de suite : bonne cible d'ombre |
| Lourd après 1 coup | **KunaiCut** (entaille, stagger) | |
| Lourd pendant la possession | **Cambrure** : si la victime a un mur à ≤ 3 studs derrière elle, elle s'y cogne (WallSplat + 8 dégâts) | conversion par le terrain |
| ↑, ←→, air | DÉCISION : **aucune** route verticale, latérale ou aérienne propre | il ne jongle pas ; la grammaire commune reste disponible (Air1/Air2) |

### 5. Armes et ninja tools
- **Kunai** générique ; **fil-piège** : deux kunai plantés (sol ou mur) se relient par un fil visible (10 s, 1 paire) ; le traverser en courant fait trébucher (Knockdown léger 0.5 s) ; se franchit en marchant ou en sautant. Coût 4 par kunai.
- Infrastructure : fil existant (`kind = "wire"`, `Server/Techniques.luau:319-335`) et plantation (`onSurface`).

### 6. Jutsus / techniques
| Technique | Coût | Canal/actif/récup | CD | Effet | Contre-jeu |
|---|---|---|---|---|---|
| Kagemane (ombre) | 8 + 6/s d'extension | maintien (H09) ; vitesse 22 studs/s ; portée 20 + relais | 3 | possession (signature) ; relâcher le bouton la rétracte | sauter (un corps en l'air n'est pas pris), s'écarter (virage limité à 120°/s), frapper Shikamaru (interruption) |
| Kage Kubi Shibari | 12 | .3 / possession restante / .3 | 8 | pendant la possession : 4 dégâts/s et −5 chakra/s à la victime ; Shikamaru enraciné | substitution (≥ 25 chakra), attendre la fin |
| Ombre portée (parachute) | 10 | .2 / 3 s / .2 | 6 | veste + kunai qui flotte au-dessus d'un point à ≤ 28 studs : disque d'ombre de 6 studs = relais | se tenir hors du disque, le précéder |
| Plan (pose de réflexion) | 0 | 1.2 immobile interruptible | 12 | la prochaine Kagemane : portée +50 %, durée +1 s, coût −50 % | le frapper pendant la pose |

### 7. Garde / défense
- Garde/parry communs. Twist : **ombre réflexe** : après un parry ou un perfect dodge, une ombre courte (6 studs, visée auto) possède 0.6 s (coût 8).
- Pendant la possession, toute frappe reçue par Shikamaru la rompt.

### 8. Esquive et substitution
- Esquive et substitution communes (`hop`). DÉCISION argumentée : sa défense est d'empêcher le contact, pas de s'en échapper (il abandonne quand il est à court, canon). Il fait partie des fighters autorisés à garder la substitution par défaut ([ROSTER_WAVE_PLAN](ROSTER_WAVE_PLAN.md), règle 6).
- **Victime possédée** : peut seulement se substituer, au coût de 25 (kawarimi forcée : les mains sont liées).

### 9. Rush / poursuite
- DÉCISION : aucune poursuite. Conversion = déplacement de la victime (mur, fil, étranglement), puis libération (victime « libérée » 0.3 s).
- Casser son contrôle : rester en l'air au bon moment, éviter les ombres, le punir pendant le Plan ou l'extension.

### 10. Chakra
- 90 / 8.5 ; l'extension et la possession coûtent au temps (H05). Low-chakra : ombre courte, possession de 0.8 s : il redevient faible. C'est voulu : **la jauge est sa barre de menace**.

### 11. Infusion / interactions de chakra
- `ombre + objet/entité (qui projette une ombre) → relais` ; `ombre + zone d'ombre de l'arène → relais`. Pas de nature élémentaire.
- Hiden Nara : **non copiable** par Kakashi.

### 12. Éveil — DEUX CENTS COUPS D'AVANCE
- Règles (12 s) : (1) l'ombre se divise en deux (deux directions, prise par le flanc) ; (2) une possession rompue peut être reprise gratuitement si l'ombre touche encore ; (3) toutes les ombres de l'arène servent de relais et les coûts sont divisés par deux.
- Contrepartie : à la sortie, **chakra à sec** : chakra 0, regen ×0.5 pendant 4 s.

### 13. États et réactions
- Crée : **Possédé** (nouvel état de contrôle, distinct de `Bound` : la victime bouge, mais pas d'elle-même), Knockdown (Trip, fil), WallSplat (cambrure), étranglement (dégâts et drain sur durée).
- Exploite : adversaire au sol ou en train de se relever, murs, objets et clones des autres.

### 14. Boucle de jeu
- Représentative : `kunai + kunai (fil tendu) → Plan à distance → Kagemane par le relais du mur → possession → reculer (la victime recule dans le fil) → cambrure contre le mur → étranglement → libérer`.
- Défensive : `string de 2 → recul → ombre réflexe sur la riposte`.
- Low-chakra : `kunai et fil seulement, attendre 30 de chakra`.
- Matchup : contre Haku/Kakashi/Gaara/Naruto, leurs objets et clones deviennent ses relais.

### 15. Skill ceiling
- Débutant : ombre droite vers l'adversaire (évitée en sautant).
- Intermédiaire : ombre lancée sur le relevé ou la récupération, relais du stade, fil-piège.
- Expert : chaîne relais → possession → géométrie (mur derrière la victime, fil sur sa trajectoire) ; Plan placé au seul moment sûr ; gère la durée en fonction du chakra ; utilise les objets adverses.

### 16. Signature irremplaçable
Shikamaru est le seul fighter qui **déplace l'adversaire avec son propre corps** et dont la victoire vient de la géométrie de l'arène et des objets des autres. Quatre jutsus de dégâts sur ses stats en feraient le plus faible du roster ; l'imitation en fait le plus dangereux à mal positionner.

## Différenciation

| Axe | Shikamaru | Minato | Itachi | Neji | Sasuke |
|---|---|---|---|---|---|
| Neutral | 12–25, ombres, attente | 6, sceaux | 10, Geometry | 5 | 6 |
| Contrôle | **possession** (la victime bouge) | — | genjutsu (leurre) | scellement des techniques | fil (Bound 1 s) |
| String | **2**, repousse | 3 | 3 | 3 | 3 |
| Terrain | ombres + objets des autres | marques au sol/murs | ricochet | carry au mur | commun |
| Chakra | le plus petit, durée de contrôle | regen 8 | réserve 125 | drain adverse | coûts lourds |
| Éveil | ombre divisée, relais | vitesse/CD | fenêtres | sans angle mort | stats + drain |

| Vague | Recouvrement | Ce qui les sépare |
|---|---|---|
| Kisame | bind | Suirō fige les deux ; Kagemane fait bouger les deux en miroir |
| Gaara | contrôle par le sol | le sable attrape et écrase ; l'ombre possède et déplace |
| Kakashi | relais posés | relais de foudre (les siens) vs relais d'ombre (ceux de tous) |
| Temari | contrôle à distance | Temari interdit des lignes ; Shikamaru capture un corps |
| Haku | objets | les miroirs de Haku sont ses relais |
| Naruto | — | les clones projettent des ombres ; la possession du vrai Naruto n'arrête pas ses clones déjà lancés |
| Lee | — | Lee saute et dévie ; l'ombre au sol est lente : matchup de patience |

## Labels lore par capacité

| Capacité | Label | Source / justification |
|---|---|---|
| Kagemane (imitation par l'ombre) | CANON_YOUNG | préliminaires contre Kin, finale contre Temari, récupération de Sasuke (ch. à vérifier) |
| Mimétisme mutuel, victime cognée contre un mur | CANON_YOUNG | Kin se cogne la tête en imitant sa cambrure (préliminaires) |
| Ombres de l'arène et tunnel comme relais | CANON_YOUNG | finale contre Temari (ombre du mur, tunnel de Naruto) |
| Parachute (veste + kunai) | CANON_YOUNG (à vérifier) | finale contre Temari |
| Étranglement par l'ombre | CANON_YOUNG (à vérifier) | Partie I (adversaire et chapitre à vérifier) |
| Faible réserve, abandon | CANON_YOUNG | abandon contre Temari faute de chakra |
| Pose de réflexion (Plan) | CANON_YOUNG (caractérisation) | « 200 coups d'avance » |
| Corps en l'air insaisissable | GAMEPLAY_LIBERTY | contre-jeu lisible (en canon l'ombre au sol suffit) |
| Durée liée au chakra, coût au temps | CANON_YOUNG (concept) / GAMEPLAY_LIBERTY (valeurs) | |
| Fil-piège | PLAUSIBLE_YOUNG | pièges de genin ; scène Shikamaru à vérifier |
| Ombre réflexe | GAMEPLAY_LIBERTY | |
| Ombre divisée (éveil) | PLAUSIBLE_YOUNG (à vérifier) | prise multiple montrée plus tard |
| Kage Nui, shuriken d'ombre, lames d'Asuma | hors stade | Partie II |

## Plan d'implémentation

**Réutilisé** : réaction `Bound` comme modèle de tenue (`Brawler.step`, `:550`) ; refus d'actions par état (`Combat:request`, `Rules.canAct`) ; projectile `wire` et plantation pour le fil-piège ; `Brawler.splat` pour la cambrure ; `Config.ChannelSpeed` pendant l'extension ; drain par seconde (même boucle que la regen, `Combat:updateActor` `:813-819`).

**Nouvelles données** : `Fighters.Imitation` (stats §1, `Shadow={Speed=22,Reach=20,Turn=120,StartCost=8,ExtendCost=6,HoldDrain=8,MaxHold=2.5}`, `StringLength=2`) ; `MoveGraphs.Imitation` (`routes={down="Trip"}`, `heavyAfterOne="KunaiCut"`, `disengage="Kunai"`) ; `Attacks` : `ShovePalm/FrontKick` (H02), `Trip`, `KunaiCut`, `Arch` (cambrure) ; `Techniques` : `Kagemane`, `NeckBind`, `ParachuteShadow`, `Plan` ; régions d'ombre statiques taguées dans `Server/World.luau` (avec ARENA-001) ; IA : ombre sur le relevé/la récupération, Plan hors de portée, cambrure si mur, et **côté victime** : sauter quand une ombre approche.

**Hooks** : H10 (possession : intention miroir, refus d'actions, substitution à 25, arbitrage `a.move` IA/joueur, cue), H15 (ombre dirigeable au sol, réplication par points), H11/H12 en lecture (empreintes d'ombre des objets/entités), H06 (régions d'ombre comme zones), H09 (maintien), H05 (coût au temps), H17 (ombre réflexe au parry/perfect dodge), H02, H03, H01. Prérequis réseau : NET-001 doit savoir suspendre la prédiction d'un client possédé.

**Motion** : stance, démarche, intro ; clips propres : ShovePalm, FrontKick, Trip, KunaiCut, cambrure, Air1/Air2, Grab/Throw, Riposte ; poses : Kagemane (sceau du rat), étranglement (mains au cou… les siennes, la victime l'imite), parachute, Plan (doigts joints) ; **pose de victime possédée** (mêmes appuis, raideur).

**Effets/UI** : ombre au sol (ruban qui suit le sol), régions d'ombre lisibles sans les surligner (lisibilité de l'arène, ARENA-003), fil tendu, jauge de durée de possession visible des deux joueurs, cue « POSSÉDÉ • X (25) ».

**Tests** (`tests/Shikamaru.spec.luau`) : prise seulement au sol ; durée selon le chakra ; mouvement miroir (avancer/reculer/côté) ; actions refusées pendant la possession sauf substitution à 25 ; rupture si Shikamaru est frappé ; cambrure contre mur → splat ; relais statique et d'objet ; fil-piège (traverser en courant/en marchant) ; IA possédée ne réécrit pas `a.move` ; nettoyage fin de manche/KO ; duels IA contre les 12 ; test sans jutsu (attendu : faible, mais reconnaissable par kunai et fil — sinon décision explicite).

**Effort** : **L** (le plus sensible au réseau).

**Périmètre minimal jouable** : string de 2, kunai, Kagemane en ligne droite (non dirigeable) + possession miroir + cambrure + étranglement, relais des seules régions d'ombre statiques. Hors minimal : ombre dirigeable, relais d'objets/entités, parachute, fil-piège, Plan, ombre réflexe, éveil.

## Points à vérifier
- Scènes canon : étranglement, parachute, fil-piège ; prises multiples avant la Partie II.
- Règle « corps en l'air insaisissable » vs canon (à confirmer comme liberté).
- Comportement de la possession sous latence (NET-001) et confort de la victime (caméra, UX).
