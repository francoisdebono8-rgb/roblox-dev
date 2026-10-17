> Documentation spécialisée de référence ; état dans [CURRENT_STATE](../active/CURRENT_STATE.md), travail et critères dans [MASTER_BACKLOG](../active/MASTER_BACKLOG.md). Les anciennes propositions et statuts ci-dessous ne fixent pas les priorités globales.

# Adding a prodigy — fighter template

Les [vingt fiches harmonisées](ROSTER_20.md) appliquent ce gabarit en huit sections compactes : version/promesse, tenue/mouvement, chakra, repères runtime, moveset/défense, techniques/période, éveil/boucles/habileté, Studio/sources. Séparer systématiquement existant, cible proposée et incertitude de période. Ne pas transformer ratings de design ou statistiques du code en faits canon. REVIEW_REQUIRED est admis quand le stade n’est pas vérifié ; ne jamais forcer une nature élémentaire pour remplir une case. Les priorités restent dans MASTER_BACKLOG.

Périmètre actuel : [CORE_ROSTER](CORE_ROSTER.md). Ce template devient la **base officielle de conception d’un fighter**, pas seulement une checklist technique. Il ne déclenche pas implicitement une extension du roster : Claude l’utilise pour concevoir, comparer ou réviser un personnage quand ce travail est autorisé.

## Philosophie obligatoire

Un personnage Ninja Duel ne doit jamais se résumer à `4 jutsus + une string M1`.

Chaque fighter doit exister à travers la même grammaire commune — mouvement, neutral, taijutsu, défense, outils, chakra, air, murs, substitution — puis **interpréter cette grammaire à sa manière**.

Le principe directeur est :

`universal system -> character interpretation -> player mastery`

Exemples : tout le monde peut esquiver, mais Shisui le fait par burst/afterimage, Neji par lecture et footwork, Gaara par défense de sable/minimal displacement, Lee par pure vitesse corporelle. Tout le monde peut utiliser des outils compatibles, mais Itachi maîtrise la géométrie des projectiles, Minato transforme les kunai marqués en réseau spatial, Sasuke combine wire/fire/lightning et Neji les garde secondaires.

La profondeur doit venir de **timing + direction + position + état + contexte air/mur + outil + chakra + lecture adverse**, pas d’un clavier rempli de boutons.

Un move n’est pas validé parce qu’il existe. S’il reste « danseur », illisible, sans fonction claire ou sans appui/contact crédible, Claude peut le rejeter ou le reconstruire.

## Fiche moveset complète

Chaque fighter doit répondre à toutes les sections ci-dessous. Une case vide est une décision consciente, pas un oubli.

### 1. Identité
- fantasy du personnage et stade jeune choisi ;
- rôle de combat ;
- rythme ;
- distance préférée ;
- forces / faiblesse principale ;
- signature mécanique ;
- question unique à laquelle son gameplay répond ;
- label lore par capacité : `CANON_YOUNG`, `PLAUSIBLE_YOUNG`, `GAMEPLAY_LIBERTY`, `REJECT_ADULT_ONLY`.

Le stade jeune n’est pas un âge uniforme pour tout le roster. Prendre le **pic jeune/prodige cohérent** où l’identité future existe déjà, sans importer l’arsenal adulte complet.

### 2. Mouvement
Définir le ressenti et l’usage de :
- idle / stance ;
- run ;
- sprint ;
- strafe / lateral run ;
- changement de direction ;
- dash / rush ;
- jump / air control / landing ;
- pursuit ;
- disengage / reposition ;
- wall entry / wall-run / wall exit ;
- éventuel mouvement signature.

La locomotion doit déjà être agréable sans combattre. Appuis, cadence, transfert de poids, posture, bras, centre de gravité et caméra doivent expliquer la vitesse.

### 3. Neutral / entrée en combat
Décrire :
- comment le personnage ferme la distance ;
- comment il maintient sa distance ;
- comment il force une réaction ;
- son poke principal ;
- son outil de lecture/feinte ;
- comment il sort d’un échange ;
- ce qu’un adversaire doit respecter avant même le premier combo.

### 4. Taijutsu et combos
La grammaire de base reste compacte mais contextuelle :
- neutral string ;
- `up` : launcher / route verticale ;
- `down` : sweep / slam / low route ;
- `left/right` : side route, angle change, grab ou conversion propre au perso ;
- air neutral / air up / air down / air side ;
- wall route ;
- pursuit route ;
- finisher ;
- cancel windows ;
- side-switch / orbit si pertinent ;
- grab / catch / throw / micro-clash si identitaire.

