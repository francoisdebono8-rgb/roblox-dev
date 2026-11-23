# Progression et collection — guide Claude

**Optionnel, serveur uniquement, OFF.** Aucun branchement au combat, à la sélection locale, aux inputs ou à la caméra. Le roster jouable actuel reste entier et immédiatement accessible. La config reflète les cinq personnages présents ; les fixtures à vingt personnages ne créent aucun combattant jouable.

| Fonctionne et testé hors ligne | Préparé, non activé / non validé en production |
|---|---|
| Profils versionnés, XP/niveaux/rangs par personnage, plafonds individuels, récompenses de maîtrise | Influence de la progression sur un combat |
| Collection, sélection possédée, fragments, monnaies séparées, récompenses idempotentes | Nouveaux personnages, techniques, éveils et cosmétiques effectivement jouables |
| Packs pondérés, quantité, coût, doublons, garantie et pity configurables | Économie finale, acquisition de monnaie, Robux, reçus d'achat |
| Simulations déterministes, sandbox persistante CLI, commandes Studio en mémoire | DataStore Roblox réel : adaptateur fourni, gate Studio + namespace DEV, aucune requête cloud effectuée |
| Repository : lease, révision, retries, snapshots fixes, migration v1→v2, refus des données corrompues | Lifecycle joueurs, budgets DataStore, sauvegarde à la fermeture, déploiement online |
| Politique Local / Ranked / ProgressionBattles et queues séparées | Matchmaking cross-server et liaison aux futurs matchs réels |

## Utiliser maintenant

Depuis `games/ninja-duel`, avec Lune/Luau installés (`NINJA_DUEL_TOOLS`, `LUNE` ou PATH) :

```sh
python3 tools/progression.py give --character Mirage
python3 tools/progression.py xp --character Mirage --amount 500
python3 tools/progression.py rank --character Mirage --rank Master
python3 tools/progression.py currency --currency Coins --amount 1000
python3 tools/progression.py pack --pack Training
python3 tools/progression.py mastery --character Mirage --reward Mirage:master
python3 tools/progression.py select --character Mirage
python3 tools/progression.py remove --character Mirage
python3 tools/progression.py dump
python3 tools/progression.py verify
python3 tools/progression.py reset
python3 tools/progression.py simulate --profiles 100 --packs 100 --out progression/reports/my-packs.json
python3 tools/progression.py simulate --profiles 1000 --packs 100 --roster 20 --out progression/reports/my-roster20.json
python3 tools/progression.py bench --profiles 1000 --roster 20
python3 tools/dev.py verify
```

`--profile dev_qa` choisit un autre profil. `--store progression/sandbox/session.dev.json` choisit une sandbox. Le CLI refuse tout autre répertoire, les ID non `dev_*`, les fichiers étrangers et les accès concurrents. Chaque commande réussie sauvegarde et libère son lease ; un échec conserve le fichier précédent. Les sandboxes sont ignorées par Git. `verify` lit le record existant sans créer de profil. Après un crash CLI, vérifier que le processus est arrêté avant d'enlever son fichier `.lock`.

`--sequence N` rejoue une commande de façon idempotente : même séquence et même opération renvoient le résultat déjà appliqué ; les anciennes séquences ou les trous sont refusés. Toujours reprendre la séquence du profil, ne pas la réinitialiser après un reset.

Studio, **Test → Command Bar Server**, sans aucun accès DataStore :

```lua
local dev = game.ServerStorage.NinjaDuelDev
print(dev:Invoke("profiles", "give", {profile="dev_studio", character="Mirage"}))
print(dev:Invoke("profiles", "xp", {profile="dev_studio", character="Mirage", amount=500}))
print(dev:Invoke("profiles", "currency", {profile="dev_studio", currency="Coins", amount=1000}))
print(dev:Invoke("profiles", "pack", {profile="dev_studio", pack="Training"}))
print(dev:Invoke("profiles", "dump", {profile="dev_studio"}))
print(dev:Invoke("profiles", "save", {profile="dev_studio"}))
print(dev:Invoke("profiles", "verify", {profile="dev_studio"}))
```

Les mêmes opérations `remove/rank/mastery/select/reset` sont disponibles avec les mêmes champs. `simulate` accepte `{profiles=100,packs=100,seed=42}` et cède périodiquement le thread ; préférer le CLI pour les gros lots. Le chemin bindable Studio est préparé ; ses opérations ont été testées via le harness, sans nouvelle QA native. Les profils Studio sont en mémoire et disparaissent à Stop. Ils ne changent pas le personnage du duel. Le bindable vit dans ServerStorage et n'est installé qu'en Studio ; aucun Remote n'expose les grants.

