# Ninja Duel — progression par arbres de compétences

Spécification de design pour Claude · 15 octobre 2026 · version proposée 1.0.

**Mandat autorisé : analyse distante et spécification uniquement. Aucun changement gameplay, activation de roster, achat, matchmaking ou publication.** La vision des arbres et des budgets vient de la demande utilisateur de cette session ; les choix de coûts, valeurs, rythme XP et nouvelles capacités ci-dessous sont des propositions de conception, pas des fonctionnalités livrées ni un équilibrage validé.

## 1. Provenance et choix de base

Source exclusive : `francoisdebono8-rgb/roblox-dev` sur GitHub. Lecture par API GitHub, inventaires récursifs distants, comparaison des branches, puis clone neuf de la branche documentaire distante dans un répertoire temporaire. Aucun contenu de l’ancienne copie de travail n’a servi à ces spécifications. Les absences et le roster à deux personnages constatés auparavant sur cette copie sont **invalidés pour cette analyse**.

| Référence distante vérifiée | SHA | Rôle retenu |
|---|---|---|
| `main` (branche par défaut GitHub) | `1baf3ef5e811b1b86c06aed63ccc760edea7b5cf` | Référence de dépôt ; ne contient pas la couche active demandée |
| `codex/ninja-claude-technical-prep` | `3b50d8eccbaebcc982af5476ff56d279353b3cb0` | **Base documentaire de cette spec** : START, décisions, template, pool utilisateur du 13 octobre |
| `claude/minato-itachi-final` | `4bb3275141e4c34e5937fde7c2e1bb9f2b9a5a73` | Base runtime Claude identifiée par le journal actif, incorporée dans la préparation |
| `codex/ninja-progression-foundations` | `29a9ec101f22105f682a24484547a5de86ba2197` | Préparation progression isolée à comparer ; non fusionnée à la base documentaire |
| `codex/ninja-chakra-interactions` | `7091585542b1795b3abac614cbd2f1bab85d7e51` | Autre suite divergente ; aucune interaction de cette branche supposée intégrée |
| `codex/ninja-input-ps5` | `ad8247c4105258589cb7bfd8f7080299950466af` | Suite inputs divergente, ancêtre de progression |
| `codex/ninja-devtools-online` | `33028b26041570940cfcaf9c1f66cd3f93d8e5aa` | Préparation outils/online divergente, ancêtre de progression |

La comparaison GitHub progression → préparation documentaire donne **37 commits propres à préparation et 4 à progression**, ancêtre commun `4df212c57373a01b5c7ba6c10df4859a7b515f50`. Chakra ajoute un cinquième commit sur ce côté. Main et préparation divergent également (65 / 1). Il n’existe donc pas ici de preuve d’une branche réunissant toutes les dernières évolutions. Le choix documentaire repose sur START/CURRENT_STATE/DECISIONS et les demandes du 13 octobre, **pas sur la seule date d’un commit**. Claude devra résoudre l’intégration avant toute implémentation ; cette spec ne tranche pas une fusion runtime.

### Registre des sources lues

