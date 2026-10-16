# Minato — jeune prodige

Code : `Flashstep`. IDs : CHR-MIN-001/002/003, CHR-CORE-001/002. Les données réelles viennent de Fighters/MoveGraphs/Attacks et [inventaire](../current/COMBAT_INVENTORY.json) ; le label lore n’est pas automatiquement prouvé par le nom du move.

## Expression visée

Vif, peu de gestes superflus, changement d’angle. Kunai physiquement tenu/lancé ; marques persistantes distinctes sur corps/surface/en vol, entrée/sortie FTG lisibles. Le transfert de poids précède la vitesse ; pas un corps immobile qui teleport spam. Costume jeune, pas haori Hokage.

## Conversions à rechercher, pas à ajouter aveuglément

PreparedAnchor→SideSwitch→ShortPunish ; lancer en mouvement→marque en vol→conversion ; launch→FTG chase→sortie. Candidats à comparer aux routes déjà présentes, pas nouvelles obligations de kit.

Pour chaque exemple : source/âge/scene/timecode, label lore, état initial/contact/réaction/résultat/followup, brique commune et expression spécifique, input/camera/air/wall/risque. Vérifier d’abord si le code satisfait déjà l’intention. Lire le blueprint complet dans [ROSTER_MOVESETS_10_PRODIGIES](ROSTER_MOVESETS_10_PRODIGIES.md) et les passages propres à Minato dans [CLAUDE_FINAL_PASS](../archive/missions/CLAUDE_FINAL_PASS.md).

## Validation

Baseline native + garde/course/strafe/dash/jump, contact/defense/throw/outil/jutsu/air/mur/KO ; duel contre les quatre IA et manette. Même scénario avant/après ; motion/export sélectionné par Claude, contrats/costs/timings protégés. Reconnaissance de Minato sans jutsu ; vérifier jeunesse et contre-jeu. Un headless PASS technique ne clôt pas cette identité visuelle.

## Fiche FIGHTER_TEMPLATE — audit 2026-10-16

> Audit Claude du 2026-10-16 (CHR-CORE-001/002, bloc 4 du plan approuvé le 2026-10-14). Décrit le code réel de `claude/ninja-duel-2026-10-14` ; les références `fichier:ligne` ont pu glisser avec les correctifs du bloc 3 (`f93d866`) — le nom de fonction fait foi. Les sources canon marquées « à vérifier » ne sont pas confirmées. Les propositions sont des candidates, non implémentées ; les labels REJECT_ADULT_ONLY signalent un écart code ↔ décision DEC-005 à trancher, pas un changement fait.

IDs : CHR-MIN-001 (DONE technique), CHR-MIN-002/003, CHR-CORE-001/002, SYS-003, TOOL-002/005. Fiche rédigée à partir du code réel, sans modification du dépôt. Convention : **EXISTE** = ce que fait le code (`fichier:ligne`, valeurs réelles) ; **MANQUE** = écart au gabarit ; **DÉCISION** = absence volontaire argumentée. Chemins relatifs à `games/ninja-duel/src/`. Timings d'attaque = valeur `Attacks` × `AttackProfile` Minato (startup/active/recovery en s).

### Fiche moveset

