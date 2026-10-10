# FOUNDATION — matrice humaine manette, 20 scénarios

Contrat proposé le 10 octobre 2026. **Tous les résultats : NON TESTÉS sur le nouveau socle.** Une recherche, un log headless ou une démonstration scriptée ne constitue pas un PASS humain. Les scénarios 14–17 relèvent de la slice avec techniques, pas d'une obligation d'implémenter ces kits dans FOUNDATION 02.

## Protocole commun

Deux R15 aux proportions finales, même noyau physique ; joueur P et défenseur D pilotés par deux humains, sauf fixture d'observation explicitement indiquée. Sol marqué tous les 2 studs, mur latéral long, mur d'impact et plateforme accessibles. Réinitialiser états/ressources entre essais, pas pendant une séquence. Enregistrer build SHA/fingerprint, lieu Studio/live, rig/joints, IDs/propriétaire d'animations, deux clients, latence **RTT observée**, framerate, modèle de manette, vidéo joueur et vidéo défenseur, input trace et mesures de vitesse/contacts. Trois répétitions par branche, côtés inversés. PASS exige toutes les clauses ; un UNKNOWN bloque ce scénario.

Les timings ci-dessous sont des **hypothèses de design**, à faire correspondre aux manifestes d'actions avant QA. Les changer implique versionner matrice et clips ensemble, pas déclarer PASS en ralentissant arbitrairement la séquence. Tap = pression 50–100 ms ; neutral = stick relâché ; ↑ = vers l'adversaire en lock, ↓ = s'en éloigner ; ←/→ = latéral. Hors lock : directions relatives à la caméra. Pas de souris/clavier requis.

| Entrée manette | Intent et résolution contextuelle proposée | Équivalent clavier à vérifier ensuite |
| --- | --- | --- |
| LS (stick gauche) | Move analogique, deadzone ≤0,15 à régler ; maintien demi-course ≠ plein sprint | WASD |
| RS (stick droit), R3 | Orbit/look ; R3 toggle Lock | Souris, Shift Lock |
| L3 | Sprint toggle ; annulation par arrêt prolongé ou action engagée selon manifeste | Ctrl |
| A | Jump ; près d'un mur : walljump ; après launcher confirmé dans fenêtre : Pursuit ; priorité explicite | Space |
| X | Light / suite / horizontal finisher ; dans grab : forward throw | Clic gauche |
| Y | Heavy ; après light2 + LS↑ : launcher ; en air + LS↓ : downslam ; dans grab : upthrow | T + direction |
| B | Directional dodge / air dash ; pendant préparation cancellable : CancelPrepare | Q |
| LB | Guard hold | F |
| LT | Grab tap ; grab invalide = whiff, pas stun | V |
| RT | Tool throw tap | R |
| RB + B | Evasive/substitution si ouverte et ressource disponible | E |
| RB + X / Y / A | Technique1 Prepare / Technique2 Read-deception / Technique3 Mark travel, uniquement fixtures/kits futurs | 1 / 2 / 3 |

RB est un modificateur, pas une deuxième action. Les commandes modifiées ne déclenchent pas simultanément X/Y/A/B de base ; priorité grab > action modifiée > contextualisation > base, avec refus si état incompatible. Les techniques ne réclament pas de menu radial au milieu du combo. Les rôles 1/2/3 sont propres aux fixtures 14–17, pas un kit imposé à vingt combattants.

## 01 — Stand → run → sprint → hard stop → reverse

