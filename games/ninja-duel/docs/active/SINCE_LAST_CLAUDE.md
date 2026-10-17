# Boîte de réception Claude

Propriétaire unique : notifications temporaires à accuser puis absorber selon [EXECUTION_RULES](EXECUTION_RULES.md). Décisions dans [DECISIONS](DECISIONS.md), faits dans [CURRENT_STATE](CURRENT_STATE.md), travail dans [MASTER_BACKLOG](MASTER_BACKLOG.md).

## INBOX-AUDIT-ROSTER20-20261017 — PENDING ACK Claude

Demande utilisateur : audit complet avant nouvelle passe gameplay, sans corrections runtime Codex. Lecture prioritaire : [ENGINEERING_REVIEW](ENGINEERING_REVIEW.md), puis [preuves et classement datés](../archive/audits/2026-10-17-roster20/AUDIT.md). Appliquer les critères des tickets existants et la séquence DEC-021 ; ne pas interpréter le checkpoint « Tier A » comme clôture de la gate native.

Les anciennes entrées ACK et la passation désormais dépassée à dix sont conservées dans le [snapshot avant audit](../archive/audits/2026-10-17-roster20/before-active/SINCE_LAST_CLAUDE.md). Elles ne constituent plus des missions ouvertes. À réception, ajouter l'ACK/commit et conserver les faits et tâches uniquement dans leurs propriétaires.

## INBOX-INCREMENTAL-20261018 — PENDING ACK Claude

Préparation demandée par l'utilisateur, HEAD bc7faa3. Les corrections déjà livrées sont reconnues ; lire la [revue remplacée](ENGINEERING_REVIEW.md), puis les petits packets M1–M7 sous [QA-004](MASTER_BACKLOG.md#qa-004--reproduire-séquences-anormales-et-cycle-de-match). [Preuves ciblées et fiches des anciens WEAK](../archive/audits/2026-10-18-feel-preparation/AUDIT.md). L'ancien inbox reste sans ACK explicite ; ne pas recréer ses défauts déjà corrigés ni poursuivre une ancienne revue à l'aveugle. Aucun runtime modifié par Codex.

## INBOX-FICHES20-20261018 — PENDING ACK Claude

DEC-025 : l’utilisateur demande une fiche par personnage et signale une identité/chakra insuffisamment perceptible en jouant. Lire l’[index20](../characters/ROSTER_20.md) puis uniquement les fiches du lot traité ; les cibles de gestes/mirages/chakra ne sont pas des mécaniques déjà validées. CHR-CORE-001/002 et SYS-001 portent les critères. Cette préparation ne remplace pas M1–M7 de QA-004 ni la séquence DEC-021. Les anciennes fiches détaillées sont conservées sous docs/archive/characters/2026-10-18-before-profiles ; aucun runtime modifié. Accuser à la reprise sans redécouvrir les chiffres dans les sources.
