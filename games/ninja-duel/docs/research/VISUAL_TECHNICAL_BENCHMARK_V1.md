# Visual + Technical Benchmark V1 — freedom, movement, combat, weapons

Purpose: give Claude concrete external reference targets for *feel* and *freedom*, not permission to copy code/assets/movesets. Ninja Duel stays a focused 1v1 game with a compact input grammar. The useful question is always: **what principle makes this feel like free shinobi movement/combat, and how do we adapt that principle to a readable 1v1 duel?**

## Benchmark rule

For every reference, Claude must separate:

1. **Observed visual/mechanical fact** — what is actually visible or documented.
2. **Why it feels good** — speed, body intention, camera, timing, space use, tool integration, etc.
3. **Reusable principle** — e.g. momentum-preserving wall entry, weapon route that closes distance, air-to-ground continuation.
4. **Ninja Duel adaptation** — how it fits CORE4, current combat grammar and 1v1 readability.
5. **Do not copy** — assets, exact choreography, copyrighted animation, whole combat engines, progression clutter, MMO/RP complexity.

A screenshot/still is a **visual target**, not an implementation spec. Compare the same Ninja Duel action in Studio before/after.

---

# A. Freedom target — Naruto RP / free-roam Roblox games adapted to 1v1

These are important because the user wants the *freedom* of Naruto RP/free-roam games — moving through a shinobi world, chaining terrain, tools and combat — but compressed into a competitive 1v1 where every action is readable and useful.

## A1 — Shinobi Life 2 / Shindo-style free-roam

Source: https://www.roblox.com/games/5988565633/Shinobi-Life-2

Why it matters:
- free-roam shinobi fantasy instead of a flat arena-only fighter;
- many worlds / exploration / abilities and an Arena mode;
- useful reference for the feeling that the character is a ninja *before* combat starts.

Supporting movement reference:
- Tree jump / wall walk video: https://www.youtube.com/watch?v=1kKR36zIim4

Visual captures Claude should collect/review:
- normal traversal across a village/forest;
- tree jump / traversal jump;
- wall walk/run entry and exit;
- transition from free movement into combat stance/attack;
- camera distance during fast traversal;
- any moment where terrain changes the route rather than serving as background.

Extract for Ninja Duel:
- traversal should preserve momentum and let the player choose routes;
- wall/tree/height should be movement verbs, not canned set pieces;
- regular movement should already feel “shinobi” without a jutsu;
- adapt the freedom to a bounded 1v1 arena: fewer systems, higher responsiveness, clearer counterplay.

Do not import:
- open-world grind/progression clutter;
- huge ability inventory;
- evasive movement that lets a 1v1 player run forever without pressure.

## A2 — Shinobi Way (Ouro Games)

Source: https://www.roblox.com/games/104741933311544/Shinobi-Way

Gameplay reference found: https://www.youtube.com/watch?v=V3WI3wCeYDQ

Why it matters:
- modern Roblox shinobi RPG reference;
- taijutsu/ninjutsu lineage fantasy in an explorable village/world;
- useful for run/sprint, approach, weapon/tool transitions, how a Roblox avatar reads at speed.

Visual captures Claude should collect/review:
- basic run and sprint side-by-side;
- dash from neutral;
- approach to an opponent/NPC;
- taijutsu exchange at normal speed;
- weapon draw/use if visible;
- camera during high-speed approach and abrupt direction change.

Extract for Ninja Duel:
- movement must look fun even before first contact;
- camera and body posture should make speed perceptible without FOV abuse;
- tool/combat transitions should not freeze the locomotion state.

## A3 — Shinobi Rising

Source: https://www.roblox.com/games/9107482158/Shinobi-Rising

Documented controls useful as reference:
- dash;
- substitution/evasive;
- block;
- kunai throw;
- weapon/special abilities;
- guardbreak;
- explicit air-combo route.

Visual captures Claude should collect/review:
- dash → attack;
- 4-hit ground route → air-combo conversion;
- kunai while moving;
- substitution/evasive return to neutral;
- guardbreak body language;
- vertical camera during air conversion.

