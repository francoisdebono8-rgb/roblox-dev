# Règles d’exécution

## Reprise et autorité

Lire START puis les six sources par rôle, enfin ENGINEERING_REVIEW. Vérifier `git status --short`, `git branch --show-current`, `git rev-parse HEAD`, `git log` et les changements depuis le dernier checkpoint du journal. Ni main ni une ancienne branche Codex n’est autoritaire par défaut. Comparer historique/diffs/décisions avant de trancher une divergence ; une date récente seule ne suffit pas. Ne pas réinitialiser ni écraser le travail de Claude.

Les responsabilités et autorisations sont définies dans DECISIONS. Dans le périmètre déjà approuvé, Claude continue sans redemander une permission par bloc. Nouvelle décision uniquement pour un vrai conflit de scope/design ou une permission manquante. Codex audite le HEAD réel et ses preuves, tient la revue et les sources actives ; pas de travail gameplay parallèle implicite. Une revue ne remplace pas une autorisation produit et ne commande pas une réécriture du moteur.

## Propriétaire unique de chaque information

| Information | Destination unique |
|---|---|
| Intention durable / finalité | VISION |
| Arbitrage autorisé, portée, provenance et remplacement d’une décision | DECISIONS |
| Fait présent, version/commit, preuve et limite | CURRENT_STATE |
| Travail et critères de clôture, IDs, priorités et dépendances | MASTER_BACKLOG |
| Changements depuis le checkpoint, transfert de session | SINCE_LAST_CLAUDE |
| Méthode, maintenance documentaire, outils et validation | EXECUTION_RULES |
| Diagnostic technique présent et trois priorités | ENGINEERING_REVIEW |

Référencer le propriétaire au lieu de recopier ses paragraphes. START/README sont des index. Guides techniques et données générées ne définissent ni état global ni priorité. Les archives sont des références historiques non exécutables ; leurs exigences encore valables doivent être exprimées dans le backlog avant rangement. Lire seulement les sections utiles au travail courant.

## Validation et clôture

Pour chaque changement player-facing : tests pertinents → build exact → ouvrir/jouer dans Studio → déclencher par vraie sélection et vrais inputs quand possible → observer en mouvement → corriger → reconstruire/rejouer l’artefact final. Une sonde/debug aide à isoler ; ni elle ni une image figée ne remplace le parcours joueur continu. Pour le roster, les critères sont dans CHR-EXT-002 ; pour le flow Roblox publié, NET-001/REL-001.

Consigner **TECHNICAL**, **NATIVE_STUDIO**, **HUMAN_VISUAL/FEEL**, et **LIVE_ROBLOX** quand applicable : PASS/PENDING/FAIL/NOT_APPLICABLE justifié, date, commit, hash du build, scénario/inputs, outil, résultat et limite. Anciennes preuves datées non transférables au HEAD par défaut. Si seules les données/tests existent : `IMPLEMENTED / NOT YET STUDIO-VALIDATED`. Une clôture technique existante reste bornée au contrat du ticket et n’autorise aucune annonce player-facing complète ; citer le ticket de validation restant ouvert.

Backlog : OPEN/PARTIAL/IN_PROGRESS/DONE/BLOCKED/DEFERRED/REJECTED. DONE clôt son critère exact, avec preuve ; IMPROVED est un outcome de DONE, jamais une preuve esthétique. BLOCKED indique cause et condition de sortie, DEFERRED son déclencheur, REJECTED sa raison. Reproduire une ancienne régression sur la base actuelle avant réouverture. Aucun test affaibli pour obtenir PASS.

## Cycle documentaire continu

