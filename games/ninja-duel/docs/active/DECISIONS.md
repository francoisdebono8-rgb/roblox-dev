# Décisions en vigueur

Propriétaire unique : arbitrages produit, périmètre et responsabilités. Les faits d’implémentation sont dans [CURRENT_STATE](CURRENT_STATE.md), les tâches/critères dans [MASTER_BACKLOG](MASTER_BACKLOG.md), les protocoles dans [EXECUTION_RULES](EXECUTION_RULES.md). Priorité : demande utilisateur actuelle > décision datée applicable ; signaler un conflit non résolu, sans transformer une recherche en approbation. L’historique complet DEC-001..015 est [conservé](../archive/audits/2026-10-17/before-active/DECISIONS.md).

| ID | Disposition actuelle |
|---|---|
| DEC-001 | Ancienne limite CORE4 et Gaara caché remplacée par DEC-016. Ne pas réactiver cette restriction. |
| DEC-002 | Motion Lab sous le jeu ; adapter Lab → jeu uniquement ; exports inertes jusqu’à intégration choisie. |
| DEC-003 | Jeu et plugins Forge isolés ; aucun import croisé, même via shared. |
| DEC-004 | Répartition historique Codex/Claude remplacée et précisée par DEC-019. |
| DEC-005 | Capacités sourcées, étiquettes `CANON_YOUNG`, `PLAUSIBLE_YOUNG`, `GAMEPLAY_LIBERTY`, `REJECT_ADULT_ONLY` ; interprétation par stade DEC-013. Aucun nom dans une recherche ne prouve une capacité approuvée. |
| DEC-006 | Grammaire commune, identités distinctes et contrôles simples ; réutiliser les familles réelles, pas de frameworks anticipés ou de clones de moveset. |
| DEC-007 | Preuves techniques, Studio et jugement humain distincts ; renforcé par DEC-017. |
| DEC-008 | Exigences cumulatives et provenance conservée ; seules les sept sources actives commandent l’exécution. Une archive ne lance jamais une mission. |
| DEC-009 | Gel documentaire du 12 octobre historique, non applicable à la phase Claude déjà approuvée. Aucun nouveau gameplay autorisé à Codex par l’audit. |
| DEC-010 | Ancien report général du PvP/roster/publication remplacé par DEC-012, DEC-016 et DEC-018. League/Path complets et MMO hors jalon alpha. |
| DEC-011 | Anciens apports Codex audités/repris partiellement ; aucune fusion globale de branches historiques exigée. Conserver les fondations réellement intégrées. |
| DEC-012 | Convergence approuvée le 16 octobre : combat, PvP 1v1 serveur, progression par arbres/budgets, IA à budget et roster ouverts. Pas de réécriture gratuite. |
| DEC-013 | Stade jeune/prodige intéressant avant escalade adulte, pas limite universelle 12–14 ans. Échelle endgame exclue ; noms adultes de Minato tolérés provisoirement par l’utilisateur le 16 octobre. Ne pas bloquer la breadth sur un débat canon secondaire. |
| DEC-014 | Confirmation des combos, intentions tolérantes, relance accessible, identités visibles et chakra comportemental maintenus. Son ancien gel roster n’est plus applicable (DEC-015/016). |
| DEC-015 | Autonomie de Claude dans le périmètre approuvé ; stade Chūnin agrandi, obstacles justifiés. Ancienne limite de 1–2 fighters de stress remplacée par DEC-016. |

## DEC-016 — 20 jouables breadth-first

Décision utilisateur, commit `f23c454` (texte [préservé](../archive/missions/ROSTER_20_BREADTH_PASS.md), ancêtre du HEAD audité ; date exacte à lire dans Git) : viser **20 personnages réellement jouables au total**. Partir des six initiaux ; Claude choisit les suivants selon iconicité, diversité et besoins moteur, sauf lorsque l’utilisateur verrouille explicitement la composition du roster (voir DEC-022). Les pools 25/~32 et la cible intermédiaire 8–10 restent historiques. Ordre : Tier A pour tous → identité Tier B par familles → polish Tier C. Les gates détaillés appartiennent à CHR-EXT-002. Pas d’extension au-delà de vingt dans cette phase.

## DEC-017 — Studio obligatoire

Décision utilisateur, commit `3174e38`, [texte préservé](../archive/missions/STUDIO_VALIDATION_RULE.md) : toute fonctionnalité player-facing doit être exercée dans le build réel en Studio avant validation, y compris l’existant encore uniquement headless. Sans cette preuve, statut `IMPLEMENTED / NOT YET STUDIO-VALIDATED` ; aucune clôture globale « done ». Le protocole et les dimensions de preuve appartiennent à EXECUTION_RULES. Le ressenti humain reste une dimension distincte.

## DEC-018 — Alpha publique et online réel

Décision utilisateur, commit `c38825d`, [texte préservé](../archive/missions/PUBLIC_ALPHA_AFTER_ROSTER_20.md) : dès les vingt baseline suffisamment jouables et le combat online stable, viser **l’alpha publique Roblox / combat test**. Online signifie le vrai flow d’une expérience publiée : rejoindre, trouver un adversaire, sélectionner, combattre, finir, rematch/requeue et quitter/rejoindre proprement. Deux clients Studio sont une étape technique, pas la validation du produit online. Ne pas attendre VFX premium, équilibre final, progression complète ou monétisation. Gates minimum dans NET-001 et REL-001. Cette mission documentaire ne réalise aucune publication.

## DEC-019 — Boucle utilisateur / ChatGPT / Claude / Codex

Décision utilisateur du **17 octobre 2026**, [mandat préservé](../archive/requests/2026-10-17-documentation-brain.md) : **Utilisateur ↔ ChatGPT → décisions dans le repo → Claude implémente → Studio valide → Codex audite → Claude corrige/continue.** Claude reste l’implémenteur principal. Codex est reviewer technique, architecte et mainteneur continu du cerveau documentaire ; il audite après gros merges, dérive d’architecture, nouvelles décisions et avant roster 20/online public/alpha. Il ne crée pas de branche gameplay concurrente. L’audit courant ne change ni runtime, ni équilibrage, ni systèmes.

## DEC-020 — Une seule couche opérationnelle

