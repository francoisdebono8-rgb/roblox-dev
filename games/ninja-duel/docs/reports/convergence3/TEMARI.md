# Temari — zoneuse de vent (convergence 3, roster §9)

Branche `claude/nd-vrs-temari`, base `2aba0ca`. Mission : [NEXT_VALIDATION_ROSTER_SCALE](../../missions/NEXT_VALIDATION_ROSTER_SCALE.md) §8–§12. Fiche et état détaillé : [TEMARI](../../characters/TEMARI.md) (section « État d'implémentation »). Identifiant de code **`Gale`**.

**Tout est prouvé en headless seulement** (Studio réservé au lead) : `tests/Temari.spec.luau`, 35 cas, plus les limites articulaires de `tests/Animation.spec.luau`. Rien n'a été vu ni joué dans Studio.

## En bref

- Temari est **sélectionnable et complète sur les systèmes partagés** : string à l'éventail, 3 routes + route aérienne, Bourrasque (outil) avec profil chakra Vent, 3 techniques, réengagement « pas de vent », vol plané, substitution longue, éveil Kirikiri Mai, IA zoneuse, costume, couche `GaleFX`, famille `GaleMotion`.
- **Signature : `Server/Zones.luau`**, un composant de zones persistantes typées à côté des hazards (couloir de vent orienté, colonne d'air montant) qui change le vol des projectiles (dévier, porter, nourrir le feu, renvoyer) **et** le mouvement des corps (vent contraire/porteur, portage, ruée brisée, chute ralentie). Le client le dessine en vent, jamais en feu.
- Le test de charge a trouvé et corrigé **quatre défauts partagés** : marche headless 3,3× trop rapide (harness), vol modifié en l'air dessiné sur la mauvaise trajectoire (serveur + client), IA de mêlée qui ne savait que « fermer la distance » contre une portée supérieure, contact de projectile sans réaction possible (pas de splat à distance). Plus des crochets de données minimes (outil, payoff, éveil, pas par acteur, contact d'arme, poussée latérale).
- 24 suites, **394 cas, tous PASS** ; builds normal / Debug / QA PASS ; isolation 9/9, docs et architecture PASS.

## Implémenté et prouvé (headless)

| Capacité | Où | Test (`Temari.spec`) |
|---|---|---|
| Données : HP 130, chakra 120, `Tool="Gust"`, aucune lame, profil `Zoner`, éveil sans bonus de dégâts | `Shared/Fighters.luau` (`Gale`) | « her kit » |
| String à l'éventail : portée 7,5, arrêt à 5 studs (contact d'arme), la 3e ouvre l'éventail et rejette à 12+ studs | `AttackProfile` + `Brawler.start` (`contact`) | « the fan string » |
| Routes : Updraft (colonne d'air, corps tenu ≥ 0,35 s de plus qu'un lanceur), Fan Slam, Fan Pirouette (jeté sur le côté), revers | `MoveGraphs.Gale`, `Attacks`, `Gale.updraft`, `Brawler.hit` (`lateral`) | « routes » |
| Route aérienne : Fan Dive (Spiked), AirDrive | `MoveGraphs.Gale` | « the air route » |
| Bourrasque : pousse sans dégât, renvoie les lames au lanceur, nourrit le feu ; gratuite en string, arrière + R saute | `Gale.gust/blow`, `Techniques.Tools` | « the gust » ×2 |
| Profil chakra **Vent** (`WindFan`) : Bourrasque infusée plus longue + couloir, coût 12, refus avec fizzle | `ChakraTuning`, `Chakra.plan(…,"Fan")` | « chakra modifier » |
| Couloir : ×0,7 / ×1,15 (mesuré), portage (plus en l'air), corps au-dessus non touché | `Zones.speedScale`, `Zones.step` | « wind lane » ×2 |
| Lame qui remonte le couloir : déviée, +2 chakra, **trajectoire annoncée = trajectoire serveur à chaque frame** | `Zones.flight`, `Combat:redirect` | « turned aside » |
| Lame qui le descend ×1,4 et +1 ; volumes de jutsu intacts ; feu grossi (même adverse) | `Zones.flight/feed` | « riding », « fire » |
| Ruée chakra qui remonte un couloir adverse : brisée (+0,25 s) ; à côté du couloir : intacte ; jamais le pas de Temari dans son couloir | `Zones.step` (Rush) | « a chakra dash » |
| Fin des zones (durée, KO, `Combat:clear`), snapshot par type | `Zones.snapshot/clear`, `Matches:view` | « zones end » |
| Kamaitachi : 12 chakra, CD 2,8, canal interruptible, faux qui grandit, Knockback → splat mural, couloir posé pendant le vol | `Server/Gale.luau` (kamaitachi) | « Kamaitachi » |
| Great Gust : lames soufflées, feu nourri, corps au mur, couloir large ; vent qui disperse le sable (bouclier de Gaara brisé, faux comprise) | `greatGust`, `Combat.shieldBreak` | « Great Gust » |
| Rising Whirlwind : marqué puis 0,45 s, Launched + maintien ≥ 1,6 s, rien si le corps a bougé | `cyclone` | « Rising Whirlwind » |
| Pas de vent : de 5 → ≥ 14 studs en angle, de 40 → 14–22, à 17 → de côté ; chasse commune dans une fenêtre | `Gale.reposition` (crochet `Combat:rush`) | « the wind step » |
| Substitution 14 studs | `Combat:substitute` (`twist.Distance`) | « the wind's retreat » |
| Vol plané : chute ≤ 16 studs/s maintenu, posé plus tard | `Gale.glide` (`Techniques.actorSteps`) | « the glide » |
| Kirikiri Mai : Kamatari + long couloir qui renvoie ; Bourrasque qui pose un couloir ; pas de bonus ; éventail fermé 3 s | `Gale.summon` (`awakenHooks`), `fanOpen` | « Kirikiri Mai » |
| IA zoneuse : faux à distance, tourbillon devant l'approche, Bourrasque contre une lame, pointe à sa portée, Bourrasque/pas de vent trop près, conversion d'un corps en l'air sans poursuite | `AI:zone` | « the AI zones » |
| IA adverses : pas de sondage à sa portée, sortie d'un couloir de face, **jamais de ruée dans un couloir** | `AI.luau` (`laneAgainst`, `laneOnPath`) | « the AIs that fight her » ×2 |
| Duels IA semés contre Minato, Itachi, Neji, Sasuke, Gaara, Lee (deux ordres) + miroir, jusqu'au KO, détecteur de blocage de `Lee.spec`, invariant de trajectoire de **tous** les projectiles | — | « AI duels » |
| Client : vol réannoncé dessiné sans disparition ni saut (échoue sur l'ancien `Effects`) | `Effects` (`entry.previous`) | « a flight re-based » |
| Client : faux et Kamatari à la taille du rayon serveur ; couloirs (traits le long du vent) et colonnes, aucun émetteur de feu ; le hazard de feu reste du feu | `GaleFX` (`frame`) | « the scythe and Kamatari… zones » |
| Client : chaque contact dessiné (faux, Bourrasque, Great Gust, tourbillon, feu nourri, lame déviée, éveil, pas de vent, cast) | `GaleFX.impact` | « her contacts » |
| Client : éventail au dos, en main fermé, ouvert lune par lune, planté à l'intro ; manteau d'éveil couleur vent | `GaleFX.fanPose` | « the iron fan » |
| Famille de mouvement : posture ≠ chacun des 6 autres (≥ 4 articulations), main sur la hanche en marche, clips à elle (≠ Itachi, ≠ Sasuke), casts ≠ sceaux, intro, aucune arme du moteur | `GaleMotion`, registres `CAST/INTRO` | « motion family » |
| Tout le kit présenté sans saut de pose (pire 38,0 °/frame, plafond 39) | — | « without a snap » |
| Costume (SmoothPlastic, pas de Fabric, pas d'éventail dans le costume) ; sélection roster | `World.dressTemari`, `UI` | « costume », « selectable » |
| Caméra à 20–90 studs (et 12 studs de hauteur) : les deux corps dans le cadre | `Client/Camera` (mesure, **aucun défaut trouvé**) | « camera at her range » |

Tests qui échouent sur la base : tous ceux qui touchent `Gale`/`Zones` (absents) ; en particulier « a flight re-based » (vérifié : échoue avec l'ancien `Effects`, « the turned blade vanished ») et « headless walking » (échoue sur l'ancien harness : 3,3×). Le test caméra est une **mesure** (passe sur la base).

## Défauts moteur trouvés et corrigés

1. **Harness : marche 3,3× trop rapide.** `Place1Movement` puis `Motor.step` appellent `Humanoid:Move` à chaque frame ; le stub déplaçait la racine pour chaque appel, de 1/60 s sur des pas de 0,01 s. Dans tous les duels IA headless, marcher/sprinter allait 3,3× plus vite que ruées, poursuites et projectiles (une zoneuse y était sans espoir, et toutes les mesures de distance étaient faussées). → un seul déplacement par frame, à la durée réelle de la frame, la dernière demande gagne (comme l'Humanoid). Les 23 autres suites passent sans changement ; **les agents parallèles qui ont calibré des duels sur l'ancien harness verront des marches plus lentes** (à signaler à la fusion).
2. **Vol modifié en l'air dessiné faux.** Le client reconstruit chaque vol par `origin + direction × vitesse × (t − born)` ; changer direction ou vitesse en place le faisait dessiner sur l'ancienne ligne, et un projectile tué/recréé disparaissait 0,06 s. → `Combat:redirect` rebase le vol (origine, born, portée, croissance repliée dans le rayon, snapshot urgent) ; le client garde l'ancien segment jusqu'à ce que l'horloge visuelle atteigne le nouveau (`Effects`, 14 lignes). Invariant vérifié à chaque frame sur tous les projectiles des duels.
3. **Hazards = feu partout.** Les zones de vent ne sont pas des hazards : composant `Zones` séparé (données par type, nettoyage par `Combat:clear`, liste `zones` du snapshot) et rendu par type via un crochet `frame` des couches client.
4. **IA contre une portée supérieure.** L'IA ne savait que fermer la distance. → contre une zoneuse : pas de sondage, zigzag d'approche, sortie latérale d'un couloir contraire, aucune ruée qui remonterait un couloir, garde/pointe/Bourrasque côté zoneuse.
5. **Contact de projectile sans réaction.** La branche `wind` posait une vitesse sans réaction (pas de splat à distance) ; `opts.reaction/impulse` étaient stockés mais jamais lus. → réaction, impulsion, stun, style et `breaksShield` par données sur le projectile.

Crochets de données ajoutés (petits, génériques, inertes pour les autres) : `Techniques.Tools` (outil non lancé), `Techniques.payoffs` (payoff de route), `Techniques.awakenHooks`, `Techniques.actorSteps`, `Techniques.reposition` ; `AttackProfile.contact` ; `Attacks.lateral` ; `Substitution.Distance` ; raison de refus d'un `check` (`Rules.technique`) ; registres `CAST/INTRO` et module de famille dans le moteur de mouvement ; `Combat.shieldBreak` (vent × sable).

## Fichiers partagés touchés

- `Server/Combat.luau` : require `Zones` ; `Combat:redirect` ; style/réaction/stun/`breaksShield` du projectile + branche de réaction ; `shieldBreak` ; distance de substitution par twist ; crochet outil (`Techniques.Tools`) ; crochet `reposition` dans `rush` ; crochet d'éveil ; `jumpHeld` (Jump/JumpOff) ; `speedScale × Zones` ; `actorSteps` ; `Zones.step` avant les projectiles ; `Zones.clear`.
- `Server/Brawler.luau` : `contact` du profil (3 lignes), poussée `lateral` (1), registre de payoffs (2).
- `Server/AI.luau` : `DASH/CHASE.Gale`, `AI:zone` (fonction isolée), 1 ligne d'appel ; approche contre zoneuse (no-probe, zigzag, sortie de couloir, pas de ruée dans un couloir).
- `Server/Techniques.luau` : une ligne `require(Gale).install`.
- `Server/Matches.luau` : `zones` et `glide` dans le snapshot.
- `Server/World.luau` : `dressTemari` + une ligne de dispatch.
- `Server/ChakraTuning.luau` : objet `Fan`, maîtrise `WindFan`, `ObjectOf.gale/kamatari` (en fin de fichier).
- `Shared/Fighters.luau`, `MoveGraphs.luau`, `Attacks.luau` : entrées en fin de table ; `Shared/Rules.luau` : raison de refus.
- `Client/Effects.luau` : continuité des vols rebasés, crochet `frame`, require `GaleFX`. `Client/VelmoraMotionEngine.luau` : registres `CAST/INTRO`, require `GaleMotion`. `Client/UI.luau` : `table.insert(playable,"Gale")`.
- Tests : `Harness.luau` (marche), `Animation.spec.luau` (listes + Gale), `run.sh` et `build.py` (suite Temari, ligne séparée).

## Duels IA (avertissement, pas un réglage d'équilibre)

72 duels semés (6 graines × 2 ordres × 6 adversaires, harness corrigé) : Temari gagne **31/72** — Minato 2/12, Itachi 10/12, Neji 4/12, Sasuke 8/12, Gaara 3/12, Lee 4/12. Avant le harness et l'IA corrigés : 6/72. Elle tient 12+ studs ~66 % du temps, 20+ studs ~23 % (les IA de mêlée reviennent vite). Gaara reste le plus dur (bouclier + sable à distance, déjà signalé dominant).

## À valider dans Studio (lead)

Place Debug, Play. Duel direct : `print(game.ServerStorage.NinjaDuelDev:Invoke("tool","character",{first="Gale",second="Lion"}))`, ou roster : TEMARI (vous) contre l'IA.

1. **Intro** : éventail planté **ouvert** à sa droite, main droite dessus. Au début du round il passe **dans le dos** (diagonale, poignée au-dessus de l'épaule droite). Vérifier qu'il ne traverse pas le torse (offsets : `GaleFX.MOUNT`).
2. **Posture / marche** : main droite sur la hanche, main gauche ouverte devant ; en marche et en pas latéral la main reste sur la hanche, l'éventail reste au dos ; sprint (CTRL) : bras balancés. Elle ne doit ressembler à aucun autre.
3. **String** (LMB ×3 à 5–7 studs de Sasuke) : pointe (éventail fermé en main) → fauche → l'éventail **s'ouvre** sur la 3e et Sasuke est rejeté à 12+ studs. L'éventail revient au dos en fin de récupération. Orientation de l'éventail en main = point à juger (`MOUNT.hand/open`).
4. **Routes** : LMB, LMB, **W**+LMB → Updraft : Sasuke monte et **reste en l'air** (anneaux d'air montants), puis **1** sur lui (faux en l'air). **S**+LMB après deux coups → Fan Slam. **A/D**+LMB après un coup → Fan Pirouette (jeté du côté demandé). RMB après un coup → revers.
5. **Air** : Space, LMB sur un corps en l'air, **S**+LMB → Fan Dive (le corps plaqué au sol).
6. **R (Bourrasque)** contre Itachi ou Minato en bot : leurs lames **reviennent** sur eux ; à 9 studs R repousse le bot sans dégâts. **Z+R** : cône plus long + un couloir de traits au sol.
7. **1 (Kamaitachi)** : éventail ouvert sur une lune pendant le canal, croissant pâle qui **grandit**, couloir de traits qui suit la faux et reste ~3,6 s. Marcher contre (ralenti, poussé), avec (plus vite). Lames lancées dans le couloir **déviées** (tourbillon), boule de feu de Sasuke qui le traverse **grossit**. Une ruée E droit dans le couloir **se brise** (« THE WIND BREAKS THE DASH »).
8. **2 (Great Gust)** : trois lunes, large cône de traits, bot rejeté (contre un mur : splat).
9. **3 (Rising Whirlwind)** : anneau de marque au sol, colonne qui monte 0,45 s après ; rester = lancé et tenu ; bouger = rien.
10. **E hors fenêtre** à 5 studs : pas de vent en angle jusqu'à ~17 studs ; à 40 studs : arrêt vers 17 (jamais au contact).
11. **Space maintenu en l'air** : descente lente (≤ 12 studs/s), éventail ouvert.
12. **T sous 35 %** : Kamatari (belette sur un croissant) traverse ; couloirs violets ensuite (renvoient les lames) ; à la fin 3 s sans technique (« FAN CLOSED »).
13. **Caméra** à 30–60 studs : les deux corps lisibles.
14. **Bot Temari** : elle doit zoner (faux à distance, Bourrasque quand vous ruez, pas de vent pour sortir, tourbillon devant vous) ; `ai_soak.luau` Gale contre chacun : console sans erreur.
15. **Costume** : quatre couettes sable, bandeau de Suna au front, kimono lilas court, obi rouge, résille aux coudes et genoux, sandales ; aucun rendu « osier ».

## Risques et limites

- **Feel, lisibilité, équilibre : non jugés.** Orientation de l'éventail en main et offsets du dos à régler en natif ; vitesse et taille de la faux, largeur des couloirs : points de départ.
- La ruée brisée par un couloir est une règle forte (lisible, contournable par le côté ou en sautant au-dessus) : à confirmer manette en main.
- Le vol plané et le `jumpHeld` reposent sur Jump/JumpOff du client ; l'IA n'envoie jamais JumpOff (elle plane à chaque saut).
- Le harness corrigé change la vitesse de marche de **tous** les duels headless : les suites parallèles calibrées sur l'ancien harness peuvent bouger à la fusion.
- `Combat`, `AI`, `Brawler`, `Effects`, `VelmoraMotionEngine` restent les fichiers disputés : crochets courts mais à revérifier à chaque fusion (lignes `TEST_RUNNERS`, `playable`, fin de `Fighters`).
- Saisies/projections : clips d'Itachi (dette listée). Pas de charge maintenir/relâcher (aucune entrée de relâchement de technique).
