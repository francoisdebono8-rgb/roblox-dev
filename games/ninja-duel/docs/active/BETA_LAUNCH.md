# Lancement de la bêta : Discord, page Roblox, recrutement

Demande utilisateur, 03/11 : « commercialisation de la bêta […] pour qu'on ait un peu des joueurs et un moyen de récolter leurs avis et les bugs ».

Décisions du 03/11 :

- **Retours** : dans le jeu ET sur Discord.
- **Personnages** : publics tels quels. Rien n'est à vendre.
- **Publication** : quand la bêta sera prête, pas avant.
- **Discord** : monté par Claude dans le navigateur de l'utilisateur.

Les retours venus du jeu sont décrits dans [FEEDBACK.md](FEEDBACK.md).

## Discord

Nom du serveur : **Ninja Duel — Prodigy Tournament**. Salons textes simples, sans serveur « Communauté » : ce mode demande d'accepter les règles Discord, et c'est à l'utilisateur de le faire.

| Catégorie | Salon | Qui écrit |
|---|---|---|
| INFOS | `#bienvenue` | équipe |
| | `#règles` | équipe |
| | `#annonces` | équipe |
| | `#comment-jouer` | équipe |
| BÊTA | `#bugs` | tous (modèle épinglé) |
| | `#idées` | tous |
| | `#avis` | tous |
| | `#rapports-du-jeu` | le jeu seul (webhook) |
| COMMUNAUTÉ | `#général` | tous |
| | `#clips-et-captures` | tous |
| | `#cherche-un-adversaire` | tous |
| | 🔊 Vocal | tous |

Rôles :

- **Équipe** : gère le serveur.
- **Testeur bêta** : donné à ceux qui rapportent un bug reproduit.
- `@everyone` : écrit dans BÊTA et COMMUNAUTÉ.

### Textes (EN puis FR)

**#bienvenue**

> **Welcome to Ninja Duel!** ⚔️ A 1v1 ninja fighting game on Roblox: twenty young prodigies, one tournament stage.
> The game is in **beta**: it changes every week, and *you* decide what gets fixed first.
> • Found a bug? → #bugs (or the **BUG / IDEA** button in the game)
> • Want something? → #idées
> • Tell us how it feels → #avis
> Read #règles, then have fun.
>
> **Bienvenue sur Ninja Duel !** ⚔️ Un jeu de combat ninja en 1 contre 1 sur Roblox : vingt jeunes prodiges, une seule arène de tournoi.
> Le jeu est en **bêta** : il change chaque semaine, et c'est *vous* qui décidez de ce qu'on corrige en premier.
> • Un bug ? → #bugs (ou le bouton **BUG / IDEA** dans le jeu)
> • Une envie ? → #idées
> • Votre ressenti → #avis
> Lisez #règles, et amusez-vous.

**#règles**

> 1. Be kind. No insults, harassment, hate or discrimination. / Soyez respectueux : pas d'insultes, de harcèlement, de haine ni de discrimination.
> 2. No personal info: yours or anyone's (address, phone, school, photos). / Aucune info personnelle, ni la vôtre ni celle des autres (adresse, téléphone, école, photos).
> 3. No spam, no ads, no links to other servers or scams. / Pas de spam, de pub, de liens vers d'autres serveurs ni d'arnaques.
> 4. No cheats or exploits: report them in #bugs, don't share them. / Pas de triche ni d'exploit : signalez-les dans #bugs, ne les partagez pas.
> 5. Discord's own rules apply, including the minimum age of 13. / Les règles de Discord s'appliquent, y compris l'âge minimum de 13 ans.
> Breaking a rule = warning, then removal. / Une règle enfreinte = un avertissement, puis l'exclusion.

**#bugs** (message épinglé)

