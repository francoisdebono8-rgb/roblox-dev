# Ninja Duel — commencer ici

Do not depend on prior chat history. The repository is the source of truth.

1. Lis [VISION](docs/active/VISION.md), [DECISIONS](docs/active/DECISIONS.md), [CURRENT_STATE](docs/active/CURRENT_STATE.md), [SINCE_LAST_CLAUDE](docs/active/SINCE_LAST_CLAUDE.md), puis [MASTER_BACKLOG](docs/active/MASTER_BACKLOG.md).
2. Applique [EXECUTION_RULES](docs/active/EXECUTION_RULES.md) et vérifie [CAPABILITIES_AND_TOOLS](docs/active/CAPABILITIES_AND_TOOLS.md). Compare systématiquement SINCE_LAST_CLAUDE au Git log et au HEAD de la session ; intègre les nouveaux commits Codex/ChatGPT et capacités au plan avant tout changement gameplay. Ouvre seulement les sources liées aux IDs actifs, puis l’artefact exact dans Studio.
3. Propose un plan par dépendances pour le backlog cumulatif, en distinguant déjà fonctionnel, corrections, amélioration et futur. Demande une seule approbation globale du plan, puis exécute ses blocs autonomes.
4. Ne traite jamais le dernier fichier ajouté comme la mission complète. Ne recommence pas les systèmes déjà corrects. Une archive conserve les détails ; elle ne commande pas une nouvelle session.
5. Mets à jour les preuves, statuts, décisions et [journal de reprise](docs/active/SINCE_LAST_CLAUDE.md) après chaque bloc. Ne déclare pas le feel validé à partir d’un test headless.

This orchestration was established on codex/ninja-claude-technical-prep. Verify the current HEAD and authoritative Ninja Duel branch before working. Do not assume main or any historical branch is current.

Vérifie HEAD et branche courante. Identifie la branche Ninja Duel la plus récente et autoritative à partir de l’historique, des fichiers actifs et des décisions utilisateur ; une date récente seule ne fait pas autorité. Si plusieurs branches concurrentes existent, compare leurs historiques et fichiers actifs avant de choisir ; signale un conflit réel non résolu. La branche d’établissement est historique, elle ne fixe pas les futures branches de travail. Aucun plan de modification gameplay n’est encore approuvé par cette préparation documentaire.
