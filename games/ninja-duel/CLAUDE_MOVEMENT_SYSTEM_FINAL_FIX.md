# Dernière priorité critique avant ce soir : refaire la logique globale des mouvements pour qu’elle paraisse humaine, fluide, technique et cohérente

Le problème actuel n’est pas seulement quelques animations imparfaites. C’est tout le comportement du corps qui manque de logique : déplacement, orientation, jambes, appuis, bras, coups, rotations, caméra, transitions et manière dont le personnage garde sa cible.

Je veux que tu traites ça comme un **problème systémique**, pas comme une série de petits bugs.

---

## 1. Déplacement humain + lock-on

Quand un personnage garde un adversaire en focus, ça ne veut pas dire qu’il doit rester constamment le torse parfaitement face à lui avec des pas latéraux artificiels.

Exemple actuel à corriger :
le joueur veut partir franchement vers la gauche → le personnage fait des pas chassés / croisés bizarres tout en regardant l’adversaire.

Ce que je veux :
- si le joueur se déplace légèrement autour de l’ennemi → strafe naturel ;
- s’il veut vraiment partir dans une direction → le corps **court réellement dans cette direction** ;
- la tête, le torse ou le regard peuvent continuer à suivre partiellement la cible ;
- le personnage peut pivoter progressivement ;
- il peut courir de trois-quarts, tourner les épaules, repositionner les pieds ;
- il ne doit jamais donner l’impression d’un mannequin qui “slide” autour d’un point.

Il faut distinguer :
- déplacement frontal ;
- recul ;
- strafe ;
- course latérale ;
- course diagonale ;
- changement brusque de direction ;
- sprint ;
- poursuite ;
- déplacement autour d’un adversaire ;
- repositionnement après attaque.

Chaque cas doit avoir une logique corporelle crédible.

---

## 2. Les jambes doivent conduire le déplacement

Aujourd’hui, on sent trop que le root se déplace et que les jambes essaient ensuite de suivre.

Je veux l’inverse visuellement :
**les appuis doivent expliquer le mouvement du personnage.**

Donc :
- longueur des pas cohérente avec la vitesse ;
- cadence adaptée à la vitesse ;
- pied planté quand il doit l’être ;
- pas de glissement visible ;
- poussée sur la jambe correcte ;
- hanches qui participent ;
- centre de gravité qui change ;
- vraie impulsion avant un dash ;
- vraie réception après un saut ;
- transitions course → arrêt → attaque naturelles.

Un personnage qui change de direction doit avoir une petite réaction corporelle crédible, pas juste changer instantanément de vecteur.

---

## 3. Les attaques doivent avoir une vraie biomécanique

Les coups de poing et de pied ne doivent pas être juste “le bras ou la jambe bouge”.

Chaque attaque doit utiliser :
- appui au sol ;
- rotation du bassin ;
- rotation du torse ;
- épaule ;
- bras ou jambe ;
- transfert de poids ;
- suivi après l’impact ;
- récupération.

Exemple : un gros crochet doit partir des pieds et des hanches, pas uniquement de l’épaule.

Même chose pour :
- jab ;
- cross ;
- crochet ;
- coup de coude ;
- genou ;
- low kick ;
- high kick ;
- side kick ;
- sweep ;
- spinning kick ;
- 360 kick ;
- projection ;
- attaque aérienne ;
- attaque murale.

Je veux voir clairement **des gestes différents**, pas une succession de poses vaguement similaires.

---

## 4. Le niveau technique doit différencier les personnages

Tous les personnages ne doivent pas se déplacer ou frapper de la même manière.

La technique martiale devient une vraie caractéristique du personnage.

Exemple :

**Neji**
Très propre, précis, appuis courts, mains ouvertes, rotations, redirections, posture stable.

**Minato**
Ultra fluide, peu de mouvements inutiles, changements d’angle, déplacements explosifs, attaques très propres.

**Itachi**
Plus calme, minimaliste, anticipation, feintes, esquives courtes, précision.

Et plus tard, certains personnages pourront être :
- très puissants mais moins techniques ;
- très rapides ;
- très acrobatiques ;
- très agressifs ;
- très rigides ;
- très défensifs.

Je veux que ça se voie **avant même d’utiliser un jutsu**.

---

## 5. Le taijutsu doit devenir spectaculaire

Naruto repose énormément sur les échanges physiques.

Je veux des séquences où l’on sente que les personnages sont des prodiges :
- échange de 3–5 coups rapides ;
- esquive d’un coup → contre ;
- blocage → riposte ;
- coup de pied retourné ;
- attaque dans le dos ;
- sweep → launcher ;
- projection ;
- rebond sur mur ;
- poursuite aérienne ;
- combo au sol → air → mur → retour au sol ;
- clashes ;
- contres ;
- mouvements acrobatiques.

