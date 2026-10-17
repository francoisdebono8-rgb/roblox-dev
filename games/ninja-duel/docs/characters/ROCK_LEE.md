> Documentation spécialisée de référence ; état dans [CURRENT_STATE](../active/CURRENT_STATE.md), travail et critères dans [MASTER_BACKLOG](../active/MASTER_BACKLOG.md). Les anciennes propositions et statuts ci-dessous ne fixent pas les priorités globales.

# Rock Lee — taijutsu pur (vague d'archétypes)

Code proposé : `Lotus` (absent du code). IDs : CHR-EXT-002, CHR-CORE-001 (référence « reconnaissable sans jutsu »), COM-002, SYS-003, DEF-002, DEF-005.

> Fiche de conception Claude du 2026-10-16 (mission [COMBAT_CONVERGENCE_ONLINE_ROSTER](../archive/missions/COMBAT_CONVERGENCE_ONLINE_ROSTER.md) §18–21, DEC-012/DEC-013). Rien n'est implémenté ; valeurs = points de départ à régler en natif. Code lu sur `c2d797c` (chemins relatifs à `games/ninja-duel/src/`, le nom de fonction fait foi). Sources canon « à vérifier » non confirmées. Plan : [ROSTER_WAVE_PLAN](ROSTER_WAVE_PLAN.md) ; hooks : [ROSTER_WAVE_HOOKS](ROSTER_WAVE_HOOKS.md).

## Stade retenu (DEC-013)

**Examen chûnin, préliminaires contre Gaara (12–13 ans)**, prolongé jusqu'à la récupération de Sasuke (Poing ivre, 13 ans) comme réserve de progression. Racines présentes : poids aux jambes, Gōken, Konoha Senpū, Kage Buyō, Lotus primaire, cinq portes et Lotus inversé. Échelle absente : 6e porte et au-delà (Paon du matin, Tigre du jour, Gai de la nuit) = escalade Gai/Partie II.

## Pourquoi il mérite une place (système éprouvé)

1. **La grammaire commune sans ninjutsu** : Lee répond à la question de [ROSTER_ARCHETYPES_32](../archive/design_research/02_character_architecture/ROSTER_ARCHETYPES_32.md) « le moteur est-il amusant sans spectacle de jutsu ? ». Il est le test de CHR-CORE-001 à l'état pur.
2. **Vitesse extrême** : met à l'épreuve le plafonnement de `Motor.step` (qui **ignore `a.speedScale`**, `Server/Motor.luau:220-221`, alors que `Place1Movement` l'applique, `:187` : les bonus de vitesse d'éveil existants semblent écrêtés au sol — lecture de code, à confirmer), la validation de coup à haute vitesse, la caméra et, plus tard, la prédiction réseau.
3. **Chaînes M1 propres à un fighter** : la string commune est figée à 3 coups (`Shared/BanglaCombo.luau:3`) ; Lee en a 4 (H02).
4. **PV comme ressource** (portes) et **substitution remplacée** : il ne peut pas faire de ninjutsu, donc pas de kawarimi → il tord la règle universelle de défense.
5. **Saisie aérienne** : le Lotus exige une prise en l'air, interdite aujourd'hui (`Server/Brawler.luau:210`).

## Mécanique signature

**Élan** (0–3, 5 poids retirés) : Lee le gagne en convertissant le mouvement en coup — FlyingKick/SlideSweep qui touchent, DashAttack au bout d'un Rush, coup ≤ 0.4 s après une esquive, coup de poursuite, 4e coup de string, déviation réussie, sortie de mur. Il perd 1 cran par 3 s sans gain. Il **dépense** l'Élan, il ne le convertit pas en dégâts : 3 crans = retirer les poids (vitesse pour la manche) ; 1 cran = Kage Buyō automatique après le launcher. Les **portes** coûtent des PV (jamais létales). Lee gagne en préservant son élan physique, pas en préparant des projectiles (blueprint « Body Momentum », [ROSTER_MOVESETS_10_PRODIGIES](ROSTER_MOVESETS_10_PRODIGIES.md) §10).

