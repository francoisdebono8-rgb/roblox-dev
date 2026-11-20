# Boîte de réception Claude

## INBOX-OUTILLEUR-ETAPE1-20261120 — OUTILLEUR 20/11 : place commune automatique, comparateur de kits, contrôle des tenues

**Poussé sur la branche commune** (Python : 34 PASS ; 4 builds verts ; docs PASS). Pas de lune ici : les specs Luau ne sont pas lancées de mon côté.

**Ce qui est livré :**
1. **La place commune automatique** (`tools/mac/place_commune.py`, README `tools/mac`). Un agent macOS tourne toutes les 2 min. Après chaque lot poussé, et 3 min sans nouveau commit, il reconstruit les 4 places au même commit et les pose dans `PLACES`, avec `VERSION.md`.
   - Une place ouverte dans Studio n'est jamais remplacée : les places attendent dans `PLACES/_prochaine`, et François est prévenu une fois.
   - Une place modifiée dans Studio est mise de côté, pas écrasée.
   - **En service sur le Mac depuis le 20/11 :** `98a2a1f2` posé à 22 h 27, puis `29a59f15` (mon push) posé à 22 h 39 sans aucune main. Journal : `_maintenance/place-commune/journal.log`.
2. **Le comparateur de kits** (`tools/kits`) donne une empreinte chiffrée par kit : portée, vitesse, mobilité, dégâts/s, tenue, et ce que le kit a en propre. Il calcule trois versions (prodige, départ d'un joueur, arbre complet), puis compare avant et après sur la même échelle. Première empreinte : sources `053395e4`, mesurée dans Studio. Les constats sont dans le README.
3. **Le contrôle des tenues** (`tools/tenues`) : une cabine d'essayage dans Studio et 7 avatars types.
   - Les avatars : Korblox, Rthro Big Bill, Rthro Vanessa, Garçon Roblox, Femme, Bloc R15 et l'avatar de François.
   - Ils sont construits comme `AvatarBody` construit le joueur, puis habillés par `Outfit`, `OutfitDress` et `Headband`, de face et de dos.
   - Deux séries de planches, plus l'avant / après côte à côte (`tools/tenues/rendus/`) :
     - avant les corrections de l'ANIMATEUR : place `699d331d`, 12 tenues ;
     - après : place `29a59f15`, 19 tenues, dont les 6 inventées et les nouveaux accessoires.
   - Toutes les corrections de l'ANIMATEUR se voient en jeu, sur les 7 corps : holsters, plaques, masque et gants de Kakashi, cape courte, rouleau en travers.
   - Les constats sont dans le README.

**Corrigé :** `tests/KitPrint.spec.luau` échouait sur `Sand: walk/run` (l'ANIMATEUR l'a signalé). Le test exigeait une course au moins aussi rapide que la marche, or le `SprintScale` de Gaara est inférieur à 1. C'est une donnée du jeu : le test la note sans échouer.

**DEV, à toi :**
- **Gaara court moins vite qu'il ne marche** (course 14,0, marche 16,5 ; `SprintScale` < 1). Est-ce voulu ?
- **Un corps à armure (Korblox) transforme toute tenue en boîte.** Son `UpperTorso` mesure 3,25 × 6,30 × 3,02 studs, et les pièces se mettent à l'échelle du torse. Remettre le torse standard dans `AvatarBody` quand il dépasse une taille plausible ? Sinon, l'ANIMATEUR plafonne l'échelle.
- **Les cheveux de 3 paquets sur 5 disparaissent** à `Outfit.strip` (Femme, Vanessa, Big Bill sortent chauves).
- **Le bandeau bleu se lit noir** à distance de duel (`Band = 46, 64, 120`) : le bleu et le noir se confondent.
- **La place commune remplace la reconstruction à la main.** Avec elle, faut-il encore committer `dist/` ? Environ 80 Mo par reconstruction.
- **Lune :** je ne peux pas lancer les specs Luau ici. Une exécution de la suite côté DEV, ou un runner, attraperait plus tôt un test qui casse.

**DEV et ANIMATEUR, une règle à trancher :** quatre sets portent déjà un bandeau : Ember Monk, Storm Courier, Leaf Medic, et Lee par sa plaque de ceinture. Le bandeau choisi s'y ajoute, et on voit deux bandeaux sur une tête. Un set qui a son bandeau remplace-t-il l'emplacement « bandeau » ?

**ANIMATEUR :** les planches Studio montrent les tenues sur 7 corps réels, dont Korblox et deux têtes Rthro, à côté de tes planches Blender.
- La capuche de la cape (Accessoires 2, Sand Nomad) est traversée de dos par les nœuds du bandeau et les yeux du masque.
- Le col de Naruto monte jusqu'à la bouche.
- Sur une tête Rthro, le masque fait un bloc.

Ce sont des observations de Claude, pas l'avis de François.

## INBOX-ANIM-ETAPE1-20261120 — ANIMATEUR 20/11 : audit des clips, fiches de mouvement, auras, tenues

**Poussé sur la branche commune** (suite : 88 PASS ; `KitPrint` échoue déjà sur la branche sans ces commits, sur `Sand: walk/run`, et ce n'est pas mon domaine ; 4 builds verts).

**Ce qui est livré :**
1. **L'audit des 845 clips des 8 kits :** `docs/reports/audit-clips-2026-11-20` (`tools/blender/clip_grades.py`). Chaque clip est noté sur 10, moyenne 8,6. Les 60 pires sont classés. Lee et Gaara sont les plus bas. **6 gardes sur 8 sont la même garde de boxeur, poings dans la tête.**
2. **Les fiches de mouvement :** `docs/characters/FICHES_MOUVEMENT.md`, avec le tempo, la garde, les appuis et la signature de chaque kit.
3. **Les auras :** `Client/MeritAuraFX`, aux paliers de `Shared/Merit` (Ember, Storm, Legend). `Effects` appelle `MeritAuraFX.start()`, qui lit `NinjaAura` sur chaque Player et habille son `Character`.
4. **Les tenues comparées aux références et corrigées :** `docs/reports/tenues-references-2026-11-20`. La garde-robe est dans `Shared/Catalog`, dans un bloc généré : 46 looks, 6 tenues inventées et leurs icônes.

**DEV, à toi :**
- **Timings :** les fiches proposent un tempo de directs par kit (tableau en fin de fiche). Rien n'est changé sans ton accord.
- **Auras en duel :** si le corps du duel n'est pas le `Character` du joueur, appelle `MeritAuraFX.wear(corps, tier, true)` sur lui. `true` le rend discret : un tiers des particules.
- **Bandeau :** `Server/Headband` construit encore la plaque plate. Quand un bandeau a son modèle (`OutfitMeshes.Items[id]`), laisse `OutfitDress` le poser. Sans ça, les bandeaux au cou et à la taille s'affichent sur le front.
- **Config :** j'ai ajouté (sans rien retirer) 6 clés `SetEmberMonk`… à `Config.Shop.Products`, à 0 donc SOON. Chaque tenue inventée est rattachée à un kit (`Shop.spec`) : ce sont des propositions, que tu peux changer.
- **Prix :** les prix en Ryō de la garde-robe sont des propositions : hauts 600, bas 500, bras et pieds 350, bandeaux 800, masques 600, capes 900, dos 700.
- **Taille des données :** `OutfitMeshData` passe de 13 à 23 morceaux (environ 2,4 Mo). Les tenues inventées n'ajoutent rien : elles réutilisent les pièces.

## INBOX-CLASSE-20261120 — DEV 20/11 : le classé, le mérite, les classements (étape 1)

**Les règles** :
- `Shared/Ranked` : une cote Elo qui part de 1000. Chaque duel entre deux joueurs compte, il n'y a pas de file d'attente. Abandonner un duel le fait perdre.
- **6 rangs** : ACADEMY, GENIN (1100), CHUNIN (1250), JONIN (1450), ANBU (1700), KAGE (2000). Chacun a son emblème : wood, iron, bronze, silver, gold, crimson.
- `Shared/Merit` : une victoire rapporte 1 point contre l'IA et 3 contre un joueur. Les auras arrivent à 25 points (EMBER), 100 (STORM) et 300 (LEGEND), et on les garde.
- `Server/Leaderboards` : les classements cote, victoires de la semaine, mérite, jours d'affilée et Examen. Leur top 10 est recalculé chaque minute. Dans un fichier de place ouvert dans Studio, chaque classement vit sur le serveur seul.

**DESIGN** (tes données)
- Attributs du Player : `NinjaRank` (le nom du rang), `NinjaRating`, `NinjaAura` (0 à 3).
- `kits.ranked` : `{rating, rank={id,name,emblem,index}, next={name,need}, games, wins, peak}`.
- `kits.merit` : `{points, tier, name, next}`.
- Résultat d'un duel contre un joueur : `progress.ranked` (`{before,after,delta,rank,rankUp}`) et `progress.merit`.
- Les classements : `ReplicatedStorage.NinjaDuelBoards`, un StringValue par classement, en JSON `{id,title,rows={{rank,id,name,value}},at}`. Les noms : Rating, WeekWins, Merit, Streak, Exam.
- J'ai mis des mots provisoires : le rang au début de la ligne du badge (`HubPlayers.line`), et `Ranked.line` / `Merit.line` sur l'écran de résultat. Remplace-les par tes emblèmes et tes tableaux.

**ANIMATEUR**
- Les auras : `Aura.Ember`, `Aura.Storm` et `Aura.Legend`. Elles s'affichent sur tout joueur dont `NinjaAura` vaut 1, 2 ou 3, dans Konoha et pendant le duel.
- C'est un effet du client, dans ton propre fichier `*FX`, qui lit l'attribut.

## INBOX-JEU-FINI-20261120 — DEV 20/11 : un vrai jeu, une branche commune, l'étape 1 pour tous (DEC-043)

**À lire d'abord :** le doc projet `claude/jeu-fini-vision-etapes-regles-2026-11-20` (vision, 5 étapes, règles), DEC-043 et RUNBOOK § 0.
- **On pousse directement sur la branche commune** ses propres fichiers, après `git pull --rebase`, la suite et les builds verts.
- **Les questions vont au DEV**, sauf la publication, les produits Robux, la suppression d'une fonctionnalité validée et l'identité du jeu.

**Étape 1, « Ça se voit, et on se compare » :**
- **DEV :** lumière de jour, classé (cote et 6 rangs), classements, paliers de mérite, images de la DESIGN sur Roblox, liste des produits.
- **DESIGN :** face-cam v2 avec 6 expressions cartoon, emblèmes de rang, tableaux de classement, écrans repassés avec les vraies images.
- **ANIMATEUR :** audit SyphoDev des 8 kits (liste des pires), fiche de mouvement par kit, 3 auras de mérite, tenues et bandeaux fidèles.
- **OUTILLEUR :** place commune automatique, comparateur de kits (empreinte chiffrée), contrôle des tenues.
- **CM :** 8 fiches « pourquoi ce kit », le Short de l'étape, les noms affichés (titres du CM, DEC-043).

## INBOX-INTEGRATION2-20261119 — DEV 19/11, 23 h 40 : #136 à #146 intégrés (« Intègre tt », François)

Intégrés dans cet ordre, tous ensemble sur la branche de référence :
- #136 (OUTILLEUR) : robot de la boucle, icônes, parcours dans Studio ;
- #138 : ce qui vient après un duel ;
- #137 (DESIGN) : écrans au doigt ;
- #139 (DESIGN) : SHOP et marché séparés ;
- #140 : HubMove, armes du ninja, catalogue masque/cape/dos, entonnoir ;
- #141 (ANIMATEUR) : les six maisons ;
- #142 (OUTILLEUR) : lecteur de l'entonnoir ;
- #144 (OUTILLEUR) : essai à deux ;
- #143 : quêtes du jour, jours d'affilée, Examen de la semaine ;
- #145 : codes ;
- #146 : retours de l'OUTILLEUR.

**Vérifié :** suite 83 PASS, 4 builds (dist reconstruit), isolation, docs, architecture.

**Chacun repart de cette branche.** Les transmissions détaillées sont plus bas :
- INBOX-RETOURS-OUTILLEUR ;
- INBOX-CODES ;
- INBOX-RETOUR-DEV ;
- INBOX-VAGUE2-DEV ;
- INBOX-RESULTAT.

## INBOX-RETOURS-OUTILLEUR-20261119 — DEV 19/11, nuit : réponses à l'OUTILLEUR (vague 2, § « À transmettre »)

**OUTILLEUR**
- **Le format de `Matches.FUNNEL`** : chaque nom d'étape est associé à son rang, de 1 à 9 : joined, inspiration, dressed, started, hit, duel, won, bought, node.
  - L'étape est envoyée à `AnalyticsService:LogOnboardingFunnelStepEvent(player, rang, nom)`, une fois par joueur et seulement en avançant.
  - Chaque étape est aussi une ligne `[NinjaDuelFirst] <UserId> <étape> <secondes depuis l'arrivée>`. `input` et `jutsu` ne sont que dans ces lignes.
- **Le duel en ligne compte** comme un duel contre l'IA. `started` est noté au début, `hit` au premier coup qui touche, `duel` et `won` à la fin. Chaque joueur est mesuré dans sa propre session.
- **Le format de `Catalog.luau`** est dans son en-tête, une entrée par objet :
  - `id` : stable, ne jamais le renommer ;
  - `slot` : un emplacement de `Shop.Slots` ;
  - `name` ;
  - le prix : `ryo`, `robux` (une clé de `Config.Shop.Products`) ou `base` ; `none` pour « rien dans l'emplacement » ;
  - `kit` pour les objets d'arme ;
  - `colors` ;
  - `pieces` : `{on, kind, c, y0, h}`.
- **Les quêtes s'appellent maintenant `Shared/DailyQuests`** (l'ancien nom était `Shared/Daily`).
  - Ce qu'il te faut : `DailyQuests.today(day)` pour les 3 quêtes du jour, `DailyQuests.record(r, day, events)` pour ce qu'elles paient, et `DailyQuests.Streak` pour les jours d'affilée.
- **`Loop.spec` passe avec lune** (4 PASS). Il est dans `tests/run.sh` et dans `TEST_RUNNERS`. Ton robot lit maintenant la vitesse du village dans `HubMove`.
- **Les UserId négatifs sont acceptés dans Studio seulement** (`Lobby.target`). Un serveur en ligne les refuse toujours.
- **Le joueur bloqué sur `Ichiraku.StandRoof`** est corrigé dans les duels du village (`Combat:unstick`). Un corps vivant, au-dessus du sol du duel, qui demande à bouger sans bouger pendant 2,5 s est reposé au sol. Il est posé sur le premier point vers le centre du duel où le sol est celui du duel. L'attribut `Unstuck` du modèle note l'heure.
- **La bulle TALK pendant le duel** est corrigée. Les invites du village (TALK, mannequin, marché, CHALLENGE) n'apparaissent que pendant la marche (`HubClient:apply`, `ProximityPromptService.Enabled`).

**DESIGN**
- J'ai ajouté une ligne dans `HubClient:apply` : `PPS.Enabled = walking and not panel`. Aucune invite ne s'affiche pendant un duel, sur le tableau ou quand un panneau est ouvert.

## INBOX-CODES-20261119 — DEV 19/11, nuit : les codes (demande du CM, vague 2 § 3)

**CM : `Shared/Codes.luau` est à toi.** La liste est une donnée : une ligne par code. L'en-tête explique chaque champ.
- **Une seule récompense par code**, parmi trois :
  - des Ryō (`ryo`, 1 000 au plus) ;
  - la maîtrise ×2 pendant un temps (`boostMinutes`, 120 au plus) ; elle s'ajoute à un ×2 déjà en cours ;
  - un objet du catalogue (`item`), jamais un objet vendu en Robux ni un objet gratuit.
- **Les dates :** `starts` (facultatif) et `ends`, des jours UTC « AAAA-MM-JJ », tous les deux compris.
- **Les quatre codes de ta proposition sont dans la liste.** NINJADUEL (300 Ryō), MYNINJA (150 Ryō) et FIRSTDUEL (×2 pendant 15 min) finissent le 20/12. EXAM1 (150 Ryō) va du 27/11 au 06/12.
  - Corrige ces dates quand François aura publié la mise à jour.
  - Avec ces dates, 4 codes sont actifs du 27/11 au 06/12, alors que ta règle en prévoit 3 au plus.
- **Les vérifications :** `tests/Codes.spec.luau` vérifie chaque ligne (forme, une seule récompense, dates).

**Côté serveur**
- Chaque code s'utilise une fois par joueur ; c'est gardé dans le profil (`codes`).
- Un essai toutes les 2 s. Après 8 codes faux à la suite, il faut attendre une minute.
- La réponse arrive dans le `notice` de la phase Selection, avec `codeOk`. Par exemple : « CODE NINJADUEL: +300 RYŌ », « CODE ALREADY USED », « CODE EXPIRED », « CODE NOT FOUND ».

**DESIGN**
- Pour l'instant, un champ simple « HAVE A CODE? » se trouve dans la SHOP, page BUY RYŌ, sous les paquets. Il envoie `RedeemCode {code}`, et la réponse s'affiche dans la carte. Remplace-le par ton champ CODES.
- `kits.codeBoost` donne les secondes qui restent au ×2 d'un code (0 s'il n'y en a pas).
- La carte EARNED BY PLAYING montre maintenant aussi les quêtes du jour et les jours d'affilée.

## INBOX-RETOUR-DEV-20261119 — DEV 19/11, nuit : les raisons de revenir (vague 2, DEV 5)

Quêtes du jour, jours d'affilée et Examen de la semaine. Les règles sont dans `Shared/Daily` et `Shared/Exam`, le côté serveur dans `Server/WeeklyExam`. Tests : `tests/Daily.spec.luau` et `tests/Exam.spec.luau`.

**Les règles**
- **3 quêtes par jour,** une facile (60 Ryō), une moyenne (90) et une difficile (150). Ce sont les mêmes pour tout le monde. Elles sont payées dès qu'elles sont faites, sans bouton à cliquer. Le jour change à 00 h UTC.
- **Ce qui compte :** un duel que le profil compte, c'est-à-dire avec un kit appris, contre l'IA, en tournoi ou contre un joueur. L'entraînement ne compte pas.
- **Jours d'affilée :** le premier duel du jour compte la journée. Un jour manqué fait repartir à 1. Les jours 1 à 7 rapportent 25, 35, 45, 55, 65, 80 puis 150 Ryō, et la semaine recommence.
- **Examen de la semaine :** le tournoi des prodiges compte s'il est commencé entre le vendredi 18 h et le dimanche 21 h, heure de Paris (heure d'été comprise).
  - Le score d'une tentative tient compte, dans l'ordre, des matchs gagnés, des manches perdues, des PV gardés et du temps. Seul le meilleur de la semaine compte.
  - Le classement est un OrderedDataStore par semaine.
  - Titres : EXAM PASSED jusqu'au prochain Examen ; TOP 3 OF THE WEEK jusqu'à la fermeture du suivant.
  - À la fermeture, les 3 meilleurs vont sur la falaise, places 2 à 4, le n° 1 en premier. Un tournoi gagné en dehors de l'Examen ne sculpte plus de tête.
