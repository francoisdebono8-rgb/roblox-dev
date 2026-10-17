# Audit documentaire — 17 octobre 2026

Base initiale `c38825d`, réactualisée avant livraison sur `04d6eb076481093ed5b17148bd449611942af256`, branche `claude/ninja-duel-2026-10-14`. Ancien workspace main `564cbe6` écarté comme source d’état. Audit documentaire et lecture ciblée de code/manifests, pas nouvelle QA native, pas audit exhaustif du runtime. Travail isolé en checkout détaché, sans branche gameplay et sans mutation des sources/artefacts de Claude.

## Inventaire et dispositions

[INVENTORY.json](INVENTORY.json) inventorie **135 Markdown** présents au HEAD : chemin original/destination, classification, empreinte initiale, lignes et titres. Inclut archives préexistantes, guides auprès du code, README, recherches, licences et couche active. Le merge Temari arrivé pendant l’audit est conservé intégralement ; son rapport et la fiche mise à jour sont inclus dans l’inventaire. Les JSON liés aux docs (couverture, inventaires et validations) sont examinés comme preuves/snapshots ; les manifests de build sont lus sans mutation.

**71 fichiers déplacés**, aucune suppression de contenu source. Missions → archive/missions ; rapports et couverture → archive/reports ; specs combat/mouvement/systèmes → archive correspondante ; design_research → archive/design_research ; handoff et animation TODO → archive/current ; anciens outils/protocole → archive/orchestration et archive/tools. La liste exacte est dans l’inventaire. Les snapshots avant-active préservent les huit fichiers actifs initiaux avec liens adaptés à leur emplacement ; empreintes du contenu initial dans l’inventaire.

Maintenus : sept propriétaires opérationnels ; START et README de navigation ; licences ; guides de diagnostic/Studio/Lab/formats explicitement non normatifs ; recherches sourcées ; sorties docs/current consommées par combat_inventory.luau. Les dix-huit fiches/blueprints/frameworks spécialisés restent sous docs/characters, explicitement non normatifs ; un redirect sans statut au chemin du rapport Naruto conserve les commentaires du runtime byte-identiques. Aucun fichier n’est supprimé parce qu’il est simplement ancien.

## Contradictions résolues

| Écart constaté | Disposition / propriétaire |
|---|---|
| Vision CORE4/~32, Gaara caché, missions 8–10, puis ordre vingt | DEC-016 ; CHR-EXT-002 porte les gates A/B/C ; huit entrées de code décrites seulement dans CURRENT_STATE |
| PvP et publication DEFERRED malgré missions et fondations fusionnées | DEC-018 ; NET-001 exige vrai flow publié ; REL-001 OPEN pour alpha, sans dépendance au polish final |
| Deux clients assimilables à online terminé | Gate distinct LIVE_ROBLOX, Studio reste étape préalable ; pas de faux PASS |
| Ancien gel ou plan encore « à approuver » dans START | Phase Claude déjà ouverte conservée ; règles de scope centralisées, audit Codex doc-only |
| « Vue en jeu » dans titre CORE4 mais corps du rapport headless | CURRENT_STATE marque explicitement NOT YET STUDIO-VALIDATED, aucun rapport historique réécrit comme preuve nouvelle |
| Fiches/ancien journal disent Naruto futur, pass récent fusionné | Sélection Legion constatée, preuve native manquante ; aucune Tier A déclarée par menu/test seuls |
| Rôles Codex limités au scaffolding, ou instructions de missions concurrentes | DEC-019 et cycle continu ; implémentation Claude, audit Codex unique |
| Protocole/outils en huitième/neufième source active | Procédure utile dans EXECUTION_RULES ; anciens fichiers archivés |
| Économie et arbres candidats confondus avec arbitrages | Faits de la fondation distingués des propositions ; chiffres non approuvés non promus, progression complète non gate alpha |
| Slogan universel 12–14 vs règle de stade plus récente | DEC-013 fait autorité ; copier des capacités endgame non autorisé, débat canon secondaire ne bloque pas la breadth |

## Exigences extraites au lieu d’être perdues

Les 75 IDs sont conservés. Critères de LOCOMOTION transférés à MOV-001/002/005 ; grammaire et tolérance des inputs à COM-002/003/005 ; signatures CORE4 à CHR-CORE-001 ; chakra comportemental à SYS-001/003 ; stade à ARENA-001 ; stress IA à AI-001 ; harness/coût clones à PERF-001 ; sérialisation/latence/déconnexion à NET-002 ; architecture hooks à ARC-002. Tier A/B/C et boucle publique explicités dans CHR-EXT-002 / NET-001 / REL-001. Grille fighter et procédure de mise à jour dans EXECUTION_RULES. Les détails, valeurs historiques, rapports et labels lore restent en archive pour provenance, jamais un second plan opérationnel.

## Ambiguïtés conservées et signalées

- Les douze places au-delà des huit du code restent à implémenter ; la directive laisse à Claude le choix des quatorze au-delà des six initiaux. Ancien pool 25/~32 non imposé.
- Budgets 120+ et coûts/arbre runtime ne sont pas un accord produit final sur toute l’économie ; monétisation/prix non approuvés par cet audit.
- Pas de preuve actuelle de manette réelle, de validation native des couches convergence3, ni de session publiée : ne pas affirmer indisponibilité de compte ni absence absolue de publication.
- Risques Naruto/Temari/chakra/online lus dans les rapports, non reproduits ; ancien biais du harness corrigé par Claude avec Temari, simulations antérieures non comparables : revue les distingue des bugs confirmés.
- Claude peut avancer pendant l’audit ; comparer à nouveau le HEAD distant avant intégration, sans écraser ses nouvelles données.
- Le fichier local non suivi PROGRESSION_SKILL_TREES_FOR_CLAUDE de l’ancien workspace n’est pas présent sur le HEAD audité ; pas d’import silencieux d’une spec concurrente.

## Validation

Résultats : contrôleur documentaire PASS (75 IDs ; tous liens Markdown locaux, y compris archives, et sept tests de reprise), architecture PASS (387 fichiers code/projet), isolation 9/9 PASS, git diff --check PASS. Inventaire 135 documents : toutes destinations présentes. Empreintes des trois artefacts conformes aux manifests. Diff de cette passe sous src/tests/dist/build.py : vide par rapport à 04d6eb0. Contrôle des liens sur tous les Markdown, couverture des sources recalculée après déplacements, sept fichiers exacts et revue six rubriques ; architecture et isolation pertinentes. Runtime/tests de gameplay/artefacts conservés byte-identiques, pas de nouvelle promesse Studio.
