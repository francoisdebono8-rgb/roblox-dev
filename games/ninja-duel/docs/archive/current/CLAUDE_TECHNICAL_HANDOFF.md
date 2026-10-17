# Handoff technique Claude — quatre personnages

L’entrée actuelle est [CLAUDE_START_HERE](../../../CLAUDE_START_HERE.md). Le [brief artistique intégral](../missions/CLAUDE_FINAL_PASS.md) est une source du backlog, pas une mission autonome. Cette préparation ne change aucun mouvement artistique, réglage de dégâts/timing, kit, caméra ou choix de game feel.

## Démarrer en cinq minutes

Depuis `games/ninja-duel` :

```sh
python3 build.py --debug
```

Ouvrir **`dist/NinjaDuel-Debug.rbxlx`**, puis Play. Choisir Minato, Itachi, Neji ou Sasuke dans le menu existant ; le panneau de lecture seule apparaît pendant le duel. **F8** le masque. Gaara reste dans le code serveur et les tests, mais n’est pas sélectionnable dans le menu à quatre personnages.

Le Command Bar **côté serveur** peut aussi piloter les interfaces existantes :

```lua
local dev = game.ServerStorage.NinjaDuelDev
-- IDs : Flashstep=Minato, Mirage=Itachi, GentleFist=Neji, Lion=Sasuke.
dev:Invoke("start", "GentleFist", "Lion")
-- Attendre l’intro avant de tester des inputs.
print(dev:Invoke("inspect"))
print(dev:Invoke("contracts"))
dev:Invoke("act", "human", "Attack")
print(dev:Invoke("trace"))
```

`inspect` donne action, réaction, move/variant, phase et durée restante, timings du pending réellement utilisé, combo/route/confirmation/buffer, lock/cible, terrain et movement mode, guard/stamina/parry cooldown/dodge, counter/riposte, grab/bound, throw/release, projectiles et sceaux, awakening et compteurs Clash. La trace conserve au maximum 80 changements échantillonnés. Les contacts récents sont aussi dans la projection détaillée.

`workspace:SetAttribute("NinjaDuelDebugEnabled", false)` suspend collecte/diffusion. Le build normal (`python3 build.py`) **exclut** DevHooks, CombatInspector, CombatDebug et NativeQA. Le build QA séparé (`--qa`) reste destiné aux suites natives et active explicitement ses diagnostics. Aucun nouveau RemoteEvent d’écriture de combat n’a été ajouté.

## Lire puis modifier

1. [Matrice quatre personnages](../../FOUR_CHARACTER_COMBAT_MATRIX.md) : capacités, différences, couverture headless et checklist native.
2. [Contrats états/outils](../../current/COMBAT_CONTRACTS.md) : noms réels, axes indépendants, hooks et limites des mécaniques existantes.
3. [Mapping action→motion](../../current/MOTION_ATTACK_MAPPING.md) : 84 résolutions du renderer, origine des clips, aliases et timings de présentation.
4. [Inventaire JSON](../../current/COMBAT_INVENTORY.json) : IDs, MoveGraphs, ToolMastery, jutsu, awakening et throw overlays pour les scripts de contrôle.

Les interfaces sont déjà communes : `Combat`, `Brawler`, `Motor`, `VelmoraDefense`, `beginThrow/stepThrow/projectile*`. Les spécificités restent dans `Fighters`, `MoveGraphs`, `AttackProfile`, `ToolMastery` et les conversions de `Techniques`/`Brawler`. Aucune nouvelle couche générique n’a été construite.

Les contrats documentent notamment Neutral/Guarding/Stunned, les phases startup/active/recovery, Launched/Juggled/Knockdown/WallSplat/Wakeup/Grabbed/Bound, grounded/falling et les fenêtres de contre. OffBalance n’est pas un état distinct ; GuardBreak est un résultat de défense ; Clash est un événement suivi de Recovery. Ne pas créer de doublons en partant d’un terme de design.

Les hooks outils disponibles sont hold/release (`beginThrow/stepThrow`), spawn (`projectile`), impact/surface (`projectileHit/projectileSurface/onSurface`), sceau embedded (`Techniques.plant/anchors`), lookup en vol (`markedInFlight`), expiry/cleanup (`projectileExpire/removeProjectile/clear/expireSeals`) et conversions propres aux personnages. WireTrap existe ; smoke reste lié à la substitution ; aucun outil explosive-tag ou recall universel n’a été inventé.

