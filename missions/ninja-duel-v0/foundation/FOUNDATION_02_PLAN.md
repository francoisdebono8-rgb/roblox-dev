# FOUNDATION 02 — mission d'implémentation proposée, non exécutée

10 octobre 2026. **Statut : en attente de validation du socle FOUNDATION 01 par François/ChatGPT.** Ce fichier n'autorise pas son exécution. Lire la [bible](GAMEPLAY_BIBLE_DRAFT.md), la [carte de recherche](TECHNICAL_REFERENCE_MAP.md), l'[architecture](FOUNDATION_ARCHITECTURE.md) et la [matrice humaine](HUMAN_ACCEPTANCE_MATRIX.md) avant tout code.

## Résultat à produire après approbation

Une place graybox à deux combattants R15 identiques dans leurs règles, pilotables par deux humains, plus une fixture passive configurable. Une petite arène avec sol, long mur de traversal, mur d'impact, coin et plateforme. Le noyau mouvement + combat physique doit donner envie de rejouer pendant **dix minutes sans jutsu de personnage**. Les templates/fixtures servent à tester les branches, pas à fabriquer une démonstration scriptée à la place du jeu.

Noyau : accélération/brake/pivot, jump/air steer/landing, wallrun/jump/dash ; deux lights puis choix horizontal/launcher, heavy, pursuit, deux air hits modifiant trajectoire, slam/knockdown/wakeup, guard/dodge/evasive limité, grab forward/upthrow, projectile universel simple pour fermer distance. Caméra deux corps, manette, animations originales/accessibles, serveur autoritaire et réponse locale prédite. Pas de kits Minato/Itachi, genjutsu, catalogue vingt fighters, AI active, boutique, progression ou tournoi.

Deux mannequins de mêmes capacités suffisent pour isoler la qualité physique. Différenciation de personnage et scénarios 14–17 seront autorisés plus tard ; FOUNDATION 02 doit conserver leurs seams, pas prétendre les avoir validés.

## Ordre avec gates, sans chemins concurrents

### 0 — Qualifier la plateforme et figer un moteur

Micro-place indépendante, sous le propriétaire cible : R15 réel, ControllerManager Ground/Air, AuthorityMode Server, IAS, graphiques stables. Consigner Studio/Player version, joints AJU/legacy, APIs Simulation Access, settings de replication/streaming, map de contrôles et coûts mesurés. Deux clients Studio puis place privée publiée, latency/loss simulation. Vérifier collision/saut, impulse entre deux corps, état restauré après correction, replay d'une ressource et animation active.

Tester CCL et son Custom Abilities API séparément si réellement disponible en live ; vérifier surtout action slots/remapping requis et callbacks synchrones/state. L'extension beta ne doit pas bloquer le jeu : conserver **ControllerManager stable sans custom CCL** si elle échoue. Ne pas importer simultanément CCL/WCS/ancien Movement.

Si le natif échoue malgré correction localisée à un problème reproductible essentiel, comparer le fallback Chickynoid MIT sur **les mêmes** critères, avec adaptateur R15. Fixer un seul moteur dans la décision écrite ; aucun double netcode. Si aucun ne passe, documenter le blocker et arrêter la promesse de qualité, sans compenser par des CFrames ou une autorité client. Les inconnues d'API ne sont pas autorisées à devenir des réécritures génériques.

**Sortie G0 :** choix exclusif + preuve native/publiée, animation/impulse/replay/réseau/manette qualifiés. Aucun grand combat avant ce choix.

### 1 — Animation accessible et locomotion, comme gate préalable

Créer un inventaire de couverture par rôle à partir du tableau de l'architecture. Pipeline gratuit R15 Animation Editor, proportions fixes, sources originales pour les manques. Cinderlore F1/F3 uniquement si adaptation visuelle utile : conserver licence/notice, sources restreintes et droits de republication ; ne pas introduire un pack public/template. Les assets Bangla 403/modérés ne sont pas le plan B.