- **Setup :** ligne droite 40 studs, P seul, hors lock, vitesse zéro, D hors trajectoire.
- **Inputs :** neutral 1 s ; LS↑ demi-course 0,5 s ; LS↑ plein 0,5 s ; tap L3 en conservant ↑ 1 s ; neutral 0,3 s ; LS↓ plein 0,8 s. Répéter inversion directe sans phase neutral.
- **Visible :** idle → start → course → sprint ; stop avec appui puis pivot lors du retour, sans jambes immobiles/glissement excessif.
- **Physique / branches :** vitesse monte sur plusieurs frames, freinage sans snap ; reversal traverse un freinage avant vitesse opposée. Demi-stick règle réellement l'allure. Variante neutral et variante reversal ont des appuis distincts.
- **Caméra :** FOV progresse avec vitesse mesurée, revient sans saut ; RS disponible pendant stop.
- **PASS :** direction/input immédiatement pris en compte localement, rampe 0,2–0,4 s et stop 0,12–0,25 s à qualifier ; déplacement continu et animation suit la vitesse.
- **FAIL :** WalkSpeed seul, vitesse maximale frame 1, mouvement serveur retardé, pivot instantané plein sprint, pose immobile ou joystick binaire.

## 02 — Sprint → jump → air steer → land avec momentum

- **Setup :** sol 40 studs, marque départ, aucun obstacle, P acquis en sprint.
- **Inputs :** LS↑ + L3 1 s ; tap A ; maintenir ↑ 0,2 s ; LS→ 0,25 s ; neutral jusqu'à contact ; LS↑ dès réception.
- **Visible :** takeoff/appui, montée/chute, corps accompagne la courbe latérale ; réception légère retrouve la course ; pas idle au sommet.
- **Physique / branches :** composante horizontale du takeoff au moins 90 % de celle immédiatement avant saut, hors coût déclaré ; air steer dévie progressivement, neutral conserve inertie ; landing ne remet pas XY à zéro. Variante chute haute produit recovery lourde explicitement différente.
- **Caméra :** garde la direction de déplacement et amortit hauteur ; pas de FOV reset au décollage.
- **PASS :** départ, steering et sortie forment une trajectoire continue, trois fois dans les deux directions.
- **FAIL :** arrêt horizontal au saut/landing, turbo bunny-hop cumulatif, inversion aérienne instantanée, slide sans réception animée.

## 03 — Sprint → jump → wallrun → walljump → air dash → landing

- **Setup :** long mur à droite, approche oblique avec distance de contact visible ; piste parallèle et sortie dégagée, budget aérien plein.
- **Inputs :** LS↑ + L3 0,8 s ; A ; LS↑ légèrement→ pendant 0,3 s pour entrer ; ↑ le long du mur 0,5 s ; A pour détacher ; LS← + B 0,2 s ; neutral puis ↑ à réception. Inverser côté ; refaire en relâchant le contact et au bord du mur sans second A.
- **Visible :** entrée appuyée, wallrun latéral, poussée de jambe au walljump, dash et réception dédiée ; branches de détachement lisibles.
- **Physique / branches :** projection tangentielle de l'élan d'entrée, sortie tangente + normale ; air dash conserve/transforme la vitesse plutôt que snap ; coin/contact perdu mène à chute ; impossible de recharger à l'infini sur le même mur.
- **Caméra :** extérieur au mur, deux corps si D proche, horizon utilisable ; aucune obligation de caméra FPS inclinée.
- **PASS :** chaîne entière sans blanc/position snapping, sur les deux côtés ; obstacle à la sortie interrompt correctement le dash.
- **FAIL :** animation mur sans vraie vitesse, montée canned CFrame, sortie vitesse zéro, coin traverse, air dash sans budget ou input clavier exclusif.

## 04 — Neutral → directional dodge → décision de repositionnement

- **Setup :** lock sur D à 8 studs, mur à gauche dans seconde répétition.
- **Inputs :** LS→ + B ; relâcher B ; dès sortie du dash, LS↑ + X pour approche ; refaire LS↓ + B puis LB pour garde ; troisième essai neutral + B.
- **Visible :** dash distinct selon direction, transition vers appui attaque/garde sans idle parasite ; neutral repli cohérent avec cible.
- **Physique / branches :** trajectoire bornée, i-frames et recovery séparés ; sortie conserve élan autorisé ; mur arrête sans pénétration ni teleport au-delà.
- **Caméra :** orbite cohérente, garde D dans le cadre, pas rotation instantanée de 180°.
- **PASS :** décision après sortie acceptée dans sa fenêtre, pas pendant phase engagée interdite ; cooldown empêche spam.
- **FAIL :** direction ignored, CFrame target jump, invulnérabilité égale à tout déplacement, vitesse forcée zéro ou action après dash perdue.

