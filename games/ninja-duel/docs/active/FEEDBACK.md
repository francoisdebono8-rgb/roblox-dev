# Retours des joueurs (bêta)

Demande utilisateur, 03/11 : « un moyen de récolter leurs avis, les bugs qu'ils voient en jouant et les améliorations qu'ils aimeraient ».

## Le chemin d'un retour

1. **Dans le jeu.** Le formulaire « TELL US » (`Client/Feedback`) a trois onglets : Bug, Idée, Avis. On l'ouvre depuis :
   - le bouton **BUG / IDEA** du roster ;
   - la fiche des contrôles (Tab, ou Start à la manette) ;
   - la carte de fin de match.

   Le texte fait 500 caractères au plus. Le jeu y ajoute le contexte : écran, combattants, round, score, mode, étape du tutoriel, appareil, build, version de la place.
2. **Sur le serveur** (`Server/Feedback`) :
   - **Limites** : un envoi toutes les 30 s, vingt par visite.
   - **Filtre** : le texte passe par le filtre Roblox (`TextService`). Si le filtre ne répond pas, le retour est refusé : rien n'est gardé en brut.
   - **Stockage** : DataStore `NinjaDuelFeedback_v1`, avec l'index trié `NinjaDuelFeedbackIndex_v1` (le plus récent d'abord).
   - **Copie vers Discord** : si le secret `feedback_webhook` existe, une copie part dans le salon `#rapports-du-jeu`. Sans secret, ou si Discord refuse, le retour reste gardé.
3. **Lecture.** Dans Studio, en Play, depuis le contexte Server :

   ```lua
   game.ServerStorage.NinjaDuelFeedback:Invoke("list", 30)
   ```

   Ça donne les trente plus récents. Claude les lit, les trie et les range dans `MASTER_BACKLOG.md`, avec un `ND-Bug-xx` pour chaque bug reproduit.

## Réglages à faire une fois (Creator Dashboard / Studio)

- **Game Settings → Security → Enable Studio Access to API Services** : pour lire les retours depuis Studio.
- **Game Settings → Security → Allow HTTP Requests** : pour la copie vers Discord.
- **Creator Dashboard → l'expérience → Secrets → Create secret** :
  - nom : `feedback_webhook` ;
  - valeur : l'URL complète du webhook du salon `#rapports-du-jeu` ;
  - domaine : l'hôte de cette URL.

  **Discord refuse les requêtes qui viennent des serveurs Roblox en ligne.** Elles ne passent que depuis Studio. Dans le jeu publié, il faut donc l'URL d'un relais de webhook, avec le même chemin `/api/webhooks/<id>/<token>` sur un autre hôte. Le choix du relais est un choix de confiance, parce que le relais voit le jeton : il est à décider avant la bêta publique.

  En attendant, les retours sont gardés dans le DataStore, et Claude les recopie lui-même dans Discord.
- **Studio** : pour essayer la copie vers Discord dans Studio, ajoute le même secret dans **Game Settings → Security → Secrets**.

## Ce qui n'est jamais gardé

Ni adresse, ni e-mail, ni texte non filtré. Seuls l'identifiant Roblox et le pseudo du joueur sont gardés, pour pouvoir lui répondre sur Discord s'il y est.
