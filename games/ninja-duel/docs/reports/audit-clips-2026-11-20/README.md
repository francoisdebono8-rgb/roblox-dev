# Audit SyphoDev des animations des 8 kits (20/11, étape 1 ANIMATEUR)

Demande : `claude/jeu-fini-vision-etapes-regles-2026-11-20`, étape 1, ANIMATEUR 1. Chaque clip est noté et les pires sont classés.

Skills suivis : `ninja-animation-direction`, `roblox-animation` (méthode SyphoDev, `docs/tools/METHODE_SYPHODEV.md` § 3 et § 4).

## Comment c'est mesuré

On commence par les chiffres, sans image. Les 845 clips des 8 kits sont posés image par image sur le corps qui les joue : l'avatar du joueur, `tools/syphodev/rig.json` = `World.RIG`. La pose suit la chaîne des Motor6D avec les vraies boîtes des parties (`tools/syphodev/audit_clips.py`). Chaque clip est ensuite noté sur 10 par `tools/blender/clip_grades.py` :

- **Propreté** (jusqu'à −6) : ce qu'un joueur voit casser.
  - le corps qui passe sous le sol ;
  - un pied d'appui qui glisse (il pèse moins que le reste, car le moteur bloque un pied lent et bas) ;
  - une main ou un avant-bras dans la tête ou dans le torse ;
  - une articulation qui se retourne, ou un à-coup d'une seule image ;
  - une boucle qui saute.
- **Métier** (jusqu'à −4, sur les 180 coups, les clips qui portent un marqueur `contact`) : les cinq poses d'un coup (§ 4.1), lues sur la trajectoire du membre qui frappe.
  - **Armé :** le membre recule d'au moins 0,15 stud avant de partir.
  - **Vitesse au contact :** au moins 18 studs/s, pour qu'on la lise à 20 studs.
  - **Accélération :** le membre va plus vite dans le dernier cinquième avant le contact.
  - **Accompagnement :** il continue d'au moins 0,08 stud après le contact.
  - **Buste qui suit :** le haut du corps avance avec le coup.
  - Un coup qui touche avant 0,12 s (les directs rapides, au timing du serveur) n'a pas le temps d'armer : son armé est la fin du coup d'avant, et on ne le pénalise pas pour ça.
- **Boucles figées** : un idle ou une garde où rien ne bouge de plus de 2° perd 1 point.

Pour refaire la mesure :

    lune run tools/syphodev/clips_dump.luau /tmp/clips.json
    python3 tools/blender/clip_grades.py tools/syphodev/rig.json /tmp/clips.json docs/reports/audit-clips-2026-11-20

Fichiers :
- `grades.json` : chaque clip, avec sa note, ses raisons et la mesure du coup ;
- `grades.md` : le tableau par kit et les 60 pires ;
- `kits_mesures.json` : la garde, le tempo et les clips propres à chaque kit, utilisés pour les fiches de mouvement.

Ce sont des chiffres (catégorie TECHNICAL). Les clips en tête de liste restent à regarder en planche et à la caméra du jeu au moment de les refaire (étape 2).

## Résultat

**845 clips, moyenne 8,6 sur 10 :**
- 124 clips à 10 ;
- 86 sous 7 ;
- 17 sous 5.

Sur les 180 coups, la note métier moyenne est de 3,0 sur 4.

| Kit | Clips | Moyenne | Métier des coups /4 | Sous 5 | Sous 7 |
|---|---|---|---|---|---|
| Naruto (Legion) | 106 | 8.9 | 3.3 | 1 | 6 |
| Sasuke (Lion) | 110 | 8.6 | 2.9 | 3 | 11 |
| Lee (Leaf) | 100 | **7.9** | 3.0 | **6** | **21** |
| Neji (GentleFist) | 103 | 9.0 | 2.7 | 0 | 4 |
| Gaara (Sand) | 104 | **7.8** | 2.6 | 2 | 13 |
| Kakashi (Copycat) | 113 | 8.8 | 3.2 | 1 | 11 |
| Itachi (Mirage) | 108 | 9.0 | 3.1 | 2 | 6 |
| Minato (Flashstep) | 101 | 8.8 | 2.9 | 2 | 14 |

## Les pires, classés (les 25 premiers ; les 60 sont dans `grades.md`)

| # | Clip | Note | Ce qui ne va pas |
|---|---|---|---|
| 1 | `Lion.VaultKick` | 2.7 | corps 2,3 studs sous le sol, pied d'appui qui glisse à 57 st/s, à-coup sur une image (hanche et genou gauches) |
| 2 | `Flashstep.Sweep`, `Mirage.Sweep`, `Sand.Sweep` | 3.3 | corps 1,2 à 1,9 stud sous le sol, appui qui glisse de 2 à 4 studs, main dans la tête, aucun armé |
| 3 | `Leaf.Heavy` | 3.2 | appui qui glisse à 59 st/s sur 3,5 studs, bras dans le torse, à-coup sur une image, aucun accompagnement |
| 4 | `Lion.Light3` | 3.8 | appui qui glisse sur 2,7 studs, main dans la tête, aucun accompagnement |
| 5 | `Legion.Heavy` | 3.8 | corps 0,9 stud sous le sol, appui qui glisse sur 1,8 stud, à-coup sur une image |
| 6 | `Sand.DashAttack` | 3.8 | pied 0,8 stud sous le sol, main dans la tête (0,66), mains l'une dans l'autre |
| 7 | `Lion.Sweep` | 4.0 | corps 2,5 studs sous le sol, appui qui glisse à 70 st/s |
| 8 | `Leaf.LeafRising`, `Leaf.GorikiSenpu`, `Leaf.LeafHurricane`, `Leaf.LeafWhirlwind` | 4.0–4.7 | les coups de pied tournants de Lee : appui qui glisse (24 à 86 st/s), bras dans le torse (0,6 à 0,9) |
| 9 | `*.AirFlip` (8 kits) | 4.8–5.4 | le même salto partout, main dans la tête, à-coup sur une image (hanche et genou gauches), rien d'un coup |
| 10 | `Copycat.Heavy`, `Flashstep.Heavy` | 5.1–5.7 | appui qui glisse, à-coup sur une image |
| 11 | `Sand.Slam`, `Sand.SandArmor.Release`, `Sand.Light1`, `Sand.SandFist` | 5.2–5.6 | Gaara se met les mains dans la tête (0,7) et les bras dans le torse |
| 12 | `*.Guard.Step.*` (Naruto, Sasuke, Itachi) | 6.6–6.9 | les pas de garde gardent les poings dans la tête |
| 13 | **les gardes** de 6 kits (`Legion`, `Lion`, `Leaf`, `Copycat`, `Mirage`, `Flashstep`) | 7.8 | la même garde de boxeur, poings 0,85 stud dans la tête, mains l'une dans l'autre |

## Ce que les chiffres disent au-delà des notes

1. **Les 8 kits bougent pareil.**
   - **La garde :** 6 gardes sur 8 sont la même garde de boxeur, à 0,1 stud près (`kits_mesures.json`). Seuls Neji (paume ouverte, bras écartés) et Gaara (debout, bras bas) en ont une à eux.
   - **La course :** la même foulée chez tous, 9,3 studs pour 0,67 à 0,8 s ; le sprint est le même (9,5 studs, 0,53 s).
   - **Les directs :** même contact à 0,08–0,13 s chez Naruto, Lee, Neji, Kakashi, Itachi et Minato. Seuls Sasuke (jusqu'à 0,27 s) et Gaara (0,17–0,23 s) ont un tempo à eux.
   - C'est exactement ce que François dit sentir. Les fiches de mouvement (`docs/characters/FICHES_MOUVEMENT.md`) donnent à chacun son tempo, sa garde, ses appuis et sa signature.
2. **Le défaut le plus vu en jeu, ce sont les mains dans la tête en garde.** La garde se joue pendant tout le combat : c'est l'image qu'on voit le plus longtemps.
3. **Les coups balayés et les coups de pied tournants passent sous le sol et font glisser l'appui.** Ce sont les clips qui bougent le plus bas et le plus vite : Sweep, VaultKick, et les tourbillons de Lee.
4. **Plus de la moitié des coups n'ont pas d'accompagnement** (81 sur 180), et pour 85 le buste ne suit pas. Le coup s'arrête net au contact, ce qui donne l'impression de « coups qui touchent » sans poids : c'est le point le moins fun relevé le 05/11.
5. **Le salto `AirFlip` est le même chez les 8**, avec un à-coup sur une image : un clip à refaire par kit.

## Ce qui en découle

- **Étape 2 (Naruto, Sasuke, Lee) :** on refait d'abord la garde, les directs, le Heavy, le Sweep et le VaultKick, puis les tourbillons de Lee. Chacun se fait avec ses cinq poses et la signature de sa fiche, et on repasse ce même audit avant et après.
- **Les timings des coups sont au DEV.** Les fiches proposent des tempos différents par kit. Un timing ne change qu'avec son accord : je ne touche à aucun.
