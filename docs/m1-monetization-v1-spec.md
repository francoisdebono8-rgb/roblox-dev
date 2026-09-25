# BrickKit Monetization V1

## Promesse et client cible

BrickKit Monetization permet à un développeur Roblox débutant ou intermédiaire d'insérer un Model, de configurer rapidement ses Developer Products et Game Pass, puis d'obtenir une boutique fonctionnelle et un traitement serveur sûr.

Le parcours standard vise moins de cinq minutes. Les récompenses intégrées ne demandent qu'une modification de `Config`. Une récompense qui touche le système de données propre au jeu exige une petite intégration explicite dans un point d'extension isolé.

## Périmètre V1

| Fonction | Décision | Limite V1 |
| --- | --- | --- |
| Developer Products | Incluse | Prompt d'achat et récompense configurée, accordée côté serveur uniquement après réception d'un receipt. |
| Game Pass | Incluse | Vérification serveur de propriété et avantage simple configurable. |
| Boutique | Incluse | UI minimale responsive avec nom, prix Roblox, bouton d'achat et états chargement/indisponible. |
| Configuration | Incluse | Un seul `Config` pour les IDs, libellés de secours et handlers intégrés. |
| Notifications | Incluse | Achat lancé, annulé, traité ou différé. Une notification ne déclenche jamais de récompense. |

Sont exclus : gifting, rewarded ads, abonnements, marketplace complexe, analytics, datastore générique, framework BrickKit global, backend externe et dépendances tierces.

## Package et architecture

Le Creator Store livre un seul Model à placer dans `ServerScriptService` :

```text
ServerScriptService/
└── BrickKitMonetization/
    ├── Config                 (ModuleScript, seul fichier standard à éditer)
    ├── MonetizationServer     (Script)
    ├── Modules/
    │   ├── BuiltInRewards     (ModuleScript)
    │   ├── CustomRewards      (ModuleScript, extension optionnelle)
    │   ├── ReceiptLedger      (ModuleScript)
    │   └── ReceiptRouter      (ModuleScript)
    └── Templates/
        ├── MonetizationClient (LocalScript)
        └── BrickKitShop       (ScreenGui)
```

`Config` contient, pour chaque entrée : état actif, type (`DeveloperProduct` ou `GamePass`), ID numérique, libellé de secours, nom du handler et paramètres du handler. Aucun prix manuel n'est configuré.

Handlers intégrés V1 :

- `LeaderstatIncrement` ajoute une quantité à une valeur numérique `leaderstats` existante. Il convient au parcours standard, mais sa persistance et son atomicité dépendent du système de sauvegarde du jeu.
- `WalkSpeedMinimum` applique au personnage une vitesse minimale configurée. Il est idempotent et se réapplique au respawn, ce qui convient à un avantage de Game Pass.
- `CustomRewards` expose un seul point d'extension par clé pour les jeux qui utilisent leur propre profil, inventaire ou monnaie persistante. Le cœur BrickKit n'est alors pas modifié.

Le serveur est l'unique autorité sur les IDs, les receipts, la propriété et les récompenses. Le client ne transmet qu'un ID demandé; le serveur refuse les types invalides, les IDs absents ou inactifs et les appels trop fréquents. Aucun remote ne permet de choisir un montant ou d'accorder un avantage.

## Auto-installation runtime

Après insertion du Model dans `ServerScriptService`, `MonetizationServer` effectue uniquement ces actions :

1. Valider `Config` et désactiver séparément toute entrée invalide.
2. Créer `ReplicatedStorage/BrickKitMonetization` avec les remotes BrickKit si le nom est libre.
3. Cloner une seule fois `MonetizationClient` et `BrickKitShop` dans `PlayerScripts` et `PlayerGui` des joueurs présents et futurs; le `ScreenGui` utilise `ResetOnSpawn = false`.
4. Enregistrer les handlers de receipts filtrés et les vérifications de Game Pass.

Ces objets sont créés uniquement pendant l'exécution. Le produit ne se déplace pas lui-même, ne modifie pas durablement l'arborescence du lieu, ne remplace aucun objet existant et ne touche aucun script étranger. Une collision de nom provoque un arrêt BrickKit avec un message explicite. Le contenu source reste visible dans le Model : aucune installation cachée ou obfusquée.

## Developer Products et receipts

