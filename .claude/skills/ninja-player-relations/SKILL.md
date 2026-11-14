---
name: ninja-player-relations
description: Traiter avec naturel les retours de joueurs et gérer une communication crédible autour de Ninja Duel. Utiliser pour commentaires, réponses, annonces, notes de mise à jour, demandes d'aide et analyse de feedback communautaire.
---

## Exécution dans Ninja Duel

Charger `games/ninja-duel/CLAUDE_START_HERE.md`, les sources actives pertinentes et `docs/tools/RUNBOOK_4_DISCUSSIONS.md` depuis le checkout courant. Les quatre discussions sont DEV, CM, ANIMATEUR et OUTILLEUR ; elles se transmettent le travail par Git et les sources actives, pas par mémoire partagée. Respecter leurs périmètres de fichiers. Ne pas supposer que `main` ou une branche datée est la référence : comparer HEAD, checkpoint et décisions.

Pour une demande de réalisation, aller jusqu'au résultat dans le périmètre autorisé : reproduire ou capturer le départ, modifier les vrais fichiers, construire, déclencher l'action dans Studio, regarder le résultat en mouvement, corriger les défauts restants de la demande et rejouer le build final. Ne pas s'arrêter à un diagnostic, une fiche ou un plan lorsque l'utilisateur demande une réalisation. Pour une demande de conseil, répondre sans modifier le jeu.

Réutiliser les profils du même commit : ND-JEU (parcours joueur sans outils), ND-DEV (diagnostic), ND-QA (batterie native), ND-FILM (capture). Le Mac est organisé sous `~/Documents/NinjaDuel/` ; l'actualisation existante est `_outils/actualiser_places.sh`. Respecter les locks et la place occupée par une autre discussion ; employer LAB/repro si nécessaire. Un essai à chaud n'est livré qu'après report dans les sources, reconstruction et observation du résultat final. Vérifier la ligne BUILD/RUNTIME/profil/commit de la place utilisée.

Lire les commandes courantes dans `tools/studio/README.md`, `docs/tools/DEVTOOLS.md`, `docs/tools/OUTIL_VISUEL_F7.md` et, pour filmer, `docs/tools/OUTIL_TOURNAGE_F4.md` et `tools/capture/README.md` (chemins relatifs à games/ninja-duel). Piloter les outils déjà configurés ; ne pas demander à François de découvrir ou lancer ce que la session peut faire. En cas de blocage, tenter les solutions existantes dans ce périmètre puis décrire le blocage précis ; ne jamais inventer une observation.

Mettre les faits dans CURRENT_STATE, les tâches dans MASTER_BACKLOG et les transmissions dans SINCE_LAST_CLAUDE selon EXECUTION_RULES. Conserver les catégories TECHNICAL/NATIVE_STUDIO/HUMAN_VISUAL_FEEL/LIVE_ROBLOX : une observation par Claude n'est pas l'avis humain de François. Pas de second backlog ni de rapport autonome systématique. Tests et isolation pertinents obligatoires selon les règles actives ; ne pas affaiblir un test pour obtenir PASS. L'installation ne lance aucun de ces travaux : les déclencher seulement au cours des demandes utilisateur pertinentes.

## Utiliser les retours pour terminer le travail demandé

Pour une réponse ou une annonce demandée, retrouver le fil et l'état réel du jeu. Écrire une réponse spécifique prête à l'emploi ; si l'envoi a été explicitement demandé, l'effectuer avec la bonne identité et retourner son lien. En l'absence d'autorisation d'envoi, livrer le brouillon.

Si François demande de traiter un problème rapporté, suivre le lien entre message et réalisation : extraire version/scénario, retrouver l'ID existant dans MASTER_BACKLOG, reproduire avec F6/Studio, passer la demande au propriétaire DEV/ANIMATEUR/OUTILLEUR concerné et suivre le résultat dans les sources actives. La transmission doit contenir la preuve utile et le critère concret, pas « améliore la fluidité ».

Ne pas promettre au joueur une correction tant qu'elle n'est pas observée dans le build concerné, ni annoncer sa disponibilité publique si seul le dépôt a changé. Pour une demande d'annonce, produire le texte et les médias réellement requis en coopération avec le skill clips, sans inventer un lancement ou contacter une audience supplémentaire.

Ne pas créer de tickets, de campagne ni de chantier communautaire à partir de chaque commentaire. Le travail dépend de la demande en cours et des décisions actives.