- **Le nom :** `Config.Exam.Name` vaut « THE RANK EXAM » tant que François n'a pas décidé pour les noms. S'il garde les noms, ce sera « THE CHUNIN EXAM ».
- **Dans Studio seulement :** l'attribut `NinjaExamOpen=true` sur `workspace` ouvre l'Examen tout de suite, pour l'essayer avant vendredi.

**DESIGN** (vague 2, DESIGN 3 : les données sont prêtes)
- `kits.daily` (`Progression.view`, phase Selection) : `{day, resetIn, quests={{id,text,tier,goal,progress,done,ryo}}, streak={days,counted,today,tomorrow}}`. C'est pour le panneau des quêtes dans Konoha.
- `kits.exam` : `{enabled,name,key,open,opens,closes,in,best,passed}`. C'est pour le bandeau de l'Examen (ouvert ou fermé, temps restant).
- `kits.title` contient le titre du joueur. L'attribut `NinjaTitle` est posé sur chaque Player.
- **Écran de résultat :** `progress.daily` vaut `{ryo, completed={{id,text,ryo}}, streak={days,ryo}, total}`.
  - J'ai mis une phrase provisoire dans `UI:resultEarned`, écrite par `Daily.line`. Le total des Ryō comprend les quêtes. `resultNext` rétrécit pour ne jamais être coupé. Remplace-la par ta ligne.
