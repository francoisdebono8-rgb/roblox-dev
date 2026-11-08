# Lot 3 animation : jutsu et éveils — audit Studio et éveils refaits (08/11)

Branche `work/anim-lot3-jutsu` depuis `claude/ninja-duel-2026-10-14` @ `dde1a6a`. Demande : « passer aux animations visuelles des techniques jutsu, éveil ; il y a des techniques qui n'ont pas encore d'animation du tout ».

## 1. Audit dans Studio (ND-DEV `debug @ 4a8ec28`)

**Méthode.** Les 72 techniques des 8 persos de la bêta (4 rapides + 4 à 5 jutsu à signes chacun), l'éveil et l'ultime ont été lancés un par un par `ServerStorage.NinjaDuelDev` (vraies requêtes serveur, adversaire figé). Chaque lancer a été enregistré côté client pendant 3,6 s : position des 15 parties du corps et nombre d'objets d'effets. Les éveils ont été pris en capture.

**Corps.** Chaque technique a un clip, sauf celles qui passent par un coup, une téléportation ou une séquence. Ces clips sont calés sur le timing serveur : une technique dure en tout 0,2 à 0,8 s de corps. Les manques réels sont listés ci-dessous.

| Technique | Ce qui se passe | À qui |
|---|---|---|
| Dash signature au chakra (Lee *Afterimage*, Minato *Flying Thunder*, Kakashi *Headhunter*, Neji *Rotation*, Itachi *Crow Scatter*) | Le serveur déplace le corps d'un coup, sans état. Le client n'a donc rien à animer : pas de départ, pas d'arrivée. Neji n'a même pas son *Rotation* (aucune rotation du corps). | DEV : il faut un état ou un événement pour poser un clip (issue) |
| Arrivée de *Lightning Strike* (Minato) et *Lightning Cut* (Kakashi) | La téléportation enchaîne directement sur le DashAttack, sans pose d'arrivée. Déjà dans les besoins de l'audit feel du 07/11. | ANIMATEUR, après l'état DEV |
| *CloneRasengan*, *CloneThrow* (Naruto), *BurstStrike* (Minato) | Seul le clip *Channel* existe : la sortie et la fin restent en pose procédurale. | ANIMATEUR (lot 3b) |
| *Naruto Rendan*, *Primary Lotus* | L'approche de la séquence (64 studs/s) n'a pas de coup nommé : le corps court, puis le Launcher générique part. | ANIMATEUR, une fois le coup d'ouverture propre à chacun nommé côté serveur |

**Éveils.** Sur les 8 persos, une fois l'entrée passée (dalles cassées, identiques pour tous), l'éveil ne se voyait presque plus :
- Sasuke : teinte rose au sol ;
- Naruto : coque rouge pâle et une queue de 10 billes en Neon uni, le look « vieux Roblox » refusé par la bible VFX ;
- Gaara : deux boules de sable ;
- Lee : vapeur à peine visible ;
- Neji : un disque au sol ;
- Itachi : yeux rouges seulement ;
- Kakashi : sol rouge ;
- Minato : sol jaune.

Captures prises en qualité graphique « Automatique », puis refaites en qualité 10 pour Sasuke, Naruto, Gaara et Lee : même constat.

**Découverte : la qualité graphique change tout.** En « Automatique », sur un Mac chargé (ND-FILM tournait en même temps), Roblox supprime la plupart des particules. Le manteau d'éveil de 55 particules disparaissait. En qualité 15, les mêmes réglages deviennent un mur de feu. Conséquences :
- un effet doit rester lisible quand les particules sont rares (lumière, formes) ;
- les preuves Studio doivent indiquer la qualité utilisée. Ce rapport utilise 10.

**Les effets des jutsu.** Le compteur d'effets ne voit que ce qui est posé dans l'arène, pas ce qui est accroché au corps. Les jutsu qui restent sous 5 nouveaux objets sont à revoir à l'œil en premier (lot 3b) :
- Sand Armor, Third Eye, Sand Clone, Quicksand ;
- Remove Weights, Drunken Fist ;
- Gentle Counter, Eight Trigrams Field ;
- Sharingan Paralysis, Read ;
- White Chakra Sabre, Space-Time Barrier.