#### 1. Identité
- **EXISTE** : `Shared/Fighters.luau:3-8` — Minato Namikaze, `Age = 13`, « THE FAST PRODIGY », « Decision speed. Kunai placement, angle changes and an unfinished teleport seal ». HP 125, chakra 110, regen 8/s, vitesse 19.5, `PreferredRange = 6`, `Tool = "Kunai"`.
- Stade jeune retenu : pic prodige **pré-guerre (~genin/chûnin, 13 ans)**, avant le titre d'« Éclair jaune » et avant l'usage montré du Hiraishin/Rasengan (acquis d'adulte, voir table lore).
- Fantasy : le gamin qui décide plus vite que l'autre ; il prépare l'espace avec des kunai scellés puis l'exploite par des angles. Rôle : skirmisher mobile / setup-punisher. Rythme : bursts courts, peu de gestes. Distance : 6 au contact, 8–66 pour poser des sceaux.
- Forces : mobilité (vitesse de marche la plus haute du noyau), outil le plus rapide, relocation sur sceau, substitution vers sceau. Faiblesse : 125 HP, techniques fortes conditionnées par des sceaux qui expirent et par le chakra ; téléport lisible par le Sharingan, techniques coupées par 64 Palms.
- Question de gameplay : « pouvez-vous couvrir tous les endroits où je peux réapparaître ? »
- **MANQUE** : `GuardStrength = 0.10` et `CombatStyle = "Angles"` (`Fighters.luau:7-8`) ne sont lus nulle part dans `src` (champs morts). Labels lore : table dédiée plus bas (CHR-CORE-002 reste PARTIAL).

#### 2. Mouvement
- **EXISTE** : stance basse et enroulée, kunai main droite en prise inversée, main avant ouverte, `tempo = 7.5` (`Client/VelmoraMotionEngine.luau:245-247`). Gait `stride 1.12, cadence .98, arm 50, bob 1.15, guard 0` (`:1059`) — famille « springy » partagée avec Sasuke (`:263`).
- Course/sprint : marche 19.5 ; sprint 45 × 1.12 = 50.4 (`Shared/Config.luau:39`, `Server/Place1Movement.luau:8`) ; accélération sol 170 × 1.15 ; saut vertical 58 × 1.1 = 63.8 ; contrôle aérien 76 × 1.15 (`Place1Movement.luau:9,16`).
- Dash/esquive : 14 × `DashScale 1.15` = 16.1 studs en 0.32 s (`Server/BanglaEvade.luau:7`), coût 10, cd 0.8 (`Config.luau:8`) ; une esquive aérienne.
- Dérive d'angle propre : pendant Light1/2/3, DashAttack, Air1/2, `spec.angle` (±.18 à .36) fait glisser Minato tangentiellement à 7 studs/s au sol, 9 en l'air (`Server/Combat.luau:970-971`).
- Mouvement signature : FTG (§6), Quickstep 11 studs (`Server/Techniques.luau:291`), AngleStep en orbite (§4).
- **MANQUE** : strafe/latéral et changement de direction = règle commune `faceLocked` (`Combat.luau:348-377`), sans interprétation Minato ; wall-run commun (`Config.luau:33-37`). Course jugée N (MOV-001/002/003).

#### 3. Neutral / entrée en combat
- Fermer : Rush (E hors poursuite) coût 10, 90 studs/s, portée 7–48, cd 0.9, arrivée → DashAttack (`Config.luau:20`, `Combat.luau:452-471`) ; course pleine → FlyingKick/SlideSweep (`Server/Brawler.luau:204-209`) ; FTG sur un sceau proche de la cible.
- Poke : kunai standard 1 lame, vitesse 96, dégâts 3, récupération 0.55 s, coût 4, portée 62 (`Fighters.luau:11`, `Combat.luau:635-654`).
- Forcer une réaction : Marked Kunai lancé en courant (le sceau menace un téléport à côté) ; un kunai en vol qui passe à < 7 studs de la cible = menace d'apparition latérale.
- Feinte/lecture : feinte de Heavy commune (`Combat.luau:557-561`) ; Quickstep « no guaranteed hit ».
- Sortir : disengage (arrière + outil dans une string) = saut 5 studs à 46/s, récupération 0.26, 1 kunai (96, portée 22, dmg 2) (`Brawler.luau:105-118`) ; FTG vers un sceau planté loin.
- À respecter : chaque sceau visible (2 au sol, 1 corporel, 1 en vol) est une destination possible.
- **MANQUE** : le zigzag latéral « Minato » n'existe que dans l'IA (`Server/AI.luau:100`), pas comme outil joueur.

#### 4. Taijutsu et combos
- **EXISTE** (graphe `Shared/MoveGraphs.luau:20-30`) :
  - Neutral : Light1 (kunai revers, .074/.12/.25, 5 dmg) → Light2 (.084/.12/.24, 10) → Light3 (roundhouse, .098/.14/.21, 18, Knockback, impulseZ 52) (`Shared/Attacks.luau:9-11`, `Fighters.luau:15-16`).
  - `up` (≥2 coups) : Launcher .122/.14/.28, 8 dmg, Launched, impulseY 62 + **sceau corporel 1.8 s** (`Brawler.luau:290-294`).
  - `down` (≥2) : Sweep .12/.14/.34, 7 dmg, Knockdown + **sceau au sol** planté (`Brawler.luau:295-298`).
  - `side` (≥1) : AngleStep .08/.10/.20, 6 dmg, orbite 17, garde la string (`Attacks.luau:23,63,103`).
  - Heavy après 1 coup : KneeStrike .08/.12/.30, 7, Juggled (`Attacks.luau:35`) ; Heavy après ≥2 : Launcher (`Brawler.luau:230-233`).
  - Air : Air1/Air2 puis AirDrive (pousse, Knockback) / AirSpike (Spiked → rebond sol) / AirSwitch (orbite 40 + éclair « quickstep ») (`Attacks.luau:51-53,111`, `Brawler.luau:81-84,237-249`).
  - Cancel : string confirmée → Rasengan canal 0.14 au lieu de 0.30 (`Combat.luau:663-666,726`) ; arrivée FTG → frappe/Launcher/Slam/Rasengan (`Brawler.luau:168-184`).
  - Side-switch : FTG à côté de la cible, côté choisi au stick, sinon côté opposé au départ (`Techniques.luau:160-171`).
- **MANQUE** : grab/throw communs, aucun grab identitaire ; pas de wall route propre (WallDive commun, clip Minato `VelmoraMotionEngine.luau:521`) ; pas de finisher dédié hors Rasengan.
- **Anomalie à vérifier** : le clip `Flashstep.Heavy` (`VelmoraMotionEngine.luau:298-303`) prend au contact une pose bras levés à 160° construite sur la stance d'Itachi (`i(...)`, `K(3,I)`), en contradiction avec son commentaire « straight right ».

#### 5. Armes et ninja tools
- **EXISTE** : kunai seul (`Count 1, Speed 96, Damage 3, Recover .55`), récupération la plus courte du noyau ; outil gratuit après une string confirmée (portée 20, récupération 0.42) (`Combat.luau:612-638`). Le lancer laisse le corps en Neutral (`Combat.luau:318-326`).
- Kunai marqué : projectile « marked », vitesse 82, portée 66, 6 dmg (`Techniques.luau:136-145`) ; au corps → sceau 5 s, en surface → sceau 12 s (décalé de 3 studs hors du mur/sol), en fin de vol → tombe et plante, sur garde → tombe aux pieds du garde (`Techniques.luau:88-121`, `Combat.luau:1104-1111,1183-1192`). Max 2 sceaux plantés, le plus ancien est remplacé (`Techniques.luau:9,103-109`).
- Corps épinglé au mur + kunai → pin 0.34 s (`Combat.luau:1099-1101`). Prise inversée visible sur Light1/2, DashAttack, Air1, AngleStep, Riposte, AirSwitch (`VelmoraMotionEngine.luau:1526`).
- **DÉCISION** : pas de shuriken (identité kunai unique). Wire/smoke/tags volontairement absents (Sasuke/TOOL-004 DEFERRED).
- **MANQUE** : pas de collision projectile-projectile (DEF-005) ; pas de ramassage/rappel du kunai planté (TOOL-002) ; transitions draw/grip/release à juger (TOOL-005).

#### 6. Jutsus / techniques (`Fighters.luau:23-27`)
| Technique | Fonction | Coût | Canal/actif/récup. | CD | Portée | Mouvement | Contre-jeu | Conversions |
|---|---|---|---|---|---|---|---|---|
| MarkedBlade « Marked Kunai » | poser un sceau à distance | 10 | .12 (lâcher)/.02/0 | 2.2 | 66 | course libre (`Mobile`, `Combat.luau:741-756`) | garde (sceau aux pieds), esquive, Rotation | sceau corps/surface/vol → FTG |
| Flashstep « Flying Thunder God » | relocation sur sceau | 16 | .06/.04/.20, annulable 0.55 s | 1.5 | 90 | vitesse 7 pendant le canal | interruption ; garde Sharingan suit < 0.7 s (`Combat.luau:164-170`) ; Byakugan couvre les flancs ; 64 Palms bloque les techniques 3.5 s (`Combat.luau:720`) ; arrivée bloquée par décor | Attack → Light1/DashAttack/Air1, Heavy → Launcher/Slam, Rasengan canal .05 |
| BurstStrike « Rasengan » | finisher/punish | 24 | .30 (.14 string, .05 FTG, ≤.12 air)/.08/.50 | 5.5 | 8 (avance 10) | vitesse 7 pendant le canal | interruptible ; Read d'Itachi ; garde | sol : 20 dmg, Knockback (0,22,70) ; air : 18 dmg, Knockdown ; compte comme « heavy » au mur → wall bounce (`Brawler.luau:381`) |
| Quickstep | créer un angle | 12 | .11/.08/.21 | 2.3 | 12 (déplacement 11) | déplacement imposé | aucun coup garanti ; « ANGLE BLOCKED » | aucune route codée |
| WindCut « Wind Cut » | couloir de déplacement | 18 | .32/.10/.34 | 3.7 | 36 (vitesse 88, rayon 1.4, 7 dmg) | vitesse 7 pendant le canal | pas de côté (`Server/Elements.luau:7`) | pousse la cible (37 + 14 vers le haut, `Combat.luau:1089-1090`), sans route |

- Sélection du sceau : kunai en vol toujours prioritaire, sinon direction du stick (dot > 0.3), sinon sceau le plus proche de l'adversaire (`Techniques.luau:33-53`). Sceau consommé à l'usage (`:193`).
- **MANQUE** : Quickstep et WindCut font doublon avec AngleStep et le kunai, sans conversion propre (risque « 5 boutons »). « Flash Counter » du blueprint absent (candidat, P4).
- **DÉCISION** : la « Seal Network control action » du blueprint est volontairement absente, parce qu'un réseau de sceaux contrôlable relève du Hiraishin adulte.

#### 7. Garde / défense
- **EXISTE (commun)** : parry 0.20 s (coût stamina 16, cd 0.6, stun attaquant 0.5) ; blocage ×0.24 ; perfect dodge 0.13 → riposte 0.5 s (`Server/VelmoraDefense.luau:16-48`, `Shared/VelmoraCombatConfig.luau:4-11`) ; riposte après blocage 0.34 s (`Brawler.luau:483`) ; clash commun (`Brawler.luau:397-421`).
- **DÉCISION** : la défense de Minato passe volontairement par le déplacement (dodge, substitution vers un sceau) plutôt que par une garde propre, parce que c'est cohérent avec son rôle de skirmisher.
- **MANQUE** : aucune interprétation de garde, d'anti-air ou de défense au mur (le champ `GuardStrength` est mort) ; pas de lecture ni de contre propre (matrice : « pas de Read spécifique »).

#### 8. Esquive et substitution
- **EXISTE** : esquive commune (§2, i-frames 0.22, `Config.luau:8`). Kawarimi : coût 15, 2 charges, recharge 9 s, cd 1.1, fenêtre 0.42 s après un coup, 8 studs, poursuite adverse 0.75 s (`Config.luau:14`, `Combat.luau:383-446`).
- Twist Minato : réapparition sur le sceau planté le plus éloigné de l'attaquant (≤ 70 studs de Minato, > 9 de l'attaquant), sceau consommé ; les sceaux corporels et en vol sont exclus (`Techniques.luau:124-135`, `Combat.luau:394-396,432`).
- Bait/punish : l'attaquant voit « SUBSTITUTION • E TO TRACK » ; un sceau visible révèle la destination.
- **MANQUE** : pas de perfect dodge propre à Minato.

