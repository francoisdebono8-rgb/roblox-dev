# Convergence 2 — modèle combo / entrée, fiabilité des routes, relance universelle

Mission : [CORE_COMBAT_CONVERGENCE_2](../../missions/CORE_COMBAT_CONVERGENCE_2.md) phases 1, 2, 3 et 10 (critères 1–5, 11, 12), DEC-014. Branche `claude/nd-ccc2-combo` (base `50b90bc`).

**Tout ce qui suit est validé en headless uniquement** (Lune, `tests/Harness.luau`). Rien n’a été vu en Studio ni joué à la manette : le ressenti, la caméra et la manette réelle restent à valider (liste en fin de rapport).

## 1. Diagnostic (avant)

Retours de test : « une pression avant le contact compte dans le combo », « le premier vrai coup se comporte comme le deuxième », « l’état du combo a un coup d’avance », « les routes directionnelles se ratent trop facilement ». Causes trouvées dans le code de `50b90bc` :

| # | Cause | Effet joueur |
|---|---|---|
| 1 | La progression des lights était le compteur du donneur (`BanglaCombo.next`) : **+1 à chaque pression** qui démarre un light, tant que la pression précédente date de moins de 1,1 s, coup raté ou non. | Un Light1 raté en approche, puis le premier vrai coup sort en **Light2** ; le deuxième vrai coup est déjà le Light3 (fin de chaîne). |
| 2 | `Combat:request` incrémentait ce compteur **avant** que `Brawler.request` teste les routes (`combo>=2`). | En pression directe, **vers lui + frappe après UN seul coup lançait déjà** ; en pression tamponnée, la même entrée donnait Light2 : direct et tampon ne donnaient pas la même route. |
| 3 | Continuation à la pression : 0,9 s après une chaîne finie, cible partie, la pression suivante continuait (« Light2/Light3 fantôme »). | « Je croyais être au coup 1, le jeu pense au coup 2. » |
| 4 | Air : `airCombo` alternait à chaque pression (0,8 s). | Après un Air1 raté, le premier vrai coup aérien sortait en Air2 ; le switch aérien ne comptait pas comme coup. |
| 5 | `hitConfirmed` était posé par **n’importe quel dégât** de l’attaquant (kunai, brûlure, shuriken de couverture). | Un kunai qui touche pendant un coup raté **ouvrait la chaîne** de ce coup raté. |
| 6 | Direction lue sur **une seule image**, relative au **regard du corps** (pas à l’adversaire), cône « vers » de ±33° seulement. | La caméra est par-dessus l’épaule (≈18–29°) et en retard après un pas latéral : « W » lisait souvent « côté » (AngleStep au lieu du launcher) ; un stick relâché 0,1 s avant la pression lisait « neutre » (Light3 au lieu du launcher). |
| 7 | Une pression tamponnée pendant un coup raté était **jetée**. | Pression « mangée ». |
| 8 | La poursuite visait la vitesse du **root** de la cible, que `Motor.flight` maintient à zéro pendant une réaction (la vraie vitesse est `reactionVelocity`). | Poursuite pressée au moment du lancer : le corps monte, le poursuivant le dépasse et arrive **dos à lui** → l’air strike rate. |
| 9 | E pendant les frames actives du Light3 qui vient d’éjecter : refusé (« Committed »), seul le launcher pouvait être annulé. | Pression de poursuite mangée sur un knock-away. |
| 10 | Chakra dash : arrivée en Neutral, aucune récupération ; saut autorisé à tout instant d’une récupération. | Relance gratuite et non punissable ; un coup raté pouvait « sauter » hors de sa punition. |
| 11 | Harnais : pendant un mouvement cinétique, le faux `Humanoid:Move` déplaçait le root une 2e fois, `Motor.move` croyait à un solveur actif et n’intégrait plus — **toute composante verticale était perdue** en headless. | Les tests de poursuite étaient pessimistes (Studio intègre la vitesse une fois). |

## 2. Changements combo / entrée (exacts)

Fichiers : `src/Server/Brawler.luau` (modèle), `src/Server/Combat.luau` (états, fenêtres, relance), `src/Shared/Config.luau` (`Config.Combo`, `Config.Rush`), `src/Server/Matches.luau` (échantillon d’intention par paquet).

