## BLOCKERS

Audit Codex `5bb52fd..aeff49a`, 18/10. Aucun P0 gameplay reproduit. **P1 : la clôture M7/QA-004 n’est pas fiable** : son verdict ne teste que les résidus du reset, pas la réussite de la séquence. Logs Studio présents : PASS avec lights=0, route=Light1 et air=0. Une passe ultérieure correcte existe ; elle ne répare pas le faux positif. [Preuves et missions](../archive/audits/2026-10-18-5bb52fd-aeff49a/AUDIT.md).

## REGRESSIONS

Aucune nouvelle régression gameplay reproduite ; 28 suites/508 cas et neuf tests d’isolation PASS. Ne pas rouvrir M1–M3 depuis l’ancienne revue. P2 : QA embarque un DevGateCheck antérieur au HEAD ; Debug concorde. P2 : S20 n’assert pas les dégâts du kunai après fermeture (rejeu Codex :3.0, comportement actuel correct).

## ARCHITECTURE RISKS

M5 utilise snapshot/buff serveur, M6 réutilise kind/reaction/air et le couperet existant : pas moteur parallèle. Gates positives seules et chaîne QA qui ignore les échecs créent une confiance excessive. Préserver invariants de confirmation et exceptions de poursuite Lion/Leaf ; éviter une infrastructure QA générique.

## PLAYER-FACING FAILURES

Les progrès tactiques/poids ne valident pas vingt identités V1. M7 replace les acteurs entre étapes malgré la mention « sans replacement » ; vraie séquence continue, S19/S21 complet/S23/S24, manette/feel restent à prouver. Aucun nouveau PASS visuel ou live Roblox Codex.

## NEXT 3 PRIORITIES

1. Claude : rendre M7 fail-closed et ses exceptions explicites ; négatifs ciblés ; ajouter l’assert post-fermeture S20. Points précis dans le rapport, QA-004.
2. Reconstruire normal/Debug/QA après correction, vérifier source-hashes/fingerprint et rejouer M7 corrigé ; corriger la portée du rapport.
3. Valider S22–S24 aux vraies touches sur le build final, puis ouvrir un petit lot des bibles DEC-026 via MASTER_BACKLOG, pas une nouvelle passe globale.

## DO NOT TOUCH

Codex n’a modifié ni gameplay, ni tests, ni builds. Préserver M1–M6 livrés et les contrats communs. Pas hub/arbre/progression ni migration prématurée17+3. Les vingt de M7 sont les anciens IDs ; cible et extrapolations des bibles inchangées.