> **How to report a bug / Comment signaler un bug**
> 1. **What happened? / Qu'est-ce qui s'est passé ?**
> 2. **What were you doing? / Que faisiez-vous ?** (fighter, opponent, move or jutsu / perso, adversaire, coup ou jutsu)
> 3. **Does it happen again? / Ça se reproduit ?**
> 4. A screenshot or a clip if you can. / Une capture ou un clip si possible.
> Faster: the **BUG / IDEA** button in the game sends it with all the details. / Plus rapide : le bouton **BUG / IDEA** du jeu l'envoie avec tous les détails.

**#comment-jouer**

> **Controls / Contrôles**: press **Tab** (gamepad: **Start**) in the game for the full list. / appuyez sur **Tab** (manette : **Start**) dans le jeu pour la liste complète.
> Start with **TRAINING** on the roster: a short tutorial adapted to your fighter. / Commencez par **TRAINING** dans le roster : un court tutoriel adapté à votre combattant.

**#annonces** (premier message, à l'ouverture de la bêta)

> 🎉 **The Ninja Duel beta is open!** Play here: <lien Roblox>. Eight fighters to start, twelve more joining one by one. Your reports shape the next updates. / **La bêta de Ninja Duel est ouverte !** Jouez ici : <lien Roblox>. Huit combattants pour commencer, douze autres arrivent un par un. Vos retours décident des prochaines mises à jour.

### État du Discord (03/11, monté par Claude)

Compte créateur `ninjaduelcreator`. Serveur **Ninja Duel — Prodigy Tournament**.

- **Invitation permanente** : https://discord.gg/mJ6Gyax7W
- **Icône** : 忍 dans un cercle d'encre, sur la bande vermillon du menu. Fichiers dans `assets/brand/`. Bannière rouge.
- **Salons** :
  - INFOS, en lecture seule : `#bienvenue`, `#règles`, `#annonces`, `#comment-jouer`. Les messages de bienvenue, de règles et de comment-jouer sont postés.
  - BÊTA :
    - `#bugs` : forum avec guide de post et tags Combat / Caméra / Interface / Personnage / En ligne / Crash, plus Reproduit / Corrigé réservés aux modérateurs ;
    - `#idées` : forum avec guide, tags et réaction 👍, plus Prévu / Ajouté réservés aux modérateurs ;
    - `#avis` ;
    - `#rapports-du-jeu` : en lecture seule, avec le webhook « Ninja Duel — reports ».
  - COMMUNAUTÉ : `#discussion`, `#clips-et-captures`, `#cherche-un-adversaire`, `#général`, et les salons vocaux Général et Vocal.
- **Rôles** :
  - Équipe : expulser, exclure temporairement, gérer les messages, épingler ;
  - Testeur bêta.
- **Sécurité** :
  - niveau de vérification Moyen ;
  - filtre des médias sensibles pour tout le monde ;
  - AutoMod contre le spam de mentions (plus de 6), le spam et les mots signalés.
- **Webhook** : son URL n'est écrite nulle part. Elle se copie dans Discord : `#rapports-du-jeu` → Modifier le salon → Intégrations → Webhooks → Ninja Duel — reports → **Copier l'URL**. Elle va dans le secret `feedback_webhook` ([FEEDBACK.md](FEEDBACK.md)).
- **À faire par l'utilisateur** :
  - confirmer l'e-mail du compte (bandeau vert dans Discord) ;
  - activer la double authentification (A2F) ;
  - passer le serveur en « Communauté » s'il veut apparaître dans la découverte, ce qui demande d'accepter les règles Discord.

## Page Roblox (prête pour la publication)

- **Nom** : `Ninja Duel: Prodigy Tournament [BETA]`. Mieux vaut ne mettre « Naruto » ni dans le titre ni dans la description : c'est la façon la plus sûre d'attirer une plainte, et les joueurs reconnaissent les persos sans ça.
- **Genre** : Fighting. **Joueurs par serveur** : 2 à 10 (les duels se font par paires). **Appareils** : ordinateur, manette et mobile, après un essai tactile.
- **Description** :

  > ⚔️ 1v1 ninja duels. Pick one of the young prodigies of the tournament and fight with strings, throws, wall runs and jutsu.
  > 🥋 Training mode teaches your fighter in a few minutes.
  > 🤖 Fight the AI, or a friend with a private code, or anyone online.
  > 🧪 BETA: things change every week. Use the **BUG / IDEA** button in the game, or join the Discord, to tell us what to fix.

