# Haku — angles, aiguilles et miroirs de glace (vague d'archétypes)

Code proposé : `Crystal` (absent du code). IDs : CHR-EXT-002, TOOL-001/002, DEF-002/005, ARENA-003, SYS-002.

> Fiche de conception Claude du 2026-10-16 (mission [COMBAT_CONVERGENCE_ONLINE_ROSTER](../missions/COMBAT_CONVERGENCE_ONLINE_ROSTER.md) §18–21, DEC-012/DEC-013). Rien n'est implémenté ; valeurs = points de départ à régler en natif. Code lu sur `c2d797c` (chemins relatifs à `games/ninja-duel/src/`, le nom de fonction fait foi). Sources canon « à vérifier » non confirmées. Plan : [ROSTER_WAVE_PLAN](ROSTER_WAVE_PLAN.md) ; hooks : [ROSTER_WAVE_HOOKS](ROSTER_WAVE_HOOKS.md).

## Stade retenu (DEC-013)

**Pays des Vagues (≈15 ans)**, masque de chasseur de Kiri : senbon, points vitaux (fausse mort), Hyōton, sceaux à une main, Mille aiguilles, Miroirs de glace démoniaques. Il n'existe pas de stade adulte : la seule escalade à éviter est l'**échelle** (dôme de 21 miroirs, ramené à 6 en éveil et à 2 en base).

## Pourquoi il mérite une place (système éprouvé)

1. **Réseau d'objets destructibles** (H11) : des miroirs physiques qui bloquent projectiles et lignes de vue, servent de **surfaces de splat**, d'**origines de tir** et de **portes de déplacement**, et se cassent. Aucun objet de gameplay persistant et solide n'existe aujourd'hui (les sceaux de Minato sont des points ; `Combat:effect` crée des pièces invisibles exclues des raycasts, `Server/Combat.luau:66-99`).
2. **Volées à origines multiples** : budget de projectiles, réplication (le client reconstruit chaque vol depuis `origin`, `Client/Effects.luau:310-358`) et lisibilité. `Combat:projectile` accepte déjà une origine explicite (`opts.origin`, `:300-313`).
3. **Vérité serveur vs reflets** (H12 visuel) : plusieurs images de Haku, un seul corps ; règle de perception (le Sharingan voit le vrai).
4. **Statut sur le mouvement adverse** (H04) : l'engourdissement modifie vitesse, esquive et saut de la victime — une perturbation de **mobilité**, distincte de la perturbation de **chakra** de Neji.

## Mécanique signature

**Miroirs de glace** (2 en base) : panneaux 3×5 posés jusqu'à 18 studs, 30 PV, 8 s, résistants au feu (dégâts ×0.3). Haku y **entre** et en **ressort** vers l'adversaire (Reflet), y **lance** ses senbon depuis leur surface, et s'y **réfugie** à la substitution. L'adversaire peut les casser, les contourner, ou s'en servir comme… murs (splat contre un miroir). En éveil, le dôme : 6 miroirs en anneau autour de l'adversaire.

## Fiche FIGHTER_TEMPLATE

### 1. Identité
- PROPOSÉ `Fighters.Crystal` : « THE ICE MIRROR » (à valider), `Age = 15`, HP 115 (le plus bas), chakra 110, regen 8, vitesse 18.5, sprint ×1.05, saut ×1.05, air ×1.1, accél. ×1.1, **esquive ×1.25** (la plus longue), `CombatDamage 0.92`, `PreferredRange 9`, `Tool = "Senbon"`.
- Fantasy : l'outil parfait, rapide et précis, qui ne veut pas tuer. Rôle : angles / projectiles / mobilité. Rythme : piqûres rapides, mise en cage, punition par le point vital. Distance : 6–18.
- Forces : vitesse, angles, ralentissement adverse. Faiblesse : PV et dégâts bas, miroirs cassables, kits anti-projectiles (Rotation, déviation de Lee, vent de Temari, absorption de Kisame, bouclier de Gaara).
- Question : « Où suis-je vraiment, et combien de pas te reste-t-il ? »