Publier **clips et graphe sous l'owner final**, donner les droits nécessaires à chaque clip, vérifier sur les deux clients d'une place publiée. Graphe de base Blend/Select/Sequence/Mask ; pas dépendance aux State Machine/Expressions Studio-only. Phases de gameplay dans manifestes, markers pour présentation ; gérer tracks vivantes après rollback. Tester sous/joints/appuis, directions, transitions, playback rates et interruption réelle.

Implémenter mouvement physique et profil unique : sol, air, wall tangent/exit, dashes, collisions et inheritance. WalkSpeed instantané et ordinary dash CFrame interdits. Qualifier **01–04/19/20 partie mouvement** à la manette physique, avant un melee prétendument complet.

**Sortie G1 :** locomotion humainement validée, clips réellement joués dans la place, tableau des rôles combat en production planifiée avec auteurs/rights ; aucun rôle manquant remplacé silencieusement par Idle. Chaque étape combat suivante exige ses clips complets avant sa validation.

### 2 — Sol, contacts et défense

ActionRules/manifestes + une MovementPolicy par acteur. Lights, heavy, horizontal finisher, déplacement racine physique, buffer/cancel légal, garde, directional dodge, whiff/recovery. ContactResolver serveur : overlap initial + sweep, mur, dédup, ordre/trade déterministe. Adapter les petits solvers MIT ShapecastHitbox après test de persistance previousCFrame ; exclure leur horloge/lifecycle. Si leur adaptation ne réduit pas le code ou échoue, employer les queries natives dans ce resolver **spécifique**, sans créer une API générique de hitbox.

Clips anticipation/contact/reaction/recovery synchronisés, caméra sol, cues sobres. Démontrer guard→whiff punish avec deux humains. Coupler move/root travel aux volumes de gameplay, pas à une pose d'affichage arbitraire.

**Sortie G2 :** 05/09/11 avec animations/caméra/contre-jeu ; tests techniques contacts rapides et through-wall pertinents. Pas de nouvelle chaîne de damage/stun déclarée « grammaire ».

### 3 — Air, trajectoires, throws, sortie défensive

Launcher crée velocity/arc, pursuit se déplace vers interception bornée, air hits changent direction, slam descend jusqu'à collision sol. Budget juggle/air, recovery sans poursuite, knocks/wallsplat bornés et wakeup contrôlé. Grab court collision-safe, animations à deux corps et forward/upthrow ; cleanup sur interruption/death/reset.

Evasive/substitution universelle limitée, destination valide et recovery punissable ; projectile/tool neutre sweep + feedback + stock/cooldown. Pas de marks/jutsu pour rendre ces échanges intéressants.

RagdollService : au besoin adapter builder/config seulement pour knockdown fort, après trajectoires/animations dirigées. Constraints créées au setup, lifecycle de corps/recovery sous le propriétaire de mouvement. Si rollback et reprise ne passent pas, knockdown animé contrôlé remplit la règle sans chaos ; conserver ragdoll comme option non requise, sans supprimer les résultats physiques.

**Sortie G3 :** 06–10/12/13 et 18, deux humains, deux côtés, clips dédiés ; vérification anti-infini et branches de défense. Un launcher sans cameraframing ou vraie poursuite reste FAIL.

### 4 — PvP publié, corrections et dix minutes humaines

Réexécuter 01–13/18–20 sur artifact final, Studio puis place privée publiée, manette réelle, profils réseau documentés. Prédire propres entrées/actions/animations, confirmer contacts/impulsions/coûts serveur, dédupliquer présentation après replay. Aucun hit déclaré par le client. Examiner les taux de correction/whiff et framerate ; ne pas ajouter un rewind universel sans preuve que la stratégie native est insuffisante.

