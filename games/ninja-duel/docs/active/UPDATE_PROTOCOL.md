# Capture continue

Une nouvelle demande ne devient pas « la dernière mission qui écrase tout ». Conserver son texte détaillé dans une source datée et ajouter/relier un ID stable au backlog.

## Cas explicite : User says: "Claude should do X later"

1. Chercher d’abord dans le backlog (tous statuts) et les specs si une exigence de même intention existe déjà.
2. Ajouter l’idée détaillée et sa provenance dans la bonne spec/source, sans perdre les nuances.
3. Créer ou mettre à jour un ID dans MASTER_BACKLOG. Si équivalent existant : enrichir cet ID et ajouter la nouvelle source ; éventuellement scinder en sous-ID lié au parent si trop large. Ne jamais dupliquer une intention parce qu’elle a été formulée à deux moments différents.
4. Modifier DECISIONS uniquement si cela change une décision durable ; ne pas transformer une idée future en décision approuvée.
5. Modifier CURRENT_STATE uniquement si l’état réel du jeu change ; une envie future ne constitue pas une feature implémentée.
6. Ajouter la nouveauté dans SINCE_LAST_CLAUDE si Claude ne l’a pas encore vue ; toute capacité/outillage nouveau est aussi référencé dans CAPABILITIES_AND_TOOLS.
7. Ne pas créer de mission isolée, sauf nécessité exceptionnelle explicitement justifiée ; même alors la relier aux IDs et à la hiérarchie active.

| Information nouvelle | Destination |
|---|---|
| Intention durable / décision autorisée | VISION / DECISIONS, provenance et raison |
| Travail futur | MASTER_BACKLOG, ID stable, status, priority, dependencies, subsystem, character, sources, validation |
| Fait actuel | CURRENT_STATE avec code/test/Studio et limite |
| Capacité ou outil réel | CAPABILITIES_AND_TOOLS + documentation tools |
| Source ou recherche | research, provenance exacte, statut de revue, éléments observés vs idées |
| Comportement personnage | characters + backlog ; label lore |
| Règle de combat/mouvement/système | combat/movement/systems + backlog ; implémenté vs cible |
| Bloc exécuté / changement en absence de Claude | SINCE_LAST_CLAUDE + reports avec artefact exact |

Ne pas réutiliser un ID supprimé. Scinder un ticket trop large en sous-IDs liés en conservant le parent. Garder les critères détaillés dans les specs/sources ; l’entrée synthétique ne les remplace pas. DONE doit citer une preuve du critère exact. IMPROVED clôt DONE avec résultat et explication ; les besoins non satisfaits restent PARTIAL ou un nouvel ID dépendant. DEFERRED et REJECTED gardent source et raison, sans effacer la demande.

Une recherche candidate est à évaluer, pas approuvée. Un conflit avec une décision active se note explicitement et nécessite une décision si le plan approuvé ne le couvre pas. Mettre à jour le registre de couverture si une source change de place ou de nouveaux IDs reprennent ses exigences. Exécuter le validateur documentaire avant commit.
