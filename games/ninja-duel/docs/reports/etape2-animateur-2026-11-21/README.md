# Étape 2, ANIMATEUR : Naruto, Sasuke et Lee refaits, les natures, les outils, les transformations (21/11)

**Demande :** `claude/etape2-deux-arbres-taches-2026-11-21`, section ANIMATEUR, points 1 à 4 (DEC-045). François : « les coups d'abord ».

Skills suivis : `ninja-animation-direction`, `roblox-animation` (méthode SyphoDev), `roblox-vfx`.

**Ce qui n'est pas vu :** rien de tout ça n'a été regardé dans Studio. Tout est TECHNICAL : des chiffres, des planches, et la suite de tests.

## 1. Les coups refaits (38 clips)

**L'outil :** `tools/blender/syph_author.py`. Il suit la méthode SyphoDev, sans Blender.
- Chaque coup est écrit en poses clés, comme on dirige un corps : où sont les pieds, où va le poing ou le pied, et comment tournent les hanches, le buste et la tête.
- La cinématique inverse garde les pieds plantés pendant que les hanches tournent et descendent. Ils sont replacés **à chaque image**, pas seulement aux poses clés.
- Un pied qui change de place se lève au lieu de glisser ; un pied qui pivote tourne sur sa plante.
- Les mains de garde suivent le buste. 60 images par seconde, pour qu'une image tombe pile au contact.
- **Le minutage reste celui du DEV :** la durée et les repères `contact` et `recover` sont repris du clip remplacé.

**Les poses :** `tools/blender/e2_strikes.py`. `tools/blender/e2_build.py` note chaque clip contre celui qu'il remplace, dessine sa planche, et **n'écrit un clip que s'il fait mieux**.

**Où ils sont :** `src/Client/AuthoredJutsu6`, `7` et `8`, la dernière couche d'`AuthoredMotion` (un clip du même nom gagne). Les anciens clips restent dans leurs fichiers : pour revenir en arrière, il suffit de retirer trois lignes d'`AuthoredJutsu.luau`.

**Les notes :** les 35 clips remplacés passent de **6,0 à 8,6 sur 10** en moyenne. Le détail est dans `notes.md`. Les pires de l'étape 1 :

| Clip | Avant | Après |
|---|---|---|
| `Lion.VaultKick` | 2,7 | 7,4 |
| `Leaf.Heavy` | 3,2 | 9,0 |
| `Legion.Heavy` | 3,8 | 8,5 |
| `Lion.Light3` | 3,8 | 7,9 |
| `Lion.Sweep` | 4,0 | 7,7 |
| `Leaf.LeafRising` | 4,0 | 6,8 |
| `Leaf.LeafWhirlwind` | 4,7 | 8,4 |
| `Leaf.LeafHurricane` | 4,7 | 7,7 |
| Les 3 gardes | 7,8 | 9,6 à 10 |
| Les 12 pas de garde | 6,6 à 6,9 | 8,8 à 9,0 |

