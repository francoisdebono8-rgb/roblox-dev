---
name: ninja-clips-and-image
description: Concevoir, évaluer et préparer des clips de gameplay et une image cohérente pour Ninja Duel. Utiliser pour choisir des moments partageables, préparer des captures, auditer trailers et miniatures, ou relier une amélioration du jeu à sa présentation publique.
---

## Exécution dans Ninja Duel

Charger `games/ninja-duel/CLAUDE_START_HERE.md`, les sources actives pertinentes et `docs/tools/RUNBOOK_4_DISCUSSIONS.md` depuis le checkout courant. Les quatre discussions sont DEV, CM, ANIMATEUR et OUTILLEUR ; elles se transmettent le travail par Git et les sources actives, pas par mémoire partagée. Respecter leurs périmètres de fichiers. Ne pas supposer que `main` ou une branche datée est la référence : comparer HEAD, checkpoint et décisions.

Pour une demande de réalisation, aller jusqu'au résultat dans le périmètre autorisé : reproduire ou capturer le départ, modifier les vrais fichiers, construire, déclencher l'action dans Studio, regarder le résultat en mouvement, corriger les défauts restants de la demande et rejouer le build final. Ne pas s'arrêter à un diagnostic, une fiche ou un plan lorsque l'utilisateur demande une réalisation. Pour une demande de conseil, répondre sans modifier le jeu.

Réutiliser les profils du même commit : ND-JEU (parcours joueur sans outils), ND-DEV (diagnostic), ND-QA (batterie native), ND-FILM (capture). Le Mac est organisé sous `~/Documents/NinjaDuel/` ; l'actualisation existante est `_outils/actualiser_places.sh`. Respecter les locks et la place occupée par une autre discussion ; employer LAB/repro si nécessaire. Un essai à chaud n'est livré qu'après report dans les sources, reconstruction et observation du résultat final. Vérifier la ligne BUILD/RUNTIME/profil/commit de la place utilisée.

Lire les commandes courantes dans `tools/studio/README.md`, `docs/tools/DEVTOOLS.md`, `docs/tools/OUTIL_VISUEL_F7.md` et, pour filmer, `docs/tools/OUTIL_TOURNAGE_F4.md` et `tools/capture/README.md` (chemins relatifs à games/ninja-duel). Piloter les outils déjà configurés ; ne pas demander à François de découvrir ou lancer ce que la session peut faire. En cas de blocage, tenter les solutions existantes dans ce périmètre puis décrire le blocage précis ; ne jamais inventer une observation.

Mettre les faits dans CURRENT_STATE, les tâches dans MASTER_BACKLOG et les transmissions dans SINCE_LAST_CLAUDE selon EXECUTION_RULES. Conserver les catégories TECHNICAL/NATIVE_STUDIO/HUMAN_VISUAL_FEEL/LIVE_ROBLOX : une observation par Claude n'est pas l'avis humain de François. Pas de second backlog ni de rapport autonome systématique. Tests et isolation pertinents obligatoires selon les règles actives ; ne pas affaiblir un test pour obtenir PASS. L'installation ne lance aucun de ces travaux : les déclencher seulement au cours des demandes utilisateur pertinentes.

## Fabriquer le clip demandé jusqu'à l'export

1. Pour une demande de clip, travailler dans ND-FILM actualisée et relever RUNTIME/commit. Lire le guide F4 et le README capture au HEAD actuel. Réutiliser ClipKit/ShotRunner/Sets ou NDReplay/NDDirector selon la scène existante ; ne pas créer une nouvelle place de tournage.
2. Préparer l'image avec F4, régler la qualité graphique de manière explicite, confirmer la bonne fenêtre OBS et vérifier la bande verticale. Un signal vert signifie absence des défauts détectés, pas intérêt artistique.
3. Obtenir la performance : jouer ou diriger une action du moteur réel, enregistrer le match avec NDReplay si utile. Rejouer la même performance sous plusieurs cadrages NDDirector (`front`, `ots`, `best`, `pair`, `center`) pour comparer sans changer l'action. Réserver un plan large à la compréhension du trajet, un plan rapproché à l'expression ou au contact ; choisir selon ce que l'on veut faire comprendre.
4. Synchroniser REC/STOP de F4 avec l'enregistrement réel OBS. Exploiter les plages, scènes et défauts du journal `[NinjaDuelClip]`. Corriger un cadrage, une obstruction ou un problème d'exposition et reprendre la scène ; ne pas conserver une prise ratée parce que son score global est meilleur.
5. Si pertinent, utiliser `tools/capture/edit_list.py` sur les JSON de prises pour préparer la sélection. Regarder les passages retenus : le script favorise le temps propre, pas l'émotion ou la qualité du montage. Garder le choix, l'impact et sa conséquence compréhensibles.
6. Si Studio est trop lent, employer le rendu ralenti déjà prévu par le directeur puis restituer la vitesse prévue au montage ; vérifier les sons séparément selon les limites de NDReplay. Ne pas présenter une vidéo accélérée comme une mesure de performance du jeu.
7. Monter et exporter réellement avec les moyens autorisés existants. Utiliser ffmpeg/ffprobe et `video_qc.py` pour décodage, noirs/figés possibles et planche contact après lecture des options. Regarder aussi l'export final entier, écouter les raccords et vérifier qu'il ne contient ni panneau, ni compteur dans le recadrage, ni bureau.
8. Mettre le final dans `MEDIA/<FILMxx>/` avec l'alias prévu vers `MEDIA/00_CLIPS_FINAUX/`. Respecter l'approbation sur la liste exacte avant toute suppression des rushes ; ne rien publier implicitement. Un bug de jeu part au DEV/ANIMATEUR avec instant, BUILD et prise, sans correction du gameplay dans FILM.

