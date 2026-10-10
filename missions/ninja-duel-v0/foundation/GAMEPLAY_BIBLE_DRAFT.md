# Ninja Duel — gameplay bible proposée

Recherche arrêtée au **10 octobre 2026**. Statut : proposition à valider, aucun gameplay implémenté par FOUNDATION 01. Les références et leurs limites figurent dans [TECHNICAL_REFERENCE_MAP.md](TECHNICAL_REFERENCE_MAP.md). Les vingt comportements observables sont contractuels dans [HUMAN_ACCEPTANCE_MATRIX.md](HUMAN_ACCEPTANCE_MATRIX.md).

## FINAL VISION

Un arena fighter ninja en 3D où gagner signifie lire et déplacer un adversaire, exploiter une ouverture puis choisir entre poursuivre, projeter, préparer un piège ou se désengager. Deux corps, leurs trajectoires et les décisions des deux joueurs constituent le combat. Les dégâts sanctionnent une interaction réussie ; ils ne constituent pas cette interaction.

La boucle est `observer → provoquer → lire → ouvrir → exécuter → réponse adverse → punir ou sortir`. Une séquence doit émerger des règles communes : sprint, saut avec élan, mur, saut mural, dash aérien, kunai, réception, esquive, attaque avançante, launcher, poursuite, changement de trajectoire aérienne, slam et repositionnement. Aucun script ne doit reconnaître cette séquence entière pour la rendre possible.

### Mouvement

Le stick gauche règle direction et intensité. Marche, course et sprint ont un démarrage, une accélération et un freinage perceptibles. Inverser la direction produit un appui/pivot, pas un demi-tour instantané à pleine vitesse. L'accélération doit rester assez courte pour autoriser les micro-ajustements de distance.

Le saut hérite de la vitesse horizontale réellement acquise. Le contrôle aérien infléchit une trajectoire, sans autoriser une inversion instantanée ni une accélération infinie par sauts répétés. Une réception légère conserve l'élan tangent au sol ; une chute lourde engage une récupération explicite. Sur pente, les normales et la friction comptent ; les escaliers ne doivent pas devenir des trampolines.

Une esquive au sol ou un dash aérien applique une impulsion/une enveloppe de vitesse bornée, puis transmet une partie de son élan à la sortie. Collision avec un mur = déplacement interrompu proprement, pas traversée, téléportation ou glissement forcé jusqu'au point cible. Une neutral dodge a une direction de repli définie par la cible, jamais un vecteur arbitraire.

Le wallrun exige contact latéral, vitesse d'entrée tangentielle minimale et disponibilité de traversée. Sa direction découle du mur et de l'entrée ; sa durée est limitée. Détachement naturel, coin de mur, saut volontaire et mur devenu absent sont quatre sorties. Le walljump combine l'élan tangent et une impulsion extérieure ; le dash suivant ne remet pas les vitesses à zéro. Une même surface ne recharge pas indéfiniment les actions aériennes.

### Grammaire physique universelle

