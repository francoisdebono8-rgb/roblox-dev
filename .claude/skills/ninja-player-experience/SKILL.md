---
name: ninja-player-experience
description: Évaluer et améliorer le plaisir de jouer à Ninja Duel, la sensation de ninja, les déplacements, le combat, les animations, la caméra et les premières minutes. Utiliser pour les playtests, les audits de gameplay et les modifications susceptibles de changer le ressenti joueur.
---

## Exécution dans Ninja Duel

Charger `games/ninja-duel/CLAUDE_START_HERE.md`, les sources actives pertinentes et `docs/tools/RUNBOOK_4_DISCUSSIONS.md` depuis le checkout courant. Les quatre discussions sont DEV, CM, ANIMATEUR et OUTILLEUR ; elles se transmettent le travail par Git et les sources actives, pas par mémoire partagée. Respecter leurs périmètres de fichiers. Ne pas supposer que `main` ou une branche datée est la référence : comparer HEAD, checkpoint et décisions.

Pour une demande de réalisation, aller jusqu'au résultat dans le périmètre autorisé : reproduire ou capturer le départ, modifier les vrais fichiers, construire, déclencher l'action dans Studio, regarder le résultat en mouvement, corriger les défauts restants de la demande et rejouer le build final. Ne pas s'arrêter à un diagnostic, une fiche ou un plan lorsque l'utilisateur demande une réalisation. Pour une demande de conseil, répondre sans modifier le jeu.

Réutiliser les profils du même commit : ND-JEU (parcours joueur sans outils), ND-DEV (diagnostic), ND-QA (batterie native), ND-FILM (capture). Le Mac est organisé sous `~/Documents/NinjaDuel/` ; l'actualisation existante est `_outils/actualiser_places.sh`. Respecter les locks et la place occupée par une autre discussion ; employer LAB/repro si nécessaire. Un essai à chaud n'est livré qu'après report dans les sources, reconstruction et observation du résultat final. Vérifier la ligne BUILD/RUNTIME/profil/commit de la place utilisée.

Lire les commandes courantes dans `tools/studio/README.md`, `docs/tools/DEVTOOLS.md`, `docs/tools/OUTIL_VISUEL_F7.md` et, pour filmer, `docs/tools/OUTIL_TOURNAGE_F4.md` et `tools/capture/README.md` (chemins relatifs à games/ninja-duel). Piloter les outils déjà configurés ; ne pas demander à François de découvrir ou lancer ce que la session peut faire. En cas de blocage, tenter les solutions existantes dans ce périmètre puis décrire le blocage précis ; ne jamais inventer une observation.

Mettre les faits dans CURRENT_STATE, les tâches dans MASTER_BACKLOG et les transmissions dans SINCE_LAST_CLAUDE selon EXECUTION_RULES. Conserver les catégories TECHNICAL/NATIVE_STUDIO/HUMAN_VISUAL_FEEL/LIVE_ROBLOX : une observation par Claude n'est pas l'avis humain de François. Pas de second backlog ni de rapport autonome systématique. Tests et isolation pertinents obligatoires selon les règles actives ; ne pas affaiblir un test pour obtenir PASS. L'installation ne lance aucun de ces travaux : les déclencher seulement au cours des demandes utilisateur pertinentes.

## Produire une amélioration visible avec les outils existants

1. Reproduire le défaut précis dans ND-DEV. Utiliser F6 pour une mise en situation (`neutral`, `launcher`, `air`, `wall`, `whiff`, etc.), puis fermer le panneau et rejouer avec les vraies commandes. Une situation qui place les acteurs après le lancement ne prouve pas la chaîne d'inputs.
2. Pour la mesure, réutiliser selon le symptôme `tools/studio/probes/snaps.luau`, `measure_movement.luau`, `intentrec.luau`, `seqrec.luau`, ou les drivers `tools/studio/input_matrix.py` et `tools/studio/fighter_check.py` après lecture de leur interface actuelle. Réutiliser F6/profile pour les saccades et F7 pour isoler lumière/effets ; ne pas reconstruire une instrumentation équivalente.
3. Relier le défaut au contrat réel : serveur Combat/Brawler/Motor pour trajectoire, contacts et contrôle ; client Camera/Presentation/BodyViews/VelmoraMotionEngine pour leur représentation ; clips et FX à l'ANIMATEUR. Faire le changement dans les fichiers de son rôle. Un besoin hors de ce rôle passe par une demande ciblée `besoin-dev` ou `besoin-animateur` avec build, instant et résultat voulu.
4. Rejouer la même action au même endroit avec les mêmes personnages. Si le symptôme a disparu mais qu'un autre défaut induit empêche l'action demandée, le corriger dans le même périmètre. Ne pas annoncer « plus fluide » sans expliquer ce qui a effectivement changé à l'écran.
5. Refaire le parcours dans ND-JEU pour vérifier qu'il fonctionne sans commandes debug. Livrer le changement concret, une preuve avant/après consultable et la limite restante. Préférer quelques secondes montrant le gain à une longue liste de paramètres.

Exemple de raisonnement applicable : si une attaque semble traverser un corps, distinguer orientation, distance de contact, pose du bras et réaction de la victime ; corriger la cause constatée au lieu d'ajouter un flash qui dissimule le contact.

# Intention

Viser « je maîtrise un ninja » et « les combats sont trop stylés ». Faire provenir cette sensation des actions et de leurs conséquences : mobilité contrôlable, esquive, anticipation, impact, ruse, maîtrise et possibilité de reprendre l'avantage. Ne pas réduire cette intention à davantage de particules, de vitesse ou de tremblements de caméra.

