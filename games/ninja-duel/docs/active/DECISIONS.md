# Décisions en vigueur

Propriétaire unique : arbitrages produit, périmètre et responsabilités. Les faits d’implémentation sont dans [CURRENT_STATE](CURRENT_STATE.md), les tâches/critères dans [MASTER_BACKLOG](MASTER_BACKLOG.md), les protocoles dans [EXECUTION_RULES](EXECUTION_RULES.md). Priorité : demande utilisateur actuelle > décision datée applicable ; signaler un conflit non résolu, sans transformer une recherche en approbation. L’historique complet DEC-001..015 est [conservé](../archive/audits/2026-10-17/before-active/DECISIONS.md).

| ID | Disposition actuelle |
|---|---|
| DEC-001 | Ancienne limite CORE4 et Gaara caché remplacée par DEC-016. Ne pas réactiver cette restriction. |
| DEC-002 | Motion Lab sous le jeu ; adapter Lab → jeu uniquement ; exports inertes jusqu’à intégration choisie. |
| DEC-003 | Jeu et plugins Forge isolés ; aucun import croisé, même via shared. |
| DEC-004 | Répartition historique Codex/Claude remplacée et précisée par DEC-019. |
| DEC-005 | Capacités sourcées, étiquettes `CANON_YOUNG`, `PLAUSIBLE_YOUNG`, `GAMEPLAY_LIBERTY`, `REJECT_ADULT_ONLY` ; interprétation par stade DEC-013. Aucun nom dans une recherche ne prouve une capacité approuvée. |
| DEC-006 | Grammaire commune, identités distinctes et contrôles simples ; réutiliser les familles réelles, pas de frameworks anticipés ou de clones de moveset. |
| DEC-007 | Preuves techniques, Studio et jugement humain distincts ; renforcé par DEC-017. |
| DEC-008 | Exigences cumulatives et provenance conservée ; seules les sept sources actives commandent l’exécution. Une archive ne lance jamais une mission. |
| DEC-009 | Gel documentaire du 12 octobre historique, non applicable à la phase Claude déjà approuvée. Aucun nouveau gameplay autorisé à Codex par l’audit. |
| DEC-010 | Ancien report général du PvP/roster/publication remplacé par DEC-012, DEC-016 et DEC-018. League/Path complets et MMO hors jalon alpha. |
| DEC-011 | Anciens apports Codex audités/repris partiellement ; aucune fusion globale de branches historiques exigée. Conserver les fondations réellement intégrées. |
| DEC-012 | Convergence approuvée le 16 octobre : combat, PvP 1v1 serveur, progression par arbres/budgets, IA à budget et roster ouverts. Pas de réécriture gratuite. |
| DEC-013 | Stade jeune/prodige intéressant avant escalade adulte, pas limite universelle 12–14 ans. Échelle endgame exclue ; noms adultes de Minato tolérés provisoirement par l’utilisateur le 16 octobre. Ne pas bloquer la breadth sur un débat canon secondaire. |
| DEC-014 | Confirmation des combos, intentions tolérantes, relance accessible, identités visibles et chakra comportemental maintenus. Son ancien gel roster n’est plus applicable (DEC-015/016). |
| DEC-015 | Autonomie de Claude dans le périmètre approuvé ; stade Chūnin agrandi, obstacles justifiés. Ancienne limite de 1–2 fighters de stress remplacée par DEC-016. |

## DEC-016 — 20 jouables breadth-first

Décision utilisateur, commit `f23c454` (texte [préservé](../archive/missions/ROSTER_20_BREADTH_PASS.md), ancêtre du HEAD audité ; date exacte à lire dans Git) : viser **20 personnages réellement jouables au total**. Partir des six initiaux ; Claude choisit les quatorze suivants selon iconicité, diversité et besoins moteur. Les pools 25/~32 et la cible intermédiaire 8–10 restent historiques. Ordre : Tier A pour tous → identité Tier B par familles → polish Tier C. Les gates détaillés appartiennent à CHR-EXT-002. Pas d’extension au-delà de vingt dans cette phase.