## 2. Ce qui change (fichiers ANIMATEUR)

- **`src/Client/AwakenFX.luau` (nouveau) :**
  - Chaque éveil a son propre aspect pendant toute sa durée, plus une entrée qui lui est propre.
  - Il remplace le manteau commun.
  - Style de la bible VFX : animé, un peu de couleur, peu de couches, pas de Neon uni. Les textures sont celles du 06/11, déjà envoyées sur Roblox.

| Perso | Pendant l'éveil | Entrée |
|---|---|---|
| Sasuke (marque maudite) | fumée sombre et langues violettes côté marqué | fumée au sol, traits violets, anneau |
| Naruto (chakra de Kyūbi) | le manteau rouge brûle sur chaque membre | gerbe de feu, fumée, anneau |
| Gaara (sable de Shukaku) | trois courants de sable tournent autour de lui, des grains en l'air | souffle de sable, éclats |
| Lee (huit portes) | vapeur verte sur tout le corps, qui augmente à chaque porte ouverte (la peau rougit déjà, LeeFX) | poussière, vapeur, feuilles |
| Neji (Byakugan, champ total) | chakra dans les deux paumes, une onde du champ au sol toutes les 1,3 s | grande onde, éclair blanc |
| Itachi (focus du Sharingan) | plumes qui tombent des épaules, brume rouge aux pieds | envolée de plumes, anneau rouge |
| Kakashi (Sharingan découvert) | la foudre crépite dans la main droite | éclairs, anneau |
| Minato (éclair jaune) | étincelles dorées arrachées au corps, plus il va vite, plus il y en a | formule 飛雷神 au sol, éclats |

- **Sécurité :**
  - Une erreur dans ce module ne bloque jamais l'image d'Effects. Elle est attrapée et signalée une seule fois.
  - L'éveil se reconstruit si le modèle a été réutilisé : en Studio, un duel relancé pendant un éveil laissait l'éveil suivant vide.
- **`src/Client/NarutoFX.luau` :**
  - la queue de Naruto devient une flamme le long de la même courbe (les billes sont invisibles) ;
  - les oreilles prennent la matière de la coque au lieu du Neon.
- **`src/Client/Effects.luau` : une seule ligne**, l'installation de la couche, comme les autres modules `*FX`. Fichier partagé : à relire par le DEV.
- **`tests/AwakenFX.spec.luau` (nouveau)**, branché dans `run.sh`. Il vérifie que :
  - les 8 persos ont leur éveil ;
  - l'éveil est construit une seule fois puis effacé à la fin ;
  - il n'y a pas de Neon ;
  - une faute ne bloque pas l'image.

## 3. Preuves

- Suite headless : **45/45 PASS** (lune 0.10.4 avec un équivalent local de `CFrame:FuzzyEq`). `test_build_isolation` 11/11.
- Studio, code poussé à chaud dans ND-DEV puis retiré (la place n'a pas été enregistrée), en qualité 10 à 15 :
  - la vapeur de Lee se voit nettement ;
  - le manteau de Naruto fait vraiment une aura de feu ;
  - les réglages finaux ont été recalés entre les deux essais.
- **Pas prouvé :**
  - Je n'ai pas revu les 8 éveils dans leur version finale : ND-FILM tournait en même temps sur le Mac, les captures échouaient et j'ai arrêté pour ne pas gêner le tournage.
  - Pas de vidéo.
  - Pas de manette.

## 4. Suite (lot 3b)

1. Revoir les 8 éveils à l'œil en qualité 10 puis 3, quand le Mac est libre.
2. Revoir à l'œil les 12 jutsu de la liste ci-dessus et refaire leurs effets.
3. Clips de sortie et de fin pour *CloneRasengan*, *CloneThrow* et *BurstStrike*.
4. Clips des dashes signature et des arrivées, une fois l'état demandé au DEV disponible.