## Reprendre le contexte réel

1. Lire les instructions du dépôt, les rôles existants et les décisions créatives récentes. Identifier les responsabilités effectives sans inventer le quatrième rôle ni créer une nouvelle organisation.
2. Relever la version/branche, les commandes, les mécaniques effectivement présentes, les plateformes visées et les moyens de test. Marquer toute donnée absente comme inconnue.
3. Choisir un parcours représentatif de jeu actuel. Réutiliser les outils de lancement et capture du projet. Si l'accès Studio échoue, tenter de rétablir le circuit existant ; n'utiliser l'audit seul comme repli qu'après un blocage précis documenté.

## Séparer les preuves

Attribuer chaque constat à une catégorie :
- Observé en jeu : session et scénario identifiés, capture ou horodatage si disponible.
- Mesuré : méthode, unité, environnement et échantillon explicités.
- Déduit du code : chemin et symbole pertinents ; effet visuel ou ressenti encore à confirmer.
- Retour joueur : propos ou comportement réellement recueilli, avec contexte anonymisé.
- Hypothèse : effet attendu à tester.

Ne pas convertir une appréciation de l'agent en préférence humaine vérifiée. Ne pas inventer de mesures de latence, rétention, satisfaction ou réactions de joueurs. Présenter les seuils proposés comme des objectifs de test.

## Tester une séquence plutôt qu'une liste de fonctionnalités

Utiliser les scénarios pertinents parmi ceux-ci ; signaler les mécaniques absentes sans les transformer automatiquement en demandes de développement.

| Scénario | Questions à vérifier |
| --- | --- |
| Première arrivée, puis première minute de contrôle | Comprendre quoi faire et comment agir sans connaître le dépôt ? Atteindre rapidement une action plaisante ? |
| Traverser une zone, changer de direction, sauter puis atterrir | Contrôler trajectoire et caméra ? Lire l'élan et l'atterrissage ? Éviter de glisser ou de subir une animation ? |
| Approcher, frapper, manquer, subir un coup | Distinguer portée, réussite et échec ? Relier son entrée à une conséquence visible ? |
| Esquiver ou contrer, puis riposter si disponible | Comprendre le timing et la fenêtre de réponse ? Identifier ce qui dépend de sa maîtrise ? |
| Perdre un duel puis rejouer | Comprendre pourquoi on a perdu ? Avoir une action concrète à essayer ensuite ? |
| Combat près d'un mur ou d'un obstacle | Conserver visibilité, contrôle et lecture des adversaires ? |
| Même séquence sur appareil ciblé | Lire l'action à taille réelle ? Utiliser les commandes sans masquer les informations utiles ? |

Pour un duel réel, utiliser deux joueurs/clients si l'environnement le permet. Un mannequin peut vérifier une animation ou un impact, pas la tension d'un duel ni l'équilibrage humain.

## Observer les liens entre technique et émotion

- Mobilité : la liberté perçue vient des choix de trajectoire et de timing. Vérifier orientation, accélération, inertie, réception, transitions et contrôle aérien avant d'augmenter la vitesse.
- Animation : examiner intention, préparation, contact et récupération, synchronisés à la mécanique réelle. Examiner pieds, appuis, poses et changements de direction. Une animation élégante mais déconnectée du contrôle peut détériorer le plaisir.
- Combat : garder lisibles menace, réponse possible, contact et conséquence. Préserver un contre-jeu et des règles cohérentes.
- Caméra et son : servir l'information et l'impact. Tester si un effet spectaculaire masque l'adversaire ou empêche de viser.
- Émotion : distinguer excitation, maîtrise, surprise et frustration ; préciser le comportement observé qui motive l'interprétation.
- Relation entre joueurs : favoriser rivalité et revanche compréhensibles, expression personnelle et admiration du beau geste. Ne pas supposer que l'humiliation ou le spam crée une communauté.

## Prioriser et vérifier

Décrire chaque problème sous la forme : situation → observation → conséquence probable pour le joueur → changement minimal → test.

Classer au maximum trois actions selon impact attendu, solidité des preuves et coût. Traiter d'abord les blocages de contrôle et de compréhension. Ne pas ajouter une mécanique simplement parce qu'elle est courante dans un autre jeu.

Si une modification est autorisée, garder un avant/après sur le même scénario, appareil, caméra et conditions. Comparer compréhension, contrôle et lisibilité, ainsi que le rendu. Exécuter les vérifications techniques pertinentes. Conserver la possibilité de revenir au réglage précédent.

Pour vérifier l'attrait humain, proposer un test exploratoire court avec quelques joueurs consentants, dont des nouveaux : donner un objectif sans expliquer les commandes, observer hésitations et choix, puis demander « Qu'est-ce que tu pensais pouvoir faire ? », « Pourquoi as-tu perdu ? » et « Qu'as-tu envie de retenter ? ». Un petit échantillon donne des pistes, pas une preuve de rétention.

## Travailler avec les rôles existants

Transmettre au développeur les règles, transitions et critères mesurables ; transmettre à l'animateur les poses, appuis, rythme et raccords à vérifier. Donner à chacun le même scénario et les mêmes preuves. Vérifier ensemble le résultat en jeu : une animation réussie isolément ne suffit pas.

## Livrer

Résumer les conditions réellement testées, le verdict actuel sur la sensation de ninja, au maximum trois constats prioritaires avec preuve, et les actions à vérifier. Signaler clairement ce qui reste inconnu. Éviter les notes chiffrées sans critères et les compliments sans preuve.
