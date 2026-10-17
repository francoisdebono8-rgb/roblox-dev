> Référence technique/recherche, non normative. État, priorités et règles : [sources actives](../active/EXECUTION_RULES.md). Les commandes, exemples et anciens constats ci-dessous se vérifient sur le HEAD courant.

# Contrats actuels — états, combos et outils

Ce document nomme l’implémentation existante. Aucun nouvel enum de gameplay n’est introduit.

## Trois axes indépendants

| Terme de travail | Représentation existante | Autorité / sortie |
|---|---|---|
| neutral | `actor.state = Neutral` ; une réaction peut encore être présente | Combat/Brawler ; vérifier `reaction` aussi |
| guarded | `Guarding` + `guardHeld`; résultat contact `Blocked` | VelmoraDefense, guard release |
| staggered | `Stunned` ou `reaction=HitStun`, selon la voie du contact | setState/reactionUntil ; pas de doublon Staggered |
| off-balance | Aucun état dédié constaté | Ne pas traduire automatiquement en Knockdown ni créer un nouvel état |
| guard-open | `GuardBreak` est un résultat de défense ; `Stunned` et `guardHeld=false` | VelmoraDefense.resolve ; cue GUARD BREAK, durée existante |
| launched | `reaction=Launched`, `airborne`, vitesse de réaction | Brawler.react/step, pursuit window |
| falling | `airborne` et vitesse verticale négative | Motor ; axe locomotion, pas une action Falling |
| wall-splat | `reaction=WallSplat`, splatNormal/splatAt/pins | Brawler ; pin/bounce/tech existants |
| grounded | Motor.grounded + cache `airborne=false` | Raycast réel en Studio ; l’inspecteur lit le cache sans refaire de raycast |
| recovering | `Recovery` / `TechniqueRecovery` ; au sol `Knockdown` → `Wakeup` | chainAt/recoveryCancelAt/untilTime ou reactionUntil |
| grabbed | `reaction=Grabbed`, `grabbedBy`, `grabVictim` | releaseGrab/throw/throw break |
| weapon-clash | Événement `Clash` + Recovery/hop/hitstop | Brawler.clash ; pas de phase cinématique persistante |
| projectile clash | Geometry/shuriken redirect spécifiques | Expiry/contact feed ; pas de solveur général de collisions projectile-vs-projectile |
| wire-bound | `reaction=Bound`, boundBy/wireVictim | Techniques.wireBind et conversion Dragon Flame |

Action machine : Neutral, Startup, Active, Recovery, Guarding, Dodging, Stunned, Pursuit, Rush, TechniqueChannel, TechniqueActive, TechniqueRecovery, Defeated. Les réactions comprennent notamment HitStun, Launched, Juggled, Knockback, Spiked, WallSplat, Knockdown, Wakeup, Grabbed et Bound. Elles ne sont pas interchangeables avec action.state.

L’inspecteur lit `pending.spec` (déjà modifié par AttackProfile), les timers réellement utilisés et l’action/variante active. La durée restante vient de `untilTime`. Quand le pending a été supprimé (clash, parry, interruption), les durées du move ne sont plus disponibles : le debug ne les reconstruit pas à partir d’une approximation. Le mapping Motion Lab affiche les timings de **présentation**, qui peuvent différer d’un pending modifié en cours d’action.

Combo continuity : `combo`, `chainOpen`, `chainAt`, `hitConfirmed`, `buffered.action`, noms de route `MoveGraphs.routes` et `attackVariant`. Startup→Active→Recovery→Neutral reste commun. La chaîne, ses cancels et les conversions ne doivent pas être réécrits pour rendre quatre profils identiques. Le debug conserve une trace bornée de changements échantillonnés, pas un replay déterministe de tous les sous-événements.

## Hooks communs des outils déjà présents