**Coups confirmés** (`a.combo` sol, `a.airCombo` air) :
- un coup de chaîne enregistre au démarrage l’étape qu’il confirmera (`pending.step`) ; le compteur ne change **qu’au contact propre** de ce coup (`Brawler.confirm`). Un coup gardé ne confirme rien. Une absorption par le bouclier de sable de Gaara compte (la chaîne « garde son rythme », comportement existant).
- étape du light = coups confirmés + 1 (Light1 ouvre, Light2 après 1 coup, Light3 après 2 et termine la chaîne). Un « finisseur » (Light3, route non enchaînable, lourds, choppe, slam) ferme sa chaîne au démarrage.
- la chaîne meurt sur : coup raté, coup gardé, coup encaissé (`lastHurt` postérieur au dernier coup confirmé), fin de la fenêtre de chaîne + **grâce 0,18 s** (`Config.Combo.Grace`). La grâce ne sert qu’au light suivant (une pression un peu tardive reste le coup suivant) ; **routes et conversions lourdes exigent la vraie fenêtre de chaîne** (sinon un lourd volontaire après un pin mural devenait le knee).
- contact = celui du coup lui-même : `Brawler.step` isole `hitConfirmed` autour du test de son propre volume ; en fin de fenêtre active `hitConfirmed` = contact du coup.

**Tampon** (`a.buffered`) :
- accepté pendant Startup/Active d’un coup, pendant une poursuite, un chakra dash, ou le canal d’un Flying Thunder God ; expiration fin d’active + 0,3 s (`Config.Combo.Buffer`).
- libéré : à l’ouverture de la chaîne (coup propre), à une arrivée (fin de dodge, dash, poursuite, téléportation), ou, **après un coup raté ou gardé, comme ouverture fraîche (Light1) une fois toute la récupération passée**. Il ne fait jamais avancer la progression lui-même : l’étape est lue à sa libération.

**Intention directionnelle** (`Brawler.classify / observe / intent`) :
- relative à **la ligne vers l’adversaire** (repli sur le regard) : « vers » si l’angle ≤ ~50° (`Toward=0.64`), « éloigné » si ≥ ~125° (`Away=0.57`), « côté » entre les deux (signe = droite/gauche de la ligne). Clavier, caméra verrouillée décalée de ≈18° : W = vers, A/D = côté, S = éloigné ; une diagonale W+D tombe à ≈27° ou ≈63° de la ligne selon le côté du décalage, donc « vers » ou « côté ».
- poussée « forte » ≥ 0,45 ; la **dernière poussée forte est mémorisée 0,22 s** (`IntentWindow`), échantillonnée chaque image serveur, à chaque requête et à chaque paquet Move/action. Pression : poussée courante forte, sinon mémoire valide, sinon neutre. Pression tamponnée : une poussée forte faite **pendant** l’attente l’emporte (« la plus récente »), sinon celle de la pression.
- pas d’aléatoire, pas d’automatisme : une poussée faible n’est jamais une route ; au-delà de 0,22 s la mémoire expire.
- l’IA déclare son intention explicitement (`intentOverride` via `press()` dans `AI.luau`) : sa marche d’approche ne peut plus devenir une route mémorisée ; ses pressions tamponnées gardent l’intention déclarée.

**Rythme Flow** : inchangé (bonus pour une pression sur le temps, jamais nécessaire).

**Divers** : sortie d’une récupération par saut seulement au point d’annulation (`recoveryCancelAt`), comme garde/esquive ; la poursuite peut annuler les frames actives de tout coup qui a touché et ouvert la fenêtre (plus seulement le launcher) ; un clash remet les deux chaînes à zéro ; `queuedLight` supprimé (état mort).

## 3. Table des routes CORE4 (avant → après)

Légende : ✓ existait et fiable ; ⚠ existait mais peu fiable (cause n°) ; ✚ ajouté ; ✗ manquant. Toutes les lignes « après » ont un test headless (`tests/ComboModel.spec.luau`, sections « route table »).

### Sol

