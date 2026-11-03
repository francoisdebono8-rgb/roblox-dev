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

## Page Roblox (prête pour la publication)

- **Nom** : `Ninja Duel: Prodigy Tournament [BETA]`. Mieux vaut ne mettre « Naruto » ni dans le titre ni dans la description : c'est la façon la plus sûre d'attirer une plainte, et les joueurs reconnaissent les persos sans ça.
- **Genre** : Fighting. **Joueurs par serveur** : 2 à 10 (les duels se font par paires). **Appareils** : ordinateur, manette et mobile, après un essai tactile.
- **Description** :

  > ⚔️ 1v1 ninja duels. Pick one of the young prodigies of the tournament and fight with strings, throws, wall runs and jutsu.
  > 🥋 Training mode teaches your fighter in a few minutes.
  > 🤖 Fight the AI, or a friend with a private code, or anyone online.
  > 🧪 BETA: things change every week. Use the **BUG / IDEA** button in the game, or join the Discord, to tell us what to fix.

- **Icône (512×512)** : un combattant en buste de trois quarts sur fond d'encre, avec la bande vermillon, comme le menu. À capturer depuis `Client/MenuStage`.
- **Vignettes (1920×1080)** : trois captures.
  - Le menu avec deux combattants.
  - Un échange en duel sous la lumière de fin d'après-midi.
  - Un ultime.
- **Lien Discord** : sur la page de l'expérience, dans **Social Links** du Creator Dashboard.

## Liste avant la bêta publique

1. Partie 11 (en ligne) vérifiée à deux comptes : NET-001.
2. Les réglages de [FEEDBACK.md](FEEDBACK.md) faits (API, HTTP, secret).
3. Questionnaire de maturité Roblox rempli par l'utilisateur : combat sans sang, pas de chat vocal.
4. D'abord publiée en privé, puis ouverte aux amis et au Discord, puis publique.
5. Une annonce dans `#annonces` et un lien d'invitation Discord permanent sur la page Roblox.
