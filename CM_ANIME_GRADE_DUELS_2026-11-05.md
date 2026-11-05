# NINJA DUEL — Trois combats filmés comme des scènes d'anime (et une capsule fun)
**Direction créative complémentaire — 05/11/2026.** Branche CM `media-clips`. Concepts à préparer et à tester, **pas autorisation de publier**. Destiné à compléter `CM_THREE_SERIES_PRODUCTION_BIBLE_2026-11-05.md` et `CM_STUDIO_SHOT_GATE_FINAL.md`, pas à relancer les films Minato–Neji et Itachi–Kakashi déjà produits. Gameplay de référence : HEAD réel de `claude/ninja-duel-2026-10-14` (observé à `f112cc6`, 05/11). **Les mouvements ci-dessous sont tirés des capacités codées, mais leurs combinaisons/timings et leur rendu ne sont PAS validés sans essais Studio.**

## Ce que « combat digne d'un anime » veut dire
Une scène **causale** : chaque action force la suivante. Pas un diaporama « 4 compétences cool », pas des personnages plantés dans le décor ni du texte qui explique ce que la caméra aurait dû montrer. Les étapes : (1) attaque, (2) évitement avec le corps entier, (3) contre rapproché, (4) renversement avec l'environnement ou un pouvoir, (5) chute/retour au neutral. Jeu 1v1 visible et contrôlé, pas fausse cinématique. Sur 9:16, la direction du corps, la proximité, la verticalité et la conséquence de chaque coup doivent lire **sans le son ni les sous-titres**.

**Montage** : un film premium de 15–18 s ou short de 12–14 s ; 5–8 plans, **2–3 s de vraie action continue à l'intérieur d'au moins un plan**, éventuellement un plan-séquence de 3–4 s. Ne pas couper à chaque demi-seconde par habitude. Démarrer sur une ACTION et non un logo. Couper au changement de stratégie, au contact, à la révélation, à la reprise. Au maximum 2 courts textes d'accroche/payoff ; logo final 0.4–0.7 s sur l'image d'action, pas 2 s de fondu noir. Sons originaux/licenciés (métal, sprint, respiration, souffle, chute) synchronisés aux impacts du jeu. **Pas d'OST ni de séquences d'anime protégées**.

**Dispositif de prises** : enregistrer d'abord le duel entier HUD ON et un enregistrement côté serveur montrant que chaque contact et capacité sont réels ; ensuite refaire **les mêmes portions cohérentes** sous caméra de gameplay (à privilégier), latérale basse, trois-quarts (pas de travellings qui cassent la perspective). La caméra film n'est pas la caméra qu'un utilisateur aura en jeu : conserver des prises avec la caméra jouable. Une prise où les combattants ne sont pas dans le crop 9:16 est à refaire dès le premier essai. Repérer l'orientation géographique : gauche → droite = attaque, conserver l'axe, ne jamais inverser qui est à droite entre deux coupes non motivées. Aucun faux hit, clone fictif, faux blocage, ou action simulée seulement au montage.

## VIDÉO 01 — « HE RAN INTO THE WRONG ITACHI » (Lee vs Itachi)
**Priorité A : chorégraphie pure.** Duel vitesse corporelle vs lecture/illusion. `Leaf`: sprint/RemoveWeights, DynamicEntry, LeafRising/GreatWhirlwind, suite aérienne et recovery. `Mirage`: shuriken, esquive et `MirageCast` / `Read` (avec vraie contre-attaque conditionnelle).

**Durée cible : 16–18 s.** Arc dramatique : Lee croit pouvoir gagner en accélérant ; Itachi le laisse s'engager dans un piège ; la vitesse garde une chance.

