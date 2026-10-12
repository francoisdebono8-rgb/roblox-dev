# Depuis le dernier Claude

## Points de comparaison explicites

- Dernière base runtime Claude identifiée : `4bb3275`, branche `claude/minato-itachi-final`, quatre personnages. Ne pas supposer que le prochain Claude a vu ce commit.
- Motion Lab réuni depuis `89a54f9` ; assemblage `a0ab165` puis préparation `bd3c483947bbf33dcc76282cf727d808c786141d`.
- Sur la préparation : diagnostics lecture seule/overlay optionnels, normal/debug/QA isolés, inventaire et mapping, clips hérités Neji/Sasuke conservés par l’adapter, 7 tests Preparation supplémentaires. Les 36 sources runtime protégées restent identiques à la base Claude ; Main/DevHooks ont uniquement le câblage diagnostique décrit dans le handoff.
- Refactor du 12 octobre 2026 : entrée START, couche active, backlog cumulatif, specs thématiques, sources archivées intégrales et couverture. Aucun changement source runtime, test existant, clip ou adapter pendant ce refactor. Les chemins docs ont changé ; lire le [rapport](../reports/ORCHESTRATION_REFACTOR.md).
- Rectification documentaire : Gaara reste dans serveur/tests, mais ne figure pas dans la sélection publique à quatre personnages. Les 16 matchups Studio de rapports passés ne valident pas le nouvel artefact final.

## À faire à la reprise

Vérifier la branche et `git log --oneline --decorate`, comparer `git diff 4bb3275..HEAD -- games/ninja-duel/src`, puis la préparation et le refactor. Lire les limites CURRENT_STATE, valider QA-001 sur Studio, proposer le plan par IDs et demander son approbation globale. Aucun plan gameplay futur approuvé dans cette migration ; aucun merge dans main, aucune publication/installation.

## Registre des prochaines sessions

Ajouter un bloc daté (ne pas remplacer l’historique) : base/fin SHA ; demande/approbation exacte et IDs ; changements ; DONE/IMPROVED/BLOCKED/DEFERRED/REJECTED ; preuves techniques/natives et hashes ; risques ; prochaine action ; outils désormais disponibles. Ne pas copier une ancienne PASS vers un artefact différent. Actualiser CURRENT_STATE, backlog et décisions dans le même commit.
