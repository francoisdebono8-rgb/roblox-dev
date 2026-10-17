# Progression, maîtrises et tournois — proposition architecturale

**Statut : PROPOSITION À VALIDER, aucun ordre d’implémentation.** Audit Codex du 17 octobre 2026, HEAD `b3f8ffbf137734adf12f81f9fa4d4a9f0227228d`, branche `claude/ninja-duel-2026-10-14`. La priorité Claude reste le roster V1 et la séquence DEC-021 ; cette préparation n’ouvre aucun chantier gameplay. Décisions produit : [DEC-023/024](../active/DECISIONS.md). État et exécution : [sources actives](../../CLAUDE_START_HERE.md). Les nombres proposés ci-dessous ne sont ni équilibrés ni approuvés.

## EXISTANT RÉUTILISABLE

L’utilisateur décrit la cible des vingt V1. **Le code au HEAD audité n’en expose que dix**, via [Shared/Roster](../../src/Shared/Roster.luau) : Minato, Itachi, Neji, Sasuke, Gaara, Lee, Naruto, Temari, Hinata, Kakashi. Les dix autres sont verrouillés par DEC-022, pas déjà jouables. Ne pas inventer vingt arbres disponibles ni vingt Tier A validés.

| Composant réellement lu | Réutilisation et limites constatées |
|---|---|
| [SkillTrees](../../src/Server/SkillTrees.luau) | Quatre arbres seulement : Flashstep 19, Mirage 18, GentleFist 19, Lion 19 = **75 nodes**, dont 35 Major et 10 Kind=stat. Données Id/Kind/Cost/Branch/Requires/RequiresAny/Exclusive/Effects/Shows/Counter/Lore. Les arbres Lee/Temari n’existent pas. |
| [SkillBuilds](../../src/Server/SkillBuilds.luau) | Validation serveur : tableau borné, IDs connus/uniques, prérequis **actifs**, choix exclusifs, budget/unlocked optionnels ; build sur copies de Fighters et MoveGraphs ; empilement dans l’ordre de l’arbre. checkTree contrôle cycles, bornes, champs et builds maximaux. Conserver ce noyau, ne pas créer un deuxième compilateur. |
| Restrictions du compilateur | MAX_NODES=40, DESIGN_MAX=120..150 ; exigence actuelle d’au moins un node de chaque Kind, même stat. OPTIONAL/RATIO/RANGE_READ/PAYOFFS bornent les champs connus. Ce contrat CORE4 ne correspond pas automatiquement à des petits arbres qualitatifs asymétriques. wired() vérifie les déclarations de câblage, pas une preuve de comportement/Studio. |
| [ProfileSchema](../../src/Server/ProfileSchema.luau) | V1 : earned/unlocked/builds/selected par fighter ; huit presets max, validation JSON bornée, commandes grant/unlock/saveBuild et séquence idempotente. Déverrouiller deux exclusivités est permis ; les activer ensemble non. Pas XP, roster possédé, pratique acquise ni distinction preset permanent/tournoi. |
| [ProfileRepository](../../src/Server/ProfileRepository.luau) | Dépôt à clé unique, lease de session, révision/fence, retry du même snapshot, refus des lectures corrompues/futures, adaptateurs mémoire et DataStore explicitement activé DEV/live. Main n’installe pas load/pulse/closeAll ; aucune persistance de progression live démontrée. |
| [Matches](../../src/Server/Matches.luau), [Combat:add](../../src/Server/Combat.luau) | resolveKit valide le kit optionnel avant start local/IA ; Combat:add utilise kit.def/kit.graph propres à l’acteur. Rematch local garde les options ; frontière utile pour figer un build. |
| [Online](../../src/Server/Online.luau) | Queue casual, codes par serveur, choix, duel serveur, forfait/rematch. fight appelle Combat:add **sans kit**. enter/pick vérifient Fighters[id], pas le roster possédé. Aucun branchement de SkillBuilds.admit/profil dans ce flow. Jamais prétendre que le tournoi standardisé existe déjà. |
| [BuildPresets](../../src/Server/BuildPresets.luau) | Presets CORE4/IA par budget ; bons fixtures et démonstrateurs, pas catalogue de vingt arbres ni système de sélection tournoi. |
| [Families](../../src/Server/Families.luau) | Familles Projectile/Strike/Burst/Zone/Buff/Teleport/Counter ; contact, beforeHit/afterHit, strikeHit/projectileHit, zoneTick, speed/regen/damage et snapshot. Les techniques lisent leurs specs ; maintenir comportement dans ces handlers, pas dans les nodes. |
| [MoveGraphs](../../src/Shared/MoveGraphs.luau), [Fighters](../../src/Shared/Fighters.luau) | Routes, cancels, reengage, airFinisher, éveil, outils et définitions déjà spécifiques ; éviter d’en déplacer les signatures vers des nodes payants. |
| [ChakraTuning](../../src/Server/ChakraTuning.luau), [ChakraCombat](../../src/Server/ChakraCombat.luau) | Profils d’affinités/capacités fixes et règles objet + nature + contexte. **Leur “Mastery” est une capacité du kit**, pas une maîtrise de joueur gagnée. Ne pas écrire les niveaux de pratique dans ces tables partagées. |
| [Brawler](../../src/Server/Brawler.luau), [Combat](../../src/Server/Combat.luau) | Points d’autorité pour contacts, défense, routes, réactions, techniques, mort, objets. Brawler.event compte surtout des événements pour tuto ; impacts servent la présentation. Ni l’un ni l’autre n’est un journal durable dédupliqué de maîtrise. |

**Validation de cet audit :** lecture des modules ci-dessus, des specs/profils/tests Progression et Profiles, des sept docs actives et des définitions concernées. Commande tests/run.sh tentée : non exécutée (Luau et Lune indisponibles dans cette session). Aucun Studio lancé. Les manifests du HEAD rapportent 26 suites automatisées PASS, nativeQA/visualAcceptance/controllerFeel PENDING ; ce sont des preuves enregistrées, pas rejouées ici. Les observations natives partielles de Claude dans CURRENT_STATE restent distinctes des flags globaux du manifest. Contrôles de cette livraison : docs/liens et sept régressions de reprise PASS (75 IDs), frontières PASS (403 fichiers), isolation 9/9 PASS et diff --check PASS. Aucun source, test gameplay, builder ou artefact modifié.

