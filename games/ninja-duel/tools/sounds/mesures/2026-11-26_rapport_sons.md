# Contrôle des sons

21 sons : la banque (`Shared/SoundBank.all()`) et les coups de rue (`Client/HubFightClient`).

| son | titre (créateur) | chargé | durée banque / mesurée | volume | sonie effective / niveau | crête effective | à voir |
|---|---|---|---|---|---|---|---|
| `music.final` | 燃える鼓動 (Moeru Kodou - Blazing Heartbeat) (DistrokidOfficial) | oui | 187.5 / 187.5 s | 0.27 | 55.8 / 70 | 113.6 | sous son niveau (55.8 pour 70) |
| `music.final` | Echoes Of Kabuki (DistrokidOfficial) | oui | 169.6 / 169.6 s | 0.45 | 56.9 / 70 | 121.6 | · |
| `music.duel` | Taiko Battle March (DistrokidOfficial) | oui | 89.1 / 89.1 s | 0.51 | 51.8 / 55 | 108.8 | · |
| `music.duel` | Skyfall Duel (DistrokidOfficial) | oui | 164.6 / 164.5 s | 0.38 | 52.2 / 55 | 113 | · |
| `music.duel` | Samurai Sword Echoes (DistrokidOfficial) | oui | 217.4 / 217.4 s | 0.35 | 41.4 / 55 | 126 | sous son niveau (41.4 pour 55) |
| `music.konoha` | Kyoto Arpeggios (DistrokidOfficial) | oui | 230.9 / 230.9 s | 0.25 | 38.6 / 40 | 71.6 | · |
| `music.konoha` | Shimmering Koto Dreams (DistrokidOfficial) | oui | 194.8 / 194.8 s | 0.24 | 37.2 / 40 | 75.6 | · |
| `music.konoha` | Winter Sparrow Koto Ambient (DistrokidOfficial) | oui | 158.7 / 158.6 s | 0.22 | 35.3 / 40 | 59.6 | · |
| `music.forest` | Sacred Bamboo Wind (DistrokidOfficial) | oui | 179.8 / 179.8 s | 0.21 | 29.9 / 35 | 57.5 | · |
| `music.forest` | Biwa Lake Fog (Japanese Ambient Music) (DistrokidOfficial) | oui | 290 / 289.9 s | 0.31 | 28.2 / 35 | 71.7 | · |
| `ambience.birds` | Birds Park 1 (SFX) (ProSoundEffects) | oui | 36 / 36 s | 4 | 5.2 / 6 | 22.9 | · |
| `ambience.walla` | Theater Crowd 1 (SFX) — Tokyo, avant un kabuki, foule japonaise (ProSoundEffects) | oui | 36 / 36 s | 0.42 | 8.1 / 9 | 15.2 | · |
| `ambience.hall` | Festival Of Fools 1 (SFX) — foule qui applaudit, cornes de parade (ProSoundEffects) | oui | 35.2 / 35.1 s | 0.21 | 13.3 / 12 | 39.7 | · |
| `ambience.chimes` | Wind Chimes 2 (SFX) (ProSoundEffects) | oui | 31.1 / 31 s | 1.11 | 2.4 / 3 | 11.1 | sous son niveau (2.4 pour 3) |
| `ambience.woods` | Jungle Dawn 1 (SFX) (ProSoundEffects) | oui | 36 / 36 s | 3.33 | 5.3 / 6 | 11.9 | · |
| `shot.cheer` | Wrestling Crowd 2 (SFX) — courtes acclamations, sifflets (ProSoundEffects) | oui | 20.8 / 20.7 s | 0.43 | 38.3 / 30 | 156.2 | au-dessus de son niveau (38.3 pour 30) |
| `street.wood` | Earthquake Debris Rock Bursts Scattering 1 (SFX) (ProSoundEffects) | oui | — / 5.3 s | 0.35 | 23.3 / — | 44.6 | crête 44.6 sous celle de la musique de Konoha (68.9) : risque d'être couvert |
| `street.challenge` | Wood Swish Ruler Whoosh Fast Movement In Air (SFX) (ProSoundEffects) | oui | — / 0.5 s | 0.35 | 1.2 / — | 6.4 | crête 6.4 sous celle de la musique de Konoha (68.9) : risque d'être couvert |
| `street.hit` | Punch Some Crack And Thud 2 (SFX) (ProSoundEffects) | oui | — / 1.6 s | 0.35 | 4.9 / — | 50.9 | crête 50.9 sous celle de la musique de Konoha (68.9) : risque d'être couvert |
| `street.stone` | Rock Drop On Concrete Drops Breaks 10 (SFX) (ProSoundEffects) | oui | — / 1.1 s | 0.35 | 7.3 / — | 114.6 | · |
| `street.heavy` | Punch Kit Beefy Hit 3 (SFX) (ProSoundEffects) | oui | — / 0.9 s | 0.5 | 41.8 / — | 302.4 | · |

Sonie : `Sound.PlaybackLoudness` sans son entendu (un SoundGroup à 0), 0,6 s à cinq endroits d'un morceau long, une fois depuis le début pour un son court ; « effective » = sonie × volume de la banque. Un son est sous ou au-dessus de son niveau hors de 80 à 125 % du niveau de sa couche (`SoundBank.LEVEL`). Crête moyenne de la musique de Konoha : 68.9.

Licences (`tools/sounds/licences.json`) : chaque son est un audio gratuit de la boutique des créateurs Roblox, d'un créateur vérifié : DistrokidOfficial pour les musiques, ProSoundEffects pour les ambiances et les coups.
