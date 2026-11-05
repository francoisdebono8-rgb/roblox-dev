# NINJA DUEL — BIBLE DES TROIS SÉRIES SOCIAL MEDIA

**EXÉCUTION OBLIGATOIRE :** commencer par [CM_START_HERE](CM_START_HERE.md), puis [RUNBOOK STUDIO + QC ANTI-BUG](CM_EXECUTION_RUNBOOK_SHOTS_AND_BUG_QA.md). Les scènes ne sont validées qu'après capture réelle et revue visuelle : aucun plan buggé n'est conservé.
**05 novembre 2026 — Direction créative et fabrication pour le community manager**  
**Branche : media-clips. Statut : brief créatif et production ; aucun post public ni changement gameplay autorisés par ce fichier.**

## Décision éditoriale : ne pas multiplier les duels, construire trois raisons de suivre le jeu
L'utilisateur veut potentiellement **3 vidéos/jour** : combats, mockups de personnages, devlogs. Garder les trois, mais **pas comme trois clips interchangeables**. Chacun vise une émotion, un spectateur et une conversion différente :
1. **NINJA IQ** — micro-films de tactique, cinéma réalisé avec des actions du vrai jeu. **Découverte / désir de jouer.**
2. **PRODIGY FILES** — présentations premium, mélange contrôlé de mockup/design et de preuve gameplay. **Désir de « main » un combattant / commentaires / sauvegardes.**
3. **BUILDING THE IMPOSSIBLE** — devlog narratif problème → tentative → résultat réel. **Confiance / communauté / retour voir la suite.**

Pas de répétition de Naruto–Sasuke ni Gaara–Lee, déjà utilisés dans clips/WhoWins_01*, clips/WhoWins_02*, et tour2/Tournoi_WhoWins_FINAL.mp4. Les documents ne sont pas une commande pour un 3e Who Wins. **Priorité à l'originalité du conflit et de la mise en scène**, pas à l'épaisseur du catalogue d'effets.

### Vérité produit à respecter
- Branche gameplay : claude/ninja-duel-2026-10-14, HEAD à vérifier avant capture. Au 05/11, le journal de développement marque **V36 publiée**, V37/V38/V39 encore **builds test, non publiés**. Ne pas promouvoir comme jouable une feature issue d'une build test. Différencier sur chaque fichier : LIVE / TEST / CONCEPT.
- Les huit personnages de la bêta : Sasuke, Naruto, Gaara, Lee, Neji, Itachi, Kakashi, Minato. Ne pas vendre les douze autres comme jouables.
- Le code n'est pas une preuve que la scène est belle, fluide et reproductible : préflight en vraie session, puis rushes.
- Les assets de Naruto et les OST/visuels de l'anime appartiennent à des ayants droit. Pas d'extrait vidéo d'anime, OST non licenciée, fausse revendication « official Naruto » ; revoir droits commerciaux de l'expérience et des publicités avant expansion.
- Toutes les séries sont **en anglais** pour le public mondial, sous-titres anglais simples, titres parfois japonais calligraphiques uniquement si vérifiés ; rien qui ait l'air d'une affiche fan-art officielle.
- Un concept/matte painting/Blender mockup n'est jamais montré avec une légende implicite « gameplay » ; marquage discret **CONCEPT** ou **IN-ENGINE RENDER** selon la vraie source, et passage vers **ACTUAL GAMEPLAY** si disponible.

---

# SÉRIE A — NINJA IQ
## Promesse / ADN
**Un problème. Une idée. Un contre.** Le spectateur croit qu'il a compris, puis découvre un usage tactique d'un outil ou d'une technique. L'image doit convaincre sans narration et souvent sans texte ; les effets accentuent le retournement, jamais ne remplacent une interaction réelle.

**Master : 14–20 s** (9:16 1080×1920), 6–9 plans intentionnels. Écriture avant enregistrement. Cinéma tactique plutôt que montage au hasard d'un combat complet. Couper au point de décision, au changement d'angle, au contact, pas toutes les 0,5 s.

