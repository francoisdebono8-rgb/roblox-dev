> Snapshot historique avant harmonisation des fiches le18/10/2026. Conserver les idées et preuves ; état/priorités dans docs/active, nouvelle fiche au chemin d’origine.

# Roster 20 — breadth pass (Tier A → B → C)

Référence technique des kits, pas propriétaire de leur acceptation. Décisions : [DECISIONS](../../../active/DECISIONS.md) ; statut courant et preuves : [CURRENT_STATE](../../../active/CURRENT_STATE.md) ; critères et priorités : [MASTER_BACKLOG](../../../active/MASTER_BACKLOG.md). Missions originelles : références historiques dans docs/archive/missions. Les mentions « Studio » ci-dessous signalent des observations partielles, pas un PASS final Tier A.

## Les vingt

| # | Id (code) | Combattant | Archétype | Famille réutilisée | État |
|---|---|---|---|---|---|
| 1 | `Flashstep` | Minato | mobilité / sceaux | — (CORE4) | jouable |
| 2 | `Mirage` | Itachi | lecture / contre | — (CORE4) | jouable |
| 3 | `GentleFist` | Neji | contrôle du chakra | — (CORE4) | jouable |
| 4 | `Lion` | Sasuke | rushdown / feu-foudre | — (CORE4) | jouable |
| 5 | `Sand` | Gaara | contrôleur défensif | — | jouable |
| 6 | `Leaf` | Rock Lee | taijutsu pur | coups de Sasuke | jouable |
| 7 | `Legion` | Naruto | corps multiples (clones) | Bodies | implémenté ; preuves Studio partielles datées dans CURRENT_STATE |
| 8 | `Gale` | Temari | zoneuse vent | Zones | implémenté ; preuves Studio partielles datées dans CURRENT_STATE |
| 9 | `Lavender` | Hinata | Poing souple, défensive | Neji + Families (Buff, Burst) | implémenté, Studio partiel |
| 10 | `Copycat` | Kakashi | polyvalent / Sharingan | Families (Strike, Projectile) | implémenté, Studio partiel |
| 11 | `Flicker` | Shisui | Uchiha mobilité / genjutsu | Families (Teleport ×2, Projectile fireball, Burst seal) | implémenté, Studio partiel |
| 12 | `Serpent` | Orochimaru | serpents, allonge, saisie | Families (Projectile snake Pull/PullTo + Poison, Bind, Strike venin) | implémenté, Studio partiel |
| 13 | `Mirror` | Haku | projectiles / miroirs | Families (Projectile ice, Teleport InZone, Zone dôme) ; outil senbon (Slow) | implémenté, Studio partiel |
| 14 | `Bone` | Kimimaro | armes d'os, armure | Families (Buff arme, Burst Leave, Strike) ; outil os ; Armor | implémenté, Studio partiel |
| 15 | `Rinnegan` | Nagato | Rinnegan / contrôle / attraction-répulsion | Families (Burst répulsion, Projectile Pull, Burst Drain/Steal) | implémenté, Studio partiel |
| 16 | `Puppet` | Sasori | marionnettes / corps déporté | corps de Gaara (fouets longs = fils) + Families (puppet Projectile/Bind, Counter, Poison) | implémenté, Studio partiel (marionnette = projectile, pas corps Bodies) |
| 17 | `Clay` | Deidara | explosifs / zoning | Families (claybird/clayspider Projectile + Zone, Zone mine, Burst Katsu) ; outil argile | implémenté, Studio partiel |
| 18 | `Ink` | Killer Bee | jinchūriki jeune, lutteur | Families (Strike Lariat, Zone encre, Projectile tentacule Bind) ; éveil manteau Armor | implémenté, Studio partiel |
| 19 | `Mist` | Zabuza | arme lourde + brume | clips de l'éventail = couperet + Families (Zone brume, Teleport InZone, Projectile Bind) | implémenté, Studio partiel |
| 20 | `Medic` | Kabuto | médical / scalpel chakra | Families (Buff OnHit, Strike Slow, Teleport Heal) | implémenté, Studio partiel |

