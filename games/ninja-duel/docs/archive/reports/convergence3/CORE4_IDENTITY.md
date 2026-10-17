# Identité CORE4 vue en jeu — convergence 3

Mission : [NEXT_VALIDATION_ROSTER_SCALE](../../missions/NEXT_VALIDATION_ROSTER_SCALE.md) §5. Branche `claude/nd-vrs-identity2`, base `2aba0ca`. Suite de la passe précédente : [IDENTITY_JUTSU](../convergence2/IDENTITY_JUTSU.md).

**Statut : IMPLÉMENTÉ, TESTÉ EN HEADLESS SEULEMENT.** Rien de ce document n'a été joué ni regardé dans Studio. Les tests prouvent les faits serveur (feed de contacts, snapshot) et que chaque repère client se construit au bon endroit dans une scène bouchonnée (`Harness.stubScene`). L'aspect, la lisibilité à vitesse réelle et le ressenti restent à juger (liste Studio en fin de document).

Principe : le serveur dit ce qui s'est passé (quel coup, quel point, quelle cause, quel compte), le client le montre. Les repères vivent dans un module client d'identité, `src/Client/IdentityFX.luau`, installé dans Effects comme SandFX et LeeFX.

## Neji — le réseau de chakra se voit

| Exigence | Fait serveur | Repère client / HUD |
|---|---|---|
| Paume ≠ coup de poing | Le contact d'une paume porte `move`, `point` (le tenketsu fermé), `drain`. Plus de gerbe « poing » du donneur (BanglaAssets) sur un contact Gentle Fist | Empreinte de paume ouverte (talon, quatre doigts, pouce) **sur le point exact**, trait de chakra qui entre dans le corps, main qui frappe allumée. Plus de flash au centre du corps |
| Paume bloquée | Le contact bloqué porte `drain` (3) | Empreinte pâle sur la garde, filets de chakra aspirés vers la main de Neji |
| Accumulation lisible des deux côtés | (existant) `tenketsuPoints` | Chaque point fermé garde un repère de taille fixe à l'écran (lisible de loin, attaquant et défenseur). HUD : quatre pastilles sur la plaque du fighter visé, allumées point par point, avec un « pop » à chaque fermeture. Le tic sonore existait |
| Conséquences reliées | Snapshot `chakraRegen` (la part de régénération restante, même formule que Combat) | Barre de chakra assombrie, statut « CHAKRA REGEN -30% », « NETWORK SEALED » à 4 points. Jutsus scellés grisés avec la raison : « SEALED • 2.4s » sur chaque bouton, « JUTSU SEALED » sur la plaque |
| Rotation → contre | Le contre est un contact paume `variant=TrigramCounter` | Paumes allumées tant que la fenêtre de contre est ouverte. Le dôme se referme sur la paume au contact. HUD : « LMB — TWIN PALM 0.6s » |
| Vacuum Palm et mur | La réaction garde sa cause ; le contact mur porte `cause=VacuumPalm`, `by=GentleFist` | Grande empreinte d'air et anneaux sur la pierre. Pas sur les autres chocs au mur |
| 64 Palms, apogée | Un seul contact par paume (avant : coup générique plus paume). Chacun porte `count` (2-4-8-16-32-64 répartis sur la rafale, 64 seulement sur la dernière), `strike`, `strikes`, `final`. Cue du compte aux deux joueurs | Compte au-dessus de la tête de la victime, visible des deux côtés, qui grossit. Anneau au sol à chaque annonce. Dernière paume lourde (souffle dans l'axe de la projection), compte tenu un temps puis effacé |

## Minato — sceaux, chaînes, Yellow Flash

| Exigence | Fait serveur | Repère client / HUD |
|---|---|---|
| Sceaux distincts | (existant) `seals` avec `body`, `wind`, `wake` | **Kunai planté** : balise dorée verticale. **Formule au sol** (sceau de retour du Yellow Flash) : formule blanc-or tournante, **sans kunai** (Effects ne dessine plus de kunai là où aucun n'a été lancé). **Marque corporelle** : anneau de formule qui tourne autour du corps, visible de face (avant : seulement un disque dans le dos, invisible depuis la caméra de Minato), qui se resserre à l'expiration. Vent en vert |
| Combo → relocalisation → combo | Le coup d'arrivée (frappe, launcher, slam, **Rasengan** de sortie de téléport) qui touche un corps encore dans le combo porte `arrival`. Event `FlashChain`, cue « FLYING THUNDER GOD • THE CHAIN GOES ON ». Route de base prouvée : Light1, Light2, ↑ (le coup montant scelle le corps), 2 (FTG), Air1 | Lien doré au contact. Anneau doré sous Minato qui se referme avec la fenêtre d'arrivée. HUD : « LMB — ARRIVAL STRIKE • RMB — LAUNCH (SLAM en l'air) • 3 — RASENGAN » |
| Conversion Rasengan | Le contact porte `variant=Rasengan` | Anneaux qui tournent sur tous les axes (le Rasengan « broie ») et gerbe bleue |
| Yellow Flash visible | (existant) sceau de sillage, fenêtre 0,8 s | Fil doré de Minato vers son dernier sceau de retour (A → B → A). Ligne d'éveil sous la plaque : « YELLOW FLASH 8.2s • EACH JUMP LEAVES A RETURN SEAL • FLASH ONTO A LAUNCHED BODY » |

La string-cancel en FTG reste un nœud de progression (`StringFlash`, testé par Progression.spec). Elle n'est pas ajoutée au kit de base.

## Itachi — prédiction, géométrie, feu de contrôle

| Exigence | Fait serveur | Repère client / HUD |
|---|---|---|
| Read = prédiction | (existant) impact `read` | Posture : trois tomoe tournent à ses pieds (l'attaquant le voit aussi). Lecture : trait rouge de ses yeux au corps qui frappe. Anneau rouge qui se referme avec la fenêtre de contre. HUD : « LMB — COUNTER PALM 0.7s » |
| Mirage vrai/faux | (existant) | Image prise : trait de l'image vers le vrai corps, qui s'allume |
| Ricochet / Geometry | Le contact de ricochet porte `ricochet`, `to`, `direction`. La rencontre Geometry porte `geometry`, `to` | Le nouveau trajet flashe du rebond jusqu'au corps. Deux trajets vers le flanc pour Geometry |
| Feu = contrôle | **Gameplay** : la Grande Boule de feu d'Itachi (`Lane=true`, Fighters) brûle une **voie** de plaques au sol, espacées de 5 studs, là où elle passe à moins de 14 studs de l'adversaire (`Elements.burnLane`). Les plaques font des dégâts de brûlure classiques (`Combat:chip`, jamais d'étourdissement, ni combo). Elles brûlent aussi un fil. Snapshot : `lane` sur les hazards | Une bande brûlée continue, bordée de braises, d'un bout à l'autre de la voie |

La boule de feu de Sasuke et l'infusion feu des outils (ChakraCombat) ne sont pas touchées.

## Sasuke — la marque, les routes, le risque

| Exigence | Fait serveur | Repère client / HUD |
|---|---|---|
| Curse Mark visible | (existant) `awaken`, `curseHunger` | La marque s'étend du sceau du cou, flamme après flamme, sur le visage, l'épaule et le bras. Affamée, elle traverse le visage et clignote. Elle disparaît avec l'éveil. Plaque : « CURSE MARK 6.5s • HUNGRY: LAND A BLOW » |
| Continuité Danse de la feuille / Lion Combo | Snapshot `lion` (fenêtre du finisher aérien) | Chaîne d'ombres sous le corps qui monte. HUD : « RMB — LION COMBO » (le cue du finisher pour Lee). Le coup sauté (VaultKick) trace son arc |
| **Correctif** | — | Les cues de Sasuke n'arrivaient jamais à l'écran : le filtre du HUD ne laissait pas passer DANCING LEAF, LION COMBO, CURSED LEAF, CURSE MARK, CHIDORI (ni LOTUS pour Lee). Ils passent |
| Phoenix Flower, outil caché | Les deux lames cachées sont marquées `hidden` (snapshot) | Éclat d'acier quand elles sortent des flammes |
| Chidori, risque / conversion | Le contact porte `move=ChidoriThrust`. Une poussée qui ne touche rien (pas même une garde) déclenche l'event `ChidoriMissed` et le cue « CHIDORI MISSED • PUNISH » (adversaire) / « CHIDORI • MISSED • OPEN » | Touché : éclairs dans l'axe de la poussée. Raté : le Chidori s'éteint en grésillant. Côté adverse, pendant la charge : « LMB — BREAK THE CHIDORI CHARGE » |

## Contrat ajouté

- **Contacts** (`Brawler.tagContact`) : chaque frappe touchée ou bloquée porte `move`, `variant`, `owner`, `fighter`, `victim`.
  - Paumes : `point`, `drain`.
  - 64 Palms : `count`, `strike`, `strikes`, `final`.
  - Chaîne FTG : `arrival`.
- **Autres impacts** :
  - mur : `cause`, `by` (`Brawler.react` reçoit une cause facultative) ;
  - whiff : `owner`, `fighter`, `move`, `variant` ;
  - ricochet : `ricochet`, `to`, `direction` ;
  - Geometry : `geometry`, `to`.
- **Snapshot** :
  - acteur : `chakraRegen`, `lion` ;
  - hazards : `lane` ;
  - projectiles : `hidden`.
- **Effects** :
  - les layers peuvent déclarer `frame(fx,data,dt,folder)`, appelé une fois par image avec tout le duel ;
  - le sceau `wake` n'a pas de kunai.

## Preuves

- **Tests** : `tests/Identity.spec.luau` passe de 26 à **57 cas**, dans `run.sh` et la porte de `build.py`.
  - Les **31 nouveaux échouent sur `2aba0ca`** : la spec a été lancée sur une exportation de la base. Résultat : 31 FAIL avec des messages d'assertion, les 26 anciens passent.
  - 23 suites, 390 cas PASS. Isolation des builds 9/9, architecture et docs PASS.
- **Équilibre IA** : `Balance.sim` (4 graines), matrice quasi identique à la base. Une seule graine bascule (Itachi contre Minato).
- **Builds** (normal / Debug / QA, chacun après la porte complète) :
  - `NinjaDuel.rbxlx` `b1af0d3f49c3cbf3311af511dba9c3e021babb28799ce9b7f3c15368afcd35e9`
  - `NinjaDuel-Debug.rbxlx` `f4d39b0e1f75b5a92fe703db73dd97912ee8918a97a4d2ad7d1eaf434a7e0ce5`
  - `NinjaDuel-QA.rbxlx` `402640e5b6002483522e805ee3bf967cbeeaa4d2dfa961720a162d4a2632c527`

## Fichiers partagés touchés

| Fichier | Pourquoi (diffs courts et additifs) |
|---|---|
| `Brawler.luau` | Nouvelles fonctions `contactImpact`, `tagContact`, `tenketsuRegen`. Ailleurs, modifications de quelques lignes : cause dans `react` et `splat`, point/drain dans `gentleFist`, marque `flashStrike` du coup d'arrivée, `FlashChain` dans `hit` |
| `Combat.luau` | Une ligne chacun : régénération via `Brawler.tenketsuRegen`, cause `VacuumPalm`, champs du whiff, du ricochet et de Geometry |
| `Techniques.luau` | 64 Palms (`palmCount`, un contact par paume, paume d'ouverture), cue de Chidori raté, `flashStrike` du Rasengan de sortie de téléport |
| `Effects.luau` | Une ligne `require` d'IdentityFX, hook `layer.frame`, pas de kunai pour un sceau `wake` |
| `UI.luau` | Pastilles de tenketsu, barre de chakra, jutsus scellés, ligne d'éveil, invites (arrivée, Lion Combo, contre nommé, charge du Chidori), filtre des cues |
| `Fighters.luau` | `Lane=true` et l'indice de la Grande Boule de feu d'Itachi |
| hors liste : `Matches.luau`, `Elements.luau`, `BanglaCombat.luau` | Champs du snapshot ; voie de feu et marque `hidden` ; pas de gerbe de poing pour le Gentle Fist |

Non touchés : `ChakraCombat`, `ChakraTuning`, `WireTrap`/`wireBind`, `Combat:chip`, `MoveGraphs`, `AI`, `VelmoraMotionEngine`.

## À valider dans Studio (place Debug, F6 : `character`, `dummy`, `refill`, `awaken`)

1. **Neji contre Itachi immobile** (`character first=GentleFist second=Mirage`, dummy). Clics gauche répétés au contact :
   - chaque paume imprime une main ouverte sur la poitrine (cœur, plexus) ;
   - aucune gerbe orange de poing ;
   - un repère bleu reste sur chaque point fermé et se lit à 20 studs ;
   - la plaque d'Itachi allume 1 à 4 pastilles, sa barre de chakra s'assombrit, « CHAKRA REGEN -15/-30/-45/-60% ».
2. **Même duel, Itachi garde (dummy off, ou un 2ᵉ joueur)** : sur une paume bloquée, filets de chakra aspirés de la garde vers la main de Neji.
3. **64 Palms (touche 3)** au contact, après 0 puis 4 points fermés :
   - le compte au-dessus de la tête de la victime monte 2-4-8-16-32-64 ;
   - 64 tombe sur la paume qui projette ;
   - anneaux sous Neji ;
   - les boutons de jutsu de la victime affichent « SEALED • x.xs » et sont grisés ;
   - vérifier aussi depuis le côté victime (Itachi joueur, Neji IA).
4. **Rotation (1) contre un coup**, puis clic gauche : les paumes restent allumées pendant la fenêtre ; le contre libère le dôme au contact ; l'invite « TWIN PALM » apparaît.
5. **Vacuum Palm (2) près du mur du stade** : le corps colle au mur avec une grande empreinte de paume bleue sur la pierre.
6. **Minato** :
   - Kunai marqué (1) au sol : balise dorée lisible de loin ;
   - coup sur Itachi : anneau de formule autour du corps, **visible de face** ;
   - Light, Light, W + clic (coup montant), puis 2 : lien doré au contact de Air1, cue « THE CHAIN GOES ON » ;
   - anneau doré qui se referme sous Minato à l'arrivée ; invite « ARRIVAL STRIKE • 3 — RASENGAN » ;
   - 3 à l'arrivée : le Rasengan broie au contact.
7. **Yellow Flash** (`awaken actor=human`), FTG vers un sceau :
   - formule au sol **sans kunai** au point de départ ;
   - fil doré vers ce sceau ;
   - ligne d'éveil sous la plaque.
8. **Itachi** :
   - Read (1) : tomoe à ses pieds ; frappé dedans, trait rouge des yeux vers l'attaquant, anneau rouge qui se ferme, « COUNTER PALM x.xs » ;
   - Mirage (3), puis frapper l'image : trait vers le vrai corps ;
   - shuriken contre un mur près de la cible : trajet du ricochet ;
   - D + R (Geometry) : deux trajets vers le flanc.
9. **Grande Boule de feu d'Itachi (4)**, la cible fait un pas de côté : voie de feu brûlée le long de la trajectoire près d'elle. **Juger** :
   - si la voie coupe vraiment le chemin et se lit comme une ligne ;
   - si les dégâts (1,6 par 0,48 s) sont justes ;
   - si l'IA marche trop dedans.
10. **Sasuke** (`awaken actor=human`) :
    - la marque s'étend du cou sur environ 1 s ; elle traverse le visage et clignote quand il ne touche plus ;
    - Light, Light, W + clic : ombres sous le corps, « RMB — LION COMBO » ;
    - D + clic après un coup : arc du saut ;
    - Phoenix Flower (2) : éclat des deux lames ;
    - Chidori (4) dans le vide : grésillement et « CHIDORI MISSED • PUNISH » côté adverse ; au contact, éclairs dans l'axe ;
    - côté adverse, pendant la charge : « BREAK THE CHIDORI CHARGE ».
11. **Général** : manette (libellés □/△ et R1 + … dans les invites) ; bruit visuel (repères AlwaysOnTop à travers les obstacles) ; FPS avec deux combattants actifs.

## Risques et points ouverts

- **Gameplay modifié** : la voie de feu d'Itachi (dégâts de brûlure en plus quand la boule frôle l'adversaire ; l'IA n'évite pas les hazards). Tout le reste est de la présentation, ou des champs ajoutés au feed et au snapshot.
- **Un seul contact par paume pendant les 64 Palms** : l'ancien doublon « light + palm » disparaît. Le son et la caméra de chaque paume sont ceux du style `palm`, un peu plus discrets. À juger.
- **Repères `AlwaysOnTop`** (points de tenketsu, compte des 64) : visibles à travers le décor, voulu pour la lisibilité. Peut sembler bruyant.
- **Taille réelle des repères**, à régler dans Studio (heuristiques, jamais rendues) : marque de Curse Mark (`CURSE_SPREAD`) ; anneau du corps de Minato (rayon 1,25–1,7) ; balise de 7 studs.
- **Conflits de fusion probables** avec les autres agents :
  - `Brawler.hit` : bloc après `tryHit` ;
  - `UI.luau` : chaîne des `hint`, filtre `loud` ;
  - `Effects.update` : hook `frame`.

  Tous additifs.
- **Docs non mises à jour** (au lead) : fiches CORE4 (« État — convergence 3 »), `SINCE_LAST_CLAUDE`, backlog.