## Fiche FIGHTER_TEMPLATE

### 1. Identité
- PROPOSÉ `Fighters.Lotus` : « THE TAIJUTSU PRODIGY » (titre à valider), `Age = 13`, HP 125, chakra 100, regen 9.5 (la plus haute), vitesse 18 → **20.5 poids retirés**, sprint ×1.08 → ×1.2, saut ×1.15, air ×1.1, accél. ×1.2, esquive ×1.1 → ×1.25, `CombatTravel 1.15`, `PreferredRange 4.5` (la plus courte).
- Fantasy : le génie de l'effort. Rôle : rushdown corporel. Rythme : relances continues, risque explosif. Distance : collé.
- Forces : vitesse, pression, poursuite, conversions physiques. Faiblesse : aucune réponse à distance hors déviation ; zones et volumes de jutsu ; portes qui le blessent ; début de manche lent (poids).
- Question : « Peux-tu rester dans le rythme d'un corps qui ne ralentit jamais ? »

### 2. Mouvement
- PROPOSÉ : stance Gōken (une main dans le dos, paume avant ouverte) ; démarche athlétique `stride 1.15, cadence 1.1, arm 40, lean 8, bob 1.0, guard .1`. Les poids se lisent : foulée plus lourde (bob .8) jusqu'à leur retrait.
- Sprint/dash : les valeurs ci-dessus via des **modificateurs par acteur** (H04) — ne jamais muter `a.def`, partagé entre acteurs (miroir Lee contre Lee).
- Mur : pas de « marche au chakra » (il ne moule pas le chakra en ninjutsu) : course murale courte (0.6 s) terminée par un **rebond athlétique** qui donne +1 Élan (paramètres de `Config.Wall` par fighter).
- Mouvement signature : retrait des poids (cratère, son lourd), puis course plus explosive que tout le roster.

### 3. Neutral / entrée en combat
- Fermer : sprint → FlyingKick (+1 Élan), Rush (« course explosive », mêmes règles que `Combat:rush`, `Server/Combat.luau:475`), Konoha Daisenpū (technique 2).
- Tenir la distance : il ne la tient pas. Contre les projectiles : **coup de pied de déviation** (outil, §5).
- Forcer une réaction : menace du FlyingKick dès qu'il sprinte ; feinte de lourd commune.
- Sortir : rarement ; Rupture (§8) ou rebond mural.
- À respecter : sa barre d'Élan (1 cran = Kage Buyō prêt, 3 = poids retirables), ses poids encore en place ou non.

### 4. Taijutsu et combos (H02 : string de 4)
| Entrée | Move proposé | Fonction |
|---|---|---|
| L1 → L2 → L3 → L4 | jab avant → direct arrière → **low kick** (zone jambes, déséquilibre court) → **coup de pied tournant haut** (Knockback, +1 Élan) | la seule string de 4 du roster avec Haku ; démarrages ×0.8–0.9, dégâts unitaires plus faibles (4/6/7/10) |
| ↑ (≥2) | **LeafRising** (Konoha Shōfū, coup de pied vertical, Launched 60) | si Élan ≥ 1 : payoff `shadowLeaf` réutilisé (Kage Buyō, poursuite collée, `Brawler.luau:318-333`), coûte 1 cran au lieu d'être gratuit (différence avec Sasuke) |
| ↓ (≥2) | **LowWhirl** (balayage tournant qui fait trébucher sans Knockdown, Juggled bas) | **garde la string** (`chain=true`) : le bas relance au lieu de finir |
| ←→ (≥1) | **LeafWhirlwind** (Konoha Senpū : coup de pied tournant à 360°, largeur 9) | attrape le pas de côté adverse ; ne change pas d'angle (l'inverse des routes latérales CORE4) |
| Lourd après 1 coup | **GokenBody** (coup au plexus, HitStun 0.5, +1 Élan) | ouverture |
| Lourd en l'air pendant Kage Buyō | **Omote Renge** (Lotus primaire) si PV > 25 : prise aérienne (H14), vrille, piledriver 24 dégâts, coûte 10 PV ; sinon **LeafHeel** (talon plongeant, variante de Slam) | finisher à risque |
| Course | FlyingKick / SlideSweep communs (`Brawler.luau:214-219`), clips Lee | entrée |
- Air : Air1/Air2 coups de pied ; airUp/airDown/airSide = AirDrive/AirSpike/AirSwitch communs avec clips Lee.
- Cancels : esquive annule la récupération d'un coup qui a touché (portes ouvertes) ; aucun jutsu dans la string (DÉCISION : il n'en a pas).

