# Légendes des clips (TikTok / YouTube Shorts)

Série : **WHO WINS?** Chaque épisode oppose deux ninjas du jeu. La partie 2 montre le vrai combat dans le jeu, IA contre IA.

## Épisode 1 : Naruto vs Sasuke

**TikTok**

> Who wins? 🍥 vs ⚡ Comment below, part 2 = they fight in my Roblox game 👀 #roblox #naruto #anime #robloxgames #ninja #fyp

**YouTube Shorts**

- **Titre :** `WHO WINS? Naruto vs Sasuke ⚔️ (Roblox Ninja Duel)`
- **Description :**

  > Comment your pick! Part 2: they fight for real in Ninja Duel, my 1v1 anime ninja game on Roblox (free, beta). Search "Ninja Duel" on Roblox. #roblox #anime #shorts

## Épisode 2 : Rock Lee vs Gaara

**TikTok**

> Who wins? 🥋 vs 🏜️ Taijutsu vs sand… comment your pick, part 2 they fight in-game #roblox #rocklee #gaara #anime #robloxgames #fyp

**YouTube Shorts**

- **Titre :** `WHO WINS? Rock Lee vs Gaara ⚔️ (Roblox Ninja Duel)`

## Règles de la série

- La question « WHO WINS? » est visible dès la première image.
- Les deux noms sont affichés en grand.
- La fin propose de voter en commentaire et annonce la partie 2.
- Musique : pour sortir d'office, la piste de batterie intégrée suffit. Pour la portée, mieux vaut ajouter un son tendance dans TikTok, en baissant le son d'origine à 30 %.
- Épingler en commentaire : « Part 2 tomorrow — Discord link in bio for early access ».

## Version gameplay (04/11)

Les épisodes 1 et 2 ont été refaits avec de vrais combats IA contre IA, filmés dans Studio. Le combat s'arrête sur le coup final, puis s'affiche « WHO WINS? / COMMENT YOUR PICK / RESULT IN PART 2 ».

- **Fichiers** : `Documents/NinjaDuelMedia/Clips/WhoWins_0X_gameplay_*.mp4` sur le Mac, et la branche `media-clips` du dépôt.
- **YouTube** : les deux sont en brouillon privé, avec titre et description. Il reste à l'utilisateur à cocher « conçue pour les enfants ? » (c'est sa déclaration), puis à choisir la visibilité et publier.
- **TikTok** : TikTok refuse l'import automatique depuis le navigateur. On poste depuis le téléphone avec la légende ci-dessus et un son tendance, en mettant le son d'origine à 30 %.
- **Résultats réels pour les parties 2** : Naruto bat Sasuke 2-1, Gaara bat Rock Lee 2-0.

**Chaîne de fabrication** (`tools/marketing/video/`) :
1. Enregistrement plein écran pendant que l'IA joue des deux côtés (dev hook `autopilot`).
2. Découpe sans réencodage sur le Mac, puis montage dans le cloud.
3. `track.py` suit les couleurs des combattants pour cadrer automatiquement la vue verticale.
4. `gp_ep.py` assemble le tout : bandeau titre, barres de vie du jeu, légendes, cliffhanger, carte de fin.
