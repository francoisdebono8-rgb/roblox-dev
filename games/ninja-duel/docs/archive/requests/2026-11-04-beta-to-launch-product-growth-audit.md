# Ninja Duel — audit produit, bêta V34/V35, lancement public et jeu cible
Date : 2026-11-04. Origine : demande utilisateur d'un audit approfondi du jeu, de son manque de « waouh », de son multijoueur et de sa croissance TikTok/YouTube/Discord, puis demande explicite de commit GitHub.
Statut : **AUDIT ET PROPOSITION / NON ACTIVÉ COMME MISSION DE DÉVELOPPEMENT**. Aucun changement de scope ou d'ordre d'exécution n'est autorisé par ce seul document. Respecter EXECUTION_RULES : une mission active passe par arbitrage DECISIONS, déduplication MASTER_BACKLOG, puis inbox SINCE_LAST_CLAUDE ; ne pas interrompre le bloc Claude en cours.

## 0. Clarification fondamentale : trois horizons, un seul produit
- **BÊTA ACTUELLE (V34/V35)** : rendre la version déjà jouable convaincante, stable, compréhensible, visuellement forte et testable par des inconnus. Pas d'ajout automatique de personnages, de grande carte, de nouvelles mécaniques ou de nouveau moteur.
- **LANCEMENT PUBLIC / EARLY LIVE** : après gates bêta, assurer acquisition mesurable, matchmaking global fiable, expérience utile sans population, progression/rétention minimale, découverte Roblox, exploitation.
- **JEU CIBLE / POST-LANCEMENT** : hub social compact vivant, profondeur compétitive, mastery/skill trees équilibrés, tournois, communauté, nouveaux combattants après preuve de qualité et demande. Ne pas confondre ce backlog long terme avec les besoins de la bêta.
Le présent audit ne déclare ni V34 ni V35 « terminées », ni une validation live de la téléportation interserveurs, ni une preuve humaine de qualité visuelle.