### 5. Armes et ninja tools
- DÉCISION : pas de projectile. **R = coup de pied de déviation** (H08) : coup de pied circulaire 0.18 s actif, arc frontal 120°, rayon 6 ; détruit kunai, kunai marqués, shuriken, fil, senbon, balle de sable ; **pas** les volumes de jutsu (feu, vent, paume, eau, requin, vague de sable). Chaque déviation : +1 Élan et Rush gratuit pendant 0.6 s (pont de distance). Coût 0, récupération 0.6.
- Bandages : cosmétiques (enroulés pendant le Lotus).

### 6. Jutsus / techniques (techniques corporelles)
| Technique | Coût | Canal/actif/récup | CD | Effet | Contre-jeu |
|---|---|---|---|---|---|
| Retirer les poids | 3 Élan | .5 interruptible / — / .2 | 1×/manche | modificateurs H04 pour la manche : vitesse 20.5, sprint ×1.2, esquive ×1.25, Élan max 5 | le frapper pendant 0.5 s ; le priver d'Élan (garde, distance) |
| Konoha Daisenpū (nom à vérifier) | 8 | .08 / .2 / .3 | 2.5 | vrille de 14 studs, un coup, Knockback | pas de côté, garde |
| Portes (1–3) | 10 PV + 1 PV/s | .4 / — / — | — | Lotus sans coût en PV, esquive qui annule la récupération sur coup, vitesse ×1.1 ; fermeture manuelle ou à 15 % PV → courbatures 3 s (vitesse ×0.8, pas d'esquive) | le laisser se blesser ; punir les courbatures |

### 7. Garde / défense
- Garde/parry communs. Twist : **perfect dodge → +1 Élan et riposte en DashAttack jusqu'à 8 studs** (la riposte commune n'existe qu'au contact, `Brawler.luau:148-153`).
- Matchup PROPOSÉ « plus rapide que le sable » : poids retirés, FlyingKick et DashAttack retirent une charge du bouclier de Gaara **et** touchent (règle de `Combat:damage`, `:183-201`, portée par un drapeau d'attaque, pas par le nom du fighter).
- Anti-air : LeafRising ; défense aérienne : air dodge commun.

### 8. Esquive et substitution
- Esquive commune (portée accrue poids retirés).
- **Pas de kawarimi** (canon : aucun ninjutsu). **Rupture** à la place : même touche, mêmes 2 charges et même fenêtre de 0.42 s (`Config.Substitution`) ; Lee **reste sur place**, i-frames 0.25, coup de pied à 360° qui repousse l'attaquant à moins de 5 studs (Knockback 40, 4 dégâts) ; coût 12. Contre-jeu : un attaquant qui garde ou esquive la Rupture punit 0.3 s de récupération. Nouveau mode dans `Combat:substitute` (`:406`, aujourd'hui `hop`/`seal`/`crow`).

### 9. Rush / poursuite
- Poursuite commune (8 chakra) ; Kage Buyō à 1 Élan après LeafRising ; poursuite après Knockback du L4 (fenêtre commune « knock away », `Brawler.luau:522-525`).
- Casser sa poursuite : air dodge, substitution, garde à l'arrivée ; Rotation de Neji (la poursuite compte comme attaque, `Combat.luau:1054`).

### 10. Chakra
- 100 / 9.5 : Lee dépense en esquives, Rush, poursuite, Rupture ; jamais en jutsu. Low-chakra : plus d'esquive (10) ni de Rupture (12) → il doit continuer à frapper (l'Élan ne coûte pas de chakra).
- Spécialité : la ressource « puissance » est en PV (portes), la ressource « tempo » en Élan.

