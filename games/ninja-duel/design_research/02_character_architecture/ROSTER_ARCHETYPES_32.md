# Roster Architecture — Target 32 Fighters

The final roster can target roughly 32 fighters, but the project should avoid 32 isolated combat engines.

## Mechanical family library

Use a finite set of families, then combine 1–3 per character.

1. Teleport / spatial control
2. Burst mobility / afterimages
3. Prediction / counter
4. Precision pressure / chakra disruption
5. Pure taijutsu rushdown
6. Automatic defense / armor
7. Clone deception
8. Projectile geometry
9. Body manipulation / strange range
10. Trap / preparation
11. Heavy power / grappling
12. Elemental zoning
13. Summoning
14. Terrain manipulation
15. Weapon specialist
16. Resource denial
17. Stance switching
18. Aerial specialist
19. Wall specialist
20. Adaptive/generalist

## User-selected priority roster pool — 2026-10-13

The user explicitly named the following **25 characters** as the current preferred roster pool. Treat this as the authoritative priority pool for future roster research/design unless the user changes it. This does **not** mean all 25 must be implemented now; CORE4 remains Minato / Itachi / Neji / Sasuke, and expansion should remain staged.

1. Sasuke
2. Neji
3. Gaara
4. Itachi
5. Minato
6. Kakashi
7. Shisui
8. Naruto
9. Rock Lee
10. Orochimaru
11. Nagato
12. Killer Bee
13. Obito
14. Kimimaro
15. Haku
16. Shikamaru
17. Kisame
18. Sasori
19. Kabuto
20. Tobirama
21. Hiruzen
22. Deidara
23. Darui
24. Yagura
25. Konan

Interpretation rules:
- preserve the project’s young-prodigy framing where possible;
- where strict canon age/power availability conflicts with the game concept, research and label each kit as `CANON_YOUNG`, `PLAUSIBLE_YOUNG`, `GAMEPLAY_LIBERTY`, or `REJECT_ADULT_ONLY` at the move/ability level rather than rejecting an entire character by default;
- do not flatten characters into adult/final-form miniature versions;
- each approved fighter must have a distinct neutral, movement identity, taijutsu silhouette, tool/weapon relationship, conversions and awakening logic;
- new characters should bend shared systems rather than create isolated engines.

The remaining ~7 slots toward a 32-fighter target are intentionally open. Do not fill them automatically; use future user direction plus mechanical-gap/lore research.

## Current 10 anchors

### Minato
Families: teleport/spatial + preparation + precision.
Question his kit should answer: how do I turn the arena into a network of attack angles?

### Itachi
Families: prediction + projectile geometry + deception.
Question: how do I make the opponent choose the wrong answer?

### Neji
Families: precision pressure + counter + resource denial.
Question: how do I win through superior body control and chakra control?

### Sasuke
Families: rushdown + projectile setup + elemental pressure.
Question: how do I convert aggression into increasingly dangerous sequences?

### Naruto
Families: clone deception + rushdown + endurance.
Question: how do I make chaos readable to me but unreadable to the opponent?

### Gaara
Families: automatic defense + terrain control + zoning.
Question: how do I force the opponent to solve my space before touching me?

### Kakashi
Families: prediction + adaptive/generalist + elemental versatility.
Question: how do I turn information gathered during the fight into advantage?

### Orochimaru
Families: body manipulation + strange range + trap/summoning.
Question: how do I make normal spacing rules unreliable?

### Shisui
Families: burst mobility + afterimage deception + counter.
Question: how do I create multiple believable positions at once?

### Rock Lee
Families: pure taijutsu + aerial + rushdown.
Question: can the combat engine feel amazing with almost no ninjutsu?

## Priority expansion identities to research from the user-selected pool

These are not full movesets yet. They are the mechanical questions Claude/research should answer before implementation.

- **Nagato** — gravity/repulsion-attraction, control and costly high-impact conversions; avoid giving a young version every late-series Path ability by default.
- **Killer Bee** — multi-weapon rhythm, unusual sword geometry, acrobatic pressure and jinchuriki escalation.
- **Obito** — evasive/phasing mind games, angle control and fire/tool pressure; youth framing must avoid defaulting to late-war god-kit.
- **Kimimaro** — body weapon, armor, bone range/terrain and committed close pressure.
- **Haku** — speed lanes, senbon precision, ice-mirror spatial network and aerial/angle control.
- **Shikamaru** — shadow constraint, trap/prediction, low-mobility high-IQ space control.
- **Kisame** — heavy weapon pressure, water-space control, chakra drain/resource denial.
- **Sasori** — puppet remote-body control, poison/setup and multi-position pressure; age framing to research carefully.
- **Kabuto** — medical precision, deception, adaptive utility and opportunistic counters; avoid adult sage-mode default.
- **Tobirama** — water mastery, tactical speed/spatial tools and precision; distinguish clearly from Minato.
- **Hiruzen** — broad elemental/tool mastery and adaptable fundamentals; youth version should feel gifted rather than “all jutsu old Hokage”.
- **Deidara** — aerial zoning, explosive setup, remote pressure and terrain denial.
- **Darui** — calm weapon/lightning/water mix, black-lightning pressure, efficient mid-range transitions.
- **Yagura** — staff/club-style weapon identity, water/reflective defense possibilities and jinchuriki escalation if age framing supports it.
- **Konan** — paper-body geometry, ranged shaping, traps and mobility; distinguish from generic projectile zoning.

## Candidate expansion slots not currently in the user-selected priority pool

Keep these as secondary research candidates only. Do not promote above the 25 named characters without user direction or a clear mechanical-gap reason.

Potential directions worth exploring:
- Temari — long-range wind zoning / space denial.
- Kankuro — puppet trap/control, if age framing fits.
- Tenten — true tool specialist, projectile inventory, wire/weapon transitions.
- Yamato/Tenzo — wood terrain manipulation if age framing works.
- Hashirama young — terrain/summon/regen identity.
- Madara young — weapon/Sharingan/fire pressure.
- Might Guy young — taijutsu/pressure/gates counterpart to Lee.
- Hinata young — defensive Gentle Fist variant, contrasted with Neji.
- Kiba — partner-assisted rushdown / tracking.
- Shino — swarm zoning/resource pressure.
- Choji — expansion/heavy grappler.
- Ino — risky control/setup.
- Zabuza young — mist/weapon/ambush if timeline permits.

## Differentiation checklist

Before approving a new character, answer:
- What does this fighter do in neutral that no current fighter does exactly the same way?
- What is their movement identity?
- What is their taijutsu silhouette?
- How do they launch?
- How do they pursue?
- How do they use walls?
- How do they use standard ninja tools?
- What state or rule do they manipulate?
- What is their signature resource or setup?
- What changes during awakening?

If two characters answer these questions nearly identically, one needs redesign.

## Shared-system economy

Aim for roughly 70% shared systems / 30% character-specific behavior.

Shared:
- movement states,
- lock-on,
- generic tools,
- hit reactions,
- launcher/slam state handling,
- wall states,
- air states,
- guard/substitution framework,
- awakening framework.

Character-specific:
- movement interpretation,
- combo silhouettes,
- conversions,
- signatures,
- projectile mastery,
- special rule-bending,
- awakening behavior.

This ratio is not strict, but prevents the 32-character roster from becoming impossible to maintain.
