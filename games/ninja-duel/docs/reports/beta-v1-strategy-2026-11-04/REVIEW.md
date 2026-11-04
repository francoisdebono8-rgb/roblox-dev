# Audit produit Ninja Duel — separer BETA et JEU V1 (04/11/2026)

> **STATUT : REVUE CANDIDATE / NON EXECUTABLE**. Demandee par l'utilisateur pour un commit de cadrage le 04/11. Aucun feu vert pour une nouvelle grande mission, aucun ordre de modifier le gameplay, aucune publication ni depense autorisee ici.
>
> Cette revue ne remplace ni [VISION](../../active/VISION.md), ni [DECISIONS](../../active/DECISIONS.md), ni [MASTER_BACKLOG](../../active/MASTER_BACKLOG.md). Toute execution doit passer par arbitrage de priorite avec Claude et les tickets existants, selon [EXECUTION_RULES](../../active/EXECUTION_RULES.md). **Ne pas interrompre le bloc d'animations en cours.**

## 0. La clarification que l'audit precedent n'avait pas faite

L'audit concernait **les deux horizons**, mais ses recommandations etaient insuffisamment distinguees.

- **BETA / MAINTENANT** : 8 personnages, boucle de combat plaisante, session realisable sans aide, tournois IA, defis humains, validation en ligne dans Roblox publie, instruments d'observation, debut de traction organique. C'est un produit en test : montrer sa proposition de valeur, mesurer les sorties, apprendre, corriger.
- **JEU V1 / PLUS TARD** : hub physique compact et vivant, progression persistante et maitrises, arbres de personnages et budget competitif equitable, roster enrichi, tournoi PvP/ranked, economies et socials, robustesse et contenu. Ce sont des objectifs de produit final, **pas tous des prerequis de beta**.
- **TRANSVERSAL** : « waouh » et qualite du combat = necessaires des la beta. Ce n'est ni une extension du roster ni une campagne marketing qui peut remplacer cette preuve.

## 1. Photographie verifiee du code (ne pas confondre avec une validation live)

Base analysee : branche `claude/ninja-duel-2026-10-14`, point de depart `e36abe7` au 04/11/2026 (reverifier le HEAD avant toute mise en oeuvre).

- `Shared/BetaRoster.luau` contient Lion/Sasuke, Legion/Naruto, Sand/Gaara, Leaf/Lee, GentleFist/Neji, Mirage/Itachi, Copycat/Kakashi, Flashstep/Minato : **8 visibles dans la beta, pas 20**.
- V31–V32 : `Server/Lobby` publie la presence interserveurs (MemoryStore), distribue les invitations (MessagingService), organise un duel via serveur reserve (TeleportService), tandis que `Server/Online` gere le 1v1 par serveur et la revanche.
- **Point non clos** : la paire reelle de comptes dans une experience Roblox publiee avec teleportation, latence, depart/reconnexion doit encore etre validee (NET-001). Les mocks et Studio ne sont pas du LIVE_ROBLOX.
- V33 : tournoi des huit contre l'IA, affichage du bracket et matchs IA spectatables/skip. Recompenses et tournoi entre humains non livres selon CURRENT_STATE.
- V34 : jutsu de signes, commandes reconfigurees, eveils ; V35 : correctifs et controles tactiles. Au point de depart, V35 a 38 suites PASS mais **controle visuel Studio et publication non prouvés**.
- Le dernier commit a des clips Blender de jutsu **en cours et non encore integres**. Ne pas les presenter comme des animations livrees dans le jeu.

## 2. BETA : quatre objectifs, dans cet ordre de verification

### B1. Promesse sensible en 60 secondes — « je suis un ninja »

Probleme signale par l'utilisateur : toujours pas d'effet « waouh », alors que les systemes se sont multiplies. Diagnostic a verifier avec du vrai gameplay, pas avec le nombre de clips et la reussite des tests.

Tests utilisateurs sur le build exact :
1. Un joueur inconnu comprend comment bouger et frapper sans intervention.
2. Il accomplit rapidement une attaque signature et voit son effet sur l'adversaire/le terrain.
3. Il peut se deplacer, esquiver, changer d'angle et poursuivre avec intention ; aucune sensation d'action refusee injustifiee.
4. Un duel entier reste lisible et entrainant, y compris lorsque VFX et camera sont plus sobres.
5. Sa premiere fin de combat donne envie d'une revanche.

**Methode** : enregistrer des sequences de jeu aux vraies touches (PC, manette, telephone si support), noter les 3 ruptures de sensation/visibilite par scenario, corriger **le probleme observe** puis revoir la meme sequence. Ne pas commander une refonte generale de Blender/animations, ni mesurer seulement les degres par frame. Tenir distinctes preuve TECHNICAL, NATIVE_STUDIO, HUMAN_VISUAL/FEEL, LIVE_ROBLOX.

### B2. Friction debutant / commandes

Risques a tester : complexite des combinaisons de touches, page des signes, densite de l'UI telephone, perception de freezes/hitstun, transitions tutoriel > duel > resultat. Les correctifs V35 ne sont pas une validation d'ergonomie.

Cible de conception (hypotheses, pas stats actuelles) : une **premiere minute memorable**, peu de boutons indispensables au debut ; tutorial avance disponible mais non impose entierement avant un duel ; revelation progressive des mecanismes et entrainement optionnel. Mesurer temps avant 1ere action, 1ere technique, 1er duel, refus de commandes, abandon.

### B3. Fonctionner avec tres peu de joueurs

