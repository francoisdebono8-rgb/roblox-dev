# Banc de test commun — Minato, Itachi, Neji, Sasuke

Cette matrice décrit le runtime présent, sans nouveau design. **H** = assertion headless existante ou ajoutée, **C** = présence inspectée dans le code, **N** = jugement natif/visuel encore à réaliser. H ne prouve ni qualité des poses, ni sensation du contrôleur, ni collisions du moteur Roblox. Le roster contient également Gaara : il reste intact, hors du périmètre artistique de cette passe, et sa suite continue de tourner.

| Axe | Minato (`Flashstep`) | Itachi (`Mirage`) | Neji (`GentleFist`) | Sasuke (`Lion`) |
|---|---|---|---|---|
| Loadability | H : tous les matchups du noyau | H : tous les matchups du noyau | H : tous les matchups du noyau | H : tous les matchups du noyau |
| Locomotion | Motor/Place1 communs ; vitesse et profil d’accélération propres | Même API ; rythme/stance propres | Même API ; profil paumes/Byakugan | Même API ; profil acrobatique |
| Neutral | H : `Combat.add/request`, retour Neutral après un whiff | H : idem ; neutral shuriken | H : idem ; neutral paumes/kunai | H : idem ; neutral shuriken |
| Taijutsu | H : chaîne M1 et `KneeStrike` après une confirmation | H : `CounterPalm`, routes de feinte | H : `PalmThrust`, fermeture de tenketsu | H : `KneeStrike`, routes de coups de pied |
| Launcher | H : ↑ après 2 confirmations → `Launcher`, sceau sur corps | H : `Launcher`, shuriken de couverture | H : `Launcher`, règles paumes | H : ↑ → `LionKick`, `ShadowLeaf` automatique |
| Aerial | H : moteur launcher/chase/air/slam ; variantes Rasengan | H : routes aériennes communes, couverture de lames | C : mêmes routes ; clips Air1/Air2 hérités d’Itachi | H : `ShadowLeaf` → `LionBarrage` ; plusieurs clips hérités de Minato |
| Wall conversion | H sur fixture moteur commune : splat/pin/bounce/tech ; N par perso | H sur fixture commune ; lames prolongent une pin | H : Vacuum Palm pousse vers un mur ; N des conversions visuelles | C : moteur commun + Chidori/wire ; N du wall follow-up |
| Defense | H : guard/parry/dodge/substitution communs | H : Sharingan, fenêtres propres, Read et punition | H : couverture Byakugan, angle mort, Rotation | H/C : défense commune ; pas de nouvelle défense spécifique |
| Counter | H : perfect dodge → riposte commune ; pas de Read spécifique | H : Read/parry/dodge → fenêtre et `CounterPalm` | H : Rotation ouvre `PalmThrust` | C : fenêtre commune/riposte ; aucun Read spécifique ajouté |
| Grab/throw | C/H moteur commun, throw break et cleanup | C/H : mêmes requests et liens grabVictim/grabbedBy | C : mêmes requests, clips hérités d’Itachi | C : mêmes requests, clips hérités de Minato |
| Projectile/tool | H : 1 kunai rapide ; sceau en vol/surface/corps via MarkedBlade | H : 2 shuriken, Geometry, ricochet, fan aérien | H : 1 kunai ; projectile VacuumPalm propre | H : 2 shuriken, PhoenixFlower et WireTrap |
| Jutsu | MarkedBlade, Flashstep, BurstStrike, Quickstep, WindCut | Read, NeedleFan, MirageCast, FireBloom, PhoenixFlower | Rotation, VacuumPalm, SixtyFourPalms | FireBloom, PhoenixFlower, WireTrap, Chidori |
| Awakening | C/H : Yellow Flash, modificateurs existants | C/H : Sharingan Focus, fenêtres/modificateurs | H : Byakugan Full Field | C/H : Curse Mark |
| Bugs connus | Aucun nouveau bug logique constaté par les suites ; N des sceaux, trajectoires et transitions de pose | N des angles/feintes, lisibilité des projectiles et caméra | Adapter hérité incomplet corrigé ; N des appuis et impact paumes | Adapter hérité incomplet corrigé ; N de ShadowLeaf/LionBarrage et appuis |
| Transitions manquantes / ambiguës | Pas d’état OffBalance dédié ; pas de recall générique | Pas de projectile-vs-projectile universel ; Geometry est spécifique | Pas d’état OffBalance dédié ; héritage visuel désormais explicite | Pas d’état GuardOpen dédié ; wire→Dragon Flame existe déjà |

