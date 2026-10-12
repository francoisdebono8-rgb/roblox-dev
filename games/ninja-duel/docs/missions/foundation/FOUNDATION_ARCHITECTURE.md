# FOUNDATION — architecture recommandée, à valider

10 octobre 2026. Recherche seulement. Fondement des choix : [carte A–K et sources inspectées](TECHNICAL_REFERENCE_MAP.md). Cette proposition autorise le remplacement du runtime Phase 6B ; elle ne le réalise pas.

## Choix concret

**Premier choix : R15 standard + ControllerManager/GroundController/AirController + Server Authority natif + Input Action System + Animation Graphs de base.** Les graphes de base sont utilisables en live depuis [le 15 juillet 2026](https://devforum.roblox.com/t/full-release-animation-graphs-create-complex-character-motion-visually/4739840). Les nouveaux nœuds State Machine/Expressions sont [Studio-only au 8 octobre](https://devforum.roblox.com/t/studio-beta-introducing-state-machines-and-luau-expressions-for-animation-graphs/4921939) : le socle utilise Select/Blend/Sequence avec un état gameplay explicite, sans dépendre de cette bêta.

CCL fournit une base de locomotion pertinente, mais son **Custom Abilities API est encore une Studio Beta** avec changements le 8 octobre. Recommandation de production : primitives ControllerManager stables ; qualification CCL en première étape, puis choix exclusif si les extensions et remappings requis fonctionnent réellement en place publiée. Pas de pari silencieux sur `@rbx/AvatarAbilities` ni de deuxième moteur autour de CCL. [Annonce/API et statut](https://devforum.roblox.com/t/studio-beta-expanding-the-character-controller-library-new-default-abilities-custom-abilities-api/4863739/1).

**Fallback réseau/mouvement : Chickynoid MIT**, seulement si le prototype natif échoue au gate de rollback/contact/deux joueurs. Son replay réel a été inspecté, mais son collision box/Humanoid remplacé accroît le travail R15, grab et ragdoll. Ne pas cumuler ses remotes, son simulateur et la prédiction native. Une défaillance de CCL beta ne justifie pas à elle seule de quitter ControllerManager stable.

Le choix final d'API exige un micro-prototype après approbation FOUNDATION 02. Aujourd'hui : preuves de code/documentation, aucune qualification native de cette nouvelle pile.

## Un propriétaire par responsabilité

| Responsabilité | Propriétaire proposé | Interdiction |
| --- | --- | --- |
| Commandes humaines | InputContexts/InputActions IAS, map sémantique unique | Aucun listener donor UIS/CAS de combat concurrent |
| État action/ressources/fenêtres | Ninja Duel ActionRules, exécuté dans la simulation fixe | WCS et CCL ne peuvent posséder simultanément cet état |
| Position/vitesse/orientation | Une MovementPolicy par acteur qui configure le contrôleur natif et les impulsions | Aucun autre module ne fait PivotTo/CFrame pour un dash ou une réaction |
| Contacts et défense | ContactResolver serveur, queries natives/solvers adaptés | Aucun client ne décide de dégâts, grab ou wallsplat |
| Trajectoire de victime | ReactionPolicy, appliquée par le même propriétaire de mouvement | Ni tâche de stun ni BodyVelocity indépendant pilotant la root |
| Animation | Un Animator/graph driver avec paramètres dérivés des états | Aucun Animate par défaut supplémentaire, pose Motor6D concurrente ou marker propriétaire des dégâts |
| Caméra | ArenaCamera client, composition puis collision puis shake | Default Camera/CameraService/Shaker ne réécrivent pas chacun Camera.CFrame |
| Jutsu futur | Definitions/extension handlers derrière ActionRules | Pas de moteur propre à chaque combattant |
| AI future | Observations → choix → même SemanticIntent | Pas de c.request qui contourne coûts/conditions, ni vérité cachée exposée à l'AI |
| Match/lifecycle | MatchService serveur, epoch/rematch/reset | Aucun donor ne respawn ou change Gravity globalement |

Ces noms désignent des responsabilités concrètes dans **ce jeu**, pas un framework générique à publier ou à déplacer dans shared/.

## Flux d'une commande et d'un contact

1. Stick/bouton → `Move`, `Look`, `Sprint`, `JumpContext`, `Light`, `Heavy`, `Dodge`, `Guard`, `Grab`, `Tool`, `Technique(slot)`, `CancelPrepare`, `Lock`. IAS transporte les inputs de gameplay ; caméra locale consulte Look, orientation gameplay bornée/validée. Ne pas employer l'ancien CameraAction supprimé ; le cas échéant utiliser [Player:GetCameraState](https://devforum.roblox.com/t/full-release-ship-fair-and-competitive-games-with-server-authority/4727993), en traitant la caméra déclarée comme input, pas preuve de hit.
2. ActionRules lit état actuel, fronts de bouton/buffer, ressources, grounded, collision, cible et conditions. Il accepte une transition et attribue `ActionId`, `ActionEpoch`, `StartTime`, phases et définition immuable. Le client prédit son action ; le serveur reste la vérité.
3. MovementPolicy combine vitesse existante, intention, engagement de l'action et collision. Exemple launcher : l'attaquant garde l'avance autorisée ; la victime reçoit une nouvelle vitesse seulement après contact confirmé. Un état n'efface jamais implicitement l'élan. Aux changements de contrôleur, la vitesse est transférée explicitement.
4. Animation driver reçoit vitesse locale, grounded, direction, action, temps de phase, état/réaction. Les courbes de déplacement et volumes viennent du même manifeste d'action que le clip ; le déplacement est physique, pas extraction tardive de pose décorative.
5. Pendant la fenêtre active, ContactResolver fait overlap initial + sweep entre volumes précédents/actuels, déduplication par cible/action, LOS/occlusion et défense. Grab utilise portée, angle et disponibilité vérifiés, pas la hitbox de punch élargie. Une rotation rapide impose subdivisions bornées ; Blockcast linéaire ne balaie pas à lui seul un arc rotatif complet.
6. Le serveur résout hit/guard/evade/trade puis modifie ressources, trajectoire et état. Le défenseur reçu en l'air n'est pas `Stunned=true` sans trajectoire : vitesse, gravité, budget juggle, fenêtre evasive, landing et wakeup sont définis.
7. Presentation lit le résultat avec un identifiant stable ; audio/VFX/shake sont dédupliqués et corrigibles. Caméra suit les positions/états observables, jamais une cible fantôme révélant l'illusion. Dégâts/UI confirmés ne se basent pas sur le preview client.

### Simulation et sécurité

[Server Authority](https://create.roblox.com/docs/projects/server-authority) impose IAS, simulation fixe, replication adaptée et streaming. La qualification vérifie que seules les API portant Simulation Access sont appelées dans BindToSimulation. Employer `time()`/temps de simulation pour les règles, pas task.wait, os.clock, TweenService ou des timers de framework. Une table Luau mutable n'est pas automatiquement restaurée : phases, ressources, fronts et budgets résident dans un état reconnu par rollback (attributs d'instances prédites ou State CCL si retenu). Les définitions et références immuables peuvent rester en tables. Budget explicite d'attributs ; aucun dictionnaire arbitraire de statuts dans une string non bornée.

Le client prédit ses coûts/règles/mouvement/animation et un preview de contact. Le serveur tranche les interactions entre joueurs, donc une garde tardive peut corriger un hit apparent. Ne pas simuler de dégâts définitifs sur une victime distante pour préserver une illusion de zéro latence. Valider inputs finis, normes, fronts, débit, temps, epoch, capacités autorisées, conditions LOS/marque et limites de déplacement. Les remotes hors simulation servent aux sessions/résultats et restent validés/rate-limités ; l'ordre entre remotes et attributs n'est pas présumé.

La prédiction native n'est **pas** une politique automatique de rewind melee. Premier gate : contacts à temps simulé serveur synchronisé, sans accepter de timestamp historique client libre. Comparer ensuite les taux de whiff/correction aux latences de la matrice. Si insuffisant, qualification séparée d'une fenêtre de rewind bornée avec historiques de hurt volumes, états défensifs et obstacles ; pas simplement root ancienne contre mur actuel. Secure-Cast sert de source MIT pour cette discipline, pas de serveur de projectiles concurrent importé aveuglément.

### Mouvement et réaction

GroundController fournit rampe/friction ; AirController fournit conservation/force de steering. Ninja Duel fournit les règles de wall tangent/contact, sortie, budgets et profils d'attaque. Wallrun, pursuit et grab désactivent/remplacent le contrôleur actif uniquement pendant leurs fenêtres autorisées ; aucun Humanoid motor ne pousse simultanément. Qualifier la désactivation du moteur hérité avec [Humanoid.EvaluateStateMachine](https://create.roblox.com/docs/reference/engine/classes/Humanoid#EvaluateStateMachine), et fournir nos propres capteurs/états ; ne pas continuer à consulter FloorMaterial/états hérités comme vérité si leur moteur est désactivé.

Light/guard/air hit : animation de réaction + impulsion physique contrôlée. Heavy/launcher : trajectoire bornée avec collisions. Slam/throw : knockdown dirigé, puis reprise du contrôleur et wakeup. Ragdoll sélectif optionnel aux impacts forts ; pas requis pour rendre le noyau jouable. Le candidat MIT RagdollService sait traiter les AnimationConstraints R15 modernes, mais son lifecycle/remotes ne sont pas prouvés rollback-safe : adapter seulement le builder/config, créer les constraints hors simulation, activer un état simulable qualifié. Ne pas changer ownership pour suivre l'ancien module ; ne pas appeler Destroy pendant une resimulation.

## Animation : livrable préalable au combat validable

Rig R15 standard, proportions fixes initiales ; documenter Motor6D versus AnimationConstraint du modèle réellement utilisé. Un rig fait de quinze blocs n'est pas à lui seul une chaîne d'animation fiable. Pas de retarget R6 automatique vendu comme couverture R15 : segments, appuis, arcs et contact doivent être réauthorés/vérifiés.

| Couverture exigée pour le noyau physique | Minimum de clips/familles à livrer et tester |
| --- | --- |
| Sol | Idle garde libre ; locomotion avant/arrière/gauche/droite avec blend ; sprint ; start/stop ; pivots gauche/droite |
| Air | Takeoff ; rise/fall ; land légère ; land forte ; air steering lisible |
| Murs | Entry gauche/droite ; run gauche/droite ; exit ; walljump ; réception |
| Dash | Avant/arrière/gauche/droite sol ; air dash ; sortie vers course/garde |
| Melee attaquant | Light1, light2, horizontal finisher, heavy, launcher, pursuit, airlight1, airlight2, downslam |
| Melee victime | Hit avant/arrière/gauche/droite ; guard recoil ; launch ; air hit ; chute/slam ; wallsplat/rebond |
| Grab | Grab attaquant/victime synchronisés, throw avant/haut et victime correspondante ; grab whiff |
| Défense/réveil | Guard entrée/loop/sortie ; evasive/substitution sortie ; knockdown ; wakeup, directions de sortie |
| Après le noyau | Tool throw ; prepare/cancel/commit/recovery ; mark travel/Read/deception, propres à la slice future |

Une famille peut utiliser des blends/mirroring testés ; elle ne peut être un alias silencieux vers Idle ou Punch. Inventaire par rôle avec fichier source, auteur/licence, joints/proportions, durée, priorités, marqueurs, phases, courbe de root travel, hurt/hit volumes, ID publié, propriétaire, date et résultat runtime.

Workflow gratuit : Animation Editor Roblox ; source originale pour les lacunes ; les deux packs Cinderlore gratuits sont des **bases possibles**, pas une couverture complète. Inspection réelle : 7 clips combat et 6 movement, R15, aucune source script détectée. Licence autorise édition/publication par notre propriétaire mais interdit redistribution publique ; repository actuellement PRIVATE, conserver un espace restreint et exclure ces fichiers d'un futur template/publication du code. Les 13 clips nécessitent QA visuelle : ils ne couvrent pas launcher/air combo/throw/slam. Voir preuves/hashes dans la carte.

Publier clips **et graphes**, avec droits de chaque clip, sous le compte/groupe de l'expérience finale ; tester client/serveur/deux clients et place privée publiée. `PreviewInStudio` ne prouve pas les droits en live et n'est pas supporté en Server Authority selon la [documentation du graphe](https://create.roblox.com/docs/animation/graph-editor#replication). Source/IDs gratuits ne dispensent pas des permissions. Les quatre animations Bangla renvoyant 403/modération ne sont pas le fallback de cette pipeline.

Priorités : base locomotion, overlays de garde/attaque uniquement là où l'appui le permet, réaction entière prioritaire. Transitions en fonction de vitesse/phase ; durée d'anticipation/contact/recovery figée par manifeste et test d'alignement. Les markers sont utiles à la présentation, jamais une autorisation client de frapper. [Techniques natives](https://create.roblox.com/docs/projects/server-authority/techniques) : retrouver une track vivante après rollback ; pas de cache permanent de handles devenus invalides. Utiliser la génération officielle RunClient/RunServer comme référence et qualifier SetParameter/synchronisation sur la version installée.

## Donors, boundaries et code survivant

| Phase 6B / externe | Décision et limite exacte |
| --- | --- |
| Controls/Input | KEEP CURRENT **vocabulaire et couverture**, ADAPT transport IAS/contexts ; réviser Jump/Pursuit/Modifier ambiguës dans la matrice |
| Match/reset/epoch, validation finitude/débit, QA | KEEP CURRENT politiques/tests pertinents ; recâbler au nouveau runtime, aucune déclaration native PASS héritée |
| BanglaCombo/Combat | REFERENCE ONLY de progression/engagement ; remplacer attaque/contact/action state par le manifeste physique R15 |
| BanglaEvade | REJECT runtime : moving-origin CFrame Lerp + velocity zéro ; remplacer par dash simulé avec sortie d'élan |
| Place1Movement/Parkour/Motor | REFERENCE ONLY pour takeoff/air steering et clearance ; remplacer boucle serveur, WalkSpeed instantané et CFrame traversal ; pas de branche legacy active |
| DonorAnimations/AnimationBindings/Animation | Remplacer playback/retarget et catalogue incomplet ; conserver notices légales et inventaires de provenance, pas leurs IDs interdits |
| Combat/Brawler/reactions/AI/Techniques | Remplacer état physique et conditionnels de personnage ; réutiliser seulement contrat sémantique/lifecycle vérifié ; AI actuelle désactivée dans F02 |
| Camera | ADAPT besoins two-body/obstruction ; réécrire le propriétaire si nécessaire, sans protéger son implementation |
| ShapecastHitbox MIT | ADAPT solvers géométriques après correctif/qualification ; exclure PostSimulation/os.clock/task.defer et la gestion d'entités de la bibliothèque |
| RbxCameraShaker MIT | IMPORT calcul d'offset/fade, piloté par ArenaCamera ; désactiver son writer/bind autonome concurrent |
| RagdollService MIT | ADAPT builder/config seulement, optionnel après trajectoires contrôlées |
| WCS MIT | REFERENCE ONLY / différé : lifecycle/resource/jutsu utiles, pas garantie rollback ; pas de deuxième propriétaire melee/status |
| BehaviorTree MIT | IMPORT éventuel plus tard pour orchestration AI hors simulation ; aucune AI construite en F02 |

## Capacités, AI et extension

Actions = données et hooks étroits : `CanStart`, `OnCommit`, `ResolveContact`, `OnInterrupt`, `OnRecovery`, `PerceptionEffect`. Tous passent par ActionRules et la validation serveur. Un profil de fighter sélectionne des variantes/paramètres et capacités ; un handler de marque écoute `MarkContact`, pas `if Minato`. Une protection liée à zone ou chakra utilise la même interface de condition. Les hooks ne peuvent écrire root/health hors propriétaire.

La vérité et `ObservedActor` sont séparées. ObservationView applique masque/retard/LOS/illusion pour humain et AI ; DifficultyPolicy borne réaction et erreurs. DecisionPolicy émet exactement les mêmes intents qu'IAS, via un adaptateur serveur, puis les mêmes validations. RNG décisionnel serveur distinct de la simulation prédite ; décision retenue/reproduite comme état/input pour éviter une nouvelle décision lors d'un replay. Aucun tree ne doit devenir un moteur de physique.

Pour vingt combattants, budgets de capacités/entités, catalogue d'actions versionné et validation des combinaisons ; pour Create-a-Ninja, assembler des définitions whitelisted plutôt que des classes nommées. Pour examens/tournois, MatchService orchestre des matchs à deux indépendants ; les graphes/handlers ne changent pas avec la taille du lobby.

## Inconnues qui bloquent une affirmation de qualité

Compatibilité native publiée de chaque API, prédiction de contacts/impulsions inter-acteurs, coût et corrections sur client modeste, remapping IAS/CCL, synchronisation graphique, disponibilité de clips manquants et vraie réception manette restent à prouver. Aucun module étudié n'offre gratuitement et sous licence claire toute cette grammaire R15 avec ces garanties. Les règles de combat spécifiques sont donc nécessaires ; réinventer réseau, contrôleur physique, graphe ou framework d'abilities ne l'est pas.

**FOUNDATION 02 NOT EXECUTED**