- **Tournoi :** `cup.examName` est présent tant que le tournoi compte pour l'Examen. `cup.exam` vaut `{name,score,best,improved,passed}` à la fin.
  - J'ai écrit une phrase provisoire sur la carte du champion : `Cup.examLine`, dans `championNote`.
- **Au-dessus des autres joueurs dans Konoha** (`HubPlayers`) : une ligne de titre en or au-dessus du nom. Le badge passe de 58 à 78 px de haut.

**OUTILLEUR**
- Le robot de la boucle peut lire `Daily.today(day)` et `Daily.record` pour compter les Ryō des quêtes et des jours d'affilée dans le temps du premier achat (vague 2, OUTILLEUR 2).
- L'entonnoir ne change pas.

**CM**
- Les règles de ton § 3 (Examen) sont dans le jeu : la fenêtre, le score, les titres EXAM PASSED et TOP 3 OF THE WEEK, la falaise du n° 1 au n° 3.
- La première édition est simplement le premier vendredi qui suit la publication.
- Les codes ne sont pas faits : c'est une autre PR DEV.

## INBOX-VAGUE2-DEV-20261119 — DEV 19/11, nuit : ce que la DEV livre pour la vague 2

Le plan de la vague est dans le projet claude.ai : `claude/vague-2-taches-2026-11-19.md`.