## Pilote A1 déjà spécifié (ne pas le redévelopper)
**THE KUNAI WAS BAIT — Minato vs Neji.** Voir PRODUCTION_FILM_01_THE_KUNAI_WAS_BAIT.md dans CETTE branche : 8 plans, timecodes, méthode de tournage et montage complète. Ce fichier est autoritaire sur le premier film. Lancer sa réalisation en priorité et produire 1 master approuvable avant d'étendre la série.

## Pilote A2, si la première vidéo fonctionne : « HE HIT THE WRONG ITACHI »
**Duo : Itachi vs Kakashi.** Un combattant attaque ce qu'il pense être le vrai Itachi ; l'image reste, le vrai Itachi a changé d'angle, il contre. **Nouveau problème narratif**, non basé sur canonique Naruto/Sasuke. Le code de Itachi/Mirage possède MirageCast (image résiduelle), Read (contre), shuriken multi-angle ; cela n'autorise pas à inventer le résultat exact contre Kakashi. Tester d'abord l'action réelle.

| Timecode | Plan à tourner | Raison / son / texte |
|---|---|---|
| 0.00–1.00 | POV caméra derrière Kakashi ; Itachi semble ouvert, frappe imminente | Hook HE'S RIGHT THERE. ; petite suspension |
| 1.00–3.20 | Gros plan des yeux/garde de Kakashi, puis il engage réellement | tension et claquement de pas |
| 3.20–5.10 | Coup qui traverse ou frappe **une image de MirageCast**, si le vrai moteur le permet | musique coupée, impact creux |
| 5.10–8.00 | Plan latéral plus large : Itachi réel s'est décalé, image dans l'ancien emplacement | texte WRONG ONE. |
| 8.00–11.60 | Itachi exploite le contre réel, ou lance ses shuriken, EN FONCTION de ce que le test produit | 1 whoosh, 1 contact net |
| 11.60–14.20 | Deux silhouettes redéployées ; finir avant de faire traîner | YOU CAN'T JUST MASH. |
| 14.20–16.00 | NINJA DUEL • PLAY ON ROBLOX | CTA clair, pas fausse promesse |

**Plan B si illusion illisible :** filmer un usage réel de Read / esquive parfaite / counter de Itachi et titrer « HE READ THE ATTACK », sans dire que le joueur a frappé un clone.

## Bibliothèque d'idées A3–A6 à tester, pas scènes garanties
- **« THE WALL IS A WEAPON » — Neji vs Kakashi** : paume ou poussée qui exploite vraiment le mur, angle qui révèle le rebond et le repositionnement. Vérifier collision et contre ; ne pas créer de physique imaginaire.
- **« SPEED ISN'T EVERYTHING » — Lee vs Minato** : Lee feinte ou se protège d'un repositionnement ; tension entre course physique et téléportation, pas un 40 secondes d'échange de jutsu.
- **« THE GROUND IS THE TRAP » — Gaara vs Kakashi** : enjeu de contrôle d'espace, plans bas sur terrain et anticipation, pas remake du duel classique Lee–Gaara.
- **« ONE SHURIKEN. TWO ANGLES. » — Itachi vs Neji** : Shuriken Geometry / ricochets réellement existants, une décision liée à l'angle de sortie ; tester l'effet visualisable en vidéo verticale.

### Direction de tournage A
- Capturer 1 prise continue avec HUD pour prouver l'interaction, puis tournages d'angles **A/B/C** avec vrais inputs et actions cohérentes ; jamais prétendre que le montage multireprise est une captation continue.
- Shooter 1920×1080 ou plus, 60 fps si stable ; garder personnages et point de décision dans la zone centrale recadrable. Freecam Roblox (Shift+P si autorisée), OBS, capteur local. Freecam uniquement en session autorisée, ne pas introduire d'outil cinématique runtime dans la release.
- 1 angle espace, 1 angle intention, 1 angle décision/contre. Les coupes servent **la compréhension spatiale**, donc ne pas multiplier FOV/axes de manière confuse.
- Son : pas de musique choisie avant d'avoir les contacts ; métal de kunai/shuriken, vent, friction, claque, demi-silence avant révélation. Un seul speed ramp modéré si le rush peut le supporter.
- Validation **muette sur téléphone** : un spectateur inconnu comprend-il le piège en moins de 15 s ? Si non, refaire un plan. Pas ajouter 8 sous-titres explicatifs.
- Micro-CTA 1–2 s sans briser le climax ; nom du jeu identique à sa page Roblox.

