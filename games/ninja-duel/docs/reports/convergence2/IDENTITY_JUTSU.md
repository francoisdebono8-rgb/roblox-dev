# Identité CORE4 et qualité des jutsus — convergence 2

Mission : [CORE_COMBAT_CONVERGENCE_2](../../missions/CORE_COMBAT_CONVERGENCE_2.md), phases 4 (identité), 8 (jutsus) et 10 (UI sobre). Branche `claude/nd-ccc2-identity`, base `50b90bc`.

**Rien ici n'est validé dans Studio.** Les règles, l'état et le contrat snapshot/impacts sont prouvés en headless (`tests/Identity.spec.luau`). L'aspect visuel, les poses et le ressenti restent à juger en natif (liste en fin de document).

Chaque différence vise les quatre couches demandées : **règle**, **corps** (mouvement serveur ou demande de pose), **retour** (VFX/son/HUD), **conséquence de combo**.

## Itachi — lecture, tromperie, contrôle

### Diagnostic Mirage/Écho (code de `50b90bc`)

Pourquoi « pas convaincant, ne marche peut-être pas » :

1. **Le lanceur ne voyait jamais son leurre.** `Presentation:illusion` ne dessinait le fantôme que si *le joueur local* était la victime. Itachi voyait des corbeaux, puis rien. Son cue « ECHO ACTIVE » était en plus filtré par le HUD (pas dans la liste des cues décisifs).
2. **La règle ne correspondait pas à l'image.** N'importe quel coup dans le vide pendant 3 s était puni, même loin du leurre ou contre le vrai corps hors de portée. Frapper le leurre n'était pas requis.
3. **Un humain ne frappait jamais le leurre.** Le verrouillage, la caméra et l'auto-visée restaient sur le vrai Itachi. Le leurre était fixe, à 7 studs sur sa droite, et translucide (0,72). Pour l'humain, ce n'était qu'un fantôme sans enjeu. Seule l'IA « tombait » dedans (65 %), en marchant vers un point vide.
4. **Un étiquetage tuait la tromperie.** Le billboard « ◇ ECHO? » marquait le faux chez la victime.
5. **Le lancement figeait le corps.** Le canal durait 0,9 s, interruptible, plus 0,45 s de récupération : une technique lente et facile à couper pour 32 de chakra.
6. **La tromperie de base reposait sur la progression.** L'image rémanente de FeintStep était purement visuelle. Le leurre n'existait qu'avec le nœud FeintEcho, et le leurre sur parade qu'avec MirageReflex.

### Correctif — Genjutsu : Mirage (kit de base)

- **Règle :**
  - Au relâchement, l'**image reste là où Itachi se tenait** et il **recule de 5,5 studs, exactement derrière elle**, sur la ligne de regard de l'adversaire. Le verrouillage et la caméra de la victime passent donc *à travers* l'image. Contre un mur, il glisse de côté (vers le stick).
  - Victime : `illusionKind="image"`, 2,6 s.
  - **Prise :** un coup qui *atteint l'image* (portée du coup + 2, devant soi) sans toucher le corps. L'image se brise, la victime est **étourdie 0,55 s** et Itachi obtient une CounterPalm **avec allonge**, jusqu'à 9 studs : il traverse son image. Un coup dans le vide ailleurs n'est pas puni.
  - **Fin de l'illusion :** à expiration, si quelqu'un est touché (la douleur brise le genjutsu, y compris Itachi), si le corps de la victime entre dans l'image (« dispelled »), ou face au Byakugan (immunité inchangée).
  - **Coût :** 26 chakra, canal 0,42 s, récupération 0,2 s (*Flow*), CD 7 s.
- **Corps :**
  - Le recul est un vrai déplacement serveur, lissé côté client.
  - L'IA Itachi tient la ligne derrière son image tant qu'elle dure (pas de rapprochement ni de strafe). Les lames traversent l'image.