| Route | Minato | Itachi | Neji | Sasuke | Avant | Après |
|---|---|---|---|---|---|---|
| Chaîne de base | L1→L2→L3 | L1→L2(aiguille)→L3 | paumes L1→L2→L3 (PalmThrust à 3 points) | coups de pied L1→L2→L3 | ⚠ 1, 3 | ✓ coups confirmés |
| Vers lui (2 coups) | Launcher + sceau corporel | Launcher + 2 shuriken de couverture | Launcher | LionKick → Shadow Leaf | ⚠ 2, 6 | ✓ |
| Éloigné / bas (2 coups) | Sweep + kunai marqué au sol | Sweep | Sweep (2 points) | Sweep | ⚠ 6 | ✓ |
| Côté (1 coup) | AngleStep | FeintStep (image rémanente) | CircleStep | VaultKick | ⚠ 6 | ✓ garde la chaîne, compte comme 2e coup |
| Lourd après 1 coup | KneeStrike | CounterPalm | PalmThrust | KneeStrike | ✓ | ✓ |
| Lourd normal | Heavy | Heavy | Heavy | Heavy | ✓ | ✓ |
| Lourd après 2 coups | Launcher | Launcher | Launcher | Launcher (LionKick via nœud *Dancing Leaf*) | ✓ | ✓ (voir question ouverte) |
| Course | FlyingKick / SlideSweep | idem | idem | idem | ✓ | ✓ |
| Arrivée de relance | DashAttack / lourd rapide | idem | idem | DashAttack ×1,15 | ⚠ 10 | ✚ lourd d’arrivée = son lourd rapide (sauf corps collé au mur : rebond) |
| Outil dans la chaîne | kunai gratuit | 2 shuriken (+ après garde) | kunai | 2 shuriken | ✓ | ✓ |
| Désengagement (éloigné + outil) | bond + kunai | bond + 2 shuriken | bond + kunai | bond + 2 shuriken | ✓ | ✓ |
| Conversion jutsu | Rasengan | **✗ → ✚ Shadow Shuriken** | Vacuum Palm | Chidori | ✗ Itachi | ✚ `stringCancels.NeedleFan` (corps → couverture de projectiles) |

### Air

| Route | Minato | Itachi | Neji | Sasuke | Avant | Après |
|---|---|---|---|---|---|---|
| Chaîne aérienne | Air1→Air2 | idem | idem | idem | ⚠ 4 | ✓ alternance aux coups confirmés |
| Drive (vers lui) | AirDrive | AirDrive + couverture | AirDrive | AirDrive | ✓ | ✓ |
| Spike (éloigné) | AirSpike + rebond | idem | **AirSpike + 2 points** | idem | ✓ | ✚ Neji : la paume descendante ferme un 2e point |
| Switch (côté) | AirSwitch | idem | idem | idem | ⚠ 4 | ✓ garde la chaîne aérienne |
| Conversion propre | Rasengan Drop | éventail de 3 shuriken | paume descendante (ci-dessus) | Lion Combo | ✗ Neji | ✚ |
| Fin | Slam | Slam | Slam | Slam / Lion Barrage | ✓ | ✓ |

### Relance

| Route | Avant | Après |
|---|---|---|
| Poursuite après launch | ⚠ 8 (pressée au lancer : ratée) | ✓ CORE4 : arrive en 0,47–0,50 s, l’air strike touche |
| Poursuite après knock-away | ⚠ 9 | ✓ CORE4 |
| Route après poursuite | ⚠ 8 | ✓ chaîne + routes aériennes ; au sol DashAttack (ouvre une chaîne) ou lourd rapide |
| Route après mur | ✓ (Minato seul testé) | ✓ CORE4 : splat → poursuite → lourd = rebond |
| Version propre au personnage | FTG, Shadow Leaf | ✚ styles de relance (§4) |

Aucun nouveau clip n’est nécessaire (toutes les routes réutilisent des noms d’attaque existants). Demandes au moteur de mouvement client (non bloquantes) : une pose d’« arrivée/freinage » pour la récupération d’un chakra dash (aujourd’hui : la locomotion de base, `Recovery` sans `attackName`), et une pose d’arrêt courte pour la feinte d’Itachi.

## 4. Relance universelle / chakra dash

**Une seule action contextuelle** (`Combat:reengage`) : dans une fenêtre de poursuite (knock-away, launch, projection, splat/rebond mural, substitution à suivre) c’est **la poursuite** 3D ; hors fenêtre c’est **le chakra dash** vers l’adversaire verrouillé. Même prix : `Config.PursuitCost` = 8 (poursuite inchangée, dash 10 → 8). Fenêtres existantes conservées ; pas de fenêtre nouvelle après un simple kunai (les tests de progression *Ricochet Chase* / *Gale Chase* exigent que le kit de base n’en ouvre pas) : après un projectile, c’est le dash qui sert, disponible à mi-distance.