- **S01** — [Entrée Claude](https://github.com/francoisdebono8-rgb/roblox-dev/blob/3b50d8eccbaebcc982af5476ff56d279353b3cb0/games/ninja-duel/CLAUDE_START_HERE.md).
- **S02** — [Vision active](https://github.com/francoisdebono8-rgb/roblox-dev/blob/3b50d8eccbaebcc982af5476ff56d279353b3cb0/games/ninja-duel/docs/active/VISION.md).
- **S03** — [Décisions actives](https://github.com/francoisdebono8-rgb/roblox-dev/blob/3b50d8eccbaebcc982af5476ff56d279353b3cb0/games/ninja-duel/docs/active/DECISIONS.md).
- **S04** — [État et limites](https://github.com/francoisdebono8-rgb/roblox-dev/blob/3b50d8eccbaebcc982af5476ff56d279353b3cb0/games/ninja-duel/docs/active/CURRENT_STATE.md).
- **S05** — [Journal cumulatif](https://github.com/francoisdebono8-rgb/roblox-dev/blob/3b50d8eccbaebcc982af5476ff56d279353b3cb0/games/ninja-duel/docs/active/SINCE_LAST_CLAUDE.md).
- **S06** — [Backlog maître](https://github.com/francoisdebono8-rgb/roblox-dev/blob/3b50d8eccbaebcc982af5476ff56d279353b3cb0/games/ninja-duel/docs/active/MASTER_BACKLOG.md).
- **S07** — [Template fighter intégral](https://github.com/francoisdebono8-rgb/roblox-dev/blob/3b50d8eccbaebcc982af5476ff56d279353b3cb0/games/ninja-duel/docs/characters/FIGHTER_TEMPLATE.md).
- **S08** — [Core roster](https://github.com/francoisdebono8-rgb/roblox-dev/blob/3b50d8eccbaebcc982af5476ff56d279353b3cb0/games/ninja-duel/docs/characters/CORE_ROSTER.md).
- **S09** — [Dix blueprints](https://github.com/francoisdebono8-rgb/roblox-dev/blob/3b50d8eccbaebcc982af5476ff56d279353b3cb0/games/ninja-duel/docs/characters/ROSTER_MOVESETS_10_PRODIGIES.md).
- **S10** — [Pool utilisateur 25 et familles](https://github.com/francoisdebono8-rgb/roblox-dev/blob/3b50d8eccbaebcc982af5476ff56d279353b3cb0/games/ninja-duel/design_research/02_character_architecture/ROSTER_ARCHETYPES_32.md).
- **S11** — [Fighters, valeurs réelles](https://github.com/francoisdebono8-rgb/roblox-dev/blob/3b50d8eccbaebcc982af5476ff56d279353b3cb0/games/ninja-duel/src/Shared/Fighters.luau).
- **S12** — [MoveGraphs, routes réelles](https://github.com/francoisdebono8-rgb/roblox-dev/blob/3b50d8eccbaebcc982af5476ff56d279353b3cb0/games/ninja-duel/src/Shared/MoveGraphs.luau).
- **S13** — [Contrats états/outils](https://github.com/francoisdebono8-rgb/roblox-dev/blob/3b50d8eccbaebcc982af5476ff56d279353b3cb0/games/ninja-duel/docs/current/COMBAT_CONTRACTS.md).
- **S14** — [Matrice quatre personnages](https://github.com/francoisdebono8-rgb/roblox-dev/blob/3b50d8eccbaebcc982af5476ff56d279353b3cb0/games/ninja-duel/docs/FOUR_CHARACTER_COMBAT_MATRIX.md).
- **S15** — [Awakenings candidats, non approuvés](https://github.com/francoisdebono8-rgb/roblox-dev/blob/3b50d8eccbaebcc982af5476ff56d279353b3cb0/games/ninja-duel/design_research/02_character_architecture/AWAKENING_DESIGN.md).
- **S16** — [Règles de reprise](https://github.com/francoisdebono8-rgb/roblox-dev/blob/3b50d8eccbaebcc982af5476ff56d279353b3cb0/games/ninja-duel/docs/active/EXECUTION_RULES.md).
- **S17** — [Capacités et QA](https://github.com/francoisdebono8-rgb/roblox-dev/blob/3b50d8eccbaebcc982af5476ff56d279353b3cb0/games/ninja-duel/docs/active/CAPABILITIES_AND_TOOLS.md).
- **S18** — [Inventaire technique](https://github.com/francoisdebono8-rgb/roblox-dev/blob/3b50d8eccbaebcc982af5476ff56d279353b3cb0/games/ninja-duel/docs/current/COMBAT_INVENTORY.json).
- **S19** — [README progression isolée](https://github.com/francoisdebono8-rgb/roblox-dev/blob/29a9ec101f22105f682a24484547a5de86ba2197/games/ninja-duel/progression/README.md), [ProgressionRoster](https://github.com/francoisdebono8-rgb/roblox-dev/blob/29a9ec101f22105f682a24484547a5de86ba2197/games/ninja-duel/src/Server/ProgressionRoster.luau), [ProgressionConfig](https://github.com/francoisdebono8-rgb/roblox-dev/blob/29a9ec101f22105f682a24484547a5de86ba2197/games/ninja-duel/src/Server/ProgressionConfig.luau).

Les fiches actives [Sasuke](https://github.com/francoisdebono8-rgb/roblox-dev/blob/3b50d8eccbaebcc982af5476ff56d279353b3cb0/games/ninja-duel/docs/characters/SASUKE.md), [Minato](https://github.com/francoisdebono8-rgb/roblox-dev/blob/3b50d8eccbaebcc982af5476ff56d279353b3cb0/games/ninja-duel/docs/characters/MINATO.md), [Itachi](https://github.com/francoisdebono8-rgb/roblox-dev/blob/3b50d8eccbaebcc982af5476ff56d279353b3cb0/games/ninja-duel/docs/characters/ITACHI.md), [Neji](https://github.com/francoisdebono8-rgb/roblox-dev/blob/3b50d8eccbaebcc982af5476ff56d279353b3cb0/games/ninja-duel/docs/characters/NEJI.md) ont été lues. Le template a été lu jusqu’au mapping et aux gates Studio ; le backlog a été examiné par domaines et IDs. L’audit couvre les systèmes du jeu par leurs contrats, inventaire, matrice, définition Fighters et MoveGraphs : il ne prétend pas à une revue ligne par ligne de chaque dépendance ou de chaque asset binaire. Forge est hors périmètre.

### État réel à ne pas confondre avec la cible

- Quatre personnages sélectionnables sur la base documentaire : Minato/Flashstep, Itachi/Mirage, Neji/GentleFist, Sasuke/Lion. Gaara/Sand existe côté serveur/tests et reste caché. Naruto n’est pas encore un kit jouable démontré.
- Le pool explicitement choisi par l’utilisateur contient **25 noms**, alors que la recherche plus large vise ~32. La demande actuelle « ~20 » devient une vague de vingt propositions, puis cinq fiches d’annexe ; aucun nom du pool n’est supprimé. Cet ordre de vague est proposé ici.
- Le socle comporte routes directionnelles, air/murs, parades, substitutions, grabs, outils et awakenings. Les points ne doivent pas retirer ces éléments aux CORE4 pour les revendre.
- Le match décrit par CURRENT_STATE est humain contre IA. Les gates PvP, natifs et feel restent ouverts. Ni cette spec ni les anciens rapports ne constituent une preuve de vingt combattants en production.
- La branche progression prépare XP, rangs, collection, profils versionnés, transactions et queues. Elle est OFF, sans application combat. Son ranked actuel utilise les bases normalisées **sans croissance** : ce n’est pas encore le ranked à arbre actif demandé. Les fixtures « roster20 » ne sont pas vingt personnages réels.

## 2. Vision désormais demandée et décisions proposées

Le moteur de combat reste la valeur centrale. **À zéro point**, chaque combattant possède un neutral, une entrée, une sortie, des frappes identitaires, défense, outil pertinent, conversion sol/air/mur et signature jouable. Son arbre enrichit les décisions : nouvelle fin de combo, alternative de jutsu, contre conditionnel, géométrie d’outil, substitution spécialisée, règle d’éveil. La progression ne répare pas un personnage volontairement amputé.

Le template complet S07 continue à régir mouvement, neutral, taijutsu, outils, jutsu, garde, dodge/substitution, poursuite, chakra, infusion, éveil, états, boucles, maîtrise et signature. Cette spec définit la couche progression ; elle n’autorise pas à remplacer les moteurs ni à contourner la validation d’un moveset.

| Décision | Statut et portée |
|---|---|
| Arbre par personnage, XP, points, rebuild ; ranked par points actifs | **Demandé par l’utilisateur le 15/10/2026**, design seulement |
| Boost XP, achat de points/accélération, tenues/cosmétiques | **Demandé** ; prix/catalogue/reçus live non conçus ni activés ici |
| 150 points d’arbre possédables, 100 actifs maximum ; trois branches de 50 | **Proposition chiffrée** pour rendre les arbitrages testables |
| 20 fiches principales + 5 annexes du pool distant | **Proposition de couverture**, pas autorisation d’ajouter 25 combattants au runtime |
| Toutes les nouvelles options ci-dessous = GAMEPLAY_LIBERTY provisoire | **Choix conservateur de provenance** : pas de canon inventé |

Les anciens briefs refusaient l’achat de puissance et S19 normalise les stats ranked. La demande actuelle remplace ce principe de design par une progression achetable sous budget actif. Il faut écrire cette évolution explicitement lors de l’intégration, sans réécrire les archives. **Même budget n’implique pas égalité d’options** : un joueur qui a payé pour plus de déblocages peut disposer d’un meilleur contre-build. Cette limite est inhérente au modèle demandé, pas résolue par le chiffre 100. Proposition complémentaire : entraînement avec tous les nodes essayables gratuitement, et format tournoi séparé à catalogue prêté intégral pour les compétitions exigeant une parité d’accès. Ce format ne remplace pas les files 50/80/100.

## 3. Économie de progression et ranked

### Trois nombres distincts

1. **Points disponibles G** : maximum 150 par personnage, issus de progression gratuite + accélération achetée. Non transférables entre personnages dans cette proposition.
2. **Points possédés O** : somme des coûts des nodes débloqués ; O ≤ G. Ils représentent la largeur du catalogue acquis.
3. **Points actifs A** : somme des nodes équipés **et de tous leurs ancêtres actifs** ; A ≤ budget de la file et A ≤ O. Un ancêtre possédé mais désactivé ne suffit jamais. Aucun passif d’un node inactif n’est appliqué.

Chaque node est un achat unique, sans rang caché. Trois chaînes indépendantes par personnage, A/B/C, coûts incrémentaux **5 → 10 → 15 → 20**, soit coûts cumulés **5 / 15 / 30 / 50**. Les racines des trois branches sont ouvertes dès le départ ; aucune branche n’exige une autre branche. Total de catalogue = 150 points. Pas d’exigence de niveau supplémentaire par node, pas de capstone gratuit parce qu’il est possédé.

Les chaînes utilisent une même grille de prix pour faciliter l’audit, **pas un arbre moteur générique ni des movesets clonés**. Leurs fonctions diffèrent : corps, perception, entités, contrôle, outils, défense, espace. Chaque palier 2/3/4 apporte une décision de combat propre au personnage. Les embranchements se font entre A/B/C et par variantes exclusives à l’intérieur des actions. Une topologie plus complexe ne se justifie que si ces décisions ne suffisent pas en playtest.

### XP et attribution — hypothèse de départ mesurable

Niveau de personnage 1 à 51 ; 3 points par niveau gagné, soit 150 gratuits au niveau 51. Coût de passage du niveau L au niveau L+1 : `100 + 20 × (L−1)` XP ; total à L51 = 29 500 XP. Points naturels `min(150, 3 × (niveau−1))`. Un duel éligible terminé donne 100 XP de participation +25 XP de victoire, sans récompense par dégât, clone tué, durée AFK ou achat d’arbre. Ces chiffres servent à tester une économie, pas à annoncer une durée de grind : mesurer la durée réelle d’un duel avant calibrage. Tutoriel : récompense fixe idempotente ; entraînement libre sans XP répétable. Match annulé/serveur interrompu : pas de victoire attribuée artificiellement, reprise du résultat par ID serveur si déjà validé.

Boost proposé : ×1,5 sur XP, non cumulable, durée en temps de jeu éligible annoncée à l’achat ; aucun multiplicateur de points par niveau. Achat direct de N points : `G = min(150, pointsNaturels + pointsPayésConfirmés)`, plafonné au restant disponible. Points payés accélèrent exactement le même catalogue ; aucun node premium, aucun plafond supérieur. Une fois G=150, empêcher l’achat de points sur ce personnage. L’XP ultérieure peut ne plus ajouter de points : l’indiquer clairement, sans récompense fictive. Pas de Robux/prix de boutique inventé dans ce document.

Rebuild gratuit hors match/file : refund intégral des nodes vendus, descendants obligatoirement retirés si parent supprimé ; aucune destruction de l’XP ou du personnage. Trois presets minimum, un par budget ; preview gratuit en entraînement. Changement d’actifs sans coût avant mise en file. L’arbre et les choix de variantes sont verrouillés du pairing à la fin du match entier, pas seulement du round. Aucun achat/XP gagné pendant le match ne change ce snapshot.

### Files et information

Clé cible : `mode + budget(50|80|100) + région + versionBalance`, puis MMR et tolérance de latence. Ne jamais fusionner deux budgets pour raccourcir l’attente. Le lancement peut n’ouvrir que 50 pour concentrer la population, tout en conservant les règles 80/100. Entrer exige un loadout légal ; proposition de produit : demander G ≥ budget pour que chacun puisse atteindre le plafond, sans obliger à le dépenser entièrement. Pas de remplissage automatique de nodes si A < budget. En dessous : entraînement et duel non classé.

Deux adversaires peuvent avoir des personnages différents mais doivent partager budget et version. Montrer avant match budget, points réellement actifs, branches et icônes des gros nodes ; masquer argent dépensé et XP, qui ne sont pas des informations de combat. Pas de contre-pick d’arbre après révélation. Reconnect reprend le même snapshot ; requeue utilise un nouveau snapshot validé. Un patch invalide les builds concernés et rend leurs points, sans amputer silencieusement une branche.

Un profil à 150 débloqués pourra équiper A complet + B complet en 100 ; ses 50 points de C ne servent qu’à un autre preset. Un novice ne reçoit jamais la puissance de ses points **non actifs**, ni un bonus de compte ou de rareté en combat. La croissance SpeedGrowth de S19 doit être remplacée par les nodes actifs dans ce mode, pas additionnée à eux.

## 4. Contrats de compétences et garde-fous chiffrés

### Stats de base

Cartes **ordinales 1–10**, comparées à ce roster et non à la fiction adulte : 1 = très faible, 5 = moyen, 10 = exceptionnel. Difficulté 10 = demande forte en lecture/exécution. Intelligence/lecture décrit les décisions et indices offerts au joueur, jamais l’omniscience du bot. Contrôle chakra = efficacité/précision, défense = options/recovery et non armure passive ; portée = pression utile, mobilité = espace sol/air/mur, vitesse = cadence de déplacement. **Aucune conversion automatique `note × WalkSpeed/dégâts/HP`**.

Pour CORE4 et Sand, conserver à zéro point les chiffres réellement présents dans S11 tant qu’un retune séparé n’est pas approuvé. Exemple distant : HP/chakra/vitesse = Sasuke 120/105/19, Minato 125/110/19,5, Itachi 145/125/18, Neji 135/115/18,5, Gaara 140/130/16,5. Les notes ne prétendent pas corriger ces valeurs. Pour les nouveaux personnages, la calibration absolue (rig/arène/frames) est une tâche d’implémentation future.

Les petits nodes n’augmentent qu’une propriété indiquée. Somme active des bonus scalaires par propriété plafonnée à +6 % (ou réduction de coût 6 %), dégâts généraux jamais plus de +4 % par ces nodes. Une remise de 2 % signifie coût final `ceil(coûtBase × 0,98)`, jamais une soustraction de deux chakra. Aucun node de stats n’augmente portée, hitstun, iframe, charges de substitution, fenêtre de parade ou régénération des boucliers. Un bonus sur « course » ne s’applique pas à FTG, dash ou projectile. Tout écart à cette règle exige un retune explicite.

### Application commune des gros nodes

Chaque ligne de fiche décrit condition, changement et indice visible. Les valeurs de ce tableau complètent les lignes :

| Type | Proposition de contrat par défaut si la fiche ne précise pas une exception |
|---|---|
| Route/cancel de combo | Coût ressource et phases de l’action remplacée ; seulement après hit confirmé si indiqué ; pas de cancel sur garde/whiff ajouté implicitement ; même plafond de dégâts et budget air/mur que la route remplacée |
| Variante de jutsu existant | Même slot, chakra, phases, range, cooldown et dégâts totaux que le parent, sauf changement explicite ; augmenter couverture/angle impose le compromis décrit, jamais une seconde technique avec cooldown indépendant |
| Nouvelle action autonome (contre, zone, phase) | 18 chakra ; startup 0,3 s interruptible ; actif 0,15 s ; recovery 0,45 s ; cooldown 6 s ; portée corps 6 studs, placement 12 studs maximum avec LOS ; les durées/valeurs explicites de la fiche priment |
| Contre conditionnel | Réussite de défense constatée serveur, fenêtre de commande 0,6 s ; le contre consomme sa propre startup/recovery et n’est jamais un hit automatique ; pas de coût si aucune commande n’est entrée |
| Placement/entité | 1 par famille sauf limite explicitement annoncée ; durée 3 s ; objet destructible à 1 PV par attaque valide ; pas de dégâts au spawn ; cooldown démarre au placement et ne reset pas à la destruction ; raycast et overlap à création/résolution |
| Modification de substitution | Activation uniquement si substitution de base légale ; mêmes charges/coût/cooldown/iframe/délai d’attaque/distance que la base ; sortie libre validée et aucun remboursement au succès ; effet visuel ne devient pas un collider sans mention |
| Capstone A4/B4 | Manœuvre spécialisée, pas une transformation permanente ; si action autonome : 24 chakra, startup 0,4 s, actif 0,15 s, recovery 0,6 s, cooldown 10 s ; autrement partage intégralement le budget et cooldown de la route/jutsu remplacé |
| Capstone C4 | Variante de l’éveil de base, pas un deuxième éveil. Proposition future : activation manuelle à HP ≤35 %, canal 0,5 s interruptible, durée maximale 12 s, une fois par match, pas de recharge par changement de round ; fin en neutral/recovery légal, entités temporaires nettoyées. Aucune prolongation à chaque hit/KO |

Les quatre awakenings existants ne sont pas déclarés conformes à cette nouvelle cible : leurs multiplicateurs sont observables dans S11. **Ne pas empiler les modificateurs d’un capstone avec les anciens multiplicateurs sans audit** SYS-003/BAL-001. L’implémentation devra figer une définition de base versionnée et ses variantes ; ce document seul ne retune rien.

La grammaire de commandes reste celle de S12 : direction + Light/Heavy/Tool/Jump et les slots existants. Les nodes modifient des branches contextuelles, pas neuf nouveaux boutons. Une action autonome non couverte remplace un usage secondaire ou un slot annoncé dans le futur manifeste ; aucun slot gratuit. Avant implémentation, remplir pour chaque ID son mapping exact clavier/manette et sa priorité contextuelle : si deux usages entrent en conflit, retenir une variante à l’équipement. Aucun « contexte magique » qui interprète mal une intention.

### Exclusivités et cumul

- **Aucune incompatibilité globale entre les branches A, B et C** : deux capstones A4/B4 peuvent coexister en 100 si leurs prérequis sont payés. Un capstone de manœuvre n’ajoute pas d’éveil.
- Les variantes d’une **même action** sont mutuellement exclusives à chaque exécution ou à l’équipement lorsque spécifié : cône/boule, tir direct/rebond, copie sonore/indicateur, maintien/expulsion, poussée/ignition. Le joueur choisit l’alternative, il ne bénéficie jamais des deux payoffs.
- Un node enfant exige son parent **possédé et actif**. Retirer A2 désactive A3/A4, les rend inéquipables et met à jour le coût. Aucun prérequis OR ou remboursement implicite. Les IDs sont uniques par personnage.
- Bonus de stats = propriétés distinctes avec plafonds ci-dessus ; drain/poison/clones ne se cumulent pas par plusieurs chemins. Une même victime ne reçoit pas deux dégâts « parent + variante » pour la même action.
- Un seul état d’éveil simultané par personnage. Le capstone C4 enrichit celui-ci, conserve ses coûts/risques spécifiques et ne donne aucun second déclenchement.
- Les conversions aériennes/murales **consomment ou remplacent** le budget existant. Jamais de reset à chaque sceau, clone, miroir, flaque ou mur. Le tech/wakeup et les réponses adverses restent disponibles selon les règles communes.

### Lisibilité et lore

Nouveau node majeur : silhouette/pose d’anticipation distincte, effet bref de direction/volume, réaction de contact réelle, et son de réussite/échec. Aucun VFX ne remplace un contact, et aucun cosmétique ne change la portée apparente utile. La trajectoire annoncée peut être une feinte **explicitement conçue**, pas une hitbox cachée.

La source de chaque famille de fiche est S08/S09 ou S10, indiquée ci-dessous. **Chaque node proposé reçoit le label provisoire `GAMEPLAY_LIBERTY`, source exacte = section de fiche de cette spec, filiation vers S09/S10**. Cela signifie « proposition de mécanique inspirée du repo », pas preuve canon. Claude ne doit attribuer `CANON_YOUNG` qu’après source scène/âge/timecode vérifiée ; `PLAUSIBLE_YOUNG` doit rester motivé. Les techniques déjà codées restent faits techniques, leur canon non certifié (CHR-CORE-002). Les capacités adultes exclues sont `REJECT_ADULT_ONLY`. Aucune recherche web externe ni scène canonique supposée n’a été utilisée, conformément à la source unique demandée.

## 5. Catalogue et lecture des arbres

Ordre demandé en tête : Sasuke, Naruto, Minato, Itachi, Neji. Les vingt premières fiches constituent la vague de design proposée ; Hiruzen, Deidara, Darui, Yagura et Konan sont des annexes complètes pour conserver le pool 25. Les identifiants `*_PROPOSED` sont documentaires, **pas de nouveaux IDs runtime à enregistrer**.

Chaque racine coûte 5 ; palier 2 coûte 10 ; palier 3 coûte 15 ; capstone 4 coûte 20. Chaque tableau répète les prérequis. Les presets listent **tous** leurs nodes et coûts exacts ; ils montrent une intention de jeu, sans prétendre être les builds optimaux. La branche absente est le renoncement réel du build.

### 01 — Sasuke

**Statut :** CORE4 jouable techniquement ; feel natif non certifié ici. **Filiation :** S08/S11/S12 et fiche active.

| taijutsu | vitesse | chakra | contrôle chakra | ninjutsu | genjutsu | défense | portée | mobilité | intelligence/lecture | outils/armes | difficulté |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 8 | 8 | 6 | 7 | 8 | 5 | 5 | 7 | 8 | 7 | 8 | 7 |

**Kit à zéro point et identité :** Rushdown mix-range à kicks : appuis inclinés, strafe incisif et saut de poursuite. Noyau distant déjà présent : Lion/ShadowLeaf, shuriken, WireTrap → Dragon Flame, FireBloom, PhoenixFlower, Chidori et Curse Mark. Le fil et le Chidori restent utilisables à zéro point ; les nodes ajoutent des décisions autour de ces techniques.

**Branche A — Lion aérien** (50 points cumulés).

| Node | Coût | Prérequis actif | Effet concret et signal de combat |
|---|---:|---|---|
| `A1` | 5 | Kit de base | Appuis de lion : +2 % aux dégâts des frappes corporelles seulement. |
| `A2` | 10 | `A1` | Crochet ascendant : après Light2 confirmé, direction latérale + Heavy remplace le launcher frontal par un genou oblique ; montée plus basse, côté annoncé par la jambe d’appui ; ne fonctionne pas sur garde. |
| `A3` | 15 | `A2` | Rebond du faucon : après un Air1 confirmé près d’un mur, Jump fait prendre appui sur le mur pour un kick sortant ; consomme la conversion mur et remplace Air2, sans poursuite supplémentaire. |
| `A4` **capstone** | 20 | `A3` | Lion bifurqué : le Lion Combo existant peut finir par projection latérale plutôt que spike ; choix avant le dernier contact, pied et hanches indiquent le côté ; mêmes dégâts de séquence, sortie défensive conservée. |

**Branche B — Fil et feu** (50 points cumulés).

| Node | Coût | Prérequis actif | Effet concret et signal de combat |
|---|---:|---|---|
| `B1` | 5 | Kit de base | Dosage du Katon : coût chakra de FireBloom réduit de 2 %, arrondi au supérieur. |
| `B2` | 10 | `B1` | Fil déployé : Tool latéral plante un shuriken relié à une surface ; un seul segment de 12 studs, 4 s, cassable ; remplace cet usage de WireTrap et son cooldown, pas de bind automatique. |
| `B3` | 15 | `B2` | Dragon en éventail : sur fil valide, FireBloom peut détacher la flamme en cône étroit au lieu de suivre le fil ; couture lumineuse puis cône annoncé ; perd la capture et partage le cooldown du feu. |
| `B4` **capstone** | 20 | `B3` | Nœud embrasé : au croisement corps/fil, choisir tension vers le mur OU ignition ; tension consomme le fil et ouvre une conversion mur, ignition libère la cible avant les dégâts ; jamais les deux dans la même action. |

**Branche C — Lecture et foudre** (50 points cumulés).

| Node | Coût | Prérequis actif | Effet concret et signal de combat |
|---|---:|---|---|
| `C1` | 5 | Kit de base | Réserve disciplinée : chakra maximal +3 %, sans modifier sa régénération. |
| `C2` | 10 | `C1` | Décharge de parade : une parade réussie autorise un contact électrique court commandé par Heavy ; remplace la riposte habituelle, pas d’auto-hit ni de silence. |
| `C3` | 15 | `C2` | Chidori interrompu : pendant les 40 % initiaux de préparation, Cancel transforme la charge en recul court ; 50 % du chakra payé, cooldown conservé ; aucune annulation après engagement. |
| `C4` **capstone** | 20 | `C3` | Marque, chasse oblique : pendant Curse Mark, un Chidori aérien peut viser la tangente du mur puis terminer au sol ; trajectoire fixée au départ, consomme le budget aérien et garde le drain de vie existant. |

**Presets ranked proposés** — tous les ancêtres sont actifs.

| Budget | Nodes actifs | Total | Intention et renoncement |
|---|---|---:|---|
| 50 | `A1`, `A2`, `A3`, `A4` | 50 | Spécialiste Lion aérien ; abandon des deux autres branches. |
| 80 | `A1`, `A2`, `A3`, `A4`, `B1`, `B2`, `B3` | 80 | Lion aérien + premiers outils de Fil et feu ; renonce à B4 et à Lecture et foudre. |
| 100 | `A1`, `A2`, `A3`, `A4`, `B1`, `B2`, `B3`, `B4` | 100 | Double spécialisation Lion aérien/Fil et feu ; renonce entièrement à Lecture et foudre. |

**Risque spécifique et limites :** Fil → feu → air peut supprimer toute réponse ; Chidori ne doit jamais tourner instantanément vers une esquive. Séparer puissance de la marque et nouvelles routes. Pas de Susanoo, Rinnegan ni Chidori adulte à longue portée.

**Maîtrise à tester :** débutant = boucle du kit de base sans capstone ; intermédiaire = branche choisie + lecture d’une défense adverse ; expert = alterner les conversions permises selon position/ressource et abandonner une extension risquée. La progression ne remplace pas ce travail d’exécution.

### 02 — Naruto

**Statut :** Candidat de design, aucun kit jouable affirmé. **Filiation :** S09/S10.

| taijutsu | vitesse | chakra | contrôle chakra | ninjutsu | genjutsu | défense | portée | mobilité | intelligence/lecture | outils/armes | difficulté |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 7 | 7 | 10 | 4 | 7 | 2 | 8 | 5 | 7 | 5 | 5 | 5 |

**Kit à zéro point et identité :** Candidat des dix blueprints. Bagarreur endurant, petits changements de rythme et grands gestes lisibles. Base proposée : string de poings/kicks, launcher, slam, un clone physique commandé à 1 PV, lancer de kunai et Rasengan préparé. Le clone ouvre déjà une feinte ou une attaque, jamais deux dégâts simultanés garantis ; éveil de pression bestiale limité, sans guérison gratuite.

**Branche A — Bagarre et relais** (50 points cumulés).

| Node | Coût | Prérequis actif | Effet concret et signal de combat |
|---|---:|---|---|
| `A1` | 5 | Kit de base | Poings tenaces : dégâts taijutsu +2 %. |
| `A2` | 10 | `A1` | Crochet du double : après Light1 confirmé, Tool ordonne au clone un crochet latéral remplaçant Light2 ; clone détruit = branche manquée, aucun hitstun ajouté. |
| `A3` | 15 | `A2` | Relais ascendant : après launcher confirmé, Naruto OU son clone occupe la poursuite ; silhouette saute en premier, autre corps reste au sol ; un seul acteur inflige le follow-up. |
| `A4` **capstone** | 20 | `A3` | Uzumaki choisi : finisher de clone envoie horizontalement ou vers le sol selon direction ; troisième corps purement visuel, fin de juggle identique et réveil protégé. |

**Branche B — Ruse des clones** (50 points cumulés).

| Node | Coût | Prérequis actif | Effet concret et signal de combat |
|---|---:|---|---|
| `B1` | 5 | Kit de base | Clone économe : coût du clone réduit de 2 %. |
| `B2` | 10 | `B1` | Double retardé : Tool maintenu donne un retard de 0,3 s à la feinte du clone, sans prolonger sa durée de vie ; pose de départ reproductible mais poussière révèle la copie au contact. |
| `B3` | 15 | `B2` | Substitution trompeuse : une substitution légale laisse le clone à la position de départ si le slot est libre ; consomme la charge habituelle, aucune attaque automatique du clone. |
| `B4` **capstone** | 20 | `B3` | Permutation préparée : échanger sa place avec son unique clone au sol après signal de 0,3 s, dans 12 studs et LOS ; détruit le clone, arrivée punissable, interdit pendant hitstun. |

**Branche C — Chakra turbulent** (50 points cumulés).

| Node | Coût | Prérequis actif | Effet concret et signal de combat |
|---|---:|---|---|
| `C1` | 5 | Kit de base | Réserve canalisée : chakra maximal +3 %. |
| `C2` | 10 | `C1` | Rasengan de trajectoire : en l’air, choisir descente au lieu d’avance ; sphère et bras montrent la direction, mêmes dégâts, contact requis et long whiff. |
| `C3` | 15 | `C2` | Appui du clone : le clone peut servir d’impulsion aérienne unique ; le consomme et interdit sa poursuite offensive dans la même séquence, pas de saut infini. |
| `C4` **capstone** | 20 | `C3` | Éveil, bras de détour : pendant la pression bestiale, le finisher peut allonger son angle latéral par un bras de chakra annoncé ; remplace son finisher de base et coûte 20 chakra, sans armure ni soin. |

**Presets ranked proposés** — tous les ancêtres sont actifs.

| Budget | Nodes actifs | Total | Intention et renoncement |
|---|---|---:|---|
| 50 | `B1`, `B2`, `B3`, `B4` | 50 | Spécialiste Ruse des clones ; abandon des deux autres branches. |
| 80 | `B1`, `B2`, `B3`, `B4`, `A1`, `A2`, `A3` | 80 | Ruse des clones + premiers outils de Bagarre et relais ; renonce à A4 et à Chakra turbulent. |
| 100 | `B1`, `B2`, `B3`, `B4`, `A1`, `A2`, `A3`, `A4` | 100 | Double spécialisation Ruse des clones/Bagarre et relais ; renonce entièrement à Chakra turbulent. |

**Risque spécifique et limites :** Clones multipliant hitstun, masquage du vrai corps et spam de substitutions ; fixer les règles de lock et le budget d’entités. Rasengan/forme bestiale sont choix de stade jeune à documenter ; pas de mode ermite ni arsenal de guerre.

**Maîtrise à tester :** débutant = boucle du kit de base sans capstone ; intermédiaire = branche choisie + lecture d’une défense adverse ; expert = alterner les conversions permises selon position/ressource et abandonner une extension risquée. La progression ne remplace pas ce travail d’exécution.

### 03 — Minato

**Statut :** CORE4 jouable techniquement ; feel natif non certifié ici. **Filiation :** S08/S11/S12 et fiche active.

| taijutsu | vitesse | chakra | contrôle chakra | ninjutsu | genjutsu | défense | portée | mobilité | intelligence/lecture | outils/armes | difficulté |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 8 | 10 | 7 | 9 | 7 | 3 | 5 | 7 | 10 | 10 | 9 | 9 |

**Kit à zéro point et identité :** Le code distant possède déjà sceaux corps/surface/en vol, deux sceaux plantés, sélection directionnelle, FTG, Rasengan contextuel, Quickstep et WindCut. Base : taijutsu court et économique, course qui fabrique les angles, kunai rapide ; aucune marque existante retirée pour fabriquer artificiellement une progression. Yellow Flash reste un éveil de base à auditer.

**Branche A — Interceptions** (50 points cumulés).

| Node | Coût | Prérequis actif | Effet concret et signal de combat |
|---|---:|---|---|
| `A1` | 5 | Kit de base | Précision corporelle : dégâts taijutsu +2 %. |
| `A2` | 10 | `A1` | Arrivée basse : après FTG valide, Light + arrière donne un sweep court au lieu de la frappe d’entrée ; jambe basse visible, garde possible ; conserve recovery d’arrivée. |
| `A3` | 15 | `A2` | Poursuite tangente : après launcher marqué, choisir FTG latéral qui remplace la poursuite directe ; consomme la poursuite, cible mobile revalidée, aucun contact garanti. |
| `A4` **capstone** | 20 | `A3` | Double angle : après une frappe d’arrivée confirmée, une seconde destination déjà marquée devient accessible ; nouvelle dépense FTG et limite de deux téléports par séquence, seconde arrivée termine la conversion. |

**Branche B — Géométrie des sceaux** (50 points cumulés).

| Node | Coût | Prérequis actif | Effet concret et signal de combat |
|---|---:|---|---|
| `B1` | 5 | Kit de base | Encre précise : coût MarkedBlade réduit de 2 %. |
| `B2` | 10 | `B1` | Rappel de sélection : Tool + arrière échange la priorité corps/surface du prochain FTG ; anneau de destination visible des deux joueurs, ne crée ni troisième sceau ni déplacement gratuit. |
| `B3` | 15 | `B2` | Kunai tangent : le lancer marqué peut rebondir une fois sur surface plane choisie ; angle physique visible et perte de vitesse de 20 %, incompatible avec trajectoire directe sur ce lancer. |
| `B4` **capstone** | 20 | `B3` | Sceau de relais : consommer un sceau de surface pour réorienter un kunai marqué en vol ; détruit le premier, compte dans le plafond de deux ; pas de projectile homing ni téléport supplémentaire. |

**Branche C — Lecture et sortie** (50 points cumulés).

| Node | Coût | Prérequis actif | Effet concret et signal de combat |
|---|---:|---|---|
| `C1` | 5 | Kit de base | Pied léger : vitesse de course +2 %, sans bonus de dash/FTG. |
| `C2` | 10 | `C1` | Contrepied manuel : après perfect dodge, Quickstep arrière-latéral prépare un lancer de kunai au lieu d’une frappe ; aucune iframe additionnelle et déplacement bloqué par collision. |
| `C3` | 15 | `C2` | Substitution vers sceau : choisir un sceau libre dans la distance maximale de substitution comme sortie ; consomme charge, chakra et sceau, pas d’attaque immédiate. |
| `C4` **capstone** | 20 | `C3` | Yellow Flash, évacuation : pendant l’éveil, maintenir arrière à l’arrivée autorise de consommer le sceau pour reculer de 4 studs au lieu d’attaquer ; un seul usage par éveil et aucune nouvelle invulnérabilité. |

**Presets ranked proposés** — tous les ancêtres sont actifs.

| Budget | Nodes actifs | Total | Intention et renoncement |
|---|---|---:|---|
| 50 | `A1`, `A2`, `A3`, `A4` | 50 | Spécialiste Interceptions ; abandon des deux autres branches. |
| 80 | `A1`, `A2`, `A3`, `A4`, `B1`, `B2`, `B3` | 80 | Interceptions + premiers outils de Géométrie des sceaux ; renonce à B4 et à Lecture et sortie. |
| 100 | `A1`, `A2`, `A3`, `A4`, `B1`, `B2`, `B3`, `B4` | 100 | Double spécialisation Interceptions/Géométrie des sceaux ; renonce entièrement à Lecture et sortie. |

**Risque spécifique et limites :** Réseau FTG et remboursements peuvent supprimer le neutral. Pas de resets de cooldown, de garde ignorée à l’arrivée ni de téléport hors géométrie ; FTG et Rasengan à 13 ans ne sont pas certifiés canon par leur présence dans le code.

**Maîtrise à tester :** débutant = boucle du kit de base sans capstone ; intermédiaire = branche choisie + lecture d’une défense adverse ; expert = alterner les conversions permises selon position/ressource et abandonner une extension risquée. La progression ne remplace pas ce travail d’exécution.

### 04 — Itachi

**Statut :** CORE4 jouable techniquement ; feel natif non certifié ici. **Filiation :** S08/S11/S12 et fiche active.

| taijutsu | vitesse | chakra | contrôle chakra | ninjutsu | genjutsu | défense | portée | mobilité | intelligence/lecture | outils/armes | difficulté |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 7 | 7 | 8 | 10 | 8 | 10 | 6 | 8 | 7 | 10 | 10 | 9 |

**Kit à zéro point et identité :** Noyau distant : Sharingan Read, Shadow Shuriken, Geometry, ricochet, éventail aérien, Mirage, Fireball et PhoenixFlower. Corps compact et calme ; launcher de paume, route latérale de feinte. Le joueur garde ses outils de tromperie et son contre dès zéro point. Sharingan Focus existant reste distinct des capstones proposés.

**Branche A — Géométrie des lames** (50 points cumulés).

| Node | Coût | Prérequis actif | Effet concret et signal de combat |
|---|---:|---|---|
| `A1` | 5 | Kit de base | Lames précises : dégâts des outils +2 %, sans accroître leur nombre. |
| `A2` | 10 | `A1` | Geometry retardée : le second shuriken peut partir 0,25 s plus tard pour déplacer le moment du ricochet ; même nombre, trajectoire déterministe, annulation avant release uniquement. |
| `A3` | 15 | `A2` | Croisée aérienne : après Air1 confirmé, une lame descend et l’autre part à plat ; remplace Air2, partage le budget de dégâts et ne suit pas une esquive tardive. |
| `A4` **capstone** | 20 | `A3` | Triangle calculé : un impact sur surface désignée redirige la lame vers un second angle préparé ; maximum deux rebonds au total, vitesse réduite et aucun troisième projectile. |

**Branche B — Lecture et perception** (50 points cumulés).

| Node | Coût | Prérequis actif | Effet concret et signal de combat |
|---|---:|---|---|
| `B1` | 5 | Kit de base | Lecture économe : coût Read réduit de 2 %. |
| `B2` | 10 | `B1` | Read, paume extérieure : Read réussi ouvre une riposte latérale commandée au lieu de CounterPalm frontal ; garde possible selon fenêtre, aucune poursuite automatique. |
| `B3` | 15 | `B2` | Mirage sonore : à l’équipement choisir faux son de pas plutôt que faux indicateur ; durée identique, corps réel conserve ombre/contact, contre-jeu par observation. |
| `B4` **capstone** | 20 | `B3` | Erreur provoquée : une attaque manquée sur le leurre donne une feinte de feu courte à Itachi, à déclencher manuellement sous 0,6 s ; ne stun pas la victime et ne réduit pas la recovery d’Itachi. |

**Branche C — Feu et effacement** (50 points cumulés).

| Node | Coût | Prérequis actif | Effet concret et signal de combat |
|---|---:|---|---|
| `C1` | 5 | Kit de base | Souffle mesuré : chakra maximal +3 %. |
| `C2` | 10 | `C1` | Phoenix resserré : choisir un éventail étroit et décalé en hauteur au lieu du large ; mêmes projectiles/dégâts totaux et ligne de fuite latérale. |
| `C3` | 15 | `C2` | Substitution cendrée : la substitution légale laisse un écran de cendres de 0,8 s sans collider ni dégâts ; contour et audio de sortie conservés, aucun reset du leurre. |
| `C4` **capstone** | 20 | `C3` | Focus, double lecture : pendant Sharingan Focus, Read réussi permet de choisir outil de repli OU paume ; seul le premier choix est exécutable, aucun élargissement supplémentaire des fenêtres. |

**Presets ranked proposés** — tous les ancêtres sont actifs.

| Budget | Nodes actifs | Total | Intention et renoncement |
|---|---|---:|---|
| 50 | `B1`, `B2`, `B3`, `B4` | 50 | Spécialiste Lecture et perception ; abandon des deux autres branches. |
| 80 | `B1`, `B2`, `B3`, `B4`, `A1`, `A2`, `A3` | 80 | Lecture et perception + premiers outils de Géométrie des lames ; renonce à A4 et à Feu et effacement. |
| 100 | `B1`, `B2`, `B3`, `B4`, `A1`, `A2`, `A3`, `A4` | 100 | Double spécialisation Lecture et perception/Géométrie des lames ; renonce entièrement à Feu et effacement. |

**Risque spécifique et limites :** Une illusion ne retire pas les commandes ; l’AI, le lock et la caméra ne doivent pas révéler automatiquement le vrai corps. Ne pas élargir les fenêtres de défense jusqu’à rendre la lecture automatique ; Mangekyō/Tsukuyomi/Amaterasu des vieux blueprints ne deviennent pas baseline.

**Maîtrise à tester :** débutant = boucle du kit de base sans capstone ; intermédiaire = branche choisie + lecture d’une défense adverse ; expert = alterner les conversions permises selon position/ressource et abandonner une extension risquée. La progression ne remplace pas ce travail d’exécution.

### 05 — Neji

**Statut :** CORE4 jouable techniquement ; feel natif non certifié ici. **Filiation :** S08/S11/S12 et fiche active.

| taijutsu | vitesse | chakra | contrôle chakra | ninjutsu | genjutsu | défense | portée | mobilité | intelligence/lecture | outils/armes | difficulté |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 10 | 8 | 7 | 10 | 4 | 3 | 9 | 4 | 8 | 9 | 4 | 8 |

**Kit à zéro point et identité :** Noyau distant : paumes, tenketsu, garde Byakugan avec angle mort, Rotation, VacuumPalm et SixtyFourPalms. Footwork circulaire et faible allonge, outil secondaire. Les 64 paumes et le drain existent déjà ; aucun achat nécessaire pour rendre Gentle Fist identitaire. Byakugan Full Field existant est à auditer sans supprimer ses règles en silence.

**Branche A — Paumes et angles** (50 points cumulés).

| Node | Coût | Prérequis actif | Effet concret et signal de combat |
|---|---:|---|---|
| `A1` | 5 | Kit de base | Paume précise : dégâts corporels +2 %, drain inchangé. |
| `A2` | 10 | `A1` | Paume tournante : après Light1 confirmé, direction latérale déplace Neji à l’extérieur du bras et remplace Light2 ; pas de fermeture tenketsu supplémentaire. |
| `A3` | 15 | `A2` | Deux temps : sur touche de VacuumPalm, choisir recul d’espacement plutôt que poursuite ; anneau de paume indique la poussée, ne permet pas de relancer un adversaire en réveil. |
| `A4` **capstone** | 20 | `A3` | 64, porte de sortie : au milieu de SixtyFourPalms, terminer plus tôt par expulsion latérale ; abandonne les touches/drains restants, donne placement et non dégâts additionnels. |

**Branche B — Cercle défensif** (50 points cumulés).

| Node | Coût | Prérequis actif | Effet concret et signal de combat |
|---|---:|---|---|
| `B1` | 5 | Kit de base | Garde stable : coût de stamina de garde réduit de 2 % ; aucun angle ajouté. |
| `B2` | 10 | `B1` | Rotation dirigée : choisir un demi-cercle frontal moins long au lieu du dôme ; même coût, sortie plus tôt et dos exposé ; pas de protection après la fenêtre active. |
| `B3` | 15 | `B2` | Déviation de réception : après une tech murale réussie, Tool dévie un projectile frontal pendant 0,12 s ; remplace la riposte de tech, aucun renvoi garanti vers le tireur. |
| `B4` **capstone** | 20 | `B3` | Cercle mobile : Rotation peut finir par un pas tangent de 3 studs ; centre du dôme reste à l’origine, garde inactive pendant le pas, récupération finale conservée. |

**Branche C — Contrôle des tenketsu** (50 points cumulés).

| Node | Coût | Prérequis actif | Effet concret et signal de combat |
|---|---:|---|---|
| `C1` | 5 | Kit de base | Chakra exact : coût VacuumPalm réduit de 2 %. |
| `C2` | 10 | `C1` | Point de rupture : un Heavy confirmé consomme deux points tenketsu déjà posés pour interrompre une recharge active ; ne silence pas les jutsu, pas de gain sur garde. |
| `C3` | 15 | `C2` | Marque expirante : à l’expiration d’un point, un indice de respiration renseigne Neji sur le retour de chakra ; information locale, aucun nouveau drain ni wallhack. |
| `C4` **capstone** | 20 | `C3` | Champ, lecture de sortie : pendant Full Field, une fermeture de point confirmée montre brièvement le secteur de sortie choisi lors de la prochaine substitution ; donnée après engagement, pas prédiction automatique ni frappe gratuite. |

**Presets ranked proposés** — tous les ancêtres sont actifs.

| Budget | Nodes actifs | Total | Intention et renoncement |
|---|---|---:|---|
| 50 | `A1`, `A2`, `A3`, `A4` | 50 | Spécialiste Paumes et angles ; abandon des deux autres branches. |
| 80 | `A1`, `A2`, `A3`, `A4`, `B1`, `B2`, `B3` | 80 | Paumes et angles + premiers outils de Cercle défensif ; renonce à B4 et à Contrôle des tenketsu. |
| 100 | `A1`, `A2`, `A3`, `A4`, `B1`, `B2`, `B3`, `B4` | 100 | Double spécialisation Paumes et angles/Cercle défensif ; renonce entièrement à Contrôle des tenketsu. |

**Risque spécifique et limites :** Drain + réduction de régénération + verrou jutsu peut créer un verrou permanent ; les nouveaux nodes n’augmentent pas ces trois effets ensemble. Angle mort et armes longues doivent garder une valeur ; pas d’immunité globale aux illusions ajoutée par progression.

**Maîtrise à tester :** débutant = boucle du kit de base sans capstone ; intermédiaire = branche choisie + lecture d’une défense adverse ; expert = alterner les conversions permises selon position/ressource et abandonner une extension risquée. La progression ne remplace pas ce travail d’exécution.

### 06 — Gaara

**Statut :** Sand serveur/tests, caché ; activation distincte requise. **Filiation :** S09/S10.

| taijutsu | vitesse | chakra | contrôle chakra | ninjutsu | genjutsu | défense | portée | mobilité | intelligence/lecture | outils/armes | difficulté |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 4 | 4 | 9 | 8 | 9 | 3 | 10 | 9 | 4 | 7 | 3 | 7 |

**Kit à zéro point et identité :** Serveur/tests distants présents, caché en UI. Sable à longue amorce, pilier, SandCoffin, SandShuriken, DesertWave, bouclier à charges et déplacement de sable. Noyau lent, défense conditionnelle lisible ; chaque charge brisée est visible. Pas d’activation du personnage par ce document.

**Branche A — Pression minérale** (50 points cumulés).

| Node | Coût | Prérequis actif | Effet concret et signal de combat |
|---|---:|---|---|
| `A1` | 5 | Kit de base | Sable dosé : dégâts du sable +2 %. |
| `A2` | 10 | `A1` | Lash latéral : Light2 directionnel contourne un couvert par un arc annoncé, sans traverser de collider ; échange portée contre largeur. |
| `A3` | 15 | `A2` | Pilier penché : un launcher confirmé peut expulser en biais plutôt que verticalement ; colonne inclinée visible et poursuite standard. |
| `A4` **capstone** | 20 | `A3` | Coffin ouvert : relâcher tôt SandCoffin projette vers un mur au lieu de broyer ; dégâts réduits de moitié, une seule conversion et substitution possible. |

**Branche B — Forteresse faillible** (50 points cumulés).

| Node | Coût | Prérequis actif | Effet concret et signal de combat |
|---|---:|---|---|
| `B1` | 5 | Kit de base | Sable tassé : consommation de stamina de garde -2 %. |
| `B2` | 10 | `B1` | Écran choisi : sacrifier une charge de bouclier pour un panneau frontal de 1 s, traversable par les corps ; aucun bouclier automatique pendant sa présence. |
| `B3` | 15 | `B2` | Sortie du sable : substitution légale laisse un tas inerte qui bloque une lame, puis disparaît ; aucune charge restaurée. |
| `B4` **capstone** | 20 | `B3` | Rempart fendu : panneau transformable en deux pans séparés par une sortie centrale ; même surface totale et même durée, l’adversaire peut passer au milieu. |

**Branche C — Territoire** (50 points cumulés).

| Node | Coût | Prérequis actif | Effet concret et signal de combat |
|---|---:|---|---|
| `C1` | 5 | Kit de base | Gourde profonde : chakra maximal +3 %. |
| `C2` | 10 | `C1` | Nappe brève : DesertWave peut laisser une zone de sable de 2 s qui signale les pas, sans ralentissement ; une seule nappe. |
| `C3` | 15 | `C2` | Reflux mural : depuis un mur, descendre par un rideau de sable plutôt qu’un dive ; trajectoire visible, impossible d’attaquer pendant la descente. |
| `C4` **capstone** | 20 | `C3` | Éveil, dune offensive : pendant l’éveil, consommer toutes les charges disponibles pour déplacer une nappe de 6 studs ; bouclier inactif jusqu’à fin de l’action, aucun regain de charges. |

**Presets ranked proposés** — tous les ancêtres sont actifs.

| Budget | Nodes actifs | Total | Intention et renoncement |
|---|---|---:|---|
| 50 | `B1`, `B2`, `B3`, `B4` | 50 | Spécialiste Forteresse faillible ; abandon des deux autres branches. |
| 80 | `B1`, `B2`, `B3`, `B4`, `C1`, `C2`, `C3` | 80 | Forteresse faillible + premiers outils de Territoire ; renonce à C4 et à Pression minérale. |
| 100 | `B1`, `B2`, `B3`, `B4`, `C1`, `C2`, `C3`, `C4` | 100 | Double spécialisation Forteresse faillible/Territoire ; renonce entièrement à Pression minérale. |

**Risque spécifique et limites :** Bouclier automatique + zoning peut gagner sans engagement ; pas de regen des charges pendant pression. Les piliers ne doivent pas casser caméra/navigation ni enfermer dans un coin.

**Maîtrise à tester :** débutant = boucle du kit de base sans capstone ; intermédiaire = branche choisie + lecture d’une défense adverse ; expert = alterner les conversions permises selon position/ressource et abandonner une extension risquée. La progression ne remplace pas ce travail d’exécution.

### 07 — Kakashi

**Statut :** Candidat de design, aucun kit jouable affirmé. **Filiation :** S09/S10.

| taijutsu | vitesse | chakra | contrôle chakra | ninjutsu | genjutsu | défense | portée | mobilité | intelligence/lecture | outils/armes | difficulté |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 8 | 8 | 5 | 9 | 8 | 6 | 6 | 7 | 8 | 10 | 8 | 9 |

**Kit à zéro point et identité :** Candidat blueprint : jeune tacticien au sabre court, entrée par outil puis frappe de précision. Base proposée : taijutsu économique, kunai, sabre, écran de terre frontal unique et poussée foudre engagée ; lecture manuelle d’un comportement répété. Sharingan découvert = éveil d’information, jamais copie de code adverse.

**Branche A — Lame et approche** (50 points cumulés).

| Node | Coût | Prérequis actif | Effet concret et signal de combat |
|---|---:|---|---|
| `A1` | 5 | Kit de base | Tranchant propre : dégâts d’arme +2 %. |
| `A2` | 10 | `A1` | Taille de reprise : après kunai confirmé, Light donne une coupe courte plutôt qu’un dash ; portée du sabre inchangée. |
| `A3` | 15 | `A2` | Fourreau aérien : Air2 peut rengainer et finir par un talon descendant ; remplace le slam, pas d’arme invisible active. |
| `A4` **capstone** | 20 | `A3` | Croix de lame : sur parade réussie, choisir coupe horizontale ou poussée ; chemins affichés par appui/épaule et un seul impact. |

**Branche B — Adaptation** (50 points cumulés).

| Node | Coût | Prérequis actif | Effet concret et signal de combat |
|---|---:|---|---|
| `B1` | 5 | Kit de base | Préparation sobre : coût de l’écran de terre -2 %. |
| `B2` | 10 | `B1` | Note tactique : après deux mêmes actions observées, affiche leur télégraphe plus distinctement pendant 3 s ; aucun bonus de défense automatique. |
| `B3` | 15 | `B2` | Contre préparé : avant match choisir une réponse anti-dash ou anti-projectile ; Heavy après parade correspondante ouvre cette réponse, pas les deux. |
| `B4` **capstone** | 20 | `B3` | Réponse copiée : après une lecture réussie, Tool remplace un lancer par une feinte générique du type adverse ; animation propre à Kakashi, aucun vol de signature. |

**Branche C — Foudre et couvert** (50 points cumulés).

| Node | Coût | Prérequis actif | Effet concret et signal de combat |
|---|---:|---|---|
| `C1` | 5 | Kit de base | Réserve de mission : chakra maximal +3 %. |
| `C2` | 10 | `C1` | Foudre retenue : Cancel précoce quitte la poussée foudre avec recovery, moitié coût payé et cooldown entier. |
| `C3` | 15 | `C2` | Mur de détour : écran de terre oblique plutôt que frontal ; bloque aussi ses propres projectiles et expire en 2 s. |
| `C4` **capstone** | 20 | `C3` | Éveil, décision exposée : en Sharingan découvert, une lecture réussie autorise un déplacement vers un bord de son écran ; consomme l’écran et 20 chakra, arrivée sans garde. |

**Presets ranked proposés** — tous les ancêtres sont actifs.

| Budget | Nodes actifs | Total | Intention et renoncement |
|---|---|---:|---|
| 50 | `B1`, `B2`, `B3`, `B4` | 50 | Spécialiste Adaptation ; abandon des deux autres branches. |
| 80 | `B1`, `B2`, `B3`, `B4`, `A1`, `A2`, `A3` | 80 | Adaptation + premiers outils de Lame et approche ; renonce à A4 et à Foudre et couvert. |
| 100 | `B1`, `B2`, `B3`, `B4`, `A1`, `A2`, `A3`, `A4` | 100 | Double spécialisation Adaptation/Lame et approche ; renonce entièrement à Foudre et couvert. |

**Risque spécifique et limites :** Ne pas devenir meilleur que Sasuke, Minato et Itachi dans leur spécialité ; copie limitée à une réponse préconçue, aucune acquisition permanente d’aptitude ni Kamui.

**Maîtrise à tester :** débutant = boucle du kit de base sans capstone ; intermédiaire = branche choisie + lecture d’une défense adverse ; expert = alterner les conversions permises selon position/ressource et abandonner une extension risquée. La progression ne remplace pas ce travail d’exécution.

### 08 — Shisui

**Statut :** Candidat de design, aucun kit jouable affirmé. **Filiation :** S09/S10.

| taijutsu | vitesse | chakra | contrôle chakra | ninjutsu | genjutsu | défense | portée | mobilité | intelligence/lecture | outils/armes | difficulté |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 8 | 10 | 6 | 9 | 6 | 9 | 5 | 5 | 10 | 9 | 7 | 9 |

**Kit à zéro point et identité :** Candidat blueprint : burst corporel, arrêt net, sabre court, afterimage visuelle et feu bref. Base proposée : déplacement rapide collisionné, leurre unique sans dégâts, feinte et contre commandé. Aucune téléportation de sceau ; éveil de flicker qui change la prise d’angle.

**Branche A — Corps éclair** (50 points cumulés).

| Node | Coût | Prérequis actif | Effet concret et signal de combat |
|---|---:|---|---|
| `A1` | 5 | Kit de base | Premier appui : vitesse de course +2 %. |
| `A2` | 10 | `A1` | Rush cassé : à mi-distance du rush, choisir arrêt anticipé ; aucun hit ni iframe après arrêt, poussière révèle l’appui. |
| `A3` | 15 | `A2` | Crochet mural : sortie de wallrun en coupe tangentielle plutôt que dive ; consomme la conversion mur et expose la descente. |
| `A4` **capstone** | 20 | `A3` | Deux appuis : après une touche de rush, second burst latéral au lieu du finisher ; paie 18 chakra, aucun hit garanti, séquence aérienne non réinitialisée. |

**Branche B — Positions fantômes** (50 points cumulés).

| Node | Coût | Prérequis actif | Effet concret et signal de combat |
|---|---:|---|---|
| `B1` | 5 | Kit de base | Ombre mesurée : coût du leurre -2 %. |
| `B2` | 10 | `B1` | Retard d’ombre : afterimage rejoue un seul début de frappe avec 0,25 s de retard ; non physique, son différent au contact. |
| `B3` | 15 | `B2` | Leurre bas : substitution laisse une silhouette accroupie de 0,8 s ; charge et délai de riposte inchangés. |
| `B4` **capstone** | 20 | `B3` | Angle substituable : avant le rush, le joueur choisit laquelle de deux trajectoires dessinées sera réelle ; choix verrouillé avant départ, aucune permutation réactive. |

**Branche C — Frappe et perception** (50 points cumulés).

| Node | Coût | Prérequis actif | Effet concret et signal de combat |
|---|---:|---|---|
| `C1` | 5 | Kit de base | Coupe précise : dégâts taijutsu +2 %. |
| `C2` | 10 | `C1` | Contre d’épaule : après perfect dodge, Light coupe depuis le côté choisi au lieu d’avancer ; portée courte. |
| `C3` | 15 | `C2` | Feu de recul : projectile de feu peut être lancé en recul, mais recovery à l’atterrissage empêche rush immédiat. |
| `C4` **capstone** | 20 | `C3` | Éveil, ombre d’issue : en flicker, le leurre indique une route et le corps doit prendre l’autre ; seconde route audible, coût chakra par usage, pas de corps invulnérable. |

**Presets ranked proposés** — tous les ancêtres sont actifs.

| Budget | Nodes actifs | Total | Intention et renoncement |
|---|---|---:|---|
| 50 | `A1`, `A2`, `A3`, `A4` | 50 | Spécialiste Corps éclair ; abandon des deux autres branches. |
| 80 | `A1`, `A2`, `A3`, `A4`, `B1`, `B2`, `B3` | 80 | Corps éclair + premiers outils de Positions fantômes ; renonce à B4 et à Frappe et perception. |
| 100 | `A1`, `A2`, `A3`, `A4`, `B1`, `B2`, `B3`, `B4` | 100 | Double spécialisation Corps éclair/Positions fantômes ; renonce entièrement à Frappe et perception. |

**Risque spécifique et limites :** Silhouettes, caméra et sons doivent laisser une piste juste ; pas d’invisibilité permanente, Kotoamatsukami ni contrôle mental inévitable.

**Maîtrise à tester :** débutant = boucle du kit de base sans capstone ; intermédiaire = branche choisie + lecture d’une défense adverse ; expert = alterner les conversions permises selon position/ressource et abandonner une extension risquée. La progression ne remplace pas ce travail d’exécution.

### 09 — Rock Lee

**Statut :** Candidat de design, aucun kit jouable affirmé. **Filiation :** S09/S10.

| taijutsu | vitesse | chakra | contrôle chakra | ninjutsu | genjutsu | défense | portée | mobilité | intelligence/lecture | outils/armes | difficulté |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 10 | 10 | 4 | 6 | 1 | 1 | 7 | 3 | 10 | 7 | 3 | 8 |

**Kit à zéro point et identité :** Candidat blueprint : boxe/kicks très physiques, sprint en appuis, launcher et prise tournante, outils secondaires. Base proposée : rush physique, feinte de garde, lotus court avec prise confirmée et ouverture d’une Porte limitée ; les options air/mur de base ne sont pas verrouillées derrière les points.

**Branche A — Pression de pieds** (50 points cumulés).

| Node | Coût | Prérequis actif | Effet concret et signal de combat |
|---|---:|---|---|
| `A1` | 5 | Kit de base | Poings entraînés : dégâts corporels +2 %. |
| `A2` | 10 | `A1` | Balayage intérieur : Light2 arrière donne low court, abandonne le launcher de cette chaîne ; appui bas visible. |
| `A3` | 15 | `A2` | Reprise de coude : après heavy bloqué, choisir recul au lieu de follow-up ; ne cancel pas le whiff et ne crée pas de tour gratuit. |
| `A4` **capstone** | 20 | `A3` | Lotus de traverse : une prise aérienne confirmée peut jeter de côté plutôt que descendre ; même fin de juggle et tech à l’arrivée. |

**Branche B — Air et murs** (50 points cumulés).

| Node | Coût | Prérequis actif | Effet concret et signal de combat |
|---|---:|---|---|
| `B1` | 5 | Kit de base | Élan appris : contrôle aérien +2 %, vitesse maximale inchangée. |
| `B2` | 10 | `B1` | Rebond extérieur : walljump ouvre un kick sortant optionnel à la place du dive ; un usage par séquence. |
| `B3` | 15 | `B2` | Croisé aérien : Air1 confirmé permet side-switch de hanches remplaçant Air2 ; trajectoire et cible revalidées. |
| `B4` **capstone** | 20 | `B3` | Poursuite rasante : après knockback au sol, rush courbe de faible hauteur au lieu de poursuite verticale ; consomme la poursuite et reste interceptable. |

**Branche C — Discipline des Portes** (50 points cumulés).

| Node | Coût | Prérequis actif | Effet concret et signal de combat |
|---|---:|---|---|
| `C1` | 5 | Kit de base | Respiration de garde : drain de stamina en garde -2 %. |
| `C2` | 10 | `C1` | Contre de réception : après landing parfait, garde fraîche ouvre une paume courte ; ni super-armure ni dégâts sur simple atterrissage. |
| `C3` | 15 | `C2` | Porte refermée : arrêt volontaire de l’éveil pour réduire sa fatigue finale de moitié ; perd tout temps restant, activation non remboursée. |
| `C4` **capstone** | 20 | `C3` | Porte, appuis rompus : durant l’éveil, un seul cancel hit-confirmé vers rush latéral ; 20 chakra et fatigue finale de 1 s sans attaque, pas de reset de juggle. |

**Presets ranked proposés** — tous les ancêtres sont actifs.

| Budget | Nodes actifs | Total | Intention et renoncement |
|---|---|---:|---|
| 50 | `B1`, `B2`, `B3`, `B4` | 50 | Spécialiste Air et murs ; abandon des deux autres branches. |
| 80 | `B1`, `B2`, `B3`, `B4`, `A1`, `A2`, `A3` | 80 | Air et murs + premiers outils de Pression de pieds ; renonce à A4 et à Discipline des Portes. |
| 100 | `B1`, `B2`, `B3`, `B4`, `A1`, `A2`, `A3`, `A4` | 100 | Double spécialisation Air et murs/Pression de pieds ; renonce entièrement à Discipline des Portes. |

**Risque spécifique et limites :** Pas de boucle rush/launcher/lotus ; la faible magie ne doit pas supprimer les défenses universelles. Les Portes ont coût et fatigue, aucun dommage gratuit de collision pendant sprint.

**Maîtrise à tester :** débutant = boucle du kit de base sans capstone ; intermédiaire = branche choisie + lecture d’une défense adverse ; expert = alterner les conversions permises selon position/ressource et abandonner une extension risquée. La progression ne remplace pas ce travail d’exécution.

### 10 — Orochimaru

**Statut :** Candidat de design, aucun kit jouable affirmé. **Filiation :** S09/S10.

| taijutsu | vitesse | chakra | contrôle chakra | ninjutsu | genjutsu | défense | portée | mobilité | intelligence/lecture | outils/armes | difficulté |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 6 | 7 | 8 | 9 | 9 | 7 | 6 | 10 | 8 | 9 | 7 | 10 |

**Kit à zéro point et identité :** Candidat blueprint : jeune spécialiste d’allonge étrange. Base proposée : frappes souples, thrust serpent annoncé, serpent physique unique à 1 PV, leurre de peau visuel et kunai ; éveil d’instinct serpent sans régénération. Faible contrôle à très courte distance après un whiff.

**Branche A — Corps souple** (50 points cumulés).

| Node | Coût | Prérequis actif | Effet concret et signal de combat |
|---|---:|---|---|
| `A1` | 5 | Kit de base | Articulation juste : dégâts taijutsu +2 %. |
| `A2` | 10 | `A1` | Coude étiré : finisher peut allonger la portée de 2 studs en réduisant sa largeur de moitié ; bras télégraphié et recovery +0,15 s. |
| `A3` | 15 | `A2` | Retrait bas : sur perfect dodge, recul reptilien sans attaque remplace la riposte ; hurtbox reste réelle. |
| `A4` **capstone** | 20 | `A3` | Nœud corporel : après grab confirmé, projection autour de soi plutôt qu’avant ; aucun maintien prolongé, sortie tech standard. |

**Branche B — Serpent préparé** (50 points cumulés).

| Node | Coût | Prérequis actif | Effet concret et signal de combat |
|---|---:|---|---|
| `B1` | 5 | Kit de base | Invocation sobre : coût du serpent -2 %. |
| `B2` | 10 | `B1` | Sentinelle basse : serpent posé surveille un cône pendant 3 s ; attaque seulement sur ordre et disparaît après une frappe. |
| `B3` | 15 | `B2` | Serpent de paroi : même entité peut suivre un mur visible ; aucun passage derrière un obstacle sans LOS à l’ordre. |
| `B4` **capstone** | 20 | `B3` | Morsure de détour : sacrifier le serpent pour déplacer la direction du thrust déjà préparé avant son engagement ; pas de virage pendant activité. |

**Branche C — Mue et ruse** (50 points cumulés).

| Node | Coût | Prérequis actif | Effet concret et signal de combat |
|---|---:|---|---|
| `C1` | 5 | Kit de base | Réserve souple : chakra maximal +3 %. |
| `C2` | 10 | `C1` | Peau abandonnée : substitution légale laisse une mue à 1 PV pendant 1 s ; elle n’absorbe qu’un projectile, aucun soin. |
| `C3` | 15 | `C2` | Feinte sifflée : Cancel au premier tiers du thrust laisse le son mais retire la frappe ; moitié coût et cooldown complet. |
| `C4` **capstone** | 20 | `C3` | Éveil, trajectoire serpentine : en instinct serpent, rush peut prendre une courbe prédéfinie ; courbe tracée au sol, vitesse inchangée, pas d’intangibilité. |

**Presets ranked proposés** — tous les ancêtres sont actifs.

| Budget | Nodes actifs | Total | Intention et renoncement |
|---|---|---:|---|
| 50 | `B1`, `B2`, `B3`, `B4` | 50 | Spécialiste Serpent préparé ; abandon des deux autres branches. |
| 80 | `B1`, `B2`, `B3`, `B4`, `A1`, `A2`, `A3` | 80 | Serpent préparé + premiers outils de Corps souple ; renonce à A4 et à Mue et ruse. |
| 100 | `B1`, `B2`, `B3`, `B4`, `A1`, `A2`, `A3`, `A4` | 100 | Double spécialisation Serpent préparé/Corps souple ; renonce entièrement à Mue et ruse. |

**Risque spécifique et limites :** Allonge cachée et hurtbox variable difficiles à lire ; corps réel toujours touchable. Pas d’immortalité, réincarnation, Edo Tensei ni arsenal adulte.

**Maîtrise à tester :** débutant = boucle du kit de base sans capstone ; intermédiaire = branche choisie + lecture d’une défense adverse ; expert = alterner les conversions permises selon position/ressource et abandonner une extension risquée. La progression ne remplace pas ce travail d’exécution.

### 11 — Nagato

**Statut :** Candidat de design, aucun kit jouable affirmé. **Filiation :** S10, pool utilisateur du 13 octobre.

| taijutsu | vitesse | chakra | contrôle chakra | ninjutsu | genjutsu | défense | portée | mobilité | intelligence/lecture | outils/armes | difficulté |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 4 | 4 | 10 | 6 | 10 | 5 | 6 | 10 | 4 | 7 | 3 | 10 |

**Kit à zéro point et identité :** Pool prioritaire : gravité locale coûteuse, pas les six Voies complètes. Base proposée GAMEPLAY_LIBERTY : poings défensifs, kunai, courte répulsion frontale, attraction à canal interrompable et impulsion aérienne unique ; éveil de polarité, lent et fragile en recovery.

**Branche A — Répulsion** (50 points cumulés).

| Node | Coût | Prérequis actif | Effet concret et signal de combat |
|---|---:|---|---|
| `A1` | 5 | Kit de base | Impulsion dosée : dégâts de répulsion +2 %. |
| `A2` | 10 | `A1` | Éventail repoussé : choisir cône étroit plus long plutôt que cône large, mêmes dégâts et bords visibles. |
| `A3` | 15 | `A2` | Déviation oblique : après parade, repousser un projectile sur une tangente, jamais le renvoyer automatiquement au tireur. |
| `A4` **capstone** | 20 | `A3` | Contre-onde : répulsion confirmée vers mur donne le choix stop court ou wallsplat ; le stop abandonne tout follow-up garanti. |

**Branche B — Attraction contrainte** (50 points cumulés).

| Node | Coût | Prérequis actif | Effet concret et signal de combat |
|---|---:|---|---|
| `B1` | 5 | Kit de base | Canal précis : coût attraction -2 %. |
| `B2` | 10 | `B1` | Tirage latéral : déplacer la cible le long d’un axe annoncé, portée et distance plafonnées ; garde/dodge restent actifs. |
| `B3` | 15 | `B2` | Rupture de canal : Cancel libère immédiatement la cible et fait reculer Nagato ; aucun dégât, moitié coût payé. |
| `B4` **capstone** | 20 | `B3` | Orbite brève : après attraction confirmée, choisir expulsion tangentielle plutôt que rapprochement ; une trajectoire, 0,3 s maximum de contrainte. |

**Branche C — Polarité** (50 points cumulés).

| Node | Coût | Prérequis actif | Effet concret et signal de combat |
|---|---:|---|---|
| `C1` | 5 | Kit de base | Profondeur : chakra maximal +3 %. |
| `C2` | 10 | `C1` | Ancre gravitaire : zone visible unique de 2 s qui infléchit ses propres projectiles, sans capturer ceux de l’autre. |
| `C3` | 15 | `C2` | Chute contrôlée : impulsion aérienne peut devenir frein de descente ; pas de hover, consomme la poursuite disponible. |
| `C4` **capstone** | 20 | `C3` | Éveil, inversion : pendant polarité, convertir son ancre en onde qui pousse OU attire sur 4 studs ; détruit l’ancre, 30 chakra et recovery 0,8 s. |

**Presets ranked proposés** — tous les ancêtres sont actifs.

| Budget | Nodes actifs | Total | Intention et renoncement |
|---|---|---:|---|
| 50 | `A1`, `A2`, `A3`, `A4` | 50 | Spécialiste Répulsion ; abandon des deux autres branches. |
| 80 | `A1`, `A2`, `A3`, `A4`, `B1`, `B2`, `B3` | 80 | Répulsion + premiers outils de Attraction contrainte ; renonce à B4 et à Polarité. |
| 100 | `A1`, `A2`, `A3`, `A4`, `B1`, `B2`, `B3`, `B4` | 100 | Double spécialisation Répulsion/Attraction contrainte ; renonce entièrement à Polarité. |

**Risque spécifique et limites :** Attraction ne doit pas enlever déplacement et défense pendant plusieurs secondes ; pas de one-shot, résurrection ni satellite géant. Son interprétation jeune et ses pouvoirs restent entièrement à justifier.

**Maîtrise à tester :** débutant = boucle du kit de base sans capstone ; intermédiaire = branche choisie + lecture d’une défense adverse ; expert = alterner les conversions permises selon position/ressource et abandonner une extension risquée. La progression ne remplace pas ce travail d’exécution.

### 12 — Killer Bee

**Statut :** Candidat de design, aucun kit jouable affirmé. **Filiation :** S10, pool utilisateur du 13 octobre.

| taijutsu | vitesse | chakra | contrôle chakra | ninjutsu | genjutsu | défense | portée | mobilité | intelligence/lecture | outils/armes | difficulté |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 9 | 8 | 9 | 7 | 6 | 3 | 8 | 7 | 8 | 7 | 10 | 9 |

**Kit à zéro point et identité :** Pool prioritaire : rythme d’armes et acrobatie. Base proposée : deux lames réellement actives, transition vers taijutsu, lancer unique et charge d’épaule ; éveil de rythme bestial limité. Les lames décoratives supplémentaires ne créent pas plusieurs hitboxes gratuites.

**Branche A — Cadence de lames** (50 points cumulés).

| Node | Coût | Prérequis actif | Effet concret et signal de combat |
|---|---:|---|---|
| `A1` | 5 | Kit de base | Acier propre : dégâts d’arme +2 %. |
| `A2` | 10 | `A1` | Contretemps : retarder la seconde coupe de 0,15 s, sans allonger le stun du premier coup ; permet garde entre deux. |
| `A3` | 15 | `A2` | Lame de relais : lancer une lame après contact remplace le finisher ; arme indisponible pendant son vol, retour après expiration. |
| `A4` **capstone** | 20 | `A3` | Cadence brisée : deux finishers possibles, coupe basse ou revers haut ; choix d’appui avant activité, mêmes dégâts totaux. |

**Branche B — Corps acrobatique** (50 points cumulés).

| Node | Coût | Prérequis actif | Effet concret et signal de combat |
|---|---:|---|---|
| `B1` | 5 | Kit de base | Appui léger : contrôle aérien +2 %. |
| `B2` | 10 | `B1` | Épaule oblique : charge peut prendre l’angle gauche/droit choisi au départ ; gros whiff conservé. |
| `B3` | 15 | `B2` | Vrille de paroi : kick sortant de walljump plutôt que coupe, consomme route murale et finit au sol. |
| `B4` **capstone** | 20 | `B3` | Prise rythmée : grab confirmé peut lancer vers haut puis terminer par un seul kick ; remplace lancer et poursuite, pas de double récompense. |

**Branche C — Maîtrise bestiale** (50 points cumulés).

| Node | Coût | Prérequis actif | Effet concret et signal de combat |
|---|---:|---|---|
| `C1` | 5 | Kit de base | Souffle ample : chakra maximal +3 %. |
| `C2` | 10 | `C1` | Garde armée : parade réussie autorise rengainement + recul ; renonce à la riposte pour revenir au neutral. |
| `C3` | 15 | `C2` | Substitution syncopée : apparition dans une orientation choisie, même distance et délai offensif ; aucun leurre supplémentaire. |
| `C4` **capstone** | 20 | `C3` | Éveil, percussion : pendant rythme bestial, Light2 peut devenir coup d’épaule court qui pousse plutôt que tranche ; coût 18 chakra, pas d’armure. |

**Presets ranked proposés** — tous les ancêtres sont actifs.

| Budget | Nodes actifs | Total | Intention et renoncement |
|---|---|---:|---|
| 50 | `A1`, `A2`, `A3`, `A4` | 50 | Spécialiste Cadence de lames ; abandon des deux autres branches. |
| 80 | `A1`, `A2`, `A3`, `A4`, `B1`, `B2`, `B3` | 80 | Cadence de lames + premiers outils de Corps acrobatique ; renonce à B4 et à Maîtrise bestiale. |
| 100 | `A1`, `A2`, `A3`, `A4`, `B1`, `B2`, `B3`, `B4` | 100 | Double spécialisation Cadence de lames/Corps acrobatique ; renonce entièrement à Maîtrise bestiale. |

**Risque spécifique et limites :** Nombre de lames/contacts et grandes zones peuvent saturer garde et lisibilité ; pas de forme Bijū géante ni régénération permanente.

**Maîtrise à tester :** débutant = boucle du kit de base sans capstone ; intermédiaire = branche choisie + lecture d’une défense adverse ; expert = alterner les conversions permises selon position/ressource et abandonner une extension risquée. La progression ne remplace pas ce travail d’exécution.

### 13 — Obito

**Statut :** Candidat de design, aucun kit jouable affirmé. **Filiation :** S10, pool utilisateur du 13 octobre.

| taijutsu | vitesse | chakra | contrôle chakra | ninjutsu | genjutsu | défense | portée | mobilité | intelligence/lecture | outils/armes | difficulté |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 6 | 6 | 7 | 6 | 7 | 6 | 6 | 6 | 7 | 6 | 6 | 9 |

**Kit à zéro point et identité :** Pool prioritaire : jeune feu/outils, maladresse volontaire et angles de fuite. Base proposée : string courte, boule de feu, kunai lié, leurre de substitution et contre d’esquive ; éveil de perception. Phase limitée traitée comme liberté de design, jamais Kamui adulte disponible de base.

**Branche A — Feu de poursuite** (50 points cumulés).

| Node | Coût | Prérequis actif | Effet concret et signal de combat |
|---|---:|---|---|
| `A1` | 5 | Kit de base | Katon stable : dégâts feu +2 %. |
| `A2` | 10 | `A1` | Boule décalée : lancer depuis un pas latéral au lieu de frontal ; mouvement avant projectile, pas de tir à travers mur. |
| `A3` | 15 | `A2` | Kunai incendié : une seule lame peut porter braise puis s’éteint au premier impact ; remplace une partie des dégâts feu, aucun DOT cumulable. |
| `A4` **capstone** | 20 | `A3` | Rideau percé : Fireball peut s’ouvrir en deux petites boules séparées par une ligne sûre ; dégâts totaux identiques. |

**Branche B — Angles de survie** (50 points cumulés).

| Node | Coût | Prérequis actif | Effet concret et signal de combat |
|---|---:|---|---|
| `B1` | 5 | Kit de base | Reprise d’appui : contrôle aérien +2 %. |
| `B2` | 10 | `B1` | Glissade extérieure : après perfect dodge, un pas tangent plutôt que riposte ; vulnérable en sortie. |
| `B3` | 15 | `B2` | Fil de fuite : substitution vers une extrémité de fil déjà placé, dans distance normale ; détruit le fil et coûte charge habituelle. |
| `B4` **capstone** | 20 | `B3` | Feinte traversée : rush vers une silhouette puis arrêt juste avant elle ; aucune traversée de corps/collider, feinte punissable. |

**Branche C — Perception et phase** (50 points cumulés).

| Node | Coût | Prérequis actif | Effet concret et signal de combat |
|---|---:|---|---|
| `C1` | 5 | Kit de base | Lecture calme : coût du leurre -2 %. |
| `C2` | 10 | `C1` | Observation frontale : garde fraîche met en évidence un télégraphe déjà visible, sans fenêtre défensive accrue. |
| `C3` | 15 | `C2` | Phase choisie : en neutral, posture de 0,25 s esquive une seule frappe frontale ; 25 chakra, aucun déplacement/attaque, 0,5 s recovery ; remplace le contre d’esquive. |
| `C4` **capstone** | 20 | `C3` | Éveil, phase de sortie : en perception éveillée, la phase réussie peut finir par recul de 3 studs ; aucun autre cancel, ni usage pendant hitstun. |

**Presets ranked proposés** — tous les ancêtres sont actifs.

| Budget | Nodes actifs | Total | Intention et renoncement |
|---|---|---:|---|
| 50 | `B1`, `B2`, `B3`, `B4` | 50 | Spécialiste Angles de survie ; abandon des deux autres branches. |
| 80 | `B1`, `B2`, `B3`, `B4`, `C1`, `C2`, `C3` | 80 | Angles de survie + premiers outils de Perception et phase ; renonce à C4 et à Feu de poursuite. |
| 100 | `B1`, `B2`, `B3`, `B4`, `C1`, `C2`, `C3`, `C4` | 100 | Double spécialisation Angles de survie/Perception et phase ; renonce entièrement à Feu de poursuite. |

**Risque spécifique et limites :** Intangibilité réactive sans coût gagne les échanges ; aucune attaque pendant phase, prise et zones doivent avoir réponse lisible. Ne pas importer arsenal de guerre.

**Maîtrise à tester :** débutant = boucle du kit de base sans capstone ; intermédiaire = branche choisie + lecture d’une défense adverse ; expert = alterner les conversions permises selon position/ressource et abandonner une extension risquée. La progression ne remplace pas ce travail d’exécution.

### 14 — Kimimaro

**Statut :** Candidat de design, aucun kit jouable affirmé. **Filiation :** S10, pool utilisateur du 13 octobre.

| taijutsu | vitesse | chakra | contrôle chakra | ninjutsu | genjutsu | défense | portée | mobilité | intelligence/lecture | outils/armes | difficulté |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 9 | 7 | 7 | 8 | 6 | 2 | 9 | 8 | 7 | 7 | 8 | 8 |

**Kit à zéro point et identité :** Pool prioritaire : arme corporelle, lances osseuses courtes et posture défensive. Base proposée : taijutsu pointu, lame d’os, pique de zone unique annoncé, blocage osseux actif et ruée ; éveil de densité sans guérison.

**Branche A — Danses offensives** (50 points cumulés).

| Node | Coût | Prérequis actif | Effet concret et signal de combat |
|---|---:|---|---|
| `A1` | 5 | Kit de base | Os précis : dégâts taijutsu +2 %. |
| `A2` | 10 | `A1` | Danse latérale : Light2 devient revers d’os à portée courte, change le côté et abandonne launcher. |
| `A3` | 15 | `A2` | Foret descendant : Air2 peut pointer vers sol avec trajectoire fixe ; remplace slam et garde son réveil protégé. |
| `A4` **capstone** | 20 | `A3` | Lance fragmentée : thrust peut se terminer par lancer de son extrémité ; perte d’allonge pendant 2 s, projectile unique et dégâts partagés. |

**Branche B — Armure active** (50 points cumulés).

| Node | Coût | Prérequis actif | Effet concret et signal de combat |
|---|---:|---|---|
| `B1` | 5 | Kit de base | Structure ferme : coût de garde -2 %. |
| `B2` | 10 | `B1` | Paroi d’avant-bras : garde fraîche absorbe une lame frontale, 15 chakra ; aucun renvoi ni recharge sur hit. |
| `B3` | 15 | `B2` | Contre de coude : parade physique réussie ouvre coude court qui écarte, pas un grab automatique. |
| `B4` **capstone** | 20 | `B3` | Carapace rompue : dépenser sa défense osseuse pour reculer derrière un débris à 1 PV ; aucun dommage du débris et défense indisponible 3 s. |

**Branche C — Piques et territoire** (50 points cumulés).

| Node | Coût | Prérequis actif | Effet concret et signal de combat |
|---|---:|---|---|
| `C1` | 5 | Kit de base | Moelle sobre : chakra maximal +3 %. |
| `C2` | 10 | `C1` | Pique oblique : choisir inclinaison du pique au placement, télégraphe de 0,5 s ; un seul pique. |
| `C3` | 15 | `C2` | Appui osseux : son pique peut servir de tremplin une fois puis casse ; consomme la conversion murale. |
| `C4` **capstone** | 20 | `C3` | Éveil, ossature de route : en densité, étendre une ligne de trois petits piques successifs plutôt qu’un grand ; même budget de dégâts, gaps franchissables et aucun multi-hit forcé. |

**Presets ranked proposés** — tous les ancêtres sont actifs.

| Budget | Nodes actifs | Total | Intention et renoncement |
|---|---|---:|---|
| 50 | `A1`, `A2`, `A3`, `A4` | 50 | Spécialiste Danses offensives ; abandon des deux autres branches. |
| 80 | `A1`, `A2`, `A3`, `A4`, `B1`, `B2`, `B3` | 80 | Danses offensives + premiers outils de Armure active ; renonce à B4 et à Piques et territoire. |
| 100 | `A1`, `A2`, `A3`, `A4`, `B1`, `B2`, `B3`, `B4` | 100 | Double spécialisation Danses offensives/Armure active ; renonce entièrement à Piques et territoire. |

**Risque spécifique et limites :** Lame corporelle doit avoir hurtbox/portée cohérentes ; armure ne doit pas autoriser attaque sans respecter les tours. Pas de forêt d’os couvrant toute l’arène.

**Maîtrise à tester :** débutant = boucle du kit de base sans capstone ; intermédiaire = branche choisie + lecture d’une défense adverse ; expert = alterner les conversions permises selon position/ressource et abandonner une extension risquée. La progression ne remplace pas ce travail d’exécution.

### 15 — Haku

**Statut :** Candidat de design, aucun kit jouable affirmé. **Filiation :** S10, pool utilisateur du 13 octobre.

| taijutsu | vitesse | chakra | contrôle chakra | ninjutsu | genjutsu | défense | portée | mobilité | intelligence/lecture | outils/armes | difficulté |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 6 | 9 | 7 | 9 | 8 | 5 | 5 | 9 | 10 | 8 | 9 | 9 |

**Kit à zéro point et identité :** Pool prioritaire : senbon, lignes de glace et réseau de miroirs réduit. Base proposée : paumes courtes, senbon fin, deux miroirs fragiles avec passage annoncé, vague de glace étroite ; éveil de réseau. Corps touchable entre les points.

**Branche A — Senbon précis** (50 points cumulés).

| Node | Coût | Prérequis actif | Effet concret et signal de combat |
|---|---:|---|---|
| `A1` | 5 | Kit de base | Aiguilles dosées : dégâts outils +2 %. |
| `A2` | 10 | `A1` | Éventail incliné : Tool aérien peut tirer horizontalement au lieu de descendre ; trois aiguilles maximum, dégâts partagés. |
| `A3` | 15 | `A2` | Aiguille d’arrêt : sur hit confirmé, une aiguille remplace finisher pour pousser hors axe ; aucun silence ni stun additionnel. |
| `A4` **capstone** | 20 | `A3` | Couture de glace : sur une surface gelée, faire rebondir une aiguille une fois ; ligne fine visible et perte de vitesse. |

**Branche B — Miroirs spatiaux** (50 points cumulés).

| Node | Coût | Prérequis actif | Effet concret et signal de combat |
|---|---:|---|---|
| `B1` | 5 | Kit de base | Glace fine : coût placement miroir -2 %. |
| `B2` | 10 | `B1` | Sortie basse : choisir sortie au pied du miroir plutôt qu’au centre ; arrivée annoncée et recovery identique. |
| `B3` | 15 | `B2` | Miroir de mur : un des deux miroirs peut être fixé au mur accessible ; mêmes limites de placement, caméra préserve les corps. |
| `B4` **capstone** | 20 | `B3` | Miroir sacrifié : détruire son miroir de destination pour une sortie tangentielle à 4 studs ; pas de nouvelle destination, passage suivant indisponible. |

**Branche C — Flux froid** (50 points cumulés).

| Node | Coût | Prérequis actif | Effet concret et signal de combat |
|---|---:|---|---|
| `C1` | 5 | Kit de base | Appui glissé : contrôle aérien +2 %. |
| `C2` | 10 | `C1` | Glissade froide : dash peut laisser une piste visuelle qui renseigne la trajectoire, sans ralentir l’autre ; aucun bonus de vitesse. |
| `C3` | 15 | `C2` | Substitution cristalline : sortie légale laisse un reflet 0,8 s, pas un miroir utilisable ni une troisième entité physique. |
| `C4` **capstone** | 20 | `C3` | Éveil, traversée en V : pendant réseau, autoriser deux segments entre miroirs mais une seule frappe finale ; coût de deux passages, pauses d’arrivée et destructibilité conservées. |

**Presets ranked proposés** — tous les ancêtres sont actifs.

| Budget | Nodes actifs | Total | Intention et renoncement |
|---|---|---:|---|
| 50 | `B1`, `B2`, `B3`, `B4` | 50 | Spécialiste Miroirs spatiaux ; abandon des deux autres branches. |
| 80 | `B1`, `B2`, `B3`, `B4`, `A1`, `A2`, `A3` | 80 | Miroirs spatiaux + premiers outils de Senbon précis ; renonce à A4 et à Flux froid. |
| 100 | `B1`, `B2`, `B3`, `B4`, `A1`, `A2`, `A3`, `A4` | 100 | Double spécialisation Miroirs spatiaux/Senbon précis ; renonce entièrement à Flux froid. |

**Risque spécifique et limites :** Téléport/sniper doit laisser des fenêtres ; pas de dôme qui emprisonne sans sortie. Les aiguilles ne peuvent pas verrouiller continuellement les commandes.

**Maîtrise à tester :** débutant = boucle du kit de base sans capstone ; intermédiaire = branche choisie + lecture d’une défense adverse ; expert = alterner les conversions permises selon position/ressource et abandonner une extension risquée. La progression ne remplace pas ce travail d’exécution.

### 16 — Shikamaru

**Statut :** Candidat de design, aucun kit jouable affirmé. **Filiation :** S10, pool utilisateur du 13 octobre.

| taijutsu | vitesse | chakra | contrôle chakra | ninjutsu | genjutsu | défense | portée | mobilité | intelligence/lecture | outils/armes | difficulté |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 4 | 5 | 5 | 9 | 7 | 6 | 5 | 9 | 4 | 10 | 8 | 10 |

**Kit à zéro point et identité :** Pool prioritaire : géométrie des ombres, fil et punition de route. Base proposée : string défensive courte, kunai, fil de zone unique, extension d’ombre visible conditionnelle à la surface et capture très brève avec défense possible ; éveil de planification.

**Branche A — Ombre géométrique** (50 points cumulés).

| Node | Coût | Prérequis actif | Effet concret et signal de combat |
|---|---:|---|---|
| `A1` | 5 | Kit de base | Tracé précis : coût de l’ombre -2 %. |
| `A2` | 10 | `A1` | Ombre coudée : un angle de 45 degrés fixé avant release, longueur totale inchangée et contour visible. |
| `A3` | 15 | `A2` | Passage de couvert : extension suit le bord d’un couvert plutôt que le traverser ; temps de trajet augmenté et LOS à l’engagement. |
| `A4` **capstone** | 20 | `A3` | Nœud d’ombre : sur capture confirmée, choisir expulsion courte ou maintien de 0,3 s ; aucun cumul avec capture initiale, maximum global 0,6 s. |

**Branche B — Outils de plan** (50 points cumulés).

| Node | Coût | Prérequis actif | Effet concret et signal de combat |
|---|---:|---|---|
| `B1` | 5 | Kit de base | Kunai juste : dégâts outils +2 %. |
| `B2` | 10 | `B1` | Fil de détour : placer un fil qui déclenche un son à traversée, sans bind ; une seule entité et durée 4 s. |
| `B3` | 15 | `B2` | Appât muet : lancer un kunai émoussé pour feinte, zéro dégâts mais amorce identique ; compteur d’outil consommé. |
| `B4` **capstone** | 20 | `B3` | Plan croisé : connecter son fil à l’extrémité de l’ombre pour changer sa direction une fois ; consomme le fil, pas de portée totale supplémentaire. |

**Branche C — Lecture et survie** (50 points cumulés).

| Node | Coût | Prérequis actif | Effet concret et signal de combat |
|---|---:|---|---|
| `C1` | 5 | Kit de base | Garde économe : coût garde -2 %. |
| `C2` | 10 | `C1` | Retraite calculée : après parade, recul + kunai au lieu de riposte ; projectile interceptable. |
| `C3` | 15 | `C2` | Substitution vers repère : choisir le côté de son fil dans rayon légal ; charge et fil consommés, aucune capture à l’arrivée. |
| `C4` **capstone** | 20 | `C3` | Éveil, seconde hypothèse : pendant planification, un Cancel précoce d’ombre autorise une autre direction télégraphiée ; repaie le chakra, n’efface pas la recovery du premier essai. |

**Presets ranked proposés** — tous les ancêtres sont actifs.

| Budget | Nodes actifs | Total | Intention et renoncement |
|---|---|---:|---|
| 50 | `A1`, `A2`, `A3`, `A4` | 50 | Spécialiste Ombre géométrique ; abandon des deux autres branches. |
| 80 | `A1`, `A2`, `A3`, `A4`, `B1`, `B2`, `B3` | 80 | Ombre géométrique + premiers outils de Outils de plan ; renonce à B4 et à Lecture et survie. |
| 100 | `A1`, `A2`, `A3`, `A4`, `B1`, `B2`, `B3`, `B4` | 100 | Double spécialisation Ombre géométrique/Outils de plan ; renonce entièrement à Lecture et survie. |

**Risque spécifique et limites :** Ombres dépendantes de l’éclairage artistique = imprévisibles ; employer une géométrie gameplay lisible. Pas de contrôle complet des inputs ni capture infinie. Le neutral sans piège doit rester viable.

**Maîtrise à tester :** débutant = boucle du kit de base sans capstone ; intermédiaire = branche choisie + lecture d’une défense adverse ; expert = alterner les conversions permises selon position/ressource et abandonner une extension risquée. La progression ne remplace pas ce travail d’exécution.

### 17 — Kisame

**Statut :** Candidat de design, aucun kit jouable affirmé. **Filiation :** S10, pool utilisateur du 13 octobre.

| taijutsu | vitesse | chakra | contrôle chakra | ninjutsu | genjutsu | défense | portée | mobilité | intelligence/lecture | outils/armes | difficulté |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 8 | 5 | 10 | 7 | 8 | 2 | 8 | 9 | 5 | 7 | 9 | 8 |

**Kit à zéro point et identité :** Pool prioritaire : arme lourde, contacts peu nombreux et eau locale. Base proposée : grande lame générique, lancer court, vague frontale, absorption de chakra plafonnée sur contact propre ; éveil d’agression aquatique. Samehada vivante = hypothèse de stade, pas acquise implicitement.

**Branche A — Arme lourde** (50 points cumulés).

| Node | Coût | Prérequis actif | Effet concret et signal de combat |
|---|---:|---|---|
| `A1` | 5 | Kit de base | Coupe franche : dégâts arme +2 %. |
| `A2` | 10 | `A1` | Revers bas : Light2 devient balayage large mais court, recovery +0,15 s et pas de launcher. |
| `A3` | 15 | `A2` | Prise du manche : après heavy confirmé, pousser par le manche plutôt que refaire dégâts ; finit la chaîne, crée espacement. |
| `A4` **capstone** | 20 | `A3` | Fauchage mural : un wallsplat peut finir par tirage au sol plutôt que bounce ; pas de poursuite supplémentaire ni nouveau splat. |

**Branche B — Eau de position** (50 points cumulés).

| Node | Coût | Prérequis actif | Effet concret et signal de combat |
|---|---:|---|---|
| `B1` | 5 | Kit de base | Vague économe : coût vague -2 %. |
| `B2` | 10 | `B1` | Vague diagonale : étroite et oblique plutôt que large et frontale, trajectoire fixée. |
| `B3` | 15 | `B2` | Flaque de lecture : vague laisse une flaque 2 s révélant pas, sans slow ni drain ; une seule zone. |
| `B4` **capstone** | 20 | `B3` | Remous de sortie : consommer flaque pour un pas latéral de 4 studs ; pas d’iframe, aucune attaque pendant déplacement. |

**Branche C — Chakra disputé** (50 points cumulés).

| Node | Coût | Prérequis actif | Effet concret et signal de combat |
|---|---:|---|---|
| `C1` | 5 | Kit de base | Réserve profonde : chakra maximal +3 %. |
| `C2` | 10 | `C1` | Absorption choisie : finisher renonce à moitié des dégâts pour voler au maximum 5 chakra, une fois par chaîne. |
| `C3` | 15 | `C2` | Drain de parade : après parade de projectile chakra admissible, récupérer 3 chakra au lieu de riposter ; cooldown 6 s. |
| `C4` **capstone** | 20 | `C3` | Éveil, lame chargée : durant éveil, dépenser 20 chakra stocké pour élargir une seule coupe de 20 % ; startup +0,15 s, aucun drain sur cette coupe. |

**Presets ranked proposés** — tous les ancêtres sont actifs.

| Budget | Nodes actifs | Total | Intention et renoncement |
|---|---|---:|---|
| 50 | `A1`, `A2`, `A3`, `A4` | 50 | Spécialiste Arme lourde ; abandon des deux autres branches. |
| 80 | `A1`, `A2`, `A3`, `A4`, `C1`, `C2`, `C3` | 80 | Arme lourde + premiers outils de Chakra disputé ; renonce à C4 et à Eau de position. |
| 100 | `A1`, `A2`, `A3`, `A4`, `C1`, `C2`, `C3`, `C4` | 100 | Double spécialisation Arme lourde/Chakra disputé ; renonce entièrement à Eau de position. |

**Risque spécifique et limites :** Vol de chakra + dégâts + garde peuvent créer double bénéfice ; drain plafonné, pas de soin automatique. Pas de fusion requin ou d’arène noyée permanente.

**Maîtrise à tester :** débutant = boucle du kit de base sans capstone ; intermédiaire = branche choisie + lecture d’une défense adverse ; expert = alterner les conversions permises selon position/ressource et abandonner une extension risquée. La progression ne remplace pas ce travail d’exécution.

### 18 — Sasori

**Statut :** Candidat de design, aucun kit jouable affirmé. **Filiation :** S10, pool utilisateur du 13 octobre.

| taijutsu | vitesse | chakra | contrôle chakra | ninjutsu | genjutsu | défense | portée | mobilité | intelligence/lecture | outils/armes | difficulté |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 3 | 5 | 7 | 10 | 8 | 4 | 5 | 10 | 4 | 9 | 10 | 10 |

**Kit à zéro point et identité :** Pool prioritaire : marionnette unique à distance, vrai corps vulnérable. Base proposée : défense courte au corps, kunai, marionnette à santé visible commandée en Tool, thrust et rappel collisionné ; éveil de coordination. Pas de corps immortel ni cent marionnettes.

**Branche A — Fils de commande** (50 points cumulés).

| Node | Coût | Prérequis actif | Effet concret et signal de combat |
|---|---:|---|---|
| `A1` | 5 | Kit de base | Fils fins : coût commande -2 %. |
| `A2` | 10 | `A1` | Commande latérale : marionnette prend un angle fixe avant thrust, délai et fil visibles ; corps de Sasori ne peut attaquer en parallèle. |
| `A3` | 15 | `A2` | Rappel protecteur : rappeler la marionnette pour intercepter une lame puis elle subit le contact ; cooldown partagé avec thrust. |
| `A4` **capstone** | 20 | `A3` | Triangle de fils : déplacement de marionnette entre deux points déjà posés, longueur totale 16 studs ; pas de téléport, fil cassé interrompt. |

**Branche B — Arsenal limité** (50 points cumulés).

| Node | Coût | Prérequis actif | Effet concret et signal de combat |
|---|---:|---|---|
| `B1` | 5 | Kit de base | Lame propre : dégâts marionnette +2 %. |
| `B2` | 10 | `B1` | Dard annoncé : une commande tire un dard au lieu de frappe ; un projectile, pas de tir simultané. |
| `B3` | 15 | `B2` | Poison de pression : touche de dard applique 2 dégâts en 2 s, inclus dans ses dégâts de base et non cumulable ; aucun slow. |
| `B4` **capstone** | 20 | `B3` | Coque ouverte : sacrifier la moitié des PV de marionnette pour une poussée circulaire courte ; avertissement sonore et grande recovery. |

**Branche C — Corps du pilote** (50 points cumulés).

| Node | Coût | Prérequis actif | Effet concret et signal de combat |
|---|---:|---|---|
| `C1` | 5 | Kit de base | Posture cachée : coût garde -2 %. |
| `C2` | 10 | `C1` | Pas du pilote : après commande manquée, Sasori peut reculer mais la marionnette reste immobile ; pas de cancel de sa recovery. |
| `C3` | 15 | `C2` | Substitution de fil : sortie légale près de sa marionnette, consomme charge et ramène la marionnette sans attaque. |
| `C4` **capstone** | 20 | `C3` | Éveil, commande inversée : pendant coordination, choisir corps ou marionnette comme origine de la feinte ; un seul hit réel, les deux silhouettes restent discernables par leurs fils. |

**Presets ranked proposés** — tous les ancêtres sont actifs.

| Budget | Nodes actifs | Total | Intention et renoncement |
|---|---|---:|---|
| 50 | `A1`, `A2`, `A3`, `A4` | 50 | Spécialiste Fils de commande ; abandon des deux autres branches. |
| 80 | `A1`, `A2`, `A3`, `A4`, `B1`, `B2`, `B3` | 80 | Fils de commande + premiers outils de Arsenal limité ; renonce à B4 et à Corps du pilote. |
| 100 | `A1`, `A2`, `A3`, `A4`, `B1`, `B2`, `B3`, `B4` | 100 | Double spécialisation Fils de commande/Arsenal limité ; renonce entièrement à Corps du pilote. |

**Risque spécifique et limites :** Deux positions demandent caméra et télégraphes clairs ; le joueur ne peut attaquer pleinement avec deux corps. Poison jamais létal hors interaction, pas de stun continu.

**Maîtrise à tester :** débutant = boucle du kit de base sans capstone ; intermédiaire = branche choisie + lecture d’une défense adverse ; expert = alterner les conversions permises selon position/ressource et abandonner une extension risquée. La progression ne remplace pas ce travail d’exécution.

### 19 — Kabuto

**Statut :** Candidat de design, aucun kit jouable affirmé. **Filiation :** S10, pool utilisateur du 13 octobre.

| taijutsu | vitesse | chakra | contrôle chakra | ninjutsu | genjutsu | défense | portée | mobilité | intelligence/lecture | outils/armes | difficulté |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 7 | 7 | 6 | 10 | 7 | 6 | 6 | 4 | 6 | 9 | 7 | 9 |

**Kit à zéro point et identité :** Pool prioritaire : précision médicale agressive, informations et opportunisme. Base proposée : paumes courtes, scalpel chakra engagé, kunai, feinte et garde de précision ; éveil de diagnostic sans soin gratuit. Faible portée et pas de burst gratuit.

**Branche A — Scalpel** (50 points cumulés).

| Node | Coût | Prérequis actif | Effet concret et signal de combat |
|---|---:|---|---|
| `A1` | 5 | Kit de base | Contact précis : dégâts corporels +2 %. |
| `A2` | 10 | `A1` | Incision latérale : Light2 paume de côté plutôt que frontale, change angle sans ralentissement adverse. |
| `A3` | 15 | `A2` | Tendon lu : un Heavy propre donne un indice du prochain départ de sprint pendant 1 s ; information seulement, pas de slow. |
| `A4` **capstone** | 20 | `A3` | Coupe de reprise : après whiff adverse observé en portée, choisir thrust court de scalpel ; startup propre et parade possible, aucun auto-ciblage. |

**Branche B — Diagnostic** (50 points cumulés).

| Node | Coût | Prérequis actif | Effet concret et signal de combat |
|---|---:|---|---|
| `B1` | 5 | Kit de base | Dosage fin : coût scalpel -2 %. |
| `B2` | 10 | `B1` | Écoute de chakra : canal de 0,4 s révèle seulement tranche basse/moyenne/haute du chakra adverse pendant 2 s ; interruptible. |
| `B3` | 15 | `B2` | Feinte de soin : posture identique à recharge, annulation vers garde uniquement après recovery ; aucun soin. |
| `B4` **capstone** | 20 | `B3` | Prescription tactique : choisir avant match indice de chakra OU d’épuisement de garde ; le diagnostic ne peut pas révéler les deux. |

**Branche C — Évasion clinique** (50 points cumulés).

| Node | Coût | Prérequis actif | Effet concret et signal de combat |
|---|---:|---|---|
| `C1` | 5 | Kit de base | Garde clinique : coût garde -2 %. |
| `C2` | 10 | `C1` | Recul chirurgical : perfect dodge ouvre un pas court puis scalpel manuel au lieu de riposte standard. |
| `C3` | 15 | `C2` | Substitution d’urgence : conserve l’orientation vers l’ennemi à la sortie légale ; aucun soin, aucune iframe supplémentaire. |
| `C4` **capstone** | 20 | `C3` | Éveil, diagnostic en mouvement : pendant éveil, diagnostic peut se faire à vitesse de marche et permet un lancer de kunai à sa fin ; coût 18 chakra, aucun tir pendant canal. |

**Presets ranked proposés** — tous les ancêtres sont actifs.

| Budget | Nodes actifs | Total | Intention et renoncement |
|---|---|---:|---|
| 50 | `B1`, `B2`, `B3`, `B4` | 50 | Spécialiste Diagnostic ; abandon des deux autres branches. |
| 80 | `B1`, `B2`, `B3`, `B4`, `A1`, `A2`, `A3` | 80 | Diagnostic + premiers outils de Scalpel ; renonce à A4 et à Évasion clinique. |
| 100 | `B1`, `B2`, `B3`, `B4`, `A1`, `A2`, `A3`, `A4` | 100 | Double spécialisation Diagnostic/Scalpel ; renonce entièrement à Évasion clinique. |

**Risque spécifique et limites :** Debuffs peuvent sembler arbitraires ; aucun retrait de bouton, pas de régénération pendant stun. Exclure mode ermite, Edo Tensei et corps hybride adulte.

**Maîtrise à tester :** débutant = boucle du kit de base sans capstone ; intermédiaire = branche choisie + lecture d’une défense adverse ; expert = alterner les conversions permises selon position/ressource et abandonner une extension risquée. La progression ne remplace pas ce travail d’exécution.

### 20 — Tobirama

**Statut :** Candidat de design, aucun kit jouable affirmé. **Filiation :** S10, pool utilisateur du 13 octobre.

| taijutsu | vitesse | chakra | contrôle chakra | ninjutsu | genjutsu | défense | portée | mobilité | intelligence/lecture | outils/armes | difficulté |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 8 | 9 | 8 | 9 | 9 | 4 | 7 | 8 | 9 | 10 | 8 | 10 |

**Kit à zéro point et identité :** Vingtième du pool prioritaire ; eau tactique et déplacement préparé à distinguer de Minato. Base proposée : sabre court, eau linéaire, clone aqueux unique, kunai et rush physique ; éveil de courant. Téléport avancé retenu comme liberté optionnelle, pas moteur de neutral de base.

**Branche A — Eau tranchante** (50 points cumulés).

| Node | Coût | Prérequis actif | Effet concret et signal de combat |
|---|---:|---|---|
| `A1` | 5 | Kit de base | Jet précis : dégâts eau +2 %. |
| `A2` | 10 | `A1` | Jet comprimé : choisir rayon étroit plus rapide au lieu de vague, dégâts identiques et faible couverture. |
| `A3` | 15 | `A2` | Rebond aqueux : jet peut rebondir une fois sur une flaque déjà posée, consomme celle-ci et perd 20 % de vitesse. |
| `A4` **capstone** | 20 | `A3` | Coupe de courant : finisher au sabre sur zone humide peut projeter de côté plutôt qu’au loin ; pas de dégâts supplémentaires ni electrocution générique. |

**Branche B — Clone de préparation** (50 points cumulés).

| Node | Coût | Prérequis actif | Effet concret et signal de combat |
|---|---:|---|---|
| `B1` | 5 | Kit de base | Clone sobre : coût clone aqueux -2 %. |
| `B2` | 10 | `B1` | Garde du clone : clone intercepte un projectile frontal puis éclate ; empêche son attaque dans la même invocation. |
| `B3` | 15 | `B2` | Dissolution dirigée : sacrifier clone crée une flaque de 2 s orientée, aucune explosion ni bind. |
| `B4` **capstone** | 20 | `B3` | Relais unique : rush peut finir à l’emplacement du clone visible dans 12 studs ; corps parcourt le trajet avec collision, détruit le clone et coûte 20 chakra. |

**Branche C — Vitesse tactique** (50 points cumulés).

| Node | Coût | Prérequis actif | Effet concret et signal de combat |
|---|---:|---|---|
| `C1` | 5 | Kit de base | Pas vif : vitesse de course +2 %. |
| `C2` | 10 | `C1` | Contre de garde : parade donne thrust court au sabre, garde possible hors fenêtre gagnée. |
| `C3` | 15 | `C2` | Substitution humide : laisse une flaque après sortie légale ; utilise son unique slot de flaque et ses charges normales. |
| `C4` **capstone** | 20 | `C3` | Éveil, courant de retour : pendant éveil, un jet raté peut être rappelé vers sa flaque en ligne droite ; télégraphe, un seul retour, aucun dommage doublé sur une même cible. |

**Presets ranked proposés** — tous les ancêtres sont actifs.

| Budget | Nodes actifs | Total | Intention et renoncement |
|---|---|---:|---|
| 50 | `A1`, `A2`, `A3`, `A4` | 50 | Spécialiste Eau tranchante ; abandon des deux autres branches. |
| 80 | `A1`, `A2`, `A3`, `A4`, `B1`, `B2`, `B3` | 80 | Eau tranchante + premiers outils de Clone de préparation ; renonce à B4 et à Vitesse tactique. |
| 100 | `A1`, `A2`, `A3`, `A4`, `B1`, `B2`, `B3`, `B4` | 100 | Double spécialisation Eau tranchante/Clone de préparation ; renonce entièrement à Vitesse tactique. |

**Risque spécifique et limites :** Risque de Minato + meilleur zoning ; aucun réseau de sceaux concurrent. Clone physique, eau et déplacements ont un même budget d’action. Pas d’Edo Tensei ni arsenal de Hokage adulte.

**Maîtrise à tester :** débutant = boucle du kit de base sans capstone ; intermédiaire = branche choisie + lecture d’une défense adverse ; expert = alterner les conversions permises selon position/ressource et abandonner une extension risquée. La progression ne remplace pas ce travail d’exécution.

### 21 — Hiruzen

**Statut :** Candidat de design, aucun kit jouable affirmé. **Filiation :** S10, pool utilisateur du 13 octobre.

| taijutsu | vitesse | chakra | contrôle chakra | ninjutsu | genjutsu | défense | portée | mobilité | intelligence/lecture | outils/armes | difficulté |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 8 | 7 | 8 | 9 | 9 | 6 | 7 | 8 | 7 | 9 | 9 | 9 |

**Kit à zéro point et identité :** Annexe du pool 25 : généraliste jeune bâton/outils et deux éléments choisis avant match. Base proposée : taijutsu compact, bâton court, kunai, feu frontal et écran de terre ; éveil d’enchaînement élémentaire. Pas de maîtrise parfaite de tous les jutsu.

**Branche A — Bâton** (50 points cumulés).

| Node | Coût | Prérequis actif | Effet concret et signal de combat |
|---|---:|---|---|
| `A1` | 5 | Kit de base | Bois ferme : dégâts arme +2 %. |
| `A2` | 10 | `A1` | Revers court : Light2 devient coup de talon du bâton, portée réduite et sortie plus latérale. |
| `A3` | 15 | `A2` | Appui haut : walljump permet pointe descendante plutôt que slam ; consomme conversion mur. |
| `A4` **capstone** | 20 | `A3` | Perche choisie : finisher peut écarter ou lancer bas selon appui, même budget juggle. |

**Branche B — Éléments** (50 points cumulés).

| Node | Coût | Prérequis actif | Effet concret et signal de combat |
|---|---:|---|---|
| `B1` | 5 | Kit de base | Dosage : coût feu -2 %. |
| `B2` | 10 | `B1` | Feu bas : cône plus proche du sol et plus étroit plutôt que boule, ligne de saut possible. |
| `B3` | 15 | `B2` | Terre oblique : écran incliné plutôt que frontal, bloque aussi ses outils. |
| `B4` **capstone** | 20 | `B3` | Composition locale : feu frappe son écran puis se divise aux deux bords ; détruit l’écran, dégâts totaux inchangés. |

**Branche C — Polyvalence bornée** (50 points cumulés).

| Node | Coût | Prérequis actif | Effet concret et signal de combat |
|---|---:|---|---|
| `C1` | 5 | Kit de base | Réserve : chakra maximal +3 %. |
| `C2` | 10 | `C1` | Lecture d’arme : parade ouvre outil de recul plutôt que riposte. |
| `C3` | 15 | `C2` | Substitution de couvert : sortie légale privilégie côté de son écran, détruit celui-ci. |
| `C4` **capstone** | 20 | `C3` | Éveil, alternance : en éveil, hit-confirm de bâton ouvre feu OU terre contextuel, paie le coût entier et un seul choix. |

**Presets ranked proposés** — tous les ancêtres sont actifs.

| Budget | Nodes actifs | Total | Intention et renoncement |
|---|---|---:|---|
| 50 | `A1`, `A2`, `A3`, `A4` | 50 | Spécialiste Bâton ; abandon des deux autres branches. |
| 80 | `A1`, `A2`, `A3`, `A4`, `B1`, `B2`, `B3` | 80 | Bâton + premiers outils de Éléments ; renonce à B4 et à Polyvalence bornée. |
| 100 | `A1`, `A2`, `A3`, `A4`, `B1`, `B2`, `B3`, `B4` | 100 | Double spécialisation Bâton/Éléments ; renonce entièrement à Polyvalence bornée. |

**Risque spécifique et limites :** Généraliste sans faiblesse ; seulement deux natures équipées, pas de contre parfait automatique ni invocation adulte.

**Maîtrise à tester :** débutant = boucle du kit de base sans capstone ; intermédiaire = branche choisie + lecture d’une défense adverse ; expert = alterner les conversions permises selon position/ressource et abandonner une extension risquée. La progression ne remplace pas ce travail d’exécution.

### 22 — Deidara

**Statut :** Candidat de design, aucun kit jouable affirmé. **Filiation :** S10, pool utilisateur du 13 octobre.

| taijutsu | vitesse | chakra | contrôle chakra | ninjutsu | genjutsu | défense | portée | mobilité | intelligence/lecture | outils/armes | difficulté |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 3 | 6 | 8 | 8 | 9 | 4 | 4 | 10 | 9 | 8 | 9 | 10 |

**Kit à zéro point et identité :** Annexe du pool 25 : explosifs télégraphiés, vol bref et fragilité rapprochée. Base proposée : poings de recul, petite bombe unique, piège argile visible, saut assisté ; éveil de façonnage. Pas de vol permanent.

**Branche A — Argile mobile** (50 points cumulés).

| Node | Coût | Prérequis actif | Effet concret et signal de combat |
|---|---:|---|---|
| `A1` | 5 | Kit de base | Charge nette : dégâts bombe +2 %. |
| `A2` | 10 | `A1` | Lancer bas : bombe roule au sol au lieu de voler, fuse visible et même rayon. |
| `A3` | 15 | `A2` | Oiseau de détour : trajectoire en arc fixée au départ au lieu de homing, destructible. |
| `A4` **capstone** | 20 | `A3` | Fragmentation : bombe se sépare en deux petites charges ; même dégâts totaux et compte deux dans plafond. |

**Branche B — Pièges** (50 points cumulés).

| Node | Coût | Prérequis actif | Effet concret et signal de combat |
|---|---:|---|---|
| `B1` | 5 | Kit de base | Modelage : coût piège -2 %. |
| `B2` | 10 | `B1` | Mine de mur : charge posée sur surface verticale au lieu du sol, silhouette visible. |
| `B3` | 15 | `B2` | Détonation différée : choisir fuse 0,6 ou 1,2 s au placement, aucun déclenchement rétroactif. |
| `B4` **capstone** | 20 | `B3` | Déminage offensif : sacrifier ses deux charges pour une poussée locale sans dégâts ; ne recharge pas bombes. |

**Branche C — Air risqué** (50 points cumulés).

| Node | Coût | Prérequis actif | Effet concret et signal de combat |
|---|---:|---|---|
| `C1` | 5 | Kit de base | Stabilité : contrôle aérien +2 %. |
| `C2` | 10 | `C1` | Vol plané : saut assisté devient plané descendant de 1 s maximum, aucune recharge aérienne. |
| `C3` | 15 | `C2` | Largage : un Tool aérien lâche verticalement plutôt que vise, recovery conservée. |
| `C4` **capstone** | 20 | `C3` | Éveil, façonnage de sortie : en éveil, une charge peut devenir appui de fuite qui casse sans exploser ; consomme la charge, aucune iframe. |

**Presets ranked proposés** — tous les ancêtres sont actifs.

| Budget | Nodes actifs | Total | Intention et renoncement |
|---|---|---:|---|
| 50 | `A1`, `A2`, `A3`, `A4` | 50 | Spécialiste Argile mobile ; abandon des deux autres branches. |
| 80 | `A1`, `A2`, `A3`, `A4`, `C1`, `C2`, `C3` | 80 | Argile mobile + premiers outils de Air risqué ; renonce à C4 et à Pièges. |
| 100 | `A1`, `A2`, `A3`, `A4`, `C1`, `C2`, `C3`, `C4` | 100 | Double spécialisation Argile mobile/Air risqué ; renonce entièrement à Pièges. |

**Risque spécifique et limites :** Kiting infini et mines invisibles ; limite deux charges actives, aucune attaque suicide gagnante ni nuage létal invisible.

**Maîtrise à tester :** débutant = boucle du kit de base sans capstone ; intermédiaire = branche choisie + lecture d’une défense adverse ; expert = alterner les conversions permises selon position/ressource et abandonner une extension risquée. La progression ne remplace pas ce travail d’exécution.

### 23 — Darui

**Statut :** Candidat de design, aucun kit jouable affirmé. **Filiation :** S10, pool utilisateur du 13 octobre.

| taijutsu | vitesse | chakra | contrôle chakra | ninjutsu | genjutsu | défense | portée | mobilité | intelligence/lecture | outils/armes | difficulté |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 8 | 7 | 7 | 8 | 8 | 4 | 7 | 8 | 7 | 8 | 9 | 8 |

**Kit à zéro point et identité :** Annexe du pool 25 : arme, eau et foudre de milieu de portée. Base proposée : coupe lourde calme, jet étroit, thrust électrique, kunai et garde au sabre ; éveil d’orage local. Black Lightning est une hypothèse de jeune version à justifier.

**Branche A — Lame tranquille** (50 points cumulés).

| Node | Coût | Prérequis actif | Effet concret et signal de combat |
|---|---:|---|---|
| `A1` | 5 | Kit de base | Acier : dégâts arme +2 %. |
| `A2` | 10 | `A1` | Taille en retrait : Light2 peut reculer plutôt qu’avancer, portée de contact inchangée. |
| `A3` | 15 | `A2` | Butée : heavy confirmé finit par poussée de garde au lieu de dégât, pas de nouveau bind. |
| `A4` **capstone** | 20 | `A3` | Angle d’orage : finisher permet un arc large plus lent au lieu du thrust, startup +0,2 s. |

**Branche B — Eau préparée** (50 points cumulés).

| Node | Coût | Prérequis actif | Effet concret et signal de combat |
|---|---:|---|---|
| `B1` | 5 | Kit de base | Flux : coût jet -2 %. |
| `B2` | 10 | `B1` | Jet latéral : sortie depuis un pas de côté annoncé, sans tir à travers mur. |
| `B3` | 15 | `B2` | Flaque bornée : jet peut terminer au sol pour une flaque 2 s, renonce aux dégâts de fin. |
| `B4` **capstone** | 20 | `B3` | Conducteur choisi : thrust dans sa propre flaque crée un arc unique de 6 studs ; détruit flaque et ne cible pas automatiquement. |

**Branche C — Foudre contrôlée** (50 points cumulés).

| Node | Coût | Prérequis actif | Effet concret et signal de combat |
|---|---:|---|---|
| `C1` | 5 | Kit de base | Charge : chakra maximal +3 %. |
| `C2` | 10 | `C1` | Parade conductrice : parade arme réussie ouvre contre manuel électrique, pas de stun prolongé. |
| `C3` | 15 | `C2` | Feinte d’éclair : Cancel précoce laisse crépitement, moitié chakra perdu, cooldown entier. |
| `C4` **capstone** | 20 | `C3` | Éveil, ligne noire : en éveil, thrust peut longer sa lame lancée en ligne fixe ; remplace thrust normal, pas de homing, coût 24 chakra. |

**Presets ranked proposés** — tous les ancêtres sont actifs.

| Budget | Nodes actifs | Total | Intention et renoncement |
|---|---|---:|---|
| 50 | `B1`, `B2`, `B3`, `B4` | 50 | Spécialiste Eau préparée ; abandon des deux autres branches. |
| 80 | `B1`, `B2`, `B3`, `B4`, `A1`, `A2`, `A3` | 80 | Eau préparée + premiers outils de Lame tranquille ; renonce à A4 et à Foudre contrôlée. |
| 100 | `B1`, `B2`, `B3`, `B4`, `A1`, `A2`, `A3`, `A4` | 100 | Double spécialisation Eau préparée/Lame tranquille ; renonce entièrement à Foudre contrôlée. |

**Risque spécifique et limites :** Eau/foudre ne doit pas toucher toute flaque de l’arène ; aucun conducteur universel ajouté par ce design, silhouette distincte de Kakashi.

**Maîtrise à tester :** débutant = boucle du kit de base sans capstone ; intermédiaire = branche choisie + lecture d’une défense adverse ; expert = alterner les conversions permises selon position/ressource et abandonner une extension risquée. La progression ne remplace pas ce travail d’exécution.

### 24 — Yagura

**Statut :** Candidat de design, aucun kit jouable affirmé. **Filiation :** S10, pool utilisateur du 13 octobre.

| taijutsu | vitesse | chakra | contrôle chakra | ninjutsu | genjutsu | défense | portée | mobilité | intelligence/lecture | outils/armes | difficulté |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 7 | 6 | 9 | 8 | 8 | 4 | 9 | 8 | 6 | 8 | 8 | 9 |

**Kit à zéro point et identité :** Annexe du pool 25 : bâton lourd et défense d’eau réfléchissante. Base proposée : bâton, lancer court, écran d’eau qui absorbe une lame, vague et contre manuel ; éveil de pression aquatique. Statut d’âge et jinchūriki explicitement à rechercher.

**Branche A — Bâton et contrôle** (50 points cumulés).

| Node | Coût | Prérequis actif | Effet concret et signal de combat |
|---|---:|---|---|
| `A1` | 5 | Kit de base | Bâton stable : dégâts arme +2 %. |
| `A2` | 10 | `A1` | Crochet bas : Light2 balaye plutôt que pousse, abandonne launcher. |
| `A3` | 15 | `A2` | Pointe de paroi : wall route peut projeter tangentiellement au lieu de rebond, fin de chaîne. |
| `A4` **capstone** | 20 | `A3` | Verrou du manche : grab confirmé finit en écartement du bâton, durée grab inchangée. |

**Branche B — Miroir d’eau** (50 points cumulés).

| Node | Coût | Prérequis actif | Effet concret et signal de combat |
|---|---:|---|---|
| `B1` | 5 | Kit de base | Eau fine : coût écran -2 %. |
| `B2` | 10 | `B1` | Écran incliné : angle choisi avant placement, zone de dos ouverte. |
| `B3` | 15 | `B2` | Reflet simple : écran peut dévier un projectile admissible avec vitesse réduite, sans homing. |
| `B4` **capstone** | 20 | `B3` | Miroir rompu : détruire écran pour onde de recul sans dégâts ; empêche tout renvoi restant. |

**Branche C — Pression aquatique** (50 points cumulés).

| Node | Coût | Prérequis actif | Effet concret et signal de combat |
|---|---:|---|---|
| `C1` | 5 | Kit de base | Réserve : chakra maximal +3 %. |
| `C2` | 10 | `C1` | Vague basse : trajectoire rasante au lieu de cône, saut possible. |
| `C3` | 15 | `C2` | Substitution liquide : reflet visuel après sortie légale, sans collider ni protection. |
| `C4` **capstone** | 20 | `C3` | Éveil, carapace mobile : durant éveil, écran peut accompagner un pas de 3 studs mais arme inactive pendant action ; écran détruit à la fin. |

**Presets ranked proposés** — tous les ancêtres sont actifs.

| Budget | Nodes actifs | Total | Intention et renoncement |
|---|---|---:|---|
| 50 | `B1`, `B2`, `B3`, `B4` | 50 | Spécialiste Miroir d’eau ; abandon des deux autres branches. |
| 80 | `B1`, `B2`, `B3`, `B4`, `A1`, `A2`, `A3` | 80 | Miroir d’eau + premiers outils de Bâton et contrôle ; renonce à A4 et à Pression aquatique. |
| 100 | `B1`, `B2`, `B3`, `B4`, `A1`, `A2`, `A3`, `A4` | 100 | Double spécialisation Miroir d’eau/Bâton et contrôle ; renonce entièrement à Pression aquatique. |

**Risque spécifique et limites :** Réflexion ne doit pas renvoyer toutes les signatures ; liste blanche de projectiles simples, pas de copie de corps ou Bijū complet.

**Maîtrise à tester :** débutant = boucle du kit de base sans capstone ; intermédiaire = branche choisie + lecture d’une défense adverse ; expert = alterner les conversions permises selon position/ressource et abandonner une extension risquée. La progression ne remplace pas ce travail d’exécution.

### 25 — Konan

**Statut :** Candidat de design, aucun kit jouable affirmé. **Filiation :** S10, pool utilisateur du 13 octobre.

| taijutsu | vitesse | chakra | contrôle chakra | ninjutsu | genjutsu | défense | portée | mobilité | intelligence/lecture | outils/armes | difficulté |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 4 | 7 | 7 | 9 | 8 | 5 | 5 | 9 | 9 | 8 | 9 | 9 |

**Kit à zéro point et identité :** Annexe du pool 25 : géométrie de papier, courtes lames, dispersion lisible. Base proposée : frappes précises, éventail papier, pli posé destructible, saut plané bref et feinte ; éveil de pliage sans invulnérabilité.

**Branche A — Lames pliées** (50 points cumulés).

| Node | Coût | Prérequis actif | Effet concret et signal de combat |
|---|---:|---|---|
| `A1` | 5 | Kit de base | Pli net : dégâts outils +2 %. |
| `A2` | 10 | `A1` | Éventail vertical : dispersion en hauteur au lieu de largeur, même quantité. |
| `A3` | 15 | `A2` | Retour plié : un projectile peut revenir en ligne vers son origine après raté ; aucun double hit. |
| `A4` **capstone** | 20 | `A3` | Lame déployée : finisher outil devient longue lame étroite, startup +0,15 s et recovery lourde. |

**Branche B — Géométrie papier** (50 points cumulés).

| Node | Coût | Prérequis actif | Effet concret et signal de combat |
|---|---:|---|---|
| `B1` | 5 | Kit de base | Économie de pli : coût piège -2 %. |
| `B2` | 10 | `B1` | Pli de mur : piège peut se poser sur mur accessible, contour toujours visible. |
| `B3` | 15 | `B2` | Paravent : sacrifier son pli pour écran visuel 0,8 s, corps et sons vrais restent lisibles. |
| `B4` **capstone** | 20 | `B3` | Origami d’angle : pli peut réorienter un éventail une fois, disparaît et ne crée pas de papier supplémentaire. |

**Branche C — Dispersion** (50 points cumulés).

| Node | Coût | Prérequis actif | Effet concret et signal de combat |
|---|---:|---|---|
| `C1` | 5 | Kit de base | Équilibre : contrôle aérien +2 %. |
| `C2` | 10 | `C1` | Plané tangent : choisir direction de plané au départ, descente obligatoire et durée 1 s. |
| `C3` | 15 | `C2` | Substitution de feuilles : silhouette 0,8 s au point de départ, aucune défense supplémentaire. |
| `C4` **capstone** | 20 | `C3` | Éveil, corps recomposé : en éveil, plané peut finir par frappe descendante manuelle ; remplace slam, 18 chakra, hurtbox présente durant toute dispersion. |

**Presets ranked proposés** — tous les ancêtres sont actifs.

| Budget | Nodes actifs | Total | Intention et renoncement |
|---|---|---:|---|
| 50 | `B1`, `B2`, `B3`, `B4` | 50 | Spécialiste Géométrie papier ; abandon des deux autres branches. |
| 80 | `B1`, `B2`, `B3`, `B4`, `A1`, `A2`, `A3` | 80 | Géométrie papier + premiers outils de Lames pliées ; renonce à A4 et à Dispersion. |
| 100 | `B1`, `B2`, `B3`, `B4`, `A1`, `A2`, `A3`, `A4` | 100 | Double spécialisation Géométrie papier/Lames pliées ; renonce entièrement à Dispersion. |

**Risque spécifique et limites :** Particules masquant hurtbox et pièges illimités ; pas d’intangibilité permanente ni océan de parchemins explosifs.

**Maîtrise à tester :** débutant = boucle du kit de base sans capstone ; intermédiaire = branche choisie + lecture d’une défense adverse ; expert = alterner les conversions permises selon position/ressource et abandonner une extension risquée. La progression ne remplace pas ce travail d’exécution.

## 6. Cinq séquences prioritaires à montrer à Claude

Ces exemples décrivent l’intention, pas un combo garanti de bout en bout. Un contact adverse, une garde ou un manque de ressource ferme la branche selon les règles de l’action ; aucun script ne reconnaît toute la séquence pour la forcer.

| Personnage | À zéro point | Apport visible du preset 50 | Extension possible en 80/100 | Réponse adverse à démontrer |
|---|---|---|---|---|
| Sasuke | Fil → Dragon Flame ou Light2 → ShadowLeaf → Lion | A2 donne un launcher oblique, A4 finit de côté : corps, arc et réception changent | B2 prépare un segment ; B3 choisit feu détaché ; B4 sacrifie ignition ou tension | Dodge du fil, garde de la route, tech murale ; Chidori raté reste punissable |
| Naruto | Clone unique → entrée en poings → finisher | B2 retarde le faux départ, B4 offre un échange préparé puis détruit le clone | A2 relaie Light2, A3 choisit qui poursuit, A4 oriente le finisher | Détruire le clone, lire la poussière, punir le délai de permutation |
| Minato | Kunai → sceau → FTG → frappe ou sortie | A2 sweep au lieu de frappe, A3 tangente et A4 double angle payé | B2 rend la destination choisie explicite ; B4 transforme un sceau en géométrie de kunai | Garder l’arrivée, casser l’angle, collision bloquante ; aucun troisième FTG de chaîne |
| Itachi | Shuriken Geometry → Read ou Mirage → punition manuelle | B2 riposte extérieure, B3 tromperie sonore, B4 feinte après erreur réelle | A2/A3 déplacent le moment et la hauteur des lames ; A4 exploite une seconde surface | Ne pas frapper le leurre, rompre LOS, avancer pendant préparation feu |
| Neji | Paumes → point → Rotation ou 64 paumes | A2 fait prendre l’extérieur ; A4 raccourcit les 64 pour expulser | B2 demi-Rotation expose le dos ; B4 pas tangent hors du dôme | Sortir de portée, bait Rotation, attaque derrière le demi-cercle, substitution légale |

Un autre preset doit rester utile à budget égal. Exemple : Sasuke C1–C4 =50 pour lecture/foudre plutôt qu’air ; Minato C1–C4 =50 pour sortie au lieu de double entrée ; Itachi A1–A4 =50 pour outil plutôt qu’illusion ; Neji B1–B4 =50 pour cercle plutôt que pression. Ces variantes sont légales par la même règle, sans points gratuits ni branche cachée.

### Boucles requises pour chaque fiche

Les fiches de base et branches doivent pouvoir instancier ces quatre boucles du template, avec leurs expressions corporelles propres :

- **Offensive :** poke/outil ou signature → contact confirmé → route de branche → finisher OU abandon pour sortir.
- **Défensive :** garder/esquiver selon menace → défense réussie → contre manuel OU reposition ; une mauvaise lecture conserve sa recovery.
- **Low chakra :** mouvement, taijutsu, outil de base au rythme légal → désengagement ; ni nodes ni éveil ne suppriment le coût des défenses.
- **Air/mur :** launcher ou appui valide → une conversion choisie du build → sortie et reprise au sol ; aucune boucle de recharge sur surface/entité.

Pour Lee, la boucle low chakra reste son combat physique normal, mais ses extensions coûtent toujours des ressources. Pour Gaara/Sasori, une ressource de bouclier/marionnette épuisée impose de reprendre la distance par le corps ; le jeu ne doit pas les rendre inopérants. Pour Shikamaru/Nagato, un setup manqué doit laisser un neutral minimal jouable, pas une attente obligatoire de cooldowns.

## 7. Contrat de données pour une implémentation ultérieure

Le fichier compagnon JSON est une **spec inerte**, jamais un ModuleScript à charger automatiquement. Il contient les 25 cartes, 300 nodes, leurs coûts/prérequis et 75 presets. Le Markdown porte les règles communes, contreparties et limites ; lire les deux. Aucun nom proposé ne réserve silencieusement un ID permanent.

À l’implémentation, un manifeste versionné devra porter : `fighterId`, `nodeId`, `balanceVersion`, `cost`, `prerequisites`, `exclusiveVariantGroup`, `effects`, `actionId`, `inputContext`, `resourceCost`, `startup`, `active`, `recovery`, `cooldownGroup`, `range`, `movementPolicy`, `collisionPolicy`, `damageBudget`, `juggleBudget`, `visualCue`, `counterplay`, `loreLabel`, `loreEvidence`. Les règles génériques du §4 sont des defaults de conception ; Claude doit résoudre chaque mapping avant d’ajouter l’action.

Validation au pairing, côté serveur :

```text
charger profil confirmé et registre exact de versionBalance
refuser IDs inconnus, doublons, nombres non finis et personnage illégal
vérifier nodes possédés et fermeture transitive de tous les prérequis actifs
vérifier choix exclusifs des variantes et plafond des effets/statistiques
recalculer A depuis les coûts serveur ; refuser A > budget, sans faire confiance au total client
figer fighter + nodes + variantes + budget + version + matchId
appliquer uniquement la projection de ce snapshot à une copie de définition de match
conserver les définitions de base et profils persistants hors des mutations de combat
```

Le serveur possède XP, points accordés, déblocages, builds légaux, résultat, achats confirmés, coûts et cooldowns. Le client demande un choix et prévisualise ; il n’envoie jamais comme vérité ses dégâts, son niveau ou un total de points. En cas de profil indisponible/corrompu, refuser ranked et conserver le profil ; ne pas l’écraser avec un défaut. Replay d’une récompense ou d’un achat = même résultat, aucune deuxième attribution. Les reçus doivent être persistés avant de confirmer le gain ; aucune API d’achat live choisie ici.

Réutilisation ciblée possible de S19 : versionnement/snapshots/leases/transactions idempotentes. À **revoir** : Ranked normalisé, queueKey sans budget/version, croissance de stats, rangs/récompenses d’exemple, maîtrise qui attribuerait gratuitement des techniques actives. Les exemples `optional-route` et `awakening-option` ne deviennent pas des nodes de cette spec. Les personnages et équipements possédés de S19 ne doivent pas retirer le roster local actuellement accessible.

Migration future : préserver les IDs actuels Flashstep/Mirage/GentleFist/Lion/Sand et les données de collection ; créer une version de schéma dédiée aux `grantedPoints`, `unlockedNodeIds`, `presets`, `balanceVersion`. Calcul de l’XP acquise selon une règle de conversion documentée, sans récupérer les points payés ni copier les SpeedGrowth. Aucun script de migration livré par cette passe. Les queues d’ancienne et nouvelle version ne se mélangent pas.

## 8. Équilibrage : hypothèses et critères de rejet

Les prix ne sont pas des mesures de force. Un node de 20 doit modifier un plan de jeu, pas garantir qu’il surclasse deux nodes de 10. Tester chaque racine contre base puis chaque branche contre les deux autres, à budget identique. Le roster asymétrique exige des réponses différentes, sans personnage qui annule entièrement la grammaire d’un autre.

| Famille de risque | Rejet immédiat ou mesure demandée |
|---|---|
| Stats/croissance | Aucun SpeedGrowth passif, bonus de compte ou rareté appliqué en plus du snapshot ; vérifier plafonds par propriété et valeur exacte des remises arrondies |
| Combos air/mur | Refuser infinité et reset de budget ; défense/tech/wakeup doivent fonctionner en présence de tous les nodes compatibles |
| Ressources | Neji/Kisame n’empêchent pas durablement tout jutsu ; aucun nouveau verrou ne prolonge le verrou de base. Fenêtre de récupération de ressource testée après chaîne complète |
| Illusion/phase | Commandes conservées, vérité serveur inchangée, piste contradictoire exploitable. Phase Obito ne peut ni attaquer ni être activée en hitstun |
| Entités | Les plafonds portent sur gameplay et présentation ; clones/serpents/miroirs/marionnettes ne multiplient pas les dégâts d’une même action |
| Zoning/défense automatique | Gaara, Deidara, Sasori et Nagato doivent être punissables après setup raté ; pas d’immunité pendant récupération ni de fuite aérienne permanente |
| Éveil | Capstone C4 change au moins une règle visible en plus du signal corporel, ne stack pas un second éveil ; mesurer sa valeur séparément de l’augmentation de stats existante |
| Accès payant | Mesurer diversité et réussite par nombre de nodes possédés, à MMR/budget/personnage comparables ; le budget ne suffit pas à conclure à la parité |
| Population | Mesurer attente par région/budget, éviter trois files mortes ; pas de pairing inter-budget caché |

Pilote : CORE4 à zéro/50/80/100, Naruto en cinquième seulement après validation de son kit de départ. Évaluer les séquences et mix de branches avant d’étendre. À titre de seuil d’alerte proposé, un build >55 % sur un échantillon humain comparable déclenche revue des matchups et de l’incertitude statistique ; ce n’est pas une preuve de déséquilibre sans taille d’échantillon et contexte. Enregistrer taux de sélection, dégâts par ouverture, temps sans contrôle, coûts réellement dépensés, uptime d’entités, sorties de défense, durée de match et abandons. Les simulations IA ne remplacent pas ces duels.

## 9. Handoff Claude et backlog sans régression de périmètre

Cette livraison autorise la **conception**. Avant un changement gameplay, appliquer S16 : vérifier le nouveau HEAD distant, comparer les branches divergentes, proposer un plan global et recueillir l’approbation d’implémentation prévue par le repo. Aucune nouvelle autorisation n’est nécessaire pour terminer/lire cette spec déjà demandée.

Ordre de travail proposé à Claude :

1. Reprendre START et les nouveaux commits ; conserver les règles cumulatives, fermer le choix de branche d’intégration sans supposer un merge.
2. QA-001/002/003 : établir une baseline réelle de l’artefact choisi. Protéger CORE4 à zéro point, leurs timings/identités et tous les diagnostics isolés.
3. Préparer le manifeste d’arbre et son validateur sur données inertes, puis migration/profil ; ne pas connecter les 25 candidats à la sélection.
4. Sasuke : première preuve d’arbre branches réellement visibles ; Naruto : première preuve d’un nouveau kit complet ; Minato, Itachi, Neji : adaptations identitaires et protection des signatures existantes.
5. Ranked : NET-001/002 et pairing à budget/version, deux clients réels ; boutique seulement quand grants/sauvegarde/replays de reçus sont qualifiés.
6. Vague restante selon effort, lore et validation native : Gaara/Kakashi/Shisui/Lee/Orochimaru, puis dix autres des vingt. Les cinq annexes gardent leur place dans le pool, sans obligation de calendrier.

Rattachement au backlog existant : PROG-001 porte la direction progression ; CHR-CORE-001/002 et CHR-MIN/ITA/NEJ/SAS gardent identité/lore ; COM-001..007, DEF-001..005, TOOL-001..006, SYS-001..003, BAL-001, UX-001/002, NET-001/002 et PERF-001 couvrent leurs contrats. CHR-EXT-001/002 restent les gates d’activation des futurs combattants. Ne clôturer aucun de ces tickets sur la seule présence de ce document.

Sous-travaux suggérés à créer **sous PROG-001 lors de l’intégration**, sans les déclarer déjà présents au backlog distant : registre/coûts/prérequis ; profil/XP/achats ; rebuild/presets ; projection et snapshot serveur ; queues budgets/version ; tutoriel d’arbre ; QA nodes/entités ; balance humaine et métriques d’accès. Garder les sources d’origine et ne pas remplacer tout le backlog par cette liste.

### Gate documentaire de cette livraison

- Provenance distante et SHAs enregistrés ; divergence des branches déclarée.
- 25 cartes de 12 stats ; 25 kits de départ décrits ; 75 branches ; 300 nodes aux IDs uniques.
- 75 presets aux coûts exactement 50/80/100 et prérequis fermés ; chaque arbre complet totalise 150.
- Nouvelles capacités proposées, lore provisoire explicite, aucun canon ni résultat Studio inventé.
- Sources et gameplay runtime inchangés par cette livraison ; aucun build ni test gameplay présenté comme exécuté.

### Gate future de chaque arbre implémenté — PENDING

- Validateur : rejet ID inconnu/dupliqué, parent inactif, mauvais personnage/version, surbudget, incompatibilité de variantes, profil absent/corrompu et replay de grant.
- Rebuild : refund exact, suppression descendants, conservation XP/points payés, aucun effet de node désactivé ; presets/reconnexion/patch testés.
- Combat : chaque node majeur comparé avant/après sur **le même scénario** : hit, garde, whiff, interruption, low chakra, KO, rematch et cleanup. Contrôler les ancêtres et toutes les combinaisons légales ; tester les deux autres branches non équipées pour prouver leur absence.
- CORE4 à zéro point : régression complète des routes et signatures existantes, comparaison avec baseline exacte ; toute correction de balance distincte et autorisée.
- Ranked : deux clients réels, même budget/version et snapshots immuables ; achats/XP/rebuild après pairing n’affectent pas le combat ; reconnect et disconnect traités.
- Studio : 30 s de mouvement agréable, contact crédible, neutral/défense/outil/re-entry, sol/air/mur, awakening, manette, caméra, perception adversaire et benchmark visuel. Captures/vidéos natives horodatées sur artefact exact avec SHA256 ; une simulation ne vaut pas ce gate.
- Progression et boutique : persistance réelle, doublons, conflits de sessions, panne avant/après ACK, limites de plafond et remboursements décidés ; aucun achat reçu deux fois.
- Balance : plusieurs builds par budget, réponses adverses lisibles ; zéro-point complet et amusant évalué humainement.

**État final de la spec : conception livrée, cohérence structurelle vérifiée ; toutes les valeurs d’équilibrage, toutes les nouvelles motions et tous les gates gameplay/Studio/production restent NON VALIDÉS.**

### Vérifications réellement exécutées sur la livraison

Le 15/10/2026 : relecture du JSON sérialisé et comparaison Markdown/JSON — **PASS** pour 25 personnages, 12 statistiques chacun, 75 branches, 300 IDs de nodes uniques, coûts cumulés 150 par arbre, 75 presets exacts et prérequis actifs fermés. Vérification des 22 liens vers les fichiers de la base clonée au SHA distant — **PASS**. Relecture GitHub de la tête documentaire en fin de tâche — toujours `3b50d8eccbaebcc982af5476ff56d279353b3cb0`. Clone de référence resté intact.

`python3 tools/check_architecture.py` exécuté sur le clone distant : **PASS**, 302 fichiers code/projet, avec réserve explicite du checker sur les imports calculés. Cette vérification concerne la base distante, pas une qualification des futures compétences. Aucun test gameplay, build, duel PvP, achat ni contrôle Studio exécuté pour cette livraison documentaire.
