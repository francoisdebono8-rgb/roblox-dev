# Boîte de réception Claude

Propriétaire unique : entrées temporaires à prendre en compte, puis absorber/accuser selon EXECUTION_RULES. Faits actuels dans [CURRENT_STATE](../../../../active/CURRENT_STATE.md), décisions dans [DECISIONS](../../../../active/DECISIONS.md), tâches dans [MASTER_BACKLOG](../../../../active/MASTER_BACKLOG.md). Ancien journal intégral du 12–16 octobre : [archive](../../2026-10-17/before-active/SINCE_LAST_CLAUDE.md).

## INBOX-DOC-20261017 — ACK Claude 17/10/2026 (checkpoint `fb47e88`, absorbé : START, revue, état et backlog suivis ; roster 20 poursuivi par CHR-EXT-002)

Date : 17/10/2026 ; portée : organisation documentaire uniquement ; urgence : lire avant le prochain gros bloc, sans interrompre l’implémentation en cours.

### Codex — consolidation documentaire

Base initiale : `c38825d` ; base réactualisée après avancement de Claude : `04d6eb076481093ed5b17148bd449611942af256`, branche Claude actuelle, et non le main local ancien. Mandat utilisateur : [conservation](../../../requests/2026-10-17-documentation-brain.md). Les merges Naruto/CORE4/chakra/Temari et directives roster/Studio/alpha postérieurs au vieux journal ont été pris en compte ; leur état présent n’est pas recopié ici.

- Sept propriétaires opérationnels, START réécrit ; anciennes missions, handoffs, bilans et spécifications historiques rangés avec provenance et liens réparés. Inventaire fichier par fichier dans [AUDIT](../../2026-10-17/AUDIT.md).
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

Branche `claude/ninja-duel-2026-10-14`, poussée. Fait ce jour (détails dans les commits et [CURRENT_STATE](../../../../active/CURRENT_STATE.md)) : fusions chakra2 / identité CORE4 / Naruto / Temari ; socle roster 20 (`Server/Families`, `Shared/Looks`, `Client/FamilyFX`, `Shared/Roster`, menu 5×4, `tests/Roster.spec`) ; Hinata et Kakashi ; modules par lot pré-branchés (`Shared/WaveN`, `Server/WaveNKit`, `Client/WaveNFX`) ; outil natif `tools/studio/fighter_check.py` ; corrections vues en Studio (entrave dessinée, bêtes lisibles, couloir de vent). Sélection : 10 combattants.

