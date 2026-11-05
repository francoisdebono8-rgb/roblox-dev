# CM — PRODUCTION FILM 01 : THE KUNAI WAS BAIT
Date : 2026-11-05. Branche de livraison : **media-clips**. Demande utilisateur : fournir au CM toutes les instructions pour produire un vrai film promotionnel bien tourné et monté ; **ne pas refaire Naruto vs Sasuke, Gaara vs Rock Lee, ni un énième long duel « Who Wins? »**.

## 1. Contexte à ne pas manquer
Sur cette branche existent déjà : clips/WhoWins_01_Naruto_vs_Sasuke*, clips/WhoWins_02_RockLee_vs_Gaara*, leurs recuts v2/v3 et tour2/Tournoi_WhoWins_FINAL.mp4. Ne pas supprimer ces médias. Ils ne définissent PAS le prochain format : les combats bruts et les montages précédents ne donnent pas encore le rendu désiré.

**La nouvelle vidéo raconte un piège et sa lecture, pas un vainqueur canonique.** L'USP de Ninja Duel : le joueur combine des possibilités de combat et l'adversaire peut réagir. Un film de **16–18 secondes**, des prises intentionnelles, aucun intro-logo initiale, aucun tour de compétences récité.

**Statut : brief de production vidéo approuvé, pas ordre de modifier le code du jeu, de déployer une nouvelle build ni de poster sur les réseaux.** Le code et les builds sont sur claude/ninja-duel-2026-10-14 ; media-clips contient les médias et les instructions. Vérifier SHA et build exact avant de filmer.

## 2. Concept choisi
**Titre de travail : « THE KUNAI WAS BAIT »**
**Duo non surexploité : Minato vs Neji.**
Un kunai de Minato semble manquer Neji. Mais le projectile dépose une marque : Minato se téléporte sur cette marque pour surprendre Neji. Neji déclenche Rotation pour contrer le coup de Minato. Le moment surprenant est une *décision tactique des deux joueurs*, pas une cutscene de 10 secondes.

À confirmer dans le build, par vrais inputs et non par supposition :
- src/Shared/Fighters.luau : Minato/Flashstep possède MarkedBlade (Marked Kunai) et Flashstep (Flying Thunder God) ; Neji/GentleFist possède Rotation.
- src/Server/Techniques.luau : FTG prototype prend une marque réelle (dernière marque utilisable). Vérifier que le lancer marque bien le sol à cet endroit, que le cooldown est respecté et que l'arrivée est dans le cadre.
- src/Server/Brawler.luau : **la téléportation ne fait pas de dégâts en elle-même** ; une frappe en sortie est nécessaire pour créer le contact. La Rotation de Neji doit réellement repousser / contrer cette frappe si elle est dans la bonne fenêtre. Si le rendu ou les règles réelles diffèrent, adapter la scène, NE PAS fabriquer un faux contact.

**Accroche** : HE MISSED?
**Retournement** : THE KUNAI WAS THE PLAN.
**Contre** : NEJI SAW IT.
**Fin** : WOULD YOU COUNTER IT? / NINJA DUEL — ROBLOX
Anglais, textes courts, lisibles, jamais plus de deux lignes à l'écran.

## 3. Storyboard maître — durée 17,5 s, 1080×1920
Ces bornes sont des objectifs de montage, à ajuster sur le frame précis de l'action. Le hook est un flashforward ; les plans suivants montrent le déroulement réel et cohérent.

| Timecode | Shot | Cadrage et mouvement | Texte et sound design |
|---|---|---|---|
| 00:00–00:01.15 | A HOOK | Gros plan bas sur le kunai marqué planté près de Neji, profondeur de champ légère ; motion déjà visible | HE MISSED? dès image 1 ; bref tintement métallique |
| 00:01.15–00:03.70 | B THROW | Plan latéral à deux, Minato lance réellement son kunai en courant ; Neji visible et trajectoire compréhensible | Un seul cut sec ; lancer + souffle |
| 00:03.70–00:05.60 | C BAIT | Angle de Neji, Minato à distance, Neji s'avance ou prépare une réponse | WATCH THE KUNAI (facultatif) ; tension monte |
| 00:05.60–00:08.20 | D TELEPORT | Minato active le vrai FTG sur la marque, disparition puis réapparition dans un nouvel angle ; les deux dans le cadre | whoosh distinctif, coupe sur disparition, pas de faux coup |
| 00:08.20–00:10.25 | E ATTACK | Plan rapproché à deux, vrai coup de Minato après l'arrivée | pas de faux hit ; zoom keyframe léger si nécessaire |
| 00:10.25–00:13.10 | F COUNTER | Neji déclenche Rotation et repousse / pare le coup réellement | silence de 0,15 s juste avant, puis impact lourd ; ralenti très bref si fluide |
| 00:13.10–00:15.20 | G AFTERMATH | Plan large : personnages espacés, Neji prêt, Minato a changé d'angle | NEJI SAW IT. |
| 00:15.20–00:17.50 | H CTA | Plan court de la véritable arène avec titre clair | NINJA DUEL / PLAY ON ROBLOX / WOULD YOU COUNTER IT? |

