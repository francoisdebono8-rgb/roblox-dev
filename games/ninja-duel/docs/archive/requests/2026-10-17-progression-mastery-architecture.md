# Demande utilisateur — préparation architecture progression et maîtrises

Texte intégral reçu le 17 octobre 2026. Préparation pour la phase suivante ; aucune implémentation gameplay autorisée avant validation.

Tu travailles sur le repo francoisdebono8-rgb/roblox-dev, projet games/ninja-duel/.
Contexte important
Le jeu est maintenant pensé comme un arena fighter 3D ninja centré sur un roster initial de 20 jeunes prodiges. Les 20 personnages actuels sont encore des V1 : chacun doit déjà être reconnaissable, fun et fidèle à sa logique de combat, mais ils ne représentent pas encore leur profondeur finale.
La prochaine grande couche de profondeur du jeu sera composée de deux systèmes complémentaires :
1. Arbre de compétences propre à chaque personnage
2. Maîtrises acquises par la pratique réelle
L’objectif produit est :
choisir son prodige → le jouer → apprendre son kit → progresser dans son arbre → développer des maîtrises → créer plusieurs builds → participer à des tournois standardisés où tout le monde dispose du même budget de points.
Le joueur pourra débloquer progressivement les différents personnages sur son compte. Dans le mode compétitif principal, il ne pourra jouer que les personnages qu’il a débloqués, mais leur progression permanente ne donnera pas un avantage numérique : chaque tournoi attribuera par exemple un budget temporaire de X points de compétences, identique pour tous.
Ainsi, un joueur expérimenté est avantagé parce qu’il connaît mieux le personnage, son arbre, ses synergies et ses matchups, pas parce qu’il possède plus de statistiques.
Principe fondamental : niveau 1 = identité complète, profondeur incomplète.
Un personnage niveau 1 doit déjà être amusant et donner immédiatement son fantasme principal. Minato doit déjà pouvoir penser en marques / angles / téléportation ; Lee doit déjà être un vrai combattant taijutsu ; Temari doit déjà contrôler la distance avec le vent, etc.
L’arbre ne doit jamais servir à “réparer” un personnage incomplet. Il doit ouvrir :
- variantes de routes/combo ;
- nouvelles possibilités de déplacement ;
- cancels ;
- transformations de techniques existantes ;
- interactions chakra/outils ;
- choix offensifs/défensifs ;
- spécialisations de style ;
- options contextuelles ;
- éventuellement nouvelles techniques lorsque c’est cohérent.
Éviter autant que possible les nœuds du type +5 % dégâts, +3 % vitesse, -0,5 s cooldown lorsqu’ils ne créent aucune décision intéressante.
Maîtrise
La maîtrise ne doit pas être un second arbre d’XP classique.
Elle doit provenir de ce que le joueur réussit réellement dans le gameplay : conversions aériennes propres, défense réussie, utilisation intelligente des outils, interruptions, chakra, contrôle de zone, mobilité, techniques spécifiques, etc.
Le jeu ne doit pas encourager des tâches absurdes du type “répète 500 fois la même attaque”.
Une maîtrise doit plutôt mesurer fréquence + réussite + variété + contexte.
Certaines branches de l’arbre pourraient demander à la fois :
N points + Maîtrise X niveau Y
Exemple :
3 points + Maîtrise aérienne II
Le joueur peut donc acheter/débloquer du contenu plus vite avec du pay-to-time plus tard, mais il ne peut pas acheter la preuve qu’il maîtrise réellement une mécanique.
Expérience joueur décidée
Le jeu n’est pas destiné à devenir un RPG Roblox classique.
Il y aura à terme un hub compact de tournoi de jeunes prodiges, inspiré de l’ambiance d’une salle/examen précédant un grand tournoi :
- accès rapide au combat ;
- zone Practice ;
- tournoi / ranked / casual ;
- progression / arbres / maîtrises ;
- roster ;
- leaderboard ;
- profils ;
- éventuellement boutique/cosmétiques plus tard.
Pas de grande ville vide, pas de quêtes “tue 5 bandits”, pas de déplacements inutiles.
Le joueur expérimenté doit pouvoir lancer le jeu et combattre en quelques dizaines de secondes.
Ta mission
Ne code PAS encore l’ensemble du système.
Commence par auditer sérieusement le HEAD actuel et les docs actives du projet.
Lis au minimum :
- CLAUDE_START_HERE.md
- docs/active/VISION.md
- docs/active/DECISIONS.md
- docs/active/CURRENT_STATE.md
- docs/active/MASTER_BACKLOG.md
- docs/active/ENGINEERING_REVIEW.md
- les fichiers progression/skills déjà existants dans le runtime
- les définitions des combattants, MoveGraphs, Families, Chakra, techniques, awakening, progression et online existants.
Vérifie ce qui existe réellement aujourd’hui avant de proposer quoi que ce soit.
Je veux ensuite une proposition architecturale complète pour :
1. le modèle d’arbre générique
   - structure d’un node ;
   - prérequis ;
   - coût ;
   - exclusivité éventuelle ;
   - branches ;
   - modifications de moves/routes/techniques ;
   - sauvegarde ;
   - application runtime ;
   - compatibilité avec le serveur autoritaire.
