## BLOCKERS

Audit incrémental Codex18/10, HEAD `bc7faa3`, cinq commits depuis abcb535. Aucun P0 confirmé. **BLOCKING de gate** : marionnette persistante consommée par route ; poison autonome sur garde ; mineRange26 implantée à100. Deux petites missions M1/M2 sous [QA-004](MASTER_BACKLOG.md#qa-004--reproduire-séquences-anormales-et-cycle-de-match). [Preuves](../archive/audits/2026-10-18-feel-preparation/AUDIT.md).

## REGRESSIONS

28 suites/500 cas PASS. Anciens P1 cleanup/composition/check de portée initial corrigés, ne pas les redemander. Proxy persistant→spent et poison sur block reproduits ; téléport peut encore suivre une cible sortie de portée pendant channel. Studio exact ouvert, MCP connecté ; preuves ciblées et limites dans CURRENT_STATE, pas nouveau PASS global20.

## ARCHITECTURE RISKS

Families/Bodies/MoveGraphs sont les bons points d'extension. Distinguer corps persistants/consommables sans casser Legion ; valider les bornes au bon instant serveur. Le snapshot de charges n'expose pas l'armement, la grille mesure push après déplacement et distincts via cooldowns. Pas de refonte ni code nominal dans le cœur.

## PLAYER-FACING FAILURES

**IMPORTANT** : brume cache le corps mais caméra/aim conservent des aides ; distance/visée peu fiables aux limites ; états charges/Absorb à rendre perceptibles. **POLISH** : poids/contact et continuité des conversions à comparer en natif par familles. Les anciennes lacunes d'identité ont reçu des mécaniques réelles ; ne plus annoncer quatre éveils uniquement numériques.

## NEXT 3 PRIORITIES

1. M1 : persistance proxy + garde/poison (cinq scénarios S1–S5), commit.
2. M2 : zone/charge Range + téléport release (S6–S10), puis M3 brume cohérente, commits séparés.
3. M4 mesures fiables → M5 états lisibles → M6 contact par petits lots → M7 gate20, selon les packets canoniques [QA-004](MASTER_BACKLOG.md#qa-004--reproduire-séquences-anormales-et-cycle-de-match). Rapport/synchronisation avant autre bloc.

## DO NOT TOUCH

Claude implémente ; Codex prépare et audite les deltas. Aucun gameplay modifié ici, aucun personnage ajouté, aucun nouveau système hors combat. Préserver les corrections déjà livrées, familles/hooks, autorité serveur, clones consommables Naruto et frontières game/Forge/Lab. Ne pas confondre sonde contrôlée, vraie entrée, physique native et acceptation humaine.