Même mandat du 17 octobre : exactement VISION, DECISIONS, CURRENT_STATE, MASTER_BACKLOG, SINCE_LAST_CLAUDE, EXECUTION_RULES, ENGINEERING_REVIEW dans `docs/active`. Une information a un propriétaire unique. Les guides techniques documentent commandes/formats ; les recherches proposent ; les archives prouvent l’historique. Aucun de ces dossiers ne définit un second plan actif. ENGINEERING_REVIEW est court, remplacé à chaque audit, limité aux six rubriques demandées. Les audits précédents restent dans Git/archives, jamais empilés dans ce fichier.

## DEC-021 — Roadmap large, fenêtre d’exécution étroite après roster 20

Décision utilisateur du **17 octobre 2026** : une fois les **20 combattants Tier A réellement jouables**, arrêter l’expansion du roster et passer à une convergence horizontale sur les vingt. La roadmap globale reste visible, mais Claude ne doit exécuter qu’**un bloc principal à la fois**, avec critères de sortie explicites, puis s’arrêter pour rapport/synchronisation avant le bloc suivant. Ne pas lancer simultanément plusieurs grands chantiers sous prétexte qu’ils figurent dans la roadmap.

Ordre cible après roster 20 : **(1) stabilisation combat + combo/animation/réactions/hit feel transversaux sur les 20 ; (2) couche chakra/éléments/outils et afflictions réellement comportementales ; (3) pass identité combattant sur les 20 ; (4) structure compétitive + arène/mouvement/neutral/défense ; (5) online Roblox réel + flow d’alpha publique.** Le premier bloc post-roster est prioritaire : bugs combat, fiabilité des chaînes/routes/air/knockback/guard/dodge/substitution, dégâts/réactions/impacts/transitions, puis validation Studio sur l’ensemble du roster. Le principe est breadth-first à chaque passe : **20 stables → 20 bons en combo/animation → 20 intégrés au chakra → 20 identitaires → polish**, jamais finir un seul personnage à 100 % pendant que les autres restent au stade prototype.

## DEC-022 — Composition verrouillée des 10 prochaines places et règle « version jeune »

**Composition historique remplacée par DEC-026 pour la cible de design.** Le runtime conserve encore les anciennes entrées tant que la migration n’est pas faite. La règle de stade reste applicable avec l’extrapolation raisonnable précisée par DEC-026.

Décision utilisateur du **17 octobre 2026** : les dix places restantes du roster initial sont désormais **verrouillées** sur **Shisui, Orochimaru, Haku, Kimimaro, Nagato, Sasori, Deidara, Killer Bee, Zabuza et Kabuto**. Elles remplacent les lots prévus Sakura/Choji/Kiba/Shikamaru/Shino/Kisame et toute autre proposition non encore codée. Ne pas commencer ces anciens lots.

La sélection peut venir de **toutes les époques de Naruto**, mais chaque combattant est représenté dans une **version jeune/prodige cohérente avec ce qu’il savait réellement faire à ce stade**, pas avec l’arsenal de sa version adulte finale. Ne pas importer par défaut les pouvoirs adultes pour rendre un kit plus spectaculaire. La profondeur peut venir du corps, des armes, du mouvement, des transformations déjà acquises, des ressources et des interactions système.

Les combattants d’un même clan peuvent partager une grammaire, des assets ou des familles techniques, mais ne doivent pas devenir des clones de gameplay. Différencier au minimum plusieurs axes parmi neutral, mobilité, défense, routes, ressource, portée, tempo, outils et éveil. Enfin, **le nombre de jutsus n’a pas à être identique entre les personnages** : refléter l’arsenal jeune réellement connu et équilibrer les décisions utiles, pas le nombre de boutons. Un personnage pauvre en ninjutsu (ex. Lee) doit gagner sa profondeur par le taijutsu, le mouvement, les routes et ses mécaniques propres plutôt que par des techniques inventées.

## DEC-023 — Expérience joueur : hub-tournoi compact, combat immédiat

Décision utilisateur du **17 octobre 2026** : l’expérience finale ne doit être ni un fighter composé uniquement de menus, ni un hub Roblox ouvert rempli de quêtes/PNJ/temps mort. Le joueur arrive dans une **enceinte compacte de tournoi des jeunes prodiges**, inspirée de l’ambiance d’une salle d’examen avant l’épreuve. Cet espace physique relie entraînement, progression, tournoi, classement et statut social, mais l’accès au combat doit rester quasi immédiat.

Première session cible : courte mise en scène → choix du premier prodige parmi une sélection limitée → tutoriel court → duel IA → retour libre au hub. Ensuite, accès direct et réversible à Practice, progression, duel/tournoi et menus. Les menus restent rapides et disponibles partout ; le monde sert au contexte, à la présence des autres joueurs et à la lisibilité de la progression. Aucun grind narratif artificiel ni mission « tue X ennemis » obligatoire.

## DEC-024 — Progression double et tournoi standardisé

Décision utilisateur du **17 octobre 2026** : chaque combattant possède un **arbre de compétences propre** alimenté par des points de progression, complété par des **maîtrises gagnées par pratique réelle**. Les points représentent des choix de build ; les maîtrises représentent ce que le joueur sait réellement exécuter. Les maîtrises doivent récompenser l’usage pertinent/qualitatif d’une mécanique, pas le spam répétitif, et peuvent conditionner ou modifier certains nœuds avancés.

Le Practice permet d’essayer **les 20 combattants**, y compris ceux non débloqués, afin que l’achat/déblocage ne se fasse pas à l’aveugle. Pour le **tournoi/ranked principal**, le joueur ne peut sélectionner que parmi les combattants débloqués sur son compte, mais la puissance permanente est neutralisée : chaque combattant reçoit un **budget de points tournoi identique/standardisé**, redistribuable dans le même arbre. Plusieurs builds tournoi peuvent être sauvegardés par combattant. Des événements spéciaux peuvent ouvrir temporairement tout le roster, sans changer la règle du ranked principal.

Conséquence économique : la monétisation future peut être **pay-to-time** (débloquer plus vite des combattants/progression/confort/collection), jamais pay-to-win dans le tournoi principal. La valeur compétitive vient de la connaissance du personnage, de son arbre, des matchups et de l’exécution, pas du temps ou de l’argent investi dans des statistiques permanentes.