### Variantes de hook A : tester deux premières secondes sans refaire tout le film
1. Question : « HE MISSED? »
2. Assertion : « THAT WASN'T A MISS. »
3. Challenge : « COULD YOU READ THIS? »
Ne pas attribuer artificiellement tout gain de vues au hook si les audiences/horaires diffèrent.

---

# SÉRIE B — PRODIGY FILES
## Promesse / ADN
**« This isn't a list of powers. This is how your fighter thinks. »**
Format caractère **premium, magazine japonais / fiche d'agent / sélection de tournoi**, mais PAS diaporama statique de fan art. On part d'une image forte et d'une silhouette, puis montre **une preuve de comportement dans le jeu**. Le clip doit donner envie de répondre « je main ce personnage ».

**Master : 12–18 s, vertical 9:16**. Version non parlée (musique + sons + typographie) et option courte voix off. Trois couches : image héros propre, design animé en 2D, 2 preuves de mouvement réel.

### Direction artistique B
Créer un petit système reproductible (Figma, Photopea ou Canva) :
- fond ivoire texturé / encre noir charbon + **une couleur du combattant** ; polices 1 titre expressive + 1 technique très lisible, pas de 6 typographies ;
- numéro de dossier discret, nom énorme, micro-mot clé (DECEPTION / SPEED / PRECISION), cercle de visée, lignes calligraphiques ou filet géométrique ; **pas de HUD de combat réutilisé comme mockup** ;
- parallaxe simple 2 couches, recadrage et léger grain contrôlé. Pas de VHS flou, pas de grandes flares, pas d'écran bourré de statistiques fictives ;
- le personnage est issu du **modèle réellement présent en jeu** : capturer en Studio / Blender à partir d'un rig autorisé, conserver le modèle/proportions/coiffure. Les concept arts non intégrés sont explicitement marqués **CONCEPT ART**.
- Si du contenu IA illustratif est utilisé, étiquette CONCEPT et pas « actual in-game render ». Préférer modèle Studio + éclairage + retouches photo non génératives pour représenter fidèlement la version actuelle.

### Pilote B1 : « ITACHI — YOU DIDN'T HIT HIM. »
**Angle :** ne pas vendre la « plus grosse attaque », vendre la psychologie du personnage : Itachi ne gagne pas en frappant plus fort, il **lit** et trompe. Cette série B est **une affiche vivante de perso**, différente de la narration du film A (aucun ennemi entier nécessaire dans le teaser).

| Temps | Image précise | Effet de montage / texte |
|---|---|---|
| 0.0–1.4 | Fond noir d'encre, silhouette Itachi 3/4 ; une plume ou trait rouge apparaît derrière sa tête | « NOT EVERY FIGHT IS ABOUT POWER. » 6 mots max sur l'écran |
| 1.4–3.5 | Reveal du rendu 3D Itachi, cadrage tête/torse, un regard vers caméra, nom monumental ITACHI | un seul son de claquement d'encre, pas de zoom instable |
| 3.5–5.3 | 2D dossier : trois mots-clés, par exemple **READ / DECEIVE / PUNISH** ; éléments graphiques qui apparaissent sur le beat | écran lisible 0,6–1 s ; ne pas faire croire à 3 techniques unlock |
| 5.3–8.1 | ACTUAL GAMEPLAY : Itachi déploie **Mirage** ou **Read** (selon la meilleure prise contrôlée) ; prendre le plan où l'ennemi est lisible | bref label fonctionnel « THE MIRAGE » / « HE READ IT » |
| 8.1–11.0 | ACTUAL GAMEPLAY : shuriken angle / Sharingan counter / Katon, deuxième geste **très différent** du premier | coupe sur la main ou arme avant release, son sec |
| 11.0–13.7 | Retour en gros plan héros, même pose/palette que le début, une silhouette s'efface derrière lui | « OUTPLAY. DON'T OUTSPAM. » |
| 13.7–16.0 | ITACHI — PRODIGY 06 (numéro seulement si vrai roster numéroté ; sinon supprimer « 06 ») + NINJA DUEL | « WOULD YOU MAIN HIM? » |

