> Rapport d'intégration (issue #45, reprise du 07/11). État et règles : [sources actives](../../active/EXECUTION_RULES.md).

# Intégration de `claude/perception-sharingan` dans la branche de référence (07/11/2026)

Branche intégrée : `claude/perception-sharingan` @ `8afa3cc` (10 commits,
06–07/11, discussion DEV « perception »). Base : `claude/ninja-duel-2026-10-14`
@ `2a314ff` (travaux #45 : profil FILM, identité runtime, Mac rangé). Branche
de travail : `work/dev-45-sharingan` (fusion `--no-ff`, historique des deux
côtés conservé, sans réécriture).

## 1. Ce qui entre dans le jeu (tout, sans retrait)

| Commit | Apport |
|---|---|
| `a0fd75b` | Le Sharingan lit les jutsu de vitesse ; les yeux ordinaires voient une traînée d'encre (`Shared/Sight`, `Client/PerceptionFX`, lecture par l'IA) |
| `d43d000` | Byakugan : le réseau de chakra de l'adversaire, les points fermés en sombre (`Client/ByakuganFX`, `Sight.chakraSight`) |
| `fc5cd72` | Multiclonage de Naruto : une vraie foule de 10 clones ; la même touche prend le corps de n'importe quel clone (`Server/Legion`, `Bodies`, `BodyViews`) |
| `885dd8b` | Kakashi : le Sharingan copie le jutsu lancé devant lui (`Server/Copy`, `Client/CopyFX`) |
| `9d5e328`, `dbf36e8` | Les ninken de Kakashi creusent jusqu'aux jambes et tiennent, ou poursuivent (`Server/Hounds`, `Client/HoundFX`) |
| `98f28a0` | Interactions : l'eau conduit la foudre, le Katon court le long du fil, le feu avale le Wind Cut, choc Rasengan/Chidori, les portes de Lee annoncées |
| `e2ff5a3` | Vitesse, charge de chakra, saut, combat aérien et sol revus dans Studio ; Flamme du dragon, Rasengan/Chidori et Mirage lisibles |
| `25981e1`, `8afa3cc` | Places Debug de la branche : **non reprises** (les quatre places sont reconstruites par `build.py` après fusion) |

Conflits : `dist/NinjaDuel-Debug.*` (gardés côté référence, reconstruits) et
`CURRENT_STATE.md` (les deux entrées gardées). `build.py`, le profil FILM,
`tools/capture` et l'identité runtime viennent de la référence, inchangés.

## 2. Les neuf suites en échec : causes et corrections

Reproduites avec luau/lune sur la fusion (les commits de la branche
indiquaient « suites headless non lancées »). Neuf suites en échec : sept
nouvelles, et les deux échecs historiques de la référence (Chakra, Identity,
le second masqué par un nouvel échec dans la même suite).

