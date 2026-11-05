# NINJA DUEL — RUNBOOK DE TOURNAGE CM (STUDIO -> FILM -> QC)
05/11/2026. Branch: media-clips. Companion direct de CM_THREE_SERIES_PRODUCTION_BIBLE_2026-11-05.md et PRODUCTION_FILM_01_THE_KUNAI_WAS_BAIT.md.

**C'est une procédure de tournage exécutable, PAS un nouveau brainstorming.** L'utilisateur refuse les vidéos de gameplay brut mal cadrées et les montages qui cachent des bugs. La règle : PREUVE DES ACTIONS -> CAMERA -> PRISE -> INSPECTION ANTI-BUGS -> MONTAGE -> RE-INSPECTION -> APPROBATION UTILISATEUR. Si une vraie action donne un rendu mauvais, on REFAIT la prise ou on change une scène ; on ne camoufle pas un bug avec des flashs.

## 0. Ce qui existe et ce qui reste à vérifier
La branche jeu claude/ninja-duel-2026-10-14 contient un environnement Studio Debug/QA avec NinjaDuelDev, commandes start/act/place/refill/scripted/freezeBot/state, le panneau F6 et les outils de diagnostic. La branche media-clips est UNIQUEMENT dédiée aux médias, pas aux systèmes du jeu.

Le kit CM ci-joint :
- cm_tools/NDCM_DIRECTED_TAKES.server.luau : prépare Minato-Neji en Studio Debug, lance un vrai kunai marqué, contrôle si une marque existe, déclenche le FTG, une frappe et la Rotation ; variantes mark, itachi_mirage et neji_rotation.
- cm_tools/NDCM_CAMERA_PRESETS.client.luau : caméra Studio Client avec 5 presets wide, threequarter, low, portrait et impact, et fonction de restauration. C'est un outil de tournage local, pas une modification permanente de Camera.luau.
- cm_tools/video_qc.py : analyse technique de clips avec FFmpeg, fabrique des planches-contact et signale des noirs/freezes suspects ; **ne détecte pas** membres tordus, VFX mal attachés, faux coups ou mauvais cadrage.

**Ces 2 nouveaux scripts Luau sont préparés d'après le code actuel MAIS PAS ENCORE TESTÉS en Studio.** Premier devoir du CM : essayer les outils, corriger les erreurs du kit LOCAL si nécessaire et obtenir une preuve OBS de leur fonctionnement. Ne pas déclarer PRE-FLIGHT PASS avant de l'avoir fait. La V36 est la dernière version publiée documentée au début du travail ; les V37–V39 sont des versions test. Reconsulter CURRENT_STATE avant toute promo publique.

