# Méthode SyphoDev appliquée à Ninja Duel

Demande de François (19/11) : regarder les vidéos de SyphoDev et appliquer exactement ce
qu'elles font. Chaque détail est à retenir, en particulier les animations, l'IA qui teste
sans faire 8000 essais, les API et les VFX. Ce guide reprend les trois vidéos et le pack
de skills qu'il distribue gratuitement. Il dit où chaque partie est branchée dans Ninja
Duel et quelle discussion s'en sert.

Sources :
- [How to Make Roblox Animations With AI (R6 + R15, Claude Opus 5.5)](https://www.youtube.com/watch?v=dlx_kf6jT08), 24/10/2026, 11 min ;
- [Can AI Make an Entire Roblox Creature Capture Game?](https://www.youtube.com/watch?v=jJtZmZ3Hz9k), 13/10/2026, 35 min ;
- [How to Make a Roblox Game With AI (Claude Opus 5.5 Full Tutorial)](https://www.youtube.com/watch?v=afuKhenJldY) : le tutoriel complet auquel les deux autres renvoient (skills, MCP, API, VFX, sons, cartes, UI, 3D) ;
- [SyphoDev-yt/roblox-ai-skills](https://github.com/SyphoDev-yt/roblox-ai-skills) au commit 5aad881, sous licence libre. On peut l'utiliser, y compris pour un jeu commercial. On ne peut pas le revendre. Un partage gratuit doit renvoyer à la [chaîne SyphoDev](https://www.youtube.com/@SyphoDev). La licence est dans `.claude/skills/SYPHODEV_LICENSE.txt`.

## 0. Le principe

Claude est le cerveau. Chaque discipline (code, carte, UI, 3D, animation, VFX, son) a son
propre circuit, ses propres outils et **sa propre façon de vérifier son travail**. On ne
demande pas à une seule IA de tout écrire en code. Il y a trois briques : les skills, les
MCP et les API. Chaque fois que quelque chose casse, la correction devient une règle
écrite, avec sa raison, et la session suivante ne refait pas l'erreur.

## 1. Ce qui est installé (19/11) et pour qui

Tout est dans le dépôt. Chaque discussion Claude Code qui ouvre le dépôt l'a donc
automatiquement : DEV, ANIMATEUR, OUTILLEUR, CM. DESIGN s'en sert à travers ses propres
fichiers (§ 12).

| Skill (`.claude/skills/…`) | Ce qu'il fait | Discussion principale |
|---|---|---|
| `create-roblox-game` | La porte d'entrée : recherche, plan, une section par session, `HANDOFF.md`, assemblage, essai, publication | DEV (pour un mode ou un pan entier du jeu) |
| `roblox-build-orchestrator` | Lance les étapes d'assets en parallèle avec des sous-agents, tient un journal horodaté, garde toutes les écritures Studio sur un seul fil | DEV |
| `roblox-code` | Rojo + Knit, 4 portes sans Studio (build, tests, lint, format) | DEV, OUTILLEUR |
| `roblox-map` | Carte depuis une spec, plus un **prouveur** (atteignable, chutes, lignes de vue) | DEV (Konoha), DESIGN pour le plan |
| `roblox-ui` | Spec JSON → maquette PNG + `.model.json` + constructeur Luau, plus un vérificateur | DESIGN |
| `roblox-3d-model` | Texte → image vérifiée → maillage Hi3DGen → Blender (décimation, UV, bake) → MeshPart | ANIMATEUR (armes, décor, tenues) |
| `roblox-texture-gen` | Textures pour les maillages | ANIMATEUR |
| `roblox-vfx` | VFX d'anime dans un simulateur navigateur, plus une collecte de packs que tu possèdes | ANIMATEUR |
| `roblox-sfx` | Sons du Creator Store par id, prouvés dans Studio | DEV / ANIMATEUR |
| `roblox-animation` | Animations R15/R6 écrites en données, rendues dans Blender, vérifiées | ANIMATEUR |
| `roblox-skills-setup` | Vérifie la machine et écrit les `LOCAL.md` | toutes |

Les 7 agents sont dans `.claude/agents/` : `roblox-asset-anim`, `-map`, `-mesh`, `-sfx`,
`-ui`, `-vfx` et `roblox-market-scout`. Chaque skill lit d'abord son `LOCAL.md`, rempli pour
Ninja Duel : chemins, MCP, clés jamais écrites, préférences du jeu.

Outillage :
- **Session cloud** : `bash tools/syphodev/setup_cloud.sh` à la racine du dépôt. Il installe
  Blender 5.2.3 en module `bpy` (la même version que le Mac) avec une commande `blender`,
  ainsi que Rojo 7.6.1, Wally, Selene 0.29.0, StyLua 2.3.1, Lune 0.8.9 (gabarits du skill) et Lune 0.10.5 (suite de Ninja Duel ; 0.11 n'a plus `Enum.KeyCode.Unknown`). La bibliothèque
  Roblox de Selene vient de `tools/syphodev/selene_roblox_std.py`, parce que Selene ne passe
  pas le proxy. Le rendu EEVEE est logiciel dans le cloud : environ 20 s par image. Les
  **chiffres** se font donc dans le cloud (`--no-render`, 0,7 s) et les **images** sur le Mac.
- **Mac de François** : Blender 5.2.3 LTS, lancé en arrière-plan par le MCP Blender
  (`execute_blender_code_for_cli`), sans fenêtre ni écran pris. Mesuré le 19/11 : 32 images
  en 320 px rendues en **15,3 s**. Les fichiers de travail vont dans
  `~/Documents/NinjaDuel/LAB/syphodev/`. Studio passe par le MCP officiel `Roblox_Studio`,
  avec `robloxstudio-mcp` en repli.
- Contrôle d'installation (19/11) : les 4 portes sont vertes sur un projet `roblox-code`
  neuf. `prove.py minimal` donne `WARN` (P11 seulement, normal). Le plan PNG est rendu.
  `coin_hud` donne 0 échec au vérificateur UI. Blender 5.2.3 tourne dans le cloud et sur le
  Mac.

## 2. Les trois briques

### Skills
- Un skill est un dossier avec un `SKILL.md`. Son **nom et sa description** décident quand
  Claude l'utilise. Claude ne lit que les descriptions en permanence. Les instructions
  complètes se chargent au besoin, les fichiers de référence seulement à l'étape qui les
  demande. Vingt skills installés n'encombrent donc pas la mémoire.
- Le dossier `scripts/` contient du Python **déjà écrit et testé**. Claude ne réécrit pas le
  code à chaque fois.
- Quand une correction marche, elle est **écrite comme règle avec sa raison**, dans les
  `traps.md` ou les références du skill. C'est ainsi qu'on « entraîne » Claude. Pour Ninja
  Duel, dès que François signale un défaut et qu'il est corrigé, la discussion inscrit la
  correction dans le skill concerné (préférence de chaque `LOCAL.md`).
- Le skill intégré `skill-creator` interroge l'utilisateur et rédige un premier jet. On
  teste ensuite le skill encore et encore jusqu'à ce qu'il fasse le travail comme on veut.
- Conseil de la vidéo : prendre ce que l'IA fait le plus mal, construire un skill juste pour
  ça et noter la correction à chaque erreur.

### MCP
- Le MCP **officiel** de Studio : créer des objets, régler des propriétés, exécuter du Luau,
  faire des captures et **lancer un essai en mode jeu**. SyphoDev a quitté le MCP
  tiers parce qu'il n'atteignait pas le jeu en cours d'essai. Il garde le tiers en
  **repli** si l'officiel casse. Chez nous c'est pareil : `Roblox_Studio` d'abord,
  `robloxstudio-mcp` ensuite.
- Pour brancher le MCP chez SyphoDev : Assistant de Studio, puis ⋯, Manage MCP servers,
  activer *Studio MCP server* et coller la commande « Claude Code CLI » dans une session.
  Chez nous il passe par l'application Claude du Mac, c'est déjà fait.
- Une seule connexion Studio à la fois. Dans Ninja Duel : annoncer avant de prendre l'écran,
  et jamais pendant qu'une autre discussion l'utilise.
- **Le code vit dans des fichiers** synchronisés dans Studio (Rojo chez lui, `build.py` chez
  nous). Claude peut donc tester le code avant même que Studio s'ouvre.

### API
- **Images et icônes** : Flux Schnell sur Cloudflare Workers AI, offre gratuite. Elle est
  rapide et n'use pas le GPU réservé à la 3D. Claude regarde l'image, réécrit le prompt et
  recommence jusqu'à ce qu'elle soit bonne. Variables : `CF_ACCOUNT_ID`, `CF_API_TOKEN`.
- **3D** : Hi3DGen, sous licence MIT, transforme une image en maillage. **Kaggle est arrêté**
  depuis le 19/10 : ses conditions l'interdisent et SyphoDev a été banni. Le maillage se fait
  maintenant sur un Space Hugging Face, un à la fois (`HF_TOKEN`). Les objets à arêtes vives
  passent par Kiln ou Blender directement.
- **Licences** : vérifier la licence de chaque modèle (`roblox-3d-model/references/licences.md`).
  Celle de Hunyuan3D de Tencent exclut le Royaume-Uni, l'Union européenne et la Corée du Sud.
  **François est en France : Hunyuan3D est exclu.**
- **Open Cloud** : il envoie les modèles, images et animations finis sur le compte. Chez
  SyphoDev, c'est une clé créée dans le Creator Hub (All tools, Open Cloud, API keys).
  **Chez nous, sans clé** : l'outil `open_cloud_invoke` du MCP officiel s'authentifie avec la
  session de Studio. Il se limite aux droits que François accorde dans Studio > Assistant >
  MCP Permissions, et aux dossiers qu'il y approuve.
- **Les clés ne vont jamais dans le chat** : une clé collée dans Claude reste dans la
  conversation. SyphoDev demande à Claude comment la stocker comme variable secrète et la
  tape lui-même dans un terminal. Sur le Mac, pour les processus lancés par l'application
  Claude : `launchctl setenv NOM valeur`, puis relancer l'application. François le tape
  lui-même.
- Réseau (mesuré le 19/11) : les sessions cloud et le bac à sable du Mac ne joignent **ni**
  huggingface.co, **ni** api.cloudflare.com, **ni** apis.roblox.com. GitHub passe. Les appels
  d'API se font donc depuis le Mac lui-même (Blender lancé par le MCP, ou Studio).
- Dans Studio, chez SyphoDev : Game Settings > Security, activer *Allow HTTP Requests* et
  *Enable Studio Access to API Services*. Ce sont des réglages du jeu : François les active
  lui-même, seulement si une étape en a besoin.

## 3. Comment l'IA teste sans faire 8000 essais

C'est le cœur de la méthode. **Chaque discipline a sa façon de se prouver, et un chiffre
passe avant une image.** Lire un chiffre ne coûte rien. Une image se regarde une fois, petite,
puis on ne la rouvre plus si un chiffre peut répondre.

- **Ne jamais croire un programme qui a fini sans erreur.** Les scripts vérifient leur propre
  travail : intégrité du rig, images bien écrites, sortie non nulle sinon. Blender sort en 0
  sur une exception si on ne lui passe pas `--python-exit-code 1`.
- **Ne pas faire un rendu pour une question qu'une sonde chiffrée résout.** La sonde du rig
  entier prend 0,1 s. L'option `report` donne la position de chaque articulation à chaque
  temps fort et nomme l'articulation fautive en une passe.
- **Regarder les images à chaque passe**, une planche contact petite. Avec une référence,
  juger sur la comparaison côte à côte. Les chiffres prouvent que la pose suit la spec ;
  seul le regard prouve que la spec est le bon mouvement. Le salut du pack passait tous les
  chiffres et ressemblait à une main sur la tête.
- **Ne jamais assouplir une tolérance pour faire passer un voyant au vert.** On corrige la spec.
- **La référence gagne** : si la planche et la référence divergent, la spec change.
- Ce qui ne se voit qu'en mode jeu : le journal de sortie est souvent la seule chose qui
  revient. Le script de jeu doit donc **se diagnostiquer à l'écran**. La capture échoue si
  un onglet de script est au premier plan.
- Par discipline :
  - **Code** : 4 portes en une seconde environ avant Studio. Les règles du jeu sont des
    données pures testées sans Roblox. Un projet neuf doit être vert avant la première
    ligne de jeu, sinon on ne distingue plus ses erreurs du bruit.
  - **Animation** : sonde chiffrée (0,1 s), aperçu (environ 4 s chez lui, 15 s pour 2 vues
    complètes chez nous sur le Mac), pied d'appui suivi image par image, membres qui
    traversent le corps comptés, planche contact regardée, GIF relu en ressortant ses
    images, **parité Blender ↔ Roblox** vérifiée avant Studio, puis dans Studio un script qui
    joue chaque clip et vérifie qu'il dure **exactement** sa durée d'auteur.
  - **Jambes** : en essai, debout, marche, course, saut, réception, on regarde les jambes. Ça
    prend 15 s par combattant et aucun contrôle statique ne le voit.
  - **VFX** : le *phase freeze*. Une gerbe dure moins d'une seconde, donc une capture est un
    pile ou face. On déclenche l'effet, on attend l'instant exact voulu, on fige les
    particules, et on juge le début, le milieu et la fin.
  - **Carte** : rayons tirés avec les **vrais** chiffres de déplacement du jeu, chacun étiqueté
    par sa source. Toute valeur devinée est listée dans chaque rapport. 9 contrôles (§ 9).
  - **UI** : le vérificateur à 4 tailles d'écran (§ 8).
  - **3D** : l'image de concept est regardée et le prompt réécrit. Le maillage est regardé
    sous chaque angle et régénéré s'il échoue. Le budget de triangles est vérifié avant tout
    import.
  - **Son** : chaque candidat est prouvé dans Studio (`IsLoaded` et `TimeLength` mesuré), car
    la durée affichée par la boîte à outils est souvent fausse.

## 4. Les animations, pas à pas (vidéo du 24/10)

Ce qu'il faut : Claude Code, Blender (jamais ouvert, il tourne en arrière-plan), le skill
`roblox-animation` (la version récente, mise à jour depuis la semaine d'avant), un rig R15
pour Blender (celui de la vidéo est le rig gratuit de MrXeno sur Gumroad) et Studio avec son
MCP.

1. **Une animation, c'est des poses dans le temps.** Un coup de poing en compte 5 : repos,
   anticipation (on arme), contact, accompagnement, retour. Chaque pose est un temps plus un
   angle en degrés par articulation, écrits en données.
2. **Blender transforme ces nombres en animation et rend chaque image. Claude regarde les
   images avant d'y croire.** Piège : le rig garde sa pose de repos dans une Action que
   Blender réapplique au rendu. Les nombres disent « bras levé » et l'image montre le bras
   pendant, sans aucune erreur. La parade consiste à écrire les clés dans cette même Action
   (`anim_render.py`).
3. **FK seulement, jamais IK.** En IK le bras supérieur peut pivoter sur lui-même en une
   image. Sur un perso en blocs, ça ressemble à un changement de couleur instantané.
   Une animation Roblox est de toute façon une rotation par articulation.
4. **Rendu gris uni** : une texture chargée cache la pose. Les vrais animateurs Roblox
   montrent leur travail sur un mannequin uni.
5. **Le timing de Roblox, pas celui de la vie** : un coup dure de 0,3 à 0,7 s à 30 images/s.
   1,5 s paraît lent et flottant. Un adoucissement par segment : `in` pour accélérer dans le
   coup, `out` pour se poser. Il faut **exagérer**.
6. **Étalonner le rig** la première fois. Piège : quatre interrupteurs IK/FK sont à 1, le
   rig est en IK et tous les os FK semblent morts (0 utilisable). On les met à 0 et les 12
   os FK revivent. Claude le fait dans chaque animation.
7. **Partir de la table d'angles qui marchent** (`references/pose-recipes.md`) : garde,
   anticipation, contact, accompagnement. La somme épaule + coude reste sous 120°. Un coup de
   pied haut exige une cuisse au-delà de −120°. Il faut contre-tourner la cheville d'appui.
   La torsion et l'inclinaison vont sur le haut du torse. Pour un accompagnement, dépasser
   de 6 à 10°.
8. **Les chiffres trouvent ce que l'œil rate** : dans la vidéo, le pied d'appui glissait de
   ¾ de stud pendant le coup de pied. Claude l'a vu dans les nombres en suivant le pied image
   par image. Il a alors déplacé tout le corps pour que les hanches tournent au-dessus du
   pied posé. Seconde passe : le pied ne bouge plus.
9. **GIF final sous deux angles.** Claude ressort les images du GIF pour vérifier qu'il est
   bien enregistré.
10. **Avant Studio**, il vérifie que Roblox posera chaque partie exactement comme Blender l'a
    rendue. Ce contrôle existe parce qu'il a trouvé des torsions de bras jouées en miroir.
11. **Dans Studio, par le MCP** : un script crée une animation par mouvement et vérifie que
    chacune dure exactement sa durée. Un petit script lie des touches pour jouer les
    animations. Pas besoin d'envoyer quoi que ce soit pour tester.
12. **Jambes figées** : un idle de garde en boucle qui anime les jambes, à une priorité
    au-dessus de la marche, gagne sur la marche. Le perso glisse alors en garde. La
    correction : n'animer que les bras et le torse et laisser la marche bouger les jambes.
13. **Publier** : les animations de test ne marchent pas dans un jeu publié. Le skill les
    envoie comme vraies animations Roblox par Open Cloud, sans clic droit dans Studio.
14. **R6** : 6 articulations, sans coude ni genou, donc plus raide par nature. Ce n'est pas
    un échec de l'IA. On met un R6 dans Studio (Claude fait apparaître un mannequin par le
    MCP), Claude lit les 6 vraies articulations par le MCP, construit les 6 parties à leur
    vraie taille et enregistre le rig une fois. Les hanches R6 sont aux coins du torse. Dans
    la vidéo, la première passe d'un coup d'épée traversait le corps et la seconde était
    propre. Dans Studio, au moment du coup, chaque partie est à moins d'un dix-millième de
    stud du rendu. Ça marche aussi sur les persos sur mesure.
15. Limites : les prises d'armes demandent plus de passes, et un grand geste en R6 peut
    traverser le corps. Il faut toujours regarder l'aperçu. Avant d'animer un objet tenu, on
    **cherche comment il se tient vraiment** (photos de pratiquants) et on l'écrit en
    `_intent`.
16. **Apprendre à Claude** : quand on lui dit ce qui ne va pas et qu'il corrige, on lui
    demande de **retenir la correction** pour que l'erreur ne revienne pas.

### Dans Ninja Duel : la route joint-space

Nos combattants sont un squelette R15 de blocs construit par le jeu (`Server/World.rig`,
données `World.RIG`). Nos clips (`AuthoredClips*`) sont exactement des `Motor6D.Transform`
par articulation et par image. C'est la route « rig sur mesure » de SyphoDev : celle du R6
et de son monstre, étendue au R15. Elle ne demande pas le rig Gumroad.

1. `lune run tools/syphodev/rig_dump.luau tools/syphodev/rig.json` (depuis `games/ninja-duel`)
   écrit le squelette **du jeu** : 15 articulations, C0 et C1. Les pieds sont lus le long de
   la chaîne des Motor6D, qui place les parties en jeu, à 3,01 studs sous la racine, ce qui
   colle à HipHeight 2. `tests/run.sh` (suite `SyphoRig`) vérifie que le fichier reste égal
   à `World.RIG`.
2. `blender --background --python-exit-code 1 --python tools/syphodev/make_parts.py -- tools/syphodev/rig.json parts/`
   crée les vraies parties (des blocs à leur taille).
3. Écrire la spec (`tools/syphodev/examples/cross.json`) : angles sémantiques en degrés.
   - Membres : `swing` + vers l'avant, `spread` + vers l'extérieur, `twist`.
   - Racine, taille et cou : `pitch` + penché en avant, `lean`, `turn` + vers la gauche.
   - Clés : `ease`, `markers`, `auto_ground` (pied le plus bas posé à y = 0).
   - Réglages : 30 images/s, 0,3 à 0,7 s.
4. Les chiffres d'abord : `blender … --python .claude/skills/roblox-animation/scripts/r6_clip.py -- --rig … --glb-dir parts --clip spec.json --outdir out/x --no-render`
   (0,7 s). On lit la hauteur des pieds, le glissement d'appui, les mains qui entrent dans
   le corps et la position des poings dans `report.json`.
5. Les images ensuite, sur le Mac par le MCP Blender : planche contact, GIF, puis images
   ressorties du GIF.
6. `python3 tools/syphodev/to_authored.py tools/syphodev/rig.json clips.json out/x/resolved.json`
   écrit le JSON du jeu. Il garde la même courbe et le même slerp que le rendu, et renomme les
   épaules en « Right » et « Left ». **L'ANIMATEUR** le fusionne et lance
   `tools/blender/clips_to_luau.py` : les `AuthoredClips` sont à lui.
7. Dans Studio, par le MCP : `studio_parity.py` construit un vrai combattant, joue le clip
   avec le décodeur du jeu et compare chaque partie. **Le 19/11, sur le corps lu dans
   Studio : 0,000057 stud au pire, durée 0,5 s exacte.** Contre `World.RIG`, le même contrôle
   a trouvé **0,21 stud** d'écart. Les prodiges passent par `Looks.form`, qui resserre les
   épaules de 0,21 et monte la tête de 0,15, alors qu'un avatar de joueur garde `World.RIG`.
   Un clip se cale donc sur le squelette où il sera joué (`rig_prodigy.json` ou `rig.json`).
   C'est la raison d'être de ce contrôle dans la vidéo. Il reste le test des jambes pour les
   gardes et les idles.
8. **Jambes figées chez nous** : un clip peut ne poser que le haut du corps. Le moteur saute
   les articulations absentes (`AuthoredMotion.decode`, liste `UPPER`). Une garde ou un idle
   qui doit laisser marcher ne clé que `Waist`, `Neck` et les bras.
9. Pas d'envoi Open Cloud pour nos clips : ce sont des données du jeu, publiées avec la place.
   `upload_animation.py` ne sert que pour de vraies animations Roblox, par exemple un emote.

Exemple réel du 19/11, un direct du droit de 0,5 s (`examples/cross.json`), quatre passes :

| passe | ce que les chiffres ou l'image ont montré | correction |
|---|---|---|
| 1 | les deux pieds glissent de 0,41 et 0,37 stud ; le pied arrière flotte à 0,09 stud ; le poing frappe à hauteur de poitrine (y 3,63) | rotation sortie de `Root`, qui entraîne les jambes, et mise sur la taille ; jambes réglées pour atteindre le sol |
| 2 | glissement 0, pieds au sol, poing au menton (y 4,64) ; **à l'image**, la garde est trop ouverte (poing droit à x 2,12) | balayage chiffré de swing, spread, twist et coude : 36 essais en 30 s, sans un seul rendu |
| 3 | garde serrée sans contact ; **mais** 4 triangles de main dans le torse à l'anticipation | anticipation moins serrée |
| 4 | tout à 0 : glissement 0, aucun membre dans le corps, poings devant le visage | rendu sur le Mac : 15,3 s, planche et GIF relus |

## 5. Construire un jeu ou une grosse section (vidéo du 13/10)

- Il commence par `/create-roblox-game` : « Complete the research and plan stage for … ».
  L'IA fait la recherche du créneau (jeux semblables, ce qui marche) et le plan, et **mesure
  l'équilibrage en simulation au lieu de deviner**. Elle dit honnêtement que le plaisir
  n'est pas encore prouvé : c'est l'avis humain.
- **Règle de propriété intellectuelle de la méthode** : chaque nom, type et design est une
  invention, et les noms sont vérifiés contre les jeux existants. *Pour Ninja Duel, qui
  reprend Naruto, c'est une décision à prendre par François.*
- **Une section par session** : une fois la section approuvée (« Yes, that's all good »,
  « mark the section as done »), Claude enregistre tout dans `HANDOFF.md` et donne un prompt
  de reprise. On **vide la conversation** et on colle le prompt, pour éviter la
  « context rot » qui dégrade les réponses quand la fenêtre se remplit.
- **La boucle avant l'art** : la section 2 est un *greybox* de toute la boucle centrale, et
  l'IA **la joue elle-même** dans Studio. Quand l'humain arrive, les zones sont déjà
  débloquées par l'essai de l'IA.
- **Retour avec un croquis** : un dessin Paint collé avec le message (« pas à l'échelle »,
  « le reste est ton choix »). Claude refait des maquettes (plans PNG), puis construit.
- **Prompt de retour** : captures jointes et liste numérotée, chaque point décrivant le
  comportement attendu précisément. Exemple de la vidéo : les étiquettes au-dessus de la
  tête, à l'échelle de la distance comme un vrai objet. Puis « trouve tous les endroits où
  ça arrive et corrige ».
- **L'humain ne corrige pas lui-même**, même quand c'est facile : il dit à l'IA quoi
  corriger.
- Section 4 : animations, effets et sons, puis **essai complet par l'IA dans Studio**.
- À la fin, **un essai de groupe avec de vrais joueurs** (son Discord) et une note sur 10.
- Ce qu'il a vu en essai humain : pièces qui se chevauchent, étiquettes trop grandes,
  scintillement de deux surfaces qui se battent, *placeholders* gris restants, attaque
  possible de trop loin, graine difficile à lancer sur une cible qui bouge, deux boss
  superposés en multijoueur.

## 6. VFX

- Le pack actuel a deux routes :
  1. **auteur** (le cas normal) : l'effet est défini, joué image par image dans un simulateur
     navigateur des vraies instances VFX de Roblox, avec plus de 2 000 textures **générées**
     et des maillages Blender, puis exporté en kit Studio ;
  2. **collecte** : on lit chaque émetteur d'un pack gratuit **que l'on possède**, on le
     range en recettes JSON dans sa bibliothèque et on émet un module `VFXKit`.
- Collecte (le tutoriel) : on prend des packs VFX gratuits du Creator Store, l'IA les
  collecte, les **classe** et les découpe en **briques** (boule, flamme, faisceau…), puis
  **compose** de nouveaux effets (boule de feu = boule + flamme + faisceau). La bibliothèque
  ne se partage pas : les textures appartiennent à leurs auteurs.
- Le *phase freeze* (§ 3) pour juger.
- Premier lancement, une fois par machine : `make_textures.py`, `make_magic_tex.py`,
  `make_painted.py`, `lib/build_library.py`, puis `make_meshes.py`, `make_props.py` et
  `make_dragon.py` dans Blender, puis `make_prop_tex.py`. Environ 250 Mo.
- Le niveau visé (sa vitrine de 100 coups d'anime vérifiés dans Studio) :
  - chaque élément est la vraie chose : arme ou créature en maillage, vrai cratère et débris ;
  - les ultimes ont la couche « set-piece » d'anime : impact frames, coup de FOV, lignes de
    vitesse, bandes noires, coupes caméra ;
  - une passe de polish à la fin (`fxpolish.py`) ;
  - des couleurs saturées, jamais un mélange pâle ;
  - **la cible réagit comme un corps** (`HitSystem.luau`) ;
  - la caméra cadre toute l'action ;
  - un **portail avant tout enregistrement**, jugé sur des chiffres.
- Mesuré dans Studio :
  - la taille d'un `ParticleEmitter` dessine le double ;
  - l'émissif d'une `SurfaceAppearance` ne fait pas de bloom ;
  - les `PointLight` éclairent les surfaces ;
  - il faut précharger les cartes par id ;
  - le passage OBJ → FBX retourne le maillage de 180°, d'où `obj_to_fbx.py` ;
  - un tween de CFrame tourne par le chemin le plus court, d'où l'action `spin`.
- Dans Ninja Duel, les FX sont à l'ANIMATEUR. Pour collecter, François doit d'abord cliquer
  **Get** sur les packs gratuits voulus. C'est manuel exprès, car Studio refuse de charger un
  asset que le compte ne possède pas. Il faut aussi vérifier les conditions de chaque pack
  avant la publication.

## 7. Sons

- Les envois audio par l'API sont limités par mois. Au lieu de générer des sons, l'IA prend
  des sons déjà **collectés et classés** sous des noms comme « boom », « effet de feu » ou
  « coup de feu », et les combine. La musique et les sons du jeu de créatures viennent du
  Creator Store, assemblés par l'IA.
- Le skill cherche par id sur les mêmes points d'accès que l'onglet audio de Studio, et
  **prouve** chaque son dans Studio avant de le choisir. Il émet ensuite un module
  `SoundBank`, une aide `Sfx` qui échoue sans bruit, et un script d'installation.

## 8. UI

- Pas d'outil de design : une seule spec donne trois choses, une image d'aperçu, le fichier
  UI du jeu et un script qui la construit dans Studio. L'aperçu ne peut donc pas contredire
  le jeu.
- **La pile de profondeur** sur chaque panneau et bouton :
  - une ombre dessous, légèrement décalée vers le bleu ;
  - un dégradé sur la face ;
  - un relief en haut ;
  - **un contour de la même épaisseur partout**. Des contours d'épaisseurs mélangées
    trahissent tout de suite une UI de débutant ou d'IA.
- **Icônes** : l'IA met des émojis faute d'icônes. Dans la méthode, les icônes sont générées
  (Flux). Dans Ninja Duel, il n'y a pas non plus de kanji pour les techniques.
- **Le vérificateur**, sur 4 tailles d'écran du petit téléphone au 1080p :
  - les boutons sont assez grands pour un pouce ;
  - rien ne touche rien ;
  - un élément centré l'est à 1,5 px près ;
  - aucun texte ne rétrécit trop pour être lu ;
  - aucun cadre ne dessine une boîte parasite autour d'un bouton.
- Le style vient de l'entraînement sur les UI des jeux Roblox qui marchent : on donne à
  Claude les écrans d'un jeu du top, il en garde un modèle dans le skill. Pour Ninja Duel, le
  modèle est la **DA v3 du DESIGN**, ses maquettes Mix-*.

## 9. Cartes

- Une carte n'est pas un tas de pièces : c'est un espace qu'on parcourt. Les questions ont
  des réponses mesurables. Peut-on y aller ? En revenir ? Voir à travers ? Combien de temps
  dure la chute ?
- Des rayons avec les **vrais** chiffres du jeu (saut, vitesse…), chacun étiqueté par sa
  source, les valeurs devinées listées dans chaque rapport.
- **9 contrôles** :
  1. plateformes qui flottent ;
  2. sommets où on ne tient pas ;
  3. hauteurs que personne n'atteint ;
  4. endroits atteignables qui ne devraient pas l'être ;
  5. trous dont on ne ressort pas ;
  6. lignes de vue trop ouvertes ou trop fermées ;
  7. pièces encastrées ;
  8. anneaux mal espacés ;
  9. chutes plus courtes que le ragdoll dont on doit se relever.
- Des **maillages**, pas des blocs, et un style appris sur des captures de jeux de référence.
  Chaque modèle est vérifié en triangles avant l'import.
- Pour Konoha, le profil de déplacement vient de `Hub.WALK`, `Hub.RUN`, `Hub.JUMP`,
  `Hub.LEAP` et `Shared/Config`. C'est l'outil qui prouvera « monter sur les immeubles en
  diagonale ».

## 10. Modèles 3D

1. Flux génère une image de concept. Claude la regarde et ajuste le prompt jusqu'à ce
   qu'elle soit bonne.
2. Hi3DGen en tire un maillage, avec un **Space Hugging Face** et non plus Kaggle. Claude
   regarde chaque angle et régénère en cas d'échec.
3. Environ 600 000 faces arrivent, pour une limite Roblox de 20 000 triangles par maillage.
   Blender sans fenêtre **décime environ 60:1**, jusqu'à 6 000 à 10 000.
4. Il **cuit le détail perdu dans une texture**. La couleur est **peinte d'après une petite
   spec**, pas devinée.
5. Les objets à arêtes vives (caisses, armes) sont construits directement dans Blender ou
   Kiln.
6. L'envoi se fait par Open Cloud. Chez nous il passe par `open_cloud_invoke`, avec l'accord
   de François (§ 13).

## 11. Code

Il y a 5 règles, nées d'un jeu qu'il a dû reconstruire :
1. le code vit dans des fichiers, jamais tapé dans Studio. Sa première version est morte
   parce que Studio et les fichiers avaient divergé ;
2. tout nombre à régler (vitesse, dégâts, prix) vit dans **un seul dossier de config** :
   équilibrer, c'est changer des données ;
3. les règles du jeu sont des modules purs, testés sans Roblox ;
4. tous les messages client ↔ serveur passent par **un seul fichier** ;
5. une liste de pièges, dont chacun lui a coûté des jours.

Il y a 4 portes avant Studio : `rojo build` (en environ 1 s), les tests, le linter et le
formateur. Un projet vide doit les passer avant toute ligne de jeu. Équivalents dans Ninja
Duel : `build.py` (4 profils), `tests/run.sh`, `tests/test_build_isolation.py`, les
contrôles docs et architecture et `luau-compile`. Selene et StyLua sont disponibles pour du
code neuf.

## 12. Qui fait quoi

| Discussion | Ce qu'elle prend de la méthode |
|---|---|
| **ANIMATEUR** | `roblox-animation` (route joint-space ci-dessus), `roblox-vfx`, `roblox-3d-model`, `roblox-texture-gen`, `roblox-sfx` pour les impacts. Il possède `AuthoredClips*`, les FX et Blender, et ajoute lui-même ses fichiers au jeu (RUNBOOK 3 quinquies). |
| **DESIGN** | `roblox-ui` : spec → maquette → constructeur → vérificateur à 4 tailles, pile de profondeur et contour uniforme, icônes générées sans émoji ni kanji. Il intègre ses écrans lui-même. |
| **DEV** | `create-roblox-game` et `roblox-build-orchestrator` (sections, `HANDOFF`, essais par l'IA dans Studio), `roblox-map` (prouveur de Konoha), `roblox-code` (règles et portes), branchement des pipelines au moteur. |
| **OUTILLEUR** | `roblox-code`, l'outillage (`tools/syphodev`), les sondes Studio. |
| **CM** | Les vidéos elles-mêmes : SyphoDev est un modèle de devlog (« tout ce qui est dans la vidéo est vraiment arrivé ») et d'essais de groupe notés sur 10. |

## 13. Ce que seul François peut faire

Ces étapes sont demandées au moment où une étape en a besoin, jamais avant :
- **Studio > Assistant > MCP Permissions** : accorder les droits Open Cloud (`asset:read`,
  `asset:write`) et approuver le dossier `Documents/NinjaDuel/LAB`, pour les envois. Aucun
  envoi sans son accord dans la conversation.
- **Game Settings > Security** : *Allow HTTP Requests* et *Studio Access to API Services*,
  si une étape le demande.
- **Comptes gratuits** Hugging Face et Cloudflare, pour la 3D et les icônes. Il saisit
  lui-même les jetons sur le Mac avec `launchctl setenv` ; ils ne vont jamais dans un chat.
- **VFX** : cliquer **Get** sur les packs gratuits choisis.
- Facultatif : le rig R15 de MrXeno (Gumroad), seulement pour la route FK d'`anim_render.py`.

## 14. Écarts assumés et pourquoi

- Animations : route joint-space sur notre propre squelette au lieu de KeyframeSequence +
  envoi. Notre moteur joue des `Motor6D.Transform` en données, ce qui est exactement ce que
  rend cette route.
- Pas de Rojo ni de Knit dans Ninja Duel : `build.py` existe et ses portes sont vertes. On ne
  migre pas un jeu en production pour suivre un gabarit.
- Rendus sur le Mac plutôt que dans le cloud, où le rendu est logiciel. Les chiffres, eux,
  se calculent dans le cloud.
- Open Cloud par le MCP officiel plutôt qu'avec une clé : moins de secrets.
- `r6_clip.py` lit les noms d'articulations depuis `rig.json`, pour le R15. Trois renderers
  acceptent le nom EEVEE de Blender 5. Ces retouches sont marquées « (Ninja Duel, 2026-11-19) »
  dans les scripts, comme SyphoDev invite à personnaliser ses skills.

## 15. Appliquée au jeu actuel (19/11 au soir)

François, le 19/11 à 20 h 02 : « tout ce que tu as emmagasiné, la méthode et tout, tu l'intègres
au jeu actuel. Donc que tu vérifies que tout ce qui est déjà en place, ben, faut peut-être
l'adapter. » Chaque discipline a reçu la preuve de son skill. Les commandes sont dans
[tools/syphodev/README.md](../../tools/syphodev/README.md).

### Ce qui a été corrigé et intégré

| Domaine | Contrôle SyphoDev | Trouvé | Fait |
|---|---|---|---|
| Animations | `roblox-animation` : chaque image des 862 clips posée sur le squelette, chiffres d'abord | 89 boucles qui ne se referment pas, 114 sauts d'une image | #127 : 1 boucle (voulue) et 48 sauts restent. Les passes tournent à chaque export (`clips_to_luau.py`), la suite les garde (`SyphoClips`) |
| Konoha, l'eau | `roblox-map` : le prouveur sur le village construit | L'eau en Terrain posée avant l'agrandissement ×1,3, hors du trou | #128 : `Hub.water` après `scaleVillage`. Studio : on nage dans le lac |
| Code | `roblox-code` : Selene | La pose du mur perdait sa vitesse (une expression `if` ne garde qu'une valeur) | #129 : corrigé ; `SyphoLint` garde ce motif hors de `src/` |

### Konoha au prouveur (711 pièces solides, 39 345 points où l'on tient debout, résolution 4 studs)

- **Toits.** 348 surfaces hautes :
  - 341 s'atteignent en marchant, avec le saut et le second saut ;
  - 6 seulement en courant : le grand toit de la salle de l'examen, à 55 studs ;
  - 1 jamais : le toit de la porte, à 60 studs.
- **Pièges :** aucun. Partout où l'on monte, on peut redescendre jusqu'à l'arrivée.
- **Pièces :** aucune ne flotte, et aucune face superposée ne peut scintiller (P1 et P10 PASS).
- **Chevauchements :** 248, tous des joints de construction (toits dans les murs, pignons sous les toits, marches). Rien ne se voit.
- **Espace vide :** 64 % des cases sont à plus de 26 studs de tout objet, pour un repère de 22 % dans le skill. Le village est très ouvert, alors que François veut « plus de place pour se battre, mais dans des espaces resserrés ». C'est une donnée d'entrée pour le nouveau Konoha de l'ANIMATEUR.
- **Lacune du modèle :** le prouveur ne connaît qu'un saut. Le profil lui donne un saut unique qui monte aussi haut que saut + second saut, avec moins de temps en l'air, donc une portée prudente.
- **Lacune de l'outil :** la conversion des toits inclinés autour de Z s'était trompée d'axe. Elle est corrigée dans `konoha_spec.py`.

### Ce qui reste, par discussion

- **ANIMATEUR (`AuthoredClips`, FX, Blender)**
  - Mains dans la tête : 307 clips signalés, dont 42 gardes. Les boîtes en signalent trop, mais les poings devant le visage se voient en jeu.
  - Corps sous le sol : Lion.Sweep (main −2,4), Lion.VaultKick (tête −2,43).
  - 48 sauts sur plusieurs images, par exemple Flashstep.Ultimate et Leaf.GorikiSenpu.
  - Coups trop longs : Copycat.Blade.Heavy et Lion.Heavy font 0,77 s.
  - Glissement des pieds au-dessus de 6 studs/s dans 297 clips. C'est mesuré sur le clip brut, avant le blocage des pieds du moteur (ANIM-002).
  - VFX : pas encore passés à l'arrêt sur image par phase (préparation, contact, dissipation) avec `roblox-vfx`. Les défauts A1 à A7 du 14/11 restent la liste de départ.
  - Modèles, comptés depuis les données du jeu :
    - le village pose 518 copies pour 722 752 triangles, sous le plafond total du skill (1,5 million) ;
    - une maison fait 3 400 à 6 500 triangles, quand le repère du skill est de 800 par maison ;
    - ExamHall seul fait 36 940 triangles ;
    - aucune pièce ne dépasse la limite Roblox de 20 000 ;
    - les effets font 68 052 triangles en tout (44 modèles) ;
    - les tenues font 86 756 triangles en tout (16 modèles, 8 000 à 11 400 par personnage).
- **DESIGN (interface)**
  - **Mesures** au simulateur iPhone 13 en paysage (749 × 388 pixels utiles), avec `ui_probe.luau` sur le HUD de Konoha :
    - les boutons DUELS et SHOP font 98 × 42 px, sous la cible tactile de 44 px ;
    - les contours mélangent 3 px (×2), 2,5 px (×11) et 2 px (×13) ;
    - aucun chevauchement, aucun texte trop petit, rien hors de l'écran.
  - **Cause** : `UIScale` réduit des boutons de 140 × 60 à 70 %.
  - **Captures** aux 4 tailles du skill, prises avec `capture_device_matrix` : 720p, iPhone 13, iPad, 1080p.
- **DEV et ANIMATEUR, à décider ensemble : deux squelettes.**
  - Les clips sont écrits sur `World.RIG`, celui des avatars.
  - Les prodiges passent par `Looks.form`, qui a les épaules à ±0,84 au lieu de ±1,05 et la tête plus haute.
  - Le même clip ne tombe donc pas au même endroit sur les deux corps (0,21 stud). C'est à relier au bandeau mal placé et à la taille qui change (liste du 15/11).
  - L'audit des clips utilise le squelette des prodiges.
- **Sons** (`roblox-sfx` : `IsLoaded`, puis `TimeLength` mesuré dans Studio) : tous les sons du jeu se chargent. Le coup de poing est lent au premier chargement.
