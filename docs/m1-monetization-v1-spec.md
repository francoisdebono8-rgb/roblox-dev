# BrickKit Monetization V1

## Objectif et client cible

BrickKit Monetization est un Model prêt à configurer pour un développeur Roblox débutant ou intermédiaire qui possède déjà une expérience et veut ajouter une monétisation simple sans bâtir toute l'infrastructure.

La V1 doit être installable et configurable en moins de cinq minutes. Elle ne couvre que les Developer Products, les Game Pass et une boutique minimale.

## Périmètre V1

| Fonction | Décision | Limite V1 |
| --- | --- | --- |
| Developer Products | Incluse | Achat déclenché depuis la boutique, récompense configurée par produit et accordée uniquement par le serveur via `ProcessReceipt`. |
| Game Pass | Incluse | Détection de propriété et un avantage simple configuré par pass. |
| Boutique | Incluse | Un `ScreenGui` responsive avec liste, nom, prix affiché, bouton d'achat et états chargement/vide/erreur. |
| Configuration | Incluse | Un `Config` central pour activer les entrées et définir ID, nom affiché, prix affiché et clé de récompense/avantage. |
| Notifications | Incluse | Messages locaux sobres pour achat lancé, annulé, réussi ou échoué. Le message ne déclenche jamais de récompense. |

Sont exclus : gifting, rewarded ads, abonnements, marketplace complexe, analytics, datastore générique, framework BrickKit global, backend externe et dépendances tierces.

## Architecture Roblox minimale

Le Model livré contient trois éléments à déplacer :

```text
BrickKitMonetization/
├── ServerScriptService/BrickKitMonetization/
│   ├── Config                 (ModuleScript)
│   ├── RewardHandlers         (ModuleScript)
│   ├── ReceiptStore           (ModuleScript)
│   └── MonetizationServer     (Script)
├── StarterPlayer/StarterPlayerScripts/
│   └── MonetizationClient     (LocalScript)
└── StarterGui/
    └── BrickKitShop           (ScreenGui)
```

Au démarrage, `MonetizationServer` crée dans `ReplicatedStorage/BrickKitMonetization` les remotes nécessaires : une requête de catalogue, une requête d'achat et un événement de notification. Le serveur renvoie au client uniquement les données d'affichage utiles.

`Config` est la source centrale des Developer Products et Game Pass. Chaque entrée contient un ID numérique, un nom, un prix affiché et une clé de handler. `RewardHandlers` associe ces clés à de petites fonctions adaptées au jeu. Toute attribution, vérification d'ID et vérification de propriété se fait sur le serveur.

Le client peut seulement demander l'ouverture d'un prompt pour un ID présent et actif dans `Config`. Il ne transmet jamais de montant de récompense et aucun remote ne permet d'accorder directement un avantage.

Les Developer Products sont traités par l'unique callback serveur `MarketplaceService.ProcessReceipt`. `ReceiptStore` est un registre dédié, indexé par `PurchaseId`, utilisé uniquement pour empêcher une double attribution. Un reçu inconnu, un joueur absent ou un échec d'attribution retourne `NotProcessedYet`; `PurchaseGranted` n'est retourné qu'après attribution durable ou détection d'un reçu déjà traité.

Les Game Pass sont vérifiés côté serveur avec `UserOwnsGamePassAsync` à l'arrivée et après le prompt. L'avantage doit pouvoir être réappliqué sans effet indésirable après un respawn.

## Installation en moins de cinq minutes

1. Publier l'expérience et créer les Developer Products et Game Pass dans Creator Hub.
2. Insérer le Model BrickKit Monetization dans Roblox Studio.
3. Déplacer chacun des trois contenus livrés vers le service portant le même nom, puis supprimer le conteneur vide du Model.
4. Ouvrir `ServerScriptService/BrickKitMonetization/Config` et remplacer les exemples par les IDs, noms, prix affichés et clés de handlers du jeu.
5. Adapter uniquement les fonctions correspondantes dans `RewardHandlers` aux données déjà utilisées par le jeu.
6. Activer l'accès API en Studio pour les tests du registre de reçus, lancer la scène de démo et parcourir la checklist ci-dessous.

Une entrée invalide ou incomplète est désactivée au démarrage avec un avertissement explicite; elle n'apparaît pas dans la boutique.