> **Composition verrouillée par DEC-022 (17/10/2026).** Les anciens lots Sakura / Choji / Kiba / Shikamaru / Shino / Kisame sont abandonnés avant code pour ce roster initial. Les noms ci-dessus priment sur les anciennes notes de lots.
>
> **Règle de période :** les vingt peuvent venir de générations différentes, mais chaque personnage est construit dans une version **jeune/prodige**, avec les capacités réellement connues ou raisonnablement établies à ce stade. Ne pas importer son arsenal adulte final par défaut. Les Uchiha et autres familles/clans peuvent partager une base sans partager leur boucle de jeu. Le nombre de jutsus n'est pas standardisé : équilibrer la profondeur et les décisions, pas le nombre de techniques.

## Champs génériques ajoutés pour les dix (18/10, données uniquement)

`Families` : `Poison {Damage, Time, Every}` (dégâts dans le temps), `PullTo` (une traction ne passe jamais derrière lui), Teleport `Heal` / `InZone` (+ `ZoneName`), Burst `Leave` (zone laissée), Buff `OnHit` ; `ToolMastery.Projectile`/`Contact` (outil dessiné par un Looks, avec cavaliers) ; `Attacks.riders` (frappe propre avec Slow/Poison…) ; `Motion.borrow` (une frappe nouvelle emprunte un clip existant) ; téléportations de famille dessinées dans leur look ; arme tenue en main pendant un Buff à look lame/aiguille ; zone `spikes`. `Shared/RosterMoves` ajoute les frappes d'un lot. `tests/Roster20.spec.luau` vérifie l'invariant d'ouverture et la mécanique propre de chacun. `Server/DevRosterCheck` (Debug seulement) : passe Studio par le pipeline serveur, sans le pont MCP Windows.

## Portée réelle des tests

`tests/Roster.spec.luau` contrôle les pièces du kit, la résolution des techniques, des chemins de combat et des appels de dessin ; `Roster20.spec` ajoute les mécaniques des dix nouveaux. Ces suites n'établissent pas seules le Tier A : nombre minimal >=8, chaîne tolérant deux touches, éveil accepté sur un bonus numérique, effet mesurable pouvant être un simple spawn. Les critères d'acceptation et leurs corrections appartiennent à QA-002 / CHR-EXT-002 du backlog.

`tools/studio/fighter_check.py <Id> [adversaire]` rejoue de vraies entrées ; il peut lancer par Debug si le menu manque et ne prouve pas systématiquement les impacts outils/projectiles. `DevRosterCheck` passe par les requêtes serveur ; son saut scripté n'établit pas une frappe aérienne. Ne pas déduire sélection, contre-jeu ou feel de ces seules traces. [Audit daté](../../audits/2026-10-17-roster20/AUDIT.md).

## Socle commun (pas de moteur par personnage)

- **`Server/Families.luau`** : familles de techniques pilotées par les données (`Projectile`, `Strike`, `Burst`, `Zone`, `Buff`, `Teleport`, `Counter`) et champs de contact (`Knock`, `Lift`, `React`, `Bind`, `Crush`, `Drain`, `Steal`, `Slow`, `Seal`, `Pull`, `Zone`). Traits lus par le cœur via des crochets : `beforeHit` (posture de contre), `damageScale` (buff, armure `def.Armor`), `withstands` (super-armure `Heavy`), `afterHit` (`def.OnHit` : drain, ralentissement), `zoneTick`, `speedScale`/`regenScale`. Éveil : `Awakening.Buff`, `Awakening.OnHit`, `Awakening.BindScale`.
- **`Shared/Looks.luau`** : l'apparence de chaque genre d'objet (forme, couleurs, lumière, traînée, impact, zone). **`Client/FamilyFX.luau`** construit les modèles (orb, needle, blade, wave, beast, serpent, swarm, shadow, boulder), leurs poses de vol, les impacts, les zones au sol, les auras de buff et de ralentissement.
- **`AI.luau`** : `familyWants` décide d'une technique de famille par sa famille et `spec.AI` (`Min`, `Max`, `Chance`, `Punish`).
- **Poses** : `VelmoraMotionEngine` donne une pose de lancer par famille (signes pendant le canal, puis projection / explosion / zone / buff / garde / arrivée) ; `spec.Pose = {channel=…, release=…}` la remplace ; `Motion.stance` (données) donne une garde propre.
- **Costumes** : `Server/Costumes.luau` (`install(dressers, kit)`), enregistrés par nom ; `World.dress` les appelle.
- **Menu** : `Shared/Roster.luau` est la seule liste ; la sélection affiche une grille de cinq colonnes par moitié.

