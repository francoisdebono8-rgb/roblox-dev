## BLOCKERS

Audit Codex du 17/10/2026, base `04d6eb0` ; documentaire/code ciblé, sans Studio. Gates non clos : CHR-EXT-002 (roster réel), QA-001 (couches récentes non jouées) et NET-001/REL-001 (flow Roblox publié sans preuve). Voir [état exact](CURRENT_STATE.md), sans interpréter ces gaps comme des bugs reproduits.

## REGRESSIONS

Aucune nouvelle régression gameplay reproduite dans cet audit. Ne pas rouvrir les anciens correctifs sans scénario sur le HEAD courant.

## ARCHITECTURE RISKS

ARC-002 : fichiers centraux Combat/Brawler/AI disputés aux merges ; garder hooks/familles ciblés. PERF-001/NET-002 : corps secondaires, zones et snapshots exigent mesures natives. Harness corrigé à la fusion Temari : anciennes métriques IA à recalibrer, pas bug encore ouvert. Online par serveur, gigue et ordre des sièges restent à éprouver ; aucune réécriture réseau préventive.

## PLAYER-FACING FAILURES

**Absences de preuve**, pas FAIL natif nouveau : Naruto/clones, Temari/vent, nouvelle identité CORE4 et fil/conduction/repères chakra uniquement headless dans leurs rapports. Titre « vue en jeu » trompeur. Manette réelle et parcours online publié non validés. Progression sans flow joueur complet ; ne pas la présenter comme livrée.

## NEXT 3 PRIORITIES

1. QA-001 : jouer les merges récents dans le vrai flow Studio ; corriger les échecs observés et dater les preuves.
2. CHR-EXT-002 : poursuivre les kits Tier A par familles avec validation native à chaque lot ; pas de polish isolé qui bloque la breadth.
3. NET-001/REL-001 : prouver les sessions à deux clients puis le flow Roblox publié ; préparer les gates alpha sans attendre le polish final.

## DO NOT TOUCH

Codex : aucun gameplay/runtime ni branche d’implémentation concurrente. Préserver travail de Claude, autorité serveur, isolation normal/Debug/QA, frontière Forge/Lab et artefacts. Ne pas intégrer en bloc les anciennes branches ou pools de roster. Les arbitrages appartiennent à [DECISIONS](DECISIONS.md) ; cette revue ne les remplace pas.