**Règles d'authenticité B1 :** Itachi dans le jeu a Shadow Shuriken, Great Fireball, Genjutsu Mirage, Sharingan Read et un éveil Sharingan Focus. Le CM choisit 2 actions **filmées et vérifiables** ; pas de Mangekyo/corbeaux géants non présents, ni gameplay de Naruto emprunté. Si l'animation/FX ne supportent pas encore le gros plan, réduire la durée du close-up ou choisir une silhouette forte 3D, mais **ne jamais maquiller un rendu non jouable en gameplay**.

### Pilote B2 — « WHY MAIN NEJI? »
Personnage pour public connaisseur, pas le choix évident « Naruto vs Sasuke ».
- Hook 0–2 s : « HE DOESN'T NEED A GIANT JUTSU. » plan main ouverte + chakra bleuté discret.
- 2–5 s : portrait Studio en grand + calligraphie HYUGA / PRECISION ; pas d'attaque.
- 5–8 s : gameplay paume réelle, une fenêtre de garde/contre ; montrer le déplacement du corps adverse.
- 8–11 s : Rotation ou 64 Palms vraie, cadrage court qui montre la lecture.
- 11–14 s : écran décision « POWER or PRECISION? », appel commentaire « WOULD YOU MAIN NEJI? ».
Ne pas afficher « SHUTS DOWN EVERY JUTSU » : le vrai moteur a des règles/limites. Ne pas transformer la fiche en tuto de 10 touches.

