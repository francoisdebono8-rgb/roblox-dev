# Demande utilisateur intégrale — 17 octobre 2026

Tu travailles sur Ninja Duel pendant que Claude continue d’implémenter le jeu.

IMPORTANT : tu n’es PAS l’implémenteur principal du projet. Claude l’est.

Le fonctionnement réel du projet est le suivant :
Utilisateur ↔ ChatGPT pour la vision, les idées, les priorités et les décisions produit.
ChatGPT formalise ces décisions dans le repo.
Claude implémente le jeu.
Studio sert de vérité pour tout ce qui est player-facing.
Codex sert de reviewer technique, architecte, nettoyeur du repo et garant de la mémoire du projet.

Le problème actuel :
La vision évolue souvent pendant que Claude travaille. De nouvelles idées, décisions ou corrections sont ajoutées en continu. Jusqu’ici, cela a créé trop de missions, handoffs, rapports et fichiers séparés. Le risque est que Claude perde la hiérarchie des priorités, lise des informations obsolètes ou ne comprenne pas la vision aussi bien que l’utilisateur + ChatGPT.

Ta mission est donc de construire un vrai "cerveau actif" du projet, simple, fiable et maintenable.

OBJECTIF PRINCIPAL
À n’importe quel moment, Claude doit pouvoir comprendre la vision actuelle du jeu, l’état réel du projet, les décisions récentes et ce qu’il doit faire ensuite sans devoir parcourir des dizaines d’anciennes missions.

PRINCIPE CENTRAL
Une nouvelle idée importante ne doit plus automatiquement créer une nouvelle mission indépendante.
Elle doit être absorbée dans la bonne source de vérité active.

RÔLES DES SOURCES DE VÉRITÉ

`docs/active/VISION.md`
= pourquoi le jeu doit être comme ça.
Identité du jeu, expérience recherchée, principes de game feel, philosophie combat, rôle des personnages, ambitions long terme.
Ce fichier doit rester relativement stable et compréhensible.

`docs/active/DECISIONS.md`
= décisions produit/techniques durablement actées par l’utilisateur.
Exemples actuels :
- cible initiale de 20 personnages jouables ;
- développement breadth-first du roster avant polish profond ;
- Studio obligatoire pour valider toute fonctionnalité player-facing ;
- online = vrai produit Roblox publié, pas seulement 2 clients locaux ;
- objectif d’alpha publique tôt dès que roster + combat online sont suffisamment jouables ;
- Claude reste implémenteur principal ;
- Codex reste reviewer/architecte ;
- ne pas multiplier les contrôles/boutons inutilement ;
- combos accessibles à l’exécution mais profonds dans les décisions ;
- identité de chaque personnage doit être visible dans le combat.

`docs/active/CURRENT_STATE.md`
= ce qui existe réellement AU HEAD actuel.
Pas ce qui était prévu.
Pas ce qu’un ancien rapport prétend.
Ce qui est réellement implémenté et validé.

`docs/active/MASTER_BACKLOG.md`
= ce qu’il reste à faire.
Doit être unique, priorisé et non dupliqué ailleurs.

`docs/active/SINCE_LAST_CLAUDE.md`
= nouvelles décisions, changements ou ajouts arrivés pendant que Claude travaillait.
C’est la boîte de réception temporaire.
Quand Claude les intègre, elles doivent être absorbées dans VISION/DECISIONS/BACKLOG/CURRENT_STATE selon le cas.

`docs/active/ENGINEERING_REVIEW.md`
= dernier audit Codex du HEAD.
Court, remplacé à chaque audit.
Sections uniquement :
- BLOCKERS
- REGRESSIONS
- ARCHITECTURE RISKS
- PLAYER-FACING FAILURES
- NEXT 3 PRIORITIES
- DO NOT TOUCH

`docs/active/EXECUTION_RULES.md`
= règles de fonctionnement Claude/Codex/Studio/repo.

TA MISSION MAINTENANT

1. Audite toute la documentation Ninja Duel existante.

2. Identifie :
- anciennes missions déjà exécutées ;
- handoffs obsolètes ;
- rapports historiques ;
- doublons ;
- contradictions ;
- informations importantes encore perdues dans de vieux fichiers ;
- fichiers qui donnent encore l’impression d’être actifs alors qu’ils ne le sont plus.

3. Ne supprime pas brutalement l’historique.
Archive ce qui reste utile sous `docs/archive/`.

4. Consolide toutes les informations encore valides dans les sources actives ci-dessus.

5. Une information opérationnelle ne doit avoir qu’une seule source active de vérité.

6. Les dossiers détaillés comme `characters/`, `combat/`, `movement/`, `systems/`, `research/` peuvent rester comme documentation spécialisée, mais ils ne doivent pas déterminer eux-mêmes les priorités globales.

7. Mets à jour `CLAUDE_START_HERE.md`.
Claude doit :
- commencer par lire les sources actives ;
- lire ensuite le dernier `ENGINEERING_REVIEW.md` ;
- vérifier `SINCE_LAST_CLAUDE.md` avant chaque nouveau gros bloc ;
- considérer les archives uniquement comme références historiques ;
- ne jamais traiter "le dernier fichier ajouté" comme la mission globale du projet.

8. Mets en place la boucle de travail suivante dans les règles :
Utilisateur ↔ ChatGPT
→ ChatGPT met à jour les décisions du repo
→ Claude implémente
→ Studio valide
→ Codex audite le HEAD réel
→ Codex remplace ENGINEERING_REVIEW
→ Claude corrige/continue

9. Codex ne doit pas concurrencer Claude sur le gameplay.
Tu peux auditer le runtime et l’architecture, mais évite les gros changements gameplay dans cette mission.

10. Vérifie que les nouvelles décisions récentes sont bien intégrées dans les sources actives, en particulier :
- roster cible 20 ;
- breadth-first ;
- Studio obligatoire ;
- alpha publique tôt ;
- vrai online Roblox ;
- Claude builder / Codex reviewer ;
- réduction du nombre de missions isolées ;
- volonté d’éviter que Claude perde la vision globale quand de nouvelles idées arrivent pendant son travail.

11. Rends le système compatible avec un flux très fréquent de nouvelles idées venant de ChatGPT.
L’objectif est que ChatGPT puisse mettre à jour la mémoire centrale sans casser le plan de Claude.

12. Vérifie les liens internes après tout déplacement/archivage.

13. Travaille à partir du HEAD autoritaire actuel, pas d’une ancienne branche Codex.

LIVRABLE FINAL
À la fin, donne un rapport très court :
- fichiers actifs finaux ;
- fichiers archivés/déplacés ;
- contradictions supprimées ;
- informations importantes consolidées ;
- éventuels points encore ambigus ;
- comment Claude récupère les nouvelles décisions sans perdre le contexte.