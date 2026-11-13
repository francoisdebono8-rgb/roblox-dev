# ANIMATEUR — issue #73, avant le tournage Sasuke vs Kakashi (13/11/2026)

Branche `work/anim-sasuke-kakashi`. Décisions de François sur le Sharingan : voir les commentaires de #73.

## Priorité 1

| # | Point | Ce qui change | Fichiers |
|---|---|---|---|
| 1 | Étoile noire de la Grande boule de feu | La texture « scorch » (traînées radiales) faisait l'étoile. Toute brûlure au sol est maintenant une tache sombre douce, au bord chaud qui refroidit en 0,7 s, plus petite (×0,62). | `Client/VfxKit` (`Kit.burn`, `Kit.ground`) |
| 2 | Sharingan lisible en plan moyen | Pendant la copie, le Sharingan apparaît en grand à l'œil de Kakashi : 1,15 stud, avec les virgules qui tournent ; il s'ouvre en 0,12 s. Le regard rouge devient un trait clair avec un halo. Un œil allumé reçoit un halo rouge (EyeGlow). Les billes en Neon sont retirées. | `Client/CopyFX`, `Client/Effects` |
| 3 | Un seul œil pour Kakashi | Le Sharingan dessiné va sur son œil gauche seul ; l'autre garde son iris. L'éclat de lecture (`eyeGlint`) ne touche plus qu'un œil sur Kakashi. | `Shared/Face` (`Face.tint`), `Client/Effects` |
| 4 | Chidori lisible quand Sasuke court | Les étincelles, le cœur et les éclairs suivent la main (`LockedToPart`) : avant, en monde fixe, ils restaient derrière en course. Les arcs de `LightningFX` sont accrochés à la main. Une traînée bleue courte suit la main. | `Client/Effects`, `Client/LightningFX` |

**Sharingan : un par perso et par forme** (`Face.SHARINGAN`, réglable). De vraies virgules : une tête et une queue qui s'affine le long de l'anneau.

| Perso | Forme de base | Éveil (pour l'instant) | Mangekyō | Quand on le voit |
|---|---|---|---|---|
| Sasuke | 2 | 3 | non | lectures, jutsu, contres, intro, éveil |
| Kakashi | 2 | 3 | non | œil gauche seul : éveil, ou copie en main |
| Itachi | 3 | 3 | oui | toujours ; le Mangekyō seulement pendant Tsukuyomi (ultime et genjutsu) |
| Shisui | 3 | 3 | non | lectures, contres, genjutsu, intro, éveil |
| Madara enfant | 3 | 3 | non | lectures, contres, intro, éveil |

Pour revenir à 2 tomoe en éveil : changer `awake` dans `Face.SHARINGAN`, et rien d'autre.

## Priorité 2

| # | Point | État |
|---|---|---|
| 5 | Signes de Kakashi | **Fait (lueur)** : `Client/SealFX`. Le chakra s'amasse entre les mains pendant le canal d'un jutsu à signes, avec une couleur par nature (terre ambre, eau bleue, foudre blanc-bleu). Chaque fois que les mains se joignent, une pulsation marque un signe. **Reste** : les poses existent dans les clips (`jutsu_v2_kakashi` : serpent, bélier, rat, tigre), mais le canal du serveur est court (0,2 à 0,55 s), donc elles passent vite ; les mains sont des poings. Pour les tenir un instant, il faut un canal plus long côté DEV, ou une pose tenue sur le dernier signe. |
| 6 | Dragon de terre | **Fait** : `Client/FamilyFX`, `earthSerpent`. Tête en coin de roche avec museau, mâchoire ouverte, cornes, arcades et yeux braise ; corps en dalles de deux tons avec des épines ; terre et cailloux qui tombent en route. Avant : des boules lisses. |
| 7 | Flaque du Dragon aqueux | **DEV** : la taille (rayon 9) et la durée (6 s) sont des règles du jeu (`Server/Interactions` : la flaque conduit la foudre). Proposition : rayon 5,5 et 3,5 s. Le dessin suit ces règles. |
| 8 | Bûche de substitution | **Fait** : le « fantôme blanc » venait du nuage blanc de la taille du corps, qui restait près de 3 s, alors que la bûche disparaissait à 1,7 s. Maintenant : une bouffée grise basse de 1 s, et la bûche reste visible 2,6 s. |
| 9 | Corps tenu par les chiens | **DEV** : la pose « Bound » du moteur a déjà une lutte (05/11). S'il reste figé, c'est l'état (gel, ancrage ou pose écrasée). Les nouvelles boucles `Grabbed` / `.Back` / `.Side` (#58) peuvent servir. |

## Preuve

- **Images AVANT/APRÈS** (le dessin reproduit les mêmes proportions que le code ; ce n'est pas une capture Studio) :
  - `sharingan_avant_apres.png`
  - `kakashi_un_oeil.png`
  - `burn_avant_apres.png` : la vraie texture « scorch » du jeu, décodée de `VfxAtlas`, à côté de la nouvelle brûlure.
- **Capture dans ND-DEV** : à faire quand le Mac sera relié. Plan moyen à 8 studs, qualité 10 :
  1. boule de feu ;
  2. copie par Kakashi ;
  3. Chidori en course ;
  4. Tsukuyomi ;
  5. Dragon de terre ;
  6. substitution.
- **Tests** : `tests/Sharingan.spec.luau` (8 tests). La suite Lune passe, sauf `CameraFeel` et `Naruto` (FuzzyEq), qui échouent déjà sur la référence.