Précision utilisateur du 17 octobre, [demande architecture](../archive/requests/2026-10-17-progression-mastery-architecture.md), portée DEC-024 : **niveau 1 = identité complète, profondeur incomplète**. Les arbres ne réparent pas les kits et privilégient des décisions/variantes qualitatives ; les maîtrises mesurent fréquence, réussite, variété et contexte, jamais une preuve achetable ni un compteur de spam. Codex prépare l’architecture suivante, sans gameplay et sans détourner le roster V1 prioritaire. La [proposition spécialisée](../systems/PROGRESSION_MASTERY_PROPOSAL.md) reste **à valider** : taille des arbres, budgets et surtout prêt des prérequis de maîtrise/nodes en tournoi ne sont pas décidés par ce document. Les choix `USER DECISION REQUIRED` ne deviennent pas des règles par leur présence dans une spec.

## DEC-025 — Fiches personnages et identité perceptible

**Format et roster des premières fiches remplacés par DEC-026.** La demande d’identité perceptible reste valide ; les anciennes fiches sont historiques.

Demande utilisateur du **18 octobre 2026**, [texte conservé](../archive/requests/2026-10-18-character-profiles.md) : établir une fiche pour chacun des vingt personnages couvrant vêtements/silhouette, nature et usage du chakra, capacités possibles, moveset, vitesse/déplacement, réservoir, contrôle et habiletés. Le retour joueur signale combos trop similaires, dash rouge commun et identité/chakra insuffisamment perceptibles ; Shisui doit notamment évoquer mirages et mobilité particulière, pas seulement téléport/frappe.

Un kit câblé ou un effet déclenché ne valide pas cette expérience. Les fiches distinguent **code actuel**, **cible de design proposée**, **preuve de période** et **validation Studio**. Ne pas confondre nature élémentaire, forme/propriété, réserve/contrôle, source bijû ou dōjutsu. Les chiffres du code ne sont pas des statistiques canon ; les valeurs de design relatives ne modifient aucun équilibrage.

L’[index des vingt fiches](../characters/ROSTER_20.md) sert de référence spécialisée ; les missions/critères restent dans MASTER_BACKLOG. Cette demande autorise la préparation documentaire, pas vingt refontes simultanées ni un changement de séquence DEC-021. Les gestes précis, variantes et ratings proposés ne sont pas tous des arbitrages validés par l’utilisateur. Conserver les incertitudes d’âge/source sans modifier silencieusement le runtime.

## DEC-026 — Roster cible et Character V1 Combat Bibles

Décision utilisateur du **18 octobre 2026**, [brief intégral](../archive/requests/2026-10-18-character-v1-combat-bibles.md). Cible de design : **Itachi, Shisui, Sasuke, Madara enfant, Hashirama enfant, Hiruzen enfant, Minato, Kakashi, Naruto, Gaara, Rock Lee, Neji, Haku, Kimimaro, Nagato, Orochimaru, Sasori, Deidara, Killer Bee, Zabuza**. Madara/Hashirama/Hiruzen remplacent Hinata/Temari/Kabuto dans la cible ; ne pas confondre cette décision avec une migration déjà faite du runtime. Remplace la composition de DEC-022 et les premières fiches DEC-025 sur ces points.

**V1 personnage = identité complète par corps, mouvements, animations, coups/combos, réactions/défense, armes physiques/naturelles et signatures fondamentales.** HUD masqué, reconnaissance en quelques secondes. Les vingt ne doivent pas partager jab→jab→kick avec seulement des jutsus différents. Les pouvoirs dans les gestes (os, sable, clones, forces, mirages) et armes fondamentales font déjà partie de V1. En revanche arbre complet, maîtrise acquise, chakra global final, armes globales finales, sound/VFX/balance finaux ne sont pas requis. Cela précise/remplace l’ancien plancher TierA de DEC-016 et le placement de l’identité fondamentale après les systèmes finaux ; conserver de DEC-021 le travail breadth-first, un gros bloc à la fois et rapport/synchronisation.

Concept : grands prodiges de générations différentes vers12–14ans ; canon principal d’abord, puis anime/romans/databooks/statements, puis extrapolation fan cohérente déclarée quand l’enfance est peu documentée. Pas d’arsenal adulte importé, mais ne pas dépouiller les prodiges de leur identité. Madara n’est pas EMS/Rinnegan, Hashirama n’est pas sa prime, Hiruzen n’a pas tous les jutsus. **Bee multi-sabres** est exigé par le brief malgré l’ancienne exclusion documentaire ; **Kimimaro squelette qui fabrique ses armes dans les gestes**, pas Jedi à lame blanche. Sasori alterne maître/puppet, Deidara pose/repousse, Nagato minimise ses gestes, Shisui porte Shunshin dans le corps entier, Gaara reste calme et Naruto intègre ses clones aux routes.

Livrable documentaire : vingt [Combat Bibles](../characters/ROSTER_20.md), douze rubriques de chorégraphie et appendices A–E (réemploi, unités uniques, priorité de design, actuel→cible, lots proposés). Moteurs/hooks restent communs ; aucune branche spéciale avant premier hit confirmé ; contre-jeu, anti-infini et manette obligatoires. Viser réemploi réel sans uniformiser le rendu, pas300animations uniques. Les temps/portées/chorégraphies proposés sont des cibles de production à tester, pas équilibre final ni faits canon.

**Mission Codex = design uniquement.** Ne pas interrompre le bloc Claude en cours, coder les fighters, migrer les IDs/menu, reconstruire les builds ou lancer les hooks futurs. Audit initial code sur le vrai HEAD ; les trois nouveaux absents sont marqués absents. Tâches/ordre d’ouverture dans MASTER_BACKLOG, état/proof dans CURRENT_STATE ; les lots de design ne deviennent pas tous actifs simultanément.

## DEC-027 — Ninja Embodiment : le joueur devient le ninja

Demande utilisateur du **25 octobre 2026** (commits `e72cd9c`, `072831c`, `cd92301`), textes intégraux conservés : [mission](../archive/requests/2026-10-25-ninja-embodiment-game-completion.md) et [règle universelle normative](../archive/requests/2026-10-25-ninja-embodiment-universal-system-rule.md). Remplace toute petite passe de convergence comme bloc courant ; le travail de convergence (`e3b2932`…`84119ea`) est conservé.