### Variantes B3–B8 / ligne de chaque perso
- Minato : **HE FIGHTS WITH WHERE HE'LL BE** (marques/angles).
- Gaara : **HE OWNS THE GROUND** (contrôle d'espace).
- Lee : **NO SHORTCUTS. JUST SPEED.** (taijutsu et jeu d'appuis).
- Kakashi : **HE LEARNED TO READ YOU** (tanto/terre/lecture).
- Sasuke : **VERTICAL PRESSURE** (mur/feu/foudre).
- Naruto : **YOU NEVER FIGHT JUST ONE** (clones), sans refaire Naruto–Sasuke.
- Neji : **ONE OPENING IS ENOUGH** (paumes/rotation).
- Itachi : **THE HIT YOU NEVER SAW** (mirage/read).
Varier l'angle de l'image, la cadence et le moment gameplay ; le template sert à rendre identifiable la marque, pas à fabriquer 8 clips identiques.

### Workflow B concret
1. Choisir 1 perso et 1 proposition visuelle **vraie**. Prendre 5–10 photos / renders in-engine (hero, silhouette, détail visage, mains/arme, action, arène). Viser poses vraiment distinctives.
2. Figma (https://www.figma.com/) ou Photopea (https://www.photopea.com/) : créer un poster vertical 1080×1920 en calques séparés BG / ink / hero / text / graphic. Canva (https://www.canva.com/) possible pour exécuter plus vite, mais garder une charte unique.
3. Studio + OBS : enregistrer **deux actions précises** du personnage, 3–5 s chacune avec et sans HUD selon la preuve à conserver. Développer si nécessaire les besoins de cadrage sur une copie test, pas sur la production.
4. CapCut : animer poster en 2D via 3 keyframes max par plan (parallaxe lent, masque d'encre d'entrée, surimpression d'une courte scène jeu), synchroniser vrai release avec un accent sonore.
5. Export : MP4 9:16, cover 9:16 et cover carrée recadrable, PNG poster séparé, fichier source rééditable. Vérifier sur téléphone que le vrai gameplay occupe **au moins ~35 % du temps** (cible éditoriale, pas obligation arbitraire si clip exceptionnel).
6. Critère : en mode muet, le spectateur sait **de quel perso il s'agit, ce qui le rend différent, et qu'il existe réellement dans le jeu**.

---

# SÉRIE C — BUILDING THE IMPOSSIBLE
## Promesse / ADN
« Nous fabriquons le jeu de ninja auquel on aurait voulu jouer. Voici le problème du jour et le progrès concret. »  
**Devlog ≠ journal de commits.** On ne dit pas « V39 est sortie avec 40 tests passés ». On raconte : « Le jeu était complexe à jouer. Regarde pourquoi. Regarde ce qu'on a changé. Est-ce mieux ? »

**Master : 25–40 s**, anglais, ton humain et direct, pas d'avatar IA qui se fait passer pour un développeur, pas de gameplay mis en scène présenté comme un test avec un joueur réel. Visuel : vrai Studio, écran de capture du jeu, avant/après côte à côte, annot 2–3 mots maximum.

### Pilot C1 : « THE CAMERA WAS FIGHTING US »
Ce pilote s'appuie sur un problème historique **documenté**, pas une invention marketing :
- CURRENT_STATE de la branche gameplay : V37/V38/V39 (05/11) mentionne une caméra qui perdait le rival au mur, rebondissait entre cadrages, et une relecture des commandes manette ; V39 est en test, pas encore publié lors de la préparation de ce brief.
- Le CM doit **obtenir deux captures comparables** : ancien build conservé (V37/V38) et build V39 test sous Studio. Si l'ancien build est indisponible, **NE PAS simuler un faux « before »** ; filmer le problème sur une session actuelle si reproduit ou prendre une autre vraie amélioration testable.

#### Script de voix off (anglais, naturel, ~70 mots, à enregistrer ou sous-titrer)
« We're building a ninja fighting game on Roblox. But there was a problem: during fast fights, the camera kept losing the opponent. It made the combat feel worse than it actually was. So we changed how the camera follows the action, especially near walls. Here's the old version. And here's the new one, filmed from the same situation. Is it actually better? Tell us what still looks wrong. »

Remplacer toute phrase sur l'avant/après si les images ne prouvent pas ce qu'elle dit.

| Temps | Plan | Audio / légende |
|---|---|---|
| 0–2 s | **Avant** : caméra qui perd réellement l'adversaire, au pire moment | « OUR CAMERA WAS RUINING THE FIGHTS. » |
| 2–6 s | Même plan encore 1–2 s avec surlignage fin du rival hors-champ | « You couldn't even see the opponent. » |
| 6–10 s | Capture Studio / réglage caméra / note du bug réelle, souris qui parcourt | « So we rebuilt the camera rules. » |
| 10–15 s | Comparaison écran séparé, même perso, même arène, même action si possible | mini labels BEFORE / AFTER, pas de chiffres sortis de nulle part |
| 15–23 s | **Après** : duel court vraiment plus lisible (saut, mur, déplacement), capture V39 TEST | démonstration sans musique trop forte |
| 23–29 s | 1 plan héros du vrai jeu + question | « WHAT WOULD YOU FIX NEXT? » |
| 29–32 s | NINJA DUEL / ROBLOX / BETA (uniquement si la version montrée correspond à la disponibilité) | CTA discret |

Un devlog n'a pas besoin de « troisième minute d'ordinateur qui code ». Montrer le problème immédiatement puis la preuve. Les commentaires doivent aider à décider du prochain problème.

### Pilote C2 : « WE MADE TOO MANY BUTTONS »
**Même code, meilleur onboarding**. V34 a été corrigée par V35/V39 ; le journal documente de nombreux inputs refusés lors d'une séance manette et l'évolution de l'interface. Filmer une vraie séquence de touches de la vieille interface puis une version de test plus simple, en notant la version visible.
- Hook : « WE BUILT A NINJA GAME NOBODY COULD CONTROL. »
- Révélation : commandes / page de jutsu incompréhensible, joueur rate sa substitution (si capture existante).
- Changement : écran tutorial réduit (V37, premier PLAY / 4 étapes) et jutsu sur accords plus simples V39.
- Payoff : un nouveau joueur réussit une action en quelques secondes. **À prouver avec testeur réel**, pas un bot de tutoriel.
- Question : « SHOULD COMBAT BE SIMPLE TO LEARN OR HARD TO MASTER? » (réponse : les deux, si possible).
Ne pas affirmer « nobody » factuellement dans la voix off si pas de vrais retours utilisateurs : faire du hook une question/ressenti « WE MADE CONTROLS WAY TOO COMPLICATED. ».

### Pilote C3 : « WHY OUR FIGHTS DIDN'T FEEL LIKE NINJAS »
Ancien geste faible → action corporelle refaite (course/mur/réception/impact) dans un mini A/B exact. Filmer la vraie animation native du build, pas une animation Blender seule et ne pas déduire de « x % smoother » sans mesure. C'est le développement **qui améliore l'expérience joueur**, pas l'artiste qui récite des progrès.

### Structure de script C réutilisable
1. **0–3 s : le défaut visuel**, pas « Hey guys » ni écran logo ;
2. **3–10 s : pourquoi c'est un problème pour le joueur** (1 idée) ;
3. **10–22 s : la correction réelle, 2–3 images utiles de Studio/Blender/code MAX** ;
4. **22–30 s : comparaison ou démonstration filmée** ;
5. **30–36 s : question spécifique / teaser du prochain problème**, CTA très léger.
Les vidéos peuvent être plus courtes si les plans n'apportent pas de valeur.

### Langage visuel et son C
- Charte atelier/annotation : petit marqueur rouge sur un défaut, encart TIME / VERSION / TEST BUILD, typo sans-serif lisible, grille simple, pas de fausses interfaces de code.
- Une voix humaine réelle si possible. Si aucune, sous-titres animés et audio du jeu. Éviter les voix IA génériques ou les clones de voix sans accord. L'aspect « artisan du jeu » doit paraître sincère.
- Faire entendre les deux versions ; si la musique masque le défaut elle ruine le devlog. Narration en avant, effet jeu en retrait, pas d'OST Naruto.
- Conserver des snapshots « avant » et « après » dans une petite médiathèque ; **la principale matière première d'un bon devlog est une preuve capturée au moment où le problème existe**, pas un faux avant recréé après.

---

# SYSTÈME DE PRODUCTION COMMUN — 3 POSTS / JOUR SANS 3 TOURNAGES COMPLETS
## Une journée de tournage doit alimenter plusieurs vidéos
**Production n'est pas publication.** Construire 1 micro-film phare + 1 séance de poses/rendus + 1 vraie correction filmée. Les rushes servent à 3 séries, mais **chaque montage doit avoir sa propre histoire**. Ne pas mettre les mêmes 6 plans dans 3 posts consécutifs.

**Cadence recommandée pour tester l'objectif 3/jour** :
- Préproduire un tampon de **9–12 vidéos terminées** avant toute cadence 3/jour ; sinon publier 1–2 de qualité plutôt que 3 remplissages.
- Sur 7 jours : visée **7 NINJA IQ** (2 films principaux + des variantes/contre-angles/hooks, pas 7 combats complets), **7 PRODIGY FILES** (personnages non répétés ou comparaisons différentes), **7 BUILDING THE IMPOSSIBLE** (à condition d'avoir 7 vrais changements intéressants ; sinon remplacer certains devlogs par un making-of ou réponse aux commentaires VRAIE).
- Ne pas inventer 7 problèmes ou améliorations si vous n'en avez que 2 ; la qualité et l'authenticité prévalent. Tester une première semaine avant de figer 3/jour.

### Planning de contenu pour une semaine test (concepts, pas scènes automatiquement disponibles)
| Jour | A — NINJA IQ | B — PRODIGY FILES | C — DEVLOG |
|---|---|---|---|
| Lundi | Minato–Neji « kunai bait » | Itachi « read/deceive/punish » | Caméra avant/après |
| Mardi | Teaser alternatif du même piège, hook différent | Neji « precise counter » | Pourquoi notre HUD cachait le combat |
| Mercredi | Itachi–Kakashi « wrong Itachi » (si viable) | Lee « no shortcuts » | Pourquoi les coups manquaient de poids |
| Jeudi | Réponse tactique au meilleur commentaire du lundi | Minato « fight with angles » | Ce qui a raté au tournage, puis correction |
| Vendredi | « One shuriken, two angles » (préflight) | Kakashi « tanto / earth » | Les commandes trop complexes |
| Samedi | Duel contre-intuitif Gaara–Kakashi (préflight) | Gaara « owns the ground » | Comment on a tourné un film avec le vrai jeu |
| Dimanche | Compilation tactique 9–12 s de meilleurs moments, pas faux « part 2 » | Naruto ou Sasuke, focus capacité distinctive | Vote sur le prochain problème, avec vraies options |

**Attention :** deux variations du même film ne doivent pas être postées le même jour ; ne pas marteler le même final pendant une semaine.

## Emploi d'outils — choisir l'outil selon la tâche, pas le prestige
- **Studio + Freecam + OBS** pour les faits gameplay et les plans. Voir la bible du film 01 pour le guide de capture ; Full/Low effects v38 ne doit pas être confondu avec un embellissement artificiel.
- **Blender ou rendu Studio** pour les poses de personnages, PAS pour inventer du gameplay. Conserver rigs/couleurs et lisibilité.
- **Photopea / Figma / Canva** pour les mockups en couches ; créer 8 fichiers de personnage sur UNE charte modulaire.
- **CapCut Desktop** pour montage, keyframes, recadrage 9:16, captions, sound design ; **DaVinci Resolve** seulement si CM est déjà à l'aise pour l'étalonnage/mixage.
- **Audacity** (https://www.audacityteam.org/) pour nettoyer une vraie voix, réduire bruit, égaliser rapidement.
- **OBS remux MKV→MP4** pour la sécurité des rushes.
- Captures 16:9 peuvent être difficiles en 9:16 : valider sur téléphone dès les premières prises. Ne pas créer une vidéo verticale où les joueurs sont minuscules.
- Garder un **dossier commun d'assets**: logo exact, 8 renders autorisés, palette par personnage, 10 SFX originaux/licenciés, 3 gabarits 9:16, 3 intros immédiates (sans logo), gabarit CTA 1,5 s, projet de sous-titrage.

## Prescriptions techniques minimales
- Fichier master 1080×1920, H.264 MP4 + AAC, 30 ou 60 fps **cohérent avec les sources** ; viser 60 seulement si capture native stable. Son enregistré proprement, pas d'écrêtage.
- Textes au centre du champ utile (éviter les contrôles TikTok en bas et la colonne de boutons à droite). 5–7 mots maxi par panneau en mouvement ; sous-titres sur 1–2 lignes.
- Pas d'intro/logo de 3 s, pas de freeze sale, de surimpressions VFX gratuites, de mélange images fan-art et prétendues captures moteur.
- YouTube Shorts accepte vertical/carré jusqu'à 3 minutes, mais nos séries **restent bien plus courtes par choix créatif**, pas à cause d'une limite technique.
- Prévoir exports **MASTER / CLEAN-no-text / COVER / CAPTION / SOURCE-PROOF**, sans watermark de plateforme pour réutiliser sur TikTok/YouTube.
- Musique et images : garder l'origine et la licence, ne pas supposer qu'un son autorisé sur TikTok l'est automatiquement sur YouTube.

## Caption/pinned comment/CTA de base — anglais
**A (cinéma tactique)** : « He didn't miss. He wanted you to think he did. Minato vs Neji in Ninja Duel. Would you have seen it coming? »  
**B (fiche perso)** : « Itachi isn't just about big jutsu. Reading your opponent changes the fight. Would you main him? [CONCEPT / GAMEPLAY labels where relevant]. »  
**C (devlog)** : « The camera kept getting in the way of combat, so we're testing a new one. Which version feels better to you? Game: Ninja Duel on Roblox. »  
Toujours ajuster au contenu **réel** et à la disponibilité publiée. Commentaire épinglé avec nom EXACT du jeu + lien traçable si plateforme le permet ; ne pas spammer Discord.
- Les hashtags sont secondaires : 2–4 pertinentes (ex. #Roblox #RobloxFighting #NinjaDuel), pas 20 hashtags sans rapport.

## Mesure et décision — éviter « vues = succès »
Utiliser le Creator Dashboard Roblox, menu Analytics > Acquisition, et des **Share Links dédiés** par réseau / campagne si disponibles. Mesurer sans inventer l'attribution précise d'un spectateur individuel.
- **A :** rétention sur vidéo, revisionnage, partages, clics Roblox et qualified plays.
- **B :** visionnage complet, sauvegardes, commentaires spontanés « I main X », visite profil et clics.
- **C :** commentaires argumentés, abonnements, taux de retour aux vidéos suivantes, tests bêta recrutés, signalements utiles.
- Au bout de **14 jours** comparer chaque série à elle-même (longueur, hook, horaire, audience) ; ne pas conclure « tel format convertit mieux » uniquement à partir des vues.
- Si le CM a accès aux analytics, enregistrer captures/statistiques **sans exposer d'identifiants personnels** ; KPI dérivés clairs et notes sur incertitude. Les métriques vidéo de TikTok/YouTube ne sont pas des logs de sessions Roblox.

## Critères de livraison à l'utilisateur
1. Un **MASTER A1** selon le brief de film autonome (17,5 s), preuve de scène complète ; puis A2 uniquement si le premier est réussi.
2. Un **MASTER B1** Itachi avec poster portrait source + scènes jeu réelles et source editable ; labels concept/gameplay honnêtes.
3. Un **MASTER C1** caméra avant/après avec **deux versions identifiées** ou plan B honnête si ancien rush indisponible.
4. Un fichier texte pour chaque video : nom de série, question marketing, SHA/build, rushes, traitement visuel, durée, son/licence, date, version, défauts encore visibles, statut **READY FOR USER REVIEW**. Pas de « publié » tant qu'aucune publication n'a eu lieu.
5. Soumettre les 3 pilotes ensemble au créateur. Corriger d'abord qualité des pilotes avant de mettre en route 3 publications quotidiennes.

## Vérifications de sources d'information
- Roblox Acquisition / share links : https://create.roblox.com/docs/production/analytics/acquisition
- Roblox Discovery / onboarding : https://create.roblox.com/docs/discovery
- TikTok guide : https://ads.tiktok.com/business/en/guides/video-advertising-guide
- YouTube Shorts : https://support.google.com/youtube/answer/12779649?hl=en
- Figma : https://www.figma.com/ ; Photopea : https://www.photopea.com/ ; Canva : https://www.canva.com/ ; Audacity : https://www.audacityteam.org/
- Source jeu : games/ninja-duel/docs/active/CURRENT_STATE.md, src/Shared/Fighters.luau, src/Server/Techniques.luau sur **branche gameplay**, et la bible du film 01 dans cette **branche média**.

**Ordre de prod** : vérifier / réaliser A1, fabriquer B1, fabriquer C1, comparer les trois pilotes en vidéo, soumettre à approbation. **Aucune modification du gameplay et aucune publication automatique**.