## Interfaces à reprendre plus tard

Modules sous `ServerScriptService.NinjaDuelServer` / `src/Server/` :

- `ProgressionConfig` : registre, starter, monnaies, rangs et packs. Toutes les valeurs économiques/caps/récompenses sont des **exemples de travail non approuvés**. Pour un nouveau personnage, ajouter sa définition, puis seulement les entrées de packs voulues. `stats.Speed={base=…,growth=…,cap=…}` représente BaseSpeed/SpeedGrowth/SpeedCap. Un cap propre à chaque identité borne la projection, sans écrire dans Fighters.
- `CharacterProgression.project(cfg,id,record,normalized)` : aperçu des valeurs plafonnées. `variants/techniques/awakenings/cosmetics` sont des ensembles d'ID ; plusieurs éveils sont possibles. Les grants `variant/technique/awakening/cosmetic/currency` d'une mastery reward sont débloqués une seule fois, au rang requis.
- `ProfileSchema` : nouveau profil, validation JSON bornée, copie, migration. Le profil garde inventaire/collection, progression, stats, pity, sélection et séquences. Les personnages retirés du registre conservent leurs données mais ne deviennent pas sélectionnables online. Ne pas changer les ID stables ni recycler les ID de récompenses.
- `CollectionEconomy.apply(profile,cfg,sequence,kind,args,rng)` : transaction sur copie, vérification puis résultat. Pour l'intégration, utiliser `repo:apply(handle,sequence,kind,args,rng)` ; les petits mutateurs internes supposent un état validé et ne constituent pas l'API transactionnelle. `reward` possède en plus un stream serveur et un numéro continu ; `matchResult` reçoit résultat/XP décidés par le serveur, jamais par le client.
- `ProfileRepository.new(adapter,cfg,{owner,clock,sleep})` : `load`, `view`, `apply`, `save(handle,release)`, `verify`, `pulse`, `closeAll`. Adaptateur `update(key,transform)` / `read(key)`. IDs actuellement **DEV seulement**. `DevelopmentProfiles.new(cfg)` fournit la façade mémoire ; `DevelopmentDataStore.new(cfg)` refuse de s'ouvrir sauf Studio, flag explicite et namespace DEV exact. Aucun adaptateur live n'est créé.
- `ProgressionRoster` : Local ignore la collection ; Ranked prend les bases sans croissance ; ProgressionBattles retourne une projection potentielle. **Les deux plans indiquent combatApplicationEnabled=false.** `ProgressionLobby.new(cfg,lookup)` exige Enabled=true et un lookup serveur synchrone de profils prêts ; valide encore possession/chargement lors du pairing. Les régions viennent de cfg.Regions et les queues vides sont supprimées. Il réutilise OnlineQueue, sans activer OnlineHost ni les matchs locaux.

Les flags `Enabled`, `CombatEffectsEnabled`, `MonetizationEnabled`, `DevDataStoreEnabled` sont false. Les changer ne construit pas une intégration : il faut un host explicite et ses tests.

## Sauvegarde : garanties et limites

Un profil et ses balances/receipts sont dans une seule clé ; l'acquisition du lease et chaque snapshot utilisent UpdateAsync. Un callback répété ne retire ni monnaie ni RNG à nouveau. En erreur ambiguë, le même token/snapshot est réessayé ; le handle passe SaveUncertain et bloque les mutations jusqu'à confirmation. Une révision différente ou un lease expiré bloque l'ancien écrivain. Un chargement corrompu/indisponible ne devient jamais un profil par défaut écrasable. Ces mécanismes suivent les contraintes [Roblox sur l'écriture atomique et le session locking](https://create.roblox.com/docs/cloud-services/data-stores/player-data-purchasing) ; les [erreurs d'écriture peuvent être ambiguës](https://create.roblox.com/docs/cloud-services/data-stores/error-codes-and-limits).

La mutation en mémoire **n'est pas durable avant save confirmé**. Une panne avant sauvegarde peut perdre les changements non enregistrés. Aucun achat/transfert ne doit être exposé comme acquis avant cet ACK. Avant le live : adaptateur/namespace séparé, owner unique par processus, host chargé de pulse/renouvellement, budgets/retry avec jitter, départ des joueurs/BindToClose, récupération après crash, migrations sur sauvegardes réelles, tests cloud de conflits/throttling/disconnect et deux vrais clients. Le benchmark mémoire ne mesure aucune limite Roblox.

Rapports et limites statistiques : [SIMULATION_RESULTS.md](SIMULATION_RESULTS.md). Futur marché, **note seulement** : [MARKET_PREPARATION.md](MARKET_PREPARATION.md).