## 05 — Light → light → horizontal finisher

- **Setup :** P à portée de light, D sans garde ; sol et mur éloigné ; lock activé.
- **Inputs :** X à t=0 ; X à t≈0,28 ; X à t≈0,56 (timings initialement proposés) ; après recovery, LS↑. Refaire avec D reculant hors portée du troisième coup.
- **Visible :** trois clips/appuis distincts, avance corporelle mesurée, contact aligné avec réaction ; finisher directionnel plus marqué.
- **Physique / branches :** light1/2 transfèrent une poussée, finisher crée séparation horizontale ; whiff troisième ne déplace pas D et garde sa recovery ; pas magnet-contact malgré recul.
- **Caméra :** contact et recul inclus, FOV/changement de distance amortis.
- **PASS :** chaîne bufferisée légale, aucune touche dupliquée par maintien ; variante whiff punissable, mouvement d'attaquant cohérent.
- **FAIL :** damage labels seuls, mêmes poses, trois stuns statiques, hit hors volume ou recovery supprimée sur miss.

## 06 — Light → light → launcher → pursuit → air light → air light → downslam

- **Setup :** mêmes positions, budgets aérien/juggle pleins, zone au sol libre ; deux humains.
- **Inputs :** X ; X après ≈0,28 s ; LS↑ + Y après ≈0,28 s ; A dans fenêtre de poursuite après contact launcher ; X à portée aérienne ; X dans fenêtre suivante ; LS↓ + Y ; à réception LS→. D essaie RB+B pendant sa fenêtre dans seconde répétition.
- **Visible :** uppercut articulé → victime airborne → poursuite animée avec travel → deux contacts aériens distincts → slam vers sol → impact/knockdown/wakeup ; aucune pose Punch recyclée pour tout.
- **Physique / branches :** vitesses verticales/horizontales réelles ; pursuit peut manquer une sortie adverse ; chaque air hit modifie trajectoire, budget fini ; slam atteint collision sol, knockdown borné. Après escape, suite sur ancienne cible ne touche pas à distance.
- **Caméra :** élève/élargit pour les deux corps, revient au sol sans perdre l'impact ; RS influence conservée.
- **PASS :** toute chaîne réellement jouée à la manette, continue, plus branche défensive légale ; pas d'infini en remettant un launcher.
- **FAIL :** Y offset/stun en l'air, pursuit teleport, victime suspendue immobile, air hits sans déplacement, slam CFrame rotation seule ou adversaire hors écran.

## 07 — Launcher sans poursuite : trajectoire et recovery du défenseur

- **Setup :** sol plat, D sans charge evasive pour première branche, charge disponible ensuite.
- **Inputs :** P X → X → LS↑+Y ; P neutral et **aucun A** ; D neutral jusqu'à fenêtre défensive puis LS→ + B si sortie autorisée ; autre essai neutral jusqu'à landing puis LS→.
- **Visible :** arc de launch, chute, réception/recovery, retour contrôlé ; P ne monte pas automatiquement.
- **Physique / branches :** gravité réelle et vitesse horizontale héritée ; D récupère par règle prévue sans attendre fin de combo de P ; pas relaunch gratuit au réveil.
- **Caméra :** conserve P au sol et D en altitude, même sans pursuit.
- **PASS :** launch autonome possède une fin, D peut choisir une sortie/réception légale, P choisit distance/pression ensuite.
- **FAIL :** D flotte jusqu'à timer, revient par snap, P suit automatiquement ou garde impossible indéfiniment.

## 08 — Nouvelle frappe aérienne change la direction du défenseur

