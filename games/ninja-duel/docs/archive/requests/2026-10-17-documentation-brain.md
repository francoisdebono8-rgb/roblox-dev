# Mandat utilisateur — 17 octobre 2026

Provenance : deux messages directs utilisateur du chat Codex du 17 octobre 2026 ; consolidation documentaire autorisée, pas de gameplay, pas de branche de développement concurrente. Les décisions reprises des fichiers du repo gardent leur commit source dans DECISIONS.

## Première demande

Auditer tous les documents de games/ninja-duel ; identifier obsolescence, missions exécutées, handoffs historiques, doublons, décisions contradictoires et exigences uniquement dans de vieux fichiers. Rien supprimer sans raison ; archiver l’historique utile et consolider l’opérationnel.

Les seules sources opérationnelles demandées : VISION, DECISIONS, CURRENT_STATE, MASTER_BACKLOG, SINCE_LAST_CLAUDE, EXECUTION_RULES et nouveau ENGINEERING_REVIEW dans docs/active. Une information, un propriétaire actif.

Intégrer les décisions déjà présentes dans le repo : vingt jouables breadth-first, Studio obligatoire pour le player-facing, alpha publique dès vingt baseline et online de base suffisamment jouables, online = vrai flow Roblox publié (pas deux clients locaux), Claude implémenteur principal, Codex reviewer/tech lead continu.

ENGINEERING_REVIEW court, vivant, remplacé à chaque audit, uniquement BLOCKERS / REGRESSIONS / ARCHITECTURE RISKS / PLAYER-FACING FAILURES / NEXT 3 PRIORITIES / DO NOT TOUCH. START lit les sources actives puis la revue ; archives historiques uniquement. Réparer tous les liens après rangement ; pas de runtime sauf référence documentaire strictement nécessaire. HEAD réel avant toute hypothèse de branche. Rapport final très court : actifs, archives, contradictions, ambiguïtés.

## Précision utilisateur pendant l’audit

« Tu n’es pas l’implémenteur principal de Ninja Duel. Claude l’est. »

L’utilisateur pilote surtout avec ChatGPT, qui formalise les décisions produit et priorités. Codex est reviewer technique, architecte et mainteneur du cerveau documentaire. Intégrer les décisions dans les sources de vérité, les rendre faciles à retrouver par Claude, éviter l’accumulation de missions/handoffs contradictoires.

Intervenir après gros merges Claude, dérive architecturale, décisions importantes et avant roster 20 / online public / alpha. Auditer HEAD, comparer à vision/décisions/Studio, mettre à jour une seule revue.

Fonctionnement : **Utilisateur ↔ ChatGPT → décisions dans le repo → Claude implémente → Studio valide → Codex audite → Claude corrige/continue.** Commencer par la consolidation existante, sans concurrence d’implémentation.

## Contexte utilisateur explicite du même chat (15 octobre)

Abandon du shinobi personnel ; progression/amélioration des personnages définis. Multijoueur en ligne et boucle de jeu prioritaires après la qualité du combat. Ces précisions viennent des corrections directes de l’utilisateur, pas des anciennes propositions de l’assistant.

Dernière précision intégrale : [demande utilisateur](2026-10-17-active-brain-user-request.md). SINCE_LAST_CLAUDE est une inbox temporaire avec ACK, pas un journal cumulatif. Les docs spécialisées peuvent rester ; aucune ne fixe les priorités globales.