**Garde-fou de mise en scène :** pas de victoire ou KO artificiel ; si le jeu ne donne pas réellement un contre lisible, le film DOIT se terminer sur le FTG surprenant, en cliffhanger « WOULD YOU HAVE SEEN IT? » (12–14 s), plutôt que simuler une mécanique. Conserver une capture continue avec HUD comme preuve. Les gros plans refilmés peuvent être des reprises de la même action, jamais une preuve mensongère d'un PvP réel.

## 4. Méthode de capture — exécuter dans cet ordre
### Préflight (une seule fois)
1. Ouvrir le HEAD du jeu sur sa vraie branche (non media-clips). Relever commit, nom de build, fps approximatifs, conditions (Studio / Roblox live) ; V39 test n'est pas automatiquement V39 publié.
2. Avec Minato et Neji, enregistrer UN échange brut avec HUD à vitesse normale qui prouve marque → téléport → frappe → Rotation. Idéal : 2 comptes/personnages humains ; sinon pilote IA et scène déterministe en Studio, en l'indiquant honnêtement. Tester collision, terrain, distance et cooldown avant de commencer les prises.
3. Si scénario impossible, NE PAS modifier le moteur pour la vidéo. Utiliser le plan B précédent ; documenter ce qui manque.
4. Tester un premier recadrage vertical 9:16 avant de filmer tous les plans : avec un écran 16:9, les deux ninjas peuvent sortir du cadre. Préparer l'angle pour que le point important reste dans la zone centrale.

### Couvrir les 8 plans
- Capture sans HUD pour les rushes ; capture avec HUD séparée uniquement pour la preuve.
- 2 prises utiles par plan A à H, avec positions/spawn, orientation et repères stables. À chaque prise : 2 s avant et 2 s après l'action pour le montage ; précompte oral non enregistré / coupé.
- A : caméra basse, champ ~40–50° ; B et F : champ moyen ~55–65° et deux corps entièrement visibles ; D : diagonal, angle qui révèle la destination du kunai. Valeurs indicatives, adapter.
- Lors d'un film multi-angle : refaire la séquence avec mêmes actions, ne pas essayer de « suivre » un duel chaotique à la souris en temps réel. Filmer le mouvement puis découper.
- Rechercher silhouette visible + trajectoire lisible, pas une accumulation de VFX. Aucun plan statique >1,2 s, sauf fin CTA.

### Outils à utiliser, avec sources officielles
**1. Roblox Freecam** pendant Play/Test Studio ou en client avec droits : Left Shift + P, masque le HUD, caméra libre, cadrage, zoom/FOV, roll, suivi, effets légers selon IAS. https://create.roblox.com/docs/workspace/camera/free-camera . Si les options avancées exigent IAS, **ne pas modifier le produit publié juste pour tourner** : utiliser freecam basique ou environnement de test, sans casser les contrôles V39.

**2. OBS Studio** : https://obsproject.com/ et https://obsproject.com/kb/standard-recording-output-guide . Enregistrer en local à 60 fps si stable (sinon 30 constants), résolution source 1920×1080 minimum, bonne qualité, format MKV puis remux MP4 ; enregistrer audio jeu séparé du micro. Mettre les notifications du bureau en pause et cacher le curseur si possible.

**3. CapCut Desktop** (option par défaut) : https://www.capcut.com/ . Keyframes de cadrage : https://www.capcut.com/resource/how-to-add-keyframes-in-capcut . Courbe de vitesse : https://www.capcut.com/resource/how-to-do-velocity-on-capcut . Le CM doit livrer aussi le projet éditable, pas seulement une vidéo exportée.

**4. DaVinci Resolve** en alternative, seulement si le CM maîtrise déjà mieux le montage/couleur/son : https://www.blackmagicdesign.com/products/davinciresolve . **5. FFmpeg** pour remux, format, recadrage et inspection, pas comme substitut au storytelling : https://ffmpeg.org/.

**Important :** le dépôt gameplay possède games/ninja-duel/tools/studio/probes/film_record.luau (pose recorder, **sans VFX**), side_camera.luau (diagnostic) et Server/DevFlight.luau (télémétrie). Ce ne sont PAS des exports marketing finaux ; ne pas confondre ces outils de QA avec une caméra de tournage. VFX Studio mentionné dans une autre demande n'est ni une caméra ni un monteur.

