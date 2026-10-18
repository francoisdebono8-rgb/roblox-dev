# Boîte de réception Claude

Propriétaire unique : notifications temporaires à accuser puis absorber selon [EXECUTION_RULES](EXECUTION_RULES.md). Décisions dans [DECISIONS](DECISIONS.md), faits dans [CURRENT_STATE](CURRENT_STATE.md), travail dans [MASTER_BACKLOG](MASTER_BACKLOG.md).

## INBOX-AUDIT-ROSTER20-20261017 — PENDING ACK Claude

Demande utilisateur : audit complet avant nouvelle passe gameplay, sans corrections runtime Codex. Lecture prioritaire : [ENGINEERING_REVIEW](ENGINEERING_REVIEW.md), puis [preuves et classement datés](../archive/audits/2026-10-17-roster20/AUDIT.md). Appliquer les critères des tickets existants et la séquence DEC-021 ; ne pas interpréter le checkpoint « Tier A » comme clôture de la gate native.

Les anciennes entrées ACK et la passation désormais dépassée à dix sont conservées dans le [snapshot avant audit](../archive/audits/2026-10-17-roster20/before-active/SINCE_LAST_CLAUDE.md). Elles ne constituent plus des missions ouvertes. À réception, ajouter l'ACK/commit et conserver les faits et tâches uniquement dans leurs propriétaires.

## INBOX-INCREMENTAL-20261018 — ACK Claude 18/10 (M1→M6 livrés, voir CURRENT_STATE ; M7 suivant)

Préparation demandée par l'utilisateur, HEAD bc7faa3. Les corrections déjà livrées sont reconnues ; lire la [revue remplacée](ENGINEERING_REVIEW.md), puis les petits packets M1–M7 sous [QA-004](MASTER_BACKLOG.md#qa-004--reproduire-séquences-anormales-et-cycle-de-match). [Preuves ciblées et fiches des anciens WEAK](../archive/audits/2026-10-18-feel-preparation/AUDIT.md). L'ancien inbox reste sans ACK explicite ; ne pas recréer ses défauts déjà corrigés ni poursuivre une ancienne revue à l'aveugle. Aucun runtime modifié par Codex.

## INBOX-FICHES20-20261018 — SUPERSEDED par DEC-026 (pas ACK implicite)

DEC-025 : l’utilisateur demande une fiche par personnage et signale une identité/chakra insuffisamment perceptible en jouant. Lire l’[index20](../characters/ROSTER_20.md) puis uniquement les fiches du lot traité ; les cibles de gestes/mirages/chakra ne sont pas des mécaniques déjà validées. CHR-CORE-001/002 et SYS-001 portent les critères. Cette préparation ne remplace pas M1–M7 de QA-004 ni la séquence DEC-021. Les anciennes fiches détaillées sont conservées sous docs/archive/characters/2026-10-18-before-profiles ; aucun runtime modifié. Accuser à la reprise sans redécouvrir les chiffres dans les sources.

## INBOX-BIBLES-V1-20261018 — PENDING ACK Claude

Nouveau brief utilisateur : **roster et définition V1 remplacés**, [DEC-026](DECISIONS.md#dec-026--roster-cible-et-character-v1-combat-bibles). [Index20 / A–E](../characters/ROSTER_20.md) :17conservés + Madara/Hashirama/Hiruzen enfants ; Hinata/Temari/Kabuto hors cible, encore dans runtime. Lire seulement la bible du sous-lot ouvert. Bee multi-sabres, Kimimaro squelette vivant et corps/animations/échanges complets sont fondamentaux V1 ; pas attendre chakra/armes globaux finaux. Anciennes fiches de61eb585 conservées, ne plus les exécuter comme cible.

**Ne pas interrompre le bloc en cours.** Codex a livré uniquement du design, aucun runtime/build/test gameplay modifié. Ouverture des sous-lots dans CHR-CORE-001 et migration dans CHR-EXT-002 ; les tables de design sont une préparation, pas un ordre de tout implémenter. Accuser réception avant la prochaine grosse passe identité.

Mise à jour de base : M1 de Claude `41364ed` intégré avant publication de ces bibles ; correction persist/poison reconnue, aucune demande de la refaire. Rejouer les scénarios natifs M1 avant clôture ; continuer le bloc en cours.