Les différences restent dans `src/Shared/Fighters.luau`, `MoveGraphs.luau`, `AttackProfile`, `ToolMastery` et les conversions de `Techniques`/`Brawler`. Les API communes sont `Combat.add/request`, `Brawler.start/request/react/releaseGrab`, `Motor`, `VelmoraDefense`, `Combat.beginThrow/stepThrow/projectile*`. Caméra et présentation consomment les snapshots de `Matches` ; aucun moteur Forge historique n’est importé.

## Route de test commune

1. Construire `python3 build.py --debug`, ouvrir `dist/NinjaDuel-Debug.rbxlx`, puis **Play**. Le mode debug ne lance pas les tests destructifs de NativeQA.
2. Choisir chacun des quatre personnages dans le menu existant. Avec le Command Bar **côté serveur**, le même démarrage est accessible par `game.ServerStorage.NinjaDuelDev:Invoke("start", "GentleFist", "Lion")` (IDs ci-dessus).
3. Neutral : déplacement/sprint, lock/unlock, jump, guard, dodge ; un whiff doit revenir à Neutral. Observer les trois axes action/réaction/terrain.
4. Confirmer Light1 puis Light2, stick vers l’adversaire + Attack : observer Launcher (LionKick chez Sasuke). Chase/Pursuit, attaques aériennes, puis Heavy/Slam. Comparer confirmation et retour au sol, pas seulement le bouton accepté.
5. Mur : carry → WallSplat, pin, bounce, tech ; wall run → WallDive/rebound. Les fixtures headless ne valident pas à elles seules le contact visuel dans Studio.
6. Défense/counter : frappe contre guard, garde fraîche pour parry, dodge au contact puis riposte ; tester Read d’Itachi et Rotation de Neji séparément.
7. Clash : strikes simultanés en portée → événements Clash et Recovery. Projectile-vs-projectile : tester Geometry d’Itachi ; ne pas supposer qu’un arbitrage universel existe.
8. Tool mobile : inspecter hold/release, projectile actif, impact/surface/expiry, puis cancel de chaîne lorsque le MoveGraph l’autorise. Sasuke : wire → Bound → Dragon Flame. Minato : sceau en vol → Flashstep, et corps/surface après impact.
9. Grab/throw/throw break, awakening sous son seuil existant, remise en sélection puis redémarrage : aucun projectile/grab/sceau de l’ancienne session ne doit subsister.
10. Dans Motion Lab, modifier une **copie/variante du profil**, exporter ses données et comparer le mapping ci-dessous avant toute intégration manuelle.

Le panneau **F8** est masquable. `Invoke("inspect")` fournit la projection détaillée ; `Invoke("trace")` retourne les 80 dernières transitions échantillonnées. `workspace:SetAttribute("NinjaDuelDebugEnabled", false)` arrête la collecte et la diffusion. Aucun champ debug supplémentaire n’est envoyé dans les snapshots du build normal.

## Couverture et limites

`tests/Preparation.spec.luau` couvre les 16 matchups, le read-only, les phases d’attaque sur les quatre acteurs, hold/release/expiry sur les quatre, cleanup, réaction/air/wall/wakeup, défense/riposte et clash. Les suites `Branches`, `Phase4`, `Neji`, `Tools`, `Sasuke`, `Systems`, `Sequences` couvrent les conversions réellement présentes. Un test portant « every fighter » dans un ancien titre peut ne boucler que sur trois IDs : cette matrice ne l’étend pas implicitement à Sasuke.

Les routes longues et l’observation native de chaque personnage restent une checklist N, pas un PASS inventé. Les collisions de la fixture sont une approximation. Le lancement/contrôle Studio a été interrompu pendant cette passe ; le build debug final et son overlay nécessitent encore le smoke test natif décrit dans le handoff.

- [États et hooks outils](current/COMBAT_CONTRACTS.md)
- [Mapping des 84 actions/variantes](current/MOTION_ATTACK_MAPPING.md)
- [Inventaire machine-readable](current/COMBAT_INVENTORY.json)
- [Handoff technique Claude](current/CLAUDE_TECHNICAL_HANDOFF.md)
