## BLOCKERS

Audit Codex du 17/10, HEAD `b3f8ffb` (lecture runtime/documents ; tests Luau/Lune indisponibles, pas Studio). PROG-001/002 restent fondations : [état](../../../../active/CURRENT_STATE.md). Avant leur implémentation, arbitrer T1 (prêt des options/prérequis en tournoi), P1/P2 dans la [proposition](../../../../systems/PROGRESSION_MASTERY_PROPOSAL.md). Ce ne sont pas des blockers pour poursuivre le roster.

## REGRESSIONS

Aucune nouvelle régression gameplay reproduite. Ne pas qualifier de bugs les systèmes non encore intégrés ; les cas existants ne sont pas rejoués faute d’outils.

## ARCHITECTURE RISKS

ProfileSchema dépend de l’existence d’un arbre (CORE4 seulement), ne représente ni collection ni maîtrises. admit dépend des unlocked ; Online:fight ne passe pas de kit. Les “Mastery” Chakra sont des profils fixes, pas des acquis. Le ring d’impacts/tuto n’est pas un ledger fiable. Règles de composition, migration et déduplication à traiter au pilote, sans refonte moteur préventive.

## PLAYER-FACING FAILURES

Absences de flow, pas nouveaux FAIL Studio : progression/maîtrises/tournoi standardisé non intégrés. Le roster expose dix noms sur vingt ciblés. Les observations natives partielles de Claude sur Naruto/Temari/Hinata/Kakashi restent valides dans leur portée ; ne plus dire que tout est uniquement headless. Manette et online publié restent non prouvés au snapshot.

## NEXT 3 PRIORITIES

1. CHR-EXT-002 : poursuivre les dix places verrouillées de DEC-022 avec les gates Studio par lot.
2. À vingt Tier A : appliquer le premier bloc combat/combos/animations de DEC-021, puis rapport et synchronisation ; pas tous les grands chantiers en parallèle.
3. PROG-001/002 : faire arbitrer la proposition préparatoire et conserver ses risques pour la phase suivante ; aucune activation gameplay ou monétisation par cet audit.

## DO NOT TOUCH

Aucun runtime, coût, contrôle, profil live, artefact ou gameplay modifié par Codex. Claude reste implémenteur ; DEC-021 fixe la séquence. Ne pas adopter coûts des mini-arbres, catalogue prêté ou tailles recommandées comme décisions validées. Préserver autorité serveur, base niveau1, branches de Claude et frontières Forge/Lab.
