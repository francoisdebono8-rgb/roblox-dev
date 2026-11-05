# NINJA DUEL — BRIEF CM #01 : « THE KUNAI WAS BAIT »
**Date : 2026-11-05. Branche media : `media-clips`.**  
**Statut : commande de production vidéo autorisée par le propriétaire ; AUCUN changement du gameplay ni publication automatique.**

## Pourquoi cette mission
La branche contient déjà `WhoWins_01_Naruto_vs_Sasuke`, `WhoWins_02_RockLee_vs_Gaara`, leurs recuts et un film de tournoi. **Ne pas refaire Naruto contre Sasuke, Gaara contre Rock Lee ni un autre long « WHO WINS? » interchangeable.** L'utilisateur a constaté que les captures de gameplay brut manquent de spectacle et que les combats enregistrés ne sont pas bien montés. Il veut un **vrai film promotionnel** pensé avant le tournage, puis monté de façon professionnelle, sans mentir sur les mécaniques réellement jouables.

## Film à produire : « THE KUNAI WAS BAIT » (Minato vs Neji)
**Concept :** Minato semble rater un lancer de kunai, mais le kunai marqué est un piège : Minato s'y téléporte, débouche dans un angle imprévu et tente une frappe. Neji lit le piège et déclenche Rotation pour le repousser. Le spectacle vient d'une **décision tactique lisible et d'un contre**, pas d'un enchaînement d'ultimes.

Ce scénario est un **objectif de tournage, pas une preuve de compatibilité mécanique** : faire d'abord une prise brute complète avec la version du jeu réellement accessible et vérifier la cohérence marque → téléportation → frappe → Rotation. Dans le code `games/ninja-duel/src/Shared/Fighters.luau`, Minato a Marked Kunai et Flying Thunder God ; la téléportation ne frappe pas d'elle-même, il faut une action offensive réelle à l'arrivée. Neji a Rotation. Vérifier les timings réels. **Si la scène est impossible, utiliser le plan B plutôt que tricher.**

**Format :** master vertical 9:16, 1080x1920, 15–18 s, 30 ou 60 fps constants selon source ; accroche avant 1 seconde ; compréhensible sans son ; aucun logo avant l'action.

## Découpage EXACT à tourner (timecodes cibles, ajuster au contact réel)
| Master | Prise | Mise en scène | Montage/son/texte |
|---|---|---|---|
| 00:00–00:01.3 | A — HOOK | Très gros plan kunai marqué fiché au sol, Neji dans le fond ; plan intrigue | « HE MISSED? » immédiatement, tintement, micro-silence |
| 00:01.3–00:03.7 | B — THROW | Plan 3/4 montrant **Minato qui lance réellement** la marque à côté de Neji | Cut sur le mouvement + whoosh bref ; les deux silhouettes restent discernables |
| 00:03.7–00:05.7 | C — BAIT | Neji recentre sa garde, Minato loin ; kunai placé derrière / côté | Tension ; texte « WATCH THE KUNAI » seulement si indispensable |
| 00:05.7–00:08.2 | D — REVEAL | Téléportation FTG réelle à la marque, angle diagonal qui montre Minato et Neji | Coupe précisément sur disparition/réapparition, son spatial, pas de flash blanc aveuglant |
| 00:08.2–00:10.3 | E — ATTACK | Vrai coup de Minato après son arrivée ; angle moyen serré | Petit zoom de montage, conserver pieds/mains et direction de frappe |
| 00:10.3–00:13.0 | F — COUNTER | **Rotation réellement déclenchée** à temps, repousse / annule la frappe si le moteur le permet | 0.15–0.25 s d'attente juste avant impact puis SFX puissant ; au plus un speed ramp |
| 00:13.0–00:15.2 | G — RESULT | Plan large des deux corps séparés, pas de KO inventé | « NEJI SAW IT. » |
| 00:15.2–00:17.0 | H — CTA | Frame propre du jeu réel, typographie simple | « NINJA DUEL • ROBLOX » puis « WOULD YOU COUNTER IT? » |