| Action | Engagement de l'attaquant | Résultat et branches du défenseur |
| --- | --- | --- |
| Light 1/2 | Anticipation courte, transfert d'appui, petite avance ; buffer de la prochaine action | Réaction orientée et recul mesuré ; garde/esquive selon fenêtre ; pas de chaîne garantie depuis n'importe quelle distance |
| Finisher horizontal | Engagement supérieur, déplacement limité par collision | Éloignement horizontal réel ; avantage de repositionnement, wallsplat possible |
| Heavy directionnel | Télégraphe plus long, rotation bornée, recovery punissable même sur whiff | Knockback orienté ; garde coûteuse mais règle lisible ; coup manqué n'attire pas l'adversaire |
| Launcher | Branche annoncée de la chaîne, contact obligatoire | Vitesse verticale et horizontale, arc balistique ; poursuite facultative de l'attaquant et récupération possible de la victime |
| Pursuit | Consomme un budget aérien et engage un déplacement interceptant, sans snap vers la cible | Ne garantit pas le contact ; esquive/evasive ou changement de trajectoire peut faire manquer |
| Air light | Contact en volume, animation avec anticipation/contact/sortie | Modifie la vitesse de la victime ; chaque coup doit changer quelque chose de visible dans l'échange |
| Downslam | Engagement vers le bas ; volume actif lié à sa phase | Accélération descendante, collision au sol, impact, knockdown, réveil ; pas de pose couchée flottante |
| Grab/throw | Portée courte, télégraphe, whiff recovery ; couplage bref de deux acteurs | La garde ne protège pas du grab ; le déplacement/esquive le contre ; lancer avant ou haut selon choix ; pas de weld permanent |
| Wall impact | Résultat d'une trajectoire et d'une collision, pas un effet déclenché par proximité | Wallsplat court ou rebond borné selon action, une seule fois par séquence ; sortie/réveil explicites |

Chaque action décrit anticipation, activité, recovery, déplacement, rotation, hit volume, réaction et conditions de cancel. Les fenêtres de cancel diffèrent sur hit, garde et whiff. Une saisie de bouton légèrement anticipée entre dans un buffer borné ; maintenir X ne rejoue pas une commande une fois par frame. Un trade simultané doit suivre une règle commune, pas l'ordre d'arrivée aléatoire de deux remotes.

Le juggle a un budget : coups/poursuites épuisent la possibilité de maintenir l'adversaire en l'air. À épuisement, sortie forcée de la chaîne et récupération protégée contre une relance immédiate. Le défenseur conserve une décision aux fenêtres explicitement prévues ; aucun infinité mur/air/sol.

### Défense, ressources et techniques

Garde directionnelle, déplacement, esquive et whiff punish sont le premier niveau défensif. La garde entraîne recoil, déplacement et coût de pression ; son angle, ses exceptions et sa sortie sont visibles. Une esquive a déplacement, courte fenêtre défensive et recovery distincts. Elle ne doit pas annuler gratuitement toutes les anticipations.

La substitution/evasive est une sortie limitée après ouverture : charge consommée côté serveur, direction choisie, sortie sûre vérifiée contre murs/terrain, délai avant contre-attaque, télégraphe permettant une lecture adverse. Elle ne recharge pas à chaque light ni à chaque contact au sol. Une option épuisée reste clairement indisponible. Le chakra paie les techniques ; le budget aérien et les charges de sortie restent des ressources lisibles distinctes, sans cinq jauges permanentes.

| Catégorie de jutsu | Décision offerte | Contre-jeu exigé |
| --- | --- | --- |
| Instant | Réponse locale rapide mais coût/conditions | Portée, angle, ressource et recovery limitent l'usage |
| Préparation courte | Menace lisible avant engagement | Melee interrompt avant la fenêtre de commit ; remboursement défini |
| Committed | Fort effet après engagement | Recovery punissable ; pas d'annulation gratuite une fois engagé |
| Conditionnel | Marque, LOS, contact, projectile ou état aérien | Condition visible/expirable ; vérification au départ et à la résolution |
| Charge/channel | Exposition contre rendement | Interruption, coût dans le temps et abandon contrôlé |
| Counter/Read | Anticipation d'un type de décision | Fenêtre courte, mauvaise lecture punissable ; aucune lecture parfaite permanente |
| Clone/piège/marque | Créer une géométrie ou information favorable | Budget d'entités, durée, indices et destruction/évitement possibles |

Outils et projectiles forcent garde, déplacement ou esquive afin de permettre une approche. L'attaquant ne doit pas pouvoir verrouiller indéfiniment la distance par spam. Les éléments changent une règle de zone, pression ou préparation ; ils ne se réduisent pas à une couleur de dégâts. Une feinte s'arrête pendant une fenêtre de préparation dédiée, avec coût partiel et recovery ; elle exige que l'autre joueur engage une réponse.

