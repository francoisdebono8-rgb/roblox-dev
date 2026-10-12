# Forge Motion Lab 0.5 — bases de combat référencées

Plugin local R15 : browser avec miniatures de poses, preview et comparaison A/B,
Body Mixer, DNA, variantes éditables, timeline par canaux, export inert.
Aucun changement au runtime Ninja Duel, aucune publication.

## Mettre à jour

Depuis `games/ninja-duel` : `python3 motion-lab/install.py`.
Le binaire vérifié va dans `~/Documents/Roblox/Plugins/ForgeMotionLab.rbxm`, avec
sauvegarde `.previous`. Relancer Studio pour recharger le plugin. Les presets de
la version précédente sont conservés dans la même clé de settings.

Alternative : insérer `motion-lab/dist/ForgeMotionLab.rbxm` dans une place en édition,
sélectionner le Model ForgeMotionLab, **Save as Local Plugin**, puis retirer ce Model
avant de sauver une place de jeu. Éviter deux copies installées simultanément.


## Comparer les nouvelles bases de combat

1. Après installation/rechargement, **New profile → Combat reference study (neutral DNA)**.
   Cela sélectionne **Motions → Combat references**, sans toucher aux personnages du jeu.
2. Filtrer **Family**, puis **Left / Right** : Base, variante tactique et Ninja.
   **L/R** choisit la version avec sa stance et ses appuis ; **Mirror** reste un outil de preview.
3. Sélectionner une frappe, **Old/new** : A = ancienne version commune, B = nouvelle.
   **Pin A** permet aussi de comparer Base / variante tactique / Ninja.
4. Les variantes sont déjà éditables : sélectionner **Ready, Anticipation, Acceleration,
   Contact, FollowThrough, Recovery**, ou HipDrive/Rechamber dans **Pose**.
   Les parties du corps, deltas, timing, amplitude, root path et hold sont conservés.
   **Create Variant** produit une autre copie nommable ; **Save** garde le profil local.
5. Famille de transition : **Bridge** montre le transfert seul ; **Phrase** joue la route
   complète avec plusieurs contacts. `Contact2`, `Contact3` et les phases intermédiaires
   sont sélectionnables/retimables dans la liste de clés. Jab → Cross → Hook existe aussi.
6. **Export** conserve les variantes et produit les poses modifiées via NinjaDuelAdapter.
   `ninjaDuel.motionMetadata` inclut fonction, stance, références et temps édités.
   L'export est inert : Claude choisit son intégration dans le jeu.

**120 nouvelles Motion Variants** : 78 attaques (13 familles × 2 côtés × 3 formes),
8 briques dodge/pursuit/launcher/aerial, 16 transferts et 18 phrases complètes.
Jab/cross distinguent avant/arrière en orthodoxe/southpaw. Hook, uppercut, knees et
elbows incluent les différences avant/arrière dans une garde à pied gauche avancé.
Les anciennes 182 briques restent accessibles sous **Common bilateral**, sans mutation
ni perte des presets précédents. Le nouveau six-phase schema coexiste avec leurs cinq phases.

Les sources et limites sont dans [COMBAT_REFERENCES.md](COMBAT_REFERENCES.md).
Ce sont des adaptations R15 keyframées, avec IK/FK et interpolation procédurale,
sans motion capture, simulation de pression au sol ou adversaire physique. Le sweep
suppose un adversaire déjà déséquilibré ; launcher/aerial sont des adaptations de jeu.
Le DNA/mixer et les edits extrêmes peuvent dégrader les appuis : juger la base en profil
neutre, puis spécialiser. Aucun rendu Studio ni feel humain n'est déclaré validé.

## Tester une correction de mouvement en cinq minutes

1. **Plugins → Forge Motion Lab → Motion Lab**. Taille conseillée 1180 × 780 ;
   minimum 780 × 600. La séparation au-dessus de la timeline ajuste sa hauteur.
2. **New profile → Lee starting profile**, puis **Motions → Kick → Roundhouse**.
   **Create Variant** conserve la source et la fige en A. Renommer la variante dans
   l'inspector, par exemple `Lee_Roundhouse_01`. A est bleue, B est ambre.
3. Cliquer le diamant **Contact / RightLeg** dans la timeline. **Pose** : augmenter
   Hip raise, réduire Knee bend ; choisir Hips puis Yaw, Torso puis Roll. Les valeurs
   sont des *deltas* en degrés/studs, pas des angles absolus. Le mannequin est corrigé
   immédiatement. Choisir aussi un corps depuis le bouton sous la preview.
4. **Motion** : Amplitude 1.25, Hip rotation 1.2, Root travel / Forward travel.
   Déplacer Contact sur la timeline pour retimer. Ajuster Duration, Contact hold et
   Easing. **Ghosts** montre les poses voisines, **Root** la trajectoire échantillonnée.
5. **Save**, puis relancer Studio : **Custom → profil sauvegardé → Motions** retrouve
   la variante. **Assign** la branche au slot source du profil. **+** sur sa carte ou
   **+ Block** l'insère dans la séquence. **Export** produit les poses/timings modifiés
   sous `ServerStorage/ForgeMotionLabExports`, avec un enfant JSON réimportable.

