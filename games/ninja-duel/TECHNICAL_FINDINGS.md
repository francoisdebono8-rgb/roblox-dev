# Constats techniques — passe outillage

## Problèmes confirmés et corrigés

| Priorité | Problème / reproduction | Correction et preuve |
| --- | --- | --- |
| P1 outillage | Un build écrivait `dist/NinjaDuel.rbxlx` avant les tests ; une suite en échec remplaçait donc le dernier artefact utilisable. | Publication après compilation/égalité/tests, écriture atomique par fichier. Test Python avec suite défaillante : place et manifest précédents conservés. |
| P2 diagnostic | Le client cherchait NinjaDuelDevLog dans Shared pendant 10 s avant de chercher le canal réel à la racine de ReplicatedStorage. Le jeu continuait, mais les diagnostics étaient aveugles au début. | Recherche directe du vrai canal ; aucun délai ajouté au combat. |
| P2 diagnostic | L’ancienne sonde marquait l’accélération de tête >900 comme « spike » sans distinguer pose, hitstop, transition et téléportation. | CPU/cadence/corrections/gap mesurés séparément, état/attaque/warpSerial enregistrés. Les événements ne sont pas étiquetés automatiquement « bug ». |
| P2 diagnostic | Le premier export JSON natif a été tronqué par Studio, au milieu d’une mesure, après environ 1 Ko. | Une ligne JSON courte par mesure/compteur/événement, begin/end et décompte. Test export >250 lignes : toutes valides et <1000 caractères. Le collecteur rejette captures tronquées ou mauvais fingerprint. |
| P2 robustesse QA | Le canal Studio acceptait des tables client non bornées ; les anciennes sondes restaient actives chaque frame. | Entrées dev allowlistées, quotas par joueur, télémétrie limitée en taille/profondeur/nœuds, mesures OFF par défaut et stockage borné. Le jeu publié ne crée aucun canal/menu dev. |

## Mesures natives réellement obtenues

Première QA outils : **12 PASS / 0 FAIL**, fingerprint `24d3b7b9bfe3a5af9546ca7fbbf97b842d0c6105f48db00101ca31ec0283dece`. Neuf situations, personnage/refill/éveil/repeat, capture client+serveur, retrait des wrappers. Douze secondes d’AI-vs-AI après les setups. Journal `0.742.0.7421053_20261011T004638Z_Studio_b19d8_last.log`.

Le rapport imprimé étant tronqué, seules cinq mesures complètes ont été récupérées dans `reports/preliminary-native.json` :

| Méthode / donnée | moyenne | p95 des derniers 240 | max de la capture |
| --- | ---: | ---: | ---: |
| Presentation.update | 0,978 ms | 2,496 ms | 7,443 ms |
| Presentation.impacts | 0,159 ms | 1,071 ms | 3,381 ms |
| Camera.update | 0,058 ms | 0,112 ms | 0,353 ms |
| UI.render | 0,162 ms | 0,351 ms | 1,323 ms |
| Âge du snapshot reçu | 35,34 ms | 42,28 ms | 146,15 ms |

Ces chiffres couvrent resets et combat dans Studio avec plusieurs instances ouvertes. Ils ne donnent ni le temps total de frame, ni le détail serveur, ni la physique/GPU. **Aucun goulet ni cause de snap du gameplay n’est donc prouvé ici.** Presentation.update est le poste le plus coûteux parmi les méthodes récupérées, pas une preuve qu’il provoque les saccades. Refaire une capture complète sur une seule instance, puis isoler neutral/mouvement/contact/air/mur/projetiles avant de corriger un système.

La capture **finale complète** a ensuite été récupérée et vérifiée : `reports/native-devtools.json`, fingerprint `bd189a8ad3c2d17986987d550dd710a44e0fb24a48b1928c2977daaecd9c6cb9`, artefact SHA-256 `c19fd03addef4769bcf3e8634dda75e9a6997f14e0a372a3ef7ae7ca18beff5e`. **12 PASS / 0 FAIL** et toutes les lignes d’export reçues. La fenêtre native a également affiché ce fingerprint, F6 a ouvert le panneau et le bouton reset a renvoyé `reset : OK`, avec retour au duel.