### Information et genjutsu

Une illusion falsifie une piste précise pendant une fenêtre courte : direction d'un déplacement, silhouette temporaire, son, cible apparente ou indicateur. Le joueur affecté peut toujours déplacer, garder, esquiver et attaquer. Il existe une vérification active ou un indice contradictoire. La tromperie peut provoquer une mauvaise décision ; l'utilisateur doit ensuite approcher et toucher réellement pour la punir.

La vérité serveur (corps, hit volumes, ressources) reste distincte de la perception de chaque observateur. Un clone purement visuel ne reçoit pas des dégâts destinés au corps réel par magie. Un clone physique éventuel possède un rôle, une collision et une durée déclarés. Lock-on, UI, audio et AI doivent consulter la même politique de perception pour éviter qu'un marqueur révèle automatiquement la vérité. Ce principe est une adaptation de design, pas un emprunt d'assets Riot ; voir les deux analyses Neeko dans la carte de recherche.

### Espace, caméra, animation et impact

Une arène compacte propose sol, murs exploitables, changements de hauteur et routes de sortie. Les coins sont des situations tactiques sans devenir des prisons permanentes. Les collisions, les limites et les surfaces autorisées au wallrun doivent se lire sans particules.

En lock-on, les deux corps et leur zone de contact restent cadrés ; une montée agrandit/élève le cadrage avant de perdre la victime. Le stick droit conserve une influence orbitale. À proximité d'un mur, la caméra se rapproche/recompose et masque si nécessaire l'obstacle localement ; elle ne traverse pas la géométrie. Hors lock, orientation libre et acquisition explicite. FOV lié à la vitesse réelle, transitions amorties, aucune cinématique qui vole les contrôles pendant un échange normal.

Le R15 doit être animé nativement, sur les proportions réellement utilisées. Direction, départ, arrêt, pivot, saut, mur, dash, chaque attaque et chaque réaction ont une couverture dédiée. Blending bas/haut du corps conserve les appuis quand l'action l'autorise ; lancer/slam/reaction forte prennent le corps entier. Les markers déclenchent sons/trails ; les phases de gameplay restent déterminées par les règles simulées. Une animation absente/inaccessible empêche de valider la mécanique. Le pipeline complet et sa couverture sont dans [FOUNDATION_ARCHITECTURE.md](FOUNDATION_ARCHITECTURE.md).

Impact = transfert d'appui + trajectoire adverse + contact synchronisé + son lisible + impulsion caméra mesurée. Shake désactivable, flashes contenus, trails brefs. Le hitstop éventuel ne bloque jamais arbitrairement tout le monde ni le réseau. Silhouette, anticipation et information utile priment sur quantité d'effets ; l'UI reste en périphérie.

### Vingt combattants et Create-a-Ninja

Une définition combine `MovementProfile`, `MeleeStyle`, `ToolSet`, `Resources`, `Traits`, `TechniqueDefinitions`, `PerceptionRules` et `AnimationSet`. Tous utilisent les mêmes intents et la même résolution physique. Les extensions reçoivent des événements/types de capacités, jamais une chaîne globale de `if FighterName == ...`.

| Stress test, sans conception de kit | Capacité que le socle doit exprimer |
| --- | --- |
| Minato | Marque/kunai, interception et angle d'approche, budgets de repositionnement |
| Itachi | Read faillible, projection/feinte, effets par observateur, punition manuelle |
| Lee | Pression physique, variations de vitesse/appuis, budgets de poursuite |
| Gaara | Volumes persistants, protection conditionnelle, contrôle de routes |
| Neji | Contacts précis, contrôle de ressource, défense rotative avec contre-jeu |
| Shikamaru | Conditions géométriques, préparation/piège, récompense de lecture |

