# Kisame — lourd, chakra volé, pression d'eau (vague d'archétypes)

Code proposé : `Shark` (absent du code). IDs : CHR-EXT-002, SYS-001/002, DEF-005, COM-006, BAL-001.

> Fiche de conception Claude du 2026-10-16 (mission [COMBAT_CONVERGENCE_ONLINE_ROSTER](../missions/COMBAT_CONVERGENCE_ONLINE_ROSTER.md) §18–21, DEC-012/DEC-013). Rien n'est implémenté ; valeurs = points de départ à régler en natif. Code lu sur `c2d797c` (chemins relatifs à `games/ninja-duel/src/`, le nom de fonction fait foi). Sources canon « à vérifier » non confirmées. Plan : [ROSTER_WAVE_PLAN](ROSTER_WAVE_PLAN.md) ; hooks : [ROSTER_WAVE_HOOKS](ROSTER_WAVE_HOOKS.md).

## Stade retenu (DEC-013) — **décision utilisateur requise**

**Jeune épéiste de Kiri (≈16–17 ans), avant l'Akatsuki**. Aucune scène canonique d'un Kisame adolescent ne nous est connue : le stade lui-même est une **liberté assumée**. DEC-013 le permet (« identité présente, échelle adulte absente ») et la mission le nomme explicitement, mais l'utilisateur doit confirmer ce cadrage (look adolescent, bandeau de Kiri, Samehada déjà portée). Racines présentes : Samehada qui dévore le chakra, Suiton requin, réserve de chakra hors norme. Échelle absente : pas de manteau Akatsuki, pas de fusion avec Samehada, pas d'inondation (Bakusui à pleine échelle), pas de « Mille requins » ni de « Grand requin ».

## Pourquoi il mérite une place (système éprouvé)