## MANQUES

1. Séparer clairement **possession de personnage**, déblocages permanents, points équipés, budget tournoi et preuve de pratique.
2. Un catalogue de vingt arbres : seules quatre premières fondations existent, avec beaucoup d’ajustements numériques. Aucun système de maîtrise acquise, d’opportunités qualifiées, de certification ou de lutte contre le farm.
3. Politique serveur par mode : Practice prêtée, permanent, casual choisi, tournoi standardisé, futur Open Tournament. Le tournoi actuel refuse les nodes non possédés si unlocked est fourni ; supprimer simplement ce paramètre ne crée pas une politique d’accès sécurisée.
4. Profil versionné capable de posséder un fighter sans arbre encore publié ; V1 refuse tout record sans SkillBuilds.tree. Sauvegarde de presets tournoi prêtés actuellement refusée par le contrôle des unlocked permanents.
5. Runtime host de profils, attribution de résultats idempotente, transport des builds online, versions de catalogue/règles et cycle de migration/remboursement.
6. Vue publique du catalogue : SkillTrees est serveur, pas utilisable tel quel par la future UI. Pas de progression/maîtrises/build editor branchés au flow normal.
7. Preuves de niveau 1 et compatibilité des nouveaux comportements avec animations, feedback, IA, objets, murs, substitutions et online. “Champ déclaré wired” n’est pas une recette jouable.

## ARCHITECTURE PROPOSÉE

### Un compilateur de kits, plusieurs politiques d’accès

Conserver **SkillBuilds** comme fonction pure qui valide puis compile un kit. Étendre le schéma par versions et adapters au lieu de jeter ses règles. Une seule définition de node, un seul coût actif et un seul comportement, quel que soit le mode.

Flux proposé :

```text
Catalogue validé + profil serveur + Ruleset serveur + preset d’IDs
    → BuildPolicy.resolveEligibility(mode, fighter, nodes)
    → SkillBuilds.validate(…budget, prérequis, variantes, allowlist…)
    → SkillBuilds.compile(…) = kit isolé + résumé + version/fingerprint
    → snapshot d’admission immuable
    → Matches / Online : Combat:add(…, kit)
    → moteur existant + événements sémantiques serveur
    → réducteur MasteryLedger par match
    → résultat serveur dédupliqué → dépôt de profil
```

**Module frontière proposé, non créé :** BuildPolicy choisit les droits d’usage selon Ruleset ; il ne calcule ni hitbox ni dégâts. ProgressionService gère profil/XP/possession/récompenses ; MasteryLedger évalue les événements ; MatchContracts fige les deux builds. Ces noms désignent des responsabilités, pas un framework à créer en bloc. Partir de fonctions dans les modules existants ; extraire seulement quand deux consommateurs réels l’exigent.

Mode, roster publié/activé et budget viennent du serveur. Un fighter dans Fighters mais absent du roster publié, ou un node seulement data-only, ne devient pas admissible par requête forgée. allowUnwired demeure réservé aux outils de design isolés. Le client transmet au plus fighterId, presetId ou IDs/variantes bornés et la version attendue ; jamais earned/unlocked/mastery, stats calculées, effets, budget ou règles faisant foi. Charge/validation à entrée de file, contrôle après choix du personnage et avant match ; changement de pick invalide le prêt/build précédent. Revalidation après attente si version/profil a changé, pas pendant le duel.

Conserver le même snapshot sur tous les rounds ; évolution du profil/achat/XP n’a aucun effet sur le match en cours. Rematch : nouveau contrat sous le même ruleset, revalidation des droits, aucun changement caché d’arbre après révélation adverse. Reprise éventuelle : contrat d’origine, pas recompilation depuis le profil nouvellement modifié.

### Publication des définitions

Catalogue serveur canonique ; sérialisation publique contrôlée des seuls IDs, liens, coûts, descriptions, contre-jeu, compatibilités et raisons de blocage. Aucun besoin de cacher les mécaniques par sécurité ; les paramètres applicables viennent toujours du serveur. Hash de contenu/versionBalance/treeVersion dans l’admission et la vue UI ; une UI obsolète reçoit une raison et un refresh plutôt qu’un build silencieusement corrigé.

## MODÈLE DE DONNÉES

Schéma illustratif, **pas code runtime à copier**, ni IDs définitifs. Garder les IDs existants en migration et ne jamais les recycler. Le prototype de coûts ne remplace pas les budgets actuels.

```json
{
  "treeVersion": 2,
  "fighterId": "Flashstep",
  "branches": [{"id":"angles","label":"Angles et réentrée"}],
  "nodes": [{
    "id": "AirExit",
    "branch": "angles",
    "cost": 3,
    "requiresAll": ["AirSwitchSeal"],
    "requiresAny": [],
    "exclusiveGroup": "arrival_choice",
    "masteryAll": [{"id":"conversion","scope":"global","tier":2}],
    "effects": [{"kind":"behavior","id":"arrival_tool_option","params":{"variant":"departure_anchor"}}],
    "slot": "arrival.option",
    "modeAllowlist": ["practice","permanent","standard_tournament"],
    "explains": "Choisir un point de sortie à l’arrivée aérienne.",
    "counterplay": "Option remplace la frappe d’arrivée ; point visible.",
    "lore": "GAMEPLAY_LIBERTY"
  }]
}
```

