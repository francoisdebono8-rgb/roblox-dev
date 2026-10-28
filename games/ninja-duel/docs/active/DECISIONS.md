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
