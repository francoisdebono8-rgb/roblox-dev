# Mission FEEL (issue #44) — rapport APRÈS, tranche Neji et Minato

5 novembre 2026, 21:00–21:45 (heure de Paris). Rédigé par Claude après les mesures Studio. À lire avec `AVANT.md`.

## Ce qui a été testé

| Point | Valeur |
|---|---|
| Code | `42939bd` puis `8be877c` (branche `claude/ninja-duel-2026-10-14`). Gameplay de base inchangé ; changements limités à la caméra, aux appuis et à l'interface. |
| Build | ND-Test-travail (build Debug), un seul fichier de travail, pas de nouvelle version numérotée. Studio exécute le même code que `8be877c` : seul `Camera.luau` a été corrigé à chaud entre deux parties, puis le fichier a été reconstruit et recopié sur le Mac. |
| Studio | instance `7ed5fe09` ; un seul Studio ouvert cette fois (le Mac n'était plus saturé : images à 60 i/s, 0 à 1 à-coup par scène) |
| Contrôles | manette simulée par le plugin MCP (□ △ ○ × R1 L2 R3 L1) ; clavier ZQSD |
| Mesures | même enregistreur client (`tools/feel/recorder.client.luau`), journal serveur `DevFlight`, tests Lune `CameraFeel`, `FeelPress`, `Online` |

## État des preuves

| Preuve | État |
|---|---|
| NATIVE_STUDIO (journaux, mêmes scènes) | **obtenue** |
| Vidéo APRÈS | **échec** : OBS enregistre un écran noir depuis son redémarrage (aperçu noir, fichier de 2 Mo pour 70 s). L'encodage, lui, est réparé (1,2 % d'images ignorées au lieu de 89–99 %). Probablement une autorisation macOS d'enregistrement de l'écran perdue au redémarrage d'OBS, ou une source de capture qui ne vise plus le bon écran. Hypothèse non vérifiée : je n'ai pas touché aux réglages système. |
| HUMAN_VISUAL_FEEL | **PENDING** : il faut une partie à la vraie manette |
| LIVE_ROBLOX | non publié, non testé |

## Les comparaisons avant / après

### 1. Corps et caméra au mur (défaut 1)

| Situation | AVANT | APRÈS |
|---|---|---|
| Verrouillé, dos au mur, adversaire devant (Studio) | joueur hors cadre **100 %** des images pendant 5 s (prise 2) | hors cadre **0 / 240** images, au bord 4 ; adversaire hors cadre 0 |
| Libre à la manette (caméra par défaut), dos au mur (Studio) | joueur hors cadre **241 / 241** images (mesuré sur la première version APRÈS, sans le correctif « libre ») | joueur hors cadre **42 / 237** (les 0,7 premières secondes, le temps que la caméra pivote), adversaire hors cadre **0** |
| Même chose sans rendu (Lune, mur simulé) | joueur hors écran (verrouillé) | joueur et adversaire à l'écran, verrouillé et libre à la manette |

**Correction.** Quand un mur bloque la caméra, celle-ci cherche le cap dégagé le plus proche (±0,5, ±1, ±1,5 rad) et pivote le long du mur. Pendant ce pivot, elle cadre la paire, comme un verrou. Elle revient en place 0,6 s après que le mur ne gêne plus. La caméra souris n'est pas concernée : c'est le joueur qui la tient, et elle oriente le corps.

**Ce qui reste.** Dos au mur, le joueur est visible mais coupé en bas à gauche, et son corps est en partie transparent. À juger à l'œil.

**Risque.** Sur manette en caméra libre, la caméra qui pivote fait aussi tourner l'axe du stick : « avant » change pendant qu'on est acculé. À vérifier à la vraie manette.

### 2. Coup, réaction, caméra : le Heavy chakra de Neji (défaut 2)

