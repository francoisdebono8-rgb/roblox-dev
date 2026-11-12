> Essai technique (laboratoire). Rien de ce dossier n'est chargé par le jeu ni par `build.py`. État, priorités et règles : [sources actives](../../docs/active/EXECUTION_RULES.md).

# Essai Server Authority : un perso, déplacement et esquive prédits (12/11)

Demande de l'utilisateur (12/11) : « D'abord, un essai de Server Authority (Roblox, officiel) sur une branche, avec un perso : déplacement et esquive prédits. Il demande l'Input Action System et la simulation fixe. Le résultat décide de la suite. » Point de départ : la note de projet « Projets GitHub utilisables » (`github-projets-utilisables-2026-11-12`), point 1.

## Ce que Server Authority demande (documentation Roblox, lue le 12/11)

- **Workspace** : `StreamingEnabled`, `SignalBehavior = Deferred`, `NextGenerationReplication`, `UseFixedSimulation` et `PlayerScriptsUseInputActionSystem` activés, puis `AuthorityMode = Server` en dernier.
- **Boucle** : la logique tourne dans `RunService:BindToSimulation`, le même module côté serveur et côté client. Le client prédit ; en cas de désaccord, il revient à l'état du serveur et rejoue ses entrées.
- **Entrées** : uniquement des `InputAction`. Le serveur ne croit rien d'autre. Chaque `InputContext` doit être sous le `Player`.
- **État** : en attributs sur les instances prédites (64 au plus par instance, chaînes de 50 caractères). Les variables Luau ne reviennent pas en arrière.
- **Interdit dans la simulation** : `Destroy`, changer le `Parent` d'une instance déjà dans le jeu, `os.clock()` et `tick()` (on utilise `time()`).

## L'essai

| Fichier | Rôle |
|---|---|
| `SATrial.luau` | Module partagé (ReplicatedStorage). Marche de Sasuke (19 studs/s, accélérations du jeu × 1,12) et esquive du jeu (61 studs/s pendant 0,32 s, recharge 0,8 s), écrites pour la simulation : entrées `Move` (ZQSD/WASD, stick) et `Dodge` (Q, B), état en attributs sur la racine, temps de la simulation |
| `SATrialServer.server.luau` | Donne un `InputContext` à chaque joueur, lance la simulation |
| `SATrialClient.client.luau` | Même simulation côté client (prédite), caméra fixe, sonde `_G.SATrialProbe` : temps entre l'appui et la première image où le corps répond, A/B prédiction activée / coupée |
| `setup_studio.luau` | À lancer en Edit (Studio MCP) : active Server Authority dans l'ordre et dit ce qui a pris |
| `build_trial.py` | Écrit la place d'essai (sol, repères tous les 10 studs, les 3 scripts) |

Procédure :
1. `python3 lab/server-authority/build_trial.py ~/Documents/NinjaDuel/LAB/repro/ND-SA-essai.rbxlx`
2. Ouvrir cette place dans Studio (une place à soi, jamais une place commune).
3. MCP `execute_luau` (Edit) avec le contenu de `setup_studio.luau`.
4. Play. Côté client : `_G.SATrialProbe.press("Dodge",.1)`, puis `report()` ; `predict(false)` pour l'A/B ; lag simulé dans les réglages réseau de Studio.

Vérifié hors Studio (12/11) : les 4 scripts compilent ; le contrôleur simulé à 60 i/s donne la marche à 19 studs/s, l'esquive à 61 studs/s dès sa première image, aucune esquive pendant la recharge.

## Résultats dans Studio

À remplir (voir le rapport de l'essai dans `CURRENT_STATE`).
