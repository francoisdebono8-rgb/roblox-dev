# Boîte de réception Claude

Propriétaire unique : entrées temporaires à prendre en compte, puis absorber/accuser selon EXECUTION_RULES. Faits actuels dans [CURRENT_STATE](CURRENT_STATE.md), décisions dans [DECISIONS](DECISIONS.md), tâches dans [MASTER_BACKLOG](MASTER_BACKLOG.md). Ancien journal intégral du 12–16 octobre : [archive](../archive/audits/2026-10-17/before-active/SINCE_LAST_CLAUDE.md).

## INBOX-DOC-20261017 — ACK Claude 17/10/2026 (checkpoint `fb47e88`, absorbé : START, revue, état et backlog suivis ; roster 20 poursuivi par CHR-EXT-002)

Date : 17/10/2026 ; portée : organisation documentaire uniquement ; urgence : lire avant le prochain gros bloc, sans interrompre l’implémentation en cours.

### Codex — consolidation documentaire

Base initiale : `c38825d` ; base réactualisée après avancement de Claude : `04d6eb076481093ed5b17148bd449611942af256`, branche Claude actuelle, et non le main local ancien. Mandat utilisateur : [conservation](../archive/requests/2026-10-17-documentation-brain.md). Les merges Naruto/CORE4/chakra/Temari et directives roster/Studio/alpha postérieurs au vieux journal ont été pris en compte ; leur état présent n’est pas recopié ici.

- Sept propriétaires opérationnels, START réécrit ; anciennes missions, handoffs, bilans et spécifications historiques rangés avec provenance et liens réparés. Inventaire fichier par fichier dans [AUDIT](../archive/audits/2026-10-17/AUDIT.md).
- DEC-016..020 formalisent les dernières orientations et la boucle utilisateur/ChatGPT/Claude/Studio/Codex. Anciennes restrictions CORE4, Gaara caché, gel roster, alpha différée explicitement remplacées.
- Les 75 IDs du backlog sont conservés ; CHR-EXT-001/002, QA-001, NET-001, REL-001, ARC-002 et les critères de convergence sont actualisés, sans annoncer de nouvelle feature validée.
- Aucun runtime, test gameplay, build ou artefact modifié. Les fiches spécialisées restent sous docs/characters ; le rapport Naruto garde un redirect documentaire pour le commentaire de code ; les sorties du générateur restent dans docs/current.
- Validation : documentation/liens/couverture PASS (75 IDs, sept tests de reprise) ; architecture PASS (387 fichiers) ; isolation 9/9 PASS ; diff --check PASS ; inventaire 135 documents, toutes destinations présentes ; hashes des trois artefacts conformes. Temari/vent et le correctif harness du merge 26c2526 sont absorbés dans le snapshot ; aucun de ces changements gameplay n’est de Codex. Ni Studio ni publication réalisés dans cette passe. Aucun ancien PASS copié comme nouvelle preuve.

Reprise Claude : suivre START et la revue courante, continuer le travail autorisé ; mettre à jour le snapshot sur le vrai HEAD avant de traiter ses priorités. Ce rangement ne relance aucune ancienne mission.

## INBOX-ROADMAP-20261017 — ACK Claude 17/10/2026 (`69808f4` ; DEC-021 appliquée dès que les 20 sont Tier A : arrêt du roster, rapport, un seul bloc à la fois)

Date : 17/10/2026 ; portée : séquencement post-roster ; urgence : **ne pas interrompre le breadth pass en cours**, appliquer dès que le roster atteint 20 Tier A réellement jouables.

Décision absorbée dans `DEC-021` : après les 20, **stopper l’ajout de personnages** pour cette phase. La roadmap est volontairement large mais la fenêtre d’exécution doit rester étroite : un seul gros bloc actif à la fois, puis rapport/synchronisation avant le suivant.

Séquence cible :
1. stabilisation combat + combos + animations + réactions + hit feel/dégâts sur les 20 ;
2. chakra/éléments/outils/afflictions comportementales ;
3. identité combattant sur les 20 ;
4. structure compétitive + arène/mouvement/neutral/défense ;
5. vrai online Roblox + flow alpha publique.

**Premier bloc uniquement après roster 20** : corriger les bugs combat transversaux et fiabiliser chaînes, routes, launcher/air, poursuite, knockback, garde, dodge, substitution, dégâts, mort/reset ; améliorer anticipation/contact/follow-through, transitions, hit reactions et impacts ; faire passer les 20 par la même grille et Studio. Ne pas commencer en parallèle le gros chantier chakra, l’arène compétitive ou l’alpha tant que ce premier bloc n’a pas atteint ses critères de sortie.

Principe de convergence : 20 stables → 20 bons en combo/animation → 20 intégrés au chakra → 20 identitaires → polish. Pas de personnage fini à 100 % isolément pendant que le reste du roster reste prototype.

## PASSATION-CLAUDE-20261017-SOIR — arrêt propre demandé par l'utilisateur

Branche `claude/ninja-duel-2026-10-14`, poussée. Fait ce jour (détails dans les commits et [CURRENT_STATE](CURRENT_STATE.md)) : fusions chakra2 / identité CORE4 / Naruto / Temari ; socle roster 20 (`Server/Families`, `Shared/Looks`, `Client/FamilyFX`, `Shared/Roster`, menu 5×4, `tests/Roster.spec`) ; Hinata et Kakashi ; modules par lot pré-branchés (`Shared/WaveN`, `Server/WaveNKit`, `Client/WaveNFX`) ; outil natif `tools/studio/fighter_check.py` ; corrections vues en Studio (entrave dessinée, bêtes lisibles, couloir de vent). Sélection : 10 combattants.

En cours, **non fusionné** : lots 1–3 du roster 20 (Sakura, Choji, Kiba, Kimimaro / Shikamaru, Shino, Orochimaru / Haku, Zabuza, Kisame) sur les branches locales `claude/nd-r20-wave1..3` (worktrees `%LOCALAPPDATA%/Temp/ndwt/waveN`), arrêtés en WIP : état et SHA de chaque lot = dernier commit `wip(ninja-duel): roster 20 wave N` de sa branche (ce qui est fait, partiel ou absent y est listé).

Reprise : fusionner chaque lot (union des lignes Roster/run.sh/build.py, `dist/` reconstruit), `tests/Roster.spec` sur toute la liste, puis `fighter_check.py` en Studio pour chaque nouveau combattant ; rejouer Itachi, Sasuke, Neji, Gaara, Lee ; revoir le couloir de Temari ; à 20 Tier A : rapport roster (tableau DEC-016/CHR-EXT-002) puis arrêt selon DEC-021.