| Champ/règle | Contrat proposé |
|---|---|
| Id | Stable, unique dans l’arbre, préfixage par fighter dans logs/profil. Ne pas renommer les anciens sans migration. |
| Branch | Présentation seulement ; pas une classe de combattant ni un moteur distinct. |
| Cost | Entier positif ; même coût d’activation tous modes. Compter chaque ancêtre **actif**, une fois. Coût permanent de déblocage initialement égal, relation à confirmer. |
| Prérequis | DAG all/any, pas d’ancestor incompatible avec une exclusivité, roots accessibles sans boucle. Maîtrise indépendante du nœud qui la demande : obtenable avec le kit de base/Practice. |
| ExclusiveGroup/slot | Posséder plusieurs options permis ; n’activer qu’une variante incompatible par slot. Alternative à une croissance qui finit par tout cumuler. |
| Effects | Adapter les anciens tuples path/op/value ; nouveaux comportements par ID de handler typé/allowlist et paramètres bornés. Pas de fonctions sérialisées, scripts, eval ou paths arbitraires soumis par le client. |
| Composition | Ordre explicite : base canonique → choix de routes/slots → traits paramétrés → bornes invariantes → résumé. Rejeter deux writers non déclarés sur le même champ ; ne pas résoudre par “dernier node gagné”. |
| Borne | Coûts chakra/recovery, maximums objets/zones, i-frames, nombre de poursuites/cancels et sorties défensives testables ; pas de combo infinie ni garantie de toucher. |
| Apparence/IA | Chaque behaviorId désigne aussi événements/indices nécessaires et scénario d’IA/QA ; rendu lit l’état réel, pas la possession de node. |
| Versions | schemaVersion profil, catalogVersion/treeVersion, masteryRuleVersion et balanceVersion distincts. Preset invalidé par patch conservé pour édition, jamais réduit ou activé silencieusement. |

### Profil V2 proposé

```json
{
  "schemaVersion": 2,
  "account": {"xp":0,"unlockedFighters":{"Flashstep":true},"starterClaimed":true},
  "globalMastery": {"defense":{"ruleVersion":1,"tier":0,"evidence":{}}},
  "fighters": {
    "Flashstep": {
      "xp":0,"earnedPoints":0,"ownedNodes":{},
      "mastery":{"seal_geometry":{"ruleVersion":1,"tier":0,"evidence":{}}},
      "presets":{
        "p1":{"name":"Angles","mode":"standard_tournament","rulesetId":"standard_v1","treeVersion":2,"nodes":["AirExit"],"variants":{},"needsReview":true}
      }
    }
  },
  "revision":0,
  "recentResultReceipts":[],
  "lastCommand":null
}
```

Le preset minimal ci-dessus est volontairement **invalide sans ses prérequis** : needsReview=true le rend éditable, jamais admis au match. En production, sauvegarder un preset légal selon sa politique ; conserver un preset devenu invalide après patch sans corrompre le profil. Les droits permanents ne sont pas ceux d’un preset tournoi.

Profil : stocker XP, droits et preuves agrégées bornées, **pas** le kit dérivé, des tables de combat complètes, chaque frame ni tout l’historique de match. Dériver niveau/points disponibles via config versionnée ; stocker les crédits accordés quand une courbe change pour éviter une perte rétroactive. Limite proposée : six presets par personnage, compatible avec un plafond global en octets ; V1 en permet huit, **aucune suppression des presets existants** pour adopter cette préférence.

### Sauvegarde, récompenses et transitions online

Réutiliser ProfileRepository et ses verrous, pas ajouter une bibliothèque non nécessaire. Migrer V1→V2 explicitement : earned→earnedPoints, unlocked→ownedNodes, ancien selected/builds→presets permanents. **Ne pas déduire le roster possédé de la présence d’un ancien record** sans décision produit. Quarantaine pour schéma futur/lecture impossible ; pas de profil vide sauvegardé sur erreur. Compatibilité des anciennes versions de serveur, déploiement/drain et rollback avant activation live.

Une seule écriture atomique pour le profil d’un utilisateur. Identifier les commandes par token et empreinte des arguments ; même token avec payload différent doit être refusé, pas interprété comme une nouvelle transaction. Commande de résultat identifiée par matchId + userId + résultat/règle de récompense et dédupliquée, même après reconnexion. Le lastCommand V1 ne protège que la dernière commande séquentielle : insuffisant pour les résultats/reçus tardifs. Ajouter journal borné + plancher/checkpoints selon politique de replay. Une preuve déjà appliquée ne donne jamais deux fois points ou maîtrise. Les deux profils des adversaires ne forment pas une transaction DataStore atomique ; appliquer chaque résultat indépendamment et prévoir reprise, pas un faux “commit global”.

Pour l’alpha : garder récompenses sur le serveur de duel tant que possible. Si hub/place de match séparés plus tard : libérer/acquérir la lease proprement ; le serveur qui reçoit relit les droits. TeleportData n’est ni profil ni preuve de victoire. Contrat/reçu de match côté serveur, réconciliation bornée après crash. Une durabilité forte entre crash de match et première sauvegarde requiert un outbox/reçu durable : ne pas promettre exactly-once sans ce mécanisme. **USER DECISION REQUIRED :** quelle garantie de récupération des gains est nécessaire à la première release progression ?

Les adaptateurs DataStore restent explicitement activés, expérience test séparée du live ; aucun appel par hit. Flush périodique/fin de match et fermeture, retries bornés et feedback “sauvegarde en attente”. Match standard si profil non chargé : Practice prêtée possible ; pas d’attribution permanente ni de ranked supposant des droits inconnus.

## RÈGLES DE DESIGN DES ARBRES

### Niveau 1 : identité complète, profondeur incomplète

Pour **chaque** fighter : mouvement reconnaissable et maniable ; neutral et entrée/sortie ; light/heavy et route directionnelle ; air/mur adapté à l’archétype ; défense/garde/dodge/substitution ou équivalent ; outil pertinent ; ressource et limites lisibles ; techniques fondamentales en nombre cohérent ; signature et première boucle complète ; éveil de base qui change réellement une règle. La checklist Tier A reste la référence ; pas ajouter du ninjutsu à Lee pour remplir une colonne.