- **Visuels** : voir « Visuels de la page Roblox » plus bas.
- **Lien Discord** : sur la page de l'expérience, dans **Social Links** du Creator Dashboard.

## Visuels de la page Roblox (à produire dans un second temps)

Une seule identité partout, la même que le menu et le Discord : fond d'encre, bande vermillon à -9°, titres en Bangers papier cerclés d'encre, sceau rouge. L'icône Discord est dans `assets/brand/`, avec son générateur `icon.py`.

### Icône du jeu (512×512)

- **A, recommandée** : un combattant en buste de trois quarts, sous la lumière du menu (`Client/MenuStage`). Il prend la moitié gauche, et le cercle d'encre et 忍 sont en filigrane derrière lui. C'est le personnage qui fait cliquer.
- **B** : deux silhouettes dos à dos (le prodige et son rival) coupées par la bande vermillon.
- **C** : l'icône Discord telle quelle. C'est la plus cohérente, mais elle montre peu le jeu.

À tester : A/B, avec les tests d'icônes du Creator Dashboard s'ils sont disponibles sur le compte.

### Vignettes (1920×1080, jusqu'à 10)

Chacune montre une promesse du jeu, avec trois à cinq mots au plus en surimpression.

| # | Image | Texte | Comment l'obtenir |
|---|---|---|---|
| 1 | Le menu : deux prodiges face à face, VS au milieu | 1v1 NINJA DUELS | Capture du menu |
| 2 | Un impact au corps à corps, l'étincelle, les deux corps lisibles | READ. STRIKE. PUNISH. | Caméra de duel, figée au moment du coup |
| 3 | Un ultime en plein écran (Rasengan, Chidori ou sable de Gaara) | EVERY PRODIGY HAS AN ULTIMATE | Caméra de cinématique |
| 4 | Une course sur le mur de l'arène, l'adversaire en contrebas | USE THE WHOLE ARENA | Caméra basse, grand-angle |
| 5 | La grille des huit combattants de la bêta | 8 FIGHTERS · MORE EVERY UPDATE | Composition du roster avec des portraits |
| 6 | Le tutoriel, la fiche des contrôles ouverte | LEARN IN 2 MINUTES | Capture avec Tab ouvert |
| 7 | Deux joueurs, le code de duel privé affiché | DUEL YOUR FRIENDS | Capture de l'écran HOST |
| 8 | Le sceau 勝, la carte de victoire | WIN THE TOURNAMENT | Capture de l'écran de fin |

Les vignettes 1 à 3 sont les plus vues : elles passent en premier.

### Vidéo de gameplay (30 s)

Plan proposé :

- **0–3 s** : noir d'encre, le coup de pinceau vermillon traverse l'écran (le balayage du jeu), le titre « NINJA DUEL ».
- **3–8 s** : le menu, deux combattants entrent sur scène, VS.
- **8–20 s** : six plans de deux secondes, un par promesse. Enchaînement, projection, course sur le mur, poursuite en l'air, technique, garde puis riposte.
- **20–26 s** : un ultime en entier.
- **26–30 s** : le sceau 勝, puis « BETA — PLAY NOW », avec le lien Discord.

Méthode :

- Les plans sont tournés dans Studio, avec la caméra de duel et le pilote automatique des deux côtés.
- Le son du jeu est laissé en place, avec une musique libre de droits.
- La même vidéo sert pour la page Roblox, le salon #annonces et les réseaux (TikTok, Shorts) en version verticale 9:16.

### À fournir par l'utilisateur