2. les maîtrises
   - quelles familles de maîtrise doivent exister ;
   - lesquelles sont globales vs propres au personnage ;
   - comment les mesurer sans encourager le spam ;
   - comment éviter l’exploitation ;
   - comment elles interagissent avec les arbres.
3. le niveau 1 des personnages
   - définir ce qui doit toujours être disponible au niveau 1 ;
   - distinguer identité fondamentale vs profondeur déblocable ;
   - proposer une règle commune pour les 20.
4. les builds tournoi
   - même arbre que la progression permanente ;
   - budget standardisé temporaire ;
   - seulement personnages débloqués sur le compte ;
   - plusieurs presets sauvegardés par personnage ;
   - aucune puissance achetable en tournoi ;
   - prévoir plus tard des événements “open roster” possibles.
5. la progression permanente
   - XP / points / déblocage des personnages ;
   - relation entre progression compte et progression personnage ;
   - espace pour du pay-to-time sans pay-to-win ;
   - compatibilité avec DataStore et online.
6. l’interface et l’expérience
   - comment le joueur consulte son arbre ;
   - comment on montre les maîtrises ;
   - comment on construit un build tournoi ;
   - comment éviter une UI énorme et incompréhensible ;
   - comment rendre les premières heures accessibles.
7. l’architecture technique
   - ce qui peut être data-driven ;
   - ce qui doit rester dans Combat/Brawler/Families ;
   - quels hooks génériques sont nécessaires ;
   - comment éviter d’ajouter du code spécial pour chacun des 20 personnages ;
   - risques de dette technique avec les systèmes actuels.
8. la stratégie de contenu
   - taille recommandée d’un arbre initial ;
   - nombre de branches ;
   - combien de nœuds doivent réellement modifier le gameplay ;
   - combien de maîtrises sont nécessaires ;
   - comment construire 20 arbres sans rendre le projet infaisable.
Je veux particulièrement que tu répondes à cette question :
comment rendre les arbres suffisamment profonds pour que “main Rock Lee” ou “main Minato” ait un vrai sens, sans transformer le développement en 20 jeux différents impossibles à maintenir ?
Livrable
Fais d’abord un audit de l’existant, puis une proposition.
Je veux :
- EXISTANT RÉUTILISABLE
- MANQUES
- ARCHITECTURE PROPOSÉE
- MODÈLE DE DONNÉES
- RÈGLES DE DESIGN DES ARBRES
- RÈGLES DE MAÎTRISE
- TOURNOI STANDARDISÉ
- UX JOUEUR
- RISQUES TECHNIQUES
- EXEMPLE CONCRET sur 3 personnages très différents (par exemple Rock Lee, Minato, Temari) avec un petit arbre prototype pour chacun
- PLAN D’IMPLÉMENTATION PAR ÉTAPES
- CE QU’IL NE FAUT SURTOUT PAS FAIRE
Ne fais pas 20 arbres complets maintenant.
Le but de cette mission est de définir le système qui permettra ensuite de construire les 20 correctement.
Ne casse pas la roadmap actuelle : le roster V1 des 20 reste prioritaire côté Claude. Cette mission Codex est une préparation architecturale pour la phase suivante.
Si tu identifies des décisions qui doivent être arbitrées par l’utilisateur, marque-les clairement USER DECISION REQUIRED au lieu de choisir arbitrairement.
Ne modifie aucun gameplay runtime tant que la proposition n’a pas été validée.