## DEC-017 — Studio obligatoire

Décision utilisateur, commit `3174e38`, [texte préservé](../archive/missions/STUDIO_VALIDATION_RULE.md) : toute fonctionnalité player-facing doit être exercée dans le build réel en Studio avant validation, y compris l’existant encore uniquement headless. Sans cette preuve, statut `IMPLEMENTED / NOT YET STUDIO-VALIDATED` ; aucune clôture globale « done ». Le protocole et les dimensions de preuve appartiennent à EXECUTION_RULES. Le ressenti humain reste une dimension distincte.

## DEC-018 — Alpha publique et online réel

Décision utilisateur, commit `c38825d`, [texte préservé](../archive/missions/PUBLIC_ALPHA_AFTER_ROSTER_20.md) : dès les vingt baseline suffisamment jouables et le combat online stable, viser **l’alpha publique Roblox / combat test**. Online signifie le vrai flow d’une expérience publiée : rejoindre, trouver un adversaire, sélectionner, combattre, finir, rematch/requeue et quitter/rejoindre proprement. Deux clients Studio sont une étape technique, pas la validation du produit online. Ne pas attendre VFX premium, équilibre final, progression complète ou monétisation. Gates minimum dans NET-001 et REL-001. Cette mission documentaire ne réalise aucune publication.

## DEC-019 — Boucle utilisateur / ChatGPT / Claude / Codex

Décision utilisateur du **17 octobre 2026**, [mandat préservé](../archive/requests/2026-10-17-documentation-brain.md) : **Utilisateur ↔ ChatGPT → décisions dans le repo → Claude implémente → Studio valide → Codex audite → Claude corrige/continue.** Claude reste l’implémenteur principal. Codex est reviewer technique, architecte et mainteneur continu du cerveau documentaire ; il audite après gros merges, dérive d’architecture, nouvelles décisions et avant roster 20/online public/alpha. Il ne crée pas de branche gameplay concurrente. L’audit courant ne change ni runtime, ni équilibrage, ni systèmes.

## DEC-020 — Une seule couche opérationnelle

Même mandat du 17 octobre : exactement VISION, DECISIONS, CURRENT_STATE, MASTER_BACKLOG, SINCE_LAST_CLAUDE, EXECUTION_RULES, ENGINEERING_REVIEW dans `docs/active`. Une information a un propriétaire unique. Les guides techniques documentent commandes/formats ; les recherches proposent ; les archives prouvent l’historique. Aucun de ces dossiers ne définit un second plan actif. ENGINEERING_REVIEW est court, remplacé à chaque audit, limité aux six rubriques demandées. Les audits précédents restent dans Git/archives, jamais empilés dans ce fichier.

## DEC-021 — Roadmap large, fenêtre d’exécution étroite après roster 20

Décision utilisateur du **17 octobre 2026** : une fois les **20 combattants Tier A réellement jouables**, arrêter l’expansion du roster et passer à une convergence horizontale sur les vingt. La roadmap globale reste visible, mais Claude ne doit exécuter qu’**un bloc principal à la fois**, avec critères de sortie explicites, puis s’arrêter pour rapport/synchronisation avant le bloc suivant. Ne pas lancer simultanément plusieurs grands chantiers sous prétexte qu’ils figurent dans la roadmap.

Ordre cible après roster 20 : **(1) stabilisation combat + combo/animation/réactions/hit feel transversaux sur les 20 ; (2) couche chakra/éléments/outils et afflictions réellement comportementales ; (3) pass identité combattant sur les 20 ; (4) structure compétitive + arène/mouvement/neutral/défense ; (5) online Roblox réel + flow d’alpha publique.** Le premier bloc post-roster est prioritaire : bugs combat, fiabilité des chaînes/routes/air/knockback/guard/dodge/substitution, dégâts/réactions/impacts/transitions, puis validation Studio sur l’ensemble du roster. Le principe est breadth-first à chaque passe : **20 stables → 20 bons en combo/animation → 20 intégrés au chakra → 20 identitaires → polish**, jamais finir un seul personnage à 100 % pendant que les autres restent au stade prototype.