| Situation | AVANT | APRÈS |
|---|---|---|
| Libre à la manette (comme la prise 1), 2 coups puis L2+△, bot à y 67,5 | adversaire hors cadre **109 images (≈1,8 s)** | **0** image hors cadre, 0 au bord ; joueur toujours dans le cadre |
| Verrouillé, même enchaînement | non mesuré | **0** image hors cadre |
| Vol rejoué sans rendu (Lune) | **107 / 150** images hors écran | **12 / 150** (le premier dixième de seconde de montée) |

**Correction.** Au-delà de 8 studs d'écart en hauteur, la caméra vise le milieu des deux corps, recule pour tenir toute la hauteur (plafond 66 studs au lieu de 48), suit plus vite, puis s'incline et s'élargit (au plus 0,6 rad et 16°) pour ce qui manque. Le lancer lui-même n'a pas changé : 66 studs, 2,4 s de vol.

**Classement.** AMUSANT À CONSERVER, désormais lisible. Il reste à juger si les 2,4 s de vol cassent le rythme. Ce n'est pas tranché : il faut le test de riposte à la manette.

### 3. Appuis refusés (défaut 3)

| Situation | AVANT | APRÈS |
|---|---|---|
| Latence simulée de 350 ± 80 ms (outil dev `lag`), 6 appuis (□ ○ □ △ ○ □) | **6 / 6 jetés en silence** (GATE, âges 342–450 ms) | 5 joués, 1 refusé par le combat (Committed) et signalé |
| Novice Neji contre IA facile, 25 appuis en 20 s | (sans rendu) ≈30 % refusés, sans aucun retour | 19 joués (9 directs, 10 mis en attente puis joués), 6 refusés (Committed 2, Cooldown 1, Reacting 3), **chacun suivi d'une ligne discrète** (BUSY, RECHARGING) ; 0 GATE |
| Minato : second FTG dans les 6 s | repère « COOLDOWN » invisible (le client n'affiche que les repères forts) | ligne discrète « RECHARGING » |

**Corrections.**
- Un appui qui arrive entre 0,3 et 1 s après son envoi est joué, sans son horodatage périmé. Au-delà de 1 s, il est toujours jeté. L'horodatage ne servait qu'à dater l'engagement, il ne donnait rien.
- Tout refus, et tout appui mis en attente puis jamais joué, s'affiche en petit gris sous la bande des repères pendant 0,6 s. Il ne remplace jamais un repère fort.
- Les appuis de chaque manche sont comptés (en retard, jetés, refusés, perdus) et envoyés à **AnalyticsService** en événements personnalisés (`Press_late`, `Press_gate`, `Press_refused`, `Press_lost`, champ 1 = combattant). On pourra donc mesurer en ligne la part d'appuis sans effet. Dans Studio, ces événements ne partent pas : à vérifier en live.

**Risque.** Un appui de 0,9 s peut sortir alors que le joueur pense à autre chose. Le compteur `Press_late` permettra de le voir.

### 4. Le saut (défaut 4) : correction du rapport AVANT

Mesure Studio, Neji, sur un code de saut identique avant et après :
- appui de 80 ms : **8,1 studs**, 0,62 s en l'air ;
- appui tenu 400 ms : **13,0 studs**, 0,81 s en l'air.

Un appui bref donne donc 62 % du saut complet, pas un « petit sautillement » : le rapport AVANT exagérait. La hauteur variable est **conservée** (liberté des experts) et le code n'a pas changé. À juger à la manette.

### 5. Le décor de bordure (défaut 5)

Les buissons au pied du mur et les cimes des arbres sont du décor (sans collision ni requête). Les pièces proches d'un combattant, ou placées entre la caméra et le joueur, deviennent transparentes à 70 %, avec une vérification 10 fois par seconde. Effet vu dans Studio : le buisson à côté de Neji dos au mur est transparent. Pas de mesure chiffrée.

Le perchoir sur un tronc d'arbre invisible (y 14,8 à la prise AVANT) n'est pas touché. Rester perché dans un arbre est assez « ninja » ; maintenant que le feuillage s'efface, le corps reste visible. Classement : AMUSANT, à confirmer à l'œil.

### Scène 1 rejouée avec le même script

L'enchaînement n'est plus le même, parce que l'appui ○ passe désormais. Avec sprint et le stick vers l'adversaire, ○ donne la ruée chakra (règle des contrôles : « sprint + ○ toward: chakra dash »). Le corps fonce donc sur le bot au lieu de courir jusqu'au mur, et l'attaque aérienne devient WallDive. Caméra : joueur et adversaire dans le cadre sur 100 % des 1 019 images ; un seul à-coup de 56 ms.

**Point de friction pour la passe D.** Un débutant qui court vers l'adversaire en appuyant sur « esquive » obtient une ruée qui dépense du chakra. C'est voulu par les contrôles, mais cela compte comme une annulation non voulue dans la matrice.

## Matrice PC / manette / tactile (partielle)

| Action | Manette simulée | Clavier | Tactile | Vraie manette |
|---|---|---|---|---|
| Première action (□) | joue | joue (prise AVANT) | non testé | **à faire (toi)** |
| Esquive ○ | joue ; avec sprint vers l'adversaire, devient la ruée chakra | — | non testé | à faire |
| Heavy △ / Heavy chakra L2+△ | joue ; lancer lisible | — | non testé | à faire |
| Verrou R3 / caméra libre | les deux mesurés (mur, lancer) | — | non testé | à faire |
| Air (× puis □) | joue (WallDive près de l'adversaire) | — | non testé | à faire |
| Mur | lisible en verrouillé et en libre manette ; course murale non rejouée cette fois | — | non testé | à faire |
| Réaction au coup | HitStun ; « HIT • Q TO ESCAPE » si l'échappée est ouverte | — | non testé | à faire |
| Refus | toujours expliqué (ligne discrète) | — | non testé | à faire |
| Latence | 350 ± 80 ms : appuis joués | — | — | — |
| Duel à 2 clients | **non fait** | | | |
| FPS | 60 i/s, 0 à 1 à-coup par scène | | | |

**Non fait :** l'émulation tactile, le duel à deux clients, la simulation réseau du moteur (le réglage réseau de Studio demande une permission « Network » que le bac à sable refuse), et le niveau d'IA « normal » (non réglable depuis l'outil).

## Équilibrage

Aucune valeur de combat n'a changé : ni dégâts, ni portée, ni hauteur de lancer, ni durée de vol. Il n'y a donc pas de test de riposte à fournir pour un changement d'équilibre.

## Outils intégrés (règle du 05/11)

- **AnalyticsService** : intégré pour les appuis (voir plus haut).
- **Input Action System** : pas encore. Les correctifs de cette tranche ne touchent pas aux liaisons de touches. Le repère discret s'appuie sur les étiquettes existantes, déjà localisées AZERTY et manette. La migration vers des contextes d'actions est le prochain chantier « entrées ».
- **Animation Graphs, ClientCast, Jest Roblox, RoSentry** : non concernés par cette tranche.

## Réponse provisoire à la question finale

Plus près, mais pas tranché. Les deux moments où un débutant perdait son perso ou son adversaire de vue (le mur, la grande technique) sont corrigés dans les mesures, et un bouton ne reste plus jamais muet. Ce qui reste ne se mesure pas avec des journaux : l'envie de rejouer, le rythme du lancer de 2,4 s, l'axe du stick qui tourne au mur. Cela se juge à la vraie manette.

## Pour toi (test court, environ 5 minutes, manette)

1. Neji contre l'IA facile : courir jusqu'au mur, se retourner dos au mur, puis 2 □ et L2+△ (le grand lancer).
2. Minato : R1+□ (kunai), R1+○ (téléportation), □□□, puis encore R1+○ (tu dois voir « RECHARGING » en petit).
3. Ton avis en une phrase : est-ce qu'on voit tout, et est-ce qu'on a envie d'y retourner ?

Données brutes : `logs/APRES_journaux.md`.