**Règles cinéma :** pas plus de 8 plans ; couper sur l'action ; cadrages variés (bas, 3/4, large), pas d'effets de transitions templates ; garder l'espace cohérent entre plans ; la géographie du kunai/Neji/Minato est essentielle ; la trajectoire doit rester compréhensible ; pas d'énorme zoom artificiel qui cache le contact.

## Préflight obligatoire dans Studio
1. Ouvrir le projet **jeu**, sur sa branche actuelle `claude/ninja-duel-2026-10-14` (la branche media ne contient pas les sources complètes de gameplay). Relever HEAD et nom/hash du build effectivement filmé. Ne PAS prétendre filmer une V39 publiée si elle n'est qu'en test.
2. Vérifier le lancer de Marked Kunai, son ancrage exploitable, le Flying Thunder God, le coup réel en sortie et le contre Rotation. **Enregistrer une prise continue avec HUD**, même médiocre : c'est la preuve que l'action est réellement jouable.
3. Préparer une séance de capture **dirigée** : idéalement deux joueurs/contrôleurs (Minato et Neji) et un opérateur caméra ; sinon bots et Studio si les actions se reproduisent vraiment. Dire dans le rapport si c'est PvP, duel IA dirigé ou scène filmée par répétitions. Pas de faux « PvP live ».
4. Vérifier le **recadrage vertical** avant de filmer toutes les prises. Si source 16:9, placer les deux personnages dans la zone centrale 9:16 ; les mains, le kunai et la Rotation doivent y rester visibles.
5. Pour chaque plan A–H, capturer **2 prises courtes**, nommées, avec 0,5–1 s d'amorce et fin. Conserver les vraies actions du moteur et refaire les prises pour les angles ; ne pas inventer un mouvement au montage.

## Outils à utiliser (pas besoin d'un nouveau moteur vidéo)
- **Roblox Studio Freecam / caméra indépendante** : essayer le contrôle gratuit intégré en local pour des cadrages propres ; chercher la documentation Roblox officielle de free camera. Ne pas activer des capacités de modération/publication dans la place live juste pour filmer. Documentation : https://create.roblox.com/docs/workspace/camera/free-camera
- **OBS Studio** : https://obsproject.com ; capture écran/fenêtre à 60 fps si machine stable, haute qualité, audio du jeu séparé si possible, enregistrer en MKV puis remux en MP4 ; notifications désactivées.
- **CapCut Desktop** : https://www.capcut.com ; éditeur principal recommandé pour vitesse de production, images-clés, crop/pan 9:16, waveform et mix SFX.
- **DaVinci Resolve** : https://www.blackmagicdesign.com/products/davinciresolve ; option si CM sait déjà l'utiliser ; pas de migration obligatoire.
- **FFmpeg** : https://ffmpeg.org ; inspection fps/dimensions, conversion/export ponctuel, pas un prétexte pour écrire une grande pipeline.
- **Musique/SFX** : enregistrement et créations originales ou licences valides pour usage commercial et plateformes concernées. Pas d'OST Naruto, scènes d'anime ou effets tiers non licenciés. Une piste disponible sur TikTok n'est pas nécessairement autorisée sur YouTube.
- **Pas de confusion avec outils QA du repo :** `tools/studio/probes/film_record.luau` capture les poses **sans VFX**, `src/Server/DevFlight.luau` analyse les freezes, `tools/studio/probes/side_camera.luau` est une vue diagnostic ; aucun n'est un logiciel de production marketing. VFX Studio n'est pas un monteur vidéo.