### 11. Infusion / interactions de chakra
- DÉCISION : aucune infusion (ni nature, ni outil). Seule interaction : déviation physique (H08).

### 12. Éveil — CINQUIÈME PORTE (Lotus inversé)
- Déclenchement : ≤ 35 % PV, 1×/match (cadre commun, `Combat:awaken` `:497`) ; ouvre les portes si elles sont fermées.
- Règles (12 s) : (1) Lourd pendant Kage Buyō = **Ura Renge** (5 coups aériens puis double frappe au sol, 30 dégâts, Knockdown) ; (2) l'Élan ne décroît plus ; (3) vitesse ×1.25 (H04) ; (4) esquives sans CD mais payées 2 PV au lieu de 10 chakra.
- Contrepartie : drain 2 PV/s (jamais létal, comme `HealthDrain`, `Combat.luau:828-829`) ; sortie = **Épuisé** 4 s (vitesse ×0.6, ni esquive ni Rush, stamina de garde ×0.5).

### 13. États et réactions
- Crée : déséquilibre court (L3 bas, LowWhirl), Launched, Juggled, Knockback (L4), Grabbed **en l'air** (Lotus), Knockdown (piledriver).
- Exploite : esquive adverse (LeafWhirlwind), projectiles (déviation), corps lancé (Kage Buyō), bouclier de Gaara (poids retirés).
- Sur lui-même : courbatures, épuisement (états de sortie lisibles).

### 14. Boucle de jeu
- Représentative : `sprint → FlyingKick (+1) → L1 L2 L3 L4 (+1) → E poursuite → L1 L2 ↑ LeafRising (−1, Kage Buyō) → LeafHeel`.
- Agressive : `3 Élan → poids retirés → Rush → L1 L2 ↓ LowWhirl → L3 L4 → ↑ → Kage Buyō → Omote Renge (−10 PV)`.
- Défensive : `projectile → déviation (+1, Rush gratuit) → DashAttack → string` ; `combo subi → Rupture → garde`.
- Low-chakra : `pas d'esquive → garde → riposte → string complète pour regagner l'Élan`.
- Air/mur : `rebond mural (+1) → Air1 → AirSpike → LowWhirl au sol`.

### 15. Skill ceiling
- Débutant : string de 4, FlyingKick, Lotus quand il le peut.
- Intermédiaire : gère l'Élan (ne le gaspille pas, garde 1 cran pour Kage Buyō), dévie au lieu de garder, retire les poids hors de portée.
- Expert : timing de la Rupture (la garder pour la vraie fenêtre), seuils de PV pour le Lotus et les portes, courbatures évitées, route ↓ pour prolonger, LeafWhirlwind contre les pas de côté adverses.

### 16. Signature irremplaçable
Lee est le seul fighter dont **la puissance se gagne en se déplaçant** (Élan) **et se paie en PV** (portes), et le seul **sans substitution** : la grammaire commune doit tenir seule. Quatre jutsus sur ses stats le dénatureraient : ce qui le définit est l'absence de jutsu.

## Différenciation

| Axe | Lee | Minato | Itachi | Neji | Sasuke |
|---|---|---|---|---|---|
| Neutral | collé, déviation | sceaux à 6 | 10, shuriken | 5, paumes | 6, pression outils |
| Mouvement | le plus rapide **après** les poids | le plus vif dès le départ | contrôlé | pas courts | acrobatique, saut haut |
| String | **4 coups**, bas qui relance | 3, dérive d'angle | 3, recul auto | 3, drain | 3, coups de pied |
| Poursuite | Kage Buyō payé 1 Élan | FTG | commune | commune | Kage Buyō **gratuit** (copié de Lee, canon) |
| Finisher aérien | **Lotus** (prise + PV) | RasenganDrop | lames | — | Lion Combo (talon) |
| Défense | Rupture sur place, déviation | sceau | lecture | Rotation | Sharingan |
| Ressource | Élan + PV | chakra | chakra | chakra adverse | PV en éveil |

