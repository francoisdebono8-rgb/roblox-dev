# Rock Lee — test de charge (convergence 2, DEC-015)

Branche `claude/nd-ccc2-lee`, base `6b9c254`, puis fusion de `claude/ninja-duel-2026-10-14` quatre fois (`4ec179c` : identité, combo, chakra ; `15008c9` : registre de couches client ; `6b98e28` : poses d'identité, frein de la ruée, double appui ; `2009811` : maintien aérien réservé aux strings qui touchent, IA sans coups sur un corps protégé au réveil). Fiche : [ROCK_LEE](../../../characters/ROCK_LEE.md) (section « État d'implémentation »). Cadre : [LIVE_AUTONOMY_ADDENDUM](../../missions/LIVE_AUTONOMY_ADDENDUM.md) §7, DEC-015, stade DEC-013 (examen chûnin, cinq portes au plus).

## En bref

- **Rock Lee (`Leaf`) est jouable et sélectionnable** : kit serveur complet sur les systèmes partagés, IA, famille de mouvement, couche visuelle `LeeFX`, costume, roster. Studio n'était pas disponible : **tout est prouvé en headless seulement**.
- Taijutsu pur : aucun élément, aucun projectile, pas de kawarimi (Rupture), outil = coup de pied de déviation, chakra non infusable (profil `Taijutsu`).
- Identité visible dans les règles : Leaf Rising Wind → Ombre de la feuille dansante → **Lotus primaire payé en PV** ; Leaf Hurricane qui garde la string (L L ↓ L3 = quatre coups) ; Cinquième porte (vitesse, drain, **Lotus caché** gratuit qui fait rebondir le corps).
- Le test de charge a cassé **dix hypothèses moteur** (dont un vrai crash et une fuite d'identité de Sasuke vers Lee) ; chacune est corrigée par un point d'extension générique et minimal, sans changer le comportement des CORE4.
- `tests/Lee.spec.luau` : 24 cas, dont des duels IA contre les CORE4, Gaara et lui-même **jusqu'au KO** ; 23 suites passent, trois builds, isolation, docs, architecture.

## Implémenté et jouable (preuve headless)

| Capacité | Où | Test (`tests/Lee.spec.luau` sauf mention) |
|---|---|---|
| Données : stats, profil d'attaque, aucun élément ni lancer, `Tool="Deflect"`, `Substitution.Mode="burst"` | `src/Shared/Fighters.luau` (`Leaf`) | « pure taijutsu » |
| ↑ Leaf Rising Wind (lanceur) + Ombre de la feuille dansante partagée ; cue « HEAVY = PRIMARY LOTUS » | `MoveGraphs.Leaf`, `Attacks.LeafRising`, `Brawler.routePayoff` | « two kicks and toward » |
| Lotus primaire : 22, coûte 10 PV, jamais létal ; ≤ 26 PV → Leaf Heel gratuit ; Sasuke garde son Lion Combo | `MoveGraphs.Leaf.airFinisher`, `Brawler.airFinisher` | « Primary Lotus », « too hurt » |
| Lourd après deux coups = lanceur, après un coup = genou | `LauncherMove`, `heavyAfterOne` | « heavy after two kicks » |
| ↓ Leaf Hurricane (`chain`, Juggled bas) : la string continue (L3, ou ↑) | `Attacks.LeafHurricane` | « keeps the string » |
| ←→ Leaf Whirlwind : arc de 9 studs, rattrape un pas de côté, pas d'orbite, string ouverte | `Attacks.LeafWhirlwind` | « Leaf Whirlwind » |
| Leaf Great Whirlwind (technique) : traverse 12 studs, Knockback + poursuite, 10 chakra, CD, annulation de string | `Techniques.LeafGreatWhirlwind` → `Attacks.GreatWhirlwind` | « Leaf Great Whirlwind » |
| Coup de pied de déviation : lames détruites dans l'arc, volumes de jutsu intacts, ruée gratuite 0,6 s, rien si rien n'arrive | `Techniques.deflectKick/deflectSweep`, crochet `Combat` | « deflecting kick », « nothing coming » |
| Modificateur chakra refusé (fizzle, rien dépensé) | `ChakraTuning` (`Taijutsu`), crochet `Combat` | « chakra modifier » |
| Rupture : reste sur place, repousse l'attaquant, ratée = 0,3 s de récupération, aucune bûche côté client | `Combat:substitute` (`burst`), `Techniques.rupture` | « Rupture » |
| Cinquième porte : ≤ 35 %, vitesse réelle ×1,28 (limite `Motor.step` mesurée), drain non létal ; Lotus caché gratuit + rebond | `Awakening`, `airFinisher.awakened` | « Fifth Gate » (deux cas) |
| Relance « leaf », la plus rapide du roster ; IA la plus avide (`DASH.Leaf`) | `MoveGraphs.Leaf.reengage`, `AI.luau` | « re-engage » |
| IA : Daisenpū à distance, déviation d'une lame, lotus après le lanceur ; pas de lancer de sonde | `AI.luau` (blocs isolés) | « the AI uses his kit » |
| Duels IA (RNG semé) contre Minato, Itachi, Neji, Sasuke, Gaara (deux ordres) et miroir : tous **jusqu'au KO**, aucun blocage, aucun projectile de Lee | — | « AI duels » |
| Famille client `body="Lion"`, `weapons="none"`, intro à lui ; main arrière derrière le dos à l'arrêt et en marche (z = 0,86 dans le repère du torse), balancée au sprint | `VelmoraMotionEngine` (`STANCE.Leaf`, `GAIT.Leaf.holdRear`) | « motion family » |
| Clips propres là où l'identité le demande, ceux de Sasuke ailleurs ; lotus en variantes clientes | `CLIPS.Leaf`, `VARIANT_OF` | « his own clips » |
| Tout le kit présenté sans saut de pose (pire 38,0 °/image, plafond 39) | — | « without a snap » |
| Limites articulaires et poses finies (tous les coups, lotus compris) | `tests/Animation.spec.luau` | listes étendues à `Leaf` |
| `LeeFX` : porte verte, lueur rouge, spirale et cratère du lotus, croissant de la déviation, ses contacts de vitesse/Rupture/éveil | `src/Client/LeeFX.luau` (registre `FX.layers`) | « client: the Fifth Gate… » |
| Costume : combinaison verte, jambières orange, bandeau en ceinture rouge, mains bandées, coupe au bol, gros sourcils, grands yeux ; rien d'adulte | `World.dress` (`dressLee`) | « costume builds » |
| Sélectionnable (slot, boutons des deux côtés, départ du duel avec lui) | `UI.luau` (`playable`) | « he is selectable » |

## Partagé contre sur mesure

| Couche (DEC-015) | Réutilisé tel quel | Sur mesure pour Lee |
|---|---|---|
| Stats / profil | format `Fighters`, `AttackProfile` | valeurs |
| Grammaire de combo | string commune, routes, air routes `AirDrive/AirSpike/AirSwitch`, genou | 3 routes (`LeafRising`, `LeafHurricane`, `LeafWhirlwind`) |
| Famille de lanceur | `shadowLeaf` (Kage Buyō de Sasuke) | — |
| Finisher aérien | slam, fenêtre `lionUntil` | **descripteur générique** `airFinisher` (+ variante d'éveil) |
| Relance | `Combat:reengage`, `rushPlan` | entrée `reengage` (données) |
| Outil | pipeline `Tool` | `def.Tool="Deflect"` + balayage de déviation |
| Défense | substitution (charges, fenêtre, i-frames, suivi) | `Mode="burst"` (Rupture) |
| Technique | pipeline jutsu → coup `Brawl` (comme le Chidori) | `GreatWhirlwind` |
| Éveil | `Awakening` (vitesse, dégâts, regen, CD, `HealthDrain`) | Lotus caché via `airFinisher.awakened` |
| Chakra | `ChakraCombat` / `Chakra.refuse` | profil `Taijutsu` (refus) |
| Mouvement client | famille `Lion` (clips, sprint, air, réactions), IK, damping | posture, démarche `holdRear`, intro, 5 clips, pose de canal |
| VFX | registre `FX.layers` | `LeeFX` |
| IA | moteur générique (routes, poursuite, lotus via la fenêtre) | 4 règles isolées |

Proportion : environ un tiers sur mesure (données de kit, 5 clips, la couche VFX, 4 règles d'IA), le reste vient des familles partagées, conformément à l'addendum §7.

## Ce que le test de charge a révélé (hypothèses cassées, contournements)

1. **Finisher aérien câblé pour Sasuke.** La fenêtre de l'Ombre finissait toujours en `LionBarrage` (dégâts 17, cue « LION COMBO »). → `MoveGraphs[...].airFinisher` lu par un crochet de 2 lignes dans `Brawler.request`, logique dans `Brawler.airFinisher` (coût PV, seuil, repli, variante d'éveil). Le Lion Combo est inchangé ; il pourrait migrer vers le descripteur.
2. **Variantes clientes codées en dur à trois endroits** (`Rasengan`, `RasenganDrop`, `LionBarrage`). → une table `VARIANT_OF` (clip de la variante, timing du coup porteur). Effet de bord voulu : `Motion.pose` refusait silencieusement `LionBarrage`, que `Animation.spec` croyait tester ; il est désormais réellement testé.
3. **« Tout le monde lance un outil ».** Sans `ToolMastery`, l'outil lançait un kunai par défaut, et l'IA lançait des sondes. → `def.Tool=="Deflect"` en tête de la branche `Tool` de `Combat`, sonde IA désactivée pour ce cas.
4. **Kawarimi universel.** `Combat:substitute` supposait une relocalisation et le client dessinait toujours une bûche. → `Mode="burst"` : pas de déplacement, impact `repel` au lieu de `substitute`.
5. **Briseurs du bouclier de sable = liste de noms dans `Combat`.** Le lanceur générique brise, `LionKick` de Sasuke non : un nouveau lanceur n'est jamais reconnu. → drapeau de données `breaksShield` sur l'attaque, lu à côté de la liste.
6. **Vrai crash : `Combat:updateHazards`.** Une brûlure qui met KO termine le duel, `Combat:clear` vide la liste pendant l'itération → `attempt to index nil`. Trouvé par Lee contre le feu de Sasuke en duel IA. → garde `phase~="Duel"` après les dégâts, comme les autres boucles. (En jeu, le KO différé masque le bug ; le harness le révèle.)
7. **L'IA n'atteignait jamais le finisher.** Dans la fenêtre de l'Ombre, après un coup aérien, la branche de chaîne enchaînait des routes au lieu du lourd : zéro lotus sur 18 duels. → règle IA pour les graphes à `airFinisher` (Sasuke inchangé).
8. **Un seul modificateur de vitesse : l'éveil.** `speedScale` est recalculé à chaque image depuis l'éveil : pas de vitesse par acteur pour les poids ou une technique Portes (H04). → retrait des poids non implémenté.
9. **String figée à trois coups** (`Light min(combo+1,3)`) : pas de longueur par fighter (H02). → la quatrième frappe passe par la route ↓ qui garde la chaîne.
10. **Fuite d'identité par la famille.** La posture voûtée de la Curse Mark (poses d'identité, `6b98e28`) s'appliquait à toute famille `body="Lion"` éveillée : Lee, bâti sur les coups de Sasuke, se voûtait comme Sasuke maudit pendant la Cinquième porte. → trait déclaré `awakenPosture="curse"` dans la famille de Sasuke ; les traits d'identité se déclarent, ils ne s'héritent pas du corps (test « family traits are declared »).

Autres constats :
- Couleurs d'éveil et de traînée dans `Effects` indexées par `fighterId` ; `Awakening.Color` n'est jamais lu par le client. → recolorées par `LeeFX`.
- Tutoriel, étape 17 (« interrompre la technique télégraphiée » du bot) : elle suppose un canal long ; avec Lee en bot (0,08 s × 3 = 0,24 s), elle devient presque impossible.
- `Random` du harness renvoie toujours 0,5 : les duels IA à RNG constante (`Sasuke.spec`, `Gaara.spec`) n'entrent jamais dans la boucle de techniques de l'IA (seuil 0,34) ni dans la substitution planifiée. `Lee.spec` utilise une RNG semée (comme `ComboModel.spec`).
- Répétition d'animation : string, air string et genou identiques à Sasuke ; Leaf Whirlwind = L3 = talon tournant de Sasuke ; Daisenpū = roundhouse de Minato ; talon plongeant = clip du Lion Combo.
- Composition racine `Rx*Ry` des clips : avec un grand lacet, le tangage relève la jambe balayée (même effet dans les sweeps CORE4).
- Matchups (un seul duel IA semé par ordre : échantillon minuscule, aucun réglage d'équilibre fait) : Lee bat Neji dans les deux ordres, partage avec Itachi, perd les deux ordres contre Minato, Sasuke et Gaara (bouclier + portée, même avec `breaksShield`).
- Outil (hors gameplay) : sous Windows, `tools/dev.py verify` lit la sortie de `luau-compile` en cp1252 (`text=True` sans encodage) ; des threads de lecture lèvent `UnicodeDecodeError` sur le bytecode, sans effet sur le verdict (code de retour). Préexistant, non corrigé ici.

## Fichiers partagés touchés (fusions)

Les quatre fusions sont passées **sans conflit dans les sources** (seuls les artefacts `dist/` de la troisième ont été pris d'un côté puis reconstruits). Aucune résolution manuelle dans `Brawler`, `Combat`, `AI`, `Fighters` ou `MoveGraphs`. Modifications ajoutées dans les fichiers partagés, toutes localisées :
- `Brawler` : crochet `airFinisher` (2 lignes) + `Brawler.airFinisher` ; cue de l'Ombre lu dans le graphe (1 ligne).
- `Combat` : crochet `Tool` (6 lignes), branche `burst` (2 + 1 lignes), `breaksShield` (1 ligne), garde des hazards (1 ligne).
- `AI` : `DASH/CHASE.Leaf` (1 ligne), déviation (1), finisher aérien (1), sonde désactivée (condition), Daisenpū (2).
- `Techniques` : bloc Lee séparé (entre Gaara et Neji).
- `Fighters`, `MoveGraphs`, `Attacks` : entrées ajoutées en fin de table ; `ChakraTuning` : 3 lignes après la table.
- Client : `VelmoraMotionEngine` (posture, démarche, clips, `VARIANT_OF`, intro, pose de canal, trait `awakenPosture` de la famille de Sasuke), `Effects` (une ligne `require` de `LeeFX`), `UI` (liste + texte réduit), `World` (`dressLee` + une ligne de dispatch).
- `build.py` / `tests/run.sh` : `Lee.spec` ajouté après Gaara dans les deux listes. `TEST_RUNNERS` reste une ligne unique : tout ajout parallèle y entre en conflit, résolution triviale.

## Tests

- `bash tests/run.sh` : **23 suites PASS** (Lee 24 cas, Animation 14, Gaara 11, …).
- `python -I build.py`, `--debug`, `--qa` : PASS (les suites tournent dans chaque build) ; `tests/test_build_isolation.py` : 9 OK ; `tools/check_project_docs.py` : PASS ; `tools/check_architecture.py` : PASS.

## À valider dans Studio

Place Debug, Test → Play. Duel direct : `print(game.ServerStorage.NinjaDuelDev:Invoke("tool","character",{first="Leaf",second="Lion"}))`, ou le roster normal.

1. **Posture et démarche** : main arrière derrière le dos (pas dans le torse), main avant tendue, accroupi et souple ; la main reste derrière le dos en marche, se libère au sprint.
2. **Clips** : Leaf Rising Wind (lecture verticale), Leaf Hurricane (hauteur de la jambe balayée), croissant de déviation, Lotus primaire (plongée tête en bas, possible interpénétration avec le corps adverse), Lotus caché, intro.
3. **Lotus côté serveur** : saut de relocalisation au-dessus du corps (warp), coût PV lisible (salve rouge sur Lee), cratère.
4. **Cinquième porte** : marche 25,6, sprint ≈ 64 : caméra, validation des coups à haute vitesse ; manteau vert, lueur rouge, drain.
5. **Déviation** : fenêtre contre de vraies lames, lisibilité, ruée gratuite.
6. **Rupture** : lisibilité face à la substitution commune (anneau au lieu de la bûche).
7. **UI et costume** : noms qui tiennent dans les boutons, frange au-dessus des sourcils (tête agrandie ×1,24), jambières, ceinture.
8. **En ligne** : Lee dans un duel à deux clients.

## Non implémenté

Élan et ses dépenses, retrait des poids, string de quatre par acteur (H02), GokenBody, technique Portes à tout moment, esquives payées en PV, épuisement de sortie de porte, prise aérienne du lotus (H14), série complète du Lotus caché, rebond mural athlétique, règle « plus rapide que le sable », Poing ivre. Détail : fiche [ROCK_LEE](../../../characters/ROCK_LEE.md).

## Risques

- Équilibre et feel non jugés (headless) ; vitesse de porte non mesurée nativement.
- La plongée du lotus peut traverser le corps adverse à l'écran.
- `VARIANT_OF` teste désormais `LionBarrage` pour tous les fighters dans `Animation.spec` (il passe) ; un futur clip fautif de Sasuke y échouera.
- Les crochets `Combat`/`Brawler`/`AI` sont petits, mais ces fichiers restent les plus disputés : à revérifier à chaque fusion.
