# Partie 0 — état des lieux du roster (28/10/2026)

DEC-030. Each of the twenty fighters was played in Studio (Debug build of 28/10, which still had Sasuke's old chain). The opponent was a frozen Rock Lee, or Minato for Lee.

How the captures were made:
- `tools/studio/probes/audit_show.luau` scripts the moves;
- `audit_rec.luau` records them;
- `audit_strip.luau` turns them into chronophotographs.

On each sheet, one row is one move, shown as 6 instants from left to right. The sheets are the `*.jpg` files in this folder. The page shown to the user is the "État des lieux du roster" artifact.

## Findings common to the roster
1. **Bodies are upright and stiff, with short gestures.** 18 of the 20 fighters are still procedural rather than authored. Nothing is amplified the way the reference is.
2. **Techniques have almost no body acting.** There are no seals and no wind-up. The effects are tiny or invisible: Gaara's sand, Water Dragon, Haku's needles, Bee's ink, Orochimaru's snake, Deidara's spiders and Katsu, Zabuza's mist.
3. **MotionSmear ghosts read as clouds of dark cubes.** They have to be redone: finer and lighter.
4. **Bodies end up inside each other.** This happens with Shisui's Body Flicker, Haku's Mirror Step, Orochimaru, and Zabuza's blade.
5. **Five fighters reuse other fighters' strings.** Shisui, Nagato, Madara, Hashirama and Hiruzen will be redone from scratch from their bibles (user, 28/10 13:38).

## Per fighter (beta order)
- **Sasuke:** old kick string shown; the kunai string is in ND-Kunai1. The rest is authored but restrained.
- **Itachi:**
  - high, upright guard; the chain turns his back on the opponent;
  - Read and Needle Fan show nothing;
  - Katon is two rings, Phoenix Flower two small balls.
- **Minato:** authored but restrained; every FTG leaves a cube cloud; the Rasengan is a small glow.
- **Naruto:** generic chain; the clones are separate bodies, not recorded (to check in game).
- **Kakashi:** the Raikiri is red instead of blue-white; Water Dragon is invisible; the dog reads.
- **Gaara:** the biggest beta gap. The sand is nearly absent and the body stays upright.
- **Lee:** the liveliest kicks of the roster; smear clouds cover them.
- **Neji:** the Kaiten dome shows but the body does not spin; 64 Palms is only a floor circle.

## The twelve after the beta
- **Zabuza:** best of the twelve, the cleaver arcs read; mist invisible; the blade crosses the body.
- **Haku:** needles invisible; Mirror Step ends inside the opponent.
- **Kimimaro:** all white, unreadable silhouette.
- **Shisui:** copied strikes; Body Flicker ends inside the opponent.
- **Orochimaru:** snake invisible.
- **Deidara:** birds are a dark line; spiders and Katsu are invisible.
- **Sasori:** the puppet is not recorded; the master is static.
- **Nagato:** recycled chain; Repulsion has no wave.
- **Bee:** thin swords, ink invisible.
- **Madara:** generic, wrong hair, no Katon fire.
- **Hashirama:** generic.
- **Hiruzen:** the staff reads, the rest is generic.

## Limits
- Inputs were scripted, not played by a human.
- Clones and puppets are not recorded.
- The capture rate is Studio's (15–60 fps).