Extract for Ninja Duel:
- compact inputs can still produce a broad shinobi language;
- air combat should be a continuation of neutral/ground combat, not a disconnected minigame;
- defense/evasion must return to movement quickly.

## A4 — Shinobi Storm / other Naruto Roblox arena references

Shinobi Storm: https://www.roblox.com/games/4585085581/Shinobi-Storm
Naruto: Ninja Fighting Arena: https://www.roblox.com/games/125188005/Naruto-Ninja-Fighting-Arena
Naruto Fighting Arena: https://www.roblox.com/games/6229539377/Naruto-Fighting-Arena

Use these as comparative references for:
- fast shinobi PvP readability;
- how Roblox-scale characters occupy an arena;
- whether simple punch/jutsu/control grammars can still feel immediate;
- character differentiation.

Do not lower Ninja Duel’s target just because a simpler Roblox game is playable. These references are useful for **clarity and immediacy**, while Ninja Duel should keep deeper body mechanics, tools, air/wall conversion and character-specific interpretation.

---

# B. Naruto console reference — Storm 4 for continuity and spectacle

## B1 — General combat flow / cancellation / counters

Reference: https://www.youtube.com/watch?v=77DJwBsg-l0

Useful documented sections:
- counterattack;
- guard break;
- combo cancellation;
- elemental effects;
- awakenings.

Visual captures Claude should collect/review:
- run/approach → first hit;
- combo cancellation into reposition;
- counterattack body/camera read;
- guard break feedback;
- launcher/chase/air continuation if present.

Extract:
- low downtime;
- clear continuation from approach to hit to conversion;
- animation/camera can be spectacular while preserving readable state changes.

## B2 — Wall-running fight

Reference: https://www.youtube.com/watch?v=DAJFdMyplPs

Visual captures Claude should collect/review:
- ground → wall transition;
- wall pursuit;
- wall attack / defend / reposition;
- return from wall to floor;
- camera orientation through vertical changes.

Extract:
- wall traversal must preserve combat intention;
- verticality should create angles, not temporarily turn off the fight;
- camera should reframe smoothly and preserve opponent awareness.

---

# C. Shinobi Striker — primary weapon / tool / 3D-combat technical reference

Shinobi Striker is **not** the target structure (it is team-oriented and content-heavy), but it is a strong reference for integrating weapons, ninja tools, chakra properties, pursuit and 3D terrain into normal combat.

## C1 — Weapon identity changes routes, not just damage numbers

Official Naruto developer reference:
https://naruto-official.com/en/news/01_1742

Documented examples:
- a light blade trades reach for fast attacks and can be combined with taijutsu for high-speed combos;
- tonfa-style weapons extend combo/follow-up behavior.

Ninja Duel principle:
- weapon = body language + range + route + recovery + conversion;
- do not implement “equip sword = same combo with a sword mesh”.

Visual captures to collect:
- weapon stance;
- first attack startup;
- weapon-to-body strike transition;
- finisher/recovery;
- how the weapon changes spacing.

## C2 — Weapons/ninja tools can close distance and create pursuit

Official developer reference:
https://naruto-official.com/en/news/01_2341

Documented design change:
- many attack/heal weapons received forward-charging ranged-normal attacks so normal attacks can bring the user closer to a fleeing target;
- ranged weapons such as Kunai received range attacks;
- stated goal: reduce passive disengage and create more tactical pressure after resources are spent.

Ninja Duel principle:
- tools/weapons can be **range bridges**;
- a kunai/shuriken route can open or close space rather than being a detached projectile cooldown;
- pursuit should be interactable and punishable, not homing autopilot.

Strong direct fit:
- Minato: marked kunai → destination/angle/pursuit;
- Itachi: shuriken geometry → force reaction → controlled entry;
- Sasuke: shuriken/wire/fire → aggressive range bridge;
- Neji: mostly body-led approach/counter; tools remain secondary.

## C3 — Tool + element/chakra property + movement

Official developer reference:
https://naruto-official.com/fr/news/01_2400

Documented examples include:
- lightning-infused Uchiha shuriken that slow/restrain when they connect;
- the throw also enables rapid movement in the throw direction, supporting gap-close or escape;
- weapons mixing multiple elemental/jutsu properties.

