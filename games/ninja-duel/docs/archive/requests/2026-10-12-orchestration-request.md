# Source utilisateur — orchestration persistante (2026-10-12)

Archive de provenance. Consulter la couche active ; ne pas rejouer cette demande comme une mission nouvelle.

Travaille sur le repository :
francoisdebono8-rgb/roblox-dev
Objectif principal :
refactorer l’architecture documentaire et opérationnelle de games/ninja-duel pour qu’un nouveau Claude, sans aucun contexte de chat précédent, puisse comprendre tout le projet, voir ce qui a changé pendant son absence, reconstruire le backlog, proposer un ordre de travail, puis exécuter progressivement tout ce qui reste à faire avec un minimum d’itérations utilisateur.
Important :
ce travail est un refactor d’architecture, de documentation et d’orchestration.
Ne modifie pas le gameplay, les animations, les movesets, le game feel, la caméra ou l’équilibrage simplement pour faire rentrer l’architecture.
Le jeu actuel doit continuer à fonctionner.
1. Principe fondamental
Assume que Claude revient avec :
- zéro historique de conversation ;
- zéro mémoire du projet ;
- aucune connaissance de ce qui s’est passé dans les anciens chats ;
- seulement l’accès au repo GitHub.
Le repository doit donc devenir auto-explicatif et auto-orchestrant.
L’objectif final est qu’un Claude neuf puisse recevoir seulement :
Connecte-toi au repo, ouvre games/ninja-duel/CLAUDE_START_HERE.md, audite l’état actuel et propose l’ordre des prochains blocs.
et être capable de comprendre :
- la vision globale du jeu ;
- les 4 personnages jouables actuels : Minato, Itachi, Neji, Sasuke ;
- le fonctionnement du combat ;
- les décisions de design prises ;
- les idées futures déjà validées ;
- les recherches et références accumulées ;
- Motion Lab ;
- les outils préparés par Codex ;
- les systèmes actuels ;
- ce qui est terminé ;
- ce qui est partiel ;
- ce qui reste à faire ;
- ce qui a changé depuis la dernière session Claude ;
- l’ordre logique des prochains travaux.
2. Ne pas faire un simple rangement de dossiers
Le but n’est PAS seulement :
déplacer des fichiers dans docs/
Le but est de créer une vraie hiérarchie opérationnelle :
vision -> décisions -> état actuel -> backlog -> specs -> recherche -> outils -> implémentation -> validation -> mise à jour de l’état
Claude doit comprendre automatiquement comment naviguer cette hiérarchie.
3. Créer une seule porte d’entrée pour Claude
Crée :
games/ninja-duel/CLAUDE_START_HERE.md
Ce fichier doit être court, clair et impératif.
Il doit expliquer que :
- tout le contexte utile est dans le repo ;
- les anciens chats ne sont pas nécessaires ;
- le projet possède un backlog cumulatif vivant ;
- Claude ne doit jamais considérer uniquement le dernier fichier ajouté comme “sa mission” ;
- il doit reconstruire l’état du projet au début de chaque session ;
- il doit lire les fichiers actifs prioritaires dans un ordre défini ;
- il doit inspecter les changements récents ;
- il doit ouvrir et tester le jeu dans Studio ;
- il doit proposer un ordre d’exécution basé sur dépendances, impact et état réel ;
- après validation utilisateur du plan global, il doit avancer bloc par bloc sans redemander validation pour chaque petite étape ;
- il doit mettre à jour l’état et le backlog au fur et à mesure.
Ajouter explicitement une règle :
Do not depend on prior chat history. The repository is the source of truth.
4. Créer une couche active
Crée une architecture claire, par exemple :
games/ninja-duel/docs/active/
contenant au minimum :
- VISION.md
- CURRENT_STATE.md
- MASTER_BACKLOG.md
- DECISIONS.md
- EXECUTION_RULES.md
- CAPABILITIES_AND_TOOLS.md
- SINCE_LAST_CLAUDE.md
Tu peux adapter légèrement les noms si nécessaire, mais garde cette logique.
5. VISION.md
Ce fichier doit résumer la vision durable du jeu sans écraser les détails.
Il doit contenir notamment :
- tournoi de prodiges ninja jeunes ;
- actuellement 4 personnages jouables : Minato, Itachi, Neji, Sasuke ;
- long terme : roster extensible, environ 32 potentiels ;
- ne pas créer 32 moteurs de combat ;
- créer un langage de combat commun que chaque personnage déforme ;
- combat rapide, physique, anime, lisible, avec plus de liberté que Storm ;
- importance majeure du taijutsu ;
- arena mécaniquement utile ;
- chakra systémique ;
- outils ninja systémiques ;
- identité très forte de chaque personnage ;
- progression future possible vers Prodigy League / Shinobi Path sans imposer cela au gameplay actuel.
Ce fichier doit être stable et rarement modifié.
6. CURRENT_STATE.md
Ce fichier doit donner l’état réel actuel du projet en une lecture.
Inclure :
- playable characters ;
- état combat ;
- état movement ;
- état camera ;
- état arena ;
- état tools/projectiles ;
- état air/wall ;
- état defense/counter ;
- état Motion Lab ;
- état tests/build ;
- bugs importants connus ;
- limitations connues.
Chaque système doit avoir un statut simple :
- WORKING
- PARTIAL
- BROKEN
- NOT_STARTED
Important :
ce fichier doit refléter l’état courant, pas l’historique.
7. MASTER_BACKLOG.md
C’est le fichier le plus important après CLAUDE_START_HERE.md.
Transforme les exigences encore valides du projet en backlog traçable.
Chaque item doit avoir :
- ID stable ;
- titre ;
- statut ;
- priorité ;
- dépendances éventuelles ;
- personnages concernés ;
- résumé ;
- source(s) documentaire(s) ;
- critère de validation.
Statuts recommandés :
- OPEN
- PARTIAL
- IN_PROGRESS
- DONE
- BLOCKED
- DEFERRED
- REJECTED
Exemples d’IDs :
- MOV-001
- COM-004
- DEF-003
- TOOL-002
- CHR-MIN-004
- CHR-ITA-003
- CHR-NEJ-002
- CHR-SAS-005
- ARENA-003
- CAM-002
Le backlog doit intégrer les grandes exigences déjà présentes dans le repo, notamment :
- locomotion humaine multidirectionnelle ;
- body continuity ;
- lateral run correct ;
- taijutsu riche ;
- directional/contextual combos ;
- aerial/wall conversion ;
- grabs/throws/counters ;
- defense/deflect/dodge/kawarimi ;
- clashes ;
- tools ninja ;
- chakra interactions ;
- projectile lifecycle ;
- Minato FTG/marked kunai ;
- Itachi shuriken/deception/fire ;
- Neji Gentle Fist ;
- Sasuke agressive taijutsu + fire + tools ;
- arena scale ;
- camera ;
- awakenings ;
- movement research pipeline ;
- Motion Lab integration ;
- character differentiation ;
- known bug classes.
Ne perds pas les détails :
le backlog résume, mais pointe vers les specs détaillées.
8. DECISIONS.md
Regroupe les décisions produit actuelles qui doivent avoir priorité sur les anciens documents.
Exemples :
- 4 playable characters now = Minato / Itachi / Neji / Sasuke ;
- Motion Lab reste sous Ninja Duel ;
- Codex est outilleur, Claude arbitre le game feel ;
- gameplay commun + expression propre par personnage ;
- éviter input overload ;
- garder versions jeunes plausibles ;
- lore statuses :
  CANON_YOUNG
  PLAUSIBLE_YOUNG
  GAMEPLAY_LIBERTY
  REJECT_ADULT_ONLY