Il faut qu’on puisse parfois se dire :
**“ce qu’ils viennent de faire était techniquement fou”**

même sans gros VFX.

---

## 6. Les combos doivent être lisibles et vraiment différents

Actuellement, les combos se ressemblent trop.

Je veux plusieurs routes clairement reconnaissables :
- combo rapide ;
- combo lourd ;
- launcher ;
- combo aérien ;
- combo mural ;
- projection ;
- mix-up ;
- finisher ;
- combo utilisant un jutsu ;
- combo utilisant mobilité / teleport / shuriken.

Et chaque personnage doit avoir ses propres routes.

Le joueur doit reconnaître visuellement :
**“ça, c’est une séquence de Minato”**

ou
**“ça, c’est du Neji.”**

---

## 7. Caméra et mouvement doivent être développés ensemble

La caméra ne doit plus essayer de réparer les mouvements après coup.

Elle doit être pensée avec eux.

Elle doit :
- anticiper légèrement la direction du joueur ;
- rester stable pendant la course ;
- accompagner les accélérations ;
- monter avec le combat aérien ;
- suivre proprement un wall-run ;
- gérer les changements de côté ;
- s’éloigner pendant les gros échanges ;
- se rapprocher uniquement quand ça améliore vraiment l’impact ;
- éviter les petits mouvements parasites constants.

Le jeu doit rester lisible même quand les personnages bougent très vite.

---

## 8. Fluidité absolue

Les téléportations visuelles, snaps, personnages qui sautent de position et morceaux de corps qui “rattrapent” le déplacement ne sont plus acceptables.

Identifie leur vraie cause :
- interpolation ;
- snapshots serveur ;
- ownership ;
- root motion ;
- Motor6D ;
- animation blending ;
- caméra ;
- correction réseau ;
- fréquence d’update ;
- autre.

Ne masque pas le problème avec du motion blur ou des FX.

**Corrige la cause.**

À vitesse normale comme lors des mouvements extrêmes, le personnage doit rester continu.

---

## 9. Référence de sensation

Utilise **Naruto Storm 4 uniquement comme référence de fluidité corporelle et de lecture du mouvement** :
- continuité ;
- vitesse ;
- poses ;
- transitions ;
- poursuites ;
- impacts ;
- utilisation caméra.

Je ne demande pas le même niveau de détail ni une copie.

Notre jeu doit rester beaucoup plus libre et permettre davantage de contrôle, de déplacements et d’attaques spéciales.

Mais visuellement, il faut arrêter d’avoir la sensation d’un personnage Roblox déplacé par script.

Il faut commencer à avoir la sensation d’un **combattant ninja qui contrôle son propre corps**.

---

## 10. Méthode obligatoire

Ne commence pas par réécrire encore une architecture complète.

Fais :
**jouer → observer → identifier le problème visuel exact → corriger → rejouer.**

Teste particulièrement :
- déplacements 360° ;
- changements rapides de direction ;
- sprint ;
- lock-on ;
- attaque pendant déplacement ;
- combos ;
- aerial ;
- wall combat ;
- projections ;
- téléportation ;
- caméra pendant toutes ces situations.

Utilise Roblox Studio en continu.

---

## 11. Vérification bugs + fluidité globale obligatoire

Pendant toute la passe, fais un sweep de bugs et de fluidité sur l’ensemble du jeu, pas uniquement sur les nouvelles modifications.

Vérifie au minimum :
- sélection personnage ;
- intro ;
- déplacement libre ;
- lock-on ;
- course / sprint / strafe / diagonales ;
- changement de direction ;
- dash ;
- saut / landing ;
- taijutsu ;
- combos sol ;
- combos air ;
- projections ;
- wall-run / wall splat / bounce / tech ;
- jutsu ;
- substitution ;
- téléportation ;
- hit reactions ;
- knockdown / wake-up ;
- caméra ;
- KO ;
- résultat ;
- rematch ;
- changement de personnage.

Aucun freeze, state bloqué, snap, correction brutale, jitter visuel, caméra cassée ou pièce du corps qui décroche ne doit rester s’il peut être reproduit.

Si un bug est trouvé pendant un test, corrige-le avant de continuer.

---

## Critère de réussite

À la fin de cette passe, je veux pouvoir déplacer un personnage pendant **30 secondes sans combattre** et déjà trouver ses mouvements agréables et crédibles.

Puis je veux pouvoir lancer un combat et comprendre clairement :
- quel coup vient d’être lancé ;
- quel personnage est plus technique ;
- comment le corps produit le mouvement ;
- pourquoi l’impact paraît puissant ;
- quelle route de combo est utilisée.

Si le jeu est seulement spectaculaire grâce aux VFX, la mission n’est pas réussie.

**Le corps doit être spectaculaire.**

Traite cette passe comme la correction définitive du mouvement global avant que nous continuions à ajouter du contenu.