#### 9. Rush / poursuite
- **EXISTE** : Rush commun (§3). Poursuite : coût 8, portée 46 (`Config.luau:10`) ; fenêtre 1.15 s après un launch (`Brawler.luau:509`), 0.8 s après un knock-away. Variante Minato : Launcher → sceau corporel 1.8 s → FTG à hauteur de la cible (arrivée en l'air, `Techniques.luau:170,191`) → Air1/Slam/RasenganDrop. Le kunai en vol sert de poursuite outillée.
- Casser la poursuite : substitution, wall tech (12 chakra, `Combat.luau:503-531`), Sharingan (suivi du téléport), Rotation.
- **MANQUE** : pas de « sortie » codée après une poursuite FTG aérienne (candidat P5).

#### 10. Chakra
- **EXISTE** : réserve 110, regen 8/s (la plus rapide du noyau), suspendue pendant les canaux et le stun (`Combat.luau:786-792`). Coût d'un cycle sceau + saut = 26 ; substitution 15 ; esquive 10 ; garde à 0 chakra sous un coup → GuardStun (`Brawler.luau:487`).
- **MANQUE** : pas d'état low-chakra (seulement des refus « Need chakra ») ; pas de spécialité au-delà de la regen (SYS-001).

#### 11. Infusion / interactions de chakra
- **EXISTE** : `Kunai + sceau + (contact corps | surface | vol | fin de vol | garde) → destination de téléport` — c'est l'infusion signature de Minato. Vent uniquement via WindCut.
- **DÉCISION** : pas d'infusion vent sur kunai ni de nature sur le Rasengan, parce que TOOL-006 est OPEN et qu'aucune source jeune ne le justifie.

#### 12. Éveil
- **EXISTE** : « YELLOW FLASH », une fois par match sous 35 % HP, 12 s ; +40 chakra, cooldowns remis à zéro, invulnérable 0.45 s, repousse à moins de 9 studs (`Combat.luau:474-495`). Vitesse ×1.18, dégâts ×1.05, regen ×1.5, cooldowns ×0.4 (FTG 0.6 s) (`Fighters.luau:13`, `Combat.luau:497-502`).
- **MANQUE** : uniquement des multiplicateurs, aucune règle nouvelle (contraire au gabarit et à SYS-003) ; le nom est un titre de guerre adulte (table lore) ; pas de contrepartie.

#### 13. États et réactions
- Crée : Launched (Launcher), Juggled (KneeStrike, AirSwitch), Knockdown (Sweep, Slam, RasenganDrop), Knockback (Light3, AirDrive, Rasengan → wall splat), Spiked (AirSpike → rebond), wall bounce (Rasengan sur un corps épinglé).
- Exploite : corps lancé (sceau + FTG), corps épinglé (pin au kunai), recovery adverse (l'IA cible Rasengan sur Recovery/Stunned, `AI.luau:257`).
- **MANQUE** : pas d'OffBalance ni de GuardOpen (matrice) ; **DÉCISION** : pas de perturbation de chakra, réservée à Neji.

#### 14. Boucle de jeu
- Représentative : `kunai marqué en course → sceau planté → poke kunai → Light1-Light2 (dérive d'angle) → ↑ Launcher (sceau corps 1.8 s) → FTG côté choisi → Air1 → AirSpike → rebond → Sweep (sceau au sol) → disengage`.
- Agressive : `Rush → DashAttack → Light1 → AngleStep → Light → ↑ Launcher → FTG au corps → Air1 → AirSwitch → RasenganDrop`.
- Défensive : `garder un sceau loin (> 9 studs de l'adversaire) → encaisser → substitution vers le sceau → Marked Kunai à distance → FTG en vol sur la poursuite adverse (fenêtre 0.75 s)`.
- Low-chakra (< 16) : `plus de FTG → kunai à 4 + AngleStep/outil gratuit en string → réserver 15 pour la substitution → regen ~2 s → reprendre`.
- Mur/air : `Marked Kunai dans un mur (sceau décalé de 3 studs) → FTG = arrivée en l'air → Air1/RasenganDrop` ; `Light3/Rasengan → wall splat → Rasengan = wall bounce → E poursuite`.

#### 15. Skill ceiling
- Débutant : string → ↑ Launcher → E ; Marked Kunai puis FTG sur le sceau par défaut.
- Intermédiaire : stick = choix du sceau et du côté ; frappe dans la fenêtre d'arrivée de 0.55 s ; Sweep et kunai pour préparer ; disengage.
- Expert : téléport sur kunai en vol au passage près de la cible ; gestion de la limite de 2 sceaux (le plus ancien est remplacé) avec un sceau de fuite réservé ; mixup de côté contre le suivi Sharingan de 0.7 s ; évite Rotation et 64 Palms ; budget de 26 chakra par cycle ; wall bounce au Rasengan. Le plafond repose sur position + timing + lecture, pas sur des inputs longs.

#### 16. Signature irremplaçable
Minato est le seul fighter dont l'action **laisse un état spatial persistant** (jusqu'à 4 destinations : 2 sceaux plantés de 12 s, 1 corporel de 5 s ou 1.8 s, 1 kunai en vol) que le stick transforme en attaque (à côté, côté choisi), en défense (substitution vers un sceau) ou en poursuite (sceau du Launcher). Le système traverse taijutsu (`onRoute`), outil, technique, défense, IA et VFX : quatre autres jutsus sur les mêmes stats ne le reproduiraient pas. Réserve honnête : la signature repose aujourd'hui sur des noms et visuels adultes (FTG, kunai à trois branches, Rasengan, Yellow Flash) ; elle doit tenir sous un cadrage « prototype jeune » (P1).

### Exigence de différenciation
| Axe | Minato | Itachi (`Mirage`) | Neji (`GentleFist`) | Sasuke (`Lion`) |
|---|---|---|---|---|
| Neutral | poke kunai 0.55 s + pose de sceaux, portée 6 | shuriken ×2, Geometry, portée 10 | paumes, portée 5, kunai secondaire 0.85 | shuriken ×2 0.6, pression, portée 6 |
| Mouvement | 19.5 / sprint ×1.12, dérive d'angle, springy | 18 / ×1.0, contrôlé, garde 0.35 | 18.5, pas courts, garde 0.8 | 19, saut ×1.15, springy (**même famille**) |
| Silhouette | kunai revers, palm/kick | paumes économiques | Juken bas | coups de pied ; **clips air/projection/genou hérités de Minato** (`VelmoraMotionEngine.luau:731`) |
| Launcher | coup de pied montant + sceau corporel | paume + lames de couverture | paume sous le menton | LionKick + Shadow Leaf auto |
| Poursuite | E ou FTG sur le corps | E commun | E commun | Shadow Leaf gratuit → Lion Combo |
| Mur | sceau mural, pin au kunai, bounce au Rasengan | ricochet, pin aux lames | Vacuum Palm vers le mur | commun + wire |
| Air | AirSwitch éclair, RasenganDrop, FTG en l'air | éventail de 3 lames | routes communes | Lion Barrage |
| Outils | 1 kunai + kunai marqué | Geometry, ricochet | kunai standard | wire → Dragon Flame |
| Chakra | regen 8, cycle sceau 26 | coût ×0.6 à l'éveil | draine le chakra adverse | Chidori 34 |
| Défense | mobilité + substitution vers un sceau | fenêtres Sharingan, Read, corbeau | Byakugan, Rotation | Sharingan 2 tomoe |
| Éveil | stats + cd ×0.4 | fenêtres ×1.5 | sans angle mort, drain ×1.8 | stats + perte de HP |
| Règle détournée | relocation choisie sur sceaux persistants | redirection de projectiles, leurres | scelle les tenketsu et les techniques | conversion wire → feu |

Risques : Sasuke partage la famille de gait de Minato et hérite de ses clips (CHR-CORE-001) ; l'éveil de Minato reste le moins « règle » des quatre.

### Labels lore par capacité
| Capacité (code) | Label | Justification / source canon |
|---|---|---|
| Vitesse/agilité (`Fighters.luau:6-7`) | PLAUSIBLE_YOUNG | Minato enfant retrouve et sauve Kushina seul (flashback de Kushina, Shippuden, ch. ~498, n° à vérifier) ; la réputation de vitesse est surtout adulte (Kakashi Gaiden). |
| Kunai standard, disengage, chain tool | CANON_YOUNG | Équipement générique de tout genin (Partie I) ; pas spécifique à Minato. |
| String en kunai revers, AngleStep, dérive d'angle | PLAUSIBLE_YOUNG | Minato adulte combat au kunai (Kakashi Gaiden ch. 239–244) ; version jeune sans jutsu, déduite de l'identité vitesse/angle. |
| KneeStrike, Sweep, Launcher, routes aériennes, Rush, poursuite | GAMEPLAY_LIBERTY | Grammaire commune ; coût : string confirmée, chakra, contre-jeux communs. |
| Kawarimi commun | CANON_YOUNG | Technique de base de l'Académie (générique). |
| Substitution vers un sceau | GAMEPLAY_LIBERTY | Dérivée du sceau ; coût 15 + sceau consommé ; destination lisible. |
| Kunai marqué (kunai + étiquette de sceau) | PLAUSIBLE_YOUNG | Élève de Jiraiya, maître du fûinjutsu (flashbacks, arc Pain, ch. à vérifier) ; sceau rudimentaire limité (12 s, 2 maximum). |
| Mesh « three-pronged kunai » (`Client/Effects.luau:139,706`, `VelmoraMotionEngine.luau:1522-1523`) | REJECT_ADULT_ONLY | Kunai de guerre de Minato jônin (Kakashi Gaiden, offert à Kakashi à 13 ans) ; à remplacer par un kunai standard + étiquette. |
| Sceau corporel (Launcher 1.8 s, kunai 5 s) | GAMEPLAY_LIBERTY | Le marquage au contact est adulte (nuit de l'attaque de Kyûbi, ch. ~501–503, à vérifier) ; ici court, unique, sans réseau. |
| Sceau au sol / en fin de vol | GAMEPLAY_LIBERTY | Mise en place de sceaux ; expiration et limite de 2 comme coût. |
| Téléport vers un sceau (mécanique `Techniques.luau:146-202`) | GAMEPLAY_LIBERTY | Cadrée « unfinished teleport seal » (`Fighters.luau:5`) ; coût 16, cd 1.5, sceau requis et consommé, suivi Sharingan, interruption. Aucune preuve canonique connue d'un usage genin. |
| Nom/cue « Flying Thunder God » (`Fighters.luau:24`, `Techniques.luau:200`) | REJECT_ADULT_ONLY | Hiraishin inventé par Tobirama (ch. à vérifier), maîtrisé par Minato adulte en guerre (Kakashi Gaiden ch. 239–244 ; anime Shippuden 119–120). |
| Téléport sur kunai en vol | GAMEPLAY_LIBERTY | Extension du prototype ; contre : garde, couper la trajectoire. |
| Rasengan au sol (`BurstStrike`) | REJECT_ADULT_ONLY (en l'état) | Créé par Minato en ~3 ans de développement (Jiraiya à Naruto, arc Recherche de Tsunade, ch. à vérifier) ; usage montré adulte. Requalifiable GAMEPLAY_LIBERTY en « rotation inachevée » (P1). |
| FlashRasengan (FTG → Rasengan) / RasenganDrop | REJECT_ADULT_ONLY (en l'état) | Combo signature adulte (nuit de Kyûbi, à vérifier) ; à requalifier avec le Rasengan. |
| Quickstep | PLAUSIBLE_YOUNG | Équivalent du Shunshin, technique générique de chûnin/jônin ; âge d'acquisition de Minato à vérifier. |
| Wind Cut | GAMEPLAY_LIBERTY | Aucune technique Vent du jeune Minato montrée ; affinité Vent selon les databooks à vérifier ; contre : pas de côté. |
| Éveil « YELLOW FLASH » (nom) | REJECT_ADULT_ONLY | Titre de guerre (Iwa ordonne de fuir à vue, Kakashi Gaiden) ; Minato adulte. |
| Éveil (effets numériques) | GAMEPLAY_LIBERTY | « Pic de concentration » acceptable s'il est renommé et doté d'une règle (P2). |

### Propositions (candidates, non implémentées)
1. **P1 — Recadrage jeune des noms et visuels** (CHR-CORE-002, CHR-MIN-002) : « Sceau de translation (prototype) » au lieu de « Flying Thunder God », kunai standard + étiquette, éveil renommé (« Flow »), Rasengan présenté comme rotation inachevée. Mécanique et contre-jeu inchangés. Label : GAMEPLAY_LIBERTY (supprime trois REJECT_ADULT_ONLY).
2. **P2 — Éveil à règle** (SYS-003) : pendant 12 s, un coup confirmé après une arrivée FTG replace un sceau corporel de 1.8 s (une boucle relancée par un toucher, 16 chakra par saut). Contre : garde/parry coupe la boucle, suivi Sharingan, Rotation ; une fois par match. Label : GAMEPLAY_LIBERTY.
3. **P3 — Ramasser son kunai planté** (TOOL-002) : passer sur son propre sceau le récupère (rembourse 5 chakra, retire le sceau). « La course crée la géométrie. » Contre : l'adversaire peut occuper ou couvrir la zone. Label : PLAUSIBLE_YOUNG (récupérer ses kunai est générique).
4. **P4 — Déviation au kunai revers** (CHR-MIN-003, DEF-003) : parry à fenêtre commune de 0.20 s qui dévie aussi kunai et shuriken, mais pas le feu, le vent ni les paumes. Contre : timing strict, volumes de jutsu. Label : PLAUSIBLE_YOUNG (parer au kunai est une compétence de genin).
5. **P5 — Sortie après poursuite FTG** (CHR-MIN-003, TOOL-005) : outil pendant la fenêtre d'arrivée aérienne = kunai lancé vers le bas qui plante un sceau au sol (atterrissage/fuite). Contre : coûte un lancer (4), sceau visible, Sharingan. Label : GAMEPLAY_LIBERTY.

Points à vérifier : numéros de chapitres/épisodes cités (sauf Kakashi Gaiden), âge canon de Minato genin/chûnin, affinités de chakra databook, possible copier-coller dans le clip `Flashstep.Heavy`, hint MarkedBlade « Two seals planted at once » alors qu'un lancer plante un seul sceau (2 au maximum détenus), absence de `tests/Minato.spec.luau` (couverture répartie entre Branches, Phase4, Tools et Preparation).

### État — convergence 2 (identité, 2026-10-16)

Code de `claude/nd-ccc2-identity` ; détails, tests et poses demandées : [IDENTITY_JUTSU](../reports/convergence2/IDENTITY_JUTSU.md). Validé en headless uniquement.

- **Wind Cut refondu (même slot)** :
  - lancé en courant ;
  - coupe les lames ennemies dans son couloir ;
  - un corps coupé est rejeté de côté avec un sceau de vent de 1,6 s, et le FTG atterrit à côté ;
  - la garde ne reçoit pas de sceau ;
  - 14 chakra, CD 3,2 s.
- **Yellow Flash = règles** :
  - chaque FTG laisse un sceau au point de départ (sillage) ;
  - un corps lancé, éjecté ou plaqué au mur est une destination sans sceau (poursuite éclair) ;
  - l'arrivée dure 0,8 s ;
  - bonus de dégâts retiré.
- FTG et Quickstep cèdent la fin de leur récupération à une garde ou une esquive.
- **MANQUE toujours** : pose de revers pour Wind Cut, arrivée aérienne dédiée, jugement Studio sur le bruit visuel des sceaux.

Sources code lues : `src/Shared/Fighters.luau`, `src/Shared/MoveGraphs.luau`, `src/Shared/Attacks.luau`, `src/Shared/Config.luau`, `src/Shared/Rules.luau`, `src/Shared/VelmoraCombatConfig.luau`, `src/Shared/BanglaCombo.luau` (dégâts), `src/Server/Techniques.luau`, `src/Server/Brawler.luau`, `src/Server/Combat.luau`, `src/Server/AI.luau`, `src/Server/Elements.luau`, `src/Server/VelmoraDefense.luau`, `src/Server/BanglaEvade.luau`, `src/Server/Place1Movement.luau` (en-tête), `src/Server/Motor.luau` (vitesse de canal), `src/Client/VelmoraMotionEngine.luau` (STANCE/GAIT/CLIPS/castSpec/MELEE Flashstep), `src/Client/Effects.luau` (kunai marqué/téléport, extraits) ; docs : FIGHTER_TEMPLATE, MINATO, CORE_ROSTER, DECISIONS, FOUR_CHARACTER_COMBAT_MATRIX, ROSTER_MOVESETS_10_PRODIGIES (§1 Minato), MASTER_BACKLOG (tickets cités), COMBAT_INVENTORY.json (entrée Flashstep).
