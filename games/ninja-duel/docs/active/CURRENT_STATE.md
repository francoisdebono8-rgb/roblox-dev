**Audit de jeu en jouant → v21 (03/11, 14 h 30 – 16 h)** (utilisateur : « les combats trop courts », « fais un audit global du gameplay en y jouant ; dès que tu repères un bug ou une incohérence, tu fais une place où tu le recrées et tu répares » ; puis à 15 h : « freeze, bugs, sensation horrible… les traînées aux bords de l'écran quand on court me rendent fou »)
- **Rounds plus longs** : les dégâts reçus sont multipliés par `Config.DamageScale` (0,6), après la réduction des combos. L'impact visuel et la force du coup gardent le poids d'origine. Le bouclier de Gaara repousse 1/0,6 fois plus lentement, pour qu'il garde sa part. Simulation IA contre IA : 70 s par round en moyenne (de 39 à 120 s), Gaara gagne 64 % de ses duels (82 % sans la compensation).
- **Traînées au bord de l'écran** (lignes de vitesse à la course) : supprimées. Elles restaient aussi affichées pendant toute la recharge du dash, donc presque tout le temps.
- **Places de repro** (`Server/Repro.luau`, Debug seulement ; `tools/make_repro_place.py <id>` → `ND-Bug-<id>.rbxlx`) : la place met le duel dans la situation du bug, affiche ce qui n'allait pas et ce que la correction montre, et rejoue la situation toutes les quelques secondes.
- **B01, touches en QWERTY sur un clavier AZERTY** : le tutoriel et l'aide demandaient Q et Z. Les étiquettes suivent maintenant le clavier (`GetStringForKeyCode`), y compris les notes d'enchaînements de la sélection. Le « A » seul reste l'article (« A CLONE »). Test : `Input.spec` (B01).
- **B02, coups en l'air dans le vide** : un saut sur place à côté d'un adversaire debout monte à 15 studs au-dessus de sa tête, et le léger comme le salto passaient au-dessus de lui. Correction : de là-haut, le léger plonge sur lui et le salto redescend sur sa tête ; les deux finissent à côté de lui. Vérifié dans Studio (les deux touchent). Test : `AirCombat.spec` (B02).
- **B03, l'IA ne lançait jamais son ultime**, alors que son HUD affichait ULTIMATE READY. Maintenant, barre pleine et cible à portée, elle le lance, surtout sur une ouverture, et de plus en plus sûrement tant que la barre reste pleine. Test : `Ultimates.spec` (B03). Les détecteurs de blocage des duels IA acceptent la séquence d'ultime (3,4 à 4 s).
- **Freezes, mesurés** :
  - côté écran : client à 60 images/s, un seul accroc de 82 ms sur 150 s ;
  - côté perso : `Control.sim`, 8 persos × 60 s, aucun moment où l'on est libre, stick tenu, sans bouger. On est sans contrôle 16 à 27 % du temps sous les coups de l'IA ; le plus long blocage est son ultime (4,5 s), tracé par la sim.
  - Ce que l'utilisateur a vu figé pendant l'audit venait en partie des outils : bot immobilisé (`freezeBot`), répétitions des places de repro. L'enregistreur (`DevFlight`) lira ses propres freezes dans la v21.
- **Vu, pas des bugs** : la saisie seule ne projette pas (le tutoriel enseigne « saisis, puis projette ») ; Chidori et Rasengan se gardent en main jusqu'au coup suivant ; « Condition missing » sur le Genjutsu juste après une téléportation de test.

**Vérification Studio de la v19 → v20 (03/11, 14 h)** (utilisateur : « on est demain, vérifie tout, je vois pas mal de choses qui vont pas »)
- **Fichiers ouverts par l'utilisateur** : `ND-Test.rbxlx` (29/10, 32 modules de clips) et `ND-FreezeFix` (banc de l'autre session). Aucun n'était la v19 (55 modules).
- **Méthode** : `ND-Test-v19` ouvert dans Studio ; tutoriel joué par le bot (`tutorialRun`) pour les 8 persos ; sonde client (`TutorialProbe`) qui mesure ce qui se voit. Résultat : aucune erreur dans la console, 28/29 étapes réussies par perso, sauf les blocages corrigés ci-dessous.
- **Corps qui saute de 3 à 9 studs en une image** (atterrissage, plongée, poursuite ; 6 à 20 fois par perso). Cause : `snapshotRoot` prolongeait la chute sous le sol, puis le paquet suivant le remontait. Correction :
  - prolongement à plat, gravité en l'air, arrêt au sol ;
  - le corps dessiné ne parcourt pas plus que la vitesse max du corps par image ; une téléportation déclarée saute toujours.
  - Mesuré en direct : Sasuke 17 → 9 (pire 7,5 → 2,6 studs), Lee 18 → 9, Minato 20 → 3.
- **Corps fondus l'un dans l'autre** (Minato poussé dans Gaara) : l'avance locale ne rapproche jamais plus que ce que garde le serveur.
- **Interface** :
  - le panneau de debug (`CombatDebug`) est caché par défaut (F8) : il couvrait la plaque du joueur ;
  - la plaque du joueur commence après les boutons Roblox (`GuiService.TopbarInset`).
- **Tutoriel bloqué selon l'adversaire** :
  - le bouclier de sable de Gaara mangeait le coup en course et la saisie : baissé pendant les exercices, levé pendant le duel ;
  - le Dieu du Tonnerre Volant de Minato reçoit un sceau ;
  - l'esquive accepte n'importe quel coup ;
  - l'évasion après un coup reçu se fait sur un coup léger (le lourd de Gaara met au sol) ;
  - l'interruption prend une technique tenue sur place (le Rasengan de Naruto fonce).
- **Mesuré sans changement** : l'IA met KO un joueur passif en 17 à 39 s (headless).
- **Livré** : `ND-Test-v20.rbxlx` (+ `ND-Jeu`, `ND-Labo`).