## 5. CapCut : la recette concrète, pas « monte ça bien »
1. Projet 9:16, 1080×1920, 60 fps si rushes 60 stables, sinon 30 fps cohérents. Import A_hook, B_throw, C_bait, D_teleport, E_attack, F_counter, G_after, H_cta.
2. Poser les marqueurs sur **projectile, disparition, réapparition, frappe et Rotation**. Monter les huit plans suivant le tableau ; couper sur le mouvement (hard cut), pas de transitions de template. Tolérance de montage ±0,25 s si besoin de lisibilité.
3. Si source 16:9, utiliser la propriété Position/Scale et deux keyframes pour recentrer le sujet dans le crop vertical ; ne couper ni kunai ni bras actifs.
4. **Une seule courbe de vitesse** sur F si utile : 1× → 0,7× pendant 0,2–0,35 s → 1× au contact. Si ça devient saccadé, supprimer le ralenti. Eventuellement un freeze bref 0,1 s sur la marque au hook.
5. Audio en pistes distinctes : musique de tension discrète, métal du kunai, whoosh spatial FTG, rotation/impact, audio original du jeu. Laisser 0,1–0,2 s de contraste sonore avant la Rotation ; baisser la musique d'environ 10–15 dB lors des impacts ; éviter saturation.
6. Texte maximum 2 lignes, 1 police + 2 couleurs. Safe zones haute/basse adaptées au TikTok UI. Aucun écran titre au début, aucun élément debug, pas de transition « glitch » toutes les 2 s.
7. Correction colorimétrique subtile (silhouette et contrastes lisibles), pas de bloom excessif, de flash blanc long, de shake ou de flou généralisé. **Impact au contact, pas effet qui le cache.**
8. Export **H.264 MP4 / AAC / 1080×1920**, 12–18 Mbps cible si 60 fps, vérifier le fichier entièrement sur téléphone, en son et en muet. Tester à luminosité moyenne.
9. Musique : utiliser un son composé spécialement ou légalement licencié **pour chaque réseau**. TikTok pro recommande sa Commercial Music Library (pas automatiquement licenciée pour YouTube) : https://ads.tiktok.com/help/article/commercial-music-library?lang=en . Ne pas ajouter des extraits officiels de Naruto ni leur OST non autorisé. Risque IP existant sur personnages, à traiter indépendamment.

## 6. Assets et livrables — 1 film, pas encore 3 par jour
Sur le poste de montage, dossier :
- 00_PROOF/UNCUT_GAMEPLAY_WITH_HUD.mp4 (preuve réelle, pas la version promo)
- 01_RUSHES/A_hook_take1.mp4 ... H_cta_take2.mp4
- 02_AUDIO/SOURCES_AND_LICENSES.md
- 03_EDIT/CapCut_project + NOTES.md
- 04_EXPORT/NINJA_DUEL_KUNAI_TRAP_MASTER_9x16.mp4
- 04_EXPORT/NINJA_DUEL_KUNAI_TRAP_CLEAN_9x16.mp4
- 04_EXPORT/NINJA_DUEL_KUNAI_TRAP_COVER.png
- 05_REVIEW/QUALITY_GATE.md

Ne pousser sur **media-clips** que master final, cover et rapport si les fichiers sont acceptables ; préserver les anciens clips, ne pas multiplier les rushes de 50 Mo sur GitHub si inutile. Ne pas affirmer que des exports existent avant de les produire.

**Qualité / stop-or-go** :
- [ ] marque/FTG/attaque/Rotation fonctionnent réellement dans le build capturé (ou fin de cliffhanger honnête) ;
- [ ] hook fort dans la première seconde, le kunai est visible sur téléphone ;
- [ ] un inconnu comprend les causes et le contre en version muette, sans devoir lire un pavé ;
- [ ] audio lisible, timing des contacts précis, pas de logos/intros superflus ;
- [ ] aucune perte de cadre pendant l'action, aucun HUD de debug ou curseur ;
- [ ] au moins 1 visionnage CM + 1 visionnage d'une personne non impliquée ; correction des 3 défauts les plus gênants ;
- [ ] rapport note SHA, nom build, méthode d'enregistrement, ce qui est vraiment jouable, sons et licences, tailles/fichiers, statut READY FOR USER REVIEW ou BLOCKED.

**Pas d'upload TikTok/YouTube/Discord sans accord.** La version MASTER doit être soumise à l'utilisateur pour validation d'abord.

## 7. Après validation seulement : trois contenus tirés du même tournage
- **Combat/situation 7–9 s** : kunai → warp → contre → question « WOULD YOU COUNTER? ».
- **Perso 10–12 s** : Minato + « HE DOESN'T JUST THROW KUNAI » + deux réels usages de ses marques (si prouvés) ; distinguer mockup du gameplay.
- **Devlog 20–30 s** : extrait vieux WhoWins / gameplay brut → capture Freecam / CapCut → avant-après → « IS THIS BETTER? ». Pas de fausse histoire de progrès : montrer une vraie différence.

**Principe de prod :** le CM filme une fois pour alimenter les trois catégories. Pas trois tournages journaliers imposés. Le premier résultat à livrer est ce **film unique de qualité supérieure** ; ensuite seulement scaler.

## 8. Responsabilités et remontée des blocages
Le CM réalise : préflight → captures → montage → mixage → cover → validation muette et sonore → rapport → commit média. Il ne change pas les systèmes de combat ni les autorisations Roblox. Toute dépense, nouveau plugin payant, diffusion publique ou changement produit exige un accord distinct. Si les contrôles/IA/Studio bloquent un plan, rapporter **le bug et l'alternative filmable**, ne pas laisser le projet s'enliser dans une refonte technique.

**C'est un brief de réalisation, pas une simple liste d'idées. Priorité : une scène de ruse de ninja mémorable, courte, authentique, qui n'existe pas déjà dans mille TikTok.**