- **Rapide** : dash 90 studs/s × style, fin dès l’arrivée (plus de durée fixe).
- **Suivi** : verrouillé, il suit la cible ; **déverrouillé, c’est un repositionnement droit** de 18 studs dans la direction du stick (sans ciblage).
- **Arrivée** : courte récupération (0,14–0,30 s selon le style) ; frappe (DashAttack, ouvre une chaîne), lourd (le lourd rapide du personnage) ou choppe **immédiatement** ; garde, esquive ou saut seulement après 0,1 s (`Config.Rush.CancelAfter`) : un dash prévisible se punit.
- **Poursuite** : vise la vraie trajectoire du corps (`reactionVelocity` + gravité), arrive de son propre côté, un pas avant et légèrement dessous, face au corps ; dure jusqu’à 0,6 s si le corps monte encore vite ; se termine dès que le corps est à portée et qu’un coup aérien peut le suivre ; peut annuler le coup qui a ouvert la fenêtre.

**Styles** (`MoveGraphs[...].reengage`, impact `chase` avec `variant` pour le client ; mesures headless dash à 12 / 24 / 40 studs) :

| | Vitesse | Arrivée | Angle | Récup. si non suivi | Règle propre | Arrivée mesurée |
|---|---|---|---|---|---|---|
| Minato `flash` | ×1,3 | 3,2 studs | 32° (58° et ×1,12 côté de son sceau planté près de la cible) | 0,14 s | poursuite 0,24 s ; angle alterné ou choisi au stick | 0,15 / 0,25 / 0,39 s — le plus rapide |
| Itachi `mirage` | ×0,8 | 3,8 studs | 18° | 0,20 s | image rémanente au départ ; **garde ou esquive pendant le dash = feinte** (arrêt + image) | 0,16 / 0,33 / 0,55 s — le plus calme |
| Neji `palm` | ×1,02 | 2,9 studs | 0° (ligne centrale) | 0,18 s | utilisable dès **5 studs** (7 pour les autres) | 0,15 / 0,29 / 0,46 s |
| Sasuke `lion` | ×1,15 | 2,8 studs | 0° | **0,30 s** | ligne figée après 0,06 s et visée 2,6 studs **à travers** le corps : un pas de côté le fait passer à côté ; frappe d’arrivée ×1,15 | 0,16 / 0,28 / 0,43 s |

Client (`Effects.luau`, branche `chase`, petit ajout) : flash net pour Minato, copie qui s’attarde pour Itachi, pulsation de chakra pour Neji, départ explosif (étincelles, poussière) pour Sasuke ; variante inconnue = rendu d’origine. Aucun nouveau style d’impact (pas de risque de crash client).

**IA** (`AI.luau`) : envie de relance par personnage (dash ×1,45 Sasuke … ×0,75 Itachi ; poursuite 74 % … 50 %), jamais de dash dans une garde levée, Neji dès 7,5 studs, Itachi feinte parfois son dash (garde), à l’arrivée : DashAttack, lourd rapide ou choppe contre une garde.

### Commandes

- **Clavier** : **E** inchangé (poursuite dans une fenêtre, dash sinon). Même règle serveur que la manette : CTRL (sprint) + Q avec W vers un adversaire verrouillé à mi-distance = dash (au lieu d’une roulade avant).
- **Manette** : **×** poursuit dans une fenêtre (inchangé). Hors fenêtre : **○ (esquive) stick vers l’adversaire verrouillé en sprint (L3) à mi-distance** = chakra dash. Hors sprint, de côté, de près (< 7 studs, 5 pour Neji) ou si le dash est indisponible (recharge, chakra) : esquive normale. **Le dash n’est plus sur la croix directionnelle** (D-pad ← libéré).
- Justification : aucun bouton ajouté ; c’est le geste qu’un joueur fait déjà pour fermer la distance (courir vers lui puis esquiver vers lui) ; la roulade avant reste disponible en marchant et au contact ; aucune collision avec R1 + face (jutsus), R1 + L1 (détache), R1 + L2 (feinte), L1/L2/R2 ; décision côté serveur (le paquet Dodge porte déjà stick et sprint), donc identique en ligne. La croix et les boutons restent libres pour le modificateur de chakra d’un autre agent.
- Textes : `Controls.Help` « E re-engage (chase / chakra dash) », `Controls.HelpPad` « sprint + ○ toward: chakra dash », `PadLabel.Dash`. Pas de nouveau texte en combat (UI simple, phase 10).

