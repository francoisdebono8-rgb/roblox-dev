# Vision Gap Audit — Phase 3 (Youth Tournament Core)

Written after playing the build in Roblox Studio during this phase (scripted routes for both fighters,
frame captures of throws / Flying Thunder God / Great Fireball / strings, and 45 s AI-vs-AI soaks).
The target read: *twenty 12–14-year-old future legends in a prestigious tournament that shows why each of
them will become extraordinary*.

## 1. What still prevents the combat from feeling premium?

- **Hit feel is visual-only.** Contacts have hitstop, sparks and camera impulse, but only three melee sounds
  exist. No whoosh per limb, no material-specific impacts, no crowd reaction, no voice. Audio is the
  largest single gap between "prototype" and "premium".
- **Animation is procedural keyframes on a block rig.** The owned-pose engine with leg IK reads cleanly, but
  every clip is 3–5 keys with smoothstep easing. There are no overlapping actions (hair/cloth lag), no
  secondary motion, no squash on impacts, no root-motion-driven attacks. Strong clips look intentional; weak
  ones look like poses being interpolated.
- **Contact timing is server-tick based.** Hit validation is now consistent (history + per-frame active
  checks), but the visual contact pose is reached by damping, so a few strikes still look a frame early or
  late. A per-move "contact frame" authored in the clip and shared with the server would align them.
- **Defence has little drama.** Guard, parry and perfect dodge work, but their presentation is small
  (sparks, a guard pose). Parry should be an event (freeze frame, camera punch, unique sound).

## 2. What still prevents Minato from feeling like a uniquely gifted young Minato?

- His identity now lives in real mechanics (mobile kunai, Flying Thunder God onto a kunai in flight with an
  arrival strike, AngleStep around the guard, kunai disengage, Rasengan as a string finisher). What is
  missing is **mastery expression**: a skilled player should be able to chain two seals, re-mark mid-air, or
  teleport to a planted kunai behind cover for a whiff punish. Today there is one seal and one teleport.
- The teleport is readable but always lands "behind if near the opponent". A deliberate choice of
  arrival side (stick direction at arrival) would turn it into prediction rather than a fixed trick.
- His locomotion is fast but similar in shape to Itachi's; he needs lighter, springier footwork (on-toes
  stance, quicker turn steps).

## 3. What still prevents Itachi from feeling like a uniquely gifted young Itachi?

- Read now pays off with a counter palm, the Sweep trades a string for a knockdown, and he can cancel a
  blocked light into shuriken. But **shuriken geometry** is still mostly straight lines. Young Itachi is
  defined by ricochet/curving shuriken and perfect accuracy; one bank-shot technique would sell him.
- Genjutsu: Mirage changes position information but rarely changes a decision. It needs a real read: e.g.
  attacking the decoy triggers a crow scatter and a free counter.
- Great Fireball is a good lane-denial tool; it needs a stronger windup tell for the opponent (hand-sign
  sound, ember gather already exists) and a small "burning ground" zone control role in neutral.

## 4. Which mechanics are currently too generic?

- The ground light string (Light1–3) is still shared logic with per-fighter tuning and clips; only the
  branches are character-specific. The third hit should be bespoke per fighter.
- Air combos (Air1, Air2, Slam) are identical in structure for both fighters.
- Substitution is identical (only the VFX differ: log vs crows).
- Chase is identical; Itachi's aerial game should end with control (shuriken, fire) rather than the same chase.

## 5. Which animations still look weak?

- Walk/run transitions at low speed (feet slide when speed changes quickly).
- Turning in place (root rotates, legs do not step).
- Grab / throw clips (generic).
- Air1/Air2 for both fighters (limb poses, no body rotation through the strike).
- Hit reactions are correct directionally but stiff; there is no stagger step.
- Knockdown → wake-up is fast and readable but not "anime" (no kip-up, no recovery roll).

## 6. What camera problems remain?

- Framing at long range puts the player large in the foreground; acceptable, but cross-arena fireball
  exchanges would read better with a wider two-shot.
- No finisher / KO camera; the result screen arrives without a final beat.
- Wall running and very high aerial exchanges are only lightly tested.
- Props between the camera and the fight now fade instead of shoving the lens in (fixed this phase).

## 7. What arena/presentation problems remain?

- The arena is now the Konoha Chunin Exam finals stadium (at the user's request): tall panelled wall used for
  wall running, bushes, field trees, earth floor, spectators along the rim, golden-roofed pavilions, the
  Kage box, participants' balcony and gate. It is still a block-built approximation: no curved roof tiles,
  no textured wall panels, simple spectator capsules.
- Spectators now rise on big moments, but there is no crowd sound, announcer, round system or bracket view.
- The sky is the default sky; the forest outside is simple spheres.
- The Studio window on high-DPI Windows shows only part of the play viewport (Studio display issue, not the
  game); on Mac the full HUD and framing are visible.

## 8. What does the game still lack to sell "20 greatest prodigies aged 12–14"?

- A visible roster: the selection screen now shows 20 slots with 18 locked, but locked slots have no names,
  silhouettes or villages.
- Character faces: block faces cannot carry age or personality. Face textures (eyes/brows/expression
  decals) are the cheapest high-impact upgrade, but need uploaded assets.
- Tournament structure: rounds, bracket, judges' commentary, a reason to win.
- Youth attitude in animation (fidgeting idle, celebratory win pose, frustrated loss pose).

## 9. Technical risks when adding the next 18 fighters

- **Move graphs were hard-coded per fighter id inside Brawler.** Fixed this phase: branches and cancel rules
  now live in `src/Shared/MoveGraphs.luau` (data per fighter) with code hooks only where behaviour is
  bespoke.
- Clips live in one large client module keyed by fighter id; it will need to be split per fighter.
- Techniques are a flat table keyed by technique id (`Techniques.luau`); fine, but each new kit will add
  bespoke server code — keep a per-fighter folder.
- Costumes are code (`World.dress`); 20 costumes in code is maintainable only with a shared helper set
  (`wear`, `spike`, `hairCap`, `crest` exist now).
- Test harness covers timing/state headlessly; native Studio QA is still manual.

## 10. Five highest-value improvements after this phase

1. **Audio pass** (impacts per weight, whooshes, throws, fire, teleport crack, crowd) — biggest feel gain.
2. **Per-fighter third hit + air route** so strings stop being shared skeletons.
3. **Contact-frame authoring** shared by clip and server, removing early/late visual contacts.
4. **Crowd and judges that react** (stand up, cheer on big hits, gasps on a teleport) — sells the tournament.
5. **Faces with expression** (decal-based) and youth attitude poses (intro, win, loss).

## Implemented from this audit during the phase

- Move graphs extracted to data (`MoveGraphs.luau`), with Brawler/Combat reading them (item 9).
- Crowd reactions: spectators on the stadium rim rise and cheer on heavy hits, Flying Thunder God and
  fire blasts (item 4).
- Arena rebuilt as the Chunin Exam finals stadium (item 7).
- Fighter intro attitudes: Minato twirls a kunai, Itachi's Sharingan flares during the match intro (item 5,
  partial).
- Camera fades occluding props instead of collapsing onto the player (item 6).