1. Capturer la demande produit datée et sa provenance (commit/source ; copie intégrale si nécessaire dans archive/requests). Ne pas inventer une approbation.
2. Chercher une intention équivalente parmi tous les IDs, y compris DONE/DEFERRED/REJECTED. Enrichir l’existant ; scinder avec lien parent seulement si nécessaire. Ne pas dupliquer un ticket pour une nouvelle formulation.
3. Mettre la décision durable dans DECISIONS, le travail dans MASTER_BACKLOG ; modifier CURRENT_STATE uniquement sur fait prouvé. Mettre à jour les exigences ouvertes issues d’une archive avant son déplacement.
4. SINCE_LAST_CLAUDE est une **boîte de réception temporaire**, pas un second journal/backlog. ChatGPT/Codex y ajoute une ligne stable (date, ID, liens vers décision/ticket propriétaire, portée, urgence, accusé PENDING). Claude la vérifie **avant chaque nouveau gros bloc** ; le bloc en cours continue sauf blocker explicite. À prise en compte, Claude note ACK + commit/checkpoint, absorbe toute information encore non classée dans son propriétaire, puis retire les entrées ACK à la prochaine rotation (historique Git/archives). Ne jamais écraser les entrées PENDING concurrentes. Une nouvelle idée non arbitrée reste candidate, pas décision ni changement de plan implicite.
5. Après audit Codex : **remplacer** ENGINEERING_REVIEW, ses six rubriques uniquement. Distinguer blocage de gate, bug reproduit, risque de lecture et simple absence de preuve. Référencer IDs/état sans réécrire le backlog. Ne pas retirer une alerte sur la seule promesse d’une correction.
6. Avant livraison : vérifier HEAD distant à nouveau. Si Claude a avancé, comparer ses changements et réappliquer uniquement les deltas documentaires pertinents ; ne jamais forcer le push, ne jamais écraser son journal. Exécuter contrôle docs/liens, frontières et checks des consommateurs concernés. Aucun rangement non prouvé ni suppression de contenu utile.

## Architecture et ajouts de personnages

Serveur autoritaire et validation des données/inputs ; client présentation/inputs. Frontières jeu/plugins/shared/Lab dans DEC-002/003. Préserver moteurs, sécurité, coûts et contrats pendant un audit documentaire. Pas d’intégration automatique de modèles/exports/recherches. Audit de licence/sécurité isolé avant d’exécuter un modèle externe ; aucun secret ni dépendance douteuse.

Le backlog définit les gates des fighters. La grille de conception couvre : identité/stade sourcé, mouvement, neutral, sol/air/mur, armes/outils, jutsu, garde/parade, dodge/substitution, poursuite/relance, chakra/infusion, éveil, réactions, gameplay loops, maîtrise et signature. Justifier les omissions selon l’archétype. Réutiliser familles/hooks pour un besoin démontré ; les fiches historiques sont des candidats, pas des obligations d’implémenter tout leur contenu. Le framework technique historique et le code servent à localiser les points d’entrée, pas à fixer la stratégie produit.

## Outils et disponibilité

Depuis la racine ; Python 3, Luau/Lune à vérifier dans chaque environnement. `tests/run.sh` cherche LUAU/LUNE, NINJA_DUEL_TOOLS puis PATH. SKIPPED n’est pas PASS. Ne figer aucun nombre de suites dans un guide : lire les sorties/manifests du build courant.

```sh
bash games/ninja-duel/tests/run.sh
python3 games/ninja-duel/build.py
python3 games/ninja-duel/build.py --debug
python3 games/ninja-duel/build.py --qa
python3 -m unittest discover -s games/ninja-duel/tests -p test_build_isolation.py
python3 tools/check_architecture.py
python3 games/ninja-duel/tools/check_project_docs.py
python3 games/ninja-duel/tools/check_project_docs.py --self-test
python3 games/ninja-duel/motion-lab/build.py
```

Le normal exclut DevHooks/CombatInspector/CombatDebug/NativeQA. F8 diagnostic lecture seule et F6 outils de mise en situation appartiennent aux builds Debug/QA. Commandes détaillées : [DEVTOOLS](../tools/DEVTOOLS.md), [Studio MCP](../../tools/studio/README.md), [Lab](../../motion-lab/README.md), [formats de progression](../systems/PROGRESSION.md). Générateur `tools/combat_inventory.luau` conserve `docs/current` pour ses sorties ; snapshots à dater, pas état du produit. [Anciens contrats](../current/COMBAT_CONTRACTS.md) et mappings sont des aides de lecture à confronter au code.

Windows : `core.longpaths=true`, `core.autocrlf=false`, variables NINJA_DUEL_TOOLS/LUAU/LUNE/LUAU_COMPILE vers les exécutables ; `python` si nécessaire. Studio MCP requiert le réglage et l’accès authentifié de la session. Présence d’un binaire/UI ≠ disponibilité prouvée. Publication : utiliser les permissions réelles et les gates REL-001 ; ne pas inventer PlaceID, accès API ni besoin d’action utilisateur à partir d’un vieux guide.
