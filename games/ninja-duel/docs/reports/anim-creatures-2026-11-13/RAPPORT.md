# ANIMATEUR — revue des animations sans Studio (13/11/2026)

Demande de François (12 h 16) : « la grenouille de Naruto, c'est pas bon, et on a plusieurs qui sont pas au point ». L'ordinateur n'est pas disponible : tout est vu hors Studio.

## Les outils de la revue (nouveaux)
- `tools/fx_preview/dump.luau` lance les vrais constructeurs du jeu en Lune : les créatures et objets de `FamilyFX` (toutes les formes de `Looks`) et les chiens de `HoundFX`. Il écrit chaque pièce dans un fichier JSON (forme, taille, position, couleur, matière).
- `tools/fx_preview/render.py` rend ce JSON dans Blender. C'est le dessin que le jeu construit, sans effets de particules ni lumière du jeu.
- `tools/blender/review_clips.py` (existant) donne les planches des clips de jutsu.
- Statistiques des clips (`clip_stats.txt`) :
  - l'amplitude de chaque clip (somme des débattements des articulations) ;
  - les clips de même nom presque identiques d'un perso à l'autre.

## Corrigé dans cette PR
1. **Gamakichi (Naruto)** :
   - **Avant** : 9 boules lisses qui grossissaient sur place puis disparaissaient.
   - **Après** : un vrai crapaud, dessiné dans `tools/blender/fx_toad.py` (35 pièces, sans maillage à envoyer). Large tête plate, gros yeux jaunes à pupille horizontale, paupières, gorge et ventre crème, joues gonflables, gilet bleu-violet, taches, mains palmées, pattes arrière repliées.
   - Il bondit hors de la fumée, atterrit en s'écrasant, gonfle les joues et crache au moment où la balle d'eau part. Ensuite il reste assis, respire, cligne deux fois et disparaît dans une bouffée.
   - Fichiers : `Client/ToadFX`, `Client/ToadModel`. Image : `gamakichi_apres.png` (rendu Blender de la même géométrie et de la même chronologie que le jeu).
2. **Dragon aqueux (Kakashi)** :
   - **Avant** : un ver rayé fin, avec une boule en guise de tête (`dragons_avant_apres.png`, en haut à gauche).
   - **Après** : un dragon d'eau à l'orientale (en haut à droite). Crâne long et museau relevé, mâchoire ouverte, crocs, cornes en arrière, longues moustaches, crête de nageoires, yeux pâles, corps d'eau translucide avec une nageoire sur deux, éclaboussures et gouttes.
3. **Dragon de terre (Kakashi)** : déjà refait dans #74 (en bas des images : avant / après).

## Ce qui n'est pas au point (relevé, pas encore corrigé)
**A. Gestes identiques chez les 8 persos** (écart de 0,4 à 0,7° : le même clip) :
- roue (Cartwheel) ;
- poursuite (Chase) ;
- au sol (Down) ;
- roulade arrière (Handspring) ;
- mise à terre (Knockdown).

Presque identiques : salto (Flip, 21 paires sur 28), saut en l'air (21/28), envol (16/28), réception (16/28), sprint (16/28). C'était déjà dans l'audit du 07/11, et ce n'est toujours pas fait.

**B. Jutsu presque immobiles** (le corps bouge à peine, ça ressemble à une attente) :

| Clip | Amplitude |
|---|---|
| Kakashi, Tracking Fang (sortie) | 13° |
| Itachi, Lecture du Sharingan (sortie) | 13° |
| Minato, Dieu du tonnerre volant (sortie) | 19° |
| Itachi, Genjutsu Mirage (sortie) | 26° |
| Itachi, Paralysie (sortie) | 46° |
| Neji, Byakugan | 62° |
| Minato, Sceau-piège | 66° |
| Gaara, Cercueil de sable | 82° |
| Gaara, Troisième œil | 101° |
| Gaara, Sables mouvants | 137° |

Les maintiens (boule de feu tenue, Chidori tenu : 23 à 26°) sont calmes par nature, mais ils devraient respirer.

**C. Les autres créatures**, vues en rendu, sont lisibles : les chiens ninja, le requin, les chiens qui tiennent, le bras de Shukaku. Elles restent simples (formes de base) : c'est à revoir en jeu.

## Pas fait
- Aucune vérification dans Studio : l'ordinateur est indisponible. Les animations du jeu (vitesse, effets, lumière) sont à voir en jouant.
- Les planches de Kakashi n'ont pas pu être rendues ici : son module de jutsu lit une capture Mixamo qui n'est que sur le Mac.