La V1 utilise `MarketplaceService:BindReceiptHandler(Enum.ReceiptType.DeveloperProduct, handler, { productId })`, avec un binding filtré par Developer Product actif. Cette API est retenue car un handler filtré prend en charge uniquement ses IDs et peut coexister avec le `ProcessReceipt` ou les bindings d'un jeu existant.

Chaque ID est lié séparément afin qu'un conflit n'empêche pas les autres produits de fonctionner. Si l'API est indisponible ou si un ID possède déjà un binding, l'entrée concernée est retirée de la boutique et une erreur d'intégration est affichée. La V1 n'assigne jamais automatiquement `ProcessReceipt`, car cela pourrait remplacer le callback du jeu.

`PromptProductPurchaseFinished` peut uniquement fermer l'état visuel du prompt. Il n'accorde jamais de récompense et n'est jamais considéré comme preuve d'achat. Seul le handler de receipt peut accorder la récompense.

Traitement d'un receipt :

1. Vérifier le `ProductId`, le `PlayerId`, la présence du joueur et le handler configuré.
2. Consulter `ReceiptLedger` avec `PurchaseId`; un receipt déjà finalisé retourne `Processed` sans réattribuer.
3. Si le ledger est indisponible, ne rien attribuer et retourner `NotProcessedYet`.
4. Exécuter le handler serveur, puis enregistrer le `PurchaseId` comme finalisé.
5. Retourner `Processed` seulement si l'attribution et l'enregistrement ont réussi; sinon retourner `NotProcessedYet`.

`ReceiptLedger` est un DataStore dédié aux receipts BrickKit, pas un datastore générique de jeu. Un garde mémoire empêche également une répétition sur le même serveur.

Roblox peut présenter le même receipt plusieurs fois ou simultanément à deux serveurs. Le ledger réduit fortement les doubles attributions mais ne garantit pas « exactement une fois » si le serveur tombe entre l'attribution et l'enregistrement. Pour une récompense persistante, le handler personnalisé doit enregistrer `PurchaseId` et appliquer la mutation dans la même transaction atomique que les données du joueur. Sans cette intégration au système de sauvegarde du jeu, BrickKit promet une gestion avec nouvelle tentative et déduplication, pas une garantie absolue.

Si DataStore est indisponible avant l'attribution, aucune récompense n'est donnée, le receipt reste non traité et Roblox pourra le représenter. Si l'enregistrement échoue après l'attribution, le handler retourne `NotProcessedYet`, journalise clairement le risque de répétition et conserve le garde mémoire tant que le serveur vit.

## Game Pass

Le serveur appelle `UserOwnsGamePassAsync` à l'arrivée du joueur, au respawn et après la fermeture d'un prompt. Le résultat de propriété côté serveur, et non le booléen envoyé par le client, décide de l'avantage. Un échec API n'accorde rien et produit une notification réessayable.

L'avantage intégré `WalkSpeedMinimum` fixe un minimum au lieu d'ajouter plusieurs fois une valeur. Un avantage persistant propre au jeu passe par `CustomRewards`.

## Noms et prix affichés

À l'ouverture de la boutique, le client récupère les informations Roblox avec `GetProductInfoAsync`, en utilisant `Enum.InfoType.Product` pour un Developer Product et `Enum.InfoType.GamePass` pour un pass. Les appels sont protégés, lancés en parallèle puis mis en cache pour la session afin d'afficher le nom et `PriceInRobux` correspondant au joueur.

En cas d'échec, l'UI affiche le libellé de secours de `Config` et « Prix indisponible ». Le bouton peut ouvrir le prompt Roblox, qui reste la source de vérité du prix, mais l'UI n'invente ni ne conserve un prix manuel.

## Installation standard, objectif inférieur à cinq minutes

1. Publier l'expérience et créer les Developer Products et Game Pass dans Creator Hub.
2. Insérer le Model BrickKit Monetization et déplacer son unique racine dans `ServerScriptService`.
3. Ouvrir `Config`, saisir les IDs et choisir `LeaderstatIncrement` ou `WalkSpeedMinimum` avec leurs paramètres.
4. Vérifier que le leaderstat ciblé existe si ce handler est choisi, puis lancer le jeu et ouvrir la boutique.
5. Tester dans une expérience publiée avec l'accès API Studio activé pour le ledger.

