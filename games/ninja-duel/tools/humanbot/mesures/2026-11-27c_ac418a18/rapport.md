# Le robot humain

24 min de jeu : 102 clics et 113 touches, 64 boutons qui ont répondu ; 21 commandes du profil côté serveur, 0 refusées.

## refus muet — un bouton qui répond, une demande que le serveur refuse sans rien dire au joueur

| quoi | combien de fois | à l'écran | les gestes juste avant |
|---|---|---|---|
| Tournament.start:Legion | 1 | le jeu (vu par l'état du serveur : cup=false, lastLifecycle posé) |  |
| Tournament.start:Sand | 1 | le jeu (idem) |  |

## souris bloquée — un menu ouvert, la souris bloquée au centre : on ne peut viser aucun bouton

| quoi | combien de fois | à l'écran | les gestes juste avant |
|---|---|---|---|
| « CONTROLS » | 1262 | « CONTROLS » (Tab en duel, place ac418a18 (avant f68e504e)) | clic FIGHT · → FIGHT répond · note · Tab |
| « LOSS » | 4 | « LOSS » (le tampon LOSS avant l'écran DEFEAT : la souris reste au centre ~0,6 s) | clic · clic · clic |

## à-coup — une image de plus de 0,5 s

| quoi | combien de fois | à l'écran | les gestes juste avant |
|---|---|---|---|
| 2.1 | 1 | le jeu |  |
| 2.0 | 1 | le jeu |  |
| 1.6 | 1 | le jeu |  |
| 1.5 | 1 | le jeu |  |
| 1.4 | 2 | le jeu |  |
| 1.3 | 1 | le jeu |  |
| 1.2 | 2 | le jeu |  |
| 1.1 | 1 | le jeu |  |
| 1.0 | 2 | le jeu |  |
| 0.8 | 2 | le jeu |  |
| 0.7 | 1 | le jeu |  |
| 0.6 | 1 | le jeu |  |
| 0.5 | 1 | le jeu |  |

Images longues : 19 de 0.4 s ou plus (la plus longue 2.1145 s), une toutes les 56.3 s en moyenne.

## Les duels

| quoi | contre | qui tenait la manette | résultat |
|---|---|---|---|
| tournoi quart | THE UNTOUCHABLE | NDDuelBot joueur 1 | 2-0 |
| tournoi demi | THE FATED GENIUS | NDDuelBot joueur 2 + touches | 2-0 |
| tournoi finale | THE HARD WORKER | NDDuelBot joueur 3 | 1-2 |
| prodige de rue | THE UNTOUCHABLE (Sand, IA normal) | mains humaines (mash) | 0-2 |
| prodige de rue | THE UNTOUCHABLE | NDDuelBot joueur 4 | 0-2 |
| prodige de rue | THE UNTOUCHABLE | NDDuelBot joueur 5 | 1-2 |

## Deux joueurs

- Player1 ouvre la boutique ; Player2 : DUELS → ALL MODES → PLAYERS ONLINE (1 ONLINE • 1 READY) → CHALLENGE ×3 vite → un seul défi (le bouton passe à SENT…)
- Player1, dans la boutique, voit PLAYER2 CHALLENGES YOU (ACCEPT / DECLINE, ENTER ACCEPTS • BACKSPACE DECLINES) par-dessus la boutique ; il l'ignore : le défi tombe au bout de 20 s
- nouveau défi : Player1 appuie sur Backspace dans la boutique → PLAYER1 DECLINED
- Player2 redéfie aussitôt → WAIT A MOMENT BEFORE THE NEXT CHALLENGE (sans dire combien de temps)
- 10 s plus tard, défi ; Player1 appuie deux fois sur Entrée : la 1re accepte, la 2e le met READY (il n'a pas choisi son ninja)
- Player2 choisit THE LOUDMOUTH (verrouillé) puis READY : il se bat en THE AVENGER, sans un mot
- pendant tout le duel, et encore sur l'écran de victoire, Player2 garde le bandeau CHALLENGE SENT TO PLAYER1 • WAITING… avec CANCEL ; CANCEL répond au clic et ne fait rien (Lobby:accepted, même serveur → pairHere, aucun statut envoyé au défieur)
- duel en ligne aux mains humaines des deux côtés (touches au hasard + clics) : Player2 gagne 2-0
- Player2 clique REMATCH pendant que Player1 clique BACK TO KONOHA : Player1 rentre au village, le bouton de Player2 devient OPPONENT LEFT
- serveur : rankedResult pour les deux, +200 maîtrise et +150 Ryō au gagnant, +120 et +20 au perdant, aucun paiement en double

- client-1 (Player2, le défieur) : 99 clics, 64 touches, 1 images de 0.4 s ou plus ; souris bloquée : « CONTROLS » ×3882; à-coup : 0.5 ×1.
- client-2 (Player1, le défié) : 47 clics, 77 touches, 0 images de 0.4 s ou plus ; aucun bug.

Le serveur : gainMastery ok, earnRyo ok, dailyRecord ok, earnItem ok, gainMastery ok, earnRyo ok, dailyRecord ok, soloRecord ok, earnItem ok, gainMastery ok, earnRyo ok, gainMastery ok, earnRyo ok, gainMastery ok, earnRyo ok, soloRecord ok, gainMastery ok, gainMastery ok, earnRyo ok, gainMastery ok, earnRyo ok.

## Ce que les mains ont vu et que le témoin ne sait pas voir

Observations de Claude pendant le jeu (pas l'avis de François), place ac418a18, clavier AZERTY du Mac.
TECHNICAL : vérifié dans l'état du serveur ou dans le code. HUMAN_VISUAL_FEEL : lu à l'écran.

1. TECHNICAL — TOURNAMENT avec un kit verrouillé : la page d'entrée s'ouvre, on dépense ses 100 points, ENTER (ou BEST BUILD) ferme la page et rien ne se passe. Le serveur refuse (Tournament.start : Progression.owns faux) sans un mot. Reproduit à la main : clic sur THE UNTOUCHABLE (LOCKED), TOURNAMENT • VS AI, ENTER (images 18 à 20). Le VS laisse choisir un kit verrouillé comme YOU, et l'étiquette YOU cache l'étiquette LOCKED de la tablette choisie (image 17).
2. TECHNICAL — BEST BUILD et NEW TOURNAMENT donnent un build vide à un joueur qui n'a rien appris : NEW TOURNAMENT a démarré « YOUR BUILD 0 / 100 » sans page d'entrée (en-tête du tableau lu par le témoin ; cup.build.spent=0 côté serveur). Cause dans le code : Tournament.defaultBuild(fighter, own) garde `own` dès qu'il est admis, et une liste vide l'est (0 point) ; avec nil le serveur propose 14 nœuds. BEST BUILD passe par le même chemin (nodes=nil) : vérifié en appelant Tournament.defaultBuild("Lion", ses nœuds) sur le serveur → 0 nœud ; pas joué jusqu'au tableau.
3. HUMAN_VISUAL_FEEL — finale perdue : l'écran dit « THE HARD WORKER ADVANCES » et le bouton « SEE WHO WINS IT • THE BRACKET », alors que c'était la finale (image 29). Le tableau de fin dit « Out this time » sans la prime du finaliste ; le serveur a pourtant versé +150 Ryō et +60 maîtrise (Progression.cupEnded, montré seulement à un champion) (image 30).
4. HUMAN_VISUAL_FEEL — les écrans de gain disent « … more: Naruto, Itachi, Kakashi will want to meet you » : les vrais noms, alors que le jeu dit THE AVENGER, THE LOUDMOUTH… partout ailleurs (images 25, 29, 34).
5. HUMAN_VISUAL_FEEL — LEAVE est collé à SKIP sur chaque écran du tableau et quitte le tournoi d'un clic, sans confirmation (images 22, 28, 31).
6. TECHNICAL — CONTROLS (Tab) sur un clavier AZERTY : Dodge et Escape affichés « A », Chakra « W » (les touches AZERTY de Q et Z : juste), mais Move reste « WASD » en dur. Sur ce clavier, « A » se lit à la fois « aller à gauche » et « esquiver » (image 33). Le village dit « SHIFT RUN », le duel « CTRL Sprint / SHIFT Lock ».
7. TECHNICAL — le prodige de rue (THE UNTOUCHABLE, IA normal, kit sans nœud appris) a battu trois fois le joueur : mains au hasard 0-2, robot de duel 0-2 et 1-2 ; le même robot a battu THE UNTOUCHABLE 2-0 en quart de tournoi avec 35 points de build. Petit échantillon, robot et non humain.
8. Tenu : ENTER double-cliqué ne lance rien sous la page ; SKIP ×5 ne saute qu'un match ; REMATCH puis BACK TO KONOHA 160 ms après : la revanche gagne la course ; E deux fois sur le prodige : un seul défi ; aucune ligne rouge, aucun paiement en double, Ryō justes (1000 → 1605).
9. À revoir (non expliqué) : en spectateur, deux clics sur SKIP n'ont touché aucun bouton ; un troisième 34 s plus tard a marché.

Deux joueurs (multiplayer_playtest, 2 clients) :

10. TECHNICAL — le défieur garde « CHALLENGE SENT TO PLAYER1 • WAITING… » et CANCEL pendant tout le duel et sur l'écran de victoire ; CANCEL répond et ne fait rien. Cause dans le code : Lobby:accepted, même serveur → pairHere sans statut au défieur (le bandeau « cancellable » ne se cache jamais seul).
11. HUMAN_VISUAL_FEEL — un défi arrive par-dessus la boutique avec « ENTER ACCEPTS • BACKSPACE DECLINES » : Backspace dans la boutique a refusé le défi ; deux Entrée ont accepté ET validé READY sans choix du ninja.
12. HUMAN_VISUAL_FEEL — « WAIT A MOMENT BEFORE THE NEXT CHALLENGE » ne dit pas combien (10 s).
13. Tenu : CHALLENGE ×3 → un seul défi ; défi ignoré → tombe à 20 s ; kit verrouillé choisi en ligne → il se bat avec le sien ; REMATCH contre BACK TO KONOHA → OPPONENT LEFT ; classement et gains justes pour les deux.
14. Mesure : 19 images de 0,4 s ou plus en 24 min de Play solo (jusqu'à 2,1 s), 1 en 10 min sur les clients du test à deux. Même place ; je ne sais pas encore d'où vient l'écart.