- **Setup :** D déjà lancé selon 07, P pursuit côté droit ; repères de trajectoire de QA activables.
- **Inputs :** P A pursuit ; LS← + X à portée ; neutral ; répéter LS→ + X depuis approche opposée ; D LS↓ + B dans fenêtre autorisée.
- **Visible :** contact latéral et réaction orientée correspondant au côté touché, pas loop vertical identique.
- **Physique / branches :** vecteur post-hit diffère du vecteur pré-hit selon direction de l'action, composante verticale maîtrisée ; trajet désormais interceptable autrement ; air evade fait whiff si bien timing.
- **Caméra :** recompose vers nouvel arc, ne verrouille pas l'ancienne prédiction.
- **PASS :** changement mesurable et visible sans téléport, trois essais et deux côtés ; budget empêche maintien infini.
- **FAIL :** seul compteur/stun change, velocity override toujours identique, décorative rotation sans nouvelle trajectoire.

## 09 — Heavy knockback près d'un mur

- **Setup :** D à 3 studs du mur arrière, P face au mur ; refaire loin du mur et D en garde.
- **Inputs :** P LS↑ + Y depuis neutral, puis neutral ; D B latéral au télégraphe dans branche évitement, LB dans branche garde.
- **Visible :** heavy anticipation/appui, impact/recul puis wallsplat/rebond dédié ; garde et whiff ont feedback distinct.
- **Physique / branches :** collision réelle avant impact mur, énergie/angle bornés ; aucune traversée ni dégât mural doublé par plusieurs parts ; sortie après wallsplat.
- **Caméra :** collision mur sans encastrement, garde contact puis victime visible ; pas de tilt masquant appuis.
- **PASS :** mur modifie réellement l'échange ; loin du mur le coup produit seulement knockback normal ; dodge fait whiff recovery.
- **FAIL :** wallsplat déclenché par proximité sans collision, ragdoll explosif, mur infini, camera dans mur ou hit through-wall.

## 10 — Grab → forward throw et grab → upward throw

- **Setup :** portée courte face à face, D en garde, budget air libre ; refaire hors portée et près d'un mur.
- **Inputs :** P LT tap ; après capture LS↑ + X → lancer avant. Reset ; LT puis LS↑ + Y → lancer haut ; A pour poursuivre si fenêtre autorisée. D LS→+B au télégraphe dans autre branche.
- **Visible :** deux animations de prise synchronisées et lancers distincts ; D lâché avant vol/landing ; grab whiff visible.
- **Physique / branches :** capture vérifiée angle/portée/état ; grab bat garde, perd contre déplacement/esquive ; couplage court collision-safe ; vitesses avant/haut différentes, release garanti si mort/reset/obstacle.
- **Caméra :** deux silhouettes pendant prise, suit le vol sans centrage sur ancienne prise.
- **PASS :** les deux throws et les échecs sont jouables ; D récupère selon trajectoire, aucun contrôle d'attaquant déplacé par bug.
- **FAIL :** stun à distance, attach permanent, throw identique, victime PivotTo destination, saisie à travers mur ou purge lifecycle manquante.

## 11 — Guard normal chain puis punish whiff/recovery

- **Setup :** D à portée, P face à lui ; ressource garde pleine.
- **Inputs :** D maintient LB ; P X → X → X ; D relâche LB et LS↓+B pendant le télégraphe d'un Y de P ; dès Y manque, D LS↑+X. Refaire garde tournée loin de P.
- **Visible :** garde loop/recoil, appuis sous pression ; heavy manqué finit son mouvement ; contre-attaque de D lisible.
- **Physique / branches :** angle garde validé, pushback/pression coût mesuré ; arrière de garde vulnérable ; punish arrive pendant recovery, pas annulation impossible du heavy par garde instantanée.
- **Caméra :** suit changement d'attaquant sans flip ; champ garde/arme visible.
- **PASS :** vraie décision garder/esquiver puis approche/punish ; pas avantage automatique après chaque block.
- **FAIL :** garde omnidirectionnelle cachée, aucun recul, whiff sans recovery, bouton garde efface toute récupération.