- Le choix de l'icône, A, B ou C.
- La musique de la vidéo, si tu en as une préférée.

## Faire venir du monde (plan du 03/11)

Le principe : avant la bêta publique, il n'y a rien à jouer. Ce qui fait venir, c'est **voir le jeu se construire** et **jouer avant les autres**.

Le Discord promet donc l'accès anticipé. Le rôle **Testeur bêta** ouvre des sessions de test sur invitation, sur la place privée, avec Claude qui fait tourner les builds.

### 1. Vidéos courtes : le levier principal

Pour un jeu Roblox, la découverte passe par TikTok, YouTube Shorts et Reels.

- **Un compte au nom du jeu** sur chaque plateforme, avec l'adresse e-mail du jeu. C'est l'utilisateur qui le crée.
- **Rythme** : 3 clips par semaine, de 10 à 20 s. Le plus fort dans la première seconde (un impact, un ultime), du texte à l'écran, la musique tendance du moment.
- **Formats qui marchent** :
  1. « Je crée un jeu de combat ninja sur Roblox — jour N » : un avant/après d'une animation ou d'une technique.
  2. Un ultime en entier, sans texte.
  3. « Quel ninja j'ajoute ensuite ? » avec trois portraits du menu. Les commentaires répondent, et on renvoie vers le vote sur Discord.
  4. Un bug drôle, puis sa correction. Le public adore, et ça montre que les retours servent.
  5. Le combo le plus long de la semaine, envoyé par un joueur dans `#clips-et-captures`.
- **Lien en bio** : l'invitation Discord. En légende : « Beta testers wanted → Discord in bio ».
- **Tournage** : Claude prépare les plans dans Studio (caméra de duel, pilote automatique, lumière du jeu) et les exporte. L'utilisateur poste depuis son téléphone.

### 2. Roblox même

- **Dans le jeu, c'est fait (03/11)** : le menu affiche « JOIN THE COMMUNITY • discord.gg/mJ6Gyax7W » sous BUG / IDEA, et le formulaire de retour le rappelle aussi. Ce n'est montré qu'aux joueurs que Roblox autorise à voir une référence Discord (PolicyService : âge, pays). Les autres ne voient rien et gardent le bouton du jeu.
- **Page de l'expérience** : le lien Discord dans Social Links, une fois l'expérience publiée.
- **Groupe Roblox « Ninja Duel »** : il possède le jeu, ses annonces (shouts) arrivent aux membres, et on peut lui donner un rôle « Beta tester » pour accéder à la place privée.
- **Publicité Roblox** (Ads Manager), seulement après la bêta publique : un petit budget test sur la meilleure vignette, et on mesure les visites.

### 3. Communautés existantes

Il faut toujours lire les règles du sous-forum avant de poster. On montre le jeu, on demande un avis, et on ne colle jamais juste un lien.

- **Reddit `r/robloxgamedev`** : un devlog court avec un GIF, et une question précise (« does the hit feel heavy enough? »).
- **Reddit `r/roblox`** : le jour de la bêta seulement, avec une vidéo.
- **Forum développeurs Roblox** (catégorie retours de créations) : pour des avis de développeurs, dès qu'on y a accès.
- **Annuaires de serveurs Discord** (type Disboard) : il faut y ajouter leur bot, et c'est à l'utilisateur de le valider.
- **Petits créateurs YouTube et TikTok Roblox** (1 000 à 50 000 abonnés) qui font des jeux de combat ou d'anime : on leur propose l'accès anticipé, et un rôle « Créateur » sur le Discord.

### 4. Garder les gens une fois venus

- Le **devlog du vendredi** dans `#annonces` : ce qui a changé grâce à eux, avec les bugs signalés corrigés et leurs auteurs remerciés.
- Une **session de test le samedi** pour les testeurs bêta, et un tournoi interne quand il y a assez de joueurs.
- Un **vote** sur le prochain combattant ou le prochain changement. Les idées les plus 👍 de `#idées` sont lues en premier.
- Le rôle **Testeur bêta** pour chaque bug reproduit. Il est donné à la main au début.