Le tournoi IA est un avantage concurrentiel : une personne seule doit trouver un match satisfaisant. Conserver la liste des joueurs et les defis directs. La file casual de `Online` est locale au serveur ; la presence interserveurs + CHALLENGE ne garantissent pas **une queue automatique globale**.

**Candidat**, uniquement apres test live du PvP existant : une seule file globale « duel rapide », capable d'appairer des joueurs de serveurs differents puis de les rejoindre en securite. Eviter plusieurs files (ranked/casual/region/modes) qui dispersent la faible population. Ne pas utiliser un bot en se faisant passer pour un humain. Preconditions : NET-001, latence acceptable, refus/timeout/recherche/teleport observes sur 2 vrais comptes.

### B4. Distribution et qualite du trafic

Avant de pousser le budget pub : recuperer **liens publics Roblox/TikTok/YouTube/Discord + donnees reelles**. Sans ces sources, impossible d'attribuer les faibles arrives aux videos, a l'algorithme, a la fiche Roblox ou au gameplay.

Construire un funnel simple :
- impressions / vues pertinentes de video ;
- visite fiche experience Roblox (lorsque mesurable) ;
- lancement ;
- premier combat ;
- premiere session terminee ;
- retour J1/J7 ;
- amis invites ou parties entre amis.

Tester des videos montrant **une situation jouee**, plutot qu'un inventaire de fonctionnalites : surprise de combat, choix creatif avec un meme jutsu, rivalite/defi, progression de maitrise. Conserver les variations, format, CTA, lien et resultats. TikTok sert a la decouverte ; YouTube montre la profondeur et les vrais matchs ; Discord aide a reunir les premiers testeurs et fixer des rendez-vous, pas a remplacer les fonctions de jeu.

**Ne pas acheter du trafic pour compenser un parcours debutant frustrant.** Les seuils de test doivent etre fixes apres observation de donnees reelles ; aucun chiffre de retention ou de conversion n'est invente dans cette revue.

## 3. JEU V1 : parcours de produit cible (NE PAS exiger pour lancer la beta)

1. **Hub de tournoi dense** (DEC-023) : pas de ville vide. Acces immediate a combat, practice, progression et observation ; PNJ et activite IA rendent le lieu vivant si aucun humain n'est connecte. Pas de temps de marche force.
2. **Progression persistante + maitrise** (DEC-024, PROG-001/002) : investir dans une identite de personnage, developper des variantes et choix qualitatifs ; ne pas convertir une seule victoire en course aux statistiques. Etat de persistance/release a valider avant promesse marketing.
3. **Tournois PvP et competition** : matchmaking fiable, retour rapide au duel, classement lorsque la population le justifie, builds de tournoi a budget standardise, pas d'avantage pay-to-win competitif.
4. **Roster complet par qualite** : faire entrer les 12 autres personnages a mesure de leur validation player-facing ; ne pas lancer une extension uniquement pour annoncer « 20 fighters ».
5. **Boucle sociale, status et monetisation** : rivalites, replays/partages si faisables, recompenser le style et la maitrise, cosmétiques/confort/temps sans achat de puissance en ranked. Mesurer la retention avant monetisation.
6. **Marque/IP et performance** : les noms/personnages/techniques Naruto soulevent un risque de droits pour une exploitation commerciale durable ; clarifier les droits ou adopter une direction originale avant amplification payante. Performance et accessibilite sur appareils Roblox reels a prouver.

## 4. Regle de priorisation / anti-mission interminable

Le prochain travail doit partir d'une preuve observable et finir par la meme preuve re-testee. Trois questions a chaque livraison :
- Qu'est-ce que l'utilisateur **voit ou ressent differemment** en jouant ?
- Quel blocage d'un nouveau joueur ou du PvP est **eliminee en vrai** ?
- Quelle donnee permettra de juger si le changement a accru l'interet ou la retention ?

Arbitrer **B1 + B2 + validation B3** avant de grossir contenu et marketing. Conserver l'autonomie actuelle de Claude (DEC-030) et son chantier en cours. Une seule priorite approuvee a la fois, pas une « mission » de 40 sous-taches qui detourne de la qualite visible.

## 5. Decisions NON prises par cette revue

Ce document **ne decide pas** :
- de stopper la production actuelle, de suspendre Claude ou de lui attribuer automatiquement B1–B4 ;
- de repousser ou d'annoncer une date de beta ;
- d'implementer une queue globale, un hub, une economie, une progression, un ranked ou une nouvelle UI ;
- de depenser 50 euros de publicite ;
- que la V35 est publiee, validée sur mobile ou que le probleme visuel est resolu ;
- que les TikTok ont telle performance (comptes/stats absents).

## 6. Informations et preuves a obtenir en premier

**Produit** : URL Roblox/Universe/Place et version reellement publiee ; cinq enregistrements de vraies sessions incluant la premiere minute, le mouvement/mur, un jutsu signature, un duel, et un ecran de fin ; teste sur PC/mobile/manette.

**Multijoueur** : 2 comptes reels, serveurs distincts, chemin invitation → acceptation → teleport → selection → round → rematch → retour, avec latence et cas echec.

**Distribution** : comptes sociaux, au moins plusieurs videos et leurs vues/retention/CTA si disponibles, trafic/referrals Roblox et premiere session/revisites, sans pretendre calculer ce qui n'est pas mesure.

**Suite** : Claude et l'utilisateur choisissent un premier petit lot a partir de ces preuves et des tickets existants, puis seul ce lot est implemente et valide.
