---
name: ninja-animation-direction
description: Diriger et améliorer les animations de Ninja Duel pour exprimer agilité, maîtrise, puissance et intention. Utiliser lors des tâches de locomotion, attaques, esquives, transitions, réactions et coordination entre animation et gameplay.
---

## Exécution dans Ninja Duel

Charger `games/ninja-duel/CLAUDE_START_HERE.md`, les sources actives pertinentes et `docs/tools/RUNBOOK_4_DISCUSSIONS.md` depuis le checkout courant. Les quatre discussions sont DEV, CM, ANIMATEUR et OUTILLEUR ; elles se transmettent le travail par Git et les sources actives, pas par mémoire partagée. Respecter leurs périmètres de fichiers. Ne pas supposer que `main` ou une branche datée est la référence : comparer HEAD, checkpoint et décisions.

Pour une demande de réalisation, aller jusqu'au résultat dans le périmètre autorisé : reproduire ou capturer le départ, modifier les vrais fichiers, construire, déclencher l'action dans Studio, regarder le résultat en mouvement, corriger les défauts restants de la demande et rejouer le build final. Ne pas s'arrêter à un diagnostic, une fiche ou un plan lorsque l'utilisateur demande une réalisation. Pour une demande de conseil, répondre sans modifier le jeu.

Réutiliser les profils du même commit : ND-JEU (parcours joueur sans outils), ND-DEV (diagnostic), ND-QA (batterie native), ND-FILM (capture). Le Mac est organisé sous `~/Documents/NinjaDuel/` ; l'actualisation existante est `_outils/actualiser_places.sh`. Respecter les locks et la place occupée par une autre discussion ; employer LAB/repro si nécessaire. Un essai à chaud n'est livré qu'après report dans les sources, reconstruction et observation du résultat final. Vérifier la ligne BUILD/RUNTIME/profil/commit de la place utilisée.

Lire les commandes courantes dans `tools/studio/README.md`, `docs/tools/DEVTOOLS.md`, `docs/tools/OUTIL_VISUEL_F7.md` et, pour filmer, `docs/tools/OUTIL_TOURNAGE_F4.md` et `tools/capture/README.md` (chemins relatifs à games/ninja-duel). Piloter les outils déjà configurés ; ne pas demander à François de découvrir ou lancer ce que la session peut faire. En cas de blocage, tenter les solutions existantes dans ce périmètre puis décrire le blocage précis ; ne jamais inventer une observation.

Mettre les faits dans CURRENT_STATE, les tâches dans MASTER_BACKLOG et les transmissions dans SINCE_LAST_CLAUDE selon EXECUTION_RULES. Conserver les catégories TECHNICAL/NATIVE_STUDIO/HUMAN_VISUAL_FEEL/LIVE_ROBLOX : une observation par Claude n'est pas l'avis humain de François. Pas de second backlog ni de rapport autonome systématique. Tests et isolation pertinents obligatoires selon les règles actives ; ne pas affaiblir un test pour obtenir PASS. L'installation ne lance aucun de ces travaux : les déclencher seulement au cours des demandes utilisateur pertinentes.

## Modifier les animations, puis les voir dans le vrai jeu

Lire le partage RUNBOOK §3 quater. L'ANIMATEUR possède AuthoredClips*, AuthoredJutsu*, AuthoredMotion, les FX, Blender et motion-lab. Le DEV possède le moteur de pose et les timings de combat. Un défaut de cadence ou d'application des poses ne se résout pas en réécrivant tous les clips.

Pour la demande courante :
1. Repérer la source du clip et son générateur sous `tools/blender/`, le slot réellement résolu et ses héritages. Capturer la séquence actuelle dans Studio ; employer `poses.luau`, `side_camera.luau`, `film_record.luau` et `film_show.luau` si un profil ou une chronophotographie aide le diagnostic.
2. Modifier la vraie source Blender ou les données d'auteur appropriées. Réutiliser le générateur/exporteur concerné au lieu de créer des données jetables ; conserver les exports utiles et la correspondance avec les tables du runtime. Motion Lab peut aider à comparer des variantes et exporter, mais ses exports sont inertes : un succès de preview ne prouve aucune intégration.
3. Construire une phrase corporelle : appui préparatoire, transfert, contact, sortie vers le mouvement suivant. Examiner l'adversaire et le terrain en même temps, pas seulement le mannequin isolé. Donner à chaque kit sa signature à travers des choix de poses et trajectoires, au-delà d'un changement de vitesse.
4. Charger la correction dans la place de test disponible via le circuit existant. Un hot push sert à itérer rapidement, puis doit revenir aux sources et au build. Regarder de face/profil pour comprendre, puis depuis la caméra normale à vitesse réelle pour décider.
5. Comparer la silhouette, les pieds, le contact, le raccord et la liberté de contrôle. Reprendre le point faible observé plutôt que déclarer terminé après export. Un générateur qui a produit cent clips n'est pas cent améliorations démontrées.
6. Soumettre le delta dans le circuit ANIMATEUR→DEV prévu, avec la scène et la preuve. Respecter les noms/contrats de StepSpeeds, ReactionSides et travel actuels ; ne pas les contourner avec un second système. Après intégration, le résultat visible dans le build commun reste à vérifier.