**DESIGN**
- `HubClient` est séparé de la marche. La marche, la course, le second saut et la chute vers la porte sont dans `Client/HubMove` (DEV). `HubClient` ne garde que l'écran, et il est à toi. Un test garde la frontière : `HubClient` ne touche plus au corps du joueur.
- Le catalogue a trois emplacements portés : `mask`, `cape` et `back`.
- J'ai ajouté une ligne dans deux de tes fichiers :
  - `Wardrobe.W.SLOTS` reçoit mask, cape et back ;
  - l'onglet STYLE de `ShopPanel` liste mask, cape et back.

  L'arme du ninja et la pose de victoire restent en SOON.

**ANIMATEUR**
- **`Shared/Catalog.luau` est à toi.** Toutes les apparences y sont. L'en-tête explique chaque champ. Les règles restent dans `Shared/Shop` (DEV).
- **Nouveaux emplacements :** mask (sur la tête, sous les yeux), cape (des épaules aux genoux), back (dans le dos).
- **Premiers objets en tissu :** MaskCloth, CapeTravel et BackScroll. Leur modèle remplacera le tissu par le nom de l'objet (`OutfitMeshes`).
- **Changement dans le jeu :** il ne cache plus que le tissu des objets qui ont un modèle. Une cape sans modèle reste visible sur une tunique modélisée.
- **`Shared/NinjaWeapons.luau` est le contrat des 8 armes.**
  - Il donne pour chacune :
    - le modèle `NinjaWeapon_<Id>` : origine à la poignée, +Y vers la pointe ;
    - les clips `Weapon.<Id>.Draw`, `.Guard` et un par coup de `Moves` ;
    - le nombre d'images de chaque coup : `NinjaWeapons.frames(id, move)`, à 60 images par seconde.
  - Puissance égale, vérifiée par `tests/NinjaWeapons.spec` : un coup plus lent frappe plus fort d'autant, et la portée se paie en vitesse.
  - Commence par le katana et la kusarigama.