Create-a-Ninja assemble plus tard des capacités autorisées sous budgets de compatibilité/coût, avec validation serveur des loadouts. Il ne télécharge pas de script utilisateur et ne multiplie pas les moteurs. Animations, volumes et profils doivent être validés ensemble ; mixer des avantages incompatibles est refusé par des règles de composition, sans écrire ce générateur maintenant.

### AI, produit et réseau

L'AI voit une observation limitée (distance/LOS/indices perçus, historique retardé), choisit un intent, puis passe par les mêmes coûts, fenêtres et collisions qu'un humain. Spacing, guard bait, préparation interrompue et poursuite sont des décisions. Difficulté = délai de réaction, précision et qualité de choix ; pas plus de dégâts, connaissance des boutons adverses ou substitution gratuite.

Le produit commence à **deux joueurs** : duel immédiat, entraînement/rematch, puis petites poules et examens. Un groupe réduit peut jouer des duels successifs, rencontrer des épreuves ou compléter avec AI clairement annoncé. Des événements plus grands composent ces rencontres ; ils ne nécessitent jamais vingt joueurs simultanés pour lancer le jeu. À vingt combattants au catalogue, seuls les acteurs présents sont simulés.

Progression future = apprentissage, variété et expression. Cosmétiques, poses, effets équivalents en lisibilité et personnalisation ; aucun achat de puissance, portée, ressource, i-frames ou accès à un avantage classé. Tournois, examens, progression et boutique ne sont pas des travaux FOUNDATION 02.

Prédiction locale pour ses commandes/mouvements/anticipations ; serveur pour contact, défense, dégâts, trajectoire de victime, coûts et fin de match. Corrections possibles et assumées, jamais résultat envoyé comme vérité par le client. Les validations portent aussi sur ressources, états, temps, ordre, débit et conditions géométriques. Les garanties natives proposées et leurs gates restent à qualifier ; la recherche ne constitue pas un test PvP.

## VERTICAL SLICE

Un excellent 1v1 dans une arène, deux combattants réellement différenciés, chacun avec un noyau physique complet et quelques techniques produisant des décisions différentes. Deux humains et un adversaire AI optionnel ; clavier/manette ; vraie place publiée de test sous le propriétaire final des animations. Les scénarios 01–20 doivent tous passer à ce stade, y compris marque et perception, sans raccourcis de démonstration.

## CURRENT FOUNDATION GATE

**FOUNDATION 01 : recherche et contrat seulement. FOUNDATION 02 : proposé, à approuver.** Le prochain gate doit prouver deux R15 gris, mouvement continu, corps contre corps, caméra, assets accessibles et PvP réactif, sans kits de personnage. Dix minutes intéressantes avec uniquement mouvement et combat physique. Les scénarios techniques futurs 14–17 restent des contrats d'extension explicitement NON TESTÉS tant que leurs fixtures/kits ne sont pas autorisés ; pas de faux PASS sur papier.

Hypothèses initiales à régler dans le playground, non mesures Roblox : accélération sprint 0,2–0,4 s ; freinage 0,12–0,25 s ; buffer 80–140 ms ; télégraphes/recovery de heavy supérieurs aux lights ; budget limité à une poursuite et une modification aérienne majeure avant sortie. Les distances/vitesses seront choisies avec le rig, les clips et l'arène ; celles de Phase 6B ne sont pas un standard à conserver.

## Anti-patterns et clôture

Refuser WalkSpeed seul, dash par interpolation de CFrame, zéro de vitesse entre actions, launcher par pose/Y, ragdoll à chaque light, dégâts/stun comme unique interaction, particules masquant les manques, chaîne infinie, jutsu automatique de cinq secondes d'impuissance, client déclarant un hit, présentation attendant chaque aller-retour, action accessible seulement au clavier, asset public considéré comme autorisé, et « animations meilleures plus tard ».

Une validation exige simultanément physique, animation, caméra, défense et contrôles. Une clause satisfaite n'annule pas les autres. Aucun des vingt scénarios humains n'est déclaré PASS par ce document.