## Notes de reprise (17/10, relevées par les anciens lots avant code)

Ces constats techniques restent utiles au socle, mais les compositions d'anciens lots qu'ils visaient ne sont plus normatives après DEC-022 :

1. `Roster.spec` refuse qu'une technique de **famille** soit refusée au lancer : une technique conditionnelle s'enregistre dans `WaveNKit.install` **sans** `Family`, avec `Requires="Bound"` ; il faut alors une ligne générique dans `AI.luau` et un cas `Requires=="Bound"` pour l'état « prêt » de la barre (`Matches.luau`).
2. `Effects.luau` enroule du fil d'acier autour de tout corps `Bound` (sauf Gaara) : une entrave de famille doit le désactiver (ex. `family.tie` dans l'instantané) et dessiner son propre lien.
3. `Families.afterHit` sort tôt sans `def.OnHit` : `Awakening.OnHit` doit s'appliquer même sans trait de base.
4. `Pull` est un vol de recul : sans plafond (ex. `PullTo` ≈ 3,5 studs devant lui) une cible proche est projetée derrière lui.
5. Une ombre au sol vole 2,2 studs sous la racine : contre une cible qui bouge, rayon ≈ 1,8 et un champ générique `Steer` (réorientation via `c:redirect`) sont nécessaires.
6. Champs génériques prévus : `Awakening.ZoneScale` (famille Zone), `Heal` optionnel sur Teleport.
7. Un coup `heavy=true` lance le corps et casse l'entrave : dégâts non lourds pendant une entrave.
8. Une frappe nouvelle sans clip prend le Light1 de sa famille de corps : la dessiner dans le FX de vague en attendant un clip.
9. Contraintes des suites : Ids de techniques globaux et uniques ; Speed × SprintScale < 24 (`Lee.spec`) ; JumpScale borné par `Regression.spec` ; toute entrée d'`Attacks` porte side/twist/lean/arm/step (`Animation.spec`).
10. `CostScale` d'éveil rembourse **toutes** les techniques (`Combat:awakenTechnique`) ; `Regen` d'un Buff agit sur le chakra, pas la santé ; un seul buff compte à la fois (`Families.buff`).
11. Une frappe nouvelle d'`Attacks` doit aussi poser `animation/feedback/chain/air/depth/offset` ; un champ `clip` lu par le moteur de mouvement permettrait d'emprunter une animation existante au lieu du Light1.
12. Un outil non kunai/shuriken est lancé comme `shuriken` ; un outil sur mesure (`Techniques.Tools`) perd les annulations de chaîne : garder `Tool="Kunai"` sauf besoin réel. L'IA de famille soignerait à pleine santé : seuil générique `spec.AI.Hurt` à prévoir.
13. La famille Zone vaut `"Fire"` par défaut (`ZoneKind`/`Zone.Kind`) et une zone sans `Kind` d'apparence est dessinée en feu : toute zone non ignée doit nommer `ZoneKind` et un `Kind` de `Looks`.
14. Une téléportation de famille est dessinée par `FX:teleport` (éclair jaune de Minato) : chaque identité doit dessiner la sienne et éteindre l'éclair générique.
15. Champs génériques prévus : `Shroud` sur une zone, `Leave` sur Burst, `Awakening.TeleportCost`.
