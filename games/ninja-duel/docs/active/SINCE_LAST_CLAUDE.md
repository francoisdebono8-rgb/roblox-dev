# Depuis le dernier Claude

## Points de comparaison explicites

- Dernière base runtime Claude identifiée : `4bb3275`, branche `claude/minato-itachi-final`, quatre personnages. Ne pas supposer que le prochain Claude a vu ce commit.
- Motion Lab réuni depuis `89a54f9` ; assemblage `a0ab165` puis préparation `bd3c483947bbf33dcc76282cf727d808c786141d`.
- Sur la préparation : diagnostics lecture seule/overlay optionnels, normal/debug/QA isolés, inventaire et mapping, clips hérités Neji/Sasuke conservés par l’adapter, 7 tests Preparation supplémentaires. Les 36 sources runtime protégées restent identiques à la base Claude ; Main/DevHooks ont uniquement le câblage diagnostique décrit dans le handoff.
- Refactor du 12 octobre 2026 : entrée START, couche active, backlog cumulatif, specs thématiques, sources archivées intégrales et couverture. Aucun changement source runtime, test existant, clip ou adapter pendant ce refactor. Les chemins docs ont changé ; lire le [rapport](../reports/ORCHESTRATION_REFACTOR.md).
- Rectification documentaire : Gaara reste dans serveur/tests, mais ne figure pas dans la sélection publique à quatre personnages. Les 16 matchups Studio de rapports passés ne valident pas le nouvel artefact final.
- Nouvelle exigence utilisateur du 12 octobre 2026 : renforcer fortement la **sensation de vitesse** de la course/sprint et rendre les sauts/traversal nettement plus « ninja ». Les exigences existantes MOV-001/002/003/005 et CAM-002 sont enrichies plutôt qu’un nouveau système parallèle : sprint perceptiblement plus rapide par corps + cadence + accélération + caméra bornée, pas seulement WalkSpeed/FOV ; sauts avec impulsion franche, momentum horizontal, contrôle aérien et réception proportionnée, pas petit hop Roblox + lourde retombée. Voir [LOCOMOTION](../movement/LOCOMOTION.md) et [ARENA_CAMERA_PRESENTATION](../systems/ARENA_CAMERA_PRESENTATION.md). Aucun runtime n’a encore été modifié pour cette demande.
- Recherche utilisateur du 13 octobre 2026 : constituer une banque **gratuite R15** de systèmes combat, systèmes mouvement et packs d’animations externes pour que Claude puisse comparer, utiliser, adapter ou rejeter selon la vision. Le catalogue est [FREE_R15_COMBAT_MOVEMENT_RESOURCES](../research/FREE_R15_COMBAT_MOVEMENT_RESOURCES.md) et enrichit RES-003 + IDs mouvement/combat/défense/caméra/Lab existants, sans ticket doublon. Priorités : ressources R15 Studio gratuites et dépôts open source avec licence claire ; ressources sans licence = référence seulement ; modèles avec scripts = audit isolé avant Play ; aucune importation automatique dans le runtime.

## À faire à la reprise

Vérifier la branche et `git log --oneline --decorate`, comparer `git diff 4bb3275..HEAD -- games/ninja-duel/src`, puis la préparation et le refactor. Lire les limites CURRENT_STATE, valider QA-001 sur Studio, proposer le plan par IDs et demander son approbation globale. Pour le bloc mouvement/caméra, inclure explicitement la perception de vitesse course/sprint et le traversal ninja ajoutés après la dernière session Claude. Pour combat/mouvement/animations, auditer le catalogue gratuit R15 : inspecter d’abord les priorités A/B en place Studio isolée, classer USE_DIRECTLY/ADAPT/REFERENCE_ONLY/REJECT, et n’intégrer que ce qui améliore réellement appuis, contact, transitions, variété et fun sans casser les fondations. Aucun plan gameplay futur approuvé dans cette migration ; aucun merge dans main, aucune publication/installation.

## Registre des prochaines sessions