| Toujours disponible sans progression | Déblocable si la boucle de base reste entière |
|---|---|
| Minato : poser/utiliser des marques, choisir un angle et téléporter | Choix entre sorties d’arrivée, façon de recycler une marque, conversion après réaction adverse |
| Lee : taijutsu, poursuite, launcher/Lotus, parade au pied, rupture, Portes de base | Finisher alternatif, choix sortie/pression après défense, arbitrage de risque des Portes |
| Temari : tenir la distance, éventail, vent/retour des lames, Updraft/couloir et éveil | Orientation/fin de zone, conversion d’un contrôle réussi, alternative de repositionnement |
| Tous : commandes accessibles et contre-jeu fiable | Contextes, variantes, cancels limités, transformations de techniques, spécialisations compatibles avec ces commandes |

Aucun node ne débloque “la caméra correcte”, “le premier combo fiable”, “la vraie garde” ou la signature promise. Ne pas retirer une fonction V1 satisfaisante pour la revendre dans V2. Avant conservation d’un ancien node CORE4 : comparer son effet au nouveau kit de base ; s’il est devenu redondant, reclasser/remplacer avec migration/remboursement plutôt qu’un faux déblocage. Les statistiques de base peuvent différer entre ninjas ; c’est la progression permanente qui est neutralisée en tournoi, pas une obligation de mêmes HP pour tous.

### Taille initiale soutenable et profondeur d’un main

Recommandation : **12 nodes par personnage, trois branches lisibles de quatre**, schémas non forcément symétriques. Au moins **10/12 changent une décision ou un comportement** ; zéro node purement +HP/+dégâts/vitesse recommandé pour cette première version. Les 2 autres éventuels doivent avoir un effet de confort/contextuel explicable, jamais une taxe numérique obligatoire avant un node utile. Un seul rang par node au départ, pas cinq upgrades de la même chose. Taille/coûts finaux = proposition, pas baisse rétroactive imposée aux 75 nodes existants.

Vingt arbres = 240 nodes, **pas 240 mécaniques uniques**. Partir de 8–12 motifs de modification réutilisables démontrés (sortie après réaction, variante de route, conversion outil, choix air/sol, contrôle de zone, trait d’éveil, etc.), deux ou trois capacités réellement signature par arbre, surtout des extensions des mécaniques déjà portées par le kit, et composants déjà présents. Les nœuds identitaires restent parfois spécifiques : ne pas créer un langage générique de script pour supprimer toute ligne spécifique.

La profondeur vient de trois décisions croisées : **où préparer l’ouverture, comment convertir, comment conserver une sortie**. Coût/ancêtres/exclusivités empêchent de tout avoir ; matchup, espace, ressource et lecture changent le bon choix. Un main Lee apprend ses distances, ses sorties et son risque corporel ; un main Minato construit la géométrie de ses destinations. Les systèmes communs exécutent ces plans différents. La maîtrise reconnaît cette expertise ; elle ne la remplace pas par une barre remplie.

Budget proposé pour le **prototype seulement** : 6 unités, chaque branche courte exemple coûte 1 puis 3 (coût cumulé 4). Trois racines + un avancé = 6 ; deux avancés = 8, donc impossible. Ce calcul illustre un arbitrage ; il ne choisit ni budget live ni valeurs des arbres complets. Deux builds de même coût ne sont pas automatiquement équilibrés : mesurer domination de choix et matchup humain.

## RÈGLES DE MAÎTRISE

### Familles initiales

Recommandation : **six familles globales**, plus **une signature par personnage** au premier pilote (20 signatures ensuite, sans les inventer maintenant). Trois paliers qualitatifs I/II/III proposés ; éviter vingt métriques propres par fighter.

| Famille | Preuve pertinente et limite |
|---|---|
| Défense/lecture | Parade, dodge intentionnel ou interruption d’une menace réelle ; confirmer sortie/punition appropriée, pas garder contre mannequin inerte |
| Conversion/continuité | Ouverture → route réussie → fin propre, sol/air/mur comme contextes distincts ; pas durée de combo infinie |
| Mobilité/position | Entrée ou sortie utile après pression, approche mur/angle et reengage sûr ; pas distance parcourue AFK |
| Outils/interception | Dévier/interrompre/créer une ouverture puis conversion ; aucun gain au lancer dans le vide |
| Chakra/interactions | Infusion ou interaction qui change un état pertinent, usage de ressource et réponse adverse ; pas coût dépensé seul |
| Espace/contrôle | Forcer une réponse ou convertir un trajet/zone sous menace ; pas prétendre que toute absence adverse dans une zone prouve une décision forcée |

Global = apprentissage transversal, transférable entre ninjas. Les contextes air/sol/mur restent des facettes de Conversion, pas trois nouveaux arbres. Une maîtrise non pertinente pour un ninja (ex. infusion élémentaire pour Lee) ne devient jamais une taxe obligatoire : mapping de preuves par capacités, équivalents physiques ou absence de prérequis justifiée. Signature = compétence propre à **ce ninja** : géométrie FTG pour Minato, rythme/risque du corps pour Lee, maintien/rupture de distance pour Temari. Les affinités fixes `ChakraTuning.Masteries` restent un vocabulaire du kit, indépendant. Pas d’augmentation passive de puissance à chaque palier global ; la maîtrise autorise/atteste une option explicite selon la politique de mode.

### Mesurer fréquence + réussite + variété + contexte

Émettre des **événements sémantiques serveur**, après résolution : DefenseResolved, ConfirmedRoute, ReengageResolved, ToolInteractionResolved, ZoneInteractionResolved, TechniqueResolved, MatchEnded (noms proposés). Chaque preuve : matchId/round/exchange, eventId monotone, owner/target réels, fighter/build/ruleset versions, action/route, état avant/après, origine (joueur/bot/clone), ressource, menace/contexte et résultat. Réutiliser notamment le callback déjà présent `Brawler.event → match.onCombatEvent` en enrichissant son contexte ; le compteur seul n’est pas une preuve. Ajouter les événements de défense/objets aux points de vérité existants, pas un appel arbitraire par node.

Le réducteur retient par famille et contexte des **opportunités O**, succès qualifiés S, essais/contexts distincts et rencontres éligibles. Un palier exige conjointement un minimum d’opportunités, un taux S/O sur échantillon suffisant, plusieurs contextes et preuve de défi ; jamais S seul ni une seule réussite chanceuse. Utiliser une fenêtre récente bornée + certification persistante, pas une ratio à vie qui pénalise l’apprentissage. Échec n’annule pas la maîtrise certifiée ; patch de règle peut demander requalification explicite. Seuils chiffrés après télémétrie, pas “500 coups”.