| Montage final | ACTION EXACTE à capturer (pas juste poser les persos) | Caméra / rythme / son |
|---|---|---|
| 0.00–1.25 | Lee **déjà lancé** traverse le cadre vers Itachi, glisse un appui, change d'angle et démarre un premier coup rapide. Ne jamais introduire les combattants avec un plan fixe. | 3/4 arrière de Lee, axe de mouvement clair, bruit de course court. |
| 1.25–3.40 | Itachi lance **ses véritables shuriken** sur la trajectoire ; Lee esquive **en diagonale** (pas en se téléportant), retombe près de lui et tente immédiatement une frappe. | Plan latéral taille entière : les deux corps ET les projectiles visibles ; trajectoire lisible ; 2 s de mouvement quasi continu. |
| 3.40–5.60 | Échange au corps-à-corps : Lee touche ou est gardé sur deux coups (réponse à tester), pivote et tente un grand coup de pied tournant/Leaf Great Whirlwind. Itachi recule d'un pas, sans être immobile comme un mannequin. | Plan serré mais les pieds doivent rester dans le cadre ; coup de pied dessiné en entier, 1 impact sonore net seulement si hit. |
| 5.60–8.50 | Itachi active **MirageCast** au moment où Lee s'engage. Film : Lee fonce vers le **leurre réellement créé** ; l'attaque doit rater le corps réel et interagir avec le mirage *si le moteur permet cette rencontre précise*. | Maintenir la géographie : on doit comprendre où était Itachi et où apparaît son image. Baisser brièvement la musique, laisser le son creux du faux coup. |
| 8.50–11.20 | Révélation dans **le même axe** : vrai Itachi sur le flanc / derrière le leurre. Lee tente de se réorienter ; si le `whiffRead` déclenche effectivement le contre, Itachi enchaîne son **CounterPalm** avec un contact enregistré. | Plan légèrement plus large révélant les 3 positions, puis gros impact. Pas de « clone remplacé » si l'illusion est invisible. |
| 11.20–14.70 | Lee **répond**, ne devient pas un sac de frappe : récupère/roule/saute, essaie Dynamic Entry depuis un nouvel angle ou se relève en garde (selon vrai état après le contre). Itachi fait une sortie de garde ou esquive. | 2–3 s de gameplay continu ; on voit que les deux ont encore du contrôle. Un atterrissage franc. |
| 14.70–17.50 | Clôture sur l'instant où les deux repartent l'un vers l'autre : Lee bondit, Itachi se prépare à lire, **cut à l'attaque**, jamais un logo qui gèle l'énergie. Superposer discrètement « SPEED VS PREDICTION » puis `NINJA DUEL` pendant les dernières ~0.6 s. | Plan large court + cut net sur action. |

**Point Studio impératif** : `MirageCast` ne garantit pas qu'une frappe arbitraire déclenche exactement le contre attendu ; tester depuis un duel réel, observer `whiffRead` et `CounterPalm`. Si non reproductible : substituer `Read` + garde/parade réelle contre la frappe de Lee, et titrer « HE READ THE KICK », pas « HE HIT A CLONE ». Ne pas falsifier un hit pour sauver le storyboard. Si une feinte casse la continuité, refaire la combinaison.

## VIDÉO 02 — « CHIDORI FROM ABOVE » (Sasuke vs Neji)
**Priorité A : verticalité, caméra, choix défensif.** `Lion` Sasuke dispose de shuriken, pression de pieds, Chidori **tenu en main** puis `ChidoriDive` depuis l'air ou le mur (build récente). `GentleFist` Neji : pas circulaires, paumes sur points, `Rotation` (protection), riposte `rotationCounter`, `VacuumPalm`; expérimentation de Heavy chakra avec énorme projection, **non garantie**.

**Durée cible : 15–18 s.** Arc : Sasuke attire Neji à regarder au sol et finit au-dessus de lui ; Neji transforme la descente en une contre-attaque.

