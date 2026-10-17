# État vérifié — audit documentaire du 17 octobre 2026

**Snapshot : `04d6eb076481093ed5b17148bd449611942af256`, branche `claude/ninja-duel-2026-10-14`.** Audit de code ciblé, Git, documents et manifests ; aucun test gameplay/Studio exécuté par Codex dans cet audit. Claude peut avancer après ce checkpoint : vérifier Git avant reprise. La copie locale main `564cbe6` et la préparation Codex ne décrivent pas cet état.

| Domaine | Fait au checkpoint | Preuve et limite |
|---|---|---|
| Sélection | **8 entrées** : Minato/Flashstep, Itachi/Mirage, Neji/GentleFist, Sasuke/Lion, Gaara/Sand, Lee/Leaf, Naruto/Legion, Temari/Gale | Liste `playable` de `src/Client/UI.luau`. Une entrée ne prouve pas Tier A. Les 12 autres places ne sont pas implémentées ici. |
| CORE4, Gaara, Lee | Combat et premières preuves Studio historiques ; qualité/feel non clos | [Bilan convergence 2](../archive/reports/convergence2/FINAL_REPORT.md). Ancien menu six, routes, dash et certains effets observés le 16 octobre ; pas acceptation globale de l’artefact courant. |
| Naruto / corps secondaires | **IMPLEMENTED / NOT YET STUDIO-VALIDATED** | Merge `caef06f`, `Bodies`, `BodyViews`, `Legion`, `NarutoFX`, suite Naruto ; [rapport](../archive/reports/convergence3/NARUTO.md) explicitement headless. Clones/contre-jeu/routes/Rasengan/substitution/éveil et coût client restent à jouer. |
| Temari / zones de vent | **IMPLEMENTED / NOT YET STUDIO-VALIDATED** | Merge `26c2526`, `Zones`, `Gale`, `GaleFX/GaleMotion` ; [rapport](../archive/reports/convergence3/TEMARI.md) explicitement headless : éventail, couloirs, vent/projectiles, éveil et IA à jouer en Studio. |
| Identité CORE4, couche récente | **IMPLEMENTED / NOT YET STUDIO-VALIDATED** | Merge `b25d230`, `IdentityFX` et [rapport](../archive/reports/convergence3/CORE4_IDENTITY.md) : en dépit du titre « vue en jeu », le corps du rapport dit rien observé en Studio. Tenketsu, sceaux, Read, marque/Chidori à valider en mouvement. |
| Chakra, couche récente | **IMPLEMENTED / NOT YET STUDIO-VALIDATED** | Merge `738b449`, `ChakraFX`, fil-objet/conduction/repères, [rapport](../archive/reports/convergence3/CHAKRA_PLAYER_LAYER.md). Rapport headless ; les anciennes observations du kunai de vent ne valident pas cette nouvelle couche. |
| Mouvement, réactions, caméra | Implémentés, validation partielle historique | [Mesures natives](../archive/reports/convergence/VISUAL_AUDIT.md), [contact](../archive/reports/convergence/CONTACT_AND_REACTIONS.md). Quelques défauts corrigés au fil des passes ; aucune garantie de feel final. |
| Stade | Recomposition récente vers une enceinte Chūnin | `ccd1629` ; nouvelles proportions à confronter au parcours, murs/corniches, caméra et IA dans Studio. |
| Online | Fondation serveur intégrée ; produit online non validé | [Rapport](../archive/reports/ONLINE_FOUNDATION.md) : queue casual et codes **par serveur**, sélection, duel deux humains, rematch/forfait. Deux clients/latence non prouvés ; aucune preuve de session Roblox publiée. Départ = forfait, rejoin = nouvelle session (pas de reprise transparente). |
| Progression | Fondation CORE4 intégrée ; intégration joueur incomplète | [Rapport](../archive/reports/PROGRESSION_FOUNDATION.md) et [formats](../systems/PROGRESSION.md) : arbres, validation de builds et budgets ; pas UI ni persistance réelle branchée prouvées. Budgets présents 50/80/100/120+ : faits du code, pas arbitrage économique final. |
| Inputs | Clavier/PS5 testés techniquement ; clavier réel historiquement joué | Manette physique et feel encore PENDING ; ne pas inférer l’ergonomie d’un callback. |
| IA | Combat et réponses spécifiques intégrés | Stress tests historiques headless ; utilisation complète du stade/pièges et diversité en natif restent partielles. |
| Motion Lab/outils | Lab et diagnostics intégrés, isolés du normal | Tests/smokes historiques ; disponibilité et QA de la session à revérifier selon EXECUTION_RULES. |
| Publication | **NON VÉRIFIÉE** | Pas de PlaceID/version/URL ni test live probant dans les sources examinées. L’absence de preuve ne prouve pas une impossibilité du compte. |

Les trois manifests version `0.13.0-arena-combo` enregistrent `automatedQA=PASS`, `sourceEquality=PASS`, **25 suites / 470 cas** (lecture des summaries, pas nouvelle exécution). Leurs statuts natifs/visuels/manette restent PENDING. Hash du normal enregistré : `53c428359ec461a756c75489a545ac6453e62a743b617ea5b8b0e442644987a4`. Ne pas déduire de la seule étiquette de version que ces builds correspondent à une ancienne branche ; vérifier les empreintes/sources.

Correctif harness intégré avec Temari : un déplacement par frame à durée réelle, au lieu de cumuler les appels Move (ancien biais mesuré 3,3× dans son rapport). Les anciennes statistiques de duels ne se comparent pas directement ; correctif non réexécuté ici.

Risques signalés dans les rapports, non reproduits ici : clones qui traversent le décor et ne montent pas la corniche ; coût des copies client ; asymétrie d’ordre des sièges et fenêtre anti-cheat sous gigue ; couche HUD chakra filtrée ; IA n’évitant pas les hazards. Ils restent des risques à reproduire, pas des régressions confirmées par cet audit.

Critères, actions et priorités : [MASTER_BACKLOG](MASTER_BACKLOG.md). Diagnostic Codex courant : [ENGINEERING_REVIEW](ENGINEERING_REVIEW.md). Inventaire des documents/contradictions et historique exact : [audit](../archive/audits/2026-10-17/AUDIT.md).