Thèse : le combat n'est plus un moveset (Light1→2→3, routes, Heavy/Launcher, Pursuit, Air1/2, Slam + slots) mais un corps, une réserve de chakra, une perception, des objets et un monde réactif avec lesquels le joueur improvise. **Construire l'univers une fois, décrire ce que chaque ninja sait y faire** : résolveur d'action contextuel universel, agence du défenseur globale, langage de chakra commun, couche monde/matériaux autoritaire serveur, primitives persistantes et perception partagées ; pas de switch `fighterId`, pas de destruction par technique, pas plus de boutons de cooldown, pas de cinématiques. Sasuke/Minato/Kimimaro sont trois tests d'architecture, pas le périmètre ; le transfert doit être prouvé sur Gaara, Haku ou Itachi, Zabuza, Lee, Neji, Naruto. Gates : Boxer Test et test de liberté de 3 minutes en Studio ; autorité serveur, builds et online préservés ; plafonds de performance documentés. Le dépôt `izzyfrm/roblox-ai` est une bibliothèque de références visuelles facultative, jamais une source d'assets copiés.

Ordre : audit (fait le 25/10, [rapport](../reports/ninja-embodiment-2026-10-25/AUDIT.md)) → blockers → résolveur → défenseur → chakra → monde → tranches verticales → généralisation → portage → tests 3 min/Boxer → online/perf → polish → docs. Travail et critères dans MASTER_BACKLOG (EMB-001…).

## DEC-028 — Animation de production dans Blender, puis maîtrise réelle du métier

Demandes utilisateur des **26 et 27 octobre 2026**, textes intégraux : [Blender-first](../archive/requests/2026-10-26-blender-first-production-pipeline.md) (`72054c1`) et [maîtrise de l'animation](../archive/requests/2026-10-27-animation-mastery-combat-breakthrough.md) (`6b6fe95`), **activée le 27/10 à 22 h 22** (« fais intégralement le dernier commit poussé par ChatGPT »). Retour de jeu du 27/10 à 0 h 08 : les coups paraissent pensés seuls, pas comme le geste d'un joueur qui se déplace et attaque.

Blender produit le corps (locomotion, sauts, frappes, réactions, préparations, sorties) ; Roblox/Luau garde le déplacement réel, l'intention, la direction, l'élan, les collisions, les touches, le chakra, les annulations et l'agence du défenseur (§10 : jamais de cinématique verrouillée). Python sert au pipeline (export, cuisson, films), pas d'animateur principal : les poses clés, intermédiaires, contacts et courbes sont posés dans Blender sur un rig de contrôle et le .blend est la source. Aucun effet visuel n'est ajouté pour sauver un mouvement faible (test sans maquillage, §14). Gate de compétence en six exercices avant production de masse ; Sasuke puis Minato comme preuves ; la méthode (§21) devient une règle permanente pour les vingt fighters. Travail et critères : ANIM-001…ANIM-006 dans MASTER_BACKLOG.


## DEC-029 — Cible de fluidité : la vidéo de référence de l'utilisateur (28/10)

Demande utilisateur du **28 octobre 2026, 2 h 09** : « je veux que l'animation en général soit comme la vidéo Itachi de référence » puis, vidéo jointe (démo « 1 Tomoe Sharingan », TikTok @piercevile, tags deepwoken/rintama) : « regarde la fluidité, tout est smooth ; l'autre vidéo c'était surtout pour les techniques ». La copie `reference/itachi-quality-benchmark.mp4` du dépôt est tronquée (15 Ko, illisible) ; la vidéo des techniques est la vitrine Itachi de Shonen Unleashed (jointe le 26/10).

Décision : la fluidité de cette vidéo est la cible du corps pour tout le roster. Elle se traduit en règles mesurables :
- aucun membre ne saute : une articulation authored tourne au plus à 1 500°/s (≈ 25° par image à 60 Hz), et les transitions sont inertialisées sur 0,05 à 0,15 s ;
- au-delà d'un sprint (55 studs/s) et sur toute téléportation, le corps laisse des copies sombres translucides et des traits de vitesse, comme dans la référence ;
- des arcs fins suivent les mains et les pieds pendant une frappe ;
- une frappe lancée en mouvement garde l'élan (vitesse ramenée en 0,1 s vers 14 studs/s au lieu d'un freinage à 12 en une image) ;
- la caméra se tient près, derrière l'épaule (distance ≈ 10,5, hauteur 3,4).

La règle de la mission ChatGPT « ne pas cacher un corps faible derrière des effets » reste valable : les traînées n'apparaissent que là où l'œil ne peut pas suivre le corps. Le corps lui-même doit être fluide (premier point).