Chaque coup doit avoir une fonction : opener, pressure, counter, spacing, knockback, launcher, sweep, pursuit, side-switch, finisher, defensive conversion, wall conversion, aerial conversion. Éviter les spins gratuits et la chorégraphie sans fonction.

### 5. Armes et ninja tools
Définir :
- kunai ;
- shuriken ;
- arme spécifique ;
- wire / tags / smoke si pertinent ;
- tool while moving ;
- tool -> melee ;
- melee -> tool ;
- tool -> pursuit ;
- projectile collisions / deflections ;
- outil planté dans mur/sol si utile ;
- usage offensif, défensif, setup ou range bridge.

Une arme ne doit pas être « le même combo avec un mesh différent ». Elle doit changer corps, portée, timing, angle, recovery ou conversion.

### 6. Jutsus / techniques
Pour chaque technique :
- fonction de gameplay ;
- coût chakra ;
- startup / channel ;
- active ;
- recovery ;
- cooldown si nécessaire ;
- portée ;
- mouvement autorisé pendant l’usage ;
- counterplay ;
- conversions possibles ;
- interaction air / mur / terrain / outil ;
- raison lore.

Limiter la quantité brute. Une technique utile dans plusieurs contextes vaut mieux que cinq boutons redondants.

### 7. Garde / défense
Définir l’interprétation du personnage pour :
- guard normal ;
- timed deflect / parry ;
- perfect dodge ;
- counter ;
- anti-air ;
- defense on wall / in air ;
- guard break vulnerability ;
- strike clash / weapon clash si pertinent.

### 8. Esquive et substitution
Définir séparément :
- dodge simple ;
- directional dodge ;
- perfect dodge window ;
- substitution / kawarimi ;
- coût / charge / cooldown ;
- destination ;
- fenêtre de punish ou de bait ;
- retour au neutral ;
- twist propre au personnage.

La substitution est un anti-combo lisible et maîtrisable, pas un bouton gratuit qui efface toute erreur.

### 9. Rush / poursuite
Définir :
- offensive dash ;
- gap closer ;
- chase après launcher ;
- air pursuit ;
- wall pursuit ;
- tool-assisted pursuit ;
- re-entry après disengage ;
- moyen adverse de casser la poursuite.

### 10. Chakra
Définir :
- réserve ;
- recharge active/passive ;
- vitesse de recharge ;
- état low chakra ;
- conséquence sur mouvement, défense et jutsu ;
- éventuelle spécialité du personnage : grosse réserve, contrôle précis, coût réduit ciblé, drain, etc.

Le chakra est un système, pas seulement une barre de mana.

### 11. Infusion / interactions de chakra
Utiliser la formule :

`Object + Chakra Property/Nature + Trigger/Context -> Result`

Pour chaque fighter, décider ce qui est pertinent parmi :
- reinforcement du corps ;
- arme ;
- kunai/shuriken ;
- wire ;
- environnement ;
- marque/seal ;
- nature élémentaire ;
- clash/interception.

Exemples génériques : wind + kunai -> vitesse/coupe ; lightning + métal/wire -> conductivité ; fire + projectile -> ignition ; seal + kunai marqué -> destination FTG.

Ne pas forcer une infusion à tous les personnages. La règle commune existe ; chacun l’exploite selon son identité.

### 12. Éveil
Un awakening doit **modifier la manière de jouer**, pas seulement `+20% damage`.

Définir :
- condition ;
- coût ;
- durée ;
- nouvelles règles ;
- mouvements / cancels / propriétés ajoutés ;
- changement de mobilité ;
- changement de chakra ;
- contrepartie / risque ;
- sortie de l’éveil.

Le stade reste celui du jeune prodige : pas de pouvoir adulte/endgame non justifié.

### 13. États et réactions
Définir quelles routes exploitent ou créent :
- stagger ;
- off-balance ;
- guard-open ;
- launch ;
- falling ;
- wall-splat ;
- grounded ;
- recovering ;
- grabbed ;
- weapon clash ;
- chakra/resource disruption si pertinent.

Combat grammar cible :

`contact -> state change -> transition -> character-specific conversion`

### 14. Gameplay loop
Écrire une boucle représentative en une ligne, par exemple :