| Étape | API / données actuelles | Limite ou conversion |
|---|---|---|
| hold/equip | `Combat:beginThrow(actor, spec)` ; `actor.throwing` avec kind/release/count/fired | Overlay mobile, sans nouvel inventaire/equip persistant |
| throw/release | `Combat:stepThrow(actor)` → `spec.fire(index, aim)` au timer nextRelease | Aim choisi ou cible revalidée au release ; état Neutral autorise la locomotion |
| spawn | `Combat:projectile(actor, aim, speed, range, damage, kind, onSurface?, opts?)` | id/owner/origin/direction/born/remaining ; launchPoint commun |
| impact acteur | `Combat:projectileHit(p, target, position, normal)` | Résolution serveur damage/defense, callbacks et conversions existants |
| impact surface | `Combat:projectileSurface(p, raycastResult)` | Callback `p.onSurface(position, normal, victim?)` ; ricochet selon mastery |
| embedded point | `Techniques.plant(c, actor, surface, normal, victim?)`, `actor.anchors` | Minato : sceau sur surface ou corps. Blade ordinaire : contact visuel `stick`, pas une entité gameplay persistante universelle |
| recall | `Combat:markedInFlight(actor)` et `Techniques.seals/sealOf` | Lookup / téléportation du sceau ; aucun recall générique kunai/shuriken ajouté |
| expiry | `Combat:projectileExpire(p)` + suppression dans `updateProjectiles` | Fade ou effet spécifique ; marked arrivé à portée peut planter un sceau |
| cleanup | `Combat:removeProjectile(p)`, `Combat:clear()`, `Techniques.expireSeals(c,a,now)` | Fin de session/KO, expiry et liens grab/throw/sceaux ; pas de pool opaque |
| conversion personnage | ToolMastery, MoveGraphs, onSurface, Techniques | Minato seal→Flashstep ; Itachi ricochet/Geometry/air fan ; Neji Rotation deflect/VacuumPalm ; Sasuke wireBind→Dragon Flame et PhoenixFlower |

Kunai et shuriken empruntent la même infrastructure. **WireTrap existe** chez Sasuke. **Smoke** est une présentation liée à la substitution, pas un outil smoke configurable. **Explosive tag** : aucun système commun dédié constaté ; Fireball/explosion existe comme jutsu et ne doit pas être renommé tag pour cocher une case.

Le Command Bar serveur du build debug peut consulter ces hooks avec `game.ServerStorage.NinjaDuelDev:Invoke("contracts")`. Les fonctions spawn/impact ne sont pas exposées comme nouveaux RemoteEvents d’écriture. Les commandes de test `act` passent par la request serveur réelle.

## Motion Lab : source, variante, export

Le runtime reste entièrement indépendant de Motion Lab. L’extraction offline lit uniquement le renderer trusted du repo. `NinjaSources.clipInheritance` conserve `GentleFist→Mirage` et `Lion→Flashstep`; l’adapter résout les poses héritées avec les timings propres au personnage, au lieu de perdre les clips et de tomber sur une génération procédurale différente.

Les poses source restent définies une seule fois dans les données d’extraction. Les profils importés normalisent les mêmes données pour leurs timings ; `metadata.motionClipSources` explique leur origine. Les variantes/edit/export existants restent copy-on-edit, et les presets persistants ne sont pas effacés.

`Characters` retrouve les quatre profils authored. `Motions→Common bilateral` expose 182 briques ; `Motions→Combat references` expose 120 variantes. Filtre Family puis L/R/counterpart pour retrouver les deux côtés. Leur disponibilité **n’implique pas leur affectation actuelle** à une attaque. Le mapping actuel part de CLIPS, aliases, metatables et overrides Rasengan/RasenganDrop/LionBarrage ; il n’invente aucune sélection artistique.

Exporter produit `NinjaDuel.MotionDefinitions.v1`, `ninjaDuel.clips`, `timings`, `motionMetadata` et `automaticApply=false`. Importer accepte les données JSON validées ; il ne nécessite pas de require d’un ModuleScript sélectionné. Claude choisit manuellement le point d’intégration dans VelmoraMotionEngine. Le plugin n’écrit ni dans les sources runtime ni dans les valeurs de combat.