Si rewind nécessaire : ticket limité, comparaison Secure-Cast/snapshots à la géométrie/defense historiques, fenêtre bounded et anti-forgery ; le profil RTT observé et les vidéos doivent justifier le changement. Pas de nouvelle couche de remotes compétitive ajoutée par confort.

Faire deux séances à deux joueurs de dix minutes sans jutsu ni script qui chaîne les actions. Alterner rôles et styles : pression/air, distance/projectile, garde/esquive, environnement. Consigner les décisions réellement choisies, whiffs punis, poursuites abandonnées, reprises défensives et envie de rematch ; demander un verdict humain sur mouvement, physique et caméra. Une séquence exécutée une fois ne suffit pas si personne ne veut y jouer ensuite.

**Sortie G4 :** matrice documentée avec preuves et défauts résolus sur SHA exact, aucune clause ignorée ; dix minutes jugées intéressantes par les joueurs. Performance seuil initial : 60 fps sur poste cible courant, budget client modeste déclaré et mesuré ; ne pas présenter l'annonce de performance d'un donor comme nos mesures.

## Remplacement exact et imports proposés

| Élément | Boundary après autorisation |
| --- | --- |
| Old Boot/ServerHeartbeat/Input snapshot/Motor et ownership nil | Nouveau bootstrap/simulation IAS/native autoritaire ; supprimer branche concurrente active |
| Place1Movement/Parkour et BanglaEvade | Remplacer exécution mouvement/traversal ; garder originals/notices comme références, pas loops actifs |
| BanglaCombo/Combat + Brawler/Combat reaction state | Remplacer action/contact/reaction par grammaire spécifique ; retain seulement règles vérifiées utiles, aucune exemption au gate |
| Animation/DonorAnimations/Bindings/rig | Remplacer playback incomplet/retarget et IDs par R15 source/owner/graph ; archiver provenance |
| Controls + lifecycle/epoch/rate/finitude | Conserver contrat/politiques, adapter IAS et reset des états prédites, tests portés aux bonnes attentes |
| Camera | Une ArenaCamera ; réutilisation possible de math actuelle après gates, pas obligation de préserver fichier |
| ShapecastHitbox | Pin/notice MIT, solvers adaptés et testés ; aucun auto-lifecycle/temporel |
| RbxCameraShaker | Pin/notice MIT, offset/fade intégré au seul writer ; option shake réduite/off |
| RagdollService | Pin/notice MIT, builder R15 moderne/legacy optionnel qualifié, runtime restreint |
| WCS/BehaviorTree/Chickynoid | WCS et BT différés ; Chickynoid uniquement si décision G0 fallback exclusive |

Les prochaines modifications devront être isolées et reviewables ; les corrections QA Phase6B non committées et travaux Forge ne sont pas du scope de cette future mission. Ne pas écraser le catalogue/Creator Store ni publier un lancement commercial.

## Acceptation et handoff

Livrer sources/build reproductibles, manifestes/licences et IDs, instructions d'installation/test, gates natifs/publiés, vidéos deux vues, input traces, résultats manette/réseau et liste explicite des limites. Tests automatisés ciblés : phases/coûts/cancels/anti-infini, contact au mur/grab cleanup, validation entrées, resimulation sans double outcome. Ne pas fabriquer des tests qui vérifient seulement la présence de son propre code.

Scénarios 14–17 et AI avancée restent **NOT IMPLEMENTED / NOT TESTED**, prêts pour la slice ultérieure : interfaces ressources/prepare/cancel/conditions/perception documentées, aucune technique de personnage implémentée pour obtenir artificiellement leur PASS. À clôture, séparer clairement gate noyau et gate vision entière.

La décision demandée pour ouvrir F02 est le socle : natif d'abord avec qualification G0, pipeline R15 préalable, grammaire physique complète puis preuve humaine. On peut modifier cette proposition lors de la revue ; **aucune étape ci-dessus n'a été exécutée par FOUNDATION 01**.

**FOUNDATION 02 NOT EXECUTED**