## 5. Tests

Nouveau `tests/ComboModel.spec.luau` (22 cas, enregistré dans `tests/run.sh` et `build.py` TEST_RUNNERS). Exécuté contre les sources de `50b90bc` (harnais ancien et nouveau) : **19 échecs / 22**, chacun pour la raison visée ; les 3 qui passaient déjà sont des garde-fous de routes qui marchaient (côté/éloigné, lourds, relance IA).

| Cas | Échec sur `50b90bc` |
|---|---|
| un coup raté n’avance jamais la chaîne ; le premier vrai coup est l’ouverture (CORE4) | « a whiff advanced the combo to 1 » |
| un seul coup = un seul : vers lui après 1 coup = Light2, direct ou tamponné | « (direct): toward after ONE hit gave Launcher » |
| L, L, vers lui relâché 0,1 s avant la pression = launcher (CORE4) | « … gave Light3 » |
| une direction poussée pendant le tampon choisit la route (CORE4) | « … was ignored (Light3) » |
| 40° hors ligne = vers lui ; 62° = côté | « 40 degrees off the line gave AngleStep » |
| 1 coup + côté garde la chaîne ; 2 coups + éloigné = sweep (CORE4) | passe (garde-fou) |
| lourd après 1 / après 2 / neutre (CORE4) | passe (garde-fou) |
| pression tamponnée pendant un raté = ouverture fraîche après toute la récupération (CORE4) | « the buffered press was dropped after the whiff » |
| un kunai qui touche pendant un raté n’ouvre pas la chaîne | « a kunai that landed during a whiff opened the string » |
| pression juste après la fenêtre = suite ; après une pause = Light1 (CORE4) | « a press after a pause continued a dead string (Light2) » |
| mémoire directionnelle : brève, jamais une poussée faible, la plus récente gagne | « a push released 0.1 s ago was forgotten » |
| air : un raté remet la chaîne aérienne à zéro ; drive / spike / switch (CORE4) | « after an air whiff the next air strike is Air2 » |
| table des routes sol (payoffs, course, outil, désengagement, conversion jutsu) | « Mirage: no string cancel into NeedleFan » |
| table des routes air (chaîne, slam, spike-rebond, drive, switch, conversion propre) | « the switch did not count as the second air hit » |
| table des routes relance (launch, knock-away, mur) | « chase refused after the knock-away » |
| E hors fenêtre = dash, dans une fenêtre = poursuite, même prix | « the dash costs 10.0, the chase 8.0 » |
| arrivée : frappe tout de suite, pas de garde tout de suite, lourd rapide | « the dash arrival has no recovery (Neutral) » |
| manette : sprint + ○ vers lui = dash, sinon esquive (CORE4) | « sprint + dodge toward is Dodging » |
| identité : Minato le plus rapide et en angle (côté du sceau), Itachi calme + image, Neji ligne centrale | « Minato is not the fastest re-entry (0.27 / 0.27 / 0.27 / 0.27 s) » |
| identité : feinte d’Itachi, Neji de plus près, Sasuke engagé dépasse une cible qui esquive | « Itachi could not feint his dash with a guard » |
| dash déverrouillé = repositionnement droit | « the unlocked dash homed onto the opponent » |
| l’IA relance (CORE4, 60 s), sans blocage | passe (garde-fou) |

Tests existants modifiés (ils encodaient l’ancien comportement) :
- `Combat.spec` « active window late entry, whiff recovery and combo buffer » : après une pause la pression est **Light1** (avant : Light3) ; la pression tamponnée après un raté sort en Light1 ; « imported Bangla combo » : après le 3e coup, `combo==0` (chaîne finie), la pression suivante est Light1 et ne compte qu’au contact (avant : `combo==3` puis `combo==1` dès la pression).
- `Regression.spec` « a whiffed swing keeps its recovery and cannot queue a phantom combo » : la récupération du raté reste entière, aucune chaîne, la pression tamponnée sort ensuite en ouverture fraîche (avant : elle devait disparaître).
- `Input.spec` : le test « rush » sur D-pad ← devient « re-engage is never a D-pad press » (aucune touche de la croix n’envoie la relance, × poursuit, ○ envoie Dodge, aides à jour) ; nouveau test distant « sprint + dodge toward = dash, a walking dodge stays a dodge » (CORE4, via `Matches:request`).
- `Harness.luau` : les images où `Motor.move` a déjà intégré le root ne sont plus « marchées » une 2e fois par le faux `Humanoid:Move` (cause n°11). Toutes les suites passent avec ; avec l’ancien harnais, le test existant « pursuit reaches a victim that is still rising » échoue sur la nouvelle poursuite (vertical perdu en headless), d’où la correction.

