# Naruto — clones, rush et réserve immense (vague d'archétypes)

Code proposé : `Legion` (absent du code). IDs : CHR-EXT-002, NET-001 (corps supplémentaires répliqués), AI-001, SYS-001/003, CAM-001.

> Fiche de conception Claude du 2026-10-16 (mission [COMBAT_CONVERGENCE_ONLINE_ROSTER](../missions/COMBAT_CONVERGENCE_ONLINE_ROSTER.md) §18–21, DEC-012/DEC-013). Rien n'est implémenté ; valeurs = points de départ à régler en natif. Code lu sur `c2d797c` (chemins relatifs à `games/ninja-duel/src/`, le nom de fonction fait foi). Sources canon « à vérifier » non confirmées. Plan : [ROSTER_WAVE_PLAN](ROSTER_WAVE_PLAN.md) ; hooks : [ROSTER_WAVE_HOOKS](ROSTER_WAVE_HOOKS.md).

## Stade retenu (DEC-013)

**Vallée de la Fin, Partie I (≈13 ans)** (exemple explicite de DEC-013) : Kage Bunshin (plafonné), Rendan Uzumaki, kunai-clone transformé, Rasengan **formé avec l'aide d'un clone**, sursaut du chakra de Kyûbi, manteau à une queue. Échelle absente : Gamabunta (géant), quatre queues, mode ermite, Rasenshuriken, mode Kurama.

## Pourquoi il mérite une place (système éprouvé)