## 1. Mise en place pas à pas : plus besoin de diriger un duel au hasard
1. Ouvrir le HEAD de la branche gameplay, lancer son build Debug selon games/ninja-duel/docs/tools/DEVTOOLS.md et ouvrir le fichier NinjaDuel-Debug.rbxlx créé par le build. La place Normal n'a pas les DevHooks de tournage.
2. Dans Studio, Test > Play (F5). Attendre que l'expérience ait chargé. Pour la première vidéo, **un joueur + bot réel** suffit ; ne pas essayer de monter un serveur multiclient inutilement. Le test Studio Server & Clients (F7) est disponible si une scène exige deux joueurs réellement pilotés (doc officielle : https://create.roblox.com/docs/studio/testing-modes).
3. Dans la Command Bar positionnée côté SERVER, exécuter le texte du fichier cm_tools/NDCM_DIRECTED_TAKES.server.luau. Modifier seulement la ligne SCENE au début (preflight, mark, teleport_counter, itachi_mirage, neji_rotation). Lire Output : si NinjaDuelDev est absent, mauvais build OU mauvais contexte. Le script a un délai LEAD de 4 sec avant action : monter à 7–8 sec si besoin d'ouvrir OBS et de revenir dans la fenêtre de capture.
4. Dans la Command Bar positionnée côté CLIENT, exécuter cm_tools/NDCM_CAMERA_PRESETS.client.luau et choisir au début PRESET = "threequarter" ou "wide" / "low" / "portrait" / "impact". La caméra suit les modèles du duel ; elle s'arrête proprement avec shared.CM_CAMERA_STOP(). Si Players.LocalPlayer vaut nil, tu n'es pas sur le Client. Si le bot n'est pas trouvé par le script, essayer la Freecam officielle avant d'enregistrer : Shift gauche+P dans la session Play, propriétaire/éditeur autorisé (https://create.roblox.com/docs/workspace/camera/free-camera).
5. Dans OBS, ajouter une source de capture de la fenêtre du CLIENT Studio/Roblox, pas l'interface code/Output. Enregistrer 6–10 sec pour vérifier cadrage, HUD, son, fps et netteté. Réglages de départ : 1920x1080 ou plus en capture, 60 fps SI réellement fluide (sinon 30 constants), MKV puis OBS File > Remux Recordings vers MP4. Guide : https://obsproject.com/kb/standard-recording-output-guide.
6. Préparer 2 dossiers distincts : PROOF (une prise continue normale HUD ON montrant les vraies actions) et CINEMA (prises dirigées en Debug avec HUD caché, pour la pub). **Les prises cinématiques ne sont pas une preuve de PvP humain, ni des images de la version LIVE publiée.** Étiqueter la version.
7. Tester un crop 9:16 au téléphone avant les longues prises. Si les deux personnages sortent de l'écran vertical, changer l'axe caméra pour qu'ils soient **dans la profondeur**, pas aux deux extrêmes d'un large écran horizontal.

**Principe de production** : l'IA adverse est figée uniquement pendant la préparation et les prises dirigées ; les actions du moteur sont réelles. Le CM n'a plus à réussir trois actions complexes et un mouvement de caméra simultanément. Faire 2 prises par angle ; monter les meilleurs extraits de 0,5 à 3 s. Ne pas recourir à une chorégraphie scriptée de fausses dégâts.

## 2. Priorité A — NINJA IQ : The Kunai Was Bait (Minato vs Neji)
Un micro-film de 17,5 secondes, 8 plans. Les temps ci-dessous sont ceux du MONTAGE FINAL, non ceux de la console Studio.

A (0.00–1.15, HOOK) : caméra LOW, SCENE = mark. Capturer une marque de kunai réellement plantée au sol dans le même cadre que Neji ; si la lame n'est pas visible ou flotte dans le sol, REJECT. Au montage, démarrer DIRECT sur la marque, texte HE MISSED? au premier instant, son métallique sec. Éviter logo/introduction.

B (1.15–3.70, THROW) : caméra WIDE ou THREEQUARTER, SCENE = preflight. Capturer le mouvement complet de Minato lançant un vrai kunai marqué. Les deux silhouettes + trajectoire doivent être dans le recadrage vertical. REJECT si la main est tordue, le projectile sort d'un mauvais point ou il n'y a pas de lancer lisible. Couper sur le geste du bras.

C (3.70–5.60, BAIT) : caméra THREEQUARTER, une autre prise de preflight. Neji au premier plan ; la marque sur le côté ; Minato encore au loin. Si le bot est figé, NE PAS prétendre qu'il a avancé. Un léger zoom 2–4 % dans CapCut suffit. Le spectateur doit comprendre où le kunai a atterri.

D (5.60–8.20, REVEAL) : caméra THREEQUARTER, SCENE = preflight, vrai FTG vers une marque plantée et non une destination inventée. Monter un cut sur disparition/réapparition. Revoir à 0,25x : corps poppe-t-il dans un mur ? pose cassée ? réapparition bien près de Neji ? si oui problème -> REJECT, pas de flash blanc pour le cacher. Le runner affiche la distance d'arrivée et les refus d'action.

E (8.20–10.25, ATTACK) : caméra IMPACT, reprise de la même combinaison. **FTG ne fait pas de dégâts en soi** : filmer un vrai Attack APRES l'arrivée ; vérifier action acceptée, posture, contact. Si Attack a été refusée ou touche visuellement sans contact réel, REJECT. Monter un punch-in très léger, pas de zoom qui cache les jambes.

F (10.25–13.10, TWIST) : caméra WIDE ou THREEQUARTER. Filmer **une Rotation de Neji qui intercepte effectivement le coup** : la commande bot Technique3 n'est PAS une preuve d'un contre réussi. L'animation de Rotation seule peut être capturée par SCENE = neji_rotation pour un teaser de VFX, mais elle ne peut pas être intercalée mensongèrement comme si elle avait paré la frappe. Si le timing échoue : reprendre, ajuster les délais dans le script après diagnostic, OU tourner le final honnête (cliffhanger sans contre). Petit silence avant le son de choc, léger ralenti seulement s'il reste fluide.

G (13.10–15.20, PAYOFF) : caméra WIDE, les combattants visibles après l'action. Texte NEJI SAW IT uniquement si le contre est réellement visible et prouvé. Si cela ne se produit pas, texte WOULD YOU HAVE SEEN IT? et couper plus tôt.

H (15.20–17.50, CTA) : plan réel propre de l'arène, logo exact Ninja Duel, PLAY ON ROBLOX seulement pour la version effectivement jouable, sinon IN DEVELOPMENT. Pas d'images d'anime officielles ni fausse capture. Texte final WOULD YOU COUNTER IT?

**Prises minimales concrètes A1** : une preuve continue HUD ON, puis 2 prises MARK en LOW, 2 PREFLIGHT en WIDE, 2 PREFLIGHT en THREEQUARTER, 2 PREFLIGHT en IMPACT. Cela fournit tous les angles sans 8 scripts différents. Réutiliser seulement les takes visuellement acceptées.

**Si le runner CM échoue** : utiliser les commandes existantes sur la SERVER Command Bar dans un test Debug. Procédure : dev = game.ServerStorage.NinjaDuelDev ; dev:Invoke("start","Flashstep","GentleFist",true) ; attendre state.phase == "Duel" ; dev:Invoke("scripted",true) ; dev:Invoke("freezeBot",true) ; dev:Invoke("place",Vector3.new(0,3,8),Vector3.new(0,3,-7)) ; dev:Invoke("refill") ; contrôler state.bot.position ; dev:Invoke("act","human","Technique1",state.bot.position+Vector3.new(3,-2,0)) ; attendre collision et state.human.seals > 0 ; puis dev:Invoke("act","human","Technique3"). Contrôler chaque réponse ok/reason et le rendu. Ces commandes agissent dans **Studio Debug uniquement**, pas dans la release.

## 3. Série B — PRODIGY FILES : Itachi / You Didn't Hit Him
Pilote de 16 secondes. Une fiche premium ne doit pas devenir un diaporama ni remplacer la preuve de gameplay par un beau fan art.

0.0–1.4 : dans Studio EDIT, cadrer Itachi modèle du JEU avec vue 3/4, éclairage latéral, fond propre. Exporter portrait PNG ou capturer depuis Studio ; visage, cheveux, épaules propres. Dans Photopea/Figma, fond encre noir/charbon et un accent rouge. Si c'est un concept/asset non intégré, label CONCEPT ART.

1.4–3.5 : révéler silhouette + nom ITACHI, animation 2 keyframes seulement (translation légère + opacité) ; pas de chromatic aberration ou effet de distorsion agressif. Gros plan digne d'un personnage qu'on voudrait sélectionner.

3.5–5.3 : 3 mots sur le visuel dossier : READ / DECEIVE / PUNISH ; ce sont des INTENTIONS, non des 3 pouvoirs inventés. Un beat par mot ; laisser 0,7 s pour lire.

5.3–8.1 : capturer le vrai MirageCast dans Debug : SCENE = itachi_mirage, caméra THREEQUARTER, personnage Itachi/Mirage contre Kakashi/Copycat. Si l'illusion est illisible/buggée, refaire l'angle ou choisir un geste alternatif vraiment filmé, sans prétendre une attaque sur clone qui n'a pas eu lieu.

8.1–11.0 : seconde scène de gameplay réelle : outil shuriken ou Technique1 d'Itachi (Shadow Shuriken) avec vraie demande du moteur et prise OBS ; se rapprocher du bras et laisser visible direction des projectiles. Le runner ne programme PAS automatiquement ce deuxième geste : exécuter l'attaque et vérifier acceptation/cooldowns puis enregistrer. Ne pas ajouter un shuriken virtuel au montage.

11.0–13.7 : retour au portrait Studio, trait rouge de composition qui relie les deux clips au style de fiche, révélation OUTPLAY. DON'T OUTSPAM.

13.7–16.0 : titre Ninja Duel, WOULD YOU MAIN HIM? et statut CONCEPT/IN-ENGINE/ACTUAL GAMEPLAY correct selon la provenance.

**Vérifications B** : modèle strictement cohérent avec le jeu, aucune tenue fictive, pas de Mangekyo/corbeaux non filmés, la main et les shuriken synchronisés, 9:16 lisible en muet. Si le clip réel n'est pas assez joli, pas de « fake AI animation » pour maquiller. Changer le mouvement choisi ou attendre une vraie passe d'animation.

## 4. Série C — BUILDING THE IMPOSSIBLE : The Camera Was Fighting Us
Pilote 29–32 secondes. Le devlog le plus crédible a un AVANT authentique et un APRÈS mesurable.

0–2 : ouvrir sur un vrai ancien clip où la caméra perd l'ennemi près d'un mur ; texte OUR CAMERA WAS RUINING THE FIGHTS. **Ne pas recréer volontairement un faux bug**.

2–6 : garder la scène 1–2 s supplémentaires, entourer simplement la zone où le rival disparaît (petit cercle/trait rouge), garder le son du jeu et le mouvement.

6–10 : vraie prise de Studio montrant le travail sur la caméra, deux inserts de 1–2 s maximum (script Camera.luau, test de scène, panneau Studio), pas du faux code.

10–15 : split BEFORE V38 / AFTER V39 TEST uniquement SI le CM dispose effectivement des deux builds/anciens rushes datés ; même paire, même distance et angle, même type de mouvement. Mettre les versions dans le cadre, sans laisser croire que V39 est déjà LIVE.

15–23 : nouvelle caméra avec mouvement réel, wall jump ou duel complet de quelques secondes, sans motion blur/flash ajouté pour cacher un nouveau bug. S'il reste des bascules ou clipping, REFUSER l'assertion « fixed » et documenter le problème.

23–29 : question précise « IS IT ACTUALLY BETTER? WHAT STILL LOOKS WRONG? » ; inviter des commentaires de développeurs/joueurs.

29–32 : Ninja Duel + IN DEVELOPMENT ou statut vrai du build filmé.

**Si ancien build indisponible** : aucune fausse comparaison. Faire « WE'RE REWORKING OUR CAMERA — HERE'S THE TEST » avec V39 uniquement, un vrai problème démontré si possible et une question honnête. Autre devlog possible si on possède une preuve meilleure : « WE MADE TOO MANY BUTTONS » (V34 vs V39, version de chaque plan).

## 5. GATE ANTI-BUGS — un script ne suffit jamais
### Gate T : technique, avant d'inspecter l'image
- Noter nom de fichier, build/commit, NORMAL/DEBUG/QA et LIVE/TEST/CONCEPT. Ne pas mélanger les sources dans une même vidéo sans le dire.
- Lire Output NinjaDuelDev : action ok/reason. Un ok signifie **seulement que l'action est demandée/acceptée**, pas qu'elle a touché, ni que le rendu est beau.
- Inspecter 3 captures : le fichier brut, une capture écran du frame du contact, une capture frame de sortie de technique ; garder la preuve HUD ON.
- Dans le terminal du CM : python3 cm_tools/video_qc.py "chemin/vers/la_prise.mp4" (requiert ffmpeg + ffprobe). Regarder fichiers *_qc/sheet_*.jpg et report.json. Vérifier durée, résolution, pistes et alarmes noirs/freezes. Une transition noire intentionnelle peut être signalée à tort, et un squelette cassé n'est PAS signalé automatiquement.

### Gate V : inspection humaine frame par frame ; P0 = PAS DE PUBLICATION
Visionner la prise native à 1x puis autour de l'action critique à 0,25x et par frames. **Rejeter et refaire** dès qu'un P0 apparaît :
- Bras/jambes cassés, rotations d'os, sauts non voulus de poses, épaule ou arme détachée ; projectile partant d'un point incorrect.
- Coup touchant à l'image mais pas dans le gameplay, ou l'inverse ; dégâts présentés comme contre alors que l'action a été refusée.
- Téléportation voulue confondue avec pops visuels : corps dans mur, caméra qui traverse l'arène ou adversaire disparaissant hors cadre sans raison.
- Auras/particules qui restent après le mouvement, effets figés à l'ancien emplacement de main, VFX surchargés qui cachent entièrement l'action.
- Pause de personnage >0,2 s quand l'action devrait être fluide, root bloqué ou freeze de commande, coupes qui font croire que deux actions distinctes sont un seul hit.
- HUD Debug, Output, curseur, menu Roblox, noms de clients test, watermark ou UI qui masque l'attaque.
- Personnage dont le design change brutalement entre deux prises présentées comme un même échange.
- Mauvaise qualité de la scène : attaque ratée mais montage prétend succès, interaction impossible en jeu, promesse trompeuse.
- Écran noir/freeze non intentionnel, audio qui saute, fréquence irrégulière et saccades importantes.
**Interdiction :** masquer un P0 par flou, flash, énorme shake, speed-ramp, zoom qui coupe les mains, ou en sonorisant un faux contact. Si la mécanique est réellement impossible à filmer, adopter un cliffhanger honnête ou un autre scénario.

**P1 = reprendre ou recadrer AVANT export** : personnages trop petits en crop 9:16, objets-clés invisibles, visages non reconnaissables, contre illisible, caméra molle, fond trop éclatant, musique couvrant le contact. **P2 = cosmétique** : colorimétrie faible, texte perfectible, bruit décoratif mineur. P2 peut être corrigé au montage.

### Gate M : master final
- Revoir master complet à 1x muet sur téléphone, puis avec audio, puis 0,25x autour de chaque impact ou changement de plan.
- Interroger une personne non briefée : « Que s'est-il passé ? » Pour A elle doit voir un piège et sa réponse ; B qui est le perso et comment il se bat ; C quel problème a été amélioré. Si réponse incorrecte, refaire découpage/prise, pas ajouter plus de longs textes.
- Pas de logo 3 secondes au début. 2 lignes de texte maximum, anglais compréhensible, zone sûre hors UI TikTok/Shorts ; effets au service du jeu.
- Statut final : READY FOR USER REVIEW uniquement si Q0/Q1/Q2 sont acceptés ; sinon BLOCKED avec preuves du défaut.

### Modèle de rapport pour chaque prise
Tableau de CM_QA_YYYYMMDD.md :
PLAN | FICHIER | BUILD SHA | INPUT OK/REASON | MARQUE/VRAI CONTACT/ROTATION PROUVÉS ? | BLACK/FREEZE AUTO | P0/P1 HUMAIN | ACCEPT/REJECT | CORRECTION.
Exemples de décisions (PAS des faits actuels) : « A1_F_take02 : Rotation lancée mais aucun coup réellement contré -> REJECT » ; « B1_Mirage_take03 : effet clair, rig stable, couleur correcte -> ACCEPT ». Ne jamais recopier un exemple fictif comme résultat de test.

### Si le jeu produit réellement un bug
Créer CM_BUG_REPORT_YYYYMMDD_NOM.md avec SHA exact, build, personnage(s), commandes, setup/distance, nombre de reproductions, fichier preuve, frame ou timecode, diagnostic P0/P1, workaround filmable et escalade au gameplay. Le CM peut adapter un angle ou choisir une autre scène, **pas corriger le moteur en cachette**, pas publier la vidéo défectueuse. Si l'erreur vient uniquement du script de caméra CM, la rapporter comme bug du kit de tournage avant d'accuser le jeu.

## 6. Montage précis CapCut
- Créer le projet 1080x1920, 9:16, 30 ou 60 fps cohérents avec les rushes ; importer UNIQUEMENT les prises ACCEPT, pas des dizaines de rushes rejetés.
- Série A : monter D+E+F EN PREMIER. Si la téléportation/attaque/contre ne convainquent pas, le reste est inutile. Ajouter ensuite B, A, C, G, H. Couper sur mouvement/impact, pas transitions automatiques. Couper musique pendant 0,15 sec avant Rotation, ajouter un son de contact au vrai frame, pas au cut. Un seul léger ralenti au contre si fluide.
- Série B : monter les deux actions réelles d'Itachi avant de finaliser les jolies cartes. Rendre poster en couches séparées fond/personnage/texte, 2–3 keyframes maximum par couche. L'identité est plus importante que les transitions CapCut.
- Série C : monter comparatif avec vraies versions en premier puis enregistrer voix et construire les 25–32 sec autour ; supprimer toute assertion que les plans ne prouvent pas.
- Colorimétrie : petits contrastes et exposition, pas de bloom/blur/chromatic aberration qui cache les défauts. Audio : bruit du jeu + impacts/kunai/teleport séparés, musique abaissée aux moments importants, aucun OST Naruto non licencié.
- Export MP4 H.264 + AAC, 1080x1920 ; MASTER avec texte + CLEAN sans texte, COVER et projet source. Relire export FINAL ; repasser video_qc.py sur le master.
- Pas de publication TikTok/YouTube ni achat de plugin sans accord utilisateur. Travailler les contenus pour être meilleurs, pas pour atteindre artificiellement 3 vidéos/jour.

## 7. Blocages courants : solutions rapides
- Pas de NinjaDuelDev : mauvais build (Normal) ou Command Bar pas Server -> ouvrir Debug en Play, Server.
- Pas de LocalPlayer : caméra script côté Server -> Client.
- Bot/personnages absents dans caméra : structure de modèles différente -> regarder l'Explorer actuel, utiliser Freecam en secours, ne pas filmer vide. Ne pas toucher Camera.luau du jeu.
- Kunai sans marque : vérifier direction/collision et state.human.seals ; changer visée, recommencer, ne pas téléporter sans marque.
- FTG arrive loin : vérifier marque au sol et distance dans Output ; ne pas utiliser la prise si elle ne démontre rien.
- Rotation trop tard : regarder 0,25x, ajuster le délai de Technique3 bot, refaire la prise, ne pas intercaler une Rotation d'une autre scène comme faux contre.
- Capture OBS montre le code : mauvais choix de source -> capturer fenêtre client/jeu, masquage fenêtre, vérifier test de 6 s.
- HUD encore visible : UI recréée par le jeu ou CoreGui -> Freecam officielle ; ne pas supprimer interface du build publié.
- Caméra coupe les ninjas en 9:16 : changer angle camera trois-quarts, réduire écart, faire crop-test immédiatement.
- Ancien before introuvable : pas de comparaison, faire devlog honnête sur les tests actuels.
- Son ou vidéo saccadés : tester fps réels, capture GPU, diminuer qualité source si besoin puis remonter ; ne pas interpoler un faux 60fps.
- Studio script impossible à lancer : présenter capture Output et erreur exacte ; documenter BLOCKED, essayer méthode F6 officielle et capture depuis caméra normale. Ne pas affirmer avoir tourné.

## 8. Livrable et critère de clôture
Pour chacun des trois pilotes, fournir MASTER 9:16, version CLEAN, COVER, projet source, preuve réelle du mouvement, planche-contact/report auto, tableau ACCEPT/REJECT par plan, version/commit et audio/licence. Documenter les trois pires défauts restants et les correctifs/reprises effectués. Afficher uniquement READY FOR USER REVIEW si les images ne contiennent aucun P0 et sont compréhensibles sans briefing. Ne PAS annoncer « fini » parce qu'un MP4 existe.

**Règle finale pour le CM : un beau film exige une scène bonne, une prise lisible et un montage précis. Si une de ces trois conditions manque, on ne poste pas, on refait.**
