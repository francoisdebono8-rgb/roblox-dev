# Outils pour la prochaine passe Claude

Base : `claude/minato-itachi-final` 4df212c, avec la passe input ad8247c. Cette passe ne modifie ni Combat/Brawler/Motor/Matches/AI/World, ni Attacks/Fighters/MoveGraphs, ni Camera/Presentation/VelmoraMotionEngine. `reports/core-preservation.json` fournit les empreintes comparées à ad8247c.

## Utilisation immédiate

Ouvrir `dist/NinjaDuel.rbxlx`, lancer **Test**, puis **F6**. Le panneau est réservé à Studio, caché initialement. Il permet de changer chaque personnage, reset sans intro, remplir chakra/substitution, déclencher l’éveil, KO, dummy/IA, neuf situations et répétition. Une situation reconstruit le duel avec de nouveaux acteurs et une nouvelle époque : elle ne ressuscite pas un Humanoid mort. Les paramètres de gameplay ne sont pas changés. L’éveil QA place explicitement les PV sous le seuil pour appeler la véritable action.

Le panneau suspend les commandes du personnage pendant sa navigation. Fermer F6 rend l’input normal. Les boutons sont sélectionnables à la manette via la navigation Roblox ; F6 est pour l’outillage clavier. Aucune touche de combat supplémentaire n’est réaffectée.

**Volumes** affiche les racines en bleu et les véritables Parts `BanglaHitbox` en rouge, sans modifier leurs propriétés ni leurs collisions. Une boîte de startup n’est pas une confirmation de fenêtre active ; les projectiles/hazards n’utilisent pas cette Part. Désactiver cette vue pour mesurer le rendu sans adornments.

Command Bar, côté **Server**, après Test :

```lua
local dev=game.ServerStorage.NinjaDuelDev
print(dev:Invoke("tool","character",{first="Flashstep",second="Mirage"}))
print(dev:Invoke("tool","scenario",{name="launcher"}))
print(dev:Invoke("tool","repeat"))
print(dev:Invoke("tool","dummy",{enabled=false}))
print(dev:Invoke("tool","refill"))
print(dev:Invoke("tool","awaken",{actor="human"}))
print(dev:Invoke("tool","ko",{actor="bot"}))
```

Scénarios : `neutral`, `launcher`, `air`, `wall`, `substitution`, `grab`, `whiff`, `projectile`, `ko`. La situation mur teste une vraie surface à `World.WALL_RADIUS`, sans coordonnées périmées. Ces setups sont des reproductions d’état ; ils ne prouvent pas qu’un combo humain a été correctement exécuté.

Les hooks précédents `act`, `move`, `place`, `scripted`, `autopilot`, `state`, `damagelog` restent disponibles. Exemple de reproduction sans paquet Move idle concurrent :

```lua
local dev=game.ServerStorage.NinjaDuelDev
dev:Invoke("tool","scenario",{name="neutral"})
dev:Invoke("scripted",true)
dev:Invoke("act","human","Attack")
task.wait(.25)
print(dev:Invoke("state"))
dev:Invoke("scripted",false)
```

## Mesurer, puis attribuer

Activer **Mesures**, reproduire une séquence courte, cliquer **Rapport → Output**, puis désactiver. Command Bar : `dev:Invoke("tool","profile",{enabled=true})`, puis `dev:Invoke("tool","report")` et `dev:Invoke("tool","profile",{enabled=false})`.

Les sondes mesurent séparément temps CPU des méthodes, frame/Heartbeat, cadence et âge des snapshots, taille applicative estimée, corrections de séparation, sauts de position et écart position répliquée/présentée. Les événements contiennent états, attaques, warpSerial, commandes QA et intentions non-Move. Une intention enregistrée n’est pas nécessairement acceptée par le moteur. Aucun journal par frame ni nouveau paquet de combat n’est ajouté.

Les séries gardent 240 échantillons par mesure, 128 labels et 80 événements. Moyenne/max portent sur toute la capture ; p50/p95 sur les 240 derniers échantillons. Les wrappers sont retirés à OFF et à la destruction d’un duel. Le coût instrumenté inclut celui des sondes imbriquées : comparer aussi une capture sans instrumentation via MicroProfiler avant toute optimisation. Les scopes `NinjaDuel/server.*` et `NinjaDuel/client.*` sont accessibles dans MicroProfiler.

Un déplacement rapide avec changement de warpSerial peut être une substitution/téléportation prévue. Une frame longue n’identifie pas à elle seule le script responsable. L’écart présenté/répliqué inclut le délai de lissage voulu. Ne pas modifier les trajectoires pour faire disparaître un compteur.

`dist/NinjaDuel-DevQA.rbxlx` exécute les neuf setups, changement de personnage/refill/éveil, AI-vs-AI et capture des deux côtés. Il n’est jamais publié. La QA historique reste dans `NinjaDuel-QA.rbxlx`, séparée de ce smoke test outils.