## Motion Lab

Le laboratoire reste sous `games/ninja-duel/motion-lab`, sans dépendance du runtime envers le plugin. Ses moteurs/UI/bibliothèques artistiques sont conservés. Le binaire local est reconstruit, **sans installation, publication ni effacement des presets existants**.

Un défaut d’extraction est corrigé : `CLIPS.GentleFist` hérite d’Itachi et `CLIPS.Lion` de Minato, mais les anciennes itérations ne parcouraient que les clés directes. `NinjaSources.clipInheritance` et `metadata.motionClipSources` rendent ces héritages explicites ; l’adapter importe les poses existantes avec les timings du personnage concerné. Aucun clip du renderer n’est réécrit.

Dans Motion Lab : Characters → profil authored ; Motions → Common bilateral / Combat references ; Family puis L/R. Les 182 briques bilatérales et 120 variantes référencées restent accessibles. Une variante L/R disponible n’est pas nécessairement affectée à une attaque : le mapping distingue disponibilité et usage réel.

Créer/modifier une variante ou une copie du profil, exporter puis importer ses données validées. Le format reste `NinjaDuel.MotionDefinitions.v1` et `automaticApply=false`. Claude choisit l’intégration manuelle dans le renderer ; le plugin n’écrit pas les timings/dégâts du serveur.

```sh
lune run tools/combat_inventory.luau  # régénère mapping + inventaire
python3 motion-lab/build.py          # extrait les sources actuelles, teste et package
```

Après fermeture/sauvegarde de la session Studio personnelle, `python3 motion-lab/install.py` peut installer le binaire local selon le workflow existant. La nouvelle compatibilité n’est pas prétendue chargée dans une session qui utilisait encore l’ancien plugin.

## Validation et travail volontairement laissé à Claude

- 14 suites Ninja Duel, 139 cas déclarés PASS, dont 7 nouveaux cas de préparation couvrant les 16 matchups, read-only, phases, throws/expiry/cleanup, axes air/wall/réaction, défense et clash.
- Motion Lab : 45 cas PASS, dont roundtrip des quatre profils, L/R, héritages de clips et indépendance des edits. Smoke du binaire/UI PASS sous événements Studio simulés.
- Builds normal/debug/QA : sources embarquées vérifiées ; 4 tests d’isolation PASS. Le debug contient l’overlay et exclut NativeQA ; le normal exclut tout module de diagnostic.
- Frontières d’architecture PASS ; 9 tests de frontières et 7 tests de packaging Forge PASS ; freeze des cinq candidats Forge PASS.
- Les 36 sources runtime protégées (combat, mouvement, personnages, graphes, caméra, renderer, etc.) restent byte-identiques à `4bb3275`. Seuls Main.server (activation conditionnelle) et DevHooks (outillage optionnel) changent parmi les fichiers runtime préexistants.

Les résultats et hashes exacts figurent dans [TECHNICAL_PREPARATION_VALIDATION.json](../../current/TECHNICAL_PREPARATION_VALIDATION.json).

**Native Studio final : non validé.** Studio/Motion Lab ont pu s’ouvrir, mais les tentatives de pilotage de la place debug ont été interrompues par des changements de fenêtre. Cela ne vaut pas un test Play de l’overlay, ni une validation native du nouveau binaire Motion Lab. Les manifests gardent les gates native/visuel/contrôleur PENDING.

Claude doit encore juger les appuis, poses/aliases hérités, transitions visibles de Neji/Sasuke, contact/impact des paumes/lames, caméra, rythme, wall follow-ups, lisibilité de ShadowLeaf/LionBarrage, tool→melee et les timings ressentis. Pas de nouveau design de projectile-vs-projectile, OffBalance, GuardOpen, recall, smoke ou explosive-tag sous couvert de nettoyage technique. Aucun fichier n’a été supprimé faute de preuve d’inutilité.

Cette préparation est sur la branche `codex/ninja-claude-technical-prep`, dans un worktree isolé. Elle réunit la mission quatre personnages (`4bb3275`), Motion Lab référencé (`89a54f9`) et la séparation des workspaces (`564cbe6`). `main` et ses modifications locales préexistantes restent intacts. Lire le SHA final avec `git log -1 --format=%H` ; aucune fusion ou publication implicite n’a été réalisée.