## 1. Constat du dépôt et limites
- Roster bêta de huit, tournoi IA à huit, invitations interserveurs, serveurs réservés, sélection/manches/revanche, V34 signes/commandes, V35 touch, tutoriel adapté et sondes ; consulter le HEAD courant, CURRENT_STATE, Shared/BetaRoster, Server/Online, Server/Lobby, Server/Tournament, Server/Tutorial, Client/UI, Client/TouchControls.
- Le nombre de clips, la réussite des tests headless et la présence d'une interface ne prouvent pas le **feel** humain. Rejouer le build exact dans Studio et le build Roblox publié.
- Signal historique à reproduire et re-mesurer : contrôle perdu sous les coups IA (rapport 03/11 : 16–27 % du temps en simulation et jusqu'à 4,5 s sur ultime), « freeze » perçu, coups aériens, snaps visuels, commandes trop nombreuses, durées de combat, vitesse/effets gênants. Ces chiffres ne sont PAS des mesures de la V35 actuelle.
- Le marketing ne peut être audité quantitativement sans URL du jeu, des réseaux, statistiques des vidéos, page Roblox, acquisition et rétention. Ne jamais inventer vues, conversion, CCU, D1, CTR ou qualité du live.
- Risque IP majeur : personnages, noms, techniques, visuels et marques Naruto. Avant monétisation/promotion importante, évaluer autorisations/licences et stratégie originale si nécessaire.

## 2. Diagnostic produit : le « waouh » est une propriété du combat joué
L'USP n'est pas « huit personnages et beaucoup de jutsu », mais « incarner un ninja et inventer sa manière de combattre avec son corps, ses outils, son chakra et l'espace ». Ne pas devenir un battleground à quatre cooldowns, ni une chorégraphie Storm non interactive.
**Cinq dimensions à juger ensemble** :
1. Corps : silhouettes, anticipation, appuis, poids, trajectoires, timing, transitions, retours au neutral, course/mur/air.
2. Conséquence : réaction corporelle et environnementale, contacts, lisibilité des dommages et trajectoires, sons et poussière utiles.
3. Caméra : suivi stable, lisibilité des distances, impact sans nausée ni shake permanent.
4. Contrôle : latence perçue, buffer/cancel, sortie de hitstun, punition lisible versus blocage subi ; aucune promesse « free combat » contredite par des locks prolongés.
5. Identité : Minato marques/angles, Sasuke verticalité/Chidori/Katon, Gaara zone, Neji précision, etc. Les signatures doivent être reconnaissables SANS UI ni VFX excessifs.
**Test obligatoire avant/après** : six scènes réelles : arrivée, premier coup, course→saut→mur→attaque→atterrissage, signature, duel complet, KO/revanche. Enregistrer VFX ON et OFF, vraie sélection et vrais inputs, même build hash ; lister top trois défauts observables par scène, corriger, reconstruire, rejouer. Interdire les « succès » fondés seulement sur nombre de clips/commits ou vidéos debug. Mesurer et documenter la part de temps sans décision possible, snaps, actions refusées, performance mobile et réseau.

## 3. Ergonomie et première session — bêta P0
- Préserver profondeur mais proposer une couche de maîtrise immédiate : se déplacer, attaquer, esquiver, une technique signature. Le joueur expert garde outils, routes, signes, cancels et chakra.
- Audit des commandes V34 et du TouchControls V35 sur PC AZERTY/QWERTY, manette, vrais mobiles : densité de boutons, chevauchements, lisibilité, gestes simultanés, confort, refus/feedback, accès à jutsu secondaires.
- Conserver tutoriel exhaustif et ses probes comme mode Practice/QA ; créer un **parcours d'introduction bref** visant premier input <15 s, première action spectaculaire <45 s, premier duel dans les 3 premières minutes (cibles hypothétiques à valider). Aucun long cours obligatoire avant le plaisir.
- Dix nouveaux testeurs non briefés si possible : observer leurs hésitations et abandons ; enregistrer premiers inputs, première attaque, premier jutsu, premier duel terminé, retour au menu, relance. Ne pas interpréter les tests bot comme acceptation utilisateur.
- Prioriser la réduction des moments « le jeu ne répond plus » ; préserver punition tactique, pas une invulnérabilité permanente.

## 4. Modes, online et cold start — bêta → lancement
**Bêta** : valider réellement avec deux comptes et deux serveurs Roblox publiés : présence MemoryStore, MessagingService, invitation, accept/refus, réservation/téléport, no-show, échec teleport, retour au roster, revanche, spam et déconnexions ; documenter LIVE_ROBLOX PASS/PENDING/FAIL par scénario. Ne pas annoncer le cross-server complet sans cela.
**Lancement** : une file **Quick Duel globale** (cross-server) et défis directs en parallèle, avec protection contre doubles inscriptions, expiration, échecs de téléport, no-show, reconnection/cleanup, rate limits, budget MemoryStore, latence/région, matching progressif, anti-abus. N'ouvrir qu'une file principale tant que le CCU est faible ; ne pas segmenter casual/ranked/équipe par défaut. Ne pas implémenter sans décision et tests de charge.
**Sans population** : le tournoi IA et Practice sont de vrais modes autonomes ; tournoi rapide, skip visible, récompense/objectif non pay-to-win, motivation à refaire. Ne pas dépendre d'un hub social peuplé ; un hub futur doit être vivant à 1 joueur et permettre combat en quelques dizaines de secondes. Le lobby est un complément, pas un obstacle.

## 5. Distribution et conversion — lancement, pas simple volume de posts
- Public primaire à tester : joueurs Roblox anime/combat intéressés par Naruto et le skill expression ; second public Roblox action/compétition. Tester promesses distinctes, pas viser tout Roblox avec la même vidéo.
- Quatre angles créatifs : (A) spectacle clair en 3–10 s, (B) même pouvoir deux usages libres, (C) défi/rivalité/tournoi, (D) novice vs expert. Montrer des captures authentiques du build actuel, pas des séquences mises en scène impossibles à reproduire.
- TikTok = découverte ; YouTube Shorts = découverte + YouTube long = preuve du combat réel ; Discord = communauté, testeurs, tournois, feedback ; la recherche d'adversaire doit fonctionner dans Roblox sans Discord.
- Auditer page Roblox : nom et risque IP, icône, thumbnails, premières secondes, description, accès, appareils supportés, attentes induites par les vidéos, CTA clair, lien traçable quand disponible. Ne pas vendre « nouvelle map immense » si jeu d'arène.
- Instrumenter funnel par source/campagne quand permis : impressions vidéo → clics/visites fiche → lancement → première action → premier duel terminé → session >3 min → J1/J7 → retour au PvP / invitation ami. Séparer signaux internes, Analytics Roblox et plateformes sociales ; pas de causalité inventée.
- Une vidéo à beaucoup de vues sans joueurs n'indique pas nécessairement un mauvais jeu : diagnostiquer séparément hook, ciblage, friction vers Roblox, page, compatibilité, premier combat, rétention.
- Ne pas dépenser même un petit budget pub avant que la bêta soit stable, mesurée et plaisante à l'entrée. Budget de test limité, hypothèses préenregistrées, seuil d'arrêt si abandon élevé.

## 6. Gates et priorités recommandées
### Gate B0 — reproductibilité et preuves (bêta)
- Capturer commit/build exact et parcours complet PC/manette/mobile ; établir baseline des six scènes et des bugs ; deux vrais comptes en live.
- Sortie : tableau de preuves TECHNICAL / NATIVE_STUDIO / HUMAN_VISUAL_FEEL / LIVE_ROBLOX, vidéos comparables et top dix défauts classés par sévérité/fréquence/impact.

### Gate B1 — premier plaisir + feel (bêta)
- Corriger P0 contrôles/freezes/air/wall/caméra/impacts ; intro de première minute, 1 signature Sasuke et 1 Minato exceptionnellement réussies ; pas de nouvelle feature décorative.
- Sortie : testeurs novices terminent le premier duel et veulent volontairement rejouer ; défauts restants visibles consignés.

### Gate B2 — boucle autonome + online prouvé (bêta)
- Tournoi IA et Practice sans attente ni séquence imposée excessive ; challenge live interserveurs vérifié ; feedback d'erreur utile.
- Sortie : un joueur seul a un objectif ; deux joueurs peuvent se retrouver, combattre, rejouer et sortir.

### Gate L1 — lancement contrôlé
- Matchmaking Quick Duel si confirmé nécessaire par tests ; télémétrie funnel et rétention ; page Roblox crédible ; tests vidéos organiques avec attribution.
- Sortie : acquisition et retour mesurables, aucun lancement public massif avant qualité.

### Gate F1 — produit durable
- Progression/maîtrise, ranked/tournois équilibrés, hub compact vivant, identité de marque et IP sécurisées, extension roster uniquement après gates de qualité. Éviter pay-to-win.

## 7. Tests de décision (pas des promesses)
- 10 nouveaux joueurs non guidés : noter « compréhension, plaisir, bugs, envie de rejouer », vidéos des 3 premières minutes ; objectif proposé 70 % premier duel terminé dans ce panel, à réviser selon données.
- Tester 4 familles de TikTok/Shorts à cadence et audience comparables ; analyser la **qualité des arrivées** et non les vues seules.
- Tests live interserveurs avec échecs volontaires ; logs et temps d'attente.
- Une vidéo complète de 60–90 s du vrai duel, sans debug, pour juger l'USP, avec et sans VFX.
- Revue comparative de 3–5 jeux Roblox pertinents (acquisition, onboarding, commandes, effets, matchmaking) seulement après recherche de sources actuelles et captures, sans imitation aveugle.

## 8. Ce que Claude ne doit PAS inférer de ce document
- Ce n'est PAS une demande de tout développer, de commencer V36, de créer un monde ouvert, d'ajouter 20 combattants, de réécrire le moteur ou de publier/acheter des publicités.
- Ne pas interrompre un chantier actif sans décision explicite. Les tickets existants (QA-001, QA-004, NET-001, REL-001, COM/CHR et progression) doivent être cherchés et enrichis, pas dupliqués.
- Ne pas annoncer de validation mobile, humaine ou LIVE sur des tests simulés. Ne pas affirmer que la bêta V35 est la version réellement publiée sans preuve.
- La direction **bêta vs final** est fixée ici comme proposition de séquencement ; toute mise en exécution doit suivre les sources actives et l'accord utilisateur.

## 9. Prochaine décision attendue de l'utilisateur
Choisir le premier lot concret : **B0 audit du build joué + tests novices + validation live**, puis B1, plutôt qu'un chantier « tout améliorer ». Recueillir URL Roblox publiée, comptes TikTok/YouTube/Discord et analytics pour compléter l'audit commercial. Une fois validé, intégrer les exigences dans les tickets existants et l'inbox, avec propriétaire et critères de clôture.