## Démo et tests manuels

La place de démonstration contient une zone de spawn, un bouton d'ouverture de boutique, une monnaie visible, un Developer Product de faible valeur et un Game Pass donnant un avantage visuel simple. Elle n'ajoute aucun système de jeu annexe.

Checklist Roblox Studio et environnement publié :

- [ ] Annuler un prompt ne donne aucune récompense et affiche une notification d'annulation.
- [ ] Un achat Developer Product réussi accorde exactement la récompense configurée.
- [ ] Rejouer le même `PurchaseId`, y compris depuis deux serveurs, n'accorde la récompense qu'une fois.
- [ ] Un joueur possédant le Game Pass reçoit l'avantage; un non-propriétaire ne le reçoit pas.
- [ ] Un achat de Game Pass nouvellement terminé est revérifié par le serveur avant l'avantage.
- [ ] Un ID absent, nul ou non numérique désactive seulement l'entrée concernée et produit un avertissement lisible.
- [ ] Après respawn, l'UI fonctionne et les avantages de Game Pass sont réappliqués sans duplication.
- [ ] Un client qui invoque les remotes avec un ID inconnu, un type incorrect ou à répétition ne reçoit rien et ne provoque pas d'erreur serveur.
- [ ] Une indisponibilité Marketplace/DataStore conserve le reçu en attente et produit une erreur exploitable sans attribution hasardeuse.

## Packaging Creator Store

- Le Model `BrickKitMonetization` avec les trois arborescences de services.
- Un `Config` contenant des exemples clairement invalides par défaut.
- Des handlers d'exemple minimaux et commentés.
- Le registre dédié aux `PurchaseId` et le traitement serveur des reçus.
- L'UI, le client et les remotes créés par le serveur.
- Un guide d'installation court reprenant les six étapes ci-dessus.
- Une place de démonstration séparée et une checklist de test.
- Une miniature et une description Creator Store qui n'annoncent que les fonctions de cette V1.

## Limites Roblox et API

- `ProcessReceipt` doit rester l'unique gestionnaire des Developer Products de l'expérience. Si le jeu en possède déjà un, le client doit fusionner le routage BrickKit dans ce callback; deux callbacks concurrents ne sont pas pris en charge.
- Roblox peut livrer un reçu plusieurs fois ou sur deux serveurs. La garantie « une seule fois » dépend donc d'un handler de récompense idempotent et du registre persistant dédié; elle ne peut pas être garantie si le client remplace ce mécanisme par une modification non durable.
- Un prix écrit dans `Config` est seulement informatif et peut diverger du prix Roblox, notamment avec une tarification personnalisée. La V1 n'effectue pas de synchronisation dynamique des prix.
- Les appels Marketplace et DataStore peuvent échouer temporairement. La V1 doit échouer fermée, différer le reçu et permettre un nouvel essai plutôt que supposer un achat ou une propriété.
- La propriété d'un Game Pass acheté hors de l'expérience peut mettre du temps à se propager pendant une session active.
- Les tests complets d'achat exigent une expérience publiée et peuvent nécessiter de vrais Robux; Studio seul ne reproduit pas toutes les conditions de production.

## Definition of Done

La V1 peut passer à Package/Publish uniquement si tous les points suivants sont vrais :

- [ ] Le Model s'installe en suivant le guide en moins de cinq minutes, sans dépendance tierce.
- [ ] Seuls les Developer Products, Game Pass, boutique, configuration et notifications définis ici sont présents.
- [ ] Tous les IDs et handlers se configurent depuis `Config` et `RewardHandlers`, sans modifier le cœur du produit.
- [ ] Le serveur valide chaque requête et le client ne peut attribuer ni récompense ni avantage.
- [ ] `ProcessReceipt` gère les IDs connus, les erreurs, les joueurs absents et les reçus répétés sans double attribution.
- [ ] La propriété des Game Pass est vérifiée côté serveur et survit au respawn sans duplication.
- [ ] Chaque cas de la checklist manuelle passe dans la démo publiée.
- [ ] Les IDs invalides échouent proprement et les erreurs utiles sont visibles dans la console.
- [ ] Le package contient le Model, le guide, la démo, la checklist, la miniature et la description conformes au périmètre V1.
- [ ] Aucune fonctionnalité explicitement exclue n'est présente.