## 12 — Evasive/substitution après ouverture, charge et counterplay

- **Setup :** D avec une charge ; P ouvre par light/launcher ; destination latérale libre puis obstruée.
- **Inputs :** D LS→ + RB+B pendant fenêtre d'ouverture autorisée ; D tente X immédiatement puis à sa sortie recovery ; P poursuit avec LS→+A/X si légal. D retente RB+B sans recharge ; refaire avant ouverture.
- **Visible :** cue de sortie et direction, ressource consommée, recovery de réapparition/evade lisible ; refus clair à charge zéro.
- **Physique / branches :** sortie bornée collision-safe ; pas de dégât automatique en sortie ; P peut lire/punir la nouvelle position ; pas d'escape pendant un état explicitement incompatible.
- **Caméra :** suit position réelle autorisée, jamais une vieille cible invisible ; D conserve contrôle.
- **PASS :** échappe une ouverture au prix déclaré, ne garantit pas retournement ; deuxième usage refusé et mur respecté.
- **FAIL :** recharge par hit, invulnérabilité permanente, teleport through-wall, counter gratuit, charges décidées client.

## 13 — Projectile force guard/dodge et approche

- **Setup :** distance 18 studs, projectile universel simple, couloir dégagé ; cooldown stock limité.
- **Inputs :** P RT puis LS↑+L3 pendant recovery autorisée ; D LB, puis autre essai LS→+B au cue ; P X seulement à portée réelle.
- **Visible :** lancer R15/télégraphe, vol continu, block/whiff distinct ; P se rapproche pendant la décision de D.
- **Physique / branches :** projectile sweep ne traverse pas cible/mur à haute vitesse ; pas damage sur dodge réussi ; approche couvre une distance réelle ; RT spam refusé selon stock/cooldown.
- **Caméra :** conserve D et corps de P ; n'orbite pas vers projectile, impact reste lisible.
- **PASS :** outil crée une décision puis possible contact manuel ; les deux branches existent.
- **FAIL :** projectile instant-hit caché, trajet sans collision, block ne change rien, jutsu damage auto suivi de téléport approche.

## 14 — Préparation courte interrompue par melee

- **Setup :** slice future avec fixture Technique1 prepare 0,6 s, commit défini, coût/remboursement journalisé ; D proche.
- **Inputs :** P RB+X ; D LS↑+X à +0,25 s ; P garde RB+X jusqu'à +0,8 s. Répéter D X après commit.
- **Visible :** préparation distincte/avertissement ; contact avant commit casse la préparation et produit réaction ; après commit, effet/recovery suivent règle différente.
- **Physique / branches :** interruption arrête instance future et applique coût défini une fois ; pas projectile fantôme/tâche retardée continuant après stun ; late hit ne rembobine pas un résultat acquis.
- **Caméra :** aucune cinématique forcée ; distance et télégraphe restent lisibles aux deux joueurs.
- **PASS :** early/late branches et charges reproductibles ; melee exige toucher réellement.
- **FAIL :** préparation invisible, interrupteur stun mais technique part quand même, coût doublé en replay, invulnérabilité automatique.

## 15 — Fake preparation pour provoquer une réponse

- **Setup :** même fixture, fenêtre cancel avant 0,4 s, recovery/cout partiel définis ; D à portée de punish.
- **Inputs :** P RB+X ; à +0,20 s relâcher RB/X puis B (CancelPrepare contextuel) ; D Y au cue ; P LS→+B après recovery de feinte, puis LS↑+X si heavy de D manque. Refaire D ignorant le faux cue.
- **Visible :** début de préparation identique avant cancel, sortie propre ; D engage un choix lisible ; P doit esquiver/approcher pour punir.
- **Physique / branches :** cancel n'est pas aussi une dodge gratuite ; coût/recovery empêchent spam ; si D ignore, aucun bonus automatique à P.
- **Caméra :** cue visible sans zoom cachant D ; maintien du contrôle RS.
- **PASS :** mauvaise réponse crée ouverture réellement exploitée ; bonne lecture ne donne pas cette ouverture.
- **FAIL :** bouton feint damage/stun gratuit, cancel après commit rembourse tout, B déclenche deux actions, preparation spam infini.