### 5. Mesurer

Un lien d'invitation par source (TikTok, YouTube, Reddit, page Roblox, jeu). Discord affiche combien de personnes chaque lien a amenées : on garde ce qui marche.

### Textes prêts

**Bio TikTok / YouTube / Instagram**

> 1v1 ninja fighting game on Roblox 🥷⚔️ · Beta testers wanted · Discord ↓

**Légende du premier clip**

> I'm making a ninja fighting game on Roblox. Day 1 of showing you until the beta. Want to test it before everyone? Discord in bio. #roblox #robloxdev #ninja #anime #fightinggame

**Devlog `r/robloxgamedev`**

> **Title:** My 1v1 ninja fighting game: wall runs, throws and ultimates. Does the combat read well?
>
> I've been building a 1v1 fighting game on Roblox (R15, server-authoritative, hand-animated in Blender). Here's a 20s clip of a duel. I'm looking for feedback on two things: (1) can you tell who's attacking and who's defending at each moment? (2) does the hit feel heavy enough? Beta testers welcome; there's a Discord if you want in.

**Message à un petit créateur**

> Hi! I'm the dev of Ninja Duel, a 1v1 ninja fighting game on Roblox (clip attached). We're opening a closed beta and I'd love you to be one of the first to try it, before anyone else, with your own code for a private duel. No obligation to post anything; if you like it, you're welcome to. Our Discord: discord.gg/mJ6Gyax7W

**Annonce Discord (ouverture des inscriptions)**

> 🧪 **Closed beta testers wanted!** React ✅ to get the Beta tester role: first sessions soon, with the 8 first fighters. Every bug you report and every idea you post is read. / **On cherche des testeurs !** Réagissez ✅ pour le rôle Testeur bêta : premières sessions bientôt, avec les 8 premiers combattants.

**Annonce « À quoi sert la bêta »** (à épingler dans `#annonces` à l'ouverture des inscriptions, puis à reprendre dans la description du jeu)

> 🧪 **What this beta is for**
> Right now you play the tournament's prodigies. This beta is here to test the heart of the game: **the combat system, the attacks, the arena and the lighting**. Tell us what feels good, what feels off, and what breaks.
> **What comes next**: playing **your own Roblox avatar**, choosing your **fighting style**, and growing it through a **skill tree**. Your feedback on the combat now decides how that next part is built.
>
> 🧪 **À quoi sert cette bêta**
> Pour l'instant, vous jouez les prodiges du tournoi. La bêta sert à tester le cœur du jeu : **le système de combat, les attaques, l'arène et la lumière**. Dites-nous ce qui est agréable, ce qui cloche et ce qui casse.
> **La suite** : jouer **votre propre avatar Roblox**, choisir votre **style de combat** et le faire grandir avec un **arbre de compétences**. Vos retours sur le combat décident de la façon dont on construit cette suite.

### À faire par l'utilisateur

- Créer les comptes TikTok, YouTube et Instagram du jeu avec l'adresse e-mail du jeu, et y mettre la bio.
- Valider l'ajout d'un bot d'annuaire si tu veux être listé.

Claude s'occupe du reste :

- les clips ;
- les textes ;
- les liens d'invitation par source ;
- le devlog du vendredi ;
- le tri des retours.

## Liste avant la bêta publique

1. Partie 11 (en ligne) vérifiée à deux comptes : NET-001.
2. Les réglages de [FEEDBACK.md](FEEDBACK.md) faits (API, HTTP, secret).
3. Questionnaire de maturité Roblox rempli par l'utilisateur : combat sans sang, pas de chat vocal.
4. D'abord publiée en privé, puis ouverte aux amis et au Discord, puis publique.
5. Une annonce dans `#annonces` et un lien d'invitation Discord permanent sur la page Roblox.
