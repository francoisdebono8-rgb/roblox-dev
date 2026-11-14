---
name: ninja-interface-design
description: Concevoir et améliorer les interfaces de Ninja Duel selon les décisions et perceptions du joueur. Utiliser pour HUD, menus, boutique, progression, commandes tactiles, onboarding et cohérence visuelle en jeu.
---

## Exécution dans Ninja Duel

Charger `games/ninja-duel/CLAUDE_START_HERE.md`, les sources actives pertinentes et `docs/tools/RUNBOOK_4_DISCUSSIONS.md` depuis le checkout courant. Les quatre discussions sont DEV, CM, ANIMATEUR et OUTILLEUR ; elles se transmettent le travail par Git et les sources actives, pas par mémoire partagée. Respecter leurs périmètres de fichiers. Ne pas supposer que `main` ou une branche datée est la référence : comparer HEAD, checkpoint et décisions.

Pour une demande de réalisation, aller jusqu'au résultat dans le périmètre autorisé : reproduire ou capturer le départ, modifier les vrais fichiers, construire, déclencher l'action dans Studio, regarder le résultat en mouvement, corriger les défauts restants de la demande et rejouer le build final. Ne pas s'arrêter à un diagnostic, une fiche ou un plan lorsque l'utilisateur demande une réalisation. Pour une demande de conseil, répondre sans modifier le jeu.

Réutiliser les profils du même commit : ND-JEU (parcours joueur sans outils), ND-DEV (diagnostic), ND-QA (batterie native), ND-FILM (capture). Le Mac est organisé sous `~/Documents/NinjaDuel/` ; l'actualisation existante est `_outils/actualiser_places.sh`. Respecter les locks et la place occupée par une autre discussion ; employer LAB/repro si nécessaire. Un essai à chaud n'est livré qu'après report dans les sources, reconstruction et observation du résultat final. Vérifier la ligne BUILD/RUNTIME/profil/commit de la place utilisée.

Lire les commandes courantes dans `tools/studio/README.md`, `docs/tools/DEVTOOLS.md`, `docs/tools/OUTIL_VISUEL_F7.md` et, pour filmer, `docs/tools/OUTIL_TOURNAGE_F4.md` et `tools/capture/README.md` (chemins relatifs à games/ninja-duel). Piloter les outils déjà configurés ; ne pas demander à François de découvrir ou lancer ce que la session peut faire. En cas de blocage, tenter les solutions existantes dans ce périmètre puis décrire le blocage précis ; ne jamais inventer une observation.

Mettre les faits dans CURRENT_STATE, les tâches dans MASTER_BACKLOG et les transmissions dans SINCE_LAST_CLAUDE selon EXECUTION_RULES. Conserver les catégories TECHNICAL/NATIVE_STUDIO/HUMAN_VISUAL_FEEL/LIVE_ROBLOX : une observation par Claude n'est pas l'avis humain de François. Pas de second backlog ni de rapport autonome systématique. Tests et isolation pertinents obligatoires selon les règles actives ; ne pas affaiblir un test pour obtenir PASS. L'installation ne lance aucun de ces travaux : les déclencher seulement au cours des demandes utilisateur pertinentes.

## Construire et utiliser l'écran final

Partir de la vraie tâche et des composants au HEAD courant : localiser le panneau depuis `src/Client/UI.luau`, MenuStage ou ses modules actuels ; ne pas imposer ces anciens points d'entrée si le code a évolué. Pour le corps/avatar, les kits et la progression, relire les décisions actives : ne pas vendre visuellement un système absent.

1. Ouvrir le parcours actuel et prendre une capture de départ. Identifier ce que le joueur doit lire et faire, puis choisir la modification de structure nécessaire : ordre, espace, contenu, accès ou feedback. Une recoloration seule ne corrige pas une mauvaise hiérarchie.
2. Implémenter le composant réel, ses états et sa navigation dans le périmètre du rôle. Utiliser les ressources du jeu. Faire les choix de taille, contraste et rythme visuel ; ne pas se limiter à une description que François devrait transformer en maquette.
3. Construire et ouvrir l'écran modifié. Cliquer réellement ses actions, fermer et rouvrir, puis revenir au jeu. Sur les appareils pris en charge, utiliser l'émulateur Studio et vérifier le viewport, les zones sûres, les textes longs et la fermeture accessible. Pour un problème de fit/clamp, mesurer les positions réelles des boutons plutôt que conclure du seul calcul théorique.
4. Inspecter le rendu à taille réelle et sur fond de jeu chargé ; reprendre les débordements et les incohérences. Si le panneau est beau isolément mais masque l'action, corriger la composition.
5. Livrer l'écran implémenté et une capture du build final avec le parcours vérifié. Si seule une maquette a été demandée, livrer la maquette ; ne pas lancer son intégration sans demande.