# Donner une intention au mouvement

Partir de la sensation recherchée dans l'action demandée : bondir avec précision, éviter de justesse, frapper avec engagement, se réceptionner avec maîtrise. Décrire ce que le corps doit communiquer avant de choisir des effets. Conserver les proportions, rigs, équipements et contraintes réellement utilisés dans le projet.

## Examiner avant de prescrire

Lire la mécanique concernée et les animations voisines. Identifier le rig, les animations existantes, leurs priorités, les transitions, les événements de contact, les règles de mouvement et la source du déplacement. Ne pas inventer des identifiants d'assets ni déclarer un asset publié sans preuve.

Quand une référence est fournie, analyser ce qui est effectivement visible : pose, appui, direction, rythme, trajectoire et cadrage. Séparer le mouvement du corps des déplacements de caméra, du montage et des effets. Sans accès à la référence, le dire et s'appuyer sur les éléments disponibles.

## Construire une action lisible

Décomposer seulement l'action utile en intention/préparation, impulsion, phase principale, contact ou évitement, récupération et retour au contrôle. Pour chaque phase, préciser la pose dominante, les appuis, l'orientation et le lien avec la mécanique. Adapter la décomposition à l'action : ne pas imposer une longue préparation à une réponse qui doit être immédiate.

Rechercher :
- Une silhouette lisible depuis la caméra normale et avec le rig réel.
- Un transfert de poids cohérent entre bassin, torse et appuis.
- Un rythme différencié : préparation et contact n'ont pas nécessairement la même vitesse.
- Une direction de force compréhensible ; éviter un coup qui traverse sans réaction ou une réception sans absorption.
- Des raccords utilisables entre course, saut, attaque et réception, y compris en diagonale.
- Une personnalité cohérente : agilité maîtrisée, ruse ou puissance selon le personnage ; éviter de rendre chaque geste identique.

Préciser les compromis. Un salto peut être agréable à regarder mais ralentir une esquive ou rendre la visée confuse ; ne le recommander que si son rôle est clair dans l'action.

## Raccorder aux règles du jeu

Faire correspondre préparation visible, fenêtre active, impact et récupération avec les règles réelles. Ne pas modifier implicitement portée, invulnérabilité, délai d'action ou annulation en corrigeant une pose. Séparer correction visuelle et changement d'équilibrage.

Identifier qui contrôle la trajectoire pour éviter un déplacement doublé par l'animation et le script. Examiner les conflits de priorités et de mélange. Vérifier les variantes réellement concernées : action manquée, interrompue, en mouvement, près d'un obstacle, avec une arme. Ne pas exiger toutes les variantes pour une retouche locale sans lien avec elles.

## Formuler une consigne exploitable

Remplacer « rends ça plus fluide » par une instruction située : transition concernée, symptôme visible, pose ou timing à corriger, contrainte à préserver et résultat observable. Donner les durées comme mesures relevées ou propositions explicites, jamais comme valeurs universelles.

Transmettre à l'animateur la pose et le rythme ; transmettre au développeur les événements et limites de contrôle. Coordonner les rôles existants sans les redéfinir.

## Vérifier dans la tâche en cours

Comparer avant/après dans les mêmes conditions quand les outils le permettent. Contrôler glissement des pieds, pénétration, ruptures de pose, raccord des mains à l'équipement et lecture du contact. Vérifier d'abord à vitesse normale depuis la caméra de jeu, puis au ralenti pour diagnostiquer.

Sans rendu accessible, qualifier le résultat comme modification de code ou spécification à confirmer en jeu. Ne pas confondre animation exportée, animation chargée et animation observée dans la partie.

Conclure brièvement sur l'intention obtenue, ce qui a été modifié, la preuve disponible et la limite restante ; ne pas lancer une revue de toutes les animations.
