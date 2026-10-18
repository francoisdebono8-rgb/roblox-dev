# M7 — gate du bloc combat sur les vingt (18/10, ~03:15)

Build : Debug, sources `DevGateCheck` M7 (commit de ce rapport), Studio Mac, `workspace:SetAttribute("NinjaDuelGate","M7")`.
Ce qui est mesuré : pour chaque fighter, **une séquence continue** contre Rock Lee (bot figé), sans refill ni replacement après le départ, par le pipeline serveur natif (`Combat:request`, même point d'entrée que la remote) : deux légers confirmés → toward+léger (sa route) → E → deux frappes aériennes → retour au sol → outil à 12 studs → chaque technique tour à tour avec la réserve réelle → garde contre un léger du bot → KO → round suivant : aucun buff/posture/slow/poison/zone/charge/corps de l'ancien round. Ce n'est **pas** une partie aux vraies touches ni un jugement de ressenti.

Résultat : **20/20 PASS**, 0 erreur dans l'Output pendant la passe. Lignes lues à l'écran (extraits) :

| Fighter | lights (dégâts) | route | E | air | outil | jutsu | garde | reset |
|---|---|---|---|---|---|---|---|---|
| Mirage | 20 | Launcher | ok | 2 | ok | Read, NeedleFan, MirageCast, FireBloom, PhoenixFlower ok | tenue, chip 0 | propre |
| GentleFist | 16 | Launcher | ok | 2 | ok | Rotation, VacuumPalm, SixtyFourPalms ok | tenue | propre |
| Lion | 17 | LionKick | Committed (sa propre poursuite) | 2 | ok | FireBloom, PhoenixFlower, WireTrap, Chidori ok | tenue | propre |
| Sand | 10 | SandPillar | ok | 2 | ok | SandCoffin, SandShuriken, DesertWave ok | tenue | propre |
| Leaf | 14 | LeafRising | Committed (sa propre poursuite) | 2 | « Nothing to deflect » (outil = parade, voulu) | LeafGreatWhirlwind ok | tenue, chip 1.2 | propre |
| Gale | 13 | Updraft | ok | 2 | ok | Kamaitachi, GreatGust, Cyclone ok | tenue | propre |
| Lavender | 15 | Launcher | ok | 2 | ok | TwinLionFists, VacuumPalm, ProtectiveTrigrams ok | tenue | propre |
| Copycat | 17 | Launcher | ok | 2 | ok | LightningBlade, TrackingFang, WaterDragon ok | tenue | propre |
| Mirror | 15 | Launcher | ok | 2 | ok | WaterNeedles, MirrorStep, IceMirrors ok | tenue | propre |
| Mist | 19 | CleaverRise | ok | 2 | ok | HiddenMist, SilentKilling, WaterPrison ok | tenue | propre |
| Bone | 16 | Launcher | ok | 2 | ok | Camellia, Larch, Willow ok | tenue, chip 1.1 | propre |
| Flicker | 16 | Launcher | ok | 2 | ok | BodyFlicker, FlickerOut, ShisuiFireball, ShisuiGenjutsu ok | tenue | propre |
| Serpent | 16 | Launcher | ok | 2 | ok | ShadowSnake, SnakeCoil, SnakeLunge ok | tenue | propre |
| Medic | 15 | Launcher | ok | 2 | ok | ChakraScalpel, TendonCut, MendingRetreat ok | tenue | propre |
| Clay | 15 | Launcher | ok | 2 | ok | ClayBirds, ClaySpiders, ClayMine, Katsu ok | tenue | propre |
| Puppet | 10 | PuppetRise | ok | 2 | ok | Marionette, FatherMother, NeedleRain, PuppetShield ok | tenue, chip 1.2 | propre |
| Rinnegan | 15 | Launcher | ok | 2 | ok | Repulsion, Attraction, Absorb ok | tenue, chip 1.2 | propre |
| Ink | 18 | Launcher | ok | 2 | ok | Lariat, InkMist, OctoHold ok | tenue | propre |

Flashstep et Legion : PASS dans la même passe (lignes présentes dans l'Output, non recopiées à l'écran ; Flashstep détaillé dans la première exécution : MarkedBlade, Flashstep, BurstStrike, Quickstep, WindCut ok, reset propre).

Constat transversal (pour la passe identité DEC-026, pas un défaut de ce bloc) : 15 des 20 routes « vers l'avant » sont encore le `Launcher` partagé — c'est exactement l'homogénéité que les bibles V1 doivent casser.

Non couvert par cette gate : vraies touches pour chacun des vingt (faites seulement pour Haku, Shisui, Deidara, Sasori, Zabuza au fil des blocs), manette physique, matchups à risque réciproques joués par un humain, ressenti. Sélection des vingt au menu vue (grille complète) ; choix à la souris faits pour Haku, Shisui, Deidara.