| Mesure finale | moyenne | p95 récent | max |
| --- | ---: | ---: | ---: |
| Combat serveur | 0,166 ms | 0,313 ms | 0,953 ms |
| Matches.update serveur | 0,224 ms | 0,538 ms | 1,275 ms |
| Destruction de duel QA | 15,14 ms | 21,94 ms | 21,94 ms |
| Frame client (temps total) | 17,24 ms | 19,72 ms | 141,37 ms |
| Presentation.update client | 0,909 ms | 2,689 ms | 6,944 ms |
| FX.update client (inclus dans Presentation) | 0,760 ms | 2,562 ms | 3,934 ms |
| Caméra client | 0,056 ms | 0,092 ms | 0,190 ms |
| Gap entre snapshots serveur | 58,82 ms | 82,63 ms | 125,96 ms |
| Gap entre snapshots client | 67,86 ms | 87,19 ms | 228,67 ms |

**Attribution observée :** les douze événements de frame >50 ms sont concentrés dans les huit premières secondes, pendant les reconstructions QA. Le rebuild d’arène/rigs est donc corrélé aux spikes ; le coût de destruction seul ne mesure pas tout le coût de création/physique/rendu. Le reset reste rapide pour un humain mais n’est pas un reset sans coût de frame. Pour l’optimiser plus tard, mesurer création d’arène et spawn séparément, puis décider d’un reset QA réutilisant l’arène, sans toucher au reset des rounds du jeu.

Pendant les douze secondes de combat après les setups, les méthodes serveur sont peu coûteuses dans cette capture. Les VFX représentent environ 84 % de la moyenne de Presentation.update, avec des scopes imbriqués : priorité d’inspection concrète côté client, **pas une preuve de dépassement du budget de frame par les VFX**. Une vraie passe GPU/physique/appareil cible reste nécessaire avant d’optimiser.

Deux grands déplacements sont contextualisés : 20,21 studs en échantillonnage serveur durant Pursuit, puis 13,37 studs côté client en TechniqueActive avec warpSerial passant de 1 à 2. La seconde est une téléportation annoncée ; la première est un déplacement de poursuite rapide à investiguer seulement si visuellement incorrect. Aucune correction de moteur n’a été introduite pour masquer ces signaux. La séparation existante a été observée 276 fois, correction totale max 0,35 stud par tick ; ce n’est pas une autorisation de changer les distances de combat.

Aucun watchdog overdue-state ni script-error n’a été remonté dans la capture. Le panneau et reset ont un smoke visuel, mais la navigation matérielle PS5 et la vue de volumes ne sont pas revendiquées comme validées. Les anciens tests généraux en échec restent distincts de ce PASS outillage.

## Dette critique de validation déjà présente

La QA native historique de la passe input avait **28 PASS / 9 FAIL** sur son artefact exact (`b6b7834f...`). Cela ne prouve pas neuf bugs actuels. Les tests ci-dessous doivent être réalignés aux vrais setups ou investigués :

- Mur : NativeQA utilise x=76 et x=24 alors que World.WALL_RADIUS=103 et l’arène est circulaire. La situation dev `wall` a effectivement passé contre une surface native réelle.
- Feinte de technique : le test utilise Minato Technique1 ; la technique Feintable actuelle est Itachi FireBloom (Technique4). La donnée du test est périmée.
- Restants : Fire/Wind, interruption de tous les channels, chip/backside/guard break, anchor sur floor, interruption IA, impact hors portée. Reproduire séparément avec le menu et l’état serveur avant de qualifier la cause ou modifier le gameplay.
- Les animations donor Bangla non publiées avaient des refus d’accès 403 dans l’ancienne QA générale. Le mode procédural actif est conservé. Ne pas les activer silencieusement ; vérifier les permissions dans l’expérience finale si Claude décide de les utiliser.

Le smoke outils est séparé de cette QA générale ; un PASS outils ne valide pas toutes les mécaniques, le rendu ou le feel manette. Les warnings de style du Roblox Studio et `Player:Move` sans personnage au démarrage observés dans le premier journal ne sont pas attribués à un bug de combat.

## Conservation et prochaine action utile

`reports/core-preservation.json` compare 16 fichiers centraux au début de cette passe (ad8247c) : tous identiques. Les différences précédentes d’input par rapport à Claude 4df212c restent la passe input autorisée ; elles ne sont pas une modification gameplay de cette mission.

Le prochain travail technique utile est de comparer des captures courtes mono-situation et appareil cible, sans les reconstructions QA, avec `Report`. Les briques online sont OFF et non importées. La bibliothèque `lab/` et ses templates restent des propositions. Voir DEVTOOLS.md pour reproduire et extraire les rapports.