**Parties 8–9 de la feuille de route : le socle dessiné pour les 8 (03/11, 1 h 30)** (utilisateur : « continue la suite étape 8 9 10 », « pk que Neji »)
- **Mesure de départ** : seuls Sasuke et Minato avaient leur garde, leurs coups reçus, chutes, relevés, esquives et poursuite dessinés ; les 6 autres les jouaient en procédural. Aucun des 8 n'avait sa saisie ni ses projections ; seul Sasuke avait le salto talon en l'air (`AirFlip`, lourd en l'air hors chaîne).
- **Garde, réactions, esquives, poursuite des 6** (`tools/blender/job_react_6.py`, le jeu de `clips_react2` sur la garde de chacun) : 23 clips × 6 (garde et impact, coups reçus tête / corps / flanc / dos / jambes des deux côtés, projeté et réception, envoyé en l'air, au sol, relevé des deux côtés, dash, roue, flip arrière, poursuite). Tempo propre : Lee revient le plus vite, Gaara le plus lent, Naruto encaisse large. Gaara pare bras croisés (le sable prend le coup), Neji paumes levées.
- **Saisie, projection, projection en l'air pour les 8** et **salto talon pour 6** (`tools/blender/common_e9.py`) : la jambe avant fait un vrai pas (glissement des pieds 0,18 → 0,04 stud).
- **Flip de saut** pour Lee, Naruto, Kakashi, Neji (ceux qui font des figures, `Motion.ACRO`).
- **Riposte et plongée du mur** jouées avec le Light1 et l'AirDrive dessinés de chacun (Gaara n'a pas d'AirDrive : sa plongée reste procédurale) (`Motion.DRAWN_AS`, client seulement : le timing serveur ne bouge pas) ; une seule règle pour savoir quel clip joue un coup (`Motion.drawnClip`), aussi pour les appuis.
- **Clips** : 449 → 621.
- **Test « un jab plie le corps »** (`CombatFeel`) : mesuré depuis la garde de chacun (l'ancien seuil lisait l'inclinaison absolue : seul un perso penché pouvait le passer). Seuil = le jab dessiné de Sasuke filmé en Studio (12°) ; les 6 nouveaux : 15–21° au jab, 42–52° au coup lourd.
- **Branche parallèle intégrée** (`claude/ninja-duel-tutorial-v2` : freezes, tutoriel v2 et sonde, nouvelle interface, look) ; trois tests réparés après la fusion (bibliothèque `task` du banc de test, escalade avancée image par image).
- **Livré** : `ND-Test-v19.rbxlx` (+ `ND-Jeu`, `ND-Labo`), liste « quoi essayer » du projet mise à jour.
- **Partie 10 (boucle du joueur)** : déjà en place (sélection → duel en rounds → résultat → revanche / retour, tutoriel) ; son interface et son tutoriel sont le chantier de l'autre session : rien de doublé ici.

**É7, les devinettes tiennent le ping (03/11, 1 h 30)** (utilisateur : « continue la suite des étapes »)
- **Tout ce que la touche peut lancer est deviné**, en suivant `Brawler.request` dans le même ordre : coups en l'air (Air1 / Air2 selon la chaîne aérienne, talon `Slam` ou salto `AirFlip`, Lion Combo et finishers), routes au stick (haut, bas, côté) au sol et en l'air, plongée sur un corps au sol (`WallDive`), coup en tombant (`DropStrike`), coup de fin d'esquive ou d'arrivée (`DashAttack`, lourd d'arrivée), enchaînement contre un mur (le client lance le même rayon que le serveur), riposte, paume de Neji (`PalmThrust`), l'image d'Itachi sous illusion.
- **Lecteurs partagés serveur / client** (`Shared/ActionContext`) : le stick (`stick`), la géométrie du plongeon (`airDive`), les surfaces (`surface`).
- **Lu au moment où la touche arrive au serveur** : le snapshot envoie les fenêtres en temps restant (`guess = Brawler.guessView` : chaîne, enchaînement, arrivée, riposte, Lion, annulation, recharge du dash, sortie d'un coup reçu, maintien en l'air). Le client les lit un aller-retour plus tard (`Presentation.viewAt`, aller simple mesuré par `noteSnapshot`), les corps avancés sur leur vitesse, et ne devine que si la réponse est la même à ½ et à 1,5 aller-retour (`steady`). Pas de devinette quand une pression attend déjà, quand le corps touche le sol entre-temps, quand une course monte ou retombe. Les devinettes attendent un aller-retour avant d'être abandonnées.
- **Esquive** : aussi pour sortir d'un coup reçu (passé sa part, `Brawler.standIn`, comme le serveur) et en sprint vers lui quand le dash chakra n'est pas disponible (recharge, chakra, trop loin).
- **Mesure** (`tests/Prediction.spec.luau`, release : duels IA, pressions aléatoires, à 0 et à 100 ms de ping, le joueur ne touche à rien pendant l'aller-retour) :

| | 0 ms : justes / faux | 100 ms : justes / faux (+ coup reçu en route) |
|---|---|---|
| Léger | 37 / 1 | 32 / 2 |
| Lourd | 57 / 0 | 34 / 1 (+1) |
| En l'air | 11 / 0 | 6 / 0 |
| Esquive | 30 / 0 | 19 / 0 (+4 : devenue permutation) |

  Avant (mêmes duels, 100 ms, lecture du snapshot tel quel) : léger 19 % faux, lourd 7 %. Pas devinés exprès : la permutation de sable de Gaara (téléportation) et l'esquive en l'air.
- **Banc de test** : le sol a un vrai parent (le parkour remonte les ancêtres ; `Parent=true` cassait une lecture de rebord).

**É7, les gestes du joueur devinés juste (03/11, 0 h 30)** (utilisateur : « continue tes missions initiales »)
- **L'impact au contact** (`Presentation.localContact`) : au moment où le coup deviné touche le corps dessiné (portée du coup + 1,1 stud), si l'adversaire est ouvert (ni en garde, ni en esquive, ni à terre, ni en Rotation), le son, les éclats et le coup de caméra partent tout de suite ; le contact du serveur pour ce coup ne rejoue que ses effets du monde (pas de second son).
- **Deviner ce que le serveur fera vraiment** : le client lit la situation du corps avec le même lecteur partagé que le serveur (`Shared/ActionContext` : dans le dos, sur le flanc, de près, au bout de la portée, en reculant, en courant) ; les coups de course ; la chaîne ouverte ; pas de devinette dans une riposte, un état tenu (Chidori), une fenêtre de re-entrée. L'esquive suit les règles du serveur (chakra, temps de recharge, sable de Gaara, dash chakra, ré-engagement en sprint) et sort d'une récupération passé son point d'annulation ; le saut aussi.
- **Nouveaux champs du snapshot** : `chainReady`, `stringAlive`, `arrival`, `riposte`, `cancelReady`, `jumpCancel`.
- **Mesure** (`tests/Prediction.spec.luau`, dans la release : duels IA, pressions aléatoires comparées au serveur) — devinettes fausses : coup lourd 64 % → 5 %, léger 60 % → 9 %, esquive 0 % ; esquives devinées 11 → 26 sur 47.

**É7, PV logiques (02/11, 23 h 40)** (utilisateur : « pas logique Naruto moins de PV que Sasuke », « à 13 ans Itachi n'est pas malade ») — remplace les chiffres de l'équilibrage précédent. Les PV suivent l'histoire, l'équilibre passe par les dégâts :

| Perso | PV | Dégâts | Pourquoi |
|---|---|---|---|
| Naruto | 150 | × 0,82 (clones 3 toutes les 2,3 s ; Naruto Rendan 18 → 21) | l'endurance d'Uzumaki ; il gagne au nombre, pas au coup |
| Lee | 140 | × 1,00 | le corps forgé par l'entraînement |
| Gaara | 138 | × 0,88 | l'armure et le bouclier de sable |
| Itachi | 130 | × 1,15 (chakra + 8,6/s, vitesse 18,5) | 13 ans, ANBU, en pleine forme : le prodige précis |
| Sasuke | 130 | × 1,10 | |
| Kakashi | 130 | × 1,05 | |
| Neji | 130 | × 1,12 | |
| Minato | 125 | × 1,00 | le plus rapide de tous |

Matrice IA contre IA des 8 (`tests/Balance.sim.luau`) : 39–61 % (Sasuke 39, Neji et Lee 46, Minato et Kakashi 50, Itachi et Naruto 54, Gaara 61). Indicateur seulement : à confirmer en jouant.

**É7, suite (02/11, 23 h 30)** (utilisateur : « continue sur ta voie »)
- **Pas en avant des coups à la touche** (`Presentation.predictStrike`) : le corps avance vers l'adversaire dès la pression, sur la courbe du serveur (`Combat` drive), arrêté à la portée du coup ; rien sans place pour avancer.
- **Équilibrage des 8** (matrice IA contre IA, `tests/Balance.sim.luau` passée à 8) : écart 25–82 % → 36–64 %. Naruto PV 140 → 128, clones 4 dégâts toutes les 1,9 s → 3 toutes les 2,3 s ; Sasuke PV 120 → 132 ; Neji dégâts × 0,95 → 1,06 ; Lee PV 125 → 132, dégâts × 1,06 ; Gaara PV 140 → 134. L'IA n'est qu'un indicateur : à confirmer en jouant.
- **Essai retiré** : jouer toute la préparation des clips (début accéléré) au lieu d'en sauter le début : plus de sauts mesurés (201 → 227 images > 25° sur les préparations des 8), comme l'essai 1 du 02/11.

**É7, ressenti du perso joué (02/11, 22 h 45)** (utilisateur : « on est pas au niveau de la triche encore, fais le truc le plus impactant niveau ressenti » ; audits du jour : corps affiché ~65 ms derrière le serveur, esquive / saut non prédits)
- **Corps du joueur dessiné au présent** (`Presentation.smoothRoot`) : plus de retard fixe de 45 ms pour son propre perso ; entre deux paquets il continue sur le dernier segment (au plus 1/30 s). L'adversaire reste interpolé 45 ms derrière.
- **Esquive et saut à la touche** (`Presentation.predictMove` / `movement`) : le corps part sur la même courbe que le serveur (esquive 14 studs × DashScale en 0,32 s ; saut à JumpVelocity × JumpScale), la pose d'esquive aussi ; confirmée par l'état serveur en ~0,1 s, sinon abandonnée en douceur (0,16 s). Pas de saut prédit dans une fenêtre de poursuite (le saut manette y est la poursuite).
- **Coup après une course** : l'avance de course s'efface sur 0,18 s pendant le coup au lieu de 0,07 s (le corps n'est plus tiré en arrière au départ du coup).
- **Chevilles** : 54 allers-retours de cheville lissés à l'export (`clips_to_luau.ankle_jitter`) ; les gestes rapides dans un seul sens restent.
- **Preuves** : `Animation.spec` (corps au présent, esquive et saut dès la première image, abandon sans confirmation). Non mesuré en Studio : à sentir en jouant.

**É6, derniers manques de la liste des coups (02/11, 22 h)** (utilisateur : « poursuit sur la suite »)
- **Lotus primaire (Lee) et Naruto Rendan (×)** : portée 13 ; au-delà de 3,4 studs il fonce d'abord (64 studs/s) puis lance. Avant : refusés à 10 studs. L'IA les garde au contact (`AI` Sequence ≤ 9).
- **Kakashi, tantô dégainé** : ses propres coupes (`Copycat.Blade.*`, 12 clips : 3 coupes, estoc de chakra blanc, coupe montante, coupe basse, pas feinté + coupe, attaque en course, coupes aériennes, coupe plongeante), au lieu du couteau partagé de Sasuke et de ses poings sabre en main (`Motion.kunaiClip`).
- **Naruto** : course + △ = plongée tête la première (`HeadDive`, roulade à la réception) ; air □ □ △ = deux clones (vrais corps, `Legion.airDrive`) qui renvoient l'adversaire au sol.
- **Coup lourd aérien propre aux 8** (`<perso>.Slam`) : talon écrasant, marteau, piqué, piqué au kunai, talon, paumes plongeantes, talon de la feuille. Avant : pose procédurale pour 7 sur 8.
- **Jutsu sans animation** : Byakugan, armure de sable, retrait des poids, glissade de sable (route latérale de Gaara).
- **Pipeline Blender** : jambes en l'air en espace bassin avec genou dans le plan du mouvement et clés en arc (`ult_clips._between`) : les 180° de hanche dans les ultimes de Naruto, Sasuke et Lee ont disparu (contrôle FLIP de l'export). Dépôt sur le Mac : un nom de fichier préparé unique par envoi (sinon l'ancien contenu est réécrit).
- **Preuves** : `Lee.spec` (portée), `Naruto.spec` (plongée, clones), `Animation.spec` (clips propres) ; release à jour. Non jugé en jeu.

**É6, ultimes refaites (02/11, soir)** (utilisateur, 20 h 50 : « globalement tous les mêmes … les coups sont mal faits … même effet même sensation à chaque fois » ; 20 h 53 : « fais le juste », sans vidéo)
- **Un script par ultime** (`Shared/UltimateScripts`, partagé serveur/client) : trajectoires des deux corps dans le repère de la prise, coups datés, dernier coup à T-0,3, plans de caméra (coupes, cadrages qui suivent un corps) et moments dessinés.
- **Clips Blender sur toute la séquence** (`tools/blender/ult_clips.py`, job 180/181) : `<perso>.Ultimate` pour le lanceur depuis l'appui, `Ult.<kind>.Victim` pour le corps pris ; joués par une branche de `VelmoraMotionEngine` (champs `ultClip/ultSerial/ultElapsed` du snapshot). Jambes en l'air en espace bassin (vrilles, saltos, chutes cohérents).
- **Chacun le sien :** Naruto, vrais clones (`Bodies`, mode `ult`) puis U-ZU-MA-KI et talon du ciel ; Sasuke, course Chidori qui déchire le sol, empalé, lancé, Lion Combo en l'air ; Gaara, une seule masse de sable de l'inondation à l'éclatement (plus de pyramide) ; Lee, portes, coup montant, flipper aérien avec images rémanentes, bandage, chute ; Neji, trigrammes, pluie de paumes 2→128, silence, dernière paume ; Itachi, œil, monde rouge, croix, épées, 72 h ; Minato, éventail de kunaï, temps arrêté, 8 apparitions, dos tourné, coupes en même temps ; Kakashi, chiens, Raikiri chargé, course, transpercé. Impact frames et mots à l'écran.
- **Preuves :** `tests/Ultimates.spec.luau` 11 PASS (scripts distincts, clips présents et assez longs, aucun corps lié, Naruto ≥ 10 clones réels, chaque indice et plan dessinable), release PASS. Places `ND-Test-v12`, `ND-Jeu`, `ND-Labo` dans Documents/Roblox. **Non jugé en jeu** : acceptation à faire en jouant.

**Arène, É5 close (29/10, 17 h 45)** (photos de référence de l'utilisateur, 17 h 03) : refaite dans Blender d'après le vrai stade (`tools/blender/arena_assets.py`, `arena_kit.py`, `arena_to_luau.py` → `Server/ArenaMeshData`, posée par `Server/ArenaMeshes` dans `World.arena`). Mur intérieur lisse en panneaux gris-vert, bol extérieur rouge en dôme à nervures, spectateurs seulement dans la grande salle et les quatre ailes au nord, sol de terre claire avec grain (texture à 50 %), herbe et touffes irrégulières, buissons et arbres entiers le long du mur, forêt autour. Plus de poteaux, caisses, rochers ni lanternes au milieu. Gameplay inchangé : sol, mur de course (invisible sous le décor), balcon, troncs (cassables). Sans les meshes (tests headless), l'ancien stade en pièces reste le secours.

**Apparence des 8 persos, passe finale bêta (29/10, après-midi)** (utilisateur : « cheveux et bandeau, faut que tu t'y attardes », « les mains sont des moignons », « produis les designs sur Blender »)
- **Visages dessinés** (`Shared/Face`) : yeux, sourcils et bouche sur des plaques tangentes à la tête ; expressions selon l'état (combat, cri sur les lourds et les jutsu, douleur, K.-O., victoire), clignement ; Sharingan et yeux de renard en teinte.
- **Meshes Blender** :
  - `tools/blender/nd_look.py` et `nd_kit.py` : une seule forme de tête dont dérivent la peau, la masse de cheveux et le bandeau ;
  - le bandeau se porte par-dessus les cheveux : la mèche sort dessous, les pointes débordent au-dessus ;
  - des poings avec des doigts.
- **Chaîne de production :**
  - `look_<perso>.py` produit un FBX et un manifeste ;
  - Studio importe le FBX et téléverse les meshes ;
  - `looks_to_luau.py` écrit `Server/LookMeshData` ;
  - au démarrage, `Server/LookMeshes` charge les meshes, puis habille le perso.
  - La version en pièces simples (`Server/Looks`) reste en secours.
- **État (16 h 30) : É4 close.** Les 8 sont en jeu sur meshes Blender (8 imports Studio). Dernière retouche : nœud du bandeau à pans écartés ; épis sans la couronne autour du bandeau (sauf Sasuke inchangé) ; mèches pointues pour Minato et Gaara ; crâne arrêté sous les cheveux (le dessus de la tête ressortait vu d'en haut en combat : « Itachi devient chauve ») ; meshes en détail plein à toute distance. Yeux : la paupière couleur peau n'est pas découpée sur un visage 3D (rectangle clair au-dessus de l'œil) ; un œil plissé est maintenant un blanc plus court, sourcil posé sur le bord. Le joueur pourra plus tard jouer avec son propre skin : les persos ne sont plus la priorité.

**Audit de fluidité (29/10, nuit), après les 2 combats joués par l'utilisateur** (« je pouvais plus bouger », « plein de bugs et d'incohérences ») — [rapport](../reports/fluidity-audit-2026-10-29/REPORT.md).
- **Les causes corrigées :**
  - le stick était coupé hors de l'état neutre (garde, canalisation, récupération) ;
  - l'atterrissage n'était pas détecté pendant les coups et les stuns (faux « en l'air », corps figé) ;
  - un anti-triche jetait la 2e pression ;
  - il n'y avait pas de mémoire des touches ;
  - suspension après un chase, et coup sauté qui se figeait ;
  - boucle garde / stun ;
  - réactions aériennes coupées en vol ;
  - coup ou dodge au réveil perdus ;
  - embardée après un stun ;
  - R1 qui chargeait du chakra, × décidé sur un état périmé, jutsu tenus à la manette ;
  - touches oubliées au nouveau round ;
  - léger de près de Gaara qui était un lanceur ;
  - caméra au K.-O. et au corps à corps ;
  - effets calculés deux fois par image.
- **Mesure (joueur manette scripté contre l'IA, 8 persos) :** pressions mangées 7 % → 2 %, faux « en l'air » → 0.
- **La release bloque maintenant sur la fluidité :** `tests/Fluidity.spec.luau` (12 tests, tous échouaient avant), `tests/Control.spec.luau` (contrôle du joueur), ainsi que Mouvement, Embodiment et CombatFeel, qui étaient hors de la release.
- **Contrôle Studio (`ND-Visual4.rbxlx`, physique réelle) :**
  - agent joueur sur 3 × 70 s (Gaara–Itachi, Naruto–Itachi, Kakashi–Lee) : 0 freeze, 0 état figé, 1 faux « en l'air » de 0,7 s au réveil au pied d'un mur (corrigé : un corps qui se relève est posé au sol) ;
  - vraies touches clavier (marche, saut, garde + D qui marche à 8, dodge, saut en courant) : tout répond ;
  - en garde avec le stick, le corps se déplace de 5,5 studs en 0,6 s ;
  - après un coup sauté, le perso est libre au sol en 0,65 s et marche aussitôt ;
  - K.-O. filmé (Sasuke contre Itachi) : la caméra suit le corps projeté jusqu'à ce qu'il retombe couché ;
  - l'accroupissement d'atterrissage attend que le corps dessiné touche le sol : il est dessiné environ 45 ms derrière le serveur, et l'accroupissement commençait 2 studs en l'air.

**Partie 10, passe visuelle (28/10, 19 h 45 → 21 h 30, utilisateur absent)** — chaque point filmé en Studio (captures en rafale), puis corrigé et refilmé :
- **caméra** : plus large, décalée sur le côté, centrée vers le joueur (plus de corps qui se masquent) ; flash de coup court et clair au lieu d'un corps rouge ;
- **contact** : un coup léger s'arrête à une longueur de bras (4,1) ; un coup au ventre recule les hanches et redresse le buste (le pli de 77° collait les têtes, 1,9 stud) ;
- **course** : un léger en courant ouvre l'enchaînement (le coup de pied sauté reste sur le lourd) ;
- **arène, avec un poids** (retour 19 h 43 « pas un champ de mines ») : le sol ne garde que les coups lourds (slam, pique, grande boule de feu), au plus 10 marques, qui s'effacent après 22 s (60 s pour les grandes) ; une zone qui brûle laisse une brûlure, jamais un cratère ;
- **coup final** (nouveau) : le dernier coup du round projette le corps en arc, au ralenti 0,45 s puis à pleine vitesse, il casse ce qu'il touche, retombe couché et reste au sol ; le K.O. dure 2,6 s ;
- **animations « comme un film »** (passe dans l'export des clips, `clips_to_luau.py`) : 83 coups figés net après l'impact continuent maintenant leur mouvement puis se posent sur la clé (dépassement et retour) ; 31 articulations qui sautaient en une image dans les cycles (garde qui changeait de main en reculant) sont lissées ;
- **Sable de Gaara** : le Cercueil de sable enferme le corps dans des bandes de sable tassé qui montent jusqu'au cou, puis s'effritent (pas encore refilmé : écran du Mac en veille).
Puis (23 h 45 → 0 h 30, écran revenu, `ND-Visual2.rbxlx` ouvert en Studio) :
- **Cercueil de sable filmé** : les bandes de sable enferment le corps (8 bandes, jusqu'au cou), puis l'enterrement ;
- **coup final filmé avec Itachi** : arc, ralenti, retombée couchée, le corps reste au sol pendant le K.O. ;
- **Dragon aqueux de Kakashi** (filmé : une boule bleue) : un long serpent d'eau qui sort du sol devant lui, se cabre et plonge sur la cible, le corps suit le vrai trajet de la tête, cornes et mâchoire ; tous les serpents du jeu suivent maintenant leur trajet ;
- vus sans défaut à corriger : 64 Paumes de Neji (compteur, cercle, projection), Raikiri bleu-blanc, Rasengan de Naruto (formé par le clone, tenu 3 s).
L'écran s'est remis en veille vers 0 h 30.

**Partie 10, la boucle joueur (28/10, soir), après le match observé** — [DEC-030, révision 16 h 55](DECISIONS.md#dec-030--autonomie-de-claude-et-feuille-de-route-par-parties-jusquà-la-bêta-en-ligne-2810). Fait, chaque lot avec release PASS :
- **décor qui casse** (`531447b`) : poteaux d'entraînement, caisses et lanternes de pierre dans la zone de combat (34–56 studs), solidité propre à chaque objet (une caisse cède à un coup lourd) ; cratères, entailles, tranchées et fissures dessinés en relief : blocs du sol soulevés et inclinés, dans sa matière et sa couleur, au lieu d'une marque imprimée ;
- **Katon propre à chaque lanceur** (`14fdbd6`) : Sasuke, boule serrée blanc-jaune qui roule vite, main en anneau à la bouche, recul puis projection du buste ; Itachi, masse rouge sombre plus lente avec traîne et fumée, signe du tigre gardé sur la poitrine, droit, sans main à la bouche (clips Blender refaits) ; souffle visible de la bouche à la boule ;
- **liberté : le chakra dans l'action suivante** (`eb8c2fa`, `Server/ChakraFlow`) : R1 (clavier Z) tenu seul charge le chakra de sa nature pendant 2,4 s. L'action suivante le prend :
  - frappe : ×1,3 à ×1,45, plus d'allonge, et la nature au contact (foudre qui prolonge l'étourdissement, feu qui brûle, vent qui projette plus loin, poing souple qui ferme un point, sable qui ralentit, force brute de Lee) ;
  - saut : bond de chakra ;
  - esquive : dash de chakra vers l'adversaire, au sol sans sprint ni verrou, et en l'air ;
  - outil : le lancer chargé de chakra sans l'accord R1 + R2.
  Le bot s'en sert aussi. Studio, physique réelle : lourd 14,7 → 21,3 (foudre), saut 18 → 30 studs (réduit ensuite à environ ×1,5), dash au sol et en l'air jusqu'à 3–4 studs de l'adversaire.
Reste dans la Partie 10 : combat aérien plus vivant, techniques depuis toutes les positions, contrôle visuel en Studio (écran du Mac verrouillé : le serveur est vérifié, pas encore l'image), puis un match enregistré avec l'utilisateur.

**Méthode (28/10, 13 h 18) : autonomie et parties** — [DEC-030](DECISIONS.md#dec-030--autonomie-de-claude-et-feuille-de-route-par-parties-jusquà-la-bêta-en-ligne-2810). Partie 0 faite : les vingt capturés en Studio, [rapport](../reports/partie0-2026-10-28/REPORT.md). Partie 1 (Sasuke), première livraison `ND-Partie1b.rbxlx` : routes, aériens, Lion Combo, jutsu joués par le corps (signes, souffle, rafales), intro et entrée de la marque maudite, kunai en main sur tout son taijutsu ; contrôlé en Studio sur planches (`tools/studio/probes/audit_*`). Verdict humain PENDING ; restent victoire, murs, substitution. Retour utilisateur 15 h 01 : « pas d'amélioration dingue », la fluidité d'abord, le kunai doit être global. Partie 1c, le socle commun :
- réactivité du joueur local : stick envoyé au changement, état à 30 Hz, corps dessiné en avance sur la piste serveur, coup lancé dès l'appui ;
- **kunai pour tous** : B ou D-pad ← pour le sortir ou le ranger. Lames et lourd au kunai : clips communs `Kunai.*`, +0,6 de portée, ×1,1 de dégâts, coupe. Garde tenue par le bras droit par-dessus toute pose. R le lance et la lame est perdue. Le bot s'en sert aussi. Sasuke retrouve ses coups à mains nues ;
- Katon : 3 signes au lieu de 5, Channel 0,32 s au lieu de 0,5 s ;
- intro filmée de près, chaque combattant à tour de rôle ;
- fil de Sasuke : six spires qui se serrent et un fil tendu jusqu'à la main.
- contrôle Studio `ND-Partie1c.rbxlx` (Itachi au kunai : sortie, garde, course, enchaînement, lancer ; intro ; fil) : 0 erreur. Le bandeau VS cachait la pose d'intro : les noms passent en bas d'écran.

Partie 2 (Sasuke fini), `ND-Partie2a.rbxlx` : pose de victoire `Lion.Win` (dos tourné, mains dans les poches, regard par-dessus l'épaule), jouée par le vainqueur après le K.O. et sur l'écran de résultat ; contrôlée en Studio.

Partie 3 (Itachi), `ND-Partie3a.rbxlx` : 49 clips authored (`tools/blender/itachi_p3.py`), sur sa bible (« inviter, lire, punir avec un geste plus petit »).
- Corps : posture droite, main gauche ouverte qui invite, droite à la sacoche. La démarche de Sasuke est rejouée en version calme : épaules stables, bras contenus.
- Coups : L1 tranchant de main, L2 paume, L3 retrait couvert, Heavy paume traversante.
- Routes, aériens, lancer de shuriken réel et contre-paume.
- Jutsu joués par le corps : Read, Ombre des shuriken, Mirage, Katon (un signe, Channel 0,3 s au lieu de 0,55 s), Phénix.
- Intro immobile, victoire sobre, focalisation Sharingan.
- Réactions, garde, chutes et esquives : clips partagés de Sasuke par alias (`AuthoredMotion.ALIAS`), en attendant des réactions propres.
- Contrôle Studio : 0 erreur.
**Priorité (28/10, nuit) : fluidité de la vidéo de référence** — [DEC-029](DECISIONS.md#dec-029--cible-de-fluidité--la-vidéo-de-référence-de-lutilisateur-2810). Fait : vitesse des articulations plafonnée et transitions plus longues ; traînées de corps et traits de vitesse au-delà d’un sprint et sur les téléports (`Client/MotionSmear`) ; arcs fins mains/pieds pendant les frappes ; la frappe garde l’élan ; caméra proche derrière l’épaule. Studio, IA contre IA 45 s : 1 saut > 40°/image, 0 > 60° (round précédent aux vraies touches, 75 s : 94 et 23). Puis (12 h 08, « pas de différence ») : chaîne kunai de Sasuke animée pose par pose dans Blender, plus amplifiée (Light1 dégainé-taillé, Light2 revers en passant le pied, Light3 taille tournoyante, Heavy salto avant + taille vers le bas) ; kunai en main pendant ces coups. À jouer : `Documents/Roblox/ND-Kunai1.rbxlx`. Verdict humain PENDING.

**Mission en cours (27/10) : Animation Mastery + Combat Breakthrough** — [DEC-028](DECISIONS.md#dec-028--animation-de-production-dans-blender-puis-maîtrise-réelle-du-métier), ANIM-001…006, [gate](../reports/animation-mastery-2026-10-27/GATE.md). Fait : rig d'animateur dans Blender (pieds IK monde, pôles de genou, retarget exact) ; Sasuke et Minato réécrits pose par pose (locomotion complète, taijutsu, lancers, Katon, Chidori, FTG, Rasengan) `8e664a8` ; moteur : transitions inertialisées, frappes en course sur les jambes de la course, pieds plantés tenus au sol `36be268`. 31 suites + release PASS. Studio aux vraies touches : course→frappe, Chidori formé→course→estoc, FTG→Rasengan, 0 erreur. Pass 2 (28/10) : bug des marqueurs corrigé (les coups jouaient après le contact serveur), réactions et défense réécrites pose par pose, pieds tenus sous les coups, sprint sans retournement du genou ; rounds réels 60–90 s VFX activés et coupés, sauts > 60°/frame divisés par deux ([gate](../reports/animation-mastery-2026-10-27/GATE.md)). À jouer : `Documents/Roblox/ND-Anim5.rbxlx`. Reste : verdict humain, quelques à-coups (arrivée FTG, départ de course, Light3 de Minato).

**Bloquant actif (26/10) : VISUAL CONTINUITY BLOCKER** — [brief](../archive/requests/2026-10-26-visual-continuity-blocker-latest-capture.md) : ordre caméra → décollage/air/réception → passage de pose → facing/poursuite magnétiques → contact → relevé → occlusion. Fait : 1. caméra — l'objectif ne traverse plus le mur (la « Boundary cap » était traitée comme un accessoire à estomper ; contrôle final après lissage et secousse, décalage suivant la normale, poussée hors des surfaces à moins de 1,1 stud) ; Studio 50 s de combat collé au mur : 0 image à moins d'un stud de la paroi. 2/4 (partiel) — une frappe sortie ne pivote presque plus (160°/s, 480°/s au départ ; rien vers un corps passé derrière) ; la poursuite vise le point d'interception et ne le corrige qu'à 60 studs/s (fin de la « colle » en l'air) ; le saut du Lion Combo et des lotus est un bond, plus une téléportation. Restent : anticipation du décollage, réception, passages de pose, contact.

**Priorité active (26/10) : STOP ABSTRACT EXPANSION — VISIBLE RUPTURE** — [brief](../archive/requests/2026-10-26-stop-abstract-expansion-visible-rupture.md) (déplacé sous archive/requests : `docs/active` n'accepte que les sept documents canoniques). Plus de nouvelle couche abstraite ; livrable : un combat libre Sasuke–Minato de 60–90 s en Studio visiblement différent. En cours : arène dégagée au centre (poteaux/pierres retirés, rochers en couronne), IA qui rompt l'échange après 1–2 coups et se repositionne, Chidori tenu en main (état du corps) libéré au sol / en l'air / depuis un mur.

**Mission en cours (25/10 soir) : Ninja Embodiment** — [DEC-027](DECISIONS.md#dec-027--ninja-embodiment--le-joueur-devient-le-ninja), briefs sous archive/requests. Audit Studio de départ fait ([rapport](../reports/ninja-embodiment-2026-10-25/AUDIT.md)) : grammaire universelle 68–93 % des frappes, victime verrouillée 22–49 % du temps, aucun usage de mur, Boxer Test FAIL. Travail : EMB-001…004, SYS-001/002. Lots : `db6caf7` résolveur contextuel + agence du défenseur (verrou Lee 49 → 16 %, frappes universelles encore 66–88 %) ; lot 2 monde réactif (EMB-004, [progression](../reports/ninja-embodiment-2026-10-25/PROGRESS.md)) ; lot 3 perception de l'espace (situation « mur », l'IA amène le combat vers le décor, poteaux et pierres au centre) — le vocabulaire de frappe reste majoritairement partagé.

**Mission en cours (25/10) : Combat Convergence Breakthrough** — brief [2026-10-25-combat-convergence-breakthrough](../archive/requests/2026-10-25-combat-convergence-breakthrough.md) (sous archive/requests : `docs/active` n'accepte que les sept documents canoniques). [Rapport d'étape](../reports/combat-convergence-2026-10-25/REPORT.md), cinq lots : `e3b2932` réactions du défenseur, frappes engagées, rotations bornées, objets lancés depuis la main (vu en planches Studio) ; `8bbf439` identité dans l'échange + réaction tenue entre deux coups ; `1758922` corps projetés posés sur le vrai sol puis dérapage (relevé 8,3→0,1 stud ; le harness a maintenant le sol de Studio) ; `01388bd` plus de corps fusionnés (frames sous 2 studs : 13–24 → 0 par combat IA de 20 s) ; `307f731` whiff qui emporte le corps. Lots 2–5 mesurés côté serveur en Studio, **pas encore vus à l'écran** (client sans rendu, écran en veille) : combats A–E à vitesse normale PENDING, pas de verdict de rupture.

**Checkpoint Claude 25/10 : Movement Overhaul, passes 2–4 (Studio).** Rapport §23 : [movement-overhaul-2026-10-25](../reports/movement-overhaul-2026-10-25/REPORT.md). TECHNICAL PASS (29 suites, Movement 17 dont 2 contrôles par mutation). NATIVE_STUDIO PASS mesuré : route continue §20 en une prise pour Lee, Sasuke, Zabuza, Gaara (stick serveur) + vraies entrées pour saut/Light aérien, frappes en course, esquive en sprint ; murs horizontal/vertical, wall-jump tangentiel, poursuite → combo aérien sans pause, esquives qui tournent à chaque fois (bug d'horloge corrigé), sprint et traînée de dash par fighter. HUMAN_VISUAL/FEEL PENDING. Restes : départ de Zabuza à peine plus lent, Haku/Bee non rejoués en Studio, pas d'audit dédié du glissement des pieds.

**Checkpoint Claude 24/10 (soir) : Movement Overhaul, passe 1 (brief 2026-10-24, vidéos regardées).** Carte observé→principe→état→adaptation dans [MOVEMENT_OVERHAUL_AUDIT](../movement/MOVEMENT_OVERHAUL_AUDIT.md). Corps : acrobaties choisies par le contexte et le niveau `ACRO` de chaque fighter (salto arrière sur saut arrière lancé, salto latéral sur saut de côté lancé, salto avant sur un saut sprinté enchaîné — jamais deux de suite, salto en quittant un mur, roue / flip arrière en esquive pour les plus acrobates), annulées par toute action engagée, réception ninja accroupie bras écartés. Serveur : l'esquive rend son élan à la sortie (plus d'arrêt net). Tests : 29 suites PASS dont Movement (9, avec contrôle négatif). Studio non fait ; suite du brief (course plus basse, attaques aériennes qui gardent l'élan, murs, caméra) à venir.

**Checkpoint Claude 24/10 : lot L4-A Kimimaro + Haku (bibles KIMIMARO.md, HAKU.md), headless seulement.** Kimimaro : corps propre (phalanges, coude, circulaire, Heavy coudes croisés ; routes BoneRise / CamelliaArc / BoneReap qui recule ; riposte BoneElbow ; air genou + talon) et os qui naissent au membre avant le contact puis se rétractent (Wave1FX) ; plus de lame claire en garde. Haku : corps propre (senbon oblique, paume + pic de poignet, senbon de sortie, Heavy sur pic ; routes FrostLift / IceSlide / SenbonLow qui recule ; riposte SenbonStab ; air SenbonDive), senbon aux doigts et plaque de glace sous la glisse. Plus de lourd-après-un : le Heavy reste le même geste. Tests : 28 suites PASS. Studio non fait.

**Passe R15 commun Codex, base `b445df5` (18/10) :** contre-mouvement en strafe, continuité du pied en sortie de course, reset des anciens appuis et équilibre latéral. Un module client, trois régressions, 28 suites PASS par build et neuf tests isolation PASS. Comparaison native avant/après et parcours réel partiel ; acceptation feel/manette non close. [Rapport et limites](../archive/reports/r15-common-2026-10-18/REPORT.md). Passe préparée sur `codex/ninja-r15-common-pass` depuis le HEAD Claude, sans remplacer ses lots ; statuts MOV conservés.

**Checkpoint Claude 18/10 (14 h 30) : lot L7-B Killer Bee (bible KILLER_BEE.md), headless seulement.** Corps propre `Client/Wave3Motion` (trois prises visibles : main, coude, genou ; Heavy X ; routes ↑ BladeLift / ←→ BladeSwap / ↓ KneeKick qui recule ; riposte ElbowCut ; air : finisher X, BladeFall) ; sept lames et leurs configurations dans `Wave3FX` (présentation seule, un seul contact serveur) ; timings/portées de la bible via AttackProfile ; plus de lourd-après-un (le Heavy reste le X). Lariat, encre et tentacule conservés. Tests : suite complète PASS. **Studio** : garde (lame droite pointe basse, sept fourreaux dans le dos), L1 montante, L2 au coude, Heavy en X qui projette vus de profil ; gate native Q:Ink et Q:Mist PASS, 0 erreur. Reste à voir : la lame de genou en L3 (non captée aux clics) ; à refaire sur ND-Debug-bee (pose de garde, lame de coude/genou visibles, rien ne traverse le torse).

# État vérifié — audit incrémental combat du 18 octobre 2026

**Checkpoint Claude 18/10 (après-midi) : lot L7-A Zabuza (bible ZABUZA.md).** Corps propre : `Client/Wave1Motion` (L1 manche dans le sternum, L2 arc horizontal de hanche, L3 revers qui freine, Heavy chargé à l'épaule en diagonale pointe au sol, ↑ montée de hanche, ↓ coupe basse qui recule, ←→ arc qui couvre le flanc, air, Silent Killing) ; timings/portées de la bible via AttackProfile ; riposte au manche sur garde tenue (MoveGraphs.riposte, plus de lourd-après-un) ; garde propre via un hook générique `guard` du moteur (aucun `if fighterId`) ; couperet tenu tout le duel, lame dans le prolongement de l'avant-bras (Wave1FX). Tests : suite complète PASS (test Roster20 Zabuza). Studio Mac (Debug, clics réels vs Lee figé) : pointe basse en garde, L2/L3/Heavy lisibles comme arc/revers/diagonale, Heavy projette. Non vérifiés : HUD masqué par un humain, manette, ressenti. Suivant : L7-B Killer Bee (multi-lames).

**Checkpoint Claude 18/10 (midi) : roster cible DEC-026 dans le menu (17+3).** Brouillon Wave4 (ND-Debug-new3, jamais commité) fusionné sur le HEAD en conservant la passe R15 de Codex : Madara `Rival`, Hashirama `Sapling`, Hiruzen `Professor` (fiches *_CHILD), crochets génériques `MoveGraphs.riposte` / `Awakening.Riposte` / Counter `Move` / Attacks `retreat` ; Hinata, Temari, Kabuto hors menu (code conservé). Gate durcie (audit Codex F1/F3 : contrats obligatoires, contrôles négatifs NEG1/NEG2 qui doivent échouer, S20 exige le coup après fermeture). Défaut de jeu trouvé en natif et corrigé : le cône d'un Katon court (Arc) suivait l'auto-facing pendant l'incantation et brûlait un corps qui avait esquivé de côté — direction désormais figée à la pression. Tests : 28 suites PASS. Studio Mac (Debug) : menu à 20 vu, Madara et Hiruzen choisis à la souris et joués aux vraies touches (Madara : 3 légers au sabre, 30 dégâts) ; gate NEW + M7 natives — les trois nouveaux PASS sur séquence et contrôles de corps (routes propres, riposte, contre qui frappe, Katon devant 9 / flanc 0) ; NEG1/NEG2 échouent comme attendu ; voir le commit pour la passe finale des vingt. Non vérifiés : manette, ressenti humain, contre-jeu joué par un humain.

**Passe R15 Codex autorisée directement par l’utilisateur, base1792c40 :** réceptions indépendantes par acteur, compression/relâchement progressifs et cadence murale liée au déplacement dessiné. Deux modules client, aucun serveur/kit/graphe modifié. Trois builds reconstruits :28suites/511cas PASS chacun, neuf tests isolation PASS. Debug final ouvert séparément dans Studio, fingerprint vérifié ; clavier/souris, saut et mur observés. [Preuves et limites](../archive/reports/r15-2026-10-18/REPORT.md). MOV-005 reste IN_PROGRESS ; aucun PASS global du feel/des vingt identités. Brouillon Wave4 de Claude préservé.

**Audit Codex de `5bb52fd..aeff49a` :** M5/M6 cohérents ; clôture M7 à fiabiliser (verdict accepte séquences ratées), QA source périmée. 28 suites/508 cas + neuf tests isolation PASS ; MCP Studio connecté, logs M7 lus et S20 rejoué (3.0 dégâts après fermeture). [Preuves, portée et limites](../archive/audits/2026-10-18-5bb52fd-aeff49a/AUDIT.md). Aucun nouveau PASS feel/visuel ; les anciens constats ci-dessous restent datés.

**Checkpoint Claude 18/10 (nuit), après l'audit Codex : M1→M7 de QA-004 livrés ; bloc combat clos côté technique, rapport/synchronisation avant le bloc suivant (DEC-021).** M7 `7ebcb6a` : une séquence continue par fighter (chaîne→route→E→air→outil→chaque jutsu→garde→KO→round propre), Studio natif **20/20 PASS**, 0 erreur ([rapport](../archive/reports/convergence4/M7_GATE.md)) ; pas une partie aux vraies touches pour les vingt, ni manette, ni ressenti humain. `41364ed` M1 (marionnette persistante rendue à son contrôleur, venin jamais à travers une garde), `e0b9e6d` M2 (zones/charges bornées à Range et aux murs ; téléport non suivi hors portée/vue au release : fizzle, chakra dépensé, cooldown 0,8 s), `ba39455` M3 (un contrat de brume : ni snap/lead jutsu-outil, ni caméra qui suit, bot sur mémoire `fogAim`), `5bb52fd` M4 (grille fiable : push depuis le contact, colonne react, casts distincts par `Cast:<Id>` ; [baseline](../archive/reports/convergence4/M4_BASELINE.md)), `0f09fbc` M5 (charges posé/armé dans le snapshot et la mèche ; fenêtre Absorb visible, fermeture lisible), `0485027` M6 lot 1 (hitstop selon la nature du coup pour les routes/lourds propres ; arc du couperet). Tests : 28 suites PASS (Convergence 14 cas). Studio Mac (Debug, `DevGateCheck` lancé par `workspace:SetAttribute("NinjaDuelGate","M1,M2")`, pipeline serveur natif) : S1–S6, S8, S10, S11, S12, S15–S18, S20 PASS, 0 erreur Output ; vraies touches : marionnette de Sasori portant 2 coups puis toujours à son poste (vu), trois légers de Zabuza avec le couperet en main et son arc (vu), sphère d'Absorb vue. Non natifs : S7/S9 (murs/vue), S13/S14, S19, S21 complet, S23/S24 ; caméra dans la brume en mouvement non capturée ; manette et ressenti humain PENDING.

**Source auditée : `aeff49a7b6ebbfef24068e25e2726b9febffff04`, branche réelle `claude/ninja-duel-2026-10-14`, disponible sur GitHub.** Recontrôler le HEAD avant reprise. Le vieux main local n'est pas autoritaire. [Delta vérifié et preuves](../archive/audits/2026-10-18-feel-preparation/AUDIT.md).

**Build :20anciensIDs câblés. Cible DEC-026 :20prodiges,17conservés +3nouveaux absents.** Les anciens P1 et lacunes d’identité ont reçu des corrections/règles réelles. Le classement 2PASS/8WEAK du17/10 reste historique, pas nouvel état automatiquement reconduit. Gate native complète et feel humain non clos. Diagnostic : [ENGINEERING_REVIEW](ENGINEERING_REVIEW.md) ; petits commits ordonnés dans QA-004 de [MASTER_BACKLOG](MASTER_BACKLOG.md).

| Domaine | Fait au checkpoint | Preuve et limite |
|---|---|---|
| Roster / sélection | Liste runtime de vingt IDs uniques, tous intégrés aux définitions/attaques/graphes/motions/familles | Headless exact HEAD ; preuves natives du17/10 : menu vingt, Haku choisi à la souris et dix nouveaux rejoués via Debug. Au18/10, seulement le delta ciblé est rejoué sur le nouvel artefact ; sélection complète finale encore à prouver. |
| Combat Bibles V1 | Vingt bibles de design au18/10 :17cibles présentes, Madara/Hashirama/Hiruzen absents ; Hinata/Temari/Kabuto retirés de la cible, pas du runtime | [Index/A–E](../characters/ROSTER_20.md), DEC-026.12rubriques de chorégraphie + réemploi/uniques/priorité/gaps/lots. Aucun nouveau geste codé ni PASS Studio de ces cibles. |
| Tests | **28 suites /511 cas PASS** sur la passe R15 base1792c40 | Lune0.10.5/Luau0.743 ; Convergence14cas, Animation17cas ; neuf tests Python d’isolation PASS. Gates roster préservées. Pas de nouveau rejeu des180 sondes de l’audit précédent revendiqué. |
| Réserves actuelles du delta | Verdict M7 non fiable, assert S20 incomplet, QA ancien DevGateCheck | Audit ciblé 5bb52fd..aeff49a lié en tête ; M1–M3 livrés avant cette plage, pas rouverts depuis les anciennes sondes. |
| Identité / éveils | ChainTeleport, Ring/ZoneFree, charges/Katsu/ChainCharges, Absorb/ReflectClear, marionnette persistante et cleaver/shroud implémentés | Convergence/roster PASS ; détails et bornes natives dans l’audit incrémental. Les quatre éveils ne sont plus uniquement numériques. |
| Studio Codex | MCP connecté au Debug M7 en Play ; logs Claude lus et S20 rejoué par attribut DevHooks | Fingerprint2dc36969…0502d2 conforme au manifest Debug. S20 absorption/mêlée/fermeture PASS, kunai après fermeture3.0 dégâts. Les logs M7 comportent une première passe avec faux positifs, puis vingt lignes cohérentes ; verdict automatique à durcir. Aucun nouveau PASS feel/manette/visuel. |
| IA / anciens | Rotation de slots par famille et opportunités ajoutées ; suites anciennes PASS | Grille20 vsLeaf seed unique15–33s ; push/distincts à corriger avant retuning. Aucun nouveau crash ancien reproduit. |
| CORE4, Gaara, Lee | Combat et premières preuves Studio historiques ; qualité/feel non clos | [Bilan convergence 2](../archive/reports/convergence2/FINAL_REPORT.md). Ancien menu six, routes, dash et certains effets observés le 16 octobre ; pas acceptation globale de l’artefact courant. |
| Naruto / corps secondaires | **NATIVE_STUDIO partiel (17/10)** | Merge `caef06f`, `Bodies`, `BodyViews`, `Legion`, `NarutoFX`. Claude, Debug `dd5fa46`, `tools/studio/fighter_check.py` (vraies touches/souris) : chaîne L1→L2→L3, route vers l'avant = UzumakiKick, frappe aérienne, Shadow Clone (clone apparu, trois jabs), Rasengan façonné par un clone (touché), Multi Shadow Clone (deux clones, six jabs), éveil (clones dissipés) ; clones et fumée vus à l'image. Restent : contre-jeu côté adversaire (viser un clone), échange par substitution, kunai transformé, coût client, feel humain. |
| Temari / zones de vent | **NATIVE_STUDIO partiel (17/10)** | Merge `26c2526`, `Zones`, `Gale`, `GaleFX/GaleMotion`. Claude, Debug `dd5fa46`, fighter_check : chaîne, route Updraft, frappe aérienne, Gust (poussée), Kamaitachi, Great Gust, Rising Whirlwind (touchés), éveil Kamatari. Défaut vu : couloir dessiné comme une dalle translucide au sol → remplacé par de la poussière entraînée (`69808f4`), **pas encore revu à l'image**. Restent : vent contre projectiles/dash, plané, IA zoneuse en duel, feel. |
| Identité CORE4, couche récente | **NATIVE_STUDIO partiel (17/10)** | Merge `b25d230`, `IdentityFX`, [rapport](../archive/reports/convergence3/CORE4_IDENTITY.md). Vu le 17/10 : empreinte de paume de Neji (image figée) ; passe fighter_check complète de Minato (chaîne, launcher, air, les cinq techniques résolues, éveil). Passe d'Itachi interrompue (pont MCP injoignable en cours de route ; étapes suivantes non fiables) ; Sasuke, Neji, Gaara, Lee non rejoués sur ce HEAD. Points, sceaux, Read, marque/Chidori en mouvement : PENDING. |
| Chakra, couche récente | **IMPLEMENTED / NOT YET STUDIO-VALIDATED** | Merge `738b449`, `ChakraFX`, fil-objet/conduction/repères, [rapport](../archive/reports/convergence3/CHAKRA_PLAYER_LAYER.md). Rapport headless ; les anciennes observations du kunai de vent ne valident pas cette nouvelle couche. |
| Mouvement, réactions, caméra | Implémentés, validation partielle historique | [Mesures natives](../archive/reports/convergence/VISUAL_AUDIT.md), [contact](../archive/reports/convergence/CONTACT_AND_REACTIONS.md). Quelques défauts corrigés au fil des passes ; aucune garantie de feel final. |
| Stade | Recomposition récente vers une enceinte Chūnin | `ccd1629` ; nouvelles proportions à confronter au parcours, murs/corniches, caméra et IA dans Studio. |
| Online | Fondation serveur intégrée ; produit online non validé | [Rapport](../archive/reports/ONLINE_FOUNDATION.md) : queue casual et codes **par serveur**, sélection, duel deux humains, rematch/forfait. Deux clients/latence non prouvés ; aucune preuve de session Roblox publiée. Départ = forfait, rejoin = nouvelle session (pas de reprise transparente). |
| Progression | Fondation CORE4 intégrée ; intégration joueur incomplète | [Rapport](../archive/reports/PROGRESSION_FOUNDATION.md) et [formats](../systems/PROGRESSION.md) : arbres, validation de builds et budgets ; pas UI ni persistance réelle branchée prouvées. Budgets présents 50/80/100/120+ : faits du code, pas arbitrage économique final. |
| Inputs | Clavier/PS5 testés techniquement ; clavier réel historiquement joué | Manette physique et feel encore PENDING ; ne pas inférer l’ergonomie d’un callback. |
| IA | Combat et réponses spécifiques intégrés | Stress tests historiques headless ; utilisation complète du stade/pièges et diversité en natif restent partielles. |
| Motion Lab/outils | Lab et diagnostics intégrés, isolés du normal | Tests/smokes historiques ; disponibilité et QA de la session à revérifier selon EXECUTION_RULES. |
| Publication | **NON VÉRIFIÉE** | Pas de PlaceID/version/URL ni test live probant dans les sources examinées. L’absence de preuve ne prouve pas une impossibilité du compte. |


Artefact Debug courant SHA256 `cc2e33d505d55f5cb89908819153896c0ea48beda8f07d6ddbbe7ef6958d295d`, fingerprint `ea3b2dc525073dbc3167811a752c7a6333ab765dcafa74224e1293592dfe765b` relu dans la session finale R15 NinjaDuel-Debug.rbxlx. Normal/Debug concordent avec les hashes source du HEAD ; QA reconstruit par la passe R15 : ancien écart DevGateCheck (F2) résolu ; assertions M7/S20 toujours à corriger. Aucun build modifié par Codex.

Les preuves historiques des autres domaines ci-dessus restent datées : aucune revalidation globale implicite. Correctif harness de déplacement intégré avant les trois lots ; anciennes statistiques de duels non directement comparables. Risques antérieurs conservés : clones/décor et coût client, asymétrie des sièges/gigue, HUD chakra, IA/hazards. Les constats préparatoires d'autres systèmes restent dans leurs documents spécialisés et tickets ; ils ne changent pas la fenêtre d'exécution DEC-021.

État antérieur complet : [snapshot conservé](../archive/audits/2026-10-17-roster20/before-active/CURRENT_STATE.md). Le présent fichier possède les faits actuels ; le rapport possède seulement les preuves datées.