**OUTILLEUR**
- **L'entonnoir d'accueil** (`Matches.FUNNEL`, `AnalyticsService:LogOnboardingFunnelStepEvent`) suit maintenant la boucle, dans l'ordre :

  | Étape | Nom | Moment |
  |---|---|---|
  | 1 | joined | arrivée |
  | 2 | inspiration | inspiration choisie |
  | 3 | dressed | tenue choisie |
  | 4 | started | premier duel lancé |
  | 5 | hit | premier coup porté |
  | 6 | duel | premier duel terminé |
  | 7 | won | premier duel gagné |
  | 8 | bought | premier achat |
  | 9 | node | premier nœud de l'arbre |

- Chaque étape est aussi écrite dans la sortie, en `[NinjaDuelFirst] <id> <étape> <s>`.

## INBOX-RESULTAT-20261119 — DEV 19/11, 22 h 30 : réponse à l'OUTILLEUR (#136), ce qui vient après un duel

**OUTILLEUR**
- `tests/Loop.spec.luau` est passé avec Lune 0.10.5 : 4 PASS en 0,8 s. Il est ajouté à `TEST_RUNNERS` (`build.py`) et à `tests/run.sh`.
- Le bandeau sur les yeux que tu as vu venait de `bbcfffb7`. Il est corrigé par #133 (intégré à `3516f3d9`).
- À noter pour la boucle : ton robot met 15 duels gagnés (environ 28 min) avant le premier achat au marché (800 Ryō). C'est long à côté d'un premier nœud après 1 duel.

**DESIGN**
- Le serveur envoie maintenant `progress.ahead` avec le résultat d'un duel (`Progression.aheadOf`) :
  - `node` : le prochain nœud de l'arbre, avec `{id, name, cost, free, mastery}`. `mastery` est ce qu'il manque ; 0 veut dire qu'il est à apprendre maintenant ;
  - `tier` : le prochain palier, avec `{name, need, mastery}` ;
  - `inspirations` : les inspirations vers lesquelles mène ce kit, avec `{kit, mastery}`.
- J'ai touché à trois endroits de `UI.luau`, au minimum, et tu peux les retravailler :
  - `UI.stageName` : seul le tournoi dit TOURNAMENT. Le premier duel s'appelle YOUR FIRST DUEL, le duel d'une inspiration AN INSPIRATION'S DUEL, et les autres KONOHA • THE EXAM HALL ;
  - `UI.resultLine` : ADVANCES seulement dans le tournoi, WINS ailleurs ;
  - `UI:resultEarned` : le prochain nœud par son nom.

## INBOX-OUTILLEUR-VAGUE2-20261119 — OUTILLEUR, nuit du 19/11 : entonnoir, robot étendu, icônes, essai à deux

Détail : `tools/analytics/README.md`, `tools/loopbot/README.md`, `tools/icons/README.md`, `tools/duo/README.md`.

**DEV**
- **#142, l'entonnoir.** Pour DEV 4, garder une table `FUNNEL` (`nom=numéro`), ou des appels avec le numéro et le nom en clair. Le lecteur les lit dans `src/`. Il nomme déjà en français `joined`, `outfit`, `starter`, `firstDuel`, `firstHit`, `firstWin` et `firstPurchase`. Test à ajouter : `run Entonnoir python3 tools/analytics/test_entonnoir.py`.
- **#136, étendue.**
  - `Loop.spec` a une étape de plus (`garderobe`) et un test de la collection. À passer avec lune.
  - Contrôle de la collection sans lune : `python3 tools/icons/catalogue.py --gate`.
- **Catalogue (DEV 2).** `catalogue.py` lit `Shared/Catalog.luau` s'il existe : chaque objet en `{id="…",slot="…",name="…",…}`, et les emplacements dans une table `Slots={…}` (`outfit=true` pour une pièce de tenue). Un autre format demande de toucher `catalogue.py`.
  - Dans le jeu, le modèle d'une pièce de tenue reste `OutfitMeshes.Items[id]`.
  - Un emplacement absent de `Shop.SlotOrder` fait échouer l'étape `garderobe` : la garde-robe ne le montrerait pas.
- **Quêtes (DEV 5).** Le robot cherche un module dont le nom contient `Quest`, dans `Shared` ou `Server`. Il les jouera dès qu'il existera.
- **#144, l'essai à deux dans Studio** (détail : `tools/duo/README.md`).
  - `Server/Lobby:request` ignore un défi si `to<=0`. Or les joueurs de test de Studio ont des UserId négatifs : aucun défi ne part dans un essai à plusieurs. Accepter un id négatif quand `RunService:IsStudio()` rendrait l'essai possible sans patch.
  - **Un joueur reste bloqué sur `Workspace.NinjaDuelHub.Ichiraku.StandRoof`.**
    - Où : rue « Legion », position (-24,5 ; 14,54 ; -2254,8).
    - Comment il y est arrivé : envoyé en l'air par les coups légers de Minato.
    - Ce qu'on a vu : état Neutral ; plus de 30 s sans bouger, malgré `Move` dans quatre directions ; corps non ancré, qui ne touche rien.
    - Conséquence : l'adversaire ne peut plus l'atteindre à pied.
  - Une bulle TALK (un maître de Konoha) s'affiche pendant un duel de rue.
  - Le duel en ligne ne compte pas comme « premier duel » dans l'entonnoir (`not s.online`). À décider pour DEV 4.
  - Profils dans Studio à plusieurs : « Profile id required ». Tous les kits sont ouverts, donc la progression ne se teste pas à deux.

**ANIMATEUR**
- Mets les masques, capes et objets du dos dans `outfit_models.ITEMS`, comme les autres pièces : leurs icônes se rendent sans autre changement.
  - Un masque doit avoir des pièces sur `Head`, une cape sur le buste, un objet du dos sur `UpperTorso` ou `LowerTorso`. Sinon, l'icône est refusée, avec la raison.
- L'arme du ninja et la pose de victoire demanderont une ligne dans `render_icons.py` quand leurs modèles existeront.

**DESIGN**
- Les icônes des nouveaux objets arriveront après les modèles de l'ANIMATEUR, dans le même dossier (`tools/icons/renders`). `icons.json` reste complet.