Même workflow : Neji/Palm compact, Itachi/Jab, Minato/Dash attack, Sasuke/Launcher.
Gaara, Killer Bee et Shisui restent des profils de départ modifiables, sans pouvoirs
simulés. Le générateur utilise des données et du DNA, sans identité hardcodée.

## Timeline / controls

- Règle : cliquer/glisser pour scrubbing continu ; playhead synchronisé au R15.
- Diamants et marqueurs : sélectionner et glisser pour retimer. Les clés de phase restent ordonnées : six pour les références de combat, cinq
  (Start / Anticipation / Contact / FollowThrough / Recovery) pour les anciennes variantes.
- `+ Key` à la tête de lecture insère une clé héritant des corrections interpolées.
  `Delete key` retire une clé additionnelle ; les frontières sont conservées.
- `Multi` : sélectionner plusieurs temps de clés ; glisser déplace le groupe ;
  `Stretch` étire les temps sélectionnés autour du premier. Les croisements sont refusés.
- `M` désactive les corrections de pose du canal ; `L` empêche son édition.
- `+ / − / Fit` : zoom horizontal ; scroll pour parcourir tous les canaux.
- `Sequence` : blocs proportionnels à leur durée, glisser pour réordonner, bord droit
  pour retimer. En bas : nom, durée, blend, Cut/Blend et retrait du bloc.
- Pose : liste corporelle, sliders/valeurs numériques et boutons de nudge. Le champ
  dédié reçoit ↑ / ↓ ; ces touches ne sont pas liées aux inputs du jeu.
- `↶ / ↷` : undo/redo ; un drag constitue une seule transaction.
- Play/Pause, Loop/Once, speed, Front/Side/Free, molette/orbite et miroir sont conservés.
- **Mix**, **DNA → Generate movement set**, **Advanced** gardent le workflow précédent.
  `⋯` regroupe duplication, suppression d'un preset custom et import.
- **Attach R15** attache les données à un Model sélectionné, sans remplacer d'animation.

## Données / intégration Claude

Le modèle v1 reste compatible. `preset.motionVariants[id]` ajoute : sourceAsset,
sourceGrammar, sourceDuration, poseOverrides (temps normalisés + deltas anatomiques),
motionModifiers, timing, rootPath et mute/lock. Aucun code utilisateur n'est exécuté.
Une variante hérite du bloc + du profil/mixer/DNA courant : changer ce profil change
sa base. Pin A fige une référence indépendante. Save conserve toutes les variantes du
profil, leurs séquences et leurs sources nécessaires, avec budget de stockage 2 Mo.

`NinjaDuelAdapter` extrait les vrais stances/CLIPS/gaits/timings au build. Son bundle
`NinjaDuel.MotionDefinitions.v1` contient `preset`, `sources`, `assets`, et
`ninjaDuel = {stance, gait, clips, timings}`. L'export suit les phases existantes :
0 → startup, 1 → contact/actif, 2 → recovery, 3 → fin.

Chaque variante exporte un clip sous son ID. Une variante assignée remplace aussi
le clip du slot source **dans les données exportées**. Les 25 samples de base sont
complétés par les temps exacts des clés et du contact hold ; les timings reflètent
la durée, les marqueurs et la vitesse éditées. Le runtime actif n'est jamais touché.
Claude décide ensuite où intégrer ces tables. JSON import valide les références,
remappe les profils sources et ne lit jamais du Luau arbitraire.

## Limites réelles

- Pas de gizmo 3D ni de sélection directe d'une mesh : sélection via canaux/liste,
  sliders et nudges opérationnels. Pas de graph editor complet.
- Mannequin R15 et arme schématique ; blocs génériques procéduraux et profils de
  départ sont des approximations, pas des animations Roblox publiées ni du combat.
- Hips et Root rotations composent le même root anatomique. Modifier une jambe
  passe en FK ; modifier un pied passe en IK. La conversion conserve la position
  ou l'orientation de base autant que cette représentation permet ; l'ankle FK
  a un seul axe. Si jambe ET pied sont corrigés, le pied IK est prioritaire.
- `elbowTwist` est une extension locale du solveur ; un consommateur Ninja Duel doit
  lire ce champ pour reproduire ce degré de liberté. Aucun changement moteur imposé.
- Modifiers/trajectoires/hold sont des opérations cinématiques : pas de contraintes
  biomécaniques, collisions, terrain, victime, VFX, sable, téléportation ou multi-armes.
- Les variantes preview/export partagent le mix anatomique. Les profils historiques
  gardent leur blend CFrame existant, dont le bake anatomique peut différer aux IK.
- Easing est commun à la variante ; pas de tangentes éditables par propriété.
  Les marqueurs procéduraux de départ sont estimés, puis entièrement retimables.
- Loop raccorde les dernières 80 ms uniquement lors de lecture preview ; les poses
  en pause et les données exportées n'ont pas ce raccord.
- Contrôles techniques automatisés réussis ; rendu et gestes **natifs Studio à
  valider par François**, conformément à cette passe. Aucune QA visuelle inventée.