Pour “Aérien II”, exemple de **contrat qualitatif** : confirmer un launcher, choisir une conversion permise et finir/revenir au neutral sans état bloqué, dans plusieurs opportunités où l’adversaire peut répondre ; combiner contrôle d’arrivée et conservation d’une ressource de sortie. La même route sur la même cible figée ne constitue pas plusieurs contextes.

Compter une preuve **une fois par échange et famille**, partager son poids si elle contribue à plusieurs critères ; les trois paumes d’un même contact, ticks de feu, contacts de clone et VFX ne doivent pas multiplier les gains. Actions sur clones peuvent prouver une réponse anti-proxy si une vraie menace existe ; jamais des victoires fictives sur des clones pour XP de match. Les décisions d’espace non observables doivent rester des proxies documentés, complétés par défis contrôlés ; ne pas inférer une intention humaine avec certitude.

### Anti-exploitation et Practice

- L’observation serveur exclut les auto-déclarations client. Événements match-bound, ID monotone, déduplication ; les outils Debug/QA n’accordent aucune progression.
- Refuser récompense de session annulée/AFK, mannequin passif, auto-dommage ou boucle sans menace. Amortir répétition de même action/contexte et même paire de joueurs, avec plafonds par échange/match et revue des anomalies ; ne pas punir automatiquement amis, foyers/IP ou joueurs très forts.
- Les bots/Practice peuvent enseigner et **certifier des épreuves avec variations/menaces réelles** ; distinguer source/force de preuve, empêcher reset/refill/script Debug de compter. XP économique de Practice libre non farmable. **USER DECISION REQUIRED :** les paliers avancés exigent-ils du PvP ou un défi IA suffit-il ? Recommandation : aucune obligation PvP pour apprendre, validation avancée par défi contrôlé ou duel éligible.
- Aucun anticheat ne garantit l’absence de collusion. Détection/rate limits + contexte et suivi du taux d’anomalies ; ne pas promettre “impossible à exploiter”. Expliquer au joueur les réussites utiles sans publier tous les seuils antifarm.
- Une maîtrise n’est jamais vendue, ni multipliée par boost XP, ni accordée par reçu d’achat. Les points et la preuve de pratique sont deux ressources indépendantes.
- Éviter le verrou circulaire : toute maîtrise requise par une option doit se prouver sans posséder cette option, notamment via base et prêt Practice.

## TOURNOI STANDARDISÉ

### Même arbre, droits temporaires différents

| Mode | Fighter autorisé | Nodes utilisables | Maîtrise | Puissance et prêt |
|---|---|---|---|---|
| Practice | Tous les fighters publiés | Catalogue d’essai validé | Essai libre ; certification séparée | Tout build légal du scénario ; rien acquis par simple prêt |
| Permanent / entraînement progression | Fighter possédé | Nodes acquis dans le profil | Prérequis réels | Catalogue acheté avec points gagnés, budget actif permanent dérivé côté serveur et plafonné par ruleset ; pas bonus “mastery level” implicite |
| Tournoi/ranked standard | **Fighter possédé**, vérifié serveur | Catalogue compétitif prêté, budget fixe | **Arbitrage ci-dessous** | Base même version, aucun crédit/level/stat permanent ajouté |
| Casual | Selon règle de file affichée | Permanent ou standard **explicite** | Selon cette règle | Ne pas mélanger silencieusement les deux formes |
| Futur Open roster | Prêt temporaire de fighters | Ruleset explicite | Selon événement | N’écrit jamais unlockedFighters permanent |

**USER DECISION REQUIRED — T1, accès aux nodes/masteries en tournoi.** Deux politiques cohérentes, pas à confondre :

- **Recommandation : catalogue compétitif et conditions de maîtrise prêtés à tous pour le fighter possédé.** La preuve personnelle reste un statut et condition de progression permanente ; le tournoi teste la compétence réelle avec accès égal aux options. Aucune certification de profil n’est écrite par ce prêt.
- Alternative : nodes avancés conditionnés aux maîtrises personnelles, malgré budget égal. Pas achetable directement, mais davantage de pratique donne davantage d’options de contre-build. C’est une compétition à accès progressif, **pas** une neutralisation complète de la progression. Il faut l’assumer explicitement plutôt que dire “budget égal donc aucune influence”.

Même prêter les maîtrises sans prêter les nodes permanents laisserait un avantage d’accès aux nodes : le choix T1 couvre **les deux**. Le roster possédé reste un filtre explicitement voulu ; accélérer son déblocage peut élargir les counterpicks. L’égalité promise porte sur les options du **même fighter/ruleset** ; égalité complète d’accès entre comptes n’est pas vraie. Pas besoin de rouvrir la décision du roster possédé, mais montrer cette limite au produit.

Standardisation ne signifie pas mêmes builds : le coût actif A ≤ budget B ; ancêtres inclus ; pas obligation de dépenser tout B. Choix/variantes verrouillés avant révélation adverse (ou format draft annoncé). Le build UI est un preset validé, pas un kit client. Le ruleset fixe le budget/versions pour tout le tournoi ; pas un patch entre deux rounds. Leaderboard/rating ultérieurs distincts de l’XP économique.

## PROGRESSION PERMANENTE

Compte : XP/étapes pour collection, accès roster et statut. Personnage : XP/points pour catalogue de styles ; maîtrise par preuves. Un même résultat éligible peut créditer compte + personnage, mais avec identifiant commun de déduplication et sources distinctes. Pas vingt monnaies ni achat aléatoire de puissance.

Niveau 1 dispose du kit entier de base et d’un preset recommandé sans points requis. Déblocages progressifs de nodes, respec gratuit hors file/match recommandé ; les nodes acquis gardent leur coût actif. Aucun point permanent injecté dans le kit tournoi. XP issue surtout de matchs terminés et apprentissages/étapes authentiques ; victoire comme bonus raisonnable, pas dégâts/combo longueur qui invite au farm. Courbes/récompenses calibrées sur temps de duel et rétention réels.

