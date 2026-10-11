# Forge Motion Lab

Plugin local de création, mix et preview R15. Aucun fichier du runtime Ninja Duel
n'est modifié. Aucun asset Creator Store n'est publié.

## Installer et tester

1. Fermer Studio quand cela convient, puis exécuter `python3 motion-lab/install.py`
   depuis `games/ninja-duel`. Sur macOS, le plugin va dans
   `~/Documents/Roblox/Plugins/ForgeMotionLab.rbxm`. Une ancienne copie est conservée
   avec l'extension `.previous`. Aucune ouverture de Studio n'est automatisée.
2. Ouvrir une place dans Studio, en mode édition. **Plugins → Forge Motion Lab →
   Motion Lab** ouvre la fenêtre. Taille conseillée : environ 1180 × 780.
3. Le mix initial utilise Minato pour jambes/bassin/root, Itachi pour torse/bras,
   Neji pour tête. **Mixer** : changer une source, déplacer Blend, activer/désactiver
   une couche. **Save**, puis **Custom**, puis relancer Studio : le mix est conservé.
4. **Library** : choisir Jab, **+ Jab**, puis Cross, Knee et Spin kick. Glisser les
   blocs pour les réordonner, ajuster Duration/Blend, **Preview phrase**. La bande
   sous les blocs permet de parcourir la séquence. Pause/Loop/Speed/Reset sont dans
   la preview. Front/Side/Free : caméra ; en Free, glisser pour orbiter, molette
   pour zoomer. Grid et Root activent leurs affichages.
5. **Pin A**, modifier le mix ou le DNA : A reste figé, B affiche l'édition. Mirror
   échange les côtés. **New profile** propose Blank, Lee, Gaara, Killer Bee et
   Shisui. Les 22 valeurs **DNA** sont libres ; **Generate movement set** propose
   une route remplaçable. **Advanced** permet de changer les blocs locomotion et
   les règles d'expression JSON.
6. **Export** produit un ModuleScript de données sous
   `ServerStorage/ForgeMotionLabExports`. **Import selected export** le relit sans
   exécuter son Source. **Attach R15**, après sélection d'un Model R15, lui attache
   ces données ; ce bouton ne remplace pas ses animations.

Alternative sans Python : insérer `dist/ForgeMotionLab.rbxm` dans une place en mode
édition, sélectionner le Model ForgeMotionLab puis **Save as Local Plugin**.
Ne pas conserver ce Model dans la place destinée au jeu.

## Ce qui est réutilisé

`NinjaDuelAdapter` importe les stances, CLIPS anatomiques, gaits et timings privés
actuels de `VelmoraMotionEngine`, `Fighters` et `Attacks`, par extraction **au build**.
L'IK R15 du plugin reprend le solveur existant. La bibliothèque expose les blocs
procéduraux et les autres clips déjà écrits pour Minato, Itachi, Neji et Sasuke.

Le générateur ne connaît aucun nom de personnage. Les règles sont des données :
`grammarOverrides[grammar] = {bodyScale, rootLift, rootTravel, lateralTravel}`.
`preferredGrammar` décrit des intentions pour Claude ; il n'exécute aucun pouvoir.
Le DNA de l'édition façonne aussi les couches issues d'autres profils. Off bypass
le mix d'une couche ; pour Weapon, il masque aussi l'accessoire.

## Export vers Ninja Duel

Le module exporté retourne un bundle `NinjaDuel.MotionDefinitions.v1` contenant
le preset, ses sources, la bibliothèque et `ninjaDuel = {stance, gait, clips,
timings}`. Ces dernières tables suivent le vocabulaire anatomique et la timeline
**0 → startup, 1 → actif, 2 → recovery, 3 → fin** du moteur actuel.

Claude peut reprendre `bundle.ninjaDuel.stance`, `.gait` et `.clips` dans les tables
existantes STANCE/GAIT/CLIPS d'une copie de test. Le plugin ne les injecte jamais
au runtime et ne change ni dégâts, ni combos, ni IA, ni mouvements actifs.
Les clips générés sont échantillonnés à 25 poses. Le mix anatomique exporté peut
légèrement différer du blend de rotations de la preview, notamment aux jambes IK.
Le bundle complet conserve les sources pour raffiner le résultat.

## Limites explicites

- Preview procédurale sur mannequin R15 ; aucune animation Roblox publiée.
- Locomotion de preview cyclique, sans le foot planting adaptatif au terrain du jeu.
- Accessoire d'arme schématique. Pas de sable, téléportation, VFX, victime, dégâts,
  collisions ou vraie simulation du combat. Les profils de départ sont des bases.
- Loop adoucit les dernières 80 ms uniquement dans la preview ; Once montre la fin
  sans ce raccord. Les données de gameplay exportées ne reçoivent pas ce raccord.
- Pas d'éditeur complet de keyframes ni d'import d'animations distantes.
- La validation visuelle/native Studio est à faire par François après livraison.

## Rebuild / QA

`python3 motion-lab/build.py` depuis `games/ninja-duel` (ou chemin absolu du script).
Outils attendus : Lune et luau-compile dans `/private/tmp/ninja-duel-tools`, ou
`NINJA_DUEL_TOOLS`, `LUNE`, `LUAU_COMPILE`. Le build ré-extrait les données depuis le
checkout courant, compile, teste, vérifie les Sources du binaire et ne publie rien.

`tests/run.luau` teste mixer, DNA, génération, graphes, persistance, undo/redo,
import/export. `tests/ui_smoke.luau` utilise le **binaire exact**, des instances
Roblox et événements Studio **simulés** : UI, preview, séquence, export, thèmes,
format 780 × 600, teardown. Ce test ne certifie ni le rendu ni les interactions
réelles dans Studio. `dist/manifest.json` enregistre les hashes et le statut QA.