## Rebuild / QA

`python3 motion-lab/build.py` compile, extrait les données courantes, teste puis
package le binaire. Lune/luau-compile : `/private/tmp/ninja-duel-tools`, ou variables
`NINJA_DUEL_TOOLS`, `LUNE`, `LUAU_COMPILE`.

41 cas de données/controller/variantes/appuis/références, puis smoke sur le **binaire exact** : anciens workflows,
édition de poses/amplitude/timing, marker/block drags, ghosts, save/import/export,
layout minimum, thème et libération des connexions. Instances/schema Roblox réels,
événements/layout Studio simulés : ce n'est pas une certification du rendu natif.
`dist/manifest.json` enregistre version, hashes, sources et statuts QA honnêtes.

Références de workflow étudiées : [Roblox Animation Editor](https://create.roblox.com/docs/animation/editor),
[Blender Dope Sheet](https://docs.blender.org/manual/en/5.4/editors/dope_sheet/introduction.html),
[Blender channels](https://docs.blender.org/manual/en/latest/editors/graph_editor/channels/introduction.html).

### Archive de comparaison — bibliothèque bilatérale 0.4.0

182 nouveaux assets, indépendants des movesets du jeu : 126 frappes (21 familles × 3 variantes × 2 côtés), 32 états/déplacements, 24 ponts de transition. Aucun ancien asset supprimé. Les quatre profils Ninja Duel importés et quatre profils de départ restent inchangés.

- Punches : Jab, Cross, Hook, Uppercut, Backfist, Palm.
- Kicks : Front kick, Side kick, Roundhouse, Low kick, High kick, Back kick, Spinning kick, Axe kick, Sweep.
- Knees : Front, Rising, Jumping. Elbows : Horizontal, Downward, Spinning.
- Bilatéral aussi : strafe, lateral run, diagonal, pivot, stop, dodge, pursuit, recovery, lateral step, side counter, wall exit, launcher drive, landing brace.
- Neutres : idle neutral/combat, walk forward/backward, run, sprint.

Chaque famille offensive a Standard + deux variantes adaptées parmi Compact/Fast/Heavy/Long/Rotational/Stepping. Les variantes changent chambre, garde, profondeur d'appui, rotation, silhouette au contact, parcours des pieds et recovery ; pas seulement la vitesse. Les frappes partent d'une garde LeftLead commune : côté droit chargé à l'arrière, côté gauche plus direct. Les déplacements latéraux démarrent avec le pied du côté du déplacement. Les coups de jambe gardent une jambe d'appui IK et une jambe attaquante FK (deux FK pendant le jumping knee). Les tours complets utilisent un yaw continu et un spotting de tête borné.

**Tester/comparer** : redémarrer Studio après `python3 games/ninja-duel/motion-lab/install.py`, Plugins → Forge Motion Lab → Motion Lab. New profile → Blank profile donne une expression commune neutre. Motions → source Common → Family (ex. Roundhouse), sélectionner un clip. `Old/new` fige le bloc historique correspondant en A ; B joue le nouveau. `Pin A`, puis `L/R` compare les deux côtés indépendants. Filtres catégorie/côté/source/famille ; les variantes sont regroupées par famille, variante, côté. `Mirror` reste un simple miroir de preview : utiliser `L/R` pour les assets réellement préparés.

`Create Variant` → Pose : éditer membre, garde, bassin, torse, tête, pied d'appui (yaw/toe), center-height (Root Y), ainsi que chaque phase. Motion : amplitude, hip rotation, torso follow, extension, anticipation/follow-through, durée/contact/recovery, trajet du root. Ajouter des clés à la timeline pour éditer HipDrive ou Rechamber. Save conserve les corrections ; Export passe par NinjaDuelAdapter et produit des données inertes. Les exports conservent les clips historiques et n'ajoutent que les nouveaux clips sélectionnés/référencés, leurs sources et les extrémités des ponts, pour ne pas copier tout le catalogue à chaque export.

Les 24 ponts couvrent jab→cross/hook, cross→kick, punch→knee, kick→punch/knee, sweep→follow-up, dodge→counter, pivot→strike, launcher→aerial pursuit, landing→attack, attack→guard. Advanced indique `fromAsset`, `toAsset`, phases d'entrée/sortie et changement de stance. Un pont commence au FollowThrough sortant et finit à l'Anticipation entrante (le root sortant est recentré) : c'est une brique à raccorder avec les blends existants, pas une nouvelle règle de cancel/combat.

**Limites** : clips synthétiques anatomiques, pas de mocap ni contact physique avec un adversaire. Pas de résolution automatique du sol/mur ni contrainte de pied/COG à chaque frame ; les supports sont préparés aux clés et interpolés, le solver reste approximatif entre elles. Les courbes extrêmes/DNA/mix peuvent nécessiter des corrections artistiques. Les ponts sont des propositions de transfert de poids, sans garantie de raccord automatique à n'importe quel clip. Les boucles de preview recentrent leur root ; `Once` permet de lire toute la réception. Validation visuelle laissée à François : compilation, continuité des clés, schémas R15 et événements UI simulés ne prouvent pas le feel.