`probe -> force dodge -> angle change -> short taijutsu -> tool cancel -> pursuit -> wall conversion -> disengage`

Puis au moins :
- une boucle agressive ;
- une boucle défensive ;
- une boucle low-chakra ;
- une boucle air/wall si le personnage la privilégie.

### 15. Skill ceiling
Décrire explicitement :
- ce que fait un débutant ;
- ce qu’apprend un intermédiaire ;
- ce qu’un expert fait différemment ;
- quelles décisions/timings/positions séparent réellement ces niveaux.

Le skill ceiling doit venir de maîtrise et de lecture, pas uniquement de mémorisation de longs inputs.

### 16. Signature irremplaçable
Répondre :

> Pourquoi ce fighter ne pourrait-il pas être remplacé par un autre personnage avec les mêmes stats et quatre jutsus différents ?

Si la réponse n’est pas claire, le design n’est pas terminé.

## Exigence de différenciation

Avant validation, comparer le fighter aux personnages existants :
- neutral ;
- movement identity ;
- taijutsu silhouette ;
- launcher ;
- pursuit ;
- wall use ;
- air use ;
- standard tools ;
- chakra use ;
- defense ;
- awakening ;
- signature rule-bending.

Deux personnages peuvent partager des systèmes, mais pas produire la même expérience avec des VFX différents.

## Mapping technique actuel

| Layer | Where | What to write |
|---|---|---|
| Identity & stats | `../../src/Shared/Fighters.luau` | `Name`, `FullName`, `Age`, `Title`, `Color`, `Description`, `Routes`, health/chakra/speed scales, `PreferredRange` |
| Taijutsu timing | `Fighters.<id>.AttackProfile` | `startup`, `recovery`, `travel`, `range`, hitbox, damage, impulses |
| Combo grammar | `../../src/Shared/MoveGraphs.luau` | `routes`, air routes, side routes, disengage, payoffs, cancels, read counter |
| New strikes | `../../src/Shared/Attacks.luau` | timing + motion + `ZONE` / `KIND` + hitbox + reactions |
| Route payoffs | `Brawler.routePayoff` | character-specific conversion kinds |
| Ninja tools | `Fighters.<id>.ToolMastery` | kind/count/speed/damage/recover + mastery flags |
| Techniques | `Fighters.<id>.Techniques` + `../../src/Server/Techniques.luau` | cost/channel/active/recovery/cooldown/range + execution |
| Signature / passive | Combat / Brawler hook | data-driven when possible |
| Awakening | `Fighters.<id>.Awakening` | rule changes, not only numeric buffs |
| Body: stance & gait | `../../src/Client/VelmoraMotionEngine.luau` | stance/gait/stride/cadence/lean/guard |
| Body: clips | same file | attack/contact/recovery clips; no fallback accepted as final identity proof |
| Technique poses | `castSpec` | channel/release pose |
| Effects | `../../src/Client/Effects.luau` | signature + impact + projectile visuals |
| Camera | `../../src/Client/Camera.luau` | bounded support for impact/speed/verticality |
| AI | `../../src/Server/AI.luau` | use rules that exercise actual identity |
| Tests | `tests/<Name>.spec.luau` | signature mechanics + state integrity + matchup checks |

Ces chemins reflètent l’architecture actuelle et doivent être vérifiés au moment de l’implémentation. Ne pas préserver un ancien point de branchement s’il a été remplacé proprement.

## Validation Studio obligatoire

Un fighter n’est pas « terminé » parce que ses tests passent.

Minimum :
1. 30 secondes de déplacement seul agréables et identitaires ;
2. simple punch / kick crédibles image par image autour du contact ;
3. neutral -> défense -> outil -> re-entry sans coupure visible ;
4. routes ground / air / wall testées ;
5. substitution / dodge / guard / counter lisibles ;
6. chakra et low-chakra réellement ressentis ;
7. arme/outils changent le gameplay si le personnage les maîtrise ;
8. awakening change les décisions ;
9. comparaison avec le golden visual set et les références R15 ;
10. aucune motion « danseuse » conservée simplement parce qu’elle existait déjà.

Linked active work: CHR-CORE-001/002, current CHR-* identity tickets, MOV-001..005, COM-001..007, DEF-001..005, TOOL-001..006, SYS-001..003, ARENA-001/003, CAM-001/002, RES-001/003, LAB-002.