## 16 — Marque/kunai change un angle, sans teleport spam

- **Setup :** slice future fixture mark sur kunai ; deux destinations, l'une derrière obstacle ; charge/coût et expiration définis.
- **Inputs :** P RT pour placer/contact mark ; LS→ pour créer angle ; RB+A pour déplacement conditionnel ; relâcher puis LS↑+X pour punish manuel ; RB+A à répétition, puis sur marque expirée et destination bouchée.
- **Visible :** marque/localisation lisible, déplacement spécial télégraphié et arrivée/recovery ; attaque part séparément.
- **Physique / branches :** exception de déplacement conditionnelle autorisée serveur, destination validée, coût/cooldown/budget et interruption ; angle différent, aucune touche automatique. Cette technique spéciale n'autorise pas les dashes ordinaires par CFrame.
- **Caméra :** recompose après destination sans perdre D ni verrouiller l'ancien angle ; aucune cinématique obligatoire.
- **PASS :** marque change la géométrie d'approche ; spam/expiry/obstacle refusés et counterplay à l'arrivée.
- **FAIL :** RB+A attaque touche à distance, marks illimitées, coûts client, destination à travers limite/sol ou répétition sans recovery.

## 17 — Read/deception induit une erreur puis punish manuel

- **Setup :** slice future fixture Technique2 : faux cue de déplacement latéral bref, Read conditionnel ; D humain, puis même observation alimentant AI future ; aucun contrôle désactivé.
- **Inputs :** P RB+Y dans fenêtre Read ; D LS↑+X vers silhouette/indice perçu ; P LS→ pour sortir de l'axe puis LS↑+X pour toucher ; refaire D attendant/guardant en vérifiant l'indice contradictoire. P tente hors condition/coût.
- **Visible :** D reçoit fausse piste courte mais peut agir ; contre-indice/expiration perceptibles ; P voit son vrai corps et choisit le punish ; HUD/lock n'affichent pas la vérité sous le masque.
- **Physique / branches :** aucun stun/damage automatique ; hitboxes restent liées au corps légal, coût valide, erreur de D peut whiff ; bonne décision contre illusion évite la punition.
- **Caméra :** ne vole pas contrôle, politique lock suit perception cohérente sans secret révélé gratuitement.
- **PASS :** les deux décisions donnent résultats distincts ; victoire demande contact manuel ; AI n'utilise pas la vérité cachée.
- **FAIL :** cinq secondes hard stun, forced auto-punish, faux clone absorbant hit sans règle, lock/UI omniscients ou illusion incontrable.

## 18 — Caméra ground → air → ground

- **Setup :** reprise complète de 06 en trois géométries : centre, mur à 3 studs, plateforme ; vue de P et D enregistrées.
- **Inputs :** séquence 06 ; pendant pursuit RS→ 0,2 s puis RS↑ 0,2 s ; relâcher à slam ; R3 off/on après réveil.
- **Visible :** anticipation/contact/air/slam/landing présents avec silhouettes distinguables ; aucune particule ne cache impact.
- **Physique / branches :** mêmes trajectories/contacts que 06, changer camera ne change pas portée/position ; LOS réelle protège au mur.
- **Caméra :** les deux centres corporels restent dans la zone centrale 80 % aux moments de contact ; hors cadre ≤0,1 s lors d'une correction exceptionnelle consignée, jamais pendant un contact ; aucune pénétration mur ; RS a effet perceptible sans renversement.
- **PASS :** mêmes exigences sur les deux vues, trois géométries, ground/air/return ; joueur peut retrouver cible après unlock.
- **FAIL :** launcher mécaniquement correct mais victime hors écran, near clip dans corps/mur, horizontale flip, caméra bloque les commandes.

## 19 — Core sequence entièrement sur manette