1. **Économie de transfert de chakra** (H05) : Neji **détruit** le chakra adverse (`Brawler.gentleFist`, `Server/Brawler.luau:435-443`) ; Kisame le **vole** et peut dépasser son maximum (surcharge). Éprouve toutes les règles de seuil (esquive 10, substitution 15, techniques) dans les deux sens.
2. **Armure de coup** (H13) : aujourd'hui tout coup interrompt (`Combat:damage` → `Stunned`, `Server/Combat.luau:220-229`) ; seul le bouclier de Gaara arrête un coup sans input. Kisame encaisse en payant du chakra.
3. **Absorption de projectiles** (H08) et **zones qui renforcent leur propriétaire** (H06 : l'eau le rend plus rapide).
4. **Bind lié au lanceur** (H10) : la prison d'eau l'immobilise lui aussi tant qu'il la tient.
5. **Arme lourde** : allonge 8.5, garde rabotée, rythme lent (BAL-001 : durée des combats sans inflation de PV).

## Mécanique signature

**Samehada se nourrit** : chaque contact de Samehada retire du chakra et le **transfère** à Kisame (6 sur coup, 4 à travers la garde, 2 sur un blocage adverse de la lame). Au-delà de son maximum, la **surcharge** (jusqu'à 150 %) décroît de 3/s et paie d'abord son **armure** : pendant le démarrage de ses coups lourds, un coup léger ne l'interrompt pas (il prend les dégâts, paie 6 chakra). Plus l'adversaire lui donne de chakra, plus il devient inarrêtable.

## Fiche FIGHTER_TEMPLATE

### 1. Identité
- PROPOSÉ `Fighters.Shark` : « THE TAILLESS SHARK » (à valider), `Age = 16`, HP 150 (le plus haut), chakra 140 (+ surcharge à 210), regen 6 (la plus basse), vitesse 17, sprint ×0.95, saut ×0.95, air ×0.9, accél. ×0.9, esquive ×0.95, `CombatDamage 1.1`, `PreferredRange 8`, `Tool = "WaterJet"`.
- Fantasy : le requin qui grossit en mangeant. Rôle : lourd / pression mi-distance. Rythme : lent, écrasant, de plus en plus confiant. Distance : 6–9 au sabre, 20–55 à l'eau.
- Forces : endurance, armure, vol de ressource, eau. Faiblesse : lent hors de l'eau, string courte et lisible, ne gagne rien si l'adversaire évite le contact ; drain de Neji, vitesse de Lee.
- Question : « Combien de chakra peux-tu te permettre de me donner ? »

### 2. Mouvement
- PROPOSÉ : stance Samehada sur l'épaule, épaules larges ; démarche lourde `stride 1.1, cadence .82, arm 10, lean 4, bob .9, guard 0`.
- **Dans l'eau** (ses zones, H06) : vitesse ×1.35, saut ×1.1 (« il nage ») ; c'est son vrai mouvement signature.
- Mur : commun ; DÉCISION : pas de route murale propre (il frappe les corps contre les murs, il n'y court pas).

### 3. Neutral / entrée en combat
- Fermer : Rush commun, Charge du requin (route latérale), tirs de requin qui forcent le déplacement vers lui.
- Tenir : Suikōdan (55 studs) ; jet d'eau (outil) qui pose des flaques.
- Forcer une réaction : un lourd armé qu'on ne peut pas « jabber » ; une flaque où il devient rapide.
- À respecter : sa jauge (surcharge = armure), ses flaques.

### 4. Taijutsu et combos (H02 : string de 2)
| Entrée | Move proposé | Fonction |
|---|---|---|
| L1 → L2 | **taille verticale** (démarrage ×1.25, portée 8.5) → **rabot horizontal** (largeur 8, Knockback) | la string la plus courte avec Shikamaru ; chaque contact transfère du chakra |
| ↑ (après 2) | **SharkRise** (Samehada remontée, Launched 50) | payoff `feed` : +10 chakra si touché |
| ↓ (après 2) | **Crush** (Samehada abattue au sol, onde de 6 studs, Knockdown) | armé (H13) |
| ←→ (≥1) | **SharkCharge** (coup d'épaule latéral, Knockback de côté, dégâts de garde) | termine la string ; vers un mur → splat |
| Lourd après 1 coup | **Grind** (Samehada qui rabote : 3 tics de 3 dégâts, 4 chakra volés par tic, HitStun maintenu) | le cœur de la signature |
| Lourd neutre | taille armée (H13) | punition, anti-pression |
| Air | Air1/Air2 coups de lame | DÉCISION : pas de routes aériennes (il ne jongle pas) |
| Grab | prise d'une main → Throw | commun, clip propre |

### 5. Armes et ninja tools
- Arme : **Samehada** (épée bandée, écailles) : allonge, rythme, transfert. Objet tenu (H01).
- **R = jet d'eau** : jet court (portée 20, 2 dégâts, repousse 4 studs) qui laisse une **flaque** (rayon 3, 3 s, H06) ; coût 4, récupération 0.7.
- DÉCISION : ni kunai ni shuriken.

### 6. Jutsus / techniques
| Technique | Coût | Canal/actif/récup | CD | Effet | Contre-jeu |
|---|---|---|---|---|---|
| Suikōdan (requin d'eau) | 22 (11 depuis l'eau) | .4 / .1 / .35 | 5 | projectile rayon 2, vitesse 60, portée 55, 12 dégâts, Knockback 50 (splat possible) ; raté → flaque rayon 6, 5 s | pas de côté, garde ; option : légère poursuite de cible (H15) |
| Bakusui (échelle réduite) | 28 | .5 / .2 / .4 | 12 | zone d'eau rayon 10 centrée sur lui, 6 s ; repousse à moins de 5 studs | sortir de la zone, l'attirer dehors |
| Suirō (prison d'eau) | 20 | prise .22 (insaisissable comme une saisie, portée 6) | 10 | `Bound` 1.6 s dans une sphère : la victime perd 10 chakra/s, Kisame les gagne ; **Kisame est immobilisé tant qu'il tient** ; fin au choix : lâcher (Knockback) ou enchaîner le lourd armé | substitution (de plus en plus chère : le chakra fuit), rester hors de 6 studs |

### 7. Garde / défense
- **Garde-Samehada** : les projectiles de chakra gardés de face (feu, vent, paume, sable, eau) sont **absorbés** (détruits, +50 % de leur coût ou 8 par défaut, sans coût de stamina) (H08) ; les projectiles physiques sont bloqués normalement ; une frappe de mêlée bloquée lui rend 3 chakra (pris à l'attaquant).
- **Armure** (H13) : démarrage de Heavy, Crush et Grind ; ignore les légers (dégâts subis, 6 chakra/surcharge payés par coup absorbé) ; cassée par lourds, launchers, saisies et techniques.
- Parry commun ; anti-air : SharkRise.

### 8. Esquive et substitution
- Esquive commune (×0.95).
- **Substitution « clone d'eau »** : hop commun, mais le corps laissé s'effondre en **flaque** (rayon 4, 4 s) : il prépare son retour. Coût et suivi communs.

### 9. Rush / poursuite
- Poursuite commune (rare : il ne jongle pas). Conversion de Kisame = **mur** (SharkCharge, rabot, requin → splat) et **prison**.
- Casser sa pression : sortir de l'eau, ne pas lui donner de chakra (esquiver plutôt que garder Samehada), frapper ses démarrages avec des lourds.

### 10. Chakra
- 140 / 6 ; **surcharge** jusqu'à 210 par absorption seulement (décroît 3/s) ; l'armure puise d'abord dans la surcharge.
- Low-chakra : plus d'armure, plus de jutsu ; il doit toucher (Grind) pour se recharger, ce qui l'expose.
- Spécialité : la seule réserve qui grossit au contact de l'adversaire.

### 11. Infusion / interactions de chakra (H07)
- `Samehada + contact → transfert` ; `garde + projectile de chakra → absorption` ; `eau + Kisame → vitesse` ; PROPOSÉ (différable) : `eau + foudre (Kakashi, Sasuke) → choc dans toute la zone` ; `eau + glace (Haku) → zone gelée` ; `eau + sable (Gaara) → sable alourdi`.

### 12. Éveil — REQUIN SANS QUEUE
- Règles (12 s) : (1) Samehada s'éveille : allonge +30 %, transfert ×2 ; (2) surcharge plafonnée à 200 % ; (3) armure sur **tous** ses coups tant qu'il reste de la surcharge. Pas de multiplicateur de dégâts.
- Contrepartie : à la sortie, surcharge à 0 et « ventre vide » 3 s (pas d'armure, regen ×0.5). Contre-jeu pendant l'éveil : ne pas le nourrir, l'obliger à payer l'armure avec des légers puis punir au lourd.

### 13. États et réactions
- Crée : Knockback (L2, SharkCharge, requin), Launched (SharkRise), Knockdown (Crush), Bound (Suirō), WallSplat (portée), perturbation de ressource (vol).
- Exploite : garde adverse (transfert à travers), chakra adverse bas (prison = plus de substitution).

### 14. Boucle de jeu
- Représentative : `jet d'eau (flaque) → Suikōdan → l'adversaire bloque → entrée dans la flaque (×1.35) → L1 L2 → Grind (+12) → SharkCharge vers le mur → splat → lourd armé`.
- Agressive : `surcharge → lourds armés dans la pression adverse → Crush → Suirō sur le relevé`.
- Défensive : `Bakusui → garde-Samehada contre les jutsu → riposte`.
- Low-chakra : `garder Samehada contre la mêlée (+3) → Grind dès qu'un coup passe`.

### 15. Skill ceiling
- Débutant : lourds armés en boucle, requins à distance.
- Intermédiaire : place des flaques avant d'entrer, garde les jutsu adverses pour se nourrir, Grind au bon moment.
- Expert : gère surcharge vs armure (ne pas la gaspiller en esquive), prison quand l'adversaire est sous 25 chakra, oriente chaque Knockback vers un mur, lit qui lui donnera du chakra (et refuse le duel contre Neji).

### 16. Signature irremplaçable
Kisame est le seul dont **la ressource adverse devient la sienne** et dont **l'armure se paie avec ce qu'il a volé**. Quatre jutsus sur ses stats en feraient un gros personnage lent ; Samehada en fait un problème d'économie : chaque échange modifie deux jauges à la fois.

## Différenciation

| Axe | Kisame | Minato | Itachi | Neji | Sasuke |
|---|---|---|---|---|---|
| Neutral | 8 au sabre, 55 à l'eau | 6, sceaux | 10, Geometry | 5 | 6 |
| Mouvement | lent, rapide dans l'eau | vif | contrôlé | pas courts | acrobatique |
| String | **2 coups** lourds | 3 | 3 | 3 | 3 |
| Ressource | **vole** le chakra, surcharge | regen 8 | réserve 125 | **détruit** le chakra | PV en éveil |
| Défense | armure + absorption | mobilité | lecture | Rotation | Sharingan |
| Règle tordue | ne bronche pas | téléport | flanc/whiff | drain | chasse gratuite |

| Vague | Recouvrement | Ce qui les sépare |
|---|---|---|
| Gaara | lent, gros PV | défense passive à distance vs armure active au corps ; Gaara ne touche jamais, Kisame ne fait que toucher |
| Naruto | grosse réserve | Naruto la dépense en corps ; Kisame la vole ; matchup : chaque contact de Samehada sur le vrai Naruto le nourrit, un clone coupé ne rapporte rien |
| Haku | eau | Haku gèle l'eau (PROPOSÉ H07) ; aucun recouvrement de corps |
| Temari | zones | les couloirs gênent l'autre, l'eau le sert lui |
| Kakashi | — | la foudre dans l'eau (H07) donne à Kakashi une réponse de terrain |
| Lee | corps à corps | Lee évite tout contact et contourne l'armure par la vitesse et les lourds |
| Shikamaru | contrôle | prison (le lanceur est figé aussi) vs possession (le lanceur bouge et l'autre suit) |

## Labels lore par capacité

| Capacité | Label | Source / justification |
|---|---|---|
| Stade « jeune épéiste de Kiri » | GAMEPLAY_LIBERTY | aucune scène jeune connue ; Samehada héritée de Fuguki Suikazan (flashback, ch. à vérifier, âge inconnu) |
| Samehada absorbe le chakra | GAMEPLAY_LIBERTY (capacité canon adulte transposée) | Partie I, contre Asuma (ch. à vérifier) |
| Transfert au contact, surcharge | GAMEPLAY_LIBERTY | traduction en économie lisible |
| Absorption des jutsu gardés | GAMEPLAY_LIBERTY (canon adulte) | Samehada qui mange les techniques en Partie II (scènes à vérifier) |
| Armure payée en chakra | GAMEPLAY_LIBERTY | lourd « inarrêtable » avec coût et contres |
| Suikōdan | GAMEPLAY_LIBERTY (canon adulte) | scène à vérifier |
| Suirō (prison d'eau) | PLAUSIBLE_YOUNG | technique de Kiri montrée par Zabuza en Partie I ; version Kisame en Partie II |
| Bakusui à échelle réduite | GAMEPLAY_LIBERTY | inondation canon (Partie II) ramenée à une zone de 10 studs |
| Réserve de chakra hors norme | GAMEPLAY_LIBERTY (canon adulte) | « bijû sans queue » (citation à vérifier) |
| Jet d'eau / flaques | GAMEPLAY_LIBERTY | outil de terrain |
| Clone d'eau à la substitution | PLAUSIBLE_YOUNG | Mizu Bunshin, technique de Kiri (Partie I, Zabuza) |
| Fusion avec Samehada, Mille requins, Grand requin, inondation | REJECT_ADULT_ONLY | Partie II, échelle endgame |
| Manteau Akatsuki | REJECT_ADULT_ONLY | stade adulte |

## Plan d'implémentation

**Réutilisé** : branchement du drain de Neji dans `Brawler.hit` (`:483`) comme modèle du transfert ; `Bound` et sa tenue en place (`Brawler.step`, `:550`) ; modèle de `Techniques.bindInSand` (bind + suite planifiée) pour Suirō ; projectile volumique (rayon/croissance, comme `palm`) pour le requin ; `Combat:addHazard` comme base des flaques ; suppression de projectiles de `Techniques.DesertWave` pour l'absorption ; splat/pin communs.

**Nouvelles données** : `Fighters.Shark` (stats §1, `Samehada={Drain=6,GuardDrain=4,BlockGain=3,Overflow=1.5,Decay=3}`, `Armor={Cost=6}`, `StringLength=2`, `Tool="WaterJet"`, `Substitution={Puddle=4}`) ; `MoveGraphs.Shark` (`routes={up="SharkRise",down="Crush",side="SharkCharge"}`, `onRoute={SharkRise="feed"}`, `heavyAfterOne="Grind"`, `stringCancels={Suikodan=true}`) ; `Attacks` : `SamehadaChop`, `SamehadaSweep`, `SharkRise`, `Crush`, `SharkCharge`, `Grind` (+ drapeau `armor`) ; `Techniques` : `Suikodan`, `Bakusui`, `Suiro` ; IA : rester à 6–9, lourd armé contre la pression légère, prison quand l'adversaire est à 6 et sous 25 chakra, garder Samehada face aux jutsu, éviter de garder contre Neji.

**Hooks** : H05 (transfert/surcharge), H13 (armure), H08 (absorption), H06 (eau : bonus propriétaire, ralentissement adverse, rendu), H10 (prison liée au lanceur), H17 (substitution « clone d'eau »), H02, H03, H04, H01 ; H07 et H15 différables.

**Motion** : stance, démarche, intro (sourire, Samehada plantée) ; clips propres : taille, rabot, SharkRise, Crush, SharkCharge, Grind (maintenu), lourd armé (pose d'armure lisible), Air1/Air2, Grab/Throw/ThrowUp, Riposte ; poses : Suikōdan, Bakusui, Suirō (main dans la sphère) ; objet tenu Samehada.

**Effets/UI** : jauge de surcharge (au-delà de la barre), flaques/zones d'eau (rendu distinct du feu), absorption visible (le projectile disparaît dans la lame).

**Tests** (`tests/Kisame.spec.luau`) : transfert sur coup/garde/blocage ; surcharge et décroissance ; armure : un léger n'interrompt pas, un lourd si ; coût de l'armure ; absorption d'un feu gardé, pas d'un kunai ; flaque : vitesse de Kisame et ralentissement adverse ; Suirō : les deux figés, drain, substitution de sortie ; duels IA contre les 12 ; test sans jutsu (Samehada seule reste reconnaissable).

**Effort** : **M** si H06 existe déjà (après Temari), sinon **L**.

**Périmètre minimal jouable** : string de 2 + Grind avec transfert, surcharge, armure sur le lourd, Suikōdan + flaque (vitesse/ralentissement), jet d'eau. Hors minimal : Suirō, Bakusui, garde absorbante, guidage du requin, éveil à règles, interactions de natures.

## Points à vérifier
- **Décision utilisateur** sur le cadrage jeune (et le titre).
- Scènes et chapitres des capacités adultes citées.
- Réglage du transfert pour éviter une boucle infinie (plafond de surcharge, décroissance) et durée des combats (BAL-001).