Roster 20, anciens lots 1–3 (Sakura, Choji, Kiba, Kimimaro / Shikamaru, Shino, Orochimaru / Haku, Zabuza, Kisame) : **arrêtés avant code**, rien à fusionner (worktrees vides retirés). Leurs constats sur le code commun restent utiles dans les [notes de reprise](../../../../characters/ROSTER_20.md#notes-de-reprise-1710-relevees-par-les-anciens-lots-avant-code), mais leur composition n'est plus normative après DEC-022.

Reprise : suivre la composition verrouillée de DEC-022 et `ROSTER_20.md`, puis `tests/Roster.spec` sur toute la liste et `fighter_check.py` en Studio pour chaque nouveau combattant ; rejouer Itachi, Sasuke, Neji, Gaara, Lee ; revoir le couloir de Temari ; à 20 Tier A : rapport roster (tableau DEC-016/CHR-EXT-002) puis arrêt selon DEC-021.

## INBOX-ROSTER-20261017 — ACK Claude 18/10 (les dix implémentés Tier A, voir CURRENT_STATE)

Le roster des dix places restantes est désormais verrouillé dans **DEC-022** : **Shisui, Orochimaru, Haku, Kimimaro, Nagato, Sasori, Deidara, Killer Bee, Zabuza, Kabuto**.

Les anciens candidats non encore codés (Sakura, Choji, Kiba, Shikamaru, Shino, Kisame) sortent du roster initial. Ne pas relancer leurs lots.

Règle de conception : toutes les générations de Naruto sont permises pour choisir les personnages, mais chacun reste dans une **version jeune/prodige** cohérente avec ce qu'il maîtrisait alors ; pas de kit adulte final importé par défaut. Les membres d'un même clan doivent garder des boucles de jeu distinctes. Le nombre de jutsus peut être asymétrique : équilibrer les décisions utiles et l'identité, pas le nombre de techniques.

## INBOX-PLAYER-EXPERIENCE-20261017 — ACK Claude 18/10 (lu ; non entamé, DEC-021)

Décision utilisateur du 17/10 : la cible produit est maintenant beaucoup plus précise. **Ne pas interrompre le roster 20 pour construire ces systèmes immédiatement** ; les absorber dans les prochaines passes conformément à DEC-021. Les décisions normatives sont DEC-023/024 et la vision détaillée est dans `VISION.md`.

Expérience cible : le joueur n’arrive pas dans une ville Roblox générique ni dans un menu abstrait. Il entre dans une **enceinte compacte de tournoi des jeunes prodiges**, ambiance salle d’examen avant l’épreuve. Le monde relie entraînement, progression, classement, tournoi et présence sociale, mais ne crée jamais du temps mort : un joueur habitué doit pouvoir se battre presque immédiatement.

Première session : courte intro → choix du premier prodige parmi une sélection de départ → tuto combat utile → duel IA → retour libre au hub. Aucun système de quêtes artificielles type « tue cinq bandits ». Practice, progression, tournoi et menus doivent rester accessibles sans friction.

Progression : **deux couches complémentaires**. (1) arbre propre à chaque combattant, points investis dans des choix réels de gameplay ; (2) maîtrises gagnées par pratique pertinente, qualité et variété d’usage. Les maîtrises peuvent ouvrir/conditionner des variantes ou nœuds avancés mais ne doivent jamais devenir un compteur de spam. La salle d’entraînement sert réellement à tester, apprendre, développer une maîtrise et essayer les 20 combattants même non possédés.

Compétitif : dans le tournoi/ranked principal, on ne sélectionne que des combattants débloqués sur son compte, mais chaque combattant reçoit un **budget de points standardisé** dans son arbre. La progression permanente ne donne donc pas plus de puissance en tournoi. Le main expérimenté gagne par connaissance de son personnage, de ses builds et des matchups. Plusieurs builds tournoi sauvegardables ; événements spéciaux pouvant ouvrir tout le roster.

Économie future : **pay-to-time**, pas pay-to-win compétitif. Le joueur peut accélérer accès/progression/collection et acheter du statut/cosmétique ; il ne peut pas acheter un budget de tournoi supérieur. Axe produit/marketing à préserver : **« Choisis ton prodige. Maîtrise-le. Entre dans le tournoi. »**


## INBOX-PROGRESSION-ARCH-20261017 — ACK Claude 18/10 (proposition conservée, non implémentée)

Demande utilisateur : [source intégrale](../../../requests/2026-10-17-progression-mastery-architecture.md). Base auditée `b3f8ffb`. [Proposition](../../../../systems/PROGRESSION_MASTERY_PROPOSAL.md) reliée à PROG-001/002 et DEC-024 : réutilisation SkillBuilds/ProfileRepository, schéma versionné, maîtrises par preuves, tournoi standardisé, trois mini-arbres Lee/Minato/Temari, UX et étapes.

**Ne pas interrompre le roster V1 ni modifier le gameplay pour cette inbox.** Aucun design proposé n’est validé par sa livraison. T1 (prêt de nodes/prérequis de maîtrise en tournoi), P1 (progression/déblocages) et P2 (format/budget) portent USER DECISION REQUIRED. Le niveau1 complet et la preuve de maîtrise non achetable sont précisés dans DEC-024. À reprise : accuser réception et garder la proposition comme préparation de la phase ultérieure, pas comme chantier parallèle.
