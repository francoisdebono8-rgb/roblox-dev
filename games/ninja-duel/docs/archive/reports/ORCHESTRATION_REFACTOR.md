# Refactor documentaire et orchestration — 2026-10-12

Base : `bd3c483947bbf33dcc76282cf727d808c786141d`. Branche de reprise GitHub : `codex/ninja-claude-technical-prep`. Le SHA final est fourni par le commit qui contient ce rapport (`git log -1 --format=%H`), sans hash autoréférentiel dans le document. Aucun merge main, aucune publication/installation.

## Déplacé

37 documents : 9 missions Claude/brief Lab vers archive/missions ; 16 anciennes missions et fondations vers archive/missions/legacy-v0 ; 7 rapports vers reports ; ROADMAP_WEEK vers archive/plans ; 2 blueprints vers characters ; 2 documents de maintenance/release vers tools. Liste exhaustive ancienne/nouvelle, références recherchées avant déplacement, consommateurs, hashes et diff des références : [MOVE_REFERENCE_AUDIT](MOVE_REFERENCE_AUDIT.json). Le shim CLAUDE_FINAL_PASS renvoie vers START et l’archive intégrale.

## Conservé car partagé ou utile

`shared/`, tous les plugins historiques et Forge Playground, moteurs Bangla/Velmora/Place1 réellement utilisés, assets donateurs, sources/binaries du jeu, Motion Lab et son adapter. Aucun module déplacé parce que son nom paraît ancien. `design_research` conserve ses sources riches ; `docs/current` conserve les destinations des générateurs d’inventaire/mapping. Les docs Forge restent hors du jeu.

## Archivé

Missions et délais anciens, fondations, roadmap et demande utilisateur du 12 octobre. Contenus intégralement conservés ; seules références adaptées et avertissement historique du template ajouté. 59 sources et 909 titres/sections indexés : [SOURCE_COVERAGE](SOURCE_COVERAGE.md), [registre JSON](SOURCE_COVERAGE.json). La couverture pointe aux tickets, ne vaut ni approbation des candidats ni validation artistique. Vision/lore/état actifs filtrent dates, kits adultes, ancien roster et vieux bugs résolus.

## Supprimé avec justification

Aucun contenu ni composant supprimé. Le dossier missions devenu vide disparaît après relocalisation de ses fichiers. Le shim garde l’ancien point d’entrée ; toutes les sources utiles restent accessibles.

## Points ambigus laissés intacts

Anciennes références replay.sh/sweep.lua et bases externes : disponibilité non prouvée, contenu historique conservé ; aucune commande inventée. Références jeux/vidéo fournies non visionnées, inscrites PROVIDED_NOT_REVIEWED. Gaara code/tests conservés, menu caché, scope futur explicite. Permissions/publication actuelles non prouvées ; pas de faux PlaceID. L’évaluation native finale des quatre personnages et du Lab reste PENDING ; les résultats Studio historiques ne sont pas transférés.

## Créé et opérationnel

START ; sept fichiers actifs obligatoires + UPDATE_PROTOCOL ; specs combat/movement, CORE_ROSTER et quatre profils, systèmes outils/chakra/arène/futurs ; recherche/registre ; navigation tools/current/archive ; rapport, couverture et audit ; validateur `tools/check_project_docs.py`. Backlog : 73 IDs stables avec status/priority/dependencies/subsystem/character/sources/validation/evidence/outcome. Nouveau souhait : protocole de routage ; nouveau Claude : reconstruction Git et réalité Studio, plan général approuvé une fois, exécution par blocs et état mis à jour.

## Validation

Résultats exacts avant/après et identité des sources/artifacts : [ORCHESTRATION_VALIDATION](ORCHESTRATION_VALIDATION.json). Les tests automatiques ne valent pas acceptation native du feel. Aucun gameplay, animation, move, camera, balance ou code plugin volontairement changé ; les sources existantes et les cinq artifacts Roblox sont comparés par hash. Voir les limites QA-001/LAB-003.

Validation finale automatique : jeu139 cas, isolation4, Motion Lab45 + UI simulée, architecture9 tests, packaging Forge7 tests, cinq candidates Forge et33 projets Rojo PASS.99 sources/artifacts existants protégés byte-identiques, dont les trois places et les deux formats Lab. Le manifest Lab actualise seulement sa provenance sourceTree à la base préparatoire inchangée. Aucun PASS natif final n’est affirmé.

Inventaire exhaustif : [33 fichiers créés,37 déplacés,26 archivés,0 contenus supprimés](ORCHESTRATION_FILES.json). Les références Markdown locales du jeu entier ont été contrôlées : aucune destination manquante. Le validateur documentaire détecte aussi IDs dupliqués, cycles, dépendances inconnues et liens cassés (4 contre-exemples contrôlés).