# Construire une relation crédible

Écrire comme un créateur attentif, concret et accessible. Adapter le ton au contexte et aux interlocuteurs sans imiter artificiellement leur argot. Préserver la confiance en distinguant ce qui existe, ce qui est en cours et ce qui reste envisagé.

## Comprendre avant de répondre

Lire le message complet et le fil pertinent. Identifier si la personne rapporte un problème, exprime une préférence, pose une question, propose son aide ou cherche simplement un échange. Plusieurs intentions peuvent coexister. Vérifier la version ou le contexte nécessaire sans demander des informations déjà disponibles.

Distinguer ce qui est dit de ce qu'on interprète. Ne pas conclure qu'un joueur est hostile, qu'il veut voler le jeu ou qu'il représente toute la communauté sur la base d'un seul message. Ne pas transformer un compliment en preuve de demande commerciale.

## Répondre avec une attention précise

Reconnaître le détail réellement utile du message, puis répondre au point principal. Poser au maximum une ou deux questions nécessaires pour avancer. Remercier proportionnellement à la contribution ; éviter les longues formules de service client, l'enthousiasme automatique et les promesses vagues.

Pour un bug : reformuler le symptôme sans prétendre l'avoir reproduit, demander l'information manquante décisive, et indiquer l'état réel du traitement. Pour une préférence : reconnaître le ressenti et explorer le contexte sans promettre immédiatement de changer le jeu. Pour une proposition d'aide : clarifier la contribution souhaitée et les moyens existants, sans accorder d'accès au dépôt.

Quand une découverte du projet est pertinente, demander naturellement comment la personne l'a trouvé. Ne pas mener un interrogatoire ni présenter cette question comme une suspicion.

Pour une critique vive, traiter le fond sans adopter l'agressivité. Pour une correction justifiée, reconnaître précisément l'erreur et donner la bonne information. Ne pas inventer une excuse ou un calendrier.

## Transformer un retour en information produit

Séparer : message original, situation vécue, problème probable, solution proposée par le joueur et éléments vérifiables. Un joueur peut bien décrire sa frustration sans identifier la meilleure solution technique.

Rattacher les retours similaires sans perdre leurs différences. Distinguer nouveaux joueurs, joueurs expérimentés et contributeurs techniques uniquement si ces statuts sont établis. Noter les contradictions et les informations manquantes. Un commentaire isolé peut révéler un blocage grave ; plusieurs commentaires ne constituent pas automatiquement un échantillon représentatif.

Si une décision est nécessaire dans la tâche, évaluer gravité, fréquence connue, impact sur le contrôle et coût de correction. Utiliser ninja-player-experience pour examiner une hypothèse de gameplay plutôt que de suivre mécaniquement la suggestion la plus insistante.

## Communiquer sur le jeu et ses changements

Présenter d'abord ce qui change pour le joueur, avec un exemple concret si utile. Séparer disponible, corrigé, expérimental et prévu. Employer les noms actuels des fonctionnalités. Ne pas annoncer une correction uniquement parce qu'un commit existe : préciser l'état de mise à disposition connu.

Pour une annonce ou un clip, donner une raison de regarder ou d'essayer liée au jeu réel. Pour une note de mise à jour, privilégier les conséquences perceptibles et mentionner les limites qui changent réellement l'usage. Éviter le jargon interne et les superlatifs sans fondement.

Ne pas promettre de date, de fonctionnalité ou de suivi individuel sans base explicite. Ne pas inventer joueurs, témoignages, popularité, partenariats ou sentiment collectif.

## Respecter le périmètre de la demande

Préparer un brouillon si l'utilisateur demande quoi répondre. Envoyer ou publier uniquement si l'utilisateur l'a explicitement demandé, sur la surface et au destinataire vérifiés. Ne pas interpréter l'activation de ce skill comme une autorisation permanente de communiquer.

Vérifier l'identité et le fil avant un envoi. Ne pas publier de détails privés, de secrets du dépôt ou d'informations personnelles inutiles. Ne pas modifier les accès pour faciliter un échange sans instruction correspondante.

Adapter la sortie au besoin : réponse prête à envoyer, annonce, synthèse de retours ou décision argumentée. Ne pas ajouter systématiquement un plan communautaire, une campagne marketing ou une nouvelle mission.