## CLI locale

Depuis le dossier `games/ninja-duel` :

```sh
python3 tools/dev.py verify
python3 tools/dev.py build --kind main
python3 tools/dev.py build --kind dev-qa
python3 tools/dev.py release
python3 tools/dev.py audit --baseline ad8247c
python3 tools/dev.py compare
python3 tools/dev.py catalogue --archetype acrobatique
python3 tools/dev.py report --log /chemin/du/Studio.log
```

`release` vérifie puis construit main/QA/DevQA ; il ne publie, ne commit et ne pousse rien. Les binaires Luau/Lune doivent être installés ; utiliser `NINJA_DUEL_TOOLS`, `LUAU`, `LUNE`, `LUAU_COMPILE` ou PATH. Aucun téléchargement automatique. Les manifests dérivent la version de Config et enregistrent révision, branche, état des sources, empreintes et résultats. Un échec des tests conserve le précédent artefact. L’écriture de chaque fichier final est atomique.

L’export de rapport exige un fingerprint exact, un artefact identique au manifest et toutes les lignes begin/end ; il rejette une capture tronquée. Pas besoin de confondre les journaux de plusieurs Studio. `audit` est une vérification volontaire de cette passe ; Claude pourra choisir un autre baseline pour ses futures modifications de gameplay.

## Bases optionnelles

`lab/combat-library.json` : 33 briques, dix archétypes, variantes des quatre personnages. `lab/templates/` : personnage/moveset/éveil/projectile/grab. `lab/combat-tags.json` : taxonomie de travail. Aucun de ces fichiers n’est importé, exécuté ou enregistré dans le runtime. Les valeurs `null` sont à décider par Claude, pas des paramètres implicites.

`tools/dev.py compare` extrait les vraies tables actives et compare routes, outil, éveil, techniques et overrides. `reports/movesets.json` est une photographie générée, à régénérer après modification des données. Ne pas recopier des propositions dans les tables actives sans choix gameplay explicite.

## Online : préparation, OFF

`Shared/OnlineProtocol.Enabled=false`. Aucun bootstrap n’importe OnlineHost/OnlineMatch/OnlineQueue/OnlineValidation/OnlineReplication. Changer le flag seul ne lance aucun serveur online et n’altère pas le mode local.

Les modules fournissent FIFO/de-duplication, lobby/participants, match à deux joueurs serveur sans IA, validation d’intention/époque/séquence/horloge/aim/direction, budgets de requêtes, timeout de mouvement, enveloppe de réplication et curseurs d’impacts indépendants après envoi confirmé. Les dégâts/positions ne viennent jamais du client.

À fournir ultérieurement : factory d’arène/rigs serveur, nettoyage de cette arène, remotes séparés, sérialiseur d’acteur, tick/snapshot à cadence choisie et client à deux joueurs. Le client local nomme encore son adversaire `AIFighter` et attend `human/bot` : il ne doit pas être branché tel quel. Aucun matchmaking cross-server, rollback, compensation réseau ou déploiement online n’est revendiqué. `tests/Online.spec.luau` teste les contrats isolés, pas deux vrais clients réseau.

## Checklists avant intégration / commercialisation

Personnage : ID/routes résolues ; whiff/guard/dodge/substitution/grab break ; KO pendant saisie ; réveil et rounds ; cleanup des projectiles ; contrôle clavier/PS5 ; visibilité sans UI ; budgets CPU/VFX/payload mesurés ; aucune permission d’animation manquante.

Map : spawn des deux corps ; floor/wall/plafond réels ; tag NinjaWall cohérent ; sweep/occlusion ; wall tech/detach ; sorties et retours ; réception ; limites de caméra déjà prévues ; budgets parts/render mesurés sur appareil cible.

Online futur : deux clients propriétaires distincts ; serveur décide dégâts/état ; directions/aim/time validés ; anti-spam/replay ; impacts livrés aux deux ; disconnect/KO/cleanup ; queue leave/rejoin ; perte/latence/jitter ; aucun canal dev en production ; pas de partage d’état avec le mode local.

Sortie commerciale : identité/contenus et droits vérifiés ; permissions des assets dans l’expérience finale ; appareils cibles et réseau réel testés ; tutoriel ; résultat/rematch ; aucun build QA publié ; télémétrie de production choisie séparément ; rollback de version disponible. Ces listes sont des gates à remplir, pas une validation acquise par cette passe.

## Progression et collection, préparation isolée

Voir [le guide Claude](progression/README.md) : commandes `profiles` via le bindable serveur Studio, CLI avec sandbox DEV persistante, simulateur de packs et benchmark de profils. Aucun nouveau canal client ni branchement au combat. Le backend Roblox réel reste OFF.
