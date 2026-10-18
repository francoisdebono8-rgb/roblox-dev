# Boîte de réception Claude

Propriétaire unique : notifications temporaires à accuser puis absorber selon [EXECUTION_RULES](EXECUTION_RULES.md). Décisions dans [DECISIONS](DECISIONS.md), faits dans [CURRENT_STATE](CURRENT_STATE.md), travail dans [MASTER_BACKLOG](MASTER_BACKLOG.md).

## INBOX-AUDIT-ROSTER20-20261017 — PENDING ACK Claude

Demande utilisateur : audit complet avant nouvelle passe gameplay, sans corrections runtime Codex. Lecture prioritaire : [ENGINEERING_REVIEW](ENGINEERING_REVIEW.md), puis [preuves et classement datés](../archive/audits/2026-10-17-roster20/AUDIT.md). Appliquer les critères des tickets existants et la séquence DEC-021 ; ne pas interpréter le checkpoint « Tier A » comme clôture de la gate native.

Les anciennes entrées ACK et la passation désormais dépassée à dix sont conservées dans le [snapshot avant audit](../archive/audits/2026-10-17-roster20/before-active/SINCE_LAST_CLAUDE.md). Elles ne constituent plus des missions ouvertes. À réception, ajouter l'ACK/commit et conserver les faits et tâches uniquement dans leurs propriétaires.

## INBOX-INCREMENTAL-20261018 — ACK Claude 18/10 (M1→M6 livrés, voir CURRENT_STATE ; M7 suivant)

Préparation demandée par l'utilisateur, HEAD bc7faa3. Les corrections déjà livrées sont reconnues ; lire la [revue remplacée](ENGINEERING_REVIEW.md), puis les petits packets M1–M7 sous [QA-004](MASTER_BACKLOG.md#qa-004--reproduire-séquences-anormales-et-cycle-de-match). [Preuves ciblées et fiches des anciens WEAK](../archive/audits/2026-10-18-feel-preparation/AUDIT.md). L'ancien inbox reste sans ACK explicite ; ne pas recréer ses défauts déjà corrigés ni poursuivre une ancienne revue à l'aveugle. Aucun runtime modifié par Codex.

## INBOX-FICHES20-20261018 — SUPERSEDED par DEC-026 (pas ACK implicite)

DEC-025 : l’utilisateur demande une fiche par personnage et signale une identité/chakra insuffisamment perceptible en jouant. Lire l’[index20](../characters/ROSTER_20.md) puis uniquement les fiches du lot traité ; les cibles de gestes/mirages/chakra ne sont pas des mécaniques déjà validées. CHR-CORE-001/002 et SYS-001 portent les critères. Cette préparation ne remplace pas M1–M7 de QA-004 ni la séquence DEC-021. Les anciennes fiches détaillées sont conservées sous docs/archive/characters/2026-10-18-before-profiles ; aucun runtime modifié. Accuser à la reprise sans redécouvrir les chiffres dans les sources.

## INBOX-BIBLES-V1-20261018 — ACK Claude 18/10 (3 nouveaux jouables, menu 17+3 ; bibles des 17 non entamées)

Nouveau brief utilisateur : **roster et définition V1 remplacés**, [DEC-026](DECISIONS.md#dec-026--roster-cible-et-character-v1-combat-bibles). [Index20 / A–E](../characters/ROSTER_20.md) :17conservés + Madara/Hashirama/Hiruzen enfants ; Hinata/Temari/Kabuto hors cible, encore dans runtime. Lire seulement la bible du sous-lot ouvert. Bee multi-sabres, Kimimaro squelette vivant et corps/animations/échanges complets sont fondamentaux V1 ; pas attendre chakra/armes globaux finaux. Anciennes fiches de61eb585 conservées, ne plus les exécuter comme cible.

**Ne pas interrompre le bloc en cours.** Codex a livré uniquement du design, aucun runtime/build/test gameplay modifié. Ouverture des sous-lots dans CHR-CORE-001 et migration dans CHR-EXT-002 ; les tables de design sont une préparation, pas un ordre de tout implémenter. Accuser réception avant la prochaine grosse passe identité.

Mise à jour de base : M1 de Claude `41364ed` intégré avant publication de ces bibles ; correction persist/poison reconnue, aucune demande de la refaire. Rejouer les scénarios natifs M1 avant clôture ; continuer le bloc en cours.

## INBOX-AUDIT-5bb52fd-aeff49a — ACK Claude 18/10 (F1/F3 faits dans DevGateCheck ; F2 : trois builds reconstruits)

Audit incrémental demandé par l’utilisateur : [ENGINEERING_REVIEW](ENGINEERING_REVIEW.md), [preuves et trois missions](../archive/audits/2026-10-18-5bb52fd-aeff49a/AUDIT.md), corrections de gate sous QA-004. M5/M6 préservés ; M7 ne peut plus être considéré clos sur son seul PASS. Aucun gameplay Codex. Avant prochain lot identité, fiabiliser verdict/négatifs/S20 puis rebuild/rejeu exact ; pas de nouvelle décision produit.

## INBOX-R15-20261018 — ACK Claude 18/10 (passe R15 conservée lors de la fusion Wave4)

Demande directe utilisateur autorisant Codex à améliorer visuellement les R15 : MOV-005 reçoit une passe client limitée (horloge de réception par acteur, détente progressive, cadence murale sur vitesse dessinée). [Rapport / hashes / preuves](../archive/reports/r15-2026-10-18/REPORT.md). Trois builds et511cas PASS par variante ; Debug exact vérifié en Studio. Aucun nouveau kit/serveur/graphe. Brouillon ND-Debug-new3 restauré en conservant Wave4 ; fusionner ses hooks sans perdre cette passe. Réserves M7/S20 précédentes maintenues ; ancien QA périmé résolu par rebuild, pas par changement de gate.

## INBOX-R15-COMMON-20261018 — PENDING ACK Claude

Passe client directement demandée par l’utilisateur : branche `codex/ninja-r15-common-pass`, base distante `b445df5`. [Rapport](../archive/reports/r15-common-2026-10-18/REPORT.md), suivi MOV-002 et CURRENT_STATE. Un module, pas de kit/serveur/graphes ; préserve les clips Wave1/3/4. Préserver les corrections ciblées de pas/strafe/reset dans les prochains lots V1 et rejouer leurs scénarios lors des prochaines intégrations. Les gates visuelles/humaines des vingt restent ouvertes. Ne pas interrompre le sous-lot roster en cours.
