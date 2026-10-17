# Ninja Duel — commencer ici

Do not depend on prior chat history. The repository is the source of truth.

Verify the current HEAD and authoritative Ninja Duel branch before working.
Do not assume main or any historical branch is current.

Lire d’abord les sources actives dans cet ordre :

1. [VISION](docs/active/VISION.md) — finalité.
2. [DECISIONS](docs/active/DECISIONS.md) — périmètre autorisé et responsabilités.
3. [CURRENT_STATE](docs/active/CURRENT_STATE.md) — état, checkpoint et limites des preuves.
4. [MASTER_BACKLOG](docs/active/MASTER_BACKLOG.md) — tâches et critères.
5. [SINCE_LAST_CLAUDE](docs/active/SINCE_LAST_CLAUDE.md) — deltas depuis le checkpoint.
6. [EXECUTION_RULES](docs/active/EXECUTION_RULES.md) — méthode, outils et maintenance.
7. Puis le dernier [ENGINEERING_REVIEW](docs/active/ENGINEERING_REVIEW.md) — diagnostic Codex à confronter au HEAD réel.

Comparer Git et checkpoint avant action. Claude reste l’implémenteur principal ; la revue fournit des constats et priorités, sans remplacer les décisions produit ni le travail courant. Continuer le périmètre déjà approuvé selon les règles actives.

Les [archives](docs/archive/README.md) sont des références historiques uniquement. Les guides techniques/recherches aident à localiser un contrat ou une source ; ils ne définissent pas une huitième vérité opérationnelle. Lire seulement ce qui est utile aux IDs traités. Mettre à jour les propriétaires concernés après chaque bloc, sans créer de nouvelle mission/handoff autonome.

Avant chaque nouveau gros bloc, vérifier la boîte de réception SINCE_LAST_CLAUDE et accuser les entrées intégrées selon EXECUTION_RULES. Ne jamais traiter « le dernier fichier ajouté » comme la mission globale.