Pay-to-time futur : accélération XP ou accès direct à un fighter possible **selon décision commerciale à venir** ; pas de budget tournoi acheté, aucune maîtrise payée, ni variante premium exclusive. Les boosts doivent expliciter ce qu’ils accélèrent ; ils n’influencent ni certification ni match déjà verrouillé. Receipts autoritaires et idempotents seulement si vente ultérieure activée, aucun tarif dans cette proposition.

**USER DECISION REQUIRED — P1 :** sélection de départ et rythme d’accès aux personnages ; formule compte/personnage et respec ; limites de points et rythme XP. **USER DECISION REQUIRED — P2 :** conserver les budgets 50/80/100 comme formats distincts ou une seule file standard au lancement ? Recommandation : une seule file pour concentrer la population, nombre choisi après tests du pilote ; ni 6 ni 18 des exemples ne vaut décision live.

## UX JOUEUR

Le hub compact DEC-023 sert de contexte ; **Practice / Combattre / Mon prodige** accessibles immédiatement au menu et aux lieux correspondants. Ne pas attendre un grand hub 3D pour tester le flow.

- **Arbre :** trois branches visibles, quatre nodes par branche au pilote ; résumé du style, budget actif et trois premiers choix avant les descriptions détaillées. Focus d’un node = “ce que je peux faire”, démonstration, coût, prerequisite, contre-jeu, raison de blocage. Vue manette avec déplacement de focus explicite, pas vingt mini-boutons flottants.
- **Maîtrises :** six familles globales et la signature du fighter ; état I/II/III et “réussis dans un autre contexte”, plutôt qu’une pluie de +XP par hit. Explication concrète de la prochaine preuve et bouton “essayer en Practice”. Pas vingt barres simultanées au HUD de combat.
- **Build tournoi :** onglet clairement distinct “Budget prêté du tournoi”, base/points actifs/variantes résumés ; trois presets recommandés à essayer puis six slots proposés, nommables. Badge “prêt temporaire” ; ne pas laisser croire à un déblocage permanent. Si T1 est retenu, aucun node grisé à cause de son niveau permanent dans cet onglet.
- **Practice :** changer fighter/build et reset la situation sans requeue ; tester des contextes/contres, comparer avant/après. Essai ne crédite pas automatiquement le profil. Mode certification dédié signale quand les preuves comptent.
- **Premières heures :** premier prodige, tutoriel court, duel IA, choix libre ; introduire deux ou trois options à la fois dans l’apprentissage sans cacher un catalogue tournoi légal aux joueurs qui veulent l’éditer. Trois presets permettent de jouer tout de suite. Ne pas bloquer les duels sur la lecture de l’arbre.
- **Avant match :** fighter, ruleset/budget et résumé des variantes importantes ; pas argent dépensé ou niveau grindé comme indice de puissance. Règle de révélation identique pour les deux joueurs.
- **Sauvegarde/patch :** retour “enregistré / en attente / à revoir”, raisons spécifiques. Un preset invalide ne se transforme pas silencieusement en build de base.

## RISQUES TECHNIQUES

| Risque observé ou anticipé | Traitement proposé, sans patch ici |
|---|---|
| Couplage ProfileSchema → SkillBuilds.tree | Séparer validation du roster possédé et records de contenu ; profil V2 supporte fighter sans arbre publié sans admettre de node invalide. |
| Rang actuel réclame unlocked permanents | Politique de prêt serveur séparée ; deux politiques testées sur le même preset. Pas passer des droits client à admit. |
| Appels directs à apply() | API publique runtime = validate+compile ; apply interne ou assertion de contrat, jamais appelée depuis Remote. Audit des callsites à l’intégration. |
| Mutation des tables partagées | Copies profondes par kit et overlays d’attaque isolés ; ne pas écrire Attacks/Fighters/Techniques globalement au chargement d’un build. |
| Nouveaux nodes route/technique non expressibles | Extensions allowlist comportementales, IDs de techniques globalement uniques, fallback explicite et borne. Pas champs arbitraires ou script par node. Brawler.start clone actuellement Attacks[name] puis lit le profil : une future variante d’attaque doit se résoudre sur cette copie via le kit, pas écrire Attacks globalement. |
| Fields OPTIONAL/“wired” et tests de Major | Remplacer la simple heuristique “set sur absent” par contrat de capacité lu + scénario prouvé ; une variante peut modifier un comportement déjà présent. |
| Explosion des groupes exclusifs | maximalBuilds énumère des combinaisons ; borne sur groupes/choix, validations structurelles + sampling déterministe/invariants pour familles ; petite exploration exhaustive des prototypes seulement. |
| Ordre d’empilement implicite | Ordre de phases et writers incompatibles rejetés ; budget ne prouve pas l’absence d’interaction multiplicative. |
| Changements de base rendent nodes obsolètes | Tests base/niveau1, comparaison de capacité et migration ; ne pas remettre des fonctions de base derrière un verrou. |
| Events partiels/dupliqués (paumes, clones, ticks) | Ledger sémantique séparé du ring d’impacts/compteurs du tuto ; server dedupe et une preuve par famille/échange. |
| Maîtrise change la simulation en plein match | Prêt/profil figés avant match ; réducteur hors chemin critique de damage ; seules récompenses post-match mutent le profil. |
| Lease et profils pendant transfert | Host réel avec save/renew/release, non-yielding transforms ; arrêt sur perte de lease ; environnement test séparé et tests de rollback. |
| Petite population | Une file standard au pilote ; pas une file par combinaison de build/niveau/maîtrise ; MMR distinct de l’XP. |
| Future UI énorme | DTO public minimal, catalogue chargé par fighter, caches versionnés, pas d’envoi par snapshot de combat. |

## EXEMPLE CONCRET — TROIS PETITS ARBRES PROTOTYPES

