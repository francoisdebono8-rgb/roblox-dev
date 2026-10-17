# Roster20 — index des fiches personnages

Version documentaire18/10/2026 ; snapshot runtime1cabd7f/bc7faa3. Une fiche par personnage, vingt IDs uniques de [Shared/Roster](../../src/Shared/Roster.luau). Intentions : [DEC-025](../active/DECISIONS.md#dec-025--fiches-personnages-et-identité-perceptible) ; état : [CURRENT_STATE](../active/CURRENT_STATE.md) ; travail/critères : [MASTER_BACKLOG](../active/MASTER_BACKLOG.md). Cet index ne valide ni les kits ni les propositions.

**Lecture :** chaque fiche sépare vêtements/gestuelle cibles, nature et propriétés du chakra, contrôle/quantité, chiffres runtime, moveset, techniques et période, éveil/risque, habileté du joueur et scénario Studio. Les propositions sont une base de discussion/conception pour Claude ; pas vingt refontes simultanées ni ajout de boutons.

## Comparaison du snapshot technique

Speed = paramètre de marche de base ; sprint = coefficient du profil commun, pas mesure native. Réservoir et regen sont des paramètres du jeu, pas des statistiques Naruto officielles. Aucun équilibrage modifié.

| Fiche | ID | Âge affiché | Speed | SprintScale | Chakra | Regen | Profil d’infusion actuel |
|---|---|---:|---:|---:|---:|---:|---|
| [Minato](MINATO.md) | `Flashstep` | 13 | 19.5 | 1.12 | 110 | 8 | `WindBlade` |
| [Itachi](ITACHI.md) | `Mirage` | 13 | 18 | 1 | 125 | 7.2 | `FireBlade` |
| [Neji](NEJI.md) | `GentleFist` | 13 | 18.5 | 1 | 115 | 7.6 | `GentleFist` |
| [Sasuke](SASUKE.md) | `Lion` | 12 | 19 | 1.1 | 105 | 7.5 | `LightningWire` |
| [Gaara](GAARA.md) | `Sand` | 12 | 16.5 | 0.85 | 130 | 7 | `Basic` |
| [Rock Lee](ROCK_LEE.md) | `Leaf` | 13 | 20 | 1.2 | 100 | 9.5 | `Taijutsu` |
| [Naruto](NARUTO.md) | `Legion` | 13 | 18.5 | 1.12 | 160 | 6.5 | `ShadowClone` |
| [Temari](TEMARI.md) | `Gale` | 15 | 17.5 | 0.95 | 120 | 8 | `WindFan` |
| [Hinata](HINATA.md) | `Lavender` | 12 | 18.5 | 1.02 | 120 | 8 | `Basic` |
| [Kakashi](KAKASHI.md) | `Copycat` | 14 | 19 | 1.08 | 120 | 7.6 | `Basic` |
| [Haku](HAKU.md) | `Mirror` | 15 | 20 | 1.12 | 125 | 8.4 | `Basic` |
| [Zabuza](ZABUZA.md) | `Mist` | 14 | 18.5 | 1.1 | 110 | 7 | `Basic` |
| [Kimimaro](KIMIMARO.md) | `Bone` | 13 | 19 | 1.1 | 105 | 7.4 | `Basic` |
| [Shisui](SHISUI.md) | `Flicker` | 13 | 20.5 | 1.14 | 120 | 8.4 | `Basic` |
| [Orochimaru](OROCHIMARU.md) | `Serpent` | 12 | 18.5 | 1.08 | 130 | 8 | `Basic` |
| [Kabuto](KABUTO.md) | `Medic` | 13 | 19 | 1.08 | 125 | 9 | `Basic` |
| [Deidara](DEIDARA.md) | `Clay` | 15 | 18.5 | 1.1 | 125 | 8.2 | `Basic` |
| [Sasori](SASORI.md) | `Puppet` | 14 | 18 | 1.06 | 120 | 8 | `Basic` |
| [Nagato](NAGATO.md) | `Rinnegan` | 12 | 18 | 1.06 | 140 | 9 | `Basic` |
| [Killer Bee](KILLER_BEE.md) | `Ink` | 14 | 19 | 1.1 | 115 | 7.6 | `Basic` |

**Treize profils Basic**, sept mappings spécifiques. Basic n’est pas absence de chakra : les familles/jutsus peuvent déjà appliquer des effets propres. Ce mapping n’est ni l’affinité canon ni un système de maîtrise acquise. [Source ChakraTuning](../../src/Server/ChakraTuning.luau).

## Distinctions à préserver

- Vitesse de course ≠ dash ≠ poursuite ≠ téléportation ≠ déplacement par miroir. Même moteur possible, geste/condition/coût/risque distincts.
- Nature élémentaire ≠ propriété (renforcement/coupe) ≠ forme (Rasengan) ≠ dōjutsu ≠ kekkei genkai ≠ source bijû. Le genjutsu, le soin et le poison ne deviennent pas automatiquement des éléments.
- Quantité de chakra ≠ contrôle ≠ coût/efficacité ≠ vitesse de recharge. Une grande barre ne rend pas excellent dans tous les domaines.
- Les coefficients1–5 des fiches sont des cibles de rôle, pas des multiplicateurs. Une incohérence entre rôle cible et chiffres actuels devient un sujet à tester, pas un retuning automatique.
- CANON_YOUNG exige une preuve correspondant au stade. PLAUSIBLE_YOUNG reste une hypothèse ; GAMEPLAY_LIBERTY est une adaptation déclarée. REVIEW_REQUIRED conserve le doute, REJECT_ADULT_ONLY s’applique seulement quand l’origine adulte est établie ; hors-échelle/hors-scope peuvent aussi concerner une capacité jeune.

## Trous de période conservés, sans faux arbitrage

Minato13/FTG-Rasengan-WindBlade, âge Itachi12/13, Hinata12/TwinLionFists-ProtectiveTrigrams, Kakashi Kannabi13/code14/ninken-dragon, Kimimaro13/référence secondaire15 et plusieurs kits pré-adultes (Orochimaru/Kabuto/Nagato/Bee/Zabuza/Deidara) nécessitent une preuve ou une liberté explicite. Les noms de capacités tardives ne changent pas automatiquement le stade choisi. Shisui : après-images anime/jeux/roman à distinguer du manga, pas import automatique de toutes ses formes.

Les fiches non-roster Shikamaru/Kisame et les anciens pools restent des références historiques/candidats, aucune autorisation de les ajouter.

## Réemploi et provenance

Familles/traits : Families ; corps secondaires : Bodies/BodyViews ; routes : MoveGraphs/RosterMoves/Brawler ; poses : Motion/AttackProfile ; objets : Looks/FamilyFX ; chakra : ChakraTuning/ChakraCombat. [Guide d’intégration](PRODUCTION_FRAMEWORK.md), [gabarit détaillé](FIGHTER_TEMPLATE.md). Aucun moteur par fighter ni dépendance Forge/Lab ajoutée.

[Ancien index et fiches conservés](../archive/characters/2026-10-18-before-profiles/ROSTER_20.md). Le blueprint10 et la composition CORE4 étaient historiques : liens maintenus vers leurs archives, plus de liste concurrente à suivre.