| Vague | Recouvrement | Ce qui les sépare |
|---|---|---|
| Naruto | rushdown | Naruto multiplie les corps ; Lee n'en a qu'un, plus rapide |
| Kakashi | taijutsu complet | Kakashi s'adapte à l'arme (tantō) et à l'information ; Lee au rythme |
| Kisame | corps à corps | Kisame lent, armé, armure ; Lee esquive tout et n'a pas d'armure |
| Haku | string de 4, vitesse | Haku pique et ralentit, reste au sol ; Lee frappe fort et monte en l'air |
| Gaara, Temari, Shikamaru | — | ses contres naturels (zoning) ; Lee a la déviation et la vitesse comme réponses |

## Labels lore par capacité

| Capacité | Label | Source / justification |
|---|---|---|
| Incapacité au ninjutsu/genjutsu → pas de kawarimi | CANON_YOUNG | caractérisation constante de Partie I |
| Rupture (remplace la substitution) | GAMEPLAY_LIBERTY | contre-jeu : reste sur place, punissable |
| Poids aux jambes, cratères au retrait | CANON_YOUNG | préliminaires contre Gaara (ch. à vérifier) |
| Retrait payé 3 Élan | GAMEPLAY_LIBERTY | transforme un bonus gratuit en décision |
| Stance Gōken, string poings/pieds | CANON_YOUNG (style) | Gōken, Partie I ; coups exacts = liberté |
| Konoha Senpū (route latérale) | CANON_YOUNG | contre Sasuke avant l'examen (ch. à vérifier) |
| Konoha Daisenpū (technique 2) | CANON_YOUNG (nom et scène à vérifier) | Partie I |
| Konoha Shōfū / Kage Buyō | CANON_YOUNG | contre Sasuke et contre Gaara ; Sasuke le copie au Sharingan |
| Omote Renge (Lotus primaire) | CANON_YOUNG | contre Gaara, après la 1re porte |
| Coût en PV du Lotus et des portes | CANON_YOUNG (concept) / GAMEPLAY_LIBERTY (valeurs) | auto-destruction musculaire montrée contre Gaara |
| Cinq portes, Ura Renge | CANON_YOUNG | contre Gaara (5 portes) |
| Coup de pied de déviation | PLAUSIBLE_YOUNG | dévier des armes au pied : compétence de taijutsu ; scène précise à vérifier |
| Élan | GAMEPLAY_LIBERTY | blueprint « Body Momentum » |
| Rebond mural athlétique | GAMEPLAY_LIBERTY | marche au chakra non attestée pour Lee (à vérifier) |
| « Plus rapide que le sable » | CANON_YOUNG (concept) | il touche Gaara une fois les poids retirés |
| Poing ivre (Suiken) | CANON_YOUNG, **hors kit minimal** | contre Kimimaro ; candidat de nœud de progression |
| 6e porte et au-delà | REJECT_ADULT_ONLY | escalade Partie II / Gai |
| Nom « Dynamic Entry » | non retenu | technique de Gai (à vérifier) |

## Plan d'implémentation

**Réutilisé** : running taijutsu (`Brawler.luau:214-219`), payoff `shadowLeaf` (`:318-333`) paramétré par un coût, relocation au-dessus de la cible du LionBarrage (`:224-236`) comme base du Lotus, `HealthDrain` non létal (`Combat.luau:828-829`), Rush/poursuite/esquive/garde communs, `Attacks.AirDrive/AirSpike/AirSwitch/FlyingKick/SlideSweep`.

**Nouvelles données** : `Fighters.Lotus` (stats §1, `Tool="None"`, `StringLength=4`, `Elan={Max=3,MaxFree=5,Decay=3}`, `Substitution={Mode="burst"}`, éveil à règles) ; `MoveGraphs.Lotus` (`routes={up="LeafRising",down="LowWhirl",side="LeafWhirlwind",airUp="AirDrive",airDown="AirSpike",airSide="AirSwitch"}`, `onRoute={LeafRising="shadowLeaf"}`, `heavyAfterOne="GokenBody"`, pas de `disengage`) ; `Attacks` : `Light4`, `LeafRising`, `LowWhirl` (`chain=true`), `LeafWhirlwind`, `GokenBody`, `LeafHeel`, `OmoteRenge`, `UraRenge`, `DeflectKick` ; `Techniques` : `Weights`, `Daisenpu`, `Gates` ; IA : indices (H03) + règles « chercher l'Élan » (sprint → FlyingKick), « dévier plutôt que garder », « poids à 3 Élan hors de portée », « Lotus si PV > 25 ».