**Révision du 28/10, 12 h 08** (retour utilisateur : « je ne vois pas de différence… anime sur Blender… les mouvements doivent être amplifiés… on ne peut pas sortir de kunai, salto et slash pas fluides ») :
- les coups se dessinent d'abord comme des POSES amplifiées dans Blender (hanches qui tournent de 60 à 90°, buste qui dépasse, bras en dernier, arcs larges, overshoot tenu), vérifiées sur les rendus de la caméra de jeu et d'une caméra latérale ; le fichier `NinjaDuel_Sasuke_v3.blend` est la source ;
- Sasuke frappe au kunai (prise directe, même soudure dans Blender et dans le jeu) ; son Heavy est un salto avant suivi d'un coup de taille vers le bas ;
- le plafond de vitesse authored passe à 2 200°/s pour les membres et 3 600°/s pour le Root (un salto n'est pas un « pop ») ; un pied posé par un clip authored est exact (la jambe suit les hanches sans plafond), sinon il glissait vers le sol à l'atterrissage.

## DEC-030 — Autonomie de Claude et feuille de route par parties jusqu'à la bêta en ligne (28/10)

Demande utilisateur du **28 octobre 2026, 13 h 18** : « pour la suite du projet, tu travailles en autonomie avec pour but l'objectif final visé du jeu. Mais tu choisis, toi, tout ce qu'il faudrait faire pour atteindre ça. Parce que j'ai l'impression qu'on ne travaille pas de la bonne méthode. Donc peut-être qu'il te faut plus de liberté. Tu constituerais partie par partie, puis tu me ferais voir à chaque partie. […] On parle de la globalité du jeu : revoir chaque perso un par un, chaque animation, chaque attaque, chaque jutsu, chaque taijutsu, etc. Plus après, avec l'idée d'un mode en ligne, d'une bêta jouable, d'abord ça. »

Décision. Claude choisit le contenu, l'ordre et la méthode, sans redemander d'autorisation par bloc. Il présente une partie terminée à la fois, que l'utilisateur joue lui-même. La cible finale est une **bêta jouable en ligne** : DEC-018, REL-001 et NET-001 restent les critères de publication.

Diagnostic de méthode (pourquoi « on ne voit pas de différence ») :
- les dernières passes ont amélioré des mesures (degrés par image, glissements de pied) que le joueur ne voit pas ;
- elles ont touché tout le roster en surface au lieu d'amener un personnage au niveau de la référence ;
- dix-huit des vingt combattants bougent encore par code procédural (`Wave*Motion`, `VelmoraMotionEngine`) plutôt que par des clips dessinés.

Méthode retenue :
- **un personnage à la fois**, terminé de bout en bout avant de passer au suivant ;
- tout son corps est dessiné dans Blender : locomotion, chaîne, Heavy, routes, air, lancers, chaque jutsu, garde, esquive, réactions, intro et victoire ;
- ses effets sont revus sur ce corps, et son IA sait utiliser ce qu'il a ;
- Claude juge d'abord le résultat **comme un joueur**, sur des images du jeu en mouvement (Studio). Les tests et les mesures restent des garde-fous, pas la preuve.

À chaque partie, Claude remet :
- un fichier Studio jouable `Documents/Roblox/ND-PartieN.rbxlx` ;
- des planches Blender ou des captures de jeu ;
- une courte liste « quoi essayer, avec quelles touches ».

Feuille de route (ordre choisi par Claude, révisable selon les retours) :
- **Partie 0** — état des lieux joueur : chacun des vingt joué en Studio et capturé, défauts visibles listés par personnage ; outils de capture et de rendu prêts.
- **Parties 1 à 8** — les huit combattants de la bêta, dans cet ordre : Sasuke, Itachi, Minato, Naruto, Kakashi, Gaara, Rock Lee, Neji.
- **Partie 9** — socle commun revu en jeu : caméra, déplacement, garde et esquive, réactions, HUD, son, arène.
- **Partie 10** — boucle du joueur : écran d'accueil ou hub compact, sélection, tutoriel court, duel IA, rounds et revanche.
- **Partie 11** — en ligne : deux vrais clients, file d'attente et codes, latence, déconnexion. Publication privée, puis bêta.
- **Parties 12 et suivantes** — les douze autres combattants un par un, ajoutés à la bêta au fur et à mesure, au même niveau.

Le choix des huit de la bêta est fait sur deux critères : les plus iconiques, et ceux dont le runtime est le plus avancé. Les autres ne sont pas abandonnés : ils restent hors de la sélection de la bêta tant qu'ils n'ont pas atteint le niveau.

**Révision du même jour (15 h 01 – 15 h 12).**

Retours de l'utilisateur après la Partie 1a :
- « pas d'amélioration dingue » ;
- la fluidité des personnages et des mouvements reste le problème ;
- le kunai doit être un système pour tous, pas un coup de Sasuke : « tu ne penses pas assez en global » ;
- les animations actuelles sont « au rang de test » ;
- « finis les 10 parties, puis je corrigerai » ;
- toujours se référer aux références : autres jeux, vrais combats de Naruto, animation.

Ce qui change :
- **Le socle commun passe en tête (Partie 1).** Il comprend :
  - la réactivité, parce que le perso du joueur attendait le serveur 0,1 à 0,17 s : déplacement envoyé toutes les 80 ms, état à 15 Hz, lissage de 45 ms ;
  - le kunai pour tous ;
  - la locomotion et les impacts.
- **Les huit personnages viennent ensuite**, puis la boucle de jeu et le mode en ligne.
- **Les retours de l'utilisateur sont attendus à la fin des 10 parties**, pas entre chacune.
- **Codex sert d'assistant** à travers [CODEX_QUEUE](../tools/CODEX_QUEUE.md), sur des tâches qui ne touchent pas les fichiers en cours de Claude.

**Révision du même jour (16 h 55 – 17 h 13), après un vrai match observé.** [Rapport](../reports/observation-2026-10-28/REPORT.md).

L'utilisateur a joué deux rounds pendant que Claude enregistrait le match. Ses retours :
- approcher en courant envoyait toujours le coup de pied sauté, et l'adversaire loin ;
- en l'air, le coup lourd était une « pierre » qu'on peut répéter sans risque ;
- la liberté manque : infusions de chakra, techniques utilisables dans toutes les positions, Rasengan ou Chidori qu'on garde en main en courant ;
- pas de destruction ;
- les sols fissurés ressemblent à des décalcomanies, et tous les Katon se ressemblent ;
- la fluidité, c'est le suivi du mouvement ;
- « tu ne testes pas comme un joueur » ;
- garder les 10 parties, ajuster sans repartir de zéro, Claude choisit l'ordre.

Méthode désormais :
- chaque livraison passe par l'agent joueur (`tools/studio/probes/player_agent.luau`), qui joue comme un humain à la manette et mesure les répétitions, les coups qui ne s'enchaînent pas, les pressions refusées, les décollages et les blocages ;
- au fil des parties, un vrai match enregistré avec l'utilisateur.

Ordre ajusté :
- **Socle 2 (fait le 28/10)** : la course ouvre l'enchaînement ; le sprint de la manette s'arrête au repos ; saut + lourd = salto et coup de talon ; pressions gardées en mémoire au début de la récupération ; bot qui varie ; Rasengan et Lame de foudre tenus en main.
- **Partie 10, la boucle joueur**, reçoit en plus :
  - la destruction du décor et des fissures en relief ;
  - un Katon propre à chaque perso ;
  - les infusions de chakra généralisées ;
  - les techniques depuis toutes les positions ;
  - le combat aérien vivant.
- **Partie 11, en ligne** : inchangée.
- **Parties 2 à 9 (les persos)** : elles restent livrées ; chacune sera reprise sur match enregistré.


## DEC-031 — La liberté avant tout ; l'ultime reste la seule cinématique (03/11)

Utilisateur, 03/11 à 15 h 25 : « et aussi la liberté, parce que là pour l'instant on est sur du Storm total ». À la question sur les ultimes : « ça me dérange pas si c'est ponctuel, mais il faut que tout le reste soit libre ».

- **Les ultimes restent des cinématiques** (3,4 à 4 s), parce que c'est ponctuel : barre pleine, ouverture qu'on peut esquiver, une ou deux par match. Raté, l'ultime laisse une ouverture et vide la barre. Pas de raccourcissement : il faudrait refaire les clips.
- **Tout le reste devient libre** (priorité en tête de la feuille de route, avec la caméra et les freezes) :
  - plus de séquences qui bloquent les deux corps : Lotus, Rendan et les réveils deviennent des coups joués dans le combat ;
  - le corps ne se tourne vers l'adversaire que si le joueur verrouille ;
  - le dash, la poursuite et les plongées partent seulement si le joueur les demande ;
  - on sort d'une fin de coup en bougeant, en sautant ou en esquivant ;
  - les techniques marchent en l'air, en courant, depuis un mur.

## DEC-032 — Un jeu libre et vivant : Blender partout, chakra propre à chacun, combos libres, signes des mains (03/11)

Utilisateur, 03/11 à 17 h 15 : « ce qui manque au jeu, c'est beaucoup plus d'animation passée dans Blender, pour quasiment chaque situation [...] l'utilité du chakra, pour l'instant c'est nul [...] les combos sont très génériques [...] on devrait pouvoir varier plus qu'avoir 4 cases d'attaque comme dans Storm [...] il faudrait que ce soit libre [...] sois plus créatif et plus ambitieux, tu as les pleins pouvoirs ; si je ne suis pas d'accord, je te dis non ».

Plan (détail : document de projet `claude/plan-arene-des-prodiges-2026-11-03.md`) :
1. **Le corps** : pour les 8, déplacement (avec pas de côté et en arrière depuis la caméra libre), sauts (petit, normal, grand, super saut et double saut au chakra), réceptions et murs, dessinés dans Blender. Coups redessinés, avec un clip propre au coup chargé ; le piqué depuis un saut refait.
2. **Le chakra change le coup selon le perso** : foudre et feu de Sasuke, clones de Naruto, sable de Gaara, portes de Lee, points de chakra de Neji, corbeaux d'Itachi, marques de Minato, copie de Kakashi.
3. **Des combos libres** : léger, lourd, chargé, saut, dash et jutsu s'enchaînent dans tous les ordres pendant leurs fenêtres, avec des variantes de direction à chaque coup. Le rythme, la réduction des dégâts et la substitution gardent la défense possible.
4. **Plus que 4 cases** : des signes des mains (8 à 12 jutsu par perso), en gardant les 4 cases rapides et les variantes de situation.
5. **L'arène des prodiges** : répliques des rivaux, jury, arène qui réagit, tournoi, défis de maîtrise.

Ordre : 1 pour les 8 ; 2 et 3 sur Sasuke d'abord, testés par l'utilisateur ; puis 4, les 7 autres, 5.

## DEC-033 — Bêta d'abord : le lot B0 de l'audit produit, la v35 publiée après (04/11)

Décision utilisateur du **04/11 à 22 h 45**, sur l'[audit produit bêta → lancement](../archive/requests/2026-11-04-beta-to-launch-product-growth-audit.md) (commit `26f8623`, §9) : **premier lot = B0**, puis décision sur B1 avec ses résultats ; **la v35 est publiée après B0** si le passage dans Studio ne montre aucun bloquant.

B0 (Claude) : le build exact v35 rejoué dans Studio en six scènes (arrivée, premier coup, course → saut → mur → attaque → atterrissage, signature, duel complet, KO et revanche), au clavier, à la manette et en émulation téléphone, effets allumés puis éteints ; tableau de preuves TECHNICAL / NATIVE_STUDIO / HUMAN_VISUAL_FEEL / LIVE_ROBLOX et dix pires défauts (sévérité, fréquence, impact). B0 (utilisateur) : testeurs débutants non guidés et défi en ligne réel entre deux comptes et deux serveurs. Suivi dans [QA-001](MASTER_BACKLOG.md#qa-001--validation-studio--artefact-courant-roster-réel-et-manette) et NET-001. Pas de B1, de nouveau mode ni de publicité sans nouvelle décision.

## DEC-034 — Bêta : B1 (premier plaisir et feel) puis B2 (jouer seul, en ligne prouvé), un lot à la fois (04/11)

Décision utilisateur du **04/11 à 23 h 07**, après B0 (DEC-033) et la publication de la v36 : **« Both et intègre ça à B1 »** (relectures Roblox et animations dans B1). **Revue à 23 h 10** sur sa remarque : « ça me semble pas couvrir l'ensemble de ce que t'as demandé codex pr la bêta, le fun jouable même si y'a personne directement en lancement l'appli, le tuto etc. ». Le plan relit l'[audit](../archive/requests/2026-11-04-beta-to-launch-product-growth-audit.md) (`26f8623`, §2–§7) et la [revue bêta / V1](../reports/beta-v1-strategy-2026-11-04/REVIEW.md) en entier ; plan détaillé et correspondance point par point dans le doc projet `plan-beta-b1-b2-2026-11-04`.

Règle (revue, §4) : un lot à la fois ; chaque lot part d'une scène jouée et finit par la même scène rejouée sur le nouveau build ; preuves TECHNICAL / NATIVE_STUDIO / HUMAN_VISUAL_FEEL / LIVE_ROBLOX séparées ; ni feature décorative, ni nouveau perso, ni publicité.

**B1 — premier plaisir et feel**

1. **Le jeu répond** : IA en trois niveaux (facile pour un nouveau joueur et par défaut hors tournoi, montante dans le tournoi, sélecteur au roster ; défaut B0 1) ; temps sans contrôle sous les coups re-mesuré par niveau (sim du 03/11 : 16–27 %, ultime 4,5 s) ; caméra (défauts B0 2–4) ; scène air / mur / impacts rejouée jusqu'au bout. Tickets : BAL-001, CAM-001, QA-004.
2. **La première minute, seul, dès le lancement** : choix du ninja en un geste, 30 s de consignes dans le jeu (bouger, frapper, esquiver, signature sur une touche), premier duel direct contre l'IA facile, REVANCHE en grand ; révélation progressive du HUD ; le tutoriel complet devient ENTRAÎNEMENT (étapes au choix, sonde QA conservée) ; mesures du premier input, de la première technique, du premier duel, des refus et des abandons. Cibles hypothétiques de l'audit : < 15 s, < 45 s, < 3 min. Ticket : UX-001.
3. **Deux signatures exceptionnelles** : Chidori de Sasuke (verticalité), Dieu du tonnerre volant de Minato (marque puis angle), lisibles sans interface ni effets ; test avant / après VFX Studio sur le Rasengan (défaut B0 7) ; interrupteur d'effets (défaut B0 8). Tickets : ANIM-003, ANIM-004.
4. **Travail déjà lancé** : les trois relectures Roblox (sécurité, performance, interface / mobile) et leurs corrections confirmées ; les animations Blender des sept autres, intégrées seulement si elles rendent mieux dans la scène jouée ; défauts B0 9–10.

Sortie B1 (audit §6–§7) : les six scènes rejouées sur le même build, effets allumés et éteints, PC / manette / téléphone émulé ; l'utilisateur puis des débutants non briefés (objectif proposé : 70 % finissent le premier duel) ; un débutant finit son premier duel et veut rejouer ; défauts restants consignés ; version publiée avec le feu vert de l'utilisateur.

**B2 — jouer seul, en ligne prouvé**

5. **Tournoi IA et entraînement, vrais modes seuls** : tournoi rapide (aujourd'hui 15–20 min), PASSER visible partout, récompense sans pay-to-win (décision du 04/11 : classement, titre, monnaie ; sceau de champion par ninja), sauvegarde par `ProfileRepository` après correction des trous de la relecture sécurité (propriété réseau du corps en duel local, actions du tournoi sans limite) ; entraînement libre contre un mannequin réglable. Ticket : REL-001.
6. **En ligne prouvé** : défi entre deux serveurs joué en vrai avec deux comptes (parcours et échecs), messages d'erreur utiles. Ticket : NET-001.

Sortie B2 (audit §6) : un joueur seul a un objectif ; deux joueurs se trouvent, se battent, rejouent et sortent.

Hors bêta (audit §4–§6, gates L1 / F1) : file « duel rapide » sur tout le jeu (seulement si le test en ligne la montre nécessaire), entonnoir par source, page Roblox et publicité, hub, progression, classé, boutique, nouveaux persos, tournoi entre joueurs ; risque de droits Naruto à trancher avant toute promotion payante. Restent à l'utilisateur : testeurs débutants, vrai téléphone, deux comptes, vidéos des trois premières minutes. Questions ouvertes (lot 5) : format du tournoi rapide ; monnaie dès la bêta ou avec la boutique.


## DEC-035 — Une source, quatre places ; le Mac rangé sous `~/Documents/NinjaDuel` (07/11)

Décision utilisateur ([issue #45](https://github.com/francoisdebono8-rgb/roblox-dev/issues/45), complétée le **07/11 à 13 h 25** : « auditer et réorganiser les fichiers Ninja Duel présents sur mon Mac… un espace de travail propre et unique, avec des archives… demande-moi mon accord avant toute suppression définitive »).

- Branche d'intégration : `claude/ninja-duel-2026-10-14` ; branches courtes `work/<rôle>-<sujet>` et PR testées. Les quatre discussions (DEV, CLIPS, ANIMATION/VFX, OUTILLAGE) se transmettent le travail par Git, les fichiers et les issues ([RUNBOOK](../tools/RUNBOOK_4_DISCUSSIONS.md)).
- GAME, DEV, QA et FILM sont **quatre profils du même commit** (`build.py`, `--debug`, `--qa`, `--capture`), avec le même `runtimeFingerprint`. Plus de place copiée à la main ni de `ND-Test-vNN` : une ancienne version se reconstruit par son commit.
- Sur le Mac : `~/Documents/NinjaDuel/PLACES/` contient les quatre places actives (`ND-JEU`, `ND-DEV`, `ND-QA`, `ND-FILM`), mises à jour par `_outils/actualiser_places.sh` ; `MEDIA`, `BLENDER`, `LAB`, `ARCHIVES`, `_maintenance` à côté ; anciens dossiers en alias.
- Réorganiser sans détruire est autorisé ; **supprimer demande l'accord explicite** du propriétaire sur une liste de chemins exacts (DELETED WITH APPROVAL). Publication Roblox : toujours sur son feu vert.

Résultat : [MAC_CLEANUP_RESULT](../reports/mac-local-2026-11-07/MAC_CLEANUP_RESULT.md).

## DEC-036 — Le ninja du joueur porte le kit d’un prodige (12/11)

Décision utilisateur du **12/11 à 16 h 29**, en réponse à la question « les prodiges seulement, son propre ninja seulement, ou les deux ? » : l’option des deux, précisée ainsi : on garde toutes les attaques et on continue de faire les prodiges ; le joueur peut les jouer avec son propre perso ; les modifications sont très légères (le build), l’essentiel porte sur les tenues ; au début, un perso a un build, comme si on clonait les capacités du prodige sur lui. Ainsi tout ce qui est fait pour la bêta puis pour les 20 prodiges reste utilisable. Remplace la phrase de VISION « le shinobi personnel à créer est abandonné ».

- **Deux couches.** Le **kit** est le prodige : stats (cohérentes avec l’histoire), déplacements, coups, combos, jutsu, signes, ultime, éveil, animations Blender, effets. Le **corps** est le ninja du joueur : visage, cheveux, peau, tenue, couleurs, accessoires sans effet.
- **Un objet qui sert à une technique appartient au kit** et apparaît sur le ninja qui le porte : la gourde de Gaara, le sabre de Kakashi, les kunai marqués de Minato, les poids de Lee ; les yeux (Sharingan, Byakugan) s’allument sur les yeux du ninja ; les clones sont des copies du ninja.
- **À préciser : l’usage des objets de kit et l’arbre.** Précision de l’utilisateur (12/11, 16 h 34) : les objets ne seront peut-être pas utilisables au début, puis utilisables selon les niveaux de l’arbre ; la forme de l’arbre et ce à quoi il sert restent à définir. D’ici là, les objets de kit sont seulement repérés (ce qu’ils sont, à quel kit ils appartiennent), sans règle de jeu nouvelle.
- **Le corps, c’est l’avatar Roblox du joueur.** Précisions de l’utilisateur (12/11, 16 h 49 et 16 h 54) : l’essai se fait avec son propre avatar Roblox, « c’est ça le vrai délire », pas avec l’Ōtsutsuki ; et un joueur garde tout ce qu’il a acheté pour son avatar. Le corps est donc l’avatar complet (vêtements, vêtements superposés, accessoires, cheveux, visages et têtes, packs de corps) ; seuls les curseurs de taille (hauteur, largeur, profondeur, tête, type de corps, proportions) sont remis à la normale, et les articulations sont posées sur le squelette du jeu. Ses animations et emotes Roblox ne servent pas en combat. L’Ōtsutsuki reste l’hôte des devlogs.
- **Un seul squelette R15**, aux proportions pour lesquelles les animations sont faites (`World.RIG`) : chaque pivot d’articulation de l’avatar est placé là où est celui du rig, chaque pièce garde son propre décalage. Mêmes clips, mêmes pieds au sol, même portée pour tous.
- **Modifications légères seulement** : les variantes de build (arbres DEC-024), jamais un autre moveset ; budgets standardisés en tournoi inchangés. Au départ, un build par ninja = un kit cloné.
- **Les prodiges restent** : adversaires IA, tableau du tournoi, fiches et vidéos ; leur apparence d’origine reste jouable.
- **Ordre** : séparer kit et corps dans le code sans changement visible (fait) ; marquer les pièces de kit (fait) ; jouer chaque kit avec l’avatar Roblox de l’utilisateur dans Studio ; sauvegarde du profil (kit, build, corps choisi : son avatar ou l’apparence du prodige) ; pièces ninja du jeu à porter par-dessus l’avatar (bandeau, gilet…) au lieu d’un créateur de perso ; puis hub, tenues à gagner, boutique cosmétique.

## DEC-037 — Le chemin des maîtres : un kit sur trois, puis chaque maître apprend le sien ; on vend le temps, pas la victoire (12/11)

Décisions utilisateur du **12/11, 17 h 02 à 17 h 21** : au début, le joueur choisit un kit parmi trois et doit ensuite débloquer tous les autres ; une fois débloqués, il choisit son kit entre deux matchs ; pas de mélange de kits ; « un maître qui t’apprend son kit et qui t’emmène à débloquer un autre kit » ; « on veut que les gens paient », pas de tirage au sort pour les kits, mais une attente qui pousse à payer est assumée ; « lance les premiers travaux… dès qu’on aura les premières bases, on pourra l’intégrer à la bêta ».

- **Départ** : un kit parmi Naruto, Sasuke et Lee (`Shared/Masters.Starters`, proposition par défaut, à confirmer).
- **Maîtres** : chaque kit a son maître, le prodige lui-même ; il enseigne quand le joueur a `Masters.Need` de maîtrise dans un kit lié (carte `Masters.Map`, d’après l’histoire ; depuis chaque départ, tous les kits sont atteignables) et qu’il gagne son duel (IA `hard`). Les épreuves d’entraînement du maître viendront ensuite.
- **Maîtrise** : gagnée par un duel décidé avec un kit appris (finir, gagner, chaque jutsu différent une fois, moins contre l’IA facile) ; jamais en entraînement, match regardé, pilote automatique ou en ligne pour l’instant.
- **Kits en pratique** : l’entraînement et le tutoriel prennent n’importe quel kit ; un duel qui compte (roster, tournoi, en ligne) exige un kit appris.
- **Argent** : un kit peut s’acheter tout de suite (produit développeur par kit, accordé une seule fois par reçu, sauvegardé avant de répondre à Roblox) ; passe 2x maîtrise ; cosmétiques, accès anticipé, abonnement, serveurs privés à venir. Jamais de tirage au sort ; le classé et le tournoi gardent un budget égal (DEC-024). Les points de compétence ne s’achètent toujours pas.
- **Sauvegarde** : profil v2 (`kits` : appris, départ, kit choisi, maîtrise, reçus), chargé à l’arrivée, sauvegardé toutes les 30 s, au départ et à l’arrêt du serveur.
- **Interrupteur** : `Config.Progression.Enabled` reste à `false` jusqu’à l’écran du roster (choix du départ, carte des maîtres, achat) ; `Live` ouvre le DataStore réel ; les identifiants de produits sont créés par l’utilisateur sur Roblox.
- **Allumé dans la bêta (13/11)**, sur la demande de l’utilisateur « avance maintenant sur la bêta qu’on soit proche de la vraie boucle du jeu » : `Enabled` et `Live` passent à `true` avec l’écran du roster (`Shared/MastersView`) ; le serveur ne l’applique que si le magasin des profils a démarré, sinon tous les kits restent ouverts. Le corps du joueur est son avatar Roblox dans ses propres duels (`Config.AvatarBody`, DEC-036). Rien n’est vendu tant que `Products` est vide. Le jeu publié ne change qu’à la prochaine publication, qui reste soumise à l’autorisation de l’utilisateur.
- **Risque** : les noms et personnages de Naruto dans un jeu qui encaisse ; à trancher avant d’activer les achats (déjà noté dans le plan bêta).

## DEC-038 — La boucle dans le monde : Konoha et la salle de l’examen, les maîtres chez eux, des arbres payés par la maîtrise (13/11)

Demande de l’utilisateur du **13/11 à 17 h 11** : « il faut vraiment que je travaille la boucle en mode le décor, les scènes, où est-ce qu’on va choisir le maître, […] les premiers déplacements. Du coup, il faut faire les arbres de compétences réelles ». Les quatre choix suivants ont été faits par l’utilisateur à 17 h 14, chacun étant l’option recommandée.

- **Le décor** : un village de Konoha compact. On y trouve la porte d’arrivée, une rue, le terrain d’entraînement, le quartier Uchiha, la maison Hyûga, les toits et les visages des Hokage. Au centre se trouve la salle des préliminaires de l’examen Chûnin : c’est de là que partent les duels et le tournoi. L’avatar du joueur arrive par la porte.
- **Les maîtres** : chacun attend chez lui, et le joueur marche jusqu’à eux. Il y prend son premier kit, se fait enseigner les autres, affronte le duel du maître et consulte l’arbre. Ceux qui n’enseignent pas encore sont visibles et disent ce qui manque.
- **Les arbres** : chaque kit de la bêta a son arbre réel (`Shared/SkillTrees`, de 120 à 150 points au maximum). Les points viennent de la maîtrise du kit : un point pour 10 de maîtrise (`Masters.points`). Jouer un kit fait donc grandir son arbre. Un kit acheté n’apporte aucun point, et les points ne s’achètent pas. Un nœud appris entre aussitôt dans le build du kit ; on l’allume ou on l’éteint entre deux matchs.
- **Les objets de kit sont des nœuds** : la gourde de Gaara, les poids de Lee et le tanto de Kakashi. L’objet est porté dès le départ, mais le ninja **du joueur** ne s’en sert qu’une fois le nœud acquis : sans lui, pas de bouclier de sable, pas de « Remove the Weights », un tanto qui reste au fourreau. Les prodiges eux-mêmes gardent tout : l’IA, les maîtres, le tournoi vu et les films. Exception : le kunai marqué de Minato est le cœur de son kit ; son nœud d’objet reste « Kunai Recall », qui ramasse un kunai planté.
- **Où l’arbre s’applique** : dans les duels qui comptent avec un kit appris, dans le duel du maître et en entraînement avec un kit appris. Un kit seulement essayé, le tournoi et le 1v1 en ligne gardent le kit entier du prodige, à budget égal (DEC-024).