### 2. Mouvement
- PROPOSÉ : stance légère, de profil, senbon entre les doigts ; démarche silencieuse `stride .95, cadence 1.15, arm 20, lean 4, bob .5, guard .5` ; esquive longue et basse.
- Mouvement signature : **Reflet** (entrer dans un miroir, ressortir d'un autre) ; DÉCISION : pas de vol plané ni de course murale propre (ses murs, ce sont ses miroirs).

### 3. Neutral / entrée en combat
- Poke : 3 senbon (vitesse 110, la plus haute ; 1 dégât ; +1 engourdissement) ; depuis un miroir à ≤ 25 studs, la volée part **du miroir** (angle de flanc).
- Fermer : Reflet vers le miroir le plus proche du flanc adverse ; esquive longue.
- Forcer une réaction : un miroir posé derrière l'adversaire menace de flanc ; le casser coûte du temps.
- À respecter : ses miroirs (portes et canons), les crans d'engourdissement (4 = point vital).

### 4. Taijutsu et combos (H02 : string de 4)
| Entrée | Move proposé | Fonction |
|---|---|---|
| L1 → L2 → L3 → L4 | **aiguille** (démarrage ×0.75, le plus rapide) → paume → **aiguille basse** (jambes) → **coup de pied croissant** | dégâts bas (3/4/4/7) ; L1 et L3 : +1 engourdissement |
| ↑ (≥2) | **FrostCrescent** : relance à hauteur de taille (Juggled, `impulseY 26`), **garde la string** | Haku ne quitte jamais le sol : pas de phase aérienne |
| ↓ (≥2) | **IceSweep** (Knockdown) + plaque de glace 4 s, rayon 4 (H06 : adhérence ×0.4, esquive ×0.8) | punir le relevé |
| ←→ (≥1) | **PinFlick** : senbon dans le pied à bout portant, « pied cloué » 0.4 s (peut agir, pas bouger), +1 cran, garde la string | les routes latérales de CORE4 sont des orbites : celle-ci fixe |
| Lourd après 1 coup | **NeedlePalm** (+2 crans, HitStun 0.4) | |
| Lourd à 4 crans (prioritaire) | **VitalPoint** : « figé » 0.8 s (ni mouvement ni attaque ; substitution possible), crans consommés | la fausse mort, version duel |
| Saisie | prise à une main → Light = **sceaux à une main** (Mille aiguilles à bout portant, 10 dégâts, +2 crans) ; Heavy = projection commune | saisie → technique (H10) |
| Air | Air1/Air2 ; routes aériennes communes, clips propres | DÉCISION : pas d'identité aérienne |

### 5. Armes et ninja tools
- **Senbon** (`ToolMastery={Kind="senbon",Count=3,Speed=110,Damage=1,Recover=.45}`) : nouveau `kind` (constructeur client fin, H01) ; chaque coup +1 engourdissement ; un senbon qui touche un corps en WallSplat le cloue (étendre la liste `shuriken/kunai/marked` de `Combat:projectileHit`, `:1143-1146`).
- Depuis un miroir : origine = surface du miroir (`opts.origin`).
- PROPOSÉ (TOOL-002) : senbon plantés 6 s → conducteurs pour la foudre de Kakashi.

### 6. Jutsus / techniques
| Technique | Coût | Canal/actif/récup | CD | Effet | Contre-jeu |
|---|---|---|---|---|---|
| Miroir de glace | 14 | .2 / — / .2 | 3 | pose un miroir (≤ 18 studs, face à l'adversaire, 2 au plus, le plus ancien fond) | le casser (30 PV ; feu ×0.3), le contourner |
| Reflet | 10 | .1 (invulnérable dans le miroir) / .12 / .25 | 1.2 | ressort du miroir le plus proche du flanc/dos adverse avec une frappe d'aiguille | regarder quel miroir s'illumine ; casser le miroir ; garde vers lui |
| Sensatsu Suishō (Mille aiguilles) | 22 | .4 (sceaux à une main, déplacement 7) / .2 / .3 | 7 | si la cible est sur de l'eau ou de la glace : anneau de 8 aiguilles convergentes (la garde ne couvre que l'avant), 12 dégâts, +3 crans ; sinon cône court (portée 6, 5 aiguilles) | quitter la zone humide ; interrompre les sceaux |

### 7. Garde / défense
- Garde/parry communs. Perfect dodge : **miroir d'évasion** gratuit posé au point de départ.
- Les miroirs arrêtent les projectiles adverses : Haku joue derrière eux contre les zoneurs.
- Anti-air : FrostCrescent (court) ; défense aérienne commune.

### 8. Esquive et substitution
- Esquive commune ×1.25.
- **Substitution « dans le miroir »** : s'il a un miroir, il réapparaît **à l'intérieur** (protégé, 0.6 s max, sortie à l'input). Si l'attaquant casse ce miroir pendant ce temps, Haku est éjecté et étourdi 0.5 s. Sinon hop commun. (≠ Minato : son sceau ne peut pas être cassé pendant la fuite.)

### 9. Rush / poursuite
- DÉCISION : pas de poursuite aérienne. Conversion **au sol** (FrostCrescent garde la string ; IceSweep → glace → relevé puni) ; Reflet comme ré-entrée.
- Casser sa pression : casser les miroirs, sortir de la glace, frapper fort (il a 115 PV).

### 10. Chakra
- 110 / 8 ; miroirs 14, Reflet 10, Mille aiguilles 22. Low-chakra : plus de miroir → un épéiste d'aiguilles rapide mais sans angles ; il doit ralentir l'adversaire au senbon pour survivre.

### 11. Infusion / interactions de chakra (H07)
- `glace + eau → glace` (les flaques et zones de Kisame deviennent glissantes et alimentent les Mille aiguilles) ; `miroir + feu → résiste` ; `miroir + chakra de Kyûbi (éveil de Naruto) → se brise` ; `senbon planté + foudre (Kakashi) → conducteur`.
- Hyōton = kekkei genkai : **non copiable** par Kakashi.

### 12. Éveil — MAKYŌ HYŌSHŌ
- Activation : 6 miroirs en anneau (rayon 7) autour de l'adversaire, 8 s (ses miroirs existants y sont intégrés).
- Règles : Reflet gratuit (CD 0.4) ; volées depuis 2 miroirs à la fois ; reflets de Haku visibles dans tous les miroirs (H12 visuel) ; on ne sort qu'en cassant un miroir (lourd, launcher, Rasengan, technique) ou par substitution (qui replace **hors** du dôme : le hop serait bloqué par les miroirs). Les porteurs du Sharingan (Itachi, Sasuke, Kakashi découvert) voient le vrai Haku (reflets atténués).
- Contrepartie : à la fin, les miroirs éclatent et Haku reste **à découvert** 2 s (pas de Reflet). Pas de multiplicateur de dégâts.

### 13. États et réactions
- Crée : engourdissement (mobilité), pied cloué (route latérale), figé (point vital), Knockdown + glace (IceSweep), Juggled bas (FrostCrescent), WallSplat contre ses miroirs.
- Exploite : adversaire ralenti, zones d'eau/glace, adversaire collé à un miroir.

### 14. Boucle de jeu
- Représentative : `miroir derrière l'adversaire → senbon depuis le miroir (+1) → Reflet → L1 L2 ↑ FrostCrescent (+1) L3 (+1) → lourd à 4 crans → point vital → IceSweep`.
- Défensive : `miroir entre lui et le zoneur → volées depuis l'autre miroir → esquive longue`.
- Low-chakra : `senbon + string rapide, garder 15 pour la substitution`.
- Cage : `éveil → Reflets successifs → volées croisées → l'adversaire casse un miroir ou perd`.

### 15. Skill ceiling
- Débutant : senbon et string, miroirs posés au hasard.
- Intermédiaire : place les miroirs en angle de flanc, compte les crans, garde le point vital pour une ouverture.
- Expert : géométrie à deux miroirs (flanc + dos), substitution dans le miroir hors de portée de casse, glace sous le relevé, synchronise les volées avec Reflet ; contre le Sharingan, compte sur les angles plutôt que sur l'illusion.

### 16. Signature irremplaçable
Haku est le seul à poser des **objets solides qui sont à la fois murs, canons, portes et refuge**, et le seul dont la perturbation vise **la mobilité** adverse. Quatre jutsus sur ses stats en feraient un lanceur d'aiguilles fragile ; les miroirs en font un architecte de cage.

## Différenciation

| Axe | Haku | Minato | Itachi | Neji | Sasuke |
|---|---|---|---|---|---|
| Réseau | miroirs **visibles, cassables, solides**, près de l'adversaire (cage) | sceaux = points de destination dispersés (traversée) | — | — | — |
| Flanc | depuis un objet fixe | depuis un téléport | depuis une collision de lames (Geometry) | — | — |
| Perturbation | **mobilité** (engourdissement) | — | — | **chakra** (tenketsu) | — |
| String | 4, la plus rapide, relance au sol | 3 | 3 | 3 | 3 |
| Substitution | dans le miroir, punissable | vers un sceau | corbeau derrière | hop | hop |
| Éveil | dôme (règles de cage) | vitesse/CD | fenêtres | sans angle mort | stats + drain |

| Vague | Recouvrement | Ce qui les sépare |
|---|---|---|
| Lee | string de 4, vitesse | Lee frappe fort, monte en l'air, sans objet ; Haku pique, ralentit, reste au sol |
| Kakashi | Sharingan voit Haku | ses senbon conduisent la foudre de Kakashi ; glace non copiable |
| Kisame | eau | Haku gèle l'eau de Kisame (glissante, Mille aiguilles) |
| Temari | projectiles | ses couloirs dévient les senbon : matchup défavorable |
| Shikamaru | objets | les miroirs projettent des ombres utilisables par Shikamaru |
| Naruto | — | l'éveil de Naruto brise les miroirs (canon) |
| Gaara | — | le bouclier arrête les senbon une charge à la fois |

## Labels lore par capacité

| Capacité | Label | Source / justification |
|---|---|---|
| Senbon, précision | CANON_YOUNG | Pays des Vagues (ch. à vérifier) |
| Point vital / fausse mort | CANON_YOUNG (concept) | fausse mort de Zabuza, puis de Sasuke ; 0.8 s = GAMEPLAY_LIBERTY |
| Engourdissement par crans | GAMEPLAY_LIBERTY | aiguilles qui gênent les mouvements de Naruto et Sasuke (à vérifier) |
| Miroirs de glace démoniaques, voyage entre miroirs | CANON_YOUNG | pont du Pays des Vagues |
| Résistance au feu, casse par le chakra de Kyûbi | CANON_YOUNG | Gōkakyū de Sasuke inefficace ; Naruto brise les miroirs |
| Sharingan qui suit Haku | CANON_YOUNG | éveil du Sharingan de Sasuke contre Haku |
| Miroirs isolés hors dôme, 2 au plus | GAMEPLAY_LIBERTY | réduction d'échelle |
| Mille aiguilles depuis l'eau | CANON_YOUNG | eau du pont |
| Sceaux à une main | CANON_YOUNG | même scène |
| Glace au sol (IceSweep) | PLAUSIBLE_YOUNG | Hyōton ; pas de scène précise |
| Substitution dans le miroir | GAMEPLAY_LIBERTY | contre-jeu : casse du miroir |
| Dôme à 6 miroirs (éveil) | CANON_YOUNG (échelle réduite) | 21 miroirs en canon (à vérifier) |
| « Hirondelles de glace » et autres Hyōton | non retenus | apparition à vérifier (anime/jeux) |

## Plan d'implémentation

**Réutilisé** : `Combat:projectile` avec `opts.origin` (volées depuis un miroir) ; `Combat:relocate` (`:58`, Reflet) ; `Brawler.splatSurface` (attribut `NinjaWall`) et `Brawler.pin` ; liste de clouage de `Combat:projectileHit` ; modèle d'accumulation des tenketsu (`tenketsu`/`tenketsuUntil`, `Brawler.gentleFist`) comme gabarit de crans ; clip `Bound` pour figé/cloué ; perception d'illusion existante (Byakugan qui voit à travers le Mirage, `Server/Techniques.luau:273-276`) comme modèle de règle de perception.

**Nouvelles données** : `Fighters.Crystal` (stats §1, `ToolMastery` senbon, `Numb={Max=4,Duration=4,Speed=.95,Dodge=.93,Jump=.95}`, `Mirrors={Max=2,HP=30,Life=8,Fire=.3}`) ; `MoveGraphs.Crystal` (`routes={up="FrostCrescent",down="IceSweep",side="PinFlick",…}`, `onRoute={IceSweep="ice"}`, `heavyAfterOne="NeedlePalm"`, `disengage="Senbon"`) ; `Attacks` : `NeedleJab/NeedlePalm2/NeedleLow/Crescent` (H02), `FrostCrescent` (`chain=true`), `IceSweep`, `PinFlick` (`chain=true`), `NeedlePalm`, `VitalPoint`, `MirrorStrike` ; `Techniques` : `IceMirror`, `Reflection`, `Sensatsu`, éveil `Dome` ; IA : miroir en angle de flanc, volées depuis le miroir, Reflet quand l'adversaire tourne le dos au miroir, point vital à 4 crans.

**Hooks** : H11 (miroirs : création hors `match.effects`, PV, casse en mêlée et par projectile, résistance au feu, nettoyage), H12 v0 (reflets visuels + règle de perception), H04 (crans sur la victime), H06 (glace), H10 (saisie → technique), H07 (eau → glace, différable), H17 (substitution dans le miroir, miroir d'évasion au perfect dodge), H02, H03, H01.

**Motion** : stance, démarche, intro (retire le masque à moitié ? à valider) ; clips propres : string de 4, FrostCrescent, IceSweep, PinFlick, NeedlePalm, VitalPoint, MirrorStrike (sortie de miroir), Air1/Air2, Grab + sceaux à une main, Throw, Riposte ; poses : pose de miroir, Reflet (entrée), Mille aiguilles ; objet tenu : senbon entre les doigts.

**Effets/UI** : miroirs (glace, fissures selon les PV), reflets dans les miroirs, senbon fins, crans d'engourdissement sur la victime, plaque de glace.

**Tests** (`tests/Haku.spec.luau`) : crans et modificateurs de mobilité (sans muter `def`), point vital à 4 crans, substitution possible pendant « figé » ; miroirs : limite 2, PV, feu ×0.3, blocage de projectile, ligne de vue IA, splat contre un miroir, nettoyage fin de manche/KO ; Reflet : relocation, invulnérabilité courte, refus sans miroir ; volée depuis un miroir (origine) ; substitution dans le miroir et éjection si cassé ; dôme : sortie par casse ou substitution hors dôme ; duels IA contre les 12 ; test sans jutsu (senbon + string + crans).

**Effort** : **L**.

**Périmètre minimal jouable** : string de 4 + engourdissement + point vital, senbon, Miroir de glace (2, cassables, bloquants), Reflet, volées depuis le miroir. Hors minimal : dôme, reflets et règle Sharingan, Mille aiguilles par zones, glace au sol, saisie→sceaux, senbon persistants.

## Points à vérifier
- Âge et chapitres des scènes du pont ; effet réel des senbon sur la mobilité dans le canon.
- Budget réseau des volées (projectiles simultanés, NET-001) et lisibilité à la caméra.
- Présentation du masque et de l'intro (référence visuelle).
