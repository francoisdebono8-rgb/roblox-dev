# System Interaction Matrix

The long-term goal is emergent ninja combat: systems should interact so spectacle can come from combinations rather than one-off scripted moves.

## Projectile interactions

Potential shared properties:
- speed,
- mass/priority,
- spin,
- ricochet count,
- surface stick,
- destructibility,
- elemental tag,
- mark tag,
- wire tag,
- delayed activation,
- homing/retarget permission.

Possible interactions:
- projectile hits projectile -> deflect, destroy, redirect or alter velocity;
- projectile hits wall -> stick or ricochet;
- marked kunai sticks -> teleport anchor;
- fire hits tool -> ignite/enhance if character rule allows;
- wire-tagged shuriken -> creates tether/angle control;
- clone throws tool -> secondary origin point;
- sand intercepts tool -> absorbs/redirects;
- Rotation deflects tool -> new trajectory.

Mastery, not ownership, should differentiate fighters. Many ninjas can throw a kunai. Itachi is better at geometry, Minato turns one into a spatial anchor, Sasuke integrates wire/aggression, Tenten could use volume/inventory.

## Terrain interactions

Every arena surface can expose tags:
- runnable,
- splattable,
- bounceable,
- breakable,
- markable,
- climbable,
- projectile-stickable,
- trap-valid,
- elevated.

Possible uses:
- wall-run route,
- wall splat,
- rebound,
- planted mark,
- projectile ricochet,
- trap placement,
- cover,
- aerial launch origin,
- terrain destruction later if performance allows.

## Movement interactions

Movement states should feed combat:
- sprint attack,
- dash attack,
- retreat throw,
- wall-run attack,
- jump attack,
- landing attack,
- teleport re-entry,
- dodge counter,
- side-switch.

Characters should reinterpret these states, not simply receive identical attacks.

## Hit reaction interactions

Hit reactions are not cosmetic only. They create routes:
- head snap -> short advantage,
- torso twist -> side opening,
- stagger -> grab opportunity,
- launch -> aerial pursuit,
- spin -> side switch,
- wall splat -> wall route,
- ground bounce -> re-launch window,
- knockdown -> reset/setup.

## Chakra/resource interactions

Potential generic resource hooks:
- jutsu cost,
- movement burst cost,
- substitution charges,
- awakening meter,
- guard integrity,
- character-specific subresource.

Character examples:
- Neji can restrict chakra efficiency temporarily.
- Lee largely ignores ninjutsu resource but pays through stamina/gate cost.
- Gaara may spend sand-defense resource.
- Minato's spatial setup can depend on active marks rather than raw chakra alone.

## Defensive interaction families

- Guard: reduces/blocks frontal pressure.
- Perfect guard/parry: creates counter opportunity.
- Dodge: positional answer.
- Substitution: expensive state escape.
- Auto-defense: character-specific, resource constrained.
- Rotation-like defense: active area rejection.
- Clone/afterimage escape: leaves deceptive state behind.

Every powerful offensive state should have at least one reasonable answer.

## Interaction examples worth prototyping later

1. Itachi throws first shuriken wide, second hits it and bends trajectory behind guard.
2. Sasuke uses wire tool to constrain dodge direction before Fireball.
3. Minato throws marked kunai past target, attacks front, teleports behind after guard.
4. Neji Rotation deflects projectile into arena wall; projectile remains as environmental hazard/anchor if rules permit.
5. Naruto clone throws tool from secondary origin while real Naruto approaches.
6. Gaara catches projectile in sand and uses sand mass for counterattack.
7. Shisui afterimage draws lock-on while real fighter changes attack vector.
8. Kakashi observes repeated projectile route and gains a contextual response window.
9. Orochimaru attacks around cover via extended body/snake path.
10. Lee uses wall rebound purely physically to continue pursuit.

## Engineering principle

Prefer composable tags/events over character-to-character hardcoded exceptions.

Example:
A projectile can expose `Deflectable`, `StickToSurface`, `Marked`, `Element=Fire`, etc. Character systems react to those properties.

This lets future characters create new interactions without rewriting old combat systems.

Do not over-generalize too early. If a spectacular character behavior needs a specific module, allow it, but connect it through shared state/tag interfaces where possible.