**Exemples de design non implémentés**, six nodes par personnage, trois branches, coûts illustratifs 1 → 3. Pas les vingt arbres ; plusieurs choix nécessitent des handlers/animations nouveaux. Aucun pouvoir adulte ajouté implicitement. Les nodes n’ajoutent pas d’i-frame gratuite, de boucle ou de garantie de toucher. Chaque avancé requiert sa racine active et une preuve II proposée en permanent (T1 gouverne le tournoi).

### Rock Lee — engager, convertir, ressortir

Base conservée : routes LeafRising/Hurricane/Whirlwind, poursuite, Primary Lotus avec coût corporel et fallback, Deflect, rupture et Fifth Gate ; **pas de jutsu inventé**.

| Node | Coût/prérequis | Décision ajoutée | Contre-jeu / support |
|---|---|---|---|
| L-A1 Sortie circulaire | 1, racine | Après Hurricane confirmé, choisir sortie latérale au lieu de prolonger ; perdre le droit de follow-up direct | L’adversaire reprend espace ; nouveau slot route exit borné |
| L-A2 Crochet de reprise | 3, A1 + Mobilité II | Une reprise latérale payée sur l’ennemi encore en récupération, sans deuxième boucle de launcher | Garde/attente punit ; handler de reengage conditionnel et limite par échange |
| L-B1 Fin aérienne choisie | 1, racine | Depuis fenêtre Lotus, choisir un heel de sortie au lieu du Lotus payé en vie ; garde la signature Lotus disponible de base | Moins de conversion/pas de bounce ; variante de airFinisher existant à exposer |
| L-B2 Descente décalée | 3, B1 + Conversion II | Orienter cette sortie vers un côté du sol, plutôt que prolonger la frappe ; renoncer au follow-up | Lire réception, sortie défensive adverse conservée ; landing/finisher handler |
| L-C1 Déviation et retrait | 1, racine | Après vraie déviation, choisir retrait au lieu du dash gratuit déjà présent | Rend le neutral ; option remplace la fenêtre de pression |
| L-C2 Frein des Portes | 3, C1 + signature Lee II | Terminer volontairement l’éveil après une déviation : stop du drain, mais toutes fenêtres offensives d’éveil ferment et recovery lisible | Adversaire peut feinter la lame ; handler exit-awakening nouveau, pas réduction passive du coût |

Build exemple 6 : A1+A2+B1+C1. Lee choisit une reprise et conserve deux sorties simples ; il ne possède pas à la fois les trois conversions avancées. La maîtrise signature mesure une ouverture/pression puis désengagement viable **sans récompenser la perte de vie elle-même**. Chaque build doit respecter le fallback du Lotus à faible vie.

### Minato — préparer sa géométrie

Base conservée : marques corps/sol/en vol, FTG/choix d’angle, arrival strike/Rasengan, Wind Cut et éveil FlashWake/FlashPursuit. Rien ne verrouille la première téléportation.

| Node | Coût/prérequis | Décision ajoutée | Contre-jeu / support |
|---|---|---|---|
| M-A1 Rappel de kunai | 1, racine | Récupérer volontairement un ancrage posé pour recycler une petite ressource, au prix de perdre une destination | Spot visible ; adapter l’existant KunaiRecall, valeurs à retuner |
| M-A2 Retour conditionnel | 3, A1 + signature Géométrie II | Choix de conserver une marque de départ **hors éveil** après une arrivée sans attaque ; consomme la conversion immédiate | Destination visible, maximum de marques inchangé ; différencier du FlashWake gratuit de l’éveil |
| M-B1 Marque d’air alternative | 1, racine | Le side switch aérien peut marquer au lieu de sa récompense normale | Pas cumul ; correspond à AirSwitchSeal existant |
| M-B2 Sortie d’arrivée | 3, B1 + Conversion II | À arrivée aérienne, choisir lancer d’ancrage vers le sol au lieu de la frappe instantanée | Dépenser outil/chakra et sacrifier hit ; réutiliser le hook ArrivalThrow/AirExit |
| M-C1 Lecture de destination | 1, racine | Après parade réelle, placer une marque courte sur le corps plutôt que prendre la punition immédiate | Feintes/grab et marque qui expire ; adapter ParrySeal |
| M-C2 Cancel préparé | 3, C1 + Défense II | FTG annule une chaîne confirmée vers une marque existante, en payant chakra et marque | Blocage/substitution coupe ; StringFlash existant à comparer au kit courant |

Build exemple 6 : B1+B2+A1+C1. Le main prépare une sortie verticale et des opportunités, pas plus de HP. Plusieurs hooks existent déjà ; chaque recouvrement avec le kit V1 impose audit de non-régression avant conservation du node. Exemple M-A2 reste une **liberté gameplay à valider**, pas un fait canon.

### Temari — dessiner la distance

Base conservée : éventail/Gust, déviation de lames et interaction feu, couloirs/updraft, conversion à distance, pas de vent, plané et Kamatari. L’arbre ne débloque pas “son vent marche enfin”.

| Node | Coût/prérequis | Décision ajoutée | Contre-jeu / support |
|---|---|---|---|
| T-A1 Couloir oblique | 1, racine | Choisir une orientation latérale au lancement au lieu de l’axe direct, à aire/durée constantes | Montre direction ; paramètres de Zone/Gale nouveaux à borner |
| T-A2 Fermeture de couloir | 3, A1 + Contrôle II | Sacrifier un couloir existant pour une seule rafale de sortie ; coûts, zone restante et confirmation bornés | Plus de contrôle persistant, adversaire peut attendre ; handler consume-zone nouveau |
| T-B1 Rupture latérale | 1, racine | Après corps réellement repoussé, pas de vent latéral au lieu de retrait automatique | Trajet lisible, pas d’invulnérabilité ; reengage.reposition existant à étendre |
| T-B2 Reprise au sol | 3, B1 + Mobilité II | À l’atterrissage d’un plané, convertir en pas latéral payé ; interdit si hitstun/engagement adverse actif | Recovery et coût, pas cancel de punition ; hook landing nouveau |
| T-C1 Conversion basse | 1, racine | Après Updraft confirmé, choisir Gust descendant pour finir au sol au lieu du maintien aérien | Sacrifie la pression aérienne, wakeup conservée ; payoff Updraft à étendre |
| T-C2 Renvoi placé | 3, C1 + Outils II | Lors d’une vraie interception par Gust, orienter le renvoi vers un angle prédéfini au lieu du lanceur | Pas tracking garanti, même volume de lecture ; Combat.redirect réutilisé avec fenêtre/paramètres |

