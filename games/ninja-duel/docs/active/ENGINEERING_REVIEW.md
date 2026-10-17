## BLOCKERS

Audit Codex `de33f3d` (17/10). **Aucun P0 confirmé.** Les vingt sont une base technique pour DEC-021, pas vingt Tier A validés. Le breadth pass est fini ; commencer par les P1 avant le travail de feel. [État/preuves](CURRENT_STATE.md).

## REGRESSIONS

27 suites / 489 cas PASS sur le HEAD exact ; invariant direction + Light : 180 cas PASS sur20. Aucune nouvelle régression des anciens reproduite. Défauts préexistants exposés : buff persiste au round2 ; Camellia masque Heavy/Armor éveillés ; téléports ciblés acceptés depuis120 malgré Range30–34. Tests natifs finaux des anciens encore partiels.

## ARCHITECTURE RISKS

Families doit expliciter composition buff/éveil/OnHit et cleanup des états. Combat/Brawler restent centraux : hooks partagés plutôt que conditions par nom. Tests roster permissifs (>=8, bonus numérique accepté comme éveil, spawn accepté comme effet) donnent des faux badges. Réemploi des familles correct ; pas de réécriture générale.

## PLAYER-FACING FAILURES

Quatre éveils seulement numériques : Haku/Shisui/Deidara/Nagato. Sasori sans marionnette persistante ; Deidara mine/Katsu non liés ; Zabuza arme/contact peu incarnés ; Nagato absorption abstraite. MCP Studio utilisé sur Debug batch3, pas sur le SHA final (seule couleur Shisui diffère). Impact des projectiles/outils, sélection complète finale, manette et feel humain restent à valider. [Classement et preuves](../archive/audits/2026-10-17-roster20/AUDIT.md).

## NEXT 3 PRIORITIES

1. QA-004 / ARC-002 : corriger reset, composition des états et portée des téléports avec régressions ciblées.
2. COM-002/003/005 + QA-002 : grille combat breadth-first sur20 ; fiabiliser chaînes/routes/air/défense/KO puis anticipation/contact/réactions/transitions. Conserver l'invariant avant premier hit.
3. QA-001/005 + AI-001/BAL-001 : gate Studio sur artefact final, anciens compris, vrais impacts et matchups à risque ; rapport/synchronisation avant bloc suivant de DEC-021. Signatures/éveils sous SYS-003 et CHR-CORE-001 ensuite, sans chantier parallèle.

## DO NOT TOUCH

Claude implémente ; Codex ne corrige aucun gameplay dans cet audit. Aucun personnage supplémentaire, aucune refonte Combat/Brawler/MoveGraphs/Fighters, aucune extension vers les autres grands systèmes. Préserver autorité serveur, familles/hook existants, branches concurrentes et frontières Forge/Lab. Pas de faux PASS natif final ni de preuve online déduite du headless.