Ninja Duel principle:
**Object + Chakra Property/Nature + Trigger/Context → Result**

This directly supports TOOL-006 / SYS-001. Prototype one readable, counterable interaction before building a universal framework.

Visual captures to collect:
- pre-throw body preparation;
- projectile release;
- movement caused by/paired with the tool;
- enemy reaction;
- follow-up opportunity.

## C4 — Timing-sensitive weapon combos

Official developer reference:
https://naruto-official.com/en/news/01_2603

Documented example:
- a weapon with timed inputs where commands entered around impact improve the result.

Ninja Duel principle:
- depth can come from timing, not more buttons;
- possible future inspiration for precise weapon follow-ups/parries/impact confirms;
- do **not** add a global rhythm-game mechanic without Studio proof that it improves feel.

## C5 — Weapon as character-specific combat language

Official examples also include Danzo-style wind kunai, Orochimaru-style snake sword and other weapons that alter attack geometry / properties:
- https://naruto-official.com/en/news/01_2341
- https://naruto-official.com/en/news/01_2541

Ninja Duel principle:
- common weapon categories are shared infrastructure;
- each fighter bends the category through identity;
- do not create a generic inventory simulator.

---

# D. Golden screenshot / still set Claude must build before major animation decisions

Claude should create a small local/reference sheet (or equivalent documented screenshots/timecodes) with **at least one strong example in each category**. Prefer 2–3 when references materially differ.

1. Neutral standing/guard silhouette.
2. Normal run.
3. Sprint/high-speed pursuit.
4. Direction change / stop / re-entry.
5. Ninja jump takeoff + horizontal travel.
6. Landing/recovery.
7. Wall-run entry.
8. Wall combat/reposition.
9. Simple punch with clear support/hip/contact/recovery.
10. Kick with visible pivot/support/retraction.
11. Ground combo that does not look like dance choreography.
12. Launcher → chase → air continuation.
13. Air intercept / slam / landing.
14. Guard / deflect / counter.
15. Dodge/substitution → angle change.
16. Kunai/shuriken while moving.
17. Weapon draw/grip → strike → throw or recovery.
18. Tool used to open/close range.
19. Clash/contact moment.
20. Camera example where speed is strong but contact remains readable.

For every still/timecode record:

```text
SOURCE:
URL / GAME / VIDEO:
TIMECODE or exact situation:
CATEGORY:
WHAT IS VISUALLY GOOD:
BODY MECHANICS:
CAMERA CONTRIBUTION:
GAMEPLAY FUNCTION:
NINJA DUEL ADAPTATION:
CORE4 DIFFERENCES:
DO NOT COPY:
LINKED IDS:
```

The sheet is not complete until it contains examples for **ground, air, wall, weapon/tool, defense and pure traversal**.

---

# E. Acceptance test derived from the benchmark

A Ninja Duel pass is not “visually successful” because more clips exist. Claude must compare against the golden set in Studio.

Minimum bar:
- 30 seconds of movement without combat already feels fast, intentional and ninja-like;
- ordinary run and sprint are perceptually distinct without only changing WalkSpeed/FOV;
- ordinary traversal jump has decisive takeoff, horizontal intent and proportional landing — no tiny Roblox hop + exaggerated heavy fall;
- a jab/palm/kick can be paused near contact and still reads as a plausible strike, not a dance pose;
- attack → move → defend → tool → re-enter can happen without visible state cuts;
- wall and air routes preserve combat awareness;
- weapons/tools visibly change route/spacing/body language;
- camera supports speed and verticality without hiding feet/contact;
- Minato, Itachi, Neji and Sasuke remain recognizably different through the same common grammar.

If a motion fails the visual/mechanical benchmark, Claude may **reject or rebuild it** rather than preserve it because it already exists.

## Linked active work

MOV-001..005; COM-002..006; DEF-002..005; TOOL-002/005/006; SYS-001/002; CHR-CORE-001; CHR-MIN/ITA/NEJ/SAS; ARENA-001/003; CAM-001/002; RES-001/003; LAB-002.