| Suite (ligne) | Message | Cause | Classement | Correction |
|---|---|---|---|---|
| Combat (130) | l'air string après la poursuite ne jongle pas | `Brawler.chaseArrived` n'arrivait plus qu'à une vitesse de montée ≤ 12 studs/s : chaque poursuite après un lanceur durait ses 0,5 s entières et le coup suivant sortait de sa fenêtre | régression de gameplay (effet de bord d'un correctif Studio) | arrivée quand le poursuivant est **au niveau** d'un corps qui monte à ≤ 30 studs/s, ou près de l'apex (≤ 12). Le cas vu dans Studio (arrivé 4,5 studs **sous** un corps qui monte à 25 studs/s) reste corrigé |
| ComboModel (415) | « Flashstep: the chase never arrived » | même cause | régression | même correction |
| Regression (315) | « slam teleported 5.8 studs in one frame » | banc de test : `hum:Move` du harnais marchait le temps écoulé depuis son dernier appel (jusqu'à 0,1 s) au lieu d'une image ; la poursuite plus longue laissait plus de vitesse au moment du slam | harnais (pas de téléportation dans Studio) | harnais : une image (le `dt` de `Combat:update`) |
| Identity (Byakugan) | `ByakuganFX:233: attempt to compare nil < number` | les pièces du faux décor n'avaient pas `LocalTransparencyModifier` (0 par défaut sur une BasePart) | harnais | valeur par défaut ajoutée au faux décor |
| Identity (1175, historique) | « the lane is not drawn as one strip (6) » | la traînée d'Itachi est dessinée par `Effects` depuis la passe jutsu (marques irrégulières), mais `IdentityFX` dessinait encore par-dessus son ancienne bande (planche d'ardoise + deux bords néon) : chaque traînée en double | **bug visuel réel** + test devenu obsolète | bande d'`IdentityFX` retirée ; test réécrit sur le contrat de la passe jutsu (5 segments enchaînés ≥ 20 studs, pas de néon, le feu s'éteint avec la zone) |
| Chakra (951, historique) | « seal life or burn edge missing » | la passe jutsu (06/11, demande utilisateur) a coupé par défaut les anneaux de graduations des sceaux et du feu | test devenu obsolète | test : aucun anneau par défaut ; l'interrupteur (`SealTicks`/`BurnTicks`) les ramène et ils comptent toujours |
| Lee (313) | « the gate opening is not in the feed » | deux annonces de chaque porte (celle de l'étape 6 et `Techniques.gateStep` de la branche) : la 1re porte dessinée sur l'éveil, chaque porte deux fois | **bug réel** (doublon) | l'ancienne annonce retirée : une seule par porte |
| Naruto (723) | « Legion vs Flashstep: 10 clones out at once » | la foule de 10 est voulue (`fc5cd72`) ; le test plafonnait à 2 | test devenu obsolète | borne lue dans les données du perso : `max(Max, Crowd)` |
| Kakashi (40) | « the slot did not come back to the Water Dragon » | le délai d'1 s après un jutsu copié, prévu pour la foule copiée, valait pour toute copie : la touche répondait « recharge » au lieu du Dragon aqueux | **bug réel** | délai limité aux jutsu qui agissent encore après coup (`recast`, la foule) |
| Roster20 (269) | « nothing was absorbed » | Kakashi copiait le Sceau d'absorption de Nagato (Rinnegan) dans la case du Dragon aqueux | **bug réel** (règle incomplète) | les forces du Rinnegan ajoutées à ce que le Sharingan ne copie pas (un autre dōjutsu) |

Aucune suite désactivée, aucune assertion retirée. Trois attendus changés,
tous parce que le comportement voulu a changé (foule de 10, anneaux coupés,
traînée de la passe jutsu), avec la raison dans le test. Le harnais est corrigé
dans le sens de Studio (une image par pas, valeurs par défaut des BasePart).

## 3. Résultat

| | Référence `2a314ff` | Branche `8afa3cc` (fusion brute) | Intégré `0e579bf` |
|---|---|---|---|
| Suites headless | 39 PASS, 2 en échec | 9 en échec | **42 PASS, 0 échec** |
| `test_build_isolation` | 11/11 | — | 11/11 |
| QA native (ND-QA au Play) | 21 PASS / 16 FAIL | — | 21 PASS / 16 FAIL, mêmes cas ([QA-006](../../active/MASTER_BACKLOG.md)) |
| RUNTIME des quatre places | `1dfa3dbc4a16` | — | `aec22310b144` |

Studio (places du Mac reconstruites à `0e579bf`, sonde
[`sharingan_integration.luau`](../../../tools/studio/probes/sharingan_integration.luau)) :

| Interaction | Place | Vu |
|---|---|---|
| Foule de Naruto + prise de corps | ND-DEV | 10 clones ; la touche prend un clone à 17,4 studs |
| Byakugan contre Mirage | ND-DEV | réseau de chakra dessiné sur Itachi |
| Sharingan de Kakashi : copie | ND-DEV | Grande boule de feu copiée puis lancée ; la case revient au Dragon aqueux |
| Ninken | ND-DEV | Sasuke tenu (Bound) |
| Foudre dans l'eau | ND-DEV | arcs sur toute la flaque |
| Katon le long du fil | ND-DEV | Flamme du dragon jusqu'à Itachi lié |
| Rasengan contre Chidori | ND-DEV | relâchés ensemble : JutsuClash des deux côtés, les deux projetés (−3 PV chacun), cratère |
| Poursuite après lanceur | ND-DEV | arrivée 0,35 s, 2 coups en l'air, écrasement, à hauteur du corps |
| Partie joueur | ND-JEU | `release @ 0e579bf`, pas de DevHooks ; Naruto contre Neji aux vraies touches, Rasengan lâché, aucune erreur |

Non vérifié par Claude : la manette, et le jugement à l'œil en partie réelle
(HUMAN_FEEL PENDING).