Résultats : `bash tests/run.sh` 19/19 PASS (ComboModel 22, Input 15) ; `build.py`, `--debug`, `--qa` : PASS (19 suites dans chaque manifeste) ; `test_build_isolation.py` OK ; `check_project_docs.py` PASS ; `check_architecture.py` PASS. Rythme IA (graine du test Regression) : 17 jutsus + 10 téléportations, 7 gardes en 60 s (base `50b90bc` sur la même graine : 20 + 4, 18 gardes) — dans les bornes du test, à surveiller en Studio.

## 6. À valider en Studio (rien de cela n’a été vu)

1. Les cônes vers/éloigné/côté avec la vraie caméra par-dessus l’épaule et une manette réelle : L, L, vers + L doit lancer à chaque fois ; 1 coup + côté doit pivoter ; les diagonales clavier (W+D, W+A) doivent rester prévisibles.
2. La grâce de 0,18 s et le tampon : mash régulier, pression tardive, mash pendant un raté (le raté doit rester punissable, la pression suivante sortir en Light1).
3. La poursuite repensée (visée sur la trajectoire réelle, arrivée de côté et dessous, jusqu’à 0,6 s) : pressée au lancer, au sommet, après un knock-away, vers un mur ; vérifier qu’aucun à-coup ni saut d’image n’apparaît (le solveur Studio intègre la vitesse verticale que le harnais n’intégrait pas).
4. Le dash : sensation de vitesse par personnage, l’angle de Minato (et le côté du sceau), la feinte d’Itachi, la ligne de Neji, le dépassement de Sasuke, la récupération d’arrivée (pose de locomotion pendant 0,14–0,30 s) et sa punition.
5. La manette : sprint (L3, bascule) + ○ vers lui à mi-distance ; vérifier qu’on ne perd pas une roulade avant voulue en sprint.
6. Le saut limité au point d’annulation d’une récupération (après un raté, après une arrivée).
7. Les effets client `chase` par variante (lisibles mais discrets).
8. La suite native `NativeQA` (build QA) : son scénario « launcher chase air combo slam » a été rejoué en headless avec ses pas de 0,02 s pour les quatre fighters (poursuite → 2 coups aériens → slam : OK), mais pas encore en Studio.
9. Le limiteur anti-triche (`VelmoraCombatConfig.Rates.Attack` = 0,16 s entre deux paquets Attack) : un double appui très rapide peut perdre une pression avant même le tampon (fichier hors de mon périmètre).

## 7. Questions ouvertes

- **Sasuke, kit de base vs progression** : lourd après 2 coups = Launcher générique (LionKick seulement via le nœud *Dancing Leaf*), contre-coup du Sharingan seulement via *Sharingan Counter*. La mission dit que l’identité ne doit pas dépendre de la progression, mais `SkillBuilds` refuse qu’un nœud remplace une valeur du kit de base et les tests de progression le verrouillent : décision du lead.
- **Prix unifié 8** : la poursuite garde son prix, le dash baisse (10 → 8) mais devient punissable ; à ajuster après jeu.
- **Clavier** : faut-il réserver la règle sprint + esquive vers lui à la manette (E suffit au clavier) ? Aujourd’hui la même règle serveur vaut pour les deux.
- **Fenêtre après un kunai** : volontairement non ajoutée (progression) ; à rouvrir si le lead veut une relance contextuelle après outil dans le kit de base.
- **Gardes de l’IA** en baisse sur la graine de test (voir §5) : à juger en jeu.

## 8. Fichiers

`src/Server/Brawler.luau`, `src/Server/Combat.luau`, `src/Server/AI.luau`, `src/Server/Matches.luau`, `src/Shared/Config.luau`, `src/Shared/MoveGraphs.luau`, `src/Shared/Controls.luau`, `src/Client/Input.luau`, `src/Client/Effects.luau` ; `tests/ComboModel.spec.luau` (nouveau), `tests/Harness.luau`, `tests/Combat.spec.luau`, `tests/Regression.spec.luau`, `tests/Input.spec.luau`, `tests/run.sh`, `build.py` ; `dist/*` reconstruits.