- **Setup :** manette physique, clavier/souris inutilisés après lancement ; HUD prompts de manette ; deux joueurs ou dummy de branche configuré avant essai.
- **Inputs :** R3 lock → LS↑ L3 sprint → A jump → B air dash → landing → LS→ B → X/X/LS↑Y → A pursuit → X/X/LS↓Y → recovery → LB guard → LT/X grab/throw → RT tool. Puis RB+B sortie dans essai séparé. Utiliser RS durant combat.
- **Visible :** exactement mêmes clips/actions que clavier, glyphes corrects, transitions/branches accessibles ; pas technique simultanée via modificateur.
- **Physique / branches :** analogique, front/hold/toggle cohérents, buffer fiable, deadzone sans dérive ; coûts et vitesse identiques au clavier.
- **Caméra :** RS ne requiert pas shift-lock clavier ; R3 ne déclenche pas sprint ; reset/rematch accessibles par menu manette.
- **PASS :** séquence et branches depuis contrôleur seul sur matériel réel ; aucun retour au clavier, action manquée ou double déclenchement en trois essais.
- **FAIL :** seulement émulateur bouton, combo clavier-only, Jump avalé par pursuit hors fenêtre, RB déclenche technique et attaque, UI rematch inaccessible.

## 20 — Latence : prédiction locale, décision serveur, correction

- **Setup :** deux clients séparés, baseline puis profils RTT observés ≈50/150/250 ms, jitter ±30 ms et perte 1–3 % quand outil le permet. Documenter si Studio règle un délai aller simple, ne pas l'appeler RTT. Scénarios 02,04,06,11,13,18 ; place privée publiée requise en plus de Studio.
- **Inputs :** P sprint/A puis X/X/LS↑Y/A/X/X/LS↓Y ; D LB juste avant contact puis LS→B à un autre essai ; simuler input doublé/ancien et une position/hit client falsifiée dans tests techniques associés.
- **Visible :** propre mouvement/anticipation apparaît localement sans attendre RTT ; hit anticipé reste discret ; garde serveur invalide un hit prédit sans dégâts persistants, double son ou shake répété.
- **Physique / branches :** serveur arbitre contact, défense, victim impulse, coûts et match ; replay restaure ressources/buffer/phases, pas nouvelle random decision ; clip/hitset valide après correction. Pas de rewind libre client ; peut y avoir un whiff/correction à haute latence, présenté honnêtement.
- **Caméra :** suit correction avec amortissement sans perte prolongée, retrouve graph/track actuels ; pas oscillation perpétuelle.
- **PASS :** local input→début mouvement/anticipation ≤2 frames de simulation à framerate stable, hors contrainte d'action ; aucune double consommation/résolution, aucun hit frauduleux accepté ; à 150 ms les deux joueurs peuvent terminer/contrer séquence sans corrections récurrentes >1 stud hors impulsion attendue. À 250 ms, mesure et jugement humain consignés ; limite déclarée si qualité insuffisante, aucun PASS par absence de crash.
- **FAIL :** chaque dash attend RTT, autorité client, health fantôme, invulnérabilité par timestamps, son/reaction doublés, fling/snap durable ou use-after-rollback animation.

## Enregistrement de verdict et périmètre

Pour chaque branche : `scenario / build / environnement / inputs / vidéo P / vidéo D / physique / animation / caméra / counterplay / controller / résultat / défauts`. Verdict global = conjonction des colonnes, avec identifiant des anomalies et retest sur le build corrigé. Les mesures sont supports de ce verdict, pas substitut au regard humain ni à dix minutes de jeu.

Gate FOUNDATION 02 proposé : **01–13 et 18–20**, sans techniques de personnage (projectile neutre et sortie défensive universelle inclus). **14–17 : SPECIFIED, NOT IMPLEMENTED, NOT TESTED**, pour la slice ultérieure ; aucune clôture de toute la vision sur ce sous-ensemble. L'AI de 17 reste un gate distinct futur. Aucun nouveau PASS aujourd'hui.