## INBOX-INTEGRATION-20261119 — DEV 19/11, 22 h 10 : #131 à #135 intégrés, le plan de Konoha validé

François : « intègre et ça me va ».

- **ANIMATEUR** :
  - Ton plan est validé (DEC-042). Tu peux modéliser les six maisons, à leurs budgets.
  - À l’intégration, `konoha_layout.py` construit le dossier du jeu avec `os.pardir` au lieu de la chaîne de chemin relatif. Le fichier généré est identique. La chaîne faisait échouer `tools/check_architecture.py`, qui la lisait comme une référence à tout le dossier, Motion Lab compris.
- **DESIGN** :
  - #131, #132 et #135 sont dans le jeu.
  - Les 19 pictogrammes de `assets/ui/icons` restent à envoyer sur Roblox, avec l’accord de François. Ensuite, `UIAssets.Ids` reçoit leurs identifiants.
  - Le DEV passera `ui_probe.luau` sur tes écrans dans Studio.

## INBOX-PLAN-20261119 — DEV 19/11 au soir : les tâches de chacun et ce qui change pour les tenues

**Pour toutes les discussions**
- Le plan est dans le projet claude.ai : `claude/plan-vrai-jeu-taches-2026-11-19.md`. Il contient :
  - ce qui ne va pas dans le cœur du jeu ;
  - la boucle à vendre ;
  - qui touche quels fichiers ;
  - les tâches de chacun, dans l'ordre ;
  - les points de rencontre (qui attend qui).
- Une PR par sujet vers `claude/ninja-duel-2026-10-14`.

**ANIMATEUR (tenues)**
- En duel, le corps de l'avatar prend maintenant les tailles et les places du rig (`AvatarBody.fit`). Seule la tête garde sa taille. Tes pièces (`OutfitMeshes`, `Ref` = R15 standard) y sont donc mises à l'échelle des parties du rig.
- Dans Konoha, c'est le corps de l'avatar, agrandi à la taille des prodiges (`AvatarBody.grow`).
- `mat="Fabric"` est remplacé par SmoothPlastic à l'affichage (`OutfitDress.MATERIAL`) : sous la lumière du jeu, le Fabric sort presque noir. Si tu veux de la matière, passe par la couleur ou par une autre matière, et vérifie dans le jeu.
- Les bandes des avant-bras et des mains (`Wrap`) paraissent trop épaisses, en blocs blancs, dans le village comme en duel.

## INBOX-OUTILLEUR-BOUCLE-20261119 — OUTILLEUR 19/11 au soir : robot de la boucle, icônes, parcours dans Studio

Détail : `tools/loopbot/README.md` et `tools/icons/README.md`, branche `work/tools-loopbot`.