- ne pas recentrer le projet sur seulement Minato/Itachi ;
- ne pas recréer le moteur de combat à chaque perso ;
- Studio visual validation obligatoire pour Claude.
9. EXECUTION_RULES.md
Ce fichier doit définir le comportement attendu de Claude à chaque nouvelle session.
Au minimum :
1. lire CLAUDE_START_HERE.md;
2. lire VISION.md;
3. lire DECISIONS.md;
4. lire CURRENT_STATE.md;
5. lire SINCE_LAST_CLAUDE.md;
6. lire MASTER_BACKLOG.md;
7. inspecter les changements Git récents ;
8. consulter les specs liées aux items prioritaires ;
9. ouvrir Studio et vérifier la réalité ;
10. proposer un plan par blocs ;
11. attendre une validation utilisateur sur l’ordre général ;
12. ensuite exécuter de manière autonome ;
13. ne redemander confirmation que pour une vraie décision produit, un conflit de vision ou un blocage majeur ;
14. mettre à jour backlog/state après chaque bloc significatif.
Ajouter une règle :
Ne refais pas un système déjà correct simplement parce qu’un vieux document le demande. Vérifie-le, marque-le DONE, passe au suivant.
10. CAPABILITIES_AND_TOOLS.md
Ce fichier doit expliquer ce qui existe comme outillage disponible pour Claude.
Inclure :
- Roblox Studio ;
- Motion Lab ;
- rôle de Motion Lab ;
- exports/imports disponibles ;
- motion library ;
- adapters ;
- debug tools ;
- build scripts ;
- tests ;
- QA build ;
- éventuels outils Codex ;
- chemins importants ;
- ce qui est safe à modifier ;
- ce qui ne doit pas être remplacé inutilement.
Claude doit pouvoir découvrir rapidement les nouveaux outils ajoutés pendant son absence.
11. SINCE_LAST_CLAUDE.md
Ce fichier doit être un journal synthétique des changements arrivés depuis la dernière intervention Claude.
Il doit pouvoir contenir :
- nouveaux commits importants ;
- nouveaux systèmes Codex ;
- nouvelles décisions ;
- nouveaux personnages ;
- nouveaux outils ;
- nouvelles recherches ;
- nouvelles références vidéos/jeux ;
- nouveaux bugs connus ;
- nouvelles priorités.
Claude doit comprendre immédiatement ce qui a changé sans relire tout l’historique.
Ce fichier ne remplace pas Git.
Il sert de résumé opérationnel.
12. Réorganiser les specs existantes sans perdre d’information
Réorganise les docs actives par thème, par exemple :
docs/combat/
docs/movement/
docs/characters/
docs/systems/
docs/research/
docs/tools/
docs/reports/
docs/archive/
Les documents historiques doivent être déplacés vers archive/reports quand ils ne servent plus de source active.
Mais :
ne supprime pas une ancienne mission simplement parce qu’elle est ancienne.
D’abord :
- vérifie si elle contient encore une exigence unique ;
- migre cette exigence vers la bonne spec/backlog ;
- ensuite seulement archive-la.
13. Créer une hiérarchie de vérité
Documente clairement l’ordre de priorité en cas de contradiction :
1. instruction utilisateur actuelle ;
2. VISION.md ;
3. DECISIONS.md ;
4. MASTER_BACKLOG.md ;
5. specs actives ;
6. design_research / research ;
7. anciens rapports/missions archivés.
Une vieille mission ne doit jamais pouvoir réintroduire une décision dépassée.
Exemple :
si un ancien fichier parle d’un prototype Minato/Itachi, les décisions actuelles à 4 personnages priment.
14. Préserver la profondeur des recherches
Ne transforme pas tous les fichiers riches en petits résumés superficiels.
Conserve les recherches détaillées, notamment :
- combat grammar ;
- combo building blocks ;
- roster archetypes ;
- awakenings ;
- system interaction matrix ;
- movement source pipeline ;
- research backlog ;
- character move research ;
- lore compatibility.
Les fichiers actifs doivent pointer vers ces sources.
Claude lit d’abord le résumé opérationnel, puis ouvre la recherche détaillée quand nécessaire.
15. Motion Lab reste une exception intégrée au jeu
Motion Lab reste sous :
games/ninja-duel/motion-lab/
Ne le déplace pas vers les anciens plugins Forge.
Le lien doit être à sens unique :
- Motion Lab peut lire/exporter vers Ninja Duel ;
- le runtime Ninja Duel ne doit pas dépendre du plugin.
Documente ce rôle.
16. Séparation jeu / plugins
Si ce travail touche aussi le repo global :
sépare clairement les anciens plugins Forge du jeu Ninja Duel.
Objectif :
games/ninja-duel
= jeu + Motion Lab
plugins/...
= AccessForge, CurveForge, JointForge, PresetForge, RoadForge, SchemaForge, etc.
Ne mélange pas les anciens produits Forge dans les docs actives de Ninja Duel.
Mais :
ne casse pas les projets existants.
17. Règle absolue de sécurité avant déplacement/suppression
Avant chaque déplacement ou suppression :
- chercher toutes les références ;
- identifier les scripts/imports/build paths ;
- identifier les autres projets qui utilisent le fichier ;
- identifier les dépendances transversales ;
- mettre à jour tous les chemins ;
- lancer les tests/builds concernés.
Si l’usage est ambigu :
ne supprime pas.
Conserve et documente.
Supprime seulement :
- code mort prouvé ;
- doublon prouvé ;
- fichier vide inutile ;
- artefact historique dont le contenu utile a été migré ;
- ancien debug totalement non référencé.
Le but n’est pas de réduire le nombre de fichiers.
Le but est de rendre l’architecture compréhensible sans perdre de capacité.
18. Préserver le jeu actuel
Avant refactor :
- lancer les tests actuels ;
- noter les résultats ;
- vérifier le build ;
- vérifier que les paths importants fonctionnent.
Après refactor :
- relancer les tests ;
- rebuilder le jeu ;
- vérifier Motion Lab ;
- vérifier les imports ;
- vérifier les scripts ;
- vérifier les builds .rbxlx.
Aucune modification gameplay volontaire.
19. Ajouter un mécanisme de mise à jour continue
Le système doit être pensé pour les futures sessions.
Quand plus tard l’utilisateur dit :
“j’aimerais que Claude fasse X plus tard”
la bonne procédure doit être évidente :
- si X est une décision -> DECISIONS.md
- si X est du travail -> MASTER_BACKLOG.md
- si X change l’état actuel -> CURRENT_STATE.md
- si X est une nouvelle capacité/outillage -> CAPABILITIES_AND_TOOLS.md
- si X est une référence/recherche -> dossier research approprié
- si X est un comportement personnage -> spec personnage
- si X est une règle combat -> spec combat
Documente cette procédure pour que ChatGPT/Codex/Claude puissent l’utiliser.
20. Ajouter un format de backlog exploitable par agent
Fais en sorte que Claude puisse trier facilement par :
- priority ;
- dependencies ;
- subsystem ;
- character ;
- status.
Pas besoin d’un système logiciel complexe.
Markdown bien structuré suffit.
Mais le format doit être stable.
21. Ne pas transformer Claude en exécutant aveugle
Claude doit conserver son rôle de juge technique et visuel.
Il doit pouvoir :
- re-prioriser ;
- rejeter une solution mauvaise ;
- dire qu’une idée est déjà résolue autrement ;
- proposer un meilleur ordre ;
- adapter une spec si la réalité Studio le justifie.
Mais il ne doit jamais ignorer silencieusement un item.
Chaque item doit finir par :
- DONE
- IMPROVED
- BLOCKED
- DEFERRED
- REJECTED avec justification
22. Livrable final attendu
À la fin :
1. donne le SHA final ;
2. donne l’arborescence finale importante ;
3. liste les fichiers créés ;
4. liste les fichiers déplacés ;
5. liste les fichiers archivés ;
6. liste les fichiers supprimés avec justification ;
7. confirme que le jeu build toujours ;
8. confirme que Motion Lab fonctionne toujours ;
9. confirme qu’aucune modification gameplay intentionnelle n’a été faite ;
10. explique en 10 lignes comment un Claude sans aucun contexte reprend maintenant le projet ;
11. donne l’exemple exact du prompt minimal qu’on pourra lui envoyer dans un nouveau chat.
Le critère final de réussite est :
un nouveau Claude avec zéro mémoire doit pouvoir comprendre Ninja Duel presque entièrement depuis GitHub, voir ce qui a changé pendant son absence, reconstruire les priorités, proposer l’ordre de travail, puis continuer le backlog sans que l’utilisateur ait à lui réexpliquer le projet.
Commit final recommandé :
refactor(ninja-duel): add persistent Claude project orchestration