- **Retour :**
  - Victime : l'image *est* Itachi, une copie figée dans sa garde, tournée vers elle, avec un liseré rouge qui pulse brièvement (l'indice lisible). Le vrai corps derrière est dessiné à 55 %.
  - Lanceur : une image rémanente rouge translucide de lui-même.
  - Phases d'impact `mirage` : `cast` (onde rouge sous la victime, lueur des yeux), `catch` (l'image vole en éclats), `touch`/`break` (elle se dissout), `seen` (Byakugan).
  - Le billboard « ECHO? » est supprimé. Les cues passent par « GENJUTSU • … », que le HUD affiche.
- **Combo :** jutsu → l'adversaire vient frapper « Itachi » → prise → CounterPalm qui traverse l'image → Knockback (mur, chase). Les shuriken lancés à travers l'image couvrent l'attente.

### Sharingan Read — « je l'avais vu venir »

- **Règle :**
  - Un coup frontal de mêlée pris dans la posture n'inflige aucun dégât. Itachi **glisse de 2,2 studs sur le côté**, se replace face à l'attaquant, et l'attaquant est **étourdi 0,5 s**.
  - Le counter s'ouvre 1 s avec une petite allonge de 4 studs. Il rend +10 chakra.
  - **Un coup pressé pendant la posture** est mis en tampon et part comme CounterPalm à l'instant de la lecture. Avant, cette pression était refusée (« Committed »).
- **Retour :** impact `read` avec une lueur des yeux (deux points rouges et un trait), une **image rémanente** rouge là où il se tenait, et un éclair blanc « mordu » par le coup. Son sec. Le cue devient « READ • SEEN COMING • PUNISH ».
- **Combo :** posture → coup adverse mordu → CounterPalm de flanc. Une pression anticipée donne le counter instantané, une pression après la lecture donne le counter normal.

### Sharingan Focus (éveil) — contrôle, pas seulement des stats

- **La garde levée lit (`GuardRead`).** Tout coup frontal de mêlée qui la rencontre est paré *et lu* : glissade, image rémanente, counter. Cela marche une fois par levée de garde, avec le cooldown de parade de 0,6 s et le coût en stamina. Relever la garde pour relire.
- **Les coups ratés près de lui sont lus (`WhiffRead`, 9 studs) :** counter 0,9 s, +0,22 s de récupération pour l'adversaire, impact `read` en phase `whiff`.
- Les yeux restent allumés pendant tout l'éveil.
- Bonus de dégâts ×1,12 retiré. Restent CostScale 0,6, CD ×0,6, vitesse ×1,06 et fenêtres ×1,5 pour l'esquive parfaite.

## Minato — angles, marques, relocalisation

### Wind Cut : décision — refondu (même slot, même Id)

Avant : un projectile de vent statique (canal 0,32 s, ralenti à 7 studs/s, récupération 0,34 s). Il poussait la cible sans aucune suite : du remplissage élémentaire.

Après : **un outil de Minato.**

- **Règle :**
  - **Lancé en courant** (`Mobile`, overlay de lancer de kunai, relâchement 0,16 s) : les jambes ne s'arrêtent pas.
  - Croissant rapide et large : vitesse 104, portée 40, rayon 1,6.
  - **Il coupe les lames ennemies dans son couloir** : kunai, shuriken, kunai marqué, fil. Impacts `deflect`. C'est la réponse de Minato au zonage.
  - **Un corps touché est rejeté d'un pas sur le côté** (côté du stick) et porte un **sceau de vent de 1,6 s** (un sceau plus long déjà posé, comme celui d'un kunai marqué, est conservé). Le FTG suivant atterrit à côté de ce corps, côté choisi au stick.
  - Garde : rien, pas de sceau.
  - Coût 14, CD 3,2 s. Le nœud Gale Chase (fenêtre de chase) reste compatible.
- **Retour :** croissant pâle au point de coupe et sceau corporel aux couleurs du vent (vert pâle, distinct du sceau jaune). Cue « WIND CUT • SEALED… ».
- **Combo :** course → Wind Cut qui coupe les shuriken d'Itachi → touche → FTG à côté → frappe d'arrivée ou Rasengan.