Pour un Short de bout en bout (tournage, montage, textes de publication), le skill de compte `ninja-duel-shorts` décrit le circuit déjà suivi par le CM ; les deux se complètent, sans doublon.

Ne pas livrer trois idées quand un clip est demandé : livrer le fichier final consultable ou nommer exactement l'étape matériellement bloquée après les tentatives effectuées. Pour une miniature ou bannière demandée, produire aussi l'asset final aux dimensions de la surface, à partir des modèles actuels. L'Ōtsutsuki hôte des devlogs ne remplace pas l'avatar du joueur dans la promesse du gameplay ; relire les décisions actuelles kit/corps.

# Promesse

Faire voir une action qui donne envie de dire « je veux faire ça ». Partir du jeu réel et de la promesse « des combats stylés, la sensation d'être un ninja ». Ne pas confondre spectacle visuel et moment mémorable : donner un enjeu, une décision et une conséquence compréhensibles.

## Établir les matériaux disponibles

Lire les décisions créatives et rôles existants. Inventorier les captures, vidéos, modèles, arènes, animations et mécaniques réellement présents. Noter la version du jeu et les droits d'usage connus des éléments utilisés.

Si aucune vidéo n'est disponible, produire un plan de capture. Sans contrôle du jeu, ne pas annoncer qu'un clip a été tourné. Distinguer extrait réel, scène préparée dans le moteur, concept et visuel généré. Ne pas présenter une cinématique préparée comme une partie spontanée.

## Trouver des moments, pas accumuler des effets

Chercher dans les mécaniques existantes : esquive de justesse puis riposte ; déplacement habile suivi d'une attaque ; retournement d'un duel ; feinte comprise après son dénouement ; synchronisation entre joueurs ; incident drôle lisible.

Pour chaque candidat, préciser :
1. Ce que comprend un inconnu au premier regard.
2. La menace ou l'objectif visible.
3. Le choix du joueur qui change la situation.
4. Le dénouement et sa lisibilité.
5. Ce qui donne envie d'essayer soi-même.

Écarter les concepts dont le seul intérêt serait ajouté par une légende trompeuse, une mécanique absente ou un montage qui cache un défaut de contrôle. Ne pas recommander une refonte du jeu pour satisfaire un seul clip.

## Préparer une fiche de capture reproductible

Pour une demande de concepts ou comme préparation interne d'un tournage, fournir : titre de travail, émotion recherchée, mécanique/version requise, lieu, nombre de joueurs, positions initiales, suite d'actions, point de vue, informations à conserver à l'écran et condition de réussite.

Proposer une durée et un format adaptés au canal demandé ; à défaut, utiliser une courte version verticale comme hypothèse de travail. Conserver une source exploitable avant recadrage. Pour le vertical, vérifier effectivement la position des deux combattants, de l'impact et des informations utiles. Ne pas supposer qu'un recadrage central suffit.

Prévoir un début compréhensible, une montée et un dénouement. Éviter logos et introductions qui retardent inutilement l'action. Les durées proposées sont des choix créatifs à tester, pas des garanties de performance.

## Examiner le résultat réel

Regarder une première fois sans le son ni la légende, à taille de téléphone : peut-on identifier le joueur, la menace et le résultat ? Puis regarder avec son : impacts, rythme et cohérence renforcent-ils la lecture ? Vérifier occultations, tremblements, interfaces, compression et effets qui effacent les silhouettes.

Comparer l'extrait avec le plaisir aux commandes à l'aide de ninja-player-experience. Un clip séduisant ne justifie pas de casser la caméra ou le contrôle de la partie normale. Si un mode de capture est utile, le distinguer du réglage destiné aux joueurs.

## Gérer l'image à partir du jeu

Reprendre les modèles, proportions, tenues, décors, palette et effets réels. Une miniature doit rester reconnaissable dans le jeu. Si une stylisation est proposée, indiquer ce qu'elle transforme et faire valider la fidélité.

Formuler une promesse concrète appuyée par une scène disponible. Éviter les affirmations de type « meilleur jeu ninja », les fausses réactions et les fonctionnalités à venir présentées comme disponibles. Ne pas déduire une identité visuelle définitive d'anciennes images sans vérifier les références actuelles.

Pour les textes, préférer une situation ou un défi compréhensible à une avalanche d'adjectifs. Adapter le ton au public observé sans inventer son âge ni ses goûts.

## Vérifier l'attrait sans inventer une audience

Faire varier une seule dimension à la fois : moment d'ouverture, cadrage ou texte. Définir avant le test ce que l'on cherche : compréhension, envie d'essayer, clic vers le jeu ou arrivée effective. Ne pas confondre vues et nouveaux joueurs.

Si des données de publication sont fournies, rapporter période, impressions et taille d'échantillon, puis les indicateurs réellement disponibles. Comparer avec prudence des canaux ou audiences différents. Sans données, livrer une hypothèse et un plan de test, jamais une prédiction chiffrée de viralité.

En test exploratoire, demander à des personnes n'ayant pas reçu l'explication « Qu'est-ce qui vient de se passer ? » et « Qu'aurais-tu envie de faire dans ce jeu ? ». Leurs réponses peuvent révéler un écart entre l'intention et la lecture.

## Coordonner et livrer

Utiliser les rôles existants : le développeur vérifie la reproductibilité mécanique ; l'animateur vérifie les poses, silhouettes et contacts ; le responsable de présentation existant assemble les éléments selon son périmètre réel. Ne pas inventer des rôles supplémentaires.

Adapter la livraison à la demande : clip exporté pour une réalisation, fiches seulement pour une demande d'idées ou de préparation. Joindre les preuves et les limites utiles. Ne publier et ne contacter personne sans instruction explicite de l'utilisateur.