## Montage CapCut (méthode reproductible)
- Projet : **9:16 / 1080x1920** ; poser toutes les meilleures prises sur timeline A→H et déplacer les coupes précisément au lancer, disparition, réapparition, frappe et contre. En cas de doute, mieux vaut **1 seconde de vraie action claire** que 3 secondes d'effets.
- Traitement : hard cuts, 1 speed ramp maximum (si source fluide), micro punch-in 3–6 % maximum, pas de transitions flashy répétées, pas de screen shake ajouté en continu. Stabiliser la lecture des combattants.
- Audio : cinq groupes (musique d'ambiance / métal-kunai / dash-téléport / frappe / Rotation + silence avant contact) ; privilégier un son distinct pour chaque action et éviter saturation. Diminuer musique au contre. Un montage doit sembler percutant même avec 3–4 SFX seulement.
- Texte anglais : **HE MISSED?**, éventuellement **WATCH THE KUNAI**, **NEJI SAW IT.**, **NINJA DUEL — ROBLOX**. Deux couleurs, une famille de fonte, pas de texte qui cache personnages, visuel lisible en mode muet. Ne pas affirmer « play now » si le build présenté n'est pas accessible.
- Color grade très léger : ne pas cramer les auras ni détruire la lisibilité du terrain. Pas de fausses frappes, faux dégâts, fausses téléportations, animations IA présentées comme input joueur, VFX simulant un comportement inexistant.

## Fichiers et état de livraison
Dossier local : `FILM01_KUNAI_TRAP/00_proof/uncut_with_HUD.mp4`, `01_raw/{A..H}_takeNN.mp4`, `02_edit/project.capcut` ou équivalent, `03_export/master_9x16.mp4`, `03_export/clean_no_text.mp4`, `03_export/cover.png`, `04_review/report.md`.
Sur **media-clips** : pousser la vidéo finale + miniature si le dépôt et les tailles le permettent, et toujours pousser un rapport avec build SHA, méthode de prise, outils, problèmes, vérification des mécaniques et licences. Préserver tous les anciens clips de cette branche. Ne jamais pousser un gros lot de rushes inutilement. Le CM doit rendre **une version visionnable en premier**, ne pas passer des heures à écrire des docs ou une infrastructure vidéo.

### Vérification qualité avant de dire « terminé »
- Un novice comprend **kunai → marque → téléport → attaque → parade** en un seul visionnage, sur téléphone, **sans son**.
- Hook réel visible dans <1 seconde ; vidéo dense ; aucune transition tape-à-l'œil qui masque le combat ; au moins un vrai contre / choix tactique.
- 16–18 secondes ; 1080x1920 ; audio propre ; miniature attrayante ; CTA visible mais pas envahissant.
- Comparatif avec anciens WhoWins : **action compréhensible plus vite et meilleure sensation de montage**. Ne pas se déclarer « cinéma pro » sans retour utilisateur.
- Statut rendu : `READY FOR REVIEW` et **ne pas publier sur les réseaux** sans feu vert du propriétaire.

## Plan B si l'action ne fonctionne pas dans le build
- Si la Rotation n'arrête pas proprement l'attaque : couper après le téléport et la préparation d'attaque, laisser le mystère `DID YOU SEE IT COMING?`. **Ne pas fabriquer un contre qui n'existe pas.**
- Si la marque ne peut pas être posée derrière / sur le côté : reprendre une **configuration vérifiée** montrant seulement un déplacement malin vers une marque vraie.
- Si le tout est impossible : proposer une **autre micro-ruse avec une paire différente** du roster bêta, jamais Naruto–Sasuke ni Gaara–Lee, et documenter la prise de substitution avant export.
- En cas de bug du jeu, remonter la vidéo + SHA à l'équipe gameplay sans modifier cette branche de code ni bloquer la production de plusieurs clips.

## Suite après approbation de ce film
Exploiter les rushes : teaser 7–9 s, showcase Minato 10–12 s, micro-devlog 20–30 s « how we filmed the trap ». Ne pas produire trois montages médiocres avant le master ; le rythme de 3 posts/jour viendra **après** mise au point du format et des templates.

**FIN :** commence par le test de réalité mécanique, puis **tourne et monte effectivement le film**, ne reste pas au stade d'une proposition. Tout achat/abonnement/plugin, changement du jeu et publication nécessitent autorisation distincte.