| Temps | Action | Réalisation |
|---|---|---|
| 0.00–1.25 | Sasuke arrive par le côté et lance un **vrai shuriken**. Neji le détourne avec sa garde/sa défense réelle ou esquive latéralement. | Hook en pleine action, couteau visible, caméra basse 3/4. |
| 1.25–3.70 | Sasuke entre avec **light → light → heavy / coup de pied** ; Neji esquive le dernier coup ou garde, puis rentre à portée de paume. Les animations des jambes sont prioritaires. | Un plan de 2.5 s sans découper chaque coup ; voir le sol et la tête. |
| 3.70–5.70 | Neji touche avec sa paume et ferme réellement un point (si contact prouvé) ; Sasuke recule volontairement vers le mur / se repositionne, sans coupure spatiale. | Contact net, réaction brève, pas de gros titre « CHAKRA SEALED ». |
| 5.70–8.80 | Sasuke **prend de la hauteur** (saut/mur), Chidori **en main** (le personnage conserve le pouvoir en bougeant), et se jette vers Neji en **vrai ChidoriDive** depuis ce point haut. | Plan large vertical révélant hauteur et cible, puis 3/4 au début de plongée, main bleue et silhouette visibles ; ne pas coller la caméra à l'effet. |
| 8.80–11.80 | Neji déclenche `Rotation` **avant le contact**. Montrer le résultat réel : Chidori arrêté/dévié ou Neji protégé, **si validé dans le moteur**. Sasuke termine son trajet et récupère, pas téléporté arbitrairement. | Le spectateur doit voir deux corps, la rotation et la conséquence : minimum ~1.5 s de cadre lisible. |
| 11.80–14.80 | Neji enchaîne son **contre réel après Rotation**, ou une `VacuumPalm` qui éloigne Sasuke ; Sasuke réceptionne/roule/récupère. | Un vrai impact et une vraie chute, pas 4 shakes. |
| 14.80–17.00 | Sasuke se relève ; Neji avance les mains ouvertes ; les deux reprennent le neutral. Texte « HE SAW THE DIVE » ou « AIR VS BYAKUGAN », micro-marque NINJA DUEL. | Fin sur anticipation du prochain échange. |

**Passage viral alternatif, à tester séparément** : Heavy infusé de chakra de Neji → projection anormalement haute → caméra révèle toute la trajectoire → Neji resté au sol. Si le résultat est reproduit **sans éjection de map / KO cassé**, en faire un **clip de 8–10 s** avec le vrai son + une phrase « WHERE DID HE GO? ». Ne pas greffer cette projection à un duel où elle n'a pas été obtenue. La conserver comme découverte amusante, ne pas la « corriger » pour la communication.

**Fallback** : si Rotation ne stoppe pas ChidoriDive dans la vraie fenêtre, faire une **esquive franche** de Neji puis `VacuumPalm` en punition du dive raté ; dans ce cas le titre devient « THE DIVE WAS A MISTAKE ». Ne jamais présenter une Rotation qui n'a pas véritablement défendu.

## VIDÉO 03 — « HIS SHIELD DOESN'T SEE BEHIND » (Kakashi vs Gaara)
**Priorité B : tactique avec le terrain.** `Copycat` Kakashi : kunai / tanto, déplacement, `WaterDragon`, `LightningCut` (avec arme dégainée, repositionnement derrière), `TrackingFang`; `Sand` Gaara : bouclier auto orienté, balayages, `SandCoffin`, `DesertWave`. Le `SandShield` a un cône de couverture, mais un back-hit réel doit être prouvé en capture.

**Durée cible : 14–17 s.** Arc : Gaara domine de face, Kakashi comprend l'angle ; pas « le plus gros jutsu gagne ».

| Temps | Action | Caméra |
|---|---|---|
| 0.00–1.60 | Kakashi s'engage au kunai ; le sable **arrête réellement** son attaque frontale. Son corps recule sous la réponse. | Un plan bas 3/4, impact SABLE + métal si vrai blocage. |
| 1.60–4.10 | Gaara envoie deux attaques à distance (lash / Sand Shuriken si condition), Kakashi court **de côté puis saute**, pas d'écran rempli de particules. | Plan latéral entier, trajectoires visibles. |
| 4.10–6.80 | Gaara pose une `SandCoffin` dans sa voie ; Kakashi évite par un bond/angle, retombe près d'un obstacle. L'attaque doit être réellement évitée, pas un personnage qui ignore la hitbox. | Un plan de 2.5 s où l'espace fait sens, évitement complet. |
| 6.80–9.10 | Kakashi **dégainer réellement** son tantō (condition de `LightningCut`), se replace en un éclair à l'arrière de Gaara. Éviter fausse caméra 360 qui masque le trajet. | Avant = bouclier devant ; après = Kakashi clairement derrière, même axe. |
| 9.10–11.60 | Kakashi frappe depuis l'arrière ; si le moteur enregistre le hit par la zone non couverte du bouclier, **montrer le contact**, la réaction et l'effet électrique. | Tenir le plan de contact ~1 s, pas cut sur un flash qui dissimule la hitbox. |
| 11.60–14.20 | Gaara répond avec `DesertWave` / défend avec du sable ; Kakashi s'échappe ou encaisse. **Les deux combattants agissent dans le dernier tiers.** | Retour au cadre lisible, réaction physique. |
| 14.20–16.20 | Fin avant décision : poussière qui descend, deux silhouettes face à face. « THE SHIELD HAD AN ANGLE » et NINJA DUEL sur image réelle. | Pas de fondu de 2 s / corps figés. |