Un jeu dont les récompenses modifient un profil ou inventaire personnalisé remplace l'étape 3 par l'ajout d'une fonction dans `CustomRewards`; c'est la seule intégration supplémentaire prévue.

## Démo et tests manuels

La démo contient une zone de spawn, un bouton de boutique, un leaderstat de monnaie, un Developer Product de faible valeur et un Game Pass utilisant `WalkSpeedMinimum`. Aucun autre système de jeu n'est inclus.

- [ ] Le Model démarre après un seul déplacement et une édition de `Config`.
- [ ] Un achat annulé ne donne rien et ferme proprement l'état d'attente.
- [ ] Un achat réussi n'est accordé que depuis le handler de receipt.
- [ ] La représentation d'un même `PurchaseId` est dédupliquée dans les conditions normales et ne prétend pas garantir l'exactement-une-fois absolu.
- [ ] Une panne DataStore avant attribution ne donne rien et retourne `NotProcessedYet`.
- [ ] Un Game Pass possédé applique l'avantage; un pass non possédé ne l'applique pas.
- [ ] Le respawn conserve l'UI et réapplique l'avantage sans accumulation.
- [ ] Les IDs invalides ou manquants désactivent uniquement leur entrée.
- [ ] Un conflit de remote ou de binding arrête ou désactive explicitement la partie concernée sans écrasement.
- [ ] Les remotes refusent ID inconnu, mauvais type, montant injecté et appels excessifs sans erreur serveur.
- [ ] Les noms et prix viennent de Roblox; un échec affiche le fallback sans faux prix.
- [ ] Un `ProcessReceipt` existant continue de recevoir les produits non filtrés par BrickKit.

## Packaging Creator Store

- Le Model unique `BrickKitMonetization` avec `Config`, serveur, modules et templates.
- Des exemples inactifs par défaut et les deux handlers intégrés documentés.
- Le point d'extension `CustomRewards` isolé.
- Le ledger de receipts et les bindings filtrés par ProductId.
- L'UI, le client et les remotes créés au runtime sans écrasement.
- Un guide d'installation reprenant les cinq étapes standard et le cas personnalisé.
- Une place de démonstration séparée avec la checklist complète.
- Une miniature et une description limitées à la promesse exacte de cette V1.

## Limites Roblox et API

- La V1 exige une version de Roblox prenant en charge `BindReceiptHandler`; elle ne remplace jamais silencieusement un ancien `ProcessReceipt`.
- Un binding déjà enregistré pour le même type et ProductId est un conflit à résoudre par le développeur.
- Les receipts peuvent être rejoués ou traités sur deux serveurs. Une garantie stricte « exactement une fois » exige une transaction intégrée aux données persistantes du jeu.
- Les appels Marketplace et DataStore peuvent échouer. La V1 échoue fermée et laisse le receipt en attente plutôt que supposer un achat.
- La propriété d'un Game Pass acheté hors de l'expérience peut mettre du temps à se propager pendant une session active.
- Les informations de prix peuvent être temporairement indisponibles; seul le prompt Roblox fait foi.
- Les tests complets exigent une expérience publiée et peuvent consommer de vrais Robux.

## Definition of Done

- [ ] Le parcours standard fonctionne en moins de cinq minutes avec un seul déplacement de Model et une seule édition de `Config`.
- [ ] L'auto-installation est limitée aux objets BrickKit décrits et n'écrase ni ne modifie durablement le jeu.
- [ ] Chaque Developer Product actif possède un `BindReceiptHandler` filtré; `PromptProductPurchaseFinished` n'accorde rien.
- [ ] Une panne DataStore avant attribution conserve le receipt en attente sans récompense.
- [ ] La stratégie de déduplication, son point d'extension atomique et ses limites sont documentés et testés.
- [ ] Les Game Pass sont vérifiés côté serveur et leur avantage intégré est idempotent au respawn.
- [ ] Les prix sont lus via MarketplaceService avec un fallback sans prix inventé.
- [ ] Les validations serveur et tous les cas de la checklist passent dans la démo publiée.
- [ ] Le package, le guide, la démo, la miniature et la description reflètent uniquement le périmètre V1.
- [ ] Aucune fonctionnalité exclue, dépendance tierce, backend externe ou framework global n'est présent.