Ajouter un bloc daté (ne pas remplacer l’historique) : base/fin SHA ; demande/approbation exacte et IDs ; changements ; DONE/IMPROVED/BLOCKED/DEFERRED/REJECTED ; preuves techniques/natives et hashes ; risques ; prochaine action ; outils désormais disponibles. Ne pas copier une ancienne PASS vers un artefact différent. Actualiser CURRENT_STATE, backlog et décisions dans le même commit.

## 2026-10-12 — durcissement de la reprise multi-session

Base : `ac54d55dca07abd9d575d043b64210a582fe8c45`. Demande utilisateur : petite correction de l’orchestration seulement ; aucun plan gameplay nouveau approuvé. La branche d’établissement devient un repère historique : vérifier HEAD/branche et comparer les branches concurrentes pour choisir la base autoritative. Intégrer les commits Codex/ChatGPT et nouvelles capacités au plan ; lire seulement les sources liées aux IDs actifs. Capture explicite « Claude should do X later », déduplication des intentions et distinction DONE technique/natif/humain renforcées. Aucun ticket ajouté ou fermé ; état réel, code runtime et plugins inchangés.

Validation : `python3 games/ninja-duel/tools/check_project_docs.py --self-test`, contrôles docs/architecture et suites/builds rapides ; les résultats de cette passe sont enregistrés dans le commit de durcissement. Le SHA final se lit dans Git ; native finale et feel restent PENDING. Prochaine reprise : appliquer la nouvelle sélection de base, vérifier les évolutions depuis ce bloc, puis plan global par IDs.

Résultats de cette passe : docs + mini reprise (cinq régressions et branche alternative) PASS ; architecture302 fichiers PASS ; jeu14 suites/139 cas + isolation4 PASS ; builds normal/debug/QA PASS ; Lab45 cas + smoke binaire UI simulé PASS. Les99 sources/artifacts protégés du rapport précédent gardent leurs hashes, et aucun diff sous src, motion-lab, plugins ou shared. Aucun déplacement/suppression ; aucune validation native finale supplémentaire.

Commits documentaires concurrents conservés avant publication : `349540a` (vitesse/traversal), `192b8bb` (caméra liée à vitesse/traversal), `d538389` (capture dans ce journal). La correction est réappliquée sur cette nouvelle base distante ; leurs exigences MOV-001/002/003/005 et CAM-002 restent intégralement dans les specs et doivent être intégrées au prochain plan, sans implémentation gameplay dans cette passe.

## 2026-10-12 — références combat et mouvement R15 fournies

L’utilisateur fournit une description de combat Roblox (download NFWuW, movement jfbUGuQZ), puis R15 Movement System (download VyLSC,37 452 vues et8 février2026 rapportés). Sources détaillées dans [SOURCE_REGISTER](../research/SOURCE_REGISTER.md), rattachées à RES-003 et aux IDs mouvement/combat existants, sans ticket doublon. Liens tentés par outil web mais inaccessibles ; vidéos originales non fournies, aucune promesse vérifiée, aucun téléchargement/intégration. À inclure dans la recherche du prochain plan Claude ; aucun changement d’état du jeu ni décision durable ajouté.

## 2026-10-13 — catalogue web gratuit R15

Recherche large Creator Store/GitHub/DevForum/YouTube ajoutée dans [FREE_R15_COMBAT_MOVEMENT_RESOURCES](../research/FREE_R15_COMBAT_MOVEMENT_RESOURCES.md). Le catalogue priorise notamment Place1 Movement System (R6/R15, MIT), CombatEngine/roblox-combat-framework (MIT), Kvarwaxa Combat-System (R6/R15, MIT), plusieurs packs Creator Store R15 gratuits de combat/dash/punch/kick et plusieurs références locomotion run/sprint. Les ressources GitHub sans licence explicite et les vidéos avec copyright ambigu sont marquées REFERENCE_ONLY jusqu’à clarification. Cette capture ne télécharge ni n’exécute aucun modèle externe et ne change pas le runtime : Claude doit faire l’audit Studio et choisir ce qui correspond réellement à Ninja Duel.