**Hooks** : H02 (string de 4, `Combo.next` par acteur), H04 (modificateurs + correctif `speedScale`), H05 (coût PV non létal, Élan), H08 (déviation v1 : destruction en arc), H09 (poids/portes = postures), H14 (prise aérienne), H17 (substitution `burst` = Rupture, twist de perfect dodge) ; H01 pour tout le client.

**Motion** : stance Gōken, démarche, intro (pouce levé) ; clips propres (aucun héritage) : Light1–4, LeafRising, LowWhirl, LeafWhirlwind, GokenBody, LeafHeel, Daisenpū, Omote Renge (séquence prise → vrille → piledriver), Ura Renge, Air1/Air2, AirDrive/AirSpike/AirSwitch, FlyingKick, SlideSweep, Grab/Throw/ThrowUp, Riposte, coup de pied de déviation, Rupture ; poses : retrait des poids, ouverture des portes (aura verte), épuisement.

**Effets/UI** : pips d'Élan, cratères des poids, aura des portes, PV qui fondent (drain déjà rendu, `Client/Presentation.luau:208`).

**Tests** (`tests/Lee.spec.luau`) : string de 4 et `LowWhirl` qui garde la chaîne ; Élan gagné/décroît/dépensé ; poids refusés sous 3 Élan, effet sans muter `def` ; vitesse réelle accrue (régression du correctif `speedScale`) ; déviation qui détruit kunai/shuriken mais pas feu/paume ; Rupture sans relocation et punissable ; Lotus : prise aérienne, coût PV, échappé par la substitution adverse ; portes jamais létales ; duels IA contre les 12 ; test sans jutsu.

**Effort** : **M**.

**Périmètre minimal jouable** : stats + string de 4, Élan, retrait des poids, coup de pied de déviation (destruction), Rupture, LeafRising/Kage Buyō → Omote Renge, éveil = portes avec drain et Lotus gratuit. Hors minimal : technique Portes à tout moment, Ura Renge, Konoha Daisenpū, règle anti-bouclier, Poing ivre.

## Points à vérifier
- Chapitres des scènes citées ; capacité de Lee à courir sur un mur ; attribution de « Dynamic Entry ».
- Mesure native du plafonnement de vitesse (`Motor.step`) avant de calibrer les poids.
- Lisibilité de la Rupture face à la substitution commune (UX, cues).

## État d'implémentation (2026-10-16, test de charge DEC-015)

Code de `claude/nd-ccc2-lee`, bâti sur les règles intégrées (modèle combo confirmé, relance, chakra systémique, couche identité). Rapport, découvertes moteur et liste Studio : [ROCK_LEE_STRESS_TEST](../archive/reports/convergence2/ROCK_LEE_STRESS_TEST.md). **Validé en headless uniquement** (`tests/Lee.spec.luau`, 24 cas ; limites articulaires dans `tests/Animation.spec.luau`) : le feel, la lecture des coups et le costume restent à juger dans Studio. L'identifiant de code est **`Leaf`** (la fiche proposait `Lotus`).

