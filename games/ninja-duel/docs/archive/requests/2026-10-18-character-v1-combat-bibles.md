# Brief intégral utilisateur — Combat Bibles V1 — 18 octobre 2026

Source : pièce jointe remise dans ce chat. Remplace explicitement le roster et la définition de V1 antérieurs pour le design ; aucune implémentation runtime par Codex. Décision opérationnelle DEC-026, tâches MASTER_BACKLOG, bibles docs/characters.

Oui. Pour Codex, je lui donnerais une mission de design pure, pas d’implémentation. Le but est qu’il nous prépare les 20 vraies V1 personnage avant que Claude fasse la grosse passe d’identité.
Envoie-lui ça :
Tu travailles sur francoisdebono8-rgb/roblox-dev, projet games/ninja-duel/.
Mission : écrire les 20 Character V1 Combat Bibles.
Ne code aucun gameplay dans cette mission.
Nous redéfinissons officiellement ce qu’est une V1 personnage.
Jusqu’ici, plusieurs combattants sont techniquement jouables mais partagent encore trop :
- les mêmes gestes ;
- les mêmes Light chains ;
- les mêmes launchers ;
- les mêmes animations génériques ;
- les mêmes réactions ;
- des armes utilisées seulement comme VFX de techniques ;
- une identité surtout portée par les jutsus plutôt que par le corps entier du personnage.
Cela n’est plus suffisant.
DÉFINITION DE V1 PERSONNAGE
V1 personnage = identité complète à travers le corps, les mouvements, les animations, les combos, les armes naturelles/physiques et les capacités signatures fondamentales.
Une V1 n’inclut PAS encore :
- arbre de compétences complet ;
- maîtrise joueur ;
- système chakra global final ;
- système armes global final ;
- sound design final ;
- VFX final ;
- équilibrage compétitif final.
Ces systèmes viendront après.
En revanche, après la V1 personnage, on doit pouvoir cacher le HUD et reconnaître le combattant en quelques secondes simplement par sa manière de bouger et combattre.
ROSTER À DESIGNER
Travaille sur ces 20 prodiges :
1. Itachi
2. Shisui
3. Sasuke
4. Madara enfant
5. Hashirama enfant
6. Hiruzen enfant
7. Minato
8. Kakashi
9. Naruto
10. Gaara
11. Rock Lee
12. Neji
13. Haku
14. Kimimaro
15. Nagato
16. Orochimaru
17. Sasori
18. Deidara
19. Killer Bee
20. Zabuza
Concept lore :
Ils représentent de grands prodiges de différentes générations, comparés autour du même stade de vie, environ 12–14 ans, avec extrapolation raisonnable lorsque leur enfance est peu documentée.
Canon principal d’abord, puis anime/novels/databooks/statements, puis extrapolation fan cohérente.
Ne donne jamais automatiquement au personnage tout son arsenal adulte.
Madara enfant n’est pas Madara EMS/Rinnegan.
Hashirama enfant n’est pas le dieu shinobi de sa prime.
Hiruzen enfant n’a pas nécessairement déjà maîtrisé chaque jutsu de Konoha.
Mais ne fais pas non plus l’erreur inverse : ce sont des prodiges. Leur version enfant doit déjà avoir une identité impressionnante et crédible.
OBJECTIF CENTRAL
Les 20 ne doivent PAS être le même combattant avec trois jutsus différents.
Les moteurs et systèmes techniques doivent rester communs, mais leur expression visible doit être radicalement différente.
Deux personnages peuvent utiliser le même système de Light / Heavy / Forward / Side / Air, mais les animations, rythmes, distances, intentions et transitions doivent raconter leur personnalité.
Pas :
jab → jab → kick × 20.
POUR CHAQUE PERSONNAGE, ÉCRIS UNE FICHE V1 COMPLÈTE
1. Combat identity
Une phrase qui décrit exactement ce que le joueur doit ressentir.
Exemple :
Minato = préparer une destination, disparaître, reprendre un angle et continuer avant que l'adversaire puisse remettre le combat à zéro.
2. Silhouette corporelle
Décrire précisément :
- idle ;
- position des bras/jambes ;
- centre de gravité ;
- déplacement avant/arrière ;
- strafe ;
- sprint ;
- dash ;
- saut ;
- chute ;
- landing ;
- garde ;
- esquive ;
- réaction légère/lourde ;
- knockdown/get-up.
Il faut pouvoir reconnaître le personnage sans technique.
3. Light chain
Décrire chaque hit physiquement.
Pour chaque Light :
- membre/arme utilisé ;
- direction ;
- déplacement du corps ;
- distance ;
- rythme ;
- intention.
Les combos doivent être propres au personnage.
4. Branches de combo
Définir :
- Forward route ;
- Side route ;
- Away route ;
- Air route ;
- launcher ;
- air continuation ;
- finisher ;
- éventuellement wall route si pertinente.
Respecter notre invariant :
aucune branche directionnelle spéciale avant le premier hit confirmé.
Avant confirmation, Light reste le Light normal quelle que soit la direction tenue.
5. Heavy
Décrire son vrai Heavy propre.
Pas un uppercut générique pour tout le monde.
Il peut utiliser poids du corps, arme, pouvoir physique, marionnette, os, vent, etc.
6. Défense
Décrire comment ce personnage :
- bloque ;
- esquive ;
- contre ;
- reprend le neutral ;
- éventuellement substitue.
La défense peut elle aussi participer à l’identité.
7. Armes intégrées au corps-à-corps
Très important.
Une arme ne doit pas uniquement apparaître pendant un jutsu.
Si l’arme est fondamentale au personnage, elle doit influencer sa grammaire normale de combat.
Exemples impératifs :
Killer Bee
- véritable kenjutsu multi-lames ;
- utilise plusieurs sabres simultanément ;
- lames dans mains, coudes, jambes/angles inhabituels ;
- changements de configuration pendant les chaînes ;
- rythme imprévisible ;
- certains Lights doivent déjà être impossibles à confondre avec un sabreur classique.
Zabuza
- Kubikiribōchō doit être centrale ;
- inertie ;
- arcs larges ;
- portée importante ;
- utilisation du manche/poignée à courte distance ;
- repositionnement de la lame ;
- poids du corps ;
- garde avec l’arme ;
- la brume vient ensuite renforcer ce style d’assassin lourd.
8. Pouvoirs intégrés aux gestes
Même principe : ne pas séparer artificiellement “combo normal” et “super pouvoir”.
Kimimaro
Il ne doit surtout pas ressembler à un Jedi avec une épée blanche.
Son fantasme :
son squelette fabrique ses armes pendant ses mouvements.
Exemples :
- direct → os/phalanges prolongent l’impact ;
- garde → radius/ulna sortent comme protection ;
- spinning kick → pointes osseuses apparaissent pendant la rotation ;
- coude → excroissance osseuse ;
- réaction défensive → côtes/épines brièvement exposées ;
- seulement certaines techniques extraient réellement un os long pour en faire une lame.
Haku
Ne pas faire un simple mage à projectiles de glace.
- déplacements fluides ;
- senbon ;
- petits pics utilisés dans les transitions ;
- glace créée pendant la mobilité ;
- miroirs comme points de déplacement/angles ;
- combinaison corps + senbon + repositionnement.
9. Signature abilities
Identifier seulement les techniques vraiment nécessaires à la V1.
Elles doivent compléter la boucle du personnage, pas la remplacer.
Pour chacune :
- activation ;
- comportement ;
- mouvement du corps ;
- usage tactique ;
- contre-jeu ;
- possibilité de conversion.
10. Awakening / état spécial
S’il existe :
expliquer quelle règle du personnage change.
Pas simplement :
+20 % dégâts.
11. Animation language
Donner 5–10 règles simples qu’un animateur/Claude doit respecter.
Exemple Itachi :
- peu de mouvements inutiles ;
- économie gestuelle ;
- esquives courtes ;
- mains disponibles pour shuriken ;
- pose calme après frappe ;
- déplacements qui donnent l’impression qu’il avait déjà prévu la réponse.
Exemple Lee :
- transfert de poids clair ;
- forte extension hanche/épaule ;
- pas d’effets “magiques” dans les mouvements normaux ;
- récupération physique rapide ;
- posture toujours prête à repartir.
12. Hooks futurs
Décrire ce que les systèmes ultérieurs pourront enrichir :
- chakra ;
- nature élémentaire ;
- outils ;
- armes ;
- arbre ;
- maîtrise.
Ne les implémente pas dans la V1.
Il faut simplement éviter que le design V1 rende ces futurs systèmes impossibles.
IDENTITÉS IMPORTANTES À RESPECTER
En particulier :
Sasori
Sasori ne doit pas faire tout le combo avec son propre corps.
Sa marionnette doit pouvoir entrer dans les Light chains :
Sasori → puppet → repositionnement fils → attaque croisée.
On doit sentir qu’on contrôle deux corps avec un cerveau.
Deidara
Son corps-à-corps sert surtout à :
- repousser ;
- créer de l’espace ;
- poser de l’argile ;
- préparer le prochain explosif.
Un mouvement défensif peut laisser une petite création.
Une paume peut préparer une charge.
Il ne doit jamais ressembler à Lee avec des bombes ajoutées.
Nagato
Gestuelle minimale.
Paumes, mains ouvertes, petits déplacements.
Attraction/répulsion peut déjà participer aux transitions.
Il doit donner l’impression de manipuler les forces du combat plutôt que d’être un brawler.
Shisui
Shunshin partout dans son langage corporel :
- dash ;
- dodge ;
- transition de combo ;
- pursuit ;
- finisher.
Il ne doit pas avoir “combo générique + bouton téléportation”.
Gaara
Ne doit toujours pas devenir un brawler.
Son corps peut rester relativement calme pendant que le sable agit.
Naruto
Les clones doivent pouvoir participer naturellement aux routes et transitions plutôt que n’être que des capacités séparées.
LIVRABLE
Crée une Combat Bible V1 pour chacun des 20 personnages.
Elles doivent être assez précises pour que Claude puisse ensuite prendre une fiche et implémenter le personnage sans devoir redécider son design.
Je veux un niveau de précision proche d’une fiche d’animation / chorégraphie.
Pas seulement :
Bee : multi swords, fast
mais quelque chose comme :
Light 1 : lame main droite diagonale hanche → épaule ; léger pas intérieur
Light 2 : rotation inverse, lame coincée sous coude gauche ; attaque depuis angle inhabituel
etc.
CONTRAINTES
- audit d’abord ce que les 20 font actuellement ;
- réutiliser ce qui fonctionne déjà ;
- ne pas inventer un deuxième moteur ;
- signaler ce qui peut rester commun techniquement malgré des animations différentes ;
- éviter les combos infinis ;
- garder contre-jeu et lisibilité ;
- tenir compte de la manette ;
- éviter d’exiger 300 animations uniques inutiles ;
- identifier les animations réutilisables par famille de mouvement, mais jamais au prix de l’identité visible ;
- ne pas implémenter ;
- ne pas interrompre Claude.
EN FIN DE DOCUMENT
Ajoute :
A. Animation reuse matrix
Ce qui peut réellement être partagé entre plusieurs combattants sans qu’ils deviennent génériques.
B. Unique animation requirements
Les animations absolument uniques nécessaires pour chaque personnage.
C. Implementation priority
Quels personnages nécessitent le plus gros travail pour atteindre V1 réelle.
D. Current-vs-target gap
Pour chacun :
actuel → manque → cible V1.
E. Claude execution batches
Propose des lots d’implémentation cohérents pour que Claude puisse ensuite faire les 20 avec le moins de contexte et d’allers-retours possible.
Ne fais aucune modification runtime.
Cette mission sert à transformer les 20 entrées du roster en 20 vrais combattants.