Ce qui le distingue du Marked Kunai : ce dernier est lent (82), long (66) et sert de *préparation* (sceau de 5 s sur le corps, 12 s planté). Wind Cut sert la *conversion immédiate* : rapide, large, sceau court, nettoie le couloir.

### Yellow Flash (éveil) — la relocalisation enchaîne

- **Sillage (`FlashWake`)** : chaque FTG plante un sceau au sol là où il était. Il revient donc toujours au point de départ (A → B → A), dans la limite de 2 sceaux plantés.
- **Poursuite éclair (`FlashPursuit`)** : un corps qu'il vient de lancer, d'envoyer au loin ou de plaquer au mur (fenêtre de chase ouverte) **est une destination sans sceau**. Le FTG le rejoint dans les airs et consomme la fenêtre de chase. C'est sa ré-entrée propre, distincte du dash commun.
- **L'arrivée reste ouverte 0,8 s** au lieu de 0,55 s.
- Retour : anneau d'arrivée doré plus large, éclair au départ (le sceau laissé).
- Bonus de dégâts ×1,05 retiré. Restent vitesse ×1,18, CD ×0,4 et regen ×1,5.
- Le nœud *Flow* (YellowFlow, un coup après l'arrivée rescelle le corps) reste un ajout distinct.

### FTG et sceaux

Le FTG (`Flow`) et le Quickstep (`Flow`) cèdent la seconde moitié de leur récupération à une garde ou une esquive. Les sceaux de vent ont leur couleur.

## Neji — précision, tenketsu, contrôle du chakra

### Tenketsu visibles

- **Serveur :**
  - Chaque point fermé est un **lieu du corps** : gorge, cœur, plexus, nombril, épaules, hanches. L'ordre dépend de la zone frappée (`Brawler.TENKETSU_ORDER`).
  - Les points sont suivis par victime (`tenketsuPoints`) et exposés dans le snapshot (`tenketsuPoints`, `tenketsuSevere`).
  - Chaque fermeture pousse un impact `tenketsu` (point, compte, sévère).
- **Client :**
  - Éclair ponctuel sur le point exact, courte pulsation de chakra et « tic » sec.
  - Le point reste allumé sur le corps tant qu'il est fermé.
  - À **quatre points (réseau scellé)** : pulsation rapide, fuite de chakra visible, HUD « • SEALED », cue victime « CHAKRA NETWORK SEALED ».
  - Les paumes de Neji ont désormais le retour *paume* (son, flash, caméra) au lieu de celui d'un coup de poing générique.
- **Règle :** les points fermés **compromettent la garde**.
  - La fenêtre de parade rétrécit de 25 % par point (plus de parade à quatre, Sharingan compris).
  - Un coup bloqué coûte +20 % de stamina par point.
  - La régénération de chakra reste coupée (−15 % par point).

### 64 Palms — l'apogée du réseau

- **Règle :**
  - Chaque point déjà fermé ajoute une paume : 7 + points, jusqu'à 11.
  - L'intervalle accélère : 0,15 − 0,012 × points.
  - La dernière paume s'alourdit : ×(2,5 + 0,25 × points).
  - Le scellement s'allonge : 3,5 s (+ nœud), plus 0,4 s par point.
  - **À quatre points, la garde s'effondre** sous la paume d'ouverture (« GUARD BREAK • THE NETWORK IS CLOSED »).
- **La substitution reste l'issue.**
- **Combo :** paume → paume → CircleStep → Sweep (2 points) → 64 Palms à 4 points. Le trigramme reçoit le nombre de points.

### Rotation → counter fluide

Avant : l'attaquant repoussé volait d'environ 23 studs (Knockback 48, 18 vers le haut). Le dôme gardait ses 0,55 s puis 0,24 s de récupération, si bien que la fenêtre de counter de 0,9 s expirait pendant la rotation, hors de portée.

Après :

- Un coup détourné fait **chanceler** l'attaquant hors du dôme (HitStun 0,6 s, environ 2,5 studs), à portée. Un corps qui se tenait seulement dans le dôme est toujours projeté.
- Le dôme **s'arrête 0,08 s après la répulsion**, puis 0,04 s de récupération, et son invulnérabilité est rognée d'autant.
- Une paume pressée pendant la rotation, ou pendant ce repli, **sort directement** en PalmThrust avec allonge (7 studs, variante `TrigramCounter`).

### Byakugan Full Field (éveil)

- **Une paume propre ferme deux points.** On voit deux éclairs, et l'accumulation mène à l'apogée des 64 Palms.
- **Une paume qui brise un jutsu en cours de canalisation scelle les techniques 1,5 s** (« BYAKUGAN • CHAKRA FLOW CUT »).
- Plus d'angle mort (inchangé). Les veines restent visibles et un anneau de champ s'affiche au sol pendant l'éveil.

## Sasuke — Curse Mark : le flux change

- **Prolongations :**
  - Le troisième coup de pied et l'AirDrive **ne lâchent pas** : au lieu d'envoyer au loin, ils font chanceler (HitStun au sol, Juggled en l'air) et **la chaîne reste ouverte**. C'est une fois par échange (2,5 s), donc pas de boucle.
  - Heavy derrière donne le lanceur, et sous la marque **tout lanceur devient la Danse de la feuille** : chase gratuite collée sous le corps, puis Heavy pour le Lion Combo.
- **Risque :**
  - Le drain double (2,8 PV/s) quand il ne touche plus depuis 1,5 s (« faim », les marques clignotent) et s'arrête 0,6 s après chaque coup porté.
  - Il ne tue jamais.
  - **Le corps maudit encaisse +12 %.**
- Dégâts ×1,18 ramenés à ×1,12. La transformation visible est conservée, avec un éclat violet sur la prolongation.
- Fil, feu et foudre n'ont pas été touchés (agent chakra).

## Fluidité des jutsus (audit, niveau machine d'états)

| Jutsu | Canal / actif / récup. (s) | Avant | Après |
|---|---|---|---|
| Wind Cut | 0,16 (lancer) | figé 0,32 + 0,34, ralenti à 7 studs/s | **lancé en courant** (état Neutral) |
| Mirage | 0,42 / 0,06 / 0,2 | 0,9 / 0,08 / 0,45 | plus court, récupération *Flow* |
| FTG | 0,06 / 0,04 / 0,2 | frappe seulement | + garde/esquive après 50 % de la récup. (*Flow*) |
| Quickstep | 0,11 / 0,08 / 0,21 | — | *Flow* |
| Vacuum Palm | 0,18 / 0,06 / 0,26 | — | *Flow* |
| Shadow Shuriken | 0,26 / 0,08 / 0,26 | — | *Flow* |
| Read | 0,1 / 1,0 / 0,2 | coup pendant la posture refusé | coup mis en tampon, posture quittée à la lecture |
| Rotation | 0,04 / 0,55 / 0,24 | counter souvent impossible | dôme écourté à la répulsion, counter direct |
| 64 Palms, Rasengan, Katon, Chidori | inchangés | — | **engagements** : pas de *Flow* (fenêtres de punition intactes) |

- **Lancement hors axe :** au-delà de 35°, le corps **tourne** vers la cible pendant le canal (1440 °/s) au lieu d'un `lookAt` instantané. En dessous de 35°, le recalage reste immédiat (invisible).
- **Hors de mon périmètre :** le plafond de vitesse de 7 studs/s pendant un canal (`Motor.step`, `Config.ChannelSpeed`) coupe net un sprint. C'est la vraie saccade restante des jutsus canalisés. Je recommande une décélération progressive dans `Motor.step` (agent mouvement / lead).

## Base contre progression

Toute la tromperie d'Itachi décrite plus haut est dans le **kit de base**. Les nœuds restent des ajouts distincts, sans doublon :

- FeintEcho : écho sur FeintStep, règle historique, tout coup raté.
- MirageReflex : leurre sur l'attaquant après une parade sous Focus.
- YellowFlow : resceller le corps après l'arrivée.
- GaleChase : chase après Wind Cut.
- FullFieldPoints : points à travers la garde.

Le seul changement dans `SkillTrees.luau` est le texte de Short Signs, devenu faux (0,34 s au lieu de 0,42 s).

Le texte `Hook` de `tech.WindCut.Chase` dans `SkillBuilds.OPTIONAL` cite encore `Elements.wind`. C'est de la documentation hors de mon périmètre. Le lecteur réel est `Techniques.WindCut`.

## Contrat client ajouté

- **Snapshot (`Matches:view`)** : `tenketsuPoints`, `tenketsuSevere`, `illusionKind`, `curseHunger`. Les sceaux portent en plus `wind` et `wake`.
- **Impacts** :
  - `read` (owner, victim, to, phase `read`/`focus`/`whiff`) ;
  - `mirage` (phase `cast`/`catch`/`touch`/`break`/`seen`, ou sans phase pour l'écho historique) ;
  - `tenketsu` (victim, point, count, severe) ;
  - `windseal`, `curse` ;
  - `teleport` reçoit en plus `awake` et `body`.
- **Variantes d'attaque** : `MirageCounter`, `ReadCounter`, `TrigramCounter`.
- **Événements** : `ReadSlip`, `ReadSuccess`, `WhiffRead`, `Mirage`, `Counter`, `WindSeal`, `WindCutBlade`, `FlashWake`, `PointClosed`, `Severed`, `GuardCollapse`, `FlowCut`, `CurseExtension`, `CursedLeaf`.

## Demandes de poses (moteur d'animation, lead)

Je n'ai pas modifié `VelmoraMotionEngine.luau`. Toutes les données nécessaires sont déjà dans le snapshot.

1. **Glissade de Read**, déclenchée par un nouvel impact `read` sur soi (owner = soi). Durée 0,12 s :
   - racine décalée latéralement (le serveur déplace déjà le corps), roulis 6° *opposé* au coup, hanches qui pivotent de 20° vers l'attaquant ;
   - main avant ouverte qui monte (raise 70, elbow 60), tête stable, regard fixé.
   - Puis la CounterPalm habituelle.
2. **Posture Read** (`castId=="Read"`, état TechniqueActive) :
   - menton légèrement baissé (tête pitch −4) ;
   - mains plus basses et ouvertes (ra raise 30 / elbow 80, la raise 45 / elbow 70) ;
   - immobile : respiration réduite de moitié.
3. **Mirage** (`castId=="MirageCast"`) :
   - pendant le canal, signe d'une main à la poitrine et poids qui recule (root z +0,3, pitch −4) ;
   - au relâchement, retrait : root z +0,6, pitch −6 pendant 0,1 s, puis retour à la garde.
4. **Coup « mordu dans le vide »** pour la victime d'une prise Mirage (Stunned juste après un coup sans contact, cue GENJUTSU • EXPOSED) :
   - buste pitch +14, bras du coup tendu en avant ;
   - tête qui se tourne de 30° vers le vrai Itachi, 0,55 s.
5. **CounterPalm `MirageCounter` et `ReadCounter`** :
   - glissade basse pendant le startup (root y −0,7, z −1,2) ;
   - paume avant tendue (raise 95, elbow 5).
6. **PalmThrust `TrigramCounter`** :
   - démarre dans le lacet de la rotation (root yaw +90 par rapport à l'adversaire) et se déroule à 0 pendant le startup (0,11 s) ;
   - doubles paumes en avant.
7. **Victime de tenketsu** (tout combattant ; `tenketsu` 0–4, `tenketsuSevere`) :
   - 1–2 points : colonne pitch +3°, mains de garde −8° ;
   - 3 points : +6°, main avant qui tombe (raise −15) ;
   - 4 points (sévère) : +10°, genoux fléchis (root y −0,15), respiration ×1,6, bras lourds (raise −20), légère secousse de tête (yaw ±4° à 7 Hz).
8. **Wind Cut** (lancer `Kunai`, `castId=="WindCut"` pendant le lancer) : remplacer l'overlay de lancer par un **revers horizontal** du kunai. Le bras droit balaie de out +60 à −40 en 0,12 s autour du relâchement, buste yaw −30 à +10.
9. **Curse Mark** (Lion, `awaken>0`) : garde plus voûtée et agressive (root pitch +6, y −0,1, tempo ×1,2). Quand `curseHunger`, épaules qui tressaillent (torso roll ±3° à 9 Hz).
10. **Arrivée Yellow Flash dans les airs sur un corps lancé** (`teleport.body`) : prêt pour Air1 (pose d'arrivée aérienne, kunai levé), pas la pose d'arrivée au sol.

## Tests

- **`tests/Identity.spec.luau` : 26 tests, dans `tests/run.sh` et dans la porte de `build.py`.**
  - 25 d'entre eux échouent sur `50b90bc` (vérifié en lançant la spec sur l'archive de la base) : 21 tests de règles, le test IA (Itachi tient la ligne) et 3 tests client, dont les fonctions n'existent pas sur la base.
  - Le 26e (Wind Cut ne raccourcit pas un sceau plus long déjà posé) protège un invariant du nouveau comportement : il passe aussi sur la base.
- **`tests/Neji.spec.luau`** : le test Rotation suit le nouveau contrat (chancellement HitStun au lieu de Knockback).
- **Résultat** : 19 suites PASS, 3 builds, isolation, docs, architecture.
- **Headless seulement** : règles, timings, géométrie (image en ligne, glissade, allonge), contrat snapshot et impacts. Les fonctions client tournent sur des bouchons (aucun rendu).

## À valider dans Studio

1. **Mirage, vu par la victime humaine** : le liseré et le corps à 55 % rendent-ils l'image lisible sans la trahir ?
   - Le joueur va-t-il réellement frapper l'image ?
   - La caméra reste sur le vrai corps (`Camera.luau`, hors périmètre) : est-ce un indice trop fort ?
2. **Mirage, vu par Itachi** : l'image rouge est-elle lisible et pas bruyante ? Le retrait de 5,5 studs, lissé, se lit-il comme un retrait, pas comme une téléportation ?
3. **Read** : la glissade de 2,2 studs, la lueur des yeux et l'image mordue font-elles comprendre « je l'avais vu venir » ? Le counter instantané est-il agréable ?
4. **Tenketsu** : les points tombent-ils au bon endroit sur le corps R15 ? Les pulsations et la fuite sont-elles sobres ?
5. **Wind Cut** : le croissant en course, la coupe des lames et le FTG à côté, au rythme réel.
6. **Yellow Flash** : la poursuite éclair sur un corps lancé (arrivée aérienne), le sillage de sceaux et la lisibilité des 2 sceaux.
7. **Rotation → PalmThrust** (sans pose dédiée pour l'instant).
8. **Prolongation maudite et Danse de la feuille sur tout lanceur** ; le clignotement de la faim.
9. **Rotation du corps au lancement hors axe** (1440 °/s) : naturelle ?

## Risques et points ouverts

- **Itachi Focus** : une garde lit tout coup frontal une fois par levée. C'est fort pendant 12 s ; à surveiller en équilibrage. Contre : la saisie, les projectiles, le flanc, les feintes, ou attendre l'usure de la stamina.
- **Prolongation maudite** : elle manipule `p.spec.chain` sur le coup en cours. Si l'agent combo change la sémantique de `chainOpen` ou de `combo`, il faudra garder ce cas : « après un Light3 maudit, la chaîne reste ouverte, Heavy = lanceur ».
- **Fichiers partagés** : `Brawler.request` reçoit deux lignes (tampon de posture, counter de rotation), `Brawler.hit` deux appels (hooks d'éveil) et `Combat.updateActor` des remplacements d'une ligne. Des conflits de fusion sont possibles avec les agents combo et mouvement, mais simples à résoudre.
- **Coupe des lames de Wind Cut** : elle est implémentée dans `Techniques` (scan programmé). Si l'agent chakra ajoute une collision générale des projectiles, les deux peuvent se recouvrir sans casser. Il faudra unifier.
- **Bug préexistant hors périmètre** : `tests/Balance.sim.luau` plante sur `50b90bc` (`Combat:updateHazards`, entrée `nil` après `c:clear()` en cours de boucle). C'est un artefact du faux `finish` du harness. Ma branche finit la simulation, mais le bug reste.
