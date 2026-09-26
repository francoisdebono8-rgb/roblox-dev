# GAME0 — Quel jeu Roblox commercial construire ?

Étude du 26 septembre 2026, issue [#9](https://github.com/francoisdebono8-rgb/roblox-dev/issues/9). Recherche uniquement : aucun code, asset, jeu ou achat publicitaire créé.

## Décision

**Aucun candidat ne mérite encore le build commercial.** Parmi 26 pistes, trois restent intéressantes à examiner ; aucune ne démontre simultanément une différence immédiatement visible, une rétention plausible sans production permanente de contenu et une monétisation récurrente acceptable. Le meilleur sujet de validation préalable est **récupérer des objets avant une marée montante**, pas une recommandation de développement.

Une audience potentielle supérieure à celle d'un plugin ne signifie pas une meilleure probabilité de revenu. Le jeu nécessite acquisition, exploitation et renouvellement ; les données publiques ne permettent pas de comparer son bénéfice espéré à PresetForge.

## Méthode et limites

- **Observation [O]** : charts et recherche Roblox anonymes en français, descriptions publiques, métadonnées et passes publics, documentation officielle. Les compteurs sont des instantanés, pas des tendances.
- **Inférence [I]** : jugement de saturation, coût de production, difficulté et risque commercial déduit de ces observations.
- **Hypothèse [H]** : proposition de jeu, motivation du joueur, prix ou seuil de test non validé.
- Aucun jeu joué, aucun tutoriel interne, achat, taux de conversion, D1 ou revenu concurrent vérifié. Les descriptions sont les promesses des créateurs, pas une validation de leur exécution.
- Les résultats visibles favorisent les survivants. Une grosse audience ne donne ni le taux de réussite des nouveaux jeux ni leur coût d'acquisition. Un petit compteur isolé ne prouve pas non plus un échec commercial.
- Les estimations supposent un développeur expérimenté à temps plein avec Codex, des modèles simples originaux et des tests mobiles humains. Elles excluent les délais de modération et ne sont pas des engagements.

### Échantillon public observé

Sur les [charts Top Playing Now](https://www.roblox.com/fr/charts/top-playing-now), compteurs affichés arrondis : Steal An Egg 2,6 M ; +1 Speed Keyboard Escape 178,6 k ; +1 Loot To Forge 88,5 k ; Build and Kill Zombies 50,8 k ; Sol's RNG 41,6 k ; Karinderya 33,5 k ; Grow a Garden 32,8 k ; Drill Earth's Core 24 k ; Work at a Pizza Place et Grapple Cart Obby 15,7 k chacun. **[O] Ce sont des joueurs simultanés affichés, pas des acheteurs.**

Contre-échantillon : l'API publique donnait Cleaning Simulator 19 joueurs, Clean Your Room Before Mom 125, Superstore Simulator 3 et Restock Simulator 0 au moment de la lecture. Dans la [recherche « flood »](https://www.roblox.com/fr/discover/?keyword=flood), Flood Escape 2 affichait 372 et +1 Speed Escape Flood 2. Ces contrastes interdisent de conclure « genre populaire = clone rentable ».

Les métadonnées ont été lues via [Games API](https://games.roblox.com/v1/games?universeIds=323675642,10454823955,10648820673,9363735110,339208486,9898369521,10231962609). Ces endpoints sont des sources publiques consultées, pas des dépendances proposées pour un produit.

## A. 26 concepts, élimination initiale

Potentiel et verdicts ci-dessous sont des **inférences**, non des prévisions de vente. « Écarter » signifie pour notre équipe et notre budget, pas que le genre est inviable.

| Concept | Concurrence observée / référence | Potentiel et obstacle principal | Verdict |
|---|---|---|---|
| 1. Clicker +1 vitesse | [+1 Speed Keyboard Escape](https://www.roblox.com/games/95082159892680) | Promesse instantanée ; course aux variantes et faible identité | Écarter |
| 2. Incremental combat/forge | [+1 Loot To Forge](https://www.roblox.com/games/118805555015549) | Progression lisible ; équipement, équilibre et cadence de contenu | Écarter |
| 3. Jardin idle/offline | [Grow a Garden](https://www.roblox.com/games/126884695634066) | Retours naturels ; économie, collection et événements déjà établis | Écarter |
| 4. Vol/collection de créatures | [Steal An Egg](https://www.roblox.com/games/107778070777162) | Social et collection visibles ; frustration, économie et clones | Écarter |
| 5. RNG d'auras | [Sol's RNG](https://www.roblox.com/games/15532962292) | Production initiale accessible ; collection massive et hasard payant risqué | Écarter |
| 6. Collection de pets | [Pet Simulator 99](https://www.roblox.com/games/8737899170) | Progression et boutique évidentes ; volumes d'assets et concurrence | Écarter |
| 7. Merge de producteurs | [Monkey Tycoon](https://www.roblox.com/games/11400511154) | Combinaison compréhensible ; multiplicateurs peu différenciants | Écarter |
| 8. Tycoon de production | Lumber Tycoon 2, charts | Construction persistante ; sauvegarde, économie et édition complexes | Écarter |
| 9. Comptoir coopératif express | [Karinderya](https://www.roblox.com/games/116497287371701), [Pizza Place](https://www.roblox.com/games/192800) | Travail partagé ; doit rester bon sans équipiers | Finaliste B2 |
| 10. Supermarché/restock | [Superstore Simulator](https://www.roblox.com/games/104367690412000), [Restock Simulator](https://www.roblox.com/games/121369190169794) | Métier lisible ; répétition et UI mobile, traction non démontrée | Écarter |
| 11. Nettoyage/restauration | [Clean Your Room](https://www.roblox.com/games/85081695804302), [Cleaning Simulator](https://www.roblox.com/games/818287233) | Avant/après fort ; différenciation et retours faibles | Finaliste B3 |
| 12. Démolition/recyclage | Proximité nettoyage, collecte et Drill Earth's Core | Satisfaction potentielle ; physique et exploitation réseau coûteuses | Écarter : demande spécifique non établie |
| 13. Survie à catastrophes en manches | [Natural Disaster Survival](https://www.roblox.com/games/189707) | Compréhensible ; variété des cartes et catastrophes attendue | Écarter |
| 14. Survie coopérative longue | [99 Nights](https://www.roblox.com/games/79546208627805), [100 Days at Sea](https://www.roblox.com/games/70411440483149) | Sessions partagées ; IA, construction, contenu et équilibrage | Écarter |
| 15. Tour obby avec progression | Tower of Hell, charts | Mobile et peu de systèmes ; difficulté, niveaux et saturation | Écarter |
| 16. Obby coopératif à contrainte | [Grapple Cart Obby](https://www.roblox.com/games/117448312570314) | Invitation d'un ami plausible ; physique et besoin de partenaire | Écarter |
| 17. Véhicule contre vagues | [Build and Kill Zombies](https://www.roblox.com/games/105011592530400) | Résultat spectaculaire ; construction, IA et collisions | Écarter |
| 18. Extraction courte avant la marée | [Flood Escape 2](https://www.roblox.com/games/738339342), [Escape Tsunami](https://www.roblox.com/games/131623223084840) | Choix risque/récompense lisible ; voisinage concurrentiel très proche | Finaliste B1 |
| 19. Tower defense minimal | Tower Defense Simulator, charts | Progression récurrente ; unités, cartes et équilibre au-delà d'un petit V1 | Écarter |
| 20. PvE auto-attaque en arène | Voisinage +1 Loot To Forge / Build and Kill Zombies | Contrôle simple ; originalité et profondeur non établies | Écarter |
| 21. Roleplay social | Brookhaven / Berry Avenue, charts | Coplay ; monde, population initiale et modération nécessaires | Écarter |
| 22. Party/minigames courts | Ball vs Ball, charts ; proximité NDS | Rejouabilité ; plusieurs activités et serveurs peuplés nécessaires | Écarter |
| 23. Mode/défilé à votes | Dress To Impress, charts | Expression sociale ; garde-robe, art et modération coûteux | Écarter |
| 24. Pêche/collection | Fisch / Fish It, charts | Collection et rythme accessible ; gros catalogue et événements | Écarter |
| 25. Forage vertical | [Drill Earth's Core](https://www.roblox.com/games/101906032112547) | Progression spatiale visible ; véhicules, monstres et contenu | Écarter |
| 26. Livraison coopérative courte | Pizza Place ; voisinage des jeux de véhicules | Objectif clair ; conduite mobile et répétition sans différence nette | Écarter |

Les pistes 12 et 20 sont des variantes hypothétiques, pas des niches dont une demande autonome serait établie. Ball vs Ball prouve seulement la présence d'un titre adjacent dans les charts, pas les règles exactes d'un party game.

## B. Trois finalistes, aucun feu vert commercial

### B1. « Dernière marée » : récupérer, choisir, évacuer

**[H] Hook en dix secondes :** « L'eau monte. Ramène cette caisse ou tente la suivante. » Une caisse, une sortie et le niveau d'eau sont visibles immédiatement. Dans les trente premières secondes : déplacement, ramassage avec un bouton, dépôt, première récompense garantie sans achat.

**Boucle exacte :** manche de 2–3 minutes, choisir un trajet, porter une caisse, revenir au quai pour sécuriser sa valeur, éventuellement repartir plus loin, évacuer avant submersion. Seule la cargaison non déposée est perdue ; la progression acquise reste intacte. Nouvelle manche sans attente obligatoire d'autres joueurs.

**Progression / retour / social :** aménager un quai personnel avec les trouvailles, compléter de petites collections ; variantes de trajets et contrat quotidien. Passer une caisse à un ami serait une interaction facultative, jamais un verrou à deux joueurs. **[H]** Montrer son quai et partager une extraction pourraient encourager le retour et les invitations ; aucune de ces motivations n'est validée.

**Audit concurrentiel [O] :** Flood Escape 2 promet évasion face à l'eau/acide/lave, boutons et coopération, plus de 150 cartes communautaires et plusieurs mouvements. Escape Tsunami promet collecte sous menace, améliorations, revenus et extension de base. Leurs promesses recouvrent déjà l'essentiel du pitch.

**Monétisation visible [O] :** le [catalogue public FE2](https://apis.roblox.com/game-passes/v1/universes/323675642/game-passes?passView=Full&pageSize=100) proposait VIP à 1 200 Robux, Flood Pass Premium S2 à 399 et plusieurs packs cosmétiques. Celui d'[Escape Tsunami](https://apis.roblox.com/game-passes/v1/universes/9363735110/game-passes?passView=Full&pageSize=100) proposait notamment VIP à 175, VIP+ à 888 et Anti-Wave Device à 699. Prix publics de base observés, pas prix garantis pour tous les comptes ; présence d'une offre ne prouve pas ses ventes ni ses effets réels.

**Monétisation envisagée [H] :** décorations de quai et tenues déterministes ; éventuellement monnaie cosmétique achetable plusieurs fois. Pas de résurrection payante, protection payante ou capacité qui neutralise le choix de risque. Problème : une petite collection donne peu de motifs d'achats répétés, une grande recrée une charge artistique permanente.

**Minimum V1 hypothétique :** une petite carte originale à trois routes, une marée scriptée, huit objets de récupération, un quai, sauvegarde, interface tactile à une action, attribution serveur des récompenses, une offre cosmétique et instrumentation minimale. Pas de bateau physique, combat, trading ou génération procédurale.

**Difficulté Codex [I] : moyenne.** Peu d'art complexe, mais téléportation/décès/déconnexion en transport, double attribution, sauvegarde et synchronisation de l'eau sont des risques certains à tester. Compter 10–15 jours ouvrés jusqu'au test fermé, 15–25 jusqu'à une V1 publiable. Les achats et leur validation font partie de ce coût.

**Différence proposée :** livrer des objets pour transformer son quai, plutôt qu'accumuler des personnages et multiplicateurs. **Principal concurrent : Escape Tsunami. Principal risque : différence trop faible sur une miniature et après trois manches.** Un quai original n'est pas une barrière concurrentielle. Potentiel de recommandation seulement si le choix produit effectivement retour et coplay ; le thème n'offre aucun bonus algorithmique connu. IP/modération : objets et noms originaux, pas de marques/personnages repris, pas de hasard payant.

**Verdict : meilleur sujet de validation du hook, pas de build autorisé/recommandé.**

### B2. « Comptoir express » : servir seul ou à deux

**[H] Hook :** « Trois clients, deux mains, 90 secondes. » En trente secondes : prendre un ingrédient, le préparer en une action et remettre une première commande. Session : petites séries de commandes, récompense, amélioration visible du comptoir, nouveau service. Le solo doit rester complet ; un ami prend une station sans rendre le jeu obligatoire à deux.

**Progression / retour :** présentation du stand, quelques recettes et dispositions ; défis de service. Co-play et situations amusantes sont plausibles, pas démontrés pour ce nouveau concept. La progression risque de devenir une attente artificielle si les commandes ne changent pas réellement.

**Audit [O] :** Karinderya se présente comme un restaurant philippin coopératif avec objectif de cinq étoiles ; Work at a Pizza Place promet travail d'équipe sur les commandes et revenus utilisés pour meubler une maison. Ce dernier dispose donc déjà du lien métier → expression personnelle. Le [catalogue public Karinderya](https://apis.roblox.com/game-passes/v1/universes/10648820673/game-passes?passView=Full&pageSize=100) ne renvoyait aucun pass dans la réponse consultée. Cela ne prouve pas l'absence de produits consommables ou d'autres revenus ; sa boutique en jeu n'a pas été auditée.

**Monétisation [H] :** thèmes de comptoir et tenues, pas de priorité client payante. Les achats répétés supposent assez de décoration désirable ; vendre de la vitesse risque de dégrader le rôle du joueur gratuit.

**Minimum V1 :** un stand, trois recettes simples, un système de commandes, clients très simples, trois améliorations visuelles, support solo/deux joueurs, sauvegarde et boutique minimale. Difficulté Codex moyenne à élevée : concurrence sur les commandes, clients bloqués, duplication d'objets, équilibrage solo/duo et lisibilité tactile. Besoin artistique moyen, animation et feedback importants.

**Différenciation :** manches plus courtes et moins de déplacements. **Principal concurrent : Karinderya. Risque dominant : enlever la richesse du restaurant sans créer une meilleure raison de cliquer.** Saturation forte ; ni « plus petit » ni « plus rapide » ne suffisent. Estimation : 15–20 jours ouvrés testables, 20–30 publiables. IP/modération : recettes et objets originaux, aucune marque de restauration ; pas de texte libre nécessaire. Recommandation potentielle liée au coplay mais pénalisée si un serveur vide rend la boucle mauvaise.

**Verdict : écarter tant qu'une interaction sociale distincte n'est pas démontrée.**

### B3. « Remise à neuf » : des pièces sales aux pièces exposables

**[H] Hook :** « Cette pièce devient propre en une minute. » Dans les trente premières secondes : nettoyer une zone au doigt, ranger un objet et voir une récompense et un changement net. Session : terminer une pièce, choisir une amélioration d'outil, ouvrir la suivante. Long terme : restaurer et personnaliser son propre petit appartement.

**Retour / social :** contrats courts, appartement à montrer, aide facultative d'un ami. Une fois la satisfaction avant/après épuisée, le retour nécessite des pièces réellement différentes ; multiplier les jauges ne résout pas cela.

**Audit [O] :** Clean Your Room Before Mom promet déjà ramassage de jouets/déchets/vêtements, équipement, argent, nouvelles pièces et compte à rebours. Cleaning Simulator propose nettoyage solo/amis d'un bâtiment. [House Cleaning Simulator](https://www.roblox.com/games/10114636986) annonce outils, campagne et sandbox. Le besoin supposé est donc déjà servi, y compris sans pression obligatoire.

**Monétisation visible [O] :** [Clean Your Room](https://apis.roblox.com/game-passes/v1/universes/10454823955/game-passes?passView=Full&pageSize=100) proposait Unlimited Find Objective à 250 Robux, 2X XP/Power/Max Speed à 290 et 2X Money à 390. Aucun volume de ventes observé. Copier ces accélérateurs pourrait vendre la suppression de la tâche principale plutôt que son plaisir.

**Monétisation envisagée [H] :** outils visuels et mobilier non aléatoire. Minimum V1 : trois pièces originales, deux actions tactiles, saleté représentée par zones discrètes, progression courte, une pièce personnelle, sauvegarde et boutique. Pas de simulation de fluide ni peinture libre.

**Difficulté Codex [I] : faible à moyenne**, art moyen : c'est le changement visuel, non le code de nettoyage, qui vend la promesse. Risques : zones inaccessibles, ciblage tactile, état partagé incohérent et répétition. Estimation : 10–15 jours ouvrés testables, 15–22 publiables. Différence proposée : restaurer puis habiter la pièce ; déjà proche des jeux de maison. **Principal concurrent : Clean Your Room. Risque dominant : rétention et achats récurrents insuffisants.** IP/modération faibles avec objets originaux ; aucune garantie de recommandation liée à un avant/après satisfaisant.

**Verdict : écarter, sauf observation ultérieure d'une attente précise non couverte.**

## C. Pourquoi aucun gagnant aujourd'hui

| Critère décisif [I] | Marée | Comptoir | Nettoyage |
|---|---|---|---|
| Compréhension visuelle rapide | Plausible | Plausible | Plausible |
| Solo et mobile sans système lourd | Plausible | Plus délicat | Plausible |
| Différence concurrentielle démontrée | Non | Non | Non |
| Retour sans gros catalogue | Non démontré | Non démontré | Fragile |
| Achats répétés sans avantage gênant | Non démontrés | Non démontrés | Non démontrés |
| Produit durable exploitable seul | À tester | Risqué | À tester |

Le piège serait de choisir le nettoyage parce qu'il est facile à programmer, ou la marée parce qu'un concurrent affiche beaucoup de visites. **La preuve manquante est une préférence joueur pour notre différence, pas la faisabilité technique.**

### Ce que les sources officielles changent

La [documentation Discovery](https://create.roblox.com/docs/discovery) distingue exposition initiale et recommandation. Les signaux incluent engagement, retours, coplay intentionnel et monétisation ; ils ne se réduisent pas à la taille brute du jeu. Les publicités peuvent apporter des joueurs, pas acheter une bonne performance organique. Les comportements du trafic recommandé et ceux du trafic publicitaire ne doivent pas être confondus. Aucun seuil de cette étude n'est une promesse d'entrée dans les recommandations.

Les [passes et produits développeur](https://create.roblox.com/docs/production/monetization) ne sont pas interchangeables : achat permanent d'un côté, répétable de l'autre. Une économie et un traitement fiable des achats doivent exister avant de mesurer un revenu ; proposer une boutique n'établit aucune volonté de payer. Éviter le hasard payant évite aussi une partie des contraintes supplémentaires des [objets aléatoires payants](https://create.roblox.com/docs/production/monetization/paid-random-items).

**Blocage administratif potentiel, non vérifié sur le compte :** les [conditions de publication actuelles](https://create.roblox.com/docs/production/publishing/publish-games-and-places) distinguent audiences et éligibilité. Elles prévoient notamment contrôle d'âge et questionnaire ; l'accès aux audiences enfants implique des exigences supplémentaires, dont vérification/2FA et condition d'abonnement ou frais. Le parcours à frais indique 1 000 Robux par expérience. Ne pas supposer qu'avoir publié un plugin satisfait ces conditions. Vérifier le parcours réellement proposé avant de promettre une date ; aucun compte modifié ici.

### Retours développeurs : contre-exemples, pas benchmarks

- Un [auteur de tower defense, juin 2026](https://devforum.roblox.com/t/4662850), rapporte environ quinze minutes de jeu mais peu de retours après publicité. **Auto-déclaration**, utile pour rappeler qu'une longue première session n'est pas la rétention.
- Un [auteur d'incremental, juillet 2026](https://devforum.roblox.com/t/4756120), décrit l'absence de recommandations pendant douze jours puis leur arrivée. Ses chiffres ne sont pas auditables ; ne pas abandonner uniquement parce qu'aucune recommandation n'arrive en 72 heures.
- Un [retour sur un jeu de combat, septembre 2025](https://devforum.roblox.com/t/3929377), décrit pics de fréquentation publicitaire et faibles retours. La simultanéité momentanée ne suffit pas.
- Le [retour Sea Cleaning Simulator](https://devforum.roblox.com/t/teamseas-sea-cleaning-simulator-uncopylocked/1689682) annonce une réalisation rapide, mais les réponses évoquent des problèmes de contrôle de bateau. Aucun code ni asset repris : prototype rapide ne signifie pas jeu mobile commercial robuste.
- Dans ses [retours d'expérimentation](https://devforum.roblox.com/t/4549276), Roblox décrit des améliorations issues de tests ciblés de progression et de contrôles mobiles et recommande une durée plus longue pour conclure. Les premiers jours servent à détecter les ruptures, pas à certifier un revenu durable.

## D. Plan de validation conditionnel, plafond absolu 50 €

**Aujourd'hui : 0 € et aucun build.** Il n'y a donc pas de campagne recommandée à lancer. Le protocole suivant concerne uniquement B1 si une validation préalable fait apparaître une différence et si un développement est autorisé dans une autre tâche.

### Porte 0 : avant tout développement

Présenter oralement le hook et sa différence à 8–12 joueurs Roblox correspondant à la cible, dont au moins la moitié principalement mobiles. Ne pas prétendre qu'un produit existe. Demander de reformuler l'action, de citer les jeux similaires et d'expliquer pourquoi ils choisiraient celui-ci ; ne pas compter les compliments comme intention de retour.

**Seuil opérationnel [H] :** au moins 8 sur 12 comprennent la décision « sécuriser ou repartir », et au moins 6 peuvent expliquer spontanément une différence pertinente avec les concurrents. Sinon reformuler une fois puis arrêter cette piste. Petit échantillon exploratoire, pas une validation statistique ni une preuve de volonté de payer. Pas de rémunération promise hors budget.

### Budget et instrumentation, seulement après la porte 0

- 30 € maximum pour une première acquisition ciblée ; 10 € pour une seule relance après correction mesurable ; 10 € de réserve de change/taxes. Total débité maximum 50 €, recharge automatique désactivée.
- Vérifier prix et minimums réellement proposés dans [Ads Manager](https://create.roblox.com/docs/production/promotion/ads-manager). La documentation mentionne l'achat à partir d'un crédit ; cela ne garantit ni un minimum de campagne identique ni un coût par joueur. Si le parcours ne rentre pas dans le plafond, ne pas lancer.
- Le plafond ci-dessus est marketing, pas temps de développement. Si 50 € doit couvrir aussi les frais de publication éventuels, les déduire avant toute publicité ; ne pas élargir implicitement le budget.
- Tester d'abord avec quelques volontaires sur mobile. Ne pas acheter du trafic pour découvrir une sauvegarde cassée. Aucun budget ne garantit 100 joueurs.
- Prévoir, dans une éventuelle future V1, les événements minimum : arrivée, première caisse, premier dépôt, fin de manche, seconde manche, retour, ouverture boutique et achat confirmé côté serveur. Séparer volontaires, publicité et organique ; exclure l'équipe.
- Les [conditions de l'Analytics Dashboard](https://create.roblox.com/docs/production/analytics/analytics-dashboard) exigent plus de 10 DAU et 10 heures de jeu pendant sept jours consécutifs pour l'ensemble des KPI. Ne pas promettre ces tableaux au jour 1. Prévoir une mesure minimale agrégée et vérifiable ; sinon noter les mesures indisponibles, jamais les reconstruire intuitivement.

### Les 24–72 premières heures

| Moment | À observer | Décision possible |
|---|---|---|
| 0–24 h | Mobile réel, erreurs, pertes de données, arrivée → dépôt, temps jusqu'au dépôt, abandon avant 60 s, seconde manche | Couper l'acquisition si panne ; corriger un obstacle identifié |
| 24–48 h | Retours des cohortes ayant réellement eu le temps de revenir, session médiane, différences mobile/ordinateur et sources | Distinguer défaut de compréhension et défaut d'intérêt |
| 48–72 h | Cohortes D1 mûres, répétition des manches, coplay spontané, dépenses publicitaires réelles et premiers achats éventuels | Décider correction limitée, poursuite d'observation ou abandon ; pas de conclusion D7 |

Définir D1 selon la [mesure de rétention Roblox](https://create.roblox.com/docs/production/analytics/retention) lorsque disponible. Toute mesure provisoire doit préciser sa fenêtre et son dénominateur ; ne pas la présenter comme identique au dashboard. Ne pas inclure dans D1 les derniers inscrits qui n'ont pas encore eu leur fenêtre de retour.

### Seuils de travail, pas standards Roblox

À utiliser avec **au moins 100 nouveaux joueurs mesurables**, dont un sous-échantillon mobile identifié, et 100 joueurs ayant une fenêtre D1 complète pour le seuil de retour. Si le budget n'atteint pas ces effectifs, verdict **inconclusif**, pas obligation de dépenser davantage. Même à 100, les marges d'incertitude restent importantes.

| Indicateur | Continuer à observer | Corriger une fois | Abandonner / arrêter |
|---|---|---|---|
| Dépôt d'une caisse dans les 60 s / nouveaux joueurs | ≥ 70 % | 40–69 % avec obstacle précis | < 40 % après correction |
| Début d'une deuxième manche / nouveaux joueurs | ≥ 45 % | 25–44 % | < 25 % après correction |
| Retour D1 / cohorte mûre | ≥ 15 % | 8–14 % | < 8 % avec onboarding réparé |
| Fiabilité | Pas d'erreur bloquante observée | Défaut local reproductible | Arrêt immédiat des ads si perte de données/achats ou boucle inutilisable |
| Coût réel par joueur et budget | Mesurés, plafond respecté | Ciblage/création publicitaire à revoir | Plafond atteint : arrêter les dépenses, même si inconclusif |

Ces seuils **[H]** sont des garde-fous pré-enregistrés et arbitraires, pas des percentiles de marché. Un résultat proche de la frontière mérite observation et entretien, pas une décision pseudo-statistique. « Continuer » signifie suivre les cohortes jusqu'à D7, sans autoriser automatiquement un second budget ou davantage de contenu.

Suivre aussi les achats confirmés, acheteurs uniques et recettes nettes réellement disponibles. **Zéro achat sur un petit échantillon ne prouve pas l'absence de marché ; quelques achats ne prouvent pas une économie rentable.** Ne pas annualiser 72 heures, ne pas confondre Robux dépensés et euros encaissables, ne pas calculer une LTV sans historique. Ni CTR seul, ni absence de trafic Home en trois jours ne décide du sort du jeu.

## Conclusion opérationnelle

Ne pas ouvrir aujourd'hui une issue d'implémentation de jeu. Valider d'abord la préférence pour B1 à coût nul ; garder B2 et B3 écartés sauf information nouvelle. Si personne ne distingue réellement la proposition, arrêter la piste plutôt que produire un clone techniquement propre. Le prochain investissement doit acheter une information manquante, pas ajouter du code.