Build exemple 6 : A1+A2+B1+C1. Elle privilégie une sortie de zone contre la persistance, sans gagner de vent infini. Sa maîtrise signature vérifie des changements de distance sous pression et conversions depuis zone, pas des secondes AFK passées loin.

## PLAN D’IMPLÉMENTATION PAR ÉTAPES

**Aucune étape gameplay n’est autorisée par ce document.** Après validation de la proposition, l’insérer au bon moment de DEC-021 avec Claude ; ne pas interrompre les vingt V1 ni les passes post-roster déjà ordonnées.

1. **Arbitrer T1/P1/P2 et certifier les bases.** Fixer la politique de prêt, le ruleset pilote et les responsabilités ; grille niveau1 sur le roster courant, puis vingt. Gate : aucune signature confisquée par un node.
2. **Adapter schéma/compilateur sur les trois pilotes seulement.** Réutiliser SkillBuilds, allowlist typée, héritage des IDs, variantes/exclusivités, conflits de writers, versions. Gate : DAG, ancêtres, coût, bornes, déterminisme, base immuable ; zéro profil live modifié.
3. **Prototyper les trois mini-arbres et leur présentation en Practice isolée.** Minimum de handlers démontrés, garder les autres nodes data-only/inaccessibles. Gate Studio : vraie sélection/inputs, avant/après, contre-jeu, IA et cleanup ; pas “wired=true” comme seul critère.
4. **Brancher les événements de maîtrise en observation seule.** Aucun droit ni récompense au début ; replay déterministe, déduplication paumes/clones/zones, tests collusion/repeat/reset/AFK et coût CPU. Gate : événements utiles et seuils discutés à partir de données réelles.
5. **Versionner et migrer les profils en DEV.** Host de lease/save/close, XP/unlocks/presets séparés par mode, journal de résultats. Gate : retry avant/après commit, callbacks répétés, perte de lease, deux serveurs, profil futur/corrompu, preset retiré, crash/rollback. Aucun wipe/remboursement inventé.
6. **Intégrer le tournoi prêté dans Online.** Choix de fighter possédé, preset standard, budget/versions figés, round/rematch/disconnect ; tests T1 avec comptes progression différente. Gate : deux clients Studio puis véritable expérience Roblox publiée selon NET-001/REL-001 ; aucun surcroît de pouvoir depuis XP/achat/maîtrise prêtée.
7. **Activer certification et UX guidée au pilote.** Étudier la frustration, prouver une mastery requise sans node verrouillé, presets simples et raisons de refus. Gate : parcours d’un nouveau joueur, un main et une manette réelle ; temps jusqu’au premier combat mesuré.
8. **Étendre horizontalement par familles vers vingt.** Quatre ou cinq fighters par lot en réutilisant les motifs démontrés, pas vingt conceptions indépendantes. Gate par lot : identité/conversions, choix de build réellement distincts, absence de build dominant manifeste ; pas promesse de “balance prouvée” par IA.

Rester derrière des flags serveur distincts catalogue/observation/récompenses/profils/tournoi ; rollback conserve les profils V2 ou empêche un ancien serveur de les écrire. Une activation produit n’active pas la boutique. Chaque grande étape a ses sorties et un arrêt de synchronisation ; pas les huit en parallèle.

## CE QU’IL NE FAUT SURTOUT PAS FAIRE

- Réparer un kit incomplet par ses nodes ; vendre le FTG de base, le Lotus de base ou la portée tactique de Temari.
- Assimiler le “Mastery” statique de ChakraTuning à la preuve de compétence du joueur.
- Ajouter une classe de personnage, un contrôleur ou une langue de script par arbre ; écrire des if fighterId dans chaque hook central.
- Retirer les bornes de SkillBuilds pour faire passer des petits arbres ; adapter ses invariants avec tests, pas les contourner.
- Laisser le client choisir points, droits, budget, XP, maîtrise ou résultat ; faire confiance à un preset sauvegardé sans le revalider.
- Appliquer des buffs permanents en tournoi ou croire que budget égal = mêmes options si nodes/masteries sont encore grind-gatés.
- Récompenser dégâts bruts, auto-dommage, spam d’outil ou 500 répétitions ; écrire DataStore sur chaque coup.
- Enregistrer kits dérivés/closures ou rejouer des gains à partir des effets visuels ; transmettre le profil par TeleportData comme autorité.
- Renommer des IDs, réduire les presets existants ou refuser un profil complet pour un node retiré sans migration explicite.
- Appeler des mocks un tournoi online, les mesures IA une preuve de balance humaine ou cet audit une validation Studio.
- Construire maintenant vingt arbres complets, le hub final, la boutique ou une refonte réseau ; cette mission prépare la phase suivante.

## Références Roblox vérifiées

Consultées le 17 octobre 2026 ; elles guident les adaptations futures, ne prouvent pas le fonctionnement du repo.

- [Data stores](https://create.roblox.com/docs/cloud-services/data-stores) : persistance côté serveur ; appels sujets à échec ; UpdateAsync sans yield dans son callback ; éviter que Studio touche les données live.
- [Memory stores](https://create.roblox.com/docs/cloud-services/memory-stores) : données temporaires fréquentes, utiles à une future coordination de matchmaking ; pas remplacement de la progression durable.
- [Frontière client/serveur](https://create.roblox.com/docs/scripting/security/client-server-boundary) : validation serveur des requêtes, contexte et limites, pas confiance dans des données de progression déclarées par le client.
- [Developer products](https://create.roblox.com/docs/production/monetization/developer-products) : traitement serveur des achats/reçus pour une future monétisation, sans vente activée par cette proposition.