**Point Studio** : `LightningCut` exige l'arme dégainée ; contrôler le vrai `SandShield.Cover` dans le duel. Si le back-hit est absorbé quand même, ne pas inventer la faiblesse : remplacer le twist par **attaque contre angle de retraite** ou **Water Dragon vs sable**, et retitrer. `WaterDragon` peut aussi être une vidéo autonome de conflit élémentaire ; ne pas forcer en plus dans ce film.

## Capsule D — « I SENT HIM TO THE MOON » (Neji Heavy chakra, 8–10 s)
**But différent** : prouver que le jeu est vivant, imprévu et drôle.
- 0.0–1.3 : Neji et adversaire au corps à corps ; angle latéral montrant leurs pieds.
- 1.3–3.0 : **vrai Heavy infusé** (entrée et contact à l'image), sans ajouter une animation inventée.
- 3.0–6.5 : plan assez large / cadrage vertical qui **montre la hauteur entière** et le retour du corps si possible ; réaction drôle uniquement si visible.
- 6.5–8.8 : Neji encore au sol, regard vers le ciel, très bref « BRO WHERE DID HE GO 💀 », retour aux commandes du duel.
- Si le bug détruit la partie ou n'est pas reproductible : ne pas publier comme une mécanique promise, et le signaler au dev. Pas de ralentissement pour feindre une hauteur qui n'existe pas.

## Procédure réaliste pour ne pas refaire 3 heures de montage inutile
1. **Test de faisabilité 10–15 min max par concept avant montage**, sur le SHA exact : aligner les deux personnages et essayer le point culminant FIRST (Mirage → punition ; ChidoriDive → Rotation ; LightningCut → dos du bouclier ; projection Neji). Si raté, choisir le fallback sans mentir.
2. Capturer un **rough entier avec la caméra jouable**, même brut et imparfait. S'il n'y a pas un combat intéressant de 4–5 secondes **sans coupe**, le montage ne sauvera pas le film : refaire les entrées et les placements.
3. Ensuite seulement prises latérales complémentaires et montage ; garder un rush HUD ON continu. Ne pas monter 3 scènes simultanément : tester le meilleur climax d'abord.
4. Vérifier images clés : joueurs toujours visibles, mouvements des bras/jambes clairs, vrais impacts/réactions, points de départ et d'arrivée cohérents, aucune caméra dans un personnage, aucun freeze/FX collé, vraie animation de réception. `video_qc.py` détecte des anomalies techniques de frames mais ne juge pas la qualité du combat.
5. Exporter une version **sans texte**, la regarder sur téléphone, puis au plus 2 textes. Préparer deux hooks si besoin. **Le clip doit susciter « comment il a fait ? je veux jouer » en montrant précisément comment c'est arrivé.**
6. Avant toute publication, contrôler LIVE vs TEST, licence/sons, et recueillir l'accord de l'utilisateur.

## Ordre proposé
**1. Lee vs Itachi** pour prouver qu'un combat peut être bon *grâce au corps et à l'intelligence*, pas à quatre pouvoirs. **2. Sasuke vs Neji** pour vendre l'air, les murs et le chakra. **3. Kakashi vs Gaara** pour le combat tactique et le terrain. **Capsule Neji** en parallèle uniquement si la projection est prouvée en jeu. Si les rushes Studio donnent un autre meilleur vrai échange, privilégier celui-là plutôt que de forcer le script.