**Implémenté et jouable (sélectionnable dans le roster)**
- `Fighters.Leaf` : HP 125, chakra 100, regen 9,5, vitesse 20 (sprint ×1,12, accélération ×1,22), `PreferredRange 4,5`, frappes plus rapides (×0,85–0,9) et plus légères ; aucun élément, aucun projectile, aucun outil lancé.
- String commune + routes à lui : ↑ **Leaf Rising Wind** (Konoha Shōfū, lanceur) suivi par l'**Ombre de la feuille dansante** partagée ; ↓ **Leaf Hurricane** (coup de pied tournant bas, `chain`) : L L ↓ L3 fait une string de quatre coups sous le modèle à coups confirmés ; ←→ **Leaf Whirlwind** (arc de 9 studs, pas d'orbite : il rattrape le pas de côté). Lourd après deux coups = le lanceur (`LauncherMove`), lourd après un coup = genou commun.
- **Lotus primaire** (Omote Renge) : le lourd dans la fenêtre de l'Ombre, 22 dégâts, coûte 10 PV (jamais létal, refusé à 26 PV ou moins → **Leaf Heel** gratuit). Mécanisme générique `MoveGraphs.airFinisher` + `Brawler.airFinisher` ; Sasuke garde son Lion Combo.
- Technique 1 **Leaf Great Whirlwind** (Konoha Daisenpū) : coup de pied tournant qui traverse ~14 studs, Knockback + poursuite, 10 chakra, CD 2,6, annule une string propre.
- Outil = **coup de pied de déviation** : kunai, kunai marqués, shuriken, fil et balle de sable détruits dans un arc frontal pendant la fenêtre active ; les volumes de jutsu passent ; chaque déviation rend la prochaine ruée gratuite 0,6 s. Le modificateur chakra est refusé (profil `Taijutsu`, aucune infusion).
- **Rupture** à la place du kawarimi (`Substitution.Mode="burst"`) : même touche, charges et fenêtre ; il reste sur place, i-frames communes, coup tournant 4 dégâts / Knockback 40 dans 5,5 studs ; ratée, 0,3 s de récupération.
- Éveil **CINQUIÈME PORTE** : ≤ 35 % PV, vitesse ×1,28, dégâts ×1,1, regen ×1,6, CD ×0,5, drain 2 PV/s non létal ; le lotus devient le **Lotus caché** (26, gratuit, le corps rebondit au sol pour une reprise).
- Relance `reengage` « leaf » (la plus rapide du roster) ; IA : la plus avide de relance, utilise le Daisenpū, dévie les lames, encaisse le lotus, ne « sonde » pas avec un outil.
- Client : famille de mouvement (`body="Lion"`, `weapons="none"`, intro à lui), posture Gōken (main arrière derrière le dos, vérifiée en cinématique directe), démarche qui garde la main dans le dos, clips propres (Leaf Rising Wind, Leaf Hurricane, coup de déviation, Lotus primaire, Lotus caché), couche `LeeFX` (porte verte, lueur rouge, spirale et cratère du lotus, croissant de la déviation, ses couleurs de vitesse) ; costume (combinaison verte, jambières orange, bandeau en ceinture rouge, mains bandées, coupe au bol, gros sourcils).

**Implémenté, à polir (feel / lecture)**
- Clips réutilisés de la famille : jab, coup de pied tournant, talon tournant, air string, genou de Sasuke ; le Leaf Whirlwind et le L3 partagent le talon tournant de Sasuke, le Daisenpū le roundhouse de Minato : répétition visible.
- Le lotus est une plongée au-dessus du corps (comme le Lion Combo), pas une prise aérienne (H14) ; le Lotus caché est un seul impact lourd, pas la série de cinq coups.
- Équilibrage IA : contre Gaara (bouclier, portée) Lee perd les deux ordres dans les duels IA semés.

**Fondation seulement**
- Le Lotus caché comme route d'éveil (données `airFinisher.awakened`) ; la règle `breaksShield` portée par ses deux grands coups de pied, à côté de la liste de noms de `Combat`.

**Non implémenté (planifié)**
- Élan (0–3/5) et tout ce qui en dépend (Kage Buyō payé, retrait des poids à 3 crans, gains sur esquive/déviation) ; retrait des poids (pas de modificateur de vitesse par acteur hors éveil, H04) ; string de quatre via `Combo.next` par acteur (H02) ; GokenBody ; technique Portes à tout moment ; esquives payées en PV et épuisement de sortie de la Cinquième porte ; prise aérienne du lotus (H14) ; rebond mural athlétique ; règle « plus rapide que le sable » ; Poing ivre (hors kit minimal).