1. **Combat à plusieurs corps** (H12) : tout le moteur suppose deux corps — `Combat:separate` lit `actors[1]` et `actors[2]` (`Server/Combat.luau:1309-1310`), chaque projectile ne teste que `p.a.target` (`:1241-1285`), le snapshot n'envoie que `human` et `bot` (`Server/Matches.luau`). Les clones forcent : corps serveur non-acteurs, routage des coups vers eux, réplication, rendu client, IA qui les voit, verrouillage caméra.
2. **Angles réels sans téléport** : un coup de clone est jugé depuis la position du clone grâce au mécanisme de flanc existant (`self.hitOrigin`, `Combat.luau:161`) — la garde frontale ne couvre pas un clone dans le dos.
3. **Technique à deux corps** : son Rasengan exige un clone vivant pendant la canalisation (le casser l'annule) — première technique dont le contre-jeu est un **autre corps**.
4. **Économie de la plus grande réserve** + sursaut unique à 0 (H05) ; éveil qui **retire** une capacité (plus de clones en manteau) au lieu d'en ajouter.

## Mécanique signature

**Routes de clones** : jusqu'à 2 clones vivants (12 chakra chacun, 6 s, un seul coup les dissipe). Certaines suites se résolvent **par un clone** au lieu de Naruto : le 3e coup de string vient de l'autre côté, la route latérale fait surgir un clone en miroir, le launcher est exécuté par des clones qui jonglent pendant que Naruto choisit sa conversion, le kunai lancé redevient un clone près de la cible. Le joueur décide quelle branche passe par quel corps. DÉCISION de lisibilité : le **verrouillage reste sur le vrai Naruto** et sa barre de vie est la seule affichée ; la tromperie porte sur l'origine des coups, pas sur l'identité du corps (alternative « politique de perception » du [brouillon de bible](../archive/missions/legacy-v0/foundation/GAMEPLAY_BIBLE_DRAFT.md) écartée pour la v1 : coût et lisibilité).

## Fiche FIGHTER_TEMPLATE

### 1. Identité
- PROPOSÉ `Fighters.Legion` : « THE NUMBER ONE SURPRISE » (à valider), `Age = 13`, HP 140, **chakra 160** (la plus grande), regen 6.5, vitesse 18.5, sprint ×1.12, saut ×1.1, air ×1.0, accél. ×1.08, esquive ×1.05, `PreferredRange 6`, `Tool = "CloneKunai"`.
- Fantasy : le chaos lisible pour lui, illisible pour l'autre. Rôle : rushdown à corps multiples. Rythme : pression continue, débordement. Distance : 4–12.
- Forces : pression multi-angles, endurance, réserve. Faiblesse : clones fragiles (chaque coup reçu en efface un), taijutsu peu précis, chakra qui part vite, techniques lisibles (fumée d'apparition).
- Question : « Lequel est le vrai, et est-ce que ça compte ? »

### 2. Mouvement
- PROPOSÉ : stance de bagarreur (garde basse et ouverte) ; démarche énergique et imprécise `stride 1.1, cadence 1.05, arm 48, lean 7, bob 1.2, guard .05` — différente de la famille *springy* de Minato/Sasuke par le poids (bras larges, foulée lourde).
- Manteau (éveil) : locomotion à quatre appuis (H09 + H04).
- DÉCISION : pas de mouvement signature hors clones ; course murale commune.

### 3. Neutral / entrée en combat
- Fermer : sprint, Rush commun, kunai-clone (le clone apparaît près de la cible), Tajū (vague).
- Forcer une réaction : un clone « leurre » à côté de lui double chaque menace ; le kunai lancé peut être un clone.
- Sortir : substitution vers un clone ; kunai-clone vers l'arrière (disengage).
- À respecter : le nombre de clones vivants (0, 1 ou 2), la fumée d'un kunai-clone.

### 4. Taijutsu et combos
| Entrée | Move proposé | Fonction |
|---|---|---|
| L1 → L2 → L3 | **crochet** large → **direct** → L3 : **par un clone de l'autre côté** s'il en existe un (cross-up, jugé depuis le clone), sinon front kick de Naruto (Knockback) | la string commune devient un mixup de côté |
| ↑ (≥2) | **UzumakiKick** : un clone surgit sous l'adversaire et le lance (Launched 55), 2 clones éphémères le relancent (« U-ZU-MA ») ; pendant 1.2 s Naruto choisit : poursuite E puis Lourd = **Naruto Rendan** (talon, Knockdown), ou Rasengan au sol sur la chute, ou kunai-clone | **poursuite déléguée** : les clones gardent le corps en l'air, pas Naruto ; coûte un clone ou 12 chakra |
| ↓ (≥2) | **Tackle** (plongeon dans les jambes, Knockdown) | fin de string |
| ←→ (≥1) | **MirrorClone** : un clone apparaît du côté opposé et frappe en même temps que l'appui suivant | coûte un clone ; garde la string |
| Lourd après 1 coup | **Headbutt** (coup de tête, stagger 0.45) | bagarre |
| Air | Air1/Air2, AirDrive/AirSpike/AirSwitch communs, clips propres | |

### 5. Armes et ninja tools
- **R = kunai-clone** (henge) : kunai (vitesse 80, portée 50) qui, en fin de vol ou en passant à ≤ 6 studs du flanc/dos de la cible, redevient un clone et frappe (4 dégâts, HitStun). Coût 12 (c'est un clone) ; avec 2 clones déjà vivants, kunai ordinaire (4). Signe lisible : reflet orange.
- Pas de maîtrise d'outil au-delà (DÉCISION, blueprint « Basic tools »).

### 6. Jutsus / techniques
| Technique | Coût | Canal/actif/récup | CD | Effet | Contre-jeu |
|---|---|---|---|---|---|
| Kage Bunshin | 12 | .2 / — / .15 | 1.5 | un clone « leurre » à côté de lui : imite ses actions avec 0.2 s de retard (frappes en écho) | un coup quelconque le dissipe |
| Rasengan | 22 (+12 sans clone) | .35 avec clone (le clone vient le former), .6 sans (un clone apparaît) / .1 / .45 | 6 | poussée de 10 studs, 22 dégâts, Knockback 80 en vrille (splat probable) | **frapper le clone pendant la canalisation annule le Rasengan** ; pas de côté ; garde |
| Tajū (vague, plafonnée) | 30 | .3 / .4 / .4 | 10 | jusqu'à 2 clones chargent par les côtés en même temps que lui ; un coup chacun | reculer en diagonale ; un coup large (LeafWhirlwind de Lee, Rotation) les efface |

### 7. Garde / défense
- Garde/parry communs. Le clone leurre peut **absorber** un projectile (il est un corps).
- Anti-air : Headbutt/launcher communs. DÉCISION : pas de lecture.

### 8. Esquive et substitution
- Esquive commune. **Substitution « c'était un clone ! »** : s'il a un clone vivant, Naruto **échange sa place** avec lui (le corps frappé se dissipe en fumée) ; le clone est consommé. Sinon hop commun. Contre-jeu : effacer ses clones avant d'engager ; la destination est un corps visible et mobile (≠ sceau fixe de Minato).

### 9. Rush / poursuite
- Poursuite commune, plus **poursuite déléguée** (UzumakiKick) et ré-entrée par kunai-clone.
- Casser : dissiper les clones (un coup chacun), air dodge, substitution.

### 10. Chakra
- 160 / 6.5 : il dépense beaucoup (clones) et recharge lentement. **Sursaut de Kyûbi** (passif, 1×/manche) : la première fois que son chakra tombe à 0, +50 chakra et 2 s de « chakra rouge » (prochain Rasengan sans clone, canal .2). Vider sa jauge exprès est une décision.

### 11. Infusion / interactions de chakra
- `clone + coup reçu → dissipation` ; `clone + Rasengan → technique à deux corps` ; `kunai + henge → corps`. Pas de nature élémentaire (son vent est de Partie II).
- Kage Bunshin **non copiable** par Kakashi tant que H12 n'est pas généralisé.

### 12. Éveil — MANTEAU À UNE QUEUE
- Règles (12 s) : (1) **plus de clones** (un seul corps, bestial) : les routes de clones deviennent des coups de griffe (↑ griffe montante, ←→ balayage de griffe, L3 toujours par Naruto) ; (2) locomotion à quatre appuis : sprint ×1.2, saut ×1.15 (H04) ; (3) **armure de chakra** : les coups légers ne l'interrompent pas et n'infligent que 50 % (H13) ; (4) **griffe de chakra** : Lourd, route latérale et saisie +5 studs de portée ; (5) Rasengan sans clone (canal .2) ; regen 2 PV/s (guérison de Kyûbi).
- Contrepartie : pas de garde (la touche de garde devient un **rugissement** qui repousse à 6 studs, coût 10) ; à la sortie, **contrecoup** : 3 s sans regen de chakra ni clones.

### 13. États et réactions
- Crée : HitStun (clones), Launched/Juggled (UzumakiKick), Knockdown (Tackle, Rendan), Knockback (Rasengan, L3), prise aux jambes (option H10 : un clone d'assaut qui arrive dans le dos tient 0.6 s).
- Exploite : garde frontale (clones dans le dos), bouclier de Gaara (chaque coup de clone consomme une charge), adversaire occupé à dissiper.

### 14. Boucle de jeu
- Représentative : `Kage Bunshin → approche à deux → L1 L2 → L3 du clone dans le dos → ↑ UzumakiKick → E → Naruto Rendan`.
- Agressive : `kunai-clone dans le flanc → L1 L2 → ←→ MirrorClone → Rasengan (le clone forme) → splat`.
- Défensive : `combo subi → « c'était un clone ! » → Kage Bunshin → reset`.
- Low-chakra : `vider à 0 → sursaut (+50, 2 s) → Rasengan instantané`.

### 15. Skill ceiling
- Débutant : clones au hasard, Rasengan sans clone (lent, cassé).
- Intermédiaire : garde un clone pour la substitution, L3 de clone pour passer la garde, UzumakiKick → Rendan.
- Expert : écho du leurre synchronisé avec ses propres coups (deux angles au même frame), kunai-clone comme pont de distance et piège de flanc, Rasengan à clone protégé (clone placé derrière lui), gestion du sursaut, choix du moment du manteau (perdre les clones pour gagner l'armure).

### 16. Signature irremplaçable
Naruto est le seul fighter qui **multiplie les corps réels** et dont chaque route peut être jouée par un autre corps que le sien. Quatre jutsus sur ses stats en feraient un bagarreur à grosse réserve ; les clones en font une pression d'angles que personne d'autre n'a.

## Différenciation

| Axe | Naruto | Minato | Itachi | Neji | Sasuke |
|---|---|---|---|---|---|
| Neutral | 4–12, clones et kunai-clone | 6, sceaux | 10, Geometry | 5 | 6 |
| Tromperie | **corps réels** qui frappent | téléport | **leurre sans corps** (genjutsu) | — | — |
| Rasengan | **besoin d'un clone**, poussée longue | instantané après FTG (noms adultes à trancher, [MINATO](MINATO.md)) | — | — | — |
| Launcher | **poursuite déléguée** aux clones | sceau corporel | lames | paume | se poursuit lui-même |
| Substitution | échange avec un clone (mobile, destructible) | vers un sceau (fixe) | corbeau derrière | hop | hop |
| Chakra | 160, sursaut à 0 | regen 8 | 125 | drain | 105 |
| Éveil | **perd** les clones, gagne armure et portée | vitesse/CD | fenêtres | sans angle mort | stats + drain |

| Vague | Recouvrement | Ce qui les sépare |
|---|---|---|
| Lee | rushdown | Lee : un corps, élan, vitesse ; Naruto : plusieurs corps, angles |
| Kisame | grosse réserve | Naruto dépense, Kisame vole (Samehada sur le vrai Naruto le nourrit ; les clones ne rapportent rien mais l'occupent) |
| Gaara | — | les clones vident le bouclier charge par charge (canon : Naruto contre Gaara) |
| Shikamaru | — | les clones projettent des ombres (relais) ; posséder le vrai n'arrête pas un clone déjà lancé |
| Haku | — | le manteau brise les miroirs (canon) |
| Temari | — | les couloirs ralentissent les clones |
| Kakashi | clones | Kakashi n'en a pas (pas de copie avant H12) |

## Labels lore par capacité

| Capacité | Label | Source / justification |
|---|---|---|
| Kage Bunshin / Tajū | CANON_YOUNG | ch. 1 (contre Mizuki) |
| Plafond de 2 clones | GAMEPLAY_LIBERTY | lisibilité 1v1 |
| Clone dissipé en un coup | CANON_YOUNG | règle constante des clones d'ombre |
| Rendan Uzumaki (U-ZU-MA-KI) | CANON_YOUNG | préliminaires contre Kiba (ch. à vérifier) |
| L3 / route latérale par un clone | PLAUSIBLE_YOUNG | attaques de clones par derrière (finale contre Neji, à vérifier) |
| Kunai/shuriken qui redevient clone | CANON_YOUNG | Fûma shuriken transformé contre Zabuza (Pays des Vagues) |
| Rasengan formé avec un clone | CANON_YOUNG | arc de Tsunade ; il ne le forme pas seul en Partie I |
| Clone touché = Rasengan annulé | GAMEPLAY_LIBERTY | contre-jeu à deux corps |
| Substitution « c'était un clone » | CANON_YOUNG (schéma) | Neji frappe un clone en finale |
| Sursaut de Kyûbi à l'épuisement | CANON_YOUNG | finale contre Neji |
| Manteau à une queue | CANON_YOUNG | Vallée de la Fin |
| Rasengan sans clone en manteau | CANON_YOUNG (à vérifier) | Vallée de la Fin |
| Griffe/bras de chakra | PLAUSIBLE_YOUNG | même manteau à une queue, Partie II (pont du Ciel et de la Terre, à vérifier) |
| Guérison de Kyûbi | CANON_YOUNG | Pays des Vagues et suivants |
| Rugissement | PLAUSIBLE_YOUNG (à vérifier) | |
| Tunnel/attaque par en dessous | CANON_YOUNG, **hors kit** | finale contre Neji ; candidat de progression |
| Gamabunta | REJECT_ADULT_ONLY | échelle géante (DEC-013 : échelle, pas âge) |
| Quatre queues, ermite, Rasenshuriken, Kurama | REJECT_ADULT_ONLY | Partie II / endgame |
| Sexy/Harem no jutsu | non retenus | ton |

## Plan d'implémentation

**Réutilisé** : exécution de `Techniques.BurstStrike` (Rasengan qui voyage, `Server/Techniques.luau:203-232`) avec une condition « clone » ; tirs planifiés comme `coverBlades` (`Brawler.luau:309-317`) pour UzumakiKick v0 ; jugement de flanc `hitOrigin` ; `Combat:relocate` (échange de substitution) ; impacts `substitute`/`afterimage` ; cadre d'éveil.

**Nouvelles données** : `Fighters.Legion` (stats §1, `Clones={Max=2,Life=6,Cost=12,Echo=.2}`, `Surge={Refill=50,Window=2}`, `Tool="CloneKunai"`, éveil à règles) ; `MoveGraphs.Legion` (`routes={up="UzumakiKick",down="Tackle",side="MirrorClone",airUp="AirDrive",airDown="AirSpike",airSide="AirSwitch"}`, `onRoute={UzumakiKick="uzumaki",MirrorClone="mirrorClone"}`, `heavyAfterOne="Headbutt"`, `stringCancels={RasenganClone=true}`, `disengage="CloneKunai"`) ; `Attacks` : `Hook`, `Straight`, `CloneKick`, `UzumakiKick`, `NarutoRendan`, `Tackle`, `MirrorClone`, `Headbutt`, `ClawSwipe` ; `Techniques` : `ShadowClone`, `RasenganClone`, `MassClones` ; IA : garder 1 clone pour la substitution, L3 de clone, Rasengan si un clone est proche et la cible en récupération, manteau quand les clones ne suffisent plus ; **côté adversaire** : dissiper les clones proches.

**Hooks** : H12 (v0 : clones éphémères visuels et coups planifiés pour UzumakiKick ; v1 : clones touchables à comportements, routage des coups et projectiles, liste `entities` du snapshot, rendu client), H05 (sursaut), H09 (manteau), H13 (armure du manteau), H04 (vitesse du manteau), H10 (option : tenue aux jambes), H17 (substitution d'échange avec un clone, `disengage` kunai-clone), H02, H03, H01.

**Motion** : stance, démarche, intro (pouce et sourire, pas de pose adulte) ; clips propres : Hook, Straight, CloneKick (exécuté par le clone), UzumakiKick (clones), NarutoRendan, Tackle, MirrorClone, Headbutt, Air1/Air2, routes aériennes, Grab/Throw, Riposte ; poses : signe du clone, Rasengan à deux corps (Naruto + clone qui façonne), Tajū ; jeu de locomotion du manteau (course à quatre appuis, saut, griffe, rugissement) ; le **clone réutilise le rig et le costume de Naruto** (`World.dress`, fonction à créer).

**Effets/UI** : fumée d'apparition/dissipation, compteur de clones (0–2) dans le HUD de Naruto seulement, Rasengan bleu à deux mains, manteau rouge-orangé à une queue, éclair rouge du sursaut.

**Tests** (`tests/Naruto.spec.luau`) : limite et durée des clones, dissipation en un coup ; coup de clone jugé depuis le clone (garde frontale contournée) ; Rasengan annulé si le clone est touché ; UzumakiKick (jonglage délégué) ; substitution d'échange ; sursaut 1×/manche ; manteau : pas de clone, armure sur les légers, portée de griffe ; **nettoyage des entités** (fin de manche, KO, substitution, sélection) ; projectiles qui touchent un clone ; duels IA contre les 12. Test sans jutsu : DÉCISION, sa signature **est** un jutsu (comme le Sharingan d'Itachi) ; sans technique il reste reconnaissable par son corps (bagarre, tacle, coup de tête) et le kunai-clone (outil) — à confirmer en natif.

**Effort** : **L** (H12 est le hook le plus lourd de la vague).

**Périmètre minimal jouable** : string + L3 de clone, Kage Bunshin (clone touchable, modes leurre/assaut), kunai-clone, Rasengan à clone, substitution d'échange, UzumakiKick v0. Hors minimal : Tajū, sursaut, manteau (armure, griffe, rugissement), tenue aux jambes, tunnel.

## Points à vérifier
- Chapitres : Rendan contre Kiba, Fûma shuriken transformé, Rasengan seul en manteau, griffe de chakra.
- Coût réseau de 2 corps supplémentaires (NET-001) et lisibilité caméra (CAM-001) ; budget de parties/clients (PERF-001).
- Décision utilisateur sur le Rasengan : canon pour Naruto, adulte pour Minato en l'état ([MINATO](MINATO.md), labels).

## État d'implémentation (2026-10-17, convergence 3, plusieurs corps)

Code de `claude/nd-vrs-naruto`. Rapport, constats moteur et liste Studio : [NARUTO (convergence 3)](../reports/convergence3/NARUTO.md). **Validé en headless uniquement** (`tests/Naruto.spec.luau`, 33 cas) : le rendu des clones, les fumées, le feel et l'équilibre restent à juger dans Studio. L'identifiant de code est **`Legion`**, comme proposé.

**Implémenté et jouable (sélectionnable dans le roster)**
- Corps supplémentaires génériques (H12 v1) : `Server/Bodies` (clones touchables, contrôleurs, coups jugés depuis le clone, frappes et lames adverses qui les dissipent, liste `bodies` du snapshot) et `Client/BodyViews` (copie posée du modèle de Naruto). Verrouillage, cible de l'IA et caméra restent sur le vrai Naruto.
- Clone d'ombre (12, 2 au plus, 6 s, un coup) : à côté de lui loin de l'adversaire, sur un flanc près de lui (un direct quand l'adversaire est ouvert, jugé depuis le flanc).
- Routes : 3e coup par un clone dehors depuis le dos ; ←→ frappe de flanc par un clone (payé 12 sans clone dehors) qui garde la string ; ↑ (et lourd après deux coups) **Rendan Uzumaki** puis E et lourd = **NARUTO UZUMAKI RENDAN** ; ↓ tacle ; lourd après un coup = coup de tête.
- Rasengan à deux corps (22, +12 et canal 0,6 sans clone dehors) : frapper le clone qui le façonne l'annule. Multi clone d'ombre (30, deux clones qui chargent).
- Outil : kunai ; Z + R = kunai transformé en clone près de la cible (profil chakra `ShadowClone`). Substitution « c'était un clone ! » (échange avec un clone).
- Éveil **CHAKRA DE KYÛBI** : plus aucun clone, griffes (↑ / ←→), Rasengan sans clone en 0,2 s, récupérations ×0,78, vitesse ×1,15.
- Relance « legion » au côté irrégulier, tenaille d'un clone de flanc ; IA (clones, Rasengan, Rendan, kunai transformé) ; toute IA frappe un clone qui arme son coup à côté d'elle.
- Client : posture, démarche, string et clips à lui (clips des clones compris), couche `NarutoFX`, costume Partie I, compteur de clones sur la plaque.

**Fondation seulement / non implémenté**
- Sursaut de chakra à 0 (H05), rugissement et armure du manteau (H13), locomotion à quatre appuis, tenue aux jambes (H10), tunnel, écho des frappes par le clone leurre, kunai qui redevient un clone sur un clone déjà dehors.
