# Le contrôle des sons (OUTILLEUR, passe commune 3, 26/11, DEC-055)

La demande : « chaque son se charge, a la bonne durée et un volume cohérent, avec sa licence notée (sons de la bibliothèque Roblox) ».

`NDSoundCheck` (`sound_check.luau`, client) passe chaque son de la banque du DEV (`Shared/SoundBank.all()` : musiques, ambiances, acclamations), et aussi les sons des coups de rue (`Client/HubFightClient`). Pour chaque son, il relève :

- s'il se charge (`ContentProvider:PreloadAsync`, `IsLoaded`) ;
- sa durée réelle (`TimeLength`), à comparer à celle de la banque ;
- sa sonie, mesurée sans qu'on l'entende : un `SoundGroup` à 0, `PlaybackLoudness` relevé 0,6 s à cinq endroits d'un morceau long ;
- sa sonie « effective » : la sonie × le volume de la banque, à comparer au niveau de sa couche (`SoundBank.LEVEL`) et aux autres.

Les licences sont dans `licences.json`, lues par `get_asset_details` (la boutique des créateurs). Chaque son est gratuit et vient d'un créateur vérifié : DistrokidOfficial pour les 10 musiques, ProSoundEffects pour les ambiances et les coups.

```sh
python3 tools/robots/inject.py sound          # Client
python3 tools/sounds/report.py --start        # Client : _G.NDSoundCheck.start()
python3 tools/sounds/report.py --read         # Client : le JSON
python3 tools/sounds/report.py MESURE.json --md RAPPORT.md
```

## Le 26/11 (place `6c673043`)

Fichiers : `mesures/2026-11-26_sons_6c673043.json`, `mesures/2026-11-26_rapport_sons.md`.

- **Les 21 sons se chargent**, et leur durée est celle de la banque, à 0,1 s près.
- **En jeu, chaque état a sa musique**, au volume de la banque. À Konoha, on entend « Winter Sparrow Koto Ambient », plus les oiseaux et la foule. En duel, c'est « Samurai Sword Echoes ». À la fin d'un duel, les acclamations. En finale, « Moeru Kodou ».
- **Sous leur niveau** :
  - « Samurai Sword Echoes » (duel) : 41 pour 55 ;
  - « Moeru Kodou » (finale) : 56 pour 70 ;
  - les carillons : 2,4 pour 3.
- **Au-dessus** : les acclamations de fin de duel, 38 pour 30.
- **Les coups de rue risquent d'être couverts par la musique de Konoha** (crête moyenne 69) :
  - le coup léger culmine à 51 ;
  - le son du défi presque à rien (6,4) : c'est un « whoosh » d'une demi-seconde, pas un son de défi ;
  - la casse d'un objet (« wood ») est un éboulement de rochers de 5 s, pour une caisse en bois.
  - Ces sons sont joués en 3D à l'endroit du coup : de près, ils sont plus forts que mesuré ici. À écouter en jeu.
- **L'ambiance de la salle** est « Festival Of Fools » : une foule qui applaudit, avec des cornes de parade. À écouter : ça peut sonner moderne pour Konoha.

Ce sont des mesures de Claude ; le volume ressenti est à juger à l'oreille (HUMAN_VISUAL_FEEL).