# Rendre l'action évidente

Commencer par la décision que l'écran doit permettre au joueur de prendre. Définir une action principale, les informations nécessaires et la façon de revenir au jeu. Ancrer l'identité ninja dans les références actuelles du projet : typographie lisible, silhouettes, matériaux et détails cohérents, sans inventer une nouvelle direction artistique à chaque écran.

## Reprendre le système existant

Lire les composants, styles, ressources, captures actuelles et décisions du projet. Réutiliser les éléments cohérents. Identifier la plateforme et le mode de saisie visés ; ne pas supposer qu'un écran desktop fonctionne sur téléphone.

Séparer une retouche locale, un composant réutilisable et une évolution de direction artistique. Ne pas transformer une correction en refonte globale. Si une maquette demandée change le système, expliciter les quelques règles réutilisables qu'elle introduit.

## Organiser l'information

Pour l'écran concerné, écrire la question du joueur en une phrase : « que puis-je faire maintenant ? », « cette compétence est-elle disponible ? », « que vais-je recevoir pour ce prix ? ». Éliminer ou réduire les éléments qui concurrencent cette réponse.

Pendant un combat, privilégier adversaire, menace et informations utiles à la décision immédiate. En menu, organiser titre, contenu et action selon leur importance. Une hiérarchie claire doit rester perceptible sans dépendre uniquement de la couleur.

Ne pas prendre les néons, dégradés, panneaux translucides ou effets permanents comme recette de qualité. Justifier chaque traitement par la lisibilité, l'identité ou le retour d'action.

## Concevoir une interaction complète

Prévoir seulement les états applicables : normal, sélectionné, indisponible, chargement, succès, erreur et contenu absent. Donner un retour proche de l'action et un moyen clair de corriger une erreur. Employer des textes courts, précis et naturels ; expliquer la conséquence plutôt qu'un détail technique interne.

Pour une boutique, distinguer prix, devise, contenu reçu, prérequis et propriété actuelle. Confirmer les achats selon le flux réel du projet et éviter ambiguïtés ou fausse urgence. Pour une progression, montrer ce qui est débloqué, la prochaine action possible et les prérequis pertinents.

Pour la fermeture, garder le bouton visible et utilisable sur le mode de saisie ciblé. Ne pas dépendre d'un clavier pour un joueur tactile. Conserver l'état utile quand un panneau est rouvert si cela correspond au comportement attendu.

## Composer pour l'écran réel

Vérifier dimensions disponibles, zones sûres, placement des contrôles et masquage du terrain. Employer une mise en page adaptée au contenu et aux contraintes plutôt que de réduire uniformément un grand panneau.

Prendre en compte textes longs, montants élevés, liste vide ou remplie et résolutions étroites concernées par la tâche. Si le jeu prend en charge les deux orientations, examiner les deux ; sinon respecter l'orientation prévue. Maintenir contraste, tailles lisibles et cibles tactiles adaptées. Les objectifs numériques proposés doivent être vérifiés dans l'environnement réel.

## Passer de l'intention au rendu

Décrire la structure, les espacements, les styles et états nécessaires au développeur. Si des assets sont requis, vérifier leur disponibilité et leur fidélité au projet avant de les utiliser. Ne pas reconstruire une ressource depuis une miniature quand sa source est disponible.

Vérifier le résultat en contexte : HUD sur une scène chargée, panneau au-dessus du jeu, commande tactile pendant le mouvement. Une capture isolée ne prouve pas que l'écran reste utilisable en partie.

Utiliser ninja-player-experience lorsque l'interface change le contrôle ou la compréhension de la partie ; utiliser ninja-clips-and-image uniquement si la tâche concerne aussi une présentation extérieure.

Rapporter les changements utiles au joueur et les conditions réellement vérifiées. Sans rendu accessible, signaler que la validation visuelle reste ouverte. Ne pas lancer un audit des autres écrans hors de la demande.