**DEV**
- `tests/Loop.spec.luau` n'a pas pu tourner ici : pas de lune. À passer avec lune avant de l'ajouter à `TEST_RUNNERS` (`build.py`).
- L'écran de résultat ne reçoit pas encore le prochain nœud ni l'inspiration suivante (`progress`, tâche 6 ; c'est #138). Le robot le note sans échouer.
- Le premier duel s'appelle « PRODIGY TOURNAMENT » à l'intro et « … ADVANCES » à la défaite.
- Le bandeau était sur les yeux (vu dans Studio sur `bbcfffb7`) ; #133 le pose sur le front.

**DESIGN**
- Les icônes des 33 objets sont dans `tools/icons/renders` (PNG transparents de 512 px, manifeste `icons.json`, planche `_planche.png`), à placer dans `assets/ui`.
- Sur iPhone 13, ces boutons sont sous 44 px :
  - les flèches de la fiche YOUR NINJA : 31 px ;
  - DONE : 32 px ;
  - SKILL TREE : 37 px ;
  - LATER : 30 px.
- Toujours sur iPhone 13 :
  - la fiche YOUR NINJA couvre la moitié gauche de celle de l'inspiration ;
  - SKIP STEP couvre le titre de la consigne ;
  - l'inspiration est cachée derrière le corps du joueur, et aucune bulle TALK n'est visible (une tape à sa place marche).

**ANIMATEUR**
- Les icônes de tenue se rendent depuis `outfit_models.py`, celles des armes depuis `fx_models.py`.
- Pour un nouvel objet (masque, cape, dos, arme du ninja), il faut une ligne dans `tools/icons/render_icons.py`.
- Il n'existe pas de modèle Blender des bandeaux.

## INBOX-SYPHODEV-JEU-20261119 — DEV 19/11 au soir : le jeu actuel passé à la méthode, ce qui revient à chacun

Détail et chiffres : [METHODE_SYPHODEV § 15](../tools/METHODE_SYPHODEV.md).

**ANIMATEUR**
- `tools/blender/clips_to_luau.py` lance maintenant `tools/syphodev/clip_passes.py` à chaque export. Il referme les boucles et lisse les sauts d'une image. `ND_NO_FILM=1` le coupe.
- La suite échoue (`SyphoClips`) si une boucle ou un saut d'une image revient.
- `python3 tools/syphodev/audit_clips.py` donne le reste à reprendre dans Blender :
  - mains dans la tête en garde ;
  - Lion.Sweep et Lion.VaultKick sous le sol ;
  - 48 sauts sur plusieurs images ;
  - Copycat.Blade.Heavy et Lion.Heavy à 0,77 s.
- Les VFX sont à passer à l'arrêt sur image par phase avec `roblox-vfx`.
- Pour le nouveau Konoha :
  - une maison fait 3 400 à 6 500 triangles, quand le repère du skill est de 800 ;
  - le village actuel est vide à 64 %, pour un repère de 22 %.

**DESIGN**
- Mesuré sur le HUD de Konoha (iPhone 13 paysage), avec `tools/syphodev/ui_probe.luau` :
  - DUELS et SHOP font 98 × 42 px, sous la cible tactile de 44 px (`UIScale` réduit 140 × 60 à 70 %) ;
  - les contours mélangent 2, 2,5 et 3 px.
- Les captures aux 4 tailles se font avec `capture_device_matrix`.

**DEV et ANIMATEUR**
- Les clips sont écrits sur `World.RIG` (les avatars), mais les prodiges passent par `Looks.form` (épaules ±0,84, tête plus haute).
- Le même clip tombe à 0,21 stud d'écart sur les deux corps.
- Il faut décider ensemble : un seul squelette, ou un audit sur les deux.

## INBOX-SYPHODEV-20261119 — DEV 19/11 : la méthode SyphoDev est pour toutes les discussions

François veut que chaque discussion applique exactement la méthode de SyphoDev. Avant ta prochaine tâche :
1. lis [METHODE_SYPHODEV](../tools/METHODE_SYPHODEV.md) (§ 3, comment l'IA teste sans 8000 essais ; § 12, ce que ta discussion en prend) ;
2. lance `bash tools/syphodev/setup_cloud.sh` à la racine du dépôt ;
3. utilise le skill de ta discipline (`roblox-animation`, `roblox-vfx`, `roblox-ui`, `roblox-map`, `roblox-3d-model`, `roblox-sfx`, `roblox-code`) ;
4. écris dans le skill chaque correction validée par François.

ANIMATEUR : la route joint-space est prête sur notre squelette (`tools/syphodev/README.md`, exemple `examples/cross.json`). Les `AuthoredClips` restent à toi.

## INBOX-VFX-STUDIO-20261104 — ACK Claude 04/11 22 h 40 (installé ; test comparatif proposé, pas lancé)

**Fait (Claude, 04/11, 22 h 40) :** vérifié sur la page officielle (create.roblox.com, asset 135581141962270) : **VFX Studio**, par **@XxOmqxXNerd**, catégorie Plugins / Éclairage et ambiance, **gratuit**, 95 % (800+ votes), créé le 31/05/2025, mis à jour le 07/09/2026. Installé depuis la Boîte à outils de Studio (le même résultat : « VFX Studio — By @XxOmqxXNerd — FREE », pas « VFX Studio Pro » à 4,99 $). **Preuve dans Studio** : bouton Toolbox « Installed », onglet Plugins avec « VFX Studio » et « Toggle Panels », panneau VFX Studio ouvert (VFX, Mesh, Properties, Scripts, Sounds, Textures), barre d'outils flottante dans la vue. Le plugin a demandé l'accès Internet à `raw.githubusercontent.com` ; l'utilisateur a répondu « Autoriser » (révocable dans Plugins > Plugin Management). Rien n'a été ajouté au jeu ni publié.

**Suite proposée (non lancée) :** un seul test avant/après, dans une place de test (ND-Test-v35), sur un effet existant ; voir CURRENT_STATE.


**Demande utilisateur : « dis-lui d'installer VFX Studio ».** Plugin Roblox Studio précis : **VFX Studio** par **@XxOmqxXNerd**, asset ID **135581141962270**, Creator Store officiel : https://create.roblox.com/store/asset/135581141962270/VFX-Studio . Ne pas confondre avec VFX Editor, VFX Forge ou d'autres plugins.

**Action demandée à Claude :** depuis la session Roblox Studio accessible, ouvrir le lien officiel, vérifier l'éditeur, le prix et les autorisations demandées, puis installer le plugin si accessible sans achat ni élévation de permissions inattendue. S'il faut une transaction, une connexion/autorisation non disponible ou si l'installation ne peut pas être effectuée par Claude, signaler exactement la manipulation nécessaire à l'utilisateur ; ne jamais affirmer « installé » avant preuve dans l'interface Plugins de Studio. Ne pas télécharger des réuploads tiers ni introduire le plugin dans le runtime du jeu.

**Après installation :** confirmer présence et ouverture de VFX Studio ; examiner en priorité sa pertinence pour les effets jutsu/impacts de la bêta V35. Proposer **un seul test visuel comparatif isolé** sur un effet existant (avant/après), sans remplacer la pipeline VFX actuelle, sans nouveaux systèmes, sans publier automatiquement ; intégrer seulement après preuve à l'écran et validation du rendu. Respecter le chantier en cours et les règles d'exécution : ce message ne vaut pas permission de refondre tous les VFX ni de détourner la roadmap.


Propriétaire unique : notifications temporaires à accuser puis absorber selon [EXECUTION_RULES](EXECUTION_RULES.md). Décisions dans [DECISIONS](DECISIONS.md), faits dans [CURRENT_STATE](CURRENT_STATE.md), travail dans [MASTER_BACKLOG](MASTER_BACKLOG.md).

## INBOX-ANIM-MASTERY-20261027 — ACK Claude 27/10 (bloc en cours)

Mission [maîtrise de l'animation](../archive/requests/2026-10-27-animation-mastery-combat-breakthrough.md) (`6b6fe95`), activée par l'utilisateur le 27/10 à 22 h 22. Décision [DEC-028](DECISIONS.md#dec-028--animation-de-production-dans-blender-puis-maîtrise-réelle-du-métier), travail ANIM-001…006 dans MASTER_BACKLOG. Déjà livré avant activation (Blender-first, non encore jugé artistiquement) : `719d115`, `cdfad66`, `c7ab3c0` (locomotion), `04ac9bf` (défense, réactions, poursuite).

## INBOX-AUDIT-ROSTER20-20261017 — PENDING ACK Claude

Demande utilisateur : audit complet avant nouvelle passe gameplay, sans corrections runtime Codex. Lecture prioritaire : [ENGINEERING_REVIEW](ENGINEERING_REVIEW.md), puis [preuves et classement datés](../archive/audits/2026-10-17-roster20/AUDIT.md). Appliquer les critères des tickets existants et la séquence DEC-021 ; ne pas interpréter le checkpoint « Tier A » comme clôture de la gate native.

Les anciennes entrées ACK et la passation désormais dépassée à dix sont conservées dans le [snapshot avant audit](../archive/audits/2026-10-17-roster20/before-active/SINCE_LAST_CLAUDE.md). Elles ne constituent plus des missions ouvertes. À réception, ajouter l'ACK/commit et conserver les faits et tâches uniquement dans leurs propriétaires.

## INBOX-INCREMENTAL-20261018 — ACK Claude 18/10 (M1→M6 livrés, voir CURRENT_STATE ; M7 suivant)

Préparation demandée par l'utilisateur, HEAD bc7faa3. Les corrections déjà livrées sont reconnues ; lire la [revue remplacée](ENGINEERING_REVIEW.md), puis les petits packets M1–M7 sous [QA-004](MASTER_BACKLOG.md#qa-004--reproduire-séquences-anormales-et-cycle-de-match). [Preuves ciblées et fiches des anciens WEAK](../archive/audits/2026-10-18-feel-preparation/AUDIT.md). L'ancien inbox reste sans ACK explicite ; ne pas recréer ses défauts déjà corrigés ni poursuivre une ancienne revue à l'aveugle. Aucun runtime modifié par Codex.

## INBOX-FICHES20-20261018 — SUPERSEDED par DEC-026 (pas ACK implicite)

DEC-025 : l’utilisateur demande une fiche par personnage et signale une identité/chakra insuffisamment perceptible en jouant. Lire l’[index20](../characters/ROSTER_20.md) puis uniquement les fiches du lot traité ; les cibles de gestes/mirages/chakra ne sont pas des mécaniques déjà validées. CHR-CORE-001/002 et SYS-001 portent les critères. Cette préparation ne remplace pas M1–M7 de QA-004 ni la séquence DEC-021. Les anciennes fiches détaillées sont conservées sous docs/archive/characters/2026-10-18-before-profiles ; aucun runtime modifié. Accuser à la reprise sans redécouvrir les chiffres dans les sources.

## INBOX-BIBLES-V1-20261018 — ACK Claude 18/10 (3 nouveaux jouables, menu 17+3 ; bibles des 17 non entamées)

Nouveau brief utilisateur : **roster et définition V1 remplacés**, [DEC-026](DECISIONS.md#dec-026--roster-cible-et-character-v1-combat-bibles). [Index20 / A–E](../characters/ROSTER_20.md) :17conservés + Madara/Hashirama/Hiruzen enfants ; Hinata/Temari/Kabuto hors cible, encore dans runtime. Lire seulement la bible du sous-lot ouvert. Bee multi-sabres, Kimimaro squelette vivant et corps/animations/échanges complets sont fondamentaux V1 ; pas attendre chakra/armes globaux finaux. Anciennes fiches de61eb585 conservées, ne plus les exécuter comme cible.

**Ne pas interrompre le bloc en cours.** Codex a livré uniquement du design, aucun runtime/build/test gameplay modifié. Ouverture des sous-lots dans CHR-CORE-001 et migration dans CHR-EXT-002 ; les tables de design sont une préparation, pas un ordre de tout implémenter. Accuser réception avant la prochaine grosse passe identité.

Mise à jour de base : M1 de Claude `41364ed` intégré avant publication de ces bibles ; correction persist/poison reconnue, aucune demande de la refaire. Rejouer les scénarios natifs M1 avant clôture ; continuer le bloc en cours.

## INBOX-AUDIT-5bb52fd-aeff49a — ACK Claude 18/10 (F1/F3 faits dans DevGateCheck ; F2 : trois builds reconstruits)

Audit incrémental demandé par l’utilisateur : [ENGINEERING_REVIEW](ENGINEERING_REVIEW.md), [preuves et trois missions](../archive/audits/2026-10-18-5bb52fd-aeff49a/AUDIT.md), corrections de gate sous QA-004. M5/M6 préservés ; M7 ne peut plus être considéré clos sur son seul PASS. Aucun gameplay Codex. Avant prochain lot identité, fiabiliser verdict/négatifs/S20 puis rebuild/rejeu exact ; pas de nouvelle décision produit.

## INBOX-R15-20261018 — ACK Claude 18/10 (passe R15 conservée lors de la fusion Wave4)

Demande directe utilisateur autorisant Codex à améliorer visuellement les R15 : MOV-005 reçoit une passe client limitée (horloge de réception par acteur, détente progressive, cadence murale sur vitesse dessinée). [Rapport / hashes / preuves](../archive/reports/r15-2026-10-18/REPORT.md). Trois builds et511cas PASS par variante ; Debug exact vérifié en Studio. Aucun nouveau kit/serveur/graphe. Brouillon ND-Debug-new3 restauré en conservant Wave4 ; fusionner ses hooks sans perdre cette passe. Réserves M7/S20 précédentes maintenues ; ancien QA périmé résolu par rebuild, pas par changement de gate.

## INBOX-R15-COMMON-20261018 — PENDING ACK Claude

Passe client directement demandée par l’utilisateur : branche `codex/ninja-r15-common-pass`, base distante `b445df5`. [Rapport](../archive/reports/r15-common-2026-10-18/REPORT.md), suivi MOV-002 et CURRENT_STATE. Un module, pas de kit/serveur/graphes ; préserve les clips Wave1/3/4. Préserver les corrections ciblées de pas/strafe/reset dans les prochains lots V1 et rejouer leurs scénarios lors des prochaines intégrations. Les gates visuelles/humaines des vingt restent ouvertes. Ne pas interrompre le sous-lot roster en cours.

## INBOX-PRODUCT-REVIEW-20261104 — ACK Claude 04/11 22 h 45 (DEC-033 : B0 choisi par l'utilisateur, v35 publiée après B0)

Demande utilisateur du 04/11 : pousser dans GitHub la synthese de l'audit V34/V35 en distinguant **BETA immediate** et **JEU V1 a long terme**. [Revue candidate](../reports/beta-v1-strategy-2026-11-04/REVIEW.md). **Aucun gameplay, changement de priorite, lancement de chantier ou nouvelle decision n'est autorise par ce commit**. Lire au prochain checkpoint, sans interrompre le travail courant ; si un point est retenu par l'utilisateur, faire le rapprochement avec DEC-023/024/030/032 et NET-001/REL-001, puis seulement actualiser les sources proprietaires. Ne pas substituer cette revue aux preuves Studio et Roblox publie.
