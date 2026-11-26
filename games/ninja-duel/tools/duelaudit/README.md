# Le robot de duel et son témoin (OUTILLEUR, passe commune 2, 26/11, DEC-054)

La demande : « un robot de duel qui joue des duels complets (les 8 kits, et l'avatar) et relève chaque incohérence : corps bloqué, coup qui traverse, chute dans le sol, caméra dans un mur, erreur en rouge ».

Deux robots travaillent ensemble pendant un Play de la place du jeu (DEC-052) :
- **Le joueur simulé** (`NDDuelBot`, `tools/duelbot`). Il joue des duels complets par la télécommande du jeu, avec l'avatar de François (le corps de duel est son avatar Roblox, `Server/AvatarBody`).
- **Le témoin** (`NDDuelAudit`, `duel_audit.luau`). Il regarde chaque image de chaque duel depuis le client, comme le joueur la voit, et garde ce qui ne tient pas.

Côté serveur, `NDServerLog` (`server_log.luau`) garde les lignes rouges du serveur et ses images (à-coups).

| Incohérence | Ce que le témoin mesure |
|---|---|
| corps bloqué | le stick tenu, le corps libre (état `Neutral`, au sol, sans réaction), et il bouge de moins de 0,6 stud en 1 s, sans l'adversaire ni un mur devant lui |
| état figé | un corps tenu 6 s dans le même état, autre que libre, garde ou K.O. |
| corps l'un dans l'autre | les deux racines à moins de 1,4 stud l'une de l'autre, hors prise |
| coup qui traverse | pendant un coup, une main, un pied, un avant-bras ou un tibia du frappeur à plus de 0,35 stud dans le torse, le bassin ou la tête de l'autre |
| coup de loin | le serveur compte un contact alors qu'aucun de ces membres n'est à moins de 2,5 studs du corps de l'autre, dans les images autour du contact |
| dans le sol | le point le plus bas du corps (ses boîtes) à plus de 0,7 stud sous le sol, mesuré par un rayon vers le bas. Les effets du duel, comme la bûche de la substitution, ne comptent pas comme sol |
| sous le sol | la racine 2,5 studs sous sa hauteur de départ |
| caméra dans un mur / un objet / le terrain | la caméra dans une pièce dessinée du décor. Les maillages comptent par leur boîte réduite à 80 % |
| combattant caché | la tête et la racine d'un combattant cachées par le décor pendant 0,5 s |
| erreur en rouge | une ligne rouge de la sortie du client ; celle du serveur vient de `NDServerLog` |

Pour les premières incohérences de chaque sorte, le témoin garde l'image : les deux corps tels qu'ils étaient. `show(run, i)` les repose à leur place, avec une marque rouge, les écrans cachés. La caméra se met sur le côté des deux corps. On fait alors `capture_screenshot`.

## Lancer

Dans une Studio à soi (voir `tools/robots/README.md`), pendant un Play :

```sh
python3 tools/robots/inject.py --server serverlog   # Serveur : puis _G.NDServerLog.start()
python3 tools/robots/inject.py duel audit           # Client
python3 tools/duelaudit/report.py --start           # Client : le témoin, puis les 8 kits, chacun contre le suivant
python3 tools/duelaudit/report.py --read            # Client : le JSON du témoin
python3 tools/duelaudit/report.py --show 2 3        # Client : l'image de l'incident 3 du duel 2 (puis capture_screenshot)
python3 tools/duelaudit/report.py MESURE.json --md RAPPORT.md
```

Le profil de jeu d'un Play est neuf et en mémoire. Les 8 kits sont appris pour ce Play seulement, côté serveur : `Progression.handles[joueur].data.kits.owned`, et seulement si la réserve est celle de la mémoire. Le duel exige un kit appris.

## Le 26/11 (place commune `f28b8ba1`, avant la passe 2)

Fichiers : `mesures/2026-11-26_avant_f28b8ba1/` (`duels.json`, `rapport_duels.md`, les images).

- 11 duels, soit environ 12 minutes de combat :
  - les 8 kits joués avec l'avatar de François, chacun contre le suivant des 8, IA `normal` ;
  - puis 3 duels rejoués avec une tenue, pour les images. Un profil neuf ne porte que le bandeau ; voir plus bas.
- Le total :
  - 18 corps bloqués et 12 coups qui traversent ;
  - 12 coups de loin ;
  - 53 passages dans le sol et 2 corps l'un dans l'autre ;
  - 3 combattants cachés et 1 erreur rouge, vue deux fois.
- Aucune caméra dans un mur, aucun état figé, aucun corps sous le sol.

Ce sont des mesures de Claude (TECHNICAL / NATIVE_STUDIO), pas l'avis de François. Les images montrent ce qu'elles veulent dire :

| Image | Ce qu'on voit |
|---|---|
| `01_traverse_slam_main_dans_la_tete.jpg` | Sasuke (l'avatar), Slam : la main gauche bandée dans le visage de Naruto |
| `02_traverse_kakashi_dans_le_corps.jpg` | Kakashi au coup de pied : son corps dans celui de l'avatar |
| `03_coup_de_loin_7_studs.jpg` | Itachi (l'avatar) frappe dans le vide, Kakashi en l'air à 11 studs : le coup compte |
| `04_superposes_lee.jpg` | l'avatar (Gaara) et Lee l'un dans l'autre |
| `05_bloque_vitesse_serveur_0.jpg` | l'avatar (Gaara), stick tenu, debout sur les débris d'un cratère, le serveur dit vitesse 0 |
| `06_dans_le_sol_tete_de_naruto.jpg` | Naruto à terre : la tête et le torse sous le sol de la cour |
| `10_entrainement_sasuke_chidori_planche.jpg` | l'entraînement de Sasuke, l'étape Chidori qui ne passe pas (planche de 10 images) |

## Ce qu'il ne prouve pas

- **Les corps sont mesurés par leurs boîtes** (les parts du corps R15). Un poing arrondi dans une boîte carrée peut paraître plus loin ou plus près de quelques dixièmes de stud.
- **Le « coup de loin » de Gaara** est sa main de sable : le sable porte le coup, pas un membre. À regarder en jeu (le sable va-t-il jusqu'au corps ?) avant d'y voir un défaut.
- **Le joueur simulé n'est pas un joueur.** Il pousse le stick, frappe, garde, comme un joueur moyen. Un « corps bloqué » dit qu'avec ce stick-là, le corps ne bougeait pas ; à revoir en jeu.