**La signature de chaque kit** (d'après `docs/characters/FICHES_MOUVEMENT.md`) :
- **Lee :**
  - la garde du Gōken : main ouverte tendue devant, l'autre dans le dos, en fente profonde ;
  - ses coups sont surtout des coups de pied ;
  - la main du dos ne sort que pour le Heavy, le direct dur en fente.
- **Sasuke :**
  - de profil, la main arrière près du menton et la main avant basse et ouverte ;
  - un temps d'arrêt, puis un départ sec ;
  - ses coups de pied montent : le 3e coup va au menton, le LionKick lance l'adversaire, le Sweep se fait une main au sol.
- **Naruto :**
  - une garde basse et ouverte, les coudes écartés, sur la pointe des pieds ;
  - de grands armés, des coups qui vont trop loin : le crochet dépasse, le Heavy est un coup de poing balancé qui l'emporte, le coup de pied du 3e coup le déséquilibre et lui fait battre des bras.

**Ce qui reste :**
- les coups de pied tournants font encore glisser un peu le pied d'appui (11 à 25 st/s) ;
- les sauts (AirFlip, LotusEntry) gardent les à-coups du décollage ;
- le métier des directs rapides n'est pas mesurable : leur contact tombe avant 0,12 s.

## 2. Les cinq natures : `Client/InfusionFX`, effets `Infusion.<Nature>`

| Nature | Le kunai en vol | L'impact | Le 3e coup (le membre) | Sur le corps touché |
|---|---|---|---|---|
| Feu | flammes le long de la lame, braises | gerbe de feu, braises, lumière | flammes autour du pied | il brûle 2 s, de la fumée à la tête |
| Vent | deux croissants pâles qui tournent, un long sillage fin | trois entailles croisées, un anneau de poussière | une spirale de vent, des traits | — |
| Foudre | des arcs qui courent sur l'acier et se redessinent | éclairs courts, flash blanc | des étincelles qui crépitent | des arcs pendant l'immobilisation |
| Terre | des éclats de pierre gainent la lame, de la poussière | des pierres qui se détachent, de la poussière | une plaque de pierre sur le tibia | des éclats sautent des avant-bras (garde entamée) |
| Eau | un manchon d'eau, un ruban de gouttes | une éclaboussure, des gouttes, une onde | des gouttes, un ruban | il dégouline pendant le ralentissement |

- **La maîtrise de l'élément** grossit et densifie tout, de 35 %.
- **Ce que le client lit** (les champs du DEV, `Server/NinjaArts`) :
  - le `ninja` du projectile ;
  - le `ninja` du combattant (`nature`, `blade`, `strong`, `ready`), avec `attackName == "Light3"` ;
  - les impacts de style `"infusion"`.

## 3. Le parchemin explosif et la fumée : `Client/NinjaToolsFX`

- **Le parchemin :**
  - une bande de papier, avec un cadre et un trait de sceau rouges, faits en pièces (aucune lettre) ;
  - en vol, elle est nouée à l'anneau du kunai et flotte derrière ;
  - **posée** (la charge `look = "tag"` des Families), le kunai est planté, la bande brûle vers le nœud pendant la seconde de mèche (braises, lumière qui monte) ;
  - **l'explosion** (impact `look`, `kind = "tag"`) : une gerbe de feu, des morceaux de papier, un anneau et de la fumée.
- **La bombe fumigène :**
  - un nuage blanc épais d'un coup, qui tient 1,5 s puis s'éclaircit (impact `zone`, `kind = "mist"`, `smoke = true`) ;
  - le projectile `kind = "smoke"` est dessiné aussi : une boule sombre, une bande de papier, une mèche.

## 4. Les trois transformations : `Client/TransformFX` et 3 clips

| Kit | Ce qui se voit | Clip | Ce qui fonctionne déjà |
|---|---|---|---|
| Sasuke, Wall Chidori | sur le mur, la foudre mord la paroi : une brûlure tracée sous sa main pendant la charge, des étincelles, puis le plongeon | `Lion.WallChidori.Channel` (accroupi contre le mur, le Chidori traîné bas) | l'effet : il lit `castId == "Chidori"` et `wall` |
| Naruto, Rasengan lancé | la sphère file en tournant, des bandes de vent autour, un sillage bleu | `Legion.RasenganThrow` (lancer par-dessus l'épaule, il dépasse) | rien encore : il faut le nœud et le projectile `kind = "rasengan"` (DEV) |
| Lee, Lotus vers Dynamic Entry | du cratère du Lotus, il rebondit et revient pieds en avant ; des images vertes le long du saut, un anneau au décollage | `Leaf.LotusEntry` | rien encore : il faut la variante `attackVariant = "LotusEntry"` (DEV) |

## Tests

- `tests/InfusionFX.spec` : 7 tests. Les 5 natures (kunai, impact, membre, corps), les champs du DEV, le parchemin, la fumée, la charge posée, les transformations.
- `SyphoClips` : les 865 clips, chaque boucle se referme et aucun saut d'une image.
- La suite et les 4 builds sont verts.
