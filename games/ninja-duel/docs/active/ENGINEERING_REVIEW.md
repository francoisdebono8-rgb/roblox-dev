## BLOCKERS

25/10, source `a014262` intégrant `fe09024`. Gate finale native bloquée : `execute_luau` refusé par contrôle automatique d'approbation, limite d'utilisation atteinte. Aucune conclusion d'insécurité ; aucun contournement. [Preuves et portée](../archive/reports/fight-continuity-2026-10-25/REPORT.md). Pas de clôture du brief de rupture visuelle.

## REGRESSIONS

31suites/563cas PASS sur normal/Debug/QA fusionnés. Régression de durée de ruée Sasuke détectée pendant la passe puis corrigée en accordant arrivée et séparation des corps ; assertions existantes conservées. Le vieux constat M7 du18/10 n'est pas réaffirmé : upstream a durci cette gate depuis.

## ARCHITECTURE RISKS

Réemploi de Motor/Brawler/Combat et Velmora, pas moteur parallèle. Les exceptions de saisie/orbite restent explicites. Autorité serveur inchangée ; délai visuel distinct des inputs/UI. Buffers bornés. Réseau à deux clients et latence ne sont pas validés par ces tests.

## PLAYER-FACING FAILURES

Baseline A :11/180 échantillons avec gap<2studs ; A–E +Lee A pré-fusion:0 dans chaque séquence. Ce résultat ne prouve ni absence de tout clipping de membre ni qualité des vingt fighters. Réactions, pieds, outils naturels et cadence des clashes nécessitent le rejeu normal-speed final. Screenshots pré-fusion ne sont pas des preuves finales.

## NEXT 3 PRIORITIES

1. Rejouer A–E +Lee/Itachi/Sasuke sur le Debug fusionné, observer frames et vraies entrées ; QA-001.
2. Confronter le combat normal-speed à la vidéo, corriger seulement les défauts reproduits d'appui/contact/récupération ; MOV-004/005 et COM-003/005.
3. Valider les cycles naturels/armes restantes puis deux clients/latence/manette, sans extrapoler un PASS roster ; TOOL-002/005 et NET-001.

## DO NOT TOUCH

Préserver passes Movement1–4, kits/graphes, moteur de confirmation, safety réseau, séparation jeu/plugins/Lab et travail local Forge. DEC-027 autorise cette implémentation ponctuelle ; aucune publication, nouveau roster ou caméra spectaculaire.
